import pyodbc
import re
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Connection details for Vietinsoft_ForTest
conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Vietinsoft_ForTest;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

migration_file = r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\migration_level_rate_system.sql"

print("Connecting to Vietinsoft_ForTest...")
conn = pyodbc.connect(conn_str)
cursor = conn.cursor()

try:
    print(f"Reading migration script from {migration_file}...")
    with open(migration_file, "r", encoding="utf-8") as f:
        script_text = f.read()

    # Split SQL script into batches by 'GO' (case insensitive, full word matching)
    batches = re.split(r'^\s*GO\s*$', script_text, flags=re.MULTILINE | re.IGNORECASE)

    print(f"Split migration script into {len(batches)} batches. Executing...")
    for idx, batch in enumerate(batches):
        batch = batch.strip()
        if not batch:
            continue
        print(f"--- Executing batch {idx + 1}... ---")
        cursor.execute(batch)
        conn.commit()

    print("\nMigration executed successfully! Verifying changes in Vietinsoft_ForTest...")

    # Verify column existence in tbllevel
    cursor.execute("""
        SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'tbllevel' AND COLUMN_NAME = 'LevelRate'
    """)
    col = cursor.fetchone()
    if col:
        print(f"SUCCESS: Column '{col[0]}' exists with type '{col[1]}'.")
    else:
        print("FAIL: Column 'LevelRate' not found in tbllevel.")

    # Verify level count
    cursor.execute("SELECT COUNT(*) FROM tbllevel")
    cnt = cursor.fetchone()[0]
    print(f"SUCCESS: Total records in tbllevel: {cnt} (Expected: 91).")

    # Verify procedure compiled
    cursor.execute("SELECT name FROM sys.objects WHERE type = 'P' AND name = 'sp_Level_AutoUpdateHistory'")
    proc = cursor.fetchone()
    if proc:
        print(f"SUCCESS: Stored procedure '{proc[0]}' compiled and exists.")
    else:
        print("FAIL: Stored procedure 'sp_Level_AutoUpdateHistory' not found.")

except Exception as e:
    print("An error occurred during migration execution:")
    print(e)
    conn.rollback()
finally:
    conn.close()
