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
    
    cursor.execute("""
        SELECT TableName, LanguageID, html
        FROM tblHtmlScriptCache
        WHERE TableName = 'sp_Task_ComplaintForm_html' AND LanguageID = 'VN'
    """)
    row = cursor.fetchone()
    if row:
        html = row[2]
        pos = html.find('fa-')
        if pos != -1:
            print(f"Found 'fa-' at index {pos}")
            start = max(0, pos - 100)
            end = min(len(html), pos + 100)
            print(f"Context: {html[start:end]}")
        else:
            print("No 'fa-' found in database cache row.")
    else:
        print("Row not found in cache.")
        
    conn.close()
except Exception as e:
    print("Error:", e)
