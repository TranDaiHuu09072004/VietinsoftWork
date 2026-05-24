import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Connection details for Paradise_Dev
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

cursor = conn.cursor()

try:
    print("=== Step 1: Creating/Compiling Stored Procedure sp_Level_AutoUpdateHistory ===")
    
    sp_ddl = """
    CREATE OR ALTER PROCEDURE dbo.sp_Level_AutoUpdateHistory
    AS
    BEGIN
        SET NOCOUNT ON;

        -- 1. Calculate Standard Salary (Mức lương tiêu chuẩn)
        DECLARE @StandardSalary DECIMAL(18, 4);

        SELECT @StandardSalary = MAX(sh.Salary + ISNULL(sh.Trans_AL, 0) + ISNULL(sh.Pos_AL, 0))
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
            SELECT TOP 1 Salary, Trans_AL, Pos_AL
            FROM tblSalaryHistory
            WHERE EmployeeID = e.EmployeeID AND Date <= GETDATE()
            ORDER BY Date DESC, SalaryHistoryID DESC
        ) sh
        WHERE lv.LevelID = 1 AND sh.Salary IS NOT NULL;

        -- Fallback if no Level = 1 exists or standard salary is zero/null
        IF @StandardSalary IS NULL OR @StandardSalary = 0
            SET @StandardSalary = 8000000.0000;

        -- 2. Calculate Total Salary, LevelRate, and Round for each employee
        -- Total Salary = Basic Salary + fixed/regular allowances (IncludedIns = 0 or NULL, e.g. Trans_AL, Pos_AL)
        SELECT 
            e.EmployeeID,
            sh.Salary + ISNULL(sh.Trans_AL, 0) + ISNULL(sh.Pos_AL, 0) AS TotalSalary,
            CAST((sh.Salary + ISNULL(sh.Trans_AL, 0) + ISNULL(sh.Pos_AL, 0)) / @StandardSalary AS DECIMAL(18, 4)) AS RawRate,
            -- Rounding logic: V = TotalSalary / StandardSalary
            -- If (V*10) - FLOOR(V*10) > 0.5, CEILING(V*10)/10, else FLOOR(V*10)/10
            CASE 
                WHEN ((sh.Salary + ISNULL(sh.Trans_AL, 0) + ISNULL(sh.Pos_AL, 0)) / @StandardSalary * 10.0) - FLOOR((sh.Salary + ISNULL(sh.Trans_AL, 0) + ISNULL(sh.Pos_AL, 0)) / @StandardSalary * 10.0) > 0.5
                THEN CEILING((sh.Salary + ISNULL(sh.Trans_AL, 0) + ISNULL(sh.Pos_AL, 0)) / @StandardSalary * 10.0) / 10.0
                ELSE FLOOR((sh.Salary + ISNULL(sh.Trans_AL, 0) + ISNULL(sh.Pos_AL, 0)) / @StandardSalary * 10.0) / 10.0
            END AS LevelRate
        INTO #EmpCalculatedRate
        FROM tblEmployee e
        OUTER APPLY (
            SELECT TOP 1 Salary, Trans_AL, Pos_AL
            FROM tblSalaryHistory
            WHERE EmployeeID = e.EmployeeID AND Date <= GETDATE()
            ORDER BY Date DESC, SalaryHistoryID DESC
        ) sh
        WHERE sh.Salary IS NOT NULL;

        -- 3. Join with tbllevel to find matching LevelID
        SELECT 
            ec.EmployeeID,
            l.LevelID AS NewLevelID,
            ec.LevelRate
        INTO #EmpNewLevel
        FROM #EmpCalculatedRate ec
        INNER JOIN tbllevel l ON ec.LevelRate = l.LevelRate;

        -- 4. Insert into tblLevelIDHistory only when there is a change
        INSERT INTO tblLevelIDHistory (EmployeeID, LevelID, EffectiveDate, Remark)
        SELECT 
            nl.EmployeeID,
            nl.NewLevelID,
            CAST(GETDATE() AS DATE),
            N'Tự động cập nhật cấp bậc theo lương thực tế (LevelRate: ' + CAST(nl.LevelRate AS NVARCHAR(20)) + N')'
        FROM #EmpNewLevel nl
        OUTER APPLY (
            -- Get the current active Level for the employee
            SELECT TOP 1 lh.LevelID
            FROM tblLevelIDHistory lh
            WHERE lh.EmployeeID = nl.EmployeeID AND lh.EffectiveDate <= GETDATE()
            ORDER BY lh.EffectiveDate DESC
        ) curr
        WHERE curr.LevelID IS NULL OR curr.LevelID <> nl.NewLevelID;

    END
    """
    
    cursor.execute(sp_ddl)
    conn.commit()
    print("Stored procedure sp_Level_AutoUpdateHistory compiled successfully.")

    # Let's clean tblLevelIDHistory first to ensure clean test state
    print("\n=== Clearing existing records in tblLevelIDHistory for clean test ===")
    cursor.execute("DELETE FROM tblLevelIDHistory")
    conn.commit()

    print("\n=== Step 2: Executing sp_Level_AutoUpdateHistory (First Run) ===")
    cursor.execute("EXEC dbo.sp_Level_AutoUpdateHistory")
    conn.commit()
    print("First run completed.")

    print("\n=== Step 3: Checking records in tblLevelIDHistory (First Run Output) ===")
    cursor.execute("""
        SELECT h.EmployeeID, e.FullName, h.LevelID, l.LevelName, l.LevelRate, h.EffectiveDate, h.Remark
        FROM tblLevelIDHistory h
        INNER JOIN tblEmployee e ON h.EmployeeID = e.EmployeeID
        INNER JOIN tbllevel l ON h.LevelID = l.LevelID
        ORDER BY h.EmployeeID
    """)
    cols = [col[0] for col in cursor.description]
    first_run_rows = cursor.fetchall()
    for r in first_run_rows:
        print(dict(zip(cols, r)))
    print(f"Total inserted records: {len(first_run_rows)}")

    print("\n=== Step 4: Executing sp_Level_AutoUpdateHistory (Second Run - Idempotency Check) ===")
    cursor.execute("EXEC dbo.sp_Level_AutoUpdateHistory")
    conn.commit()
    print("Second run completed.")

    print("\n=== Step 5: Checking records in tblLevelIDHistory (Second Run Output) ===")
    cursor.execute("""
        SELECT h.EmployeeID, e.FullName, h.LevelID, l.LevelName, l.LevelRate, h.EffectiveDate, h.Remark
        FROM tblLevelIDHistory h
        INNER JOIN tblEmployee e ON h.EmployeeID = e.EmployeeID
        INNER JOIN tbllevel l ON h.LevelID = l.LevelID
        ORDER BY h.EmployeeID
    """)
    second_run_rows = cursor.fetchall()
    print(f"Total records in history: {len(second_run_rows)}")
    if len(first_run_rows) == len(second_run_rows):
        print("SUCCESS: Stored procedure is IDEMPOTENT (no duplicate history records inserted when level doesn't change).")
    else:
        print("FAIL: Duplicate records inserted!")

except Exception as e:
    print(f"An error occurred: {e}")
    conn.rollback()

finally:
    conn.close()
