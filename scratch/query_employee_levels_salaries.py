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

# 1. Query tblLevelIDHistory to see if there is any data
print("=== Records in tblLevelIDHistory ===")
try:
    cursor.execute("SELECT * FROM tblLevelIDHistory")
    cols = [col[0] for col in cursor.description]
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))
except Exception as e:
    print(f"Error: {e}")

# 2. Query tblSalaryHistory records for Level = 1
print("\n=== Employees and their current levels & salaries ===")
query = """
SELECT e.EmployeeID, e.FullName, lv.LevelID, sh.Salary, sh.Trans_AL, sh.Pos_AL
FROM tblEmployee e
OUTER APPLY (
    SELECT TOP 1 lh.LevelID
    FROM tblLevelIDHistory lh
    WHERE lh.EmployeeID = e.EmployeeID AND lh.EffectiveDate <= GETDATE()
    ORDER BY lh.EffectiveDate DESC
) lv
OUTER APPLY (
    SELECT TOP 1 s.Salary, s.Trans_AL, s.Pos_AL
    FROM tblSalaryHistory s
    WHERE s.EmployeeID = e.EmployeeID AND s.Date <= GETDATE()
    ORDER BY s.Date DESC, s.SalaryHistoryID DESC
) sh
WHERE lv.LevelID IS NOT NULL OR sh.Salary IS NOT NULL
"""
try:
    cursor.execute(query)
    cols = [col[0] for col in cursor.description]
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))
except Exception as e:
    print(f"Error: {e}")

conn.close()
