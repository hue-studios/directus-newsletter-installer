#!/bin/bash

# scripts/rollback.sh
# Rollback script for newsletter feature installation

set -e

# Configuration
BACKUP_DIR="/opt/newsletter-backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[ROLLBACK]${NC} $1"
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

# Function to list available backups
list_backups() {
    print_status "Available backups:"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR")" ]; then
        print_error "No backups found in $BACKUP_DIR"
        return 1
    fi
    
    local manifests
    manifests=$(find "$BACKUP_DIR" -name "backup_manifest_*.json" -type f | sort -r)
    
    if [ -z "$manifests" ]; then
        print_warning "No backup manifests found. Listing backup files directly:"
        ls -la "$BACKUP_DIR"
        return 1
    fi
    
    local i=1
    for manifest in $manifests; do
        local date timestamp
        date=$(basename "$manifest" | sed 's/backup_manifest_//; s/.json//')
        timestamp=$(jq -r '.timestamp' "$manifest" 2>/dev/null || echo "unknown")
        
        echo "  $i) $date ($timestamp)"
        ((i++))
    done
}

# Function to remove newsletter collections
remove_newsletter_collections() {
    local directus_url=$1
    local email=$2
    local password=$3
    
    print_status "Removing newsletter collections from Directus..."
    
    # Collections to remove (in reverse dependency order)
    local collections=(
        "newsletter_sends"
        "newsletter_blocks" 
        "newsletters"
        "mailing_lists"
        "block_types"
    )
    
    # Create temporary Node.js script for removal
    cat > /tmp/remove_collections.js << 'EOF'
import { createDirectus, rest, authentication, deleteCollection } from '@directus/sdk';

const [,, directusUrl, email, password] = process.argv;

async function removeCollections() {
    const directus = createDirectus(directusUrl).with(rest()).with(authentication());
    
    try {
        await directus.login(email, password);
        console.log('✅ Authentication successful');
        
        const collections = [
            'newsletter_sends',
            'newsletter_blocks', 
            'newsletters',
            'mailing_lists',
            'block_types'
        ];
        
        for (const collection of collections) {
            try {
                await directus.request(deleteCollection(collection));
                console.log(`✅ Removed collection: ${collection}`);
            } catch (error) {
                if (error.message.includes('doesn\'t exist')) {
                    console.log(`⏭️  Collection ${collection} doesn't exist`);
                } else {
                    console.error(`❌ Failed to remove ${collection}:`, error.message);
                }
            }
        }
        
        console.log('🎉 Newsletter collections removed successfully');
    } catch (error) {
        console.error('❌ Rollback failed:', error.message);
        process.exit(1);
    }
}

removeCollections();
EOF

    # Run the removal script
    if command -v node >/dev/null 2>&1; then
        cd /opt/newsletter-feature 2>/dev/null || {
            print_error "Newsletter installer directory not found"
            return 1
        }
        
        node /tmp/remove_collections.js "$directus_url" "$email" "$password"
        rm -f /tmp/remove_collections.js
    else
        print_error "Node.js not found. Cannot remove collections automatically."
        print_status "Manual removal required. Execute this SQL in your database:"
        echo ""
        echo "DROP TABLE IF EXISTS newsletter_sends CASCADE;"
        echo "DROP TABLE IF EXISTS newsletter_blocks CASCADE;"
        echo "DROP TABLE IF EXISTS newsletters CASCADE;"
        echo "DROP TABLE IF EXISTS mailing_lists CASCADE;"
        echo "DROP TABLE IF EXISTS block_types CASCADE;"
        echo ""
    fi
}

# Function to restore from backup
restore_from_backup() {
    local backup_date=$1
    local directus_url=$2
    local email=$3
    local password=$4
    
    print_status "Restoring from backup: $backup_date"
    
    local manifest_file="${BACKUP_DIR}/backup_manifest_${backup_date}.json"
    
    if [ ! -f "$manifest_file" ]; then
        print_error "Backup manifest not found: $manifest_file"
        return 1
    fi
    
    # Extract backup files from manifest
    local backup_files
    backup_files=$(jq -r '.backup_files[]' "$manifest_file")
    
    print_status "Backup files to restore:"
    echo "$backup_files" | while read -r file; do
        echo "  - $file"
    done
    
    # Restore database
    for file in $backup_files; do
        if [[ "$file" == *".sql.gz" ]]; then
            restore_database "$file" "$directus_url" "$email" "$password"
        elif [[ "$file" == *"uploads"*".tar.gz" ]]; then
            restore_uploads "$file"
        fi
    done
}

# Function to restore database
restore_database() {
    local backup_file=$1
    local directus_url=$2
    local email=$3
    local password=$4
    
    print_status "Restoring database from: $backup_file"
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi
    
    # Detect database type
    if [[ "$backup_file" == *"postgres"* ]]; then
        restore_postgres_backup "$backup_file"
    elif [[ "$backup_file" == *"mysql"* ]]; then
        restore_mysql_backup "$backup_file"
    else
        print_error "Cannot determine database type from backup file name"
        return 1
    fi
}

# Function to restore PostgreSQL backup
restore_postgres_backup() {
    local backup_file=$1
    
    print_status "Restoring PostgreSQL backup"
    
    local postgres_container
    postgres_container=$(docker ps --format "{{.Names}}" | grep postgres | head -1)
    
    if [ -z "$postgres_container" ]; then
        print_error "PostgreSQL container not found"
        return 1
    fi
    
    # Decompress and restore
    if gunzip -c "$backup_file" | docker exec -i "$postgres_container" psql -U directus directus; then
        print_success "PostgreSQL database restored successfully"
    else
        print_error "Failed to restore PostgreSQL database"
        return 1
    fi
}

# Function to restore MySQL backup
restore_mysql_backup() {
    local backup_file=$1
    
    print_status "Restoring MySQL backup"
    
    local mysql_container
    mysql_container=$(docker ps --format "{{.Names}}" | grep -E "(mysql|mariadb)" | head -1)
    
    if [ -z "$mysql_container" ]; then
        print_error "MySQL/MariaDB container not found"
        return 1
    fi
    
    # Decompress and restore
    if gunzip -c "$backup_file" | docker exec -i "$mysql_container" mysql -u directus -pdirectus directus; then
        print_success "MySQL database restored successfully"
    else
        print_error "Failed to restore MySQL database"
        return 1
    fi
}

# Function to restore uploads
restore_uploads() {
    local backup_file=$1
    
    print_status "Restoring Directus uploads"
    
    local directus_container
    directus_container=$(docker ps --format "{{.Names}}" | grep directus | head -1)
    
    if [ -z "$directus_container" ]; then
        print_error "Directus container not found"
        return 1
    fi
    
    # Restore uploads
    if docker exec -i "$directus_container" tar -xzf - < "$backup_file"; then
        print_success "Directus uploads restored successfully"
    else
        print_error "Failed to restore Directus uploads"
        return 1
    fi
}

# Function to remove Nuxt endpoints
remove_nuxt_endpoints() {
    local nuxt_project_path=$1
    
    if [ -z "$nuxt_project_path" ]; then
        print_warning "Nuxt project path not provided. Skipping endpoint removal."
        return 0
    fi
    
    if [ ! -d "$nuxt_project_path" ]; then
        print_warning "Nuxt project path not found: $nuxt_project_path"
        return 0
    fi
    
    print_status "Removing newsletter endpoints from Nuxt project"
    
    local endpoints_dir="${nuxt_project_path}/server/api/newsletter"
    
    if [ -d "$endpoints_dir" ]; then
        rm -rf "$endpoints_dir"
        print_success "Newsletter endpoints removed from: $endpoints_dir"
    else
        print_status "Newsletter endpoints directory not found"
    fi
}

# Interactive backup selection
select_backup() {
    list_backups
    
    echo ""
    read -p "Select backup number to restore (or 'q' to quit): " selection
    
    if [ "$selection" = "q" ]; then
        print_status "Rollback cancelled"
        exit 0
    fi
    
    # Validate selection
    if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
        print_error "Invalid selection. Please enter a number."
        return 1
    fi
    
    # Get backup date based on selection
    local manifests
    manifests=($(find "$BACKUP_DIR" -name "backup_manifest_*.json" -type f | sort -r))
    
    if [ "$selection" -lt 1 ] || [ "$selection" -gt "${#manifests[@]}" ]; then
        print_error "Invalid selection. Please choose a number between 1 and ${#manifests[@]}."
        return 1
    fi
    
    local selected_manifest="${manifests[$((selection-1))]}"
    local backup_date
    backup_date=$(basename "$selected_manifest" | sed 's/backup_manifest_//; s/.json//')
    
    echo "$backup_date"
}

# Function to show usage
show_usage() {
    echo "Directus Newsletter Feature - Rollback Script"
    echo ""
    echo "Usage:"
    echo "  $0 list                                              # List available backups"
    echo "  $0 remove <directus-url> <email> <password>          # Remove newsletter collections only"
    echo "  $0 full <directus-url> <email> <password> [nuxt-path] # Full rollback with backup restore"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 remove https://admin.example.com admin@example.com password"
    echo "  $0 full https://admin.example.com admin@example.com password /path/to/nuxt"
    echo ""
}

# Main function
main() {
    echo "======================================================"
    echo "   Directus Newsletter Feature - Rollback Script"
    echo "======================================================"
    echo ""
    
    case "$1" in
        "list")
            list_backups
            ;;
        "remove")
            if [ $# -lt 4 ]; then
                print_error "Remove command requires 3 arguments: <directus-url> <email> <password>"
                show_usage
                exit 1
            fi
            
            print_warning "This will remove all newsletter collections from Directus."
            read -p "Are you sure you want to continue? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_status "Rollback cancelled"
                exit 0
            fi
            
            remove_newsletter_collections "$2" "$3" "$4"
            print_success "Newsletter collections removed successfully"
            ;;
        "full")
            if [ $# -lt 4 ]; then
                print_error "Full command requires 3 arguments: <directus-url> <email> <password> [nuxt-path]"
                show_usage
                exit 1
            fi
            
            print_warning "This will perform a full rollback including database restore."
            print_warning "ALL newsletter data will be lost!"
            read -p "Are you sure you want to continue? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_status "Rollback cancelled"
                exit 0
            fi
            
            local backup_date
            backup_date=$(select_backup)
            
            if [ -z "$backup_date" ]; then
                print_error "No backup selected"
                exit 1
            fi
            
            print_status "Performing full rollback..."
            
            # Remove newsletter collections
            remove_newsletter_collections "$2" "$3" "$4"
            
            # Restore from backup
            restore_from_backup "$backup_date" "$2" "$3" "$4"
            
            # Remove Nuxt endpoints if path provided
            if [ -n "$5" ]; then
                remove_nuxt_endpoints "$5"
            fi
            
            print_success "Full rollback completed successfully"
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# Check dependencies
if ! command -v jq >/dev/null 2>&1; then
    print_error "jq is required but not installed. Please install jq first."
    echo "Ubuntu/Debian: sudo apt-get install jq"
    echo "CentOS/RHEL: sudo yum install jq"
    exit 1
fi

# Run main function
main "$@"