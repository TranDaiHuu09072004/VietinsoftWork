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
    
    # Check collation
    cursor.execute("SELECT DATABASEPROPERTYEX('Vietinsoft_ForTest', 'Collation')")
    collation = cursor.fetchone()[0]
    print(f"Collation of Vietinsoft_ForTest: {collation}")
    
    # Check what the select returns
    cursor.execute("SELECT LanguageID FROM tblLanguage WHERE LanguageID IN ('vn', 'en')")
    rows = cursor.fetchall()
    print("Query 'LanguageID IN (''vn'', ''en'')' returned:")
    for r in rows:
        print(f"  {r[0]}")
        
    cursor.execute("SELECT LanguageID FROM tblLanguage WHERE LanguageID IN ('VN', 'EN')")
    rows_up = cursor.fetchall()
    print("Query 'LanguageID IN (''VN'', ''EN'')' returned:")
    for r in rows_up:
        print(f"  {r[0]}")
        
    conn.close()
except Exception as e:
    print("Error:", e)
