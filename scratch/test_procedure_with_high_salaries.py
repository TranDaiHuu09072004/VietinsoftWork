import pyodbc
import datetime
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

print("Connecting to Vietinsoft_ForTest to verify sp_Level_AutoUpdateHistory with test data...")
conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

try:
    # 1. Clear tblLevelIDHistory to start fresh
    cursor.execute("DELETE FROM tblLevelIDHistory")
    
    # 2. Insert temporary test salaries
    # Employee 003: 8,000,000 (Rate 1.0 -> Gb1)
    # Employee 014: 10,400,000 (Rate 1.3 -> Gb4)
    today = datetime.date.today().strftime('%Y-%m-%d')
    print("Inserting temporary high salaries for Employee 003 and 014...")
    
    cursor.execute("""
        INSERT INTO tblSalaryHistory (EmployeeID, Date, Salary, Trans_AL, Pos_AL, InsSalary, NETSalary, SalCalRuleID)
        VALUES 
        ('003', ?, 8000000.0000, 0.0000, 0.0000, 0.0000, 0.0000, 1),
        ('014', ?, 10400000.0000, 0.0000, 0.0000, 0.0000, 0.0000, 1)
    """, (today, today))
    conn.commit()
    
    # Get IDs of inserted salary histories to clean them up later
    cursor.execute("SELECT SalaryHistoryID FROM tblSalaryHistory WHERE Date = ? AND Salary IN (8000000, 10400000)", (today,))
    inserted_ids = [row[0] for row in cursor.fetchall()]
    print(f"Inserted SalaryHistoryIDs: {inserted_ids}")
    
    # 3. Run the stored procedure
    print("Running EXEC sp_Level_AutoUpdateHistory...")
    cursor.execute("EXEC dbo.sp_Level_AutoUpdateHistory")
    conn.commit()
    
    # 4. Check tblLevelIDHistory
    print("Checking tblLevelIDHistory results:")
    cursor.execute("""
        SELECT h.EmployeeID, e.FullName, h.LevelID, l.LevelName, l.LevelRate, h.Remark
        FROM tblLevelIDHistory h
        INNER JOIN tblEmployee e ON h.EmployeeID = e.EmployeeID
        INNER JOIN tbllevel l ON h.LevelID = l.LevelID
    """)
    rows = cursor.fetchall()
    for row in rows:
        print(f" - Emp: {row[0]} ({row[1]}), LevelID: {row[2]} ({row[3]}), Rate: {row[4]}, Remark: {row[5]}")
        
    # 5. Clean up temporary salary records
    if inserted_ids:
        print("Cleaning up temporary salary records...")
        id_placeholders = ",".join(["?"] * len(inserted_ids))
        cursor.execute(f"DELETE FROM tblSalaryHistory WHERE SalaryHistoryID IN ({id_placeholders})", inserted_ids)
        conn.commit()
        print("Cleanup completed.")
        
except Exception as e:
    print("An error occurred during verification:")
    print(e)
    conn.rollback()
finally:
    conn.close()
