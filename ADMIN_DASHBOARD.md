# Admin Dashboard Guide

Du kannst alle User-Aktivitäten in **Echtzeit** auf einem Web-Interface sehen! 🎯

## 🚀 Quickstart

### 1. Backend starten
```bash
cd backend
npm install
npm start
```

### 2. Dashboard öffnen
Öffne im Browser: **http://localhost:3000/admin**

Das's it! 🎉

---

## 📊 Was kannst du sehen?

### 👥 **Benutzer Tab**
- **Name** des Benutzers
- **Anonymisierte User-ID** (nur erste 12 Zeichen sichtbar)
- Anzahl Sessions
- Anzahl Events
- Zeitstempel der Registrierung

Klick auf einen User, um die volle User-ID zu sehen.

### 📱 **Sessions Tab**
- **Session-ID** (einzigartig für jede App-Öffnung)
- **User-ID** (wer hat die App geöffnet)
- **Start-Zeit**: Wann wurde die App geöffnet
- **End-Zeit**: Wann wurde die App geschlossen
- **Dauer**: Wie lange war die App offen (z.B. "15m 32s")
- **Status**: 🔴 Aktiv oder ✅ Beendet
- **Events**: Wie viele Events in dieser Session

Filter nach User-ID oder Session-ID.

**Beispiel**:
```
Session: session_1718... 
User: a1b2c3d4e5f6...
Start: 14:32:15
Dauer: 5m 42s
Events: 8
```

### 📊 **Events Tab**
Alle Aktionen die der User in der App gemacht hat:

#### Event Types:

| Event | Bedeutung |
|-------|-----------|
| **prompt_viewed** | User hat einen neuen Prompt angesehen |
| **photo_taken** | Photo wurde mit Kamera/Galerie aufgenommen |
| **note_added** | User hat eine Notiz geschrieben |
| **memento_saved** | Memento wurde gespeichert |
| **prompt_skipped** | Prompt wurde übersprungen |
| **tab_changed** | User wechselte zu einem anderen Tab |
| **memento_viewed** | User hat ein Memento angeschaut |
| **memento_edited** | User hat ein Memento bearbeitet |
| **memento_deleted** | Memento wurde gelöscht |
| **onboarding_completed** | User hat Onboarding abgeschlossen |

Jedes Event zeigt:
- **Event-Typ** (farbig gekennzeichnet)
- **User-ID**
- **Zeitstempel** (genau wann)
- **Zusatz-Daten** (z.B. Prompt-Text, Note-Länge)

**Beispiel**:
```
📊 prompt_viewed [a1b2c3d4]
14:32:42
Data: {
  prompt: "Find something soft"
}

📷 photo_taken [a1b2c3d4]  
14:33:15
Data: {
  photoPath: "/path/to/photo.jpg"
}

💾 memento_saved [a1b2c3d4]
14:34:21
Data: {
  prompt: "Find something soft"
}
```

---

## 🔍 Features des Dashboards

### Auto-Refresh
Das Dashboard aktualisiert sich **automatisch alle 10 Sekunden** mit neuen Events und Sessions.

### Live-Statistiken
Oben sehen 4 Karten mit aktuellen Zahlen:
- **Benutzer**: Gesamtzahl der registrierten User
- **Sessions**: Alle Sessions gesamt
- **Events**: Alle Events gesamt
- **Aktive Sessions**: Sessions die gerade offen sind 🔴

### Suchen & Filtern
- **Sessions-Tab**: Nach User-ID oder Session-ID filtern
- **Events-Tab**: Nach User-ID oder Event-Type filtern

### Details aufklappen
Klick auf jedes Item um Details zu sehen:
- Volle IDs (nicht gekürzt)
- Alle Datensätze
- Timestamps

---

## 🎯 Use Cases

### Beispiel 1: Ein User macht eine "Nature Walk Session"

1. **Session Start** (14:00:00)
   - Backend logs: Session gestartet
   - Dashboard zeigt: 🔴 Aktiv

2. **Events während der Session**:
   - 14:02:15 - `prompt_viewed`: "Find something soft"
   - 14:03:42 - `photo_taken` - User macht Foto
   - 14:04:10 - `note_added` - "Beautiful moss texture!"
   - 14:04:25 - `memento_saved`
   - 14:05:00 - `tab_changed` to "Journal"
   - 14:05:45 - `tab_changed` to "Walk"
   - 14:06:10 - `prompt_viewed`: "Capture something that moves"

3. **Session End** (14:15:30)
   - User schließt App
   - Backend logs: Session beendet
   - Dashboard zeigt: ✅ Beendet, Dauer: 15m 30s

### Beispiel 2: Analysen über User Verhalten

Du kannst sehen:
- **Wie lange** nutzen User die App? (Duration in Sessions)
- **Wann** nutzen sie sie? (Start-Zeit)
- **Was** machen sie? (Event-Typen und -Reihenfolge)
- **Wie oft** speichern sie Mementos? (Anzahl `memento_saved` Events)
- **Nutzen** sie alle Features? (Alle Event-Types vorhanden?)

---

## 🔐 Sicherheit & Datenschutz

Das Dashboard zeigt:
- ✅ **Anonymisierte User-IDs** (nicht der echte Name)
- ✅ **Zeitstempel** (NICHT der genaue Standort)
- ✅ **Aktionen** (WAS der User macht, nicht WO)
- ✅ **Prompts & Text** (was der User sieht)
- ❌ **KEINE** sensiblen Daten
- ❌ **KEINE** Bilder/Photos (nur Pfade)
- ❌ **KEINE** GPS/Standort

---

## 📈 Backend-Daten speichern

Aktuell speichert das Backend alles **im RAM**. Das bedeutet:
- ✅ Schnell & einfach
- ❌ Daten sind weg wenn der Server restarts

Für Production solltest du eine **echte Datenbank** nutzen:

### Option 1: MongoDB
```bash
npm install mongoose
```

Dann Models für Users, Sessions, Events erstellen.

### Option 2: PostgreSQL
```bash
npm install pg sequelize
```

### Option 3: Firebase
```bash
npm install firebase-admin
```

---

## 🛠️ Troubleshooting

### Dashboard lädt nicht
1. Ist der Backend am Laufen? `npm start` in `backend/`
2. URL korrekt? Sollte `http://localhost:3000/admin` sein
3. Port blockiert? Versuche `PORT=5000 npm start`

### Keine Events sichtbar
1. Öffne die App auf deinem Gerät
2. Mach was in der App (Foto, Note, etc.)
3. Warte 1-2 Sekunden
4. Klick "🔄 Aktualisieren" im Dashboard

### Alte Daten weg nach Server-Restart
Das ist normal! Im RAM-Mode werden Daten nicht persistiert.
Lösung: Mit MongoDB/PostgreSQL Datenbankintegrieren.

---

## 📱 Mobile vs. Dashboard

```
Flutter App                Backend               Browser/Admin
┌──────────────┐          ┌──────────┐         ┌──────────────┐
│ User Actions │ -------> │ Log      │ ------> │ Dashboard    │
│ - Photos     │  POST    │ Events & │  GET    │ - Real-time  │
│ - Notes      │  /api    │ Sessions │  /admin │ - Analytics  │
│ - Skips      │ Sessions │ Store    │         │ - User Data  │
└──────────────┘          └──────────┘         └──────────────┘
```

---

## 💡 Tipps & Tricks

1. **Mehrere Browser-Tabs öffnen**: Einen für Users, einen für Events
2. **Session-Details**: Klick auf eine Session um alle ihre Events zu sehen
3. **Zeitpunkt vergleichen**: Sessions-Dauer mit Event-Zeitstempel vergleichen
4. **User verfolgen**: Filtern nach einer User-ID um alles von einem User zu sehen

---

## 🚀 Nächste Schritte

1. **Backend mit Datenbank**: Persistente Speicherung
2. **Erweiterte Analysen**: Graphen, Charts, Reports
3. **Export**: Sessions/Events als CSV/JSON exportieren
4. **Alerts**: Benachrichtigungen bei abnormalen Aktivitäten
5. **User-Management**: Block, Unblock, Delete Users

