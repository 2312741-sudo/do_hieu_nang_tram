# ⏱️ Đo Hiệu Năng Trạm (Performance Measurement App)

Ứng dụng & module Flutter đa nền tảng (**Android, iOS, Web**) chuyên biệt để đo lường, giám sát và tối ưu hóa thời gian pha chế Nước, nướng/chuẩn bị Bánh và thời gian xử lý Đơn hàng tại chuỗi cửa hàng **Trạm**. Được tích hợp hoàn toàn đồng bộ với hệ sinh thái **Chấm Công Trạm** (`chamcongtram`).

---

## 1. Hệ Sinh Thái & Dùng Chung Firebase

Ứng dụng sử dụng chung toàn bộ hạ tầng Backend với Chấm Công Trạm:
- **Firebase Project:** `chamcongtram`
- **Firebase Auth:** Dùng chung tài khoản, email/password, Google Sign-in.
- **Collection `/users/{userId}`:** Tái sử dụng thông tin tài khoản, danh sách cửa hàng (`storeIds`), cửa hàng kích hoạt (`currentStoreId`).
- **Collection `/stores/{storeId}`:** Thông tin cửa hàng, danh sách chi nhánh.
- **Subcollection `/stores/{storeId}/members/{userId}`:** Phân quyền và vai trò theo cửa hàng.

---

## 2. Ma Trận Phân Quyền & Vai Trò (RBAC)

| Vai trò trong hệ thống | Role String trên Firestore | Quyền truy cập Đo Hiệu Năng | Mô tả nghiệp vụ |
| :--- | :--- | :---: | :--- |
| **Chủ cửa hàng** | `owner` | ✅ Có (Chủ) | Nhận báo cáo realtime từ Quản lý, badge báo cáo chưa xem, xem chi tiết ca, nhân sự và xuất Excel. |
| **Quản lý** | `manager_1`, `manager1`, `manager_2`, `manager2`, `manager` | ✅ Có (Quản lý) | Chọn QL đứng ca, multi-select nhân viên trong ca, bắt đầu phiên, đo multi-timer Nước/Bánh/Đơn, kết thúc phiên & nộp báo cáo. |
| **Nhân viên** | `employee` | ⛔ **BỊ CHẶN** | Hiển thị màn hình thông báo: *"Bạn không có quyền sử dụng tính năng Đo Hiệu Năng."* Firestore Security Rules chặn ở mức database. |

---

## 3. Quy Chuẩn Nhân Sự Phiên Đo (Mục 62 - 75)

1. **Quản lý đứng ca (`managerOnDutyId`, `managerOnDutyName`):**
   - Single-select dropdown.
   - Chỉ hiển thị người có vai trò Quản lý thuộc đúng cửa hàng.
2. **Nhân viên trong ca (`employeeIds`, `employeeNames`):**
   - Multi-select dropdown/chips.
   - Hiển thị cả Nhân viên và Quản lý phụ ca của cửa hàng.
3. **Khóa read-only:**
   - Ngay sau khi bấm `BẮT ĐẦU PHIÊN ĐO`, thông tin nhân sự chuyển thành chế độ read-only đã khóa.
   - Snapshot nhân sự được lưu vào Session, nộp vào Report và xuất đầy đủ ra sheet `TongQuan` của file Excel.

---

## 4. Cơ Chế Multi-Timer & Tính Toán Thời Gian

- **Nguồn thời gian Timestamp:** Tính `elapsed = DateTime.now() - startedAt - totalPausedDuration`. Không tích lũy giây qua periodic timer, đảm bảo chính xác tuyệt đối khi chuyển tab, khóa màn hình hoặc app background.
- **Multi-timer đồng thời:** Chạy song song nhiều timer Nước, Bánh, Đơn hàng độc lập.
- **Giới hạn đo:** Tối đa 20 lần đo cho mỗi hạng mục trong một phiên.
- **Tính toán trung bình:**
  - Nước: Weighted average = `totalDuration / totalQuantity`
  - Bánh: Weighted average = `totalDuration / totalQuantity`
  - Đơn hàng: Average = `totalDuration / totalOrderCount`
  - Định dạng hiển thị `mm:ss` chuẩn (VD: `03:19`, `04:45`).

---

## 5. Xuất Báo Cáo Excel (.xlsx)

File name: `BaoCao_HieuNang_[TÊN_QUÁN]_[YYYY-MM-DD].xlsx`
- **Sheet 1: `TongQuan`:** Cửa hàng, Quản lý đứng ca, Nhân viên trong ca, thời gian bắt đầu/kết thúc, bảng tổng hợp hiệu năng.
- **Sheet 2: `Nuoc`:** STT, Ngày, Giờ bắt đầu, Giờ kết thúc, QL đứng ca, Cửa hàng, Số lượng nước, Tổng thời gian, Thời gian / nước.
- **Sheet 3: `Banh`:** Chi tiết từng lần đo bánh.
- **Sheet 4: `DonHang`:** Chi tiết từng đơn hàng và thời gian xử lý.
- **Hỗ trợ đa nền tảng:** Tải file trực tiếp trên Web trình duyệt, mở hộp thoại Share / Lưu cache trên Android & iOS.

---

## 6. Hướng Dẫn Cài Đặt & Khởi Chạy

```bash
# 1. Cài đặt thư viện
flutter pub get

# 2. Chạy kiểm thử tự động (Unit Tests)
flutter test

# 3. Phân tích mã nguồn
flutter analyze

# 4. Chạy trên trình duyệt Web
flutter run -d chrome

# 5. Chạy trên thiết bị di động
flutter run
```
