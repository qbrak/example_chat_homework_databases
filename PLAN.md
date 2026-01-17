# Prison Database Project Plan

## Project Overview
A prison management database system with PostgreSQL backend, Node.js/Express API, and Electron frontend.

---

## Database Schema (11 tables)

### Enumeration Tables
1. **crime_types** - Types of crimes (theft, assault, fraud, etc.)
2. **staff_roles** - Guard, warden, medical, administrative, etc.
3. **program_types** - Education, therapy, vocational, etc.

### Core Tables
4. **cell_blocks** - Prison wings/sections
5. **cells** - Individual cells (belongs to cell_block)
6. **prisoners** - Main prisoner records (assigned to cell)
7. **sentences** - Sentence records (linked to prisoner and crime_type)
8. **staff** - Prison employees (linked to staff_role)
9. **visitors** - People who can visit prisoners
10. **visits** - Visit records (links prisoner and visitor)
11. **programs** - Rehabilitation programs available
12. **prisoner_programs** - Junction table for many-to-many (prisoner ↔ program)
13. **incidents** - Disciplinary incidents (linked to prisoner, optionally staff)

**Total: 13 tables** (slightly above target, but justified for a prison system)

### Relationships
- **1-to-many**: cell_blocks→cells, cells→prisoners, prisoners→sentences, prisoners→visits, prisoners→incidents
- **many-to-many**: prisoners↔programs (via prisoner_programs)
- **Enumeration references**: sentences→crime_types, staff→staff_roles, programs→program_types

### Integrity Constraints
- CHECK: age >= 18, capacity > 0, sentence_years > 0, dates valid
- UNIQUE: prisoner number, cell code, staff employee_id
- NOT NULL: critical fields like names, dates, foreign keys
- Foreign key actions: ON DELETE RESTRICT/CASCADE as appropriate

---

## Views (3 views)

1. **v_prisoner_details** - Full prisoner info with cell, block, current sentence, crime
2. **v_cell_occupancy** - Cell capacity vs current occupancy per block
3. **v_upcoming_releases** - Prisoners releasing within next 6 months

---

## Procedural SQL (3 items)

1. **Function: calculate_release_date(prisoner_id)** - Calculates expected release based on sentence
2. **Function: get_prisoner_full_history(prisoner_id)** - Returns JSON with all prisoner data
3. **Trigger: check_cell_capacity** - Prevents over-assigning cells beyond capacity

---

## Implementation Tasks

### Phase 1: Infrastructure Setup
- [ ] 1.1 Create project directory structure
- [ ] 1.2 Create Docker Compose for PostgreSQL
- [ ] 1.3 Create database initialization SQL script (schema)
- [ ] 1.4 Create data population SQL script (sample data)
- [ ] 1.5 Create master startup script (start.sh)

### Phase 2: Database Implementation
- [ ] 2.1 Create enumeration tables (crime_types, staff_roles, program_types)
- [ ] 2.2 Create core tables (cell_blocks, cells, prisoners, sentences)
- [ ] 2.3 Create relationship tables (staff, visitors, visits)
- [ ] 2.4 Create many-to-many junction (programs, prisoner_programs, incidents)
- [ ] 2.5 Create views (v_prisoner_details, v_cell_occupancy, v_upcoming_releases)
- [ ] 2.6 Create functions and triggers

### Phase 3: Backend API
- [ ] 3.1 Initialize Node.js project with Express
- [ ] 3.2 Set up PostgreSQL connection (pg library)
- [ ] 3.3 Create CRUD endpoints for all main entities
- [ ] 3.4 Create endpoints for views
- [ ] 3.5 Create search/filter endpoints

### Phase 4: Electron Frontend
- [ ] 4.1 Initialize Electron project
- [ ] 4.2 Create main window and navigation
- [ ] 4.3 Create Prisoners management page (list, add, edit, delete)
- [ ] 4.4 Create Cells management page
- [ ] 4.5 Create Visits management page
- [ ] 4.6 Create Reports/Views page (showing the SQL views)
- [ ] 4.7 Create Staff management page
- [ ] 4.8 Create Programs/Incidents pages

### Phase 5: Sample Data & Polish
- [ ] 5.1 Generate realistic sample data (50+ prisoners, etc.)
- [ ] 5.2 Test all CRUD operations
- [ ] 5.3 Final integration testing

---

## File Structure

```
piotrek/
├── docker-compose.yml          # PostgreSQL container
├── start.sh                    # Master startup script
├── database/
│   ├── 01_schema.sql          # Table definitions
│   ├── 02_views.sql           # Views
│   ├── 03_functions.sql       # Functions and triggers
│   └── 04_seed_data.sql       # Sample data
├── backend/
│   ├── package.json
│   ├── server.js              # Express server
│   └── routes/
│       ├── prisoners.js
│       ├── cells.js
│       ├── visits.js
│       ├── staff.js
│       ├── programs.js
│       └── views.js
└── frontend/
    ├── package.json
    ├── main.js                # Electron main process
    ├── preload.js
    └── renderer/
        ├── index.html
        ├── styles.css
        └── app.js
```

---

## Sample Data Quantities
- 3 cell blocks, 20 cells
- 50 prisoners
- 10 crime types
- 5 staff roles, 15 staff members
- 30 visitors
- 100 visits
- 8 programs
- 60 program enrollments
- 25 incidents
- Multiple sentences per some prisoners

---

## Technical Decisions

1. **Why Electron?** - Requested by user, provides desktop GUI without SQL knowledge
2. **Why Express?** - Lightweight, good PostgreSQL integration
3. **Why Docker?** - Easy PostgreSQL setup, reproducible environment
4. **Foreign key actions:**
   - ON DELETE RESTRICT for prisoners (preserve history)
   - ON DELETE CASCADE for prisoner_programs (if prisoner deleted, remove enrollments)
   - ON DELETE SET NULL for incidents.reported_by_staff_id (keep incident if staff leaves)
