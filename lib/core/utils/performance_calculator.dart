import '../../models/measurement_model.dart';
import '../../models/performance_report_model.dart';

class PerformanceCalculator {
  PerformanceCalculator._();

  /// Returns the 1-based sequence number of a measurement within its category in the session.
  static int getCategorySequenceNumber(
    MeasurementModel target,
    List<MeasurementModel> allMeasurements,
  ) {
    final list = allMeasurements
        .where((m) => m.category == target.category && !m.status.isCancelled)
        .toList();
    list.sort((a, b) => a.startedAt.compareTo(b.startedAt));

    final idx = list.indexWhere((m) => m.id == target.id);
    if (idx != -1) {
      return idx + 1;
    }
    return list.length + 1;
  }

  /// Formats seconds into mm:ss (or hh:mm:ss if >= 1 hour).
  /// Examples:
  ///   0   -> 00:00
  ///   4   -> 00:04
  ///   65  -> 01:05
  ///   135 -> 02:15
  ///   484 -> 08:04
  static String formatSeconds(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats seconds per unit into a user-friendly string (e.g., "1p 15s/nước").
  static String formatSecondsPerUnit(int seconds, String unit) {
    final timeStr = formatSeconds(seconds);
    return '$timeStr/$unit';
  }

  /// Calculates the average seconds per item from total seconds and total items,
  /// rounded to the nearest integer.
  static int calculateAverageSecondsPerItem({
    required int totalSeconds,
    required int totalQuantity,
  }) {
    if (totalQuantity <= 0) return 0;
    return (totalSeconds / totalQuantity).round();
  }

  /// Calculates the average seconds per item across a list of completed measurements.
  static int calculateCategoryAverage(List<MeasurementModel> measurements) {
    final completed = measurements.where((m) => m.status == MeasurementStatus.completed).toList();
    if (completed.isEmpty) return 0;

    final totalSeconds = completed.fold<int>(0, (sum, m) => sum + m.durationSeconds);
    final totalQty = completed.fold<int>(0, (sum, m) => sum + m.quantity);

    return calculateAverageSecondsPerItem(
      totalSeconds: totalSeconds,
      totalQuantity: totalQty,
    );
  }

  /// Parses mm:ss string into total seconds.
  /// Example: '02:15' -> 135
  static int parseTimeStringToSeconds(String timeStr) {
    final parts = timeStr.trim().split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      return m * 60 + s;
    } else if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;
      return h * 3600 + m * 60 + s;
    }
    return int.tryParse(timeStr) ?? 0;
  }

  /// Calculates weighted average: totalDurationSeconds / totalQuantity,
  /// rounded to the nearest integer.
  static int calculateWeightedAverage({
    required int totalSeconds,
    required int totalQuantity,
  }) {
    if (totalQuantity <= 0) return 0;
    return (totalSeconds / totalQuantity).round();
  }

  /// Calculates the average seconds per measurement count,
  /// rounded to the nearest integer.
  static int calculateCountAverage({
    required int totalSeconds,
    required int count,
  }) {
    if (count <= 0) return 0;
    return (totalSeconds / count).round();
  }

  /// Calculates Leaderboard statistics for all staff across given performance reports.
  static List<StaffPerformanceStats> calculateStaffLeaderboard({
    required List<PerformanceReportModel> reports,
    int drinkStandardSeconds = 120,
    int cakeStandardSeconds = 120,
  }) {
    if (reports.isEmpty) return [];

    final Map<String, _StaffAccumulator> accumulators = {};

    for (final report in reports) {
      final empNames = report.employeeNames;
      final empIds = report.employeeIds;

      // Track who was on shift in this report
      for (int i = 0; i < empNames.length; i++) {
        final rawName = empNames[i];
        final id = empIds.length > i ? empIds[i] : rawName;

        String cleanName = rawName
            .replaceAll(RegExp(r'\((Nước|Bánh|Phục vụ|nuoc|banh|phuc vu)\)', caseSensitive: false), '')
            .trim();
        if (cleanName.isEmpty) cleanName = rawName;

        final isDrink = rawName.toLowerCase().contains('nước') || rawName.toLowerCase().contains('nuoc');
        final isCake = rawName.toLowerCase().contains('bánh') || rawName.toLowerCase().contains('banh');
        final isService = rawName.toLowerCase().contains('phục vụ') || rawName.toLowerCase().contains('phuc vu');

        // If legacy data without tags, attribute both drink & cake if present
        final assignDrink = isDrink || (!isCake && !isService);
        final assignCake = isCake || (!isDrink && !isService);

        final acc = accumulators.putIfAbsent(
          cleanName,
          () => _StaffAccumulator(id: id, name: cleanName),
        );

        acc.sessionIds.add(report.sessionId.isNotEmpty ? report.sessionId : report.id);

        if (assignDrink && report.drinkTotalQuantity > 0) {
          acc.drinkQuantity += report.drinkTotalQuantity;
          acc.drinkTotalSeconds += report.drinkTotalSeconds;
        }

        if (assignCake && report.cakeTotalQuantity > 0) {
          acc.cakeQuantity += report.cakeTotalQuantity;
          acc.cakeTotalSeconds += report.cakeTotalSeconds;
        }
      }
    }

    final statsList = <StaffPerformanceStats>[];

    for (final acc in accumulators.values) {
      final drinkAvg = acc.drinkQuantity > 0 ? (acc.drinkTotalSeconds / acc.drinkQuantity).round() : 0;
      final double? drinkEff = drinkAvg > 0 ? ((drinkStandardSeconds / drinkAvg) * 100.0) : null;

      final cakeAvg = acc.cakeQuantity > 0 ? (acc.cakeTotalSeconds / acc.cakeQuantity).round() : 0;
      final double? cakeEff = cakeAvg > 0 ? ((cakeStandardSeconds / cakeAvg) * 100.0) : null;

      final totalProducts = acc.drinkQuantity + acc.cakeQuantity;
      final totalStandardTime = (acc.drinkQuantity * drinkStandardSeconds) + (acc.cakeQuantity * cakeStandardSeconds);
      final totalActualTime = acc.drinkTotalSeconds + acc.cakeTotalSeconds;

      double totalEff = 0.0;
      if (totalActualTime > 0 && totalProducts > 0) {
        totalEff = (totalStandardTime / totalActualTime) * 100.0;
      } else if (drinkEff != null) {
        totalEff = drinkEff;
      } else if (cakeEff != null) {
        totalEff = cakeEff;
      }

      statsList.add(
        StaffPerformanceStats(
          staffId: acc.id,
          staffName: acc.name,
          sessionCount: acc.sessionIds.length,
          drinkQuantity: acc.drinkQuantity,
          drinkTotalSeconds: acc.drinkTotalSeconds,
          drinkAverageSeconds: drinkAvg,
          drinkStandardSeconds: drinkStandardSeconds,
          drinkEfficiencyPercent: drinkEff,
          cakeQuantity: acc.cakeQuantity,
          cakeTotalSeconds: acc.cakeTotalSeconds,
          cakeAverageSeconds: cakeAvg,
          cakeStandardSeconds: cakeStandardSeconds,
          cakeEfficiencyPercent: cakeEff,
          totalProducts: totalProducts,
          totalEfficiencyPercent: totalEff,
        ),
      );
    }

    // Sort by Total Efficiency DESC, then by total products DESC
    statsList.sort((a, b) {
      final cmp = b.totalEfficiencyPercent.compareTo(a.totalEfficiencyPercent);
      if (cmp != 0) return cmp;
      return b.totalProducts.compareTo(a.totalProducts);
    });

    // Assign 1-based ranks
    for (int i = 0; i < statsList.length; i++) {
      statsList[i] = statsList[i].copyWith(rank: i + 1);
    }

    return statsList;
  }
}

class _StaffAccumulator {
  final String id;
  final String name;
  final Set<String> sessionIds = {};
  int drinkQuantity = 0;
  int drinkTotalSeconds = 0;
  int cakeQuantity = 0;
  int cakeTotalSeconds = 0;

  _StaffAccumulator({required this.id, required this.name});
}

class StaffPerformanceStats {
  final String staffId;
  final String staffName;
  final int sessionCount;
  final int drinkQuantity;
  final int drinkTotalSeconds;
  final int drinkAverageSeconds;
  final int drinkStandardSeconds;
  final double? drinkEfficiencyPercent;
  final int cakeQuantity;
  final int cakeTotalSeconds;
  final int cakeAverageSeconds;
  final int cakeStandardSeconds;
  final double? cakeEfficiencyPercent;
  final int totalProducts;
  final double totalEfficiencyPercent;
  final int rank;

  const StaffPerformanceStats({
    required this.staffId,
    required this.staffName,
    required this.sessionCount,
    this.drinkQuantity = 0,
    this.drinkTotalSeconds = 0,
    this.drinkAverageSeconds = 0,
    this.drinkStandardSeconds = 120,
    this.drinkEfficiencyPercent,
    this.cakeQuantity = 0,
    this.cakeTotalSeconds = 0,
    this.cakeAverageSeconds = 0,
    this.cakeStandardSeconds = 120,
    this.cakeEfficiencyPercent,
    this.totalProducts = 0,
    this.totalEfficiencyPercent = 0.0,
    this.rank = 0,
  });

  String get performanceRating {
    if (totalEfficiencyPercent >= 110.0) return 'Xuất sắc';
    if (totalEfficiencyPercent >= 95.0) return 'Đạt chuẩn';
    if (totalEfficiencyPercent >= 80.0) return 'Khá';
    return 'Cần cải thiện';
  }

  StaffPerformanceStats copyWith({
    String? staffId,
    String? staffName,
    int? sessionCount,
    int? drinkQuantity,
    int? drinkTotalSeconds,
    int? drinkAverageSeconds,
    int? drinkStandardSeconds,
    double? drinkEfficiencyPercent,
    int? cakeQuantity,
    int? cakeTotalSeconds,
    int? cakeAverageSeconds,
    int? cakeStandardSeconds,
    double? cakeEfficiencyPercent,
    int? totalProducts,
    double? totalEfficiencyPercent,
    int? rank,
  }) {
    return StaffPerformanceStats(
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      sessionCount: sessionCount ?? this.sessionCount,
      drinkQuantity: drinkQuantity ?? this.drinkQuantity,
      drinkTotalSeconds: drinkTotalSeconds ?? this.drinkTotalSeconds,
      drinkAverageSeconds: drinkAverageSeconds ?? this.drinkAverageSeconds,
      drinkStandardSeconds: drinkStandardSeconds ?? this.drinkStandardSeconds,
      drinkEfficiencyPercent: drinkEfficiencyPercent ?? this.drinkEfficiencyPercent,
      cakeQuantity: cakeQuantity ?? this.cakeQuantity,
      cakeTotalSeconds: cakeTotalSeconds ?? this.cakeTotalSeconds,
      cakeAverageSeconds: cakeAverageSeconds ?? this.cakeAverageSeconds,
      cakeStandardSeconds: cakeStandardSeconds ?? this.cakeStandardSeconds,
      cakeEfficiencyPercent: cakeEfficiencyPercent ?? this.cakeEfficiencyPercent,
      totalProducts: totalProducts ?? this.totalProducts,
      totalEfficiencyPercent: totalEfficiencyPercent ?? this.totalEfficiencyPercent,
      rank: rank ?? this.rank,
    );
  }
}
