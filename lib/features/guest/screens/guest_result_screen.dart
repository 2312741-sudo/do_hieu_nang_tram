import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as xl;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/performance_calculator.dart';
import '../models/guest_session_model.dart';
import '../models/guest_measurement_model.dart';
import '../providers/guest_providers.dart';

class GuestResultScreen extends ConsumerStatefulWidget {
  final GuestSessionModel session;

  const GuestResultScreen({
    super.key,
    required this.session,
  });

  @override
  ConsumerState<GuestResultScreen> createState() => _GuestResultScreenState();
}

class _GuestResultScreenState extends ConsumerState<GuestResultScreen> {
  List<GuestMeasurementModel> _measurements = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = ref.read(guestLocalRepositoryProvider);
      final measurements = await repo.loadMeasurements(widget.session.id);
      if (mounted) {
        setState(() {
          _measurements = measurements;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi tải dữ liệu: $e',
              style: const TextStyle(fontFamily: 'BeVietnamPro'),
            ),
          ),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    try {
      return PerformanceCalculator.formatSeconds(seconds);
    } catch (_) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      var excel = xl.Excel.createExcel();

      // TongQuan Sheet
      xl.Sheet sheetOverview = excel['TongQuan'];
      excel.setDefaultSheet('TongQuan');
      excel.delete('Sheet1');

      sheetOverview.appendRow([
        xl.TextCellValue('KẾT QUẢ PHIÊN ĐO HIỆU NĂNG (GUEST MODE)'),
      ]);
      sheetOverview.appendRow([
        xl.TextCellValue('Ngày bắt đầu'),
        xl.TextCellValue(
          DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.session.startedAt),
        ),
      ]);
      sheetOverview.appendRow([
        xl.TextCellValue('Ngày kết thúc'),
        xl.TextCellValue(
          widget.session.endedAt != null
              ? DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.session.endedAt!)
              : 'Đang diễn ra',
        ),
      ]);
      sheetOverview.appendRow([
        xl.TextCellValue('Quản lý đứng ca'),
        xl.TextCellValue(widget.session.managerOnDutyLabel),
      ]);
      sheetOverview.appendRow([
        xl.TextCellValue('Nhân viên trong ca'),
        xl.TextCellValue(widget.session.employeeLabels.join(', ')),
      ]);
      sheetOverview.appendRow([xl.TextCellValue('')]);

      // Summary Table
      sheetOverview.appendRow([
        xl.TextCellValue('Hạng mục'),
        xl.TextCellValue('Số lần đo'),
        xl.TextCellValue('Số lượng'),
        xl.TextCellValue('Tổng thời gian (giây)'),
        xl.TextCellValue('Trung bình'),
      ]);

      sheetOverview.appendRow([
        xl.TextCellValue('Nước'),
        xl.IntCellValue(widget.session.drinkCount),
        xl.IntCellValue(widget.session.drinkTotalQuantity),
        xl.IntCellValue(widget.session.drinkTotalSeconds),
        xl.TextCellValue('${_formatDuration(widget.session.drinkAverageSeconds)} / nước'),
      ]);

      sheetOverview.appendRow([
        xl.TextCellValue('Bánh'),
        xl.IntCellValue(widget.session.cakeCount),
        xl.IntCellValue(widget.session.cakeTotalQuantity),
        xl.IntCellValue(widget.session.cakeTotalSeconds),
        xl.TextCellValue('${_formatDuration(widget.session.cakeAverageSeconds)} / bánh'),
      ]);

      sheetOverview.appendRow([
        xl.TextCellValue('Đơn hàng'),
        xl.IntCellValue(widget.session.orderCount),
        xl.IntCellValue(widget.session.orderCount),
        xl.IntCellValue(widget.session.orderTotalSeconds),
        xl.TextCellValue('${_formatDuration(widget.session.orderAverageSeconds)} / đơn'),
      ]);

      // Detailed category sheets
      final nuocMs = _measurements
          .where((m) => m.category == PerformanceCategory.drink)
          .toList();
      final banhMs = _measurements
          .where((m) => m.category == PerformanceCategory.cake)
          .toList();
      final donMs = _measurements
          .where((m) => m.category == PerformanceCategory.order)
          .toList();

      _buildDetailSheet(excel, 'Nuoc', 'NƯỚC', nuocMs);
      _buildDetailSheet(excel, 'Banh', 'BÁNH', banhMs);
      _buildDetailSheet(excel, 'DonHang', 'ĐƠN HÀNG', donMs);

      var fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Không thể tạo file Excel');

      final dateStr = DateFormat('yyyy-MM-dd').format(widget.session.startedAt);
      final fileName = 'BaoCao_HieuNang_$dateStr.xlsx';

      if (kIsWeb) {
        final blob = html.Blob(
          [fileBytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/$fileName';
        final file = File(path);
        await file.writeAsBytes(fileBytes);
        await Share.shareXFiles([XFile(path)], text: 'Báo cáo hiệu năng $dateStr');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lỗi xuất Excel: $e',
              style: const TextStyle(fontFamily: 'BeVietnamPro'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _buildDetailSheet(
    xl.Excel excel,
    String sheetName,
    String title,
    List<GuestMeasurementModel> measurements,
  ) {
    xl.Sheet sheet = excel[sheetName];
    sheet.appendRow([xl.TextCellValue('CHI TIẾT ĐO: $title')]);
    sheet.appendRow([
      xl.TextCellValue('STT'),
      xl.TextCellValue('Số lượng'),
      xl.TextCellValue('Thời gian đo (giây)'),
      xl.TextCellValue('Thời gian định dạng'),
      xl.TextCellValue('Mã đơn / Ghi chú'),
      xl.TextCellValue('Bắt đầu lúc'),
    ]);

    for (int i = 0; i < measurements.length; i++) {
      final m = measurements[i];
      sheet.appendRow([
        xl.IntCellValue(i + 1),
        xl.IntCellValue(m.quantity),
        xl.IntCellValue(m.durationSeconds),
        xl.TextCellValue(_formatDuration(m.durationSeconds)),
        xl.TextCellValue(m.orderCode ?? ''),
        xl.TextCellValue(DateFormat('HH:mm:ss dd/MM').format(m.startedAt)),
      ]);
    }
  }

  Widget _buildSummaryCard() {
    final startStr =
        DateFormat('dd/MM/yyyy HH:mm').format(widget.session.startedAt);
    final endStr = widget.session.endedAt != null
        ? DateFormat('HH:mm').format(widget.session.endedAt!)
        : '...';

    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'THÔNG TIN PHIÊN',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  '$startStr – $endStr',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.divider),
            Row(
              children: [
                const Icon(Icons.badge_rounded, size: 16, color: AppColors.info),
                const SizedBox(width: 8),
                Text(
                  'Quản lý đứng ca: ${widget.session.managerOnDutyLabel}',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.group_rounded, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Nhân viên: ${widget.session.employeeLabels.isNotEmpty ? widget.session.employeeLabels.join(', ') : 'Chưa phân công'}',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    IconData icon,
    Color color,
    int count,
    int totalQty,
    int avgSec,
    String unit,
    List<GuestMeasurementModel> items,
  ) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.neutral,
          ),
        ),
        subtitle: Text(
          '$count lần • $totalQty $unit • TB: ${_formatDuration(avgSec)} / $unit',
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
        children: [
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Chưa có dữ liệu đo',
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  color: AppColors.textDisabled,
                ),
              ),
            )
          else ...[
            const Divider(height: 1, color: AppColors.divider),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final m = items[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: color.withOpacity(0.12),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    m.orderCode != null && m.orderCode!.isNotEmpty
                        ? '${m.orderCode} (SL: ${m.quantity})'
                        : 'Lần #${index + 1} (SL: ${m.quantity})',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: AppColors.neutral,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('HH:mm:ss').format(m.startedAt),
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Text(
                    _formatDuration(m.durationSeconds),
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.neutral,
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final nuocMs = _measurements
        .where((m) => m.category == PerformanceCategory.drink)
        .toList();
    final banhMs = _measurements
        .where((m) => m.category == PerformanceCategory.cake)
        .toList();
    final donMs = _measurements
        .where((m) => m.category == PerformanceCategory.order)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'KẾT QUẢ PHIÊN ĐO',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontWeight: FontWeight.bold,
            color: AppColors.neutral,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.neutral),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/guest');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildMetricCard(
                    'Nước',
                    Icons.local_cafe_rounded,
                    const Color(0xFF0284C7),
                    widget.session.drinkCount,
                    widget.session.drinkTotalQuantity,
                    widget.session.drinkAverageSeconds,
                    'nước',
                    nuocMs,
                  ),
                  _buildMetricCard(
                    'Bánh',
                    Icons.cake_rounded,
                    const Color(0xFFD97706),
                    widget.session.cakeCount,
                    widget.session.cakeTotalQuantity,
                    widget.session.cakeAverageSeconds,
                    'bánh',
                    banhMs,
                  ),
                  _buildMetricCard(
                    'Đơn hàng',
                    Icons.receipt_long_rounded,
                    const Color(0xFF1C4E6B),
                    widget.session.orderCount,
                    widget.session.orderCount,
                    widget.session.orderAverageSeconds,
                    'đơn',
                    donMs,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isExporting ? null : _exportExcel,
                      icon: _isExporting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.file_download_outlined, size: 20),
                      label: Text(
                        _isExporting ? 'ĐANG XUẤT FILE...' : 'XUẤT EXCEL',
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => context.go('/guest'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'VỀ TỔNG QUAN',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
