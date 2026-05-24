import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

print("Testing connection to Vietinsoft_ForTest with Paradise_Dev credentials...")

try:
    conn = pyodbc.connect(
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=192.168.11.51,2222;"
        "DATABASE=Vietinsoft_ForTest;"
        "UID=vts.sa;"
        "PWD=LuaThieng1@3@2020;"
        "TrustServerCertificate=yes;"
    )
    cursor = conn.cursor()
    print("Connection SUCCESSFUL!")
    
    # Query database name
    cursor.execute("SELECT DB_NAME()")
    print("Connected to database:", cursor.fetchone()[0])
    
    # List top 5 tables
    cursor.execute("SELECT TOP 5 name FROM sys.tables ORDER BY name")
    print("Top 5 tables:")
    for r in cursor.fetchall():
        print(" -", r[0])
        
    conn.close()
except Exception as e:
    print("Connection FAILED!")
    print("Error:", e)
