import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

script_path = r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\create_rpt_EmployeeSalary_Jan2025.sql"
db_name = "Paradise_Dev"

conn_base = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

try:
    # 1. Read SQL Script
    with open(script_path, "r", encoding="utf-8") as f:
        script_sql = f.read()
        
    # Split into batches by GO
    batches = []
    current_batch = []
    for line in script_sql.splitlines():
        if line.strip().upper() == "GO":
            if current_batch:
                batches.append("\n".join(current_batch))
                current_batch = []
        else:
            current_batch.append(line)
    if current_batch:
        batches.append("\n".join(current_batch))
        
    # 2. Connect to Paradise_Dev and deploy
    print(f"Connecting to database: {db_name}...")
    conn_str = f"{conn_base}DATABASE={db_name};"
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    print("\n=== Executing Migration Script Batches ===")
    for idx, batch in enumerate(batches, 1):
        batch_trimmed = batch.strip()
        if not batch_trimmed or batch_trimmed.startswith("PRINT"):
            continue
        try:
            cursor.execute(batch_trimmed)
            conn.commit()
            print(f"Successfully deployed batch {idx}.")
        except Exception as be:
            print(f"Error in batch {idx}: {be}")
            print("Batch content:")
            print(batch_trimmed[:300])
            raise be
            
    print("\nProcedure compiled and deployed successfully!")
    
    # 3. Test execution
    print("\n=== Test Executing dbo.sp_Report_EmployeeSalary_Jan2025 ===")
    # LoginID = 3 (Admin)
    cursor.execute("EXEC dbo.sp_Report_EmployeeSalary_Jan2025 @LoginID = 3")
    rows = cursor.fetchall()
    columns = [column[0] for column in cursor.description]
    
    print(f"Returned {len(rows)} rows.")
    print("Columns returned:")
    print(" | ".join(columns))
    
    if rows:
        print("\nFirst 3 rows of data:")
        for r in rows[:3]:
            print(" | ".join(str(val) for val in r))
            
    conn.close()
    print("\nValidation finished successfully.")
except Exception as e:
    print("\nExecution Error:", e)
    sys.exit(1)
