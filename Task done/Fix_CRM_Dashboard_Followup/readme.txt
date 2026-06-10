BUG THỐNG KÊ KPI TRÊN CRM DASHBOARD KHÔNG KHỚP VÀ KHÔNG CHUYỂN DỮ LIỆU SANG POPUP

1. Nguyên nhân lỗi:
- Dashboard: Lấy số liệu dựa trên các trường ngày tháng tương tác như `LastTimeContact` hoặc `FirstTimeContact` (thông qua bảng `tblCRM_NotesHistory` đối với các trạng thái "Cần chăm sóc", "Tiềm năng", v.v.).
- Popup List (Data Collection): Lại lọc dữ liệu theo `CreatedDate` đối với trạng thái `activeStatus = 3` (Cần chăm sóc), dẫn đến kết quả trả về trong danh sách không khớp với số đếm trên Dashboard.
- Lỗi Duplicate (Trùng lặp dòng): Khi JOIN với bảng `tblCRM_CustomerOwner` (nhiều người phụ trách cùng một khách hàng), danh sách trả về bị nhân bản số dòng thay vì gom nhóm lại.
- Lỗi không lọc nhân viên trên Popup: Biến filter nhân viên `window.EmployeeIDsKPI` trên Dashboard không được truyền tự động vào Control lọc Nhân Viên của giao diện Popup khi người dùng click vào Dashboard.

2. Cách fix (Quy trình):
- Đối với `sp_KPIgetDataCollection`:
  + Thay đổi logic lọc cho `@activeStatus = 3` để dùng `LastTimeContact` (kết nối với bảng `tblCRM_NotesHistory` để lấy ngày tương tác) thay vì `CreatedDate`.
  + Bổ sung từ khoá `DISTINCT` khi SELECT vào `#tmpData1` nhằm loại bỏ các dòng bị trùng lặp do kết quả của phép JOIN với `tblCRM_CustomerOwner`.
  + Loại bỏ điều kiện bắt buộc `PhoneNumber IS NOT NULL` khi đếm KPI trạng thái để đồng nhất với Dashboard.
- Đối với giao diện `sp_KPIListDataCollection_html` (Renderer của MnuKPI003):
  + Tiêm (inject) đoạn mã JavaScript đọc giá trị `window.EmployeeIDsKPI` (biến toàn cục từ Dashboard).
  + Tự động gán giá trị này vào `InstanceEmployeeIDPDF...` của form Data Collection Popup ngay khi khởi tạo (`setTimeout` trong phần `onContentReady` hoặc Toolbar Configure) để lọc đúng nhân viên mà Dashboard đang xem.
- Đối với quá trình Migrate (Chuyển đổi môi trường):
  + Các lệnh cập nhật SQL đã được chuẩn hoá sang dạng Idempotent (IF EXISTS / IF NOT EXISTS) để khi chạy vào Database khác (UAT / PROD) sẽ tự động cập nhật mà không báo lỗi hoặc trùng lặp.
  + Không dùng USE [DatabaseName] để đảm bảo an toàn.

3. Các file đính kèm:
- `Fix_CRM_Dashboard_Followup_sp_KPIgetDataCollection.sql`: Chứa script CREATE OR ALTER thủ tục lấy dữ liệu đã được sửa DISTINCT và Date Filtering.
- `migrate_menu_MnuKPI003.sql`: Chứa script chuẩn cập nhật lại UI (sp_KPIListDataCollection_html) và build lại cache Menu HTML an toàn, cho phép mang sang các Database khác để chạy ngay.
