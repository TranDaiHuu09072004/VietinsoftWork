import json
import os
import re
import sys
import pyodbc
from datetime import datetime, timedelta

def log(msg):
    sys.stderr.write(f"[DbDebugger] {msg}\n")
    sys.stderr.flush()

log("Starting Database Debugger MCP Server...")

# Set console output to UTF-8
if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception as e:
        log(f"Failed to set UTF-8 console output: {e}")

# Dynamic connection string loading
def load_conn_str():
    try:
        cur_dir = os.getcwd()
        mcp_path = None
        temp_dir = cur_dir
        for _ in range(3):
            candidate = os.path.join(temp_dir, ".mcp.json")
            if os.path.exists(candidate):
                mcp_path = candidate
                break
            parent = os.path.dirname(temp_dir)
            if parent == temp_dir:
                break
            temp_dir = parent
            
        if mcp_path and os.path.exists(mcp_path):
            with open(mcp_path, 'r', encoding='utf-8') as f:
                config = json.load(f)
            servers = config.get("mcpServers", {})
            for name, s_cfg in servers.items():
                env = s_cfg.get("env", {})
                if "SQLSERVER_HOST" in env:
                    host = env.get("SQLSERVER_HOST")
                    port = env.get("SQLSERVER_PORT", "1433")
                    user = env.get("SQLSERVER_USER")
                    pwd = env.get("SQLSERVER_PASSWORD")
                    db = env.get("SQLSERVER_DATABASE")
                    
                    log(f"Loaded connection settings from {mcp_path} (Server: {name}, DB: {db})")
                    return (
                        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
                        f"SERVER={host},{port};"
                        f"UID={user};"
                        f"PWD={pwd};"
                        f"TrustServerCertificate=yes;"
                        f"DATABASE={db};"
                    )
    except Exception as e:
        log(f"Warning: Failed to dynamically load database configuration: {e}")
        
    return (
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=192.168.11.51,2222;"
        "UID=vts.sa;"
        "PWD=LuaThieng1@3@2020;"
        "TrustServerCertificate=yes;"
        "DATABASE=Paradise_SKN;"
    )

CONN_STR = load_conn_str()

def get_connection(autocommit=True):
    return pyodbc.connect(CONN_STR, autocommit=autocommit)

# --- Tool Implementations ---

def tool_get_sp_metadata(sp_name):
    log(f"Fetching metadata for SP: {sp_name}")
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        # Verify exists
        cursor.execute("SELECT OBJECT_ID(?)", (sp_name,))
        if cursor.fetchone()[0] is None:
            return f"Error: Stored Procedure '{sp_name}' does not exist in database."
            
        query = """
        SELECT 
            p.name AS ParameterName,
            TYPE_NAME(p.user_type_id) AS DataType,
            p.max_length AS MaxLength,
            p.is_output AS IsOutput
        FROM sys.parameters p
        WHERE p.object_id = OBJECT_ID(?)
        ORDER BY p.parameter_id
        """
        cursor.execute(query, (sp_name,))
        rows = cursor.fetchall()
        
        params = []
        for r in rows:
            params.append({
                "Parameter": r[0],
                "Type": r[1],
                "MaxLength": r[2],
                "Direction": "OUTPUT" if r[3] else "INPUT"
            })
            
        return json.dumps(params, indent=2, ensure_ascii=False)
    except Exception as e:
        return f"Error occurred: {e}"
    finally:
        if cursor:
            try:
                cursor.close()
            except Exception:
                pass
        if conn:
            try:
                conn.close()
            except Exception:
                pass

def tool_get_sp_source(sp_name):
    log(f"Fetching definition for SP: {sp_name}")
    conn = None
    cursor = None
    try:
        conn = get_connection()
        cursor = conn.cursor()
        
        # Fetch definition avoiding SQL keyword issues
        query = """
        SELECT definition 
        FROM sys.sql_modules 
        WHERE object_id = OBJECT_ID(?)
        """
        cursor.execute(query, (sp_name,))
        row = cursor.fetchone()
        
        if not row or not row[0]:
            # Try fallback using sys.procedures/sys.comments if sys.sql_modules doesn't return
            cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID(?))", (sp_name,))
            row = cursor.fetchone()
            
        if not row or not row[0]:
            return f"Error: Source code not found for stored procedure '{sp_name}'."
            
        source_code = row[0]
        return source_code
    except Exception as e:
        return f"Error occurred: {e}"
    finally:
        if cursor:
            try:
                cursor.close()
            except Exception:
                pass
        if conn:
            try:
                conn.close()
            except Exception:
                pass

def detect_referenced_tables(cursor, sp_name):
    tables = set()
    # 1. System catalog dependencies
    query_deps = """
    SELECT DISTINCT o.name AS TableName
    FROM sys.sql_expression_dependencies d
    INNER JOIN sys.objects o ON d.referenced_id = o.object_id
    WHERE d.referencing_id = OBJECT_ID(?) AND o.type = 'U'
    """
    try:
        cursor.execute(query_deps, (sp_name,))
        for r in cursor.fetchall():
            tables.add(r[0])
    except Exception as e:
        log(f"Failed to query sys.sql_expression_dependencies: {e}")
        
    # 2. Regex scan of procedure definition
    try:
        cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID(?))", (sp_name,))
        row = cursor.fetchone()
        if row and row[0]:
            sp_text = row[0]
            # Match tbl[Name] or dbo.tbl[Name] or similar user tables
            matches = re.findall(r'\b(?:dbo\.)?(tbl[A-Za-z0-9_]+)\b', sp_text, re.IGNORECASE)
            for m in matches:
                tables.add(m)
    except Exception as e:
        log(f"Failed regex scan of SP definition: {e}")
        
    # Verify tables actually exist in database
    valid_tables = []
    for t in sorted(list(tables)):
        cursor.execute("SELECT OBJECT_ID(?)", (t,))
        if cursor.fetchone()[0] is not None:
            valid_tables.append(t)
            
    return valid_tables

def get_table_schema(cursor, table_name):
    # Query column names and primary keys
    cursor.execute("""
        SELECT COLUMN_NAME, DATA_TYPE 
        FROM INFORMATION_SCHEMA.COLUMNS 
        WHERE TABLE_NAME = ?
    """, (table_name,))
    columns = {r[0]: r[1] for r in cursor.fetchall()}
    
    # Query Primary Keys
    cursor.execute("""
        SELECT col.COLUMN_NAME
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tab
        INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE col 
            ON col.CONSTRAINT_NAME = tab.CONSTRAINT_NAME
            AND col.CONSTRAINT_SCHEMA = tab.CONSTRAINT_SCHEMA
        WHERE tab.CONSTRAINT_TYPE = 'PRIMARY KEY' AND col.TABLE_NAME = ?
    """, (table_name,))
    pkeys = [r[0] for r in cursor.fetchall()]
    
    return columns, pkeys

def build_snapshot_query(table_name, columns, employee_id, date_start, date_end):
    # Find employee column and date column
    emp_col = None
    date_col = None
    
    for col in columns:
        col_lower = col.lower()
        if col_lower in ("employeeid", "userid", "employeeid_pram", "user_id"):
            emp_col = col
        if col_lower in ("attdate", "date", "scheduledate", "replace_date", "atttime"):
            date_col = col
            
    # If table has a photo or binary field, exclude it to keep JSON payload and memory small
    selected_cols = []
    for col, dtype in columns.items():
        if dtype.lower() in ("image", "varbinary", "binary") or "photo" in col.lower():
            continue
        selected_cols.append(f"[{col}]")
        
    select_list = ", ".join(selected_cols)
    if not select_list:
        select_list = "*"
        
    base_query = f"SELECT {select_list} FROM [{table_name}] WHERE 1=1"
    params = []
    
    if emp_col:
        # Check if column is int (sometimes USERID is int)
        if columns[emp_col].lower() in ("int", "bigint"):
            try:
                params.append(int(employee_id))
                base_query += f" AND [{emp_col}] = ?"
            except ValueError:
                # If can't cast, skip employee filter
                pass
        else:
            params.append(employee_id)
            base_query += f" AND [{emp_col}] = ?"
            
    if date_col:
        # Check if type is date or datetime
        dtype = columns[date_col].lower()
        if dtype in ("datetime", "smalldatetime", "atttime") or "time" in date_col.lower():
            # Range check with timestamps
            t_start = f"{date_start} 00:00:00"
            t_end = f"{date_end} 23:59:59"
            params.append(t_start)
            params.append(t_end)
            base_query += f" AND [{date_col}] BETWEEN ? AND ?"
        else:
            # Simple date match
            params.append(date_start)
            params.append(date_end)
            base_query += f" AND [{date_col}] BETWEEN ? AND ?"
            
    return base_query, params

def take_snapshot(cursor, table_name, employee_id, date_start, date_end):
    columns, pkeys = get_table_schema(cursor, table_name)
    if not columns:
        return None, [], []
        
    query, params = build_snapshot_query(table_name, columns, employee_id, date_start, date_end)
    try:
        cursor.execute(query, params)
        desc = [col[0] for col in cursor.description]
        rows = cursor.fetchall()
        
        snapshot = []
        for r in rows:
            snapshot.append(dict(zip(desc, r)))
        return snapshot, pkeys, list(columns.keys())
    except Exception as e:
        log(f"Error taking snapshot for {table_name}: {e}")
        return None, [], []

def format_value(val):
    if val is None:
        return "NULL"
    if isinstance(val, datetime):
        return val.strftime("%Y-%m-%d %H:%M:%S")
    return str(val)

def generate_diff_markdown(table_name, before, after, pkeys, columns):
    if before is None or after is None:
        return f"### Bảng: `{table_name}`\n*Không thể đọc dữ liệu hoặc bảng không khớp cấu trúc lọc.*\n"
        
    # Index both snapshots
    def get_row_key(row):
        if pkeys:
            return tuple(format_value(row.get(pk)) for pk in pkeys)
        # If no primary keys, use combination of employee and date fields or whole row
        id_cols = [c for c in ["EmployeeID", "UserID", "AttDate", "Date", "ScheduleDate", "AttTime"] if c in row]
        if id_cols:
            return tuple(format_value(row.get(c)) for c in id_cols)
        return tuple(format_value(row.get(col)) for col in sorted(row.keys()))

    before_map = {get_row_key(r): r for r in before}
    after_map = {get_row_key(r): r for r in after}
    
    inserts = []
    deletes = []
    updates = []
    
    # Process deletes and updates
    for key, b_row in before_map.items():
        if key not in after_map:
            deletes.append(b_row)
        else:
            a_row = after_map[key]
            changed_cols = {}
            for col in columns:
                if col in b_row and col in a_row:
                    b_val = b_row[col]
                    a_val = a_row[col]
                    # Handle datetime comparison precisely
                    if isinstance(b_val, datetime) and isinstance(a_val, datetime):
                        if b_val != a_val:
                            changed_cols[col] = (b_val, a_val)
                    elif str(b_val) != str(a_val):
                        changed_cols[col] = (b_val, a_val)
            if changed_cols:
                updates.append((b_row, changed_cols))
                
    # Process inserts
    for key, a_row in after_map.items():
        if key not in before_map:
            inserts.append(a_row)
            
    if not inserts and not deletes and not updates:
        return f"### Bảng: `{table_name}`\n*Không có thay đổi dữ liệu.*\n"
        
    md = [f"### Bảng: `{table_name}`\n"]
    md.append("| Hành động | Khóa/Định danh | Cột thay đổi | Giá trị Trước | Giá trị Sau |")
    md.append("| :--- | :--- | :--- | :--- | :--- |")
    
    def get_row_identity_string(row):
        if pkeys:
            return ", ".join(f"{pk}={format_value(row.get(pk))}" for pk in pkeys)
        id_cols = [c for c in ["EmployeeID", "UserID", "AttDate", "Date", "ScheduleDate"] if c in row]
        if id_cols:
            return ", ".join(f"{c}={format_value(row.get(c))}" for c in id_cols)
        return "Row"

    # Format deletes
    for row in deletes:
        ident = get_row_identity_string(row)
        md.append(f"| `Xóa` | {ident} | *Tất cả các cột* | *Dòng bị xóa* | - |")
        
    # Format inserts
    for row in inserts:
        ident = get_row_identity_string(row)
        # Show key columns values in before/after
        info = []
        for col in sorted(row.keys()):
            if col not in pkeys and row.get(col) is not None:
                info.append(f"{col}:{format_value(row.get(col))}")
        info_str = "; ".join(info[:4]) + ("..." if len(info) > 4 else "")
        md.append(f"| `Thêm mới` | {ident} | *Tất cả các cột* | - | {info_str} |")
        
    # Format updates
    for row, changes in updates:
        ident = get_row_identity_string(row)
        first = True
        for col, (b_val, a_val) in changes.items():
            act = "`Cập nhật`" if first else ""
            id_str = ident if first else ""
            md.append(f"| {act} | {id_str} | {col} | {format_value(b_val)} | {format_value(a_val)} |")
            first = False
            
    md.append("")
    return "\n".join(md)

def tool_trace_sp_execution(sp_name, parameters, employee_id, date_start, date_end, commit=False, no_transaction=False):
    log(f"Tracing SP: {sp_name} for Employee: {employee_id} ({date_start} -> {date_end}), commit={commit}, no_trans={no_transaction}")
    
    use_transaction = not no_transaction
    conn = get_connection(autocommit=not use_transaction)
    cursor = conn.cursor()
    
    try:
        # 1. Identify tables referenced
        referenced_tables = detect_referenced_tables(cursor, sp_name)
        log(f"Detected referenced tables: {referenced_tables}")
        
        if not referenced_tables:
            cursor.close()
            conn.close()
            return f"Không phát hiện bảng nghiệp vụ nào liên quan đến stored procedure '{sp_name}'."
            
        # 2. Take before snapshots
        snapshots_before = {}
        table_pkeys = {}
        table_columns = {}
        
        for t in referenced_tables:
            snap, pkeys, cols = take_snapshot(cursor, t, employee_id, date_start, date_end)
            if snap is not None:
                snapshots_before[t] = snap
                table_pkeys[t] = pkeys
                table_columns[t] = cols
                
        # 3. Discover parameters and execute SP
        cursor.execute("SELECT OBJECT_ID(?)", (sp_name,))
        if cursor.fetchone()[0] is None:
            cursor.close()
            conn.close()
            return f"Error: Stored procedure '{sp_name}' không tồn tại."
            
        sp_params = []
        query_params = """
        SELECT p.name, TYPE_NAME(p.user_type_id), p.is_output
        FROM sys.parameters p
        WHERE p.object_id = OBJECT_ID(?)
        """
        cursor.execute(query_params, (sp_name,))
        for r in cursor.fetchall():
            sp_params.append({"name": r[0], "type": r[1], "is_out": bool(r[2])})
            
        # Build SQL arguments
        args_dict = {}
        for param in sp_params:
            p_name = param["name"]
            p_type = param["type"]
            is_out = param["is_out"]
            
            if is_out:
                continue
                
            p_key = p_name.lstrip('@')
            val = None
            if p_key in parameters:
                val = parameters[p_key]
            elif p_name in parameters:
                val = parameters[p_name]
                
            # Cast type with string type checks for empty string preserving
            if val is not None:
                if val == "":
                    if p_type in ("varchar", "nvarchar", "char", "nchar", "text", "ntext"):
                        args_dict[p_name] = ""
                    else:
                        args_dict[p_name] = None
                else:
                    if p_type in ("int", "bigint", "smallint", "tinyint"):
                        args_dict[p_name] = int(val)
                    elif p_type in ("decimal", "numeric", "float", "real", "money"):
                        args_dict[p_name] = float(val)
                    elif p_type == "bit":
                        args_dict[p_name] = True if str(val).lower() in ("true", "1", "yes") else False
                    else:
                        args_dict[p_name] = str(val)
            else:
                args_dict[p_name] = None
                
        param_placeholders = []
        param_values = []
        for p_name, val in args_dict.items():
            param_placeholders.append(f"{p_name} = ?")
            param_values.append(val)
            
        exec_sql = f"EXEC {sp_name} {', '.join(param_placeholders)}"
        log(f"Executing: {exec_sql} with values {param_values}")
        
        # Run SP
        cursor.execute(exec_sql, param_values)
        
        # Consume any active resultsets to ensure execution finishes completely
        while cursor.nextset():
            pass
            
        # 4. Take after snapshots
        snapshots_after = {}
        for t in referenced_tables:
            if t in snapshots_before:
                snap, _, _ = take_snapshot(cursor, t, employee_id, date_start, date_end)
                snapshots_after[t] = snap
                
        # 5. Rollback or commit
        if not use_transaction:
            status_line = "⚠️ **Trạng thái thực thi:** KHÔNG TRANSACTION (Dữ liệu đã được cập nhật trực tiếp vào DB)."
        elif commit:
            conn.commit()
            log("Transaction COMMITTED.")
            status_line = "✅ **Trạng thái thực thi:** THÀNH CÔNG (Dữ liệu đã được COMMIT vào database)."
        else:
            conn.rollback()
            log("Transaction ROLLED BACK.")
            status_line = "🛡️ **Trạng thái thực thi:** THỬ NGHIỆM AN TOÀN (Dữ liệu tự động ROLLBACK, không thay đổi DB thực tế)."
            
        cursor.close()
        conn.close()
        
        # 6. Generate comparative report
        report = [
            f"## BÁO CÁO TRUY VẾT TÁC ĐỘNG (TRACE REPORT) - THỦ TỤC: `{sp_name}`",
            f"**Nhân viên:** {employee_id} | **Khoảng ngày:** {date_start} -> {date_end}",
            status_line,
            "-" * 80,
            ""
        ]
        
        changes_found = False
        for t in referenced_tables:
            if t in snapshots_before and t in snapshots_after:
                diff_md = generate_diff_markdown(t, snapshots_before[t], snapshots_after[t], table_pkeys[t], table_columns[t])
                if "Không có thay đổi dữ liệu" not in diff_md:
                    changes_found = True
                report.append(diff_md)
                
        if not changes_found:
            report.append("### Kết quả:\n*Không phát hiện thay đổi dữ liệu nào trên các bảng nghiệp vụ liên quan.*")
            
        return "\n".join(report)
        
    except Exception as e:
        # Safety rollback if transaction was used
        if use_transaction:
            try:
                conn.rollback()
            except Exception:
                pass
        try:
            cursor.close()
            conn.close()
        except Exception:
            pass
            
        err_msg = str(e)
        log(f"Trace failed: {err_msg}")
        
        if "574" in err_msg or "CONFIG statement" in err_msg:
            return (
                f"### [THÔNG BÁO HỆ THỐNG] Lỗi Giao dịch (Error 574)\n"
                f"Stored Procedure `{sp_name}` chứa lệnh thay đổi cấu hình máy chủ (`RECONFIGURE` / `sp_configure`) "
                f"không cho phép thực thi bên trong một User Transaction.\n\n"
                f"**Giải pháp:** Hãy chạy lại cuộc gọi với tham số `no_transaction=True` để thực hiện chạy trực tiếp ngoài Transaction.\n"
                f"*(Lưu ý: Chế độ này sẽ thực sự cập nhật dữ liệu vào database)*"
            )
            
        return f"Error running trace: {e}"

def tool_execute_sp_safe(sp_name, parameters, commit=False, no_transaction=False):
    log(f"Executing SP safely: {sp_name} (commit={commit}, no_trans={no_transaction})")
    use_transaction = not no_transaction
    conn = get_connection(autocommit=not use_transaction)
    cursor = conn.cursor()
    
    try:
        sp_params = []
        query_params = """
        SELECT p.name, TYPE_NAME(p.user_type_id), p.is_output
        FROM sys.parameters p
        WHERE p.object_id = OBJECT_ID(?)
        """
        cursor.execute(query_params, (sp_name,))
        for r in cursor.fetchall():
            sp_params.append({"name": r[0], "type": r[1], "is_out": bool(r[2])})
            
        # Build SQL arguments
        args_dict = {}
        for param in sp_params:
            p_name = param["name"]
            p_type = param["type"]
            is_out = param["is_out"]
            
            if is_out:
                continue
                
            p_key = p_name.lstrip('@')
            val = None
            if p_key in parameters:
                val = parameters[p_key]
            elif p_name in parameters:
                val = parameters[p_name]
                
            # Cast type with string type checks for empty string preserving
            if val is not None:
                if val == "":
                    if p_type in ("varchar", "nvarchar", "char", "nchar", "text", "ntext"):
                        args_dict[p_name] = ""
                    else:
                        args_dict[p_name] = None
                else:
                    if p_type in ("int", "bigint", "smallint", "tinyint"):
                        args_dict[p_name] = int(val)
                    elif p_type in ("decimal", "numeric", "float", "real", "money"):
                        args_dict[p_name] = float(val)
                    elif p_type == "bit":
                        args_dict[p_name] = True if str(val).lower() in ("true", "1", "yes") else False
                    else:
                        args_dict[p_name] = str(val)
            else:
                args_dict[p_name] = None
                
        param_placeholders = []
        param_values = []
        for p_name, val in args_dict.items():
            param_placeholders.append(f"{p_name} = ?")
            param_values.append(val)
            
        exec_sql = f"EXEC {sp_name} {', '.join(param_placeholders)}"
        cursor.execute(exec_sql, param_values)
        
        result_sets = []
        set_idx = 1
        
        while True:
            if cursor.description:
                columns = [col[0] for col in cursor.description]
                rows = cursor.fetchall()
                
                rows_list = []
                for row in rows:
                    rows_list.append(dict(zip(columns, row)))
                    
                result_sets.append({
                    "resultSet": set_idx,
                    "rowCount": len(rows_list),
                    "columns": columns,
                    "rows": rows_list
                })
                set_idx += 1
            else:
                if cursor.rowcount != -1:
                    result_sets.append({
                        "message": f"Affected {cursor.rowcount} rows"
                    })
            if not cursor.nextset():
                break
                
        if not use_transaction:
            status = "NoTransaction (AutoCommitted)"
        elif commit:
            conn.commit()
            status = "Committed"
        else:
            conn.rollback()
            status = "RolledBack (Safe Test Mode)"
            
        cursor.close()
        conn.close()
        
        output = {
            "status": "Success",
            "transaction": status,
            "resultSets": result_sets
        }
        return json.dumps(output, indent=2, ensure_ascii=False, default=str)
        
    except Exception as e:
        if use_transaction:
            try:
                conn.rollback()
            except Exception:
                pass
        try:
            cursor.close()
            conn.close()
        except Exception:
            pass
            
        err_msg = str(e)
        if "574" in err_msg or "CONFIG statement" in err_msg:
            return json.dumps({
                "status": "Error",
                "code": 574,
                "message": f"Stored Procedure `{sp_name}` chứa lệnh CONFIG/RECONFIGURE không thể chạy trong Transaction. Hãy gọi lại với tham số no_transaction=True."
            }, indent=2, ensure_ascii=False)
            
        return json.dumps({"status": "Error", "message": err_msg}, indent=2)

# --- Standard JSON-RPC stdio Loop ---

def respond(response_id, result=None, error=None):
    resp = {"jsonrpc": "2.0", "id": response_id}
    if error:
        resp["error"] = error
    else:
        resp["result"] = result
    
    sys.stdout.write(json.dumps(resp, ensure_ascii=False) + "\n")
    sys.stdout.flush()

def main():
    while True:
        try:
            line = sys.stdin.readline()
            if not line:
                break
                
            req = json.loads(line.strip())
            method = req.get("method")
            req_id = req.get("id")
            
            if method == "initialize":
                respond(req_id, {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {
                        "tools": {}
                    },
                    "serverInfo": {
                        "name": "paradisehr-local-debugger",
                        "version": "1.0.0"
                    }
                })
                
            elif method == "tools/list":
                respond(req_id, {
                    "tools": [
                        {
                            "name": "get_sp_metadata",
                            "description": "Lấy thông tin danh sách tham số (tên, kiểu dữ liệu, chiều IN/OUT) của một stored procedure từ hệ thống.",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "sp_name": {"type": "string", "description": "Tên stored procedure (ví dụ: sp_ShiftDetector)"}
                                },
                                "required": ["sp_name"]
                            }
                        },
                        {
                            "name": "get_sp_source",
                            "description": "Lấy định nghĩa (mã nguồn T-SQL) của stored procedure an toàn.",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "sp_name": {"type": "string", "description": "Tên stored procedure (ví dụ: sp_ShiftDetector)"}
                                },
                                "required": ["sp_name"]
                            }
                        },
                        {
                            "name": "execute_sp_safe",
                            "description": "Chạy thử stored procedure và tự động Rollback (hoặc Commit nếu chọn) để xem kết quả trả về.",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "sp_name": {"type": "string", "description": "Tên stored procedure"},
                                    "parameters": {"type": "object", "description": "Đối tượng key-value chứa các tham số đầu vào"},
                                    "commit": {"type": "boolean", "description": "Chọn True nếu thực sự muốn lưu thay đổi vào DB (Mặc định: False)"},
                                    "no_transaction": {"type": "boolean", "description": "Chọn True để chạy ngoài Transaction nếu thủ tục chứa lệnh CONFIG/RECONFIGURE (Mặc định: False)"}
                                },
                                "required": ["sp_name", "parameters"]
                            }
                        },
                        {
                            "name": "trace_sp_execution",
                            "description": "Chụp ảnh trạng thái các bảng nghiệp vụ liên quan trước và sau khi chạy SP, so sánh sai lệch và xuất báo cáo Markdown dạng bảng (mặc định tự động Rollback).",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "sp_name": {"type": "string", "description": "Tên stored procedure cần trace"},
                                    "parameters": {"type": "object", "description": "Đối tượng chứa các tham số chạy thủ tục"},
                                    "employee_id": {"type": "string", "description": "Mã nhân viên cần theo dõi thay đổi"},
                                    "date_start": {"type": "string", "description": "Ngày bắt đầu theo dõi dạng YYYY-MM-DD"},
                                    "date_end": {"type": "string", "description": "Ngày kết thúc theo dõi dạng YYYY-MM-DD"},
                                    "commit": {"type": "boolean", "description": "Chọn True nếu muốn lưu kết quả chạy thật vào DB (Mặc định: False)"},
                                    "no_transaction": {"type": "boolean", "description": "Chọn True để chạy ngoài Transaction nếu thủ tục chứa lệnh CONFIG/RECONFIGURE (Mặc định: False)"}
                                },
                                "required": ["sp_name", "parameters", "employee_id", "date_start", "date_end"]
                            }
                        }
                    ]
                })
                
            elif method == "tools/call":
                params = req.get("params", {})
                tool_name = params.get("name")
                args = params.get("arguments", {})
                
                log(f"Calling tool: {tool_name} with args {args}")
                
                result_text = ""
                if tool_name == "get_sp_metadata":
                    result_text = tool_get_sp_metadata(args.get("sp_name", ""))
                elif tool_name == "get_sp_source":
                    result_text = tool_get_sp_source(args.get("sp_name", ""))
                elif tool_name == "execute_sp_safe":
                    result_text = tool_execute_sp_safe(
                        args.get("sp_name", ""),
                        args.get("parameters", {}),
                        args.get("commit", args.get("commit", False)),
                        args.get("no_transaction", False)
                    )
                elif tool_name == "trace_sp_execution":
                    result_text = tool_trace_sp_execution(
                        args.get("sp_name", ""),
                        args.get("parameters", {}),
                        args.get("employee_id", ""),
                        args.get("date_start", ""),
                        args.get("date_end", ""),
                        args.get("commit", args.get("commit", False)),
                        args.get("no_transaction", False)
                    )
                else:
                    respond(req_id, error={"code": -32601, "message": f"Method not found: {tool_name}"})
                    continue
                    
                respond(req_id, {
                    "content": [
                        {
                            "type": "text",
                            "text": result_text
                        }
                    ]
                })
                
            elif method == "notifications/initialized":
                pass
                
            else:
                if req_id is not None:
                    respond(req_id, error={"code": -32601, "message": f"Method not found: {method}"})
                    
        except Exception as e:
            log(f"Error in main loop: {e}")
            break

if __name__ == "__main__":
    main()
