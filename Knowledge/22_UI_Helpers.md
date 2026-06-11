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

---

## 3. Hàm chuẩn `normalize(v)` — Loại bỏ dấu tiếng Việt (ParadiseJS Standard)

> **Đây là standard library function của Paradise.** Mọi màn hình cần tìm kiếm/lọc tiếng Việt không dấu đều dùng hàm này.

### Source code (copy-paste vào mọi màn hình)

```js
/**
 * Loại bỏ dấu tiếng Việt, chuyển về chữ thường ASCII.
 * Tương đương fn_RemoveToneMark trong SQL.
 * @param {string} v - Chuỗi đầu vào
 * @returns {string} Chuỗi không dấu, lowercase
 */
const normalize = v => {
    var s = String(v || "").toLowerCase();
    // Fast-path: nếu đã thuần ASCII (0x20-0x7E) thì return ngay
    if (!/[^\x20-\x7E]/.test(s)) return s;
    var r = "";
    for (var i = 0; i < s.length; i++) {
        var c = s.charAt(i), d = c.normalize("NFD");
        r += d.length > 1 ? d.charAt(0) : c;
    }
    return r.replace(/\u0111/g, "d");
};
```

### Cách dùng

```js
// Search không dấu
var q = normalize(keyword);
data.forEach(item => {
    if (normalize(item.name).indexOf(q) >= 0) { /* match */ }
});

// Render data-text cho tree/grid search
var dataText = normalize(rawName); // "Quản trị Nhân sự" → "quan tri nhan su"
```

### Logic (so với SQL `fn_RemoveToneMark`)

| SQL | JS |
|-----|-----|
| `NOT LIKE N'%[^ -~]%' COLLATE Latin1_General_100_BIN2` | `!/[^\x20-\x7E]/.test(s)` |
| NFD decomposition | `c.normalize("NFD")` + `.charAt(0)` |
| `REPLACE(@InputStr, N'đ', N'd')` | `.replace(/\u0111/g, "d")` |
| `REPLACE(@InputStr, N'Đ', N'D')` | (đã `.toLowerCase()` trước) |

### Use cases

- **Tree filter/search**: `data-text="${normalize(name)}"`
- **Grid search**: normalize cả keyword và cell value trước khi `indexOf`
- **Auto-complete/suggestion**: normalize trước khi compare
- **Dashboard cross-filter**: normalize để match label không phân biệt dấu
