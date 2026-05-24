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

# 1. Search for allowance and salary tables
print("=== Allowance/Salary tables in Paradise_Dev ===")
cursor.execute("SELECT name FROM sys.tables WHERE name LIKE '%Allowance%' OR name LIKE '%Sal%' ORDER BY name")
for r in cursor.fetchall():
    print(r[0])

# 2. Columns of tblLabourContract
print("\n=== Columns of tblLabourContract ===")
try:
    cursor.execute("SELECT TOP 0 * FROM tblLabourContract")
    cols = [col[0] for col in cursor.description]
    print([c for c in cols if 'Sal' in c or 'Basic' in c or 'Pay' in c or 'Amt' in c])
except Exception as e:
    print(f"Error: {e}")

# 3. Columns of tblEmployeeAllowance
print("\n=== Columns of tblEmployeeAllowance ===")
try:
    cursor.execute("SELECT TOP 0 * FROM tblEmployeeAllowance")
    cols = [col[0] for col in cursor.description]
    print(cols)
except Exception as e:
    print(f"Error: {e}")

# 4. Check for allowance master table
print("\n=== Table tblAllowance or tblAllowanceList or tblMST_Allowance ===")
for t in ['tblAllowance', 'tblAllowanceList', 'tblMST_Allowance', 'tblAllowanceSetting', 'tblPR_Allowance']:
    try:
        cursor.execute(f"SELECT TOP 0 * FROM {t}")
        print(f"Table {t} columns:", [col[0] for col in cursor.description])
    except Exception:
        pass

conn.close()
