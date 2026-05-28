SET NOCOUNT ON;
PRINT '--- 6-Layer Renderer ---';
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

    -- Layer 2: Text VN/EN
    DECLARE @lblTotalLeads  NVARCHAR(100), @lblThisMonth NVARCHAR(100), @lblThisWeek NVARCHAR(100),
            @lblFromDate    NVARCHAR(50),  @lblToDate    NVARCHAR(50),
            @lblFilter      NVARCHAR(50),  @lblReset     NVARCHAR(50),
            @lblSearch      NVARCHAR(100), @lblFullName  NVARCHAR(100),
            @lblPhone       NVARCHAR(100), @lblCreatedDate NVARCHAR(100),
            @lblOwner       NVARCHAR(100), @lblStatus    NVARCHAR(100),
            @errLoad        NVARCHAR(200);

    IF @LanguageID = 'EN'
        SELECT @lblTotalLeads=N'Total Leads', @lblThisMonth=N'This Month', @lblThisWeek=N'This Week',
               @lblFromDate=N'From:', @lblToDate=N'To:', @lblFilter=N'Filter', @lblReset=N'Reset',
               @lblSearch=N'Search...', @lblFullName=N'Full Name', @lblPhone=N'Phone',
               @lblCreatedDate=N'Created Date', @lblOwner=N'Owner', @lblStatus=N'Status',
               @errLoad=N'Data Loading Error';
    ELSE
        SELECT @lblTotalLeads=N'Tong so Lead', @lblThisMonth=N'Thang nay', @lblThisWeek=N'Tuan nay',
               @lblFromDate=N'Tu ngay:', @lblToDate=N'Den ngay:', @lblFilter=N'Loc', @lblReset=N'Reset',
               @lblSearch=N'Tim kiem...', @lblFullName=N'Ho ten', @lblPhone=N'SDT',
               @lblCreatedDate=N'Ngay tao', @lblOwner=N'Phu trach', @lblStatus=N'Trang thai',
               @errLoad=N'Loi tai du lieu';

    -- Layer 3: JS-escaped
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

    -- Layer 4: Build HTML
    DECLARE @html NVARCHAR(MAX) = N'';

    SET @html = N'<div id="sp_LeadTrackingForMarketing_html" style="display:flex;flex-direction:column;height:100%;padding:8px;box-sizing:border-box;">';

    -- Filter bar
    SET @html = @html + N'<div id="filterBarLead" style="display:flex;gap:8px;align-items:center;margin-bottom:12px;flex-shrink:0;flex-wrap:wrap;background:#f8f9fa;padding:8px 12px;border-radius:6px;border:1px solid #e0e0e0;">';
    SET @html = @html + N'<span style="font-weight:600;font-size:13px;color:#333;">' + @lblFromDate + N'</span>';
    SET @html = @html + N'<input type="text" id="filterFromDate" class="datepicker-lead" style="width:130px;padding:6px 8px;border:1px solid #ccc;border-radius:4px;font-size:13px;" />';
    SET @html = @html + N'<span style="font-weight:600;font-size:13px;color:#333;">' + @lblToDate + N'</span>';
    SET @html = @html + N'<input type="text" id="filterToDate" class="datepicker-lead" style="width:130px;padding:6px 8px;border:1px solid #ccc;border-radius:4px;font-size:13px;" />';
    SET @html = @html + N'<button id="btnApplyFilter" style="background:#667eea;color:#fff;border:none;padding:6px 16px;border-radius:4px;cursor:pointer;font-size:13px;font-weight:600;">' + @lblFilter + N'</button>';
    SET @html = @html + N'<button id="btnResetFilter" style="background:#6c757d;color:#fff;border:none;padding:6px 16px;border-radius:4px;cursor:pointer;font-size:13px;">' + @lblReset + N'</button>';
    SET @html = @html + N'</div>';

    -- Dashboard
    SET @html = @html + N'<div id="dashboardLeadMarketing" style="display:flex;gap:16px;margin-bottom:12px;flex-shrink:0;flex-wrap:wrap;">';
    SET @html = @html + N'<div class="stat-card" style="flex:1;min-width:180px;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:#fff;border-radius:8px;padding:16px;box-shadow:0 2px 8px rgba(0,0,0,0.12);"><div style="font-size:13px;opacity:0.85;">' + @lblTotalLeads + N'</div><div style="font-size:32px;font-weight:700;margin-top:4px;" id="valTotalLeads">--</div></div>';
    SET @html = @html + N'<div class="stat-card" style="flex:1;min-width:180px;background:linear-gradient(135deg,#f093fb 0%,#f5576c 100%);color:#fff;border-radius:8px;padding:16px;box-shadow:0 2px 8px rgba(0,0,0,0.12);"><div style="font-size:13px;opacity:0.85;">' + @lblThisMonth + N'</div><div style="font-size:32px;font-weight:700;margin-top:4px;" id="valLeadsThisMonth">--</div></div>';
    SET @html = @html + N'<div class="stat-card" style="flex:1;min-width:180px;background:linear-gradient(135deg,#4facfe 0%,#00f2fe 100%);color:#fff;border-radius:8px;padding:16px;box-shadow:0 2px 8px rgba(0,0,0,0.12);"><div style="font-size:13px;opacity:0.85;">' + @lblThisWeek + N'</div><div style="font-size:32px;font-weight:700;margin-top:4px;" id="valLeadsThisWeek">--</div></div>';
    SET @html = @html + N'</div>';

    -- Grid
    SET @html = @html + N'<div id="GridLeadTracking" style="flex:1;min-height:0;"></div></div>';

    -- JS
    SET @html = @html + N'<script>(function(){';
    SET @html = @html + N'var _currentKeyword="";var _pageCache={};var _fromDate=null;var _toDate=null;';
    SET @html = @html + N'var ERR_MSG="' + @errLoadJs + N'";';
    SET @html = @html + N'function escapeHtml(v){if(v===null||v===undefined)return "";return String(v).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#039;");}';
    SET @html = @html + N'function loadDashboardStats(){AjaxHPAParadise({data:{name:"sp_LeadTrackingForMarketing_GetStats",param:["LoginID",window.UserID||window.LoginID,"LanguageID",window.LanguageID]},success:function(res){var json=typeof res==="string"?JSON.parse(res):res;var stats=(json&&json.data&&json.data[0]&&json.data[0][0])||{};document.getElementById("valTotalLeads").textContent=(stats.TotalLeads||0).toLocaleString();document.getElementById("valLeadsThisMonth").textContent=(stats.NewLeadsThisMonth||0).toLocaleString();document.getElementById("valLeadsThisWeek").textContent=(stats.NewLeadsThisWeek||0).toLocaleString();}});}';
    SET @html = @html + N'var dataStore=new DevExpress.data.CustomStore({key:"CRM_CustomerID",load:function(lo){var d=$.Deferred();var p=[];p.push("@ProcName","sp_LeadTrackingForMarketingList");p.push("@ProcParam","@LoginID="+(window.UserID||window.LoginID)+", @LanguageID="+window.LanguageID);p.push("@Take",lo.take||50);p.push("@Skip",lo.skip||0);if(lo.requireTotalCount)p.push("@RequireTotalCount",1);var sort=lo.sort?lo.sort.map(function(s){return s.selector+(s.desc?" DESC":" ASC");}).join(","):"STT";p.push("@Sort","ORDER BY "+sort);if(_currentKeyword){p.push("@SearchValue",_currentKeyword);p.push("@ColumnSearch","FullName,PhoneNumber,Email");}if(lo.filter){var hf=false;try{hf=JSON.stringify(lo.filter,function(k,v){return typeof v==="function"?"F":v;}).indexOf("F")>=0;}catch(e){}if(!hf)p.push("@Filters",createConditionQuery(lo.filter));}if(_fromDate)p.push("@FromDate",_fromDate);if(_toDate)p.push("@ToDate",_toDate);AjaxHPAParadise({data:{name:"sp_LoadGridUsingAPI",param:p},success:function(res){var json=typeof res==="string"?JSON.parse(res):res;var results=Array.isArray(json&&json.data&&json.data[0])?json.data[0]:[];var result={data:results};if(lo.requireTotalCount)result.totalCount=(json&&json.data&&json.data[1]&&json.data[1][0]&&json.data[1][0].TotalCount)||0;d.resolve(result);},error:function(){d.reject(ERR_MSG);}});return d.promise();}});';
    SET @html = @html + N'var gridElement=document.getElementById("GridLeadTracking");var gridInstance=$(gridElement).dxDataGrid({dataSource:dataStore,remoteOperations:{paging:true,filtering:true,sorting:true,searching:true},scrolling:{mode:"infinite",rowRenderingMode:"virtual",preloadEnabled:false},paging:{enabled:true,pageSize:50},pager:{visible:false},searchPanel:{visible:true,placeholder:"' + @lblSearchJs + N'",highlightSearchText:false},columns:[{dataField:"STT",caption:"STT",width:50,allowFiltering:false},{dataField:"FullName",caption:"' + @lblFullNameJs + N'",width:180},{dataField:"PhoneNumber",caption:"' + @lblPhoneJs + N'",width:120},{dataField:"Email",caption:"Email",width:200},{dataField:"PhoneNumberZalo",caption:"Zalo",width:120},{dataField:"CreatedDate",caption:"' + @lblCreatedDateJs + N'",width:110,allowFiltering:false},{dataField:"OwnerID",caption:"' + @lblOwnerJs + N'",width:100},{dataField:"StatusID",caption:"' + @lblStatusJs + N'",width:100}],height:function(){var el=document.getElementById("GridLeadTracking");if(!el)return 400;return Math.max(300,window.innerHeight-el.getBoundingClientRect().top-30);},onOptionChanged:function(e){if(e.name==="searchPanel"&&e.fullName==="searchPanel.text"){_currentKeyword=(e.value||"").trim();_pageCache={};}}}).dxDataGrid("instance");';
    SET @html = @html + N'function applyFilter(){_fromDate=document.getElementById("filterFromDate").value||null;_toDate=document.getElementById("filterToDate").value||null;_pageCache={};gridInstance.refresh();loadDashboardStats();}';
    SET @html = @html + N'function resetFilter(){document.getElementById("filterFromDate").value="";document.getElementById("filterToDate").value="";_fromDate=null;_toDate=null;_pageCache={};gridInstance.refresh();loadDashboardStats();}';
    SET @html = @html + N'document.getElementById("btnApplyFilter").addEventListener("click",applyFilter);document.getElementById("btnResetFilter").addEventListener("click",resetFilter);';
    SET @html = @html + N'try{$(".datepicker-lead").datepicker({dateFormat:"dd/mm/yy"});}catch(e){}loadDashboardStats();';
    SET @html = @html + N'})();</script>';

    -- Layer 5: MERGE cache 8 columns
    MERGE dbo.tblHtmlScriptCache AS tgt
    USING (SELECT 'sp_LeadTrackingForMarketing' AS TableName,
                  @LanguageID AS LanguageID, '-1' AS ScreenType,
                  @html AS html, N'' AS HtmlParadise, N'' AS paradiseJs,
                  '1' AS Version, N'' AS VersionData) AS src
       ON tgt.TableName = src.TableName AND tgt.LanguageID = src.LanguageID
    WHEN MATCHED THEN
        UPDATE SET tgt.ScreenType=src.ScreenType, tgt.html=src.html,
                   tgt.HtmlParadise=src.HtmlParadise, tgt.paradiseJs=src.paradiseJs,
                   tgt.Version=src.Version, tgt.VersionData=src.VersionData
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData)
        VALUES (src.TableName, src.LanguageID, src.ScreenType, src.html, src.HtmlParadise, src.paradiseJs, src.Version, src.VersionData);

    -- Layer 6: Fallback SELECT
    SELECT @html AS html;
END;
GO
PRINT '  [+] Renderer rewritten (6-layer)';
