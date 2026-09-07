import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/performance_calculator.dart';
import '../models/guest_session_model.dart';
import '../providers/guest_providers.dart';

class GuestHistoryTab extends ConsumerStatefulWidget {
  const GuestHistoryTab({super.key});

  @override
  ConsumerState<GuestHistoryTab> createState() => _GuestHistoryTabState();
}

class _GuestHistoryTabState extends ConsumerState<GuestHistoryTab> {
  DateTime? _selectedDate;

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
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(guestHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Lịch sử phiên đo',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontWeight: FontWeight.bold,
            color: AppColors.neutral,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 20),
              onPressed: () => setState(() => _selectedDate = null),
            ),
        ],
      ),
      body: historyAsync.when(
        data: (sessions) {
          final filteredSessions = _selectedDate == null
              ? sessions
              : sessions.where((s) {
                  return s.startedAt.year == _selectedDate!.year &&
                      s.startedAt.month == _selectedDate!.month &&
                      s.startedAt.day == _selectedDate!.day;
                }).toList();

          if (filteredSessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.border),
                  SizedBox(height: 16),
                  Text(
                    'Chưa có lịch sử phiên đo',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredSessions.length,
            itemBuilder: (context, index) {
              final session = filteredSessions[index];
              return _buildSessionCard(context, session);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text(
            'Lỗi: $error',
            style: const TextStyle(fontFamily: 'BeVietnamPro'),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, GuestSessionModel session) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final dateStr = dateFormatter.format(session.startedAt);
    final startTimeStr = timeFormatter.format(session.startedAt);
    final endTimeStr = session.endedAt != null
        ? timeFormatter.format(session.endedAt!)
        : 'Đang đo';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.neutral,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$startTimeStr – $endTimeStr',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Divider(height: 18, color: AppColors.divider),
            Row(
              children: [
                const Icon(Icons.badge_rounded, size: 14, color: AppColors.info),
                const SizedBox(width: 6),
                Text(
                  'Quản lý: ${session.managerOnDutyLabel}',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: AppColors.neutral,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${session.employeeLabels.length} nhân viên',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniMetric(
                    'Nước',
                    _formatTime(session.drinkAverageSeconds),
                    const Color(0xFF0284C7),
                  ),
                  _buildMiniMetric(
                    'Bánh',
                    _formatTime(session.cakeAverageSeconds),
                    const Color(0xFFD97706),
                  ),
                  _buildMiniMetric(
                    'Đơn hàng',
                    _formatTime(session.orderAverageSeconds),
                    const Color(0xFF1C4E6B),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  context.push('/guest-result', extra: session);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'XEM CHI TIẾT',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontWeight: FontWeight.bold,
            color: AppColors.neutral,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
