import 'package:intl/intl.dart';
import '../../models/member_model.dart';
import '../../models/schedule_model.dart';
import '../../models/store_model.dart';

enum DepartmentCategory {
  drink,
  cake,
  service,
  other;

  bool get isDrink => this == DepartmentCategory.drink;
  bool get isCake => this == DepartmentCategory.cake;
  bool get isService => this == DepartmentCategory.service;
}

class ParsedShiftEntry {
  final String raw;
  final String shiftId;
  final String deptIdentifier;

  const ParsedShiftEntry({
    required this.raw,
    required this.shiftId,
    required this.deptIdentifier,
  });

  factory ParsedShiftEntry.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.contains('|')) {
      final parts = trimmed.split('|');
      return ParsedShiftEntry(
        raw: trimmed,
        shiftId: parts[0].trim(),
        deptIdentifier: parts.length > 1 ? parts[1].trim() : '',
      );
    }

    final lower = trimmed.toLowerCase();
    if (lower == 'dr' || lower == 'ck' || lower == 'lo' || lower == 'drink' || lower == 'cake' || lower == 'service' || lower == 'lobby') {
      return ParsedShiftEntry(
        raw: trimmed,
        shiftId: '',
        deptIdentifier: trimmed,
      );
    }

    return ParsedShiftEntry(
      raw: trimmed,
      shiftId: trimmed,
      deptIdentifier: '',
    );
  }
}

class TodayScheduleResolution {
  final List<MemberModel> drinkStaff;
  final List<MemberModel> cakeStaff;
  final List<MemberModel> serviceStaff;
  final List<MemberModel> unassignedStaff;
  final ShiftDefinition? activeShift;
  final List<ShiftDefinition> todayShifts;
  final int totalScheduledToday;
  final String? activeShiftName;

  const TodayScheduleResolution({
    required this.drinkStaff,
    required this.cakeStaff,
    required this.serviceStaff,
    required this.unassignedStaff,
    this.activeShift,
    this.todayShifts = const [],
    this.totalScheduledToday = 0,
    this.activeShiftName,
  });
}

class ScheduleHelper {
  ScheduleHelper._();

  /// Tính chuỗi ngày Thứ Hai đầu tuần định dạng 'yyyy-MM-dd'
  static String getWeekStartString([DateTime? date]) {
    final target = date ?? DateTime.now();
    // In Dart DateTime, Monday is 1, Sunday is 7
    final diff = target.weekday - 1;
    final monday = DateTime(target.year, target.month, target.day).subtract(Duration(days: diff));
    return DateFormat('yyyy-MM-dd').format(monday);
  }

  /// Chuyển weekday (1 = Monday, 7 = Sunday) sang key tiếng Anh trong DaySchedule
  static String getDayKey(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  /// Chuẩn hóa chuỗi (bỏ dấu tiếng Việt, chữ thường, bỏ khoảng trắng thừa)
  static String normalize(String? text) {
    if (text == null) return '';
    var result = text.trim().toLowerCase();
    const withDia = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const noDia = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], noDia[i]);
    }
    return result;
  }

  /// Phân loại bộ phận: dr -> Nước, ck -> Bánh, lo -> Phục vụ
  static DepartmentCategory classifyDepartment({
    String? deptIdentifier,
    StoreModel? store,
    String? memberDeptId,
  }) {
    final cleanId = normalize(deptIdentifier);

    // 1. Kiểm tra trực tiếp short code theo quy ước Trạm
    if (cleanId == 'dr' || cleanId == 'drink' || cleanId == 'nuoc' || cleanId == 'pha_che') {
      return DepartmentCategory.drink;
    }
    if (cleanId == 'ck' || cleanId == 'cake' || cleanId == 'banh' || cleanId == 'bep' || cleanId == 'nuong_banh') {
      return DepartmentCategory.cake;
    }
    if (cleanId == 'lo' || cleanId == 'lobby' || cleanId == 'service' || cleanId == 'phuc_vu' || cleanId == 'sanh') {
      return DepartmentCategory.service;
    }

    // 2. Tra cứu trong store.departments
    if (store != null && store.departments.isNotEmpty) {
      final target = (deptIdentifier != null && deptIdentifier.trim().isNotEmpty)
          ? deptIdentifier.trim()
          : (memberDeptId != null && memberDeptId.trim().isNotEmpty ? memberDeptId.trim() : null);

      if (target != null) {
        final deptDef = store.departments.where((d) =>
            d.id.trim() == target ||
            normalize(d.shortName) == normalize(target) ||
            normalize(d.id) == normalize(target)
        ).firstOrNull;

        if (deptDef != null) {
          final sName = normalize(deptDef.shortName);
          final dName = normalize(deptDef.name);

          if (sName == 'dr' || dName.contains('nuoc') || dName.contains('pha che') || dName.contains('barista') || dName.contains('drink')) {
            return DepartmentCategory.drink;
          }
          if (sName == 'ck' || dName.contains('banh') || dName.contains('nuong') || dName.contains('bep') || dName.contains('cake') || dName.contains('bakery')) {
            return DepartmentCategory.cake;
          }
          if (sName == 'lo' || dName.contains('phuc vu') || dName.contains('sanh') || dName.contains('lobby') || dName.contains('thu ngan') || dName.contains('service')) {
            return DepartmentCategory.service;
          }
        }
      }
    }

    // 3. Fallback kiểm tra memberDeptId nếu ca không có mã bộ phận
    if (memberDeptId != null && memberDeptId.trim().isNotEmpty) {
      final cleanMember = normalize(memberDeptId);
      if (cleanMember == 'dr' || cleanMember == 'drink') return DepartmentCategory.drink;
      if (cleanMember == 'ck' || cleanMember == 'cake') return DepartmentCategory.cake;
      if (cleanMember == 'lo' || cleanMember == 'lobby' || cleanMember == 'service') return DepartmentCategory.service;
    }

    return DepartmentCategory.other;
  }

  /// Xác định ca đang diễn ra tại thời điểm hiện tại
  static ShiftDefinition? findActiveShift(DateTime now, List<ShiftDefinition> customShifts) {
    if (customShifts.isEmpty) return null;
    final nowMinutes = now.hour * 60 + now.minute;

    for (final shift in customShifts) {
      final start = shift.startHour * 60 + shift.startMinute;
      final end = shift.endHour * 60 + shift.endMinute;

      if (start < end) {
        // Ví dụ 06:00 -> 14:00
        if (nowMinutes >= start && nowMinutes < end) {
          return shift;
        }
      } else if (start > end) {
        // Ca qua đêm, ví dụ 22:00 -> 06:00
        if (nowMinutes >= start || nowMinutes < end) {
          return shift;
        }
      } else {
        // start == end: 24h
        return shift;
      }
    }
    return null;
  }

  /// Phân tích và tải nhân sự hôm nay theo ca và bộ phận
  static TodayScheduleResolution resolveTodaySchedule({
    required ScheduleModel schedule,
    required StoreModel store,
    required List<MemberModel> availableStaff,
    DateTime? targetDate,
    String? selectedShiftId, // null: ưu tiên activeShift, 'all': toàn bộ ca hôm nay, hoặc shiftId cụ thể
  }) {
    final now = targetDate ?? DateTime.now();
    final weekday = now.weekday; // 1 = Monday ... 7 = Sunday
    final activeShift = findActiveShift(now, store.customShifts);

    final drinkStaff = <MemberModel>[];
    final cakeStaff = <MemberModel>[];
    final serviceStaff = <MemberModel>[];
    final unassignedStaff = <MemberModel>[];

    // Thu thập tất cả shiftId xuất hiện trong hôm nay
    final detectedShiftIds = <String>{};
    int totalScheduledToday = 0;

    // Map chứa các entry của từng user hôm nay
    final userEntriesToday = <String, List<ParsedShiftEntry>>{};

    for (final entry in schedule.shifts.entries) {
      final userId = entry.key;
      final daySchedule = entry.value;
      final rawShifts = daySchedule.shiftsForDay(weekday);

      if (rawShifts.isNotEmpty) {
        totalScheduledToday++;
        final parsed = rawShifts.map((s) => ParsedShiftEntry.parse(s)).toList();
        userEntriesToday[userId] = parsed;

        for (final p in parsed) {
          if (p.shiftId.isNotEmpty) {
            detectedShiftIds.add(p.shiftId);
          }
        }
      }
    }

    // Danh sách các ca hợp lệ hôm nay (dựa trên customShifts của quán)
    final todayShifts = store.customShifts.where((s) => detectedShiftIds.contains(s.id)).toList();

    // Quyết định shiftId mục tiêu để lọc
    String? targetShiftId;
    if (selectedShiftId == 'all') {
      targetShiftId = null; // lấy tất cả
    } else if (selectedShiftId != null && selectedShiftId.isNotEmpty) {
      targetShiftId = selectedShiftId;
    } else if (activeShift != null && detectedShiftIds.contains(activeShift.id)) {
      // Có ca đang chạy và có nhân viên thuộc ca đó
      targetShiftId = activeShift.id;
    } else {
      // Không có ca đang chạy hoặc không trùng -> lấy tất cả nhân sự hôm nay
      targetShiftId = null;
    }

    // Phân bổ nhân sự vào 3 bộ phận
    for (final member in availableStaff) {
      final entries = userEntriesToday[member.userId];
      if (entries == null || entries.isEmpty) continue;

      // Lọc entry theo targetShiftId nếu có
      final matchingEntries = targetShiftId != null
          ? entries.where((e) => e.shiftId.isEmpty || e.shiftId == targetShiftId).toList()
          : entries;

      if (matchingEntries.isEmpty) continue;

      // Xác định bộ phận của nhân viên từ entry đầu tiên khớp
      DepartmentCategory category = DepartmentCategory.other;
      for (final e in matchingEntries) {
        final cat = classifyDepartment(
          deptIdentifier: e.deptIdentifier,
          store: store,
          memberDeptId: member.department,
        );
        if (cat != DepartmentCategory.other) {
          category = cat;
          break;
        }
      }

      // Nếu vẫn chưa nhận diện được, thử lại với member.department
      if (category == DepartmentCategory.other && member.department != null) {
        category = classifyDepartment(
          store: store,
          memberDeptId: member.department,
        );
      }

      // Gán vào danh sách tương ứng
      switch (category) {
        case DepartmentCategory.drink:
          if (!drinkStaff.any((m) => m.userId == member.userId)) {
            drinkStaff.add(member);
          }
          break;
        case DepartmentCategory.cake:
          if (!cakeStaff.any((m) => m.userId == member.userId)) {
            cakeStaff.add(member);
          }
          break;
        case DepartmentCategory.service:
          if (!serviceStaff.any((m) => m.userId == member.userId)) {
            serviceStaff.add(member);
          }
          break;
        case DepartmentCategory.other:
          // Mặc định nhân viên chưa gán rõ bộ phận được đưa vào Phục vụ (sảnh/thu ngân)
          if (!serviceStaff.any((m) => m.userId == member.userId)) {
            serviceStaff.add(member);
          }
          if (!unassignedStaff.any((m) => m.userId == member.userId)) {
            unassignedStaff.add(member);
          }
          break;
      }
    }

    String? shiftDisplay;
    if (targetShiftId != null) {
      final shift = store.customShifts.where((s) => s.id == targetShiftId).firstOrNull;
      shiftDisplay = shift != null ? '${shift.name} (${shift.timeRange})' : targetShiftId;
    }

    return TodayScheduleResolution(
      drinkStaff: drinkStaff,
      cakeStaff: cakeStaff,
      serviceStaff: serviceStaff,
      unassignedStaff: unassignedStaff,
      activeShift: activeShift,
      todayShifts: todayShifts,
      totalScheduledToday: totalScheduledToday,
      activeShiftName: shiftDisplay,
    );
  }
}
