import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

cursor = conn.cursor()
cursor.execute("SELECT definition FROM sys.sql_modules WHERE object_id = OBJECT_ID('sp_Level_AutoUpdateHistory')")
row = cursor.fetchone()
if row and row[0]:
    print("=== sp_Level_AutoUpdateHistory compiled definition ===")
    print(row[0])
else:
    print("Procedure not found.")
conn.close()
