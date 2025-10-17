# 🐳 Docker Compose Homelab

A complete solution for managing Docker Compose services with automated refresh capabilities across macOS and Ubuntu.

## 🚀 Quick Start

### 1. Refresh Services (OS-Aware)
```bash
# Automatically detects your OS and refreshes services
./refresh.sh
```

### 2. Setup Cron Job (OS-Aware)
```bash
# Set up daily refresh at 2 AM
./setup-cron.sh daily

# Set up weekly refresh on Sunday at 3 AM
./setup-cron.sh weekly

# Set up monthly refresh on 1st at 4 AM
./setup-cron.sh monthly

# Custom schedule (every 6 hours)
./setup-cron.sh custom "0 */6 * * *"

# Remove cron job
./setup-cron.sh remove

# Check status
./setup-cron.sh status
```

### 3. Check Cron Job Status (OS-Aware)
```bash
# Quick status check
./check-cron.sh

# Detailed analysis
./check-cron.sh detailed

# Show help
./check-cron.sh help
```

## 📁 Project Structure

```
homelab/
├── refresh.sh                    # 🎯 Main OS-aware refresh script
├── setup-cron.sh                 # 🎯 Main OS-aware cron setup script
├── check-cron.sh                 # 🔍 Main OS-aware cron check script
├── docker-compose.yml            # Docker Compose configuration
├── .env.example                  # Environment variables template
├── scripts/                      # Platform-specific scripts
│   ├── universal/                # Cross-platform scripts
│   │   └── test-cron-env-universal.sh
│   ├── macos/                    # macOS-specific scripts
│   │   ├── refresh-cron.sh
│   │   └── test-cron-env.sh
│   └── ubuntu/                   # Ubuntu-specific scripts
│       ├── refresh-ubuntu.sh
│       └── test-cron-env-ubuntu.sh
├── docs/                         # Documentation
│   ├── ubuntu-setup-guide.md
│   └── crontab-example.txt
└── logs/                         # Log files (auto-created)
    └── refresh-YYYYMMDD.log
```

## 🎯 Main Scripts

### `refresh.sh` - Universal Refresh Script
- ✅ **OS-Aware**: Automatically detects macOS vs Ubuntu/Linux
- ✅ **Idempotent**: Safe to run multiple times
- ✅ **Comprehensive**: Graceful shutdown, image pull, restart, health checks
- ✅ **Logging**: Detailed logs with emojis and timestamps
- ✅ **Locking**: Prevents concurrent runs
- ✅ **Resource Monitoring**: Disk space and memory checks

### `setup-cron.sh` - Universal Cron Setup Script
- ✅ **OS-Aware**: Adapts to macOS and Ubuntu environments
- ✅ **Idempotent**: Safe to run multiple times, removes old jobs
- ✅ **Flexible**: Daily, weekly, monthly, or custom schedules
- ✅ **Prerequisites Check**: Validates Docker access and permissions
- ✅ **Environment Testing**: Tests cron environment compatibility

### `check-cron.sh` - Universal Cron Check Script
- ✅ **OS-Aware**: Automatically detects macOS vs Ubuntu/Linux
- ✅ **Comprehensive**: Quick status and detailed analysis modes
- ✅ **Validation**: Checks cron format, script paths, permissions
- ✅ **Monitoring**: Shows last execution time and cron service status
- ✅ **Troubleshooting**: Identifies common issues and provides solutions

## 🖥️ OS Support

### macOS (Docker Desktop)
- ✅ Automatic Docker Desktop detection
- ✅ User socket permissions (`/Users/username/.docker/run/docker.sock`)
- ✅ No special group requirements
- ✅ Homebrew PATH support

### Ubuntu/Linux (Docker Engine)
- ✅ System Docker daemon support
- ✅ Docker group membership checks
- ✅ System socket permissions (`/var/run/docker.sock`)
- ✅ Systemctl daemon status checks
- ✅ Environment variables for headless operation

## 🔧 Features

### Refresh Script Features
- 🛑 **Graceful Shutdown**: 30-second timeout for clean container stops
- 📥 **Image Updates**: Pulls latest versions of all images
- 🚀 **Service Restart**: Starts services in detached mode
- 🔍 **Health Verification**: Waits for services to become healthy
- 📊 **Status Reporting**: Shows container status and system resources
- 🧹 **Log Rotation**: Automatically cleans up old log files
- 🔒 **Process Locking**: Prevents multiple instances running

### Cron Setup Features
- 📅 **Multiple Schedules**: Daily, weekly, monthly, custom
- 🔄 **Idempotent**: Removes old jobs before adding new ones
- 🧪 **Environment Testing**: Validates cron environment
- 📋 **Status Checking**: Shows current cron configuration
- 🛡️ **Prerequisites**: Validates Docker access and permissions

## 📋 Usage Examples

### Basic Usage
```bash
# Refresh services now
./refresh.sh

# Set up daily refresh at 2 AM
./setup-cron.sh daily

# Check if cron job is installed
./check-cron.sh

# Check what's scheduled
./setup-cron.sh status
```

### Advanced Usage
```bash
# Custom schedule (every 6 hours)
./setup-cron.sh custom "0 */6 * * *"

# Weekly on Monday at 3 AM
./setup-cron.sh weekly 1

# Monthly on 15th at 4 AM
./setup-cron.sh monthly 15

# Test cron environment
./setup-cron.sh test

# Remove cron job
./setup-cron.sh remove

# Detailed cron job analysis
./check-cron.sh detailed
```

### Monitoring
```bash
# Watch logs in real-time
tail -f logs/refresh-$(date +%Y%m%d).log

# Check service status
docker compose ps

# Check service logs
docker compose logs -f
```

## 🚨 Troubleshooting

### Permission Issues
```bash
# Ubuntu: Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Test Docker access
docker ps
```

### Cron Issues
```bash
# Test cron environment
./setup-cron.sh test

# Check cron logs
sudo journalctl -u cron  # Ubuntu
log show --predicate 'process == "cron"' --last 1h  # macOS
```

### Service Issues
```bash
# Check service status
docker compose ps

# View service logs
docker compose logs -f

# Restart specific service
docker compose restart service-name
```

## 📊 Logs

Logs are automatically created in the `logs/` directory:
- `refresh-YYYYMMDD.log` - Daily refresh logs
- `cron-test-YYYYMMDD-HHMMSS.log` - Environment test logs

Log files are automatically rotated after 7 days.

## 🔒 Security

- ✅ Process locking prevents concurrent runs
- ✅ Graceful shutdown with timeout
- ✅ Health verification before completion
- ✅ Resource monitoring and warnings
- ✅ Comprehensive error handling

## 🤝 Contributing

1. Test on both macOS and Ubuntu
2. Ensure scripts are idempotent
3. Add appropriate error handling
4. Update documentation
5. Test cron environment compatibility

## 📄 License

This project is part of your homelab setup. Use and modify as needed.