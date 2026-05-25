-- ============================================================================
-- File      : SQL script/redesign_MnuSCR699_decentralization_control_20260525.sql
-- Mục đích  : Chuyển đổi dropdown phân quyền (scr699-select) sang dạng config control
--             lưu trữ trong tblCommonControlType_Signed (sử dụng DevExpress TagBox).
--             Đảm bảo chuẩn select listbox của ParadiseHR, đồng bộ và hiển thị nhãn đẹp mắt.
-- Tác giả   : Antigravity
-- Ngày cập nhật: 2026-05-25
-- Cảnh báo  : USER tự review và CHẠY trên database Paradise_Dev.
-- ============================================================================

SET NOCOUNT ON;
GO

PRINT N'BẮT ĐẦU CẤU HÌNH CONFIG CONTROL CHO PHÂN QUYỀN TRUY CẬP (MnuSCR699)...';
GO

-- ============================================================================
-- 1) Tạo stored procedure DataSource sp_decentralization_SelectOptions
-- ============================================================================
PRINT N'1. Tạo sp_decentralization_SelectOptions...';
GO

CREATE OR ALTER PROCEDURE dbo.sp_decentralization_SelectOptions
(
    @LoginID INT = 3,
    @LanguageID CHAR(2) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @isVN BIT = CASE WHEN LOWER(ISNULL(@LanguageID, 'VN')) = 'vn' THEN 1 ELSE 0 END;
    
    SELECT '0' AS ID, IIF(@isVN = 1, N'Từ chối', N'Denied') AS Name
    UNION ALL
    SELECT '1' AS ID, IIF(@isVN = 1, N'Xem', N'Read') AS Name
    UNION ALL
    SELECT '8' AS ID, IIF(@isVN = 1, N'Theo nhóm', N'Follow group') AS Name
    UNION ALL
    SELECT '32' AS ID, IIF(@isVN = 1, N'Toàn quyền', N'Full') AS Name;
END
GO

PRINT N'  [OK] Đã tạo sp_decentralization_SelectOptions.';
GO

-- ============================================================================
-- 2) Đăng ký control scr699Select trong tblCommonControlType_Signed
-- ============================================================================
PRINT N'2. Đăng ký control scr699Select trong tblCommonControlType_Signed...';
GO

DELETE FROM tblCommonControlType_Signed 
WHERE TableName = 'sp_decentralization' AND ColumnName = 'scr699Select';

INSERT INTO tblCommonControlType_Signed (
    TableName, ColumnName, Type, DataSourceSP, ColumnIDName, DisplayName, UID
)
VALUES (
    'sp_decentralization', 
    'scr699Select', 
    'hpaControlSelectBox', 
    'sp_decentralization_SelectOptions', 
    'ID', 
    N'Quyền truy cập', 
    'P699SELECT0000000000000000000000'
);
GO

PRINT N'  [OK] Đã đăng ký control scr699Select.';
GO

-- ============================================================================
-- 3) Thực thi DUC để sinh mã load dữ liệu
-- ============================================================================
PRINT N'3. Thực thi DUC (sptblCommonControlType_Signed_DUC)...';
GO

EXEC dbo.sptblCommonControlType_Signed_DUC @TableName = 'sp_decentralization';
GO

PRINT N'  [OK] Đã hoàn thành thực thi DUC.';
GO

-- ============================================================================
-- 4) Cập nhật stored procedure sp_decentralization
-- ============================================================================
PRINT N'4. Thiết kế lại sp_decentralization tích hợp Config Control...';
GO

CREATE OR ALTER PROCEDURE dbo.sp_decentralization
(
    @LoginID INT = 3,
    @LanguageID CHAR(2) = 'VN',
    @IsWeb INT = NULL,
    @LoginAccount VARCHAR(100) = NULL,
    @IsAcessEmp BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @isVN BIT = CASE WHEN LOWER(ISNULL(@LanguageID, 'VN')) = 'vn' THEN 1 ELSE 0 END;
    DECLARE @title NVARCHAR(200) = IIF(@isVN = 1, N'Phân quyền truy cập', N'Grant Access Right');
    DECLARE @subtitle NVARCHAR(300) = IIF(@isVN = 1, N'Tìm tài khoản, chọn nhóm quyền hoặc phạm vi dữ liệu, sau đó lưu thay đổi.', N'Find an account, choose feature permissions or data scope, then save changes.');
    DECLARE @accountLabel NVARCHAR(200) = IIF(@isVN = 1, N'Tên/nhóm đăng nhập', N'Login name / group name');
    DECLARE @menuTab NVARCHAR(100) = IIF(@isVN = 1, N'Chức năng', N'Features');
    DECLARE @empTab NVARCHAR(100) = IIF(@isVN = 1, N'Dữ liệu', N'Data');
    DECLARE @reload NVARCHAR(80) = IIF(@isVN = 1, N'Xem', N'View');
    DECLARE @save NVARCHAR(80) = IIF(@isVN = 1, N'Lưu', N'Save');
    DECLARE @search NVARCHAR(120) = IIF(@isVN = 1, N'Tìm nhanh quyền, menu, phòng ban...', N'Search permissions, menus, departments...');
    DECLARE @empty NVARCHAR(200) = IIF(@isVN = 1, N'Nhập tên truy cập rồi bấm Xem.', N'Enter login name, then click View.');
    DECLARE @invalid NVARCHAR(200) = IIF(@isVN = 1, N'Không tìm thấy tên truy cập / tên nhóm.', N'Login name / group name was not found.');
    DECLARE @confirm NVARCHAR(200) = IIF(@isVN = 1, N'Xác nhận lưu thay đổi?', N'Confirm saving changes?');
    DECLARE @saved NVARCHAR(200) = IIF(@isVN = 1, N'Đã lưu thay đổi.', N'Changes saved.');

    -- Các nhãn thống kê đa ngôn ngữ
    DECLARE @itemsLabel NVARCHAR(100) = IIF(@isVN = 1, N'Mục lục', N'Items');
    DECLARE @selectedLabel NVARCHAR(100) = IIF(@isVN = 1, N'Đang phân quyền', N'Selected');
    DECLARE @modeLabel NVARCHAR(100) = IIF(@isVN = 1, N'Chế độ xem', N'Mode');

    DECLARE @titleJs NVARCHAR(400) = REPLACE(REPLACE(@title, N'\', N'\\'), N'"', N'\"');
    DECLARE @subtitleJs NVARCHAR(600) = REPLACE(REPLACE(@subtitle, N'\', N'\\'), N'"', N'\"');
    DECLARE @accountLabelJs NVARCHAR(400) = REPLACE(REPLACE(@accountLabel, N'\', N'\\'), N'"', N'\"');
    DECLARE @menuTabJs NVARCHAR(200) = REPLACE(REPLACE(@menuTab, N'\', N'\\'), N'"', N'\"');
    DECLARE @empTabJs NVARCHAR(200) = REPLACE(REPLACE(@empTab, N'\', N'\\'), N'"', N'\"');
    DECLARE @reloadJs NVARCHAR(200) = REPLACE(REPLACE(@reload, N'\', N'\\'), N'"', N'\"');
    DECLARE @saveJs NVARCHAR(200) = REPLACE(REPLACE(@save, N'\', N'\\'), N'"', N'\"');
    DECLARE @searchJs NVARCHAR(300) = REPLACE(REPLACE(@search, N'\', N'\\'), N'"', N'\"');
    DECLARE @emptyJs NVARCHAR(400) = REPLACE(REPLACE(@empty, N'\', N'\\'), N'"', N'\"');
    DECLARE @invalidJs NVARCHAR(400) = REPLACE(REPLACE(@invalid, N'\', N'\\'), N'"', N'\"');
    DECLARE @confirmJs NVARCHAR(400) = REPLACE(REPLACE(@confirm, N'\', N'\\'), N'"', N'\"');
    DECLARE @savedJs NVARCHAR(400) = REPLACE(REPLACE(@saved, N'\', N'\\'), N'"', N'\"');
    DECLARE @loginAccountJs NVARCHAR(300) = REPLACE(REPLACE(ISNULL(@LoginAccount, ''), N'\', N'\\\\'), N'"', N'\"');

    -- Không cần tải loadData từ database vì chúng ta tự tải datasource an toàn qua API nếu bị thiếu

    SELECT N'
<div id="scr699Root" class="scr699-page">
    <style>
        #scr699Root {
            font-family: var(--paradise-font-family-base);
            color: var(--paradise-text-body); 
            box-sizing: border-box;
        }
        #scr699Root .scr699-shell {
            display: flex;
            flex-direction: column;
            gap: var(--paradise-space-4);
        }
        
        /* Hàng 1: Top Bar (Tabs, Bộ lọc & Nút bấm trên cùng một hàng ngang) */
        #scr699Root .scr699-top-bar {
            display: flex;
            justify-content: space-between;
            align-items: flex-end;
            border-bottom: 1px solid var(--paradise-border-color);
            gap: var(--paradise-space-4);
            flex-wrap: wrap;
            margin-top: var(--paradise-space-2);
        }
        #scr699Root .scr699-tabs-nav {
            display: flex;
            gap: var(--paradise-space-2);
            margin-bottom: -1px;
        }
        #scr699Root .scr699-filter-area {
            display: flex;
            align-items: center;
            gap: var(--paradise-space-3);
            margin-bottom: var(--paradise-space-2);
            flex-wrap: wrap;
        }
        #scr699Root .scr699-label {
            font-weight: 600;
            font-size: .9rem;
            color: var(--paradise-text-body);
            white-space: nowrap;
        }
        #scr699Root .scr699-input-wrapper {
            position: relative;
            display: flex;
            align-items: center;
            width: 240px;
        }
        #scr699Root .scr699-input-icon {
            position: absolute;
            left: var(--paradise-space-3);
            color: var(--paradise-text-muted);
            font-size: 1.1rem;
            pointer-events: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }
        #scr699Root .scr699-input {
            padding-left: 2.5rem;
            width: 100%;
            height: 38px;
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-input-border-radius);
            color: var(--paradise-text-body);
            background-color: var(--paradise-bg-surface);
            outline: none;
            box-sizing: border-box;
            font-size: var(--paradise-font-body1);
            transition: var(--paradise-transition-fast);
        }
        #scr699Root .scr699-input:focus {
            border-color: var(--paradise-color-input-border-hover);
            box-shadow: 0 0 0 2px var(--paradise-bg-primary-subtle);
        }
        #scr699Root .scr699-filter-area button {
            min-width: 90px;
            height: 38px;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: var(--paradise-space-2);
            font-weight: 600;
            white-space: nowrap;
        }
        #scr699Root .scr699-tab {
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
        #scr699Root .scr699-tab:hover {
            color: var(--paradise-color-primary);
            background-color: var(--paradise-bg-primary-subtle);
        }
        #scr699Root .scr699-tab.is-active {
            color: var(--paradise-color-primary);
            background-color: var(--paradise-card-bg);
            border-color: var(--paradise-border-color);
            border-bottom: 2px solid var(--paradise-color-primary);
        }
        
        /* Hàng 3: Main Content Panel */
        #scr699Root .scr699-panel {
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
        #scr699Root .scr699-panel-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: var(--paradise-space-4);
            flex-wrap: wrap;
            border-bottom: 1px solid var(--paradise-border-color);
            padding-bottom: var(--paradise-space-4);
        }
        #scr699Root .scr699-title {
            display: flex;
            gap: var(--paradise-space-3);
            align-items: center;
        }
        #scr699Root .scr699-title-icon {
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
        #scr699Root .scr699-panel h2 {
            font-size: 1.25rem;
            margin: 0;
            font-weight: 700;
            color: var(--paradise-text-heading, var(--paradise-text-body));
        }
        #scr699Root .scr699-muted {
            color: var(--paradise-text-muted);
            font-size: .85rem;
            margin-top: 2px;
        }
        
        /* Stats Thống kê */
        #scr699Root .scr699-stats {
            display: flex;
            gap: var(--paradise-space-3);
            flex-wrap: wrap;
        }
        #scr699Root .scr699-stat {
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
        #scr699Root .scr699-stat-label {
            font-size: 0.75rem;
            color: var(--paradise-text-muted);
            text-transform: uppercase;
            font-weight: 600;
            letter-spacing: 0.5px;
        }
        #scr699Root .scr699-stat-val {
            font-size: 1.2rem;
            color: var(--paradise-color-primary);
            font-weight: 700;
            margin-top: 2px;
        }
        
        /* Toolbar & Tìm kiếm */
        #scr699Root .scr699-toolbar {
            display: flex;
            width: 100%;
        }
        #scr699Root .scr699-search-wrapper {
            position: relative;
            display: flex;
            align-items: center;
            width: 100%;
        }
        #scr699Root .scr699-search-icon {
            position: absolute;
            left: var(--paradise-space-3);
            color: var(--paradise-text-muted);
            pointer-events: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }
        #scr699Root .scr699-search {
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
        #scr699Root .scr699-search:focus {
            border-color: var(--paradise-color-input-border-hover);
            box-shadow: 0 0 0 2px var(--paradise-bg-primary-subtle);
        }
        
        /* Cây phân quyền */
        #scr699Root .scr699-tree {
            flex: 1;
            max-height: calc(100vh - 380px);
            overflow-y: auto;
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-lg);
            padding: var(--paradise-space-3);
            background-color: var(--paradise-bg-surface);
        }
        #scr699Root .scr699-node {
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-lg);
            margin-bottom: var(--paradise-space-2);
            padding: var(--paradise-space-2) var(--paradise-space-3);
            background-color: var(--paradise-card-bg);
            transition: all var(--paradise-transition-fast);
        }
        #scr699Root .scr699-node:hover {
            border-color: var(--paradise-color-primary);
            box-shadow: var(--paradise-shadow-sm);
        }
        #scr699Root .scr699-node-row {
            display: flex;
            align-items: center;
            gap: var(--paradise-space-3);
        }
        #scr699Root .scr699-toggle {
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
        #scr699Root .scr699-toggle:hover {
            color: var(--paradise-color-primary);
            background-color: var(--paradise-bg-primary-subtle);
        }
        #scr699Root .scr699-name {
            font-weight: 600;
            line-height: 1.35;
            font-size: var(--paradise-font-body1);
            flex: 1;
            color: var(--paradise-text-body);
        }
        #scr699Root .scr699-children {
            margin-top: var(--paradise-space-2);
            padding-left: var(--paradise-space-4);
            display: none;
            border-left: 1px dashed var(--paradise-border-color);
        }
        #scr699Root .scr699-node.is-open > .scr699-children {
            display: block;
        }
        
        /* Container của DevExpress TagBox */
        #scr699Root .scr699-select-container {
            min-width: 180px;
            max-width: 280px;
            width: 100%;
        }
        #scr699Root .scr699-check {
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
        #scr699Root .scr699-check:hover {
            background-color: var(--paradise-bg-primary-subtle);
        }
        #scr699Root .scr699-check input[type=checkbox] {
            width: 16px;
            height: 16px;
            accent-color: var(--paradise-color-primary);
            cursor: pointer;
        }
        #scr699Root .scr699-empty {
            border: 1px dashed var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-lg);
            padding: var(--paradise-space-6);
            text-align: center;
            color: var(--paradise-text-muted);
            font-size: var(--paradise-font-body1);
        }
        #scr699Root .scr699-hidden {
            display: none !important;
        }
        
        /* Reponsive cho các thiết bị nhỏ hơn */
        @media (max-width: 920px) {
            #scr699Root .scr699-control-bar {
                flex-direction: column;
                align-items: stretch;
            }
            #scr699Root .scr699-field {
                max-width: none;
            }
            #scr699Root .scr699-actions {
                justify-content: flex-end;
            }
            #scr699Root .scr699-panel-header {
                flex-direction: column;
                align-items: flex-start;
            }
            #scr699Root .scr699-stats {
                width: 100%;
                justify-content: space-between;
            }
            #scr699Root .scr699-stat {
                flex: 1;
                min-width: 80px;
            }
            #scr699Root .scr699-node-row {
                flex-direction: column;
                align-items: stretch;
                gap: var(--paradise-space-2);
            }
        }
    </style>

    <div class="scr699-shell">
        <!-- Hàng 1: Top Bar (Tabs + Bộ lọc & Nút bấm trên cùng một hàng ngang) -->
        <div class="scr699-top-bar">
            <div class="scr699-tabs-nav">
                <button type="button" class="scr699-tab" data-mode="0">
                    <i class="bi bi-shield-check"></i><span>' + @menuTab + '</span>
                </button>
                <button type="button" class="scr699-tab" data-mode="1">
                    <i class="bi bi-database-fill-gear"></i><span>' + @empTab + '</span>
                </button>
            </div>
            
            <div class="scr699-filter-area">
                <label class="scr699-label" for="scr699Login">' + @accountLabel + '</label>
                <div class="scr699-input-wrapper">
                    <i class="bi bi-person-circle scr699-input-icon"></i>
                    <input id="scr699Login" class="scr699-input" autocomplete="off" />
                </div>
                <button type="button" id="scr699Reload" class="paradise-btn paradise-btn--reload">
                    <i class="bi bi-search"></i><span>' + @reload + '</span>
                </button>
                <button type="button" id="scr699Save" class="paradise-btn paradise-btn--save">
                    <i class="bi bi-check-circle"></i><span>' + @save + '</span>
                </button>
            </div>
        </div>

        <!-- Hàng 3: Main Content Panel -->
        <main class="scr699-panel">
            <div class="scr699-panel-header">
                <div class="scr699-title">
                    <span class="scr699-title-icon"><i class="bi bi-shield-lock-fill"></i></span>
                    <div>
                        <h2 id="scr699Title">' + @title + '</h2>
                        <div class="scr699-muted" id="scr699Subtitle">' + @subtitle + '</div>
                    </div>
                </div>
                
                <div class="scr699-stats">
                    <div class="scr699-stat">
                        <span class="scr699-stat-label">' + @itemsLabel + '</span>
                        <strong id="scr699Total" class="scr699-stat-val">0</strong>
                    </div>
                    <div class="scr699-stat">
                        <span class="scr699-stat-label">' + @selectedLabel + '</span>
                        <strong id="scr699Selected" class="scr699-stat-val">0</strong>
                    </div>
                    <div class="scr699-stat">
                        <span class="scr699-stat-label">' + @modeLabel + '</span>
                        <strong id="scr699ModeLabel" class="scr699-stat-val"></strong>
                    </div>
                </div>
            </div>
            
            <div class="scr699-toolbar">
                <div class="scr699-search-wrapper">
                    <i class="bi bi-search scr699-search-icon"></i>
                    <input id="scr699Search" class="scr699-search" placeholder="' + @search + '" />
                </div>
            </div>
            
            <div id="scr699Tree" class="scr699-tree">
                <div class="scr699-empty" id="scr699Empty">' + @empty + '</div>
            </div>
        </main>
    </div>
</div>
<script>
(function(){
    var LOGIN_ID = ' + CAST(@LoginID AS NVARCHAR(20)) + N';
    var LANGUAGE_ID = "' + @LanguageID + N'";
    var mode = ' + CAST(ISNULL(@IsAcessEmp,0) AS NVARCHAR(2)) + N';
    var texts = {title:"' + @titleJs + N'",subtitle:"' + @subtitleJs + N'",account:"' + @accountLabelJs + N'",menu:"' + @menuTabJs + N'",emp:"' + @empTabJs + N'",reload:"' + @reloadJs + N'",save:"' + @saveJs + N'",search:"' + @searchJs + N'",empty:"' + @emptyJs + N'",invalid:"' + @invalidJs + N'",confirm:"' + @confirmJs + N'",saved:"' + @savedJs + N'"};
    var state = {rows:[], tree:[]};
    var root = document.getElementById("scr699Root");
    var $ = window.jQuery;

    function getDataSource(callback){
        if (window.DataSource_scr699Select && window.DataSource_scr699Select.length) {
            callback(window.DataSource_scr699Select);
            return;
        }
        if (typeof AjaxHPAParadise === "function") {
            AjaxHPAParadise({
                data: {
                    name: "sp_decentralization_SelectOptions",
                    param: ["LoginID", LOGIN_ID, "LanguageID", LANGUAGE_ID]
                },
                success: function(res) {
                    var json = typeof res === "string" ? JSON.parse(res) : res;
                    window.DataSource_scr699Select = (json && json.data && json.data[0]) || [];
                    callback(window.DataSource_scr699Select);
                },
                error: function() {
                    callback([]);
                }
            });
        } else {
            callback([]);
        }
    }

    function byId(id){return document.getElementById(id);}
    function escapeHtml(v){if(v===null||v===undefined)return "";return String(v).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/\u0027/g,"&#039;");}
    function normalize(v){return String(v||"").normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase();}
    function paramName(){return mode === 1 ? "Json_update_Emp" : "Json_update";}
    function apiName(){return mode === 1 ? "sp_decentralization_EmpData" : "sp_decentralization_MenuData";}
    function getLogin(){return byId("scr699Login").value.trim();}

    function initLabels(){
        byId("scr699Title").textContent = texts.title;
        byId("scr699Subtitle").textContent = texts.subtitle;
        root.querySelector("label[for=scr699Login]").textContent = texts.account;
        root.querySelector(".scr699-tab[data-mode=0] span").textContent = texts.menu;
        root.querySelector(".scr699-tab[data-mode=1] span").textContent = texts.emp;
        byId("scr699Reload").querySelector("span").textContent = texts.reload;
        byId("scr699Save").querySelector("span").textContent = texts.save;
        byId("scr699Search").placeholder = texts.search;
        byId("scr699Empty").textContent = texts.empty;
        byId("scr699Login").value = "' + @loginAccountJs + N'";
        setMode(mode, false);
    }

    function setMode(nextMode, load){
        mode = Number(nextMode) === 1 ? 1 : 0;
        root.querySelectorAll(".scr699-tab").forEach(function(btn){btn.classList.toggle("is-active", Number(btn.dataset.mode) === mode);});
        byId("scr699ModeLabel").textContent = mode === 1 ? texts.emp : texts.menu;
        if(load) loadData();
    }

    function buildTree(rows){
        var map = {}, roots = [];
        rows.forEach(function(r){
            var id = String(r.ObjectID);
            r._id = id;
            r._children = [];
            map[id] = r;
        });
        rows.forEach(function(r){
            var pid = mode === 1 ? String(r.ParentObjectID||"") : String(r.ParentObjectID||r.ObjectID);
            if(pid && pid !== r._id && map[pid]) map[pid]._children.push(r); else roots.push(r);
        });
        roots.sort(sortNode); roots.forEach(function(r){r._children.sort(sortNode);});
        return roots;
    }
    function sortNode(a,b){return (Number(a.Prio||0)-Number(b.Prio||0)) || String(a.Description||"").localeCompare(String(b.Description||""));}

    function render(){
        var tree = byId("scr699Tree");
        byId("scr699Total").textContent = state.rows.length;
        if(!state.rows.length){tree.innerHTML = "<div class=\"scr699-empty\">" + texts.empty + "</div>"; updateSelected(); return;}
        tree.innerHTML = state.tree.map(renderNode).join("");
        initializeNodeControls();
        updateSelected();
    }

    function renderNode(n){
        var hasChild = n._children && n._children.length;
        var name = escapeHtml(n.Description || n.ObjectName || n.ObjectID);
        var control = mode === 1 ? renderCheckbox(n) : renderSelect(n);
        return "<div class=\"scr699-node" + (hasChild ? " is-open" : "") + "\" data-text=\"" + escapeHtml(normalize(name)) + "\" data-id=\"" + escapeHtml(n._id) + "\">"
            + "<div class=\"scr699-node-row\">"
            + "<button type=\"button\" class=\"scr699-toggle\">" + (hasChild ? "<i class=\"bi bi-chevron-down\"></i>" : "") + "</button>"
            + "<div class=\"scr699-name\">" + name + "</div>" + control + "</div>"
            + (hasChild ? "<div class=\"scr699-children\">" + n._children.map(renderNode).join("") + "</div>" : "")
            + "</div>";
    }
    
    // Trả về container cho TagBox khởi tạo động
    function renderSelect(n){
        return "<div class=\"scr699-select-container\" id=\"select_container_" + escapeHtml(n.ObjectID) + "\" data-value=\"" + escapeHtml(n.FullAccess || "") + "\"></div>";
    }
    
    function renderCheckbox(n){
        return "<label class=\"scr699-check\"><input type=\"checkbox\" id=\"IsFull_" + escapeHtml(n.ObjectID) + "\" " + (Number(n.ViewInfo)===1 ? "checked" : "") + "> <span>View</span></label>";
    }

    // Khởi tạo các TagBox của DevExpress cho từng node
    function initializeNodeControls() {
        getDataSource(function(ds) {
            document.querySelectorAll(".scr699-select-container").forEach(function(el) {
                var id = el.id.replace("select_container_", "");
                var val = el.dataset.value;
                var selectedVals = val ? val.split("&").map(function(s){return s.trim();}).filter(function(s){return s !== "";}) : [];
                
                $(el).dxTagBox({
                    dataSource: ds || [],
                    valueExpr: "ID",
                    displayExpr: "Name",
                    value: selectedVals,
                    width: "100%",
                    placeholder: "...",
                    showSelectionControls: true,
                    applyValueMode: "useButtons",
                    onValueChanged: function(e) {
                        updateSelected();
                    }
                });
            });
        });
    }

    function loadData(){
        var login = getLogin();
        if(!login){state.rows=[];state.tree=[];render();return;}
        byId("scr699Tree").innerHTML = "<div class=\"scr699-empty\"><i class=\"bi bi-hourglass-split\"></i> Loading...</div>";
        AjaxHPAParadise({data:{name:apiName(),param:["LoginID",LOGIN_ID,"LanguageID",LANGUAGE_ID,"LoginAccount",login]},success:function(res){
            var json = typeof res === "string" ? JSON.parse(res) : res;
            var row = json && json.data && json.data[0] && json.data[0][0];
            if(!row || !row.IsValid){state.rows=[];state.tree=[];byId("scr699Tree").innerHTML = "<div class=\"scr699-empty\">"+texts.invalid+"</div>";updateSelected();return;}
            state.rows = row.JsonData ? JSON.parse(row.JsonData) : [];
            state.tree = buildTree(state.rows);
            render();
        }});
    }

    function saveData(){
        if(!getLogin()){return;}
        
        var confirmDialog = DevExpress.ui.dialog.custom({
            title: texts.title,
            messageHtml: "<div style=\"width: 300px; font-size: 14px; padding: 10px 0;\">" + texts.confirm + "</div>",
            buttons: [
                {
                    text: LANGUAGE_ID === "VN" ? "Đồng ý" : "Yes",
                    onClick: function() { return true; }
                },
                {
                    text: LANGUAGE_ID === "VN" ? "Hủy" : "Cancel",
                    onClick: function() { return false; }
                }
            ]
        });
        
        confirmDialog.show().done(function(dialogResult) {
            if (!dialogResult) return;
            
            var payload = {};
            if(mode === 1){
                root.querySelectorAll("input[type=checkbox][id^=IsFull_]").forEach(function(el){payload[el.id]=el.checked?1:0;});
            } else {
                // Lấy dữ liệu từ các DevExpress TagBox instances
                document.querySelectorAll(".scr699-select-container").forEach(function(el) {
                    var id = el.id.replace("select_container_", "");
                    var instance = $(el).dxTagBox("instance");
                    if (instance) {
                        var val = instance.option("value");
                        payload["select_access_" + id] = Array.isArray(val) ? val.join("&") : (val || "0");
                    }
                });
            }
            var params = ["LoginID",LOGIN_ID,"LoginAccount",getLogin(),paramName(),JSON.stringify(payload)];
            AjaxHPAParadise({
                data:{name:"sp_decentralization_update",param:params},
                success:function(){
                    if (typeof showPopupNotify === "function") {
                        showPopupNotify(texts.title, texts.saved, "OK", "300px");
                    } else {
                        DevExpress.ui.dialog.custom({
                            title: texts.title,
                            messageHtml: "<div style=\"width: 300px; font-size: 14px; padding: 10px 0;\">" + texts.saved + "</div>",
                            buttons: [{ text: "OK", onClick: function() { return true; } }]
                        }).show();
                    }
                    loadData();
                }
            });
        });
    }

    function updateSelected(){
        var count = 0;
        if(mode === 1){
            count = root.querySelectorAll("input[type=checkbox][id^=IsFull_]:checked").length;
        } else {
            document.querySelectorAll(".scr699-select-container").forEach(function(el) {
                var instance = $(el).dxTagBox("instance");
                if (instance) {
                    var val = instance.option("value");
                    if (Array.isArray(val)) {
                        // Chỉ đếm các quyền khác "0" (Từ chối)
                        var activeRights = val.filter(function(v){return v !== "0";});
                        count += activeRights.length;
                    }
                }
            });
        }
        byId("scr699Selected").textContent = count;
    }

    function filterTree(){
        var q = normalize(byId("scr699Search").value);
        root.querySelectorAll(".scr699-node").forEach(function(n){
            var match = !q || n.dataset.text.indexOf(q) >= 0 || Array.from(n.querySelectorAll(".scr699-node")).some(function(c){return c.dataset.text.indexOf(q)>=0;});
            n.classList.toggle("scr699-hidden", !match);
            if(q && match) n.classList.add("is-open");
        });
    }

    root.addEventListener("click", function(e){
        var tab = e.target.closest(".scr699-tab"); if(tab){setMode(tab.dataset.mode, true);return;}
        if(e.target.closest("#scr699Reload")){loadData();return;}
        if(e.target.closest("#scr699Save")){saveData();return;}
        var toggle = e.target.closest(".scr699-toggle"); if(toggle){var node=toggle.closest(".scr699-node"); if(node) node.classList.toggle("is-open");}
    });
    root.addEventListener("change", updateSelected);
    byId("scr699Search").addEventListener("input", filterTree);
    byId("scr699Login").addEventListener("keydown", function(e){if(e.key === "Enter") loadData();});
    initLabels();
    if(getLogin()) loadData();
    if(typeof HideLoadingByClassOrID === "function") HideLoadingByClassOrID("#sp_decentralization");
})();
</script>' AS col1;
END
GO

PRINT N'  [OK] Đã thiết kế lại sp_decentralization.';
GO

-- ============================================================================
-- 5) Đảm bảo metadata hiện tại vẫn đúng cho HTML-rendered/DataSetting
-- ============================================================================
PRINT N'5. Cập nhật tblDataSetting và tblDataSettingLayout...';
GO

UPDATE dbo.tblDataSetting
   SET IsProcedure = 1,
       IsShowLayout = 1,
       ColumnDataType = 'col1&ViewHtml',
       ColumnOrderBy = 'col1&0'
 WHERE TableName = 'sp_decentralization';

IF NOT EXISTS (SELECT 1 FROM dbo.tblDataSettingLayout WHERE TableName = 'sp_decentralization' AND Name = 'root')
BEGIN
    INSERT INTO dbo.tblDataSettingLayout(TableName, Name, ControlName, NamePa, Type, TypeLayout, WidthPercentage)
    VALUES ('sp_decentralization', 'root', '', '', 'g', '6', 100);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.tblDataSettingLayout WHERE TableName = 'sp_decentralization' AND ControlName = 'col1')
BEGIN
    INSERT INTO dbo.tblDataSettingLayout(TableName, Name, ControlName, NamePa, Type, TypeLayout, ControlType, WidthPercentage)
    VALUES ('sp_decentralization', 'lblcol1', 'col1', 'root', 'i', '6', 'ParadiseWebView2', 100);
END;
GO

PRINT N'  [OK] Đã đảm bảo cấu hình layout trong database.';
GO

-- ============================================================================
-- 6) Làm mới menu cache phía client
-- ============================================================================
PRINT N'6. Đồng bộ cache hệ thống...';
GO

IF OBJECT_ID('dbo.sp_Men_Menu_AfterSave_Simple', 'P') IS NOT NULL
    EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_decentralization';
GO

PRINT N'CẬP NHẬT GIAO DIỆN PHÂN QUYỀN TRUY CẬP (MnuSCR699) THÀNH CÔNG!';
GO
