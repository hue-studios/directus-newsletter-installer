#!/bin/bash

# scripts/backup-database.sh
# Database backup script for newsletter feature deployment

set -e

# Configuration
BACKUP_DIR="/opt/newsletter-backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[BACKUP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to backup PostgreSQL database
backup_postgres() {
    local container_name=$1
    local db_name=$2
    local db_user=$3
    
    print_status "Backing up PostgreSQL database: $db_name"
    
    local backup_file="${BACKUP_DIR}/postgres_${db_name}_${DATE}.sql"
    
    if docker exec "$container_name" pg_dump -U "$db_user" "$db_name" > "$backup_file"; then
        gzip "$backup_file"
        print_success "PostgreSQL backup created: ${backup_file}.gz"
        echo "${backup_file}.gz"
    else
        print_error "Failed to create PostgreSQL backup"
        return 1
    fi
}

# Function to backup MySQL/MariaDB database
backup_mysql() {
    local container_name=$1
    local db_name=$2
    local db_user=$3
    local db_password=$4
    
    print_status "Backing up MySQL database: $db_name"
    
    local backup_file="${BACKUP_DIR}/mysql_${db_name}_${DATE}.sql"
    
    if docker exec "$container_name" mysqldump -u "$db_user" -p"$db_password" "$db_name" > "$backup_file"; then
        gzip "$backup_file"
        print_success "MySQL backup created: ${backup_file}.gz"
        echo "${backup_file}.gz"
    else
        print_error "Failed to create MySQL backup"
        return 1
    fi
}

# Function to backup Directus uploads
backup_directus_uploads() {
    local container_name=$1
    local upload_path=${2:-"/directus/uploads"}
    
    print_status "Backing up Directus uploads from: $upload_path"
    
    local backup_file="${BACKUP_DIR}/directus_uploads_${DATE}.tar.gz"
    
    if docker exec "$container_name" tar -czf - "$upload_path" > "$backup_file"; then
        print_success "Directus uploads backup created: $backup_file"
        echo "$backup_file"
    else
        print_error "Failed to create Directus uploads backup"
        return 1
    fi
}

# Function to cleanup old backups
cleanup_old_backups() {
    print_status "Cleaning up backups older than $RETENTION_DAYS days"
    
    local deleted_count=0
    
    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -type f | while read -r file; do
        rm -f "$file"
        print_status "Deleted old backup: $(basename "$file")"
        ((deleted_count++))
    done
    
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -type f | while read -r file; do
        rm -f "$file"
        print_status "Deleted old backup: $(basename "$file")"
        ((deleted_count++))
    done
    
    if [ $deleted_count -eq 0 ]; then
        print_status "No old backups to clean up"
    else
        print_success "Cleaned up $deleted_count old backup files"
    fi
}

# Function to detect database type and container
detect_database() {
    print_status "Detecting database configuration..."
    
    # Look for common database containers
    if docker ps --format "table {{.Names}}" | grep -q postgres; then
        echo "postgres"
    elif docker ps --format "table {{.Names}}" | grep -q mysql; then
        echo "mysql"
    elif docker ps --format "table {{.Names}}" | grep -q mariadb; then
        echo "mariadb"
    else
        print_error "No supported database container found"
        return 1
    fi
}

# Function to create backup manifest
create_backup_manifest() {
    local backup_files=("$@")
    local manifest_file="${BACKUP_DIR}/backup_manifest_${DATE}.json"
    
    print_status "Creating backup manifest"
    
    cat > "$manifest_file" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "date": "$DATE",
  "backup_files": [
$(printf '    "%s",' "${backup_files[@]}" | sed '$ s/,$//')
  ],
  "newsletter_feature_version": "1.0.0",
  "directus_version": "$(docker exec directus npm list directus 2>/dev/null | grep directus@ | cut -d@ -f2 || echo 'unknown')",
  "backup_type": "pre-newsletter-installation"
}
EOF
    
    print_success "Backup manifest created: $manifest_file"
}

# Main backup function
main() {
    echo "======================================================"
    echo "   Directus Newsletter Feature - Database Backup"
    echo "======================================================"
    echo ""
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    # Array to store backup file paths
    local backup_files=()
    
    # Detect and backup database
    local db_type
    db_type=$(detect_database)
    
    case $db_type in
        "postgres")
            local postgres_container
            postgres_container=$(docker ps --format "{{.Names}}" | grep postgres | head -1)
            local backup_file
            backup_file=$(backup_postgres "$postgres_container" "directus" "directus")
            backup_files+=("$backup_file")
            ;;
        "mysql"|"mariadb")
            local mysql_container
            mysql_container=$(docker ps --format "{{.Names}}" | grep -E "(mysql|mariadb)" | head -1)
            local backup_file
            backup_file=$(backup_mysql "$mysql_container" "directus" "directus" "directus")
            backup_files+=("$backup_file")
            ;;
        *)
            print_error "Unsupported database type: $db_type"
            exit 1
            ;;
    esac
    
    # Backup Directus uploads if container exists
    if docker ps --format "{{.Names}}" | grep -q directus; then
        local directus_container
        directus_container=$(docker ps --format "{{.Names}}" | grep directus | head -1)
        local uploads_backup
        uploads_backup=$(backup_directus_uploads "$directus_container")
        backup_files+=("$uploads_backup")
    fi
    
    # Create backup manifest
    create_backup_manifest "${backup_files[@]}"
    
    # Cleanup old backups
    cleanup_old_backups
    
    print_success "Backup completed successfully!"
    print_status "Backup files created:"
    for file in "${backup_files[@]}"; do
        echo "  - $file"
    done
    
    print_warning "Please verify backup integrity before proceeding with installation"
}

# Check if running with proper permissions
if [ "$EUID" -ne 0 ] && ! groups | grep -q docker; then
    print_error "This script requires root privileges or Docker group membership"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running or not accessible"
    exit 1
fi

# Run main function
main "$@"