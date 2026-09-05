import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/performance_calculator.dart';
import '../../../models/performance_report_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reports/screens/staff_leaderboard_screen.dart';
import '../../session/providers/timer_service.dart';
import '../../owner/screens/report_detail_screen.dart';

class SessionHistoryTab extends ConsumerWidget {
  const SessionHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeId = ref.watch(currentStoreIdProvider);
    final repo = ref.watch(performanceRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral,
        elevation: 0,
        title: const Text(
          'LỊCH SỬ PHIÊN ĐO',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            fontFamily: 'BeVietnamPro',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_rounded, color: AppColors.primary),
            tooltip: 'Bảng xếp hạng hiệu suất',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaffLeaderboardScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: storeId == null || storeId.isEmpty
          ? const Center(child: Text('Vui lòng chọn cửa hàng'))
          : StreamBuilder<List<PerformanceReportModel>>(
              stream: repo.watchReportsForStore(storeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Lỗi tải lịch sử: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.danger, fontFamily: 'BeVietnamPro'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final reports = snapshot.data ?? [];
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có lịch sử phiên đo nào.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'BeVietnamPro',
                            color: AppColors.neutral,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final dateFmt = DateFormat('dd/MM/yyyy');
                final timeFmt = DateFormat('HH:mm');

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final dateStr = dateFmt.format(report.startedAt);
                    final timeStr = '${timeFmt.format(report.startedAt)} – ${timeFmt.format(report.endedAt)}';

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailScreen(report: report),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
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
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.assessment_rounded, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        report.storeName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'BeVietnamPro',
                                        ),
                                      ),
                                      Text(
                                        '$dateStr • $timeStr',
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: report.isViewed ? Colors.grey.shade100 : AppColors.accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    report.status.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: report.isViewed ? Colors.grey.shade600 : AppColors.accent,
                                      fontFamily: 'BeVietnamPro',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Icon(Icons.badge_rounded, size: 14, color: AppColors.info),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'QL: ${report.managerOnDutyName}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'BeVietnamPro',
                                      color: AppColors.neutral,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${report.employeeNames.length} nhân sự',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'BeVietnamPro',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _MiniMetric(
                                    label: 'Nước',
                                    value: PerformanceCalculator.formatSeconds(report.drinkAverageSeconds),
                                  ),
                                  Container(width: 1, height: 20, color: AppColors.border),
                                  _MiniMetric(
                                    label: 'Bánh',
                                    value: PerformanceCalculator.formatSeconds(report.cakeAverageSeconds),
                                  ),
                                  Container(width: 1, height: 20, color: AppColors.border),
                                  _MiniMetric(
                                    label: 'Đơn',
                                    value: PerformanceCalculator.formatSeconds(report.orderAverageSeconds),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.neutral, fontFamily: 'BeVietnamPro'),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, fontFamily: 'BeVietnamPro', color: AppColors.neutral),
        ),
      ],
    );
  }
}
