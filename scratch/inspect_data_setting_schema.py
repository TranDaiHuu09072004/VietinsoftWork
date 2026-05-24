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
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    classes = ('sp_Task_GetComplaintList', 'sp_Task_ComplaintForm')
    
    # 1. Print columns for tblDataSetting
    print("=== Columns of tblDataSetting ===")
    cursor.execute("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'tblDataSetting'")
    cols = [r[0] for r in cursor.fetchall()]
    print(", ".join(cols))
    
    # 2. Print columns for tblDataSettingLayout
    print("\n=== Columns of tblDataSettingLayout ===")
    cursor.execute("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'tblDataSettingLayout'")
    cols_layout = [r[0] for r in cursor.fetchall()]
    print(", ".join(cols_layout))
    
    # 3. Query rows from tblDataSetting
    print("\n=== Rows in tblDataSetting ===")
    cursor.execute("SELECT * FROM tblDataSetting WHERE TableName IN (?, ?) OR ViewName IN (?, ?)", classes + classes)
    rows = cursor.fetchall()
    print(f"Count: {len(rows)}")
    for r in rows:
        print(r)
        
    # 4. Query rows from tblDataSettingLayout
    print("\n=== Rows in tblDataSettingLayout ===")
    cursor.execute("SELECT * FROM tblDataSettingLayout WHERE TableName IN (?, ?)", classes)
    rows_layout = cursor.fetchall()
    print(f"Count: {len(rows_layout)}")
    for r in rows_layout:
        # print first few fields to avoid too much output
        print(r[:8])
        
    conn.close()
except Exception as e:
    print("Error:", e)
