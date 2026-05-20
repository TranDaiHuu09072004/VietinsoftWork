# 12 — Skill: Quy trình tạo menu Web mới trong ParadiseHR

> **Skill file** — hướng dẫn lập trình viên mới triển khai trọn vẹn 1 menu Web kiểu HTML-rendered (kiểu duy nhất ParadiseHR hiện dùng — kiểu ASPX-style đã lỗi thời, xem [99_deprecated.md §5](99_deprecated.md) và [99_deprecated.md §7](99_deprecated.md)).
>
> Liên quan: [07_menu_system.md](07_menu_system.md) (tri thức nền), [11_permissions.md](11_permissions.md) (phân quyền), [01_architecture.md](01_architecture.md) (3 nền tảng + cờ).
>
> Ví dụ minh hoạ xuyên suốt file: menu **"Hello world Vietinsoft"** (`MnuHEP910`) hiển thị **Top 3 nhân viên có điểm xếp hạng cao nhất tháng hiện tại** — gọi API runtime qua `AjaxHPAParadise`.

---

## 1. Hai layer trong 1 menu HTML-rendered

Mỗi menu Web ParadiseHR gồm **2 layer** tách rời:

| Layer | Bản chất | Cập nhật khi |
|---|---|---|
| **A. Metadata + UI tĩnh** | 3 bảng (`MEN_Menu`, `tblSC_Object`, `tblMD_Message`) + HTML/CSS/JS tĩnh trong `tblHtmlScriptCache` | Khi tạo menu / đổi tên / sửa layout / sửa CSS / sửa JS |
| **B. Dữ liệu động (runtime)** | Procedure API riêng được JS gọi qua `AjaxHPAParadise` lúc người dùng mở menu | Khi cần data từ DB — KHÔNG cần rebuild cache HTML |

Tách 2 layer ⇒ khi data DB thay đổi → user nhận data mới ngay; khi cần thay đổi UI → chỉ cần rebuild renderer + reset cache, **không** đụng tới quyền/menu.

---

## 2. Quy ước đặt tên (BẮT BUỘC)

| Thành phần | Mẫu | Ví dụ Hello world |
|---|---|---|
| `MenuID` | `Mnu<MODULE><N>` — 3 chữ module + số | `MnuHEP910` (nhóm `HEP` = Trợ giúp) |
| `ClassName` (= tên wrapper) | `sp_<TenNghiepVu>` | `sp_HelloWorldVietinsoft` |
| Renderer | `<ClassName>_html` | `sp_HelloWorldVietinsoft_html` |
| API runtime | `sp_<TenNghiepVu>_<Action>` | `sp_HelloWorldVietinsoft_GetTopRank` |
| `ObjectName` (`tblSC_Object`) | `<AssemblyName>.<ClassName>` | `DataSetting.sp_HelloWorldVietinsoft` |
| Cache key (`tblHtmlScriptCache.TableName`) | `<ClassName>_html` | `sp_HelloWorldVietinsoft_html` |

Cách tự sinh `MenuID` mới: lấy `MAX` số sau 6 ký tự đầu trong cùng nhóm + 1. Cách này được proc `sp_s_CreateMenu` ([07_menu_system.md §6](07_menu_system.md)) làm tự động.

---

## 3. Quy trình 9 phase end-to-end

```
[A] Thiết kế nguồn dữ liệu    → quyết định procedure API runtime nào sẽ trả data
[B] Viết cặp procedure UI     → <class>_html (renderer) + <class> (wrapper đọc cache)
[C] Viết procedure API        → sp_<X>_<Action>: SELECT data từ DB
[D] Tạo metadata menu         → MEN_Menu + tblSC_Object + tblMD_Message (qua sp_s_CreateMenu hoặc thủ công)
[E] Set cờ nền tảng + UI      → IsWeb=0, ViewOnWeb=1, isShowLayOutWeb=1, IsUseMobileDevice, glyphicon, GroupID
[F] Build HTML cache          → EXEC <class>_html cho từng LanguageID (VN/EN)
[G] Phân quyền                → tblSC_Right_Stored (LoginID) hoặc tblSC_GroupRight (UserGroupID)
[H] Refresh cache menu        → sp_Men_Menu_AfterSave_Simple + sp_UpdateMenuInUserRight
[I] User logout/login         → app load lại cây menu → click → wrapper trả HTML → JS gọi API runtime
```

Xem chi tiết từng phase ở [07_menu_system.md §13](07_menu_system.md).

---

## 4. Ví dụ Hello world Vietinsoft — Top 3 xếp hạng

### 4.1. Bảng tham gia (đã xác minh schema từ DB)

| Bảng | Vai trò | Cột chính |
|---|---|---|
| `tblRank_PersonalRating_Detail` | Fact điểm/coin theo `EmployeeID` + `CreatedDate` + `PointType` | `EmployeeID` (varchar), `ExperiencePonits` (int), `Coin` (int), `CreatedDate` (datetime), `PointType` (int) |
| `tblEmployee` | Lấy `FullName` (xem [02_db_employee.md](02_db_employee.md)) | `EmployeeID`, `FullName` |
| `tblHtmlScriptCache` | Lưu HTML/CSS/JS theo `(TableName, LanguageID)` | xem [07_menu_system.md §10](07_menu_system.md) |

> ⚠️ Cột điểm là `ExperiencePonits` (có typo trong DB gốc — KHÔNG sửa). Tổng điểm theo tháng = `SUM(ExperiencePonits)` filter theo `CreatedDate` trong tháng hiện tại.

### 4.2. Phase C — Procedure API runtime `sp_HelloWorldVietinsoft_GetTopRank`

JS sẽ gọi proc này qua `AjaxHPAParadise`. Proc nhận `@LoginID` + `@LanguageID` (chuẩn ParadiseHR) + tham số filter (tháng/năm tuỳ chọn), trả về 1 result-set đã sort.

```sql
CREATE PROCEDURE dbo.sp_HelloWorldVietinsoft_GetTopRank
(
    @LoginID    INT,
    @LanguageID VARCHAR(5) = 'VN',
    @FilterYear INT        = NULL,    -- nếu NULL → năm hiện tại
    @FilterMonth INT       = NULL     -- nếu NULL → tháng hiện tại
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FilterYear IS NULL  SET @FilterYear  = YEAR(GETDATE());
    IF @FilterMonth IS NULL SET @FilterMonth = MONTH(GETDATE());

    DECLARE @FromDate DATETIME = DATEFROMPARTS(@FilterYear, @FilterMonth, 1);
    DECLARE @ToDate   DATETIME = DATEADD(MONTH, 1, @FromDate);

    SELECT TOP 3
           r.EmployeeID,
           ISNULL(e.FullName, r.EmployeeID) AS FullName,
           SUM(r.ExperiencePonits)          AS TotalPoints,
           SUM(r.Coin)                      AS TotalCoin,
           @FilterYear                      AS FilterYear,
           @FilterMonth                     AS FilterMonth
    FROM   tblRank_PersonalRating_Detail r
    LEFT   JOIN tblEmployee e ON e.EmployeeID = r.EmployeeID
    WHERE  r.CreatedDate >= @FromDate
      AND  r.CreatedDate <  @ToDate
    GROUP  BY r.EmployeeID, e.FullName
    ORDER  BY TotalPoints DESC, r.EmployeeID ASC;
END
```

> **Lưu ý**: Procedure ParadiseHR runtime luôn nhận tối thiểu 2 tham số chuẩn `@LoginID` + `@LanguageID` (framework `AjaxHPAParadise` tự bơm vào nếu JS không truyền — xem các renderer mẫu như `sp_Train_Ranking_Template_html`, `sp_KPIProcessCustomer_html`).

### 4.3. Phase B — Renderer `sp_HelloWorldVietinsoft_html`

Renderer build chuỗi HTML/CSS/JS rồi UPSERT vào `tblHtmlScriptCache`. Code JS bên trong gọi proc API qua `AjaxHPAParadise`. **Đa ngôn ngữ**: lưu thành 2 cache record theo `LanguageID = 'VN' / 'EN'`.

```sql
CREATE PROCEDURE dbo.sp_HelloWorldVietinsoft_html
(
    @LoginID    INT          = 3,
    @LanguageID VARCHAR(5)   = 'VN',
    @isWeb      INT          = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @title    NVARCHAR(200) = N'Hello world Vietinsoft';
    DECLARE @subtitle NVARCHAR(300);
    DECLARE @colNo    NVARCHAR(50);
    DECLARE @colName  NVARCHAR(50);
    DECLARE @colPts   NVARCHAR(50);
    DECLARE @loading  NVARCHAR(100);
    DECLARE @empty    NVARCHAR(200);

    IF @LanguageID = 'EN'
    BEGIN
        SET @subtitle = N'Top 3 employees with highest ranking points this month.';
        SET @colNo    = N'#';
        SET @colName  = N'Employee';
        SET @colPts   = N'Total points';
        SET @loading  = N'Loading...';
        SET @empty    = N'No data for this month.';
    END
    ELSE
    BEGIN
        SET @subtitle = N'Top 3 nhân viên có điểm xếp hạng cao nhất tháng hiện tại.';
        SET @colNo    = N'STT';
        SET @colName  = N'Nhân viên';
        SET @colPts   = N'Tổng điểm';
        SET @loading  = N'Đang tải...';
        SET @empty    = N'Không có dữ liệu cho tháng này.';
    END

    DECLARE @html NVARCHAR(MAX) =
        N'<div id="helloWorldVtsContainer" style="font-family:''Segoe UI'',Arial,sans-serif;max-width:720px;margin:24px auto;padding:24px;border-radius:12px;background:linear-gradient(135deg,#1e3c72 0%,#2a5298 100%);color:#fff;box-shadow:0 6px 24px rgba(0,0,0,.18);">'
      + N'  <h1 style="margin:0 0 8px 0;font-size:26px;">' + @title + N'</h1>'
      + N'  <p style="margin:0 0 18px 0;opacity:.92;font-size:14px;">' + @subtitle + N'</p>'
      + N'  <table id="hwVtsTable" style="width:100%;border-collapse:collapse;background:rgba(255,255,255,.08);border-radius:8px;overflow:hidden;">'
      + N'    <thead>'
      + N'      <tr style="background:rgba(0,0,0,.18);text-align:left;">'
      + N'        <th style="padding:10px 12px;width:48px;">' + @colNo   + N'</th>'
      + N'        <th style="padding:10px 12px;">'             + @colName + N'</th>'
      + N'        <th style="padding:10px 12px;text-align:right;width:120px;">' + @colPts + N'</th>'
      + N'      </tr>'
      + N'    </thead>'
      + N'    <tbody id="hwVtsTbody">'
      + N'      <tr><td colspan="3" style="padding:14px;text-align:center;opacity:.8;">' + @loading + N'</td></tr>'
      + N'    </tbody>'
      + N'  </table>'
      + N'</div>'
      + N'<script>'
      + N'(function(){'
      + N'  var EMPTY_MSG = "' + @empty + N'";'
      + N'  function render(rows){'
      + N'    var tb = document.getElementById("hwVtsTbody");'
      + N'    if(!tb) return;'
      + N'    if(!rows || rows.length === 0){'
      + N'      tb.innerHTML = "<tr><td colspan=''3'' style=''padding:14px;text-align:center;opacity:.85;''>" + EMPTY_MSG + "</td></tr>";'
      + N'      return;'
      + N'    }'
      + N'    var html = "";'
      + N'    for(var i=0;i<rows.length;i++){'
      + N'      var r = rows[i];'
      + N'      html += "<tr style=''border-top:1px solid rgba(255,255,255,.12);''>" +'
      + N'              "<td style=''padding:10px 12px;font-weight:600;''>" + (i+1) + "</td>" +'
      + N'              "<td style=''padding:10px 12px;''>" + (r.FullName || r.EmployeeID) + "</td>" +'
      + N'              "<td style=''padding:10px 12px;text-align:right;font-weight:700;''>" + (r.TotalPoints != null ? r.TotalPoints : 0) + "</td>" +'
      + N'              "</tr>";'
      + N'    }'
      + N'    tb.innerHTML = html;'
      + N'  }'
      + N'  AjaxHPAParadise({'
      + N'    data: {'
      + N'      name: "sp_HelloWorldVietinsoft_GetTopRank",'
      + N'      param: ["FilterYear", null, "FilterMonth", null]'
      + N'    },'
      + N'    success: function(res){'
      + N'      try{'
      + N'        var json = typeof res === "string" ? JSON.parse(res) : res;'
      + N'        var rows = [];'
      + N'        if(json && json.data && Array.isArray(json.data)){ rows = json.data[0] || []; }'
      + N'        else if(Array.isArray(json)){ rows = json; }'
      + N'        render(rows);'
      + N'      }catch(e){ render([]); }'
      + N'    },'
      + N'    error: function(){ render([]); }'
      + N'  });'
      + N'})();'
      + N'</script>';

    -- UPSERT cache theo (TableName, LanguageID) — phải fill cả 5 cột notnull
    MERGE dbo.tblHtmlScriptCache AS tgt
    USING (SELECT
              'sp_HelloWorldVietinsoft_html' AS TableName,
              @LanguageID                    AS LanguageID,
              '-1'                           AS ScreenType,
              @html                          AS html,
              N''                            AS HtmlParadise,
              N''                            AS paradiseJs,
              '1'                            AS Version,
              N''                            AS VersionData) AS src
       ON tgt.TableName = src.TableName AND tgt.LanguageID = src.LanguageID
    WHEN MATCHED THEN
        UPDATE SET tgt.ScreenType=src.ScreenType, tgt.html=src.html,
                   tgt.HtmlParadise=src.HtmlParadise, tgt.paradiseJs=src.paradiseJs,
                   tgt.Version=src.Version, tgt.VersionData=src.VersionData
    WHEN NOT MATCHED THEN
        INSERT (TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData)
        VALUES (src.TableName, src.LanguageID, src.ScreenType, src.html, src.HtmlParadise, src.paradiseJs, src.Version, src.VersionData);
END
```

### 4.4. Phase B — Wrapper `sp_HelloWorldVietinsoft`

Wrapper chỉ đọc HTML từ cache theo `LanguageID`:

```sql
CREATE PROCEDURE dbo.sp_HelloWorldVietinsoft
(
    @LoginID    INT,
    @LanguageID VARCHAR(5) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 html
    FROM   dbo.tblHtmlScriptCache
    WHERE  TableName  = 'sp_HelloWorldVietinsoft_html'
      AND  ScreenType = '-1'
      AND  LanguageID = @LanguageID;
END
```

### 4.5. Phase D — Tạo metadata menu (`sp_s_CreateMenu`)

```sql
EXEC dbo.sp_s_CreateMenu
     @Text         = N'Hello world Vietinsoft',
     @TextEN       = 'Hello world Vietinsoft',
     @ClassName    = 'sp_HelloWorldVietinsoft',
     @ParentMenuID = 'MnuHEP000',          -- nhóm Trợ giúp
     @AssemblyName = 'DataSetting',
     @Option       = 1,                    -- 1 = thực thi (0 = preview script)
     @LoginIDList  = '3';                  -- cấp FullAccess=32 cho LoginID=3 (admin)
```

Proc tự sinh `MenuID = 'MnuHEP910'` + `ObjectID = MAX+1`, insert đủ 3 bảng metadata + cấp quyền. Hoặc dùng cách insert thủ công nếu cần kiểm soát `MenuID` cụ thể — xem [SQL script/deploy_menu_HelloWorldVietinsoft_20260520.sql](../SQL%20script/deploy_menu_HelloWorldVietinsoft_20260520.sql).

### 4.6. Phase E — Cờ nền tảng + UI

```sql
UPDATE MEN_Menu
SET    IsWeb              = 0,    -- 0 vì kiểu HTML-rendered (wrapper server-side)
       ViewOnWeb          = 1,
       isShowLayOutWeb    = 1,    -- bật layout container WebView
       IsUseMobileDevice  = 1,    -- bật cho mobile
       isShowInMobileLayOut = 1,
       glyphicon          = N'Info',
       GroupID            = 'MnuHEP000',
       Priority           = 99
WHERE  MenuID = 'MnuHEP910';
```

### 4.7. Phase F — Build cache HTML cho VN + EN

```sql
EXEC dbo.sp_HelloWorldVietinsoft_html @LoginID=3, @LanguageID='VN', @isWeb=1;
EXEC dbo.sp_HelloWorldVietinsoft_html @LoginID=3, @LanguageID='EN', @isWeb=1;
-- hoặc helper:
EXEC dbo.sp_GenerateHTMLScript 'sp_HelloWorldVietinsoft_html';
```

### 4.8. Phase H — Refresh menu cache

```sql
EXEC dbo.sp_Men_Menu_AfterSave_Simple;
EXEC dbo.sp_UpdateMenuInUserRight;
```

User logout/login để app load cây menu mới.

---

## 5. Pattern gọi API runtime — `AjaxHPAParadise` (rút từ source thực tế)

### 5.1. Cú pháp chuẩn

```javascript
AjaxHPAParadise({
    data: {
        name:  "<TenProcedure>",                        // tên procedure server-side
        param: ["ParamName1", value1, "ParamName2", v2] // ARRAY phẳng: [name, value, name, value, ...]
    },
    success: function(res) {
        // res có thể là chuỗi JSON hoặc object đã parse
        var json = typeof res === "string" ? JSON.parse(res) : res;

        // Procedure trả N result-set ⇒ json.data = [ resultSet1, resultSet2, ... ]
        // Mỗi result-set là array of row-object (key = tên cột)
        var rows1 = json.data[0] || [];
        var rows2 = json.data[1] || [];
        // ...
    },
    error: function(err) { /* xử lý lỗi */ },
    xhrFields: { responseType: "blob" }                 // (optional) khi cần tải file/ảnh
});
```

Đã verify pattern từ source `sp_Train_Ranking_Template_html` và `sp_KPIProcessCustomer_html`.

### 5.2. Quy tắc về `param`

- Là **mảng phẳng** xen kẽ `[name, value, name, value, ...]` — KHÔNG phải object `{name: value}`.
- `name` không kèm dấu `@` (framework tự thêm).
- `value` có thể là `null` — server-side proc dùng default param.
- Có thể đẩy động: `params.push("ExtraName", extraValue);` (xem source `sp_Train_Ranking_Template_html`).

### 5.3. Quy tắc về procedure API

- Luôn nhận tối thiểu `@LoginID INT` + `@LanguageID VARCHAR(5) = 'VN'` (framework tự bơm).
- Tham số filter còn lại nên có `DEFAULT NULL` để JS bỏ trống được.
- Trả 1 hoặc nhiều `SELECT` — mỗi `SELECT` thành 1 phần tử của `json.data`.
- Tên cột của `SELECT` sẽ thành key của row object trên client.

### 5.4. Lấy file/ảnh

Khi cần ảnh nhân viên hoặc file binary — gọi `paradisefile_sp_GetFileAPI` với `xhrFields: { responseType: "blob" }`, rồi `URL.createObjectURL(blob)` gán vào `img.src`. Mẫu: `sp_Train_Ranking_Template_html` (xem [07_menu_system.md §10](07_menu_system.md)).

---

## 6. Checklist 7 điểm dành cho lập trình viên mới

1. ☐ Đã chọn `MenuID` không trùng — kiểm tra qua `SELECT * FROM MEN_Menu WHERE MenuID='<id>'`.
2. ☐ Renderer đã UPSERT cache cho **cả VN và EN** (2 dòng trong `tblHtmlScriptCache`).
3. ☐ Wrapper đã `SELECT TOP 1 html` lọc đúng `(TableName, ScreenType='-1', LanguageID)`.
4. ☐ Procedure API runtime có 2 tham số chuẩn `@LoginID` + `@LanguageID`.
5. ☐ JS gọi `AjaxHPAParadise` với `param` là **mảng phẳng** `[name, value, ...]`, KHÔNG phải object.
6. ☐ Đã chạy `sp_Men_Menu_AfterSave_Simple` + `sp_UpdateMenuInUserRight` sau khi insert metadata.
7. ☐ Đã verify menu hiển thị bằng cách logout/login → mở menu → mở DevTools → check Network tab xem `AjaxHPAParadise` POST đúng `name` + `param`.

---

## 7. Các lỗi thường gặp khi tạo menu mới

| Triệu chứng | Nguyên nhân hay gặp | Cách kiểm tra |
|---|---|---|
| Menu không hiện trong cây | Chưa `sp_UpdateMenuInUserRight` / user chưa logout-login / `IsVisible = 0` / chưa cấp quyền | `SELECT m.IsVisible, o.ObjectID, r.LoginID FROM MEN_Menu m LEFT JOIN tblSC_Object o ON o.Description=m.MenuID LEFT JOIN tblSC_Right_Stored r ON r.ObjectID=o.ObjectID WHERE m.MenuID='<id>'` |
| Mở menu thấy trắng / "loading..." không kết thúc | Renderer chưa chạy → cache rỗng | `SELECT DATALENGTH(html) FROM tblHtmlScriptCache WHERE TableName='<class>_html' AND LanguageID='VN'` |
| Hiển thị HTML cũ sau khi sửa | Cache HTML chưa được rebuild | `DELETE FROM tblHtmlScriptCache WHERE TableName='<class>_html'; EXEC dbo.<class>_html @LoginID=3, @LanguageID='VN', @isWeb=1;` |
| JS gọi API lỗi 500 | Tham số `param` sai (object thay vì array) hoặc thiếu `@LoginID`/`@LanguageID` trong procedure | Mở DevTools Network → xem request body |
| Data trống nhưng DB có | `EmployeeID` mismatch (varchar có leading zeros) hoặc filter ngày sai | Chạy thẳng `EXEC <proc_API> @LoginID=3, @LanguageID='VN'` trong SSMS |
| `'Cannot insert NULL into column ''html'''` | Insert thiếu cột notnull của `tblHtmlScriptCache` | Phải fill cả 5 cột notnull (`html`, `HtmlParadise`, `paradiseJs`, `Version`, `VersionData`) — xem [07_menu_system.md §10](07_menu_system.md) |

---

## 8. File tham chiếu sẵn sàng triển khai

| Mục đích | File |
|---|---|
| Script deploy đầy đủ menu Hello world Vietinsoft (đã được cập nhật để hiển thị Top 3 ranking) | [SQL script/deploy_menu_HelloWorldVietinsoft_20260520.sql](../SQL%20script/deploy_menu_HelloWorldVietinsoft_20260520.sql) |
| Script cleanup menu ASPX-style lỗi thời (kiểu menu Web duy nhất bị deprecated) | [SQL script/cleanup_menu_aspx_20260520.sql](../SQL%20script/cleanup_menu_aspx_20260520.sql) |
| Tri thức nền: 5 mảnh dữ liệu, cờ nền tảng, refresh, HTML cache | [07_menu_system.md](07_menu_system.md) |
| Phân quyền: `FullAccess` map, data scope, inheritance | [11_permissions.md](11_permissions.md) |
| Cờ tách 3 nền tảng Desktop/Web/Mobile | [01_architecture.md](01_architecture.md) |
| Bảng `tblEmployee` + cấu trúc hồ sơ NV | [02_db_employee.md](02_db_employee.md) |
