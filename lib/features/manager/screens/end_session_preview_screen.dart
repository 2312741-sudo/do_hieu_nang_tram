import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/performance_calculator.dart';
import '../../../models/measurement_model.dart';
import '../../../models/performance_report_model.dart';
import '../../../models/performance_session_model.dart';
import '../../../models/store_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../session/providers/timer_service.dart';

class EndSessionPreviewScreen extends ConsumerStatefulWidget {
  final PerformanceSessionModel session;

  const EndSessionPreviewScreen({super.key, required this.session});

  @override
  ConsumerState<EndSessionPreviewScreen> createState() => _EndSessionPreviewScreenState();
}

class _EndSessionPreviewScreenState extends ConsumerState<EndSessionPreviewScreen> {
  bool _isSubmitting = false;
  final Map<String, dynamic> _formValues = {};
  final Map<String, String?> _formErrors = {};

  bool _validateForm(List<EndSessionCriterionModel> criteria) {
    bool isValid = true;
    _formErrors.clear();

    for (final c in criteria) {
      if (!c.isRequired) continue;

      final val = _formValues[c.id];
      if (c.type == 'checkbox') {
        if (val != true) {
          _formErrors[c.id] = 'Vui lòng xác nhận đã hoàn thành';
          isValid = false;
        }
      } else if (c.type == 'number') {
        if (val == null || val.toString().trim().isEmpty) {
          _formErrors[c.id] = 'Vui lòng nhập số lượng';
          isValid = false;
        }
      } else if (c.type == 'text') {
        if (val == null || val.toString().trim().isEmpty) {
          _formErrors[c.id] = 'Vui lòng nhập nội dung';
          isValid = false;
        }
      } else if (c.type == 'rating') {
        if (val == null || (val as num) <= 0) {
          _formErrors[c.id] = 'Vui lòng chọn đánh giá';
          isValid = false;
        }
      }
    }

    setState(() {});
    return isValid;
  }

  Future<void> _shareShiftSummary({
    required String storeName,
    required DateTime date,
    required String reporterName,
    required String managerOnDutyName,
    required List<String> employeeNames,
    required int drinkQty,
    required int drinkAvg,
    required int drinkStd,
    required int cakeQty,
    required int cakeAvg,
    required int cakeStd,
    required int orderCount,
    required int orderAvg,
    required int orderStd,
    required int incidentCount,
    required List<PerformanceIncidentModel> incidents,
  }) async {
    HapticFeedback.lightImpact();
    final summaryText = PerformanceCalculator.generateShiftSummaryText(
      storeName: storeName,
      date: date,
      reporterName: reporterName,
      managerOnDutyName: managerOnDutyName,
      employeeNames: employeeNames,
      drinkQty: drinkQty,
      drinkAvg: drinkAvg,
      drinkStd: drinkStd,
      cakeQty: cakeQty,
      cakeAvg: cakeAvg,
      cakeStd: cakeStd,
      orderCount: orderCount,
      orderAvg: orderAvg,
      orderStd: orderStd,
      incidentCount: incidentCount,
      incidentSummaries: incidents.map((i) => '${i.category}: ${i.description}').toList(),
    );

    try {
      await Share.share(summaryText, subject: 'Báo cáo hiệu năng ca làm việc - $storeName');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: summaryText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã sao chép tóm tắt ca vào bộ nhớ tạm để dán vào Zalo.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitReport(
    List<MeasurementModel> completedMeasurements,
    int drinkQty,
    int drinkDuration,
    int drinkAvg,
    int cakeQty,
    int cakeDuration,
    int cakeAvg,
    int orderCount,
    int orderDuration,
    int orderAvg,
    StoreModel? store,
  ) async {
    final criteria = store?.endSessionCriteria ?? [];
    if (!_validateForm(criteria)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng hoàn thành đầy đủ tất cả các mục báo cáo ca.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final std = store?.performanceStandards ?? const StorePerformanceStandards();

      final report = PerformanceReportModel(
        id: widget.session.id,
        sessionId: widget.session.id,
        storeId: widget.session.storeId,
        storeName: widget.session.storeName,
        managerId: widget.session.managerId,
        managerName: widget.session.managerName,
        managerOnDutyId: widget.session.managerOnDutyId,
        managerOnDutyName: widget.session.managerOnDutyName,
        employeeIds: widget.session.employeeIds,
        employeeNames: widget.session.employeeNames,
        startedAt: widget.session.startedAt,
        endedAt: now,
        drinkTotalQuantity: drinkQty,
        drinkMeasurementCount: completedMeasurements.where((m) => m.category == PerformanceCategory.drink).length,
        drinkTotalSeconds: drinkDuration,
        drinkAverageSeconds: drinkAvg,
        cakeTotalQuantity: cakeQty,
        cakeMeasurementCount: completedMeasurements.where((m) => m.category == PerformanceCategory.cake).length,
        cakeTotalSeconds: cakeDuration,
        cakeAverageSeconds: cakeAvg,
        orderCount: orderCount,
        orderTotalSeconds: orderDuration,
        orderAverageSeconds: orderAvg,
        status: ReportStatus.submitted,
        submittedAt: now,
        createdAt: now,
        formResponses: {
          for (final c in criteria)
            if (_formValues.containsKey(c.id))
              c.id: {
                'title': c.title,
                'type': c.type,
                'value': _formValues[c.id],
              }
        },
        standardSnapshot: {
          'drink': std.drinkStandardSeconds,
          'cake': std.cakeStandardSeconds,
          'order': std.orderStandardSeconds,
        },
        incidents: widget.session.incidents,
      );

      final repo = ref.read(performanceRepositoryProvider);
      await repo.endAndSubmitSession(
        session: widget.session,
        report: report,
      );

      // Clear all active timers in local engine
      await ref.read(performanceTimerProvider.notifier).clearAllTimers();

      // Invalidate stream providers so state transitions to State 1 immediately
      ref.invalidate(activeSessionProvider);
      ref.invalidate(sessionMeasurementsProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi báo cáo & kết thúc phiên đo thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Pop back to root ManagerMainScreen so it displays State 1 (New Session)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi báo cáo: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allMeasurements = ref.watch(sessionMeasurementsProvider).valueOrNull ?? [];
    final activeTimers = allMeasurements.where((m) => m.status.isActive).toList();
    final completed = allMeasurements.where((m) => m.status.isCompleted).toList();

    final drinks = completed.where((m) => m.category == PerformanceCategory.drink).toList();
    final cakes = completed.where((m) => m.category == PerformanceCategory.cake).toList();
    final orders = completed.where((m) => m.category == PerformanceCategory.order).toList();

    final drinkQty = drinks.fold<int>(0, (sum, m) => sum + m.quantity);
    final drinkDuration = drinks.fold<int>(0, (sum, m) => sum + m.durationSeconds);
    final drinkAvg = PerformanceCalculator.calculateWeightedAverage(totalSeconds: drinkDuration, totalQuantity: drinkQty);

    final cakeQty = cakes.fold<int>(0, (sum, m) => sum + m.quantity);
    final cakeDuration = cakes.fold<int>(0, (sum, m) => sum + m.durationSeconds);
    final cakeAvg = PerformanceCalculator.calculateWeightedAverage(totalSeconds: cakeDuration, totalQuantity: cakeQty);

    final orderCount = orders.length;
    final orderDuration = orders.fold<int>(0, (sum, m) => sum + m.durationSeconds);
    final orderAvg = PerformanceCalculator.calculateCountAverage(totalSeconds: orderDuration, count: orderCount);

    final timeFmt = DateFormat('HH:mm');
    final now = DateTime.now();
    final store = ref.watch(currentStoreProvider).valueOrNull;
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final std = store?.performanceStandards ?? const StorePerformanceStandards();
    final criteria = store?.endSessionCriteria ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.neutral, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: AppColors.neutral),
        title: const Text(
          'KẾT THÚC PHIÊN ĐO',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'BeVietnamPro',
            color: AppColors.neutral,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning if active timers remain
            if (activeTimers.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Còn ${activeTimers.length} timer đang chạy chưa hoàn thành. Vui lòng hoàn thành hoặc hủy các lần đo đó trước khi gửi.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8C5300),
                          fontFamily: 'BeVietnamPro',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Session Info Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Cửa hàng', value: widget.session.storeName),
                  const Divider(height: 20),
                  _InfoRow(label: 'Người tạo phiên', value: widget.session.managerName),
                  const Divider(height: 20),
                  _InfoRow(
                    label: 'Thời gian phiên',
                    value: '${timeFmt.format(widget.session.startedAt)} – ${timeFmt.format(now)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Personnel Section (Section 68)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NHÂN SỰ CA',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.badge_rounded, size: 18, color: AppColors.info),
                      const SizedBox(width: 8),
                      const Text(
                        'Quản lý đứng ca: ',
                        style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, fontFamily: 'BeVietnamPro'),
                      ),
                      Text(
                        widget.session.managerOnDutyName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.neutral,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Nhân viên trong ca (${widget.session.employeeNames.length} người):',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (widget.session.employeeNames.isEmpty)
                    const Text(
                      '• Không có nhân viên phụ ca',
                      style: TextStyle(fontSize: 13, color: AppColors.textDisabled, fontFamily: 'BeVietnamPro'),
                    )
                  else
                    ...widget.session.employeeNames.map((rawName) {
                      String name = rawName;
                      String? dept;
                      Color deptColor = AppColors.primary;
                      IconData deptIcon = Icons.person;

                      if (rawName.contains('(Nước)')) {
                        name = rawName.replaceAll('(Nước)', '').trim();
                        dept = 'Nước';
                        deptColor = const Color(0xFF0284C7);
                        deptIcon = Icons.local_cafe_rounded;
                      } else if (rawName.contains('(Bánh)')) {
                        name = rawName.replaceAll('(Bánh)', '').trim();
                        dept = 'Bánh';
                        deptColor = const Color(0xFFD97706);
                        deptIcon = Icons.cake_rounded;
                      } else if (rawName.contains('(Phục vụ)')) {
                        name = rawName.replaceAll('(Phục vụ)', '').trim();
                        dept = 'Phục vụ';
                        deptColor = const Color(0xFF16A34A);
                        deptIcon = Icons.room_service_rounded;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.5),
                        child: Row(
                          children: [
                            const Text('•  ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'BeVietnamPro',
                                color: AppColors.neutral,
                              ),
                            ),
                            if (dept != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: deptColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: deptColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(deptIcon, size: 11, color: deptColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      dept,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: deptColor,
                                        fontFamily: 'BeVietnamPro',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Performance Summaries
            _CategorySummaryCard(
              title: 'NƯỚC',
              countLabel: '${drinks.length} lần ($drinkQty nước)',
              avgLabel: 'TB ${PerformanceCalculator.formatSeconds(drinkAvg)} / nước',
              totalDuration: PerformanceCalculator.formatSeconds(drinkDuration),
              icon: Icons.local_cafe_rounded,
            ),
            const SizedBox(height: 12),

            _CategorySummaryCard(
              title: 'BÁNH',
              countLabel: '${cakes.length} lần ($cakeQty bánh)',
              avgLabel: 'TB ${PerformanceCalculator.formatSeconds(cakeAvg)} / bánh',
              totalDuration: PerformanceCalculator.formatSeconds(cakeDuration),
              icon: Icons.cake_rounded,
            ),
            const SizedBox(height: 12),

            _CategorySummaryCard(
              title: 'ĐƠN HÀNG',
              countLabel: '$orderCount đơn',
              avgLabel: 'TB ${PerformanceCalculator.formatSeconds(orderAvg)} / đơn',
              totalDuration: PerformanceCalculator.formatSeconds(orderDuration),
              icon: Icons.receipt_long_rounded,
            ),

            // End Session Checklist Form
            if (criteria.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
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
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.assignment_turned_in_rounded, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'BIỂU MẪU BÁO CÁO CA LÀM',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'BeVietnamPro',
                              color: AppColors.neutral,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Text(
                            'Bắt buộc',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vui lòng hoàn thành tất cả các mục bên dưới để hoàn tất kết thúc phiên:',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'BeVietnamPro'),
                    ),
                    const SizedBox(height: 14),

                    ...criteria.map((c) {
                      final hasError = _formErrors[c.id] != null;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasError ? Colors.red.shade50.withOpacity(0.4) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: hasError ? Colors.red.shade300 : Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.title,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'BeVietnamPro',
                                      color: AppColors.neutral,
                                    ),
                                  ),
                                ),
                                if (c.isRequired)
                                  const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Render based on type
                            if (c.type == 'checkbox')
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: AppColors.primary,
                                value: _formValues[c.id] == true,
                                title: Text(
                                  _formValues[c.id] == true ? 'Đã hoàn thành' : 'Chưa hoàn thành (Chạm để tích)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _formValues[c.id] == true ? AppColors.primary : Colors.grey.shade600,
                                  ),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _formValues[c.id] = val;
                                    _formErrors.remove(c.id);
                                  });
                                },
                              )
                            else if (c.type == 'number')
                              TextField(
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Nhập số lượng...',
                                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textDisabled),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onChanged: (val) {
                                  _formValues[c.id] = val;
                                  if (val.trim().isNotEmpty) {
                                    _formErrors.remove(c.id);
                                  }
                                },
                              )
                            else if (c.type == 'text')
                              TextField(
                                maxLines: 2,
                                decoration: InputDecoration(
                                  hintText: 'Nhập nội dung ghi chú...',
                                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textDisabled),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                onChanged: (val) {
                                  _formValues[c.id] = val;
                                  if (val.trim().isNotEmpty) {
                                    _formErrors.remove(c.id);
                                  }
                                },
                              )
                            else if (c.type == 'rating')
                              Row(
                                children: List.generate(5, (starIdx) {
                                  final starVal = starIdx + 1;
                                  final curRating = (_formValues[c.id] as num?) ?? 0;
                                  return IconButton(
                                    icon: Icon(
                                      starVal <= curRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: Colors.amber.shade700,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _formValues[c.id] = starVal;
                                        _formErrors.remove(c.id);
                                      });
                                    },
                                  );
                                }),
                              ),

                            if (hasError) ...[
                              const SizedBox(height: 4),
                              Text(
                                _formErrors[c.id]!,
                                style: const TextStyle(fontSize: 11.5, color: Colors.red, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            // Incidents Section (if any logged)
            if (widget.session.incidents.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
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
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.report_problem_rounded, color: Color(0xFFDC2626), size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LỖI PHÁT SINH TRONG CA (${widget.session.incidents.length})',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'BeVietnamPro',
                            color: Color(0xFF991B1B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.session.incidents.map((incident) {
                      final timeStr = timeFmt.format(incident.timestamp);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    incident.category,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  timeStr,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textDisabled),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              incident.description,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral,
                              ),
                            ),
                            if (incident.staffName != null && incident.staffName!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Liên quan: ${incident.staffName}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Share Shift Summary Button
            OutlinedButton.icon(
              onPressed: () => _shareShiftSummary(
                storeName: store?.name ?? widget.session.storeName,
                date: widget.session.startedAt,
                reporterName: currentUser?.name ?? widget.session.managerName,
                managerOnDutyName: widget.session.managerOnDutyName.isNotEmpty
                    ? widget.session.managerOnDutyName
                    : widget.session.managerName,
                employeeNames: widget.session.employeeNames,
                drinkQty: drinkQty,
                drinkAvg: drinkAvg,
                drinkStd: std.drinkStandardSeconds,
                cakeQty: cakeQty,
                cakeAvg: cakeAvg,
                cakeStd: std.cakeStandardSeconds,
                orderCount: orderCount,
                orderAvg: orderAvg,
                orderStd: std.orderStandardSeconds,
                incidentCount: widget.session.incidents.length,
                incidents: widget.session.incidents,
              ),
              icon: const Icon(Icons.share_rounded, size: 20, color: AppColors.primary),
              label: const Text(
                'CHIA SẺ TÓM TẮT CA (ZALO)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'BeVietnamPro',
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: AppColors.primary.withOpacity(0.04),
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.neutral,
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('QUAY LẠI'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || activeTimers.isNotEmpty)
                        ? null
                        : () => _submitReport(
                              completed,
                              drinkQty,
                              drinkDuration,
                              drinkAvg,
                              cakeQty,
                              cakeDuration,
                              cakeAvg,
                              orderCount,
                              orderDuration,
                              orderAvg,
                              store,
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'KẾT THÚC & GỬI BÁO CÁO',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, fontFamily: 'BeVietnamPro'),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'BeVietnamPro',
            color: AppColors.neutral,
          ),
        ),
      ],
    );
  }
}

class _CategorySummaryCard extends StatelessWidget {
  final String title;
  final String countLabel;
  final String avgLabel;
  final String totalDuration;
  final IconData icon;

  const _CategorySummaryCard({
    required this.title,
    required this.countLabel,
    required this.avgLabel,
    required this.totalDuration,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'BeVietnamPro',
                    color: AppColors.neutral,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  countLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontFamily: 'BeVietnamPro',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                avgLabel,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'BeVietnamPro',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Tổng: $totalDuration',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                  fontFamily: 'BeVietnamPro',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
