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
    
    print("=== Verification of Complaint Menus in Vietinsoft_ForTest ===")
    cursor.execute("""
        SELECT m.MenuID, m.ClassName, m.AssemblyName, m.ParentMenuID,
               o.ObjectID, o.ObjectName,
               msgVN.Content AS NameVN, msgEN.Content AS NameEN,
               (SELECT COUNT(*) FROM tblSC_Right_Stored WHERE ObjectID = o.ObjectID) AS RightsCount,
               (SELECT COUNT(*) FROM tblHtmlScriptCache WHERE TableName = m.ClassName) AS CacheLangsCount
        FROM MEN_Menu m
        LEFT JOIN tblSC_Object o ON o.Description = m.MenuID
        LEFT JOIN tblMD_Message msgVN ON msgVN.MessageID = m.MenuID AND msgVN.Language = 'VN'
        LEFT JOIN tblMD_Message msgEN ON msgEN.MessageID = m.MenuID AND msgEN.Language = 'EN'
        WHERE m.MenuID IN ('MnuAT009', 'MnuAT010')
    """)
    rows = cursor.fetchall()
    for r in rows:
        print(f"MenuID: {r[0]} | Class: {r[1]} | Assembly: {r[2]} | Parent: {r[3]} | ObjectID: {r[4]} | NameVN: {r[6]} | RightsCount: {r[8]} | CacheCount: {r[9]}")
        
    print("\n=== Checking tblHtmlScriptCache rows ===")
    cursor.execute("SELECT TableName, LanguageID, ScreenType, DATALENGTH(html) FROM tblHtmlScriptCache WHERE TableName IN ('sp_Task_GetComplaintList', 'sp_Task_ComplaintForm')")
    for r in cursor.fetchall():
        print(f"Cache: TableName={r[0]} | Lang={r[1]} | ScreenType={r[2]} | HtmlLength={r[3]}")
        
    conn.close()
except Exception as e:
    print("Error:", e)
