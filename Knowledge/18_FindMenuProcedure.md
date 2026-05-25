# 18 — Skill: Tìm procedure trong DB để debug / sửa giao diện một menu

> **Skill file** — dùng khi user yêu cầu kiểu: "tìm proc của menu X", "menu Y dùng procedure nào", "sửa giao diện menu Z", "debug menu W không hiển thị". Đầu vào: **tên menu tiếng Việt** (hoặc EN/KR). Đầu ra: **MenuID + ClassName + procedure renderer `%_html`** kèm xác nhận tồn tại trong DB.
>
> Mục tiêu: Agent context-nhỏ chỉ cần đọc 1 file là biết quy trình 5 bước chuẩn — không loay hoay tra `MEN_Menu` blind hoặc đoán tên proc.
>
> Liên quan: [07_menu_system.md](07_menu_system.md) (tri thức nền 5 mảnh menu), [12_CreateMenu.md](12_CreateMenu.md) (tạo menu mới), [13_Migrate_Menu.md](13_Migrate_Menu.md) (migrate menu), [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) (sửa renderer HTML/JS), [99_deprecated.md](99_deprecated.md) (check item lỗi thời).

---

## ⚡ Quick Start (30 giây — đủ cho agent context-nhỏ)

5 query copy-paste-ready cho 5 bước lookup:

```sql
-- B1: Tìm menu theo tên (chỉ MessageID dạng Mnu...)
SELECT TOP 20 MessageID, Language, Content
FROM tblMD_Message
WHERE Content LIKE N'%<tên menu>%' AND MessageID LIKE 'Mnu%' AND Language='VN';

-- B2: Join MEN_Menu (sau khi xác định được MessageID/MenuID)
SELECT TOP 5 m.MenuID, m.ClassName, m.AssemblyName, m.ParentMenuID,
       m.IsVisible, m.IsWeb, m.ViewOnWeb, m.IsUseMobileDevice
FROM MEN_Menu m WHERE m.MenuID = '<MnuXXX>';

-- B3: ClassName = giá trị cột m.ClassName ở B2

-- B4: Verify ClassName tồn tại trong DB
SELECT name, type_desc, modify_date FROM sys.objects
WHERE name = '<ClassName>' AND type IN ('P','V','U');

-- B5: Tìm renderer _html (cho menu Web HTML-rendered)
SELECT name, type_desc, modify_date FROM sys.objects
WHERE name = '<ClassName>' + '_html' AND type='P';
```

**3 cảnh báo BẮT BUỘC**:
- ❌ KHÔNG `write_query` / `alter_table` / `drop_table` — chỉ `read_query` / `list_tables` / `describe_table` / `export_query`.
- ❌ KHÔNG đoán tên menu/proc nếu B1 trả 0 row → broaden search → **BÁO USER + LIỆT KÊ candidate**.
- ✅ Luôn check [99_deprecated.md](99_deprecated.md) trước khi đề xuất dùng tên item.

→ Đi sâu: [§2 quy trình 5 bước](#2-quy-trình-5-bước-chi-tiết) · [§3 combo query 1 lượt](#3-combo-query-1-lượt-đọc-trọn-5-bước-trong-1-batch-read_query) · [§4 demo end-to-end](#4-demo-end-to-end) · [§5 special cases](#5-xử-lý-6-trường-hợp-đặc-biệt)

---

## 1. Nguyên lý — Sơ đồ quan hệ 4 bảng

```
              ┌──────────────────────────────────────┐
              │       tblMD_Message                  │
              │  MessageID (= MenuID)                │ ← B1: tìm theo Content
              │  Language ('VN'/'EN'/'KR'/...)       │
              │  Content (tên menu hiển thị)         │
              └──────────────┬───────────────────────┘
                             │ MessageID = MenuID
                             ▼
              ┌──────────────────────────────────────┐
              │       MEN_Menu                       │
              │  MenuID (PK)                         │ ← B2: join lấy ClassName
              │  ClassName ← tên proc / view         │
              │  AssemblyName (DataSetting / HPA.*)  │
              │  ParentMenuID, IsVisible, cờ Web...  │
              └──────────────┬───────────────────────┘
                             │ ClassName → sys.objects.name
                             ▼
              ┌──────────────────────────────────────┐
              │       sys.objects                    │
              │  name (= ClassName)                  │ ← B4: verify type='P'/'V'
              │  type = 'P' (proc) / 'V' (view) / 'U'│
              │  type_desc                           │
              └──────────────┬───────────────────────┘
                             │ ClassName + '_html'
                             ▼
              ┌──────────────────────────────────────┐
              │       sys.objects (renderer)         │
              │  name = ClassName + '_html'          │ ← B5: tìm proc UI
              │  type = 'P'                          │
              └──────────────────────────────────────┘
```

Tri thức nền 5 mảnh dữ liệu của menu (bao gồm `tblSC_Object` cho phân quyền + `tblDataSetting`/`tblDataSettingLayout` cho layout): xem [07_menu_system.md §1](07_menu_system.md). File 18 này chỉ tập trung **đường đi từ tên menu → procedure**.

---

## 2. Quy trình 5 bước chi tiết

### Bước 1 — Tìm menu trong `tblMD_Message`

3 biến thể query, dùng tăng dần khi exact không có kết quả:

```sql
-- Biến thể A (exact, VN-only) — dùng đầu tiên
SELECT TOP 20 MessageID, Language, Content FROM tblMD_Message
WHERE Content LIKE N'%<tên>%' AND MessageID LIKE 'Mnu%' AND Language='VN'
ORDER BY MessageID;

-- Biến thể B (broaden — chỉ keyword chính, bỏ tiền tố/hậu tố)
SELECT TOP 50 MessageID, Language, Content FROM tblMD_Message
WHERE Content LIKE N'%<keyword>%' AND MessageID LIKE 'Mnu%'
ORDER BY MessageID;

-- Biến thể C (không giới hạn Language — đề phòng menu chỉ có EN/KR)
SELECT TOP 50 MessageID, Language, Content FROM tblMD_Message
WHERE (Content LIKE N'%<tên VN>%' OR Content LIKE N'%<tên EN>%')
  AND MessageID LIKE 'Mnu%'
ORDER BY MessageID, Language;
```

Bộ lọc `MessageID LIKE 'Mnu%'` là quan trọng — bảng `tblMD_Message` còn chứa label cột proc (dạng `sp_XXX.<ColumnName>`) và label form, không lọc sẽ trả về quá nhiều noise.

Edge cases sẽ xử lý ở [§5](#5-xử-lý-6-trường-hợp-đặc-biệt): 0 match, nhiều match.

### Bước 2 — Join `MEN_Menu` theo `MenuID = MessageID`

```sql
SELECT TOP 5 m.MenuID, m.ClassName, m.AssemblyName, m.ParentMenuID,
       m.IsVisible, m.IsWeb, m.ViewOnWeb, m.isShowLayOutWeb,
       m.IsUseMobileDevice, m.glyphicon, m.URL
FROM MEN_Menu m WHERE m.MenuID = '<MnuXXX>';
```

Đọc các cờ → xác định loại menu:

| Pattern cờ | Loại menu | ClassName trỏ tới |
|---|---|---|
| `AssemblyName='DataSetting'` + `IsUseMobileDevice=1` + cờ Web (`IsWeb`/`ViewOnWeb`/`isShowLayOutWeb`)=0 | Menu Web HTML-rendered (chuẩn hiện hành) | Procedure (có proc `_html` đi kèm) |
| `AssemblyName='DataSetting'` + tất cả cờ Web/Mobile = 0 | Menu Desktop grid | View hoặc Procedure |
| `AssemblyName='HPA.<X>'` (vd `HPA.TimeAttendance`, `HPA.Recruitment`) | Form .NET viết tay (Desktop) | Class .NET — **KHÔNG** có object DB cùng tên |
| `URL` có giá trị + `IsWeb=1` | Menu Web kiểu cũ ASPX | **LỖI THỜI** — xem [99_deprecated.md §5](99_deprecated.md) |

Pattern cờ ĐÚNG cho menu Web HTML-rendered (verified từ DB thực tế): xem [13_Migrate_Menu.md Rule 2](13_Migrate_Menu.md).

### Bước 3 — Lấy `ClassName`

`ClassName` ở MEN_Menu có thể trỏ tới 3 loại object khác nhau:

| Giá trị thực tế | Loại | Ví dụ |
|---|---|---|
| Tên procedure (thường `sp_*`) | SQL Stored Procedure | `sp_ResignationLetter_Register`, `sp_KPIProcessCustomer`, `sp_Train_Ranking_Template` |
| Tên view (thường `vtbl*` hoặc `v*`) | SQL View | `vtblEmployeeList` |
| FQN class .NET | Class trong assembly | `HPA.TimeAttendance.AttendanceForm` (không có ở DB) |

→ Bước 4 dùng `sys.objects` để xác định loại nào.

### Bước 4 — Verify `ClassName` có trong DB

```sql
SELECT name, type_desc, modify_date FROM sys.objects
WHERE name = '<ClassName>' AND type IN ('P','V','U');
```

3 nhánh kết quả:

| Kết quả | Nghĩa | Bước tiếp |
|---|---|---|
| `type_desc='SQL_STORED_PROCEDURE'` (`type='P'`) | Menu chạy procedure | Tiếp [B5](#bước-5--tìm-proc-renderer-_html-cho-menu-web-html-rendered) tìm `_html` |
| `type_desc='VIEW'` (`type='V'`) | Menu DataSetting grid (kiểu cũ, có `tblDataSetting.ViewName`) | Sửa UI = sửa view + `tblDataSetting`/`tblDataSettingLayout`. **KHÔNG** có proc `_html` |
| `type_desc='USER_TABLE'` (`type='U'`) | Menu trỏ trực tiếp bảng (hiếm gặp) | Sửa UI = sửa schema bảng + `tblDataSetting` |
| 0 row | (a) Menu form .NET (`AssemblyName='HPA.*'`) — giao diện ở .NET code, không ở DB; (b) Menu broken / deprecated | Check [99_deprecated.md](99_deprecated.md) + báo user |

### Bước 5 — Tìm proc renderer `_html` (cho menu Web HTML-rendered)

```sql
SELECT name, type_desc, modify_date FROM sys.objects
WHERE name = '<ClassName>' + '_html' AND type='P';
```

2 nhánh:

| Kết quả | Nghĩa | Bước tiếp |
|---|---|---|
| 1 row, `type='P'` | Menu HTML-rendered đúng chuẩn | Sửa UI = sửa source proc `<ClassName>_html` + `EXEC sp_GenerateHTMLScript '<ClassName>_html'` để rebuild cache (xem [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md)) |
| 0 row | Menu kiểu cũ — wrapper-only / grid không HTML-rendered | Check `tblDataSetting.IsProcedure` để biết: nếu `=0` thì grid view, nếu `=1` thì wrapper proc xử lý logic riêng (không render HTML) |

Bonus — verify HTML cache đã build:

```sql
SELECT TableName, LanguageID, ScreenType,
       DATALENGTH(html) AS HtmlBytes, Version
FROM tblHtmlScriptCache
WHERE TableName = '<ClassName>' + '_html'
ORDER BY LanguageID;
```

Nếu trả 0 row → renderer đã có nhưng chưa build cache → chạy `EXEC sp_GenerateHTMLScript '<ClassName>_html'` (xem [07_menu_system.md §6 Phase F](07_menu_system.md)).

---

## 3. Combo query 1 lượt (đọc trọn 5 bước trong 1 batch `read_query`)

Khi đã biết tên chính xác của menu (hoặc đã verify ở B1 bằng query exact), chạy combo dưới đây để lấy đủ thông tin cho 5 bước:

```sql
DECLARE @MenuName nvarchar(200) = N'<tên menu chính xác>';
DECLARE @MenuID   varchar(100), @ClassName varchar(200);

-- 1. Tìm MenuID từ tên (exact match VN)
SELECT TOP 1 @MenuID = MessageID FROM tblMD_Message
WHERE Content = @MenuName AND MessageID LIKE 'Mnu%' AND Language='VN';

SELECT @MenuID AS ResolvedMenuID;

-- 2. Lấy MEN_Menu info
SELECT m.MenuID, m.ClassName, m.AssemblyName, m.ParentMenuID,
       m.IsVisible, m.IsWeb, m.ViewOnWeb, m.isShowLayOutWeb,
       m.IsUseMobileDevice, m.glyphicon, m.URL
FROM MEN_Menu m WHERE m.MenuID = @MenuID;

SELECT TOP 1 @ClassName = ClassName FROM MEN_Menu WHERE MenuID = @MenuID;

-- 3-4. Verify proc + renderer cùng lúc
SELECT name, type_desc, modify_date FROM sys.objects
WHERE name IN (@ClassName, @ClassName + '_html')
ORDER BY name;

-- 5. (Bonus) Check HTML cache size nếu là HTML-rendered
SELECT TableName, LanguageID, ScreenType,
       DATALENGTH(html) AS HtmlBytes, Version
FROM tblHtmlScriptCache
WHERE TableName = @ClassName + '_html'
ORDER BY LanguageID;

-- 6. (Bonus) Lấy tên đa ngôn ngữ
SELECT MessageID, Language, Content FROM tblMD_Message
WHERE MessageID = @MenuID ORDER BY Language;
```

→ 1 lần `read_query` = đủ 5 bước. Nếu cell HTML quá lớn (> 8KB), xem [17_RendererHtmlJsSafe.md §8.4](17_RendererHtmlJsSafe.md) cho pattern SUBSTRING chunk / `export_query`.

---

## 4. Demo end-to-end

### 4.1. Demo failed lookup — "Đơn khiếu nại"

> Minh hoạ workflow khi menu KHÔNG tồn tại — đây là trường hợp rất hay gặp khi user gõ tên menu không chính xác hoặc menu thuộc module chưa triển khai.

**Bước 1 (exact)**:

```sql
SELECT TOP 20 MessageID, Language, Content FROM tblMD_Message
WHERE Content LIKE N'%Đơn khiếu nại%' AND MessageID LIKE 'Mnu%';
```
→ **0 row**.

**Broaden lần 1** — bỏ tiền tố "Đơn", chỉ giữ "khiếu nại":

```sql
SELECT TOP 50 MessageID, Language, Content FROM tblMD_Message
WHERE Content LIKE N'%khiếu nại%' ORDER BY MessageID;
```
→ Chỉ trả 7 row, **toàn bộ** là `MessageID` dạng `sp_*.<ColumnName>` — đây là label cột trong proc, KHÔNG phải `MenuID`. Vd: `sp_ProfitBonusAttendanceDiligenceList.DeductComplained = N'Trừ tiền   khách hàng khiếu nại'`.

**Broaden lần 2** — mở rộng từ đồng nghĩa (`phản ánh`, `kiến nghị`, `khiếu kiện`, `complain`, `grievance`, `feedback`):

```sql
SELECT TOP 50 MessageID, Language, Content FROM tblMD_Message
WHERE (Content LIKE N'%phản ánh%' OR Content LIKE N'%kiến nghị%'
       OR Content LIKE N'%khiếu kiện%' OR Content LIKE N'%complain%'
       OR Content LIKE N'%grievance%' OR Content LIKE N'%feedback%')
  AND MessageID LIKE 'Mnu%';
```
→ **0 row**.

**Liệt kê candidate gần nghĩa** — mọi menu visible bắt đầu "Đơn":

```sql
SELECT TOP 30 m.MenuID, m.ClassName, msg.Content
FROM MEN_Menu m
JOIN tblMD_Message msg ON msg.MessageID = m.MenuID AND msg.Language='VN'
WHERE msg.Content LIKE N'Đơn%' AND ISNULL(m.IsVisible,0)=1
ORDER BY m.MenuID;
```
→ Chỉ **1 row**: `MnuWPT023 / sp_ResignationLetter_Register / "Đơn xin nghỉ việc"`.

**Hành động chuẩn (Agent ĐÚNG)**:

> *"Menu **'Đơn khiếu nại'** không tồn tại trong DB. Đã tra:
> - Exact `'%Đơn khiếu nại%'` AND `MessageID LIKE 'Mnu%'` → 0 row.
> - Broaden `'%khiếu nại%'` → chỉ 7 label cột proc, không phải menu.
> - Đồng nghĩa (`phản ánh`, `kiến nghị`, `khiếu kiện`, `complain`, `grievance`, `feedback`) → 0 row.
>
> Menu duy nhất bắt đầu 'Đơn' và đang hoạt động: **`MnuWPT023 / Đơn xin nghỉ việc`**.
>
> Xin user xác nhận tên menu chính xác / cung cấp `MenuID` / chọn menu khác trong danh sách."*

**Hành động SAI (cần tránh)**:
- ❌ Đoán đại "có lẽ là Đơn xin nghỉ việc" rồi tiếp tục như user đã chọn.
- ❌ Tự tạo menu mới "Đơn khiếu nại" mà chưa được yêu cầu.
- ❌ Tự suy `ClassName` từ tên menu (kiểu `sp_DonKhieuNai_html`).
- ❌ Tự sinh thư-tự-tự-luận kiểu "thông thường ParadiseHR có menu khiếu nại nằm trong module WPT".

### 4.2. Demo successful — "Đơn xin nghỉ việc"

**Bước 1** — Tìm trong `tblMD_Message`:

```sql
SELECT TOP 5 MessageID, Language, Content FROM tblMD_Message
WHERE Content LIKE N'%Đơn xin nghỉ việc%' AND MessageID LIKE 'Mnu%';
```

Kết quả → 1 `MessageID = 'MnuWPT023'` với 3 ngôn ngữ:

| Language | Content |
|---|---|
| VN | Đơn xin nghỉ việc |
| EN | Resignation Letter Register |
| KR | 사직 신청 |

**Bước 2** — Join `MEN_Menu`:

```sql
SELECT m.MenuID, m.ClassName, m.AssemblyName, m.ParentMenuID, m.IsVisible,
       m.IsWeb, m.ViewOnWeb, m.isShowLayOutWeb, m.IsUseMobileDevice
FROM MEN_Menu m WHERE m.MenuID = 'MnuWPT023';
```

Kết quả:

| Cột | Giá trị |
|---|---|
| `MenuID` | MnuWPT023 |
| `ClassName` | sp_ResignationLetter_Register |
| `AssemblyName` | DataSetting |
| `ParentMenuID` | MnuWPT000 (Portal / WorkFlow) |
| `IsVisible` | 1 |
| `IsWeb` | 0 |
| `ViewOnWeb` | 0 |
| `isShowLayOutWeb` | 0 |
| `IsUseMobileDevice` | 1 |

→ Pattern cờ này khớp **menu Web HTML-rendered chuẩn** (so với [13_Migrate_Menu.md Rule 2](13_Migrate_Menu.md)).

**Bước 3** — `ClassName = sp_ResignationLetter_Register`.

**Bước 4** — Verify proc tồn tại:

```sql
SELECT name, type_desc, modify_date FROM sys.objects
WHERE name = 'sp_ResignationLetter_Register';
```

Kết quả: `type_desc = SQL_STORED_PROCEDURE`, `modify_date = 2025-09-26`. ✓

**Bước 5** — Tìm renderer `_html`:

```sql
SELECT name, type_desc, modify_date FROM sys.objects
WHERE name = 'sp_ResignationLetter_Register_html' AND type='P';
```

Kết quả: tồn tại, `modify_date = 2025-09-26`. ✓ → menu HTML-rendered hợp lệ.

**Bonus — Verify HTML cache đã build**:

```sql
SELECT TableName, LanguageID, DATALENGTH(html) AS HtmlBytes
FROM tblHtmlScriptCache
WHERE TableName = 'sp_ResignationLetter_Register_html';
```

Kết quả:

| LanguageID | HtmlBytes |
|---|---|
| EN | 57868 |
| VN | 57756 |

→ Cache đã build cho 2 ngôn ngữ, mỗi cache ~57KB.

**Kết luận của lookup**:

> Menu **"Đơn xin nghỉ việc"** = `MnuWPT023`, ClassName = `sp_ResignationLetter_Register` (proc wrapper), renderer = `sp_ResignationLetter_Register_html`. Để **sửa giao diện**: mở source `sp_ResignationLetter_Register_html` qua `OBJECT_DEFINITION` (do cache > 8KB → đọc qua `SUBSTRING` chunk theo [17 §10.4](17_RendererHtmlJsSafe.md)). Sau khi sửa: `EXEC sp_GenerateHTMLScript 'sp_ResignationLetter_Register_html'` để rebuild cache.

---

## 5. Xử lý 6 trường hợp đặc biệt

| # | Trường hợp | Triệu chứng | Cách xử lý |
|---|---|---|---|
| 1 | **0 match B1** | Bước 1 trả 0 row | Broaden LIKE → bỏ tiền tố → thử EN/KR → liệt kê candidate → **BÁO USER**, không đoán (xem [§4.1](#41-demo-failed-lookup--đơn-khiếu-nại)) |
| 2 | **Nhiều match B1** | Bước 1 trả >1 row | Liệt kê đầy đủ `MenuID` + `Content` + `ParentMenuID` + `IsVisible`, hỏi user chọn |
| 3 | **ClassName là VIEW** | B4 `type_desc='VIEW'` | Menu DataSetting grid kiểu cũ → sửa UI = sửa view + `tblDataSetting`/`tblDataSettingLayout`. **KHÔNG** có proc `_html` |
| 4 | **ClassName không có trong `sys.objects`** | B4 trả 0 row | (a) Menu form .NET (`AssemblyName='HPA.*'`) → giao diện nằm trong .NET assembly, không phải DB → user phải sửa code .NET. (b) Menu broken / deprecated → check [99_deprecated.md](99_deprecated.md) |
| 5 | **Có proc nhưng KHÔNG có `_html`** | B5 trả 0 row | Menu kiểu cũ — wrapper-only hoặc grid → check `tblDataSetting.IsProcedure` + `tblDataSetting.IsShowLayout` để biết loại |
| 6 | **Menu/proc trong [99_deprecated.md](99_deprecated.md)** | item nằm trong bảng deprecated | **KHÔNG dùng**. Báo user item đã lỗi thời, kèm lý do (nếu có) + hỏi xem có cần xử lý cleanup không |

Query check `tblDataSetting` cho trường hợp 5:

```sql
SELECT TOP 1 TableName, ViewName, IsProcedure, IsShowLayout,
             ColumnDataType, ColumnOrderBy, FormLayoutJS
FROM tblDataSetting WHERE TableName = '<ClassName>' OR ViewName = '<ClassName>';
```

---

## 6. Sau khi tìm được proc: bước tiếp theo

| Nhu cầu | File hướng dẫn |
|---|---|
| Sửa HTML/JS trong renderer `_html` | [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) (escape T-SQL/JS, MERGE cache 8 cột, Msg 257, polyfill 5 global helper) |
| Đọc source proc dài (> 8KB) | [17_RendererHtmlJsSafe.md §8.4](17_RendererHtmlJsSafe.md) (SUBSTRING chunk 4000 ký tự / `export_query` ra file) |
| Extract trọn renderer package để migrate | [17_RendererHtmlJsSafe.md §8.3](17_RendererHtmlJsSafe.md) (combo 8-query) |
| Migrate menu sang DB khác | [13_Migrate_Menu.md](13_Migrate_Menu.md) (script idempotent + 5 rule cấp quyền) |
| Tạo menu tương tự mới | [12_CreateMenu.md](12_CreateMenu.md) (quy trình 9 phase end-to-end) |
| Thiết kế UI theo chuẩn ParadiseStyle | [14_ParadiseStyle.md](14_ParadiseStyle.md) (token `--paradise-*`, `.paradise-*`, KHÔNG gọi `sp_MainStyleCSSParadise` trong renderer menu thông thường) |
| Refresh cache sau khi sửa | `EXEC sp_GenerateHTMLScript '<ClassName>_html';` + `EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>';` |

---

## 7. Quy tắc an toàn (BẤT BIẾN)

- ✅ Tool đọc cho phép: `mcp__mssql-vietinsoft__read_query`, `list_tables`, `describe_table`, `export_query`, `list_insights`.
- ❌ **KHÔNG** gọi `write_query` / `alter_table` / `create_table` / `drop_table` / `append_insight` khi user chưa yêu cầu rõ ràng câu này. Permission câu hỏi trước **không** kéo dài sang câu sau.
- ❌ **KHÔNG đoán** tên menu / proc nếu B1 trả 0 row — broaden + báo user (xem [§4.1](#41-demo-failed-lookup--đơn-khiếu-nại)).
- ✅ Luôn dùng `TOP N` / `WHERE` trong `read_query` — không bao giờ `SELECT *` toàn bảng lớn.
- ✅ Luôn check [99_deprecated.md](99_deprecated.md) trước khi đề xuất dùng tên item.
- ✅ Source proc dài (> 8KB) → đọc bằng `SUBSTRING` chunk hoặc `export_query` (xem [17 §10.4](17_RendererHtmlJsSafe.md)).
- ✅ Khi user yêu cầu sửa DB: build SQL script trong `SQL script/` cho user tự chạy — không dùng `write_query` để thực thi trực tiếp (xem [CLAUDE.md Bước 6](../CLAUDE.md)).

---

## Tham khảo bổ sung

| Topic | File |
|---|---|
| Logic menu nền tảng (5 mảnh dữ liệu) | [07_menu_system.md](07_menu_system.md) |
| Tạo menu Web mới end-to-end | [12_CreateMenu.md](12_CreateMenu.md) |
| Migrate/update menu có sẵn | [13_Migrate_Menu.md](13_Migrate_Menu.md) |
| Chuẩn thiết kế UI ParadiseStyle (4 layout gốc + token CSS) | [14_ParadiseStyle.md](14_ParadiseStyle.md) |
| Viết renderer HTML/JS an toàn (escape, MERGE cache, Msg 257) | [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) |
| MCP query template + extract renderer package | [17_RendererHtmlJsSafe.md §8](17_RendererHtmlJsSafe.md) |
| Item lỗi thời (table / proc / view / menu / parameter) | [99_deprecated.md](99_deprecated.md) |
| Quy tắc MCP đọc-only + TOP N + OBJECT_DEFINITION | [CLAUDE.md Bước 3](../CLAUDE.md) |
