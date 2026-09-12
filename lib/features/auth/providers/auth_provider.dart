import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';
import '../../../models/user_model.dart';
import '../../../models/member_model.dart';
import '../../../models/store_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentFirebaseUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateChangesProvider).whenOrNull(data: (u) => u);
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentFirebaseUserProvider)?.uid;
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchUserDocument(uid);
});

/// Quản lý trạng thái chọn cửa hàng RIÊNG BIỆT của app Đo Hiệu Năng:
/// Lưu trong SharedPreferences local, TUYỆT ĐỐI KHÔNG ghi đè users/{uid}.currentStoreId trên Firestore
class PerformanceStoreNotifier extends StateNotifier<String?> {
  final Ref _ref;

  PerformanceStoreNotifier(this._ref) : super(null) {
    _init();
  }

  Future<void> _init() async {
    final uid = _ref.read(currentUserIdProvider);
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      final savedStoreId = prefs.getString('perf_store_$uid');
      if (savedStoreId != null && savedStoreId.isNotEmpty) {
        state = savedStoreId;
      }
    }
  }

  Future<void> selectStore(String storeId) async {
    state = storeId;
    final uid = _ref.read(currentUserIdProvider);
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('perf_store_$uid', storeId);
    }
  }
}

final performanceSelectedStoreIdProvider =
    StateNotifierProvider<PerformanceStoreNotifier, String?>((ref) {
  return PerformanceStoreNotifier(ref);
});

final currentStoreIdProvider = Provider<String?>((ref) {
  // 1. Ưu tiên cửa hàng được chọn riêng cho Đo Hiệu Năng trong SharedPreferences
  final perfStoreId = ref.watch(performanceSelectedStoreIdProvider);
  if (perfStoreId != null && perfStoreId.isNotEmpty) {
    return perfStoreId;
  }

  // 2. Fallback sang currentStoreId của user nếu có
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) return null;

  if (user.currentStoreId != null && user.currentStoreId!.isNotEmpty) {
    if (user.storeIds.isEmpty || user.storeIds.contains(user.currentStoreId)) {
      return user.currentStoreId;
    }
  }
  if (user.storeIds.isNotEmpty) {
    return user.storeIds.first;
  }
  return null;
});

final currentStoreProvider = StreamProvider<StoreModel?>((ref) {
  final storeId = ref.watch(currentStoreIdProvider);
  if (storeId == null || storeId.isEmpty) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchStore(storeId);
});

final userStoresProvider = FutureProvider<List<StoreModel>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return [];
  ref.watch(currentUserProvider);
  return ref.watch(authRepositoryProvider).getUserStores(uid);
});

final userStoresWithRoleProvider = FutureProvider<List<UserStoreWithRole>>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return [];
  ref.watch(currentUserProvider);
  return ref.watch(authRepositoryProvider).getUserStoresWithRoles(uid);
});

final currentMemberProvider = StreamProvider<MemberModel?>((ref) {
  final uid = ref.watch(currentUserIdProvider);
  final storeId = ref.watch(currentStoreIdProvider);
  if (uid == null || storeId == null || storeId.isEmpty) {
    return Stream.value(null);
  }
  return ref.watch(authRepositoryProvider).watchMember(storeId, uid);
});

final currentRoleProvider = Provider<UserRole?>((ref) {
  final store = ref.watch(currentStoreProvider).valueOrNull;
  final uid = ref.watch(currentUserIdProvider);
  final member = ref.watch(currentMemberProvider).valueOrNull;

  if (store == null || uid == null) return null;

  final isStoreOwner = store.ownerId.trim() == uid.trim();

  // 1. Nếu member doc chưa tải hoặc không tồn tại, nhưng store.ownerId == uid -> Chủ quán
  if (member == null) {
    return isStoreOwner ? UserRole.owner : null;
  }

  // 2. PERMISSION TRUTH RECONCILIATION:
  // Nếu member doc ghi role == owner, nhưng store.ownerId KHÁC uid -> hạ quyền xuống manager1 (chống chiếm quyền)
  if (member.role == UserRole.owner) {
    return isStoreOwner ? UserRole.owner : UserRole.manager1;
  }

  // 3. Nếu store.ownerId khớp uid -> luôn bảo vệ quyền Chủ tối cao
  if (isStoreOwner) {
    return UserRole.owner;
  }

  // 4. Các role thông thường (manager1, manager2, legacyManager, employee)
  return member.role;
});

final isOwnerProvider = Provider<bool>((ref) {
  final role = ref.watch(currentRoleProvider);
  return role == UserRole.owner;
});

final isManagerProvider = Provider<bool>((ref) {
  final role = ref.watch(currentRoleProvider);
  return role != null && role.isManager;
});

final isEmployeeProvider = Provider<bool>((ref) {
  final role = ref.watch(currentRoleProvider);
  return role == UserRole.employee;
});

final storeMembersProvider = StreamProvider<List<MemberModel>>((ref) {
  final storeId = ref.watch(currentStoreIdProvider);
  if (storeId == null || storeId.isEmpty) return Stream.value([]);
  return ref.watch(authRepositoryProvider).watchStoreMembers(storeId);
});

/// Danh sách Quản lý / Chủ quán của cửa hàng (dành cho ô chọn Quản lý đứng ca - Single select)
final storeManagersProvider = Provider<List<MemberModel>>((ref) {
  final members = ref.watch(storeMembersProvider).valueOrNull ?? [];
  return members.where((m) => (m.role.isManager || m.role.isOwner) && m.isActive).toList();
});

/// Danh sách Nhân sự trong ca (dành cho ô chọn Nhân viên trong ca - Multi select)
/// Hiển thị cả Nhân viên, Quản lý và Chủ cửa hàng trong ca
final storeShiftStaffProvider = Provider<List<MemberModel>>((ref) {
  final members = ref.watch(storeMembersProvider).valueOrNull ?? [];
  return members.where((m) => (m.role.isEmployee || m.role.isManager || m.role.isOwner) && m.isActive).toList();
});
