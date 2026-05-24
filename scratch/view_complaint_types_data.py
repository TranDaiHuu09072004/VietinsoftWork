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
    
    cursor.execute("SELECT * FROM tblTask_ComplaintTypes")
    rows = cursor.fetchall()
    print("=== tblTask_ComplaintTypes Records ===")
    for r in rows:
        print(f"ID: {r[0]}, Name: {r[1]}, NameEN: {r[2]}")
        
    conn.close()
except Exception as e:
    print("Error:", e)
