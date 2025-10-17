# 🐧 Ubuntu Headless Server Setup Guide

## Prerequisites

### 1. Install Docker on Ubuntu

```bash
# Update package index
sudo apt update

# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
sudo apt update

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker
```

### 2. Configure User Permissions

```bash
# Add your user to the docker group
sudo usermod -aG docker $USER

# Apply group changes (logout and login, or use newgrp)
newgrp docker

# Verify Docker works without sudo
docker --version
docker compose version
docker ps
```

### 3. Test Docker Socket Permissions

```bash
# Check Docker socket
ls -la /var/run/docker.sock

# Should show something like:
# srw-rw---- 1 root docker 0 [date] /var/run/docker.sock

# Test access
docker ps
```

## 🚀 Deployment Steps

### 1. Upload Files to Server

```bash
# Copy your homelab files to the server
scp -r /Users/n8/code/n8io/homelab/ user@your-server:/home/user/

# Or use git
git clone your-repo-url
```

### 2. Set Up Environment Variables

```bash
# Create .env file
cp .env.example .env

# Edit with your values
nano .env
```

### 3. Test the Environment

```bash
# Test cron environment compatibility
./test-cron-env-universal.sh

# Or use Ubuntu-specific test
./test-cron-env-ubuntu.sh

# Make script executable
chmod +x refresh-ubuntu.sh

# Test manually first
./refresh-ubuntu.sh

# Check logs
tail -f logs/refresh-$(date +%Y%m%d).log
```

### 4. Set Up Cron Job

```bash
# Edit crontab
crontab -e

# Add one of these lines:
# Daily at 2 AM
0 2 * * * cd /home/user/homelab && /home/user/homelab/refresh-ubuntu.sh

# Weekly on Sunday at 3 AM
0 3 * * 0 cd /home/user/homelab && /home/user/homelab/refresh-ubuntu.sh

# With logging
0 2 * * * cd /home/user/homelab && /home/user/homelab/refresh-ubuntu.sh >> /var/log/docker-refresh.log 2>&1
```

## 🔧 Ubuntu-Specific Considerations

### 1. **Docker Socket Location**
- **macOS**: `/Users/username/.docker/run/docker.sock`
- **Ubuntu**: `/var/run/docker.sock`

### 2. **User Groups**
- **macOS**: No special group needed
- **Ubuntu**: Must be in `docker` group

### 3. **Environment Variables**
- Added `COMPOSE_INTERACTIVE_NO_CLI=1` for headless operation
- Added `DOCKER_BUILDKIT=0` for compatibility
- Added `COMPOSE_DOCKER_CLI_BUILD=0` for older systems

### 4. **System Resource Monitoring**
- Added disk space checks
- Added memory usage monitoring
- Added system info logging

### 5. **Path Differences**
- Ubuntu uses `/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`
- macOS uses `/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin`

## 🚨 Troubleshooting

### Permission Denied Errors
```bash
# Check if user is in docker group
groups $USER

# If not, add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Check Docker socket permissions
ls -la /var/run/docker.sock
```

### Docker Not Found in Cron
```bash
# Add full PATH to cron job
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
0 2 * * * cd /home/user/homelab && /home/user/homelab/refresh-ubuntu.sh
```

### Services Not Starting
```bash
# Check Docker daemon status
sudo systemctl status docker

# Check logs
journalctl -u docker.service

# Restart Docker if needed
sudo systemctl restart docker
```

### Disk Space Issues
```bash
# Clean up Docker resources
docker system prune -a

# Check disk usage
df -h

# Clean up old logs
find logs/ -name "*.log" -mtime +7 -delete
```

## 📊 Monitoring

### Check Cron Job Status
```bash
# View cron logs
sudo journalctl -u cron

# Check if cron job ran
grep "docker-refresh" /var/log/syslog
```

### Monitor Script Logs
```bash
# Real-time log monitoring
tail -f logs/refresh-$(date +%Y%m%d).log

# Check all logs
ls -la logs/
```

### Service Health Checks
```bash
# Check container status
docker compose ps

# Check service logs
docker compose logs -f

# Check system resources
htop
df -h
free -h
```

## ✅ Verification Checklist

- [ ] Docker installed and running
- [ ] User added to docker group
- [ ] Docker commands work without sudo
- [ ] Script runs manually without errors
- [ ] Cron job added and scheduled
- [ ] Logs are being created
- [ ] Services start and become healthy
- [ ] System resources are adequate
- [ ] Backup strategy in place

## 🔄 Migration from macOS

1. **Update script**: Use `refresh-ubuntu.sh` instead of `refresh-cron.sh`
2. **Update paths**: Change all paths to Ubuntu equivalents
3. **Update permissions**: Ensure user is in docker group
4. **Test thoroughly**: Run manual tests before setting up cron
5. **Monitor logs**: Watch logs for any Ubuntu-specific issues
