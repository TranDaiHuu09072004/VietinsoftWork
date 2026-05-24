import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_base = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "DATABASE=Paradise_Dev;"
    "TrustServerCertificate=yes;"
)

try:
    conn = pyodbc.connect(conn_base)
    cursor = conn.cursor()
    
    # Search for bubble-btn or bubble-dropdown-menu
    cursor.execute("""
        SELECT o.name, o.type_desc 
        FROM sys.objects o
        JOIN sys.sql_modules m ON o.object_id = m.object_id
        WHERE m.definition LIKE '%bubble-btn%'
    """)
    rows = cursor.fetchall()
    print(f"Found {len(rows)} database objects containing 'bubble-btn':")
    for r in rows:
        print(f"  - {r[0]} ({r[1]})")
        
    conn.close()
except Exception as e:
    print("Error:", e)
