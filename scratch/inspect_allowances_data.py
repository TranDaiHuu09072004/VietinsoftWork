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

# Check tblEmployeeAllowance count
cursor.execute("SELECT COUNT(*) FROM tblEmployeeAllowance")
print("tblEmployeeAllowance row count:", cursor.fetchone()[0])

# Check tblPR_EmpAllowance count and columns
print("\n=== tblPR_EmpAllowance count and columns ===")
try:
    cursor.execute("SELECT COUNT(*) FROM tblPR_EmpAllowance")
    print("tblPR_EmpAllowance row count:", cursor.fetchone()[0])
    cursor.execute("SELECT TOP 0 * FROM tblPR_EmpAllowance")
    cols = [col[0] for col in cursor.description]
    print("Columns:", cols)
    cursor.execute("SELECT TOP 5 * FROM tblPR_EmpAllowance")
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))
except Exception as e:
    print(f"Error: {e}")

# Check tblAllowanceSetting columns where IncludedIns = 0 or NULL
print("\n=== tblAllowanceSetting where IncludedIns = 0 or NULL or False ===")
try:
    cursor.execute("""
        SELECT AllowanceID, AllowanceCode, AllowanceName, IncludedIns, ForSalary 
        FROM tblAllowanceSetting 
        WHERE IncludedIns = 0 OR IncludedIns IS NULL
    """)
    cols = [col[0] for col in cursor.description]
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))
except Exception as e:
    print(f"Error: {e}")

conn.close()
