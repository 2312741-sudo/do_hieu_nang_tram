import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/performance_calculator.dart';
import '../models/guest_session_model.dart';
import '../models/guest_measurement_model.dart';
import '../providers/guest_providers.dart';
import '../widgets/guest_personnel_selector.dart';

class GuestOverviewTab extends ConsumerStatefulWidget {
  const GuestOverviewTab({super.key});

  @override
  ConsumerState<GuestOverviewTab> createState() => _GuestOverviewTabState();
}

class _GuestOverviewTabState extends ConsumerState<GuestOverviewTab> {
  int? _selectedManagerIndex;
  List<int> _selectedEmployeeIndexes = [];

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String _formatDate() {
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy');
    String dayStr = '';
    switch (now.weekday) {
      case 1:
        dayStr = 'Thứ 2';
        break;
      case 2:
        dayStr = 'Thứ 3';
        break;
      case 3:
        dayStr = 'Thứ 4';
        break;
      case 4:
        dayStr = 'Thứ 5';
        break;
      case 5:
        dayStr = 'Thứ 6';
        break;
      case 6:
        dayStr = 'Thứ 7';
        break;
      case 7:
        dayStr = 'Chủ nhật';
        break;
    }
    return '$dayStr, ${formatter.format(now)}';
  }

  String _formatTime(int seconds) {
    try {
      return PerformanceCalculator.formatSeconds(seconds);
    } catch (_) {
      final m = (seconds / 60).floor();
      final s = seconds % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
  }

  void _startSession() async {
    if (_selectedManagerIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng chọn Quản lý đứng ca',
            style: TextStyle(fontFamily: 'BeVietnamPro'),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final session = GuestSessionModel(
      id: const Uuid().v4(),
      managerOnDutyIndex: _selectedManagerIndex!,
      employeeIndexes: _selectedEmployeeIndexes,
      startedAt: now,
      createdAt: now,
    );

    ref.read(guestActiveSessionProvider.notifier).state = session;
    ref.read(guestSessionMeasurementsProvider.notifier).state = [];

    try {
      final repo = ref.read(guestLocalRepositoryProvider);
      await repo.saveActiveSession(session);
      await repo.saveMeasurements(session.id, []);
    } catch (_) {}
  }

  void _showAddTimerSheet(PerformanceCategory category) {
    final session = ref.read(guestActiveSessionProvider);
    if (session == null) return;

    final allMeasurements = ref.read(guestSessionMeasurementsProvider);
    final count = allMeasurements
        .where((m) => m.category == category && m.status != MeasurementStatus.cancelled)
        .length;

    if (count >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã đạt tối đa 20 lần đo cho mục ${category.label}.',
            style: const TextStyle(fontFamily: 'BeVietnamPro'),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    int quantity = 1;
    String orderCode = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isOrder = category == PerformanceCategory.order;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bấm giờ ${category.label}',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutral,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: AppColors.neutral),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isOrder) ...[
                    TextField(
                      style: const TextStyle(fontFamily: 'BeVietnamPro'),
                      decoration: InputDecoration(
                        labelText: 'Mã đơn (không bắt buộc)',
                        hintText: 'Ví dụ: A01, ORD-01...',
                        labelStyle: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                      onChanged: (val) => orderCode = val,
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Số lượng ${category.label.toLowerCase()}:',
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: quantity > 1
                                  ? () => setSheetState(() => quantity--)
                                  : null,
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setSheetState(() => quantity++),
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      final currentMeasurements =
                          ref.read(guestSessionMeasurementsProvider);
                      final defaultOrderCode = isOrder
                          ? (orderCode.trim().isEmpty
                              ? 'Đơn #${currentMeasurements.where((e) => e.category == PerformanceCategory.order).length + 1}'
                              : orderCode.trim())
                          : null;

                      final err = await ref
                          .read(guestTimerProvider.notifier)
                          .startTimer(
                            sessionId: session.id,
                            category: category,
                            quantity: quantity,
                            orderCode: defaultOrderCode,
                            allSessionMeasurements: currentMeasurements,
                          );

                      if (err != null && mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              err,
                              style: const TextStyle(fontFamily: 'BeVietnamPro'),
                            ),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'BẮT ĐẦU ĐO',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(GuestSessionModel? session) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFFE8192F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Chế độ khách',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(),
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 14,
              color: AppColors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionBanner(GuestSessionModel session) {
    final timeFmt = DateFormat('HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22876D), Color(0xFF16594B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A6B5A).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PHIÊN ĐO ĐANG HOẠT ĐỘNG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'BeVietnamPro',
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bắt đầu lúc: ${timeFmt.format(session.startedAt)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Color(0xFF4ADE80), size: 8),
                    SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/guest-end-session');
            },
            icon: const Icon(Icons.stop_circle_outlined, size: 20, color: AppColors.primary),
            label: const Text(
              'KẾT THÚC PHIÊN ĐO',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                color: AppColors.primary,
                letterSpacing: 0.3,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    IconData icon,
    Color color,
    List<GuestMeasurementModel> measurements,
  ) {
    final completed =
        measurements.where((m) => m.status == MeasurementStatus.completed).toList();
    final count = completed.length;
    final totalQuantity =
        completed.fold<int>(0, (sum, m) => sum + m.quantity);
    final totalDuration =
        completed.fold<int>(0, (sum, m) => sum + m.durationSeconds);
    final avgTime = totalQuantity > 0 ? (totalDuration / totalQuantity).round() : 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: AppColors.white,
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.neutral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildKpiItem('Số lần', count.toString()),
                _buildKpiItem('Tổng SL', totalQuantity.toString()),
                _buildKpiItem('Trung bình', _formatTime(avgTime)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.neutral,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(guestActiveSessionProvider);
    final measurements = ref.watch(guestSessionMeasurementsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(session),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: session == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GuestPersonnelSelector(
                            selectedManagerIndex: _selectedManagerIndex,
                            selectedEmployeeIndexes: _selectedEmployeeIndexes,
                            onManagerChanged: (val) =>
                                setState(() => _selectedManagerIndex = val),
                            onEmployeesChanged: (val) =>
                                setState(() => _selectedEmployeeIndexes = val),
                            isReadOnly: false,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            onPressed: _startSession,
                            child: const Text(
                              'BẮT ĐẦU PHIÊN ĐO',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Prominent Active Session Banner with End Session CTA
                          _buildActiveSessionBanner(session),

                          // 2. Quick Measurement Action Buttons
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showAddTimerSheet(PerformanceCategory.drink),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text(
                                  'BẤM GIỜ NƯỚC',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF0284C7),
                                  side: const BorderSide(
                                    color: Color(0xFF0284C7),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showAddTimerSheet(PerformanceCategory.cake),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text(
                                  'BẤM GIỜ BÁNH',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD97706),
                                  side: const BorderSide(
                                    color: Color(0xFFD97706),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showAddTimerSheet(PerformanceCategory.order),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text(
                                  'BẤM GIỜ ĐƠN HÀNG',
                                  style: TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1C4E6B),
                                  side: const BorderSide(
                                    color: Color(0xFF1C4E6B),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 3. Personnel on duty (Locked)
                          GuestPersonnelSelector(
                            selectedManagerIndex: session.managerOnDutyIndex,
                            selectedEmployeeIndexes: session.employeeIndexes,
                            onManagerChanged: (_) {},
                            onEmployeesChanged: (_) {},
                            isReadOnly: true,
                          ),
                          const SizedBox(height: 20),

                          // 4. KPI Summary
                          const Text(
                            'TỔNG QUAN PHIÊN ĐO',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildKpiCard(
                            'Nước',
                            Icons.local_cafe_rounded,
                            const Color(0xFF0284C7),
                            measurements
                                .where((m) => m.category == PerformanceCategory.drink)
                                .toList(),
                          ),
                          _buildKpiCard(
                            'Bánh',
                            Icons.cake_rounded,
                            const Color(0xFFD97706),
                            measurements
                                .where((m) => m.category == PerformanceCategory.cake)
                                .toList(),
                          ),
                          _buildKpiCard(
                            'Đơn hàng',
                            Icons.receipt_long_rounded,
                            const Color(0xFF1C4E6B),
                            measurements
                                .where((m) => m.category == PerformanceCategory.order)
                                .toList(),
                          ),
                          const SizedBox(height: 20),

                          // 5. Bottom End Session CTA
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.stop_circle_outlined, size: 20),
                            label: const Text(
                              'KẾT THÚC PHIÊN ĐO',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            onPressed: () {
                              context.push('/guest-end-session');
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
