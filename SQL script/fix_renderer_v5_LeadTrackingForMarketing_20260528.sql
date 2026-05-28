/* ============================================================
 * PHASE 7: ALTER renderer sp_LeadTrackingForMarketing_html
 *          Update scrolling to Infinite + Inject Toolbar (+ and Reload)
 * ============================================================ */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT '--- Alter 6-layer renderer ---';
GO

ALTER PROCEDURE dbo.sp_LeadTrackingForMarketing_html
(
    @LoginID    INT         = 3,
    @LanguageID VARCHAR(5)  = 'VN',
    @isWeb      INT         = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @SQ NCHAR(1) = CHAR(39);

    /* Lấy UID của grid cha */
    DECLARE @uidGrid NVARCHAR(33) = (
        SELECT UID FROM tblCommonControlType_Signed
         WHERE TableName = 'sp_LeadTrackingForMarketing_html'
           AND ColumnName = 'GridLeadTracking'
           AND Layout = 'Grid_View'
           AND GridColumnName IS NULL
    );

    DECLARE @html NVARCHAR(MAX) = N'';

    /* ============================================================
     * HTML STRUCTURE - ParadiseStyle
     * ============================================================ */
    SET @html = @html + N'<div id="sp_LeadTrackingForMarketing_html" class="ltm-page">';
    SET @html = @html + N'<div id="GridLeadTracking" class="ltm-grid"></div>';
    SET @html = @html + N'</div>';

    /* ============================================================
     * CSS - ParadiseStyle scoped (Rule 6)
     * ============================================================ */
    SET @html = @html + N'<style>'
        + N'.ltm-page{display:flex;flex-direction:column;height:100%;padding:var(--paradise-space-3);box-sizing:border-box;font-family:var(--paradise-font-family-base);color:var(--paradise-text-body);}'
        + N'.ltm-grid{flex:1;min-height:0;}'
        + N'</style>';

    /* ============================================================
     * JAVASCRIPT - Control injection pattern
     * ============================================================ */
    SET @html = @html + N'<script>(function(){'
        + N'function esc(v){if(v===null||v===undefined)return"";return String(v).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/' + @SQ + N'/g,"&#039;");}';

    /* --- Cờ hiển thị Toolbar (+ và Reload) --- */
    SET @html = @html + N'var _showtoolbarGrid_' + @uidGrid + N' = true;';

    /* --- Callback Thêm mới (+) --- */
    SET @html = @html + N'function addCRM_CustomerID() {'
        + N'    window.currentClicked_GridLeadTracking = null;'
        + N'    window.currentRecordID_CRM_CustomerID = null;'
        + N'    var tf = "sp_CRM_CustomerDetail";'
        + N'    if (typeof getMobileOperatingSystem === "function" && ["Android", "iOS"].includes(getMobileOperatingSystem())) { if(typeof OpenFormParamMobile==="function") OpenFormParamMobile(tf); } else { if(typeof openFormParam==="function") openFormParam(tf); }'
        + N'}';

    /* --- Callback Xem chi tiết (Double Click) --- */
    SET @html = @html + N'function openDetailCRM_CustomerID(rowData) {'
        + N'    if (rowData && rowData.CRM_CustomerID) {'
        + N'        window.currentClicked_GridLeadTracking = rowData.CRM_CustomerID;'
        + N'        window.currentRecordID_CRM_CustomerID = rowData.CRM_CustomerID;'
        + N'        var tf = "sp_CRM_CustomerDetail";'
        + N'        var param = { LoginID: window.UserID || window.LoginID, LanguageID: window.LanguageID, CRM_CustomerID: rowData.CRM_CustomerID };'
        + N'        if (typeof getMobileOperatingSystem === "function" && ["Android", "iOS"].includes(getMobileOperatingSystem())) { if(typeof OpenFormParamMobile==="function") OpenFormParamMobile(tf, param); } else { if(typeof openFormParam==="function") openFormParam(tf, param); }'
        + N'    }'
        + N'}';

    /* --- Reload: gọi API load grid + cập nhật dataSource --- */
    SET @html = @html + N'function Reload(){'
        + N'AjaxHPAParadise({data:{name:"sp_LeadTrackingForMarketingList",param:["LoginID",window.UserID||window.LoginID,"LanguageID",window.LanguageID]},success:function(res){'
            + N'var j=typeof res==="string"?JSON.parse(res):res;'
            + N'var rows=Array.isArray(j&&j.data&&j.data[0])?j.data[0]:[];'
            + N'var gridInst=InstanceGridLeadTracking' + @uidGrid + N';'
            + N'if(gridInst){'
                + N'gridInst.beginUpdate();'
                -- Áp dụng chuẩn Infinite Scroll (Rule 6)
                + N'gridInst.option("scrolling",{mode:"infinite",rowRenderingMode:"virtual",preloadEnabled:false});'
                + N'gridInst.option("remoteOperations",false);'
                + N'gridInst.option("paging",{enabled:false,pageSize:50});'
                + N'gridInst.option("pager",{visible:false});'
                + N'gridInst.option("searchPanel.highlightSearchText",false);'
                + N'gridInst.option("dataSource",rows);'
                + N'gridInst.endUpdate();'
                + N'if(rows.length>0&&rows[0].CRM_CustomerID!==undefined){window.currentRecordID_CRM_CustomerID=rows[0].CRM_CustomerID;}'
                -- inject loadData cho grid
                + N''
                + ISNULL((SELECT loadData FROM tblCommonControlType_Signed WHERE UID = @uidGrid), N'')
                + N''
            + N'}'
        + N'},error:function(){console.error("Reload failed");}});}';

    /* ========== INJECT SYSTEM CONTROLS ========== */
    -- Grid loadUI (tạo dxDataGrid)
    SET @html = @html + N''
        + ISNULL((SELECT loadUI FROM tblCommonControlType_Signed WHERE UID = @uidGrid), N'')
        + N'';

    /* --- Initial load --- */
    SET @html = @html + N'Reload();';

    SET @html = @html + N'})();</script>';

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

PRINT '  [+] Renderer ALTERED to use Infinite Scroll + Toolbar (+/Reload).';
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
PRINT '=== DONE ===';
