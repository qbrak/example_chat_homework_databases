@echo off
setlocal enabledelayedexpansion

REM Prison Management System - Startup Script (Windows)
REM This script starts all components: PostgreSQL, Backend API, and Electron Frontend

echo =====================================
echo   Prison Management System Startup
echo =====================================

REM Check for required tools
echo.
echo Checking requirements...

where docker >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: Docker is not installed
    exit /b 1
)

where uv >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: UV is not installed
    echo Install with: irm https://astral.sh/uv/install.ps1 ^| iex
    exit /b 1
)

where npm >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: npm is not installed
    exit /b 1
)

echo All requirements satisfied!

REM Start PostgreSQL with Docker
echo.
echo Starting PostgreSQL database...

docker ps | findstr prison_db >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo PostgreSQL container already running
) else (
    REM Remove old container if exists
    docker rm -f prison_db >nul 2>nul

    REM Start PostgreSQL container
    docker run -d ^
        --name prison_db ^
        -e POSTGRES_USER=prison_admin ^
        -e POSTGRES_PASSWORD=prison_secure_pwd_2025 ^
        -e POSTGRES_DB=prison_management ^
        -p 5432:5432 ^
        -v prison_db_data:/var/lib/postgresql/data ^
        postgres:15

    echo Waiting for PostgreSQL to be ready...

    REM Wait for database to be healthy
    set /a count=0
    :wait_loop
    docker exec prison_db pg_isready -U prison_admin -d prison_management >nul 2>nul
    if %ERRORLEVEL% equ 0 (
        echo PostgreSQL is ready!
        goto :db_ready
    )
    set /a count+=1
    if !count! geq 30 (
        echo Timeout waiting for PostgreSQL
        exit /b 1
    )
    echo|set /p=.
    timeout /t 1 /nobreak >nul
    goto :wait_loop

    :db_ready

    REM Check if database is already initialized
    for /f %%i in ('docker exec prison_db psql -U prison_admin -d prison_management -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2^>nul') do set TABLES_COUNT=%%i
    set TABLES_COUNT=!TABLES_COUNT: =!

    if "!TABLES_COUNT!"=="" set TABLES_COUNT=0
    if !TABLES_COUNT! lss 5 (
        echo Initializing database schema...
        docker exec -i prison_db psql -U prison_admin -d prison_management < database\01_schema.sql
        echo Creating views...
        docker exec -i prison_db psql -U prison_admin -d prison_management < database\02_views.sql
        echo Creating functions and triggers...
        docker exec -i prison_db psql -U prison_admin -d prison_management < database\03_functions.sql
        echo Loading sample data...
        docker exec -i prison_db psql -U prison_admin -d prison_management < database\04_seed_data.sql
        echo Database initialized!
    ) else (
        echo Database already initialized
    )
)

REM Install Python dependencies if needed
echo.
echo Setting up Python backend...
if not exist ".venv" (
    uv sync
)

REM Start the backend API in background
echo.
echo Starting backend API server...
start /b cmd /c "uv run uvicorn backend.server:app --host 0.0.0.0 --port 8000"

REM Wait for backend to be ready
echo Waiting for backend API to be ready...
set /a count=0
:wait_backend
curl -s http://localhost:8000/api/health >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo Backend API is ready!
    goto :backend_ready
)
set /a count+=1
if !count! geq 30 (
    echo Timeout waiting for backend API
    exit /b 1
)
echo|set /p=.
timeout /t 1 /nobreak >nul
goto :wait_backend

:backend_ready

REM Install Electron dependencies if needed
echo.
echo Setting up Electron frontend...
cd frontend
if not exist "node_modules" (
    call npm install
)

REM Start Electron
echo.
echo =====================================
echo   All services started successfully!
echo =====================================
echo.
echo Services:
echo   - PostgreSQL: localhost:5432
echo   - Backend API: http://localhost:8000
echo   - API Docs: http://localhost:8000/docs
echo.
echo Starting Electron application...
echo Press Ctrl+C to stop all services
echo.

call npm start

REM Cleanup
echo.
echo Shutting down services...
taskkill /f /im "uvicorn.exe" >nul 2>nul
echo Services stopped. Docker container still running.
echo To stop PostgreSQL: docker stop prison_db

cd ..
endlocal
