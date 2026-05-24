import pyodbc
import sys
import json

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

def fetch_all_as_dict(cursor, query, params=None):
    if params:
        cursor.execute(query, params)
    else:
        cursor.execute(query)
    columns = [column[0] for column in cursor.description]
    results = []
    for row in cursor.fetchall():
        results.append(dict(zip(columns, row)))
    return results

try:
    print("Connecting to Paradise_Dev...")
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    menu_ids = ('MnuAT009', 'MnuAT010')
    classes = ('sp_Task_GetComplaintList', 'sp_Task_ComplaintForm')
    
    # 1. MEN_Menu
    print("\n--- 1. MEN_Menu ---")
    menus = fetch_all_as_dict(cursor, "SELECT * FROM MEN_Menu WHERE MenuID IN (?, ?)", menu_ids)
    for m in menus:
        print(f"MenuID: {m['MenuID']}, ClassName: {m['ClassName']}, Parent: {m['ParentMenuID']}, Assembly: {m['AssemblyName']}")
        
    # 2. tblSC_Object
    print("\n--- 2. tblSC_Object ---")
    sc_objects = fetch_all_as_dict(cursor, "SELECT * FROM tblSC_Object WHERE Description IN (?, ?)", menu_ids)
    for obj in sc_objects:
        print(f"ObjectID: {obj['ObjectID']}, ObjectName: {obj['ObjectName']}, Description: {obj['Description']}, ParentObjectID: {obj['ParentObjectID']}")
        
    # 3. tblMD_Message
    print("\n--- 3. tblMD_Message ---")
    messages = fetch_all_as_dict(cursor, "SELECT * FROM tblMD_Message WHERE MessageID IN (?, ?)", menu_ids)
    for msg in messages:
        print(f"MessageID: {msg['MessageID']}, Language: {msg['Language']}, Content: {msg['Content']}")
        
    # 4. tblDataSetting
    print("\n--- 4. tblDataSetting ---")
    ds_list = fetch_all_as_dict(cursor, "SELECT * FROM tblDataSetting WHERE TableName IN (?, ?) OR ViewName IN (?, ?)", classes + classes)
    for ds in ds_list:
        print(f"TableName: {ds['TableName']}, ViewName: {ds['ViewName']}, IsProcedure: {ds['IsProcedure']}")
        
    # 5. tblDataSettingLayout
    print("\n--- 5. tblDataSettingLayout ---")
    layouts = fetch_all_as_dict(cursor, "SELECT TableName, ControlName, ControlType, FieldName, WidthPercentage, OrderID FROM tblDataSettingLayout WHERE TableName IN (?, ?) ORDER BY TableName, OrderID", classes)
    print(f"Total layout rows: {len(layouts)}")
    for lay in layouts:
        print(f"  [{lay['TableName']}] ControlName: {lay['ControlName']}, ControlType: {lay['ControlType']}, FieldName: {lay['FieldName']}")

    # 6. tblHtmlScriptCache
    print("\n--- 6. tblHtmlScriptCache ---")
    caches = fetch_all_as_dict(cursor, "SELECT TableName, LanguageID, ScreenType, Version, DATALENGTH(html) as HtmlLen, DATALENGTH(HtmlParadise) as ParadiseLen, DATALENGTH(paradiseJs) as JsLen FROM tblHtmlScriptCache WHERE TableName IN (?, ?)", ('sp_Task_GetComplaintList_html', 'sp_Task_ComplaintForm_html'))
    for c in caches:
        print(f"Cache TableName: {c['TableName']}, Lang: {c['LanguageID']}, ScreenType: {c['ScreenType']}, html length: {c['HtmlLen']}")

    # 7. Procedures matching "sp_Task_*Complaint*"
    print("\n--- 7. Procedures matching Complaint ---")
    cursor.execute("SELECT name, type_desc FROM sys.objects WHERE type = 'P' AND name LIKE '%Complaint%'")
    procs = cursor.fetchall()
    for p in procs:
        print(f"Procedure name: {p[0]}")
        
    conn.close()
except Exception as e:
    print("Error:", e)
