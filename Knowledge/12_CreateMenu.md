# 12 — Skill: Tạo menu Web mới trong ParadiseHR (HTML-rendered)

> Hướng dẫn end-to-end **tạo mới** menu Web kiểu HTML-rendered — kiểu duy nhất ParadiseHR đang dùng (ASPX-style đã deprecated, xem [99_deprecated.md](99_deprecated.md)).
>
> Liên quan: [07](07_menu_system.md) nền · [13](13_Migrate_Menu.md) migrate · [14](14_ParadiseStyle.md) UI · [17](17_RendererHtmlJsSafe.md) renderer JS · [18](18_FindMenuProcedure.md) tra cứu menu→proc · [11](11_permissions.md) phân quyền · [01](01_architecture.md) 3 nền tảng.

## Mục lục

1. [6 Quy tắc bắt buộc](#1-6-quy-tắc-bắt-buộc)
2. [Hai layer + Quy ước đặt tên](#2-hai-layer--quy-ước-đặt-tên)
3. [Quy trình 10 phase](#3-quy-trình-10-phase)
4. [Nhánh config-driven `tblCommonControlType_Signed`](#4-nhánh-config-driven-tblcommoncontroltype_signed)
5. [Menu mẫu "Hello world Vietinsoft"](#5-menu-mẫu-hello-world-vietinsoft)
6. [`AjaxHPAParadise` runtime API](#6-ajaxhpaparadise-runtime-api)
7. [Checklist 13 điểm](#7-checklist-13-điểm)
8. [Lỗi thường gặp](#8-lỗi-thường-gặp)
9. [Grid + Infinite Loop Scroll (Rule 6)](#9-grid--infinite-loop-scroll-rule-6)

---

> **Nếu menu có SQL backend chạy chậm, xem [26_QueryOptimization.md](26_QueryOptimization.md) để tối ưu query.**

## 1. 6 Quy tắc bắt buộc

### Rule 1 — Cấp quyền: CHỈ LoginID = 3

- ✅ `INSERT tblSC_Right_Stored(ObjectID, LoginID = 3, FullAccess = '32')` — chỉ admin.
- ❌ **KHÔNG** gọi `sp_UpdateMenuInUserRight` (tự cấp `FullAccess=32` cho **MỌI** LoginID > 0 → mở quyền toàn hệ thống).
- ➡️ User/group khác: cấp sau qua UI app hoặc script riêng.

### Rule 2 — Cờ menu HTML-rendered  và chuẩn giao diện ParadiseStyle.

Tất cả menu HTML-rendered (`MnuKPI007`, `MnuTM022`, `MnuWPT037`...) dùng **CÙNG PATTERN**:

| Cờ `MEN_Menu` | Giá trị | Lý do |
|---|---|---|
| `IsVisible` | `1` | Cho phép hiển thị |
| `IsWeb` | **`0`** | Không phải ASPX cũ |
| `ViewOnWeb` | **`0`** | ⚠️ SAI nếu để `1` |
| `isShowLayOutWeb` | **`0`** | ⚠️ SAI nếu để `1` |
| `isShowInMobileLayOut` | **`0`** | ⚠️ SAI nếu để `1` |
| `IsUseMobileDevice` | `1` | Bật cho Web HTML-rendered + Mobile |

#### phải thiết kế giao diện theo đúng chuẩn ParadiseStyle 
- Tham khảo tri thức tại file 14_ParadiseStyle.md

> Hệ thống nhận diện "menu Web HTML-rendered" qua `AssemblyName='DataSetting'` + `ClassName` trỏ cặp wrapper/renderer + có cache `tblHtmlScriptCache`. **KHÔNG** qua các cờ `ViewOnWeb`/`isShowLayOutWeb`.

### Rule 3 — Parent menu phải `IsVisible = 1`

```sql
SELECT IsVisible FROM MEN_Menu WHERE MenuID = '<ParentMenuID>';
-- Nếu = 0 → chọn parent khác.
```

Parent đã verify an toàn: `MnuKPI000` · `MnuTM000` · `MnuWPT000` · `MnuHRS000` · `MnuCSM000` · `MnuMDT000`· `MnuPRL000`· `MnuTAD000` · `MnuTM000`· `MnuSCR000`. ❌ Tránh `MnuHEP000` (Trợ giúp — `IsVisible=0`).

### Rule 4 — BẮT BUỘC `tblDataSetting` 

Mỗi menu HTML-rendered phải có **3 bảng metadata**:

| Bảng | Số dòng | Vai trò |
|---|---|---|
| `tblDataSetting` | 1 | Báo cho app: procedure HTML-rendered (`IsProcedure=1, IsShowLayout=1, ColumnDataType='html&ViewHtml', ColumnOrderBy='html&0'`) |
| `tblHtmlScriptCache` | ≥ 1/lang | HTML/CSS/JS thực |



### Rule 5 — Renderer HTML/JS an toàn

Viết renderer `<class>_html` build chuỗi `NVARCHAR(MAX)` → bắt buộc đọc [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md): 7 escape rule, cache `tblHtmlScriptCache` (MERGE 8 cột do `sp_GenerateHTMLScript` đảm nhiệm), varbinary (Msg 257), dynamic SQL config-driven, polyfill global, template + checklist 15 điểm.

### Rule 6 — Grid PHẢI dùng Infinite Loop Scroll (CẤM pager truyền thống)

Mọi menu có `dxDataGrid` hiển thị list dữ liệu **BẮT BUỘC**:

| Option | Giá trị | Ghi chú |
|---|---|---|
| `scrolling.mode` | `"infinite"` | Cuộn cận đáy → fetch next |
| `scrolling.rowRenderingMode` | `"virtual"` | Chỉ render row trong viewport |
| `scrolling.preloadEnabled` | `false` | |
| `paging.enabled` | `true` | Cần để DevExtreme tính skip/take |
| `paging.pageSize` | `50` | Chunk size (30-100) |
| `pager.visible` | **`false`** | **ẨN pager** — chìa khoá |
| `remoteOperations` | 4 cờ `true` | Delegate paging/filter/sort/search về server |
| `dataSource` | `CustomStore` | KHÔNG array tĩnh, KHÔNG `ODataStore` |
| Data SP | có `@TempTableAPIName varchar(100)=''` | Để `sp_LoadGridUsingAPI` cache temp `##<X><LoginID><LangID>` |

❌ Cấm: `scrolling.mode="standard"`, `pager.visible=true`, dataSource array, tự viết SP paging `@PageNumber/@PageSize` thay vì `sp_LoadGridUsingAPI` + `@Skip/@Take`.

Template đầy đủ + kiến trúc 3 lớp + menu mẫu `sp_CRM_ProductType_html`: [§9](#9-grid--infinite-loop-scroll-rule-6).

> **Why**: ≥30 procedure trong DB đã dùng pattern này (verify: `OBJECT_DEFINITION LIKE '%scrolling.mode%infinite%'`).

### Rule 7 — Đa ngôn ngữ: `%Placeholder%` → `tblMD_Message`

Mọi text hiển thị trên UI phải hỗ trợ đa ngôn ngữ qua cơ chế placeholder `%MessageID%`:

```
Renderer HTML:        <div>%EmployeeID%</div>
                              ↓
sp_GenerateHTMLScript quét tất cả %...% trong HTML
                              ↓
Lookup tblMD_Message WHERE MessageID = 'EmployeeID' AND Language = @Language
                              ↓
Cache VN:  <div>Mã nhân viên</div>
Cache EN:  <div>Employee ID</div>
```

**Áp dụng ở đâu**:
| Nơi dùng | Ví dụ | Cần tblMD_Message? |
|---|---|---|
| `tblCommonControlType_Signed.DisplayName` | `'%STT%'`, `'%FullName%'`, `'%OwnerID%'` | ✅ Bắt buộc |
| HTML trong renderer | `<div>%EmployeeID%</div>` | ✅ Bắt buộc |
| Label tĩnh trong T-SQL | `@title = N'Danh sách'` | ❌ Không (đã là text cứng, xử lý riêng trong renderer) |

**Bắt buộc trong migration script**:
- Mọi `%MessageID%` dùng trong `tblCommonControlType_Signed` hoặc renderer HTML → phải có `tblMD_Message` entry cho **cả VN và EN**
- Pattern idempotent:
```sql
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'OwnerID' AND Language = 'VN')
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('OwnerID', 'VN', N'Người phụ trách');
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'OwnerID' AND Language = 'EN')
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('OwnerID', 'EN', 'Owner');
```

---

## 2. Hai layer + Quy ước đặt tên

**Hai layer tách rời:**

| Layer | Bản chất | Cập nhật khi |
|---|---|---|
| **A. Metadata + UI tĩnh** | `MEN_Menu` + `tblSC_Object` + `tblMD_Message` + HTML/CSS/JS trong `tblHtmlScriptCache` | Tạo / đổi tên / sửa UI |
| **B. Data runtime** | Procedure API gọi qua `AjaxHPAParadise` | Khi data thay đổi — KHÔNG rebuild cache |

**Quy ước đặt tên:**

| Thành phần | Mẫu | Ví dụ |
|---|---|---|
| `MenuID` | `Mnu<MODULE><N>` | `MnuHEP910` |
| `ClassName` (= wrapper) | `sp_<TenNghiepVu>` | `sp_HelloWorldVietinsoft` |
| Renderer | `<ClassName>_html` | `sp_HelloWorldVietinsoft_html` |
| API runtime | `sp_<TenNghiepVu>_<Action>` | `sp_HelloWorldVietinsoft_GetTopRank` |
| `ObjectName` | `<AssemblyName>.<ClassName>` | `DataSetting.sp_HelloWorldVietinsoft` |
| Cache key | `<ClassName>_html` | `sp_HelloWorldVietinsoft_html` |

Tự sinh `MenuID` mới: lấy `MAX(số sau 6 ký tự)` trong nhóm + 1 (proc `sp_s_CreateMenu` tự làm — xem [07 §6](07_menu_system.md)).

---

## 3. Quy trình 10 phase

### Phase 0 — Khảo sát thông tin (BẮT BUỘC, trước mọi phase khác)

> ⚠️ **Khi user yêu cầu tạo menu mới, Agent PHẢI hỏi đủ 6 câu dưới đây trước khi tiến hành bất kỳ thao tác kỹ thuật nào.** Không được bỏ qua bước này.

Agent cần khảo sát tuần tự các thông tin sau:

| # | Câu hỏi | Mục đích | Ánh xạ tới phase |
|---|---|---|---|
| 0.1 | **Tên menu là gì?** (tiếng Việt) | Tên hiển thị trong cây menu → `tblMD_Message` (`Language='VN'`) | Phase D |
| 0.2 | **Bạn có muốn tôi tự dịch tên menu sang tiếng Anh không?** | Nếu user đồng ý → Agent tự dịch và điền `@TextEN`. Nếu không → hỏi tiếp tên tiếng Anh | Phase D |
| 0.3 | **Thuộc menu cha nào?** (vd: `MnuKPI000`, `MnuHRS000`, `MnuWPT000`...) | `@ParentMenuID` trong `sp_s_CreateMenu`. Agent phải **verify `IsVisible=1`** trước khi chấp nhận (Rule 3) | Phase D |
| 0.4 | **Tên thủ tục (stored procedure) cần gắn vào menu này là gì?** | `@ClassName` — wrapper procedure sẽ được tạo. Agent tự suy ra tên renderer (`<ClassName>_html`) và các API runtime | Phase A, B, C |
| 0.5 | **Phân quyền menu này cho nhóm (Group) hay cho riêng LoginName?** | Quyết định ghi `tblSC_GroupRight` (nhóm) hay `tblSC_Right_Stored` (cá nhân). Ngoài ra **luôn cấp cho `LoginID=3`** (Rule 1) | Phase G |
| 0.6 | **Cho tôi biết tên nhóm hoặc LoginName đó?** | Xác định `UserGroupID` hoặc `LoginID` cụ thể để cấp `FullAccess=32` | Phase G |

**Quy tắc khảo sát:**
- Hỏi **tuần tự** từ 0.1 → 0.6. Mỗi câu trả lời có thể ảnh hưởng đến câu sau.
- Với câu 0.3: Agent phải **tự verify** `ParentMenuID` có `IsVisible=1` trong DB trước khi confirm với user.
- Với câu 0.4: Agent tự suy ra quy ước đặt tên: `ClassName` → renderer `ClassName_html` → API `ClassName_<Action>` → cache key `ClassName_html`.
- Với câu 0.5–0.6: Agent cần tra cứu DB để xác nhận tên group/LoginName tồn tại trước khi dùng.
- **KHÔNG được phép skip bất kỳ câu nào.** Nếu user không cung cấp đủ thông tin, Agent phải hỏi lại.

```
[0] Khảo sát thông tin          → Hỏi đủ 6 câu: tên VN, tên EN, parent, procedure, group/login, tên group/login
[A] Thiết kế nguồn data        → quyết định procedure API runtime
[B] Cặp procedure UI           → <class>_html (renderer) + <class> (wrapper đọc cache)
[C] Procedure API runtime      → sp_<X>_<Action>: SELECT data từ DB
[D] Metadata menu              → sp_s_CreateMenu hoặc INSERT thủ công 3 bảng
[D2] tblDataSetting            → 1 row (IsProcedure=1, IsShowLayout=1, ColumnDataType='html&ViewHtml') 
[E] Cờ nền tảng                → IsWeb=0, ViewOnWeb=0, isShowLayOutWeb=0, isShowInMobileLayOut=0, IsUseMobileDevice=1
[F] Build cache                → EXEC sp_GenerateHTMLScript '<class>_html'
[G] Quyền                      → INSERT tblSC_Right_Stored(LoginID=3, FullAccess='32') + group/login từ khảo sát
[H] Refresh menu cache         → EXEC sp_Men_Menu_AfterSave_Simple @ClassName='<ClassName>'
[I] User logout/login          → Click menu → wrapper trả HTML → JS gọi API runtime
```

> ⚠️ **Phase D2 + D3** dễ bị bỏ sót → màn hình trắng (Rule 4).

---

## 4. Nhánh config-driven `tblCommonControlType_Signed`

Pattern build UI từ metadata control — dùng rộng cho grid/form chuẩn (CRM, REC, Train, KPI).

### 4.1 Vai trò các thành phần

| Thành phần | Vai trò |
|---|---|
| `tblCommonControlType_Signed` | Lưu config control/grid theo `TableName`, `ColumnName`, `Type`, `Layout`, `DataSourceSP`, `UID`, `SPLoadData`. Mỗi `TableName` = renderer; mỗi row = 1 control |
| `sptblCommonControlType_Signed_DUC @TableName` | Đọc metadata, sinh `html`/`loadUI`/`loadData`, **UPDATE ngược** 3 cột vào bảng. Side-effect là chính |
| Renderer `<class>_html` | Viết HTML khung + nhúng `loadUI`/`loadData` bằng dynamic SQL trỏ `UID` |
| `sp_GenerateHTMLScript '<class>_html'` | Build cache `tblHtmlScriptCache` (VN+EN) |

### 4.2 Schema `tblCommonControlType_Signed` (verify từ DB 2026-05-21)

PK = `ID` (varchar(36), default `[dbo].[fn_UUIDv7_Min]()`); các cột khác **nullable**. Cột thực sự dùng:

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `TableName` | nvarchar(400) | = `<class>_html` (group key) |
| `ColumnName` | nvarchar(400) | Tên cột data; hoặc tên grid container (`GridCustomer`) |
| `Type` | varchar(64) | `hpaControlGrid` / `hpaControlGrid_Duc` / `hpaControlText` / `hpaControlDate` / `hpaControlSelectEmployee` / `hpaControlSelectBox` / `hpaControlTagBox` / `hpaControlSegmented` / `hpaControlNumber` / `hpaControlMoney` / `hpaControlDateTime` / `hpaControlTime` / `hpaControlPhone` / `hpaControlFile` / `hpaControlRichTextEditor(Premium)` / `hpaControlTextArea` / `hpaControlPipeline` / `hpaControlCheckBox` (Grid-only) / `hpaControlLink` (Grid-only) / `AdvancedFilterPanel`. **NULL** = column con của Grid (`Layout='Grid_View'`) |
| `Layout` | nvarchar(400) | `'Grid_View'` cho grid + column; `'Card_View'` cho form card; NULL cho form |
| `DataSourceSP` | varchar(100) | SP load options dropdown → JS `loadDataSourceCommon` → `window["DataSource_<ColumnName>"]` |
| `SPLoadData` | varchar(100) | (Grid container) SP nghiệp vụ trả data grid |
| `ColumnIDName` | nvarchar(400) | PK field name → `window.currentRecordID_<X>` |
| `TableEditor` | varchar(200) | Bảng vật lý cho lookup `column_id` qua `sys.columns` |
| `DisplayName` | nvarchar(512) | Header column |
| `GridColumnName` | varchar(100) | (Column row) trỏ tới `ColumnName` của grid container |
| `GridWidth` | varchar(20) | Width pixel column |
| `AllowSorting`/`AllowFiltering` | bit | 1/0 |
| `UID` | varchar(33) | `'P' + 32 ký tự`. Để NULL → proc tự sinh random. **Renderer dynamic SQL cần UID deterministic** để idempotent. ⚠️ **PHẢI UNIQUE TOÀN BỘ BẢNG** (global across all `TableName`) — nếu trùng UID với menu khác, renderer `(SELECT loadUI ... WHERE UID='...')` sẽ trả về >1 row → lỗi `Msg 512 Subquery returned more than 1 value`. Không dùng UID quá generic như `P000...G01` — thay vào đó dùng prefix riêng theo menu (vd `PUMG...` cho UserMgmt, `PCRM...` cho CRM) |
| `html`, `loadUI`, `loadData` | nvarchar(MAX) | **KHÔNG fill khi insert** — DUC tự build + UPDATE |

### 4.3 Thứ tự deploy (BẮT BUỘC)

```sql
1. DELETE FROM tblCommonControlType_Signed WHERE TableName='<class>_html'  -- idempotent
2. INSERT metadata (UID deterministic, html/loadUI/loadData NULL)
3. EXEC sptblCommonControlType_Signed_DUC '<class>_html'                   -- populate
4. CREATE OR ALTER PROCEDURE <class_Data>                                  -- procedure to get data from DB and show on the UI.
5. CREATE OR ALTER PROCEDURE <class>_html                                  -- renderer trỏ UID
6. DELETE FROM tblHtmlScriptCache WHERE TableName='<class>_html'
7. EXEC sp_GenerateHTMLScript '<class>_html'                               -- build cache
8. EXEC sp_Men_Menu_AfterSave_Simple @ClassName=N'<ClassName>'
```

> ⚠️ **DUC PHẢI EXEC TRƯỚC khi tạo renderer** — vì renderer dynamic SQL `(SELECT loadUI FROM tblCommonControlType_Signed WHERE UID='...')` cần cột `loadUI` đã có data.
>
> ⚠️ **Chỉ cần DUC khi renderer có `+(SELECT loadUI ...)` / `+(SELECT loadData ...)`** (config-driven). Nếu `tblCommonControlType_Signed` chỉ chứa data source reference (vd `hpaControlSelectBox` làm dropdown options, không inject loadUI vào renderer) thì **KHÔNG** cần DUC khi sửa renderer — chỉ cần `DELETE tblHtmlScriptCache` + `sp_GenerateHTMLScript`.
>
> ⚠️ **UID phải unique TOÀN BỘ BẢNG `tblCommonControlType_Signed`** (global, không chỉ trong 1 `TableName`). Nếu 2 menu khác nhau dùng chung UID, subquery `WHERE UID='...'` trả về >1 row → `Msg 512`. **Pattern đặt UID an toàn**: dùng prefix 3-4 ký tự viết tắt của menu + đủ 32 ký tự sau `P`. Ví dụ: `PUMG...` (UserMgmt), `PCRM...` (CRM), `PKPI...` (KPI). Không dùng UID quá generic như `P000...G01`.

### 4.4 Pattern renderer nhúng loadUI/loadData

Renderer concat HTML + `(SELECT loadUI FROM tblCommonControlType_Signed WHERE UID='<container_UID>')` + JS + `(SELECT loadData FROM ...)`. Code template + UID deterministic + bảng biến: [17_RendererHtmlJsSafe.md §4](17_RendererHtmlJsSafe.md).

### 4.5 Data API `<SPLoadData>`

Chỉ cần `@LoginID INT = 3` (framework auto-bơm). Trả 1 SELECT có **đúng các cột** matching `ColumnName` trong metadata:

```sql
CREATE OR ALTER PROCEDURE dbo.sp_LoadHelloWorldVietinsoftEmployeeList
( @LoginID INT = 3, @LanguageID VARCHAR(5) = 'VN' )
AS BEGIN
    SELECT TOP 200
        e.EmployeeID, ISNULL(e.FullName, N'') AS FullName,
        CASE WHEN e.Sex=1 THEN N'Nam' WHEN e.Sex=0 THEN N'Nữ' ELSE N'-' END AS Sex,
        CONVERT(VARCHAR(10), e.Birthday, 103) AS Birthday
    FROM tblEmployee e WHERE ISNULL(e.IsTerminated, 0) = 0;
END
```

### 4.6 ⚠️ Khi migrate sang DB khác

Phải mang theo data `tblCommonControlType_Signed` cho `TableName='<class>_html'`. Renderer dynamic-SQL đọc trực tiếp bảng metadata — DB đích thiếu data → JS lỗi `InstanceXXX is not defined` / `window.getGridConfig_XXX is not a function`. Xem [13_Migrate_Menu.md Rule 4](13_Migrate_Menu.md).

### 4.7 Ví dụ production

| Renderer | Pattern |
|---|---|
| `sp_CRM_Customers_html` | `hpaControlGrid_Duc` (read-only) — 7 column + 1 container |
| `sp_KPIProcessCustomer_html` | `hpaControlSegmented` + `hpaControlSelectEmployee` + 2×`hpaControlDate` |
| `sp_REC_Candidate_html`, `sp_Train_SubjectList_New_html`, `sp_Adjustment_html` | Form + grid |

Script template end-to-end (Hello world Vietinsoft demo grid): [update_menu_HelloWorldVietinsoft_employeelist_20260521.sql](../SQL%20script/update_menu_HelloWorldVietinsoft_employeelist_20260521.sql).

### 4.8 Lỗi thường gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| JS lỗi `InstanceXXX is not defined` | Renderer build trước DUC → `loadUI` rỗng | Đúng thứ tự: metadata → DUC → renderer → `sp_GenerateHTMLScript` |
| Grid hiện không có data | `SPLoadData` sai tên / column SELECT không khớp `ColumnName` | `EXEC <SPLoadData> @LoginID=3` thủ công kiểm tra |
| DUC báo `Invalid column name` khi join `sys.columns` | `TableEditor` trỏ bảng/cột không tồn tại | Đảm bảo bảng vật lý + có cột, hoặc NULL cho grid container |
| UI vẫn cũ sau rebuild | Chưa xoá cache cũ | `DELETE` trước `sp_GenerateHTMLScript` |
| Control hiển thị + dropdown trống trên barebones HTML-rendered | Các global helper (`loadDataSourceCommon`, `hpaUtils`, `RemoveToneMarks_Js`, `uiManager`, `LoginID`/`LanguageID`) chưa load | Polyfill 5 global trong bootstrap `<script>` trước khi inject `loadUI` — [17 §3.5](17_RendererHtmlJsSafe.md) |

---

## 5. Menu mẫu "Hello world Vietinsoft"

> Ví dụ minh hoạ Top 3 nhân viên có điểm xếp hạng cao nhất tháng. **Code đầy đủ** trong [deploy_menu_HelloWorldVietinsoft_20260520.sql](../SQL%20script/deploy_menu_HelloWorldVietinsoft_20260520.sql) + [fix_menu_HelloWorldVietinsoft_v2_20260520.sql](../SQL%20script/fix_menu_HelloWorldVietinsoft_v2_20260520.sql).

### 5.1 Bảng tham gia

| Bảng | Cột chính | Vai trò |
|---|---|---|
| `tblRank_PersonalRating_Detail` | `EmployeeID` (varchar), `ExperiencePonits` (int — typo gốc, KHÔNG sửa), `Coin`, `CreatedDate`, `PointType` | Fact điểm/coin |
| `tblEmployee` | `EmployeeID`, `FullName` | Lookup tên — xem [02](02_db_employee.md) |
| `tblHtmlScriptCache` | 8 cột — xem [07 §10](07_menu_system.md) | Cache HTML/CSS/JS |

### 5.2 Procedure API runtime (Phase C)

```sql
CREATE PROCEDURE dbo.sp_HelloWorldVietinsoft_GetTopRank
( @LoginID INT, @LanguageID VARCHAR(5)='VN',
  @FilterYear INT=NULL, @FilterMonth INT=NULL )
AS BEGIN
    SET NOCOUNT ON;
    IF @FilterYear IS NULL  SET @FilterYear  = YEAR(GETDATE());
    IF @FilterMonth IS NULL SET @FilterMonth = MONTH(GETDATE());

    DECLARE @FromDate DATETIME = DATEFROMPARTS(@FilterYear, @FilterMonth, 1);
    DECLARE @ToDate   DATETIME = DATEADD(MONTH, 1, @FromDate);

    SELECT TOP 3 r.EmployeeID, ISNULL(e.FullName, r.EmployeeID) AS FullName,
                 SUM(r.ExperiencePonits) AS TotalPoints, SUM(r.Coin) AS TotalCoin,
                 @FilterYear AS FilterYear, @FilterMonth AS FilterMonth
    FROM tblRank_PersonalRating_Detail r
    LEFT JOIN tblEmployee e ON e.EmployeeID = r.EmployeeID
    WHERE r.CreatedDate >= @FromDate AND r.CreatedDate < @ToDate
    GROUP BY r.EmployeeID, e.FullName
    ORDER BY TotalPoints DESC, r.EmployeeID ASC;
END
```

### 5.3 Renderer + Wrapper (Phase B)

- **Renderer** `sp_HelloWorldVietinsoft_html`: build chuỗi HTML/CSS/JS, gọi API qua `AjaxHPAParadise`, kết thúc bằng `SELECT @html AS html;`. Cache `tblHtmlScriptCache` do `sp_GenerateHTMLScript` xử lý UPSERT đủ 8 cột cho cả VN + EN.
- **Wrapper** `sp_HelloWorldVietinsoft`: `SELECT TOP 1 html FROM tblHtmlScriptCache WHERE TableName='sp_HelloWorldVietinsoft' AND ScreenType='-1' AND LanguageID=@LanguageID`.

Code đầy đủ: xem 2 script đã liệt kê đầu §5.

### 5.4 Metadata menu (Phase D, D2, D3, E)

```sql
-- Phase D: tạo menu + 3 bảng metadata + cấp LoginID=3
EXEC dbo.sp_s_CreateMenu
     @Text=N'Hello world Vietinsoft', @TextEN='Hello world Vietinsoft',
     @ClassName='sp_HelloWorldVietinsoft',
     @ParentMenuID='MnuKPI000',      -- VERIFY IsVisible=1 trước!
     @AssemblyName='DataSetting',
     @Option=1, @LoginIDList='3';

-- Phase D2: tblDataSetting (1 row, full notnull defaults — xem fix script)
INSERT INTO tblDataSetting (TableName, ViewName, IsProcedure, IsShowLayout,
    ColumnOrderBy, ColumnDataType, ColumnHide, ControlHiddenInShowLayout, /* + nhiều cột notnull */)
VALUES ('sp_HelloWorldVietinsoft', 'sp_HelloWorldVietinsoft', 1, 1,
    'html&0', 'html&ViewHtml', 'isReadOnlyRow,dtftxxENGColumns',
    'grdTableEditor,txtFilter,btnReload,btnFWDelete,btnFWReset,btnExport,btnFWSave,btnFWAdd,isReadOnlyRow,dtftxxENGColumns', /* ... */);


-- Phase E: cờ menu (đảm bảo Rule 2)
UPDATE MEN_Menu
   SET IsVisible=1, IsWeb=0, ViewOnWeb=0, isShowLayOutWeb=0,
       IsUseMobileDevice=1, isShowInMobileLayOut=0, Priority=99
       glyphicon=N'Info', GroupID='MnuKPI000'
 WHERE MenuID='MnuHEP910';
```

### 5.5 Build cache + Refresh (Phase F + H)

```sql
-- Phase F: build cache HTML (cách DUY NHẤT)
EXEC dbo.sp_GenerateHTMLScript 'sp_HelloWorldVietinsoft_html';

-- Phase H: refresh menu (CHỈ 1 lệnh, LUÔN truyền @ClassName)
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_HelloWorldVietinsoft';
```

> Sau Phase H: user logout/login → chỉ admin (LoginID=3) thấy. Cấp quyền cho user/group khác sau qua UI app hoặc script riêng.

---

## 6. `AjaxHPAParadise` runtime API

### 6.1 Cú pháp chuẩn

```javascript
AjaxHPAParadise({
    data: {
        name:  "<TenProcedure>",
        param: ["ParamName1", value1, "ParamName2", v2]   // MẢNG PHẲNG
    },
    success: function(res) {
        var json = typeof res === "string" ? JSON.parse(res) : res;
        var rows1 = json.data[0] || [];   // result-set 1
        var rows2 = json.data[1] || [];   // result-set 2
    },
    error: function(err) { /* ... */ },
    xhrFields: { responseType: "blob" }   // optional: tải file/ảnh
});
```

Verified từ: `sp_Train_Ranking_Template_html`, `sp_KPIProcessCustomer_html`.

### 6.2 Quy tắc

- `param`: **mảng phẳng** `[name, value, ...]`, KHÔNG object `{name: value}`. `name` không kèm `@` (framework tự thêm). Có thể `params.push(...)` động.
- Procedure API: tối thiểu nhận `@LoginID INT` + `@LanguageID VARCHAR(5)='VN'`. Tham số filter có `DEFAULT NULL`. Mỗi `SELECT` thành 1 phần tử `json.data`.
- Lấy file/ảnh: gọi `paradisefile_sp_GetFileAPI` với `xhrFields: { responseType: "blob" }`, rồi `URL.createObjectURL(blob)` gán vào `img.src`.

---

## 7. Checklist 15 điểm

1. ☐ **Phase 0 — Khảo sát đủ 6 câu**: tên VN, tên EN (hoặc tự dịch), parent menu, procedure, group/LoginName, tên group/LoginName.
2. ☐ **`MenuID` không trùng** — `SELECT * FROM MEN_Menu WHERE MenuID='<id>'`.
3. ☐ **Parent menu** `IsVisible=1` (Rule 3). Né `MnuHEP000`.
4. ☐ **Cờ Rule 2**: `IsWeb=0, ViewOnWeb=0, isShowLayOutWeb=0, isShowInMobileLayOut=0, IsUseMobileDevice=1`.
5. ☐ **Phase D2 (Rule 4)** — `tblDataSetting` 1 row đủ `IsProcedure=1, IsShowLayout=1, ColumnOrderBy='html&0', ColumnDataType='html&ViewHtml'`. 
7. ☐ Renderer UPSERT cache cho **cả VN và EN**.
8. ☐ Wrapper `SELECT TOP 1 html` lọc `(TableName, ScreenType='-1', LanguageID)`.
9. ☐ Procedure API có `@LoginID` + `@LanguageID`.
10. ☐ JS gọi `AjaxHPAParadise` với `param` **mảng phẳng**.
11. ☐ Phase G — CHỈ `LoginID = 3` + group/LoginName từ khảo sát.
12. ☐ Phase H — CHỈ `sp_Men_Menu_AfterSave_Simple @ClassName='...'`. KHÔNG `sp_UpdateMenuInUserRight`.
13. ☐ Verify logout/login → menu hiện → click → render OK → DevTools Network xem POST `AjaxHPAParadise` đúng `name` + `param`.
14. ☐ **(Rule 6) Nếu có `dxDataGrid`**: `scrolling.mode="infinite"`, `pager.visible=false`, `remoteOperations` đủ 4 cờ, `CustomStore` gọi `sp_LoadGridUsingAPI` với `@Skip/@Take`. Data SP có `@TempTableAPIName`. Xem [§9](#9-grid--infinite-loop-scroll-rule-6).
15. ☐ **Phase 0 verify** — tên group/LoginName từ khảo sát đã được xác nhận tồn tại trong DB trước khi gán quyền.

---

## 8. Lỗi thường gặp

| Triệu chứng | Nguyên nhân | Cách kiểm tra |
|---|---|---|
| Menu không hiện trong cây (đã có quyền + logout/login) | (1) Sai cờ Web (Rule 2); (2) parent `IsVisible=0` (vd `MnuHEP000`); (3) menu `IsVisible=0` | `SELECT m.MenuID, m.IsVisible, m.IsWeb, m.ViewOnWeb, m.isShowLayOutWeb, m.IsUseMobileDevice, m.isShowInMobileLayOut, p.IsVisible AS ParentVisible FROM MEN_Menu m LEFT JOIN MEN_Menu p ON p.MenuID=m.ParentMenuID WHERE m.MenuID IN ('<id>','MnuKPI007')` |
| Mở menu thấy "loading..." không kết thúc | Cache chưa build | `SELECT DATALENGTH(html) FROM tblHtmlScriptCache WHERE TableName='<class>_html' AND LanguageID='VN'` → nếu rỗng: `EXEC dbo.sp_GenerateHTMLScript '<class>_html'` |
| HTML cũ sau khi sửa | Cache chưa rebuild | `DELETE FROM tblHtmlScriptCache WHERE TableName='<class>_html'; EXEC dbo.sp_GenerateHTMLScript '<class>_html'` |
| JS gọi API lỗi 500 | `param` sai (object thay vì array) / thiếu `@LoginID`/`@LanguageID` | DevTools Network xem body |
| Data trống nhưng DB có | `EmployeeID` mismatch (leading zeros) / filter ngày sai | `EXEC <proc> @LoginID=3, @LanguageID='VN'` trong SSMS |
| `Cannot insert NULL into column 'html'` | Thiếu cột notnull của `tblHtmlScriptCache` | Fill đủ 5 cột notnull — [07 §10](07_menu_system.md) |
| `Msg 201: ... expects parameter '@ClassName'` | Gọi refresh thiếu `@ClassName` | `EXEC sp_Men_Menu_AfterSave_Simple @ClassName=N'<ClassName>'` |
| Menu hiện đúng UI nhưng MỌI user đều thấy | Đã gọi `sp_UpdateMenuInUserRight` (Rule 1 vi phạm) | `DELETE FROM tblSC_Right_Stored WHERE ObjectID=<id> AND LoginID<>3` — cấp lại qua UI |
| Cần cấp cho user/group khác | Script tạo menu chỉ cấp LoginID=3 | UI app, hoặc `INSERT tblSC_Right_Stored(ObjectID, LoginID, FullAccess='32')` / `INSERT tblSC_GroupRight(...)` |

### Hành vi `sp_UpdateMenuInUserRight` (THAM KHẢO — KHÔNG dùng)

Verify từ source DB: insert `tblSC_Right_Stored(ObjectID, LoginID, FullAccess=32)` cho **MỌI LoginID > 0** trong `tblSC_Login`; update `FullAccess=32` cho row đã có → mở quyền menu cho tất cả user.

---

## 9. Grid + Infinite Loop Scroll (Rule 6)

> Chuẩn DUY NHẤT cho mọi list dữ liệu trong menu HTML-rendered. Copy template + chỉnh params theo nghiệp vụ.

### 9.1 Kiến trúc 3 lớp

```
┌─ Lớp 1 — UI Browser (renderer JS) ────────────────────────────────┐
│ dxDataGrid + DevExpress.data.CustomStore                          │
│  • scrolling.mode = "infinite"                                    │
│  • pager.visible  = false                                         │
│  • load(loadOptions) → DevExtreme tự cấp { skip, take, ... }      │
└──────────────────────────┬────────────────────────────────────────┘
                           │ AjaxHPAParadise (POST)
                           │ name = "sp_LoadGridUsingAPI"
                           ▼
┌─ Lớp 2 — Orchestrator (universal grid loader) ────────────────────┐
│ sp_LoadGridUsingAPI                                               │
│  • Lần đầu: EXEC <@ProcName> @TempTableAPIName='##<X><LoginID><LangID>' │
│  • Lần sau: SELECT * FROM ##<table> + WHERE + ORDER BY            │
│             + OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY        │
│  • Trả về : { data, totalCount?, summary? }                       │
└──────────────────────────┬────────────────────────────────────────┘
                           │ EXEC … @TempTableAPIName=…
                           ▼
┌─ Lớp 3 — Data SP (nghiệp vụ) ─────────────────────────────────────┐
│ sp_<Tên>List                                                      │
│  • PHẢI có param @TempTableAPIName varchar(100)=''                │
│  • SELECT data vào #tmpTableData                                  │
│  • Dynamic: SELECT * INTO @TempTableAPIName FROM #tmpTableData    │
└───────────────────────────────────────────────────────────────────┘
```

### 9.2 Menu mẫu — `sp_CRM_ProductType_html` (đơn giản nhất, 19 KB)

**Data SP** (lớp 3):

```sql
CREATE PROCEDURE sp_CRM_ProductTypeList
( @LoginID int=3, @LanguageID varchar(5)='VN',
  @TempTableAPIName varchar(100)='' )     -- ← BẮT BUỘC
AS BEGIN
    SELECT ROW_NUMBER() OVER (ORDER BY ProductTypeID) AS STT,
           ProductTypeID, ProductTypeName,
           CASE WHEN @LanguageID='VN' THEN cd.ContractDetailTypeName ELSE cd.ContractDetailTypeNameEN END AS ContractDetailTypeName,
           cd.ContractDetailType
    INTO #tmpTableData
    FROM tblWH_ProductType pt
    LEFT JOIN tblCRM_Contact_Detail_Type cd ON pt.ContractDetailType = cd.ContractDetailType;

    DECLARE @sql nvarchar(max);
    IF (@TempTableAPIName = '')
        SET @sql = N'SELECT * FROM #tmpTableData';
    ELSE
        SET @sql = N'SELECT * INTO ' + QUOTENAME(@TempTableAPIName) + N' FROM #tmpTableData';
    EXEC sp_executesql @sql;
    DROP TABLE #tmpTableData;
END
```

**Renderer JS** (lớp 1 - Mẫu cấu trúc chuẩn và tối giản cho Grid được trình bày đầy đủ ở mục 9.2.1 ngay bên dưới).



### 9.2.1 Cấu trúc JS CustomStore chuẩn và tối giản cho Grid

Dưới đây là cấu trúc Javascript CustomStore và cấu hình đè Grid tối giản (không cần DateBox lọc, không có stats và các nút lọc). Mẫu này tập trung hoàn toàn vào cấu trúc chuẩn của grid và `dataSource` (sử dụng `CustomStore` kết nối API `sp_LoadGridUsingAPI` hỗ trợ phân trang infinite scroll, sắp xếp, tìm kiếm):

> [!IMPORTANT]
> **Quy chế tích hợp Toolbar & Event của Hệ thống**:
> Khi cờ hiển thị toolbar hệ thống được bật (ví dụ: `_showtoolbarGrid_<uidGrid>` = true), hệ thống đã tích hợp sẵn nút **Tải lại (Reload)** và nút **Thêm mới (+)**:
> - Nút **Tải lại** tự động gọi hàm cục bộ tên là `Reload()`.
> - Nút **Thêm mới (+)** tự động gọi hàm cục bộ theo cú pháp: `add` + `PKColumn` (Ví dụ PKColumn là `ExampleKey` thì hàm là `addExampleKey()`).
> - Sự kiện mở chi tiết dòng (click/dblclick) tự động gọi hàm cục bộ theo cú pháp: `openDetail` + `PKColumn` (Ví dụ: `openDetailExampleKey(rowData)`).
>
> Vì vậy, ta cần đặt tên hàm cục bộ chính xác theo các quy tắc trên. Không cần chèn thủ công các nút này qua sự kiện `onToolbarPreparing`.

1. **Encapsulation (Hàm cục bộ)**: Các hàm callback `add<PKColumn>` và `openDetail<PKColumn>` được khai báo dạng local function bên trong IIFE để tránh xung đột biến toàn cục và khớp với sự kiện tự động từ hệ thống.
2. **Offline/Local Cache slicing**: Lưu trữ và đọc dữ liệu từ cache cục bộ `DataSource` khi `api = false`.
3. **Filter Safety Check**: Lọc bỏ các Javascript Function trong điều kiện filter trước khi chuyển thành SQL query.
4. **Dynamic Total Summary**: Ánh xạ động các summary types của DevExtreme.
5. **Grid Config Override**: Đè các cấu hình bắt buộc như `scrolling.mode: "infinite"`, `remoteOperations` và gán `dataSource`.

### 9.3 Cache temp table (lớp 2)

`sp_LoadGridUsingAPI` đặt tên: `@TableDataName = '##' + @ProcName + cast(@LoginID as nvarchar) + @LanguageID` (vd `##sp_CRM_ProductTypeList3VN`).

- **Lần đầu** (object_id NULL HOẶC requireTotalCount=1 + filter rỗng): EXEC data SP, materialize toàn bộ vào global temp.
- **Page tiếp**: chỉ `SELECT * FROM ##... WHERE + ORDER BY + OFFSET FETCH` trên temp.
- **Đổi search/filter**: JS clear `_pageCache` + `gridInstance.refresh()` → reload từ skip=0.

⇒ Data SP chỉ chạy 1 lần/user/session/lang.

### 9.4 Lỗi thường gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Grid load toàn bộ + có pager số trang | Thiếu `scrolling.mode="infinite"` + `pager.visible=false` | Bổ sung 2 option |
| Cuộn xuống không load thêm | Thiếu `remoteOperations.paging=true` HOẶC dataSource array tĩnh | Wrap trong `new CustomStore({ key, load })` |
| Cuộn lại re-run Data SP đầy đủ | Data SP thiếu `@TempTableAPIName` | Thêm `@TempTableAPIName varchar(100)=''` + dynamic INTO |
| Search/Filter không reset về đầu | Thiếu `onOptionChanged` clear `_pageCache` + `refresh()` | Copy block onOptionChanged §9.2 |
| TotalCount = 0/undefined | Không push `@RequireTotalCount=1` | Push khi `loadOptions.requireTotalCount` true |

### 9.5 Menu thực tế dùng pattern này

≥30 procedure (verify: `OBJECT_DEFINITION LIKE '%scrolling.mode%infinite%'`):

- **CRM**: `sp_CRM_ProductType_html`, `sp_CRM_CustomerList_html`, `sp_CRM_ContractType_html`, `sp_CRM_ContractDetailTypeList_Menu_html`
- **KPI**: `sp_KPIContentPost_html`, `sp_KPIListEmailManual_html`, `sp_KPIProcessCustomer_html`
- **Đào tạo**: `sp_TrainNew_KnowLedgeGroup_html`, `sp_SubjectManagement_html`, `sp_Train_SubjectList_New_html`, `sp_EditSubject_html`, `sp_Train_Dashboard_New_html`
- **Tuyển dụng**: `sp_REC_PopupAddNewJob_html`
- **Sản phẩm**: `sp_Sub_SubProduct_html`, `sp_Sub_SubQuotation_html`
- **Khác**: `sp_Adjustment_html`, `sp_DataFilter_html`, `sp_UserHunryTask_html`, `sp_CollectingDataGoogleMap_html`, `sp_zalo_autoSendMessage_html`

### 9.6 Các hàm tiện ích giao diện chung (UI Helpers)

Xem chi tiết hướng dẫn sử dụng và ví dụ đầy đủ của `uiManager.showAlert` và `showConfirmPopup` tại tài liệu riêng: [22_UI_Helpers.md](22_UI_Helpers.md).

---

## File tham chiếu

| Mục đích | File |
|---|---|
| Template config-driven grid (Hello world employee list) | [update_menu_HelloWorldVietinsoft_employeelist_20260521.sql](../SQL%20script/update_menu_HelloWorldVietinsoft_employeelist_20260521.sql) |
| Template ParadiseStyle (Top 3 ranking) | [update_menu_HelloWorldVietinsoft_paradisestyle_20260521.sql](../SQL%20script/update_menu_HelloWorldVietinsoft_paradisestyle_20260521.sql) |
| Deploy ban đầu Hello world | [deploy_menu_HelloWorldVietinsoft_20260520.sql](../SQL%20script/deploy_menu_HelloWorldVietinsoft_20260520.sql) |
| Fix D2+D3 (template INSERT đầy đủ notnull) | [fix_menu_HelloWorldVietinsoft_v2_20260520.sql](../SQL%20script/fix_menu_HelloWorldVietinsoft_v2_20260520.sql) |
| Cleanup ASPX-style deprecated | [cleanup_menu_aspx_20260520.sql](../SQL%20script/cleanup_menu_aspx_20260520.sql) |
| Tri thức nền menu | [07_menu_system.md](07_menu_system.md) |
| Phân quyền | [11_permissions.md](11_permissions.md) |
| 3 nền tảng Desktop/Web/Mobile | [01_architecture.md](01_architecture.md) |
| `tblEmployee` schema | [02_db_employee.md](02_db_employee.md) |
