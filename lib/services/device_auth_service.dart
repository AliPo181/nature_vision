import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';

class DeviceAuthService {
  static const _deviceIdKey = 'device_id';
  static const _userIdKey = 'user_id';
  static final _deviceInfo = DeviceInfoPlugin();

  /// Generiert eine eindeutige Device-ID beim ersten Start
  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = await _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  /// Erstellt eine eindeutige User-ID (kann sich unterscheiden von Device-ID)
  static Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString(_userIdKey);

    if (userId == null) {
      userId = _generateRandomId();
      await prefs.setString(_userIdKey, userId);
    }

    return userId;
  }

  static Future<String> _generateDeviceId() async {
    try {
      String identifier = '';

      final androidInfo = await _deviceInfo.androidInfo;
      identifier = androidInfo.id;

      // Kombiniere mit anderen Infos für mehr Eindeutigkeit
      final combined = '$identifier-${DateTime.now().millisecondsSinceEpoch}';
      final deviceId = md5.convert(utf8.encode(combined)).toString();

      return deviceId;
    } catch (e) {
      // Fallback: Zufällige ID
      return _generateRandomId();
    }
  }

  static String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(32, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Gibt Auth-Header für API-Requests zurück
  static Future<Map<String, String>> getAuthHeaders() async {
    final deviceId = await getOrCreateDeviceId();
    final userId = await getOrCreateUserId();

    return {
      'X-Device-ID': deviceId,
      'X-User-ID': userId,
    };
  }

  /// Gibt Device-Info zurück für Debug/Analytics
  static Future<Map<String, String>> getDeviceInfo() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return {
        'manufacturer': androidInfo.manufacturer,
        'model': androidInfo.model,
        'version': androidInfo.version.toString(),
      };
    } catch (e) {
      return {'error': 'Could not get device info'};
    }
  }
}
