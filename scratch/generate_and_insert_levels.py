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

sql_script = """-- T-SQL Script to merge levels from 1.0 to 10.0 into tbllevel
-- Range: LevelID 1 to 91, LevelRate 1.0 to 10.0

WITH LevelCTE AS (
    SELECT 
        1 AS LevelID,
        CAST('Gb1' AS NVARCHAR(50)) AS LevelName,
        CAST('Gb1' AS NVARCHAR(50)) AS LevelNameEN,
        CAST(1.0 AS DECIMAL(10, 4)) AS LevelRate
    UNION ALL
    SELECT 
        LevelID + 1,
        CAST('Gb' + CAST(LevelID + 1 AS NVARCHAR(10)) AS NVARCHAR(50)) AS LevelName,
        CAST('Gb' + CAST(LevelID + 1 AS NVARCHAR(10)) AS NVARCHAR(50)) AS LevelNameEN,
        CAST(LevelRate + 0.1 AS DECIMAL(10, 4)) AS LevelRate
    FROM LevelCTE
    WHERE LevelID < 91
)
MERGE INTO tbllevel AS target
USING LevelCTE AS source
ON target.LevelID = source.LevelID
WHEN MATCHED THEN
    UPDATE SET 
        target.LevelName = source.LevelName,
        target.LevelNameEN = source.LevelNameEN,
        target.LevelRate = source.LevelRate
WHEN NOT MATCHED THEN
    INSERT (LevelID, LevelName, LevelNameEN, Note, LevelRate)
    VALUES (source.LevelID, source.LevelName, source.LevelNameEN, NULL, source.LevelRate)
OPTION (MAXRECURSION 100);
"""

# Write the SQL script file for reference
sql_file_path = r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\scratch\insert_tbllevel_records.sql"
with open(sql_file_path, "w", encoding="utf-8") as f:
    f.write(sql_script)
print(f"SQL script saved to {sql_file_path}")

try:
    print("Executing MERGE statement on tbllevel in Paradise_Dev...")
    cursor.execute(sql_script)
    conn.commit()
    print("Execution completed successfully.")

    # Let's check row count and some sample values
    cursor.execute("SELECT COUNT(*) FROM tbllevel")
    count = cursor.fetchone()[0]
    print(f"Total records in tbllevel: {count}")

    print("\nFirst 5 records in tbllevel:")
    cursor.execute("SELECT TOP 5 * FROM tbllevel ORDER BY LevelID")
    cols = [col[0] for col in cursor.description]
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))

    print("\nLast 5 records in tbllevel:")
    cursor.execute("SELECT TOP 5 * FROM tbllevel ORDER BY LevelID DESC")
    cols = [col[0] for col in cursor.description]
    for r in cursor.fetchall():
        print(dict(zip(cols, r)))

except Exception as e:
    print(f"An error occurred: {e}")
    conn.rollback()
finally:
    conn.close()
