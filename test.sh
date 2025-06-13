#!/bin/bash

# Quick Test Script for ZSH Configuration
# This script tests the installation without making permanent changes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

echo "============================================"
echo "     ZSH Configuration Test"
echo "============================================"
echo ""

# Test 1: Check if required files exist
print_status "Checking required files..."
files=("config/.zshrc" "install.sh" "uninstall.sh" "themes/suprima-asra.zsh-theme")
all_files_exist=true

for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
        print_success "Found: $file"
    else
        print_error "Missing: $file"
        all_files_exist=false
    fi
done

# Test 2: Check plugins
print_status "Checking plugins..."
required_plugins=("zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-autocomplete" "zsh-completions" "zsh-history-substring-search")
all_plugins_exist=true

for plugin in "${required_plugins[@]}"; do
    if [[ -d "plugins/$plugin" ]]; then
        print_success "Found plugin: $plugin"
    else
        print_error "Missing plugin: $plugin"
        all_plugins_exist=false
    fi
done

# Test 3: Check script permissions
print_status "Checking script permissions..."
scripts=("install.sh" "uninstall.sh")
all_scripts_executable=true

for script in "${scripts[@]}"; do
    if [[ -x "$script" ]]; then
        print_success "Executable: $script"
    else
        print_error "Not executable: $script"
        all_scripts_executable=false
    fi
done

# Test 4: Validate .zshrc syntax
print_status "Validating .zshrc syntax..."
if zsh -n config/.zshrc 2>/dev/null; then
    print_success ".zshrc syntax is valid"
    zshrc_valid=true
else
    print_error ".zshrc syntax has errors"
    zshrc_valid=false
fi

echo ""
echo "============================================"
echo "             Test Summary"
echo "============================================"

if $all_files_exist && $all_plugins_exist && $all_scripts_executable && $zshrc_valid; then
    print_success "All tests passed! Configuration is ready to install."
    echo ""
    echo "To install on this machine: ./install.sh"
    echo "To install on another machine: Copy this directory and run ./install.sh"
    exit 0
else
    print_error "Some tests failed. Please check the issues above."
    exit 1
fi
