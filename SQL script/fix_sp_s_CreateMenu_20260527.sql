-- =====================================================================
-- Fix: sp_s_CreateMenu — Thêm đầy đủ các cột bắt buộc cho menu HTML-rendered
-- Date: 2026-05-27
-- Problem: Procedure cũ chỉ INSERT 5 cột, để NULL tất cả cột quan trọng:
--   Priority, GroupID, MobileDeviceGroup, ParentMenuMobileID,
--   glyphicon, NotUsePlatform, IsLeftMenu, IsHiddenInTree, SupperAdmin
--   → Menu không hiển thị trong cây + không mở được giao diện.
-- Fix: Tự động kế thừa từ parent menu + thêm @Priority, @glyphicon params.
-- =====================================================================

USE [Paradise_dev];
GO

-- =====================================================================
-- Phase 1: ALTER sp_s_CreateMenu — thêm cột INSERT + params mới
-- =====================================================================
ALTER PROCEDURE [dbo].[sp_s_CreateMenu](
    @Text           nvarchar(4000),
    @TextEN         nvarchar(4000),
    @ClassName      varchar(100),
    @ParentMenuID   varchar(100),
    @AssemblyName   varchar(100),
    @ParentObjectID int          = null,
    @Option         int          = 0,
    --0 Select (preview script only, no execute)
    --1 Create (execute insert)
    --2 for tblsc_right - @LoginIDList
    @LoginIDList    varchar(max) = '',
    @Priority       int          = 99,
    @glyphicon      varchar(100) = 'Info'
)
AS
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@ClassName, '') = '' OR ISNULL(@ParentMenuID, '') = '' OR ISNULL(@AssemblyName, '') = ''
        RETURN;

    IF @ParentObjectID IS NULL
        SET @ParentObjectID = (SELECT TOP 1 ObjectID FROM tblSC_Object WHERE Description = @ParentMenuID);

    DECLARE @MenuID    VARCHAR(100);
    DECLARE @MenuStart VARCHAR(100) = SUBSTRING(@ParentMenuID, 1, 6);

    IF @ParentObjectID IS NULL
        SET @ParentObjectID = (SELECT TOP 1 ObjectID FROM tblSC_Object WHERE Description = SUBSTRING(@ParentMenuID, 1, 6) + '000');

    -- =====================================================================
    -- Kế thừa cấu hình từ menu cha (FIX: không còn để NULL)
    -- =====================================================================
    DECLARE @InheritGroupID            VARCHAR(100),
            @InheritMobileDeviceGroup  VARCHAR(100),
            @InheritParentMenuMobileID VARCHAR(100),
            @InheritNotUsePlatform     VARCHAR(100);

    SELECT @InheritGroupID           = GroupID,
           @InheritMobileDeviceGroup = MobileDeviceGroup,
           @InheritParentMenuMobileID = ParentMenuMobileID,
           @InheritNotUsePlatform    = NotUsePlatform
    FROM MEN_Menu
    WHERE MenuID = @ParentMenuID;

    -- Fallback defaults nếu parent cũng NULL
    SET @InheritGroupID           = ISNULL(@InheritGroupID,           @ParentMenuID);
    SET @InheritMobileDeviceGroup = ISNULL(@InheritMobileDeviceGroup, 'MnuTAD000');
    SET @InheritParentMenuMobileID = ISNULL(@InheritParentMenuMobileID, '');
    SET @InheritNotUsePlatform    = ISNULL(@InheritNotUsePlatform,    '2');

    -- =====================================================================
    -- Sinh MenuID mới
    -- =====================================================================
    DECLARE @bigint    BIGINT,
            @bigintsc  BIGINT = ISNULL((SELECT TOP 1 ObjectID FROM tblSC_Object ORDER BY ObjectID DESC), 0) + 1;

    SET @bigint = ISNULL(
        (SELECT TOP 1 CAST(SUBSTRING(MenuID, 7, LEN(MenuID) - 6) AS BIGINT)
         FROM MEN_Menu
         WHERE SUBSTRING(MenuID, 1, 6) = @MenuStart
         ORDER BY CAST(SUBSTRING(MenuID, 7, LEN(MenuID) - 6) AS BIGINT) DESC), 0) + 1;

    SET @MenuID = @MenuStart + CAST(@bigint AS VARCHAR);

    -- =====================================================================
    -- Build dynamic SQL (FIX: INSERT đủ 19 cột thay vì 5)
    -- =====================================================================
    DECLARE @sql  NVARCHAR(MAX) = N'',
            @sql1 NVARCHAR(MAX) = N'';

    SET @sql = N'
DELETE MEN_Menu WHERE MenuID = ''' + @MenuID + N''';
INSERT INTO MEN_Menu (
    MenuID, ClassName, ParentMenuID, AssemblyName, IsVisible,
    IsWeb, ViewOnWeb, isShowLayOutWeb,
    IsUseMobileDevice, isShowInMobileLayOut,
    Priority, GroupID, MobileDeviceGroup, ParentMenuMobileID,
    glyphicon, NotUsePlatform, IsLeftMenu, IsHiddenInTree, SupperAdmin
) VALUES (
    ''' + @MenuID + N''',
    ''' + @ClassName + N''',
    ''' + @ParentMenuID + N''',
    ''' + @AssemblyName + N''',
    1,
    0, 0, 0,
    1, 0,
    ' + CAST(@Priority AS VARCHAR) + N',
    ''' + @InheritGroupID + N''',
    ''' + @InheritMobileDeviceGroup + N''',
    ''' + @InheritParentMenuMobileID + N''',
    ''' + @glyphicon + N''',
    ''' + @InheritNotUsePlatform + N''',
    0, 0, 0
);
';

    SET @sql1 = N'
DELETE tblSC_Object WHERE ObjectID = ' + CAST(@bigintsc AS VARCHAR) + N';
INSERT INTO tblSC_Object (ObjectID, ObjectName, Description, Visible, ParentObjectID)
VALUES (' + CAST(@bigintsc AS VARCHAR) + N',
    ''' + @AssemblyName + N'.' + @ClassName + N''',
    ''' + @MenuID + N''',
    1,
    ' + ISNULL(CAST(@ParentObjectID AS VARCHAR), '') + N');
';

    -- =====================================================================
    -- Collect all statements
    -- =====================================================================
    SELECT *
    INTO #tmp
    FROM (
        SELECT @sql AS Name
        UNION
        SELECT @sql1 AS Name
        UNION
        SELECT 'EXEC [1rename_Mess] ''' + @MenuID + N''',''VN'',N''' + @Text + N'''' AS Name
        WHERE ISNULL(@Text, '') <> ''
        UNION
        SELECT 'EXEC [1rename_Mess] ''' + @MenuID + N''',''EN'',N''' + @TextEN + N'''' AS Name
        WHERE ISNULL(@TextEN, '') <> ''
    ) t;

    -- =====================================================================
    -- Execute if @Option = 1 and menu doesn't already exist
    -- =====================================================================
    IF @Option = 1 AND NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE ClassName = @ClassName)
    BEGIN
        DECLARE @sqlCreate NVARCHAR(MAX) = N'';
        SELECT @sqlCreate += N'' + Name FROM #tmp;
        EXEC (@sqlCreate);
    END

    -- =====================================================================
    -- Grant permissions
    -- =====================================================================
    IF @LoginIDList != ''
    BEGIN
        DECLARE @execsql NVARCHAR(MAX) = N'';
        DECLARE @ObID    VARCHAR(MAX);

        SELECT @ObID = ObjectID FROM tblSC_Object WHERE ObjectName = @AssemblyName + '.' + @ClassName;
        IF @Option = 0 SET @ObID = @bigintsc;

        IF @ObID IS NOT NULL
        BEGIN
            DECLARE @tblsc_right VARCHAR(MAX) = 'tblsc_right';
            IF OBJECT_ID('tblsc_right') IS NULL SET @tblsc_right = 'tblSC_Right_Stored';

            SELECT @execsql += N'
INSERT INTO ' + @tblsc_right + N'(ObjectID, LoginID, FullAccess)
SELECT ' + @ObID + N', LoginID, 32 AS FullAccess
FROM tblSC_login WHERE LoginID IN (' + @LoginIDList + N')
EXCEPT
SELECT ObjectID, LoginID, FullAccess FROM ' + @tblsc_right;
        END

        PRINT @execsql;
        IF @Option = 0
            INSERT INTO #tmp (Name) VALUES (@execsql);
        ELSE
            EXEC (@execsql);
    END

    -- =====================================================================
    -- Preview mode: return generated script
    -- =====================================================================
    IF @Option = 0
        SELECT * FROM #tmp;
END
GO


-- =====================================================================
-- Phase 2: Kiểm tra kết quả — so sánh output trước/sau
-- =====================================================================

-- Test 1: Preview mode (không thực thi) — kiểm tra các cột mới có trong INSERT không
DECLARE @TestTextVN    NVARCHAR(4000) = N'Test menu moi';
DECLARE @TestTextEN    NVARCHAR(4000) = N'Test new menu';
DECLARE @TestClass     VARCHAR(100)   = 'sp_Test_NewMenu';
DECLARE @TestParent    VARCHAR(100)   = 'MnuKPI000';
DECLARE @TestAssembly  VARCHAR(100)   = 'DataSetting';

EXEC dbo.sp_s_CreateMenu
     @Text         = @TestTextVN,
     @TextEN       = @TestTextEN,
     @ClassName    = @TestClass,
     @ParentMenuID = @TestParent,
     @AssemblyName = @TestAssembly,
     @Option       = 0,          -- preview only
     @LoginIDList  = '3',
     @Priority     = 60,
     @glyphicon    = 'JBookMark';
GO


-- =====================================================================
-- Phase 3: Cleanup cache rác cho MnuKPI448 (LeadTrackingForMarketing)
-- =====================================================================

-- Xoá 2 rows rác (thiếu _html, html=NULL) — do gọi sai sp_GenerateHTMLScript trước đây
DELETE FROM dbo.tblHtmlScriptCache
WHERE TableName = 'sp_LeadTrackingForMarketing'
  AND DATALENGTH(html) IS NULL;

-- Build cache EN còn thiếu cho renderer
EXEC dbo.sp_GenerateHTMLScript 'sp_LeadTrackingForMarketing_html';

-- Refresh menu tree
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_LeadTrackingForMarketing';
GO


-- =====================================================================
-- Phase 4: Fix dữ liệu menu MnuKPI448 hiện tại (fill các cột NULL)
-- =====================================================================

-- Cập nhật các cột còn thiếu cho menu đã tạo bằng proc cũ
UPDATE MEN_Menu
   SET Priority            = 60,
       GroupID             = 'MnuKPI000',
       MobileDeviceGroup   = 'MnuTAD000',
       ParentMenuMobileID  = '',
       glyphicon           = 'JBookMark',
       NotUsePlatform      = '2',
       IsLeftMenu          = 0,
       IsHiddenInTree      = 0,
       SupperAdmin         = 0
 WHERE ClassName = 'sp_LeadTrackingForMarketing'
   AND GroupID IS NULL;  -- chỉ fix nếu chưa được fix

-- Verify
SELECT MenuID, ClassName, ParentMenuID, Priority, GroupID,
       MobileDeviceGroup, ParentMenuMobileID, glyphicon,
       NotUsePlatform, IsLeftMenu, IsHiddenInTree, SupperAdmin
FROM MEN_Menu
WHERE ClassName = 'sp_LeadTrackingForMarketing';
GO

PRINT 'Done. User logout/login để kiểm tra menu.';
