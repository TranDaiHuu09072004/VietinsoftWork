import pyodbc

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM dbo.fn_vtblEmployeeList_Bydate('2026-03-16', '008', NULL)")
    rows = cursor.fetchall()
    print("Employee list results:", len(rows))
    for r in rows:
        print(r)
    conn.close()
except Exception as e:
    print("Error:", e)
