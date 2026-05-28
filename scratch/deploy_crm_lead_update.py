import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

script_path = r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\update_tblCRM_CustomerPersonInfo_IsCRMLead_20260527.sql"
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
            
    print("\nModification script deployed successfully!")
    
    # 3. Verification
    print("\n=== Verifying Migration Results ===")
    
    # Verify column existence
    cursor.execute("""
        SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'tblCRM_CustomerPersonInfo' AND COLUMN_NAME = 'IsCRMLead'
    """)
    col_row = cursor.fetchone()
    if col_row:
        print(f"SUCCESS: Column '{col_row[0]}' exists! Type: {col_row[1]}, Nullable: {col_row[2]}.")
    else:
        print("ERROR: Column 'IsCRMLead' NOT found in tblCRM_CustomerPersonInfo!")
        
    # Verify procedure code
    # We query using OBJECT_DEFINITION to see if it includes IsCRMLead
    cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID('sp_ContactCustommer_Update'))")
    proc_defn = cursor.fetchone()[0]
    if "IsCRMLead" in proc_defn:
        print("SUCCESS: Stored procedure sp_ContactCustommer_Update successfully contains 'IsCRMLead'!")
    else:
        print("ERROR: Stored procedure sp_ContactCustommer_Update does NOT contain 'IsCRMLead'!")

    conn.close()
    print("\nDeployment and verification finished successfully.")
except Exception as e:
    print("\nExecution Error:", e)
    sys.exit(1)
