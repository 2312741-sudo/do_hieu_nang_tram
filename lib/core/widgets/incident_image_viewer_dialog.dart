import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Dialog xem ảnh sự cố phóng to toàn màn hình với tính năng zoom (InteractiveViewer)
class IncidentImageViewerDialog extends StatelessWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String? title;

  const IncidentImageViewerDialog({
    super.key,
    this.imageUrl,
    this.imageBytes,
    this.title,
  }) : assert(imageUrl != null || imageBytes != null, 'Phải cung cấp imageUrl hoặc imageBytes');

  static void show(
    BuildContext context, {
    String? imageUrl,
    Uint8List? imageBytes,
    String? title,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (_) => IncidentImageViewerDialog(
        imageUrl: imageUrl,
        imageBytes: imageBytes,
        title: title,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Image with Interactive Zoom & Pan
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Hero(
                  tag: imageUrl ?? imageBytes.hashCode.toString(),
                  child: imageBytes != null
                      ? Image.memory(
                          imageBytes!,
                          fit: BoxFit.contain,
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2.5,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image_rounded, color: Colors.white60, size: 48),
                                SizedBox(height: 12),
                                Text(
                                  'Không thể tải ảnh minh chứng',
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // Top bar with title and close button
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title ?? 'Ảnh minh chứng sự cố',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom hint
            const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Chụm tay để phóng to / thu nhỏ ảnh',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
