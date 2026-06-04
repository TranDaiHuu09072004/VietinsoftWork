# 26 — Query Optimization Reference

Reference: [24_CreateStoredProcedure.md](24_CreateStoredProcedure.md) (Stored procedures).
*Rules*: Never execute DDL/DML optimization scripts directly; write to `SQL script/` for user review. Limit Transaction blocks to prevent lock contention.

---

## 1. Syntax Compatibility Matrix (SQL 2008 - 2022)
Select the most modern syntax supported by the target environment (fallback to SQL 2008 if unspecified):

| Feature | SQL 2008 / 2012 | SQL 2012+ (Preferred) | SQL 2017+ |
|---|---|---|---|
| **Pagination** | `ROW_NUMBER() OVER(...) BETWEEN` | `OFFSET ... FETCH NEXT` | — |
| **Conditionals** | `CASE WHEN ... THEN ... END` | `IIF(condition, true, false)` | — |
| **Safe Cast** | `CASE WHEN ISNUMERIC(x)=1 THEN CAST(x AS ..)` | `TRY_CAST(x AS ...)` | — |
| **String Agg** | `FOR XML PATH('')` + `STUFF` | `FOR XML PATH` | `STRING_AGG(c, ', ')` |
| **Lead / Lag** | Self-join or Subquery | `LEAD(...)` / `LAG(...)` | — |
| **Date Parts** | String Concatenation Cast | `DATEFROMPARTS(y, m, d)` | — |
| **Drop Index** | `IF EXISTS(SELECT 1...) DROP INDEX` | — | `DROP INDEX IF EXISTS` |
| **Create/Alter**| `IF OBJECT_ID(...) DROP; CREATE...` | — | `CREATE OR ALTER` |

*Note on `FORMAT()`*: Consider using `CONVERT()` over `FORMAT()` for date formatting on large datasets (e.g. >10k rows) due to execution CPU overhead.

---

## 2. Lock Contention & `WITH (NOLOCK)`
To prevent lock escalation on concurrent read/write environments (e.g., `tblHasTA`, `tblTmpAttend`):
*   **Recommended**: Analytical queries, reports, dashboards, grid searches, references lookup tables.
*   **Prohibited**: Payroll computation tables (`tblSal_*`), automated primary key sequencing, transactions involving rollback blocks.
*   *Template*:
    ```sql
    SELECT te.EmployeeID, td.DepartmentName FROM tblEmployee te WITH (NOLOCK)
    INNER JOIN tblDepartment td WITH (NOLOCK) ON te.DepartmentID = td.DepartmentID;
    ```

---

## 3. CTE vs Temporary Tables vs Table Variables
*   **Common Table Expressions (CTE)**: Memory-optimal. Best for simple single-run subqueries. Avoid if the dataset is referenced multiple times within the batch.
*   **Temp Tables (`#temp`)**: Best for large sets (> 100 rows) requiring indexing, multiple references, or statistics tracking. Remember to execute `DROP TABLE #temp` at completion.
*   **Table Variables (`@table`)**: Best for small sets (< 30 rows) requiring transactional safety. Avoid for large joins due to lack of column statistics (causes execution plan deterioration).

---

## 4. Diagnostics DMV Queries

### 4.1. Identify High Logical Read Procedures
```sql
SELECT TOP 10 OBJECT_NAME(ps.object_id, DB_ID()) AS ProcName, ps.execution_count, ps.total_elapsed_time / 1000000.0 AS TotalElapsedSec,
              ps.total_logical_reads AS TotalReads, ps.total_logical_reads / ps.execution_count AS AvgReads
FROM sys.dm_exec_procedure_stats ps WHERE DB_NAME(ps.database_id) = DB_NAME() AND ps.execution_count > 0 ORDER BY ps.total_logical_reads DESC;
```

### 4.2. Missing Index Analyzer
```sql
SELECT mid.statement AS TableName, mid.equality_columns, mid.inequality_columns, mid.included_columns,
       (gs.avg_total_user_cost * gs.avg_user_impact * (gs.user_seeks + gs.user_scans)) AS Score
FROM sys.dm_db_missing_index_details mid
INNER JOIN sys.dm_db_missing_index_groups mig ON mid.index_handle = mig.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats gs ON mig.index_group_handle = gs.group_handle
WHERE mid.database_id = DB_ID() ORDER BY Score DESC;
```

---

## 5. Idempotent Optimization Script Template
Write scripts to `SQL script/query_optimization_<object>_<date>.sql`.
```sql
SET NOCOUNT ON;
PRINT '=== Starting Optimization ===';

-- 1. Index Creation (Idempotent check)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_tbl_CP_CompanyID' AND object_id = OBJECT_ID(N'[dbo].[tblCRM_CustomerPersonInfo]'))
BEGIN
    CREATE NONCLUSTERED INDEX [IX_tbl_CP_CompanyID] ON [dbo].[tblCRM_CustomerPersonInfo] ([CRM_CompanyID]) INCLUDE ([FullName], [PhoneNumber]);
    PRINT '[OK] Created Index IX_tbl_CP_CompanyID';
END;

-- 2. Update stats
UPDATE STATISTICS [dbo].[tblCRM_CustomerPersonInfo];

-- 3. Procedure Alteration
IF OBJECT_ID(N'[dbo].[sp_CRM_CustomerList_html]', 'P') IS NOT NULL
BEGIN
    EXEC dbo.sp_executesql N'
    ALTER PROCEDURE [dbo].[sp_CRM_CustomerList_html]
        @LoginID INT
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT c.Company, p.FullName FROM dbo.tblCRM_CustomerPersonInfo p WITH (NOLOCK)
        INNER JOIN dbo.tblCRM_CompanyInfo c WITH (NOLOCK) ON p.CRM_CompanyID = c.Company_ID;
    END';
    PRINT '[OK] Altered sp_CRM_CustomerList_html';
END;

PRINT '=== Optimization Completed ===';
SET NOCOUNT OFF;
```