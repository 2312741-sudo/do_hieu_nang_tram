import 'package:flutter_test/flutter_test.dart';
import 'package:do_hieu_nang_tram/models/member_model.dart';
import 'package:do_hieu_nang_tram/features/store/services/store_inheritance_service.dart';

void main() {
  group('StoreInheritanceService in do_hieu_nang_tram', () {
    final now = DateTime.now().toUtc();

    MemberModel createMember({
      required String id,
      required String name,
      required UserRole role,
      required MemberStatus status,
      required DateTime joinedAt,
    }) {
      return MemberModel(
        userId: id,
        name: name,
        role: role,
        status: status,
        employeeType: EmployeeType.fulltime,
        joinedAt: joinedAt,
      );
    }

    test('Ưu tiên Quản lý 1 vào sớm nhất', () {
      final candidates = [
        createMember(
          id: 'emp1',
          name: 'Nhân viên 1',
          role: UserRole.employee,
          status: MemberStatus.active,
          joinedAt: now.subtract(const Duration(days: 100)),
        ),
        createMember(
          id: 'ql1_late',
          name: 'Quản lý 1 Mới',
          role: UserRole.manager1,
          status: MemberStatus.active,
          joinedAt: now.subtract(const Duration(days: 10)),
        ),
        createMember(
          id: 'ql1_early',
          name: 'Quản lý 1 Cũ',
          role: UserRole.manager1,
          status: MemberStatus.active,
          joinedAt: now.subtract(const Duration(days: 50)),
        ),
        createMember(
          id: 'ql2',
          name: 'Quản lý 2',
          role: UserRole.manager2,
          status: MemberStatus.active,
          joinedAt: now.subtract(const Duration(days: 60)),
        ),
      ];

      final nextOwner = StoreInheritanceService.selectNextOwner(candidates);
      expect(nextOwner?.userId, 'ql1_early');
    });

    test('Nếu không có Quản lý 1 -> Chọn Quản lý 2 vào sớm nhất', () {
      final candidates = [
        createMember(
          id: 'emp1',
          name: 'Nhân viên 1',
          role: UserRole.employee,
          status: MemberStatus.active,
          joinedAt: now.subtract(const Duration(days: 100)),
        ),
        createMember(
          id: 'ql2_late',
          name: 'Quản lý 2 Mới',
          role: UserRole.manager2,
          status: MemberStatus.active,
          joinedAt: now.subtract(const Duration(days: 20)),
        ),
        createMember(
          id: 'ql2_early',
          name: 'Quản lý 2 Cũ',
          role: UserRole.manager2,
          status: MemberStatus.active,
          joinedAt: now.subtract(const Duration(days: 40)),
        ),
      ];

      final nextOwner = StoreInheritanceService.selectNextOwner(candidates);
      expect(nextOwner?.userId, 'ql2_early');
    });

    test('Nếu chỉ có Nhân viên -> Chọn Nhân viên vào sớm nhất', () {
      final candidates = [
        createMember(
          id: 'emp_late',
          name: 'Nhân viên Mới',
          role: UserRole.employee,
          status: MemberStatus.active,
          joinedAt: now.subtract(const Duration(days: 10)),
        ),
        createMember(
          id: 'emp_early',
          name: 'Nhân viên Cũ',
          role: UserRole.employee,
          status: MemberStatus.active,
          joinedAt: now.subtract(const Duration(days: 80)),
        ),
      ];

      final nextOwner = StoreInheritanceService.selectNextOwner(candidates);
      expect(nextOwner?.userId, 'emp_early');
    });

    test('Không chọn thành viên bị kicked hoặc pending', () {
      final candidates = [
        createMember(
          id: 'ql1_kicked',
          name: 'Quản lý 1 Bị Xóa',
          role: UserRole.manager1,
          status: MemberStatus.kicked,
          joinedAt: now.subtract(const Duration(days: 200)),
        ),
        createMember(
          id: 'ql1_pending',
          name: 'Quản lý 1 Chờ Duyệt',
          role: UserRole.manager1,
          status: MemberStatus.pending,
          joinedAt: now.subtract(const Duration(days: 150)),
        ),
        createMember(
          id: 'emp_active',
          name: 'Nhân viên Hoạt Động',
          role: UserRole.employee,
          status: MemberStatus.active,
          joinedAt: now.subtract(const Duration(days: 10)),
        ),
      ];

      final nextOwner = StoreInheritanceService.selectNextOwner(candidates);
      expect(nextOwner?.userId, 'emp_active');
    });

    test('Không chọn chính người Chủ đang rời đi', () {
      final candidates = [
        createMember(
          id: 'owner_user',
          name: 'Chủ Hiện Tại',
          role: UserRole.owner,
          status: MemberStatus.active,
          joinedAt: now.subtract(const Duration(days: 300)),
        ),
        createMember(
          id: 'emp1',
          name: 'Nhân viên duy nhất',
          role: UserRole.employee,
          status: MemberStatus.active,
          joinedAt: now.subtract(const Duration(days: 50)),
        ),
      ];

      final nextOwner = StoreInheritanceService.selectNextOwner(
        candidates,
        leavingOwnerId: 'owner_user',
      );
      expect(nextOwner?.userId, 'emp1');
    });

    test('Nếu không còn ai khác -> Trả về null để chuyển trạng thái orphaned', () {
      final candidates = [
        createMember(
          id: 'owner_user',
          name: 'Chủ Duy Nhất',
          role: UserRole.owner,
          status: MemberStatus.active,
          joinedAt: now.subtract(const Duration(days: 300)),
        ),
      ];

      final nextOwner = StoreInheritanceService.selectNextOwner(
        candidates,
        leavingOwnerId: 'owner_user',
      );
      expect(nextOwner, isNull);
    });
  });
}
