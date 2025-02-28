#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# Define colors for output
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# Function to display elapsed time
show_elapsed_time() {
    local end_time=$(date +%s)
    local execution_time=$((end_time - start_time))
    local minutes=$((execution_time / 60))
    local seconds=$((execution_time % 60))
    printf "${BLUE}Execution time: %02d:%02d${NC} (%d sec)\n" $minutes $seconds $execution_time
}

# Function to handle errors
error_handler() {
    printf "${RED}Error occurred. Cleaning up...${NC}\n"
    docker-compose down
    exit 1
}

# Set error trap
trap error_handler ERR

# Start time benchmark
start_time=$(date +%s)

printf "${BLUE}Stopping OpenVPN Server...${NC}\n"
docker-compose down

printf "${BLUE}Rebuilding and starting OpenVPN Server...${NC}\n"
if docker-compose up -d --build; then
    printf "${GREEN}OpenVPN Server successfully rebuilt and started!${NC}\n"
else
    printf "${RED}Failed to rebuild and start OpenVPN Server${NC}\n"
    exit 1
fi

# Show elapsed time
show_elapsed_time