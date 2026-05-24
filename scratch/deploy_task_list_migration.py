import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

script_path = r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\migrate_menu_task_list_20260523.sql"
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
        except Exception as be:
            print(f"Error in batch {idx}: {be}")
            print("Batch content:")
            print(batch_trimmed[:300])
            raise be
            
    print("\nMigration script deployed successfully!")
    
    # 3. Clear and rebuild caches for sp_Task_TaskList
    print("\n=== Rebuilding HTML Caches ===")
    
    # Clear existing caches first
    cursor.execute("""
        DELETE FROM tblHtmlScriptCache 
        WHERE TableName IN ('sp_Task_TaskList', 'sp_Task_TaskList_html')
    """)
    conn.commit()
    print(f"Deleted {cursor.rowcount} cache rows.")
    
    generators = [
        ('sp_Task_TaskList_html', 'VN', 'sp_Task_TaskList'),
        ('sp_Task_TaskList_html', 'EN', 'sp_Task_TaskList'),
        ('sp_Task_TaskList_html', 'VN', 'sp_Task_TaskList_html'),
        ('sp_Task_TaskList_html', 'EN', 'sp_Task_TaskList_html'),
    ]
    
    for proc, lang, table in generators:
        print(f"Executing sp_GenerateHTMLScript '{proc}', '{lang}', '{table}'...")
        cursor.execute("EXEC dbo.sp_GenerateHTMLScript ?, ?, ?", proc, lang, table)
        
        # Consume all result sets
        set_idx = 1
        while True:
            if cursor.description:
                cursor.fetchall()
            if not cursor.nextset():
                break
            set_idx += 1
        conn.commit()
        
    # 4. Verify results
    print("\n=== Verifying Migration Results ===")
    
    # Verify cache table
    cursor.execute("""
        SELECT TableName, LanguageID, LEN(html), CHARINDEX('fa-plus', html)
        FROM tblHtmlScriptCache
        WHERE TableName IN ('sp_Task_TaskList', 'sp_Task_TaskList_html')
    """)
    rows = cursor.fetchall()
    print(f"Found {len(rows)} entries in tblHtmlScriptCache:")
    for r in rows:
        print(f"  - {r[0]} ({r[1]}): {r[2]} chars | 'fa-plus' index: {r[3]}")
        if r[3] > 0:
            print("  WARNING: FontAwesome icon 'fa-plus' still exists!")
            
    # Verify menu shortcut keys
    cursor.execute("SELECT MenuID, ClassName, ShortcutKeys FROM MEN_Menu WHERE MenuID = 'MnuAT001'")
    menu_row = cursor.fetchone()
    if menu_row:
        print(f"\nMenu: {menu_row[0]} | Class: {menu_row[1]} | ShortcutKeys: {menu_row[2]}")
        if menu_row[2] == 'CONTROL+B':
            print("  SUCCESS: Shortcut keys updated correctly!")
        else:
            print("  WARNING: Shortcut keys NOT updated!")
            
    conn.close()
    print("\nDeployment and verification finished successfully.")
except Exception as e:
    print("\nExecution Error:", e)
