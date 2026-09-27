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
  return ref
      .watch(performanceRepositoryProvider)
      .watchWeekSchedule(storeId, weekStart);
});

/// Active session stream owned by the authenticated user at the selected store.
final activeSessionProvider = StreamProvider<PerformanceSessionModel?>((ref) {
  final storeId = ref.watch(currentStoreIdProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (storeId == null || storeId.isEmpty || userId == null || userId.isEmpty) {
    return Stream.value(null);
  }
  return ref.watch(performanceRepositoryProvider).watchActiveSession(
        storeId: storeId,
        userId: userId,
      );
});

/// Measurements stream for the currently active session
final sessionMeasurementsProvider =
    StreamProvider<List<MeasurementModel>>((ref) {
  final session = ref.watch(activeSessionProvider).valueOrNull;
  if (session == null) return Stream.value([]);
  return ref.watch(performanceRepositoryProvider).watchMeasurements(session.id);
});

List<MeasurementModel> mergeActiveTimersForSession({
  required String sessionId,
  required String storeId,
  required List<MeasurementModel> localTimers,
  required List<MeasurementModel> remoteMeasurements,
}) {
  bool belongsToCurrentSession(MeasurementModel measurement) {
    return measurement.sessionId == sessionId && measurement.storeId == storeId;
  }

  final terminalRemoteIds = remoteMeasurements
      .where((measurement) =>
          belongsToCurrentSession(measurement) && !measurement.status.isActive)
      .map((measurement) => measurement.id)
      .toSet();
  final scopedLocal = localTimers
      .where((measurement) =>
          belongsToCurrentSession(measurement) &&
          measurement.status.isActive &&
          !terminalRemoteIds.contains(measurement.id))
      .toList();
  final localIds = scopedLocal.map((measurement) => measurement.id).toSet();
  final scopedRemote = remoteMeasurements
      .where((measurement) =>
          belongsToCurrentSession(measurement) &&
          measurement.status.isActive &&
          !localIds.contains(measurement.id))
      .toList();

  return [...scopedLocal, ...scopedRemote];
}

/// Active timers that belong to the authenticated user's current session only.
final activeSessionTimersProvider = Provider<List<MeasurementModel>>((ref) {
  final storeId = ref.watch(currentStoreIdProvider);
  final session = ref.watch(activeSessionProvider).valueOrNull;
  if (storeId == null || session == null) return const [];

  return mergeActiveTimersForSession(
    sessionId: session.id,
    storeId: storeId,
    localTimers: ref.watch(performanceTimerProvider).activeTimers,
    remoteMeasurements:
        ref.watch(sessionMeasurementsProvider).valueOrNull ?? const [],
  );
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
  final String? _userId;
  final String? _storeId;
  Timer? _ticker;
  final _uuid = const Uuid();

  PerformanceTimerNotifier(this._ref, this._userId, this._storeId)
      : super(const PerformanceTimerState()) {
    _initTicker();
    _restoreLocalTimers();
    _listenToMeasurements();
  }

  String? get _localTimersKey {
    final userId = _userId;
    final storeId = _storeId;
    if (userId == null ||
        userId.isEmpty ||
        storeId == null ||
        storeId.isEmpty) {
      return null;
    }
    return 'perf_active_timers_v2_${userId}_$storeId';
  }

  void _initTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (state.activeTimers
          .any((t) => t.status == MeasurementStatus.running)) {
        state = state.copyWith(tick: state.tick + 1);
      }
    });
  }

  void _listenToMeasurements() {
    _ref.listen<AsyncValue<List<MeasurementModel>>>(sessionMeasurementsProvider,
        (prev, next) {
      final list = next.valueOrNull;
      if (list != null) {
        syncFromFirestore(list);
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

    if (session == null ||
        uid == null ||
        storeId == null ||
        !session.canResume(storeId: storeId, userId: uid)) {
      return 'Chưa có phiên đo đang hoạt động.';
    }

    // Check max 20 measurements per category
    final allMeasurements =
        _ref.read(sessionMeasurementsProvider).valueOrNull ?? [];
    final categoryCount = allMeasurements
        .where((m) => m.category == category && !m.status.isCancelled)
        .length;
    if (categoryCount >= 20) {
      return 'Đã đạt tối đa 20 lần đo cho mục ${category.label}.';
    }

    // Order code duplicate check — orderCode is now optional (user may enter later on the card).
    if (category == PerformanceCategory.order) {
      if (orderCode != null && orderCode.trim().isNotEmpty) {
        final cleanCode = orderCode.trim();
        final hasDuplicate = allMeasurements.any(
          (m) =>
              m.category == PerformanceCategory.order &&
              !m.status.isCancelled &&
              m.orderCode?.trim() == cleanCode,
        );
        if (hasDuplicate) {
          return 'Mã đơn này đã tồn tại trong phiên đo.';
        }
      }
    }

    // Tự động gán nhân sự bộ phận từ session nếu chưa có staffName
    String? resolvedStaff =
        staffName?.trim().isNotEmpty == true ? staffName!.trim() : null;
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
      } else if (category == PerformanceCategory.order &&
          session.managerOnDutyName.isNotEmpty) {
        resolvedStaff = session.managerOnDutyName;
      }
    }

    final user = _ref.read(currentUserProvider).valueOrNull;
    final measuredByName = user?.name ?? 'Quản lý';

    final newMeasurement = MeasurementModel(
      id: _uuid.v4(),
      sessionId: session.id,
      storeId: storeId,
      userId: uid,
      measuredByName: measuredByName,
      category: category,
      quantity: quantity < 1 ? 1 : quantity,
      orderCode: orderCode?.trim(),
      staffName: resolvedStaff,
      durationSeconds: 0,
      startedAt: DateTime.now(),
      status: MeasurementStatus.running,
      createdAt: DateTime.now(),
    );

    // Add to local state FIRST so that when the Firestore snapshot arrives
    // and syncFromFirestore runs, the timer is already in localIds and won't
    // be added a second time (preventing the duplicate-timer race condition).
    final updatedList = List<MeasurementModel>.from(state.activeTimers)
      ..add(newMeasurement);
    state = state.copyWith(activeTimers: updatedList);
    await _persistLocalTimers();

    try {
      await _ref
          .read(performanceRepositoryProvider)
          .addMeasurement(newMeasurement);
    } catch (error) {
      // Rollback local state if Firestore write failed.
      final rollback = List<MeasurementModel>.from(state.activeTimers)
        ..removeWhere((m) => m.id == newMeasurement.id);
      state = state.copyWith(activeTimers: rollback);
      await _persistLocalTimers();
      return 'Không thể bắt đầu timer vì chưa lưu được lên hệ thống: $error';
    }

    return null; // Success
  }

  /// Pause an active running timer
  Future<String?> pauseTimer(String measurementId) async {
    final idx = state.activeTimers.indexWhere((m) => m.id == measurementId);
    MeasurementModel? timer;
    if (idx != -1) {
      timer = state.activeTimers[idx];
    } else {
      final all = _ref.read(sessionMeasurementsProvider).valueOrNull ?? [];
      timer = all.where((m) => m.id == measurementId).firstOrNull;
    }
    if (timer == null || timer.status != MeasurementStatus.running) {
      return 'Không tìm thấy timer đang chạy để tạm dừng.';
    }

    final now = DateTime.now();
    final elapsed = timer.elapsedSeconds;

    final updated = timer.copyWith(
      status: MeasurementStatus.paused,
      pausedAt: now,
      durationSeconds: elapsed,
    );

    try {
      await _ref.read(performanceRepositoryProvider).updateMeasurement(updated);
    } catch (error) {
      return 'Không thể tạm dừng timer: $error';
    }

    final list = List<MeasurementModel>.from(state.activeTimers);
    if (idx != -1) {
      list[idx] = updated;
    } else {
      list.add(updated);
    }
    state = state.copyWith(activeTimers: list);
    await _persistLocalTimers();
    return null;
  }

  /// Resume a paused timer
  Future<String?> resumeTimer(String measurementId) async {
    final idx = state.activeTimers.indexWhere((m) => m.id == measurementId);
    MeasurementModel? timer;
    if (idx != -1) {
      timer = state.activeTimers[idx];
    } else {
      final all = _ref.read(sessionMeasurementsProvider).valueOrNull ?? [];
      timer = all.where((m) => m.id == measurementId).firstOrNull;
    }
    if (timer == null || timer.status != MeasurementStatus.paused) {
      return 'Không tìm thấy timer đang tạm dừng để tiếp tục.';
    }

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

    try {
      await _ref.read(performanceRepositoryProvider).updateMeasurement(updated);
    } catch (error) {
      return 'Không thể tiếp tục timer: $error';
    }

    final list = List<MeasurementModel>.from(state.activeTimers);
    if (idx != -1) {
      list[idx] = updated;
    } else {
      list.add(updated);
    }
    state = state.copyWith(activeTimers: list);
    await _persistLocalTimers();
    return null;
  }

  /// Complete a timer
  Future<String?> completeTimer(String measurementId) async {
    final idx = state.activeTimers.indexWhere((m) => m.id == measurementId);
    MeasurementModel? timer;
    if (idx != -1) {
      timer = state.activeTimers[idx];
    } else {
      final all = _ref.read(sessionMeasurementsProvider).valueOrNull ?? [];
      timer = all.where((m) => m.id == measurementId).firstOrNull;
    }
    if (timer == null) return 'Không tìm thấy lần đo để hoàn thành.';

    final session = _ref.read(activeSessionProvider).valueOrNull;
    final storeId = _ref.read(currentStoreIdProvider);
    if (session == null ||
        storeId == null ||
        timer.sessionId != session.id ||
        timer.storeId != storeId) {
      return 'Lần đo không thuộc phiên hiện tại.';
    }

    final finalSeconds = timer.elapsedSeconds;
    final now = DateTime.now();

    final updated = timer.copyWith(
      status: MeasurementStatus.completed,
      durationSeconds: finalSeconds,
      completedAt: now,
    );

    try {
      await _ref.read(performanceRepositoryProvider).updateMeasurement(updated);
    } catch (error) {
      return 'Không thể lưu lịch sử lần đo: $error';
    }

    final list = state.activeTimers
        .where((measurement) => measurement.id != measurementId)
        .toList();
    state = state.copyWith(activeTimers: list);
    await _persistLocalTimers();

    try {
      await _updateSessionSummaryAfterMeasurement();
    } catch (error) {
      return 'Đã lưu lần đo nhưng chưa cập nhật được tổng hợp phiên: $error';
    }
    return null;
  }

  /// Cancel an active timer
  Future<String?> cancelTimer(String measurementId) async {
    final session = _ref.read(activeSessionProvider).valueOrNull;
    if (session == null) return 'Không tìm thấy phiên hiện tại.';

    try {
      await _ref
          .read(performanceRepositoryProvider)
          .cancelMeasurement(session.id, measurementId);
    } catch (error) {
      return 'Không thể hủy timer: $error';
    }

    final idx = state.activeTimers.indexWhere((m) => m.id == measurementId);
    if (idx != -1) {
      final list = List<MeasurementModel>.from(state.activeTimers)
        ..removeAt(idx);
      state = state.copyWith(activeTimers: list);
      await _persistLocalTimers();
    }
    return null;
  }

  /// Set the order code on an active order-measurement that was started without one.
  /// Returns an error string on failure, null on success.
  Future<String?> updateOrderCode(
      String measurementId, String orderCode) async {
    final code = orderCode.trim();
    if (code.isEmpty) return 'Vui lòng nhập mã đơn hàng.';

    // Duplicate check across the whole session
    final allMeasurements =
        _ref.read(sessionMeasurementsProvider).valueOrNull ?? [];
    final hasDuplicate = allMeasurements.any(
      (m) =>
          m.id != measurementId &&
          m.category == PerformanceCategory.order &&
          !m.status.isCancelled &&
          m.orderCode?.trim() == code,
    );
    if (hasDuplicate) return 'Mã đơn này đã tồn tại trong phiên đo.';

    // Find the timer in local active state or remote list
    final idx = state.activeTimers.indexWhere((m) => m.id == measurementId);
    MeasurementModel? timer;
    if (idx != -1) {
      timer = state.activeTimers[idx];
    } else {
      timer = allMeasurements
          .where((m) => m.id == measurementId)
          .firstOrNull;
    }
    if (timer == null) return 'Không tìm thấy lần đo.';

    final updated = timer.copyWith(orderCode: code);

    try {
      await _ref
          .read(performanceRepositoryProvider)
          .updateMeasurement(updated);
    } catch (error) {
      return 'Không thể lưu mã đơn: $error';
    }

    // Update local active-timer state so UI refreshes immediately
    if (idx != -1) {
      final list = List<MeasurementModel>.from(state.activeTimers);
      list[idx] = updated;
      state = state.copyWith(activeTimers: list);
      await _persistLocalTimers();
    }
    return null;
  }

  Future<void> _updateSessionSummaryAfterMeasurement() async {
    final session = _ref.read(activeSessionProvider).valueOrNull;
    if (session == null) return;

    final measurements = await _ref
        .read(performanceRepositoryProvider)
        .watchMeasurements(session.id)
        .first;
    final completed = measurements
        .where((m) => m.status == MeasurementStatus.completed)
        .toList();

    final drinks = completed
        .where((m) => m.category == PerformanceCategory.drink)
        .toList();
    final cakes =
        completed.where((m) => m.category == PerformanceCategory.cake).toList();
    final orders = completed
        .where((m) => m.category == PerformanceCategory.order)
        .toList();

    final drinkTotalQty = drinks.fold<int>(0, (sum, m) => sum + m.quantity);
    final drinkTotalSec =
        drinks.fold<int>(0, (sum, m) => sum + m.durationSeconds);

    final cakeTotalQty = cakes.fold<int>(0, (sum, m) => sum + m.quantity);
    final cakeTotalSec =
        cakes.fold<int>(0, (sum, m) => sum + m.durationSeconds);

    final orderTotalSec =
        orders.fold<int>(0, (sum, m) => sum + m.durationSeconds);

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

  /// Sync active timers from Firestore when session is loaded or updated.
  /// Merges remote active timers with locally-running timers to avoid
  /// overwriting timers started locally that haven't yet propagated to Firestore.
  void syncFromFirestore(List<MeasurementModel> firestoreMeasurements) {
    final currentSessionId = _ref.read(activeSessionProvider).valueOrNull?.id;
    if (currentSessionId == null) {
      if (state.activeTimers.isNotEmpty) {
        state = state.copyWith(activeTimers: const []);
        _persistLocalTimers();
      }
      return;
    }

    final currentStoreId = _storeId;
    if (currentStoreId == null) return;
    final merged = mergeActiveTimersForSession(
      sessionId: currentSessionId,
      storeId: currentStoreId,
      localTimers: state.activeTimers,
      remoteMeasurements: firestoreMeasurements,
    );

    final currentIds = state.activeTimers
        .map((m) => '${m.id}_${m.status.value}_${m.totalPausedSeconds}')
        .toSet();
    final mergedIds = merged
        .map((m) => '${m.id}_${m.status.value}_${m.totalPausedSeconds}')
        .toSet();

    if (currentIds.length != mergedIds.length ||
        !currentIds.containsAll(mergedIds)) {
      state = state.copyWith(activeTimers: merged);
      _persistLocalTimers();
    }
  }

  Future<void> _persistLocalTimers() async {
    try {
      final key = _localTimersKey;
      if (key == null) return;
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.activeTimers.map((m) {
        final json = m.toJson();
        // Convert Timestamp to ISO string for JSON serialization
        json['startedAt'] = m.startedAt.toIso8601String();
        if (m.pausedAt != null) {
          json['pausedAt'] = m.pausedAt!.toIso8601String();
        }
        if (m.completedAt != null) {
          json['completedAt'] = m.completedAt!.toIso8601String();
        }
        json['createdAt'] = m.createdAt.toIso8601String();
        return json;
      }).toList();
      await prefs.setString(key, jsonEncode(jsonList));
    } catch (_) {}
  }

  Future<void> _restoreLocalTimers() async {
    try {
      final key = _localTimersKey;
      if (key == null) return;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        final list = decoded
            .map((e) => MeasurementModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final activeSessionId =
            _ref.read(activeSessionProvider).valueOrNull?.id;
        final activeOnly = list
            .where((m) =>
                m.status.isActive &&
                m.storeId == _storeId &&
                (activeSessionId == null || m.sessionId == activeSessionId))
            .toList();
        state = state.copyWith(activeTimers: activeOnly);
      }
    } catch (_) {}
  }

  Future<void> clearAllTimers() async {
    state = state.copyWith(activeTimers: const []);
    try {
      final key = _localTimersKey;
      if (key == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}

final performanceTimerProvider =
    StateNotifierProvider<PerformanceTimerNotifier, PerformanceTimerState>(
        (ref) {
  final userId = ref.watch(currentUserIdProvider);
  final storeId = ref.watch(currentStoreIdProvider);
  return PerformanceTimerNotifier(ref, userId, storeId);
});
