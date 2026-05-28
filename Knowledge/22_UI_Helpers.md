---
name: ui-helpers
description: >
  Các hàm tiện ích giao diện chung (UI Helpers) của hệ thống Paradise: showAlert, showConfirmPopup.
  Sử dụng khi cần hiển thị thông báo thành công/lỗi hoặc hộp thoại xác nhận đồng ý/hủy bỏ.
---

# Paradise UI Helpers

> File này tài liệu hóa các hàm JS tiện ích toàn cục (Global UI Helpers) được tích hợp sẵn trong hệ thống Paradise để hiển thị thông báo alert hoặc popup xác nhận.

---

## 1. Hiển thị thông báo nhanh (`uiManager.showAlert`)

Sử dụng để hiển thị các toast notification thông báo kết quả hành động hoặc cảnh báo nhập liệu cho người dùng.

### Cú pháp
```javascript
uiManager.showAlert({
    type: "warning", // Các loại hỗ trợ: "success", "error", "warning" (hoặc "danger")
    message: "Nội dung thông báo cần hiển thị"
});
```

### Chi tiết các loại Alert Type:
- **`success`**: Sử dụng khi thao tác thành công (ví dụ: *"Lưu thành công!"*, *"Xóa thành công!"*).
- **`warning`**: Sử dụng khi cảnh báo validate dữ liệu (ví dụ: *"Vui lòng nhập Mã nhân viên và chọn ít nhất 1 nhóm phân quyền!"*).
- **`error` / `danger`**: Sử dụng khi gặp sự cố, lỗi kết nối hoặc lưu thất bại (ví dụ: *"Không thể kết nối đến máy chủ!"*).

---

## 2. Hộp thoại xác nhận (`showConfirmPopup`)

Sử dụng khi cần người dùng xác nhận lại trước khi thực hiện các hành động nguy hiểm hoặc không thể hoàn tác (như xóa dữ liệu, hủy bỏ tài liệu).

### Cú pháp
```javascript
if (typeof showConfirmPopup === "function") {
    showConfirmPopup({
        title: "Tiêu đề popup?",
        message: "Nội dung câu hỏi xác nhận?",
        YesText: "Nút Đồng ý", // Ví dụ: "Xóa", "Đồng ý"
        NoText: "Nút Hủy bỏ",   // Ví dụ: "Hủy", "Quay lại"

        onYes: () => {
            console.log("Người dùng chọn Đồng ý");
            // Gọi hàm nghiệp vụ thực tế ở đây
        },
        onNo: () => {
            console.log("Người dùng chọn Hủy bỏ");
            // Xử lý khi hủy bỏ (nếu có)
        }
    });
}
```

> [!WARNING]
> Luôn bọc ngoài cuộc gọi bằng kiểm tra điều kiện `typeof showConfirmPopup === "function"` để tránh gặp lỗi runtime JS trên các môi trường hoặc nền tảng cũ chưa cập nhật thư viện này.
