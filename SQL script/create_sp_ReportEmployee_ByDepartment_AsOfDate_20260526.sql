/*
    File: SQL script/create_sp_ReportEmployee_ByDepartment_AsOfDate_20260526.sql
    Mục đích: Tạo thủ tục báo cáo danh sách nhân viên theo bộ phận tại một thời điểm.
    Cảnh báo: User tự review và chạy trên DB đích. Agent không thực thi script này.

    Nguồn xác thực:
    - Knowledge/15_employee_query_apis.md: fn_vtblEmployeeList_Bydate(@ViewDate, @EmployeeID, @LoginID) trả snapshot nhân viên as-of ngày.
    - Knowledge/02_db_employee.md: tblEmployee có FullName, Birthday.
    - Knowledge/03_db_contract.md: tblLabourContract và tblMST_ContractType chứa thông tin hợp đồng.
    - DB MCP: fn_CurrentSalaryByDate(@ViewDate, @LoginID) trả thông tin lương theo ngày gồm Salary, InsSalary, NETSalary, TotalSalary, CurrencyCode.
*/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ReportEmployee_ByDepartment_AsOfDate
    @LoginID INT,
    @ViewDate DATE,
    @DepartmentID INT = NULL,
    @EmployeeID NVARCHAR(4000) = N'-1',
    @IncludeTerminated BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @ViewDate IS NULL
    BEGIN
        SET @ViewDate = CAST(GETDATE() AS DATE);
    END;

    ;WITH EmployeeSnapshot AS
    (
        SELECT
            e.EmployeeID,
            e.EmployeeCodeReal,
            e.FullName,
            e.Birthday,
            e.DepartmentID,
            e.ContractID,
            e.ContractCode,
            e.ContractStartDay,
            e.TerminateDate,
            e.LastWorkingDate
        FROM dbo.fn_vtblEmployeeList_Bydate(@ViewDate, @EmployeeID, @LoginID) AS e
        WHERE (@DepartmentID IS NULL OR e.DepartmentID = @DepartmentID)
          AND (@IncludeTerminated = 1 OR e.TerminateDate IS NULL OR e.TerminateDate > @ViewDate)
    )
    SELECT
        es.DepartmentID,
        d.DepartmentCode,
        d.DepartmentName,
        d.DepartmentNameEN,
        es.EmployeeID,
        es.EmployeeCodeReal,
        es.FullName,
        es.Birthday,
        sal.SalaryHistoryID,
        sal.[Date] AS SalaryEffectiveDate,
        sal.Salary,
        sal.InsSalary,
        sal.NETSalary,
        sal.Trans_AL,
        sal.Pos_AL,
        sal.Per_Rate,
        sal.TotalSalary,
        sal.CurrencyCode,
        es.ContractID,
        lc.ContractNo,
        es.ContractCode,
        ct.ContractName,
        ct.ContractNameEN,
        es.ContractStartDay,
        lc.ContractEndDay,
        es.TerminateDate,
        es.LastWorkingDate
    FROM EmployeeSnapshot AS es
    LEFT JOIN dbo.tblDepartment AS d
        ON es.DepartmentID = d.DepartmentID
    LEFT JOIN dbo.fn_CurrentSalaryByDate(@ViewDate, @LoginID) AS sal
        ON es.EmployeeID = sal.EmployeeID
    LEFT JOIN dbo.tblLabourContract AS lc
        ON es.ContractID = lc.ContractID
    LEFT JOIN dbo.tblMST_ContractType AS ct
        ON es.ContractCode = ct.ContractCode
    ORDER BY
        d.DepartmentName,
        es.FullName,
        es.EmployeeID;
END;
GO

/*
Ví dụ chạy thử:
EXEC dbo.sp_ReportEmployee_ByDepartment_AsOfDate
     @LoginID = 3,
     @ViewDate = '2026-05-26',
     @DepartmentID = NULL,
     @EmployeeID = N'-1',
     @IncludeTerminated = 0;
*/
