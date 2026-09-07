import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/guest_providers.dart';

class GuestSettingsTab extends ConsumerWidget {
  const GuestSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text(
          'Cài đặt',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontWeight: FontWeight.bold,
            color: AppColors.neutral,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  elevation: 0,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.delete_outline, color: AppColors.primary),
                        title: const Text(
                          'Xóa toàn bộ lịch sử',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () => _showClearHistoryDialog(context, ref),
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      ListTile(
                        leading: const Icon(Icons.login, color: AppColors.info),
                        title: const Text(
                          'Đăng nhập hệ thống Trạm',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: AppColors.neutral,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          ref.read(isGuestModeProvider.notifier).state = false;
                          context.go('/login');
                        },
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.neutral),
                        title: const Text(
                          'Chính sách quyền riêng tư',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: AppColors.neutral,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          // TODO: Show privacy policy
                        },
                      ),
                      const Divider(height: 1, color: AppColors.border),
                      ListTile(
                        leading: const Icon(Icons.info_outline, color: AppColors.neutral),
                        title: const Text(
                          'Thông tin ứng dụng',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            color: AppColors.neutral,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'Đo Hiệu Năng Trạm',
                            applicationVersion: '1.0.0',
                            applicationIcon: const Icon(Icons.speed, size: 48, color: AppColors.primary),
                            children: [
                              const Text(
                                'Ứng dụng đo lường hiệu năng nội bộ.',
                                style: TextStyle(fontFamily: 'BeVietnamPro'),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Phiên bản 1.0.0',
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.white,
        title: const Text(
          'Xóa lịch sử?',
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontWeight: FontWeight.bold,
            color: AppColors.neutral,
          ),
        ),
        content: const Text(
          'Hành động này sẽ xóa toàn bộ lịch sử đo trên thiết bị. Bạn có chắc chắn không?',
          style: TextStyle(fontFamily: 'BeVietnamPro', color: AppColors.neutral),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'HỦY',
              style: TextStyle(fontFamily: 'BeVietnamPro', color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final repo = ref.read(guestLocalRepositoryProvider);
              await repo.clearAllHistory();
              ref.invalidate(guestHistoryProvider);
            },
            child: const Text(
              'XÓA',
              style: TextStyle(fontFamily: 'BeVietnamPro', color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
