# Hướng dẫn Fix Lỗi Dark Mode Bằng CSS Trong Các SQL Procedure (HTML/CSS/JS)

## Ngữ cảnh
Trong hệ thống, có nhiều giao diện (như Dashboard, Báo cáo) được sinh ra toàn bộ HTML, CSS và JavaScript từ bên trong các SQL Stored Procedure. Khi người dùng chuyển sang chế độ Dark Mode (chủ đề tối), các thành phần có hardcode màu sáng (ví dụ nền trắng, chữ xám đen) sẽ không tự đổi màu, gây ra lỗi chói mắt hoặc chữ không thể đọc được.

**Yêu cầu cốt lõi:**
1. Chỉ chỉnh sửa CSS / HTML classes để hỗ trợ Dark Mode.
2. Không làm hỏng hoặc ảnh hưởng giao diện hiện tại ở chế độ Light Mode.
3. Không can thiệp vào logic dữ liệu (SELECT, WHERE, JOIN...) hoặc Javascript nghiệp vụ.

## Cách tiếp cận

### 1. Xác định Class/Selector Trạng thái Dark Mode
Trước khi viết CSS, cần tìm xem HTML wrapper bên ngoài khi ở chế độ Dark Mode được gán class gì. Thường gặp trong dự án:
- `.dark-mode` (được gán ở `body` hoặc `html`)
- `[data-bs-theme="dark"]` (bootstrap 5)
- `.dx-theme-generic-dark`, `.dx-theme-material-dark` (nếu dùng DevExtreme)

*Kiểm tra file CSS hiện tại trong procedure xem đang dùng selector nào cho các xử lý dark mode (nếu có).*

### 2. Nguyên tắc viết CSS Override (Ghi đè an toàn)

Không thay đổi trực tiếp thuộc tính màu của các class cơ bản. Phải **tạo một khối CSS riêng biệt** (thường đặt ở cuối thẻ `<style>`) kết hợp selector Dark Mode và ID container chính của giao diện.

**Ví dụ một khối CSS an toàn:**
```css
/* --- BỔ SUNG DARK MODE OVERRIDES --- */
.dark-mode #MyDashboardContainer .card,
[data-bs-theme="dark"] #MyDashboardContainer .card {
  background: #242a32 !important; /* Ghi đè màu nền trắng sang xám tối */
  border-color: rgba(255, 255, 255, 0.08) !important;
}

.dark-mode #MyDashboardContainer .text-primary,
[data-bs-theme="dark"] #MyDashboardContainer .text-primary {
  color: #f1f5f9 !important; /* Đổi màu chữ tối sang màu sáng để dễ đọc */
}
```

*Tại sao phải dùng ID Container (`#MyDashboardContainer`)?*
Để đảm bảo style này là **scoped** (chỉ có tác dụng bên trong màn hình được sinh bởi procedure đó), không rò rỉ ra ngoài ảnh hưởng các màn hình khác của hệ thống.

*Tại sao dùng `!important`?*
Vì đôi khi thẻ HTML có chứa inline-style (`style="background: white"`) hoặc các thư viện ngoài (như DevExtreme) sinh ra inline-style đè lên class. Việc dùng `!important` kết hợp với `.dark-mode` sẽ ép hiển thị đúng khi ở giao diện tối, mà hoàn toàn không kích hoạt nếu đang ở Light Mode.

### 3. Các thành phần thường cần Override trong Dark Mode
- **Background của Box/Card/Panel:** Đang để `#fff` -> nên đổi thành `#1f242b`, `#242a32` hoặc `#252b33`.
- **Màu chữ (Text/Label):** Đang để các màu tối như `#475569`, `#64748b`, `#333` -> nên đổi sang `#9ca3af`, `#aab3c2` hoặc `#f1f5f9`.
- **Border:** Đang để `rgba(0,0,0, 0.1)` -> đổi thành `rgba(255,255,255, 0.08)`.
- **Hover effects:** Hover đang dùng nền sáng/đen -> đổi sang `rgba(255, 255, 255, 0.1)`.

### 4. Quy trình xử lý (Dành cho AI Agent hoặc Developer)
1. Dùng tool đọc code procedure (VD: qua SSMS, hoặc dùng MCP SQL Server `OBJECT_DEFINITION`).
2. Tìm các đoạn `<style>` và xác định các class gây trắng nền.
3. Soạn thảo khối CSS Override áp dụng mẫu kết hợp selector `.dark-mode`.
4. Tìm vị trí `</style>` cuối cùng trong biến sinh HTML và chèn khối CSS Override vào ngay phía trên nó.
5. Sinh lệnh `CREATE OR ALTER PROCEDURE` để lưu lại (lưu ý không dùng `DROP PROCEDURE`).
6. Kiểm tra lại cẩn thận xem mã CSS mới đã có ID bao bọc an toàn chưa.

*Cập nhật lần cuối: Tháng 06/2026*
