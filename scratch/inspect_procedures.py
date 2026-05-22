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

# Connection details for Paradise_Dev
conn_paradise = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

def inspect_procedures(conn, db_name):
    print(f"\n===== Procedures in {db_name} =====")
    cursor = conn.cursor()
    cursor.execute("""
        SELECT o.name, o.type_desc, LEN(m.definition) as def_len
        FROM sys.objects o
        JOIN sys.sql_modules m ON o.object_id = m.object_id
        WHERE o.name LIKE '%ResignationLeave%'
    """)
    rows = cursor.fetchall()
    for row in rows:
        print(f"Name: {row[0]}, Type: {row[1]}, Def Length: {row[2]}")
        # Print first 200 chars of definition
        cursor.execute("SELECT definition FROM sys.sql_modules WHERE object_id = OBJECT_ID(?)", (row[0],))
        defn = cursor.fetchone()[0]
        print("--- Definition excerpt (first 300 chars): ---")
        print(defn[:300])
        print("---------------------------------------------")
    cursor.close()

inspect_procedures(conn_vietinsoft, "Vietinsoft_Pay")
inspect_procedures(conn_paradise, "Paradise_Dev")

conn_vietinsoft.close()
conn_paradise.close()
