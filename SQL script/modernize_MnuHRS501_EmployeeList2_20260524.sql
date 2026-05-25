-- ============================================================================
-- File      : SQL script/modernize_MnuHRS501_EmployeeList2_20260524.sql
-- Mục đích  : Chuyển đổi cấu hình menu MnuHRS501 'Danh sách nhân viên'
--             sang chuẩn cấu hình web mới (Cách 2: Pure HTML Render).
--             - Đặt cờ IsWeb = 1, isShowLayOutWeb = 1.
--             - Xóa cấu hình cũ trong tblDataSetting và tblDataSettingLayout.
--             - Cập nhật wrapper HR_EmployeeList2 để SELECT html từ cache TableName='HR_EmployeeList2'.
-- Idempotent: Hỗ trợ chạy lại nhiều lần an toàn (IF NOT EXISTS, CREATE OR ALTER).
-- Tác giả   : Antigravity
-- Ngày tạo  : 2026-05-24
-- ============================================================================

SET NOCOUNT ON;
GO

PRINT N'BẮT ĐẦU CHUYỂN ĐỔI MNUHRS501 SANG CẤU HÌNH WEB MỚI...';
GO

-- ============================================================================
-- PHASE 1: Cập nhật MEN_Menu cho MnuHRS501 theo cách cấu hình mới (Cách 2)
-- ============================================================================
PRINT N'1. Đang cập nhật MEN_Menu cho MnuHRS501 (IsWeb = 1, isShowLayOutWeb = 1)...';
GO

IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = 'MnuHRS501')
BEGIN
    INSERT INTO MEN_Menu (
        MenuID, ClassName, Priority, IsModal, ParentMenuID, LinkMenuID, IsCollapsed, 
        AssemblyName, ShortcutKeys, IsVisible, SupperAdmin, LargeTile, Colors, 
        superForm, DefaultParam, Notification, IsWeb, URL, IsNotAjax, glyphicon, 
        GroupID, InstructionID, showDialog, ProcessDataForNotifyProc, ClassName_Audit, 
        ClassName_CT, Showinsuperform, Activity, ViewOnWeb, Separation, MobileDeviceGroup, 
        IsUseMobileDevice, PriorityMobileDevice, IsLeftMenu, NotUsePlatform, 
        OptionAuthentication, IconBackColor, IconForeColor, isParentMenu, 
        ParentMenuMobileID, isShowInMobileLayOut, isShowLayOutWeb, IsHiddenInTree
    )
    VALUES (
        'MnuHRS501', N'HR_EmployeeList2', 1, 0, 'MnuHRS000', '', 0, 
        'DataSetting', '', 1, 0, 1, '#4787ed', 
        '', '', 0, 1, '', 0, 'UserList', 
        'HumanGroup', 'InsMnuHRS142', 0, '', '', 
        '', 0, '', 0, 0, 'MnuHRS000', 
        0, 0, 0, '2', 
        0, '', '', 0, 
        '', 0, 1, 0
    );
    PRINT N'  [OK] Đã INSERT MEN_Menu MnuHRS501 theo chuẩn Web mới.';
END
ELSE
BEGIN
    UPDATE MEN_Menu
    SET
        ClassName            = N'HR_EmployeeList2',
        Priority             = 1,
        IsModal              = 0,
        ParentMenuID         = 'MnuHRS000',
        LinkMenuID           = '',
        IsCollapsed          = 0,
        AssemblyName         = 'DataSetting',
        ShortcutKeys         = '',
        IsVisible            = 1,
        SupperAdmin          = 0,
        LargeTile            = 1,
        Colors               = '#4787ed',
        superForm            = '',
        DefaultParam         = '',
        Notification         = 0,
        IsWeb                = 1,         -- Bật IsWeb
        URL                  = '',
        IsNotAjax            = 0,
        glyphicon            = 'UserList',
        GroupID              = 'HumanGroup',
        InstructionID        = 'InsMnuHRS142',
        showDialog           = 0,
        ProcessDataForNotifyProc = '',
        ClassName_Audit      = '',
        ClassName_CT         = '',
        Showinsuperform      = 0,
        Activity             = '',
        ViewOnWeb            = 0,
        Separation           = 0,
        MobileDeviceGroup    = 'MnuHRS000',
        IsUseMobileDevice    = 0,         -- Tắt MobileDevice
        PriorityMobileDevice = 0,
        IsLeftMenu           = 0,
        NotUsePlatform       = '2',
        OptionAuthentication = 0,
        IconBackColor        = '',
        IconForeColor        = '',
        isParentMenu         = 0,
        ParentMenuMobileID   = '',
        isShowInMobileLayOut = 0,
        isShowLayOutWeb      = 1,         -- Bật isShowLayOutWeb
        IsHiddenInTree       = 0
    WHERE MenuID = 'MnuHRS501';
    PRINT N'  [OK] Đã cập nhật cờ IsWeb = 1 và isShowLayOutWeb = 1.';
END
GO

-- ============================================================================
-- PHASE 2: Cấu hình tblSC_Object cho MnuHRS501
-- ============================================================================
PRINT N'2. Đang cấu hình tblSC_Object cho MnuHRS501...';
GO

IF NOT EXISTS (SELECT 1 FROM tblSC_Object WHERE Description = 'MnuHRS501')
BEGIN
    DECLARE @NewObjectID INT;
    SELECT @NewObjectID = MAX(ObjectID) + 1 FROM tblSC_Object;

    INSERT INTO tblSC_Object (ObjectID, ObjectName, Description, Visible, ParentObjectID)
    VALUES (@NewObjectID, N'DataSetting.HR_EmployeeList2', 'MnuHRS501', 1, 1);
    
    IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblSC_Right_Stored')
    BEGIN
        INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess)
        VALUES (@NewObjectID, 3, '32');
    END
    PRINT N'  [OK] Đã INSERT tblSC_Object.';
END
ELSE
BEGIN
    UPDATE tblSC_Object
    SET ObjectName = N'DataSetting.HR_EmployeeList2',
        Visible = 1,
        ParentObjectID = 1
    WHERE Description = 'MnuHRS501';
    PRINT N'  [OK] Đã UPDATE tblSC_Object.';
END
GO

-- ============================================================================
-- PHASE 3: Thiết lập nhãn đa ngôn ngữ trong tblMD_Message
-- ============================================================================
PRINT N'3. Đang cấu hình tên menu đa ngôn ngữ (tblMD_Message)...';
GO

IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'MnuHRS501' AND Language = 'VN')
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('MnuHRS501', 'VN', N'Danh sách nhân viên');
ELSE
    UPDATE tblMD_Message SET Content = N'Danh sách nhân viên' WHERE MessageID = 'MnuHRS501' AND Language = 'VN';

IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'MnuHRS501' AND Language = 'EN')
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('MnuHRS501', 'EN', N'Employee list');
ELSE
    UPDATE tblMD_Message SET Content = N'Employee list' WHERE MessageID = 'MnuHRS501' AND Language = 'EN';

IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'MnuHRS501' AND Language = 'CN')
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('MnuHRS501', 'CN', N'员工列表');
ELSE
    UPDATE tblMD_Message SET Content = N'员工列表' WHERE MessageID = 'MnuHRS501' AND Language = 'CN';

IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'MnuHRS501' AND Language = 'KR')
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('MnuHRS501', 'KR', N'직원 목록');
ELSE
    UPDATE tblMD_Message SET Content = N'직원 목록' WHERE MessageID = 'MnuHRS501' AND Language = 'KR';
GO

PRINT N'  [OK] Đã cấu hình đa ngôn ngữ.';
GO

-- ============================================================================
-- PHASE 4: Dọn dẹp cấu hình cũ trong tblDataSetting và tblDataSettingLayout (Không cần cho Cách 2)
-- ============================================================================
PRINT N'4. Đang dọn dẹp cấu hình tblDataSetting & tblDataSettingLayout cũ...';
GO

DELETE FROM tblDataSetting WHERE TableName = 'hr_employeelist2';
DELETE FROM tblDataSettingLayout WHERE TableName = 'hr_employeelist2';
GO

PRINT N'  [OK] Đã dọn dẹp cấu hình layout cũ.';
GO

-- ============================================================================
-- PHASE 5: Tạo/Cập nhật các thủ tục lưu trữ liên quan
-- ============================================================================
PRINT N'5. Đang tạo/cập nhật các thủ tục lưu trữ...';
GO

-- 5.1. sp_GetEmployeesList_GetParam
PRINT N'  - Tạo sp_GetEmployeesList_GetParam...';
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_GetEmployeesList_GetParam]
(
  @LanguageID varchar(2) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT -1 DepartmentID, CASE WHEN @LanguageID = 'EN' THEN 'All' ELSE N'Tất cả' END DepartmentName
    UNION ALL
    SELECT DepartmentID, CASE WHEN @LanguageID = 'EN' THEN DepartmentNameEN ELSE DepartmentName END FROM tblDepartment;

    SELECT -1 EmployeeStatusID, CASE WHEN @LanguageID = 'EN' THEN 'All' ELSE N'Tất cả' END EmployeeStatus
    UNION ALL
    SELECT EmployeeStatusID, CASE WHEN @LanguageID = 'EN' THEN EmployeeStatusEN ELSE EmployeeStatus END FROM tblEmployeeStatus;
END
GO

-- 5.2. sp_GetEmployeesList
PRINT N'  - Tạo sp_GetEmployeesList...';
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_GetEmployeesList]
(
    @currentPage      int            = 1,            -- DEPRECATED — chỉ giữ backward-compat
    @EmployeeSearch   nvarchar(max)  = N'',
    @DepartmentID     int            = -1,
    @EmployeeStatusID int            = -1,
    @ViewDate         date           = null,
    @LoginID          int            = 3,
    @LanguageID       varchar(2)     = 'VN',
    @Skip             int            = -1,           -- LAZY MODE: -1 = fallback @currentPage; >=0 = lazy
    @Take             int            = 50
)
AS
BEGIN
    SET NOCOUNT ON;

    /* ----- Chuẩn hoá tham số paging ----- */
    IF @Take IS NULL OR @Take <= 0 SET @Take = 50;
    IF @Skip < 0
    BEGIN
        IF @currentPage IS NULL OR @currentPage < 1 SET @currentPage = 1;
        SET @Skip = (@currentPage - 1) * @Take;
    END

    /* ----- Chuẩn hoá keyword ----- */
    SET @EmployeeSearch = REPLACE(@EmployeeSearch, CHAR(10), N';');
    SET @EmployeeSearch = REPLACE(@EmployeeSearch, CHAR(13), N';');
    SET @EmployeeSearch = REPLACE(@EmployeeSearch, N'.', N';');
    SET @EmployeeSearch = REPLACE(@EmployeeSearch, N',', N';');
    WHILE CHARINDEX(N'  ', @EmployeeSearch) > 0
        SET @EmployeeSearch = REPLACE(@EmployeeSearch, N'  ', N' ');
    SET @EmployeeSearch = LTRIM(RTRIM(@EmployeeSearch));

    IF @ViewDate IS NULL SET @ViewDate = GETDATE();

    /* ----- Snapshot nhân viên theo ngày + filter dept/status ----- */
    SELECT
        te.EmployeeID, te.FullName, te.DivisionID, te.DepartmentID,
        te.MobilePhone, te.HireDate, te.TerminateDate, te.Birthday,
        te.PositionID, te.SectionID, te.PhotoImage, te.ID_Number,
        CAST(1 AS int)               AS MatchSearch,
        CAST(NULL AS nvarchar(500))  AS FullNameEN,
        CAST(NULL AS nvarchar(200))  AS FirstName,
        CAST(NULL AS nvarchar(200))  AS FirstNameEN
    INTO #vtblEmployeeList_Bydate
    FROM dbo.fn_vtblEmployeeList_Bydate(@ViewDate, '-1', @LoginID) te
    WHERE (@DepartmentID = -1 OR (te.DepartmentID = @DepartmentID AND @DepartmentID >= 1))
      AND (@EmployeeStatusID = -1 OR (te.EmployeeStatusID = @EmployeeStatusID AND @EmployeeStatusID >= 0));

    /* ----- Chấm điểm match search ----- */
    IF ISNULL(@EmployeeSearch, N'') <> N''
    BEGIN
        UPDATE #vtblEmployeeList_Bydate SET MatchSearch = 0;
        UPDATE #vtblEmployeeList_Bydate SET FirstName = dbo.fn_getCallName(FullName);
        UPDATE #vtblEmployeeList_Bydate
           SET FullNameEN  = dbo.fn_RemoveToneMark(FullName),
               FirstNameEN = dbo.fn_RemoveToneMark(FirstName);

        DECLARE @EmployeeSearchEN nvarchar(max) = dbo.fn_RemoveToneMark(@EmployeeSearch);

        UPDATE #vtblEmployeeList_Bydate SET MatchSearch = 100
         WHERE MatchSearch = 0 AND (EmployeeID = @EmployeeSearch OR FullName = @EmployeeSearch
            OR MobilePhone = @EmployeeSearchEN OR ID_Number = @EmployeeSearchEN);
        UPDATE #vtblEmployeeList_Bydate SET MatchSearch = 99
         WHERE MatchSearch = 0 AND (FullNameEN = @EmployeeSearchEN OR FirstName = @EmployeeSearch);
        UPDATE #vtblEmployeeList_Bydate SET MatchSearch = 95
         WHERE MatchSearch = 0 AND (FirstNameEN = @EmployeeSearchEN);
        UPDATE #vtblEmployeeList_Bydate SET MatchSearch = 90
         WHERE MatchSearch = 0 AND (EmployeeID LIKE @EmployeeSearch + N'%' OR EmployeeID LIKE N'%' + @EmployeeSearch);
        UPDATE #vtblEmployeeList_Bydate SET MatchSearch = 85
         WHERE MatchSearch = 0 AND (FirstName LIKE N'%' + @EmployeeSearch OR FirstNameEN LIKE N'%' + @EmployeeSearchEN);
        UPDATE #vtblEmployeeList_Bydate SET MatchSearch = 80
         WHERE MatchSearch = 0 AND (FullName LIKE N'%' + @EmployeeSearch);
        UPDATE #vtblEmployeeList_Bydate SET MatchSearch = 75
         WHERE MatchSearch = 0 AND (FullName LIKE N'%' + @EmployeeSearch OR FullName LIKE @EmployeeSearch + N'%');
        UPDATE #vtblEmployeeList_Bydate SET MatchSearch = 60
         WHERE MatchSearch = 0 AND (EmployeeID LIKE N'%' + @EmployeeSearchEN + N'%');
        UPDATE #vtblEmployeeList_Bydate SET MatchSearch = 40
         WHERE MatchSearch = 0 AND (FullName LIKE N'%' + @EmployeeSearch + N'%');
        UPDATE #vtblEmployeeList_Bydate SET MatchSearch = 30
         WHERE MatchSearch = 0 AND (FullNameEN LIKE N'%' + @EmployeeSearchEN + N'%');
        UPDATE #vtblEmployeeList_Bydate SET MatchSearch = 30
         WHERE MatchSearch = 0
           AND (ISNUMERIC(@EmployeeSearchEN) = 1 AND LEN(@EmployeeSearchEN) > 5
                AND MobilePhone LIKE N'%' + @EmployeeSearchEN + N'%');

        DELETE FROM #vtblEmployeeList_Bydate WHERE MatchSearch = 0;
    END

    /* ----- Build dataset cuối + sort ----- */
    SELECT
        ROW_NUMBER() OVER(ORDER BY MatchSearch DESC, HireDate DESC,
                          ISNULL(ss.Priority, ss.SectionID), ps.PositionID, te.EmployeeID) AS STT,
        te.EmployeeID, te.FullName,
        CASE WHEN @LanguageID = 'vn' OR ISNULL(dv.DivisionNameEN,   N'') = N'' THEN dv.DivisionName   ELSE dv.DivisionNameEN   END AS DivisionName,
        CASE WHEN @LanguageID = 'vn' OR ISNULL(td.DepartmentNameEN, N'') = N'' THEN td.DepartmentName ELSE td.DepartmentNameEN END AS DepartmentName,
        CASE WHEN @LanguageID = 'vn' OR ISNULL(ss.SectionNameEN,    N'') = N'' THEN ss.SectionName    ELSE ss.SectionNameEN    END AS SectionName,
        te.HireDate, te.TerminateDate, te.Birthday, te.MobilePhone,
        CASE WHEN @LanguageID = 'vn' OR ISNULL(ps.PositionNameEN,   N'') = N'' THEN ps.PositionName   ELSE ps.PositionNameEN   END AS PositionName,
        CASE WHEN @LanguageID = 'vn' OR ISNULL(tp.ContractNameEN,   N'') = N'' THEN tp.ContractName   ELSE tp.ContractNameEN   END AS ContractName,
        ct.ContractNo, ct.ContractStartDay,
        CASE WHEN tp.[Limit] = 0 THEN NULL ELSE ct.ContractEndDay END AS ContractEndDay,
        dbo.fn_GetStringUrlImageByEmployeeID(te.EmployeeID) AS PhotoImage
    INTO #tmpExportData
    FROM #vtblEmployeeList_Bydate te
    LEFT JOIN tblDivision  dv ON te.DivisionID  = dv.DivisionID
    LEFT JOIN tblDepartment td ON te.DepartmentID = td.DepartmentID
    LEFT JOIN tblSection   ss ON te.SectionID   = ss.SectionID
    LEFT JOIN tblPosition  ps ON te.PositionID  = ps.PositionID
    LEFT JOIN (
        SELECT ct.EmployeeID, ct.ContractID, ct.ContractCode, ct.ContractNo, ct.ContractStartDay, ct.ContractEndDay
        FROM dbo.tblLabourContract ct
        INNER JOIN (
            SELECT MAX(ct2.ContractID) AS ContractID, ct2.EmployeeID
            FROM dbo.tblLabourContract ct2
            INNER JOIN (
                SELECT EmployeeID, MAX(ISNULL(ContractEndDay, '2099-01-01')) AS ContractEndDay
                FROM dbo.tblLabourContract
                GROUP BY EmployeeID
            ) tmp ON ct2.EmployeeID = tmp.EmployeeID
                 AND ISNULL(ct2.ContractEndDay, '2099-01-01') = tmp.ContractEndDay
            GROUP BY ct2.EmployeeID
        ) tmp ON ct.ContractID = tmp.ContractID
    ) ct ON te.EmployeeID = ct.EmployeeID
    LEFT JOIN tblMST_ContractType tp ON ct.ContractCode = tp.ContractCode;

    /* ----- RS#1: data chunk theo OFFSET/FETCH ----- */
    SELECT *
    FROM #tmpExportData
    ORDER BY STT
    OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;

    /* ----- RS#2: meta lazy load ----- */
    DECLARE @TotalCount int = (SELECT COUNT(*) FROM #tmpExportData);
    DECLARE @NextSkip  int = @Skip + @Take;
    SELECT
        @TotalCount                              AS TotalCount,
        @Skip                                    AS [Skip],
        @Take                                    AS [Take],
        CASE WHEN @NextSkip < @TotalCount THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS HasMore,
        CEILING(@TotalCount / CAST(@Take AS FLOAT)) AS totalPages,    -- backward-compat
        ((@Skip / @Take) + 1)                    AS currentPage;       -- backward-compat
END
GO

-- 5.3. HR_EmployeeList2 (Wrapper theo chuẩn IsWeb=1)
PRINT N'  - Tạo wrapper HR_EmployeeList2 (chuẩn IsWeb=1)...';
GO

CREATE OR ALTER PROCEDURE [dbo].[HR_EmployeeList2]
(
    @LoginID    int = NULL,
    @LanguageID varchar(5) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;

    -- SELECT ra cột [html] theo chuẩn IsWeb = 1
    SELECT html FROM tblHtmlScriptCache 
    WHERE TableName = 'HR_EmployeeList2' 
      AND LanguageID = @LanguageID;

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC HR_EmployeeList2_html @LanguageID = @LanguageID;
    END
END
GO

-- 5.4. HR_EmployeeList2_html (Renderer)
PRINT N'  - Tạo renderer HR_EmployeeList2_html...';
GO

CREATE OR ALTER PROCEDURE [dbo].[HR_EmployeeList2_html]
(
    @ViewDate   date         = null,
    @LoginID    int          = 3,
    @LanguageID varchar(2)   = 'VN',
    @isWeb      int          = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    IF @ViewDate IS NULL SET @ViewDate = GETDATE();

    DECLARE @QueryWeb nvarchar(max) = N'';

    SET @QueryWeb = N'
<style>
  #employee-list-container .table>:not(caption)>*>* {
    background-color: transparent !important;
    box-shadow: none !important;
  }
  #employee-list-container .grid-view .item {
    width: 23%;
    margin: 10px;
    padding: 20px;
    border: 1px solid #ccc;
    text-align: center;
    border-radius: 5px;
  }
  #employee-list-container .list-view .item {
    width: 100%;
    margin: 5px 0;
    padding: 15px;
    border: 1px solid #ccc;
    border-radius: 5px;
    text-align: left;
  }
  #employee-list-container .btn-left  { height: 44px; border-radius: 20px 0 0 20px; }
  #employee-list-container .btn-right { height: 44px; border-radius: 0 20px 20px 0; }
  #employee-list-container .layout-param {
    border-radius: 0 20px 20px 0;
    white-space: nowrap;
    padding-top: 6px;
  }
  #employee-list-container #viewdate-datebox .dx-texteditor-input {
    padding-left: 12px;
    border: 1px solid var(--bs-border-color);
  }
  #employee-list-container .avatar-img {
    width: 100px; height: 100px;
    object-fit: cover;
    border-radius: 50%;
    border: 2px solid var(--bs-border-color);
    padding: 2px;
  }
  #employee-list-container .avatar-container { display: flex; justify-content: center; }
  #employee-list-container .avatar-container svg {
    border: 2px solid var(--bs-border-color);
    border-radius: 50%;
    padding: 2px;
    color: var(--bs-border-color);
  }
  #employee-list-container #employeeListGridView { padding-bottom: 15px; }
  #employee-list-container .row { display: flex; align-items: stretch; flex-wrap: wrap; }
  #employee-list-container .item { display: flex; box-sizing: border-box; }
  #employee-list-container .card {
    flex: 1; display: flex; flex-direction: column;
    margin-top: 15px; margin-bottom: 15px;
    border: 1px solid var(--bs-border-color);
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
  }
  #employee-list-container .card-title {
    text-align: center; padding-top: 10px;
    border-radius: 8px; box-shadow: none; font-weight: bold;
  }
  #employee-list-container .card-text { text-align: center; }
  #employee-list-container .card-title:hover { text-shadow: 0 4px 20px rgba(25, 135, 84, 0.3); }
  #employee-list-container .card:hover {
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
    cursor: pointer;
  }
  #employee-list-container .employee-card-link { text-decoration: none; color: inherit; display: block; }
  #employee-list-container .employee-card-link:hover { text-decoration: none; }

  /* === LAZY LOAD === thay thế pagination-container cũ === */
  #employee-list-container .lazy-sentinel-wrap {
    min-height: 60px; padding: 16px 0; text-align: center;
  }
  #employee-list-container .lazy-loading {
    display: none; gap: 8px;
    align-items: center; justify-content: center;
    font-style: italic; color: var(--bs-secondary);
  }
  #employee-list-container .lazy-loading .lazy-spinner {
    width: 16px; height: 16px;
    border: 2px solid var(--bs-border-color);
    border-top-color: var(--bs-success);
    border-radius: 50%;
    animation: lazy-spin 0.7s linear infinite;
  }
  @keyframes lazy-spin { to { transform: rotate(360deg); } }
  #employee-list-container .lazy-end {
    display: none; padding: 12px 0;
    font-style: italic; color: var(--bs-secondary);
  }

  #employee-list-container .nodata {
    height: 8vh; display: none;
    justify-content: center; font-style: italic;
  }
  #employee-list-container table { width: 100%; border-collapse: collapse; }
  #employee-list-container .td-center { text-align: center; }
  #employee-list-container #employeelist-title { border-top-left-radius: 15px; }
  #employee-list-container #employeelist-last-title { border-top-right-radius: 15px; }
  #employee-list-container th {
    vertical-align: middle; font-weight: bold;
    padding: 10px; border-bottom: 2px solid #ddd;
  }
  #employee-list-container td {
    vertical-align: middle; padding: 10px;
    border-bottom: 1px solid var(--bs-border-color);
  }
  #employee-list-container td img, #employee-list-container td svg {
    width: 40px; height: 40px;
    border-radius: 50%; object-fit: cover;
    border: 2px solid var(--bs-border-color);
    padding: 2px; color: var(--bs-border-color);
  }
  #employee-list-container .table-container { overflow-x: auto; margin: 20px 0; }
  #employee-list-container th, #employee-list-container td { white-space: nowrap; }
  #employee-list-container .employee-name:hover {
    text-shadow: 0 4px 20px rgba(25, 135, 84, 0.5); cursor: pointer;
  }
  #employee-list-container .position-badge-green {
    text-align: center; padding: 5px 10px;
    border-radius: 15px; font-weight: bold; font-size: 10px;
  }
  #employee-list-container .search-container {
    display: flex; max-width: 250px;
    border: var(--bs-border-width) solid var(--bs-border-color);
    border-radius: 5px;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    margin-left: 0;
  }
  #employee-list-container #employee-search-input {
    flex: 1; padding: 10px; border: none; outline: none;
  }
</style>

<div id="employee-list-container" class="px-3 py-2">
  <div class="d-flex mb-2 mb-3 justify-content-end">
    <div class="param d-flex align-self-center  me-2">
      <div class="d-flex align-items-center me-2">
        <label for="departmentSelect" class="layout-param form-label me-2 align-self-center" >%DepartmentName%:</label>
        <select id="departmentSelect" class="form-select"></select>
      </div>
      <div class="d-flex align-items-center me-2">
        <label for="employeeStatusSelect" class="layout-param form-label me-2 align-self-center" >%Status%:</label>
        <select id="employeeStatusSelect" class="form-select"></select>
      </div>
      <div class="d-flex align-items-center me-2">
        <div for="viewdate-datebox" class="layout-param form-label me-2" style="padding-top: 8px;" >%sp_OTAssignment_Detail.OTDate%:</div>
        <div id="viewdate-datebox" class="form-value" style="height: 38px;"></div>
      </div>
      <div class="search-container d-flex align-items-center">
        <input type="text" id="employee-search-input" placeholder="%searchemployee%" oninput="handleSearch(event)" />
        <button class="btn btn-success" onclick="searchEmployees()"><i class="bi bi-search"></i></button>
      </div>
    </div>
    <button id="employeelist-reset" type="button" class="btn btn-success me-2">%btnReload%</button>
    <div class="d-flex justify-content-end align-items-center">
      <button id="listViewBtn" class="btn-left btn btn-secondary mr-4"><i class="bi bi-list"></i></button>
      <button id="gridViewBtn" class="btn-right btn btn-primary"><i class="bi bi-grid-3x3-gap"></i></button>
    </div>
  </div>

  <div id="employeeListGridView" class="row"></div>

  <div id="employeeListView" class="list-view" style="display: none; overflow-x: auto;">
    <table class="table table-striped table-hover">
      <thead>
        <tr style="background-color: #04452D;">
          <th id="employeelist-title" class="text-white td-center">%Image%</th>
          <th class="text-white td-center">%STT%</th>
          <th class="text-white">ID</th>
          <th class="text-white">%EmpFullName%</th>
          <th class="text-white">%Birthday%</th>
          <th class="text-white">%PositionID%</th>
          <th class="text-white">%DepartmentName%</th>
          <th class="text-white">%SDT%</th>
          <th class="text-white">%HR_StaffInformation_List_2.lblContractCode%</th>
          <th class="text-white">%ContractStartDay%</th>
          <th id="employeelist-last-title" class="text-white">%ContractEndDay%</th>
        </tr>
      </thead>
      <tbody id="employee-listview-body"></tbody>
    </table>
  </div>

  <div class="nodata text-center"><h2 class="text-secondary">No Data</h2></div>

  <!-- === LAZY LOAD: sentinel + indicators === -->
  <div class="lazy-sentinel-wrap">
    <div id="employee-lazy-loading" class="lazy-loading">
      <div class="lazy-spinner"></div>
      <span id="employee-lazy-loading-text">%Loading%</span>
    </div>
    <div id="employee-lazy-end" class="lazy-end"></div>
    <div id="employee-list-sentinel" style="height: 1px;"></div>
  </div>
</div>

<script>
(function () {
  /* ====== STATE ====== */
  var LL_TAKE      = 50;
  var _skip        = 0;
  var _hasMore     = true;
  var _isLoading   = false;
  var _observer    = null;
  var _firstLoaded = false;

  var EmployeesState = {
    employeeSearch: "",
    department:     -1,
    status:         -1,
    date:           new Date()
  };

  /* ====== ELEMENTS ====== */
  var gridView      = document.getElementById("employeeListGridView");
  var listBody      = document.getElementById("employee-listview-body");
  var sentinel      = document.getElementById("employee-list-sentinel");
  var loadingEl     = document.getElementById("employee-lazy-loading");
  var endEl         = document.getElementById("employee-lazy-end");
  var noDataEl      = document.querySelector("#employee-list-container .nodata");

  /* ====== HELPERS ====== */
  function formatDate(date) {
    if (!date) return "N/A";
    var d = new Date(date);
    var day   = String(d.getDate()).padStart(2, "0");
    var month = String(d.getMonth() + 1).padStart(2, "0");
    return day + "/" + month + "/" + d.getFullYear();
  }

  function escapeText(s) {
    if (s === null || typeof s === "undefined") return "";
    return String(s)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;").replace(/''/g, "&#39;");
  }

  function setLoading(on) {
    _isLoading = on;
    loadingEl.style.display = on ? "flex" : "none";
  }

  function setEnd(reached) {
    if (reached) {
      var lang = (typeof LanguageID !== "undefined") ? LanguageID : "VN";
      var txt;
      if (lang === "EN") txt = "— End of list —";
      else if (lang === "CN") txt = "— 已显示全部 —";
      else if (lang === "KR") txt = "— 목록 끝 —";
      else                    txt = "— Đã hiển thị toàn bộ —";
      endEl.textContent  = txt;
      endEl.style.display = "block";
    } else {
      endEl.style.display = "none";
    }
  }

  /* ====== APPEND ROW HANDLERS ======
     Dùng template literal (backtick) + data-attribute (delegated listener)
     để tránh xung đột single-quote với T-SQL escape. */
  function appendGridCard(emp) {
    var item = document.createElement("div");
    item.classList.add("item", "col-xxl-2", "col-lg-3", "col-md-4", "col-sm-6");
    var id   = escapeText(emp.EmployeeID);
    var img  = escapeText(emp.PhotoImage);
    item.innerHTML = `
      <div class="card p-3">
        <a href="javascript:void(0)" class="employee-card-link" data-employee-id="${id}">
          <div class="avatar-container">
            <img data-employee-id="${id}" _param="${img}" class="card-img-top avatar-img" alt="Avatar">
          </div>
          <div class="card-body p-0">
            <h5 class="card-title text-success">${escapeText(emp.FullName)}</h5>
            <p class="position-badge-green text-success bg-success bg-opacity-10">${escapeText(emp.PositionName || "N/A")}</p>
            <p class="card-text">${id}</p>
            <p class="card-text">${escapeText(emp.DivisionName  || "N/A")}</p>
            <p class="card-text">${escapeText(emp.DepartmentName || "N/A")}</p>
            <p class="card-text">${escapeText(emp.MobilePhone   || "N/A")}</p>
          </div>
        </a>
      </div>`;
    gridView.appendChild(item);
  }

  function appendListRow(emp) {
    var row = document.createElement("tr");
    var id  = escapeText(emp.EmployeeID);
    var img = escapeText(emp.PhotoImage);
    row.innerHTML = `
      <td class="td-center"><img _param="${img}" alt="Avatar"></td>
      <td class="td-center">${escapeText(emp.STT)}</td>
      <td>${id}</td>
      <td class="employee-name" data-employee-id="${id}">
        <p class="text-success employee-name mb-0" data-employee-id="${id}">${escapeText(emp.FullName)}</p>
      </td>
      <td>${emp.Birthday ? formatDate(emp.Birthday) : "N/A"}</td>
      <td>${escapeText(emp.PositionName  || "N/A")}</td>
      <td>${escapeText(emp.DepartmentName || "N/A")}</td>
      <td>${escapeText(emp.MobilePhone   || "N/A")}</td>
      <td>${escapeText(emp.ContractName  || "N/A")}</td>
      <td>${emp.ContractStartDay ? formatDate(emp.ContractStartDay) : "N/A"}</td>
      <td>${emp.ContractEndDay   ? formatDate(emp.ContractEndDay)   : "N/A"}</td>`;
    listBody.appendChild(row);
  }

  /* ====== LAZY LOAD CORE ====== */
  function resetList() {
    _skip        = 0;
    _hasMore     = true;
    _firstLoaded = false;
    gridView.innerHTML  = "";
    listBody.innerHTML  = "";
    noDataEl.style.display = "none";
    setEnd(false);
  }

  function loadNextChunk() {
    if (_isLoading || !_hasMore) return;
    setLoading(true);

    AjaxHPAParadise({
      data: {
        name: "sp_GetEmployeesList",
        param: [
          "Skip",             _skip,
          "Take",             LL_TAKE,
          "EmployeeSearch",   EmployeesState.employeeSearch,
          "DepartmentID",     EmployeesState.department,
          "EmployeeStatusID", EmployeesState.status,
          "ViewDate",         EmployeesState.date,
          "LoginID",          LoginID,
          "LanguageID",       LanguageID
        ]
      },
      success: async function (result) {
        var json   = (typeof result === "string") ? JSON.parse(result) : result;
        var rows   = (json && json.data && json.data[0]) ? json.data[0] : [];
        var meta   = (json && json.data && json.data[1] && json.data[1][0]) ? json.data[1][0] : {};
        var hasMore = (meta.HasMore === true) || (meta.HasMore === 1);

        rows.forEach(function (emp) {
          appendGridCard(emp);
          appendListRow(emp);
        });

        _skip   += LL_TAKE;
        _hasMore = hasMore;

        if (!_firstLoaded) {
          _firstLoaded = true;
          if (rows.length === 0) noDataEl.style.display = "flex";
        }

        await loadImageEmployeeListContainer();

        setLoading(false);
        if (!_hasMore) setEnd(true);
      },
      error: function () {
        setLoading(false);
      }
    });
  }

  function setupIntersectionObserver() {
    if (_observer) _observer.disconnect();
    _observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) loadNextChunk();
      });
    }, { root: null, rootMargin: "200px", threshold: 0 });
    _observer.observe(sentinel);
  }

  /* ====== FILTER DROPDOWNS (giữ logic gốc) ====== */
  function getEmployeesList_GetParam() {
    var selectElement         = document.getElementById("departmentSelect");
    var employeeStatusElement = document.getElementById("employeeStatusSelect");
    showLoadingByClassOrID("#HR_EmployeeList", "%Loading%", "Black", "Black");
    AjaxHPAParadise({
      data: {
        name: "sp_GetEmployeesList_GetParam",
        param: ["LoginID", LoginID, "LanguageID", LanguageID]
      },
      success: function (result) {
        var json = JSON.parse(result);
        var departmentList = json.data[0];
        selectElement.options.length = 0;
        departmentList.forEach(function (item) {
          var option = document.createElement("option");
          option.value = item.DepartmentID;
          option.textContent = item.DepartmentName;
          selectElement.appendChild(option);
        });

        employeeStatusElement.options.length = 0;
        json.data[1].forEach(function (item) {
          var opt = document.createElement("option");
          opt.value = item.EmployeeStatusID;
          opt.textContent = item.EmployeeStatus;
          employeeStatusElement.appendChild(opt);
        });
        HideLoadingByClassOrID("#HR_EmployeeList");
      }
    });
  }

  /* ====== IMAGE LOADER (giữ logic gốc) ====== */
  async function loadImageEmployeeListContainer() {
    var $imgs = $("#employee-list-container img").filter(function () {
      return !$(this).attr("src") && $(this).attr("_param");
    });
    if ($imgs.length === 0) return;
    $imgs.each(async function () {
      var self  = $(this);
      var param = JSON.parse(''["FilePath","'' + self.attr("_param") + ''"]'');
      await AjaxHPAParadiseAsync({
        data: { name: "paradisefilesp_GetFileAPI", param: param },
        xhrFields: { responseType: "blob" },
        success: function (blob) {
          try {
            self.attr("src", URL.createObjectURL(blob));
          } catch (e) {
            self.replaceWith(''<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-person card-img-top avatar-img" viewBox="0 0 16 16"><path d="M8 8a3 3 0 1 0 0-6 3 3 0 0 0 0 6m2-3a2 2 0 1 1-4 0 2 2 0 0 1 4 0m4 8c0 1-1 1-1 1H3s-1 0-1-1 1-4 6-4 6 3 6 4m-1-.004c-.001-.246-.154-.986-.832-1.664C11.516 10.68 10.289 10 8 10s-3.516.68-4.168 1.332c-.678.678-.83 1.418-.832 1.664z"/></svg>'');
          }
        }
      });
    });
  }

  /* ====== EVENT HANDLERS ====== */
  window.handleCardClick = function (employeeID) {
    if (!employeeID) return;
    openFormParam("HR_StaffInformation_List_2", {
      EmployeeID: employeeID, LoginID: LoginID, LanguageID: LanguageID,
      TableName: "-1", Isweb: 1
    });
  };

  window.handleTitleClick = function (event) {
    if (!event.target) return;
    /* Click trong list-view (cell có class employee-name) */
    var nameNode = event.target.closest(".employee-name");
    if (nameNode && nameNode.dataset.employeeId) {
      window.handleCardClick(nameNode.dataset.employeeId);
      return;
    }
    /* Click trong grid-view (card link — không còn inline onclick) */
    var cardLink = event.target.closest(".employee-card-link");
    if (cardLink && cardLink.dataset.employeeId) {
      window.handleCardClick(cardLink.dataset.employeeId);
    }
  };

  window.handleSearch = function (event) {
    EmployeesState.employeeSearch = event.target.value.toLowerCase();
  };

  window.searchEmployees = function () {
    resetList();
    loadNextChunk();
  };

  function resetEmployeeList() {
    EmployeesState = {
      employeeSearch: "",
      department:     -1,
      status:         -1,
      date:           new Date()
    };
    $("#viewdate-datebox").dxDateBox("instance").option("value", EmployeesState.date);
    document.getElementById("departmentSelect").value      = -1;
    document.getElementById("employeeStatusSelect").value  = -1;
    document.getElementById("employee-search-input").value = "";
    getEmployeesList_GetParam();
    resetList();
    loadNextChunk();
  }

  /* ====== BOOTSTRAP ====== */
  $(document).ready(function () {
    $("#listViewBtn").click(function () {
      $("#employeeListGridView").hide();
      $("#employeeListView").show();
      $(this).addClass("btn-primary").removeClass("btn-secondary");
      $("#gridViewBtn").removeClass("btn-primary").addClass("btn-secondary");
    });
    $("#gridViewBtn").click(function () {
      $("#employeeListView").hide();
      $("#employeeListGridView").show();
      $(this).addClass("btn-primary").removeClass("btn-secondary");
      $("#listViewBtn").removeClass("btn-primary").addClass("btn-secondary");
    });
  });

  var viewDate = new Date();
  $("#viewdate-datebox").dxDateBox({
    placeholder: viewDate.toLocaleDateString("vi-VN"),
    useMaskBehavior: true,
    displayFormat: "dd/MM/yyyy",
    type: "date",
    value: viewDate,
    inputAttr: { "aria-label": "Date" },
    onValueChanged: function (data) {
      EmployeesState.date = data.value;
      resetList();
      loadNextChunk();
    }
  });

  document.body.addEventListener("click", window.handleTitleClick);

  document.getElementById("departmentSelect").addEventListener("change", function (event) {
    EmployeesState.department = event.target.value;
    resetList();
    loadNextChunk();
  });
  document.getElementById("employeeStatusSelect").addEventListener("change", function (event) {
    EmployeesState.status = event.target.value;
    resetList();
    loadNextChunk();
  });
  document.getElementById("employeelist-reset").addEventListener("click", resetEmployeeList);
  document.getElementById("employee-search-input").addEventListener("keypress", function (e) {
    if (e.key === "Enter") window.searchEmployees();
  });

  /* ====== KICK OFF ====== */
  getEmployeesList_GetParam();
  setupIntersectionObserver();
  loadNextChunk();
})();
</script>
';

    SELECT @QueryWeb AS html;
END
GO

PRINT N'  [OK] Đã tạo renderer HR_EmployeeList2_html.';
GO

-- ============================================================================
-- PHASE 6: Rebuild HTML Cache theo khóa HR_EmployeeList2 (chuẩn IsWeb=1)
-- ============================================================================
PRINT N'6. Đang build cache HTML cho HR_EmployeeList2...';
GO

DELETE FROM dbo.tblHtmlScriptCache WHERE TableName = N'HR_EmployeeList2';
GO

EXEC dbo.sp_GenerateHTMLScript 'HR_EmployeeList2_html', 'VN', 'HR_EmployeeList2';
EXEC dbo.sp_GenerateHTMLScript 'HR_EmployeeList2_html', 'EN', 'HR_EmployeeList2';
GO

PRINT N'  [OK] Đã rebuild cache HTML cho HR_EmployeeList2.';
GO

-- ============================================================================
-- PHASE 7: Làm mới menu cache phía client
-- ============================================================================
PRINT N'7. Đang làm mới cache hệ thống...';
GO

EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'HR_EmployeeList2';
GO

PRINT N'CHUYỂN ĐỔI MENU MNUHRS501 SANG CẤU HÌNH WEB MỚI THÀNH CÔNG!';
GO
