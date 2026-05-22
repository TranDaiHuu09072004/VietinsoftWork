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
cursor.execute("""
    SELECT name 
    FROM sys.tables 
    WHERE name LIKE '%Period%' 
       OR name LIKE '%Term%' 
       OR name LIKE '%Cycle%'
       OR name LIKE '%Sheet%'
       OR name LIKE '%Time%'
       OR name LIKE '%Config%'
    ORDER BY name
""")
rows = cursor.fetchall()
print("Payroll Cycle / Period tables:")
for r in rows:
    print(r[0])

conn_vietinsoft.close()
