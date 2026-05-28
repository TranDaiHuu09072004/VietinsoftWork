-- ============================================================================
-- MIGRATE: MnuKPI448 — Lead Tracking For Marketing
-- Pattern: 13_Migrate_Menu.md Phase E2 — scan toàn bộ dependency
-- Idempotent: chạy nhiều lần không lỗi. Đổi USE <DB> nếu migrate.
-- Ngày: 2026-05-28
-- ============================================================================

-- ============================================================
-- DEPENDENCY MAP (Phase E2 scan)
-- ============================================================
-- SP nghiệp vụ (migrate):
--   ✓ sp_LeadTrackingForMarketing          — wrapper (đọc cache)
--   ✓ sp_LeadTrackingForMarketing_html     — renderer (CustomStore + Grid + Date)
--   ✓ sp_LeadTrackingForMarketingList      — data SP (grid, có @TempTableAPIName)
--   ✓ sp_LeadTrackingForMarketing_GetStats — stats SP (dashboard cards)
--
-- SP hệ thống (phải có sẵn):
--   ⚠ sp_LoadGridUsingAPI                  — generic grid loader
--   ⚠ sptblCommonControlType_Signed_DUC    — build control loadUI/loadData
--   ⚠ sp_GenerateHTMLScript                — build cache VN/EN
--   ⚠ sp_Men_Menu_AfterSave_Simple         — refresh menu
--   ⚠ EmployeeListAll_DataSetting_Custom   — employee DataSource
--
-- SP module khác (DB đích phải có module CRM):
--   ⚠ sp_CRM_CustomerDetail                — form chi tiết lead
--
-- Table hệ thống (có sẵn):
--   · tblHtmlScriptCache, tblCommonControlType_Signed
--   · tblMD_Message, MEN_Menu, tblSC_Object
--
-- Table module CRM (DB đích phải có):
--   · tblCRM_CustomerPersonInfo
--   · tblCRM_ContactCustommerStatus
-- ============================================================

USE [Paradise_Dev]; -- <<< THAY nếu migrate sang DB khác
GO
SET NOCOUNT ON;
PRINT '=== MIGRATE MnuKPI448 ==='
PRINT ''
GO

-- ============================================================================
-- 0/9 PRE-FLIGHT + CREATE TABLE nếu thiếu
-- ============================================================================
PRINT '0/9 Pre-flight: checking table dependencies...'

-- 0.1 Tạo bảng nếu chưa có
IF OBJECT_ID('dbo.tblCRM_CustomerPersonInfo', 'U') IS NULL
BEGIN
    PRINT 'Creating tblCRM_CustomerPersonInfo...'
    CREATE TABLE dbo.tblCRM_CustomerPersonInfo (
        CRM_CustomerID           INT           NOT NULL,
        FullName                 NVARCHAR(500) NULL,
        PhoneNumber              NVARCHAR(1000) NULL,
        PhoneNumberZalo          VARCHAR(50)   NULL,
        Email                    NVARCHAR(2000) NULL,
        AvartaUrl                NVARCHAR(500) NULL,
        CRM_CompanyID            INT           NULL,
        Notes                    NVARCHAR(MAX) NULL,
        PositionID               INT           NULL,
        OwnerID                  VARCHAR(50)   NULL,
        CreatedDate              DATETIME      NULL,
        StatusID                 INT           NULL,
        LastStatusIDBeforeChange INT           NULL,
        Email1                   NVARCHAR(300) NULL,
        PhoneNumber1             NVARCHAR(50)  NULL,
        UpdateTime               DATETIME      NULL,
        zaloID                   VARCHAR(200)  NULL,
        IsCRMLead                BIT           NULL
    );
END

IF OBJECT_ID('dbo.tblCRM_ContactCustommerStatus', 'U') IS NULL
BEGIN
    PRINT 'Creating tblCRM_ContactCustommerStatus...'
    CREATE TABLE dbo.tblCRM_ContactCustommerStatus (
        Status       INT           NULL,
        StatusName   NVARCHAR(400) NULL,
        StatusNameEN NVARCHAR(400) NULL,
        Priority     INT           NULL,
        isVisible    BIT           NULL
    );
END

-- 0.2 Kiểm tra parent menu MnuKPI000
IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = 'MnuKPI000')
BEGIN
    -- Tạo parent menu nếu chưa có
    INSERT INTO MEN_Menu (MenuID, ParentMenuID, ClassName, Priority, IsWeb, AssemblyName, IsVisible, glyphicon, GroupID, showDialog, Activity, Separation)
    VALUES ('MnuKPI000', NULL, '', 90, 0, '', 1, 'bi-bar-chart', 'MnuKPI000', 0, '', 1);

    -- tblMD_Message
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('MnuKPI000', 'VN', N'Quản lý KPI');
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('MnuKPI000', 'EN', 'KPI Management');

    -- tblSC_Object
    INSERT INTO tblSC_Object (ObjectName, Description, Visible, ParentObjectID)
    VALUES ('MnuKPI000', 'MnuKPI000', 1, 0);

    DECLARE @parentObjID INT = (SELECT ObjectID FROM tblSC_Object WHERE Description = 'MnuKPI000');
    INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@parentObjID, 3, '32');

    PRINT 'Parent MnuKPI000 created.';
END
ELSE
    PRINT 'Parent MnuKPI000: OK';

-- 0.3 Kiểm tra SP dependency
IF OBJECT_ID('dbo.sp_LoadGridUsingAPI', 'P') IS NULL
    PRINT 'WARNING: sp_LoadGridUsingAPI not found.'
IF OBJECT_ID('dbo.EmployeeListAll_DataSetting_Custom', 'P') IS NULL
    PRINT 'WARNING: EmployeeListAll_DataSetting_Custom not found.'
IF OBJECT_ID('dbo.sp_CRM_CustomerDetail', 'P') IS NULL
    PRINT 'WARNING: sp_CRM_CustomerDetail not found.'

PRINT 'Pre-flight OK.'
GO

-- ============================================================================
-- 1/9 MESSAGES (tblMD_Message)
-- ============================================================================
PRINT '1/9 Messages...'

IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'MnuKPI448' AND Language = 'VN')
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('MnuKPI448', 'VN', N'Theo dõi lead Marketing');
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'MnuKPI448' AND Language = 'EN')
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('MnuKPI448', 'EN', 'Marketing Lead Tracking');

IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'FromDate' AND Language = 'VN')
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('FromDate', 'VN', N'Từ ngày');
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'FromDate' AND Language = 'EN')
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('FromDate', 'EN', 'From Date');

IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'ToDate' AND Language = 'VN')
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('ToDate', 'VN', N'Đến ngày');
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'ToDate' AND Language = 'EN')
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('ToDate', 'EN', 'To Date');
GO

-- ============================================================================
-- 2/9 MENU (MEN_Menu)
-- ============================================================================
PRINT '2/9 Menu...'

IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = 'MnuKPI448')
    INSERT INTO MEN_Menu (MenuID, ParentMenuID, ClassName, Priority, IsWeb, AssemblyName,
          IsVisible, glyphicon, GroupID, showDialog, Activity, Separation)
    VALUES ('MnuKPI448', 'MnuKPI000', 'sp_LeadTrackingForMarketing', 99, 0, 'DataSetting',
            1, 'UserProfile', 'MnuKPI000', 0, '', 0);
ELSE
    UPDATE MEN_Menu SET glyphicon = 'UserProfile' WHERE MenuID = 'MnuKPI448' AND glyphicon = 'fa fa-user-circle';
GO

-- ============================================================================
-- 3/9 DATA SP: sp_LeadTrackingForMarketingList (grid data)
-- ============================================================================
PRINT '3/9 Data SP: sp_LeadTrackingForMarketingList...'

IF OBJECT_ID('dbo.sp_LeadTrackingForMarketingList') IS NOT NULL DROP PROCEDURE dbo.sp_LeadTrackingForMarketingList;
GO
CREATE PROCEDURE [dbo].[sp_LeadTrackingForMarketingList]
(
    @LoginID           INT          = 3,
    @LanguageID        VARCHAR(5)   = 'VN',
    @FromDate          DATETIME     = NULL,
    @ToDate            DATETIME     = NULL,
    @TempTableAPIName  VARCHAR(100) = ''   -- cho sp_LoadGridUsingAPI
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FromDate IS NULL SET @FromDate = DATEADD(DAY, -30, GETDATE());
    IF @ToDate IS NULL   SET @ToDate   = GETDATE();
    SET @ToDate = DATEADD(SECOND, -1, DATEADD(DAY, 1, CONVERT(DATETIME, CONVERT(DATE, @ToDate))));

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
        ISNULL(c.StatusID, 0)          AS Status,
        CASE WHEN @LanguageID = 'VN' THEN cs.StatusName ELSE cs.StatusNameEN END AS StatusID
    INTO #tmpTableData
    FROM dbo.tblCRM_CustomerPersonInfo c                          -- ⚠ table CRM
    LEFT JOIN tblCRM_ContactCustommerStatus cs ON cs.Status = c.StatusID  -- ⚠ table CRM
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

-- ============================================================================
-- 4/9 DATA SP: sp_LeadTrackingForMarketing_GetStats (dashboard)
-- ============================================================================
PRINT '4/9 Stats SP: sp_LeadTrackingForMarketing_GetStats...'

IF OBJECT_ID('dbo.sp_LeadTrackingForMarketing_GetStats') IS NOT NULL DROP PROCEDURE dbo.sp_LeadTrackingForMarketing_GetStats;
GO
CREATE PROCEDURE dbo.sp_LeadTrackingForMarketing_GetStats
(
    @LoginID    INT        = 3,
    @LanguageID VARCHAR(5) = 'VN',
    @FromDate   DATETIME   = NULL,
    @ToDate     DATETIME   = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FromDate IS NULL SET @FromDate = DATEADD(DAY, -30, GETDATE());
    IF @ToDate IS NULL   SET @ToDate   = GETDATE();
    SET @ToDate = DATEADD(SECOND, -1, DATEADD(DAY, 1, CONVERT(DATE, @ToDate)));

    SELECT
        COUNT(*) AS TotalLeads,
        SUM(CASE WHEN c.CreatedDate >= DATEADD(MONTH, -1, GETDATE()) THEN 1 ELSE 0 END) AS NewLeadsThisMonth,
        SUM(CASE WHEN c.CreatedDate >= DATEADD(DAY, -7, GETDATE()) THEN 1 ELSE 0 END)   AS NewLeadsThisWeek
    FROM dbo.tblCRM_CustomerPersonInfo c                          -- ⚠ table CRM
    WHERE ISNULL(c.IsCRMLead, 0) = 1
      AND c.CreatedDate >= @FromDate
      AND c.CreatedDate <= @ToDate;
END;
GO

-- ============================================================================
-- 5/9 WRAPPER
-- ============================================================================
PRINT '5/9 Wrapper...'

IF OBJECT_ID('dbo.sp_LeadTrackingForMarketing') IS NOT NULL DROP PROCEDURE dbo.sp_LeadTrackingForMarketing;
GO
CREATE PROCEDURE dbo.sp_LeadTrackingForMarketing
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

-- ============================================================================
-- 6/9 CONTROLS (tblCommonControlType_Signed)
-- ============================================================================
PRINT '6/9 Controls...'

DELETE FROM tblCommonControlType_Signed WHERE TableName = 'sp_LeadTrackingForMarketing_html';

-- Grid cha
INSERT INTO tblCommonControlType_Signed
  (TableName, ColumnName, Type, Layout, GridColumnName, SPLoadData, ColumnIDName)
VALUES ('sp_LeadTrackingForMarketing_html', 'GridLeadTracking', 'hpaControlGrid_Duc', 'Grid_View', NULL, 'sp_LeadTrackingForMarketingList', 'CRM_CustomerID');

-- Grid columns
INSERT INTO tblCommonControlType_Signed
  (TableName, ColumnIDName, ColumnName, Type, DisplayName, Layout, GridColumnName)
VALUES
  ('sp_LeadTrackingForMarketing_html', 'CRM_CustomerID', 'STT',             NULL,              '%STT%',            'Grid_View', 'GridLeadTracking'),
  ('sp_LeadTrackingForMarketing_html', 'CRM_CustomerID', 'FullName',        NULL,              '%FullName%',       'Grid_View', 'GridLeadTracking'),
  ('sp_LeadTrackingForMarketing_html', 'CRM_CustomerID', 'PhoneNumber',     NULL,              '%PhoneNumber%',    'Grid_View', 'GridLeadTracking'),
  ('sp_LeadTrackingForMarketing_html', 'CRM_CustomerID', 'Email',           NULL,              '%Email%',          'Grid_View', 'GridLeadTracking'),
  ('sp_LeadTrackingForMarketing_html', 'CRM_CustomerID', 'PhoneNumberZalo', NULL,              '%Zalo%',           'Grid_View', 'GridLeadTracking'),
  ('sp_LeadTrackingForMarketing_html', 'CRM_CustomerID', 'CreatedDate',     NULL,              '%CreatedDate%',    'Grid_View', 'GridLeadTracking'),
  ('sp_LeadTrackingForMarketing_html', 'CRM_CustomerID', 'OwnerID',         'hpaControlSelectEmployee', '%OwnerID%', 'Grid_View', 'GridLeadTracking'),
  ('sp_LeadTrackingForMarketing_html', 'CRM_CustomerID', 'StatusID',        NULL,              '%StatusID%',       'Grid_View', 'GridLeadTracking');

-- OwnerID DataSource
UPDATE tblCommonControlType_Signed SET DataSourceSP = 'EmployeeListAll_DataSetting_Custom'
WHERE TableName = 'sp_LeadTrackingForMarketing_html' AND ColumnName = 'OwnerID';

-- Date filter controls
INSERT INTO tblCommonControlType_Signed (TableName, ColumnName, Type, AutoSave, ReadOnly, DisplayName)
VALUES ('sp_LeadTrackingForMarketing_html', 'FromDate', 'hpaControlDate', 0, 0, N'Từ ngày');

INSERT INTO tblCommonControlType_Signed (TableName, ColumnName, Type, AutoSave, ReadOnly, DisplayName)
VALUES ('sp_LeadTrackingForMarketing_html', 'ToDate', 'hpaControlDate', 0, 0, N'Đến ngày');
GO

-- ============================================================================
-- 7/9 BUILD CONTROLS
-- ============================================================================
PRINT '7/9 Build controls (sptblCommonControlType_Signed_DUC)...'
EXEC sptblCommonControlType_Signed_DUC 'sp_LeadTrackingForMarketing_html';
GO

-- ============================================================================
-- 8/9 RENDERER
-- ============================================================================
PRINT '8/9 Renderer...'

IF OBJECT_ID('dbo.sp_LeadTrackingForMarketing_html') IS NOT NULL DROP PROCEDURE dbo.sp_LeadTrackingForMarketing_html;
GO
CREATE PROCEDURE dbo.sp_LeadTrackingForMarketing_html
(
    @LoginID    INT         = 3,
    @LanguageID VARCHAR(5)  = 'VN',
    @isWeb      INT         = 1
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @SQ NCHAR(1) = CHAR(39);
    DECLARE @uidGrid     NVARCHAR(33) = (SELECT UID FROM tblCommonControlType_Signed WHERE TableName = 'sp_LeadTrackingForMarketing_html' AND ColumnName = 'GridLeadTracking' AND Layout = 'Grid_View' AND GridColumnName IS NULL);
    DECLARE @uidFromDate NVARCHAR(33) = (SELECT UID FROM tblCommonControlType_Signed WHERE TableName = 'sp_LeadTrackingForMarketing_html' AND ColumnName = 'FromDate'     AND Type = 'hpaControlDate');
    DECLARE @uidToDate   NVARCHAR(33) = (SELECT UID FROM tblCommonControlType_Signed WHERE TableName = 'sp_LeadTrackingForMarketing_html' AND ColumnName = 'ToDate'       AND Type = 'hpaControlDate');
    DECLARE @html NVARCHAR(MAX);

    SET @html = N'
    <style>
        #sp_LeadTrackingForMarketing_html { padding: 8px; }
        .ltm-filter { display: flex; align-items: center; gap: 8px; padding-bottom: 8px; flex-shrink: 0; }
        .ltm-filter-label { font-weight: 600; white-space: nowrap; }
        .ltm-filter-ctrl { width: 140px; }
        .dx-scrollbar-horizontal .dx-scrollable-scroll { height: 4px !important; }
        .dx-scrollbar-horizontal .dx-scrollable-scroll-content { height: 4px !important; }
    </style>
    <div id="sp_LeadTrackingForMarketing_html">
        <div class="ltm-filter">
            <label class="ltm-filter-label">%FromDate%</label>
            <div class="ltm-filter-ctrl" id="' + @uidFromDate + N'"></div>
            <label class="ltm-filter-label">%ToDate%</label>
            <div class="ltm-filter-ctrl" id="' + @uidToDate + N'"></div>
        </div>
        <div id="GridLeadTracking" style="height: 100%;"></div>
    </div>
    <script>
        (() => {
            let _showtoolbarGrid_' + @uidGrid + N' = true;
            let _showtoolbarAdd_'  + @uidGrid + N' = false;
            var api = true;
            var DataSource = [];
            var _pageCache = {};
            var _currentKeyword = "";
            var dataStore_GridLeadTracking = null;

            function esc(v) {
                if (v === null || v === undefined) return "";
                return String(v).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/' + @SQ + N'/g, "&#039;");
            }

            function getSafeVal(id) {
                var e = $("#" + id);
                if (e.length && e.hasClass("dx-datebox")) {
                    var i = e.dxDateBox("instance");
                    return i ? i.option("value") : null;
                }
                return null;
            }

            function loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback) {
                if (!columnName || !dataSourceSP || dataSourceSP.trim() === "") return;
                const dataSourceKey = "DataSource_" + columnName;
                const loadedKey = columnName + "DataSourceLoaded";
                if (window[loadedKey] === true) { if (typeof onSuccessCallback === "function") onSuccessCallback(window[dataSourceKey] || []); return; }
                if (window[loadedKey] === "loading") { setTimeout(function() { loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback); }, 100); return; }
                window[loadedKey] = "loading";
                return new Promise((resolve, reject) => {
                    AjaxHPAParadise({
                        data: { name: dataSourceSP, param: ["LoginID", LoginID, "LanguageID", LanguageID] },
                        success: function(res) {
                            const json = typeof res === "string" ? JSON.parse(res) : res;
                            window[dataSourceKey] = (json.data && json.data[0]) || [];
                            window[loadedKey] = true;
                            let idField = json.valueExpr, nameField = json.displayExpr;
                            if (!idField || !nameField) { if (json.dataSchema && json.dataSchema[0]) { const schema = json.dataSchema[0]; if (!idField) idField = schema[0] ? schema[0].name : null; if (!nameField) nameField = schema[1] ? schema[1].name : null; } }
                            window["DataSourceIDField_" + columnName] = idField || "ID";
                            window["DataSourceNameField_" + columnName] = nameField || "Name";
                            if (typeof onSuccessCallback === "function") onSuccessCallback(window[dataSourceKey], json);
                            resolve(window[dataSourceKey]);
                        },
                        error: function(err) { window[loadedKey] = false; if (typeof onSuccessCallback === "function") onSuccessCallback([]); reject(err); }
                    });
                });
            }

            if ("EmployeeListAll_DataSetting_Custom" && "EmployeeListAll_DataSetting_Custom".trim() !== "") {
                loadDataSourceCommon("OwnerID", "EmployeeListAll_DataSetting_Custom", function(data) {});
            }

            function addCRM_CustomerID() {
                window.currentClicked_GridLeadTracking = null;
                window.currentRecordID_CRM_CustomerID = null;
                var tf = "sp_CRM_CustomerDetail";
                if (["Android", "iOS"].includes(getMobileOperatingSystem())) { OpenFormParamMobile(tf); } else { openFormParam(tf); }
            }

            function openDetailCRM_CustomerID(rowData) {
                if (rowData && rowData.CRM_CustomerID) {
                    window.currentClicked_GridLeadTracking = rowData.CRM_CustomerID;
                    window.currentRecordID_CRM_CustomerID = rowData.CRM_CustomerID;
                    var tf = "sp_CRM_CustomerDetail";
                    var param = { LoginID: window.UserID || window.LoginID, LanguageID: window.LanguageID, CRM_CustomerID: rowData.CRM_CustomerID };
                    if (["Android", "iOS"].includes(getMobileOperatingSystem())) { OpenFormParamMobile(tf, param); } else { openFormParam(tf, param); }
                }
            }

            dataStore_GridLeadTracking = new DevExpress.data.CustomStore({
                key: "CRM_CustomerID",
                load: function(loadOptions) {
                    var deferred = $.Deferred();
                    if (!api) { var a = DataSource || []; deferred.resolve({ data: a.slice(loadOptions.skip||0, (loadOptions.skip||0)+(loadOptions.take||50)), totalCount: a.length }); api = true; return deferred.promise(); }
                    var params = [];
                    params.push("@ProcName", "sp_LeadTrackingForMarketingList");
                    var procParam = "@LoginID=" + (window.UserID || window.LoginID) + ",@LanguageID=" + window.LanguageID;
                    var fDate = getSafeVal("' + @uidFromDate + N'"), tDate = getSafeVal("' + @uidToDate + N'");
                    var fdStr = fDate ? DevExpress.localization.formatDate(new Date(fDate), "yyyy-MM-dd") : null;
                    var tdStr = tDate ? DevExpress.localization.formatDate(new Date(tDate), "yyyy-MM-dd") : null;
                    if (fdStr) procParam += ",@FromDate=''" + fdStr + "''";
                    if (tdStr) procParam += ",@ToDate=''" + tdStr + "''";
                    params.push("@ProcParam", procParam);
                    params.push("@Take", loadOptions.take || 50); params.push("@Skip", loadOptions.skip || 0);
                    if (loadOptions.requireTotalCount) params.push("@RequireTotalCount", 1);
                    var sort = loadOptions.sort ? loadOptions.sort.map(s => s.selector + (s.desc ? " DESC" : " ASC")).join(",") : "";
                    params.push("@Sort", sort != "" ? "ORDER BY " + sort : "");
                    if (_currentKeyword) { params.push("@SearchValue", _currentKeyword); params.push("@ColumnSearch", "FullName,PhoneNumber,Email"); }
                    if (loadOptions.filter) { var hf = JSON.stringify(loadOptions.filter, (k, v) => typeof v === "function" ? "FUNCTION" : v).includes("FUNCTION"); if (!hf) params.push("@Filters", createConditionQuery(loadOptions.filter)); }
                    AjaxHPAParadise({
                        data: { name: "sp_LoadGridUsingAPI", param: params },
                        success: function(res) {
                            var json = typeof res === "string" ? JSON.parse(res) : res;
                            var results = Array.isArray(json?.data?.[0]) ? json.data[0] : [];
                            var result = { data: results };
                            if (loadOptions.requireTotalCount) result.totalCount = json?.data?.[1]?.[0]?.TotalCount ?? 0;
                            DataSource = results; window.syncSharedGridData("GridLeadTracking"); deferred.resolve(result);
                        },
                        error: function() { deferred.reject("Data Loading Error"); }
                    });
                    return deferred.promise();
                }
            });

            function ReloadData() { _pageCache = {}; var gridInst = InstanceGridLeadTracking' + @uidGrid + N'; if (gridInst) { gridInst.refresh(); } }

            '
            +(select loadUI from tblCommonControlType_Signed WHERE UID = @uidFromDate)
            +N''
            +(select loadUI from tblCommonControlType_Signed WHERE UID = @uidToDate)
            +N''
            +(select loadUI from tblCommonControlType_Signed WHERE UID = @uidGrid)
            +N'

            try {
                var gi = $("#GridLeadTracking").dxDataGrid("instance");
                if (gi) {
                    gi.beginUpdate();
                    gi.option("remoteOperations", { paging: true, filtering: true, sorting: true, searching: true });
                    gi.option({ "scrolling.mode": "infinite", "scrolling.rowRenderingMode": "virtual", "scrolling.preloadEnabled": false, "scrolling.showScrollbar": "onHover", "scrolling.useNative": false, "paging.enabled": false, "paging.pageSize": 50, "pager.visible": false, "searchPanel.highlightSearchText": false, "columnAutoWidth": true, "dataSource": dataStore_GridLeadTracking, "height": function() { var el = document.getElementById("GridLeadTracking"); if (!el) return 400; return Math.max(300, window.innerHeight - el.getBoundingClientRect().top - 30); } });
                    gi.option("onOptionChanged", function(e) { if (e.name === "searchPanel" && e.fullName === "searchPanel.text") { _currentKeyword = (e.value || "").trim(); _pageCache = {}; } });
                    gi.endUpdate();
                }
            } catch(e) {}

            try {
                var today = new Date(); var prior = new Date(); prior.setDate(today.getDate() - 30);
                InstanceFromDate' + @uidFromDate + N'.option("value", prior);
                InstanceToDate' + @uidToDate + N'.option("value", today);
            } catch(e) {}

            try {
                var iFd = InstanceFromDate' + @uidFromDate + N'; if (iFd && iFd.option) iFd.option("onValueChanged", function(e) { ReloadData(); });
                var iTd = InstanceToDate' + @uidToDate + N'; if (iTd && iTd.option) iTd.option("onValueChanged", function(e) { ReloadData(); });
            } catch(e) {}

            ReloadData()
        })();
    </script>
'

    SELECT @html AS html;
END;
GO

-- ============================================================================
-- 9/9 BUILD CACHE + REFRESH
-- ============================================================================
-- ============================================================================
-- 9/11 DATASETTING + DATASETTINGLAYOUT (bắt buộc — Rule 4)
-- ============================================================================
PRINT '9/11 tblDataSetting + tblDataSettingLayout...'

-- tblDataSetting
IF NOT EXISTS (SELECT 1 FROM tblDataSetting WHERE TableName = 'sp_LeadTrackingForMarketing')
    INSERT INTO tblDataSetting (TableName, IsProcedure, IsShowLayout, ColumnOrderBy, ColumnDataType, ControlHiddenInShowLayout, FormLayoutJS)
    VALUES ('sp_LeadTrackingForMarketing', 1, 1, 'html&0', 'html&ViewHtml', 'grdTableEditor,txtFilter,btnReload,btnFWDelete,btnFWReset,btnExport,btnFWSave,btnFWAdd,isReadOnlyRow,dtftxxENGColumns', 1);
ELSE
    PRINT '  tblDataSetting: already exists';

-- tblDataSettingLayout (2 rows: root + lblhtml)
IF NOT EXISTS (SELECT 1 FROM tblDataSettingLayout WHERE TableName = 'sp_LeadTrackingForMarketing' AND Name = 'root')
    INSERT INTO tblDataSettingLayout (TableName, Name, ControlName, NamePa, Type, Lx, Ly, Sx, Sy, WidthPercentage, TypeLayout)
    VALUES ('sp_LeadTrackingForMarketing', 'root', '', '', 'g', 0, 0, 1620, 929, 100, '6');

IF NOT EXISTS (SELECT 1 FROM tblDataSettingLayout WHERE TableName = 'sp_LeadTrackingForMarketing' AND Name = 'lblhtml')
    INSERT INTO tblDataSettingLayout (TableName, Name, ControlName, NamePa, Type, Lx, Ly, Sx, Sy, WidthPercentage, ControlType, TypeLayout)
    VALUES ('sp_LeadTrackingForMarketing', 'lblhtml', 'html', 'root', 'i', 0, 0, 1620, 929, 100, 'ParadiseWebView2', '6');

PRINT '  tblDataSettingLayout: ensured 2 rows (root + lblhtml)';
GO

-- ============================================================================
-- 10/11 PERMISSION (tblSC_Object + tblSC_Right_Stored)
-- ============================================================================
PRINT '9/9 Permission...'

-- Tìm ObjectID của parent MnuKPI000
DECLARE @parentObjectID INT = (SELECT TOP 1 ObjectID FROM tblSC_Object WHERE Description = 'MnuKPI000');
IF @parentObjectID IS NULL
BEGIN
    PRINT 'ERROR: Parent MnuKPI000 not found in tblSC_Object. Run pre-flight first.';
    RETURN;
END

-- tblSC_Object: MERGE idempotent
IF NOT EXISTS (SELECT 1 FROM tblSC_Object WHERE Description = 'MnuKPI448')
BEGIN
    INSERT INTO tblSC_Object (ObjectName, Description, Visible, ParentObjectID)
    VALUES ('DataSetting.sp_LeadTrackingForMarketing', 'MnuKPI448', 1, @parentObjectID);
    PRINT '  tblSC_Object: created MnuKPI448';
END
ELSE
    PRINT '  tblSC_Object: already exists';

-- tblSC_Right_Stored: CHỈ LoginID = 3 (admin), theo Rule 1
DECLARE @objID INT = (SELECT ObjectID FROM tblSC_Object WHERE Description = 'MnuKPI448');

IF NOT EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID = @objID AND LoginID = 3)
BEGIN
    INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess)
    VALUES (@objID, 3, '32');
    PRINT '  tblSC_Right_Stored: LoginID=3 FullAccess=32';
END
ELSE
    PRINT '  tblSC_Right_Stored: LoginID=3 already exists';
GO

-- ============================================================================
-- 10/10 BUILD CACHE + REFRESH
-- ============================================================================
PRINT '11/11 Build cache + refresh menu...'
DELETE FROM tblHtmlScriptCache WHERE TableName = 'sp_LeadTrackingForMarketing_html';
EXEC sp_GenerateHTMLScript 'sp_LeadTrackingForMarketing_html';
EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_LeadTrackingForMarketing';

PRINT ''
PRINT '=== DONE: MnuKPI448 migrated (10 steps) ==='
PRINT 'Includes: Messages + Menu + 2 Data SPs + Wrapper + Controls + Renderer + Permission + Cache'
PRINT 'Permission: LoginID=3 (admin) FullAccess=32'
GO
