# 17 — Skill: Viết Renderer HTML/JS an toàn, idempotent, portable cross-DB

> Dùng khi build/sửa renderer `sp_X_html` sinh HTML/CSS/JS lưu `tblHtmlScriptCache`, hoặc script render export sang DB khác.
>
> Mục tiêu: 1 Agent chỉ cần load file này là viết được renderer chuẩn — không vỡ quote boundary T-SQL, không Msg 257, không lỗi runtime sau export.
>
> Liên quan: [12](12_CreateMenu.md) tạo menu · [13](13_Migrate_Menu.md) migrate · [14](14_ParadiseStyle.md) CSS · [18](18_FindMenuProcedure.md) lookup menu→proc.

## Mục lục

1. [Quick Start (5 phút)](#1-quick-start-5-phút)
2. [7 quy tắc bắt buộc + Anatomy 6 layer](#2-7-quy-tắc-bắt-buộc--anatomy-6-layer)
3. [Pattern escape T-SQL → JavaScript](#3-pattern-escape-t-sql--javascript)
4. [Pattern config-driven (`tblCommonControlType_Signed`)](#4-pattern-config-driven-tblcommoncontroltype_signed)
5. [MERGE `tblHtmlScriptCache` (8 cột) + `varbinary(max)` (Msg 257)](#5-merge-tblhtmlscriptcache-8-cột--varbinarymax-msg-257)
6. [Checklist 15 điểm + Triệu chứng lỗi](#6-checklist-15-điểm--triệu-chứng-lỗi)
7. [Template renderer đầy đủ](#7-template-renderer-đầy-đủ)
8. [Truy vấn MCP để extract renderer từ DB](#8-truy-vấn-mcp-để-extract-renderer-từ-db)

---

## 1. Quick Start (5 phút)

### 7 quy tắc (1 dòng/rule)

1. **`N'...'`** — mọi `'` trong HTML/JS phải escape `''` hoặc dùng `&#039;`.
2. **CẤM `.replace(/''/g, ...)`** trong JS embed — vỡ N-string T-SQL. Dùng `.replace(/'/g, ...)`.
3. **Text VN/EN → JS** qua biến `*Js` đã escape — `REPLACE(REPLACE(@x, N'\', N'\\'), N'"', N'\"')`.
4. **`varbinary(max)` → `CAST(NULL AS VARBINARY(MAX))`** — KHÔNG `N''` (Msg 257).
5. **MERGE `tblHtmlScriptCache` đủ 8 cột**: `TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData`.
6. **UID `tblCommonControlType_Signed` deterministic** — không random.
7. **Idempotent**: `DROP IF EXISTS` cho proc, `DELETE` cache trước build, `MERGE` metadata.

### Template tối giản (copy-paste, fork rồi sửa)

```sql
CREATE OR ALTER PROCEDURE dbo.sp_X_html (@LoginID INT=3, @LanguageID VARCHAR(5)='VN', @isWeb INT=1)
AS BEGIN SET NOCOUNT ON;
    DECLARE @title   NVARCHAR(200) = N'Tiêu đề';
    DECLARE @empty   NVARCHAR(200) = N'Không có dữ liệu.';
    DECLARE @emptyJs NVARCHAR(400) = REPLACE(REPLACE(@empty, N'\', N'\\'), N'"', N'\"');

    DECLARE @html NVARCHAR(MAX) =
        N'<div id="xRoot"><h1>' + @title + N'</h1><div id="xBody"></div></div>'
      + N'<script>(function(){'
      + N'  var EMPTY_MSG = "' + @emptyJs + N'";'
      + N'  // ... gọi AjaxHPAParadise + render ...'
      + N'})();</script>';

    SELECT @html AS html;
END
```

→ Đi sâu: [§7 Template đầy đủ](#7-template-renderer-đầy-đủ) · [§6 Checklist 15 điểm](#6-checklist-15-điểm--triệu-chứng-lỗi)

---

## 2. 7 quy tắc bắt buộc + Anatomy 6 layer

### Khi nào dùng file này

- Build/sửa renderer `sp_X_html` lưu `tblHtmlScriptCache`.
- Script render export sang DB khác (DEV→UAT→PROD).
- Nhúng `hpaControl*` từ `tblCommonControlType_Signed` (config-driven).
- Gặp lỗi: `Incorrect syntax near 'function'/String`, Msg 257, `InstanceXXX is not defined`.

### 7 quy tắc (NEVER-SKIP)

| # | Quy tắc | Lý do |
|---|---|---|
| 1 | Mọi `'` trong HTML/JS embed escape `''` hoặc `&#039;` | T-SQL đóng N-string khi gặp `'` đơn |
| 2 | KHÔNG `.replace(/''/g, ...)` trong JS embed | T-SQL parse `''` thành `'` + chuỗi kế → vỡ boundary |
| 3 | Text VN/EN nhúng JS qua biến `*Js` đã escape `\` + `"` | Backslash + `"` trong text có thể vỡ JS string |
| 4 | `varbinary(max)` → `CAST(NULL AS VARBINARY(MAX))` (KHÔNG `N''`) | Msg 257 implicit conversion nvarchar → varbinary |
| 5 | MERGE `tblHtmlScriptCache` đủ 8 cột notnull | Lỗi `Cannot insert NULL into column 'html'` |
| 6 | UID `tblCommonControlType_Signed` deterministic | Renderer dynamic-SQL `(SELECT loadUI FROM ... WHERE UID='...')` cần UID stable |
| 7 | Script export idempotent (`DROP IF EXISTS`, `DELETE` cache trước build, `MERGE` metadata) | Chạy lần 2 trên DB đích phải không lỗi |

### Anatomy 6 layer

```
┌─ Layer 1: Signature  — @LoginID INT=3, @LanguageID VARCHAR(5)='VN', @isWeb INT=1
├─ Layer 2: Text VN/EN — DECLARE @title NVARCHAR(200) = N'...'; IF @LanguageID='EN' SET @title=N'...';
├─ Layer 3: Biến *Js   — DECLARE @titleJs = REPLACE(REPLACE(@title, N'\', N'\\'), N'"', N'\"');
├─ Layer 4: Build @html NVARCHAR(MAX) = N'<html>...<script>...</script>';
├─ Layer 5: MERGE tblHtmlScriptCache UPSERT theo (TableName, LanguageID)
└─ Layer 6: SELECT @html AS html  (fallback khi cache chưa có — framework gọi proc trực tiếp lần đầu)
```

---

## 3. Pattern escape T-SQL → JavaScript

### §3.1 Escape text label đa ngôn ngữ

```sql
DECLARE @empty   NVARCHAR(200) = N'Không có dữ liệu cho tháng này.';
DECLARE @emptyJs NVARCHAR(400) = REPLACE(REPLACE(@empty, N'\', N'\\'), N'"', N'\"');
```

- **Thứ tự BẮT BUỘC**: `\` TRƯỚC, rồi `"`. Đảo ngược sẽ double-escape backslash (`\` → `\\` → `\\\\`).
- Nối JS: `"' + @emptyJs + N'"` — đóng N-string T-SQL → concat biến → mở N-string lại.

### §3.2 Nháy đơn trong HTML inline — phân biệt 2 case

**Case A — JS string literal** (vd `<td style='...'>` inside `innerHTML`):

T-SQL `''` an toàn vì T-SQL parse `''` → `'` runtime; JS bao ngoài bằng `"..."` không xung đột.
```sql
SET @html = @html + N'html += "<td style=''padding:10px;''>" + value + "</td>";';
-- JS runtime: html += "<td style='padding:10px;'>" + value + "</td>";
```

**Case B — JS regex literal** (vd `.replace(/'/g, ...)`):

**TUYỆT ĐỐI KHÔNG** viết `.replace(/''/g, ...)` raw — pattern này có 2 `'` cạnh nhau giữa các slash, gây nhầm lẫn parser. Dùng unicode escape `'`:
```sql
SET @html = @html + N'.replace(/'/g, "&#039;")';
-- JS runtime: .replace(/'/g, "&#039;")   (JS regex engine: ' = ')
```

> Quy tắc tổng kết: JS string literal dùng `''`, JS regex literal dùng `'`.

### §3.3 Escape HTML output runtime (XSS-safe)

JS runtime cần escape 5 ký tự: `& < > " '` — regex literal `/'/g` phải dùng `'`:

```sql
SET @html = @html + N'function escapeHtml(value){'
          + N'  if(value === null || value === undefined) return "";'
          + N'  return String(value)'
          + N'    .replace(/&/g, "&amp;")'
          + N'    .replace(/</g, "&lt;").replace(/>/g, "&gt;")'
          + N'    .replace(/"/g, "&quot;")'
          + N'    .replace(/'/g, "&#039;");'
          + N'}';
```

### §3.4 Truyền biến số/chuỗi từ T-SQL sang JS

```sql
SET @html = @html + N'<script>'
          + N'  window.LoginID    = ' + CAST(@LoginID AS NVARCHAR(20)) + N';'
          + N'  window.LanguageID = "' + @LanguageID + N'";'
          + N'</script>';
```

- Số: `CAST(@n AS NVARCHAR(...))` rồi nối thẳng (không cần ngoặc).
- Chuỗi: bọc `"..."` (JS string literal).

### §3.5 Polyfill 5 global khi nhúng `hpaControl*` vào barebones HTML-rendered menu

Menu sinh từ `DataSetting`/`hpaControlGrid_Duc` được framework wrap kèm global helper. Nhúng `hpaControl*` riêng lẻ vào renderer barebones → helper KHÔNG có sẵn → `loadUI` gọi `loadDataSourceCommon(...)` → `undefined` → control "im lặng".

**Bắt buộc polyfill TRƯỚC khi inject `loadUI`** (5 global): `LoginID`, `LanguageID`, `loadDataSourceCommon`, `hpaUtils`, `RemoveToneMarks_Js`, `uiManager`.

```sql
SET @html = @html + N'<script>(function(){'
+ N'  if(typeof window.LoginID === "undefined")    window.LoginID    = ' + CAST(@LoginID AS NVARCHAR(20)) + N';'
+ N'  if(typeof window.LanguageID === "undefined") window.LanguageID = "' + @LanguageID + N'";'
+ N'  if(typeof window.loadDataSourceCommon === "undefined"){'
+ N'    window.loadDataSourceCommon = function(columnName, dataSourceSP, cb){'
+ N'      AjaxHPAParadise({'
+ N'        data: { name: dataSourceSP, param: ["LoginID", window.LoginID, "LanguageID", window.LanguageID] },'
+ N'        success: function(res){'
+ N'          var json = typeof res === "string" ? JSON.parse(res) : res;'
+ N'          var data = (json && json.data && json.data[0]) || [];'
+ N'          window["DataSource_" + columnName] = data;'
+ N'          if(json && json.dataSchema && json.dataSchema[0]){'
+ N'            window["DataSourceIDField_"   + columnName] = json.dataSchema[0][0] && json.dataSchema[0][0].name;'
+ N'            window["DataSourceNameField_" + columnName] = json.dataSchema[0][1] && json.dataSchema[0][1].name;'
+ N'          }'
+ N'          if(typeof cb === "function") cb(data, json);'
+ N'        }'
+ N'      });'
+ N'    };'
+ N'  }'
+ N'  if(typeof window.hpaUtils === "undefined"){'
+ N'    window.hpaUtils = { loadAvatar:function(){}, highlightText:function(t,s){return t;} };'
+ N'  }'
+ N'  if(typeof window.RemoveToneMarks_Js === "undefined"){'
+ N'    window.RemoveToneMarks_Js = function(s){'
+ N'      return String(s||"").normalize("NFD").replace(/[̀-ͯ]/g, "")'
+ N'        .replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase();'
+ N'    };'
+ N'  }'
+ N'  if(typeof window.uiManager === "undefined"){'
+ N'    window.uiManager = { showAlert: function(opt){ console.warn(opt); } };'
+ N'  }'
+ N'})();</script>';
```

> `saveFunction`, `updateOrDeleteDataExample` chỉ cần khi `AutoSave=1`. Menu `AutoSave=0` thì KHÔNG cần polyfill 2 hàm này.

---

## 4. Pattern config-driven (`tblCommonControlType_Signed`)

Áp dụng khi renderer dùng grid/form sinh từ `tblCommonControlType_Signed`. Tri thức nền: [12_CreateMenu.md §4](12_CreateMenu.md).

### 4.1 Renderer concat 3 mảnh

> CSS toàn cục đã inject sẵn từ 4 layout gốc — renderer KHÔNG ghép `@StyleHtml` ([14_ParadiseStyle.md Rule 2](14_ParadiseStyle.md)).

```sql
SET @html = N'
    <div id="<class>">
        <div id="<GridName>" style="height:100%;"></div>
    </div>
    <script>(() => {
        let DataSource = [];
        '
+ (SELECT loadUI FROM tblCommonControlType_Signed WHERE UID = '<grid_container_UID>') + N'
        window.currentRecordID_<ColumnIDName> = null;
        function ReloadData() {
            AjaxHPAParadise({
                data: { name: "<SPLoadData>", param: [] },
                success: function (res) {
                    const json    = typeof res === "string" ? JSON.parse(res) : res;
                    const results = Array.isArray(json?.data?.[0]) ? json.data[0] : (json?.data?.[0] ? [json.data[0]] : []);
                    const gridInstance = Instance<GridName><UID>;
                    const gridConfig   = window.getGridConfig_<GridName>(results);
                    gridInstance.beginUpdate();
                    gridInstance.option("paging.enabled",     true);
                    gridInstance.option("paging.pageSize",    gridConfig.pageSize);
                    gridInstance.option("pager.allowedPageSizes", gridConfig.allowedPageSizes);
                    gridInstance.option("dataSource",         results);
                    gridInstance.endUpdate();
                    DataSource = results;
                    '
+ (SELECT loadData FROM tblCommonControlType_Signed WHERE UID = '<grid_container_UID>') + N'
                }
            });
        }
        ReloadData();
    })();
    </script>';
SELECT @html AS html;
```

| Biến template | Lấy từ |
|---|---|
| `<class>` | Renderer name (`sp_HelloWorldVietinsoft_html`) — cũng là `TableName` metadata |
| `<GridName>` | `ColumnName` của row grid container (vd `GridEmployees`) |
| `<grid_container_UID>` | `UID` row grid container — **PHẢI deterministic** (vd `P00000000000000000000000000000G01`) |
| `<ColumnIDName>` | PK field name (vd `EmployeeID`) |
| `<SPLoadData>` | SP trả data grid (vd `sp_LoadHelloWorldVietinsoftEmployeeList`) |

### 4.2 Thứ tự deploy 7 bước (idempotent)

```
1. DELETE FROM tblCommonControlType_Signed WHERE TableName = '<class>_html';
2. INSERT metadata (UID DETERMINISTIC, html/loadUI/loadData NULL);
3. EXEC sptblCommonControlType_Signed_DUC '<class>_html';    -- populate html/loadUI/loadData
4. CREATE OR ALTER PROCEDURE <class>_html ...;               -- renderer trỏ UID
5. DELETE FROM tblHtmlScriptCache WHERE TableName = '<class>_html';
6. EXEC sp_GenerateHTMLScript '<class>_html';                -- build cache VN+EN
7. EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>';
```

> ⚠️ **DUC PHẢI EXEC TRƯỚC** khi tạo renderer — vì renderer dynamic-SQL cần `loadUI` đã có data. Đảo thứ tự → cache build với JS rỗng → runtime lỗi `InstanceXXX is not defined`.

### 4.3 Migrate sang DB khác — BẮT BUỘC mang theo metadata

Renderer dynamic-SQL đọc trực tiếp `tblCommonControlType_Signed` lúc build cache. DB đích thiếu data → chuỗi rỗng → JS lỗi runtime. Script migrate phải insert lại metadata UID deterministic trước EXEC DUC + `sp_GenerateHTMLScript`:

```sql
DELETE FROM tblCommonControlType_Signed WHERE TableName = '<class>_html';
INSERT INTO tblCommonControlType_Signed (TableName, ColumnName, Type, Layout, /* ... */, UID) VALUES
    ('<class>_html', 'GridX', 'hpaControlGrid_Duc', 'Grid_View', /* ... */, 'P00000000000000000000000000000G01'),
    /* ... */;
EXEC sptblCommonControlType_Signed_DUC '<class>_html';
DELETE FROM tblHtmlScriptCache WHERE TableName = '<class>_html';
EXEC sp_GenerateHTMLScript '<class>_html';
```

---

## 5. MERGE `tblHtmlScriptCache` (8 cột) + `varbinary(max)` (Msg 257)

### 5.1 MERGE pattern (8 cột notnull)

```sql
MERGE dbo.tblHtmlScriptCache AS tgt
USING (SELECT 'sp_X_html' AS TableName, @LanguageID AS LanguageID, '-1' AS ScreenType,
              @html AS html, N'' AS HtmlParadise, N'' AS paradiseJs,
              '1' AS Version, N'' AS VersionData) AS src
   ON tgt.TableName = src.TableName AND tgt.LanguageID = src.LanguageID
WHEN MATCHED THEN
    UPDATE SET tgt.ScreenType=src.ScreenType, tgt.html=src.html,
               tgt.HtmlParadise=src.HtmlParadise, tgt.paradiseJs=src.paradiseJs,
               tgt.Version=src.Version, tgt.VersionData=src.VersionData
WHEN NOT MATCHED BY TARGET THEN
    INSERT (TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData)
    VALUES (src.TableName, src.LanguageID, src.ScreenType, src.html, src.HtmlParadise, src.paradiseJs, src.Version, src.VersionData);
```

| Cột | Kiểu | Giá trị mặc định an toàn |
|---|---|---|
| `TableName` | varchar | `'sp_X_html'` |
| `LanguageID` | varchar(5) | `@LanguageID` (`'VN'`/`'EN'`) |
| `ScreenType` | varchar | `'-1'` |
| `html` | nvarchar(max) | `@html` |
| `HtmlParadise` | nvarchar(max) | `N''` (notnull) |
| `paradiseJs` | nvarchar(max) | `N''` (notnull) |
| `Version` | varchar | `'1'` |
| `VersionData` | nvarchar(max) | `N''` |

### 5.2 Cột `varbinary(max)` — Msg 257

Khi MERGE/INSERT vào `tblDataSetting` / `tblDataSettingLayout`, có các cột `varbinary(max)`. Truyền `N''` → lỗi:
```
Msg 257, Implicit conversion from nvarchar to varbinary(max) is not allowed.
```

**Cột `varbinary(max)` đã verify (2026-05-21):**

| Bảng | Cột `varbinary(max)` |
|---|---|
| `tblDataSetting` | `LayoutDataConfigFillter`, `LayoutParamConfig`, `LayoutDataConfigColumnView`, `LayoutDataConfigCardView`, `LayoutMobileLocalConfig` |
| `tblDataSettingLayout` | `BackgroundImage` |

**Quy tắc:**

| Kiểu cột | ✅ Đúng | ❌ Sai |
|---|---|---|
| `varbinary(max)` default NULL | `CAST(NULL AS VARBINARY(MAX))` hoặc `NULL` | `N''`, `''`, `0x` |
| `nvarchar(...)` default rỗng | `N''` | `NULL` (nếu notnull) |
| `bit` | `0` / `1` | `'0'` / `'1'` (string) |
| `int` | `0` | `NULL` (nếu notnull) |

---

## 6. Checklist 15 điểm + Triệu chứng lỗi

### 6.1 Checklist 15 điểm (đối chiếu trước khi export)

**Quote boundary (5):**
- [ ] 1. `<script>`, `function`, `String(...)`, `AjaxHPAParadise(...)` đều BÊN TRONG chuỗi `@html`. 
- [ ] 2. Không còn `.replace(/''/g` raw — đã đổi sang `.replace(/'/g, ...)` (Case B §3.2).
- [ ] 3. Mọi text label đa ngôn ngữ đi qua biến `*Js` đã escape `\` + `"`.
- [ ] 4. JS regex literal chứa `'` dùng `'`, JS string literal dùng `''`.

**Schema constraints (3):**
- [ ] 6. MERGE `tblHtmlScriptCache` fill đủ 8 cột notnull.
- [ ] 7. `varbinary(max)` dùng `CAST(NULL AS VARBINARY(MAX))`, không `N''`.
- [ ] 8. UID `tblCommonControlType_Signed` deterministic (`'P'+32 ký tự` cố định, không NULL).

**Thứ tự deploy (3):**
- [ ] 9. `EXEC sptblCommonControlType_Signed_DUC` TRƯỚC `CREATE OR ALTER` renderer (config-driven).
- [ ] 10. `DELETE FROM tblHtmlScriptCache` TRƯỚC `EXEC sp_GenerateHTMLScript`.
- [ ] 11. Renderer có `SELECT @html AS html` cuối (fallback khi cache chưa có).

**Idempotency (4):**
- [ ] 12. Script có `SET NOCOUNT ON; SET XACT_ABORT ON; GO` ở header.
- [ ] 13. Mọi proc dùng `CREATE OR ALTER` (hoặc DROP + CREATE).
- [ ] 14. Metadata (`MEN_Menu`, `tblSC_Object`, `tblDataSetting`, `tblDataSettingLayout`) dùng MERGE hoặc IF NOT EXISTS.
- [ ] 15. Có verify cuối: `SELECT DATALENGTH(html) FROM tblHtmlScriptCache WHERE TableName='<class>_html'`.

### 6.2 Triệu chứng → Nguyên nhân → Fix

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `Incorrect syntax near 'function'` / `String` / tên biến JS | Nháy đơn JS đóng N-string T-SQL sớm | Escape `''` hoặc `&#039;`; rà `.replace(/''/g)` |
| `Msg 257 Implicit conversion from nvarchar to varbinary(max)` | MERGE/INSERT `N''` vào cột `varbinary(max)` | `CAST(NULL AS VARBINARY(MAX))` |
| `InstanceXXX is not defined` runtime | Renderer build trước DUC → `loadUI` rỗng trong cache | Đảo thứ tự: metadata → DUC → renderer → cache |
| `Cannot insert NULL into column 'html'` | MERGE thiếu 1 trong 8 cột notnull | Fill đủ 8 cột |
| UI cache vẫn cũ sau khi sửa | Chưa DELETE cache trước build | `DELETE FROM tblHtmlScriptCache WHERE TableName='<class>_html'` trước `sp_GenerateHTMLScript` |
| `loadDataSourceCommon is not a function` (barebones menu) | Polyfill global thiếu | Áp pattern §3.5 |
| Tiếng Việt bị `???` trong cache | T-SQL string không có prefix `N'` | Mọi chuỗi VN phải `N'...'`, biến `NVARCHAR(MAX)` |
| Grid hiện nhưng không có data | `SPLoadData` sai tên / column SELECT không khớp `ColumnName` | Test `EXEC <SPLoadData> @LoginID=3` thủ công |
| `dataSource` không update khi `ReloadData` | Trỏ sai `Instance<GridName><UID>` — UID đổi giữa các lần chạy | UID deterministic, không random |

---

## 7. Template renderer đầy đủ

> Khung renderer hoàn chỉnh — fork + thay text/data API/class. Verified production: `sp_HelloWorldVietinsoft_html` ([update_menu_HelloWorldVietinsoft_employeelist_20260521.sql](../SQL%20script/update_menu_HelloWorldVietinsoft_employeelist_20260521.sql)) và `sp_CRM_Customers_html`.

```sql
SET NOCOUNT ON; SET XACT_ABORT ON;
GO

-- ============================================================
-- RENDERER sp_X_html — Skill 17 chuẩn
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_X_html (@LoginID INT=3, @LanguageID VARCHAR(5)='VN', @isWeb INT=1)
AS BEGIN
    SET NOCOUNT ON;

    -- Layer 2: Text VN/EN
    DECLARE @title    NVARCHAR(200), @subtitle NVARCHAR(300),
            @loading  NVARCHAR(100), @empty    NVARCHAR(200);

    IF @LanguageID = 'EN'
        SELECT @title=N'My Feature', @subtitle=N'English subtitle.', @loading=N'Loading...', @empty=N'No data.';
    ELSE
        SELECT @title=N'Tên tính năng', @subtitle=N'Mô tả tiếng Việt.', @loading=N'Đang tải...', @empty=N'Không có dữ liệu.';

    -- Layer 3: Biến *Js đã escape
    DECLARE @titleJs    NVARCHAR(400) = REPLACE(REPLACE(@title,    N'\', N'\\'), N'"', N'\"');
    DECLARE @subtitleJs NVARCHAR(600) = REPLACE(REPLACE(@subtitle, N'\', N'\\'), N'"', N'\"');
    DECLARE @loadingJs  NVARCHAR(200) = REPLACE(REPLACE(@loading,  N'\', N'\\'), N'"', N'\"');
    DECLARE @emptyJs    NVARCHAR(400) = REPLACE(REPLACE(@empty,    N'\', N'\\'), N'"', N'\"');

    -- Layer 4: HTML + JS
    DECLARE @html NVARCHAR(MAX) =
        N'<div id="xRoot" style="font-family:Segoe UI,Arial,sans-serif;padding:24px;">'
      + N'  <h1 style="margin:0 0 8px 0;">' + @title + N'</h1>'
      + N'  <p style="margin:0 0 18px 0;opacity:.85;">' + @subtitle + N'</p>'
      + N'  <div id="xBody">' + @loading + N'</div>'
      + N'</div>'
      + N'<script>(function(){'
      + N'  var EMPTY_MSG = "' + @emptyJs + N'";'
      + N'  function escapeHtml(v){'
      + N'    if(v === null || v === undefined) return "";'
      + N'    return String(v).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#039;");'
      + N'  }'
      + N'  function render(rows){'
      + N'    var body = document.getElementById("xBody");'
      + N'    if(!body) return;'
      + N'    if(!rows || rows.length === 0){ body.innerHTML = EMPTY_MSG; return; }'
      + N'    var html = "<ul>";'
      + N'    for(var i=0;i<rows.length;i++){ html += "<li>" + escapeHtml(rows[i].Name) + "</li>"; }'
      + N'    body.innerHTML = html + "</ul>";'
      + N'  }'
      + N'  AjaxHPAParadise({'
      + N'    data: { name: "sp_X_GetData", param: [] },'
      + N'    success: function(res){'
      + N'      try{'
      + N'        var json = typeof res === "string" ? JSON.parse(res) : res;'
      + N'        var rows = (json && json.data && Array.isArray(json.data)) ? (json.data[0] || []) : [];'
      + N'        render(rows);'
      + N'      } catch(e){ render([]); }'
      + N'    },'
      + N'    error: function(){ render([]); }'
      + N'  });'
      + N'})();</script>';

    -- Layer 5: UPSERT cache
    MERGE dbo.tblHtmlScriptCache AS tgt
    USING (SELECT 'sp_X_html' AS TableName, @LanguageID AS LanguageID, '-1' AS ScreenType,
                  @html AS html, N'' AS HtmlParadise, N'' AS paradiseJs,
                  '1' AS Version, N'' AS VersionData) AS src
       ON tgt.TableName = src.TableName AND tgt.LanguageID = src.LanguageID
    WHEN MATCHED THEN UPDATE SET tgt.ScreenType=src.ScreenType, tgt.html=src.html,
                                 tgt.HtmlParadise=src.HtmlParadise, tgt.paradiseJs=src.paradiseJs,
                                 tgt.Version=src.Version, tgt.VersionData=src.VersionData
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData)
        VALUES (src.TableName, src.LanguageID, src.ScreenType, src.html, src.HtmlParadise, src.paradiseJs, src.Version, src.VersionData);

    -- Layer 6: Fallback SELECT
    SELECT @html AS html;
END
GO

-- BUILD CACHE + VERIFY
DELETE FROM dbo.tblHtmlScriptCache WHERE TableName = 'sp_X_html';
EXEC dbo.sp_GenerateHTMLScript 'sp_X_html';
GO

SELECT TableName, LanguageID, ScreenType, DATALENGTH(html) AS HtmlBytes, Version
FROM dbo.tblHtmlScriptCache WHERE TableName = 'sp_X_html' ORDER BY LanguageID;
GO
```

---

## 8. Truy vấn MCP để extract renderer từ DB

> Đọc renderer từ DB nguồn (để rebuild script migrate, debug cache, copy menu sang DB khác). Trước khi extract: nếu chỉ có tên menu → resolve `ClassName`/`MenuID` qua [18_FindMenuProcedure.md](18_FindMenuProcedure.md).

### 8.1 Quick MCP (3 query phổ biến nhất)

```sql
-- 1. Tìm menu theo tên VN
SELECT TOP 50 MessageID, Language, Content FROM tblMD_Message WHERE Content LIKE N'%<tên>%';

-- 2. Đọc source procedure
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_X_html')) AS Source;

-- 3. Check size HTML cache TRƯỚC khi đọc full (tránh truncate)
SELECT TableName, LanguageID, DATALENGTH(html) AS Bytes
FROM tblHtmlScriptCache WHERE TableName = 'sp_X_html';
```

### 8.2 Bộ tool MCP — quy tắc bất biến

| Tool | Mục đích |
|---|---|
| `list_tables` | Liệt kê bảng/view |
| `describe_table` | Schema 1 bảng — verify cột notnull/varbinary trước MERGE |
| `read_query` | Query SELECT bất kỳ — đọc data, source proc (`OBJECT_DEFINITION`) |
| `export_query` | Xuất kết quả ra file (data > 8 KB) |

**Bất biến (BẮT BUỘC):**
- ❌ KHÔNG gọi `write_query` / `alter_table` / `create_table` / `drop_table` / `append_insight` khi user chưa yêu cầu rõ ràng **trong câu hỏi hiện tại** (permission câu trước không kéo dài).
- `read_query` LUÔN có `TOP N` / `WHERE` — không `SELECT *` toàn bảng lớn.
- User yêu cầu sửa DB → build SQL script trong `SQL script/` cho user chạy, KHÔNG `write_query` trực tiếp ([CLAUDE.md](../CLAUDE.md)).

### 8.3 Combo "Extract renderer package" — 1 menu trong 1 lượt

```sql
DECLARE @MenuID varchar(100) = 'MnuXXX';
DECLARE @ClassName varchar(200);
SELECT TOP 1 @ClassName = ClassName FROM MEN_Menu WHERE MenuID = @MenuID;

-- 1. Metadata
SELECT TOP 1 MenuID, ClassName, AssemblyName, ParentMenuID, Priority,
             IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb, IsUseMobileDevice, isShowInMobileLayOut,
             glyphicon, GroupID
FROM MEN_Menu WHERE MenuID = @MenuID;

-- 2. tblSC_Object (quyền)
SELECT TOP 5 ObjectID, ObjectName, Description, ParentObjectID
FROM tblSC_Object WHERE Description = @MenuID;

-- 3. Đa ngôn ngữ
SELECT TOP 10 MessageID, Language, Content
FROM tblMD_Message WHERE MessageID = @MenuID ORDER BY Language;

-- 4. tblDataSetting
SELECT TOP 1 TableName, ViewName, IsProcedure, IsShowLayout,
             ColumnOrderBy, ColumnDataType, ControlHiddenInShowLayout, FormLayoutJS
FROM tblDataSetting WHERE TableName = @ClassName;

-- 5. tblDataSettingLayout (root + lblhtml)
SELECT TOP 10 TableName, Name, ControlName, NamePa, Type, ControlType, Lx, Ly, Sx, Sy, WidthPercentage
FROM tblDataSettingLayout WHERE TableName = @ClassName ORDER BY Name;

-- 6. Source wrapper + renderer
SELECT name, OBJECT_DEFINITION(object_id) AS Source
FROM sys.objects
WHERE name IN (@ClassName, @ClassName+'_html') AND type='P';

-- 7. HTML cache size
SELECT TableName, LanguageID, ScreenType, DATALENGTH(html) AS HtmlBytes, Version
FROM tblHtmlScriptCache WHERE TableName = @ClassName + '_html' ORDER BY LanguageID;

-- 8. tblCommonControlType_Signed (nếu config-driven)
SELECT TOP 50 TableName, ColumnName, Type, Layout, DataSourceSP, SPLoadData,
              ColumnIDName, TableEditor, DisplayName, GridColumnName, GridWidth,
              AllowSorting, AllowFiltering, UID
FROM tblCommonControlType_Signed WHERE TableName = @ClassName + '_html' ORDER BY UID;
```

### 8.4 Đọc cột `nvarchar(max)` lớn (HTML cache > 8 KB)

MCP có thể truncate response khi cell quá lớn. 3 cách:

**Cách A — `SUBSTRING` chunk** (đọc nhiều lần `read_query`):
```sql
SELECT SUBSTRING(html,     1, 4000) AS Chunk1,
       SUBSTRING(html,  4001, 4000) AS Chunk2,
       SUBSTRING(html,  8001, 4000) AS Chunk3,
       SUBSTRING(html, 12001, 4000) AS Chunk4
FROM tblHtmlScriptCache WHERE TableName='sp_X_html' AND LanguageID='VN';
```

**Cách B — `export_query`** xuất ra file (an toàn cho data > 30 KB).

**Cách C — KHUYẾN NGHỊ cho migrate**: KHÔNG kéo HTML lớn — port source proc qua `CREATE OR ALTER PROCEDURE` (source ngắn), DB đích chạy lại `sp_GenerateHTMLScript` để tự build cache mới. Đây là pattern mặc định trong [§7 Template](#7-template-renderer-đầy-đủ).

### 8.5 Workflow "migrate menu X"

```
1. read_query LIKE          → Tìm MenuID từ tên/keyword
2. read_query combo §8.3    → 8 mảnh metadata + source + cache size
3. describe_table           → Verify cột notnull/varbinary 3 bảng metadata
4. read_query SUBSTRING     → Đọc full source nếu truncate
5. Quyết định bring HTML    → Cách A/B (copy cache) HAY Cách C (rebuild — khuyến nghị)
6. Build script SQL/        → Theo template §7
7. KHÔNG tự chạy            → User review
```

---

## Tham khảo bổ sung

| Chủ đề | File |
|---|---|
| Luồng tạo menu end-to-end | [12_CreateMenu.md](12_CreateMenu.md) |
| Luồng migrate menu | [13_Migrate_Menu.md](13_Migrate_Menu.md) |
| Chuẩn thiết kế UI (ParadiseStyle, CSS) | [14_ParadiseStyle.md](14_ParadiseStyle.md) |
| Tri thức nền menu (5 mảnh, HTML cache) | [07_menu_system.md](07_menu_system.md) |
| Phân quyền (LoginID = 3) | [11_permissions.md](11_permissions.md) |
| Cờ 3 nền tảng Desktop/Web/Mobile | [01_architecture.md](01_architecture.md) |
| MCP query (đọc-only, TOP N, `OBJECT_DEFINITION`) | [CLAUDE.md Bước 3](../CLAUDE.md) |
