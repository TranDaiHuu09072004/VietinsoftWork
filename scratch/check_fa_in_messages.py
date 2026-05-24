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

dbs = ["Paradise_Dev", "Vietinsoft_ForTest"]

try:
    for db in dbs:
        print(f"\n=== Message check for Database: {db} ===")
        conn = pyodbc.connect(f"{conn_base}DATABASE={db};")
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT MessageID, Language, Content
            FROM tblMD_Message
            WHERE Content LIKE '%fa-%'
        """)
        rows = cursor.fetchall()
        if rows:
            for r in rows:
                print(f"  Found FA in Message: MessageID={r[0]} | Lang={r[1]} | Content={r[2]}")
        else:
            print("  0 messages with FontAwesome icons found.")
            
        conn.close()
except Exception as e:
    print("Error:", e)
