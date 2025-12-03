const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const fs = require('fs');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server);

// Damit Express JSON-Body-Payloads auswerten kann:
app.use(express.json());
app.use(express.static(path.join(__dirname)));

let measurementsSensor1 = [];
let measurementsSensor2 = [];

// Definiere Pfade für die JSON-Dateien
const dataDir = path.join(__dirname, 'data');
const bluetezeltDataFile = path.join(dataDir, 'bluetezelt.json');
const aufzuchtszeltDataFile = path.join(dataDir, 'aufzuchtszelt.json');

// Stelle sicher, dass das Datenverzeichnis existiert
if (!fs.existsSync(dataDir)) {
    fs.mkdirSync(dataDir, { recursive: true });
}

// Funktion zum Laden der Daten aus den JSON-Dateien
function loadSensorData() {
    console.log('Lade Sensordaten aus JSON-Dateien...');
    
    try {
        // Blütezelt-Daten laden
        if (fs.existsSync(bluetezeltDataFile)) {
            const data = fs.readFileSync(bluetezeltDataFile, 'utf8');
            measurementsSensor1 = JSON.parse(data);
            console.log(`${measurementsSensor1.length} Datenpunkte für Blütezelt geladen.`);
        } else {
            console.log('Keine Daten für Blütezelt gefunden, verwende leeres Array.');
            measurementsSensor1 = [];
        }
        
        // Aufzuchtszelt-Daten laden
        if (fs.existsSync(aufzuchtszeltDataFile)) {
            const data = fs.readFileSync(aufzuchtszeltDataFile, 'utf8');
            measurementsSensor2 = JSON.parse(data);
            console.log(`${measurementsSensor2.length} Datenpunkte für Aufzuchtszelt geladen.`);
        } else {
            console.log('Keine Daten für Aufzuchtszelt gefunden, verwende leeres Array.');
            measurementsSensor2 = [];
        }
        
        // Füge Beispieldaten hinzu, wenn keine vorhanden sind
        if (measurementsSensor1.length === 0 || measurementsSensor2.length === 0) {
            addSampleData();
            // Speichere die generierten Beispieldaten sofort
            saveSensorData();
        }
    } catch (error) {
        console.error('Fehler beim Laden der Sensordaten:', error);
        // Bei Fehler, leere Arrays verwenden und Beispieldaten generieren
        measurementsSensor1 = [];
        measurementsSensor2 = [];
        addSampleData();
    }
}

// Funktion zum Speichern der Daten in JSON-Dateien
function saveSensorData() {
    console.log('Speichere Sensordaten in JSON-Dateien...');
    
    try {
        // Blütezelt-Daten speichern
        fs.writeFileSync(bluetezeltDataFile, JSON.stringify(measurementsSensor1, null, 2), 'utf8');
        console.log(`${measurementsSensor1.length} Datenpunkte für Blütezelt gespeichert.`);
        
        // Aufzuchtszelt-Daten speichern
        fs.writeFileSync(aufzuchtszeltDataFile, JSON.stringify(measurementsSensor2, null, 2), 'utf8');
        console.log(`${measurementsSensor2.length} Datenpunkte für Aufzuchtszelt gespeichert.`);
    } catch (error) {
        console.error('Fehler beim Speichern der Sensordaten:', error);
    }
}

// Aktualisiere die POST-Route für den ersten Feuchtigkeitssensor
app.post('/api/measurements', (req, res) => {
  const data = req.body;
  console.log('POST /api/measurements received:', data);
  data.timestamp = new Date().toISOString();
  measurementsSensor1.push(data);
  io.emit('updateHumidity', data);
  
  // Speichere die Daten nach jeder Änderung
  saveSensorData();
  
  res.status(200).json({ success: true });
});

// Aktualisiere die POST-Route für den zweiten Feuchtigkeitssensor
app.post('/api/measurements/sensor2', (req, res) => {
  const data = req.body;
  console.log('POST /api/measurements/sensor2 received:', data);
  data.timestamp = new Date().toISOString();
  measurementsSensor2.push(data);
  io.emit('updateHumiditySensor2', data);
  
  // Speichere die Daten nach jeder Änderung
  saveSensorData();
  
  res.status(200).json({ success: true });
});

// Aktualisiere die WebSocket-Verbindung
io.on('connection', (socket) => {
  console.log('New client connected');

  // Empfang von Daten des ersten Sensors
  socket.on('humidityData', (data) => {
    console.log('Humidity Data (Sensor 1) Received:', data);
    const timestamp = new Date().toISOString();
    measurementsSensor1.push({ ...data, timestamp });
    io.emit('updateHumidity', data);
    
    // Speichere die Daten nach jeder Änderung
    saveSensorData();
  });

  // Empfang von Daten des zweiten Sensors
  socket.on('humidityDataSensor2', (data) => {
    console.log('Humidity Data (Sensor 2) Received:', data);
    const timestamp = new Date().toISOString();
    measurementsSensor2.push({ ...data, timestamp });
    io.emit('updateHumiditySensor2', data);
    
    // Speichere die Daten nach jeder Änderung
    saveSensorData();
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected');
  });
});

// Regelmäßiges Speichern der Daten (alle 5 Minuten)
setInterval(saveSensorData, 5 * 60 * 1000);

// Beim Serverstart Daten laden
loadSensorData();

// Bei Serverbeendigung Daten speichern
process.on('SIGINT', () => {
  console.log('Server wird beendet, speichere Daten...');
  saveSensorData();
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('Server wird beendet, speichere Daten...');
  saveSensorData();
  process.exit(0);
});

// Routen für die Webseiten
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.get('/vpd', (req, res) => {
  res.sendFile(path.join(__dirname, 'vpd.html'));
});

app.get('/measurements', (req, res) => {
  res.sendFile(path.join(__dirname, 'measurements.html'));
});

app.get('/measurements-bluetezelt.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'measurements-bluetezelt.html'));
});

app.get('/measurements-aufzuchtszelt.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'measurements-aufzuchtszelt.html'));
});

app.get('/grow-journal.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'grow-journal.html'));
});

app.get('/vpd-bluetezelt.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'vpd-bluetezelt.html'));
});

app.get('/vpd-aufzuchtszelt.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'vpd-aufzuchtszelt.html'));
});

app.get('/vpd-manuell.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'vpd-manuell.html'));
});

// API-Routen für JSON-Daten
app.get('/api/measurements/bluetezelt', (req, res) => {
  res.json(measurementsSensor1);
});

app.get('/api/measurements/aufzuchtszelt', (req, res) => {
  res.json(measurementsSensor2);
});

// Dashboard-Route
app.get('/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'data', 'dashboard.html'));
});

// Beispieldaten hinzufügen, falls keine vorhanden sind
function addSampleData() {
    // Nur hinzufügen, wenn noch keine Daten vorhanden sind
    if (measurementsSensor1.length === 0) {
        const now = new Date();
        
        // Für Blütezelt
        for (let i = 0; i < 100; i++) {
            const timestamp = new Date(now.getTime() - i * 30 * 60 * 1000); // Alle 30 Minuten
            measurementsSensor1.push({
                timestamp: timestamp.toISOString(),
                temperature: 25 + Math.random() * 3 - 1.5,
                humidity: 60 + Math.random() * 10 - 5
            });
        }
    }
    
    if (measurementsSensor2.length === 0) {
        const now = new Date();
        
        // Für Aufzuchtszelt
        for (let i = 0; i < 100; i++) {
            const timestamp = new Date(now.getTime() - i * 30 * 60 * 1000); // Alle 30 Minuten
            measurementsSensor2.push({
                timestamp: timestamp.toISOString(),
                temperature: 23 + Math.random() * 3 - 1.5,
                humidity: 70 + Math.random() * 10 - 5
            });
        }
    }
}

// Server starten
const PORT = process.env.PORT || 9100;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});