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
    
    # Get all stored procedures starting with sp_Task_
    cursor.execute("""
        SELECT o.name, m.definition 
        FROM sys.objects o
        JOIN sys.sql_modules m ON o.object_id = m.object_id
        WHERE o.type = 'P' AND o.name LIKE 'sp_Task_%'
    """)
    procs = cursor.fetchall()
    print(f"Found {len(procs)} task-related stored procedures.")
    
    for name, definition in procs:
        if not definition:
            continue
        # Search for fa-
        matches = [m.start() for m in re.finditer(r'\bfa-[a-zA-Z0-9-]+\b', definition)]
        if matches:
            # Get unique fa- classes in this procedure
            classes = set(re.findall(r'\bfa-[a-zA-Z0-9-]+\b', definition))
            print(f"\nProcedure: {name} has {len(matches)} occurrences of fa-:")
            print(f"  Unique classes: {sorted(list(classes))}")
            # Print first 2 snippets
            for pos in matches[:3]:
                start = max(0, pos - 40)
                end = min(len(definition), pos + 60)
                snippet = definition[start:end].replace('\r', '').replace('\n', ' ')
                print(f"    - Position {pos}: ... {snippet} ...")
                
    conn.close()
except Exception as e:
    print("Error:", e)
