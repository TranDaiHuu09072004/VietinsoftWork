import pyodbc
import json
import os
import re

conn_base = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
    "DATABASE=Paradise_Dev;"
)

def extract_graph():
    print("Connecting to SQL Server database...")
    conn = pyodbc.connect(conn_base)
    cursor = conn.cursor()
    
    nodes = {}
    edges = []

    # 1. Extract tables
    print("Extracting tables...")
    cursor.execute("""
        SELECT name, type_desc 
        FROM sys.tables 
        WHERE name NOT LIKE 'dt%'
    """)
    for row in cursor.fetchall():
        table_name = row[0]
        nodes[f"table:{table_name.lower()}"] = {
            "id": f"table:{table_name.lower()}",
            "label": "Table",
            "name": table_name,
            "properties": {
                "type": "USER_TABLE"
            }
        }

    # 2. Extract views
    print("Extracting views...")
    cursor.execute("""
        SELECT name, type_desc 
        FROM sys.views 
        WHERE name NOT LIKE 'dt%'
    """)
    for row in cursor.fetchall():
        view_name = row[0]
        nodes[f"view:{view_name.lower()}"] = {
            "id": f"view:{view_name.lower()}",
            "label": "View",
            "name": view_name,
            "properties": {
                "type": "VIEW"
            }
        }

    # 3. Extract Stored Procedures and Functions
    print("Extracting procedures and functions...")
    cursor.execute("""
        SELECT name, type_desc 
        FROM sys.objects 
        WHERE type IN ('P', 'FN', 'IF', 'TF')
          AND name NOT LIKE 'dt%'
    """)
    for row in cursor.fetchall():
        name = row[0]
        type_desc = row[1]
        
        is_renderer = False
        if name.lower().endswith('_html') or 'html' in name.lower() or name.lower().startswith('sp_report'):
            is_renderer = True

        label = "StoredProcedure"
        if "FUNCTION" in type_desc:
            label = "Function"

        nodes[f"proc:{name.lower()}"] = {
            "id": f"proc:{name.lower()}",
            "label": label,
            "name": name,
            "properties": {
                "type": type_desc,
                "is_renderer": is_renderer
            }
        }

    # 4. Extract Foreign Key Relationships
    print("Extracting foreign key relations...")
    cursor.execute("""
        SELECT 
            tp.name AS ParentTable, 
            tr.name AS ReferencedTable,
            fk.name AS ForeignKeyName
        FROM sys.foreign_keys fk
        INNER JOIN sys.tables tp ON fk.parent_object_id = tp.object_id
        INNER JOIN sys.tables tr ON fk.referenced_object_id = tr.object_id
    """)
    for row in cursor.fetchall():
        parent = row[0].lower()
        referenced = row[1].lower()
        fk_name = row[2]
        
        edges.append({
            "source": f"table:{parent}",
            "target": f"table:{referenced}",
            "type": "REFERENCES",
            "properties": {
                "fk_name": fk_name
            }
        })

    # 5. Extract Expression Dependencies (SP -> Table / SP -> SP)
    print("Extracting expression dependencies...")
    cursor.execute("""
        SELECT 
            o_ref.name AS ReferencingName,
            o_ref.type_desc AS ReferencingType,
            d.referenced_entity_name AS ReferencedName,
            COALESCE(o_dep.type_desc, 'UNKNOWN') AS ReferencedType
        FROM sys.sql_expression_dependencies d
        INNER JOIN sys.objects o_ref ON d.referencing_id = o_ref.object_id
        LEFT JOIN sys.objects o_dep ON d.referenced_id = o_dep.object_id
        WHERE o_ref.name NOT LIKE 'dt%'
          AND d.referenced_entity_name NOT LIKE 'dt%'
    """)
    for row in cursor.fetchall():
        ref_name = row[0].lower()
        ref_type = row[1]
        dep_name = row[2].lower()
        dep_type = row[3]
        
        source_prefix = "proc:" if "PROCEDURE" in ref_type or "FUNCTION" in ref_type else ("table:" if "TABLE" in ref_type else "view:")
        target_prefix = "proc:" if "PROCEDURE" in dep_type or "FUNCTION" in dep_type else ("table:" if "TABLE" in dep_type else "view:")
        
        if dep_type == 'UNKNOWN':
            if dep_name.startswith('tbl') or dep_name.startswith('userinfo') or dep_name.startswith('template'):
                target_prefix = "table:"
            elif 'sp_' in dep_name or dep_name.startswith('fn_'):
                target_prefix = "proc:"
            else:
                target_prefix = "table:"

        source_id = f"{source_prefix}{ref_name}"
        target_id = f"{target_prefix}{dep_name}"
        
        edges.append({
            "source": source_id,
            "target": target_id,
            "type": "DEPENDS_ON",
            "properties": {}
        })

    # 6. Extract Menus
    print("Extracting menus...")
    # Check if NotUsePlatform column exists in MEN_Menu (safeguard for older/different client DB schemas)
    cursor.execute("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MEN_Menu'")
    menu_columns = [r[0].lower() for r in cursor.fetchall()]
    has_not_use_platform = "notuseplatform" in menu_columns

    sql_menu = """
        SELECT 
            MenuID,
            ClassName,
            IsWeb,
            IsUseMobileDevice
    """
    if has_not_use_platform:
        sql_menu += ", NotUsePlatform"
    sql_menu += " FROM MEN_Menu"

    cursor.execute(sql_menu)
    for row in cursor.fetchall():
        menu_id = row[0]
        class_name = row[1]
        is_web = bool(row[2])
        is_mobile = bool(row[3])
        not_use_platform = row[4] if has_not_use_platform else None
        
        nodes[f"menu:{menu_id.lower()}"] = {
            "id": f"menu:{menu_id.lower()}",
            "label": "Menu",
            "name": menu_id,
            "properties": {
                "class_name": class_name,
                "is_web": is_web,
                "is_mobile": is_mobile,
                "not_use_platform": not_use_platform
            }
        }
        
        if class_name:
            proc_key = f"proc:{class_name.lower()}"
            if proc_key in nodes:
                edges.append({
                    "source": f"menu:{menu_id.lower()}",
                    "target": proc_key,
                    "type": "CALLS_RENDERER",
                    "properties": {}
                })

    # 7. Extract Controls
    print("Extracting controls...")
    try:
        cursor.execute("""
            SELECT 
                TableName,
                ColumnName,
                [Type],
                TableEditor,
                DisplayName
            FROM tblCommonControlType_Signed
            WHERE TableName IS NOT NULL AND ColumnName IS NOT NULL
        """)
        for row in cursor.fetchall():
            table_name = row[0]
            col_name = row[1]
            ctrl_type = row[2]
            table_editor = row[3]
            display_name = row[4]
            
            ctrl_id = f"control:{table_name.lower()}:{col_name.lower()}"
            nodes[ctrl_id] = {
                "id": ctrl_id,
                "label": "Control",
                "name": col_name,
                "properties": {
                    "control_type": ctrl_type,
                    "table_editor": table_editor,
                    "display_name": display_name
                }
            }
            
            parent_proc = f"proc:{table_name.lower()}"
            parent_table = f"table:{table_name.lower()}"
            
            if parent_proc in nodes:
                edges.append({
                    "source": parent_proc,
                    "target": ctrl_id,
                    "type": "CONTAINS",
                    "properties": {}
                })
            elif parent_table in nodes:
                edges.append({
                    "source": parent_table,
                    "target": ctrl_id,
                    "type": "CONTAINS",
                    "properties": {}
                })
                
            if table_editor:
                target_table = f"table:{table_editor.lower()}"
                if target_table in nodes:
                    edges.append({
                        "source": ctrl_id,
                        "target": target_table,
                        "type": "EDIT_TARGET",
                        "properties": {}
                    })
    except Exception as e:
        print(f"Warning: Could not extract controls from tblCommonControlType_Signed: {e}")

    # 8. Extract JS dependencies (SPA Routing & API Calls) from HTML renderers
    print("Extracting JS dependencies (SPA Routing & API Calls) from HTML renderers...")
    cursor.execute("""
        SELECT name, OBJECT_DEFINITION(object_id)
        FROM sys.procedures
        WHERE name LIKE '%_html' OR name LIKE '%html%'
    """)
    for row in cursor.fetchall():
        proc_name = row[0]
        proc_def = row[1]
        if not proc_def:
            continue
            
        proc_key = f"proc:{proc_name.lower()}"
        
        # Parse API Calls: AjaxHPAParadise("ProcName")
        api_matches = re.findall(r'AjaxHPAParadise\s*\(\s*[\'"]([a-zA-Z0-9_]+)[\'"]', proc_def, re.IGNORECASE)
        for target_proc in api_matches:
            target_key = f"proc:{target_proc.lower()}"
            if target_key not in nodes:
                nodes[target_key] = {
                    "id": target_key,
                    "label": "StoredProcedure",
                    "name": target_proc,
                    "properties": {
                        "type": "SQL_STORED_PROCEDURE",
                        "is_renderer": False
                    }
                }
            edges.append({
                "source": proc_key,
                "target": target_key,
                "type": "CALLS_API",
                "properties": {}
            })
            
        # Parse SPA Routing: openFormParam("MenuID") or OpenFormParamMobile("MenuID")
        routing_matches_1 = re.findall(r'openFormParam\s*\(\s*[\'"]([a-zA-Z0-9_]+)[\'"]', proc_def, re.IGNORECASE)
        routing_matches_2 = re.findall(r'OpenFormParamMobile\s*\(\s*[\'"]([a-zA-Z0-9_]+)[\'"]', proc_def, re.IGNORECASE)
        for target_menu in routing_matches_1 + routing_matches_2:
            target_key = f"menu:{target_menu.lower()}"
            if target_key not in nodes:
                nodes[target_key] = {
                    "id": target_key,
                    "label": "Menu",
                    "name": target_menu,
                    "properties": {
                        "class_name": "",
                        "is_web": True,
                        "is_mobile": "mobile" in target_menu.lower()
                    }
                }
            edges.append({
                "source": proc_key,
                "target": target_key,
                "type": "NAVIGATES_TO",
                "properties": {}
            })

    # 9. Post-process to remove duplicates and normalize
    print("Normalizing graph...")
    seen_edges = set()
    dedup_edges = []
    for edge in edges:
        edge_key = (edge["source"], edge["target"], edge["type"])
        if edge_key not in seen_edges:
            seen_edges.add(edge_key)
            dedup_edges.append(edge)

    graph_data = {
        "nodes": list(nodes.values()),
        "edges": dedup_edges
    }
    
    # Save JSON Graph
    output_path = os.path.join(os.path.dirname(__file__), "db_graph.json")
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(graph_data, f, indent=2, ensure_ascii=False)
    print(f"Graph saved to: {output_path}")

    # 10. Generate Neo4j Cypher Import Script
    print("Generating Neo4j Cypher import script...")
    cypher_path = os.path.join(os.path.dirname(__file__), "import_graph.cypher")
    
    with open(cypher_path, "w", encoding="utf-8") as cf:
        cf.write("// --- Clear existing database ---\n")
        cf.write("MATCH (n) DETACH DELETE n;\n\n")
        
        cf.write("// --- Create constraints for unique IDs ---\n")
        labels = ["Table", "View", "StoredProcedure", "Function", "Menu", "Control"]
        for lbl in labels:
            cf.write(f"CREATE CONSTRAINT FOR (n:{lbl}) REQUIRE n.id IS UNIQUE;\n")
        cf.write("\n")
        
        cf.write("// --- Create Nodes ---\n")
        for node in graph_data["nodes"]:
            lbl = node["label"]
            nid = node["id"].replace("'", "\\'")
            name = node["name"].replace("'", "\\'")
            props = [f"id: '{nid}'", f"name: '{name}'"]
            for k, v in node["properties"].items():
                v_str = str(v).replace("'", "\\'")
                if isinstance(v, bool):
                    props.append(f"{k}: {str(v).lower()}")
                else:
                    props.append(f"{k}: '{v_str}'")
            props_str = ", ".join(props)
            cf.write(f"CREATE (:{lbl} {{{props_str}}});\n")
        cf.write("\n")
        
        cf.write("// --- Create Edges ---\n")
        cf.write("USING PERIODIC COMMIT 500\n" if len(graph_data["edges"]) > 1000 else "")
        for edge in graph_data["edges"]:
            src = edge["source"].replace("'", "\\'")
            tgt = edge["target"].replace("'", "\\'")
            etype = edge["type"]
            props = []
            for k, v in edge["properties"].items():
                v_str = str(v).replace("'", "\\'")
                props.append(f"{k}: '{v_str}'")
            props_str = f" {{{', '.join(props)}}}" if props else ""
            cf.write(f"MATCH (a {{id: '{src}'}}), (b {{id: '{tgt}'}}) CREATE (a)-[:{etype}{props_str}]->(b);\n")
            
    print(f"Cypher script saved to: {cypher_path}")
    print(f"Total Nodes: {len(graph_data['nodes'])}")
    print(f"Total Edges: {len(graph_data['edges'])}")
    
    conn.close()

if __name__ == "__main__":
    extract_graph()
