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
    
    cursor.execute("""
        SELECT YEAR(AttTime) as Y, MONTH(AttTime) as M, COUNT(*), COUNT(DISTINCT EmployeeID)
        FROM tblTmpAttend
        GROUP BY YEAR(AttTime), MONTH(AttTime)
        ORDER BY Y DESC, M DESC
    """)
    for row in cursor.fetchall():
        print(f"Year: {row[0]} | Month: {row[1]} | Count: {row[2]} | Distinct Emps: {row[3]}")
    conn.close()
except Exception as e:
    print("Error:", e)
