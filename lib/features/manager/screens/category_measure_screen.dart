import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/performance_calculator.dart';
import '../../../models/measurement_model.dart';
import '../../session/providers/timer_service.dart';
import '../widgets/add_timer_bottom_sheet.dart';
import '../widgets/timer_card.dart';

class CategoryMeasureScreen extends ConsumerWidget {
  final PerformanceCategory category;

  const CategoryMeasureScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(performanceTimerProvider);
    final allMeasurements = ref.watch(sessionMeasurementsProvider).valueOrNull ?? [];
    final categoryMeasurements = allMeasurements
        .where((m) => m.category == category && !m.status.isCancelled)
        .toList();

    final activeTimers = categoryMeasurements.where((m) => m.status.isActive).toList();
    final completedMeasurements = categoryMeasurements.where((m) => m.status.isCompleted).toList();

    final count = categoryMeasurements.length;
    final isMaxReached = count >= 20;

    // Summary calculations
    final totalQuantity = completedMeasurements.fold<int>(
      0,
      (sum, m) => sum + (category == PerformanceCategory.order ? 1 : m.quantity),
    );
    final totalDuration = completedMeasurements.fold<int>(
      0,
      (sum, m) => sum + m.durationSeconds,
    );

    final avgSeconds = category == PerformanceCategory.order
        ? PerformanceCalculator.calculateCountAverage(totalSeconds: totalDuration, count: completedMeasurements.length)
        : PerformanceCalculator.calculateWeightedAverage(totalSeconds: totalDuration, totalQuantity: totalQuantity);

    final formattedAvg = PerformanceCalculator.formatSeconds(avgSeconds);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFC8102E), Color(0xFF8B0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          ),
                          Expanded(
                            child: Text(
                              category.label.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'BeVietnamPro',
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '$count / 20 lần',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'BeVietnamPro',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Metrics Cards
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: category == PerformanceCategory.order ? 'Tổng số đơn' : 'Tổng số lượng',
                              value: '$totalQuantity',
                              unit: category.unitLabel.replaceAll('/', '').trim(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricCard(
                              label: 'Trung bình',
                              value: formattedAvg,
                              unit: category.unitLabel,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MetricCard(
                              label: 'Đang đo',
                              value: '${activeTimers.length}',
                              unit: 'timer',
                              isHighlight: activeTimers.isNotEmpty,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Measurement CTA Button
                  ElevatedButton.icon(
                    onPressed: isMaxReached
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã đạt tối đa 20 lần đo cho mục này.'),
                                backgroundColor: AppColors.neutral,
                              ),
                            );
                          }
                        : () => AddTimerBottomSheet.show(context, category),
                    icon: const Icon(Icons.add_rounded, size: 22),
                    label: Text(
                      isMaxReached ? 'ĐÃ ĐẠT TỐI ĐA 20 LẦN ĐO' : '+ THÊM LẦN ĐO',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMaxReached ? AppColors.textDisabled : AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: isMaxReached ? 0 : 3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Active Timers Section
                  if (activeTimers.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đang chạy (${activeTimers.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'BeVietnamPro',
                            color: AppColors.neutral,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...activeTimers.map((timer) {
                      final itemIdx = PerformanceCalculator.getCategorySequenceNumber(timer, allMeasurements);
                      return TimerCard(timer: timer, itemNumber: itemIdx);
                    }),
                    const SizedBox(height: 20),
                  ],

                  // Completed Section
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Đã hoàn thành (${completedMeasurements.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.neutral,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (completedMeasurements.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Text(
                        'Chưa có lần đo hoàn thành nào.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'BeVietnamPro',
                        ),
                      ),
                    )
                  else
                    ...completedMeasurements.reversed.map((m) {
                      final seqNum = PerformanceCalculator.getCategorySequenceNumber(m, allMeasurements);
                      final timeFmt = DateFormat('HH:mm');
                      final startStr = timeFmt.format(m.startedAt);
                      final endStr = m.completedAt != null ? timeFmt.format(m.completedAt!) : '--:--';
                      final durStr = PerformanceCalculator.formatSeconds(m.durationSeconds);
                      final perItemStr = PerformanceCalculator.formatSeconds(m.secondsPerItem);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Lần $seqNum',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'BeVietnamPro',
                                  color: AppColors.primary,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category == PerformanceCategory.order
                                        ? 'Đơn ${m.orderCode ?? ''}'
                                        : '${m.quantity} ${category.label.toLowerCase()}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'BeVietnamPro',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$startStr – $endStr',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'BeVietnamPro',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  durStr,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'BeVietnamPro',
                                    color: AppColors.neutral,
                                  ),
                                ),
                                if (category != PerformanceCategory.order && m.quantity > 1) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '$perItemStr ${category.unitLabel}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'BeVietnamPro',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool isHighlight;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? Colors.amber.withOpacity(0.8) : Colors.white24,
          width: isHighlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? Colors.amberAccent : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'BeVietnamPro',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontFamily: 'BeVietnamPro',
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            unit,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9.5,
              fontFamily: 'BeVietnamPro',
            ),
          ),
        ],
      ),
    );
  }
}
