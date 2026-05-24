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
    
    # 1. Rebuild Complaint menu caches
    print("Rebuilding HTML Cache for sp_Task_GetComplaintList...")
    cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_GetComplaintList_html', 'VN', 'sp_Task_GetComplaintList'")
    cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_GetComplaintList_html', 'EN', 'sp_Task_GetComplaintList'")
    
    print("Rebuilding HTML Cache for sp_Task_ComplaintForm...")
    cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'VN', 'sp_Task_ComplaintForm'")
    cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'EN', 'sp_Task_ComplaintForm'")
    
    # 2. Check and rebuild sp_dashboard_mobile_Beta if exists
    cursor.execute("SELECT 1 FROM sys.objects WHERE type = 'P' AND name = 'sp_dashboard_mobile_Beta_html'")
    if cursor.fetchone():
        print("Rebuilding HTML Cache for sp_dashboard_mobile_Beta...")
        cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_dashboard_mobile_Beta_html', 'VN', 'sp_dashboard_mobile_Beta'")
        cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_dashboard_mobile_Beta_html', 'EN', 'sp_dashboard_mobile_Beta'")
        
    # 3. Check and rebuild sslayoutbody if exists in sys.objects as _html
    cursor.execute("SELECT name FROM sys.objects WHERE type = 'P' AND name LIKE '%sslayoutbody%_html'")
    rows = cursor.fetchall()
    for r in rows:
        layout_proc = r[0]
        target_table = layout_proc.replace("_html", "")
        print(f"Rebuilding HTML Cache for {layout_proc} -> {target_table}...")
        cursor.execute(f"EXEC dbo.sp_GenerateHTMLScript '{layout_proc}', 'VN', '{target_table}'")
        cursor.execute(f"EXEC dbo.sp_GenerateHTMLScript '{layout_proc}', 'EN', '{target_table}'")
        
    conn.commit()
    print("All caches rebuilt successfully on Vietinsoft_ForTest!")
    conn.close()
except Exception as e:
    print("Error:", e)
