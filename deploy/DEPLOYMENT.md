# 🌡️ Humidity Monitor - Deployment Guide

Vollständige Dokumentation für das Deployment der Humidity Monitor App auf einem Linux-Server mit automatischer CI/CD-Pipeline über GitHub Actions.

## 📋 Inhaltsverzeichnis

- [Architektur](#architektur)
- [Voraussetzungen](#voraussetzungen)
- [Server-Setup](#server-setup)
- [GitHub Actions Setup](#github-actions-setup)
- [Manuelle Deployment-Schritte](#manuelle-deployment-schritte)
- [Troubleshooting](#troubleshooting)

---

## Architektur

### Deployment-Stack

```
┌─────────────────────────────────────┐
│         GitHub Actions              │
│  (Automated Deployment Pipeline)    │
└─────────────┬───────────────────────┘
              │ SSH Deploy
              ↓
┌─────────────────────────────────────┐
│         Linux Server                │
├─────────────────────────────────────┤
│  Nginx (Port 9100)                  │
│    ↓ Reverse Proxy                  │
│  Node.js App (Port 9100)            │
│    ↓ Express + Socket.io            │
│  JSON Files (Data Storage)          │
└─────────────────────────────────────┘
```

### Komponenten

**Node.js Service:**
- Express.js Server auf Port 9100
- Socket.io für Echtzeit-Updates
- Läuft als systemd-Service
- Automatischer Neustart bei Fehler

**Nginx:**
- Reverse Proxy für Node.js App
- WebSocket-Support für Socket.io
- Optional: SSL/HTTPS-Terminierung

**Datenspeicherung:**
- JSON-Dateien für Sensordaten
- Persistenter Speicher in `data/data/`

---

## Voraussetzungen

### Server-Anforderungen

- **OS:** Ubuntu 20.04+ (oder ähnliche Debian-basierte Distribution)
- **RAM:** Mindestens 512 MB
- **Disk:** Mindestens 2 GB freier Speicherplatz
- **Netzwerk:** Öffentliche IP-Adresse, Port 9100 erreichbar
- **Zugriff:** SSH-Zugang mit sudo-Rechten

### Lokale Anforderungen

- Git installiert
- GitHub Account
- SSH-Client (für Server-Verbindung)

---

## Server-Setup

### Option 1: Automatisches Setup (Empfohlen)

Verwenden Sie das bereitgestellte Setup-Skript:

```bash
# Auf dem Server
curl -sSL https://raw.githubusercontent.com/IHR_GITHUB_USERNAME/humidity-monitor/master/deploy/server-setup.sh | sudo bash
```

Das Skript installiert und konfiguriert automatisch:
- Node.js & npm
- Git
- Nginx
- Systemd-Service für die App
- Repository-Clone
- Alle Dependencies

### Option 2: Manuelles Setup

Falls Sie mehr Kontrolle wünschen:

#### 1. System-Dependencies installieren

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y git curl nginx
```

#### 2. Node.js installieren

```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo bash -
sudo apt install -y nodejs
```

Überprüfen:
```bash
node -v  # Should be v18+ or v20+
npm -v
```

#### 3. Repository clonen

```bash
sudo mkdir -p /var/www/humidity-monitor
sudo chown $USER:$USER /var/www/humidity-monitor
cd /var/www/humidity-monitor
git clone https://github.com/IHR_GITHUB_USERNAME/humidity-monitor.git .
```

#### 4. Dependencies installieren

```bash
cd /var/www/humidity-monitor/data
npm install
```

#### 5. Systemd Service erstellen

```bash
sudo nano /etc/systemd/system/humidity-monitor.service
```

Inhalt:
```ini
[Unit]
Description=Humidity Monitor Node.js Service
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/var/www/humidity-monitor/data
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
```

Service aktivieren:
```bash
sudo systemctl daemon-reload
sudo systemctl enable humidity-monitor
sudo systemctl start humidity-monitor
```

#### 6. Nginx konfigurieren

```bash
sudo nano /etc/nginx/sites-available/humidity-monitor
```

Inhalt:
```nginx
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

    location /socket.io/ {
        proxy_pass http://localhost:9100;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Site aktivieren:
```bash
sudo ln -s /etc/nginx/sites-available/humidity-monitor /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

---

## GitHub Actions Setup

### 1. SSH-Keys generieren

Auf dem Server:
```bash
curl -sSL https://raw.githubusercontent.com/IHR_GITHUB_USERNAME/humidity-monitor/master/deploy/setup-ssh-keys.sh | bash
```

Oder manuell:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/github_actions_deploy -N ""
cat ~/.ssh/github_actions_deploy.pub >> ~/.ssh/authorized_keys
cat ~/.ssh/github_actions_deploy  # Private Key für GitHub Secret
```

### 2. GitHub Secrets konfigurieren

Gehen Sie zu: `https://github.com/IHR_USERNAME/humidity-monitor/settings/secrets/actions`

Fügen Sie diese 4 Secrets hinzu:

| Secret Name | Wert | Beispiel |
|------------|------|----------|
| `SSH_PRIVATE_KEY` | Privater SSH-Key | (Kompletter Key inkl. Header/Footer) |
| `SERVER_HOST` | Server-IP oder Hostname | `123.45.67.89` |
| `SERVER_USER` | SSH-Benutzername | `ubuntu` |
| `DEPLOY_PATH` | App-Pfad auf Server | `/var/www/humidity-monitor` |

### 3. Deployment testen

**Manueller Workflow-Trigger:**
1. Gehen Sie zu: Actions → Deploy to Server
2. Klicken Sie auf "Run workflow"
3. Überwachen Sie den Deployment-Prozess

**Automatisches Deployment:**
- Bei jedem `git push` zu `master` wird automatisch deployed

---

## Manuelle Deployment-Schritte

Falls Sie ohne GitHub Actions deployen möchten:

```bash
# Auf dem Server
cd /var/www/humidity-monitor

# Code aktualisieren
git pull origin master

# Dependencies aktualisieren
cd data
npm install

# Service neu starten
sudo systemctl restart humidity-monitor

# Status prüfen
sudo systemctl status humidity-monitor
```

---

## Troubleshooting

### Service läuft nicht

**Problem:** `systemctl status humidity-monitor` zeigt "failed"

**Lösung:**
```bash
# Logs ansehen
sudo journalctl -u humidity-monitor -n 50 --no-pager

# Häufige Ursachen:
# 1. Port bereits belegt
sudo netstat -tulpn | grep :9100

# 2. Dependencies fehlen
cd /var/www/humidity-monitor/data
npm install

# 3. Dateiberechtigungen
sudo chown -R $USER:$USER /var/www/humidity-monitor

# Service neu starten
sudo systemctl restart humidity-monitor
```

### 502 Bad Gateway (Nginx)

**Problem:** Nginx kann nicht mit Node.js-App kommunizieren

**Lösung:**
```bash
# 1. Prüfe ob Service läuft
sudo systemctl status humidity-monitor

# 2. Prüfe Nginx-Konfiguration
sudo nginx -t

# 3. Prüfe Nginx-Logs
sudo tail -f /var/log/nginx/error.log

# 4. Prüfe ob Port richtig ist
curl http://localhost:9100
```

### WebSocket-Verbindung schlägt fehl

**Problem:** Socket.io kann keine Verbindung herstellen

**Lösung:**
```bash
# Prüfe Nginx-Konfiguration für WebSocket-Support
sudo nano /etc/nginx/sites-available/humidity-monitor

# Stelle sicher, dass diese Zeilen vorhanden sind:
# proxy_http_version 1.1;
# proxy_set_header Upgrade $http_upgrade;
# proxy_set_header Connection 'upgrade';

sudo systemctl reload nginx
```

### GitHub Actions Deployment schlägt fehl

**Problem:** Workflow-Fehler in GitHub Actions

**Lösungen:**

1. **SSH-Verbindung fehlgeschlagen:**
   ```bash
   # Prüfe SSH-Key auf Server
   cat ~/.ssh/authorized_keys | grep github

   # Teste SSH-Verbindung
   ssh -i ~/.ssh/github_actions_deploy $USER@$SERVER_IP
   ```

2. **Permission denied:**
   ```bash
   # Stelle sicher, dass User Berechtigung hat
   sudo chown -R $USER:$USER /var/www/humidity-monitor

   # User muss systemctl ohne sudo ausführen können
   sudo visudo
   # Füge hinzu: YOUR_USER ALL=(ALL) NOPASSWD: /bin/systemctl restart humidity-monitor
   ```

3. **Git pull schlägt fehl:**
   ```bash
   # Repository-Status prüfen
   cd /var/www/humidity-monitor
   git status

   # Bei Konflikten
   git stash
   git pull origin master
   ```

### Datenverlust nach Deployment

**Problem:** JSON-Dateien werden überschrieben

**Lösung:**
Die JSON-Dateien befinden sich in `data/data/` und sollten nicht von Git verwaltet werden.

```bash
# Prüfe .gitignore
cat .gitignore | grep "data/data/"

# Falls nicht vorhanden, hinzufügen:
echo "data/data/*.json" >> .gitignore
git add .gitignore
git commit -m "Ignore sensor data files"
git push
```

---

## Sicherheit

### Firewall konfigurieren

```bash
sudo ufw allow 9100/tcp
sudo ufw enable
sudo ufw status
```

### HTTPS mit Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d ihre-domain.de
```

### Regelmäßige Updates

```bash
# System-Updates
sudo apt update && sudo apt upgrade -y

# Node.js-Dependencies
cd /var/www/humidity-monitor/data
npm update
```

---

## Performance-Optimierung

### PM2 als Process Manager (Alternative zu systemd)

```bash
npm install -g pm2
cd /var/www/humidity-monitor/data
pm2 start server.js --name humidity-monitor
pm2 startup
pm2 save
```

### Nginx-Caching

Für statische Assets in `nginx.conf`:
```nginx
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

---

## Support

Bei Problemen:
1. Prüfen Sie die Logs: `sudo journalctl -u humidity-monitor -f`
2. Prüfen Sie den Service-Status: `sudo systemctl status humidity-monitor`
3. Erstellen Sie ein Issue auf GitHub

---

**Deployment erstellt mit Claude Code**
