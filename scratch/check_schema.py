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

# Connection details for Paradise_Dev
conn_paradise = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

def print_columns(conn, db_name):
    print(f"\n===== Columns in {db_name}.dbo.tblHtmlScriptCache =====")
    cursor = conn.cursor()
    for row in cursor.columns(table='tblHtmlScriptCache'):
        print(f"Column: {row.column_name}, Type: {row.type_name}, Size: {row.column_size}, Nullable: {row.is_nullable}")
    cursor.close()

print_columns(conn_vietinsoft, "Vietinsoft_Pay")
print_columns(conn_paradise, "Paradise_Dev")

conn_vietinsoft.close()
conn_paradise.close()
