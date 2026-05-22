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

print("--- Top 10 Highest Salaries in tblSalaryHistory ---")
query_salary_history = """
SELECT TOP 10 sh.EmployeeID, emp.FullName, sh.Date, sh.Salary, sh.NETSalary, sh.Note
FROM tblSalaryHistory sh
LEFT JOIN tblEmployee emp ON sh.EmployeeID = emp.EmployeeID
ORDER BY sh.Salary DESC
"""
cursor.execute(query_salary_history)
rows = cursor.fetchall()
for r in rows:
    sal_val = f"{r[3]:,.2f}" if r[3] is not None else "N/A"
    net_val = f"{r[4]:,.2f}" if r[4] is not None else "N/A"
    print(f"EmployeeID: {r[0]}, Name: {r[1]}, Date: {r[2]}, Salary: {sal_val}, NETSalary: {net_val}, Note: {r[5]}")


print("\n--- Columns in tblLabourContract ---")
cursor.execute("SELECT TOP 0 * FROM tblLabourContract")
columns = [col[0] for col in cursor.description]
print(", ".join(columns))

# Let's search for columns in tblLabourContract that might be salary-related
salary_cols = [c for c in columns if any(kw in c.lower() for kw in ['salary', 'luong', 'pay', 'money', 'allowance'])]
print(f"Salary related columns in tblLabourContract: {salary_cols}")

print("\n--- Top 10 Highest Salaries in tblLabourContract (using any salary columns found) ---")
if salary_cols:
    # Let's see if there is 'Salary' or similar
    main_sal_col = 'Salary' if 'Salary' in salary_cols else (salary_cols[0] if salary_cols else None)
    if main_sal_col:
        query_contract = f"""
        SELECT TOP 10 c.EmployeeID, emp.FullName, c.ContractNo, c.SignDate, c.{main_sal_col}
        FROM tblLabourContract c
        LEFT JOIN tblEmployee emp ON c.EmployeeID = emp.EmployeeID
        ORDER BY c.{main_sal_col} DESC
        """
        try:
            cursor.execute(query_contract)
            rows = cursor.fetchall()
            for r in rows:
                sal_val = f"{r[4]:,.2f}" if r[4] is not None else "N/A"
                print(f"EmployeeID: {r[0]}, Name: {r[1]}, ContractNo: {r[2]}, SignDate: {r[3]}, {main_sal_col}: {sal_val}")
        except Exception as e:
            print(f"Error querying tblLabourContract: {e}")

conn_vietinsoft.close()
