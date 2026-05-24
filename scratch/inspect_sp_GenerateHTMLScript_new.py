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
    
    cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID('sp_GenerateHTMLScript_new'))")
    defn = cursor.fetchone()[0]
    if defn:
        # Find where tblHtmlScriptCache is referenced in this procedure
        lines = defn.splitlines()
        for idx, line in enumerate(lines):
            if 'tblHtmlScriptCache' in line or 'TableName' in line or 'MERGE' in line:
                print(f"Line {idx+1}: {line.strip()}")
    else:
        print("Procedure sp_GenerateHTMLScript_new not found.")
        
    conn.close()
except Exception as e:
    print("Error:", e)
