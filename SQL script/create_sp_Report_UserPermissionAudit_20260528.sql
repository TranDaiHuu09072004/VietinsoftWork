-- ============================================================================
-- SQL SCRIPT: create_sp_Report_UserPermissionAudit_20260528.sql
-- STORED PROCEDURE: sp_Report_UserPermissionAudit_html (Renderer)
--                  sp_Report_UserPermissionAudit (Wrapper)
-- AUTHOR: Claude Agent
-- DATE: 2026-05-28
-- MỤC ĐÍCH:
--   Báo cáo chi tiết quyền truy cập của người dùng — dùng để audit xem một
--   account đã được phân quyền đúng hay chưa. Hiển thị đầy đủ các layer:
--   cờ override, quyền trực tiếp, quyền theo nhóm, chuỗi kế thừa cha,
--   và phạm vi dữ liệu (Data Scope).
--
-- CÁC BẢNG & HÀM LIÊN QUAN SỬ DỤNG:
--   - Bảng: tblSC_Login, tblSC_Right_Stored, tblSC_Object, tblSC_GroupRight,
--           tblUserGrantGroup, tblUserRightGroup, tblSC_DepartmentView_Group,
--           tblSC_SectionView_Group, tblSC_GroupView_Group, tblSC_Group,
--           tblSC_GroupMember, tblSC_GroupView, tblDepartment, tblMD_Message,
--           tblHtmlScriptCache
--   - Hàm:   dbo.SplitString
--
-- CÁC THỦ TỤC / MÀN HÌNH GỌI:
--   - Được gọi từ: AjaxHPAParadise từ client, hoặc trực tiếp từ SSMS
-- ============================================================================

USE [ParadiseHR];
GO

-- ============================================================================
-- PART 1: RENDERER — sp_Report_UserPermissionAudit_html
-- Sinh HTML đầy đủ hiển thị báo cáo phân quyền theo từng nhóm
-- ============================================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Report_UserPermissionAudit_html
    @LoginID        INT          = NULL,    -- Người đang chạy báo cáo (Rule 3)
    @TargetLoginID  INT          = NULL,    -- Tài khoản cần audit (NULL = hiển thị danh sách tất cả)
    @LanguageID     VARCHAR(2)   = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;

    -- =========================================================================
    -- Layer 2: Text labels VN/EN
    -- =========================================================================
    DECLARE @title           NVARCHAR(200) = N'Báo cáo phân quyền người dùng';
    DECLARE @lblAccount      NVARCHAR(100) = N'Tài khoản';
    DECLARE @lblSelectAcct   NVARCHAR(200) = N'-- Chọn tài khoản --';
    DECLARE @lblAllAccts     NVARCHAR(200) = N'-- Tất cả tài khoản --';
    DECLARE @lblAcctInfo     NVARCHAR(100) = N'Thông tin tài khoản';
    DECLARE @lblOverride     NVARCHAR(100) = N'Cờ đặc quyền (Override Flags)';
    DECLARE @lblDirectPerm   NVARCHAR(100) = N'Quyền trực tiếp (Direct Permissions)';
    DECLARE @lblGroupMember  NVARCHAR(100) = N'Thành viên nhóm quyền (Group Memberships)';
    DECLARE @lblGroupPerm    NVARCHAR(100) = N'Quyền theo nhóm (Group Permissions)';
    DECLARE @lblParentChain  NVARCHAR(100) = N'Chuỗi kế thừa (Parent Inheritance Chain)';
    DECLARE @lblDataScope    NVARCHAR(100) = N'Phạm vi dữ liệu (Data Scope)';
    DECLARE @lblDeptScope    NVARCHAR(100) = N'Phòng ban được xem';
    DECLARE @lblSectScope    NVARCHAR(100) = N'Section được xem';
    DECLARE @lblGroupScope   NVARCHAR(100) = N'SC Group nhân viên được xem';
    DECLARE @lblNoData       NVARCHAR(200) = N'Không có dữ liệu.';
    DECLARE @lblLoginName    NVARCHAR(50)  = N'LoginName';
    DECLARE @lblEmployee     NVARCHAR(50)  = N'Nhân viên';
    DECLARE @lblStatus       NVARCHAR(50)  = N'Trạng thái';
    DECLARE @lblActive       NVARCHAR(50)  = N'Hoạt động';
    DECLARE @lblDisabled     NVARCHAR(50)  = N'Đã khóa';
    DECLARE @lblLockedOut    NVARCHAR(50)  = N'Đã Lockout';
    DECLARE @lblObjectName   NVARCHAR(50)  = N'Object';
    DECLARE @lblDescription  NVARCHAR(50)  = N'Mô tả';
    DECLARE @lblFullAccess   NVARCHAR(50)  = N'Quyền';
    DECLARE @lblGroupName    NVARCHAR(50)  = N'Nhóm quyền';
    DECLARE @lblFlag         NVARCHAR(50)  = N'Cờ';
    DECLARE @lblValue        NVARCHAR(50)  = N'Giá trị';
    DECLARE @lblLevel        NVARCHAR(50)  = N'Cấp';
    DECLARE @lblParentLogin  NVARCHAR(50)  = N'Parent LoginID';
    DECLARE @lblParentName   NVARCHAR(50)  = N'Tên tài khoản cha';
    DECLARE @lblDept         NVARCHAR(50)  = N'Phòng ban';
    DECLARE @lblSection      NVARCHAR(50)  = N'Section';
    DECLARE @lblViewScope    NVARCHAR(50)  = N'Được xem';
    DECLARE @lblYes          NVARCHAR(10)  = N'Có';
    DECLARE @lblNo           NVARCHAR(10)  = N'Không';
    DECLARE @lblDenied       NVARCHAR(30)  = N'Từ chối';
    DECLARE @lblReadOnly     NVARCHAR(30)  = N'Chỉ đọc';
    DECLARE @lblFollowGroup  NVARCHAR(30)  = N'Theo nhóm';
    DECLARE @lblFullCtrl     NVARCHAR(30)  = N'Toàn quyền';
    DECLARE @lblUnknown      NVARCHAR(30)  = N'Không xác định';
    DECLARE @lblSummary      NVARCHAR(100) = N'Tổng quan tất cả tài khoản';
    DECLARE @lblPermCount    NVARCHAR(50)  = N'Số quyền';

    IF @LanguageID = 'EN'
    BEGIN
        SET @title           = N'User Permission Audit Report';
        SET @lblAccount      = N'Account';
        SET @lblSelectAcct   = N'-- Select Account --';
        SET @lblAllAccts     = N'-- All Accounts --';
        SET @lblAcctInfo     = N'Account Information';
        SET @lblOverride     = N'Override Flags';
        SET @lblDirectPerm   = N'Direct Permissions';
        SET @lblGroupMember  = N'Group Memberships';
        SET @lblGroupPerm    = N'Group Permissions';
        SET @lblParentChain  = N'Parent Inheritance Chain';
        SET @lblDataScope    = N'Data Scope';
        SET @lblDeptScope    = N'Viewable Departments';
        SET @lblSectScope    = N'Viewable Sections';
        SET @lblGroupScope   = N'Viewable SC Groups';
        SET @lblNoData       = N'No data available.';
        SET @lblLoginName    = N'Login Name';
        SET @lblEmployee     = N'Employee';
        SET @lblStatus       = N'Status';
        SET @lblActive       = N'Active';
        SET @lblDisabled     = N'Disabled';
        SET @lblLockedOut    = N'Locked Out';
        SET @lblObjectName   = N'Object';
        SET @lblDescription  = N'Description';
        SET @lblFullAccess   = N'Permission';
        SET @lblGroupName    = N'Group Name';
        SET @lblFlag         = N'Flag';
        SET @lblValue        = N'Value';
        SET @lblLevel        = N'Level';
        SET @lblParentLogin  = N'Parent Login';
        SET @lblParentName   = N'Parent Name';
        SET @lblDept         = N'Department';
        SET @lblSection      = N'Section';
        SET @lblViewScope    = N'Viewable';
        SET @lblYes          = N'Yes';
        SET @lblNo           = N'No';
        SET @lblDenied       = N'Denied';
        SET @lblReadOnly     = N'Read Only';
        SET @lblFollowGroup  = N'Follow Group';
        SET @lblFullCtrl     = N'Full Access';
        SET @lblUnknown      = N'Unknown';
        SET @lblSummary      = N'All Accounts Summary';
        SET @lblPermCount    = N'Permission Count';
    END

    -- =========================================================================
    -- Layer 3: Biến *Js (escape cho JS string)
    -- =========================================================================
    DECLARE @lblNoDataJs      NVARCHAR(400) = REPLACE(REPLACE(@lblNoData,      N'\', N'\\'), N'"', N'\"');
    DECLARE @lblSelectAcctJs  NVARCHAR(400) = REPLACE(REPLACE(@lblSelectAcct,  N'\', N'\\'), N'"', N'\"');
    DECLARE @lblAllAcctsJs    NVARCHAR(400) = REPLACE(REPLACE(@lblAllAccts,    N'\', N'\\'), N'"', N'\"');

    -- =========================================================================
    -- Build account list for dropdown
    -- =========================================================================
    DECLARE @accountOptions NVARCHAR(MAX) = N'';

    IF @TargetLoginID IS NULL
    BEGIN
        -- Summary mode: show all accounts
        SELECT @accountOptions = @accountOptions
            + N'<option value="' + CAST(l.LoginID AS NVARCHAR) + N'">'
            + ISNULL(l.LoginName, N'(NULL)') + N' (ID: ' + CAST(l.LoginID AS NVARCHAR) + N')'
            + N'</option>'
        FROM tblSC_Login l
        ORDER BY l.LoginName;
    END
    ELSE
    BEGIN
        -- Pre-select the target account
        SELECT @accountOptions = @accountOptions
            + N'<option value="' + CAST(l.LoginID AS NVARCHAR) + N'"'
            + CASE WHEN l.LoginID = @TargetLoginID THEN N' selected' ELSE N'' END
            + N'>'
            + ISNULL(l.LoginName, N'(NULL)') + N' (ID: ' + CAST(l.LoginID AS NVARCHAR) + N')'
            + N'</option>'
        FROM tblSC_Login l
        ORDER BY l.LoginName;
    END

    -- =========================================================================
    -- Layer 4: Build @html NVARCHAR(MAX)
    -- =========================================================================
    DECLARE @html NVARCHAR(MAX) = N'';

    -- === CSS ===
    SET @html = @html + N'
<style>
    .pua-page {
        padding: var(--paradise-space-4);
        font-family: var(--paradise-font-family-base);
        color: var(--paradise-text-body);
        max-width: 1400px;
        margin: 0 auto;
    }
    .pua-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        flex-wrap: wrap;
        gap: var(--paradise-space-3);
        margin-bottom: var(--paradise-space-4);
    }
    .pua-title {
        font-size: 1.5rem;
        font-weight: 700;
        color: var(--paradise-color-header1);
        margin: 0;
    }
    .pua-selector {
        display: flex;
        gap: var(--paradise-space-2);
        align-items: center;
    }
    .pua-selector select {
        min-width: 280px;
        padding: 8px 12px;
        border: 1px solid var(--paradise-border-color);
        border-radius: var(--paradise-border-radius-md);
        font-size: 14px;
        background: var(--paradise-card-bg);
        color: var(--paradise-text-body);
    }
    .pua-selector .paradise-btn {
        white-space: nowrap;
    }
    .pua-section {
        margin-bottom: var(--paradise-space-4);
    }
    .pua-section-title {
        font-size: 1.1rem;
        font-weight: 600;
        color: var(--paradise-color-header2);
        margin: 0 0 var(--paradise-space-3) 0;
        padding-bottom: var(--paradise-space-2);
        border-bottom: 2px solid var(--paradise-color-primary);
    }
    .pua-card {
        background: var(--paradise-card-bg);
        border: 1px solid var(--paradise-card-border);
        border-radius: var(--paradise-border-radius-md);
        box-shadow: var(--paradise-shadow-sm);
        overflow: hidden;
    }
    .pua-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 0.9rem;
    }
    .pua-table th {
        background: var(--paradise-bg-primary-subtle);
        color: var(--paradise-color-header2);
        padding: 10px 14px;
        text-align: left;
        font-weight: 600;
        border-bottom: 2px solid var(--paradise-border-color);
        white-space: nowrap;
    }
    .pua-table td {
        padding: 8px 14px;
        border-bottom: 1px solid var(--paradise-border-color);
        vertical-align: top;
    }
    .pua-table tr:hover td {
        background: var(--paradise-bg-primary-subtle);
    }
    .pua-badge {
        display: inline-block;
        padding: 2px 10px;
        border-radius: var(--paradise-border-radius-pill);
        font-size: 0.8rem;
        font-weight: 600;
        white-space: nowrap;
    }
    .pua-badge--full     { background: var(--paradise-bg-success-subtle); color: var(--paradise-color-success); }
    .pua-badge--read     { background: var(--paradise-bg-info-subtle);    color: var(--paradise-color-info); }
    .pua-badge--denied   { background: var(--paradise-bg-danger-subtle);  color: var(--paradise-color-danger); }
    .pua-badge--follow   { background: var(--paradise-bg-warning-subtle); color: var(--paradise-color-warning); }
    .pua-badge--unknown  { background: var(--paradise-bg-secondary-subtle); color: var(--paradise-text-muted); }
    .pua-flag-true  { color: var(--paradise-color-success); font-weight: 600; }
    .pua-flag-false { color: var(--paradise-text-muted); }
    .pua-info-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
        gap: var(--paradise-space-2);
        padding: var(--paradise-space-3);
    }
    .pua-info-item {
        display: flex;
        justify-content: space-between;
        padding: 6px 0;
        border-bottom: 1px dotted var(--paradise-border-color);
    }
    .pua-info-label {
        font-weight: 500;
        color: var(--paradise-text-muted);
    }
    .pua-info-value {
        font-weight: 600;
    }
    .pua-empty {
        text-align: center;
        padding: var(--paradise-space-6);
        color: var(--paradise-text-muted);
        font-style: italic;
    }
    .pua-sub-group {
        padding: 4px 14px;
        font-weight: 600;
        color: var(--paradise-color-primary);
        background: var(--paradise-bg-primary-subtle);
    }
    .pua-summary-count {
        font-size: 0.85rem;
        color: var(--paradise-text-muted);
        margin-left: var(--paradise-space-2);
        font-weight: 400;
    }
</style>';

    -- === Page shell ===
    SET @html = @html + N'
<div class="pua-page">
    <div class="pua-header">
        <h1 class="pua-title">' + @title + N'</h1>
        <div class="pua-selector">
            <label for="puaAccountSelect">' + @lblAccount + N':</label>
            <select id="puaAccountSelect" onchange="puaOnAccountChange(this.value)">
                <option value="">' + @lblSelectAcct + N'</option>'
                + @accountOptions +
            N'</select>
            <button class="paradise-btn paradise-btn--reload" onclick="puaReload()">&#x21bb; Xem</button>
        </div>
    </div>
    <div id="puaContent">';

    -- =========================================================================
    -- Nếu @TargetLoginID IS NULL: hiển thị bảng tổng quan tất cả tài khoản
    -- =========================================================================
    IF @TargetLoginID IS NULL
    BEGIN
        SET @html = @html + N'
    <div class="pua-section">
        <h2 class="pua-section-title">' + @lblSummary + N'</h2>
        <div class="pua-card">
        <table class="pua-table">
            <thead><tr>
                <th>ID</th>
                <th>' + @lblLoginName + N'</th>
                <th>' + @lblEmployee + N'</th>
                <th>' + @lblStatus + N'</th>
                <th>isAdmin</th>
                <th>IsHRManager</th>
                <th>AlwaysFullAccess</th>
                <th>' + @lblPermCount + N'</th>
                <th>' + @lblGroupName + N'</th>
            </tr></thead>
            <tbody>';

        -- Query summary for all accounts
        DECLARE @summaryHTML NVARCHAR(MAX) = N'';

        SELECT @summaryHTML = @summaryHTML
            + N'<tr>'
            + N'<td>' + CAST(l.LoginID AS NVARCHAR) + N'</td>'
            + N'<td><strong>' + ISNULL(l.LoginName, N'NULL') + N'</strong></td>'
            + N'<td>' + ISNULL(l.EmployeeID, N'—') + N'</td>'
            + N'<td>'
            + CASE WHEN l.IsDisable = 1 THEN N'<span class="pua-badge pua-badge--denied">' + @lblDisabled + N'</span> '
                   WHEN l.IsLockout = 1 THEN N'<span class="pua-badge pua-badge--warning">' + @lblLockedOut + N'</span> '
                   ELSE N'<span class="pua-badge pua-badge--full">' + @lblActive + N'</span> '
              END
            + N'</td>'
            + N'<td>' + CASE WHEN l.isAdmin = 1 THEN N'<span class="pua-flag-true">Yes</span>' ELSE N'<span class="pua-flag-false">No</span>' END + N'</td>'
            + N'<td>' + CASE WHEN l.IsHRManager = 1 THEN N'<span class="pua-flag-true">Yes</span>' ELSE N'<span class="pua-flag-false">No</span>' END + N'</td>'
            + N'<td>' + CASE WHEN l.AlwaysFullAccess = 1 THEN N'<span class="pua-flag-true">Yes</span>' ELSE N'<span class="pua-flag-false">No</span>' END + N'</td>'
            + N'<td>' + CAST(ISNULL(dc.DirectCount, 0) AS NVARCHAR) + N'</td>'
            + N'<td>' + ISNULL(gn.GroupNames, N'—') + N'</td>'
            + N'</tr>'
        FROM tblSC_Login l
        OUTER APPLY (
            SELECT COUNT(*) AS DirectCount
            FROM tblSC_Right_Stored rs
            WHERE rs.LoginID = l.LoginID
        ) dc
        OUTER APPLY (
            SELECT STRING_AGG(urg.UserGroupName, N', ') AS GroupNames
            FROM tblUserGrantGroup ug
            INNER JOIN tblUserRightGroup urg ON urg.UserGroupID = ug.UserGroupID
            WHERE ug.UserID = CAST(l.LoginID AS varchar)
        ) gn
        ORDER BY l.LoginName;

        SET @html = @html + ISNULL(@summaryHTML, N'<tr><td colspan="9" class="pua-empty">' + @lblNoData + N'</td></tr>');

        SET @html = @html + N'
            </tbody>
        </table>
        </div>
    </div>';
    END
    ELSE
    BEGIN
        -- =====================================================================
        -- @TargetLoginID IS NOT NULL: Hiển thị chi tiết đầy đủ cho 1 account
        -- =====================================================================

        -- -----------------------------------------------------------------
        -- SECTION 1: Thông tin tài khoản + Override Flags
        -- -----------------------------------------------------------------
        DECLARE @acctHTML NVARCHAR(MAX) = N'';
        DECLARE @parentHTML NVARCHAR(MAX) = N'';
        DECLARE @directHTML NVARCHAR(MAX) = N'';
        DECLARE @groupMemHTML NVARCHAR(MAX) = N'';
        DECLARE @groupPermHTML NVARCHAR(MAX) = N'';
        DECLARE @deptScopeHTML NVARCHAR(MAX) = N'';
        DECLARE @sectScopeHTML NVARCHAR(MAX) = N'';
        DECLARE @scGroupScopeHTML NVARCHAR(MAX) = N'';

        -- Account info
        SELECT @acctHTML = @acctHTML
            + N'<div class="pua-info-item"><span class="pua-info-label">LoginID:</span><span class="pua-info-value">' + CAST(l.LoginID AS NVARCHAR) + N'</span></div>'
            + N'<div class="pua-info-item"><span class="pua-info-label">LoginName:</span><span class="pua-info-value">' + ISNULL(l.LoginName, N'(NULL)') + N'</span></div>'
            + N'<div class="pua-info-item"><span class="pua-info-label">EmployeeID:</span><span class="pua-info-value">' + ISNULL(l.EmployeeID, N'—') + N'</span></div>'
            + N'<div class="pua-info-item"><span class="pua-info-label">DepartmentID:</span><span class="pua-info-value">' + ISNULL(CAST(l.DepartmentID AS NVARCHAR), N'—') + N'</span></div>'
            + N'<div class="pua-info-item"><span class="pua-info-label">IsDisable:</span><span class="pua-info-value">' + CASE WHEN l.IsDisable = 1 THEN N'<span class="pua-flag-true">YES</span>' ELSE N'<span class="pua-flag-false">No</span>' END + N'</span></div>'
            + N'<div class="pua-info-item"><span class="pua-info-label">IsLockout:</span><span class="pua-info-value">' + CASE WHEN l.IsLockout = 1 THEN N'<span class="pua-flag-true">YES</span>' ELSE N'<span class="pua-flag-false">No</span>' END + N'</span></div>'
            + N'<div class="pua-info-item"><span class="pua-info-label">IsActive:</span><span class="pua-info-value">' + CASE WHEN l.IsActive = 1 THEN N'<span class="pua-flag-true">Yes</span>' ELSE N'<span class="pua-flag-false">No</span>' END + N'</span></div>'
            + N'<div class="pua-info-item"><span class="pua-info-label">ParentLoginID:</span><span class="pua-info-value">' + ISNULL(l.ParentLoginID, N'—') + N'</span></div>'
        FROM tblSC_Login l
        WHERE l.LoginID = @TargetLoginID;

        -- Override flags
        DECLARE @flagHTML NVARCHAR(MAX) = N'';
        SELECT @flagHTML = @flagHTML
            + N'<tr><td>isAdmin</td><td>'            + CASE WHEN l.isAdmin = 1            THEN N'<span class="pua-badge pua-badge--full">1 (YES)</span>'   ELSE N'<span class="pua-badge pua-badge--denied">0 (No)</span>' END + N'</td></tr>'
            + N'<tr><td>IsHRManager</td><td>'         + CASE WHEN l.IsHRManager = 1         THEN N'<span class="pua-badge pua-badge--full">1 (YES)</span>'   ELSE N'<span class="pua-badge pua-badge--denied">0 (No)</span>' END + N'</td></tr>'
            + N'<tr><td>IsBigBoss</td><td>'           + CASE WHEN l.IsBigBoss = 1           THEN N'<span class="pua-badge pua-badge--full">1 (YES)</span>'   ELSE N'<span class="pua-badge pua-badge--denied">0 (No)</span>' END + N'</td></tr>'
            + N'<tr><td>AlwaysFullAccess</td><td>'    + CASE WHEN l.AlwaysFullAccess = 1    THEN N'<span class="pua-badge pua-badge--full">1 (YES)</span>'   ELSE N'<span class="pua-badge pua-badge--denied">0 (No)</span>' END + N'</td></tr>'
            + N'<tr><td>UseGroupRightOnly</td><td>'   + CASE WHEN l.UseGroupRightOnly = 1   THEN N'<span class="pua-badge pua-badge--follow">1 (YES)</span>'  ELSE N'<span class="pua-badge pua-badge--denied">0 (No)</span>' END + N'</td></tr>'
            + N'<tr><td>IsAuditAccount</td><td>'      + CASE WHEN l.IsAuditAccount = 1      THEN N'<span class="pua-badge pua-badge--full">1 (YES)</span>'   ELSE N'<span class="pua-badge pua-badge--denied">0 (No)</span>' END + N'</td></tr>'
            + N'<tr><td>IsSelfService</td><td>'       + CASE WHEN l.IsSelfService = 1       THEN N'<span class="pua-badge pua-badge--full">1 (YES)</span>'   ELSE N'<span class="pua-badge pua-badge--denied">0 (No)</span>' END + N'</td></tr>'
            + N'<tr><td>ActiveWeb</td><td>'           + CASE WHEN l.ActiveWeb = 1           THEN N'<span class="pua-badge pua-badge--full">1 (YES)</span>'   ELSE N'<span class="pua-badge pua-badge--denied">0 (No)</span>' END + N'</td></tr>'
            + N'<tr><td>isAdmin (raw)</td><td>'       + CASE WHEN l.isAdmin = 1             THEN N'<span class="pua-badge pua-badge--full">1 (YES)</span>'   ELSE N'<span class="pua-badge pua-badge--denied">0 (No)</span>' END + N'</td></tr>'
        FROM tblSC_Login l
        WHERE l.LoginID = @TargetLoginID;

        -- Build Section 1 HTML
        SET @html = @html + N'
    <div class="pua-section">
        <h2 class="pua-section-title">' + @lblAcctInfo + N'</h2>
        <div class="pua-card">
            <div class="pua-info-grid">'
            + ISNULL(@acctHTML, N'<div class="pua-empty">' + @lblNoData + N'</div>')
            + N'</div>
        </div>
    </div>

    <div class="pua-section">
        <h2 class="pua-section-title">' + @lblOverride + N'</h2>
        <div class="pua-card">
        <table class="pua-table">
            <thead><tr><th>' + @lblFlag + N'</th><th>' + @lblValue + N'</th></tr></thead>
            <tbody>'
            + ISNULL(@flagHTML, N'<tr><td colspan="2" class="pua-empty">' + @lblNoData + N'</td></tr>')
            + N'</tbody>
        </table>
        </div>
    </div>';

        -- -----------------------------------------------------------------
        -- SECTION 2: Chuỗi kế thừa cha (Parent Inheritance Chain)
        -- -----------------------------------------------------------------
        DECLARE @parentLoginIDChain VARCHAR(500);
        SELECT @parentLoginIDChain = ParentLoginID
        FROM tblSC_Login
        WHERE LoginID = @TargetLoginID;

        IF @parentLoginIDChain IS NOT NULL AND @parentLoginIDChain != ''
        BEGIN
            -- Resolve parent chain (1 level)
            SELECT @parentHTML = @parentHTML
                + N'<tr>'
                + N'<td>' + CAST(pc.Level AS NVARCHAR) + N'</td>'
                + N'<td>' + CAST(l.LoginID AS NVARCHAR) + N'</td>'
                + N'<td><strong>' + ISNULL(l.LoginName, N'NULL') + N'</strong></td>'
                + N'<td>' + CASE WHEN l.isAdmin = 1 THEN N'<span class="pua-badge pua-badge--full">Admin</span>' ELSE N'<span class="pua-flag-false">No</span>' END + N'</td>'
                + N'<td>' + CASE WHEN l.IsHRManager = 1 THEN N'<span class="pua-badge pua-badge--full">Yes</span>' ELSE N'<span class="pua-flag-false">No</span>' END + N'</td>'
                + N'<td>' + CASE WHEN l.AlwaysFullAccess = 1 THEN N'<span class="pua-badge pua-badge--full">Yes</span>' ELSE N'<span class="pua-flag-false">No</span>' END + N'</td>'
                + N'<td>' + CAST(ISNULL(pc.DirectCount, 0) AS NVARCHAR) + N'</td>'
                + N'<td>' + ISNULL(l.ParentLoginID, N'—') + N'</td>'
                + N'</tr>'
            FROM tblSC_Login target
            CROSS APPLY dbo.SplitString(target.ParentLoginID, '&') split
            INNER JOIN tblSC_Login l ON CAST(split.Items AS INT) = l.LoginID
            OUTER APPLY (
                SELECT COUNT(*) AS DirectCount, 1 AS Level
                FROM tblSC_Right_Stored rs
                WHERE rs.LoginID = l.LoginID
            ) pc
            WHERE target.LoginID = @TargetLoginID
            ORDER BY pc.Level, l.LoginName;

            SET @html = @html + N'
    <div class="pua-section">
        <h2 class="pua-section-title">' + @lblParentChain + N'</h2>
        <div class="pua-card">
        <table class="pua-table">
            <thead><tr>
                <th>' + @lblLevel + N'</th>
                <th>ID</th>
                <th>' + @lblParentName + N'</th>
                <th>isAdmin</th>
                <th>IsHRManager</th>
                <th>AlwaysFullAccess</th>
                <th>' + @lblPermCount + N'</th>
                <th>' + @lblParentLogin + N'</th>
            </tr></thead>
            <tbody>'
            + ISNULL(@parentHTML, N'<tr><td colspan="8" class="pua-empty">' + @lblNoData + N'</td></tr>')
            + N'</tbody>
        </table>
        </div>
    </div>';
        END
        ELSE
        BEGIN
            SET @html = @html + N'
    <div class="pua-section">
        <h2 class="pua-section-title">' + @lblParentChain + N'</h2>
        <div class="pua-card"><div class="pua-empty">' + @lblNoData + N' (Không có ParentLoginID)</div></div>
    </div>';
        END

        -- -----------------------------------------------------------------
        -- SECTION 3: Quyền trực tiếp (tblSC_Right_Stored)
        -- -----------------------------------------------------------------
        SELECT @directHTML = @directHTML
            + N'<tr>'
            + N'<td>' + CAST(o.ObjectID AS NVARCHAR) + N'</td>'
            + N'<td>' + ISNULL(o.ObjectName, N'—') + N'</td>'
            + N'<td>' + ISNULL(msg.Content, ISNULL(o.Description, N'—')) + N'</td>'
            + CASE rs.FullAccess
                WHEN N'32' THEN N'<td><span class="pua-badge pua-badge--full">32 — ' + @lblFullCtrl + N'</span></td>'
                WHEN N'1'  THEN N'<td><span class="pua-badge pua-badge--read">1 — ' + @lblReadOnly + N'</span></td>'
                WHEN N'0'  THEN N'<td><span class="pua-badge pua-badge--denied">0 — ' + @lblDenied + N'</span></td>'
                WHEN N'8'  THEN N'<td><span class="pua-badge pua-badge--follow">8 — ' + @lblFollowGroup + N'</span></td>'
                ELSE N'<td><span class="pua-badge pua-badge--unknown">' + ISNULL(rs.FullAccess, N'NULL') + N'</span></td>'
              END
            + N'</tr>'
        FROM tblSC_Right_Stored rs
        INNER JOIN tblSC_Object o ON o.ObjectID = rs.ObjectID
        LEFT JOIN tblMD_Message msg ON msg.MessageID = o.ObjectName AND msg.Language = @LanguageID
        WHERE rs.LoginID = @TargetLoginID
        ORDER BY o.ObjectName;

        SET @html = @html + N'
    <div class="pua-section">
        <h2 class="pua-section-title">' + @lblDirectPerm + N'<span class="pua-summary-count">(tblSC_Right_Stored)</span></h2>
        <div class="pua-card">
        <table class="pua-table">
            <thead><tr>
                <th>ObjectID</th>
                <th>' + @lblObjectName + N'</th>
                <th>' + @lblDescription + N'</th>
                <th>' + @lblFullAccess + N'</th>
            </tr></thead>
            <tbody>'
            + ISNULL(@directHTML, N'<tr><td colspan="4" class="pua-empty">' + @lblNoData + N'</td></tr>')
            + N'</tbody>
        </table>
        </div>
    </div>';

        -- -----------------------------------------------------------------
        -- SECTION 4: Thành viên nhóm quyền
        -- -----------------------------------------------------------------
        SELECT @groupMemHTML = @groupMemHTML
            + N'<tr>'
            + N'<td>' + CAST(urg.UserGroupID AS NVARCHAR) + N'</td>'
            + N'<td><strong>' + ISNULL(urg.UserGroupName, N'—') + N'</strong></td>'
            + N'</tr>'
        FROM tblUserGrantGroup ug
        INNER JOIN tblUserRightGroup urg ON urg.UserGroupID = ug.UserGroupID
        WHERE ug.UserID = CAST(@TargetLoginID AS varchar)
        ORDER BY urg.UserGroupName;

        SET @html = @html + N'
    <div class="pua-section">
        <h2 class="pua-section-title">' + @lblGroupMember + N'<span class="pua-summary-count">(tblUserGrantGroup)</span></h2>
        <div class="pua-card">
        <table class="pua-table">
            <thead><tr>
                <th>UserGroupID</th>
                <th>' + @lblGroupName + N'</th>
            </tr></thead>
            <tbody>'
            + ISNULL(@groupMemHTML, N'<tr><td colspan="2" class="pua-empty">' + @lblNoData + N'</td></tr>')
            + N'</tbody>
        </table>
        </div>
    </div>';

        -- -----------------------------------------------------------------
        -- SECTION 5: Quyền theo nhóm (Group Permissions)
        -- -----------------------------------------------------------------
        SELECT @groupPermHTML = @groupPermHTML
            + N'<tr>'
            + N'<td>' + ISNULL(urg.UserGroupName, N'—') + N'</td>'
            + N'<td>' + CAST(o.ObjectID AS NVARCHAR) + N'</td>'
            + N'<td>' + ISNULL(o.ObjectName, N'—') + N'</td>'
            + N'<td>' + ISNULL(msg.Content, ISNULL(o.Description, N'—')) + N'</td>'
            + CASE gr.FullAccess
                WHEN 32 THEN N'<td><span class="pua-badge pua-badge--full">32 — ' + @lblFullCtrl + N'</span></td>'
                WHEN 1  THEN N'<td><span class="pua-badge pua-badge--read">1 — ' + @lblReadOnly + N'</span></td>'
                WHEN 0  THEN N'<td><span class="pua-badge pua-badge--denied">0 — ' + @lblDenied + N'</span></td>'
                WHEN 8  THEN N'<td><span class="pua-badge pua-badge--follow">8 — ' + @lblFollowGroup + N'</span></td>'
                ELSE N'<td><span class="pua-badge pua-badge--unknown">' + ISNULL(CAST(gr.FullAccess AS NVARCHAR), N'NULL') + N'</span></td>'
              END
            + N'</tr>'
        FROM tblUserGrantGroup ug
        INNER JOIN tblSC_GroupRight gr ON gr.UserGroupID = ug.UserGroupID
        INNER JOIN tblSC_Object o ON o.ObjectID = gr.ObjectID
        INNER JOIN tblUserRightGroup urg ON urg.UserGroupID = ug.UserGroupID
        LEFT JOIN tblMD_Message msg ON msg.MessageID = o.ObjectName AND msg.Language = @LanguageID
        WHERE ug.UserID = CAST(@TargetLoginID AS varchar)
        ORDER BY urg.UserGroupName, o.ObjectName;

        SET @html = @html + N'
    <div class="pua-section">
        <h2 class="pua-section-title">' + @lblGroupPerm + N'<span class="pua-summary-count">(tblSC_GroupRight)</span></h2>
        <div class="pua-card">
        <table class="pua-table">
            <thead><tr>
                <th>' + @lblGroupName + N'</th>
                <th>ObjectID</th>
                <th>' + @lblObjectName + N'</th>
                <th>' + @lblDescription + N'</th>
                <th>' + @lblFullAccess + N'</th>
            </tr></thead>
            <tbody>'
            + ISNULL(@groupPermHTML, N'<tr><td colspan="5" class="pua-empty">' + @lblNoData + N'</td></tr>')
            + N'</tbody>
        </table>
        </div>
    </div>';

        -- -----------------------------------------------------------------
        -- SECTION 6: Phạm vi dữ liệu — Phòng ban
        -- -----------------------------------------------------------------
        SELECT @deptScopeHTML = @deptScopeHTML
            + N'<tr>'
            + N'<td>' + ISNULL(urg.UserGroupName, N'—') + N'</td>'
            + N'<td>' + CAST(d.DepartmentID AS NVARCHAR) + N'</td>'
            + N'<td>' + ISNULL(
                CASE WHEN @LanguageID = 'EN' THEN d.DepartmentNameEN ELSE d.DepartmentName END,
                N'—'
            ) + N'</td>'
            + N'<td>' + CASE WHEN dvg.ViewInfo = 1 THEN N'<span class="pua-badge pua-badge--full">' + @lblYes + N'</span>' ELSE N'<span class="pua-badge pua-badge--denied">' + @lblNo + N'</span>' END + N'</td>'
            + N'</tr>'
        FROM tblUserGrantGroup ug
        INNER JOIN tblSC_DepartmentView_Group dvg ON dvg.UserGroupID = ug.UserGroupID
        INNER JOIN tblDepartment d ON d.DepartmentID = dvg.DepartmentID
        INNER JOIN tblUserRightGroup urg ON urg.UserGroupID = ug.UserGroupID
        WHERE ug.UserID = CAST(@TargetLoginID AS varchar)
        ORDER BY urg.UserGroupName, d.DepartmentName;

        SET @html = @html + N'
    <div class="pua-section">
        <h2 class="pua-section-title">' + @lblDataScope + N'</h2>

        <h3 style="margin: 16px 0 8px 0; color: var(--paradise-color-header2);">' + @lblDeptScope + N'<span class="pua-summary-count">(tblSC_DepartmentView_Group)</span></h3>
        <div class="pua-card">
        <table class="pua-table">
            <thead><tr>
                <th>' + @lblGroupName + N'</th>
                <th>DepartmentID</th>
                <th>' + @lblDept + N'</th>
                <th>' + @lblViewScope + N'</th>
            </tr></thead>
            <tbody>'
            + ISNULL(@deptScopeHTML, N'<tr><td colspan="4" class="pua-empty">' + @lblNoData + N'</td></tr>')
            + N'</tbody>
        </table>
        </div>';

        -- -----------------------------------------------------------------
        -- SECTION 6b: Phạm vi dữ liệu — Section
        -- -----------------------------------------------------------------
        SELECT @sectScopeHTML = @sectScopeHTML
            + N'<tr>'
            + N'<td>' + ISNULL(urg.UserGroupName, N'—') + N'</td>'
            + N'<td>' + CAST(d.DepartmentID AS NVARCHAR) + N'</td>'
            + N'<td>' + ISNULL(
                CASE WHEN @LanguageID = 'EN' THEN d.DepartmentNameEN ELSE d.DepartmentName END,
                N'—'
            ) + N'</td>'
            + N'<td>' + CAST(svg.SectionID AS NVARCHAR) + N'</td>'
            + N'<td>' + CASE WHEN svg.ViewInfo = 1 THEN N'<span class="pua-badge pua-badge--full">' + @lblYes + N'</span>' ELSE N'<span class="pua-badge pua-badge--denied">' + @lblNo + N'</span>' END + N'</td>'
            + N'</tr>'
        FROM tblUserGrantGroup ug
        INNER JOIN tblSC_SectionView_Group svg ON svg.UserGroupID = ug.UserGroupID
        INNER JOIN tblDepartment d ON d.DepartmentID = svg.DepartmentID
        INNER JOIN tblUserRightGroup urg ON urg.UserGroupID = ug.UserGroupID
        WHERE ug.UserID = CAST(@TargetLoginID AS varchar)
        ORDER BY urg.UserGroupName, d.DepartmentName, svg.SectionID;

        SET @html = @html + N'
        <h3 style="margin: 16px 0 8px 0; color: var(--paradise-color-header2);">' + @lblSectScope + N'<span class="pua-summary-count">(tblSC_SectionView_Group)</span></h3>
        <div class="pua-card">
        <table class="pua-table">
            <thead><tr>
                <th>' + @lblGroupName + N'</th>
                <th>DepartmentID</th>
                <th>' + @lblDept + N'</th>
                <th>SectionID</th>
                <th>' + @lblViewScope + N'</th>
            </tr></thead>
            <tbody>'
            + ISNULL(@sectScopeHTML, N'<tr><td colspan="5" class="pua-empty">' + @lblNoData + N'</td></tr>')
            + N'</tbody>
        </table>
        </div>';

        -- -----------------------------------------------------------------
        -- SECTION 6c: Phạm vi dữ liệu — SC Group nhân viên
        -- -----------------------------------------------------------------
        SELECT @scGroupScopeHTML = @scGroupScopeHTML
            + N'<tr>'
            + N'<td>' + ISNULL(urg.UserGroupName, N'—') + N'</td>'
            + N'<td>' + CAST(gvg.GroupID AS NVARCHAR) + N'</td>'
            + N'<td>' + ISNULL(sg.GroupName, N'—') + N'</td>'
            + N'<td>' + CAST(gvg.SectionID AS NVARCHAR) + N'</td>'
            + N'<td>' + CASE WHEN gvg.ViewInfo = 1 THEN N'<span class="pua-badge pua-badge--full">' + @lblYes + N'</span>' ELSE N'<span class="pua-badge pua-badge--denied">' + @lblNo + N'</span>' END + N'</td>'
            + N'</tr>'
        FROM tblUserGrantGroup ug
        INNER JOIN tblSC_GroupView_Group gvg ON gvg.UserGroupID = ug.UserGroupID
        INNER JOIN tblUserRightGroup urg ON urg.UserGroupID = ug.UserGroupID
        LEFT JOIN tblSC_Group sg ON sg.GroupID = gvg.GroupID
        WHERE ug.UserID = CAST(@TargetLoginID AS varchar)
        ORDER BY urg.UserGroupName, sg.GroupName;

        SET @html = @html + N'
        <h3 style="margin: 16px 0 8px 0; color: var(--paradise-color-header2);">' + @lblGroupScope + N'<span class="pua-summary-count">(tblSC_GroupView_Group)</span></h3>
        <div class="pua-card">
        <table class="pua-table">
            <thead><tr>
                <th>' + @lblGroupName + N'</th>
                <th>GroupID</th>
                <th>' + @lblGroupName + N' (SC Group)</th>
                <th>SectionID</th>
                <th>' + @lblViewScope + N'</th>
            </tr></thead>
            <tbody>'
            + ISNULL(@scGroupScopeHTML, N'<tr><td colspan="5" class="pua-empty">' + @lblNoData + N'</td></tr>')
            + N'</tbody>
        </table>
        </div>';

    END -- End of @TargetLoginID IS NOT NULL block

    -- === Close page shell ===
    SET @html = @html + N'
    </div><!-- #puaContent -->
</div><!-- .pua-page -->

<script>
(function() {
    function puaOnAccountChange(loginID) {
        if (!loginID) return;
        // Reload page with selected account via AjaxHPAParadise
        var url = window.location.href.split("?")[0] + "?TargetLoginID=" + loginID;
        window.location.href = url;
    }
    function puaReload() {
        var sel = document.getElementById("puaAccountSelect");
        if (sel && sel.value) {
            puaOnAccountChange(sel.value);
        }
    }
    // Expose to global scope for inline onchange handler
    window.puaOnAccountChange = puaOnAccountChange;
    window.puaReload = puaReload;
})();
</script>';

    -- =========================================================================
    -- Return HTML (cache được build bởi sp_GenerateHTMLScript — Phase F)
    -- =========================================================================
    SELECT @html AS html;
END
GO

-- ============================================================================
-- PART 2: WRAPPER — sp_Report_UserPermissionAudit
-- Đọc HTML từ cache hoặc fallback gọi trực tiếp renderer
-- ============================================================================

CREATE OR ALTER PROCEDURE dbo.sp_Report_UserPermissionAudit
    @LoginID        INT          = NULL,
    @TargetLoginID  INT          = NULL,
    @LanguageID     VARCHAR(2)   = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;

    DECLARE @html NVARCHAR(MAX);

    -- Try cache first
    SELECT @html = html
    FROM dbo.tblHtmlScriptCache
    WHERE TableName  = N'sp_Report_UserPermissionAudit_html'
      AND LanguageID = @LanguageID
      AND ScreenType = -1;

    -- Fallback: call renderer directly
    IF @html IS NULL OR @html = N''
    BEGIN
        EXEC dbo.sp_Report_UserPermissionAudit_html
            @LoginID       = @LoginID,
            @TargetLoginID = @TargetLoginID,
            @LanguageID    = @LanguageID;
        RETURN;
    END

    SELECT @html AS html;
END
GO

-- ============================================================================
-- DONE
-- ============================================================================
PRINT N'Created: sp_Report_UserPermissionAudit_html (Renderer)';
PRINT N'Created: sp_Report_UserPermissionAudit (Wrapper)';
GO
