#!/bin/bash

# ZSH Configuration Installation Script
# This script installs Oh My Zsh with custom plugins and configuration

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check if zsh is installed
    if ! command -v zsh &> /dev/null; then
        print_error "zsh is not installed. Please install zsh first."
        echo "Ubuntu/Debian: sudo apt install zsh"
        echo "CentOS/RHEL: sudo yum install zsh"
        echo "macOS: brew install zsh"
        exit 1
    fi
    
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        print_error "git is not installed. Please install git first."
        exit 1
    fi
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        print_warning "curl is not installed. Some features may not work."
    fi
    
    print_success "Dependencies check completed"
}

backup_existing_config() {
    print_status "Backing up existing configuration..."
    
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "Backed up existing .zshrc"
    fi
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        print_warning "Oh My Zsh is already installed. Custom plugins will be added/updated."
    fi
}

install_oh_my_zsh() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_status "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        print_success "Oh My Zsh installed successfully"
    else
        print_status "Oh My Zsh is already installed"
    fi
}

install_custom_plugins() {
    print_status "Installing custom plugins..."
    
    local custom_plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    
    # Create custom plugins directory if it doesn't exist
    mkdir -p "$custom_plugins_dir"
    
    # Copy all plugins from our plugins directory
    for plugin_dir in "$SCRIPT_DIR/plugins"/*; do
        if [[ -d "$plugin_dir" ]]; then
            plugin_name=$(basename "$plugin_dir")
            print_status "Installing plugin: $plugin_name"
            
            # Remove existing plugin and copy new one
            rm -rf "$custom_plugins_dir/$plugin_name"
            cp -r "$plugin_dir" "$custom_plugins_dir/"
            
            print_success "Installed plugin: $plugin_name"
        fi
    done
}

install_custom_theme() {
    print_status "Installing custom theme..."
    
    local themes_dir="$HOME/.oh-my-zsh/themes"
    
    # Copy theme file
    if [[ -f "$SCRIPT_DIR/themes/suprima-asra.zsh-theme" ]]; then
        cp "$SCRIPT_DIR/themes/suprima-asra.zsh-theme" "$themes_dir/"
        print_success "Installed suprima-asra theme"
    else
        print_warning "suprima-asra theme file not found"
    fi
}

install_zsh_config() {
    print_status "Installing zsh configuration..."
    
    if [[ -f "$SCRIPT_DIR/config/.zshrc" ]]; then
        cp "$SCRIPT_DIR/config/.zshrc" "$HOME/.zshrc"
        print_success "Installed .zshrc configuration"
    else
        print_error "Configuration file not found"
        exit 1
    fi
}

set_zsh_as_default() {
    print_status "Setting zsh as default shell..."
    
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        print_warning "Zsh is not your default shell."
        echo "To set zsh as your default shell, run:"
        echo "chsh -s \$(which zsh)"
        echo ""
        read -p "Would you like to set zsh as default now? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            chsh -s "$(which zsh)"
            print_success "Default shell changed to zsh"
        fi
    else
        print_success "Zsh is already your default shell"
    fi
}

create_local_config() {
    print_status "Creating local configuration template..."
    
    if [[ ! -f "$HOME/.zshrc.local" ]]; then
        cat > "$HOME/.zshrc.local" << 'EOF'
# Local ZSH Configuration
# This file is for machine-specific customizations
# It will be sourced by .zshrc if it exists

# Example: Add local bin paths
# export PATH="/path/to/local/bin:$PATH"

# Example: Set local environment variables
# export LOCAL_VAR="value"

# Example: Local aliases
# alias myproject='cd /path/to/my/project'

# Example: Load work-specific configurations
# [[ -f ~/.zshrc.work ]] && source ~/.zshrc.work
EOF
        print_success "Created ~/.zshrc.local template"
    else
        print_status "~/.zshrc.local already exists, skipping template creation"
    fi
}

verify_installation() {
    print_status "Verifying installation..."
    
    local errors=0
    
    # Check if Oh My Zsh is installed
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        print_error "Oh My Zsh installation failed"
        ((errors++))
    fi
    
    # Check if .zshrc exists
    if [[ ! -f "$HOME/.zshrc" ]]; then
        print_error ".zshrc installation failed"
        ((errors++))
    fi
    
    # Check if custom plugins are installed
    local required_plugins=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-autocomplete" "zsh-completions" "zsh-history-substring-search")
    for plugin in "${required_plugins[@]}"; do
        if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/$plugin" ]]; then
            print_error "Plugin $plugin installation failed"
            ((errors++))
        fi
    done
    
    # Check if theme is installed
    if [[ ! -f "$HOME/.oh-my-zsh/themes/suprima-asra.zsh-theme" ]]; then
        print_error "Theme installation failed"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_success "Installation verification completed successfully"
        return 0
    else
        print_error "Installation verification failed with $errors errors"
        return 1
    fi
}

main() {
    echo "============================================"
    echo "     ZSH Configuration Installation"
    echo "============================================"
    echo ""
    
    check_dependencies
    backup_existing_config
    install_oh_my_zsh
    install_custom_plugins
    install_custom_theme
    install_zsh_config
    create_local_config
    set_zsh_as_default
    
    echo ""
    echo "============================================"
    
    if verify_installation; then
        print_success "Installation completed successfully!"
        echo ""
        echo "To apply the new configuration:"
        echo "1. Open a new terminal, or"
        echo "2. Run: source ~/.zshrc"
        echo ""
        echo "Notes:"
        echo "- Edit ~/.zshrc.local for machine-specific customizations"
        echo "- Run 'uninstall.sh' to remove this configuration"
        echo "- Check README.md for more information"
    else
        print_error "Installation completed with errors. Please check the output above."
        exit 1
    fi
}

# Run main function
main "$@"
