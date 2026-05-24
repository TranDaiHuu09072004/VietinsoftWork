import pyodbc
import re
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
    
    # Get procedure definition using OBJECT_DEFINITION
    cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID('sp_Task_TaskList_html'))")
    row = cursor.fetchone()
    if not row or not row[0]:
        print("Error: Could not retrieve procedure definition for sp_Task_TaskList_html.")
        sys.exit(1)
        
    definition = row[0]
    print(f"Length of sp_Task_TaskList_html definition: {len(definition)} characters.")
    
    # Search for occurrences of 'fa-'
    # We will search for 'fa-' and show 50 chars before and after
    matches = [m.start() for m in re.finditer('fa-', definition)]
    print(f"Found {len(matches)} occurrences of 'fa-':")
    for idx, pos in enumerate(matches, 1):
        start = max(0, pos - 40)
        end = min(len(definition), pos + 60)
        snippet = definition[start:end].replace('\r', '').replace('\n', ' ')
        print(f"Match {idx} at position {pos}: ... {snippet} ...")
        
    conn.close()
except Exception as e:
    print("Error:", e)
