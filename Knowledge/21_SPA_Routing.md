---
name: spa-routing-and-params
description: >
  Hướng dẫn cơ chế chuyển trang (Routing) trong Single Page Application (SPA) của ParadiseHR.
  Cách dùng openFormParam, OpenFormParamMobile để truyền tham số giữa các màn hình,
  cách nhận tham số ở form đích thông qua biến global <FormName>_param.
---

# Cơ chế SPA Routing và Truyền Tham số

Hệ thống ParadiseHR là một ứng dụng Single Page Application (SPA). Việc chuyển từ màn hình này (ví dụ: màn hình danh sách lưới) sang màn hình khác (ví dụ: form chi tiết) được thực hiện qua các hàm định tuyến (routing) dùng chung của hệ thống, đồng thời hỗ trợ truyền tham số (parameters).

## 1. Gọi hàm chuyển trang và truyền tham số

Tùy vào nền tảng (Web Desktop hay Mobile Webview), hệ thống cung cấp hai hàm khác nhau. Bạn nên luôn luôn dùng hàm `getMobileOperatingSystem()` để kiểm tra môi trường và gọi đúng hàm:

```javascript
// 1. Chuẩn bị dữ liệu cần truyền sang form đích
let paramData = { currentID: 2, action: "edit" };
let targetForm = "sp_CRM_EditProductType"; // Tên màn hình đích (không có đuôi _html)

// 2. Chuyển form an toàn cross-platform
if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
    OpenFormParamMobile(targetForm, paramData);
} else {
    openFormParam(targetForm, paramData);
}
```

## 2. Cách nhận tham số ở Form Đích

Sau khi gọi hàm chuyển form, hệ thống sẽ mở giao diện của `targetForm` và **tự động khởi tạo một biến toàn cục (global variable)** để chứa toàn bộ dữ liệu (object) được truyền vào. 

**Quy tắc đặt tên biến tự động:** `<Tên_Form>_param`

Ví dụ, nếu `targetForm` là `sp_CRM_EditProductType`, thì bên trong code JS của màn hình đích này, bạn có thể truy xuất tham số rất dễ dàng:

```javascript
// Biến này ĐÃ ĐƯỢC HỆ THỐNG TỰ ĐỘNG KHAI BÁO VÀ GÁN GIÁ TRỊ (bạn không cần let/var)
console.log(sp_CRM_EditProductType_param); 
// Output: { currentID: 2, action: "edit" }

// Lấy id để xử lý
let id = sp_CRM_EditProductType_param.currentID;

// Thực hiện gọi Ajax để load dữ liệu chi tiết vào các Control dựa trên id này...
```

## 3. Ứng dụng thực tế: Click dòng mở Form chi tiết từ ControlGrid

Đây là pattern chuẩn và phổ biến nhất: Cấu hình lưới với cờ `IsOpenDetailRowGrid = 1`, sau đó viết mã JS trong sự kiện `openDetail<Khóa_Chính>` để chuyển sang trang chi tiết.

```javascript
// Giả sử Khoá chính của lưới là 'TemplateName'
window.openDetailTemplateName = function(rowData) {
    let targetForm = "sp_REC_EmailTemplateDetail"; // Tên SP của màn hình chi tiết
    
    // Đóng gói data truyền đi (thường là khóa chính)
    let paramData = { 
        TemplateName: rowData.TemplateName 
    };

    // Điều hướng theo nền tảng
    if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
        OpenFormParamMobile(targetForm, paramData);
    } else {
        openFormParam(targetForm, paramData);
    }
};
```

## 4. Bắt buộc: Đăng ký Menu ẩn để Routing hoạt động
Để hàm `openFormParam` có thể tìm thấy màn hình đích, màn hình đó PHẢI được khai báo trong `tblMD_Message` và `MEN_Menu` (dù nó không hiển thị trên cây menu gốc).

```sql
-- 1. Khai báo Message
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'sp_REC_GridTest_Detail')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) 
    VALUES ('sp_REC_GridTest_Detail', 'VN', N'Chi tiết Form'),
           ('sp_REC_GridTest_Detail', 'EN', 'Form Detail');
END

-- 2. Đăng ký Menu ẩn (Gắn vào 1 ParentMenuID hợp lệ, ví dụ 'MnuREC001')
IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE ClassName = 'sp_REC_GridTest_Detail')
BEGIN
    INSERT INTO MEN_Menu (
        MenuID, ParentMenuID, ClassName, Priority, IsWeb, 
        Activity, showDialog, AssemblyName, IsVisible, Separation
    )
    VALUES (
        'sp_REC_GridTest_Detail', 'MnuREC001', 'sp_REC_GridTest_Detail', 999, 1, 
        'DataSettingListViewActivity', 0, 'DataSetting', 1, 1
    );
END
```
