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

# Find employees with "Thắng" in their name
print("=== Searching for employees with 'Thắng' or 'Thang' ===")
cursor.execute("""
    SELECT EmployeeID, FullName, LastName, FirstName, Sex, Birthday, HireDate
    FROM tblEmployee 
    WHERE FirstName LIKE N'%Thắng%' 
       OR LastName LIKE N'%Thắng%'
       OR FirstName LIKE N'%Thang%'
       OR LastName LIKE N'%Thang%'
       OR FullName LIKE N'%Thắng%'
       OR FullName LIKE N'%Thang%'
""")
emps = cursor.fetchall()
for emp in emps:
    print(f"EmployeeID: {emp[0]}, FullName: {emp[1]}, LastName: {emp[2]}, FirstName: {emp[3]}, Sex: {emp[4]}, Birthday: {emp[5]}, HireDate: {emp[6]}")

# Let's inspect ranking tables
print("\n=== Checking ranking tables ===")
tables = ['tblRank_PersonalRating_Detail', 'tblRank_PointType', 'tblRank_Coin_Wallet', 'tblRank_Coin_Transaction']
for t in tables:
    try:
        cursor.execute(f"SELECT COUNT(*) FROM {t}")
        cnt = cursor.fetchone()[0]
        print(f"Table {t}: {cnt} rows")
    except Exception as e:
        print(f"Error checking {t}: {e}")

# Let's check sp_Rank_getPersonalRating or sp_Rank_GetEmployeeDetail
print("\n=== Searching for Rank / Rating procedures ===")
cursor.execute("""
    SELECT name FROM sys.procedures 
    WHERE name LIKE '%Rank%' OR name LIKE '%Rating%'
""")
procs = cursor.fetchall()
for p in procs:
    print(p[0])

conn.close()
