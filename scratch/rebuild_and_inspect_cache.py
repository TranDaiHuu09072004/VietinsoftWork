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
    
    # 1. Clear existing cache entries for these keys
    print("Clearing cache keys...")
    cursor.execute("""
        DELETE FROM tblHtmlScriptCache 
        WHERE TableName IN ('sp_Task_ComplaintForm', 'sp_Task_ComplaintForm_html', 
                            'sp_Task_GetComplaintList', 'sp_Task_GetComplaintList_html')
    """)
    conn.commit()
    print(f"Deleted {cursor.rowcount} cache rows.")
    
    # 2. Run cache generators
    print("\nRegenerating caches...")
    generators = [
        ('sp_Task_ComplaintForm_html', 'VN', 'sp_Task_ComplaintForm'),
        ('sp_Task_ComplaintForm_html', 'EN', 'sp_Task_ComplaintForm'),
        ('sp_Task_GetComplaintList_html', 'VN', 'sp_Task_GetComplaintList'),
        ('sp_Task_GetComplaintList_html', 'EN', 'sp_Task_GetComplaintList'),
        
        ('sp_Task_ComplaintForm_html', 'VN', 'sp_Task_ComplaintForm_html'),
        ('sp_Task_ComplaintForm_html', 'EN', 'sp_Task_ComplaintForm_html'),
        ('sp_Task_GetComplaintList_html', 'VN', 'sp_Task_GetComplaintList_html'),
        ('sp_Task_GetComplaintList_html', 'EN', 'sp_Task_GetComplaintList_html'),
    ]
    
    for proc, lang, table in generators:
        print(f"  Executing sp_GenerateHTMLScript {proc} ({lang}) -> {table}...")
        cursor.execute("EXEC dbo.sp_GenerateHTMLScript ?, ?, ?", proc, lang, table)
    conn.commit()
    
    # 3. Query and check cache contents
    print("\nChecking generated cache contents...")
    cursor.execute("""
        SELECT TableName, LanguageID, CHARINDEX('fa-', html)
        FROM tblHtmlScriptCache
        WHERE TableName IN ('sp_Task_ComplaintForm', 'sp_Task_ComplaintForm_html', 
                            'sp_Task_GetComplaintList', 'sp_Task_GetComplaintList_html')
    """)
    rows = cursor.fetchall()
    for r in rows:
        print(f"  Cache: TableName={r[0]} | Lang={r[1]} | 'fa-' Index={r[2]}")
        if r[2] > 0:
            # Let's inspect where it is
            cursor.execute("SELECT html FROM tblHtmlScriptCache WHERE TableName = ? AND LanguageID = ?", r[0], r[1])
            html = cursor.fetchone()[0]
            pos = html.find('fa-')
            print(f"    Context: {html[max(0, pos-50):min(len(html), pos+50)]}")
            
    conn.close()
except Exception as e:
    print("Error:", e)
