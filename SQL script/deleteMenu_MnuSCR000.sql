-- ============================================================================
-- File      : SQL script/deleteMenu_MnuSCR000.sql
-- Mục đích  : Xóa TOÀN BỘ menu MnuSCR000 (Bảo mật và quyền user)
--             cùng tất cả menu con, thủ tục và cấu hình liên quan
--             khỏi database Vietinsoft_ForTest.
-- Database  : Vietinsoft_ForTest
-- Tác giả   : Antigravity
-- Ngày tạo  : 2026-05-24
-- Idempotent: Có thể chạy lại nhiều lần an toàn (kiểm tra EXISTS trước khi xóa).
-- ============================================================================
--
-- DANH SÁCH MenuID bị xóa:
--   MnuSCR000  - Bảo mật và quyền user (menu cha)
--   MnuSCR010  - Phân quyền truy cập
--   MnuSCR020  - Thay đổi mật khẩu
--   MnuSCR030  - Cấu hình kết nối
--   MnuSCR040  - Nhật ký người dùng (Desktop cũ - HPALog)
--   MnuSCR041  - Chính sách bảo mật
--   MnuSCR050  - Sao lưu cơ sở dữ liệu
--   MnuSCR605  - Nhật ký người dùng (EzLog)
--   MnuSCR606  - Thiết lập nhóm người dùng
--   MnuSCR607  - Nhóm phân quyền
--   MnuSCR608  - Quản lý người dùng
--   MnuSCR609  - Đổi mật khẩu
--   MnuSCR611  - Quên mật khẩu
--   MnuSCR612  - Tạo mật khẩu
--   MnuSCR699  - Phân Quyền truy cập
--
-- DANH SÁCH ObjectID bị xóa khỏi tblSC_Object / quyền:
--   6    - HPA.SystemAdmin             (MnuSCR000)
--   603  - HPA.SystemAdmin.UserRight   (MnuSCR010)
--   601  - HPA.SystemAdmin.ChangePassword (MnuSCR020)
--   602  - HPA.SystemAdmin.SetConnection  (MnuSCR030)
--   604  - HPA.SystemAdmin.HPALog       (MnuSCR040)
--   605  - DataSetting.sp_PasswordPolicyConfig (MnuSCR041)
--   1150 - HPA.SystemAdmin.BackupRestoreDB     (MnuSCR050)
--   14   - DataSetting.EzLog            (MnuSCR605)
--   606  - DataSetting.sp_UserRightGroup_list       (MnuSCR606)
--   607  - DataSetting.sp_UserManagementList_Group   (MnuSCR607)
--   608  - DataSetting.sp_UserManagementList         (MnuSCR608)
--   165  - DataSetting.user_changepassword_loaddata  (MnuSCR609)
--   240  - DataSetting.ForgotPasswordForm            (MnuSCR611)
--   354  - DataSetting.SetInitialPasswordForm        (MnuSCR612)
--   281  - DataSetting.sp_decentralization           (MnuSCR699)
--
-- ============================================================================

SET NOCOUNT ON;
GO

PRINT N'============================================================';
PRINT N'BẮT ĐẦU XÓA MENU MnuSCR000 VÀ CÁC THÀNH PHẦN LIÊN QUAN';
PRINT N'Database: Vietinsoft_ForTest';
PRINT N'============================================================';
GO

-- ============================================================================
-- BƯỚC 1: Xóa quyền truy cập (tblSC_Right_Stored)
-- ============================================================================
PRINT N'1. Đang xóa quyền tblSC_Right_Stored...';
GO

DELETE FROM tblSC_Right_Stored
WHERE ObjectID IN (
    6, 603, 601, 602, 604, 605, 1150,
    14, 606, 607, 608, 165, 240, 354, 281
);
GO

PRINT N'   [OK] Đã xóa tblSC_Right_Stored.';
GO

-- ============================================================================
-- BƯỚC 2: Xóa quyền theo nhóm (tblSC_GroupRight)
-- ============================================================================
PRINT N'2. Đang xóa quyền tblSC_GroupRight...';
GO

DELETE FROM tblSC_GroupRight
WHERE ObjectID IN (
    6, 603, 601, 602, 604, 605, 1150,
    14, 606, 607, 608, 165, 240, 354, 281
);
GO

PRINT N'   [OK] Đã xóa tblSC_GroupRight.';
GO

-- ============================================================================
-- BƯỚC 3: Xóa object phân quyền (tblSC_Object)
-- ============================================================================
PRINT N'3. Đang xóa tblSC_Object...';
GO

DELETE FROM tblSC_Object
WHERE Description IN (
    'MnuSCR000', 'MnuSCR010', 'MnuSCR020', 'MnuSCR030', 'MnuSCR040',
    'MnuSCR041', 'MnuSCR050', 'MnuSCR605', 'MnuSCR606', 'MnuSCR607',
    'MnuSCR608', 'MnuSCR609', 'MnuSCR611', 'MnuSCR612', 'MnuSCR699'
);
GO

PRINT N'   [OK] Đã xóa tblSC_Object.';
GO

-- ============================================================================
-- BƯỚC 4: Xóa tên menu đa ngôn ngữ (tblMD_Message)
-- ============================================================================
PRINT N'4. Đang xóa tên đa ngôn ngữ tblMD_Message...';
GO

DELETE FROM tblMD_Message
WHERE MessageID IN (
    'MnuSCR000', 'MnuSCR010', 'MnuSCR020', 'MnuSCR030', 'MnuSCR040',
    'MnuSCR041', 'MnuSCR050', 'MnuSCR605', 'MnuSCR606', 'MnuSCR607',
    'MnuSCR608', 'MnuSCR609', 'MnuSCR611', 'MnuSCR612', 'MnuSCR699'
);
GO

PRINT N'   [OK] Đã xóa tblMD_Message.';
GO

-- ============================================================================
-- BƯỚC 5: Xóa cấu hình Layout grid (tblDataSettingLayout)
-- Layout của EzLog (desktop cũ) có 21 dòng cấu hình cần xóa
-- ============================================================================
PRINT N'5. Đang xóa cấu hình tblDataSettingLayout...';
GO

DELETE FROM tblDataSettingLayout
WHERE TableName IN ('EzLog', 'ezlog');
GO

PRINT N'   [OK] Đã xóa tblDataSettingLayout.';
GO

-- ============================================================================
-- BƯỚC 6: Xóa cấu hình DataSetting (tblDataSetting)
-- ============================================================================
PRINT N'6. Đang xóa cấu hình tblDataSetting...';
GO

DELETE FROM tblDataSetting
WHERE TableName IN ('EzLog', 'ezlog');
GO

PRINT N'   [OK] Đã xóa tblDataSetting.';
GO

-- ============================================================================
-- BƯỚC 7: Xóa HTML cache (tblHtmlScriptCache) nếu có
-- ============================================================================
PRINT N'7. Đang xóa tblHtmlScriptCache...';
GO

DELETE FROM tblHtmlScriptCache
WHERE TableName IN ('EzLog_html', 'ezlog_html');
GO

PRINT N'   [OK] Đã xóa tblHtmlScriptCache (nếu có).';
GO

-- ============================================================================
-- BƯỚC 8: Xóa thủ tục EzLog, EzLog_html (nếu tồn tại trên DB này)
-- ============================================================================
PRINT N'8. Đang xóa các stored procedure EzLog / EzLog_html...';
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'EzLog' AND type = 'P')
BEGIN
    DROP PROCEDURE [dbo].[EzLog];
    PRINT N'   [OK] Đã DROP PROCEDURE EzLog.';
END
ELSE
    PRINT N'   [SKIP] PROCEDURE EzLog không tồn tại.';
GO

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'EzLog_html' AND type = 'P')
BEGIN
    DROP PROCEDURE [dbo].[EzLog_html];
    PRINT N'   [OK] Đã DROP PROCEDURE EzLog_html.';
END
ELSE
    PRINT N'   [SKIP] PROCEDURE EzLog_html không tồn tại.';
GO

-- Ghi chú: SC_EZLog_List là thủ tục nghiệp vụ gốc dùng chung cho Desktop.
-- Nếu muốn xóa luôn thủ tục nguồn dữ liệu thì bỏ comment 3 dòng bên dưới:
-- IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'SC_EZLog_List' AND type = 'P')
--     DROP PROCEDURE [dbo].[SC_EZLog_List];
-- GO

-- ============================================================================
-- BƯỚC 9: Xóa toàn bộ bản ghi MEN_Menu (menu con trước, menu cha sau)
-- ============================================================================
PRINT N'9. Đang xóa MEN_Menu (menu con)...';
GO

DELETE FROM MEN_Menu
WHERE MenuID IN (
    'MnuSCR010', 'MnuSCR020', 'MnuSCR030', 'MnuSCR040', 'MnuSCR041',
    'MnuSCR050', 'MnuSCR605', 'MnuSCR606', 'MnuSCR607', 'MnuSCR608',
    'MnuSCR609', 'MnuSCR611', 'MnuSCR612', 'MnuSCR699'
);
GO

PRINT N'   [OK] Đã xóa menu con.';
GO

PRINT N'9b. Đang xóa MEN_Menu (menu cha MnuSCR000)...';
GO

DELETE FROM MEN_Menu
WHERE MenuID = 'MnuSCR000';
GO

PRINT N'   [OK] Đã xóa menu cha MnuSCR000.';
GO

-- ============================================================================
-- BƯỚC 10: Xác minh kết quả
-- ============================================================================
PRINT N'';
PRINT N'10. XÁC MINH KẾT QUẢ:';
GO

SELECT
    'MEN_Menu còn lại'   AS [Bảng],
    COUNT(*)             AS [Số dòng còn sót]
FROM MEN_Menu
WHERE MenuID IN (
    'MnuSCR000', 'MnuSCR010', 'MnuSCR020', 'MnuSCR030', 'MnuSCR040',
    'MnuSCR041', 'MnuSCR050', 'MnuSCR605', 'MnuSCR606', 'MnuSCR607',
    'MnuSCR608', 'MnuSCR609', 'MnuSCR611', 'MnuSCR612', 'MnuSCR699'
)
UNION ALL
SELECT
    'tblSC_Object còn lại',
    COUNT(*)
FROM tblSC_Object
WHERE Description IN (
    'MnuSCR000', 'MnuSCR010', 'MnuSCR020', 'MnuSCR030', 'MnuSCR040',
    'MnuSCR041', 'MnuSCR050', 'MnuSCR605', 'MnuSCR606', 'MnuSCR607',
    'MnuSCR608', 'MnuSCR609', 'MnuSCR611', 'MnuSCR612', 'MnuSCR699'
)
UNION ALL
SELECT
    'tblMD_Message còn lại',
    COUNT(*)
FROM tblMD_Message
WHERE MessageID IN (
    'MnuSCR000', 'MnuSCR010', 'MnuSCR020', 'MnuSCR030', 'MnuSCR040',
    'MnuSCR041', 'MnuSCR050', 'MnuSCR605', 'MnuSCR606', 'MnuSCR607',
    'MnuSCR608', 'MnuSCR609', 'MnuSCR611', 'MnuSCR612', 'MnuSCR699'
)
UNION ALL
SELECT
    'tblDataSetting còn lại',
    COUNT(*)
FROM tblDataSetting
WHERE TableName IN ('EzLog', 'ezlog')
UNION ALL
SELECT
    'tblDataSettingLayout còn lại',
    COUNT(*)
FROM tblDataSettingLayout
WHERE TableName IN ('EzLog', 'ezlog')
UNION ALL
SELECT
    'tblHtmlScriptCache còn lại',
    COUNT(*)
FROM tblHtmlScriptCache
WHERE TableName IN ('EzLog_html', 'ezlog_html')
UNION ALL
SELECT
    'PROCEDURE EzLog còn tồn tại',
    COUNT(*)
FROM sys.objects
WHERE name IN ('EzLog', 'EzLog_html')
  AND type = 'P';
GO

PRINT N'============================================================';
PRINT N'HOÀN THÀNH XÓA MENU MnuSCR000.';
PRINT N'>>> Mọi cột "Số dòng còn sót" phải = 0 để xác nhận thành công.';
PRINT N'============================================================';
GO
