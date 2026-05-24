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
    
    print("=== Checking tasks in Vietinsoft_ForTest ===")
    cursor.execute("""
        SELECT TOP 10 AssigneeID, StatusID, ActualStartDate, ActualFinishDate, StandardTime, ModifiedDate, dDate
        FROM tblTask_Tasks
        WHERE AssigneeID IS NOT NULL AND StatusID = 4
    """)
    rows = cursor.fetchall()
    print(f"Found approved tasks: {len(rows)}")
    for r in rows:
        print(f"AssigneeID: {r[0]} | Status: {r[1]} | Start: {r[2]} | Finish: {r[3]} | StdTime: {r[4]} | ModifiedDate: {r[5]} | dDate: {r[6]}")
        
    conn.close()
except Exception as e:
    print("Error:", e)
