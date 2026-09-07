import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../models/guest_measurement_model.dart';
import '../providers/guest_providers.dart';

class GuestActiveTimersTab extends ConsumerStatefulWidget {
  const GuestActiveTimersTab({super.key});

  @override
  ConsumerState<GuestActiveTimersTab> createState() => _GuestActiveTimersTabState();
}

class _GuestActiveTimersTabState extends ConsumerState<GuestActiveTimersTab> {
  String _selectedFilter = 'Tất cả';

  void _showAddTimerBottomSheet() {
    final session = ref.read(guestActiveSessionProvider);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa có phiên đo nào đang diễn ra',
            style: TextStyle(fontFamily: 'BeVietnamPro'),
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _AddTimerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(guestTimerProvider);
    final activeMeasurements = timerState.activeTimers;

    List<GuestMeasurementModel> filteredList = activeMeasurements;
    if (_selectedFilter == 'Nước') {
      filteredList = activeMeasurements
          .where((m) => m.category == PerformanceCategory.drink)
          .toList();
    } else if (_selectedFilter == 'Bánh') {
      filteredList = activeMeasurements
          .where((m) => m.category == PerformanceCategory.cake)
          .toList();
    } else if (_selectedFilter == 'Đơn') {
      filteredList = activeMeasurements
          .where((m) => m.category == PerformanceCategory.order)
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Đồng hồ đang đo',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.neutral,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final measurement = filteredList[index];
                      return _GuestTimerCard(
                        measurement: measurement,
                        onPause: () {
                          ref
                              .read(guestTimerProvider.notifier)
                              .pauseTimer(measurement.id);
                        },
                        onResume: () {
                          ref
                              .read(guestTimerProvider.notifier)
                              .resumeTimer(measurement.id);
                        },
                        onComplete: () async {
                          final completed = await ref
                              .read(guestTimerProvider.notifier)
                              .completeTimer(measurement.id);
                          if (completed != null) {
                            final session = ref.read(guestActiveSessionProvider);
                            if (session != null) {
                              final list = List<GuestMeasurementModel>.from(
                                ref.read(guestSessionMeasurementsProvider),
                              );
                              final idx = list.indexWhere((m) => m.id == completed.id);
                              if (idx != -1) {
                                list[idx] = completed;
                              } else {
                                list.add(completed);
                              }
                              ref.read(guestSessionMeasurementsProvider.notifier).state = list;
                              await ref
                                  .read(guestLocalRepositoryProvider)
                                  .saveMeasurements(session.id, list);
                            }
                          }
                        },
                        onCancel: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text(
                                'Hủy đồng hồ',
                                style: TextStyle(fontFamily: 'BeVietnamPro'),
                              ),
                              content: const Text(
                                'Bạn có chắc chắn muốn hủy đồng hồ này?',
                                style: TextStyle(fontFamily: 'BeVietnamPro'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text(
                                    'Không',
                                    style: TextStyle(
                                      fontFamily: 'BeVietnamPro',
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Hủy',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontFamily: 'BeVietnamPro',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(guestTimerProvider.notifier)
                                .cancelTimer(measurement.id);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTimerBottomSheet,
        backgroundColor: AppColors.primary,
        elevation: 2,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['Tất cả', 'Nước', 'Bánh', 'Đơn'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: filters.map((f) {
          final isSelected = _selectedFilter == f;
          return FilterChip(
            label: Text(
              f,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.white,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            onSelected: (val) {
              if (val) {
                setState(() => _selectedFilter = f);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_off_outlined, size: 64, color: AppColors.border),
          SizedBox(height: 16),
          Text(
            'Chưa có đồng hồ đang chạy',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestTimerCard extends StatelessWidget {
  final GuestMeasurementModel measurement;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _GuestTimerCard({
    required this.measurement,
    required this.onPause,
    required this.onResume,
    required this.onComplete,
    required this.onCancel,
  });

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Color catColor;
    IconData catIcon;
    String catLabel;

    switch (measurement.category) {
      case PerformanceCategory.drink:
        catColor = const Color(0xFF0284C7); // blue
        catIcon = Icons.local_cafe;
        catLabel = 'Nước';
        break;
      case PerformanceCategory.cake:
        catColor = const Color(0xFFD97706); // amber
        catIcon = Icons.cake;
        catLabel = 'Bánh';
        break;
      case PerformanceCategory.order:
        catColor = AppColors.info; // navy
        catIcon = Icons.receipt_long;
        catLabel = 'Đơn hàng';
        break;
    }

    final isRunning = measurement.status == MeasurementStatus.running;

    return Card(
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, color: catColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$catLabel (x${measurement.quantity})',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.neutral,
                        ),
                      ),
                      if (measurement.orderCode != null &&
                          measurement.orderCode!.isNotEmpty)
                        Text(
                          'Mã đơn: ${measurement.orderCode}',
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isRunning
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isRunning ? 'Đang chạy' : 'Tạm dừng',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isRunning ? AppColors.success : AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _formatTime(measurement.elapsedSeconds),
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, color: AppColors.primary),
                  tooltip: 'Hủy',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                  ),
                ),
                IconButton(
                  onPressed: isRunning ? onPause : onResume,
                  icon: Icon(
                    isRunning ? Icons.pause : Icons.play_arrow,
                    color: AppColors.info,
                  ),
                  tooltip: isRunning ? 'Tạm dừng' : 'Tiếp tục',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.info.withOpacity(0.1),
                  ),
                ),
                IconButton(
                  onPressed: onComplete,
                  icon: const Icon(Icons.check, color: AppColors.success),
                  tooltip: 'Hoàn thành',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.success.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTimerBottomSheet extends ConsumerStatefulWidget {
  const _AddTimerBottomSheet();

  @override
  ConsumerState<_AddTimerBottomSheet> createState() => _AddTimerBottomSheetState();
}

class _AddTimerBottomSheetState extends ConsumerState<_AddTimerBottomSheet> {
  PerformanceCategory _category = PerformanceCategory.drink;
  int _quantity = 1;
  final TextEditingController _orderCodeController = TextEditingController();

  @override
  void dispose() {
    _orderCodeController.dispose();
    super.dispose();
  }

  void _submit() async {
    final session = ref.read(guestActiveSessionProvider);
    if (session == null) return;

    final isOrder = _category == PerformanceCategory.order;
    final currentMeasurements = ref.read(guestSessionMeasurementsProvider);
    final defaultOrderCode = isOrder
        ? (_orderCodeController.text.trim().isEmpty
            ? 'Đơn #${currentMeasurements.where((e) => e.category == PerformanceCategory.order).length + 1}'
            : _orderCodeController.text.trim())
        : null;

    final err = await ref.read(guestTimerProvider.notifier).startTimer(
          sessionId: session.id,
          category: _category,
          quantity: _quantity,
          orderCode: defaultOrderCode,
          allSessionMeasurements: currentMeasurements,
        );

    if (mounted) {
      Navigator.pop(context);
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              err,
              style: const TextStyle(fontFamily: 'BeVietnamPro'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Thêm đồng hồ mới',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.neutral,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Phân loại',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontWeight: FontWeight.w600,
              color: AppColors.neutral,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<PerformanceCategory>(
            segments: const [
              ButtonSegment(
                value: PerformanceCategory.drink,
                label: Text('Nước', style: TextStyle(fontFamily: 'BeVietnamPro')),
                icon: Icon(Icons.local_cafe),
              ),
              ButtonSegment(
                value: PerformanceCategory.cake,
                label: Text('Bánh', style: TextStyle(fontFamily: 'BeVietnamPro')),
                icon: Icon(Icons.cake),
              ),
              ButtonSegment(
                value: PerformanceCategory.order,
                label: Text('Đơn', style: TextStyle(fontFamily: 'BeVietnamPro')),
                icon: Icon(Icons.receipt_long),
              ),
            ],
            selected: {_category},
            onSelectionChanged: (set) {
              setState(() => _category = set.first);
            },
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary.withOpacity(0.1),
              selectedForegroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          if (_category != PerformanceCategory.order) ...[
            const Text(
              'Số lượng',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.w600,
                color: AppColors.neutral,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.primary,
                  iconSize: 28,
                ),
                Expanded(
                  child: Text(
                    '$_quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.neutral,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                  iconSize: 28,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ] else ...[
            const Text(
              'Mã đơn (Tùy chọn)',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.w600,
                color: AppColors.neutral,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _orderCodeController,
              decoration: InputDecoration(
                hintText: 'Nhập mã đơn (VD: A01)...',
                hintStyle: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontFamily: 'BeVietnamPro'),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Bắt đầu',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
