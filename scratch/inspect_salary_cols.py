import pyodbc

# Connection details for Vietinsoft_Pay
conn_vietinsoft = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,6688;"
    "DATABASE=Vietinsoft_Pay;"
    "UID=ai.sa;"
    "PWD=ThoiDaiVibeCodeIA@2026;"
    "TrustServerCertificate=yes;"
)

def print_columns(conn, table_name):
    print(f"\n===== Columns in {table_name} =====")
    cursor = conn.cursor()
    try:
        for row in cursor.columns(table=table_name):
            print(f"Column: {row.column_name}, Type: {row.type_name}, Size: {row.column_size}")
    except Exception as e:
        print(f"Error reading {table_name}: {e}")
    cursor.close()

print_columns(conn_vietinsoft, "tblLabourContract")
print_columns(conn_vietinsoft, "tblEmployee")
print_columns(conn_vietinsoft, "tblSalaryHistory")
print_columns(conn_vietinsoft, "tblSalaryTable")

conn_vietinsoft.close()
