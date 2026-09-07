import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/guest_session_model.dart';
import '../models/guest_measurement_model.dart';

/// Local repository for Guest Mode — stores everything in SharedPreferences.
/// Keys are namespaced with 'guest_' to avoid collision with internal timer cache.
class GuestLocalRepository {
  static const String _activeSessionKey = 'guest_active_session_v1';
  static const String _activeTimersKey = 'guest_active_timers_v1';
  static const String _sessionMeasurementsPrefix = 'guest_measurements_';
  static const String _sessionHistoryKey = 'guest_session_history_v1';

  // ─── Active Session ───

  Future<void> saveActiveSession(GuestSessionModel session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSessionKey, jsonEncode(session.toJson()));
  }

  Future<GuestSessionModel?> loadActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeSessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final session = GuestSessionModel.fromJson(jsonDecode(raw));
      return session.isActive ? session : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSessionKey);
  }

  // ─── Active Timers (running/paused measurements) ───

  Future<void> saveActiveTimers(List<GuestMeasurementModel> timers) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = timers.map((m) => m.toJson()).toList();
    await prefs.setString(_activeTimersKey, jsonEncode(jsonList));
  }

  Future<List<GuestMeasurementModel>> loadActiveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeTimersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => GuestMeasurementModel.fromJson(Map<String, dynamic>.from(e)))
          .where((m) => m.status.isActive)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearActiveTimers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeTimersKey);
  }

  // ─── Session Measurements (all measurements for a session) ───

  String _measurementsKey(String sessionId) => '$_sessionMeasurementsPrefix$sessionId';

  Future<void> saveMeasurements(String sessionId, List<GuestMeasurementModel> measurements) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = measurements.map((m) => m.toJson()).toList();
    await prefs.setString(_measurementsKey(sessionId), jsonEncode(jsonList));
  }

  Future<List<GuestMeasurementModel>> loadMeasurements(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_measurementsKey(sessionId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => GuestMeasurementModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ─── Session History (completed sessions list) ───

  Future<List<GuestSessionModel>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionHistoryKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded
          .map((e) => GuestSessionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> addToHistory(GuestSessionModel session) async {
    final history = await loadHistory();
    // Avoid duplicates
    history.removeWhere((s) => s.id == session.id);
    history.insert(0, session);
    await _saveHistory(history);
  }

  Future<void> _saveHistory(List<GuestSessionModel> history) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((s) => s.toJson()).toList();
    await prefs.setString(_sessionHistoryKey, jsonEncode(jsonList));
  }

  Future<void> clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Remove history
    await prefs.remove(_sessionHistoryKey);
    // Remove all measurement keys
    final keys = prefs.getKeys().where((k) => k.startsWith(_sessionMeasurementsPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> clearAll() async {
    await clearActiveSession();
    await clearActiveTimers();
    await clearAllHistory();
  }
}
