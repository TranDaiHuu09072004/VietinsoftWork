# 17 — Skill: Viết Renderer HTML/JS an toàn, idempotent, portable cross-DB

> **Skill file** — dùng khi build/sửa renderer `sp_X_html` sinh HTML/CSS/JS lưu vào `tblHtmlScriptCache`, hoặc khi script render được export gửi cho user chạy trên DB khác (DEV → UAT → PROD).
>
> Mục tiêu: 1 Agent (kể cả model context nhỏ, suy luận yếu) chỉ cần load đúng file này là viết được renderer chuẩn — không vi phạm quote boundary T-SQL, không lỗi Msg 257, không lỗi runtime sau khi export.
>
> Liên kết bắt buộc đọc kèm: [12_CreateMenu.md](12_CreateMenu.md) (luồng tạo menu end-to-end), [13_Migrate_Menu.md](13_Migrate_Menu.md) (luồng migrate menu), [14_ParadiseStyle.md](14_ParadiseStyle.md) (chuẩn CSS).

---

## ⚡ QUICK START (5 phút — đủ làm việc)

### 7 quy tắc bắt buộc (1 dòng/rule)

1. **N'...'** — mọi nháy đơn trong HTML/JS phải escape `''` hoặc dùng `&#039;`.
2. **CẤM `.replace(/''/g, ...)` trong JS embed** — vỡ N-string T-SQL.
3. **Text VN/EN → JS bắt buộc qua biến `*Js` đã escape** — `REPLACE(REPLACE(@x, N'\', N'\\'), N'"', N'\"')`.
4. **Cột `varbinary(max)` → `CAST(NULL AS VARBINARY(MAX))`** — KHÔNG `N''` (lỗi Msg 257).
5. **MERGE `tblHtmlScriptCache` đủ 8 cột notnull**: `TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData`.
6. **UID `tblCommonControlType_Signed` deterministic** — không để proc tự sinh UID random.
7. **Idempotent**: `DROP IF EXISTS` cho proc, `DELETE` cache trước build, `MERGE` cho metadata.

### Template renderer tối giản (copy-paste, fork rồi sửa)

```sql
CREATE OR ALTER PROCEDURE dbo.sp_X_html
(
    @LoginID    INT          = 3,
    @LanguageID VARCHAR(5)   = 'VN',
    @isWeb      INT          = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @title   NVARCHAR(200) = N'Tiêu đề';
    DECLARE @empty   NVARCHAR(200) = N'Không có dữ liệu.';
    DECLARE @emptyJs NVARCHAR(400) = REPLACE(REPLACE(@empty, N'\', N'\\'), N'"', N'\"');

    DECLARE @html NVARCHAR(MAX) =
        N'<div id="xRoot"><h1>' + @title + N'</h1><div id="xBody"></div></div>'
      + N'<script>(function(){'
      + N'  var EMPTY_MSG = "' + @emptyJs + N'";'
      + N'  // ... gọi AjaxHPAParadise + render ...'
      + N'})();</script>';

    MERGE dbo.tblHtmlScriptCache AS tgt
    USING (SELECT 'sp_X_html' AS TableName, @LanguageID AS LanguageID,
                  '-1' AS ScreenType, @html AS html,
                  N'' AS HtmlParadise, N'' AS paradiseJs,
                  '1' AS Version, N'' AS VersionData) AS src
       ON tgt.TableName = src.TableName AND tgt.LanguageID = src.LanguageID
    WHEN MATCHED THEN
        UPDATE SET tgt.ScreenType   = src.ScreenType,
                   tgt.html         = src.html,
                   tgt.HtmlParadise = src.HtmlParadise,
                   tgt.paradiseJs   = src.paradiseJs,
                   tgt.Version      = src.Version,
                   tgt.VersionData  = src.VersionData
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData)
        VALUES (src.TableName, src.LanguageID, src.ScreenType, src.html, src.HtmlParadise, src.paradiseJs, src.Version, src.VersionData);

    SELECT @html AS html;
END
```

→ Đi sâu: [§9 Template đầy đủ](#9-template-đầy-đủ-copy-paste-ready) · [§7 Checklist 15 điểm](#7-checklist-15-điểm-trước-khi-export-script)

---

## §0. Khi nào dùng file này

- Khi build/sửa renderer `sp_X_html` sinh HTML/CSS/JS lưu vào `tblHtmlScriptCache`.
- Khi script render được export, gửi cho user chạy trên DB khác.
- Khi nhúng `hpaControl*` từ `tblCommonControlType_Signed` vào renderer (config-driven).
- Khi gặp lỗi `Incorrect syntax near 'function'` / `String` / Msg 257 / `InstanceXXX is not defined`.

---

## §1. 7 quy tắc bắt buộc (NEVER-SKIP)

| # | Quy tắc | Lý do |
|---|---|---|
| 1 | Mọi `'` trong HTML/JS embed phải escape `''` (T-SQL parse → 1 dấu `'` runtime) hoặc dùng `&#039;` | T-SQL đóng N-string khi gặp `'` đơn |
| 2 | KHÔNG dùng `.replace(/''/g, ...)` trong JS embed | T-SQL parse `''` thành `'` + chuỗi kế tiếp → vỡ boundary |
| 3 | Text VN/EN nhúng vào JS phải qua biến `*Js` đã escape `\` + `"` | Backslash, dấu ngoặc kép trong text có thể vỡ JS string |
| 4 | Cột `varbinary(max)` dùng `CAST(NULL AS VARBINARY(MAX))` — KHÔNG `N''` | Msg 257 "Implicit conversion from nvarchar to varbinary(max)" |
| 5 | MERGE `tblHtmlScriptCache` đủ 8 cột notnull | Lỗi `Cannot insert NULL into column 'html'` nếu thiếu |
| 6 | UID `tblCommonControlType_Signed` deterministic, không random | Renderer dynamic-SQL `(SELECT loadUI FROM ... WHERE UID='...')` cần UID stable |
| 7 | Script export phải idempotent (`DROP IF EXISTS`, `DELETE` trước build, `MERGE` metadata) | Chạy lần 2 trên DB đích phải không lỗi |

---

## §2. Anatomy của renderer chuẩn (6 layer)

```
┌─ Layer 1: Khai báo signature
│   @LoginID INT = 3, @LanguageID VARCHAR(5) = 'VN', @isWeb INT = 1
│   (Default = 3 / 'VN' để debug-friendly trên DB khác)
├─ Layer 2: Khai báo biến text VN/EN
│   DECLARE @title NVARCHAR(200) = N'...';
│   IF @LanguageID = 'EN' SET @title = N'...';
├─ Layer 3: Khai báo biến *Js đã escape
│   DECLARE @titleJs NVARCHAR(400) = REPLACE(REPLACE(@title, N'\', N'\\'), N'"', N'\"');
├─ Layer 4: Build @html NVARCHAR(MAX) = N'<html>...<script>...</script>';
├─ Layer 5: MERGE tblHtmlScriptCache UPSERT theo (TableName, LanguageID)
└─ Layer 6: SELECT @html AS html
    (Fallback khi cache chưa có — framework gọi proc trực tiếp lần đầu)
```

---

## §3. Pattern escape T-SQL → JavaScript (step-by-step)

### §3.1. Escape text label đa ngôn ngữ

```sql
DECLARE @empty   NVARCHAR(200) = N'Không có dữ liệu cho tháng này.';
DECLARE @emptyJs NVARCHAR(400) =
    REPLACE(REPLACE(@empty, N'\', N'\\'), N'"', N'\"');
```

- **Thứ tự bắt buộc**: `\` trước, rồi `"`. Đảo ngược sẽ double-escape backslash (`\` → `\\` → `\\\\`).
- Nối vào JS: `"' + @emptyJs + N'"` — đóng N-string T-SQL → concat biến → mở N-string lại.

### §3.2. Escape nháy đơn trong HTML inline (JS string literal vs JS regex literal)

**2 trường hợp KHÁC NHAU — phải phân biệt rõ**:

#### Case A — Nháy đơn nằm trong JS **string literal** (vd `<td style='...'>` inside `innerHTML`)

T-SQL `''` escape là an toàn vì T-SQL parse `''` thành 1 dấu `'` runtime. JS string literal dùng `"..."` bao ngoài nên không xung đột.

```sql
-- T-SQL viết:
SET @html = @html + N'html += "<td style=''padding:10px;''>" + value + "</td>";';

-- JS runtime sau khi T-SQL parse:
-- html += "<td style='padding:10px;'>" + value + "</td>";
```

#### Case B — Nháy đơn nằm trong JS **regex literal** (vd `.replace(/'/g, ...)`)

**TUYỆT ĐỐI KHÔNG** viết `.replace(/''/g, ...)` raw — pattern này có 2 nháy đơn cạnh nhau giữa các slash, dễ bị parser T-SQL/IDE/editor highlight sai và dễ gây nhầm lẫn khi đọc/sửa script. **Dùng `'`** (unicode escape):

```sql
-- T-SQL viết (an toàn 100%):
SET @html = @html + N'.replace(/'/g, "&#039;")';

-- JS runtime sau khi T-SQL parse:
-- .replace(/'/g, "&#039;")
-- JS regex engine interpret ' = '
```

→ Quy tắc tổng kết: JS string literal dùng `''`, JS regex literal dùng `'`.

### §3.3. Khi cần escape HTML output runtime (XSS-safe)

JS runtime cần (lý thuyết):

```javascript
function escapeHtml(value){
    if(value === null || value === undefined) return "";
    return String(value)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;");
}
```

Trong T-SQL phải viết với regex literal `/`/g` dùng unicode escape `'` (Case B §3.2):

```sql
SET @html = @html + N'function escapeHtml(value){'
          + N'  if(value === null || value === undefined) return "";'
          + N'  return String(value)'
          + N'    .replace(/&/g, "&amp;")'
          + N'    .replace(/</g, "&lt;")'
          + N'    .replace(/>/g, "&gt;")'
          + N'    .replace(/"/g, "&quot;")'
          + N'    .replace(/'/g, "&#039;");'
          + N'}';
```

- 5 ký tự bắt buộc thoát: `& < > " '`.
- Regex literal `/'/g` viết là `/'/g` trong T-SQL — JS parse `'` thành `'`.

### §3.4. Truyền biến số/chuỗi từ T-SQL sang JS

```sql
SET @html = @html + N'<script>'
          + N'  window.LoginID    = ' + CAST(@LoginID AS NVARCHAR(20)) + N';'
          + N'  window.LanguageID = "' + @LanguageID + N'";'
          + N'</script>';
```

- Số: `CAST(@n AS NVARCHAR(...))` rồi nối thẳng (không cần dấu ngoặc).
- Chuỗi: bọc `"..."` (JS string literal).

### §3.5. Polyfill global helper khi nhúng `hpaControl*` vào barebones HTML-rendered menu

Các menu sinh ra bằng `DataSetting`/`hpaControlGrid_Duc` được framework wrapper render kèm bộ global JS helper. Khi nhúng `hpaControl*` riêng lẻ vào menu HTML-rendered đơn giản (không dùng wrapper full), các helper KHÔNG có sẵn → `loadUI` gọi `loadDataSourceCommon(...)` → `undefined` → control "im lặng" / dropdown rỗng / select trống.

**Bắt buộc polyfill 5 global trong bootstrap `<script>` của renderer, TRƯỚC khi inject `loadUI`**:

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
+ N'    window.hpaUtils = {'
+ N'      loadAvatar: function(){},'
+ N'      highlightText: function(text, search){ return text; }'
+ N'    };'
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

⚠️ **Lưu ý**: `saveFunction`, `updateOrDeleteDataExample` chỉ cần khi `AutoSave=1`. Menu sample đặt `AutoSave=0` thì KHÔNG cần polyfill 2 hàm này.

---

## §4. Pattern config-driven (dynamic SQL nhúng `loadUI` / `loadData`)

Áp dụng khi renderer dùng grid/form sinh từ `tblCommonControlType_Signed` (xem [12_CreateMenu.md §3.1](12_CreateMenu.md) để hiểu nhánh này).

### §4.1. Renderer concat 3 mảnh (T-SQL static + 2 dynamic SQL subquery)

> Lưu ý: CSS toàn cục đã inject sẵn từ 4 layout gốc — renderer KHÔNG cần ghép `@StyleHtml` ở đầu (xem [14_ParadiseStyle.md Rule 2](14_ParadiseStyle.md)).

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
                    const json = typeof res === "string" ? JSON.parse(res) : res;
                    const results = Array.isArray(json?.data?.[0]) ? json.data[0] : (json?.data?.[0] ? [json.data[0]] : []);
                    const gridInstance = Instance<GridName><UID>;
                    const gridConfig   = window.getGridConfig_<GridName>(results);
                    gridInstance.beginUpdate();
                    gridInstance.option("paging.enabled", true);
                    gridInstance.option("paging.pageSize", gridConfig.pageSize);
                    gridInstance.option("pager.allowedPageSizes", gridConfig.allowedPageSizes);
                    gridInstance.option("dataSource", results);
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
| `<class>` | Tên renderer (`sp_HelloWorldVietinsoft_html`) — cũng là `TableName` trong metadata |
| `<GridName>` | `ColumnName` của row grid container (vd `GridEmployees`) |
| `<grid_container_UID>` | `UID` của row grid container — **PHẢI deterministic** (vd `P00000000000000000000000000000G01`) |
| `<ColumnIDName>` | Tên PK row (vd `EmployeeID`) |
| `<SPLoadData>` | Tên SP trả data grid (vd `sp_LoadHelloWorldVietinsoftEmployeeList`) |

### §4.2. Thứ tự deploy đúng (7 bước idempotent)

```
1. DELETE FROM tblCommonControlType_Signed WHERE TableName = '<class>_html';
2. INSERT các row metadata (UID DETERMINISTIC, html/loadUI/loadData để NULL);
3. EXEC sptblCommonControlType_Signed_DUC '<class>_html';   -- populates html/loadUI/loadData
4. CREATE OR ALTER PROCEDURE <class>_html ...;              -- renderer trỏ UID
5. DELETE FROM tblHtmlScriptCache WHERE TableName = '<class>_html';
6. EXEC sp_GenerateHTMLScript '<class>_html';               -- build cache VN + EN
7. EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>';
```

> ⚠️ **Phải EXEC `sptblCommonControlType_Signed_DUC` TRƯỚC khi tạo renderer**, vì renderer dynamic-SQL `(SELECT loadUI FROM tblCommonControlType_Signed WHERE UID='...')` cần cột `loadUI` đã có data. Đảo thứ tự → cache build với JS rỗng → lỗi runtime `InstanceXXX is not defined`.

### §4.3. Khi migrate sang DB khác — BẮT BUỘC mang theo data `tblCommonControlType_Signed`

Renderer dynamic-SQL đọc trực tiếp từ `tblCommonControlType_Signed` lúc build cache. DB đích thiếu data → chuỗi rỗng → JS lỗi runtime. **Script migrate phải insert lại metadata với UID deterministic** trước khi `EXEC sptblCommonControlType_Signed_DUC` + `sp_GenerateHTMLScript`.

```sql
-- 1. Xoá metadata cũ
DELETE FROM tblCommonControlType_Signed WHERE TableName = '<class>_html';

-- 2. Insert lại với UID deterministic (không để NULL — proc tự sinh UID random sẽ phá liên kết)
INSERT INTO tblCommonControlType_Signed (TableName, ColumnName, Type, Layout, ..., UID) VALUES
    ('<class>_html', 'GridX', 'hpaControlGrid_Duc', 'Grid_View', ..., 'P00000000000000000000000000000G01'),
    ...;

-- 3. EXEC để populate html/loadUI/loadData
EXEC sptblCommonControlType_Signed_DUC '<class>_html';

-- 4. Build cache
DELETE FROM tblHtmlScriptCache WHERE TableName = '<class>_html';
EXEC sp_GenerateHTMLScript '<class>_html';
```

---

## §5. Pattern MERGE `tblHtmlScriptCache` (8 cột notnull)

Renderer **bắt buộc** tự upsert cache bằng `MERGE` theo `(TableName, LanguageID)` và fill đủ 8 cột notnull:

```sql
MERGE dbo.tblHtmlScriptCache AS tgt
USING (SELECT
          'sp_X_html'    AS TableName,
          @LanguageID    AS LanguageID,
          '-1'           AS ScreenType,
          @html          AS html,
          N''            AS HtmlParadise,
          N''            AS paradiseJs,
          '1'            AS Version,
          N''            AS VersionData) AS src
   ON tgt.TableName = src.TableName AND tgt.LanguageID = src.LanguageID
WHEN MATCHED THEN
    UPDATE SET tgt.ScreenType   = src.ScreenType,
               tgt.html         = src.html,
               tgt.HtmlParadise = src.HtmlParadise,
               tgt.paradiseJs   = src.paradiseJs,
               tgt.Version      = src.Version,
               tgt.VersionData  = src.VersionData
WHEN NOT MATCHED BY TARGET THEN
    INSERT (TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData)
    VALUES (src.TableName, src.LanguageID, src.ScreenType, src.html, src.HtmlParadise, src.paradiseJs, src.Version, src.VersionData);
```

| Cột | Kiểu | Giá trị mặc định an toàn |
|---|---|---|
| `TableName` | varchar(...) | `'sp_X_html'` |
| `LanguageID` | varchar(5) | `@LanguageID` ('VN' / 'EN') |
| `ScreenType` | varchar(...) | `'-1'` (mặc định cho HTML-rendered) |
| `html` | nvarchar(max) | `@html` (nội dung HTML/JS) |
| `HtmlParadise` | nvarchar(max) | `N''` (notnull, không dùng) |
| `paradiseJs` | nvarchar(max) | `N''` (notnull, không dùng) |
| `Version` | varchar(...) | `'1'` |
| `VersionData` | nvarchar(max) | `N''` |

---

## §6. Pattern các cột `varbinary(max)` (lỗi Msg 257)

Khi `MERGE` / `INSERT` vào `tblDataSetting` hoặc `tblDataSettingLayout`, có các cột kiểu `varbinary(max)`. Nếu truyền `N''` (kiểu `nvarchar`) → lỗi:

```
Msg 257, Level 16, State 3
Implicit conversion from data type nvarchar to varbinary(max) is not allowed.
Use the CONVERT function to run this query.
```

**Danh sách cột `varbinary(max)` đã xác minh từ DB (2026-05-21)**:

| Bảng | Cột `varbinary(max)` |
|---|---|
| `tblDataSetting` | `LayoutDataConfigFillter`, `LayoutParamConfig`, `LayoutDataConfigColumnView`, `LayoutDataConfigCardView`, `LayoutMobileLocalConfig` |
| `tblDataSettingLayout` | `BackgroundImage` |

**Quy tắc**:

| Kiểu cột | ✅ Cách đúng | ❌ Cách sai |
|---|---|---|
| `varbinary(max)` (default NULL) | `CAST(NULL AS VARBINARY(MAX))` hoặc `NULL` trực tiếp | `N''`, `''`, `0x` |
| `nvarchar(...)` (default rỗng) | `N''` | `NULL` (nếu cột notnull) |
| `bit` | `0` / `1` | `'0'` / `'1'` (string) |
| `int` | `0` | `NULL` (nếu cột notnull) |

Ví dụ MERGE đúng:

```sql
MERGE dbo.tblDataSetting AS tgt
USING (SELECT @ClassName AS TableName,
              N'' AS ReadOnlyColumns,
              CAST(NULL AS VARBINARY(MAX)) AS LayoutDataConfigFillter,
              CAST(NULL AS VARBINARY(MAX)) AS LayoutParamConfig,
              -- ...
              1 AS IsProcedure,
              1 AS IsShowLayout) AS src
   ON tgt.TableName = src.TableName
WHEN MATCHED THEN UPDATE SET ...
WHEN NOT MATCHED BY TARGET THEN INSERT (...) VALUES (...);
```

---

## §7. Checklist 15 điểm trước khi export script

Agent tự đối chiếu trước khi giao file SQL cho user:

### Quote boundary (5 điểm)
- [ ] 1. `<script>`, `function`, `String(...)`, `AjaxHPAParadise(...)` đều nằm BÊN TRONG chuỗi `@html`.
- [ ] 2. `MERGE dbo.tblHtmlScriptCache` nằm BÊN NGOÀI chuỗi `@html`.
- [ ] 3. Không còn pattern `.replace(/''/g` raw — đã đổi sang `.replace(/'/g, ...)` (Case B §3.2).
- [ ] 4. Mọi text label đa ngôn ngữ đều đi qua biến `*Js` đã escape `\` + `"`.
- [ ] 5. JS regex literal chứa nháy đơn dùng unicode escape `'`, JS string literal dùng `''` T-SQL escape.

### Schema constraints (3 điểm)
- [ ] 6. MERGE `tblHtmlScriptCache` fill đủ 8 cột notnull.
- [ ] 7. Cột `varbinary(max)` dùng `CAST(NULL AS VARBINARY(MAX))`, không phải `N''`.
- [ ] 8. UID `tblCommonControlType_Signed` deterministic (chuỗi `'P' + 32 ký tự` cố định, không NULL).

### Thứ tự deploy (3 điểm)
- [ ] 9. `EXEC sptblCommonControlType_Signed_DUC` chạy TRƯỚC `CREATE OR ALTER` renderer (nếu config-driven).
- [ ] 10. `DELETE FROM tblHtmlScriptCache` chạy TRƯỚC `EXEC sp_GenerateHTMLScript`.
- [ ] 11. Renderer có `SELECT @html AS html` ở cuối (fallback khi cache chưa có).

### Idempotency (4 điểm)
- [ ] 12. Script có `SET NOCOUNT ON; SET XACT_ABORT ON; GO` ở header.
- [ ] 13. Mọi proc dùng `CREATE OR ALTER` (hoặc `IF OBJECT_ID(...) IS NOT NULL DROP` rồi `CREATE`).
- [ ] 14. Metadata (`MEN_Menu`, `tblSC_Object`, `tblDataSetting`, `tblDataSettingLayout`) dùng `MERGE` hoặc `IF NOT EXISTS INSERT ELSE UPDATE`.
- [ ] 15. Có block verify cuối: `SELECT DATALENGTH(html) FROM tblHtmlScriptCache WHERE TableName='<class>_html'`.

---

## §8. Triệu chứng lỗi → nguyên nhân → fix

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| `Incorrect syntax near 'function'` / `String` / tên biến JS | Nháy đơn JS đóng N-string T-SQL sớm | Escape `''` hoặc `&#039;`; rà `.replace(/''/g)` |
| `Msg 257 Implicit conversion from nvarchar to varbinary(max)` | MERGE/INSERT truyền `N''` vào cột `varbinary(max)` | Dùng `CAST(NULL AS VARBINARY(MAX))` |
| `InstanceXXX is not defined` runtime | Renderer build trước `EXEC sptblCommonControlType_Signed_DUC` → `loadUI` rỗng trong cache | Đảo thứ tự: metadata → DUC → renderer → cache |
| `Cannot insert NULL into column 'html'` | MERGE thiếu 1 trong 8 cột notnull của `tblHtmlScriptCache` | Fill đủ `TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData` |
| UI cache vẫn cũ sau khi sửa renderer | Chưa DELETE cache trước build | `DELETE FROM tblHtmlScriptCache WHERE TableName='<class>_html'` rồi mới `EXEC sp_GenerateHTMLScript` |
| `loadDataSourceCommon is not a function` trên barebones menu | Polyfill global helper thiếu | Áp pattern §3.5 |
| Tiếng Việt bị `???` trong cache | T-SQL string không có prefix `N'` | Mọi chuỗi tiếng Việt phải `N'...'`, biến `NVARCHAR(MAX)` |
| Grid hiện nhưng không có data | `SPLoadData` không tồn tại / sai tên column SELECT | Test `EXEC <SPLoadData> @LoginID=3` — column name khớp `ColumnName` metadata |
| `dataSource` không update khi gọi `ReloadData` | Trỏ sai `Instance<GridName><UID>` — UID đổi giữa các lần chạy | Đảm bảo UID deterministic, không để proc tự sinh random |

---

## §9. Template đầy đủ (copy-paste ready)

Khung renderer hoàn chỉnh — fork từ đây và thay text + data API + tên class. Pattern này đã verify production qua `sp_HelloWorldVietinsoft_html` ([SQL script/update_menu_HelloWorldVietinsoft_employeelist_20260521.sql](../SQL%20script/update_menu_HelloWorldVietinsoft_employeelist_20260521.sql)) và `sp_CRM_Customers_html`.

```sql
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- ============================================================
-- RENDERER sp_X_html — Skill 17 chuẩn
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_X_html
(
    @LoginID    INT          = 3,
    @LanguageID VARCHAR(5)   = 'VN',
    @isWeb      INT          = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Layer 2: Text label đa ngôn ngữ
    DECLARE @title    NVARCHAR(200);
    DECLARE @subtitle NVARCHAR(300);
    DECLARE @loading  NVARCHAR(100);
    DECLARE @empty    NVARCHAR(200);

    IF @LanguageID = 'EN'
    BEGIN
        SET @title    = N'My Feature';
        SET @subtitle = N'English subtitle.';
        SET @loading  = N'Loading...';
        SET @empty    = N'No data.';
    END
    ELSE
    BEGIN
        SET @title    = N'Tên tính năng';
        SET @subtitle = N'Mô tả tiếng Việt.';
        SET @loading  = N'Đang tải...';
        SET @empty    = N'Không có dữ liệu.';
    END

    -- Layer 3: Biến *Js đã escape (BẮT BUỘC trước khi nối vào JS)
    DECLARE @titleJs    NVARCHAR(400) = REPLACE(REPLACE(@title,    N'\', N'\\'), N'"', N'\"');
    DECLARE @subtitleJs NVARCHAR(600) = REPLACE(REPLACE(@subtitle, N'\', N'\\'), N'"', N'\"');
    DECLARE @loadingJs  NVARCHAR(200) = REPLACE(REPLACE(@loading,  N'\', N'\\'), N'"', N'\"');
    DECLARE @emptyJs    NVARCHAR(400) = REPLACE(REPLACE(@empty,    N'\', N'\\'), N'"', N'\"');

    -- Layer 4: Build HTML + JS
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
    USING (SELECT 'sp_X_html'   AS TableName,
                  @LanguageID    AS LanguageID,
                  '-1'           AS ScreenType,
                  @html          AS html,
                  N''            AS HtmlParadise,
                  N''            AS paradiseJs,
                  '1'            AS Version,
                  N''            AS VersionData) AS src
       ON tgt.TableName = src.TableName AND tgt.LanguageID = src.LanguageID
    WHEN MATCHED THEN
        UPDATE SET tgt.ScreenType   = src.ScreenType,
                   tgt.html         = src.html,
                   tgt.HtmlParadise = src.HtmlParadise,
                   tgt.paradiseJs   = src.paradiseJs,
                   tgt.Version      = src.Version,
                   tgt.VersionData  = src.VersionData
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData)
        VALUES (src.TableName, src.LanguageID, src.ScreenType, src.html, src.HtmlParadise, src.paradiseJs, src.Version, src.VersionData);

    -- Layer 6: Fallback SELECT
    SELECT @html AS html;
END
GO

-- ============================================================
-- BUILD CACHE
-- ============================================================
DELETE FROM dbo.tblHtmlScriptCache WHERE TableName = 'sp_X_html';
EXEC dbo.sp_GenerateHTMLScript 'sp_X_html';
GO

-- ============================================================
-- VERIFY
-- ============================================================
SELECT TableName, LanguageID, ScreenType,
       DATALENGTH(html) AS HtmlBytes, Version
FROM   dbo.tblHtmlScriptCache
WHERE  TableName = 'sp_X_html'
ORDER  BY LanguageID;
GO
```

---

## §10. Truy vấn MCP `mssql-vietinsoft` để extract renderer từ DB

Section này dạy cách **đọc** renderer từ DB nguồn (để rebuild script migrate, debug cache, copy menu sang DB khác). Bổ sung cho §1–§9 dạy *viết* renderer.

> 💡 **Trước khi extract**: nếu chưa biết `ClassName`/`MenuID` mà chỉ có tên menu, dùng [18_FindMenuProcedure.md](18_FindMenuProcedure.md) (quy trình 5 bước `tblMD_Message → MEN_Menu → ClassName → %_html`) để resolve trước, rồi quay lại đây extract.

### §10.0. ⚡ QUICK START MCP (30 giây — đủ làm việc cơ bản)

**3 câu lệnh phổ biến nhất** (gọi qua MCP tool `mcp__mssql-vietinsoft__read_query`):

1. **Tìm menu theo tên tiếng Việt**:
   ```sql
   SELECT TOP 50 MessageID, Language, Content
   FROM tblMD_Message WHERE Content LIKE N'%<tên>%';
   ```
2. **Đọc source procedure renderer**:
   ```sql
   SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_X_html')) AS Source;
   ```
3. **Check kích thước HTML cache TRƯỚC khi đọc full** (tránh truncate):
   ```sql
   SELECT TableName, LanguageID, DATALENGTH(html) AS Bytes
   FROM tblHtmlScriptCache WHERE TableName = 'sp_X_html';
   ```

**2 cấm kỵ bất biến**:
- ❌ KHÔNG gọi `write_query` / `alter_table` / `create_table` / `drop_table` / `append_insight` khi user chưa yêu cầu rõ ràng **trong câu hỏi hiện tại**. Permission câu trước không kéo dài sang câu sau.
- ❌ KHÔNG `SELECT *` thiếu `TOP N` / `WHERE` — luôn giới hạn.

→ Đi sâu: [§10.1 tools](#§101-bộ-công-cụ-mcp-chỉ-đọc--không-write) · [§10.3 combo query](#§103-combo-query-extract-renderer-package--đọc-trọn-1-menu-trong-1-lượt) · [§10.5 workflow](#§105-workflow-chuẩn--từ-tôi-cần-migrate-menu-x-đến-script)

### §10.1. Bộ công cụ MCP (CHỈ đọc — không write)

| Tool | Mục đích | Khi nào dùng |
|---|---|---|
| `mcp__mssql-vietinsoft__list_tables` | Liệt kê bảng/view trong DB | Khi cần tìm tên bảng theo prefix nhanh |
| `mcp__mssql-vietinsoft__describe_table` | Lấy schema 1 bảng (cột + kiểu) | Trước khi INSERT/MERGE — verify cột notnull + varbinary |
| `mcp__mssql-vietinsoft__read_query` | Query bất kỳ (`SELECT`) | Đọc data, đọc source procedure (`OBJECT_DEFINITION`), đếm dòng |
| `mcp__mssql-vietinsoft__export_query` | Xuất kết quả ra file | Khi data quá lớn để inline (HTML cache > 8KB) |
| `mcp__mssql-vietinsoft__list_insights` | Liệt kê insight đã lưu | Khi muốn xem note cũ từ session trước |

**Quy tắc bất biến** (BẮT BUỘC):
- TUYỆT ĐỐI KHÔNG gọi `write_query` / `alter_table` / `create_table` / `drop_table` / `append_insight` khi user chưa yêu cầu rõ ràng.
- `read_query` LUÔN dùng `TOP N` / `WHERE` — không bao giờ `SELECT *` toàn bảng lớn.
- Đọc source procedure → dùng `SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.<name>'))`.

### §10.2. Query template 4 cấp độ (copy-paste ready)

#### §10.2.1. Tìm tên bảng / procedure theo keyword

```sql
-- Bảng/view
SELECT TOP 50 name, type_desc, create_date, modify_date
FROM   sys.objects
WHERE  name LIKE '%<keyword>%' AND type IN ('U','V')
ORDER  BY name;

-- Procedure
SELECT TOP 50 name, type_desc, modify_date
FROM   sys.objects
WHERE  name LIKE 'sp_<prefix>%' AND type = 'P'
ORDER  BY name;
```

#### §10.2.2. Describe schema bảng (verify cột varbinary)

```sql
-- Cách 1: dùng INFORMATION_SCHEMA (recommended — đầy đủ)
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE,
       CHARACTER_MAXIMUM_LENGTH, COLUMN_DEFAULT
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME = '<tableName>'
ORDER  BY ORDINAL_POSITION;
```

Hoặc gọi MCP tool `describe_table` với arg `table_name='<tableName>'` — nhanh hơn nếu chỉ cần liệt kê cột.

→ Trước khi viết script renderer: bắt buộc describe `tblHtmlScriptCache`, `tblDataSetting`, `tblDataSettingLayout` để verify cột notnull + cột varbinary (xem [§5](#§5-pattern-merge-tblhtmlscriptcache-8-cột-notnull) và [§6](#§6-pattern-các-cột-varbinarymax-lỗi-msg-257)).

#### §10.2.3. Đọc source procedure renderer (wrapper + renderer + API)

```sql
-- Source 1 proc duy nhất
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_HelloWorldVietinsoft_html')) AS Source;

-- 3 proc cùng họ trong 1 lượt
SELECT name,
       OBJECT_DEFINITION(object_id) AS Source
FROM   sys.objects
WHERE  name IN ('sp_HelloWorldVietinsoft',
                'sp_HelloWorldVietinsoft_html',
                'sp_LoadHelloWorldVietinsoftEmployeeList')
  AND  type = 'P';
```

> ⚠️ Source proc dài → MCP có thể truncate response. Nếu thấy bị cắt: dùng `SUBSTRING` từng chunk 4000 ký tự (§10.4) hoặc `export_query`.

#### §10.2.4. Đọc HTML/JS đã build trong cache

```sql
-- Bước 1: Check kích thước trước (KHÔNG đọc html luôn)
SELECT TableName, LanguageID, ScreenType,
       DATALENGTH(html)         AS HtmlBytes,
       DATALENGTH(HtmlParadise) AS HtmlParadiseBytes,
       DATALENGTH(paradiseJs)   AS ParadiseJsBytes,
       Version
FROM   tblHtmlScriptCache
WHERE  TableName = 'sp_X_html'
ORDER  BY LanguageID;

-- Bước 2: Đọc full html nếu < 8000 ký tự
SELECT TOP 1 html
FROM   tblHtmlScriptCache
WHERE  TableName = 'sp_X_html' AND LanguageID = 'VN';

-- Bước 3: Nếu > 8000 → đọc từng chunk (xem §10.4)
```

### §10.3. Combo query "Extract renderer package" — đọc trọn 1 menu trong 1 lượt

Khi cần migrate menu, chạy combo dưới để lấy đủ 8 mảnh metadata + source + cache + config controls:

```sql
DECLARE @MenuID    varchar(100) = 'MnuXXX';
DECLARE @ClassName varchar(200);

-- 1. MEN_Menu metadata (1 dòng)
SELECT TOP 1 MenuID, ClassName, AssemblyName, ParentMenuID, Priority,
             IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb,
             IsUseMobileDevice, isShowInMobileLayOut,
             glyphicon, GroupID
FROM   MEN_Menu
WHERE  MenuID = @MenuID;

SELECT TOP 1 @ClassName = ClassName FROM MEN_Menu WHERE MenuID = @MenuID;

-- 2. tblSC_Object (quyền)
SELECT TOP 5 ObjectID, ObjectName, Description, ParentObjectID
FROM   tblSC_Object
WHERE  Description = @MenuID;

-- 3. tblMD_Message (label đa ngôn ngữ)
SELECT TOP 10 MessageID, Language, Content
FROM   tblMD_Message
WHERE  MessageID = @MenuID
ORDER  BY Language;

-- 4. tblDataSetting (1 dòng — verify IsProcedure, IsShowLayout, ColumnDataType)
SELECT TOP 1 TableName, ViewName, IsProcedure, IsShowLayout,
             ColumnOrderBy, ColumnDataType,
             ControlHiddenInShowLayout, FormLayoutJS
FROM   tblDataSetting
WHERE  TableName = @ClassName;

-- 5. tblDataSettingLayout (2 dòng — root + lblhtml)
SELECT TOP 10 TableName, Name, ControlName, NamePa, Type, ControlType,
              Lx, Ly, Sx, Sy, WidthPercentage
FROM   tblDataSettingLayout
WHERE  TableName = @ClassName
ORDER  BY Name;

-- 6. Source wrapper + renderer
SELECT name, OBJECT_DEFINITION(object_id) AS Source
FROM   sys.objects
WHERE  name IN (@ClassName, @ClassName + '_html') AND type = 'P';

-- 7. tblHtmlScriptCache — chỉ check size trước
SELECT TableName, LanguageID, ScreenType,
       DATALENGTH(html) AS HtmlBytes, Version
FROM   tblHtmlScriptCache
WHERE  TableName = @ClassName + '_html'
ORDER  BY LanguageID;

-- 8. tblCommonControlType_Signed (nếu config-driven)
SELECT TOP 50 TableName, ColumnName, Type, Layout,
              DataSourceSP, SPLoadData, ColumnIDName,
              TableEditor, DisplayName, GridColumnName,
              GridWidth, AllowSorting, AllowFiltering, UID
FROM   tblCommonControlType_Signed
WHERE  TableName = @ClassName + '_html'
ORDER  BY UID;
```

→ 8 query trên = trọn vẹn renderer package. Lưu output (nếu cần) bằng `export_query` để dùng làm input cho script migrate.

### §10.4. Pattern đọc cột `nvarchar(max)` lớn (HTML cache > 8KB)

MCP có thể truncate response khi cell quá lớn. 3 cách xử lý:

#### Cách A — Chunk bằng `SUBSTRING` (đọc trong nhiều lần `read_query`)

```sql
DECLARE @TableName  varchar(200) = 'sp_X_html';
DECLARE @LanguageID varchar(5)   = 'VN';

-- Đọc 4 chunk 4000 ký tự liên tiếp
SELECT SUBSTRING(html,     1, 4000) AS Chunk1,
       SUBSTRING(html,  4001, 4000) AS Chunk2,
       SUBSTRING(html,  8001, 4000) AS Chunk3,
       SUBSTRING(html, 12001, 4000) AS Chunk4
FROM   tblHtmlScriptCache
WHERE  TableName = @TableName AND LanguageID = @LanguageID;
```

Concat các chunk lại client-side. Nếu HTML > 16KB → tăng số chunk hoặc dùng Cách B.

#### Cách B — Dùng `export_query` xuất ra file

Gọi MCP tool `export_query` với query:

```sql
SELECT html
FROM   tblHtmlScriptCache
WHERE  TableName = 'sp_X_html' AND LanguageID = 'VN';
```

→ MCP ghi kết quả ra file → Agent đọc file bằng `Read` tool. An toàn cho data > 30KB.

#### Cách C — Tránh kéo HTML lớn, chỉ port source proc (khuyến nghị cho migrate)

Mục đích migrate: thay vì kéo HTML ra rồi nhúng vào script, **chạy lại `sp_GenerateHTMLScript`** ở DB đích. Renderer ở DB nguồn được port qua dưới dạng `CREATE OR ALTER PROCEDURE` (source ngắn), DB đích tự build cache mới — tránh nhúng HTML lớn vào script migrate.

→ Đây là pattern mặc định trong [§9 Template đầy đủ](#§9-template-đầy-đủ-copy-paste-ready).

### §10.5. Workflow chuẩn — từ "tôi cần migrate menu X" đến script

```
1. (read_query LIKE)       → Tìm MenuID từ tên menu/keyword
2. (read_query combo §10.3)→ Lấy 8 mảnh metadata + source + cache size
3. (describe_table)        → Verify cột notnull/varbinary của 3 bảng metadata
4. (read_query SUBSTRING)  → Đọc source renderer + wrapper full (nếu MCP truncate)
5. Quyết định cách bring HTML: Cách A/B (copy cache) HAY Cách C (rebuild qua sp_GenerateHTMLScript — khuyến nghị)
6. Build SQL script trong SQL script/ theo template §9
7. KHÔNG tự chạy script — đưa user review
```

### §10.6. Quy tắc an toàn (BẤT BIẾN)

- ✅ Tool đọc được phép: `list_tables`, `describe_table`, `read_query`, `export_query`, `list_insights`.
- ❌ KHÔNG gọi `write_query` / `create_table` / `alter_table` / `drop_table` / `append_insight` khi user **chưa yêu cầu rõ ràng trong câu hỏi hiện tại**.
- Permission của câu hỏi trước **không** kéo dài sang câu hỏi sau.
- Khi user yêu cầu sửa DB: build SQL script trong `SQL script/` cho user tự chạy, **không** dùng `write_query` để thực thi trực tiếp (xem [CLAUDE.md Bước 6](../CLAUDE.md)).

---

## Tham khảo bổ sung

| Chủ đề | File |
|---|---|
| Luồng tạo menu end-to-end (9 phase) | [12_CreateMenu.md](12_CreateMenu.md) |
| Luồng migrate / update menu có sẵn | [13_Migrate_Menu.md](13_Migrate_Menu.md) |
| Chuẩn thiết kế UI (ParadiseStyle, token CSS) | [14_ParadiseStyle.md](14_ParadiseStyle.md) |
| Tri thức nền menu (5 mảnh dữ liệu, HTML cache) | [07_menu_system.md](07_menu_system.md) |
| Phân quyền menu (LoginID = 3) | [11_permissions.md](11_permissions.md) |
| Cờ nền tảng Desktop / Web / Mobile | [01_architecture.md](01_architecture.md) |
| Quy tắc MCP `mssql-vietinsoft` (đọc-only, TOP N, `OBJECT_DEFINITION`) | [CLAUDE.md Bước 3](../CLAUDE.md) |
