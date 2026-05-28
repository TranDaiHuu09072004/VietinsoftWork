# 13 — Skill: Migrate / Update menu ParadiseHR

> Dùng khi user yêu cầu: "tạo script update/migrate cho menu X", "copy giao diện menu X sang hệ thống mới", "update UI/ngôn ngữ/quyền menu X".
>
> Mục tiêu: từ **tên menu** / `MenuID` / `ClassName` → query DB → inventory đầy đủ → sinh script SQL **idempotent**.
>
> Liên quan: [07](07_menu_system.md) nền · [11](11_permissions.md) quyền · [12](12_CreateMenu.md) tạo mới · [14](14_ParadiseStyle.md) UI · [17](17_RendererHtmlJsSafe.md) renderer · [18](18_FindMenuProcedure.md) lookup menu→proc · [99](99_deprecated.md) lỗi thời.

## Mục lục

1. [6 Quy tắc bắt buộc](#1-6-quy-tắc-bắt-buộc)
2. [Khi nào dùng + Checklist đầu vào](#2-khi-nào-dùng--checklist-đầu-vào)
3. [Quy trình 5 Phase](#3-quy-trình-5-phase)
4. [Template idempotent từng thành phần](#4-template-idempotent-từng-thành-phần)
5. [Skeleton script migrate full](#5-skeleton-script-migrate-full)
6. [Workflow Agent + Checklist QA + Câu trả lời mẫu](#6-workflow-agent--checklist-qa--câu-trả-lời-mẫu)

---

## 1. 6 Quy tắc bắt buộc

### Rule 1 — Cấp quyền: CHỈ LoginID = 3

- ✅ `INSERT tblSC_Right_Stored(ObjectID, LoginID=3, FullAccess='32')` — chỉ admin.
- ❌ **KHÔNG** gọi `sp_UpdateMenuInUserRight` (tự cấp `FullAccess=32` cho **MỌI** LoginID > 0 → mở quyền toàn hệ thống).
- ❌ **KHÔNG** xử lý `tblSC_GroupRight` trong script migrate. User/group khác: UI app hoặc script riêng.
- Phase refresh: CHỈ `EXEC sp_Men_Menu_AfterSave_Simple @ClassName=N'<ClassName>'`.
- Khi migrate "giữ nguyên quyền cũ": chỉ ghi LoginID=3 — giữ nguyên quyền DB đích.

### Rule 2 — Cờ Web HTML-rendered

Copy từ DB nguồn — **KHÔNG** tự "chuẩn hoá" sang `1` (sai lầm phổ biến):

| Cờ | Giá trị |
|---|---|
| `IsWeb` | `0` |
| `ViewOnWeb` | **`0`** |
| `isShowLayOutWeb` | **`0`** |
| `isShowInMobileLayOut` | **`0`** |
| `IsUseMobileDevice` | `1` |

### Rule 3 — Parent menu `IsVisible = 1`

Verify parent có `IsVisible=1` trước khi update `ParentMenuID`. Nếu giữ parent cũ vẫn check (cảnh báo nếu `IsVisible=0`). ❌ Tránh `MnuHEP000` (`IsVisible=0` ở DB thực tế).

### Rule 4 — BẮT BUỘC copy `tblDataSetting` + `tblDataSettingLayout` (+ `tblCommonControlType_Signed` nếu config-driven)

| Bảng | Yêu cầu | Khi nào |
|---|---|---|
| `tblDataSetting` | 1 row theo `TableName=<ClassName>` (`IsProcedure, IsShowLayout, ColumnOrderBy, ColumnDataType, ControlHiddenInShowLayout, FormLayoutJS`) | **Mọi** menu HTML-rendered |
| `tblDataSettingLayout` | **2 row** (`root` + `lblhtml`/ParadiseWebView2) | **Mọi** menu HTML-rendered |
| `tblHtmlScriptCache` | Build cache bằng `sp_GenerateHTMLScript` | **Mọi** menu HTML-rendered |
| `tblCommonControlType_Signed` | Full row metadata theo `TableName='<ClassName>_html'` với **UID deterministic** + EXEC `sptblCommonControlType_Signed_DUC '<ClassName>_html'` trước cache | Menu **config-driven** (renderer dynamic SQL — xem [12 §4](12_CreateMenu.md)) |

**Triệu chứng nếu thiếu:**
- Thiếu DataSetting/Layout → menu hiện trong cây + có quyền nhưng click → **màn hình trắng**.
- Thiếu `tblCommonControlType_Signed` (config-driven) → JS lỗi `InstanceXXX is not defined` / `window.getGridConfig_XXX is not a function`.

**Audit check:**
```sql
SELECT COUNT(*) AS ControlCount FROM tblCommonControlType_Signed
WHERE TableName = '<ClassName>_html';
-- > 0 → bắt buộc đưa metadata vào script
```

### Rule 5 — Renderer HTML/JS an toàn

Mọi script migrate/update có renderer `sp_X_html` → bắt buộc đọc [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md): escape T-SQL/JS, `varbinary(max)` của tblDataSetting/Layout (Msg 257), dynamic SQL config-driven, polyfill global, template + checklist 15 điểm. Cache build bằng `sp_GenerateHTMLScript` (cách DUY NHẤT), KHÔNG MERGE thủ công từ renderer.

### Rule 6 — Schema-aware idempotent (chống Msg 8106 và họ lỗi tương tự)

Script dùng `IF OBJECT_ID('dbo.X','U') IS NULL CREATE TABLE ...` → mọi thao tác phía sau phụ thuộc schema **BẮT BUỘC** defensively check schema thực tế ở DB đích (vì DB đích có thể đã có bảng với schema CŨ).

| Thao tác | Pattern defensive |
|---|---|
| `SET IDENTITY_INSERT dbo.X ON/OFF` | `IF COLUMNPROPERTY(OBJECT_ID('dbo.X'),'<col>','IsIdentity')=1 SET IDENTITY_INSERT ...` (lặp cho OFF) |
| `INSERT explicit ID` | Check IDENTITY trước; nếu không có IDENTITY thì INSERT không kèm cột ID |
| `ALTER COLUMN <type>` | Check `INFORMATION_SCHEMA.COLUMNS` trước; chỉ ALTER khi kiểu khác mong muốn |
| `ADD CONSTRAINT FK_X` | `IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_X')` |
| `ALTER TABLE ADD <col>` | `IF COL_LENGTH('dbo.X','<col>') IS NULL` |
| `CREATE INDEX IX_X` | `IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_X' AND object_id=OBJECT_ID('dbo.X'))` |
| `DROP CONSTRAINT DF_X` | `IF EXISTS (SELECT 1 FROM sys.default_constraints WHERE name='DF_X')` |

**Tiền lệ 2026-05-23** ([migrate_menu_ComplaintForm_20260523.sql](../SQL%20script/migrate_menu_ComplaintForm_20260523.sql)): PHASE 1 `IF OBJECT_ID IS NULL CREATE TABLE tblTask_ComplaintTypes (ComplaintTypeID int IDENTITY ...)`. DB đích đã có bảng với `ComplaintTypeID` KHÔNG IDENTITY → skip CREATE → PHASE 2 `SET IDENTITY_INSERT ON` raise **Msg 8106**. Fix: wrap `COLUMNPROPERTY(...,'IsIdentity')=1`.

Khi schema mismatch critical → RAISERROR thay vì silent skip:
```sql
IF OBJECT_ID('dbo.X','U') IS NOT NULL
   AND COLUMNPROPERTY(OBJECT_ID('dbo.X'),'<col>','IsIdentity') <> 1
    RAISERROR(N'Bảng X tồn tại nhưng <col> không phải IDENTITY. Align schema trước khi rerun.', 16, 1);
```

---

## 2. Khi nào dùng + Checklist đầu vào

### 2.1 Khi nào dùng file này

| User nói | Việc Agent làm |
|---|---|
| "update script cho menu X" | Tìm menu → đọc metadata/source hiện tại → script `UPDATE/MERGE` idempotent |
| "migrate menu X sang hệ thống mới" | Export đủ procedure + metadata + quyền + ngôn ngữ sang script |
| "update giao diện web menu X" | CHỈ renderer + cache + layout (nếu metadata không đổi) |
| "copy phân quyền menu X" | Theo Rule 1: script CHỈ cấp LoginID=3. Quyền user/group khác → script riêng |
| "đảm bảo ngôn ngữ khi migrate" | Lấy label từ `tblMD_Message` nguồn, dùng `dbo.[1rename_Mess]` / MERGE |

❌ **KHÔNG** dùng file này khi tạo menu mới từ đầu (không có nguồn) → [12_CreateMenu.md](12_CreateMenu.md).

### 2.2 Nguyên tắc bắt buộc

1. KHÔNG đoán `MenuID`/`ClassName`/proc/cột — phải query DB hoặc đọc Knowledge.
2. Check [99_deprecated.md](99_deprecated.md) trước khi dùng/đề xuất item.
3. KHÔNG tự chạy DDL/DML — chỉ tạo file SQL trong `SQL script/` cho user review.
4. Mọi query đọc DB phải có `TOP N` / `WHERE`.
5. Script phải idempotent — chạy nhiều lần không sinh trùng + không lỗi object đã tồn tại.
6. KHÔNG dùng `.aspx` (đã lỗi thời) — Web hiện dùng HTML-rendered (wrapper/renderer/cache/ParadiseWebView2).
7. Tên đa ngôn ngữ lấy từ `tblMD_Message` — không hard-code.
8. Quyền map qua `tblSC_Object.Description = MenuID` — không suy `ObjectID`.

### 2.3 Thông tin đầu vào

| Thông tin | Bắt buộc | Cách lấy |
|---|---|---|
| Tên menu VN/EN | ✓ | User cung cấp hoặc `tblMD_Message.Content` |
| `MenuID` | ✓ | Query `tblMD_Message` + `MEN_Menu` |
| Hệ thống nguồn/đích | tuỳ | User cung cấp |
| Script update / migrate full | ✓ | Nếu chưa rõ → mặc định migrate full |
| Migrate quyền | mặc định: CHỈ LoginID=3 | Rule 1 — không hỏi user |

Quy trình lookup menu→procedure 5 bước (xử lý case 0 match / nhiều match / `ClassName` là VIEW / không có `_html`): [18_FindMenuProcedure.md](18_FindMenuProcedure.md).

---

## 3. Quy trình 5 Phase

### Phase A — Tìm menu nguồn

**Theo tên VN:**
```sql
DECLARE @Keyword nvarchar(200) = N'Quản lý bài học';
SELECT TOP 50 msg.MessageID AS MenuID, msg.Language, msg.Content,
       m.ParentMenuID, m.ClassName, m.AssemblyName,
       m.IsVisible, m.IsWeb, m.ViewOnWeb, m.isShowLayOutWeb, m.IsUseMobileDevice, m.URL
FROM tblMD_Message msg
LEFT JOIN MEN_Menu m ON m.MenuID = msg.MessageID
WHERE msg.Content LIKE N'%' + @Keyword + N'%'
ORDER BY msg.MessageID, msg.Language;
```

| Kết quả | Xử lý |
|---|---|
| 0 dòng | Báo không tìm thấy, query thêm `MEN_Menu.ClassName` — không đoán |
| 1 `MenuID` | Dùng làm nguồn |
| Nhiều | Liệt kê ngắn + hỏi user chọn |
| Có `MessageID` không có `MEN_Menu` | Message orphan — không dùng nếu user chưa xác nhận |

**Theo `MenuID` / `ClassName`:** `SELECT * FROM MEN_Menu WHERE MenuID=... / ClassName=...`.

### Phase B — Inventory đầy đủ

```sql
DECLARE @MenuID varchar(100) = 'MnuXXX';

-- 1. Metadata
SELECT TOP 1 * FROM MEN_Menu WHERE MenuID = @MenuID;
-- 2. Object phân quyền
SELECT TOP 10 * FROM tblSC_Object WHERE Description = @MenuID;
-- 3. Đa ngôn ngữ
SELECT * FROM tblMD_Message WHERE MessageID = @MenuID ORDER BY Language;
-- 4. DataSetting
SELECT TOP 20 ds.* FROM tblDataSetting ds JOIN MEN_Menu m
 ON LOWER(ds.TableName)=LOWER(m.ClassName) OR LOWER(ds.ViewName)=LOWER(m.ClassName)
WHERE m.MenuID = @MenuID;
-- 5. Layout
SELECT TOP 100 l.* FROM tblDataSettingLayout l JOIN MEN_Menu m
 ON LOWER(l.TableName)=LOWER(m.ClassName)
WHERE m.MenuID = @MenuID
ORDER BY l.TableName, l.ControlName;
-- 6. HTML cache
SELECT c.TableName, c.LanguageID, c.ScreenType,
       DATALENGTH(c.html) AS HtmlBytes, c.Version
FROM tblHtmlScriptCache c JOIN MEN_Menu m ON c.TableName = m.ClassName + '_html'
WHERE m.MenuID = @MenuID
ORDER BY c.TableName, c.LanguageID;
```

### Phase C — Xác định loại menu + phạm vi migrate

| Dấu hiệu | Loại menu | Cần migrate |
|---|---|---|
| `AssemblyName='DataSetting'`, có `sp_X_html` + `tblHtmlScriptCache` | Web HTML-rendered | wrapper + renderer + API JS gọi + cache + metadata + layout + quyền + ngôn ngữ |
| `AssemblyName='DataSetting'`, `ClassName` là view/table/proc, có `tblDataSetting` | DataSetting grid/list | view/proc data + `tblDataSetting` + layout + metadata + quyền + ngôn ngữ |
| `AssemblyName='SuperForm'` | SuperForm | `Menu_FrameSetting` + metadata + quyền + ngôn ngữ + source |
| `AssemblyName` dạng `HPA.*` | Form .NET viết tay | metadata + quyền + ngôn ngữ (source .NET ngoài DB) |
| `URL` trỏ `.aspx` | Lỗi thời | KHÔNG migrate — chuyển sang HTML-rendered |

### Phase D — Tìm wrapper + renderer

Quy ước: với `ClassName = sp_X`: Wrapper = `sp_X`; Renderer = `sp_X_html`; Cache key = `'sp_X_html'`.

```sql
DECLARE @ClassName sysname = 'sp_X';
SELECT name, type_desc, create_date, modify_date FROM sys.objects WHERE name IN (@ClassName, @ClassName+'_html');
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.'+@ClassName))         AS WrapperSrc;
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.'+@ClassName+'_html')) AS RendererSrc;
```

Wrapper chuẩn:
```sql
CREATE PROCEDURE dbo.sp_X (@LoginID INT, @LanguageID VARCHAR(5)='VN')
AS BEGIN SET NOCOUNT ON;
    SELECT TOP 1 html FROM dbo.tblHtmlScriptCache
    WHERE TableName='sp_X_html' AND ScreenType='-1' AND LanguageID=@LanguageID;
END
```

Nếu wrapper khác pattern này — đọc source + giữ logic, không tự đơn giản hoá.

### Phase E — Tìm API JS gọi

Trong source renderer, tìm keywords: `AjaxHPAParadise`, `sp_`, `openFormParam`, `OpenFormParamMobile`, `paradisefile_`, `GetFileAPI`.

```sql
-- Tìm proc cùng họ:
SELECT TOP 100 o.name, o.type_desc, o.modify_date FROM sys.objects o
WHERE o.type='P' AND o.name LIKE 'sp_X%' ORDER BY o.name;

-- Tìm proc nhắc trong source:
SELECT TOP 100 o.name FROM sys.sql_modules sm JOIN sys.objects o ON o.object_id=sm.object_id
WHERE sm.definition LIKE N'%AjaxHPAParadise%';

-- Export source:
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_X_GetData')) AS Source;
```

| Loại proc | Vào script migrate? |
|---|---|
| Wrapper `sp_X` / Renderer `sp_X_html` / API `sp_X_GetData` | ✓ |
| Proc dùng chung toàn hệ thống | Chỉ nếu DB đích chưa có — ghi chú rõ |
| Proc refresh (`sp_Men_Menu_AfterSave_Simple`...) | KHÔNG — chỉ EXEC sau migrate |

### Phase F — Lấy ngôn ngữ + quyền

**Ngôn ngữ** — KHÔNG hard-code, lấy từ `tblMD_Message` nguồn:
```sql
SELECT MessageID, Language, Content FROM tblMD_Message WHERE MessageID = @MenuID ORDER BY Language;
```

| Tình huống | Xử lý |
|---|---|
| Có VN, thiếu EN | Dùng VN cho EN + ghi comment |
| Có EN, thiếu VN | Dùng EN cho VN + ghi comment |
| Thiếu cả 2 | KHÔNG tự đặt — hỏi user |

**Quyền** — lấy `ObjectID` nguồn + (đọc tham khảo) quyền cá nhân/group:
```sql
SELECT TOP 10 ObjectID, ObjectName, Description, Visible, ParentObjectID
FROM tblSC_Object WHERE Description = @MenuID;
-- Script migrate CHỈ ghi LoginID=3 (Rule 1) — không copy quyền user/group khác.
```

### Phase G — Build script idempotent

**Đặt tên:** `SQL script/migrate_menu_<TenNgan>_<YYYYMMDD>.sql` hoặc `update_menu_*`.

**Header bắt buộc:**
```sql
-- ============================================================================
-- File   : SQL script/migrate_menu_<scope>_<YYYYMMDD>.sql
-- Mục đích: Migrate/update menu <Tên> (<MenuID>) ParadiseHR.
-- Nguồn  : Xác minh từ MEN_Menu, tblSC_Object, tblMD_Message, tblDataSetting,
--          tblDataSettingLayout, tblHtmlScriptCache, source procedure.
-- Cảnh báo: USER tự review + chạy. Agent KHÔNG tự thực thi. BACKUP DB trước.
-- Idempotent: chạy nhiều lần không trùng dữ liệu.
-- ============================================================================
SET NOCOUNT ON; SET XACT_ABORT ON;
GO
```

**Thứ tự block:**

| # | Block | Transaction? | Ghi chú |
|---|---|---|---|
| 1 | DROP/CREATE proc API runtime | ❌ (cần GO) | |
| 2 | DROP/CREATE renderer `sp_X_html` | ❌ | |
| 3 | DROP/CREATE wrapper `sp_X` | ❌ | |
| 4 | Metadata: `MEN_Menu`, `tblSC_Object`, `tblMD_Message`, `tblDataSetting`, `tblDataSettingLayout`, quyền | ✓ TRY/TRAN | |
| 4b | `tblCommonControlType_Signed` nếu config-driven | ✓ TRY/TRAN | EXEC `sptblCommonControlType_Signed_DUC '<class>_html'` sau insert metadata, **trước** cache |
| 5 | `EXEC sp_GenerateHTMLScript 'sp_X_html'` | ✓ hoặc sau | CHỈ helper này — không gọi renderer trực tiếp |
| 6 | COMMIT | ✓ | Rollback nếu lỗi |
| 7 | `EXEC sp_Men_Menu_AfterSave_Simple @ClassName=N'<ClassName>'` | ❌ | **CHỈ** lệnh này. ❌ KHÔNG `sp_UpdateMenuInUserRight` |
| 8 | Verify SELECT | ❌ | |

---

## 4. Template idempotent từng thành phần

### 4.1 Procedure (`CREATE OR ALTER` nếu DB hỗ trợ; else DROP+CREATE)

```sql
IF OBJECT_ID('dbo.sp_X', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_X;
GO
CREATE PROCEDURE dbo.sp_X (@LoginID INT, @LanguageID varchar(5)='VN')
AS BEGIN SET NOCOUNT ON;
    -- source đã xác minh
END
GO
PRINT '[OK] sp_X';
GO
```

Áp dụng tương tự cho `sp_X_html` + `sp_X_GetData`.

### 4.2 `tblHtmlScriptCache` — Build cache bằng `sp_GenerateHTMLScript` (cách DUY NHẤT)

KHÔNG MERGE thủ công từ renderer. Cache được build bởi helper hệ thống:

```sql
EXEC dbo.sp_GenerateHTMLScript @ProcName = N'sp_X_html';
```

`sp_GenerateHTMLScript` tự động gọi renderer cho VN + EN và MERGE vào `tblHtmlScriptCache` với đủ 8 cột. Renderer chỉ cần `SELECT @html AS html;` — không tự MERGE.

### 4.3 `MEN_Menu` — IF NOT EXISTS INSERT ELSE UPDATE

```sql
IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = @MenuID)
    INSERT INTO MEN_Menu
        (MenuID, ClassName, AssemblyName, ParentMenuID, Priority,
         IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb, IsUseMobileDevice, isShowInMobileLayOut,
         glyphicon, GroupID,
         /* + nhiều cột notnull (IsModal, LinkMenuID, IsCollapsed, ShortcutKeys, SupperAdmin,
            LargeTile, Colors, superForm, DefaultParam, Notification, URL, IsNotAjax,
            InstructionID, showDialog, ProcessDataForNotifyProc, ClassName_Audit, ClassName_CT,
            Showinsuperform, Activity, Separation, MobileDeviceGroup, PriorityMobileDevice,
            IsLeftMenu, NotUsePlatform, OptionAuthentication, IconBackColor, IconForeColor,
            isParentMenu, ParentMenuMobileID, IsHiddenInTree) — defaults ''/0 */)
    VALUES (@MenuID, @ClassName, @AssemblyName, @ParentMenuID, @Priority,
            1, @IsWeb, @ViewOnWeb, @IsShowLayOutWeb, @IsUseMobileDevice, @IsShowInMobileLayOut,
            @Glyphicon, @GroupID, /* + defaults */);
ELSE
    UPDATE MEN_Menu
       SET ClassName=@ClassName, AssemblyName=@AssemblyName, ParentMenuID=@ParentMenuID,
           Priority=@Priority, IsVisible=1, IsWeb=@IsWeb, ViewOnWeb=@ViewOnWeb,
           isShowLayOutWeb=@IsShowLayOutWeb, IsUseMobileDevice=@IsUseMobileDevice,
           isShowInMobileLayOut=@IsShowInMobileLayOut, glyphicon=@Glyphicon, GroupID=@GroupID
     WHERE MenuID = @MenuID;
```

### 4.4 `tblSC_Object`

```sql
DECLARE @ObjectID int, @ParentObjectID int;
SELECT TOP 1 @ParentObjectID = ObjectID FROM tblSC_Object WHERE Description = @ParentMenuID;
IF @ParentObjectID IS NULL SET @ParentObjectID = 1;

IF NOT EXISTS (SELECT 1 FROM tblSC_Object WHERE Description = @MenuID)
BEGIN
    SET @ObjectID = ISNULL((SELECT MAX(ObjectID) FROM tblSC_Object), 0) + 1;
    INSERT INTO tblSC_Object (ObjectID, ObjectName, Description, Visible, ParentObjectID, ParentObjectRightID, ParentRight)
    VALUES (@ObjectID, @ObjectName, @MenuID, 1, @ParentObjectID, 0, 0);
END
ELSE BEGIN
    UPDATE tblSC_Object SET ObjectName=@ObjectName, Visible=1, ParentObjectID=@ParentObjectID
     WHERE Description = @MenuID;
    SELECT TOP 1 @ObjectID = ObjectID FROM tblSC_Object WHERE Description = @MenuID;
END
```

### 4.5 `tblMD_Message` — Helper hoặc MERGE

```sql
EXEC dbo.[1rename_Mess] @MenuID, 'VN', @NameVN;
EXEC dbo.[1rename_Mess] @MenuID, 'EN', @NameEN;
```

Nhiều language → MERGE:
```sql
MERGE tblMD_Message AS tgt
USING (SELECT @MenuID AS MessageID, 'VN' AS Language, @NameVN AS Content) AS src
   ON tgt.MessageID=src.MessageID AND tgt.Language=src.Language
WHEN MATCHED THEN UPDATE SET tgt.Content = src.Content
WHEN NOT MATCHED BY TARGET THEN INSERT (MessageID, Language, Content) VALUES (src.MessageID, src.Language, src.Content);
```

### 4.6 `tblDataSetting` + `tblDataSettingLayout`

Query schema thực tế trước khi viết block:
```sql
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='tblDataSetting' ORDER BY ORDINAL_POSITION;
```

Logic:
- `tblDataSetting`: key `TableName=@ClassName OR ViewName=@ClassName` — IF EXISTS UPDATE ELSE INSERT.
- `tblDataSettingLayout`: KHÔNG `DELETE` toàn bộ — MERGE từng control theo key (`TableName+ControlName` đã xác minh). HTML-rendered cần control `ParadiseWebView2` với `ControlName='html'`.

```sql
MERGE dbo.tblDataSettingLayout AS tgt
USING (SELECT LOWER(@ClassName) AS TableName, 'lblhtml' AS ControlName,
              'ParadiseWebView2' AS ControlType, 'html' AS FieldName, 100 AS WidthPercentage) AS src
ON LOWER(tgt.TableName)=src.TableName AND tgt.ControlName=src.ControlName
WHEN MATCHED THEN UPDATE SET tgt.ControlType=src.ControlType, tgt.FieldName=src.FieldName, tgt.WidthPercentage=src.WidthPercentage
WHEN NOT MATCHED BY TARGET THEN INSERT (TableName, ControlName, ControlType, FieldName, WidthPercentage)
                                VALUES (src.TableName, src.ControlName, src.ControlType, src.FieldName, src.WidthPercentage);
```

> Danh sách cột thực tế phải query trước — template chỉ minh hoạ logic MERGE.

### 4.7 `tblSC_Right_Stored` — CHỈ LoginID=3 (Rule 1)

```sql
DECLARE @AdminLoginID INT = 3, @FullAccess NVARCHAR(10) = N'32';
IF NOT EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID=@ObjectID AND LoginID=@AdminLoginID)
    INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@ObjectID, @AdminLoginID, @FullAccess);
ELSE
    UPDATE tblSC_Right_Stored SET FullAccess=@FullAccess WHERE ObjectID=@ObjectID AND LoginID=@AdminLoginID;
```

### 4.8 `tblSC_GroupRight` — KHÔNG xử lý trong script migrate (Rule 1)

User/group khác → UI app hoặc script riêng (Agent build tách riêng, không trộn).

### 4.9 Seed master data với schema-aware IDENTITY_INSERT (Rule 6)

```sql
-- Bảng + IDENTITY mong muốn
IF OBJECT_ID('dbo.tblTask_ComplaintTypes','U') IS NULL
    CREATE TABLE dbo.tblTask_ComplaintTypes (
        ComplaintTypeID     int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ComplaintTypeName   nvarchar(255) NOT NULL,
        ComplaintTypeNameEN nvarchar(255) NULL );
GO

-- Seed: wrap IDENTITY_INSERT bằng COLUMNPROPERTY (Rule 6).
-- Lý do: DB đích có thể đã có bảng với cột PK KHÔNG IDENTITY → SET sẽ raise Msg 8106.
IF COLUMNPROPERTY(OBJECT_ID('dbo.tblTask_ComplaintTypes'),'ComplaintTypeID','IsIdentity')=1
    SET IDENTITY_INSERT dbo.tblTask_ComplaintTypes ON;
GO

MERGE dbo.tblTask_ComplaintTypes AS tgt
USING (VALUES (1, N'Gia hạn thời gian hoàn thành', N'Extend Deadline'),
              (2, N'Khiếu nại từ chối duyệt',      N'Appeal Rejection'))
   AS src(ComplaintTypeID, ComplaintTypeName, ComplaintTypeNameEN)
   ON tgt.ComplaintTypeID = src.ComplaintTypeID
WHEN MATCHED THEN UPDATE SET tgt.ComplaintTypeName=src.ComplaintTypeName, tgt.ComplaintTypeNameEN=src.ComplaintTypeNameEN
WHEN NOT MATCHED BY TARGET THEN INSERT (ComplaintTypeID, ComplaintTypeName, ComplaintTypeNameEN)
                                VALUES (src.ComplaintTypeID, src.ComplaintTypeName, src.ComplaintTypeNameEN);
GO

IF COLUMNPROPERTY(OBJECT_ID('dbo.tblTask_ComplaintTypes'),'ComplaintTypeID','IsIdentity')=1
    SET IDENTITY_INSERT dbo.tblTask_ComplaintTypes OFF;
GO
```

Schema mismatch critical → RAISERROR (xem Rule 6).

---

## 5. Skeleton script migrate full

> Agent thay placeholder bằng giá trị đã query từ DB nguồn — không tự bịa.

```sql
-- ============================================================================
-- File: SQL script/migrate_menu_<scope>_<YYYYMMDD>.sql
-- Mục đích: Migrate menu <Tên> (<MenuID>) ParadiseHR.
-- Cảnh báo: USER review + chạy. BACKUP DB trước. Idempotent.
-- ============================================================================
SET NOCOUNT ON; SET XACT_ABORT ON;
GO

-- PHASE 1: API procedures
IF OBJECT_ID('dbo.sp_X_GetData','P') IS NOT NULL DROP PROCEDURE dbo.sp_X_GetData;
GO
CREATE PROCEDURE dbo.sp_X_GetData (@LoginID int, @LanguageID varchar(5)='VN')
AS BEGIN SET NOCOUNT ON; /* source đã xác minh */ END
GO

-- PHASE 2: Renderer (chỉ SELECT @html AS html — cache do sp_GenerateHTMLScript build)
IF OBJECT_ID('dbo.sp_X_html','P') IS NOT NULL DROP PROCEDURE dbo.sp_X_html;
GO
CREATE PROCEDURE dbo.sp_X_html (@LoginID int=3, @LanguageID varchar(5)='VN', @isWeb int=1)
AS BEGIN SET NOCOUNT ON;
    DECLARE @html nvarchar(max) = N'<!-- HTML/CSS/JS đã xác minh -->';

    SELECT @html AS html;
END
GO

-- PHASE 3: Wrapper
IF OBJECT_ID('dbo.sp_X','P') IS NOT NULL DROP PROCEDURE dbo.sp_X;
GO
CREATE PROCEDURE dbo.sp_X (@LoginID int, @LanguageID varchar(5)='VN')
AS BEGIN SET NOCOUNT ON;
    SELECT TOP 1 html FROM dbo.tblHtmlScriptCache
    WHERE TableName='sp_X_html' AND ScreenType='-1' AND LanguageID=@LanguageID;
END
GO

-- PHASE 4: Metadata + language + permission
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @MenuID varchar(100) = 'MnuXXX';
    DECLARE @ParentMenuID varchar(100) = 'MnuPARENT';
    DECLARE @ClassName varchar(100) = 'sp_X';
    DECLARE @AssemblyName varchar(100) = 'DataSetting';
    DECLARE @ObjectName varchar(200) = @AssemblyName + '.' + @ClassName;
    DECLARE @NameVN nvarchar(200) = N'<từ tblMD_Message>';
    DECLARE @NameEN nvarchar(200) = N'<từ tblMD_Message>';
    DECLARE @Priority int = 99, @Glyphicon nvarchar(100) = N'Info';
    DECLARE @GroupID varchar(100) = @ParentMenuID;
    DECLARE @IsWeb int=0, @ViewOnWeb int=0, @IsShowLayOutWeb int=0,
            @IsUseMobileDevice int=1, @IsShowInMobileLayOut int=0;
    DECLARE @AdminLoginID int=3, @FullAccess nvarchar(10)=N'32';

    -- MEN_Menu: IF NOT EXISTS INSERT ELSE UPDATE (§4.3)
    -- tblSC_Object: IF NOT EXISTS INSERT ELSE UPDATE (§4.4)
    -- tblMD_Message: EXEC dbo.[1rename_Mess] (§4.5)
    -- tblDataSetting/Layout: MERGE (§4.6)
    -- tblSC_Right_Stored: chỉ LoginID=3 (§4.7)
    -- Nếu config-driven: + tblCommonControlType_Signed + EXEC sptblCommonControlType_Signed_DUC

    EXEC dbo.sp_GenerateHTMLScript 'sp_X_html';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT '[ERROR] Line '+CAST(ERROR_LINE() AS varchar(10))+': '+ERROR_MESSAGE();
    THROW;
END CATCH
GO

-- PHASE 5: Refresh menu cache (CHỈ 1 lệnh — Rule 1)
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_X';
GO
-- ❌ KHÔNG sp_UpdateMenuInUserRight (vi phạm Rule 1)

-- VERIFY
DECLARE @MenuID varchar(100) = 'MnuXXX';
SELECT m.MenuID, m.ClassName, m.AssemblyName, m.ParentMenuID, m.Priority,
       m.IsVisible, m.IsWeb, m.ViewOnWeb, m.isShowLayOutWeb, m.IsUseMobileDevice,
       o.ObjectID, o.ObjectName,
       msgVN.Content AS NameVN, msgEN.Content AS NameEN,
       (SELECT COUNT(*) FROM tblSC_Right_Stored WHERE ObjectID = o.ObjectID) AS RightStoredRows,
       (SELECT COUNT(*) FROM tblSC_GroupRight WHERE ObjectID = o.ObjectID) AS GroupRightRows,
       (SELECT COUNT(*) FROM tblHtmlScriptCache WHERE TableName = m.ClassName + '_html') AS HtmlCacheLangs
FROM MEN_Menu m
LEFT JOIN tblSC_Object o ON o.Description = m.MenuID
LEFT JOIN tblMD_Message msgVN ON msgVN.MessageID = m.MenuID AND msgVN.Language='VN'
LEFT JOIN tblMD_Message msgEN ON msgEN.MessageID = m.MenuID AND msgEN.Language='EN'
WHERE m.MenuID = @MenuID;
GO
```

### Diagnostic verify

| Dấu hiệu | Ý nghĩa / Fix |
|---|---|
| `MEN_Menu` không có dòng | Script chưa insert/update đúng `MenuID` |
| `tblSC_Object` null | Quyền không map — sửa block object |
| `NameVN/NameEN` null | Thiếu `tblMD_Message` — sửa block language |
| `HtmlCacheLangs = 0` | Renderer chưa build cache hoặc sai `TableName` |
| `RightStoredRows = 0` và `GroupRightRows = 0` | User có thể không thấy menu (không có quyền override) |

---

## 6. Workflow Agent + Checklist QA + Câu trả lời mẫu

### 6.1 Workflow Agent (9 bước)

| # | Bước | Việc làm |
|---|---|---|
| 1 | Đọc Knowledge bắt buộc | INDEX, 99_deprecated, file này; nếu cần: 07, 11 |
| 2 | Tìm menu DB | `tblMD_Message.Content LIKE N'%<Tên>%'` / `MEN_Menu.MenuID/ClassName` |
| 3 | Nhiều menu trùng tên | Trả danh sách (`MenuID, Content, ClassName, ParentMenuID`) → hỏi user |
| 4 | Inventory menu | Phase B — 6 query: `MEN_Menu`, `tblSC_Object`, `tblMD_Message`, `tblDataSetting`, `tblDataSettingLayout`, `tblHtmlScriptCache` (+ quyền) |
| 5 | Tìm source procedure | Wrapper + renderer + API (Phase D, E) |
| 6 | Xác định script cần sinh | label/lang / quyền / UI HTML / migrate full |
| 7 | Tạo file SQL trong `SQL script/` | Header rõ, TRY/TRAN, GO đúng chỗ. KHÔNG thực thi |
| 8 | Self-review idempotent (xem 6.2) | |
| 9 | Trả lời user (xem 6.3) | |

| User yêu cầu | Script sinh |
|---|---|
| Label/ngôn ngữ | CHỈ `tblMD_Message` / `dbo.[1rename_Mess]` + verify |
| Quyền | `tblSC_Object` nếu thiếu + `tblSC_Right_Stored` (LoginID=3) + refresh |
| UI HTML | renderer `sp_X_html` + build cache + verify |
| Migrate full | API + renderer + wrapper + metadata + layout + cache + quyền + refresh + verify |

### 6.2 Checklist QA (16 điểm)

- [ ] `MenuID` đã xác minh từ DB (không đoán).
- [ ] Check [99_deprecated.md](99_deprecated.md) — không dùng item lỗi thời.
- [ ] Label từ `tblMD_Message`.
- [ ] Đã đọc `MEN_Menu`: `ParentMenuID`, `ClassName`, `AssemblyName`, cờ Web/mobile.
- [ ] `tblSC_Object` có / tạo theo `Description=MenuID`.
- [ ] Có source wrapper + renderer (HTML-rendered) + API JS gọi.
- [ ] `tblHtmlScriptCache` build bằng `sp_GenerateHTMLScript` (KHÔNG MERGE thủ công từ renderer).
- [ ] `MEN_Menu` IF NOT EXISTS INSERT ELSE UPDATE.
- [ ] `tblSC_Object` không insert trùng.
- [ ] `tblSC_Right_Stored` key `(ObjectID, LoginID=3)` — KHÔNG xử lý `tblSC_GroupRight`.
- [ ] Transaction + rollback cho metadata block.
- [ ] `sp_Men_Menu_AfterSave_Simple @ClassName=N'<class>'` BẮT BUỘC truyền tham số. KHÔNG `sp_UpdateMenuInUserRight`.
- [ ] Có verify SELECT cuối script.
- [ ] KHÔNG tự thực thi script.
- [ ] Nếu config-driven: `tblCommonControlType_Signed` UID deterministic + EXEC `sptblCommonControlType_Signed_DUC` trước cache (Rule 4).
- [ ] **Schema-aware (Rule 6)**: mọi `SET IDENTITY_INSERT` wrap `COLUMNPROPERTY(...,'IsIdentity')=1`; `ALTER COLUMN` check kiểu hiện tại; `ADD CONSTRAINT FK` / `CREATE INDEX` / `ALTER TABLE ADD <col>` / `DROP CONSTRAINT DF_*` đều có guard `IF EXISTS`/`IF NOT EXISTS`/`COL_LENGTH IS NULL`.

### 6.3 Câu trả lời mẫu

```text
Đã tạo script [SQL script/migrate_menu_<scope>_<YYYYMMDD>.sql](../SQL%20script/migrate_menu_<scope>_<YYYYMMDD>.sql).

Nguồn xác minh:
- Menu: <MenuID> / <ClassName> từ MEN_Menu.
- Ngôn ngữ: tblMD_Message cho VN/EN.
- Phân quyền: tblSC_Object.Description=<MenuID>, tblSC_Right_Stored / tblSC_GroupRight.
- UI Web: wrapper <sp_X>, renderer <sp_X_html>, cache tblHtmlScriptCache.

Script idempotent cho MEN_Menu, tblSC_Object, tblMD_Message, tblHtmlScriptCache, quyền;
có refresh menu cache + verify cuối file.
User review + BACKUP DB trước khi chạy.
```
