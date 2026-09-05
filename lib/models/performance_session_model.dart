import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum SessionStatus {
  active,
  completed,
  cancelled,
}

extension SessionStatusExtension on SessionStatus {
  String get value {
    switch (this) {
      case SessionStatus.active:
        return 'active';
      case SessionStatus.completed:
        return 'completed';
      case SessionStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case SessionStatus.active:
        return 'Đang hoạt động';
      case SessionStatus.completed:
        return 'Đã hoàn thành';
      case SessionStatus.cancelled:
        return 'Đã hủy';
    }
  }

  static SessionStatus fromString(String? val) {
    switch (val) {
      case 'completed':
        return SessionStatus.completed;
      case 'cancelled':
        return SessionStatus.cancelled;
      case 'active':
      default:
        return SessionStatus.active;
    }
  }
}

class PerformanceIncidentModel extends Equatable {
  final String id;
  final String description;
  final String category; // 'Pha chế / Nước', 'Bánh', 'Thiết bị / Máy móc', 'Đổ vỡ / Thất thoát', 'Khách đổi / Hủy', 'Phục vụ', 'Khác'
  final String? staffName;
  final String reportedBy;
  final DateTime timestamp;

  const PerformanceIncidentModel({
    required this.id,
    required this.description,
    this.category = 'Khác',
    this.staffName,
    required this.reportedBy,
    required this.timestamp,
  });

  factory PerformanceIncidentModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return PerformanceIncidentModel(
      id: json['id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Khác',
      staffName: json['staffName'] as String?,
      reportedBy: json['reportedBy'] as String? ?? '',
      timestamp: parseDate(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'category': category,
    'staffName': staffName,
    'reportedBy': reportedBy,
    'timestamp': Timestamp.fromDate(timestamp),
  };

  PerformanceIncidentModel copyWith({
    String? id,
    String? description,
    String? category,
    String? staffName,
    String? reportedBy,
    DateTime? timestamp,
  }) {
    return PerformanceIncidentModel(
      id: id ?? this.id,
      description: description ?? this.description,
      category: category ?? this.category,
      staffName: staffName ?? this.staffName,
      reportedBy: reportedBy ?? this.reportedBy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [id, description, category, staffName, reportedBy, timestamp];
}

class PerformanceSessionModel extends Equatable {
  final String id;
  final String storeId;
  final String storeName;
  final String managerId;
  final String managerName;
  final String managerOnDutyId;
  final String managerOnDutyName;
  final List<String> employeeIds;
  final List<String> employeeNames;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionStatus status;
  final int drinkCount;
  final int drinkTotalQuantity;
  final int drinkTotalSeconds;
  final int cakeCount;
  final int cakeTotalQuantity;
  final int cakeTotalSeconds;
  final int orderCount;
  final int orderTotalSeconds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> formResponses;
  final Map<String, int> standardSnapshot;
  final List<PerformanceIncidentModel> incidents;

  const PerformanceSessionModel({
    required this.id,
    required this.storeId,
    required this.storeName,
    required this.managerId,
    required this.managerName,
    required this.managerOnDutyId,
    required this.managerOnDutyName,
    this.employeeIds = const [],
    this.employeeNames = const [],
    required this.startedAt,
    this.endedAt,
    this.status = SessionStatus.active,
    this.drinkCount = 0,
    this.drinkTotalQuantity = 0,
    this.drinkTotalSeconds = 0,
    this.cakeCount = 0,
    this.cakeTotalQuantity = 0,
    this.cakeTotalSeconds = 0,
    this.orderCount = 0,
    this.orderTotalSeconds = 0,
    required this.createdAt,
    this.updatedAt,
    this.formResponses = const {},
    this.standardSnapshot = const {},
    this.incidents = const [],
  });

  bool get isActive => status == SessionStatus.active;

  int get drinkAverageSeconds =>
      drinkTotalQuantity > 0 ? (drinkTotalSeconds / drinkTotalQuantity).round() : 0;

  int get cakeAverageSeconds =>
      cakeTotalQuantity > 0 ? (cakeTotalSeconds / cakeTotalQuantity).round() : 0;

  int get orderAverageSeconds =>
      orderCount > 0 ? (orderTotalSeconds / orderCount).round() : 0;

  PerformanceSessionModel copyWith({
    String? id,
    String? storeId,
    String? storeName,
    String? managerId,
    String? managerName,
    String? managerOnDutyId,
    String? managerOnDutyName,
    List<String>? employeeIds,
    List<String>? employeeNames,
    DateTime? startedAt,
    DateTime? endedAt,
    SessionStatus? status,
    int? drinkCount,
    int? drinkTotalQuantity,
    int? drinkTotalSeconds,
    int? cakeCount,
    int? cakeTotalQuantity,
    int? cakeTotalSeconds,
    int? orderCount,
    int? orderTotalSeconds,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? formResponses,
    Map<String, int>? standardSnapshot,
    List<PerformanceIncidentModel>? incidents,
  }) {
    return PerformanceSessionModel(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      managerId: managerId ?? this.managerId,
      managerName: managerName ?? this.managerName,
      managerOnDutyId: managerOnDutyId ?? this.managerOnDutyId,
      managerOnDutyName: managerOnDutyName ?? this.managerOnDutyName,
      employeeIds: employeeIds ?? this.employeeIds,
      employeeNames: employeeNames ?? this.employeeNames,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      drinkCount: drinkCount ?? this.drinkCount,
      drinkTotalQuantity: drinkTotalQuantity ?? this.drinkTotalQuantity,
      drinkTotalSeconds: drinkTotalSeconds ?? this.drinkTotalSeconds,
      cakeCount: cakeCount ?? this.cakeCount,
      cakeTotalQuantity: cakeTotalQuantity ?? this.cakeTotalQuantity,
      cakeTotalSeconds: cakeTotalSeconds ?? this.cakeTotalSeconds,
      orderCount: orderCount ?? this.orderCount,
      orderTotalSeconds: orderTotalSeconds ?? this.orderTotalSeconds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      formResponses: formResponses ?? this.formResponses,
      standardSnapshot: standardSnapshot ?? this.standardSnapshot,
      incidents: incidents ?? this.incidents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storeId': storeId,
      'storeName': storeName,
      'managerId': managerId,
      'managerName': managerName,
      'managerOnDutyId': managerOnDutyId,
      'managerOnDutyName': managerOnDutyName,
      'employeeIds': employeeIds,
      'employeeNames': employeeNames,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'status': status.value,
      'drinkCount': drinkCount,
      'drinkTotalQuantity': drinkTotalQuantity,
      'drinkTotalSeconds': drinkTotalSeconds,
      'cakeCount': cakeCount,
      'cakeTotalQuantity': cakeTotalQuantity,
      'cakeTotalSeconds': cakeTotalSeconds,
      'orderCount': orderCount,
      'orderTotalSeconds': orderTotalSeconds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'formResponses': formResponses,
      'standardSnapshot': standardSnapshot,
      'incidents': incidents.map((i) => i.toJson()).toList(),
    };
  }

  factory PerformanceSessionModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawForm = json['formResponses'] as Map<String, dynamic>? ?? {};
    final rawStandards = (json['standardSnapshot'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ) ??
        {};
    final rawIncidents = (json['incidents'] as List<dynamic>?)
            ?.map((item) => PerformanceIncidentModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList() ??
        [];

    return PerformanceSessionModel(
      id: docId ?? json['id'] as String? ?? '',
      storeId: json['storeId'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      managerId: json['managerId'] as String? ?? '',
      managerName: json['managerName'] as String? ?? '',
      managerOnDutyId: json['managerOnDutyId'] as String? ?? '',
      managerOnDutyName: json['managerOnDutyName'] as String? ?? '',
      employeeIds: List<String>.from(json['employeeIds'] ?? []),
      employeeNames: List<String>.from(json['employeeNames'] ?? []),
      startedAt: parseDate(json['startedAt']),
      endedAt: json['endedAt'] != null ? parseDate(json['endedAt']) : null,
      status: SessionStatusExtension.fromString(json['status'] as String?),
      drinkCount: (json['drinkCount'] as num?)?.toInt() ?? 0,
      drinkTotalQuantity: (json['drinkTotalQuantity'] as num?)?.toInt() ?? 0,
      drinkTotalSeconds: (json['drinkTotalSeconds'] as num?)?.toInt() ?? 0,
      cakeCount: (json['cakeCount'] as num?)?.toInt() ?? 0,
      cakeTotalQuantity: (json['cakeTotalQuantity'] as num?)?.toInt() ?? 0,
      cakeTotalSeconds: (json['cakeTotalSeconds'] as num?)?.toInt() ?? 0,
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      orderTotalSeconds: (json['orderTotalSeconds'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? parseDate(json['updatedAt']) : null,
      formResponses: rawForm,
      standardSnapshot: rawStandards,
      incidents: rawIncidents,
    );
  }

  factory PerformanceSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PerformanceSessionModel.fromJson(data, doc.id);
  }

  @override
  List<Object?> get props => [
        id,
        storeId,
        storeName,
        managerId,
        managerName,
        managerOnDutyId,
        managerOnDutyName,
        employeeIds,
        employeeNames,
        startedAt,
        endedAt,
        status,
        drinkCount,
        drinkTotalQuantity,
        drinkTotalSeconds,
        cakeCount,
        cakeTotalQuantity,
        cakeTotalSeconds,
        orderCount,
        orderTotalSeconds,
        createdAt,
        updatedAt,
        formResponses,
        standardSnapshot,
        incidents,
      ];
}
