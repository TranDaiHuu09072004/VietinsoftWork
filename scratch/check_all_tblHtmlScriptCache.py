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
    
    print("=== All Distinct TableNames in tblHtmlScriptCache ===")
    cursor.execute("SELECT DISTINCT TableName FROM tblHtmlScriptCache ORDER BY TableName")
    for r in cursor.fetchall():
        print(f" - {r[0]}")
        
    conn.close()
except Exception as e:
    print("Error:", e)
