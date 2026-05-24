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

generators = [
    # (ProcName, LanguageID, TableName)
    ('sp_Task_ComplaintForm_html', 'VN', 'sp_Task_ComplaintForm'),
    ('sp_Task_ComplaintForm_html', 'EN', 'sp_Task_ComplaintForm'),
    ('sp_Task_ComplaintForm_html', 'VN', 'sp_Task_ComplaintForm_html'),
    ('sp_Task_ComplaintForm_html', 'EN', 'sp_Task_ComplaintForm_html'),
    
    ('sp_Task_GetComplaintList_html', 'VN', 'sp_Task_GetComplaintList'),
    ('sp_Task_GetComplaintList_html', 'EN', 'sp_Task_GetComplaintList'),
    ('sp_Task_GetComplaintList_html', 'VN', 'sp_Task_GetComplaintList_html'),
    ('sp_Task_GetComplaintList_html', 'EN', 'sp_Task_GetComplaintList_html'),
]

for db in ["Paradise_Dev", "Vietinsoft_ForTest"]:
    print(f"\n=== Rebuilding Caches for Database: {db} ===")
    conn_str = f"{conn_base}DATABASE={db};"
    try:
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        
        # Clear existing caches for these keys first
        print("Clearing existing cache entries...")
        cursor.execute("""
            DELETE FROM tblHtmlScriptCache 
            WHERE TableName IN ('sp_Task_ComplaintForm', 'sp_Task_ComplaintForm_html', 
                                'sp_Task_GetComplaintList', 'sp_Task_GetComplaintList_html')
        """)
        conn.commit()
        print(f"Deleted {cursor.rowcount} cache rows.")
        
        # Execute each generator and consume all result sets
        for proc, lang, table in generators:
            print(f"Executing sp_GenerateHTMLScript '{proc}', '{lang}', '{table}'...")
            cursor.execute("EXEC dbo.sp_GenerateHTMLScript ?, ?, ?", proc, lang, table)
            
            # Crucial: consume all result sets to let the procedure complete execution
            set_idx = 1
            while True:
                if cursor.description:
                    # Fetching to clear buffer
                    cursor.fetchall()
                if not cursor.nextset():
                    break
                set_idx += 1
            conn.commit()
            
        print("Rebuild completed. Verifying generated caches...")
        cursor.execute("""
            SELECT TableName, LanguageID, LEN(html), CHARINDEX('fa-calendar-days', html)
            FROM tblHtmlScriptCache
            WHERE TableName IN ('sp_Task_ComplaintForm', 'sp_Task_ComplaintForm_html', 
                                'sp_Task_GetComplaintList', 'sp_Task_GetComplaintList_html')
        """)
        rows = cursor.fetchall()
        print(f"Found {len(rows)} entries in tblHtmlScriptCache:")
        for r in rows:
            print(f"  - {r[0]} ({r[1]}): {r[2]} chars | 'fa-calendar-days' index: {r[3]}")
            
        conn.close()
    except Exception as e:
        print(f"Error on database {db}: {e}")
