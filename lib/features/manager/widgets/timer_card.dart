import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/category_timer_theme.dart';
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
            child: const Text('QUAY LẠI',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.heavyImpact();
              Navigator.pop(ctx);
              final error = await ref
                  .read(performanceTimerProvider.notifier)
                  .cancelTimer(timer.id);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
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

  void _showEnterOrderCodeDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.confirmation_number_rounded,
                  color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text('Nhập mã đơn hàng'),
            ],
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Ví dụ: 104-382',
              errorText: errorText,
            ),
            onChanged: (_) {
              if (errorText != null) setDialogState(() => errorText = null);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                ctrl.dispose();
                Navigator.pop(ctx);
              },
              child: const Text('BỎ QUA',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                final error = await ref
                    .read(performanceTimerProvider.notifier)
                    .updateOrderCode(timer.id, ctrl.text);
                if (error != null) {
                  setDialogState(() => errorText = error);
                } else {
                  ctrl.dispose();
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('LƯU'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching timer state ensures reactive rebuild on every tick
    ref.watch(performanceTimerProvider);
    final store = ref.watch(currentStoreProvider).valueOrNull;
    final standards =
        store?.performanceStandards ?? const StorePerformanceStandards();

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

    final theme = CategoryTimerTheme.of(timer.category);

    final title = timer.category == PerformanceCategory.order
        ? (timer.orderCode != null && timer.orderCode!.isNotEmpty
            ? 'Đơn ${timer.orderCode} (Lần $itemNumber)'
            : 'Đơn hàng lần $itemNumber')
        : '${timer.category.label} lần $itemNumber';

    final staffSuffix = (timer.staffName != null && timer.staffName!.isNotEmpty)
        ? ' • 👤 ${timer.staffName}'
        : '';
    final measuredSuffix =
        (timer.measuredByName != null && timer.measuredByName!.isNotEmpty)
            ? ' • ⏱️ Đo: ${timer.measuredByName}'
            : '';
    final subtitle = timer.category == PerformanceCategory.order
        ? '1 đơn hàng • Chuẩn ${standardSeconds}s$staffSuffix$measuredSuffix'
        : '${timer.quantity} ${timer.category.label.toLowerCase()} • Chuẩn ${standardSeconds}s$staffSuffix$measuredSuffix';

    if (isCompact) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isOverStandard ? const Color(0xFFFFF5F5) : theme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverStandard
                ? AppColors.danger
                : (isRunning ? theme.border : AppColors.accent.withOpacity(0.5)),
            width: isOverStandard ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isOverStandard
                  ? AppColors.danger.withOpacity(0.14)
                  : theme.accent.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 5,
                child: Container(
                  color: isOverStandard ? AppColors.danger : theme.accent,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.badgeBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        theme.icon,
                        color: theme.accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: theme.badgeBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  theme.label.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: theme.badgeText,
                                    fontFamily: 'BeVietnamPro',
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'BeVietnamPro',
                                    color: AppColors.neutral,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'BeVietnamPro',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'BeVietnamPro',
                            color: isOverStandard
                                ? AppColors.danger
                                : (isRunning
                                    ? theme.stopwatchText
                                    : AppColors.accent),
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
                                color: isOverStandard
                                    ? AppColors.danger
                                    : (isRunning
                                        ? theme.accent
                                        : AppColors.accent),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOverStandard
                                  ? 'Quá chuẩn (+${overtimeSeconds}s)'
                                  : (isRunning ? 'Đang chạy' : 'Tạm dừng'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isOverStandard
                                    ? AppColors.danger
                                    : (isRunning
                                        ? theme.badgeText
                                        : AppColors.accent),
                                fontFamily: 'BeVietnamPro',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Full Card Mode
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isOverStandard ? const Color(0xFFFFF5F5) : theme.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverStandard
              ? AppColors.danger
              : (isRunning ? theme.border : AppColors.accent.withOpacity(0.5)),
          width: isOverStandard ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isOverStandard
                ? AppColors.danger.withOpacity(0.16)
                : theme.accent.withOpacity(0.09),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Left Category Color Bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: Container(
                color: isOverStandard ? AppColors.danger : theme.accent,
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: theme.badgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          theme.icon,
                          color: theme.accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: theme.badgeBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    theme.label.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: theme.badgeText,
                                      fontFamily: 'BeVietnamPro',
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'BeVietnamPro',
                                      color: AppColors.neutral,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isOverStandard
                              ? AppColors.danger.withOpacity(0.12)
                              : (isRunning
                                  ? theme.badgeBg
                                  : AppColors.accent.withOpacity(0.12)),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isOverStandard
                                ? AppColors.danger.withOpacity(0.35)
                                : (isRunning
                                    ? theme.border
                                    : AppColors.accent.withOpacity(0.35)),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOverStandard
                                    ? AppColors.danger
                                    : (isRunning
                                        ? theme.accent
                                        : AppColors.accent),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isOverStandard
                                  ? 'Quá chuẩn (+${overtimeSeconds}s)'
                                  : (isRunning ? 'Đang chạy' : 'Tạm dừng'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isOverStandard
                                    ? AppColors.danger
                                    : (isRunning
                                        ? theme.badgeText
                                        : AppColors.accent),
                                fontFamily: 'BeVietnamPro',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // "Chưa có mã đơn" badge + enter button (only for order timers without a code)
                  if (timer.category == PerformanceCategory.order &&
                      (timer.orderCode == null ||
                          timer.orderCode!.trim().isEmpty)) ...[
                    GestureDetector(
                      onTap: () => _showEnterOrderCodeDialog(context, ref),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFFD54F), width: 1.2),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFF9A825), size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chưa có mã đơn — Nhấn để nhập mã đơn hàng',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF795548),
                                  fontFamily: 'BeVietnamPro',
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: Color(0xFFF9A825), size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Central Stopwatch Display Box
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 10),
                      decoration: BoxDecoration(
                        color: isOverStandard
                            ? const Color(0xFFFEE2E2)
                            : theme.stopwatchBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isOverStandard
                              ? AppColors.danger.withOpacity(0.3)
                              : theme.border.withOpacity(0.8),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'BeVietnamPro',
                          color: isOverStandard
                              ? AppColors.danger
                              : (isRunning
                                  ? theme.stopwatchText
                                  : AppColors.accent),
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
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    final notifier =
                        ref.read(performanceTimerProvider.notifier);
                    final error = isRunning
                        ? await notifier.pauseTimer(timer.id)
                        : await notifier.resumeTimer(timer.id);
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 20,
                  ),
                  label: Text(isRunning ? 'Tạm dừng' : 'Tiếp tục'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isRunning ? AppColors.accent : AppColors.success,
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
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final error = await ref
                        .read(performanceTimerProvider.notifier)
                        .completeTimer(timer.id);
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: AppColors.danger,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
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
    ),
  ],
),
),
);
  }
}
