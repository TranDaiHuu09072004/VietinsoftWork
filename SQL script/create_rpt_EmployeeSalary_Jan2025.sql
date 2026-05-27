-- ============================================================================
-- SQL SCRIPT: CREATE STORED PROCEDURE FOR EMPLOYEE SALARY REPORT JANUARY 2025
-- AUTHOR: Antigravity (using sqlStoreCheck guidelines)
-- DATE: 2026-05-26
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Report_EmployeeSalary_Jan2025
    @LoginID INT,
    @EmployeeID NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Determine salary period and the view date (end date of the period) for January 2025
    DECLARE @ViewDate DATE;
    SELECT @ViewDate = CAST(ToDate AS DATE) 
    FROM dbo.fn_Get_SalaryPeriod(1, 2025);

    -- Fallback to calendar month end if no salary period is defined
    IF @ViewDate IS NULL
    BEGIN
        SET @ViewDate = '2025-01-31';
    END

    -- 2. Retrieve employee list and join with current salary by view date
    SELECT 
        emp.EmployeeCodeReal AS [Mã nhân viên],
        emp.FullName AS [Họ và tên],
        sal.DepartmentName AS [Phòng ban],
        sal.PositionName AS [Chức vụ],
        ISNULL(sal.Salary, 0) AS [Lương cơ bản],
        ISNULL(sal.Trans_AL, 0) AS [Phụ cấp đi lại],
        ISNULL(sal.Pos_AL, 0) AS [Phụ cấp chức vụ],
        ISNULL(sal.ABC, 0) AS [Phụ cấp ABC],
        ISNULL(sal.InsSalary, 0) AS [Lương đóng BH],
        ISNULL(sal.TotalSalary, 0) AS [Tổng lương],
        ISNULL(sal.NETSalary, 0) AS [Lương NET],
        emp.AccountNo AS [Số tài khoản],
        sal.BankName AS [Ngân hàng],
        emp.TaxRegNo AS [Mã số thuế],
        sal.DependentNumber AS [Số người phụ thuộc],
        1 AS [Tháng báo cáo],
        2025 AS [Năm báo cáo]
    FROM dbo.fn_vtblEmployeeList_Bydate(@ViewDate, @EmployeeID, @LoginID) emp
    LEFT JOIN dbo.fn_CurrentSalaryByDate(@ViewDate, @LoginID) sal ON emp.EmployeeID = sal.EmployeeID
    ORDER BY emp.EmployeeCodeReal;
END
GO
