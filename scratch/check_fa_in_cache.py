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
        print(f"\n=== Cache check for Database: {db} ===")
        conn = pyodbc.connect(f"{conn_base}DATABASE={db};")
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT TableName, LanguageID, ScreenType, CHARINDEX('fa-calendar-days', html)
            FROM tblHtmlScriptCache
            WHERE html LIKE '%fa-calendar-days%' OR html LIKE '%fa-regular%'
        """)
        rows = cursor.fetchall()
        if rows:
            for r in rows:
                print(f"  Found FA icon in Cache: TableName={r[0]} | Lang={r[1]} | ScreenType={r[2]} | CharPos={r[3]}")
        else:
            print("  0 cached rows with FontAwesome icons found.")
            
        conn.close()
except Exception as e:
    print("Error:", e)
