import pyodbc
import os


server = '192.168.11.51,6688'
database = 'Vietinsoft_Pay'
username = 'ai.sa'
password = 'ThoiDaiVibeCodeIA@2026'
driver = '{SQL Server}' # Adjust if using a different driver like {ODBC Driver 17 for SQL Server}

connection_string = f'DRIVER={driver};SERVER={server};DATABASE={database};UID={username};PWD={password}'

def export_schema():
    try:
        print(f"Connecting to {server}...")
        conn = pyodbc.connect(connection_string)
        cursor = conn.cursor()

        # 1. Export Tables and Columns
        print("Fetching table structures...")
        cursor.execute("""
            SELECT 
                TABLE_NAME, 
                COLUMN_NAME, 
                DATA_TYPE, 
                IS_NULLABLE,
                CHARACTER_MAXIMUM_LENGTH
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = 'dbo'
            ORDER BY TABLE_NAME, ORDINAL_POSITION
        """)
        
        tables_file = 'Database_Tables_Schema.txt'
        with open(tables_file, 'w', encoding='utf-8') as f:
            f.write("DATABASE TABLE SCHEMA\n")
            f.write("="*50 + "\n")
            current_table = ""
            for row in cursor.fetchall():
                if row.TABLE_NAME != current_table:
                    current_table = row.TABLE_NAME
                    f.write(f"\nTABLE: {current_table}\n")
                    f.write("-" * 30 + "\n")
                
                f.write(f"  - {row.COLUMN_NAME} ({row.DATA_TYPE}{f'[{row.CHARACTER_MAXIMUM_LENGTH}]' if row.CHARACTER_MAXIMUM_LENGTH else ''}, {'NULL' if row.IS_NULLABLE == 'YES' else 'NOT NULL'})\n")
        
        print(f"Schema exported to {tables_file}")

        # 2. Export Procedures
        print("Fetching procedure list...")
        cursor.execute("SELECT name FROM sys.procedures ORDER BY name")
        
        proc_file = 'Database_Procedures_List.txt'
        with open(proc_file, 'w', encoding='utf-8') as f:
            f.write("DATABASE STORED PROCEDURES\n")
            f.write("="*50 + "\n")
            for row in cursor.fetchall():
                f.write(f"{row.name}\n")
        
        print(f"Procedures exported to {proc_file}")
        
        # 3. Export Functions
        print("Fetching function list...")
        cursor.execute("""
            SELECT name, type_desc 
            FROM sys.objects 
            WHERE type IN ('FN', 'IF', 'TF') 
            ORDER BY name
        """)
        
        func_file = 'Database_Functions_List.txt'
        with open(func_file, 'w', encoding='utf-8') as f:
            f.write("DATABASE FUNCTIONS\n")
            f.write("="*50 + "\n")
            for row in cursor.fetchall():
                f.write(f"{row.name} ({row.type_desc})\n")
        
        print(f"Functions exported to {func_file}")

        conn.close()
        print("\nSuccess! You can now let the AI read these files.")

    except Exception as e:
        print(f"Error: {e}")
        print("\nIf 'Driver not found', try changing the 'driver' variable in the script to:")
        print("'{ODBC Driver 17 for SQL Server}' or '{ODBC Driver 13 for SQL Server}'")

if __name__ == "__main__":
    export_schema()
