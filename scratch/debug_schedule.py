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
    
    # Check default shift count
    cursor.execute("SELECT COUNT(DISTINCT ShiftCode) FROM tblShiftSetting WITH(NOLOCK)")
    print("Distinct ShiftCode count:", cursor.fetchone()[0])
    
    # Check if any schedule exists for employee 008 in range
    cursor.execute("""
        SELECT COUNT(*) 
        FROM tblWSchedule 
        WHERE EmployeeID = '008' AND ScheduleDate BETWEEN '2026-03-01' AND '2026-03-15'
    """)
    print("Schedule count in tblWSchedule:", cursor.fetchone()[0])
    
    # Check if default shift exists
    cursor.execute("SELECT TOP 5 * FROM tblShiftSetting WHERE WeekDays = 2")
    print("Default shift details for WeekDays = 2:")
    for r in cursor.fetchall():
        print(r)
        
    conn.close()
except Exception as e:
    print("Error:", e)
