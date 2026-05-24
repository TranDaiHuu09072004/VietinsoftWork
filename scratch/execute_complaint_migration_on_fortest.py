import pyodbc
import re
from pathlib import Path

# Load migration file
migration_file = Path(r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\migrate_menu_complaint_20260523.sql")
migration_sql = migration_file.read_text(encoding="utf-8")

# Parse SQL into batches separated by GO (case insensitive, full word matching on single line)
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

# Connection details for Vietinsoft_ForTest
conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Vietinsoft_ForTest;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

try:
    print("Connecting to Vietinsoft_ForTest...")
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    print(f"Executing migration batches ({len(batches)} total)...")
    for idx, batch in enumerate(batches, 1):
        batch_trimmed = batch.strip()
        if not batch_trimmed:
            continue
        print(f"Running batch {idx}...")
        try:
            cursor.execute(batch_trimmed)
            conn.commit()
        except Exception as batch_error:
            print(f"Error in batch {idx}: {batch_error}")
            print("Batch content preview:")
            print("\n".join(batch_trimmed.splitlines()[:10]))
            print("...")
            conn.rollback()
            raise batch_error
        
    print("\nMigration to Vietinsoft_ForTest executed successfully!")
    
    # Run verification query
    print("\nRunning verification query on Vietinsoft_ForTest:")
    cursor.execute("""
        SELECT m.MenuID, m.ClassName, m.AssemblyName, m.ParentMenuID,
               o.ObjectID, o.ObjectName,
               msgVN.Content AS NameVN, msgEN.Content AS NameEN,
               (SELECT COUNT(*) FROM tblSC_Right_Stored WHERE ObjectID = o.ObjectID) AS RightsCount,
               (SELECT COUNT(*) FROM tblHtmlScriptCache WHERE TableName = m.ClassName) AS CacheLangsCount
        FROM MEN_Menu m
        LEFT JOIN tblSC_Object o ON o.Description = m.MenuID
        LEFT JOIN tblMD_Message msgVN ON msgVN.MessageID = m.MenuID AND msgVN.Language = 'VN'
        LEFT JOIN tblMD_Message msgEN ON msgEN.MessageID = m.MenuID AND msgEN.Language = 'EN'
        WHERE m.MenuID IN ('MnuAT009', 'MnuAT010')
    """)
    for r in cursor.fetchall():
        print(f"MenuID: {r[0]} | Class: {r[1]} | Assembly: {r[2]} | Parent: {r[3]} | ObjectID: {r[4]} | NameVN: {r[6]} | Rights: {r[8]} | CacheLangs: {r[9]}")
        
    conn.close()
except Exception as e:
    print(f"Migration execution failed: {e}")
