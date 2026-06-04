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

---

## 2. Six Golden Rules of Database Programming
1.  **Schema Verification**: Verify tables and columns via MCP queries or [Database_Tables_Schema.txt](../Database_Tables_Schema.txt). **Never** guess column names.
2.  **Header Settings**: Always prefix the procedure script with:
    ```sql
    SET NOCOUNT ON; SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON;
    ```
3.  **Security Param**: Every procedure **must** have `@LoginID INT` as a parameter to filter data scopes.
4.  **Audit Deprecations**: Verify tables, columns, and parameters against [99_deprecated.md](99_deprecated.md) before writing.
5.  **Idempotence**: Always use `CREATE OR ALTER PROCEDURE` to allow safe, repetitive deployments.
6.  **Menu Access Rights**: Only seed access permissions (`FullAccess = '32'`) for Admin `LoginID = 3` in `tblSC_Right_Stored`. **Do not** invoke `sp_UpdateMenuInUserRight` automatically in installer scripts.

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
