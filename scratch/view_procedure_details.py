import pyodbc
import sys
import os

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

def save_procedure(conn, proc_name, file_path):
    cursor = conn.cursor()
    cursor.execute("SELECT definition FROM sys.sql_modules WHERE object_id = OBJECT_ID(?)", (proc_name,))
    row = cursor.fetchone()
    if row and row[0]:
        with open(file_path, "w", encoding="utf-8") as f:
            f.write(row[0])
        print(f"Saved {proc_name} definition to {file_path} (length: {len(row[0])})")
    else:
        print(f"Procedure {proc_name} not found or has no definition.")
    cursor.close()

os.makedirs("scratch/procedures", exist_ok=True)
save_procedure(conn_vietinsoft, "sp_ResignationLeave", "scratch/procedures/vietinsoft_sp_ResignationLeave.sql")
save_procedure(conn_vietinsoft, "sp_ResignationLeave_Mobile", "scratch/procedures/vietinsoft_sp_ResignationLeave_Mobile.sql")

save_procedure(conn_paradise, "sp_ResignationLeave", "scratch/procedures/paradise_sp_ResignationLeave.sql")
save_procedure(conn_paradise, "sp_ResignationLeave_html", "scratch/procedures/paradise_sp_ResignationLeave_html.sql")
save_procedure(conn_paradise, "sp_ResignationLeave_Mobile", "scratch/procedures/paradise_sp_ResignationLeave_Mobile.sql")

conn_vietinsoft.close()
conn_paradise.close()
