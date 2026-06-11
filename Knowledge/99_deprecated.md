# 99 — Dữ liệu lỗi thời / không dùng (DEPRECATED REGISTRY)

> **File này liệt kê các bảng, cột, procedure, view, menu, tham số đã được user xác nhận là LỖI THỜI / KHÔNG DÙNG NỮA trong hệ thống ParadiseHR thực tế.**
>
> Agent BẮT BUỘC đọc file này trước khi dùng bất kỳ tri thức nào liên quan đến các item ở dưới. Nếu một item nằm trong danh sách này:
> 1. **KHÔNG** dùng nó để trả lời / hướng dẫn user.
> 2. **KHÔNG** đề xuất nó như giải pháp.
> 3. Nếu user hỏi trực tiếp về item đó → trả lời rằng item đã được đánh dấu lỗi thời (kèm lý do nếu có) và hỏi user muốn tiếp tục hay không.

---

## Cách dùng file này

### Khi Agent thấy item bị user phủ nhận

User phản hồi đại loại: *"cái đó không dùng nữa"* / *"thực tế không có"* / *"đã bỏ lâu rồi"* / *"loại bỏ kiến thức này"* → Agent ghi vào đúng bảng bên dưới theo loại item (bảng / cột / procedure / view / menu / parameter).

Mỗi entry tối thiểu phải có:
- **Tên item** (giữ nguyên tên gốc tiếng Anh).
- **Loại**: table / column / procedure / view / menu / parameter / other.
- **Lý do** (theo lời user, ngắn gọn).
- **File Knowledge nguồn**: file đã ghi sai (để Agent biết phải xoá khỏi đó nếu cần).
- **Date marked** (YYYY-MM-DD).

### Khi user yêu cầu XOÁ item khỏi database

Agent **KHÔNG** được tự gọi `write_query` / `drop_table` / `alter_table` để xoá.

Thay vào đó:
1. Tạo file SQL script trong folder `SQL script/` đặt tên dạng `cleanup_<scope>_<YYYYMMDD>.sql` (vd: `cleanup_obsolete_procedures_20260519.sql`).
2. Trong script: dùng `DROP PROCEDURE IF EXISTS` / `DROP VIEW IF EXISTS` / `DROP TABLE IF EXISTS` cho từng item, có comment giải thích từng dòng.
3. **KHÔNG thực thi** — đưa cho user tự review và chạy.
4. Cập nhật cột "Cleanup script" trong bảng dưới đây trỏ tới đường dẫn file script.

Mẫu cấu trúc file cleanup script (xem mục [Mẫu script cleanup](#mẫu-script-cleanup) ở cuối file).

---

## 1. Bảng (tables) lỗi thời

| Tên bảng | Lý do | File Knowledge nguồn | Date marked | Cleanup script |
|---|---|---|---|---|
| _(chưa có)_ | | | | |

## 2. Cột (columns) lỗi thời

| Bảng.Cột | Lý do | File Knowledge nguồn | Date marked | Cleanup script |
|---|---|---|---|---|
| _(chưa có)_ | | | | |

## 3. Stored procedure lỗi thời

| Tên procedure | Lý do | File Knowledge nguồn | Date marked | Cleanup script |
|---|---|---|---|---|
| sp_CompanySalarySummary | Đã lỗi thời, không còn sử dụng (bao gồm các hậu tố: `_BeforeLoad`, `_Debug`, `_EMC`, `_Export01`, `_html`, `_STD`, `_view`) | | 2026-05-26 | [SQL script/cleanup_obsolete_procedures_20260526.sql](../SQL%20script/cleanup_obsolete_procedures_20260526.sql) |

## 4. View / function lỗi thời

| Tên | Loại | Lý do | File Knowledge nguồn | Date marked | Cleanup script |
|---|---|---|---|---|---|
| _(chưa có)_ | | | | | |

## 5. Menu (`MEN_Menu`) lỗi thời

Toàn bộ menu Web **kiểu ASPX-style** (URL trỏ tới file `.aspx`) đã được user xác nhận **không còn sử dụng** (xem [mục 7](#7-khác-tri-thức--mapping--quy-tắc-lỗi-thời) cho tri thức tổng quát). Danh sách MenuID còn sót trong DB:

### 5.1 Menu ASPX trong `MEN_Menu`

| MenuID | URL ASPX | ParentMenuID | IsVisible | Lý do | File Knowledge nguồn | Date marked | Cleanup script |
|---|---|---|---|---|---|---|---|
| `MnuAtt1` | `/ATT/LeaveHistory.aspx` | `MnuWebATT` (orphan) | 1 | Kiểu ASPX đã lỗi thời | [07_menu_system.md §9](07_menu_system.md) | 2026-05-20 | [SQL script/cleanup_menu_aspx_20260520.sql](../SQL%20script/cleanup_menu_aspx_20260520.sql) |
| `MnuAtt3` | `/ATT/LeaveSummary1.aspx` | `MnuWebATT` (orphan) | 1 | Kiểu ASPX đã lỗi thời | [07_menu_system.md §9](07_menu_system.md) | 2026-05-20 | [SQL script/cleanup_menu_aspx_20260520.sql](../SQL%20script/cleanup_menu_aspx_20260520.sql) |
| `MnuEmployeeInfo` | `/EmpInfo.aspx` | `MnuWebHRM` (orphan) | 1 | Kiểu ASPX đã lỗi thời | [07_menu_system.md §9](07_menu_system.md) | 2026-05-20 | [SQL script/cleanup_menu_aspx_20260520.sql](../SQL%20script/cleanup_menu_aspx_20260520.sql) |
| `MnuPRL1` | `/PRL/Payslip.aspx` | `MnuWebPRL` (orphan) | 1 | Kiểu ASPX đã lỗi thời | [07_menu_system.md §9](07_menu_system.md) | 2026-05-20 | [SQL script/cleanup_menu_aspx_20260520.sql](../SQL%20script/cleanup_menu_aspx_20260520.sql) |
| `MnuATTAppOT` | `/ATT/ApprovalOTList.aspx` | `MnuWebATT` (orphan) | 0 | Kiểu ASPX đã lỗi thời | [07_menu_system.md §13.3](07_menu_system.md) | 2026-05-20 | [SQL script/cleanup_menu_aspx_20260520.sql](../SQL%20script/cleanup_menu_aspx_20260520.sql) |
| `MnuATTOTRe` | `/ATT/OTRegistration.aspx` | `MnuWebATT` (orphan) | 0 | Kiểu ASPX đã lỗi thời | [07_menu_system.md §9](07_menu_system.md) | 2026-05-20 | [SQL script/cleanup_menu_aspx_20260520.sql](../SQL%20script/cleanup_menu_aspx_20260520.sql) |

### 5.2 Parent menu orphan trong `tblMD_Message` (KHÔNG còn record trong `MEN_Menu`)

| MessageID | Mô tả | Tồn tại ở | Lý do | Date marked | Cleanup script |
|---|---|---|---|---|---|
| `MnuWebATT` | Quản lý chấm công | `tblMD_Message` (VN) | Parent của menu ASPX, đã xoá khỏi `MEN_Menu` từ trước; chỉ còn label sót | 2026-05-20 | [SQL script/cleanup_menu_aspx_20260520.sql](../SQL%20script/cleanup_menu_aspx_20260520.sql) |
| `MnuWebHRM` | Nhân viên | `tblMD_Message` (VN) | Parent của menu ASPX, đã xoá khỏi `MEN_Menu` từ trước; chỉ còn label sót | 2026-05-20 | [SQL script/cleanup_menu_aspx_20260520.sql](../SQL%20script/cleanup_menu_aspx_20260520.sql) |
| `MnuWebPRL` | Lương / Salary | `tblMD_Message` (VN + EN) | Parent của menu ASPX, đã xoá khỏi `MEN_Menu` từ trước; chỉ còn label sót | 2026-05-20 | [SQL script/cleanup_menu_aspx_20260520.sql](../SQL%20script/cleanup_menu_aspx_20260520.sql) |

> ✅ **Đã xác minh** tại thời điểm 2026-05-20: KHÔNG có entry nào trong `tblSC_Object`, `tblSC_Right_Stored`, `tblSC_GroupRight` cho 6 menu ASPX trên — nghĩa là cleanup chỉ cần đụng `MEN_Menu` và `tblMD_Message`.
>
> ℹ️ Script cleanup cũ [cleanup_menu_obsolete_20260520.sql](../SQL%20script/cleanup_menu_obsolete_20260520.sql) chỉ xử lý `MnuATTAppOT` + `MnuWebATT`. Script mới [cleanup_menu_aspx_20260520.sql](../SQL%20script/cleanup_menu_aspx_20260520.sql) mở rộng phạm vi sang **toàn bộ menu ASPX-style**, idempotent (chạy được kể cả khi script cũ đã xoá một phần).

## 6. Tham số (`tblParameter`) / cấu hình lỗi thời

| Code / Setting | Lý do | File Knowledge nguồn | Date marked | Cleanup script |
|---|---|---|---|---|
| _(chưa có)_ | | | | |

## 7. Khác (tri thức / mapping / quy tắc) lỗi thời

| Mô tả tri thức sai | Lý do | File Knowledge nguồn | Date marked |
|---|---|---|---|
| **Kiểu menu Web "Web page cố định ASPX"** (`MEN_Menu.IsWeb = 1`, `URL` trỏ trực tiếp tới file `.aspx`) | User xác nhận: ParadiseHR hiện **chỉ dùng một kiểu duy nhất** cho menu Web là **HTML-rendered** (cặp procedure `sp_X` wrapper + `sp_X_html` renderer + cache trong `tblHtmlScriptCache`). Mọi menu kiểu ASPX cũ đã được thay thế và cần dọn dẹp khỏi DB. | [07_menu_system.md §9 + §13.3](07_menu_system.md) (đã cập nhật) | 2026-05-20 |

---

## Mẫu script cleanup

```sql
-- File: SQL script/cleanup_<scope>_<YYYYMMDD>.sql
-- Mục đích: Xoá các item đã được user xác nhận lỗi thời ngày <YYYY-MM-DD>.
-- Cảnh báo: User TỰ REVIEW và CHẠY. Agent KHÔNG thực thi tự động.
-- Khuyến nghị: BACKUP database trước khi chạy.

SET NOCOUNT ON; SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- Xoá procedure lỗi thời
    IF OBJECT_ID('dbo.sp_OldProc', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.sp_OldProc;
        PRINT 'Dropped procedure: sp_OldProc';
    END

    -- Xoá view lỗi thời
    IF OBJECT_ID('dbo.vOldView', 'V') IS NOT NULL
    BEGIN
        DROP VIEW dbo.vOldView;
        PRINT 'Dropped view: vOldView';
    END

    -- Xoá menu lỗi thời (kèm các bảng liên quan để không vỡ FK)
    DELETE FROM tblSC_Right_Stored WHERE ObjectID IN (
        SELECT ObjectID FROM tblSC_Object WHERE Description = 'MnuOldXXX'
    );
    DELETE FROM tblSC_GroupRight WHERE ObjectID IN (
        SELECT ObjectID FROM tblSC_Object WHERE Description = 'MnuOldXXX'
    );
    DELETE FROM tblSC_Object WHERE Description = 'MnuOldXXX';
    DELETE FROM tblMD_Message WHERE MessageID = 'MnuOldXXX';
    DELETE FROM MEN_Menu WHERE MenuID = 'MnuOldXXX';
    PRINT 'Dropped menu: MnuOldXXX';

    -- Xoá tham số lỗi thời
    DELETE FROM tblParameter WHERE Code = 'OLD_SETTING_CODE';
    PRINT 'Dropped parameter: OLD_SETTING_CODE';

    -- Xoá cột lỗi thời
    IF COL_LENGTH('dbo.tblXXX', 'OldColumn') IS NOT NULL
    BEGIN
        ALTER TABLE dbo.tblXXX DROP COLUMN OldColumn;
        PRINT 'Dropped column: tblXXX.OldColumn';
    END

    -- Xoá bảng lỗi thời (cuối cùng — sau khi đã handle FK)
    IF OBJECT_ID('dbo.tblOld', 'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.tblOld;
        PRINT 'Dropped table: tblOld';
    END

    COMMIT TRANSACTION;
    PRINT 'Cleanup completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    THROW;
END CATCH
GO
```

> Lưu ý khi build script:
> - Luôn bọc trong `BEGIN TRANSACTION ... COMMIT/ROLLBACK` để rollback được nếu lỗi giữa chừng.
> - Luôn dùng `IF OBJECT_ID(...) IS NOT NULL` / `IF COL_LENGTH(...) IS NOT NULL` để idempotent (chạy nhiều lần không lỗi).
> - Với menu: xoá đúng thứ tự `tblSC_Right_Stored` / `tblSC_GroupRight` → `tblSC_Object` → `tblMD_Message` → `MEN_Menu` để tránh vỡ FK / orphan.
> - Với bảng có FK đến bảng khác: xoá child trước, parent sau.
> - Khuyến cáo backup trước khi chạy.
