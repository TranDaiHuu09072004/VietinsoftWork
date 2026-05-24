import pyodbc
import re
from pathlib import Path

# Load migration file
migration_file = Path(r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\migration_kpi_level_xp.sql")
migration_sql = migration_file.read_text(encoding="utf-8")

# Parse SQL into batches separated by GO
batches = []
current_batch = []
for line in migration_sql.splitlines():
    if line.strip().upper() == "GO":
        if current_batch:
            batches.append("\n".join(current_batch))
            current_batch = []
    else:
        current_batch.append(line)
if current_batch:
    batches.append("\n".join(current_batch))

# Connection details
conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

try:
    print("Connecting to Paradise_Dev...")
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    print("Executing migration batches...")
    for idx, batch in enumerate(batches, 1):
        batch_trimmed = batch.strip()
        if not batch_trimmed:
            continue
        print(f"Running batch {idx}...")
        cursor.execute(batch_trimmed)
        conn.commit()
        
    print("Migration execution completed successfully.")
    
    # Test execution of sp_PerformanceKPI_Working_Process
    print("Executing sp_PerformanceKPI_Working_Process for testing...")
    # Using isDebug = 1 and specific dates, loginID = 3
    cursor.execute("EXEC sp_PerformanceKPI_Working_Process '2026-05-10', '2026-06-10', '008', 3, 1")
    conn.commit()
    print("Procedure run successful!")
    
    conn.close()
except Exception as e:
    print(f"Error occurred: {e}")
