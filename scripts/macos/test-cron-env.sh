#!/bin/bash

# Test script to verify cron environment has Docker access
# Run this manually first, then add to cron to test

LOG_FILE="/Users/n8/code/n8io/homelab/logs/cron-test-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Testing cron environment..." | tee "$LOG_FILE"

# Test 1: Check user
echo "[$(date '+%Y-%m-%d %H:%M:%S')] User: $(whoami)" | tee -a "$LOG_FILE"

# Test 2: Check PATH
echo "[$(date '+%Y-%m-%d %H:%M:%S')] PATH: $PATH" | tee -a "$LOG_FILE"

# Test 3: Check Docker command availability
if command -v docker >/dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Docker command found" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Docker command NOT found" | tee -a "$LOG_FILE"
fi

# Test 4: Check Docker Compose
if docker compose version >/dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Docker Compose available" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Docker Compose NOT available" | tee -a "$LOG_FILE"
fi

# Test 5: Check Docker socket access
if [ -S "/Users/n8/.docker/run/docker.sock" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Docker socket accessible" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Docker socket NOT accessible" | tee -a "$LOG_FILE"
fi

# Test 6: Try to run docker ps
if docker ps >/dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Docker ps works" | tee -a "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running containers:" | tee -a "$LOG_FILE"
    docker ps --format "table {{.Names}}\t{{.Status}}" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Docker ps FAILED" | tee -a "$LOG_FILE"
fi

# Test 7: Check working directory
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Working directory: $(pwd)" | tee -a "$LOG_FILE"

# Test 8: Check if docker-compose.yml exists
if [ -f "docker-compose.yml" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ docker-compose.yml found" | tee -a "$LOG_FILE"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ docker-compose.yml NOT found" | tee -a "$LOG_FILE"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Test completed. Check log: $LOG_FILE" | tee -a "$LOG_FILE"
