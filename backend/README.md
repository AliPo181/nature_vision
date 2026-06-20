# Nature Vision Backend API

Einfaches Express.js Backend für die Nature Vision Flutter App.

## 🚀 Schnellstart

### 1. Backend installieren
```bash
cd backend
npm install
```

### 2. Server starten
```bash
npm start
```

Der Server läuft dann unter: **http://localhost:3000/api**

### 3. Entwicklungsmodus (mit Auto-Reload)
```bash
npm install -D nodemon  # einmalig
npm run dev
```

---

## 📡 API Endpoints

### Health Check
```
GET /api/health
Response: { status: 'ok', message: 'Backend is running' }
```

### User Management
```
POST /api/users/register
Body: { name, deviceId, userId }
Response: { message, user }

GET /api/users/profile
Headers: X-User-ID, X-Device-ID
Response: { user data }
```

### Mementos (CRUD)
```
POST /api/mementos
Headers: X-User-ID, X-Device-ID
Body: { prompt, photoPath, note, date }
Response: { message, memento }

GET /api/mementos
Headers: X-User-ID, X-Device-ID
Response: [{ mementos array }]

PATCH /api/mementos/:id
Headers: X-User-ID, X-Device-ID
Body: { prompt, note, date }
Response: { message, memento }

DELETE /api/mementos/:id
Headers: X-User-ID, X-Device-ID
Response: { message: 'Memento deleted' }
```

### Analytics
```
POST /api/analytics
Headers: X-User-ID, X-Device-ID
Body: { date, appOpens, totalSeconds, streak, mementoCount }
Response: { message, record }

GET /api/analytics
Headers: X-User-ID, X-Device-ID
Response: [{ analytics array }]
```

---

## 🔗 Integration in Flutter App

Der API Client ist bereits in der App konfiguriert:

**Datei**: `lib/services/api_service.dart`

Beispiel-Nutzung:

```dart
import 'services/api_service.dart';

// Memento hochladen
await ApiService.uploadMemento(
  prompt: 'Find something soft',
  photoPath: '/path/to/photo.jpg',
  note: 'Beautiful moss!',
  date: DateTime.now(),
);

// Mementos laden
final mementos = await ApiService.fetchMementos();

// Analytics senden
await ApiService.reportDailyAnalytics(
  appOpens: 5,
  totalSeconds: 1200,
  streak: 10,
  mementoCount: 25,
);

// Health Check
final isOnline = await ApiService.healthCheck();
```

---

## ⚙️ Configuration

Die Backend-URL ist in `lib/services/api_service.dart` definiert:

```dart
static const String baseUrl = 'http://localhost:3000/api';
```

Änderungen für verschiedene Umgebungen:

- **Lokal (Development)**: `http://localhost:3000/api`
- **Android Emulator**: `http://10.0.2.2:3000/api`
- **iOS Simulator**: `http://localhost:3000/api`
- **Production**: `https://your-domain.com/api`

---

## 🗄️ Datenspeicherung

Dieses Backend speichert alles **im RAM** (in-memory). Das ist perfekt zum Testen, aber für Production solltest du eine echte Datenbank verwenden:

### Empfehlung: MongoDB

```bash
npm install mongoose
```

Ersetze die in-memory Maps mit Mongoose Models für persistente Speicherung.

---

## 📝 Nächste Schritte

1. **Testen**: Starte Backend und prüfe `http://localhost:3000/api/health`
2. **Integration**: Verwende `ApiService` in der Flutter App
3. **Production**: Deploye auf Heroku, Firebase, oder eigenen Server
4. **Datenbank**: Ersetze in-memory Storage mit MongoDB/PostgreSQL

---

## 🐛 Troubleshooting

### Backend antwortet nicht
```bash
# Check ob Port 3000 nicht blockiert ist
netstat -ano | findstr :3000

# Alternativ: Anderen Port nutzen
PORT=5000 npm start
```

### CORS Fehler
✅ Ist bereits konfiguriert mit `cors()` Middleware

### Headers-Fehler in API Calls
Stelle sicher, dass die Flutter App diese Headers sendet:
- `X-User-ID`
- `X-Device-ID`

Diese werden automatisch vom `ApiService` hinzugefügt.
