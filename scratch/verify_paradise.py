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
    
    # 1. Check LevelID and LevelRate of Employee 008
    print("--- Employee 008 Level History ---")
    cursor.execute("""
        SELECT lh.EmployeeID, lh.LevelID, lh.EffectiveDate, l.LevelRate 
        FROM tblLevelIDHistory lh
        LEFT JOIN tblLevel l ON lh.LevelID = l.LevelID
        WHERE lh.EmployeeID = '008'
        ORDER BY lh.EffectiveDate DESC
    """)
    rows = cursor.fetchall()
    for row in rows:
        print(f"Emp: {row[0]} | LevelID: {row[1]} | EffectiveDate: {row[2]} | LevelRate: {row[3]}")
        
    # 2. Check personal rating details for employee 008 in range
    print("\n--- tblRank_PersonalRating_Detail for employee 008 ---")
    cursor.execute("""
        SELECT CreatedDate, PointType, ExperiencePonits, OrgXP_Point 
        FROM tblRank_PersonalRating_Detail 
        WHERE EmployeeID = '008'
        ORDER BY PointType, CreatedDate
    """)
    rows = cursor.fetchall()
    if not rows:
        print("No records found in tblRank_PersonalRating_Detail for employee 008.")
    else:
        for row in rows:
            print(f"Date: {row[0]} | PointType: {row[1]} | ExperiencePoints: {row[2]} | OrgXP_Point: {row[3]}")
            
    conn.close()
except Exception as e:
    print(f"Error: {e}")
