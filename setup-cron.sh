#!/bin/bash

# Docker Compose Cron Setup Script - OS-Aware Universal Version
# This script sets up cron jobs for Docker Compose refresh in an idempotent way
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

# Function to check prerequisites
check_prerequisites() {
    print_status "🔍 Checking prerequisites..."
    
    # Check if we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        print_error "📄 docker-compose.yml not found in $SCRIPT_DIR"
        print_error "💡 Please run this script from your homelab directory"
        exit 1
    fi
    
    # Check if refresh script exists
    if [ ! -f "refresh.sh" ]; then
        print_error "🔄 refresh.sh not found in $SCRIPT_DIR"
        print_error "💡 Please ensure the refresh script is in the same directory"
        exit 1
    fi
    
    # Check if refresh script is executable
    if [ ! -x "refresh.sh" ]; then
        print_warning "🔧 Making refresh.sh executable..."
        chmod +x refresh.sh
    fi
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        print_error "🐳 Docker command not found"
        print_error "💡 Please install Docker first"
        exit 1
    fi
    
    # Check if docker compose is available
    if ! docker compose version >/dev/null 2>&1; then
        print_error "🐙 Docker Compose not available"
        print_error "💡 Please install Docker Compose first"
        exit 1
    fi
    
    # Test Docker access
    if ! docker ps >/dev/null 2>&1; then
        print_error "🚫 Cannot access Docker"
        if [[ "$OS" == "Linux" ]]; then
            print_error "💡 Run: sudo usermod -aG docker \$USER && newgrp docker"
        else
            print_error "💡 Ensure Docker Desktop is running and accessible"
        fi
        exit 1
    fi
    
    print_success "✅ All prerequisites met"
}

# Function to get current crontab
get_current_crontab() {
    crontab -l 2>/dev/null || echo ""
}

# Function to remove existing cron job
remove_existing_cron_job() {
    local current_crontab=$(get_current_crontab)
    local temp_crontab=$(mktemp)
    
    # Remove lines containing our cron job ID, comment, or refresh.sh script
    echo "$current_crontab" | grep -v "$CRON_JOB_ID" | grep -v "$CRON_COMMENT" | grep -v "refresh.sh" > "$temp_crontab"
    
    # Install the cleaned crontab
    crontab "$temp_crontab"
    rm -f "$temp_crontab"
}

# Function to add cron job
add_cron_job() {
    local schedule="$1"
    local description="$2"
    
    print_status "📅 Adding cron job: $description"
    print_status "⏰ Schedule: $schedule"
    
    # Remove existing job first
    remove_existing_cron_job
    
    # Get current crontab
    local current_crontab=$(get_current_crontab)
    local temp_crontab=$(mktemp)
    
    # Create new crontab with our job
    {
        echo "$current_crontab"
        echo ""
        echo "$CRON_COMMENT"
        echo "# $CRON_JOB_ID: $description"
        echo "PATH=$CRON_PATH"
        echo "$schedule cd $SCRIPT_DIR && $SCRIPT_DIR/refresh.sh"
    } > "$temp_crontab"
    
    # Install the new crontab
    crontab "$temp_crontab"
    rm -f "$temp_crontab"
    
    print_success "✅ Cron job added successfully"
}

# Function to show current cron jobs
show_current_cron_jobs() {
    print_status "📋 Current cron jobs:"
    local current_crontab=$(get_current_crontab)
    if [ -n "$current_crontab" ]; then
        echo "$current_crontab" | grep -E "(docker-compose|refresh)" || echo "No Docker Compose cron jobs found"
    else
        echo "No crontab configured"
    fi
}

# Function to test cron environment
test_cron_environment() {
    print_status "🧪 Testing cron environment..."
    
    # Check if test script exists
    if [ -f "scripts/universal/test-cron-env-universal.sh" ]; then
        print_status "🔬 Running comprehensive cron environment test..."
        ./scripts/universal/test-cron-env-universal.sh
    else
        print_warning "⚠️  Test script not found, running basic test..."
        
        # Basic test
        if env -i PATH="$CRON_PATH" HOME="$HOME" USER="$(whoami)" docker ps >/dev/null 2>&1; then
            print_success "✅ Docker works in minimal cron environment"
        else
            print_error "❌ Docker does NOT work in minimal cron environment"
            print_error "💡 This may cause issues with the cron job"
        fi
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  daily [time]     Set up daily refresh (default: 2 AM)"
    echo "  weekly [day]     Set up weekly refresh (default: Sunday 3 AM)"
    echo "  monthly [day]    Set up monthly refresh (default: 1st 4 AM)"
    echo "  custom <schedule> Set up custom schedule (cron format)"
    echo "  remove           Remove existing cron job"
    echo "  status           Show current cron job status"
    echo "  test             Test cron environment"
    echo "  help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 daily                    # Daily at 2 AM"
    echo "  $0 daily 3                  # Daily at 3 AM"
    echo "  $0 weekly                   # Weekly on Sunday at 3 AM"
    echo "  $0 weekly 1                 # Weekly on Monday at 3 AM"
    echo "  $0 monthly                  # Monthly on 1st at 4 AM"
    echo "  $0 monthly 15               # Monthly on 15th at 4 AM"
    echo "  $0 custom '0 */6 * * *'     # Every 6 hours"
    echo "  $0 remove                   # Remove cron job"
    echo "  $0 status                   # Show status"
    echo "  $0 test                     # Test environment"
}

# Main execution
main() {
    print_status "🖥️  Setting up Docker Compose cron job on $OS..."
    
    # Check prerequisites
    check_prerequisites
    
    # Parse arguments
    case "${1:-help}" in
        "daily")
            local time="${2:-2}"
            add_cron_job "0 $time * * *" "Daily refresh at $time:00 AM"
            ;;
        "weekly")
            local day="${2:-0}"  # 0=Sunday, 1=Monday, etc.
            local day_name=""
            case "$day" in
                0) day_name="Sunday" ;;
                1) day_name="Monday" ;;
                2) day_name="Tuesday" ;;
                3) day_name="Wednesday" ;;
                4) day_name="Thursday" ;;
                5) day_name="Friday" ;;
                6) day_name="Saturday" ;;
                *) print_error "Invalid day. Use 0-6 (0=Sunday)"; exit 1 ;;
            esac
            add_cron_job "0 3 * * $day" "Weekly refresh on $day_name at 3:00 AM"
            ;;
        "monthly")
            local day="${2:-1}"
            if [ "$day" -lt 1 ] || [ "$day" -gt 31 ]; then
                print_error "Invalid day. Use 1-31"
                exit 1
            fi
            add_cron_job "0 4 $day * *" "Monthly refresh on $day at 4:00 AM"
            ;;
        "custom")
            if [ -z "$2" ]; then
                print_error "Custom schedule required"
                print_error "Example: $0 custom '0 */6 * * *'"
                exit 1
            fi
            add_cron_job "$2" "Custom schedule: $2"
            ;;
        "remove")
            print_status "🗑️  Removing existing cron job..."
            remove_existing_cron_job
            print_success "✅ Cron job removed"
            ;;
        "status")
            show_current_cron_jobs
            ;;
        "test")
            test_cron_environment
            ;;
        "help"|*)
            show_usage
            ;;
    esac
    
    # Show final status only for setup commands
    if [ "${1:-help}" = "daily" ] || [ "${1:-help}" = "weekly" ] || [ "${1:-help}" = "monthly" ] || [ "${1:-help}" = "custom" ]; then
        echo ""
        show_current_cron_jobs
        echo ""
        print_success "🎊 Cron setup completed!"
        print_status "💡 Monitor logs with: tail -f logs/refresh-\$(date +%Y%m%d).log"
        print_status "💡 Test manually with: ./refresh.sh"
    fi
}

# Run main function
main "$@"
