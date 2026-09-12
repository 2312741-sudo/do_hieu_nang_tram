import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../models/member_model.dart';
import '../constants/app_colors.dart';
import 'store_account_sheet.dart';

class AccessDeniedScreen extends ConsumerStatefulWidget {
  const AccessDeniedScreen({super.key});

  @override
  ConsumerState<AccessDeniedScreen> createState() => _AccessDeniedScreenState();
}

class _AccessDeniedScreenState extends ConsumerState<AccessDeniedScreen> {
  bool _isSwitching = false;

  Future<void> _switchToStore(String storeId, String storeName) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;

    setState(() => _isSwitching = true);
    await ref.read(performanceSelectedStoreIdProvider.notifier).selectStore(storeId);
    if (mounted) setState(() => _isSwitching = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chuyển sang cửa hàng: $storeName'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStore = ref.watch(currentStoreProvider).valueOrNull;
    final userStoresWithRoleAsync = ref.watch(userStoresWithRoleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lock Card Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_person_rounded,
                          color: Color(0xFFD97706),
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Vai trò Nhân viên tại cửa hàng này',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.neutral,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cửa hàng: ${currentStore?.name ?? "Đang chọn"}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ứng dụng Đo Hiệu Năng Trạm chỉ hỗ trợ tài khoản có vai trò Quản lý hoặc Chủ cửa hàng để bấm giờ và theo dõi hiệu năng.\n\nVui lòng chuyển sang cửa hàng bạn có quyền Quản lý để sử dụng.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Store Switcher Direct Section
                userStoresWithRoleAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (storesWithRole) {
                    final managerStores = storesWithRole
                        .where((s) => s.role.isManager || s.role == UserRole.owner)
                        .toList();

                    if (managerStores.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF22876D).withOpacity(0.3)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF22876D)),
                              SizedBox(width: 8),
                              Text(
                                'CỬA HÀNG BẠN CÓ QUYỀN QUẢN LÝ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'BeVietnamPro',
                                  color: Color(0xFF22876D),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...managerStores.map((item) {
                            final store = item.store;
                            final role = item.role;
                            final roleStr = role.label;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ElevatedButton(
                                onPressed: _isSwitching ? null : () => _switchToStore(store.id, store.name),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF0FDF4),
                                  foregroundColor: const Color(0xFF166534),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(color: Color(0xFFBBF7D0)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            store.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              fontFamily: 'BeVietnamPro',
                                            ),
                                          ),
                                          Text(
                                            'Vai trò: $roleStr',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF15803D),
                                              fontFamily: 'BeVietnamPro',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),

                // Switch Store Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => StoreAndAccountSheet.show(context),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                    label: const Text(
                      'CHỌN CỬA HÀNG KHÁC',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'BeVietnamPro',
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'ĐĂNG XUẤT',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'BeVietnamPro',
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
