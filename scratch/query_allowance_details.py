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
SELECT sa.Year, sa.Month, sa.AllowanceID, s.AllowanceName, s.AllowanceCode,
       sa.Amount, sa.DefaultAmount, sa.TotalPaidDays, r.AllowanceRuleID, r.Description as RuleDescription, r.FullPackage
FROM tblSal_Allowance_Detail sa
JOIN tblAllowanceSetting s ON sa.AllowanceID = s.AllowanceID
LEFT JOIN tblAllowanceRule r ON s.AllowanceRuleID = r.AllowanceRuleID
WHERE sa.EmployeeID = '004'
ORDER BY sa.Year DESC, sa.Month DESC, sa.AllowanceID
"""
cursor.execute(query)
rows = cursor.fetchall()
print("Nguyen Minh Tri Allowance Details:")
for r in rows:
    print(f"Year: {r[0]}, Month: {r[1]} | Name: {r[3]} ({r[4]}) | Amount: {r[5]:,.0f} | Default: {r[6]:,.0f} | Paid Days: {r[7]} | Rule: {r[9]} (FullPackage: {r[10]})")

conn_vietinsoft.close()
