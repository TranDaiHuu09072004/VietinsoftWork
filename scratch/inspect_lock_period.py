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

print("=== Columns in tblSal_Lock_Period1 ===")
cursor.execute("SELECT TOP 0 * FROM tblSal_Lock_Period1")
cols = [col[0] for col in cursor.description]
print(cols)

print("\n=== Data in tblSal_Lock_Period1 ===")
cursor.execute("SELECT TOP 50 * FROM tblSal_Lock_Period1 ORDER BY Year DESC, Month DESC")
rows = cursor.fetchall()
for r in rows:
    print(dict(zip(cols, r)))

conn_vietinsoft.close()
