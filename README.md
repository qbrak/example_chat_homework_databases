# Test project chat's capabilities

This was a test of how well Opus can do mostly by itself.

The model used was Opus 4.5.
The cost of the project in tokens was ~10$ to make the code, and ~$20 to review the code in a customer review loop (annotate -> fix -> annotate ... loop)
The instructions were the instructions for the class project with some additional comments about the technology used.

The project was first planned out by the czat, and the plan is available in [PLAN.md](PLAN.md).

## Prison Management System

A full-stack database application for managing prison operations, built as a project for the "Bazy Danych 2025" (Databases 2025) course.

## Features

- **Prisoner Management**: Track prisoners, their sentences, cell assignments, and release dates
- **Cell & Block Management**: Monitor cell occupancy, capacity, and security levels
- **Staff Management**: Manage prison staff roles and assignments
- **Visit System**: Schedule and track prisoner visits with visitor verification
- **Rehabilitation Programs**: Enroll prisoners in educational and rehabilitation programs
- **Incident Tracking**: Log and track security incidents
- **Release Calculations**: Automatic release date calculation with parole eligibility

## Tech Stack

| Component | Technology |
|-----------|------------|
| Database | PostgreSQL 15 (Docker) |
| Backend | Python 3.11+ with FastAPI |
| Package Manager | UV |
| Frontend | Electron + HTML/CSS/JavaScript |

## Prerequisites

- **Docker** - for running PostgreSQL
- **Python 3.11+** - for the backend
- **UV** - Python package manager ([install](https://docs.astral.sh/uv/getting-started/installation/))
- **Node.js 18+** - for Electron frontend

## Quick Start

### Linux/macOS

```bash
# Clone the repository
git clone git@github.com:qbrak/example_chat_homework_databases.git
cd example_chat_homework_databases

# Start everything (database, backend, frontend)
./start.sh
```

### Windows (PowerShell - Recommended)

```powershell
# Clone the repository
git clone git@github.com:qbrak/example_chat_homework_databases.git
cd example_chat_homework_databases

# Start everything
.\start.ps1
```

### Windows (CMD)

```cmd
start.bat
```

## What the Start Script Does

1. Starts PostgreSQL in a Docker container
2. Waits for the database to be ready
3. Initializes the schema, views, functions, and seed data
4. Starts the FastAPI backend server
5. Installs frontend dependencies and launches Electron

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `localhost` | Database host |
| `DB_PORT` | `5432` | Database port |
| `DB_NAME` | `prison_management` | Database name |
| `DB_USER` | `prison_admin` | Database user |
| `DB_PASSWORD` | *required* | Database password |
| `CORS_ORIGINS` | `http://localhost:*` | Allowed CORS origins (comma-separated) |
| `API_URL` | `http://localhost:8000` | Backend API URL (for frontend) |

## Database Reset

To drop all data and recreate the database with fresh seed data:

```bash
# Linux/macOS
./reset_database.sh

# Windows PowerShell
.\reset_database.ps1

# Windows CMD
reset_database.bat
```

## Project Structure

```
piotrek/
├── database/
│   ├── 01_schema.sql      # Tables and constraints
│   ├── 02_views.sql       # Database views
│   ├── 03_functions.sql   # Functions and triggers
│   └── 04_seed_data.sql   # Sample data (50+ prisoners)
├── backend/
│   ├── server.py          # FastAPI application
│   └── pyproject.toml     # Python dependencies
├── frontend/
│   ├── main.js            # Electron main process
│   ├── preload.js         # Electron preload script
│   ├── index.html         # Main HTML
│   ├── renderer/
│   │   ├── app.js         # Frontend application logic
│   │   └── styles.css     # Styling
│   └── package.json       # Node dependencies
├── start.sh               # Unix startup script
├── start.bat              # Windows CMD startup script
├── start.ps1              # Windows PowerShell startup script
├── reset_database.sh      # Unix database reset
├── reset_database.bat     # Windows CMD database reset
└── reset_database.ps1     # Windows PowerShell database reset
```

## Database Schema

### Tables (13 total)

| Table | Description |
|-------|-------------|
| `crime_types` | Enumeration of crime categories |
| `staff_roles` | Enumeration of staff positions |
| `program_types` | Enumeration of rehabilitation programs |
| `cell_blocks` | Prison blocks with security levels |
| `cells` | Individual cells with capacity |
| `staff` | Prison employees |
| `prisoners` | Prisoner records |
| `sentences` | Sentence details with parole info |
| `visitors` | Registered visitors |
| `visits` | Visit records |
| `programs` | Available rehabilitation programs |
| `prisoner_programs` | Program enrollments (many-to-many) |
| `incidents` | Security incidents |

### Views (5 total)

- `v_prisoner_details` - Complete prisoner info with cell and sentence
- `v_cell_occupancy` - Cell status with current/max occupancy
- `v_upcoming_releases` - Prisoners releasing within 30 days
- `v_block_summary` - Block statistics (occupancy, incidents)
- `v_staff_overview` - Staff by role and block assignment

### Functions & Triggers

- `calculate_release_date()` - Computes release date from sentence
- `get_prisoner_full_history()` - Returns prisoner's complete record
- `get_cell_occupancy()` - Returns occupancy for a specific cell
- `transfer_prisoner()` - Safely transfers prisoner between cells
- `trg_check_cell_capacity` - Prevents cell overcrowding
- `trg_check_visitor_blacklist` - Blocks blacklisted visitors
- `trg_update_timestamp` - Auto-updates `updated_at` columns

## API Endpoints

### Prisoners
- `GET /prisoners` - List all prisoners
- `GET /prisoners/{id}` - Get prisoner details
- `POST /prisoners` - Add new prisoner
- `PUT /prisoners/{id}` - Update prisoner
- `DELETE /prisoners/{id}` - Delete prisoner

### Views
- `GET /views/{view_name}` - Query database views
  - `prisoner_details`
  - `cell_occupancy`
  - `upcoming_releases`
  - `block_summary`
  - `staff_overview`

### Other Resources
- `GET /cells` - List cells
- `GET /staff` - List staff
- `GET /visitors` - List visitors
- `GET /visits` - List visits
- `GET /programs` - List programs
- `GET /incidents` - List incidents

## Course Requirements Met

| Requirement | Implementation |
|-------------|----------------|
| 10-12 tables | 13 tables |
| Integrity constraints | CHECK, NOT NULL, UNIQUE, FK |
| 1-to-many relationships | prisoners-sentences, cells-prisoners |
| Many-to-many relationships | prisoner_programs |
| Foreign key actions | CASCADE, RESTRICT, SET NULL |
| Enumeration tables | crime_types, staff_roles, program_types |
| 2+ functions/triggers | 4 functions, 3 triggers |
| 2+ non-trivial views | 5 views |
| GUI without SQL | Electron desktop app |
| CRUD operations | Full support via API |
| Pre-populated data | 50 prisoners, 100+ visits, etc. |

## License

This project was created for educational purposes as part of the Databases 2025 course.
