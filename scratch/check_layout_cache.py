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
    
    print("=== Checking layout cache entries in Vietinsoft_ForTest ===")
    cursor.execute("""
        SELECT TableName, LanguageID, ScreenType, DATALENGTH(html) 
        FROM tblHtmlScriptCache
        WHERE TableName LIKE '%layout%' OR TableName LIKE '%body%' OR TableName LIKE '%dashboard%'
    """)
    for r in cursor.fetchall():
        print(f"Cache: TableName={r[0]} | Lang={r[1]} | ScreenType={r[2]} | HtmlLength={r[3]}")
        
    conn.close()
except Exception as e:
    print("Error:", e)
