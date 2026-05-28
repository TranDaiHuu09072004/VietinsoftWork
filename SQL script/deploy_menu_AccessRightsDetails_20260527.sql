SET NOCOUNT ON; SET XACT_ABORT ON;
GO

-- =========================================================================
-- 1. Data Runtime Procedure (Lấy dữ liệu Grid)
-- =========================================================================
CREATE OR ALTER PROCEDURE dbo.sp_AccessRightsDetailsList
(
    @LoginID INT = 3, 
    @LanguageID VARCHAR(5) = 'VN',
    @TempTableAPIName VARCHAR(100) = ''
)
AS BEGIN
    SET NOCOUNT ON;
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;
    
    SELECT ROW_NUMBER() OVER(ORDER BY m.MenuID) AS STT,
           m.MenuID,
           ISNULL(msg.Content, m.MenuID) AS MenuName,
           r.LoginID,
           r.FullAccess
    INTO #tmpTableData
    FROM MEN_Menu m
    INNER JOIN tblSC_Object o ON o.Description = m.MenuID
    INNER JOIN tblSC_Right_Stored r ON o.ObjectID = r.ObjectID
    LEFT JOIN tblMD_Message msg ON msg.MessageID = m.MenuID AND msg.Language = @LanguageID;
    
    DECLARE @sql NVARCHAR(MAX);
    IF (@TempTableAPIName = '')
        SET @sql = N'SELECT * FROM #tmpTableData';
    ELSE
        SET @sql = N'SELECT * INTO ' + QUOTENAME(@TempTableAPIName) + N' FROM #tmpTableData';
        
    EXEC sp_executesql @sql;
    DROP TABLE #tmpTableData;
END
GO

-- =========================================================================
-- 2. Config-driven UI (Khai báo Grid)
-- =========================================================================
DELETE FROM tblCommonControlType_Signed WHERE TableName = 'sp_AccessRightsDetails_html';

INSERT INTO tblCommonControlType_Signed (TableName, ColumnName, Type, Layout, DataSourceSP, SPLoadData, UID) VALUES 
('sp_AccessRightsDetails_html', 'GridAccessRights', 'hpaControlGrid_Duc', NULL, NULL, 'sp_AccessRightsDetailsList', 'P0000000000000000AccessRightG01'),
('sp_AccessRightsDetails_html', 'MenuID', NULL, 'Grid_View', NULL, NULL, 'P0000000000000000AccessRightC01'),
('sp_AccessRightsDetails_html', 'MenuName', NULL, 'Grid_View', NULL, NULL, 'P0000000000000000AccessRightC02'),
('sp_AccessRightsDetails_html', 'LoginID', NULL, 'Grid_View', NULL, NULL, 'P0000000000000000AccessRightC03'),
('sp_AccessRightsDetails_html', 'FullAccess', NULL, 'Grid_View', NULL, NULL, 'P0000000000000000AccessRightC04');

UPDATE tblCommonControlType_Signed SET DisplayName = N'Mã Menu', GridColumnName = 'GridAccessRights', AllowSorting = 1, AllowFiltering = 1 WHERE UID = 'P0000000000000000AccessRightC01';
UPDATE tblCommonControlType_Signed SET DisplayName = N'Tên Menu', GridColumnName = 'GridAccessRights', AllowSorting = 1, AllowFiltering = 1 WHERE UID = 'P0000000000000000AccessRightC02';
UPDATE tblCommonControlType_Signed SET DisplayName = N'Tài khoản', GridColumnName = 'GridAccessRights', AllowSorting = 1, AllowFiltering = 1 WHERE UID = 'P0000000000000000AccessRightC03';
UPDATE tblCommonControlType_Signed SET DisplayName = N'Quyền', GridColumnName = 'GridAccessRights', AllowSorting = 1, AllowFiltering = 1 WHERE UID = 'P0000000000000000AccessRightC04';

EXEC sptblCommonControlType_Signed_DUC 'sp_AccessRightsDetails_html';
GO

-- =========================================================================
-- 3. Renderer Procedure (HTML/JS generator)
-- =========================================================================
CREATE OR ALTER PROCEDURE dbo.sp_AccessRightsDetails_html (@LoginID INT=3, @LanguageID VARCHAR(5)='VN', @isWeb INT=1)
AS BEGIN
    SET NOCOUNT ON;
    DECLARE @loadUI NVARCHAR(MAX), @loadData NVARCHAR(MAX);
    SELECT @loadUI = ISNULL(loadUI, ''), @loadData = ISNULL(loadData, '') 
    FROM tblCommonControlType_Signed 
    WHERE UID = 'P0000000000000000AccessRightG01';

    DECLARE @title NVARCHAR(200) = CASE WHEN @LanguageID = 'EN' THEN N'Access Rights Details' ELSE N'Chi tiết quyền truy cập' END;

    DECLARE @html NVARCHAR(MAX) = N'
    <div id="sp_AccessRightsDetails_html" style="height:100%; display:flex; flex-direction:column; padding: 10px;">
        <h4 style="margin-bottom: 15px;">' + @title + N'</h4>
        <div id="GridAccessRights" style="flex:1;"></div>
    </div>
    <script>(() => {
        // Polyfill cho HTML-rendered menu
        if(typeof window.LoginID === "undefined") window.LoginID = ' + CAST(@LoginID AS NVARCHAR(20)) + N';
        if(typeof window.LanguageID === "undefined") window.LanguageID = "' + @LanguageID + N'";
        if(typeof window.loadDataSourceCommon === "undefined") window.loadDataSourceCommon = function(){};
        if(typeof window.hpaUtils === "undefined") window.hpaUtils = { loadAvatar:function(){}, highlightText:function(t,s){return t;} };
        if(typeof window.RemoveToneMarks_Js === "undefined") window.RemoveToneMarks_Js = function(s){ return String(s||"").normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase(); };
        if(typeof window.uiManager === "undefined") window.uiManager = { showAlert: function(opt){ console.warn(opt); } };

        let DataSource = [];
        ' + @loadUI + N'
        
        function ReloadData() {
            var gridInstance = InstanceGridAccessRightsP0000000000000000AccessRightG01;
            if(!gridInstance) return;
            
            const dataStore = new DevExpress.data.CustomStore({
                key: "MenuID",
                load: function (loadOptions) {
                    const deferred = $.Deferred();
                    let params = [];
                    params.push("@ProcName", "sp_AccessRightsDetailsList");
                    params.push("@ProcParam", "LoginID=" + window.LoginID + ", LanguageID=" + window.LanguageID);
                    params.push("@Take", loadOptions.take || 50);
                    params.push("@Skip", loadOptions.skip || 0);
                    if (loadOptions.requireTotalCount) params.push("@RequireTotalCount", 1);
                    
                    AjaxHPAParadise({
                        data: { name: "sp_LoadGridUsingAPI", param: params },
                        success: function (res) {
                            const json = typeof res === "string" ? JSON.parse(res) : res;
                            const results = Array.isArray(json?.data?.[0]) ? json.data[0] : [];
                            let result = { data: results };
                            if (loadOptions.requireTotalCount)
                                result.totalCount = json?.data?.[1]?.[0]?.TotalCount ?? 0;
                            deferred.resolve(result);
                        },
                        error: () => deferred.reject("Data Loading Error")
                    });
                    return deferred.promise();
                }
            });

            gridInstance.beginUpdate();
            gridInstance.option("remoteOperations", { paging:true, filtering:true, sorting:true, searching:true });
            gridInstance.option({
                "scrolling.mode": "infinite",
                "scrolling.rowRenderingMode": "virtual",
                "scrolling.preloadEnabled": false,
                "paging.enabled": true,
                "paging.pageSize": 50,
                "pager.visible": false,
                "dataSource": dataStore
            });
            gridInstance.endUpdate();
            
            ' + @loadData + N'
        }
        ReloadData();
    })();
    </script>';

    MERGE dbo.tblHtmlScriptCache AS tgt
    USING (SELECT 'sp_AccessRightsDetails_html' AS TableName, @LanguageID AS LanguageID,
                  '-1' AS ScreenType, @html AS html,
                  N'' AS HtmlParadise, N'' AS paradiseJs,
                  '1' AS Version, CAST(NULL AS VARBINARY(MAX)) AS VersionData) AS src
       ON tgt.TableName = src.TableName AND tgt.LanguageID = src.LanguageID
    WHEN MATCHED THEN UPDATE SET tgt.ScreenType=src.ScreenType, tgt.html=src.html,
                                 tgt.HtmlParadise=src.HtmlParadise, tgt.paradiseJs=src.paradiseJs,
                                 tgt.Version=src.Version
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version)
        VALUES (src.TableName, src.LanguageID, src.ScreenType, src.html, src.HtmlParadise, src.paradiseJs, src.Version);

    SELECT @html AS html;
END
GO

-- =========================================================================
-- 4. Wrapper procedure
-- =========================================================================
CREATE OR ALTER PROCEDURE dbo.sp_AccessRightsDetails (@LoginID INT=3, @LanguageID VARCHAR(5)='VN', @isWeb INT=1)
AS BEGIN
    SET NOCOUNT ON;
    SELECT TOP 1 html FROM tblHtmlScriptCache WHERE TableName='sp_AccessRightsDetails_html' AND ScreenType='-1' AND LanguageID=@LanguageID;
END
GO

-- =========================================================================
-- 5. Metadata Menu (Phase D)
-- =========================================================================
EXEC dbo.sp_s_CreateMenu
     @Text=N'Chi tiết quyền truy cập', @TextEN='Access Rights Details',
     @ClassName='sp_AccessRightsDetails',
     @ParentMenuID='MnuHRS000',
     @AssemblyName='DataSetting',
     @Option=1, @LoginIDList='3';

-- Tránh trùng lặp layout khi chạy nhiều lần
DELETE FROM tblDataSetting WHERE TableName = 'sp_AccessRightsDetails';
DELETE FROM tblDataSettingLayout WHERE TableName = 'sp_AccessRightsDetails';

INSERT INTO tblDataSetting (TableName, ViewName, IsProcedure, IsShowLayout, ColumnOrderBy, ColumnDataType, ColumnHide, ControlHiddenInShowLayout)
VALUES ('sp_AccessRightsDetails', 'sp_AccessRightsDetails', 1, 1, 'html&0', 'html&ViewHtml', 'isReadOnlyRow,dtftxxENGColumns', 'grdTableEditor,txtFilter,btnReload,btnFWDelete,btnFWReset,btnExport,btnFWSave,btnFWAdd,isReadOnlyRow,dtftxxENGColumns');

INSERT INTO tblDataSettingLayout (TableName, Name, ControlName, NamePa, Type, ControlType)
VALUES 
('sp_AccessRightsDetails', 'root',    '',     '',     'g', ''),
('sp_AccessRightsDetails', 'lblhtml', 'html', 'root', 'i', 'ParadiseWebView2');

-- Phase E: Cờ menu
UPDATE MEN_Menu
   SET IsVisible=1, IsWeb=0, ViewOnWeb=0, isShowLayOutWeb=0,
       IsUseMobileDevice=1, isShowInMobileLayOut=0,
       glyphicon=N'Info', GroupID='MnuHRS000', Priority=99
 WHERE ClassName='sp_AccessRightsDetails';
GO

-- =========================================================================
-- 6. Build Cache (Phase F)
-- =========================================================================
DELETE FROM tblHtmlScriptCache WHERE TableName = 'sp_AccessRightsDetails_html';
EXEC dbo.sp_GenerateHTMLScript 'sp_AccessRightsDetails_html';
GO

-- =========================================================================
-- 7. Cấp quyền cho LoginID 23 (Phase G)
-- =========================================================================
DECLARE @ObjID INT;
SELECT @ObjID = ObjectID FROM tblSC_Object WHERE ObjectName = 'DataSetting.sp_AccessRightsDetails';
IF @ObjID IS NOT NULL
BEGIN
    DELETE FROM tblSC_Right_Stored WHERE ObjectID = @ObjID AND LoginID IN (3, 23);
    INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@ObjID, 3, '32'), (@ObjID, 23, '32');
END
GO

-- =========================================================================
-- 8. Refresh Menu Cache (Phase H)
-- =========================================================================
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_AccessRightsDetails';
GO
