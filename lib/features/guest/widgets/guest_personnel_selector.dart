import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class GuestPersonnelSelector extends StatelessWidget {
  final int? selectedManagerIndex;
  final List<int> selectedEmployeeIndexes;
  final bool isReadOnly;
  final ValueChanged<int?> onManagerChanged;
  final ValueChanged<List<int>> onEmployeesChanged;

  const GuestPersonnelSelector({
    super.key,
    this.selectedManagerIndex,
    this.selectedEmployeeIndexes = const [],
    this.isReadOnly = false,
    required this.onManagerChanged,
    required this.onEmployeesChanged,
  });

  static const List<String> _managers = [
    'Quản lý 1',
    'Quản lý 2',
    'Quản lý 3',
    'Quản lý 4',
  ];

  static const List<String> _employees = [
    'Nhân viên 1',
    'Nhân viên 2',
    'Nhân viên 3',
    'Nhân viên 4',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.neutral.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildManagerSection(),
          const SizedBox(height: 16),
          _buildEmployeeSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.group_rounded, color: AppColors.primary, size: 24),
        const SizedBox(width: 8),
        const Text(
          'NHÂN SỰ PHIÊN ĐO',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.neutral,
          ),
        ),
        const Spacer(),
        if (isReadOnly)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, size: 14, color: AppColors.textSecondary),
                SizedBox(width: 4),
                Text(
                  'Đã khóa',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildManagerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUẢN LÝ ĐỨNG CA',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isReadOnly ? AppColors.surface : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: selectedManagerIndex,
              hint: const Text(
                'Chọn quản lý',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  color: AppColors.textSecondary,
                ),
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: isReadOnly ? AppColors.border : AppColors.neutral,
              ),
              items: List.generate(
                _managers.length,
                (index) => DropdownMenuItem(
                  value: index,
                  child: Text(
                    _managers[index],
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.neutral,
                    ),
                  ),
                ),
              ),
              onChanged: isReadOnly ? null : onManagerChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NHÂN VIÊN TRONG CA',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: isReadOnly ? null : () => _showEmployeeMultiSelect(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isReadOnly ? AppColors.surface : AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedEmployeeIndexes.isEmpty
                        ? 'Chọn nhân viên'
                        : '${selectedEmployeeIndexes.length} nhân viên đã chọn',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: selectedEmployeeIndexes.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.neutral,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: isReadOnly ? AppColors.border : AppColors.neutral,
                ),
              ],
            ),
          ),
        ),
        if (selectedEmployeeIndexes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedEmployeeIndexes.map((index) {
              return Chip(
                label: Text(
                  _employees[index],
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
                deleteIcon: isReadOnly
                    ? null
                    : const Icon(Icons.close, size: 14, color: AppColors.primary),
                onDeleted: isReadOnly
                    ? null
                    : () {
                        final newList = List<int>.from(selectedEmployeeIndexes)
                          ..remove(index);
                        onEmployeesChanged(newList);
                      },
              );
            }).toList(),
          ),
        ]
      ],
    );
  }

  void _showEmployeeMultiSelect(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MultiSelectEmployeeSheet(
        initialSelection: selectedEmployeeIndexes,
        employees: _employees,
        onConfirm: (List<int> newSelection) {
          onEmployeesChanged(newSelection);
        },
      ),
    );
  }
}

class _MultiSelectEmployeeSheet extends StatefulWidget {
  final List<int> initialSelection;
  final List<String> employees;
  final ValueChanged<List<int>> onConfirm;

  const _MultiSelectEmployeeSheet({
    required this.initialSelection,
    required this.employees,
    required this.onConfirm,
  });

  @override
  State<_MultiSelectEmployeeSheet> createState() =>
      _MultiSelectEmployeeSheetState();
}

class _MultiSelectEmployeeSheetState extends State<_MultiSelectEmployeeSheet> {
  late List<int> _tempSelection;

  @override
  void initState() {
    super.initState();
    _tempSelection = List.from(widget.initialSelection);
  }

  void _selectAll() {
    setState(() {
      _tempSelection = List.generate(widget.employees.length, (index) => index);
    });
  }

  void _deselectAll() {
    setState(() {
      _tempSelection.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chọn nhân viên',
                style: TextStyle(
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
          Row(
            children: [
              TextButton(
                onPressed: _selectAll,
                child: const Text(
                  'Chọn tất cả',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: _deselectAll,
                child: const Text(
                  'Bỏ chọn tất cả',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.border),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.employees.length,
              itemBuilder: (context, index) {
                final isSelected = _tempSelection.contains(index);
                return CheckboxListTile(
                  title: Text(
                    widget.employees[index],
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.neutral,
                    ),
                  ),
                  value: isSelected,
                  activeColor: AppColors.primary,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _tempSelection.add(index);
                      } else {
                        _tempSelection.remove(index);
                      }
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                widget.onConfirm(_tempSelection);
                Navigator.pop(context);
              },
              child: const Text(
                'Xác nhận',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
