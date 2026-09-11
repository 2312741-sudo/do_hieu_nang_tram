import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/performance_calculator.dart';
import '../../../models/measurement_model.dart';
import '../../../models/store_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../session/providers/timer_service.dart';

class TimerCard extends ConsumerWidget {
  final MeasurementModel timer;
  final int itemNumber;
  final bool isCompact;

  const TimerCard({
    super.key,
    required this.timer,
    required this.itemNumber,
    this.isCompact = false,
  });

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hủy lần đo?'),
        content: Text(
          'Bạn có chắc chắn muốn hủy lần đo ${timer.category.label.toLowerCase()} này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('QUAY LẠI', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx);
              ref.read(performanceTimerProvider.notifier).cancelTimer(timer.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('HỦY ĐO'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching timer state ensures reactive rebuild on every tick
    ref.watch(performanceTimerProvider);
    final store = ref.watch(currentStoreProvider).valueOrNull;
    final standards = store?.performanceStandards ?? const StorePerformanceStandards();

    int standardSeconds = 120;
    if (timer.category == PerformanceCategory.drink) {
      standardSeconds = standards.drinkStandardSeconds;
    } else if (timer.category == PerformanceCategory.cake) {
      standardSeconds = standards.cakeStandardSeconds;
    } else if (timer.category == PerformanceCategory.order) {
      standardSeconds = standards.orderStandardSeconds;
    }

    final elapsed = timer.elapsedSeconds;
    final formattedTime = PerformanceCalculator.formatSeconds(elapsed);
    final isRunning = timer.status == MeasurementStatus.running;
    final isOverStandard = isRunning && elapsed > standardSeconds;
    final overtimeSeconds = elapsed - standardSeconds;

    final primaryColor = isOverStandard
        ? AppColors.danger
        : (isRunning ? AppColors.success : AppColors.accent);

    final title = timer.category == PerformanceCategory.order
        ? (timer.orderCode != null && timer.orderCode!.isNotEmpty
            ? 'Đơn ${timer.orderCode} (Lần $itemNumber)'
            : 'Đơn hàng lần $itemNumber')
        : '${timer.category.label} lần $itemNumber';

    final staffSuffix = (timer.staffName != null && timer.staffName!.isNotEmpty)
        ? ' • 👤 ${timer.staffName}'
        : '';
    final subtitle = timer.category == PerformanceCategory.order
        ? '1 đơn hàng • Chuẩn ${standardSeconds}s$staffSuffix'
        : '${timer.quantity} ${timer.category.label.toLowerCase()} • Chuẩn ${standardSeconds}s$staffSuffix';

    if (isCompact) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverStandard
                ? AppColors.danger
                : (isRunning ? AppColors.success.withOpacity(0.3) : AppColors.accent.withOpacity(0.4)),
            width: isOverStandard ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isOverStandard
                  ? AppColors.danger.withOpacity(0.12)
                  : const Color(0x0A000000),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                timer.category == PerformanceCategory.drink
                    ? Icons.local_cafe_rounded
                    : (timer.category == PerformanceCategory.cake
                        ? Icons.cake_rounded
                        : Icons.receipt_long_rounded),
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.neutral,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
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
                  formattedTime,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'BeVietnamPro',
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverStandard
                          ? 'Quá chuẩn (+${overtimeSeconds}s)'
                          : (isRunning ? 'Đang chạy' : 'Tạm dừng'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Full Card Mode
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverStandard
              ? AppColors.danger
              : (isRunning ? AppColors.success.withOpacity(0.3) : AppColors.accent.withOpacity(0.4)),
          width: isOverStandard ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isOverStandard
                ? AppColors.danger.withOpacity(0.15)
                : (isRunning ? AppColors.success : AppColors.accent).withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  timer.category == PerformanceCategory.drink
                      ? Icons.local_cafe_rounded
                      : (timer.category == PerformanceCategory.cake
                          ? Icons.cake_rounded
                          : Icons.receipt_long_rounded),
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'BeVietnamPro',
                        color: AppColors.neutral,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOverStandard
                          ? 'Quá chuẩn (+${overtimeSeconds}s)'
                          : (isRunning ? 'Đang chạy' : 'Tạm dừng'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Central Stopwatch Display
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: isOverStandard ? AppColors.danger.withOpacity(0.06) : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'BeVietnamPro',
                  color: isOverStandard
                      ? AppColors.danger
                      : (isRunning ? AppColors.neutral : AppColors.accent),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons
          Row(
            children: [
              // Pause / Resume
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    final notifier = ref.read(performanceTimerProvider.notifier);
                    if (isRunning) {
                      notifier.pauseTimer(timer.id);
                    } else {
                      notifier.resumeTimer(timer.id);
                    }
                  },
                  icon: Icon(
                    isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 20,
                  ),
                  label: Text(isRunning ? 'Tạm dừng' : 'Tiếp tục'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isRunning ? AppColors.accent : AppColors.success,
                    side: BorderSide(
                      color: isRunning ? AppColors.accent : AppColors.success,
                      width: 1.5,
                    ),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Complete
              Expanded(
                flex: 4,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(performanceTimerProvider.notifier).completeTimer(timer.id);
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text('Hoàn thành'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Cancel
              IconButton(
                onPressed: () => _confirmCancel(context, ref),
                icon: const Icon(Icons.close_rounded, color: AppColors.danger),
                tooltip: 'Hủy lần đo',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.danger.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(46, 46),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
