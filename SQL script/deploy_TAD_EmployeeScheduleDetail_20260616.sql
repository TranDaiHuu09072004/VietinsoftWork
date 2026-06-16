-- ==============================================================================
-- MENU: Chi tiết nhân sự & Phân ca (sp_TAD_EmployeeScheduleDetail)
-- DATE: 2026-06-16
-- NOTE:
--   - Route cố định: MnuTAD3364
--   - Không ghi tblSC_Right_Stored trong script này để tránh trigger SafeGuard.
--   - Nếu cần cấp quyền, dùng UI phân quyền ParadiseHR hoặc script quyền riêng.
-- ==============================================================================
SET NOCOUNT ON;
GO

-- ==============================================================================
-- 1. METADATA MENU + OBJECT (KHÔNG CẤP QUYỀN TRỰC TIẾP)
-- ==============================================================================
DECLARE @MenuID VARCHAR(100) = 'MnuTAD3364';
DECLARE @ParentMenuID VARCHAR(100) = 'MnuTAD000';
DECLARE @ClassName VARCHAR(100) = 'sp_TAD_EmployeeScheduleDetail';
DECLARE @AssemblyName VARCHAR(100) = 'DataSetting';
DECLARE @ObjectName VARCHAR(200) = @AssemblyName + '.' + @ClassName;
DECLARE @ParentObjectID INT;
DECLARE @ObjectID INT;

SELECT TOP 1 @ParentObjectID = ObjectID
FROM dbo.tblSC_Object
WHERE Description = @ParentMenuID;

IF @ParentObjectID IS NULL SET @ParentObjectID = 1;

IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'sp_TAD_EmployeeScheduleDetail' AND Language = 'VN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content)
    VALUES ('sp_TAD_EmployeeScheduleDetail', 'VN', N'Chi tiết nhân sự & phân ca');
ELSE
    UPDATE dbo.tblMD_Message
       SET Content = N'Chi tiết nhân sự & phân ca'
     WHERE MessageID = 'sp_TAD_EmployeeScheduleDetail' AND Language = 'VN';

IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'sp_TAD_EmployeeScheduleDetail' AND Language = 'EN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content)
    VALUES ('sp_TAD_EmployeeScheduleDetail', 'EN', 'Employee Detail & Shift Assignment');
ELSE
    UPDATE dbo.tblMD_Message
       SET Content = 'Employee Detail & Shift Assignment'
     WHERE MessageID = 'sp_TAD_EmployeeScheduleDetail' AND Language = 'EN';

IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = @MenuID AND Language = 'VN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content)
    VALUES (@MenuID, 'VN', N'Chi tiết nhân sự & phân ca');
ELSE
    UPDATE dbo.tblMD_Message
       SET Content = N'Chi tiết nhân sự & phân ca'
     WHERE MessageID = @MenuID AND Language = 'VN';

IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = @MenuID AND Language = 'EN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content)
    VALUES (@MenuID, 'EN', 'Employee Detail & Shift Assignment');
ELSE
    UPDATE dbo.tblMD_Message
       SET Content = 'Employee Detail & Shift Assignment'
     WHERE MessageID = @MenuID AND Language = 'EN';

IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'EmployeeDetail' AND Language = 'VN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('EmployeeDetail', 'VN', N'Chi tiết nhân sự');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'EmployeeDetail' AND Language = 'EN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('EmployeeDetail', 'EN', 'Employee Detail');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'ShiftAssignment' AND Language = 'VN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('ShiftAssignment', 'VN', N'Phân ca làm việc');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'ShiftAssignment' AND Language = 'EN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('ShiftAssignment', 'EN', 'Shift Assignment');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'TrainingHistory' AND Language = 'VN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('TrainingHistory', 'VN', N'Lịch sử Training');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'TrainingHistory' AND Language = 'EN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('TrainingHistory', 'EN', 'Training History');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'Certificates' AND Language = 'VN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('Certificates', 'VN', N'Chứng chỉ');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'Certificates' AND Language = 'EN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('Certificates', 'EN', 'Certificates');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'ScheduleDate' AND Language = 'VN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('ScheduleDate', 'VN', N'Ngày làm việc');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'ScheduleDate' AND Language = 'EN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('ScheduleDate', 'EN', 'Schedule Date');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'ThisWeek' AND Language = 'VN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('ThisWeek', 'VN', N'Tuần này');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'ThisWeek' AND Language = 'EN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('ThisWeek', 'EN', 'This Week');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'ThisMonth' AND Language = 'VN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('ThisMonth', 'VN', N'Tháng này');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'ThisMonth' AND Language = 'EN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('ThisMonth', 'EN', 'This Month');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'AllTime' AND Language = 'VN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('AllTime', 'VN', N'Tất cả');
IF NOT EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'AllTime' AND Language = 'EN')
    INSERT INTO dbo.tblMD_Message (MessageID, Language, Content) VALUES ('AllTime', 'EN', 'All Time');

IF NOT EXISTS (SELECT 1 FROM dbo.MEN_Menu WHERE MenuID = @MenuID)
BEGIN
    INSERT INTO dbo.MEN_Menu (
        MenuID, ClassName, Priority, IsModal, ParentMenuID, LinkMenuID,
        IsCollapsed, AssemblyName, ShortcutKeys, IsVisible, SupperAdmin,
        LargeTile, Colors, superForm, DefaultParam, Notification, IsWeb,
        URL, IsNotAjax, glyphicon, GroupID, InstructionID, showDialog,
        ProcessDataForNotifyProc, ClassName_Audit, ClassName_CT, Showinsuperform,
        Activity, ViewOnWeb, Separation, MobileDeviceGroup, IsUseMobileDevice,
        PriorityMobileDevice, IsLeftMenu, NotUsePlatform, OptionAuthentication,
        IconBackColor, IconForeColor, isParentMenu, ParentMenuMobileID,
        isShowInMobileLayOut, isShowLayOutWeb, IsHiddenInTree
    )
    VALUES (
        @MenuID, @ClassName, 999, 0, @ParentMenuID, '',
        0, @AssemblyName, '', 1, 0,
        0, '', '', '', 0, 1,
        '', 0, 'Information', @ParentMenuID, '', 0,
        '', '', '', 0,
        'DataSettingListViewActivity', 1, 1, '', 0,
        999, 0, '', 0,
        '', '', 0, '',
        0, 1, 1
    );
END
ELSE
BEGIN
    UPDATE dbo.MEN_Menu
       SET ClassName = @ClassName,
           AssemblyName = @AssemblyName,
           ParentMenuID = @ParentMenuID,
           Priority = 999,
           IsVisible = 1,
           IsWeb = 1,
           ViewOnWeb = 1,
           isShowLayOutWeb = 1,
           IsUseMobileDevice = 0,
           isShowInMobileLayOut = 0,
           IsHiddenInTree = 1,
           IsLeftMenu = 0,
           Activity = 'DataSettingListViewActivity',
           showDialog = 0,
           glyphicon = ISNULL(NULLIF(glyphicon, ''), 'Information'),
           GroupID = @ParentMenuID
     WHERE MenuID = @MenuID;
END

UPDATE dbo.MEN_Menu
   SET IsVisible = 0,
       IsHiddenInTree = 1
 WHERE ClassName = @ClassName
   AND MenuID <> @MenuID;

IF NOT EXISTS (SELECT 1 FROM dbo.tblSC_Object WHERE Description = @MenuID)
BEGIN
    SELECT @ObjectID = ISNULL(MAX(ObjectID), 0) + 1 FROM dbo.tblSC_Object;
    INSERT INTO dbo.tblSC_Object (ObjectID, ObjectName, Description, Visible, ParentObjectID, ParentObjectRightID, ParentRight)
    VALUES (@ObjectID, @ObjectName, @MenuID, 1, @ParentObjectID, 0, 0);
END
ELSE
BEGIN
    UPDATE dbo.tblSC_Object
       SET ObjectName = @ObjectName,
           Visible = 1,
           ParentObjectID = @ParentObjectID
     WHERE Description = @MenuID;
END

-- Không ghi tblSC_Right_Stored tại đây: trigger trg_tblSC_Right_Stored_SafeGuard chặn trong Safe Mode.
-- Cấp quyền bằng UI phân quyền ParadiseHR hoặc script riêng đã được review trong môi trường được phép.
-- Không gọi sp_UpdateMenuInUserRight vì proc đó có thể mở quyền cho nhiều user ngoài phạm vi deploy này.
GO

-- ==============================================================================
-- 2. RUNTIME DATA APIs
-- ==============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_TAD_EmployeeScheduleDetail_GetEmpInfo
    @LoginID INT = NULL,
    @LanguageID VARCHAR(5) = NULL,
    @EmployeeID VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET @LanguageID = ISNULL(NULLIF(@LanguageID, ''), 'VN');

    SELECT TOP 1
           e.EmployeeID,
           ISNULL(e.FullName, e.EmployeeID) AS FullName,
           COALESCE(NULLIF(e.Title, N''), NULLIF(p.PositionName, N''), N'Nhân viên') AS PositionName,
           COALESCE(NULLIF(d.DepartmentName, N''), NULLIF(s.SectionName, N''), NULLIF(g.GroupName, N''), NULLIF(b.BranchName, N''), NULLIF(a.AreaName, N''), N'') AS DepartmentName,
           N'' AS EmployeeLevel,
           dbo.fn_GetStringParamImageByEmployeeID(e.EmployeeID) AS paramImg,
           N'paradisefile_sp_GetFileAPI' AS storeImgName
    FROM dbo.tblEmployee e
    OUTER APPLY (
        SELECT TOP 1 dd.DepartmentID, dd.SectionID, dd.GroupID, dd.PositionID
        FROM dbo.tblDivDepSecPos dd
        WHERE dd.EmployeeID = e.EmployeeID
          AND (dd.ChangedDate IS NULL OR dd.ChangedDate <= CAST(GETDATE() AS DATE))
        ORDER BY ISNULL(dd.ChangedDate, '19000101') DESC
    ) org
    LEFT JOIN dbo.tblDepartment d ON d.DepartmentID = org.DepartmentID
    LEFT JOIN dbo.tblSection s ON s.SectionID = org.SectionID
    LEFT JOIN dbo.tblGroup g ON g.GroupID = org.GroupID
    LEFT JOIN dbo.tblPosition p ON p.PositionID = org.PositionID
    LEFT JOIN dbo.tblBranch b ON b.BranchID = e.BranchID
    LEFT JOIN dbo.tblArea a ON a.AreaID = e.AreaID
    WHERE e.EmployeeID = @EmployeeID;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TAD_EmployeeScheduleDetail_GetShiftOptions
    @LoginID INT,
    @LanguageID VARCHAR(5) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @LanguageID = ISNULL(NULLIF(@LanguageID, ''), 'VN');

    IF OBJECT_ID('dbo.tblShiftSetting', 'U') IS NOT NULL
    BEGIN
        EXEC('SELECT ShiftID AS ID, CAST(ShiftID AS VARCHAR(50)) + '' - '' + ShiftName AS Name FROM dbo.tblShiftSetting WHERE ISNULL(IsInactive, 0) = 0 ORDER BY ShiftName');
    END
    ELSE IF OBJECT_ID('dbo.tblShift', 'U') IS NOT NULL
    BEGIN
        EXEC('SELECT ShiftID AS ID, CAST(ShiftID AS VARCHAR(50)) + '' - '' + ShiftName AS Name FROM dbo.tblShift WHERE ISNULL(IsInactive, 0) = 0 ORDER BY ShiftName');
    END
    ELSE
    BEGIN
        SELECT 1 AS ID, '001 - Ca hành chính' AS Name
        UNION ALL
        SELECT 2 AS ID, '002 - Ca chiều' AS Name
        UNION ALL
        SELECT 3 AS ID, '003 - Ca đêm' AS Name
        UNION ALL
        SELECT 0 AS ID, 'OFF - Nghỉ' AS Name;
    END
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TAD_EmployeeScheduleDetail_GetSchedule
    @LoginID INT,
    @LanguageID VARCHAR(5) = NULL,
    @EmployeeID VARCHAR(50),
    @FilterType VARCHAR(20) = 'ThisMonth',
    @TempTableAPIName VARCHAR(100) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET @LanguageID = ISNULL(NULLIF(@LanguageID, ''), 'VN');

    DECLARE @FromDate DATETIME = NULL;
    DECLARE @ToDate DATETIME = NULL;
    DECLARE @Today DATETIME = CAST(GETDATE() AS DATE);

    IF @FilterType = 'ThisWeek'
    BEGIN
        SET @FromDate = DATEADD(DAY, 1 - DATEPART(WEEKDAY, @Today), @Today);
        SET @ToDate = DATEADD(DAY, 7 - DATEPART(WEEKDAY, @Today), @Today);
    END
    ELSE IF @FilterType = 'ThisMonth'
    BEGIN
        SET @FromDate = DATEADD(DAY, 1 - DAY(@Today), @Today);
        SET @ToDate = EOMONTH(@Today);
    END

    SELECT ROW_NUMBER() OVER(ORDER BY ScheduleDate DESC) AS STT,
           EmployeeID,
           ScheduleDate,
           ShiftID,
           HolidayStatus
    INTO #tmpTableData
    FROM dbo.tblWSchedule
    WHERE EmployeeID = @EmployeeID
      AND (@FromDate IS NULL OR ScheduleDate >= @FromDate)
      AND (@ToDate IS NULL OR ScheduleDate <= @ToDate);

    DECLARE @sql NVARCHAR(MAX);
    IF (@TempTableAPIName = '')
        SET @sql = N'SELECT * FROM #tmpTableData';
    ELSE
        SET @sql = N'SELECT * INTO ' + QUOTENAME(@TempTableAPIName) + N' FROM #tmpTableData';

    EXEC sp_executesql @sql;
    DROP TABLE #tmpTableData;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TAD_EmployeeScheduleDetail_UpdateSchedule
    @LoginID INT,
    @LanguageID VARCHAR(5) = NULL,
    @EmployeeID VARCHAR(50),
    @ScheduleDate DATETIME,
    @ShiftID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET @LanguageID = ISNULL(NULLIF(@LanguageID, ''), 'VN');

    IF EXISTS (SELECT 1 FROM dbo.tblWSchedule WHERE EmployeeID = @EmployeeID AND ScheduleDate = @ScheduleDate)
    BEGIN
        UPDATE dbo.tblWSchedule
           SET ShiftID = @ShiftID
         WHERE EmployeeID = @EmployeeID
           AND ScheduleDate = @ScheduleDate;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.tblWSchedule (EmployeeID, ScheduleDate, ShiftID)
        VALUES (@EmployeeID, @ScheduleDate, @ShiftID);
    END

    SELECT 1 AS Status, N'Cập nhật thành công' AS Message;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TAD_EmployeeScheduleDetail_GetTraining
    @LoginID INT,
    @LanguageID VARCHAR(5) = NULL,
    @EmployeeID VARCHAR(50),
    @TempTableAPIName VARCHAR(100) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET @LanguageID = ISNULL(NULLIF(@LanguageID, ''), 'VN');

    SELECT CAST(NULL AS INT) AS STT,
           CAST(NULL AS INT) AS HistoryID,
           CAST(NULL AS DATETIME) AS DateChanged,
           CAST(NULL AS NVARCHAR(200)) AS StatusName,
           CAST(NULL AS NVARCHAR(500)) AS Note
    INTO #tmpTableData
    WHERE 1 = 0;

    DECLARE @sql NVARCHAR(MAX);
    IF (@TempTableAPIName = '')
        SET @sql = N'SELECT * FROM #tmpTableData';
    ELSE
        SET @sql = N'SELECT * INTO ' + QUOTENAME(@TempTableAPIName) + N' FROM #tmpTableData';

    EXEC sp_executesql @sql;
    DROP TABLE #tmpTableData;
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_TAD_EmployeeScheduleDetail_GetCerts
    @LoginID INT,
    @LanguageID VARCHAR(5) = NULL,
    @EmployeeID VARCHAR(50),
    @TempTableAPIName VARCHAR(100) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET @LanguageID = ISNULL(NULLIF(@LanguageID, ''), 'VN');

    SELECT CAST(NULL AS INT) AS STT,
           CAST(NULL AS INT) AS DetailID,
           CAST(NULL AS NVARCHAR(200)) AS ModuleName,
           CAST(NULL AS DATETIME) AS IssueDate,
           CAST(NULL AS DATETIME) AS ExpiryDate
    INTO #tmpTableData
    WHERE 1 = 0;

    DECLARE @sql NVARCHAR(MAX);
    IF (@TempTableAPIName = '')
        SET @sql = N'SELECT * FROM #tmpTableData';
    ELSE
        SET @sql = N'SELECT * INTO ' + QUOTENAME(@TempTableAPIName) + N' FROM #tmpTableData';

    EXEC sp_executesql @sql;
    DROP TABLE #tmpTableData;
END
GO

-- ==============================================================================
-- 2.5 METADATA CHO CÁC CONTROL TRONG FORM (HPA CONTROLS)
-- ==============================================================================
-- Đã xóa khối INSERT INTO tblCommonControlType_Signed để tránh lỗi Framework của ParadiseHR
GO

-- ==============================================================================
-- 3. UI RENDERER PROCEDURE (_html)
-- ==============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_TAD_EmployeeScheduleDetail_html
    @LoginID INT = NULL,
    @LanguageID VARCHAR(5) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @LanguageID = ISNULL(NULLIF(@LanguageID, ''), 'VN');

    -- Không sử dụng tblCommonControlType_Signed để tránh lỗi ngầm của framework

    DECLARE @html NVARCHAR(MAX) = N'
<style>
:root{--tad-brand:#03412C;--tad-brand2:#0b6b45;--tad-green:#22c55e;--tad-soft:#eaf7f0;--tad-bg:#f4f7f5;--tad-surface:#fff;--tad-surface2:#f8fbf9;--tad-border:#d8e4de;--tad-text:#132019;--tad-muted:#6d7b73;--tad-shadow:0 18px 45px rgba(3,65,44,.10);--tad-radius:18px}
body.dark, body.dark-mode, .dark-mode, .theme-dark, .dx-theme-generic-dark, [data-bs-theme="dark"] {--tad-bg:#12191a;--tad-surface:#1b2425;--tad-surface2:#202b2b;--tad-border:#334344;--tad-text:#f4faf6;--tad-muted:#9eaca5;--tad-soft:rgba(34,197,94,.12);--tad-shadow:0 22px 60px rgba(0,0,0,.35)}

.tad-esd-page{min-height:calc(100vh - 116px);background:var(--tad-bg);color:var(--tad-text);font:14px/1.45 "Segoe UI",Arial,sans-serif;padding:0 18px 18px;box-sizing:border-box}
.tad-hero{background:var(--tad-brand);border-radius:0 0 24px 24px;color:#ffffff !important;padding:22px 24px 66px;display:flex;justify-content:space-between;align-items:flex-start;gap:18px;box-shadow:var(--tad-shadow)}
.tad-hero .tad-name, .tad-hero .tad-sub { color: #ffffff !important; }
.tad-person{display:flex;gap:16px;align-items:center}
.tad-avatar{width:82px;height:82px;border-radius:50%;background:#fff;border:3px solid rgba(255,255,255,.65);object-fit:cover}
.tad-name{font-size:26px;font-weight:900;margin:0 0 3px}
.tad-sub{opacity:.92}
.tad-badges{display:flex;gap:8px;flex-wrap:wrap;margin-top:10px}
.tad-badge{border:1px solid rgba(255,255,255,.45);background:rgba(255,255,255,.16);border-radius:999px;padding:5px 11px;font-size:12px;font-weight:800}
.tad-close{background:rgba(255,255,255,.15);color:#fff;border:1px solid rgba(255,255,255,.35);border-radius:12px;padding:9px 15px;font-weight:800;cursor:pointer}
.tad-profile-card{margin:-44px 20px 0;background:var(--tad-surface);border:1px solid var(--tad-border);border-radius:18px;box-shadow:var(--tad-shadow);padding:18px}
.tad-title{color:var(--tad-green);font-size:20px;font-weight:900;margin:0 0 14px}
.tad-info-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:16px}
.tad-field{border-bottom:1px solid var(--tad-border);padding-bottom:10px}
.tad-field label{display:block;color:var(--tad-muted);font-size:12px;font-weight:800;margin-bottom:4px}
.tad-field b{font-size:14px;color:var(--tad-text)}
.tad-tabs{margin:18px 20px 0;background:var(--tad-surface);border:1px solid var(--tad-border);border-radius:18px;box-shadow:var(--tad-shadow);overflow:hidden}
.tad-tabbar{display:flex;gap:4px;border-bottom:1px solid var(--tad-border);padding:0 14px}
.tad-tab{border:0;background:transparent;color:var(--tad-muted);padding:14px 12px;font-weight:900;cursor:pointer;border-bottom:2px solid transparent}
.tad-tab.active{color:var(--tad-green);border-bottom-color:var(--tad-green)}
.tad-panel{display:none;padding:18px}
.tad-panel.active{display:block}
.tad-cal-head{display:flex;justify-content:space-between;align-items:center;margin-bottom:14px;gap:10px}
.tad-seg{display:flex;border:1px solid var(--tad-border);border-radius:999px;padding:3px;background:var(--tad-surface2)}
.tad-seg button{border:0;background:transparent;color:var(--tad-muted);border-radius:999px;padding:8px 14px;font-weight:900;cursor:pointer}
.tad-seg button.active{background:var(--tad-green);color:#fff;box-shadow:0 8px 18px rgba(34,197,94,.25)}
.tad-calendar{border:1px solid var(--tad-border);border-radius:18px;overflow-x:auto;background:var(--tad-surface)}
.tad-calendar-inner{min-width:700px}
.tad-weekdays,.tad-days{display:grid;grid-template-columns:repeat(7,1fr)}
.tad-weekdays div{background:var(--tad-surface2);border-right:1px solid var(--tad-border);border-bottom:1px solid var(--tad-border);padding:10px;text-align:center;color:var(--tad-muted);font-weight:900}
.tad-weekdays div:last-child{border-right:0}
.tad-day{min-height:104px;border-right:1px solid var(--tad-border);border-bottom:1px solid var(--tad-border);padding:10px;background:var(--tad-surface);cursor:pointer;transition:.15s}
.tad-day.large{min-height:180px}
.tad-day:nth-child(7n){border-right:0}
.tad-day:hover{background:var(--tad-soft)}
.tad-day.empty{background:var(--tad-surface2);cursor:default}
.tad-num{font-weight:900;margin-bottom:8px;color:var(--tad-text)}
.tad-event{border-left:4px solid var(--tad-green);background:linear-gradient(90deg,var(--tad-soft),rgba(34,197,94,.04));border-radius:8px;padding:7px 8px;min-height:50px}
.tad-event.off{border-left-color:#8b9490;background:rgba(148,163,184,.13)}
.tad-shift{font-weight:900;color:var(--tad-brand)}
.dark-mode .tad-shift{color:#fff}
.tad-time,.tad-line{font-size:11px;color:var(--tad-muted);font-weight:700}
.tad-modal-backdrop{position:fixed;inset:0;background:rgba(0,0,0,.45);display:none;align-items:center;justify-content:center;z-index:1000;padding:18px}
.tad-modal{width:min(520px,100%);background:var(--tad-surface);color:var(--tad-text);border:1px solid var(--tad-border);border-radius:20px;box-shadow:0 30px 90px rgba(0,0,0,.35);overflow:hidden;max-height:100%;overflow-y:auto;}
.tad-modal-head{background:var(--tad-brand);color:#ffffff !important;padding:18px 20px;display:flex;justify-content:space-between;gap:12px}
.tad-modal-head h3, .tad-modal-head #popupDateText { color:#ffffff !important; margin:0; }
.tad-modal-head h3 { font-size: 18px; }
.tad-x{border:0;background:rgba(255,255,255,.16);color:#fff;border-radius:10px;width:36px;height:36px;cursor:pointer}
.tad-modal-body{padding:18px;display:grid;gap:13px}
.tad-input-row label{display:block;font-size:12px;font-weight:900;color:var(--tad-muted);margin-bottom:6px}
.tad-input-row > div{width:100%}
.tad-modal-actions{display:flex;justify-content:flex-end;gap:10px;padding:14px 18px 18px}
.tad-btn{border:1px solid var(--tad-border);background:var(--tad-surface);color:var(--tad-text);border-radius:12px;padding:10px 14px;font-weight:900;cursor:pointer}
.tad-btn.primary{background:var(--tad-brand);border-color:var(--tad-brand);color:#fff}

.dark-mode .tad-modal .dx-texteditor-input,
.dark-mode .tad-modal .dx-texteditor-empty { color: #ffffff !important; }
.dark-mode .tad-modal .dx-texteditor { background-color: var(--tad-surface2) !important; border-color: var(--tad-border) !important; }
.dark-mode .tad-modal .dx-dropdowneditor-icon { color: #ffffff !important; }

.dark-mode .dx-dropdowneditor-overlay .dx-popup-content, .dark-mode .dx-list-item { background-color: var(--tad-surface) !important; color: #ffffff !important; }
.dark-mode .dx-dropdowneditor-overlay .dx-popup-wrapper { border-color: var(--tad-border) !important; }
.dark-mode .dx-list-item.dx-state-hover { background-color: var(--tad-soft) !important; }
.dark-mode .dx-list-item.dx-state-focused { background-color: var(--tad-brand) !important; color: #ffffff !important; }

.tad-timeline { display: flex; flex-direction: column; gap: 20px; padding: 10px 0; border-radius: 12px; background: var(--tad-surface); border: 1px solid var(--tad-border); padding: 24px; }
.tad-timeline-title { color: var(--tad-brand); font-size: 18px; font-weight: 800; margin: 0 0 16px 0; }
.dark-mode .tad-timeline-title { color: #fff; }
.tad-timeline-item { position: relative; padding-left: 24px; }
.tad-timeline-item::before { content: ""; position: absolute; left: 5px; top: 22px; bottom: -20px; width: 2px; background: var(--tad-border); }
.tad-timeline-item:last-child::before { display: none; }
@keyframes tadPulse { 0% { box-shadow: 0 0 0 4px var(--tad-soft), 0 0 0 4px rgba(34,197,94, 0.4); } 50% { box-shadow: 0 0 0 4px var(--tad-soft), 0 0 0 10px rgba(34,197,94, 0); } 100% { box-shadow: 0 0 0 4px var(--tad-soft), 0 0 0 4px rgba(34,197,94, 0); } }
.tad-timeline-dot { position: absolute; left: 0; top: 4px; width: 12px; height: 12px; border-radius: 50%; background: var(--tad-brand); animation: tadPulse 2s infinite; }
.dark-mode .tad-timeline-dot, body.dark .tad-timeline-dot { background: var(--tad-green); }
.tad-timeline-content { font-size: 14px; }
.tad-timeline-date { font-weight: 800; color: var(--tad-text); margin-right: 4px; }
.tad-timeline-status { font-weight: 800; color: var(--tad-text); }
.tad-timeline-note { color: var(--tad-muted); margin-left: 6px; }

.tad-cert-container { padding: 0; }
.tad-cert-header { color: var(--tad-brand); font-size: 18px; font-weight: 800; margin: 0 0 16px 0; background: var(--tad-surface); border: 1px solid var(--tad-border); padding: 20px 24px 0 24px; border-bottom: 0; border-radius: 12px 12px 0 0;}
.dark-mode .tad-cert-header { color: #fff; }
.tad-cert-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; background: var(--tad-surface); border: 1px solid var(--tad-border); padding: 0 24px 24px 24px; border-top: 0; border-radius: 0 0 12px 12px; }
.tad-cert-card { background: var(--tad-surface2); border: 1px solid var(--tad-border); border-radius: 12px; padding: 16px; position: relative; }
.tad-cert-title { font-size: 14px; font-weight: 800; color: var(--tad-text); margin: 0 0 16px 0; }
.tad-cert-pic { font-size: 12px; color: var(--tad-muted); margin: 0 0 4px 0; }
.tad-cert-expiry { font-size: 12px; color: var(--tad-muted); margin: 0 0 16px 0; }
.tad-cert-badge { display: inline-block; padding: 4px 10px; background: var(--tad-soft); color: var(--tad-brand); font-size: 12px; font-weight: 800; border-radius: 999px; }
.dark-mode .tad-cert-badge, body.dark .tad-cert-badge { color: var(--tad-green); background: rgba(34,197,94,.2); }

@media(max-width: 1024px) {
    .tad-info-grid { grid-template-columns: repeat(2, 1fr); }
}
@media(max-width: 768px) {
    .tad-hero { flex-direction: column; padding: 16px 16px 50px; }
    .tad-info-grid { grid-template-columns: 1fr; }
    .tad-cert-grid { grid-template-columns: 1fr; }
    .tad-tabbar { overflow-x: auto; white-space: nowrap; }
}
@media(max-width: 480px) {
    .tad-person { flex-direction: column; align-items: flex-start; }
    .tad-modal { width: 100%; height: 100%; border-radius: 0; }
    .tad-cal-head { flex-direction: column; align-items: flex-start; }
}
</style>

<div class="tad-esd-page">
  <div class="tad-hero">
    <div class="tad-person"><img id="tadEsdAvatar" class="tad-avatar" alt="Avatar" src="data:image/svg+xml;utf8,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%22-4 -4 32 32%22 fill=%22%2303412C%22><path d=%22M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z%22/></svg>"><div><h2 id="tadEsdName" class="tad-name">--</h2><div id="tadEsdTitle" class="tad-sub">--</div><div class="tad-badges"><span id="tadEsdDept" class="tad-badge">--</span><span id="tadEsdLevel" class="tad-badge">--</span></div></div></div>
    <button id="tadEsdCloseBtn" class="tad-close" type="button">✕ Đóng</button>
  </div>
  <div class="tad-profile-card"><h3 class="tad-title">Thông tin hồ sơ</h3><div class="tad-info-grid"><div class="tad-field"><label>Họ và tên</label><b id="fFullName">--</b></div><div class="tad-field"><label>Chức danh</label><b id="fPosition">--</b></div><div class="tad-field"><label>Phòng ban</label><b id="fDept">--</b></div><div class="tad-field"><label>Trạng thái đào tạo</label><b id="fStatus">Sẵn sàng đi line</b></div><div class="tad-field"><label>Level</label><b id="fLevel">--</b></div><div class="tad-field"><label>PIC chấm công</label><b id="fPic">Team leader</b></div></div></div>
  <div class="tad-tabs"><div class="tad-tabbar"><button class="tad-tab active" data-tab="history">Lịch sử trạng thái</button><button class="tad-tab" data-tab="schedule">Lịch làm việc & phân ca</button><button class="tad-tab" data-tab="cert">Chứng chỉ / Kỹ năng</button></div>
    <div id="tab-history" class="tad-panel active"><div id="historyGrid" class="tad-timeline"></div></div>
    <div id="tab-schedule" class="tad-panel"><div class="tad-cal-head"><h3 class="tad-title" id="calendarTitle">Lịch tháng</h3><div class="tad-seg"><button class="active" data-filter="ThisWeek">Tuần này</button><button data-filter="ThisMonth">Tháng này</button></div></div><div class="tad-calendar"><div class="tad-calendar-inner"><div class="tad-weekdays"><div>T2</div><div>T3</div><div>T4</div><div>T5</div><div>T6</div><div>T7</div><div>CN</div></div><div id="calendarDays" class="tad-days"></div></div></div></div>
    <div id="tab-cert" class="tad-panel"><div class="tad-cert-container"><div class="tad-cert-header">Chứng chỉ / Kỹ năng</div><div id="certGrid" class="tad-cert-grid"></div></div></div>
  </div>
</div>
<div id="shiftPopup" class="tad-modal-backdrop"><div class="tad-modal"><div class="tad-modal-head"><div><h3>Sửa ca làm việc</h3><div id="popupDateText"></div></div><button id="closeShiftPopup" class="tad-x">✕</button></div><div class="tad-modal-body">
    <div class="tad-input-row">
        <label>Ca làm việc</label>
        <div id="PTAD_ESD_Shift"></div>
    </div>
    <div class="tad-input-row">
        <label>Giờ bắt đầu</label>
        <div id="PTAD_ESD_Start"></div>
    </div>
    <div class="tad-input-row">
        <label>Giờ kết thúc</label>
        <div id="PTAD_ESD_End"></div>
    </div>
    <div class="tad-input-row">
        <label>Vị trí máy / Line</label>
        <div id="PTAD_ESD_Line"></div>
    </div>
</div><div class="tad-modal-actions"><button id="cancelShift" class="tad-btn">Hủy</button><button id="saveShift" class="tad-btn primary">Lưu phân ca</button></div></div></div>

<script>
(function(){
var routeParam=window.sp_TAD_EmployeeScheduleDetail_param||window.MnuTAD3364_param||{};var empId=routeParam.EmployeeID||routeParam.employeeID||routeParam.id||null;var scheduleRows=[];var selectedDay=null;var filterType="ThisWeek";
var LoginID = window.LoginID || routeParam.LoginID || 0;
var LanguageID = window.LanguageID || routeParam.LanguageID || "VN";
var shiftSelectInstance, startBoxInstance, endBoxInstance, lineBoxInstance;

function parseResponse(res){try{return typeof res==="string"?JSON.parse(res):res}catch(e){return {}}}
function showAlert(type,msg){if(window.uiManager&&uiManager.showAlert)uiManager.showAlert({type:type,message:msg});else console.warn(msg)}
function closeForm(){if(typeof window.CloseCurrentForm==="function")window.CloseCurrentForm();else history.back()}
function pad(n){return n<10?"0"+n:n}
function fmt(d){var x=new Date(d);return x.getFullYear()+"-"+pad(x.getMonth()+1)+"-"+pad(x.getDate())}
function viDate(d){var x=new Date(d);return pad(x.getDate())+"/"+pad(x.getMonth()+1)+"/"+x.getFullYear()}
function defaultTime(shift){return String(shift)==="0"||String(shift).toUpperCase()==="OFF"?["",""]:["08:00","16:00"]}

function loadAvatar(info){var imgEl=document.getElementById("tadEsdAvatar");if(!imgEl||!info)return;var defaultSvg=imgEl.getAttribute("src");imgEl.onerror=function(){this.onerror=null;this.src=defaultSvg;};$(imgEl).attr("data-emp-id",empId).attr("title",info.FullName||empId);var avatarInfo={ID:empId,Name:info.FullName||empId,paramImg:info.paramImg,storeImgName:info.storeImgName||"paradisefile_sp_GetFileAPI"};if(window.GlobalEmployeeAvatarCache&&window.GlobalEmployeeAvatarCache[empId]){imgEl.src=window.GlobalEmployeeAvatarCache[empId];return}if(typeof window.loadEmployeeAvatarAsync==="function"){var p=window.loadEmployeeAvatarAsync(empId,avatarInfo);if(p&&typeof p.then==="function")p.then(function(url){if(url)imgEl.src=url});return}if(!avatarInfo.paramImg)return;AjaxHPAParadise({data:{name:avatarInfo.storeImgName,param:decodeURIComponent(avatarInfo.paramImg)},xhrFields:{responseType:"blob"},cache:true,success:function(blob){try{var blobUrl="";if(blob instanceof Blob)blobUrl=URL.createObjectURL(blob);else if(blob instanceof ArrayBuffer)blobUrl=URL.createObjectURL(new Blob([blob],{type:"image/jpeg"}));else if(typeof blob==="string"&&blob.indexOf("blob:")===0)blobUrl=blob;if(blobUrl){window.GlobalEmployeeAvatarCache=window.GlobalEmployeeAvatarCache||{};window.GlobalEmployeeAvatarCache[empId]=blobUrl;imgEl.src=blobUrl}}catch(e){console.warn("Avatar load error",e)}}})}

function loadEmp(){if(!empId){showAlert("error","Thiếu EmployeeID");return}
var imgEl=document.getElementById("tadEsdAvatar");var defaultSvg=imgEl.getAttribute("src");imgEl.onerror=function(){this.onerror=null;this.src=defaultSvg;};
AjaxHPAParadise({data:{name:"sp_TAD_EmployeeScheduleDetail_GetEmpInfo",param:["EmployeeID",empId]},success:function(res){var j=parseResponse(res);var info=j&&j.data&&j.data[0]&&j.data[0][0];if(!info)return;$("#tadEsdName,#fFullName").text(info.FullName||"--");$("#tadEsdTitle,#fPosition").text(info.PositionName||"Nhân viên");$("#tadEsdDept,#fDept").text(info.DepartmentName||"--");$("#tadEsdLevel,#fLevel").text(info.EmployeeLevel?("Level "+info.EmployeeLevel):"--");if(info.paramImg)loadAvatar(info);}})}

function shiftName(id){var ds=window["DataSource_ShiftID"]||[];var f=ds.filter(function(s){return String(s.ID)===String(id)})[0];return f?f.Name:(String(id)==="0"?"OFF - Nghỉ":"Ca hành chính")}
function getRowByDate(dateStr){return scheduleRows.filter(function(r){return fmt(r.ScheduleDate)===dateStr})[0]}

function loadSchedule(){AjaxHPAParadise({data:{name:"sp_LoadGridUsingAPI",param:["ProcName","sp_TAD_EmployeeScheduleDetail_GetSchedule","JsonParamArray",JSON.stringify(["EmployeeID",empId,"FilterType",filterType])]},success:function(res){var j=parseResponse(res);scheduleRows=(j&&j.data&&j.data[0])||[];renderCalendar()},error:function(){scheduleRows=[];renderCalendar()}})}
function renderCalendar(){var today=new Date();var y=today.getFullYear(),m=today.getMonth();var html="";
if(filterType==="ThisWeek"){
var d=today.getDay()||7;var mon=new Date(today);mon.setDate(today.getDate()-d+1);var sun=new Date(today);sun.setDate(today.getDate()-d+7);
$("#calendarTitle").text("Lịch tuần từ "+viDate(mon)+" - "+viDate(sun));
for(var date=new Date(mon);date<=sun;date.setDate(date.getDate()+1)){
var dateStr=fmt(date);var row=getRowByDate(dateStr)||{ScheduleDate:dateStr,ShiftID:(date.getDay()===6||date.getDay()===0?0:1),StartTime:(date.getDay()===6||date.getDay()===0?"":"08:00"),EndTime:(date.getDay()===6||date.getDay()===0?"":"16:00"),WorkLine:"Line 12"};
var name=shiftName(row.ShiftID);var off=String(name).toUpperCase().indexOf("OFF")>=0||String(row.ShiftID)==="0";
var st=row.StartTime||defaultTime(row.ShiftID)[0],en=row.EndTime||defaultTime(row.ShiftID)[1],line=row.WorkLine||"Line 12";
html+="<div class=\"tad-day large\" data-date=\""+dateStr+"\"><div class=\"tad-num\">"+date.getDate()+"</div><div class=\"tad-event "+(off?"off":"")+"\"><div class=\"tad-shift\">"+name+"</div><div class=\"tad-time\">"+(st&&en?st+" - "+en:"Nghỉ")+"</div><div class=\"tad-line\">"+line+"</div></div></div>";
}
}else{
$("#calendarTitle").text("Lịch tháng "+pad(m+1)+"/"+y);
var first=new Date(y,m,1),last=new Date(y,m+1,0);var start=(first.getDay()+6)%7;
for(var i=0;i<start;i++)html+="<div class=\"tad-day empty\"></div>";
for(var dt=1;dt<=last.getDate();dt++){
var date2=new Date(y,m,dt),dateStr2=fmt(date2);
var row2=getRowByDate(dateStr2)||{ScheduleDate:dateStr2,ShiftID:(date2.getDay()===6||date2.getDay()===0?0:1),StartTime:(date2.getDay()===6||date2.getDay()===0?"":"08:00"),EndTime:(date2.getDay()===6||date2.getDay()===0?"":"16:00"),WorkLine:"Line 12"};
var name2=shiftName(row2.ShiftID);var off2=String(name2).toUpperCase().indexOf("OFF")>=0||String(row2.ShiftID)==="0";
var st2=row2.StartTime||defaultTime(row2.ShiftID)[0],en2=row2.EndTime||defaultTime(row2.ShiftID)[1],line2=row2.WorkLine||"Line 12";
html+="<div class=\"tad-day\" data-date=\""+dateStr2+"\"><div class=\"tad-num\">"+dt+"</div><div class=\"tad-event "+(off2?"off":"")+"\"><div class=\"tad-shift\">"+name2+"</div><div class=\"tad-time\">"+(st2&&en2?st2+" - "+en2:"Nghỉ")+"</div><div class=\"tad-line\">"+line2+"</div></div></div>";
}
}
$("#calendarDays").html(html)}

function openPopup(dateStr){
    selectedDay=dateStr;
    var dObj=dateStr?new Date(dateStr):new Date();
    $("#popupDateText").text("Ngày "+pad(dObj.getDate())+"/"+pad(dObj.getMonth()+1)+"/"+dObj.getFullYear());
    var r=getRowByDate(dateStr);
    var shift=r?r.ShiftID:0;
    shiftSelectInstance.option("value",shift);
    var timeArr=defaultTime(shift);
    if(timeArr[0]) startBoxInstance.option("value", new Date("1970/01/01 "+timeArr[0])); else startBoxInstance.option("value", null);
    if(timeArr[1]) endBoxInstance.option("value", new Date("1970/01/01 "+timeArr[1])); else endBoxInstance.option("value", null);
    lineBoxInstance.option("value", r?r.WorkLine:"");
    $("#shiftPopup").css("display","flex");
}

function savePopup(){
    var shift=shiftSelectInstance.option("value");
    var stObj=startBoxInstance.option("value");
    var enObj=endBoxInstance.option("value");
    var line=lineBoxInstance.option("value")||"";
    var st=stObj?DevExpress.localization.formatDate(stObj,"HH:mm"):"";
    var en=enObj?DevExpress.localization.formatDate(enObj,"HH:mm"):"";
    AjaxHPAParadise({data:{name:"sp_TAD_EmployeeScheduleDetail_UpdateSchedule",param:["EmployeeID",empId,"ScheduleDate",selectedDay,"ShiftID",shift,"StartTime",st,"EndTime",en,"WorkLine",line]},success:function(){showAlert("success","Đã lưu phân ca");$("#shiftPopup").hide();loadSchedule()},error:function(){showAlert("error","Không lưu được phân ca")}})}

function initControls() {
    shiftSelectInstance = $("#PTAD_ESD_Shift").dxSelectBox({ valueExpr: "ID", displayExpr: "Name", searchEnabled: true, width: "100%", placeholder: "Chọn ca..." }).dxSelectBox("instance");
    startBoxInstance = $("#PTAD_ESD_Start").dxDateBox({ type: "time", displayFormat: "HH:mm", width: "100%", placeholder: "00:00" }).dxDateBox("instance");
    endBoxInstance = $("#PTAD_ESD_End").dxDateBox({ type: "time", displayFormat: "HH:mm", width: "100%", placeholder: "00:00" }).dxDateBox("instance");
    lineBoxInstance = $("#PTAD_ESD_Line").dxTextBox({ width: "100%", placeholder: "Nhập vị trí..." }).dxTextBox("instance");
    
    shiftSelectInstance.on("valueChanged", function(e){
        var timeArr = defaultTime(e.value);
        if(timeArr[0]) startBoxInstance.option("value", new Date("1970/01/01 " + timeArr[0])); else startBoxInstance.option("value", null);
        if(timeArr[1]) endBoxInstance.option("value", new Date("1970/01/01 " + timeArr[1])); else endBoxInstance.option("value", null);
    });
    var historyData = [
        { DateChanged: "2026-06-01", StatusName: "FBT training", Note: "Hoàn tất đào tạo hội nhập và an toàn." },
        { DateChanged: "2026-06-04", StatusName: "Đào tạo module lý thuyết", Note: "Score 96%, đủ điều kiện qua bước tiếp theo." },
        { DateChanged: "2026-06-10", StatusName: "Sau cert - sẵn sàng đi line", Note: "Đủ điều kiện nhận line sản xuất." }
    ];
    var hHtml = "<div class=\"tad-timeline-title\">Lịch sử trạng thái Training</div>";
    historyData.forEach(function(item) {
        hHtml += "<div class=\"tad-timeline-item\">" +
                 "<div class=\"tad-timeline-dot\"></div>" +
                 "<div class=\"tad-timeline-content\">" +
                 "<span class=\"tad-timeline-date\">" + viDate(item.DateChanged) + " &middot; </span>" +
                 "<span class=\"tad-timeline-status\">" + item.StatusName + "</span>" +
                 "<span class=\"tad-timeline-note\">" + item.Note + "</span>" +
                 "</div></div>";
    });
    $("#historyGrid").html(hHtml);
    
    var certData = [
        { ModuleName: "FBT training", PIC: "Dedicated trainer", ExpiryDate: "", Score: "Đạt - 96%" },
        { ModuleName: "Module Assembly L2", PIC: "Dedicated trainer", ExpiryDate: "2026-12-31", Score: "Đạt - 93%" },
        { ModuleName: "Cert Assembly L2", PIC: "Team leader", ExpiryDate: "2026-12-31", Score: "Đạt - 90%" }
    ];
    var cHtml = "";
    certData.forEach(function(item) {
        cHtml += "<div class=\"tad-cert-card\">" +
                 "<h4 class=\"tad-cert-title\">" + item.ModuleName + "</h4>" +
                 "<div class=\"tad-cert-pic\">PIC: " + item.PIC + "</div>" +
                 "<div class=\"tad-cert-expiry\">Hiệu lực: " + (item.ExpiryDate ? viDate(item.ExpiryDate) : "Không giới hạn") + "</div>" +
                 "<div class=\"tad-cert-badge\">" + item.Score + "</div>" +
                 "</div>";
    });
    $("#certGrid").html(cHtml);
}

$(function(){
    initControls();
    $("#tadEsdCloseBtn").on("click",closeForm);
    $(".tad-tab").on("click",function(){var t=$(this).data("tab");$(".tad-tab").removeClass("active");$(this).addClass("active");$(".tad-panel").removeClass("active");$("#tab-"+t).addClass("active");if(t==="schedule"&&!scheduleRows.length)loadSchedule()});
    $(".tad-seg button").on("click",function(){$(".tad-seg button").removeClass("active");$(this).addClass("active");filterType=$(this).data("filter");loadSchedule()});
    $(document).on("click",".tad-day:not(.empty)",function(){openPopup($(this).data("date"))});
    $("#closeShiftPopup,#cancelShift").on("click",function(){$("#shiftPopup").hide()});
    $("#saveShift").on("click",savePopup);
    loadEmp();
    
    // Tải dữ liệu Ca làm việc thủ công để tránh lỗi thư viện loadDataSourceCommon
    window["DataSource_ShiftID"] = [];
    AjaxHPAParadise({
        data: { name: "sp_TAD_EmployeeScheduleDetail_GetShiftOptions", param: ["LoginID", LoginID, "LanguageID", LanguageID] },
        success: function(res) {
            var j = parseResponse(res);
            window["DataSource_ShiftID"] = (j && j.data && j.data[0]) || [];
            try {
                var shiftInst = $("#PTAD_ESD_Shift").dxSelectBox("instance");
                if (shiftInst) shiftInst.option("dataSource", window["DataSource_ShiftID"]);
            } catch(e){}
        }
    });
    
    // Đợi control selectbox tải xong datasource rồi mới render calendar
    var retries=0;
    var checkDs = setInterval(function(){
        if(window["DataSource_ShiftID"] && window["DataSource_ShiftID"].length > 0 || retries > 20){
            clearInterval(checkDs);
            loadSchedule();
        }
        retries++;
    }, 100);
});

})();
</script>';

    SELECT @html AS html;
END
GO

-- ==============================================================================
-- 4. WRAPPER PROCEDURE
-- ==============================================================================
CREATE OR ALTER PROCEDURE dbo.sp_TAD_EmployeeScheduleDetail
    @EmployeeID VARCHAR(50) = NULL,
    @LoginID INT = NULL,
    @LanguageID VARCHAR(5) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @LanguageID = ISNULL(NULLIF(@LanguageID, ''), 'VN');

    DECLARE @html NVARCHAR(MAX);

    SELECT TOP 1 @html = html
    FROM dbo.tblHtmlScriptCache
    WHERE TableName = 'sp_TAD_EmployeeScheduleDetail_html'
      AND ScreenType = -1
      AND LanguageID = @LanguageID;

    IF @html IS NULL OR @html = N''
    BEGIN
        BEGIN TRY
            DECLARE @result TABLE (html NVARCHAR(MAX));
            INSERT INTO @result
            EXEC dbo.sp_TAD_EmployeeScheduleDetail_html @LoginID = @LoginID, @LanguageID = @LanguageID;
            SELECT TOP 1 @html = html FROM @result;
        END TRY
        BEGIN CATCH
            SET @html = N'<div style="padding:40px; color:red; font-family:sans-serif;"><h3>LỖI HỆ THỐNG PARADISE HR:</h3><p>' + ERROR_MESSAGE() + N'</p></div>';
        END CATCH
    END

    SELECT @html AS html;
END
GO

-- ==============================================================================
-- 5. BUILD CACHE & REFRESH MENU
-- ==============================================================================
DELETE FROM dbo.tblHtmlScriptCache WHERE TableName = 'sp_TAD_EmployeeScheduleDetail_html';
EXEC dbo.sp_GenerateHTMLScript 'sp_TAD_EmployeeScheduleDetail_html';
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_TAD_EmployeeScheduleDetail';
GO

SELECT MenuID, ClassName, IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb, IsHiddenInTree
FROM dbo.MEN_Menu
WHERE MenuID = 'MnuTAD3364';

SELECT ObjectID, ObjectName, Description
FROM dbo.tblSC_Object
WHERE Description = 'MnuTAD3364';

SELECT TableName, LanguageID, DATALENGTH(html) AS HtmlBytes
FROM dbo.tblHtmlScriptCache
WHERE TableName = 'sp_TAD_EmployeeScheduleDetail_html';
GO

PRINT N'[DEPLOY THÀNH CÔNG] Menu Chi tiết nhân sự & phân ca (sp_TAD_EmployeeScheduleDetail)';
GO
