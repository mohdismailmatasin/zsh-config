#!/bin/bash

# ZSH Configuration Uninstallation Script
# This script removes the custom ZSH configuration and optionally Oh My Zsh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

backup_current_config() {
    print_status "Backing up current configuration..."
    
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.removed.$(date +%Y%m%d_%H%M%S)"
        print_success "Backed up current .zshrc"
    fi
}

restore_original_config() {
    print_status "Looking for original zsh configuration..."
    
    # Find the most recent backup
    local backup_file
    backup_file=$(ls -t "$HOME/.zshrc.backup."* 2>/dev/null | head -n1)
    
    if [[ -n "$backup_file" && -f "$backup_file" ]]; then
        print_status "Restoring original configuration from $backup_file"
        cp "$backup_file" "$HOME/.zshrc"
        print_success "Restored original .zshrc"
    else
        print_warning "No backup found, creating minimal .zshrc"
        cat > "$HOME/.zshrc" << 'EOF'
# Minimal ZSH Configuration
# If you had a previous configuration, check for .zshrc.backup.* files

# Basic PATH setup
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Basic prompt
PS1='%n@%m:%~$ '

# History
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history

# Basic completion
autoload -U compinit
compinit
EOF
        print_success "Created minimal .zshrc"
    fi
}

remove_custom_plugins() {
    print_status "Removing custom plugins..."
    
    local custom_plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    local plugins=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-autocomplete" "zsh-completions" "zsh-history-substring-search")
    
    for plugin in "${plugins[@]}"; do
        if [[ -d "$custom_plugins_dir/$plugin" ]]; then
            rm -rf "$custom_plugins_dir/$plugin"
            print_success "Removed plugin: $plugin"
        fi
    done
}

remove_custom_theme() {
    print_status "Removing custom theme..."
    
    local theme_file="$HOME/.oh-my-zsh/themes/suprima-asra.zsh-theme"
    if [[ -f "$theme_file" ]]; then
        rm -f "$theme_file"
        print_success "Removed suprima-asra theme"
    fi
}

uninstall_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo ""
        read -p "Do you want to completely remove Oh My Zsh? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Uninstalling Oh My Zsh..."
            
            # Run Oh My Zsh uninstaller if it exists
            if [[ -f "$HOME/.oh-my-zsh/tools/uninstall.sh" ]]; then
                bash "$HOME/.oh-my-zsh/tools/uninstall.sh" --force
            else
                # Manual removal
                rm -rf "$HOME/.oh-my-zsh"
            fi
            
            print_success "Oh My Zsh removed"
        else
            print_status "Keeping Oh My Zsh installed"
        fi
    fi
}

clean_backup_files() {
    echo ""
    read -p "Do you want to remove backup files (.zshrc.backup.* and .zshrc.removed.*)? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Removing backup files..."
        rm -f "$HOME/.zshrc.backup."*
        rm -f "$HOME/.zshrc.removed."*
        print_success "Backup files removed"
    else
        print_status "Keeping backup files"
    fi
}

reset_shell() {
    echo ""
    read -p "Do you want to reset your default shell to bash? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if command -v bash &> /dev/null; then
            chsh -s "$(which bash)"
            print_success "Default shell changed to bash"
        else
            print_error "bash not found"
        fi
    else
        print_status "Keeping current default shell"
    fi
}

remove_local_config() {
    if [[ -f "$HOME/.zshrc.local" ]]; then
        echo ""
        read -p "Do you want to remove ~/.zshrc.local? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Backup before removing
            cp "$HOME/.zshrc.local" "$HOME/.zshrc.local.removed.$(date +%Y%m%d_%H%M%S)"
            rm -f "$HOME/.zshrc.local"
            print_success "Removed ~/.zshrc.local (backup created)"
        else
            print_status "Keeping ~/.zshrc.local"
        fi
    fi
}

verify_uninstallation() {
    print_status "Verifying uninstallation..."
    
    local warnings=0
    
    # Check if custom plugins are removed
    local custom_plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    local plugins=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-autocomplete" "zsh-completions" "zsh-history-substring-search")
    
    for plugin in "${plugins[@]}"; do
        if [[ -d "$custom_plugins_dir/$plugin" ]]; then
            print_warning "Plugin $plugin still exists"
            ((warnings++))
        fi
    done
    
    # Check if custom theme is removed
    if [[ -f "$HOME/.oh-my-zsh/themes/suprima-asra.zsh-theme" ]]; then
        print_warning "Custom theme still exists"
        ((warnings++))
    fi
    
    if [[ $warnings -eq 0 ]]; then
        print_success "Uninstallation verification completed successfully"
    else
        print_warning "Uninstallation completed with $warnings warnings"
    fi
}

main() {
    echo "============================================"
    echo "     ZSH Configuration Uninstallation"
    echo "============================================"
    echo ""
    
    print_warning "This will remove the custom ZSH configuration."
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Uninstallation cancelled"
        exit 0
    fi
    
    echo ""
    backup_current_config
    remove_custom_plugins
    remove_custom_theme
    restore_original_config
    remove_local_config
    uninstall_oh_my_zsh
    clean_backup_files
    reset_shell
    
    echo ""
    echo "============================================"
    
    verify_uninstallation
    
    print_success "Uninstallation completed!"
    echo ""
    echo "To apply changes:"
    echo "1. Open a new terminal, or"
    echo "2. Run: source ~/.zshrc"
    echo ""
    echo "Notes:"
    echo "- Your original configuration has been restored (if backup was found)"
    echo "- Backup files are preserved unless you chose to remove them"
    echo "- You may need to restart your terminal or log out/in for shell changes"
}

# Run main function
main "$@"
