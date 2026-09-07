import 'package:equatable/equatable.dart';

/// Guest-local measurement model — no Firebase dependencies.
/// Reuses [PerformanceCategory] and [MeasurementStatus] enums from the main model.
import '../../../models/measurement_model.dart'
    show PerformanceCategory, PerformanceCategoryExtension, MeasurementStatus, MeasurementStatusExtension;

export '../../../models/measurement_model.dart'
    show PerformanceCategory, PerformanceCategoryExtension, MeasurementStatus, MeasurementStatusExtension;

class GuestMeasurementModel extends Equatable {
  final String id;
  final String sessionId;
  final PerformanceCategory category;
  final int quantity;
  final String? orderCode;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime? pausedAt;
  final int totalPausedSeconds;
  final DateTime? completedAt;
  final MeasurementStatus status;
  final DateTime createdAt;

  const GuestMeasurementModel({
    required this.id,
    required this.sessionId,
    required this.category,
    this.quantity = 1,
    this.orderCode,
    this.durationSeconds = 0,
    required this.startedAt,
    this.pausedAt,
    this.totalPausedSeconds = 0,
    this.completedAt,
    this.status = MeasurementStatus.running,
    required this.createdAt,
  });

  /// Timestamp-based elapsed seconds — accurate even after app restart / background
  int get elapsedSeconds {
    if (status == MeasurementStatus.completed || status == MeasurementStatus.cancelled) {
      return durationSeconds;
    }
    if (status == MeasurementStatus.ready) return 0;
    if (status == MeasurementStatus.paused) return durationSeconds;

    final now = DateTime.now();
    final elapsed = now.difference(startedAt).inSeconds - totalPausedSeconds;
    return elapsed >= 0 ? elapsed : 0;
  }

  int get secondsPerItem {
    final s = elapsedSeconds;
    if (quantity <= 1) return s;
    return (s / quantity).round();
  }

  GuestMeasurementModel copyWith({
    String? id,
    String? sessionId,
    PerformanceCategory? category,
    int? quantity,
    String? orderCode,
    int? durationSeconds,
    DateTime? startedAt,
    DateTime? pausedAt,
    int? totalPausedSeconds,
    DateTime? completedAt,
    MeasurementStatus? status,
    DateTime? createdAt,
  }) {
    return GuestMeasurementModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      orderCode: orderCode ?? this.orderCode,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      totalPausedSeconds: totalPausedSeconds ?? this.totalPausedSeconds,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sessionId': sessionId,
        'category': category.value,
        'quantity': quantity,
        'orderCode': orderCode,
        'durationSeconds': durationSeconds,
        'startedAt': startedAt.toIso8601String(),
        'pausedAt': pausedAt?.toIso8601String(),
        'totalPausedSeconds': totalPausedSeconds,
        'completedAt': completedAt?.toIso8601String(),
        'status': status.value,
        'createdAt': createdAt.toIso8601String(),
      };

  factory GuestMeasurementModel.fromJson(Map<String, dynamic> json) {
    return GuestMeasurementModel(
      id: json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      category: PerformanceCategoryExtension.fromString(json['category'] as String?),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      orderCode: json['orderCode'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
      pausedAt: json['pausedAt'] != null ? DateTime.tryParse(json['pausedAt'] as String) : null,
      totalPausedSeconds: (json['totalPausedSeconds'] as num?)?.toInt() ?? 0,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'] as String) : null,
      status: MeasurementStatusExtension.fromString(json['status'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id, sessionId, category, quantity, orderCode, durationSeconds,
        startedAt, pausedAt, totalPausedSeconds, completedAt, status, createdAt,
      ];
}
