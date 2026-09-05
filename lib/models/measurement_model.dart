import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum PerformanceCategory {
  drink,
  cake,
  order,
}

extension PerformanceCategoryExtension on PerformanceCategory {
  String get value {
    switch (this) {
      case PerformanceCategory.drink:
        return 'drink';
      case PerformanceCategory.cake:
        return 'cake';
      case PerformanceCategory.order:
        return 'order';
    }
  }

  String get label {
    switch (this) {
      case PerformanceCategory.drink:
        return 'Nước';
      case PerformanceCategory.cake:
        return 'Bánh';
      case PerformanceCategory.order:
        return 'Đơn hàng';
    }
  }

  String get unitLabel {
    switch (this) {
      case PerformanceCategory.drink:
        return '/ nước';
      case PerformanceCategory.cake:
        return '/ bánh';
      case PerformanceCategory.order:
        return '/ đơn';
    }
  }

  static PerformanceCategory fromString(String? val) {
    switch (val) {
      case 'cake':
        return PerformanceCategory.cake;
      case 'order':
        return PerformanceCategory.order;
      case 'drink':
      default:
        return PerformanceCategory.drink;
    }
  }
}

enum MeasurementStatus {
  ready,
  running,
  paused,
  completed,
  cancelled,
}

extension MeasurementStatusExtension on MeasurementStatus {
  String get value {
    switch (this) {
      case MeasurementStatus.ready:
        return 'ready';
      case MeasurementStatus.running:
        return 'running';
      case MeasurementStatus.paused:
        return 'paused';
      case MeasurementStatus.completed:
        return 'completed';
      case MeasurementStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case MeasurementStatus.ready:
        return 'Sẵn sàng';
      case MeasurementStatus.running:
        return 'Đang chạy';
      case MeasurementStatus.paused:
        return 'Tạm dừng';
      case MeasurementStatus.completed:
        return 'Hoàn thành';
      case MeasurementStatus.cancelled:
        return 'Đã hủy';
    }
  }

  bool get isActive => this == MeasurementStatus.running || this == MeasurementStatus.paused;
  bool get isRunning => this == MeasurementStatus.running;
  bool get isPaused => this == MeasurementStatus.paused;
  bool get isCompleted => this == MeasurementStatus.completed;
  bool get isCancelled => this == MeasurementStatus.cancelled;

  static MeasurementStatus fromString(String? val) {
    switch (val) {
      case 'running':
        return MeasurementStatus.running;
      case 'paused':
        return MeasurementStatus.paused;
      case 'completed':
        return MeasurementStatus.completed;
      case 'cancelled':
        return MeasurementStatus.cancelled;
      case 'ready':
      default:
        return MeasurementStatus.ready;
    }
  }
}

class MeasurementModel extends Equatable {
  final String id;
  final String sessionId;
  final String storeId;
  final String userId;
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

  const MeasurementModel({
    required this.id,
    required this.sessionId,
    required this.storeId,
    required this.userId,
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

  /// Real-time calculated elapsed seconds from timestamps
  int get elapsedSeconds {
    if (status == MeasurementStatus.completed || status == MeasurementStatus.cancelled) {
      return durationSeconds;
    }
    if (status == MeasurementStatus.ready) {
      return 0;
    }
    if (status == MeasurementStatus.paused) {
      return durationSeconds;
    }
    // Running: now - startedAt - totalPausedSeconds
    final now = DateTime.now();
    final elapsed = now.difference(startedAt).inSeconds - totalPausedSeconds;
    return elapsed >= 0 ? elapsed : 0;
  }

  /// Average seconds per item for this measurement
  int get secondsPerItem {
    final s = elapsedSeconds;
    if (quantity <= 1) return s;
    return (s / quantity).round();
  }

  MeasurementModel copyWith({
    String? id,
    String? sessionId,
    String? storeId,
    String? userId,
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
    return MeasurementModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      storeId: storeId ?? this.storeId,
      userId: userId ?? this.userId,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'storeId': storeId,
      'userId': userId,
      'category': category.value,
      'quantity': quantity,
      'orderCode': orderCode,
      'durationSeconds': durationSeconds,
      'startedAt': Timestamp.fromDate(startedAt),
      'pausedAt': pausedAt != null ? Timestamp.fromDate(pausedAt!) : null,
      'totalPausedSeconds': totalPausedSeconds,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory MeasurementModel.fromJson(Map<String, dynamic> json, [String? docId]) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return MeasurementModel(
      id: docId ?? json['id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      storeId: json['storeId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      category: PerformanceCategoryExtension.fromString(json['category'] as String?),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      orderCode: json['orderCode'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      startedAt: parseDate(json['startedAt']),
      pausedAt: json['pausedAt'] != null ? parseDate(json['pausedAt']) : null,
      totalPausedSeconds: (json['totalPausedSeconds'] as num?)?.toInt() ?? 0,
      completedAt: json['completedAt'] != null ? parseDate(json['completedAt']) : null,
      status: MeasurementStatusExtension.fromString(json['status'] as String?),
      createdAt: parseDate(json['createdAt']),
    );
  }

  factory MeasurementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MeasurementModel.fromJson(data, doc.id);
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        storeId,
        userId,
        category,
        quantity,
        orderCode,
        durationSeconds,
        startedAt,
        pausedAt,
        totalPausedSeconds,
        completedAt,
        status,
        createdAt,
      ];
}
