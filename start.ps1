# Prison Management System - Startup Script (PowerShell)
# This script starts all components: PostgreSQL, Backend API, and Electron Frontend

$ErrorActionPreference = "Stop"

Write-Host "=====================================" -ForegroundColor Blue
Write-Host "  Prison Management System Startup   " -ForegroundColor Blue
Write-Host "=====================================" -ForegroundColor Blue

# Check for required tools
Write-Host "`nChecking requirements..." -ForegroundColor Yellow

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Docker is not installed" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host "Error: UV is not installed" -ForegroundColor Red
    Write-Host "Install with: irm https://astral.sh/uv/install.ps1 | iex"
    exit 1
}

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Host "Error: npm is not installed" -ForegroundColor Red
    exit 1
}

Write-Host "All requirements satisfied!" -ForegroundColor Green

# Start PostgreSQL with Docker
Write-Host "`nStarting PostgreSQL database..." -ForegroundColor Yellow

$containerRunning = docker ps --filter "name=prison_db" --format "{{.Names}}" 2>$null
if ($containerRunning -eq "prison_db") {
    Write-Host "PostgreSQL container already running" -ForegroundColor Green
} else {
    # Remove old container if exists
    docker rm -f prison_db 2>$null | Out-Null

    # Start PostgreSQL container
    docker run -d `
        --name prison_db `
        -e POSTGRES_USER=prison_admin `
        -e POSTGRES_PASSWORD=prison_secure_pwd_2025 `
        -e POSTGRES_DB=prison_management `
        -p 5432:5432 `
        -v prison_db_data:/var/lib/postgresql/data `
        postgres:15 | Out-Null

    Write-Host "Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow

    # Wait for database to be healthy
    $count = 0
    while ($count -lt 30) {
        $result = docker exec prison_db pg_isready -U prison_admin -d prison_management 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`nPostgreSQL is ready!" -ForegroundColor Green
            break
        }
        $count++
        Write-Host -NoNewline "."
        Start-Sleep -Seconds 1
    }

    if ($count -ge 30) {
        Write-Host "`nTimeout waiting for PostgreSQL" -ForegroundColor Red
        exit 1
    }

    # Check if database is already initialized
    $tablesCount = docker exec prison_db psql -U prison_admin -d prison_management -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>$null
    $tablesCount = [int]($tablesCount -replace '\s', '')

    if ($tablesCount -lt 5) {
        Write-Host "Initializing database schema..." -ForegroundColor Yellow
        Get-Content database\01_schema.sql | docker exec -i prison_db psql -U prison_admin -d prison_management
        Write-Host "Creating views..." -ForegroundColor Yellow
        Get-Content database\02_views.sql | docker exec -i prison_db psql -U prison_admin -d prison_management
        Write-Host "Creating functions and triggers..." -ForegroundColor Yellow
        Get-Content database\03_functions.sql | docker exec -i prison_db psql -U prison_admin -d prison_management
        Write-Host "Loading sample data..." -ForegroundColor Yellow
        Get-Content database\04_seed_data.sql | docker exec -i prison_db psql -U prison_admin -d prison_management
        Write-Host "Database initialized!" -ForegroundColor Green
    } else {
        Write-Host "Database already initialized" -ForegroundColor Green
    }
}

# Install Python dependencies if needed
Write-Host "`nSetting up Python backend..." -ForegroundColor Yellow
if (-not (Test-Path ".venv")) {
    uv sync
}

# Start the backend API in background
Write-Host "`nStarting backend API server..." -ForegroundColor Yellow
$backendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    uv run uvicorn backend.server:app --host 0.0.0.0 --port 8000
}

# Wait for backend to be ready
Write-Host "Waiting for backend API to be ready..." -ForegroundColor Yellow
$count = 0
while ($count -lt 30) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8000/api/health" -UseBasicParsing -TimeoutSec 2 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "`nBackend API is ready!" -ForegroundColor Green
            break
        }
    } catch {
        # Ignore connection errors while waiting
    }
    $count++
    Write-Host -NoNewline "."
    Start-Sleep -Seconds 1
}

if ($count -ge 30) {
    Write-Host "`nTimeout waiting for backend API" -ForegroundColor Red
    Stop-Job $backendJob
    Remove-Job $backendJob
    exit 1
}

# Install Electron dependencies if needed
Write-Host "`nSetting up Electron frontend..." -ForegroundColor Yellow
Push-Location frontend
if (-not (Test-Path "node_modules")) {
    npm install
}

# Start Electron
Write-Host "`n=====================================" -ForegroundColor Green
Write-Host "  All services started successfully!  " -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host "`nServices:"
Write-Host "  - PostgreSQL: " -NoNewline; Write-Host "localhost:5432" -ForegroundColor Blue
Write-Host "  - Backend API: " -NoNewline; Write-Host "http://localhost:8000" -ForegroundColor Blue
Write-Host "  - API Docs: " -NoNewline; Write-Host "http://localhost:8000/docs" -ForegroundColor Blue
Write-Host "`nStarting Electron application..."
Write-Host "Press Ctrl+C to stop all services" -ForegroundColor Yellow
Write-Host ""

try {
    npm start
} finally {
    # Cleanup
    Write-Host "`nShutting down services..." -ForegroundColor Yellow
    Stop-Job $backendJob -ErrorAction SilentlyContinue
    Remove-Job $backendJob -ErrorAction SilentlyContinue
    Get-Process -Name "uvicorn" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Write-Host "Services stopped. Docker container still running." -ForegroundColor Green
    Write-Host "To stop PostgreSQL: docker stop prison_db" -ForegroundColor Yellow
    Pop-Location
}
