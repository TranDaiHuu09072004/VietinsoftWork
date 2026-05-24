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
    
    # 1. Run stored procedure
    print("Running EXEC sp_Level_AutoUpdateHistory...")
    cursor.execute("EXEC dbo.sp_Level_AutoUpdateHistory")
    conn.commit()
    print("Run completed successfully.")
    
    # 2. Query history
    print("\n=== Current tblLevelIDHistory ===")
    cursor.execute("""
        SELECT h.EmployeeID, e.FullName, h.LevelID, l.LevelName, l.LevelRate, h.Remark, h.EffectiveDate
        FROM tblLevelIDHistory h
        INNER JOIN tblEmployee e ON h.EmployeeID = e.EmployeeID
        INNER JOIN tbllevel l ON h.LevelID = l.LevelID
        ORDER BY h.EffectiveDate DESC, h.EmployeeID ASC
    """)
    for r in cursor.fetchall():
        print(f"Emp: {r[0]:<5} | Name: {r[1]:<25} | LevelID: {r[2]:<3} | LevelName: {r[3]:<5} | Rate: {r[4]} | Remark: {r[5]} | Date: {r[6]}")
        
    conn.close()
except Exception as e:
    print(f"Error: {e}")
