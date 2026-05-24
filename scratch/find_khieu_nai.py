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
    print("Connecting to Paradise_Dev...")
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    keyword = "Đơn Khiếu Nại"
    query = """
        SELECT msg.MessageID AS MenuID, msg.Language, msg.Content, 
               m.ParentMenuID, m.ClassName, m.AssemblyName, m.IsVisible
        FROM tblMD_Message msg
        LEFT JOIN MEN_Menu m ON m.MenuID = msg.MessageID
        WHERE msg.Content LIKE ?
        ORDER BY msg.MessageID, msg.Language
    """
    
    print(f"Searching for messages containing '{keyword}'...")
    cursor.execute(query, f"%{keyword}%")
    rows = cursor.fetchall()
    
    if not rows:
        print("No matching menu found.")
    else:
        print(f"Found {len(rows)} matching record(s):")
        for row in rows:
            print(f"MenuID: {row[0]}, Language: {row[1]}, Content: {row[2]}, Parent: {row[3]}, Class: {row[4]}, Assembly: {row[5]}, Visible: {row[6]}")
            
    conn.close()
except Exception as e:
    print("Error:", e)
