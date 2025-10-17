#!/bin/bash

# Docker Compose Cron Check Script - Universal Version
# This script checks if the Docker Compose refresh cron job is installed and working
# Automatically detects macOS vs Ubuntu/Linux and adapts accordingly

set -e  # Exit on any error

# Auto-detect script directory and OS
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
    CRON_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
    CRON_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
else
    OS="Unknown"
    CRON_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
fi

# Configuration
CRON_JOB_ID="docker-compose-refresh"
CRON_COMMENT="# Docker Compose Refresh - Auto-managed by setup-cron.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}ℹ️  [INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ [SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️  [WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}❌ [ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}🔍 [CHECK]${NC} $1"
}

# Function to get current crontab
get_current_crontab() {
    crontab -l 2>/dev/null || echo ""
}

# Function to check if cron job exists
check_cron_job_exists() {
    local current_crontab=$(get_current_crontab)
    
    # Check for either the comment ID or the actual refresh.sh command
    if echo "$current_crontab" | grep -q "$CRON_JOB_ID" || echo "$current_crontab" | grep -q "refresh.sh"; then
        return 0  # Found
    else
        return 1  # Not found
    fi
}

# Function to extract cron job details
extract_cron_job_details() {
    local current_crontab=$(get_current_crontab)
    
    # Extract the schedule line (look for lines that contain our script path)
    local schedule_line=$(echo "$current_crontab" | grep "refresh.sh" | head -1)
    
    if [ -n "$schedule_line" ]; then
        echo "$schedule_line"
    else
        echo ""
    fi
}

# Function to check cron job format
check_cron_job_format() {
    local schedule_line="$1"
    
    if [ -z "$schedule_line" ]; then
        return 1
    fi
    
    # Check if it's a valid cron format (5 fields + command)
    local cron_fields=$(echo "$schedule_line" | awk '{print NF}')
    if [ "$cron_fields" -ge 6 ]; then
        return 0
    else
        return 1
    fi
}

# Function to check if script paths are correct
check_script_paths() {
    local schedule_line="$1"
    
    if [ -z "$schedule_line" ]; then
        return 1
    fi
    
    # Extract the script path from the cron job
    local script_path=$(echo "$schedule_line" | sed 's/.*&& //')
    
    # Check if the script exists
    if [ -f "$script_path" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check if script is executable
check_script_executable() {
    local schedule_line="$1"
    
    if [ -z "$schedule_line" ]; then
        return 1
    fi
    
    # Extract the script path from the cron job
    local script_path=$(echo "$schedule_line" | sed 's/.*&& //')
    
    # Check if the script is executable
    if [ -x "$script_path" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check working directory
check_working_directory() {
    local schedule_line="$1"
    
    if [ -z "$schedule_line" ]; then
        return 1
    fi
    
    # Extract the working directory from the cron job
    local work_dir=$(echo "$schedule_line" | sed 's/.*cd //' | sed 's/ &&.*//')
    
    # Check if the directory exists and contains docker-compose.yml
    if [ -d "$work_dir" ] && [ -f "$work_dir/docker-compose.yml" ]; then
        return 0
    else
        return 1
    fi
}

# Function to check PATH in cron job
check_cron_path() {
    local current_crontab=$(get_current_crontab)
    
    if echo "$current_crontab" | grep -q "PATH=$CRON_PATH"; then
        return 0
    else
        return 1
    fi
}

# Function to check last execution (if logs exist)
check_last_execution() {
    local log_dir="$SCRIPT_DIR/logs"
    
    if [ -d "$log_dir" ]; then
        local latest_log=$(find "$log_dir" -name "refresh-*.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
        
        if [ -n "$latest_log" ] && [ -f "$latest_log" ]; then
            local last_run=$(stat -c %Y "$latest_log" 2>/dev/null || stat -f %m "$latest_log" 2>/dev/null)
            local current_time=$(date +%s)
            local time_diff=$((current_time - last_run))
            
            # Convert to human readable
            if [ $time_diff -lt 3600 ]; then
                echo "Less than 1 hour ago"
            elif [ $time_diff -lt 86400 ]; then
                echo "$((time_diff / 3600)) hours ago"
            else
                echo "$((time_diff / 86400)) days ago"
            fi
        else
            echo "No logs found"
        fi
    else
        echo "No log directory found"
    fi
}

# Function to check cron service status
check_cron_service() {
    if [[ "$OS" == "Linux" ]]; then
        if command -v systemctl >/dev/null 2>&1; then
            if systemctl is-active --quiet cron; then
                echo "Running"
            else
                echo "Not running"
            fi
        else
            echo "Unknown (systemctl not available)"
        fi
    elif [[ "$OS" == "macOS" ]]; then
        # On macOS, cron is usually managed by launchd
        if launchctl list | grep -q com.vixie.cron; then
            echo "Running (launchd)"
        else
            echo "Running (default)"
        fi
    else
        echo "Unknown OS"
    fi
}

# Function to show detailed status
show_detailed_status() {
    print_header "Detailed Cron Job Analysis"
    echo ""
    
    local current_crontab=$(get_current_crontab)
    local schedule_line=$(extract_cron_job_details)
    
    if [ -n "$schedule_line" ]; then
        echo "📋 Cron Job Details:"
        echo "   Schedule: $(echo "$schedule_line" | awk '{print $1, $2, $3, $4, $5}')"
        echo "   Command: $(echo "$schedule_line" | sed 's/^[^ ]* [^ ]* [^ ]* [^ ]* [^ ]* //')"
        echo ""
        
        echo "🔍 Validation Checks:"
        
        # Check format
        if check_cron_job_format "$schedule_line"; then
            print_success "Cron format is valid"
        else
            print_error "Cron format is invalid"
        fi
        
        # Check script paths
        if check_script_paths "$schedule_line"; then
            print_success "Script path exists"
        else
            print_error "Script path does not exist"
        fi
        
        # Check script executable
        if check_script_executable "$schedule_line"; then
            print_success "Script is executable"
        else
            print_error "Script is not executable"
        fi
        
        # Check working directory
        if check_working_directory "$schedule_line"; then
            print_success "Working directory is valid"
        else
            print_error "Working directory is invalid"
        fi
        
        # Check PATH
        if check_cron_path; then
            print_success "PATH is set correctly"
        else
            print_warning "PATH may not be set correctly"
        fi
        
        echo ""
        echo "📊 Additional Information:"
        echo "   Last execution: $(check_last_execution)"
        echo "   Cron service: $(check_cron_service)"
        echo "   OS: $OS"
        
    else
        print_error "No cron job details found"
    fi
}

# Function to show quick status
show_quick_status() {
    if check_cron_job_exists; then
        local schedule_line=$(extract_cron_job_details)
        local schedule=$(echo "$schedule_line" | awk '{print $1, $2, $3, $4, $5}')
        print_success "Cron job is installed"
        echo "   Schedule: $schedule"
        echo "   Last run: $(check_last_execution)"
    else
        print_error "Cron job is NOT installed"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  status, -s     Show quick status (default)"
    echo "  detailed, -d   Show detailed analysis"
    echo "  help, -h       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0             # Quick status check"
    echo "  $0 status      # Quick status check"
    echo "  $0 detailed    # Detailed analysis"
}

# Main execution
main() {
    print_header "Docker Compose Cron Job Check on $OS"
    echo ""
    
    case "${1:-status}" in
        "status"|"-s")
            show_quick_status
            ;;
        "detailed"|"-d")
            show_detailed_status
            ;;
        "help"|"-h")
            show_usage
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    
    echo ""
    print_status "💡 Use './setup-cron.sh' to install or modify cron jobs"
    print_status "💡 Use './refresh.sh' to run refresh manually"
}

# Run main function
main "$@"
