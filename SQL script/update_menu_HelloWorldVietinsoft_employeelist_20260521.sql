-- =====================================================================================
-- File   : SQL script/update_menu_HelloWorldVietinsoft_employeelist_20260521.sql
-- Date   : 2026-05-21
-- Mục đích:
--     Minh hoạ cách dùng `tblCommonControlType_Signed` + `sptblCommonControlType_Signed_DUC`
--     bằng cách gắn một control "Grid danh sách nhân viên" vào menu
--     "Hello world Vietinsoft" (MnuHEP910).
--
-- Pattern triển khai (mô phỏng theo sp_CRM_Customers_html đang chạy production):
--     1. (Re)create dbo.sp_LoadHelloWorldVietinsoftEmployeeList — procedure API runtime,
--        JS gọi qua AjaxHPAParadise để load data grid.
--     2. Xoá & re-insert 9 row metadata cho TableName='sp_HelloWorldVietinsoft_html'
--        trong tblCommonControlType_Signed (1 grid container + 8 column).
--        Mỗi row có UID deterministic để renderer trỏ tới.
--     3. EXEC sptblCommonControlType_Signed_DUC 'sp_HelloWorldVietinsoft_html' để
--        procedure tự build cột `html`, `loadUI`, `loadData` và update ngược lại
--        bảng metadata (side-effect chính của proc).
--     4. CREATE OR ALTER dbo.sp_HelloWorldVietinsoft_html — renderer mới nhúng
--        loadUI/loadData từ metadata bằng dynamic SQL trỏ theo UID grid container,
--        style ParadiseStyle qua sp_MainStyleCSSParadise.
--     5. Xoá cache cũ trong tblHtmlScriptCache rồi
--        EXEC sp_GenerateHTMLScript 'sp_HelloWorldVietinsoft_html' để build cache
--        mới cho cả VN và EN.
--     6. EXEC sp_Men_Menu_AfterSave_Simple @ClassName='sp_HelloWorldVietinsoft'
--        refresh metadata menu.
--
-- KHÔNG động vào:
--     - MEN_Menu / tblSC_Object / tblMD_Message / tblDataSetting / tblDataSettingLayout
--       (menu MnuHEP910 đã tồn tại đầy đủ, đã verify trước khi viết script).
--     - Phân quyền: chỉ giữ nguyên LoginID=3 hiện có. KHÔNG gọi
--       sp_UpdateMenuInUserRight (proc đó mở quyền cho mọi user — vi phạm rule).
--
-- Cảnh báo:
--     - Khuyến nghị BACKUP database trước khi chạy.
--     - Script idempotent — chạy lại nhiều lần đều OK.
--     - User TỰ REVIEW và CHẠY. Agent KHÔNG thực thi tự động.
-- =====================================================================================

SET XACT_ABORT ON;
GO


-- =====================================================================================
-- BƯỚC 1 — Procedure API runtime: trả danh sách nhân viên cho grid
-- =====================================================================================
CREATE OR ALTER PROCEDURE [dbo].[sp_LoadHelloWorldVietinsoftEmployeeList]
(
    @LoginID    INT          = 3,
    @LanguageID VARCHAR(5)   = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 200
        e.EmployeeID,
        ISNULL(e.FullName, N'') AS FullName,
        CASE WHEN e.Sex = 1 THEN N'Nam'
             WHEN e.Sex = 0 THEN N'Nữ'
             ELSE N'-' END                                     AS Sex,
        CONVERT(VARCHAR(10), e.Birthday, 103)                  AS Birthday,
        ISNULL(e.MobilePhone, N'')                             AS MobilePhone,
        ISNULL(CAST(e.Email AS NVARCHAR(500)), N'')            AS Email,
        CONVERT(VARCHAR(10), e.HireDate, 103)                  AS HireDate,
        ISNULL(CAST(e.DepartmentID AS NVARCHAR(50)), N'')      AS DepartmentID
    FROM dbo.tblEmployee e
    WHERE ISNULL(e.IsTerminated, 0) = 0
    ORDER BY e.FullName, e.EmployeeID;
END
GO

PRINT N'-- Step 1: created/altered sp_LoadHelloWorldVietinsoftEmployeeList';
GO


-- =====================================================================================
-- BƯỚC 2 + 3 — Metadata + EXEC sptblCommonControlType_Signed_DUC
-- =====================================================================================
BEGIN TRY
    BEGIN TRANSACTION;

    -- 2a. Xoá toàn bộ metadata cũ của renderer (idempotent)
    DELETE FROM dbo.tblCommonControlType_Signed
    WHERE TableName = N'sp_HelloWorldVietinsoft_html';

    -- 2b. Insert grid container row + 8 column row.
    --     UID dùng pattern deterministic 'P' + 29 ký tự '0' + (G01 | C01..C08).
    --     Renderer (bước 4) sẽ trỏ tới UID grid container 'P00000000000000000000000000000G01'.

    INSERT INTO dbo.tblCommonControlType_Signed
        (TableName, ColumnName, Type, Layout, DataSourceSP, SPLoadData,
         ColumnIDName, TableEditor, DisplayName,
         GridColumnName, GridWidth, AllowSorting, AllowFiltering,
         UID)
    VALUES
        -- Grid container (Type='hpaControlGrid_Duc' = Simple View, read-only)
        (N'sp_HelloWorldVietinsoft_html', N'GridEmployees', 'hpaControlGrid_Duc', N'Grid_View',
         NULL, 'sp_LoadHelloWorldVietinsoftEmployeeList',
         N'EmployeeID', NULL, NULL,
         NULL, NULL, 1, 1,
         'P00000000000000000000000000000G01'),

        -- Columns (Type=NULL => render thành dxDataGrid column do grid container quản lý)
        (N'sp_HelloWorldVietinsoft_html', N'EmployeeID', NULL, N'Grid_View',
         NULL, NULL,
         N'EmployeeID', 'tblEmployee', N'Mã nhân viên',
         'GridEmployees', '100', 1, 1,
         'P00000000000000000000000000000C01'),

        (N'sp_HelloWorldVietinsoft_html', N'FullName', NULL, N'Grid_View',
         NULL, NULL,
         N'EmployeeID', 'tblEmployee', N'Họ và tên',
         'GridEmployees', '220', 1, 1,
         'P00000000000000000000000000000C02'),

        (N'sp_HelloWorldVietinsoft_html', N'Sex', NULL, N'Grid_View',
         NULL, NULL,
         N'EmployeeID', 'tblEmployee', N'Giới tính',
         'GridEmployees', '90', 1, 1,
         'P00000000000000000000000000000C03'),

        (N'sp_HelloWorldVietinsoft_html', N'Birthday', NULL, N'Grid_View',
         NULL, NULL,
         N'EmployeeID', 'tblEmployee', N'Ngày sinh',
         'GridEmployees', '110', 1, 1,
         'P00000000000000000000000000000C04'),

        (N'sp_HelloWorldVietinsoft_html', N'MobilePhone', NULL, N'Grid_View',
         NULL, NULL,
         N'EmployeeID', 'tblEmployee', N'Số điện thoại',
         'GridEmployees', '130', 1, 1,
         'P00000000000000000000000000000C05'),

        (N'sp_HelloWorldVietinsoft_html', N'Email', NULL, N'Grid_View',
         NULL, NULL,
         N'EmployeeID', 'tblEmployee', N'Email',
         'GridEmployees', '220', 1, 1,
         'P00000000000000000000000000000C06'),

        (N'sp_HelloWorldVietinsoft_html', N'HireDate', NULL, N'Grid_View',
         NULL, NULL,
         N'EmployeeID', 'tblEmployee', N'Ngày vào',
         'GridEmployees', '110', 1, 1,
         'P00000000000000000000000000000C07'),

        (N'sp_HelloWorldVietinsoft_html', N'DepartmentID', NULL, N'Grid_View',
         NULL, NULL,
         N'EmployeeID', 'tblEmployee', N'Phòng ban',
         'GridEmployees', '130', 1, 1,
         'P00000000000000000000000000000C08');

    PRINT N'-- Step 2: inserted 9 metadata row vào tblCommonControlType_Signed (1 grid + 8 column)';

    -- 3. Gọi sptblCommonControlType_Signed_DUC để procedure build html/loadUI/loadData
    --    rồi UPDATE ngược vào bảng tblCommonControlType_Signed.
    --    LƯU Ý: proc trả 1 result-set `htmlProc` (NVARCHAR(MAX)) mà ta KHÔNG dùng ở đây
    --    — side-effect chính là update html/loadUI/loadData.
    DECLARE @DucResult NVARCHAR(MAX);
    DECLARE @Tmp TABLE (htmlProc NVARCHAR(MAX));
    INSERT INTO @Tmp (htmlProc)
    EXEC dbo.sptblCommonControlType_Signed_DUC @TableName = 'sp_HelloWorldVietinsoft_html';

    PRINT N'-- Step 3: EXEC sptblCommonControlType_Signed_DUC đã chạy — html/loadUI/loadData populated';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'ERROR @ Step 2-3: ' + ERROR_MESSAGE();
    THROW;
END CATCH
GO


-- =====================================================================================
-- BƯỚC 4 — Renderer mới `sp_HelloWorldVietinsoft_html`
--          Nhúng loadUI/loadData từ tblCommonControlType_Signed bằng dynamic SQL
--          (giống pattern sp_CRM_Customers_html). Trả SELECT @html AS html — để
--          sp_GenerateHTMLScript build cache.
-- =====================================================================================
CREATE OR ALTER PROCEDURE [dbo].[sp_HelloWorldVietinsoft_html]
(
    @LoginID    INT          = 3,
    @LanguageID VARCHAR(2)   = 'VN',
    @isWeb      INT          = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StyleHtml NVARCHAR(MAX) = N'';
    IF OBJECT_ID('dbo.sp_MainStyleCSSParadise', 'P') IS NOT NULL
    BEGIN
        EXEC dbo.sp_MainStyleCSSParadise @StyleHtml = @StyleHtml OUTPUT;
    END

    DECLARE @html NVARCHAR(MAX);

    SET @html = ISNULL(@StyleHtml, N'') + N'
<style>
    .hwvts-emp-page {
        padding: var(--paradise-space-5);
        font-family: var(--paradise-font-family-base);
        color: var(--paradise-text-body);
    }
    .hwvts-emp-page h2 {
        margin: 0 0 8px 0;
        color: var(--paradise-primary);
        font-size: 20px;
    }
    .hwvts-emp-page p.hwvts-desc {
        margin: 0 0 16px 0;
        opacity: 0.85;
        line-height: 1.5;
    }
    .hwvts-emp-page code {
        background: var(--paradise-surface-2);
        color: var(--paradise-text-strong);
        padding: 2px 6px;
        border-radius: 4px;
        font-size: 12px;
    }
    .hwvts-grid-wrap {
        height: calc(100vh - 200px);
        min-height: 360px;
    }
</style>

<div id="helloWorldEmpListPage" class="hwvts-emp-page">
    <h2>Hello world Vietinsoft &mdash; Danh sách nhân viên</h2>
    <p class="hwvts-desc">
        Demo control sinh từ <code>tblCommonControlType_Signed</code> +
        <code>sptblCommonControlType_Signed_DUC</code>.
        Grid bên dưới được sinh HTML/JS động từ metadata,
        data load qua API <code>sp_LoadHelloWorldVietinsoftEmployeeList</code>.
    </p>
    <div class="hwvts-grid-wrap">
        <div id="GridEmployees" style="height: 100%;"></div>
    </div>
</div>

<script>
    (() => {
        let DataSource = [];
        '
+ (SELECT loadUI FROM dbo.tblCommonControlType_Signed WHERE UID = 'P00000000000000000000000000000G01') + N'

        window.currentRecordID_EmployeeID = null;

        function ReloadData() {
            AjaxHPAParadise({
                data: {
                    name: "sp_LoadHelloWorldVietinsoftEmployeeList",
                    param: []
                },
                success: function (res) {
                    const json = typeof res === "string" ? JSON.parse(res) : res;
                    const results = Array.isArray(json?.data?.[0])
                        ? json.data[0]
                        : (json?.data?.[0] ? [json.data[0]] : []);

                    const obj = results.length === 1 ? results[0] : (results[0] || null);
                    const gridInstance = InstanceGridEmployeesP00000000000000000000000000000G01;
                    const gridConfig  = window.getGridConfig_GridEmployees(results);

                    gridInstance.beginUpdate();
                    gridInstance.option("scrolling", { mode: "standard", showScrollbar: "onHover" });
                    gridInstance.option("remoteOperations", false);
                    gridInstance.option("paging.enabled", true);
                    gridInstance.option("paging.pageSize", gridConfig.pageSize);
                    gridInstance.option("pager.allowedPageSizes", gridConfig.allowedPageSizes);
                    gridInstance.pageIndex(0);
                    gridInstance.option("dataSource", results);
                    gridInstance.endUpdate();

                    if (obj) {
                        window.currentRecordID_EmployeeID =
                            (obj.EmployeeID !== undefined && obj.EmployeeID !== null)
                                ? obj.EmployeeID
                                : window.currentRecordID_EmployeeID;
                    }
                    DataSource = results;
                    '
+ (SELECT loadData FROM dbo.tblCommonControlType_Signed WHERE UID = 'P00000000000000000000000000000G01') + N'
                },
                error: function () { /* swallow */ }
            });
        }

        ReloadData();
    })();
</script>';

    SELECT @html AS html;

    -- Khi sửa metadata (tblCommonControlType_Signed) thì chạy thủ công lại 2 dòng:
    --     EXEC dbo.sptblCommonControlType_Signed_DUC 'sp_HelloWorldVietinsoft_html';
    --     EXEC dbo.sp_GenerateHTMLScript           'sp_HelloWorldVietinsoft_html';
END
GO

PRINT N'-- Step 4: created/altered sp_HelloWorldVietinsoft_html (renderer)';
GO


-- =====================================================================================
-- BƯỚC 5 + 6 — Rebuild cache + refresh menu
-- =====================================================================================
BEGIN TRY
    BEGIN TRANSACTION;

    -- 5a. Xoá cache cũ (idempotent)
    DELETE FROM dbo.tblHtmlScriptCache
    WHERE TableName = 'sp_HelloWorldVietinsoft_html';

    -- 5b. Build lại cache cho cả VN và EN (sp_GenerateHTMLScript tự loop language)
    EXEC dbo.sp_GenerateHTMLScript 'sp_HelloWorldVietinsoft_html';

    PRINT N'-- Step 5: tblHtmlScriptCache đã rebuild cho sp_HelloWorldVietinsoft_html';

    -- 6. Refresh metadata menu (theo CLAUDE rule — CHỈ 1 lệnh refresh, KHÔNG gọi
    --    sp_UpdateMenuInUserRight).
    EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_HelloWorldVietinsoft';

    PRINT N'-- Step 6: sp_Men_Menu_AfterSave_Simple đã chạy cho sp_HelloWorldVietinsoft';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'ERROR @ Step 5-6: ' + ERROR_MESSAGE();
    THROW;
END CATCH
GO


-- =====================================================================================
-- VERIFICATION QUERIES (chạy sau script để confirm)
-- =====================================================================================
PRINT N'';
PRINT N'-- VERIFICATION:';

-- 9 row metadata
SELECT 'tblCommonControlType_Signed' AS [Table],
       COUNT(*) AS RowCount_Expected_9
FROM dbo.tblCommonControlType_Signed
WHERE TableName = 'sp_HelloWorldVietinsoft_html';

-- Cache cho VN + EN
SELECT TableName, LanguageID, ScreenType,
       DATALENGTH(html)/2 AS HtmlChars
FROM dbo.tblHtmlScriptCache
WHERE TableName = 'sp_HelloWorldVietinsoft_html'
ORDER BY LanguageID;

-- Trạng thái menu MnuHEP910 (không thay đổi — chỉ verify)
SELECT m.MenuID, m.ClassName, m.AssemblyName, m.ParentMenuID, m.IsVisible,
       m.ViewOnWeb, m.isShowLayOutWeb, m.IsUseMobileDevice,
       msg.Content AS NameVN
FROM dbo.MEN_Menu m
LEFT JOIN dbo.tblMD_Message msg ON msg.MessageID = m.MenuID AND msg.Language = 'VN'
WHERE m.MenuID = 'MnuHEP910';

PRINT N'-- DONE.';
GO
