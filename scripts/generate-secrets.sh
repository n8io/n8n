#!/bin/bash

# 🔐 n8n Security Setup Script
# Generates secure credentials for n8n deployment
# Cross-platform: Works on macOS and Ubuntu/Linux
# Idempotent: Safe to run multiple times

set -e

# Auto-detect script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMELAB_DIR="$(dirname "$SCRIPT_DIR")"

# File and Directory Paths
ENV_FILE="${HOMELAB_DIR}/.env"
ENV_EXAMPLE_FILE="${HOMELAB_DIR}/.env.example"
DOCKER_COMPOSE_FILE="${HOMELAB_DIR}/docker-compose.yml"
SCRIPTS_DIR="${HOMELAB_DIR}/scripts"
DOCS_DIR="${HOMELAB_DIR}/docs"

# Detect OS for platform-specific instructions
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    else
        OS="unknown"
    fi
}

# Check for required commands
check_dependencies() {
    local missing_deps=()
    
    # Check for openssl
    if ! command -v openssl &> /dev/null; then
        missing_deps+=("openssl")
    fi
    
    # Check for htpasswd (optional but recommended)
    if ! command -v htpasswd &> /dev/null; then
        echo "⚠️  htpasswd not found. This is optional but recommended for n8n basic auth."
        echo "   Install instructions:"
        if [ "$OS" = "macos" ]; then
            echo "   macOS: brew install httpd"
        elif [ "$OS" = "linux" ]; then
            echo "   Ubuntu/Debian: sudo apt-get install apache2-utils"
            echo "   CentOS/RHEL: sudo yum install httpd-tools"
        fi
        echo ""
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "❌ Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install instructions:"
        if [ "$OS" = "macos" ]; then
            echo "   macOS: brew install openssl"
        elif [ "$OS" = "linux" ]; then
            echo "   Ubuntu/Debian: sudo apt-get install openssl"
            echo "   CentOS/RHEL: sudo yum install openssl"
        fi
        exit 1
    fi
}

# Help function
show_help() {
    echo "🔐 n8n Security Setup Script"
    echo "============================"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --force    Force regeneration of credentials (overwrites existing)"
    echo "  --show     Show current credential status (without revealing values)"
    echo "  --help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0              # Check/create credentials (idempotent)"
    echo "  $0 --force      # Force regenerate all credentials"
    echo "  $0 --show       # Show current credential status"
    echo ""
    echo "This script is idempotent - safe to run multiple times."
    echo "It will only regenerate credentials if they're missing or invalid."
    echo ""
    echo "Platform Support:"
    echo "  ✅ macOS (with Homebrew)"
    echo "  ✅ Ubuntu/Debian Linux"
    echo "  ✅ CentOS/RHEL Linux"
    echo ""
    echo "Dependencies:"
    echo "  Required: openssl"
    echo "  Optional: htpasswd (for better n8n basic auth security)"
}

# Initialize OS detection
detect_os

# Handle help
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# Check dependencies (skip for --show to avoid breaking existing functionality)
if [ "$1" != "--show" ]; then
    check_dependencies
fi

# Handle show credentials
if [ "$1" = "--show" ]; then
    if [ -f "$ENV_FILE" ]; then
        echo "🔐 Current credentials in .env file:"
        echo "=================================="
        echo "🌐 Caddy TLS Configuration:"
        grep "CADDY_TLS=" "$ENV_FILE" | sed 's/=.*/=***HIDDEN***/'
        echo ""
        echo "📧 n8n Admin:"
        grep "N8N_BASIC_AUTH_USER=" "$ENV_FILE" | sed 's/=.*/=***HIDDEN***/'
        grep "N8N_BASIC_AUTH_PASSWORD=" "$ENV_FILE" | sed 's/=.*/=***HIDDEN***/'
        echo ""
        echo "🗄️  Database:"
        grep "POSTGRES_PASSWORD=" "$ENV_FILE" | sed 's/=.*/=***HIDDEN***/'
        echo ""
        echo "💡 To see actual values, check the .env file directly"
    else
        echo "❌ No .env file found at $ENV_FILE"
    fi
    exit 0
fi

# Handle force regeneration
if [ "$1" = "--force" ]; then
    echo "🔄 Force regeneration requested..."
    REGENERATE=true
fi

echo "🔒 n8n Security Setup"
echo "===================="
echo ""

# Check if .env already exists and has valid credentials
if [ -f "$ENV_FILE" ]; then
    echo "📋 .env file already exists at $ENV_FILE!"
    
    # Check if it has required variables
    if grep -q "POSTGRES_PASSWORD=" "$ENV_FILE"; then
        echo "✅ .env file contains required credentials"
        echo "🔍 Checking credential validity..."
        
        
        # Check if passwords are not placeholder values
        if grep -q "your_secure_password_here" "$ENV_FILE"; then
            echo "⚠️  Placeholder values detected, regenerating..."
            REGENERATE=true
        else
            if [ "$REGENERATE" = true ]; then
                echo "⚠️  Force regeneration requested, proceeding..."
            else
                echo "✅ Credentials appear to be properly set"
                echo ""
                echo "🎉 .env file is ready to use!"
                echo "💡 To regenerate credentials, run: $0 --force"
                echo "💡 To view current credentials: $0 --show"
                exit 0
            fi
        fi
    else
        echo "⚠️  .env file is missing required credentials, regenerating..."
        REGENERATE=true
    fi
else
    echo "📝 Creating new .env file at $ENV_FILE..."
    REGENERATE=true
fi

# Password generation function with custom character set
generate_secure_password() {
    local length=$1
    local chars="ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789!@#%^&*_+-=[]|;:,<>?~"
    local password=""
    
    # Generate random password using the custom character set
    for ((i=0; i<length; i++)); do
        local rand_index=$((RANDOM % ${#chars}))
        password="${password}${chars:$rand_index:1}"
    done
    
    echo "$password"
}


# Generate database password
echo "🗄️  Generating database password..."
DB_PASSWORD=$(generate_secure_password 25)
echo "✅ Database password generated"

# Generate n8n admin password
echo "👤 Generating n8n admin password..."
N8N_PASSWORD=$(generate_secure_password 20)
echo "✅ n8n admin password generated"

# Ask for domain and determine TLS configuration
echo "🌐 Domain Configuration"
echo "======================"
echo ""
echo "Please enter your domain name:"
echo "  - For localhost development: n8n.localhost (default - just hit Enter)"
echo "  - For production: your-domain.com"
echo "  - For IP access: your-server-ip"
echo ""
read -p "Domain [n8n.localhost]: " DOMAIN

# Use default domain if empty
if [ -z "$DOMAIN" ]; then
    DOMAIN="n8n.localhost"
    echo "✅ Using default domain: $DOMAIN"
else
    echo "✅ Using custom domain: $DOMAIN"
fi

# Determine TLS configuration based on domain
if [[ "$DOMAIN" == *"localhost"* ]] || [[ "$DOMAIN" == *"127.0.0.1"* ]] || [[ "$DOMAIN" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    CADDY_TLS="internal"
    echo "✅ Detected localhost/IP domain - using internal TLS"
else
    CADDY_TLS=""
    echo "✅ Detected real domain - using Let's Encrypt TLS"
fi

echo ""

# Generate n8n basic auth hash
if command -v htpasswd &> /dev/null; then
    N8N_AUTH=$(htpasswd -nb admin "$N8N_PASSWORD")
    echo "✅ n8n basic auth hash generated"
else
    echo "⚠️  htpasswd not found. Using plain password for n8n basic auth..."
    N8N_AUTH="admin:$N8N_PASSWORD"
    echo "✅ Using plain password (consider installing htpasswd for better security)"
    echo ""
    echo "💡 For better security, install htpasswd:"
    if [ "$OS" = "macos" ]; then
        echo "   brew install httpd"
    elif [ "$OS" = "linux" ]; then
        echo "   sudo apt-get install apache2-utils  # Ubuntu/Debian"
        echo "   sudo yum install httpd-tools        # CentOS/RHEL"
    fi
fi

# Backup existing .env if regenerating
if [ "$REGENERATE" = true ] && [ -f "$ENV_FILE" ]; then
    BACKUP_FILE="${HOMELAB_DIR}/.env.backup.$(date +%Y%m%d_%H%M%S)"
    echo "💾 Backing up existing .env to $BACKUP_FILE"
    cp "$ENV_FILE" "$BACKUP_FILE"
    echo "✅ Backup created: $BACKUP_FILE"
fi

# Create .env file
echo "📝 Creating .env file at $ENV_FILE..."
cat > "$ENV_FILE" << EOF
# Caddy TLS Configuration
# Options: 'internal' for localhost, '' (empty) for real domain with Let's Encrypt
CADDY_TLS=$CADDY_TLS

# Database Configuration
POSTGRES_DATABASE=n8n
POSTGRES_USER=n8n_user
POSTGRES_PASSWORD='$DB_PASSWORD'
POSTGRES_PORT=5432
POSTGRES_SCHEMA=public

# Domain Configuration
DOMAIN=$DOMAIN

# n8n Configuration
N8N_TIMEZONE=UTC

# Authentication
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD='$N8N_PASSWORD'

# Additional Security Settings
N8N_SECURE_COOKIE=true
N8N_SKIP_WEBHOOK_DEREGISTRATION_SHUTDOWN=true
EOF

echo "✅ .env file created successfully!"
echo ""

# Display credentials (user should save these)
echo "🔐 IMPORTANT: Save these credentials securely!"
echo "=============================================="
echo ""
echo "📧 n8n Admin Login:"
echo "   Username: admin"
echo "   Password: $N8N_PASSWORD"
echo ""
echo "🌐 Domain & TLS Configuration:"
echo "   Domain: $DOMAIN"
if [ "$CADDY_TLS" = "internal" ]; then
    echo "   TLS Mode: internal (for localhost/IP development)"
    echo "   Access URL: https://$DOMAIN"
else
    echo "   TLS Mode: Let's Encrypt (for production domains)"
    echo "   Access URL: https://$DOMAIN"
fi
echo ""
echo "🗄️  Database Password: $DB_PASSWORD"
echo ""

# Security reminders
echo "🚨 SECURITY REMINDERS:"
echo "======================"
if [ "$CADDY_TLS" = "internal" ]; then
    echo "1. For production, update DOMAIN in .env file to your real domain"
    echo "2. Set up firewall (ports 22, 80, 443 only)"
    echo "3. Enable automatic updates"
    echo "4. Set up regular backups"
    echo "5. Monitor logs for suspicious activity"
else
    echo "1. Ensure your domain DNS points to this server"
    echo "2. Set up firewall (ports 22, 80, 443 only)"
    echo "3. Enable automatic updates"
    echo "4. Set up regular backups"
    echo "5. Monitor logs for suspicious activity"
fi
echo ""

# Set proper permissions
chmod 600 "$ENV_FILE"
echo "✅ Set secure permissions on .env file (600)"

# Validate generated credentials
echo ""
echo "🔍 Validating generated credentials..."

if [ ${#DB_PASSWORD} -ge 16 ]; then
    echo "✅ Database password length is sufficient"
else
    echo "❌ Database password is too short"
    exit 1
fi

if [ ${#N8N_PASSWORD} -ge 12 ]; then
    echo "✅ n8n password length is sufficient"
else
    echo "❌ n8n password is too short"
    exit 1
fi

echo ""
echo "🎉 Security setup complete!"
echo "Next steps:"
echo "1. Run: docker compose up -d"
echo "2. Access n8n at: https://$DOMAIN"
if [ "$CADDY_TLS" = "internal" ]; then
    echo "   (or http://localhost:5678 for direct access)"
fi
echo ""
echo "💡 This script is idempotent - safe to run again if needed"
echo ""
echo "🖥️  Platform: $OS"
if [ "$OS" = "macos" ]; then
    echo "💡 macOS detected - Docker Desktop should be running"
elif [ "$OS" = "linux" ]; then
    echo "💡 Linux detected - ensure Docker daemon is running"
    echo "   sudo systemctl start docker  # if needed"
fi
