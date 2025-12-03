#!/bin/bash
set -e

echo "======================================"
echo "🌡️  Humidity Monitor - Server Setup"
echo "======================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  This script needs to be run with sudo"
    exit 1
fi

# Get non-root user who invoked sudo
ACTUAL_USER=${SUDO_USER:-$(whoami)}
ACTUAL_HOME=$(eval echo ~$ACTUAL_USER)

echo "📋 Installation Steps:"
echo "  1. Install system dependencies"
echo "  2. Install Node.js & npm"
echo "  3. Clone repository"
echo "  4. Setup systemd service"
echo "  5. Configure nginx"
echo ""

# Get repository URL from parameter, environment variable, or use default
DEFAULT_REPO_URL="https://github.com/steffen5567/humidity-monitor.git"

if [ -n "$1" ]; then
    REPO_URL="$1"
    echo "📦 Using repository from parameter: $REPO_URL"
elif [ -n "$REPO_URL" ]; then
    echo "📦 Using repository from environment: $REPO_URL"
else
    REPO_URL="$DEFAULT_REPO_URL"
    echo "📦 Using default repository: $REPO_URL"
fi

echo "   If you want to use a different repository, run:"
echo "   sudo bash server-setup.sh YOUR_REPO_URL"

echo ""
echo "🚀 Starting installation..."
echo ""

# Update system
echo "📦 Updating system packages..."
apt update
apt upgrade -y

# Install required packages
echo "📦 Installing system dependencies..."
apt install -y git curl nginx

# Install Node.js (LTS version via NodeSource)
echo "📦 Installing Node.js..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    apt install -y nodejs
else
    echo "✅ Node.js already installed"
fi

echo "✅ Node.js version: $(node -v)"
echo "✅ npm version: $(npm -v)"

# Create deployment directory
DEPLOY_PATH="/var/www/humidity-monitor"
echo "📁 Creating deployment directory: $DEPLOY_PATH"
mkdir -p $DEPLOY_PATH
cd $DEPLOY_PATH

# Clone repository
echo "📥 Cloning repository..."
if [ ! -d ".git" ]; then
    git clone $REPO_URL .
else
    echo "✅ Repository already cloned"
    git pull origin master
fi

# Set correct ownership
chown -R $ACTUAL_USER:$ACTUAL_USER $DEPLOY_PATH

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
cd $DEPLOY_PATH/data
sudo -u $ACTUAL_USER npm install

# Create systemd service
echo "⚙️  Creating systemd service..."
cat > /etc/systemd/system/humidity-monitor.service <<EOF
[Unit]
Description=Humidity Monitor Node.js Service
After=network.target

[Service]
Type=simple
User=$ACTUAL_USER
WorkingDirectory=$DEPLOY_PATH/data
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=humidity-monitor

Environment=NODE_ENV=production
Environment=PORT=9100

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
echo "🔧 Enabling and starting humidity-monitor service..."
systemctl daemon-reload
systemctl enable humidity-monitor
systemctl start humidity-monitor

# Check service status
sleep 2
systemctl status humidity-monitor --no-pager || echo "⚠️  Service might need manual configuration"

# Configure nginx
echo "🌐 Configuring nginx..."
cat > /etc/nginx/sites-available/humidity-monitor <<'EOF'
server {
    listen 9100;
    server_name _;

    location / {
        proxy_pass http://localhost:9100;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket support for Socket.io
    location /socket.io/ {
        proxy_pass http://localhost:9100;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF

# Enable nginx site
ln -sf /etc/nginx/sites-available/humidity-monitor /etc/nginx/sites-enabled/
# Don't remove default site, as other projects might use it

# Test and restart nginx
nginx -t
systemctl restart nginx

# Configure firewall (if ufw is installed)
if command -v ufw &> /dev/null; then
    echo "🔒 Configuring firewall..."
    ufw allow 9100/tcp
    ufw allow 'Nginx Full'
fi

echo ""
echo "======================================"
echo "✅ Installation Complete!"
echo "======================================"
echo ""
echo "📋 Service Status:"
systemctl status humidity-monitor --no-pager | head -n 10
echo ""
echo "🌐 Your app should now be accessible at:"
echo "   http://YOUR_SERVER_IP:9100"
echo ""
echo "📊 Useful commands:"
echo "   View logs:        sudo journalctl -u humidity-monitor -f"
echo "   Restart service:  sudo systemctl restart humidity-monitor"
echo "   Check status:     sudo systemctl status humidity-monitor"
echo "   Restart nginx:    sudo systemctl restart nginx"
echo ""
echo "📋 Next steps:"
echo "   1. Run: deploy/setup-ssh-keys.sh"
echo "   2. Configure GitHub Secrets (see deploy/QUICKSTART.md)"
echo "   3. Test deployment workflow"
echo ""
