# 29 — Zalo Web (chat.zalo.me) — Kiến trúc Realtime Messaging & Lưu trữ Local

> Tổng hợp kiến thức kiến trúc hệ thống Zalo Web (`chat.zalo.me`) phía client (khám phá ngày 2026-06-03). Dùng làm tài liệu tham khảo cho các mô hình realtime và offline storage.

---

## 1. Tổng quan kiến trúc

Zalo Web sử dụng **kiến trúc lai (Hybrid)** kết hợp realtime WebSocket, Web Workers để chạy ngầm và IndexedDB để lưu trữ dữ liệu lớn:

* **Realtime Connection**: Kết nối WebSocket tới `rt-wpa.chat.zalo.me` hoặc `chatgw.zalo.me`.
* **Background Threading**: Chia nhỏ 7 Web Workers để xử lý độc lập, giao tiếp qua `MessageChannel` API (point-to-point).
* **Storage Layer**: 19 database IndexedDB cục bộ trong trình duyệt và `Origin Private File System (OPFS)` cho tệp tin nhị phân lớn.

---

## 2. 7 Web Workers chạy nền

| Worker | Vai trò chính | File |
|---|---|---|
| **`mainless-worker`** | Điều phối chính, quản lý vòng đời tin nhắn | `mainless-worker.*.js` |
| **`soc-worker`** ⭐ | **Socket Worker** — Giữ kết nối WebSocket realtime | `soc-worker.*.js` |
| **`zd-worker`** | Xử lý đồng bộ dữ liệu, encode/decode | `zd-worker.*.js` |
| **`dal-worker`** | Data Access Layer — Đọc/ghi IndexedDB | `dal-worker.*.js` |
| **`trust-worker`** | Quản lý xác thực thiết bị đáng tin cậy (Trusted Device) | `trust-worker.*.js` |
| **`opfs-worker`** | Quản lý Origin Private File System | `opfs-worker.*.js` |
| *Signal Protocol* | Thư viện mã hóa/giải mã E2EE | `libsignal-protocol.static.js` |

---

## 3. Realtime Socket Tracking (`localStorage` keys)

Zalo Web dùng `localStorage` để theo dõi tiến trình nhận tin nhắn realtime:

### 3.1. Key `0_sock_msg` (Action ID của socket)
Lưu `actionId` tăng dần theo thời gian:
* `510_x`: **Tin nhắn mới / Message Push** từ server xuống.
* `511_x`: **Trạng thái tin nhắn** (Delivered/Seen ACK).
* `515_x`: **Control message** (Heartbeat / ping-pong).
* `517_x`: **System event** (Group join, friend request).
*(Hậu tố `_0` thường là mobile/primary device, `_1` là web client)*.

### 3.2. Định dạng ID tin nhắn (`0_lsmsg` - Last Socket Message)
* **Tin nhắn nhóm (Group)**: `g[Group_ID]-[ActionId]-[Timestamp]` (Ví dụ: `g3743018450-789604024-1780469269`).
* **Tin nhắn 1-1**: `[Message_Global_ID]-[ActionId]-[Timestamp]` (Không có chữ `g` ở đầu).

---

## 4. Cơ chế dự phòng (Fallback) - HTTP Polling
Khi WebSocket bị ngắt, client tự động fallback sang polling định kỳ qua API (Domain `tt-convers-wpa.chat.zalo.me`):
* `/api/preloadconvers/get-last-msgs`: Lấy tin nhắn cuối cùng khi kết nối lại.
* `/api/conv/getUnreadMark`: Check tin nhắn chưa đọc.
* `/api/hiddenconvers/get-all`: Lấy danh sách hội thoại bị ẩn.

---

## 5. Mã hóa End-to-End (E2EE)
Zalo Web sử dụng thư viện **Signal Protocol** (`libsignal-protocol.static.js`) để mã hóa tin nhắn. Nội dung tin nhắn lưu tại IndexedDB là chuỗi cipher text đã mã hóa.
* **Stores khóa học**: `e2ee_identity` (khóa thiết bị), `e2ee_session` (phiên 1-1 active), `e2ee_prekey`, `e2ee_signed_prekey`, `e2ee_group` (khóa nhóm).

---

## 6. Hệ thống IndexedDB (19 Databases)

Zalo Web chia dữ liệu thành các database riêng biệt, có hậu tố là User ID (Ví dụ: `zdb_2303003661207`).

### 6.1. Các database chính (Xác minh CDP)
1. **`zdb_`**: Kho dữ liệu chính (44 stores) - tin nhắn, bạn bè, nhóm, sticker, todo...
2. **`msginfo_`**: Cấu hình trạng thái tin nhắn (đã đọc/nhận, unread, quote...).
3. **`e2ee_`**: Lưu khóa mã hóa Signal Protocol.
4. **`media_`**: Lưu cache hình ảnh, link, tệp tin.
5. **`r_db_`**: Lưu reaction và emoji động.
6. **`sidx_`**: Cơ sở dữ liệu tìm kiếm (Keyword index cục bộ).
7. **`sync_`**: Lưu các khoảng tin nhắn bị thiếu để đồng bộ lại (`missing_message_range`).

### 6.2. Schema Object Store `message` (Database `zdb_`)
* **KeyPath**: `msgId` (string).
* **Indexes**: `cliMsgIdIndex`, `msgType_sendDttm`, `status_sendDttm`, `userId_msgType_sendDttm`.
* **Cột quan trọng**:
  * `msgId`: ID tin nhắn toàn cục do server sinh.
  * `cliMsgId`: ID tin nhắn do client sinh (thường là timestamp ms lúc gửi).
  * `msgType`: Kiểu tin nhắn (1: Text, 2: Photo, 6: Link/Sticker).
  * `status`: Trạng thái (1: Sent, 2: Delivered, 3: Seen).
  * `message`: Chuỗi nội dung **đã mã hóa E2EE**.
  * `fromUid` / `toUid`: ID người gửi và người nhận/nhóm.
  * `actionId`: ID tương ứng trong luồng socket.

### 6.3. Cơ chế tìm kiếm cục bộ (Database `sidx_`)
Zalo index tin nhắn ngay dưới client:
1. Giải mã tin nhắn mới $\rightarrow$ Tách từ khóa và ghi vào `stkw` (Keyword Table).
2. Tạo inverted index trong `stidx` (`keywordId` $\rightarrow$ `msgId list`).
3. Lưu nội dung text thô đã giải mã vào `stcont` để phục vụ tìm kiếm nhanh không cần gọi API Server.

---

## 7. Quy trình gửi tin nhắn (Optimistic UI)

Để đảm bảo trải nghiệm mượt mà, Zalo sử dụng pattern **Optimistic UI**:

```
[User nhấn Enter]
       │
       ├─► [UI Client]: Vẽ tin nhắn lập tức (Trạng thái: Đang gửi...)
       ├─► [IndexedDB]: Ghi local trước (status = 1, e2eeStatus = -1)
       └─► [soc-worker]: Đẩy socket payload (cmd=521 cho 1-1, cmd=501 cho Group) lên gateway
                 │
                 ├─► Nhận ACK từ server ──► Cập nhật status = 1 (Sent ✓)
                 ├─► Người nhận đã tải  ──► Cập nhật status = 2 (Delivered ✓✓)
                 └─► Người nhận đã đọc  ──► Cập nhật status = 3 (Seen ✓✓ Xanh)
```

Đối với tin nhắn hình ảnh, client sẽ POST ảnh nhị phân lên CDN trước để lấy `photoId`, sau đó mới gửi tin nhắn chứa `photoId` qua WebSocket.

---

## 8. Thực nghiệm DevTools Protocol (CDP)
Thông tin cấu hình được kiểm chứng trực tiếp bằng cách khởi chạy trình duyệt Edge bật Remote Debugging trên cổng `9222`, sử dụng `Runtime.evaluate` và `IndexedDB.requestDatabase` để dump schema dữ liệu trực tiếp trong phiên làm việc thực tế.
* **Dữ liệu snapshot thực tế**: Ghi nhận 659 tin nhắn, 58 cuộc hội thoại, 100% tin nhắn kích hoạt E2EE (`e2eeStatus = -1`) và WebSocket kết nối ổn định.
