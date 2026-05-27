-- File: SQL script/report_employees_by_dept_asof.sql
-- Purpose: Report employees by department as-of a given date, including basic info, contract and salary snapshot.
-- NOTE: This is a template built from Knowledge (fn_vtblEmployeeList_Bydate). Adjust column names / table names if your DB differs.

IF OBJECT_ID('dbo.sp_Report_Employees_ByDepartment_AsOf', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Report_Employees_ByDepartment_AsOf;
GO

CREATE PROCEDURE dbo.sp_Report_Employees_ByDepartment_AsOf
(
    @ViewDate        DATE,
    @DepartmentID    NVARCHAR(50) = NULL, -- NULL = all departments
    @IncludeTerminated BIT = 0             -- 0 = exclude terminated as of @ViewDate
)
AS
BEGIN
    SET NOCOUNT ON;

    /*
      Logic:
      - Use dbo.fn_vtblEmployeeList_Bydate(@ViewDate, '-1', NULL) as the snapshot source (it already contains ContractID/ContractCode/ContractStartDay fields as-of @ViewDate).
      - Left-join to tblLabourContract to get contract metadata (choose the latest ContractStartDay <= @ViewDate per employee).
      - Left-join to tblSalaryHistory (or your payroll history table) to get the latest salary record <= @ViewDate.
      - This script is intentionally conservative and uses "latest <= @ViewDate" pattern.

      TODO: Verify exact table/column names in your DB, especially salary column names (e.g., SalaryAmount, BasicSalary, GrossSalary) and department name column. If different, edit the SELECT / JOIN blocks below.
    */

    SELECT
        e.EmployeeID,
        e.FullName,
        e.EmployeeCodeReal,
        e.BirthDate,

        er.DepartmentID,
        /* Department name: adjust table/column if your schema differs */
        dept.DepartmentName AS DepartmentName,

        -- Contract snapshot (from fn_vtblEmployeeList_Bydate) — present if any contract exists as-of @ViewDate
        er.ContractID,
        er.ContractCode,
        er.ContractStartDay AS ContractStartDate,

        -- Additional contract fields from tblLabourContract (if available)
        lc.ContractTypeID,
        lc.ContractEndDate,

        -- Salary snapshot: last salary record <= @ViewDate (adjust SalaryAmount column name if needed)
        sh.SalaryAmount    AS CurrentSalary, -- TODO: verify column name (SalaryAmount / BasicSalary / GrossSalary)
        sh.EffectiveDate  AS SalaryEffectiveDate

    FROM dbo.fn_vtblEmployeeList_Bydate(@ViewDate, '-1', NULL) er
    INNER JOIN dbo.tblEmployee e ON e.EmployeeID = er.EmployeeID
    LEFT JOIN dbo.tblDepartment dept ON dept.DepartmentID = er.DepartmentID

    -- Latest contract per employee as-of @ViewDate
    LEFT JOIN (
        SELECT lc1.EmployeeID, lc1.ContractID, lc1.ContractCode, lc1.ContractStartDay, lc1.ContractTypeID, lc1.ContractEndDate
        FROM dbo.tblLabourContract lc1
        INNER JOIN (
            SELECT EmployeeID, MAX(ContractStartDay) AS ContractStartDay
            FROM dbo.tblLabourContract
            WHERE ContractStartDay <= @ViewDate
            GROUP BY EmployeeID
        ) lcmax ON lc1.EmployeeID = lcmax.EmployeeID AND lc1.ContractStartDay = lcmax.ContractStartDay
    ) lc ON lc.EmployeeID = er.EmployeeID

    -- Latest salary record per employee as-of @ViewDate
    LEFT JOIN (
        SELECT s1.EmployeeID, s1.SalaryAmount, s1.EffectiveDate
        FROM dbo.tblSalaryHistory s1
        INNER JOIN (
            SELECT EmployeeID, MAX(EffectiveDate) AS EffectiveDate
            FROM dbo.tblSalaryHistory
            WHERE EffectiveDate <= @ViewDate
            GROUP BY EmployeeID
        ) smax ON s1.EmployeeID = smax.EmployeeID AND s1.EffectiveDate = smax.EffectiveDate
    ) sh ON sh.EmployeeID = er.EmployeeID

    WHERE (@DepartmentID IS NULL OR er.DepartmentID = @DepartmentID)
      AND (@IncludeTerminated = 1 OR er.TerminateDate IS NULL)
    ORDER BY er.DepartmentID, e.FullName;
END
GO

/* How to verify / adapt:
   1) If your payroll history table is named differently (e.g., tblSal_Sal, tblSalaryHistory), replace tblSalaryHistory accordingly.
   2) To inspect actual column names, run (in your DB):
        SELECT TOP 10 * FROM dbo.tblLabourContract;
        SELECT TOP 10 * FROM dbo.tblSalaryHistory;
        SELECT TOP 10 * FROM dbo.tblDepartment;
   3) If you prefer the procedure to accept an explicit Employee list or LoginID filter, modify the call to fn_vtblEmployeeList_Bydate(@ViewDate, @EmployeeID, @LoginID).

   This script is provided as a template per Knowledge: [15_employee_query_apis.md].
*/