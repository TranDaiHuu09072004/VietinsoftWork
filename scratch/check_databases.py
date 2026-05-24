import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=master;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    cursor.execute("SELECT name FROM sys.databases ORDER BY name")
    print("=== Databases on Server ===")
    for r in cursor.fetchall():
        print(f" - {r[0]}")
        
    conn.close()
except Exception as e:
    print("Error:", e)
