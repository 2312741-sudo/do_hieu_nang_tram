import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/store_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../session/providers/timer_service.dart';

enum DeleteTimeframeType {
  customRange,
  thisWeek,
  thisMonth,
  allTime,
}

class DeleteMeasurementDataDialog extends ConsumerStatefulWidget {
  const DeleteMeasurementDataDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteMeasurementDataDialog(),
    );
  }

  @override
  ConsumerState<DeleteMeasurementDataDialog> createState() =>
      _DeleteMeasurementDataDialogState();
}

class _DeleteMeasurementDataDialogState
    extends ConsumerState<DeleteMeasurementDataDialog> {
  DeleteTimeframeType _selectedType = DeleteTimeframeType.thisWeek;
  DateTimeRange? _customDateRange;
  String? _selectedStoreId;
  bool _isDeleting = false;

  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    final currentStoreId = ref.read(currentStoreIdProvider);
    _selectedStoreId = currentStoreId;

    final now = DateTime.now();
    _customDateRange = DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
  }

  (DateTime?, DateTime?, String) _getDateRangeInfo() {
    final now = DateTime.now();
    switch (_selectedType) {
      case DeleteTimeframeType.customRange:
        if (_customDateRange == null) {
          return (null, null, 'Chưa chọn khoảng thời gian');
        }
        final start = DateTime(
          _customDateRange!.start.year,
          _customDateRange!.start.month,
          _customDateRange!.start.day,
          0,
          0,
          0,
        );
        final end = DateTime(
          _customDateRange!.end.year,
          _customDateRange!.end.month,
          _customDateRange!.end.day,
          23,
          59,
          59,
        );
        return (
          start,
          end,
          'Từ ${_dateFmt.format(start)} đến ${_dateFmt.format(end)}',
        );

      case DeleteTimeframeType.thisWeek:
        // Week starts Monday (weekday = 1)
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        final start = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
        final end = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
        return (
          start,
          end,
          'Tuần này: ${_dateFmt.format(start)} – ${_dateFmt.format(end)}',
        );

      case DeleteTimeframeType.thisMonth:
        final start = DateTime(now.year, now.month, 1, 0, 0, 0);
        final lastDay = DateTime(now.year, now.month + 1, 0).day;
        final end = DateTime(now.year, now.month, lastDay, 23, 59, 59);
        return (
          start,
          end,
          'Tháng ${now.month}/${now.year}: 01/${now.month} – $lastDay/${now.month}/${now.year}',
        );

      case DeleteTimeframeType.allTime:
        return (null, null, 'Toàn bộ dữ liệu đo từ trước đến nay');
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      helpText: 'CHỌN KHOẢNG THỜI GIAN CẦN XÓA',
      confirmText: 'CHỌN',
      cancelText: 'HỦY',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.danger,
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
        _selectedType = DeleteTimeframeType.customRange;
      });
    }
  }

  Future<void> _confirmAndDelete() async {
    final (start, end, timeLabel) = _getDateRangeInfo();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Xác nhận xóa vĩnh viễn',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn đang yêu cầu xóa dữ liệu đo lường theo tiêu chí:',
              style: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 13.5),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• Phạm vi: $timeLabel',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Dữ liệu ảnh hưởng: Các ca đo (Sessions), chi tiết lượt đo (Measurements) và báo cáo ca (Reports).',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 12,
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Hành động này KHÔNG THỂ HOÀN TÁC. Bạn có chắc chắn muốn tiếp tục không?',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('HỦY', style: TextStyle(fontFamily: 'BeVietnamPro')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'XÓA NGAY',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final repo = ref.read(performanceRepositoryProvider);
      final isAll = _selectedType == DeleteTimeframeType.allTime;

      final result = await repo.deletePerformanceData(
        storeId: _selectedStoreId,
        startDate: start,
        endDate: end,
        deleteAll: isAll,
      );

      // Clear local timers if any were active
      await ref.read(performanceTimerProvider.notifier).clearAllTimers();

      if (!mounted) return;
      Navigator.pop(context); // Close main dialog

      final sCount = result['sessions'] ?? 0;
      final mCount = result['measurements'] ?? 0;
      final rCount = result['reports'] ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã xóa thành công $sCount phiên đo ($mCount lượt đo) và $rCount báo cáo.',
            style: const TextStyle(fontFamily: 'BeVietnamPro'),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi khi xóa dữ liệu: $e',
            style: const TextStyle(fontFamily: 'BeVietnamPro'),
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(userStoresProvider).valueOrNull ?? [];
    final (_, _, timeLabel) = _getDateRangeInfo();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.delete_sweep_rounded,
              color: AppColors.danger,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'XÓA DỮ LIỆU ĐO',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.neutral,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Text(
              'Chọn phạm vi và khoảng thời gian để dọn dẹp các phiên đo & báo cáo hiệu năng.',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Store Selector
            if (stores.length > 1) ...[
              const Text(
                'CỬA HÀNG ÁP DỤNG',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStoreId,
                    isExpanded: true,
                    items: stores.map((StoreModel s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text(
                          s.name,
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _isDeleting
                        ? null
                        : (val) {
                            if (val != null) setState(() => _selectedStoreId = val);
                          },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Timeframe Options
            const Text(
              'BỘ LỌC THỜI GIAN',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            _buildRadioOption(
              type: DeleteTimeframeType.thisWeek,
              title: 'Tuần này',
              subtitle: 'Xóa toàn bộ ca đo trong tuần hiện tại',
              icon: Icons.date_range_rounded,
            ),
            const SizedBox(height: 6),
            _buildRadioOption(
              type: DeleteTimeframeType.thisMonth,
              title: 'Tháng này',
              subtitle: 'Xóa toàn bộ ca đo trong tháng hiện tại',
              icon: Icons.calendar_month_rounded,
            ),
            const SizedBox(height: 6),
            _buildRadioOption(
              type: DeleteTimeframeType.customRange,
              title: 'Khoảng thời gian tùy chọn',
              subtitle: _customDateRange != null
                  ? '${_dateFmt.format(_customDateRange!.start)} – ${_dateFmt.format(_customDateRange!.end)}'
                  : 'Bấm để chọn từ ngày đến ngày',
              icon: Icons.edit_calendar_rounded,
              trailingButton: TextButton.icon(
                onPressed: _isDeleting ? null : _pickCustomRange,
                icon: const Icon(Icons.calendar_today_rounded, size: 14),
                label: const Text('Chọn', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
            ),
            const SizedBox(height: 6),
            _buildRadioOption(
              type: DeleteTimeframeType.allTime,
              title: 'Toàn bộ dữ liệu',
              subtitle: 'Xóa tất cả các ca đo & báo cáo từ trước tới nay',
              icon: Icons.auto_delete_rounded,
              isDestructive: true,
            ),

            const SizedBox(height: 16),

            // Applied range indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      timeLabel,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          child: const Text(
            'ĐÓNG',
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isDeleting ? null : _confirmAndDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_forever_rounded, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'XÓA DỮ LIỆU',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildRadioOption({
    required DeleteTimeframeType type,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailingButton,
    bool isDestructive = false,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: _isDeleting
          ? null
          : () {
              setState(() => _selectedType = type);
              if (type == DeleteTimeframeType.customRange && _customDateRange == null) {
                _pickCustomRange();
              }
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDestructive ? Colors.red.shade50 : AppColors.primary.withOpacity(0.06))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDestructive ? AppColors.danger : AppColors.primary)
                : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? (isDestructive ? AppColors.danger : AppColors.primary)
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isDestructive && isSelected ? AppColors.danger : AppColors.neutral,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingButton != null) trailingButton,
            Radio<DeleteTimeframeType>(
              value: type,
              groupValue: _selectedType,
              activeColor: isDestructive ? AppColors.danger : AppColors.primary,
              onChanged: _isDeleting
                  ? null
                  : (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
