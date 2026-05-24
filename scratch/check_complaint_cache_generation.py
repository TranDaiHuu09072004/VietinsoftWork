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
        cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID(?))", proc)
        defn = cursor.fetchone()[0]
        if defn:
            print(f"\n--- Searching in {proc} ---")
            lines = defn.splitlines()
            for i, line in enumerate(lines):
                if 'tblHtmlScriptCache' in line or 'sp_GenerateHTMLScript' in line:
                    print(f"Line {i+1}: {line.strip()}")
        else:
            print(f"No definition for {proc}")
            
    conn.close()
except Exception as e:
    print("Error:", e)
