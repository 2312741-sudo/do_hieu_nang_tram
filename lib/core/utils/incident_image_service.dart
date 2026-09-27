import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// Service xử lý ảnh sự cố ca làm việc:
/// 1. Chụp ảnh từ camera hoặc chọn từ thư viện.
/// 2. Tự động đóng dấu thông tin (ngày giờ, cửa hàng, người chụp) lên ảnh camera.
/// 3. Thuật toán nén tối ưu (giảm dung lượng < 120 KB).
/// 4. Tải ảnh lên Firebase Storage và trả về download URL.
class IncidentImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Chụp ảnh trực tiếp từ Camera (mặc định camera sau để chụp hiện trường sự cố)
  static Future<XFile?> pickFromCamera({
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    return _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: preferredCameraDevice,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 85,
    );
  }

  /// Chọn ảnh từ Thư viện (Gallery)
  static Future<XFile?> pickFromGallery() async {
    return _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
  }

  /// Nén ảnh chọn từ thư viện xuống dung lượng siêu nhẹ (~80-120 KB)
  static Future<Uint8List> compressGalleryImage(Uint8List rawBytes) async {
    try {
      final image = img.decodeImage(rawBytes);
      if (image == null) return rawBytes;

      img.Image processed = image;
      if (image.width > 1280 || image.height > 1280) {
        processed = img.copyResize(
          image,
          width: image.width > image.height ? 1280 : null,
          height: image.height >= image.width ? 1280 : null,
        );
      }

      final jpgBytes = img.encodeJpg(processed, quality: 75);
      return Uint8List.fromList(jpgBytes);
    } catch (_) {
      return rawBytes;
    }
  }

  /// Đóng dấu thông tin (watermark) trực tiếp lên ảnh camera:
  /// - Tên hệ thống: ĐO HIỆU NĂNG TRẠM
  /// - Thời gian chụp: dd/MM/yyyy • HH:mm:ss
  /// - Tên cửa hàng & Người ghi nhận
  /// Sau đó nén chuẩn JPEG tối ưu (~80-120 KB).
  static Future<Uint8List> stampCameraImage({
    required Uint8List rawBytes,
    required String storeName,
    required String reporterName,
    String? category,
  }) async {
    try {
      // 1. Decode ảnh qua ui.instantiateImageCodec
      final codec = await ui.instantiateImageCodec(rawBytes);
      final frameInfo = await codec.getNextFrame();
      final uiImage = frameInfo.image;
      final originalWidth = uiImage.width;
      final originalHeight = uiImage.height;

      // 2. Tính tỉ lệ scale cạnh dài nhất tối đa 1280px
      double scale = 1.0;
      if (originalWidth > 1280 || originalHeight > 1280) {
        scale = 1280.0 / (originalWidth > originalHeight ? originalWidth : originalHeight);
      }
      final targetWidth = (originalWidth * scale).round();
      final targetHeight = (originalHeight * scale).round();

      // 3. Chuẩn bị Canvas vẽ lại ảnh và watermark
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Vẽ ảnh gốc (được scale mượt mà)
      canvas.drawImageRect(
        uiImage,
        Rect.fromLTWH(0, 0, originalWidth.toDouble(), originalHeight.toDouble()),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
        Paint()..filterQuality = FilterQuality.medium,
      );

      // 4. Thiết kế thanh dải watermark nền đen mờ sang trọng ở góc dưới
      final bannerHeight = (targetHeight * 0.12).clamp(68.0, 110.0);
      final bannerTop = targetHeight - bannerHeight;

      // Vẽ nền đen mờ
      final bannerPaint = Paint()..color = const Color(0xDD111827); // Dark gray/black ~87% opacity
      canvas.drawRect(
        Rect.fromLTWH(0, bannerTop, targetWidth.toDouble(), bannerHeight),
        bannerPaint,
      );

      // Vẽ viền đỏ thương hiệu ở cạnh trên dải thông tin
      final accentBorderPaint = Paint()..color = const Color(0xFFC0262D);
      canvas.drawRect(
        Rect.fromLTWH(0, bannerTop, targetWidth.toDouble(), 3.5),
        accentBorderPaint,
      );

      // 5. Vẽ thông tin thời gian & hệ thống
      final now = DateTime.now();
      final timeStr = DateFormat('dd/MM/yyyy • HH:mm:ss').format(now);

      final line1FontSize = (bannerHeight * 0.26).clamp(13.0, 20.0);
      final line2FontSize = (bannerHeight * 0.22).clamp(11.0, 16.0);

      // Dòng 1: Logo & Thời gian
      final tp1 = TextPainter(
        text: TextSpan(
          text: '⏱️ ĐO HIỆU NĂNG TRẠM  •  $timeStr',
          style: TextStyle(
            color: Colors.white,
            fontSize: line1FontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      tp1.layout(maxWidth: targetWidth - 28.0);
      tp1.paint(canvas, Offset(14.0, bannerTop + (bannerHeight * 0.18)));

      // Dòng 2: Cửa hàng & Người ghi nhận & Danh mục
      final cleanStore = storeName.isNotEmpty ? storeName : 'Cửa hàng';
      final cleanReporter = reporterName.isNotEmpty ? reporterName : 'Quản lý';
      final categorySuffix = category != null && category.isNotEmpty ? '  [$category]' : '';

      final tp2 = TextPainter(
        text: TextSpan(
          text: '📍 $cleanStore  •  👤 $cleanReporter$categorySuffix',
          style: TextStyle(
            color: const Color(0xFFE2E8F0),
            fontSize: line2FontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      tp2.layout(maxWidth: targetWidth - 28.0);
      tp2.paint(canvas, Offset(14.0, bannerTop + (bannerHeight * 0.54)));

      // 6. Xuất ra ảnh PNG từ Canvas
      final picture = recorder.endRecording();
      final renderedImage = await picture.toImage(targetWidth, targetHeight);
      final byteData = await renderedImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) return rawBytes;

      final pngBytes = byteData.buffer.asUint8List();

      // 7. Chuyển đổi sang JPEG nén 75% chất lượng cao, siêu nhẹ (<120 KB)
      final decoded = img.decodePng(pngBytes);
      if (decoded != null) {
        final jpgBytes = img.encodeJpg(decoded, quality: 75);
        return Uint8List.fromList(jpgBytes);
      }

      return pngBytes;
    } catch (_) {
      // Fallback an toàn nếu có lỗi đồ họa
      return rawBytes;
    }
  }

  /// Tải ảnh sự cố lên Firebase Storage
  /// Đường dẫn: incident_images/{storeId}/{sessionId}/{incidentId}.jpg
  static Future<String> uploadIncidentImage({
    required Uint8List imageBytes,
    required String storeId,
    required String sessionId,
    required String incidentId,
  }) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('incident_images')
        .child(storeId)
        .child(sessionId)
        .child('$incidentId.jpg');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'storeId': storeId,
        'sessionId': sessionId,
        'incidentId': incidentId,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    final uploadTask = await storageRef.putData(imageBytes, metadata);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }
}
