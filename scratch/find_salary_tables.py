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
    WHERE name LIKE '%Salary%' 
       OR name LIKE '%Luong%' 
       OR name LIKE '%Contract%' 
       OR name LIKE '%HopDong%'
       OR name LIKE '%Employee%'
       OR name LIKE '%NhanVien%'
    ORDER BY name
""")
rows = cursor.fetchall()
print("Matching tables:")
for r in rows:
    print(r[0])

conn_vietinsoft.close()
