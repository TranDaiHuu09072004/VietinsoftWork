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

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    print("=== Raw tblLevelIDHistory ===")
    cursor.execute("SELECT EmployeeID, LevelID, EffectiveDate, Remark FROM tblLevelIDHistory")
    for r in cursor.fetchall():
        print(f"Emp: {r[0]:<5} | LevelID: {r[1]:<3} | EffectiveDate: {r[2]} | Remark: {r[3]}")
        
    conn.close()
except Exception as e:
    print(f"Error: {e}")
