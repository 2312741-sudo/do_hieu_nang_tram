import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/performance_calculator.dart';
import '../../../models/store_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/delete_measurement_data_dialog.dart';

class StorePerformanceSettingsScreen extends ConsumerStatefulWidget {
  const StorePerformanceSettingsScreen({super.key});

  @override
  ConsumerState<StorePerformanceSettingsScreen> createState() =>
      _StorePerformanceSettingsScreenState();
}

class _StorePerformanceSettingsScreenState
    extends ConsumerState<StorePerformanceSettingsScreen> {
  late TextEditingController _drinkStdCtrl;
  late TextEditingController _cakeStdCtrl;
  late TextEditingController _orderStdCtrl;

  late List<EndSessionCriterionModel> _criteria;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _drinkStdCtrl = TextEditingController();
    _cakeStdCtrl = TextEditingController();
    _orderStdCtrl = TextEditingController();
    _criteria = [];
  }

  @override
  void dispose() {
    _drinkStdCtrl.dispose();
    _cakeStdCtrl.dispose();
    _orderStdCtrl.dispose();
    super.dispose();
  }

  void _initFromStore(StoreModel store) {
    if (_isInitialized) return;
    final std = store.performanceStandards;
    _drinkStdCtrl.text = std.drinkStandardSeconds.toString();
    _cakeStdCtrl.text = std.cakeStandardSeconds.toString();
    _orderStdCtrl.text = std.orderStandardSeconds.toString();
    _criteria = List<EndSessionCriterionModel>.from(store.endSessionCriteria);

    // If criteria is empty, provide default initial criteria for convenience
    if (_criteria.isEmpty) {
      _criteria = [
        const EndSessionCriterionModel(
          id: 'crit_clean',
          title: 'Vệ sinh quầy bar & kiểm tra tủ đông, dụng cụ',
          type: 'checkbox',
          isRequired: true,
          order: 1,
        ),
        const EndSessionCriterionModel(
          id: 'crit_waste',
          title: 'Số lượng ly / bánh hao hụt, hủy bỏ trong ca',
          type: 'number',
          isRequired: true,
          order: 2,
        ),
        const EndSessionCriterionModel(
          id: 'crit_note',
          title: 'Ghi chú bàn giao ca & tình hình ca làm',
          type: 'text',
          isRequired: false,
          order: 3,
        ),
      ];
    }

    _isInitialized = true;
  }

  Future<void> _saveSettings(StoreModel store) async {
    final drinkSec = int.tryParse(_drinkStdCtrl.text.trim()) ?? 120;
    final cakeSec = int.tryParse(_cakeStdCtrl.text.trim()) ?? 120;
    final orderSec = int.tryParse(_orderStdCtrl.text.trim()) ?? 180;

    if (drinkSec <= 0 || cakeSec <= 0 || orderSec <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian tiêu chuẩn phải lớn hơn 0 giây.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedStandards = StorePerformanceStandards(
        drinkStandardSeconds: drinkSec,
        cakeStandardSeconds: cakeSec,
        orderStandardSeconds: orderSec,
      );

      await FirebaseFirestore.instance
          .collection('stores')
          .doc(store.id)
          .update({
        'performanceStandards': updatedStandards.toJson(),
        'endSessionCriteria': _criteria.map((c) => c.toJson()).toList(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cài đặt tiêu chuẩn & biểu mẫu thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu cài đặt: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _openAddEditCriterionDialog({EndSessionCriterionModel? existing, int? index}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    String selectedType = existing?.type ?? 'checkbox';
    bool isRequired = existing?.isRequired ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text(
              existing == null ? 'Thêm Tiêu Chí Báo Cáo' : 'Chỉnh Sửa Tiêu Chí',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'BeVietnamPro',
                color: AppColors.neutral,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nội dung câu hỏi / Hạng mục kiểm tra:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ví dụ: Vệ sinh quầy bar sạch sẽ',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textDisabled),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loại câu hỏi / Kiểu nhập:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'checkbox',
                            child: Row(
                              children: [
                                Icon(Icons.check_box_outlined, size: 18, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text('Tích chọn hoàn thành (Checkbox)', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'number',
                            child: Row(
                              children: [
                                Icon(Icons.pin_outlined, size: 18, color: Color(0xFF0284C7)),
                                SizedBox(width: 8),
                                Text('Nhập số lượng (Number)', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'text',
                            child: Row(
                              children: [
                                Icon(Icons.text_fields_rounded, size: 18, color: Color(0xFFD97706)),
                                SizedBox(width: 8),
                                Text('Nhập ghi chú / văn bản (Text)', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'rating',
                            child: Row(
                              children: [
                                Icon(Icons.star_rate_rounded, size: 18, color: Colors.amber),
                                SizedBox(width: 8),
                                Text('Đánh giá sao (1-5 sao)', style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedType = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Bắt buộc hoàn thành',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'BeVietnamPro',
                        color: AppColors.neutral,
                      ),
                    ),
                    subtitle: const Text(
                      'Quản lý phải điền mục này mới được kết thúc phiên',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    value: isRequired,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setDialogState(() => isRequired = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('HỦY', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập nội dung tiêu chí.')),
                    );
                    return;
                  }

                  setState(() {
                    if (existing != null && index != null) {
                      _criteria[index] = existing.copyWith(
                        title: title,
                        type: selectedType,
                        isRequired: isRequired,
                      );
                    } else {
                      final newId = 'crit_${DateTime.now().millisecondsSinceEpoch}';
                      _criteria.add(
                        EndSessionCriterionModel(
                          id: newId,
                          title: title,
                          type: selectedType,
                          isRequired: isRequired,
                          order: _criteria.length + 1,
                        ),
                      );
                    }
                  });
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('LƯU'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(currentStoreProvider).valueOrNull;

    if (store == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cài đặt Tiêu chuẩn')),
        body: const Center(child: Text('Vui lòng chọn cửa hàng.')),
      );
    }

    _initFromStore(store);

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
          'TIÊU CHUẨN & BIỂU MẪU BÁO CÁO',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            fontFamily: 'BeVietnamPro',
            color: AppColors.neutral,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Info Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'BeVietnamPro',
                            color: AppColors.neutral,
                          ),
                        ),
                        Text(
                          'Cấu hình riêng biệt cho cửa hàng này',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SECTION 1: Standard Times
            const Row(
              children: [
                Icon(Icons.speed_rounded, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'THỜI GIAN TIÊU CHUẨN (BENCHMARK)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'BeVietnamPro',
                    color: AppColors.neutral,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Dùng để tính % Hiệu suất (Hiệu suất = Chuẩn / Thực tế). Số giây càng nhỏ nghĩa là tiêu chuẩn càng cao.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 12),

            // Drink Standard
            _buildStandardInputCard(
              title: 'Hạng mục Nước (Pha chế)',
              subtitle: 'Thời gian tiêu chuẩn cho 1 ly nước',
              icon: Icons.local_cafe_rounded,
              color: const Color(0xFF0284C7),
              controller: _drinkStdCtrl,
              unit: 'giây/ly',
            ),
            const SizedBox(height: 10),

            // Cake Standard
            _buildStandardInputCard(
              title: 'Hạng mục Bánh (Bếp bánh)',
              subtitle: 'Thời gian tiêu chuẩn cho 1 phần bánh',
              icon: Icons.cake_rounded,
              color: const Color(0xFFD97706),
              controller: _cakeStdCtrl,
              unit: 'giây/bánh',
            ),
            const SizedBox(height: 10),

            // Order Standard
            _buildStandardInputCard(
              title: 'Hạng mục Đơn hàng (Tổng hợp)',
              subtitle: 'Thời gian tiêu chuẩn cho 1 đơn hàng',
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF16A34A),
              controller: _orderStdCtrl,
              unit: 'giây/đơn',
            ),
            const SizedBox(height: 24),

            // SECTION 2: End-Session Form Criteria
            Row(
              children: [
                const Icon(Icons.fact_check_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'BIỂU MẪU BÁO CÁO KẾT THÚC PHIÊN ĐO',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'BeVietnamPro',
                    color: AppColors.neutral,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openAddEditCriterionDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Thêm mục', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            Text(
              'Các hạng mục bắt buộc người tạo phiên phải hoàn thành khi bấm kết thúc phiên đo ca làm.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
            ),
            const SizedBox(height: 10),

            if (_criteria.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.assignment_late_outlined, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có tiêu chí báo cáo nào',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bấm nút "Thêm mục" để tự tạo form kiểm tra cho cửa hàng.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              )
            else
              ..._criteria.asMap().entries.map((entry) {
                final idx = entry.key;
                final crit = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getTypeColor(crit.type).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_getTypeIcon(crit.type), size: 16, color: _getTypeColor(crit.type)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    crit.title,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'BeVietnamPro',
                                      color: AppColors.neutral,
                                    ),
                                  ),
                                ),
                                if (crit.isRequired)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.red.shade200),
                                    ),
                                    child: const Text(
                                      'Bắt buộc',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.red),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Loại: ${_getTypeLabel(crit.type)}',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                        onPressed: () => _openAddEditCriterionDialog(existing: crit, index: idx),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _criteria.removeAt(idx);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 30),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : () => _saveSettings(store),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'LƯU CÀI ĐẶT CỬA HÀNG',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'BeVietnamPro',
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Danger Zone: Quản lý & Xóa dữ liệu đo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.delete_sweep_rounded, color: AppColors.danger, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QUẢN LÝ DỮ LIỆU ĐO LƯỜNG',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'BeVietnamPro',
                                color: AppColors.danger,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Dọn dẹp phiên đo & báo cáo theo thời gian',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontFamily: 'BeVietnamPro',
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Cho phép xóa các ca đo và báo cáo hiệu năng cũ theo Tuần, Tháng, Khoảng thời gian cụ thể hoặc Toàn bộ dữ liệu của cửa hàng.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => DeleteMeasurementDataDialog.show(context),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text(
                      'XÓA DỮ LIỆU ĐO THEO BỘ LỌC',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardInputCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String unit,
  }) {
    final curSec = int.tryParse(controller.text) ?? 120;
    final mmss = PerformanceCalculator.formatSeconds(curSec);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'BeVietnamPro',
                        color: AppColors.neutral,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mmss,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'BeVietnamPro',
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    suffixText: unit,
                    suffixStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Preset buttons
              _buildPresetChip(controller, 90),
              const SizedBox(width: 4),
              _buildPresetChip(controller, 120),
              const SizedBox(width: 4),
              _buildPresetChip(controller, 150),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(TextEditingController ctrl, int sec) {
    return InkWell(
      onTap: () {
        ctrl.text = sec.toString();
        setState(() {});
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          '${sec}s',
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.neutral),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'number':
        return const Color(0xFF0284C7);
      case 'text':
        return const Color(0xFFD97706);
      case 'rating':
        return Colors.amber.shade800;
      case 'checkbox':
      default:
        return AppColors.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'number':
        return Icons.pin_outlined;
      case 'text':
        return Icons.text_fields_rounded;
      case 'rating':
        return Icons.star_rate_rounded;
      case 'checkbox':
      default:
        return Icons.check_box_outlined;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'number':
        return 'Nhập số lượng';
      case 'text':
        return 'Nhập văn bản/ghi chú';
      case 'rating':
        return 'Đánh giá 1 - 5 sao';
      case 'checkbox':
      default:
        return 'Tích chọn hoàn thành';
    }
  }
}
