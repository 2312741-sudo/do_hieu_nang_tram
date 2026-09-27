# APP STORE CONNECT METADATA & REVIEW NOTES — VERSION 1.0.7

**App Name:** Đo Hiệu Năng Trạm
**Version:** 1.0.7
**Build:** 15
**Platform:** iOS

---


## ⚡ URGENT NOTE TO TESTER — VERSION 1.0.7

Dear Review / Test Team,

We **sincerely apologize** for this repeated update submission and the inconvenience it has caused to your review process.

After discovering critical usability issues and performance delays in previous builds just before our scheduled store operations go-live, we issued this comprehensive update **1.0.7 (Build 15)** to ensure stable, smooth operations for our store staff and managers.

**Key improvements in 1.0.7 (Build 15):**

1. **Instant Order Timer:** Order timers can now start immediately with deferred order code entry on the active timer card.
2. **Incident Evidence Photos:** Shift managers can now attach evidence photos for recorded incidents (with auto-timestamp camera watermarking or gallery picking, and direct hyperlinks in Excel reports).
3. **App Launch & Rendering Performance:** Eliminated startup latency by parallelizing store resolution and optimizing provider reactivity.
4. **Resolved UI text wrapping:** Fixed text column wrapping issues in end-of-shift reports.
5. **Fixed duplicate timer & session isolation bugs:** Guaranteed single timer creation and distinct session ownership per manager account.

We **kindly and urgently request that you prioritize the review of this build** so it can go live for our store network.

Respectfully,
**The Đo Hiệu Năng Trạm Development Team**

---

## 1. APP INFORMATION — VIETNAMESE (VI)

### Name

Đo Hiệu Năng Trạm

### Subtitle

Bấm giờ vận hành cửa hàng

### Promotional Text

Đo thời gian pha chế, chuẩn bị bánh và xử lý đơn hàng; theo dõi phiên làm việc và báo cáo hiệu năng theo từng cửa hàng.

### Keywords

hiệu năng,bấm giờ,cửa hàng,pha chế,báo cáo,năng suất,quản lý,Trạm

### What's New in Version 1.0.7 (Build 15)

- **Bấm giờ đơn hàng linh hoạt:** Cho phép bấm giờ đo đơn ngay lập tức, nhập mã đơn sau trên thẻ đồng hồ.
- **Đính kèm ảnh sự cố:** Hỗ trợ chụp ảnh trực tiếp có đóng dấu ngày giờ, cửa hàng hoặc chọn từ thư viện ảnh; nhúng siêu liên kết xem ảnh trong file Excel.
- **Tối ưu tốc độ ứng dụng:** Khởi động cực nhanh, mượt mà, loại bỏ hoàn toàn độ trễ và hiện tượng tải lâu.
- **Cải tiến giao diện:** Tự động mở rộng ô nhập ghi chú kết ca, sửa lỗi hiển thị chữ và logo thương hiệu sắc nét trên màn hình chờ.
- **Sửa lỗi timer & phiên đo:** Ngăn chặn hoàn toàn tình trạng timer trùng lặp và đảm bảo mỗi quản lý vận hành phiên đo độc lập.

### Description

Đo Hiệu Năng Trạm hỗ trợ Chủ cửa hàng và Quản lý theo dõi thời gian thực hiện các công việc vận hành tại từng cửa hàng trong hệ sinh thái Trạm.

Tính năng chính:

- Bấm giờ đồng thời cho Nước, Bánh và Đơn hàng.
- Tạm dừng, tiếp tục và hoàn tất từng lần đo độc lập.
- Ghi nhận số lượng sản phẩm và tính thời gian trung bình.
- Quản lý phiên đo theo đúng tài khoản và cửa hàng.
- Lưu lịch sử phiên, sự cố và báo cáo cuối ca.
- Theo dõi hiệu năng nhân sự theo tiêu chuẩn của cửa hàng.
- Xem báo cáo chi tiết và xuất dữ liệu Excel.
- Phân quyền Chủ cửa hàng, Quản lý và Nhân viên bằng tài khoản dùng chung với hệ sinh thái Trạm.

Ứng dụng phục vụ công tác vận hành nội bộ. Quyền truy cập các chức năng quản lý phụ thuộc vào vai trò được cấp tại từng cửa hàng.

---

## 2. APP INFORMATION — ENGLISH (EN-US)

### Name

Đo Hiệu Năng Trạm

### Subtitle

Store performance timers

### Promotional Text

Measure preparation and order-processing times, manage work sessions, and review store performance reports.

### Keywords

performance,timer,store,drinks,bakery,orders,reports,productivity

### What's New in Version 1.0.6

- **Critical fix:** Starting a timer once no longer creates two duplicate timers simultaneously.
- **Session fix:** Two accounts at the same store no longer share the same measurement session.
- Improved timer state reliability after app restart.
- Enhanced Firestore connection stability and measurement sync.

### Description

Đo Hiệu Năng Trạm helps store owners and managers measure operational task times across stores in the Trạm ecosystem.

Key features:

- Run multiple timers for drinks, bakery items, and orders.
- Pause, resume, and complete each measurement independently.
- Record item quantities and calculate average completion times.
- Keep sessions isolated by account and store.
- Save session history, incident notes, and end-of-shift reports.
- Review staff performance against store targets.
- View detailed reports and export Excel workbooks.
- Apply store-specific access for owners, managers, and employees.

This app is intended for internal operations. Management features are available only to accounts with an authorized role at the selected store.

---

## 3. APP STORE URLS & CONTACT

- **Privacy Policy URL:** https://webquanlychamcong.vercel.app/privacy.html
- **Account Deletion URL:** https://webquanlychamcong.vercel.app/delete-account.html
- **Support URL:** https://github.com/2312741-sudo/do_hieu_nang_tram
- **Support Email:** nthanhtam.402@gmail.com

---

## 4. APP PRIVACY DECLARATION CHECKLIST

- **Contact Info — Name, Email Address:** Collected, linked to the user's identity, used for app functionality and authentication.
- **Identifiers — User ID:** Collected, linked to the user's identity, used for authentication and access control.
- **User Content — Operational measurements and reports:** Collected, linked to the user's identity, used for app functionality.
- **Precise Location:** Not collected.
- **Contacts, Photos, Financial Information:** Not collected.
- **Tracking:** Data is not used for tracking.
- **Advertising:** Data is not used for third-party advertising.
- **Encryption declaration:** ITSAppUsesNonExemptEncryption = false is configured in Info.plist.

---

## 5. APP REVIEW NOTES / INSTRUCTIONS FOR APPLE REVIEW TEAM

### Demo Credentials

- **Sign-in Required:** Yes
- **Demo Username / Email:** nguyenthanhlinh677@gmail.com
- **Demo Password:** Linh1234

---

### App Overview & Dual-Role Testing Configuration

"Đo Hiệu Năng Trạm" is an internal operations and productivity measurement application designed for coffee shop staff, managers, and owners at the "Trạm" chain.

The provided demo account (nguyenthanhlinh677@gmail.com) is configured with multi-store access to allow full testing of both Store Manager and Store Owner workflows:

1. Store "test store" → Manager Role (Quản lý):
   Used for live shift operations: assigning on-duty personnel, running multi-category stopwatch timers (Drink, Cake, Order), logging mid-shift incidents, completing the end-shift report checklist, and submitting session reports.

2. Store "test 2" → Owner Role (Chủ quán):
   Used for store governance & analytics: viewing comprehensive session reports, tracking staff performance rankings, configuring store standards, and managing dynamic end-shift reporting forms.

---

### Step-by-Step Testing Guide

#### Step 1: Sign In & Store Selection
1. Open the app and log in with Email: nguyenthanhlinh677@gmail.com / Password: Linh1234
2. The app presents the Store Selection screen after authentication.

#### Step 2: Manager Workflow (Store: "test store")
1. Tap "test store" (Role: Manager) to enter the Manager Dashboard.
2. Start a Measurement Session → assign personnel → tap "Bắt đầu phiên đo".
3. Tap BẤM GIỜ NƯỚC / BÁNH / ĐƠN HÀNG to start timers. Pause, resume, or complete each timer independently.
4. Tap "Báo lỗi" to record incidents.
5. Tap "KẾT THÚC PHIÊN ĐO", fill the checklist, then submit the report.
6. View History Tab for past reports.

#### Step 3: Owner Workflow (Store: "test 2")
1. Tap the Store Name banner and select "test 2" (Role: Owner).
2. Overview Tab: real-time store performance metrics.
3. Performance Leaderboard: multi-day employee rankings.
4. Store Standards & Forms: adjust target seconds and customize checklist.
5. Reports Tab: open any report → tap "XUẤT EXCEL" to export.

---

### Contact Information

- **Developer / Submitter:** Thanh Tam Nguyen
- **Email:** nthanhtam.402@gmail.com

---

## 6. ITEMS TO CONFIRM BEFORE SUBMISSION

- Confirm demo account credentials are still active and have access to both listed test stores.
- Upload current screenshots for iPhone and iPad display sizes required by App Store Connect.
- Complete the App Privacy questionnaire using the checklist above.
