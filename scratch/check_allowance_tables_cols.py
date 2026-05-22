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

cursor = conn_vietinsoft.cursor()
for table in ['tblSal_Allowance', 'tblSal_Allowance_Detail']:
    print(f"\nColumns in {table}:")
    cursor.execute(f"SELECT TOP 0 * FROM {table}")
    print([col[0] for col in cursor.description])

conn_vietinsoft.close()
