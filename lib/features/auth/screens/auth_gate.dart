import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/access_denied_card.dart';
import '../../../models/member_model.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import '../../manager/screens/manager_main_screen.dart';
import '../../owner/screens/owner_main_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Lỗi xác thực: $e')),
      ),
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        // User is logged in: Check member role in current store
        final currentRole = ref.watch(currentRoleProvider);
        final memberAsync = ref.watch(currentMemberProvider);

        if (memberAsync.isLoading) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // If role is Employee or unassigned: Check if user has another store where they are Manager/Owner
        if (currentRole == UserRole.employee || currentRole == null) {
          final storesWithRole = ref.watch(userStoresWithRoleProvider).valueOrNull;
          if (storesWithRole != null && storesWithRole.isNotEmpty) {
            final managerStore = storesWithRole
                .where((s) => (s.role.isManager || s.role == UserRole.owner) && s.store.id != ref.read(currentStoreIdProvider))
                .firstOrNull;

            if (managerStore != null) {
              // Auto switch to manager store
              Future.microtask(() {
                ref.read(authRepositoryProvider).switchCurrentStore(user.uid, managerStore.store.id);
              });
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text(
                        'Đang chuyển sang cửa hàng Quản lý...',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          if (currentRole == UserRole.employee) {
            return const AccessDeniedScreen();
          }
        }

        // Role Owner -> Owner Dashboard
        if (currentRole == UserRole.owner) {
          return const OwnerMainScreen();
        }

        // Role Manager -> Manager Dashboard (supports manager1, manager2, legacyManager)
        if (currentRole != null && currentRole.isManager) {
          return const ManagerMainScreen();
        }

        // Default: If member record not yet loaded or user is manager by default
        return const ManagerMainScreen();
      },
    );
  }
}
