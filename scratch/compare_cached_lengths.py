import json
import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

pay_output_path = r"C:\Users\cuong.vu\.gemini\antigravity\brain\ec0fdd6c-0e84-4b9d-a831-c465ded71ed3\.system_generated\steps\1394\output.txt"

# Connection to Paradise_Dev
conn_dev_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

try:
    # 1. Load Pay lengths
    with open(pay_output_path, "r", encoding="utf-8") as f:
        pay_data = json.load(f)
        
    pay_procs = {}
    for row in pay_data["rows"]:
        name = row[0]
        length = int(row[1]) if row[1] is not None else 0
        pay_procs[name] = length
        
    # 2. Get Dev lengths
    conn = pyodbc.connect(conn_dev_str)
    cursor = conn.cursor()
    cursor.execute("""
        SELECT p.name, LEN(m.definition)
        FROM sys.procedures p
        JOIN sys.sql_modules m ON p.object_id = m.object_id
        WHERE p.name LIKE 'sp_Task_%'
    """)
    dev_procs = {r[0]: r[1] for r in cursor.fetchall()}
    conn.close()
    
    # 3. Compare
    all_names = sorted(list(set(pay_procs.keys()) | set(dev_procs.keys())))
    
    print(f"{'Procedure Name':<45} | {'Vietinsoft_Pay':<15} | {'Paradise_Dev':<15} | {'Status':<15}")
    print("-" * 96)
    
    diff_count = 0
    diff_list = []
    for name in all_names:
        len_pay = pay_procs.get(name, -1)
        len_dev = dev_procs.get(name, -1)
        
        status = "Identical"
        if len_pay == -1:
            status = "Only in Dev"
        elif len_dev == -1:
            status = "Only in Pay"
            diff_count += 1
            diff_list.append(name)
        elif len_pay != len_dev:
            status = f"Diff ({len_pay} vs {len_dev})"
            diff_count += 1
            diff_list.append(name)
            
        print(f"{name:<45} | {str(len_pay) if len_pay != -1 else 'N/A':<15} | {str(len_dev) if len_dev != -1 else 'N/A':<15} | {status:<15}")
        
    print(f"\nTotal different/missing procedures: {diff_count}")
    print("List of procedures to migrate:")
    for name in diff_list:
        print(f"  - {name}")
except Exception as e:
    print("Error:", e)
