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
    
    procs = ['sslayoutbody', 'HtmlMacOSLayOut', 'sp_dashboard_mobile_Beta']
    for p in procs:
        cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID(?))", p)
        defn = cursor.fetchone()[0]
        if defn:
            print(f"\n--- Checking {p} ---")
            lines = defn.splitlines()
            for idx, line in enumerate(lines):
                if 'sp_MainStyleCSSParadise' in line or 'StyleHtml' in line:
                    print(f"Line {idx+1}: {line.strip()}")
        else:
            print(f"Proc {p} not found.")
            
    conn.close()
except Exception as e:
    print("Error:", e)
