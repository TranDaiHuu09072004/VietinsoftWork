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

def inspect_table_data(table_name, filter_expr=None):
    print(f"\n===== Table: {table_name} =====")
    # Print columns
    cols = [row.column_name for row in cursor.columns(table=table_name)]
    print(f"Columns: {', '.join(cols)}")
    
    # Print sample data
    sql = f"SELECT TOP 5 * FROM {table_name}"
    if filter_expr:
        sql += f" WHERE {filter_expr}"
    cursor.execute(sql)
    rows = cursor.fetchall()
    for r in rows:
        print(dict(zip(cols, r)))

inspect_table_data("tblSal_Allowance")
inspect_table_data("tblSal_Allowance_Detail")
inspect_table_data("tblPR_EmpAllowance", "EmployeeID = '004'")
inspect_table_data("tblAllowanceRule")
inspect_table_data("tblAllowanceSetting")

conn_vietinsoft.close()
