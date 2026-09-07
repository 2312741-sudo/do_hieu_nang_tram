import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/guest_measurement_model.dart';
import '../repositories/guest_local_repository.dart';

/// Guest Timer State — mirrors PerformanceTimerState but local-only
class GuestTimerState {
  final List<GuestMeasurementModel> activeTimers;
  final int tick;

  const GuestTimerState({this.activeTimers = const [], this.tick = 0});

  GuestTimerState copyWith({List<GuestMeasurementModel>? activeTimers, int? tick}) {
    return GuestTimerState(
      activeTimers: activeTimers ?? this.activeTimers,
      tick: tick ?? this.tick,
    );
  }
}

/// Guest Timer Engine — local-only, no Firestore sync.
/// Reuses the same timestamp-based approach as PerformanceTimerNotifier.
class GuestTimerNotifier extends StateNotifier<GuestTimerState> {
  final GuestLocalRepository _repo;
  Timer? _ticker;
  final _uuid = const Uuid();

  GuestTimerNotifier(this._repo) : super(const GuestTimerState()) {
    _initTicker();
    _restoreTimers();
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

  Future<void> _restoreTimers() async {
    final timers = await _repo.loadActiveTimers();
    if (timers.isNotEmpty) {
      state = state.copyWith(activeTimers: timers);
    }
  }

  Future<void> _persistTimers() async {
    await _repo.saveActiveTimers(state.activeTimers);
  }

  /// Start a new measurement timer. Returns error message or null on success.
  Future<String?> startTimer({
    required String sessionId,
    required PerformanceCategory category,
    int quantity = 1,
    String? orderCode,
    required List<GuestMeasurementModel> allSessionMeasurements,
  }) async {
    // Max 20 per category
    final categoryCount = allSessionMeasurements
        .where((m) => m.category == category && m.status != MeasurementStatus.cancelled)
        .length;
    if (categoryCount >= 20) {
      return 'Đã đạt tối đa 20 lần đo cho mục ${category.label}.';
    }

    final now = DateTime.now();
    final measurement = GuestMeasurementModel(
      id: _uuid.v4(),
      sessionId: sessionId,
      category: category,
      quantity: quantity < 1 ? 1 : quantity,
      orderCode: orderCode?.trim().isNotEmpty == true ? orderCode!.trim() : null,
      durationSeconds: 0,
      startedAt: now,
      status: MeasurementStatus.running,
      createdAt: now,
    );

    final updated = List<GuestMeasurementModel>.from(state.activeTimers)..add(measurement);
    state = state.copyWith(activeTimers: updated);
    await _persistTimers();
    return null;
  }

  Future<void> pauseTimer(String id) async {
    final idx = state.activeTimers.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    final timer = state.activeTimers[idx];
    if (timer.status != MeasurementStatus.running) return;

    final elapsed = timer.elapsedSeconds;
    final updated = timer.copyWith(
      status: MeasurementStatus.paused,
      pausedAt: DateTime.now(),
      durationSeconds: elapsed,
    );
    final list = List<GuestMeasurementModel>.from(state.activeTimers);
    list[idx] = updated;
    state = state.copyWith(activeTimers: list);
    await _persistTimers();
  }

  Future<void> resumeTimer(String id) async {
    final idx = state.activeTimers.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    final timer = state.activeTimers[idx];
    if (timer.status != MeasurementStatus.paused) return;

    final now = DateTime.now();
    var addPaused = 0;
    if (timer.pausedAt != null) {
      addPaused = now.difference(timer.pausedAt!).inSeconds;
      if (addPaused < 0) addPaused = 0;
    }

    final updated = timer.copyWith(
      status: MeasurementStatus.running,
      pausedAt: null,
      totalPausedSeconds: timer.totalPausedSeconds + addPaused,
    );
    final list = List<GuestMeasurementModel>.from(state.activeTimers);
    list[idx] = updated;
    state = state.copyWith(activeTimers: list);
    await _persistTimers();
  }

  /// Complete a timer — returns the completed measurement
  Future<GuestMeasurementModel?> completeTimer(String id) async {
    final idx = state.activeTimers.indexWhere((m) => m.id == id);
    if (idx == -1) return null;

    final timer = state.activeTimers[idx];
    final finalSeconds = timer.elapsedSeconds;
    final completed = timer.copyWith(
      status: MeasurementStatus.completed,
      durationSeconds: finalSeconds,
      completedAt: DateTime.now(),
    );

    final list = List<GuestMeasurementModel>.from(state.activeTimers)..removeAt(idx);
    state = state.copyWith(activeTimers: list);
    await _persistTimers();
    return completed;
  }

  Future<void> cancelTimer(String id) async {
    final idx = state.activeTimers.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    final list = List<GuestMeasurementModel>.from(state.activeTimers)..removeAt(idx);
    state = state.copyWith(activeTimers: list);
    await _persistTimers();
  }

  Future<void> clearAllTimers() async {
    state = state.copyWith(activeTimers: const []);
    await _repo.clearActiveTimers();
  }
}
