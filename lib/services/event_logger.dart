import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'device_auth_service.dart';

class EventLogger {
  static String? _currentSessionId;
  static DateTime? _sessionStartTime;

  /// Startet eine neue Session wenn die App geöffnet wird
  static Future<void> startSession() async {
    final deviceId = await DeviceAuthService.getOrCreateDeviceId();

    try {
      final response = await ApiService.startSession(deviceId);
      if (response != null) {
        _currentSessionId = response['sessionId'];
        _sessionStartTime = DateTime.now();
        debugPrint('📍 Session started: $_currentSessionId');
      }
    } catch (e) {
      debugPrint('Error starting session: $e');
    }
  }

  /// Beendet die aktuelle Session
  static Future<void> endSession() async {
    if (_currentSessionId == null) return;

    try {
      await ApiService.endSession(_currentSessionId!);
      debugPrint('📍 Session ended: $_currentSessionId');
      _currentSessionId = null;
      _sessionStartTime = null;
    } catch (e) {
      debugPrint('Error ending session: $e');
    }
  }

  /// Logged verschiedene Events
  static Future<void> logEvent({
    required String eventType,
    Map<String, dynamic>? data,
  }) async {
    if (_currentSessionId == null) {
      debugPrint('⚠️ No active session to log event');
      return;
    }

    try {
      await ApiService.logEvent(
        sessionId: _currentSessionId!,
        eventType: eventType,
        data: data,
      );
      debugPrint('📊 Event logged: $eventType');
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  // ─── Convenience Methods ──────────────────────────────────────────────

  static Future<void> logPromptViewed(String prompt) => logEvent(
    eventType: 'prompt_viewed',
    data: {'prompt': prompt},
  );

  static Future<void> logPhotoTaken(String photoPath) => logEvent(
    eventType: 'photo_taken',
    data: {'photoPath': photoPath},
  );

  static Future<void> logNoteAdded(String note) => logEvent(
    eventType: 'note_added',
    data: {
      'noteLength': note.length,
      'preview': note.length > 50 ? note.substring(0, 50) : note,
    },
  );

  static Future<void> logMementoSaved(String prompt) => logEvent(
    eventType: 'memento_saved',
    data: {'prompt': prompt},
  );

  static Future<void> logPromptSkipped(String prompt) => logEvent(
    eventType: 'prompt_skipped',
    data: {'prompt': prompt},
  );

  static Future<void> logTabChanged(String tabName) => logEvent(
    eventType: 'tab_changed',
    data: {'tab': tabName},
  );

  static Future<void> logMementoViewed(String mementoId) => logEvent(
    eventType: 'memento_viewed',
    data: {'mementoId': mementoId},
  );

  static Future<void> logMementoEdited(String mementoId) => logEvent(
    eventType: 'memento_edited',
    data: {'mementoId': mementoId},
  );

  static Future<void> logMementoDeleted(String mementoId) => logEvent(
    eventType: 'memento_deleted',
    data: {'mementoId': mementoId},
  );

  static Future<void> logOnboardingCompleted(String userName) => logEvent(
    eventType: 'onboarding_completed',
    data: {'userName': userName},
  );
}
