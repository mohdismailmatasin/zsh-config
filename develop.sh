#!/bin/bash

# Development and Testing Environment Setup
# Creates isolated test environments for zsh configuration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

TEST_DIR="$HOME/.zsh-config-test"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_status() {
    echo -e "${BLUE}[DEV]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

create_test_env() {
    print_status "Creating isolated test environment..."
    
    # Create test directory
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    
    # Create isolated home directory
    export ZDOTDIR="$TEST_DIR"
    export HOME="$TEST_DIR"
    
    # Copy configuration package
    cp -r "$SCRIPT_DIR" "$TEST_DIR/zsh-config"
    
    print_success "Test environment created at: $TEST_DIR"
    print_status "To test: cd $TEST_DIR/zsh-config && ./install.sh"
}

benchmark_config() {
    print_status "Running performance benchmarks..."
    
    local iterations=10
    local total_time=0
    
    for i in $(seq 1 $iterations); do
        local start_time=$(date +%s.%N)
        zsh -i -c "exit" 2>/dev/null
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l)
        total_time=$(echo "$total_time + $duration" | bc -l)
        echo "Run $i: ${duration}s"
    done
    
    local avg_time=$(echo "scale=3; $total_time / $iterations" | bc -l)
    print_success "Average startup time: ${avg_time}s"
}

profile_startup() {
    print_status "Profiling zsh startup with zprof..."
    
    # Create temporary profile script
    cat > /tmp/profile_zsh.zsh << 'EOF'
zmodload zsh/zprof
source ~/.zshrc
zprof
EOF
    
    zsh /tmp/profile_zsh.zsh
    rm -f /tmp/profile_zsh.zsh
}

test_plugins_individually() {
    print_status "Testing plugins individually..."
    
    local plugins=("git" "zsh-autosuggestions" "zsh-syntax-highlighting" "zsh-autocomplete" "zsh-completions" "zsh-history-substring-search")
    
    for plugin in "${plugins[@]}"; do
        print_status "Testing plugin: $plugin"
        
        # Create minimal config with just this plugin
        cat > /tmp/test_zshrc << EOF
export ZSH="\$HOME/.oh-my-zsh"
plugins=($plugin)
source \$ZSH/oh-my-zsh.sh
EOF
        
        # Test startup time
        local start_time=$(date +%s.%N)
        ZDOTDIR=/tmp zsh -i -c "source /tmp/test_zshrc; exit" 2>/dev/null
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l)
        
        echo "  $plugin: ${duration}s"
    done
    
    rm -f /tmp/test_zshrc
}

validate_theme() {
    print_status "Validating theme configuration..."
    
    local theme_file="$SCRIPT_DIR/themes/suprima-asra.zsh-theme"
    
    if [[ -f "$theme_file" ]]; then
        if zsh -n "$theme_file" 2>/dev/null; then
            print_success "Theme syntax is valid"
        else
            print_warning "Theme has syntax errors"
            zsh -n "$theme_file"
        fi
    else
        print_warning "Theme file not found"
    fi
}

check_compatibility() {
    print_status "Checking system compatibility..."
    
    # Check zsh version
    local zsh_version=$(zsh --version | head -n1)
    echo "ZSH Version: $zsh_version"
    
    # Check for required commands
    local required_commands=("git" "curl" "sed" "awk" "grep")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -eq 0 ]]; then
        print_success "All required commands are available"
    else
        print_warning "Missing commands: ${missing_commands[*]}"
    fi
    
    # Check optional commands
    local optional_commands=("lsd" "nvim" "vim" "bc")
    echo ""
    echo "Optional commands:"
    for cmd in "${optional_commands[@]}"; do
        if command -v "$cmd" &> /dev/null; then
            echo "  ✓ $cmd"
        else
            echo "  ○ $cmd (optional)"
        fi
    done
}

usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  test-env            Create isolated test environment"
    echo "  benchmark           Run startup time benchmarks"
    echo "  profile             Profile startup with zprof"
    echo "  test-plugins        Test each plugin individually"
    echo "  validate-theme      Validate theme syntax"
    echo "  compatibility       Check system compatibility"
    echo "  all                 Run all tests"
    echo "  help                Show this help message"
}

main() {
    case "${1:-all}" in
        test-env)
            create_test_env
            ;;
        benchmark)
            if command -v bc &> /dev/null; then
                benchmark_config
            else
                print_warning "bc calculator required for benchmarks"
            fi
            ;;
        profile)
            profile_startup
            ;;
        test-plugins)
            if command -v bc &> /dev/null; then
                test_plugins_individually
            else
                print_warning "bc calculator required for plugin testing"
            fi
            ;;
        validate-theme)
            validate_theme
            ;;
        compatibility)
            check_compatibility
            ;;
        all)
            check_compatibility
            echo ""
            validate_theme
            echo ""
            if command -v bc &> /dev/null; then
                benchmark_config
                echo ""
                test_plugins_individually
            else
                print_warning "Install 'bc' for performance testing"
            fi
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
