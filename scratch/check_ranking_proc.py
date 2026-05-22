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

# Get definition of sp_Rank_getPersonalRating
print("=== Definition of sp_Rank_getPersonalRating ===")
try:
    cursor.execute("SELECT definition FROM sys.sql_modules WHERE object_id = OBJECT_ID('dbo.sp_Rank_getPersonalRating')")
    row = cursor.fetchone()
    if row:
        print(row[0])
    else:
        print("Not found")
except Exception as e:
    print(f"Error: {e}")

conn.close()
