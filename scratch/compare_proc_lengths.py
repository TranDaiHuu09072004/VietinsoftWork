import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_base = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

# Connect to Vietinsoft_Pay
conn_pay_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=SVRVTS01\\SQL6688;"
    "DATABASE=Vietinsoft_Pay;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

try:
    # Get procedures in Vietinsoft_Pay
    conn_pay = pyodbc.connect(conn_pay_str)
    cursor_pay = conn_pay.cursor()
    cursor_pay.execute("SELECT name, LEN(definition) FROM sys.procedures p JOIN sys.sql_modules m ON p.object_id = m.object_id WHERE p.name LIKE '%sp_Task_%' ORDER BY p.name")
    pay_procs = {r[0]: r[1] for r in cursor_pay.fetchall()}
    conn_pay.close()
    
    # Get procedures in Paradise_Dev
    conn_dev_str = f"{conn_base}DATABASE=Paradise_Dev;"
    conn_dev = pyodbc.connect(conn_dev_str)
    cursor_dev = conn_dev.cursor()
    cursor_dev.execute("SELECT name, LEN(definition) FROM sys.procedures p JOIN sys.sql_modules m ON p.object_id = m.object_id WHERE p.name LIKE '%sp_Task_%' ORDER BY p.name")
    dev_procs = {r[0]: r[1] for r in cursor_dev.fetchall()}
    conn_dev.close()
    
    # Compare
    all_names = sorted(list(set(pay_procs.keys()) | set(dev_procs.keys())))
    
    print(f"{'Procedure Name':<45} | {'Vietinsoft_Pay':<15} | {'Paradise_Dev':<15} | {'Status':<15}")
    print("-" * 96)
    
    diff_count = 0
    for name in all_names:
        len_pay = pay_procs.get(name, -1)
        len_dev = dev_procs.get(name, -1)
        
        status = "Identical"
        if len_pay == -1:
            status = "Only in Dev"
        elif len_dev == -1:
            status = "Only in Pay"
            diff_count += 1
        elif len_pay != len_dev:
            status = f"Diff ({len_pay} vs {len_dev})"
            diff_count += 1
            
        print(f"{name:<45} | {str(len_pay) if len_pay != -1 else 'N/A':<15} | {str(len_dev) if len_dev != -1 else 'N/A':<15} | {status:<15}")
        
    print(f"\nTotal different/missing procedures: {diff_count}")
except Exception as e:
    print("Error:", e)
