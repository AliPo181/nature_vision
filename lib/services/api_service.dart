import 'package:http/http.dart' as http;
import 'dart:convert';
import 'device_auth_service.dart';

class ApiService {
  // ⚠️ Ändere diese URL zu deinem Backend-Server
  static const String baseUrl = 'http://localhost:3000/api';

  static final _client = http.Client();

  // ─── Mementos ────────────────────────────────────────────────────────────

  /// Uploaded ein neues Memento zum Backend
  static Future<bool> uploadMemento({
    required String prompt,
    required String? photoPath,
    required String? note,
    required DateTime date,
  }) async {
    try {
      final headers = await DeviceAuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final body = jsonEncode({
        'prompt': prompt,
        'photoPath': photoPath,
        'note': note,
        'date': date.toIso8601String(),
      });

      final response = await _client.post(
        Uri.parse('$baseUrl/mementos'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error uploading memento: $e');
      return false;
    }
  }

  /// Lädt alle Mementos vom Backend herunter
  static Future<List<Map<String, dynamic>>?> fetchMementos() async {
    try {
      final headers = await DeviceAuthService.getAuthHeaders();

      final response = await _client.get(
        Uri.parse('$baseUrl/mementos'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      print('Error fetching mementos: $e');
      return null;
    }
  }

  /// Updated ein existierendes Memento
  static Future<bool> updateMemento({
    required String id,
    required String prompt,
    required String? note,
    required DateTime date,
  }) async {
    try {
      final headers = await DeviceAuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final body = jsonEncode({
        'prompt': prompt,
        'note': note,
        'date': date.toIso8601String(),
      });

      final response = await _client.patch(
        Uri.parse('$baseUrl/mementos/$id'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating memento: $e');
      return false;
    }
  }

  /// Löscht ein Memento
  static Future<bool> deleteMemento(String id) async {
    try {
      final headers = await DeviceAuthService.getAuthHeaders();

      final response = await _client.delete(
        Uri.parse('$baseUrl/mementos/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error deleting memento: $e');
      return false;
    }
  }

  // ─── User ────────────────────────────────────────────────────────────────

  /// Registriert oder logt einen User ein (Device-based)
  static Future<Map<String, dynamic>?> registerUser(String userName) async {
    try {
      final deviceId = await DeviceAuthService.getOrCreateDeviceId();
      final userId = await DeviceAuthService.getOrCreateUserId();

      final body = jsonEncode({
        'name': userName,
        'deviceId': deviceId,
        'userId': userId,
      });

      final response = await _client.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }

  /// Lädt User-Daten vom Backend
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final headers = await DeviceAuthService.getAuthHeaders();

      final response = await _client.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // ─── Analytics ──────────────────────────────────────────────────────────

  /// Sendet tägliche Analytics zum Backend
  static Future<bool> reportDailyAnalytics({
    required int appOpens,
    required int totalSeconds,
    required int streak,
    required int mementoCount,
  }) async {
    try {
      final headers = await DeviceAuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final body = jsonEncode({
        'date': DateTime.now().toIso8601String(),
        'appOpens': appOpens,
        'totalSeconds': totalSeconds,
        'streak': streak,
        'mementoCount': mementoCount,
      });

      final response = await _client.post(
        Uri.parse('$baseUrl/analytics'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error reporting analytics: $e');
      return false;
    }
  }

  // ─── Health Check ────────────────────────────────────────────────────────

  /// Prüft, ob der Backend-Server erreichbar ist
  static Future<bool> healthCheck() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Backend not reachable: $e');
      return false;
    }
  }

  // ─── Sessions ────────────────────────────────────────────────────────────

  /// Startet eine neue Session
  static Future<Map<String, dynamic>?> startSession(String deviceId) async {
    try {
      final headers = await DeviceAuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final body = jsonEncode({'deviceId': deviceId});

      final response = await _client.post(
        Uri.parse('$baseUrl/sessions/start'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Error starting session: $e');
      return null;
    }
  }

  /// Beendet eine Session
  static Future<bool> endSession(String sessionId) async {
    try {
      final headers = await DeviceAuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final body = jsonEncode({'sessionId': sessionId});

      final response = await _client.post(
        Uri.parse('$baseUrl/sessions/end'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error ending session: $e');
      return false;
    }
  }

  // ─── Events ──────────────────────────────────────────────────────────────

  /// Logged ein Event
  static Future<bool> logEvent({
    required String sessionId,
    required String eventType,
    Map<String, dynamic>? data,
  }) async {
    try {
      final headers = await DeviceAuthService.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      final body = jsonEncode({
        'sessionId': sessionId,
        'eventType': eventType,
        'data': data ?? {},
      });

      final response = await _client.post(
        Uri.parse('$baseUrl/events'),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 201;
    } catch (e) {
      print('Error logging event: $e');
      return false;
    }
  }

  static void dispose() {
    _client.close();
  }
}
