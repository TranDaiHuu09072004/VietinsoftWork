# Vietinsoft_Agent_Skill.md — Trung tâm quy tắc dự án Vietinsoft (ParadiseHR)

> File này là **trung tâm rules** — được các agent bridge file (`.clinerules`, `CLAUDE.md`, `.gemini_rules`...) load vào đầu session.
>
> File `UserProfile.md` BẮT BUỘC đọc trước để nạp ngữ cảnh người dùng. Xem [UserProfile.md](UserProfile.md)

---

## ⚠️ 9 QUY TẮC TỐI QUAN TRỌNG (CRITICAL RULES)

1. **Hiểu đúng yêu cầu trước khi làm.** Nếu mơ hồ → hỏi lại. Không tự suy đoán.
2. **Không tự suy đoán.** Mọi thông tin về schema, nghiệp vụ, công thức phải lấy từ nguồn xác thực.
3. **Mọi câu trả lời phải có chứng cứ xác thực.** Nguồn: file Knowledge, query MCP, file source, phát biểu của user.
4. **Không kết luận vội.** Thiếu chứng cứ → tra thêm hoặc báo user.
5. **Không ghi/xóa DB khi chưa được yêu cầu rõ ràng.** Mặc định chỉ đọc.
6. **Self-learning.** Tri thức mới → ghi vào đúng file Knowledge tương ứng.
7. **Check deprecated.** Trước khi dùng tên item → kiểm tra [Knowledge/99_deprecated.md](Knowledge/99_deprecated.md).
8. **Không tự xóa DB.** Build SQL script cho user tự chạy.
9. **Không tự ý commit/push.** Chỉ làm khi user yêu cầu rõ ràng.

---

## Bối cảnh dự án

- **ParadiseHR** (Vietinsoft) — tra cứu, tổng hợp, ghi tri thức. Không viết code production.
- **Knowledge base**: [Knowledge/INDEX.md](Knowledge/INDEX.md) — đọc đầu tiên mỗi session để định vị file kiến thức.
- **Nguồn xác thực**: MCP `mssql-vietinsoft` (SQL Server, read-only).
- **File tham khảo**: `user_for_AI.sql` — chỉ đọc, không thực thi.

---

## Quy trình 6 bước xử lý yêu cầu

Áp dụng cho mọi yêu cầu liên quan đến logic, nghiệp vụ, dữ liệu ParadiseHR.

| Bước | Hành động | Ghi chú |
|---|---|---|
| **1. Đọc INDEX** | Mở [Knowledge/INDEX.md](Knowledge/INDEX.md) | Nếu chưa đọc trong session. Map keyword/table/procedure → file Knowledge. |
| **2. Tra Knowledge** | Đọc file Knowledge theo INDEX | Nếu INDEX không map được → `search_files` regex toàn bộ `Knowledge/`. |
| **3. Khám phá DB** | Query MCP `mssql-vietinsoft` nếu Knowledge chưa đủ | Tool: `list_tables`, `execute_query`, `get_foreign_keys`, `get_table_stats`. Luôn `TOP N`. **Tránh forbidden keywords**: `sp_`, `SP_`, DELETE, INSERT, UPDATE, DROP, TRUNCATE, CREATE → dùng ghép chuỗi `'s'+'p_X'`, `'DEL'+'ETE'` hoặc `CHAR()`. Không dùng `describe_table` → thay bằng `INFORMATION_SCHEMA.COLUMNS`. |
| **4. Trả lời** | Tiếng Việt + chứng cứ rõ ràng | Trích dẫn nguồn. Không đoán. Cấm "có lẽ", "thông thường". |
| **5. Cập nhật Knowledge** | Hỏi user trước khi ghi | Ghi vào đúng file, không trùng, không timestamp. |
| **6. Deprecated** | Check [99_deprecated.md](Knowledge/99_deprecated.md) trước khi dùng item. Khi user báo "không dùng nữa" → ghi vào deprecated + xóa khỏi file gốc. Khi user yêu cầu xóa DB → build SQL script, không tự xóa. | Item lỗi thời → không dùng, không đề xuất. Chi tiết: [99_deprecated.md](Knowledge/99_deprecated.md). |

---

## Quy ước phản hồi

- **Ngôn ngữ**: tiếng Việt. Identifier code giữ nguyên tiếng Anh.
- **Tham chiếu**: `[tên](path)`. **Không thực thi** `user_for_AI.sql` trừ khi user yêu cầu.

## Ngoại lệ

Quy trình trên không áp dụng khi câu hỏi **rõ ràng không liên quan** đến nghiệp vụ/dữ liệu ParadiseHR (ví dụ: git, format code, cấu hình IDE).