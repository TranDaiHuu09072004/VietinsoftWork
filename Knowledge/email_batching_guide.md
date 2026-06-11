# Hướng Dẫn Tái Sử Dụng Cơ Chế Gửi Email Theo Batch (Microsoft Graph API)

Tài liệu này hướng dẫn cách áp dụng cơ chế gửi email theo lô (batching) sử dụng Microsoft Graph API thông qua thủ tục `sp_EmailSendingByDuc`. Cơ chế này cho phép gửi tối đa 20 email riêng biệt (nội dung, tiêu đề, người nhận khác nhau) trong một lần gọi API duy nhất, giúp tối ưu hiệu suất và tốc độ cho hệ thống.

## 1. Luồng Hoạt Động Cốt Lõi

1. **Client (JavaScript)**: Gom danh sách người nhận thành các mảng (chunks), mỗi chunk tối đa 20 người. Tạo một mảng đối tượng JSON (chứa thông tin email) và truyền chuỗi JSON đó xuống server.
2. **Server (SQL)**: Stored Procedure nhận tham số chuỗi JSON (`@BatchJson`), tự động parse và dựng thành cấu trúc payload `$batch` chuẩn của Microsoft Graph API.
3. **Graph API**: Thực thi các yêu cầu gửi email và trả về kết quả chi tiết cho từng email (Thành công/Thất bại).
4. **Server (SQL)**: Đọc kết quả, tự động ghi log vào bảng `tblEmailList`, và trả danh sách kết quả về cho Client.
5. **Client (JavaScript)**: Nhận kết quả và hiển thị thông báo/modal cho người dùng, hỗ trợ chức năng "Thử gửi lại" cho các email lỗi.

---

## 2. Cách Tái Sử Dụng Ở Phía Client (JavaScript)

Để gọi tính năng này từ bất kỳ form nào (ví dụ: `tasklist.sql` hoặc form quản lý khác), bạn cần chuẩn bị mảng dữ liệu cấu hình theo đúng chuẩn sau:

### Cấu trúc JSON cho mỗi Email:

```javascript
let batchJsonArray = [];

// Thêm các email cần gửi vào mảng
batchJsonArray.push({
  TemplateName: "Ten_Mau_Email_Cua_Ban", // Tên template để lưu log
  EmployeeID: "Ma_Nhan_Vien", // Dùng để lưu log (nếu có)
  ToEmails: "nguoinhan@domain.com", // Email người nhận (có thể nhiều email cách nhau bằng dấu chấm phẩy ;)
  CcEmails: "cc@domain.com", // Email CC (tuỳ chọn)
  BccEmails: "bcc@domain.com", // Email BCC (tuỳ chọn)
  Subject: "Tiêu đề email", // Tiêu đề
  BodyContent: "Nội dung HTML hoặc Base64", // Nội dung chính
  IsBase64: 0, // 1 nếu BodyContent đã mã hoá Base64, 0 nếu truyền HTML thô
});
```

### Hàm gọi API bằng thư viện `AjaxHPAParadise` (hoặc tương đương):

```javascript
// Chuyển mảng thành chuỗi JSON
const batchJsonString = JSON.stringify(batchJsonArray);

// Gọi API
AjaxHPAParadise({
  data: {
    sp_EmailSendingByDuc: [
      "LanguageID",
      "VN",
      "BatchJson",
      batchJsonString, // Truyền cục JSON vào tham số BatchJson
    ],
  },
  success: function (res) {
    // res trả về mảng kết quả của từng email.
    // Cấu trúc trả về: { Id: "1", Result: 1, ErrorMessage: "Success" }
    // Result = 1 là thành công, 0 là thất bại.
    // Id tương ứng với thứ tự (index + 1) trong mảng truyền lên.

    let parseRes = typeof res === "string" ? JSON.parse(res) : res;
    const resultRows = parseRes.sp_EmailSendingByDuc || [];

    resultRows.forEach((row) => {
      if (row.Result == 1) {
        console.log(`Email ID ${row.Id} gửi THÀNH CÔNG.`);
      } else {
        console.error(`Email ID ${row.Id} gửi THẤT BẠI: ${row.ErrorMessage}`);
      }
    });
  },
});
```

> **Mẹo:** Graph API giới hạn **tối đa 20 requests** trong một batch. Nếu bạn có danh sách 100 người, hãy sử dụng vòng lặp để chia nhỏ mảng gốc (slice) thành các chunk 20 phần tử rồi gửi lần lượt.

---

## 3. Cấu Trúc Xử Lý Phía CSDL (SQL Server)

Thủ tục `sp_EmailSendingByDuc` đã được nâng cấp để tự động xử lý khi nhận được tham số `@BatchJson`.

### Nguyên lý xử lý tự động trong Procedure:

1. **Kiểm tra tham số**: Nếu `@BatchJson` có dữ liệu, luồng Batch sẽ được kích hoạt (bỏ qua luồng gửi email đơn lẻ cũ).
2. **Bóc tách JSON**: Sử dụng `OPENJSON(@BatchJson)` để đọc từng dòng dữ liệu mà Client truyền lên.
3. **Build `$batch` Payload**: Dùng vòng lặp Cursor hoặc FOR JSON để ghép dữ liệu thành chuỗi cấu trúc `$batch` chuẩn của Microsoft (Gồm các block `id`, `method`, `url`, `headers`, `body`).
4. **Gọi API**: Dùng `ss_RequestHttp` gọi đúng 1 lần lên URL: `https://graph.microsoft.com/v1.0/$batch`.
5. **Ghi Log Tự Động**:
   Kết quả trả về được Parse. Những dòng HTTP 200 (Thành công) hoặc lỗi sẽ tự động được `INSERT INTO tblEmailList` để phục vụ tracking lịch sử (Dựa vào `TemplateName` và `EmployeeID` truyền lên).
6. **Trả kết quả**: Trả về một Result Set chứa `Id`, `Result`, và `ErrorMessage` cho Client.

> **Lưu ý:** Nếu các module cũ vẫn gọi `sp_EmailSendingByDuc` theo cách truyền từng tham số truyền thống (`@ToEmails`, `@Subject`, `@BodyContent`), Procedure vẫn sẽ xử lý bình thường (1 request/lần) mà không bị lỗi (Tương thích ngược).

---

## 4. Gợi Ý: Xử Lý Logic "Thử Gửi Lại" Email Lỗi

Trong trường hợp muốn tái tạo nút **"Thử gửi lại email lỗi"**, bạn có thể thiết kế một hàm đệ quy (recursive) ở Client như sau:

```javascript
async function processEmailBatch(emailsBatch) {
  const CHUNK_SIZE = 20;
  let allResults = [];

  // Xử lý gửi từng chunk 20 mail
  for (let i = 0; i < emailsBatch.length; i += CHUNK_SIZE) {
    const chunkItems = emailsBatch.slice(i, i + CHUNK_SIZE);
    const chunkResults = await sendEmailChunkPromise(chunkItems); // Hàm bọc Promise gọi AjaxHPAParadise
    allResults.push(...chunkResults);
  }

  // Phân tích kết quả
  const failedItems = allResults.filter((r) => !r.success).map((r) => r.item);

  // Nếu có lỗi, hiển thị nút thử lại
  if (failedItems.length > 0) {
    // ... (Hiển thị UI báo lỗi) ...
    document.getElementById("btnRetry").onclick = function () {
      // Đệ quy: Tự động chạy lại hàm này với chỉ các item bị lỗi
      processEmailBatch(failedItems);
    };
  }
}
```
