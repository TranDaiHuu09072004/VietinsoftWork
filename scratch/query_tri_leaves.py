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

cursor = conn_vietinsoft.cursor()

def check_leave_table(table_name):
    print(f"\n===== Leave records in {table_name} for 2026 =====")
    cursor.execute(f"SELECT TOP 0 * FROM {table_name}")
    cols = [col[0] for col in cursor.description]
    
    # We find if there is a start date or leave date field
    date_col = next((c for c in cols if any(kw in c.lower() for kw in ['date', 'time', 'day'])), None)
    
    if date_col:
        query = f"""
        SELECT * FROM {table_name}
        WHERE EmployeeID = '004' AND {date_col} >= '2026-01-01'
        """
    else:
        query = f"""
        SELECT * FROM {table_name}
        WHERE EmployeeID = '004'
        """
    try:
        cursor.execute(query)
        rows = cursor.fetchall()
        if rows:
            for r in rows:
                print(dict(zip(cols, r)))
        else:
            print("No records found.")
    except Exception as e:
        print(f"Error querying {table_name}: {e}")

check_leave_table("tblLeaveRequest")
check_leave_table("tblLeaveRegistered")

conn_vietinsoft.close()
