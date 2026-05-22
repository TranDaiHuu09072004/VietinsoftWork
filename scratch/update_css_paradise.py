import re
from pathlib import Path

# Paths
raw_sql_path = Path(r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\scratch\sp_ResignationLeave_Mobile_raw.sql")
out_sql_path = Path(r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\update_menu_ResignationLeave_html_ParadiseStyle.sql")

# Read the raw SQL
content = raw_sql_path.read_text(encoding="utf-8-sig")

style_start_idx = content.find("<style>")
style_end_idx = content.find("</style>")

if style_start_idx == -1 or style_end_idx == -1:
    print("Error: Could not find <style> or </style> block!")
    exit(1)

# New CSS style content
new_css = """<style>
    /* Scope under root menu */
    #sp_ResignationLeave {
        --vc-green-transparent005: var(--paradise-bg-success-subtle);
        --vc-green-transparent02: var(--paradise-bg-success-subtle);
        --vc-red-transparent005: var(--paradise-bg-danger-subtle);
        --vc-red-transparent02: var(--paradise-bg-danger-subtle);
        --bs-green: var(--paradise-color-success);
        --vc-red: var(--paradise-color-danger);
    }

    #sp_FormEmployee {
        max-width: 768px !important;
        margin: 0 auto !important;
        background-color: transparent !important;
    }

    #sp_FormEmployee #divAdvAL {
        align-items: center;
    }
    #sp_FormEmployee #divAdvAL .col-form-label {
        display: flex;
        align-items: center;
    }
    #sp_FormEmployee #AdvAL {
        margin-right: 8px;
    }

    /* Modal styling */
    #sp_FormEmployee .modal-body p {
        margin-bottom: 0.75rem;
        font-size: 1rem;
    }
    #sp_FormEmployee .modal-body strong {
        color: var(--paradise-text-body);
    }
    #sp_FormEmployee .modal-content {
        background-color: var(--paradise-card-bg) !important;
        color: var(--paradise-text-body) !important;
        border: 1px solid var(--paradise-border-color) !important;
        border-radius: var(--paradise-border-radius-md) !important;
        box-shadow: var(--paradise-shadow-md) !important;
    }
    #sp_FormEmployee .modal-header {
        background-color: var(--paradise-bg-2) !important;
        border-bottom: 1px solid var(--paradise-border-color) !important;
        color: var(--paradise-text-body) !important;
    }

    /* Main card */
    #sp_FormEmployee .card {
        background-color: var(--paradise-card-bg) !important;
        border: 1px solid var(--paradise-border-color) !important;
        border-radius: var(--paradise-border-radius-lg) !important;
        box-shadow: var(--paradise-shadow-sm) !important;
        overflow: visible !important;
        height: auto !important;
        margin: var(--paradise-space-3) 0 !important;
    }
    #sp_FormEmployee .card-body {
        padding: var(--paradise-space-4);
        min-height: calc(100vh - 100px);
    }

    #sp_FormEmployee #register-tab {
        overflow: visible !important;
        height: auto !important;
    }

    #sp_FormEmployee #historyList {
        padding-bottom: var(--paradise-space-4);
    }

    /* Media queries for responsive layouts */
    @media (min-width: 992px) {
        #sp_FormEmployee {
            max-width: 900px !important;
        }
    }
    @media (min-width: 1200px) {
        #sp_FormEmployee {
            max-width: 1000px !important;
        }
    }
    @media (max-width: 576px) {
        #sp_FormEmployee #history-tab {
            height: calc(100vh - 120px) !important;
        }
    }

    #sp_FormEmployee .col-form-label, 
    #sp_FormEmployee .form-label {
        font-size: 0.95rem;
        font-weight: 500;
        color: var(--paradise-text-muted);
    }

    #sp_FormEmployee .from_day, 
    #sp_FormEmployee .to_day {
        width: 50%;
    }

    /* Inputs & Form Controls */
    #sp_FormEmployee .form-control {
        background-color: var(--paradise-bg-surface) !important;
        color: var(--paradise-text-body) !important;
        border: 1px solid var(--paradise-border-color) !important;
        border-radius: var(--paradise-input-border-radius, var(--paradise-border-radius-md)) !important;
        padding: var(--paradise-space-2) var(--paradise-space-3) !important;
        font-size: 0.95rem;
        transition: border-color var(--paradise-transition-fast), box-shadow var(--paradise-transition-fast);
    }
    #sp_FormEmployee .form-control:focus {
        border-color: var(--paradise-color-primary) !important;
        box-shadow: 0 0 0 3px var(--paradise-bg-primary-subtle) !important;
        outline: none !important;
    }
    #sp_FormEmployee .form-control[readonly],
    #sp_FormEmployee .form-control:disabled {
        background-color: var(--paradise-bg-surface) !important;
        opacity: 0.7;
        cursor: not-allowed;
    }
    #sp_FormEmployee .dx-selectbox-readonly {
        background-color: var(--paradise-bg-surface) !important;
        opacity: 0.7;
        cursor: not-allowed;
    }

    /* Checkbox & Radio Labels cursor: pointer */
    #sp_FormEmployee .form-check {
        display: inline-flex;
        align-items: center;
        padding: var(--paradise-space-2) var(--paradise-space-3);
        border-radius: var(--paradise-border-radius-md);
        border: 2px solid transparent;
        transition: border-color var(--paradise-transition-fast), background-color var(--paradise-transition-fast);
        cursor: pointer;
    }
    #sp_FormEmployee .form-check.active {
        border-color: var(--paradise-color-primary);
        background-color: var(--paradise-bg-primary-subtle);
    }
    #sp_FormEmployee .form-check-group {
        display: flex;
        flex-direction: row;
        justify-content: center;
        gap: var(--paradise-space-4);
    }
    #sp_FormEmployee .form-check-input {
        margin-right: var(--paradise-space-2);
        cursor: pointer;
    }
    #sp_FormEmployee .form-check-label {
        font-size: 0.95rem;
        cursor: pointer;
        user-select: none;
    }

    /* Section Titles */
    #sp_FormEmployee .section-title {
        font-size: 0.95rem;
        color: var(--paradise-text-muted);
        margin-bottom: var(--paradise-space-3);
        display: flex;
        align-items: center;
        gap: var(--paradise-space-2);
    }
    #sp_FormEmployee .section-title.detail-title {
        font-size: 1.2rem;
        font-weight: 600;
        color: var(--paradise-color-primary);
        border-bottom: 2px solid var(--paradise-color-primary);
        padding-bottom: var(--paradise-space-2);
    }

    /* Back button */
    #sp_FormEmployee .back-btn {
        background: none;
        border: none;
        color: var(--paradise-color-primary);
        font-size: 1.5rem;
        margin-right: var(--paradise-space-3);
        padding: var(--paradise-space-2);
        border-radius: 50%;
        transition: background-color var(--paradise-transition-fast);
        display: flex;
        align-items: center;
        justify-content: center;
    }
    #sp_FormEmployee .back-btn:hover {
        background-color: var(--paradise-bg-primary-subtle);
    }

    /* Tabs */
    #sp_FormEmployee #tabs {
        display: flex;
        border-bottom: 1px solid var(--paradise-border-color);
        margin-bottom: var(--paradise-space-4);
    }
    #sp_FormEmployee .tab {
        flex: 1;
        text-align: center;
        padding: var(--paradise-space-3);
        font-size: 0.95rem;
        font-weight: 500;
        color: var(--paradise-text-muted);
        cursor: pointer;
        transition: color var(--paradise-transition-fast), border-bottom var(--paradise-transition-fast);
    }
    #sp_FormEmployee .tab.active {
        color: var(--paradise-color-primary) !important;
        border-bottom: 2px solid var(--paradise-color-primary) !important;
        font-weight: 600;
    }

    /* Employee info container */
    #sp_FormEmployee .employee-info {
        margin-bottom: var(--paradise-space-4);
        padding: var(--paradise-space-4);
        border: 1px solid var(--paradise-border-color);
        border-radius: var(--paradise-border-radius-md);
        background-color: var(--paradise-bg-surface);
        display: flex;
        flex-direction: row;
        align-items: center;
        gap: var(--paradise-space-3);
    }
    #sp_FormEmployee .employee-info .avatar-container {
        margin-right: var(--paradise-space-3);
    }
    #sp_FormEmployee .employee-info .info-container {
        text-align: left;
    }
    #sp_FormEmployee .employee-info label {
        font-weight: 600;
        color: var(--paradise-text-body);
        margin-right: var(--paradise-space-2);
    }
    #sp_FormEmployee .employee-info span {
        color: var(--paradise-text-body);
    }

    /* History and Pending list Cards */
    #historyList .oa-card .card,
    #sp_FormEmployee #employeeLeaveHistoryList .oa-card .card {
        position: relative;
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        background-color: var(--paradise-card-bg) !important;
        border: 1px solid var(--paradise-border-color) !important;
        border-radius: var(--paradise-border-radius-md) !important;
        padding: var(--paradise-space-3) var(--paradise-space-4) !important;
        box-shadow: var(--paradise-shadow-sm) !important;
        transition: transform var(--paradise-transition-normal), box-shadow var(--paradise-transition-normal);
        margin-bottom: var(--paradise-space-3);
        cursor: pointer;
    }
    #historyList .oa-card:hover .card,
    #sp_FormEmployee #employeeLeaveHistoryList .oa-card:hover .card {
        transform: translateY(-2px);
        box-shadow: var(--paradise-shadow-md) !important;
        border-color: var(--paradise-color-primary) !important;
    }

    /* Status badges as beautiful pills */
    .request-draft-btn,
    .request-thisApproved-btn,
    .request-approved-btn,
    .request-rejected-btn {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        height: 28px !important;
        padding: var(--paradise-space-1) var(--paradise-space-3) !important;
        border-radius: var(--paradise-border-radius-pill) !important;
        font-weight: 600 !important;
        font-size: 12px !important;
        border: 1px solid transparent !important;
        position: absolute !important;
        bottom: 12px !important;
        right: 16px !important;
        cursor: pointer;
        width: fit-content;
    }
    .request-draft-btn {
        color: var(--paradise-text-muted) !important;
        background-color: var(--paradise-bg-secondary-subtle) !important;
        border-color: var(--paradise-border-color) !important;
    }
    .request-thisApproved-btn {
        color: var(--paradise-color-info) !important;
        background-color: var(--paradise-bg-info-subtle) !important;
        border-color: var(--paradise-bg-info-subtle) !important;
    }
    .request-approved-btn {
        color: var(--paradise-color-success) !important;
        background-color: var(--paradise-bg-success-subtle) !important;
        border-color: var(--paradise-bg-success-subtle) !important;
    }
    .request-rejected-btn {
        color: var(--paradise-color-danger) !important;
        background-color: var(--paradise-bg-danger-subtle) !important;
        border-color: var(--paradise-bg-danger-subtle) !important;
    }

    /* Timeline approvals styling */
    #sp_FormEmployee .timeline {
        display: flex;
        align-items: flex-start;
        justify-content: flex-start;
        position: relative;
        margin: var(--paradise-space-4) auto;
        max-width: max-content;
        overflow-x: auto;
        white-space: nowrap;
        gap: var(--paradise-space-3);
    }
    #sp_FormEmployee .timeline-step {
        text-align: center;
        position: relative;
        z-index: 2;
        display: inline-block;
        min-width: 120px;
    }
    #sp_FormEmployee .timeline-step .circle {
        width: 48px;
        height: 48px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto;
        color: #fff;
        font-weight: bold;
        position: relative;
        border: 2px solid var(--paradise-card-bg);
        box-shadow: var(--paradise-shadow-sm);
    }
    #sp_FormEmployee .text-status.blue { background-color: var(--paradise-bg-info-subtle); color: var(--paradise-color-info); }
    #sp_FormEmployee .text-status.gray { background-color: var(--paradise-bg-secondary-subtle); color: var(--paradise-text-muted); }
    #sp_FormEmployee .text-status.yellow { background-color: var(--paradise-bg-warning-subtle); color: var(--paradise-color-warning); }
    #sp_FormEmployee .text-status.green { background-color: var(--paradise-bg-success-subtle); color: var(--paradise-color-success); }
    #sp_FormEmployee .text-status.red { background-color: var(--paradise-bg-danger-subtle); color: var(--paradise-color-danger); }

    #sp_FormEmployee .timeline-step small {
        font-size: 11px;
        color: var(--paradise-text-muted);
    }
    #sp_FormEmployee .timeline-step .note {
        margin-top: var(--paradise-space-1);
        font-size: 12px;
        color: var(--paradise-text-body);
        line-height: 1.4;
        text-align: center;
        display: -webkit-box;
        -webkit-line-clamp: 3;
        -webkit-box-orient: vertical;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    #sp_FormEmployee .input-box {
        width: 47%;
    }

    /* File List Items */
    #sp_FormEmployee .hr-employee-item {
        display: flex;
        align-items: center;
        padding: var(--paradise-space-3);
        margin-bottom: var(--paradise-space-2);
        background-color: var(--paradise-bg-surface);
        border-radius: var(--paradise-border-radius-md);
        border: 1px solid var(--paradise-border-color);
        border-left: 4px solid var(--paradise-color-primary);
        box-shadow: var(--paradise-shadow-sm);
        transition: transform var(--paradise-transition-fast);
    }
    #sp_FormEmployee .hr-employee-item:hover {
        transform: translateX(4px);
    }
    #sp_FormEmployee .hr-badge {
        font-size: 15px;
    }
    #sp_FormEmployee .hr-employee-content {
        flex-grow: 1;
        margin-left: var(--paradise-space-3);
    }
    #sp_FormEmployee .hr-employee-name {
        font-size: 14px;
        font-weight: 500;
        color: var(--paradise-text-body);
    }
    #sp_FormEmployee .hr-employee-name.preview-image {
        color: var(--paradise-color-primary) !important;
        font-weight: 600;
        cursor: pointer;
    }
    #sp_FormEmployee .btn-remove-file {
        cursor: pointer;
        background-color: var(--paradise-bg-primary-subtle);
        color: var(--paradise-color-primary);
        padding: var(--paradise-space-1) var(--paradise-space-2);
        border-radius: var(--paradise-border-radius-sm);
    }

    /* Image Modal view */
    #sp_FormEmployee #leaveImageModal {
        background-color: rgba(0, 0, 0, 0.85);
    }
    @media (max-width: 991.98px) {
        #sp_FormEmployee .input-box {
            width: 100%;
        }
    }

    #sp_FormEmployee #leaveImageModal .modal-dialog {
        max-width: 95vw;
        width: 100%;
        margin: 0 auto;
        min-height: 100vh;
    }
    #sp_FormEmployee #leaveImageModal .modal-content {
        background-color: transparent;
        border: none;
    }
    #sp_FormEmployee #leaveImageModal .modal-body {
        padding: 10px;
        display: flex;
        justify-content: center;
        align-items: center;
        min-height: 100vh;
    }
    #sp_FormEmployee #leaveImageModal img {
        max-width: 100%;
        max-height: 80vh;
        border-radius: var(--paradise-border-radius-lg);
        box-shadow: var(--paradise-shadow-lg);
        object-fit: contain;
    }

    /* Mobile overrides */
    @media (max-width: 576px) {
        #sp_FormEmployee #leaveImageModal .modal-dialog {
            max-width: 100vw;
        }
        #sp_FormEmployee .history-card {
            flex-direction: column;
            align-items: flex-start;
        }
        #sp_FormEmployee .history-card .avatar-img,
        #sp_FormEmployee .history-card .fas.fa-user-circle {
            margin-bottom: 8px;
            margin-right: 0;
        }
        #sp_FormEmployee .history-card .info-section {
            flex-direction: column;
            align-items: flex-start;
        }
        #sp_FormEmployee .history-card .card-title {
            text-align: center;
            font-size: 16px;
            font-weight: 600;
        }
        #sp_FormEmployee .history-card .employee-id {
            font-size: 0.8rem;
        }
        #sp_FormEmployee .history-card .details-section {
            font-size: 0.8rem;
        }
        #sp_FormEmployee .history-card .status-container {
            text-align: left;
            margin-top: 8px;
        }
        #sp_FormEmployee .timeline-step small {
            font-size: 10px;
        }
        #sp_FormEmployee .timeline-step .note {
            font-size: 11px;
        }
        #sp_FormEmployee .action-buttons {
            flex-direction: column;
            align-items: center;
        }
        #sp_FormEmployee .employee-info {
            flex-direction: column;
            align-items: center;
        }
        #sp_FormEmployee .employee-info .avatar-container {
            margin-right: 0;
            margin-bottom: 15px;
        }
        #sp_FormEmployee .employee-info .info-container {
            padding-top: 5px;
            text-align: center;
        }
        #sp_FormEmployee .employee-info .info-container .fullname {
            padding-left: 0;
        }
        #sp_FormEmployee .employee-info .info-container .status {
            padding-left: 0;
        }
    }

    /* dxButton custom file chooser style */
    #sp_FormEmployee #qlbeta-customchosefileExpenses .dx-button {
        background-color: var(--paradise-color-primary) !important;
        color: var(--paradise-text-on-primary, #fff) !important;
        border-radius: var(--paradise-border-radius-pill) !important;
        padding: var(--paradise-space-2) var(--paradise-space-4) !important;
        font-size: 0.9rem !important;
        border: none !important;
    }

    /* Approver timeline styles */
    #container_approver .timeline {
        display: flex;
        align-items: flex-start;
        justify-content: flex-start;
        position: relative;
        margin: var(--paradise-space-4) auto;
        max-width: 100%;
        overflow-x: auto;
        white-space: nowrap;
        gap: var(--paradise-space-3);
    }
    #container_approver .timeline-step {
        text-align: center;
        position: relative;
        z-index: 2;
        display: inline-block;
        min-width: 120px;
    }
    #container_approver .timeline-step .circle {
        width: 48px;
        height: 48px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        margin: 0 auto;
        color: #fff;
        font-weight: bold;
        position: relative;
        border: 2px solid var(--paradise-card-bg);
        box-shadow: var(--paradise-shadow-sm);
    }
    #container_approver .timeline-step .circle.blue { background-color: var(--paradise-color-info); }
    #container_approver .timeline-step .circle.gray { background-color: var(--paradise-text-muted); }
    #container_approver .timeline-step .circle.yellow { background-color: var(--paradise-color-warning); }
    #container_approver .timeline-step .circle.green { background-color: var(--paradise-color-success); }
    #container_approver .timeline-step .circle.red { background-color: var(--paradise-color-danger); }

    #container_approver .timeline-step .circle img,
    #container_approver .timeline-step .circle i {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        object-fit: cover;
    }
    #container_approver .timeline-step .name {
        font-size: 12px;
        color: var(--paradise-text-body);
        margin-top: var(--paradise-space-2);
    }
    #container_approver .timeline-step .note {
        margin-top: var(--paradise-space-2);
        font-size: 13px;
        color: var(--paradise-text-muted);
        line-height: 1.5;
        text-align: center;
        display: -webkit-box;
        -webkit-line-clamp: 3;
        -webkit-box-orient: vertical;
        overflow: hidden;
        text-overflow: ellipsis;
    }

    .employeeid-badge-green {
        text-align: center;
        padding: 5px 10px;
        border-radius: 15px;
        font-weight: bold;
        background-color: var(--paradise-bg-success-subtle);
        color: var(--paradise-color-success);
    }
    #sp_FormEmployee .avatar-img {
        width: 56px;
        height: 56px;
    }

    /* Request CardList */
    .request-CardList .card {
        position: relative;
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        background-color: var(--paradise-card-bg) !important;
        border: 1px solid var(--paradise-border-color) !important;
        border-radius: var(--paradise-border-radius-md) !important;
        padding: var(--paradise-space-3) var(--paradise-space-4) !important;
        box-shadow: var(--paradise-shadow-sm) !important;
        margin-bottom: var(--paradise-space-3);
        cursor: pointer;
        transition: transform var(--paradise-transition-normal), box-shadow var(--paradise-transition-normal);
    }
    .request-CardList .card:hover {
        box-shadow: var(--paradise-shadow-md) !important;
        transform: translateY(-2px);
        border-color: var(--paradise-color-primary) !important;
    }
    .request-CardList {
        max-height: 900px;
        overflow-y: auto;
        padding-right: 8px;
    }
    .request-subtitle {
        font-size: 14px;
        font-weight: 400;
        line-height: 22px;
        color: var(--paradise-text-body);
    }
    .request-titleName {
        text-align: center;
        font-size: 16px;
        font-weight: 600;
        color: var(--paradise-text-body);
    }

    /* Action Buttons in GroupButton & Modals Override */
    #sp_FormEmployee .btnRegister,
    #sp_FormEmployee .btnApprove,
    #sp_FormEmployee .btnReject,
    #sp_FormEmployee .btnDestroy {
        border-radius: var(--paradise-border-radius-pill) !important;
        padding: var(--paradise-space-2) var(--paradise-space-4) !important;
        font-weight: 600 !important;
        transition: all var(--paradise-transition-fast) !important;
        border: 1px solid transparent !important;
    }
    #sp_FormEmployee .btnRegister,
    #sp_FormEmployee .btnApprove {
        background-color: var(--paradise-color-primary) !important;
        color: var(--paradise-text-on-primary, #fff) !important;
        border-color: var(--paradise-color-primary) !important;
    }
    #sp_FormEmployee .btnRegister:hover,
    #sp_FormEmployee .btnApprove:hover {
        opacity: 0.9 !important;
        transform: translateY(-1px);
    }
    #sp_FormEmployee .btnReject,
    #sp_FormEmployee .btnDestroy {
        background-color: var(--paradise-color-danger) !important;
        color: var(--paradise-text-on-danger, #fff) !important;
        border-color: var(--paradise-color-danger) !important;
    }
    #sp_FormEmployee .btnReject:hover,
    #sp_FormEmployee .btnDestroy:hover {
        opacity: 0.9 !important;
        transform: translateY(-1px);
    }

    /* Modal buttons styling */
    #sp_FormEmployee .modal-footer .btn {
        border-radius: var(--paradise-border-radius-pill) !important;
        padding: var(--paradise-space-2) var(--paradise-space-4) !important;
        font-weight: 600 !important;
    }
    #sp_FormEmployee .modal-footer .btn-success {
        background-color: var(--paradise-color-primary) !important;
        border-color: var(--paradise-color-primary) !important;
        color: var(--paradise-text-on-primary, #fff) !important;
    }
    #sp_FormEmployee .modal-footer .btn-secondary {
        background-color: var(--paradise-bg-surface) !important;
        border-color: var(--paradise-border-color) !important;
        color: var(--paradise-text-body) !important;
    }
</style>"""

# Restore mobile version: just CREATE OR ALTER and use original content
restore_mobile = re.sub(r"CREATE\s+procedure", "CREATE OR ALTER PROCEDURE", content, count=1, flags=re.IGNORECASE)

# New ResignationLeave layout content: replace CSS
new_resignation_leave = content[:style_start_idx] + new_css + content[style_end_idx + len("</style>"):]

# Modify procedure signature (line 1) to be sp_ResignationLeave_html
resignation_leave_lines = new_resignation_leave.splitlines(keepends=True)
resignation_leave_lines[0] = "CREATE OR ALTER PROCEDURE [dbo].[sp_ResignationLeave_html](@LoginID INT = 3, @LanguageID VARCHAR(2) = 'VN', @IdentityID varchar(36) = '')\n"
new_resignation_leave = "".join(resignation_leave_lines)

# Rename initsp_ResignationLeave_Mobile to initsp_ResignationLeave
new_resignation_leave = new_resignation_leave.replace("initsp_ResignationLeave_Mobile", "initsp_ResignationLeave")

# Let's prepend header and append cache refresh
header = """-- ============================================================================
-- File   : SQL script/update_menu_ResignationLeave_html_ParadiseStyle.sql
-- Mục đích: Khôi phục sp_ResignationLeave_Mobile về gốc và Thiết kế lại 
--          giao diện menu Xin Nghỉ phép sp_ResignationLeave theo chuẩn ParadiseStyle.
-- Cảnh báo: USER tự review và CHẠY. Agent KHÔNG tự động thực thi.
-- Idempotent: Có thể chạy nhiều lần; tự động dọn dẹp và nạp lại HTML cache.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
"""

wrapper_sql = """-- ============================================================================
-- Wrapper Procedure: sp_ResignationLeave (Desktop Menu MnuWPT315)
-- ============================================================================
CREATE OR ALTER PROCEDURE [dbo].[sp_ResignationLeave]
(
    @LoginID INT = 3,
    @LanguageID VARCHAR(2) = 'VN',
    @IdentityID varchar(36) = ''
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT html html FROM dbo.tblHtmlScriptCache WHERE LanguageID = @LanguageID AND ScreenType = -1 AND TableName = 'sp_ResignationLeave';
END;
"""

footer = """
-- ============================================================
-- REBUILD CACHE
-- ============================================================
DELETE FROM dbo.tblHtmlScriptCache WHERE TableName IN ('sp_ResignationLeave_Mobile', 'sp_ResignationLeave');
GO
EXEC dbo.sp_GenerateHTMLScript 'sp_ResignationLeave_Mobile';
EXEC dbo.sp_GenerateHTMLScript 'sp_ResignationLeave_html', @TableName = 'sp_ResignationLeave';
GO
PRINT 'Da refresh cache HTML thanh cong cho sp_ResignationLeave_Mobile va sp_ResignationLeave (MnuWPT315).';
GO

-- ============================================================
-- VERIFY
-- ============================================================
SELECT TableName, LanguageID, ScreenType,
       DATALENGTH(html) AS HtmlBytes, Version
FROM   dbo.tblHtmlScriptCache
WHERE  TableName IN ('sp_ResignationLeave_Mobile', 'sp_ResignationLeave')
ORDER  BY TableName, LanguageID;
GO
"""

final_sql = header + "\n" + restore_mobile + "\nGO\n\n" + new_resignation_leave + "\nGO\n\n" + wrapper_sql + "\nGO\n" + footer

# Write to output file
out_sql_path.parent.mkdir(parents=True, exist_ok=True)
out_sql_path.write_text(final_sql, encoding="utf-8-sig")

print("Successfully generated SQL script at:", out_sql_path)
print("Bytes written:", len(final_sql.encode('utf-8-sig')))
