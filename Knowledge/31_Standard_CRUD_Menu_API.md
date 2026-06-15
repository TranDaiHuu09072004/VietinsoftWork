# Quy chuẩn Vàng: Xây dựng CRUD Menu dùng 100% API Hệ thống ParadiseHR

> [!IMPORTANT]
> Đây là tiêu chuẩn bắt buộc khi Agent tạo mới một Menu Quản lý danh mục (Grid + Popup Thêm/Sửa/Xóa). KHÔNG được sử dụng các Proc Custom lắt nhắt như `sp_..._Save`, `sp_..._Delete`. Mọi thứ phải dùng API động của hệ thống!

## 1. Kiến trúc Hệ thống

Một Menu Quản lý chuẩn bao gồm 4 thành phần (viết chung vào 1 file SQL duy nhất theo thứ tự):

1. **Cấp quyền (Permissions)**: Thông luồng `FullAccess = '32'` từ Menu Gốc -> Menu Cha -> Menu Con -> Popup Sửa bằng `MERGE`.
2. **Đăng ký Metadata (tblCommonControlType_Signed)**: Khai báo cấu hình Cột (Columns) cho Grid và Input cho Popup.
3. **Thủ tục _GetData**: Hàm bắt buộc để trả về dữ liệu cho Grid (hỗ trợ phân trang/tìm kiếm động qua `sp_LoadGridUsingAPI`).
4. **Thủ tục _html**: Hàm vẽ HTML + CSS + Javascript. Sử dụng `hpaControlEngine` và gọi `saveFunction`, `sp_SaveDeleteTableDataDynamic`.

## 2. Lưu ý Tử Huyệt (Critical Gotchas)

### 2.1. SumNumber trong hàm saveFunction()
Khi gọi `saveFunction(dataJSON, idValsJSON)` để Thêm/Sửa dữ liệu:
- `SumNumber` TRONG dataJSON **KHÔNG PHẢI** là mã hash của bảng vật lý.
- `SumNumber` CHÍNH LÀ **Mã Hash của tên Form (`TableName` trong `tblCommonControlType_Signed`)**.
- Ví dụ: Bảng cấu hình ghi `TableName = 'sp_CRM_EditKPIType_html'`, thì `SumNumber` phải là `CHECKSUM('sp_CRM_EditKPIType_html')`. Agent phải tính ra giá trị số nguyên này và nhúng cứng vào code Javascript.

### 2.2. Xóa dữ liệu (Delete)
Thay vì gọi `saveFunction`, nút Xóa phải gọi hàm `sp_SaveDeleteTableDataDynamic` thông qua AJAX:
```javascript
var objData = [
    { Name: "Type", Value: 2 }, // 2 = DELETE
    { Name: "SumNumber", Value: "-449283488" }, // Giống hệt SumNumber của saveFunction
    { Name: "KPI_ID", Value: currentRecordID } // Khóa chính
];
```

### 2.3. Lỗi Cú Pháp JS trong T-SQL
Biến `@html` thường dùng `N'...'` (nháy đơn). Tuyệt đối **KHÔNG** dùng nháy đơn `'` trong các comment `//` của đoạn Javascript nằm trong chuỗi SQL, nếu không SQL Server sẽ báo lỗi `Incorrect syntax` và thủ tục sẽ bị hủy cập nhật, dẫn tới trình duyệt vẫn gọi bản code lỗi. Luôn dùng dấu `\` để escape hoặc dùng nháy đơn kép `''`.

### 2.4. Phân Quyền Xuyên Suốt (Hierarchy Permissions)
Menu bị ẩn thường do Menu Cha bị cấm. Luôn luôn phải có đoạn Script `MERGE INTO dbo.tblSC_Right_Stored` duyệt qua cả 3 cấp: Gốc (Ví dụ: `MnuKPI000`), Cha (`MnuKPI030`), Con (`MnuKPI051`) để đảm bảo không mắt xích nào bị nghẽn.

## 3. Quy trình Generate Code (Script Template)

1. Mở Transaction.
2. Xóa Cache HTML cũ: `DELETE FROM dbo.tblHtmlScriptCache WHERE TableName IN (...)`
3. Cấp quyền bằng `MERGE INTO tblSC_Right_Stored` cho chuỗi Menu (ví dụ cho các user đặc biệt: 3, 8, 23, 50).
4. `DELETE FROM tblCommonControlType_Signed` -> `INSERT INTO tblCommonControlType_Signed` cho Grid (`TableName = 'sp_..._html'`) và Popup (`TableName = 'sp_..._Edit_html'`).
5. `CREATE OR ALTER PROCEDURE sp_..._GetData`
6. `CREATE OR ALTER PROCEDURE sp_..._html` (Vẽ giao diện Grid DevExpress).
7. `CREATE OR ALTER PROCEDURE sp_..._Edit_html` (Vẽ Popup Edit & Javascript Thêm/Sửa/Xóa chuẩn API).
8. **BẮT BUỘC Ở CUỐI FILE**:
   ```sql
   EXEC dbo.sptblCommonControlType_Signed_DUC 'sp_..._html';
   EXEC dbo.sptblCommonControlType_Signed_DUC 'sp_..._Edit_html';
   EXEC dbo.sp_GenerateHTMLScript 'sp_..._html';
   EXEC dbo.sp_GenerateHTMLScript 'sp_..._Edit_html';
   ```
