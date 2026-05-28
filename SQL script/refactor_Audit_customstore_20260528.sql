-- Refactor sp_Report_UserPermissionAudit_html → CustomStore + sp_LoadGridUsingAPI
-- Pattern: 17_RendererHtmlJsSafe §4.1
USE [Paradise_Dev];
GO

-- ============================================================
-- 1. Sửa SP data: thêm @TempTableAPIName để sp_LoadGridUsingAPI dùng được
-- ============================================================
ALTER PROCEDURE [dbo].[sp_Report_UserPermissionAudit_GetSummary]
    @LoginID           INT          = 3,
    @LanguageID        VARCHAR(5)   = 'VN',
    @TempTableAPIName  VARCHAR(100) = ''
AS
BEGIN
    SET NOCOUNT ON;

    SELECT l.LoginID,
           ISNULL(l.LoginName, N'(NULL)')                                   AS LoginName,
           ISNULL(l.EmployeeID, N'—')                                       AS EmployeeID,
           CASE WHEN l.IsDisable = 1  THEN N'Đã khóa'
                WHEN l.IsLockout = 1 THEN N'Đã Lockout'
                ELSE N'Hoạt động'
           END                                                              AS StatusDisplay,
           CASE WHEN l.isAdmin = 1            THEN N'Yes' ELSE N'No' END    AS IsAdmin,
           CASE WHEN l.IsHRManager = 1        THEN N'Yes' ELSE N'No' END    AS IsHRManager,
           CASE WHEN l.AlwaysFullAccess = 1   THEN N'Yes' ELSE N'No' END    AS AlwaysFullAccess,
           ISNULL(dc.DirectCount, 0)                                        AS DirectPermCount,
           ISNULL(gn.GroupNames, N'—')                                      AS GroupNames
    INTO #tmpTableData
    FROM tblSC_Login l
    OUTER APPLY (
        SELECT COUNT(*) AS DirectCount
        FROM tblSC_Right_Stored rs
        WHERE rs.LoginID = l.LoginID
    ) dc
    OUTER APPLY (
        SELECT STRING_AGG(urg.UserGroupName, N', ') AS GroupNames
        FROM tblUserGrantGroup ug
        INNER JOIN tblUserRightGroup urg ON urg.UserGroupID = ug.UserGroupID
        WHERE ug.UserID = CAST(l.LoginID AS varchar)
    ) gn;

    DECLARE @sql NVARCHAR(MAX) = '';
    IF @TempTableAPIName = ''
        SET @sql = N'SELECT * FROM #tmpTableData ORDER BY LoginName';
    ELSE
        SET @sql = N'SELECT * INTO ' + QUOTENAME(@TempTableAPIName) + ' FROM #tmpTableData';
    EXEC sp_executesql @sql;
    DROP TABLE #tmpTableData;
END;
GO

ALTER PROCEDURE dbo.sp_Report_UserPermissionAudit_html
    @LoginID    INT          = 3,
    @LanguageID VARCHAR(5)   = 'VN',
    @isWeb      INT          = 1
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SQ NCHAR(1) = CHAR(39);

    -- Layer 2: Text labels VN/EN
    DECLARE @title      NVARCHAR(200), @lblAccount NVARCHAR(100),
            @lblLoading NVARCHAR(100), @lblError   NVARCHAR(200);

    IF @LanguageID = 'EN'
        SELECT @title = N'User Permission Audit Report',
               @lblAccount = N'Account',
               @lblLoading = N'Loading...',
               @lblError   = N'Error loading data.';
    ELSE
        SELECT @title = N'Báo cáo phân quyền người dùng',
               @lblAccount = N'Tài khoản',
               @lblLoading = N'Đang tải...',
               @lblError   = N'Lỗi tải dữ liệu.';

    DECLARE @html NVARCHAR(MAX) = N'';

    -- CSS
    SET @html = @html + N'
<style>
    .pua-page { padding: var(--paradise-space-4); font-family: var(--paradise-font-family-base); color: var(--paradise-text-body); max-width: 1500px; margin: 0 auto; }
    .pua-header { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: var(--paradise-space-3); margin-bottom: var(--paradise-space-4); }
    .pua-title { font-size: 1.4rem; font-weight: 700; color: var(--paradise-color-header1); margin: 0; }
    .pua-toolbar { display: flex; align-items: center; gap: var(--paradise-space-3); }
    .pua-toolbar-label { font-weight: 500; white-space: nowrap; }
    .pua-detail { margin-top: var(--paradise-space-4); }
    .pua-detail-empty { text-align: center; padding: 40px; color: var(--paradise-text-muted); }
    .dx-scrollbar-horizontal .dx-scrollable-scroll { height: 4px !important; }
    .dx-scrollbar-horizontal .dx-scrollable-scroll-content { height: 4px !important; }
    #GridAccountSummary .dx-toolbar-before .dx-item:first-of-type { display: none !important; }
</style>';

    -- HTML shell
    SET @html = @html + N'
<div class="pua-page">
    <div class="pua-header">
        <h1 class="pua-title">' + @title + N'</h1>
        <div class="pua-toolbar">
            <label class="pua-toolbar-label">' + @lblAccount + N':</label>
            <div id="PAUDITSEL00000000000000000000001"></div>
        </div>
    </div>
    <div id="GridAccountSummary" style="height:520px;"></div>
    <div id="puaDetail" class="pua-detail">
        <div class="pua-detail-empty">&#x2190; ' + CASE WHEN @LanguageID='EN' THEN N'Select an account or click a grid row to view details' ELSE N'Chọn tài khoản hoặc click vào dòng trong lưới để xem chi tiết' END + N'</div>
    </div>
</div>';

    -- JavaScript
    SET @html = @html + N'
<script>(() => {
    let _showtoolbarGrid_PAUDITGRD00000000000000000000001 = true;
    let _showtoolbarAdd_PAUDITGRD00000000000000000000001  = false;
    var api = true;
    var DataSource = [];
    var _pageCache = {};
    var _currentKeyword = "";
    var dataStore_GridAccountSummary = null;

    function esc(v) {
        if (v === null || v === undefined) return "";
        return String(v).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/' + @SQ + N'/g, "&#039;");
    }

    // ===== Polyfill helpers =====
    if (typeof window.LoginID === "undefined")    window.LoginID    = ' + CAST(@LoginID AS NVARCHAR(20)) + N';
    if (typeof window.LanguageID === "undefined") window.LanguageID = "' + @LanguageID + N'";
    if (typeof window.loadDataSourceCommon === "undefined") {
        window.loadDataSourceCommon = function(columnName, dataSourceSP, cb) {
            AjaxHPAParadise({
                data: { name: dataSourceSP, param: ["LoginID", window.LoginID, "LanguageID", window.LanguageID] },
                success: function(res) {
                    var json = typeof res === "string" ? JSON.parse(res) : res;
                    var data = (json && json.data && json.data[0]) || [];
                    window["DataSource_" + columnName] = data;
                    if (json && json.dataSchema && json.dataSchema[0]) {
                        window["DataSourceIDField_"   + columnName] = json.dataSchema[0][0] && json.dataSchema[0][0].name;
                        window["DataSourceNameField_" + columnName] = json.dataSchema[0][1] && json.dataSchema[0][1].name;
                    }
                    if (typeof cb === "function") cb(data, json);
                }
            });
        };
    }
    if (typeof window.hpaUtils === "undefined") {
        window.hpaUtils = { loadAvatar: function(){}, highlightText: function(t,s){ return t; } };
    }
    if (typeof window.RemoveToneMarks_Js === "undefined") {
        window.RemoveToneMarks_Js = function(s) {
            return String(s||"").normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase();
        };
    }
    if (typeof window.uiManager === "undefined") {
        window.uiManager = { showAlert: function(opt){ console.warn(opt); } };
    }

    // ===== Callback: SelectBox onChange → load detail =====
    window["onSelectBoxChanged_TargetLoginID"] = function(value, instance, e) {
        if (value) { puaLoadDetail(value); }
    };

    // ===== Load detail HTML =====
    function puaLoadDetail(targetLoginID) {
        var detail = document.getElementById("puaDetail");
        if (!detail) return;
        detail.innerHTML = "<p style=\"padding:20px;color:var(--paradise-text-muted);\">' + @lblLoading + N'</p>";
        AjaxHPAParadise({
            data: {
                name: "sp_Report_UserPermissionAudit_GetDetail",
                param: ["LoginID", window.LoginID, "TargetLoginID", targetLoginID, "LanguageID", window.LanguageID]
            },
            success: function(res) {
                var json = typeof res === "string" ? JSON.parse(res) : res;
                var result = (json && json.data && json.data[0] && json.data[0].length > 0)
                    ? json.data[0][0].DetailHtml
                    : null;
                detail.innerHTML = result || "<p class=\"pua-detail-empty\">' + @lblError + N'</p>";
            },
            error: function() {
                detail.innerHTML = "<p class=\"pua-detail-empty\">' + @lblError + N'</p>";
            }
        });
    }

    // ============================================================
    // 1. HÀM CỤC BỘ (add + openDetail)
    // ============================================================
    function openDetailLoginID(rowData) {
        if (rowData && rowData.LoginID) {
            window.currentClicked_GridAccountSummary = rowData.LoginID;
            window.currentRecordID_LoginID = rowData.LoginID;
            puaLoadDetail(rowData.LoginID);
        }
    }

    // ============================================================
    // 2. CUSTOMSTORE CHUẨN (sp_LoadGridUsingAPI → search server-side)
    // ============================================================
    dataStore_GridAccountSummary = new DevExpress.data.CustomStore({
        key: "LoginID",
        load: function(loadOptions) {
            var deferred = $.Deferred();

            if (!api) {
                var results = DataSource || [];
                var skip = loadOptions.skip || 0;
                var take = loadOptions.take || 50;
                var pageData = results.slice(skip, skip + take);
                deferred.resolve({ data: pageData, totalCount: results.length });
                api = true;
                return deferred.promise();
            }

            var params = [];
            params.push("@ProcName", "sp_Report_UserPermissionAudit_GetSummary");
            var procParam = "@LoginID=" + (window.UserID || window.LoginID) + ",@LanguageID=" + window.LanguageID;
            params.push("@ProcParam", procParam);
            params.push("@Take", loadOptions.take || 50);
            params.push("@Skip", loadOptions.skip || 0);

            if (loadOptions.requireTotalCount) params.push("@RequireTotalCount", 1);

            var sort = loadOptions.sort
                ? loadOptions.sort.map(s => s.selector + (s.desc ? " DESC" : " ASC")).join(",")
                : "";
            params.push("@Sort", sort != "" ? "ORDER BY " + sort : "");

            if (_currentKeyword) {
                params.push("@SearchValue", _currentKeyword);
                params.push("@ColumnSearch", "LoginName,EmployeeID");
            }

            if (loadOptions.filter) {
                var hasFunction = JSON.stringify(loadOptions.filter, (k, v) => typeof v === "function" ? "FUNCTION" : v).includes("FUNCTION");
                if (!hasFunction) params.push("@Filters", createConditionQuery(loadOptions.filter));
            }

            AjaxHPAParadise({
                data: { name: "sp_LoadGridUsingAPI", param: params },
                success: function(res) {
                    var json = typeof res === "string" ? JSON.parse(res) : res;
                    var results = Array.isArray(json?.data?.[0]) ? json.data[0] : [];
                    var result = { data: results };

                    if (loadOptions.requireTotalCount) {
                        result.totalCount = json?.data?.[1]?.[0]?.TotalCount ?? 0;
                    }

                    DataSource = results;
                    window.syncSharedGridData("GridAccountSummary");
                    deferred.resolve(result);
                },
                error: function() { deferred.reject("Data Loading Error"); }
            });

            return deferred.promise();
        }
    });

    // ============================================================
    // 3. RELOAD
    // ============================================================
    function ReloadData() {
        _pageCache = {};
        var gridInst = InstanceGridAccountSummaryPAUDITGRD00000000000000000000001;
        if (gridInst) { gridInst.refresh(); }
    }

    // ============================================================
    // 4. INJECT loadUI + CẤU HÌNH GRID
    // ============================================================ '
    + ISNULL((SELECT loadUI FROM tblCommonControlType_Signed WHERE UID = N'PAUDITSEL00000000000000000000001'), N'')
    + N'
    '
    + ISNULL((SELECT loadUI FROM tblCommonControlType_Signed WHERE UID = N'PAUDITGRD00000000000000000000001'), N'')
    + N'

    // ============================================================
    // 5. CẤU HÌNH GRID
    // ============================================================
    try {
        var gi = $("#GridAccountSummary").dxDataGrid("instance");
        if (gi) {
            gi.beginUpdate();
            gi.option("remoteOperations", { paging: true, filtering: true, sorting: true, searching: true });
            gi.option({
                "scrolling.mode": "infinite",
                "scrolling.rowRenderingMode": "virtual",
                "scrolling.preloadEnabled": false,
                "scrolling.showScrollbar": "onHover",
                "scrolling.useNative": false,
                "paging.enabled": false,
                "paging.pageSize": 50,
                "pager.visible": false,
                "searchPanel.highlightSearchText": false,
                "columnAutoWidth": true,
                "dataSource": dataStore_GridAccountSummary,
                "height": 520
            });
            gi.option("onOptionChanged", function(e) {
                if (e.name === "searchPanel" && e.fullName === "searchPanel.text") {
                    _currentKeyword = (e.value || "").trim();
                    _pageCache = {};
                }
            });
            gi.endUpdate();
        }
    } catch(e) {}

    ReloadData()
})();</script>';

    SELECT @html AS html;
END;
GO

EXEC sptblCommonControlType_Signed_DUC 'sp_Report_UserPermissionAudit_html';
EXEC sp_GenerateHTMLScript 'sp_Report_UserPermissionAudit_html';
EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_Report_UserPermissionAudit';
