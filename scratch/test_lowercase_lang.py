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
    
    # Check what is in tblLanguage
    cursor.execute("SELECT * FROM tblLanguage")
    langs = cursor.fetchall()
    print("tblLanguage entries:")
    for l in langs:
        print(f"  {l}")
        
    # Run generator with lowercase 'vn'
    print("\nRunning: EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'vn', 'sp_Task_ComplaintForm'")
    cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'vn', 'sp_Task_ComplaintForm'")
    conn.commit()
    print("Finished.")
    
    # Run generator with lowercase 'en'
    print("\nRunning: EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'en', 'sp_Task_ComplaintForm'")
    cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'en', 'sp_Task_ComplaintForm'")
    conn.commit()
    print("Finished.")

    # Run generator with lowercase 'vn' for TableName='sp_Task_ComplaintForm_html'
    print("\nRunning: EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'vn', 'sp_Task_ComplaintForm_html'")
    cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'vn', 'sp_Task_ComplaintForm_html'")
    conn.commit()
    print("Finished.")

    # Run generator with lowercase 'en' for TableName='sp_Task_ComplaintForm_html'
    print("\nRunning: EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'en', 'sp_Task_ComplaintForm_html'")
    cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'en', 'sp_Task_ComplaintForm_html'")
    conn.commit()
    print("Finished.")
    
    # Check cache table
    cursor.execute("SELECT TableName, LanguageID, LEN(html) FROM tblHtmlScriptCache WHERE TableName IN ('sp_Task_ComplaintForm', 'sp_Task_ComplaintForm_html')")
    rows = cursor.fetchall()
    print(f"Cache table has {len(rows)} entries:")
    for r in rows:
        print(f"  {r[0]} ({r[1]}): {r[2]} chars")
        
    conn.close()
except Exception as e:
    print("Error:", e)
