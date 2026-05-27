CREATE PROCEDURE sp_GetEmployeeDetailsReport
    @ViewDate DATE, -- Ngày cần báo cáo (The specific date to report on)
    @LoginID INT   -- Mã đăng nhập của người dùng thực hiện báo cáo (The login ID of the user running the report)
AS
BEGIN
    SET NOCOUNT ON;
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;

    SELECT
        e.EmployeeName AS [Tên],
        e.DepartmentName AS [Bộ phận],
        e.DateOfBirth AS [Ngày sinh],
        s.SalaryDetails, -- Thông tin lương (Salary details)
        c.ContractDetails -- Thông tin hợp đồng hiện tại (Current contract details)
    FROM
        dbo.fn_vtblEmployeeList_Bydate(@ViewDate, NULL, @LoginID) AS e
    OUTER APPLY (
        SELECT TOP 1 * FROM dbo.fn_CurrentSalaryByDate(@ViewDate, @LoginID) -- Lấy thông tin lương tại ngày ViewDate
    ) AS s
    OUTER APPLY (
        SELECT TOP 1 * FROM dbo.fn_CurrentContractListByDate(@ViewDate, @LoginID) -- Lấy thông tin hợp đồng tại ngày ViewDate
    ) AS c;

END
GO