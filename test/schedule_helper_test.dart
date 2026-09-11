import 'package:flutter_test/flutter_test.dart';
import 'package:do_hieu_nang_tram/core/utils/schedule_helper.dart';
import 'package:do_hieu_nang_tram/models/member_model.dart';
import 'package:do_hieu_nang_tram/models/schedule_model.dart';
import 'package:do_hieu_nang_tram/models/store_model.dart';

void main() {
  group('ScheduleHelper - Date & Key Calculations', () {
    test('getWeekStartString returns correct Monday date', () {
      // 2026-09-11 is a Friday -> Monday of that week is 2026-09-07
      final friday = DateTime(2026, 9, 11, 14, 30);
      expect(ScheduleHelper.getWeekStartString(friday), '2026-09-07');

      // 2026-09-07 is Monday -> should return 2026-09-07
      final monday = DateTime(2026, 9, 7, 8, 0);
      expect(ScheduleHelper.getWeekStartString(monday), '2026-09-07');

      // 2026-09-13 is Sunday -> Monday of that week is 2026-09-07
      final sunday = DateTime(2026, 9, 13, 23, 59);
      expect(ScheduleHelper.getWeekStartString(sunday), '2026-09-07');
    });

    test('getDayKey maps weekday integers to correct day strings', () {
      expect(ScheduleHelper.getDayKey(1), 'monday');
      expect(ScheduleHelper.getDayKey(2), 'tuesday');
      expect(ScheduleHelper.getDayKey(3), 'wednesday');
      expect(ScheduleHelper.getDayKey(4), 'thursday');
      expect(ScheduleHelper.getDayKey(5), 'friday');
      expect(ScheduleHelper.getDayKey(6), 'saturday');
      expect(ScheduleHelper.getDayKey(7), 'sunday');
    });
  });

  group('ScheduleHelper - Shift & Department Parsing', () {
    test('ParsedShiftEntry parses pipe delimited strings', () {
      final entry1 = ParsedShiftEntry.parse('ca1|dr');
      expect(entry1.shiftId, 'ca1');
      expect(entry1.deptIdentifier, 'dr');

      final entry2 = ParsedShiftEntry.parse('morning|ck');
      expect(entry2.shiftId, 'morning');
      expect(entry2.deptIdentifier, 'ck');

      final entry3 = ParsedShiftEntry.parse('ca2|lo');
      expect(entry3.shiftId, 'ca2');
      expect(entry3.deptIdentifier, 'lo');

      final entry4 = ParsedShiftEntry.parse('dr');
      expect(entry4.shiftId, '');
      expect(entry4.deptIdentifier, 'dr');

      final entry5 = ParsedShiftEntry.parse('ca1');
      expect(entry5.shiftId, 'ca1');
      expect(entry5.deptIdentifier, '');
    });

    test('classifyDepartment correctly classifies dr, ck, lo', () {
      expect(ScheduleHelper.classifyDepartment(deptIdentifier: 'dr'), DepartmentCategory.drink);
      expect(ScheduleHelper.classifyDepartment(deptIdentifier: 'drink'), DepartmentCategory.drink);
      expect(ScheduleHelper.classifyDepartment(deptIdentifier: 'nuoc'), DepartmentCategory.drink);

      expect(ScheduleHelper.classifyDepartment(deptIdentifier: 'ck'), DepartmentCategory.cake);
      expect(ScheduleHelper.classifyDepartment(deptIdentifier: 'cake'), DepartmentCategory.cake);
      expect(ScheduleHelper.classifyDepartment(deptIdentifier: 'banh'), DepartmentCategory.cake);

      expect(ScheduleHelper.classifyDepartment(deptIdentifier: 'lo'), DepartmentCategory.service);
      expect(ScheduleHelper.classifyDepartment(deptIdentifier: 'lobby'), DepartmentCategory.service);
      expect(ScheduleHelper.classifyDepartment(deptIdentifier: 'service'), DepartmentCategory.service);
      expect(ScheduleHelper.classifyDepartment(deptIdentifier: 'phuc_vu'), DepartmentCategory.service);
    });

    test('classifyDepartment uses store department definitions and member fallback', () {
      final store = StoreModel(
        id: 'store_1',
        name: 'Trạm Test',
        code: 'TRAM01',
        ownerId: 'owner_1',
        createdAt: DateTime(2026, 1, 1),
        departments: [
          DepartmentDefinition(id: 'd1', name: 'Khu pha chế nước', shortName: 'DR'),
          DepartmentDefinition(id: 'd2', name: 'Bếp bánh ngọt', shortName: 'CK'),
          DepartmentDefinition(id: 'd3', name: 'Sảnh phục vụ', shortName: 'LO'),
        ],
      );

      expect(ScheduleHelper.classifyDepartment(deptIdentifier: 'd1', store: store), DepartmentCategory.drink);
      expect(ScheduleHelper.classifyDepartment(deptIdentifier: 'd2', store: store), DepartmentCategory.cake);
      expect(ScheduleHelper.classifyDepartment(deptIdentifier: 'd3', store: store), DepartmentCategory.service);

      // Fallback from member department ID
      expect(ScheduleHelper.classifyDepartment(memberDeptId: 'd1', store: store), DepartmentCategory.drink);
      expect(ScheduleHelper.classifyDepartment(memberDeptId: 'ck'), DepartmentCategory.cake);
      expect(ScheduleHelper.classifyDepartment(memberDeptId: 'lo'), DepartmentCategory.service);
    });
  });

  group('ScheduleHelper - Active Shift Detection', () {
    const shifts = [
      ShiftDefinition(id: 'morning', name: 'Ca sáng', startHour: 6, startMinute: 0, endHour: 14, endMinute: 0),
      ShiftDefinition(id: 'afternoon', name: 'Ca chiều', startHour: 14, startMinute: 0, endHour: 22, endMinute: 0),
      ShiftDefinition(id: 'night', name: 'Ca đêm', startHour: 22, startMinute: 0, endHour: 6, endMinute: 0),
    ];

    test('detects daytime active shift', () {
      final morningTime = DateTime(2026, 9, 11, 10, 30);
      final active1 = ScheduleHelper.findActiveShift(morningTime, shifts);
      expect(active1?.id, 'morning');

      final afternoonTime = DateTime(2026, 9, 11, 15, 0);
      final active2 = ScheduleHelper.findActiveShift(afternoonTime, shifts);
      expect(active2?.id, 'afternoon');
    });

    test('detects overnight active shift', () {
      final lateNightTime = DateTime(2026, 9, 11, 23, 15);
      final active1 = ScheduleHelper.findActiveShift(lateNightTime, shifts);
      expect(active1?.id, 'night');

      final earlyMorningTime = DateTime(2026, 9, 11, 3, 45);
      final active2 = ScheduleHelper.findActiveShift(earlyMorningTime, shifts);
      expect(active2?.id, 'night');
    });
  });

  group('ScheduleHelper - resolveTodaySchedule Integration', () {
    test('resolves personnel assignments and allows managers to be part of departments', () {
      final now = DateTime(2026, 9, 11, 9, 0); // Friday, Ca sáng (06:00 - 14:00)

      final store = StoreModel(
        id: 'store_1',
        name: 'Trạm Test',
        code: 'TRAM01',
        ownerId: 'owner_1',
        createdAt: DateTime(2026, 1, 1),
        customShifts: [
          ShiftDefinition(id: 'ca1', name: 'Ca 1', startHour: 6, startMinute: 0, endHour: 14, endMinute: 0),
          ShiftDefinition(id: 'ca2', name: 'Ca 2', startHour: 14, startMinute: 0, endHour: 22, endMinute: 0),
        ],
      );

      final manager1 = MemberModel(
        userId: 'mgr_1',
        name: 'Quản lý Tuấn (Ca trưởng)',
        role: UserRole.manager1,
        status: MemberStatus.active,
        employeeType: EmployeeType.fulltime,
        baseMonthlySalary: 0,
        baseHourlyRate: 0,
        standardHoursPerMonth: 208,
        joinedAt: DateTime(2026, 1, 1),
      );

      final empDrink = MemberModel(
        userId: 'emp_drink',
        name: 'Nhân viên Nước',
        role: UserRole.employee,
        status: MemberStatus.active,
        employeeType: EmployeeType.fulltime,
        baseMonthlySalary: 0,
        baseHourlyRate: 0,
        standardHoursPerMonth: 208,
        joinedAt: DateTime(2026, 1, 1),
      );

      final empCake = MemberModel(
        userId: 'emp_cake',
        name: 'Nhân viên Bánh',
        role: UserRole.employee,
        status: MemberStatus.active,
        employeeType: EmployeeType.fulltime,
        baseMonthlySalary: 0,
        baseHourlyRate: 0,
        standardHoursPerMonth: 208,
        joinedAt: DateTime(2026, 1, 1),
      );

      final empService = MemberModel(
        userId: 'emp_service',
        name: 'Nhân viên Phục vụ',
        role: UserRole.employee,
        status: MemberStatus.active,
        employeeType: EmployeeType.fulltime,
        baseMonthlySalary: 0,
        baseHourlyRate: 0,
        standardHoursPerMonth: 208,
        joinedAt: DateTime(2026, 1, 1),
      );

      final staff = [manager1, empDrink, empCake, empService];

      // Friday schedule
      final schedule = ScheduleModel(
        id: '2026-09-07',
        storeId: 'store_1',
        weekStart: '2026-09-07',
        shifts: {
          'mgr_1': const DaySchedule(friday: ['ca1|lo']), // Quản lý đứng ca trực sảnh phục vụ
          'emp_drink': const DaySchedule(friday: ['ca1|dr']),
          'emp_cake': const DaySchedule(friday: ['ca1|ck']),
          'emp_service': const DaySchedule(friday: ['ca1|lo']),
        },
      );

      final res = ScheduleHelper.resolveTodaySchedule(
        schedule: schedule,
        store: store,
        availableStaff: staff,
        targetDate: now,
      );

      expect(res.drinkStaff.length, 1);
      expect(res.drinkStaff.first.userId, 'emp_drink');

      expect(res.cakeStaff.length, 1);
      expect(res.cakeStaff.first.userId, 'emp_cake');

      expect(res.serviceStaff.length, 2);
      // Quản lý đứng ca tham gia vận hành tại bộ phận Phục vụ!
      expect(res.serviceStaff.any((m) => m.userId == 'mgr_1'), isTrue);
      expect(res.serviceStaff.any((m) => m.userId == 'emp_service'), isTrue);

      expect(res.activeShift?.id, 'ca1');
    });
  });
}
