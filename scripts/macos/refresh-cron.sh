#!/bin/bash

# Docker Compose Refresh Script - Cron Version
# This script gracefully shuts down containers, pulls latest images, and restarts services
# Optimized for running from cron jobs

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/refresh-$(date +%Y%m%d).log"
LOCK_FILE="/tmp/docker-refresh.lock"
MAX_LOG_DAYS=7

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_success() {
    log "✅ SUCCESS: $1"
}

log_error() {
    log "❌ ERROR: $1"
}

log_warning() {
    log "⚠️  WARNING: $1"
}

log_info() {
    log "ℹ️  INFO: $1"
}

# Function to cleanup old logs
cleanup_logs() {
    find "$LOG_DIR" -name "refresh-*.log" -type f -mtime +$MAX_LOG_DAYS -delete 2>/dev/null || true
}

# Function to acquire lock
acquire_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_error "🔒 Another refresh process is already running (PID: $pid)"
            exit 1
        else
            log_warning "🧹 Stale lock file found, removing it"
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

# Function to release lock
release_lock() {
    rm -f "$LOCK_FILE"
}

# Function to setup environment
setup_environment() {
    # Add common paths where Docker might be installed
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Verify we're in the right directory
    if [ ! -f "docker-compose.yml" ]; then
        log_error "📄 docker-compose.yml not found in $SCRIPT_DIR"
        exit 1
    fi
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        log_error "🐳 Docker command not found in PATH"
        exit 1
    fi
    
    # Check if docker compose is available
    if ! docker compose version >/dev/null 2>&1; then
        log_error "🐙 Docker Compose not available"
        exit 1
    fi
}

# Function to gracefully shutdown containers
graceful_shutdown() {
    log_info "🛑 Gracefully shutting down Docker Compose services..."
    
    if docker compose ps -q | grep -q .; then
        log_info "⏳ Stopping containers with 30 second timeout..."
        if docker compose down --timeout 30 >> "$LOG_FILE" 2>&1; then
            log_success "🛑 Containers stopped gracefully"
        else
            log_error "💥 Failed to stop containers gracefully"
            return 1
        fi
    else
        log_warning "📭 No running containers found"
    fi
}

# Function to pull latest images
pull_latest_images() {
    log_info "📥 Pulling latest Docker images..."
    
    if docker compose pull >> "$LOG_FILE" 2>&1; then
        log_success "📦 Latest images pulled successfully"
    else
        log_error "📥 Failed to pull latest images"
        return 1
    fi
}

# Function to restart services in background
restart_services() {
    log_info "🚀 Starting services in background..."
    
    if docker compose up -d >> "$LOG_FILE" 2>&1; then
        log_success "🎉 Services started in background"
        
        # Wait a moment for services to start
        sleep 5
        
        # Show status of services
        log_info "📊 Service status:"
        docker compose ps >> "$LOG_FILE" 2>&1
    else
        log_error "🚫 Failed to start services"
        return 1
    fi
}

# Function to verify services are healthy
verify_services() {
    log_info "🔍 Verifying service health..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local unhealthy_services=$(docker compose ps --format "table {{.Service}}\t{{.Status}}" | grep -v "healthy" | grep -v "SERVICE" | wc -l)
        
        if [ "$unhealthy_services" -eq 0 ]; then
            log_success "🎊 All services are healthy!"
            return 0
        fi
        
        log_info "⏳ Waiting for services to become healthy (attempt $attempt/$max_attempts)..."
        sleep 10
        ((attempt++))
    done
    
    log_warning "⚠️  Some services may not be fully healthy after $max_attempts attempts"
    docker compose ps >> "$LOG_FILE" 2>&1
}

# Main execution
main() {
    log_info "🔄 Starting Docker Compose refresh process..."
    
    # Setup trap to ensure lock is released on exit
    trap 'release_lock' EXIT INT TERM
    
    # Acquire lock to prevent concurrent runs
    acquire_lock
    
    # Setup environment
    setup_environment
    
    # Cleanup old logs
    cleanup_logs
    
    # Step 1: Graceful shutdown
    if ! graceful_shutdown; then
        log_error "🛑 Graceful shutdown failed"
        exit 1
    fi
    
    # Step 2: Pull latest images
    if ! pull_latest_images; then
        log_error "📥 Image pull failed"
        exit 1
    fi
    
    # Step 3: Restart services
    if ! restart_services; then
        log_error "🚀 Service restart failed"
        exit 1
    fi
    
    # Step 4: Verify services are healthy
    verify_services
    
    log_success "🎊 Docker Compose refresh completed successfully!"
    log_info "📋 Log file: $LOG_FILE"
    log_info "💡 Check service status with: docker compose ps"
    log_info "💡 Monitor logs with: docker compose logs -f"
}

# Run main function
main "$@"
