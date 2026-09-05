import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/excel_export_service.dart';
import '../../../core/utils/performance_calculator.dart';
import '../../../models/performance_report_model.dart';
import '../../../models/store_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../session/providers/timer_service.dart';

enum LeaderboardDateFilter {
  today,
  last7Days,
  thisMonth,
  lastMonth,
  custom,
  all,
}

extension LeaderboardDateFilterExtension on LeaderboardDateFilter {
  String get label {
    switch (this) {
      case LeaderboardDateFilter.today:
        return 'Hôm nay';
      case LeaderboardDateFilter.last7Days:
        return '7 ngày qua';
      case LeaderboardDateFilter.thisMonth:
        return 'Tháng này';
      case LeaderboardDateFilter.lastMonth:
        return 'Tháng trước';
      case LeaderboardDateFilter.custom:
        return 'Tùy chọn';
      case LeaderboardDateFilter.all:
        return 'Tất cả';
    }
  }
}

class StaffLeaderboardScreen extends ConsumerStatefulWidget {
  const StaffLeaderboardScreen({super.key});

  @override
  ConsumerState<StaffLeaderboardScreen> createState() => _StaffLeaderboardScreenState();
}

class _StaffLeaderboardScreenState extends ConsumerState<StaffLeaderboardScreen>
    with SingleTickerProviderStateMixin {
  LeaderboardDateFilter _selectedFilter = LeaderboardDateFilter.thisMonth;
  DateTimeRange? _customDateRange;
  late TabController _tabController;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<PerformanceReportModel> _filterReports(List<PerformanceReportModel> allReports) {
    final now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedFilter) {
      case LeaderboardDateFilter.today:
        start = DateTime(now.year, now.month, now.day, 0, 0, 0);
        break;
      case LeaderboardDateFilter.last7Days:
        start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        break;
      case LeaderboardDateFilter.thisMonth:
        start = DateTime(now.year, now.month, 1, 0, 0, 0);
        break;
      case LeaderboardDateFilter.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        start = DateTime(lastMonth.year, lastMonth.month, 1, 0, 0, 0);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case LeaderboardDateFilter.custom:
        if (_customDateRange != null) {
          start = DateTime(
            _customDateRange!.start.year,
            _customDateRange!.start.month,
            _customDateRange!.start.day,
            0,
            0,
            0,
          );
          end = DateTime(
            _customDateRange!.end.year,
            _customDateRange!.end.month,
            _customDateRange!.end.day,
            23,
            59,
            59,
          );
        } else {
          start = DateTime(now.year, now.month, 1);
        }
        break;
      case LeaderboardDateFilter.all:
        return allReports;
    }

    return allReports.where((r) {
      final date = r.startedAt;
      return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.neutral,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = LeaderboardDateFilter.custom;
      });
    }
  }

  String _getDateFilterSubtitle() {
    final df = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    switch (_selectedFilter) {
      case LeaderboardDateFilter.today:
        return 'Hôm nay: ${df.format(now)}';
      case LeaderboardDateFilter.last7Days:
        final start = now.subtract(const Duration(days: 6));
        return '${df.format(start)} - ${df.format(now)}';
      case LeaderboardDateFilter.thisMonth:
        return 'Tháng ${now.month}/${now.year}';
      case LeaderboardDateFilter.lastMonth:
        final last = DateTime(now.year, now.month - 1, 1);
        return 'Tháng ${last.month}/${last.year}';
      case LeaderboardDateFilter.custom:
        if (_customDateRange != null) {
          return '${df.format(_customDateRange!.start)} - ${df.format(_customDateRange!.end)}';
        }
        return 'Tùy chọn';
      case LeaderboardDateFilter.all:
        return 'Tất cả các phiên đo';
    }
  }

  Future<void> _handleExportExcel({
    required StoreModel store,
    required List<StaffPerformanceStats> statsList,
    required String dateRangeLabel,
  }) async {
    setState(() => _isExporting = true);
    try {
      await ExcelExportService.exportLeaderboardReport(
        store: store,
        statsList: statsList,
        dateRangeLabel: dateRangeLabel,
        context: context,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất Excel: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(currentStoreProvider).valueOrNull;
    final repo = ref.watch(performanceRepositoryProvider);

    if (store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bảng Xếp Hạng Hiệu Suất')),
        body: const Center(child: Text('Vui lòng chọn cửa hàng.')),
      );
    }

    final std = store.performanceStandards;
    final reportsStream = repo.watchReportsForStore(store.id);

    return StreamBuilder<List<PerformanceReportModel>>(
      stream: reportsStream,
      builder: (context, snapshot) {
        final allReports = snapshot.data ?? [];
        final filteredReports = _filterReports(allReports);

        final leaderboardStats = PerformanceCalculator.calculateStaffLeaderboard(
          reports: filteredReports,
          drinkStandardSeconds: std.drinkStandardSeconds,
          cakeStandardSeconds: std.cakeStandardSeconds,
        );

        final dateSubtitle = _getDateFilterSubtitle();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.neutral, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'BẢNG XẾP HẠNG HIỆU SUẤT',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFamily: 'BeVietnamPro',
                color: AppColors.neutral,
                letterSpacing: 0.3,
              ),
            ),
            actions: [
              if (_isExporting)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Xuất Excel',
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF107C41).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.table_view_rounded, color: Color(0xFF107C41), size: 18),
                  ),
                  onPressed: leaderboardStats.isEmpty
                      ? null
                      : () => _handleExportExcel(
                            store: store,
                            statsList: leaderboardStats,
                            dateRangeLabel: dateSubtitle,
                          ),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'BeVietnamPro',
                  ),
                  tabs: const [
                    Tab(text: '🏆 TỔNG HỢP'),
                    Tab(text: '🥤 NƯỚC'),
                    Tab(text: '🍰 BÁNH'),
                  ],
                ),
              ),
            ),
          ),
          body: Column(
            children: [
              // Filter bar
              _buildFilterBar(),

              // Benchmark Summary Pill
              _buildBenchmarkHeader(std, filteredReports.length),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Tổng hợp
                    _buildLeaderboardTabContent(
                      statsList: leaderboardStats,
                      mode: _LeaderboardViewMode.overall,
                      std: std,
                    ),
                    // Tab 2: Nước
                    _buildLeaderboardTabContent(
                      statsList: leaderboardStats.where((s) => s.drinkQuantity > 0).toList(),
                      mode: _LeaderboardViewMode.drink,
                      std: std,
                    ),
                    // Tab 3: Bánh
                    _buildLeaderboardTabContent(
                      statsList: leaderboardStats.where((s) => s.cakeQuantity > 0).toList(),
                      mode: _LeaderboardViewMode.cake,
                      std: std,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: LeaderboardDateFilter.values.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(
                  filter == LeaderboardDateFilter.custom && _customDateRange != null
                      ? '${DateFormat('dd/MM').format(_customDateRange!.start)} - ${DateFormat('dd/MM').format(_customDateRange!.end)}'
                      : filter.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontFamily: 'BeVietnamPro',
                    color: isSelected ? Colors.white : AppColors.neutral,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                onSelected: (val) {
                  if (filter == LeaderboardDateFilter.custom) {
                    _pickCustomRange();
                  } else {
                    setState(() => _selectedFilter = filter);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBenchmarkHeader(StorePerformanceStandards std, int sessionCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getDateFilterSubtitle(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'BeVietnamPro',
                        color: AppColors.neutral,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$sessionCount ca',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontFamily: 'BeVietnamPro',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Chuẩn: Nước ${std.drinkStandardSeconds}s | Bánh ${std.cakeStandardSeconds}s',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'BeVietnamPro'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTabContent({
    required List<StaffPerformanceStats> statsList,
    required _LeaderboardViewMode mode,
    required StorePerformanceStandards std,
  }) {
    if (statsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu hiệu suất trong khoảng thời gian này',
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade600, fontFamily: 'BeVietnamPro'),
            ),
          ],
        ),
      );
    }

    // Sort depending on mode
    final sortedList = List<StaffPerformanceStats>.from(statsList);
    if (mode == _LeaderboardViewMode.drink) {
      sortedList.sort((a, b) {
        final aEff = a.drinkEfficiencyPercent ?? 0;
        final bEff = b.drinkEfficiencyPercent ?? 0;
        return bEff.compareTo(aEff);
      });
    } else if (mode == _LeaderboardViewMode.cake) {
      sortedList.sort((a, b) {
        final aEff = a.cakeEfficiencyPercent ?? 0;
        final bEff = b.cakeEfficiencyPercent ?? 0;
        return bEff.compareTo(aEff);
      });
    } else {
      sortedList.sort((a, b) => b.totalEfficiencyPercent.compareTo(a.totalEfficiencyPercent));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      children: [
        // Podium Top 3 (if overall mode and >= 2 staff)
        if (mode == _LeaderboardViewMode.overall && sortedList.length >= 2)
          _buildPodium(sortedList.take(3).toList()),

        const SizedBox(height: 10),

        // List of staff
        ...sortedList.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final stat = entry.value;
          return _buildStaffItemCard(stat: stat, rank: rank, mode: mode);
        }),
      ],
    );
  }

  Widget _buildPodium(List<StaffPerformanceStats> top3) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1C4E6B).withOpacity(0.08),
            const Color(0xFF22876D).withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            '🌟 TOP NHÂN SỰ XUẤT SẮC NHẤT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'BeVietnamPro',
              color: AppColors.neutral,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // #2 Silver
              if (top3.length > 1)
                _buildPodiumPillar(
                  stat: top3[1],
                  rank: 2,
                  color: const Color(0xFF94A3B8),
                  height: 90,
                  medal: '🥈',
                ),

              // #1 Gold
              if (top3.isNotEmpty)
                _buildPodiumPillar(
                  stat: top3[0],
                  rank: 1,
                  color: const Color(0xFFEAB308),
                  height: 115,
                  medal: '🥇',
                ),

              // #3 Bronze
              if (top3.length > 2)
                _buildPodiumPillar(
                  stat: top3[2],
                  rank: 3,
                  color: const Color(0xFFD97706),
                  height: 75,
                  medal: '🥉',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPillar({
    required StaffPerformanceStats stat,
    required int rank,
    required Color color,
    required double height,
    required String medal,
  }) {
    return Column(
      children: [
        Text(medal, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Container(
          constraints: const BoxConstraints(maxWidth: 90),
          child: Text(
            stat.staffName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'BeVietnamPro',
              color: AppColors.neutral,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${stat.totalEfficiencyPercent.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            fontFamily: 'BeVietnamPro',
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 75,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontFamily: 'BeVietnamPro',
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffItemCard({
    required StaffPerformanceStats stat,
    required int rank,
    required _LeaderboardViewMode mode,
  }) {
    Color rankColor = Colors.grey.shade700;
    Widget rankBadge;

    if (rank == 1) {
      rankColor = const Color(0xFFEAB308);
      rankBadge = const Text('🥇', style: TextStyle(fontSize: 20));
    } else if (rank == 2) {
      rankColor = const Color(0xFF94A3B8);
      rankBadge = const Text('🥈', style: TextStyle(fontSize: 20));
    } else if (rank == 3) {
      rankColor = const Color(0xFFD97706);
      rankBadge = const Text('🥉', style: TextStyle(fontSize: 20));
    } else {
      rankBadge = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
              fontFamily: 'BeVietnamPro',
            ),
          ),
        ),
      );
    }

    double effPercent = stat.totalEfficiencyPercent;
    if (mode == _LeaderboardViewMode.drink) {
      effPercent = stat.drinkEfficiencyPercent ?? 0.0;
    } else if (mode == _LeaderboardViewMode.cake) {
      effPercent = stat.cakeEfficiencyPercent ?? 0.0;
    }

    Color effColor = const Color(0xFF16A34A);
    if (effPercent < 80.0) {
      effColor = Colors.red.shade600;
    } else if (effPercent < 95.0) {
      effColor = const Color(0xFFD97706);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank <= 3 ? rankColor.withOpacity(0.4) : AppColors.border,
          width: rank <= 3 ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              rankBadge,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.staffName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'BeVietnamPro',
                        color: AppColors.neutral,
                      ),
                    ),
                    Text(
                      '${stat.sessionCount} ca làm việc • ${stat.totalProducts} món',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontFamily: 'BeVietnamPro'),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${effPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'BeVietnamPro',
                      color: effColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: effColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      stat.performanceRating,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'BeVietnamPro',
                        color: effColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Detail Grid (Nước & Bánh)
          Row(
            children: [
              // Nước
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_cafe_rounded, size: 13, color: Color(0xFF0284C7)),
                          SizedBox(width: 4),
                          Text(
                            'NƯỚC',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0284C7),
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (stat.drinkQuantity > 0) ...[
                        Text(
                          '${stat.drinkQuantity} ly • TB ${stat.drinkAverageSeconds}s',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.neutral),
                        ),
                        Text(
                          'Hiệu suất: ${(stat.drinkEfficiencyPercent ?? 0).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                        ),
                      ] else ...[
                        const Text(
                          'Chưa phụ trách',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Bánh
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD97706).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cake_rounded, size: 13, color: Color(0xFFD97706)),
                          SizedBox(width: 4),
                          Text(
                            'BÁNH',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (stat.cakeQuantity > 0) ...[
                        Text(
                          '${stat.cakeQuantity} bánh • TB ${stat.cakeAverageSeconds}s',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.neutral),
                        ),
                        Text(
                          'Hiệu suất: ${(stat.cakeEfficiencyPercent ?? 0).toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                        ),
                      ] else ...[
                        const Text(
                          'Chưa phụ trách',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _LeaderboardViewMode {
  overall,
  drink,
  cake,
}
