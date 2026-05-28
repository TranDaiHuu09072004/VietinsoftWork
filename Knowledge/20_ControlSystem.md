---
name: hpa-control-system
description: >
  Toàn bộ kiến thức về HPA Control System: tạo mới control (INSERT INTO tblCommonControlType_Signed),
  cấu hình ControlGrid, tích hợp vào source có sẵn, Public API, callback, biến runtime, quy tắc bắt buộc.
  Dùng khi người dùng đề cập đến: tạo control, thêm field vào màn hình, cấu hình ô nhập liệu,
  tblCommonControlType_Signed, sptblCommonControlType_Signed_DUC, hpaControlText, AutoSave,
  IsRequired, GridColumnName, TableEditor, DataSourceSP, ControlGrid, hpaControlSelectBox,
  hpaControlTagBox, Public API control, callback onSelectBoxChanged, suppress/resume, loadUI, loadData.
---

# HPA Control System

> File này là **nguồn duy nhất** cho toàn bộ kiến thức về HPA Control.
> - **Phần A** — Tạo mới: sinh INSERT SQL từ mô tả tiếng Việt
> - **Phần B** — Tích hợp & sử dụng: Public API, callback, biến runtime, quy tắc khi viết code

---

# PHẦN A — TẠO MỚI CONTROL

## A.1 Cấu trúc bảng tblCommonControlType_Signed

### Cột bắt buộc nhập

| Cột | Mô tả | Ví dụ |
|---|---|---|
| TableName | Tên SP chứa giao diện | `sp_CRM_CustomerDetail_html` |
| ColumnName | Tên cột lưu dữ liệu | `Industry_ID` |
| Type | Loại control | `hpaControlText` |
| AutoSave | 1: bật, 0: tắt (mặc định 0) | `0` |
| ReadOnly | 1: bật, 0: tắt (mặc định 0) | `0` |

### Cột thường dùng

| Cột | Mô tả | Ví dụ |
|---|---|---|
| ColumnIDName | Khóa chính của bảng | `Company_ID` |
| ColumnIDName2 | Khóa chính thứ 2 (nếu có) | `Branch_ID` |
| TableEditor | Bảng lưu dữ liệu | `tblCRM_CompanyInfo` |
| SPLoadData | SP lấy data cho grid | `sp_CRM_LoadCustomerDetail_lienhe` |
| DisplayName | Tên cột hiển thị trong ControlGrid | `Tên khách hàng` |
| GridColumnName | Tên Grid cha — quyết định cột nằm ở grid nào | `GridContractList` |
| IsRequired | 1: bắt buộc nhập, 0: không | `1` |
| TabIndex | Thứ tự tab giữa các ô input | `1` |
| DataSourceSP | SP lấy data cho SelectBox/TagBox/SelectEmployee | `sp_GetStatusList` |
| Layout | Dùng ControlGrid → `'Grid_View'`, không dùng → NULL | `NULL` |

### Cột nâng cao

| Cột | Mô tả |
|---|---|
| AllowSorting | ControlGrid: cho phép sắp xếp cột |
| AllowFiltering | ControlGrid: cho phép lọc dữ liệu |
| GridWidth | ControlGrid: độ rộng từng cột |
| IsMultiSelectEmployee | hpaControlSelectEmployee: 0=chọn 1, 1=chọn nhiều |
| IsOpenDetailRowGrid | Grid cha: mở giao diện mới khi click hàng |
| IsMultiSelectRowGrid | 1: cho phép chọn nhiều hàng trong Grid |
| TableAddNew | Bảng thêm mới option cho SelectBox/TagBox |
| ColumnNameAddNew | Cột thêm mới option cho SelectBox/TagBox |
| CustomValidate | Hàm validate khi AutoSave |
| KeyUpdateGrid | Key đồng bộ Grid (nhiều khóa chính) |
| ColumnNameSync | Tên cột đồng bộ với lưới |
| UseActionRichTextEditor | RichTextEditorPremium: 1=hiện nút lưu |
| ActionRichTextEditor | Tên hàm chạy khi nhấn nút lưu của RichTextEditorPremium |

### Cột tự động sinh (KHÔNG cần INSERT)
`ID`, `html`, `loadUI`, `loadData`, `UID`, `GroupIndex`

---

## A.2 Mapping loại control

> ⚠️ **Bảng này chỉ để THAM KHẢO — KHÔNG dùng để tự suy luận.** Khi user không nói rõ loại control, phải dùng `AskUserQuestion` (Bước 0). Chỉ dùng mapping này khi user đã xác nhận ngầm qua từ khóa trong mô tả (vd: "tạo combobox chọn loại" → `hpaControlSelectBox`).

| Từ khoá trong mô tả | Type |
|---|---|
| text, tên, mã, varchar ngắn, input thường | `hpaControlText` |
| textarea, ghi chú, mô tả, nội dung dài | `hpaControlTextArea` |
| richtext, editor, soạn thảo, word, văn bản phong phú | `hpaControlRichTextEditorPremium` |
| autocomplete, tìm kiếm gõ chữ, textsearch, search dropdown, gợi ý từ server | `hpaControlTextSearch` |
| combobox, dropdown, chọn 1, selectbox, loại, phân loại | `hpaControlSelectBox` |
| nhân viên, employee, người phụ trách, người dùng | `hpaControlSelectEmployee` |
| chọn nhiều, tagbox, multi, tags | `hpaControlTagBox` |
| checkbox, tick, đánh dấu, bật/tắt, true/false, 0/1 | `hpaControlCheckBox` |
| timeline, pipeline, tiến trình | `hpaControlPipeline` |
| segment, bộ lọc, khung chọn | `hpaControlSegmented` |
| ngày, date | `hpaControlDate` |
| ngày giờ, datetime | `hpaControlDateTime` |
| giờ, time | `hpaControlTime` |
| điện thoại, phone | `hpaControlPhone` |
| số, number, int, số lượng | `hpaControlNumber` |
| tiền, money, decimal, giá trị, doanh thu | `hpaControlMoney` |
| file, đính kèm, upload, tài liệu | `hpaControlFile` |

> ⚠️ `hpaControlRichTextEditor` (không có Premium) đã **không còn sử dụng**.

### Đặc điểm riêng của hpaControlTextSearch

- **Khác SelectBox**: TextSearch tìm kiếm server-side (debounce 300ms, lazy load 20 item/trang), không load toàn bộ danh sách một lần.
- **DataSourceSP phải trả về 2 result set**: `[{ID, Name, ...}]` và `[{TotalCount: N}]`. SP nhận tham số `@SearchText`, `@SearchTextNorm`, `@Skip`, `@Take`.
- **Callback khi chọn item**: `window["onTextSearchSelected_<ColumnName>"] = function(item, instance) {}`.
- **Biến global lưu ID đã chọn**: `window["<ColumnName>_SelectedID_<UID>"]`.
- Dùng khi danh sách quá lớn để load 1 lần (khách hàng, sản phẩm, v.v.).

---

## A.3 Quy tắc suy luận tự động

1. **IsRequired**: "bắt buộc", "không được để trống", "required" → `1`. Mặc định `0`.
2. **ReadOnly**: "chỉ xem", "không sửa", "readonly", "hiển thị" → `1`. Mặc định `0`.
3. **AutoSave**: Mặc định `0` trừ khi mô tả rõ "tự lưu" hoặc "autosave".
4. **DataSourceSP**: Chỉ thêm khi Type là `hpaControlSelectBox`, `hpaControlTagBox`, `hpaControlSelectEmployee`, hoặc `hpaControlTextSearch`.
5. **TabIndex**: Gán theo thứ tự xuất hiện trong mô tả, bắt đầu từ 1.
6. **DisplayName**: Nếu IsRequired=1, điền tên thân thiện (VD: `Tên hợp đồng`).
7. **Layout**: Chỉ điền `'Grid_View'` nếu mô tả dùng ControlGrid. Mặc định NULL.
8. **IsMultiSelectEmployee**: Chỉ thêm khi Type là `hpaControlSelectEmployee`. "chọn nhiều" → `1`, mặc định `0`.

### A.3.1 Hỏi về label cho input

Khi tạo control dạng input (form field), **luôn hỏi**:
- Có cần tạo label (tiêu đề hiển thị) cho ô input không?
- Nếu có, xin tên tiêu đề cụ thể cho từng ô.

Mặc định **không tự suy đoán** label nếu user chưa xác nhận.

---

## A.4 Quy trình sinh INSERT SQL

### Bước 0 — BẮT BUỘC HỎI: Chọn loại control cho từng cột

> ⚠️ **KHÔNG BAO GIỜ tự suy luận Type từ tên cột.** Tên cột `CreatedDate` không có nghĩa là dùng `hpaControlDate` — có thể user muốn `hpaControlDateTime`, `hpaControlText`, hoặc để `NULL`.

**Quy trình bắt buộc:**
1. Liệt kê danh sách cột cần tạo control
2. Dùng `AskUserQuestion` hiển thị multi-select hoặc từng câu hỏi cho user chọn **loại control** cho mỗi cột
3. Chỉ sau khi user xác nhận → mới sinh SQL

> Ngoại lệ duy nhất: user đã nói rõ loại control ngay từ đầu (vd: "tạo control Date cho cột NgaySinh") → không cần hỏi lại.

### Bước 1 — Phân tích input

Đọc mô tả. Xác định:
- `TableName`: tên SP màn hình (dạng `sp_..._html`)
- `ColumnIDName`: khóa chính
- `TableEditor`: bảng lưu (nếu đề cập)
- Danh sách cột cần tạo control

Nếu thiếu `TableName` hoặc `ColumnName`, **hỏi lại** trước khi sinh SQL.

### Bước 2 — Map từng cột

Với mỗi cột, xác định: `Type` (đã có từ Bước 0), `IsRequired`, `ReadOnly`, `AutoSave`, `DataSourceSP`, `TabIndex`, các cột nâng cao nếu có đề cập.

### Bước 3 — Sinh SQL

Chỉ INSERT các cột **có giá trị** (bỏ qua cột NULL/rỗng không cần thiết).
Các cột tự động sinh (`ID`, `html`, `loadUI`, `loadData`, `UID`) **không được INSERT**.

```sql
INSERT INTO tblCommonControlType_Signed
  (TableName, ColumnIDName, TableEditor, ColumnName, Type, DisplayName,
   GridColumnName, IsRequired, AutoSave, ReadOnly, TabIndex)
SELECT
  'sp_TenManHinh_html', 'TenKhoaChinh', 'tblTenBang', 'TenCot',
  'hpaControlText', 'Tên hiển thị', 'GridTenLuoi', 1, 0, 0, 1
```

### Bước 4 — Trình bày kết quả

1. **Bảng preview** — Markdown table, mỗi dòng 1 control
2. **SQL hoàn chỉnh** — Code block, copy-paste được ngay
3. **Giải thích** — Mỗi cột 1 dòng: lý do chọn Type + các setting đặc biệt

### Bước 5 — Build & Cập nhật UI (QUAN TRỌNG)

Sau khi INSERT hoặc UPDATE bảng `tblCommonControlType_Signed`, phải luôn chạy chuỗi 2 lệnh sau để cập nhật giao diện:

```sql
-- 1. Biên dịch control: Sinh mã JS/HTML nội bộ (cột loadUI, loadData, html)
EXEC sptblCommonControlType_Signed_DUC 'sp_TenManHinh_html';

-- 2. Đổ ra giao diện: Tổng hợp lại thành giao diện hoàn chỉnh và lưu vào tblHtmlScriptCache
EXEC sp_GenerateHTMLScript 'sp_TenManHinh_html';
```
> **Phân biệt:** `sptblCommonControlType_Signed_DUC` chỉ chuẩn bị code cho từng control đơn lẻ, còn `sp_GenerateHTMLScript` mới là hàm thực sự ghép chúng lại và đưa lên UI. Lỗi không cập nhật UI thường do quên gọi hàm số 2.

---

## A.5 Cấu hình ControlGrid

ControlGrid dùng cùng bảng `tblCommonControlType_Signed` nhưng có mục đích khác: **khai báo các cột hiển thị trong lưới (grid)**, không phải ô nhập liệu.

### Các cột đặc trưng của Grid

| Cột | Bắt buộc | Mô tả |
|---|---|---|
| TableName | ✓ | Tên menu/SP chứa grid |
| SPLoadData | ✓ | Tên SP load data lên grid |
| ColumnIDName | ✓ | Khóa chính của bảng |
| ColumnName | ✓ | Tên cột trong kết quả SP |
| Type | ✓ | Kiểu hiển thị dữ liệu trong cột |
| DisplayName | ✓ | Tiêu đề cột, dùng `%MessageID%` để lấy từ `tblMD_Message` |
| Layout | ✓ | Luôn để `'Grid_View'` |
| GridColumnName | ✓ | Tên khung grid cha |
| IsOpenDetailRowGrid | | `1`: click vào hàng sẽ mở giao diện chi tiết |
| AllowSorting | | `1`: cho phép sắp xếp cột |
| AllowFiltering | | `1`: cho phép lọc dữ liệu trong cột |
| GridWidth | | Độ rộng cột (px), VD: `150` |
| IsMultiSelectRowGrid | | `1`: cho phép chọn nhiều hàng |

### Mapping Type cho Grid

| Type | Dữ liệu gốc | Hiển thị |
|---|---|---|
| `hpaControlText` | DB trả về gì → hiện vậy | `Nguyễn Văn A` |
| `hpaControlDate` | `2025-01-01` | `01/01/2025` |
| `hpaControlDateTime` | `2025-01-01 08:00:00` | `08:00:00 01/01/2025` |
| `hpaControlMoney` | `100000000` | `100.000.000` |
| `hpaControlSelectEmployee` | ID nhân viên | Tên nhân viên |
| `hpaControlCheckBox` | 0/1 | Ô tích chọn |

### Dòng khai báo Grid cha (bắt buộc)

Trước khi INSERT các cột hiển thị, **phải có 1 dòng khai báo Grid cha** với `ColumnName` = tên id của khung Grid.

| Cột | Giá trị |
|---|---|
| ColumnName | Tên id khung Grid (bằng với `GridColumnName`) |
| SPLoadData | Tên SP load data lên Grid |
| Layout | `'Grid_View'` |
| **GridColumnName** | **Để `NULL` — tuyệt đối không điền tên grid vào đây** |
| ColumnIDName | Khóa chính để `keyExpr` nhận đúng row |
| IsOpenDetailRowGrid | `1` nếu click hàng mở chi tiết (chỉ đặt ở dòng này) |

> ⚠️ **QUAN TRỌNG**: `GridColumnName` của dòng Grid cha **bắt buộc để NULL**. Nếu điền tên grid vào đây sẽ gây lỗi render UI.

```sql
-- Dòng 1: khai báo Grid cha (GridColumnName = NULL bắt buộc)
INSERT INTO tblCommonControlType_Signed
  (TableName, SPLoadData, ColumnIDName, ColumnName, Type, Layout, GridColumnName, IsOpenDetailRowGrid)
SELECT 'sp_CRM_CustomerDetail_html', 'sp_CRM_LoadCustomerDetail_lienhe', 'Company_ID',
       'GridLienHe', 'hpaControlText', 'Grid_View', NULL, 1

-- Dòng 2+: từng cột hiển thị trong Grid
INSERT INTO tblCommonControlType_Signed
  (TableName, SPLoadData, ColumnIDName, ColumnName, Type, DisplayName, Layout, GridColumnName)
SELECT 'sp_CRM_CustomerDetail_html', 'sp_CRM_LoadCustomerDetail_lienhe', 'Company_ID',
       'ACFullname', 'hpaControlText', '%ACFullname%', 'Grid_View', 'GridLienHe'
```

> ⚠️ Thiếu dòng khai báo Grid cha → Grid sẽ không render được dù các cột đã INSERT đầy đủ.

### Quy tắc suy luận Grid

1. **Layout**: Luôn là `'Grid_View'` — không để NULL.
2. **GridColumnName**: Lấy từ mô tả. Nếu có nhiều grid trên 1 màn hình, mỗi grid có tên khác nhau.
3. **Dòng Grid cha**: Luôn sinh **trước tiên** cho mỗi Grid, với `ColumnName = GridColumnName` và `GridColumnName = NULL`.
4. **IsOpenDetailRowGrid**: Chỉ set `1` ở **dòng Grid cha**, không lặp lại ở các cột sau.
5. **DisplayName**: Ưu tiên dùng `%MessageID%`. Nếu người dùng cho tên trực tiếp thì dùng tên đó.
6. **SPLoadData**: Bắt buộc phải có ở cả dòng Grid cha lẫn từng cột.

---

## A.6 Ví dụ đầy đủ

### Ví dụ 1 — Control form thông thường

**Input:**
> Tạo control cho màn hình `sp_CRM_EditContract_html`, bảng lưu `tblCRM_Contract`, khóa chính `ContractID`. Tên hợp đồng (bắt buộc), Ngày ký (chỉ xem), Số tiền (tiền tệ), Trạng thái (chọn 1 từ `sp_GetContractStatusList`), Nhân viên phụ trách (chọn nhiều), Ghi chú (textarea).

**SQL:**

```sql
INSERT INTO tblCommonControlType_Signed
  (TableName, ColumnIDName, TableEditor, ColumnName, Type, DisplayName, IsRequired, AutoSave, ReadOnly, TabIndex)
SELECT 'sp_CRM_EditContract_html', 'ContractID', 'tblCRM_Contract', 'ContractName', 'hpaControlText', 'Tên hợp đồng', 1, 0, 0, 1

INSERT INTO tblCommonControlType_Signed
  (TableName, ColumnIDName, TableEditor, ColumnName, Type, IsRequired, AutoSave, ReadOnly, TabIndex)
SELECT 'sp_CRM_EditContract_html', 'ContractID', 'tblCRM_Contract', 'SignDate', 'hpaControlDate', 0, 0, 1, 2

INSERT INTO tblCommonControlType_Signed
  (TableName, ColumnIDName, TableEditor, ColumnName, Type, IsRequired, AutoSave, ReadOnly, TabIndex)
SELECT 'sp_CRM_EditContract_html', 'ContractID', 'tblCRM_Contract', 'Amount', 'hpaControlMoney', 0, 0, 0, 3

INSERT INTO tblCommonControlType_Signed
  (TableName, ColumnIDName, TableEditor, ColumnName, Type, IsRequired, AutoSave, ReadOnly, TabIndex, DataSourceSP)
SELECT 'sp_CRM_EditContract_html', 'ContractID', 'tblCRM_Contract', 'StatusID', 'hpaControlSelectBox', 0, 0, 0, 4, 'sp_GetContractStatusList'

INSERT INTO tblCommonControlType_Signed
  (TableName, ColumnIDName, TableEditor, ColumnName, Type, IsRequired, AutoSave, ReadOnly, TabIndex, IsMultiSelectEmployee)
SELECT 'sp_CRM_EditContract_html', 'ContractID', 'tblCRM_Contract', 'EmployeeID', 'hpaControlSelectEmployee', 0, 0, 0, 5, 1

INSERT INTO tblCommonControlType_Signed
  (TableName, ColumnIDName, TableEditor, ColumnName, Type, IsRequired, AutoSave, ReadOnly, TabIndex)
SELECT 'sp_CRM_EditContract_html', 'ContractID', 'tblCRM_Contract', 'Note', 'hpaControlTextArea', 0, 0, 0, 6
```

### Ví dụ 2 — ControlGrid

**Input:**
> Tạo grid danh sách liên hệ cho `sp_CRM_CustomerDetail_html`, SP load là `sp_CRM_LoadCustomerDetail_lienhe`, khóa chính `Company_ID`, grid tên `GridLienHe`. Các cột: Họ tên, Chức vụ, Ngày sinh, Lương. Click vào hàng mở chi tiết.

**SQL:**

```sql
-- Dòng 1: Grid cha — GridColumnName bắt buộc NULL
INSERT INTO tblCommonControlType_Signed
  (TableName, SPLoadData, ColumnIDName, ColumnName, Type, Layout, GridColumnName, IsOpenDetailRowGrid)
SELECT 'sp_CRM_CustomerDetail_html', 'sp_CRM_LoadCustomerDetail_lienhe', 'Company_ID',
       'GridLienHe', 'hpaControlText', 'Grid_View', NULL, 1

-- Dòng 2+: cột trong Grid
INSERT INTO tblCommonControlType_Signed
  (TableName, SPLoadData, ColumnIDName, ColumnName, Type, DisplayName, Layout, GridColumnName)
SELECT 'sp_CRM_CustomerDetail_html', 'sp_CRM_LoadCustomerDetail_lienhe', 'Company_ID',
       'ACFullname', 'hpaControlText', '%ACFullname%', 'Grid_View', 'GridLienHe'

INSERT INTO tblCommonControlType_Signed
  (TableName, SPLoadData, ColumnIDName, ColumnName, Type, DisplayName, Layout, GridColumnName)
SELECT 'sp_CRM_CustomerDetail_html', 'sp_CRM_LoadCustomerDetail_lienhe', 'Company_ID',
       'BirthDate', 'hpaControlDate', '%BirthDate%', 'Grid_View', 'GridLienHe'

INSERT INTO tblCommonControlType_Signed
  (TableName, SPLoadData, ColumnIDName, ColumnName, Type, DisplayName, Layout, GridColumnName)
SELECT 'sp_CRM_CustomerDetail_html', 'sp_CRM_LoadCustomerDetail_lienhe', 'Company_ID',
       'Salary', 'hpaControlMoney', '%Salary%', 'Grid_View', 'GridLienHe'
```

---

# PHẦN B — TÍCH HỢP & SỬ DỤNG CONTROL

## B.1 Tổng Quan Kiến Trúc

### Cách hệ thống hoạt động

Hệ thống sử dụng **SQL Stored Procedure** để sinh ra HTML + JavaScript. Các control được cấu hình trong bảng `tblCommonControlType_Signed` và được build bởi procedure `sptblCommonControlType_Signed_DUC`.

```sql
-- Mỗi control được định nghĩa bởi 1 dòng trong bảng tblCommonControlType_Signed
-- Các trường quan trọng:
--   UID          : ID duy nhất của control (VD: 'P34AFC5F15EFB43C4846CDA47E97E7748')
--   Type         : Loại control (VD: 'hpaControlText', 'hpaControlSelectBox', ...)
--   ColumnName   : Tên cột dữ liệu liên kết
--   ColumnIDName : Tên cột ID (khóa chính) để xác định record khi AutoSave
--   TableEditor  : Tên bảng chứa dữ liệu
--   ReadOnly     : 0 = editable, 1 = readonly
--   AutoSave     : 0 = manual, 1 = autosave
--   DataSourceSP : Tên SP trả về danh sách dữ liệu (cho SelectBox, TagBox, TextSearch)
--   DisplayName  : Tên hiển thị (placeholder/label)
--   Layout       : NULL = control đơn lẻ, 'Grid_View' = control nằm trong grid
--   GridColumnName : Tên cột grid mà control thuộc về
--                    (LƯU Ý: Nếu dòng này là khai báo grid container thì bắt buộc để NULL)
```

### Ba đoạn code mỗi control sinh ra

| Đoạn | Mô tả |
|------|--------|
| `html` | Thẻ HTML container: `<div id="%UID%"></div>` |
| `loadUI` | JavaScript khởi tạo DevExtreme widget + event handlers |
| `loadData` | JavaScript gán dữ liệu từ `obj.%ColumnName%` vào control |

### Cách inject control vào trang

```sql
SET @html = @html + N'
<script>
  (async () => {
    '
    -- ⚠️ SYSTEM CONTROLS — TỰ ĐỘNG SINH BỞI FRAMEWORK
    +(select loadUI from tblCommonControlType_Signed where UID = 'CONTROL_UID_1')
    +(select loadUI from tblCommonControlType_Signed where UID = 'CONTROL_UID_2')
    +N'
    // ========== Custom code bắt đầu từ đây ==========
  })();
</script>'
```

---

## B.2 Public API từng Control

### hpaControlText / hpaControlTextArea / hpaControlSelectBox / hpaControlTagBox

```javascript
Instance<ColumnName><UID>.setValue(val)              // Gán giá trị
Instance<ColumnName><UID>.getValue()                 // Lấy giá trị
Instance<ColumnName><UID>.option(name, value)        // Proxy tới widget.option()
Instance<ColumnName><UID>.repaint()                  // Repaint widget
Instance<ColumnName><UID>.clearValidationError()     // Xóa trạng thái lỗi
Instance<ColumnName><UID>.getDataSource()            // Lấy mảng DataSource (SelectBox/TagBox)
Instance<ColumnName><UID>._suppressValueChangeAction()  // Tạm dừng onValueChanged
Instance<ColumnName><UID>._resumeValueChangeAction()    // Bật lại onValueChanged
```

### hpaControlTextSearch

```javascript
Instance<ColumnName><UID>.setValue(val)
Instance<ColumnName><UID>.getValue()
Instance<ColumnName><UID>.getSelectedItem()    // Object item đã chọn từ dropdown
Instance<ColumnName><UID>.getSelectedID()      // ID của item đã chọn
Instance<ColumnName><UID>.option(name, value)
Instance<ColumnName><UID>.focus()
Instance<ColumnName><UID>.rebindInputEvent()   // Re-bind input event (sau khi DOM thay đổi)
Instance<ColumnName><UID>.destroy()            // Cleanup toàn bộ event + DOM
```

### hpaControlSelectEmployee

```javascript
Instance<ColumnName><UID>.setValue(idOrArrayIds)  // Gán ID hoặc mảng IDs
Instance<ColumnName><UID>.getValue()              // Lấy mảng IDs đã chọn
Instance<ColumnName><UID>.option(name, value)
Instance<ColumnName><UID>.repaint()
Instance<ColumnName><UID>.clearValidationError()
```

---

## B.3 Callback Pattern

```javascript
// SelectBox — được gọi SAU KHI giá trị thay đổi (chỉ khi user tương tác)
window["onSelectBoxChanged_<ColumnName>"] = function(value, instance, e) {};

// TagBox
window["onTagBoxChanged_<ColumnName>"] = function(value, instance, e) {};

// TextSearch — được gọi khi user chọn 1 item từ dropdown
window["onTextSearchSelected_<ColumnName>"] = function(item, instance) {};

// Text — validate tùy chỉnh trước khi save
window.myCustomValidate = async function(newVal) {
    if (newVal.length < 3) throw "Tối thiểu 3 ký tự";
    return true;
};
```

---

## B.4 Cơ Chế Chung

### Suppress/Resume Pattern — BẮT BUỘC khi set giá trị bằng code

```javascript
// ✅ ĐÚNG — tránh trigger AutoSave không mong muốn
Instance<ColumnName><UID>._suppressValueChangeAction();
Instance<ColumnName><UID>.option("value", newVal);
Instance<ColumnName><UID>._resumeValueChangeAction();

// ❌ SAI — sẽ trigger onValueChanged → kích hoạt AutoSave
Instance<ColumnName><UID>.option("value", newVal);
```

### AutoSave Flow

```
User thay đổi giá trị
    → Validation (Required + CustomValidate)
    → Build dataJSON: '["tableObjectId", ["ColumnName"], [newValue]]'
    → Build idValsJSON: '[["ColumnIDName", "ColumnIDName2"], [id1, id2]]'
    → Gọi saveFunction(dataJSON, idValsJSON)
    → Check response: dtError[0].Status === "ERROR" → showAlert
    → Sync SharedGrid (nếu có)
    → Dispatch event onHpaAutoSaveSuccess
    → Cập nhật OriginalValue
```

### SharedGrid Sync

```javascript
// 1. Tìm row key
let KeyRowTable = window.currentClicked_<GridColumnName>;

// 2. Update shared grid
window.updateSharedGridRow("<GridColumnName>", {
    "<KeyUpdateGrid>": KeyRowTable,
    "<ColumnName>": newValue
});

// 3. Update local DataSource array
DataSource.filter(item => item.RowID === KeyRowTable)[0]["<ColumnName>"] = newValue;
```

### Custom Event: onHpaAutoSaveSuccess

```javascript
// Lắng nghe sau khi control lưu thành công
document.getElementById("<UID>").addEventListener("onHpaAutoSaveSuccess", function(e) {
    console.log("Đã lưu:", e.detail.columnName, e.detail.value);
});
```

### loadDataSourceCommon

> ⚠️ **QUY TẮC BẮT BUỘC:**
>
> **Rule 1 — Bất kỳ control nào** (form hoặc grid column) có khai báo `DataSourceSP` trong `tblCommonControlType_Signed` → renderer **PHẢI** gọi `loadDataSourceCommon` với `columnName` khớp với `ColumnName` của control. Nếu không → control không có data → không hiển thị được tên/giá trị.
>
> **Rule 2 — `loadDataSourceCommon` PHẢI chạy TRƯỚC khi inject `loadUI`.** Vì `loadUI` cần đọc `window["DataSource_<ColumnName>"]` để render control. Nếu gọi sau → control render xong rồi data mới load → hiển thị blank.

```javascript
// Mẫu gọi trong renderer — columnName PHẢI khớp với ColumnName trong tblCommonControlType_Signed
if ("<DataSourceSP>" && "<DataSourceSP>".trim() !== "") {
    loadDataSourceCommon("<ColumnName>", "<DataSourceSP>", function(data) {});
}
// Ví dụ: cột OwnerID có DataSourceSP = 'EmployeeListAll_DataSetting_Custom'
loadDataSourceCommon("OwnerID", "EmployeeListAll_DataSetting_Custom", function(data) {});
```

**Thứ tự đúng trong renderer:**
```
1. Định nghĩa hàm loadDataSourceCommon()
2. Gọi loadDataSourceCommon("<ColumnName>", "<DataSourceSP>")  ← TRƯỚC loadUI
3. Inject loadUI của control (date, grid, selectEmployee...)
4. Code còn lại (ReloadData, openDetail, v.v.)
```

---

## B.5 Biến Global Quan Trọng

| Biến | Mô tả |
|------|--------|
| `window["DataSource_<ColumnName>"]` | Mảng dữ liệu của DataSource |
| `window["DataSourceIDField_<ColumnName>"]` | Tên field ID (mặc định "ID") |
| `window["DataSourceNameField_<ColumnName>"]` | Tên field Name (mặc định "Name") |
| `window.currentRecordID_<ColumnIDName>` | ID record hiện tại đang edit |
| `window.hpaSharedGridDataSources["<GridColumnName>"]` | DataSource của shared grid |
| `window.currentClicked_<GridColumnName>` | Key của row đang được click trong grid |
| `window.GlobalEmployeeAvatarCache` | Cache avatar nhân viên |
| `window["<ColumnName>_SelectedID_<UID>"]` | ID item đã chọn (TextSearch) |

---

## B.6 Biến Tùy Chỉnh UI (Set TRƯỚC loadUI)

| Biến window | Kiểu | Mặc định | Áp dụng cho | Mô tả |
|-------------|------|----------|-------------|-------|
| `_hideID_<ColumnName><UID>` | `boolean` | `false` | SelectBox, TagBox | Ẩn cột ID trong dropdown |
| `_hideSearch_<ColumnName><UID>` | `boolean` | `false` | SelectBox, TagBox | Ẩn ô tìm kiếm |
| `_isEdit_<ColumnName><UID>` | `boolean` | `false` | SelectBox, TagBox | Cho phép sửa item |
| `_isDelete_<ColumnName><UID>` | `boolean` | `false` | SelectBox, TagBox | Cho phép xóa item |
| `_displayedTags_<ColumnName><UID>` | `number` | `2` | TagBox | Số tag tối đa hiển thị |

### Biến Runtime Mode (Manual mode — AutoSave=0, ReadOnly=0)

| Biến (local scope) | Mô tả |
|---------------------|-------|
| `_autoSave<ColumnName><UID>` | Set `true` runtime → chuyển sang AutoSave |
| `_readOnly<ColumnName><UID>` | Set `true` runtime → chuyển sang readonly |

```sql
SET @html = @html + N'
<script>
(async () => {
    // === Set biến tùy chỉnh TRƯỚC loadUI ===
    window["_hideID_StatusP1234ABCD"] = true;
    window["_displayedTags_TagsP5678EFGH"] = 3;

    '
    -- Sau đó mới inject loadUI
    +(select loadUI from tblCommonControlType_Signed where UID = ''P1234ABCD'')
    +N'
})();
</script>'
```

---

## B.7 Quy Tắc BẮT BUỘC Khi Viết Code

### KHÔNG BAO GIỜ

```javascript
// ❌ Xóa dòng inject loadUI
+(select loadUI from tblCommonControlType_Signed where UID = 'xxx')

// ❌ Override event handler của system control
$("#UID").dxSelectBox("instance").option("onValueChanged", myHandler);

// ❌ Dùng window.Instance trực tiếp (vì Instance khai báo bằng let)
let val = window.InstanceNameXXX; // undefined!

// ❌ Gọi lại loadDataSourceCommon cho DataSource đã được loadUI gọi
loadDataSourceCommon("Name", "sp_xxx"); // DUPLICATE!
```

### LUÔN LUÔN

```javascript
// ✅ Dùng callback pattern thay vì override event
window["onSelectBoxChanged_ColumnName"] = function(value, instance, e) {};

// ✅ Suppress trước khi set programmatic value
Instance._suppressValueChangeAction();
Instance.option("value", val);
Instance._resumeValueChangeAction();

// ✅ Dùng DataSource đã được load sẵn
let data = window["DataSource_ColumnName"] || [];
```

---

## B.8 SQL String Safety

```sql
-- Single quote PHẢI escape thành double single-quote
N'var x = ''hello'';'

-- Dùng double quote cho JS strings
N'var x = "hello";'

-- jQuery selector bên trong SQL
N'$("<div class=''myClass''>")''

-- Template literal (backtick) hoạt động bình thường
N'var html = `<div>${value}</div>`;'
```

---

## B.9 Tóm Tắt Nhanh Theo Control

| Control | Widget | Trigger Save | Giá trị | Callback |
|---------|--------|-------------|---------|----------|
| **Text** | `dxTextBox` | Blur / Enter | string | — |
| **TextArea** | `dxTextArea` | Blur / Ctrl+Enter | string | — |
| **TextSearch** | `dxTextBox` + dropdown HTML | Chọn item / Blur / Enter | string | `window["onTextSearchSelected_<Col>"]` |
| **SelectBox** | `dxSelectBox` | `onValueChanged` | single ID | `window["onSelectBoxChanged_<Col>"]` |
| **TagBox** | `dxTagBox` | `onValueChanged` | array IDs | `window["onTagBoxChanged_<Col>"]` |
| **SelectEmployee** | Custom (dxPopup + dxDataGrid) | Confirm popup | array IDs | — |
