/* ===========================================================================
 * Fix: Renderer 6-layer anatomy (17_RendererHtmlJsSafe)
 * Key fix: CHAR(39) for single quote in JS regex instead of literal '
 * Run in SSMS on Paradise_Dev
 * =========================================================================== */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT '--- Drop old renderer ---';

IF OBJECT_ID('dbo.sp_LeadTrackingForMarketing_html') IS NOT NULL
    DROP PROCEDURE dbo.sp_LeadTrackingForMarketing_html;
GO

PRINT '--- Create 6-layer renderer ---';
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

    /* Layer 2: Text VN/EN */
    DECLARE @lblTotalLeads  NVARCHAR(100), @lblThisMonth   NVARCHAR(100), @lblThisWeek NVARCHAR(100),
            @lblFromDate    NVARCHAR(50),  @lblToDate      NVARCHAR(50),
            @lblFilter      NVARCHAR(50),  @lblReset       NVARCHAR(50),
            @lblSearch      NVARCHAR(100), @lblFullName    NVARCHAR(100),
            @lblPhone       NVARCHAR(100), @lblCreatedDate NVARCHAR(100),
            @lblOwner       NVARCHAR(100), @lblStatus      NVARCHAR(100),
            @errLoad        NVARCHAR(200);

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
               @errLoad        = N'Lỗi tải dữ liệu';

    /* Layer 3: JS-escaped variables */
    DECLARE @lblTotalLeadsJs  NVARCHAR(200) = REPLACE(REPLACE(@lblTotalLeads,  N'\', N'\\'), N'"', N'\"');
    DECLARE @lblThisMonthJs   NVARCHAR(200) = REPLACE(REPLACE(@lblThisMonth,   N'\', N'\\'), N'"', N'\"');
    DECLARE @lblThisWeekJs    NVARCHAR(200) = REPLACE(REPLACE(@lblThisWeek,    N'\', N'\\'), N'"', N'\"');
    DECLARE @lblSearchJs      NVARCHAR(200) = REPLACE(REPLACE(@lblSearch,      N'\', N'\\'), N'"', N'\"');
    DECLARE @lblFullNameJs    NVARCHAR(200) = REPLACE(REPLACE(@lblFullName,    N'\', N'\\'), N'"', N'\"');
    DECLARE @lblPhoneJs       NVARCHAR(200) = REPLACE(REPLACE(@lblPhone,       N'\', N'\\'), N'"', N'\"');
    DECLARE @lblCreatedDateJs NVARCHAR(200) = REPLACE(REPLACE(@lblCreatedDate, N'\', N'\\'), N'"', N'\"');
    DECLARE @lblOwnerJs       NVARCHAR(200) = REPLACE(REPLACE(@lblOwner,       N'\', N'\\'), N'"', N'\"');
    DECLARE @lblStatusJs      NVARCHAR(200) = REPLACE(REPLACE(@lblStatus,      N'\', N'\\'), N'"', N'\"');
    DECLARE @errLoadJs        NVARCHAR(400) = REPLACE(REPLACE(@errLoad,        N'\', N'\\'), N'"', N'\"');

    /* Single-quote char for JS regex (avoids literal ' in N-strings) */
    DECLARE @SQ NCHAR(1) = CHAR(39);

    /* Layer 4: Build HTML */
    DECLARE @html NVARCHAR(MAX) = N'';

    /* --- Container --- */
    SET @html = @html + N'<div id="sp_LeadTrackingForMarketing_html" style="display:flex;flex-direction:column;height:100%;padding:8px;box-sizing:border-box;">';

    /* --- Filter Bar --- */
    SET @html = @html + N'<div id="filterBarLead" style="display:flex;gap:8px;align-items:center;margin-bottom:12px;flex-shrink:0;flex-wrap:wrap;background:#f8f9fa;padding:8px 12px;border-radius:6px;border:1px solid #e0e0e0;">';
    SET @html = @html + N'<span style="font-weight:600;font-size:13px;color:#333;">' + @lblFromDate + N'</span>';
    SET @html = @html + N'<input type="text" id="filterFromDate" class="datepicker-lead" style="width:130px;padding:6px 8px;border:1px solid #ccc;border-radius:4px;font-size:13px;" />';
    SET @html = @html + N'<span style="font-weight:600;font-size:13px;color:#333;">' + @lblToDate + N'</span>';
    SET @html = @html + N'<input type="text" id="filterToDate" class="datepicker-lead" style="width:130px;padding:6px 8px;border:1px solid #ccc;border-radius:4px;font-size:13px;" />';
    SET @html = @html + N'<button id="btnApplyFilter" style="background:#667eea;color:#fff;border:none;padding:6px 16px;border-radius:4px;cursor:pointer;font-size:13px;font-weight:600;">' + @lblFilter + N'</button>';
    SET @html = @html + N'<button id="btnResetFilter" style="background:#6c757d;color:#fff;border:none;padding:6px 16px;border-radius:4px;cursor:pointer;font-size:13px;">' + @lblReset + N'</button>';
    SET @html = @html + N'</div>';

    /* --- Dashboard Cards --- */
    SET @html = @html + N'<div id="dashboardLeadMarketing" style="display:flex;gap:16px;margin-bottom:12px;flex-shrink:0;flex-wrap:wrap;">';
    SET @html = @html + N'<div class="stat-card" style="flex:1;min-width:180px;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:#fff;border-radius:8px;padding:16px;box-shadow:0 2px 8px rgba(0,0,0,0.12);">';
    SET @html = @html + N'<div style="font-size:13px;opacity:0.85;">' + @lblTotalLeads + N'</div>';
    SET @html = @html + N'<div style="font-size:32px;font-weight:700;margin-top:4px;" id="valTotalLeads">--</div></div>';
    SET @html = @html + N'<div class="stat-card" style="flex:1;min-width:180px;background:linear-gradient(135deg,#f093fb 0%,#f5576c 100%);color:#fff;border-radius:8px;padding:16px;box-shadow:0 2px 8px rgba(0,0,0,0.12);">';
    SET @html = @html + N'<div style="font-size:13px;opacity:0.85;">' + @lblThisMonth + N'</div>';
    SET @html = @html + N'<div style="font-size:32px;font-weight:700;margin-top:4px;" id="valLeadsThisMonth">--</div></div>';
    SET @html = @html + N'<div class="stat-card" style="flex:1;min-width:180px;background:linear-gradient(135deg,#4facfe 0%,#00f2fe 100%);color:#fff;border-radius:8px;padding:16px;box-shadow:0 2px 8px rgba(0,0,0,0.12);">';
    SET @html = @html + N'<div style="font-size:13px;opacity:0.85;">' + @lblThisWeek + N'</div>';
    SET @html = @html + N'<div style="font-size:32px;font-weight:700;margin-top:4px;" id="valLeadsThisWeek">--</div></div>';
    SET @html = @html + N'</div>';

    /* --- Grid Container --- */
    SET @html = @html + N'<div id="GridLeadTracking" style="flex:1;min-height:0;"></div></div>';

    /* ============================================================
     * JAVASCRIPT (CHAR(39) for single-quote in regex — Rule 2 safe)
     * ============================================================ */
    SET @html = @html + N'<script>(function(){';
    SET @html = @html + N'var _k="",_pc={},_fd=null,_td=null,ERR="' + @errLoadJs + N'";';
    SET @html = @html + N'function esc(v){if(v===null||v===undefined)return"";return String(v).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/' + @SQ + N'/g,"&#039;");}';

    /* --- Dashboard Stats Loader --- */
    SET @html = @html + N'function loadStats(){AjaxHPAParadise({data:{name:"sp_LeadTrackingForMarketing_GetStats",param:["LoginID",window.UserID||window.LoginID,"LanguageID",window.LanguageID]},success:function(r){';
    SET @html = @html + N'var j=typeof r==="string"?JSON.parse(r):r;';
    SET @html = @html + N'var s=(j&&j.data&&j.data[0]&&j.data[0][0])||{};';
    SET @html = @html + N'document.getElementById("valTotalLeads").textContent=(s.TotalLeads||0).toLocaleString();';
    SET @html = @html + N'document.getElementById("valLeadsThisMonth").textContent=(s.NewLeadsThisMonth||0).toLocaleString();';
    SET @html = @html + N'document.getElementById("valLeadsThisWeek").textContent=(s.NewLeadsThisWeek||0).toLocaleString();';
    SET @html = @html + N'}});}';

    /* --- CustomStore (Rule 6) --- */
    SET @html = @html + N'var ds=new DevExpress.data.CustomStore({key:"CRM_CustomerID",load:function(lo){';
    SET @html = @html + N'var d=$.Deferred(),p=[];';
    SET @html = @html + N'p.push("@ProcName","sp_LeadTrackingForMarketingList");';
    SET @html = @html + N'p.push("@ProcParam","@LoginID="+(window.UserID||window.LoginID)+", @LanguageID="+window.LanguageID);';
    SET @html = @html + N'p.push("@Take",lo.take||50);p.push("@Skip",lo.skip||0);';
    SET @html = @html + N'if(lo.requireTotalCount)p.push("@RequireTotalCount",1);';
    SET @html = @html + N'var srt=lo.sort?lo.sort.map(function(s){return s.selector+(s.desc?" DESC":" ASC");}).join(","):"STT";';
    SET @html = @html + N'p.push("@Sort","ORDER BY "+srt);';
    SET @html = @html + N'if(_k){p.push("@SearchValue",_k);p.push("@ColumnSearch","FullName,PhoneNumber,Email");}';
    SET @html = @html + N'if(lo.filter){var hf=false;try{hf=JSON.stringify(lo.filter,function(k,v){return typeof v==="function"?"F_":v;}).indexOf("F_")>=0;}catch(e){}if(!hf)p.push("@Filters",createConditionQuery(lo.filter));}';
    SET @html = @html + N'if(_fd)p.push("@FromDate",_fd);if(_td)p.push("@ToDate",_td);';
    SET @html = @html + N'AjaxHPAParadise({data:{name:"sp_LoadGridUsingAPI",param:p},success:function(r){';
    SET @html = @html + N'var j=typeof r==="string"?JSON.parse(r):r;';
    SET @html = @html + N'var rows=Array.isArray(j&&j.data&&j.data[0])?j.data[0]:[];';
    SET @html = @html + N'var res={data:rows};';
    SET @html = @html + N'if(lo.requireTotalCount)res.totalCount=(j&&j.data&&j.data[1]&&j.data[1][0]&&j.data[1][0].TotalCount)||0;';
    SET @html = @html + N'd.resolve(res);},error:function(){d.reject(ERR);}});';
    SET @html = @html + N'return d.promise();}});';

    /* --- dxDataGrid (Rule 6 - infinite scroll) --- */
    SET @html = @html + N'var grid=$(document.getElementById("GridLeadTracking")).dxDataGrid({';
    SET @html = @html + N'dataSource:ds,remoteOperations:{paging:true,filtering:true,sorting:true,searching:true},';
    SET @html = @html + N'scrolling:{mode:"infinite",rowRenderingMode:"virtual",preloadEnabled:false},';
    SET @html = @html + N'paging:{enabled:true,pageSize:50},pager:{visible:false},';
    SET @html = @html + N'searchPanel:{visible:true,placeholder:"' + @lblSearchJs + N'",highlightSearchText:false},';
    SET @html = @html + N'columns:[';
    SET @html = @html + N'{dataField:"STT",caption:"STT",width:50,allowFiltering:false},';
    SET @html = @html + N'{dataField:"FullName",caption:"' + @lblFullNameJs + N'",width:180},';
    SET @html = @html + N'{dataField:"PhoneNumber",caption:"' + @lblPhoneJs + N'",width:120},';
    SET @html = @html + N'{dataField:"Email",caption:"Email",width:200},';
    SET @html = @html + N'{dataField:"PhoneNumberZalo",caption:"Zalo",width:120},';
    SET @html = @html + N'{dataField:"CreatedDate",caption:"' + @lblCreatedDateJs + N'",width:110,allowFiltering:false},';
    SET @html = @html + N'{dataField:"OwnerID",caption:"' + @lblOwnerJs + N'",width:100},';
    SET @html = @html + N'{dataField:"StatusID",caption:"' + @lblStatusJs + N'",width:100}';
    SET @html = @html + N'],';
    SET @html = @html + N'height:function(){var el=document.getElementById("GridLeadTracking");if(!el)return 400;return Math.max(300,window.innerHeight-el.getBoundingClientRect().top-30);},';
    SET @html = @html + N'onOptionChanged:function(e){if(e.name==="searchPanel"&&e.fullName==="searchPanel.text"){_k=(e.value||"").trim();_pc={};}}';
    SET @html = @html + N'}).dxDataGrid("instance");';

    /* --- Filter handlers --- */
    SET @html = @html + N'function applyFilter(){_fd=document.getElementById("filterFromDate").value||null;_td=document.getElementById("filterToDate").value||null;_pc={};grid.refresh();loadStats();}';
    SET @html = @html + N'function resetFilter(){document.getElementById("filterFromDate").value="";document.getElementById("filterToDate").value="";_fd=null;_td=null;_pc={};grid.refresh();loadStats();}';
    SET @html = @html + N'document.getElementById("btnApplyFilter").addEventListener("click",applyFilter);';
    SET @html = @html + N'document.getElementById("btnResetFilter").addEventListener("click",resetFilter);';
    SET @html = @html + N'try{$(".datepicker-lead").datepicker({dateFormat:"dd/mm/yy"});}catch(e){}';
    SET @html = @html + N'loadStats();})();</script>';

    /* ================================================================
     * Layer 5: MERGE cache (8 columns)
     * ================================================================ */
    MERGE dbo.tblHtmlScriptCache AS tgt
    USING (SELECT 'sp_LeadTrackingForMarketing' AS TableName,
                  @LanguageID AS LanguageID, '-1' AS ScreenType,
                  @html AS html, N'' AS HtmlParadise, N'' AS paradiseJs,
                  '1' AS Version, N'' AS VersionData) AS src
       ON tgt.TableName = src.TableName AND tgt.LanguageID = src.LanguageID
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

    /* Layer 6: Fallback SELECT */
    SELECT @html AS html;
END;
GO

PRINT '  [+] Renderer created (6-layer)';
PRINT '';

/* ================================================================
 * Rebuild cache + refresh menu
 * ================================================================ */
PRINT '--- Rebuild cache ---';
DELETE FROM dbo.tblHtmlScriptCache WHERE TableName = 'sp_LeadTrackingForMarketing';
EXEC dbo.sp_GenerateHTMLScript 'sp_LeadTrackingForMarketing_html';

PRINT '';
PRINT '--- Refresh menu ---';
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_LeadTrackingForMarketing';

PRINT '';
PRINT '--- Verify ---';
SELECT TableName, LanguageID, ScreenType, DATALENGTH(html) AS HtmlBytes, Version
FROM dbo.tblHtmlScriptCache
WHERE TableName = 'sp_LeadTrackingForMarketing'
ORDER BY LanguageID;

PRINT '';
PRINT '=== DONE - Logout/login de thay menu MnuKPI448 ===';
