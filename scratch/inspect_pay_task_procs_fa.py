import pyodbc
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_pay_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=SVRVTS01\\SQL6688;"
    "DATABASE=Vietinsoft_Pay;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

procs = [
    'sp_Task_TaskList',
    'sp_Task_TaskTemplate_Approve',
    'sp_Task_DataSource_Project',
    'sp_Task_TaskTimeLine_CheckChange',
    'sp_Task_TaskList_html'
]

try:
    conn = pyodbc.connect(conn_pay_str)
    cursor = conn.cursor()
    
    for proc in procs:
        cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID(?))", proc)
        row = cursor.fetchone()
        if row and row[0]:
            definition = row[0]
            matches = [m.start() for m in re.finditer(r'\bfa-[a-zA-Z0-9-]+\b', definition)]
            if matches:
                classes = set(re.findall(r'\bfa-[a-zA-Z0-9-]+\b', definition))
                print(f"Procedure: {proc} has {len(matches)} occurrences of fa-:")
                print(f"  Classes: {sorted(list(classes))}")
                for pos in matches:
                    start = max(0, pos - 40)
                    end = min(len(definition), pos + 60)
                    snippet = definition[start:end].replace('\r', '').replace('\n', ' ')
                    print(f"    - Position {pos}: ... {snippet} ...")
            else:
                print(f"Procedure: {proc} has 0 occurrences of fa-.")
        else:
            print(f"Procedure: {proc} not found in Vietinsoft_Pay.")
            
    conn.close()
except Exception as e:
    print("Error:", e)
