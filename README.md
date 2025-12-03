# Humidity Monitor

Ein Echtzeit-Monitoring-System für Luftfeuchtigkeit und Temperatur mit VPD-Berechnungen (Vapor Pressure Deficit) für zwei separate Grow-Zelte.

## Features

- **Echtzeit-Monitoring**: Live-Daten von zwei Sensoren (Blütezelt & Aufzuchtszelt)
- **VPD-Berechnungen**: Automatische Berechnung des Vapor Pressure Deficit
- **Historische Daten**: Vollständiger Verlauf aller Messungen
- **Grow-Journal**: Dokumentation des Wachstumsverlaufs
- **Dashboard**: Übersicht über alle wichtigen Metriken
- **WebSocket-Support**: Echtzeit-Updates ohne Seitenaktualisierung
- **Responsive Design**: Optimiert für Desktop und Mobile

## Tech Stack

### Backend
- **Node.js** + **Express.js**
- **Socket.io**: WebSocket-Kommunikation für Echtzeit-Updates
- **JSON-Dateien**: Persistente Datenspeicherung

### Frontend
- **Vanilla JavaScript**: Keine Framework-Dependencies
- **HTML5** + **CSS3**: Modernes, responsives Design
- **Socket.io Client**: Echtzeit-Datenempfang

## Installation & Setup

### Voraussetzungen
- Node.js 18+ oder 20+
- npm

### Lokale Entwicklung

1. Repository klonen:
```bash
git clone https://github.com/steffen5567/humidity-monitor.git
cd humidity-monitor
```

2. Dependencies installieren:
```bash
cd data
npm install
```

3. Server starten:
```bash
node server.js
```

Die App läuft nun auf: `http://localhost:3006`

## 🚀 Production Deployment

Die App kann mit automatischem GitHub Actions Deployment auf einem Server deployed werden.

### Schnellstart (10 Minuten)

Siehe: **[deploy/QUICKSTART.md](deploy/QUICKSTART.md)**

### Vollständige Dokumentation

Siehe: **[deploy/DEPLOYMENT.md](deploy/DEPLOYMENT.md)**

### Features
- ✅ Automatisches Deployment bei jedem Push
- ✅ Nginx als Reverse Proxy
- ✅ Systemd Service für Node.js-App
- ✅ WebSocket-Support
- ✅ SSL/HTTPS Support (optional)
- ✅ Domain-Support (optional)

## Verwendung

### Dashboard
- **Hauptseite** (`/`): Navigation zu allen Monitoring-Bereichen
- **Dashboard** (`/dashboard`): Übersicht aller Metriken

### Messungen
- `/measurements-bluetezelt.html`: Temperatur & Luftfeuchtigkeit für Blütezelt
- `/measurements-aufzuchtszelt.html`: Temperatur & Luftfeuchtigkeit für Aufzuchtszelt

### VPD-Monitoring
- `/vpd-bluetezelt.html`: VPD-Berechnungen für Blütezelt
- `/vpd-aufzuchtszelt.html`: VPD-Berechnungen für Aufzuchtszelt
- `/vpd-manuell.html`: Manuelle VPD-Berechnung

### Grow-Journal
- `/grow-journal.html`: Dokumentation des Wachstumsverlaufs

## API Endpoints

### Sensordaten empfangen
- `POST /api/measurements` - Daten von Sensor 1 (Blütezelt)
- `POST /api/measurements/sensor2` - Daten von Sensor 2 (Aufzuchtszelt)

**Payload-Beispiel:**
```json
{
  "temperature": 25.5,
  "humidity": 65.2
}
```

### Daten abrufen
- `GET /api/measurements/bluetezelt` - Alle Messungen für Blütezelt
- `GET /api/measurements/aufzuchtszelt` - Alle Messungen für Aufzuchtszelt

### WebSocket Events
- **Senden:**
  - `humidityData`: Daten von Sensor 1
  - `humidityDataSensor2`: Daten von Sensor 2

- **Empfangen:**
  - `updateHumidity`: Updates von Sensor 1
  - `updateHumiditySensor2`: Updates von Sensor 2

## Datenstruktur

Messungen werden in JSON-Dateien gespeichert:
- `data/data/bluetezelt.json`: Blütezelt-Sensordaten
- `data/data/aufzuchtszelt.json`: Aufzuchtszelt-Sensordaten

**Format:**
```json
[
  {
    "timestamp": "2025-12-03T10:30:00.000Z",
    "temperature": 25.5,
    "humidity": 65.2
  }
]
```

## Konfiguration

### Port ändern
In `data/server.js`:
```javascript
const PORT = 3006; // Ändern Sie diesen Wert
```

### Speicher-Intervall anpassen
```javascript
// Alle 5 Minuten speichern (Standard)
setInterval(saveSensorData, 5 * 60 * 1000);
```

## Troubleshooting

### Port bereits belegt
```bash
# Prozess finden
sudo netstat -tulpn | grep :3006

# Prozess beenden
sudo kill <PID>
```

### Service läuft nicht (Production)
```bash
sudo systemctl status humidity-monitor
sudo journalctl -u humidity-monitor -f
```

### WebSocket-Verbindung schlägt fehl
- Prüfen Sie die Nginx-Konfiguration für WebSocket-Support
- Stellen Sie sicher, dass Port 3006 erreichbar ist

Mehr Details: [deploy/DEPLOYMENT.md](deploy/DEPLOYMENT.md)

## Zukünftige Erweiterungen

- **Benachrichtigungen**: Alerts bei kritischen Werten
- **Datenbank-Integration**: PostgreSQL/MongoDB für bessere Skalierung
- **Grafana-Integration**: Erweiterte Visualisierungen
- **Mobile App**: Native iOS/Android-App
- **Mehrere Sensoren**: Support für mehr als 2 Sensoren
- **Export-Funktion**: CSV/Excel-Export der Messdaten

## Lizenz

MIT

---

Dieses Projekt wurde mit Claude Code erstellt.
