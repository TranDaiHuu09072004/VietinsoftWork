import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Connection details for Vietinsoft_Pay
conn_vietinsoft = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,6688;"
    "DATABASE=Vietinsoft_Pay;"
    "UID=ai.sa;"
    "PWD=ThoiDaiVibeCodeIA@2026;"
    "TrustServerCertificate=yes;"
)

cursor = conn_vietinsoft.cursor()

# 1. Query tblParameter for SAL_START and SAL_STOP
print("=== Querying tblParameter ===")
try:
    cursor.execute("SELECT Code, Value FROM tblParameter WHERE Code IN ('SAL_START', 'SAL_STOP')")
    rows = cursor.fetchall()
    for r in rows:
        print(f"Code: {r[0]}, Value: {r[1]}")
except Exception as e:
    print(f"Error querying tblParameter: {e}")

# 2. Let's query all parameters to see what's in there
print("\n=== Querying all parameters like SAL% ===")
try:
    cursor.execute("SELECT Code, Value, Description FROM tblParameter WHERE Code LIKE 'SAL%'")
    rows = cursor.fetchall()
    for r in rows:
        print(f"Code: {r[0]}, Value: {r[1]}, Description: {r[2]}")
except Exception as e:
    print(f"Error querying tblParameter SAL%: {e}")

# 3. Test dbo.fn_Get_SalaryPeriod function
print("\n=== Testing dbo.fn_Get_SalaryPeriod ===")
try:
    # Let's test with month 5, year 2026 and other months
    for month in [1, 2, 3, 4, 5, 12]:
        cursor.execute("SELECT * FROM dbo.fn_Get_SalaryPeriod(?, ?)", (month, 2026))
        row = cursor.fetchone()
        if row:
            # Let's see columns description
            cols = [col[0] for col in cursor.description]
            print(f"Month {month}/2026: {dict(zip(cols, row))}")
except Exception as e:
    print(f"Error calling dbo.fn_Get_SalaryPeriod: {e}")

# 4. Show SQL definition of dbo.fn_Get_SalaryPeriod if available
print("\n=== Definition of dbo.fn_Get_SalaryPeriod ===")
try:
    cursor.execute("SELECT definition FROM sys.sql_modules WHERE object_id = OBJECT_ID('dbo.fn_Get_SalaryPeriod')")
    row = cursor.fetchone()
    if row:
        print(row[0])
    else:
        print("Not found")
except Exception as e:
    print(f"Error reading function definition: {e}")

# 5. Query tblSal_Lock_Period1 to see actual data
print("\n=== Data in tblSal_Lock_Period1 (last 5 rows) ===")
try:
    cursor.execute("SELECT TOP 5 * FROM tblSal_Lock_Period1 ORDER BY Year DESC, Month DESC")
    cols = [col[0] for col in cursor.description]
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))
except Exception as e:
    print(f"Error reading tblSal_Lock_Period1: {e}")

conn_vietinsoft.close()
