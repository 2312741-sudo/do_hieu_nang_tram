class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'Đo Hiệu Năng Trạm';
  static const String appTagline = 'Đo lường tốc độ pha chế & xử lý đơn hàng';
  static const String appVersion = 'Phiên bản 1.0.4';

  // Auth
  static const String login = 'Đăng nhập';
  static const String email = 'Email';
  static const String emailHint = 'Nhập email của bạn';
  static const String password = 'Mật khẩu';
  static const String passwordHint = 'Nhập mật khẩu';
  static const String forgotPassword = 'Quên mật khẩu?';
  static const String cancel = 'Hủy';
  static const String sendResetEmail = 'Gửi email khôi phục';
  static const String successPasswordReset = 'Đã gửi email khôi phục mật khẩu. Vui lòng kiểm tra hộp thư.';
  static const String errorGeneral = 'Có lỗi xảy ra, vui lòng thử lại.';
  static const String errorRequiredField = 'Vui lòng không để trống';
  static const String errorInvalidEmail = 'Email không hợp lệ';

  // Categories
  static const String drink = 'Nước';
  static const String cake = 'Bánh';
  static const String order = 'Đơn hàng';

  // Roles & Permissions
  static const String accessDeniedTitle = 'Không có quyền truy cập';
  static const String accessDeniedMessage = 'Bạn không có quyền sử dụng tính năng Đo Hiệu Năng.';
  static const String employeeRoleNotice = 'Tính năng này chỉ dành cho Chủ cửa hàng và Quản lý.';

  // Session
  static const String startSession = 'BẮT ĐẦU PHIÊN ĐO';
  static const String continueSession = 'TIẾP TỤC PHIÊN ĐO';
  static const String endSession = 'KẾT THÚC PHIÊN';
  static const String endAndSubmitReport = 'KẾT THÚC & GỬI BÁO CÁO';
  static const String activeSessionTitle = 'Phiên đo đang hoạt động';
  static const String noActiveSession = 'Chưa có phiên đo đang hoạt động.';

  // Staff on duty
  static const String managerOnDuty = 'QUẢN LÝ ĐỨNG CA';
  static const String employeesOnDuty = 'NHÂN VIÊN TRONG CA';
  static const String selectManagerHint = 'Chọn quản lý đứng ca';
  static const String selectEmployeesHint = 'Chọn nhân sự trong ca';
  static const String personnelSection = 'NHÂN SỰ PHIÊN ĐO';

  // Measurement
  static const String startMeasuring = 'Bắt đầu đo';
  static const String addMeasurement = '+ THÊM LẦN ĐO';
  static const String pause = 'Tạm dừng';
  static const String resume = 'Tiếp tục';
  static const String complete = 'Hoàn thành';
  static const String cancelMeasurement = 'Hủy lần đo';
  static const String maxMeasurementsReached = 'Đã đạt tối đa 20 lần đo.';

  // Units & Formats
  static const String perDrink = '/ nước';
  static const String perCake = '/ bánh';
  static const String perOrder = '/ đơn';
  static const String total = 'Tổng';
  static const String average = 'TB';
  static const String completedStatus = 'Đã hoàn thành';
  static const String runningStatus = 'Đang chạy';
  static const String pausedStatus = 'Tạm dừng';

  // Excel
  static const String exportExcel = 'XUẤT EXCEL';
  static const String excelExportSuccess = 'Xuất file Excel thành công';
  static const String excelExportError = 'Không thể xuất file Excel. Vui lòng thử lại.';
}
