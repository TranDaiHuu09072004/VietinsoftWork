# So sánh: ParadiseHR (`sp_CallAPIZalo`) vs Zalo Web Official (`chat.zalo.me`)

> Phân tích kỹ thuật so sánh giải pháp gửi tin Zalo Client qua API của ParadiseHR so với kiến trúc của Zalo Web Official.
> Liên quan: [28_Zalo_Integration.md](28_Zalo_Integration.md) (ParadiseHR Zalo) · [29_zalo_web_Official.md](29_zalo_web_Official.md) (Zalo Web).

---

## 1. Bảng so sánh tổng quan kiến trúc

| Đặc điểm | ParadiseHR Zalo API | Zalo Web Official | Đánh giá |
|---|---|---|---|
| **Nơi vận hành** | SQL Server (Server-side) | Trình duyệt Web (Client-side) | Trực tiếp trên DB server vs End-user client |
| **Giao thức kết nối** | HTTP REST API (`/api/message/sms`) | WebSocket realtime (`rt-wpa.chat.zalo.me`) | REST API giả lập client vs Kết nối song song realtime |
| **Mã hóa nội dung** | **Không có (Plaintext)** | **E2EE Signal Protocol** | ⚠️ Rủi ro bảo mật & dễ bị Zalo block tài khoản |
| **Mã hóa tham số** | AES encode (`ss_EncodeDecodeAESwithSecretKey`) | Client-side AES | Tương đương về cơ chế ẩn thông số request |
| **Xác thực (Auth)** | Cookie + JSON `tblZalo_User.LoginInfo` | Cookie + IndexedDB Tokens | Tương đương về mặt lấy session qua QR code |
| **Realtime ACK** | ❌ Không (gửi đi là xong) | ✅ Có (Cập nhật status 1 $\rightarrow$ 2 $\rightarrow$ 3) | ParadiseHR không thể check tin nhắn đã đọc |
| **Hỗ trợ Gửi ảnh** | ✅ Có (Upload qua OLE Stream) | ✅ Có (Upload qua browser fetch) | Cả hai đều qua API endpoint `/photo_original/send` |
| **Khả năng Retry/Offline** | ❌ Không | ✅ Lưu cache trong IndexedDB và gửi lại | ParadiseHR lỗi mạng sẽ drop tin nhắn |

---

## 2. Điểm khác biệt về nghiệp vụ gửi tin nhắn

### 2.1. Mã hóa E2EE và plain text
* **ParadiseHR**: Gửi thẳng tin nhắn văn bản dạng thô (`@MessageSend = N'Nội dung'`) lên cổng API của Zalo.
* **Zalo Web**: Tải khóa từ `e2ee_session`, mã hóa nội dung bằng Signal Protocol trước khi gửi payload qua socket.
* *Hệ quả*: Việc ParadiseHR gửi plaintext trên API Client khiến Zalo dễ dàng phát hiện hành vi tự động hóa và có nguy cơ bị khóa tài khoản cao.

### 2.2. OLE Automation trên SQL Server
* ParadiseHR khởi tạo các đối tượng COM `MSXML2.ServerXMLHTTP.6.0` và `ADODB.Stream` trực tiếp bằng stored procedure SQL Server để gửi file/ảnh dạng nhị phân.
* Cơ chế này đòi hỏi phải kích hoạt `Ole Automation Procedures` và dễ gây rò rỉ bộ nhớ (memory leak) trên DB Server nếu không giải phóng đối tượng đúng cách.

---

## 3. Các Endpoint được ParadiseHR giả lập (Từ `tblZaloClientFunction`)

* **Tin nhắn 1-1**: `tt-chat1-wpa.chat.zalo.me/api/message/sms` (POST)
* **Tin nhắn nhóm**: `tt-group-wpa.chat.zalo.me/api/group/sendmsg` (POST)
* **Upload/Gửi ảnh**: `tt-files-wpa.chat.zalo.me/api/message/photo_original/upload` (POST)
* **Đồng bộ danh bạ**: `tt-profile-wpa.chat.zalo.me/api/social/friend/getfriends` (GET)
* **Đồng bộ nhóm**: `tt-group-wpa.chat.zalo.me/api/group/getlg/v4` (GET)
