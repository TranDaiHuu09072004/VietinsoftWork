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

def decimal_default(obj):
    import decimal
    if isinstance(obj, decimal.Decimal):
        return float(obj)
    raise TypeError

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    # 1. MEN_Menu meta
    print("=== MEN_Menu Metadata ===")
    cursor.execute("SELECT * FROM MEN_Menu WHERE MenuID IN ('MnuAT009', 'MnuAT010')")
    columns = [column[0] for column in cursor.description]
    for row in cursor.fetchall():
        row_dict = dict(zip(columns, row))
        print(f"\n--- {row_dict['MenuID']} ---")
        for k, v in row_dict.items():
            if v is not None and v != '' and v != 0:
                print(f"  {k}: {v}")
                
    # 2. tblSC_Object meta
    print("\n=== tblSC_Object Metadata ===")
    cursor.execute("SELECT * FROM tblSC_Object WHERE Description IN ('MnuAT009', 'MnuAT010')")
    columns = [column[0] for column in cursor.description]
    for row in cursor.fetchall():
        row_dict = dict(zip(columns, row))
        print(f"\n--- {row_dict['Description']} ---")
        for k, v in row_dict.items():
            if v is not None:
                print(f"  {k}: {v}")
                
    # 3. tblMD_Message meta
    print("\n=== tblMD_Message Metadata ===")
    cursor.execute("SELECT * FROM tblMD_Message WHERE MessageID IN ('MnuAT009', 'MnuAT010')")
    for r in cursor.fetchall():
        print(f"  MessageID: {r[0]}, Language: {r[1]}, Content: {r[2]}")
        
    conn.close()
except Exception as e:
    print("Error:", e)
