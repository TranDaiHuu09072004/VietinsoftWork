import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=SVRVTS01\\SQL6688;"
    "DATABASE=Vietinsoft_Pay;"
    "Trusted_Connection=yes;"
)

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    cursor.execute("SELECT @@VERSION")
    print("Success! SQL Server version:")
    print(cursor.fetchone()[0])
    conn.close()
except Exception as e:
    print("Error:", e)
