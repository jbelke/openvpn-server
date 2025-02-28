#!/bin/bash
#VERSION 1.3
# Exit immediately if a command exits with a non-zero status
set -e

# Define colors for output
RED='\033[1;31m'
GREEN='\033[1;32m'
BLUE='\033[1;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to display usage instructions
show_usage() {
    echo -e "\n${BOLD}Script for Backing up or Restoration of OpenVPN Server Environment${NC}"
    echo -e " Script usage: \n"
    echo -e " ${GREEN}Backup usage:${NC} sudo ./backup.sh -b \"OpenVPN Server env\" \"Backup directory\""
    echo -e "  ${GREEN}Backup example:${NC} sudo ./backup.sh -b ~/openvpn-server backup/openvpn-server-$(date +%Y%m%d)\n"
    echo -e " ${BLUE}Restore usage:${NC} sudo ./backup.sh -r \"OpenVPN Server env\" \"Backup directory\""
    echo -e "  ${BLUE}Restore example:${NC} sudo ./backup.sh -r ~/openvpn-server backup/openvpn-server-030923\n"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root${NC}"
    exit 1
fi

# Check required arguments
if [[ -z $1 || -z $2 || -z $3 ]]; then
    show_usage
    exit 1
fi

ACTION=$1
SERVER_ENV=$2
BACKUP_DIR=$3

# Function to backup files
backup_files() {
    local src=$1
    local dest=$2
    local message=$3
    
    if cp -Rp "$src" "$dest"; then
        echo " $message backed up"
    else
        echo -e "${RED}Failed to backup $message${NC}"
        return 1
    fi
}

# Function to restore files
restore_files() {
    local src=$1
    local dest=$2
    local message=$3
    
    if rm -rf "$dest" && cp -Rp "$src" "$dest"; then
        echo " $message restored"
    else
        echo -e "${RED}Failed to restore $message${NC}"
        return 1
    fi
}

if [[ $ACTION == "-b" ]]; then
    # Prompt to confirm backup action
    read -p "Are we going to backup environment from \"$SERVER_ENV\" to \"$BACKUP_DIR\"? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Performing backup${NC}"
        echo -e " Backup OpenVPN Server Environment from \"$SERVER_ENV\" to \"$BACKUP_DIR\""
        
        # Create backup directory if it doesn't exist
        mkdir -p "$BACKUP_DIR"
        echo -e "${GREEN}Backup directory created at $BACKUP_DIR${NC}"
        # Backup all components
        backup_files "$SERVER_ENV/config" "$BACKUP_DIR" "OpenVPN config" || exit 1
        
        # Handle DB backup with special case for older versions
        backup_files "$SERVER_ENV/db" "$BACKUP_DIR" "OpenVPN-UI db"
        if [ ! -f "$BACKUP_DIR/db/data.db" ]; then
            echo " You probably have old version of OpenVPN-UI, backing up your DB with docker cp"
            mkdir -p "$BACKUP_DIR/db" "$SERVER_ENV/db"
            if docker cp openvpn-ui:/opt/openvpn-gui/data.db "$BACKUP_DIR/db/data.db"; then
                cp -p "$BACKUP_DIR/db/data.db" "$SERVER_ENV/db/data.db"
                echo " OpenVPN-UI db backed up (legacy method)"
            else
                echo -e "${RED}Failed to backup database using legacy method${NC}"
                exit 1
            fi
        fi

        backup_files "$SERVER_ENV/pki" "$BACKUP_DIR" "OpenVPN pki" || exit 1
        backup_files "$SERVER_ENV/staticclients" "$BACKUP_DIR" "OpenVPN staticclients" || exit 1
        backup_files "$SERVER_ENV/clients" "$BACKUP_DIR" "OpenVPN clients" || exit 1
        backup_files "$SERVER_ENV/fw-rules.sh" "$BACKUP_DIR/fw-rules.sh" "OpenVPN fw-rules.sh" || exit 1
        backup_files "$SERVER_ENV/docker-compose.yml" "$BACKUP_DIR/docker-compose.yml" "OpenVPN docker-compose.yml" || exit 1

        # Create backup timestamp
        date > "$BACKUP_DIR/backup_timestamp"
        
        echo -e "${GREEN}Backup created at $BACKUP_DIR${NC}"
    else
        echo -e "${RED}Backup creation cancelled!${NC}"
        exit 1
    fi
elif [[ $ACTION == "-r" ]]; then
    # Check if backup directory exists
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${RED}Backup directory does not exist!${NC}"
        exit 1
    fi

    # Prompt to confirm restore action
    read -p "Are you sure you want to delete environment in \"$SERVER_ENV\" and restore from \"$BACKUP_DIR\"? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Performing Restore${NC}"
        
        # Restore all components
        restore_files "$BACKUP_DIR/config" "$SERVER_ENV/config" "OpenVPN config" || exit 1
        restore_files "$BACKUP_DIR/db" "$SERVER_ENV/db" "OpenVPN-UI db" || exit 1
        restore_files "$BACKUP_DIR/pki" "$SERVER_ENV/pki" "OpenVPN pki" || exit 1
        restore_files "$BACKUP_DIR/staticclients" "$SERVER_ENV/staticclients" "OpenVPN staticclients" || exit 1
        restore_files "$BACKUP_DIR/clients" "$SERVER_ENV/clients" "OpenVPN clients" || exit 1
        restore_files "$BACKUP_DIR/fw-rules.sh" "$SERVER_ENV/fw-rules.sh" "OpenVPN fw-rules.sh" || exit 1
        restore_files "$BACKUP_DIR/docker-compose.yml" "$SERVER_ENV/docker-compose.yml" "OpenVPN docker-compose.yml" || exit 1

        echo -e "${BLUE}Restore Completed!${NC}"
    else
        echo -e "${RED}Restore cancelled!${NC}"
        exit 1
    fi
else
    # Invalid action
    echo -e "${RED}Invalid option: $ACTION${NC}"
    show_usage
    exit 1
fi
