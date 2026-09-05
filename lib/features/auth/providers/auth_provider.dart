import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final currentStoreIdProvider = Provider<String?>((ref) {
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
  final member = ref.watch(currentMemberProvider).valueOrNull;
  if (member != null) {
    return member.role;
  }

  final store = ref.watch(currentStoreProvider).valueOrNull;
  final uid = ref.watch(currentUserIdProvider);
  if (store != null && uid != null && store.ownerId.trim() == uid.trim()) {
    return UserRole.owner;
  }

  return null;
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

/// Danh sách Quản lý của cửa hàng (dành cho ô chọn Quản lý đứng ca - Single select)
final storeManagersProvider = Provider<List<MemberModel>>((ref) {
  final members = ref.watch(storeMembersProvider).valueOrNull ?? [];
  return members.where((m) => m.role.isManager && m.isActive).toList();
});

/// Danh sách Nhân sự trong ca (dành cho ô chọn Nhân viên trong ca - Multi select)
/// ĐÃ CẬP NHẬT THEO YÊU CẦU: Hiển thị cả Nhân viên VÀ Quản lý trong ca
final storeShiftStaffProvider = Provider<List<MemberModel>>((ref) {
  final members = ref.watch(storeMembersProvider).valueOrNull ?? [];
  return members.where((m) => (m.role.isEmployee || m.role.isManager) && m.isActive).toList();
});
