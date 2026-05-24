import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Vietinsoft_ForTest;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

try:
    print("=== Searching for columns matching AllowanceCodes in sys.columns ===")
    cursor.execute("""
        SELECT t.name AS TableName, c.name AS ColumnName
        FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        WHERE c.name IN ('Per_Rate', 'csac', 'Trans_AL', 'Pos_AL')
        ORDER BY t.name
    """)
    for r in cursor.fetchall():
        print(f"Table: {r[0]}, Column: {r[1]}")
        
    print("\n=== Checking counts of rows in tblEmployeeAllowance & tblPR_EmpAllowance ===")
    for table in ['tblEmployeeAllowance', 'tblPR_EmpAllowance', 'tblSal_Allowance', 'tblSal_Allowance_Detail']:
        try:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            cnt = cursor.fetchone()[0]
            print(f"Table {table}: {cnt} rows")
        except Exception as e:
            print(f"Table {table} error: {e}")

except Exception as e:
    print(e)
finally:
    conn.close()
