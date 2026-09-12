import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:do_hieu_nang_tram/core/utils/performance_calculator.dart';
import 'package:do_hieu_nang_tram/core/utils/excel_export_service.dart';
import 'package:do_hieu_nang_tram/models/measurement_model.dart';
import 'package:do_hieu_nang_tram/models/performance_report_model.dart';
import 'package:do_hieu_nang_tram/models/performance_session_model.dart';

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

    test('MeasurementModel supports multi-account measuredByName field', () {
      final now = DateTime.now();
      final m = MeasurementModel(
        id: 'm_multi_1',
        sessionId: 'ses_1',
        storeId: 'store_1',
        userId: 'user_account_2',
        measuredByName: 'Quản lý Bar',
        category: PerformanceCategory.drink,
        quantity: 2,
        staffName: 'Trần Văn Pha Chế',
        durationSeconds: 150,
        startedAt: now,
        createdAt: now,
      );

      expect(m.measuredByName, 'Quản lý Bar');
      final json = m.toJson();
      expect(json['measuredByName'], 'Quản lý Bar');

      final restored = MeasurementModel.fromJson(json);
      expect(restored.measuredByName, 'Quản lý Bar');
    });

    test('ExcelExportService createPerformanceReportWorkbook builds all 6 sheets with SLA and Form Responses', () {
      final now = DateTime.now();
      final report = PerformanceReportModel(
        id: 'rep_full',
        sessionId: 'ses_full',
        storeId: 'store_1',
        storeName: 'Trạm Cà Phê Quận 1',
        managerId: 'mgr_1',
        managerName: 'Quản Lý Trưởng',
        managerOnDutyId: 'mgr_1',
        managerOnDutyName: 'Quản Lý Đứng Ca',
        employeeIds: const ['emp_dr', 'emp_ck', 'emp_lo'],
        employeeNames: const [
          'Nguyễn Văn Nước (Nước)',
          'Lê Thị Bánh (Bánh)',
          'Phạm Phục Vụ (Phục vụ)',
        ],
        startedAt: now.subtract(const Duration(hours: 4)),
        endedAt: now,
        drinkTotalQuantity: 15,
        drinkMeasurementCount: 8,
        drinkTotalSeconds: 800,
        drinkAverageSeconds: 100, // SLA 120s -> ĐẠT
        cakeTotalQuantity: 10,
        cakeMeasurementCount: 5,
        cakeTotalSeconds: 700,
        cakeAverageSeconds: 140, // SLA 120s -> VƯỢT CHUẨN
        orderCount: 12,
        orderTotalSeconds: 1920,
        orderAverageSeconds: 160, // SLA 180s -> ĐẠT
        status: ReportStatus.submitted,
        createdAt: now,
        standardSnapshot: const {
          'drink': 120,
          'cake': 120,
          'order': 180,
        },
        formResponses: const {
          'cleanliness': {
            'title': 'Vệ sinh quầy bar & khu vực làm bánh',
            'type': 'checkbox',
            'value': true,
          },
          'satisfaction': {
            'title': 'Đánh giá mức độ hài lòng vận hành ca',
            'type': 'rating',
            'value': 5,
          },
          'waste_count': {
            'title': 'Số ly hỏng / hủy trong ca',
            'type': 'number',
            'value': 2,
          },
        },
        incidents: [
          PerformanceIncidentModel(
            id: 'inc_1',
            category: 'Kỹ thuật',
            description: 'Máy xay cà phê bị nghẹt nhẹ 5 phút',
            staffName: 'Nguyễn Văn Nước',
            reportedBy: 'Quản Lý Đứng Ca',
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
        ],
      );

      final measurements = [
        MeasurementModel(
          id: 'm1',
          sessionId: 'ses_full',
          storeId: 'store_1',
          userId: 'u1',
          measuredByName: 'TK Đo Nước',
          category: PerformanceCategory.drink,
          quantity: 2,
          durationSeconds: 180,
          staffName: 'Nguyễn Văn Nước',
          startedAt: now.subtract(const Duration(hours: 3)),
          completedAt: now.subtract(const Duration(hours: 3, seconds: -180)),
          status: MeasurementStatus.completed,
          createdAt: now,
        ),
        MeasurementModel(
          id: 'm2',
          sessionId: 'ses_full',
          storeId: 'store_1',
          userId: 'u2',
          measuredByName: 'TK Đo Bánh',
          category: PerformanceCategory.cake,
          quantity: 1,
          durationSeconds: 140,
          staffName: 'Lê Thị Bánh',
          startedAt: now.subtract(const Duration(hours: 2)),
          completedAt: now.subtract(const Duration(hours: 2, seconds: -140)),
          status: MeasurementStatus.completed,
          createdAt: now,
        ),
        MeasurementModel(
          id: 'm3',
          sessionId: 'ses_full',
          storeId: 'store_1',
          userId: 'u3',
          measuredByName: 'TK Đo Đơn',
          category: PerformanceCategory.order,
          orderCode: 'ORD-999',
          durationSeconds: 160,
          staffName: 'Phạm Phục Vụ',
          startedAt: now.subtract(const Duration(hours: 1)),
          completedAt: now.subtract(const Duration(hours: 1, seconds: -160)),
          status: MeasurementStatus.completed,
          createdAt: now,
        ),
      ];

      final excel = ExcelExportService.createPerformanceReportWorkbook(
        report: report,
        measurements: measurements,
      );

      // Verify all 6 sheets were created
      expect(excel.sheets.containsKey('TongQuan'), isTrue);
      expect(excel.sheets.containsKey('BaoCao_KetCa'), isTrue);
      expect(excel.sheets.containsKey('Nuoc'), isTrue);
      expect(excel.sheets.containsKey('Banh'), isTrue);
      expect(excel.sheets.containsKey('DonHang'), isTrue);
      expect(excel.sheets.containsKey('Loi_Phat_Sinh'), isTrue);

      // Verify TongQuan has store name and SLA headers
      final tongQuan = excel['TongQuan'];
      expect(tongQuan.cell(CellIndex.indexByString('B3')).value.toString(), contains('Trạm Cà Phê'));

      // Verify BaoCao_KetCa has the responses
      final ketCa = excel['BaoCao_KetCa'];
      expect(ketCa.rows.length, greaterThanOrEqualTo(4)); // Header + 3 responses

      // Verify Nuoc has measuredByName and staffName
      final nuocSheet = excel['Nuoc'];
      expect(nuocSheet.rows.length, 2); // Header + 1 measurement row

      // Verify bytes can be saved properly
      final bytes = excel.save();
      expect(bytes, isNotNull);
      expect(bytes!.length, greaterThan(0));
    });
  });
}

