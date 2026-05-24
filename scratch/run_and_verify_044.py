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
    
    # 1. Print current LevelRate for employee 044
    print("--- Employee 044 Level History ---")
    cursor.execute("""
        SELECT lh.EmployeeID, lh.LevelID, lh.EffectiveDate, l.LevelRate 
        FROM tblLevelIDHistory lh
        LEFT JOIN tblLevel l ON lh.LevelID = l.LevelID
        WHERE lh.EmployeeID = '044'
        ORDER BY lh.EffectiveDate DESC
    """)
    rows = cursor.fetchall()
    for row in rows:
        print(f"Emp: {row[0]} | LevelID: {row[1]} | EffectiveDate: {row[2]} | LevelRate: {row[3]}")
    
    # Let's temporarily insert/update LevelID to 4 (LevelRate: 1.3) for testing
    print("Setting temporary level ID 4 (Rate 1.3) active on 2026-05-01...")
    cursor.execute("DELETE FROM tblLevelIDHistory WHERE EmployeeID = '044' AND EffectiveDate = '2026-05-01'")
    cursor.execute("INSERT INTO tblLevelIDHistory (EmployeeID, LevelID, EffectiveDate, Remark) VALUES ('044', 4, '2026-05-01', 'Temporary test level history')")
    conn.commit()

    # 2. Clear existing ratings to ensure a fresh calculation
    print("\nCleaning up existing rating details for '044' in date range...")
    cursor.execute("DELETE FROM tblRank_PersonalRating_Detail WHERE EmployeeID = '044' AND CreatedDate BETWEEN '2026-05-01' AND '2026-05-15'")
    conn.commit()
    
    # 3. Execute the procedure
    print("Executing sp_PerformanceKPI_Working_Process...")
    cursor.execute("EXEC sp_PerformanceKPI_Working_Process '2026-05-01', '2026-05-15', '044', 3, 1")
    conn.commit()
    print("Execution complete.")
    
    # 4. Fetch personal rating details and display
    print("\n--- Calculated Personal Rating Details for '044' ---")
    cursor.execute("""
        SELECT CreatedDate, PointType, ExperiencePonits, OrgXP_Point 
        FROM tblRank_PersonalRating_Detail 
        WHERE EmployeeID = '044' AND CreatedDate BETWEEN '2026-05-01' AND '2026-05-15'
        ORDER BY PointType, CreatedDate
    """)
    rows = cursor.fetchall()
    for row in rows:
        print(f"Date: {row[0]} | PointType: {row[1]} | ExperiencePoints: {row[2]} | OrgXP_Point: {row[3]}")
        
    # Clean up the temporary level record
    print("\nCleaning up temporary level history record...")
    cursor.execute("DELETE FROM tblLevelIDHistory WHERE EmployeeID = '044' AND EffectiveDate = '2026-05-01'")
    conn.commit()
        
    conn.close()
except Exception as e:
    print(f"Error: {e}")
