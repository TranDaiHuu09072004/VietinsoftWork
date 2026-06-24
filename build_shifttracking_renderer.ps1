$ErrorActionPreference = 'Stop'

$workspace = 'C:\Users\Huu.Tran\Downloads\VietinsoftWork'
$source = Join-Path $workspace 'bang_theo_doi_di_ca_code_final.txt'
$target = Join-Path $workspace 'SQL script\deploy_sp_ShiftTracking_html_from_final_ui_20260623.sql'

$html = Get-Content -LiteralPath $source -Raw -Encoding UTF8
$html = $html.Replace(
    'html[data-theme="dark"] .shift-monitor,',
    "html[data-theme=`"dark`"] .shift-monitor,`r`nbody.theme-dark .shift-monitor,`r`n.theme-dark .shift-monitor,`r`n.dx-theme-generic-dark .shift-monitor,`r`n[data-bs-theme=`"dark`"] .shift-monitor,"
)

$bytes = [System.Text.Encoding]::Unicode.GetBytes($html)
$base64 = [Convert]::ToBase64String($bytes)
$chunks = for ($i = 0; $i -lt $base64.Length; $i += 3000) {
    $length = [Math]::Min(3000, $base64.Length - $i)
    $base64.Substring($i, $length)
}

$chunkSql = ($chunks | ForEach-Object { "    SET @Base64 += N'$_';" }) -join "`r`n"

$sql = @"
-- =============================================================================
-- DEPLOY UI: sp_ShiftTracking_html
-- SOURCE: bang_theo_doi_di_ca_code_final.txt
-- DATE: 2026-06-23
-- User review và chạy thủ công. Không cấp thêm quyền.
-- =============================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_ShiftTracking_html
    @LoginID INT = NULL,
    @LanguageID VARCHAR(5) = 'VN',
    @isWeb INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Base64 NVARCHAR(MAX) = N'';
$chunkSql

    DECLARE @HtmlBytes VARBINARY(MAX);
    DECLARE @html NVARCHAR(MAX);

    SET @HtmlBytes =
        CAST(N'' AS XML).value(
            'xs:base64Binary(sql:variable("@Base64"))',
            'VARBINARY(MAX)'
        );
    SET @html = CONVERT(NVARCHAR(MAX), @HtmlBytes);

    SELECT @html AS html;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_ShiftTracking_Web
    @LoginID INT = NULL,
    @LanguageID VARCHAR(5) = 'VN'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @html NVARCHAR(MAX);
    SELECT TOP (1) @html = html
    FROM dbo.tblHtmlScriptCache
    WHERE TableName = N'sp_ShiftTracking_html'
      AND LanguageID = ISNULL(NULLIF(@LanguageID, ''), 'VN')
      AND ScreenType = '-1'
    ORDER BY Version DESC;

    IF @html IS NULL OR @html = N''
    BEGIN
        DECLARE @Renderer TABLE (html NVARCHAR(MAX));
        INSERT INTO @Renderer (html)
        EXEC dbo.sp_ShiftTracking_html
             @LoginID = @LoginID,
             @LanguageID = @LanguageID,
             @isWeb = 1;
        SELECT TOP (1) @html = html FROM @Renderer;
    END

    -- Pure HTML route đọc html; DataSetting route hiện tại đọc htmlGet.
    SELECT @html AS html,
           @html AS htmlGet;
END
GO

UPDATE dbo.MEN_Menu
SET ClassName = N'sp_ShiftTracking_Web',
    AssemblyName = N'DataSetting',
    IsWeb = 1,
    ViewOnWeb = 1,
    isShowLayOutWeb = 1,
    IsUseMobileDevice = 0,
    isShowInMobileLayOut = 0
WHERE MenuID = N'MnuTAD091';
GO

IF EXISTS
(
    SELECT 1
    FROM dbo.tblDataSetting
    WHERE LOWER(TableName) = LOWER(N'sp_ShiftTracking_Web')
)
BEGIN
    UPDATE dbo.tblDataSetting
    SET ViewName = N'sp_ShiftTracking_Web',
        IsProcedure = 1,
        IsShowLayout = 1,
        ReadOnly = 1,
        AllowAdd = 0,
        ColumnDataType = N'htmlGet&ViewHtml',
        ColumnOrderBy = N'htmlGet&0'
    WHERE LOWER(TableName) = LOWER(N'sp_ShiftTracking_Web');
END
ELSE
BEGIN
    INSERT INTO dbo.tblDataSetting
        (TableName, ViewName, IsProcedure, IsShowLayout,
         ReadOnly, AllowAdd, ColumnDataType, ColumnOrderBy)
    VALUES
        ('sp_ShiftTracking_Web', N'sp_ShiftTracking_Web', 1, 1,
         1, 0, N'htmlGet&ViewHtml', N'htmlGet&0');
END
GO

DELETE FROM dbo.tblDataSettingLayout
WHERE LOWER(TableName) = LOWER(N'sp_ShiftTracking_Web');

INSERT INTO dbo.tblDataSettingLayout
    (TableName, Name, ControlName, NamePa, Type,
     Lx, Ly, Sx, Sy, ShowCaption, TypeLayout,
     ControlType, WidthPercentage)
VALUES
    ('sp_ShiftTracking_Web', 'root', '', '', 'g',
     0, 0, 100, 100, 0, '6', '', 100),
    ('sp_ShiftTracking_Web', 'lblhtmlGet', 'htmlGet', 'root', 'i',
     0, 0, 100, 100, 0, '6', 'ParadiseWebView2', 100);
GO

DELETE FROM dbo.tblHtmlScriptCache
WHERE TableName = N'sp_ShiftTracking_html';

EXEC dbo.sp_GenerateHTMLScript N'sp_ShiftTracking_html';
EXEC dbo.sp_Men_Menu_AfterSave_Simple
     @ClassName = N'sp_ShiftTracking_Web';
GO

SELECT MenuID, ClassName, IsWeb, ViewOnWeb, isShowLayOutWeb
FROM dbo.MEN_Menu
WHERE MenuID = N'MnuTAD091';

SELECT TableName, LanguageID, ScreenType,
       DATALENGTH(html) AS HtmlBytes
FROM dbo.tblHtmlScriptCache
WHERE TableName = N'sp_ShiftTracking_html'
ORDER BY LanguageID;
GO
"@

[System.IO.File]::WriteAllText($target, $sql, [System.Text.UTF8Encoding]::new($true))
Write-Output $target
