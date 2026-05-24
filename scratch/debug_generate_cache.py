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
    
    # Check if sp_Task_ComplaintForm_html exists
    cursor.execute("SELECT object_id('sp_Task_ComplaintForm_html')")
    obj_id = cursor.fetchone()[0]
    print(f"sp_Task_ComplaintForm_html object_id: {obj_id}")
    
    # Clear cache rows
    cursor.execute("DELETE FROM tblHtmlScriptCache WHERE TableName IN ('sp_Task_ComplaintForm', 'sp_Task_ComplaintForm_html')")
    conn.commit()
    print("Deleted cache rows:", cursor.rowcount)
    
    # Run generator with full error reporting
    print("Executing sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'VN', 'sp_Task_ComplaintForm'...")
    cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'VN', 'sp_Task_ComplaintForm'")
    conn.commit()
    print("Execution complete.")
    
    # Check if rows exist
    cursor.execute("SELECT TableName, LanguageID, LEN(html) FROM tblHtmlScriptCache WHERE TableName IN ('sp_Task_ComplaintForm', 'sp_Task_ComplaintForm_html')")
    rows = cursor.fetchall()
    print(f"Found {len(rows)} rows in cache after generation:")
    for r in rows:
        print(f"  {r[0]} ({r[1]}): {r[2]} chars")
        
    conn.close()
except Exception as e:
    print("Error:", e)
