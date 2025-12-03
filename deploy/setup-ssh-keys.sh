#!/bin/bash
set -e

echo "======================================"
echo "🔑 SSH Keys Setup für GitHub Actions"
echo "======================================"
echo ""

# Get current user
CURRENT_USER=$(whoami)
SSH_DIR="$HOME/.ssh"
KEY_FILE="$SSH_DIR/github_actions_deploy"

echo "📋 Dieser Skript wird:"
echo "  1. Ein SSH-Keypair generieren"
echo "  2. Den Public Key zu authorized_keys hinzufügen"
echo "  3. Dir alle Infos für GitHub Secrets anzeigen"
echo ""

# Create .ssh directory if it doesn't exist
if [ ! -d "$SSH_DIR" ]; then
    echo "📁 Erstelle .ssh Verzeichnis..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# Generate SSH key if it doesn't exist
if [ -f "$KEY_FILE" ]; then
    echo "⚠️  SSH Key existiert bereits: $KEY_FILE"
    read -p "Möchtest du einen neuen Key generieren? (y/N): " REGENERATE
    if [[ ! $REGENERATE =~ ^[Yy]$ ]]; then
        echo "Verwende existierenden Key..."
    else
        echo "🔄 Generiere neuen SSH Key..."
        rm -f "$KEY_FILE" "$KEY_FILE.pub"
        ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "github-actions-deploy"
    fi
else
    echo "🔑 Generiere SSH Key..."
    ssh-keygen -t ed25519 -f "$KEY_FILE" -N "" -C "github-actions-deploy"
fi

# Add public key to authorized_keys
echo "🔐 Füge Public Key zu authorized_keys hinzu..."
cat "${KEY_FILE}.pub" >> "$SSH_DIR/authorized_keys"
chmod 600 "$SSH_DIR/authorized_keys"

# Get server information
SERVER_IP=$(hostname -I | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(curl -s ifconfig.me)
fi

DEPLOY_PATH="/var/www/humidity-monitor"

echo ""
echo "======================================"
echo "✅ SSH Keys Setup Complete!"
echo "======================================"
echo ""
echo "📋 GitHub Secrets Configuration:"
echo "======================================"
echo ""
echo "🔗 Gehe zu: https://github.com/YOUR_USERNAME/humidity-monitor/settings/secrets/actions"
echo ""
echo "Füge folgende Secrets hinzu:"
echo ""
echo "1️⃣  SSH_PRIVATE_KEY"
echo "======================================"
cat "$KEY_FILE"
echo "======================================"
echo ""
echo "2️⃣  SERVER_HOST"
echo "======================================"
echo "$SERVER_IP"
echo "======================================"
echo ""
echo "3️⃣  SERVER_USER"
echo "======================================"
echo "$CURRENT_USER"
echo "======================================"
echo ""
echo "4️⃣  DEPLOY_PATH"
echo "======================================"
echo "$DEPLOY_PATH"
echo "======================================"
echo ""
echo "💾 Diese Informationen wurden auch gespeichert in:"
echo "   $HOME/github-secrets-info.txt"
echo ""

# Save to file
cat > "$HOME/github-secrets-info.txt" <<EOF
GitHub Secrets für humidity-monitor Deployment
==============================================

Repository: https://github.com/YOUR_USERNAME/humidity-monitor/settings/secrets/actions

1. SSH_PRIVATE_KEY:
$(cat "$KEY_FILE")

2. SERVER_HOST:
$SERVER_IP

3. SERVER_USER:
$CURRENT_USER

4. DEPLOY_PATH:
$DEPLOY_PATH
EOF

chmod 600 "$HOME/github-secrets-info.txt"

echo "📋 Nächste Schritte:"
echo "  1. Kopiere die Secrets zu GitHub"
echo "  2. Teste das Deployment mit 'Actions → Deploy to Server → Run workflow'"
echo "  3. Bei Erfolg: Ab jetzt automatisches Deployment bei jedem Push!"
echo ""
