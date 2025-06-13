#!/bin/bash

# ZSH Plugin Manager
# Easily add, remove, and update plugins

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PLUGINS_DIR="$HOME/.oh-my-zsh/custom/plugins"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_status() {
    echo -e "${BLUE}[PLUGIN]${NC} $1"
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

# Popular plugin repositories
declare -A PLUGIN_REPOS=(
    ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
    ["zsh-history-substring-search"]="https://github.com/zsh-users/zsh-history-substring-search"
    ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
    ["zsh-autocomplete"]="https://github.com/marlonrichert/zsh-autocomplete"
    ["powerlevel10k"]="https://github.com/romkatv/powerlevel10k"
    ["zsh-z"]="https://github.com/agkozak/zsh-z"
    ["fast-syntax-highlighting"]="https://github.com/zdharma-continuum/fast-syntax-highlighting"
)

list_plugins() {
    print_status "Installed plugins:"
    
    if [[ -d "$PLUGINS_DIR" ]]; then
        for plugin_dir in "$PLUGINS_DIR"/*; do
            if [[ -d "$plugin_dir" ]]; then
                local plugin_name=$(basename "$plugin_dir")
                if [[ "$plugin_name" != "example" ]]; then
                    local status="✓"
                    local info=""
                    
                    # Check if plugin is enabled in .zshrc
                    if grep -q "^[[:space:]]*plugins=.*$plugin_name" "$HOME/.zshrc" 2>/dev/null; then
                        info=" (enabled)"
                    else
                        status="○"
                        info=" (disabled)"
                    fi
                    
                    echo "  $status $plugin_name$info"
                fi
            fi
        done
    else
        echo "  No custom plugins directory found"
    fi
}

install_plugin() {
    local plugin_name="$1"
    local repo_url="$2"
    
    if [[ -z "$plugin_name" ]]; then
        print_error "Please specify a plugin name"
        return 1
    fi
    
    # Use predefined repo if available
    if [[ -z "$repo_url" && -n "${PLUGIN_REPOS[$plugin_name]}" ]]; then
        repo_url="${PLUGIN_REPOS[$plugin_name]}"
    fi
    
    if [[ -z "$repo_url" ]]; then
        print_error "Please specify a repository URL for $plugin_name"
        return 1
    fi
    
    local plugin_path="$PLUGINS_DIR/$plugin_name"
    
    if [[ -d "$plugin_path" ]]; then
        print_warning "Plugin $plugin_name is already installed"
        return 0
    fi
    
    print_status "Installing plugin: $plugin_name"
    print_status "Repository: $repo_url"
    
    mkdir -p "$PLUGINS_DIR"
    
    if git clone "$repo_url" "$plugin_path"; then
        print_success "Plugin $plugin_name installed successfully"
        
        # Copy to package plugins directory if we're in the package
        if [[ -d "$SCRIPT_DIR/plugins" ]]; then
            print_status "Adding to package..."
            cp -r "$plugin_path" "$SCRIPT_DIR/plugins/"
            print_success "Plugin added to package"
        fi
        
        suggest_enable_plugin "$plugin_name"
    else
        print_error "Failed to install plugin $plugin_name"
        return 1
    fi
}

remove_plugin() {
    local plugin_name="$1"
    
    if [[ -z "$plugin_name" ]]; then
        print_error "Please specify a plugin name"
        return 1
    fi
    
    local plugin_path="$PLUGINS_DIR/$plugin_name"
    
    if [[ ! -d "$plugin_path" ]]; then
        print_error "Plugin $plugin_name is not installed"
        return 1
    fi
    
    print_warning "This will remove plugin: $plugin_name"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Removal cancelled"
        return 0
    fi
    
    rm -rf "$plugin_path"
    
    # Remove from package if we're in the package
    if [[ -d "$SCRIPT_DIR/plugins/$plugin_name" ]]; then
        rm -rf "$SCRIPT_DIR/plugins/$plugin_name"
        print_success "Plugin removed from package"
    fi
    
    print_success "Plugin $plugin_name removed"
    suggest_disable_plugin "$plugin_name"
}

update_plugin() {
    local plugin_name="$1"
    
    if [[ -z "$plugin_name" ]]; then
        print_error "Please specify a plugin name"
        return 1
    fi
    
    local plugin_path="$PLUGINS_DIR/$plugin_name"
    
    if [[ ! -d "$plugin_path" ]]; then
        print_error "Plugin $plugin_name is not installed"
        return 1
    fi
    
    if [[ ! -d "$plugin_path/.git" ]]; then
        print_warning "Plugin $plugin_name is not a git repository - cannot update"
        return 1
    fi
    
    print_status "Updating plugin: $plugin_name"
    
    cd "$plugin_path"
    if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null; then
        print_success "Plugin $plugin_name updated successfully"
        
        # Update in package if we're in the package
        if [[ -d "$SCRIPT_DIR/plugins/$plugin_name" ]]; then
            print_status "Updating in package..."
            rm -rf "$SCRIPT_DIR/plugins/$plugin_name"
            cp -r "$plugin_path" "$SCRIPT_DIR/plugins/"
            print_success "Package updated"
        fi
    else
        print_error "Failed to update plugin $plugin_name"
        return 1
    fi
}

suggest_enable_plugin() {
    local plugin_name="$1"
    
    echo ""
    print_status "To enable this plugin, add '$plugin_name' to the plugins array in ~/.zshrc"
    echo "Example: plugins=(git $plugin_name ...other-plugins...)"
}

suggest_disable_plugin() {
    local plugin_name="$1"
    
    echo ""
    print_status "Don't forget to remove '$plugin_name' from the plugins array in ~/.zshrc"
}

list_available() {
    print_status "Popular plugins available for installation:"
    echo ""
    
    for plugin in "${!PLUGIN_REPOS[@]}"; do
        local installed=""
        if [[ -d "$PLUGINS_DIR/$plugin" ]]; then
            installed=" (installed)"
        fi
        echo "  • $plugin$installed"
        echo "    ${PLUGIN_REPOS[$plugin]}"
        echo ""
    done
}

usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  list                    List installed plugins"
    echo "  available              List popular plugins available for installation"
    echo "  install <name> [url]   Install a plugin (uses known repos if URL not provided)"
    echo "  remove <name>          Remove a plugin"
    echo "  update <name>          Update a plugin from its git repository"
    echo "  help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 install zsh-z"
    echo "  $0 install my-plugin https://github.com/user/my-plugin"
    echo "  $0 update zsh-autosuggestions"
    echo "  $0 remove old-plugin"
}

main() {
    case "${1:-list}" in
        list)
            list_plugins
            ;;
        available)
            list_available
            ;;
        install)
            install_plugin "$2" "$3"
            ;;
        remove)
            remove_plugin "$2"
            ;;
        update)
            update_plugin "$2"
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
