import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/incident_image_service.dart';
import '../../../core/widgets/incident_image_viewer_dialog.dart';
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
  String? _uploadStatusText;

  Uint8List? _incidentImageBytes;
  bool _isFromCamera = false;
  bool _isProcessingImage = false;

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

  Future<void> _pickFromCamera() async {
    try {
      final file = await IncidentImageService.pickFromCamera();
      if (file == null) return;

      setState(() => _isProcessingImage = true);

      final rawBytes = await file.readAsBytes();
      final user = ref.read(currentUserProvider).valueOrNull;
      final reporterName = user?.name ?? widget.session.managerOnDutyName;

      final stampedBytes = await IncidentImageService.stampCameraImage(
        rawBytes: rawBytes,
        storeName: widget.session.storeName,
        reporterName: reporterName.isNotEmpty ? reporterName : 'Quản lý',
        category: _selectedCategory,
      );

      if (!mounted) return;
      setState(() {
        _incidentImageBytes = stampedBytes;
        _isFromCamera = true;
        _isProcessingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chụp ảnh: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final file = await IncidentImageService.pickFromGallery();
      if (file == null) return;

      setState(() => _isProcessingImage = true);

      final rawBytes = await file.readAsBytes();
      final compressedBytes = await IncidentImageService.compressGalleryImage(rawBytes);

      if (!mounted) return;
      setState(() {
        _incidentImageBytes = compressedBytes;
        _isFromCamera = false;
        _isProcessingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _incidentImageBytes = null;
      _isFromCamera = false;
    });
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

    setState(() {
      _isSaving = true;
      _uploadStatusText = 'Đang chuẩn bị lưu...';
    });

    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      final reporterName = user?.name ?? 'Quản lý';
      final incidentId = const Uuid().v4();
      String? imageUrl;

      // Upload ảnh nếu có đính kèm
      if (_incidentImageBytes != null) {
        setState(() => _uploadStatusText = 'Đang tải ảnh minh chứng...');
        imageUrl = await IncidentImageService.uploadIncidentImage(
          imageBytes: _incidentImageBytes!,
          storeId: widget.session.storeId,
          sessionId: widget.session.id,
          incidentId: incidentId,
        );
      }

      setState(() => _uploadStatusText = 'Đang lưu sự cố...');

      final incident = PerformanceIncidentModel(
        id: incidentId,
        description: desc,
        category: _selectedCategory,
        staffName: _selectedStaff,
        reportedBy: reporterName,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
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
              minLines: 3,
              maxLines: null,
              keyboardType: TextInputType.multiline,
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
            const SizedBox(height: 16),

            // Photo Attachment Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.photo_camera_rounded, size: 16, color: Color(0xFFDC2626)),
                    SizedBox(width: 6),
                    Text(
                      'Ảnh minh chứng',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'BeVietnamPro',
                        color: AppColors.neutral,
                      ),
                    ),
                  ],
                ),
                Text(
                  _incidentImageBytes != null ? 'Đã đính kèm ảnh' : 'Không bắt buộc',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _incidentImageBytes != null ? AppColors.success : AppColors.textDisabled,
                    fontWeight: _incidentImageBytes != null ? FontWeight.w700 : FontWeight.normal,
                    fontFamily: 'BeVietnamPro',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_isProcessingImage)
              Container(
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Color(0xFFDC2626), strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Đang xử lý & đóng dấu ngày giờ...',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontFamily: 'BeVietnamPro'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_incidentImageBytes != null)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => IncidentImageViewerDialog.show(
                        context,
                        imageBytes: _incidentImageBytes,
                        title: 'Ảnh minh chứng (${_isFromCamera ? "Camera đóng dấu" : "Thư viện"})',
                      ),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _incidentImageBytes!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isFromCamera ? Icons.verified_rounded : Icons.photo_library_rounded,
                                size: 14,
                                color: _isFromCamera ? const Color(0xFF16A34A) : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isFromCamera ? 'Chụp ảnh (Đã đóng dấu)' : 'Từ thư viện ảnh',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _isFromCamera ? const Color(0xFF16A34A) : AppColors.neutral,
                                  fontFamily: 'BeVietnamPro',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Dung lượng: ~${(_incidentImageBytes!.lengthInBytes / 1024).toStringAsFixed(0)} KB (Đã nén)',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'BeVietnamPro'),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Chạm vào ảnh để xem chi tiết',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFFDC2626), fontStyle: FontStyle.italic, fontFamily: 'BeVietnamPro'),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
                      tooltip: 'Xoá ảnh',
                      onPressed: _removeImage,
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFromCamera,
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Chụp ảnh', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, fontFamily: 'BeVietnamPro')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text('Thư viện', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, fontFamily: 'BeVietnamPro')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neutral,
                        side: const BorderSide(color: AppColors.border, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
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
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _uploadStatusText ?? 'Đang lưu...',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'BeVietnamPro',
                          ),
                        ),
                      ],
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
