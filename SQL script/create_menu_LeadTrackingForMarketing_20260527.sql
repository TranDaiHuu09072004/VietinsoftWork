-- =====================================================================
-- Create menu: Theo doi lead marketing (Paradise_dev)
-- Date: 2026-05-27
-- Note: Review before running. This script is idempotent for metadata.
-- =====================================================================

USE [Paradise_dev];
GO

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @MenuTextVN NVARCHAR(4000) = N'Theo dõi lead marketing';
    DECLARE @MenuTextEN NVARCHAR(4000) = N'Marketing Lead Tracking';
    DECLARE @ClassName  VARCHAR(100)   = 'sp_LeadTrackingForMarketing';
    DECLARE @ParentMenu VARCHAR(100)   = 'MnuKPI000';
    DECLARE @Assembly   VARCHAR(100)   = 'DataSetting';

    -- Create menu + rights for LoginID 3 and 40 (if not exist yet)
    EXEC dbo.sp_s_CreateMenu
         @Text        = @MenuTextVN,
         @TextEN      = @MenuTextEN,
         @ClassName   = @ClassName,
         @ParentMenuID= @ParentMenu,
         @AssemblyName= @Assembly,
         @Option      = 1,
         @LoginIDList = '3,40';

    DECLARE @MenuID VARCHAR(100);
    SELECT @MenuID = MenuID FROM MEN_Menu WHERE ClassName = @ClassName;
    IF @MenuID IS NULL
    BEGIN
        RAISERROR('Menu not found after sp_s_CreateMenu. Please verify input.', 16, 1);
    END

    -- Rule 2: flags for HTML-rendered menu
    UPDATE MEN_Menu
       SET IsVisible           = 1,
           IsWeb               = 0,
           ViewOnWeb           = 0,
           isShowLayOutWeb     = 0,
           IsUseMobileDevice   = 1,
           isShowInMobileLayOut= 0
     WHERE ClassName = @ClassName;

    -- Metadata: tblDataSetting (ensure row + required fields)
    IF NOT EXISTS (SELECT 1 FROM tblDataSetting WHERE TableName = @ClassName)
    BEGIN
        INSERT INTO tblDataSetting
            (TableName, ViewName, IsProcedure, IsShowLayout, ColumnOrderBy, ColumnDataType,
             ColumnHide, ControlHiddenInShowLayout)
        VALUES
            (@ClassName, @ClassName, 1, 1, 'html&0', 'html&ViewHtml',
             'isReadOnlyRow,dtftxxENGColumns',
             'grdTableEditor,txtFilter,btnReload,btnFWDelete,btnFWReset,btnExport,btnFWSave,btnFWAdd,isReadOnlyRow,dtftxxENGColumns');
    END

    UPDATE tblDataSetting
       SET ViewName                 = @ClassName,
           IsProcedure              = 1,
           IsShowLayout             = 1,
           ColumnOrderBy            = 'html&0',
           ColumnDataType           = 'html&ViewHtml',
           ColumnHide               = 'isReadOnlyRow,dtftxxENGColumns',
           ControlHiddenInShowLayout= 'grdTableEditor,txtFilter,btnReload,btnFWDelete,btnFWReset,btnExport,btnFWSave,btnFWAdd,isReadOnlyRow,dtftxxENGColumns'
     WHERE TableName = @ClassName;

    -- Metadata: tblDataSettingLayout (root + html item)
    IF NOT EXISTS (SELECT 1 FROM tblDataSettingLayout WHERE TableName = @ClassName AND Name = 'root')
    BEGIN
        INSERT INTO tblDataSettingLayout
            (TableName, Name, ControlName, NamePa, Type, TypeLayout, ControlType)
        VALUES
            (@ClassName, 'root', '', '', 'g', '6', '');
    END

    IF NOT EXISTS (SELECT 1 FROM tblDataSettingLayout WHERE TableName = @ClassName AND Name = 'lblhtml')
    BEGIN
        INSERT INTO tblDataSettingLayout
            (TableName, Name, ControlName, NamePa, Type, TypeLayout, ControlType)
        VALUES
            (@ClassName, 'lblhtml', 'html', 'root', 'i', '6', 'ParadiseWebView2');
    END

        COMMIT TRANSACTION;
END TRY
BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
END CATCH
GO

-- Create stub renderer if missing
IF OBJECT_ID('dbo.sp_LeadTrackingForMarketing_html', 'P') IS NULL
        EXEC('CREATE PROCEDURE dbo.sp_LeadTrackingForMarketing_html AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.sp_LeadTrackingForMarketing_html
(
        @LoginID    INT        = 3,
        @LanguageID VARCHAR(5) = 'VN',
        @isWeb      INT        = 1
)
AS
BEGIN
        SET NOCOUNT ON;

        DECLARE @title   NVARCHAR(200) = CASE WHEN @LanguageID = 'EN'
                                                    THEN N'Marketing Lead Tracking'
                                                    ELSE N'Theo dõi lead marketing' END;
        DECLARE @note    NVARCHAR(300) = CASE WHEN @LanguageID = 'EN'
                                                                                    THEN N'Placeholder screen. UI and data will be added later.'
                                                    ELSE N'Màn hình tạm thời. Giao diện và dữ liệu sẽ được bổ sung sau.' END;
        DECLARE @html NVARCHAR(MAX);

        SET @html = N'
<div class="lead-mkt-page">
    <style>
        .lead-mkt-page {
            padding: var(--paradise-space-5);
            color: var(--paradise-text-body);
            font-family: var(--paradise-font-family-base);
        }
        .lead-mkt-card {
            background-color: var(--paradise-card-bg);
            border: var(--paradise-card-border);
            border-radius: var(--paradise-card-radius);
            box-shadow: var(--paradise-card-shadow);
            padding: var(--paradise-card-padding);
            display: grid;
            gap: var(--paradise-space-2);
            max-width: 720px;
        }
        .lead-mkt-title {
            margin: 0;
            color: var(--paradise-color-primary);
            font-size: var(--paradise-font-heading-main);
            font-weight: var(--font-weight-bold);
        }
        .lead-mkt-note {
            margin: 0;
            color: var(--paradise-text-muted);
            font-size: var(--paradise-font-body1);
            line-height: var(--line-height-lg);
        }
    </style>
    <div class="lead-mkt-card">
        <h2 class="lead-mkt-title">' + @title + N'</h2>
        <p class="lead-mkt-note">' + @note + N'</p>
    </div>
</div>';

        MERGE dbo.tblHtmlScriptCache AS t
        USING (SELECT N'sp_LeadTrackingForMarketing_html' AS TableName,
                                    @LanguageID AS LanguageID,
                                    '-1' AS ScreenType) AS s
        ON t.TableName = s.TableName
             AND t.LanguageID = s.LanguageID
             AND ISNULL(t.ScreenType, '-1') = s.ScreenType
        WHEN MATCHED THEN
                UPDATE SET html = @html,
                                     HtmlParadise = N'',
                                     paradiseJs = N'',
                                     Version = '1',
                                     VersionData = N'',
                                     ScreenType = s.ScreenType
        WHEN NOT MATCHED THEN
                INSERT (TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData)
                VALUES (s.TableName, s.LanguageID, s.ScreenType, @html, N'', N'', '1', N'');
END
GO

-- Create stub wrapper if missing
IF OBJECT_ID('dbo.sp_LeadTrackingForMarketing', 'P') IS NULL
        EXEC('CREATE PROCEDURE dbo.sp_LeadTrackingForMarketing AS BEGIN SET NOCOUNT ON; END');
GO

ALTER PROCEDURE dbo.sp_LeadTrackingForMarketing
(
        @LoginID    INT        = 3,
        @LanguageID VARCHAR(5) = 'VN',
        @isWeb      INT        = 1
)
AS
BEGIN
        SET NOCOUNT ON;
        SELECT TOP 1 html
        FROM dbo.tblHtmlScriptCache
        WHERE TableName = 'sp_LeadTrackingForMarketing_html'
            AND ISNULL(ScreenType, '-1') = '-1'
            AND LanguageID = @LanguageID;
END
GO

-- Build cache + refresh menu tree
EXEC dbo.sp_GenerateHTMLScript 'sp_LeadTrackingForMarketing_html';
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_LeadTrackingForMarketing';
GO
