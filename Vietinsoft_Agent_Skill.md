# Quy tắc bắt buộc dành cho Agent khi làm việc với dự án Vietinsoft (Vietinsoft Agent Skill)

**MỤC ĐÍCH:** Đảm bảo Agent (Antigravity/AI) luôn có đủ kiến thức chính xác trước khi trả lời câu hỏi hoặc thực hiện bất kỳ công việc nào trong dự án, tránh tuyệt đối việc tự suy đoán sai lệch.

**HƯỚNG DẪN THỰC THI DÀNH CHO AGENT (AGENT INSTRUCTIONS):**

Khi bắt đầu một session mới hoặc khi nhận được một yêu cầu liên quan đến logic, nghiệp vụ, hoặc cấu trúc của dự án, bạn (Agent) PHẢI tuân thủ nghiêm ngặt quy trình các bước sau đây:

### Bước 1: Kiểm tra trạng thái nạp kiến thức
- Nếu bạn đã đọc và nạp các kiến thức tổng quan của dự án trong phiên làm việc (session) hiện tại rồi thì bỏ qua Bước 2.
- Nếu chưa, BẮT BUỘC phải thực hiện Bước 2.

### Bước 2: Truy vấn thông tin trong file `README.md`
- Bạn phải ưu tiên dùng công cụ `view_file` hoặc `grep_search` để đọc và tìm kiếm thông tin nghiệp vụ/kỹ thuật cần thiết bên trong file `README.md` (nằm ở thư mục gốc của dự án).
- File `README.md` là nguồn kiến thức cốt lõi đầu tiên của dự án.

### Bước 3: Đánh giá thông tin và Khám phá qua Database
- Nếu thông tin trong file `README.md` ĐÃ ĐỦ để giải quyết yêu cầu: Tiến hành xử lý công việc.
- Nếu thông tin trong file `README.md` CHƯA ĐỦ hoặc không đề cập chi tiết: 
  - BẮT BUỘC phải sử dụng công cụ truy vấn Database (MCP `sql-server-vietinsoft`) để tìm hiểu, khám phá bảng (tables), views, cấu trúc hoặc các stored procedures liên quan.
  - Sử dụng các lệnh như `mcp_sql-server-vietinsoft_execute_query` để đọc mã nguồn SQL thực tế của hệ thống.

### Bước 4: Cập nhật kiến thức mới vào `README.md` (Self-Learning)
- Sau khi khám phá cơ sở dữ liệu và xác minh được các logic/quy tắc nghiệp vụ mới mà trước đó trong file `README.md` chưa có, bạn BẮT BUỘC phải cập nhật (ghi thêm) những kiến thức quan trọng đó vào file `README.md`.
- Mục đích: Lưu trữ lại kiến thức để các lần làm việc sau có thể sử dụng mà không cần truy vấn lại Database.

### ⚠️ QUY TẮC TỐI QUAN TRỌNG (CRITICAL RULES) ⚠️
1. **TUYỆT ĐỐI KHÔNG ĐƯỢC TỰ SUY ĐOÁN:** Không bao giờ được tự động giả định cấu trúc bảng, tên trường, hay quy tắc tính toán của nghiệp vụ.
2. **KHÔNG ĐƯA RA KẾT LUẬN VỘI VÃ:** Mọi câu trả lời hay kết luận đều phải có **chứng cứ xác thực** (concrete evidence) được trích xuất từ file tài liệu của dự án hoặc từ kết quả query trực tiếp trong hệ thống database MCP.
3. Nếu không tìm thấy thông tin xác thực từ cả tài liệu lẫn cơ sở dữ liệu, phải báo cáo lại cho người dùng (USER) để xin thêm chỉ dẫn hoặc xác nhận.
