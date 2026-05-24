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
    
    print("=== Searching sys.objects for sp_Task_GetComplaintList* and sp_Task_ComplaintForm* ===")
    cursor.execute("SELECT name, type_desc FROM sys.objects WHERE name LIKE 'sp_Task_GetComplaintList%' OR name LIKE 'sp_Task_ComplaintForm%'")
    for r in cursor.fetchall():
        print(f"Object: {r[0]} ({r[1]})")
        
    print("\n=== Searching tblHtmlScriptCache for TableName LIKE '%Complaint%' ===")
    cursor.execute("SELECT TableName, LanguageID, ScreenType, DATALENGTH(html) FROM tblHtmlScriptCache WHERE TableName LIKE '%Complaint%'")
    for r in cursor.fetchall():
        print(f"Cache: TableName={r[0]}, LanguageID={r[1]}, ScreenType={r[2]}, HtmlLength={r[3]}")
        
    conn.close()
except Exception as e:
    print("Error:", e)
