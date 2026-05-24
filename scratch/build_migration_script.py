import json
import os
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

pay_output_path = r"C:\Users\cuong.vu\.gemini\antigravity\brain\ec0fdd6c-0e84-4b9d-a831-c465ded71ed3\.system_generated\steps\1358\output.txt"
target_sql_path = r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\migrate_menu_task_list_20260523.sql"

try:
    # 1. Load sp_Task_TaskList_html definition from step 1358
    with open(pay_output_path, "r", encoding="utf-8") as f:
        pay_data = json.load(f)
    task_list_html_def = pay_data["rows"][0][0]
    
    # Replace FontAwesome icon with Bootstrap Icon
    # fas fa-plus -> bi bi-plus-lg
    print("Replacing FontAwesome icons in sp_Task_TaskList_html...")
    task_list_html_def_updated = task_list_html_def.replace("fas fa-plus", "bi bi-plus-lg")
    
    # Ensure it uses CREATE OR ALTER PROCEDURE instead of CREATE PROCEDURE
    task_list_html_def_updated = re.sub(
        r'^\s*CREATE\s+PROCEDURE\b',
        'CREATE OR ALTER PROCEDURE',
        task_list_html_def_updated,
        flags=re.IGNORECASE
    )
    
    # 2. Define other procedures
    sp_Task_TaskList = """
CREATE OR ALTER PROCEDURE [dbo].[sp_Task_TaskList]
 @LoginID int = null,
 @LanguageID varchar(2) = 'VN'
AS
 select html from tblHtmlScriptCache where TableName = 'sp_Task_TaskList_html' and ScreenType = -1 and LanguageID = @LanguageID
"""

    sp_Task_TaskTemplate_Approve = """
CREATE OR ALTER PROCEDURE [dbo].[sp_Task_TaskTemplate_Approve]
    @TemplateID INT,
    @ApprovalStatus INT, -- 1: Approved, 2: Rejected
    @LoginID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblTask_Templates SET
        ApprovalStatus = @ApprovalStatus
    WHERE SubTaskID = @TemplateID AND ParentTaskID = '0';

    DECLARE @Msg NVARCHAR(255) = CASE WHEN @ApprovalStatus = 1 THEN N'Đã duyệt template thành công' ELSE N'Đã từ chối template' END;
    SELECT 'SUCCESS' AS Status, @Msg AS Message;
END
"""

    sp_Task_DataSource_Project = """
CREATE OR ALTER PROCEDURE [dbo].[sp_Task_DataSource_Project]
    @LoginID    NVARCHAR(100) = '',
    @LanguageID NVARCHAR(20)  = '',
    @SearchText NVARCHAR(255) = '',
    @Id         INT = NULL,
    @Skip       INT = 0,
    @Take       INT = 2000
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ProjectID,
        ProjectName
    INTO #Filtered
    FROM tblTask_Projects
    WHERE
        (@Id IS NULL OR ProjectID = @Id)
        AND (@SearchText = '' OR ProjectName LIKE N'%' + @SearchText + N'%') AND IsActive = 1

    -- Result set 1: trang dữ liệu
    SELECT ProjectID, ProjectName
    FROM #Filtered
    ORDER BY ProjectID
    OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;

    -- Result set 2: tổng số record
    SELECT COUNT(*) AS TotalCount
    FROM #Filtered;

    DROP TABLE #Filtered;
END
"""

    sp_Task_TaskTimeLine_CheckChange = """
CREATE OR ALTER PROCEDURE [dbo].[sp_Task_TaskTimeLine_CheckChange]
AS
BEGIN
    SET NOCOUNT ON;

    -- Đếm số lượng dòng gộp với mã Checksum toàn bảng để làm mã Hash 100% không thể nhầm lẫn
    SELECT CAST(COUNT(1) AS VARCHAR(20)) + '_' + CAST(ISNULL(CHECKSUM_AGG(BINARY_CHECKSUM(*)), 0) AS VARCHAR(50)) AS StateHash
    FROM tblTask_Tasks WITH (NOLOCK)
    WHERE ISNULL(StatusID, 0) NOT IN (4,6) AND DueDate IS NOT NULL
END
"""

    # 3. Assemble unified SQL Script
    full_sql = f"""-- =========================================================================
-- MIGRATION SCRIPT: TASK LIST MENU (MnuAT001)
-- FROM Vietinsoft_Pay TO Paradise_Dev
-- CREATED AT: 2026-05-23
-- =========================================================================

-- 1. Deploy Stored Procedures
GO
PRINT 'Deploying sp_Task_TaskList...'
GO
{sp_Task_TaskList.strip()}
GO

PRINT 'Deploying sp_Task_TaskTemplate_Approve...'
GO
{sp_Task_TaskTemplate_Approve.strip()}
GO

PRINT 'Deploying sp_Task_DataSource_Project...'
GO
{sp_Task_DataSource_Project.strip()}
GO

PRINT 'Deploying sp_Task_TaskTimeLine_CheckChange...'
GO
{sp_Task_TaskTimeLine_CheckChange.strip()}
GO

PRINT 'Deploying sp_Task_TaskList_html...'
GO
{task_list_html_def_updated.strip()}
GO

-- 2. Update Menu Metadata
PRINT 'Updating MEN_Menu configuration...'
GO
IF EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = 'MnuAT001')
BEGIN
    UPDATE MEN_Menu
    SET ShortcutKeys = 'CONTROL+B'
    WHERE MenuID = 'MnuAT001';
END
GO
PRINT 'Migration script preparation done.'
"""

    with open(target_sql_path, "w", encoding="utf-8") as f:
        f.write(full_sql)
        
    print(f"Migration script successfully generated at: {target_sql_path}")
    
except Exception as e:
    print("Error:", e)
