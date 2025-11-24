#!/bin/bash

# Semantico Backend - Orange Pi Setup Script
# This script installs and configures everything needed on Armbian

set -e

echo "🚀 Semantico Backend - Orange Pi Setup"
echo "======================================"

# Update system
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose
echo "🐳 Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo apt-get install -y docker-compose
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

# Install Nginx
echo "🌐 Installing Nginx..."
sudo apt-get install -y nginx
echo "✅ Nginx installed"

# Install Certbot for Let's Encrypt
echo "🔒 Installing Certbot..."
sudo apt-get install -y certbot python3-certbot-nginx
echo "✅ Certbot installed"

# Install useful tools
echo "🛠️ Installing useful tools..."
sudo apt-get install -y curl wget git htop nano
echo "✅ Tools installed"

# Create app directory
echo "📁 Creating app directory..."
sudo mkdir -p /opt/semantico
sudo chown $USER:$USER /opt/semantico
echo "✅ App directory created at /opt/semantico"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Transfer your backend files to /opt/semantico"
echo "2. Run: cd /opt/semantico && docker-compose up -d"
echo "3. Configure DuckDNS for dynamic DNS"
echo "4. Setup Nginx reverse proxy with SSL"
echo ""
