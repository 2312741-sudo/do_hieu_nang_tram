import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import '../../../models/measurement_model.dart';
import '../../../models/performance_report_model.dart';
import '../../../models/store_model.dart';
import 'performance_calculator.dart';

class ExcelExportService {
  ExcelExportService._();

  static String sanitize(String input) {
    const vietMap = {
      'à': 'a', 'á': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a',
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ẳ': 'a', 'ẵ': 'a', 'ặ': 'a',
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ẩ': 'a', 'ẫ': 'a', 'ậ': 'a',
      'è': 'e', 'é': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e',
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ể': 'e', 'ễ': 'e', 'ệ': 'e',
      'ì': 'i', 'í': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i',
      'ò': 'o', 'ó': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o',
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ổ': 'o', 'ỗ': 'o', 'ộ': 'o',
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ở': 'o', 'ỡ': 'o', 'ợ': 'o',
      'ù': 'u', 'ú': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u',
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ử': 'u', 'ữ': 'u', 'ự': 'u',
      'ỳ': 'y', 'ý': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y',
      'đ': 'd',
      'À': 'A', 'Á': 'A', 'Ả': 'A', 'Ã': 'A', 'Ạ': 'A',
      'Ă': 'A', 'Ằ': 'A', 'Ắ': 'A', 'Ẳ': 'A', 'Ẵ': 'A', 'Ặ': 'A',
      'Â': 'A', 'Ầ': 'A', 'Ấ': 'A', 'Ẩ': 'A', 'Ẫ': 'A', 'Ậ': 'A',
      'È': 'E', 'É': 'E', 'Ẻ': 'E', 'Ẽ': 'E', 'Ẹ': 'E',
      'Ê': 'E', 'Ề': 'E', 'Ế': 'E', 'Ể': 'E', 'Ễ': 'E', 'Ệ': 'E',
      'Ì': 'I', 'Í': 'I', 'Ỉ': 'I', 'Ĩ': 'I', 'Ị': 'I',
      'Ò': 'O', 'Ó': 'O', 'Ỏ': 'O', 'Õ': 'O', 'Ọ': 'O',
      'Ô': 'O', 'Ồ': 'O', 'Ố': 'O', 'Ổ': 'O', 'Ỗ': 'O', 'Ộ': 'O',
      'Ơ': 'O', 'Ờ': 'O', 'Ớ': 'O', 'Ở': 'O', 'Ỡ': 'O', 'Ợ': 'O',
      'Ù': 'U', 'Ú': 'U', 'Ủ': 'U', 'Ũ': 'U', 'Ụ': 'U',
      'Ư': 'U', 'Ừ': 'U', 'Ứ': 'U', 'Ử': 'U', 'Ữ': 'U', 'Ự': 'U',
      'Ỳ': 'Y', 'Ý': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y', 'Ỵ': 'Y',
      'Đ': 'D',
    };
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      buffer.write(vietMap[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s_\-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .toUpperCase();
  }

  static Future<void> exportPerformanceReport({
    required PerformanceReportModel report,
    required List<MeasurementModel> measurements,
    BuildContext? context,
  }) async {
    try {
      final excel = Excel.createExcel();

      // Brand styling
      final headerStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#1C4E6B'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final titleStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: ExcelColor.fromHexString('#1C4E6B'),
      );

      final labelStyle = CellStyle(bold: true);

      final timeFmt = DateFormat('HH:mm');
      final dateFmt = DateFormat('dd/MM/yyyy');
      final dateIso = DateFormat('yyyy-MM-dd').format(report.startedAt);

      final managerName = report.managerOnDutyName.isNotEmpty
          ? report.managerOnDutyName
          : (report.managerName.isNotEmpty ? report.managerName : 'Quản lý');
      final staffList = report.employeeNames.isNotEmpty
          ? report.employeeNames.join(', ')
          : 'Không có';

      // ==========================================
      // SHEET 1: TongQuan
      // ==========================================
      final sheet1 = excel['TongQuan'];
      excel.setDefaultSheet('TongQuan');

      // Title & Metadata
      sheet1.cell(CellIndex.indexByString('A1')).value = TextCellValue('BÁO CÁO HIỆU NĂNG PHA CHẾ & XỬ LÝ ĐƠN HÀNG');
      sheet1.cell(CellIndex.indexByString('A1')).cellStyle = titleStyle;

      sheet1.cell(CellIndex.indexByString('A3')).value = TextCellValue('Cửa hàng:');
      sheet1.cell(CellIndex.indexByString('A3')).cellStyle = labelStyle;
      sheet1.cell(CellIndex.indexByString('B3')).value = TextCellValue(report.storeName);

      sheet1.cell(CellIndex.indexByString('A4')).value = TextCellValue('Ngày thực hiện:');
      sheet1.cell(CellIndex.indexByString('A4')).cellStyle = labelStyle;
      sheet1.cell(CellIndex.indexByString('B4')).value = TextCellValue(dateFmt.format(report.startedAt));

      sheet1.cell(CellIndex.indexByString('A5')).value = TextCellValue('Thời gian ca:');
      sheet1.cell(CellIndex.indexByString('A5')).cellStyle = labelStyle;
      sheet1.cell(CellIndex.indexByString('B5')).value = TextCellValue('${timeFmt.format(report.startedAt)} - ${timeFmt.format(report.endedAt)}');

      sheet1.cell(CellIndex.indexByString('A6')).value = TextCellValue('Quản lý đứng ca:');
      sheet1.cell(CellIndex.indexByString('A6')).cellStyle = labelStyle;
      sheet1.cell(CellIndex.indexByString('B6')).value = TextCellValue(managerName);

      sheet1.cell(CellIndex.indexByString('A7')).value = TextCellValue('Nhân viên trong ca:');
      sheet1.cell(CellIndex.indexByString('A7')).cellStyle = labelStyle;
      sheet1.cell(CellIndex.indexByString('B7')).value = TextCellValue(staffList);

      // Table Header
      final headers1 = ['Hạng mục', 'Số lần đo', 'Số lượng', 'Tổng thời gian', 'Thời gian trung bình'];
      for (int c = 0; c < headers1.length; c++) {
        final cell = sheet1.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 9));
        cell.value = TextCellValue(headers1[c]);
        cell.cellStyle = headerStyle;
      }

      // Rows
      final summaryRows = [
        [
          'Nước',
          report.drinkMeasurementCount,
          report.drinkTotalQuantity,
          PerformanceCalculator.formatSeconds(report.drinkTotalSeconds),
          '${PerformanceCalculator.formatSeconds(report.drinkAverageSeconds)} / nước',
        ],
        [
          'Bánh',
          report.cakeMeasurementCount,
          report.cakeTotalQuantity,
          PerformanceCalculator.formatSeconds(report.cakeTotalSeconds),
          '${PerformanceCalculator.formatSeconds(report.cakeAverageSeconds)} / bánh',
        ],
        [
          'Đơn hàng',
          report.orderCount,
          report.orderCount,
          PerformanceCalculator.formatSeconds(report.orderTotalSeconds),
          '${PerformanceCalculator.formatSeconds(report.orderAverageSeconds)} / đơn',
        ],
      ];

      for (int r = 0; r < summaryRows.length; r++) {
        for (int c = 0; c < summaryRows[r].length; c++) {
          final cell = sheet1.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 10 + r));
          final val = summaryRows[r][c];
          if (val is int) {
            cell.value = IntCellValue(val);
          } else {
            cell.value = TextCellValue(val.toString());
          }
        }
      }

      sheet1.setColumnWidth(0, 18);
      sheet1.setColumnWidth(1, 14);
      sheet1.setColumnWidth(2, 14);
      sheet1.setColumnWidth(3, 18);
      sheet1.setColumnWidth(4, 26);

      // ==========================================
      // SHEET 2: Nuoc
      // ==========================================
      final sheet2 = excel['Nuoc'];
      final drinkMeasurements = measurements
          .where((m) => m.category == PerformanceCategory.drink && m.status == MeasurementStatus.completed)
          .toList();

      final headers2 = [
        'STT',
        'Ngày',
        'Giờ bắt đầu',
        'Giờ kết thúc',
        'Quản lý đứng ca',
        'Cửa hàng',
        'Số lượng nước',
        'Tổng thời gian',
        'Thời gian / nước',
      ];
      for (int c = 0; c < headers2.length; c++) {
        final cell = sheet2.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
        cell.value = TextCellValue(headers2[c]);
        cell.cellStyle = headerStyle;
      }

      for (int i = 0; i < drinkMeasurements.length; i++) {
        final m = drinkMeasurements[i];
        final row = [
          IntCellValue(i + 1),
          TextCellValue(dateFmt.format(m.startedAt)),
          TextCellValue(timeFmt.format(m.startedAt)),
          TextCellValue(m.completedAt != null ? timeFmt.format(m.completedAt!) : '--:--'),
          TextCellValue(managerName),
          TextCellValue(report.storeName),
          IntCellValue(m.quantity),
          TextCellValue(PerformanceCalculator.formatSeconds(m.durationSeconds)),
          TextCellValue(PerformanceCalculator.formatSeconds(m.secondsPerItem)),
        ];
        for (int c = 0; c < row.length; c++) {
          sheet2.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1)).value = row[c];
        }
      }
      for (int c = 0; c < headers2.length; c++) {
        sheet2.setColumnWidth(c, 16);
      }

      // ==========================================
      // SHEET 3: Banh
      // ==========================================
      final sheet3 = excel['Banh'];
      final cakeMeasurements = measurements
          .where((m) => m.category == PerformanceCategory.cake && m.status == MeasurementStatus.completed)
          .toList();

      final headers3 = [
        'STT',
        'Ngày',
        'Giờ bắt đầu',
        'Giờ kết thúc',
        'Quản lý đứng ca',
        'Cửa hàng',
        'Số bánh',
        'Tổng thời gian',
        'Thời gian / bánh',
      ];
      for (int c = 0; c < headers3.length; c++) {
        final cell = sheet3.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
        cell.value = TextCellValue(headers3[c]);
        cell.cellStyle = headerStyle;
      }

      for (int i = 0; i < cakeMeasurements.length; i++) {
        final m = cakeMeasurements[i];
        final row = [
          IntCellValue(i + 1),
          TextCellValue(dateFmt.format(m.startedAt)),
          TextCellValue(timeFmt.format(m.startedAt)),
          TextCellValue(m.completedAt != null ? timeFmt.format(m.completedAt!) : '--:--'),
          TextCellValue(managerName),
          TextCellValue(report.storeName),
          IntCellValue(m.quantity),
          TextCellValue(PerformanceCalculator.formatSeconds(m.durationSeconds)),
          TextCellValue(PerformanceCalculator.formatSeconds(m.secondsPerItem)),
        ];
        for (int c = 0; c < row.length; c++) {
          sheet3.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1)).value = row[c];
        }
      }
      for (int c = 0; c < headers3.length; c++) {
        sheet3.setColumnWidth(c, 16);
      }

      // ==========================================
      // SHEET 4: DonHang
      // ==========================================
      final sheet4 = excel['DonHang'];
      final orderMeasurements = measurements
          .where((m) => m.category == PerformanceCategory.order && m.status == MeasurementStatus.completed)
          .toList();

      final headers4 = [
        'STT',
        'Ngày',
        'Mã đơn',
        'Giờ bắt đầu',
        'Giờ kết thúc',
        'Quản lý đứng ca',
        'Cửa hàng',
        'Thời gian xử lý',
      ];
      for (int c = 0; c < headers4.length; c++) {
        final cell = sheet4.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
        cell.value = TextCellValue(headers4[c]);
        cell.cellStyle = headerStyle;
      }

      for (int i = 0; i < orderMeasurements.length; i++) {
        final m = orderMeasurements[i];
        final row = [
          IntCellValue(i + 1),
          TextCellValue(dateFmt.format(m.startedAt)),
          TextCellValue(m.orderCode ?? ''),
          TextCellValue(timeFmt.format(m.startedAt)),
          TextCellValue(m.completedAt != null ? timeFmt.format(m.completedAt!) : '--:--'),
          TextCellValue(managerName),
          TextCellValue(report.storeName),
          TextCellValue(PerformanceCalculator.formatSeconds(m.durationSeconds)),
        ];
        for (int c = 0; c < row.length; c++) {
          sheet4.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1)).value = row[c];
        }
      }
      for (int c = 0; c < headers4.length; c++) {
        sheet4.setColumnWidth(c, 16);
      }

      // ==========================================
      // SHEET 5: Loi_Phat_Sinh (Incidents)
      // ==========================================
      if (report.incidents.isNotEmpty) {
        final sheet5 = excel['Loi_Phat_Sinh'];
        final incidentHeaders = [
          'STT',
          'Thời gian',
          'Phân loại lỗi',
          'Chi tiết sự cố / lỗi',
          'Nhân sự liên quan',
          'Người ghi nhận',
        ];
        for (int c = 0; c < incidentHeaders.length; c++) {
          final cell = sheet5.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
          cell.value = TextCellValue(incidentHeaders[c]);
          cell.cellStyle = headerStyle;
        }

        for (int i = 0; i < report.incidents.length; i++) {
          final inc = report.incidents[i];
          final row = [
            IntCellValue(i + 1),
            TextCellValue(timeFmt.format(inc.timestamp)),
            TextCellValue(inc.category),
            TextCellValue(inc.description),
            TextCellValue(inc.staffName ?? '--'),
            TextCellValue(inc.reportedBy),
          ];
          for (int c = 0; c < row.length; c++) {
            sheet5.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1)).value = row[c];
          }
        }
        sheet5.setColumnWidth(0, 8);
        sheet5.setColumnWidth(1, 14);
        sheet5.setColumnWidth(2, 22);
        sheet5.setColumnWidth(3, 40);
        sheet5.setColumnWidth(4, 20);
        sheet5.setColumnWidth(5, 20);
      }

      // Clean up default Sheet1 if exists
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // ==========================================
      // SAVE & EXPORT
      // ==========================================
      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('Không thể tạo nội dung file Excel.');
      }

      final storeSanitized = sanitize(report.storeName);
      final fileName = 'BaoCao_HieuNang_${storeSanitized}_$dateIso.xlsx';

      if (kIsWeb) {
        // Web export: In-memory byte array triggered via browser download
        final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tải xuống $fileName'),
              backgroundColor: const Color(0xFF1A6B5A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Mobile (Android / iOS): Save to cache directory and share
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(fileBytes);

        Rect? sharePositionOrigin;
        if (context != null && context.mounted) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
          }
        }

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Báo cáo hiệu năng $fileName',
          subject: 'Báo cáo hiệu năng ${report.storeName}',
          sharePositionOrigin: sharePositionOrigin,
        );
      }
    } catch (e) {
      debugPrint('Excel export error: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất Excel: $e'),
            backgroundColor: const Color(0xFFC8102E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  static Future<void> exportLeaderboardReport({
    required StoreModel store,
    required List<StaffPerformanceStats> statsList,
    required String dateRangeLabel,
    BuildContext? context,
  }) async {
    try {
      final excel = Excel.createExcel();

      final headerStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#1C4E6B'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      final titleStyle = CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: ExcelColor.fromHexString('#1C4E6B'),
      );

      final labelStyle = CellStyle(bold: true);

      final sheet = excel['BangXepHang'];
      excel.setDefaultSheet('BangXepHang');

      // Title & Metadata
      sheet.cell(CellIndex.indexByString('A1')).value =
          TextCellValue('BẢNG XẾP HẠNG HIỆU SUẤT NHÂN VIÊN');
      sheet.cell(CellIndex.indexByString('A1')).cellStyle = titleStyle;

      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Cửa hàng:');
      sheet.cell(CellIndex.indexByString('A3')).cellStyle = labelStyle;
      sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue(store.name);

      sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Khoảng thời gian:');
      sheet.cell(CellIndex.indexByString('A4')).cellStyle = labelStyle;
      sheet.cell(CellIndex.indexByString('B4')).value = TextCellValue(dateRangeLabel);

      sheet.cell(CellIndex.indexByString('A5')).value = TextCellValue('Tiêu chuẩn áp dụng:');
      sheet.cell(CellIndex.indexByString('A5')).cellStyle = labelStyle;
      sheet.cell(CellIndex.indexByString('B5')).value = TextCellValue(
        'Nước: ${store.performanceStandards.drinkStandardSeconds}s/ly | Bánh: ${store.performanceStandards.cakeStandardSeconds}s/bánh | Đơn: ${store.performanceStandards.orderStandardSeconds}s/đơn',
      );

      sheet.cell(CellIndex.indexByString('A6')).value = TextCellValue('Ngày giờ xuất:');
      sheet.cell(CellIndex.indexByString('A6')).cellStyle = labelStyle;
      sheet.cell(CellIndex.indexByString('B6')).value =
          TextCellValue(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()));

      // Table Header
      final headers = [
        'Hạng',
        'Tên nhân viên',
        'Số ca làm',
        'SL Nước',
        'TB Nước (s)',
        '% HS Nước',
        'SL Bánh',
        'TB Bánh (s)',
        '% HS Bánh',
        'Tổng sản phẩm',
        '% HS Tổng Hợp',
        'Đánh giá',
      ];

      for (int c = 0; c < headers.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 8));
        cell.value = TextCellValue(headers[c]);
        cell.cellStyle = headerStyle;
      }

      // Rows
      for (int r = 0; r < statsList.length; r++) {
        final s = statsList[r];
        final rowValues = [
          s.rank,
          s.staffName,
          s.sessionCount,
          s.drinkQuantity,
          s.drinkAverageSeconds,
          s.drinkEfficiencyPercent != null
              ? '${s.drinkEfficiencyPercent!.toStringAsFixed(1)}%'
              : '-',
          s.cakeQuantity,
          s.cakeAverageSeconds,
          s.cakeEfficiencyPercent != null
              ? '${s.cakeEfficiencyPercent!.toStringAsFixed(1)}%'
              : '-',
          s.totalProducts,
          '${s.totalEfficiencyPercent.toStringAsFixed(1)}%',
          s.performanceRating,
        ];

        for (int c = 0; c < rowValues.length; c++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 9 + r));
          final val = rowValues[c];
          if (val is int) {
            cell.value = IntCellValue(val);
          } else {
            cell.value = TextCellValue(val.toString());
          }
        }
      }

      sheet.setColumnWidth(0, 8);
      sheet.setColumnWidth(1, 24);
      sheet.setColumnWidth(2, 12);
      sheet.setColumnWidth(3, 12);
      sheet.setColumnWidth(4, 14);
      sheet.setColumnWidth(5, 14);
      sheet.setColumnWidth(6, 12);
      sheet.setColumnWidth(7, 14);
      sheet.setColumnWidth(8, 14);
      sheet.setColumnWidth(9, 16);
      sheet.setColumnWidth(10, 18);
      sheet.setColumnWidth(11, 16);

      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('Không thể tạo file Excel.');
      }

      final dateIso = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final cleanStore = sanitize(store.name);
      final fileName = 'BXH_HIEU_SUAT_${cleanStore}_$dateIso.xlsx';

      if (kIsWeb) {
        final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tải xuống $fileName'),
              backgroundColor: const Color(0xFF107C41),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(fileBytes);

        Rect? sharePositionOrigin;
        if (context != null && context.mounted) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null && box.hasSize) {
            sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
          }
        }

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Bảng xếp hạng hiệu suất $fileName',
          subject: 'Bảng xếp hạng hiệu suất ${store.name}',
          sharePositionOrigin: sharePositionOrigin,
        );
      }
    } catch (e) {
      debugPrint('Excel export error: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất Excel: $e'),
            backgroundColor: const Color(0xFFC8102E),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
