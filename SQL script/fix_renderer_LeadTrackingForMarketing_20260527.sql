-- ===========================================================================
-- Fix: Renderer + Wrapper chuẩn ParadiseHR (17_RendererHtmlJsSafe 6-layer anatomy)
-- Date: 2026-05-27
-- Run: sqlcmd -S "192.168.11.51,2222" -U "vts.sa" -P "LuaThieng1@3@2020" -d "Paradise_Dev" -I -x -i "..."
-- ===========================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
PRINT '=== START: fix_renderer_LeadTrackingForMarketing ===';
PRINT '';

-- ===========================================================================
-- Fix 1: Wrapper — sửa TableName (bỏ _html suffix)
-- ===========================================================================
PRINT '--- Fix 1: Wrapper sp_LeadTrackingForMarketing ---';

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
    WHERE TableName  = 'sp_LeadTrackingForMarketing'
      AND ScreenType = '-1'
      AND LanguageID = @LanguageID;
END;
GO
PRINT '  [+] Wrapper fixed — reads from TableName=sp_LeadTrackingForMarketing';

-- ===========================================================================
-- Fix 2: Renderer — 6-layer anatomy chuẩn
-- ===========================================================================
PRINT '--- Fix 2: Renderer sp_LeadTrackingForMarketing_html (6-layer) ---';

GO
CREATE OR ALTER PROCEDURE dbo.sp_LeadTrackingForMarketing_html
(
    @LoginID    INT         = 3,
    @LanguageID VARCHAR(5)  = 'VN',
    @isWeb      INT         = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    -- =====================================================================
    -- Layer 2: Text VN/EN
    -- =====================================================================
    DECLARE @lblTotalLeads      NVARCHAR(100),
            @lblThisMonth       NVARCHAR(100),
            @lblThisWeek        NVARCHAR(100),
            @lblFromDate        NVARCHAR(50),
            @lblToDate          NVARCHAR(50),
            @lblFilter          NVARCHAR(50),
            @lblReset           NVARCHAR(50),
            @lblSearch          NVARCHAR(100),
            @lblFullName        NVARCHAR(100),
            @lblPhone           NVARCHAR(100),
            @lblCreatedDate     NVARCHAR(100),
            @lblOwner           NVARCHAR(100),
            @lblStatus          NVARCHAR(100),
            @loading            NVARCHAR(100),
            @errLoad            NVARCHAR(200);

    IF @LanguageID = 'EN'
        SELECT @lblTotalLeads  = N'Total Leads',
               @lblThisMonth   = N'This Month',
               @lblThisWeek    = N'This Week',
               @lblFromDate    = N'From:',
               @lblToDate      = N'To:',
               @lblFilter      = N'Filter',
               @lblReset       = N'Reset',
               @lblSearch      = N'Search...',
               @lblFullName    = N'Full Name',
               @lblPhone       = N'Phone',
               @lblCreatedDate = N'Created Date',
               @lblOwner       = N'Owner',
               @lblStatus      = N'Status',
               @loading        = N'Loading...',
               @errLoad        = N'Data Loading Error';
    ELSE
        SELECT @lblTotalLeads  = N'Tổng số Lead',
               @lblThisMonth   = N'Tháng này',
               @lblThisWeek    = N'Tuần này',
               @lblFromDate    = N'Từ ngày:',
               @lblToDate      = N'Đến ngày:',
               @lblFilter      = N'Lọc',
               @lblReset       = N'Reset',
               @lblSearch      = N'Tìm kiếm...',
               @lblFullName    = N'Họ tên',
               @lblPhone       = N'SĐT',
               @lblCreatedDate = N'Ngày tạo',
               @lblOwner       = N'Phụ trách',
               @lblStatus      = N'Trạng thái',
               @loading        = N'Đang tải...',
               @errLoad        = N'Lỗi tải dữ liệu';
    -- =====================================================================
    -- Layer 3: Biến *Js escape \ + "
    -- =====================================================================
    DECLARE @lblTotalLeadsJs  NVARCHAR(200) = REPLACE(REPLACE(@lblTotalLeads,  N'\', N'\\'), N'"', N'\"');
    DECLARE @lblThisMonthJs   NVARCHAR(200) = REPLACE(REPLACE(@lblThisMonth,   N'\', N'\\'), N'"', N'\"');
    DECLARE @lblThisWeekJs    NVARCHAR(200) = REPLACE(REPLACE(@lblThisWeek,    N'\', N'\\'), N'"', N'\"');
    DECLARE @lblFromDateJs    NVARCHAR(100) = REPLACE(REPLACE(@lblFromDate,    N'\', N'\\'), N'"', N'\"');
    DECLARE @lblToDateJs      NVARCHAR(100) = REPLACE(REPLACE(@lblToDate,      N'\', N'\\'), N'"', N'\"');
    DECLARE @lblFilterJs      NVARCHAR(100) = REPLACE(REPLACE(@lblFilter,      N'\', N'\\'), N'"', N'\"');
    DECLARE @lblResetJs       NVARCHAR(100) = REPLACE(REPLACE(@lblReset,       N'\', N'\\'), N'"', N'\"');
    DECLARE @lblSearchJs      NVARCHAR(200) = REPLACE(REPLACE(@lblSearch,      N'\', N'\\'), N'"', N'\"');
    DECLARE @lblFullNameJs    NVARCHAR(200) = REPLACE(REPLACE(@lblFullName,    N'\', N'\\'), N'"', N'\"');
    DECLARE @lblPhoneJs       NVARCHAR(200) = REPLACE(REPLACE(@lblPhone,       N'\', N'\\'), N'"', N'\"');
    DECLARE @lblCreatedDateJs NVARCHAR(200) = REPLACE(REPLACE(@lblCreatedDate, N'\', N'\\'), N'"', N'\"');
    DECLARE @lblOwnerJs       NVARCHAR(200) = REPLACE(REPLACE(@lblOwner,       N'\', N'\\'), N'"', N'\"');
    DECLARE @lblStatusJs      NVARCHAR(200) = REPLACE(REPLACE(@lblStatus,      N'\', N'\\'), N'"', N'\"');
    DECLARE @errLoadJs        NVARCHAR(400) = REPLACE(REPLACE(@errLoad,        N'\', N'\\'), N'"', N'\"');

    -- =====================================================================
    -- Layer 4: Build @html
    -- =====================================================================
    DECLARE @html NVARCHAR(MAX) = '';

    -- HTML structure
    SET @html = N'
<div id="sp_LeadTrackingForMarketing_html" style="display:flex;flex-direction:column;height:100%;padding:8px;box-sizing:border-box;">

<!-- ====== Filter Bar (trên đầu) ====== -->
<div id="filterBarLead" style="display:flex;gap:8px;align-items:center;margin-bottom:12px;flex-shrink:0;flex-wrap:wrap;background:#f8f9fa;padding:8px 12px;border-radius:6px;border:1px solid #e0e0e0;">
    <span style="font-weight:600;font-size:13px;color:#333;">'
    + @lblFromDate + N'</span>
    <input type="text" id="filterFromDate" class="datepicker-lead" style="width:130px;padding:6px 8px;border:1px solid #ccc;border-radius:4px;font-size:13px;" />
    <span style="font-weight:600;font-size:13px;color:#333;">'
    + @lblToDate + N'</span>
    <input type="text" id="filterToDate" class="datepicker-lead" style="width:130px;padding:6px 8px;border:1px solid #ccc;border-radius:4px;font-size:13px;" />
    <button id="btnApplyFilter" style="background:#667eea;color:#fff;border:none;padding:6px 16px;border-radius:4px;cursor:pointer;font-size:13px;font-weight:600;">'
    + @lblFilter + N'</button>
    <button id="btnResetFilter" style="background:#6c757d;color:#fff;border:none;padding:6px 16px;border-radius:4px;cursor:pointer;font-size:13px;">'
    + @lblReset + N'</button>
</div>

<!-- ====== Dashboard Header ====== -->
<div id="dashboardLeadMarketing" style="display:flex;gap:16px;margin-bottom:12px;flex-shrink:0;flex-wrap:wrap;">
    <div class="stat-card" style="flex:1;min-width:180px;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:#fff;border-radius:8px;padding:16px;box-shadow:0 2px 8px rgba(0,0,0,0.12);">
        <div style="font-size:13px;opacity:0.85;">'
        + @lblTotalLeads + N'</div>
        <div style="font-size:32px;font-weight:700;margin-top:4px;" id="valTotalLeads">--</div>
    </div>
    <div class="stat-card" style="flex:1;min-width:180px;background:linear-gradient(135deg,#f093fb 0%,#f5576c 100%);color:#fff;border-radius:8px;padding:16px;box-shadow:0 2px 8px rgba(0,0,0,0.12);">
        <div style="font-size:13px;opacity:0.85;">'
        + @lblThisMonth + N'</div>
        <div style="font-size:32px;font-weight:700;margin-top:4px;" id="valLeadsThisMonth">--</div>
    </div>
    <div class="stat-card" style="flex:1;min-width:180px;background:linear-gradient(135deg,#4facfe 0%,#00f2fe 100%);color:#fff;border-radius:8px;padding:16px;box-shadow:0 2px 8px rgba(0,0,0,0.12);">
        <div style="font-size:13px;opacity:0.85;">'
        + @lblThisWeek + N'</div>
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

    var ERR_MSG  = "' + @errLoadJs + N'";
    var FROM_LBL = "' + @lblFromDateJs + N'";
    var TO_LBL   = "' + @lblToDateJs + N'";
    var FLT_LBL  = "' + @lblFilterJs + N'";
    var RST_LBL  = "' + @lblResetJs + N'";

    function escapeHtml(value) {
        if (value === null || value === undefined) return "";
        return String(value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;").replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    function loadDashboardStats() {
        AjaxHPAParadise({
            data: {
                name: "sp_LeadTrackingForMarketing_GetStats",
                param: ["LoginID", window.UserID || window.LoginID, "LanguageID", window.LanguageID]
            },
            success: function(res) {
                var json = typeof res === "string" ? JSON.parse(res) : res;
                var stats = (json && json.data && json.data[0] && json.data[0][0]) || {};
                document.getElementById("valTotalLeads").textContent     = (stats.TotalLeads || 0).toLocaleString();
                document.getElementById("valLeadsThisMonth").textContent = (stats.NewLeadsThisMonth || 0).toLocaleString();
                document.getElementById("valLeadsThisWeek").textContent  = (stats.NewLeadsThisWeek || 0).toLocaleString();
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
                error: function() { deferred.reject(ERR_MSG); }
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
            placeholder: "' + @lblSearchJs + N'",
            highlightSearchText: false
        },
        columns: [
            { dataField: "STT",              caption: "STT",              width: 50,  allowFiltering: false },
            { dataField: "FullName",         caption: "' + @lblFullNameJs    + N'", width: 180 },
            { dataField: "PhoneNumber",      caption: "' + @lblPhoneJs       + N'", width: 120 },
            { dataField: "Email",            caption: "Email",                  width: 200 },
            { dataField: "PhoneNumberZalo",  caption: "Zalo",                   width: 120 },
            { dataField: "CreatedDate",      caption: "' + @lblCreatedDateJs + N'", width: 110, allowFiltering: false },
            { dataField: "OwnerID",          caption: "' + @lblOwnerJs       + N'", width: 100 },
            { dataField: "StatusID",         caption: "' + @lblStatusJs      + N'", width: 100 }
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

    -- =====================================================================
    -- Layer 5: MERGE tblHtmlScriptCache (8 cột)
    -- =====================================================================
    MERGE dbo.tblHtmlScriptCache AS tgt
    USING (SELECT 'sp_LeadTrackingForMarketing' AS TableName,
                  @LanguageID                   AS LanguageID,
                  '-1'                          AS ScreenType,
                  @html                         AS html,
                  N''                           AS HtmlParadise,
                  N''                           AS paradiseJs,
                  '1'                           AS Version,
                  N''                           AS VersionData) AS src
       ON tgt.TableName  = src.TableName
      AND tgt.LanguageID = src.LanguageID
    WHEN MATCHED THEN
        UPDATE SET tgt.ScreenType   = src.ScreenType,
                   tgt.html         = src.html,
                   tgt.HtmlParadise = src.HtmlParadise,
                   tgt.paradiseJs   = src.paradiseJs,
                   tgt.Version      = src.Version,
                   tgt.VersionData  = src.VersionData
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData)
        VALUES (src.TableName, src.LanguageID, src.ScreenType, src.html, src.HtmlParadise, src.paradiseJs, src.Version, src.VersionData);

    -- =====================================================================
    -- Layer 6: Fallback SELECT
    -- =====================================================================
    SELECT @html AS html;
END;
GO
PRINT '  [+] Renderer rewritten — full 6-layer anatomy';

-- ===========================================================================
-- Fix 3: Rebuild cache
-- ===========================================================================
PRINT '--- Fix 3: Rebuild cache ---';

DELETE FROM dbo.tblHtmlScriptCache WHERE TableName = 'sp_LeadTrackingForMarketing';
PRINT '  [+] Cleared old cache';

EXEC dbo.sp_GenerateHTMLScript 'sp_LeadTrackingForMarketing_html';
PRINT '  [+] Rebuilt cache';

-- ===========================================================================
-- Fix 4: Refresh menu
-- ===========================================================================
PRINT '--- Fix 4: Refresh menu cache ---';

EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_LeadTrackingForMarketing';
PRINT '  [+] Menu refreshed';

-- ===========================================================================
-- Verify
-- ===========================================================================
PRINT '';
PRINT '=== VERIFY ===';
SELECT TableName, LanguageID, ScreenType, DATALENGTH(html) AS HtmlBytes, Version
FROM dbo.tblHtmlScriptCache
WHERE TableName = 'sp_LeadTrackingForMarketing'
ORDER BY LanguageID;

PRINT '';
PRINT '=== END: fix_renderer_LeadTrackingForMarketing ===';
PRINT '=== User: logout/login để thấy menu mới (MnuKPI448) ===';
