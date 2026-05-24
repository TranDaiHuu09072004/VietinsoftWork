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
    
    # 1. Find an employee with attendance records in Dec 2025
    cursor.execute("""
        SELECT TOP 1 EmployeeID 
        FROM tblTmpAttend 
        WHERE AttTime BETWEEN '2025-12-01' AND '2025-12-31'
        GROUP BY EmployeeID
        HAVING COUNT(*) > 5
    """)
    res = cursor.fetchone()
    if not res:
        print("No employee found with > 5 attendance records in Dec 2025.")
        sys.exit(0)
    emp_id = res[0]
    print(f"Selected employee for testing: {emp_id}")

    # 2. Print current LevelRate for this employee
    cursor.execute(f"""
        SELECT lh.EmployeeID, lh.LevelID, lh.EffectiveDate, l.LevelRate 
        FROM tblLevelIDHistory lh
        LEFT JOIN tblLevel l ON lh.LevelID = l.LevelID
        WHERE lh.EmployeeID = '{emp_id}'
        ORDER BY lh.EffectiveDate DESC
    """)
    row = cursor.fetchone()
    print(f"Emp: {emp_id} | LevelRate: {row[3] if row else 1.0}")
    
    # 3. Run sp_PerformanceKPI_Working_Process for this employee in Dec 2025
    print(f"Executing sp_PerformanceKPI_Working_Process for '{emp_id}' in December 2025...")
    cursor.execute(f"EXEC sp_PerformanceKPI_Working_Process '2025-12-01', '2025-12-31', '{emp_id}', 3, 1")
    conn.commit()
    print("Execution complete.")
    
    # 4. Query details and check if OrgXP_Point equals ExperiencePoints for non-2 point types
    print(f"\n--- Rating Details for employee {emp_id} ---")
    cursor.execute(f"""
        SELECT CreatedDate, PointType, ExperiencePonits, OrgXP_Point 
        FROM tblRank_PersonalRating_Detail 
        WHERE EmployeeID = '{emp_id}' AND CreatedDate BETWEEN '2025-12-01' AND '2025-12-31'
        ORDER BY PointType, CreatedDate
    """)
    rows = cursor.fetchall()
    if not rows:
        print("No records found.")
    for r in rows:
        print(f"Date: {r[0]} | PointType: {r[1]} | ExperiencePoints: {r[2]} | OrgXP_Point: {r[3]} | Matches: {r[2] == r[3]}")
        
    conn.close()
except Exception as e:
    print(f"Error: {e}")
