import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/performance_session_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../session/providers/timer_service.dart';

class AddIncidentBottomSheet extends ConsumerStatefulWidget {
  final PerformanceSessionModel session;

  const AddIncidentBottomSheet({super.key, required this.session});

  static Future<void> show(BuildContext context, PerformanceSessionModel session) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddIncidentBottomSheet(session: session),
    );
  }

  @override
  ConsumerState<AddIncidentBottomSheet> createState() => _AddIncidentBottomSheetState();
}

class _AddIncidentBottomSheetState extends ConsumerState<AddIncidentBottomSheet> {
  final _descController = TextEditingController();
  String _selectedCategory = 'Pha chế / Nước';
  String? _selectedStaff;
  bool _isSaving = false;

  final List<String> _categories = [
    'Pha chế / Nước',
    'Bánh / Chế biến',
    'Thiết bị / Máy móc',
    'Đổ vỡ / Thất thoát',
    'Khách đổi / Hủy món',
    'Phục vụ / Thái độ',
    'Khác',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final desc = _descController.text.trim();
    if (desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung mô tả lỗi / sự cố.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      final reporterName = user?.name ?? 'Quản lý';

      final incident = PerformanceIncidentModel(
        id: const Uuid().v4(),
        description: desc,
        category: _selectedCategory,
        staffName: _selectedStaff,
        reportedBy: reporterName,
        timestamp: DateTime.now(),
      );

      final repo = ref.read(performanceRepositoryProvider);
      await repo.addSessionIncident(widget.session.id, incident);

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu lỗi phát sinh vào phiên đo thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Available staff options
    final staffOptions = <String>[
      if (widget.session.managerOnDutyName.isNotEmpty)
        '${widget.session.managerOnDutyName} (Quản lý)',
      ...widget.session.employeeNames,
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: const Icon(Icons.report_problem_rounded, color: Color(0xFFDC2626), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BÁO CÁO LỖI PHÁT SINH',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.neutral,
                        ),
                      ),
                      Text(
                        'Ghi nhận sự cố để tổng hợp vào báo cáo ca',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'BeVietnamPro',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Selector
            const Text(
              'Phân loại sự cố / lỗi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'BeVietnamPro',
                color: AppColors.neutral,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontFamily: 'BeVietnamPro',
                      color: isSelected ? Colors.white : AppColors.neutral,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFFDC2626),
                  backgroundColor: AppColors.surface,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Staff involved (Optional)
            if (staffOptions.isNotEmpty) ...[
              const Text(
                'Nhân sự liên quan (không bắt buộc)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'BeVietnamPro',
                  color: AppColors.neutral,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedStaff,
                    isExpanded: true,
                    hint: const Text(
                      '-- Không chỉ định nhân sự --',
                      style: TextStyle(fontSize: 13.5, color: AppColors.textDisabled, fontFamily: 'BeVietnamPro'),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          '-- Không chỉ định nhân sự --',
                          style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, fontFamily: 'BeVietnamPro'),
                        ),
                      ),
                      ...staffOptions.map((name) {
                        return DropdownMenuItem<String?>(
                          value: name,
                          child: Text(
                            name,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, fontFamily: 'BeVietnamPro'),
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedStaff = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description Input
            const Text(
              'Nội dung chi tiết lỗi / sự cố *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'BeVietnamPro',
                color: AppColors.neutral,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14, fontFamily: 'BeVietnamPro'),
              decoration: InputDecoration(
                hintText: 'Ví dụ: Làm nhầm size ly nước, máy xay bị kẹt 5 phút, bánh bị cháy phải nướng lại...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textDisabled, fontFamily: 'BeVietnamPro'),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'LƯU LỖI PHÁT SINH',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'BeVietnamPro',
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
