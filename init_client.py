import os
import sys
import subprocess
import shutil
import json
import re

# Setup printing colors for terminal
def print_success(msg):
    print(f"\033[92m[SUCCESS] {msg}\033[0m")
def print_info(msg):
    print(f"\033[94m[INFO] {msg}\033[0m")
def print_warn(msg):
    print(f"\033[93m[WARNING] {msg}\033[0m")
def print_error(msg):
    print(f"\033[91m[ERROR] {msg}\033[0m")

def setup_client_workspace(client_name):
    # Normalize client name
    client_name = client_name.strip().replace(" ", "_")
    if not client_name:
        print_error("Tên khách hàng không hợp lệ!")
        return

    # Determine paths
    core_dir = os.path.abspath(os.path.dirname(__file__))
    parent_dir = os.path.dirname(core_dir)
    workspaces_dir = os.path.join(parent_dir, "Workspaces")
    client_dir = os.path.join(workspaces_dir, client_name)

    print_info(f"Đang thiết lập không gian làm việc cho khách hàng: {client_name}")
    print_info(f"Thư mục Core: {core_dir}")
    print_info(f"Thư mục Đích: {client_dir}")

    # Ensure Workspaces directory exists
    if not os.path.exists(workspaces_dir):
        os.makedirs(workspaces_dir)
        print_info(f"Đã tạo thư mục cha: {workspaces_dir}")

    if os.path.exists(client_dir):
        print_warn(f"Thư mục {client_dir} đã tồn tại!")
        choice = input("Bạn có muốn ghi đè cấu hình không? (y/n): ").strip().lower()
        if choice != 'y':
            print_info("Đã hủy thao tác.")
            return

    # Check if Git is initialized in core
    is_git = os.path.exists(os.path.join(core_dir, ".git"))
    
    use_worktree = False
    if is_git:
        try:
            # Check if git command works
            subprocess.run(["git", "--version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
            use_worktree = True
        except Exception:
            pass

    if use_worktree:
        print_info("Phát hiện Git. Sử dụng cơ chế 'git worktree' để cô lập...")
        branch_name = f"client-{client_name.lower().replace('_', '-')}"
        
        # Clean up existing worktree if any (safety check)
        try:
            subprocess.run(["git", "worktree", "prune"], check=True, stdout=subprocess.DEVNULL)
        except Exception:
            pass
            
        try:
            # Add git worktree
            # git worktree add <path> -b <new-branch>
            print_info(f"Đang chạy lệnh: git worktree add {client_dir} -b {branch_name}")
            subprocess.run(["git", "worktree", "add", client_dir, "-b", branch_name], check=True, cwd=core_dir)
            print_success("Đã tạo Git Worktree thành công!")
        except Exception as e:
            print_warn(f"Không thể tạo Git Worktree: {e}. Sẽ chuyển sang phương án sao chép thư mục (Fallback)...")
            use_worktree = False

    if not use_worktree:
        print_info("Đang tạo không gian làm việc bằng phương pháp sao chép thư mục (Fallback)...")
        if os.path.exists(client_dir):
            shutil.rmtree(client_dir)
        os.makedirs(client_dir)

    # Đồng bộ tài nguyên từ Core sang Client Workspace (áp dụng cho cả worktree và fallback sao chép)
    print_info("Đang đồng bộ các tệp cấu hình và mã nguồn đồ thị từ Core...")
    
    # 1. Đồng bộ các thư mục
    for folder in ["Knowledge", "Clients", "SQL script"]:
        src = os.path.join(core_dir, folder)
        dst = os.path.join(client_dir, folder)
        if os.path.exists(src):
            if not os.path.exists(dst):
                os.makedirs(dst)
            for root, dirs, files in os.walk(src):
                rel_path = os.path.relpath(root, src)
                dest_dir = dst if rel_path == "." else os.path.join(dst, rel_path)
                if not os.path.exists(dest_dir):
                    os.makedirs(dest_dir)
                for file in files:
                    # Bỏ qua các file database/cypher nặng đã sinh ra ở Core
                    if folder == "Clients" and file in ["db_graph.json", "import_graph.cypher"]:
                        continue
                    shutil.copy2(os.path.join(root, file), os.path.join(dest_dir, file))

    # 2. Đồng bộ các file cấu hình gốc
    for f in ["CLAUDE.md", "UserProfile.md", ".clinerules", ".gitignore"]:
        src = os.path.join(core_dir, f)
        dst = os.path.join(client_dir, f)
        if os.path.exists(src):
            shutil.copy2(src, dst)
            
    print_success("Đồng bộ tài nguyên hoàn tất!")

    # Prompt for database connection details to configure .mcp.json
    print("\n" + "="*50)
    print(" CẤU HÌNH KẾT NỐI DATABASE CHO KHÁCH HÀNG MỚI")
    print("="*50)
    
    db_host = input("1. Nhập SQL Server IP/Host (mặc định: 192.168.11.51): ").strip() or "192.168.11.51"
    db_port = input("2. Nhập SQL Server Port (mặc định: 2222): ").strip() or "2222"
    db_user = input("3. Nhập Database User (mặc định: vts.sa): ").strip() or "vts.sa"
    db_pass = input("4. Nhập Database Password: ").strip() or "LuaThieng1@3@2020"
    db_name = input(f"5. Nhập tên Database Khách hàng (ví dụ: Paradise_{client_name}): ").strip() or f"Paradise_{client_name}"

    # Build .mcp.json
    mcp_config = {
        "mcpServers": {
            f"Paradise_{client_name}": {
                "command": "npx",
                "args": ["-y", "@bilims/mcp-sqlserver"],
                "env": {
                    "SQLSERVER_HOST": db_host,
                    "SQLSERVER_PORT": db_port,
                    "SQLSERVER_USER": db_user,
                    "SQLSERVER_PASSWORD": db_pass,
                    "SQLSERVER_DATABASE": db_name
                }
            },
            "local-graph": {
                "command": "python",
                "args": ["Clients/mcp_graph_server.py"]
            },
            "local-debugger": {
                "command": "python",
                "args": ["Clients/mcp_db_debugger.py"]
            }
        }
    }

    # Write .mcp.json to the client directory
    mcp_path = os.path.join(client_dir, ".mcp.json")
    with open(mcp_path, "w", encoding="utf-8") as f:
        json.dump(mcp_config, f, indent=2)
    print_success(f"Đã tạo file cấu hình kết nối DB tại: {mcp_path}")

    # Create run_scan.bat utility for Windows developers
    bat_path = os.path.join(client_dir, "run_scan.bat")
    with open(bat_path, "w", encoding="utf-8") as f:
        f.write("@echo off\n")
        f.write("echo Dang quet co so du lieu va tao Codebase Graph cho khach hang...\n")
        f.write("cd Clients\n")
        f.write("python extract_db_graph.py\n")
        f.write("echo Quet hoan tat! Nhan phim bat ky de thoat.\n")
        f.write("pause > nul\n")
    print_success(f"Đã tạo phím tắt quét dữ liệu (Double-click để chạy): {bat_path}")

    # Edit conn_base in extract_db_graph.py to match this client's database
    client_extractor_path = os.path.join(client_dir, "Clients", "extract_db_graph.py")
    if os.path.exists(client_extractor_path):
        with open(client_extractor_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Replace conn_base connection string with custom parameters
        new_conn_base = f"""conn_base = (
    "DRIVER={{ODBC Driver 17 for SQL Server}};"
    "SERVER={db_host},{db_port};"
    "UID={db_user};"
    "PWD={db_pass};"
    "TrustServerCertificate=yes;"
    "DATABASE={db_name};"
)"""
        content = re.sub(r'conn_base\s*=\s*\([^)]+\)', new_conn_base, content)
        
        with open(client_extractor_path, "w", encoding="utf-8") as f:
            f.write(content)
        print_success("Đã tự động cập nhật chuỗi kết nối vào file extract_db_graph.py của dự án con.")

    print("\n" + "="*50)
    print(" HOÀN THÀNH TRIỂN KHAI WORKSPACE MỚI")
    print("="*50)
    print(f"Để làm việc trên dự án này:")
    print(f"1. Mở thư mục bằng VS Code: code \"{client_dir}\"")
    print(f"2. Chạy quét dữ liệu bằng cách nhấp đúp file: \"{bat_path}\"")
    print(f"3. Bắt đầu làm việc với AI Agent. Agent sẽ chỉ truy cập dữ liệu của khách hàng này.")
    print("="*50 + "\n")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print_error("Thiếu đối số! Cách dùng: python init_client.py [Ten_Khach_Hang]")
        sys.exit(1)
    setup_client_workspace(sys.argv[1])
