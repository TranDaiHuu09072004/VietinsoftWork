# Agent Skill: SQL Procedure Responsive CSS Only

Áp dụng khi sửa responsive UI cho các thủ tục HTML dạng `*_html` của Vietinsoft.

## Mục tiêu
- Chỉ sửa giao diện responsive trong thủ tục hiện tại.
- Không đổi cấu trúc thủ tục, flow xử lý, query, API, stored procedure gọi bên trong, tên biến, tên hàm, dữ liệu đầu vào/đầu ra.
- Không tạo thủ tục mới, không viết lại theo UI mẫu, không refactor kiến trúc.

## Quy trình bắt buộc
1. Đọc đúng source thủ tục hiện tại từ attachment hoặc database.
2. Liệt kê ngắn các vùng liên quan trước khi sửa:
   - Tên thủ tục `dbo.<procedure>_html`.
   - Root DOM id.
   - Grid/table/list chính.
   - Toolbar/search/filter/button.
   - Form/modal/popup nếu có.
3. Tìm CSS hiện có trong:
   - Block `<style>...</style>` của HTML.
   - Các block JavaScript chỉ chứa CSS như `document.createElement("style")` hoặc `.textContent = \`...\``.
4. Chỉ chỉnh CSS cần thiết:
   - `width`, `min-width`, `max-width`.
   - `height`, `min-height`, `max-height`.
   - `overflow`, `overflow-x`, `overflow-y`.
   - `display`, `flex`, `grid`, `gap`, `wrap`.
   - `padding`, `margin`, `font-size`, `line-height`.
   - breakpoint cho desktop/tablet/mobile.
5. Với table/list dài:
   - Ưu tiên scroll ngang trong vùng grid/table.
   - Không làm mất cột, không đổi dữ liệu, không đổi query.
6. Với form/input/select/button:
   - Đảm bảo không tràn, không chồng lên nhau trên màn hình nhỏ.
7. Với modal/popup:
   - Đảm bảo `max-width/max-height` theo viewport.
   - Nội dung có scroll khi vượt chiều cao màn hình.
8. Xuất script theo đúng source thủ tục sau khi sửa:
   - Giữ nguyên thân thủ tục và logic.
   - Nếu có attachment full procedure thì tạo file SQL full procedure từ attachment đó.
   - Không dùng dynamic patch từ `sys.sql_modules` khi người dùng đã gửi source đầy đủ.
9. Thêm lệnh cache cuối script khi phù hợp:
   - `EXEC sptblCommonControlType_Signed_DUC '<procedure>_html';`
   - `EXEC sp_GenerateHTMLScript_new '<procedure>_html';`
   - `EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'<procedure_without_html>';`
10. Sau khi sửa, báo rõ:
   - File đã sửa/tạo.
   - CSS responsive đã chỉnh ở khu vực nào.
   - Không thay đổi phần nào ngoài CSS.

## Breakpoint chuẩn
- Mobile: khoảng `375px`, dùng `@media (max-width: 480px)`.
- Tablet: khoảng `768px`, dùng `@media (max-width: 768px)`.
- Desktop nhỏ/tablet ngang: khoảng `1024px`, dùng `@media (max-width: 1024px)`.

## Điều cấm
- Không đổi JavaScript xử lý nghiệp vụ.
- Không đổi Ajax/API endpoint.
- Không đổi SQL query hoặc stored procedure backend.
- Không đổi tên biến, tên hàm, tên DOM id nếu không bắt buộc.
- Không dựng lại UI theo ảnh mẫu.
- Không tạo script stub hoặc script khác cấu trúc khi đã có source thủ tục đầy đủ.
