#!/bin/bash

# Universal test script to verify cron environment has Docker access
# Auto-detects macOS vs Ubuntu/Linux and tests accordingly

# Auto-detect script directory and create log path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMELAB_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# File and Directory Paths
DOCKER_COMPOSE_FILE="${HOMELAB_DIR}/docker-compose.yml"
LOG_DIR="${HOMELAB_DIR}/logs"
LOG_FILE="${LOG_DIR}/cron-test-$(date +%Y%m%d-%H%M%S).log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
    DOCKER_SOCKET="/Users/$(whoami)/.docker/run/docker.sock"
    CRON_PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
    DOCKER_SOCKET="/var/run/docker.sock"
    CRON_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
else
    OS="Unknown"
    DOCKER_SOCKET="/var/run/docker.sock"
    CRON_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🖥️  Testing cron environment on $OS..." | tee "$LOG_FILE"

# Test 1: Check user
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 👤 User: $(whoami)" | tee -a "$LOG_FILE"

# Test 2: Check PATH
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🛤️  PATH: $PATH" | tee -a "$LOG_FILE"

# Test 3: Check Docker command availability
if command -v docker >/dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Docker command found" | tee -a "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🐳 Docker version: $(docker --version)" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Docker command NOT found" | tee -a "$LOG_FILE"
fi

# Test 4: Check Docker Compose
if docker compose version >/dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Docker Compose available" | tee -a "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🐙 Docker Compose version: $(docker compose version --short)" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Docker Compose NOT available" | tee -a "$LOG_FILE"
fi

# Test 5: Check Docker socket access (OS-specific)
if [ -S "$DOCKER_SOCKET" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Docker socket accessible at $DOCKER_SOCKET" | tee -a "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔌 Socket permissions: $(ls -la "$DOCKER_SOCKET")" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Docker socket NOT accessible at $DOCKER_SOCKET" | tee -a "$LOG_FILE"
fi

# Test 6: Check if user is in docker group (Linux only)
if [[ "$OS" == "Linux" ]]; then
    if groups | grep -q docker; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ User is in 'docker' group" | tee -a "$LOG_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 👥 User groups: $(groups)" | tee -a "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  User NOT in 'docker' group" | tee -a "$LOG_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 👥 User groups: $(groups)" | tee -a "$LOG_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 💡 Run: sudo usermod -aG docker \$USER && newgrp docker" | tee -a "$LOG_FILE"
    fi
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ℹ️  Docker group check skipped (not needed on $OS)" | tee -a "$LOG_FILE"
fi

# Test 7: Try to run docker ps
if docker ps >/dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Docker ps works" | tee -a "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 📦 Running containers:" | tee -a "$LOG_FILE"
    docker ps --format "table {{.Names}}\t{{.Status}}" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Docker ps FAILED" | tee -a "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 💡 This usually means permission issues" | tee -a "$LOG_FILE"
fi

# Test 8: Check working directory
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 📁 Working directory: $(pwd)" | tee -a "$LOG_FILE"

# Test 9: Check if docker-compose.yml exists
if [ -f "$DOCKER_COMPOSE_FILE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ docker-compose.yml found at $DOCKER_COMPOSE_FILE" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ docker-compose.yml NOT found at $DOCKER_COMPOSE_FILE" | tee -a "$LOG_FILE"
fi

# Test 10: Check system information
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 💻 System info: $(uname -a)" | tee -a "$LOG_FILE"
if command -v lsb_release >/dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🐧 OS: $(lsb_release -d)" | tee -a "$LOG_FILE"
elif [[ "$OS" == "macOS" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🍎 OS: macOS $(sw_vers -productVersion)" | tee -a "$LOG_FILE"
fi

# Test 11: Check Docker daemon status (Linux only)
if [[ "$OS" == "Linux" ]]; then
    if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet docker; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Docker daemon is running" | tee -a "$LOG_FILE"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Docker daemon is NOT running" | tee -a "$LOG_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 💡 Run: sudo systemctl start docker" | tee -a "$LOG_FILE"
    fi
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ℹ️  Docker daemon check skipped (Docker Desktop on $OS)" | tee -a "$LOG_FILE"
fi

# Test 12: Check disk space
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 💾 Disk usage:" | tee -a "$LOG_FILE"
df -h | grep -E "(Filesystem|/dev/)" | tee -a "$LOG_FILE"

# Test 13: Check memory
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🧠 Memory usage:" | tee -a "$LOG_FILE"
if command -v free >/dev/null 2>&1; then
    free -h | tee -a "$LOG_FILE"
else
    echo "Memory info not available on this system" | tee -a "$LOG_FILE"
fi

# Test 14: Test cron environment simulation
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🕐 Testing minimal cron environment..." | tee -a "$LOG_FILE"
if env -i PATH="$CRON_PATH" HOME="$HOME" USER="$(whoami)" docker ps >/dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Docker works in minimal cron environment" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Docker does NOT work in minimal cron environment" | tee -a "$LOG_FILE"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🎊 Test completed. Check log: $LOG_FILE" | tee -a "$LOG_FILE"

# Summary
echo "" | tee -a "$LOG_FILE"
echo "=== SUMMARY ===" | tee -a "$LOG_FILE"
if docker ps >/dev/null 2>&1 && [ -f "$DOCKER_COMPOSE_FILE" ]; then
    echo "✅ READY FOR CRON: All tests passed!" | tee -a "$LOG_FILE"
    echo "💡 You can now safely add this to your crontab" | tee -a "$LOG_FILE"
    echo "📋 Recommended cron command:" | tee -a "$LOG_FILE"
    echo "   0 2 * * * cd $HOMELAB_DIR && $HOMELAB_DIR/scripts/refresh.sh" | tee -a "$LOG_FILE"
    if [[ "$OS" == "Linux" ]]; then
        echo "   # Same command works on Ubuntu/Linux too!" | tee -a "$LOG_FILE"
    fi
else
    echo "❌ NOT READY: Some tests failed" | tee -a "$LOG_FILE"
    echo "💡 Fix the issues above before setting up cron" | tee -a "$LOG_FILE"
fi
