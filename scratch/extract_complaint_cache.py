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
    
    cursor.execute("""
        SELECT TableName, LanguageID, ScreenType, Version, 
               DATALENGTH(html) as HtmlLen, 
               DATALENGTH(HtmlParadise) as ParadiseLen, 
               DATALENGTH(paradiseJs) as JsLen,
               VersionData
        FROM tblHtmlScriptCache
        WHERE TableName IN ('sp_Task_GetComplaintList', 'sp_Task_ComplaintForm')
    """)
    rows = cursor.fetchall()
    print("=== Cache rows found in Paradise_Dev ===")
    for r in rows:
        print(f"TableName: {r[0]}, Lang: {r[1]}, ScreenType: {r[2]}, Version: {r[3]}, HtmlLen: {r[4]}, ParadiseLen: {r[5]}, JsLen: {r[6]}, VersionData: {r[7]}")
        
    conn.close()
except Exception as e:
    print("Error:", e)
