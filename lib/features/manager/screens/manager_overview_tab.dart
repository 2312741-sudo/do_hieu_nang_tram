import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/performance_calculator.dart';
import '../../../core/utils/schedule_helper.dart';
import '../../../core/widgets/custom_header.dart';
import '../../../core/widgets/personnel_selector.dart';
import '../../../core/widgets/store_account_sheet.dart';
import '../../../models/member_model.dart';
import '../../../models/measurement_model.dart';
import '../../../models/performance_session_model.dart';
import '../../../models/schedule_model.dart';
import '../../../models/store_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../reports/screens/staff_leaderboard_screen.dart';
import '../../session/providers/timer_service.dart';
import '../widgets/add_incident_bottom_sheet.dart';
import '../widgets/add_timer_bottom_sheet.dart';
import '../widgets/timer_card.dart';
import 'category_measure_screen.dart';
import 'end_session_preview_screen.dart';

class ManagerOverviewTab extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToActiveTimers;

  const ManagerOverviewTab({super.key, required this.onNavigateToActiveTimers});

  @override
  ConsumerState<ManagerOverviewTab> createState() => _ManagerOverviewTabState();
}

class _ManagerOverviewTabState extends ConsumerState<ManagerOverviewTab> {
  MemberModel? _selectedManager;
  List<MemberModel> _selectedDrinkStaff = [];
  List<MemberModel> _selectedCakeStaff = [];
  List<MemberModel> _selectedServiceStaff = [];
  bool _isStartingSession = false;

  // Trạng thái Lịch làm việc
  ScheduleModel? _cachedSchedule;
  bool _isLoadingSchedule = false;
  bool _scheduleLoaded = false;
  String? _selectedShiftFilter; // null = ưu tiên ca hiện tại, 'all' = cả ngày, hoặc shiftId cụ thể
  List<ShiftDefinition> _availableShiftsToday = [];
  String? _activeShiftDisplay;
  int _scheduledStaffCount = 0;
  bool _hasUserManuallyEditedPersonnel = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final managers = ref.read(storeManagersProvider);
      final currentUid = ref.read(currentUserIdProvider);
      if (managers.isNotEmpty) {
        final currentMgr = managers.where((m) => m.userId == currentUid).firstOrNull;
        setState(() {
          _selectedManager = currentMgr ?? managers.first;
        });
      }
      _loadScheduleFromFirestore();
    });
  }

  Future<void> _loadScheduleFromFirestore({bool forceRefresh = false}) async {
    final store = ref.read(currentStoreProvider).valueOrNull;
    if (store == null) return;

    if (forceRefresh) {
      _hasUserManuallyEditedPersonnel = false;
    }

    setState(() => _isLoadingSchedule = true);

    try {
      final weekStart = ScheduleHelper.getWeekStartString();
      final schedule = await ref.read(performanceRepositoryProvider).getWeekSchedule(store.id, weekStart);

      if (schedule != null) {
        _cachedSchedule = schedule;
        _applyScheduleToDepartments();
      } else {
        if (mounted) {
          setState(() {
            _scheduleLoaded = false;
            _scheduledStaffCount = 0;
            _activeShiftDisplay = null;
            _availableShiftsToday = [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSchedule = false);
      }
    }
  }

  void _applyScheduleToDepartments({String? shiftId}) {
    final schedule = _cachedSchedule;
    final store = ref.read(currentStoreProvider).valueOrNull;
    final shiftStaff = ref.read(storeShiftStaffProvider);
    if (schedule == null || store == null) return;

    final resolution = ScheduleHelper.resolveTodaySchedule(
      schedule: schedule,
      store: store,
      availableStaff: shiftStaff,
      selectedShiftId: shiftId ?? _selectedShiftFilter,
    );

    if (!mounted) return;

    setState(() {
      _selectedDrinkStaff = resolution.drinkStaff;
      _selectedCakeStaff = resolution.cakeStaff;
      _selectedServiceStaff = resolution.serviceStaff;
      _availableShiftsToday = resolution.todayShifts;
      _scheduledStaffCount = resolution.drinkStaff.length +
          resolution.cakeStaff.length +
          resolution.serviceStaff.length;
      _activeShiftDisplay = resolution.activeShiftName;
      _scheduleLoaded = true;

      // Quản lý đứng ca: nếu người đo chưa chọn, ưu tiên đề xuất Quản lý có lịch ca hôm nay
      if (_selectedManager == null && ref.read(storeManagersProvider).isNotEmpty) {
        final managers = ref.read(storeManagersProvider);
        final scheduledMgr = managers.where((m) =>
          resolution.drinkStaff.any((s) => s.userId == m.userId) ||
          resolution.cakeStaff.any((s) => s.userId == m.userId) ||
          resolution.serviceStaff.any((s) => s.userId == m.userId)
        ).firstOrNull;
        _selectedManager = scheduledMgr ?? managers.first;
      }
    });
  }

  List<MemberModel> _getStaffForDept(PerformanceSessionModel session, String deptTag) {
    final list = <MemberModel>[];
    for (int i = 0; i < session.employeeNames.length; i++) {
      final fullName = session.employeeNames[i];
      final uid = session.employeeIds.length > i ? session.employeeIds[i] : 'staff_$i';
      if (fullName.contains('($deptTag)')) {
        final cleanName = fullName.replaceAll('($deptTag)', '').trim();
        list.add(MemberModel(
          userId: uid,
          name: cleanName,
          role: UserRole.employee,
          status: MemberStatus.active,
          employeeType: EmployeeType.fulltime,
          baseMonthlySalary: 0,
          baseHourlyRate: 0,
          standardHoursPerMonth: 208,
          joinedAt: DateTime.now(),
        ));
      }
    }
    return list;
  }

  Future<void> _startSession() async {
    final store = ref.read(currentStoreProvider).valueOrNull;
    final user = ref.read(currentUserProvider).valueOrNull;
    final managers = ref.read(storeManagersProvider);

    if (store == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn cửa hàng trước khi bắt đầu.')),
      );
      return;
    }

    final managerOnDuty = _selectedManager ?? (managers.isNotEmpty ? managers.first : null);
    if (managerOnDuty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn Quản lý đứng ca.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isStartingSession = true);

    try {
      final sessionId = const Uuid().v4();
      final now = DateTime.now();

      final allStaffIds = <String>[];
      final allStaffNames = <String>[];

      for (final s in _selectedDrinkStaff) {
        if (!allStaffIds.contains(s.userId)) allStaffIds.add(s.userId);
        allStaffNames.add('${s.name} (Nước)');
      }
      for (final s in _selectedCakeStaff) {
        if (!allStaffIds.contains(s.userId)) allStaffIds.add(s.userId);
        allStaffNames.add('${s.name} (Bánh)');
      }
      for (final s in _selectedServiceStaff) {
        if (!allStaffIds.contains(s.userId)) allStaffIds.add(s.userId);
        allStaffNames.add('${s.name} (Phục vụ)');
      }

      final newSession = PerformanceSessionModel(
        id: sessionId,
        storeId: store.id,
        storeName: store.name,
        managerId: user.id,
        managerName: user.name,
        managerOnDutyId: managerOnDuty.userId,
        managerOnDutyName: managerOnDuty.name,
        employeeIds: allStaffIds,
        employeeNames: allStaffNames,
        startedAt: now,
        status: SessionStatus.active,
        createdAt: now,
      );

      final repo = ref.read(performanceRepositoryProvider);
      await repo.createSession(newSession);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã bắt đầu phiên đo hiệu năng thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi bắt đầu phiên: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isStartingSession = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(performanceTimerProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final store = ref.watch(currentStoreProvider).valueOrNull;
    final activeSession = ref.watch(activeSessionProvider).valueOrNull;
    final managers = ref.watch(storeManagersProvider);
    final shiftStaff = ref.watch(storeShiftStaffProvider);

    final allMeasurements = ref.watch(sessionMeasurementsProvider).valueOrNull ?? [];
    final activeTimers = allMeasurements.where((m) => m.status.isActive).toList();

    // Tự động lắng nghe cập nhật Lịch làm việc tuần
    ref.listen<AsyncValue<ScheduleModel?>>(currentWeekScheduleProvider, (prev, next) {
      final schedule = next.valueOrNull;
      if (schedule != null && !_hasUserManuallyEditedPersonnel) {
        _cachedSchedule = schedule;
        _applyScheduleToDepartments();
      }
    });

    // Tự động tải lại lịch khi chuyển đổi cửa hàng
    ref.listen<String?>(currentStoreIdProvider, (prev, next) {
      if (prev != next) {
        _hasUserManuallyEditedPersonnel = false;
        _cachedSchedule = null;
        _loadScheduleFromFirestore();
      }
    });

    // Tự động điền nhân sự khi shiftStaff được load từ Firestore lần đầu
    if (_cachedSchedule != null &&
        !_hasUserManuallyEditedPersonnel &&
        _selectedDrinkStaff.isEmpty &&
        _selectedCakeStaff.isEmpty &&
        _selectedServiceStaff.isEmpty &&
        shiftStaff.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hasUserManuallyEditedPersonnel) {
          _applyScheduleToDepartments();
        }
      });
    }

    // Auto-update managers if not yet set
    if (_selectedManager == null && managers.isNotEmpty) {
      _selectedManager = managers.where((m) => m.userId == user?.id).firstOrNull ?? managers.first;
    }

    final firstName = user?.name.split(' ').last ?? 'Quản lý';
    final timeFmt = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          // Header with Store Selector and Account Action
          SliverToBoxAdapter(
            child: CustomHeader(
              title: AppStrings.appName.toUpperCase(),
              subtitle: firstName,
              storeName: store?.name ?? 'Trạm',
              onStoreTap: () => StoreAndAccountSheet.show(context),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─────────────────────────────────────────────────────────
                  // STATE 1: NO ACTIVE SESSION
                  // ─────────────────────────────────────────────────────────
                  if (activeSession == null) ...[
                    // Leaderboard Quick Banner for Manager
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StaffLeaderboardScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF047857)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Color(0x1810B981), blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bảng Xếp Hạng Hiệu Suất',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      fontFamily: 'BeVietnamPro',
                                    ),
                                  ),
                                  Text(
                                    'Xem xếp hạng Nước & Bánh của nhân viên',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11.5,
                                      fontFamily: 'BeVietnamPro',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.timer_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text(
                            AppStrings.noActiveSession,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'BeVietnamPro',
                              color: AppColors.neutral,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Chọn nhân sự trong ca và nhấn Bắt đầu để tiến hành đo lường.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontFamily: 'BeVietnamPro',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Smart Schedule Banner
                    _buildScheduleBanner(context),
                    const SizedBox(height: 12),

                    // Personnel Selection Card
                    PersonnelSelectorWidget(
                      availableManagers: managers,
                      availableStaff: shiftStaff,
                      selectedManager: _selectedManager,
                      selectedDrinkStaff: _selectedDrinkStaff,
                      selectedCakeStaff: _selectedCakeStaff,
                      selectedServiceStaff: _selectedServiceStaff,
                      isReadOnly: false,
                      onManagerChanged: (m) => setState(() => _selectedManager = m),
                      onDrinkStaffChanged: (list) => setState(() {
                        _hasUserManuallyEditedPersonnel = true;
                        _selectedDrinkStaff = list;
                      }),
                      onCakeStaffChanged: (list) => setState(() {
                        _hasUserManuallyEditedPersonnel = true;
                        _selectedCakeStaff = list;
                      }),
                      onServiceStaffChanged: (list) => setState(() {
                        _hasUserManuallyEditedPersonnel = true;
                        _selectedServiceStaff = list;
                      }),
                    ),
                    const SizedBox(height: 20),

                    // Start Session CTA
                    ElevatedButton(
                      onPressed: _isStartingSession ? null : _startSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                      ),
                      child: _isStartingSession
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              AppStrings.startSession,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'BeVietnamPro',
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ] else ...[
                    // ─────────────────────────────────────────────────────────
                    // STATE 2: ACTIVE SESSION IN PROGRESS
                    // ─────────────────────────────────────────────────────────

                    // Active Session Status Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22876D), Color(0xFF16594B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A6B5A).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PHIÊN ĐO ĐANG HOẠT ĐỘNG',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'BeVietnamPro',
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Bắt đầu lúc: ${timeFmt.format(activeSession.startedAt)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                        fontFamily: 'BeVietnamPro',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle, color: Color(0xFF4ADE80), size: 8),
                                    SizedBox(width: 4),
                                    Text(
                                      'Live',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EndSessionPreviewScreen(session: activeSession),
                                ),
                              );
                            },
                            icon: const Icon(Icons.stop_circle_outlined, size: 20, color: AppColors.danger),
                            label: const Text(
                              'KẾT THÚC PHIÊN ĐO & GỬI BÁO CÁO',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'BeVietnamPro',
                                color: AppColors.danger,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.danger,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section: 3 NÚT BẤM GIỜ TỨC THÌ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'BẤM GIỜ MÓN / ĐƠN HÀNG',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'BeVietnamPro',
                            color: AppColors.neutral,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Tối đa 20 lần / mục',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: 'BeVietnamPro',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3 Big Action Cards with Direct "+ Bấm giờ" Buttons
                    Column(
                      children: [
                        // 1. NƯỚC
                        _CategoryDirectCard(
                          category: PerformanceCategory.drink,
                          icon: Icons.local_cafe_rounded,
                          title: 'NƯỚC',
                          completedCount: activeSession.drinkCount,
                          totalQuantity: activeSession.drinkTotalQuantity,
                          averageSeconds: activeSession.drinkAverageSeconds,
                          unit: 'ly',
                          color: const Color(0xFFE8192F),
                          onAddTimer: () => AddTimerBottomSheet.show(context, PerformanceCategory.drink),
                          onViewDetail: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoryMeasureScreen(category: PerformanceCategory.drink),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 2. BÁNH
                        _CategoryDirectCard(
                          category: PerformanceCategory.cake,
                          icon: Icons.cake_rounded,
                          title: 'BÁNH',
                          completedCount: activeSession.cakeCount,
                          totalQuantity: activeSession.cakeTotalQuantity,
                          averageSeconds: activeSession.cakeAverageSeconds,
                          unit: 'cái',
                          color: const Color(0xFFEB9B28),
                          onAddTimer: () => AddTimerBottomSheet.show(context, PerformanceCategory.cake),
                          onViewDetail: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoryMeasureScreen(category: PerformanceCategory.cake),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 3. ĐƠN HÀNG
                        _CategoryDirectCard(
                          category: PerformanceCategory.order,
                          icon: Icons.receipt_long_rounded,
                          title: 'ĐƠN HÀNG',
                          completedCount: activeSession.orderCount,
                          totalQuantity: activeSession.orderCount,
                          averageSeconds: activeSession.orderAverageSeconds,
                          unit: 'đơn',
                          color: const Color(0xFF1C4E6B),
                          onAddTimer: () => AddTimerBottomSheet.show(context, PerformanceCategory.order),
                          onViewDetail: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoryMeasureScreen(category: PerformanceCategory.order),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section: TIMERS ĐANG CHẠY TRỰC TIẾP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: activeTimers.isNotEmpty ? AppColors.success : Colors.grey.shade400,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Đang đo trực tiếp (${activeTimers.length})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'BeVietnamPro',
                                color: AppColors.neutral,
                              ),
                            ),
                          ],
                        ),
                        if (activeTimers.isNotEmpty)
                          TextButton(
                            onPressed: widget.onNavigateToActiveTimers,
                            child: const Text('Xem tất cả ➔', style: TextStyle(fontSize: 13)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (activeTimers.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.hourglass_empty_rounded, size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text(
                              'Chưa có lần đo nào đang chạy',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'BeVietnamPro',
                                color: AppColors.neutral,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nhấn một trong 3 nút "+ BẤM GIỜ" ở trên để bắt đầu tính giờ!',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade600,
                                fontFamily: 'BeVietnamPro',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeTimers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final timer = activeTimers[index];
                          final itemIdx = PerformanceCalculator.getCategorySequenceNumber(timer, allMeasurements);
                          return TimerCard(
                            timer: timer,
                            itemNumber: itemIdx,
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ─────────────────────────────────────────────────────────
                    // SECTION: BÁO CÁO LỖI / SỰ CỐ PHÁT SINH TRONG CA
                    // ─────────────────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: activeSession.incidents.isNotEmpty
                              ? const Color(0xFFFCA5A5)
                              : Colors.grey.shade200,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.report_problem_rounded, color: Color(0xFFDC2626), size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'LỖI PHÁT SINH TRONG CA (${activeSession.incidents.length})',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'BeVietnamPro',
                                      color: Color(0xFF991B1B),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () => AddIncidentBottomSheet.show(context, activeSession),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text(
                                  'Báo lỗi',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'BeVietnamPro',
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  elevation: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          if (activeSession.incidents.isEmpty)
                            InkWell(
                              onTap: () => AddIncidentBottomSheet.show(context, activeSession),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFECDD3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.add_alert_rounded, color: Color(0xFFE11D48), size: 20),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Chưa ghi nhận lỗi phát sinh',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF9F1239),
                                              fontFamily: 'BeVietnamPro',
                                            ),
                                          ),
                                          Text(
                                            'Nhấn vào đây để báo cáo sự cố (làm sai món, hỏng máy, đổ vỡ...)',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Color(0xFFBE123C),
                                              fontFamily: 'BeVietnamPro',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFE11D48), size: 13),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...activeSession.incidents.asMap().entries.map((entry) {
                              final idx = entry.key + 1;
                              final incident = entry.value;
                              final timeStr = timeFmt.format(incident.timestamp);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '#$idx',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFDC2626),
                                        fontSize: 12.5,
                                        fontFamily: 'BeVietnamPro',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFDC2626).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  incident.category,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFFDC2626),
                                                    fontFamily: 'BeVietnamPro',
                                                  ),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                timeStr,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppColors.textDisabled,
                                                  fontFamily: 'BeVietnamPro',
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            incident.description,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.neutral,
                                              fontFamily: 'BeVietnamPro',
                                            ),
                                          ),
                                          if (incident.staffName != null && incident.staffName!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.textSecondary),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Liên quan: ${incident.staffName}',
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    color: AppColors.textSecondary,
                                                    fontFamily: 'BeVietnamPro',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Xóa lỗi phát sinh?'),
                                            content: Text('Bạn có chắc muốn xóa lỗi "${incident.description}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(ctx, false),
                                                child: const Text('HỦY'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(ctx, true),
                                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                                child: const Text('XÓA', style: TextStyle(color: Colors.white)),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          ref.read(performanceRepositoryProvider).removeSessionIncident(activeSession.id, incident);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Personnel Read-Only Card
                    const Text(
                      'NHÂN SỰ TRONG CA',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'BeVietnamPro',
                        color: AppColors.neutral,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    PersonnelSelectorWidget(
                      availableManagers: managers,
                      availableStaff: shiftStaff,
                      selectedManager: MemberModel(
                        userId: activeSession.managerOnDutyId,
                        name: activeSession.managerOnDutyName,
                        role: UserRole.manager1,
                        status: MemberStatus.active,
                        employeeType: EmployeeType.fulltime,
                        baseMonthlySalary: 0,
                        baseHourlyRate: 0,
                        standardHoursPerMonth: 208,
                        joinedAt: DateTime.now(),
                      ),
                      selectedDrinkStaff: _getStaffForDept(activeSession, 'Nước'),
                      selectedCakeStaff: _getStaffForDept(activeSession, 'Bánh'),
                      selectedServiceStaff: _getStaffForDept(activeSession, 'Phục vụ'),
                      selectedStaff: activeSession.employeeIds.asMap().entries.map((e) {
                        return MemberModel(
                          userId: e.value,
                          name: activeSession.employeeNames.length > e.key
                              ? activeSession.employeeNames[e.key]
                              : 'Nhân viên',
                          role: UserRole.employee,
                          status: MemberStatus.active,
                          employeeType: EmployeeType.fulltime,
                          baseMonthlySalary: 0,
                          baseHourlyRate: 0,
                          standardHoursPerMonth: 208,
                          joinedAt: DateTime.now(),
                        );
                      }).toList(),
                      isReadOnly: true,
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleBanner(BuildContext context) {
    final activeShift = ScheduleHelper.findActiveShift(DateTime.now(), _availableShiftsToday);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _scheduleLoaded
              ? const Color(0xFF10B981).withOpacity(0.35)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: _scheduleLoaded
                      ? const Color(0xFFECFDF5)
                      : (_isLoadingSchedule ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _scheduleLoaded
                      ? Icons.bolt_rounded
                      : (_isLoadingSchedule ? Icons.hourglass_top_rounded : Icons.calendar_today_rounded),
                  size: 18,
                  color: _scheduleLoaded
                      ? const Color(0xFF059669)
                      : (_isLoadingSchedule ? const Color(0xFF2563EB) : Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'LỊCH LÀM VIỆC HÔM NAY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'BeVietnamPro',
                            letterSpacing: 0.3,
                            color: AppColors.neutral,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (_scheduleLoaded)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 6, color: Color(0xFF10B981)),
                                SizedBox(width: 3),
                                Text(
                                  'Đã tải tự động',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'BeVietnamPro',
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isLoadingSchedule
                          ? 'Đang đọc dữ liệu lịch làm từ hệ thống...'
                          : (_scheduleLoaded
                              ? (_activeShiftDisplay != null
                                  ? 'Ca: $_activeShiftDisplay • $_scheduledStaffCount nhân sự'
                                  : 'Đã tự động điền $_scheduledStaffCount nhân sự vào các bộ phận')
                              : 'Chưa có lịch hôm nay. Bạn có thể chọn thủ công bên dưới.'),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: _scheduleLoaded ? FontWeight.w600 : FontWeight.w500,
                        fontFamily: 'BeVietnamPro',
                        color: _scheduleLoaded ? const Color(0xFF047857) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Nút đồng bộ lại
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isLoadingSchedule
                      ? null
                      : () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang làm mới lịch làm việc...'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          await _loadScheduleFromFirestore(forceRefresh: true);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _scheduleLoaded
                                    ? 'Đã tải thành công $_scheduledStaffCount nhân sự hôm nay!'
                                    : 'Không tìm thấy lịch làm hôm nay trên hệ thống.',
                              ),
                              backgroundColor: _scheduleLoaded ? AppColors.success : Colors.grey.shade700,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isLoadingSchedule
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF2563EB),
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        const Text(
                          'Đồng bộ',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'BeVietnamPro',
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Shift Filter Chips
          if (_availableShiftsToday.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final shift in _availableShiftsToday) ...[
                    Builder(
                      builder: (context) {
                        final isRunning = activeShift?.id == shift.id;
                        final isSelected = _selectedShiftFilter == shift.id ||
                            (_selectedShiftFilter == null && isRunning);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isRunning) ...[
                                  const Icon(Icons.play_arrow_rounded, size: 13, color: Color(0xFF10B981)),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  '${shift.name} (${shift.startTimeStr})',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'BeVietnamPro',
                                    color: isSelected
                                        ? const Color(0xFF2563EB)
                                        : AppColors.neutral,
                                  ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedShiftFilter = selected ? shift.id : null;
                              });
                              _applyScheduleToDepartments(shiftId: _selectedShiftFilter);
                            },
                            selectedColor: const Color(0xFF2563EB).withOpacity(0.12),
                            checkmarkColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          ),
                        );
                      },
                    ),
                  ],
                  FilterChip(
                    label: Text(
                      'Tất cả ca hôm nay',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'BeVietnamPro',
                        color: _selectedShiftFilter == 'all'
                            ? const Color(0xFF059669)
                            : AppColors.neutral,
                      ),
                    ),
                    selected: _selectedShiftFilter == 'all',
                    onSelected: (selected) {
                      setState(() {
                        _selectedShiftFilter = selected ? 'all' : null;
                      });
                      _applyScheduleToDepartments(shiftId: _selectedShiftFilter);
                    },
                    selectedColor: const Color(0xFF10B981).withOpacity(0.12),
                    checkmarkColor: const Color(0xFF059669),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: _selectedShiftFilter == 'all'
                            ? const Color(0xFF10B981)
                            : Colors.grey.shade300,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class _CategoryDirectCard extends StatelessWidget {
  final PerformanceCategory category;
  final IconData icon;
  final String title;
  final int completedCount;
  final int totalQuantity;
  final int averageSeconds;
  final String unit;
  final Color color;
  final VoidCallback onAddTimer;
  final VoidCallback onViewDetail;

  const _CategoryDirectCard({
    required this.category,
    required this.icon,
    required this.title,
    required this.completedCount,
    required this.totalQuantity,
    required this.averageSeconds,
    required this.unit,
    required this.color,
    required this.onAddTimer,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final avgStr = PerformanceCalculator.formatSeconds(averageSeconds);
    final isMax = completedCount >= 20;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'BeVietnamPro',
                              color: color,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isMax ? AppColors.danger.withOpacity(0.1) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$completedCount/20 lần',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'BeVietnamPro',
                                color: isMax ? AppColors.danger : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng: $totalQuantity $unit • Trung bình: $avgStr / $unit',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontFamily: 'BeVietnamPro',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isMax ? null : onAddTimer,
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                    label: Text(
                      isMax ? 'Đã đủ 20 lần' : '+ BẤM GIỜ $title',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'BeVietnamPro',
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onViewDetail,
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Text(
                    'Chi tiết ➔',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
