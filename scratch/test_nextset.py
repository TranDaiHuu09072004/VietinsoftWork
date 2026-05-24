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
    
    print("Executing sp_GenerateHTMLScript with nextset loop...")
    cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'vn', 'sp_Task_ComplaintForm'")
    
    # Consume all result sets
    set_idx = 1
    while True:
        print(f"\n--- Result Set {set_idx} ---")
        try:
            if cursor.description:
                rows = cursor.fetchall()
                print(f"Fetchall returned {len(rows)} rows.")
                if len(rows) > 0:
                    print("First row:", rows[0])
            else:
                print("No rows returned in this set (probably UPDATE/INSERT count). Rowcount:", cursor.rowcount)
        except Exception as fe:
            print(f"Fetch error: {fe}")
            
        if not cursor.nextset():
            break
        set_idx += 1
        
    conn.commit()
    print("\nCommitted. Now checking tblHtmlScriptCache...")
    cursor.execute("SELECT TableName, LanguageID, LEN(html) FROM tblHtmlScriptCache WHERE TableName = 'sp_Task_ComplaintForm'")
    rows = cursor.fetchall()
    print(f"Caches found: {len(rows)}")
    for r in rows:
        print(f"  {r[0]} ({r[1]}): {r[2]} chars")
        
    conn.close()
except Exception as e:
    print("\nGlobal Error:", e)
