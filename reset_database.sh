#!/bin/bash

# Prison Management System - Database Reset Script
# This script drops and recreates the database with fresh data

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=====================================${NC}"
echo -e "${YELLOW}  Prison Database Reset Script       ${NC}"
echo -e "${YELLOW}=====================================${NC}"

# Check if container is running
if ! docker ps | grep -q prison_db; then
    echo -e "${RED}Error: PostgreSQL container is not running${NC}"
    echo "Start it with: ./start.sh"
    exit 1
fi

echo -e "\n${YELLOW}Warning: This will DELETE all existing data!${NC}"
read -p "Are you sure you want to continue? (y/N) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo -e "\n${YELLOW}Dropping and recreating database...${NC}"

# Drop all tables and recreate
docker exec -i prison_db psql -U prison_admin -d prison_management << 'EOF'
-- Drop all tables
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO prison_admin;
GRANT ALL ON SCHEMA public TO public;
EOF

echo -e "${YELLOW}Running schema script...${NC}"
docker exec -i prison_db psql -U prison_admin -d prison_management < database/01_schema.sql

echo -e "${YELLOW}Running views script...${NC}"
docker exec -i prison_db psql -U prison_admin -d prison_management < database/02_views.sql

echo -e "${YELLOW}Running functions script...${NC}"
docker exec -i prison_db psql -U prison_admin -d prison_management < database/03_functions.sql

echo -e "${YELLOW}Running seed data script...${NC}"
docker exec -i prison_db psql -U prison_admin -d prison_management < database/04_seed_data.sql

echo -e "\n${GREEN}=====================================${NC}"
echo -e "${GREEN}  Database reset complete!            ${NC}"
echo -e "${GREEN}=====================================${NC}"

# Show some stats
echo -e "\nDatabase statistics:"
docker exec -i prison_db psql -U prison_admin -d prison_management << 'EOF'
SELECT 'Prisoners' as table_name, COUNT(*) as count FROM prisoners
UNION ALL SELECT 'Cells', COUNT(*) FROM cells
UNION ALL SELECT 'Staff', COUNT(*) FROM staff
UNION ALL SELECT 'Visits', COUNT(*) FROM visits
UNION ALL SELECT 'Sentences', COUNT(*) FROM sentences
UNION ALL SELECT 'Incidents', COUNT(*) FROM incidents
UNION ALL SELECT 'Programs', COUNT(*) FROM programs
UNION ALL SELECT 'Enrollments', COUNT(*) FROM prisoner_programs
ORDER BY table_name;
EOF
