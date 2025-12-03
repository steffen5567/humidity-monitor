# 🚀 Deployment Documentation

Willkommen zur Deployment-Dokumentation für Humidity Monitor!

## 📁 Dateien in diesem Verzeichnis

- **[QUICKSTART.md](QUICKSTART.md)** - 10-Minuten Quick-Start Guide
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Vollständige Deployment-Dokumentation
- **server-setup.sh** - Automatisches Server-Setup-Skript
- **setup-ssh-keys.sh** - SSH-Keys für GitHub Actions generieren

## 🎯 Welche Datei sollte ich verwenden?

### Neu bei Deployment? → QUICKSTART.md
Wenn Sie schnell starten und die App innerhalb von 10 Minuten deployen möchten.

**Vorteile:**
- Schritt-für-Schritt-Anleitung
- Automatische Skripte
- Schneller Setup-Prozess

**Sie brauchen:**
- Linux-Server mit SSH-Zugang
- GitHub Account
- 10 Minuten Zeit

### Mehr Kontrolle gewünscht? → DEPLOYMENT.md
Wenn Sie jeden Schritt verstehen und anpassen möchten.

**Enthält:**
- Detaillierte Architektur-Erklärungen
- Manuelle Setup-Schritte
- Erweiterte Konfigurationsoptionen
- Troubleshooting-Guide
- Performance-Optimierungen
- Sicherheits-Best-Practices

## 🛠️ Setup-Skripte

### server-setup.sh
Automatisches Setup des kompletten Servers.

**Was wird installiert:**
- Node.js & npm
- Git
- Nginx (Reverse Proxy)
- Systemd Service
- Repository-Clone
- Dependencies

**Verwendung:**
```bash
curl -sSL https://raw.githubusercontent.com/IHR_USERNAME/humidity-monitor/master/deploy/server-setup.sh | sudo bash
```

### setup-ssh-keys.sh
Generiert SSH-Keys für GitHub Actions Deployment.

**Was wird erstellt:**
- SSH-Keypair
- Authorized Keys Eintrag
- GitHub Secrets Info

**Verwendung:**
```bash
curl -sSL https://raw.githubusercontent.com/IHR_USERNAME/humidity-monitor/master/deploy/setup-ssh-keys.sh | bash
```

## 🔄 Deployment-Ablauf

```
┌─────────────────────────────────────────┐
│  1. Server Setup (server-setup.sh)     │
│     - Installiert alle Dependencies    │
│     - Konfiguriert Services            │
│     - Klont Repository                 │
└─────────────┬───────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  2. SSH Keys Setup                      │
│     (setup-ssh-keys.sh)                 │
│     - Generiert Keys                    │
│     - Zeigt GitHub Secrets an          │
└─────────────┬───────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  3. GitHub Secrets konfigurieren        │
│     - SSH_PRIVATE_KEY                   │
│     - SERVER_HOST                       │
│     - SERVER_USER                       │
│     - DEPLOY_PATH                       │
└─────────────┬───────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  4. Deployment testen                   │
│     - Manuell via Actions UI            │
│     - Oder via git push                 │
└─────────────┬───────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  ✅ Fertig!                             │
│     App läuft auf:                      │
│     http://SERVER_IP:3006               │
└─────────────────────────────────────────┘
```

## 🏗️ Architektur-Übersicht

### Production Environment
```
Internet
    ↓
Nginx (Port 3006)
    ↓ Reverse Proxy + WebSocket Support
Node.js App (Port 3006)
    ↓ Express + Socket.io
JSON Files (Data Storage)
```

### GitHub Actions Workflow
```
git push → master
    ↓
GitHub Actions
    ↓ SSH Deploy
Linux Server
    ↓
1. Git Pull
2. npm install
3. Restart Service
```

## 📋 Voraussetzungen

### Server
- Ubuntu 20.04+ (oder ähnlich)
- Mindestens 512 MB RAM
- Mindestens 2 GB Disk Space
- Öffentliche IP-Adresse
- SSH-Zugang mit sudo

### Lokal
- Git
- GitHub Account
- SSH-Client

## 🆘 Schnelle Hilfe

### App läuft nicht?
```bash
sudo systemctl status humidity-monitor
sudo journalctl -u humidity-monitor -f
```

### Nginx-Probleme?
```bash
sudo nginx -t
sudo systemctl status nginx
sudo tail -f /var/log/nginx/error.log
```

### Deployment schlägt fehl?
1. Prüfen Sie GitHub Secrets
2. Testen Sie SSH-Verbindung manuell
3. Prüfen Sie Server-Logs

Mehr Details: [DEPLOYMENT.md](DEPLOYMENT.md)

## 🔗 Nützliche Links

- **GitHub Repository:** https://github.com/steffen5567/humidity-monitor
- **GitHub Actions:** https://github.com/steffen5567/humidity-monitor/actions
- **GitHub Secrets:** https://github.com/steffen5567/humidity-monitor/settings/secrets/actions

## 📚 Weitere Ressourcen

- [Node.js Deployment Best Practices](https://nodejs.org/en/docs/guides/nodejs-docker-webapp/)
- [Nginx Configuration Guide](https://nginx.org/en/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Socket.io Production Guide](https://socket.io/docs/v4/performance-tuning/)

---

**Viel Erfolg beim Deployment! 🚀**
