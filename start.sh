#!/bin/bash

# Prison Management System - Startup Script
# This script starts all components: PostgreSQL, Backend API, and Electron Frontend

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  Prison Management System Startup   ${NC}"
echo -e "${BLUE}=====================================${NC}"

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}Shutting down services...${NC}"
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    echo -e "${GREEN}Services stopped. Docker container still running.${NC}"
    echo -e "${YELLOW}To stop PostgreSQL: docker stop prison_db${NC}"
}

trap cleanup EXIT

# Check for required tools
echo -e "\n${YELLOW}Checking requirements...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed${NC}"
    exit 1
fi

if ! command -v uv &> /dev/null; then
    echo -e "${RED}Error: UV is not installed${NC}"
    echo "Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}All requirements satisfied!${NC}"

# Start PostgreSQL with Docker
echo -e "\n${YELLOW}Starting PostgreSQL database...${NC}"

if docker ps | grep -q prison_db; then
    echo -e "${GREEN}PostgreSQL container already running${NC}"
else
    # Remove old container if exists
    docker rm -f prison_db 2>/dev/null || true

    # Start PostgreSQL container
    docker run -d \
        --name prison_db \
        -e POSTGRES_USER=prison_admin \
        -e POSTGRES_PASSWORD=prison_secure_pwd_2025 \
        -e POSTGRES_DB=prison_management \
        -p 5432:5432 \
        -v prison_db_data:/var/lib/postgresql/data \
        postgres:15

    echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"

    # Wait for database to be healthy
    for i in {1..30}; do
        if docker exec prison_db pg_isready -U prison_admin -d prison_management &> /dev/null; then
            echo -e "${GREEN}PostgreSQL is ready!${NC}"
            break
        fi
        if [ $i -eq 30 ]; then
            echo -e "${RED}Timeout waiting for PostgreSQL${NC}"
            exit 1
        fi
        echo -n "."
        sleep 1
    done

    # Check if database is already initialized
    TABLES_COUNT=$(docker exec prison_db psql -U prison_admin -d prison_management -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | tr -d ' ' || echo "0")

    if [ "$TABLES_COUNT" -lt "5" ]; then
        echo -e "${YELLOW}Initializing database schema...${NC}"
        docker exec -i prison_db psql -U prison_admin -d prison_management < database/01_schema.sql
        echo -e "${YELLOW}Creating views...${NC}"
        docker exec -i prison_db psql -U prison_admin -d prison_management < database/02_views.sql
        echo -e "${YELLOW}Creating functions and triggers...${NC}"
        docker exec -i prison_db psql -U prison_admin -d prison_management < database/03_functions.sql
        echo -e "${YELLOW}Loading sample data...${NC}"
        docker exec -i prison_db psql -U prison_admin -d prison_management < database/04_seed_data.sql
        echo -e "${GREEN}Database initialized!${NC}"
    else
        echo -e "${GREEN}Database already initialized${NC}"
    fi
fi

# Install Python dependencies if needed
echo -e "\n${YELLOW}Setting up Python backend...${NC}"
if [ ! -d ".venv" ]; then
    uv sync
fi

# Start the backend API
echo -e "\n${YELLOW}Starting backend API server...${NC}"
uv run uvicorn backend.server:app --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!

# Wait for backend to be ready
echo -e "${YELLOW}Waiting for backend API to be ready...${NC}"
for i in {1..30}; do
    if curl -s http://localhost:8000/api/health &> /dev/null; then
        echo -e "${GREEN}Backend API is ready!${NC}"
        break
    fi
    if [ $i -eq 30 ]; then
        echo -e "${RED}Timeout waiting for backend API${NC}"
        exit 1
    fi
    echo -n "."
    sleep 1
done

# Install Electron dependencies if needed
echo -e "\n${YELLOW}Setting up Electron frontend...${NC}"
cd frontend
if [ ! -d "node_modules" ]; then
    npm install
fi

# Start Electron
echo -e "\n${GREEN}=====================================${NC}"
echo -e "${GREEN}  All services started successfully!  ${NC}"
echo -e "${GREEN}=====================================${NC}"
echo -e "\nServices:"
echo -e "  - PostgreSQL: ${BLUE}localhost:5432${NC}"
echo -e "  - Backend API: ${BLUE}http://localhost:8000${NC}"
echo -e "  - API Docs: ${BLUE}http://localhost:8000/docs${NC}"
echo -e "\nStarting Electron application..."
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}\n"

npm start

# Wait for all processes
wait
