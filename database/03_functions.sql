-- Prison Management Database Functions and Triggers
-- At least 2 functions/triggers required

-- ============================================
-- FUNCTION 1: Calculate Release Date
-- Returns expected release date for a prisoner
-- ============================================

CREATE OR REPLACE FUNCTION calculate_release_date(p_prisoner_id INTEGER)
RETURNS DATE AS $$
DECLARE
    v_release_date DATE;
    v_is_life BOOLEAN;
BEGIN
    SELECT
        s.is_life_sentence,
        CASE
            WHEN s.is_life_sentence THEN NULL
            ELSE (s.sentence_start_date +
                  (s.sentence_years || ' years')::INTERVAL +
                  (s.sentence_months || ' months')::INTERVAL)::DATE
        END
    INTO v_is_life, v_release_date
    FROM sentences s
    WHERE s.prisoner_id = p_prisoner_id
    ORDER BY s.sentence_start_date DESC
    LIMIT 1;

    IF v_is_life THEN
        RETURN NULL; -- Life sentence, no release date
    END IF;

    RETURN v_release_date;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION 2: Get Prisoner Full History
-- Returns comprehensive prisoner history as JSON
-- ============================================

CREATE OR REPLACE FUNCTION get_prisoner_full_history(p_prisoner_id INTEGER)
RETURNS JSON AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'prisoner', (
            SELECT row_to_json(p.*)
            FROM prisoners p
            WHERE p.id = p_prisoner_id
        ),
        'sentences', (
            SELECT COALESCE(json_agg(row_to_json(s.*) ORDER BY s.sentence_start_date DESC), '[]'::json)
            FROM (
                SELECT
                    sen.id,
                    sen.sentence_start_date,
                    sen.sentence_years,
                    sen.sentence_months,
                    sen.is_life_sentence,
                    sen.parole_eligible,
                    sen.parole_date,
                    sen.court_name,
                    sen.case_number,
                    ct.name AS crime_type,
                    ct.severity_level
                FROM sentences sen
                JOIN crime_types ct ON sen.crime_type_id = ct.id
                WHERE sen.prisoner_id = p_prisoner_id
            ) s
        ),
        'incidents', (
            SELECT COALESCE(json_agg(row_to_json(i.*) ORDER BY i.incident_date DESC), '[]'::json)
            FROM (
                SELECT
                    inc.id,
                    inc.incident_date,
                    inc.incident_type,
                    inc.severity,
                    inc.location,
                    inc.description,
                    inc.action_taken,
                    inc.solitary_days,
                    inc.is_resolved,
                    st.first_name || ' ' || st.last_name AS reported_by
                FROM incidents inc
                LEFT JOIN staff st ON inc.reported_by_staff_id = st.id
                WHERE inc.prisoner_id = p_prisoner_id
            ) i
        ),
        'visits', (
            SELECT COALESCE(json_agg(row_to_json(v.*) ORDER BY v.visit_date DESC), '[]'::json)
            FROM (
                SELECT
                    vis.id,
                    vis.visit_date,
                    vis.scheduled_start_time,
                    vis.scheduled_end_time,
                    vis.status,
                    vis.visit_type,
                    vr.first_name || ' ' || vr.last_name AS visitor_name,
                    vr.relationship_type
                FROM visits vis
                JOIN visitors vr ON vis.visitor_id = vr.id
                WHERE vis.prisoner_id = p_prisoner_id
            ) v
        ),
        'programs', (
            SELECT COALESCE(json_agg(row_to_json(pr.*) ORDER BY pr.enrollment_date DESC), '[]'::json)
            FROM (
                SELECT
                    pp.id,
                    prog.name AS program_name,
                    pt.name AS program_type,
                    pp.enrollment_date,
                    pp.completion_date,
                    pp.status,
                    pp.grade
                FROM prisoner_programs pp
                JOIN programs prog ON pp.program_id = prog.id
                JOIN program_types pt ON prog.program_type_id = pt.id
                WHERE pp.prisoner_id = p_prisoner_id
            ) pr
        ),
        'statistics', json_build_object(
            'total_sentences', (SELECT COUNT(*) FROM sentences WHERE prisoner_id = p_prisoner_id),
            'total_incidents', (SELECT COUNT(*) FROM incidents WHERE prisoner_id = p_prisoner_id),
            'total_visits', (SELECT COUNT(*) FROM visits WHERE prisoner_id = p_prisoner_id AND status = 'completed'),
            'programs_completed', (SELECT COUNT(*) FROM prisoner_programs WHERE prisoner_id = p_prisoner_id AND status = 'completed'),
            'total_solitary_days', (SELECT COALESCE(SUM(solitary_days), 0) FROM incidents WHERE prisoner_id = p_prisoner_id)
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FUNCTION 3: Get Cell Current Occupancy
-- Returns number of prisoners in a cell
-- ============================================

CREATE OR REPLACE FUNCTION get_cell_occupancy(p_cell_id INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM prisoners
        WHERE cell_id = p_cell_id AND status = 'incarcerated'
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGER 1: Check Cell Capacity Before Insert/Update
-- Prevents assigning more prisoners than cell capacity
-- ============================================

CREATE OR REPLACE FUNCTION check_cell_capacity()
RETURNS TRIGGER AS $$
DECLARE
    v_capacity INTEGER;
    v_current_occupancy INTEGER;
BEGIN
    -- Only check if cell_id is being set and prisoner is being incarcerated
    IF NEW.cell_id IS NOT NULL AND NEW.status = 'incarcerated' THEN
        -- Get cell capacity
        SELECT capacity INTO v_capacity
        FROM cells
        WHERE id = NEW.cell_id;

        IF v_capacity IS NULL THEN
            RAISE EXCEPTION 'Cell with ID % does not exist', NEW.cell_id;
        END IF;

        -- Count current occupancy (excluding the current prisoner if updating)
        SELECT COUNT(*) INTO v_current_occupancy
        FROM prisoners
        WHERE cell_id = NEW.cell_id
          AND status = 'incarcerated'
          AND id != COALESCE(OLD.id, -1);

        -- Check if there's room
        IF v_current_occupancy >= v_capacity THEN
            RAISE EXCEPTION 'Cell % is at full capacity (% of %)',
                (SELECT cell_code FROM cells WHERE id = NEW.cell_id),
                v_current_occupancy,
                v_capacity;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_cell_capacity
    BEFORE INSERT OR UPDATE ON prisoners
    FOR EACH ROW
    EXECUTE FUNCTION check_cell_capacity();

-- ============================================
-- TRIGGER 2: Auto-update timestamps
-- Updates the updated_at column on any modification
-- ============================================

CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER trg_update_timestamp_prisoners
    BEFORE UPDATE ON prisoners
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_timestamp_sentences
    BEFORE UPDATE ON sentences
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_timestamp_cells
    BEFORE UPDATE ON cells
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_timestamp_cell_blocks
    BEFORE UPDATE ON cell_blocks
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_timestamp_staff
    BEFORE UPDATE ON staff
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_timestamp_visitors
    BEFORE UPDATE ON visitors
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_timestamp_visits
    BEFORE UPDATE ON visits
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_timestamp_programs
    BEFORE UPDATE ON programs
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_timestamp_prisoner_programs
    BEFORE UPDATE ON prisoner_programs
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER trg_update_timestamp_incidents
    BEFORE UPDATE ON incidents
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- ============================================
-- TRIGGER 3: Prevent visits for blacklisted visitors
-- ============================================

CREATE OR REPLACE FUNCTION check_visitor_blacklist()
RETURNS TRIGGER AS $$
DECLARE
    v_is_blacklisted BOOLEAN;
    v_visitor_name TEXT;
BEGIN
    SELECT is_blacklisted, first_name || ' ' || last_name
    INTO v_is_blacklisted, v_visitor_name
    FROM visitors
    WHERE id = NEW.visitor_id;

    IF v_is_blacklisted THEN
        RAISE EXCEPTION 'Visitor % is blacklisted and cannot schedule visits', v_visitor_name;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_visitor_blacklist
    BEFORE INSERT OR UPDATE ON visits
    FOR EACH ROW
    EXECUTE FUNCTION check_visitor_blacklist();

-- ============================================
-- FUNCTION 4: Transfer Prisoner to New Cell
-- Handles cell transfer with validation
-- ============================================

CREATE OR REPLACE FUNCTION transfer_prisoner(
    p_prisoner_id INTEGER,
    p_new_cell_id INTEGER,
    p_reason TEXT DEFAULT 'Administrative transfer'
)
RETURNS BOOLEAN AS $$
DECLARE
    v_old_cell_id INTEGER;
    v_prisoner_status TEXT;
BEGIN
    -- Get current info
    SELECT cell_id, status INTO v_old_cell_id, v_prisoner_status
    FROM prisoners
    WHERE id = p_prisoner_id;

    IF v_prisoner_status != 'incarcerated' THEN
        RAISE EXCEPTION 'Cannot transfer prisoner with status: %', v_prisoner_status;
    END IF;

    IF v_old_cell_id = p_new_cell_id THEN
        RAISE EXCEPTION 'Prisoner is already in cell %', p_new_cell_id;
    END IF;

    -- Update prisoner cell (trigger will check capacity)
    UPDATE prisoners
    SET cell_id = p_new_cell_id,
        notes = COALESCE(notes || E'\n', '') ||
                'Transferred on ' || CURRENT_DATE || ': ' || p_reason
    WHERE id = p_prisoner_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
