import os

html_file = r"c:\Users\Huu.Tran\Downloads\VietinsoftWork\bang_theo_doi_di_ca_code_final.txt"
sql_file = r"c:\Users\Huu.Tran\Downloads\VietinsoftWork\SQL script\deploy_sp_ShiftTracking_html_20260623.sql"

with open(html_file, 'r', encoding='utf-8') as f:
    html_content = f.read()

# Replace all single quotes with double single quotes for T-SQL escaping
html_content_escaped = html_content.replace("'", "''")

sql_script = f"""SET NOCOUNT ON; SET XACT_ABORT ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_ShiftTracking_html] (@LoginID INT=3, @LanguageID VARCHAR(5)='VN', @isWeb INT=1)
AS BEGIN
    SET NOCOUNT ON;

    DECLARE @html NVARCHAR(MAX) = N'
{html_content_escaped}
';

    SELECT @html AS html;
END
GO

-- Xoá cache cũ
DELETE FROM dbo.tblHtmlScriptCache WHERE TableName = 'sp_ShiftTracking_html';
GO

-- Build cache mới cho Web
EXEC dbo.sp_GenerateHTMLScript 'sp_ShiftTracking_html';
GO

-- Verify
SELECT TableName, LanguageID, ScreenType, DATALENGTH(html) AS HtmlBytes, Version
FROM dbo.tblHtmlScriptCache WHERE TableName = 'sp_ShiftTracking_html' ORDER BY LanguageID;
GO
"""

with open(sql_file, 'w', encoding='utf-8') as f:
    f.write(sql_script)

print(f"Successfully generated {sql_file}")
