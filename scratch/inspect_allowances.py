import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Connection details for Vietinsoft_Pay
conn_vietinsoft = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,6688;"
    "DATABASE=Vietinsoft_Pay;"
    "UID=ai.sa;"
    "PWD=ThoiDaiVibeCodeIA@2026;"
    "TrustServerCertificate=yes;"
)

cursor = conn_vietinsoft.cursor()

# Get columns of tblEmployeeAllowance
print("=== Columns in tblEmployeeAllowance ===")
for row in cursor.columns(table='tblEmployeeAllowance'):
    print(f"Column: {row.column_name}, Type: {row.type_name}")

# Check if there is data in tblEmployeeAllowance
print("\n=== Sample data in tblEmployeeAllowance ===")
cursor.execute("SELECT TOP 10 * FROM tblEmployeeAllowance")
rows = cursor.fetchall()
if rows:
    cols = [col[0] for col in cursor.description]
    for r in rows:
        print(dict(zip(cols, r)))
else:
    print("No data in tblEmployeeAllowance.")

# Get columns of tblAllowanceRuleAssignedEmployee
print("\n=== Columns in tblAllowanceRuleAssignedEmployee ===")
for row in cursor.columns(table='tblAllowanceRuleAssignedEmployee'):
    print(f"Column: {row.column_name}, Type: {row.type_name}")

# Check sample data in tblAllowanceRuleAssignedEmployee
print("\n=== Sample data in tblAllowanceRuleAssignedEmployee ===")
cursor.execute("SELECT TOP 10 * FROM tblAllowanceRuleAssignedEmployee")
rows = cursor.fetchall()
if rows:
    cols = [col[0] for col in cursor.description]
    for r in rows:
        print(dict(zip(cols, r)))
else:
    print("No data in tblAllowanceRuleAssignedEmployee.")

conn_vietinsoft.close()
