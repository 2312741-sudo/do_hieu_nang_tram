# APP REVIEW NOTES / INSTRUCTIONS FOR APPLE REVIEW TEAM

**App Name:** Đo Hiệu Năng Trạm
**Version:** 1.0
**Platform:** iOS

---

## 1. DEMO CREDENTIALS

- **Sign-in Required:** Yes
- **Demo Username / Email:** `nguyenthanhlinh677@gmail.com`
- **Demo Password:** `Linh1234`

---

## 2. APP OVERVIEW & DUAL-ROLE TESTING CONFIGURATION

"Đo Hiệu Năng Trạm" is an internal operations and productivity measurement application designed for coffee shop staff, managers, and owners at the "Trạm" chain.

The provided demo account (`nguyenthanhlinh677@gmail.com`) is configured with multi-store access to allow full testing of both **Store Manager** and **Store Owner** workflows:

1. **Store "test store"** ➔ **Manager Role (Quản lý)**:
   - Used for live shift operations: assigning on-duty personnel, running multi-category stopwatch timers (Drink, Cake, Order), logging mid-shift incidents, completing the end-shift report checklist, and submitting session reports.

2. **Store "test 2"** ➔ **Owner Role (Chủ quán)**:
   - Used for store governance & analytics: viewing comprehensive session reports, tracking staff performance rankings (Leaderboard), configuring store standards, and managing dynamic end-shift reporting forms.

---

## 3. STEP-BY-STEP TESTING GUIDE FOR REVIEWERS

### Step 1: Sign In & Store Selection
1. Open the app and log in with:
   - Email: `nguyenthanhlinh677@gmail.com`
   - Password: `Linh1234`
2. After authentication, the app presents the Store Selection screen.

---

### Step 2: Testing Store Manager Workflow (Store: "test store")
1. Tap on the store named **"test store"** (Role: Manager).
2. You will enter the **Manager Dashboard**:
   - **Start a Measurement Session:** Select the active manager and assign team members to departments (Drinks, Cake, Service), then tap "Bắt đầu phiên đo" (Start Session).
   - **Live Timers Tab:** Tap any of the 3 action buttons (+ BẤM GIỜ NƯỚC, + BẤM GIỜ BÁNH, + BẤM GIỜ ĐƠN HÀNG) to start live timing measurements. You can pause, resume, or finish timers.
   - **Log Incidents:** Tap the "Báo lỗi" button below the timer section to record any operational incident during the shift.
   - **End Session & Submit Report:** Tap "KẾT THÚC PHIÊN ĐO" (End Session). Review the session metrics summary, fill out the required end-shift checklist/form, and tap "GỬI BÁO CÁO CHO CHỦ QUÁN" (Submit Report).
   - **History Tab:** View past submitted session reports.

---

### Step 3: Testing Store Owner Workflow (Store: "test 2")
1. To switch stores: Tap the Store Name / Account banner at the top of the screen (or the profile icon) and select **"test 2"** (Role: Owner).
2. You will enter the **Owner Dashboard**:
   - **Overview Tab:** View real-time store performance metrics and recent submitted session reports.
   - **Performance Leaderboard ("Bảng xếp hạng hiệu suất"):** Tap on the Leaderboard card to view multi-day employee performance rankings, sorted by completion percentage against store standards across Drink, Cake, and Total categories.
   - **Store Performance Standards & Dynamic Forms ("Cài đặt tiêu chuẩn & Biểu mẫu"):** Adjust standard target seconds per item and customize end-of-shift checklist questions for the store.
   - **Reports Tab ("Báo cáo"):** Open any submitted session report to view full timing breakdowns, incident logs, completed form responses, and tap **"XUẤT EXCEL"** to export an `.xlsx` performance report.

---

## 4. CONTACT INFORMATION

If you have any questions or require additional test configurations during the review process, please contact us immediately:
- **Developer / Submitter:** Thanh Tam Nguyen
- **Email:** support@tramcoffee.vn / nguyenthanhlinh677@gmail.com
