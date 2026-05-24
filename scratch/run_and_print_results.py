import pyodbc
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

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    # 1. Print current allowance settings
    print("=== tblAllowanceSetting ===")
    cursor.execute("SELECT AllowanceCode, AllowanceName, ForSalary, IncludedIns FROM tblAllowanceSetting")
    for r in cursor.fetchall():
        print(f"Code: {r[0]:<10} | Name: {r[1]:<20} | ForSalary: {r[2]} | IncludedIns: {r[3]}")

    # 2. Print current LevelIDHistory count and sample
    cursor.execute("SELECT COUNT(*) FROM tblLevelIDHistory")
    count_before = cursor.fetchone()[0]
    print(f"\nNumber of records in tblLevelIDHistory before run: {count_before}")
    
    # 3. Print current employees salary details
    print("\nCurrent employees active salary details:")
    cursor.execute("""
        SELECT e.EmployeeID, e.FullName, sh.Salary, sh.Trans_AL, sh.Pos_AL, sh.Per_Rate, sh.csac
        FROM tblEmployee e
        OUTER APPLY (
            SELECT TOP 1 Salary, Trans_AL, Pos_AL, Per_Rate, csac
            FROM tblSalaryHistory
            WHERE EmployeeID = e.EmployeeID AND Date <= GETDATE()
            ORDER BY Date DESC, SalaryHistoryID DESC
        ) sh
        WHERE sh.Salary IS NOT NULL
    """)
    for r in cursor.fetchall():
        print(f"Emp: {r[0]:<5} | Name: {r[1]:<25} | Sal: {r[2]:<10} | Trans: {r[3]} | Pos: {r[4]} | Per: {r[5]} | csac: {r[6]}")

    # 4. Run sp_Level_AutoUpdateHistory
    print("\nRunning EXEC sp_Level_AutoUpdateHistory...")
    cursor.execute("EXEC dbo.sp_Level_AutoUpdateHistory")
    conn.commit()
    
    # 5. Print LevelIDHistory after run
    cursor.execute("SELECT COUNT(*) FROM tblLevelIDHistory")
    count_after = cursor.fetchone()[0]
    print(f"Number of records in tblLevelIDHistory after run: {count_after}")
    
    print("\nNew updates in tblLevelIDHistory:")
    cursor.execute("""
        SELECT h.EmployeeID, e.FullName, h.LevelID, l.LevelName, l.LevelRate, h.Remark, h.EffectiveDate
        FROM tblLevelIDHistory h
        INNER JOIN tblEmployee e ON h.EmployeeID = e.EmployeeID
        INNER JOIN tbllevel l ON h.LevelID = l.LevelID
        ORDER BY h.EffectiveDate DESC, h.EmployeeID ASC
    """)
    for r in cursor.fetchall():
        print(f"Emp: {r[0]:<5} | Name: {r[1]:<25} | LevelID: {r[2]:<3} | LevelName: {r[3]:<5} | Rate: {r[4]} | Remark: {r[5]} | Date: {r[6]}")
        
    conn.close()
except Exception as e:
    print(f"Error: {e}")
