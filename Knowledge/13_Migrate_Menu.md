# 13 — Skill: Quy trình migrate / update menu ParadiseHR

> **Skill file** — dùng khi user yêu cầu kiểu: "tạo script update cho menu Quản lý bài học", "viết script migrate menu Nhật ký công việc", "migrate giao diện menu X sang hệ thống mới", "update lại UI / phân quyền / ngôn ngữ của menu".
>
> Mục tiêu: Agent có thể đi từ **tên menu tiếng Việt** hoặc `MenuID` / `ClassName` → xác minh DB → tìm đủ procedure / layout / API / ngôn ngữ / quyền → tạo script SQL idempotent chạy nhiều lần không trùng dữ liệu.
>
> Liên quan: [07_menu_system.md](07_menu_system.md) (tri thức nền menu), [11_permissions.md](11_permissions.md) (phân quyền), [12_CreateMenu.md](12_CreateMenu.md) (tạo menu Web mới), [14_ParadiseStyle.md](14_ParadiseStyle.md) (chuẩn thiết kế UI — không thiết lập background cho menu), [99_deprecated.md](99_deprecated.md) (danh sách lỗi thời — bắt buộc check trước khi dùng item).

---

## ⚠️ 3 QUY TẮC BẮT BUỘC (đọc trước tiên)

### Rule 1 — Cấp quyền

Mọi script migrate/update menu **PHẢI** tuân thủ:

1. ✅ Chỉ `INSERT tblSC_Right_Stored(ObjectID, LoginID = 3, FullAccess = '32')`. **Không bao giờ** cấp cho LoginID khác / UserGroupID khác / tất cả user trong script migrate menu.
2. ❌ **TUYỆT ĐỐI KHÔNG** gọi `EXEC sp_UpdateMenuInUserRight @ObjectID = ...` trong script — proc này tự cấp `FullAccess = 32` cho **MỌI LoginID > 0** trong `tblSC_Login` → mở quyền menu cho toàn hệ thống.
3. ➡️ Sau khi script chạy, user tự cấp quyền cho user/group khác qua giao diện app, hoặc viết script riêng cho `tblSC_Right_Stored` / `tblSC_GroupRight`.
4. ✅ Phase refresh chỉ chạy `EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>'`.
5. ✅ Khi migrate, **giữ nguyên** quyền của user/group đã có sẵn ở DB nguồn nếu user nói "migrate quyền cũ"; còn nếu chỉ migrate UI/data thì **không đụng** các bảng quyền — chỉ đảm bảo LoginID = 3 có quyền.

### Rule 2 — Pattern cờ Web cho menu HTML-rendered

Khi migrate, **giữ đúng pattern cờ** từ menu HTML-rendered đang chạy thực tế (`MnuKPI007`, `MnuTM022`, `MnuWPT037`):

| Cờ | Giá trị BẮT BUỘC |
|---|---|
| `IsWeb` | `0` |
| `ViewOnWeb` | **`0`** (KHÔNG phải `1`) |
| `isShowLayOutWeb` | **`0`** |
| `isShowInMobileLayOut` | **`0`** |
| `IsUseMobileDevice` | `1` |

Khi migrate, **copy giá trị từ DB nguồn** — không tự "chuẩn hoá" sang `1` cho các cờ Web (sai lầm phổ biến).

### Rule 3 — Parent menu PHẢI `IsVisible = 1`

Khi đổi `ParentMenuID` của menu migrate (vd thay đổi cấu trúc cây):
- Verify parent mới có `IsVisible = 1` trước khi update.
- Nếu giữ nguyên parent: vẫn check để cảnh báo (nếu parent cũ `IsVisible = 0` thì menu sẽ không hiển thị sau migrate, dù dữ liệu khác đầy đủ).
- ❌ Tránh dùng `MnuHEP000` làm parent (có `IsVisible = 0` ở DB thực tế).

### Rule 4 — BẮT BUỘC copy `tblDataSetting` + `tblDataSettingLayout` (+ `tblCommonControlType_Signed` nếu là menu config-driven) khi migrate menu HTML-rendered

Khi migrate menu HTML-rendered từ DB nguồn sang đích, **bắt buộc copy đầy đủ các bảng metadata**:

| Bảng | Yêu cầu | Khi nào áp dụng |
|---|---|---|
| `tblDataSetting` | 1 dòng theo `TableName = <ClassName>`. Copy: `IsProcedure`, `IsShowLayout`, `ColumnOrderBy`, `ColumnDataType`, `ControlHiddenInShowLayout`, `FormLayoutJS`. | **Mọi** menu HTML-rendered |
| `tblDataSettingLayout` | Copy đủ **2 dòng** (`root` + `lblhtml`/ParadiseWebView2) theo `TableName = <ClassName>`. | **Mọi** menu HTML-rendered |
| `tblHtmlScriptCache` | Copy HTML cache hoặc chạy lại renderer sau migrate. | **Mọi** menu HTML-rendered |
| **`tblCommonControlType_Signed`** | Copy đầy đủ row metadata theo `TableName = '<ClassName>_html'` với **UID deterministic** (không random). Sau khi insert phải `EXEC sptblCommonControlType_Signed_DUC '<ClassName>_html'` để populate `html`/`loadUI`/`loadData` trước khi rebuild cache. | **Menu config-driven** — renderer dùng dynamic SQL `(SELECT loadUI FROM tblCommonControlType_Signed WHERE UID='...')` (vd `sp_CRM_Customers_html`, `sp_HelloWorldVietinsoft_html`). Xem [12_CreateMenu.md §3.1](12_CreateMenu.md). |

**Triệu chứng nếu thiếu**:
- Thiếu `tblDataSetting`/`tblDataSettingLayout`: menu xuất hiện trong cây + có quyền nhưng click vào → **màn hình trắng** (no content).
- Thiếu `tblCommonControlType_Signed` (menu config-driven): renderer build OK nhưng JS lỗi runtime **`InstanceXXX is not defined`** / `window.getGridConfig_XXX is not a function` → grid không render.

**Check audit trước khi viết script migrate**:

```sql
-- Check menu có dùng nhánh config-driven không
SELECT COUNT(*) AS ControlCount
FROM tblCommonControlType_Signed
WHERE TableName = '<ClassName>_html';
-- > 0 → bắt buộc đưa metadata này vào script migrate
```

### Rule 5 — Renderer HTML/JS phải an toàn (xem skill riêng)

Khi migrate/update renderer `sp_X_html`, **bắt buộc đọc** [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) — gồm: pattern escape quote boundary T-SQL/JS, xử lý cột `varbinary(max)` của `tblDataSetting`/`tblDataSettingLayout` (tránh lỗi Msg 257), pattern dynamic SQL `tblCommonControlType_Signed`, MERGE `tblHtmlScriptCache` 8 cột notnull, polyfill global helper, template copy-paste ready, và checklist 15 điểm trước khi export. **Đây là rule bắt buộc cho mọi script migrate/update menu có renderer.**

### Rule 6 — Schema-aware idempotent (chống Msg 8106 và họ lỗi tương tự)

Khi script dùng pattern `IF OBJECT_ID('dbo.X','U') IS NULL CREATE TABLE ... <schema mong muốn>`, **các thao tác phía sau phụ thuộc schema BẮT BUỘC defensively check schema thực tế ở DB đích**, không được giả định bảng đã có khớp schema vừa CREATE.

Lý do: DB đích có thể đã có bảng cùng tên với schema CŨ / KHÁC (từ migrate trước, từ phiên bản khác, từ developer tạo tay). Pattern `IF NULL CREATE` skip CREATE khi bảng đã tồn tại → schema cũ giữ nguyên → câu lệnh phía sau giả định IDENTITY / FK / cột mới → fail runtime.

**Pattern bắt buộc cho từng thao tác nhạy schema:**

| Thao tác | Pattern defensive bắt buộc |
|---|---|
| `SET IDENTITY_INSERT dbo.X ON/OFF` | `IF COLUMNPROPERTY(OBJECT_ID('dbo.X'), '<col>', 'IsIdentity') = 1 SET IDENTITY_INSERT dbo.X ON;` (lặp lại cho OFF) |
| `INSERT explicit ID khi cần` | Check IDENTITY trước; nếu không có IDENTITY thì INSERT không kèm cột ID (DB tự dùng default/manual) |
| `ALTER COLUMN <type>` | Check kiểu hiện tại qua `INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME=... AND COLUMN_NAME=...` trước khi đổi; chỉ ALTER khi kiểu khác mong muốn |
| `ADD CONSTRAINT FK_X` | `IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_X')` |
| `ALTER TABLE ADD <col>` | `IF COL_LENGTH('dbo.X','<col>') IS NULL ALTER TABLE dbo.X ADD <col> ...;` |
| `CREATE INDEX IX_X` | `IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_X' AND object_id=OBJECT_ID('dbo.X'))` |
| `DROP CONSTRAINT DF_X` | `IF EXISTS (SELECT 1 FROM sys.default_constraints WHERE name='DF_X')` |

**Tiền lệ ngày 2026-05-23** ([SQL script/migrate_menu_ComplaintForm_20260523.sql](../SQL%20script/migrate_menu_ComplaintForm_20260523.sql)): Script PHASE 1 `IF OBJECT_ID IS NULL CREATE TABLE tblTask_ComplaintTypes (ComplaintTypeID int IDENTITY ...)`. DB đích đã có bảng từ trước với cột `ComplaintTypeID` KHÔNG IDENTITY → skip CREATE → PHASE 2 `SET IDENTITY_INSERT ON` raise `Msg 8106 "Table does not have the identity property"`. Fix: `IF COLUMNPROPERTY(OBJECT_ID('dbo.tblTask_ComplaintTypes'), 'ComplaintTypeID', 'IsIdentity') = 1 SET IDENTITY_INSERT ...`.

**Cách xử lý triệt để hơn** (nếu schema khác biệt là vấn đề thực sự): script migrate có thể detect schema mismatch và RAISERROR yêu cầu user manually align schema, thay vì silent skip. Ví dụ:

```sql
IF OBJECT_ID('dbo.tblTask_ComplaintTypes','U') IS NOT NULL
   AND COLUMNPROPERTY(OBJECT_ID('dbo.tblTask_ComplaintTypes'),'ComplaintTypeID','IsIdentity') <> 1
BEGIN
    RAISERROR(N'Bảng tblTask_ComplaintTypes tồn tại nhưng ComplaintTypeID không phải IDENTITY. Script kỳ vọng IDENTITY — vui lòng align schema trước khi chạy.', 16, 1);
END
```


---

## 0. Khi nào bắt buộc dùng file này

Dùng file này nếu user yêu cầu một trong các việc sau:

| User nói | Việc Agent phải làm |
|---|---|
| "tạo script update cho menu Quản lý bài học" | Tìm menu theo tên trong `tblMD_Message`, xác định `MenuID`, đọc metadata/source hiện tại, tạo script `UPDATE/MERGE` idempotent |
| "viết script migrate menu Nhật ký công việc" | Tìm toàn bộ thành phần của menu nguồn, export/rebuild procedure + metadata + quyền + ngôn ngữ sang script migrate |
| "migrate giao diện menu X sang hệ thống mới" | Tạo script đầy đủ: procedure wrapper/renderer/API, `MEN_Menu`, `tblSC_Object`, `tblMD_Message`, `tblDataSetting`, `tblDataSettingLayout`, `tblHtmlScriptCache`, quyền |
| "update giao diện web menu X" | Chỉ update procedure renderer/cache/layout nếu metadata không đổi |
| "copy phân quyền menu X" | Theo rule cấp quyền: script migrate **chỉ** cấp cho LoginID = 3. Nếu user yêu cầu copy quyền cho user/group khác → Agent build **script riêng** (`tblSC_Right_Stored` / `tblSC_GroupRight`), tách khỏi script migrate menu. |
| "đảm bảo ngôn ngữ đúng khi migrate" | Lấy label từ `tblMD_Message` của menu nguồn, dùng `dbo.[1rename_Mess]` hoặc `MERGE` khi migrate |

Không dùng file này cho tạo menu mới từ đầu nếu không có menu nguồn; khi đó dùng [12_CreateMenu.md](12_CreateMenu.md).

---

## 1. Nguyên tắc bắt buộc trước khi làm

1. **Không đoán `MenuID`, `ClassName`, procedure, bảng, cột.** Phải query DB hoặc đọc Knowledge/source có chứng cứ.
2. **Luôn check [99_deprecated.md](99_deprecated.md)** trước khi dùng hoặc đề xuất bất kỳ item nào.
3. **Không tự chạy DDL/DML lên DB** nếu user chỉ yêu cầu tạo script. Chỉ tạo file SQL trong `SQL script/` để user review và chạy.
4. **Mọi query đọc DB phải giới hạn bằng `TOP N` / `WHERE`.**
5. **Script migrate phải idempotent**: chạy 1 lần, 2 lần, nhiều lần đều không sinh trùng dòng và không lỗi do object đã tồn tại.
6. **Không dùng pattern Web `.aspx`.** Kiểu này đã lỗi thời; menu Web hiện dùng HTML-rendered: wrapper `sp_X`, renderer `sp_X_html`, cache trong `tblHtmlScriptCache`, render qua `ParadiseWebView2`.
7. **Tên menu đa ngôn ngữ phải lấy từ `tblMD_Message`**, không hard-code theo cảm tính.
8. **Quyền menu phải map qua `tblSC_Object.Description = MenuID`**, không tự suy ra `ObjectID` nếu chưa query.

---

## 2. Checklist đầu vào cần hỏi user nếu thiếu

Nếu user chỉ nói tên menu, ví dụ "Quản lý bài học", Agent vẫn có thể bắt đầu bằng query theo `tblMD_Message.Content`.

→ Xem [18_FindMenuProcedure.md](18_FindMenuProcedure.md) cho quy trình lookup 5 bước chuẩn (kèm xử lý case 0 match / nhiều match / `ClassName` là VIEW / không có `_html`).

Nếu có nhiều kết quả trùng tên, phải hỏi user chọn menu nào.

Thông tin nên xác định:

| Thông tin | Bắt buộc? | Cách lấy |
|---|---:|---|
| Tên menu tiếng Việt / tiếng Anh | Có | User cung cấp hoặc `tblMD_Message.Content` |
| `MenuID` | Có | Query `tblMD_Message` + `MEN_Menu` |
| Hệ thống nguồn / đích | Tuỳ yêu cầu | User cung cấp; nếu chỉ tạo script generic thì không cần `USE DB` cố định |
| Script update hay migrate full | Có | Nếu user chưa nói rõ, mặc định migrate full an toàn theo metadata hiện có |
| Có migrate quyền không | **Mặc định: chỉ cấp LoginID = 3** | Theo rule cấp quyền (xem header file). Bỏ qua mọi LoginID/UserGroupID khác trong script. |
| LoginID/UserGroupID cần gán quyền | **Cố định = 3** | Không hỏi user — luôn chỉ LoginID = 3. User tự cấp cho user/group khác qua app/script riêng sau. |

---

## 3. Phase A — Tìm đúng menu nguồn từ tên menu

### 3.1. Tìm theo tên trong `tblMD_Message`

Khi user đưa tên như "Quản lý bài học" hoặc "Nhật ký công việc", chạy query đọc:

```sql
DECLARE @Keyword nvarchar(200) = N'Quản lý bài học';

SELECT TOP 50
       msg.MessageID AS MenuID,
       msg.Language,
       msg.Content,
       m.ParentMenuID,
       m.ClassName,
       m.AssemblyName,
       m.IsVisible,
       m.IsWeb,
       m.ViewOnWeb,
       m.isShowLayOutWeb,
       m.IsUseMobileDevice,
       m.URL
FROM tblMD_Message msg
LEFT JOIN MEN_Menu m ON m.MenuID = msg.MessageID
WHERE msg.Content LIKE N'%' + @Keyword + N'%'
ORDER BY msg.MessageID, msg.Language;
```

Đánh giá kết quả:

| Tình huống | Xử lý |
|---|---|
| 0 dòng | Báo không tìm thấy trong `tblMD_Message`; có thể query thêm `MEN_Menu.ClassName`, nhưng không đoán |
| 1 `MenuID` | Dùng `MenuID` đó làm nguồn |
| Nhiều `MenuID` | Liệt kê ngắn gọn và hỏi user chọn |
| Có `MessageID` nhưng không có `MEN_Menu` | Đây có thể là message orphan; không dùng làm menu nếu user không xác nhận |

### 3.2. Tìm trực tiếp nếu user đã đưa `MenuID`

```sql
DECLARE @MenuID varchar(100) = 'MnuXXX';

SELECT TOP 1 *
FROM MEN_Menu
WHERE MenuID = @MenuID;

SELECT TOP 20 *
FROM tblMD_Message
WHERE MessageID = @MenuID
ORDER BY Language;
```

### 3.3. Tìm theo `ClassName` nếu user đưa tên procedure/form

```sql
DECLARE @ClassName varchar(200) = 'sp_X';

SELECT TOP 20
       m.MenuID,
       msg.Content AS MenuNameVN,
       m.ParentMenuID,
       m.ClassName,
       m.AssemblyName,
       m.IsVisible,
       m.ViewOnWeb,
       m.isShowLayOutWeb
FROM MEN_Menu m
LEFT JOIN tblMD_Message msg
       ON msg.MessageID = m.MenuID AND msg.Language = 'VN'
WHERE m.ClassName = @ClassName
   OR m.ClassName LIKE '%' + @ClassName + '%'
ORDER BY m.MenuID;
```

---

## 4. Phase B — Inventory toàn bộ thành phần của menu

Sau khi có `@MenuID`, luôn chạy bộ query inventory dưới đây để lấy chứng cứ đầy đủ.

```sql
DECLARE @MenuID varchar(100) = 'MnuXXX';

-- 1. Metadata menu
SELECT TOP 1 *
FROM MEN_Menu
WHERE MenuID = @MenuID;

-- 2. Object phân quyền
SELECT TOP 10 *
FROM tblSC_Object
WHERE Description = @MenuID;

-- 3. Tên đa ngôn ngữ
SELECT TOP 20 *
FROM tblMD_Message
WHERE MessageID = @MenuID
ORDER BY Language;

-- 4. DataSetting nếu là DataSetting menu
SELECT TOP 20 ds.*
FROM tblDataSetting ds
JOIN MEN_Menu m
  ON ds.TableName = m.ClassName
  OR ds.ViewName = m.ClassName
  OR LOWER(ds.TableName) = LOWER(m.ClassName)
  OR LOWER(ds.ViewName) = LOWER(m.ClassName)
WHERE m.MenuID = @MenuID;

-- 5. Layout Web/Desktop nếu có
SELECT TOP 100 l.*
FROM tblDataSettingLayout l
JOIN MEN_Menu m
  ON LOWER(l.TableName) = LOWER(m.ClassName)
WHERE m.MenuID = @MenuID
ORDER BY l.TableName, l.ControlName;

-- 6. HTML cache nếu menu HTML-rendered
SELECT TOP 20 c.TableName, c.LanguageID, c.ScreenType,
       DATALENGTH(c.html) AS HtmlBytes,
       DATALENGTH(c.HtmlParadise) AS HtmlParadiseBytes,
       DATALENGTH(c.paradiseJs) AS ParadiseJsBytes,
       c.Version,
       DATALENGTH(c.VersionData) AS VersionDataBytes
FROM tblHtmlScriptCache c
JOIN MEN_Menu m
  ON c.TableName = m.ClassName + '_html'
WHERE m.MenuID = @MenuID
ORDER BY c.TableName, c.LanguageID;
```

Ghi chú:

- `MEN_Menu` là metadata chính.
- `tblSC_Object.Description = MenuID` là object phân quyền.
- `tblMD_Message.MessageID = MenuID` là label đa ngôn ngữ.
- `tblDataSetting` / `tblDataSettingLayout` chỉ có nếu menu dạng `DataSetting` hoặc có layout.
- `tblHtmlScriptCache.TableName = ClassName + '_html'` với menu HTML-rendered.

---

## 5. Phase C — Xác định loại menu và phạm vi migrate

Dựa vào `MEN_Menu.AssemblyName`, `ClassName`, các cờ Web và cache HTML.

| Dấu hiệu | Loại menu | Cần migrate |
|---|---|---|
| `AssemblyName = 'DataSetting'`, `ClassName = sp_X`, có `sp_X_html`, có `tblHtmlScriptCache` | Web HTML-rendered | wrapper, renderer, API JS gọi, cache, metadata, layout, quyền, ngôn ngữ |
| `AssemblyName = 'DataSetting'`, `ClassName` là view/table/proc, có `tblDataSetting` | DataSetting grid/list | view/proc data, `tblDataSetting`, layout, metadata, quyền, ngôn ngữ |
| `AssemblyName = 'SuperForm'` | SuperForm | `Menu_FrameSetting`, metadata, quyền, ngôn ngữ, source/proc liên quan |
| `AssemblyName` dạng `HPA.*` | Form .NET viết tay | metadata, quyền, ngôn ngữ; source .NET ngoài DB nếu cần |
| `URL` trỏ `.aspx` | Lỗi thời | Không migrate theo pattern này; cần xác nhận chuyển sang HTML-rendered |

Nếu là menu Web hiện tại, ưu tiên pattern HTML-rendered.

---

## 6. Phase D — Tìm procedure wrapper và renderer HTML

### 6.1. Quy ước tìm

Với `MEN_Menu.ClassName = sp_X`:

| Thành phần | Tên |
|---|---|
| Wrapper | `sp_X` |
| Renderer HTML | `sp_X_html` |
| Cache key | `tblHtmlScriptCache.TableName = 'sp_X_html'` |

### 6.2. Query kiểm tra object tồn tại và lấy source

```sql
DECLARE @ClassName sysname = 'sp_X';
DECLARE @Renderer sysname = @ClassName + '_html';

SELECT TOP 10
       name,
       type_desc,
       create_date,
       modify_date
FROM sys.objects
WHERE name IN (@ClassName, @Renderer);

SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.' + @ClassName)) AS WrapperSource;
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.' + @Renderer)) AS RendererSource;
```

### 6.3. Wrapper chuẩn nên có dạng

```sql
CREATE PROCEDURE dbo.sp_X
(
    @LoginID    INT,
    @LanguageID VARCHAR(5) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 html
    FROM dbo.tblHtmlScriptCache
    WHERE TableName = 'sp_X_html'
      AND ScreenType = '-1'
      AND LanguageID = @LanguageID;
END
```

Nếu wrapper khác pattern này, Agent phải đọc source và giữ đúng logic hiện có; không tự đơn giản hoá nếu chưa xác minh.

---

## 7. Phase E — Tìm API / procedure dữ liệu được JavaScript gọi

Renderer `sp_X_html` thường chứa HTML/CSS/JS. Cần đọc source renderer và tìm các chuỗi gọi API.

### 7.1. Từ source renderer, tìm các keyword

Tìm trong text source:

```text
AjaxHPAParadise
sp_
openFormParam
OpenFormParamMobile
paradisefile_
GetFileAPI
api
```

### 7.2. Query hỗ trợ tìm procedure liên quan bằng source SQL

Nếu biết prefix `sp_X`, tìm procedure cùng họ:

```sql
DECLARE @Prefix sysname = 'sp_X';

SELECT TOP 100
       o.name,
       o.type_desc,
       o.modify_date
FROM sys.objects o
WHERE o.type = 'P'
  AND o.name LIKE @Prefix + '%'
ORDER BY o.name;
```

Nếu cần tìm procedure được nhắc trong source:

```sql
DECLARE @Keyword nvarchar(200) = N'AjaxHPAParadise';

SELECT TOP 100
       o.name,
       o.type_desc
FROM sys.sql_modules sm
JOIN sys.objects o ON o.object_id = sm.object_id
WHERE sm.definition LIKE N'%' + @Keyword + N'%'
ORDER BY o.name;
```

### 7.3. Với từng API/procedure tìm được, export source

```sql
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_X_GetData')) AS Source;
```

Phải phân loại:

| Loại procedure | Có cần đưa vào script migrate? |
|---|---|
| Wrapper menu `sp_X` | Có |
| Renderer `sp_X_html` | Có |
| API runtime JS gọi như `sp_X_GetData` | Có |
| Procedure dùng chung toàn hệ thống | Chỉ đưa nếu user yêu cầu hoặc nếu hệ thống đích chưa có; phải ghi chú |
| Procedure refresh hệ thống như `sp_UpdateMenuInUserRight` | Không tạo lại; chỉ `EXEC` sau migrate |

---

## 8. Phase F — Lấy nội dung ngôn ngữ từ `tblMD_Message`

Không hard-code label. Luôn lấy từ DB nguồn:

```sql
DECLARE @MenuID varchar(100) = 'MnuXXX';

SELECT TOP 20
       MessageID,
       Language,
       Content
FROM tblMD_Message
WHERE MessageID = @MenuID
ORDER BY Language;
```

Khi sinh script migrate, khai báo biến theo dữ liệu thực tế:

```sql
DECLARE @NameVN nvarchar(200) = N'<Content VN lấy từ tblMD_Message>';
DECLARE @NameEN nvarchar(200) = N'<Content EN lấy từ tblMD_Message>';
```

Nếu thiếu EN hoặc VN:

| Tình huống | Xử lý |
|---|---|
| Có VN, thiếu EN | Có thể dùng VN cho EN nhưng phải ghi comment trong script |
| Có EN, thiếu VN | Có thể dùng EN cho VN nhưng phải ghi comment |
| Thiếu cả hai | Không tự đặt tên; hỏi user xác nhận |

Dùng helper đã xác minh:

```sql
EXEC dbo.[1rename_Mess] @MenuID, 'VN', @NameVN;
EXEC dbo.[1rename_Mess] @MenuID, 'EN', @NameEN;
```

Nếu migrate nhiều language khác ngoài VN/EN, dùng `MERGE tblMD_Message` theo `(MessageID, Language)` hoặc gọi helper tương ứng nếu helper hỗ trợ.

---

## 9. Phase G — Lấy và migrate quyền menu

### 9.1. Tìm `ObjectID` nguồn

```sql
DECLARE @MenuID varchar(100) = 'MnuXXX';

SELECT TOP 10
       ObjectID,
       ObjectName,
       Description,
       Visible,
       ParentObjectID,
       ParentObjectRightID,
       ParentRight
FROM tblSC_Object
WHERE Description = @MenuID;
```

Nếu không có `tblSC_Object`, menu chưa có object phân quyền; script migrate phải tạo mới theo `Description = @MenuID`.

### 9.2. Lấy quyền cá nhân nguồn

```sql
DECLARE @MenuID varchar(100) = 'MnuXXX';

SELECT TOP 100
       rs.LoginID,
       rs.ObjectID,
       rs.FullAccess
FROM tblSC_Right_Stored rs
JOIN tblSC_Object o ON o.ObjectID = rs.ObjectID
WHERE o.Description = @MenuID
ORDER BY rs.LoginID;
```

### 9.3. Lấy quyền group nguồn

```sql
DECLARE @MenuID varchar(100) = 'MnuXXX';

SELECT TOP 100
       gr.UserGroupID,
       gr.ObjectID,
       gr.FullAccess
FROM tblSC_GroupRight gr
JOIN tblSC_Object o ON o.ObjectID = gr.ObjectID
WHERE o.Description = @MenuID
ORDER BY gr.UserGroupID;
```

### 9.4. Nguyên tắc script quyền idempotent

- `tblSC_Right_Stored`: khóa logic `ObjectID + LoginID`.
- `tblSC_GroupRight`: khóa logic `ObjectID + UserGroupID`.
- Nếu có dòng thì `UPDATE FullAccess`.
- Nếu chưa có thì `INSERT`.
- Không bao giờ insert thẳng mà không check tồn tại.

---

## 10. Phase H — Build script migrate idempotent

Script nên đặt trong `SQL script/` theo format:

```text
migrate_menu_<TenNgan>_<YYYYMMDD>.sql
update_menu_<TenNgan>_<YYYYMMDD>.sql
```

Ví dụ:

```text
SQL script/migrate_menu_worklog_20260520.sql
SQL script/update_menu_lesson_management_20260520.sql
```

### 10.1. Header bắt buộc

```sql
-- ============================================================================
-- File   : SQL script/migrate_menu_<scope>_<YYYYMMDD>.sql
-- Mục đích: Migrate/update menu <Tên menu> (<MenuID>) trong ParadiseHR.
-- Nguồn  : Đã xác minh từ MEN_Menu, tblSC_Object, tblMD_Message,
--          tblDataSetting/tblDataSettingLayout/tblHtmlScriptCache và source procedure.
-- Cảnh báo: USER tự review và CHẠY. Agent KHÔNG tự động thực thi.
-- Khuyến cáo: BACKUP DB trước khi chạy.
-- Idempotent: Có thể chạy nhiều lần; không chèn trùng MEN_Menu/tblSC_Object/quyền/cache.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
```

### 10.2. Thứ tự block trong script

| Thứ tự | Block | Transaction? | Ghi chú |
|---:|---|---|---|
| 1 | Drop/Create hoặc Alter procedure API runtime | Ngoài transaction metadata | Dùng `GO` |
| 2 | Drop/Create renderer `sp_X_html` | Ngoài transaction metadata | Dùng `GO` |
| 3 | Drop/Create wrapper `sp_X` | Ngoài transaction metadata | Dùng `GO` |
| 4 | Transaction metadata | Trong `BEGIN TRY/TRAN` | `MEN_Menu`, `tblSC_Object`, `tblMD_Message`, `tblDataSetting`, `tblDataSettingLayout`, quyền |
| 4b | Metadata control/grid nếu có | Trong `BEGIN TRY/TRAN` | Nếu renderer dùng `sptblCommonControlType_Signed_DUC`, migrate thêm rows `tblCommonControlType_Signed` theo `TableName='sp_X_html'` |
| 5 | Build HTML cache | Trong hoặc sau transaction | **CHỈ** `EXEC sp_GenerateHTMLScript 'sp_X_html'` |
| 6 | Commit | Có | Rollback nếu lỗi |
| 7 | Refresh menu/right cache | Ngoài transaction | **CHỈ** `sp_Men_Menu_AfterSave_Simple @ClassName=N'<ClassName>'`. **KHÔNG** gọi `sp_UpdateMenuInUserRight` (vi phạm rule cấp quyền). |
| 8 | Verify | Ngoài transaction | SELECT kiểm chứng |

Ghi chú: `sptblCommonControlType_Signed_DUC` không thay thế bước build cache. Procedure này sinh HTML/JS control từ `tblCommonControlType_Signed`; cache cuối vẫn được ghi bởi `sp_GenerateHTMLScript 'sp_X_html'`.

---

## 11. Template idempotent cho từng thành phần

### 11.1. Procedure API / renderer / wrapper

```sql
IF OBJECT_ID('dbo.sp_X_GetData', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_X_GetData;
GO

CREATE PROCEDURE dbo.sp_X_GetData
(
    @LoginID INT,
    @LanguageID varchar(5) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;
    -- source đã xác minh
END
GO
PRINT '[OK] Created/Updated procedure sp_X_GetData';
GO
```

Áp dụng tương tự cho `sp_X_html` và `sp_X`.

### 11.2. `tblHtmlScriptCache` trong renderer (xem skill riêng)

Renderer phải tự upsert cache bằng `MERGE` theo `(TableName, LanguageID)` và fill đủ **8 cột notnull** (`TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData`). **Template MERGE đầy đủ + giải thích từng cột**: xem [17_RendererHtmlJsSafe.md §5](17_RendererHtmlJsSafe.md).

### 11.3. `MEN_Menu`

```sql
IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = @MenuID)
BEGIN
    INSERT INTO MEN_Menu
        (MenuID, ClassName, AssemblyName, ParentMenuID, Priority,
         IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb,
         IsUseMobileDevice, isShowInMobileLayOut,
         glyphicon, GroupID,
         IsModal, LinkMenuID, IsCollapsed, ShortcutKeys, SupperAdmin, LargeTile,
         Colors, superForm, DefaultParam, Notification, URL, IsNotAjax,
         InstructionID, showDialog, ProcessDataForNotifyProc,
         ClassName_Audit, ClassName_CT, Showinsuperform, Activity, Separation,
         MobileDeviceGroup, PriorityMobileDevice, IsLeftMenu, NotUsePlatform,
         OptionAuthentication, IconBackColor, IconForeColor, isParentMenu,
         ParentMenuMobileID, IsHiddenInTree)
    VALUES
        (@MenuID, @ClassName, @AssemblyName, @ParentMenuID, @Priority,
         1, @IsWeb, @ViewOnWeb, @IsShowLayOutWeb,
         @IsUseMobileDevice, @IsShowInMobileLayOut,
         @Glyphicon, @GroupID,
         0, '', 0, '', 0, 0,
         '', '', '', 0, '', 0,
         '', 0, '',
         '', '', 0, N'', 0,
         N'', 0, 0, N'',
         0, N'', N'', 0,
         '', 0);
END
ELSE
BEGIN
    UPDATE MEN_Menu
    SET ClassName              = @ClassName,
        AssemblyName           = @AssemblyName,
        ParentMenuID           = @ParentMenuID,
        Priority               = @Priority,
        IsVisible              = 1,
        IsWeb                  = @IsWeb,
        ViewOnWeb              = @ViewOnWeb,
        isShowLayOutWeb        = @IsShowLayOutWeb,
        IsUseMobileDevice      = @IsUseMobileDevice,
        isShowInMobileLayOut   = @IsShowInMobileLayOut,
        glyphicon              = @Glyphicon,
        GroupID                = @GroupID
    WHERE MenuID = @MenuID;
END
```

### 11.4. `tblSC_Object`

```sql
DECLARE @ObjectID int;
DECLARE @ParentObjectID int;

SELECT TOP 1 @ParentObjectID = ObjectID
FROM tblSC_Object
WHERE Description = @ParentMenuID;

IF @ParentObjectID IS NULL SET @ParentObjectID = 1;

IF NOT EXISTS (SELECT 1 FROM tblSC_Object WHERE Description = @MenuID)
BEGIN
    SET @ObjectID = ISNULL((SELECT MAX(ObjectID) FROM tblSC_Object), 0) + 1;

    INSERT INTO tblSC_Object
        (ObjectID, ObjectName, Description, Visible, ParentObjectID,
         ParentObjectRightID, ParentRight)
    VALUES
        (@ObjectID, @ObjectName, @MenuID, 1, @ParentObjectID, 0, 0);
END
ELSE
BEGIN
    UPDATE tblSC_Object
    SET ObjectName     = @ObjectName,
        Visible        = 1,
        ParentObjectID = @ParentObjectID
    WHERE Description = @MenuID;

    SELECT TOP 1 @ObjectID = ObjectID
    FROM tblSC_Object
    WHERE Description = @MenuID;
END
```

### 11.5. `tblMD_Message`

Ưu tiên dùng helper:

```sql
EXEC dbo.[1rename_Mess] @MenuID, 'VN', @NameVN;
EXEC dbo.[1rename_Mess] @MenuID, 'EN', @NameEN;
```

Nếu cần migrate nhiều language, dùng pattern `MERGE`:

```sql
MERGE tblMD_Message AS tgt
USING (SELECT @MenuID AS MessageID, 'VN' AS Language, @NameVN AS Content) AS src
   ON tgt.MessageID = src.MessageID AND tgt.Language = src.Language
WHEN MATCHED THEN
    UPDATE SET tgt.Content = src.Content
WHEN NOT MATCHED BY TARGET THEN
    INSERT (MessageID, Language, Content)
    VALUES (src.MessageID, src.Language, src.Content);
```

### 11.6. `tblDataSetting`

Chỉ thêm block này nếu inventory có `tblDataSetting` hoặc menu cần DataSetting layout.

Nguyên tắc:

- Xác định key theo dữ liệu nguồn: thường là `TableName` hoặc `ViewName` bằng `ClassName`.
- Nếu đã tồn tại thì `UPDATE`.
- Nếu chưa có thì `INSERT` đủ cột bắt buộc theo schema DB thực tế.
- Không tự bịa danh sách cột; phải dùng schema/source đã query.

Query schema trước khi viết block:

```sql
SELECT TOP 100
       COLUMN_NAME,
       DATA_TYPE,
       IS_NULLABLE,
       COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'tblDataSetting'
ORDER BY ORDINAL_POSITION;
```

Template logic:

```sql
IF EXISTS (SELECT 1 FROM tblDataSetting WHERE TableName = @ClassName OR ViewName = @ClassName)
BEGIN
    UPDATE tblDataSetting
    SET -- các cột đã xác minh từ menu nguồn
        IsProcedure = 1,
        IsShowLayout = 1
    WHERE TableName = @ClassName OR ViewName = @ClassName;
END
ELSE
BEGIN
    INSERT INTO tblDataSetting (...)
    VALUES (...);
END
```

### 11.7. `tblDataSettingLayout`

Nếu menu nguồn có layout, migrate theo key ổn định như `TableName + ControlName` hoặc các cột định danh đã xác minh.

Nguyên tắc:

- Không `DELETE` toàn bộ layout nếu không được user yêu cầu.
- Dùng `MERGE` từng control để chạy lại không trùng.
- Với HTML-rendered cần control `ParadiseWebView2`, thường `ControlName = 'html'`.

Template logic:

```sql
MERGE dbo.tblDataSettingLayout AS tgt
USING (
    SELECT
        LOWER(@ClassName) AS TableName,
        'lblhtml' AS ControlName,
        'ParadiseWebView2' AS ControlType,
        'html' AS FieldName,
        100 AS WidthPercentage
) AS src
ON LOWER(tgt.TableName) = src.TableName
AND tgt.ControlName = src.ControlName
WHEN MATCHED THEN
    UPDATE SET tgt.ControlType = src.ControlType,
               tgt.FieldName = src.FieldName,
               tgt.WidthPercentage = src.WidthPercentage
WHEN NOT MATCHED BY TARGET THEN
    INSERT (TableName, ControlName, ControlType, FieldName, WidthPercentage)
    VALUES (src.TableName, src.ControlName, src.ControlType, src.FieldName, src.WidthPercentage);
```

> Lưu ý: danh sách cột thực tế của `tblDataSettingLayout` phải được query trước; template trên chỉ minh hoạ logic `MERGE`.

### 11.8. `tblSC_Right_Stored` — **CHỈ** cấp cho LoginID = 3

Theo rule cấp quyền ở header file: script migrate **không bao giờ** cấp quyền cho LoginID ≠ 3 hoặc UserGroupID nào. Block dưới đây là template duy nhất được phép:

```sql
DECLARE @AdminLoginID INT = 3;
DECLARE @FullAccess   NVARCHAR(10) = N'32';

IF NOT EXISTS (
    SELECT 1 FROM tblSC_Right_Stored
    WHERE ObjectID = @ObjectID AND LoginID = @AdminLoginID
)
    INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess)
    VALUES (@ObjectID, @AdminLoginID, @FullAccess);
ELSE
    UPDATE tblSC_Right_Stored
    SET    FullAccess = @FullAccess
    WHERE  ObjectID = @ObjectID AND LoginID = @AdminLoginID;
```

### 11.9. `tblSC_GroupRight` — **KHÔNG** xử lý trong script migrate

Theo rule, **không** insert/update bất kỳ row nào trong `tblSC_GroupRight` qua script migrate. Nếu user yêu cầu cấp cho group sau khi script chạy → hướng dẫn user dùng giao diện phân quyền trong app, hoặc Agent build **script cấp quyền riêng** (không trộn với script migrate menu).

### 11.10. Seed bảng master data với schema-aware IDENTITY_INSERT

Khi script migrate phải seed bảng master data (vd `tblTask_ComplaintTypes`, `tblMST_*`) với explicit ID, phải tuân Rule 6 — chỉ `SET IDENTITY_INSERT` khi cột PK thực sự là IDENTITY ở DB đích:

```sql
-- Tạo bảng nếu chưa có
IF OBJECT_ID('dbo.tblTask_ComplaintTypes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tblTask_ComplaintTypes (
        ComplaintTypeID     int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ComplaintTypeName   nvarchar(255) NOT NULL,
        ComplaintTypeNameEN nvarchar(255) NULL
    );
END
GO

-- Seed với explicit ID — wrap IDENTITY_INSERT bằng COLUMNPROPERTY check (Rule 6)
-- Lý do: DB đích có thể đã có bảng cùng tên với schema cũ (cột PK KHÔNG khai báo IDENTITY) →
-- SET IDENTITY_INSERT sẽ raise Msg 8106 "Table does not have the identity property".
IF COLUMNPROPERTY(OBJECT_ID('dbo.tblTask_ComplaintTypes'), 'ComplaintTypeID', 'IsIdentity') = 1
    SET IDENTITY_INSERT dbo.tblTask_ComplaintTypes ON;
GO

MERGE dbo.tblTask_ComplaintTypes AS tgt
USING (VALUES
    (1, N'Gia hạn thời gian hoàn thành', N'Extend Deadline'),
    (2, N'Khiếu nại từ chối duyệt',      N'Appeal Rejection')
) AS src(ComplaintTypeID, ComplaintTypeName, ComplaintTypeNameEN)
   ON tgt.ComplaintTypeID = src.ComplaintTypeID
WHEN MATCHED THEN UPDATE SET
    tgt.ComplaintTypeName   = src.ComplaintTypeName,
    tgt.ComplaintTypeNameEN = src.ComplaintTypeNameEN
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ComplaintTypeID, ComplaintTypeName, ComplaintTypeNameEN)
    VALUES (src.ComplaintTypeID, src.ComplaintTypeName, src.ComplaintTypeNameEN);
GO

IF COLUMNPROPERTY(OBJECT_ID('dbo.tblTask_ComplaintTypes'), 'ComplaintTypeID', 'IsIdentity') = 1
    SET IDENTITY_INSERT dbo.tblTask_ComplaintTypes OFF;
GO
```

Nếu schema mismatch là critical (vd script kỳ vọng cột IDENTITY để app runtime auto-gen ID nhưng DB đích không có), phải RAISERROR thay vì silent skip — xem [Rule 6](#rule-6--schema-aware-idempotent-chống-msg-8106-và-họ-lỗi-tương-tự) phần "Cách xử lý triệt để hơn".

---

## 12. Phase I — Build cache và refresh sau migrate

Sau khi metadata đã ổn, build cache HTML bằng helper `sp_GenerateHTMLScript`:

```sql
EXEC dbo.sp_GenerateHTMLScript 'sp_X_html';
```

> ✅ Chuẩn thống nhất: không khuyến nghị gọi trực tiếp procedure renderer `_html` theo từng `LanguageID`; script migrate/update menu chỉ dùng helper để build/rebuild cache.

Sau đó refresh menu/right cache (chỉ 1 lệnh — theo rule):

```sql
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_X';   -- ClassName của menu vừa migrate
PRINT '[OK] sp_Men_Menu_AfterSave_Simple executed';
GO

-- ❌ KHÔNG gọi sp_UpdateMenuInUserRight — proc này mở quyền cho mọi LoginID,
--     vi phạm rule. User tự cấp quyền cho user/group khác qua app/script riêng.
```

User cần logout/login để cây menu reload.

---

## 13. Phase J — Verify sau migrate

Cuối script luôn có block verify.

```sql
DECLARE @MenuID varchar(100) = 'MnuXXX';

SELECT m.MenuID,
       m.ClassName,
       m.AssemblyName,
       m.ParentMenuID,
       m.Priority,
       m.IsVisible,
       m.IsWeb,
       m.ViewOnWeb,
       m.isShowLayOutWeb,
       m.IsUseMobileDevice,
       o.ObjectID,
       o.ObjectName,
       msgVN.Content AS NameVN,
       msgEN.Content AS NameEN,
       (SELECT COUNT(*) FROM tblSC_Right_Stored WHERE ObjectID = o.ObjectID) AS RightStoredRows,
       (SELECT COUNT(*) FROM tblSC_GroupRight WHERE ObjectID = o.ObjectID) AS GroupRightRows,
       (SELECT COUNT(*) FROM tblHtmlScriptCache WHERE TableName = m.ClassName + '_html') AS HtmlCacheLangs
FROM MEN_Menu m
LEFT JOIN tblSC_Object o
       ON o.Description = m.MenuID
LEFT JOIN tblMD_Message msgVN
       ON msgVN.MessageID = m.MenuID AND msgVN.Language = 'VN'
LEFT JOIN tblMD_Message msgEN
       ON msgEN.MessageID = m.MenuID AND msgEN.Language = 'EN'
WHERE m.MenuID = @MenuID;

SELECT TOP 20
       TableName,
       LanguageID,
       ScreenType,
       DATALENGTH(html) AS HtmlBytes,
       Version
FROM tblHtmlScriptCache
WHERE TableName = (SELECT TOP 1 ClassName + '_html' FROM MEN_Menu WHERE MenuID = @MenuID)
ORDER BY LanguageID;
```

Nếu verify thấy:

| Dấu hiệu | Ý nghĩa | Cách xử lý |
|---|---|---|
| `MEN_Menu` không có dòng | Script chưa insert/update menu đúng `MenuID` |
| `tblSC_Object` null | Quyền sẽ không map được; sửa block object |
| `NameVN`/`NameEN` null | Thiếu `tblMD_Message`; sửa block language |
| `HtmlCacheLangs = 0` | Renderer chưa build cache hoặc sai `TableName` |
| `RightStoredRows = 0` và `GroupRightRows = 0` | User có thể không thấy menu nếu không có quyền khác/override |

---

## 14. Quy trình Agent phải làm khi user yêu cầu "tạo script update/migrate menu <Tên>"

### Bước 1 — Đọc Knowledge bắt buộc

1. Đọc [INDEX.md](INDEX.md).
2. Đọc [99_deprecated.md](99_deprecated.md).
3. Đọc file này [13_Migrate_Menu.md](13_Migrate_Menu.md).
4. Nếu cần chi tiết nền: đọc [07_menu_system.md](07_menu_system.md), [11_permissions.md](11_permissions.md).

### Bước 2 — Tìm menu trong DB

- Nếu user đưa tên tiếng Việt: query `tblMD_Message.Content LIKE N'%<Tên>%'`.
- Nếu user đưa `MenuID`: query `MEN_Menu WHERE MenuID = ...`.
- Nếu user đưa `ClassName`: query `MEN_Menu WHERE ClassName = ...`.

### Bước 3 — Nếu nhiều menu trùng tên

Không tự chọn. Trả danh sách `MenuID`, `Content`, `ClassName`, `ParentMenuID` và hỏi user chọn.

### Bước 4 — Inventory menu đã chọn

Chạy các query Phase B để lấy:

- `MEN_Menu`
- `tblSC_Object`
- `tblMD_Message`
- `tblDataSetting`
- `tblDataSettingLayout`
- `tblHtmlScriptCache`
- quyền trong `tblSC_Right_Stored` / `tblSC_GroupRight`

### Bước 5 — Tìm source procedure

- Lấy `MEN_Menu.ClassName`.
- Query source wrapper `ClassName`.
- Query source renderer `ClassName + '_html'` nếu tồn tại.
- Search renderer để tìm API/procedure dữ liệu.
- Query source từng API/procedure liên quan.

### Bước 6 — Xác định script cần sinh

| User yêu cầu | Script cần sinh |
|---|---|
| update label/ngôn ngữ | Chỉ `tblMD_Message` / `dbo.[1rename_Mess]` + verify |
| update quyền | `tblSC_Object` nếu thiếu + `tblSC_Right_Stored` / `tblSC_GroupRight` + refresh |
| update UI HTML | renderer `sp_X_html` + build cache + verify |
| migrate full | procedure API + renderer + wrapper + metadata + layout + cache + quyền + refresh + verify |

### Bước 7 — Tạo file SQL, không thực thi

- Tạo trong `SQL script/`.
- Header rõ mục đích, nguồn xác minh, cảnh báo backup.
- Bọc metadata bằng `BEGIN TRY / BEGIN TRANSACTION / COMMIT / CATCH ROLLBACK`.
- Dùng `GO` đúng chỗ cho `CREATE PROCEDURE`.

### Bước 8 — Đảm bảo idempotent

Trước khi kết thúc, tự review script theo checklist:

| Thành phần | Check idempotent bắt buộc |
|---|---|
| Procedure | `IF OBJECT_ID(...) IS NOT NULL DROP` rồi `CREATE`, hoặc `CREATE OR ALTER` nếu DB hỗ trợ |
| `MEN_Menu` | `IF NOT EXISTS INSERT ELSE UPDATE` |
| `tblSC_Object` | Check `Description = @MenuID`; không insert trùng |
| `tblMD_Message` | `dbo.[1rename_Mess]` hoặc `MERGE` theo `(MessageID, Language)` |
| `tblHtmlScriptCache` | `MERGE` theo `(TableName, LanguageID)` |
| `tblSC_Right_Stored` | Check `(ObjectID, LoginID)` |
| `tblSC_GroupRight` | Check `(ObjectID, UserGroupID)` |
| Layout | `MERGE` theo key layout đã xác minh |
| Refresh | **CHỈ** `EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>'`. **KHÔNG** gọi `sp_UpdateMenuInUserRight` (rule cấp quyền — chỉ LoginID=3). |
| Verify | Có SELECT cuối script |

### Bước 9 — Trả lời user

Trả lời ngắn gọn:

- Đã tạo file script nào.
- Menu nguồn là gì (`MenuID`, `ClassName`) — kèm nguồn query/Knowledge.
- Script có các phần nào.
- Nhắc user review, backup DB, tự chạy.
- Nói rõ đã cập nhật Knowledge nếu có.

---

## 15. Mẫu khung script migrate full

> Đây là skeleton. Khi dùng thực tế, Agent phải thay bằng giá trị đã query từ DB nguồn, không tự bịa.

```sql
-- ============================================================================
-- File   : SQL script/migrate_menu_<scope>_<YYYYMMDD>.sql
-- Mục đích: Migrate/update menu <Tên menu> (<MenuID>) trong ParadiseHR.
-- Cảnh báo: USER tự review và CHẠY. Agent KHÔNG tự động thực thi.
-- Khuyến cáo: BACKUP DB trước khi chạy.
-- Idempotent: chạy nhiều lần không chèn trùng menu/object/quyền/cache.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- PHASE 1: API procedures
IF OBJECT_ID('dbo.sp_X_GetData', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_X_GetData;
GO
CREATE PROCEDURE dbo.sp_X_GetData
(
    @LoginID int,
    @LanguageID varchar(5) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;
    -- TODO: source đã xác minh từ DB nguồn
END
GO

-- PHASE 2: Renderer
IF OBJECT_ID('dbo.sp_X_html', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_X_html;
GO
CREATE PROCEDURE dbo.sp_X_html
(
    @LoginID int = 3,
    @LanguageID varchar(5) = 'VN',
    @isWeb int = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @html nvarchar(max);
    SET @html = N'<!-- HTML/CSS/JS đã xác minh -->';

    MERGE dbo.tblHtmlScriptCache AS tgt
    USING (SELECT 'sp_X_html' AS TableName,
                  @LanguageID AS LanguageID,
                  '-1' AS ScreenType,
                  @html AS html,
                  N'' AS HtmlParadise,
                  N'' AS paradiseJs,
                  '1' AS Version,
                  N'' AS VersionData) AS src
       ON tgt.TableName = src.TableName AND tgt.LanguageID = src.LanguageID
    WHEN MATCHED THEN
        UPDATE SET tgt.ScreenType = src.ScreenType,
                   tgt.html = src.html,
                   tgt.HtmlParadise = src.HtmlParadise,
                   tgt.paradiseJs = src.paradiseJs,
                   tgt.Version = src.Version,
                   tgt.VersionData = src.VersionData
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData)
        VALUES (src.TableName, src.LanguageID, src.ScreenType, src.html, src.HtmlParadise, src.paradiseJs, src.Version, src.VersionData);
END
GO

-- PHASE 3: Wrapper
IF OBJECT_ID('dbo.sp_X', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_X;
GO
CREATE PROCEDURE dbo.sp_X
(
    @LoginID int,
    @LanguageID varchar(5) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 html
    FROM dbo.tblHtmlScriptCache
    WHERE TableName = 'sp_X_html'
      AND ScreenType = '-1'
      AND LanguageID = @LanguageID;
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
    DECLARE @NameVN nvarchar(200) = N'<Tên VN từ tblMD_Message>';
    DECLARE @NameEN nvarchar(200) = N'<Tên EN từ tblMD_Message>';
    DECLARE @Priority int = 99;
    DECLARE @Glyphicon nvarchar(100) = N'Info';
    DECLARE @GroupID varchar(100) = @ParentMenuID;
    DECLARE @IsWeb int = 0;
    DECLARE @ViewOnWeb int = 1;
    DECLARE @IsShowLayOutWeb int = 1;
    DECLARE @IsUseMobileDevice int = 1;
    DECLARE @IsShowInMobileLayOut int = 1;
    DECLARE @AdminLoginID int = 3;
    DECLARE @FullAccess nvarchar(10) = N'32';

    -- MEN_Menu: IF NOT EXISTS INSERT ELSE UPDATE
    -- tblSC_Object: IF NOT EXISTS INSERT ELSE UPDATE
    -- tblMD_Message: EXEC dbo.[1rename_Mess]
    -- tblDataSetting/tblDataSettingLayout: MERGE nếu có
    -- tblSC_Right_Stored/tblSC_GroupRight: IF NOT EXISTS INSERT ELSE UPDATE

    EXEC dbo.sp_GenerateHTMLScript 'sp_X_html';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT '[ERROR] Line ' + CAST(ERROR_LINE() AS varchar(10)) + ': ' + ERROR_MESSAGE();
    THROW;
END CATCH
GO

EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>';
GO
-- ❌ KHÔNG gọi sp_UpdateMenuInUserRight — vi phạm rule cấp quyền (xem header file)

-- VERIFY
DECLARE @MenuID varchar(100) = 'MnuXXX';
SELECT m.MenuID, m.ClassName, m.AssemblyName, m.ParentMenuID,
       o.ObjectID, o.ObjectName,
       msgVN.Content AS NameVN, msgEN.Content AS NameEN
FROM MEN_Menu m
LEFT JOIN tblSC_Object o ON o.Description = m.MenuID
LEFT JOIN tblMD_Message msgVN ON msgVN.MessageID = m.MenuID AND msgVN.Language = 'VN'
LEFT JOIN tblMD_Message msgEN ON msgEN.MessageID = m.MenuID AND msgEN.Language = 'EN'
WHERE m.MenuID = @MenuID;
GO
```

---

## 16. Checklist chất lượng trước khi giao script cho user

Agent phải tự đối chiếu đủ các điểm sau:

- [ ] Đã xác định đúng `MenuID` từ DB, không đoán từ tên.
- [ ] Đã check [99_deprecated.md](99_deprecated.md), không dùng menu/procedure lỗi thời.
- [ ] Đã lấy label từ `tblMD_Message`.
- [ ] Đã đọc `MEN_Menu` để lấy đúng `ParentMenuID`, `ClassName`, `AssemblyName`, cờ Web/mobile.
- [ ] Đã đọc `tblSC_Object` hoặc tạo logic insert/update theo `Description = MenuID`.
- [ ] Đã tìm source wrapper và renderer nếu là HTML-rendered.
- [ ] Đã tìm API/procedure dữ liệu được JS gọi.
- [ ] Đã xử lý `tblHtmlScriptCache` bằng `MERGE`.
- [ ] `MEN_Menu` không insert trùng.
- [ ] `tblSC_Object` không insert trùng.
- [ ] `tblSC_Right_Stored` không insert trùng theo `ObjectID + LoginID`.
- [ ] `tblSC_GroupRight` không insert trùng theo `ObjectID + UserGroupID`.
- [ ] Có transaction + rollback cho metadata.
- [ ] Có refresh `sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>'` (BẮT BUỘC truyền tham số). **KHÔNG** gọi `sp_UpdateMenuInUserRight` (rule cấp quyền — chỉ LoginID=3).
- [ ] Có verify cuối script.
- [ ] Không tự thực thi script nếu user chỉ yêu cầu tạo script.
- [ ] **Schema-aware idempotent (Rule 6)**: Mọi `SET IDENTITY_INSERT` đã wrap `IF COLUMNPROPERTY(...,'IsIdentity')=1`; `ALTER COLUMN` đã check kiểu hiện tại; `ADD CONSTRAINT FK` / `CREATE INDEX` / `ALTER TABLE ADD <col>` / `DROP CONSTRAINT DF_*` đều có guard `IF EXISTS` / `IF NOT EXISTS` / `IF COL_LENGTH(...) IS NULL` tương ứng. Không giả định schema thực tế ở DB đích khớp với schema của `CREATE TABLE` ngay phía trên.

---

## 17. Câu trả lời mẫu sau khi tạo script migrate

```text
Đã tạo script [SQL script/migrate_menu_<scope>_<YYYYMMDD>.sql](../SQL%20script/migrate_menu_<scope>_<YYYYMMDD>.sql).

Nguồn xác minh:
- Menu: <MenuID> / <ClassName> từ MEN_Menu.
- Ngôn ngữ: tblMD_Message cho VN/EN.
- Phân quyền: tblSC_Object.Description = <MenuID>, quyền từ tblSC_Right_Stored / tblSC_GroupRight.
- UI Web: wrapper <sp_X>, renderer <sp_X_html>, cache tblHtmlScriptCache.

Script đã xử lý idempotent cho MEN_Menu, tblSC_Object, tblMD_Message, tblHtmlScriptCache và quyền; có refresh menu/right cache và block verify cuối file.
User review + backup DB trước khi chạy.
```
