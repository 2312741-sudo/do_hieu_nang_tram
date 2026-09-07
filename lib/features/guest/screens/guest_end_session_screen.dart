import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/performance_calculator.dart';
import '../models/guest_session_model.dart';
import '../models/guest_measurement_model.dart';
import '../providers/guest_providers.dart';

class GuestEndSessionScreen extends ConsumerWidget {
  const GuestEndSessionScreen({super.key});

  String _formatTime(int seconds) {
    try {
      return PerformanceCalculator.formatSeconds(seconds);
    } catch (_) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSession = ref.watch(guestActiveSessionProvider);
    final allMeasurements = ref.watch(guestSessionMeasurementsProvider);

    if (activeSession == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Kết thúc phiên',
            style: TextStyle(fontFamily: 'BeVietnamPro'),
          ),
        ),
        body: const Center(
          child: Text(
            'Không tìm thấy phiên đo hiện tại',
            style: TextStyle(fontFamily: 'BeVietnamPro'),
          ),
        ),
      );
    }

    final summarySession = activeSession.recomputeSummary(allMeasurements);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.neutral),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kết thúc phiên đo',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.neutral,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPersonnelSummary(summarySession),
            const SizedBox(height: 20),
            const Text(
              'TỔNG QUAN KẾT QUẢ',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Nước',
              count: summarySession.drinkCount,
              quantity: summarySession.drinkTotalQuantity,
              unit: 'nước',
              avgTime: _formatTime(summarySession.drinkAverageSeconds),
              icon: Icons.local_cafe_rounded,
              color: const Color(0xFF0284C7),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Bánh',
              count: summarySession.cakeCount,
              quantity: summarySession.cakeTotalQuantity,
              unit: 'bánh',
              avgTime: _formatTime(summarySession.cakeAverageSeconds),
              icon: Icons.cake_rounded,
              color: const Color(0xFFD97706),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              title: 'Đơn hàng',
              count: summarySession.orderCount,
              quantity: null,
              unit: 'đơn',
              avgTime: _formatTime(summarySession.orderAverageSeconds),
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF1C4E6B),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neutral,
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'QUAY LẠI',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _endSession(context, ref, summarySession, allMeasurements),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'KẾT THÚC PHIÊN',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonnelSummary(GuestSessionModel session) {
    return Card(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.badge_rounded, color: AppColors.info, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  'Quản lý đứng ca: ${session.managerOnDutyLabel}',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: AppColors.neutral,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people_alt_rounded, color: AppColors.accent, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhân viên trong ca (${session.employeeLabels.length}):',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (session.employeeLabels.isEmpty)
                        const Text(
                          'Chưa phân công',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: AppColors.textDisabled,
                            fontSize: 12,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: session.employeeLabels.map((name) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  color: AppColors.neutral,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    int? quantity,
    required String unit,
    required String avgTime,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.neutral,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quantity != null
                      ? '$count lần • $quantity $unit'
                      : '$count $unit',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'TB / món',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                avgTime,
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: AppColors.neutral,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _endSession(
    BuildContext context,
    WidgetRef ref,
    GuestSessionModel session,
    List<GuestMeasurementModel> measurements,
  ) async {
    // 1. Finalize session
    final updatedSession = session.copyWith(
      endedAt: DateTime.now(),
      status: GuestSessionStatus.completed,
    );

    // 2. Save to history
    final repo = ref.read(guestLocalRepositoryProvider);
    await repo.addToHistory(updatedSession);
    await repo.saveMeasurements(updatedSession.id, measurements);

    // 3. Clear active
    await repo.clearActiveSession();
    await repo.clearActiveTimers();
    await ref.read(guestTimerProvider.notifier).clearAllTimers();

    ref.read(guestActiveSessionProvider.notifier).state = null;
    ref.read(guestSessionMeasurementsProvider.notifier).state = [];
    ref.invalidate(guestHistoryProvider);

    // 4. Navigate to result
    if (context.mounted) {
      context.go('/guest-result', extra: updatedSession);
    }
  }
}
