# 🔒 n8n Security Configuration Guide

## 🚨 Critical Security Steps Before Deployment

### 1. Generate Secure Credentials
Use the automated script to generate secure credentials:

```bash
# Cross-platform script (works on macOS and Ubuntu/Linux)
./scripts/generate-secrets.sh
```

This script will:
- Generate strong encryption keys and passwords
- Create a secure `.env` file
- Provide platform-specific installation instructions
- Work idempotently (safe to run multiple times)

### 2. Configure Your Domain
Edit the generated `.env` file with your actual domain and email:

```bash
DOMAIN=your-actual-domain.com
```

### 3. Install Optional Dependencies (Recommended)
For better n8n basic authentication security:

```bash
# macOS
brew install httpd

# Ubuntu/Debian
sudo apt-get install apache2-utils

# CentOS/RHEL
sudo yum install httpd-tools
```

## 🔧 Security Features Implemented

### ✅ Authentication & Authorization
- **n8n Basic Auth**: Enabled by default
- **Caddy Reverse Proxy**: Automatic HTTPS with Let's Encrypt
- **Secure Cookies**: Enabled for session management

### ✅ Encryption
- **Data Encryption**: N8N_ENCRYPTION_KEY for sensitive workflow data
- **TLS/SSL**: Automatic Let's Encrypt certificates via Caddy
- **Database Encryption**: SCRAM-SHA-256 authentication

### ✅ Container Security
- **Non-root Users**: All containers run as non-privileged users
- **No New Privileges**: Security option prevents privilege escalation
- **Resource Limits**: CPU and memory limits to prevent DoS

### ✅ Network Security
- **Security Headers**: HSTS, XSS protection, content type sniffing prevention
- **HTTPS Redirect**: Automatic HTTP to HTTPS redirection
- **Internal Network**: Services communicate on isolated Docker network

### ✅ Database Security
- **Dedicated User**: Separate PostgreSQL user for n8n
- **Strong Authentication**: SCRAM-SHA-256 password hashing
- **Resource Limits**: Memory and CPU constraints

## 🛡️ Additional Security Recommendations

### Firewall Configuration
```bash
# Ubuntu/Debian
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable

# macOS (if using pfctl)
# Configure pfctl rules for port restrictions
```

### Regular Updates
- Keep Docker images updated: `docker compose pull && docker compose up -d`
- Monitor n8n releases for security updates
- Update host OS regularly

### Backup Strategy
```bash
# Database backup
docker exec n8n_postgres pg_dump -U n8n_user n8n > backup_$(date +%Y%m%d).sql

# n8n data backup
docker run --rm -v n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n_data_$(date +%Y%m%d).tar.gz -C /data .
```

### Monitoring
- Enable Caddy access logs
- Monitor n8n logs for suspicious activity
- Set up alerts for failed authentication attempts

## 🚨 Security Checklist

Before going live, ensure:

- [ ] Strong encryption key generated and set
- [ ] Basic authentication configured for n8n
- [ ] Caddy TLS configuration set appropriately
- [ ] Strong database password set
- [ ] Firewall configured (ports 22, 80, 443 only)
- [ ] SSL certificates working
- [ ] Backup strategy implemented
- [ ] Monitoring/logging enabled
- [ ] Regular update schedule planned

## 🔍 Security Testing

### Test Authentication
```bash
# Test n8n login
curl -u admin:password https://your-domain.com/login

# Test Caddy reverse proxy
curl -I https://your-domain.com
```

### Test SSL
```bash
# Check SSL configuration
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

### Test Security Headers
```bash
# Check security headers
curl -I https://your-domain.com
```

## 📞 Incident Response

If you suspect a security breach:

1. **Immediate Actions**:
   - Change all passwords
   - Rotate encryption key (will require re-encrypting data)
   - Review access logs
   - Update all components

2. **Investigation**:
   - Check Docker logs: `docker compose logs`
   - Review Caddy access logs
   - Analyze n8n audit logs

3. **Recovery**:
   - Restore from clean backup if needed
   - Re-deploy with updated security measures
   - Monitor for continued suspicious activity

## 📚 Additional Resources

- [n8n Security Documentation](https://docs.n8n.io/hosting/security/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Caddy Security Guide](https://caddyserver.com/docs/automatic-https)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/security.html)
