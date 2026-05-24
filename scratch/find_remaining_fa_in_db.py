import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_base = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

procs = ['sp_Task_ComplaintForm_html', 'sp_Task_GetComplaintList_html']
dbs = ["Paradise_Dev", "Vietinsoft_ForTest"]

try:
    for db in dbs:
        print(f"\n=== Checking Database: {db} ===")
        conn = pyodbc.connect(f"{conn_base}DATABASE={db};")
        cursor = conn.cursor()
        
        for proc in procs:
            cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID(?))", proc)
            defn_row = cursor.fetchone()
            if defn_row and defn_row[0]:
                defn = defn_row[0]
                # Find all occurrences of fa-
                import re
                fa_matches = re.findall(r'fa-[a-z0-9-]+', defn)
                if fa_matches:
                    print(f"  Procedure {proc} has remaining FontAwesome icons: {set(fa_matches)}")
                    # Find exact lines
                    lines = defn.splitlines()
                    for idx, line in enumerate(lines):
                        if 'fa-' in line:
                            print(f"    Line {idx+1}: {line.strip()}")
                else:
                    print(f"  Procedure {proc} has 0 remaining FontAwesome icons.")
            else:
                print(f"  Procedure {proc} not found.")
                
        conn.close()
except Exception as e:
    print("Error:", e)
