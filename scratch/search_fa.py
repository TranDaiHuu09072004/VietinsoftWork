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

for db in ["Paradise_Dev", "Vietinsoft_ForTest"]:
    print(f"\n=== Searching database {db} ===")
    conn_str = f"{conn_base}DATABASE={db};"
    try:
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        
        # Search sys.sql_modules
        cursor.execute("""
            SELECT OBJECT_NAME(object_id) AS ObjectName, definition
            FROM sys.sql_modules
            WHERE definition LIKE '%fa-%'
        """)
        rows = cursor.fetchall()
        print(f"Found {len(rows)} procedures containing 'fa-':")
        for r in rows:
            proc_name = r[0]
            definition = r[1]
            # Find occurrences of 'fa-'
            pos = 0
            found = []
            while True:
                pos = definition.find('fa-', pos)
                if pos == -1:
                    break
                snippet = definition[max(0, pos-40):min(len(definition), pos+40)].replace('\r', ' ').replace('\n', ' ')
                found.append(snippet)
                pos += 3
            print(f"  Procedure: {proc_name} ({len(found)} occurrences)")
            for s in found[:5]:
                print(f"    Snippet: {s}")
            if len(found) > 5:
                print(f"    ... and {len(found) - 5} more")
        conn.close()
    except Exception as e:
        print(f"Error on {db}: {e}")
