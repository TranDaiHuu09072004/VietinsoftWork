-- =================================================================================
-- MIGRATION SCRIPT: REDESIGN LEVEL SYSTEM & AUTO UPDATE LEVEL HISTORY
-- Target Database: Vietinsoft_Pay (Production)
-- Date: 2026-05-22
-- =================================================================================

-- STEP 1: Add LevelRate column to tbllevel if it does not exist
IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'tbllevel' AND COLUMN_NAME = 'LevelRate'
)
BEGIN
    PRINT 'Adding LevelRate column to tbllevel...';
    ALTER TABLE tbllevel ADD LevelRate DECIMAL(10, 4) NOT NULL DEFAULT 1.0000;
END
ELSE
BEGIN
    PRINT 'LevelRate column already exists in tbllevel.';
END
GO

-- STEP 2: Add CHECK constraint to tbllevel if it does not exist
IF NOT EXISTS (
    SELECT 1 
    FROM sys.check_constraints 
    WHERE name = 'CK_tbllevel_LevelRate_Positive' AND parent_object_id = OBJECT_ID('tbllevel')
)
BEGIN
    PRINT 'Adding CHECK constraint CK_tbllevel_LevelRate_Positive...';
    ALTER TABLE tbllevel ADD CONSTRAINT CK_tbllevel_LevelRate_Positive CHECK (LevelRate > 0);
END
ELSE
BEGIN
    PRINT 'CHECK constraint CK_tbllevel_LevelRate_Positive already exists.';
END
GO

-- STEP 3: Populate/Merge 91 Level records (LevelRate 1.0 to 10.0) into tbllevel
PRINT 'Merging 91 level records into tbllevel...';
GO
WITH LevelCTE AS (
    SELECT 
        1 AS LevelID,
        CAST('Gb1' AS NVARCHAR(50)) AS LevelName,
        CAST('Gb1' AS NVARCHAR(50)) AS LevelNameEN,
        CAST(1.0 AS DECIMAL(10, 4)) AS LevelRate
    UNION ALL
    SELECT 
        LevelID + 1,
        CAST('Gb' + CAST(LevelID + 1 AS NVARCHAR(10)) AS NVARCHAR(50)) AS LevelName,
        CAST('Gb' + CAST(LevelID + 1 AS NVARCHAR(10)) AS NVARCHAR(50)) AS LevelNameEN,
        CAST(LevelRate + 0.1 AS DECIMAL(10, 4)) AS LevelRate
    FROM LevelCTE
    WHERE LevelID < 91
)
MERGE INTO tbllevel AS target
USING LevelCTE AS source
ON target.LevelID = source.LevelID
WHEN MATCHED THEN
    UPDATE SET 
        target.LevelName = source.LevelName,
        target.LevelNameEN = source.LevelNameEN,
        target.LevelRate = source.LevelRate
WHEN NOT MATCHED THEN
    INSERT (LevelID, LevelName, LevelNameEN, Note, LevelRate)
    VALUES (source.LevelID, source.LevelName, source.LevelNameEN, NULL, source.LevelRate)
OPTION (MAXRECURSION 100);
GO
PRINT 'Levels merged successfully.';
GO

-- STEP 4: Create or Alter Stored Procedure sp_Level_AutoUpdateHistory
PRINT 'Creating/Updating stored procedure sp_Level_AutoUpdateHistory...';
GO

CREATE OR ALTER PROCEDURE dbo.sp_Level_AutoUpdateHistory
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Identify allowance columns to sum
    DECLARE @AllowanceSum NVARCHAR(MAX) = N'';
    
    SELECT @AllowanceSum = @AllowanceSum + N' + ISNULL(' + QUOTENAME(c.COLUMN_NAME) + N', 0)'
    FROM tblAllowanceSetting a 
    INNER JOIN tblAllowanceRule r ON a.AllowanceRuleID = r.AllowanceRuleID
    INNER JOIN INFORMATION_SCHEMA.COLUMNS c 
        ON a.AllowanceCode = c.COLUMN_NAME 
        AND c.TABLE_NAME = 'tblSalaryHistory'
    WHERE (r.FullPackage = 1 OR r.DivideToSTD_WD = 1 OR r.DivideTo > 15) AND (a.IncludedIns IS NULL OR a.IncludedIns = 0);

    -- 2. Build and execute dynamic SQL
    DECLARE @Sql NVARCHAR(MAX);
    SET @Sql = N'
        -- Calculate Standard Salary (Mức lương tiêu chuẩn)
        DECLARE @StandardSalary DECIMAL(18, 4);

        SELECT @StandardSalary = MAX(sh.Salary' + @AllowanceSum + N')
        FROM tblEmployee e
        INNER JOIN (
            -- Get the current active Level for each employee
            SELECT EmployeeID, LevelID
            FROM (
                SELECT EmployeeID, LevelID,
                       ROW_NUMBER() OVER (PARTITION BY EmployeeID ORDER BY EffectiveDate DESC) as rn
                FROM tblLevelIDHistory
                WHERE EffectiveDate <= GETDATE()
            ) t
            WHERE rn = 1
        ) lv ON e.EmployeeID = lv.EmployeeID
        OUTER APPLY (
            -- Get current active salary record
            SELECT TOP 1 *
            FROM tblSalaryHistory
            WHERE EmployeeID = e.EmployeeID AND Date <= GETDATE()
            ORDER BY Date DESC, SalaryHistoryID DESC
        ) sh
        WHERE lv.LevelID = 1 AND sh.Salary IS NOT NULL;

        -- Fallback if no Level = 1 exists or standard salary is zero/null
        IF @StandardSalary IS NULL OR @StandardSalary = 0
            SET @StandardSalary = 8000000.0000;

        -- Calculate Total Salary, LevelRate, and Round for each employee
        SELECT 
            e.EmployeeID,
            sh.Salary' + @AllowanceSum + N' AS TotalSalary,
            CAST((sh.Salary' + @AllowanceSum + N') / @StandardSalary AS DECIMAL(18, 4)) AS RawRate,
            -- Rounding logic: V = TotalSalary / StandardSalary
            -- If (V*10) - FLOOR(V*10) > 0.5, CEILING(V*10)/10, else FLOOR(V*10)/10
            CASE 
                WHEN ((sh.Salary' + @AllowanceSum + N') / @StandardSalary * 10.0) - FLOOR((sh.Salary' + @AllowanceSum + N') / @StandardSalary * 10.0) > 0.5
                THEN CEILING((sh.Salary' + @AllowanceSum + N') / @StandardSalary * 10.0) / 10.0
                ELSE FLOOR((sh.Salary' + @AllowanceSum + N') / @StandardSalary * 10.0) / 10.0
            END AS LevelRate
        INTO #EmpCalculatedRate
        FROM tblEmployee e
        OUTER APPLY (
            SELECT TOP 1 *
            FROM tblSalaryHistory
            WHERE EmployeeID = e.EmployeeID AND Date <= GETDATE()
            ORDER BY Date DESC, SalaryHistoryID DESC
        ) sh
        WHERE sh.Salary IS NOT NULL;

        -- Join with tbllevel to find matching LevelID
        SELECT 
            ec.EmployeeID,
            l.LevelID AS NewLevelID,
            ec.LevelRate
        INTO #EmpNewLevel
        FROM #EmpCalculatedRate ec
        INNER JOIN tbllevel l ON ec.LevelRate = l.LevelRate;

        -- First, identify the latest level *before* today for each employee.
        SELECT 
            nl.EmployeeID,
            nl.NewLevelID,
            nl.LevelRate,
            prev.LevelID AS LastLevelID
        INTO #EmpLevelCompare
        FROM #EmpNewLevel nl
        OUTER APPLY (
            -- Get the most recent level record before today (EffectiveDate < today)
            SELECT TOP 1 lh.LevelID
            FROM tblLevelIDHistory lh
            WHERE lh.EmployeeID = nl.EmployeeID 
              AND lh.EffectiveDate < CAST(GETDATE() AS DATE)
            ORDER BY lh.EffectiveDate DESC
        ) prev;

        -- Case 1: The calculated level is different from the level before today.
        -- We must ensure a record exists for today with the new level.
        -- We use MERGE to insert it if it doesn''t exist for today, or update it if it does.
        MERGE INTO tblLevelIDHistory AS target
        USING (
            SELECT EmployeeID, NewLevelID, LevelRate 
            FROM #EmpLevelCompare 
            WHERE LastLevelID IS NULL OR LastLevelID <> NewLevelID
        ) AS source
        ON target.EmployeeID = source.EmployeeID AND target.EffectiveDate = CAST(GETDATE() AS DATE)
        WHEN MATCHED THEN
            UPDATE SET target.LevelID = source.NewLevelID,
                       target.Remark = N''Tự động cập nhật cấp bậc theo lương thực tế (LevelRate: '' + CAST(source.LevelRate AS NVARCHAR(20)) + N'')''
        WHEN NOT MATCHED THEN
            INSERT (EmployeeID, LevelID, EffectiveDate, Remark)
            VALUES (source.EmployeeID, source.NewLevelID, CAST(GETDATE() AS DATE), N''Tự động cập nhật cấp bậc theo lương thực tế (LevelRate: '' + CAST(source.LevelRate AS NVARCHAR(20)) + N'')'');

        -- Case 2: The calculated level is the same as the level before today.
        -- If a record exists for today, we should delete it so the employee''s level
        -- correctly rolls back/remains as the previous level without redundant same-level history records.
        DELETE target
        FROM tblLevelIDHistory target
        INNER JOIN #EmpLevelCompare source 
            ON target.EmployeeID = source.EmployeeID 
            AND target.EffectiveDate = CAST(GETDATE() AS DATE)
        WHERE source.LastLevelID = source.NewLevelID;
    ';

    EXEC sp_executesql @Sql;
END
GO
PRINT 'Stored procedure sp_Level_AutoUpdateHistory compiled successfully.';
GO
