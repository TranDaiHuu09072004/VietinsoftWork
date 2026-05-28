-- ============================================================================
-- SQL SCRIPT: deploy_menu_Report_UserPermissionAudit_20260528.sql
-- MỤC ĐÍCH: Tạo menu "Báo cáo phân quyền người dùng" cho ParadiseHR Web
-- AUTHOR: Claude Agent
-- DATE: 2026-05-28
--
-- CƠ CHẾ: Cách 2 — Pure HTML Render (07_menu_system.md §7, KHUYẾN NGHỊ)
--   IsWeb=1, isShowLayOutWeb=1 → Web Portal gọi trực tiếp wrapper, lấy html trả về
--   KHÔNG cần tblDataSetting, KHÔNG cần tblDataSettingLayout
--
-- ĐIỀU KIỆN TIÊN QUYẾT: Đã chạy create_sp_Report_UserPermissionAudit_20260528.sql
--   để tạo sp_Report_UserPermissionAudit + sp_Report_UserPermissionAudit_html
--
-- QUY TRÌNH:
--   Phase D:  sp_s_CreateMenu → MEN_Menu + tblSC_Object + tblMD_Message + quyền
--   Phase E:  Cập nhật cờ menu Cách 2 (IsWeb=1, isShowLayOutWeb=1)
--   Phase F:  EXEC sp_GenerateHTMLScript → build cache (cách DUY NHẤT)
--   Phase H:  EXEC sp_Men_Menu_AfterSave_Simple → refresh menu
--
-- CẢNH BÁO: User tự review và chạy. Agent không thực thi tự động.
-- ============================================================================

USE [ParadiseHR];
GO

SET NOCOUNT ON;
GO

-- ============================================================================
-- SECTION 1: VERIFY prerequisites
-- ============================================================================
PRINT N'=== [1/5] VERIFY prerequisites ===';

IF OBJECT_ID('dbo.sp_Report_UserPermissionAudit_html', 'P') IS NULL
BEGIN
    RAISERROR(N'Thiếu sp_Report_UserPermissionAudit_html. Chạy create_sp_Report_UserPermissionAudit_20260528.sql trước.', 16, 1);
    RETURN;
END

IF OBJECT_ID('dbo.sp_Report_UserPermissionAudit', 'P') IS NULL
BEGIN
    RAISERROR(N'Thiếu sp_Report_UserPermissionAudit. Chạy create_sp_Report_UserPermissionAudit_20260528.sql trước.', 16, 1);
    RETURN;
END

PRINT N'  OK: Both procedures exist.';

-- ============================================================================
-- SECTION 2: CHECK if menu already exists
-- ============================================================================
PRINT N'';
PRINT N'=== [2/5] CHECK existing menu ===';

DECLARE @ClassName       NVARCHAR(250) = N'sp_Report_UserPermissionAudit';
DECLARE @AssemblyName    NVARCHAR(250) = N'DataSetting';
DECLARE @ParentMenuID    VARCHAR(50)   = N'MnuSCR000';
DECLARE @TextVN          NVARCHAR(250) = N'Báo cáo phân quyền người dùng';
DECLARE @TextEN          NVARCHAR(250) = N'User Permission Audit Report';
DECLARE @LoginIDList     VARCHAR(100)  = N'3,23';      -- 3=admin, 23=cuong.vu

DECLARE @ExistingMenuID  VARCHAR(50);

SELECT @ExistingMenuID = MenuID
FROM MEN_Menu
WHERE ClassName = @ClassName;

IF @ExistingMenuID IS NOT NULL
BEGIN
    PRINT N'  WARNING: Menu already exists: ' + @ExistingMenuID;
    PRINT N'  Script will continue (idempotent) but may skip some steps.';
END
ELSE
    PRINT N'  OK: No existing menu found for ClassName=' + @ClassName;

-- ============================================================================
-- SECTION 3: Phase D — sp_s_CreateMenu
-- ============================================================================
PRINT N'';
PRINT N'=== [3/5] Phase D — sp_s_CreateMenu ===';

IF @ExistingMenuID IS NULL
BEGIN
    EXEC dbo.sp_s_CreateMenu
         @Text         = @TextVN,
         @TextEN       = @TextEN,
         @ClassName    = @ClassName,
         @ParentMenuID = @ParentMenuID,
         @AssemblyName = @AssemblyName,
         @Option       = 1,
         @LoginIDList  = @LoginIDList;

    -- Retrieve generated MenuID
    SELECT @ExistingMenuID = MenuID
    FROM MEN_Menu
    WHERE ClassName = @ClassName;

    PRINT N'  Created menu: ' + ISNULL(@ExistingMenuID, N'ERROR — NULL');
END
ELSE
    PRINT N'  Skipped: Menu already exists.';

-- ============================================================================
-- SECTION 4: Phase E — Update flags (Cách 2: Pure HTML Render)
-- Dẫn chứng: 07_menu_system.md §7 — "luôn ưu tiên sử dụng Cách 2"
--   IsWeb=1, isShowLayOutWeb=1, IsUseMobileDevice=0, isShowInMobileLayOut=0
--   KHÔNG cần tblDataSetting + tblDataSettingLayout
-- ============================================================================
PRINT N'';
PRINT N'=== [4/5] Phase E — Update menu flags (Cách 2: Pure HTML Render) ===';

IF @ExistingMenuID IS NOT NULL
BEGIN
    UPDATE MEN_Menu
    SET IsVisible              = 1,
        IsWeb                  = 1,     -- Cách 2: Web Portal gọi trực tiếp wrapper
        ViewOnWeb              = 0,
        isShowLayOutWeb        = 1,     -- Cách 2: render thẳng HTML
        IsUseMobileDevice      = 0,     -- Cách 2: bỏ qua Mobile Engine
        isShowInMobileLayOut   = 0,
        Priority               = 99,
        GroupID                = @ParentMenuID
    WHERE MenuID = @ExistingMenuID;

    PRINT N'  Updated flags for: ' + @ExistingMenuID;
    PRINT N'    Cách 2: IsWeb=1, isShowLayOutWeb=1, IsUseMobileDevice=0';
END

-- ============================================================================
-- SECTION 5: Phase F + H — Build cache + Refresh menu
-- Dẫn chứng: 12_CreateMenu.md §5.5 — sp_GenerateHTMLScript là "cách DUY NHẤT"
-- ============================================================================
PRINT N'';
PRINT N'=== [5/5] Phase F — Build cache (sp_GenerateHTMLScript — cách DUY NHẤT) ===';

-- sp_GenerateHTMLScript tự gọi renderer cho VN + EN và MERGE vào tblHtmlScriptCache
EXEC dbo.sp_GenerateHTMLScript @TableName = N'sp_Report_UserPermissionAudit_html';

-- Verify cache
DECLARE @vnSize INT, @enSize INT;
SELECT @vnSize = DATALENGTH(html) FROM tblHtmlScriptCache
WHERE TableName = N'sp_Report_UserPermissionAudit_html' AND LanguageID = N'VN' AND ScreenType = -1;
SELECT @enSize = DATALENGTH(html) FROM tblHtmlScriptCache
WHERE TableName = N'sp_Report_UserPermissionAudit_html' AND LanguageID = N'EN' AND ScreenType = -1;

PRINT N'  Cache sizes: VN=' + ISNULL(CAST(@vnSize AS NVARCHAR), N'NULL')
    + N' bytes, EN=' + ISNULL(CAST(@enSize AS NVARCHAR), N'NULL') + N' bytes';

IF @vnSize IS NULL OR @vnSize < 100
    PRINT N'  ⚠ WARNING: VN cache is empty or very small — menu may show blank!';
ELSE
    PRINT N'  ✅ VN cache OK.';

-- ============================================================================
-- Phase H — Refresh menu
-- ============================================================================
PRINT N'';
PRINT N'=== Phase H — Refresh menu cache ===';

EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = @ClassName;

PRINT N'  Refreshed menu: ' + @ClassName;

-- ============================================================================
-- VERIFY permissions
-- ============================================================================
PRINT N'';
PRINT N'=== VERIFY permissions ===';

DECLARE @ObjectID INT;
SELECT @ObjectID = ObjectID
FROM tblSC_Object
WHERE ObjectName = @AssemblyName + N'.' + @ClassName;

IF @ObjectID IS NOT NULL
BEGIN
    PRINT N'  ObjectID = ' + CAST(@ObjectID AS NVARCHAR);

    -- Check LoginID=3
    IF EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID = @ObjectID AND LoginID = 3)
        PRINT N'  ✅ LoginID=3 (admin): FullAccess';
    ELSE
        PRINT N'  ⚠ WARNING: LoginID=3 not found in tblSC_Right_Stored!';

    -- Check LoginID=23 (cuong.vu)
    IF EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID = @ObjectID AND LoginID = 23)
        PRINT N'  ✅ LoginID=23 (cuong.vu): FullAccess';
    ELSE
        PRINT N'  ⚠ WARNING: LoginID=23 not found in tblSC_Right_Stored!';
END
ELSE
    PRINT N'  ⚠ ERROR: ObjectID not found for ' + @AssemblyName + N'.' + @ClassName;

-- ============================================================================
-- DONE
-- ============================================================================
PRINT N'';
PRINT N'===============================================================';
PRINT N'  DEPLOY COMPLETE (Cách 2 — Pure HTML Render)';
PRINT N'===============================================================';
PRINT N'  MenuID:    ' + ISNULL(@ExistingMenuID, N'???');
PRINT N'  ObjectID:  ' + ISNULL(CAST(@ObjectID AS NVARCHAR), N'???');
PRINT N'  ClassName: ' + @ClassName;
PRINT N'';
PRINT N'  NEXT STEP: User logout/login → menu appears under "Hệ thống"';
PRINT N'===============================================================';
GO
