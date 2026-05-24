import re
import pyodbc
from pathlib import Path
import sys

sys.stdout.reconfigure(encoding='utf-8')

# Mapping dictionary for class attributes replacement
# FontAwesome to Bootstrap Icons mapping
mapping = {
    # Prefix combinations
    'fa-regular fa-folder-open': 'bi bi-folder2-open',
    'fa-solid fa-folder-open': 'bi bi-folder2-open',
    'fa-regular fa-calendar-days': 'bi bi-calendar3',
    'fa-solid fa-calendar-days': 'bi bi-calendar3',
    'fa-regular fa-face-smile': 'bi bi-emoji-smile',
    
    'fa-solid fa-arrow-down': 'bi bi-arrow-down',
    'fa-solid fa-arrow-right-long': 'bi bi-arrow-right',
    'fa-solid fa-arrow-up-right-from-square': 'bi bi-box-arrow-up-right',
    'fa-solid fa-calendar-check': 'bi bi-calendar-check',
    'fa-solid fa-calendar-day': 'bi bi-calendar-date',
    'fa-solid fa-check': 'bi bi-check-lg',
    'fa-solid fa-chevron-left': 'bi bi-chevron-left',
    'fa-solid fa-chevron-right': 'bi bi-chevron-right',
    'fa-solid fa-circle-check': 'bi bi-check-circle-fill',
    'fa-solid fa-circle-xmark': 'bi bi-x-circle-fill',
    'fa-solid fa-clipboard-list': 'bi bi-card-list',
    'fa-solid fa-clock': 'bi bi-clock',
    'fa-solid fa-hourglass-half': 'bi bi-hourglass-split',
    'fa-solid fa-magnifying-glass': 'bi bi-search',
    'fa-solid fa-paperclip': 'bi bi-paperclip',
    'fa-solid fa-plus': 'bi bi-plus-lg',
    'fa-solid fa-shield-halved': 'bi bi-shield-shaded',
    'fa-solid fa-tag': 'bi bi-tag',
    'fa-solid fa-tasks': 'bi bi-list-task',
    'fa-solid fa-up-right-from-square': 'bi bi-box-arrow-up-right',
    'fa-solid fa-user-check': 'bi bi-person-check',
    'fa-solid fa-user-pen': 'bi bi-person-workspace',
    'fa-solid fa-user-tie': 'bi bi-person-badge',
    'fa-solid fa-xmark': 'bi bi-x-lg',
    
    # Spinner animation handling
    'fa-solid fa-spinner fa-spin': 'bi bi-arrow-repeat paradise-spin',
    'fa-solid fa-spinner': 'bi bi-arrow-repeat paradise-spin',
}

files_to_update = [
    Path(r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\migrate_menu_complaint_20260523.sql"),
    Path(r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\migrate_menu_ComplaintForm_20260523.sql")
]

def replace_in_file(file_path):
    if not file_path.exists():
        print(f"File {file_path} does not exist. Skipping.")
        return False
        
    print(f"Updating FontAwesome icons in {file_path}...")
    content = file_path.read_text(encoding="utf-8")
    
    # 1. Perform direct mappings
    for fa_cls, bi_cls in mapping.items():
        content = content.replace(fa_cls, bi_cls)
        
    # Double-check: in case some classes were written like class="fa-solid fa-folder-open empty-icon"
    # we need to replace raw classes
    for fa_cls, bi_cls in mapping.items():
        # Remove fa-solid, fa-regular, etc prefixes if they are standing next to specific classes
        # e.g., 'fa-solid fa-xmark' -> 'bi bi-x-lg'
        content = re.sub(r'\b' + fa_cls.replace(' ', r'\s+') + r'\b', bi_cls, content)
        
    # 2. Inject paradise-spin keyframe animation if not already present
    # We look for </style> inside the HTML renderer procedures and inject the spinner rule before it
    spinner_css = """
    /* Spinner animation for Bootstrap Icons replacement */
    @keyframes paradise-spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    .paradise-spin {
      display: inline-block;
      animation: paradise-spin 1s linear infinite;
    }
  </style>"""
    
    content = content.replace("  </style>", spinner_css)
    content = content.replace("</style>", spinner_css)
    # Deduplicate in case </style> got replaced twice or rule is already there
    content = content.replace(spinner_css + "\n" + spinner_css, spinner_css)
    
    file_path.write_text(content, encoding="utf-8")
    print(f"File {file_path.name} updated successfully.")
    return True

# Apply file updates
updated_any = False
for f in files_to_update:
    if replace_in_file(f):
        updated_any = True

# Deploy changes directly to databases
if updated_any:
    dbs = ["Paradise_Dev", "Vietinsoft_ForTest"]
    conn_base = (
        "DRIVER={ODBC Driver 17 for SQL Server};"
        "SERVER=192.168.11.51,2222;"
        "UID=vts.sa;"
        "PWD=LuaThieng1@3@2020;"
        "TrustServerCertificate=yes;"
    )
    
    for db in dbs:
        print(f"\n=== Deploying updated script to {db} ===")
        conn_str = f"{conn_base}DATABASE={db};"
        try:
            conn = pyodbc.connect(conn_str)
            cursor = conn.cursor()
            
            # Read and execute migrate_menu_complaint_20260523.sql
            script_path = files_to_update[0]
            script_sql = script_path.read_text(encoding="utf-8")
            
            batches = []
            current_batch = []
            for line in script_sql.splitlines():
                if line.strip().upper() == "GO":
                    if current_batch:
                        batches.append("\n".join(current_batch))
                        current_batch = []
                else:
                    current_batch.append(line)
            if current_batch:
                batches.append("\n".join(current_batch))
                
            for idx, batch in enumerate(batches, 1):
                batch_trimmed = batch.strip()
                if not batch_trimmed:
                    continue
                cursor.execute(batch_trimmed)
                conn.commit()
                
            print(f"Migration script executed successfully on {db}!")
            
            # Rebuild caches
            print(f"Rebuilding HTML caches for {db}...")
            cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_GetComplaintList_html', 'VN', 'sp_Task_GetComplaintList'")
            cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_GetComplaintList_html', 'EN', 'sp_Task_GetComplaintList'")
            cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'VN', 'sp_Task_ComplaintForm'")
            cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'EN', 'sp_Task_ComplaintForm'")
            
            # Rebuild layout/dashboard caches
            cursor.execute("SELECT 1 FROM sys.objects WHERE type = 'P' AND name = 'sp_dashboard_mobile_Beta'")
            if cursor.fetchone():
                cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_dashboard_mobile_Beta', 'VN', 'sp_dashboard_mobile_Beta'")
                cursor.execute("EXEC dbo.sp_GenerateHTMLScript 'sp_dashboard_mobile_Beta', 'EN', 'sp_dashboard_mobile_Beta'")
            
            conn.commit()
            print(f"Caches rebuilt successfully on {db}!")
            conn.close()
        except Exception as e:
            print(f"Error on database {db}: {e}")
