-- Prison Management Database Schema
-- Project: Bazy Danych 2025

-- ============================================
-- ENUMERATION TABLES
-- ============================================

-- Crime types enumeration
CREATE TABLE crime_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    severity_level INTEGER NOT NULL CHECK (severity_level BETWEEN 1 AND 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Staff roles enumeration
CREATE TABLE staff_roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    access_level INTEGER NOT NULL CHECK (access_level BETWEEN 1 AND 10),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Program types enumeration
CREATE TABLE program_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- CORE TABLES
-- ============================================

-- Cell blocks (prison wings/sections)
CREATE TABLE cell_blocks (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    security_level VARCHAR(20) NOT NULL CHECK (security_level IN ('minimum', 'medium', 'maximum', 'supermax')),
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    floor_count INTEGER NOT NULL CHECK (floor_count > 0),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Individual cells
CREATE TABLE cells (
    id SERIAL PRIMARY KEY,
    cell_code VARCHAR(20) NOT NULL UNIQUE,
    cell_block_id INTEGER NOT NULL REFERENCES cell_blocks(id) ON DELETE RESTRICT,
    floor_number INTEGER NOT NULL CHECK (floor_number > 0),
    capacity INTEGER NOT NULL DEFAULT 1 CHECK (capacity BETWEEN 1 AND 4),
    cell_type VARCHAR(30) NOT NULL DEFAULT 'standard' CHECK (cell_type IN ('standard', 'solitary', 'medical', 'protective')),
    has_window BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Prisoners
CREATE TABLE prisoners (
    id SERIAL PRIMARY KEY,
    prisoner_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '18 years'),
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('male', 'female', 'other')),
    nationality VARCHAR(50) NOT NULL,
    cell_id INTEGER REFERENCES cells(id) ON DELETE SET NULL,
    admission_date DATE NOT NULL DEFAULT CURRENT_DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'incarcerated' CHECK (status IN ('incarcerated', 'released', 'transferred', 'deceased', 'escaped')),
    blood_type VARCHAR(5) CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', NULL)),
    emergency_contact_name VARCHAR(200),
    emergency_contact_phone VARCHAR(20),
    notes TEXT,
    photo_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sentences
CREATE TABLE sentences (
    id SERIAL PRIMARY KEY,
    prisoner_id INTEGER NOT NULL REFERENCES prisoners(id) ON DELETE CASCADE,
    crime_type_id INTEGER NOT NULL REFERENCES crime_types(id) ON DELETE RESTRICT,
    sentence_start_date DATE NOT NULL,
    sentence_years INTEGER NOT NULL CHECK (sentence_years >= 0),
    sentence_months INTEGER NOT NULL DEFAULT 0 CHECK (sentence_months BETWEEN 0 AND 11),
    is_life_sentence BOOLEAN NOT NULL DEFAULT false,
    parole_eligible BOOLEAN NOT NULL DEFAULT true,
    parole_date DATE,
    court_name VARCHAR(200) NOT NULL,
    case_number VARCHAR(50) NOT NULL,
    judge_name VARCHAR(200),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_parole_date CHECK (parole_date IS NULL OR parole_date >= sentence_start_date)
);

-- Staff members
CREATE TABLE staff (
    id SERIAL PRIMARY KEY,
    employee_id VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    role_id INTEGER NOT NULL REFERENCES staff_roles(id) ON DELETE RESTRICT,
    date_of_birth DATE NOT NULL CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '18 years'),
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('male', 'female', 'other')),
    hire_date DATE NOT NULL DEFAULT CURRENT_DATE,
    termination_date DATE,
    email VARCHAR(200) UNIQUE,
    phone VARCHAR(20),
    assigned_block_id INTEGER REFERENCES cell_blocks(id) ON DELETE SET NULL,
    salary DECIMAL(10, 2) CHECK (salary > 0),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_termination CHECK (termination_date IS NULL OR termination_date >= hire_date)
);

-- Visitors (people who can visit prisoners)
CREATE TABLE visitors (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL CHECK (date_of_birth <= CURRENT_DATE - INTERVAL '18 years'),
    id_document_type VARCHAR(30) NOT NULL CHECK (id_document_type IN ('passport', 'national_id', 'drivers_license')),
    id_document_number VARCHAR(50) NOT NULL,
    relationship_type VARCHAR(30) NOT NULL CHECK (relationship_type IN ('spouse', 'parent', 'child', 'sibling', 'friend', 'lawyer', 'other')),
    phone VARCHAR(20),
    email VARCHAR(200),
    is_blacklisted BOOLEAN NOT NULL DEFAULT false,
    blacklist_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_visitor_document UNIQUE (id_document_type, id_document_number)
);

-- Visits
CREATE TABLE visits (
    id SERIAL PRIMARY KEY,
    prisoner_id INTEGER NOT NULL REFERENCES prisoners(id) ON DELETE CASCADE,
    visitor_id INTEGER NOT NULL REFERENCES visitors(id) ON DELETE CASCADE,
    visit_date DATE NOT NULL,
    scheduled_start_time TIME NOT NULL,
    scheduled_end_time TIME NOT NULL,
    actual_start_time TIME,
    actual_end_time TIME,
    status VARCHAR(20) NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'cancelled', 'no_show')),
    visit_type VARCHAR(20) NOT NULL DEFAULT 'regular' CHECK (visit_type IN ('regular', 'legal', 'family', 'conjugal')),
    approved_by_staff_id INTEGER REFERENCES staff(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_visit_times CHECK (scheduled_end_time > scheduled_start_time)
);

-- Rehabilitation programs
CREATE TABLE programs (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    program_type_id INTEGER NOT NULL REFERENCES program_types(id) ON DELETE RESTRICT,
    description TEXT,
    duration_weeks INTEGER NOT NULL CHECK (duration_weeks > 0),
    max_participants INTEGER NOT NULL CHECK (max_participants > 0),
    instructor_staff_id INTEGER REFERENCES staff(id) ON DELETE SET NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Prisoner program enrollments (many-to-many)
CREATE TABLE prisoner_programs (
    id SERIAL PRIMARY KEY,
    prisoner_id INTEGER NOT NULL REFERENCES prisoners(id) ON DELETE CASCADE,
    program_id INTEGER NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
    enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    completion_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'enrolled' CHECK (status IN ('enrolled', 'completed', 'dropped', 'expelled')),
    grade VARCHAR(2) CHECK (grade IN ('A', 'B', 'C', 'D', 'F', NULL)),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_prisoner_program UNIQUE (prisoner_id, program_id, enrollment_date),
    CONSTRAINT valid_completion CHECK (completion_date IS NULL OR completion_date >= enrollment_date)
);

-- Disciplinary incidents
CREATE TABLE incidents (
    id SERIAL PRIMARY KEY,
    prisoner_id INTEGER NOT NULL REFERENCES prisoners(id) ON DELETE CASCADE,
    reported_by_staff_id INTEGER REFERENCES staff(id) ON DELETE SET NULL,
    incident_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    incident_type VARCHAR(50) NOT NULL CHECK (incident_type IN ('fight', 'contraband', 'escape_attempt', 'assault_staff', 'property_damage', 'disobedience', 'other')),
    severity VARCHAR(20) NOT NULL CHECK (severity IN ('minor', 'moderate', 'major', 'critical')),
    location VARCHAR(100),
    description TEXT NOT NULL,
    action_taken TEXT,
    solitary_days INTEGER DEFAULT 0 CHECK (solitary_days >= 0),
    is_resolved BOOLEAN NOT NULL DEFAULT false,
    resolved_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_prisoners_status ON prisoners(status);
CREATE INDEX idx_prisoners_cell ON prisoners(cell_id);
CREATE INDEX idx_prisoners_name ON prisoners(last_name, first_name);
CREATE INDEX idx_sentences_prisoner ON sentences(prisoner_id);
CREATE INDEX idx_sentences_dates ON sentences(sentence_start_date);
CREATE INDEX idx_visits_prisoner ON visits(prisoner_id);
CREATE INDEX idx_visits_date ON visits(visit_date);
CREATE INDEX idx_visits_status ON visits(status);
CREATE INDEX idx_incidents_prisoner ON incidents(prisoner_id);
CREATE INDEX idx_incidents_date ON incidents(incident_date);
CREATE INDEX idx_staff_role ON staff(role_id);
CREATE INDEX idx_staff_block ON staff(assigned_block_id);
CREATE INDEX idx_cells_block ON cells(cell_block_id);
CREATE INDEX idx_prisoner_programs_prisoner ON prisoner_programs(prisoner_id);
CREATE INDEX idx_prisoner_programs_program ON prisoner_programs(program_id);
