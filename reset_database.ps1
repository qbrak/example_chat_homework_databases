# Prison Management System - Database Reset Script (PowerShell)
# This script drops and recreates the database with fresh data

$ErrorActionPreference = "Stop"

Write-Host "=====================================" -ForegroundColor Yellow
Write-Host "  Prison Database Reset Script       " -ForegroundColor Yellow
Write-Host "=====================================" -ForegroundColor Yellow

# Check if container is running
$containerRunning = docker ps --filter "name=prison_db" --format "{{.Names}}" 2>$null
if ($containerRunning -ne "prison_db") {
    Write-Host "Error: PostgreSQL container is not running" -ForegroundColor Red
    Write-Host "Start it with: .\start.ps1"
    exit 1
}

Write-Host "`nWarning: This will DELETE all existing data!" -ForegroundColor Yellow
$confirm = Read-Host "Are you sure you want to continue? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Cancelled."
    exit 0
}

Write-Host "`nDropping and recreating database..." -ForegroundColor Yellow

# Drop all tables and recreate
@"
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO prison_admin;
GRANT ALL ON SCHEMA public TO public;
"@ | docker exec -i prison_db psql -U prison_admin -d prison_management

Write-Host "Running schema script..." -ForegroundColor Yellow
Get-Content database\01_schema.sql | docker exec -i prison_db psql -U prison_admin -d prison_management

Write-Host "Running views script..." -ForegroundColor Yellow
Get-Content database\02_views.sql | docker exec -i prison_db psql -U prison_admin -d prison_management

Write-Host "Running functions script..." -ForegroundColor Yellow
Get-Content database\03_functions.sql | docker exec -i prison_db psql -U prison_admin -d prison_management

Write-Host "Running seed data script..." -ForegroundColor Yellow
Get-Content database\04_seed_data.sql | docker exec -i prison_db psql -U prison_admin -d prison_management

Write-Host "`n=====================================" -ForegroundColor Green
Write-Host "  Database reset complete!            " -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Show some stats
Write-Host "`nDatabase statistics:"
docker exec -i prison_db psql -U prison_admin -d prison_management -c @"
SELECT 'Prisoners' as table_name, COUNT(*) as count FROM prisoners
UNION ALL SELECT 'Cells', COUNT(*) FROM cells
UNION ALL SELECT 'Staff', COUNT(*) FROM staff
UNION ALL SELECT 'Visits', COUNT(*) FROM visits
UNION ALL SELECT 'Sentences', COUNT(*) FROM sentences
UNION ALL SELECT 'Incidents', COUNT(*) FROM incidents
UNION ALL SELECT 'Programs', COUNT(*) FROM programs
UNION ALL SELECT 'Enrollments', COUNT(*) FROM prisoner_programs
ORDER BY table_name;
"@
