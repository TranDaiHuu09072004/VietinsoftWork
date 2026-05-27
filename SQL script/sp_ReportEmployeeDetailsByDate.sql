-- =============================================
-- Author:      GitHub Copilot Agent
-- Create date: May 26, 2026
-- Description: Stored Procedure để báo cáo chi tiết thông tin nhân viên (Snapshot as-of)
--              bao gồm Bộ phận, Tên, Ngày sinh, Thông tin Lương và Hợp đồng tại một thời điểm xác định.
-- WARNING: Đây là bản nháp cấu trúc SP. Cần được kiểm tra cú pháp, phân quyền và logic nghiệp vụ chi tiết trước khi sử dụng trong môi trường Production.
-- =============================================

USE Paradise_dev; -- Thay thế bằng tên database thực tế nếu khác

GO

IF OBJECT_ID('dbo.sp_ReportEmployeeDetailsByDate', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_ReportEmployeeDetailsByDate;
GO

CREATE PROCEDURE dbo.sp_ReportEmployeeDetailsByDate
(
    @ViewDate DATE,       -- Ngày snapshot dữ liệu (Thời điểm báo cáo)
    @LoginID INT          -- ID người dùng thực hiện truy vấn (Dùng để lọc theo quyền hạn)
)
AS
BEGIN
    SET NOCOUNT ON;
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;

    -- Bắt đầu khối TRY/CATCH cho tính ổn định của SP
    BEGIN TRY
        SELECT
            E.EmployeeID,
            -- 1. Thông tin cơ bản (Từ fn_vtblEmployeeList_Bydate)
            DATEDIFF(day, E.DateOfBirth, @ViewDate) / 365.25 AS AgeAtReportDate, -- Tính tuổi tại ngày báo cáo
            E.DepartmentName,                                                  -- Bộ phận
            E.FullName,                                                       -- Tên đầy đủ
            E.Gender,
            E.EmployeeStatus,

            -- 2. Thông tin Hợp đồng (Từ fn_CurrentContractListByDate)
            C.ContractID,
            C.ContractType,
            C.StartDate AS ContractStartDate,
            C.EndDate AS ContractEndDate,
            ISNULL(C.IsActive, 0) AS IsCurrentlyActiveContract,

            -- 3. Thông tin Lương (Từ fn_CurrentSalaryByDate)
            S.SalaryID,
            S.BaseSalary,                                                     -- Mức lương cơ bản tại ngày báo cáo
            S.AllowanceTotal,                                                -- Tổng phụ cấp tại ngày báo cáo
            S.TaxDeduction,                                                   -- Thuế khấu trừ
            S.NetPayable,                                                    -- Số tiền thực nhận

            -- 4. Thông tin khác (Ví dụ: Tình trạng)
            CASE WHEN E.IsTerminated = 1 THEN 'Đã nghỉ việc' ELSE 'Đang làm việc' END AS EmploymentStatusDescription

        FROM
            dbo.fn_vtblEmployeeList_Bydate(@ViewDate, @LoginID) AS E -- Sử dụng TVF để lấy danh sách nhân viên snapshot tại ngày ViewDate
        INNER JOIN
            dbo.fn_CurrentContractListByDate(@ViewDate, @LoginID) AS C ON E.EmployeeID = C.EmployeeID AND C.IsActive = 1 -- Lấy HĐ đang hoạt động nhất
        LEFT JOIN
            dbo.fn_CurrentSalaryByDate(@ViewDate, @LoginID) AS S ON E.EmployeeID = S.EmployeeID -- Lấy thông tin lương tại ngày ViewDate

        WHERE
            E.DepartmentName IS NOT NULL -- Chỉ báo cáo những nhân viên có bộ phận được xác định
            AND C.ContractID IS NOT NULL; -- Bắt buộc phải có hợp đồng để báo cáo

    END TRY
    BEGIN CATCH
        -- Xử lý lỗi nếu SP bị lỗi cú pháp hoặc logic
        THROW;
        RETURN -1;
    END CATCH
END
GO

-- =============================================
-- Hướng dẫn sử dụng:
-- 1. Thay thế các hàm/bảng (fn_vtblEmployeeList_Bydate, fn_CurrentContractListByDate, fn_CurrentSalaryByDate) nếu tên thực tế khác.
-- 2. Chạy SP với tham số hợp lệ: EXEC dbo.sp_ReportEmployeeDetailsByDate @ViewDate = 'YYYY-MM-DD', @LoginID = [UserID];
-- =============================================