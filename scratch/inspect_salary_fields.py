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

# 1. Inspect tblEmployee for salary-related columns
print("=== Salary columns in tblEmployee ===")
cursor.execute("SELECT name FROM sys.columns WHERE object_id = OBJECT_ID('tblEmployee') AND (name LIKE '%Sal%' OR name LIKE '%Basic%' OR name LIKE '%Income%')")
for r in cursor.fetchall():
    print(r[0])

# 2. Inspect tblLabourContract columns
print("\n=== Salary columns in tblLabourContract ===")
cursor.execute("SELECT name FROM sys.columns WHERE object_id = OBJECT_ID('tblLabourContract') AND (name LIKE '%Sal%' OR name LIKE '%Basic%' OR name LIKE '%Income%')")
for r in cursor.fetchall():
    print(r[0])

# 3. Inspect tblSalaryHistory columns
print("\n=== Columns of tblSalaryHistory ===")
try:
    cursor.execute("SELECT TOP 0 * FROM tblSalaryHistory")
    cols = [col[0] for col in cursor.description]
    print(cols)
    cursor.execute("SELECT TOP 2 * FROM tblSalaryHistory")
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))
except Exception as e:
    print(f"Error: {e}")

# 4. Check tblAllowanceSetting data
print("\n=== Data in tblAllowanceSetting ===")
try:
    cursor.execute("SELECT AllowanceID, AllowanceCode, AllowanceName, IncludedIns, ForSalary FROM tblAllowanceSetting")
    cols = [col[0] for col in cursor.description]
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))
except Exception as e:
    print(f"Error: {e}")

# 5. Check tblEmployeeAllowance data
print("\n=== Data in tblEmployeeAllowance (first 5 rows) ===")
try:
    cursor.execute("SELECT TOP 5 * FROM tblEmployeeAllowance")
    cols = [col[0] for col in cursor.description]
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))
except Exception as e:
    print(f"Error: {e}")

conn.close()
