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

print("=== tblSal_Allowance_Detail for Feb 2026 ===")
cursor.execute("""
    SELECT EmployeeID, AllowanceID, SalaryHistoryID, Amount, DefaultAmount, TotalPaidDays
    FROM tblSal_Allowance_Detail
    WHERE EmployeeID = '004' AND Year = 2026 AND Month = 2
""")
rows = cursor.fetchall()
for r in rows:
    print(f"SalaryHistoryID: {r[2]} | Amount: {r[3]:,.0f} | DefaultAmount: {r[4]:,.0f} | TotalPaidDays: {r[5]}")

print("\n=== tblSalaryHistory for Employee 004 around Feb 2026 ===")
cursor.execute("""
    SELECT SalaryHistoryID, Date, Salary, Per_Rate, Note
    FROM tblSalaryHistory
    WHERE EmployeeID = '004' AND Date >= '2025-01-01'
    ORDER BY Date
""")
rows = cursor.fetchall()
for r in rows:
    per_rate_val = f"{r[3]:,.0f}" if r[3] is not None else "None"
    print(f"SalaryHistoryID: {r[0]} | Date: {r[1]} | Salary: {r[2]:,.0f} | Per_Rate: {per_rate_val} | Note: {r[4]}")

conn_vietinsoft.close()
