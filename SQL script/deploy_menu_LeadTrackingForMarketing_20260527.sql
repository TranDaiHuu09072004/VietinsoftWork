-- ===========================================================================
-- Deploy: Menu "Theo dõi lead marketing" (Lead Marketing Tracking)
-- Date:   2026-05-27
-- Scope:  CREATE menu HTML-rendered với dashboard header + infinite scroll grid
--         Dữ liệu: tblCRM_CustomerPersonInfo WHERE IsCRMLead = 1
--         Parent:  MnuKPI000
--         Quyền:   LoginID=3 (admin) + LoginID=40 (huong.pham)
-- ===========================================================================
-- ⚠️ Review kỹ trước khi chạy. Nên backup trước.
-- Yêu cầu: sau khi chạy, user logout/login để thấy menu mới.
-- ===========================================================================

SET NOCOUNT ON;
PRINT '=== START: deploy_menu_LeadTrackingForMarketing ===';
PRINT '';

-- ===========================================================================
-- Phase 1: Thêm cột IsCRMLead vào tblCRM_CustomerPersonInfo
-- ===========================================================================
PRINT '--- Phase 1: Add column IsCRMLead ---';

IF COL_LENGTH('dbo.tblCRM_CustomerPersonInfo', 'IsCRMLead') IS NULL
BEGIN
    ALTER TABLE dbo.tblCRM_CustomerPersonInfo ADD IsCRMLead BIT NULL;
    PRINT '  [+] Added IsCRMLead (bit, nullable) to tblCRM_CustomerPersonInfo';
END
ELSE
    PRINT '  [=] IsCRMLead already exists -- skipped';

-- ===========================================================================
-- Phase 2: Data SP -- sp_LeadTrackingForMarketingList (grid, infinite scroll)
--           Pattern: @TempTableAPIName + #tmpTableData theo Rule 6
-- ===========================================================================
PRINT '--- Phase 2: Create sp_LeadTrackingForMarketingList ---';

GO
CREATE OR ALTER PROCEDURE dbo.sp_LeadTrackingForMarketingList
(
    @LoginID           INT          = 3,
    @LanguageID        VARCHAR(5)   = 'VN',
    @FromDate          DATETIME     = NULL,
    @ToDate            DATETIME     = NULL,
    @TempTableAPIName  VARCHAR(100) = ''
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FromDate IS NULL SET @FromDate = DATEADD(DAY, -30, GETDATE());
    IF @ToDate IS NULL   SET @ToDate   = GETDATE();
    SET @ToDate = DATEADD(SECOND, -1, DATEADD(DAY, 1, CONVERT(DATE, @ToDate)));

    SELECT
        ROW_NUMBER() OVER (ORDER BY c.CreatedDate DESC, c.CRM_CustomerID) AS STT,
        c.CRM_CustomerID,
        ISNULL(c.FullName, N'')        AS FullName,
        ISNULL(c.PhoneNumber, N'')     AS PhoneNumber,
        ISNULL(c.Email, N'')           AS Email,
        ISNULL(c.PhoneNumberZalo, N'') AS PhoneNumberZalo,
        CONVERT(VARCHAR(10), c.CreatedDate, 103) AS CreatedDate,
        ISNULL(c.OwnerID, N'')         AS OwnerID,
        ISNULL(c.Notes, N'')           AS Notes,
        ISNULL(c.StatusID, 0)          AS StatusID
    INTO #tmpTableData
    FROM dbo.tblCRM_CustomerPersonInfo c
    WHERE ISNULL(c.IsCRMLead, 0) = 1
      AND c.CreatedDate >= @FromDate
      AND c.CreatedDate <= @ToDate;

    DECLARE @sql NVARCHAR(MAX) = '';
    IF @TempTableAPIName = ''
        SET @sql = N'SELECT * FROM #tmpTableData';
    ELSE
        SET @sql = N'SELECT * INTO ' + QUOTENAME(@TempTableAPIName) + ' FROM #tmpTableData';
    EXEC sp_executesql @sql;
    DROP TABLE #tmpTableData;
END;
GO
PRINT '  [+] Created sp_LeadTrackingForMarketingList';

-- ===========================================================================
-- Phase 3: Dashboard Stats SP -- sp_LeadTrackingForMarketing_GetStats
-- ===========================================================================
PRINT '--- Phase 3: Create sp_LeadTrackingForMarketing_GetStats ---';

GO
CREATE OR ALTER PROCEDURE dbo.sp_LeadTrackingForMarketing_GetStats
(
    @LoginID    INT        = 3,
    @LanguageID VARCHAR(5) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        COUNT(*) AS TotalLeads,
        SUM(CASE WHEN c.CreatedDate >= DATEADD(MONTH, -1, GETDATE()) THEN 1 ELSE 0 END) AS NewLeadsThisMonth,
        SUM(CASE WHEN c.CreatedDate >= DATEADD(DAY, -7, GETDATE()) THEN 1 ELSE 0 END)   AS NewLeadsThisWeek
    FROM dbo.tblCRM_CustomerPersonInfo c
    WHERE ISNULL(c.IsCRMLead, 0) = 1;
END;
GO
PRINT '  [+] Created sp_LeadTrackingForMarketing_GetStats';

-- ===========================================================================
-- Phase 4: Renderer -- sp_LeadTrackingForMarketing_html
--           Dashboard header + Filter bar (from date - to date)
--           + Infinite scroll dxDataGrid (Rule 6)
-- ===========================================================================
PRINT '--- Phase 4: Create sp_LeadTrackingForMarketing_html ---';

GO
CREATE OR ALTER PROCEDURE dbo.sp_LeadTrackingForMarketing_html
(
    @LoginID    INT        = 3,
    @LanguageID VARCHAR(2) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @html NVARCHAR(MAX) = '';

    SET @html = N'
<div id="sp_LeadTrackingForMarketing_html" style="display:flex;flex-direction:column;height:100%;padding:8px;box-sizing:border-box;">

<!-- ====== Filter Bar (trên đầu) ====== -->
<div id="filterBarLead" style="display:flex;gap:8px;align-items:center;margin-bottom:12px;flex-shrink:0;flex-wrap:wrap;background:#f8f9fa;padding:8px 12px;border-radius:6px;border:1px solid #e0e0e0;">
    <span style="font-weight:600;font-size:13px;color:#333;">'
    + CASE WHEN @LanguageID='VN' THEN N'Từ ngày:' ELSE 'From:' END + N'</span>
    <input type="text" id="filterFromDate" class="datepicker-lead" style="width:130px;padding:6px 8px;border:1px solid #ccc;border-radius:4px;font-size:13px;" />
    <span style="font-weight:600;font-size:13px;color:#333;">'
    + CASE WHEN @LanguageID='VN' THEN N'Đến ngày:' ELSE 'To:' END + N'</span>
    <input type="text" id="filterToDate" class="datepicker-lead" style="width:130px;padding:6px 8px;border:1px solid #ccc;border-radius:4px;font-size:13px;" />
    <button id="btnApplyFilter" style="background:#667eea;color:#fff;border:none;padding:6px 16px;border-radius:4px;cursor:pointer;font-size:13px;font-weight:600;">'
    + CASE WHEN @LanguageID='VN' THEN N'Lọc' ELSE 'Filter' END + N'</button>
    <button id="btnResetFilter" style="background:#6c757d;color:#fff;border:none;padding:6px 16px;border-radius:4px;cursor:pointer;font-size:13px;">'
    + CASE WHEN @LanguageID='VN' THEN N'Reset' ELSE 'Reset' END + N'</button>
</div>

<!-- ====== Dashboard Header ====== -->
<div id="dashboardLeadMarketing" style="display:flex;gap:16px;margin-bottom:12px;flex-shrink:0;flex-wrap:wrap;">
    <div class="stat-card" style="flex:1;min-width:180px;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:#fff;border-radius:8px;padding:16px;box-shadow:0 2px 8px rgba(0,0,0,0.12);">
        <div style="font-size:13px;opacity:0.85;">'
        + CASE WHEN @LanguageID='VN' THEN N'Tổng số Lead' ELSE 'Total Leads' END + N'</div>
        <div style="font-size:32px;font-weight:700;margin-top:4px;" id="valTotalLeads">--</div>
    </div>
    <div class="stat-card" style="flex:1;min-width:180px;background:linear-gradient(135deg,#f093fb 0%,#f5576c 100%);color:#fff;border-radius:8px;padding:16px;box-shadow:0 2px 8px rgba(0,0,0,0.12);">
        <div style="font-size:13px;opacity:0.85;">'
        + CASE WHEN @LanguageID='VN' THEN N'Tháng này' ELSE 'This Month' END + N'</div>
        <div style="font-size:32px;font-weight:700;margin-top:4px;" id="valLeadsThisMonth">--</div>
    </div>
    <div class="stat-card" style="flex:1;min-width:180px;background:linear-gradient(135deg,#4facfe 0%,#00f2fe 100%);color:#fff;border-radius:8px;padding:16px;box-shadow:0 2px 8px rgba(0,0,0,0.12);">
        <div style="font-size:13px;opacity:0.85;">'
        + CASE WHEN @LanguageID='VN' THEN N'Tuần này' ELSE 'This Week' END + N'</div>
        <div style="font-size:32px;font-weight:700;margin-top:4px;" id="valLeadsThisWeek">--</div>
    </div>
</div>

<!-- ====== Grid Container ====== -->
<div id="GridLeadTracking" style="flex:1;min-height:0;"></div>

</div>

<script>
(function() {
    var _currentKeyword = "";
    var _pageCache = {};
    var _fromDate = null;
    var _toDate = null;

    function loadDashboardStats() {
        AjaxHPAParadise({
            data: {
                name: "sp_LeadTrackingForMarketing_GetStats",
                param: ["LoginID", window.UserID || window.LoginID, "LanguageID", window.LanguageID]
            },
            success: function(res) {
                var json = typeof res === "string" ? JSON.parse(res) : res;
                var stats = (json && json.data && json.data[0] && json.data[0][0]) || {};
                document.getElementById("valTotalLeads").textContent = (stats.TotalLeads || 0).toLocaleString();
                document.getElementById("valLeadsThisMonth").textContent = (stats.NewLeadsThisMonth || 0).toLocaleString();
                document.getElementById("valLeadsThisWeek").textContent = (stats.NewLeadsThisWeek || 0).toLocaleString();
            }
        });
    }

    var dataStore = new DevExpress.data.CustomStore({
        key: "CRM_CustomerID",
        load: function(loadOptions) {
            var deferred = $.Deferred();
            var params = [];
            params.push("@ProcName", "sp_LeadTrackingForMarketingList");
            params.push("@ProcParam", "@LoginID=" + (window.UserID || window.LoginID) + ", @LanguageID=" + window.LanguageID);
            params.push("@Take", loadOptions.take || 50);
            params.push("@Skip", loadOptions.skip || 0);

            if (loadOptions.requireTotalCount) params.push("@RequireTotalCount", 1);

            var sort = loadOptions.sort
                ? loadOptions.sort.map(function(s) { return s.selector + (s.desc ? " DESC" : " ASC"); }).join(",")
                : "STT";
            params.push("@Sort", "ORDER BY " + sort);

            if (_currentKeyword) {
                params.push("@SearchValue", _currentKeyword);
                params.push("@ColumnSearch", "FullName,PhoneNumber,Email");
            }

            if (loadOptions.filter) {
                var hasFunction = false;
                try {
                    hasFunction = JSON.stringify(loadOptions.filter, function(key, val) {
                        if (typeof val === "function") return "FUNCTION";
                        return val;
                    }).indexOf("FUNCTION") >= 0;
                } catch(e) {}
                if (!hasFunction) params.push("@Filters", createConditionQuery(loadOptions.filter));
            }

            if (_fromDate) params.push("@FromDate", _fromDate);
            if (_toDate)   params.push("@ToDate", _toDate);

            AjaxHPAParadise({
                data: { name: "sp_LoadGridUsingAPI", param: params },
                success: function(res) {
                    var json = typeof res === "string" ? JSON.parse(res) : res;
                    var results = Array.isArray(json && json.data && json.data[0]) ? json.data[0] : [];
                    var result = { data: results };
                    if (loadOptions.requireTotalCount) {
                        result.totalCount = (json && json.data && json.data[1] && json.data[1][0] && json.data[1][0].TotalCount) || 0;
                    }
                    deferred.resolve(result);
                },
                error: function() { deferred.reject("Data Loading Error"); }
            });
            return deferred.promise();
        }
    });

    var gridElement = document.getElementById("GridLeadTracking");
    var gridInstance = $(gridElement).dxDataGrid({
        dataSource: dataStore,
        remoteOperations: { paging: true, filtering: true, sorting: true, searching: true },
        scrolling: { mode: "infinite", rowRenderingMode: "virtual", preloadEnabled: false },
        paging: { enabled: true, pageSize: 50 },
        pager: { visible: false },
        searchPanel: {
            visible: true,
            placeholder: "' + CASE WHEN @LanguageID='VN' THEN N'Tìm kiếm...' ELSE 'Search...' END + N'",
            highlightSearchText: false
        },
        columns: [
            { dataField: "STT",              caption: "STT",              width: 50,  allowFiltering: false },
            { dataField: "FullName",         caption: "' + CASE WHEN @LanguageID='VN' THEN N'Họ tên'      ELSE 'Full Name' END + N'",    width: 180 },
            { dataField: "PhoneNumber",      caption: "' + CASE WHEN @LanguageID='VN' THEN N'SĐT'         ELSE 'Phone' END + N'",        width: 120 },
            { dataField: "Email",            caption: "Email",                                                width: 200 },
            { dataField: "PhoneNumberZalo",  caption: "Zalo",                                                 width: 120 },
            { dataField: "CreatedDate",      caption: "' + CASE WHEN @LanguageID='VN' THEN N'Ngày tạo'   ELSE 'Created Date' END + N'", width: 110, allowFiltering: false },
            { dataField: "OwnerID",          caption: "' + CASE WHEN @LanguageID='VN' THEN N'Phụ trách'  ELSE 'Owner' END + N'",       width: 100 },
            { dataField: "StatusID",         caption: "' + CASE WHEN @LanguageID='VN' THEN N'Trạng thái' ELSE 'Status' END + N'",     width: 100 }
        ],
        height: function() {
            var el = document.getElementById("GridLeadTracking");
            if (!el) return 400;
            return Math.max(300, window.innerHeight - el.getBoundingClientRect().top - 30);
        },
        onOptionChanged: function(e) {
            if (e.name === "searchPanel" && e.fullName === "searchPanel.text") {
                _currentKeyword = (e.value || "").trim();
                _pageCache = {};
            }
        }
    }).dxDataGrid("instance");

    function applyFilter() {
        _fromDate = document.getElementById("filterFromDate").value || null;
        _toDate   = document.getElementById("filterToDate").value || null;
        _pageCache = {};
        gridInstance.refresh();
        loadDashboardStats();
    }

    function resetFilter() {
        document.getElementById("filterFromDate").value = "";
        document.getElementById("filterToDate").value = "";
        _fromDate = null;
        _toDate = null;
        _pageCache = {};
        gridInstance.refresh();
        loadDashboardStats();
    }

    document.getElementById("btnApplyFilter").addEventListener("click", applyFilter);
    document.getElementById("btnResetFilter").addEventListener("click", resetFilter);

    try { $(".datepicker-lead").datepicker({ dateFormat: "dd/mm/yy" }); } catch(e) {}

    loadDashboardStats();
})();
</script>
';

    SELECT @html AS html;
END;
GO
PRINT '  [+] Created sp_LeadTrackingForMarketing_html';

-- ===========================================================================
-- Phase 5: Wrapper -- sp_LeadTrackingForMarketing (đọc từ cache)
-- ===========================================================================
PRINT '--- Phase 5: Create sp_LeadTrackingForMarketing ---';

GO
CREATE OR ALTER PROCEDURE dbo.sp_LeadTrackingForMarketing
(
    @LoginID    INT        = 3,
    @LanguageID VARCHAR(2) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 [html] AS html
    FROM dbo.tblHtmlScriptCache
    WHERE TableName  = 'sp_LeadTrackingForMarketing_html'
      AND ScreenType = '-1'
      AND LanguageID = @LanguageID;
END;
GO
PRINT '  [+] Created sp_LeadTrackingForMarketing';

-- ===========================================================================
-- Phase 6: Menu metadata + tblDataSetting + tblDataSettingLayout
-- ===========================================================================
PRINT '--- Phase 6: Create menu metadata ---';

DECLARE @NewMenuID VARCHAR(20);

-- Tự sinh MenuID: MAX số sau 6 ký tự đầu trong nhóm MnuKPI
SELECT @NewMenuID = 'MnuKPI' + RIGHT('000' + CAST(ISNULL(
    (SELECT MAX(CAST(SUBSTRING(MenuID, 7, LEN(MenuID)-6) AS INT))
     FROM MEN_Menu WHERE MenuID LIKE 'MnuKPI%'
       AND ISNUMERIC(SUBSTRING(MenuID, 7, LEN(MenuID)-6)) = 1), 0) + 1 AS VARCHAR(3)), 3);

PRINT '  Generated MenuID: ' + @NewMenuID;

IF EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = @NewMenuID)
BEGIN
    PRINT '  [!!] MenuID ' + @NewMenuID + ' already exists -- manual review needed';
    RETURN;
END

EXEC dbo.sp_s_CreateMenu
     @Text         = N'Theo dõi lead marketing',
     @TextEN       = N'Lead Marketing Tracking',
     @ClassName    = 'sp_LeadTrackingForMarketing',
     @ParentMenuID = 'MnuKPI000',
     @AssemblyName = 'DataSetting',
     @Option       = 1,
     @LoginIDList  = '3';

-- Lấy MenuID thực tế vừa được sp_s_CreateMenu tạo
DECLARE @CreatedMenuID VARCHAR(20);
SELECT @CreatedMenuID = MenuID FROM MEN_Menu
WHERE ClassName = 'sp_LeadTrackingForMarketing' AND ParentMenuID = 'MnuKPI000';

PRINT '  [+] sp_s_CreateMenu done, MenuID = ' + ISNULL(@CreatedMenuID, 'NULL');

-- ===========================================================================
-- Phase 7: tblDataSetting (Rule 4 -- 1 row)
-- ===========================================================================
PRINT '--- Phase 7: tblDataSetting ---';

IF NOT EXISTS (SELECT 1 FROM tblDataSetting WHERE TableName = 'sp_LeadTrackingForMarketing')
BEGIN
    INSERT INTO tblDataSetting (TableName, ViewName, AllowAdd, IsProcedure, IsShowLayout,
        LoadDataAfterShow, AllowDelete, ColumnOrderBy, ColumnDataType,
        ColumnHide, ControlHiddenInShowLayout)
    VALUES ('sp_LeadTrackingForMarketing',
            'sp_LeadTrackingForMarketing',
            0, 1, 1, 1, 1,
            'html&0',
            'html&ViewHtml',
            'isReadOnlyRow,dtftxxENGColumns',
            'grdTableEditor,txtFilter,btnReload,btnFWDelete,btnFWReset,btnExport,btnFWSave,btnFWAdd,isReadOnlyRow,dtftxxENGColumns');
    PRINT '  [+] Inserted tblDataSetting';
END
ELSE
    PRINT '  [=] tblDataSetting already exists';

-- ===========================================================================
-- Phase 8: tblDataSettingLayout (Rule 4 -- 2 rows BẮT BUỘC)
-- ===========================================================================
PRINT '--- Phase 8: tblDataSettingLayout ---';

IF NOT EXISTS (SELECT 1 FROM tblDataSettingLayout WHERE TableName = 'sp_LeadTrackingForMarketing' AND Name = 'root')
BEGIN
    INSERT INTO tblDataSettingLayout (TableName, Name, ControlName, NamePa, Type, Sx, Sy, ShowCaption, Padding,
        TextLocation, TypeLayout, WidthPercentage, ControlType)
    VALUES ('sp_LeadTrackingForMarketing', 'root', '', '', 'g', 1620, 929, 0, 0, 'top', '6', 100, '');
    PRINT '  [+] Inserted tblDataSettingLayout -- root';
END
ELSE
    PRINT '  [=] tblDataSettingLayout root already exists';

IF NOT EXISTS (SELECT 1 FROM tblDataSettingLayout WHERE TableName = 'sp_LeadTrackingForMarketing' AND Name = 'lblhtml')
BEGIN
    INSERT INTO tblDataSettingLayout (TableName, Name, ControlName, NamePa, Type, Sx, Sy, ShowCaption, Padding,
        TextLocation, TypeLayout, WidthPercentage, ControlType)
    VALUES ('sp_LeadTrackingForMarketing', 'lblhtml', 'html', 'root', 'i', 1620, 929, 0, 0, 'default', '6', 100, 'ParadiseWebView2');
    PRINT '  [+] Inserted tblDataSettingLayout -- lblhtml';
END
ELSE
    PRINT '  [=] tblDataSettingLayout lblhtml already exists';

-- ===========================================================================
-- Phase 9: Cập nhật cờ MEN_Menu (Rule 2)
-- ===========================================================================
PRINT '--- Phase 9: Update MEN_Menu flags (Rule 2) ---';

UPDATE MEN_Menu
SET IsVisible             = 1,
    IsWeb                 = 0,
    ViewOnWeb             = 0,
    isShowLayOutWeb       = 0,
    isShowInMobileLayOut  = 0,
    IsUseMobileDevice     = 1,
    Priority              = 99,
    glyphicon             = N'fa fa-user-circle',
    GroupID               = 'MnuKPI000'
WHERE ClassName = 'sp_LeadTrackingForMarketing'
  AND ParentMenuID = 'MnuKPI000';

PRINT '  [+] Updated MEN_Menu flags for ' + ISNULL(@CreatedMenuID, '?');

-- ===========================================================================
-- Phase 10: Build cache HTML
-- ===========================================================================
PRINT '--- Phase 10: Build HTML cache ---';

DELETE FROM tblHtmlScriptCache WHERE TableName = 'sp_LeadTrackingForMarketing_html';
EXEC dbo.sp_GenerateHTMLScript 'sp_LeadTrackingForMarketing_html';
PRINT '  [+] Built HTML cache via sp_GenerateHTMLScript';

-- ===========================================================================
-- Phase 11: Phân quyền (Rule 1)
--           CHÚ Ý: ObjectID trong tblSC_Right_Stored là int (từ tblSC_Object.ObjectID),
--           KHÔNG phải MenuID (varchar). sp_s_CreateMenu đã tự cấp cho LoginID=3.
-- ===========================================================================
PRINT '--- Phase 11: Grant permissions ---';

DECLARE @ObjID INT;
SELECT @ObjID = ObjectID FROM tblSC_Object
WHERE ObjectName = 'DataSetting.sp_LeadTrackingForMarketing';

-- Admin (LoginID=3) — sp_s_CreateMenu đã tự làm với @LoginIDList='3', verify lại
IF NOT EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID = @ObjID AND LoginID = 3)
BEGIN
    INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@ObjID, 3, '32');
    PRINT '  [+] Granted FullAccess to LoginID=3 (admin)';
END
ELSE
    PRINT '  [=] LoginID=3 already granted by sp_s_CreateMenu';

-- huong.pham (LoginID=40)
IF NOT EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID = @ObjID AND LoginID = 40)
BEGIN
    INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@ObjID, 40, '32');
    PRINT '  [+] Granted FullAccess to LoginID=40 (huong.pham)';
END
ELSE
BEGIN
    UPDATE tblSC_Right_Stored SET FullAccess = '32' WHERE ObjectID = @ObjID AND LoginID = 40;
    PRINT '  [=] LoginID=40 already granted -- updated';
END

-- ===========================================================================
-- Phase 12: Refresh menu cache
-- ===========================================================================
PRINT '--- Phase 12: Refresh menu cache ---';

EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_LeadTrackingForMarketing';
PRINT '  [+] Menu cache refreshed';

PRINT '';
PRINT '=== END: deploy_menu_LeadTrackingForMarketing ===';
PRINT '=== User: logout/login để thấy menu mới. ===';
PRINT '=== Sau đó: vào tblCRM_CustomerPersonInfo, set IsCRMLead=1 cho các dòng cần theo dõi. ===';
