import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static const _appOpenKey = 'app_opens_today';
  static const _totalTimeKey = 'total_time_today';
  static const _lastDateKey = 'last_analytics_date';

  static DateTime _sessionStart = DateTime.now();

  /// Wird beim App-Start aufgerufen
  static Future<void> initSession() async {
    _sessionStart = DateTime.now();
    await _incrementAppOpenCount();
  }

  /// Wird beim App-Schließen aufgerufen (lifecycle hook)
  static Future<void> endSession() async {
    final prefs = await SharedPreferences.getInstance();
    final duration = DateTime.now().difference(_sessionStart);
    
    // Nur Sessions länger als 1 Sekunde zählen
    if (duration.inSeconds > 1) {
      final totalTime = prefs.getInt(_totalTimeKey) ?? 0;
      await prefs.setInt(_totalTimeKey, totalTime + duration.inSeconds);
    }
  }

  static Future<void> _incrementAppOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getDateString(DateTime.now());
    final lastDate = prefs.getString(_lastDateKey) ?? '';

    // Wenn neuer Tag: Counter zurücksetzen
    if (lastDate != today) {
      await prefs.setInt(_appOpenKey, 1);
      await prefs.setInt(_totalTimeKey, 0);
      await prefs.setString(_lastDateKey, today);
    } else {
      final current = prefs.getInt(_appOpenKey) ?? 0;
      await prefs.setInt(_appOpenKey, current + 1);
    }
  }

  static Future<int> getAppOpensToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getDateString(DateTime.now());
    final lastDate = prefs.getString(_lastDateKey) ?? '';
    
    if (lastDate != today) {
      return 0;
    }
    
    return prefs.getInt(_appOpenKey) ?? 0;
  }

  static Future<Duration> getSessionTimeToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getDateString(DateTime.now());
    final lastDate = prefs.getString(_lastDateKey) ?? '';
    
    if (lastDate != today) {
      return Duration.zero;
    }
    
    final seconds = prefs.getInt(_totalTimeKey) ?? 0;
    return Duration(seconds: seconds);
  }

  static Future<Map<String, dynamic>> getDailyAnalytics() async {
    final opens = await getAppOpensToday();
    final time = await getSessionTimeToday();
    
    return {
      'opens': opens,
      'totalSeconds': time.inSeconds,
      'formattedTime': _formatDuration(time),
    };
  }

  static String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}
