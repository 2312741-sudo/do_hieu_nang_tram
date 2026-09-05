import 'package:flutter_test/flutter_test.dart';
import 'package:do_hieu_nang_tram/core/utils/performance_calculator.dart';
import 'package:do_hieu_nang_tram/core/utils/excel_export_service.dart';
import 'package:do_hieu_nang_tram/models/measurement_model.dart';
import 'package:do_hieu_nang_tram/models/performance_report_model.dart';

void main() {
  group('PerformanceCalculator Unit Tests', () {
    test('formatSeconds matches expected prompt values', () {
      expect(PerformanceCalculator.formatSeconds(0), '00:00');
      expect(PerformanceCalculator.formatSeconds(4), '00:04');
      expect(PerformanceCalculator.formatSeconds(65), '01:05');
      expect(PerformanceCalculator.formatSeconds(135), '02:15');
      expect(PerformanceCalculator.formatSeconds(484), '08:04');
    });

    test('Section 9 mandatory test calculation: Đơn hàng', () {
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

      expect(totalSeconds, 2192);
      expect(count, 11);

      final avg = totalSeconds / count;
      expect(avg, closeTo(199.2727, 0.001));

      final rounded = PerformanceCalculator.calculateCountAverage(
        totalSeconds: totalSeconds,
        count: count,
      );
      expect(rounded, 199);
      expect(PerformanceCalculator.formatSeconds(rounded), '03:19');
    });

    test('Section 9 mandatory test calculation: Bánh', () {
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

      expect(totalSeconds, 3131);
      expect(count, 11);

      final avg = totalSeconds / count;
      expect(avg, closeTo(284.6363, 0.001));

      final rounded = PerformanceCalculator.calculateWeightedAverage(
        totalSeconds: totalSeconds,
        totalQuantity: count,
      );
      expect(rounded, 285);
      expect(PerformanceCalculator.formatSeconds(rounded), '04:45');
    });

    test('Section 8 weighted average test: Nước', () {
      // Lần 1: 1 nước, 120s
      // Lần 2: 3 nước, 300s
      // Total = 420s, Total qty = 4 -> 105s = 01:45
      const totalSeconds = 120 + 300;
      const totalQuantity = 1 + 3;

      final rounded = PerformanceCalculator.calculateWeightedAverage(
        totalSeconds: totalSeconds,
        totalQuantity: totalQuantity,
      );
      expect(rounded, 105);
      expect(PerformanceCalculator.formatSeconds(rounded), '01:45');
    });

    test('getCategorySequenceNumber accurately indexes measurements per category', () {
      final now = DateTime.now();
      final drink1 = MeasurementModel(
        id: 'd1',
        sessionId: 's1',
        storeId: 'st1',
        userId: 'u1',
        category: PerformanceCategory.drink,
        durationSeconds: 60,
        startedAt: now.add(const Duration(seconds: 1)),
        status: MeasurementStatus.completed,
        createdAt: now,
      );
      final cake1 = MeasurementModel(
        id: 'c1',
        sessionId: 's1',
        storeId: 'st1',
        userId: 'u1',
        category: PerformanceCategory.cake,
        durationSeconds: 120,
        startedAt: now.add(const Duration(seconds: 2)),
        status: MeasurementStatus.running,
        createdAt: now,
      );
      final drink2 = MeasurementModel(
        id: 'd2',
        sessionId: 's1',
        storeId: 'st1',
        userId: 'u1',
        category: PerformanceCategory.drink,
        durationSeconds: 80,
        startedAt: now.add(const Duration(seconds: 3)),
        status: MeasurementStatus.running,
        createdAt: now,
      );

      final all = [drink1, cake1, drink2];

      expect(PerformanceCalculator.getCategorySequenceNumber(drink1, all), 1);
      expect(PerformanceCalculator.getCategorySequenceNumber(cake1, all), 1);
      expect(PerformanceCalculator.getCategorySequenceNumber(drink2, all), 2);
    });

    test('ExcelExportService sanitize handles Vietnamese and special characters', () {
      expect(ExcelExportService.sanitize('Trạm Chanh - CN Quận 1'), 'TRAM_CHANH_-_CN_QUAN_1');
      expect(ExcelExportService.sanitize('Cửa hàng Trà Sữa #12!'), 'CUA_HANG_TRA_SUA_12');
    });

    test('calculateStaffLeaderboard accurately calculates multi-day performance and ranking', () {
      final now = DateTime.now();
      final reports = [
        // Day 1 Session
        PerformanceReportModel(
          id: 'rep_1',
          sessionId: 'ses_1',
          storeId: 'store_1',
          storeName: 'Trạm 1',
          managerId: 'm1',
          managerName: 'Quản lý 1',
          managerOnDutyId: 'm1',
          managerOnDutyName: 'Quản lý 1',
          employeeIds: const ['e1', 'e2'],
          employeeNames: const ['Nguyễn Văn A (Nước)', 'Trần Thị B (Bánh)'],
          startedAt: now.subtract(const Duration(days: 2)),
          endedAt: now.subtract(const Duration(days: 2, hours: -2)),
          drinkTotalQuantity: 10,
          drinkMeasurementCount: 5,
          drinkTotalSeconds: 1000, // 100s per drink (std: 120s -> 120%)
          drinkAverageSeconds: 100,
          cakeTotalQuantity: 10,
          cakeMeasurementCount: 5,
          cakeTotalSeconds: 1500, // 150s per cake (std: 120s -> 80%)
          cakeAverageSeconds: 150,
          orderCount: 10,
          orderTotalSeconds: 1800,
          orderAverageSeconds: 180,
          status: ReportStatus.submitted,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        // Day 2 Session
        PerformanceReportModel(
          id: 'rep_2',
          sessionId: 'ses_2',
          storeId: 'store_1',
          storeName: 'Trạm 1',
          managerId: 'm1',
          managerName: 'Quản lý 1',
          managerOnDutyId: 'm1',
          managerOnDutyName: 'Quản lý 1',
          employeeIds: const ['e1', 'e2'],
          employeeNames: const ['Nguyễn Văn A (Nước)', 'Trần Thị B (Bánh)'],
          startedAt: now.subtract(const Duration(days: 1)),
          endedAt: now.subtract(const Duration(days: 1, hours: -2)),
          drinkTotalQuantity: 10,
          drinkMeasurementCount: 5,
          drinkTotalSeconds: 1000, // 100s per drink
          drinkAverageSeconds: 100,
          cakeTotalQuantity: 10,
          cakeMeasurementCount: 5,
          cakeTotalSeconds: 1200, // 120s per cake (std: 120s -> 100%)
          cakeAverageSeconds: 120,
          orderCount: 10,
          orderTotalSeconds: 1800,
          orderAverageSeconds: 180,
          status: ReportStatus.submitted,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final leaderboard = PerformanceCalculator.calculateStaffLeaderboard(
        reports: reports,
        drinkStandardSeconds: 120,
        cakeStandardSeconds: 120,
      );

      expect(leaderboard.length, 2);

      // Staff A (Nước): 20 drinks, total 2000s -> avg 100s -> std 120s -> 120% efficiency
      final staffA = leaderboard.firstWhere((s) => s.staffName == 'Nguyễn Văn A');
      expect(staffA.sessionCount, 2);
      expect(staffA.drinkQuantity, 20);
      expect(staffA.drinkTotalSeconds, 2000);
      expect(staffA.drinkAverageSeconds, 100);
      expect(staffA.drinkEfficiencyPercent, 120.0);
      expect(staffA.performanceRating, 'Xuất sắc');
      expect(staffA.rank, 1);

      // Staff B (Bánh): 20 cakes, total 2700s -> avg 135s -> std 120s -> ~88.89% efficiency
      final staffB = leaderboard.firstWhere((s) => s.staffName == 'Trần Thị B');
      expect(staffB.sessionCount, 2);
      expect(staffB.cakeQuantity, 20);
      expect(staffB.cakeTotalSeconds, 2700);
      expect(staffB.cakeAverageSeconds, 135);
      expect(staffB.cakeEfficiencyPercent, closeTo(88.88, 0.1));
      expect(staffB.performanceRating, 'Khá');
      expect(staffB.rank, 2);
    });
  });
}

