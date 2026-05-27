-- ============================================================================
-- SQL SCRIPT: CREATE STORED PROCEDURE FOR EMPLOYEE PROFILE, SALARY AND CONTRACT REPORT
-- AUTHOR: Antigravity (using sqlStoreCheck guidelines)
-- DATE: 2026-05-26
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Report_EmployeeProfileSalaryContract_ByDate
    @LoginID INT,
    @ViewDate DATE = NULL,
    @DepartmentID INT = NULL,
    @EmployeeID NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;

    -- 1. Default @ViewDate to current system date if not provided
    IF @ViewDate IS NULL
    BEGIN
        SET @ViewDate = CAST(GETDATE() AS DATE);
    END

    -- 2. Retrieve report data
    SELECT 
        ISNULL(sal.DepartmentName, N'Chưa phân bộ phận') AS [Bộ phận],
        emp.EmployeeCodeReal AS [Mã nhân viên],
        emp.FullName AS [Họ và tên],
        CAST(emp.Birthday AS DATE) AS [Ngày sinh],
        ISNULL(sal.Salary, 0) AS [Lương cơ bản],
        ISNULL(sal.Trans_AL, 0) AS [Phụ cấp đi lại],
        ISNULL(sal.Pos_AL, 0) AS [Phụ cấp chức vụ],
        ISNULL(sal.ABC, 0) AS [Phụ cấp ABC],
        ISNULL(sal.InsSalary, 0) AS [Lương đóng BH],
        ISNULL(sal.TotalSalary, 0) AS [Tổng lương],
        ISNULL(sal.NETSalary, 0) AS [Lương NET],
        ct.ContractNo AS [Số hợp đồng],
        ct.ContractName AS [Loại hợp đồng],
        CAST(ct.ContractStartDay AS DATE) AS [Ngày bắt đầu HĐ],
        CAST(ct.ContractEndDay AS DATE) AS [Ngày kết thúc HĐ],
        @ViewDate AS [Thời điểm báo cáo]
    FROM dbo.fn_vtblEmployeeList_Bydate(@ViewDate, @EmployeeID, @LoginID) emp
    LEFT JOIN dbo.fn_CurrentSalaryByDate(@ViewDate, @LoginID) sal ON emp.EmployeeID = sal.EmployeeID
    OUTER APPLY (
        SELECT TOP 1 
            c.ContractNo,
            c.ContractStartDay,
            c.ContractEndDay,
            t.ContractName
        FROM dbo.tblLabourContract c
        LEFT JOIN dbo.tblMST_ContractType t ON c.ContractCode = t.ContractCode
        WHERE c.EmployeeID = emp.EmployeeID
          AND c.ContractStartDay <= @ViewDate
          AND (c.ContractEndDay IS NULL OR c.ContractEndDay >= @ViewDate)
        ORDER BY c.ContractStartDay DESC, c.ContractID DESC
    ) ct
    WHERE (@DepartmentID IS NULL OR emp.DepartmentID = @DepartmentID)
    ORDER BY sal.DepartmentName, emp.EmployeeCodeReal;
END
GO
