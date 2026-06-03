# QueryOptimization — Workflow phân tích & tối ưu hiệu năng SQL

> **Skill** — Quy trình chẩn đoán procedure/function chạy chậm: phân tích nguyên nhân (join, index, plan), đánh giá độ phức tạp, tạo script idempotent.
> **TUYỆT ĐỐI KHÔNG tự động thực thi script.** Agent chỉ tạo file `.sql` trong `SQL script/` để user tự review và chạy.
> **HẠN CHẾ dùng TRANSACTION** trong script tối ưu để tránh xung đột lock với ứng dụng C# đang chạy.

---

## ⚠️ QUY TẮC BẮT BUỘC

1. **KHÔNG TỰ ĐOÁN.** Mọi chẩn đoán phải dựa trên DMV query thực tế từ MCP `mssql-vietinsoft`.
2. **KHÔNG TỰ THỰC THI DDL/DML.** Agent chỉ tạo script, không chạy.
3. **ĐÁNH GIÁ ĐỘ PHỨC TẠP.** Nếu procedure quá rối (nhiều tầng lồng, dynamic SQL phức tạp, multi-branch logic) → DỪNG, báo cáo "quá phức tạp, cần review manual".
4. **GIẢI THÍCH RÕ RÀNG.** Mỗi script tối ưu phải kèm phân tích: vấn đề là gì, tại sao chọn giải pháp này, risk là gì.
5. **KHÔNG DÙNG TRANSACTION.** ParadiseHR hạn chế transaction để tránh xung đột với C#. Script phải idempotent (chạy nhiều lần không lỗi).
6. **TƯƠNG THÍCH ĐA PHIÊN BẢN.** Mọi câu SQL trong script phải tương thích SQL Server 2008 → 2022. Cú pháp chỉ có ở bản cao hơn phải có chú thích rõ ràng.
7. **ƯU TIÊN HÀM MỚI KHI CÓ THỂ.** Nếu phiên bản SQL Server đích hỗ trợ hàm mới (2012+), ưu tiên dùng cú pháp hiện đại để đạt hiệu năng tốt nhất. Luôn cung cấp fallback cho bản cũ. Xem [Chiến lược chọn cú pháp theo phiên bản](#chiến-lược-chọn-cú-pháp-theo-phiên-bản).
8. **CÂN NHẮC WITH (NOLOCK) KHI ĐỌC.** ParadiseHR có nhiều bảng chịu concurrent read/write cao. Trong các query đọc (SELECT) không yêu cầu consistency tuyệt đối, cân nhắc dùng `WITH (NOLOCK)` để giảm lock contention. Xem [Chiến lược WITH (NOLOCK)](#chiến-lược-with-nolock).

---

## Chiến lược chọn cú pháp theo phiên bản

Nguyên tắc: **Chọn cú pháp HIỆN ĐẠI NHẤT mà phiên bản SQL Server đích hỗ trợ.** Nếu không rõ phiên bản → fallback SQL 2008.

| Mục đích | SQL 2008-2012 | SQL 2012+ (ưu tiên) | SQL 2016+ | SQL 2017+ |
|---|---|---|---|---|
| Pagination | `ROW_NUMBER() OVER(...) BETWEEN` | `OFFSET ... FETCH NEXT` | — | — |
| Conditional value | `CASE WHEN ... THEN ... END` | `IIF(condition, true, false)` | — | — |
| NULL handling | `CASE WHEN x IS NULL THEN y ELSE x END` | — | — | — |
| Safe cast | `CASE WHEN ISNUMERIC(x)=1 THEN CAST(x AS ...) END` | `TRY_CAST(x AS ...)` / `TRY_CONVERT(...)` | — | — |
| String aggregation | `FOR XML PATH('')` + `STUFF` | `FOR XML PATH` | — | `STRING_AGG(c, ', ')` |
| First/Last value | Subquery `SELECT TOP 1 ... ORDER BY` | `FIRST_VALUE(x) OVER(...)`, `LAST_VALUE(x) OVER(...)` | — | — |
| Row offset access | Self-join or subquery | `LEAD(x, n) OVER(...)`, `LAG(x, n) OVER(...)` | — | — |
| Date from parts | `CAST(CAST(y AS VARCHAR)+'-'+CAST(m AS VARCHAR)+'-'+CAST(d AS VARCHAR) AS DATE)` | `DATEFROMPARTS(y, m, d)` | — | — |
| Format datetime | `CONVERT(VARCHAR, date, style)` | `FORMAT(date, 'yyyy-MM-dd')` (chậm hơn CONVERT) | — | — |
| Drop if exists | `IF EXISTS (SELECT 1 FROM sys.indexes ...) DROP INDEX ...` | — | `DROP INDEX IF EXISTS ...` | — |
| Create or alter | `IF OBJECT_ID(...) IS NOT NULL DROP ...; CREATE ...` | — | `CREATE OR ALTER ...` | — |
| Error handling | `RAISERROR(...)` | `THROW` | — | — |

> **⚠️ `FORMAT()`** chậm hơn `CONVERT()` đáng kể khi gọi trên nhiều rows. Chỉ dùng khi cần custom format phức tạp. Với format ngày tháng đơn giản → luôn ưu tiên `CONVERT()`.

---

## Chiến lược WITH (NOLOCK)

### Khi nào NÊN dùng NOLOCK

| Tình huống | Lý do |
|---|---|
| Query tra cứu danh sách (list view, grid) | Dirty read chấp nhận được, giảm lock |
| Report / Dashboard không cần real-time chính xác 100% | Ưu tiên tốc độ hơn consistency |
| Bảng reference ít thay đổi (tblDepartment, tblPosition...) | Nguy cơ dirty read thấp |
| Bảng có concurrent read/write cao (tblHasTA, tblTmpAttend...) | Tránh lock escalation |
| SELECT đếm / thống kê không join tới bảng đang INSERT/UPDATE | An toàn dùng NOLOCK |

### Khi nào TRÁNH dùng NOLOCK

| Tình huống | Lý do |
|---|---|
| **Tính lương / tài chính** (tblSal_*, tblPayslip) | Yêu cầu consistency tuyệt đối, dirty read gây sai tiền |
| **Tạo hóa đơn / mã số tăng tự động** | Có thể đọc duplicate hoặc missing row |
| **Query có JOIN tới bảng đang UPDATE/DELETE hàng loạt** | Có thể đọc 2 lần cùng 1 row hoặc bỏ sót row |
| **INSERT...SELECT / SELECT INTO** | Có thể insert duplicate data |
| **Subquery trong WHERE với EXISTS/IN** | Missing row detection |
| **Transaction đang chạy với ROLLBACK** | Có thể đọc row đã rollback |

> **Cảnh báo:** NOLOCK có thể gây đọc dirty data, missing rows, hoặc đọc trùng row 2 lần. Không dùng trong môi trường yêu cầu consistency tuyệt đối.

### Mẫu sử dụng NOLOCK an toàn

```sql
-- ✅ TỐT: Query báo cáo trên bảng lớn, chấp nhận dirty read
SELECT te.EmployeeID, te.FullName, td.DepartmentName
FROM tblEmployee te WITH (NOLOCK)
JOIN tblDepartment td WITH (NOLOCK) ON te.DepartmentID = td.DepartmentID
WHERE te.EmployeeStatusID = 0

-- ✅ TỐT: Đếm tổng trên bảng reference ít thay đổi
SELECT COUNT(*) FROM tblDepartment WITH (NOLOCK)

-- ❌ XẤU: Dùng NOLOCK khi tính lương (consistency critical)
SELECT SUM(SalaryPayable) FROM tblPayslip WITH (NOLOCK)  -- KHÔNG làm vậy!

-- ❌ XẤU: INSERT...SELECT với NOLOCK
INSERT INTO tblReport SELECT * FROM tblHasTA WITH (NOLOCK)  -- Có thể duplicate!
```

> **Trong script tối ưu:** Khi viết lại procedure, nếu thêm `WITH (NOLOCK)` vào các bảng đọc, phải ghi chú rõ lý do + cảnh báo dirty read trong comment header script.

---

## Bước 1 — Nhận input

Các dạng input Agent có thể nhận:

| Input | Cách xử lý |
|---|---|
| Tên procedure/function cụ thể | Bỏ qua bước 2, vào thẳng bước 3 |
| "Kiểm tra procedure chạy chậm" | Tự động query top N procedure chậm nhất (bước 2) |
| "Tối ưu bảng X" | Query missing indexes cho bảng đó |
| "Tối ưu query: `<SQL>`" | Phân tích execution plan của query cụ thể |

---

## Bước 2 — Tự động phát hiện procedure chậm (nếu không có input cụ thể)

### 2.1 Query top procedure theo thời gian chạy / logical reads

> **⚠️ SQL 2008: `sys.dm_exec_procedure_stats` có từ SQL 2008.** Nếu DB < 2008 thì DMV này không tồn tại → fallback dùng Profiler/trace thủ công.

```sql
SELECT TOP 10
    OBJECT_NAME(ps.object_id, DB_ID()) AS ProcName,
    ps.cached_time,
    ps.last_execution_time,
    ps.execution_count,
    ps.total_elapsed_time / 1000000.0 AS total_elapsed_sec,
    ps.total_worker_time / 1000000.0 AS total_cpu_sec,
    ps.total_logical_reads AS total_reads,
    CASE WHEN ps.execution_count > 0 
         THEN ps.total_elapsed_time / ps.execution_count / 1000.0 
         ELSE 0 END AS avg_elapsed_ms,
    CASE WHEN ps.execution_count > 0 
         THEN ps.total_logical_reads / ps.execution_count 
         ELSE 0 END AS avg_reads
FROM sys.dm_exec_procedure_stats ps
WHERE DB_NAME(ps.database_id) = DB_NAME()
  AND OBJECT_NAME(ps.object_id, DB_ID()) IS NOT NULL
ORDER BY ps.total_elapsed_time DESC
```

> **⚠️ SQL 2008 note:** Cột `last_execution_time` có từ SQL 2008. `cached_time` có từ SQL 2008. Trên SQL 2005 các cột này không có.

### 2.2 Query top query theo CPU/Reads

> **⚠️ SQL 2008: `sys.dm_exec_query_stats` có từ SQL 2008. `SUBSTRING` + `statement_start_offset` pattern hoạt động trên mọi phiên bản.**

```sql
SELECT TOP 10
    qs.total_worker_time / 1000000.0 AS total_cpu_sec,
    qs.total_logical_reads AS total_reads,
    qs.execution_count,
    CASE WHEN qs.execution_count > 0 
         THEN qs.total_worker_time / qs.execution_count / 1000.0 
         ELSE 0 END AS avg_cpu_ms,
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(st.text)
        ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)+1) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE DB_NAME(st.dbid) = DB_NAME()
ORDER BY qs.total_worker_time DESC
```

### 2.3 Phân tích kết quả

| Chỉ số | Ngưỡng cảnh báo | Ghi chú |
|---|---|---|
| `avg_elapsed_ms` | > 1000 ms | Cần xem xét |
| `avg_reads` | > 100,000 | Khả năng scan lớn, thiếu index |
| `execution_count` lớn + `avg` nhỏ | — | Có thể không cần tối ưu khẩn cấp |
| `total_worker_time` >> `total_elapsed_time` | — | CPU-bound, có thể parallelism hoặc compute nặng |

---

## Bước 3 — Đọc source procedure & phân tích

### 3.1 Lấy source code

> **⚠️ SQL 2008: `OBJECT_DEFINITION` có từ SQL 2005, hoạt động trên mọi phiên bản.**

```sql
SELECT OBJECT_DEFINITION(OBJECT_ID('<tên procedure>')) AS SourceCode
```

### 3.2 Phân tích độ phức tạp

Đọc source, đánh giá các yếu tố:

| Yếu tố | Đánh giá | Hành động |
|---|---|---|
| Số lượng JOIN | > 5 bảng → phức tạp | Xem xét cấu trúc lại |
| Sub-query lồng | > 2 tầng → warning | Đánh dấu cần review |
| Dynamic SQL (`sp_executesql`, `EXEC()`) | Có → cảnh báo | Cẩn thận khi tối ưu |
| CTE đệ quy | Có → phức tạp | Đánh dấu |
| Cursor / WHILE loop | Có → anti-pattern | Đề xuất SET-based |
| Scalar UDF trong WHERE/SELECT | Có → chậm | Đề xuất inline |
| `SELECT *` | Có → không tối ưu | Đề xuất liệt kê cột |
| `ORDER BY` không có index hỗ trợ | Có → sort spill | Đề xuất index |
| **Dùng #temp không cần thiết** | Query đơn giản dùng #temp → tăng I/O, chậm hơn CTE | Thay bằng CTE nếu chỉ dùng 1 lần (xem mục Chiến lược CTE vs #temp vs @table) |

**Nếu source QUÁ RỐI (> 3 yếu tố phức tạp trở lên):**
→ DỪNG. Báo cáo:
> *"Procedure `<tên>` quá phức tạp (nhiều tầng lồng / dynamic SQL / cursor). Không thể tối ưu tự động. Đề xuất review manual."*

---

## Bước 4 — Phân tích Execution Plan & Missing Index

### 4.1 Lấy plan từ cache

> **⚠️ SQL 2008: `sys.dm_exec_query_plan` có từ SQL 2005. Cột `query_plan` trả về XML plan hoạt động trên SQL 2008+.**

```sql
SELECT TOP 1
    qp.query_plan
FROM sys.dm_exec_procedure_stats ps
CROSS APPLY sys.dm_exec_query_plan(ps.plan_handle) qp
WHERE OBJECT_NAME(ps.object_id, DB_ID()) = '<tên procedure>'
ORDER BY ps.last_execution_time DESC
```

### 4.2 Kiểm tra Missing Index

> **⚠️ SQL 2008: Tất cả DMV missing index (`sys.dm_db_missing_index_*`) có từ SQL 2005, hoạt động trên mọi phiên bản từ 2008.**

```sql
SELECT
    mid.statement AS TableName,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    gs.avg_total_user_cost,
    gs.avg_user_impact,
    gs.user_seeks,
    gs.user_scans
FROM sys.dm_db_missing_index_details mid
JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
JOIN sys.dm_db_missing_index_group_stats gs ON mig.index_group_handle = gs.group_handle
WHERE mid.database_id = DB_ID()
ORDER BY (gs.avg_total_user_cost * gs.avg_user_impact) DESC
```

### 4.3 Phân tích plan (dấu hiệu cần tối ưu)

| Operator trong Plan | Vấn đề | Giải pháp | SQL version |
|---|---|---|---|
| `Table Scan` / `Clustered Index Scan` | Full scan bảng lớn | Thêm index phù hợp | All |
| `Key Lookup` | Index thiếu cột | Thêm INCLUDE trong index | SQL 2005+ |
| `Sort` (cost cao) | Sắp xếp không có index | Thêm index hỗ trợ ORDER BY | All |
| `Hash Match` | Join không có index | Thêm index trên cột join | All |
| `Nested Loops` (rows lớn) | Join row-by-row quá nhiều | Xem xét index hoặc cấu trúc lại join | All |
| `Implicit Conversion` | Ép kiểu ngầm | Khớp kiểu dữ liệu cột và tham số | All |
| `Cardinality Estimate` sai | Statistics cũ | `UPDATE STATISTICS <bảng>` | All |

---

## Bước 5 — Chẩn đoán nguyên nhân

Tổng hợp từ bước 3 + 4, xác định **1-2 nguyên nhân chính**:

| Nguyên nhân phổ biến | Cách nhận biết |
|---|---|
| **Thiếu index** | Missing index DMV có suggestion, plan có Table Scan/Key Lookup |
| **Join chưa tối ưu** | Hash Match cost cao, join sai thứ tự |
| **Scalar UDF trong WHERE** | Source code có gọi UDF trong mệnh đề WHERE |
| **Implicit conversion** | Plan có warning `CONVERT_IMPLICIT`, kiểu dữ liệu không khớp |
| **Statistics cũ** | Chênh lệch giữa `estimated rows` và `actual rows` |
| **Parameter sniffing** | Plan tốt cho param này nhưng xấu cho param khác |
| **SELECT \* / quá nhiều cột** | Source code dùng `SELECT *`, plan trả về quá nhiều cột không cần |

---

## Bước 6 — Đề xuất giải pháp & tạo script

### 6.1 Chọn giải pháp

**Luôn chọn giải pháp ít rủi ro nhất trước.**

| Nguyên nhân | Giải pháp | Rủi ro | SQL version |
|---|---|---|---|
| Thiếu index | `IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name='...') CREATE INDEX ...` | Thấp (tăng disk, chậm INSERT) | All |
| Statistics cũ | `UPDATE STATISTICS <bảng>` | Thấp (không thay đổi cấu trúc) | All |
| Join chưa tối ưu | Viết lại câu JOIN, thay đổi thứ tự | Trung bình (cần test lại output) | All |
| Scalar UDF | Viết lại thành inline TVF hoặc JOIN | Trung bình (thay đổi logic) | All |
| Implicit conversion | Sửa kiểu dữ liệu tham số/cột | Trung bình (ảnh hưởng schema) | All |
| Parameter sniffing | `OPTION (RECOMPILE)` hoặc `OPTIMIZE FOR` | Thấp (tăng compile time nhẹ) | SQL 2008+ |

> **⚠️ `OPTION (RECOMPILE)`** có từ SQL 2005, nhưng `OPTION (OPTIMIZE FOR UNKNOWN)` chỉ có từ SQL 2008. Với SQL 2005 → chỉ dùng `RECOMPILE`.

### 6.2 Tạo script idempotent

Script PHẢI tuân thủ mẫu sau, lưu trong `SQL script/query_optimization_<tên procedure>_<YYYYMMDD>.sql`:

```sql
-- =============================================
-- Script: Tối ưu hiệu năng [tên procedure]
-- Ngày tạo: [YYYY-MM-DD]
-- Tác giả: AI Agent (QueryOptimization workflow)
-- Scope: [Mô tả ngắn: index/statistics/rewrite]
-- 
-- ⚠️ CẢNH BÁO: BACKUP DATABASE TRƯỚC KHI CHẠY!
-- ⚠️ Script idempotent — có thể chạy nhiều lần không lỗi.
-- ⚠️ KHÔNG dùng transaction để tránh xung đột lock với C#.
-- ⚠️ Tương thích SQL Server 2008 → 2022.
-- 
-- Cách rollback nếu cần:
--   - Với CREATE INDEX: DROP INDEX [tên] ON [bảng]
--   - Với ALTER PROCEDURE: chạy lại script backup cũ
-- =============================================

SET NOCOUNT ON;
PRINT '=== Bắt đầu tối ưu: [tên procedure] ==='

-- 1. UPDATE STATISTICS (nếu cần)
-- UPDATE STATISTICS [dbo].[tên bảng];
-- PRINT '[OK] Đã update statistics cho [tên bảng]'

-- 2. CREATE INDEX (idempotent)
-- IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_<tên>' AND object_id = OBJECT_ID(N'[dbo].[tên bảng]'))
-- BEGIN
--     CREATE NONCLUSTERED INDEX [IX_<tên>]
--     ON [dbo].[tên bảng] ([cột1], [cột2])
--     INCLUDE ([cột3], [cột4])
--     WHERE [cột filter nếu cần];
--     PRINT '[OK] Đã tạo index IX_<tên>'
-- END
-- ELSE
-- BEGIN
--     PRINT '[SKIP] Index IX_<tên> đã tồn tại'
-- END

-- 3. ALTER PROCEDURE (nếu cần viết lại logic)
-- IF OBJECT_ID(N'[dbo].[tên procedure]', 'P') IS NOT NULL
-- BEGIN
--     EXEC dbo.sp_executesql N'
--     ALTER PROCEDURE [dbo].[tên procedure]
--     AS
--     BEGIN
--         SET NOCOUNT ON;
--         -- [code mới]
--     END';
--     PRINT '[OK] Đã update procedure [tên procedure]'
-- END

PRINT '=== Hoàn tất tối ưu ==='
SET NOCOUNT OFF;
```

### 6.3 Quy tắc idempotent

| Hành động | Pattern | SQL version |
|---|---|---|
| Tạo index | `IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_...') CREATE INDEX ...` | All |
| Xóa index cũ | `IF EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_...') DROP INDEX ... ON ...` | All |
| Tạo statistics | `IF NOT EXISTS (SELECT 1 FROM sys.stats WHERE name='...') CREATE STATISTICS ...` | All |
| Update statistics | Luôn chạy được, không cần check | All |
| Alter procedure | `IF OBJECT_ID('...','P') IS NOT NULL` + `sp_executesql` cho dynamic DDL | All |
| Drop procedure cũ | `IF OBJECT_ID('...','P') IS NOT NULL DROP PROCEDURE ...` | All |

> **⚠️ `DROP INDEX IF EXISTS`** chỉ có từ SQL 2016. Với SQL 2008-2014 → dùng `IF EXISTS (SELECT ... FROM sys.indexes ...) DROP INDEX ...`.

---

## Bước 7 — Giải thích & bàn giao

Agent PHẢI trả lời theo cấu trúc:

```
## Phân tích [tên procedure/function]

### Vấn đề phát hiện
- [Nguyên nhân 1]: [mô tả từ chứng cứ DMV/Plan]
- [Nguyên nhân 2]: [mô tả]

### Giải pháp đề xuất
- [Giải pháp 1]: [lý do chọn, risk nếu có, tương thích SQL version]
- [Giải pháp 2]: [lý do chọn, risk nếu có, tương thích SQL version]

### Script tối ưu
Đã tạo: `SQL script/query_optimization_<tên>_<YYYYMMDD>.sql`

### Khuyến nghị
- [Nên test trên môi trường DEV/Staging trước]
- [So sánh `SET STATISTICS IO ON` và plan trước/sau]
- [Cách rollback nếu có vấn đề (không dùng transaction)]
```

---

## Bảng tương thích phiên bản SQL Server

| Tính năng / Cú pháp | 2005 | 2008 | 2012 | 2014 | 2016 | 2017 | 2019 | 2022 |
|---|---|---|---|---|---|---|---|---|
| `sys.dm_exec_procedure_stats` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `sys.dm_exec_query_stats` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `sys.dm_db_missing_index_*` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `sys.dm_exec_query_plan` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `sys.dm_db_stats_properties` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `OBJECT_DEFINITION` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `DROP INDEX IF EXISTS` | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| `CREATE OR ALTER PROCEDURE` | ❌ | ❌ | ❌ | ❌ | ✅ SP1 | ✅ | ✅ | ✅ |
| `STRING_AGG` | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| `IIF(cond, v1, v2)` | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `TRY_CAST` / `TRY_CONVERT` | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `FIRST_VALUE` / `LAST_VALUE` | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `LEAD` / `LAG` | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `DATEFROMPARTS` | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `FORMAT` | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `OFFSET ... FETCH NEXT` | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `WITH (NOLOCK)` (table hint) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `OPTION (RECOMPILE)` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `OPTION (OPTIMIZE FOR UNKNOWN)` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `THROW` (error handling) | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Query Store | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ |
| `INCLUDE` trong index | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Filtered index `WHERE` | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Columnstore index | ❌ | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

> **Nguyên tắc:** Nếu môi trường đích không rõ phiên bản, mặc định dùng cú pháp tương thích SQL 2008. Nếu dùng cú pháp chỉ có ở phiên bản cao hơn, ghi chú rõ.

---

## Checklist tự kiểm tra (cho Agent)

Trước khi hoàn thành, Agent tự hỏi:

- [ ] Đã query DMV thực tế từ MCP? (không đoán)
- [ ] Đã đọc source procedure bằng `OBJECT_DEFINITION`?
- [ ] Đã phân tích execution plan?
- [ ] Đã đánh giá độ phức tạp? Nếu quá rối → đã DỪNG?
- [ ] Script **KHÔNG có TRANSACTION**? (để tránh xung đột C#)
- [ ] Script **idempotent**? (chạy nhiều lần không lỗi)
- [ ] Script đã lưu trong `SQL script/` với tên `query_optimization_*_<YYYYMMDD>.sql`?
- [ ] KHÔNG tự động thực thi script?
- [ ] Đã kiểm tra cú pháp tương thích SQL 2008-2022?
- [ ] Đã giải thích lý do chọn giải pháp?
- [ ] Đã nêu rõ cách rollback?

---

## Ví dụ mẫu

### Input
> "Kiểm tra procedure `sp_CRM_CustomerList_html` đang chạy chậm"

### Output mong đợi

```
## Phân tích sp_CRM_CustomerList_html

### Vấn đề phát hiện
- **Missing Index**: `tblCRM_CustomerPersonInfo.CompanyID` không có index, gây Clustered Index Scan
  → DMV đề xuất: CREATE INDEX ON tblCRM_CustomerPersonInfo (CompanyID) INCLUDE (FullName, Phone, Email)
  → Tương thích: SQL 2008+ (INCLUDE + nonclustered index)
- **Implicit Conversion**: Tham số `@StatusID` là `NVARCHAR`, cột `StatusID` là `INT`
  → Plan có warning CONVERT_IMPLICIT, ảnh hưởng mọi phiên bản SQL Server

### Giải pháp đề xuất
- Tạo index `IX_tblCRM_CustomerPersonInfo_CompanyID` với INCLUDE
  → Rủi ro: thấp (tăng ~5% disk, chậm INSERT không đáng kể)
  → Rollback: `DROP INDEX IX_tblCRM_CustomerPersonInfo_CompanyID ON tblCRM_CustomerPersonInfo`
- Sửa kiểu `@StatusID` thành `INT` để tránh ép kiểu
  → Rủi ro: cần kiểm tra tất cả caller của procedure

### Script tối ưu
Đã tạo: `SQL script/query_optimization_sp_CRM_CustomerList_html_20260528.sql`

### Khuyến nghị
- Test trên DEV trước
- So sánh `SET STATISTICS IO ON` trước/sau
- Nếu index gây vấn đề → chạy lệnh DROP INDEX để rollback
```

---

## Các query DMV hữu ích (tham khảo nhanh)

### Top procedure theo logical reads
```sql
SELECT TOP 10 
    OBJECT_NAME(object_id) AS ProcName,
    total_logical_reads / NULLIF(execution_count, 0) AS avg_logical_reads,
    total_elapsed_time / NULLIF(execution_count, 0) / 1000 AS avg_elapsed_ms,
    execution_count
FROM sys.dm_exec_procedure_stats
WHERE database_id = DB_ID()
  AND execution_count > 0
ORDER BY total_logical_reads DESC
```

### Index hiện có trên bảng
```sql
SELECT i.name AS IndexName, i.type_desc,
       STUFF((
           SELECT ', ' + c.name
           FROM sys.index_columns ic
           JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
           WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
           ORDER BY ic.key_ordinal
           FOR XML PATH(''), TYPE
       ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS KeyColumns
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('<bảng>')
```

> **⚠️ SQL 2008 note:** `FOR XML PATH` + `STUFF` cho string aggregation hoạt động trên SQL 2005+. `STRING_AGG` chỉ có từ SQL 2017.

### Kiểm tra statistics age
```sql
SELECT 
    OBJECT_NAME(s.object_id) AS TableName, 
    s.name AS StatName,
    STATS_DATE(s.object_id, s.stats_id) AS last_updated
FROM sys.stats s
WHERE s.object_id = OBJECT_ID('<bảng>')
```

> **⚠️ SQL 2008 note:** `STATS_DATE` hoạt động từ SQL 2005. `sys.dm_db_stats_properties` thay thế từ SQL 2008 R2 SP2+ nhưng `STATS_DATE` vẫn hoạt động trên mọi phiên bản.

### Tìm implicit conversion trong plan cache
```sql
SELECT TOP 10
    SUBSTRING(st.text, (qs.statement_start_offset/2)+1,
        ((CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(st.text)
        ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)+1) AS query_text,
    CAST(qp.query_plan AS XML).value('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";
        data(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:Warnings/ns:PlanAffectingConvert/@ConvertIssue)[1]', 'nvarchar(max)') AS ConvertIssue
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE qp.query_plan.exist('//ns:PlanAffectingConvert') = 1
  AND DB_NAME(st.dbid) = DB_NAME()
```

> **⚠️ SQL 2008 note:** XML namespace `http://schemas.microsoft.com/sqlserver/2004/07/showplan` hoạt động từ SQL 2005. Plan XML structure ổn định qua các phiên bản.

---

## Chiến lược CTE vs #temp vs @table (tối ưu RAM/CPU/IO)

### Khi nào dùng loại nào

| Loại | Khi dùng | Tránh dùng khi | RAM/IO tác động |
|---|---|---|---|
| **CTE** (`WITH ... AS`) | Query đơn giản, dùng 1 lần, cần readability, không cần index riêng | Dùng nhiều lần trong cùng batch (CTE bị re-evaluate mỗi lần gọi), cần transaction rollback (CTE không survive rollback) | ✅ Tiết kiệm RAM (không copy data). ⚠️ Re-evaluate nếu dùng nhiều lần → CPU tăng |
| **#temp table** | Dữ liệu lớn (> 100 rows), cần index riêng, dùng nhiều lần trong SP, cần statistics (estimate đúng row count) | Query nhỏ 1 lần (overhead tạo/drop), transaction rollback (temp table **không** rollback được) | ❌ Tốn RAM + tempdb I/O (INSERT #temp copy toàn bộ data). ✅ Có index → giảm I/O sau đó |
| **@table variable** | Dữ liệu rất nhỏ (< 30 rows), cần transaction safety (được rollback), dùng trong UDF | Dữ liệu > 100 rows (thiếu statistics → cardinality estimate sai 1 row → plan xấu), cần JOIN với bảng lớn | ✅ Ít RAM hơn #temp. ⚠️ **Không có statistics** → estimate sai → execution plan tồi |
| **Derived table** (subquery FROM) | Query 1 lần, đơn giản, không cần tái sử dụng | Query phức tạp cần reference nhiều lần, cần index | ✅ Không tốn RAM/IO thêm. ⚠️ Khó maintain |

### Quy tắc chọn lựa (theo thứ tự ưu tiên)

1. **Query dùng 1 lần, đơn giản → CTE** (tiết kiệm RAM, không tạo bảng tạm)
2. **Query cần index / dùng nhiều lần → #temp** (đánh đổi RAM lấy tốc độ, nhớ DROP)
3. **Query rất nhỏ, cần rollback → @table**
4. **Thay `SELECT INTO #tmp` bằng CTE khi có thể** — `SELECT INTO` gây I/O nặng, CTE thì không
5. **Tránh @table khi JOIN với bảng lớn** — estimate sai gây Hash Match nặng thay vì Nested Loops

### Mẫu chuyển từ #temp → CTE

```sql
-- ❌ CŨ: Dùng #temp cho query đơn giản
SELECT EmployeeID, FullName INTO #tmpEmp FROM tblEmployee WHERE StatusID = 1;
SELECT e.*, d.DepartmentName FROM #tmpEmp e JOIN tblDepartment d ON e.DepartmentID = d.DepartmentID;
DROP TABLE #tmpEmp;

-- ✅ MỚI: Dùng CTE, tiết kiệm RAM + I/O + không cần DROP
WITH cteEmp AS (
    SELECT EmployeeID, FullName, DepartmentID FROM tblEmployee WHERE StatusID = 1
)
SELECT e.*, d.DepartmentName FROM cteEmp e JOIN tblDepartment d ON e.DepartmentID = d.DepartmentID;
```

### Khi NÀO nên giữ #temp thay vì chuyển sang CTE

- Cần tạo index riêng cho dữ liệu trung gian (ví dụ: lọc nhiều lần theo nhiều tiêu chí khác nhau)
- Dataset trung gian được dùng > 2 lần trong cùng batch
- Cần statistics để tối ưu join với bảng lớn
- Cần `SELECT DISTINCT` + `INTO` để loại bỏ duplicate trước khi xử lý tiếp

---

## Ghi chú

- Workflow này sẽ được thay thế bằng MCP tool `fix_performance` (Python) khi đội kỹ thuật thống nhất phương án PA-A.
- Tạm thời Agent thực hiện thủ công theo workflow trên.
- Khi tạo script, luôn kiểm tra phiên bản SQL Server đích (`SELECT @@VERSION`) để chọn cú pháp phù hợp.

---

## Tham khảo bổ sung

| Chủ đề | File |
|---|---|
| Chuẩn tạo Stored Procedure mới (trước khi tối ưu) | [24_CreateStoredProcedure.md](24_CreateStoredProcedure.md) |
| Viết renderer HTML/JS an toàn, escape T-SQL | [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) |
| Tạo menu mới end-to-end (có SQL backend) | [12_CreateMenu.md](12_CreateMenu.md) |
| Migrate/update menu có sẵn (script SQL) | [13_Migrate_Menu.md](13_Migrate_Menu.md) |
| Bảng chấm công (`tblHasTA`, `tblTmpAttend`) — cần tối ưu thường xuyên | [05_db_attendance.md](05_db_attendance.md) |
| Gọi API từ JS → Stored Procedure (API chậm do SQL chậm) | [23_CallAPI.md](23_CallAPI.md) |
| Quy tắc an toàn DB, không tự thực thi DDL/DML | [CLAUDE.md](../CLAUDE.md) |
| Quy trình 5 bước tra cứu DB (knowledge base) | [INDEX.md](INDEX.md) |