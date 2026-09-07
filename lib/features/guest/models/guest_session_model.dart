import 'package:equatable/equatable.dart';
import 'guest_measurement_model.dart';

/// Status of a guest session
enum GuestSessionStatus { active, completed }

extension GuestSessionStatusExtension on GuestSessionStatus {
  String get value => this == GuestSessionStatus.active ? 'active' : 'completed';
  static GuestSessionStatus fromString(String? val) =>
      val == 'completed' ? GuestSessionStatus.completed : GuestSessionStatus.active;
}

/// Anonymous personnel labels for Guest Mode
class GuestPersonnel {
  static const List<String> managers = ['Quản lý 1', 'Quản lý 2', 'Quản lý 3', 'Quản lý 4'];
  static const List<String> employees = ['Nhân viên 1', 'Nhân viên 2', 'Nhân viên 3', 'Nhân viên 4'];

  static String managerLabel(int index) =>
      index >= 0 && index < managers.length ? managers[index] : 'Quản lý ${index + 1}';

  static String employeeLabel(int index) =>
      index >= 0 && index < employees.length ? employees[index] : 'Nhân viên ${index + 1}';

  static List<String> employeeLabels(List<int> indexes) =>
      indexes.map((i) => employeeLabel(i)).toList();
}

/// Guest session model — stored locally, never touches Firebase
class GuestSessionModel extends Equatable {
  final String id;
  final int managerOnDutyIndex; // 0-3 mapping to "Quản lý 1-4"
  final List<int> employeeIndexes; // 0-3 mapping to "Nhân viên 1-4"
  final DateTime startedAt;
  final DateTime? endedAt;
  final GuestSessionStatus status;

  // Summary metrics (computed on end)
  final int drinkCount;
  final int drinkTotalQuantity;
  final int drinkTotalSeconds;
  final int cakeCount;
  final int cakeTotalQuantity;
  final int cakeTotalSeconds;
  final int orderCount;
  final int orderTotalSeconds;

  final DateTime createdAt;

  const GuestSessionModel({
    required this.id,
    required this.managerOnDutyIndex,
    this.employeeIndexes = const [],
    required this.startedAt,
    this.endedAt,
    this.status = GuestSessionStatus.active,
    this.drinkCount = 0,
    this.drinkTotalQuantity = 0,
    this.drinkTotalSeconds = 0,
    this.cakeCount = 0,
    this.cakeTotalQuantity = 0,
    this.cakeTotalSeconds = 0,
    this.orderCount = 0,
    this.orderTotalSeconds = 0,
    required this.createdAt,
  });

  bool get isActive => status == GuestSessionStatus.active;

  String get managerOnDutyLabel => GuestPersonnel.managerLabel(managerOnDutyIndex);
  List<String> get employeeLabels => GuestPersonnel.employeeLabels(employeeIndexes);

  int get drinkAverageSeconds =>
      drinkTotalQuantity > 0 ? (drinkTotalSeconds / drinkTotalQuantity).round() : 0;
  int get cakeAverageSeconds =>
      cakeTotalQuantity > 0 ? (cakeTotalSeconds / cakeTotalQuantity).round() : 0;
  int get orderAverageSeconds =>
      orderCount > 0 ? (orderTotalSeconds / orderCount).round() : 0;

  /// Recompute summary from a list of completed measurements
  GuestSessionModel recomputeSummary(List<GuestMeasurementModel> allMeasurements) {
    final completed = allMeasurements.where((m) => m.status == MeasurementStatus.completed).toList();
    final drinks = completed.where((m) => m.category == PerformanceCategory.drink).toList();
    final cakes = completed.where((m) => m.category == PerformanceCategory.cake).toList();
    final orders = completed.where((m) => m.category == PerformanceCategory.order).toList();

    return copyWith(
      drinkCount: drinks.length,
      drinkTotalQuantity: drinks.fold<int>(0, (s, m) => s + m.quantity),
      drinkTotalSeconds: drinks.fold<int>(0, (s, m) => s + m.durationSeconds),
      cakeCount: cakes.length,
      cakeTotalQuantity: cakes.fold<int>(0, (s, m) => s + m.quantity),
      cakeTotalSeconds: cakes.fold<int>(0, (s, m) => s + m.durationSeconds),
      orderCount: orders.length,
      orderTotalSeconds: orders.fold<int>(0, (s, m) => s + m.durationSeconds),
    );
  }

  GuestSessionModel copyWith({
    String? id,
    int? managerOnDutyIndex,
    List<int>? employeeIndexes,
    DateTime? startedAt,
    DateTime? endedAt,
    GuestSessionStatus? status,
    int? drinkCount,
    int? drinkTotalQuantity,
    int? drinkTotalSeconds,
    int? cakeCount,
    int? cakeTotalQuantity,
    int? cakeTotalSeconds,
    int? orderCount,
    int? orderTotalSeconds,
    DateTime? createdAt,
  }) {
    return GuestSessionModel(
      id: id ?? this.id,
      managerOnDutyIndex: managerOnDutyIndex ?? this.managerOnDutyIndex,
      employeeIndexes: employeeIndexes ?? this.employeeIndexes,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'managerOnDutyIndex': managerOnDutyIndex,
        'employeeIndexes': employeeIndexes,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'status': status.value,
        'drinkCount': drinkCount,
        'drinkTotalQuantity': drinkTotalQuantity,
        'drinkTotalSeconds': drinkTotalSeconds,
        'cakeCount': cakeCount,
        'cakeTotalQuantity': cakeTotalQuantity,
        'cakeTotalSeconds': cakeTotalSeconds,
        'orderCount': orderCount,
        'orderTotalSeconds': orderTotalSeconds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GuestSessionModel.fromJson(Map<String, dynamic> json) {
    return GuestSessionModel(
      id: json['id'] as String? ?? '',
      managerOnDutyIndex: (json['managerOnDutyIndex'] as num?)?.toInt() ?? 0,
      employeeIndexes: (json['employeeIndexes'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
      endedAt: json['endedAt'] != null ? DateTime.tryParse(json['endedAt'] as String) : null,
      status: GuestSessionStatusExtension.fromString(json['status'] as String?),
      drinkCount: (json['drinkCount'] as num?)?.toInt() ?? 0,
      drinkTotalQuantity: (json['drinkTotalQuantity'] as num?)?.toInt() ?? 0,
      drinkTotalSeconds: (json['drinkTotalSeconds'] as num?)?.toInt() ?? 0,
      cakeCount: (json['cakeCount'] as num?)?.toInt() ?? 0,
      cakeTotalQuantity: (json['cakeTotalQuantity'] as num?)?.toInt() ?? 0,
      cakeTotalSeconds: (json['cakeTotalSeconds'] as num?)?.toInt() ?? 0,
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      orderTotalSeconds: (json['orderTotalSeconds'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id, managerOnDutyIndex, employeeIndexes, startedAt, endedAt, status,
        drinkCount, drinkTotalQuantity, drinkTotalSeconds,
        cakeCount, cakeTotalQuantity, cakeTotalSeconds,
        orderCount, orderTotalSeconds, createdAt,
      ];
}
