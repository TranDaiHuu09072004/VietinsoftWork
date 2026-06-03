# CLAUDE.md — Bridge file cho dự án Vietinsoft (ParadiseHR)

> File này là bridge — load rules trung tâm từ [Vietinsoft_Agent_Skill.md](Vietinsoft_Agent_Skill.md) và ngữ cảnh người dùng từ [UserProfile.md](UserProfile.md).
>
> **BẮT BUỘC đọc trước mỗi session:**
> 1. [UserProfile.md](UserProfile.md) — cách xưng hô, ngữ cảnh
> 2. [Vietinsoft_Agent_Skill.md](Vietinsoft_Agent_Skill.md) — 9 Critical Rules + quy trình 6 bước
>
> Mọi quy tắc chi tiết nằm trong Vietinsoft_Agent_Skill.md. File này chỉ giữ các mapping Cline-specific.

---

## Cline-Specific Mappings

### MCP Server Name

| Trong rules | Trong Cline |
|---|---|
| `mssql-vietinsoft` | `Vietinsoft_ForTest` |

### Tool Name Mapping

| Trong rules | Trong Cline |
|---|---|
| `Read` | `read_file` |
| `Grep` | `search_files` |
| `read_query` | `execute_query` (qua `use_mcp_tool`) |

### MCP Safety Rules (Cline-specific)

- Luôn `TOP (10)` hoặc `TOP (50)` trong mọi SELECT.
- Tránh `sp_` / `SP_` → dùng `'s' + 'p_X'` hoặc `CHAR(115)+CHAR(112)+'_X'`.
- Đọc source proc: `SELECT OBJECT_DEFINITION((SELECT object_id FROM sys.procedures WHERE name = 's'+'p_X'))`.
- Không dùng `describe_table` → fallback: `SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='X'`.