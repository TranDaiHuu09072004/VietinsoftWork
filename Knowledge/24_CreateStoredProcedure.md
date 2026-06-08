# 24 — Stored Procedure Coding Standards

Reference: [26_QueryOptimization.md](26_QueryOptimization.md) (Performance), [15_employee_query_apis.md](15_employee_query_apis.md) (Core APIs).

Follow these rules when designing, naming, and writing T-SQL Stored Procedures for ParadiseHR.

## 1. Pre-Implementation Survey (Mandatory Questions)
Before writing any database script, ask the user to confirm:
1.  **Purpose**: Detailed description of the business process.
2.  **Target Tables/Views**: Active schemas involved. Recommend candidate tables/views if appropriate.
3.  **Procedure Class**: Wrapper (menu shell), Data API (Get/List), Action (Update/Delete/Process), or Report.
4.  **Input Parameters**: Types and sizes (e.g. `@LoginID`, `@ViewDate`).
*Constraint*: Do not generate code until these inputs are confirmed.

> **Related:** When writing client-side code that calls procedures via `AjaxHPAParadise`, also see the mandatory procedure-existence check rule at [23_CallAPI.md §0](23_CallAPI.md).

---

## 2. Six Golden Rules of Database Programming
1.  **Schema Verification**: Verify tables and columns via MCP queries or `Database_Tables_Schema.txt`. **Never** guess column names.
2.  **Header Settings**: Always prefix the procedure script with:
    ```sql
    SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
    ```
3.  **Security Param**: Every procedure **must** have `@LoginID INT` as a parameter to filter data scopes.
4.  **Audit Deprecations**: Verify tables, columns, and parameters against [99_deprecated.md](99_deprecated.md) before writing.
5.  **Idempotence**: Always use `CREATE OR ALTER PROCEDURE` to allow safe, repetitive deployments.
6.  **Coding Details & Safety (Crucial)**:
    *   **Rule 6a (VARCHAR/NVARCHAR)**: Never use `CHAR(n)` or `NCHAR(n)` for parameters or variables. Always use `VARCHAR(n)` or `NVARCHAR(n)` to avoid whitespace padding issues. `@LanguageID` must be `VARCHAR(5)`.
    *   **Rule 6b (Unicode Prefix N)**: Always prefix literal strings concatenated/used in T-SQL with `N` (e.g. `+ N';'`, `ISNULL(@Account, N'')`), otherwise Vietnamese characters will be converted to `?`.
    *   **Rule 6c (Entity Decoding)**: Do not use `write_to_file`/`replace_in_file` on SQL strings with HTML entities (`&`, `<`, `>`, `"`). Use Python script binary patch with hex escape (`\x26amp;`) instead.
    *   **Rule 6d (Dropdown CSS)**: For dropdowns in containers with `overflow-y: auto`, use `position: fixed` + high `z-index` to prevent overflow clipping.
    *   **Rule 6e (Quote Strategy in Embedded JS)**: Use double quotes `"..."` for static strings and backticks `` `...` `` for templates or selector strings containing quotes. **Never** use single quotes `'` in JS embedded inside T-SQL, as it will close the SQL literal early.
    *   **Rule 6f (Rights Update)**: Only seed access permissions (`FullAccess = '32'`) for Admin `LoginID = 3` in `tblSC_Right_Stored`. **Do not** invoke `sp_UpdateMenuInUserRight` automatically in installer scripts.

---

## 3. Naming Conventions
*   **Menu Wrapper**: `sp_<BusinessScope>` (e.g., `sp_CRM_EditCustomer`).
*   **UI Renderer**: `sp_<BusinessScope>_html` (e.g., `sp_CRM_EditCustomer_html`).
*   **Data API**: `sp_<BusinessScope>_GetData` or `_List` / `_DataSource` (e.g., `sp_CRM_CustomerList_GetData`).
*   **Action API**: `sp_<BusinessScope>_<Action>` (Actions: `Update`, `Delete`, `Submit`, `Approve`).
*   **Report**: `sp_Report_<Scope>` or `rpt_<Scope>` (e.g., `rpt_PR_SalaryToBank`).

---
## 4. Core System Functions (Mandatory Reuse)
*   **Employee Snapshot**: `dbo.fn_vtblEmployeeList_Bydate(@ViewDate, @EmployeeID, @LoginID)` (refer to [15_employee_query_apis.md](15_employee_query_apis.md)).
*   **Active Wages**: `dbo.fn_CurrentSalaryByDate(@ViewDate, @LoginID)`.
*   **Active Contracts**: `dbo.fn_CurrentContractListByDate(@ViewDate, @LoginID)`.
*   **Salary Period boundaries**: `dbo.fn_Get_SalaryPeriod(@Month, @Year)` or `dbo.fn_Get_SalaryPeriod_ByDate(GETDATE())`.

---

## 5. File Management Standards
*   Write all SQL objects to individual `.sql` files.
*   Save scripts in: **`SQL script/`** directory.
*   Filename format: `[Action]_[ObjectName]_[YYYYMMDD].sql` (e.g., `create_sp_CRM_LeadList_GetData_20260604.sql`).

---

## 6. Boilerplate Code Templates

### 6.1. Data API / Report Template
```sql
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.sp_Report_ActiveContracts
    @LoginID INT,
    @ViewDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;

    IF @ViewDate IS NULL SET @ViewDate = CAST(GETDATE() AS DATE);

    SELECT emp.EmployeeCodeReal AS [Employee Code], emp.FullName AS [Full Name],
           sal.DepartmentName AS [Department], ct.ContractNo AS [Contract No]
    FROM dbo.fn_vtblEmployeeList_Bydate(@ViewDate, NULL, @LoginID) emp
    LEFT JOIN dbo.fn_CurrentSalaryByDate(@ViewDate, @LoginID) sal ON emp.EmployeeID = sal.EmployeeID
    OUTER APPLY (
        SELECT TOP 1 c.ContractNo
        FROM dbo.tblLabourContract c
        WHERE c.EmployeeID = emp.EmployeeID AND c.ContractStartDay <= @ViewDate
          AND (c.ContractEndDay IS NULL OR c.ContractEndDay >= @ViewDate)
        ORDER BY c.ContractStartDay DESC, c.ContractID DESC
    ) ct
    ORDER BY sal.DepartmentName, emp.EmployeeCodeReal;
END
GO
```

### 6.2. Wrapper Template (Fetch Cache)
```sql
SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE dbo.sp_CRM_EditCustomer
    @LoginID INT = NULL,
    @LanguageID VARCHAR(2) = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT html FROM dbo.tblHtmlScriptCache 
    WHERE TableName = 'sp_CRM_EditCustomer_html' AND ScreenType = -1 AND LanguageID = @LanguageID;
END
GO
```

---

## 8. Pre-Flight Checklist — Agent tự kiểm tra TRƯỚC KHI gửi code

> ⚠️ **BẮT BUỘC chạy qua checklist này trước mỗi lần `attempt_completion`.**  
> Mục tiêu: Agent tự phát hiện lỗi, không đợi user chỉ ra.

### A. T-SQL / Stored Procedure

- [ ] **Kiểu dữ liệu**: Mọi tham số/biến dùng `VARCHAR`/`NVARCHAR`, không `CHAR`. `@LanguageID` = `VARCHAR(5)`. (Rule 6a)
- [ ] **Prefix `N`**: Mọi literal string nối với `+` trong `SET @html = @html + ...` có prefix `N`, kể cả string ngắn như `N';'`, `N'";'`. (Rule 6b)
- [ ] **Không có `CHAR(2)`** nào trong toàn bộ file.

### B. JavaScript nhúng T-SQL

- [ ] **Không dùng nháy đơn `'`** trong JS code — nháy đơn đóng `N'...'` của T-SQL sớm. Dùng `"..."` cho string tĩnh, `` ` `` cho querySelector phức tạp. (Rule 6e)
- [ ] **`escapeHtml` tồn tại và có đủ 4 entity**: `&` `<` `>` `"`. KHÔNG có literal `&` `<` `>` `"` trong thân hàm.
- [ ] **`querySelector` có `data-*`** dùng backtick, VD: `` root.querySelector(`.tab[data-mode="0"] span`) `` — đảm bảo không quote lồng.
- [ ] **`data-text` trong renderNode dùng `normalize(rawName)`** — normalize trên raw string, không trên escaped string.

### C. Dropdown / UI

- [ ] **Dropdown trong container có `overflow-y: auto`** → `position: fixed; z-index: 1000`. (Rule 6d)
- [ ] **Singleton portal dropdown** — chỉ 1 dropdown instance cho toàn tree, không render inline trong mỗi node.

### D. Logic

- [ ] **Cascade trước, đếm sau**: `updateSelected()` gọi SAU `cascadeChildren()` / `cascadeCheckboxChildren()`.
- [ ] **Tree load default collapsed**: `renderNode` không set `is-open` mặc định (chỉ add khi search match).
- [ ] **Search word-based**: `normalize(query).split(/\s+/).every(w => text.indexOf(w) >= 0)`.

### E. Knowledge

- [ ] Hàm `normalize` dùng đúng chuẩn Paradise JS → tham khảo `22_UI_Helpers.md §3`.
