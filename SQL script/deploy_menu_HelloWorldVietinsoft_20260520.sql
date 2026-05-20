-- ============================================================================
-- File   : SQL script/deploy_menu_HelloWorldVietinsoft_20260520.sql
-- Tác giả: ví dụ minh hoạ triển khai menu Web kiểu HTML-rendered trên ParadiseHR
-- Mục đích: tạo trọn vẹn 1 menu Web mới tên "Hello world Vietinsoft", hiển thị
--           Top 3 nhân viên có điểm xếp hạng cao nhất tháng hiện tại.
--           Bao gồm:
--           - 3 procedure: API runtime (sp_HelloWorldVietinsoft_GetTopRank) +
--             renderer (sp_HelloWorldVietinsoft_html) +
--             wrapper  (sp_HelloWorldVietinsoft).
--           - 1 record MEN_Menu (MenuID = MnuHEP910, ParentMenuID = MnuHEP000 - Trợ giúp).
--           - 1 record tblSC_Object (Description = MnuHEP910).
--           - Tên đa ngôn ngữ VN + EN qua proc helper [1rename_Mess].
--           - Build HTML cache trong tblHtmlScriptCache cho cả VN và EN.
--           - Phân quyền FullAccess = 32 cho LoginID = 3 (tài khoản admin mặc định).
--           - Refresh cache menu (sp_Men_Menu_AfterSave_Simple, sp_UpdateMenuInUserRight).
-- Tri thức: tham chiếu Knowledge/12_CreateMenu.md (skill file đầy đủ).
-- Cảnh báo: USER tự review và CHẠY. Không tự động thực thi. Khuyến cáo BACKUP DB trước.
-- Idempotent: chạy lại nhiều lần không vỡ dữ liệu.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- ----------------------------------------------------------------------------
-- PHASE C: Procedure API runtime — JS gọi qua AjaxHPAParadise
--          Trả Top 3 nhân viên có tổng ExperiencePonits cao nhất tháng filter.
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_HelloWorldVietinsoft_GetTopRank', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_HelloWorldVietinsoft_GetTopRank;
GO

CREATE PROCEDURE [dbo].[sp_HelloWorldVietinsoft_GetTopRank]
(
    @LoginID     INT,
    @LanguageID  VARCHAR(5) = 'VN',
    @FilterYear  INT        = NULL,   -- NULL = năm hiện tại
    @FilterMonth INT        = NULL    -- NULL = tháng hiện tại
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @FilterYear  IS NULL SET @FilterYear  = YEAR(GETDATE());
    IF @FilterMonth IS NULL SET @FilterMonth = MONTH(GETDATE());

    DECLARE @FromDate DATETIME = DATEFROMPARTS(@FilterYear, @FilterMonth, 1);
    DECLARE @ToDate   DATETIME = DATEADD(MONTH, 1, @FromDate);

    SELECT TOP 3
           r.EmployeeID,
           ISNULL(e.FullName, r.EmployeeID) AS FullName,
           SUM(r.ExperiencePonits)          AS TotalPoints,
           SUM(r.Coin)                      AS TotalCoin,
           @FilterYear                      AS FilterYear,
           @FilterMonth                     AS FilterMonth
    FROM   dbo.tblRank_PersonalRating_Detail r
    LEFT   JOIN dbo.tblEmployee e ON e.EmployeeID = r.EmployeeID
    WHERE  r.CreatedDate >= @FromDate
      AND  r.CreatedDate <  @ToDate
    GROUP  BY r.EmployeeID, e.FullName
    ORDER  BY TotalPoints DESC, r.EmployeeID ASC;
END
GO
PRINT '[OK] Created procedure sp_HelloWorldVietinsoft_GetTopRank (API runtime).';
GO

-- ----------------------------------------------------------------------------
-- PHASE B1: Procedure RENDERER — build HTML/CSS/JS, UPSERT vào tblHtmlScriptCache.
--           JS bên trong gọi sp_HelloWorldVietinsoft_GetTopRank qua AjaxHPAParadise.
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_HelloWorldVietinsoft_html', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_HelloWorldVietinsoft_html;
GO

CREATE PROCEDURE [dbo].[sp_HelloWorldVietinsoft_html]
(
    @LoginID    INT          = 3,
    @LanguageID VARCHAR(5)   = 'VN',
    @isWeb      INT          = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @title    NVARCHAR(200) = N'Hello world Vietinsoft';
    DECLARE @subtitle NVARCHAR(300);
    DECLARE @colNo    NVARCHAR(50);
    DECLARE @colName  NVARCHAR(50);
    DECLARE @colPts   NVARCHAR(50);
    DECLARE @loading  NVARCHAR(100);
    DECLARE @empty    NVARCHAR(200);

    IF @LanguageID = 'EN'
    BEGIN
        SET @subtitle = N'Top 3 employees with highest ranking points this month.';
        SET @colNo    = N'#';
        SET @colName  = N'Employee';
        SET @colPts   = N'Total points';
        SET @loading  = N'Loading...';
        SET @empty    = N'No data for this month.';
    END
    ELSE
    BEGIN
        SET @subtitle = N'Top 3 nhân viên có điểm xếp hạng cao nhất tháng hiện tại.';
        SET @colNo    = N'STT';
        SET @colName  = N'Nhân viên';
        SET @colPts   = N'Tổng điểm';
        SET @loading  = N'Đang tải...';
        SET @empty    = N'Không có dữ liệu cho tháng này.';
    END

    DECLARE @html NVARCHAR(MAX);

    SET @html =
        N'<div id="helloWorldVtsContainer" style="font-family:''Segoe UI'',Arial,sans-serif;max-width:720px;margin:24px auto;padding:24px;border-radius:12px;background:linear-gradient(135deg,#1e3c72 0%,#2a5298 100%);color:#fff;box-shadow:0 6px 24px rgba(0,0,0,.18);">'
      + N'  <h1 style="margin:0 0 8px 0;font-size:26px;letter-spacing:.5px;">' + @title + N'</h1>'
      + N'  <p style="margin:0 0 18px 0;opacity:.92;font-size:14px;">' + @subtitle + N'</p>'
      + N'  <table id="hwVtsTable" style="width:100%;border-collapse:collapse;background:rgba(255,255,255,.08);border-radius:8px;overflow:hidden;">'
      + N'    <thead>'
      + N'      <tr style="background:rgba(0,0,0,.18);text-align:left;">'
      + N'        <th style="padding:10px 12px;width:48px;">' + @colNo   + N'</th>'
      + N'        <th style="padding:10px 12px;">'             + @colName + N'</th>'
      + N'        <th style="padding:10px 12px;text-align:right;width:120px;">' + @colPts + N'</th>'
      + N'      </tr>'
      + N'    </thead>'
      + N'    <tbody id="hwVtsTbody">'
      + N'      <tr><td colspan="3" style="padding:14px;text-align:center;opacity:.8;">' + @loading + N'</td></tr>'
      + N'    </tbody>'
      + N'  </table>'
      + N'</div>'
      + N'<script>'
      + N'(function(){'
      + N'  var EMPTY_MSG = "' + @empty + N'";'
      + N'  function render(rows){'
      + N'    var tb = document.getElementById("hwVtsTbody");'
      + N'    if(!tb) return;'
      + N'    if(!rows || rows.length === 0){'
      + N'      tb.innerHTML = "<tr><td colspan=''3'' style=''padding:14px;text-align:center;opacity:.85;''>" + EMPTY_MSG + "</td></tr>";'
      + N'      return;'
      + N'    }'
      + N'    var html = "";'
      + N'    for(var i=0;i<rows.length;i++){'
      + N'      var r = rows[i];'
      + N'      html += "<tr style=''border-top:1px solid rgba(255,255,255,.12);''>" +'
      + N'              "<td style=''padding:10px 12px;font-weight:600;''>" + (i+1) + "</td>" +'
      + N'              "<td style=''padding:10px 12px;''>" + (r.FullName || r.EmployeeID) + "</td>" +'
      + N'              "<td style=''padding:10px 12px;text-align:right;font-weight:700;''>" + (r.TotalPoints != null ? r.TotalPoints : 0) + "</td>" +'
      + N'              "</tr>";'
      + N'    }'
      + N'    tb.innerHTML = html;'
      + N'  }'
      + N'  AjaxHPAParadise({'
      + N'    data: {'
      + N'      name: "sp_HelloWorldVietinsoft_GetTopRank",'
      + N'      param: ["FilterYear", null, "FilterMonth", null]'
      + N'    },'
      + N'    success: function(res){'
      + N'      try{'
      + N'        var json = typeof res === "string" ? JSON.parse(res) : res;'
      + N'        var rows = [];'
      + N'        if(json && json.data && Array.isArray(json.data)){ rows = json.data[0] || []; }'
      + N'        else if(Array.isArray(json)){ rows = json; }'
      + N'        render(rows);'
      + N'      }catch(e){ render([]); }'
      + N'    },'
      + N'    error: function(){ render([]); }'
      + N'  });'
      + N'})();'
      + N'</script>';

    -- UPSERT cache theo (TableName, LanguageID) — phải fill các cột notnull
    MERGE dbo.tblHtmlScriptCache AS tgt
    USING (SELECT
              'sp_HelloWorldVietinsoft_html' AS TableName,
              @LanguageID                    AS LanguageID,
              '-1'                           AS ScreenType,
              @html                          AS html,
              N''                            AS HtmlParadise,
              N''                            AS paradiseJs,
              '1'                            AS Version,
              N''                            AS VersionData
          ) AS src
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
END
GO
PRINT '[OK] Created procedure sp_HelloWorldVietinsoft_html (renderer).';
GO

-- ----------------------------------------------------------------------------
-- PHASE B2: Procedure WRAPPER — đọc HTML từ cache.
--           App ParadiseWebView2 gọi đúng procedure này khi user mở menu.
-- ----------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_HelloWorldVietinsoft', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_HelloWorldVietinsoft;
GO

CREATE PROCEDURE [dbo].[sp_HelloWorldVietinsoft]
(
    @LoginID    INT,
    @LanguageID VARCHAR(5) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 html
    FROM   dbo.tblHtmlScriptCache
    WHERE  TableName  = 'sp_HelloWorldVietinsoft_html'
      AND  ScreenType = '-1'
      AND  LanguageID = @LanguageID;
END
GO
PRINT '[OK] Created procedure sp_HelloWorldVietinsoft (wrapper).';
GO

-- ----------------------------------------------------------------------------
-- PHASE D–H: tạo metadata menu + object + multilang + cache + permission + refresh.
--           Bọc trong TRY/CATCH + transaction.
-- ----------------------------------------------------------------------------
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @MenuID         VARCHAR(100)  = 'MnuHEP910';
    DECLARE @ParentMenuID   VARCHAR(100)  = 'MnuHEP000';   -- Trợ giúp
    DECLARE @ClassName      VARCHAR(100)  = 'sp_HelloWorldVietinsoft';
    DECLARE @AssemblyName   VARCHAR(100)  = 'DataSetting';
    DECLARE @ObjectName     VARCHAR(200)  = 'DataSetting.sp_HelloWorldVietinsoft';
    DECLARE @NameVN         NVARCHAR(200) = N'Hello world Vietinsoft';
    DECLARE @NameEN         NVARCHAR(200) = N'Hello world Vietinsoft';
    DECLARE @AdminLoginID   INT           = 3;
    DECLARE @FullAccess     NVARCHAR(10)  = N'32';   -- 32 = full quyền

    -- D1: MEN_Menu
    IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = @MenuID)
    BEGIN
        INSERT INTO MEN_Menu
            (MenuID, ClassName, AssemblyName, ParentMenuID, Priority,
             IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb,
             IsUseMobileDevice, isShowInMobileLayOut,
             glyphicon, GroupID,
             IsModal, LinkMenuID, IsCollapsed, ShortcutKeys, SupperAdmin, LargeTile,
             Colors, superForm, DefaultParam, Notification, URL, IsNotAjax,
             InstructionID, showDialog, ProcessDataForNotifyProc,
             ClassName_Audit, ClassName_CT, Showinsuperform, Activity, Separation,
             MobileDeviceGroup, PriorityMobileDevice, IsLeftMenu, NotUsePlatform,
             OptionAuthentication, IconBackColor, IconForeColor, isParentMenu,
             ParentMenuMobileID, IsHiddenInTree)
        VALUES
            (@MenuID, @ClassName, @AssemblyName, @ParentMenuID, 99,
             1, 0, 1, 1,
             1, 1,
             N'Info', @ParentMenuID,
             0, '', 0, '', 0, 0,
             '', '', '', 0, '', 0,
             '', 0, '',
             '', '', 0, N'', 0,
             N'', 0, 0, N'',
             0, N'', N'', 0,
             '', 0);

        PRINT '[OK] Inserted MEN_Menu: ' + @MenuID;
    END
    ELSE
    BEGIN
        UPDATE MEN_Menu
        SET    ClassName            = @ClassName,
               AssemblyName         = @AssemblyName,
               ParentMenuID         = @ParentMenuID,
               IsVisible            = 1,
               ViewOnWeb            = 1,
               isShowLayOutWeb      = 1,
               IsUseMobileDevice    = 1,
               isShowInMobileLayOut = 1,
               glyphicon            = N'Info',
               GroupID              = @ParentMenuID
        WHERE  MenuID = @MenuID;

        PRINT '[OK] Updated MEN_Menu: ' + @MenuID;
    END

    -- D2: tblSC_Object
    DECLARE @ObjectID       INT;
    DECLARE @ParentObjectID INT;

    SELECT TOP 1 @ParentObjectID = ObjectID
    FROM   tblSC_Object
    WHERE  Description = @ParentMenuID;

    IF @ParentObjectID IS NULL SET @ParentObjectID = 1;

    IF NOT EXISTS (SELECT 1 FROM tblSC_Object WHERE Description = @MenuID)
    BEGIN
        SET @ObjectID = ISNULL((SELECT MAX(ObjectID) FROM tblSC_Object), 0) + 1;

        INSERT INTO tblSC_Object
            (ObjectID, ObjectName, Description, Visible, ParentObjectID,
             ParentObjectRightID, ParentRight)
        VALUES
            (@ObjectID, @ObjectName, @MenuID, 1, @ParentObjectID, 0, 0);

        PRINT '[OK] Inserted tblSC_Object: ObjectID=' + CAST(@ObjectID AS VARCHAR(20))
              + ', ObjectName=' + @ObjectName;
    END
    ELSE
    BEGIN
        UPDATE tblSC_Object
        SET    ObjectName     = @ObjectName,
               Visible        = 1,
               ParentObjectID = @ParentObjectID
        WHERE  Description = @MenuID;

        SELECT @ObjectID = ObjectID FROM tblSC_Object WHERE Description = @MenuID;
        PRINT '[OK] Updated tblSC_Object: ObjectID=' + CAST(@ObjectID AS VARCHAR(20));
    END

    -- D3: tên đa ngôn ngữ qua helper [1rename_Mess]
    EXEC dbo.[1rename_Mess] @MenuID, 'VN', @NameVN;
    EXEC dbo.[1rename_Mess] @MenuID, 'EN', @NameEN;
    PRINT '[OK] Saved tblMD_Message (VN + EN) for ' + @MenuID;

    -- F: Build HTML cache cho cả VN và EN
    EXEC dbo.sp_HelloWorldVietinsoft_html @LoginID = @AdminLoginID, @LanguageID = 'VN', @isWeb = 1;
    EXEC dbo.sp_HelloWorldVietinsoft_html @LoginID = @AdminLoginID, @LanguageID = 'EN', @isWeb = 1;
    PRINT '[OK] Built tblHtmlScriptCache cho sp_HelloWorldVietinsoft_html (VN + EN)';

    -- G: Phân quyền mặc định — full quyền cho LoginID = 3
    IF NOT EXISTS (
        SELECT 1 FROM tblSC_Right_Stored
        WHERE  ObjectID = @ObjectID AND LoginID = @AdminLoginID
    )
    BEGIN
        INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess)
        VALUES (@ObjectID, @AdminLoginID, @FullAccess);
        PRINT '[OK] Granted FullAccess=32 to LoginID=' + CAST(@AdminLoginID AS VARCHAR(10))
              + ' on ObjectID=' + CAST(@ObjectID AS VARCHAR(20));
    END
    ELSE
    BEGIN
        UPDATE tblSC_Right_Stored
        SET    FullAccess = @FullAccess
        WHERE  ObjectID = @ObjectID AND LoginID = @AdminLoginID;
        PRINT '[OK] Updated FullAccess=32 cho LoginID=' + CAST(@AdminLoginID AS VARCHAR(10));
    END

    COMMIT TRANSACTION;
    PRINT '========================================================';
    PRINT '[DONE] Menu Hello world Vietinsoft (MnuHEP910) đã sẵn sàng.';
    PRINT '========================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    DECLARE @errMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @errLine INT = ERROR_LINE();
    PRINT '[ERROR] Line ' + CAST(@errLine AS VARCHAR(10)) + ': ' + @errMsg;
    THROW;
END CATCH
GO

-- ----------------------------------------------------------------------------
-- PHASE H: Refresh cache menu (chạy ngoài transaction)
--          User phải logout/login để load lại cây menu sau khi script chạy xong.
-- ----------------------------------------------------------------------------
EXEC dbo.sp_Men_Menu_AfterSave_Simple;
PRINT '[OK] sp_Men_Menu_AfterSave_Simple executed';
GO

EXEC dbo.sp_UpdateMenuInUserRight;
PRINT '[OK] sp_UpdateMenuInUserRight executed';
GO

-- ----------------------------------------------------------------------------
-- VERIFY: in các thành phần đã tạo + test API runtime
-- ----------------------------------------------------------------------------
SELECT m.MenuID, m.ClassName, m.AssemblyName, m.ParentMenuID, m.IsVisible,
       m.IsWeb, m.ViewOnWeb, m.isShowLayOutWeb, m.IsUseMobileDevice,
       o.ObjectID, o.ObjectName,
       msgVN.Content AS NameVN, msgEN.Content AS NameEN,
       (SELECT COUNT(*) FROM tblSC_Right_Stored WHERE ObjectID = o.ObjectID) AS RightStoredRows,
       (SELECT COUNT(*) FROM tblHtmlScriptCache WHERE TableName = m.ClassName + '_html') AS HtmlCacheLangs
FROM   MEN_Menu m
LEFT   JOIN tblSC_Object  o     ON o.Description  = m.MenuID
LEFT   JOIN tblMD_Message msgVN ON msgVN.MessageID = m.MenuID AND msgVN.Language = 'VN'
LEFT   JOIN tblMD_Message msgEN ON msgEN.MessageID = m.MenuID AND msgEN.Language = 'EN'
WHERE  m.MenuID = 'MnuHEP910';
GO

-- Test API runtime — phải trả ≤ 3 dòng (Top 3)
EXEC dbo.sp_HelloWorldVietinsoft_GetTopRank
     @LoginID = 3, @LanguageID = 'VN',
     @FilterYear = NULL, @FilterMonth = NULL;
GO
