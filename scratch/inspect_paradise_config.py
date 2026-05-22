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

print("=== Columns in tblParadiseConfig ===")
cursor.execute("SELECT TOP 0 * FROM tblParadiseConfig")
cols = [col[0] for col in cursor.description]
print(cols)

print("\n=== Data in tblParadiseConfig ===")
cursor.execute("SELECT TOP 100 * FROM tblParadiseConfig")
rows = cursor.fetchall()
for r in rows:
    # Print key and value if not null
    d = dict(zip(cols, r))
    print(d)

conn_vietinsoft.close()
