import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

def print_sp_definition(db_name):
    conn_str = (
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=192.168.11.51,2222;"
        f"DATABASE={db_name};"
        "UID=vts.sa;"
        "PWD=LuaThieng1@3@2020;"
        "TrustServerCertificate=yes;"
    )
    try:
        conn = pyodbc.connect(conn_str)
        cursor = conn.cursor()
        cursor.execute("SELECT definition FROM sys.sql_modules WHERE object_id = OBJECT_ID('sp_Level_AutoUpdateHistory')")
        row = cursor.fetchone()
        print(f"\n==================================================")
        print(f"Database: {db_name}")
        print(f"==================================================")
        if row and row[0]:
            print(row[0])
        else:
            print("Procedure not found.")
        conn.close()
    except Exception as e:
        print(f"Error connecting to {db_name}: {e}")

print_sp_definition("Paradise_Dev")
print_sp_definition("Vietinsoft_ForTest")
