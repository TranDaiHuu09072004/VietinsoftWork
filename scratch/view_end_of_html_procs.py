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
    
    procs = ['sp_Task_GetComplaintList_html', 'sp_Task_ComplaintForm_html']
    
    for proc in procs:
        print(f"\n========================================\nPROCEDURE END: {proc}\n========================================")
        cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID(?))", proc)
        defn = cursor.fetchone()[0]
        if defn:
            lines = defn.splitlines()
            print("\n".join(lines[-50:]))
        else:
            print("No definition found.")
            
    conn.close()
except Exception as e:
    print("Error:", e)
