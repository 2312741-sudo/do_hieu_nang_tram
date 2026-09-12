import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const String appVersion = '1.0.3';
  static const String buildNumber = '8';

  Future<void> _launchUrl(BuildContext context, String urlStr) async {
    try {
      final uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở liên kết: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Thông tin ứng dụng',
          style: GoogleFonts.beVietnamPro(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // ── App Logo & Header ──────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/logo_padded.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.primary,
                        child: const Icon(
                          Icons.timer_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đo Hiệu Năng Trạm',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Luôn tươi ngon vì sức khoẻ',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Version badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Phiên bản $appVersion (Build $buildNumber)',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Card Thông tin & Liên kết ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _LinkTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: const Color(0xFF0284C7),
                    title: 'Chính sách quyền riêng tư',
                    subtitle: 'Quy định bảo mật và bảo vệ dữ liệu người dùng',
                    onTap: () => _launchUrl(context, 'https://webquanlychamcong.vercel.app/privacy.html'),
                  ),
                  const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                  _LinkTile(
                    icon: Icons.no_accounts_outlined,
                    iconColor: const Color(0xFFEA580C),
                    title: 'Quy định xóa tài khoản',
                    subtitle: 'Quy trình xóa tài khoản và dữ liệu cá nhân',
                    onTap: () => _launchUrl(context, 'https://webquanlychamcong.vercel.app/delete-account.html'),
                  ),
                  const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                  _LinkTile(
                    icon: Icons.support_agent_rounded,
                    iconColor: const Color(0xFF16A34A),
                    title: 'Hỗ trợ & Liên hệ',
                    subtitle: 'nthanhtam.402@gmail.com',
                    onTap: () => _launchUrl(context, 'mailto:nthanhtam.402@gmail.com?subject=Hỗ trợ ứng dụng Đo Hiệu Năng Trạm'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Card Bản quyền & Tác giả ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Thông tin phát triển',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const _InfoRow(label: 'Ứng dụng', value: 'Đo Hiệu Năng Trạm'),
                  const SizedBox(height: 8),
                  const _InfoRow(label: 'Tác giả', value: 'Nguyễn Thanh Tâm'),
                  const SizedBox(height: 8),
                  const _InfoRow(label: 'Email', value: 'nthanhtam.402@gmail.com'),
                  const SizedBox(height: 8),
                  const _InfoRow(label: 'Bản quyền', value: 'Bản quyền © 2026 Nguyễn Thanh Tâm'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Footer Note
            Text(
              'Đo Hiệu Năng Trạm — Giải pháp đo lường thời gian ra món\nvà chuẩn hóa quy trình vận hành cho quầy Bar & Bếp Trạm.',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LinkTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF94A3B8),
            ),
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
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
