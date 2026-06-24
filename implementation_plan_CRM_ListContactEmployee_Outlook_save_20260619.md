# Kế hoạch cập nhật lưu Email cho `sp_CRM_ListContactEmployee`

## Mục tiêu

- Database đích: `Paradise_Dev`.
- Popup `sp_CRM_EditContactEmployee_html` dùng cùng luồng Microsoft Graph/Outlook như `sp_CRM_EmailKPIFollow_html`.
- Chỉ cập nhật `IsContact = 1` sau khi `sp_AddEmailProperty` trả `SUCCESS`.
- Xóa nút **Hủy bỏ** ở footer nhưng giữ dấu X đóng popup.
- Không thay đổi logic grid, tìm kiếm, phân trang, mobile và xóa nhân viên.

## Luồng lưu

1. Bắt buộc chọn `EmployeeID`.
2. Cho phép Email rỗng; nếu có Email thì kiểm tra định dạng.
3. Khóa nút Lưu để ngăn gửi lặp.
4. Gọi `sp_AddEmailProperty` với `EmployeeEmail`, `EmployeeID`, `FullName`.
5. Nếu Outlook thành công, gọi `saveContactEmployeeBySystem` để lưu `IsContact = 1`.
6. Đồng bộ grid, thông báo thành công và đóng popup.
7. Nếu bất kỳ bước nào lỗi, giữ popup mở, hiển thị lỗi và mở lại nút Lưu.

## File triển khai

- `SQL script/update_sp_CRM_ListContactEmployee_Outlook_save_20260619.sql`

Script:

- Backup source procedure trước khi patch.
- Chỉ patch `sp_CRM_EditContactEmployee_html`.
- Không sửa `sp_AddEmailProperty` hoặc `sp_CRM_EmailKPIFollow_html`.
- Rebuild metadata và HTML cache sau khi cập nhật.
- Sinh và kiểm tra cache theo tên wrapper `sp_CRM_EditContactEmployee` vì
  `sp_GenerateHTMLScript` tự bỏ hậu tố `_html`.
- Có các kiểm tra fail-fast và truy vấn verify cuối script.

## Kiểm thử chấp nhận

- Thêm mới và sửa Email hợp lệ đều đồng bộ Outlook rồi mới đặt `IsContact = 1`.
- Email không hợp lệ không gọi API.
- Email rỗng gỡ AutoBCC và vẫn giữ nhân viên trong danh sách kinh doanh.
- Outlook lỗi không cập nhật `IsContact` và popup không đóng.
- Nhấn Lưu liên tục chỉ tạo một request.
- Nút Hủy bỏ không còn, dấu X vẫn hoạt động.
- Luồng xóa vẫn đặt `IsContact = 0`.
- Toàn bộ thông báo tiếng Việt hiển thị đúng Unicode.
