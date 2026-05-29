-- ============================================================
-- File: deploy_menu_sp_UserManagement_20260529.sql
-- Mục đích: Tạo menu "Danh sách người dùng" (User List) chuẩn ParadiseHR
--           dùng HPA Control System (tblCommonControlType_Signed).
-- DB đích: Paradise_Dev
-- Ngày:   2026-05-29
-- Cảnh báo: User TỰ REVIEW và CHẠY. BACKUP database trước khi chạy.
-- ============================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE [Paradise_Dev];
GO

PRINT '=== START: Deploy menu "Danh sách người dùng" (sp_UserManagement) ===';
PRINT '';
GO

-- ============================================================
-- PHASE A1: Grid Data SP (wrapper sp_UserManagementList + @TempTableAPIName)
-- ============================================================
PRINT '--- Phase A1: Creating sp_UserManagementGridList ---';
GO

CREATE OR ALTER PROCEDURE dbo.sp_UserManagementGridList
( @LoginID           INT          = 3,
  @ViewGroup         BIT          = 0,
  @LanguageID        VARCHAR(5)   = 'VN',
  @IsWeb             INT          = 1,
  @TempTableAPIName  VARCHAR(100) = '' )
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #tmpResult (
        GrantAccessRight              NVARCHAR(500),
        LoginID                       INT,
        EmployeeID                    VARCHAR(20),
        FullName                      NVARCHAR(300),
        LoginName                     VARCHAR(50),
        PassWord                      VARCHAR(500),
        ParentLoginID                 VARCHAR(500),
        UseGroupRightOnly             BIT,
        IsDisable                     BIT,
        LastAttemptsTime              DATETIME,
        NeedEncryptPassWordColumnList VARCHAR(500),
        ParadiseLogOutTimeOut         FLOAT
    );

    INSERT INTO #tmpResult
    EXEC dbo.sp_UserManagementList
         @LoginID                     = @LoginID,
         @ViewGroup                   = @ViewGroup,
         @LanguageID                  = @LanguageID,
         @CreateAccountSelectedEmp_reset = 0,
         @IsWeb                       = @IsWeb;

    SELECT ROW_NUMBER() OVER (ORDER BY LoginID) AS STT,
           GrantAccessRight,
           LoginID,
           EmployeeID,
           FullName,
           LoginName,
           ParentLoginID,
           UseGroupRightOnly,
           IsDisable,
           LastAttemptsTime,
           ParadiseLogOutTimeOut
    INTO #tmpTableData
    FROM #tmpResult;

    DECLARE @sql NVARCHAR(MAX);
    IF (@TempTableAPIName = '')
        SET @sql = N'SELECT * FROM #tmpTableData';
    ELSE
        SET @sql = N'SELECT * INTO ' + QUOTENAME(@TempTableAPIName) + N' FROM #tmpTableData';
    EXEC sp_executesql @sql;

    DROP TABLE #tmpTableData;
    DROP TABLE #tmpResult;
END
GO

PRINT '   OK sp_UserManagementGridList created.';
GO

-- ============================================================
-- PHASE A2: tblCommonControlType_Signed metadata
-- ============================================================
PRINT '--- Phase A2: Setting up tblCommonControlType_Signed ---';
GO

-- Idempotent: xoá cũ trước khi insert
DELETE FROM tblCommonControlType_Signed WHERE TableName = 'sp_UserManagement_html';
GO

-- Grid container (UID = P + 32 chars, must be unique across entire table)
INSERT INTO tblCommonControlType_Signed
    (TableName, ColumnName, Type, Layout, SPLoadData, ColumnIDName, UID)
VALUES
    ('sp_UserManagement_html', 'GridUserManagement', 'hpaControlGrid_Duc', 'Grid_View',
     'sp_UserManagementGridList', 'LoginID', 'PUMG0000000000000000000000000001');

-- Columns
INSERT INTO tblCommonControlType_Signed
    (TableName, ColumnName, Type, Layout, DisplayName, GridColumnName, GridWidth, AllowSorting, AllowFiltering, UID)
VALUES
    ('sp_UserManagement_html', 'STT',              NULL, 'Grid_View', N'#',                'GridUserManagement', '50',   0, 0, 'PUMC00000000000000000000000000001'),
    ('sp_UserManagement_html', 'LoginName',        NULL, 'Grid_View', N'Tên đăng nhập',    'GridUserManagement', '150',  1, 1, 'PUMC00000000000000000000000000002'),
    ('sp_UserManagement_html', 'FullName',         NULL, 'Grid_View', N'Họ và tên',        'GridUserManagement', '200',  1, 1, 'PUMC00000000000000000000000000003'),
    ('sp_UserManagement_html', 'EmployeeID',       NULL, 'Grid_View', N'Mã nhân viên',     'GridUserManagement', '120',  1, 1, 'PUMC00000000000000000000000000004'),
    ('sp_UserManagement_html', 'IsDisable',        NULL, 'Grid_View', N'Trạng thái',       'GridUserManagement', '100',  1, 1, 'PUMC00000000000000000000000000005'),
    ('sp_UserManagement_html', 'LastAttemptsTime', NULL, 'Grid_View', N'Đăng nhập cuối',   'GridUserManagement', '150',  1, 1, 'PUMC00000000000000000000000000006'),
    ('sp_UserManagement_html', 'GrantAccessRight', NULL, 'Grid_View', N'Phân quyền',       'GridUserManagement', '100',  0, 0, 'PUMC00000000000000000000000000007');
GO

PRINT '   OK Metadata inserted (1 container + 7 columns).';

-- Run DUC to populate html/loadUI/loadData
EXEC sptblCommonControlType_Signed_DUC 'sp_UserManagement_html';
PRINT '   OK sptblCommonControlType_Signed_DUC executed.';
GO

-- ============================================================
-- PHASE B: Renderer sp_UserManagement_html (config-driven)
-- ============================================================
PRINT '--- Phase B: Creating sp_UserManagement_html (config-driven) ---';
GO

CREATE OR ALTER PROCEDURE dbo.sp_UserManagement_html
( @LoginID    INT         = 3,
  @LanguageID VARCHAR(5)  = 'VN',
  @isWeb      INT         = 1 )
AS
BEGIN
    SET NOCOUNT ON;

    -- ============================================================
    -- Text labels VN/EN
    -- ============================================================
    DECLARE @title          NVARCHAR(200);
    DECLARE @subtitle       NVARCHAR(300);
    DECLARE @loading        NVARCHAR(100);
    DECLARE @txtActive      NVARCHAR(50);
    DECLARE @txtInactive    NVARCHAR(50);
    DECLARE @txtSystem      NVARCHAR(100);
    DECLARE @txtAction      NVARCHAR(100);
    DECLARE @txtSearch      NVARCHAR(150);

    IF @LanguageID = 'EN'
    BEGIN
        SET @title        = N'User List';
        SET @subtitle     = N'System user account management.';
        SET @loading      = N'Loading...';
        SET @txtActive    = N'Active';
        SET @txtInactive  = N'Inactive';
        SET @txtSystem    = N'System account';
        SET @txtAction    = N'Permissions';
        SET @txtSearch    = N'Search by username, full name...';
    END
    ELSE
    BEGIN
        SET @title        = N'Danh sách người dùng';
        SET @subtitle     = N'Quản lý tài khoản người dùng hệ thống.';
        SET @loading      = N'Đang tải...';
        SET @txtActive    = N'Hoạt động';
        SET @txtInactive  = N'Vô hiệu';
        SET @txtSystem    = N'Tài khoản hệ thống';
        SET @txtAction    = N'Phân quyền';
        SET @txtSearch    = N'Tìm theo tên đăng nhập, họ tên...';
    END

    -- Escape text cho JavaScript
    DECLARE @loadingJs     NVARCHAR(200);
    DECLARE @txtActiveJs   NVARCHAR(100);
    DECLARE @txtInactiveJs NVARCHAR(100);
    DECLARE @txtSystemJs   NVARCHAR(200);
    DECLARE @txtActionJs   NVARCHAR(200);
    DECLARE @txtSearchJs   NVARCHAR(300);

    SET @loadingJs      = REPLACE(REPLACE(@loading,      N'\', N'\\'), N'"', N'\"');
    SET @txtActiveJs    = REPLACE(REPLACE(@txtActive,    N'\', N'\\'), N'"', N'\"');
    SET @txtInactiveJs  = REPLACE(REPLACE(@txtInactive,  N'\', N'\\'), N'"', N'\"');
    SET @txtSystemJs    = REPLACE(REPLACE(@txtSystem,    N'\', N'\\'), N'"', N'\"');
    SET @txtActionJs    = REPLACE(REPLACE(@txtAction,    N'\', N'\\'), N'"', N'\"');
    SET @txtSearchJs    = REPLACE(REPLACE(@txtSearch,    N'\', N'\\'), N'"', N'\"');

    DECLARE @ContainerUID VARCHAR(33) = 'PUMG0000000000000000000000000001';
    DECLARE @GridName     VARCHAR(100) = 'GridUserManagement';
    DECLARE @PKColumn     VARCHAR(100) = 'LoginID';

    -- ============================================================
    -- Build HTML
    -- ============================================================
    DECLARE @html NVARCHAR(MAX) = N'';

    -- HTML wrapper
    SET @html = N'
<div id="userMgmtRoot" class="um-page">
    <div class="um-header">
        <div class="um-header-left">
            <h2 class="um-title">' + @title + N'</h2>
            <p class="um-subtitle">' + @subtitle + N'</p>
        </div>
    </div>
    <div class="paradise-card um-grid-card">
        <div id="' + @GridName + N'" style="height:100%;min-height:400px;"></div>
    </div>
</div>';

    -- CSS (ParadiseStyle)
    SET @html = @html + N'
<style>
.um-page {
    padding: var(--paradise-space-4);
    font-family: var(--paradise-font-family-base);
    color: var(--paradise-text-body);
}
.um-header {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: var(--paradise-space-3);
    margin-bottom: var(--paradise-space-4);
}
.um-header-left h2.um-title {
    margin: 0 0 var(--paradise-space-1) 0;
    font-size: 1.25rem;
    font-weight: 600;
    color: var(--paradise-text-body);
}
.um-header-left .um-subtitle {
    margin: 0;
    font-size: 0.875rem;
    color: var(--paradise-text-muted);
}
.um-grid-card {
    padding: var(--paradise-card-padding, var(--paradise-space-3));
    background: var(--paradise-card-bg);
    border: 1px solid var(--paradise-card-border);
    border-radius: var(--paradise-card-radius, var(--paradise-border-radius-md));
    box-shadow: var(--paradise-card-shadow);
    overflow: hidden;
}
.um-status-badge {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 2px 10px;
    border-radius: var(--paradise-border-radius-pill);
    font-size: 0.75rem;
    font-weight: 500;
    line-height: 1.6;
}
.um-status-active {
    color: var(--paradise-color-success);
    background: var(--paradise-bg-success-subtle);
}
.um-status-inactive {
    color: var(--paradise-color-danger);
    background: var(--paradise-bg-danger-subtle);
}
.um-action-link {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    color: var(--paradise-color-primary);
    text-decoration: none;
    font-weight: 500;
    font-size: 0.8125rem;
    cursor: pointer;
    transition: opacity 0.15s;
}
.um-action-link:hover {
    opacity: 0.8;
    text-decoration: underline;
}
.um-row-system {
    opacity: 0.55;
}
</style>';

    -- ============================================================
    -- JAVASCRIPT (pattern sp_CRM_ProductType_html)
    -- ============================================================
    SET @html = @html + N'
<script>
(() => {
    let api = true;
    let DataSource = [];
    let _pageCache = {};
    let _currentKeyword = "";
    let dataStore_' + @GridName + N' = null;
    let _showtoolbarGrid_' + @ContainerUID + N' = true;
    let _showtoolbarAdd_' + @ContainerUID + N'  = false;

    /* ---- add & openDetail stubs ---- */
    function add' + @PKColumn + N'(){
        window.currentClicked' + @GridName + N' = null;
        window.currentClicked_' + @GridName + N' = null;
    }
    function openDetail' + @PKColumn + N'(obj){
        window.currentClicked' + @GridName + N' = obj;
    }

    /* ---- GrantAccessRight action handler ---- */
    function _umHandleAction(actionString){
        if(!actionString) return;
        var parts = {};
        var segs = actionString.split("|");
        for(var i = 0; i < segs.length; i++){
            var kv = segs[i].split("=");
            if(kv.length >= 2) parts[kv[0]] = kv.slice(1).join("=");
        }
        var obj = parts["Object"];
        var rawParams = parts["Params"] || "";
        if(obj){
            var paramObj = { LoginID: window.LoginID, LanguageID: window.LanguageID };
            var paramPairs = rawParams.split("&");
            for(var j = 0; j < paramPairs.length; j++){
                var pk = paramPairs[j].split("=");
                if(pk.length === 2) paramObj[pk[0]] = pk[1];
            }
            if(typeof getMobileOperatingSystem === "function" && ["Android","iOS"].includes(getMobileOperatingSystem())){
                OpenFormParamMobile(obj, paramObj);
            } else if(typeof openFormParam === "function"){
                openFormParam(obj, paramObj);
            }
        }
    }

    /* ---- formatDate helper ---- */
    function _umFormatDate(d){
        if(!d) return "-";
        var dt = new Date(d);
        if(isNaN(dt.getTime())) return "-";
        var dd = String(dt.getDate()).padStart(2,"0");
        var mm = String(dt.getMonth()+1).padStart(2,"0");
        var yyyy = dt.getFullYear();
        var hh = String(dt.getHours()).padStart(2,"0");
        var min = String(dt.getMinutes()).padStart(2,"0");
        return dd + "/" + mm + "/" + yyyy + " " + hh + ":" + min;
    }

    /* ---- CustomStore ---- */
    dataStore_' + @GridName + N' = new DevExpress.data.CustomStore({
        key: "' + @PKColumn + N'",
        load: function(loadOptions){
            const deferred = $.Deferred();
            if(!api){
                const results = DataSource || [];
                const skip = loadOptions.skip || 0;
                const take = loadOptions.take || 50;
                deferred.resolve({ data: results.slice(skip, skip + take), totalCount: results.length });
                api = true;
                return deferred.promise();
            }
            let params = [];
            params.push("@ProcName", "sp_UserManagementGridList");
            let procParam = "@LoginID=" + (window.UserID || window.LoginID)
                + ",@LanguageID=" + window.LanguageID
                + ",@ViewGroup=0,@IsWeb=1";
            params.push("@ProcParam", procParam);
            params.push("@Take", loadOptions.take || 50);
            params.push("@Skip", loadOptions.skip || 0);
            if(loadOptions.requireTotalCount) params.push("@RequireTotalCount", 1);
            const sort = loadOptions.sort
                ? loadOptions.sort.map(s => s.selector + (s.desc ? " DESC" : " ASC")).join(",")
                : "LoginID";
            params.push("@Sort", "ORDER BY " + sort);
            if(_currentKeyword){
                params.push("@SearchValue", _currentKeyword);
                params.push("@ColumnSearch", "LoginName,FullName,EmployeeID");
            }
            if(loadOptions.filter){
                const hasFunction = JSON.stringify(loadOptions.filter, (key, val) => {
                    if(typeof val === "function") return "FUNCTION";
                    return val;
                }).includes("FUNCTION");
                if(!hasFunction){
                    params.push("@Filters", createConditionQuery(loadOptions.filter));
                }
            }
            AjaxHPAParadise({
                data: { name: "sp_LoadGridUsingAPI", param: params },
                success: function(res){
                    const json = typeof res === "string" ? JSON.parse(res) : res;
                    const results = Array.isArray(json?.data?.[0]) ? json.data[0] : [];
                    let result = { data: results };
                    if(loadOptions.requireTotalCount){
                        result.totalCount = json?.data?.[1]?.[0]?.TotalCount ?? 0;
                    }
                    DataSource = results;
                    window.syncSharedGridData("' + @GridName + N'");
                    deferred.resolve(result);
                },
                error: function(){
                    deferred.reject("Data Loading Error");
                }
            });
            return deferred.promise();
        }
    });

    /* ---- Inject loadUI from DUC ---- */
    '
    + (SELECT loadUI FROM tblCommonControlType_Signed WHERE UID = @ContainerUID) + N'

    window.currentRecordID_' + @PKColumn + N' = null;

    /* ---- Grid height ---- */
    function getGridHeight(){
        const gridEl = Instance' + @GridName + @ContainerUID + N'.element();
        const domEl = gridEl.jquery ? gridEl[0] : gridEl;
        const top = domEl.getBoundingClientRect().top;
        return window.innerHeight - top - 20;
    }

    /* ---- Grid config override ---- */
    const gridInstance = Instance' + @GridName + @ContainerUID + N';
    gridInstance.beginUpdate();
    gridInstance.option("remoteOperations", {
        paging: true, filtering: true, sorting: true, searching: true
    });
    gridInstance.option({
        "scrolling.mode": "infinite",
        "scrolling.rowRenderingMode": "virtual",
        "scrolling.preloadEnabled": false,
        "paging.enabled": true,
        "paging.pageSize": 50,
        "pager.visible": false,
        "searchPanel.visible": true,
        "searchPanel.highlightSearchText": false,
        "searchPanel.placeholder": "' + @txtSearchJs + N'",
        "searchPanel.width": 280,
        "dataSource": dataStore_' + @GridName + N',
        "height": getGridHeight()
    });
    gridInstance.option("onOptionChanged", function(e){
        if(e.name === "searchPanel" && e.fullName === "searchPanel.text"){
            _currentKeyword = (e.value || "").trim();
            _pageCache = {};
        }
    });

    /* ---- Customize columns: IsDisable → badge, GrantAccessRight → action link ---- */
    gridInstance.columnOption("IsDisable", "cellTemplate", function(container, options){
        var disabled = options.value;
        if(disabled){
            container.html("<span class=\"um-status-badge um-status-inactive\"><i class=\"bi bi-lock\"></i> ' + @txtInactiveJs + N'</span>");
        } else {
            container.html("<span class=\"um-status-badge um-status-active\"><i class=\"bi bi-check-circle-fill\"></i> ' + @txtActiveJs + N'</span>");
        }
    });
    gridInstance.columnOption("GrantAccessRight", "cellTemplate", function(container, options){
        var raw = String(options.value || "");
        container.html("<a class=\"um-action-link\" data-ga=\"" + raw.replace(/"/g, "&quot;") + "\" href=\"javascript:void(0)\"><i class=\"bi bi-shield-lock\"></i> ' + @txtActionJs + N'</a>");
    });

    /* ---- Row dim for system accounts ---- */
    gridInstance.option("onRowPrepared", function(e){
        if(e.rowType === "data" && e.data){
            var isSys = !e.data.FullName || e.data.FullName === "' + @txtSystemJs + N'";
            if(isSys && e.rowElement){
                e.rowElement.addClass("um-row-system");
            }
        }
    });

    /* ---- Delegated click for action links ---- */
    $("#' + @GridName + N'").on("click", ".um-action-link", function(e){
        e.preventDefault();
        var actionStr = $(this).attr("data-ga");
        if(actionStr) _umHandleAction(actionStr);
    });

    gridInstance.endUpdate();

    /* ---- ReloadData ---- */
    function ReloadData(){
        _pageCache = {};
        _currentKeyword = "";
        gridInstance.refresh();
    }

    ReloadData();
})();
</script>';

    SELECT @html AS html;
END
GO

PRINT '   OK sp_UserManagement_html created.';
GO

-- ============================================================
-- Wrapper sp_UserManagement
-- ============================================================
PRINT '--- Creating sp_UserManagement (wrapper) ---';
GO

CREATE OR ALTER PROCEDURE dbo.sp_UserManagement
( @LoginID    INT         = 3,
  @LanguageID VARCHAR(5)  = 'VN',
  @isWeb      INT         = 1 )
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @html NVARCHAR(MAX);

    SELECT TOP 1 @html = html
    FROM dbo.tblHtmlScriptCache
    WHERE TableName  = 'sp_UserManagement_html'
      AND ScreenType = '-1'
      AND LanguageID = @LanguageID;

    IF @html IS NULL OR @html = N''
    BEGIN
        DECLARE @result TABLE (html NVARCHAR(MAX));
        INSERT INTO @result
        EXEC dbo.sp_UserManagement_html @LoginID=@LoginID, @LanguageID=@LanguageID, @isWeb=@isWeb;
        SELECT TOP 1 @html = html FROM @result;
    END

    SELECT @html AS html;
END
GO

PRINT '   OK sp_UserManagement created.';
GO

-- ============================================================
-- PHASE D: Menu metadata via sp_s_CreateMenu
-- ============================================================
PRINT '--- Phase D: Creating menu metadata ---';
GO

IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE ClassName = 'sp_UserManagement')
BEGIN
    EXEC dbo.sp_s_CreateMenu
         @Text          = N'Danh sách người dùng',
         @TextEN        = 'User List',
         @ClassName     = 'sp_UserManagement',
         @ParentMenuID  = 'MnuSCR000',
         @AssemblyName  = 'DataSetting',
         @Option        = 1,
         @LoginIDList   = '3';
    PRINT '   OK sp_s_CreateMenu executed.';
END
ELSE
    PRINT '   WARNING: Menu already exists. Skipped sp_s_CreateMenu.';
GO

-- ============================================================
-- PHASE D2: tblDataSetting
-- ============================================================
PRINT '--- Phase D2: tblDataSetting ---';
GO

DECLARE @dsClassName VARCHAR(200) = 'sp_UserManagement';

IF NOT EXISTS (SELECT 1 FROM tblDataSetting WHERE TableName = @dsClassName)
BEGIN
    INSERT INTO tblDataSetting (
        TableName, ViewName, IsProcedure, IsShowLayout,
        ColumnOrderBy, ColumnDataType, ColumnHide,
        ControlHiddenInShowLayout
    ) VALUES (
        @dsClassName, @dsClassName,
        1, 1,
        'html&0', 'html&ViewHtml',
        'isReadOnlyRow,dtftxxENGColumns',
        'grdTableEditor,txtFilter,btnReload,btnFWDelete,btnFWReset,btnExport,btnFWSave,btnFWAdd,isReadOnlyRow,dtftxxENGColumns'
    );
    PRINT '   OK tblDataSetting inserted.';
END
ELSE
BEGIN
    UPDATE tblDataSetting
       SET IsProcedure   = 1,
           IsShowLayout  = 1,
           ColumnOrderBy = 'html&0',
           ColumnDataType = 'html&ViewHtml',
           ColumnHide    = 'isReadOnlyRow,dtftxxENGColumns',
           ControlHiddenInShowLayout = 'grdTableEditor,txtFilter,btnReload,btnFWDelete,btnFWReset,btnExport,btnFWSave,btnFWAdd,isReadOnlyRow,dtftxxENGColumns'
     WHERE TableName = @dsClassName;
    PRINT '   OK tblDataSetting updated.';
END
GO

-- ============================================================
-- PHASE E: Menu flags (Rule 2)
-- ============================================================
PRINT '--- Phase E: Menu flags ---';
GO

DECLARE @muID VARCHAR(100);
SELECT TOP 1 @muID = MenuID FROM MEN_Menu WHERE ClassName = 'sp_UserManagement';

IF @muID IS NOT NULL
BEGIN
    UPDATE MEN_Menu
       SET IsVisible             = 1,
           IsWeb                 = 0,
           ViewOnWeb             = 0,
           IsUseMobileDevice     = 1,
           isShowLayOutWeb       = 0,
           isShowInMobileLayOut  = 0,
           Priority              = 99,
           glyphicon             = 'UserList',
           GroupID               = 'MnuSCR000'
     WHERE MenuID = @muID;
    PRINT '   OK Flags updated for ' + @muID;
END
ELSE
    PRINT '   ERROR: No MenuID found.';
GO

-- ============================================================
-- PHASE F: Build HTML cache
-- ============================================================
PRINT '--- Phase F: Building HTML cache ---';
GO

DELETE FROM dbo.tblHtmlScriptCache WHERE TableName = 'sp_UserManagement_html';
EXEC dbo.sp_GenerateHTMLScript 'sp_UserManagement_html';

SELECT TableName, LanguageID, ScreenType, DATALENGTH(html) AS HtmlBytes, Version
FROM dbo.tblHtmlScriptCache
WHERE TableName = 'sp_UserManagement_html'
ORDER BY LanguageID;
GO

PRINT '   OK Cache built.';
GO

-- ============================================================
-- PHASE G: Permissions (LoginID=3 + cuong.vu)
-- ============================================================
PRINT '--- Phase G: Permissions ---';
GO

DECLARE @muID2  VARCHAR(100);
DECLARE @objID  INT;

SELECT TOP 1 @muID2 = MenuID FROM MEN_Menu WHERE ClassName = 'sp_UserManagement';
SELECT TOP 1 @objID = ObjectID FROM tblSC_Object WHERE Description = @muID2;

IF @objID IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID = @objID AND LoginID = 3)
    BEGIN
        INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@objID, 3, '32');
        PRINT '   OK Permission: LoginID=3 (admin).';
    END
    ELSE
        PRINT '   WARNING: LoginID=3 already has permission.';

    IF NOT EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID = @objID AND LoginID = 23)
    BEGIN
        INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@objID, 23, '32');
        PRINT '   OK Permission: Cuong.vu (LoginID=23).';
    END
    ELSE
        PRINT '   WARNING: Cuong.vu already has permission.';
END
ELSE
    PRINT '   ERROR: No ObjectID found.';
GO

-- ============================================================
-- PHASE H: Refresh menu cache
-- ============================================================
PRINT '--- Phase H: Refresh menu cache ---';
GO

EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_UserManagement';
PRINT '   OK sp_Men_Menu_AfterSave_Simple executed.';
GO

-- ============================================================
-- FINAL VERIFICATION
-- ============================================================
PRINT '';
PRINT '=== VERIFICATION ===';
PRINT '';
GO

DECLARE @vMuID VARCHAR(100);
SELECT TOP 1 @vMuID = MenuID FROM MEN_Menu WHERE ClassName = 'sp_UserManagement';

SELECT '1_MEN_Menu' AS Chk, MenuID, ClassName, ParentMenuID, IsVisible, glyphicon
FROM MEN_Menu WHERE ClassName = 'sp_UserManagement';

SELECT '2_Object' AS Chk, ObjectID, ObjectName, Description
FROM tblSC_Object WHERE Description = @vMuID;

SELECT '3_Message' AS Chk, MessageID, Language, Content
FROM tblMD_Message WHERE MessageID = @vMuID;

SELECT '4_DataSetting' AS Chk, TableName, IsProcedure, IsShowLayout, ColumnDataType
FROM tblDataSetting WHERE TableName = 'sp_UserManagement';

SELECT '5_Cache' AS Chk, TableName, LanguageID, ScreenType, DATALENGTH(html) AS HtmlBytes, Version
FROM tblHtmlScriptCache WHERE TableName = 'sp_UserManagement_html' ORDER BY LanguageID;

DECLARE @vObjID INT;
SELECT TOP 1 @vObjID = ObjectID FROM tblSC_Object WHERE Description = @vMuID;
SELECT '6_Perm' AS Chk, ObjectID, LoginID, FullAccess
FROM tblSC_Right_Stored WHERE ObjectID = @vObjID;

SELECT '7_ControlMeta' AS Chk, TableName, ColumnName, Type, Layout, SPLoadData, UID
FROM tblCommonControlType_Signed WHERE TableName = 'sp_UserManagement_html' ORDER BY UID;

PRINT '';
PRINT '=== DEPLOY COMPLETE ===';
PRINT 'Logout/login → "Danh sách người dùng" under Bảo mật (MnuSCR000).';
GO
