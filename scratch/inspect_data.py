import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')


# Connection details for Vietinsoft_Pay
conn_vietinsoft = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,6688;"
    "DATABASE=Vietinsoft_Pay;"
    "UID=ai.sa;"
    "PWD=ThoiDaiVibeCodeIA@2026;"
    "TrustServerCertificate=yes;"
)

# Connection details for Paradise_Dev
conn_paradise = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

def inspect_db(conn, db_name):
    print(f"\n===== Inspecting {db_name} =====")
    cursor = conn.cursor()
    # We query to see the columns, their types, and data.
    cursor.execute("""
        SELECT TableName, LanguageID, ScreenType, 
               LEN(html) as html_len, 
               LEN(HtmlParadise) as html_paradise_len, 
               LEN(paradiseJs) as paradise_js_len, 
               Version, VersionData
        FROM tblHtmlScriptCache
        WHERE TableName LIKE '%Resignation%'
    """)
    rows = cursor.fetchall()
    columns = [col[0] for col in cursor.description]
    for row in rows:
        row_dict = dict(zip(columns, row))
        print(row_dict)
    cursor.close()

inspect_db(conn_vietinsoft, "Vietinsoft_Pay")
inspect_db(conn_paradise, "Paradise_Dev")

conn_vietinsoft.close()
conn_paradise.close()
