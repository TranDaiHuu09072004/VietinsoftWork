import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

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
    
    cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID('sp_Task_TaskDetail'))")
    defn = cursor.fetchone()[0]
    if defn:
        print("=== sp_Task_TaskDetail Definition ===")
        print(defn[:1500])
        print("... [TRUNCATED] ...")
    else:
        print("sp_Task_TaskDetail not found.")
        
    conn.close()
except Exception as e:
    print("Error:", e)
