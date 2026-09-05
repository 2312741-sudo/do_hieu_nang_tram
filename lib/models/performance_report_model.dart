import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'performance_session_model.dart';

enum ReportStatus {
  draft,
  submitted,
  viewed,
  archived,
}

extension ReportStatusExtension on ReportStatus {
  String get value {
    switch (this) {
      case ReportStatus.draft:
        return 'draft';
      case ReportStatus.submitted:
        return 'submitted';
      case ReportStatus.viewed:
        return 'viewed';
      case ReportStatus.archived:
        return 'archived';
    }
  }

  String get label {
    switch (this) {
      case ReportStatus.draft:
        return 'Bản nháp';
      case ReportStatus.submitted:
        return 'Chưa xem';
      case ReportStatus.viewed:
        return 'Đã xem';
      case ReportStatus.archived:
        return 'Lưu trữ';
    }
  }

  static ReportStatus fromString(String? val) {
    switch (val) {
      case 'submitted':
        return ReportStatus.submitted;
      case 'viewed':
        return ReportStatus.viewed;
      case 'archived':
        return ReportStatus.archived;
      case 'draft':
      default:
        return ReportStatus.draft;
    }
  }
}

class PerformanceReportModel extends Equatable {
  final String id;
  final String sessionId;
  final String storeId;
  final String storeName;
  final String managerId;
  final String managerName;
  final String managerOnDutyId;
  final String managerOnDutyName;
  final List<String> employeeIds;
  final List<String> employeeNames;
  final DateTime startedAt;
  final DateTime endedAt;
  final int drinkTotalQuantity;
  final int drinkMeasurementCount;
  final int drinkTotalSeconds;
  final int drinkAverageSeconds;
  final int cakeTotalQuantity;
  final int cakeMeasurementCount;
  final int cakeTotalSeconds;
  final int cakeAverageSeconds;
  final int orderCount;
  final int orderTotalSeconds;
  final int orderAverageSeconds;
  final ReportStatus status;
  final DateTime? submittedAt;
  final DateTime? viewedAt;
  final String? viewedBy;
  final DateTime createdAt;
  final Map<String, dynamic> formResponses;
  final Map<String, int> standardSnapshot;
  final List<PerformanceIncidentModel> incidents;

  const PerformanceReportModel({
    required this.id,
    required this.sessionId,
    required this.storeId,
    required this.storeName,
    required this.managerId,
    required this.managerName,
    required this.managerOnDutyId,
    required this.managerOnDutyName,
    this.employeeIds = const [],
    this.employeeNames = const [],
    required this.startedAt,
    required this.endedAt,
    this.drinkTotalQuantity = 0,
    this.drinkMeasurementCount = 0,
    this.drinkTotalSeconds = 0,
    this.drinkAverageSeconds = 0,
    this.cakeTotalQuantity = 0,
    this.cakeMeasurementCount = 0,
    this.cakeTotalSeconds = 0,
    this.cakeAverageSeconds = 0,
    this.orderCount = 0,
    this.orderTotalSeconds = 0,
    this.orderAverageSeconds = 0,
    this.status = ReportStatus.submitted,
    this.submittedAt,
    this.viewedAt,
    this.viewedBy,
    required this.createdAt,
    this.formResponses = const {},
    this.standardSnapshot = const {},
    this.incidents = const [],
  });

  bool get isViewed => status == ReportStatus.viewed;
  bool get isSubmitted => status == ReportStatus.submitted;

  PerformanceReportModel copyWith({
    String? id,
    String? sessionId,
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
    int? drinkTotalQuantity,
    int? drinkMeasurementCount,
    int? drinkTotalSeconds,
    int? drinkAverageSeconds,
    int? cakeTotalQuantity,
    int? cakeMeasurementCount,
    int? cakeTotalSeconds,
    int? cakeAverageSeconds,
    int? orderCount,
    int? orderTotalSeconds,
    int? orderAverageSeconds,
    ReportStatus? status,
    DateTime? submittedAt,
    DateTime? viewedAt,
    String? viewedBy,
    DateTime? createdAt,
    Map<String, dynamic>? formResponses,
    Map<String, int>? standardSnapshot,
    List<PerformanceIncidentModel>? incidents,
  }) {
    return PerformanceReportModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
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
      drinkTotalQuantity: drinkTotalQuantity ?? this.drinkTotalQuantity,
      drinkMeasurementCount: drinkMeasurementCount ?? this.drinkMeasurementCount,
      drinkTotalSeconds: drinkTotalSeconds ?? this.drinkTotalSeconds,
      drinkAverageSeconds: drinkAverageSeconds ?? this.drinkAverageSeconds,
      cakeTotalQuantity: cakeTotalQuantity ?? this.cakeTotalQuantity,
      cakeMeasurementCount: cakeMeasurementCount ?? this.cakeMeasurementCount,
      cakeTotalSeconds: cakeTotalSeconds ?? this.cakeTotalSeconds,
      cakeAverageSeconds: cakeAverageSeconds ?? this.cakeAverageSeconds,
      orderCount: orderCount ?? this.orderCount,
      orderTotalSeconds: orderTotalSeconds ?? this.orderTotalSeconds,
      orderAverageSeconds: orderAverageSeconds ?? this.orderAverageSeconds,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      viewedAt: viewedAt ?? this.viewedAt,
      viewedBy: viewedBy ?? this.viewedBy,
      createdAt: createdAt ?? this.createdAt,
      formResponses: formResponses ?? this.formResponses,
      standardSnapshot: standardSnapshot ?? this.standardSnapshot,
      incidents: incidents ?? this.incidents,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'storeId': storeId,
      'storeName': storeName,
      'managerId': managerId,
      'managerName': managerName,
      'managerOnDutyId': managerOnDutyId,
      'managerOnDutyName': managerOnDutyName,
      'employeeIds': employeeIds,
      'employeeNames': employeeNames,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': Timestamp.fromDate(endedAt),
      'drinkTotalQuantity': drinkTotalQuantity,
      'drinkMeasurementCount': drinkMeasurementCount,
      'drinkTotalSeconds': drinkTotalSeconds,
      'drinkAverageSeconds': drinkAverageSeconds,
      'cakeTotalQuantity': cakeTotalQuantity,
      'cakeMeasurementCount': cakeMeasurementCount,
      'cakeTotalSeconds': cakeTotalSeconds,
      'cakeAverageSeconds': cakeAverageSeconds,
      'orderCount': orderCount,
      'orderTotalSeconds': orderTotalSeconds,
      'orderAverageSeconds': orderAverageSeconds,
      'status': status.value,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'viewedAt': viewedAt != null ? Timestamp.fromDate(viewedAt!) : null,
      'viewedBy': viewedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'formResponses': formResponses,
      'standardSnapshot': standardSnapshot,
      'incidents': incidents.map((i) => i.toJson()).toList(),
    };
  }

  factory PerformanceReportModel.fromJson(Map<String, dynamic> json, [String? docId]) {
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

    return PerformanceReportModel(
      id: docId ?? json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      storeId: json['storeId'] as String? ?? '',
      storeName: json['storeName'] as String? ?? '',
      managerId: json['managerId'] as String? ?? '',
      managerName: json['managerName'] as String? ?? '',
      managerOnDutyId: json['managerOnDutyId'] as String? ?? '',
      managerOnDutyName: json['managerOnDutyName'] as String? ?? '',
      employeeIds: List<String>.from(json['employeeIds'] ?? []),
      employeeNames: List<String>.from(json['employeeNames'] ?? []),
      startedAt: parseDate(json['startedAt']),
      endedAt: parseDate(json['endedAt']),
      drinkTotalQuantity: (json['drinkTotalQuantity'] as num?)?.toInt() ?? 0,
      drinkMeasurementCount: (json['drinkMeasurementCount'] as num?)?.toInt() ?? 0,
      drinkTotalSeconds: (json['drinkTotalSeconds'] as num?)?.toInt() ?? 0,
      drinkAverageSeconds: (json['drinkAverageSeconds'] as num?)?.toInt() ?? 0,
      cakeTotalQuantity: (json['cakeTotalQuantity'] as num?)?.toInt() ?? 0,
      cakeMeasurementCount: (json['cakeMeasurementCount'] as num?)?.toInt() ?? 0,
      cakeTotalSeconds: (json['cakeTotalSeconds'] as num?)?.toInt() ?? 0,
      cakeAverageSeconds: (json['cakeAverageSeconds'] as num?)?.toInt() ?? 0,
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      orderTotalSeconds: (json['orderTotalSeconds'] as num?)?.toInt() ?? 0,
      orderAverageSeconds: (json['orderAverageSeconds'] as num?)?.toInt() ?? 0,
      status: ReportStatusExtension.fromString(json['status'] as String?),
      submittedAt: json['submittedAt'] != null ? parseDate(json['submittedAt']) : null,
      viewedAt: json['viewedAt'] != null ? parseDate(json['viewedAt']) : null,
      viewedBy: json['viewedBy'] as String?,
      createdAt: parseDate(json['createdAt']),
      formResponses: rawForm,
      standardSnapshot: rawStandards,
      incidents: rawIncidents,
    );
  }

  factory PerformanceReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PerformanceReportModel.fromJson(data, doc.id);
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
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
        drinkTotalQuantity,
        drinkMeasurementCount,
        drinkTotalSeconds,
        drinkAverageSeconds,
        cakeTotalQuantity,
        cakeMeasurementCount,
        cakeTotalSeconds,
        cakeAverageSeconds,
        orderCount,
        orderTotalSeconds,
        orderAverageSeconds,
        status,
        submittedAt,
        viewedAt,
        viewedBy,
        createdAt,
        formResponses,
        standardSnapshot,
        incidents,
      ];
}
