import pyodbc
import os

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

def fetch_data(conn, name_pattern):
    cursor = conn.cursor()
    query = """
    SELECT TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData 
    FROM tblHtmlScriptCache 
    WHERE TableName LIKE ?
    """
    cursor.execute(query, (name_pattern,))
    rows = cursor.fetchall()
    result = []
    for r in rows:
        result.append({
            'TableName': r[0],
            'LanguageID': r[1],
            'ScreenType': r[2],
            'html': r[3],
            'HtmlParadise': r[4],
            'paradiseJs': r[5],
            'Version': r[6],
            'VersionData': r[7]
        })
    cursor.close()
    return result

print("=== Vietinsoft_Pay (Source) ===")
v_rows = fetch_data(conn_vietinsoft, '%ResignationLeave%')
for r in v_rows:
    html_len = len(r['html']) if r['html'] else 0
    html_par_len = len(r['HtmlParadise']) if r['HtmlParadise'] else 0
    print(f"Table: {r['TableName']}, Lang: {r['LanguageID']}, Screen: {r['ScreenType']}, html_len: {html_len}, html_paradise_len: {html_par_len}, Version: {r['Version']}")
    
    # Save a sample to file
    fn = f"scratch/vietinsoft_{r['TableName']}_{r['LanguageID']}.html"
    with open(fn, "w", encoding="utf-8") as f:
        f.write(r['html'] or "")
    print(f"  Saved to {fn}")

print("\n=== Paradise_Dev (Destination) ===")
p_rows = fetch_data(conn_paradise, '%ResignationLeave%')
for r in p_rows:
    html_len = len(r['html']) if r['html'] else 0
    html_par_len = len(r['HtmlParadise']) if r['HtmlParadise'] else 0
    print(f"Table: {r['TableName']}, Lang: {r['LanguageID']}, Screen: {r['ScreenType']}, html_len: {html_len}, html_paradise_len: {html_par_len}, Version: {r['Version']}")
    
    # Save a sample to file
    fn = f"scratch/paradise_{r['TableName']}_{r['LanguageID']}.html"
    with open(fn, "w", encoding="utf-8") as f:
        f.write(r['html'] or "")
    print(f"  Saved to {fn}")

conn_vietinsoft.close()
conn_paradise.close()
