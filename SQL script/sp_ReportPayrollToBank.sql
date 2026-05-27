-- ============================================================================
-- Stored Procedure: sp_ReportPayrollToBank
-- Mục đích: Báo cáo danh sách lương chuyển khoản ngân hàng theo tháng và năm.
-- Tác giả: Copilot Agent (Dựa trên yêu cầu của user)
-- Ngày tạo: 2026-05-26
-- Mô tả: Thủ tục này tổng hợp thông tin từ bảng tính lương chi tiết, nhân viên, và thông tin ngân hàng để xuất báo cáo thanh toán.
-- ============================================================================

CREATE OR ALTER PROCEDURE [dbo].[sp_ReportPayrollToBank]
(
    @Month INT, 
    @Year INT, 
    @BankCode VARCHAR(20) -- Cần truyền BankCode để tra cứu Tên Ngân hàng
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Bắt đầu Transaction để đảm bảo tính toàn vẹn dữ liệu khi chạy SP
    BEGIN TRANSACTION;

    BEGIN TRY
        SELECT 
            COALESCE(c.FullName, e.FullName) AS [Họ Tên], -- Ưu tiên FullName từ CompanySalarySummary
            e.AccountNo AS [Số Tài Khoản],
            b.BankName AS [Tên Ngân Hàng],
            ssl.GrossTakeHome AS [Gross Take Home]
        FROM 
            tblSal_Sal ssl
        INNER JOIN 
            tblEmployee e ON ssl.EmployeeID = e.EmployeeID -- Join qua EmployeeID để lấy AccountNo
        INNER JOIN 
            CompanySalarySummary c ON ssl.EmployeeID = c.EmployeeID AND ssl.Month = c.[Month] AND ssl.Year = c.[Year] -- Giả định join theo kỳ lương
        INNER JOIN 
            tblMD_Bank b ON b.BankCode = @BankCode -- Join qua BankCode được truyền vào
        WHERE 
            ssl.Month = @Month 
            AND ssl.Year = @Year
            -- Thêm điều kiện lọc nếu cần thiết (ví dụ: chỉ báo cáo những người có lương > 0)
            AND ssl.GrossTakeHome IS NOT NULL AND ssl.GrossTakeHome > 0;

        COMMIT TRANSACTION;
        PRINT '=================================================================';
        PRINT '✅ Báo cáo danh sách lương chuyển khoản ngân hàng cho kỳ [' + CAST(@Month AS VARCHAR) + '/' + CAST(@Year AS VARCHAR) + '] đã được thực thi thành công.';
        PRINT 'Lưu ý: Cần đảm bảo @BankCode là mã ngân hàng hợp lệ và các bảng liên kết (tblSal_Sal, tblEmployee, CompanySalarySummary, tblMD_Bank) đều có dữ liệu cho kỳ này.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Báo lỗi chi tiết nếu có vấn đề xảy ra
        THROW;
        RETURN -1;
    END CATCH
END
GO