import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/guest_providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingSession();
    });
  }

  Future<void> _checkExistingSession() async {
    final repo = ref.read(guestLocalRepositoryProvider);
    final session = await repo.loadActiveSession();
    if (session != null && mounted) {
      _showContinueSessionDialog();
    }
  }

  void _showContinueSessionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Tiếp tục phiên đo?',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            color: AppColors.neutral,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Bạn có một phiên đo hiệu năng đang dang dở. Bạn có muốn tiếp tục không?',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(guestLocalRepositoryProvider).clearAll();
            },
            child: const Text(
              'Bắt đầu mới',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: AppColors.textSecondary,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(isGuestModeProvider.notifier).state = true;
              context.go('/guest');
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Tiếp tục',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 20),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      )
                          .animate()
                          .fade(duration: 600.ms)
                          .scale(delay: 100.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 32),
                      const Text(
                        'ĐO HIỆU NĂNG',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neutral,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fade(delay: 200.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 16),
                      const Text(
                        'Đo thời gian xử lý Nước, Bánh và Đơn hàng một cách nhanh chóng.',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fade(delay: 300.ms).slideY(begin: 0.2, end: 0),
                    ],
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: () {
                            ref.read(isGuestModeProvider.notifier).state = true;
                            context.go('/guest');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'SỬ DỤNG NGAY',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(isGuestModeProvider.notifier).state = false;
                            context.go('/login');
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'ĐĂNG NHẬP HỆ THỐNG TRẠM',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ).animate().fade(delay: 500.ms).slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 32),
                      const Text(
                        'Hệ sinh thái Trạm • Đo Hiệu Năng',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ).animate().fade(delay: 600.ms),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
