import 'package:flutter_test/flutter_test.dart';
import 'package:do_hieu_nang_tram/models/member_model.dart';
import 'package:do_hieu_nang_tram/models/measurement_model.dart';
import 'package:do_hieu_nang_tram/models/performance_session_model.dart';
import 'package:do_hieu_nang_tram/models/performance_report_model.dart';

void main() {
  group('MeasurementModel Tests', () {
    test('MeasurementModel accurately computes elapsedSeconds from timestamp', () {
      final now = DateTime.now();
      final started = now.subtract(const Duration(seconds: 135));

      final measurement = MeasurementModel(
        id: 'm1',
        sessionId: 's1',
        storeId: 'store1',
        userId: 'u1',
        category: PerformanceCategory.drink,
        quantity: 3,
        startedAt: started,
        createdAt: started,
      );

      // Should be around 135 seconds
      expect(measurement.elapsedSeconds, inInclusiveRange(134, 136));

      // secondsPerItem: 135 / 3 = 45
      expect(measurement.secondsPerItem, inInclusiveRange(44, 46));
    });

    test('MeasurementModel accounts for totalPausedSeconds', () {
      final now = DateTime.now();
      final started = now.subtract(const Duration(seconds: 100));

      final measurement = MeasurementModel(
        id: 'm2',
        sessionId: 's1',
        storeId: 'store1',
        userId: 'u1',
        category: PerformanceCategory.cake,
        quantity: 1,
        startedAt: started,
        totalPausedSeconds: 20,
        createdAt: started,
      );

      // 100 - 20 = 80
      expect(measurement.elapsedSeconds, inInclusiveRange(79, 81));
    });
  });

  group('PerformanceSessionModel & Personnel Tests', () {
    test('Session preserves personnel snapshot correctly', () {
      final session = PerformanceSessionModel(
        id: 'session_1',
        storeId: 'store_tramchanh',
        storeName: 'TRẠM CHANH',
        managerId: 'mgr_creator',
        managerName: 'Nguyễn Văn A',
        managerOnDutyId: 'mgr_duty_1',
        managerOnDutyName: 'Trần Văn B',
        employeeIds: const ['emp_1', 'emp_2', 'emp_3'],
        employeeNames: const ['Lê Văn C', 'Phạm Văn D', 'Hoàng Văn E'],
        startedAt: DateTime.now(),
        drinkCount: 8,
        drinkTotalQuantity: 12,
        drinkTotalSeconds: 1656,
        cakeCount: 5,
        cakeTotalQuantity: 5,
        cakeTotalSeconds: 1425,
        orderCount: 11,
        orderTotalSeconds: 2192,
        createdAt: DateTime.now(),
      );

      // Verify personnel snapshot
      expect(session.managerOnDutyId, 'mgr_duty_1');
      expect(session.managerOnDutyName, 'Trần Văn B');
      expect(session.employeeIds.length, 3);
      expect(session.employeeNames, ['Lê Văn C', 'Phạm Văn D', 'Hoàng Văn E']);

      // Verify average calculations
      // Drink: 1656 / 12 = 138s
      expect(session.drinkAverageSeconds, 138);

      // Cake: 1425 / 5 = 285s
      expect(session.cakeAverageSeconds, 285);

      // Order: 2192 / 11 = 199.27 -> 199s
      expect(session.orderAverageSeconds, 199);
    });
  });

  group('PerformanceReportModel Tests', () {
    test('Report stores personnel snapshot and status transitions', () {
      final now = DateTime.now();
      final report = PerformanceReportModel(
        id: 'rep_1',
        sessionId: 'session_1',
        storeId: 'store_tramchanh',
        storeName: 'TRẠM CHANH',
        managerId: 'mgr_creator',
        managerName: 'Nguyễn Văn A',
        managerOnDutyId: 'mgr_duty_1',
        managerOnDutyName: 'Trần Văn B',
        employeeIds: const ['emp_1', 'emp_2'],
        employeeNames: const ['Lê Văn C', 'Phạm Văn D'],
        startedAt: now.subtract(const Duration(hours: 4)),
        endedAt: now,
        drinkTotalQuantity: 12,
        drinkMeasurementCount: 8,
        drinkTotalSeconds: 1656,
        drinkAverageSeconds: 138,
        cakeTotalQuantity: 5,
        cakeMeasurementCount: 5,
        cakeTotalSeconds: 1425,
        cakeAverageSeconds: 285,
        orderCount: 11,
        orderTotalSeconds: 2192,
        orderAverageSeconds: 199,
        status: ReportStatus.submitted,
        submittedAt: now,
        createdAt: now,
      );

      expect(report.isSubmitted, true);
      expect(report.isViewed, false);

      final viewedReport = report.copyWith(
        status: ReportStatus.viewed,
        viewedAt: now,
        viewedBy: 'owner_uid',
      );

      expect(viewedReport.isViewed, true);
      expect(viewedReport.viewedBy, 'owner_uid');
      expect(viewedReport.managerOnDutyName, 'Trần Văn B');
      expect(viewedReport.employeeNames.length, 2);
    });
  });

  group('UserRole parsing & label Tests', () {
    test('UserRoleExtension.fromString parses all variations and cases accurately', () {
      expect(UserRoleExtension.fromString('owner'), UserRole.owner);
      expect(UserRoleExtension.fromString('OWNER'), UserRole.owner);
      expect(UserRoleExtension.fromString('ROLE_OWNER'), UserRole.owner);
      expect(UserRoleExtension.fromString('chu_cua_hang'), UserRole.owner);
      expect(UserRoleExtension.fromString('chủ'), UserRole.owner);

      expect(UserRoleExtension.fromString('manager_1'), UserRole.manager1);
      expect(UserRoleExtension.fromString('MANAGER_1'), UserRole.manager1);
      expect(UserRoleExtension.fromString('manager1'), UserRole.manager1);
      expect(UserRoleExtension.fromString('ql1'), UserRole.manager1);
      expect(UserRoleExtension.fromString('qly1'), UserRole.manager1);
      expect(UserRoleExtension.fromString('quan_ly_1'), UserRole.manager1);

      expect(UserRoleExtension.fromString('manager_2'), UserRole.manager2);
      expect(UserRoleExtension.fromString('MANAGER_2'), UserRole.manager2);
      expect(UserRoleExtension.fromString('manager2'), UserRole.manager2);
      expect(UserRoleExtension.fromString('ql2'), UserRole.manager2);
      expect(UserRoleExtension.fromString('qly2'), UserRole.manager2);
      expect(UserRoleExtension.fromString('quan_ly_2'), UserRole.manager2);

      expect(UserRoleExtension.fromString('manager'), UserRole.legacyManager);
      expect(UserRoleExtension.fromString('MANAGER'), UserRole.legacyManager);
      expect(UserRoleExtension.fromString('ROLE_MANAGER'), UserRole.legacyManager);
      expect(UserRoleExtension.fromString('ql'), UserRole.legacyManager);
      expect(UserRoleExtension.fromString('qly'), UserRole.legacyManager);
      expect(UserRoleExtension.fromString('quan_ly'), UserRole.legacyManager);

      expect(UserRoleExtension.fromString('employee'), UserRole.employee);
      expect(UserRoleExtension.fromString('EMPLOYEE'), UserRole.employee);
      expect(UserRoleExtension.fromString('staff'), UserRole.employee);
      expect(UserRoleExtension.fromString('STAFF'), UserRole.employee);
      expect(UserRoleExtension.fromString('nhan_vien'), UserRole.employee);
      expect(UserRoleExtension.fromString('nv'), UserRole.employee);
      expect(UserRoleExtension.fromString(null), UserRole.employee);
    });

    test('UserRole labels and permissions getters behave correctly', () {
      expect(UserRole.owner.label, 'Chủ cửa hàng');
      expect(UserRole.manager1.label, 'Quản lý');
      expect(UserRole.manager2.label, 'Quản lý');
      expect(UserRole.legacyManager.label, 'Quản lý');
      expect(UserRole.employee.label, 'Nhân viên');

      expect(UserRole.manager1.isManager, true);
      expect(UserRole.manager2.isManager, true);
      expect(UserRole.legacyManager.isManager, true);
      expect(UserRole.employee.isManager, false);
      expect(UserRole.owner.isOwner, true);
    });
  });

  group('PerformanceIncidentModel Tests', () {
    test('Incident model serialization and deserialization works correctly', () {
      final now = DateTime.now();
      final incident = PerformanceIncidentModel(
        id: 'inc_1',
        description: 'Máy ép cam bị kẹt 3 phút',
        category: 'Thiết bị / Máy móc',
        staffName: 'Lê Văn C (Nước)',
        reportedBy: 'Nguyễn Văn A',
        timestamp: now,
      );

      final json = incident.toJson();
      expect(json['id'], 'inc_1');
      expect(json['description'], 'Máy ép cam bị kẹt 3 phút');
      expect(json['category'], 'Thiết bị / Máy móc');
      expect(json['staffName'], 'Lê Văn C (Nước)');
      expect(json['reportedBy'], 'Nguyễn Văn A');

      final deserialized = PerformanceIncidentModel.fromJson(json);
      expect(deserialized.id, 'inc_1');
      expect(deserialized.description, 'Máy ép cam bị kẹt 3 phút');
      expect(deserialized.category, 'Thiết bị / Máy móc');
      expect(deserialized.staffName, 'Lê Văn C (Nước)');
      expect(deserialized.reportedBy, 'Nguyễn Văn A');
    });

    test('Session and Report preserve incidents list', () {
      final now = DateTime.now();
      final incident = PerformanceIncidentModel(
        id: 'inc_2',
        description: 'Làm sai size ly nước',
        category: 'Pha chế / Nước',
        staffName: 'Lê Văn C (Nước)',
        reportedBy: 'Nguyễn Văn A',
        timestamp: now,
      );

      final session = PerformanceSessionModel(
        id: 's_inc',
        storeId: 'store_1',
        storeName: 'Trạm Chanh',
        managerId: 'm1',
        managerName: 'Mgr A',
        managerOnDutyId: 'm1',
        managerOnDutyName: 'Mgr A',
        startedAt: now,
        createdAt: now,
        incidents: [incident],
      );

      final sessionJson = session.toJson();
      final deserializedSession = PerformanceSessionModel.fromJson(sessionJson);
      expect(deserializedSession.incidents.length, 1);
      expect(deserializedSession.incidents.first.description, 'Làm sai size ly nước');

      final report = PerformanceReportModel(
        id: 'r_inc',
        sessionId: 's_inc',
        storeId: 'store_1',
        storeName: 'Trạm Chanh',
        managerId: 'm1',
        managerName: 'Mgr A',
        managerOnDutyId: 'm1',
        managerOnDutyName: 'Mgr A',
        startedAt: now,
        endedAt: now,
        createdAt: now,
        incidents: [incident],
      );

      final reportJson = report.toJson();
      final deserializedReport = PerformanceReportModel.fromJson(reportJson);
      expect(deserializedReport.incidents.length, 1);
      expect(deserializedReport.incidents.first.category, 'Pha chế / Nước');
    });
  });
}

