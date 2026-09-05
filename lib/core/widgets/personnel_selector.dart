import 'package:flutter/material.dart';
import '../../models/member_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

class PersonnelSelectorWidget extends StatelessWidget {
  final List<MemberModel> availableManagers;
  final List<MemberModel> availableStaff;
  final MemberModel? selectedManager;
  final List<MemberModel> selectedStaff;
  final List<MemberModel> selectedDrinkStaff;
  final List<MemberModel> selectedCakeStaff;
  final List<MemberModel> selectedServiceStaff;
  final ValueChanged<MemberModel?>? onManagerChanged;
  final ValueChanged<List<MemberModel>>? onStaffChanged;
  final ValueChanged<List<MemberModel>>? onDrinkStaffChanged;
  final ValueChanged<List<MemberModel>>? onCakeStaffChanged;
  final ValueChanged<List<MemberModel>>? onServiceStaffChanged;
  final bool isReadOnly;

  const PersonnelSelectorWidget({
    super.key,
    required this.availableManagers,
    required this.availableStaff,
    required this.selectedManager,
    this.selectedStaff = const [],
    this.selectedDrinkStaff = const [],
    this.selectedCakeStaff = const [],
    this.selectedServiceStaff = const [],
    this.onManagerChanged,
    this.onStaffChanged,
    this.onDrinkStaffChanged,
    this.onCakeStaffChanged,
    this.onServiceStaffChanged,
    this.isReadOnly = false,
  });

  void _openDepartmentSelectDialog({
    required BuildContext context,
    required String departmentTitle,
    required String departmentKey,
    required IconData icon,
    required Color color,
    required List<MemberModel> currentSelected,
    required ValueChanged<List<MemberModel>> onConfirm,
  }) {
    if (isReadOnly) return;

    final tempSelected = List<MemberModel>.from(currentSelected);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.78,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              departmentTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'BeVietnamPro',
                                color: AppColors.neutral,
                              ),
                            ),
                            Text(
                              'Đã chọn ${tempSelected.length} nhân sự',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'BeVietnamPro',
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (tempSelected.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempSelected.clear();
                            });
                          },
                          child: const Text(
                            'Bỏ chọn',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'BeVietnamPro',
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: availableStaff.isEmpty
                      ? const Center(
                          child: Text(
                            'Không có nhân sự khả dụng',
                            style: TextStyle(color: AppColors.textSecondary, fontFamily: 'BeVietnamPro'),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: availableStaff.length,
                          itemBuilder: (context, index) {
                            final staff = availableStaff[index];
                            final isChecked = tempSelected.any((m) => m.userId == staff.userId);
                            final isManager = staff.role.isManager;

                            // Check if staff is assigned to other departments
                            String? otherDept;
                            if (departmentKey != 'drink' &&
                                selectedDrinkStaff.any((m) => m.userId == staff.userId)) {
                              otherDept = 'Nước';
                            } else if (departmentKey != 'cake' &&
                                selectedCakeStaff.any((m) => m.userId == staff.userId)) {
                              otherDept = 'Bánh';
                            } else if (departmentKey != 'service' &&
                                selectedServiceStaff.any((m) => m.userId == staff.userId)) {
                              otherDept = 'Phục vụ';
                            }

                            return CheckboxListTile(
                              value: isChecked,
                              activeColor: color,
                              checkboxShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              secondary: CircleAvatar(
                                radius: 18,
                                backgroundColor: isManager
                                    ? AppColors.info.withOpacity(0.15)
                                    : color.withOpacity(0.12),
                                child: Text(
                                  staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'N',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isManager ? AppColors.info : color,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      staff.name,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'BeVietnamPro',
                                        color: AppColors.neutral,
                                      ),
                                    ),
                                  ),
                                  if (otherDept != null)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.amber.shade300),
                                      ),
                                      child: Text(
                                        'Đang ở: $otherDept',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber.shade900,
                                          fontFamily: 'BeVietnamPro',
                                        ),
                                      ),
                                    ),
                                  if (isManager)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.info.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Quản lý',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.info,
                                          fontFamily: 'BeVietnamPro',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    if (!tempSelected.any((m) => m.userId == staff.userId)) {
                                      tempSelected.add(staff);
                                    }
                                  } else {
                                    tempSelected.removeWhere((m) => m.userId == staff.userId);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: ElevatedButton(
                    onPressed: () {
                      onConfirm(tempSelected);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Xác nhận (${tempSelected.length} nhân sự)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDepartmentCard({
    required BuildContext context,
    required String title,
    required String departmentKey,
    required String suggestion,
    required IconData icon,
    required Color color,
    required List<MemberModel> selectedList,
    required ValueChanged<List<MemberModel>>? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selectedList.isNotEmpty ? color.withOpacity(0.04) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selectedList.isNotEmpty ? color.withOpacity(0.35) : Colors.grey.shade200,
          width: 1.2,
        ),
      ),
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
                      suggestion,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedList.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${selectedList.length} NV',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'BeVietnamPro',
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (isReadOnly) ...[
            if (selectedList.isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 2),
                child: Text(
                  '• Chưa phân công',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontFamily: 'BeVietnamPro'),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedList.map((staff) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_rounded, size: 13, color: color),
                        const SizedBox(width: 4),
                        Text(
                          staff.name,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'BeVietnamPro',
                            color: AppColors.neutral,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ] else ...[
            if (selectedList.isEmpty)
              InkWell(
                onTap: () => _openDepartmentSelectDialog(
                  context: context,
                  departmentTitle: title,
                  departmentKey: departmentKey,
                  icon: icon,
                  color: color,
                  currentSelected: selectedList,
                  onConfirm: (newList) => onChanged?.call(newList),
                ),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, size: 16, color: color),
                      const SizedBox(width: 6),
                      Text(
                        'Chọn nhân viên',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: color,
                          fontFamily: 'BeVietnamPro',
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...selectedList.map((staff) {
                    return Chip(
                      backgroundColor: Colors.white,
                      avatar: CircleAvatar(
                        backgroundColor: color.withOpacity(0.15),
                        child: Text(
                          staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'N',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                        ),
                      ),
                      label: Text(
                        staff.name,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.neutral,
                        ),
                      ),
                      deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
                      onDeleted: () {
                        final updated = List<MemberModel>.from(selectedList)
                          ..removeWhere((m) => m.userId == staff.userId);
                        onChanged?.call(updated);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: color.withOpacity(0.4)),
                      ),
                    );
                  }),
                  ActionChip(
                    backgroundColor: color.withOpacity(0.08),
                    avatar: Icon(Icons.add, size: 14, color: color),
                    label: Text(
                      'Thêm',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: color.withOpacity(0.3)),
                    ),
                    onPressed: () => _openDepartmentSelectDialog(
                      context: context,
                      departmentTitle: title,
                      departmentKey: departmentKey,
                      icon: icon,
                      color: color,
                      currentSelected: selectedList,
                      onConfirm: (newList) => onChanged?.call(newList),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalStaffCount = selectedDrinkStaff.length +
        selectedCakeStaff.length +
        selectedServiceStaff.length +
        (selectedDrinkStaff.isEmpty && selectedCakeStaff.isEmpty && selectedServiceStaff.isEmpty
            ? selectedStaff.length
            : 0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.group_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  AppStrings.personnelSection,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'BeVietnamPro',
                    letterSpacing: 0.5,
                    color: AppColors.neutral,
                  ),
                ),
              ),
              if (isReadOnly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 12, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'Đã khóa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          fontFamily: 'BeVietnamPro',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Quản lý đứng ca
          const Text(
            AppStrings.managerOnDuty,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'BeVietnamPro',
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),

          if (isReadOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_rounded, size: 18, color: AppColors.info),
                  const SizedBox(width: 8),
                  Text(
                    selectedManager?.name ?? 'Chưa xác định',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.neutral,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MemberModel>(
                  value: availableManagers.any((m) => m.userId == selectedManager?.userId)
                      ? availableManagers.firstWhere((m) => m.userId == selectedManager?.userId)
                      : (availableManagers.isNotEmpty ? availableManagers.first : null),
                  hint: const Text(
                    AppStrings.selectManagerHint,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textDisabled,
                      fontFamily: 'BeVietnamPro',
                    ),
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  items: availableManagers.map((manager) {
                    return DropdownMenuItem<MemberModel>(
                      value: manager,
                      child: Text(
                        manager.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.neutral,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: onManagerChanged,
                ),
              ),
            ),

          const SizedBox(height: 18),

          // 2. Phân bổ Nhân sự theo Bộ phận
          Row(
            children: [
              const Text(
                'NHÂN SỰ THEO BỘ PHẬN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'BeVietnamPro',
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (totalStaffCount > 0)
                Text(
                  'Tổng: $totalStaffCount NV',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'BeVietnamPro',
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Bộ phận Nước (1 NV)
          _buildDepartmentCard(
            context: context,
            title: 'Bộ phận Nước (Pha chế)',
            departmentKey: 'drink',
            suggestion: 'Khuyến nghị: 1 nhân viên',
            icon: Icons.local_cafe_rounded,
            color: const Color(0xFF0284C7),
            selectedList: selectedDrinkStaff,
            onChanged: onDrinkStaffChanged,
          ),

          // Bộ phận Bánh (1 NV)
          _buildDepartmentCard(
            context: context,
            title: 'Bộ phận Bánh (Bếp bánh)',
            departmentKey: 'cake',
            suggestion: 'Khuyến nghị: 1 nhân viên',
            icon: Icons.cake_rounded,
            color: const Color(0xFFD97706),
            selectedList: selectedCakeStaff,
            onChanged: onCakeStaffChanged,
          ),

          // Bộ phận Phục vụ (2-3 NV)
          _buildDepartmentCard(
            context: context,
            title: 'Bộ phận Phục vụ (Thu ngân / Phục vụ)',
            departmentKey: 'service',
            suggestion: 'Khuyến nghị: 2 - 3 nhân viên',
            icon: Icons.room_service_rounded,
            color: const Color(0xFF16A34A),
            selectedList: selectedServiceStaff,
            onChanged: onServiceStaffChanged,
          ),

          // Fallback legacy display if only selectedStaff is passed in read-only mode
          if (isReadOnly &&
              selectedDrinkStaff.isEmpty &&
              selectedCakeStaff.isEmpty &&
              selectedServiceStaff.isEmpty &&
              selectedStaff.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: selectedStaff.map((staff) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    staff.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.neutral,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
