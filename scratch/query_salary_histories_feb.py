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
query = """
SELECT sh.EmployeeID, emp.FullName, sh.SalaryHistoryID, sh.Date, sh.Salary, sh.Per_Rate
FROM tblSalaryHistory sh
JOIN tblEmployee emp ON sh.EmployeeID = emp.EmployeeID
WHERE sh.Date >= '2026-02-01' AND sh.Date < '2026-03-01'
ORDER BY sh.EmployeeID, sh.Date
"""
cursor.execute(query)
rows = cursor.fetchall()
print("Salary history changes in Feb 2026:")
for r in rows:
    per_rate_val = f"{r[5]:,.0f}" if r[5] is not None else "0"
    print(f"EmpID: {r[0]} | Name: {r[1]} | HistoryID: {r[2]} | Date: {r[3]} | Salary: {r[4]:,.0f} | Per_Rate: {per_rate_val}")

conn_vietinsoft.close()
