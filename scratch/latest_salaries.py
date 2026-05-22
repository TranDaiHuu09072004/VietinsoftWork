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

# Get the latest salary for each employee
query = """
WITH LatestSalaries AS (
    SELECT sh.EmployeeID, emp.FullName, sh.Date, sh.Salary, sh.NETSalary,
           ROW_NUMBER() OVER (PARTITION BY sh.EmployeeID ORDER BY sh.Date DESC) as rn
    FROM tblSalaryHistory sh
    LEFT JOIN tblEmployee emp ON sh.EmployeeID = emp.EmployeeID
)
SELECT EmployeeID, FullName, Date, Salary, NETSalary
FROM LatestSalaries
WHERE rn = 1
ORDER BY Salary DESC
"""

cursor.execute(query)
rows = cursor.fetchall()
print("Latest salaries for all employees in Vietinsoft_Pay:")
for r in rows:
    sal_val = f"{r[3]:,.2f}" if r[3] is not None else "N/A"
    net_val = f"{r[4]:,.2f}" if r[4] is not None else "N/A"
    print(f"EmployeeID: {r[0]} | Name: {r[1]} | Date: {r[2]} | Salary: {sal_val} | NETSalary: {net_val}")

conn_vietinsoft.close()
