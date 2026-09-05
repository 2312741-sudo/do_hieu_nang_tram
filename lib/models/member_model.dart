import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole {
  owner,
  manager1,
  manager2,
  legacyManager,
  employee,
}

enum MemberStatus { pending, active, kicked }

enum EmployeeType { fulltime, parttime }

extension UserRoleExtension on UserRole {
  bool get isOwner => this == UserRole.owner;
  bool get isManager1 => this == UserRole.manager1;
  bool get isManager2 => this == UserRole.manager2;
  bool get isLegacyManager => this == UserRole.legacyManager;
  bool get isManager =>
      this == UserRole.manager1 ||
      this == UserRole.manager2 ||
      this == UserRole.legacyManager;
  bool get isEmployee => this == UserRole.employee;

  String get label {
    switch (this) {
      case UserRole.owner:
        return 'Chủ cửa hàng';
      case UserRole.manager1:
      case UserRole.manager2:
      case UserRole.legacyManager:
        return 'Quản lý';
      case UserRole.employee:
        return 'Nhân viên';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.owner:
        return 'Chủ';
      case UserRole.manager1:
      case UserRole.manager2:
      case UserRole.legacyManager:
        return 'Quản lý';
      case UserRole.employee:
        return 'Nhân viên';
    }
  }

  String get description {
    switch (this) {
      case UserRole.owner:
        return 'Toàn quyền quản trị cửa hàng, cài đặt, phân vai trò & tính lương.';
      case UserRole.manager1:
      case UserRole.manager2:
      case UserRole.legacyManager:
        return 'Toàn quyền đo hiệu năng, quản lý phiên làm việc, lịch làm và xem báo cáo.';
      case UserRole.employee:
        return 'Nhân viên chấm công, tham gia ca làm việc và xem thông tin cá nhân.';
    }
  }

  String get value {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.manager1:
        return 'manager_1';
      case UserRole.manager2:
        return 'manager_2';
      case UserRole.legacyManager:
        return 'manager';
      case UserRole.employee:
        return 'employee';
    }
  }

  static UserRole fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return UserRole.employee;
    }
    final clean = value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    switch (clean) {
      case 'owner':
      case 'role_owner':
      case 'chu':
      case 'chu_cua_hang':
      case 'chủ':
      case 'chủ_cửa_hàng':
      case 'admin':
      case 'administrator':
        return UserRole.owner;
      case 'manager_1':
      case 'manager1':
      case 'role_manager_1':
      case 'role_manager1':
      case 'ql1':
      case 'ql_1':
      case 'qly1':
      case 'qly_1':
      case 'quan_ly_1':
      case 'quanly1':
      case 'quanly_1':
      case 'quản_lý_1':
      case 'quan_ly_cap_1':
      case 'qly_cap_1':
        return UserRole.manager1;
      case 'manager_2':
      case 'manager2':
      case 'role_manager_2':
      case 'role_manager2':
      case 'ql2':
      case 'ql_2':
      case 'qly2':
      case 'qly_2':
      case 'quan_ly_2':
      case 'quanly2':
      case 'quanly_2':
      case 'quản_lý_2':
      case 'quan_ly_cap_2':
      case 'qly_cap_2':
        return UserRole.manager2;
      case 'manager':
      case 'role_manager':
      case 'ql':
      case 'qly':
      case 'role_qly':
      case 'quan_ly':
      case 'quanly':
      case 'quản_lý':
      case 'legacy_manager':
      case 'legacymanager':
      case 'management':
        return UserRole.legacyManager;
      case 'employee':
      case 'role_employee':
      case 'staff':
      case 'role_staff':
      case 'nhan_vien':
      case 'nhanvien':
      case 'nhân_viên':
      case 'nv':
      case 'cashier':
      case 'role_cashier':
      case 'kitchen':
      case 'role_kitchen':
      default:
        return UserRole.employee;
    }
  }
}

extension MemberStatusExtension on MemberStatus {
  String get label {
    switch (this) {
      case MemberStatus.pending:
        return 'Chờ duyệt';
      case MemberStatus.active:
        return 'Hoạt động';
      case MemberStatus.kicked:
        return 'Đã xóa';
    }
  }

  String get value {
    switch (this) {
      case MemberStatus.pending:
        return 'pending';
      case MemberStatus.active:
        return 'active';
      case MemberStatus.kicked:
        return 'kicked';
    }
  }

  static MemberStatus fromString(String? value) {
    switch (value) {
      case 'active':
        return MemberStatus.active;
      case 'kicked':
        return MemberStatus.kicked;
      case 'pending':
      default:
        return MemberStatus.pending;
    }
  }
}

extension EmployeeTypeExtension on EmployeeType {
  String get label {
    switch (this) {
      case EmployeeType.fulltime:
        return 'Toàn thời gian';
      case EmployeeType.parttime:
        return 'Bán thời gian';
    }
  }

  String get shortLabel {
    switch (this) {
      case EmployeeType.fulltime:
        return 'Full-time';
      case EmployeeType.parttime:
        return 'Part-time';
    }
  }

  String get value {
    switch (this) {
      case EmployeeType.fulltime:
        return 'fulltime';
      case EmployeeType.parttime:
        return 'parttime';
    }
  }

  static EmployeeType fromString(String? value) {
    switch (value) {
      case 'parttime':
        return EmployeeType.parttime;
      case 'fulltime':
      default:
        return EmployeeType.fulltime;
    }
  }
}

class MemberModel extends Equatable {
  final String userId;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final MemberStatus status;
  final EmployeeType employeeType;
  final double baseMonthlySalary; // fulltime: monthly salary in VND (thousands)
  final double baseHourlyRate; // parttime: per hour in VND (thousands)
  final double standardHoursPerMonth; // default 208
  final DateTime joinedAt;
  final String? employeeCode;
  final String? department; // Department ID (from store.departments)
  final DateTime? birthday;

  const MemberModel({
    required this.userId,
    required this.name,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.status,
    required this.employeeType,
    this.baseMonthlySalary = 0,
    this.baseHourlyRate = 0,
    this.standardHoursPerMonth = 208,
    required this.joinedAt,
    this.employeeCode,
    this.department,
    this.birthday,
  });

  // Convenience getters
  bool get isOwner => role == UserRole.owner;
  bool get isManager1 => role == UserRole.manager1 || role == UserRole.legacyManager;
  bool get isManager2 => role == UserRole.manager2;
  bool get isManager => isManager1 || isManager2;
  bool get isLegacyManager => role == UserRole.legacyManager;
  bool get isEmployee => role == UserRole.employee;
  bool get isActive => status == MemberStatus.active;
  bool get isPending => status == MemberStatus.pending;
  bool get isKicked => status == MemberStatus.kicked;
  bool get isFulltime => employeeType == EmployeeType.fulltime;
  bool get isParttime => employeeType == EmployeeType.parttime;
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory MemberModel.fromJson(Map<String, dynamic> json, String userId) {
    DateTime? parsedBirthday;
    if (json['birthday'] is Timestamp) {
      parsedBirthday = (json['birthday'] as Timestamp).toDate();
    } else if (json['birthday'] != null) {
      parsedBirthday = DateTime.tryParse(json['birthday'].toString());
    }

    final rawRole = json['role'] ??
        json['roleId'] ??
        json['userRole'] ??
        json['position'] ??
        json['roleName'] ??
        json['type'];

    final actualUserId = json['userId']?.toString() ??
        json['id']?.toString() ??
        json['uid']?.toString() ??
        userId;

    return MemberModel(
      userId: actualUserId,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: UserRoleExtension.fromString(rawRole?.toString()),
      status: MemberStatusExtension.fromString(json['status']?.toString()),
      employeeType:
          EmployeeTypeExtension.fromString(json['employeeType']?.toString()),
      baseMonthlySalary:
          (json['baseMonthlySalary'] as num?)?.toDouble() ?? 0.0,
      baseHourlyRate: (json['baseHourlyRate'] as num?)?.toDouble() ?? 0.0,
      standardHoursPerMonth:
          (json['standardHoursPerMonth'] as num?)?.toDouble() ?? 208.0,
      joinedAt: json['joinedAt'] is Timestamp
          ? (json['joinedAt'] as Timestamp).toDate().toUtc()
          : DateTime.tryParse(json['joinedAt'] as String? ?? '') ??
              DateTime.now().toUtc(),
      employeeCode: json['employeeCode'] as String?,
      department: json['department'] as String?,
      birthday: parsedBirthday,
    );
  }

  factory MemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberModel.fromJson(data, doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'role': role.value,
      'status': status.value,
      'employeeType': employeeType.value,
      'baseMonthlySalary': baseMonthlySalary,
      'baseHourlyRate': baseHourlyRate,
      'standardHoursPerMonth': standardHoursPerMonth,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'employeeCode': employeeCode,
      'department': department,
      if (birthday != null) 'birthday': birthday!.toIso8601String(),
    };
  }

  MemberModel copyWith({
    String? userId,
    String? name,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    MemberStatus? status,
    EmployeeType? employeeType,
    double? baseMonthlySalary,
    double? baseHourlyRate,
    double? standardHoursPerMonth,
    DateTime? joinedAt,
    String? employeeCode,
    String? department,
    DateTime? birthday,
    bool clearPhone = false,
    bool clearAvatarUrl = false,
    bool clearDepartment = false,
    bool clearBirthday = false,
  }) {
    return MemberModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: clearPhone ? null : (phone ?? this.phone),
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      role: role ?? this.role,
      status: status ?? this.status,
      employeeType: employeeType ?? this.employeeType,
      baseMonthlySalary: baseMonthlySalary ?? this.baseMonthlySalary,
      baseHourlyRate: baseHourlyRate ?? this.baseHourlyRate,
      standardHoursPerMonth:
          standardHoursPerMonth ?? this.standardHoursPerMonth,
      joinedAt: joinedAt ?? this.joinedAt,
      employeeCode: employeeCode ?? this.employeeCode,
      department: clearDepartment ? null : (department ?? this.department),
      birthday: clearBirthday ? null : (birthday ?? this.birthday),
    );
  }

  @override
  List<Object?> get props => [
        userId,
        name,
        phone,
        avatarUrl,
        role,
        status,
        employeeType,
        baseMonthlySalary,
        baseHourlyRate,
        standardHoursPerMonth,
        joinedAt,
        employeeCode,
        department,
        birthday,
      ];

  @override
  String toString() =>
      'MemberModel(userId: $userId, name: $name, role: ${role.value}, status: ${status.value})';
}
