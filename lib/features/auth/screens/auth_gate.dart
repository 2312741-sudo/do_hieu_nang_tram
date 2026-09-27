import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/access_denied_card.dart';
import '../../../models/member_model.dart';
import '../providers/auth_provider.dart';
import '../../guest/providers/guest_providers.dart';
import '../../guest/screens/welcome_screen.dart';
import '../../guest/screens/guest_main_screen.dart';
import '../../manager/screens/manager_main_screen.dart';
import '../../owner/screens/owner_main_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const _SplashScreen(),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Lỗi xác thực: $e')),
      ),
      data: (user) {
        if (user == null) {
          final isGuest = ref.watch(isGuestModeProvider);
          if (isGuest) {
            return const GuestMainScreen();
          }
          return const WelcomeScreen();
        }

        // User is logged in: Check member role in current store
        final currentRole = ref.watch(currentRoleProvider);
        final memberAsync = ref.watch(currentMemberProvider);
        final storesWithRoleAsync = ref.watch(userStoresWithRoleProvider);

        if (memberAsync.isLoading || storesWithRoleAsync.isLoading) {
          return const _SplashScreen();
        }

        // If role is Employee or unassigned: Check if user has another store where they are Manager/Owner
        if (currentRole == UserRole.employee || currentRole == null) {
          final storesWithRole = storesWithRoleAsync.valueOrNull;
          if (storesWithRole != null && storesWithRole.isNotEmpty) {
            final managerStore = storesWithRole
                .where((s) =>
                    (s.role.isManager || s.role == UserRole.owner) &&
                    s.store.id != ref.read(currentStoreIdProvider))
                .firstOrNull;

            if (managerStore != null) {
              // Auto switch to manager store (local only, do not overwrite Firestore currentStoreId)
              Future.microtask(() {
                ref
                    .read(performanceSelectedStoreIdProvider.notifier)
                    .selectStore(managerStore.store.id);
              });
              return const _SplashScreen(message: 'Đang chuyển sang cửa hàng Quản lý...');
            }
          }

          if (currentRole == UserRole.employee) {
            return const AccessDeniedScreen();
          }

          return const AccessDeniedScreen();
        }

        // Role Owner -> Owner Dashboard
        if (currentRole == UserRole.owner) {
          return const OwnerMainScreen();
        }

        // Role Manager -> Manager Dashboard (supports manager1, manager2, legacyManager)
        if (currentRole.isManager) {
          return const ManagerMainScreen();
        }

        return const AccessDeniedScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  final String? message;

  const _SplashScreen({this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              // App name
              const Text(
                'Đo Hiệu Năng Trạm',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'BeVietnamPro',
                  color: AppColors.neutral,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),

              // Tagline
              Text(
                message ?? 'Đang khởi động...',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  fontFamily: 'BeVietnamPro',
                ),
              ),
              const SizedBox(height: 40),

              // Subtle loading indicator
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primary.withOpacity(0.7),
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
