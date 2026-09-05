import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../session/providers/timer_service.dart';
import 'owner_overview_tab.dart';
import 'owner_reports_tab.dart';

class OwnerMainScreen extends ConsumerStatefulWidget {
  const OwnerMainScreen({super.key});

  @override
  ConsumerState<OwnerMainScreen> createState() => _OwnerMainScreenState();
}

class _OwnerMainScreenState extends ConsumerState<OwnerMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(currentStoreProvider).valueOrNull;
    final repo = ref.watch(performanceRepositoryProvider);

    // Realtime badge for unviewed submitted reports
    final unviewedStream = store != null
        ? repo.watchUnviewedReportsCount(store.id)
        : repo.watchAllUnviewedReportsCount();

    return StreamBuilder<int>(
      stream: unviewedStream,
      builder: (context, snapshot) {
        final unviewedCount = snapshot.data ?? 0;

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              OwnerOverviewTab(
                onNavigateToReports: () => setState(() => _currentIndex = 1),
              ),
              const OwnerReportsTab(),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _OwnerNavItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Tổng quan',
                      isSelected: _currentIndex == 0,
                      onTap: () => setState(() => _currentIndex = 0),
                    ),
                    _OwnerNavItem(
                      icon: Icons.assessment_rounded,
                      label: 'Báo cáo',
                      badgeCount: unviewedCount,
                      isSelected: _currentIndex == 1,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OwnerNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _OwnerNavItem({
    required this.icon,
    required this.label,
    this.badgeCount = 0,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'BeVietnamPro',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontFamily: 'BeVietnamPro',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
