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
cursor.execute("SELECT * FROM tblSalaryHistory WHERE EmployeeID = '004'")
rows = cursor.fetchall()
if rows:
    cols = [col[0] for col in cursor.description]
    for r in rows:
        print("--- Salary History Entry ---")
        entry = dict(zip(cols, r))
        for k, v in entry.items():
            if v is not None:
                print(f"  {k}: {v}")
else:
    print("No records found in tblSalaryHistory for EmployeeID = '004'")

conn_vietinsoft.close()
