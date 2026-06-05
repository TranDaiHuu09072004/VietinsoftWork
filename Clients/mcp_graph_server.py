import json
import os
import re
import sys

# Ensure stdout/stderr use UTF-8. MCP uses stdout for JSON-RPC, so logs must stay on stderr.
try:
    if sys.stdout.encoding != "utf-8":
        sys.stdout.reconfigure(encoding="utf-8")
    if sys.stderr.encoding != "utf-8":
        sys.stderr.reconfigure(encoding="utf-8")
except Exception:
    pass

# Ensure stderr is used for logging to avoid corrupting stdout JSON-RPC communication
def log(msg):
    sys.stderr.write(f"[GraphServer] {msg}\n")
    sys.stderr.flush()

log("Starting Local Graph MCP Server...")

# Path to the local graph JSON file
GRAPH_PATH = os.path.join(os.path.dirname(__file__), "db_graph.json")

# Adjacency structures for quick lookups
nodes = {}
node_by_name = {}
adj_out = {}
adj_in = {}

def load_graph():
    global nodes, node_by_name, adj_out, adj_in
    if not os.path.exists(GRAPH_PATH):
        log(f"Error: {GRAPH_PATH} not found. Returning empty graph.")
        return
        
    try:
        with open(GRAPH_PATH, "r", encoding="utf-8") as f:
            graph = json.load(f)
            
        nodes = {node["id"]: node for node in graph["nodes"]}
        
        # Index by name
        node_by_name = {}
        for nid, node in nodes.items():
            name_lower = node["name"].lower()
            lbl = node["label"].lower()
            node_by_name[(lbl, name_lower)] = node

        # Build adjacency list
        adj_out = {}
        adj_in = {}
        for edge in graph["edges"]:
            src = edge["source"]
            tgt = edge["target"]
            etype = edge["type"]
            props = edge.get("properties", {})
            
            if src not in adj_out:
                adj_out[src] = []
            adj_out[src].append((tgt, etype, props))
            
            if tgt not in adj_in:
                adj_in[tgt] = []
            adj_in[tgt].append((src, etype, props))
            
        log(f"Loaded graph with {len(nodes)} nodes and {len(graph['edges'])} edges.")
    except Exception as e:
        log(f"Failed to load graph: {e}")

load_graph()

def find_node_by_name(name, label=None):
    name_lower = name.lower()
    if label:
        return node_by_name.get((label.lower(), name_lower))
    for lbl in ["table", "storedprocedure", "view", "function", "menu", "control"]:
        node = node_by_name.get((lbl, name_lower))
        if node:
            return node
    return None

def ensure_node_exists(nid):
    if nid not in nodes:
        parts = nid.split(":")
        prefix = parts[0]
        name = parts[1] if len(parts) > 1 else nid
        
        label_map = {
            "table": "Table",
            "proc": "StoredProcedure",
            "view": "View",
            "function": "Function",
            "menu": "Menu",
            "control": "Control"
        }
        label = label_map.get(prefix, "Table")
        nodes[nid] = {
            "id": nid,
            "label": label,
            "name": name,
            "properties": {"type": "UNKNOWN_PLACEHOLDER"}
        }
    return nodes[nid]

# --- Graph Logic Implementations for the Tools ---

def do_search_nodes(query):
    query_lower = query.lower()
    matches = []
    for nid, node in nodes.items():
        if query_lower in node["name"].lower() or query_lower in nid:
            matches.append({
                "id": node["id"],
                "label": node["label"],
                "name": node["name"],
                "properties": node["properties"]
            })
    return json.dumps(matches[:30], indent=2, ensure_ascii=False)

def do_impact_analysis(target_name, depth=2):
    node = find_node_by_name(target_name)
    if not node:
        return f"Không tìm thấy thực thể nào có tên: {target_name}"
        
    visited = {node["id"]: (0, None, None)} # id -> (depth, parent, edge_type)
    queue = [node["id"]]
    
    while queue:
        curr_id = queue.pop(0)
        curr_depth, _, _ = visited[curr_id]
        
        if curr_depth >= depth:
            continue
            
        incoming = adj_in.get(curr_id, [])
        for src_id, etype, _ in incoming:
            if src_id not in visited:
                visited[src_id] = (curr_depth + 1, curr_id, etype)
                queue.append(src_id)

    by_label = {}
    for nid, (d, parent, etype) in visited.items():
        if nid == node["id"]:
            continue
        dep_node = ensure_node_exists(nid)
        lbl = dep_node["label"]
        if lbl not in by_label:
            by_label[lbl] = []
        
        path = []
        curr = nid
        while curr != node["id"]:
            p_depth, p_id, p_etype = visited[curr]
            curr_node_name = ensure_node_exists(curr)["name"]
            path.append(f"-({p_etype})-> {curr_node_name}")
            curr = p_id
        path_str = f"{dep_node['name']} " + " ".join(path)
        by_label[lbl].append((d, path_str))

    res = [f"=== BẢN ĐỒ PHÂN TÍCH ẢNH HƯỞNG: {node['name']} ({node['label']}) ===",
           f"Tìm thấy {len(visited) - 1} thực thể bị ảnh hưởng trực tiếp hoặc gián tiếp:"]
    
    for lbl, deps in by_label.items():
        res.append(f"\n* Nhóm {lbl} ({len(deps)} thực thể):")
        for d, path_str in sorted(deps, key=lambda x: x[0]):
            indent = "  " * d
            res.append(f"{indent}└─ [Cấp {d}] {path_str}")
            
    return "\n".join(res)

def do_trace_menu_flow(menu_id):
    node = find_node_by_name(menu_id, "Menu")
    if not node:
        node = nodes.get(f"menu:{menu_id.lower()}")
    if not node:
        return f"Không tìm thấy Menu có ID: {menu_id}"

    res = [f"=== LUỒNG GIAO DIỆN -> DATABASE: {node['name']} ===",
           f"ClassName: {node['properties'].get('class_name')}",
           f"Platform: Web={node['properties'].get('is_web')}, Mobile={node['properties'].get('is_mobile')}",
           "-" * 50]

    outgoing = adj_out.get(node["id"], [])
    renderers = [ensure_node_exists(tgt) for tgt, etype, _ in outgoing if etype == "CALLS_RENDERER"]
    
    if not renderers:
        res.append("⚠️ Không tìm thấy SP HTML renderer cho Menu này.")
        return "\n".join(res)

    for r in renderers:
        res.append(f"[Renderer] ── {r['name']} (SP)")
        r_outgoing = adj_out.get(r["id"], [])
        
        controls = [ensure_node_exists(tgt) for tgt, etype, _ in r_outgoing if etype == "CONTAINS"]
        api_calls = [ensure_node_exists(tgt) for tgt, etype, _ in r_outgoing if etype == "CALLS_API"]
        
        if controls:
            res.append(f"  ├─ [Controls Giao diện] ({len(controls)} controls):")
            for ctrl in controls[:7]:
                target_editor = ctrl['properties'].get('table_editor')
                editor_str = f" -> Cập nhật: {target_editor}" if target_editor else ""
                res.append(f"  │  ├─ Ô: {ctrl['name']} ({ctrl['properties'].get('control_type')}){editor_str}")
            if len(controls) > 7:
                res.append(f"  │  └─ ... và {len(controls)-7} controls khác.")
                
        if api_calls:
            res.append(f"  ├─ [API Calls (Gọi qua AjaxHPAParadise)]:")
            for api in api_calls:
                res.append(f"  │  ├─ Thủ tục: {api['name']}")
                api_outgoing = adj_out.get(api["id"], [])
                tables = [ensure_node_exists(tgt) for tgt, etype, _ in api_outgoing if etype == "DEPENDS_ON" and ensure_node_exists(tgt)["label"] == "Table"]
                if tables:
                    res.append(f"  │  │  └─ Bảng SQL tác động:")
                    for t in tables[:4]:
                        res.append(f"  │  │     ├─ {t['name']}")
                    if len(tables) > 4:
                        res.append(f"  │  │     └─ ... và {len(tables)-4} bảng khác.")
        else:
            r_tables = [ensure_node_exists(tgt) for tgt, etype, _ in r_outgoing if etype == "DEPENDS_ON" and ensure_node_exists(tgt)["label"] == "Table"]
            if r_tables:
                res.append(f"  ├─ [Tương tác Bảng từ Renderer SP]:")
                for t in r_tables[:6]:
                    res.append(f"  │  ├─ Bảng: {t['name']}")
                if len(r_tables) > 6:
                    res.append(f"  │  └─ ... và {len(r_tables)-6} bảng khác.")
                    
    return "\n".join(res)

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
                client_protocol = req.get("params", {}).get("protocolVersion", "2024-11-05")
                respond(req_id, {
                    "protocolVersion": client_protocol,
                    "capabilities": {
                        "tools": {}
                    },
                    "serverInfo": {
                        "name": "paradisehr-local-graph",
                        "version": "1.0.0"
                    }
                })
                
            elif method == "tools/list":
                respond(req_id, {
                    "tools": [
                        {
                            "name": "search_graph_nodes",
                            "description": "Tìm kiếm thực thể trong đồ thị theo từ khóa.",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "query": {"type": "string", "description": "Từ khóa tìm kiếm (tên bảng, procedure...)"}
                                },
                                "required": ["query"]
                            }
                        },
                        {
                            "name": "impact_analysis",
                            "description": "Phân tích ảnh hưởng khi sửa đổi một thực thể (Table, Procedure) đến các đối tượng phụ thuộc khác trong đồ thị.",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "target_name": {"type": "string", "description": "Tên thực thể cần phân tích (ví dụ: tblEmployee)"},
                                    "depth": {"type": "integer", "description": "Độ sâu duyệt đồ thị (1-3), mặc định là 2"}
                                },
                                "required": ["target_name"]
                            }
                        },
                        {
                            "name": "trace_menu_flow",
                            "description": "Truy vết luồng gọi từ giao diện người dùng (Menu ID) xuống tới các stored procedure nghiệp vụ và bảng dữ liệu vật lý.",
                            "inputSchema": {
                                "type": "object",
                                "properties": {
                                    "menu_id": {"type": "string", "description": "Mã Menu ID (ví dụ: MnuHRS030)"}
                                },
                                "required": ["menu_id"]
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
                if tool_name == "search_graph_nodes":
                    result_text = do_search_nodes(args.get("query", ""))
                elif tool_name == "impact_analysis":
                    result_text = do_impact_analysis(args.get("target_name", ""), args.get("depth", 2))
                elif tool_name == "trace_menu_flow":
                    result_text = do_trace_menu_flow(args.get("menu_id", ""))
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
                    
        except json.JSONDecodeError as e:
            log(f"Invalid JSON-RPC payload: {e}")
            continue
        except Exception as e:
            log(f"Error in main loop: {e}")
            try:
                if 'req_id' in locals() and req_id is not None:
                    respond(req_id, error={"code": -32603, "message": f"Internal error: {e}"})
            except Exception as respond_error:
                log(f"Failed to send error response: {respond_error}")
            continue

if __name__ == "__main__":
    main()
