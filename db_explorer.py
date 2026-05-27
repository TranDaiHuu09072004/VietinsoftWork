import argparse
import json
import os
import re
import sys
import pyodbc

# Ensure console supports UTF-8 output
sys.stdout.reconfigure(encoding='utf-8')

def get_odbc_driver():
    """Detects installed SQL Server ODBC drivers on the system."""
    drivers = pyodbc.drivers()
    preferred = [
        'ODBC Driver 17 for SQL Server',
        'ODBC Driver 18 for SQL Server',
        'ODBC Driver 13 for SQL Server',
        'SQL Server'
    ]
    for d in preferred:
        if d in drivers:
            return f"{{{d}}}"
    # Try any driver containing "SQL Server"
    for d in drivers:
        if "SQL Server" in d:
            return f"{{{d}}}"
    return "{SQL Server}"  # Default fallback

def resolve_value(val):
    """Resolves environment variables like ${VAR_NAME} to actual values."""
    if not isinstance(val, str):
        return val
    match = re.match(r'^\$\{(.+)\}$', val)
    if match:
        var_name = match.group(1)
        return os.environ.get(var_name, '')
    return val

def load_mcp_config():
    """Loads and parses .mcp.json from the current or parent directory."""
    config_path = '.mcp.json'
    # Check parent directory if not found in current directory
    if not os.path.exists(config_path):
        config_path = os.path.join('..', '.mcp.json')
        
    if not os.path.exists(config_path):
        return {}
        
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"Warning: Failed to parse {config_path}: {e}")
        return {}

def select_server_interactively(servers):
    """Prompts the user to select an MCP server from the list."""
    server_list = list(servers.keys())
    print("\nAvailable database servers in MCP session:")
    for idx, sname in enumerate(server_list, 1):
        env = servers[sname].get('env', {})
        host = resolve_value(env.get('SQLSERVER_HOST', ''))
        db = resolve_value(env.get('SQLSERVER_DATABASE', ''))
        print(f"  {idx}. {sname} (Host: {host or 'EnvVar'}, DB: {db or 'EnvVar'})")
        
    while True:
        try:
            choice = input(f"\nSelect server (1-{len(server_list)}, default 2): ").strip()
            if not choice:
                return server_list[1] if len(server_list) > 1 else server_list[0]
            choice_idx = int(choice) - 1
            if 0 <= choice_idx < len(server_list):
                return server_list[choice_idx]
            else:
                print("Invalid choice, please select within range.")
        except ValueError:
            print("Please enter a valid number.")

def main():
    parser = argparse.ArgumentParser(description="ParadiseHR Schema and Object Explorer")
    parser.add_argument('server', nargs='?', help='Name of the MCP server configured in .mcp.json (e.g. Paradise_Dev)')
    parser.add_argument('--host', help='Override host')
    parser.add_argument('--port', help='Override port')
    parser.add_argument('--db', help='Override database name')
    parser.add_argument('--user', help='Override username')
    parser.add_argument('--password', help='Override password')
    args = parser.parse_args()

    mcp_config = load_mcp_config()
    servers = mcp_config.get('mcpServers', {})

    selected_server = args.server
    
    # If no server argument is provided and we have configured servers, select one
    if not selected_server and servers:
        if len(servers) == 1:
            selected_server = list(servers.keys())[0]
        else:
            selected_server = select_server_interactively(servers)

    # Initialize connection parameter variables
    host, port, db, user, password = '', '', '', '', ''

    if selected_server and selected_server in servers:
        print(f"\nLoading configuration for server: {selected_server}")
        env = servers[selected_server].get('env', {})
        host = resolve_value(env.get('SQLSERVER_HOST', ''))
        port = resolve_value(env.get('SQLSERVER_PORT', ''))
        db = resolve_value(env.get('SQLSERVER_DATABASE', ''))
        user = resolve_value(env.get('SQLSERVER_USER', ''))
        password = resolve_value(env.get('SQLSERVER_PASSWORD', ''))
    else:
        if selected_server:
            print(f"Warning: Server '{selected_server}' not found in .mcp.json. Using overrides/defaults.")

    # Apply command-line overrides
    if args.host: host = args.host
    if args.port: port = args.port
    if args.db: db = args.db
    if args.user: user = args.user
    if args.password: password = args.password

    # Validate parameters
    if not host or not db or not user or not password:
        print("\nError: Missing database connection details.")
        print("Please check that your environmental variables are set or provide overrides.")
        print("Required: Host, Database, User, Password.")
        sys.exit(1)

    driver = get_odbc_driver()
    server_address = f"{host},{port}" if port else host

    # Build connection string
    connection_string = (
        f"DRIVER={driver};"
        f"SERVER={server_address};"
        f"DATABASE={db};"
        f"UID={user};"
        f"PWD={password};"
        f"TrustServerCertificate=yes;"
    )

    try:
        print(f"\nConnecting using driver: {driver}")
        print(f"Server: {server_address} | Database: {db} | User: {user}")
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
            f.write(f"DATABASE TABLE SCHEMA (DB: {db})\n")
            f.write("="*50 + "\n")
            current_table = ""
            for row in cursor.fetchall():
                if row.TABLE_NAME != current_table:
                    current_table = row.TABLE_NAME
                    f.write(f"\nTABLE: {current_table}\n")
                    f.write("-" * 30 + "\n")
                
                len_suffix = f"[{row.CHARACTER_MAXIMUM_LENGTH}]" if row.CHARACTER_MAXIMUM_LENGTH and row.CHARACTER_MAXIMUM_LENGTH != -1 else ""
                null_suffix = "NULL" if row.IS_NULLABLE == "YES" else "NOT NULL"
                f.write(f"  - {row.COLUMN_NAME} ({row.DATA_TYPE}{len_suffix}, {null_suffix})\n")
        
        print(f"Schema successfully exported to {tables_file}")

        # 2. Export Procedures
        print("Fetching procedure list...")
        cursor.execute("SELECT name FROM sys.procedures ORDER BY name")
        
        proc_file = 'Database_Procedures_List.txt'
        with open(proc_file, 'w', encoding='utf-8') as f:
            f.write(f"DATABASE STORED PROCEDURES (DB: {db})\n")
            f.write("="*50 + "\n")
            for row in cursor.fetchall():
                f.write(f"{row.name}\n")
        
        print(f"Procedures successfully exported to {proc_file}")
        
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
            f.write(f"DATABASE FUNCTIONS (DB: {db})\n")
            f.write("="*50 + "\n")
            for row in cursor.fetchall():
                f.write(f"{row.name} ({row.type_desc})\n")
        
        print(f"Functions successfully exported to {func_file}")

        conn.close()
        print("\nSuccess! Connection verified and metadata files updated.")

    except Exception as e:
        print(f"\nConnection Error: {e}")
        print("Hint: Check server host/port availability, firewall rules, and credentials.")

if __name__ == "__main__":
    main()
