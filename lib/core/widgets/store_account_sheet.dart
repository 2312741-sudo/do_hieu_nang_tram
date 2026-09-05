import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../models/store_model.dart';
import '../../models/member_model.dart';
import '../constants/app_colors.dart';

class StoreAndAccountSheet extends ConsumerStatefulWidget {
  const StoreAndAccountSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StoreAndAccountSheet(),
    );
  }

  @override
  ConsumerState<StoreAndAccountSheet> createState() => _StoreAndAccountSheetState();
}

class _StoreAndAccountSheetState extends ConsumerState<StoreAndAccountSheet> {
  bool _isSwitchingStore = false;

  Future<void> _handleSwitchStore(StoreModel targetStore) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    final currentStoreId = ref.read(currentStoreIdProvider);

    if (user == null || targetStore.id == currentStoreId) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSwitchingStore = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).update({
        'currentStoreId': targetStore.id,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chuyển sang cửa hàng: ${targetStore.name}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể đổi cửa hàng: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSwitchingStore = false);
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản hiện tại không?'),
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
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      Navigator.pop(context); // Close bottom sheet
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final currentStoreId = ref.watch(currentStoreIdProvider);
    final userStoresWithRoleAsync = ref.watch(userStoresWithRoleProvider);
    final currentRole = ref.watch(currentRoleProvider);

    final roleLabel = currentRole?.label ?? 'Nhân viên';
    final roleColor = currentRole == UserRole.owner
        ? AppColors.primary
        : (currentRole?.isManager == true
            ? const Color(0xFF22876D)
            : Colors.grey.shade700);
    final roleBgColor = currentRole == UserRole.owner
        ? AppColors.primary.withOpacity(0.12)
        : (currentRole?.isManager == true
            ? const Color(0xFF22876D).withOpacity(0.12)
            : Colors.grey.shade200);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // User Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary,
                      backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                          ? Text(
                              (user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Người dùng',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'BeVietnamPro',
                              color: AppColors.neutral,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              fontFamily: 'BeVietnamPro',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: roleColor,
                                fontFamily: 'BeVietnamPro',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Store Switcher Section
              const Row(
                children: [
                  Icon(Icons.store_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: 6),
                  Text(
                    'CHUYỂN CỬA HÀNG',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'BeVietnamPro',
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              userStoresWithRoleAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text('Lỗi tải danh sách cửa hàng: $e', style: const TextStyle(color: AppColors.danger)),
                ),
                data: (storesWithRole) {
                  if (storesWithRole.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'Bạn chưa tham gia cửa hàng nào.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: storesWithRole.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        final item = storesWithRole[index];
                        final store = item.store;
                        final role = item.role;
                        final isSelected = store.id == currentStoreId;

                        final itemRoleLabel = role.label;
                        final itemRoleColor = role == UserRole.owner
                            ? AppColors.primary
                            : (role.isManager ? const Color(0xFF22876D) : Colors.grey.shade600);

                        return InkWell(
                          onTap: _isSwitchingStore
                              ? null
                              : () async {
                                  if (role == UserRole.employee && store.id != currentStoreId) {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('Lưu ý vai trò Nhân viên'),
                                        content: Text(
                                          'Tài khoản của bạn tại "${store.name}" có vai trò Nhân viên.\n\nỨng dụng Đo Hiệu Năng yêu cầu quyền Quản lý hoặc Chủ cửa hàng.',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('HỦY'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.neutral,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('VẪN CHUYỂN'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm != true) return;
                                  }
                                  _handleSwitchStore(store);
                                },
                          borderRadius: BorderRadius.vertical(
                            top: index == 0 ? const Radius.circular(16) : Radius.zero,
                            bottom: index == storesWithRole.length - 1 ? const Radius.circular(16) : Radius.zero,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    color: isSelected ? AppColors.primary : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              store.name,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                fontFamily: 'BeVietnamPro',
                                                color: isSelected ? AppColors.primary : AppColors.neutral,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: itemRoleColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              itemRoleLabel,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: itemRoleColor,
                                                fontFamily: 'BeVietnamPro',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (store.code.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Mã: ${store.code}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.textSecondary,
                                            fontFamily: 'BeVietnamPro',
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22)
                                else
                                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Logout Button
              OutlinedButton(
                onPressed: _confirmLogout,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.danger, width: 1.5),
                  foregroundColor: AppColors.danger,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: AppColors.danger),
                    SizedBox(width: 8),
                    Text(
                      'ĐĂNG XUẤT',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'BeVietnamPro',
                        color: AppColors.danger,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
