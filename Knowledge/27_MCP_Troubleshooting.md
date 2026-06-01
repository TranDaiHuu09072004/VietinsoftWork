# MCP Troubleshooting — Workaround cho tool bị lỗi

> **Mục đích:** Ghi lại các lỗi đã phát hiện của MCP `mssql-vietinsoft` (package `@bilims/mcp-sqlserver`) và workaround bằng `execute_query`. Cập nhật khi có thay đổi.

---

## Trạng thái các tool MCP

| # | Tool | Kết quả | Ngày test |
|---|---|---|---|
| 1 | `test_connection` | ✅ OK (75ms) | 2026-05-28 |
| 2 | `get_server_info` | ✅ OK | 2026-05-28 |
| 3 | `list_tables` | ✅ OK (1203 tables) | 2026-05-28 |
| 4 | `list_views` | ✅ OK (34 views) | 2026-05-28 |
| 5 | `describe_table` | ❌ Bug package | 2026-05-28 |
| 6 | `execute_query` | ✅ OK (~20ms) | 2026-05-28 |
| 7 | `get_foreign_keys` | ✅ OK (8 FKs) | 2026-05-28 |
| 8 | `get_table_stats` | ✅ OK | 2026-05-28 |
| 9 | `list_databases` | ❌ Bug package | 2026-05-28 |

---

## Lỗi 1: `list_databases`

### Error message
```
Database operation failed: Query validation failed: Forbidden keyword detected: CREATE
```

### Nguyên nhân
Package `@bilims/mcp-sqlserver` có cơ chế validate SQL trước khi gửi. Khi gọi `list_databases`, package tự sinh câu SQL nội bộ (có thể dùng `CREATE VIEW` hoặc system procedure chứa từ `CREATE`). Cơ chế validate phát hiện và block — đây là **bug internal của package**, không phải lỗi DB.

### Workaround
Dùng `execute_query` với query sau:

```sql
SELECT name AS DatabaseName FROM sys.databases ORDER BY name
```

### Fix lâu dài
Fork `@bilims/mcp-sqlserver` → sửa logic validate: thêm whitelist cho các câu SQL nội bộ của chính package, hoặc kiểm tra context trước khi block.

---

## Lỗi 2: `describe_table`

### Error message
```
Database operation failed: Invalid column name 'dbo'
```

### Nguyên nhân
Package build câu SQL truy vấn `INFORMATION_SCHEMA` nhưng xử lý sai tham số `schema`. Thay vì dùng `schema` trong `WHERE TABLE_SCHEMA = '...'`, package có thể đã nhầm thành tên cột trong `SELECT` clause. **Bug internal của package.**

### Workaround 1 — Structure đầy đủ
```sql
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CASE WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN 'max'
         ELSE ISNULL(CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR), '') END AS MaxLength,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'IsIdentity') AS IsIdentity,
    CASE WHEN pk.COLUMN_NAME IS NOT NULL THEN 'YES' ELSE '' END AS PrimaryKey
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN (
    SELECT ku.TABLE_SCHEMA, ku.TABLE_NAME, ku.COLUMN_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE ku 
        ON tc.CONSTRAINT_NAME = ku.CONSTRAINT_NAME
        AND tc.TABLE_SCHEMA = ku.TABLE_SCHEMA
        AND tc.TABLE_NAME = ku.TABLE_NAME
    WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
) pk ON c.TABLE_SCHEMA = pk.TABLE_SCHEMA
    AND c.TABLE_NAME = pk.TABLE_NAME
    AND c.COLUMN_NAME = pk.COLUMN_NAME
WHERE c.TABLE_NAME = '<tên bảng>'
  AND c.TABLE_SCHEMA = 'dbo'
ORDER BY c.ORDINAL_POSITION
```

### Workaround 2 — Ngắn gọn (dùng sp_help)
```sql
EXEC sp_help '<tên bảng>'
```

> **⚠️ Lưu ý:** `sp_help` trả về nhiều result sets. `execute_query` có thể chỉ trả về set đầu tiên. Nếu cần đầy đủ → dùng workaround 1.

### Workaround 3 — Chỉ cần danh sách cột + type
```sql
SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '<tên bảng>' AND TABLE_SCHEMA = 'dbo'
ORDER BY ORDINAL_POSITION
```

### Fix lâu dài
Fork `@bilims/mcp-sqlserver` → sửa SQL builder trong `describe_table`, đảm bảo tham số `schema` được dùng đúng vị trí `WHERE` clause.

---

## Bảng workaround nhanh

| Mục đích | Tool gốc | Workaround (dùng execute_query) |
|---|---|---|
| Liệt kê databases | `list_databases` ❌ | `SELECT name FROM sys.databases ORDER BY name` |
| Xem cấu trúc bảng (đầy đủ) | `describe_table` ❌ | Workaround 1 (INFORMATION_SCHEMA + PK join) |
| Xem cấu trúc bảng (ngắn) | `describe_table` ❌ | `EXEC sp_help '<bảng>'` hoặc Workaround 3 |
| Liệt kê bảng | `list_tables` ✅ | (không cần) |
| Liệt kê view | `list_views` ✅ | (không cần) |
| FK relationships | `get_foreign_keys` ✅ | (không cần) |
| Row count & size | `get_table_stats` ✅ | (không cần) |

---

## Cập nhật

- 2026-05-28: Phát hiện 2 bug (`list_databases`, `describe_table`), thêm workaround.
- 2026-05-30: Phát hiện Cline trên Windows **không đọc được MCP config qua symlink**. `cline_mcp_settings.json` phải là file thật, không được symlink tới `.mcp.json`. Nếu muốn đồng bộ, dùng script copy thay vì symlink.
- 2026-05-30: Cline MCP config format **không hỗ trợ field `"type": "stdio"`** cho stdio transport. Chỉ cần `"command"`, `"args"`, `"env"`.
- Khi package `@bilims/mcp-sqlserver` được fix hoặc thay thế bằng MCP server tự viết → cập nhật file này.