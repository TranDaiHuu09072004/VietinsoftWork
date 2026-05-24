import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Connection details for Vietinsoft_Pay
conn = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,6688;"
    "DATABASE=Vietinsoft_Pay;"
    "UID=ai.sa;"
    "PWD=ThoiDaiVibeCodeIA@2026;"
    "TrustServerCertificate=yes;"
)

cursor = conn.cursor()

# 1. Schema and sample data of tbllevel
print("=== Schema and Data of tbllevel ===")
try:
    cursor.execute("SELECT TOP 0 * FROM tbllevel")
    cols = [col[0] for col in cursor.description]
    print("Columns:", cols)
    cursor.execute("SELECT * FROM tbllevel")
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))
except Exception as e:
    print(f"Error: {e}")

# 2. Get the full JOIN logic for tblLevelIDHistory in fn_vtblEmployeeList_Bydate
print("\n=== JOIN Logic for Level in fn_vtblEmployeeList_Bydate ===")
try:
    cursor.execute("SELECT definition FROM sys.sql_modules WHERE object_id = OBJECT_ID('dbo.fn_vtblEmployeeList_Bydate')")
    row = cursor.fetchone()
    if row:
        def_text = row[0]
        # Find where tblLevelIDHistory or ' lv ' is referenced
        idx = def_text.lower().find("tbllevelidhistory")
        if idx == -1:
            idx = def_text.lower().find(" levelid ")
        if idx != -1:
            start = max(0, idx - 100)
            end = min(len(def_text), idx + 800)
            print(def_text[start:end])
        else:
            print("tblLevelIDHistory reference not found by text search, showing part of definition:")
            print(def_text[:1000])
except Exception as e:
    print(f"Error: {e}")

# 3. Check some sample records in tblLevelIDHistory
print("\n=== Sample records from tblLevelIDHistory ===")
try:
    cursor.execute("SELECT TOP 10 * FROM tblLevelIDHistory ORDER BY EffectiveDate DESC")
    cols = [col[0] for col in cursor.description]
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))
except Exception as e:
    print(f"Error: {e}")

conn.close()
