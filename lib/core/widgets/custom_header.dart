import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import 'store_account_sheet.dart';

class CustomHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? storeName;
  final VoidCallback? onStoreTap;
  final bool isNavy;
  final Widget? trailing;

  const CustomHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.storeName,
    this.onStoreTap,
    this.isNavy = false,
    this.trailing,
  });

  String _getGreeting(int hour) {
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final dateStr = DateFormat('EEEE, dd/MM/yyyy', 'vi').format(now);

    final gradientColors = isNavy
        ? const [Color(0xFF1C4E6B), Color(0xFF0A3247)]
        : const [Color(0xFFC8102E), Color(0xFF8B0000)];

    final effectiveStoreTap = onStoreTap ?? () => StoreAndAccountSheet.show(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: (isNavy ? const Color(0xFF1C4E6B) : AppColors.primary).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$greeting, $subtitle',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontFamily: 'BeVietnamPro',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'BeVietnamPro',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (storeName != null) ...[
                    GestureDetector(
                      onTap: effectiveStoreTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.store_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 110),
                              child: Text(
                                storeName!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'BeVietnamPro',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  trailing ??
                      IconButton(
                        onPressed: () => StoreAndAccountSheet.show(context),
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30),
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                        ),
                        tooltip: 'Tài khoản & Đăng xuất',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: Colors.white60, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontFamily: 'BeVietnamPro',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
