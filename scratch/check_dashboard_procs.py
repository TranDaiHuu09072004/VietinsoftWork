import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Vietinsoft_ForTest;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    print("=== Searching stored procedures containing 'dashboard', 'mobile', or 'layout' ===")
    cursor.execute("""
        SELECT name, type_desc 
        FROM sys.objects 
        WHERE type = 'P' 
          AND (name LIKE '%dashboard%' OR name LIKE '%mobile%' OR name LIKE '%layout%' OR name LIKE '%body%')
        ORDER BY name
    """)
    for r in cursor.fetchall():
        print(f"Proc: {r[0]} ({r[1]})")
        
    conn.close()
except Exception as e:
    print("Error:", e)
