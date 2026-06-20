# Setup-Anleitung für Nature Vision Features

## 📝 Überblick der implementierten Features

### 1. ✅ Daily Reminders (Tägliche Reminders um 12 Uhr)
- **Service**: `lib/services/notification_service.dart`
- **Status**: Implementiert und aktiv
- Sendet täglich um 12:00 Uhr eine Benachrichtigung

### 2. ✅ Analytics (App-Öffnungen & Sitzungsdauer)
- **Service**: `lib/services/analytics_service.dart`
- **Status**: Implementiert und aktiv
- Tracked:
  - Anzahl App-Öffnungen pro Tag
  - Verbrachte Zeit in der App (in Sekunden)
  - Auto-Reset um Mitternacht
- **Anzeige**: Analytics-Card auf dem Homescreen

### 3. ✅ Device Authentication (Device-ID & User-ID)
- **Service**: `lib/services/device_auth_service.dart`
- **Status**: Implementiert, bereit für API-Integration
- Generiert automatisch:
  - Eindeutige Device-ID
  - Eindeutige User-ID
- Kann mit `getAuthHeaders()` für API-Requests genutzt werden

## 🔧 Erforderliche Android-Konfiguration

### AndroidManifest.xml
In `android/app/src/main/AndroidManifest.xml` müssen diese Permissions hinzugefügt sein:

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

### Notification Channel
Das wird automatisch erstellt in `notification_service.dart`:
- **Channel ID**: `nature_vision_channel`
- **Name**: Daily Reminder
- **Importance**: Default

## 🍎 Erforderliche iOS-Konfiguration

### Info.plist
In `ios/Runner/Info.plist` können optional hinzugefügt werden:
```xml
<key>UIUserInterfaceStyle</key>
<string>Light</string>
```

### Notification Permissions
Das App wird beim Start um Notification-Permissions fragen (automatisch via flutter_local_notifications).

## 📦 Abhängigkeiten

Alle notwendigen Packages sind bereits in `pubspec.yaml` hinzugefügt:
- `flutter_local_notifications: ^17.1.0` - Für Reminders
- `device_info_plus: ^10.0.0` - Für Device-Info
- `timezone: ^0.9.4` - Für Zeitzone-Handling
- `crypto: ^3.0.3` - Für Device-ID Hashing

## 🚀 Nach Flutter pub get

```bash
flutter pub get
flutter clean
flutter pub get
```

Dann kannst du die App starten:
```bash
flutter run
```

## 🧪 Testing der Features

### Daily Reminder testen
1. Öffne die App
2. Navigiere zu 12:00 Uhr (oder ändere die Zeit in `main.dart` für schnellere Tests)
3. Eine Benachrichtigung sollte angezeigt werden

### Analytics testen
1. Öffne und schließe die App mehrmals
2. Verbringige Zeit in der App
3. Analytics-Card auf dem Homescreen zeigt die Werte an
4. Nach Mitternacht wird alles zurückgesetzt

### Device-ID testen
```dart
import 'services/device_auth_service.dart';

// In irgendeinem Widget:
final deviceId = await DeviceAuthService.getOrCreateDeviceId();
final userId = await DeviceAuthService.getOrCreateUserId();
final headers = await DeviceAuthService.getAuthHeaders();
```

## 🔗 API-Integration vorbereiten

Wenn du den Backend-Teil later hinzufügst, kannst du die Device-ID und User-ID so nutzen:

```dart
import 'services/device_auth_service.dart';

final headers = await DeviceAuthService.getAuthHeaders();
final response = await http.post(
  Uri.parse('https://your-backend.com/api/mementos'),
  headers: {
    ...headers,
    'Content-Type': 'application/json',
  },
  body: jsonEncode(mementoData),
);
```

## 📋 Nächste Schritte

1. **Backend-Setup**: REST API für Memento-Speicherung
2. **Cloud-Sync**: Automatisches Syncing von Mementos mit Backend
3. **User-Profile**: Backend-seitiges User-Profile Management
4. **Erweiterte Analytics**: Mehr Metriken (z.B. Streak-Tracking über Backend)

