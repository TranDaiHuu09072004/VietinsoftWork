import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

sp_ddl = """
CREATE OR ALTER PROCEDURE dbo.sp_Level_AutoUpdateHistory
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Identify allowance columns to sum (ForSalary = 1, IncludedIns IS NULL or 0)
    DECLARE @AllowanceSum NVARCHAR(MAX) = N'';
    
    SELECT @AllowanceSum = @AllowanceSum + N' + ISNULL(' + QUOTENAME(c.COLUMN_NAME) + N', 0)'
    FROM tblAllowanceSetting a
    INNER JOIN INFORMATION_SCHEMA.COLUMNS c 
        ON a.AllowanceCode = c.COLUMN_NAME 
        AND c.TABLE_NAME = 'tblSalaryHistory'
    WHERE a.ForSalary = 1 AND (a.IncludedIns IS NULL OR a.IncludedIns = 0);

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
"""

try:
    print("Connecting to Paradise_Dev...")
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    print("Compiling robust stored procedure in Paradise_Dev...")
    cursor.execute(sp_ddl)
    conn.commit()
    print("Compilation successful.")
    
    # Run the procedure to check
    print("Executing sp_Level_AutoUpdateHistory in Paradise_Dev...")
    cursor.execute("EXEC dbo.sp_Level_AutoUpdateHistory")
    conn.commit()
    print("Execution successful.")
    
    conn.close()
except Exception as e:
    print(f"Error: {e}")
