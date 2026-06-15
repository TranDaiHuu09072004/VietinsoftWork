# Prompt Chuẩn Sinh Code CRUD Menu (ParadiseHR)

> Copy nguyên đoạn bên dưới đưa cho Agent AI khi cần làm một Menu danh mục mới:

------------------------------------------------

Chào bạn, hôm nay chúng ta sẽ tạo một tính năng Quản lý danh mục mới trên hệ thống ParadiseHR.

**Yêu Cầu Bài Toán:**
- Bảng vật lý dưới CSDL: `[TÊN BẢNG]`, ví dụ: `tblCRM_KPICategories`
- Tên Menu trên UI: `[TÊN MENU HIỂN THỊ]`, ví dụ: `Quản lý loại KPI`
- Tên thủ tục (Menu Code): `sp_[MODULE]_[TÊN MENU]`, ví dụ: `sp_CRM_KPITypeManage`
- Menu Cha chứa tính năng này: `[MÃ MENU CHA]`, ví dụ: `MnuKPI030`
- Các cột cần quản lý trên Grid và Form: `[DANH SÁCH CỘT]`, ví dụ: `KPI_ID, KPI_Name, KPI_Name_EN`

**Quy Trình Bắt Buộc:**
Trước khi bắt đầu code, TÔI YÊU CẦU bạn phải làm điều này:
1. Đọc kỹ file tri thức gốc: `Knowledge/31_Standard_CRUD_Menu_API.md`
2. Làm đúng chuẩn "Gold Standard" ghi trong đó (chia làm _GetData, _html cho grid, và _Edit_html cho Popup).
3. Tuyệt đối dùng API Hệ thống (`saveFunction`, `sp_SaveDeleteTableDataDynamic`) để thực hiện lệnh Thêm/Sửa/Xóa. KHÔNG viết các Proc Custom (`sp_..._Save`, `sp_..._Delete`).
4. Khai báo `SumNumber` chuẩn xác bằng mã Hash (`CHECKSUM`) của `TableName` trong `tblCommonControlType_Signed`, KHÔNG LẤY MÃ HASH CỦA BẢNG VẬT LÝ!
5. Khi viết chuỗi Javascript nhúng trong T-SQL, tuyệt đối phải chú ý các dấu nháy đơn (') trong comment (VD: `// N'...'`) để không làm gãy lệnh SQL.
6. Thêm đoạn `MERGE INTO tblSC_Right_Stored` để cấp quyền thông luồng xuyên suốt từ Menu Gốc -> Menu Cha -> Menu Con cho các tài khoản `3, 8, 23, 50`.
7. Xuất ra 1 file script `.sql` duy nhất bao trọn gói mọi khâu (Xóa rác cũ -> Phân quyền -> Đăng ký Control -> Viết Proc -> Tạo Cache HTML cuối cùng).

Bây giờ bạn hãy viết script SQL hoàn chỉnh cho tính năng này giúp tôi!
