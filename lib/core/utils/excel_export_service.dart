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

  static Excel createPerformanceReportWorkbook({
    required PerformanceReportModel report,
    required List<MeasurementModel> measurements,
  }) {
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

      final sectionHeaderStyle = CellStyle(
        bold: true,
        fontSize: 11,
        fontColorHex: ExcelColor.fromHexString('#1C4E6B'),
      );

      final labelStyle = CellStyle(bold: true);

      final passStyle = CellStyle(
        fontColorHex: ExcelColor.fromHexString('#0F766E'),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      final failStyle = CellStyle(
        fontColorHex: ExcelColor.fromHexString('#B91C1C'),
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );

      final centerStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
      );

      final timeFmt = DateFormat('HH:mm');
      final dateFmt = DateFormat('dd/MM/yyyy');

      final managerName = report.managerOnDutyName.isNotEmpty
          ? report.managerOnDutyName
          : (report.managerName.isNotEmpty ? report.managerName : 'Quản lý');

      final reporterName = report.managerName.isNotEmpty ? report.managerName : managerName;

      final durationMinutes = report.endedAt.difference(report.startedAt).inMinutes;
      final durationHours = durationMinutes ~/ 60;
      final durationRemainingMins = durationMinutes % 60;
      final durationStr = durationHours > 0
          ? '$durationHours giờ $durationRemainingMins phút'
          : '$durationMinutes phút';

      // Standards (SLA)
      final stdSnapshot = report.standardSnapshot;
      final stdDrink = stdSnapshot['drink'] ?? 120;
      final stdCake = stdSnapshot['cake'] ?? 120;
      final stdOrder = stdSnapshot['order'] ?? 180;

      // Classify staff by department
      final drinkStaffList = <String>[];
      final cakeStaffList = <String>[];
      final serviceStaffList = <String>[];
      final otherStaffList = <String>[];

      for (final name in report.employeeNames) {
        final clean = name.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
        if (name.contains('(Nước)') || name.toLowerCase().contains('(dr)')) {
          drinkStaffList.add(clean);
        } else if (name.contains('(Bánh)') || name.toLowerCase().contains('(ck)')) {
          cakeStaffList.add(clean);
        } else if (name.contains('(Phục vụ)') || name.toLowerCase().contains('(lo)')) {
          serviceStaffList.add(clean);
        } else {
          otherStaffList.add(clean);
        }
      }

      // ==========================================
      // SHEET 1: TongQuan (Tổng quan & SLA)
      // ==========================================
      final sheet1 = excel['TongQuan'];
      excel.setDefaultSheet('TongQuan');

      // Title
      sheet1.cell(CellIndex.indexByString('A1')).value =
          TextCellValue('BÁO CÁO HIỆU NĂNG PHA CHẾ & XỬ LÝ ĐƠN HÀNG - TRẠM');
      sheet1.cell(CellIndex.indexByString('A1')).cellStyle = titleStyle;

      // Metadata Ca làm việc
      sheet1.cell(CellIndex.indexByString('A3')).value = TextCellValue('Cửa hàng:');
      sheet1.cell(CellIndex.indexByString('A3')).cellStyle = labelStyle;
      sheet1.cell(CellIndex.indexByString('B3')).value = TextCellValue(report.storeName);

      sheet1.cell(CellIndex.indexByString('A4')).value = TextCellValue('Ngày thực hiện:');
      sheet1.cell(CellIndex.indexByString('A4')).cellStyle = labelStyle;
      sheet1.cell(CellIndex.indexByString('B4')).value = TextCellValue(dateFmt.format(report.startedAt));

      sheet1.cell(CellIndex.indexByString('A5')).value = TextCellValue('Thời gian ca:');
      sheet1.cell(CellIndex.indexByString('A5')).cellStyle = labelStyle;
      sheet1.cell(CellIndex.indexByString('B5')).value =
          TextCellValue('${timeFmt.format(report.startedAt)} - ${timeFmt.format(report.endedAt)} (Thời lượng: $durationStr)');

      sheet1.cell(CellIndex.indexByString('A6')).value = TextCellValue('Quản lý đứng ca:');
      sheet1.cell(CellIndex.indexByString('A6')).cellStyle = labelStyle;
      sheet1.cell(CellIndex.indexByString('B6')).value = TextCellValue(managerName);

      sheet1.cell(CellIndex.indexByString('A7')).value = TextCellValue('Người lập báo cáo:');
      sheet1.cell(CellIndex.indexByString('A7')).cellStyle = labelStyle;
      sheet1.cell(CellIndex.indexByString('B7')).value = TextCellValue(reporterName);

      sheet1.cell(CellIndex.indexByString('A8')).value = TextCellValue('Thời điểm nộp:');
      sheet1.cell(CellIndex.indexByString('A8')).cellStyle = labelStyle;
      sheet1.cell(CellIndex.indexByString('B8')).value = TextCellValue(
        report.submittedAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(report.submittedAt!) : '--',
      );

      // Section 1: Phân bổ nhân sự bộ phận
      sheet1.cell(CellIndex.indexByString('A10')).value =
          TextCellValue('I. PHÂN BỔ NHÂN SỰ THEO BỘ PHẬN TRONG CA');
      sheet1.cell(CellIndex.indexByString('A10')).cellStyle = sectionHeaderStyle;

      final staffHeaders = ['Bộ phận', 'Nhân sự đảm nhiệm', 'Nhiệm vụ chính trong ca'];
      for (int c = 0; c < staffHeaders.length; c++) {
        final cell = sheet1.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 11));
        cell.value = TextCellValue(staffHeaders[c]);
        cell.cellStyle = headerStyle;
      }

      final staffRows = [
        ['Quản lý đứng ca', managerName, 'Điều hành, phân công & giám sát vận hành ca'],
        [
          'Pha chế (Nước - dr)',
          drinkStaffList.isNotEmpty ? drinkStaffList.join(', ') : 'Không phân bổ',
          'Pha chế đồ uống theo tiêu chuẩn SLA',
        ],
        [
          'Làm bánh (Bánh - ck)',
          cakeStaffList.isNotEmpty ? cakeStaffList.join(', ') : 'Không phân bổ',
          'Nướng, trang trí & ra bánh theo tiêu chuẩn SLA',
        ],
        [
          'Phục vụ & Line order (lo)',
          serviceStaffList.isNotEmpty
              ? serviceStaffList.join(', ')
              : (otherStaffList.isNotEmpty ? otherStaffList.join(', ') : 'Không phân bổ'),
          'Thu ngân, kiểm tra đơn hàng & giao đồ cho khách',
        ],
      ];

      for (int r = 0; r < staffRows.length; r++) {
        for (int c = 0; c < staffRows[r].length; c++) {
          final cell = sheet1.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 12 + r));
          cell.value = TextCellValue(staffRows[r][c]);
          if (c == 0) cell.cellStyle = labelStyle;
        }
      }

      // Section 2: Tổng hợp hiệu năng & Đối chiếu SLA
      sheet1.cell(CellIndex.indexByString('A17')).value =
          TextCellValue('II. BẢNG TỔNG HỢP HIỆU NĂNG & ĐỐI CHIẾU TIÊU CHUẨN (SLA)');
      sheet1.cell(CellIndex.indexByString('A17')).cellStyle = sectionHeaderStyle;

      final kpiHeaders = [
        'Hạng mục',
        'Số lượt đo',
        'Tổng số lượng',
        'Tổng thời gian',
        'TB thực tế / SP',
        'Tiêu chuẩn (SLA)',
        'Chênh lệch (+/-)',
        'Hiệu suất (%)',
        'Đánh giá kết quả',
      ];
      for (int c = 0; c < kpiHeaders.length; c++) {
        final cell = sheet1.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 18));
        cell.value = TextCellValue(kpiHeaders[c]);
        cell.cellStyle = headerStyle;
      }

      // Calculations for Drink
      final diffDrink = report.drinkAverageSeconds - stdDrink;
      final diffDrinkStr = report.drinkMeasurementCount == 0
          ? '-'
          : (diffDrink <= 0 ? '-${-diffDrink}s (Nhanh hơn)' : '+$diffDrink s (Chậm hơn)');
      final effDrinkStr = report.drinkAverageSeconds > 0
          ? '${(stdDrink / report.drinkAverageSeconds * 100).toStringAsFixed(1)}%'
          : '-';
      final isDrinkPass = report.drinkAverageSeconds <= stdDrink;
      final evalDrinkStr = report.drinkMeasurementCount == 0
          ? 'Không đo'
          : (isDrinkPass ? 'ĐẠT CHUẨN' : 'VƯỢT CHUẨN (+${diffDrink}s)');

      // Calculations for Cake
      final diffCake = report.cakeAverageSeconds - stdCake;
      final diffCakeStr = report.cakeMeasurementCount == 0
          ? '-'
          : (diffCake <= 0 ? '-${-diffCake}s (Nhanh hơn)' : '+$diffCake s (Chậm hơn)');
      final effCakeStr = report.cakeAverageSeconds > 0
          ? '${(stdCake / report.cakeAverageSeconds * 100).toStringAsFixed(1)}%'
          : '-';
      final isCakePass = report.cakeAverageSeconds <= stdCake;
      final evalCakeStr = report.cakeMeasurementCount == 0
          ? 'Không đo'
          : (isCakePass ? 'ĐẠT CHUẨN' : 'VƯỢT CHUẨN (+${diffCake}s)');

      // Calculations for Order
      final diffOrder = report.orderAverageSeconds - stdOrder;
      final diffOrderStr = report.orderCount == 0
          ? '-'
          : (diffOrder <= 0 ? '-${-diffOrder}s (Nhanh hơn)' : '+$diffOrder s (Chậm hơn)');
      final effOrderStr = report.orderAverageSeconds > 0
          ? '${(stdOrder / report.orderAverageSeconds * 100).toStringAsFixed(1)}%'
          : '-';
      final isOrderPass = report.orderAverageSeconds <= stdOrder;
      final evalOrderStr = report.orderCount == 0
          ? 'Không đo'
          : (isOrderPass ? 'ĐẠT CHUẨN' : 'VƯỢT CHUẨN (+${diffOrder}s)');

      final kpiRows = [
        [
          'Nước',
          report.drinkMeasurementCount,
          '${report.drinkTotalQuantity} ly',
          PerformanceCalculator.formatSeconds(report.drinkTotalSeconds),
          '${PerformanceCalculator.formatSeconds(report.drinkAverageSeconds)} / ly',
          '${stdDrink}s / ly',
          diffDrinkStr,
          effDrinkStr,
          evalDrinkStr,
        ],
        [
          'Bánh',
          report.cakeMeasurementCount,
          '${report.cakeTotalQuantity} bánh',
          PerformanceCalculator.formatSeconds(report.cakeTotalSeconds),
          '${PerformanceCalculator.formatSeconds(report.cakeAverageSeconds)} / bánh',
          '${stdCake}s / bánh',
          diffCakeStr,
          effCakeStr,
          evalCakeStr,
        ],
        [
          'Đơn hàng',
          report.orderCount,
          '${report.orderCount} đơn',
          PerformanceCalculator.formatSeconds(report.orderTotalSeconds),
          '${PerformanceCalculator.formatSeconds(report.orderAverageSeconds)} / đơn',
          '${stdOrder}s / đơn',
          diffOrderStr,
          effOrderStr,
          evalOrderStr,
        ],
      ];

      for (int r = 0; r < kpiRows.length; r++) {
        final row = kpiRows[r];
        for (int c = 0; c < row.length; c++) {
          final cell = sheet1.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 19 + r));
          final val = row[c];
          if (val is int) {
            cell.value = IntCellValue(val);
            cell.cellStyle = centerStyle;
          } else {
            cell.value = TextCellValue(val.toString());
            if (c == 0) {
              cell.cellStyle = labelStyle;
            } else if (c == 8) {
              final isPass = r == 0 ? isDrinkPass : (r == 1 ? isCakePass : isOrderPass);
              final count = r == 0 ? report.drinkMeasurementCount : (r == 1 ? report.cakeMeasurementCount : report.orderCount);
              cell.cellStyle = count == 0 ? centerStyle : (isPass ? passStyle : failStyle);
            } else if (c >= 1 && c <= 7) {
              cell.cellStyle = centerStyle;
            }
          }
        }
      }

      // Section 3: Tóm tắt vận hành trong ca
      sheet1.cell(CellIndex.indexByString('A23')).value = TextCellValue('III. TỔNG KẾT VẬN HÀNH TRONG CA');
      sheet1.cell(CellIndex.indexByString('A23')).cellStyle = sectionHeaderStyle;

      sheet1.cell(CellIndex.indexByString('A24')).value = TextCellValue('Sự cố & lỗi phát sinh:');
      sheet1.cell(CellIndex.indexByString('A24')).cellStyle = labelStyle;
      sheet1.cell(CellIndex.indexByString('B24')).value = TextCellValue(
        report.incidents.isNotEmpty
            ? '${report.incidents.length} sự cố ghi nhận (Xem chi tiết tại Sheet Loi_Phat_Sinh)'
            : '0 sự cố (Ca làm việc vận hành trơn tru)',
      );

      sheet1.cell(CellIndex.indexByString('A25')).value = TextCellValue('Báo cáo kết thúc ca:');
      sheet1.cell(CellIndex.indexByString('A25')).cellStyle = labelStyle;
      sheet1.cell(CellIndex.indexByString('B25')).value = TextCellValue(
        report.formResponses.isNotEmpty
            ? 'Đã hoàn tất (${report.formResponses.length} mục kiểm tra - Xem chi tiết tại Sheet BaoCao_KetCa)'
            : 'Không có câu hỏi khảo sát kết ca',
      );

      sheet1.setColumnWidth(0, 20);
      sheet1.setColumnWidth(1, 14);
      sheet1.setColumnWidth(2, 16);
      sheet1.setColumnWidth(3, 16);
      sheet1.setColumnWidth(4, 20);
      sheet1.setColumnWidth(5, 18);
      sheet1.setColumnWidth(6, 22);
      sheet1.setColumnWidth(7, 16);
      sheet1.setColumnWidth(8, 24);

      // ==========================================
      // SHEET 2: BaoCao_KetCa (Form Checklist & Responses)
      // ==========================================
      if (report.formResponses.isNotEmpty) {
        final sheetKetCa = excel['BaoCao_KetCa'];
        final headersKetCa = [
          'STT',
          'Tiêu chí kiểm tra / Khảo sát kết ca',
          'Phân loại câu hỏi',
          'Câu trả lời / Kết quả ghi nhận',
          'Đánh giá trạng thái',
        ];
        for (int c = 0; c < headersKetCa.length; c++) {
          final cell = sheetKetCa.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
          cell.value = TextCellValue(headersKetCa[c]);
          cell.cellStyle = headerStyle;
        }

        int rowIndex = 1;
        report.formResponses.forEach((key, rawValue) {
          String title = key;
          String type = 'text';
          dynamic val;

          if (rawValue is Map) {
            title = rawValue['title']?.toString() ?? key;
            type = rawValue['type']?.toString() ?? 'text';
            val = rawValue['value'];
          } else {
            val = rawValue;
          }

          String displayVal = '--';
          String evalStr = 'Ghi nhận';
          bool isPass = true;

          if (type == 'checkbox') {
            final b = val == true || val == 'true';
            displayVal = b ? 'ĐÃ HOÀN THÀNH' : 'CHƯA HOÀN THÀNH';
            evalStr = b ? 'ĐẠT' : 'CHƯA ĐẠT';
            isPass = b;
          } else if (type == 'rating') {
            final numVal = (val is num) ? val.toInt() : int.tryParse(val.toString()) ?? 0;
            displayVal = '$numVal / 5 ⭐';
            if (numVal >= 4) {
              evalStr = 'TỐT';
              isPass = true;
            } else if (numVal == 3) {
              evalStr = 'TRUNG BÌNH';
              isPass = true;
            } else {
              evalStr = 'CẦN CẢI THIỆN';
              isPass = false;
            }
          } else if (type == 'number') {
            displayVal = val?.toString() ?? '0';
            evalStr = 'ĐẠT';
            isPass = true;
          } else {
            displayVal = val?.toString() ?? '';
            evalStr = 'GHI NHẬN';
            isPass = true;
          }

          sheetKetCa.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = IntCellValue(rowIndex);
          sheetKetCa.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).cellStyle = centerStyle;

          sheetKetCa.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(title);

          sheetKetCa.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(
            type == 'checkbox'
                ? 'Xác nhận hoàn tất'
                : (type == 'rating' ? 'Đánh giá điểm sao' : (type == 'number' ? 'Số liệu kiểm kê' : 'Văn bản phản hồi')),
          );
          sheetKetCa.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).cellStyle = centerStyle;

          sheetKetCa.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(displayVal);

          final evalCell = sheetKetCa.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex));
          evalCell.value = TextCellValue(evalStr);
          evalCell.cellStyle = isPass ? passStyle : failStyle;

          rowIndex++;
        });

        sheetKetCa.setColumnWidth(0, 8);
        sheetKetCa.setColumnWidth(1, 40);
        sheetKetCa.setColumnWidth(2, 22);
        sheetKetCa.setColumnWidth(3, 30);
        sheetKetCa.setColumnWidth(4, 20);
      }

      // ==========================================
      // SHEET 3: Nuoc (Chi tiết đo Nước)
      // ==========================================
      final sheet2 = excel['Nuoc'];
      final drinkMeasurements = measurements
          .where((m) => m.category == PerformanceCategory.drink && m.status == MeasurementStatus.completed)
          .toList();

      final headers2 = [
        'STT',
        'Lần đo',
        'Ngày',
        'Giờ bắt đầu',
        'Giờ kết thúc',
        'Số lượng ly',
        'Tổng thời gian (s)',
        'Định dạng',
        'Thời gian / 1 ly',
        'Chuẩn SLA (s)',
        'Chênh lệch (+/-s)',
        'Đánh giá SLA',
        'Nhân viên pha chế',
        'Người thực hiện đo',
      ];
      for (int c = 0; c < headers2.length; c++) {
        final cell = sheet2.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
        cell.value = TextCellValue(headers2[c]);
        cell.cellStyle = headerStyle;
      }

      for (int i = 0; i < drinkMeasurements.length; i++) {
        final m = drinkMeasurements[i];
        final diff = m.secondsPerItem - stdDrink;
        final isPass = m.secondsPerItem <= stdDrink;
        final diffStr = diff <= 0 ? '-${-diff}s' : '+$diff s';
        final evalStr = isPass ? 'ĐẠT' : 'VƯỢT CHUẨN (+$diff s)';
        final staff = (m.staffName != null && m.staffName!.isNotEmpty)
            ? m.staffName!
            : (drinkStaffList.isNotEmpty ? drinkStaffList.join(', ') : '--');
        final measuredBy = (m.measuredByName != null && m.measuredByName!.isNotEmpty)
            ? m.measuredByName!
            : managerName;

        final rowValues = [
          i + 1,
          'Lần ${i + 1}',
          dateFmt.format(m.startedAt),
          timeFmt.format(m.startedAt),
          m.completedAt != null ? timeFmt.format(m.completedAt!) : '--:--',
          m.quantity,
          m.durationSeconds,
          PerformanceCalculator.formatSeconds(m.durationSeconds),
          PerformanceCalculator.formatSeconds(m.secondsPerItem),
          '${stdDrink}s',
          diffStr,
          evalStr,
          staff,
          measuredBy,
        ];

        for (int c = 0; c < rowValues.length; c++) {
          final cell = sheet2.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1));
          final val = rowValues[c];
          if (val is int) {
            cell.value = IntCellValue(val);
            cell.cellStyle = centerStyle;
          } else {
            cell.value = TextCellValue(val.toString());
            if (c == 11) {
              cell.cellStyle = isPass ? passStyle : failStyle;
            } else if (c == 1 || c == 2 || c == 3 || c == 4 || c == 7 || c == 8 || c == 9 || c == 10) {
              cell.cellStyle = centerStyle;
            }
          }
        }
      }

      sheet2.setColumnWidth(0, 8);
      sheet2.setColumnWidth(1, 12);
      sheet2.setColumnWidth(2, 14);
      sheet2.setColumnWidth(3, 14);
      sheet2.setColumnWidth(4, 14);
      sheet2.setColumnWidth(5, 14);
      sheet2.setColumnWidth(6, 18);
      sheet2.setColumnWidth(7, 14);
      sheet2.setColumnWidth(8, 16);
      sheet2.setColumnWidth(9, 14);
      sheet2.setColumnWidth(10, 16);
      sheet2.setColumnWidth(11, 22);
      sheet2.setColumnWidth(12, 22);
      sheet2.setColumnWidth(13, 22);

      // ==========================================
      // SHEET 4: Banh (Chi tiết đo Bánh)
      // ==========================================
      final sheet3 = excel['Banh'];
      final cakeMeasurements = measurements
          .where((m) => m.category == PerformanceCategory.cake && m.status == MeasurementStatus.completed)
          .toList();

      final headers3 = [
        'STT',
        'Lần đo',
        'Ngày',
        'Giờ bắt đầu',
        'Giờ kết thúc',
        'Số lượng bánh',
        'Tổng thời gian (s)',
        'Định dạng',
        'Thời gian / 1 bánh',
        'Chuẩn SLA (s)',
        'Chênh lệch (+/-s)',
        'Đánh giá SLA',
        'Nhân viên làm bánh',
        'Người thực hiện đo',
      ];
      for (int c = 0; c < headers3.length; c++) {
        final cell = sheet3.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
        cell.value = TextCellValue(headers3[c]);
        cell.cellStyle = headerStyle;
      }

      for (int i = 0; i < cakeMeasurements.length; i++) {
        final m = cakeMeasurements[i];
        final diff = m.secondsPerItem - stdCake;
        final isPass = m.secondsPerItem <= stdCake;
        final diffStr = diff <= 0 ? '-${-diff}s' : '+$diff s';
        final evalStr = isPass ? 'ĐẠT' : 'VƯỢT CHUẨN (+$diff s)';
        final staff = (m.staffName != null && m.staffName!.isNotEmpty)
            ? m.staffName!
            : (cakeStaffList.isNotEmpty ? cakeStaffList.join(', ') : '--');
        final measuredBy = (m.measuredByName != null && m.measuredByName!.isNotEmpty)
            ? m.measuredByName!
            : managerName;

        final rowValues = [
          i + 1,
          'Lần ${i + 1}',
          dateFmt.format(m.startedAt),
          timeFmt.format(m.startedAt),
          m.completedAt != null ? timeFmt.format(m.completedAt!) : '--:--',
          m.quantity,
          m.durationSeconds,
          PerformanceCalculator.formatSeconds(m.durationSeconds),
          PerformanceCalculator.formatSeconds(m.secondsPerItem),
          '${stdCake}s',
          diffStr,
          evalStr,
          staff,
          measuredBy,
        ];

        for (int c = 0; c < rowValues.length; c++) {
          final cell = sheet3.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1));
          final val = rowValues[c];
          if (val is int) {
            cell.value = IntCellValue(val);
            cell.cellStyle = centerStyle;
          } else {
            cell.value = TextCellValue(val.toString());
            if (c == 11) {
              cell.cellStyle = isPass ? passStyle : failStyle;
            } else if (c == 1 || c == 2 || c == 3 || c == 4 || c == 7 || c == 8 || c == 9 || c == 10) {
              cell.cellStyle = centerStyle;
            }
          }
        }
      }

      sheet3.setColumnWidth(0, 8);
      sheet3.setColumnWidth(1, 12);
      sheet3.setColumnWidth(2, 14);
      sheet3.setColumnWidth(3, 14);
      sheet3.setColumnWidth(4, 14);
      sheet3.setColumnWidth(5, 14);
      sheet3.setColumnWidth(6, 18);
      sheet3.setColumnWidth(7, 14);
      sheet3.setColumnWidth(8, 16);
      sheet3.setColumnWidth(9, 14);
      sheet3.setColumnWidth(10, 16);
      sheet3.setColumnWidth(11, 22);
      sheet3.setColumnWidth(12, 22);
      sheet3.setColumnWidth(13, 22);

      // ==========================================
      // SHEET 5: DonHang (Chi tiết đo Đơn hàng)
      // ==========================================
      final sheet4 = excel['DonHang'];
      final orderMeasurements = measurements
          .where((m) => m.category == PerformanceCategory.order && m.status == MeasurementStatus.completed)
          .toList();

      final headers4 = [
        'STT',
        'Mã đơn hàng',
        'Ngày',
        'Giờ bắt đầu',
        'Giờ kết thúc',
        'Thời gian xử lý (s)',
        'Định dạng',
        'Chuẩn SLA (s)',
        'Chênh lệch (+/-s)',
        'Đánh giá SLA',
        'Nhân sự phụ trách',
        'Người thực hiện đo',
      ];
      for (int c = 0; c < headers4.length; c++) {
        final cell = sheet4.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0));
        cell.value = TextCellValue(headers4[c]);
        cell.cellStyle = headerStyle;
      }

      for (int i = 0; i < orderMeasurements.length; i++) {
        final m = orderMeasurements[i];
        final diff = m.durationSeconds - stdOrder;
        final isPass = m.durationSeconds <= stdOrder;
        final diffStr = diff <= 0 ? '-${-diff}s' : '+$diff s';
        final evalStr = isPass ? 'ĐẠT' : 'VƯỢT CHUẨN (+$diff s)';
        final staff = (m.staffName != null && m.staffName!.isNotEmpty)
            ? m.staffName!
            : (serviceStaffList.isNotEmpty ? serviceStaffList.join(', ') : managerName);
        final measuredBy = (m.measuredByName != null && m.measuredByName!.isNotEmpty)
            ? m.measuredByName!
            : managerName;

        final rowValues = [
          i + 1,
          m.orderCode?.isNotEmpty == true ? m.orderCode! : 'Đơn #${i + 1}',
          dateFmt.format(m.startedAt),
          timeFmt.format(m.startedAt),
          m.completedAt != null ? timeFmt.format(m.completedAt!) : '--:--',
          m.durationSeconds,
          PerformanceCalculator.formatSeconds(m.durationSeconds),
          '${stdOrder}s',
          diffStr,
          evalStr,
          staff,
          measuredBy,
        ];

        for (int c = 0; c < rowValues.length; c++) {
          final cell = sheet4.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1));
          final val = rowValues[c];
          if (val is int) {
            cell.value = IntCellValue(val);
            cell.cellStyle = centerStyle;
          } else {
            cell.value = TextCellValue(val.toString());
            if (c == 9) {
              cell.cellStyle = isPass ? passStyle : failStyle;
            } else if (c == 2 || c == 3 || c == 4 || c == 6 || c == 7 || c == 8) {
              cell.cellStyle = centerStyle;
            }
          }
        }
      }

      sheet4.setColumnWidth(0, 8);
      sheet4.setColumnWidth(1, 16);
      sheet4.setColumnWidth(2, 14);
      sheet4.setColumnWidth(3, 14);
      sheet4.setColumnWidth(4, 14);
      sheet4.setColumnWidth(5, 18);
      sheet4.setColumnWidth(6, 14);
      sheet4.setColumnWidth(7, 14);
      sheet4.setColumnWidth(8, 16);
      sheet4.setColumnWidth(9, 22);
      sheet4.setColumnWidth(10, 22);
      sheet4.setColumnWidth(11, 22);

      // ==========================================
      // SHEET 6: Loi_Phat_Sinh (Incidents)
      // ==========================================
      if (report.incidents.isNotEmpty) {
        final sheet5 = excel['Loi_Phat_Sinh'];
        final incidentHeaders = [
          'STT',
          'Thời gian ghi nhận',
          'Phân loại sự cố',
          'Chi tiết sự cố / lỗi phát sinh',
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
            final cell = sheet5.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: i + 1));
            cell.value = row[c];
            if (c == 0 || c == 1) cell.cellStyle = centerStyle;
          }
        }
        sheet5.setColumnWidth(0, 8);
        sheet5.setColumnWidth(1, 18);
        sheet5.setColumnWidth(2, 22);
        sheet5.setColumnWidth(3, 42);
        sheet5.setColumnWidth(4, 20);
        sheet5.setColumnWidth(5, 20);
      }

      // Clean up default Sheet1 if exists
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      return excel;
    }

  static Future<void> exportPerformanceReport({
    required PerformanceReportModel report,
    required List<MeasurementModel> measurements,
    BuildContext? context,
  }) async {
    try {
      final excel = createPerformanceReportWorkbook(
        report: report,
        measurements: measurements,
      );

      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception('Không thể tạo nội dung file Excel.');
      }

      final dateIso = DateFormat('yyyy-MM-dd').format(report.startedAt);
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
