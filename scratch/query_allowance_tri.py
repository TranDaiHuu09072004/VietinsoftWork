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

# Get Employee info for Nguyen Minh Tri (EmployeeID: 004)
print("=== Employee Info ===")
cursor.execute("SELECT * FROM tblEmployee WHERE EmployeeID = '004'")
row = cursor.fetchone()
if row:
    cols = [col[0] for col in cursor.description]
    emp_info = dict(zip(cols, row))
    # Print non-null key values
    for k, v in emp_info.items():
        if v is not None and k not in ['PhotoImage', 'ChopImage', 'SignImage']:
            print(f"  {k}: {v}")

# Get Allowance info
print("\n=== tblEmployeeAllowance ===")
cursor.execute("SELECT * FROM tblEmployeeAllowance WHERE EmployeeID = '004'")
rows = cursor.fetchall()
if rows:
    cols = [col[0] for col in cursor.description]
    for r in rows:
        allowance = dict(zip(cols, r))
        print("  --- Allowance Entry ---")
        for k, v in allowance.items():
            if v is not None:
                print(f"    {k}: {v}")
else:
    print("  No allowance entries found in tblEmployeeAllowance.")

# Get Allowance Rules
print("\n=== tblAllowanceRuleAssignedEmployee ===")
cursor.execute("SELECT * FROM tblAllowanceRuleAssignedEmployee WHERE EmployeeID = '004'")
rows = cursor.fetchall()
if rows:
    cols = [col[0] for col in cursor.description]
    for r in rows:
        rule = dict(zip(cols, r))
        print("  --- Rule Entry ---")
        for k, v in rule.items():
            if v is not None:
                print(f"    {k}: {v}")
else:
    print("  No rules found in tblAllowanceRuleAssignedEmployee.")

conn_vietinsoft.close()
