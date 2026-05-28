# Vietinsoft_Agent_Skill.md — Quy tắc bắt buộc khi làm việc với dự án Vietinsoft (ParadiseHR)

> File này được Claude Code tự load mỗi session. **MỌI QUY TẮC TRONG FILE NÀY ĐỀU LÀ BẮT BUỘC.** Không có loại trừ nào, không có "ưu tiên", không có "thường thường" — chỉ có TUÂN THỦ.

---

## ⚠️ QUY TẮC TỐI QUAN TRỌNG (CRITICAL RULES) ⚠️

Đây là các quy tắc **không bao giờ được vi phạm** dưới bất kỳ hoàn cảnh nào:

1. **TUYỆT ĐỐI KHÔNG TỰ SUY ĐOÁN.** Không bao giờ giả định cấu trúc bảng, tên cột, kiểu dữ liệu, mối quan hệ, quy tắc nghiệp vụ, công thức tính toán, hay hành vi của hệ thống. Mọi thông tin đều phải lấy từ nguồn xác thực.

2. **MỌI CÂU TRẢ LỜI PHẢI CÓ CHỨNG CỨ XÁC THỰC (CONCRETE EVIDENCE).** Chứng cứ chấp nhận được:
   - Nội dung trích trực tiếp từ **các file Knowledge** trong [Knowledge/](Knowledge/) (đã xác minh ở các session trước).
   - Kết quả query trực tiếp từ MCP `mssql-vietinsoft` (schema, data, source của procedure/view).
   - Nội dung trích từ file source trong repo (đọc qua `Read`/`Grep`).
   - Phát biểu rõ ràng của user trong session hiện tại.

3. **KHÔNG ĐƯA RA KẾT LUẬN VỘI VÃ.** Nếu chứng cứ chưa đủ, không được "đoán cho hợp lý". Phải:
   - Hoặc tiếp tục tra cứu để có chứng cứ.
   - Hoặc nói rõ với user: *"Không tìm thấy thông tin xác thực trong Knowledge và DB. Xin user cung cấp thêm chỉ dẫn / xác nhận."*

4. **KHÔNG VIẾT/SỬA/XOÁ DỮ LIỆU DB KHI CHƯA ĐƯỢC USER YÊU CẦU RÕ RÀNG TRONG TURN HIỆN TẠI.** Mặc định chỉ dùng tool đọc. Permission một lần không đồng nghĩa permission vĩnh viễn.

5. **TỰ HỌC — SELF-LEARNING.** Sau khi khám phá tri thức mới qua DB hoặc source, BẮT BUỘC ghi lại vào **đúng file** trong [Knowledge/](Knowledge/) tương ứng (xem mục [Bước 5](#bước-5--tự-cập-nhật-knowledge-self-learning)) để session sau không phải tra lại.

6. **LUÔN CHECK DANH SÁCH LỖI THỜI TRƯỚC KHI DÙNG TÊN ITEM.** Trước khi đề cập tên bảng / cột / procedure / view / menu / parameter trong câu trả lời, phải kiểm tra [Knowledge/99_deprecated.md](Knowledge/99_deprecated.md). Nếu item nằm trong danh sách → KHÔNG dùng, KHÔNG đề xuất.

7. **KHÔNG TỰ THỰC THI CÂU LỆNH DDL/DML XOÁ DB.** Khi user yêu cầu xoá item khỏi DB, luôn build SQL script trong [SQL script/](SQL script/) cho user tự chạy — không gọi tool DB ghi để xoá trực tiếp.

8. **KHÔNG TỰ Ý COMMIT/PUSH CODE.** Agent chỉ được phép `git commit` và `git push` khi user yêu cầu rõ ràng trong turn hiện tại. Có thể `git add` để stage file nhưng không được commit khi chưa có lệnh của user. Với git operations (stash, pull, rebase, status) vẫn được thực hiện để phục vụ công việc.

---

## Bối cảnh dự án

Đây là dự án **khám phá phần mềm Vietinsoft (ParadiseHR)**. Mục tiêu của workspace là **tra cứu — tổng hợp — ghi lại tri thức** về hệ thống. Không viết code production.

- **Knowledge base chính**: thư mục [Knowledge/](Knowledge/) — gồm 1 file chỉ mục [INDEX.md](Knowledge/INDEX.md) + ~12 file kiến thức đặc thù theo chủ đề.
- **Nguồn dữ liệu xác thực**: MCP server `mssql-vietinsoft` (SQL Server, cấu hình ở [.mcp.json](.mcp.json)).
- **File tham khảo SQL**: [user_for_AI.sql](user_for_AI.sql) — đọc để hiểu context, **KHÔNG được thực thi** trừ khi user yêu cầu rõ ràng.

---

## Quy trình 5 bước BẮT BUỘC khi xử lý yêu cầu

Áp dụng cho **mọi yêu cầu liên quan đến logic, nghiệp vụ, dữ liệu, schema, hoặc cấu trúc** của hệ thống ParadiseHR.

### Bước 1 — Đọc [Knowledge/INDEX.md](Knowledge/INDEX.md) đầu tiên

- Nếu trong session hiện tại đã đọc [INDEX.md](Knowledge/INDEX.md) rồi: tiếp tục Bước 2.
- Nếu chưa đọc: BẮT BUỘC dùng `Read` đọc [Knowledge/INDEX.md](Knowledge/INDEX.md) **trước khi làm bất cứ điều gì khác**. INDEX cung cấp:
  - Bảng map keyword tiếng Việt → file Knowledge.
  - Bảng map tên bảng (table) → file Knowledge.
  - Bảng map tên procedure → file Knowledge.

### Bước 2 — Tra Knowledge file đặc thù

- Dựa trên INDEX, xác định **1 hoặc nhiều file Knowledge** chứa tri thức về chủ đề user hỏi.
- Dùng `Read` mở file đó. Không đọc các file Knowledge khác trừ khi cần thiết.
- Nếu câu hỏi chạm nhiều chủ đề (vd: chấm công + tính lương): mở từng file theo thứ tự cần.

### Bước 3 — Đánh giá & Khám phá DB nếu thiếu

- **Nếu Knowledge đã đủ** để trả lời chính xác: tiến hành xử lý.
- **Nếu Knowledge chưa đủ / chưa có / không chắc còn chính xác**: BẮT BUỘC truy vấn MCP `mssql-vietinsoft` để xác minh từ DB thực tế.

Các tool MCP được phép dùng (load schema qua `ToolSearch` nếu cần):

| Mục đích | Tool | Tính chất |
|---|---|---|
| Liệt kê bảng | `mcp__mssql-vietinsoft__list_tables` | Đọc |
| Xem cấu trúc bảng | `mcp__mssql-vietinsoft__describe_table` | Đọc |
| Truy vấn dữ liệu / source procedure | `mcp__mssql-vietinsoft__read_query` | Đọc |
| Xuất kết quả | `mcp__mssql-vietinsoft__export_query` | Đọc |
| Liệt kê insight | `mcp__mssql-vietinsoft__list_insights` | Đọc |

**Quy tắc an toàn DB (BẮT BUỘC):**
- Mặc định CHỈ dùng tool đọc ở bảng trên.
- TUYỆT ĐỐI KHÔNG gọi `write_query`, `create_table`, `alter_table`, `drop_table`, `append_insight` khi user chưa yêu cầu rõ ràng trong câu hỏi hiện tại của session này. Permission một câu hỏi không kéo dài sang câu sau.
- Với `read_query`: luôn dùng `TOP N` / `WHERE` để giới hạn — không bao giờ trả về toàn bộ bảng lớn.
- Khi đọc source của procedure/view: dùng `SELECT OBJECT_DEFINITION(OBJECT_ID('...'))`.

### Bước 4 — Trả lời với chứng cứ rõ ràng

- Trả lời bằng **tiếng Việt**. Tên bảng, cột, câu SQL, identifier code: giữ nguyên tiếng Anh.
- **Trích dẫn nguồn cho mọi khẳng định**: tên bảng đã tra, file Knowledge đã đọc, tên procedure đã đọc source. Dùng cú pháp markdown link `[tên](path)` cho file refs.
- Nếu không tìm thấy chứng cứ xác thực: **không được đoán**. Báo user theo mẫu:
  > *"Không tìm thấy thông tin về X trong Knowledge cũng như DB. Xin user xác nhận / cung cấp thêm chỉ dẫn."*
- Cấm các cụm từ tự suy luận như "có lẽ", "thông thường", "đoán là", "chắc là" khi nói về cấu trúc/nghiệp vụ hệ thống.

### Bước 5 — Tự cập nhật Knowledge (Self-Learning)

Sau khi xác minh tri thức mới từ DB/source, BẮT BUỘC Hỏi người dùng có đồng ý ghi vào file Knowledge đúng chủ đề hay không:

- **Xác định file đúng** qua [Knowledge/INDEX.md](Knowledge/INDEX.md) — bảng map table/procedure/keyword → file.
- Chèn nội dung vào đúng section bên trong file. Nếu không khớp section nào: thêm sub-heading mới ở vị trí phù hợp.
- Mỗi entry mới ghi tối thiểu:
  - **Mô tả** ngắn gọn bằng tiếng Việt.
  - **Bảng / cột / file / procedure liên quan** (giữ nguyên tên gốc tiếng Anh).
  - **Câu SQL mẫu** trong code block ```sql … ``` khi hữu ích.
- **KHÔNG ghi lại nội dung đã có** — cập nhật chỗ cũ thay vì thêm bản trùng.
- **KHÔNG thêm timestamp / changelog** vào từng entry (đã có git history).
- **Nếu chủ đề mới hoàn toàn không khớp file nào**: tạo file mới trong [Knowledge/](Knowledge/) (đặt số tiếp theo, vd `12_xxx.md`) và **bổ sung file đó vào [INDEX.md](Knowledge/INDEX.md)** (bảng 1 + bảng 2/3/4 tương ứng).
- Cuối câu trả lời: nói ngắn gọn đã cập nhật file Knowledge nào, hoặc "đã có sẵn, không cần update".

### Bước 6 — Quản lý dữ liệu lỗi thời (DEPRECATED)

File [Knowledge/99_deprecated.md](Knowledge/99_deprecated.md) là **danh sách các item DB đã được user xác nhận là LỖI THỜI / KHÔNG DÙNG NỮA**. Đây là nguồn tra cứu bắt buộc trước khi đề cập bất kỳ tên item nào.

**Check deprecated trước khi trả lời:**

- Trước khi dùng tên bảng / cột / procedure / view / menu / parameter trong câu trả lời, BẮT BUỘC kiểm tra [99_deprecated.md](Knowledge/99_deprecated.md).
- Nếu item nằm trong danh sách → KHÔNG dùng. KHÔNG đề xuất.
- Nếu user hỏi trực tiếp về item đó → trả lời rằng item đã được đánh dấu lỗi thời (kèm lý do nếu có) và hỏi user muốn tiếp tục hay không.

**Khi user phản hồi tri thức Agent vừa cung cấp là sai / lỗi thời:**

User nói đại loại *"cái đó không dùng nữa"* / *"thực tế không có"* / *"đã bỏ lâu rồi"* / *"loại bỏ kiến thức này"* → BẮT BUỘC:

1. Ghi item vào đúng bảng phân loại trong [99_deprecated.md](Knowledge/99_deprecated.md) — bảng 1 (tables) / 2 (columns) / 3 (procedures) / 4 (views) / 5 (menus) / 6 (parameters) / 7 (other).
2. Mỗi entry phải có tối thiểu: tên item, loại, lý do (theo lời user), file Knowledge nguồn (nơi đã ghi tri thức sai), ngày đánh dấu (định dạng `YYYY-MM-DD`).
3. **Xoá entry sai khỏi file Knowledge gốc** nếu trước đây đã ghi vào.

**Khi user yêu cầu XOÁ item khỏi database:**

TUYỆT ĐỐI KHÔNG tự gọi `write_query` / `drop_table` / `drop_procedure` / `alter_table` để xoá. Thay vào đó:

1. Build file SQL script trong [SQL script/](SQL script/) đặt tên dạng `cleanup_<scope>_<YYYYMMDD>.sql`.
2. Script PHẢI:
   - Bọc trong `BEGIN TRANSACTION ... COMMIT/ROLLBACK` với `TRY/CATCH`.
   - Dùng `IF OBJECT_ID(...) IS NOT NULL` / `IF COL_LENGTH(...) IS NOT NULL` / `DROP IF EXISTS` để idempotent (chạy nhiều lần không lỗi).
   - Với menu: xoá theo đúng thứ tự để không vỡ FK — `tblSC_Right_Stored` / `tblSC_GroupRight` → `tblSC_Object` → `tblMD_Message` → `MEN_Menu`.
   - Có `PRINT` log từng item đã xoá.
   - Header comment ghi rõ: ngày tạo, scope, cảnh báo backup trước.
3. **Đưa file cho user tự review và chạy — KHÔNG thực thi tự động.**
4. Cập nhật cột "Cleanup script" trong bảng deprecated tương ứng trỏ tới file vừa tạo.

Mẫu script đầy đủ: xem cuối file [99_deprecated.md](Knowledge/99_deprecated.md).

---

## Quy ước phản hồi

- **Ngôn ngữ**: tiếng Việt.
- **Identifier code**: giữ nguyên tiếng Anh (tên bảng, cột, procedure, biến, từ khoá SQL).
- **Tham chiếu file**: dùng `[tên](đường-dẫn)` thay vì backtick.
- **Không thực thi** [user_for_AI.sql](user_for_AI.sql) trừ khi user yêu cầu rõ ràng — đọc để hiểu, không chạy.

---

## Ngoại lệ duy nhất

Quy trình 5 bước trên có thể **không áp dụng** chỉ trong **một** trường hợp:

> Câu hỏi của user **rõ ràng không liên quan** đến nghiệp vụ / dữ liệu / kiến trúc của ParadiseHR — ví dụ: cấu hình VS Code, Cấu hình Claude Code, lệnh git, format code thuần tuý, sửa file ngoài repo này.

Không có ngoại lệ nào khác. Câu hỏi tiếp nối cùng chủ đề **vẫn phải xác minh lại nếu chuyển sang khía cạnh chưa tra**. "User nói trả lời nhanh" không phải lý do để bỏ Bước 3 (tra DB) hay Bước 4 (chứng cứ) — chỉ có thể rút gọn Bước 5 (update Knowledge) nếu user nói rõ "không cần update".
