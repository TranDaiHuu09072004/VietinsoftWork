-- ============================================================================
-- File      : SQL script/deleteMenu_MnuSCR605.sql
-- Mục đích  : Xóa CHỈ menu MnuSCR605 (Nhật ký người dùng / EzLog)
--             cùng các thủ tục và cấu hình liên quan riêng của menu này
--             khỏi database Vietinsoft_ForTest.
--             KHÔNG ảnh hưởng đến bất kỳ menu nào khác trong MnuSCR000.
-- Database  : Vietinsoft_ForTest
-- Tác giả   : Antigravity
-- Ngày tạo  : 2026-05-24
-- Idempotent: Có thể chạy lại nhiều lần an toàn (kiểm tra EXISTS trước khi xóa).
-- ============================================================================
--
-- PHẠM VI XÓA:
--   MenuID    : MnuSCR605
--   ObjectID  : 14  (DataSetting.EzLog)
--   ClassName : EzLog
--   TableName : EzLog, ezlog (tblDataSetting, tblDataSettingLayout)
--   Cache     : EzLog_html, ezlog_html (tblHtmlScriptCache)
--   Procedures: EzLog, EzLog_html (nếu tồn tại)
--
--   ⚠ KHÔNG XÓA: SC_EZLog_List (thủ tục nguồn dữ liệu nghiệp vụ dùng chung)
--   ⚠ KHÔNG XÓA: MnuSCR000 và các menu con khác trong nhóm SCR
-- ============================================================================

SET NOCOUNT ON;
GO

PRINT N'============================================================';
PRINT N'BẮT ĐẦU XÓA MENU MnuSCR605 (Nhật ký người dùng - EzLog)';
PRINT N'Database: Vietinsoft_ForTest';
PRINT N'============================================================';
GO

-- ============================================================================
-- BƯỚC 1: Xóa quyền truy cập cá nhân (tblSC_Right_Stored) cho ObjectID = 14
-- ============================================================================
PRINT N'1. Đang xóa tblSC_Right_Stored (ObjectID = 14)...';
GO

DELETE FROM tblSC_Right_Stored
WHERE ObjectID = 14;
GO

PRINT N'   [OK] Đã xóa tblSC_Right_Stored.';
GO

-- ============================================================================
-- BƯỚC 2: Xóa quyền theo nhóm (tblSC_GroupRight) cho ObjectID = 14
-- ============================================================================
PRINT N'2. Đang xóa tblSC_GroupRight (ObjectID = 14)...';
GO

DELETE FROM tblSC_GroupRight
WHERE ObjectID = 14;
GO

PRINT N'   [OK] Đã xóa tblSC_GroupRight.';
GO

-- ============================================================================
-- BƯỚC 3: Xóa object phân quyền (tblSC_Object) cho MnuSCR605
-- ============================================================================
PRINT N'3. Đang xóa tblSC_Object (Description = MnuSCR605)...';
GO

DELETE FROM tblSC_Object
WHERE Description = 'MnuSCR605';
GO

PRINT N'   [OK] Đã xóa tblSC_Object.';
GO

-- ============================================================================
-- BƯỚC 4: Xóa tên menu đa ngôn ngữ (tblMD_Message) cho MnuSCR605
--   VN: Nhật ký người dùng
--   EN: System logs
-- ============================================================================
PRINT N'4. Đang xóa tblMD_Message (MessageID = MnuSCR605)...';
GO

DELETE FROM tblMD_Message
WHERE MessageID = 'MnuSCR605';
GO

PRINT N'   [OK] Đã xóa tblMD_Message.';
GO

-- ============================================================================
-- BƯỚC 5: Xóa cấu hình Layout (tblDataSettingLayout) cho EzLog
--   DB Vietinsoft_ForTest có 21 dòng layout Desktop cũ (GridControl, DateEdit...)
-- ============================================================================
PRINT N'5. Đang xóa tblDataSettingLayout (TableName = EzLog / ezlog)...';
GO

DELETE FROM tblDataSettingLayout
WHERE TableName IN ('EzLog', 'ezlog');
GO

PRINT N'   [OK] Đã xóa tblDataSettingLayout.';
GO

-- ============================================================================
-- BƯỚC 6: Xóa cấu hình DataSetting (tblDataSetting) cho EzLog
--   DB Vietinsoft_ForTest: IsProcedure=1, IsShowLayout=0, ColumnDataType=''
-- ============================================================================
PRINT N'6. Đang xóa tblDataSetting (TableName = EzLog / ezlog)...';
GO

DELETE FROM tblDataSetting
WHERE TableName IN ('EzLog', 'ezlog');
GO

PRINT N'   [OK] Đã xóa tblDataSetting.';
GO

-- ============================================================================
-- BƯỚC 7: Xóa HTML cache (tblHtmlScriptCache) nếu có
-- ============================================================================
PRINT N'7. Đang xóa tblHtmlScriptCache (EzLog_html / ezlog_html)...';
GO

DELETE FROM tblHtmlScriptCache
WHERE TableName IN ('EzLog_html', 'ezlog_html');
GO

PRINT N'   [OK] Đã xóa tblHtmlScriptCache (nếu có).';
GO

-- ============================================================================
-- BƯỚC 8: Drop stored procedure wrapper EzLog (nếu tồn tại)
-- ============================================================================
PRINT N'8. Đang kiểm tra và xóa PROCEDURE EzLog...';
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'EzLog' AND type = 'P')
BEGIN
    DROP PROCEDURE [dbo].[EzLog];
    PRINT N'   [OK] Đã DROP PROCEDURE EzLog.';
END
ELSE
    PRINT N'   [SKIP] PROCEDURE EzLog không tồn tại trên database này.';
GO

-- ============================================================================
-- BƯỚC 9: Drop stored procedure renderer EzLog_html (nếu tồn tại)
-- ============================================================================
PRINT N'9. Đang kiểm tra và xóa PROCEDURE EzLog_html...';
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'EzLog_html' AND type = 'P')
BEGIN
    DROP PROCEDURE [dbo].[EzLog_html];
    PRINT N'   [OK] Đã DROP PROCEDURE EzLog_html.';
END
ELSE
    PRINT N'   [SKIP] PROCEDURE EzLog_html không tồn tại trên database này.';
GO

-- ============================================================================
-- BƯỚC 10: Xóa bản ghi menu chính (MEN_Menu) cho MnuSCR605
-- ============================================================================
PRINT N'10. Đang xóa MEN_Menu (MenuID = MnuSCR605)...';
GO

DELETE FROM MEN_Menu
WHERE MenuID = 'MnuSCR605';
GO

PRINT N'    [OK] Đã xóa MEN_Menu.';
GO

-- ============================================================================
-- BƯỚC 11: Xác minh kết quả — mọi cột "Còn sót" phải = 0
-- ============================================================================
PRINT N'';
PRINT N'11. XÁC MINH KẾT QUẢ:';
GO

SELECT 'MEN_Menu'             AS [Bảng], COUNT(*) AS [Còn sót] FROM MEN_Menu          WHERE MenuID = 'MnuSCR605'
UNION ALL
SELECT 'tblSC_Object',                   COUNT(*)               FROM tblSC_Object       WHERE Description = 'MnuSCR605'
UNION ALL
SELECT 'tblMD_Message',                  COUNT(*)               FROM tblMD_Message      WHERE MessageID = 'MnuSCR605'
UNION ALL
SELECT 'tblSC_Right_Stored',             COUNT(*)               FROM tblSC_Right_Stored WHERE ObjectID = 14
UNION ALL
SELECT 'tblSC_GroupRight',               COUNT(*)               FROM tblSC_GroupRight   WHERE ObjectID = 14
UNION ALL
SELECT 'tblDataSetting',                 COUNT(*)               FROM tblDataSetting     WHERE TableName IN ('EzLog', 'ezlog')
UNION ALL
SELECT 'tblDataSettingLayout',           COUNT(*)               FROM tblDataSettingLayout WHERE TableName IN ('EzLog', 'ezlog')
UNION ALL
SELECT 'tblHtmlScriptCache',             COUNT(*)               FROM tblHtmlScriptCache WHERE TableName IN ('EzLog_html', 'ezlog_html')
UNION ALL
SELECT 'PROCEDURE EzLog (sys.objects)',  COUNT(*)               FROM sys.objects         WHERE name IN ('EzLog', 'EzLog_html') AND type = 'P';
GO

PRINT N'============================================================';
PRINT N'HOÀN THÀNH XÓA MENU MnuSCR605.';
PRINT N'>>> Mọi cột "Còn sót" phải = 0 để xác nhận thành công.';
PRINT N'>>> SC_EZLog_List được giữ nguyên (thủ tục nghiệp vụ dùng chung).';
PRINT N'============================================================';
GO
