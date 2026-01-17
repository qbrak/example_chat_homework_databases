-- Prison Management Database Views
-- At least 2 non-trivial views required

-- ============================================
-- VIEW 1: Prisoner Full Details
-- Combines prisoner info with cell, block, and current sentence
-- ============================================

CREATE OR REPLACE VIEW v_prisoner_details AS
SELECT
    p.id AS prisoner_id,
    p.prisoner_number,
    p.first_name,
    p.last_name,
    p.first_name || ' ' || p.last_name AS full_name,
    p.date_of_birth,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, p.date_of_birth))::INTEGER AS age,
    p.gender,
    p.nationality,
    p.status,
    p.admission_date,
    p.blood_type,
    p.emergency_contact_name,
    p.emergency_contact_phone,
    c.cell_code,
    c.cell_type,
    c.floor_number AS cell_floor,
    cb.name AS block_name,
    cb.security_level,
    s.id AS current_sentence_id,
    ct.name AS crime,
    ct.severity_level AS crime_severity,
    s.sentence_start_date,
    s.sentence_years,
    s.sentence_months,
    s.is_life_sentence,
    s.parole_eligible,
    s.parole_date,
    s.court_name,
    s.case_number,
    CASE
        WHEN s.is_life_sentence THEN NULL
        ELSE s.sentence_start_date +
             (s.sentence_years || ' years')::INTERVAL +
             (s.sentence_months || ' months')::INTERVAL
    END AS expected_release_date,
    (SELECT COUNT(*) FROM incidents i WHERE i.prisoner_id = p.id) AS total_incidents,
    (SELECT COUNT(*) FROM visits v WHERE v.prisoner_id = p.id AND v.status = 'completed') AS total_visits,
    (SELECT COUNT(*) FROM prisoner_programs pp WHERE pp.prisoner_id = p.id AND pp.status = 'completed') AS completed_programs
FROM prisoners p
LEFT JOIN cells c ON p.cell_id = c.id
LEFT JOIN cell_blocks cb ON c.cell_block_id = cb.id
LEFT JOIN LATERAL (
    SELECT * FROM sentences
    WHERE prisoner_id = p.id
    ORDER BY sentence_start_date DESC
    LIMIT 1
) s ON true
LEFT JOIN crime_types ct ON s.crime_type_id = ct.id;

-- ============================================
-- VIEW 2: Cell Occupancy Report
-- Shows cell and block capacity vs current occupancy
-- ============================================

CREATE OR REPLACE VIEW v_cell_occupancy AS
SELECT
    cb.id AS block_id,
    cb.name AS block_name,
    cb.security_level,
    cb.capacity AS block_total_capacity,
    c.id AS cell_id,
    c.cell_code,
    c.cell_type,
    c.floor_number,
    c.capacity AS cell_capacity,
    COUNT(p.id) AS current_occupancy,
    c.capacity - COUNT(p.id) AS available_spots,
    ROUND(COUNT(p.id)::NUMERIC / c.capacity * 100, 1) AS occupancy_percentage,
    CASE
        WHEN COUNT(p.id) = 0 THEN 'empty'
        WHEN COUNT(p.id) < c.capacity THEN 'available'
        ELSE 'full'
    END AS cell_status,
    STRING_AGG(p.prisoner_number, ', ' ORDER BY p.last_name) AS prisoner_numbers
FROM cell_blocks cb
LEFT JOIN cells c ON c.cell_block_id = cb.id
LEFT JOIN prisoners p ON p.cell_id = c.id AND p.status = 'incarcerated'
GROUP BY cb.id, cb.name, cb.security_level, cb.capacity,
         c.id, c.cell_code, c.cell_type, c.floor_number, c.capacity
ORDER BY cb.name, c.cell_code;

-- ============================================
-- VIEW 3: Upcoming Releases (within 6 months)
-- Shows prisoners due for release soon
-- ============================================

CREATE OR REPLACE VIEW v_upcoming_releases AS
SELECT
    p.id AS prisoner_id,
    p.prisoner_number,
    p.first_name || ' ' || p.last_name AS full_name,
    p.admission_date,
    ct.name AS crime,
    s.sentence_start_date,
    s.sentence_years,
    s.sentence_months,
    s.sentence_start_date +
        (s.sentence_years || ' years')::INTERVAL +
        (s.sentence_months || ' months')::INTERVAL AS release_date,
    (s.sentence_start_date +
        (s.sentence_years || ' years')::INTERVAL +
        (s.sentence_months || ' months')::INTERVAL - CURRENT_DATE) AS days_until_release,
    s.parole_eligible,
    s.parole_date,
    c.cell_code,
    cb.name AS block_name,
    (SELECT COUNT(*) FROM incidents i WHERE i.prisoner_id = p.id) AS incident_count,
    (SELECT COUNT(*) FROM prisoner_programs pp
     WHERE pp.prisoner_id = p.id AND pp.status = 'completed') AS programs_completed
FROM prisoners p
JOIN sentences s ON s.prisoner_id = p.id
JOIN crime_types ct ON s.crime_type_id = ct.id
LEFT JOIN cells c ON p.cell_id = c.id
LEFT JOIN cell_blocks cb ON c.cell_block_id = cb.id
WHERE
    p.status = 'incarcerated'
    AND s.is_life_sentence = false
    AND (s.sentence_start_date +
         (s.sentence_years || ' years')::INTERVAL +
         (s.sentence_months || ' months')::INTERVAL)
        BETWEEN CURRENT_DATE AND CURRENT_DATE + INTERVAL '6 months'
ORDER BY release_date ASC;

-- ============================================
-- VIEW 4: Block Summary Statistics
-- Aggregated statistics per cell block
-- ============================================

CREATE OR REPLACE VIEW v_block_summary AS
SELECT
    cb.id AS block_id,
    cb.name AS block_name,
    cb.security_level,
    cb.floor_count,
    COUNT(DISTINCT c.id) AS total_cells,
    SUM(c.capacity) AS total_bed_capacity,
    COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'incarcerated') AS current_prisoners,
    ROUND(
        COUNT(DISTINCT p.id) FILTER (WHERE p.status = 'incarcerated')::NUMERIC /
        NULLIF(SUM(c.capacity), 0) * 100, 1
    ) AS occupancy_rate,
    COUNT(DISTINCT s.id) FILTER (WHERE s.role_id IN (SELECT id FROM staff_roles WHERE name = 'Guard')) AS assigned_guards,
    (SELECT COUNT(*) FROM incidents i
     JOIN prisoners pr ON i.prisoner_id = pr.id
     JOIN cells ce ON pr.cell_id = ce.id
     WHERE ce.cell_block_id = cb.id
     AND i.incident_date >= CURRENT_DATE - INTERVAL '30 days') AS incidents_last_30_days
FROM cell_blocks cb
LEFT JOIN cells c ON c.cell_block_id = cb.id
LEFT JOIN prisoners p ON p.cell_id = c.id
LEFT JOIN staff s ON s.assigned_block_id = cb.id AND s.is_active = true
GROUP BY cb.id, cb.name, cb.security_level, cb.floor_count
ORDER BY cb.name;

-- ============================================
-- VIEW 5: Staff Schedule Overview
-- Shows staff assignments and basic info
-- ============================================

CREATE OR REPLACE VIEW v_staff_overview AS
SELECT
    s.id AS staff_id,
    s.employee_id,
    s.first_name || ' ' || s.last_name AS full_name,
    sr.name AS role,
    sr.access_level,
    s.hire_date,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, s.hire_date))::INTEGER AS years_employed,
    s.is_active,
    cb.name AS assigned_block,
    cb.security_level AS block_security,
    s.email,
    s.phone
FROM staff s
JOIN staff_roles sr ON s.role_id = sr.id
LEFT JOIN cell_blocks cb ON s.assigned_block_id = cb.id
ORDER BY sr.access_level DESC, s.last_name;
