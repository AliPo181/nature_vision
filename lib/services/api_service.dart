import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'device_auth_service.dart';

class ApiService {
  // NOTE: Event visibility/privacy is handled by backend. The app only sends event data for admin purposes.

  // ⚠️ Ändere diese URL zu deinem Backend-Server
  static const String baseUrl = 'https://nv.cipot.dev/api/';

  static final _client = http.Client();

  // ─── Mementos ────────────────────────────────────────────────────────────

  /// Uploaded ein neues Memento zum Backend
  static Future<String?> uploadMemento({
    required String prompt,
    required String? photoPath,
    required String? note,
    required DateTime date,
  }) async {
    try {
      final headers = await DeviceAuthService.getAuthHeaders();
      final uri = Uri.parse('$baseUrl/mementos');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..fields['prompt'] = prompt
        ..fields['date'] = date.toIso8601String();

      if (note != null) {
        request.fields['note'] = note;
      }

      if (photoPath != null && photoPath.isNotEmpty) {
        final file = File(photoPath);
        if (await file.exists()) {
          // Backend field name (current guess): "photo"
          request.files.add(await http.MultipartFile.fromPath('photo', photoPath));
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      final bodyText = response.body.trim();

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint(
          'uploadMemento failed: status=${response.statusCode}, body=$bodyText',
        );
        // Keep a clear signal in logs for backend alignment.
        debugPrint('uploadMemento request preview: promptLength=${prompt.length}, photoPath=$photoPath, notePresent=${note != null}');
        return null;
      }


      if (bodyText.isEmpty) {
        // Backend might return an empty body but still create the record.
        // In that case we can't get the id.
        debugPrint('uploadMemento success but empty body (no id returned).');
        return null;
      }

      final decoded = jsonDecode(bodyText);
      if (decoded is Map<String, dynamic>) {
        final id =
            decoded['mementoId'] ?? decoded['id'] ?? decoded['_id'] ?? decoded['uuid'];
        return id?.toString();
      }

      // Sometimes backend returns: {"data": {"id": "..."}}
      if (decoded is Map) {
        final data = decoded['data'];
        if (data is Map) {
          final id = data['mementoId'] ?? data['id'] ?? data['_id'] ?? data['uuid'];
          return id?.toString();
        }
      }

      debugPrint('uploadMemento success but unrecognized response body: $bodyText');
      return null;
    } catch (e) {
      debugPrint('Error uploading memento: $e');
      return null;
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
      debugPrint('Error fetching mementos: $e');
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
      debugPrint('Error updating memento: $e');
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
      debugPrint('Error deleting memento: $e');
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
      debugPrint('Error registering user: $e');
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
      debugPrint('Error fetching user profile: $e');
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
      debugPrint('Error reporting analytics: $e');
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
      debugPrint('Backend not reachable: $e');
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
      debugPrint('Error starting session: $e');
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
      debugPrint('Error ending session: $e');
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
    // App does not store or display these events to the user; backend decides what admin can view.

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
      debugPrint('Error logging event: $e');
      return false;
    }
  }

  static void dispose() {
    _client.close();
  }
}
