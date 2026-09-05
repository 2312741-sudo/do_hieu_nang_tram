import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/excel_export_service.dart';
import '../../../core/utils/performance_calculator.dart';
import '../../../models/measurement_model.dart';
import '../../../models/performance_report_model.dart';
import '../../../models/performance_session_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../session/providers/timer_service.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final PerformanceReportModel report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsViewedIfOwner();
    });
  }

  void _markAsViewedIfOwner() {
    final uid = ref.read(currentUserIdProvider);
    final isOwner = ref.read(isOwnerProvider);
    if (isOwner && uid != null && widget.report.status == ReportStatus.submitted) {
      ref.read(performanceRepositoryProvider).markReportViewed(widget.report.id, uid);
    }
  }

  Future<void> _handleExportExcel(List<MeasurementModel> measurements) async {
    setState(() => _isExporting = true);
    try {
      await ExcelExportService.exportPerformanceReport(
        report: widget.report,
        measurements: measurements,
        context: context,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(performanceRepositoryProvider);
    final measurementsStream = repo.watchMeasurements(widget.report.sessionId);

    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.neutral,
        elevation: 0,
        title: const Text(
          'BÁO CÁO PHIÊN ĐO',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            fontFamily: 'BeVietnamPro',
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<MeasurementModel>>(
        stream: measurementsStream,
        builder: (context, snapshot) {
          final measurements = snapshot.data ?? [];
          final completed = measurements.where((m) => m.status == MeasurementStatus.completed).toList();

          final drinkMeasurements = completed.where((m) => m.category == PerformanceCategory.drink).toList();
          final cakeMeasurements = completed.where((m) => m.category == PerformanceCategory.cake).toList();
          final orderMeasurements = completed.where((m) => m.category == PerformanceCategory.order).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info Card
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
                    children: [
                      _DetailRow(label: 'Cửa hàng', value: widget.report.storeName, isBold: true),
                      const Divider(height: 20),
                      _DetailRow(label: 'Người tạo', value: widget.report.managerName),
                      const Divider(height: 20),
                      _DetailRow(label: 'Ngày thực hiện', value: dateFmt.format(widget.report.startedAt)),
                      const Divider(height: 20),
                      _DetailRow(
                        label: 'Thời gian phiên',
                        value: '${timeFmt.format(widget.report.startedAt)} – ${timeFmt.format(widget.report.endedAt)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section NHÂN SỰ CA (Section 69)
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
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(Icons.badge_rounded, size: 18, color: AppColors.info),
                          const SizedBox(width: 8),
                          const Text(
                            'Quản lý đứng ca: ',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.textSecondary,
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                          Text(
                            widget.report.managerOnDutyName,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'BeVietnamPro',
                              color: AppColors.neutral,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nhân viên trong ca (${widget.report.employeeNames.length} người):',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (widget.report.employeeNames.isEmpty)
                        const Text(
                          '• Không có nhân sự phụ ca',
                          style: TextStyle(fontSize: 13, color: AppColors.textDisabled, fontFamily: 'BeVietnamPro'),
                        )
                      else
                        ...widget.report.employeeNames.map((rawName) {
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
                                    fontSize: 14,
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

                // Metrics Summary Card
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
                        'TỔNG QUAN HIỆU NĂNG',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.neutral,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MetricSummaryItem(
                            label: 'NƯỚC',
                            countStr: '${widget.report.drinkTotalQuantity} nước',
                            timesStr: '${widget.report.drinkMeasurementCount} lần',
                            avgStr: PerformanceCalculator.formatSeconds(widget.report.drinkAverageSeconds),
                            unit: '/ nước',
                          ),
                          Container(width: 1, height: 60, color: AppColors.border),
                          _MetricSummaryItem(
                            label: 'BÁNH',
                            countStr: '${widget.report.cakeTotalQuantity} bánh',
                            timesStr: '${widget.report.cakeMeasurementCount} lần',
                            avgStr: PerformanceCalculator.formatSeconds(widget.report.cakeAverageSeconds),
                            unit: '/ bánh',
                          ),
                          Container(width: 1, height: 60, color: AppColors.border),
                          _MetricSummaryItem(
                            label: 'ĐƠN HÀNG',
                            countStr: '${widget.report.orderCount} đơn',
                            timesStr: '${widget.report.orderCount} lần',
                            avgStr: PerformanceCalculator.formatSeconds(widget.report.orderAverageSeconds),
                            unit: '/ đơn',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section BÁO CÁO KẾT THÚC CA (Checklist & Dynamic Form)
                if (widget.report.formResponses.isNotEmpty) ...[
                  _FormResponsesSection(responses: widget.report.formResponses),
                  const SizedBox(height: 16),
                ],

                // Section SỰ CỐ & LỖI PHÁT SINH TRONG CA
                if (widget.report.incidents.isNotEmpty) ...[
                  _IncidentsSection(incidents: widget.report.incidents),
                  const SizedBox(height: 16),
                ],

                // Export Excel CTA Button (Section 37)
                ElevatedButton.icon(
                  onPressed: _isExporting ? null : () => _handleExportExcel(measurements),
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download_rounded, size: 22),
                  label: const Text(
                    AppStrings.exportExcel,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'BeVietnamPro',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1C4E6B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                ),
                const SizedBox(height: 24),

                // Measurement Breakdown
                _CategorySection(
                  title: 'Chi tiết Nước (${drinkMeasurements.length})',
                  measurements: drinkMeasurements,
                  category: PerformanceCategory.drink,
                ),
                const SizedBox(height: 16),

                _CategorySection(
                  title: 'Chi tiết Bánh (${cakeMeasurements.length})',
                  measurements: cakeMeasurements,
                  category: PerformanceCategory.cake,
                ),
                const SizedBox(height: 16),

                _CategorySection(
                  title: 'Chi tiết Đơn hàng (${orderMeasurements.length})',
                  measurements: orderMeasurements,
                  category: PerformanceCategory.order,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FormResponsesSection extends StatelessWidget {
  final Map<String, dynamic> responses;

  const _FormResponsesSection({required this.responses});

  @override
  Widget build(BuildContext context) {
    if (responses.isEmpty) return const SizedBox.shrink();

    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF10B981), size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'BÁO CÁO KẾT THÚC CA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'BeVietnamPro',
                  color: Color(0xFF0F766E),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...responses.entries.map((entry) {
            String title = entry.key;
            dynamic value = entry.value;
            String? type;

            if (value is Map) {
              title = value['title']?.toString() ?? entry.key;
              type = value['type']?.toString();
              value = value['value'];
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'BeVietnamPro',
                            color: AppColors.neutral,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildValueWidget(value, type),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildValueWidget(dynamic value, String? type) {
    if (value is bool) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: value ? const Color(0xFFA5D6A7) : const Color(0xFFFFCDD2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 14,
              color: value ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
            const SizedBox(width: 4),
            Text(
              value ? 'Hoàn thành' : 'Chưa xong',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: value ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                fontFamily: 'BeVietnamPro',
              ),
            ),
          ],
        ),
      );
    }

    if (type == 'rating' && value is num) {
      final rating = value.toInt();
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          return Icon(
            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 16,
            color: index < rating ? const Color(0xFFF59E0B) : AppColors.textDisabled,
          );
        }),
      );
    }

    return Text(
      value?.toString() ?? '--',
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        fontFamily: 'BeVietnamPro',
      ),
    );
  }
}

class _IncidentsSection extends StatelessWidget {
  final List<PerformanceIncidentModel> incidents;

  const _IncidentsSection({required this.incidents});

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) return const SizedBox.shrink();

    final timeFmt = DateFormat('HH:mm');

    return Container(
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
                'LỖI & SỰ CỐ PHÁT SINH TRONG CA (${incidents.length})',
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
          const SizedBox(height: 14),
          ...incidents.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final incident = entry.value;
            final timeStr = timeFmt.format(incident.timestamp);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#$idx',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFDC2626),
                      fontSize: 13,
                      fontFamily: 'BeVietnamPro',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                incident.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                  fontFamily: 'BeVietnamPro',
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textDisabled,
                                fontFamily: 'BeVietnamPro',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          incident.description,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'BeVietnamPro',
                            color: AppColors.neutral,
                          ),
                        ),
                        if (incident.staffName != null && incident.staffName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                'Liên quan: ${incident.staffName}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'BeVietnamPro',
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (incident.reportedBy.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Ghi nhận bởi: ${incident.reportedBy}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textDisabled,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _DetailRow({required this.label, required this.value, this.isBold = false});

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
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            fontFamily: 'BeVietnamPro',
            color: AppColors.neutral,
          ),
        ),
      ],
    );
  }
}

class _MetricSummaryItem extends StatelessWidget {
  final String label;
  final String countStr;
  final String timesStr;
  final String avgStr;
  final String unit;

  const _MetricSummaryItem({
    required this.label,
    required this.countStr,
    required this.timesStr,
    required this.avgStr,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            fontFamily: 'BeVietnamPro',
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          countStr,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            fontFamily: 'BeVietnamPro',
            color: AppColors.neutral,
          ),
        ),
        Text(
          timesStr,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textDisabled,
            fontFamily: 'BeVietnamPro',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          avgStr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            fontFamily: 'BeVietnamPro',
            color: AppColors.primary,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 10.5,
            color: AppColors.textSecondary,
            fontFamily: 'BeVietnamPro',
          ),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<MeasurementModel> measurements;
  final PerformanceCategory category;

  const _CategorySection({
    required this.title,
    required this.measurements,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'BeVietnamPro',
              color: AppColors.neutral,
            ),
          ),
          const SizedBox(height: 12),
          if (measurements.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Không có lần đo hoàn thành',
                style: TextStyle(color: AppColors.textDisabled, fontSize: 13),
              ),
            )
          else
            ...measurements.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final m = entry.value;
              final startStr = timeFmt.format(m.startedAt);
              final endStr = m.completedAt != null ? timeFmt.format(m.completedAt!) : '--:--';
              final durationStr = PerformanceCalculator.formatSeconds(m.durationSeconds);
              final perItemStr = PerformanceCalculator.formatSeconds(m.secondsPerItem);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      '#$idx',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        fontSize: 13,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        category == PerformanceCategory.order
                            ? 'Mã: ${m.orderCode ?? ''}'
                            : '${m.quantity} ${category.label.toLowerCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          fontFamily: 'BeVietnamPro',
                        ),
                      ),
                    ),
                    Text(
                      '$startStr – $endStr',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontFamily: 'BeVietnamPro',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          durationStr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            fontFamily: 'BeVietnamPro',
                            color: AppColors.neutral,
                          ),
                        ),
                        if (category != PerformanceCategory.order && m.quantity > 1)
                          Text(
                            '$perItemStr/mục',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
