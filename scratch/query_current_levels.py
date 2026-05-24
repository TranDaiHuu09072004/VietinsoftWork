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
    
    # 1. Print all current active levels (latest in history)
    print("=== Current Active Level for each Employee ===")
    cursor.execute("""
        SELECT e.EmployeeID, e.FullName, lv.LevelID, l.LevelName, l.LevelRate
        FROM tblEmployee e
        INNER JOIN (
            SELECT EmployeeID, LevelID
            FROM (
                SELECT EmployeeID, LevelID,
                       ROW_NUMBER() OVER (PARTITION BY EmployeeID ORDER BY EffectiveDate DESC) as rn
                FROM tblLevelIDHistory
                WHERE EffectiveDate <= GETDATE()
            ) t
            WHERE rn = 1
        ) lv ON e.EmployeeID = lv.EmployeeID
        INNER JOIN tbllevel l ON lv.LevelID = l.LevelID
    """)
    rows = cursor.fetchall()
    print(f"Total employees with levels: {len(rows)}")
    for r in rows:
        print(f"Emp: {r[0]:<5} | Name: {r[1]:<25} | LevelID: {r[2]:<3} | LevelName: {r[3]:<5} | Rate: {r[4]}")
        
    # 2. Check if any employee has LevelID = 1
    cursor.execute("""
        SELECT e.EmployeeID, e.FullName, sh.Salary, sh.Trans_AL, sh.Pos_AL, sh.Per_Rate, sh.csac
        FROM tblEmployee e
        INNER JOIN (
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
            SELECT TOP 1 Salary, Trans_AL, Pos_AL, Per_Rate, csac
            FROM tblSalaryHistory
            WHERE EmployeeID = e.EmployeeID AND Date <= GETDATE()
            ORDER BY Date DESC, SalaryHistoryID DESC
        ) sh
        WHERE lv.LevelID = 1 AND sh.Salary IS NOT NULL
    """)
    rows_lvl1 = cursor.fetchall()
    print(f"\nActive employees at LevelID = 1: {len(rows_lvl1)}")
    for r in rows_lvl1:
        print(f"Emp: {r[0]:<5} | Name: {r[1]:<25} | Sal: {r[2]:<10} | Trans: {r[3]} | Pos: {r[4]} | Per: {r[5]} | csac: {r[6]}")

    conn.close()
except Exception as e:
    print(f"Error: {e}")
