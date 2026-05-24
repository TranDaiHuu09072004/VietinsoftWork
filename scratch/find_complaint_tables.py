import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    print("=== Searching sys.objects for Tables and Views containing Complaint, Appeal, or KhieuNai ===")
    cursor.execute("""
        SELECT name, type_desc 
        FROM sys.objects 
        WHERE type IN ('U', 'V') 
          AND (name LIKE '%Complaint%' OR name LIKE '%Appeal%' OR name LIKE '%KhieuNai%')
    """)
    for r in cursor.fetchall():
        print(f"Object: {r[0]} ({r[1]})")
        
    conn.close()
except Exception as e:
    print("Error:", e)
