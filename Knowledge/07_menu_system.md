# 07 — Hệ thống Menu (Logic tạo + vận hành menu ParadiseHR)

> Toàn bộ tri thức về menu: cấu trúc 5 mảnh, quy ước đặt tên, phân loại theo `AssemblyName`, quy trình tạo (thủ công + shortcut), giao diện desktop/web, HTML cache pattern, và quy trình end-to-end. Liên quan: [11_permissions.md](11_permissions.md), [01_architecture.md](01_architecture.md).
>
> 💡 **Cần triển khai 1 menu Web mới**? Xem skill file [12_CreateMenu.md](12_CreateMenu.md) — quy trình 9 phase đầy đủ + ví dụ Hello world Vietinsoft (Top 3 xếp hạng) + cách gọi API runtime qua `AjaxHPAParadise`.
>
> 🔁 **Cần migrate/update một menu đã có**? Xem skill file [13_Migrate_Menu.md](13_Migrate_Menu.md) — quy trình tìm menu theo tên, inventory metadata/source/API/ngôn ngữ/quyền, rồi tạo script idempotent không chèn trùng `MEN_Menu`, `tblSC_Object`, `tblSC_Right_Stored`, `tblSC_GroupRight`.
>
> 🎨 **Cần thiết kế/refactor giao diện menu**? Xem skill file [14_ParadiseStyle.md](14_ParadiseStyle.md) — dùng token `--paradise-*` + class `.paradise-*` đã inject sẵn từ 4 layout gốc (renderer menu thông thường **KHÔNG** gọi `sp_MainStyleCSSParadise`), và **không thiết lập background cho bất cứ menu nào**.
>
> 🔍 **Cần tìm procedure của một menu có sẵn để debug/sửa UI**? Xem skill file [18_FindMenuProcedure.md](18_FindMenuProcedure.md) — quy trình 5 bước copy-paste-ready từ **tên menu** → `tblMD_Message` → `MEN_Menu.ClassName` → verify `sys.objects` → tìm renderer `%_html`.

## 1. Cấu trúc menu — 5 mảnh dữ liệu liên kết qua `MenuID`

| # | Bảng | Vai trò |
|---|---|---|
| 1 | `MEN_Menu` | Định nghĩa menu — PK = `MenuID`, vị trí trong cây, class form, cờ nền tảng |
| 2 | `tblSC_Object` | Đối tượng phân quyền — `Description = MenuID`, `ObjectName = '<Assembly>.<Class>'` |
| 3 | `tblMD_Message` | Tên đa ngôn ngữ — `MessageID = MenuID`, `Language = 'VN'/'EN'/...` |
| 4 | `tblDataSetting` (optional) | Cấu hình grid + proc CRUD — chỉ với menu `AssemblyName = 'DataSetting'` |
| 5 | `tblSC_Right_Stored` / `tblSC_GroupRight` | Cấp quyền dùng menu (xem [11_permissions.md](11_permissions.md)) |

Các bảng phụ trợ: `tblWorkFlow` (liên kết menu với business flow), `Menu_FrameSetting` (SuperForm), `tblContextMenu` (menu chuột phải).

## 2. Quy ước đặt tên

- **`MenuID`**: `Mnu<MODULE><N>` — `MODULE` 3 ký tự nhóm (`HRS`, `TAD`, `PRL`, `MDT`, `WPT`, `SCR`, `HEP`, `RPT`...), `N` là số. Menu cha của mỗi module thường có dạng `Mnu<MODULE>000`.
- **`ObjectName`** trong `tblSC_Object`: bắt buộc theo dạng `'<AssemblyName>.<ClassName>'` (procedure resolve quyền dựa vào convention này).

## 3. Phân loại menu theo `AssemblyName`

| AssemblyName | Loại | Yêu cầu thêm |
|---|---|---|
| `DataSetting` | Grid tự dựng từ view / table / proc | Cần 1 record trong `tblDataSetting` (`TableName`, `Title`, `TitleEN`, `ProcSelect`, `ProcInsert`, `ProcUpdate`, `ProcDelete`, `KeyColumn`, `IsList`, `FormType`) |
| `SuperForm` | Form đa tab/section | Config trong `Menu_FrameSetting` |
| `HPA.<X>` / assembly tự viết | Form .NET viết tay | `ClassName` = tên class trong assembly |

## 4. Ví dụ thực tế — menu "Danh sách nhân viên" (`MnuHRS142`)

| Bảng | Giá trị chính |
|---|---|
| `MEN_Menu` | `MenuID='MnuHRS142'`, `ClassName='vtblEmployeeList'`, `AssemblyName='DataSetting'`, `ParentMenuID='MnuHRS000'`, `Priority=2`, `IsVisible=1`, `glyphicon='UserList'`, `GroupID='MnuHRS0000'` |
| `tblSC_Object` | `ObjectID=133`, `ObjectName='DataSetting.vtblEmployeeList'`, `Description='MnuHRS142'`, `Visible=1`, `ParentObjectID=1` |
| `tblMD_Message` | `MessageID='MnuHRS142'`, `Language='VN'`, `Content=N'Danh sách nhân viên'` |
| Nguồn data | `vtblEmployeeList` là 1 SQL VIEW (`sys.objects.type='V'`) |

## 5. Quy trình tạo menu mới — 6 bước thủ công

### Bước 1 — Tạo nguồn dữ liệu

```sql
CREATE VIEW vtblEmployeeList AS
SELECT EmployeeID, FullName, Sex, Birthday, MobilePhone, Email,
       HireDate, BranchID, DepartmentID, PositionID
FROM tblEmployee
WHERE ISNULL(IsTerminated,0) = 0;
```

### Bước 2 — Chọn `MenuID`

Lấy `MAX(số sau 6 ký tự)` của `MEN_Menu` trong cùng nhóm + 1. Hoặc dùng [Section 6](#6-shortcut--sp_s_createmenu-làm-cả-bước-3-6-trong-1-lệnh) (`sp_s_CreateMenu` tự sinh).

### Bước 3 — Insert `MEN_Menu`

```sql
INSERT INTO MEN_Menu
    (MenuID, ClassName, AssemblyName, ParentMenuID, Priority, IsVisible,
     glyphicon, GroupID, IsWeb, IsUseMobileDevice)
VALUES
    ('MnuHRSXXX', 'vtblEmployeeList', 'DataSetting', 'MnuHRS000',
     2, 1, 'UserList', 'MnuHRS0000', 0, 0);
```

### Bước 4 — Insert `tblSC_Object`

```sql
DECLARE @ObjID INT = (SELECT MAX(ObjectID)+1 FROM tblSC_Object);
DECLARE @ParentObjID INT = (SELECT TOP 1 ObjectID FROM tblSC_Object
                            WHERE Description = 'MnuHRS000');

INSERT INTO tblSC_Object (ObjectID, ObjectName, Description, Visible, ParentObjectID)
VALUES (@ObjID, 'DataSetting.vtblEmployeeList', 'MnuHRSXXX', 1, @ParentObjID);
```

### Bước 5 — Đặt tên đa ngôn ngữ qua procedure helper

```sql
EXEC dbo.[1rename_Mess] 'MnuHRSXXX', 'VN', N'Danh sách nhân viên';
EXEC dbo.[1rename_Mess] 'MnuHRSXXX', 'EN', 'Employee List';
```

### Bước 6 — Cấp quyền

```sql
INSERT INTO tblSC_Right_Stored (LoginID, ObjectID, FullAccess)
VALUES (<LoginID>, @ObjID, 32);
-- hoặc cho group:
INSERT INTO tblSC_GroupRight (UserGroupID, ObjectID, FullAccess)
VALUES (<UserGroupID>, @ObjID, 32);
```

## 6. Shortcut — `sp_s_CreateMenu` làm cả bước 3–6 trong 1 lệnh

Procedure tự sinh `MenuID` + `ObjectID`, insert đồng thời `MEN_Menu` + `tblSC_Object` + `tblMD_Message` (VN/EN) + optional `tblSC_Right_Stored`:

```sql
EXEC dbo.sp_s_CreateMenu
     @Text         = N'Danh sách nhân viên',
     @TextEN       = 'Employee List',
     @ClassName    = 'vtblEmployeeList',
     @ParentMenuID = 'MnuHRS000',
     @AssemblyName = 'DataSetting',
     @Option       = 1,                  -- 0=preview script, 1=execute
     @LoginIDList  = '1,3,5';            -- (optional) gán FullAccess=32 cho các LoginID
```

Logic auto-sinh ID đọc từ source:
- `MenuID = LEFT(ParentMenuID, 6) + (MAX(số sau 6 ký tự trong cùng nhóm) + 1)`
- `ObjectID = MAX(ObjectID) + 1`
- Nếu `@Option = 0`: chỉ in script SQL để preview, không thực thi
- Nếu `@Option = 1` và chưa tồn tại menu cùng `ClassName`: thực thi
- Khi có `@LoginIDList`: tự insert quyền `FullAccess=32` cho từng LoginID (ghi vào `tblSC_Right` hoặc `tblSC_Right_Stored` tuỳ bảng nào tồn tại)

## 7. Cờ quan trọng trên `MEN_Menu`

- **Visibility**: `IsVisible`, `IsHiddenInTree`, `SupperAdmin`.
- **Nền tảng** (xem [01_architecture.md](01_architecture.md)): `IsWeb`, `ViewOnWeb`, `isShowLayOutWeb`, `IsUseMobileDevice`, `isShowInMobileLayOut`, `MobileDeviceGroup`, `ParentMenuMobileID`, `PriorityMobileDevice`, `NotUsePlatform`.
- **UI**: `glyphicon`, `Colors`, `IconBackColor`, `IconForeColor`, `LargeTile`, `IsCollapsed`, `IsLeftMenu`.
- **Hành vi**: `IsModal`, `showDialog`, `URL` (web menu), `ShortcutKeys` (desktop), `superForm`, `LinkMenuID`, `DefaultParam`, `OptionAuthentication`.
- **Liên quan**: `ClassName_Audit`, `ClassName_CT` (class phụ trợ), `ProcessDataForNotifyProc`, `InstructionID`.

### Hai cơ chế cấu hình menu HTML-rendered (Rất quan trọng)

Hiện tại, hệ thống Web Portal hỗ trợ **2 cơ chế** thiết lập và hiển thị menu HTML-rendered. Khi tạo hoặc cập nhật menu, **luôn ưu tiên sử dụng Cách 2**.

#### Cách 1: WebView qua Mobile Engine (Legacy)
* **Các cờ trên `MEN_Menu`:** `IsWeb=0`, `ViewOnWeb=0`, `isShowLayOutWeb=0`, `IsUseMobileDevice=1`, `isShowInMobileLayOut=0` (hoặc con `1` parent `1`).
* **Yêu cầu Metadata:** **BẮT BUỘC** cấu hình 3 bảng metadata đầy đủ:
  - `tblDataSetting`: 1 dòng (`TableName = <ClassName>`, `IsProcedure=1`, `IsShowLayout=1`, `ColumnDataType='html&ViewHtml'`, `ColumnOrderBy='html&0'`).
  - `tblDataSettingLayout`: 2 dòng (`root` container + item `lblhtml` trỏ tới `ControlType='ParadiseWebView2'`).
  - `tblHtmlScriptCache`: Chứa nội dung HTML/CSS/JS từ renderer.
* **Đặc điểm:** Tận dụng bộ máy kết xuất di động cũ. Nhược điểm: Phức tạp, dễ gặp lỗi phân biệt chữ hoa/thường (case-sensitive) giữa ClassName và cấu hình TableName trong DataSetting, và phụ thuộc hoàn toàn vào cờ hiển thị di động của menu cha.
* **Menu mẫu:** `MnuKPI007` (Sales Pipeline), `MnuTM022` (Xếp hạng nhân viên), `MnuWPT037` (Danh sách phê duyệt).

#### Cách 2: Pure HTML Render (Hiện đại - KHUYẾN NGHỊ)
* **Các cờ trên `MEN_Menu`:** **`IsWeb=1`**, **`isShowLayOutWeb=1`**, `IsUseMobileDevice=0`, `isShowInMobileLayOut=0`.
* **Yêu cầu Metadata:** **KHÔNG CẦN** cấu hình `tblDataSetting` và `tblDataSettingLayout` (chỉ cần cache HTML trong `tblHtmlScriptCache`).
* **Đặc điểm:** Web Portal khi thấy cờ `IsWeb=1` sẽ bỏ qua toàn bộ Mobile Engine cũ, tự động chạy trực tiếp stored procedure wrapper (ClassName) và lấy giá trị cột `html` trả về để render thẳng lên trang. Cách làm này vô cùng đơn giản, sạch sẽ, không phụ thuộc cờ menu cha và hoàn toàn loại bỏ nguy cơ lỗi màn hình trắng do thiếu cấu hình layout.
* **Menu mẫu:** `MnuAT009` (Danh sách đơn khiếu nại), `MnuSCR605` (Nhật ký người dùng mới), `MnuSCR010` (Phân quyền truy cập mới).

---

### Parent menu PHẢI `IsVisible = 1`

Trước khi chọn `ParentMenuID` cho menu mới, **kiểm tra parent có `IsVisible = 1`**. Parent không visible thì menu con không hiển thị (ngay cả khi đầy đủ quyền). Đặc biệt **TRÁNH `MnuHEP000`** (Trợ giúp — `IsVisible = 0` ở DB thực tế).

---

### BẮT BUỘC tạo `tblDataSetting` + `tblDataSettingLayout` (Chỉ áp dụng cho Cách 1)

Nếu cấu hình theo **Cách 1**, mỗi menu HTML-rendered cần **3 bảng metadata** đầy đủ (verify từ `MnuKPI447`, `MnuTM022`, `MnuWPT037`):

| Bảng | Số dòng | Cờ chính |
|---|---|---|
| `tblDataSetting` | 1 | `TableName = <ClassName>`, `IsProcedure=1`, `IsShowLayout=1`, `ColumnDataType='html&ViewHtml'`, `ColumnOrderBy='html&0'` |
| `tblDataSettingLayout` | 2 | Row `root` (`Type='g'`) + row `lblhtml` (`Type='i'`, `ControlType='ParadiseWebView2'`, `ControlName='html'`, `NamePa='root'`) |
| `tblHtmlScriptCache` | ≥ 1 / lang | HTML/CSS/JS từ renderer |

**Triệu chứng nếu thiếu (khi chạy Cách 1)**: menu xuất hiện trong cây + có quyền + có cache HTML → click vào → **màn hình TRẮNG** (không content). Xem [12_CreateMenu.md Rule 4 + Phase D2/D3](12_CreateMenu.md).

## 8. Giao diện desktop app lưu ở đâu

Các giao diện/menu của Windows Desktop không lưu trong một bảng riêng tên "desktop", mà nằm chủ yếu ở `MEN_Menu` và các bảng liên kết theo `MenuID`:

| Bảng | Vai trò với desktop app |
|---|---|
| `MEN_Menu` | Bảng chính định nghĩa cây menu/giao diện: `MenuID`, `ParentMenuID`, `Priority`, `AssemblyName`, `ClassName`, `IsVisible`, `ShortcutKeys`, `IsModal`, `glyphicon`... Desktop là layout mặc định khi không bật `IsWeb` / `IsUseMobileDevice`. |
| `tblSC_Object` | Object phân quyền tương ứng menu: `Description = MenuID`, `ObjectName = '<AssemblyName>.<ClassName>'`. |
| `tblMD_Message` | Tên giao diện/menu đa ngôn ngữ: `MessageID = MenuID`, `Language`, `Content`. |
| `tblDataSetting` | Cấu hình giao diện dạng grid/list tự dựng khi `MEN_Menu.AssemblyName = 'DataSetting'`: `TableName`, `ViewName`, `TableEditorName`, `IsProcedure`, `IsShowLayout`, `IsEditForm`, `LayoutDataConfig`... |
| `Menu_FrameSetting` | Config form kiểu `SuperForm` / form nhiều frame. |
| `tblContextMenu` | Menu chuột phải / action phụ trên giao diện. |
| `tblSC_Right_Stored`, `tblSC_GroupRight` | Quyền user/group để thấy và dùng giao diện. |

```sql
SELECT TOP 100
       m.MenuID, msg.Content AS MenuNameVN, m.AssemblyName, m.ClassName,
       o.ObjectName, ds.TableName, ds.ViewName, ds.TableEditorName,
       ds.IsProcedure, ds.IsShowLayout, ds.IsEditForm
FROM MEN_Menu m
LEFT JOIN tblMD_Message msg ON msg.MessageID = m.MenuID AND msg.Language = 'VN'
LEFT JOIN tblSC_Object o    ON o.Description = m.MenuID
LEFT JOIN tblDataSetting ds ON ds.TableName = m.ClassName OR ds.ViewName = m.ClassName
WHERE ISNULL(m.IsVisible, 0) = 1
  AND ISNULL(m.IsWeb, 0) = 0
  AND ISNULL(m.IsUseMobileDevice, 0) = 0
ORDER BY m.MenuID;
```

Ghi nhận từ DB: trong các menu visible mặc định desktop, nhóm `AssemblyName = 'DataSetting'` chiếm nhiều nhất (275 menu), sau đó là các assembly form viết tay như `HPA.TimeAttendance`, `HPA.Recruitment`, `HPA.Update`, `HPA.MasterData`, `HPA.HumanResource`, `HPA.SystemAdmin`.

## 9. Giao diện web được thiết kế và lưu ở đâu

| Lớp | Bảng/cột | Vai trò |
|---|---|---|
| Menu/route Web | `MEN_Menu` | Bảng chính định nghĩa màn hình Web. Các cờ Web: `IsWeb`, `ViewOnWeb`, `isShowLayOutWeb`; URL Web ở `URL`; class/nguồn xử lý ở `AssemblyName`, `ClassName`. |
| Tên giao diện | `tblMD_Message` | Tên menu/màn hình đa ngôn ngữ. |
| Thiết kế grid/form data-driven | `tblDataSetting` | Lưu cấu hình màn hình dạng `DataSetting`: `LayoutDataConfigWeb`, `WebDataGridKeys`, `UseAPIOptionForWeb`, `FormLayoutJS`, `ViewMode`, `Mode`, `Template`, `HtmlCell`, `TypeGrid`... |
| Control/grid metadata nâng cao | `tblCommonControlType_Signed` | Lưu cấu hình control/grid theo `TableName`, `ColumnName`, `Type`, `Layout`, `DataSourceSP`, `UID`... để sinh HTML/JS control chung. |
| Cấu hình chung Web | `tblParameter` | `APPLICATION_ADDRESS`, `ThemeWeb`, `allowedPageSizes`, `isConfirmCloseTab`, `LimitAppInDock`, `MenuIDLaunPad`, `MenuVisibleOpion`, `ParadiseLogOutTimeOut`. |
| Quyền truy cập | `tblSC_Object`, `tblSC_Right_Stored`, `tblSC_GroupRight` | Phân quyền user/group nhìn thấy và dùng màn hình Web. |

ParadiseHR hiện chỉ dùng **một kiểu duy nhất** cho menu Web: **HTML-rendered** (chi tiết Section 10). Cụ thể: `MEN_Menu.AssemblyName = 'DataSetting'`, `ClassName` trỏ tới cặp procedure wrapper + renderer (`sp_X` + `sp_X_html`), HTML/CSS/JS thực được lưu trong `tblHtmlScriptCache`, render qua control `ParadiseWebView2`. Có thể đi kèm `tblDataSetting` + `tblDataSettingLayout` để dựng layout container.

Trong kiểu HTML-rendered có 2 nhánh triển khai đã xác minh:

1. Renderer tự viết toàn bộ HTML/CSS/JS rồi build cache bằng `sp_GenerateHTMLScript`.
2. Renderer dùng metadata `tblCommonControlType_Signed`; procedure `sptblCommonControlType_Signed_DUC @TableName` sinh HTML/JavaScript cho Grid View và control chung, trả `htmlProc`; sau đó cache cuối vẫn build bằng `sp_GenerateHTMLScript '<proc_html>'`.

> ⚠️ **Kiểu Web page cố định ASPX đã LỖI THỜI và KHÔNG còn sử dụng**. Trước đây hệ thống có menu trỏ trực tiếp tới file `.aspx` (vd `/EmpInfo.aspx`, `/PRL/Payslip.aspx`, `/ATT/LeaveHistory.aspx`) — nay đã được thay thế hoàn toàn bằng menu HTML-rendered. Các MenuID còn sót trong DB đã được liệt kê tại [99_deprecated.md §5](99_deprecated.md). Khi đề xuất / thiết kế menu Web mới, **KHÔNG dùng pattern này**.

## 10. Web layout kiểu mới bằng HTML cache — ví dụ `Xếp hạng nhân viên`

Một số màn hình Web "phong cách mới" không dùng `LayoutDataConfigWeb` dạng grid truyền thống. Chúng dùng cơ chế **DataSetting + layout container + HTML/JS render động**.

Ví dụ menu **Xếp hạng nhân viên**:

| Thành phần | Giá trị / bảng |
|---|---|
| Menu chính | `MEN_Menu.MenuID = 'MnuTM022'`, `Content = N'Xếp hạng nhân viên'`, `AssemblyName = 'DataSetting'`, `ClassName = 'sp_Train_Ranking_Template'` |
| Menu detail | `MEN_Menu.MenuID = 'MnuTM025'`, `Content = N'Chi tiết xếp hạng'`, `AssemblyName = 'DataSetting'`, `ClassName = 'sp_Train_Ranking_TemplateDetail'`, `isShowLayOutWeb = 1` |
| DataSetting | `tblDataSetting.TableName/ViewName = 'sp_train_ranking_template'` và `sp_train_ranking_templatedetail`, `IsProcedure = 1`, `IsShowLayout = 1` |
| Layout container | `tblDataSettingLayout` có 2 dòng/màn hình: `root` và `lblhtml`; `lblhtml.ControlType = 'ParadiseWebView2'`, `ControlName = 'html'`, `TypeLayout = '6'`, `WidthPercentage = 100` |
| HTML/CSS/JS thực tế | `tblHtmlScriptCache.html`, theo `TableName = 'sp_Train_Ranking_Template_html'` hoặc `sp_Train_Ranking_TemplateDetail_html`, `LanguageID = 'VN'/'EN'`, `ScreenType = '-1'` |
| Procedure wrapper | `sp_Train_Ranking_Template`, `sp_Train_Ranking_TemplateDetail` chỉ `SELECT TOP 1 html FROM tblHtmlScriptCache ...` |
| Procedure sinh HTML gốc | `sp_Train_Ranking_Template_html`, `sp_Train_Ranking_TemplateDetail_html`; sau khi sửa procedure HTML cần generate/cache lại bằng `sp_GenerateHTMLScript '<proc_html>'` |
| API dữ liệu runtime | JS gọi `AjaxHPAParadise` tới `sp_Rank_getPersonalRating`, `sp_Rank_getDepartment`, `sp_Rank_GetEmployeeDetail`, `paradisefile_sp_GetFileAPI` |
| Bảng nghiệp vụ ranking | `tblRank_PersonalRating_Detail`, `tblRank_PointType`, `tblRank_Coin_Wallet`, `tblRank_Coin_Transaction` |

Cách hoạt động tổng quát:

1. User mở menu `MnuTM022`.
2. App đọc `MEN_Menu.ClassName = 'sp_Train_Ranking_Template'` và nhận diện đây là `DataSetting`.
3. App đọc `tblDataSetting` để biết đây là procedure và có layout (`IsProcedure = 1`, `IsShowLayout = 1`).
4. App đọc `tblDataSettingLayout` theo `TableName = 'sp_train_ranking_template'` để dựng layout root + control `ParadiseWebView2` tên `html`.
5. App gọi procedure `sp_Train_Ranking_Template`; procedure này trả về 1 cột `html` từ `tblHtmlScriptCache`.
6. Control `ParadiseWebView2` render HTML/CSS/JS trong cột `html`.
7. JavaScript trong HTML tự gọi API qua `AjaxHPAParadise`:
   - `sp_Rank_getPersonalRating` lấy danh sách xếp hạng, năm, phòng ban, kỳ lương.
   - `sp_Rank_getDepartment` lấy danh sách phòng ban.
   - `paradisefile_sp_GetFileAPI` lấy ảnh nhân viên.
8. Khi click nhân viên, JS gọi `openFormParam('sp_Train_Ranking_TemplateDetail', params)` hoặc `OpenFormParamMobile(...)` để mở màn hình chi tiết.
9. Màn hình detail `sp_Train_Ranking_TemplateDetail` lặp lại cơ chế trên, render HTML từ `tblHtmlScriptCache`, rồi gọi `sp_Rank_GetEmployeeDetail` để lấy thông tin/ranking/history.

```sql
-- Menu + DataSetting
SELECT m.MenuID, msg.Content AS MenuNameVN, m.AssemblyName, m.ClassName,
       m.IsWeb, m.isShowLayOutWeb,
       ds.TableName, ds.ViewName, ds.IsProcedure, ds.IsShowLayout,
       DATALENGTH(ds.LayoutDataConfigWeb) AS LayoutDataConfigWebBytes
FROM MEN_Menu m
LEFT JOIN tblMD_Message msg ON msg.MessageID = m.MenuID AND msg.Language = 'VN'
LEFT JOIN tblDataSetting ds ON ds.TableName = m.ClassName OR ds.ViewName = m.ClassName
WHERE m.MenuID IN ('MnuTM022', 'MnuTM025');

-- HTML cache đang được render
SELECT TableName, LanguageID, ScreenType, DATALENGTH(html) AS HtmlBytes
FROM tblHtmlScriptCache
WHERE TableName IN ('sp_Train_Ranking_Template_html', 'sp_Train_Ranking_TemplateDetail_html')
ORDER BY TableName, LanguageID;
```

Ghi chú: với kiểu mới này, `tblDataSetting.LayoutDataConfigWeb` có thể rỗng/null. Layout "thật" là HTML/CSS/JS nằm trong `tblHtmlScriptCache.html`, còn `tblDataSettingLayout` chỉ đóng vai trò tạo vùng chứa WebView (`ParadiseWebView2`).

### Schema `tblHtmlScriptCache` — các cột bắt buộc khi insert thủ công

Khi renderer tự upsert vào cache, phải fill **đủ các cột notnull** dưới đây — nếu thiếu sẽ lỗi `Cannot insert NULL`:

| Cột | Kiểu | PK | NotNull | Mô tả |
|---|---|---|---|---|
| `TableName` | nvarchar | ✓ | (PK) | Tên proc renderer (vd `sp_HelloWorldVietinsoft_html`) |
| `LanguageID` | varchar | ✓ | (PK) | `'VN'` / `'EN'` / ... |
| `ScreenType` | varchar | | ✓ | Mặc định `'-1'` (chung) |
| `html` | nvarchar | | ✓ | HTML/CSS/JS chính |
| `HtmlParadise` | nvarchar | | ✓ | Có thể `N''` nếu không dùng phiên bản Paradise riêng |
| `paradiseJs` | nvarchar | | ✓ | Có thể `N''` |
| `Version` | varchar | | ✓ | Mặc định `'1'` |
| `VersionData` | nvarchar | | ✓ | Có thể `N''` |

Mẫu upsert idempotent dùng `MERGE` theo `(TableName, LanguageID)`: xem [SQL script/deploy_menu_HelloWorldVietinsoft_20260520.sql](../SQL%20script/deploy_menu_HelloWorldVietinsoft_20260520.sql).

### Script ví dụ tham chiếu — `MnuHEP910 / Hello world Vietinsoft`

[SQL script/deploy_menu_HelloWorldVietinsoft_20260520.sql](../SQL%20script/deploy_menu_HelloWorldVietinsoft_20260520.sql) là script triển khai trọn vẹn 1 menu Web kiểu HTML-rendered: 2 procedure (renderer + wrapper) + `MEN_Menu` + `tblSC_Object` + `tblMD_Message` VN/EN + cache + permission `LoginID = 3` + refresh. Idempotent, bọc TRY/CATCH + transaction. Có thể dùng như template cho menu HTML-rendered mới.

### Quy trình tính điểm kinh nghiệm và xếp hạng nhân viên (cùng menu Xếp hạng)

Hệ thống ranking không chỉ là màn hình hiển thị. Khi màn hình gọi `sp_Rank_getPersonalRating`, procedure này **kích hoạt/tái tính điểm** qua `sp_PerformanceKPI_Working_Process` theo kỳ lọc trước khi tổng hợp rank.

Nguồn dữ liệu chính:

| Nhóm | Bảng/procedure | Vai trò |
|---|---|---|
| Fact điểm | `tblRank_PersonalRating_Detail` | Mỗi dòng là một phát sinh điểm/coin của nhân viên theo ngày và `PointType`. Cột chính: `EmployeeID`, `ExperiencePonits`, `Coin`, `CreatedDate`, `PointType`. |
| Loại điểm | `tblRank_PointType` | Danh mục loại điểm: bài học, task, thưởng, đi trễ, về sớm, vào sớm, về trễ, giờ công, cuối tuần. |
| Tính điểm tự động | `sp_PerformanceKPI_Working_Process` | Tính lại điểm từ chấm công GPS/lịch/ca/nghỉ phép/task, rồi `MERGE` vào `tblRank_PersonalRating_Detail`. |
| Hiển thị danh sách rank | `sp_Rank_getPersonalRating` | Xác định kỳ lọc, gọi tính điểm, cộng điểm/coin và xếp hạng bằng `ROW_NUMBER()`. |
| Hiển thị chi tiết nhân viên | `sp_Rank_GetEmployeeDetail` | Lấy profile, tổng điểm/coin, lịch sử điểm và rank của một nhân viên trong kỳ. |
| Coin | `tblRank_Coin_Wallet`, `tblRank_Coin_Transaction`, `sp_Rank_Coin_Get` | Lưu ví coin/giao dịch coin. |

Danh mục `PointType` đã xác minh:

| PointType | Tên VN | Cách phát sinh |
|---:|---|---|
| 1 | Hoàn thành bài học | Module training. |
| 2 | Hoàn thành tốt công việc được giao | Từ task lá trong `tblTask_Tasks` có `StatusID = 4`, được duyệt trong `tblTask_Approvals`; điểm = `SUM(StandardTime) * 2`. |
| 3 | Thưởng | Manual. |
| 4 | Khác | Manual. |
| 5 | Đi trễ | phút trễ * `-2`. |
| 6 | Về sớm | phút về sớm * `-2`. |
| 7 | Vào sớm | phút vào sớm * `0.5`, chỉ tính khi không miss GPS. |
| 8 | Về trễ | phút về trễ * `0.5`, chỉ tính khi không miss GPS. |
| 9 | Giờ công | phút làm việc * `1`, tối đa `480` phút/ngày; CT/WFH vẫn được cộng theo `LvAmount * 60`. |
| 10 | Làm việc cuối tuần | số phút làm việc * `1`, nếu làm ít nhất 30 phút. |

Cách `sp_PerformanceKPI_Working_Process` tính điểm tự động:

1. Xác định kỳ tính: nếu không truyền `@FromDate/@ToDate` thì lấy kỳ lương hiện tại từ `fn_Get_SalaryPeriod_ByDate(GETDATE())`.
2. Nếu không chạy debug, procedure chỉ chạy vào **thứ 2 hằng tuần** hoặc **ngày cuối kỳ lương**; đồng thời dùng `sp_getapplock` và `tblProcessTracker` để tránh chạy trùng quá sát nhau.
3. Lấy danh sách nhân viên hợp lệ từ `fn_vtblEmployeeList_Bydate` (xem [15_employee_query_apis.md §2](15_employee_query_apis.md) cho chi tiết 3 chế độ filter), loại nhân viên nghỉ việc ngoài kỳ, loại nhân viên không chấm công (`TAOptionID <> 0`) và vị trí `tblPosition.NoTA = 1`.
4. Sinh lưới ngày làm việc theo từng nhân viên, lấy lịch/ca từ `tblWSchedule` + `tblShiftSetting`.
5. Lấy log GPS/chấm công từ `tblTmpAttend` trong kỳ; mỗi ngày chỉ giữ log vào sớm nhất (`AttState = 1`) và log ra muộn nhất (`AttState = 2`).
6. Map log vào lịch để có `AttStart`, `AttEnd`, xử lý ca qua đêm và tính `WorkingTimeMinute`.
7. Lấy nghỉ phép `tblLvHistory`: riêng `CT`, `WFH` vẫn được cộng điểm giờ công (`PointType = 9`).
8. Tính điểm attendance vào bảng tạm `#tmpPointWorking` theo công thức từng `PointType`.
9. Lấy task hoàn thành; điểm task = `SUM(StandardTime) * 2`, `PointType = 2`.
10. `MERGE` vào `tblRank_PersonalRating_Detail` theo khóa logic (`EmployeeID`, `CreatedDate`, `PointType`).

Cách xếp hạng:

```sql
SELECT EmployeeID,
       SUM(ExperiencePonits) AS TotalPoints,
       SUM(Coin) AS TotalCoin,
       MIN(CreatedDate) AS EarliestDate
FROM tblRank_PersonalRating_Detail
WHERE CreatedDate BETWEEN @FilterDateFrom AND @FilterDateTo
GROUP BY EmployeeID;

ROW_NUMBER() OVER (
  ORDER BY ISNULL(TotalPoints, 0) DESC,
           EarliestDate ASC,
           FullName ASC
) AS Rank
```

## 11. Refresh cache sau khi tạo

Quy trình refresh chuẩn theo rule cấp quyền của dự án (xem [12_CreateMenu.md](12_CreateMenu.md) header + [13_Migrate_Menu.md](13_Migrate_Menu.md) header): **chỉ chạy 1 lệnh refresh duy nhất**.

```sql
-- Refresh cache layout sau khi save MEN_Menu — PHẢI truyền @ClassName
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>';
-- (proc nội bộ resolve MenuID/AssemblyName/ParentMenuID rồi gọi sp_Men_Menu_AfterSave)
```

> ⚠️ **TUYỆT ĐỐI KHÔNG** thêm `EXEC sp_UpdateMenuInUserRight @ObjectID = ...` vào script tạo/migrate menu. Proc này tự cấp `FullAccess = 32` cho **MỌI LoginID > 0** trong `tblSC_Login` → mở quyền menu cho toàn hệ thống, vi phạm rule cấp quyền (script chỉ cấp cho `LoginID = 3`; user tự cấp quyền cho user/group khác qua app hoặc script riêng).

**Hành vi `sp_UpdateMenuInUserRight @ObjectID`** (verify từ `OBJECT_DEFINITION` — chỉ ghi để tham khảo):
- Insert `tblSC_Right_Stored(ObjectID, LoginID, FullAccess=32)` cho **MỌI LoginID > 0** chưa có quyền với ObjectID này.
- Update `FullAccess = 32` cho mọi row đã có.

User cần logout/login để cây menu được load lại.

## 12. Procedure liên quan đến menu

| Procedure | Mục đích |
|---|---|
| `sp_s_CreateMenu` | Tạo nhanh menu (bao gồm cả cấp quyền) |
| `sp_Men_Menu_AfterSave`, `sp_Men_Menu_AfterSave_Simple` | Refresh sau khi save `MEN_Menu` |
| `sp_UpdateMenuInUserRight` | Cập nhật cache menu trong phân quyền |
| `sp_UpdateMenuName` | Đổi tên menu đa ngôn ngữ |
| `[1rename_Mess]` | Insert/update `tblMD_Message` (đặt tên menu/label) |
| `sp_LoadMenuByMenuID`, `sp_Menu_Load`, `sp_Menu_Load_open`, `sp_Menu_LoadSimpleUI` | Load menu khi user mở |
| `sp_Mobile_GetLeftMenu`, `sp_Mobile_GetFullInfoMenu`, `MenuMobile` | Load menu cho Mobile app |
| `MenuSearch`, `sp_Mobile_SearchMenu`, `ss_GetMenuSearch` | Search menu |
| `sp_MenuList`, `MST_MENU_GET_ALL_INDIVIDUAL`, `sp_ParentMenu_list` | Liệt kê menu |
| `GetMenuDetail`, `sp_getObject_menuID` | Lấy chi tiết 1 menu |
| `sp_decentralization_Menu` | Phân cấp menu |
| `sp_UpdateKeysShortcutMenu` | Cập nhật phím tắt |
| `sp_RecentlyUsedMenu_List`, `sp_RecentlyUsedMenu_update` | Lịch sử menu gần dùng |

## Menu phê duyệt tăng ca

Hệ thống có hai menu hoạt động chính để phê duyệt tăng ca (một cho dữ liệu chấm công và một cho đơn từ trên Portal/Web), cùng một menu cũ đã lỗi thời:

### 1. Menu duyệt dữ liệu chấm công tăng ca (Desktop app)
Menu chính hiển thị danh sách phê duyệt và xác nhận giờ công tăng ca trên phần mềm Desktop là `MnuTAD060`:
- **`MenuID`**: `MnuTAD060`
- **Tên hiển thị (VN)**: `Xác nhận dữ liệu tăng ca` (Tên tiếng Anh: `Overtime approval`)
- **`ParentMenuID`**: `MnuTAD000` (Quản lý chấm công / Time Attendance)
- **`ClassName`**: `TA_OverTime_List_Approval` (dữ liệu nguồn từ `tblDataSetting` với bảng cập nhật/chỉnh sửa là `tblOTList`)
- **`IsVisible`**: `1` (Đang hoạt động)

### 2. Menu duyệt đơn xin tăng ca (Web Portal / ESS / Desktop WebView)
Menu dùng để phê duyệt các đơn xin tăng ca do nhân viên gửi lên từ Mobile/Web là `MnuWPT037`:
- **`MenuID`**: `MnuWPT037`
- **Tên hiển thị (VN)**: `Danh sách phê duyệt` (Tên tiếng Anh: `List to review`)
- **`ParentMenuID`**: `MnuWPT000` (Portal / WorkFlow)
- **`ClassName`**: `sp_List_To_Review` (giao diện HTML-rendered sử dụng renderer `sp_List_To_Review_html`, khi click duyệt đơn tăng ca thuộc `group = 6` sẽ gọi form `sp_overtime_assignment`)
- **`IsVisible`**: `1` (Đang hoạt động)

### 3. Menu Web cũ đã lỗi thời (DEPRECATED)
Toàn bộ menu Web kiểu **ASPX-style** (URL trỏ trực tiếp tới file `.aspx`) đã được user xác nhận **không còn sử dụng** — bao gồm cả menu duyệt tăng ca `MnuATTAppOT` (`/ATT/ApprovalOTList.aspx`). Danh sách đầy đủ các MenuID còn sót trong DB và script cleanup: xem [99_deprecated.md §5](99_deprecated.md).

Câu SQL xác minh trạng thái các menu phê duyệt tăng ca:

```sql
SELECT m.MenuID,
       msg.Content AS MenuNameVN,
       msgEN.Content AS MenuNameEN,
       m.ParentMenuID,
       m.AssemblyName,
       m.ClassName,
       m.IsVisible,
       m.IsWeb,
       m.URL
FROM MEN_Menu m
LEFT JOIN tblMD_Message msg ON msg.MessageID = m.MenuID AND msg.Language = 'VN'
LEFT JOIN tblMD_Message msgEN ON msgEN.MessageID = m.MenuID AND msgEN.Language = 'EN'
WHERE m.MenuID IN ('MnuTAD060', 'MnuWPT037', 'MnuATTAppOT');
```

## 13. Quy trình end-to-end lập trình + vận hành 1 menu — ví dụ "Sales Pipeline" (`MnuKPI007`)

Ví dụ này mô tả **toàn bộ vòng đời** của menu HTML-rendered (cùng pattern với Section 10).

### Dữ liệu thực tế của `MnuKPI007` đang có trong DB

| Bảng | Giá trị |
|---|---|
| `MEN_Menu` | `MenuID='MnuKPI007'`, `ClassName='sp_KPIProcessCustomer'`, `AssemblyName='DataSetting'`, `ParentMenuID='MnuKPI000'`, `Priority=3`, `IsVisible=1`, `IsUseMobileDevice=1`, `glyphicon='Report'`, `GroupID='MnuKPI000'` |
| `tblSC_Object` | `ObjectID=347`, `ObjectName='DataSetting.sp_KPIProcessCustomer'`, `Description='MnuKPI007'`, `ParentObjectID=101098` |
| `tblMD_Message` | `MnuKPI007 / VN`: "Sales Pipeline" (EN chưa được thiết lập) |
| Menu cha `MnuKPI000` | `Content VN`: "Trang chủ CRM", `EN`: "CRM Dashboard", `ParentMenuID='Mnu'` |
| Phân quyền | `tblSC_Right_Stored`: LoginID 3, 4, 5, 6, 7 — đều `FullAccess=32`. `tblSC_GroupRight`: chưa có. |
| Procedure | `sp_KPIProcessCustomer` (wrapper) + `sp_KPIProcessCustomer_html` (renderer) — cả 2 là `SQL_STORED_PROCEDURE` |

### Cấu trúc cặp procedure (verbatim từ `OBJECT_DEFINITION`)

```sql
-- Wrapper: chỉ đọc HTML từ cache
CREATE PROCEDURE [dbo].[sp_KPIProcessCustomer](
    @LoginID    int,
    @languageID varchar(5) = 'VN'
) AS BEGIN
    SELECT TOP 1 html FROM tblHtmlScriptCache
    WHERE TableName  = 'sp_KPIProcessCustomer_html'
      AND ScreenType = -1
      AND LanguageID = @LanguageID;
END

-- Renderer: build HTML Kanban (CSS + markup + JS), upsert vào cache
CREATE PROCEDURE [dbo].[sp_KPIProcessCustomer_html](
    @LoginID    INT = 3,
    @LanguageID VARCHAR(2) = 'EN',
    @isWeb      INT = 0
) AS BEGIN
    DECLARE @html NVARCHAR(MAX);
    SET @html = N'<div id="customerKanbanComponent"> … Kanban CSS + HTML … </div>';
    -- UPSERT vào tblHtmlScriptCache
END
```

### Lưu đồ 9 phase từ thiết kế đến đưa cho user

```
[A] Thiết kế nguồn dữ liệu          → quyết định pattern: DataSetting grid HAY HTML-rendered
        │
        ▼
[B] Viết cặp procedure              → <class>_html (renderer) + <class> (wrapper đọc cache)
        │
        ▼
[C] Tạo menu (4 mảnh dữ liệu)       → sp_s_CreateMenu  HAY  insert thủ công MEN_Menu +
                                       tblSC_Object + tblMD_Message + tblSC_Right_Stored
        │
        ▼
[D] Set cờ nền tảng + UI            → IsUseMobileDevice, glyphicon, GroupID, Priority
        │
        ▼
[E] Phân quyền (xem 11_permissions) → tblSC_Right_Stored / tblSC_GroupRight + data scope
        │
        ▼
[F] Build HTML cache lần đầu        → CHỈ dùng helper sp_GenerateHTMLScript '<class>_html'
        │
        ▼
[G] Refresh menu cache              → CHỈ sp_Men_Menu_AfterSave_Simple @ClassName='…'
                                       KHÔNG gọi sp_UpdateMenuInUserRight (xem Section 11 + rule cấp quyền)
        │
        ▼
[H] Đưa cho user đang dùng          → user logout/login → load lại cây menu
                                       Web: sp_Menu_Load_PortalView / sp_LoadMenuByMenuID
                                       Mobile: MenuMobile / sp_Mobile_GetFullInfoMenu
        │
        ▼
[I] Client gọi menu runtime         → app gọi sp_KPIProcessCustomer → nhận HTML cached →
                                       render trong ParadiseWebView2 / WebView mobile →
                                       JS trong HTML gọi tiếp API qua AjaxHPAParadise /
                                       paradisepublic để load data động (Kanban cards)
```

### Phase chi tiết với ví dụ `MnuKPI007`

**Phase C — Tạo menu qua `sp_s_CreateMenu`**

```sql
EXEC dbo.sp_s_CreateMenu
     @Text         = N'Sales Pipeline',
     @TextEN       = 'Sales Pipeline',
     @ClassName    = 'sp_KPIProcessCustomer',
     @ParentMenuID = 'MnuKPI000',
     @AssemblyName = 'DataSetting',
     @Option       = 1,
     @LoginIDList  = '3,4,5,6,7';
```

Procedure tự sinh `MenuID = 'MnuKPI007'` (`LEFT('MnuKPI000', 6) + (MAX(số sau) + 1)`) và `ObjectID = 347` (MAX+1).

**Phase D — Cờ riêng**

```sql
UPDATE MEN_Menu
SET    IsUseMobileDevice = 1,
       glyphicon         = 'Report',
       GroupID           = 'MnuKPI000',
       Priority          = 3
WHERE  MenuID = 'MnuKPI007';
```

**Phase F — Build cache HTML bằng helper `sp_GenerateHTMLScript` (cách duy nhất)**

```sql
EXEC dbo.sp_GenerateHTMLScript 'sp_KPIProcessCustomer_html';
```

Khi sửa renderer → xoá cache cũ rồi build lại bằng helper:

```sql
DELETE FROM tblHtmlScriptCache
WHERE  TableName = 'sp_KPIProcessCustomer_html';

EXEC dbo.sp_GenerateHTMLScript 'sp_KPIProcessCustomer_html';
```

> ✅ Chuẩn thống nhất: không khuyến nghị gọi trực tiếp procedure renderer `_html` theo từng `LanguageID`; dùng helper `sp_GenerateHTMLScript` để build/rebuild cache.

### Đặc điểm thiết kế đáng chú ý

| Đặc điểm | Lợi ích |
|---|---|
| Tách markup khỏi logic config | Sửa UI = sửa renderer + reset cache; không đụng `MEN_Menu`/`tblSC_Object` |
| Cache per-`LanguageID` | Đa ngôn ngữ không cần i18n phía client |
| Pattern đồng nhất | Toàn module CRM (`sp_CRM_*`), Mobile (`sp_*_Mobile`), nhiều dashboard dùng cùng pattern này |
| Versioning trong cache (`Version`, `VersionData`) | Client biết invalidate khi server đẩy version mới |

### Câu SQL kiểm tra trạng thái menu

```sql
SELECT m.MenuID, m.ClassName, m.AssemblyName, m.IsVisible,
       o.ObjectID, o.ObjectName,
       msgVN.Content AS NameVN, msgEN.Content AS NameEN,
       (SELECT COUNT(*) FROM tblSC_Right_Stored WHERE ObjectID = o.ObjectID) AS UsersDirect,
       (SELECT COUNT(*) FROM tblSC_GroupRight   WHERE ObjectID = o.ObjectID) AS GroupRights,
       (SELECT COUNT(*) FROM tblHtmlScriptCache WHERE TableName = m.ClassName + '_html') AS CachedLangs
FROM MEN_Menu m
LEFT JOIN tblSC_Object o     ON o.Description = m.MenuID
LEFT JOIN tblMD_Message msgVN ON msgVN.MessageID = m.MenuID AND msgVN.Language = 'VN'
LEFT JOIN tblMD_Message msgEN ON msgEN.MessageID = m.MenuID AND msgEN.Language = 'EN'
WHERE m.MenuID = 'MnuKPI007';
```
