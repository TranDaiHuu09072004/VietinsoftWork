import pyodbc

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
    
    # 1. Count non-null ShiftIDs in tblWSchedule
    cursor.execute("SELECT COUNT(*), COUNT(ShiftID) FROM tblWSchedule")
    total, non_null = cursor.fetchone()
    print(f"Total schedule records: {total} | Records with ShiftID: {non_null}")
    
    # 2. Show some rows where ShiftID is not null
    cursor.execute("""
        SELECT TOP 10 EmployeeID, ScheduleDate, ShiftID 
        FROM tblWSchedule 
        WHERE ShiftID IS NOT NULL
        ORDER BY ScheduleDate DESC
    """)
    rows = cursor.fetchall()
    for r in rows:
        print(f"Emp: {r[0]} | Date: {r[1]} | ShiftID: {r[2]}")
        
    conn.close()
except Exception as e:
    print("Error:", e)
