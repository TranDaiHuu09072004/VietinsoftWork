import pyodbc
import datetime
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Vietinsoft_ForTest;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

print("Connecting to Vietinsoft_ForTest...")
conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

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

        -- Insert into tblLevelIDHistory only when there is a change
        INSERT INTO tblLevelIDHistory (EmployeeID, LevelID, EffectiveDate, Remark)
        SELECT 
            nl.EmployeeID,
            nl.NewLevelID,
            CAST(GETDATE() AS DATE),
            N''Tự động cập nhật cấp bậc theo lương thực tế (LevelRate: '' + CAST(nl.LevelRate AS NVARCHAR(20)) + N'')''
        FROM #EmpNewLevel nl
        OUTER APPLY (
            -- Get the current active Level for the employee
            SELECT TOP 1 lh.LevelID
            FROM tblLevelIDHistory lh
            WHERE lh.EmployeeID = nl.EmployeeID AND lh.EffectiveDate <= GETDATE()
            ORDER BY lh.EffectiveDate DESC
        ) curr
        WHERE curr.LevelID IS NULL OR curr.LevelID <> nl.NewLevelID;
    ';

    EXEC sp_executesql @Sql;
END
"""

try:
    print("Compiling dynamic stored procedure sp_Level_AutoUpdateHistory...")
    cursor.execute(sp_ddl)
    conn.commit()
    print("Compilation successful.")

    # Clear history
    cursor.execute("DELETE FROM tblLevelIDHistory")
    conn.commit()

    # Insert test salary history with Per_Rate
    # Employee 003: 8,000,000 basic, Per_Rate = 0 -> Total = 8,000,000 -> Rate 1.0 (Gb1)
    # Employee 014: 10,000,000 basic, Per_Rate = 400,000 -> Total = 10,400,000 -> Rate 1.3 (Gb4)
    # Also verify that Trans_AL and Pos_AL (e.g. 500,000) are NOT added to the total salary!
    today = datetime.date.today().strftime('%Y-%m-%d')
    print("\nInserting test salary history with Per_Rate and Trans_AL...")
    cursor.execute("""
        INSERT INTO tblSalaryHistory (EmployeeID, Date, Salary, Trans_AL, Pos_AL, Per_Rate, csac, InsSalary, NETSalary, SalCalRuleID)
        VALUES 
        ('003', ?, 8000000.0000, 300000.0000, 500000.0000, 0.0000, 0.0000, 0.0000, 0.0000, 1),
        ('014', ?, 10000000.0000, 300000.0000, 500000.0000, 400000.0000, 0.0000, 0.0000, 0.0000, 1)
    """, (today, today))
    conn.commit()

    cursor.execute("SELECT SalaryHistoryID FROM tblSalaryHistory WHERE Date = ? AND Salary IN (8000000, 10000000)", (today,))
    inserted_ids = [row[0] for row in cursor.fetchall()]
    print(f"Temporary SalaryHistoryIDs: {inserted_ids}")

    # Run procedure
    print("\nRunning EXEC sp_Level_AutoUpdateHistory...")
    cursor.execute("EXEC dbo.sp_Level_AutoUpdateHistory")
    conn.commit()

    # Check results
    print("\nChecking level history inserts:")
    cursor.execute("""
        SELECT h.EmployeeID, e.FullName, h.LevelID, l.LevelName, l.LevelRate, h.Remark
        FROM tblLevelIDHistory h
        INNER JOIN tblEmployee e ON h.EmployeeID = e.EmployeeID
        INNER JOIN tbllevel l ON h.LevelID = l.LevelID
    """)
    rows = cursor.fetchall()
    for row in rows:
        print(f" - Emp: {row[0]} ({row[1]}), LevelID: {row[2]} ({row[3]}), Rate: {row[4]}, Remark: {row[5]}")

    # Clean up
    if inserted_ids:
        print("\nCleaning up temporary salary records...")
        id_placeholders = ",".join(["?"] * len(inserted_ids))
        cursor.execute(f"DELETE FROM tblSalaryHistory WHERE SalaryHistoryID IN ({id_placeholders})", inserted_ids)
        conn.commit()
        print("Cleanup completed.")

except Exception as e:
    print(f"An error occurred: {e}")
    conn.rollback()
finally:
    conn.close()
