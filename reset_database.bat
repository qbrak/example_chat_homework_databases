@echo off
setlocal enabledelayedexpansion

REM Prison Management System - Database Reset Script (Windows)
REM This script drops and recreates the database with fresh data

echo =====================================
echo   Prison Database Reset Script
echo =====================================

REM Check if container is running
docker ps | findstr prison_db >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: PostgreSQL container is not running
    echo Start it with: start.bat
    exit /b 1
)

echo.
echo Warning: This will DELETE all existing data!
set /p CONFIRM="Are you sure you want to continue? (y/N) "
if /i not "%CONFIRM%"=="y" (
    echo Cancelled.
    exit /b 0
)

echo.
echo Dropping and recreating database...

REM Drop all tables and recreate
echo DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO prison_admin; GRANT ALL ON SCHEMA public TO public; | docker exec -i prison_db psql -U prison_admin -d prison_management

echo Running schema script...
docker exec -i prison_db psql -U prison_admin -d prison_management < database\01_schema.sql

echo Running views script...
docker exec -i prison_db psql -U prison_admin -d prison_management < database\02_views.sql

echo Running functions script...
docker exec -i prison_db psql -U prison_admin -d prison_management < database\03_functions.sql

echo Running seed data script...
docker exec -i prison_db psql -U prison_admin -d prison_management < database\04_seed_data.sql

echo.
echo =====================================
echo   Database reset complete!
echo =====================================

REM Show some stats
echo.
echo Database statistics:
docker exec -i prison_db psql -U prison_admin -d prison_management -c "SELECT 'Prisoners' as table_name, COUNT(*) as count FROM prisoners UNION ALL SELECT 'Cells', COUNT(*) FROM cells UNION ALL SELECT 'Staff', COUNT(*) FROM staff UNION ALL SELECT 'Visits', COUNT(*) FROM visits UNION ALL SELECT 'Sentences', COUNT(*) FROM sentences UNION ALL SELECT 'Incidents', COUNT(*) FROM incidents UNION ALL SELECT 'Programs', COUNT(*) FROM programs UNION ALL SELECT 'Enrollments', COUNT(*) FROM prisoner_programs ORDER BY table_name;"

endlocal
