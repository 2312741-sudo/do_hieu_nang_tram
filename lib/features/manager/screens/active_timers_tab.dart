import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/performance_calculator.dart';
import '../../../models/measurement_model.dart';
import '../../session/providers/timer_service.dart';
import '../widgets/timer_card.dart';

class ActiveTimersTab extends ConsumerStatefulWidget {
  const ActiveTimersTab({super.key});

  @override
  ConsumerState<ActiveTimersTab> createState() => _ActiveTimersTabState();
}

class _ActiveTimersTabState extends ConsumerState<ActiveTimersTab> {
  PerformanceCategory? _selectedCategory; // null = Tất cả

  @override
  Widget build(BuildContext context) {
    ref.watch(performanceTimerProvider);
    final allMeasurements = ref.watch(sessionMeasurementsProvider).valueOrNull ?? [];
    final activeTimers = allMeasurements.where((m) => m.status.isActive).toList();

    final drinkCount = activeTimers.where((m) => m.category == PerformanceCategory.drink).length;
    final cakeCount = activeTimers.where((m) => m.category == PerformanceCategory.cake).length;
    final orderCount = activeTimers.where((m) => m.category == PerformanceCategory.order).length;

    final filteredTimers = _selectedCategory == null
        ? activeTimers
        : activeTimers.where((m) => m.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // Header — Navy style
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1C4E6B), Color(0xFF0A3247)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ĐANG ĐO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'BeVietnamPro',
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activeTimers.length} timer đang hoạt động đồng thời',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFamily: 'BeVietnamPro',
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterPill(
                              label: 'Tất cả (${activeTimers.length})',
                              isSelected: _selectedCategory == null,
                              onTap: () => setState(() => _selectedCategory = null),
                            ),
                            const SizedBox(width: 8),
                            _FilterPill(
                              label: 'Nước ($drinkCount)',
                              isSelected: _selectedCategory == PerformanceCategory.drink,
                              onTap: () => setState(() => _selectedCategory = PerformanceCategory.drink),
                            ),
                            const SizedBox(width: 8),
                            _FilterPill(
                              label: 'Bánh ($cakeCount)',
                              isSelected: _selectedCategory == PerformanceCategory.cake,
                              onTap: () => setState(() => _selectedCategory = PerformanceCategory.cake),
                            ),
                            const SizedBox(width: 8),
                            _FilterPill(
                              label: 'Đơn ($orderCount)',
                              isSelected: _selectedCategory == PerformanceCategory.order,
                              onTap: () => setState(() => _selectedCategory = PerformanceCategory.order),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Timer list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: filteredTimers.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.timer_off_outlined, size: 52, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'Không có timer nào đang chạy',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'BeVietnamPro',
                              color: AppColors.neutral,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Vào tab Tổng quan hoặc từng mục để bắt đầu đo.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontFamily: 'BeVietnamPro',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedCategory == null) ...[
                          // Grouped display
                          if (drinkCount > 0) ...[
                            _SectionGroupTitle(title: 'NƯỚC ($drinkCount)'),
                            ...activeTimers
                                .where((m) => m.category == PerformanceCategory.drink)
                                .map((t) => TimerCard(
                                      timer: t,
                                      itemNumber: PerformanceCalculator.getCategorySequenceNumber(t, allMeasurements),
                                    )),
                            const SizedBox(height: 16),
                          ],
                          if (cakeCount > 0) ...[
                            _SectionGroupTitle(title: 'BÁNH ($cakeCount)'),
                            ...activeTimers
                                .where((m) => m.category == PerformanceCategory.cake)
                                .map((t) => TimerCard(
                                      timer: t,
                                      itemNumber: PerformanceCalculator.getCategorySequenceNumber(t, allMeasurements),
                                    )),
                            const SizedBox(height: 16),
                          ],
                          if (orderCount > 0) ...[
                            _SectionGroupTitle(title: 'ĐƠN HÀNG ($orderCount)'),
                            ...activeTimers
                                .where((m) => m.category == PerformanceCategory.order)
                                .map((t) => TimerCard(
                                      timer: t,
                                      itemNumber: PerformanceCalculator.getCategorySequenceNumber(t, allMeasurements),
                                    )),
                          ],
                        ] else ...[
                          ...filteredTimers.map((t) => TimerCard(
                                timer: t,
                                itemNumber: PerformanceCalculator.getCategorySequenceNumber(t, allMeasurements),
                              )),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionGroupTitle extends StatelessWidget {
  final String title;

  const _SectionGroupTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          fontFamily: 'BeVietnamPro',
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white30,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.neutral : Colors.white,
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontFamily: 'BeVietnamPro',
          ),
        ),
      ),
    );
  }
}
