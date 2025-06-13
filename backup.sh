#!/bin/bash

# ZSH Configuration Backup and Sync Script
# Creates timestamped backups and syncs with remote locations

set -e

# Configuration
BACKUP_DIR="$HOME/.zsh-config-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="zsh-config-backup-$TIMESTAMP"

# Colors
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

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

create_backup() {
    print_status "Creating backup of current zsh configuration..."
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    
    local backup_path="$BACKUP_DIR/$BACKUP_NAME"
    mkdir -p "$backup_path"
    
    # Backup main files
    [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$backup_path/"
    [[ -f "$HOME/.zshrc.local" ]] && cp "$HOME/.zshrc.local" "$backup_path/"
    [[ -f "$HOME/.zshrc.work" ]] && cp "$HOME/.zshrc.work" "$backup_path/"
    
    # Backup Oh My Zsh custom directory
    if [[ -d "$HOME/.oh-my-zsh/custom" ]]; then
        cp -r "$HOME/.oh-my-zsh/custom" "$backup_path/"
    fi
    
    # Create info file
    cat > "$backup_path/backup-info.txt" << EOF
Backup created: $(date)
Hostname: $(hostname)
User: $(whoami)
ZSH version: $(zsh --version)
Oh My Zsh path: $ZSH
Current theme: $ZSH_THEME
EOF
    
    print_success "Backup created at: $backup_path"
}

list_backups() {
    print_status "Available backups:"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        local count=0
        for backup in "$BACKUP_DIR"/zsh-config-backup-*; do
            if [[ -d "$backup" ]]; then
                local backup_name=$(basename "$backup")
                local backup_date=$(echo "$backup_name" | sed 's/zsh-config-backup-//' | sed 's/_/ /')
                echo "  - $backup_name ($(date -d "$backup_date" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$backup_date"))"
                ((count++))
            fi
        done
        
        if [[ $count -eq 0 ]]; then
            echo "  No backups found"
        fi
    else
        echo "  Backup directory doesn't exist"
    fi
}

restore_backup() {
    local backup_name="$1"
    
    if [[ -z "$backup_name" ]]; then
        print_error "Please specify a backup name"
        list_backups
        return 1
    fi
    
    local backup_path="$BACKUP_DIR/$backup_name"
    
    if [[ ! -d "$backup_path" ]]; then
        print_error "Backup not found: $backup_name"
        return 1
    fi
    
    print_warning "This will overwrite your current configuration!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Restore cancelled"
        return 0
    fi
    
    print_status "Restoring from backup: $backup_name"
    
    # Restore main files
    [[ -f "$backup_path/.zshrc" ]] && cp "$backup_path/.zshrc" "$HOME/"
    [[ -f "$backup_path/.zshrc.local" ]] && cp "$backup_path/.zshrc.local" "$HOME/"
    [[ -f "$backup_path/.zshrc.work" ]] && cp "$backup_path/.zshrc.work" "$HOME/"
    
    # Restore custom directory
    if [[ -d "$backup_path/custom" ]]; then
        rm -rf "$HOME/.oh-my-zsh/custom"
        cp -r "$backup_path/custom" "$HOME/.oh-my-zsh/"
    fi
    
    print_success "Configuration restored from backup"
    print_status "Restart your shell or run 'source ~/.zshrc' to apply changes"
}

clean_old_backups() {
    local keep_days="${1:-30}"
    
    print_status "Cleaning backups older than $keep_days days..."
    
    if [[ -d "$BACKUP_DIR" ]]; then
        find "$BACKUP_DIR" -name "zsh-config-backup-*" -type d -mtime +$keep_days -exec rm -rf {} \; 2>/dev/null || true
        print_success "Old backups cleaned"
    fi
}

sync_to_cloud() {
    local cloud_path="$1"
    
    if [[ -z "$cloud_path" ]]; then
        print_error "Please specify cloud sync path (e.g., ~/Dropbox/zsh-configs)"
        return 1
    fi
    
    print_status "Syncing configuration to: $cloud_path"
    
    mkdir -p "$cloud_path"
    
    # Get script directory (where this script is located)
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Sync the entire configuration package
    rsync -av --delete "$script_dir/" "$cloud_path/zsh-config-$(hostname)/"
    
    print_success "Configuration synced to cloud storage"
}

usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  backup              Create a backup of current configuration"
    echo "  list                List available backups"
    echo "  restore <name>      Restore from a specific backup"
    echo "  clean [days]        Clean backups older than X days (default: 30)"
    echo "  sync <path>         Sync configuration to cloud storage path"
    echo "  help                Show this help message"
}

main() {
    case "${1:-backup}" in
        backup)
            create_backup
            ;;
        list)
            list_backups
            ;;
        restore)
            restore_backup "$2"
            ;;
        clean)
            clean_old_backups "$2"
            ;;
        sync)
            sync_to_cloud "$2"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            echo "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

main "$@"
