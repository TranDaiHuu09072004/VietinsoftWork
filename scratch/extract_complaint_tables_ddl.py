import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

def get_table_ddl(cursor, table_name):
    # Retrieve columns
    cursor.execute("""
        SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, 
               NUMERIC_PRECISION, NUMERIC_SCALE, IS_NULLABLE, COLUMN_DEFAULT
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = ?
        ORDER BY ORDINAL_POSITION
    """, table_name)
    columns = cursor.fetchall()
    
    # Retrieve primary keys
    cursor.execute("""
        SELECT k.COLUMN_NAME
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE k
        JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS c ON k.CONSTRAINT_NAME = c.CONSTRAINT_NAME
        WHERE c.CONSTRAINT_TYPE = 'PRIMARY KEY' AND c.TABLE_NAME = ?
    """, table_name)
    pks = [r[0] for r in cursor.fetchall()]
    
    # Retrieve identity column
    cursor.execute("""
        SELECT name 
        FROM sys.identity_columns 
        WHERE object_id = OBJECT_ID(?)
    """, table_name)
    ident_row = cursor.fetchone()
    identity_col = ident_row[0] if ident_row else None

    ddl_parts = []
    for col in columns:
        col_name, data_type, max_len, num_prec, num_scale, is_nullable, col_default = col
        col_def = f"    [{col_name}] {data_type.upper()}"
        
        if data_type.upper() in ('VARCHAR', 'NVARCHAR', 'CHAR', 'NCHAR'):
            if max_len == -1:
                col_def += "(MAX)"
            else:
                col_def += f"({max_len})"
        elif data_type.upper() in ('DECIMAL', 'NUMERIC'):
            col_def += f"({num_prec},{num_scale})"
            
        if col_name == identity_col:
            col_def += " IDENTITY(1,1)"
            
        if is_nullable == 'NO':
            col_def += " NOT NULL"
        else:
            col_def += " NULL"
            
        if col_default:
            col_def += f" DEFAULT {col_default}"
            
        ddl_parts.append(col_def)
        
    if pks:
        pk_cols = ", ".join([f"[{pk}]" for pk in pks])
        ddl_parts.append(f"    CONSTRAINT [PK_{table_name}] PRIMARY KEY CLUSTERED ({pk_cols})")
        
    ddl = f"IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = '{table_name}')\nBEGIN\n"
    ddl += f"    CREATE TABLE [dbo].[{table_name}] (\n"
    ddl += ",\n".join(ddl_parts)
    ddl += "\n    );\n"
    ddl += f"    PRINT 'Created table {table_name}.';\n"
    ddl += "END\nGO\n"
    return ddl

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    for tbl in ['tblTask_ComplaintTypes', 'tblTask_Complaints']:
        print(f"--- DDL for {tbl} ---")
        print(get_table_ddl(cursor, tbl))
        
    conn.close()
except Exception as e:
    print("Error:", e)
