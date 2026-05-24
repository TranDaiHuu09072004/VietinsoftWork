import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

def query_allowance_setting(db_name):
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
        cursor.execute("SELECT AllowanceCode, AllowanceName, ForSalary, IncludedIns FROM tblAllowanceSetting")
        rows = cursor.fetchall()
        print(f"\n==================================================")
        print(f"Database: {db_name}")
        print(f"==================================================")
        print(f"{'AllowanceCode':<15} | {'AllowanceName':<25} | {'ForSalary':<10} | {'IncludedIns':<10}")
        print("-" * 70)
        for r in rows:
            print(f"{str(r[0]):<15} | {str(r[1]):<25} | {str(r[2]):<10} | {str(r[3]):<10}")
        conn.close()
    except Exception as e:
        print(f"Error: {e}")

query_allowance_setting("Paradise_Dev")
query_allowance_setting("Vietinsoft_ForTest")
