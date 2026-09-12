import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../models/user_model.dart';
import '../../../models/member_model.dart';
import '../../../models/store_model.dart';
import '../../store/services/store_inheritance_service.dart';

class UserStoreWithRole {
  final StoreModel store;
  final UserRole role;

  const UserStoreWithRole({
    required this.store,
    required this.role,
  });
}

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        userCredential = await _auth.signInWithProvider(googleProvider);
      }
      await _ensureFirestoreUserExists(userCredential.user);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'web-context-cancelled' ||
          e.code == 'cancelled' ||
          e.code == 'user-cancelled' ||
          e.code == 'canceled') {
        throw FirebaseAuthException(
          code: 'cancelled',
          message: 'Người dùng đã hủy đăng nhập Google',
        );
      }
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Lỗi đăng nhập Google: $e',
      );
    }
  }

  Future<UserCredential> signInWithApple() async {
    try {
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(appleProvider);
      } else {
        userCredential = await _auth.signInWithProvider(appleProvider);
      }
      await _ensureFirestoreUserExists(userCredential.user);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'web-context-cancelled' ||
          e.code == 'cancelled' ||
          e.code == 'user-cancelled' ||
          e.code == 'canceled') {
        throw FirebaseAuthException(
          code: 'cancelled',
          message: 'Người dùng đã hủy đăng nhập Apple',
        );
      }
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'apple-sign-in-failed',
        message: 'Lỗi đăng nhập Apple: $e',
      );
    }
  }

  Future<void> _ensureFirestoreUserExists(User? user, {String? fallbackName}) async {
    if (user == null) return;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      final name = fallbackName ??
          (user.displayName != null && user.displayName!.isNotEmpty
              ? user.displayName!
              : 'Người dùng');
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: user.email ?? '',
        avatarUrl: user.photoURL,
        createdAt: DateTime.now().toUtc(),
      );
      await _firestore.collection('users').doc(user.uid).set(userModel.toJson());
    } else {
      final data = doc.data() ?? {};
      final existingAvatar = data['avatarUrl'] as String?;
      if ((existingAvatar == null || existingAvatar.trim().isEmpty) &&
          user.photoURL != null &&
          user.photoURL!.trim().isNotEmpty) {
        try {
          await _firestore.collection('users').doc(user.uid).update({
            'avatarUrl': user.photoURL,
          });
        } catch (_) {}
      }
    }
  }

  Stream<UserModel?> watchUserDocument(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return UserModel.fromFirestore(snap);
    });
  }

  Stream<StoreModel?> watchStore(String storeId) {
    return _firestore.collection('stores').doc(storeId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return StoreModel.fromJson(snap.data()!, snap.id);
    });
  }

  Stream<MemberModel?> watchMember(String storeId, String uid) {
    return _firestore
        .collection('stores')
        .doc(storeId)
        .collection('members')
        .snapshots()
        .map((snap) {
      for (final doc in snap.docs) {
        if (doc.id.trim() == uid.trim()) {
          return MemberModel.fromFirestore(doc);
        }
        final data = doc.data();
        final docUserId = data['userId']?.toString() ??
            data['id']?.toString() ??
            data['uid']?.toString();
        if (docUserId != null && docUserId.trim() == uid.trim()) {
          return MemberModel.fromFirestore(doc);
        }
      }
      return null;
    });
  }

  Stream<List<MemberModel>> watchStoreMembers(String storeId) {
    return _firestore
        .collection('stores')
        .doc(storeId)
        .collection('members')
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => MemberModel.fromFirestore(doc))
          .where((m) => m.status == MemberStatus.active)
          .toList();
    });
  }

  Future<List<StoreModel>> getUserStores(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      final storeIds = List<String>.from(userData['storeIds'] ?? []);
      final currentStoreId = userData['currentStoreId'] as String?;

      if (currentStoreId != null &&
          currentStoreId.isNotEmpty &&
          !storeIds.contains(currentStoreId)) {
        storeIds.add(currentStoreId);
      }

      // Auto-discover stores owned by user
      try {
        final ownedStores = await _firestore
            .collection('stores')
            .where('ownerId', isEqualTo: uid)
            .get();
        for (final doc in ownedStores.docs) {
          if (!storeIds.contains(doc.id)) {
            storeIds.add(doc.id);
          }
        }
      } catch (_) {}

      // Auto-discover stores where user is member
      try {
        final memberDocs = await _firestore
            .collectionGroup('members')
            .where('userId', isEqualTo: uid)
            .get();
        for (final doc in memberDocs.docs) {
          final storeRef = doc.reference.parent.parent;
          if (storeRef != null && !storeIds.contains(storeRef.id)) {
            final status = doc.data()['status'] as String?;
            if (status != 'kicked') {
              storeIds.add(storeRef.id);
            }
          }
        }
      } catch (_) {}

      if (storeIds.isEmpty) return [];

      final stores = <StoreModel>[];
      for (final id in storeIds) {
        final snap = await _firestore.collection('stores').doc(id).get();
        if (snap.exists && snap.data() != null) {
          final store = StoreModel.fromJson(snap.data()!, snap.id);
          if (!store.isDeleted) {
            stores.add(store);
          }
        }
      }
      return stores;
    } catch (_) {
      return [];
    }
  }

  Future<List<UserStoreWithRole>> getUserStoresWithRoles(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      final storeIds = List<String>.from(userData['storeIds'] ?? []);
      final currentStoreId = userData['currentStoreId'] as String?;

      if (currentStoreId != null &&
          currentStoreId.isNotEmpty &&
          !storeIds.contains(currentStoreId)) {
        storeIds.add(currentStoreId);
      }

      // Auto-discover stores owned by user
      try {
        final ownedStores = await _firestore
            .collection('stores')
            .where('ownerId', isEqualTo: uid)
            .get();
        for (final doc in ownedStores.docs) {
          if (!storeIds.contains(doc.id)) {
            storeIds.add(doc.id);
          }
        }
      } catch (_) {}

      // Auto-discover stores where user is member
      try {
        final memberDocs = await _firestore
            .collectionGroup('members')
            .where('userId', isEqualTo: uid)
            .get();
        for (final doc in memberDocs.docs) {
          final storeRef = doc.reference.parent.parent;
          if (storeRef != null && !storeIds.contains(storeRef.id)) {
            final status = doc.data()['status'] as String?;
            if (status != 'kicked') {
              storeIds.add(storeRef.id);
            }
          }
        }
      } catch (_) {}

      if (storeIds.isEmpty) return [];

      final results = <UserStoreWithRole>[];
      for (final id in storeIds) {
        final snap = await _firestore.collection('stores').doc(id).get();
        if (snap.exists && snap.data() != null) {
          final store = StoreModel.fromJson(snap.data()!, snap.id);
          if (!store.isDeleted) {
            UserRole? role;

            // 1. Check direct doc by uid in members subcollection
            final memberDoc = await _firestore
                .collection('stores')
                .doc(id)
                .collection('members')
                .doc(uid)
                .get();
            if (memberDoc.exists && memberDoc.data() != null) {
              final member = MemberModel.fromFirestore(memberDoc);
              role = member.role;
            } else {
              // 2. Query where userId == uid
              final memberQuery = await _firestore
                  .collection('stores')
                  .doc(id)
                  .collection('members')
                  .where('userId', isEqualTo: uid)
                  .limit(1)
                  .get();
              if (memberQuery.docs.isNotEmpty) {
                final member = MemberModel.fromFirestore(memberQuery.docs.first);
                role = member.role;
              } else {
                // 3. Fallback: inspect all docs in members collection in case field is id or uid
                try {
                  final allMembers = await _firestore
                      .collection('stores')
                      .doc(id)
                      .collection('members')
                      .get();
                  for (final doc in allMembers.docs) {
                    final data = doc.data();
                    final mUid = data['userId']?.toString() ??
                        data['id']?.toString() ??
                        data['uid']?.toString() ??
                        doc.id;
                    if (mUid.trim() == uid.trim()) {
                      role = MemberModel.fromFirestore(doc).role;
                      break;
                    }
                  }
                } catch (_) {}
              }
            }

            // 4. Fallback to owner check only if no member doc was found in members collection
            if (role == null) {
              if (store.ownerId.trim() == uid.trim()) {
                role = UserRole.owner;
              } else {
                role = UserRole.employee;
              }
            }

            results.add(UserStoreWithRole(store: store, role: role));
          }
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  Future<bool> switchCurrentStore(String uid, String storeId) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'currentStoreId': storeId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // ── Step 1: Kích hoạt kế thừa cửa hàng nếu user là Chủ / dọn dẹp quan hệ store ──
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final storeIds = <String>{};

      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        final rawStoreIds = List<String>.from(userData['storeIds'] ?? []);
        storeIds.addAll(rawStoreIds.where((id) => id.isNotEmpty));

        final currentStoreId = userData['currentStoreId'] as String?;
        if (currentStoreId != null && currentStoreId.isNotEmpty) {
          storeIds.add(currentStoreId);
        }
      }

      // Fallback discovery: tìm các cửa hàng user sở hữu hoặc có member doc
      try {
        final ownedSnap = await _firestore
            .collection('stores')
            .where('ownerId', isEqualTo: uid)
            .get();
        for (final doc in ownedSnap.docs) {
          storeIds.add(doc.id);
        }
      } catch (_) {}

      try {
        final memberSnap = await _firestore
            .collectionGroup('members')
            .where('userId', isEqualTo: uid)
            .get();
        for (final doc in memberSnap.docs) {
          final storeRef = doc.reference.parent.parent;
          if (storeRef != null && storeRef.id.isNotEmpty) {
            storeIds.add(storeRef.id);
          }
        }
      } catch (_) {}

      final inheritanceService =
          StoreInheritanceService(firestore: _firestore);
      for (final storeId in storeIds) {
        try {
          await inheritanceService.executeInheritance(
            storeId: storeId,
            leavingUserId: uid,
            reason: 'account_deleted',
          );
        } catch (_) {
          // Bỏ qua lỗi từng store, không chặn quá trình xóa TK
        }
      }
    } catch (_) {
      // Bỏ qua lỗi bước cleanup, tiếp tục xóa tài khoản
    }

    // ── Step 2: Xóa document /users/{uid} ──
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (_) {}

    // ── Step 3: Xóa Firebase Auth account ──
    await user.delete();
  }
}
