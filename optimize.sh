#!/bin/bash

# ZSH Configuration Optimizer
# Analyzes and optimizes zsh startup performance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[OPTIMIZE]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

benchmark_startup() {
    print_status "Benchmarking zsh startup time..."
    
    local times=()
    local total_time=0
    local runs=5
    
    for i in $(seq 1 $runs); do
        echo -n "  Run $i/$runs: "
        
        # Use time command with proper output capture
        local time_result=$(TIMEFORMAT='%3R'; time (zsh -i -c "exit" 2>/dev/null) 2>&1)
        local startup_time=$(echo "$time_result" | grep -E '^[0-9]+\.[0-9]+$' | head -1)
        
        # If the above doesn't work, use date-based timing
        if [[ -z "$startup_time" ]] || [[ ! "$startup_time" =~ ^[0-9]+\.[0-9]+$ ]]; then
            local start_time=$(date +%s.%N)
            zsh -i -c "exit" 2>/dev/null
            local end_time=$(date +%s.%N)
            startup_time=$(awk "BEGIN {printf \"%.3f\", $end_time - $start_time}")
        fi
        
        times+=($startup_time)
        total_time=$(awk "BEGIN {printf \"%.3f\", $total_time + $startup_time}")
        
        echo "${startup_time}s"
    done
    
    local avg_time=$(awk "BEGIN {printf \"%.3f\", $total_time / $runs}")
    
    # Calculate min and max
    local min_time=${times[0]}
    local max_time=${times[0]}
    for time in "${times[@]}"; do
        if (( $(awk "BEGIN {print ($time < $min_time)}") )); then
            min_time=$time
        fi
        if (( $(awk "BEGIN {print ($time > $max_time)}") )); then
            max_time=$time
        fi
    done
    
    echo ""
    echo "📈 Benchmark Results:"
    echo "   • Average startup time: ${avg_time}s"
    echo "   • Fastest run: ${min_time}s"
    echo "   • Slowest run: ${max_time}s"
    echo ""
    
    # Performance evaluation
    if (( $(awk "BEGIN {print ($avg_time < 0.3)}") )); then
        print_success "🚀 Excellent performance! Your zsh starts very quickly."
    elif (( $(awk "BEGIN {print ($avg_time < 0.5)}") )); then
        print_success "✅ Very good performance! Well-optimized configuration."
    elif (( $(awk "BEGIN {print ($avg_time < 1.0)}") )); then
        print_warning "⚡ Good performance, but there's room for improvement."
        suggest_optimizations
    else
        print_warning "🐌 Slow startup detected - optimization recommended."
        suggest_optimizations
    fi
}

suggest_optimizations() {
    echo ""
    echo "🔧 Performance Optimization Suggestions:"
    echo ""
    echo "1. 🔌 Plugin Analysis:"
    echo "   • Temporarily disable plugins one by one to identify bottlenecks"
    echo "   • Run: ./develop.sh test-plugins"
    echo ""
    echo "2. 📊 Profiling:"
    echo "   • Use 'zprof' to profile plugin loading times"
    echo "   • Add 'zmodload zsh/zprof' to top of .zshrc, then 'zprof' at end"
    echo ""
    echo "3. ⚡ Lazy Loading:"
    echo "   • Consider lazy-loading less critical plugins"
    echo "   • Move heavy initialization to functions called on-demand"
    echo ""
    echo "4. 🗂️ Completion Cache:"
    echo "   • Check if completion cache is being regenerated too often"
    echo "   • Ensure compinit -C is used for faster loading"
    echo ""
    echo "5. 🧹 Cleanup:"
    echo "   • Remove unused aliases and functions"
    echo "   • Minimize sourced files"
    echo "   • Use built-in features instead of external commands where possible"
}

check_plugin_health() {
    print_status "Checking plugin health..."
    
    local plugins_dir="$HOME/.oh-my-zsh/custom/plugins"
    local issues=0
    
    for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-autocomplete zsh-completions zsh-history-substring-search; do
        if [[ -d "$plugins_dir/$plugin" ]]; then
            if [[ -f "$plugins_dir/$plugin/$plugin.plugin.zsh" || -f "$plugins_dir/$plugin/$plugin.zsh" ]]; then
                print_success "Plugin $plugin: OK"
            else
                print_warning "Plugin $plugin: Missing main file"
                ((issues++))
            fi
        else
            print_warning "Plugin $plugin: Not installed"
            ((issues++))
        fi
    done
    
    if [[ $issues -eq 0 ]]; then
        print_success "All plugins are healthy"
    else
        print_warning "$issues plugin issues detected"
    fi
}

analyze_config() {
    print_status "Analyzing configuration..."
    
    if [[ -f "$HOME/.zshrc" ]]; then
        local lines=$(wc -l < "$HOME/.zshrc")
        local aliases=$(grep -c "^alias " "$HOME/.zshrc" 2>/dev/null || echo 0)
        local functions=$(grep -c "^[a-zA-Z_][a-zA-Z0-9_]*() {" "$HOME/.zshrc" 2>/dev/null || echo 0)
        local plugins_line=$(grep -E "^[[:space:]]*plugins=\(" "$HOME/.zshrc" | head -1)
        
        echo "📊 Configuration Statistics:"
        echo "   • Total lines: $lines"
        echo "   • Aliases defined: $aliases"
        echo "   • Functions defined: $functions"
        
        if [[ -n "$plugins_line" ]]; then
            local plugin_count=$(echo "$plugins_line" | tr '(' '\n' | tail -1 | tr ')' '\n' | head -1 | wc -w)
            echo "   • Active plugins: $plugin_count"
        fi
        
        echo ""
        echo "🔍 Configuration Health Checks:"
        
        # Check for potential issues
        local issues=0
        
        if grep -q "compinit" "$HOME/.zshrc"; then
            if grep -q "compinit -C" "$HOME/.zshrc"; then
                print_success "   ✅ Using fast completion initialization (compinit -C)"
            else
                print_warning "   ⚠️  Consider using 'compinit -C' for faster startup"
                ((issues++))
            fi
        fi
        
        local sourced_files=$(grep -c "^source\|^\." "$HOME/.zshrc" 2>/dev/null || echo 0)
        if [[ $sourced_files -gt 5 ]]; then
            print_warning "   ⚠️  Many sourced files detected ($sourced_files) - consider consolidation"
            ((issues++))
        else
            print_success "   ✅ Reasonable number of sourced files ($sourced_files)"
        fi
        
        if grep -q "HISTSIZE.*[0-9]" "$HOME/.zshrc"; then
            local histsize=$(grep "HISTSIZE" "$HOME/.zshrc" | head -1 | grep -o '[0-9]*')
            if [[ $histsize -gt 50000 ]]; then
                print_warning "   ⚠️  Very large history size ($histsize) - may impact performance"
                ((issues++))
            else
                print_success "   ✅ Reasonable history size ($histsize)"
            fi
        fi
        
        if [[ $issues -eq 0 ]]; then
            print_success "   🎉 No configuration issues detected!"
        else
            echo "   📝 $issues potential optimization opportunities found"
        fi
    else
        print_warning "No .zshrc file found"
    fi
}

main() {
    echo "============================================"
    echo "     ZSH Configuration Optimizer"
    echo "============================================"
    echo ""
    
    check_plugin_health
    echo ""
    analyze_config
    echo ""
    benchmark_startup
    
    echo ""
    print_success "🎯 Optimization analysis complete!"
    echo ""
    echo "💡 Quick Tips:"
    echo "   • Your current average startup time: Check results above"
    echo "   • Run './develop.sh profile' for detailed profiling"
    echo "   • Run './develop.sh test-plugins' to test individual plugins"
    echo "   • Consider running this optimizer regularly to track performance"
}

main "$@"
