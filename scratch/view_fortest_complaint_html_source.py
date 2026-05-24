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
    
    cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID('sp_Task_ComplaintForm_html'))")
    row = cursor.fetchone()
    if row and row[0]:
        defn = row[0]
        print("=== Checking sp_Task_ComplaintForm_html in database Vietinsoft_ForTest ===")
        lines = defn.splitlines()
        found = False
        for idx, line in enumerate(lines, 1):
            if 'fa-' in line:
                print(f"  Line {idx}: {line.strip()}")
                found = True
        if not found:
            print("  0 occurrences of 'fa-' found in database procedure.")
    else:
        print("sp_Task_ComplaintForm_html not found.")
        
    conn.close()
except Exception as e:
    print("Error:", e)
