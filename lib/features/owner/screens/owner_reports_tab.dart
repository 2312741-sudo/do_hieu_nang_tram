import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/performance_calculator.dart';
import '../../../models/performance_report_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reports/screens/staff_leaderboard_screen.dart';
import '../../session/providers/timer_service.dart';
import 'report_detail_screen.dart';
import 'store_performance_settings_screen.dart';
import '../widgets/delete_measurement_data_dialog.dart';

class OwnerReportsTab extends ConsumerStatefulWidget {
  const OwnerReportsTab({super.key});

  @override
  ConsumerState<OwnerReportsTab> createState() => _OwnerReportsTabState();
}

class _OwnerReportsTabState extends ConsumerState<OwnerReportsTab> {
  String? _selectedStoreId;
  String? _selectedManagerId;
  String _dateFilter = 'all'; // 'all', 'today', '7days'
  String _statusFilter = 'all'; // 'all', 'unviewed', 'viewed'

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(userStoresProvider);
    final stores = storesAsync.valueOrNull ?? [];
    final currentStore = ref.watch(currentStoreProvider).valueOrNull;

    // Tự động gán store mặc định nếu chưa chọn
    if (_selectedStoreId == null && stores.isNotEmpty) {
      if (stores.length == 1) {
        _selectedStoreId = stores.first.id;
      } else if (currentStore != null && stores.any((s) => s.id == currentStore.id)) {
        _selectedStoreId = currentStore.id;
      } else {
        _selectedStoreId = '__all__';
      }
    }

    final repo = ref.watch(performanceRepositoryProvider);
    final Stream<List<PerformanceReportModel>> reportsStream;
    if (_selectedStoreId == '__all__') {
      reportsStream = repo.watchReportsForStores(stores.map((s) => s.id).toList());
    } else if (_selectedStoreId != null) {
      reportsStream = repo.watchReportsForStore(_selectedStoreId!);
    } else {
      reportsStream = Stream.value([]);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral,
        elevation: 0,
        title: const Text(
          'BÁO CÁO HIỆU NĂNG',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            fontFamily: 'BeVietnamPro',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger),
            tooltip: 'Xóa dữ liệu đo lường',
            onPressed: () => DeleteMeasurementDataDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.neutral),
            tooltip: 'Cài đặt tiêu chuẩn & biểu mẫu',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const StorePerformanceSettingsScreen(),
                ),
              );
            },
          ),
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
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              children: [
                // Store & Manager Dropdowns
                Row(
                  children: [
                    // Store Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: (_selectedStoreId == '__all__' || stores.any((s) => s.id == _selectedStoreId))
                                ? _selectedStoreId
                                : (stores.length > 1 ? '__all__' : (stores.isNotEmpty ? stores.first.id : null)),
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            items: [
                              if (stores.length > 1)
                                DropdownMenuItem(
                                  value: '__all__',
                                  child: Text(
                                    '🏢 Tất cả cơ sở (${stores.length})',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'BeVietnamPro',
                                      color: AppColors.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ...stores.map((s) {
                                return DropdownMenuItem(
                                  value: s.id,
                                  child: Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'BeVietnamPro',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedStoreId = val;
                                _selectedManagerId = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Date Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _dateFilter,
                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Tất cả ngày', style: TextStyle(fontSize: 13, fontFamily: 'BeVietnamPro'))),
                            DropdownMenuItem(value: 'today', child: Text('Hôm nay', style: TextStyle(fontSize: 13, fontFamily: 'BeVietnamPro'))),
                            DropdownMenuItem(value: '7days', child: Text('7 ngày qua', style: TextStyle(fontSize: 13, fontFamily: 'BeVietnamPro'))),
                          ],
                          onChanged: (val) => setState(() => _dateFilter = val ?? 'all'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Status Filter Pills
                Row(
                  children: [
                    _StatusPill(
                      label: 'Tất cả',
                      isSelected: _statusFilter == 'all',
                      onTap: () => setState(() => _statusFilter = 'all'),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(
                      label: 'Chưa xem',
                      isSelected: _statusFilter == 'unviewed',
                      onTap: () => setState(() => _statusFilter = 'unviewed'),
                      isAccent: true,
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(
                      label: 'Đã xem',
                      isSelected: _statusFilter == 'viewed',
                      onTap: () => setState(() => _statusFilter = 'viewed'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Reports List Stream
          Expanded(
            child: StreamBuilder<List<PerformanceReportModel>>(
              stream: reportsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Lỗi tải danh sách báo cáo: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.danger, fontFamily: 'BeVietnamPro'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                var reports = snapshot.data ?? [];

                // Filter by Manager on duty
                if (_selectedManagerId != null) {
                  reports = reports.where((r) => r.managerOnDutyId == _selectedManagerId).toList();
                }

                // Filter by Date
                final now = DateTime.now();
                if (_dateFilter == 'today') {
                  reports = reports.where((r) =>
                    r.startedAt.year == now.year &&
                    r.startedAt.month == now.month &&
                    r.startedAt.day == now.day
                  ).toList();
                } else if (_dateFilter == '7days') {
                  final sevenDaysAgo = now.subtract(const Duration(days: 7));
                  reports = reports.where((r) => r.startedAt.isAfter(sevenDaysAgo)).toList();
                }

                // Filter by Status
                if (_statusFilter == 'unviewed') {
                  reports = reports.where((r) => !r.isViewed).toList();
                } else if (_statusFilter == 'viewed') {
                  reports = reports.where((r) => r.isViewed).toList();
                }

                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Không tìm thấy báo cáo phù hợp.',
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
                          border: Border.all(
                            color: report.isViewed ? Colors.transparent : AppColors.primary.withOpacity(0.3),
                            width: report.isViewed ? 0 : 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'BeVietnamPro',
                                      color: AppColors.neutral,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: report.isViewed ? Colors.grey.shade100 : AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!report.isViewed) ...[
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                      Text(
                                        report.status.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: report.isViewed ? Colors.grey.shade600 : AppColors.primary,
                                          fontFamily: 'BeVietnamPro',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person_rounded, size: 14, color: AppColors.info),
                                const SizedBox(width: 6),
                                Text(
                                  'QL: ${report.managerOnDutyName}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'BeVietnamPro',
                                    color: AppColors.neutral,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$dateStr  $timeStr',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'BeVietnamPro',
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _ReportStat(
                                  label: 'Nước',
                                  avg: PerformanceCalculator.formatSeconds(report.drinkAverageSeconds),
                                  total: '${report.drinkTotalQuantity} ly',
                                ),
                                Container(width: 1, height: 28, color: AppColors.border),
                                _ReportStat(
                                  label: 'Bánh',
                                  avg: PerformanceCalculator.formatSeconds(report.cakeAverageSeconds),
                                  total: '${report.cakeTotalQuantity} bánh',
                                ),
                                Container(width: 1, height: 28, color: AppColors.border),
                                _ReportStat(
                                  label: 'Đơn',
                                  avg: PerformanceCalculator.formatSeconds(report.orderAverageSeconds),
                                  total: '${report.orderCount} đơn',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAccent;

  const _StatusPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isAccent ? AppColors.primary : AppColors.neutral)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'BeVietnamPro',
          ),
        ),
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String label;
  final String avg;
  final String total;

  const _ReportStat({required this.label, required this.avg, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.neutral, fontFamily: 'BeVietnamPro'),
        ),
        Text(
          avg,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, fontFamily: 'BeVietnamPro', color: AppColors.neutral),
        ),
        Text(
          total,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontFamily: 'BeVietnamPro'),
        ),
      ],
    );
  }
}
