# 13 — Skill: Migrate / Update menu ParadiseHR

> Dùng khi cần tạo script update/migrate menu, chuyển giao diện sang database mới, hoặc cập nhật UI/ngôn ngữ.
> Liên quan: [07_menu_system.md](07_menu_system.md) (nền) · [12_CreateMenu.md](12_CreateMenu.md) (tạo mới) · [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) (JS escaping).

---

## 1. 8 Quy tắc bắt buộc khi viết Script Migration

### Rule 1 — Quyền hạn
* **Chỉ cấp cho admin (`LoginID = 3`)**: `INSERT tblSC_Right_Stored(ObjectID, LoginID = 3, FullAccess = '32')`.
* **CẤM** gọi `sp_UpdateMenuInUserRight` (Tránh cấp quyền tràn lan).
* **Refresh**: Chỉ gọi `EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>'`.

### Rule 2 — Cờ Menu HTML-rendered
Copy chính xác từ DB nguồn, tránh tự ý thay đổi cờ. Cờ chuẩn: `IsWeb = 0, ViewOnWeb = 0, isShowLayOutWeb = 0/1, isShowInMobileLayOut = 0, IsUseMobileDevice = 1`.

### Rule 3 — Parent Menu
Kiểm tra xem parent menu có `IsVisible = 1` ở DB đích không. Tránh `MnuHEP000`.

### Rule 4 — Bắt buộc di chuyển Metadata
Bên cạnh các stored procedure, script di chuyển phải bao gồm dữ liệu cấu hình trong các bảng:
* `tblDataSetting` (bản ghi cấu hình của ClassName).
* `tblDataSettingLayout` (bản ghi layout root + lblhtml).
* `tblCommonControlType_Signed` (nếu là menu config-driven, kèm theo chạy SP DUC).

### Rule 5 — Renderer an toàn
Tuân thủ [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md). Cache phải được build bằng `sp_GenerateHTMLScript` (CẤM insert cache thủ công).

### Rule 6 — Thiết kế Script Idempotent an toàn về Schema
Để tránh lỗi biên dịch (Ví dụ: **Msg 8106** khi chạy `SET IDENTITY_INSERT` trên cột không phải IDENTITY của DB đích), bắt buộc sử dụng cơ chế bảo vệ:
* **IDENTITY Check**:
  ```sql
  IF COLUMNPROPERTY(OBJECT_ID('dbo.tblTask_ComplaintTypes'), 'ComplaintTypeID', 'IsIdentity') = 1
      SET IDENTITY_INSERT dbo.tblTask_ComplaintTypes ON;
  ```
* **Thêm cột**: `IF COL_LENGTH('dbo.X', 'ColName') IS NULL ALTER TABLE dbo.X ADD ColName ...`
* **Thêm FK/Constraint**: `IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Name') ...`
* **Thêm Index**: `IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Name' AND object_id = OBJECT_ID('dbo.X')) ...`

### Rule 7 — CẤM dùng `USE [Database]`
Tên database có thể khác nhau giữa các server (Dev, Test, Prod).
* **KHÔNG** viết lệnh `USE [Paradise_Dev]` hoặc `USE [$(Database)]`.
* Người dùng tự chọn Database trong SSMS trước khi chạy.
* Chỉ cần đặt `SET NOCOUNT ON; SET XACT_ABORT ON; GO` ở đầu script.

### Rule 8 — Kèm đầy đủ `tblMD_Message` cho các Placeholder `%...%`
Mọi placeholder đa ngôn ngữ dùng trên UI (ví dụ `%Zalo%`, `%OwnerID%`) phải có bản dịch đầy đủ trong `tblMD_Message` ở cả VN và EN. Nếu thiếu, màn hình sẽ hiển thị text thô dạng `%OwnerID%`.

---

## 2. Quy trình 4 bước di chuyển (Agent Workflow)

### Bước 1: Khảo sát & Inventory nguồn
Chạy các truy vấn tìm kiếm thông tin của MenuID trên DB nguồn:
* `MEN_Menu`, `tblSC_Object`, `tblMD_Message`.
* `tblDataSetting` và `tblDataSettingLayout`.
* `tblHtmlScriptCache` (để kiểm tra kích thước cache).

### Bước 2: Quét Dependency (BẮT BUỘC)
Quét mã nguồn của renderer SP (`sp_X_html`) để lấy danh sách:
* Các stored procedure gọi qua `AjaxHPAParadise` (Ví dụ: `sp_X_GetData`).
* Các bảng nghiệp vụ liên quan bằng truy vấn:
  ```sql
  SELECT DISTINCT referenced_entity_name FROM sys.dm_sql_referenced_entities('dbo.sp_X_GetData', 'OBJECT');
  ```
* Mang theo tất cả các SP và Function nghiệp vụ này vào script di chuyển. Ghi chú rõ các bảng nghiệp vụ cần có sẵn.

### Bước 3: Tạo file Script di chuyển
Tạo file dạng `SQL script/migrate_menu_<scope>_<YYYYMMDD>.sql`. Bọc toàn bộ phần thay đổi metadata trong block `BEGIN TRANSACTION ... COMMIT TRANSACTION` và `TRY/CATCH` để tự động Rollback nếu lỗi.

### Bước 4: Refresh Cache và Kiểm thử
Chạy `sp_Men_Menu_AfterSave_Simple` sau khi chạy script để đồng bộ hệ thống.

---

## 3. Khung Script di chuyển chuẩn (Skeleton Script)

```sql
-- ============================================================================
-- File: SQL script/migrate_menu_<scope>_<YYYYMMDD>.sql
-- Mục đích: Migrate menu <Tên> (<MenuID>) ParadiseHR.
-- ============================================================================
SET NOCOUNT ON; SET XACT_ABORT ON;
GO

-- 1. DROP/CREATE các stored procedure nghiệp vụ/API
IF OBJECT_ID('dbo.sp_X_GetData','P') IS NOT NULL DROP PROCEDURE dbo.sp_X_GetData;
GO
CREATE PROCEDURE dbo.sp_X_GetData (@LoginID int, @LanguageID varchar(5)='VN')
AS BEGIN
    SET NOCOUNT ON;
    -- Code API nghiệp vụ ở đây
END
GO

-- 2. DROP/CREATE Renderer SP (chỉ SELECT html, không tự merge cache)
IF OBJECT_ID('dbo.sp_X_html','P') IS NOT NULL DROP PROCEDURE dbo.sp_X_html;
GO
CREATE PROCEDURE dbo.sp_X_html (@LoginID int=3, @LanguageID varchar(5)='VN', @isWeb int=1)
AS BEGIN
    SET NOCOUNT ON;
    DECLARE @html nvarchar(max) = N'<!-- HTML/CSS/JS chính -->';
    SELECT @html AS html;
END
GO

-- 3. DROP/CREATE Wrapper SP
IF OBJECT_ID('dbo.sp_X','P') IS NOT NULL DROP PROCEDURE dbo.sp_X;
GO
CREATE PROCEDURE dbo.sp_X (@LoginID int, @LanguageID varchar(5)='VN')
AS BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 html FROM dbo.tblHtmlScriptCache
    WHERE TableName='sp_X_html' AND ScreenType='-1' AND LanguageID=@LanguageID;
END
GO

-- 4. Cấu hình Metadata, Language và Permission (Bọc trong Transaction)
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @MenuID varchar(100) = 'MnuXXX';
    DECLARE @ClassName varchar(100) = 'sp_X';
    DECLARE @AssemblyName varchar(100) = 'DataSetting';
    DECLARE @ObjectName varchar(200) = @AssemblyName + '.' + @ClassName;

    -- A. Thêm hoặc cập nhật MEN_Menu
    IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = @MenuID)
        INSERT INTO MEN_Menu (MenuID, ClassName, AssemblyName, ParentMenuID, Priority, IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb, IsUseMobileDevice, isShowInMobileLayOut, glyphicon, GroupID)
        VALUES (@MenuID, @ClassName, @AssemblyName, 'MnuPARENT', 99, 1, 0, 0, 0, 1, 0, 'Info', 'MnuPARENT');
    ELSE
        UPDATE MEN_Menu SET ClassName=@ClassName, AssemblyName=@AssemblyName, IsVisible=1 WHERE MenuID=@MenuID;

    -- B. Thêm hoặc cập nhật tblSC_Object
    IF NOT EXISTS (SELECT 1 FROM tblSC_Object WHERE Description = @MenuID)
        INSERT INTO tblSC_Object (ObjectID, ObjectName, Description, Visible, ParentObjectID)
        VALUES ((SELECT ISNULL(MAX(ObjectID),0)+1 FROM tblSC_Object), @ObjectName, @MenuID, 1, 1);
    
    DECLARE @ObjectID int = (SELECT ObjectID FROM tblSC_Object WHERE Description=@MenuID);

    -- C. Thêm đa ngôn ngữ cho tên menu
    EXEC dbo.[1rename_Mess] @MenuID, 'VN', N'Tên tiếng Việt';
    EXEC dbo.[1rename_Mess] @MenuID, 'EN', 'Tên tiếng Anh';

    -- D. Cấu hình tblDataSetting và Layout (Xem Rule 4)
    -- E. Cấp quyền duy nhất cho LoginID = 3
    IF NOT EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID=@ObjectID AND LoginID=3)
        INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@ObjectID, 3, '32');

    -- F. Tải lại Cache HTML
    EXEC dbo.sp_GenerateHTMLScript 'sp_X_html';

    COMMIT TRANSACTION;
    PRINT '[SUCCESS] Migrate completed successfully!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT '[ERROR] Line '+CAST(ERROR_LINE() AS varchar(10))+': '+ERROR_MESSAGE();
    THROW;
END CATCH
GO

-- 5. Refresh cache hệ thống (Bên ngoài Transaction)
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_X';
GO
