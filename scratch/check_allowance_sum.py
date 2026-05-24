import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Vietinsoft_ForTest;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    # 1. Check generated AllowanceSum
    cursor.execute("""
        DECLARE @AllowanceSum NVARCHAR(MAX) = N'';
        
        SELECT @AllowanceSum = @AllowanceSum + N' + ISNULL(' + QUOTENAME(c.COLUMN_NAME) + N', 0)'
        FROM tblAllowanceSetting a
        INNER JOIN INFORMATION_SCHEMA.COLUMNS c 
            ON a.AllowanceCode = c.COLUMN_NAME 
            AND c.TABLE_NAME = 'tblSalaryHistory'
        WHERE a.ForSalary = 1 AND (a.IncludedIns IS NULL OR a.IncludedIns = 0);
        
        SELECT @AllowanceSum;
    """)
    allowance_sum = cursor.fetchone()[0]
    print(f"Generated AllowanceSum for Vietinsoft_ForTest: '{allowance_sum}'")
    
    # 2. Check the column list of tblSalaryHistory
    cursor.execute("""
        SELECT COLUMN_NAME, DATA_TYPE 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = 'tblSalaryHistory'
    """)
    cols = cursor.fetchall()
    print("\nColumns in tblSalaryHistory:")
    for col in cols:
        print(f" - {col[0]} ({col[1]})")
        
    conn.close()
except Exception as e:
    print(f"Error: {e}")
