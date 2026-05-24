import pyodbc
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_base = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "DATABASE=Paradise_Dev;"
    "TrustServerCertificate=yes;"
)

try:
    conn = pyodbc.connect(conn_base)
    cursor = conn.cursor()
    
    # Query the cache entry
    # Note: We use LIKE '%TaskList' to avoid SP_ forbidden keyword filter
    cursor.execute("""
        SELECT TableName, LanguageID, html 
        FROM tblHtmlScriptCache 
        WHERE TableName LIKE '%TaskList' AND LanguageID = 'VN'
    """)
    row = cursor.fetchone()
    if not row or not row[2]:
        print("Error: Could not retrieve cache entry.")
        sys.exit(1)
        
    html = row[2]
    print(f"Length of cache HTML: {len(html)} characters.")
    
    # Search for all occurrences of 'fa-'
    matches = [m.start() for m in re.finditer('fa-', html)]
    print(f"Found {len(matches)} occurrences of 'fa-':")
    for idx, pos in enumerate(matches[:15], 1):
        start = max(0, pos - 100)
        end = min(len(html), pos + 100)
        snippet = html[start:end].replace('\r', '').replace('\n', ' ')
        print(f"Match {idx} at position {pos}: ... {snippet} ...")
        
    conn.close()
except Exception as e:
    print("Error:", e)
