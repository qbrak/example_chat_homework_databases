"""
Prison Management System - FastAPI Backend
"""

from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from typing import Optional
import json

# Database connection settings
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "5432"),
    "database": os.getenv("DB_NAME", "prison_management"),
    "user": os.getenv("DB_USER", "prison_admin"),
    "password": os.getenv("DB_PASSWORD", "prison_secure_pwd_2025"),
}


def get_db_connection():
    """Create a new database connection."""
    return psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: test database connection
    try:
        conn = get_db_connection()
        conn.close()
        print("Database connection successful")
    except Exception as e:
        print(f"Warning: Could not connect to database: {e}")
    yield
    # Shutdown: cleanup if needed
    pass


app = FastAPI(
    title="Prison Management System",
    description="API for managing prison database",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS middleware for Electron frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================
# PRISONERS ENDPOINTS
# ============================================


@app.get("/api/prisoners")
def get_prisoners(
    status: Optional[str] = None,
    search: Optional[str] = None,
    limit: int = Query(100, le=1000),
    offset: int = 0,
):
    """Get all prisoners with optional filtering."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        query = """
            SELECT p.*, c.cell_code, cb.name as block_name
            FROM prisoners p
            LEFT JOIN cells c ON p.cell_id = c.id
            LEFT JOIN cell_blocks cb ON c.cell_block_id = cb.id
            WHERE 1=1
        """
        params = []

        if status:
            query += " AND p.status = %s"
            params.append(status)

        if search:
            query += " AND (p.first_name ILIKE %s OR p.last_name ILIKE %s OR p.prisoner_number ILIKE %s)"
            search_param = f"%{search}%"
            params.extend([search_param, search_param, search_param])

        query += " ORDER BY p.last_name, p.first_name LIMIT %s OFFSET %s"
        params.extend([limit, offset])

        cur.execute(query, params)
        prisoners = cur.fetchall()

        # Get total count
        count_query = "SELECT COUNT(*) FROM prisoners WHERE 1=1"
        count_params = []
        if status:
            count_query += " AND status = %s"
            count_params.append(status)
        if search:
            count_query += " AND (first_name ILIKE %s OR last_name ILIKE %s OR prisoner_number ILIKE %s)"
            count_params.extend([f"%{search}%", f"%{search}%", f"%{search}%"])

        cur.execute(count_query, count_params)
        total = cur.fetchone()["count"]

        return {"data": prisoners, "total": total, "limit": limit, "offset": offset}
    finally:
        conn.close()


@app.get("/api/prisoners/{prisoner_id}")
def get_prisoner(prisoner_id: int):
    """Get a single prisoner by ID."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT p.*, c.cell_code, cb.name as block_name
            FROM prisoners p
            LEFT JOIN cells c ON p.cell_id = c.id
            LEFT JOIN cell_blocks cb ON c.cell_block_id = cb.id
            WHERE p.id = %s
        """,
            (prisoner_id,),
        )
        prisoner = cur.fetchone()
        if not prisoner:
            raise HTTPException(status_code=404, detail="Prisoner not found")
        return prisoner
    finally:
        conn.close()


@app.post("/api/prisoners")
def create_prisoner(prisoner: dict):
    """Create a new prisoner."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO prisoners (
                prisoner_number, first_name, last_name, date_of_birth,
                gender, nationality, cell_id, admission_date, status,
                blood_type, emergency_contact_name, emergency_contact_phone, notes
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING *
        """,
            (
                prisoner.get("prisoner_number"),
                prisoner.get("first_name"),
                prisoner.get("last_name"),
                prisoner.get("date_of_birth"),
                prisoner.get("gender"),
                prisoner.get("nationality"),
                prisoner.get("cell_id"),
                prisoner.get("admission_date"),
                prisoner.get("status", "incarcerated"),
                prisoner.get("blood_type"),
                prisoner.get("emergency_contact_name"),
                prisoner.get("emergency_contact_phone"),
                prisoner.get("notes"),
            ),
        )
        new_prisoner = cur.fetchone()
        conn.commit()
        return new_prisoner
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.put("/api/prisoners/{prisoner_id}")
def update_prisoner(prisoner_id: int, prisoner: dict):
    """Update a prisoner."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            UPDATE prisoners SET
                first_name = COALESCE(%s, first_name),
                last_name = COALESCE(%s, last_name),
                date_of_birth = COALESCE(%s, date_of_birth),
                gender = COALESCE(%s, gender),
                nationality = COALESCE(%s, nationality),
                cell_id = %s,
                status = COALESCE(%s, status),
                blood_type = %s,
                emergency_contact_name = %s,
                emergency_contact_phone = %s,
                notes = %s
            WHERE id = %s
            RETURNING *
        """,
            (
                prisoner.get("first_name"),
                prisoner.get("last_name"),
                prisoner.get("date_of_birth"),
                prisoner.get("gender"),
                prisoner.get("nationality"),
                prisoner.get("cell_id"),
                prisoner.get("status"),
                prisoner.get("blood_type"),
                prisoner.get("emergency_contact_name"),
                prisoner.get("emergency_contact_phone"),
                prisoner.get("notes"),
                prisoner_id,
            ),
        )
        updated = cur.fetchone()
        if not updated:
            raise HTTPException(status_code=404, detail="Prisoner not found")
        conn.commit()
        return updated
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.delete("/api/prisoners/{prisoner_id}")
def delete_prisoner(prisoner_id: int):
    """Delete a prisoner."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM prisoners WHERE id = %s RETURNING id", (prisoner_id,))
        deleted = cur.fetchone()
        if not deleted:
            raise HTTPException(status_code=404, detail="Prisoner not found")
        conn.commit()
        return {"message": "Prisoner deleted", "id": prisoner_id}
    finally:
        conn.close()


@app.get("/api/prisoners/{prisoner_id}/history")
def get_prisoner_history(prisoner_id: int):
    """Get full history of a prisoner using the stored function."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT get_prisoner_full_history(%s) as history", (prisoner_id,))
        result = cur.fetchone()
        if not result or not result["history"]:
            raise HTTPException(status_code=404, detail="Prisoner not found")
        return result["history"]
    finally:
        conn.close()


# ============================================
# CELLS ENDPOINTS
# ============================================


@app.get("/api/cells")
def get_cells(block_id: Optional[int] = None, available_only: bool = False):
    """Get all cells with optional filtering."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        query = """
            SELECT c.*, cb.name as block_name, cb.security_level,
                   (SELECT COUNT(*) FROM prisoners p WHERE p.cell_id = c.id AND p.status = 'incarcerated') as current_occupancy
            FROM cells c
            JOIN cell_blocks cb ON c.cell_block_id = cb.id
            WHERE 1=1
        """
        params = []

        if block_id:
            query += " AND c.cell_block_id = %s"
            params.append(block_id)

        if available_only:
            query += """ AND c.capacity > (
                SELECT COUNT(*) FROM prisoners p WHERE p.cell_id = c.id AND p.status = 'incarcerated'
            )"""

        query += " ORDER BY cb.name, c.cell_code"
        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()


@app.get("/api/cells/{cell_id}")
def get_cell(cell_id: int):
    """Get a single cell by ID."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT c.*, cb.name as block_name, cb.security_level,
                   (SELECT COUNT(*) FROM prisoners p WHERE p.cell_id = c.id AND p.status = 'incarcerated') as current_occupancy
            FROM cells c
            JOIN cell_blocks cb ON c.cell_block_id = cb.id
            WHERE c.id = %s
        """,
            (cell_id,),
        )
        cell = cur.fetchone()
        if not cell:
            raise HTTPException(status_code=404, detail="Cell not found")
        return cell
    finally:
        conn.close()


@app.post("/api/cells")
def create_cell(cell: dict):
    """Create a new cell."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO cells (cell_code, cell_block_id, floor_number, capacity, cell_type, has_window)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING *
        """,
            (
                cell.get("cell_code"),
                cell.get("cell_block_id"),
                cell.get("floor_number"),
                cell.get("capacity", 1),
                cell.get("cell_type", "standard"),
                cell.get("has_window", True),
            ),
        )
        new_cell = cur.fetchone()
        conn.commit()
        return new_cell
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.put("/api/cells/{cell_id}")
def update_cell(cell_id: int, cell: dict):
    """Update a cell."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            UPDATE cells SET
                cell_code = COALESCE(%s, cell_code),
                cell_block_id = COALESCE(%s, cell_block_id),
                floor_number = COALESCE(%s, floor_number),
                capacity = COALESCE(%s, capacity),
                cell_type = COALESCE(%s, cell_type),
                has_window = COALESCE(%s, has_window)
            WHERE id = %s
            RETURNING *
        """,
            (
                cell.get("cell_code"),
                cell.get("cell_block_id"),
                cell.get("floor_number"),
                cell.get("capacity"),
                cell.get("cell_type"),
                cell.get("has_window"),
                cell_id,
            ),
        )
        updated = cur.fetchone()
        if not updated:
            raise HTTPException(status_code=404, detail="Cell not found")
        conn.commit()
        return updated
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.delete("/api/cells/{cell_id}")
def delete_cell(cell_id: int):
    """Delete a cell."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM cells WHERE id = %s RETURNING id", (cell_id,))
        deleted = cur.fetchone()
        if not deleted:
            raise HTTPException(status_code=404, detail="Cell not found")
        conn.commit()
        return {"message": "Cell deleted", "id": cell_id}
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


# ============================================
# CELL BLOCKS ENDPOINTS
# ============================================


@app.get("/api/cell-blocks")
def get_cell_blocks():
    """Get all cell blocks."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("""
            SELECT cb.*,
                   (SELECT COUNT(*) FROM cells c WHERE c.cell_block_id = cb.id) as total_cells,
                   (SELECT COUNT(*) FROM prisoners p
                    JOIN cells c ON p.cell_id = c.id
                    WHERE c.cell_block_id = cb.id AND p.status = 'incarcerated') as current_prisoners
            FROM cell_blocks cb
            ORDER BY cb.name
        """)
        return cur.fetchall()
    finally:
        conn.close()


@app.post("/api/cell-blocks")
def create_cell_block(block: dict):
    """Create a new cell block."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO cell_blocks (name, security_level, capacity, floor_count, description)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING *
        """,
            (
                block.get("name"),
                block.get("security_level"),
                block.get("capacity"),
                block.get("floor_count"),
                block.get("description"),
            ),
        )
        new_block = cur.fetchone()
        conn.commit()
        return new_block
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


# ============================================
# STAFF ENDPOINTS
# ============================================


@app.get("/api/staff")
def get_staff(role_id: Optional[int] = None, active_only: bool = True):
    """Get all staff members."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        query = """
            SELECT s.*, sr.name as role_name, sr.access_level, cb.name as block_name
            FROM staff s
            JOIN staff_roles sr ON s.role_id = sr.id
            LEFT JOIN cell_blocks cb ON s.assigned_block_id = cb.id
            WHERE 1=1
        """
        params = []

        if role_id:
            query += " AND s.role_id = %s"
            params.append(role_id)

        if active_only:
            query += " AND s.is_active = true"

        query += " ORDER BY s.last_name, s.first_name"
        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()


@app.get("/api/staff/{staff_id}")
def get_staff_member(staff_id: int):
    """Get a single staff member."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT s.*, sr.name as role_name, sr.access_level, cb.name as block_name
            FROM staff s
            JOIN staff_roles sr ON s.role_id = sr.id
            LEFT JOIN cell_blocks cb ON s.assigned_block_id = cb.id
            WHERE s.id = %s
        """,
            (staff_id,),
        )
        staff = cur.fetchone()
        if not staff:
            raise HTTPException(status_code=404, detail="Staff member not found")
        return staff
    finally:
        conn.close()


@app.post("/api/staff")
def create_staff(staff: dict):
    """Create a new staff member."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO staff (
                employee_id, first_name, last_name, role_id, date_of_birth,
                gender, hire_date, email, phone, assigned_block_id, salary, is_active
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING *
        """,
            (
                staff.get("employee_id"),
                staff.get("first_name"),
                staff.get("last_name"),
                staff.get("role_id"),
                staff.get("date_of_birth"),
                staff.get("gender"),
                staff.get("hire_date"),
                staff.get("email"),
                staff.get("phone"),
                staff.get("assigned_block_id"),
                staff.get("salary"),
                staff.get("is_active", True),
            ),
        )
        new_staff = cur.fetchone()
        conn.commit()
        return new_staff
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.put("/api/staff/{staff_id}")
def update_staff(staff_id: int, staff: dict):
    """Update a staff member."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            UPDATE staff SET
                first_name = COALESCE(%s, first_name),
                last_name = COALESCE(%s, last_name),
                role_id = COALESCE(%s, role_id),
                email = %s,
                phone = %s,
                assigned_block_id = %s,
                salary = %s,
                is_active = COALESCE(%s, is_active)
            WHERE id = %s
            RETURNING *
        """,
            (
                staff.get("first_name"),
                staff.get("last_name"),
                staff.get("role_id"),
                staff.get("email"),
                staff.get("phone"),
                staff.get("assigned_block_id"),
                staff.get("salary"),
                staff.get("is_active"),
                staff_id,
            ),
        )
        updated = cur.fetchone()
        if not updated:
            raise HTTPException(status_code=404, detail="Staff member not found")
        conn.commit()
        return updated
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.delete("/api/staff/{staff_id}")
def delete_staff(staff_id: int):
    """Delete a staff member."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM staff WHERE id = %s RETURNING id", (staff_id,))
        deleted = cur.fetchone()
        if not deleted:
            raise HTTPException(status_code=404, detail="Staff member not found")
        conn.commit()
        return {"message": "Staff member deleted", "id": staff_id}
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


# ============================================
# VISITS ENDPOINTS
# ============================================


@app.get("/api/visits")
def get_visits(
    prisoner_id: Optional[int] = None,
    status: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    limit: int = Query(100, le=1000),
    offset: int = 0,
):
    """Get all visits with optional filtering."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        query = """
            SELECT v.*,
                   p.prisoner_number, p.first_name as prisoner_first_name, p.last_name as prisoner_last_name,
                   vr.first_name as visitor_first_name, vr.last_name as visitor_last_name, vr.relationship_type
            FROM visits v
            JOIN prisoners p ON v.prisoner_id = p.id
            JOIN visitors vr ON v.visitor_id = vr.id
            WHERE 1=1
        """
        params = []

        if prisoner_id:
            query += " AND v.prisoner_id = %s"
            params.append(prisoner_id)

        if status:
            query += " AND v.status = %s"
            params.append(status)

        if date_from:
            query += " AND v.visit_date >= %s"
            params.append(date_from)

        if date_to:
            query += " AND v.visit_date <= %s"
            params.append(date_to)

        query += " ORDER BY v.visit_date DESC, v.scheduled_start_time LIMIT %s OFFSET %s"
        params.extend([limit, offset])

        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()


@app.post("/api/visits")
def create_visit(visit: dict):
    """Create a new visit."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO visits (
                prisoner_id, visitor_id, visit_date, scheduled_start_time,
                scheduled_end_time, status, visit_type, approved_by_staff_id, notes
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING *
        """,
            (
                visit.get("prisoner_id"),
                visit.get("visitor_id"),
                visit.get("visit_date"),
                visit.get("scheduled_start_time"),
                visit.get("scheduled_end_time"),
                visit.get("status", "scheduled"),
                visit.get("visit_type", "regular"),
                visit.get("approved_by_staff_id"),
                visit.get("notes"),
            ),
        )
        new_visit = cur.fetchone()
        conn.commit()
        return new_visit
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.put("/api/visits/{visit_id}")
def update_visit(visit_id: int, visit: dict):
    """Update a visit."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            UPDATE visits SET
                visit_date = COALESCE(%s, visit_date),
                scheduled_start_time = COALESCE(%s, scheduled_start_time),
                scheduled_end_time = COALESCE(%s, scheduled_end_time),
                actual_start_time = %s,
                actual_end_time = %s,
                status = COALESCE(%s, status),
                visit_type = COALESCE(%s, visit_type),
                notes = %s
            WHERE id = %s
            RETURNING *
        """,
            (
                visit.get("visit_date"),
                visit.get("scheduled_start_time"),
                visit.get("scheduled_end_time"),
                visit.get("actual_start_time"),
                visit.get("actual_end_time"),
                visit.get("status"),
                visit.get("visit_type"),
                visit.get("notes"),
                visit_id,
            ),
        )
        updated = cur.fetchone()
        if not updated:
            raise HTTPException(status_code=404, detail="Visit not found")
        conn.commit()
        return updated
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.delete("/api/visits/{visit_id}")
def delete_visit(visit_id: int):
    """Delete a visit."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM visits WHERE id = %s RETURNING id", (visit_id,))
        deleted = cur.fetchone()
        if not deleted:
            raise HTTPException(status_code=404, detail="Visit not found")
        conn.commit()
        return {"message": "Visit deleted", "id": visit_id}
    finally:
        conn.close()


# ============================================
# VISITORS ENDPOINTS
# ============================================


@app.get("/api/visitors")
def get_visitors(search: Optional[str] = None, blacklisted: Optional[bool] = None):
    """Get all visitors."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        query = "SELECT * FROM visitors WHERE 1=1"
        params = []

        if search:
            query += " AND (first_name ILIKE %s OR last_name ILIKE %s)"
            params.extend([f"%{search}%", f"%{search}%"])

        if blacklisted is not None:
            query += " AND is_blacklisted = %s"
            params.append(blacklisted)

        query += " ORDER BY last_name, first_name"
        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()


@app.post("/api/visitors")
def create_visitor(visitor: dict):
    """Create a new visitor."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO visitors (
                first_name, last_name, date_of_birth, id_document_type,
                id_document_number, relationship_type, phone, email
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING *
        """,
            (
                visitor.get("first_name"),
                visitor.get("last_name"),
                visitor.get("date_of_birth"),
                visitor.get("id_document_type"),
                visitor.get("id_document_number"),
                visitor.get("relationship_type"),
                visitor.get("phone"),
                visitor.get("email"),
            ),
        )
        new_visitor = cur.fetchone()
        conn.commit()
        return new_visitor
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.put("/api/visitors/{visitor_id}")
def update_visitor(visitor_id: int, visitor: dict):
    """Update a visitor."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            UPDATE visitors SET
                first_name = COALESCE(%s, first_name),
                last_name = COALESCE(%s, last_name),
                phone = %s,
                email = %s,
                is_blacklisted = COALESCE(%s, is_blacklisted),
                blacklist_reason = %s
            WHERE id = %s
            RETURNING *
        """,
            (
                visitor.get("first_name"),
                visitor.get("last_name"),
                visitor.get("phone"),
                visitor.get("email"),
                visitor.get("is_blacklisted"),
                visitor.get("blacklist_reason"),
                visitor_id,
            ),
        )
        updated = cur.fetchone()
        if not updated:
            raise HTTPException(status_code=404, detail="Visitor not found")
        conn.commit()
        return updated
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.delete("/api/visitors/{visitor_id}")
def delete_visitor(visitor_id: int):
    """Delete a visitor."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM visitors WHERE id = %s RETURNING id", (visitor_id,))
        deleted = cur.fetchone()
        if not deleted:
            raise HTTPException(status_code=404, detail="Visitor not found")
        conn.commit()
        return {"message": "Visitor deleted", "id": visitor_id}
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


# ============================================
# SENTENCES ENDPOINTS
# ============================================


@app.get("/api/sentences")
def get_sentences(prisoner_id: Optional[int] = None):
    """Get all sentences."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        query = """
            SELECT s.*, ct.name as crime_name, ct.severity_level,
                   p.prisoner_number, p.first_name, p.last_name
            FROM sentences s
            JOIN crime_types ct ON s.crime_type_id = ct.id
            JOIN prisoners p ON s.prisoner_id = p.id
        """
        params = []

        if prisoner_id:
            query += " WHERE s.prisoner_id = %s"
            params.append(prisoner_id)

        query += " ORDER BY s.sentence_start_date DESC"
        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()


@app.post("/api/sentences")
def create_sentence(sentence: dict):
    """Create a new sentence."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO sentences (
                prisoner_id, crime_type_id, sentence_start_date, sentence_years,
                sentence_months, is_life_sentence, parole_eligible, parole_date,
                court_name, case_number, judge_name, notes
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING *
        """,
            (
                sentence.get("prisoner_id"),
                sentence.get("crime_type_id"),
                sentence.get("sentence_start_date"),
                sentence.get("sentence_years"),
                sentence.get("sentence_months", 0),
                sentence.get("is_life_sentence", False),
                sentence.get("parole_eligible", True),
                sentence.get("parole_date"),
                sentence.get("court_name"),
                sentence.get("case_number"),
                sentence.get("judge_name"),
                sentence.get("notes"),
            ),
        )
        new_sentence = cur.fetchone()
        conn.commit()
        return new_sentence
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.delete("/api/sentences/{sentence_id}")
def delete_sentence(sentence_id: int):
    """Delete a sentence."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM sentences WHERE id = %s RETURNING id", (sentence_id,))
        deleted = cur.fetchone()
        if not deleted:
            raise HTTPException(status_code=404, detail="Sentence not found")
        conn.commit()
        return {"message": "Sentence deleted", "id": sentence_id}
    finally:
        conn.close()


# ============================================
# PROGRAMS ENDPOINTS
# ============================================


@app.get("/api/programs")
def get_programs(active_only: bool = True):
    """Get all programs."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        query = """
            SELECT p.*, pt.name as type_name,
                   s.first_name as instructor_first_name, s.last_name as instructor_last_name,
                   (SELECT COUNT(*) FROM prisoner_programs pp WHERE pp.program_id = p.id AND pp.status = 'enrolled') as current_enrolled
            FROM programs p
            JOIN program_types pt ON p.program_type_id = pt.id
            LEFT JOIN staff s ON p.instructor_staff_id = s.id
        """
        if active_only:
            query += " WHERE p.is_active = true"
        query += " ORDER BY p.name"
        cur.execute(query)
        return cur.fetchall()
    finally:
        conn.close()


@app.post("/api/programs")
def create_program(program: dict):
    """Create a new program."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO programs (
                name, program_type_id, description, duration_weeks,
                max_participants, instructor_staff_id, is_active
            ) VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING *
        """,
            (
                program.get("name"),
                program.get("program_type_id"),
                program.get("description"),
                program.get("duration_weeks"),
                program.get("max_participants"),
                program.get("instructor_staff_id"),
                program.get("is_active", True),
            ),
        )
        new_program = cur.fetchone()
        conn.commit()
        return new_program
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.get("/api/prisoner-programs")
def get_prisoner_programs(prisoner_id: Optional[int] = None, program_id: Optional[int] = None):
    """Get prisoner program enrollments."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        query = """
            SELECT pp.*, p.name as program_name, pt.name as program_type,
                   pr.prisoner_number, pr.first_name, pr.last_name
            FROM prisoner_programs pp
            JOIN programs p ON pp.program_id = p.id
            JOIN program_types pt ON p.program_type_id = pt.id
            JOIN prisoners pr ON pp.prisoner_id = pr.id
            WHERE 1=1
        """
        params = []

        if prisoner_id:
            query += " AND pp.prisoner_id = %s"
            params.append(prisoner_id)

        if program_id:
            query += " AND pp.program_id = %s"
            params.append(program_id)

        query += " ORDER BY pp.enrollment_date DESC"
        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()


@app.post("/api/prisoner-programs")
def enroll_prisoner(enrollment: dict):
    """Enroll a prisoner in a program."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO prisoner_programs (prisoner_id, program_id, enrollment_date, status, notes)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING *
        """,
            (
                enrollment.get("prisoner_id"),
                enrollment.get("program_id"),
                enrollment.get("enrollment_date"),
                enrollment.get("status", "enrolled"),
                enrollment.get("notes"),
            ),
        )
        new_enrollment = cur.fetchone()
        conn.commit()
        return new_enrollment
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.put("/api/prisoner-programs/{enrollment_id}")
def update_enrollment(enrollment_id: int, enrollment: dict):
    """Update a program enrollment."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            UPDATE prisoner_programs SET
                status = COALESCE(%s, status),
                completion_date = %s,
                grade = %s,
                notes = %s
            WHERE id = %s
            RETURNING *
        """,
            (
                enrollment.get("status"),
                enrollment.get("completion_date"),
                enrollment.get("grade"),
                enrollment.get("notes"),
                enrollment_id,
            ),
        )
        updated = cur.fetchone()
        if not updated:
            raise HTTPException(status_code=404, detail="Enrollment not found")
        conn.commit()
        return updated
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


# ============================================
# INCIDENTS ENDPOINTS
# ============================================


@app.get("/api/incidents")
def get_incidents(
    prisoner_id: Optional[int] = None,
    severity: Optional[str] = None,
    resolved: Optional[bool] = None,
    limit: int = Query(100, le=1000),
    offset: int = 0,
):
    """Get all incidents."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        query = """
            SELECT i.*, p.prisoner_number, p.first_name, p.last_name,
                   s.employee_id as reporter_employee_id,
                   s.first_name as reporter_first_name, s.last_name as reporter_last_name
            FROM incidents i
            JOIN prisoners p ON i.prisoner_id = p.id
            LEFT JOIN staff s ON i.reported_by_staff_id = s.id
            WHERE 1=1
        """
        params = []

        if prisoner_id:
            query += " AND i.prisoner_id = %s"
            params.append(prisoner_id)

        if severity:
            query += " AND i.severity = %s"
            params.append(severity)

        if resolved is not None:
            query += " AND i.is_resolved = %s"
            params.append(resolved)

        query += " ORDER BY i.incident_date DESC LIMIT %s OFFSET %s"
        params.extend([limit, offset])

        cur.execute(query, params)
        return cur.fetchall()
    finally:
        conn.close()


@app.post("/api/incidents")
def create_incident(incident: dict):
    """Create a new incident."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO incidents (
                prisoner_id, reported_by_staff_id, incident_date, incident_type,
                severity, location, description, action_taken, solitary_days
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING *
        """,
            (
                incident.get("prisoner_id"),
                incident.get("reported_by_staff_id"),
                incident.get("incident_date"),
                incident.get("incident_type"),
                incident.get("severity"),
                incident.get("location"),
                incident.get("description"),
                incident.get("action_taken"),
                incident.get("solitary_days", 0),
            ),
        )
        new_incident = cur.fetchone()
        conn.commit()
        return new_incident
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.put("/api/incidents/{incident_id}")
def update_incident(incident_id: int, incident: dict):
    """Update an incident."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            UPDATE incidents SET
                incident_type = COALESCE(%s, incident_type),
                severity = COALESCE(%s, severity),
                location = %s,
                description = COALESCE(%s, description),
                action_taken = %s,
                solitary_days = COALESCE(%s, solitary_days),
                is_resolved = COALESCE(%s, is_resolved),
                resolved_date = %s
            WHERE id = %s
            RETURNING *
        """,
            (
                incident.get("incident_type"),
                incident.get("severity"),
                incident.get("location"),
                incident.get("description"),
                incident.get("action_taken"),
                incident.get("solitary_days"),
                incident.get("is_resolved"),
                incident.get("resolved_date"),
                incident_id,
            ),
        )
        updated = cur.fetchone()
        if not updated:
            raise HTTPException(status_code=404, detail="Incident not found")
        conn.commit()
        return updated
    except psycopg2.Error as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        conn.close()


@app.delete("/api/incidents/{incident_id}")
def delete_incident(incident_id: int):
    """Delete an incident."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM incidents WHERE id = %s RETURNING id", (incident_id,))
        deleted = cur.fetchone()
        if not deleted:
            raise HTTPException(status_code=404, detail="Incident not found")
        conn.commit()
        return {"message": "Incident deleted", "id": incident_id}
    finally:
        conn.close()


# ============================================
# VIEWS / REPORTS ENDPOINTS
# ============================================


@app.get("/api/views/prisoner-details")
def get_prisoner_details_view(limit: int = Query(100, le=1000), offset: int = 0):
    """Get prisoner details view."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(f"SELECT * FROM v_prisoner_details LIMIT {limit} OFFSET {offset}")
        return cur.fetchall()
    finally:
        conn.close()


@app.get("/api/views/cell-occupancy")
def get_cell_occupancy_view():
    """Get cell occupancy view."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM v_cell_occupancy")
        return cur.fetchall()
    finally:
        conn.close()


@app.get("/api/views/upcoming-releases")
def get_upcoming_releases_view():
    """Get upcoming releases view."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM v_upcoming_releases")
        return cur.fetchall()
    finally:
        conn.close()


@app.get("/api/views/block-summary")
def get_block_summary_view():
    """Get block summary view."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM v_block_summary")
        return cur.fetchall()
    finally:
        conn.close()


@app.get("/api/views/staff-overview")
def get_staff_overview_view():
    """Get staff overview view."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM v_staff_overview")
        return cur.fetchall()
    finally:
        conn.close()


# ============================================
# ENUMERATIONS ENDPOINTS
# ============================================


@app.get("/api/crime-types")
def get_crime_types():
    """Get all crime types."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM crime_types ORDER BY name")
        return cur.fetchall()
    finally:
        conn.close()


@app.get("/api/staff-roles")
def get_staff_roles():
    """Get all staff roles."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM staff_roles ORDER BY access_level DESC")
        return cur.fetchall()
    finally:
        conn.close()


@app.get("/api/program-types")
def get_program_types():
    """Get all program types."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM program_types ORDER BY name")
        return cur.fetchall()
    finally:
        conn.close()


# ============================================
# UTILITY ENDPOINTS
# ============================================


@app.get("/api/stats")
def get_stats():
    """Get overall statistics."""
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        stats = {}

        cur.execute("SELECT COUNT(*) FROM prisoners WHERE status = 'incarcerated'")
        stats["total_prisoners"] = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM cells")
        stats["total_cells"] = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM staff WHERE is_active = true")
        stats["active_staff"] = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM visits WHERE status = 'scheduled'")
        stats["scheduled_visits"] = cur.fetchone()["count"]

        cur.execute("SELECT COUNT(*) FROM incidents WHERE is_resolved = false")
        stats["unresolved_incidents"] = cur.fetchone()["count"]

        cur.execute("""
            SELECT cb.name, COUNT(p.id) as count
            FROM cell_blocks cb
            LEFT JOIN cells c ON c.cell_block_id = cb.id
            LEFT JOIN prisoners p ON p.cell_id = c.id AND p.status = 'incarcerated'
            GROUP BY cb.id, cb.name
            ORDER BY cb.name
        """)
        stats["prisoners_by_block"] = cur.fetchall()

        return stats
    finally:
        conn.close()


@app.get("/api/health")
def health_check():
    """Health check endpoint."""
    try:
        conn = get_db_connection()
        conn.close()
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "database": str(e)}


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
