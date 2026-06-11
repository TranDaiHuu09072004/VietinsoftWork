# 28 — Tích hợp Zalo (Cơ chế gửi tin nhắn Zalo qua T-SQL)

> Tài liệu tổng hợp kiến thức về hệ thống tích hợp Zalo trong ParadiseHR: các bảng lưu trữ, thủ tục gửi tin nhắn (cá nhân/nhóm), cơ chế gửi ảnh nhị phân và các tiến trình background service gửi tin nhắn Zalo Official Account (OA).
>
> Liên quan: [02_db_employee.md](02_db_employee.md) (hồ sơ nhân viên), [09_workflow_payroll.md](09_workflow_payroll.md) (gửi phiếu lương), [05_db_attendance.md](05_db_attendance.md) (gửi giờ công chấm công).

---

## 1. Hai cơ chế gửi tin nhắn Zalo trong ParadiseHR

Hệ thống hỗ trợ 2 cơ chế độc lập tùy theo nghiệp vụ và loại tài khoản gửi:

| Cơ chế | Tài khoản gửi | Thủ tục chính | Đặc điểm & Cách hoạt động |
|---|---|---|---|
| **Đồng bộ qua Zalo Client API** | Tài khoản Zalo cá nhân | `sp_CallAPIZalo` | Gửi trực tiếp, đồng bộ từ T-SQL qua OLE Automation tới API Client Zalo. Thường dùng trong chat trực tiếp, gửi tin nhắn tự động từ tài khoản nhân viên kinh doanh. |
| **Bất đồng bộ qua Zalo OA** | Zalo Official Account (Doanh nghiệp) | `sp_ZaloSendSMSPaySlip...` / `sp_ZaloSendSMSFor...` | Trả về tập dữ liệu (User ID + Message) từ procedure. Một **Background Service (C#)** định kỳ quét kết quả này và gọi Zalo OA API để gửi. |

---

## 2. Hệ thống bảng cơ sở dữ liệu (Tables)

Các bảng dữ liệu chính phục vụ tính năng tích hợp Zalo (liên kết về `LoginID` hoặc `EmployeeID`):

| Tên bảng | Vai trò | Các cột quan trọng |
|---|---|---|
| `tblZalo_User` | Lưu cấu hình đăng nhập Zalo cá nhân theo từng tài khoản hệ thống. | `LoginID` (PK), `LoginName`, `LoginInfo` (JSON chứa Cookies, IMEI, UserAgent, SecretKey...), `level` (1=Active). |
| `tblZaloClientFriends` | Danh sách bạn bè Zalo cá nhân đồng bộ về. | `LoginID` (PK), `userId` (PK - Zalo User ID), `displayName` (Tên Zalo), `phoneNumber`, `lastActionTime`. |
| `tblZaloClientGroups` | Danh sách các nhóm chat Zalo mà tài khoản cá nhân tham gia. | `LoginID` (PK), `groupId` (PK), `groupName`, `memVerList` (JSON danh sách thành viên), `lastActionTime`. |
| `tblZaloFollowerInfo` | Lưu thông tin người theo dõi (Follower) trang Zalo Official Account (OA) của doanh nghiệp. | `EmployeeID` (mã nhân viên liên kết), `user_id` (Zalo OA ID người dùng), `display_name`, `name_Shared`, `LastSendSMS`. |
| `tblZaloMessage` | Nhật ký đồng bộ lịch sử tin nhắn Zalo cá nhân. | `LoginID`, `fromID`, `toID`, `message` (nội dung text), `imgURL` (URL ảnh trên CDN Zalo), `msgType` (loại tin: `chat.photo`...), `timeSend`. |
| `tblZaloClientFunction` | Danh mục khai báo API endpoints, phương thức và template tham số gọi Zalo Client. | `FunctionName` (sendMessage, sendPhoto, getAllFriends...), `FunctionUrl`, `Method`, `Parameter`, `DataEncode`. |

---

## 3. Gửi tin nhắn cá nhân/nhóm qua `sp_CallAPIZalo` (Đồng bộ)

Thủ tục `sp_CallAPIZalo` đóng gói toàn bộ logic gọi API Zalo Client từ SQL Server thông qua thủ tục HTTP helper `ss_RequestHttp_Zalo` và OLE Automation.

### 3.1. Cú pháp gửi tin nhắn văn bản (Text)
* **Gửi cho cá nhân (Friend)**:
  ```sql
  EXEC dbo.sp_CallAPIZalo 
      @CallFunction = 'sendMessage',
      @LoginID = @LoginID,            -- ID tài khoản gửi (tblZalo_User)
      @UserIdSend = @ZaloUserID,      -- Zalo User ID nhận (tblZaloClientFriends.userId)
      @MessageSend = N'Nội dung tin nhắn bằng tiếng Việt có dấu';
  ```
* **Gửi vào nhóm (Group)**:
  ```sql
  EXEC dbo.sp_CallAPIZalo 
      @CallFunction = 'sendGroupMessage',
      @LoginID = @LoginID,
      @UserIdSend = @ZaloGroupID,     -- Zalo Group ID nhận (tblZaloClientGroups.groupId)
      @MessageSend = N'Nội dung tin nhắn nhóm';
  ```

### 3.2. Cú pháp gửi tin nhắn hình ảnh (Photo)
Khi gửi ảnh, đường dẫn tệp tin trên máy chủ server cần được truyền vào tham số `@MessageSendPath` dưới dạng chuỗi JSON chứa thuộc tính `path`, `width`, và `height`.

```sql
EXEC dbo.sp_CallAPIZalo 
    @CallFunction = 'sendPhoto', -- Hoặc 'sendGroupPhoto' nếu gửi nhóm
    @LoginID = 62,
    @UserIdSend = '4172804304489894804',
    @MessageSend = N'Chú thích ảnh đi kèm (caption)',
    @MessageSendPath = N'{"path":"C:\\inetpub\\wwwroot\\App_Data\\temp\\image.jpg","width":800,"height":600}';
```

### 3.3. Quy trình 5 bước xử lý gửi ảnh nhị phân dưới nền
Thủ tục `sp_CallAPIZalo` thực hiện quy trình phức tạp sau để gửi ảnh mà không thông qua Client ngoài:
1. **Đọc tệp tin**: Gọi API nội bộ của Paradise Service qua `ss_RequestHttp` để đọc ảnh từ đường dẫn vật lý trên server và trả về dữ liệu dạng Base64.
2. **Convert & Stream nhị phân**: Convert chuỗi Base64 thành dữ liệu nhị phân (`varbinary(max)`) và nạp vào đối tượng bộ nhớ `ADODB.Stream` thông qua OLE Automation.
3. **Upload Multipart**: Sử dụng đối tượng `MSXML2.ServerXMLHTTP.6.0` để post dữ liệu nhị phân dưới dạng `multipart/form-data` trực tiếp lên máy chủ upload của Zalo.
4. **Nhận Metadata**: Zalo trả về response chứa các thông tin mã hóa gồm: `photoId`, `normalUrl`, `hdUrl`, `thumbUrl`.
5. **Gửi tin nhắn ảnh**: Thủ tục giải mã response, trích xuất metadata và gọi API `sendPhoto` chuyển tiếp tin nhắn hình ảnh đến khách hàng.

---

## 4. Gửi tin nhắn bất đồng bộ qua Zalo OA (Doanh nghiệp)

Được áp dụng cho các tin nhắn tự động từ hệ thống. Các stored procedure đóng vai trò tổng hợp dữ liệu và trả ra hàng đợi (Queue) kết quả, để Background Service (C#) xử lý.

### 4.1. Ví dụ gửi phiếu lương: `sp_ZaloSendSMSPaySlipForEmployeeID`
Thủ tục này tính toán thông tin phiếu lương của nhân viên từ bảng `tblSal_Sal`, map với Zalo OA ID từ bảng `tblZaloFollowerInfo` và trả về kết quả cấu trúc để service gửi:
```sql
-- Đoạn mã trả về cho Background Service quét
SELECT 
    'ZaloSendSMSToFollower' AS FunctionName, 
    'HPA.Service.Common.ZaloOfficalAcount' AS ClassName, 
    z.user_id AS Param1,            -- Zalo OA ID người nhận
    N'Xin chào ! ' + te.FullName + N'\nPhiếu lương tháng...\nThực lãnh: ' + CAST(ss.ThucLanh AS varchar) AS Param2 -- Nội dung tin nhắn
FROM tblSal_Sal ss
INNER JOIN tblEmployee te ON te.EmployeeID = ss.EmployeeID
INNER JOIN tblZaloFollowerInfo z ON ss.EmployeeID = z.EmployeeID
WHERE ss.EmployeeID = @EmployeeID;
```

### 4.2. Ví dụ gửi tin nhắn báo công: `sp_ZaloSendSMSForRemainFollower`
Tự động lấy dữ liệu chấm công từ bảng tạm chấm công `tblTmpAttend` và thiết bị chấm công `Machines` để gửi tin nhắn thông báo giờ check-in/check-out cho nhân viên vào cuối ngày:
```sql
SELECT 
    z.user_id,
    N'Xin chào! ' + ISNULL(z.name_Shared, z.display_name) +
    N'\nBạn đã thực hiện chấm công lúc: ' + CONVERT(varchar(19), att.AttTime, 121) +
    N'\nMã chấm công: ' + u.BADGENUMBER +
    N'\nTại địa điểm: ' + m.MachineAlias AS zaloMessage
FROM USERINFO u 
INNER JOIN tblZaloFollowerInfo z ON u.SSN = z.EmployeeID
INNER JOIN tblTmpAttend att ON z.EmployeeID = att.EmployeeID
INNER JOIN Machines m ON att.sn = m.sn AND m.MachineNumber = ISNULL(att.MachineNo, 1)
WHERE DATEDIFF(hh, z.LastSendSMS, att.AttTime) > 10;
```

---

## 5. Các lỗi thường gặp (Troubleshooting)

| Triệu chứng | Nguyên nhân | Hướng xử lý |
|---|---|---|
| `sp_CallAPIZalo` trả về trạng thái `haveLogout` | Tài khoản cá nhân tại LoginID chưa đăng nhập hoặc cookie bị hết hạn. | Thực hiện quét mã QR Zalo trên Portal để làm mới login session và cập nhật cột `LoginInfo` của bảng `tblZalo_User`. |
| Gửi ảnh bị lỗi `ADODB Write FAILED` | Lỗi xảy ra khi convert dữ liệu Base64 sang nhị phân hoặc không thể khởi tạo OLE objects trên SQL Server. | Kiểm tra xem SQL Server đã được cấu hình cho phép OLE Automation chưa: `sp_configure 'Ole Automation Procedures', 1`. |
| Tin nhắn gửi đi thành công nhưng khách hàng không nhận được ảnh | Kích thước ảnh truyền vào JSON `@MessageSendPath` không đúng (width/height = 0 hoặc null). | Đảm bảo điền đúng chiều rộng và chiều cao thực tế của ảnh trong chuỗi JSON. |

---

## 6. Menu Danh bạ Zalo (Giao diện 2 cột Web)

Hệ thống cung cấp menu **Danh bạ Zalo** (`MnuHRS503`) hiển thị dưới nhánh menu **Nhân sự** (`MnuHRS000`), cho phép quản trị viên và các User được phân quyền tra cứu trực quan danh sách bạn bè và nhóm chat của các tài khoản Zalo cá nhân.

### 6.1. Kiến trúc & Các Procedure liên quan
- **Wrapper Procedure**: `sp_ZaloContactBook` (đọc cache HTML).
- **Renderer Procedure**: `sp_ZaloContactBook_html` (sinh HTML/CSS/JS thuần theo layout Zalo Web).
- **API Procedure**: `sp_ZaloContactBook_GetData` (cung cấp dữ liệu động).

### 6.2. Cú pháp gọi API dữ liệu
Thủ tục `sp_ZaloContactBook_GetData` hỗ trợ các Action sau:
* **Lấy danh sách tài khoản Zalo cá nhân hoạt động**:
  ```sql
  EXEC dbo.sp_ZaloContactBook_GetData @Action = 'GET_ZALO_USERS';
  ```
* **Lấy danh sách bạn bè của một tài khoản Zalo**:
  ```sql
  EXEC dbo.sp_ZaloContactBook_GetData @Action = 'GET_FRIENDS', @ZaloLoginID = 23;
  ```
* **Lấy danh sách nhóm chat của một tài khoản Zalo**:
  ```sql
  EXEC dbo.sp_ZaloContactBook_GetData @Action = 'GET_GROUPS', @ZaloLoginID = 23;
  ```
* **Lấy chi tiết thành viên của một nhóm Zalo**:
  ```sql
  EXEC dbo.sp_ZaloContactBook_GetData @Action = 'GET_GROUP_MEMBERS', @ZaloLoginID = 23, @GroupId = '8158996882542150263';
  ```

### 6.3. Chi tiết giao diện & Tương thích
- **Thiết kế**: Sử dụng layout 2 cột (sidebar bên trái hiển thị danh bạ phân tab Bạn bè/Nhóm và ô tìm kiếm; nội dung bên phải hiển thị chi tiết liên hệ/nhóm và danh sách thành viên).
- **Quy chuẩn Style**: Thiết kế theo chuẩn **Paradise Style** (sử dụng các token màu hệ thống `var(--paradise-*)`), không sử dụng các control HPA Paradise, hỗ trợ tương thích Dark Mode toàn cục.
