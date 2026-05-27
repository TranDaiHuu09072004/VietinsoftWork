---
name: call-api
description: >
  Quy chuẩn và hướng dẫn gọi API từ JS Client tới SQL Server Stored Procedure
  trong hệ thống ParadiseHR sử dụng hàm tiện ích AjaxHPAParadise.
---

# Gọi API trong ParadiseHR (`AjaxHPAParadise`)

> Hướng dẫn và quy chuẩn gọi Stored Procedure từ Javascript Client bằng hàm tiện ích `AjaxHPAParadise` của hệ thống ParadiseHR.

---

## 1. Cú pháp cơ bản của `AjaxHPAParadise`

Hàm `AjaxHPAParadise` là một wrapper API bất đồng bộ (AJAX) được xây dựng sẵn trong hệ thống ParadiseHR để giao tiếp với cơ sở dữ liệu SQL Server.

### Cấu trúc tiêu chuẩn
```javascript
AjaxHPAParadise({
    data: {
        name: "sp_ProcedureName", // Tên Stored Procedure nghiệp vụ cần chạy
        param: [                  // MẢNG PHẲNG chứa tham số
            "LoginID", window.UserID || window.LoginID,
            "LanguageID", window.LanguageID || "VN",
            "ParamName1", value1,
            "ParamName2", value2
        ]
    },
    success: function (res) {
        try {
            // 1. Giải mã dữ liệu nếu backend mã hóa đường truyền
            if (typeof res === "string" && !IsNullOrEmpty(res)) {
                res = res.includes("{") ? res : EncryptionStringDecryption(res);
            }
            
            // 2. Parse dữ liệu sang JSON Object
            const json = typeof res === "string" ? JSON.parse(res) : res;
            
            // 3. Lấy các table kết quả từ SQL Server
            const mainData = json?.data?.[0] || []; // Result-set 1 (bảng SELECT thứ nhất)
            const extraData = json?.data?.[1] || []; // Result-set 2 (nếu procedure có nhiều SELECT)

            if (mainData && mainData.length > 0) {
                // Thực hiện logic xử lý dữ liệu và UI ở đây
            }
        } catch (e) {
            console.error("[callAPI] Lỗi xử lý phản hồi:", e);
        }
    },
    error: function (err) {
        // Luôn hiển thị thông báo lỗi cho người dùng bằng UI Helper hệ thống
        if (window.uiManager && typeof window.uiManager.showAlert === "function") {
            window.uiManager.showAlert({
                type: "error",
                message: "Không thể tải dữ liệu từ máy chủ. Vui lòng kiểm tra kết nối mạng!"
            });
        }
    }
});
```

---

## 2. 4 Quy tắc bắt buộc khi truyền tham số (`param`)

> [!IMPORTANT]
> Vi phạm bất kỳ quy tắc nào dưới đây sẽ dẫn đến lỗi runtime JS hoặc lỗi HTTP 500 từ phía server.

1. **BẮT BUỘC dùng mảng phẳng (Flat Array)**:
   * Tham số phải được truyền dưới dạng mảng phẳng tuần tự cặp tên-giá trị: `["Tên_Tham_Số_1", Giá_Trị_1, "Tên_Tham_Số_2", Giá_Trị_2]`.
   * **CẤM** truyền dạng Object như `{ ParamName: value }`.
2. **KHÔNG viết ký tự `@`**:
   * Tên tham số truyền trong mảng phải viết dạng text thuần (ví dụ: `"LoginID"`, `"LanguageID"`, `"Keyword"`).
   * Framework phía Backend sẽ tự động tiền tố `@` khi liên kết với Stored Procedure.
3. **BẮT BUỘC truyền tham số hệ thống**:
   * Luôn truyền `"LoginID"` (dùng `window.UserID || window.LoginID`).
   * Luôn truyền `"LanguageID"` (dùng `window.LanguageID || "VN"`) để hỗ trợ lọc đa ngôn ngữ.
4. **Sử dụng push động khi cần**:
   * Bạn có thể khởi tạo mảng `param` rỗng và `push()` các giá trị động tùy thuộc vào các bộ lọc (Filters) trên giao diện.

---

## 3. Cấu trúc dữ liệu phản hồi (Response Structure)

Mỗi lệnh `SELECT` thực thi thành công trong Stored Procedure ở Backend sẽ được hệ thống gom nhóm lại thành một mảng các bảng dữ liệu trong thuộc tính `.data` của JSON trả về.

```
Response JSON:
{
    "data": [
        [ { "Col1": "Val1" }, { "Col1": "Val2" } ],   // json.data[0]: Bảng SELECT thứ 1
        [ { "TotalCount": 150 } ]                    // json.data[1]: Bảng SELECT thứ 2
    ]
}
```

* **`json.data[0]`**: Luôn là kết quả của câu lệnh `SELECT` đầu tiên (chứa dữ liệu danh sách/bản ghi chính).
* **`json.data[1]`**: Kết quả của câu lệnh `SELECT` thứ hai (thường dùng để trả về `TotalCount` cho Grid phân trang).
* **`json.data[2]`**: Kết quả của câu lệnh `SELECT` thứ ba (thường dùng để trả về thông tin tổng hợp/Summary).

---

## 4. Tải file hoặc ảnh qua API

Khi cần tải file vật lý, tài liệu hoặc hình ảnh từ server thông qua procedure api, sử dụng API đặc thù `paradisefile_sp_GetFileAPI` kết hợp cấu hình `xhrFields`.

```javascript
AjaxHPAParadise({
    data: {
        name: "paradisefile_sp_GetFileAPI",
        param: [
            "LoginID", window.UserID || window.LoginID,
            "FileID", fileId,
            "TableName", "tblEmployee"
        ]
    },
    xhrFields: { 
        responseType: "blob" // Quan trọng: Yêu cầu trả về định dạng binary Blob
    },
    success: function (blob) {
        if (blob) {
            // Chuyển đổi blob thành đường dẫn URL tạm thời để hiển thị lên thẻ img.src
            const imageUrl = URL.createObjectURL(blob);
            $("#employeeAvatar").attr("src", imageUrl);
        }
    },
    error: function () {
        console.error("Lỗi tải ảnh đại diện nhân viên.");
    }
});
```

---

## 5. Lỗi thường gặp và cách xử lý (Troubleshooting)

| Triệu chứng lỗi | Nguyên nhân phổ biến | Cách khắc phục |
|---|---|---|
| Lỗi cú pháp Javascript tại thuộc tính `name` | Lỗi viết shorthand sai hoặc thiếu giá trị gán, ví dụ: `name: "", procedureName` | Đảm bảo thuộc tính `name` được gán trực tiếp: `name: procedureName` hoặc `name: "sp_ExampleList"`. |
| API trả về lỗi HTTP 500 | Truyền tham số `param` dạng Object `{}` thay vì mảng phẳng `[]` | Sửa cấu trúc `param` thành mảng: `["ParamName", value]`. |
| Dữ liệu hiển thị trống dù DB có bản ghi | 1. Quên giải mã bằng hàm `EncryptionStringDecryption`<br>2. Thiếu tham số bắt buộc `LoginID` hoặc `LanguageID` | 1. Thêm khối kiểm tra giải mã trước khi parse JSON.<br>2. Kiểm tra log Network xem payload gửi lên đã đủ tham số chưa. |
| JS lỗi `IsNullOrEmpty is not defined` hoặc `EncryptionStringDecryption is not defined` | Các hàm toàn cục (global helpers) của hệ thống chưa được nạp | Đảm bảo đoạn script gọi API chạy sau khi trang đã tải hoàn tất các thư viện tiện ích chung. |
