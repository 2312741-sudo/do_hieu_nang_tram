import 'package:do_hieu_nang_tram/features/session/providers/timer_service.dart';
import 'package:do_hieu_nang_tram/models/measurement_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MeasurementModel measurement({
    required String id,
    required String sessionId,
    required String storeId,
  }) {
    return MeasurementModel(
      id: id,
      sessionId: sessionId,
      storeId: storeId,
      userId: 'user_a',
      category: PerformanceCategory.drink,
      startedAt: DateTime(2026),
      createdAt: DateTime(2026),
    );
  }

  test('active timer merge excludes other stores and sessions', () {
    final localCurrent = measurement(
      id: 'local_current',
      sessionId: 'session_a',
      storeId: 'store_test',
    );
    final remoteCurrent = measurement(
      id: 'remote_current',
      sessionId: 'session_a',
      storeId: 'store_test',
    );

    final result = mergeActiveTimersForSession(
      sessionId: 'session_a',
      storeId: 'store_test',
      localTimers: [
        localCurrent,
        measurement(
          id: 'wrong_store',
          sessionId: 'session_a',
          storeId: 'tram_chanh',
        ),
        measurement(
          id: 'wrong_session',
          sessionId: 'session_b',
          storeId: 'store_test',
        ),
      ],
      remoteMeasurements: [remoteCurrent, localCurrent],
    );

    expect(result.map((timer) => timer.id), [
      'local_current',
      'remote_current',
    ]);
  });

  test('completed remote measurement removes stale local running timer', () {
    final localRunning = measurement(
      id: 'measurement_1',
      sessionId: 'session_a',
      storeId: 'store_test',
    );
    final remoteCompleted = localRunning.copyWith(
      status: MeasurementStatus.completed,
      completedAt: DateTime(2026, 1, 1, 0, 1),
      durationSeconds: 60,
    );

    final result = mergeActiveTimersForSession(
      sessionId: 'session_a',
      storeId: 'store_test',
      localTimers: [localRunning],
      remoteMeasurements: [remoteCompleted],
    );

    expect(result, isEmpty);
  });
}
