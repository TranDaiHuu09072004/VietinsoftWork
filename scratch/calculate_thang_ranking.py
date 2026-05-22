import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Connection details for Vietinsoft_Pay
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,6688;"
    "DATABASE=Vietinsoft_Pay;"
    "UID=ai.sa;"
    "PWD=ThoiDaiVibeCodeIA@2026;"
    "TrustServerCertificate=yes;"
)

cursor = conn.cursor()

# Let's execute the calculations for different filter types
def check_ranks(filter_type, year=2026, month=5, quarter=2):
    print(f"\n======================================")
    print(f"Filter Type: {filter_type}, Year: {year}, Month: {month}, Quarter: {quarter}")
    print(f"======================================")
    
    # We call the procedure. Note that the procedure might run sp_PerformanceKPI_Working_Process
    # Let's call the procedure directly and read the first result set (which is #RankedData)
    try:
        # Since sp_Rank_getPersonalRating returns multiple result sets:
        # 1: #RankedData
        # 2: Years
        # 3: Departments
        # 4: UserDepartmentID
        # 5: CurrentSalaryMonth/Quarter/Year
        cursor.execute("EXEC dbo.sp_Rank_getPersonalRating @LoginID=23, @LanguageID='VN', @FilterType=?, @FilterYear=?, @FilterMonth=?, @FilterQuarter=?", 
                       (filter_type, year, month, quarter))
        
        # Fetch RankedData
        rows = cursor.fetchall()
        cols = [col[0] for col in cursor.description]
        
        ranked_list = []
        for r in rows:
            ranked_list.append(dict(zip(cols, r)))
            
        print(f"Total ranked employees: {len(ranked_list)}")
        
        # Find Bùi Trần Thắng Duy (008) and Nguyễn Thắng (045)
        for emp in ranked_list:
            if emp['EmployeeID'] in ['008', '045'] or 'Thắng' in emp['FullName'] or 'Thang' in emp['FullName']:
                print(f"Rank: {emp['Rank']} - ID: {emp['EmployeeID']} - Name: {emp['FullName']} - Dept: {emp['DepartmentName']} - Points: {emp['TotalPoints']} - Coins: {emp['TotalCoin']}")
                
    except Exception as e:
        print(f"Error executing sp_Rank_getPersonalRating: {e}")

# Run checks
check_ranks('year', year=2026)
check_ranks('month', year=2026, month=5)
check_ranks('quarter', year=2026, quarter=2)

conn.close()
