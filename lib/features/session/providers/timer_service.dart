import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../models/measurement_model.dart';
import '../../../models/performance_session_model.dart';
import '../../../models/schedule_model.dart';
import '../../../core/utils/schedule_helper.dart';
import '../repositories/performance_repository.dart';
import '../../auth/providers/auth_provider.dart';

final performanceRepositoryProvider = Provider<PerformanceRepository>((ref) {
  return PerformanceRepository();
});

/// Weekly schedule stream for the current active store
final currentWeekScheduleProvider = StreamProvider<ScheduleModel?>((ref) {
  final storeId = ref.watch(currentStoreIdProvider);
  if (storeId == null || storeId.isEmpty) return Stream.value(null);
  final weekStart = ScheduleHelper.getWeekStartString();
  return ref.watch(performanceRepositoryProvider).watchWeekSchedule(storeId, weekStart);
});

/// Active session stream for the current active store
final activeSessionProvider = StreamProvider<PerformanceSessionModel?>((ref) {
  final storeId = ref.watch(currentStoreIdProvider);
  if (storeId == null || storeId.isEmpty) return Stream.value(null);
  return ref.watch(performanceRepositoryProvider).watchActiveSession(storeId);
});

/// Measurements stream for the currently active session
final sessionMeasurementsProvider = StreamProvider<List<MeasurementModel>>((ref) {
  final session = ref.watch(activeSessionProvider).valueOrNull;
  if (session == null) return Stream.value([]);
  return ref.watch(performanceRepositoryProvider).watchMeasurements(session.id);
});

/// Performance Timer Engine State
class PerformanceTimerState {
  final List<MeasurementModel> activeTimers;
  final int tick; // Incrementing counter for UI rebuilds

  const PerformanceTimerState({
    this.activeTimers = const [],
    this.tick = 0,
  });

  PerformanceTimerState copyWith({
    List<MeasurementModel>? activeTimers,
    int? tick,
  }) {
    return PerformanceTimerState(
      activeTimers: activeTimers ?? this.activeTimers,
      tick: tick ?? this.tick,
    );
  }
}

/// Global Timer Notifier managing all concurrent timers
class PerformanceTimerNotifier extends StateNotifier<PerformanceTimerState> {
  final Ref _ref;
  Timer? _ticker;
  static const String _localTimersKey = 'perf_active_timers_v1';
  final _uuid = const Uuid();

  PerformanceTimerNotifier(this._ref) : super(const PerformanceTimerState()) {
    _initTicker();
    _restoreLocalTimers();
  }

  void _initTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (state.activeTimers.any((t) => t.status == MeasurementStatus.running)) {
        state = state.copyWith(tick: state.tick + 1);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Start a new measurement timer
  Future<String?> startTimer({
    required PerformanceCategory category,
    int quantity = 1,
    String? orderCode,
    String? staffName,
  }) async {
    final session = _ref.read(activeSessionProvider).valueOrNull;
    final uid = _ref.read(currentUserIdProvider);
    final storeId = _ref.read(currentStoreIdProvider);

    if (session == null || uid == null || storeId == null) {
      return 'Chưa có phiên đo đang hoạt động.';
    }

    // Check max 20 measurements per category
    final allMeasurements = _ref.read(sessionMeasurementsProvider).valueOrNull ?? [];
    final categoryCount = allMeasurements.where((m) => m.category == category && !m.status.isCancelled).length;
    if (categoryCount >= 20) {
      return 'Đã đạt tối đa 20 lần đo cho mục ${category.label}.';
    }

    // Order code duplicate check in the same session
    if (category == PerformanceCategory.order) {
      if (orderCode == null || orderCode.trim().isEmpty) {
        return 'Vui lòng nhập mã đơn hàng.';
      }
      final cleanCode = orderCode.trim();
      final hasDuplicate = allMeasurements.any(
        (m) => m.category == PerformanceCategory.order &&
               !m.status.isCancelled &&
               m.orderCode?.trim() == cleanCode,
      );
      if (hasDuplicate) {
        return 'Mã đơn này đã tồn tại trong phiên đo.';
      }
    }

    // Tự động gán nhân sự bộ phận từ session nếu chưa có staffName
    String? resolvedStaff = staffName?.trim().isNotEmpty == true ? staffName!.trim() : null;
    if (resolvedStaff == null) {
      final tag = category == PerformanceCategory.drink
          ? '(Nước)'
          : (category == PerformanceCategory.cake ? '(Bánh)' : '(Phục vụ)');
      final altTag = category == PerformanceCategory.drink
          ? '(dr)'
          : (category == PerformanceCategory.cake ? '(ck)' : '(lo)');

      final deptStaff = session.employeeNames
          .where((n) => n.contains(tag) || n.toLowerCase().contains(altTag))
          .map((n) => n.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim())
          .where((n) => n.isNotEmpty)
          .toList();

      if (deptStaff.isNotEmpty) {
        resolvedStaff = deptStaff.join(', ');
      } else if (category == PerformanceCategory.order && session.managerOnDutyName.isNotEmpty) {
        resolvedStaff = session.managerOnDutyName;
      }
    }

    final newMeasurement = MeasurementModel(
      id: _uuid.v4(),
      sessionId: session.id,
      storeId: storeId,
      userId: uid,
      category: category,
      quantity: quantity < 1 ? 1 : quantity,
      orderCode: orderCode?.trim(),
      staffName: resolvedStaff,
      durationSeconds: 0,
      startedAt: DateTime.now(),
      status: MeasurementStatus.running,
      createdAt: DateTime.now(),
    );

    // Update in-memory active list
    final updatedList = List<MeasurementModel>.from(state.activeTimers)..add(newMeasurement);
    state = state.copyWith(activeTimers: updatedList);

    // Save local and Firestore
    await _persistLocalTimers();
    await _ref.read(performanceRepositoryProvider).addMeasurement(newMeasurement);

    return null; // Success
  }

  /// Pause an active running timer
  Future<void> pauseTimer(String measurementId) async {
    final idx = state.activeTimers.indexWhere((m) => m.id == measurementId);
    if (idx == -1) return;

    final timer = state.activeTimers[idx];
    if (timer.status != MeasurementStatus.running) return;

    final now = DateTime.now();
    final elapsed = timer.elapsedSeconds;

    final updated = timer.copyWith(
      status: MeasurementStatus.paused,
      pausedAt: now,
      durationSeconds: elapsed,
    );

    final list = List<MeasurementModel>.from(state.activeTimers);
    list[idx] = updated;
    state = state.copyWith(activeTimers: list);

    await _persistLocalTimers();
    await _ref.read(performanceRepositoryProvider).updateMeasurement(updated);
  }

  /// Resume a paused timer
  Future<void> resumeTimer(String measurementId) async {
    final idx = state.activeTimers.indexWhere((m) => m.id == measurementId);
    if (idx == -1) return;

    final timer = state.activeTimers[idx];
    if (timer.status != MeasurementStatus.paused) return;

    final now = DateTime.now();
    var addPausedSecs = 0;
    if (timer.pausedAt != null) {
      addPausedSecs = now.difference(timer.pausedAt!).inSeconds;
      if (addPausedSecs < 0) addPausedSecs = 0;
    }

    final updated = timer.copyWith(
      status: MeasurementStatus.running,
      pausedAt: null,
      totalPausedSeconds: timer.totalPausedSeconds + addPausedSecs,
    );

    final list = List<MeasurementModel>.from(state.activeTimers);
    list[idx] = updated;
    state = state.copyWith(activeTimers: list);

    await _persistLocalTimers();
    await _ref.read(performanceRepositoryProvider).updateMeasurement(updated);
  }

  /// Complete a timer
  Future<void> completeTimer(String measurementId) async {
    final idx = state.activeTimers.indexWhere((m) => m.id == measurementId);
    if (idx == -1) return;

    final timer = state.activeTimers[idx];
    final finalSeconds = timer.elapsedSeconds;
    final now = DateTime.now();

    final updated = timer.copyWith(
      status: MeasurementStatus.completed,
      durationSeconds: finalSeconds,
      completedAt: now,
    );

    // Remove from active list
    final list = List<MeasurementModel>.from(state.activeTimers)..removeAt(idx);
    state = state.copyWith(activeTimers: list);

    await _persistLocalTimers();
    await _ref.read(performanceRepositoryProvider).updateMeasurement(updated);

    // Recalculate session summary
    _updateSessionSummaryAfterMeasurement();
  }

  /// Cancel an active timer
  Future<void> cancelTimer(String measurementId) async {
    final idx = state.activeTimers.indexWhere((m) => m.id == measurementId);
    if (idx != -1) {
      final list = List<MeasurementModel>.from(state.activeTimers)..removeAt(idx);
      state = state.copyWith(activeTimers: list);
      await _persistLocalTimers();
    }

    final session = _ref.read(activeSessionProvider).valueOrNull;
    if (session != null) {
      await _ref.read(performanceRepositoryProvider).cancelMeasurement(session.id, measurementId);
    }
  }

  void _updateSessionSummaryAfterMeasurement() async {
    final session = _ref.read(activeSessionProvider).valueOrNull;
    if (session == null) return;

    final measurements = await _ref.read(performanceRepositoryProvider).watchMeasurements(session.id).first;
    final completed = measurements.where((m) => m.status == MeasurementStatus.completed).toList();

    final drinks = completed.where((m) => m.category == PerformanceCategory.drink).toList();
    final cakes = completed.where((m) => m.category == PerformanceCategory.cake).toList();
    final orders = completed.where((m) => m.category == PerformanceCategory.order).toList();

    final drinkTotalQty = drinks.fold<int>(0, (sum, m) => sum + m.quantity);
    final drinkTotalSec = drinks.fold<int>(0, (sum, m) => sum + m.durationSeconds);

    final cakeTotalQty = cakes.fold<int>(0, (sum, m) => sum + m.quantity);
    final cakeTotalSec = cakes.fold<int>(0, (sum, m) => sum + m.durationSeconds);

    final orderTotalSec = orders.fold<int>(0, (sum, m) => sum + m.durationSeconds);

    await _ref.read(performanceRepositoryProvider).updateSessionSummary(
      sessionId: session.id,
      drinkCount: drinks.length,
      drinkTotalQuantity: drinkTotalQty,
      drinkTotalSeconds: drinkTotalSec,
      cakeCount: cakes.length,
      cakeTotalQuantity: cakeTotalQty,
      cakeTotalSeconds: cakeTotalSec,
      orderCount: orders.length,
      orderTotalSeconds: orderTotalSec,
    );
  }

  /// Sync active timers from Firestore when session is loaded
  void syncFromFirestore(List<MeasurementModel> firestoreMeasurements) {
    final active = firestoreMeasurements.where((m) => m.status.isActive).toList();
    state = state.copyWith(activeTimers: active);
    _persistLocalTimers();
  }

  Future<void> _persistLocalTimers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.activeTimers.map((m) {
        final json = m.toJson();
        // Convert Timestamp to ISO string for JSON serialization
        json['startedAt'] = m.startedAt.toIso8601String();
        if (m.pausedAt != null) json['pausedAt'] = m.pausedAt!.toIso8601String();
        if (m.completedAt != null) json['completedAt'] = m.completedAt!.toIso8601String();
        json['createdAt'] = m.createdAt.toIso8601String();
        return json;
      }).toList();
      await prefs.setString(_localTimersKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> _restoreLocalTimers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localTimersKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        final list = decoded.map((e) => MeasurementModel.fromJson(Map<String, dynamic>.from(e))).toList();
        final activeOnly = list.where((m) => m.status.isActive).toList();
        state = state.copyWith(activeTimers: activeOnly);
      }
    } catch (_) {}
  }

  Future<void> clearAllTimers() async {
    state = state.copyWith(activeTimers: const []);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localTimersKey);
    } catch (_) {}
  }
}

final performanceTimerProvider =
    StateNotifierProvider<PerformanceTimerNotifier, PerformanceTimerState>((ref) {
  return PerformanceTimerNotifier(ref);
});
