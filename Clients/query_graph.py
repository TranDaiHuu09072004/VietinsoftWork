import json
import os
import re
import sys

# Reconfigure console output to UTF-8 to prevent encoding errors on Windows
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

# Load the database graph
GRAPH_PATH = os.path.join(os.path.dirname(__file__), "db_graph.json")

def load_graph():
    if not os.path.exists(GRAPH_PATH):
        raise FileNotFoundError(f"Graph file not found at {GRAPH_PATH}. Please run extract_db_graph.py first.")
    with open(GRAPH_PATH, "r", encoding="utf-8") as f:
        return json.load(f)

# Building indexes for fast traversal
class ParadiseGraphQueryEngine:
    def __init__(self, graph):
        self.nodes = {node["id"]: node for node in graph["nodes"]}
        
        # Build index of nodes by lowercase name and label for easy lookup
        self.node_by_name = {}
        for nid, node in self.nodes.items():
            name_lower = node["name"].lower()
            lbl = node["label"].lower()
            self.node_by_name[(lbl, name_lower)] = node

        # Build adjacency lists
        self.adj_out = {} # source -> list of (target, edge_type, properties)
        self.adj_in = {}  # target -> list of (source, edge_type, properties)
        
        for edge in graph["edges"]:
            src = edge["source"]
            tgt = edge["target"]
            etype = edge["type"]
            props = edge.get("properties", {})
            
            if src not in self.adj_out:
                self.adj_out[src] = []
            self.adj_out[src].append((tgt, etype, props))
            
            if tgt not in self.adj_in:
                self.adj_in[tgt] = []
            self.adj_in[tgt].append((src, etype, props))

    def find_node_by_name(self, name, label=None):
        name_lower = name.lower()
        if label:
            return self.node_by_name.get((label.lower(), name_lower))
        # Search all labels
        for lbl in ["table", "storedprocedure", "view", "function", "menu", "control"]:
            node = self.node_by_name.get((lbl, name_lower))
            if node:
                return node
        return None

    def ensure_node_exists(self, nid):
        if nid not in self.nodes:
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
            
            self.nodes[nid] = {
                "id": nid,
                "label": label,
                "name": name,
                "properties": {
                    "type": "UNKNOWN_PLACEHOLDER"
                }
            }
        return self.nodes[nid]

    # --- Scenario 1: Impact Analysis ---
    def impact_analysis(self, target_name, depth=3):
        node = self.find_node_by_name(target_name)
        if not node:
            print(f"❌ Không tìm thấy thực thể nào có tên: {target_name}")
            return
            
        print(f"\n=== PHÂN TÍCH ẢNH HƯỞNG CHO THỰC THỂ: {node['name']} ({node['label']}) ===")
        
        # We perform a BFS traversal backwards (incoming edges) to see what depends on this node
        visited = {node["id"]: (0, None, None)} # id -> (depth, parent, edge_type)
        queue = [node["id"]]
        
        while queue:
            curr_id = queue.pop(0)
            curr_depth, _, _ = visited[curr_id]
            
            if curr_depth >= depth:
                continue
                
            incoming = self.adj_in.get(curr_id, [])
            for src_id, etype, _ in incoming:
                if src_id not in visited:
                    visited[src_id] = (curr_depth + 1, curr_id, etype)
                    queue.append(src_id)

        # Group dependencies by type
        by_label = {}
        for nid, (d, parent, etype) in visited.items():
            if nid == node["id"]:
                continue
            
            dep_node = self.ensure_node_exists(nid)
            lbl = dep_node["label"]
            if lbl not in by_label:
                by_label[lbl] = []
            
            # Reconstruct path
            path = []
            curr = nid
            while curr != node["id"]:
                p_depth, p_id, p_etype = visited[curr]
                curr_node_name = self.ensure_node_exists(curr)["name"]
                path.append(f"-({p_etype})-> {curr_node_name}")
                curr = p_id
            path_str = f"{dep_node['name']} " + " ".join(path)
            by_label[lbl].append((d, path_str))

        # Output results
        print(f"Tìm thấy {len(visited) - 1} thực thể phụ thuộc trực tiếp hoặc gián tiếp (Độ sâu tối đa: {depth}):")
        for lbl, deps in by_label.items():
            print(f"\n  • [Nhóm {lbl}] ({len(deps)} thực thể):")
            for d, path_str in sorted(deps, key=lambda x: x[0]):
                indent = "    " * d
                print(f"{indent}└─ [Cấp {d}] {path_str}")

    # --- Scenario 2: Trace UI-to-DB Call Hierarchy ---
    def trace_menu_flow(self, menu_id):
        node = self.find_node_by_name(menu_id, "Menu")
        if not node:
            node = self.nodes.get(f"menu:{menu_id.lower()}")
        if not node:
            print(f"❌ Không tìm thấy Menu với ID: {menu_id}")
            return

        print(f"\n=== TRUY VẾT LUỒNG GIAO DIỆN -> DATABASE: {node['name']} ===")
        print(f"Menu ID: {node['name']}")
        print(f"Class Name: {node['properties'].get('class_name')}")
        print(f"Platform: Web={node['properties'].get('is_web')}, Mobile={node['properties'].get('is_mobile')}")
        print("-" * 60)

        # Step 1: Find SP HTML Renderer
        outgoing = self.adj_out.get(node["id"], [])
        renderers = [self.ensure_node_exists(tgt) for tgt, etype, _ in outgoing if etype == "CALLS_RENDERER"]
        
        if not renderers:
            print("  ⚠️ Không tìm thấy Stored Procedure render HTML/JS trực tiếp gắn với Menu này.")
            return

        for renderer in renderers:
            print(f"  [Renderer HTML/JS] ── {renderer['name']} (SP)")
            
            # Step 2: Find Controls inside this Menu/Renderer
            r_outgoing = self.adj_out.get(renderer["id"], [])
            controls = [self.ensure_node_exists(tgt) for tgt, etype, _ in r_outgoing if etype == "CONTAINS"]
            
            # Step 3: Find API Calls from this Renderer
            api_calls = [self.ensure_node_exists(tgt) for tgt, etype, _ in r_outgoing if etype == "CALLS_API"]
            
            if controls:
                print(f"    ├─ [Controls Giao diện] ({len(controls)} controls cấu hình):")
                for ctrl in controls[:5]:
                    target_editor = ctrl['properties'].get('table_editor')
                    editor_str = f" -> Cập nhật bảng: {target_editor}" if target_editor else ""
                    print(f"    │  ├─ Ô nhập: {ctrl['name']} ({ctrl['properties'].get('control_type')}){editor_str}")
                if len(controls) > 5:
                    print(f"    │  └─ ... và {len(controls) - 5} controls khác.")
            
            if api_calls:
                print(f"    ├─ [API Calls (Gọi từ client qua AjaxHPAParadise)]:")
                for api in api_calls:
                    print(f"    │  ├─ Gọi thủ tục nghiệp vụ: {api['name']}")
                    # Step 4: Find Tables referenced by this API SP
                    api_outgoing = self.adj_out.get(api["id"], [])
                    tables = [self.ensure_node_exists(tgt) for tgt, etype, _ in api_outgoing if etype == "DEPENDS_ON" and self.ensure_node_exists(tgt)["label"] == "Table"]
                    if tables:
                        print(f"    │  │  └─ Tác động cơ sở dữ liệu:")
                        for t in tables[:3]:
                            print(f"    │  │     ├─ Đọc/Ghi Bảng: {t['name']}")
                        if len(tables) > 3:
                            print(f"    │  │     └─ ... và {len(tables)-3} bảng khác.")
            else:
                r_tables = [self.ensure_node_exists(tgt) for tgt, etype, _ in r_outgoing if etype == "DEPENDS_ON" and self.ensure_node_exists(tgt)["label"] == "Table"]
                if r_tables:
                    print(f"    ├─ [Tương tác Bảng trực tiếp từ Renderer SP]:")
                    for t in r_tables[:5]:
                        print(f"    │  ├─ Đọc/Ghi Bảng: {t['name']}")
                    if len(r_tables) > 5:
                        print(f"    │  └─ ... và {len(r_tables)-5} bảng khác.")

    # --- Scenario 3: SPA Routing Map ---
    def spa_routing_map(self, start_menu_id=None):
        print("\n=== BẢN ĐỒ ĐIỀU HƯỚNG MÀN HÌNH (SPA ROUTING MAP) ===")
        
        routing_edges = []
        for src_id, targets in self.adj_out.items():
            for tgt_id, etype, _ in targets:
                if etype == "NAVIGATES_TO":
                    routing_edges.append((src_id, tgt_id))
                    
        print(f"Phát hiện tổng cộng {len(routing_edges)} liên kết điều hướng SPA qua Javascript nhúng.")
        
        if start_menu_id:
            start_node = self.find_node_by_name(start_menu_id)
            if not start_node:
                print(f"❌ Không tìm thấy điểm xuất phát: {start_menu_id}")
                return
                
            print(f"\nLuồng chuyển trang xuất phát từ {start_node['name']}:")
            visited = set()
            
            def dfs(curr_id, path_str, level=0):
                if curr_id in visited or level > 4:
                    print("  " * level + "└─ " + path_str + " (vòng lặp hoặc quá sâu)")
                    return
                visited.add(curr_id)
                curr_node = self.ensure_node_exists(curr_id)
                
                print("  " * level + "└─ " + f"{curr_node['name']} ({curr_node['label']})")
                
                out_edges = self.adj_out.get(curr_id, [])
                
                if curr_node["label"] == "Menu":
                    renderers = [tgt for tgt, etype, _ in out_edges if etype == "CALLS_RENDERER"]
                    for r_id in renderers:
                        r_out = self.adj_out.get(r_id, [])
                        for target_menu, etype, _ in r_out:
                            if etype == "NAVIGATES_TO":
                                dfs(target_menu, "openFormParam", level + 1)
                else:
                    for target_menu, etype, _ in out_edges:
                        if etype == "NAVIGATES_TO":
                            dfs(target_menu, "openFormParam", level + 1)
                            
            dfs(start_node["id"], "Start")
        else:
            print("\nVí dụ các liên kết SPA routing tiêu biểu:")
            for src_id, tgt_id in routing_edges[:10]:
                src_node = self.ensure_node_exists(src_id)
                tgt_node = self.ensure_node_exists(tgt_id)
                print(f"  • {src_node['name']} ({src_node['label']}) ──[NAVIGATES_TO]──> {tgt_node['name']} (Menu)")

    # --- Scenario 4: Deprecated Validation ---
    def check_deprecated_violations(self):
        print("\n=== BÁO CÁO QUÉT KIỂM TRA THỰC THỂ LỖI THỜI (DEPRECATED CHECK) ===")
        
        deprecated_rules = {
            "table": [
                "tblZaloFollowerInfo"
            ],
            "proc": [
                "sp_CompanySalarySummary",
                "sp_ZaloSendSMSPaySlip",
                "sp_ZaloSendSMSFor",
                "sp_CompanySalarySummary_BeforeLoad",
                "sp_CompanySalarySummary_Debug",
                "sp_CompanySalarySummary_EMC",
                "sp_CompanySalarySummary_Export01",
                "sp_CompanySalarySummary_html",
                "sp_CompanySalarySummary_STD",
                "sp_CompanySalarySummary_view"
            ],
            "menu": [
                "MnuAtt1", "MnuAtt3", "MnuEmployeeInfo", "MnuPRL1", "MnuATTAppOT", "MnuATTOTRe",
                "MnuWebATT", "MnuWebHRM", "MnuWebPRL"
            ]
        }
        
        violations_found = 0
        
        for dep_type, names in deprecated_rules.items():
            for name in names:
                dep_node = self.find_node_by_name(name)
                if not dep_node:
                    continue
                    
                nid = dep_node["id"]
                incoming = self.adj_in.get(nid, [])
                
                active_referencing = []
                for src_id, etype, _ in incoming:
                    src_node = self.ensure_node_exists(src_id)
                    src_name = src_node["name"]
                    
                    is_src_deprecated = False
                    for d_names in deprecated_rules.values():
                        if any(src_name.lower().startswith(dn.lower()) for dn in d_names):
                            is_src_deprecated = True
                            break
                            
                    if not is_src_deprecated:
                        active_referencing.append((src_node, etype))
                        
                if active_referencing:
                    violations_found += len(active_referencing)
                    print(f"\n⚠️ PHÁT HIỆN VI PHẠM: Thực thể lỗi thời '{dep_node['name']}' ({dep_node['label']}) đang bị tham chiếu bởi các đối tượng ĐANG HOẠT ĐỘNG:")
                    for ref_node, etype in active_referencing:
                        print(f"  └─ [{ref_node['label']}] '{ref_node['name']}' ──({etype})──> '{dep_node['name']}'")
                        
        if violations_found == 0:
            print("✅ Tuyệt vời! Không phát hiện thực thể đang hoạt động nào tham chiếu đến các đối tượng đã lỗi thời.")
        else:
            print(f"\n❌ Tổng cộng phát hiện {violations_found} vi phạm liên kết thực thể lỗi thời.")


def run_demo():
    print("Loading graph data...")
    graph = load_graph()
    engine = ParadiseGraphQueryEngine(graph)
    
    # Run Scenario 1: Impact Analysis
    engine.impact_analysis("tblTmpAttend")
    engine.impact_analysis("tblEmployee", depth=2)
    
    # Run Scenario 2: Trace UI-to-DB Flow
    web_menus = [n["name"] for n in graph["nodes"] if n["label"] == "Menu" and n["properties"].get("is_web") and n["properties"].get("class_name")]
    if web_menus:
        selected_menu = None
        for wm in web_menus:
            m_node = engine.find_node_by_name(wm, "Menu")
            if m_node and len(engine.adj_out.get(m_node["id"], [])) > 0:
                selected_menu = wm
                break
        if not selected_menu:
            selected_menu = web_menus[0]
        engine.trace_menu_flow(selected_menu)
    else:
        engine.trace_menu_flow("MnuHRS142")
        
    # Run Scenario 3: SPA Routing Map
    proc_with_routing = []
    for n in graph["nodes"]:
        if any(e["source"] == n["id"] and e["type"] == "NAVIGATES_TO" for e in graph["edges"]):
            incoming = engine.adj_in.get(n["id"], [])
            for src_id, etype, _ in incoming:
                src_node = engine.ensure_node_exists(src_id)
                if src_node["label"] == "Menu":
                    proc_with_routing.append(src_node["name"])
                    
    if proc_with_routing:
        engine.spa_routing_map(proc_with_routing[0])
    else:
        engine.spa_routing_map()
        
    # Run Scenario 4: Deprecated Validation
    engine.check_deprecated_violations()

if __name__ == "__main__":
    run_demo()
