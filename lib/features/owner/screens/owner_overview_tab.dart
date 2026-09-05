import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/performance_calculator.dart';
import '../../../core/widgets/custom_header.dart';
import '../../../models/performance_report_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reports/screens/staff_leaderboard_screen.dart';
import '../../session/providers/timer_service.dart';
import 'report_detail_screen.dart';
import 'store_performance_settings_screen.dart';

class OwnerOverviewTab extends ConsumerWidget {
  final VoidCallback onNavigateToReports;

  const OwnerOverviewTab({super.key, required this.onNavigateToReports});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final store = ref.watch(currentStoreProvider).valueOrNull;
    final repo = ref.watch(performanceRepositoryProvider);

    final reportsStream = store != null
        ? repo.watchReportsForStore(store.id)
        : repo.watchAllReports();

    final firstName = user?.name.split(' ').last ?? 'Chủ quán';
    final dateFmt = DateFormat('dd/MM/yyyy');
    final timeFmt = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: CustomHeader(
              title: AppStrings.appName.toUpperCase(),
              subtitle: firstName,
              storeName: store?.name,
              isNavy: true,
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<List<PerformanceReportModel>>(
                stream: reportsStream,
                builder: (context, snapshot) {
                  final reports = snapshot.data ?? [];
                  final unviewedReports = reports.where((r) => !r.isViewed).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Action Cards
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const StaffLeaderboardScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1C4E6B), Color(0xFF26668B)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x181C4E6B), blurRadius: 10, offset: Offset(0, 4)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 22),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'BXH Hiệu Suất',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'BeVietnamPro',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Nước • Bánh • Tổng',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 11.5,
                                        fontFamily: 'BeVietnamPro',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const StorePerformanceSettingsScreen(),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: const [
                                    BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Cài Đặt Tiêu Chuẩn',
                                      style: TextStyle(
                                        color: AppColors.neutral,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'BeVietnamPro',
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Thời gian & Biểu mẫu',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.5,
                                        fontFamily: 'BeVietnamPro',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section: Báo Cáo Mới
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'BÁO CÁO MỚI',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'BeVietnamPro',
                                  color: AppColors.neutral,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          if (reports.isNotEmpty)
                            TextButton(
                              onPressed: onNavigateToReports,
                              child: const Text(
                                'Xem tất cả >',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'BeVietnamPro',
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (unviewedReports.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.mark_email_read_outlined, size: 44, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              const Text(
                                'Không có báo cáo mới chưa xem.',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'BeVietnamPro',
                                  color: AppColors.neutral,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Các báo cáo hiệu năng mới nhất sẽ hiển thị ngay khi Quản lý nộp.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'BeVietnamPro',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        ...unviewedReports.take(3).map((report) {
                          final dateStr = dateFmt.format(report.startedAt);
                          final timeStr = '${timeFmt.format(report.startedAt)} – ${timeFmt.format(report.endedAt)}';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        report.storeName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'BeVietnamPro',
                                          color: AppColors.neutral,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.fiber_manual_record, size: 8, color: AppColors.primary),
                                          SizedBox(width: 4),
                                          Text(
                                            'Chưa xem',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                              fontFamily: 'BeVietnamPro',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.person_rounded, size: 15, color: AppColors.info),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Quản lý: ${report.managerOnDutyName}',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'BeVietnamPro',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$dateStr  $timeStr',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary,
                                        fontFamily: 'BeVietnamPro',
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),

                                // Metric Pills
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _MiniStat(
                                      label: 'Nước',
                                      val: PerformanceCalculator.formatSeconds(report.drinkAverageSeconds),
                                    ),
                                    _MiniStat(
                                      label: 'Bánh',
                                      val: PerformanceCalculator.formatSeconds(report.cakeAverageSeconds),
                                    ),
                                    _MiniStat(
                                      label: 'Đơn',
                                      val: PerformanceCalculator.formatSeconds(report.orderAverageSeconds),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReportDetailScreen(report: report),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 44),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 1,
                                  ),
                                  child: const Text(
                                    'XEM BÁO CÁO',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'BeVietnamPro',
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 24),

                      // System Summary Metrics
                      const Text(
                        'TỔNG QUAN HỆ THỐNG',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.neutral,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _SummaryBox(
                              title: 'Tổng số báo cáo',
                              value: '${reports.length}',
                              icon: Icons.assignment_rounded,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SummaryBox(
                              title: 'Chưa xem',
                              value: '${unviewedReports.length}',
                              icon: Icons.markunread_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String val;

  const _MiniStat({required this.label, required this.val});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.neutral, fontFamily: 'BeVietnamPro')),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.neutral, fontFamily: 'BeVietnamPro')),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'BeVietnamPro',
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'BeVietnamPro',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
