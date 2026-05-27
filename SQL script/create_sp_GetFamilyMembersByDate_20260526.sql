/*
    File: SQL script/create_sp_GetFamilyMembersByDate_20260526.sql
    Mục đích: Tạo thủ tục báo cáo danh sách thành viên gia đình của nhân viên tại một thời điểm.
    Cảnh báo: User tự review và chạy trên DB đích (Vietinsoft_ForTest). Agent không thực thi script này.

    Nguồn xác thực:
    - Knowledge/02_db_employee.md: tblFamilyInfo chứa thông tin thành viên gia đình, liên kết qua EmployeeID.
    - Knowledge/15_employee_query_apis.md: Sử dụng logic snapshot date-based tương tự fn_vtblEmployeeList_Bydate để xác định nhân viên hợp lệ tại @ViewDate.
*/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_GetFamilyMembersByDate
    @LoginID INT,
    @ViewDate DATE,
    @EmployeeID NVARCHAR(4000) = N'-1' -- Hoặc list EmployeeID (delimited by ';')
AS
BEGIN
    SET NOCOUNT ON;

    IF @ViewDate IS NULL
    BEGIN
        SET @ViewDate = CAST(GETDATE() AS DATE);
    END;

    -- 1. Xác định danh sách nhân viên hợp lệ tại ViewDate và thuộc phạm vi quyền của LoginID
    WITH EmployeeSnapshot AS
    (
        SELECT
            e.EmployeeID,
            e.FullName,
            e.DepartmentID,
            e.PositionID,
            e.ContractID,
            e.TerminateDate
        FROM dbo.fn_vtblEmployeeList_Bydate(@ViewDate, @EmployeeID, @LoginID) AS e
    ),
    -- 2. Lấy thông tin thành viên gia đình (Family Info) theo snapshot date
    FamilySnapshot AS
    (
        SELECT
            tfi.EmployeeID,
            tfi.DependentNumber,
            tfi.FullName AS DependentName,
            tfi.RelationshipType, -- Quan hệ: Vợ/Chồng, Con cái, Cha mẹ...
            tfi.BirthDate,
            tfi.Gender,
            tfi.IsPrimaryDependant
        FROM dbo.tblFamilyInfo tfi
        INNER JOIN EmployeeSnapshot es ON tfi.EmployeeID = es.EmployeeID -- Join trực tiếp với snapshot nhân viên
    )
    SELECT
        es.EmployeeID,
        es.FullName AS EmployeeName,
        es.DepartmentID,
        d.DepartmentName,
        fs.DependentNumber,
        fs.DependentName,
        fs.RelationshipType,
        fs.BirthDate,
        fs.Gender,
        fs.IsPrimaryDependant
    FROM EmployeeSnapshot AS es
    LEFT JOIN dbo.tblDepartment AS d ON es.DepartmentID = d.DepartmentID
    LEFT JOIN FamilySnapshot AS fs ON es.EmployeeID = fs.EmployeeID
    WHERE 1=1; -- Điều kiện lọc bổ sung sẽ được thêm vào sau khi xác định rõ logic snapshot của tblFamilyInfo

END;
GO

/*
Ví dụ chạy thử:
EXEC dbo.sp_GetFamilyMembersByDate @LoginID = 3, @ViewDate = '2026-05-26', @EmployeeID = N'-1';
*/