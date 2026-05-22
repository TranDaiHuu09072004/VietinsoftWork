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
cursor.execute("SELECT * FROM tblEmployee WHERE EmployeeID = '004'")
row = cursor.fetchone()
if row:
    cols = [col[0] for col in cursor.description]
    for k, v in zip(cols, row):
        if 'date' in k.lower() or 'hire' in k.lower() or 'terminate' in k.lower() or 'status' in k.lower() or 'working' in k.lower():
            print(f"{k}: {v}")

conn_vietinsoft.close()
