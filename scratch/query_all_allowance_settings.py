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

# Query all from tblAllowanceSetting
print("=== All rows in tblAllowanceSetting ===")
cursor.execute("SELECT AllowanceID, AllowanceCode, AllowanceName, IncludedIns, ForSalary, DefaultAmount FROM tblAllowanceSetting")
cols = [col[0] for col in cursor.description]
for r in cursor.fetchall():
    print(dict(zip(cols, r)))

conn.close()
