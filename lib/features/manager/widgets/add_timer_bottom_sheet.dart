import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/measurement_model.dart';
import '../../../models/performance_session_model.dart';
import '../../session/providers/timer_service.dart';

class AddTimerBottomSheet extends ConsumerStatefulWidget {
  final PerformanceCategory category;

  const AddTimerBottomSheet({super.key, required this.category});

  static Future<void> show(BuildContext context, PerformanceCategory category) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTimerBottomSheet(category: category),
    );
  }

  @override
  ConsumerState<AddTimerBottomSheet> createState() => _AddTimerBottomSheetState();
}

class _AddTimerBottomSheetState extends ConsumerState<AddTimerBottomSheet> {
  int _quantity = 1;
  final TextEditingController _orderCodeCtrl = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _orderCodeCtrl.dispose();
    super.dispose();
  }

  String? _getDepartmentStaffName(PerformanceSessionModel? session) {
    if (session == null) return null;
    final tag = widget.category == PerformanceCategory.drink
        ? '(Nước)'
        : (widget.category == PerformanceCategory.cake ? '(Bánh)' : '(Phục vụ)');
    final altTag = widget.category == PerformanceCategory.drink
        ? '(dr)'
        : (widget.category == PerformanceCategory.cake ? '(ck)' : '(lo)');

    final deptStaff = session.employeeNames
        .where((n) => n.contains(tag) || n.toLowerCase().contains(altTag))
        .map((n) => n.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (deptStaff.isNotEmpty) {
      return deptStaff.join(', ');
    }
    if (widget.category == PerformanceCategory.order && session.managerOnDutyName.isNotEmpty) {
      return session.managerOnDutyName;
    }
    return null;
  }

  Future<void> _handleStart() async {
    HapticFeedback.lightImpact();

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final session = ref.read(activeSessionProvider).valueOrNull;
    final staff = _getDepartmentStaffName(session);

    final timerNotifier = ref.read(performanceTimerProvider.notifier);
    final error = await timerNotifier.startTimer(
      category: widget.category,
      quantity: _quantity,
      orderCode: _orderCodeCtrl.text,
      staffName: staff,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      setState(() {
        _errorMessage = error;
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final session = ref.watch(activeSessionProvider).valueOrNull;
    final deptStaffName = _getDepartmentStaffName(session);

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.category == PerformanceCategory.drink
                      ? Icons.local_cafe_rounded
                      : (widget.category == PerformanceCategory.cake
                          ? Icons.cake_rounded
                          : Icons.receipt_long_rounded),
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đo thời gian ${widget.category.label.toLowerCase()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'BeVietnamPro',
                        color: AppColors.neutral,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.category == PerformanceCategory.order
                          ? 'Nhập mã đơn trước khi bắt đầu.'
                          : 'Nhập số lượng ${widget.category.label.toLowerCase()} trước khi bắt đầu.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (widget.category == PerformanceCategory.order) ...[
            // Đơn hàng: Mã đơn
            const Text(
              'Mã đơn hàng',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'BeVietnamPro',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _orderCodeCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Ví dụ: 104-382',
                prefixIcon: const Icon(Icons.confirmation_number_rounded, size: 20),
                errorText: _errorMessage,
              ),
              onSubmitted: (_) => _handleStart(),
            ),
          ] else ...[
            // Nước & Bánh: Stepper số lượng
            Text(
              'Số lượng ${widget.category.label.toLowerCase()}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'BeVietnamPro',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 32),
                    color: AppColors.primary,
                    disabledColor: AppColors.textDisabled,
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.neutral,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 32),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'BeVietnamPro',
                ),
              ),
            ],
          ],

          if (deptStaffName != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Nhân sự ${widget.category.label.toLowerCase()}: ',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      deptStaffName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'BeVietnamPro',
                        color: AppColors.neutral,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Start Button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'BẮT ĐẦU ĐO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'BeVietnamPro',
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
