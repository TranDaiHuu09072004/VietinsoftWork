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
SELECT sa.EmployeeID, emp.FullName, s.AllowanceName, sa.Amount, sa.DefaultAmount, sa.TotalPaidDays, r.Description, r.FullPackage
FROM tblSal_Allowance_Detail sa
JOIN tblAllowanceSetting s ON sa.AllowanceID = s.AllowanceID
LEFT JOIN tblAllowanceRule r ON s.AllowanceRuleID = r.AllowanceRuleID
LEFT JOIN tblEmployee emp ON sa.EmployeeID = emp.EmployeeID
WHERE sa.Year = 2026 AND sa.Month = 2
ORDER BY sa.Amount DESC
"""
cursor.execute(query)
rows = cursor.fetchall()
print("All employee allowances in Feb 2026:")
for r in rows:
    amount = f"{r[3]:,.0f}" if r[3] is not None else "N/A"
    default_amount = f"{r[4]:,.0f}" if r[4] is not None else "N/A"
    print(f"EmpID: {r[0]} | Name: {r[1]} | Allowance: {r[2]} | Amount: {amount} | Default: {default_amount} | Paid Days: {r[5]} | Rule: {r[6]} (FullPackage: {r[7]})")

conn_vietinsoft.close()
