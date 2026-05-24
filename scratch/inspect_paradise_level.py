import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Connection details for Paradise_Dev
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

cursor = conn.cursor()

print("=== Columns in tbllevel (Paradise_Dev) ===")
try:
    cursor.execute("SELECT TOP 0 * FROM tbllevel")
    cols = [col[0] for col in cursor.description]
    print("Columns:", cols)
    
    # Check column data types
    cursor.execute("""
        SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'tbllevel'
    """)
    for r in cursor.fetchall():
        print(r)
except Exception as e:
    print(f"Error checking tbllevel in Paradise_Dev: {e}")

print("\n=== Current data in tbllevel (Paradise_Dev) ===")
try:
    cursor.execute("SELECT * FROM tbllevel")
    cols = [col[0] for col in cursor.description]
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))
except Exception as e:
    print(f"Error reading tbllevel in Paradise_Dev: {e}")

conn.close()
