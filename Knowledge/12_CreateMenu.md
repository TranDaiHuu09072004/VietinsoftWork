# 12 — Skill: Tạo menu Web mới trong ParadiseHR (HTML-rendered)

> Hướng dẫn thiết lập đầu-cuối để tạo mới menu Web kiểu HTML-rendered.
> Liên quan: [07_menu_system.md](07_menu_system.md) (nền) · [13_Migrate_Menu.md](13_Migrate_Menu.md) (migrate) · [14_ParadiseStyle.md](14_ParadiseStyle.md) (UI CSS) · [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) (JS escaping).

---

## 1. 7 Quy tắc bắt buộc

### Rule 1 — Quyền hạn
* **Chỉ cấp cho admin (`LoginID = 3`)**: `INSERT tblSC_Right_Stored(ObjectID, LoginID = 3, FullAccess = '32')`.
* **CẤM** gọi `sp_UpdateMenuInUserRight` trong script tự động (sẽ cấp quyền tràn lan cho mọi user).
* **Refresh**: Chỉ gọi `EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>'`.

### Rule 2 — Cấu hình cờ `MEN_Menu` (Chọn 1 trong 2 cách hiển thị)
* **Cách 1: Pure HTML Render (Hiện đại - KHUYẾN NGHỊ)**:
  * `IsWeb = 1`, `ViewOnWeb = 1` hoặc `0`, `isShowLayOutWeb = 1` (hoặc `0` để hiện trên menu/search).
  * `IsUseMobileDevice = 0`, `isShowInMobileLayOut = 0`.
* **Cách 2: WebView qua Mobile Engine (Legacy)**:
  * `IsWeb = 0`, `ViewOnWeb = 0`, `isShowLayOutWeb = 0`.
  * `IsUseMobileDevice = 1`, `isShowInMobileLayOut = 0`.
* *Chung*: `IsVisible = 1` (bắt buộc).

### Rule 3 — Parent Menu
Phải có `IsVisible = 1`. Tránh chọn `MnuHEP000` (Trợ giúp - mặc định ẩn). Các parent an toàn: `MnuKPI000`, `MnuTM000`, `MnuWPT000`, `MnuHRS000`, `MnuPRL000`, `MnuTAD000`...

### Rule 4 — Cấu hình Metadata (Tránh màn hình trắng)
* **Nếu chọn Cách 1 (Pure HTML)**: Chỉ cần lưu trữ cache HTML trong `tblHtmlScriptCache`. Không cần cấu hình `tblDataSetting` hay `tblDataSettingLayout`.
* **Nếu chọn Cách 2 (WebView)**: Bắt buộc cấu hình đủ:
  * `tblDataSetting`: 1 dòng (`TableName = <ClassName>`, `IsProcedure = 1`, `IsShowLayout = 1`, `ColumnDataType = 'html&ViewHtml'`, `ColumnOrderBy = 'html&0'`).
  * `tblDataSettingLayout`: 2 dòng (`root` container và item `lblhtml` trỏ tới `ControlType = 'ParadiseWebView2'`).
  * `tblHtmlScriptCache`: Chứa cache HTML/CSS/JS.

### Rule 5 — Renderer an toàn
Mã nguồn renderer `<class>_html` phải tuân thủ [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md).

### Rule 6 — Cấu hình Grid phải dùng Infinite Scroll (CẤM Pager)
Nếu menu hiển thị danh sách dạng `dxDataGrid`, bắt buộc cấu hình:
* `scrolling.mode = "infinite"`
* `scrolling.rowRenderingMode = "virtual"`
* `paging.enabled = true`, `paging.pageSize = 50`
* `pager.visible = false` (Ẩn hoàn toàn thanh phân trang)
* `remoteOperations`: Cả 4 cờ `paging`, `filtering`, `sorting`, `grouping` phải set `true`.
* `dataSource`: Dùng `CustomStore` kết nối API `sp_LoadGridUsingAPI` (truyền `@Skip` / `@Take`).

### Rule 7 — Đa ngôn ngữ (`tblMD_Message`)

Bảng `tblMD_Message` là từ điển đa ngôn ngữ của hệ thống, được sử dụng trong **2 mục đích hoàn toàn tách biệt**:

**1. Dịch tên Menu (Tên hiển thị trên cây Menu/Tab)**
- Khi đăng ký một menu mới vào `MEN_Menu`, hệ thống dùng `MenuID` (vd: `MnuREC101`) để tìm tên hiển thị.
- **Bắt buộc:** Phải insert vào `tblMD_Message` với **`MessageID` CHÍNH LÀ `MenuID`** (TUYỆT ĐỐI KHÔNG dùng `ClassName`).
  *(Lưu ý: Nếu tạo menu bằng hàm `sp_s_CreateMenu` thì hàm đã tự làm việc này. Chỉ phải lưu ý quy tắc này khi INSERT thủ công vào `MEN_Menu` cho các form chi tiết ẩn).*

**2. Dịch `%Placeholder%` trong HTML/JS/Controls**
- Mọi text hiển thị bên trong nội dung menu (HTML, Label, Column Name) dùng cơ chế `%Placeholder%`:
  ```
  HTML: <div>%EmployeeID%</div>  → Build Cache → VN: <div>Mã nhân viên</div> | EN: <div>Employee ID</div>
  ```

**Tổng hợp các nơi áp dụng `tblMD_Message`**:
| Nơi dùng | Giá trị `MessageID` cần lưu | Cần `tblMD_Message`? |
|---|---|---|
| Tên Menu (Gắn với `MEN_Menu`) | **`MenuID`** (vd: `MnuREC101`) | ✅ Bắt buộc |
| `tblCommonControlType_Signed.DisplayName` | Nội dung `%...%` (vd: `FullName`) | ✅ Bắt buộc |
| HTML trong renderer | Nội dung `%...%` (vd: `EmployeeID`) | ✅ Bắt buộc |
| Label tĩnh trong T-SQL | ❌ Không có (xử lý bằng IF @LanguageID) | ❌ Không |

**Bắt buộc trong migration script**:
- Mọi `%MessageID%` dùng trong `tblCommonControlType_Signed` hoặc renderer HTML → phải có `tblMD_Message` entry cho **cả VN và EN**

---

## 2. Quy trình 10 Phase triển khai

```
[0] Khảo sát (Tên VN, Tên EN, Parent, ClassName, Nhóm/Login nhận quyền)
   ↓
[A] Tạo Procedure API dữ liệu động (sp_<Ten>_<Action>)
   ↓
[B] Tạo cặp SP giao diện: <class>_html (renderer) + <class> (wrapper đọc cache)
   ↓
[C] Tạo menu và Object: gọi sp_s_CreateMenu hoặc insert MEN_Menu + tblSC_Object
   ↓
[D] Thiết lập cờ Web/Mobile trên MEN_Menu (Rule 2)
   ↓
[E] Thêm cấu hình Metadata tblDataSetting và tblDataSettingLayout (Rule 4)
   ↓
[F] Cấp quyền LoginID = 3 và nhóm phân quyền được khảo sát
   ↓
[G] (Nếu có) Insert metadata tblCommonControlType_Signed và chạy SP DUC
   ↓
[H] Xóa cache cũ & chạy: EXEC sp_GenerateHTMLScript '<class>_html' để build cache mới
   ↓
[I] Làm sạch cache hệ thống: EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>'
   ↓
[J] Test runtime: User login -> click menu -> render UI -> check Ajax API
```

---

## 3. Nhánh Config-Driven (`tblCommonControlType_Signed`)

Sử dụng khi muốn tự sinh UI grid/form nhanh từ metadata của bảng.
* **Quy trình deploy**:
  1. Insert các dòng định nghĩa control vào `tblCommonControlType_Signed` với `UID` unique (Dùng tiền tố như `PCRM...`, `PUMG...` để tránh trùng global gây lỗi Msg 512).
  2. Chạy `EXEC sptblCommonControlType_Signed_DUC '<class_html>'` để sinh tự động mã `loadUI`/`loadData`.
  3. Tạo SP renderer `<class_html>` nhúng loadUI/loadData động:
     `SELECT @html = @html + loadUI FROM tblCommonControlType_Signed WHERE UID = '<UID>'`
  4. Chạy `sp_GenerateHTMLScript` để ghi cache.

---

## 4. Javascript CustomStore mẫu cho Grid (Infinite Scroll)

> ⚠️ **Before writing code that calls `AjaxHPAParadise`:** MUST check that the target procedure `name` exists in the DB. If not → ask user whether to create it. See [23_CallAPI.md §0](23_CallAPI.md).

```javascript
var gridInstance;
var _pageCache = {}; // Lưu cache skip/take cục bộ

var customStore = new DevExpress.data.CustomStore({
    key: "EmployeeID",
    load: function(loadOptions) {
        var d = $.Deferred();
        var params = [];
        
        // 1. Phân trang
        var skip = loadOptions.skip || 0;
        var take = loadOptions.take || 50;
        params.push("Skip", skip, "Take", take);
        
        // 2. Tìm kiếm / Lọc (Ví dụ: FullName)
        if (loadOptions.searchValue) {
            params.push("SearchValue", loadOptions.searchValue);
        }
        
        // 3. Sắp xếp
        if (loadOptions.sort && loadOptions.sort.length > 0) {
            params.push("SortField", loadOptions.sort[0].selector, "SortDir", loadOptions.sort[0].desc ? "DESC" : "ASC");
        }
        
        // Gọi API qua AjaxHPAParadise
        AjaxHPAParadise({
            data: {
                name: "sp_LoadGridUsingAPI",
                param: ["ProcName", "sp_LoadHelloWorldEmployeeList", "LoginID", window.LoginID, "ParamsList", params.join("|")]
            },
            success: function(res) {
                var json = typeof res === "string" ? JSON.parse(res) : res;
                var result = json.data[0] || [];
                var totalCount = json.data[1] && json.data[1][0] ? json.data[1][0].TotalCount : result.length;
                d.resolve(result, { totalCount: totalCount });
            },
            error: function(err) {
                d.reject(err);
            }
        });
        return d.promise();
    }
});

// Cấu hình Grid đè cấu hình bắt buộc
$("#gridContainer").dxDataGrid({
    dataSource: customStore,
    scrolling: { mode: "infinite", rowRenderingMode: "virtual" },
    pager: { visible: false },
    paging: { enabled: true, pageSize: 50 },
    remoteOperations: { paging: true, filtering: true, sorting: true, grouping: true }
});
```

---

## 5. Lỗi thường gặp và cách sửa

* **Màn hình trắng xóa**: Thiếu record trong `tblDataSetting` hoặc `tblDataSettingLayout` (Xem Rule 4).
* **Không cuộn trang được (Infinite loop scroll đứng im)**: Quên ẩn pager (`pager.visible = false`) hoặc thiếu `remoteOperations.paging = true`.
* **Lỗi `InstanceXXX is not defined`**: Chạy renderer trước khi chạy SP DUC, dẫn đến cột `loadUI` trong `tblCommonControlType_Signed` bị rỗng.
* **Lỗi subquery Msg 512**: Trùng lặp `UID` trong `tblCommonControlType_Signed` với menu khác. Phải đảm bảo UID là global unique.
