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
| _(chưa có)_ | | | | |

## 4. View / function lỗi thời

| Tên | Loại | Lý do | File Knowledge nguồn | Date marked | Cleanup script |
|---|---|---|---|---|---|
| _(chưa có)_ | | | | | |

## 5. Menu (`MEN_Menu`) lỗi thời

| MenuID | Mô tả | Lý do | File Knowledge nguồn | Date marked | Cleanup script |
|---|---|---|---|---|---|
| `MnuATTAppOT` | Duyệt tăng ca (`URL = /ATT/ApprovalOTList.aspx`, parent = `MnuWebATT`) — `IsVisible = 0` tại thời điểm verify | User xác nhận không còn dùng | _(chưa được ghi vào Knowledge nào)_ | 2026-05-20 | [SQL script/cleanup_menu_obsolete_20260520.sql](../SQL%20script/cleanup_menu_obsolete_20260520.sql) |
| `MnuWebATT` | Quản lý chấm công (orphan parent — KHÔNG còn record trong `MEN_Menu`, chỉ còn label VN trong `tblMD_Message`) | User xác nhận không còn dùng; cũng đã bị xoá khỏi `MEN_Menu` từ trước | _(chưa được ghi vào Knowledge nào)_ | 2026-05-20 | [SQL script/cleanup_menu_obsolete_20260520.sql](../SQL%20script/cleanup_menu_obsolete_20260520.sql) |

> ⚠️ **Lưu ý orphan**: sau khi xoá `MnuWebATT`, 3 menu sau vẫn còn `ParentMenuID = 'MnuWebATT'` → trở thành orphan (parent không tồn tại): `MnuAtt1`, `MnuAtt3`, `MnuATTOTRe`. User cần quyết định riêng — re-parent về menu hợp lệ hoặc xoá. Script `cleanup_menu_obsolete_20260520.sql` CHỈ in cảnh báo, không tự xử lý.

## 6. Tham số (`tblParameter`) / cấu hình lỗi thời

| Code / Setting | Lý do | File Knowledge nguồn | Date marked | Cleanup script |
|---|---|---|---|---|
| _(chưa có)_ | | | | |

## 7. Khác (tri thức / mapping / quy tắc) lỗi thời

| Mô tả tri thức sai | Lý do | File Knowledge nguồn | Date marked |
|---|---|---|---|
| _(chưa có)_ | | | |

---

## Mẫu script cleanup

```sql
-- File: SQL script/cleanup_<scope>_<YYYYMMDD>.sql
-- Mục đích: Xoá các item đã được user xác nhận lỗi thời ngày <YYYY-MM-DD>.
-- Cảnh báo: User TỰ REVIEW và CHẠY. Agent KHÔNG thực thi tự động.
-- Khuyến nghị: BACKUP database trước khi chạy.

USE [<DatabaseName>];
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
