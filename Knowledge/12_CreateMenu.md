# 12 — Skill: Quy trình tạo menu Web mới trong ParadiseHR

> **Skill file** — hướng dẫn lập trình viên mới triển khai trọn vẹn 1 menu Web kiểu HTML-rendered (kiểu duy nhất ParadiseHR hiện dùng — kiểu ASPX-style đã lỗi thời, xem [99_deprecated.md §5](99_deprecated.md) và [99_deprecated.md §7](99_deprecated.md)).
>
> Liên quan: [07_menu_system.md](07_menu_system.md) (tri thức nền), [11_permissions.md](11_permissions.md) (phân quyền), [01_architecture.md](01_architecture.md) (3 nền tảng + cờ), [14_ParadiseStyle.md](14_ParadiseStyle.md) (chuẩn thiết kế UI — không thiết lập background cho menu).
>
> 🔍 **Cần debug menu có sẵn (không phải tạo mới)?** Xem [18_FindMenuProcedure.md](18_FindMenuProcedure.md) — quy trình 5 bước tra cứu từ tên menu → procedure.
>
> Ví dụ minh hoạ xuyên suốt file: menu **"Hello world Vietinsoft"** (`MnuHEP910`) hiển thị **Top 3 nhân viên có điểm xếp hạng cao nhất tháng hiện tại** — gọi API runtime qua `AjaxHPAParadise`.

---

## ⚠️ 2 QUY TẮC BẮT BUỘC (đọc trước tiên)

### Rule 1 — Cấp quyền

Mọi script tạo menu mới **PHẢI** tuân thủ:

1. ✅ Chỉ `INSERT tblSC_Right_Stored(ObjectID, LoginID = 3, FullAccess = '32')`. **Không bao giờ** cấp cho LoginID khác / UserGroupID khác / tất cả user trong script tạo menu.
2. ❌ **TUYỆT ĐỐI KHÔNG** gọi `EXEC sp_UpdateMenuInUserRight @ObjectID = ...` trong script tạo menu, vì proc này tự cấp `FullAccess = 32` cho **TẤT CẢ LoginID > 0** trong `tblSC_Login` → mở quyền menu cho mọi user, **vượt phạm vi cần thiết**.
3. ➡️ Sau khi script chạy xong, **user tự cấp quyền** cho các user/group khác bằng giao diện phân quyền trong app, hoặc **tự viết script riêng** để cấp quyền hàng loạt cho `tblSC_Right_Stored` / `tblSC_GroupRight`.
4. ✅ Phase H chỉ chạy `EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>'` để refresh cache layout. **KHÔNG** thêm bất kỳ proc nào khác.

### Rule 2 — Pattern cờ cho menu HTML-rendered (rất dễ sai)

Tất cả menu Web HTML-rendered đang chạy thực tế trong DB (`MnuKPI007` Sales Pipeline, `MnuTM022` Xếp hạng nhân viên, `MnuWPT037` Danh sách phê duyệt) đều dùng **CÙNG MỘT PATTERN** sau, **KHÔNG** có ngoại lệ:

| Cờ trong `MEN_Menu` | Giá trị BẮT BUỘC | Lý do |
|---|---|---|
| `IsVisible` | `1` | Cho phép hiển thị trong cây |
| `IsWeb` | **`0`** | Không phải ASPX-style cũ (đã deprecated) — wrapper chạy server-side, không có URL static |
| `ViewOnWeb` | **`0`** | **KHÔNG** phải `1` — đây là sai lầm phổ biến |
| `isShowLayOutWeb` | **`0`** | **KHÔNG** phải `1` |
| `isShowInMobileLayOut` | **`0`** | **KHÔNG** phải `1` |
| `IsUseMobileDevice` | `1` | Bật cho cả Web HTML-rendered (qua ParadiseWebView2) lẫn Mobile |
| `glyphicon` | tuỳ chọn | Icon hiển thị |
| `Priority` | tuỳ chọn (vd 99) | Vị trí trong cây |
| `ParentMenuID` | tuỳ chọn | **PHẢI có `IsVisible=1`** — xem Rule 3 |

> ⚠️ **Sai lầm điển hình**: nghĩ rằng "menu Web" = `ViewOnWeb=1` + `isShowLayOutWeb=1`. **SAI**. Các cờ này phải = 0. Hệ thống quyết định "menu Web HTML-rendered" qua `AssemblyName='DataSetting'` + `ClassName` trỏ tới cặp wrapper/renderer + có cache trong `tblHtmlScriptCache`.

### Rule 3 — Parent menu PHẢI `IsVisible = 1`

Trước khi chọn `ParentMenuID`, **luôn kiểm tra** parent có `IsVisible = 1` không. Nếu parent `IsVisible = 0` thì menu con cũng không hiển thị (ngay cả khi đầy đủ quyền).

```sql
SELECT MenuID, IsVisible
FROM   MEN_Menu
WHERE  MenuID = '<ParentMenuID dự định dùng>';
-- Nếu IsVisible = 0 → CHỌN parent khác.
```

Parent visible đã verify (an toàn dùng cho menu HTML-rendered mới):
- `MnuKPI000` (Trang chủ CRM) — đã có MnuKPI007 chạy OK
- `MnuTM000` (Đào tạo) — đã có MnuTM022 chạy OK
- `MnuWPT000` (Portal/WorkFlow) — đã có MnuWPT037 chạy OK
- `MnuHRS000` (Quản trị nhân sự) — đã có MnuHRS142 chạy OK

❌ KHÔNG nên dùng làm parent: `MnuHEP000` (Trợ giúp — `IsVisible=0` ở DB thực tế).

### Rule 4 — BẮT BUỘC tạo `tblDataSetting` + `tblDataSettingLayout` cho mỗi menu HTML-rendered

Đây là rule **dễ bỏ sót nhất**, gây triệu chứng "click menu thấy màn hình trắng" (menu hiển thị trong cây + có quyền + có cache HTML, nhưng app không biết kiểu render).

Mỗi menu HTML-rendered **PHẢI** có **3 bảng metadata** sau (verify từ `MnuKPI447` Doanh số, `MnuTM022` Xếp hạng, `MnuWPT037` Danh sách phê duyệt — tất cả đều đầy đủ 3 bảng):

| Bảng | Số dòng cần | Vai trò |
|---|---|---|
| `tblDataSetting` | 1 dòng | Báo cho app biết menu là procedure HTML-rendered (`IsProcedure=1, IsShowLayout=1`) + chỉ định cột render html (`ColumnDataType='html&ViewHtml'`, `ColumnOrderBy='html&0'`) |
| `tblDataSettingLayout` | **2 dòng**: `root` + `lblhtml` | Định nghĩa container `ParadiseWebView2` chiếm 100% chiều rộng. Thiếu 2 dòng này → app render menu thành màn hình trắng. |
| `tblHtmlScriptCache` | ≥ 1 dòng / language | HTML/CSS/JS thực do renderer sinh ra |

**Triệu chứng nếu thiếu `tblDataSetting`/`tblDataSettingLayout`**: menu xuất hiện trong cây → click vào → màn hình trắng (no content). Đầy đủ quyền, cờ Web đúng, cache HTML có sẵn → vẫn không hiển thị.

Đây là rule **không có ngoại lệ** — kể cả khi user chỉ nói "tạo menu mới" mà không nhắc đến cờ/parent/DataSetting, vẫn áp dụng đúng cả 4 rule này.

### Rule 5 — Renderer HTML/JS phải an toàn (xem skill riêng)

Khi viết renderer `<ClassName>_html` build HTML/CSS/JS trong chuỗi `NVARCHAR(MAX)`, **bắt buộc đọc** [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) — file skill này tổng hợp 7 quy tắc escape T-SQL → JS, pattern MERGE `tblHtmlScriptCache` 8 cột, xử lý cột varbinary (Msg 257), dynamic SQL config-driven, polyfill global helper, template copy-paste ready và checklist 15 điểm trước khi export. **KHÔNG** tự suy đoán pattern escape khi viết script.


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
[D2] tblDataSetting           → 1 dòng (IsProcedure=1, IsShowLayout=1, ColumnDataType='html&ViewHtml')  ← BẮT BUỘC
[D3] tblDataSettingLayout     → 2 dòng (root + lblhtml/ParadiseWebView2)                                ← BẮT BUỘC
[E] Set cờ nền tảng + UI      → IsWeb=0, ViewOnWeb=0, isShowLayOutWeb=0, isShowInMobileLayOut=0, IsUseMobileDevice=1
[F] Build HTML cache          → CHỈ dùng helper sp_GenerateHTMLScript '<class>_html'
[G] Phân quyền                → CHỈ tblSC_Right_Stored cho LoginID = 3 (admin). KHÔNG cấp cho user/group khác.
[H] Refresh cache menu        → CHỈ sp_Men_Menu_AfterSave_Simple @ClassName='...'. KHÔNG gọi sp_UpdateMenuInUserRight.
[I] User logout/login         → app load lại cây menu → click → wrapper trả HTML → JS gọi API runtime
```

> ⚠️ **Phase D2 + D3 là phần dễ bị bỏ sót nhất** — gây triệu chứng "click menu thấy màn hình trắng" (Rule 4).

### 3.1. Nhánh UI config-driven bằng `tblCommonControlType_Signed`

Ngoài kiểu renderer tự viết toàn bộ HTML/CSS/JS, ParadiseHR còn có nhánh build UI từ metadata control. Pattern này được dùng rộng rãi cho các màn hình có grid view / form nhiều control chuẩn (CRM, Recruitment, Training, KPI).

#### Vai trò các thành phần

| Thành phần | Vai trò |
|---|---|
| `tblCommonControlType_Signed` | Lưu cấu hình control/grid theo `TableName`, `ColumnName`, `Type`, `Layout`, `DataSourceSP`, `UID`, `SPLoadData`... Mỗi `TableName` = tên renderer (vd `sp_CRM_Customers_html`); mỗi row = 1 control (column hoặc container). |
| `sptblCommonControlType_Signed_DUC @TableName` | Đọc metadata, sinh `html`, `loadUI`, `loadData` cho từng row + **UPDATE ngược** lại 3 cột đó trong `tblCommonControlType_Signed`. Trả `SELECT @nsqlHtml AS htmlProc` (1 row, 1 cột — thường không dùng, side-effect chính mới là điều cần). |
| Renderer `<class>_html` | Viết HTML khung + nhúng `loadUI`/`loadData` của grid container bằng **dynamic SQL** trỏ theo `UID` (xem mẫu §3.1.3). Trả `SELECT @html AS html`. |
| `sp_GenerateHTMLScript '<class>_html'` | Build cache chính thức vào `tblHtmlScriptCache` cho cả VN + EN. |

#### 3.1.1. Schema `tblCommonControlType_Signed` (verify từ DB 2026-05-21)

PK = `ID` (varchar(36), default `[dbo].[fn_UUIDv7_Min]()`); tất cả các cột khác đều **nullable**.

Các cột thực sự dùng khi insert metadata:

| Cột | Kiểu | Ý nghĩa |
|---|---|---|
| `TableName` | nvarchar(400) | = tên renderer `<class>_html` (khoá nhóm các row của 1 màn hình) |
| `ColumnName` | nvarchar(400) | Tên cột data trong result-set của `SPLoadData`; với row grid container thì là tên định danh của grid (`GridCustomer`, `GridEmployees`...) |
| `Type` | varchar(64) | `hpaControlGrid` (Grid full edit), `hpaControlGrid_Duc` (Grid read-only), `hpaControlText`, `hpaControlDate`, `hpaControlSelectEmployee`, `hpaControlSelectBox`, `hpaControlTagBox`, `hpaControlSegmented`, `hpaControlNumber`, `hpaControlMoney`, `hpaControlDateTime`, `hpaControlTime`, `hpaControlPhone`, `hpaControlFile`, `hpaControlRichTextEditor`, `hpaControlRichTextEditorPremium`, `hpaControlTextArea`, `hpaControlPipeline`, `hpaControlCheckBox` (chỉ render trong Grid), `hpaControlLink` (chỉ render trong Grid), `AdvancedFilterPanel`. **NULL** = column con của Grid (Type=NULL + Layout='Grid_View'). |
| `Layout` | nvarchar(400) | `'Grid_View'` cho cả grid container + column; `'Card_View'` cho form card; NULL cho form thường |
| `DataSourceSP` | varchar(100) | Tên SP load options (dropdown/lookup). Proc sẽ sinh JS `loadDataSourceCommon` gọi qua AjaxHPAParadise, lưu vào `window["DataSource_<ColumnName>"]`. |
| `SPLoadData` | varchar(100) | Chỉ dùng với grid container — tên SP nghiệp vụ trả data grid (vd `sp_loadCRMCustomers`). |
| `ColumnIDName` | nvarchar(400) | Tên field PK của row hiện tại (sinh `window.currentRecordID_<X>`). |
| `TableEditor` | varchar(200) | Tên bảng vật lý cho lookup `column_id` qua `sys.columns` (proc dùng cho `%tableId%` placeholder). Với column row đặt là bảng gốc; với grid container row có thể để NULL. |
| `DisplayName` | nvarchar(512) | Tiêu đề hiển thị trên header column (vd `'Email'`, `'Mã số thuế'`). |
| `GridColumnName` | varchar(100) | Trên column row: trỏ tới `ColumnName` của grid container (vd `'GridCustomer'`). Trên grid container row: NULL. |
| `GridWidth` | varchar(20) | Width pixel column (vd `'200'`). |
| `AllowSorting` | bit | 1/0 |
| `AllowFiltering` | bit | 1/0 |
| `UID` | varchar(33) | `'P' + 32 ký tự` (uppercase hex hoặc bất cứ pattern nào dài 32). Nếu để NULL/rỗng, proc tự sinh `'P' + REPLACE(NEWID(),'-','')`. **Renderer cần trỏ tới UID grid container bằng dynamic SQL — đặt UID deterministic để script idempotent.** |
| `html`, `loadUI`, `loadData` | nvarchar(MAX) | KHÔNG fill khi insert — `sptblCommonControlType_Signed_DUC` sẽ tự build và UPDATE. |

#### 3.1.2. Thứ tự deploy (4 bước chuẩn)

```
1. DELETE FROM tblCommonControlType_Signed WHERE TableName='<class>_html'  -- idempotent
2. INSERT các row metadata (UID deterministic, html/loadUI/loadData để NULL)
3. EXEC sptblCommonControlType_Signed_DUC '<class>_html'                   -- populates html/loadUI/loadData
4. CREATE OR ALTER PROCEDURE <class>_html                                  -- renderer trỏ tới UID
5. DELETE FROM tblHtmlScriptCache WHERE TableName='<class>_html'           -- xoá cache cũ
6. EXEC sp_GenerateHTMLScript '<class>_html'                               -- build cache VN + EN
7. EXEC sp_Men_Menu_AfterSave_Simple @ClassName=N'<ClassName>'             -- refresh menu
```

> ⚠️ **Phải EXEC `sptblCommonControlType_Signed_DUC` TRƯỚC khi tạo renderer**, vì renderer dynamic-SQL `(SELECT loadUI FROM tblCommonControlType_Signed WHERE UID='...')` cần cột `loadUI` đã có data.

#### 3.1.3. Pattern renderer nhúng `loadUI` / `loadData` (xem skill riêng)

Renderer concat HTML khung + `loadUI` + JS bao quanh + `loadData` qua dynamic SQL subquery `(SELECT loadUI/loadData FROM tblCommonControlType_Signed WHERE UID = '<grid_container_UID>')`. **Code mẫu đầy đủ + bảng biến template + quy tắc UID deterministic**: xem [17_RendererHtmlJsSafe.md §4](17_RendererHtmlJsSafe.md). UID phải **deterministic** (vd `'P00000000000000000000000000000G01'`) để renderer + cache reproducible khi export sang DB khác.

#### 3.1.4. Pattern data API `<SPLoadData>`

Chỉ cần `@LoginID INT = 3` (framework auto-bơm). Trả 1 SELECT result-set có **đúng các cột** matching `ColumnName` trong metadata:

```sql
CREATE OR ALTER PROCEDURE dbo.sp_LoadHelloWorldVietinsoftEmployeeList
(
    @LoginID INT = 3,
    @LanguageID VARCHAR(5) = 'VN'
)
AS
BEGIN
    SELECT TOP 200
        e.EmployeeID,
        ISNULL(e.FullName, N'') AS FullName,
        CASE WHEN e.Sex = 1 THEN N'Nam' WHEN e.Sex = 0 THEN N'Nữ' ELSE N'-' END AS Sex,
        CONVERT(VARCHAR(10), e.Birthday, 103) AS Birthday,
        ...
    FROM tblEmployee e
    WHERE ISNULL(e.IsTerminated, 0) = 0;
END
```

#### 3.1.5. ⚠️ Khi migrate sang DB khác — PHẢI mang theo data `tblCommonControlType_Signed`

Khi migrate / deploy menu config-driven sang DB khác (DEV → UAT → PROD, hoặc giữa các tenant), **không được chỉ migrate procedure + `tblHtmlScriptCache`**. Bắt buộc bao gồm cả data trong `tblCommonControlType_Signed` cho `TableName = '<class>_html'`. Lý do: renderer dynamic-SQL `(SELECT loadUI FROM tblCommonControlType_Signed WHERE UID='<UID>')` đọc trực tiếp từ bảng metadata — DB đích thiếu data → chuỗi rỗng → JS lỗi runtime `InstanceXXX is not defined` / `window.getGridConfig_XXX is not a function`.

**Bắt buộc trong script migrate**:

```sql
-- 1. Xoá metadata cũ (idempotent)
DELETE FROM tblCommonControlType_Signed WHERE TableName = '<class>_html';

-- 2. Insert lại toàn bộ row metadata với UID DETERMINISTIC (không để NULL — proc tự sinh UID random sẽ phá liên kết với renderer)
INSERT INTO tblCommonControlType_Signed (TableName, ColumnName, Type, Layout, ..., UID) VALUES
    ('<class>_html', 'GridX', 'hpaControlGrid_Duc', 'Grid_View', ..., 'P00...G01'),
    ...;

-- 3. EXEC để populate html/loadUI/loadData
EXEC sptblCommonControlType_Signed_DUC '<class>_html';

-- 4. Mới được build cache
DELETE FROM tblHtmlScriptCache WHERE TableName = '<class>_html';
EXEC sp_GenerateHTMLScript '<class>_html';
```

Xem rule chi tiết ở [13_Migrate_Menu.md Rule 4](13_Migrate_Menu.md) (đã mở rộng để cover bảng này).

#### 3.1.6. Ví dụ tham chiếu đã chạy production

| Renderer | Pattern | Data API |
|---|---|---|
| `sp_CRM_Customers_html` | `hpaControlGrid_Duc` (read-only grid) — 7 column + 1 container | `sp_loadCRMCustomers` |
| `sp_KPIProcessCustomer_html` | `hpaControlSegmented` + `hpaControlSelectEmployee` + 2 × `hpaControlDate` (form filter) | (load qua các API filter riêng) |
| `sp_REC_Candidate_html`, `sp_Train_SubjectList_New_html`, `sp_Adjustment_html` | Hỗn hợp form + grid | (xem source) |

Script template đầy đủ end-to-end cho menu Hello world Vietinsoft: [SQL script/update_menu_HelloWorldVietinsoft_employeelist_20260521.sql](../SQL%20script/update_menu_HelloWorldVietinsoft_employeelist_20260521.sql) — chứa cả 6 bước (metadata → DUC → renderer → cache → refresh).

#### 3.1.7. Lỗi thường gặp

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Click menu → JS lỗi `InstanceXXX is not defined` | Renderer build trước khi `EXEC sptblCommonControlType_Signed_DUC` → cột `loadUI` rỗng | Chạy lại đúng thứ tự: metadata → DUC → renderer → `sp_GenerateHTMLScript` |
| Grid hiện nhưng không có data | `SPLoadData` không tồn tại / sai tên column SELECT | Test thủ công: `EXEC <SPLoadData> @LoginID=3` — kiểm tra column name khớp `ColumnName` trong metadata |
| `EXEC sptblCommonControlType_Signed_DUC` báo lỗi `Invalid column name` khi join `sys.columns` | `TableEditor` trỏ tới bảng không tồn tại / cột metadata không tồn tại trên `TableEditor` | Đảm bảo `TableEditor` là bảng vật lý có cột tương ứng, hoặc để NULL cho row grid container |
| Cache rebuild xong nhưng UI vẫn cũ | Chưa xoá cache cũ trước khi build | `DELETE FROM tblHtmlScriptCache WHERE TableName='<class>_html'` rồi mới `sp_GenerateHTMLScript` |
| SelectBox/SelectEmployee/TextSearch hiển thị nhưng dropdown trống / load không có data trên barebones HTML-rendered menu | Menu KHÔNG phải DataSetting menu nên các global JS helper (`loadDataSourceCommon`, `hpaUtils`, `RemoveToneMarks_Js`, `uiManager`, biến `LoginID`/`LanguageID`) KHÔNG được framework tự load. `loadUI` của control gọi `loadDataSourceCommon(...)` → undefined → silent fail | Polyfill 5 global trong bootstrap script TRƯỚC khi gọi loadUI (xem §3.1.8) |

#### 3.1.8. Polyfill các global helper khi nhúng hpaControl* vào barebones HTML-rendered menu (xem skill riêng)

Khi nhúng `hpaControl*` riêng lẻ vào barebones HTML-rendered menu (không dùng wrapper `DataSetting` full), các global helper (`loadDataSourceCommon`, `hpaUtils`, `RemoveToneMarks_Js`, `uiManager`, `LoginID`/`LanguageID`) KHÔNG có sẵn → control im lặng / dropdown rỗng. **Bắt buộc polyfill 5 global trong bootstrap `<script>` TRƯỚC khi inject `loadUI`** — xem code mẫu đầy đủ trong [17_RendererHtmlJsSafe.md §3.5](17_RendererHtmlJsSafe.md).

Xem thêm tri thức nền từng phase ở [07_menu_system.md §13](07_menu_system.md).

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
     @ParentMenuID = 'MnuKPI000',          -- Trang chủ CRM (IsVisible=1 — verify trước!)
     @AssemblyName = 'DataSetting',
     @Option       = 1,                    -- 1 = thực thi (0 = preview script)
     @LoginIDList  = '3';                  -- cấp FullAccess=32 cho LoginID=3 (admin)
```

Proc tự sinh `MenuID = 'MnuKPI<N>'` (số tiếp theo trong nhóm KPI) + `ObjectID = MAX+1`, insert đủ 3 bảng metadata + cấp quyền. Hoặc dùng cách insert thủ công nếu cần kiểm soát `MenuID` cụ thể — xem [SQL script/deploy_menu_HelloWorldVietinsoft_20260520.sql](../SQL%20script/deploy_menu_HelloWorldVietinsoft_20260520.sql).

> ⚠️ **Trước khi gọi `sp_s_CreateMenu`**: phải verify parent menu có `IsVisible=1` (Rule 3). Đặc biệt **TRÁNH** `MnuHEP000` (Trợ giúp) vì có `IsVisible=0` ở DB thực tế.

### 4.5b. Phase D2 — Tạo dòng trong `tblDataSetting` (BẮT BUỘC theo Rule 4)

```sql
INSERT INTO tblDataSetting
    (TableName, ViewName, AllowAdd, ReadOnlyColumns, ComboboxColumns,
     ColumnOrderBy, ColumnHide, ReadOnly, TableEditorName, IsProcedure,
     -- ... + nhiều cột notnull khác (xem script ví dụ đầy đủ) ...
     IsShowLayout, LoadDataAfterShow, AllowDelete, ColumnDataType,
     IsLayoutCommandButton, ControlHiddenInShowLayout, FormLayoutJS)
VALUES
    ('sp_HelloWorldVietinsoft', 'sp_HelloWorldVietinsoft', 1, '', '',
     'html&0', 'isReadOnlyRow,dtftxxENGColumns', 0, '', 1,
     -- ... defaults '' / 0 / false cho các cột còn lại ...
     1, 1, 1, 'html&ViewHtml',
     1,
     'grdTableEditor,txtFilter,btnReload,btnFWDelete,btnFWReset,btnExport,btnFWSave,btnFWAdd,isReadOnlyRow,dtftxxENGColumns',
     1);
```

| Cột | Giá trị | Ý nghĩa |
|---|---|---|
| `TableName` | `'sp_HelloWorldVietinsoft'` | = `ClassName` của menu (PK) |
| `ViewName` | `'sp_HelloWorldVietinsoft'` | Giống `TableName` |
| `IsProcedure` | `1` | Báo cho app: đây là procedure (không phải table/view) |
| `IsShowLayout` | `1` | Bật layout container → app đọc `tblDataSettingLayout` |
| `ColumnOrderBy` | `'html&0'` | Render cột `html` (cột duy nhất renderer trả về), thứ tự 0 = ascending |
| `ColumnDataType` | `'html&ViewHtml'` | Cột `html` có kiểu `ViewHtml` → app render HTML thay vì text |
| `ControlHiddenInShowLayout` | (chuỗi dài) | Ẩn các button không cần (Save/Delete/Add/Reset/Export...) cho menu read-only |
| `FormLayoutJS` | `1` | Bật JS layout |
| Các binary cột (`LayoutDataConfig`, `LayoutDataConfigWeb`, ...) | NULL | Không cần fill — layout thực ở `tblDataSettingLayout` |

> ⚠️ `tblDataSetting` có rất nhiều cột notnull (text rỗng `''`, bit `0`, int `0`). Xem [SQL script/fix_menu_HelloWorldVietinsoft_v2_20260520.sql](../SQL%20script/fix_menu_HelloWorldVietinsoft_v2_20260520.sql) để có template INSERT đầy đủ.

### 4.5c. Phase D3 — Tạo 2 dòng `tblDataSettingLayout` (container `ParadiseWebView2`)

```sql
-- Row 1: root group
INSERT INTO tblDataSettingLayout
    (TableName, Name, ControlName, NamePa, Type, TypeLayout,
     Lx, Ly, Sx, Sy, WidthPercentage, ControlType, TextLocation, CaptionHorizontalAlign,
     CaptionVerticalAlign, TabPageOrder
     -- ... + các cột notnull khác (string '', int 0, bit 0) ...
    )
VALUES
    ('sp_HelloWorldVietinsoft', 'root', '', '', 'g', '6',
     0, 0, 1620, 929, 100, '', 'top', 'default', 'default', -1
     /* ... */ );

-- Row 2: lblhtml — ParadiseWebView2 control (chứa HTML từ cache)
INSERT INTO tblDataSettingLayout
    (TableName, Name, ControlName, NamePa, Type, TypeLayout,
     Lx, Ly, Sx, Sy, WidthPercentage, ControlType, TextLocation, CaptionHorizontalAlign,
     CaptionVerticalAlign, Padding, PaddingTop, PaddingLeft, PaddingBottom, PaddingRight
     /* ... */ )
VALUES
    ('sp_HelloWorldVietinsoft', 'lblhtml', 'html', 'root', 'i', '6',
     0, 0, 1620, 929, 100, 'ParadiseWebView2', 'default', 'default',
     'default', 2, 2, 2, 2, 2
     /* ... */ );
```

| Row | `Name` | `Type` | `ControlType` | `ControlName` | `NamePa` | Ý nghĩa |
|---|---|---|---|---|---|---|
| 1 | `root` | `g` (group) | `''` | `''` | `''` | Root container |
| 2 | `lblhtml` | `i` (item) | `ParadiseWebView2` | `html` | `root` | WebView2 control hiển thị HTML, link vào cột `html` của procedure wrapper |

> Khoá logic: `(TableName, Name)`. Idempotent: `DELETE FROM tblDataSettingLayout WHERE TableName='<x>'` rồi `INSERT` lại 2 row.

### 4.6. Phase E — Cờ nền tảng + UI (theo PATTERN ĐÚNG ở Rule 2)

```sql
UPDATE MEN_Menu
SET    IsVisible            = 1,
       IsWeb                = 0,    -- HTML-rendered, không phải ASPX
       ViewOnWeb            = 0,    -- ⚠️ PHẢI = 0 (không phải 1!)
       isShowLayOutWeb      = 0,    -- ⚠️ PHẢI = 0
       IsUseMobileDevice    = 1,    -- bật cho mobile + Web HTML-rendered
       isShowInMobileLayOut = 0,    -- ⚠️ PHẢI = 0
       glyphicon            = N'Info',
       GroupID              = 'MnuKPI000',   -- giống ParentMenuID
       Priority             = 99
WHERE  MenuID = 'MnuHEP910';
```

### 4.7. Phase F — Build cache HTML bằng helper `sp_GenerateHTMLScript` (cách duy nhất)

```sql
EXEC dbo.sp_GenerateHTMLScript 'sp_HelloWorldVietinsoft_html';
```

> ✅ Chuẩn thống nhất: chỉ dùng helper `sp_GenerateHTMLScript` để build/rebuild HTML cache cho renderer. Không khuyến nghị gọi trực tiếp procedure renderer `_html` theo từng `LanguageID` trong script tạo/migrate/update menu.

### 4.8. Phase H — Refresh menu cache (CHỈ 1 lệnh)

Theo quy tắc bắt buộc ở đầu file: Phase H **chỉ** chạy `sp_Men_Menu_AfterSave_Simple` với `@ClassName` của menu vừa tạo. **TUYỆT ĐỐI KHÔNG** gọi `sp_UpdateMenuInUserRight`.

```sql
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_HelloWorldVietinsoft';
```

> ⚠️ Lưu ý signature: proc này có default `@ClassName = ''` nhưng nếu không truyền sẽ resolve menu rỗng → không hữu ích. **Luôn truyền** `@ClassName` thực tế.

Sau khi script chạy xong:
- User logout/login để app load cây menu mới (chỉ admin LoginID = 3 thấy được).
- Để cấp quyền cho user/group khác: dùng giao diện phân quyền trong app, hoặc viết script riêng `INSERT tblSC_Right_Stored` / `tblSC_GroupRight`.

**Hành vi của `sp_UpdateMenuInUserRight @ObjectID`** (đã verify source DB — chỉ ghi để tham khảo, KHÔNG dùng):
- Insert `tblSC_Right_Stored(ObjectID, LoginID, FullAccess=32)` cho **MỌI LoginID > 0** trong `tblSC_Login` chưa có quyền.
- Update `FullAccess = 32` cho mọi row đã có.
- Lý do tránh: mở quyền menu cho tất cả user toàn hệ thống — vượt phạm vi cần thiết.

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

## 6. Checklist 12 điểm dành cho lập trình viên mới

1. ☐ Đã chọn `MenuID` không trùng — kiểm tra qua `SELECT * FROM MEN_Menu WHERE MenuID='<id>'`.
2. ☐ **Parent menu** đã verify `IsVisible = 1` — `SELECT IsVisible FROM MEN_Menu WHERE MenuID='<ParentMenuID>'`. **Né `MnuHEP000`**.
3. ☐ **Cờ MEN_Menu theo Rule 2**: `IsWeb=0, ViewOnWeb=0, isShowLayOutWeb=0, isShowInMobileLayOut=0, IsUseMobileDevice=1`. Không bật `ViewOnWeb=1` (sai lầm phổ biến).
4. ☐ **Phase D2 (Rule 4) — `tblDataSetting`**: 1 dòng với `IsProcedure=1, IsShowLayout=1, ColumnOrderBy='html&0', ColumnDataType='html&ViewHtml'`. **Thiếu = màn hình trắng.**
5. ☐ **Phase D3 (Rule 4) — `tblDataSettingLayout`**: 2 dòng `root` (`Type='g'`) + `lblhtml` (`Type='i', ControlType='ParadiseWebView2', ControlName='html', NamePa='root'`). **Thiếu = màn hình trắng.**
6. ☐ Renderer đã UPSERT cache cho **cả VN và EN** (2 dòng trong `tblHtmlScriptCache`).
7. ☐ Wrapper đã `SELECT TOP 1 html` lọc đúng `(TableName, ScreenType='-1', LanguageID)`.
8. ☐ Procedure API runtime có 2 tham số chuẩn `@LoginID` + `@LanguageID`.
9. ☐ JS gọi `AjaxHPAParadise` với `param` là **mảng phẳng** `[name, value, ...]`, KHÔNG phải object.
10. ☐ Phase G — chỉ `INSERT tblSC_Right_Stored(ObjectID, LoginID = 3, FullAccess = '32')`.
11. ☐ Phase H — chỉ `EXEC sp_Men_Menu_AfterSave_Simple @ClassName = '<ClassName>'`. **KHÔNG** gọi `sp_UpdateMenuInUserRight`.
12. ☐ Đã verify: logout/login (LoginID = 3) → menu hiển thị → click vào → giao diện render → mở DevTools → check Network tab xem `AjaxHPAParadise` POST đúng `name` + `param`. Cấp quyền cho user/group khác sau (qua app hoặc script riêng).

---

## 7. Các lỗi thường gặp khi tạo menu mới

| Triệu chứng | Nguyên nhân hay gặp | Cách kiểm tra |
|---|---|---|
| Menu không hiện trong cây dù đã cấp quyền + logout/login | (1) Sai cờ Web (`ViewOnWeb=1`/`isShowLayOutWeb=1`/`isShowInMobileLayOut=1` — phải = 0 theo Rule 2); HOẶC (2) parent menu `IsVisible = 0` (vd `MnuHEP000`); HOẶC (3) `IsVisible = 0` của chính menu | So sánh cờ với menu HTML-rendered đang chạy: `SELECT m.MenuID, m.IsVisible, m.IsWeb, m.ViewOnWeb, m.isShowLayOutWeb, m.IsUseMobileDevice, m.isShowInMobileLayOut, p.IsVisible AS ParentVisible FROM MEN_Menu m LEFT JOIN MEN_Menu p ON p.MenuID=m.ParentMenuID WHERE m.MenuID IN ('<id>','MnuKPI007')` |
| **Menu hiện trong cây + click vào → màn hình TRẮNG (không content)** | **Thiếu Phase D2 + D3** — KHÔNG có dòng trong `tblDataSetting` và `tblDataSettingLayout`. App đọc `MEN_Menu.AssemblyName='DataSetting'` nhưng không tìm thấy config layout → render rỗng. | Check: `SELECT * FROM tblDataSetting WHERE TableName='<ClassName>';` + `SELECT * FROM tblDataSettingLayout WHERE TableName='<ClassName>';` Phải có 1 row tblDataSetting (`IsProcedure=1, IsShowLayout=1`) + 2 row tblDataSettingLayout (`root` + `lblhtml`). Fix: chạy script tạo 2 bảng (xem [fix_menu_HelloWorldVietinsoft_v2_20260520.sql](../SQL%20script/fix_menu_HelloWorldVietinsoft_v2_20260520.sql)). |
| Mở menu thấy trắng / "loading..." không kết thúc | Renderer chưa được build cache → cache rỗng | `SELECT DATALENGTH(html) FROM tblHtmlScriptCache WHERE TableName='<class>_html' AND LanguageID='VN'`; nếu rỗng thì chạy `EXEC dbo.sp_GenerateHTMLScript '<class>_html';` |
| Hiển thị HTML cũ sau khi sửa | Cache HTML chưa được rebuild | `DELETE FROM tblHtmlScriptCache WHERE TableName='<class>_html'; EXEC dbo.sp_GenerateHTMLScript '<class>_html';` |
| JS gọi API lỗi 500 | Tham số `param` sai (object thay vì array) hoặc thiếu `@LoginID`/`@LanguageID` trong procedure | Mở DevTools Network → xem request body |
| Data trống nhưng DB có | `EmployeeID` mismatch (varchar có leading zeros) hoặc filter ngày sai | Chạy thẳng `EXEC <proc_API> @LoginID=3, @LanguageID='VN'` trong SSMS |
| `'Cannot insert NULL into column ''html'''` | Insert thiếu cột notnull của `tblHtmlScriptCache` | Phải fill cả 5 cột notnull (`html`, `HtmlParadise`, `paradiseJs`, `Version`, `VersionData`) — xem [07_menu_system.md §10](07_menu_system.md) |
| `Msg 201: Procedure 'sp_Men_Menu_AfterSave_Simple' expects parameter '@ClassName'` | Gọi proc refresh thiếu `@ClassName` | `EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>'` |
| Menu hiện đúng UI nhưng tất cả user trong hệ thống cũng thấy | **Vi phạm rule cấp quyền** — đã gọi `sp_UpdateMenuInUserRight` (proc tự cấp `FullAccess=32` cho mọi LoginID) | Xoá row dư trong `tblSC_Right_Stored`: `DELETE FROM tblSC_Right_Stored WHERE ObjectID = <id> AND LoginID <> 3;` Sau đó user tự cấp lại quyền qua app cho user/group cần thiết. |
| Cần cấp quyền cho user khác / cả group sau khi menu đã chạy | Theo rule chuẩn, script tạo menu chỉ cấp cho LoginID = 3 | Dùng giao diện phân quyền trong app, hoặc viết script riêng `INSERT tblSC_Right_Stored(ObjectID, LoginID, FullAccess='32')` / `INSERT tblSC_GroupRight(ObjectID, UserGroupID, FullAccess='32')` |

---

## 8. File tham chiếu sẵn sàng triển khai

| Mục đích | File |
|---|---|
| Script update menu Hello world Vietinsoft sang **demo `tblCommonControlType_Signed` + `sptblCommonControlType_Signed_DUC`** (grid danh sách nhân viên) — template đầy đủ pattern config-driven (§3.1) | [SQL script/update_menu_HelloWorldVietinsoft_employeelist_20260521.sql](../SQL%20script/update_menu_HelloWorldVietinsoft_employeelist_20260521.sql) |
| Script update menu Hello world Vietinsoft sang ParadiseStyle reference (Top 3 ranking) | [SQL script/update_menu_HelloWorldVietinsoft_paradisestyle_20260521.sql](../SQL%20script/update_menu_HelloWorldVietinsoft_paradisestyle_20260521.sql) |
| Script cleanup menu ASPX-style lỗi thời (kiểu menu Web duy nhất bị deprecated) | [SQL script/cleanup_menu_aspx_20260520.sql](../SQL%20script/cleanup_menu_aspx_20260520.sql) |
| Tri thức nền: 5 mảnh dữ liệu, cờ nền tảng, refresh, HTML cache | [07_menu_system.md](07_menu_system.md) |
| Phân quyền: `FullAccess` map, data scope, inheritance | [11_permissions.md](11_permissions.md) |
| Cờ tách 3 nền tảng Desktop/Web/Mobile | [01_architecture.md](01_architecture.md) |
| Bảng `tblEmployee` + cấu trúc hồ sơ NV | [02_db_employee.md](02_db_employee.md) |
