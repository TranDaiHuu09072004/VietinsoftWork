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
    print("Connecting to Vietinsoft_ForTest...")
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    # 1. Let's find some active employees with tasks or just any active employee
    cursor.execute("""
        SELECT TOP 5 e.EmployeeID, e.FullName 
        FROM tblEmployee e
        INNER JOIN tblLevelIDHistory lh ON e.EmployeeID = lh.EmployeeID
    """)
    emps = cursor.fetchall()
    if not emps:
        print("No active employees found in Vietinsoft_ForTest.")
        conn.close()
        sys.exit(0)
        
    print("\nTop 5 active employees in Vietinsoft_ForTest:")
    for emp in emps:
        print(f" - ID: {emp[0]}, Name: {emp[1]}")
        
    test_emp_id = '044'
    print(f"\nUsing employee '{test_emp_id}' for KPI XP verification.")
    
    # Let's see their current level history
    print(f"--- Employee {test_emp_id} Level History ---")
    cursor.execute("""
        SELECT lh.EmployeeID, lh.LevelID, lh.EffectiveDate, l.LevelRate 
        FROM tblLevelIDHistory lh
        LEFT JOIN tblLevel l ON lh.LevelID = l.LevelID
        WHERE lh.EmployeeID = ?
        ORDER BY lh.EffectiveDate DESC
    """, test_emp_id)
    rows = cursor.fetchall()
    for row in rows:
        print(f"Emp: {row[0]} | LevelID: {row[1]} | EffectiveDate: {row[2]} | LevelRate: {row[3]}")

    # Clear existing personal rating details for the test employee
    print(f"\nCleaning up existing rating details for '{test_emp_id}'...")
    cursor.execute("DELETE FROM tblRank_PersonalRating_Detail WHERE EmployeeID = ? AND CreatedDate BETWEEN '2026-04-01' AND '2026-04-20'", test_emp_id)
    conn.commit()

    # Set temporary LevelID to 4 (LevelRate 1.3) active on 2026-04-01
    print("Setting temporary level ID 4 (Rate 1.3) active on 2026-04-01 for test...")
    cursor.execute("DELETE FROM tblLevelIDHistory WHERE EmployeeID = ? AND EffectiveDate = '2026-04-01'", test_emp_id)
    cursor.execute("INSERT INTO tblLevelIDHistory (EmployeeID, LevelID, EffectiveDate, Remark) VALUES (?, 4, '2026-04-01', 'Temporary test level history')", test_emp_id)
    conn.commit()

    # Run the procedure
    print("Executing sp_PerformanceKPI_Working_Process...")
    # Using specific dates, loginID = 3, isDebug = 1
    cursor.execute("EXEC sp_PerformanceKPI_Working_Process '2026-04-10', '2026-04-20', ?, 3, 1", test_emp_id)
    conn.commit()
    print("Execution complete.")

    # Check tblRank_PersonalRating_Detail
    print(f"\n--- Calculated Personal Rating Details for '{test_emp_id}' ---")
    cursor.execute("""
        SELECT CreatedDate, PointType, ExperiencePonits, OrgXP_Point 
        FROM tblRank_PersonalRating_Detail 
        WHERE EmployeeID = ? AND CreatedDate BETWEEN '2026-04-10' AND '2026-04-20'
        ORDER BY PointType, CreatedDate
    """, test_emp_id)
    rows = cursor.fetchall()
    if not rows:
        print("No ratings calculated (may not have GPS attendance or task approvals).")
        print("Stored procedure ran without SQL exceptions.")
    else:
        for row in rows:
            print(f"Date: {row[0]} | PointType: {row[1]} | ExperiencePoints: {row[2]} | OrgXP_Point: {row[3]}")
            if row[1] == 2:
                # Scaled by 1.3 and rounded
                expected_scaled = int(round(float(row[3]) / 1.3))
                if row[2] == expected_scaled:
                    print(f"  -> SUCCESS: PointType 2 is correctly scaled from {row[3]} to {row[2]} (Expected: {expected_scaled})")
                else:
                    print(f"  -> FAIL: PointType 2 scaled to {row[2]} but expected {expected_scaled}")
            else:
                if row[2] == row[3]:
                    print(f"  -> SUCCESS: PointType {row[1]} remains unscaled: {row[2]}")
                else:
                    print(f"  -> FAIL: PointType {row[1]} changed from {row[3]} to {row[2]}")
                    
    # Clean up the temporary level record
    print("\nCleaning up temporary level history record...")
    cursor.execute("DELETE FROM tblLevelIDHistory WHERE EmployeeID = ? AND EffectiveDate = '2026-04-01'", test_emp_id)
    conn.commit()
    
    conn.close()
except Exception as e:
    print("Error:", e)
