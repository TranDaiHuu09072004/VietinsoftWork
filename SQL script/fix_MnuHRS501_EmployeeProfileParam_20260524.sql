-- ============================================================================
-- File      : SQL script/fix_MnuHRS501_EmployeeProfileParam_20260524.sql
-- Mục đích  : Sửa lỗi khi click vào tên nhân viên mở chi tiết hồ sơ nhân viên 
--             luôn mở hồ sơ của người đăng nhập hiện tại.
--             - Sửa stored procedure HR_StaffInformation_List_2_Beta:
--               Đọc EmployeeID từ window.HR_StaffInformation_List_2_param 
--               hoặc window.HR_StaffInformation_List_2_Beta_param.
--             - Rebuild HTML cache.
-- Idempotent: Có (ALTER PROCEDURE, sp_GenerateHTMLScript).
-- Tác giả   : Antigravity
-- Ngày tạo  : 2026-05-24
-- ============================================================================

SET NOCOUNT ON;
GO

PRINT N'BẮT ĐẦU CẬP NHẬT THỦ TỤC LƯU TRỮ HR_StaffInformation_List_2_Beta...';
GO

DECLARE @def nvarchar(max);
SELECT @def = definition FROM sys.sql_modules WHERE object_id = OBJECT_ID('dbo.HR_StaffInformation_List_2_Beta');

IF @def IS NULL
BEGIN
    PRINT N'LỖI: Không tìm thấy thủ tục dbo.HR_StaffInformation_List_2_Beta!';
    THROW 50000, 'Procedure HR_StaffInformation_List_2_Beta not found', 1;
END

-- Thay thế CREATE PROCEDURE thành CREATE OR ALTER PROCEDURE
SET @def = REPLACE(@def, 'CREATE PROCEDURE', 'CREATE OR ALTER PROCEDURE');

-- Thay thế đoạn code để parse parameter
DECLARE @target1 nvarchar(100) = '<script>' + CHAR(13) + CHAR(10) + 'var divisions =[];';
DECLARE @target2 nvarchar(100) = '<script>' + CHAR(10) + 'var divisions =[];';

DECLARE @replacement nvarchar(max) = '<script>' + CHAR(13) + CHAR(10) + 
'var passedParams = window.HR_StaffInformation_List_2_param || window.HR_StaffInformation_List_2_Beta_param;' + CHAR(13) + CHAR(10) +
'if (passedParams) {' + CHAR(13) + CHAR(10) +
'    var passedEmployeeID = Array.isArray(passedParams) ?' + CHAR(13) + CHAR(10) +
'        (function() {' + CHAR(13) + CHAR(10) +
'            for (var i = 0; i < passedParams.length - 1; i += 2) {' + CHAR(13) + CHAR(10) +
'                if (passedParams[i] === ''''EmployeeID'''') return passedParams[i + 1];' + CHAR(13) + CHAR(10) +
'            }' + CHAR(13) + CHAR(10) +
'        })() : passedParams.EmployeeID;' + CHAR(13) + CHAR(10) +
'    if (passedEmployeeID) {' + CHAR(13) + CHAR(10) +
'        window.EmployeeParam = passedEmployeeID;' + CHAR(13) + CHAR(10) +
'    }' + CHAR(13) + CHAR(10) +
'}' + CHAR(13) + CHAR(10) +
'var divisions =[];';

IF CHARINDEX(@target1, @def) > 0
BEGIN
    SET @def = REPLACE(@def, @target1, @replacement);
    PRINT N'Đã thay thế theo định dạng CRLF.';
END
ELSE IF CHARINDEX(@target2, @def) > 0
BEGIN
    SET @def = REPLACE(@def, @target2, @replacement);
    PRINT N'Đã thay thế theo định dạng LF.';
END
ELSE
BEGIN
    THROW 50000, 'Could not find script insertion point in HR_StaffInformation_List_2_Beta', 1;
END

-- Thực thi ALTER thủ tục
EXEC sp_executesql @def;
PRINT N'Đã cập nhật thành công thủ tục HR_StaffInformation_List_2_Beta trong database.';
GO

PRINT N'Đang dọn dẹp và rebuild HTML Cache cho HR_StaffInformation_List_2_Beta...';
GO
DELETE FROM dbo.tblHtmlScriptCache WHERE TableName = 'HR_StaffInformation_List_2_Beta';
EXEC dbo.sp_GenerateHTMLScript 'HR_StaffInformation_List_2_Beta', '-1', 'HR_StaffInformation_List_2_Beta';
GO

PRINT N'CẬP NHẬT HOÀN TẤT!';
GO
