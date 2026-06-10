$ErrorActionPreference = "Stop"

$scriptPath = "d:\VietinsoftWork\Task done\Fix_CRM_Dashboard_Followup\migrate_menu_MnuKPI003_20260608.sql"
$htmlProcPath = "d:\VietinsoftWork\SQL script\sp_KPIListDataCollection_html.sql"

$header = @"
-- ============================================================================
-- File: SQL script/migrate_menu_MnuKPI003_20260608.sql
-- Mục đích: Migrate menu MnuKPI003 (KPI List Data Collection) ParadiseHR.
-- Cảnh báo: USER review + chạy. BACKUP DB trước. Idempotent.
-- ============================================================================
SET NOCOUNT ON; SET XACT_ABORT ON;
GO

-- PHASE 1: API procedures (sp_KPIgetDataCollection - nằm ở file sql riêng)
-- File Update_sp_KPIgetDataCollection.sql đi kèm trong thư mục Task done.

-- PHASE 2: Renderer (sp_KPIListDataCollection_html)
IF OBJECT_ID('dbo.sp_KPIListDataCollection_html','P') IS NOT NULL DROP PROCEDURE dbo.sp_KPIListDataCollection_html;
GO

"@

$wrapper = @"
GO

-- PHASE 3: Wrapper
IF OBJECT_ID('dbo.sp_KPIListDataCollection','P') IS NOT NULL DROP PROCEDURE dbo.sp_KPIListDataCollection;
GO
CREATE PROCEDURE dbo.sp_KPIListDataCollection (@LoginID int, @LanguageID varchar(5)='VN')
AS BEGIN SET NOCOUNT ON;
    SELECT TOP 1 html FROM dbo.tblHtmlScriptCache
    WHERE TableName='sp_KPIListDataCollection_html' AND ScreenType='-1' AND LanguageID=@LanguageID;
END
GO

-- PHASE 4: Metadata + language + permission
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @MenuID varchar(100) = 'MnuKPI003';
    DECLARE @ParentMenuID varchar(100) = 'MnuKPI000';
    DECLARE @ClassName varchar(100) = 'sp_KPIListDataCollection';
    DECLARE @AssemblyName varchar(100) = 'DataSetting';
    DECLARE @ObjectName varchar(200) = @AssemblyName + '.' + @ClassName;
    DECLARE @Priority int = 2, @Glyphicon nvarchar(100) = N'UserList';
    DECLARE @GroupID varchar(100) = @ParentMenuID;
    DECLARE @IsWeb int=0, @ViewOnWeb int=0, @IsShowLayOutWeb int=0,
            @IsUseMobileDevice int=1, @IsShowInMobileLayOut int=0;
    DECLARE @AdminLoginID int=3, @FullAccess nvarchar(10)=N'32';

    -- MEN_Menu
    IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = @MenuID)
        INSERT INTO MEN_Menu
            (MenuID, ClassName, AssemblyName, ParentMenuID, Priority,
             IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb, IsUseMobileDevice, isShowInMobileLayOut,
             glyphicon, GroupID)
        VALUES (@MenuID, @ClassName, @AssemblyName, @ParentMenuID, @Priority,
                1, @IsWeb, @ViewOnWeb, @IsShowLayOutWeb, @IsUseMobileDevice, @IsShowInMobileLayOut,
                @Glyphicon, @GroupID);
    ELSE
        UPDATE MEN_Menu
           SET ClassName=@ClassName, AssemblyName=@AssemblyName, ParentMenuID=@ParentMenuID,
               Priority=@Priority, IsVisible=1, IsWeb=@IsWeb, ViewOnWeb=@ViewOnWeb,
               isShowLayOutWeb=@IsShowLayOutWeb, IsUseMobileDevice=@IsUseMobileDevice,
               isShowInMobileLayOut=@IsShowInMobileLayOut, glyphicon=@Glyphicon, GroupID=@GroupID
         WHERE MenuID = @MenuID;

    -- tblSC_Object
    DECLARE @ObjectID int, @ParentObjectID int;
    SELECT TOP 1 @ParentObjectID = ObjectID FROM tblSC_Object WHERE Description = @ParentMenuID;
    IF @ParentObjectID IS NULL SET @ParentObjectID = 1;

    IF NOT EXISTS (SELECT 1 FROM tblSC_Object WHERE Description = @MenuID)
    BEGIN
        SET @ObjectID = ISNULL((SELECT MAX(ObjectID) FROM tblSC_Object), 0) + 1;
        INSERT INTO tblSC_Object (ObjectID, ObjectName, Description, Visible, ParentObjectID, ParentObjectRightID, ParentRight)
        VALUES (@ObjectID, @ObjectName, @MenuID, 1, @ParentObjectID, 0, 0);
    END
    ELSE BEGIN
        UPDATE tblSC_Object SET ObjectName=@ObjectName, Visible=1, ParentObjectID=@ParentObjectID
         WHERE Description = @MenuID;
        SELECT TOP 1 @ObjectID = ObjectID FROM tblSC_Object WHERE Description = @MenuID;
    END

    -- tblSC_Right_Stored
    IF NOT EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID=@ObjectID AND LoginID=@AdminLoginID)
        INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@ObjectID, @AdminLoginID, @FullAccess);
    ELSE
        UPDATE tblSC_Right_Stored SET FullAccess=@FullAccess WHERE ObjectID=@ObjectID AND LoginID=@AdminLoginID;

    -- Cache build
    EXEC dbo.sp_GenerateHTMLScript 'sp_KPIListDataCollection_html';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT '[ERROR] Line '+CAST(ERROR_LINE() AS varchar(10))+': '+ERROR_MESSAGE();
    THROW;
END CATCH
GO

-- PHASE 5: Refresh menu cache (CHỈ 1 lệnh — Rule 1)
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_KPIListDataCollection';
GO

PRINT '[SUCCESS] Migration Menu MnuKPI003 Completed!';
"@

# Read HTML Procedure Content
$htmlContent = Get-Content -Path $htmlProcPath -Raw

# Remove any existing USE statement from the content
$htmlContent = $htmlContent -replace "(?i)USE \[[a-zA-Z0-9_]+\]\s*GO\s*", ""

# Combine components into the final SQL script
$finalContent = $header + $htmlContent + $wrapper

Set-Content -Path $scriptPath -Value $finalContent -Encoding UTF8
Write-Host "Migration script created at $scriptPath"
