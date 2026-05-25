-- ============================================================================
-- File      : SQL script/redesign_MnuSCR010_UserRight_20260525.sql
-- Mục đích  : Thiết kế lại giao diện MnuSCR010 'Phân quyền truy cập' sang bố cục mới.
--             Sắp xếp các control căn ngang (Login, Xem, Lưu), tab ngang và bảng chứa cây phân quyền.
--             Đảm bảo chuẩn ParadiseStyle v3, responsive và hỗ trợ dark mode.
-- Tác giả   : Antigravity
-- Ngày cập nhật: 2026-05-25
-- Cảnh báo  : USER tự review và CHẠY trên database Paradise_Dev.
-- ============================================================================

SET NOCOUNT ON;
GO

PRINT N'BẮT ĐẦU CẬP NHẬT GIAO DIỆN PHÂN QUYỀN TRUY CẬP...';
GO

-- ============================================================================
-- PHASE 1: Tạo thủ tục Wrapper UserRight và Renderer UserRight_html
-- ============================================================================
PRINT N'1. Đang tạo các thủ tục wrapper & renderer...';
GO

-- 1.1: Thủ tục Wrapper - Được gọi bởi Web Portal khi click menu MnuSCR010
CREATE OR ALTER PROCEDURE [dbo].[UserRight]
(
    @LoginID    INT = NULL,
    @LanguageID VARCHAR(5) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy mã HTML từ cache theo khóa 'UserRight'
    SELECT html FROM tblHtmlScriptCache
    WHERE TableName  = 'UserRight'
      AND LanguageID = @LanguageID;

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC UserRight_html @LanguageID = @LanguageID;
    END
END
GO

PRINT N'  [OK] Đã tạo wrapper UserRight.';
GO

-- 1.2: Thủ tục Renderer - Sinh mã HTML/CSS/JS cho trang Phân quyền truy cập
CREATE OR ALTER PROCEDURE [dbo].[UserRight_html]
(
    @LanguageID VARCHAR(5) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @html NVARCHAR(MAX) = N'';

    SET @html = N'
<div id="scr010Root" class="scr010-page">
    <style>
        #scr010Root {
            font-family: var(--paradise-font-family-base);
            color: var(--paradise-text-body);
            padding: var(--paradise-space-5);
            box-sizing: border-box;
        }
        #scr010Root .scr010-shell {
            display: flex;
            flex-direction: column;
            gap: var(--paradise-space-4);
        }
        
        /* Hàng 1: Control Bar chứa Tên đăng nhập và các nút Xem, Lưu */
        #scr010Root .scr010-control-bar {
            display: flex;
            align-items: flex-end;
            gap: var(--paradise-space-4);
            background-color: var(--paradise-card-bg);
            border: var(--paradise-card-border);
            border-radius: var(--paradise-card-radius);
            padding: var(--paradise-card-padding);
            box-shadow: var(--paradise-card-shadow);
            flex-wrap: wrap;
        }
        #scr010Root .scr010-field {
            display: flex;
            flex-direction: column;
            gap: var(--paradise-space-2);
            flex: 1;
            min-width: 280px;
            max-width: 480px;
        }
        #scr010Root .scr010-label {
            font-weight: 600;
            font-size: .9rem;
            color: var(--paradise-text-body);
        }
        #scr010Root .scr010-input-wrapper {
            position: relative;
            display: flex;
            align-items: center;
            width: 100%;
        }
        #scr010Root .scr010-input-icon {
            position: absolute;
            left: var(--paradise-space-3);
            color: var(--paradise-text-muted);
            font-size: 1.1rem;
            pointer-events: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }
        #scr010Root .scr010-input {
            padding-left: 2.5rem;
            width: 100%;
            height: 42px;
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-input-border-radius);
            color: var(--paradise-text-body);
            background-color: var(--paradise-bg-surface);
            outline: none;
            box-sizing: border-box;
            font-size: var(--paradise-font-body1);
            transition: var(--paradise-transition-fast);
        }
        #scr010Root .scr010-input:focus {
            border-color: var(--paradise-color-input-border-hover);
            box-shadow: 0 0 0 2px var(--paradise-bg-primary-subtle);
        }
        #scr010Root .scr010-actions {
            display: flex;
            gap: var(--paradise-space-2);
            margin-bottom: 2px;
        }
        #scr010Root .scr010-actions button {
            min-width: 100px;
            height: 42px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: var(--paradise-space-2);
            font-weight: 600;
            white-space: nowrap;
        }
        
        /* Hàng 2: Tabs Bar */
        #scr010Root .scr010-tabs-nav {
            display: flex;
            gap: var(--paradise-space-2);
            border-bottom: 1px solid var(--paradise-border-color);
            padding-bottom: 0;
            margin-top: var(--paradise-space-2);
        }
        #scr010Root .scr010-tab {
            background: transparent;
            border: 1px solid transparent;
            border-bottom: none;
            padding: var(--paradise-space-3) var(--paradise-space-5);
            font-weight: 600;
            color: var(--paradise-text-muted);
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: var(--paradise-space-2);
            position: relative;
            transition: all var(--paradise-transition-fast);
            border-radius: var(--paradise-border-radius-lg) var(--paradise-border-radius-lg) 0 0;
            font-size: var(--paradise-font-body1, 0.95rem);
            margin-bottom: -1px;
        }
        #scr010Root .scr010-tab:hover {
            color: var(--paradise-color-primary);
            background-color: var(--paradise-bg-primary-subtle);
        }
        #scr010Root .scr010-tab.is-active {
            color: var(--paradise-color-primary);
            background-color: var(--paradise-card-bg);
            border-color: var(--paradise-border-color);
            border-bottom: 2px solid var(--paradise-color-primary);
        }
        
        /* Hàng 3: Main Content Panel */
        #scr010Root .scr010-panel {
            background-color: var(--paradise-card-bg);
            border: var(--paradise-card-border);
            border-radius: var(--paradise-card-radius);
            padding: var(--paradise-card-padding);
            box-shadow: var(--paradise-card-shadow);
            min-height: calc(100vh - 280px);
            display: flex;
            flex-direction: column;
            gap: var(--paradise-space-4);
            box-sizing: border-box;
        }
        #scr010Root .scr010-panel-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: var(--paradise-space-4);
            flex-wrap: wrap;
            border-bottom: 1px solid var(--paradise-border-color);
            padding-bottom: var(--paradise-space-4);
        }
        #scr010Root .scr010-title {
            display: flex;
            gap: var(--paradise-space-3);
            align-items: center;
        }
        #scr010Root .scr010-title-icon {
            width: 44px;
            height: 44px;
            border-radius: var(--paradise-border-radius-xl);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            color: var(--paradise-color-primary);
            background-color: var(--paradise-bg-primary-subtle);
            border: 1px solid var(--paradise-border-color);
            box-shadow: var(--paradise-shadow-sm);
            font-size: 1.25rem;
        }
        #scr010Root .scr010-panel h2 {
            font-size: 1.25rem;
            margin: 0;
            font-weight: 700;
            color: var(--paradise-text-heading, var(--paradise-text-body));
        }
        #scr010Root .scr010-muted {
            color: var(--paradise-text-muted);
            font-size: .85rem;
            margin-top: 2px;
        }
        
        /* Stats Thống kê */
        #scr010Root .scr010-stats {
            display: flex;
            gap: var(--paradise-space-3);
            flex-wrap: wrap;
        }
        #scr010Root .scr010-stat {
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-lg);
            padding: var(--paradise-space-2) var(--paradise-space-4);
            background-color: var(--paradise-bg-surface);
            display: flex;
            flex-direction: column;
            align-items: center;
            min-width: 110px;
            box-sizing: border-box;
        }
        #scr010Root .scr010-stat-label {
            font-size: 0.75rem;
            color: var(--paradise-text-muted);
            text-transform: uppercase;
            font-weight: 600;
            letter-spacing: 0.5px;
        }
        #scr010Root .scr010-stat-val {
            font-size: 1.2rem;
            color: var(--paradise-color-primary);
            font-weight: 700;
            margin-top: 2px;
        }
        
        /* Toolbar & Tìm kiếm */
        #scr010Root .scr010-toolbar {
            display: flex;
            width: 100%;
        }
        #scr010Root .scr010-search-wrapper {
            position: relative;
            display: flex;
            align-items: center;
            width: 100%;
        }
        #scr010Root .scr010-search-icon {
            position: absolute;
            left: var(--paradise-space-3);
            color: var(--paradise-text-muted);
            pointer-events: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }
        #scr010Root .scr010-search {
            width: 100%;
            height: 42px;
            padding-left: 2.5rem;
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-input-border-radius);
            color: var(--paradise-text-body);
            background-color: var(--paradise-bg-surface);
            outline: none;
            box-sizing: border-box;
            font-size: var(--paradise-font-body1);
            transition: var(--paradise-transition-fast);
        }
        #scr010Root .scr010-search:focus {
            border-color: var(--paradise-color-input-border-hover);
            box-shadow: 0 0 0 2px var(--paradise-bg-primary-subtle);
        }
        
        /* Cây phân quyền */
        #scr010Root .scr010-tree {
            flex: 1;
            max-height: calc(100vh - 380px);
            overflow-y: auto;
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-lg);
            padding: var(--paradise-space-3);
            background-color: var(--paradise-bg-surface);
        }
        #scr010Root .scr010-node {
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-lg);
            margin-bottom: var(--paradise-space-2);
            padding: var(--paradise-space-2) var(--paradise-space-3);
            background-color: var(--paradise-card-bg);
            transition: all var(--paradise-transition-fast);
        }
        #scr010Root .scr010-node:hover {
            border-color: var(--paradise-color-primary);
            box-shadow: var(--paradise-shadow-sm);
        }
        #scr010Root .scr010-node-row {
            display: flex;
            align-items: center;
            gap: var(--paradise-space-3);
        }
        #scr010Root .scr010-toggle {
            border: 0;
            background: transparent;
            color: var(--paradise-text-muted);
            cursor: pointer;
            width: 28px;
            height: 28px;
            border-radius: var(--paradise-border-radius-pill);
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 14px;
            transition: all var(--paradise-transition-fast);
        }
        #scr010Root .scr010-toggle:hover {
            color: var(--paradise-color-primary);
            background-color: var(--paradise-bg-primary-subtle);
        }
        #scr010Root .scr010-name {
            font-weight: 600;
            line-height: 1.35;
            font-size: var(--paradise-font-body1);
            flex: 1;
            color: var(--paradise-text-body);
        }
        #scr010Root .scr010-children {
            margin-top: var(--paradise-space-2);
            padding-left: var(--paradise-space-4);
            display: none;
            border-left: 1px dashed var(--paradise-border-color);
        }
        #scr010Root .scr010-node.is-open > .scr010-children {
            display: block;
        }
        #scr010Root .scr010-check {
            display: inline-flex;
            align-items: center;
            gap: var(--paradise-space-2);
            cursor: pointer;
            font-weight: 600;
            font-size: var(--paradise-font-body2);
            padding: var(--paradise-space-1) var(--paradise-space-3);
            border-radius: var(--paradise-border-radius-md);
            transition: background var(--paradise-transition-fast);
            color: var(--paradise-text-body);
        }
        #scr010Root .scr010-check:hover {
            background-color: var(--paradise-bg-primary-subtle);
        }
        #scr010Root .scr010-check input[type=checkbox] {
            width: 16px;
            height: 16px;
            accent-color: var(--paradise-color-primary);
            cursor: pointer;
        }
        #scr010Root .scr010-select {
            min-width: 160px;
            max-width: 240px;
            height: 36px;
            padding: 0 var(--paradise-space-2);
            border-radius: var(--paradise-input-border-radius);
            border: 1px solid var(--paradise-border-color);
            background-color: var(--paradise-bg-surface);
            color: var(--paradise-text-body);
            font-size: var(--paradise-font-body2);
            outline: none;
            cursor: pointer;
            transition: border var(--paradise-transition-fast);
        }
        #scr010Root .scr010-select:focus {
            border-color: var(--paradise-color-primary);
            box-shadow: 0 0 0 2px var(--paradise-bg-primary-subtle);
        }
        #scr010Root .scr010-empty {
            border: 1px dashed var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-lg);
            padding: var(--paradise-space-6);
            text-align: center;
            color: var(--paradise-text-muted);
            font-size: var(--paradise-font-body1);
        }
        #scr010Root .scr010-hidden {
            display: none !important;
        }
        
        /* Reponsive cho các thiết bị nhỏ hơn */
        @media (max-width: 920px) {
            #scr010Root .scr010-control-bar {
                flex-direction: column;
                align-items: stretch;
            }
            #scr010Root .scr010-field {
                max-width: none;
            }
            #scr010Root .scr010-actions {
                justify-content: flex-end;
            }
            #scr010Root .scr010-panel-header {
                flex-direction: column;
                align-items: flex-start;
            }
            #scr010Root .scr010-stats {
                width: 100%;
                justify-content: space-between;
            }
            #scr010Root .scr010-stat {
                flex: 1;
                min-width: 80px;
            }
            #scr010Root .scr010-node-row {
                flex-direction: column;
                align-items: stretch;
                gap: var(--paradise-space-2);
            }
            #scr010Root .scr010-select {
                max-width: none;
                width: 100%;
            }
        }
    </style>

    <div class="scr010-shell">
        <!-- Hàng 1: Control Bar (Tên/nhóm đăng nhập, Xem, Lưu) -->
        <div class="scr010-control-bar">
            <div class="scr010-field">
                <label class="scr010-label" for="scr010Login"></label>
                <div class="scr010-input-wrapper">
                    <i class="bi bi-person-circle scr010-input-icon"></i>
                    <input id="scr010Login" class="scr010-input" autocomplete="off" />
                </div>
            </div>
            <div class="scr010-actions">
                <button type="button" id="scr010Reload" class="paradise-btn paradise-btn--reload">
                    <i class="bi bi-search"></i><span></span>
                </button>
                <button type="button" id="scr010Save" class="paradise-btn paradise-btn--save">
                    <i class="bi bi-check-circle"></i><span></span>
                </button>
            </div>
        </div>

        <!-- Hàng 2: Tabs Bar (Chức năng, Dữ liệu) -->
        <div class="scr010-tabs-nav">
            <button type="button" class="scr010-tab" data-mode="0">
                <i class="bi bi-shield-check"></i><span></span>
            </button>
            <button type="button" class="scr010-tab" data-mode="1">
                <i class="bi bi-database-fill-gear"></i><span></span>
            </button>
        </div>

        <!-- Hàng 3: Main Content Panel -->
        <main class="scr010-panel">
            <div class="scr010-panel-header">
                <div class="scr010-title">
                    <span class="scr010-title-icon"><i class="bi bi-shield-lock-fill"></i></span>
                    <div>
                        <h2 id="scr010Title"></h2>
                        <div class="scr010-muted" id="scr010Subtitle"></div>
                    </div>
                </div>
                
                <div class="scr010-stats">
                    <div class="scr010-stat">
                        <span class="scr010-stat-label"></span>
                        <strong id="scr010Total" class="scr010-stat-val">0</strong>
                    </div>
                    <div class="scr010-stat">
                        <span class="scr010-stat-label"></span>
                        <strong id="scr010Selected" class="scr010-stat-val">0</strong>
                    </div>
                    <div class="scr010-stat">
                        <span class="scr010-stat-label"></span>
                        <strong id="scr010ModeLabel" class="scr010-stat-val"></strong>
                    </div>
                </div>
            </div>
            
            <div class="scr010-toolbar">
                <div class="scr010-search-wrapper">
                    <i class="bi bi-search scr010-search-icon"></i>
                    <input id="scr010Search" class="scr010-search" />
                </div>
            </div>
            
            <div id="scr010Tree" class="scr010-tree">
                <div class="scr010-empty" id="scr010Empty"></div>
            </div>
        </main>
    </div>
</div>

<script>
(() => {
    const lang = window.LanguageID || "VN";
    const LOGIN_ID = window.UserID || 3;
    
    const labels = {
        VN: {
            title: "Phân quyền truy cập",
            subtitle: "Tìm tài khoản, chọn nhóm quyền hoặc phạm vi dữ liệu, sau đó lưu thay đổi.",
            account: "Tên/nhóm đăng nhập",
            menu: "Chức năng",
            emp: "Dữ liệu",
            reload: "Xem",
            save: "Lưu",
            search: "Tìm nhanh quyền, menu, phòng ban...",
            empty: "Nhập tên truy cập rồi bấm Xem.",
            invalid: "Không tìm thấy tên truy cập / tên nhóm.",
            confirm: "Xác nhận lưu thay đổi?",
            saved: "Đã lưu thay đổi.",
            loading: "Đang tải dữ liệu...",
            items: "Mục lục",
            selected: "Đang phân quyền",
            mode: "Chế độ xem",
            denied: "Từ chối",
            read: "Xem",
            followGroup: "Theo nhóm",
            full: "Toàn quyền",
            view: "Xem"
        },
        EN: {
            title: "Grant Access Right",
            subtitle: "Find an account, choose feature permissions or data scope, then save changes.",
            account: "Login name / group name",
            menu: "Features",
            emp: "Data",
            reload: "View",
            save: "Save",
            search: "Search permissions, menus, departments...",
            empty: "Enter login name, then click View.",
            invalid: "Login name / group name was not found.",
            confirm: "Confirm saving changes?",
            saved: "Changes saved.",
            loading: "Loading...",
            items: "Items",
            selected: "Selected",
            mode: "Mode",
            denied: "Denied",
            read: "Read",
            followGroup: "Follow group",
            full: "Full",
            view: "View"
        }
    };
    
    const curLabels = labels[lang] || labels.VN;
    let mode = 0; // 0: Menu, 1: Employee data scope
    let state = { rows: [], tree: [] };
    
    const byId = (id) => document.getElementById(id);
    const escapeHtml = (v) => {
        if (v === null || v === undefined) return "";
        return String(v)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/\u0027/g, "&#039;");
    };
    
    const normalize = (v) => {
        return String(v || "")
            .normalize("NFD")
            .replace(/[\u0300-\u036f]/g, "")
            .toLowerCase();
    };
    
    const paramName = () => mode === 1 ? "Json_update_Emp" : "Json_update";
    const apiName = () => mode === 1 ? "sp_decentralization_EmpData" : "sp_decentralization_MenuData";
    const getLogin = () => byId("scr010Login").value.trim();
    
    function initLabels() {
        byId("scr010Title").textContent = curLabels.title;
        byId("scr010Subtitle").textContent = curLabels.subtitle;
        document.querySelector("label[for=scr010Login]").textContent = curLabels.account;
        document.querySelectorAll(".scr010-tab")[0].querySelector("span").textContent = curLabels.menu;
        document.querySelectorAll(".scr010-tab")[1].querySelector("span").textContent = curLabels.emp;
        byId("scr010Reload").querySelector("span").textContent = curLabels.reload;
        byId("scr010Save").querySelector("span").textContent = curLabels.save;
        byId("scr010Search").placeholder = curLabels.search;
        byId("scr010Empty").textContent = curLabels.empty;
        
        document.querySelectorAll(".scr010-stat")[0].querySelector(".scr010-stat-label").textContent = curLabels.items;
        document.querySelectorAll(".scr010-stat")[1].querySelector(".scr010-stat-label").textContent = curLabels.selected;
        document.querySelectorAll(".scr010-stat")[2].querySelector(".scr010-stat-label").textContent = curLabels.mode;
        
        // Nhận tham số URL nếu có
        const getUrlParameter = (name) => {
            name = name.replace(/[\[]/, "\\\\[").replace(/[\]]/, "\\\\]");
            const regex = new RegExp("[\\?&]" + name + "=([^&#]*)", "i");
            const results = regex.exec(location.search);
            return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
        };
        const loginAccountParam = getUrlParameter("LoginAccount") || getUrlParameter("loginaccount");
        if (loginAccountParam) {
            byId("scr010Login").value = loginAccountParam;
        }
        
        setMode(0, false);
    }
    
    function setMode(nextMode, load) {
        mode = Number(nextMode) === 1 ? 1 : 0;
        document.querySelectorAll(".scr010-tab").forEach((btn) => {
            btn.classList.toggle("is-active", Number(btn.dataset.mode) === mode);
        });
        byId("scr010ModeLabel").textContent = mode === 1 ? curLabels.emp : curLabels.menu;
        if (load) loadData();
    }
    
    function buildTree(rows) {
        let map = {};
        let roots = [];
        rows.forEach((r) => {
            let id = String(r.ObjectID);
            r._id = id;
            r._children = [];
            map[id] = r;
        });
        rows.forEach((r) => {
            let pid = mode === 1 ? String(r.ParentObjectID || "") : String(r.ParentObjectID || r.ObjectID);
            if (pid && pid !== r._id && map[pid]) {
                map[pid]._children.push(r);
            } else {
                roots.push(r);
            }
        });
        roots.sort(sortNode);
        rows.forEach((r) => {
            r._children.sort(sortNode);
        });
        return roots;
    }
    
    function sortNode(a, b) {
        return (Number(a.Prio || 0) - Number(b.Prio || 0)) || 
               String(a.Description || "").localeCompare(String(b.Description || ""));
    }
    
    function render() {
        const tree = byId("scr010Tree");
        byId("scr010Total").textContent = state.rows.length;
        if (!state.rows.length) {
            tree.innerHTML = "<div class=\"scr010-empty\">" + curLabels.empty + "</div>";
            updateSelected();
            return;
        }
        tree.innerHTML = state.tree.map(renderNode).join("");
        updateSelected();
    }
    
    function renderNode(n) {
        var hasChild = n._children && n._children.length;
        var name = escapeHtml(n.Description || n.ObjectName || n.ObjectID);
        var control = mode === 1 ? renderCheckbox(n) : renderSelect(n);
        return "<div class=\"scr010-node" + (hasChild ? " is-open" : "") + "\" data-text=\"" + escapeHtml(normalize(name)) + "\" data-id=\"" + escapeHtml(n._id) + "\">"
            + "<div class=\"scr010-node-row\">"
            + "<button type=\"button\" class=\"scr010-toggle\">" + (hasChild ? "<i class=\"bi bi-chevron-down\"></i>" : "") + "</button>"
            + "<div class=\"scr010-name\">" + name + "</div>"
            + control + "</div>"
            + (hasChild ? "<div class=\"scr010-children\">" + n._children.map(renderNode).join("") + "</div>" : "")
            + "</div>";
    }
    
    function renderSelect(n) {
        const rights = String(n.FullAccess || "").split("&");
        const opts = [
            { id: "0", name: curLabels.denied },
            { id: "1", name: curLabels.read },
            { id: "8", name: curLabels.followGroup },
            { id: "32", name: curLabels.full }
        ];
        return "<select class=\"scr010-select\" id=\"select_access_" + escapeHtml(n.ObjectID) + "\">" 
            + opts.map(o => "<option value=\"" + o.id + "\"" + (rights.indexOf(o.id) >= 0 ? " selected" : "") + ">" + o.name + "</option>").join("")
            + "</select>";
    }
    
    function renderCheckbox(n) {
        return "<label class=\"scr010-check\"><input type=\"checkbox\" id=\"IsFull_" + escapeHtml(n.ObjectID) + "\" " + (Number(n.ViewInfo) === 1 ? "checked" : "") + "> <span>" + curLabels.view + "</span></label>";
    }
    
    function loadData() {
        const login = getLogin();
        if (!login) {
            state.rows = [];
            state.tree = [];
            render();
            return;
        }
        byId("scr010Tree").innerHTML = "<div class=\"scr010-empty\"><i class=\"bi bi-hourglass-split me-1\"></i>" + curLabels.loading + "</div>";
        
        if (typeof AjaxHPAParadise === "function") {
            AjaxHPAParadise({
                data: {
                    name: apiName(),
                    param: ["LoginID", LOGIN_ID, "LanguageID", lang, "LoginAccount", login]
                },
                success: (res) => {
                    const json = typeof res === "string" ? JSON.parse(res) : res;
                    const row = json && json.data && json.data[0] && json.data[0][0];
                    if (!row || !row.IsValid) {
                        state.rows = [];
                        state.tree = [];
                        byId("scr010Tree").innerHTML = "<div class=\"scr010-empty\">" + curLabels.invalid + "</div>";
                        updateSelected();
                        return;
                    }
                    state.rows = row.JsonData ? JSON.parse(row.JsonData) : [];
                    state.tree = buildTree(state.rows);
                    render();
                }
            });
        }
    }
    
    function saveData() {
        const login = getLogin();
        if (!login) return;
        if (!window.confirm(curLabels.confirm)) return;
        
        const payload = {};
        if (mode === 1) {
            document.querySelectorAll("input[type=checkbox][id^=IsFull_]").forEach((el) => {
                payload[el.id] = el.checked ? 1 : 0;
            });
        } else {
            document.querySelectorAll("select[id^=select_access_]").forEach((el) => {
                payload[el.id] = el.value;
            });
        }
        
        if (typeof AjaxHPAParadise === "function") {
            AjaxHPAParadise({
                data: {
                    name: "sp_decentralization_update",
                    param: ["LoginID", LOGIN_ID, "LoginAccount", login, paramName(), JSON.stringify(payload)]
                },
                success: () => {
                    alert(curLabels.saved);
                    loadData();
                }
            });
        }
    }
    
    function updateSelected() {
        let count = 0;
        if (mode === 1) {
            count = document.querySelectorAll("input[type=checkbox][id^=IsFull_]:checked").length;
        } else {
            document.querySelectorAll("select[id^=select_access_]").forEach((el) => {
                if (el.value !== "0") count++;
            });
        }
        byId("scr010Selected").textContent = count;
    }
    
    function filterTree() {
        const q = normalize(byId("scr010Search").value);
        document.querySelectorAll(".scr010-node").forEach((n) => {
            const match = !q || n.dataset.text.indexOf(q) >= 0 || 
                           Array.from(n.querySelectorAll(".scr010-node")).some(c => c.dataset.text.indexOf(q) >= 0);
            n.classList.toggle("scr010-hidden", !match);
            if (q && match) n.classList.add("is-open");
        });
    }
    
    // Đăng ký sự kiện
    byId("scr010Root").addEventListener("click", (e) => {
        const tab = e.target.closest(".scr010-tab");
        if (tab) {
            setMode(tab.dataset.mode, true);
            return;
        }
        if (e.target.closest("#scr010Reload")) {
            loadData();
            return;
        }
        if (e.target.closest("#scr010Save")) {
            saveData();
            return;
        }
        const toggle = e.target.closest(".scr010-toggle");
        if (toggle) {
            const node = toggle.closest(".scr010-node");
            if (node) node.classList.toggle("is-open");
        }
    });
    
    byId("scr010Root").addEventListener("change", updateSelected);
    byId("scr010Search").addEventListener("input", filterTree);
    byId("scr010Login").addEventListener("keydown", (e) => {
        if (e.key === "Enter") loadData();
    });
    
    initLabels();
    if (getLogin()) loadData();
    
    if (typeof HideLoadingByClassOrID === "function") {
        HideLoadingByClassOrID("#UserRight");
    }
})();
</script>
';

    SELECT @html AS html;
END
GO

PRINT N'  [OK] Đã tạo renderer UserRight_html.';
GO

-- ============================================================================
-- PHASE 2: Cấu hình lại MEN_Menu cho MnuSCR010 theo chuẩn Cách 2 (Pure HTML)
-- ============================================================================
PRINT N'2. Đang cập nhật MEN_Menu cho MnuSCR010...';
GO

UPDATE MEN_Menu
SET
    ClassName            = N'UserRight',
    AssemblyName         = N'DataSetting',
    IsWeb                = 1,
    ViewOnWeb            = 0,
    isShowLayOutWeb      = 1,
    IsUseMobileDevice    = 0,
    isShowInMobileLayOut = 0,
    glyphicon            = N'shield-lock',
    GroupID              = N'MnuSCR0000',
    IsNotAjax            = 0,
    showDialog           = 0,
    Colors               = N'',
    LargeTile            = 0,
    SupperAdmin          = 0,
    IsModal              = 0,
    IsCollapsed          = 0,
    IsLeftMenu           = 0,
    IsHiddenInTree       = 0,
    Notification         = 0
WHERE MenuID = 'MnuSCR010';

PRINT N'  [OK] Đã cấu hình MEN_Menu cho MnuSCR010.';
GO

-- ============================================================================
-- PHASE 3: Cập nhật ObjectName trong tblSC_Object cho MnuSCR010
-- ============================================================================
PRINT N'3. Đang cập nhật tblSC_Object cho MnuSCR010...';
GO

UPDATE tblSC_Object
SET ObjectName = N'DataSetting.UserRight'
WHERE Description = 'MnuSCR010';

PRINT N'  [OK] Đã cập nhật ObjectName thành DataSetting.UserRight.';
GO

-- ============================================================================
-- PHASE 4: Đảm bảo bản ghi đa ngôn ngữ tên menu trong tblMD_Message (Idempotent)
-- ============================================================================
PRINT N'4. Đang kiểm tra tên menu đa ngôn ngữ (tblMD_Message)...';
GO

IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'MnuSCR010' AND Language = 'VN')
    INSERT INTO tblMD_Message (MessageID, Language, Content)
    VALUES ('MnuSCR010', 'VN', N'Phân quyền truy cập');
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'MnuSCR010' AND Language = 'EN')
    INSERT INTO tblMD_Message (MessageID, Language, Content)
    VALUES ('MnuSCR010', 'EN', N'Grant Access Right');
GO

PRINT N'  [OK] Đã đảm bảo tên menu trong tblMD_Message.';
GO

-- ============================================================================
-- PHASE 5: Dọn dẹp cấu hình cũ trong tblDataSetting và tblDataSettingLayout (nếu có)
-- ============================================================================
PRINT N'5. Đang dọn dẹp cấu hình tblDataSetting & tblDataSettingLayout cũ...';
GO

DELETE FROM tblDataSetting WHERE TableName = 'UserRight';
DELETE FROM tblDataSettingLayout WHERE TableName = 'UserRight';
GO

PRINT N'  [OK] Đã dọn dẹp cấu hình cũ.';
GO

-- ============================================================================
-- PHASE 6: Rebuild HTML Cache cho UserRight
-- ============================================================================
PRINT N'6. Đang build cache HTML cho UserRight...';
GO

DELETE FROM tblHtmlScriptCache WHERE TableName = 'UserRight';
GO

EXEC dbo.sp_GenerateHTMLScript 'UserRight_html', 'VN', 'UserRight';
EXEC dbo.sp_GenerateHTMLScript 'UserRight_html', 'EN', 'UserRight';
GO

PRINT N'  [OK] Đã build cache HTML.';
GO

-- ============================================================================
-- PHASE 7: Làm mới menu cache phía client
-- ============================================================================
PRINT N'7. Đang làm mới cache hệ thống...';
GO

EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'UserRight';
GO

PRINT N'CẬP NHẬT GIAO DIỆN PHÂN QUYỀN TRUY CẬP THÀNH CÔNG!';
GO
