import 'package:flutter_test/flutter_test.dart';
import 'package:do_hieu_nang_tram/core/utils/performance_calculator.dart';
import 'package:do_hieu_nang_tram/features/guest/models/guest_session_model.dart';
import 'package:do_hieu_nang_tram/features/guest/models/guest_measurement_model.dart';

void main() {
  group('Guest Mode - Models and Personnel Tests', () {
    test('GuestPersonnel labels match expected 1-4 format', () {
      expect(GuestPersonnel.managerLabel(0), 'Quản lý 1');
      expect(GuestPersonnel.managerLabel(1), 'Quản lý 2');
      expect(GuestPersonnel.managerLabel(2), 'Quản lý 3');
      expect(GuestPersonnel.managerLabel(3), 'Quản lý 4');

      expect(GuestPersonnel.employeeLabel(0), 'Nhân viên 1');
      expect(GuestPersonnel.employeeLabel(1), 'Nhân viên 2');
      expect(GuestPersonnel.employeeLabel(2), 'Nhân viên 3');
      expect(GuestPersonnel.employeeLabel(3), 'Nhân viên 4');

      final empLabels = GuestPersonnel.employeeLabels([0, 1, 3]);
      expect(empLabels, ['Nhân viên 1', 'Nhân viên 2', 'Nhân viên 4']);
    });

    test('GuestSessionModel JSON serialization and deserialization', () {
      final now = DateTime(2026, 9, 7, 10, 0, 0);
      final ended = DateTime(2026, 9, 7, 11, 30, 0);

      final session = GuestSessionModel(
        id: 'guest_ses_1',
        managerOnDutyIndex: 1, // Quản lý 2
        employeeIndexes: const [0, 2], // Nhân viên 1, Nhân viên 3
        startedAt: now,
        endedAt: ended,
        status: GuestSessionStatus.completed,
        drinkCount: 5,
        drinkTotalQuantity: 10,
        drinkTotalSeconds: 1200,
        cakeCount: 3,
        cakeTotalQuantity: 4,
        cakeTotalSeconds: 800,
        orderCount: 8,
        orderTotalSeconds: 1600,
        createdAt: now,
      );

      expect(session.managerOnDutyLabel, 'Quản lý 2');
      expect(session.employeeLabels, ['Nhân viên 1', 'Nhân viên 3']);
      expect(session.drinkAverageSeconds, 120); // 1200 / 10
      expect(session.cakeAverageSeconds, 200); // 800 / 4
      expect(session.orderAverageSeconds, 200); // 1600 / 8

      final json = session.toJson();
      final restored = GuestSessionModel.fromJson(json);

      expect(restored.id, session.id);
      expect(restored.managerOnDutyIndex, session.managerOnDutyIndex);
      expect(restored.employeeIndexes, session.employeeIndexes);
      expect(restored.status, session.status);
      expect(restored.drinkCount, session.drinkCount);
      expect(restored.drinkTotalQuantity, session.drinkTotalQuantity);
      expect(restored.drinkTotalSeconds, session.drinkTotalSeconds);
      expect(restored.cakeCount, session.cakeCount);
      expect(restored.cakeTotalQuantity, session.cakeTotalQuantity);
      expect(restored.cakeTotalSeconds, session.cakeTotalSeconds);
      expect(restored.orderCount, session.orderCount);
      expect(restored.orderTotalSeconds, session.orderTotalSeconds);
    });

    test('GuestMeasurementModel JSON serialization and elapsed time', () {
      final now = DateTime.now();

      final measurement = GuestMeasurementModel(
        id: 'm_1',
        sessionId: 'guest_ses_1',
        category: PerformanceCategory.drink,
        quantity: 3,
        orderCode: null,
        durationSeconds: 150,
        startedAt: now.subtract(const Duration(seconds: 150)),
        completedAt: now,
        status: MeasurementStatus.completed,
        createdAt: now,
      );

      expect(measurement.elapsedSeconds, 150);
      expect(measurement.secondsPerItem, 50); // 150 / 3

      final json = measurement.toJson();
      final restored = GuestMeasurementModel.fromJson(json);

      expect(restored.id, measurement.id);
      expect(restored.sessionId, measurement.sessionId);
      expect(restored.category, measurement.category);
      expect(restored.quantity, 3);
      expect(restored.durationSeconds, 150);
      expect(restored.status, MeasurementStatus.completed);
    });

    test('GuestSessionModel recomputeSummary accurately calculates averages', () {
      final now = DateTime.now();

      final measurements = [
        GuestMeasurementModel(
          id: 'm1',
          sessionId: 's1',
          category: PerformanceCategory.drink,
          quantity: 2,
          durationSeconds: 200,
          startedAt: now,
          status: MeasurementStatus.completed,
          createdAt: now,
        ),
        GuestMeasurementModel(
          id: 'm2',
          sessionId: 's1',
          category: PerformanceCategory.drink,
          quantity: 3,
          durationSeconds: 300,
          startedAt: now,
          status: MeasurementStatus.completed,
          createdAt: now,
        ),
        GuestMeasurementModel(
          id: 'm3',
          sessionId: 's1',
          category: PerformanceCategory.cake,
          quantity: 1,
          durationSeconds: 180,
          startedAt: now,
          status: MeasurementStatus.completed,
          createdAt: now,
        ),
        GuestMeasurementModel(
          id: 'm4',
          sessionId: 's1',
          category: PerformanceCategory.order,
          quantity: 1,
          durationSeconds: 240,
          startedAt: now,
          status: MeasurementStatus.completed,
          createdAt: now,
        ),
        // Active/cancelled timer should not be included in completed summary
        GuestMeasurementModel(
          id: 'm5',
          sessionId: 's1',
          category: PerformanceCategory.drink,
          quantity: 1,
          durationSeconds: 50,
          startedAt: now,
          status: MeasurementStatus.running,
          createdAt: now,
        ),
      ];

      final session = GuestSessionModel(
        id: 's1',
        managerOnDutyIndex: 0,
        employeeIndexes: const [0, 1],
        startedAt: now,
        createdAt: now,
      );

      final summary = session.recomputeSummary(measurements);

      // Drink: 2 measurements completed, qty = 2+3 = 5, totalSeconds = 200+300 = 500 -> avg = 100s
      expect(summary.drinkCount, 2);
      expect(summary.drinkTotalQuantity, 5);
      expect(summary.drinkTotalSeconds, 500);
      expect(summary.drinkAverageSeconds, 100);

      // Cake: 1 completed, qty = 1, totalSeconds = 180 -> avg = 180s
      expect(summary.cakeCount, 1);
      expect(summary.cakeTotalQuantity, 1);
      expect(summary.cakeTotalSeconds, 180);
      expect(summary.cakeAverageSeconds, 180);

      // Order: 1 completed, totalSeconds = 240 -> avg = 240s
      expect(summary.orderCount, 1);
      expect(summary.orderTotalSeconds, 240);
      expect(summary.orderAverageSeconds, 240);
    });
  });

  group('Section 33 Mandatory Calculation Parity Tests', () {
    test('Order calculation sample from spec', () {
      final orderTimes = [
        '02:15',
        '02:02',
        '04:00',
        '01:15',
        '01:43',
        '02:12',
        '02:07',
        '02:24',
        '04:16',
        '06:14',
        '08:04',
      ];

      final secondsList = orderTimes.map(PerformanceCalculator.parseTimeStringToSeconds).toList();
      final totalSeconds = secondsList.reduce((a, b) => a + b);
      final count = secondsList.length;

      final rounded = PerformanceCalculator.calculateCountAverage(
        totalSeconds: totalSeconds,
        count: count,
      );
      expect(rounded, 199);
      expect(PerformanceCalculator.formatSeconds(rounded), '03:19');
    });

    test('Cake calculation sample from spec', () {
      final cakeTimes = [
        '04:15',
        '04:00',
        '06:30',
        '02:02',
        '05:22',
        '06:00',
        '04:13',
        '06:08',
        '03:30',
        '05:51',
        '04:20',
      ];

      final secondsList = cakeTimes.map(PerformanceCalculator.parseTimeStringToSeconds).toList();
      final totalSeconds = secondsList.reduce((a, b) => a + b);
      final count = secondsList.length;

      final rounded = PerformanceCalculator.calculateWeightedAverage(
        totalSeconds: totalSeconds,
        totalQuantity: count,
      );
      expect(rounded, 285);
      expect(PerformanceCalculator.formatSeconds(rounded), '04:45');
    });
  });
}
