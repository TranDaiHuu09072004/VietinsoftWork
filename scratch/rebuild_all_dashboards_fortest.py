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

dashboards = [
    ('sp_dashboard_mobile_Beta', 'sp_dashboard_mobile_Beta'),
    ('sp_dashboard_humanresource_beta', 'sp_dashboard_humanresource_beta'),
    ('sp_dashboard_home_new', 'sp_dashboard_home_new'),
    ('sp_dashboard_home_new_customer', 'sp_dashboard_home_new_customer'),
    ('sp_CRMDashboard', 'sp_CRMDashboard'),
    ('sp_Dashboard_Thanh', 'sp_Dashboard_Thanh'),
    ('dashboard_mobile', 'sp_dashboard_mobile') # Proc name might be sp_dashboard_mobile
]

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    for target_table, proc_name in dashboards:
        # Check if proc exists
        cursor.execute("SELECT 1 FROM sys.objects WHERE type = 'P' AND name = ?", proc_name)
        if cursor.fetchone():
            print(f"Rebuilding HTML Cache for {proc_name} -> {target_table}...")
            try:
                cursor.execute("EXEC dbo.sp_GenerateHTMLScript ?, 'VN', ?", proc_name, target_table)
                cursor.execute("EXEC dbo.sp_GenerateHTMLScript ?, 'EN', ?", proc_name, target_table)
                conn.commit()
            except Exception as e:
                print(f"  Failed for {proc_name}: {e}")
                conn.rollback()
        else:
            print(f"Procedure {proc_name} does not exist.")
            
    conn.close()
    print("Dashboard caches rebuild complete!")
except Exception as e:
    print("Error:", e)
