-- =========================================================================
-- MIGRATION SCRIPT: TASK LIST MENU (MnuAT001)
-- FROM Vietinsoft_Pay TO Paradise_Dev
-- CREATED AT: 2026-05-23
-- =========================================================================

-- 1. Deploy Stored Procedures
GO
PRINT 'Deploying sp_Task_TaskList...'
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_Task_TaskList]
 @LoginID int = null,
 @LanguageID varchar(2) = 'VN'
AS
 select html from tblHtmlScriptCache where TableName = 'sp_Task_TaskList_html' and ScreenType = -1 and LanguageID = @LanguageID
GO

PRINT 'Deploying sp_Task_TaskTemplate_Approve...'
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_Task_TaskTemplate_Approve]
    @TemplateID INT,
    @ApprovalStatus INT, -- 1: Approved, 2: Rejected
    @LoginID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE tblTask_Templates SET
        ApprovalStatus = @ApprovalStatus
    WHERE SubTaskID = @TemplateID AND ParentTaskID = '0';

    DECLARE @Msg NVARCHAR(255) = CASE WHEN @ApprovalStatus = 1 THEN N'Đã duyệt template thành công' ELSE N'Đã từ chối template' END;
    SELECT 'SUCCESS' AS Status, @Msg AS Message;
END
GO

PRINT 'Deploying sp_Task_DataSource_Project...'
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_Task_DataSource_Project]
    @LoginID    NVARCHAR(100) = '',
    @LanguageID NVARCHAR(20)  = '',
    @SearchText NVARCHAR(255) = '',
    @Id         INT = NULL,
    @Skip       INT = 0,
    @Take       INT = 2000
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        ProjectID,
        ProjectName
    INTO #Filtered
    FROM tblTask_Projects
    WHERE
        (@Id IS NULL OR ProjectID = @Id)
        AND (@SearchText = '' OR ProjectName LIKE N'%' + @SearchText + N'%') AND IsActive = 1

    -- Result set 1: trang dữ liệu
    SELECT ProjectID, ProjectName
    FROM #Filtered
    ORDER BY ProjectID
    OFFSET @Skip ROWS FETCH NEXT @Take ROWS ONLY;

    -- Result set 2: tổng số record
    SELECT COUNT(*) AS TotalCount
    FROM #Filtered;

    DROP TABLE #Filtered;
END
GO

PRINT 'Deploying sp_Task_TaskTimeLine_CheckChange...'
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_Task_TaskTimeLine_CheckChange]
AS
BEGIN
    SET NOCOUNT ON;

    -- Đếm số lượng dòng gộp với mã Checksum toàn bảng để làm mã Hash 100% không thể nhầm lẫn
    SELECT CAST(COUNT(1) AS VARCHAR(20)) + '_' + CAST(ISNULL(CHECKSUM_AGG(BINARY_CHECKSUM(*)), 0) AS VARCHAR(50)) AS StateHash
    FROM tblTask_Tasks WITH (NOLOCK)
    WHERE ISNULL(StatusID, 0) NOT IN (4,6) AND DueDate IS NOT NULL
END
GO

PRINT 'Deploying sp_Task_TaskList_html...'
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_Task_TaskList_html]
@LoginID    INT = NULL,
@LanguageID VARCHAR(2) = 'VN',
@isWeb      INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    -- Trigger Recurring Tasks Generation (On Form Open)
    -- EXEC sp_Task_GenerateRecurringTasks;

DECLARE @html NVARCHAR(MAX);
SET @html = N'
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.10/main.min.css">
<script src="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.10/index.global.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/fullcalendar@6.1.10/locales/vi.global.min.js"></script>
<style>
    :root {
        /* TÔNG MÀU XANH LÁ - TÙY CHỈNH */
        --primary-color: #4a9e0f;
        --primary-bg: #e2f0d9;
        --primary-hover: #3d800c;
        --active-color: #004c39;
    }

    .dx-dropdowneditor-input-wrapper .dx-placeholder,
    .dx-tagbox .dx-placeholder {
        line-height: normal !important;
        padding-top: 6px !important;
    }

    .dx-list-item-selected,
    .dx-list-item-selected.dx-list-item-focused {
        background-color: #d1e7dd !important;
        color: #0f5132 !important;
        font-weight: 600 !important;
    }

    .dx-list-item-selected .dx-list-item-content {
        color: #0f5132 !important;
    }

    #sp_Task_TaskList_html {
        position: relative;
        z-index: 1;
        height: 100vh;
        display: flex;
        flex-direction: column;
        overflow: hidden;
        margin-bottom: 12px;
    }

    #sp_Task_TaskList_html .dx-widget {
        color: inherit !important;
    }

    #sp_Task_TaskList_html .dx-texteditor.dx-state-active::before,
    #sp_Task_TaskList_html .dx-texteditor.dx-state-focused::before {
        border-radius: inherit !important;
    }

    /* Thanh công cụ */
    #sp_Task_TaskList_html .task-toolbar {
        padding: 8px 8px 0;
        display: flex;
        justify-content: flex-end;
        align-items: center;
        gap: 8px;
    }

    /* --- KIỂU DÁNG CHUYỂN TAB MỚI --- */
    #sp_Task_TaskList_html .switcher-container {
        display: flex;
        justify-content: center;
        align-items: center;
        gap: 10px;
        width: fit-content;
        border-radius: 50px;
        border: 1px solid #e0e0e0;
        padding: 4px;
        position: relative;
    }

    #sp_Task_TaskList_html .tab-slider {
        position: absolute;
        border-radius: 40px;
        transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        height: calc(100% - 8px);
        top: 4px;
        z-index: 1;
        box-shadow: 0 2px 6px rgba(0, 0, 0, 0.15);
        pointer-events: none;
    }

    #sp_Task_TaskList_html .switcher-item {
        border-radius: 40px;
        padding: 6px 18px;
        font-size: 0.85rem;
        border: none;
        background: transparent;
        cursor: pointer;
        transition: color 0.3s ease;
        position: relative;
        z-index: 2;
        white-space: nowrap;
        font-weight: 600;
        display: inline-flex;
        align-items: center;
        justify-content: center;
    }

    #sp_Task_TaskList_html .switcher-item.active {
        color: #fff;
    }

    #sp_Task_TaskList_html #view-switcher .switcher-item {
        padding: 6px 12px;
        min-width: 40px;
    }

    #sp_Task_TaskList_html .btn-add-task {
        white-space: nowrap;
        border-radius: 20px;
        padding: 6px 18px;
        font-weight: 500;
        font-size: 0.9rem;
        border: none;
        box-shadow: 0 2px 4px rgba(74, 158, 15, 0.2);
        transition: background-color 0.2s;
    }

    #sp_Task_TaskList_html .btn-add-task:hover {
        opacity: 0.8;
    }

    /* Khung chứa */
    #sp_Task_TaskList_html #view-container {
        height: calc(100vh - 100px);
        overflow: hidden;
        display: flex;
        flex-direction: column;
        min-height: 0;
    }

    /* Toolbar bên trong view-container không được co lại */
    #sp_Task_TaskList_html .task-toolbar.grid-toolbar {
        flex-shrink: 0;
    }

    /* Search bar trong toolbar */
    #sp_Task_TaskList_html .ttv-search-wrap {
        position: relative;
        display: flex;
        align-items: center;
    }

    #sp_Task_TaskList_html .ttv-search-wrap .ttv-search-icon {
        position: absolute;
        left: 8px;
        color: #94a3b8;
        font-size: 0.8rem;
        pointer-events: none;
    }

    #sp_Task_TaskList_html .ttv-search-input {
        height: 32px;
        padding: 0 10px 0 28px;
        border: 1px solid var(--bs-border-color, #e2e8f0);
        border-radius: 6px;
        font-size: 0.875rem;
        width: 200px;
        background: var(--bs-body-bg, #fff);
        color: var(--bs-body-color, #1e293b);
        transition: border-color 0.15s, width 0.2s;
        outline: none;
    }

    #sp_Task_TaskList_html .ttv-search-input:focus {
        border-color: #4a9e0f;
        width: 260px;
        box-shadow: 0 0 0 3px rgba(74, 158, 15, 0.1);
    }

    #sp_Task_TaskList_html .ttv-search-input::placeholder {
        color: #94a3b8;
    }

    /* Reload button */
    #sp_Task_TaskList_html .btn-ttv-reload {
        height: 32px;
        width: 32px;
        display: flex;
        align-items: center;
        justify-content: center;
        border: 1px solid var(--bs-border-color, #e2e8f0);
        border-radius: 6px;
        background: var(--bs-body-bg, #fff);
        color: #64748b;
        cursor: pointer;
        transition: background 0.15s, color 0.15s, transform 0.2s;
        padding: 0;
    }

    #sp_Task_TaskList_html .btn-ttv-reload:hover {
        background: #f1f5f9;
        color: #4a9e0f;
    }

    #sp_Task_TaskList_html .btn-ttv-reload.spinning i {
        animation: ttvSpin 0.6s linear;
    }

    @keyframes ttvSpin {
        from {
            transform: rotate(0deg);
        }

        to {
            transform: rotate(360deg);
        }
    }

    /* --- GIAO DIỆN LỊCH (SCHEDULER) --- */
    #sp_Task_TaskList_html #scheduler-container {
        height: calc(100vh - 160px);
        border-radius: 12px;
        border: 1px solid var(--bs-border-color, #e2e8f0);
        overflow: hidden;
        box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
        background: var(--bs-body-bg, #fff);
    }

    /* Sao ưu tiên - Logic hover */
    #sp_Task_TaskList_html .star-container {
        display: inline-flex;
        gap: 2px;
    }

    #sp_Task_TaskList_html .priority-star,
    #sp_Task_TaskList_html .ttv-star {
        color: #d1d9e2;
        font-size: 0.9rem;
        cursor: default;
    }

    #sp_Task_TaskList_html .priority-star.active,
    #sp_Task_TaskList_html .ttv-star.active {
        color: #ffc107;
    }

    /* Thanh cuộn mảnh */
    ::-webkit-scrollbar {
        width: 4px;
        height: 4px;
    }

    ::-webkit-scrollbar-track {
        background: transparent;
    }

    ::-webkit-scrollbar-thumb {
        background: #cfd6da;
        border-radius: 2px;
    }

    ::-webkit-scrollbar-thumb:hover {
        background: #b6bdc1;
    }

    /* Firefox: make scrollbars thin and set colors */
    #sp_Task_TaskList_html,
    #sp_Task_TaskList_html * {
        scrollbar-width: thin;
        /* auto | thin | none */
        scrollbar-color: #8d8d8d transparent;
        /* thumb color, track color */
    }

    /* --- DRAWER (CREATE TASK) --- */
    #sp_Task_TaskList_html .custom-modal-overlay {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.55);
        z-index: 1200;
        display: flex;
        align-items: center;
        justify-content: flex-end;
        backdrop-filter: none !important;
        -webkit-backdrop-filter: none !important;
        opacity: 0;
        visibility: hidden;
        pointer-events: none;
        transition: opacity 0.3s ease, visibility 0.3s ease;
    }

    #sp_Task_TaskList_html .custom-modal-overlay.active {
        opacity: 1;
        visibility: visible;
        pointer-events: auto;
    }

    #sp_Task_TaskList_html .custom-modal-container {
        height: calc(100vh - 100px);
        will-change: auto;
        overflow: hidden;
        position: absolute;
        top: 0;
        bottom: 0;
        right: 0;
        width: 100%;
        max-width: 70vw;
        z-index: 2;
        box-shadow: -20px 0 60px rgba(0, 0, 0, 0.15);
        display: flex;
        flex-direction: column;
        transform: translateX(100%);
        transition: transform 0.5s ease;
    }

    #sp_Task_TaskList_html .custom-modal-overlay.active .custom-modal-container {
        transform: translateX(0);
    }

    #sp_Task_TaskList_html .custom-modal-header {
        padding: 16px 24px;
        border-bottom: 1px solid #f0f0f0;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }

    #sp_Task_TaskList_html .custom-modal-title {
        font-weight: 700;
        font-size: 1.4rem;
    }

    #sp_Task_TaskList_html .custom-modal-body {
        -webkit-overflow-scrolling: touch;
        padding: 0;
        flex-grow: 1;
        overflow: hidden;
        display: flex;
        min-height: 0;
    }

    #sp_Task_TaskList_html .modal-main-content {
        flex: 1;
        min-height: 0;
        padding: 12px 24px 0;
        overflow-y: auto;
        overflow-x: hidden;
        max-width: 100%;
    }

    #sp_Task_TaskList_html .modal-right-sidebar {
        width: 280px;
        border-left: 1px solid var(--bs-border-color, #555);
        padding: 16px;
        display: flex;
        flex-direction: column;
        gap: 8px;
    }

    #sp_Task_TaskList_html .custom-modal-footer {
        padding: 16px 24px;
        display: flex;
        justify-content: flex-end;
        gap: 12px;
        z-index: 2;
    }

    /* Thẻ thông tin công việc */
    #sp_Task_TaskList_html .task-info-grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 8px;
        margin-bottom: 8px;
    }

    #sp_Task_TaskList_html .task-info-card {
        padding: 8px;
        display: flex;
        align-items: flex-start;
        gap: 16px;
        transition: all 0.2s;
    }

    #sp_Task_TaskList_html .task-info-icon {
        width: 40px;
        height: 40px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.2rem;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
    }

    #sp_Task_TaskList_html .task-info-details {
        flex: 1;
    }

    #sp_Task_TaskList_html .task-info-label {
        font-size: 0.8rem;
        font-weight: 600;
        margin-bottom: 4px;
    }

    /* Form Controls Overrides */
    #sp_Task_TaskList_html .task-title-input {
        font-size: 1.8rem !important;
        font-weight: 700 !important;
        border: none !important;
        padding: 0 !important;
        margin-bottom: 8px;
    }

    #sp_Task_TaskList_html .task-title-input .dx-texteditor-input {
        padding: 0 !important;
    }

    #sp_Task_TaskList_html .link-action,
    #sp_Task_TaskList_html #trigger_dropzone_FileUrl {
        color: #3b82f6;
        font-size: 0.95rem;
        font-weight: 500;
        display: flex;
        align-items: center;
        gap: 2px;
        margin-top: 20px;
        cursor: pointer;
    }

    #sp_Task_TaskList_html .link-action:hover,
    #sp_Task_TaskList_html #trigger_dropzone_FileUrl:hover {
        color: #2563eb;
    }

    /* Hành động thanh bên */
    #sp_Task_TaskList_html .action-item-sidebar {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 10px 16px;
        border-radius: 10px;
        cursor: pointer;
        transition: all 0.2s;
        font-size: 0.9rem;
        font-weight: 600;
        background: rgba(var(--bs-primary-rgb), 0.04);
        border: 1px solid var(--bs-border-color);
        margin-bottom: 15px;
    }

    #sp_Task_TaskList_html .action-item-sidebar:hover {
        background: rgba(var(--bs-primary-rgb), 0.08);
        border-color: #4a9e0f;
        color: #4a9e0f;
        transform: translateY(-1px);
    }

    /* Responsive Modal Fixes */
    #sp_Task_TaskList_html .hpa-responsive .dx-popup-content {
        padding: 10px !important;
        overflow: auto !important;
        -webkit-overflow-scrolling: touch;
    }

    #sp_Task_TaskList_html .action-item-sidebar.active {
        background: rgba(74, 158, 15, 0.1) !important;
        border-color: #4a9e0f !important;
        color: #4a9e0f !important;
        box-shadow: 0 4px 12px rgba(74, 158, 15, 0.1);
    }

    #sp_Task_TaskList_html .action-item-sidebar i {
        font-size: 1.1rem;
        width: 20px;
    }

    #sp_Task_TaskList_html .btn-drawer-primary {
        border: none;
        padding: 10px 24px;
        border-radius: 10px;
        font-weight: 600;
        transition: all 0.2s;
        cursor: pointer;
    }

    #sp_Task_TaskList_html .btn-drawer-primary:hover {
        transform: translateY(-1px);
        box-shadow: 0 4px 12px rgba(34, 197, 94, 0.3);
    }

    #sp_Task_TaskList_html .btn-drawer-secondary {
        background: var(--bs-body-bg, #fff);
        color: var(--bs-body-color, #64748b);
        border: 1px solid var(--bs-border-color, #e2e8f0);
        padding: 10px 24px;
        border-radius: 10px;
        font-weight: 600;
        transition: all 0.2s;
        cursor: pointer;
    }

    #sp_Task_TaskList_html .btn-drawer-secondary:hover {
        background: var(--bs-tertiary-bg, #f8fafc);
    }


    /* Checklist Styling */
    #sp_Task_TaskList_html .checklist-section {
        margin-top: 24px;
        position: relative;
    }

    #sp_Task_TaskList_html .checklist-list {
        display: flex;
        flex-direction: column;
        gap: 4px;
    }

    #sp_Task_TaskList_html .checklist-item {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 10px 12px;
        border-radius: 10px;
        transition: all 0.2s;
        border: 1px solid #e2e8f0;
    }

    #sp_Task_TaskList_html .checklist-item:hover {
        border-color: #4a9e0f;
    }

    #sp_Task_TaskList_html .checklist-item.done .checklist-item-text {
        text-decoration: line-through;
        color: #94a3b8;
    }

    #sp_Task_TaskList_html .checklist-checkbox {
        width: 20px;
        height: 20px;
        border: 2px solid #cbd5e1;
        border-radius: 6px;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all 0.2s;
        flex-shrink: 0;
    }

    #sp_Task_TaskList_html .checklist-item.done .checklist-checkbox {
        background: #22c55e;
        border-color: #22c55e;
        color: #fff;
    }

    #sp_Task_TaskList_html .checklist-checkbox i {
        font-size: 12px;
        display: none;
    }

    #sp_Task_TaskList_html .checklist-item.done .checklist-checkbox i {
        display: block;
    }

    #sp_Task_TaskList_html .checklist-item-text {
        flex: 1;
        font-size: 0.95rem;
        border: none;
        background: transparent;
        padding: 4px 0;
        transition: all 0.2s;
        cursor: pointer;
    }

    #sp_Task_TaskList_html .checklist-item-text:focus {
        outline: none;
        color: #3b82f6;
    }

    #sp_Task_TaskList_html .checklist-item-actions {
        display: flex;
        gap: 8px;
        opacity: 0;
        transition: all 0.2s;
    }

    #sp_Task_TaskList_html .checklist-item:hover .checklist-item-actions {
        opacity: 1;
    }

    #sp_Task_TaskList_html .checklist-btn-delete {
        color: #94a3b8;
        cursor: pointer;
        font-size: 1.1rem;
    }

    #sp_Task_TaskList_html .checklist-btn-delete:hover {
        color: #ef4444;
    }

    #sp_Task_TaskList_html .checklist-add-box {
        margin-top: 12px;
        padding: 4px 12px;
        display: flex;
        align-items: center;
        gap: 12px;
        border-radius: 10px;
        border: 1px dashed #e2e8f0;
        transition: all 0.2s;
    }

    #sp_Task_TaskList_html .checklist-add-box:focus-within {
        border-style: solid;
        border-color: #3b82f6;
        box-shadow: 0 4px 12px rgba(59, 130, 246, 0.08);
    }

    #sp_Task_TaskList_html .checklist-add-input {
        flex: 1;
        border: none;
        background: transparent;
        padding: 10px 0;
        font-size: 0.95rem;
    }

    #sp_Task_TaskList_html .checklist-add-input:focus {
        outline: none;
    }

    #sp_Task_TaskList_html .checklist-add-input::placeholder {
        color: #94a3b8;
    }

    #sp_Task_TaskList_html .checklist-add-btn {
        color: #3b82f6;
        cursor: pointer;
        font-size: 1.2rem;
        display: flex;
        align-items: center;
        transition: transform 0.2s;
    }

    #sp_Task_TaskList_html .checklist-add-btn:hover {
        transform: scale(1.1);
    }

    /* Subtask List Styles - Modern Row Style */
    #sp_Task_TaskList_html .subtask-section {
        border-top: 1px solid var(--bs-border-color, #f0f0f0);
        padding: 24px 0;
    }

    #sp_Task_TaskList_html .subtask-row {
        display: flex !important;
        flex-direction: row !important;
        flex-wrap: nowrap;
        align-items: center !important;
        gap: 8px;
        padding: 10px 14px !important;
        border-bottom: 1px solid var(--bs-border-color-translucent, #f8fafc);
        transition: background 0.2s;
        border-radius: 8px;
    }

    #sp_Task_TaskList_html .subtask-row:hover {
        background: var(--bs-tertiary-bg, #f8fafc);
    }

    #sp_Task_TaskList_html .subtask-name {
        display: flex;
        flex: 1;
        font-size: 1rem;
        color: var(--bs-body-color, #1e293b);
        font-weight: 500;
    }

    #sp_Task_TaskList_html .subtask-actions {
        display: flex;
        gap: 10px;
    }

    #sp_Task_TaskList_html .subtask-icon-btn {
        width: 32px;
        height: 32px;
        border-radius: 50%;
        border: 1px solid #e2e8f0;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all 0.2s;
    }

    #sp_Task_TaskList_html .subtask-icon-btn:hover {
        border-color: #3b82f6;
        color: #3b82f6;
        background: #f0f7ff;
    }

    #sp_Task_TaskList_html .subtask-icon-btn:focus,
    #sp_Task_TaskList_html .subtask-icon-btn:focus-within {
        outline: none !important;
        box-shadow: 0 0 0 2px var(--bs-body-bg, #fff), 0 0 0 4px var(--primary-color) !important;
        z-index: 2;
    }

    #sp_Task_TaskList_html .subtask-item-wrapper.dragging {
        opacity: 0.5;
        transform: scale(0.98);
    }

    #sp_Task_TaskList_html .subtask-item-wrapper.drag-over {
        border-top: 2px solid #4a9e0f !important;
    }

    #sp_Task_TaskList_html .drag-handle {
        cursor: grab;
        padding: 4px 8px;
        color: #94a3b8;
        transition: color 0.2s;
        margin-right: 4px;
    }

    #sp_Task_TaskList_html .drag-handle:hover {
        color: #4a9e0f;
    }

    #sp_Task_TaskList_html .drag-handle:active {
        cursor: grabbing;
    }

    /* ===== FIX: Subtask Detail Form - CSS Grid layout ===== */
    #sp_Task_TaskList_html .subtask-detail-form {
        background: var(--bs-tertiary-bg, #f8fafc);
        border: 1px solid var(--bs-border-color, #e2e8f0);
        border-top: none;
        border-radius: 0 0 10px 10px;
        padding: 14px 16px;
        margin: -2px 0 4px 0;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .subtask-detail-form {
        background: rgba(255, 255, 255, 0.03);
        border-color: rgba(255, 255, 255, 0.1);
    }

    #sp_Task_TaskList_html .subtask-detail-grid {
        display: grid;
        grid-template-columns: 1fr 130px auto;
        gap: 12px;
        align-items: end;
    }

    #sp_Task_TaskList_html .subtask-detail-label {
        font-size: 0.7rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.04em;
        color: #94a3b8;
        margin-bottom: 6px;
        display: flex;
        align-items: center;
        gap: 4px;
    }

    #sp_Task_TaskList_html .subtask-detail-actions {
        display: flex;
        gap: 6px;
        align-items: flex-end;
        padding-bottom: 2px;
    }

    #sp_Task_TaskList_html .btn-subtask-save {
        height: 36px;
        padding: 0 14px;
        border-radius: 8px;
        background: var(--primary-color, #4a9e0f);
        color: #fff;
        border: none;
        font-weight: 600;
        font-size: 0.82rem;
        display: flex;
        align-items: center;
        gap: 5px;
        cursor: pointer;
        transition: all 0.15s;
        white-space: nowrap;
    }

    #sp_Task_TaskList_html .btn-subtask-save:hover {
        opacity: 0.85;
        transform: translateY(-1px);
    }

    #sp_Task_TaskList_html .btn-subtask-save:focus,
    #sp_Task_TaskList_html .btn-subtask-save:focus-visible {
        outline: none;
        box-shadow: 0 0 0 2px var(--bs-body-bg, #fff), 0 0 0 4px var(--primary-color, #4a9e0f) !important;
    }

    #sp_Task_TaskList_html .btn-subtask-cancel {
        height: 36px;
        padding: 0 12px;
        border-radius: 8px;
        background: var(--bs-body-bg, #fff);
        color: var(--bs-body-color, #64748b);
        border: 1px solid var(--bs-border-color, #e2e8f0);
        font-weight: 600;
        font-size: 0.82rem;
        cursor: pointer;
        transition: background 0.15s;
        white-space: nowrap;
    }

    #sp_Task_TaskList_html .btn-subtask-cancel:hover {
        background: var(--bs-tertiary-bg, #f1f5f9);
    }

    #sp_Task_TaskList_html .btn-subtask-cancel:focus,
    #sp_Task_TaskList_html .btn-subtask-cancel:focus-visible {
        outline: none;
        box-shadow: 0 0 0 2px var(--bs-body-bg, #fff), 0 0 0 4px #64748b !important;
    }

    /* ===== RESPONSIVE: Subtask detail on mobile ===== */
    @media (max-width: 1024px) {
        #sp_Task_TaskList_html .subtask-detail-grid {
            grid-template-columns: 1fr;
            gap: 10px;
        }

        #sp_Task_TaskList_html .subtask-detail-actions {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 8px;
            padding-bottom: 0;
        }

        #sp_Task_TaskList_html .btn-subtask-save,
        #sp_Task_TaskList_html .btn-subtask-cancel {
            justify-content: center;
            height: 40px;
            width: 100%;
        }

        #sp_Task_TaskList_html .subtask-row {
            flex-wrap: wrap !important;
            gap: 8px;
            padding: 12px !important;
        }
    }

    #sp_Task_TaskList_html #P63128D34B83D4F9EA7BEB928C35C7CF7 .dx-texteditor-input,
    #sp_Task_TaskList_html #P63128D34B83D4F9EA7BEB928C35C7CF7 .dx-placeholder {
        font-size: 1.8rem !important;
        line-height: 1.2 !important;
    }

    /* Đảm bảo tất cả placeholder & input trên form đều có line-height chuẩn để không bị vỡ trên iOS */
    #sp_Task_TaskList_html .dx-placeholder,
    #sp_Task_TaskList_html .dx-texteditor-input {
        line-height: 1.2 !important;
    }

    #sp_Task_TaskList_html .task-info-details .dx-placeholder {
        font-size: 0.95rem !important;
    }

    /* --- MÀN HÌNH CHỜ (SKELETON) --- */
    #sp_Task_TaskList_html .skeleton-loading {
        background: rgba(var(--bs-body-color-rgb), 0.08);
        background-image: linear-gradient(90deg,
                rgba(var(--bs-body-color-rgb), 0) 0%,
                rgba(var(--bs-body-color-rgb), 0.04) 50%,
                rgba(var(--bs-body-color-rgb), 0) 100%);
        background-repeat: no-repeat;
        background-size: 200% 100%;
        display: inline-block;
        position: relative;
        animation: shimmer 1.5s infinite linear;
        border-radius: 4px;
    }

    @keyframes shimmer {
        0% {
            background-position: 200% 0;
        }

        100% {
            background-position: -200% 0;
        }
    }

    #sp_Task_TaskList_html .skeleton-row {
        height: 60px;
        width: 100%;
        margin-bottom: 12px;
        border-radius: 8px;
    }

    /* ===== TREE VIEW KIỂU JIRA / LINEAR ===== */
    #sp_Task_TaskList_html #grid-wrapper {
        flex: 1;
        overflow: hidden;
        display: flex;
        flex-direction: column;
        min-height: 0;
    }

    #sp_Task_TaskList_html .ttv-wrap {
        flex: 1;
        min-height: 0;
        display: flex;
        flex-direction: column;
        overflow: hidden;
        border: 1px solid var(--bs-border-color, #e2e8f0);
        border-radius: 8px;
        background: var(--bs-body-bg, #fff);
    }

    #sp_Task_TaskList_html .ttv-body {
        flex: 1;
        position: relative;
        scrollbar-gutter: stable;
        overflow-y: auto;
        overflow-x: hidden;
        min-height: 0;
    }

    /* Header */
    #sp_Task_TaskList_html .ttv-header {
        display: grid;
        grid-template-columns: 32px 64px minmax(300px, 1fr) 110px 100px 100px 120px 125px 125px 125px 80px 64px;
        align-items: center;
        padding: 0 8px;
        height: 42px;
        background: var(--bs-tertiary-bg, #f8fafc);
        border-bottom: 2px solid var(--bs-border-color, #e2e8f0);
        flex-shrink: 0;
        scrollbar-gutter: stable;
    }

    #sp_Task_TaskList_html .ttv-header-cell {
        font-size: 0.75rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.04em;
        color: #94a3b8;
        padding: 0 5px;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        user-select: none;
        cursor: default;
        display: flex;
        align-items: center;
        gap: 3px;
    }

    #sp_Task_TaskList_html .ttv-header-cell.sortable {
        cursor: pointer;
    }

    #sp_Task_TaskList_html .ttv-header-cell.sortable:hover {
        color: #475569;
    }

    #sp_Task_TaskList_html .ttv-header-cell.sorted {
        color: #4a9e0f;
    }

    #sp_Task_TaskList_html .ttv-sort-icon {
        font-size: 1rem;
        flex-shrink: 0;
    }

    #sp_Task_TaskList_html .ttv-header-cell:last-child {
        text-align: right;
    }

    /* Task row */
    #sp_Task_TaskList_html .ttv-row {
        display: grid;

        grid-template-columns: 32px 64px minmax(300px, 1fr) 110px 100px 100px 120px 125px 125px 125px 80px 64px;
        align-items: center;
        padding: 0 8px;
        min-height: 42px;
        border-bottom: 1px solid var(--bs-border-color-translucent, #f1f5f9);
        transition: background 0.12s;
        cursor: pointer;
        position: relative;
    }

    #sp_Task_TaskList_html .ttv-row:hover {
        background: rgba(74, 158, 15, 0.04);
    }

    /* Overdue row */
    #sp_Task_TaskList_html .ttv-row.overdue {
        background: rgba(239, 68, 68, 0.06);
    }

    #sp_Task_TaskList_html .ttv-row.overdue:hover {
        background: rgba(239, 68, 68, 0.12);
    }

    #sp_Task_TaskList_html .ttv-row.today {
        background: rgba(245, 158, 11, 0.07);
    }

    #sp_Task_TaskList_html .ttv-row.today:hover {
        background: rgba(245, 158, 11, 0.14);
    }

    #sp_Task_TaskList_html .ttv-row.ttv-subtask {
        background: transparent;
    }

    #sp_Task_TaskList_html .ttv-row.ttv-subtask.overdue {
        background: rgba(239, 68, 68, 0.06);
    }

    #sp_Task_TaskList_html .ttv-row.ttv-subtask.overdue:hover {
        background: rgba(239, 68, 68, 0.12);
    }

    #sp_Task_TaskList_html .ttv-row.ttv-subtask.today {
        background: rgba(245, 158, 11, 0.07);
    }

    #sp_Task_TaskList_html .ttv-row.ttv-subtask:hover {
        background: rgba(74, 158, 15, 0.05);
    }

    /* Toggle / indent */
    #sp_Task_TaskList_html .ttv-toggle {
        display: flex;
        align-items: center;
        justify-content: center;
        width: 24px;
        height: 24px;
        border-radius: 4px;
        border: none;
        background: transparent;
        cursor: pointer;
        color: #94a3b8;
        font-size: 1rem;
        transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
        flex-shrink: 0;
    }

    #sp_Task_TaskList_html .ttv-toggle:hover {
        background: var(--bs-border-color, #e2e8f0);
        color: #475569;
    }

    #sp_Task_TaskList_html .ttv-toggle.expanded {
        transform: rotate(90deg);
        color: var(--primary-color);
    }

    /* Name cell */
    #sp_Task_TaskList_html .ttv-name-cell {
        display: flex;
        align-items: center;
        gap: 5px;
        padding: 0 5px;
        overflow: hidden;
    }

    #sp_Task_TaskList_html .ttv-indent-line {
        width: 1px;
        align-self: stretch;
        background: var(--bs-border-color, #e2e8f0);
        flex-shrink: 0;
        margin-left: 6px;
        margin-right: 2px;
    }

    #sp_Task_TaskList_html .ttv-task-icon {
        font-size: 1rem;
        flex-shrink: 0;
    }

    #sp_Task_TaskList_html .ttv-task-icon.parent {
        color: #4a9e0f;
    }

    #sp_Task_TaskList_html .ttv-task-icon.sub {
        color: #94a3b8;
        font-size: 0.9rem;
    }

    #sp_Task_TaskList_html .ttv-task-name {
        font-size: 1rem;
        font-weight: 500;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        flex: 1;
        color: inherit;
    }

    #sp_Task_TaskList_html .ttv-row:hover .ttv-task-name {
        color: #4a9e0f;
    }

    #sp_Task_TaskList_html .ttv-subtask-count {
        display: inline-flex;
        align-items: center;
        background: rgba(74, 158, 15, 0.08);
        color: #4a9e0f;
        padding: 1px 6px;
        border-radius: 4px;
        font-size: 0.78rem;
        font-weight: 700;
        gap: 4px;
        flex-shrink: 0;
        white-space: nowrap;
    }

    #sp_Task_TaskList_html .ttv-subtask-count i {
        font-size: 1rem;
    }

    /* Skeleton rows for tree view */
    #sp_Task_TaskList_html .ttv-skeleton-row {
        display: grid;
        grid-template-columns: 32px 64px minmax(300px, 1fr) 110px 100px 100px 120px 125px 125px 80px 64px;
        align-items: center;
        padding: 0 8px;
        height: 42px;
        border-bottom: 2px solid var(--bs-border-color-translucent, #f1f5f9);
    }

    #sp_Task_TaskList_html .ttv-skeleton-row .sk-icon {
        width: 16px;
        height: 16px;
        border-radius: 4px;
    }

    #sp_Task_TaskList_html .ttv-skeleton-row .sk-name {
        height: 10px;
        border-radius: 4px;
    }

    #sp_Task_TaskList_html .ttv-skeleton-row .sk-badge {
        width: 70%;
        height: 10px;
        border-radius: 10px;
    }

    #sp_Task_TaskList_html .ttv-skeleton-row .sk-avatar {
        width: 20px;
        height: 20px;
        border-radius: 50%;
    }

    #sp_Task_TaskList_html .ttv-skeleton-row .sk-date {
        width: 65%;
        height: 10px;
        border-radius: 4px;
    }

    #sp_Task_TaskList_html .ttv-skeleton-row .sk-pri {
        width: 40px;
        height: 10px;
        border-radius: 4px;
    }

    /* Cell : Assignee */
    #sp_Task_TaskList_html .ttv-assignee-cell {
        padding: 0 5px;
        display: flex;
        align-items: center;
        overflow: hidden;
    }

    #sp_Task_TaskList_html .ttv-avatar-group {
        display: flex;
        align-items: center;
    }

    #sp_Task_TaskList_html .ttv-avatar {
        width: 34px;
        height: 34px;
        border-radius: 50%;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 0.7rem;
        border: 2px solid var(--bs-body-bg, #fff);
        flex-shrink: 0;
        overflow: hidden;
        background: #dbeafe;
        color: #1d4ed8;
        margin-left: -12px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.12);
        position: relative;
    }

    #sp_Task_TaskList_html .ttv-avatar:first-child {
        margin-left: 0;
    }

    #sp_Task_TaskList_html .ttv-avatar img {
        width: 100%;
        height: 100%;
        object-fit: cover;
        display: block;
    }

    #sp_Task_TaskList_html .ttv-avatar-more {
        font-size: 0.65rem;
        font-weight: 700;
        background: var(--bs-tertiary-bg, #f1f5f9);
        color: #64748b;
        border: 2px solid var(--bs-body-bg, #fff);
    }

    /* Cell: ID (HistoryID) */
    #sp_Task_TaskList_html .ttv-id-cell {
        padding: 0 5px;
        font-size: 0.8rem;
        color: #94a3b8;
        white-space: nowrap;
        font-variant-numeric: tabular-nums;
    }

    /* Cell: Status badge */
    #sp_Task_TaskList_html .ttv-status-cell {
        padding: 0 5px;
    }

    #sp_Task_TaskList_html .ttv-status-badge {
        display: inline-flex;
        align-items: center;
        justify-content: center;
        white-space: nowrap;
        max-width: 130px;
        overflow: hidden;
        text-overflow: ellipsis;
        text-transform: uppercase;
        letter-spacing: 0.02em;
        font-size: 0.7rem;
        font-weight: 500;
        vertical-align: middle;
    }

    #sp_Task_TaskList_html .ttv-status-badge i {
        font-size: 1rem;
    }

    /* Cell: DueDate / AssignDate */
    #sp_Task_TaskList_html .ttv-date-cell {
        padding: 0 5px;
        font-size: 0.875rem;
        color: #64748b;
        white-space: nowrap;
        line-height: 1.3;
    }

    #sp_Task_TaskList_html .ttv-date-cell .ttv-date-main {
        display: block;
    }

    #sp_Task_TaskList_html .ttv-date-cell .ttv-date-time {
        display: block;
        font-size: 0.75rem;
        color: var(--paradise-color-secondary, #94a3b8);
    }

    #sp_Task_TaskList_html .ttv-date-cell.overdue .ttv-date-main {
        color: var(--paradise-color-important, #ef4444);
        font-weight: 600;
    }

    #sp_Task_TaskList_html .ttv-date-cell.today .ttv-date-main {
        color: var(--paradise-color-warning, #f59e0b);
        font-weight: 600;
    }

    /* Cell: Priority stars (Shared styles applied) */
    #sp_Task_TaskList_html .ttv-priority-cell {
        padding: 0 5px;
        display: flex;
        align-items: center;
        gap: 2px;
    }

    /* Cell: Actions */
    #sp_Task_TaskList_html .ttv-actions-cell {
        padding: 0 3px;
        display: flex;
        align-items: center;
        justify-content: flex-end;
        gap: 2px;
        opacity: 0;
        transition: opacity 0.12s;
    }

    #sp_Task_TaskList_html .ttv-row:hover .ttv-actions-cell {
        opacity: 1;
    }

    #sp_Task_TaskList_html .ttv-btn-action {
        width: 28px;
        height: 28px;
        display: flex;
        align-items: center;
        justify-content: center;
        border-radius: 6px;
        border: none;
        background: transparent;
        color: #64748b;
        font-size: 1rem;
        cursor: pointer;
        transition: all 0.15s;
    }

    #sp_Task_TaskList_html .ttv-btn-action:hover {
        background: var(--bs-tertiary-bg, #f1f5f9);
        color: #1e293b;
    }

    #sp_Task_TaskList_html .ttv-btn-action.add {
        color: #4a9e0f;
    }

    #sp_Task_TaskList_html .ttv-btn-action.add:hover {
        background: #dcfce7;
    }

    /* Empty state */
    #sp_Task_TaskList_html .ttv-empty {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 60px 20px;
        text-align: center;
        color: #94a3b8;
        gap: 12px;
    }

    #sp_Task_TaskList_html .ttv-empty i {
        font-size: 2.5rem;
        opacity: 0.4;
    }

    #sp_Task_TaskList_html .ttv-empty p {
        font-size: 0.9rem;
        margin: 0;
    }

    /* Pagination */
    #sp_Task_TaskList_html .ttv-pagination {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 8px 12px;
        border-top: 1px solid var(--bs-border-color, #e2e8f0);
        background: var(--bs-tertiary-bg, #f8fafc);
        border-radius: 0 0 8px 8px;
        flex-shrink: 0;
    }

    #sp_Task_TaskList_html .ttv-page-size {
        font-size: 0.75rem;
        color: #94a3b8;
    }

    #sp_Task_TaskList_html .ttv-page-info {
        font-size: 0.75rem;
        color: #94a3b8;
    }

    /* Search highlight */
    #sp_Task_TaskList_html .ttv-task-name mark {
        background: rgba(251, 191, 36, 0.3);
        color: inherit;
        border-radius: 2px;
        padding: 0 1px;
    }

    /* Dark mode */
    [data-bs-theme="dark"] #sp_Task_TaskList_html .ttv-wrap {
        border-color: rgba(255, 255, 255, 0.1);
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .ttv-header {
        background: rgba(255, 255, 255, 0.04);
        border-bottom-color: rgba(255, 255, 255, 0.1);
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .ttv-row {
        border-bottom-color: rgba(255, 255, 255, 0.06);
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .ttv-row.ttv-subtask {
        background: rgba(255, 255, 255, 0.02);
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .ttv-btn-action {
        background: rgba(255, 255, 255, 0.05);
        border-color: rgba(255, 255, 255, 0.12);
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .ttv-subtask-count {
        background: rgba(255, 255, 255, 0.1);
        color: #cbd5e1;
    }

    /* DevExtreme Underlined Overrides */
    #sp_Task_TaskList_html .dx-editor-underlined::after {
        border-bottom-color: var(--bs-border-color) !important;
    }

    #sp_Task_TaskList_html .dx-editor-underlined.dx-state-focused::after {
        border-bottom-color: #4a9e0f !important;
        border-bottom-width: 2px !important;
    }

    #sp_Task_TaskList_html .dx-editor-underlined .dx-texteditor-input {
        background: transparent !important;
        padding: 8px 0px !important;
        color: inherit !important;
        width: 100%;
    }

    #sp_Task_TaskList_html .dx-editor-underlined.dx-state-hover::after {
        border-bottom-color: #4a9e0f !important;
    }

    /* flatpickr Input Styling */
    #sp_Task_TaskList_html .flatpickr-input.form-control {
        border: none !important;
        border-bottom: 1px solid var(--bs-border-color) !important;
        border-radius: 0 !important;
        padding: 8px 0 !important;
        background: transparent !important;
        box-shadow: none !important;
        font-size: 0.95rem;
    }

    #sp_Task_TaskList_html .flatpickr-input.form-control:focus {
        border-bottom-color: var(--primary-color) !important;
    }

    /* FullCalendar Customizations */
    #sp_Task_TaskList_html .fc {
        border-radius: 12px;
        overflow: hidden;
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.05);
        font-family: inherit;
        background: transparent !important;
        color: inherit !important;
    }

    #sp_Task_TaskList_html .fc-header-toolbar {
        padding: 10px 15px !important;
        margin-bottom: 0 !important;
        border-bottom: 1px solid #eee;
        display: flex !important;
        align-items: center !important;
    }

    #sp_Task_TaskList_html .fc-toolbar-chunk {
        display: flex !important;
        align-items: center !important;
        gap: 10px;
    }

    #sp_Task_TaskList_html #calendar-view-options-group {
        margin: 0 !important;
    }

    #sp_Task_TaskList_html #calendar-view-options-group .switcher-container {
        background: rgba(var(--bs-body-color-rgb), 0.03);
        border-color: rgba(var(--bs-body-color-rgb), 0.1);
    }

    #sp_Task_TaskList_html .fc-toolbar-title {
        font-size: 1.25rem !important;
        font-weight: 800 !important;
        color: var(--active-color);
        letter-spacing: -0.02em;
    }

    #sp_Task_TaskList_html .fc-event {
        border: none !important;
        padding: 4px 8px !important;
        border-radius: 8px !important;
        cursor: pointer;
        transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
        font-weight: 600 !important;
        font-size: 0.85rem !important;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.04) !important;
        margin: 1px 2px !important;
    }

    #sp_Task_TaskList_html .fc-event:hover {
        transform: translateY(-1px);
        box-shadow: 0 6px 15px rgba(0, 0, 0, 0.1) !important;
        z-index: 10 !important;
    }

    #sp_Task_TaskList_html .fc-daygrid-event {
        white-space: normal !important;
    }

    #sp_Task_TaskList_html .fc-event-main,
    #sp_Task_TaskList_html .fc-event-title,
    #sp_Task_TaskList_html .fc-event-time {
        color: inherit !important;
    }

    #sp_Task_TaskList_html .fc-event {
        --fc-event-text-color: inherit;
    }

    /* High Priority - Soft Red */
    #sp_Task_TaskList_html .event-prio-1 {
        background-color: #fff1f0 !important;
        color: #cf1322 !important;
        border-left: 4px solid #ff4d4f !important;
    }

    /* Medium Priority - Soft Orange */
    #sp_Task_TaskList_html .event-prio-2 {
        background-color: #fff7e6 !important;
        color: #d46b08 !important;
        border-left: 4px solid #ffa940 !important;
    }

    /* Low Priority - Soft Green */
    #sp_Task_TaskList_html .event-prio-3 {
        background-color: #f6ffed !important;
        color: #389e0d !important;
        border-left: 4px solid #52c41a !important;
    }

    /* Calendar Grid Styling */
    #sp_Task_TaskList_html .fc-theme-standard td,
    #sp_Task_TaskList_html .fc-theme-standard th {
        border: 1px solid #f0f0f0 !important;
    }

    #sp_Task_TaskList_html .fc-col-header-cell {
        background: var(--bs-body-bg, #fafafa);
        padding: 10px 0 !important;
    }

    #sp_Task_TaskList_html .fc-col-header-cell-cushion {
        font-weight: 700 !important;
        text-decoration: none;
        text-transform: uppercase;
        font-size: 0.75rem;
        letter-spacing: 0.05em;
        color: var(--bs-body-color, #1e293b);
    }

    #sp_Task_TaskList_html .fc-day-today {
        background: rgba(74, 158, 15, 0.03) !important;
    }

    /* --- TASK PREVIEW POPOVER --- */
    #task-preview-popover {
        position: fixed;
        z-index: 9999;
        width: 300px;
        background: var(--bs-body-bg, #fff);
        border: 1px solid var(--bs-border-color, #e2e8f0);
        border-radius: 12px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
        padding: 16px;
        display: none;
        flex-direction: column;
        gap: 12px;
        animation: popIn 0.2s ease;
    }

    [data-bs-theme="dark"] #task-preview-popover {
        background: #1e293b;
        border-color: #334155;
        box-shadow: 0 10px 40px rgba(0, 0, 0, 0.4);
        color: #f1f5f9;
    }

    @keyframes popIn {
        from {
            opacity: 0;
            transform: scale(0.95) translateY(5px);
        }

        to {
            opacity: 1;
            transform: scale(1) translateY(0);
        }
    }

    .preview-header {
        display: flex;
        align-items: flex-start;
        justify-content: space-between;
        gap: 8px;
    }

    .preview-title {
        font-size: 1.05rem;
        font-weight: 700;
        margin: 0;
        line-height: 1.4;
        color: var(--active-color);
    }

    [data-bs-theme="dark"] .preview-title {
        color: #fff;
    }

    .preview-close {
        background: none;
        border: none;
        padding: 0;
        color: #94a3b8;
        cursor: pointer;
        font-size: 1.2rem;
        line-height: 1;
    }

    .preview-close:hover {
        color: #ef4444;
    }

    .preview-body {
        font-size: 0.88rem;
        display: flex;
        flex-direction: column;
        gap: 10px;
    }

    .preview-info-item {
        display: flex;
        align-items: center;
        gap: 10px;
        color: #64748b;
    }

    [data-bs-theme="dark"] .preview-info-item {
        color: #94a3b8;
    }

    .preview-info-item i {
        font-size: 0.95rem;
        min-width: 18px;
        color: var(--primary-color);
    }

    .preview-footer {
        border-top: 1px solid #f1f5f9;
        padding-top: 12px;
        margin-top: 4px;
    }

    [data-bs-theme="dark"] .preview-footer {
        border-top-color: #334155;
    }

    .btn-preview-detail {
        width: 100%;
        border-radius: 8px;
        padding: 10px;
        font-weight: 700;
        font-size: 0.9rem;
        border: none;
        background: var(--primary-color);
        color: #fff;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
    }

    .btn-preview-detail:hover {
        background: var(--primary-hover);
        transform: translateY(-1px);
        box-shadow: 0 4px 12px rgba(74, 158, 15, 0.2);
    }

    /* Grid toolbar styling to align with grid search */
    #sp_Task_TaskList_html .grid-toolbar {
        padding: 6px 8px;
    }

    /* Collapsible responsive toolbar overlay */
    #sp_Task_TaskList_html .toolbar-toggle {
        display: none;
        align-items: center;
        justify-content: center;
        width: 44px;
        height: 44px;
        border-radius: 8px;
        border: 1px solid rgba(0, 0, 0, 0.06);
        background: var(--primary-bg, #fff);
        cursor: pointer;
        box-shadow: 0 6px 18px rgba(0, 0, 0, 0.06);
    }

    #sp_Task_TaskList_html .filter-pill-wrap {
        position: relative;
    }

    #sp_Task_TaskList_html .filter-pill-btn {
        display: inline-flex;
        align-items: center;
        gap: 2px;
        border-radius: 50px;
        padding: 10px 14px;
        font-size: 0.85rem;
        font-weight: 600;
        border: 1px solid #e0e0e0;
        background: rgba(255, 255, 255, 0.05);
        cursor: pointer;
        transition: all 0.2s;
        white-space: nowrap;
        color: inherit;
    }

    #sp_Task_TaskList_html .filter-pill-btn:hover {
        border-color: var(--primary-color);
        color: var(--primary-color);
        background: var(--primary-bg);
    }

    #sp_Task_TaskList_html .filter-pill-btn.active {
        background: var(--primary-color);
        border-color: var(--primary-color);
        color: #fff;
        box-shadow: 0 2px 8px rgba(74, 158, 15, 0.25);
    }

    #sp_Task_TaskList_html .filter-pill-btn .bi-chevron-down {
        transition: transform 0.2s;
    }

    #sp_Task_TaskList_html .filter-pill-btn.open .bi-chevron-down {
        transform: rotate(180deg);
    }

    #sp_Task_TaskList_html .fpd-filter-count {
        font-size: 0.8rem;
        font-weight: 700;
        margin: 0 2px;
        color: var(--primary-color);
    }

    #sp_Task_TaskList_html .filter-pill-btn.active .fpd-filter-count {
        color: #fff;
    }

    #sp_Task_TaskList_html .filter-pill-dropdown {
        display: none;
        position: absolute;
        top: calc(100% + 8px);
        left: auto;
        right: 0;
        width: 480px;
        max-width: calc(100vw - 32px);
        border: 1px solid #e5e7eb;
        border-radius: 16px;
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.14);
        z-index: 1000;
        overflow: hidden;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .filter-pill-dropdown {
        background: #1e293b;
        border-color: #334155;
    }

    #sp_Task_TaskList_html .filter-pill-dropdown.show {
        display: block;
    }

    @keyframes pillDropIn {
        from {
            opacity: 0;
            transform: translateY(-8px) scale(0.97);
        }

        to {
            opacity: 1;
            transform: translateY(0) scale(1);
        }
    }

    /* Section */
    #sp_Task_TaskList_html .fpd-section {
        padding: 10px 14px;
        border-bottom: 1px solid #f1f5f9;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .fpd-section {
        border-bottom-color: #334155;
    }

    #sp_Task_TaskList_html .fpd-section:last-child {
        border-bottom: none;
    }

    #sp_Task_TaskList_html .fpd-label {
        font-size: 0.68rem;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 0.07em;
        color: #94a3b8;
        margin-bottom: 8px;
        display: flex;
        align-items: center;
        gap: 6px;
    }

    /* Pill options (Status, Tag, DueDate) */
    #sp_Task_TaskList_html .fpd-options {
        display: flex;
        flex-wrap: wrap;
        gap: 6px;
    }

    #sp_Task_TaskList_html .fpd-option {
        padding: 4px 11px;
        border-radius: 20px;
        font-size: 0.78rem;
        font-weight: 500;
        border: 1px solid #e5e7eb;
        cursor: pointer;
        transition: all 0.15s;
        background: transparent;
        white-space: nowrap;
        color: inherit;
        display: inline-flex;
        align-items: center;
        gap: 4px;
    }

    #sp_Task_TaskList_html .fpd-option:hover {
        border-color: var(--primary-color);
        color: var(--primary-color);
        background: var(--primary-bg);
    }

    #sp_Task_TaskList_html .fpd-option.selected {
        background: var(--primary-color);
        border-color: var(--primary-color);
        color: #fff;
    }

    /* Footer */
    #sp_Task_TaskList_html .fpd-footer {
        padding: 8px 14px;
        display: flex;
        justify-content: flex-end;
        border-top: 1px solid #f1f5f9;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .fpd-footer {
        border-top-color: #334155;
    }

    #sp_Task_TaskList_html .fpd-btn-clear {
        font-size: 0.78rem;
        font-weight: 600;
        color: #ef4444;
        background: none;
        border: none;
        cursor: pointer;
        padding: 4px 8px;
        border-radius: 6px;
        transition: background 0.15s;

        display: inline-flex;
        align-items: center;
        gap: 4px;
    }

    #sp_Task_TaskList_html .fpd-btn-clear:hover {
        background: rgba(239, 68, 68, 0.06);
    }

    /* Dark Theme Overrides - Standard Bootstrap [data-bs-theme="dark"] */
    [data-bs-theme="dark"] #sp_Task_TaskList_html .fc-header-toolbar {
        background: rgba(0, 0, 0, 0.2) !important;
        border-bottom-color: rgba(255, 255, 255, 0.1) !important;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .fc-toolbar-title {
        color: #fff !important;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .fc-col-header-cell {
        background: rgba(255, 255, 255, 0.05) !important;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .fc-theme-standard td,
    [data-bs-theme="dark"] #sp_Task_TaskList_html .fc-theme-standard th {
        border-color: rgba(255, 255, 255, 0.1) !important;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .fc-daygrid-day-number {
        color: #cbd5e1 !important;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .fc-day-today {
        background: rgba(74, 158, 15, 0.1) !important;
    }

    /* Dark Mode Event Tinting - High Contrast */
    [data-bs-theme="dark"] #sp_Task_TaskList_html .event-prio-1 {
        background-color: rgba(255, 77, 79, 0.15) !important;
        color: #ffa39e !important;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .event-prio-2 {
        background-color: rgba(255, 169, 64, 0.15) !important;
        color: #ffd591 !important;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .event-prio-3 {
        background-color: rgba(82, 196, 26, 0.15) !important;
        color: #b7eb8f !important;
    }

    /* Dark Mode UI Controls */
    [data-bs-theme="dark"] #sp_Task_TaskList_html .switcher-container {
        background-color: rgba(255, 255, 255, 0.05) !important;
        border-color: rgba(255, 255, 255, 0.1) !important;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .switcher-item {
        color: #94a3b8 !important;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .switcher-item.active {
        color: #fff !important;
    }

    [data-bs-theme="dark"] #sp_Task_TaskList_html .fc-button-primary {
        background-color: #334155 !important;
        border-color: #475569 !important;
        color: #f8fafc !important;
    }

    /* --- RESPONSIVE QUERIES --- */
    @media (max-width: 991px) {
        #sp_Task_TaskList_html .task-toolbar.grid-toolbar {
            display: flex;
            gap: 8px;
        }

        #sp_Task_TaskList_html .toolbar-toggle {
            display: inline-flex;
        }
    }

    @media (min-width: 992px) {
        #sp_Task_TaskList_html .grid-toolbar {
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
    }

    /* Default hide mobile toolbar */
    #sp_Task_TaskList_html .mobile-toolbar-wrapper {
        display: none;
    }

    .dx-overlay-wrapper,
    .dx-popup-wrapper,
    .dx-dropdowneditor-overlay,
    .dx-selectbox-popup-wrapper,
    .dx-tagbox-popup-wrapper,
    .dx-datagrid-filter-range-overlay {
        z-index: 2000 !important;
        background-color: transparent !important;
    }

    .flatpickr-calendar {
        z-index: 2000 !important;
    }

    /* Cho phép các overlay thoát khỏi container bị clip */
    #sp_Task_TaskList_html .custom-modal-overlay {
        backdrop-filter: none !important;
        /* bỏ blur để tránh tạo stacking context */
        -webkit-backdrop-filter: none !important;
        background: rgba(0, 0, 0, 0.55) !important;
    }

    #sp_Task_TaskList_html .btn-modal-close {
        background: none;
        border: none;
        font-size: 1.5rem;
        color: #94a3b8;
        cursor: pointer;
        padding: 4px;
    }

    #sp_Task_TaskList_html .btn-modal-close:hover {
        color: #ef4444;
    }

    @media (max-width: 1024px) {
        #sp_Task_TaskList_html .task-toolbar.grid-toolbar {
            display: none !important;
        }

        #sp_Task_TaskList_html .mobile-toolbar-wrapper {
            display: block;
            border-bottom: 1px solid #f1f5f9;
        }

        #sp_Task_TaskList_html .ttv-skeleton-row {

            display: flex !important;
            flex-direction: column !important;
            padding: 14px !important;
            margin: 0 12px 10px !important;
            border-radius: 14px !important;
            border: 1px solid var(--bs-border-color, #f1f5f9) !important;
            background: var(--bs-body-bg, #fff) !important;
            gap: 10px !important;
            height: auto !important;
        }

        #sp_Task_TaskList_html .ttv-skeleton-row>div:not(:nth-child(3)):not(:nth-child(4)):not(:nth-child(7)) {
            display: none !important;
        }

        #sp_Task_TaskList_html .ttv-skeleton-row>div:nth-child(3) {
            width: 70% !important;
            display: block !important;
        }

        #sp_Task_TaskList_html .ttv-skeleton-row>div:nth-child(4),
        #sp_Task_TaskList_html .ttv-skeleton-row>div:nth-child(7) {
            display: flex !important;
            align-items: center !important;
        }

        #sp_Task_TaskList_html #scheduler-container {
            height: calc(100vh - 200px) !important;
            margin: 0;
            border-radius: 0;
            border-left: none;
            border-right: none;
            z-index: 10;
        }

        #sp_Task_TaskList_html .custom-modal-container {
            position: fixed !important;
            max-height: calc(100% - 115px);
            top: 50px !important;
            height: 100% !important;
            display: flex !important;
            gap: 6px;
            flex-direction: column !important;
            overflow: hidden !important;
            max-width: 100% !important;
            transform: translateX(100%);
            transition: transform 0.5s ease;
        }

        #sp_Task_TaskList_html .custom-modal-overlay.active .custom-modal-container {
            transform: translateX(0) !important;
        }

        #sp_Task_TaskList_html .custom-modal-overlay {
            position: absolute !important;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.55);
            z-index: 1100 !important;
            display: none !important;
            align-items: center;
            justify-content: flex-end;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.4s cubic-bezier(0.4, 0, 0.2, 1);
        }

        #sp_Task_TaskList_html .custom-modal-overlay.active {
            display: flex !important;
            opacity: 1 !important;
            pointer-events: auto !important;
        }

        #sp_Task_TaskList_html .modal-right-sidebar {
            display: none !important;
        }

        /* Show sidebar content in main content on mobile */
        #sp_Task_TaskList_html .modal-main-content .mobile-only-sidebar-content {
            display: block !important;
            margin-top: 24px;
            padding-top: 24px;
            border-top: 1px dashed #e2e8f0;
        }

        #sp_Task_TaskList_html .task-info-grid {
            grid-template-columns: 1fr;
        }

        #sp_Task_TaskList_html .custom-modal-footer {
            flex-shrink: 0 !important;
            padding-bottom: calc(12px + env(safe-area-inset-bottom, 0px)) !important;
            position: relative !important;
            z-index: 2001 !important;
            background: var(--bs-body-bg, #fff) !important;
            padding: 0 24px;
        }

        #sp_Task_TaskList_html .custom-modal-footer button {
            width: 100%;
            padding: 8px;
            justify-content: center;
        }

        #sp_Task_TaskList_html .custom-modal-header {
            display: none !important;
        }

        #sp_Task_TaskList_html .custom-modal-body {
            flex: 1 1 0 !important;
            min-height: 0 !important;
            overflow-y: auto !important;
            overflow-x: hidden !important;
            overscroll-behavior: contain !important;
            padding-bottom: 0 !important;
            -webkit-tap-highlight-color: transparent;
        }

        #sp_Task_TaskList_html .modal-main-content {
            flex: 1;
            min-height: 0;
            padding: 24px;
            overflow-y: auto;
            overflow-x: hidden;
            max-width: 100%;
        }

        #sp_Task_TaskList_html .custom-modal-title {
            font-weight: 700;
            font-size: 1.1rem;
        }

        /* Filter dropdown as mobile drawer */
        #sp_Task_TaskList_html .filter-pill-dropdown {
            position: fixed !important;
            top: auto !important;
            bottom: 60px !important;
            left: 0 !important;
            right: 0 !important;
            width: 100% !important;
            max-width: 100% !important;
            height: 80vh !important;
            max-height: 80vh !important;
            border-radius: 24px 24px 0 0 !important;
            box-shadow: 0 -15px 50px rgba(0, 0, 0, 0.3) !important;

            /* Animation properties */
            display: flex !important;
            flex-direction: column !important;
            transform: translateY(100%) !important;
            visibility: hidden !important;
            pointer-events: none !important;
            transition: transform 0.4s ease, visibility 0s 0.4s !important;

            z-index: 1200 !important;
            overflow: hidden !important;
            padding: 0 !important;
            padding-bottom: env(safe-area-inset-bottom, 20px) !important;
        }

        #sp_Task_TaskList_html .filter-pill-dropdown.show {
            visibility: visible !important;
            pointer-events: auto !important;
            transform: translateY(0) !important;
            transition: transform 0.4s ease, visibility 0s 0s !important;
        }

        #sp_Task_TaskList_html .mb-filter-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.6);
            backdrop-filter: none !important;
            -webkit-backdrop-filter: none !important;
            z-index: 1050;
            display: block !important;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.3s ease;
        }

        #sp_Task_TaskList_html .mb-filter-overlay.active {
            opacity: 1;
            pointer-events: auto;
        }

        #sp_Task_TaskList_html .filter-pill-dropdown .fpd-section {
            padding: 16px;
            border-bottom: 1px solid #f1f5f9;
        }

        #sp_Task_TaskList_html .fpd-body {
            flex: 1;
            overflow-y: auto;
            -webkit-overflow-scrolling: touch;
        }

        #sp_Task_TaskList_html .fpd-header-mobile {

            display: flex;
            align-items: center;
            justify-content: center;
            padding: 12px;
            border-bottom: 1px solid #f1f5f9;
            flex-shrink: 0;
        }

        #sp_Task_TaskList_html .fpd-pull-bar {
            width: 40px;
            height: 4px;
            background: #e2e8f0;
            border-radius: 2px;
        }

        #sp_Task_TaskList_html .filter-pill-dropdown .fpd-footer {
            padding: 16px 20px;
            margin-top: auto;
            position: sticky;
            bottom: 0;
        }

        #sp_Task_TaskList_html .mb-filter-btn {
            position: relative;
        }

        #sp_Task_TaskList_html .mb-filter-badge {
            position: absolute;
            top: -4px;
            right: -4px;
            background: #ef4444;
            color: white;
            font-size: 10px;
            min-width: 16px;
            height: 16px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 0 4px;
            font-weight: 700;
            border: 2px solid #fff;
        }

        #sp_Task_TaskList_html .btn-add-task {
            display: none !important;
        }

        /* --- LAYOUT TỔNG QUAN --- */
        #sp_Task_TaskList_html {
            position: relative;
            z-index: 1;
            height: auto;
            min-height: 100vh;
            overflow: visible;
        }

        #sp_Task_TaskList_html #view-container {
            overflow: visible;
            height: 100%;
        }

        #sp_Task_TaskList_html #grid-wrapper {
            overflow: auto;
            flex: unset;
        }

        #sp_Task_TaskList_html .ttv-wrap {
            border: none;
            background: transparent;
            overflow: visible;
        }

        #sp_Task_TaskList_html .ttv-header {
            display: none !important;
        }

        #sp_Task_TaskList_html .ttv-empty {
            min-height: 65vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            padding: 40px 20px !important;
        }

        #sp_Task_TaskList_html .ttv-empty i {
            font-size: 5rem !important;
            opacity: 0.2 !important;
            margin-bottom: 12px;
        }

        #sp_Task_TaskList_html .ttv-empty p {
            font-size: 1.1rem !important;
            font-weight: 500;
            color: #94a3b8;
        }

        #sp_Task_TaskList_html .fc-header-toolbar {
            gap: 8px !important;
            padding: 10px !important;
        }

        #sp_Task_TaskList_html .fc-toolbar-chunk:first-child {
            width: 100%;
            justify-content: center !important;
            gap: 5px !important;
        }

        #sp_Task_TaskList_html .fc-toolbar-title {
            font-size: 1.1rem !important;
            width: 100% !important;
            white-space: nowrap;
            text-align: center !important;
        }

        #sp_Task_TaskList_html .fc-daygrid-event {
            font-size: 0.6rem !important;
            padding: 1px 4px !important;
            margin: 1px 0 !important;
        }

        #sp_Task_TaskList_html .fc-daygrid-event-dot,
        #sp_Task_TaskList_html .fc-event-title {
            display: none !important;
        }

        #sp_Task_TaskList_html .ttv-body {
            overflow: visible;
            padding-top: 4px;
        }

        #sp_Task_TaskList_html .dx-texteditor.dx-state-active::before,
        #sp_Task_TaskList_html .dx-texteditor.dx-state-focused::before {
            transform: scaleX(1) !important;
            transition: none !important;
        }

        /* ===== MOBILE TOOLBAR ===== */
        #sp_Task_TaskList_html .mobile-toolbar-wrapper {
            background: var(--bs-body-bg, #fff);
            border-bottom: 1px solid var(--bs-border-color, #f0f4f8);
            padding: 10px 14px 0;
            position: sticky;
            top: 0;
            z-index: 1050;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
        }

        [data-bs-theme="dark"] #sp_Task_TaskList_html .mobile-toolbar-wrapper {
            background: #1e293b;
            border-bottom-color: #334155;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
        }

        /* Row 1: Search (80%) + Filter button (20%) */
        #sp_Task_TaskList_html .mb-searchrow {
            display: flex;
            align-items: center;
            gap: 8px;

            margin-bottom: 10px;
        }

        #sp_Task_TaskList_html .mb-search-wrap {
            flex: 0 0 86%;
            position: relative;
        }

        #sp_Task_TaskList_html .mb-search-icon {
            position: absolute;
            left: 11px;
            top: 50%;
            transform: translateY(-50%);
            color: #94a3b8;
            font-size: 0.82rem;
            pointer-events: none;
        }

        #sp_Task_TaskList_html .mb-search-clear {
            position: absolute;
            right: 12px;
            top: 50%;
            transform: translateY(-50%);
            color: #cbd5e1;
            font-size: 1.1rem;
            cursor: pointer;
            transition: color 0.15s;
            z-index: 5;
        }

        #sp_Task_TaskList_html .mb-search-clear:hover {
            color: #94a3b8;
        }

        #sp_Task_TaskList_html .mb-search-input {
            width: 100%;
            padding: 9px 34px 9px 32px;
            border-radius: 10px;
            border: 1px solid var(--bs-border-color, #e2e8f0);
            background: var(--bs-tertiary-bg, #f8fafc);
            font-size: 0.88rem;
            color: var(--bs-body-color, #1e293b);
            outline: none;
            transition: border-color 0.2s, background 0.2s;
        }

        #sp_Task_TaskList_html .mb-search-input:focus {
            border-color: var(--primary-color, #4a9e0f);
            background: var(--bs-body-bg, #fff);
            box-shadow: 0 0 0 3px rgba(74, 158, 15, 0.08);
        }

        #sp_Task_TaskList_html .mb-search-input::placeholder {
            color: #94a3b8;
        }

        [data-bs-theme="dark"] #sp_Task_TaskList_html .mb-search-input {
            background: #0f172a;
            border-color: #334155;
            color: #f1f5f9;
        }

        /* Filter button chiếm phần còn lại */
        #sp_Task_TaskList_html .mb-filter-btn {
            flex: 1;
            height: 40px;
            border-radius: 10px;
            border: 1px solid var(--bs-border-color, #e2e8f0);
            background: var(--bs-tertiary-bg, #f8fafc);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.82rem;
            font-weight: 600;
            color: #64748b;
            gap: 5px;
            cursor: pointer;
            transition: all 0.15s;
            white-space: nowrap;
        }

        #sp_Task_TaskList_html .mb-filter-btn.has-filter {
            border-color: var(--primary-color, #4a9e0f);
            color: var(--primary-color, #4a9e0f);
            background: rgba(74, 158, 15, 0.06);
        }

        [data-bs-theme="dark"] #sp_Task_TaskList_html .mb-filter-btn {
            background: #0f172a;
            border-color: #334155;
            color: #94a3b8;
        }

        /* Row 2: Tab switcher với underline slider */
        #sp_Task_TaskList_html .mb-tab-wrap {
            overflow-x: auto;
            scrollbar-width: none;
            margin-bottom: 0;
        }

        #sp_Task_TaskList_html .mb-tab-wrap::-webkit-scrollbar {
            display: none;
        }

        #sp_Task_TaskList_html .mb-tab-track {
            position: relative;
            display: inline-flex;
            min-width: 100%;
        }

        #sp_Task_TaskList_html .mb-tab-item {
            background: none;
            border: none;
            padding: 9px 13px;
            font-size: 0.86rem;
            font-weight: 600;
            color: #94a3b8;
            white-space: nowrap;
            transition: color 0.2s;
            cursor: pointer;
            flex-shrink: 0;
        }

        #sp_Task_TaskList_html .mb-tab-item.active {
            color: var(--primary-color, #4a9e0f);
        }

        #sp_Task_TaskList_html .mb-tab-slider {
            position: absolute;
            bottom: 0;
            height: 3px;
            background: var(--primary-color, #4a9e0f);
            border-radius: 3px 3px 0 0;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }

        /* Row 3: View toggle (List/Calendar) + Reload */
        #sp_Task_TaskList_html .mb-viewrow {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 8px 0;
            border-top: 1px solid var(--bs-border-color-translucent, #f0f4f8);
        }

        [data-bs-theme="dark"] #sp_Task_TaskList_html .mb-viewrow {
            border-top-color: #334155;
        }

        #sp_Task_TaskList_html .mb-view-toggle {
            position: relative;
            display: flex;
            background: var(--bs-tertiary-bg, #f1f5f9);
            border-radius: 10px;
            padding: 3px;
        }

        [data-bs-theme="dark"] #sp_Task_TaskList_html .mb-view-toggle {
            background: #0f172a;
        }

        #sp_Task_TaskList_html .mb-view-slider {
            position: absolute;
            top: 3px;
            bottom: 3px;
            border-radius: 8px;
            background: var(--primary-color, #4a9e0f);
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            box-shadow: 0 2px 6px rgba(74, 158, 15, 0.3);
        }

        #sp_Task_TaskList_html .mb-view-item {
            position: relative;
            z-index: 1;
            background: none;
            border: none;
            padding: 7px 13px;
            font-size: 0.82rem;
            font-weight: 600;
            color: #64748b;
            display: flex;
            align-items: center;
            gap: 5px;
            transition: color 0.2s;
            cursor: pointer;
            white-space: nowrap;
        }

        #sp_Task_TaskList_html .mb-view-item.active {
            color: #fff;
        }

        #sp_Task_TaskList_html .mb-reload-btn {
            width: 36px;
            height: 36px;
            border-radius: 10px;
            border: 1px solid var(--bs-border-color, #e2e8f0);
            background: var(--bs-tertiary-bg, #f8fafc);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.95rem;
            color: #64748b;
            cursor: pointer;
            transition: all 0.2s;
            flex-shrink: 0;
        }

        #sp_Task_TaskList_html .mb-add-btn {
            height: 36px;
            padding: 0 12px;
            border-radius: 10px;
            border: none;
            background: var(--primary-color, #4a9e0f);
            color: #fff;
            font-size: 0.82rem;
            font-weight: 700;
            display: flex;
            align-items: center;
            gap: 5px;
            box-shadow: 0 4px 10px rgba(74, 158, 15, 0.25);
            white-space: nowrap;

        }

        #sp_Task_TaskList_html .mb-add-btn:active {
            transform: scale(0.96);
        }

        #sp_Task_TaskList_html .mb-reload-btn:active {
            background: rgba(74, 158, 15, 0.1);
            color: var(--primary-color, #4a9e0f);
        }

        /* ===== TASK CARDS ===== */
        /* Fix: mobile scroll container không chặn tap events */
        #sp_Task_TaskList_html .ttv-body {
            overflow: visible !important;
            height: auto !important;
            min-height: unset !important;
            flex: unset !important;
        }

        #sp_Task_TaskList_html .ttv-row {
            display: flex;
            flex-direction: column;
            padding: 6px;
            margin: 0 6px 6px 6px;
            border-radius: 14px;
            border: 1px solid var(--bs-border-color, #e8ecf4);
            border-left: 4px solid var(--bs-border-color, #e8ecf4);
            background: var(--bs-body-bg, #fff);
            gap: 7px;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
            cursor: pointer;
            transition: box-shadow 0.15s, transform 0.1s;
            /* Fix: đảm bảo tap được nhận diện ngay, không bị delay */
            touch-action: manipulation;
            -webkit-tap-highlight-color: rgba(74, 158, 15, 0.1);
            user-select: none;
        }

        #sp_Task_TaskList_html .ttv-row:active {
            transform: scale(0.99);
            box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
        }

        [data-bs-theme="dark"] #sp_Task_TaskList_html .ttv-row {
            background: #1e293b;
            border-color: #334155;
            border-left-color: #475569;
        }

        /* Overdue = đỏ border trái + nền hồng */
        #sp_Task_TaskList_html .ttv-row.overdue {
            border-left-color: var(--paradise-color-important, #ef4444) !important;
            background: rgba(220, 53, 69, 0.05) !important;
        }

        [data-bs-theme="dark"] #sp_Task_TaskList_html .ttv-row.overdue {
            background: rgba(220, 53, 69, 0.12) !important;
        }

        /* Today = vàng/cam */
        #sp_Task_TaskList_html .ttv-row.today {
            border-left-color: var(--paradise-color-warning, #f59e0b) !important;
            background: rgba(255, 193, 7, 0.05) !important;
        }

        [data-bs-theme="dark"] #sp_Task_TaskList_html .ttv-row.today {
            background: rgba(255, 193, 7, 0.1) !important;
        }

        /* Subtask: lùi vào trái */
        #sp_Task_TaskList_html .ttv-row.ttv-subtask {
            margin-left: 26px;
            margin-right: 6px;
            border-left-width: 3px;
            border-left-color: var(--paradise-color-secondary, #94a3b8) !important;
            background: var(--bs-tertiary-bg, #f8fafc);
        }

        [data-bs-theme="dark"] #sp_Task_TaskList_html .ttv-row.ttv-subtask {
            background: rgba(255, 255, 255, 0.02);
        }

        #sp_Task_TaskList_html .ttv-row.ttv-subtask.overdue {
            border-left-color: var(--paradise-color-important, #ef4444) !important;
        }

        #sp_Task_TaskList_html .ttv-row.ttv-subtask.today {
            border-left-color: var(--paradise-color-warning, #f59e0b) !important;
        }

        /* --- Card Row 1: Tên task + ID --- */
        #sp_Task_TaskList_html .ttv-card-top {
            display: flex !important;
            align-items: flex-start;
            gap: 6px;
            width: 100%;
        }

        #sp_Task_TaskList_html .ttv-card-top .ttv-task-name {
            flex: 1;
            font-size: 0.93rem;
            font-weight: 700;
            color: var(--bs-body-color, #1e293b);
            line-height: 1.4;
            white-space: normal !important;
            text-overflow: clip !important;
        }

        #sp_Task_TaskList_html .ttv-card-top .ttv-card-id {
            flex-shrink: 0;
            font-size: 0.68rem;
            color: #94a3b8;
            font-weight: 600;
            white-space: nowrap;
            padding-top: 3px;
            letter-spacing: 0.02em;
        }

        /* --- Avatar Group Refining --- */
        #sp_Task_TaskList_html .ttv-avatar-group {
            display: flex;
            align-items: center;
            flex-direction: row !important;
        }

        #sp_Task_TaskList_html .ttv-avatar {
            width: 24px;
            height: 24px;
            border: 1.5px solid #fff;
            border-radius: 50%;
            margin-left: -8px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 0.62rem;
            font-weight: 700;
            position: relative;
            z-index: 1;
            overflow: hidden;
            background: #e2e8f0;
        }

        #sp_Task_TaskList_html .ttv-avatar:first-child {
            margin-left: 0;
        }

        #sp_Task_TaskList_html .ttv-avatar img {
            width: 100%;
            height: 100%;
            object-fit: cover;
        }

        [data-bs-theme="dark"] #sp_Task_TaskList_html .ttv-avatar {
            border-color: #1e293b;
        }

        #sp_Task_TaskList_html .ttv-card-sub-toggle {
            display: inline-flex;
            align-items: center;
            gap: 3px;
            font-size: 0.7rem;
            font-weight: 700;
            color: var(--primary-color, #4a9e0f);
            background: rgba(74, 158, 15, 0.08);
            border: none;
            border-radius: 5px;
            padding: 2px 6px;
            cursor: pointer;
            flex-shrink: 0;
            transition: background 0.2s;
        }

        #sp_Task_TaskList_html .ttv-card-sub-toggle i {
            transition: transform 0.25s cubic-bezier(0.4, 0, 0.2, 1);
            display: inline-block;
        }

        #sp_Task_TaskList_html .ttv-card-sub-toggle.expanded i {
            transform: rotate(180deg);
        }

        /* --- Hide Desktop Columns on Mobile --- */
        #sp_Task_TaskList_html .ttv-row>div:not(.ttv-card-top):not(.ttv-card-meta) {
            display: none !important;
        }

        #sp_Task_TaskList_html .ttv-row>.ttv-card-top,
        #sp_Task_TaskList_html .ttv-row>.ttv-card-meta {
            display: flex !important;
        }

        /* --- Card Row 2: Status + Assignee --- */
        #sp_Task_TaskList_html .ttv-card-meta {
            display: flex !important;
            align-items: center;
            justify-content: space-between !important;
            gap: 8px;
            width: 100%;
            margin-top: 2px;
        }

        #sp_Task_TaskList_html .ttv-card-meta .ttv-status-badge {
            font-size: 0.6rem;
            padding: 0px 4px;
            border-radius: 4px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.02em;
        }

        #sp_Task_TaskList_html .ttv-card-meta .mb-meta-right {
            display: flex;
            align-items: flex-end;
            gap: 8px;
        }

        #sp_Task_TaskList_html .ttv-card-meta .ttv-assignee-cell {
            padding: 0;
        }

        #sp_Task_TaskList_html .ttv-card-meta .ttv-avatar {
            width: 26px;
            height: 26px;

            font-size: 0.62rem;
        }

        #sp_Task_TaskList_html .mb-date-chip {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            font-size: 0.72rem;
            font-weight: 600;
            color: #94a3b8;
        }

        #sp_Task_TaskList_html .mb-date-chip.overdue {
            color: #ef4444 !important;
        }

        #sp_Task_TaskList_html .mb-date-chip.today {
            color: #f59e0b !important;
        }
    }

    @media (max-width: 1024px) {

        #sp_Task_TaskList_html .custom-modal-body .dx-widget,
        #sp_Task_TaskList_html .custom-modal-body .dx-texteditor,
        #sp_Task_TaskList_html .custom-modal-body .dx-dropdowneditor-button,
        #sp_Task_TaskList_html .custom-modal-body input,
        #sp_Task_TaskList_html .custom-modal-body [class*="hpa"] {
            touch-action: manipulation !important;
            -webkit-tap-highlight-color: transparent;
            position: relative;
            z-index: 2000 !important;
        }

        #sp_Task_TaskList_html #mdlRecurrenceDrawer .dx-widget,
        #sp_Task_TaskList_html #mdlRecurrenceDrawer .dx-texteditor,
        #sp_Task_TaskList_html #mdlRecurrenceDrawer .dx-dropdowneditor-button,
        #sp_Task_TaskList_html #mdlRecurrenceDrawer input,
        #sp_Task_TaskList_html #mdlRecurrenceDrawer [class*="hpa"] {
            touch-action: manipulation !important;
            -webkit-tap-highlight-color: transparent;
            z-index: 2000 !important;
        }
    }

    @media (min-width: 768px) {

        #sp_Task_TaskList_html .ttv-card-top,
        #sp_Task_TaskList_html .ttv-card-meta {
            display: none !important;
        }
    }

    /* ===== SCROLL PERFORMANCE FIXES ===== */
    #sp_Task_TaskList_html .ttv-body {
        will-change: transform;
        -webkit-overflow-scrolling: touch;
        contain: layout style;
        transform: translateZ(0);
    }

    #sp_Task_TaskList_html .ttv-row {
        contain: layout style;
    }

    #sp_Task_TaskList_html .ttv-header {
        contain: layout style;
        transform: translateZ(0);
        backface-visibility: hidden;
    }

    /* --- CODE FIX: FORM DRAWER ỔN ĐỊNH TUYỆT ĐỐI (SÁT TRÊN, SÁT DƯỚI, VUÔNG GÓC) --- */
    #sp_Task_TaskList_html {
        width: 100% !important;
    }

    #sp_Task_TaskList_html .custom-modal-overlay.active {
        display: flex !important;
    }

    @media (min-width: 768px) {
        #sp_Task_TaskList_html .custom-modal-overlay {
            position: absolute !important;
            top: 0 !important;
            left: 0 !important;
            right: 0 !important;
            /* CẮT BỎ PHẦN TRÀN ĐÁY: Giới hạn chiều cao Overlay bằng đúng vùng hiển thị thực tế */
            height: calc(100vh - 105px) !important;
            overflow: hidden !important;
        }

        #sp_Task_TaskList_html .custom-modal-container {
            position: absolute !important;
            top: 0 !important;
            /* NEO SÁT MÉP TRÊN */
            bottom: 0 !important;
            /* NEO SÁT MÉP DƯỚI */

            right: -70vw !important;
            /* Giấu form đi khi chưa mở */
            width: 70vw !important;
            max-width: 70vw !important;

            height: 100% !important;
            /* Lấy vừa khít 100% chiều cao của lớp Overlay đã bị cắt */
            max-height: 100% !important;

            border-radius: 0 !important;
            /* YÊU CẦU 2: BỎ BO TRÒN -> VIỀN VUÔNG GÓC 100% */
            display: flex !important;
            flex-direction: column !important;

            opacity: 0 !important;
            transition: right 0.35s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.35s ease !important;
            box-shadow: -10px 0 30px rgba(0, 0, 0, 0.15) !important;
            transform: none !important;
        }

        #sp_Task_TaskList_html .custom-modal-overlay.active .custom-modal-container {
            right: 0 !important;
            /* Trượt vào sát mép phải */
            opacity: 1 !important;
        }

        /* Đảm bảo phần body sinh thanh cuộn, giữ 2 nút bấm nổi cố định dưới đáy */
        #sp_Task_TaskList_html .custom-modal-body {
            flex: 1 1 auto !important;
            overflow-y: auto !important;
            min-height: 0 !important;
        }

        #sp_Task_TaskList_html .custom-modal-footer {
            flex: 0 0 auto !important;
            padding-bottom: 20px !important;
            background-color: var(--bs-body-bg, #fff) !important;
        }
    }

    /* ------------------------------------------------------------- */
</style>

<div id="sp_Task_TaskList_html">
    <div id="view-container">
        <div class="task-toolbar grid-toolbar d-flex align-items-center justify-content-between" style="width:100%">
            <div class="toolbar-left d-flex align-items-center gap-2">
                <div class="toolbar-group d-none" id="calendar-view-options-group">
                    <div class="switcher-container" id="calendar-view-options">
                        <div class="tab-slider bg-success"></div>
                        <button class="switcher-item" data-value="day" id="btn-cal-day">%Day%</button>
                        <button class="switcher-item" data-value="week" id="btn-cal-week">%week%</button>
                        <button class="switcher-item active" data-value="month" id="btn-cal-month">%Month%</button>
                    </div>
                </div>

                <div class="toolbar-group d-flex align-items-center gap-2">
                    <div class="switcher-container p-1" id="view-switcher">
                        <div class="tab-slider bg-success"></div>
                        <button class="switcher-item active" data-value="list" id="btn-view-list" title="%List%">
                            <i class="bi bi-list-ul" style="font-size: 1.1rem;"></i>
                        </button>
                        <button class="switcher-item" data-value="calendar" id="btn-view-calendar"
                            title="%grbCalendar%">
                            <i class="bi bi-calendar3" style="font-size: 1.1rem;"></i>
                        </button>
                    </div>
                </div>

                <div class="toolbar-group d-flex align-items-center gap-2">
                    <div class="switcher-container" id="filter-switcher">
                        <div class="tab-slider bg-success"></div>
                        <button class="switcher-item active" data-value="all" id="btn-filter-all">%All%</button>
                        <button class="switcher-item" data-value="doing" id="btn-filter-doing">%MyTasks%</button>
                        <button class="switcher-item" data-value="assigned"
                            id="btn-filter-assigned">%AssignedByMe%</button>
                        <button class="switcher-item" data-value="main" id="btn-filter-main">%Responsibility%</button>
                        <button class="switcher-item" data-value="review" id="btn-filter-review">%IReview%</button>
                        <button class="switcher-item" data-value="recent" id="btn-filter-recent">%Recent%</button>
                    </div>

                    <div class="filter-pill-wrap" id="filter-advanced-wrap">
                        <button class="filter-pill-btn" id="btn-filter-advanced">
                            <i class="bi bi-funnel" style="font-size:0.85rem;"></i>
                            <span class="fpd-filter-count"></span>
                            <i class="bi bi-chevron-down" style="font-size:0.65rem; margin-left:2px;"></i>
                        </button>
                    </div>
                </div>
            </div>

            <div class="toolbar-right d-flex align-items-center gap-2">
                <!-- Search bar -->
                <div class="ttv-search-wrap" id="ttv-search-wrap">
                    <i class="bi bi-search ttv-search-icon"></i>
                    <input type="text" class="ttv-search-input" id="ttv-search-input" placeholder="%Search%..."
                        autocomplete="off">
                </div>
                <!-- Reload -->
                <button class="btn-ttv-reload" id="btn-ttv-reload" title="%Reload%">
                    <i class="bi bi-arrow-clockwise" style="font-size:0.95rem"></i>
                </button>
                <div class="d-flex align-items-center gap-2">
                    <button class="btn btn-add-task btn-success" id="btn-add-total-task">
                        <i class="bi bi-plus-lg"></i> %AddNew%
                    </button>
                    <button class="toolbar-toggle" id="toolbar-toggle" title="%OpenToolbar%">
                        <i class="bi bi-three-dots-vertical"></i>
                    </button>
                </div>
            </div>
        </div>
        <div id="mobile-toolbar" class="mobile-toolbar-wrapper">
            <div class="mb-searchrow">
                <div class="mb-search-wrap">
                    <i class="bi bi-search mb-search-icon"></i>
                    <input type="text" class="mb-search-input" id="mb-search-input" placeholder="Tìm kiếm công việc..."
                        autocomplete="off">
                    <i class="bi bi-x-circle-fill mb-search-clear" id="mb-search-clear" style="display:none;"></i>
                </div>
                <button class="mb-filter-btn" id="mb-filter-btn" title="Bộ lọc">
                    <i class="bi bi-funnel"></i>
                    <span id="mb-filter-badge" class="mb-filter-badge" style="display:none"></span>
                </button>
            </div>
            <div class="mb-tab-wrap">
                <div class="mb-tab-track" id="mb-tab-track">
                    <div class="mb-tab-slider" id="mb-tab-slider"></div>
                    <button class="mb-tab-item active" data-value="all" id="mb-tab-all">%All%</button>
                    <button class="mb-tab-item" data-value="doing" id="mb-tab-doing">%MyTasks%</button>
                    <button class="mb-tab-item" data-value="assigned" id="mb-tab-assigned">%AssignedByMe%</button>

                    <button class="mb-tab-item" data-value="main" id="mb-tab-main">%Responsibility%</button>
                    <button class="mb-tab-item" data-value="review" id="mb-tab-review">%IReview%</button>
                    <button class="mb-tab-item" data-value="recent" id="mb-tab-recent">%Recent%</button>
                </div>
            </div>
            <div class="mb-viewrow">
                <div class="mb-view-toggle" id="mb-view-toggle">
                    <div class="mb-view-slider" id="mb-view-slider"></div>
                    <button class="mb-view-item active" data-view="list" id="mb-vt-list">
                        <i class="bi bi-list-ul"></i> <span>%List%</span>
                    </button>
                    <button class="mb-view-item" data-view="calendar" id="mb-vt-cal">
                        <i class="bi bi-calendar3"></i> <span>%grbCalendar%</span>
                    </button>
                </div>
                <div class="d-flex align-items-center gap-2">
                    <button class="mb-add-btn" id="mb-btn-add-task">
                        <i class="bi bi-plus-lg"></i> %AddNew%
                    </button>
                    <button class="mb-reload-btn" id="mb-reload-btn" title="%Reload%">
                        <i class="bi bi-arrow-clockwise"></i>
                    </button>
                </div>
            </div>
        </div>
        <div id="grid-wrapper">
            <div class="ttv-wrap" id="task-tree-view">
                <!-- Render bởi renderTreeView() -->
            </div>
        </div>
        <div id="scheduler-container" class="d-none"></div>
    </div>

    <!-- Move filter dropdown outside of toolbar to fix mobile display issues -->
    <div class="mb-filter-overlay" id="mb-filter-overlay"></div>
    <div class="filter-pill-dropdown bg-body" id="filter-advanced-dropdown"
        style="-webkit-overflow-scrolling: touch; overscroll-behavior-y: contain;"></div>

    <!-- CREATE TASK DRAWER -->
    <div class="custom-modal-overlay" id="create-task-modal">
        <div class="custom-modal-container bg-body" id="custom-modal-container">
            <div class="custom-modal-header">
                <div class="d-flex flex-column">
                    <h5 class="custom-modal-title" id="create-modal-title">%CreateNewTask%</h5>
                </div>
                <button class="btn-modal-close" id="btn-close-modal-x"><i class="bi bi-x-lg"></i></button>
            </div>
            <div class="custom-modal-body">
                <!-- Left: Main Task Content -->
                <div class="modal-main-content">
                    <!-- Main Task Content -->

                    <!-- Task Name & Priority Header -->
                    <div class="mb-3">
                        <label class="task-info-label d-block text-uppercase mb-1"
                            style="font-size: 0.7rem; letter-spacing: 1px; color: var(--bs-secondary-color, #94a3b8);">%TaskName%
                            <span class="text-danger">*</span></label>
                        <div class="d-flex align-items-center justify-content-between gap-3">
                            <div id="P63128D34B83D4F9EA7BEB928C35C7CF7" class="task-title-input flex-grow-1"></div>
                            <div id="create-priority-container" class="star-container" style="display: flex; gap: 8px;">
                            </div>
                        </div>
                    </div>

                    <!-- Card-style Inputs -->
                    <div class="task-info-grid">
                        <!-- Assignee -->
                        <div class="task-info-card">
                            <div class="task-info-icon"><i class="bi bi-person"></i></div>
                            <div class="task-info-details">
                                <div class="task-info-label">%Assignee% <span class="text-danger">*</span></div>
                                <div id="PD76FE9F7E30A44A08B305AC908595419"></div>
                            </div>
                        </div>
                        <!-- Due Date -->
                        <div class="task-info-card">
                            <div class="task-info-icon"><i class="bi bi-calendar3"></i></div>
                            <div class="task-info-details">
                                <div class="task-info-label">%DueDate%</div>
                                <div id="P1D812C8523D54ECFB8BDE98FE5E7EF98"></div>
                            </div>
                        </div>
                    </div>

                    <div class="task-info-grid">
                        <!-- Project -->
                        <div class="task-info-card" id="project-card-create">
                            <div class="task-info-icon"><i class="bi bi-folder2"></i></div>
                            <div class="task-info-details">
                                <div class="task-info-label">%Project% <span
                                        class="text-danger d-none d-md-inline">*</span></div>
                                <div id="P279678A95C514D7B815B1B357824875D"></div>
                            </div>

                        </div>
                        <!-- Standard Time -->
                        <div class="task-info-card">
                            <div class="task-info-icon"><i class="bi bi-clock-history"></i></div>
                            <div class="task-info-details">
                                <div class="task-info-label">%StandardTime% (m) <span class="text-danger">*</span></div>
                                <div id="main-time-container-tasklist">
                                    <div id="P136F0762551345078797DB3CC80DA470"></div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="task-info-grid" id="tags-card-create"
                        style="width: 100%; overflow: hidden; grid-template-columns: 1fr;">
                        <!-- Tag Row -->
                        <div class="task-info-card">
                            <div class="task-info-icon"><i class="bi bi-hash"></i></div>
                            <div class="task-info-details">
                                <div class="task-info-label">%TaskTags%</div>
                                <div id="P3F6E55934BF74079A3EBA78D91296EE0"></div>
                            </div>
                        </div>
                    </div>

                    <!-- Description -->
                    <div class="link-action" id="btn-toggle-description">
                        <i class="bi bi-text-left"></i> %EnterDescription%
                    </div>
                    <div id="description-container" class="d-none mt-2">
                        <div id="PDADFE6D548FF40EE8109B030B5B31AE9" class="position-relative"></div>
                    </div>

                    <!-- Actions Links -->
                    <!-- Checklist Section -->
                    <div class="checklist-section mt-4" id="checklist-container-wrapper">
                        <div class="checklist-header-compact mb-3">
                            <div id="label-checklist-toggle-list"
                                class="d-flex justify-content-between align-items-center mb-1 cursor-pointer"
                                style="cursor: pointer;">
                                <div class="d-flex align-items-baseline gap-2">
                                    <div class="text-uppercase fw-bold text-muted small" style="letter-spacing: 0.5px;">
                                        Checklist</div>
                                    <div class="cursor-pointer d-flex align-items-center justify-content-center text-success"
                                        style="width: 24px; height: 24px; border-radius: 6px;">
                                        <i class="bi bi-plus-lg" style="font-size: 1.1rem;"></i>
                                    </div>
                                    <span class="fw-bold text-success ms-1" id="checklist-count-text"
                                        style="font-size: 0.85rem;"></span>
                                </div>
                                <div class="d-flex align-items-center gap-2">
                                    <div id="checklist-percent-text" style="font-size: 0.85rem;">0%</div>
                                    <div id="btn-toggle-checklist_list"
                                        class="cursor-pointer d-flex align-items-center justify-content-center"
                                        style="width: 24px; height: 24px; border-radius: 6px;">
                                        <i class="bi bi-chevron-down text-muted" id="checklist-chevron"
                                            style="transition: transform 0.2s; font-size: 0.85rem;"></i>
                                    </div>
                                </div>
                            </div>
                            <div class="progress"
                                style="height: 6px; background-color: #f1f5f9; border-radius: 10px; overflow: hidden; border: 1px solid #f1f5f9;">
                                <div id="checklist-progress-bar" class="progress-bar bg-success shadow-sm"
                                    role="progressbar"
                                    style="width: 0%; border-radius: 10px; transition: width 0.4s ease;"></div>
                            </div>
                        </div>

                        <div id="checklist-body-content_list">
                            <div class="checklist-list d-flex flex-column gap-2" id="checklist-items-list">
                                <!-- Checklist items will be rendered here -->
                            </div>
                            <div class="checklist-add-box mt-3 p-2 border-dashed" id="checklist-add-box-wrapper"
                                style="display: none; border: 1px dashed #e2e8f0; background: var(--bs-body-bg, #fdfdfd);">
                                <input type="text"
                                    class="px-3 flex-grow-1 border-0 bg-transparent outline-none fw-semibold"
                                    style="font-size: 0.9rem; outline: none;" id="checklist-add-input"
                                    placeholder="Thêm mục kiểm tra...">
                                <div class="text-success cursor-pointer fs-3 px-2" id="btn-add-checklist-item"><i
                                        class="bi bi-plus-circle-fill"></i></div>
                            </div>
                        </div>
                    </div>

                    <!-- Sidebar content moved here for mobile -->
                    <div class="attachment-section mt-2" id="file-card-create">
                        <div id="PEBB780F668924A108C0A9FF20D70CD80"></div>
                    </div>

                    <!-- Phần công việc con -->
                    <div class="subtask-section mt-4" id="subtask-section-drawer">
                        <div class="d-flex align-items-center gap-3 mb-3">
                            <h6 class="mb-0 fw-bold" style="font-size: 1.1rem;">%Subtasks%</h6>
                        </div>

                        <div id="added-subtasks-list" class="mb-2"></div>

                        <!-- Bộ nhớ ẩn để duy trì các thực thể khi render lại -->
                        <div id="subtask-instances-storage" class="d-none">
                            <div id="P4386BF8B5C97415683E8B1F2FAA230DB"></div>
                            <div id="P25F5CBFA3D854FFD8AC3C1984B5439FC"></div>
                            <!-- Metric Controls are separate for subtasks -->
                            <div id="PF542142C17247A09FCD23C6FCF8462P"></div>
                        </div>
                        <div id="fpd-date-storage" class="d-none">
                            <div id="PC6BB82D3F057477BBEA1A0BD3B77AF2D"></div>
                            <div id="P72DD5A0B80D24D4EBFFF8F48E6B6D838"></div>
                            <div id="P794C2F8348554BF6B8EB236EC6F3A215"></div>
                            <div id="P_Filter_EmployeeID"></div>
                        </div>

                        <div class="link-action text-primary mt-3 d-inline-flex align-items-center gap-1"
                            id="btn-add-subtask-manual"
                            style="font-size: 0.95rem; font-weight: 600; padding: 10px 16px;">
                            <i class="bi bi-plus-lg"></i> %AddTask%
                        </div>
                    </div>

                    <!-- Sidebar content moved here for mobile -->
                    <div class="mobile-only-sidebar-content d-none">
                        <div class="mb-4">
                            <label class="task-info-label d-block text-uppercase mb-3"
                                style="font-size: 0.7rem; letter-spacing: 1px; color: #94a3b8;">Tiện ích khác</label>
                            <div class="d-flex gap-2 flex-wrap">
                                <div class="action-item-sidebar flex-fill mb-0" id="btn-drawer-approval-mb">
                                    <i class="bi bi-person-check"></i> Phê duyệt
                                </div>
                                <div class="action-item-sidebar flex-fill mb-0" id="btn-drawer-repeat-mb">
                                    <i class="bi bi-arrow-repeat"></i> Lặp lại
                                </div>
                            </div>
                        </div>
                        <div class="task-info-grid">
                            <div class="task-info-card">
                                <div class="task-info-icon"><i class="bi bi-person-up"></i></div>
                                <div class="task-info-details">
                                    <div class="task-info-label">%Requester%</div>
                                    <div id="P1257D8B184374728847FCB0CAEC1B7DB"></div>
                                </div>
                            </div>
                            <div class="task-info-card">
                                <div class="task-info-icon"><i class="bi bi-person-gear"></i></div>
                                <div class="task-info-details">
                                    <div class="task-info-label">%MainAssignee%</div>
                                    <div id="P0902358F935A441E868AADCB1DBFCF64"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Bên phải: Thanh hành động -->
                <div class="modal-right-sidebar" id="modal-right-sidebar-create">
                    <div style="padding: 0 8px;" id="other-utilities-label">
                        <label class="task-info-label d-block text-uppercase mb-3"
                            style="font-size: 0.7rem; letter-spacing: 1px; color: #94a3b8;">%OtherUtilitiesTitle%</label>
                        <div class="action-item-sidebar" id="btn-drawer-approval">
                            <i class="bi bi-person-check"></i> %RequireTaskApproval%
                        </div>
                        <div class="action-item-sidebar" id="btn-drawer-repeat">
                            <i class="bi bi-arrow-repeat"></i> %Repeat%
                        </div>
                    </div>

                    <div style="padding: 0 8px;" id="requester-section-create">
                        <div class="task-info-label">%Requester%</div>
                        <div id="requester-desktop-slot" class="mt-2"></div>
                    </div>
                    <div style="padding: 0 8px; margin-bottom: 8px;" id="main-assignee-section-create">
                        <div class="task-info-label">%MainAssignee%</div>
                        <div id="main-assignee-desktop-slot" class="mt-2"></div>
                    </div>

                </div>
            </div>
            <div class="custom-modal-footer">
                <button class="btn-drawer-secondary" id="btn-cancel-create">%Cancel%</button>
                <button class="btn-drawer-secondary" id="btn-reset-create">Làm mới</button>
                <button class="btn-drawer-primary bg-success text-white" id="btn-submit-create">
                    <i class="bi bi-send-check me-2"></i> %AddNew%
                </button>
            </div>
        </div>
    </div>

    <!-- Modal cài đặt phê duyệt (Ngăn kéo) -->
    <div id="mdlApprovalDrawer" class="custom-modal-overlay" style="z-index: 1200 !important;">
        <div class="custom-modal-container bg-body p-4"
            style="max-width: 550px !important; overflow-y: auto !important;">

            <!-- Tiêu đề -->
            <div class="d-flex justify-content-between align-items-center mb-2">
                <h5 class="fw-bold mb-0 text-body">%ApprovalConfiguration%</h5>
                <button type="button" class="btn-close-modal btn-outline-secondary border-0 bg-transparent"
                    id="btn-close-approval-drawer-x" style="font-size: 20px;">
                    <i class="bi bi-x-lg"></i>
                </button>
            </div>

            <!-- Toggle: Require approval -->
            <div class="d-flex align-items-center justify-content-between rounded-3 border bg-body mb-2"
                style="padding: 24px 16px;">
                <div>
                    <div class="fw-bold text-body" style="font-size: 1.2rem;">%RequireTaskApproval%</div>
                    <div class="text-muted" style="font-size: 0.9rem; margin-top: 6px;">%TaskApprovalRequired%</div>
                </div>
                <div class="form-check form-switch mb-0">
                    <input class="form-check-input" type="checkbox" id="approval-drawer-required" role="switch"
                        style="width: 44px; height: 22px; cursor: pointer;">
                </div>
            </div>

            <!-- Extra (shown only when required is ON) -->
            <div id="approval-drawer-extra" style="display: none; flex-direction: column; gap: 14px;">

                <!-- Toggle: Multi-level -->
                <div class="d-flex align-items-center justify-content-between rounded-3 border bg-body"
                    style="padding: 12px 16px;">
                    <div>
                        <div class="fw-bold text-body" style="font-size: 1.2rem;">%MultiLevelApproval%</div>
                        <div class="text-muted" style="font-size: 0.9rem; margin-top: 6px;">
                            %AddMultipleApproversInOrder%</div>
                    </div>
                    <div class="form-check form-switch mb-0">
                        <input class="form-check-input" type="checkbox" id="approval-drawer-multilevel" role="switch"
                            style="width: 44px; height: 22px; cursor: pointer;">
                    </div>
                </div>

                <!-- Stages container -->
                <div class="mt-2">
                    <label class="small fw-bold text-muted mb-2 d-block text-uppercase"
                        style="font-size: 0.72rem; letter-spacing: 0.5px;">%Approver%</label>
                    <div id="approval-stages-container" style="display: flex; flex-direction: column; gap: 10px;">
                        <!-- Stage cards rendered by JS -->
                    </div>
                    <!-- Add stage button (only in multi mode) -->
                    <div id="btn-add-approval-stage" style="display: none; margin-top: 10px;">
                        <button type="button" class="btn btn-outline-secondary border btn-sm fw-bold"
                            style="border-radius: 8px; padding: 6px 16px; font-size: 0.82rem;">
                            <i class="bi bi-plus-lg me-1"></i>%AddApprovalLevel%
                        </button>
                    </div>
                </div>

                <!-- Note -->
                <div class="mt-2">
                    <label class="small fw-bold text-muted mb-2 d-block text-uppercase"
                        style="font-size: 0.72rem; letter-spacing: 0.5px;">Ghi chú</label>
                    <textarea id="approval-drawer-note" class="form-control border rounded-3 shadow-none" rows="2"
                        placeholder="Nhập ghi chú (nếu có)..." style="font-size: 0.88rem; resize: none;"></textarea>
                </div>
            </div>

            <!-- Chân trang -->
            <div class="d-flex justify-content-end gap-3 border-top" style="padding-top: 14px; margin-top: 4px;">
                <button type="button" class="btn btn-light border fw-bold" id="btn-cancel-approval-drawer"
                    style="padding: 7px 22px; border-radius: 8px; color: #64748b;">%Cancel%</button>
                <button type="button" class="btn btn-success text-white fw-bold" id="btn-confirm-approval-drawer"
                    style="padding: 7px 22px; border-radius: 8px;">%btnConfirm%</button>
            </div>
        </div>
    </div>

    <!-- Modal cài đặt lặp lại (Ngăn kéo) -->
    <div id="mdlRecurrenceDrawer" class="custom-modal-overlay" style="z-index: 1200 !important;">
        <div class="custom-modal-container bg-body p-4" style="max-width: 550px !important;">

            <!-- Tiêu đề -->
            <div class="d-flex justify-content-between align-items-center mb-2">
                <h5 class="fw-bold mb-0 text-body">%RecurrenceConfiguration%</h5>
                <button type="button" class="btn-close-modal btn-outline-secondary border-0 bg-transparent"
                    id="btn-close-recurrence-drawer-x" style="font-size: 20px;">
                    <i class="bi bi-x-lg"></i>
                </button>
            </div>

            <!-- Alert (Recurrence Explanation) -->
            <div class="d-flex align-items-start gap-3 rounded-3 border mb-2" style="padding: 16px; color: #1e40af;">
                <i class="bi bi-check2-circle text-primary" style="margin-top: 2px; font-size: 1.2rem;"></i>
                <div style="font-size: 0.85rem; line-height: 1.6;" class="text-body">
                    <strong class="d-block mb-1 text-primary">%RecurrenceRule%:</strong>
                    %RecurrenceRuleDescription%
                </div>
            </div>

            <!-- Chọn kiểu lặp -->
            <div>
                <label class="small fw-bold text-muted mb-2 d-block text-uppercase"
                    style="font-size: 0.75rem; letter-spacing: 0.5px;">%RecurrenceType%</label>
                <div class="d-flex position-relative bg-body rounded-3 border mb-2" style="padding: 4px;">
                    <div class="position-absolute bg-success rounded-3 shadow-sm" id="rec-drawer-slider"
                        style="top: 4px; bottom: 4px; width: calc(33.333% - 6px); transition: all 0.3s ease; left: 4px; z-index: 0;">
                    </div>

                    <input type="radio" class="btn-check" name="rec-drawer-type" id="rec-drawer-daily"
                        autocomplete="off" value="1">
                    <label class="btn btn-md border-0 flex-fill fw-bold position-relative text-center"
                        for="rec-drawer-daily"
                        style="padding: 8px 0; z-index: 1; transition: color 0.2s; cursor: pointer;">%Daily%</label>

                    <input type="radio" class="btn-check" name="rec-drawer-type" id="rec-drawer-weekly"
                        autocomplete="off" value="2" checked>
                    <label class="btn btn-md border-0 flex-fill fw-bold position-relative text-center"
                        for="rec-drawer-weekly"
                        style="padding: 8px 0; z-index: 1; transition: color 0.2s; cursor: pointer;">%Weekly%</label>

                    <input type="radio" class="btn-check" name="rec-drawer-type" id="rec-drawer-monthly"
                        autocomplete="off" value="3">
                    <label class="btn btn-md border-0 flex-fill fw-bold position-relative text-center"
                        for="rec-drawer-monthly"
                        style="padding: 8px 0; z-index: 1; transition: color 0.2s; cursor: pointer;">%Monthly%</label>
                </div>
            </div>

            <!-- Chu kỳ lặp -->
            <div class="mb-2">
                <label class="small fw-bold text-muted mb-2 d-block text-uppercase"
                    style="font-size: 0.75rem; letter-spacing: 0.5px;">%RecurrenceInterval%</label>
                <div class="d-flex align-items-center border rounded-3 bg-body input-group-focus"
                    style="padding: 8px 16px;">
                    <span class="text-muted me-3">%Every%</span>
                    <input type="number" id="rec-drawer-interval" value="1" min="1"
                        class="form-control border-0 fw-bold text-center p-0 shadow-none bg-body"
                        style="flex: 1; font-size: 1rem;">
                    <span class="text-muted ms-3" id="rec-drawer-interval-unit">%week%</span>
                </div>
            </div>

            <!-- Weekly Days -->
            <div id="rec-drawer-weekly-days-container" class="mb-2">
                <label class="small fw-bold text-muted mb-2 d-block text-uppercase"
                    style="font-size: 0.75rem; letter-spacing: 0.5px;">%OnDays%</label>
                <div class="d-flex gap-2">
                    <input type="checkbox" class="btn-check rec-drawer-day" id="drawer-day-2" value="2">
                    <label
                        class="btn btn-outline-light text-body border shadow-sm d-flex align-items-center justify-content-center fw-bold day-circle"
                        style="border-radius: 50% !important; width: 40px; height: 40px; padding: 0;"
                        for="drawer-day-2">T2</label>
                    <input type="checkbox" class="btn-check rec-drawer-day" id="drawer-day-3" value="3">
                    <label
                        class="btn btn-outline-light text-body border shadow-sm d-flex align-items-center justify-content-center fw-bold day-circle"
                        style="border-radius: 50% !important; width: 40px; height: 40px; padding: 0;"
                        for="drawer-day-3">T3</label>
                    <input type="checkbox" class="btn-check rec-drawer-day" id="drawer-day-4" value="4">
                    <label
                        class="btn btn-outline-light text-body border shadow-sm d-flex align-items-center justify-content-center fw-bold day-circle"
                        style="border-radius: 50% !important; width: 40px; height: 40px; padding: 0;"
                        for="drawer-day-4">T4</label>
                    <input type="checkbox" class="btn-check rec-drawer-day" id="drawer-day-5" value="5">
                    <label
                        class="btn btn-outline-light text-body border shadow-sm d-flex align-items-center justify-content-center fw-bold day-circle"
                        style="border-radius: 50% !important; width: 40px; height: 40px; padding: 0;"
                        for="drawer-day-5">T5</label>
                    <input type="checkbox" class="btn-check rec-drawer-day" id="drawer-day-6" value="6">
                    <label
                        class="btn btn-outline-light text-body border shadow-sm d-flex align-items-center justify-content-center fw-bold day-circle"
                        style="border-radius: 50% !important; width: 40px; height: 40px; padding: 0;"
                        for="drawer-day-6">T6</label>
                    <input type="checkbox" class="btn-check rec-drawer-day" id="drawer-day-7" value="7">
                    <label
                        class="btn btn-outline-light text-body border shadow-sm d-flex align-items-center justify-content-center fw-bold day-circle"
                        style="border-radius: 50% !important; width: 40px; height: 40px; padding: 0;"
                        for="drawer-day-7">T7</label>
                    <input type="checkbox" class="btn-check rec-drawer-day" id="drawer-day-1" value="1">
                    <label
                        class="btn btn-outline-light text-body border shadow-sm d-flex align-items-center justify-content-center fw-bold day-circle"
                        style="border-radius: 50% !important; width: 40px; height: 40px; padding: 0;"
                        for="drawer-day-1">CN</label>
                </div>
            </div>

            <!-- Cài đặt ngày -->
            <div class="row g-3">
                <div class="col-6">
                    <label class="small fw-bold text-muted mb-2 d-block text-uppercase"
                        style="font-size: 0.75rem; letter-spacing: 0.5px;">%StartFrom%</label>
                    <div id="rec-drawer-start-date"></div>
                </div>
                <div class="col-6">
                    <label class="small fw-bold text-muted mb-2 d-block text-uppercase"
                        style="font-size: 0.75rem; letter-spacing: 0.5px;">%RepeatEndDate%</label>

                    <div id="rec-drawer-end-date"></div>
                </div>
            </div>

            <!-- Chân trang -->
            <div class="d-flex justify-content-end gap-3 border-top" style="padding-top: 16px; margin-top: 16px;">
                <button type="button" class="btn btn-light border fw-bold" id="btn-cancel-recurrence-drawer"
                    style="padding: 8px 24px; border-radius: 8px; color: #64748b;">%Cancel%</button>
                <button type="button" class="btn btn-success text-white fw-bold" id="btn-confirm-recurrence-drawer"
                    style="padding: 8px 24px; border-radius: 8px; box-shadow: 0 4px 10px rgba(16, 185, 129, 0.3);">%Confirm%</button>
            </div>
        </div>
    </div>

    <!-- Task Preview Popover -->
    <div id="task-preview-popover" style="display: none;">
        <div class="preview-header">
            <h6 class="preview-title"></h6>
            <button class="preview-close"><i class="bi bi-x"></i></button>
        </div>
        <div class="preview-body">
            <!-- Info items will be injected here -->
        </div>
        <div class="preview-footer">
            <button class="btn-preview-detail">%ViewDetail% <i class="bi bi-arrow-right ms-1"></i></button>
        </div>
    </div>
</div>

<script>
    (function () {
        window.hpaIsAdminOrManager = window.hpaIsAdminOrManager || false;
        // Biến xử lý window._noManagerWarning và window.tempApprovalUserEdited
        const isMobile = () => window.innerWidth <= 767;
        window.isSubmittingTask = false;
        window.activeDraftHistoryID = 0;
        window.activeDraftTaskID = 0;
        window.isSavedSuccessfully = false;
        window.currentRecordID_HistoryID = null;
        window.currentRecordID_Temp_HistoryID = window.currentRecordID_HistoryID;
        window.createTaskSessionUID = null;
        window["_displayedTags_TagIDP3F6E55934BF74079A3EBA78D91296EE0"] = 10;

        function generateUUID() {
            return ''xxxxxxxx - xxxx - 4xxx - yxxx - xxxxxxxxxxxx''.replace(/[xy]/g, function (c) {
                var r = Math.random() * 16 | 0, v = c == ''x'' ? r : (r & 0x3 | 0x8);
                return v.toString(16);
            });
        }

        // Hàm hỗ trợ để bật/tắt các lớp hoạt động cho các đầu vào lặp lại trong Ngăn kéo
        const bindRecurrenceDrawerToggles = (containerId) => {
            const $container = $("#" + containerId);
            if (!$container.length) return;

            const $slider = $("#rec-drawer-slider");
            const $radios = $container.find(''input[type = "radio"]'');

            const updateSliderCallback = () => {
                $radios.each(function (index) {
                    const $r = $(this);
                    if ($r.is(":checked")) {
                        if ($slider.length) {
                            if (index === 0) $slider.css("left", "4px");
                            else if (index === 1) $slider.css("left", "calc(33.333% + 2px)");
                            else if (index === 2) $slider.css("left", "calc(66.666%)");
                        }

                        // Thay đổi màu chữ cho các nhãn
                        $radios.each(function () {
                            const $other = $(this);
                            const $lbl = $container.find(`label[for="${$other.attr("id")}"]`);
                            if ($lbl.length) {
                                if ($other.attr("id") === $r.attr("id")) {
                                    $lbl.removeClass("text-muted text-secondary text-body").addClass("text-white").removeClass("bg-success shadow-sm");
                                } else {
                                    $lbl.removeClass("text-white bg-success shadow-sm").addClass("text-body");
                                }
                            }
                        });
                    }
                });
            };

            $radios.on("change", updateSliderCallback);
            setTimeout(updateSliderCallback, 50);

            // For Checkboxes (Days)
            const $checkboxes = $container.find(''input[type = "checkbox"].rec - drawer - day'');
            $checkboxes.each(function () {
                const $c = $(this);
                const $lbl = $container.find(`label[for="${$c.attr("id")}"]`);
                if ($lbl.length) {
                    $lbl.addClass("day-circle bg-body text-body border");
                }

                $c.on("change", () => {
                    if ($c.is(":checked")) {
                        $lbl.removeClass("bg-body text-body border").addClass("bg-success text-white border-0 shadow-sm");
                    } else {
                        $lbl.removeClass("bg-success text-white border-0 shadow-sm").addClass("bg-body text-body border").removeClass("btn-outline-light");
                    }
                });

                if ($c.is(":checked")) {
                    $lbl.removeClass("bg-body text-body border").addClass("bg-success text-white border-0 shadow-sm");
                }
            });
        };

        // Gọi hàm hỗ trợ sau khi DOM tải xong
        setTimeout(() => bindRecurrenceDrawerToggles("mdlRecurrenceDrawer"), 100);

        let allTasks = [];
        let displayedTasks = [];
        let projects = [];
        let employees = [];
        let statusList = [];
        let tags = [];
        let currentCreatePriority = 2; // Default Medium
        let isMyTask = "all";
        let switchingLock = false; // Prevent spamming switch
        let currentViewParentID = 0;
        let currentParentId = 0;     // ParentHistoryID
        let currentParentTaskId = 0;  // ParentTaskID

        let currentUser = null;
        let pendingSubtasks = [];
        let isLoading = false; // Loading state guard

        let currentView = "list";
        let currentCalendarView = "month";
        let selectedProjectIDs = [];
        let selectedStatusIDs = [];
        let selectedTagIDs = [];
        let selectedPriorityFilters = [];
        let selectedEmployeeIDs = [];

        let selectedDueDateFilter = null; // "today" | "week" | "month" | "overdue"
        let filterDateFrom = new Date(new Date().getFullYear(), new Date().getMonth() - 1, 1);
        let filterDateTo = new Date(new Date().getFullYear(), new Date().getMonth() + 2, 0);

        window.saveFilterState = function() {
            try {
                window.sp_Task_TaskList_param = {
                    ttvSearch, currentView, currentCalendarView, selectedProjectIDs, selectedStatusIDs,
                    selectedTagIDs, selectedPriorityFilters, selectedEmployeeIDs, selectedDueDateFilter,
                    filterDateFrom, filterDateTo, isMyTask
                };
            } catch (e) { }
        };

        try {
            const sf = window.sp_Task_TaskList_param;
            if (sf) {
                if (sf.ttvSearch !== undefined) ttvSearch = sf.ttvSearch;
                if (sf.currentView !== undefined) currentView = sf.currentView;
                if (sf.currentCalendarView !== undefined) currentCalendarView = sf.currentCalendarView;
                if (sf.selectedProjectIDs) selectedProjectIDs = sf.selectedProjectIDs;
                if (sf.selectedStatusIDs) selectedStatusIDs = sf.selectedStatusIDs;
                if (sf.selectedTagIDs) selectedTagIDs = sf.selectedTagIDs;
                if (sf.selectedPriorityFilters) selectedPriorityFilters = sf.selectedPriorityFilters;
                if (sf.selectedEmployeeIDs) selectedEmployeeIDs = sf.selectedEmployeeIDs;
                if (sf.selectedDueDateFilter !== undefined) selectedDueDateFilter = sf.selectedDueDateFilter;
                if (sf.filterDateFrom) filterDateFrom = new Date(sf.filterDateFrom);
                if (sf.filterDateTo) filterDateTo = new Date(sf.filterDateTo);
                if (sf.isMyTask !== undefined) isMyTask = sf.isMyTask;
            }
        } catch (e) {
            console.error("Failed to load filters from window.sp_Task_TaskList_param", e);
        }

        window["_hideID_ProjectIDP279678A95C514D7B815B1B357824875D"] = true
        window["_hideID_TagIDP3F6E55934BF74079A3EBA78D91296EE0"] = true
        window["_isEdit_TagIDP3F6E55934BF74079A3EBA78D91296EE0"] = true
        window["_isDelete_TagIDP3F6E55934BF74079A3EBA78D91296EE0"] = true
        window.currentRecordID_ProjectID = null;
        window.currentRecordID_TagID = null;

        window["DataSourceIDField_StatusID"] = "StatusID"
        window["DataSourceNameField_StatusID"] = "StatusName"

        window["DataSourceIDField_TagID"] = "TagID"
        window["DataSourceNameField_TagID"] = "TagName"

        function formatIDList(val) {
            if (!val) return "";
            const items = Array.isArray(val) ? val : String(val).split(",");
            return items
                .map(id => String(id).trim())
                .filter(id => id && id !== "null" && id !== "undefined")
                .join(",");
        }

        function renderCreatePriority(p, skipSave = false) {
            currentCreatePriority = p;
            if (!skipSave) saveDraft();

            const $con = $("#create-priority-container");
            if (!$con.length) {
                console.warn("[Priority] Container not found, retrying...");
                setTimeout(() => renderCreatePriority(p, true), 200);
                return;
            }

            let htmlsection = "";
            for (let i = 1; i <= 3; i++) {
                const isActive = i <= p;
                htmlsection += `<i class="bi bi-star-fill priority-star ${isActive ? "active" : ""}" style="font-size: 1.5rem; cursor: pointer;" data-priority="${i}"></i>`;
            }
            $con.html(htmlsection);
            // Attach click handlers programmatically
            $con.find(".priority-star").off("click").on("click", function () {
                const pr = parseInt($(this).data("priority"), 10) || 1;
                renderCreatePriority(pr, false);
            });
        }

        // --- HÀM HỖ TRỢ FORMAT NGÀY DÙNG CHUNG ---
        function formatDateLocal(d) {
            if (!d) return null;
            const dateObj = (d instanceof Date) ? d : new Date(d);
            if (isNaN(dateObj.getTime())) return null;
            const year = dateObj.getFullYear();
            const month = String(dateObj.getMonth() + 1).padStart(2, "0");
            const day = String(dateObj.getDate()).padStart(2, "0");
            return `${year}-${month}-${day}`;
        }

        // --- HÀM HỖ TRỢ CHO HPACONTROLS ---
        function getInstanceByUID(uid) {
            // If it''s already an instance (has .option)
            if (window[uid] && typeof window[uid].option === "function") return window[uid];

            // Try finding by "Instance..." prefix
            const key = Object.keys(window).find(k => k.startsWith("Instance") && k.includes(uid));
            if (key && window[key] && typeof window[key].option === "function") return window[key];

            // Try getting from DOM if available
            const $el = $("#" + uid);
            if ($el.length) {
                const el = $el[0];
                const instance = DevExpress.ui.dxSelectBox.getInstance(el) ||
                    DevExpress.ui.dxTextBox.getInstance(el) ||
                    DevExpress.ui.dxDateBox.getInstance(el) ||
                    DevExpress.ui.dxTagBox.getInstance(el) ||
                    DevExpress.ui.dxNumberBox.getInstance(el) ||
                    DevExpress.ui.dxTextArea.getInstance(el) ||
                    DevExpress.ui.dxDataGrid.getInstance(el);
                if (instance) return instance;
            }

            return null;
        }

        function getInstanceValue(InstanceName) {
            const instance = getInstanceByUID(InstanceName);
            if (!instance) return null;

            if (typeof instance.getValue === "function") return instance.getValue();
            if (instance && typeof instance.option === "function") {
                return instance.option("value");
            }
            return null;
        }

        function setInstanceValue(InstanceName, val) {
            const setValueOp = (inst) => {
                if (typeof inst.setValue === "function") inst.setValue(val);
                else if (typeof inst.option === "function") inst.option("value", val);
            };

            const instance = getInstanceByUID(InstanceName);
            if (!instance) {
                // Try several times
                let retries = 0;
                const timer = setInterval(() => {
                    const retryInstance = getInstanceByUID(InstanceName);
                    if (retryInstance || retries > 5) {
                        if (retryInstance) setValueOp(retryInstance);

                        clearInterval(timer);
                    }
                    retries++;
                }, 200);
                return;
            }
            setValueOp(instance);
        }

        function init() {
            const $dynamicPane = $("#dynamic-pane-MnuAT001");
            if ($dynamicPane.length) $dynamicPane.removeClass("overflow-auto");

            window.InstancegridTasks = null;
            initSliders();

            LoadLookupData(function () {
                ReloadData();

                // Lọc bỏ các subtask đã có trong danh sách tìm gợi ý (P25F5CBFA3D854FFD8AC3C1984B5439FC)
                const subInst = (typeof getInstanceByUID === "function") ? getInstanceByUID("P25F5CBFA3D854FFD8AC3C1984B5439FC") : null;
                if (subInst) {
                    const originalOnDataSourceLoaded = subInst.option("onDataSourceLoaded");
                    subInst.option("onDataSourceLoaded", function (e) {
                        if (e.dataSource && e.dataSource.length > 0 && Array.isArray(window.pendingSubtasks)) {
                            const currentIds = window.pendingSubtasks.map(s => s.TemplateID || s.ExistingTaskID).filter(id => id > 0);
                            e.dataSource = e.dataSource.filter(item => !currentIds.includes(item.ID));
                        }
                        if (typeof originalOnDataSourceLoaded === "function") originalOnDataSourceLoaded.apply(this, arguments);
                    });
                }
            });
        }

        function LoadLookupData(callback) {
            AjaxHPAParadise({
                data: {
                    name: "sp_Task_GetLookupData",
                    param: [
                        "LoginID", LoginID,
                        "LanguageID", LanguageID
                    ]
                },
                success: function (res) {
                    try {
                        const json = (typeof res === "string" ? JSON.parse(res) : res);
                        const data = json.data?.[0]?.[0] || {};
                        employees = parseJson(data.Employees);
                        statusList = parseJson(data.Statuses);
                        tags = parseJson(data.Tags);
                        window.hpaIsAdminOrManager = (data.IsAdminOrManager == 1);

                        window.allFileTemp = json.data[1] || [];

                        window["DataSource_FileUrlTaskList"] = allFileTemp ? allFileTemp : [];
                        if (window.InstanceFileUrlTaskListPEBB780F668924A108C0A9FF20D70CD80) {
                            InstanceFileUrlTaskListPEBB780F668924A108C0A9FF20D70CD80.option("dataSource", window["DataSource_FileUrlTaskList"]);
                        }
                        currentUser = employees.find(e => String(e.LoginID) === String(LoginID));

                        window.statusMap = {};
                        statusList.forEach(s => {
                            window.statusMap[s.StatusID] = (s.StatusName || "").toLowerCase();
                        });

                        // Setup data sources cho các control
                        window["DataSource_StatusID"] = statusList.map(s => ({ StatusID: s.StatusID, StatusName: s.StatusName, Color: s.Color }));

                        window["DataSource_ApproverID"] = employees.map(e => ({
                            ID: String(e.EmployeeID),
                            Name: e.FullName,
                            Email: e.Email || "",
                            Position: e.Position || "",
                            storeImgName: e.StoreImgName || "",
                            paramImg: e.ImgParamV || ""
                        }));

                        window["DataSource_EmployeeFilter"] = employees.map(e => ({ EmployeeID: e.EmployeeID, FullName: e.FullName }));

                        // Cập nhật nhân viên cho các control (nếu có)
                        [
                            "PD76FE9F7E30A44A08B305AC908595419", // AssigneeID
                            "P0902358F935A441E868AADCB1DBFCF64", // MainAssigneeID
                            "P4386BF8B5C97415683E8B1F2FAA230DB", // Subtask Assignee
                            "P1257D8B184374728847FCB0CAEC1B7DB"  // RequestID
                        ].forEach(uid => {
                            const inst = getInstanceByUID(uid);
                            if (inst) inst.option("dataSource", employees);
                        });

                        // Safe updates for remaining controls
                        try {
                            if (window.InstanceP_Filter_EmployeeID) {
                                window.InstanceP_Filter_EmployeeID.option("dataSource", employees);
                            }
                            initAdvancedFilter();
                        } catch (e) { }

                        if (typeof callback === "function") callback();
                    } catch (e) {
                        console.error("Error in LoadLookupData", e);
                        if (typeof callback === "function") callback();
                    }
                }
            });
        }

        function initSliders() {
            updateSlider("view-switcher", $("#view-switcher .switcher-item.active"));
            updateSlider("filter-switcher", $("#filter-switcher .switcher-item.active"));
            if (window.innerWidth <= 767) {
                setTimeout(() => {
                    const $activeTab = $(".mb-tab-item.active");
                    const $activeView = $(".mb-view-item.active");
                    if ($activeTab.length) updateMobileSlider("mb-tab-track", $activeTab, "mb-tab-slider");
                    if ($activeView.length) updateMobileSlider("mb-view-toggle", $activeView, "mb-view-slider");
                }, 150);
            }
        }

        function updateSlider(containerId, $activeBtn) {
            if (!$activeBtn || !$activeBtn.length) return;
            const $container = $("#" + containerId);
            const $slider = $container.find(".tab-slider");
            const rect = $activeBtn[0].getBoundingClientRect();
            const containerRect = $container[0].getBoundingClientRect();
            $slider.css({
                width: rect.width + "px",
                left: (rect.left - containerRect.left) + "px"
            });
        }

        function updateMobileSlider(containerId, $activeBtn, sliderId) {
            const $btn = $activeBtn instanceof jQuery ? $activeBtn : $($activeBtn);
            if (!$btn.length) return;
            const $container = typeof containerId === "string" ? $("#" + containerId) : $(containerId);
            if (!$container.length) return;
            const $slider = $("#" + sliderId);
            if (!$slider.length) return;

            if (sliderId === "mb-tab-slider") {
                $slider.css({
                    width: $btn.outerWidth() + "px",
                    left: $btn[0].offsetLeft + "px"
                });
                const $wrap = $container.parent();
                if ($wrap.length) {
                    const scrollLeft = $btn[0].offsetLeft - ($wrap.outerWidth() / 2) + ($btn.outerWidth() / 2);
                    $wrap[0].scrollTo({ left: scrollLeft, behavior: "smooth" });
                }
            } else {
                const rect = $btn[0].getBoundingClientRect();
                const tRect = $container[0].getBoundingClientRect();
                $slider.css({
                    width: $btn.outerWidth() + "px",
                    left: (rect.left - tRect.left) + "px"
                });
            }
        }

        function setupEventListeners() {
            // View Switcher
            $("#btn-view-list").on("click", function (e) { switchView("list", this); });
            $("#btn-view-calendar").on("click", function (e) { switchView("calendar", this); });

            // Calendar Sub-views
            $("#btn-cal-day").on("click", function (e) { switchCalendarView("day", this); });
            $("#btn-cal-week").on("click", function (e) { switchCalendarView("week", this); });
            $("#btn-cal-month").on("click", function (e) { switchCalendarView("month", this); });

            // Filter Switcher
            $("#btn-filter-all").on("click", function (e) { setMyTaskFilter("all", this); });
            $("#btn-filter-doing").on("click", function (e) { setMyTaskFilter("doing", this); });
            $("#btn-filter-assigned").on("click", function (e) { setMyTaskFilter("assigned", this); });
            $("#btn-filter-main").on("click", function (e) { setMyTaskFilter("main", this); });
            $("#btn-filter-review").on("click", function (e) { setMyTaskFilter("review", this); });
            $("#btn-filter-recent").on("click", function (e) { setMyTaskFilter("recent", this); });

            // Search bar in toolbar
            const $ttvSearchInput = $("#ttv-search-input");
            if ($ttvSearchInput.length) {
                let ttvSearchTimer = null;
                $ttvSearchInput.on("input", function () {
                    clearTimeout(ttvSearchTimer);
                    ttvSearchTimer = setTimeout(() => {
                        ttvSearch = $(this).val().trim();
                        ReloadData();
                    }, 280);
                });
                // Xóa search khi nhấn Escape
                $ttvSearchInput.on("keydown", function (e) {
                    if (e.key === "Escape") {
                        $(this).val("");
                        ttvSearch = "";
                        ReloadData();
                    }
                });
            }

            // Reload button
            $("#btn-ttv-reload").on("click", function () {
                const $btn = $(this);
                $btn.addClass("spinning");
                setTimeout(() => $btn.removeClass("spinning"), 650);
                ReloadData();
            });

            // Create Modal
            $("#btn-add-total-task, #mb-btn-add-task").on("click", function () { openCreateTaskModalTaskList(); });
            $("#btn-close-modal-x, #btn-cancel-create").on("click", closeCreateModal);
            $("#btn-reset-create").on("click", function () {
                resetModalForm();
                saveDraft();
            });
            $("#btn-submit-create").on("click", submitCreateTask);

            // ===== Checklist & Modal Events – dùng Event Delegation trên container form để tránh xung đột với form khác =====
            const $listRoot = $("#sp_Task_TaskList_html");

            $listRoot
                .off("click.checklistLabelList")
                .on("click.checklistLabelList", "#label-checklist-toggle-list", function (e) {
                    if ($(e.target).closest("#btn-toggle-checklist_list").length) return;

                    const $content = $("#checklist-body-content_list");
                    const showAndFocus = () => {
                        const $addBoxWrapper = $("#checklist-add-box-wrapper");
                        $addBoxWrapper.show().css("display", "flex");
                        setTimeout(() => $("#checklist-add-input").focus(), 50);
                    };

                    if ($content.css("display") === "none") {
                        $("#checklist-chevron").css("transform", "rotate(0deg)");
                        $content.slideDown(250, showAndFocus);
                    } else {
                        showAndFocus();
                    }
                });

            $listRoot
                .off("click.checklistToggleList")
                .on("click.checklistToggleList", "#btn-toggle-checklist_list", function () {
                    const $content = $("#checklist-body-content_list");
                    const $chevron = $("#checklist-chevron");
                    const isHidden = $content.css("display") === "none";

                    if (isHidden) {
                        $chevron.css("transform", "rotate(0deg)");
                        $content.slideDown(250);
                    } else {
                        $chevron.css("transform", "rotate(-90deg)");
                        $content.slideUp(250);
                    }
                });

            $listRoot
                .off("click.checklistAddList")
                .on("click.checklistAddList", "#btn-add-checklist-item", function () { addChecklistItem(); });

            $listRoot
                .off("keypress.checklistInputList")
                .on("keypress.checklistInputList", "#checklist-add-input", function (e) {
                    if (e.key === "Enter") addChecklistItem();
                });

            // Toggle Description & Attachments in Create Modal
            $listRoot
                .off("click.toggleDescList")
                .on("click.toggleDescList", "#btn-toggle-description", function () {
                    $("#description-container").toggleClass("d-none");
                });

            $listRoot
                .off("click.addSubtaskManualList")
                .on("click.addSubtaskManualList", "#btn-add-subtask-manual", function () {
                    addSubtaskManual();
                });

            // Mobile Sidebar Actions
            $listRoot
                .off("click.drawerApprovalMb")
                .on("click.drawerApprovalMb", "#btn-drawer-approval-mb", function () { $("#btn-drawer-approval").click(); });
            $listRoot
                .off("click.drawerRepeatMb")
                .on("click.drawerRepeatMb", "#btn-drawer-repeat-mb", function () { $("#btn-drawer-repeat").click(); });

            // Preview popover close (use local function)
            $("#task-preview-popover .preview-close").on("click", closeTaskPreview);

            initMobileToolbar();

            // Fix mobile: đảm bảo DevExtreme overlay thoát khỏi modal
            setTimeout(() => {
                if (typeof DevExpress !== "undefined") {
                    DevExpress.ui.dxOverlay.baseZIndex(2000);
                }
                // Patch: force DevExtreme dropdowns thoát overflow nếu cần
                const dxUIDs = [
                    "P279678A95C514D7B815B1B357824875D",
                    "PD76FE9F7E30A44A08B305AC908595419",
                    "P3F6E55934BF74079A3EBA78D91296EE0",
                    "P1257D8B184374728847FCB0CAEC1B7DB",
                    "P0902358F935A441E868AADCB1DBFCF64",
                    "P136F0762551345078797DB3CC80DA470"
                ];
                dxUIDs.forEach(uid => {
                    try {
                        const inst = getInstanceByUID(uid);
                        if (inst && typeof inst.option === "function") {
                            inst.option("dropDownOptions", {
                                shading: true,
                                shadingColor: "transparent",
                                closeOnOutsideClick: true
                            });
                        }
                    } catch (e) { }
                });
            }, 1500);
        }

        function initMobileToolbar() {
            const $mbSearch = $("#mb-search-input");
            const $mbClear = $("#mb-search-clear");
            const $desktopSearch = $("#ttv-search-input");

            function toggleClearBtn() {
                if ($mbClear.length) $mbClear.css("display", ($mbSearch.length && $mbSearch.val()) ? "block" : "none");
            }

            if ($mbSearch.length) {
                let mbTimer = null;
                $mbSearch.on("input", function () {
                    toggleClearBtn();
                    clearTimeout(mbTimer);
                    mbTimer = setTimeout(() => {
                        ttvSearch = $(this).val().trim();
                        if ($desktopSearch.length) $desktopSearch.val(ttvSearch);
                        ReloadData();
                    }, 400);
                });
            }

            if ($mbClear.length) {
                $mbClear.on("click", function () {
                    if ($mbSearch.length) {
                        $mbSearch.val("").focus();
                        toggleClearBtn();
                        ttvSearch = "";
                        if ($desktopSearch.length) $desktopSearch.val("");
                        ReloadData();
                    }
                });
            }
            $("#mb-filter-btn").on("click", function (e) {
                e.stopPropagation();
                if (typeof window.openDropdown === "function") {
                    window.openDropdown();
                } else {
                    const $desktopBtn = $("#btn-filter-advanced");
                    if ($desktopBtn.length) $desktopBtn.trigger("click");
                }
            });

            // Header Plus Button Pattern
            const mobileOS = (typeof getMobileOperatingSystem === "function")
                ? getMobileOperatingSystem()
                : (window.getMobileOperatingSystem?.() || "");

            if (["Android", "iOS"].includes(mobileOS)) {
                const $header = $("#header_sp_Task_TaskList");
                if ($header.length && !$header.find(".back-btn.m-0").length) {
                    $("<button/>", {
                        class: "back-btn m-0",
                        html: `<i class="bi bi-plus-lg"></i>`,
                        on: {
                            click: function () {
                                if (typeof openCreateTaskModalTaskList === "function") {
                                    openCreateTaskModalTaskList(currentViewParentID || 0);
                                }
                            }
                        }
                    }).appendTo($header);
                }
            }

            $(".mb-tab-item").on("click", function () {
                if ($(this).hasClass("active")) return;
                const val = $(this).data("value");
                const $desktopBtn = $("#btn-filter-" + val);
                $(".mb-tab-item").removeClass("active");
                $(this).addClass("active");
                updateMobileSlider("mb-tab-track", $(this), "mb-tab-slider");

                renderSkeleton(currentView);
                setTimeout(() => {
                    if ($desktopBtn.length) setMyTaskFilter(val, $desktopBtn[0]);
                    hideSkeleton();
                }, 300);
            });

            $(".mb-view-item").on("click", function () {
                if ($(this).hasClass("active")) return;
                const view = $(this).data("view");
                const $desktopBtn = $("#" + (view === "list" ? "btn-view-list" : "btn-view-calendar"));

                $(".mb-view-item").removeClass("active");
                $(this).addClass("active");
                updateMobileSlider("mb-view-toggle", $(this), "mb-view-slider");

                renderSkeleton(view);
                setTimeout(() => {
                    if ($desktopBtn.length) switchView(view, $desktopBtn[0]);
                    hideSkeleton();
                }, 300);
            });

            $("#mb-reload-btn").on("click", function () {
                $("#btn-ttv-reload").click();
                const $icon = $(this).find("i");
                $icon.css({ transition: "transform 0.6s ease", transform: "rotate(360deg)" });
                setTimeout(() => { $icon.css({ transition: "none", transform: "rotate(0deg)" }); }, 650);
            });

            // Cập nhật badge filter nếu có function global (tùy chọn)
            if (typeof window._updateMbFilterBadge !== "function") {
                window._updateMbFilterBadge = () => {
                    const n = (selectedProjectIDs.length > 0 ? 1 : 0)
                        + (selectedStatusIDs.length > 0 ? 1 : 0)
                        + (selectedTagIDs.length > 0 ? 1 : 0)
                        + (selectedPriorityFilters.length > 0 ? 1 : 0)
                        + (selectedEmployeeIDs.length > 0 ? 1 : 0)
                        + (selectedDueDateFilter ? 1 : 0);
                    const $badge = $("#mb-filter-badge");
                    const $btn = $("#mb-filter-btn");
                    if ($badge.length) $badge.css("display", n > 0 ? "block" : "none");
                    if ($btn.length) $btn.toggleClass("has-filter", n > 0);
                };
            }
        }

        let _isCheckingPermissionList = false;
        function openDetailHistoryID(historyID, parentHistoryID = 0, parentTaskID = 0) {
            if (historyID === 0) { openCreateTaskModalTaskList(parentHistoryID, parentTaskID); return; }
            if (_isCheckingPermissionList) return;

            _isCheckingPermissionList = true;

            // Permission check trước khi mở form
            AjaxHPAParadise({
                data: {
                    name: "sp_Task_CheckPermission",
                    param: ["LoginID", LoginID, "HistoryID", historyID]
                },
                success: function (res) {
                    _isCheckingPermissionList = false;
                    const json = typeof res === "string" ? JSON.parse(res) : res;
                    const dataPermission = json?.data?.[0]?.[0] || {};

                    if (dataPermission.HasPermission === 1) {
                        const params = { HistoryID: historyID, LoginID: LoginID, LanguageID: LanguageID };
                        if (["Android", "iOS"].includes(window.getMobileOperatingSystem?.() || "")) {
                            window.OpenFormParamMobile("sp_Task_TaskDetail", params);
                        } else {
                            window.openFormParam("sp_Task_TaskDetail", params);
                        }
                    } else {
                        uiManager.showAlert({ type: "warning", message: "%NoPermissionViewContent%" });
                    }
                },
                error: function (err) {
                    _isCheckingPermissionList = false;
                    console.error("Permission check error:", err);
                    uiManager.showAlert({ type: "error", message: "%disconectServer%" });
                }
            });
        }

        function openCreateTaskModalTaskList(parentHistoryId = 0, parentTaskId = 0) {
            if (window.activeDraftHistoryID > 0 && !window.isSavedSuccessfully) {
                if (currentParentId === parentHistoryId && currentParentTaskId === (parentTaskId || 0)) {
                    const draftStr = localStorage.getItem("taskCreateDraft");
                    if (draftStr) {
                        try {
                            const draft = JSON.parse(draftStr);
                            if (draft && draft.activeDraftHistoryID === window.activeDraftHistoryID) {
                                proceedOpenCreateModal(parentHistoryId, parentTaskId);
                                applyDraftData(draft);
                                return;
                            }
                        } catch (e) { }
                    }
                    proceedOpenCreateModal(parentHistoryId, parentTaskId);
                    return;
                }
            }

            const draftStr = localStorage.getItem("taskCreateDraft");
            if (draftStr) {
                try {
                    const draft = JSON.parse(draftStr);
                    const draftAge = new Date() - new Date(draft.timestamp);
                    if (draftAge < 24 * 60 * 60 * 1000 && draft.activeDraftHistoryID) {
                        window.activeDraftHistoryID = draft.activeDraftHistoryID;
                        window.activeDraftTaskID = draft.activeDraftTaskID;
                        window.currentRecordID_HistoryID = draft.activeDraftHistoryID;
                        window.currentRecordID_Temp_HistoryID = window.currentRecordID_HistoryID;
                        window.isSavedSuccessfully = false;
                        window.createTaskSessionUID = draft.sessionUID || generateUUID();
                        resetModalForm();
                        proceedOpenCreateModal(parentHistoryId, parentTaskId);
                        applyDraftData(draft);
                        return;
                    }

                    // Nếu lọt xuống đây (không return ở trên) thì do bản nháp đã quá hạn 24H hoặc thiếu hàm hiển thị confirm
                    if (draft && draft.activeDraftHistoryID && draft.activeDraftHistoryID > 0) {
                        if (typeof AjaxHPAParadise === "function") {
                            AjaxHPAParadise({
                                data: { name: "sp_Task_Delete", param: ["HistoryID", draft.activeDraftHistoryID, "LoginID", (typeof LoginID !== "undefined" ? LoginID : 0)] }
                            });
                        }
                    }
                    clearDraft(); // Dọn dẹp local storage
                } catch (e) { clearDraft(); }
            }
            createNewDraft(parentHistoryId, parentTaskId);
        }

        function createNewDraft(parentHistoryId = 0, parentTaskId = 0) {
            if (window.activeDraftHistoryID > 0) {
                resetModalForm();
                proceedOpenCreateModal(parentHistoryId, parentTaskId);
                return;
            }
            const currentEmpID = currentUser ? String(currentUser.EmployeeID) : null;
            AjaxHPAParadise({
                data: {
                    name: "sp_Task_Save",
                    param: ["StatusID", 0, "RequestID", currentEmpID, "ParentTaskID", parentTaskId || null, "ParentHistoryID", parentHistoryId || null, "LoginID", LoginID, "SessionUID", window.createTaskSessionUID = generateUUID()]
                },
                success: function (res) {
                    const data = (typeof res === "string" ? JSON.parse(res) : res).data?.[0]?.[0] || {};
                    if (data.Status === "SUCCESS") {
                        window.activeDraftHistoryID = data.NewHistoryID;
                        window.activeDraftTaskID = data.NewTaskID;
                        window.currentRecordID_HistoryID = data.NewHistoryID;
                        window.currentRecordID_Temp_HistoryID = window.currentRecordID_HistoryID
                        window.isSavedSuccessfully = false;
                        resetModalForm();
                        proceedOpenCreateModal(parentHistoryId, parentTaskId);
                    } else {
                        uiManager.showAlert({ type: "error", message: "Không thể khởi tạo công việc nháp." });
                    }
                },
                error: function () {
                    uiManager.showAlert({ type: "error", message: "Lỗi kết nối máy chủ khi tạo nháp." });
                }
            });
        }

        function proceedOpenCreateModal(parentHistoryId = 0, parentTaskId = 0) {
            window._mainAssigneeManuallySet = false;
            window._noManagerWarning = false;
            window.tempApprovalUserEdited = false;
            currentParentId = parentHistoryId;
            currentParentTaskId = parentTaskId || 0;
            const $modal = $("#create-task-modal");
            $modal.css("display", "flex");
            requestAnimationFrame(() => $modal.addClass("active"));

            if (currentUser) {
                $("#user-req-name").text(currentUser.EmployeeName || "");
                const avatar = currentUser.Avatar || "https://ui-avatars.com/api/?name=" + encodeURIComponent(currentUser.EmployeeName || "U");
                $("#user-req-avatar").attr("src", avatar);
            }

            if (typeof setupAssigneeControl === "function") setupAssigneeControl();
            if (typeof setupProjectControl === "function") setupProjectControl();
            if (typeof setupTagControl === "function") setupTagControl();
            if (typeof setupDateControl === "function") setupDateControl();
            if (typeof setupOwnerControl === "function") setupOwnerControl();
            if (typeof setupMainAssigneeControl === "function") setupMainAssigneeControl();

            if (typeof attachAutoSaveListeners === "function") attachAutoSaveListeners();
            if (!window._draftBeforeUnloadBound) {
                window.addEventListener("beforeunload", function () {
                    if ($("#create-task-modal").hasClass("active")) saveDraft();
                });
                window._draftBeforeUnloadBound = true;
            }
            if (!window._draftAutoSaveInterval) {
                window._draftAutoSaveInterval = setInterval(function () {
                    if ($("#create-task-modal").hasClass("active")) saveDraft();
                }, 400);
            }

            // Move controls back to their containers based on mobile/desktop
            const isMbVisible = window.innerWidth < 768;
            if (!isMbVisible) {
                // Move to desktop sidebar
                $("#P1257D8B184374728847FCB0CAEC1B7DB").appendTo("#requester-desktop-slot");
                $("#P0902358F935A441E868AADCB1DBFCF64").appendTo("#main-assignee-desktop-slot");
            } else {
                // Stay or move back to mobile grid (they are there by default now)
                const $mbReq = $("#P1257D8B184374728847FCB0CAEC1B7DB");
                const $mbMain = $("#P0902358F935A441E868AADCB1DBFCF64");
                // Just in case they were moved to desktop slot earlier
                if (!$mbReq.closest("#mobile-only-sidebar-content").length) {
                    $mbReq.appendTo($("#mobile-only-sidebar-content").find(".task-info-icon .bi-person-up").closest(".task-info-card").find(".task-info-details"));
                }
            }

            const projectInstance = getInstanceByUID("P279678A95C514D7B815B1B357824875D");
            const assigneeInstance = getInstanceByUID("PD76FE9F7E30A44A08B305AC908595419");
            const requesterInstance = getInstanceByUID("P1257D8B184374728847FCB0CAEC1B7DB");
            const mainAssigneeInstance = getInstanceByUID("P0902358F935A441E868AADCB1DBFCF64");

            if (parentHistoryId) {
                $("#create-modal-title").text("%CreateSubtask%");
                const parent = allTasks.find(t => t.HistoryID === parentHistoryId);
                if (parent) {
                    if (projectInstance) projectInstance.option("value", parent.ProjectID);
                    setInstanceValue("P1D812C8523D54ECFB8BDE98FE5E7EF98", parent.DueDate);
                    if (requesterInstance) requesterInstance.option("value", parent.RequestID);
                    if (mainAssigneeInstance) mainAssigneeInstance.option("value", parent.MainAssigneeID ? String(parent.MainAssigneeID).padStart(3, "0") : null);
                }
                $("#modal-right-sidebar-create, #project-card-create, #create-priority-container").addClass("d-none");
            } else {
                $("#create-modal-title").text("%CreateTask%");
                $("#modal-right-sidebar-create, #project-card-create, #create-priority-container").removeClass("d-none");
                if (requesterInstance) requesterInstance.option("value", currentUser ? currentUser.EmployeeID : null);
            }
        }

        function saveDraft() {
            if (window.isDraftClosing || window.isSavedSuccessfully || !window.activeDraftHistoryID) return;
            try {
                const draft = {
                    activeDraftHistoryID: window.activeDraftHistoryID, activeDraftTaskID: window.activeDraftTaskID,
                    taskName: getInstanceValue("P63128D34B83D4F9EA7BEB928C35C7CF7"), project: getInstanceValue("P279678A95C514D7B815B1B357824875D"),
                    assigneeId: getInstanceValue("PD76FE9F7E30A44A08B305AC908595419"), mainAssigneeId: getInstanceValue("P0902358F935A441E868AADCB1DBFCF64"),
                    requestId: getInstanceValue("P1257D8B184374728847FCB0CAEC1B7DB"), priority: currentCreatePriority,
                    dueDate: getInstanceValue("P1D812C8523D54ECFB8BDE98FE5E7EF98"), tagId: getInstanceValue("P3F6E55934BF74079A3EBA78D91296EE0"),
                    pendingSubtasks: pendingSubtasks, pendingChecklist: pendingChecklist,
                    recurrence: tempRecurrenceSettings, approval: tempApprovalSettings,
                    approvalUserEdited: !!window.tempApprovalUserEdited, templateID: window.lastSelectedTemplateID,
                    templateName: window.lastSelectedTemplateName,
                    sessionUID: window.createTaskSessionUID,
                    timestamp: new Date().toISOString()
                };
                localStorage.setItem("taskCreateDraft", JSON.stringify(draft));
            } catch (e) { console.error("%CannotSaveDraft%:", e); }
        }

        function clearDraft() {
            localStorage.removeItem("taskCreateDraft");
            if (window.draftSaveTimeout) { clearTimeout(window.draftSaveTimeout); window.draftSaveTimeout = null; }
        }

        function updateRecurrenceUI(settings) {
            const $btnRec = $("#btn-drawer-repeat, #btn-drawer-repeat-mb");

            if (!$btnRec.length) return;
            if (settings) {
                $btnRec.addClass("active").html('' < i class= "bi bi-check-circle-fill" ></i > % RepeatConfigured % '');
            } else {
                $btnRec.removeClass("active").html('' < i class= "bi bi-arrow-repeat" ></i > % Repeat % '');
            }
        }

        function updateApprovalUI(settings) {
            const $btnApp = $("#btn-drawer-approval, #btn-drawer-approval-mb");
            if (!$btnApp.length) return;
            if (settings && settings.RequireApproval) {
                $btnApp.addClass("active").css("color", "#d97706");
                const stageCount = (settings.Stages || []).length;
                let text = window.LanguageID === "VN" ? `Duyệt ${stageCount > 1 ? stageCount + " cấp" : "1 người"}` : `Approval ${stageCount > 1 ? stageCount + " levels" : "1 person"}`;
                if (settings.Note === "%AutoActivatedNotInTemplate%") text += " (Auto)";
                $btnApp.html(`<i class="bi bi-check-circle-fill"></i> ${text}`);
            } else {
                $btnApp.removeClass("active").css("color", "").html(`<i class="bi bi-person-check"></i> ${window.LanguageID === "VN" ? "Phê duyệt" : "Approval"}`);
            }
        }

        function applyDraftData(draft) {
            if (!draft) return;
            window.isRestoringDraft = true;
            try {
                setInstanceValue("P63128D34B83D4F9EA7BEB928C35C7CF7", draft.taskName);
                setInstanceValue("P279678A95C514D7B815B1B357824875D", draft.project);
                setInstanceValue("PD76FE9F7E30A44A08B305AC908595419", draft.assigneeId);
                setInstanceValue("P0902358F935A441E868AADCB1DBFCF64", draft.mainAssigneeId);
                setInstanceValue("P1257D8B184374728847FCB0CAEC1B7DB", draft.requestId);
                currentCreatePriority = draft.priority || 2;
                renderCreatePriority(currentCreatePriority, true);
                setInstanceValue("P1D812C8523D54ECFB8BDE98FE5E7EF98", draft.dueDate);
                setInstanceValue("P3F6E55934BF74079A3EBA78D91296EE0", draft.tagId);
                if (draft.pendingSubtasks) { pendingSubtasks = draft.pendingSubtasks; renderPendingSubtasks(); }
                if (draft.pendingChecklist) { pendingChecklist = draft.pendingChecklist; renderChecklist(window.activeDraftHistoryID || 0); }
                tempRecurrenceSettings = draft.recurrence; tempApprovalSettings = draft.approval;
                window.tempApprovalUserEdited = !!draft.approvalUserEdited;
                window.lastSelectedTemplateID = draft.templateID; window.lastSelectedTemplateName = draft.templateName;
                if (typeof updateRecurrenceUI === "function" && tempRecurrenceSettings) updateRecurrenceUI(tempRecurrenceSettings);
                if (typeof updateApprovalUI === "function" && tempApprovalSettings) updateApprovalUI(tempApprovalSettings);
            } finally { setTimeout(() => { window.isRestoringDraft = false; }, 500); }
        }

        function attachAutoSaveListeners() {
            const $modal = $("#create-task-modal");
            if (!$modal.length) return;
            $modal.find("input, textarea, select").off("input change", scheduleDraftSave).on("input change", scheduleDraftSave);
        }

        window.draftSaveTimeout = null;
        function scheduleDraftSave() {
            clearTimeout(window.draftSaveTimeout); window.draftSaveTimeout = setTimeout(saveDraft, 400);
        }

        function closeCreateModal(isSaveSuccessful) {
            const hasValue = (val) => {
                if (val === null || val === undefined) return false;
                if (Array.isArray(val)) return val.length > 0;
                if (typeof val === "number") return val > 0;
                if (typeof val === "string") {
                    const str = val.trim();
                    return str !== "" && str !== "0";
                }
                return true;
            };

            const isDraftEmpty = () => {
                const checks = [
                    getInstanceValue("P63128D34B83D4F9EA7BEB928C35C7CF7"),
                    getInstanceValue("P279678A95C514D7B815B1B357824875D"),

                    getInstanceValue("PD76FE9F7E30A44A08B305AC908595419"),
                    getInstanceValue("P0902358F935A441E868AADCB1DBFCF64"),
                    getInstanceValue("P1D812C8523D54ECFB8BDE98FE5E7EF98"),
                    getInstanceValue("P3F6E55934BF74079A3EBA78D91296EE0"),
                    getInstanceValue("P136F0762551345078797DB3CC80DA470")
                ];

                if (checks.some(hasValue)) return false;
                if (Array.isArray(pendingSubtasks) && pendingSubtasks.length > 0) return false;
                if (Array.isArray(pendingChecklist) && pendingChecklist.length > 0) return false;
                if (tempRecurrenceSettings || tempApprovalSettings) return false;
                if (window.lastSelectedTemplateID) return false;
                return true;
            };

            const finalClose = () => {
                window.isDraftClosing = true;
                clearTimeout(window.draftSaveTimeout);
                if (window._draftAutoSaveInterval) {
                    clearInterval(window._draftAutoSaveInterval);
                    window._draftAutoSaveInterval = null;
                }
                window.isSavedSuccessfully = false;
                $("#create-task-modal").removeClass("active");
                setTimeout(() => {
                    $("#create-task-modal").css("display", "");
                    window.isDraftClosing = false;
                }, 400);
            };

            if (isSaveSuccessful === true) {
                window.isSavedSuccessfully = true;
                clearDraft();
                window.activeDraftHistoryID = 0;
                window.activeDraftTaskID = 0;
                finalClose();
                return;
            }

            const closeWithSave = () => {
                saveDraft();
                finalClose();
            };

            const closeWithoutSave = () => {
                const oldDraftID = window.activeDraftHistoryID;
                clearDraft();
                if (oldDraftID && !isNaN(oldDraftID) && oldDraftID > 0) {
                    if (typeof AjaxHPAParadise === "function") {
                        AjaxHPAParadise({
                            data: { name: "sp_Task_Delete", param: ["HistoryID", oldDraftID, "LoginID", (typeof LoginID !== "undefined" ? LoginID : 0)] }
                        });
                    }
                }
                window.activeDraftHistoryID = 0;
                window.activeDraftTaskID = 0;
                finalClose();
            };

            if (isDraftEmpty()) {
                closeWithoutSave();
                return;
            }

            if (typeof showConfirmPopup === "function") {
                showConfirmPopup({
                    title: "Lưu bản nháp",
                    message: "Bạn có muốn lưu lại thông tin nháp không?",
                    onYes: closeWithSave,
                    onNo: closeWithoutSave
                });
            } else {
                const ok = window.confirm("Bạn có muốn lưu lại thông tin nháp không?");
                ok ? closeWithSave() : closeWithoutSave();
            }
        }

        function resetModalForm() {
            setInstanceValue("P63128D34B83D4F9EA7BEB928C35C7CF7", "");
            setInstanceValue("P279678A95C514D7B815B1B357824875D", null);
            setInstanceValue("PD76FE9F7E30A44A08B305AC908595419", null);
            setInstanceValue("P0902358F935A441E868AADCB1DBFCF64", null);
            setInstanceValue("P1D812C8523D54ECFB8BDE98FE5E7EF98", null);
            $("#P1D812C8523D54ECFB8BDE98FE5E7EF98 input").val("");

            setInstanceValue("P3F6E55934BF74079A3EBA78D91296EE0", null);

            setInstanceValue("P136F0762551345078797DB3CC80DA470", null);
            $("#P136F0762551345078797DB3CC80DA470 input").val("");

            setInstanceValue("PDADFE6D548FF40EE8109B030B5B31AE9", "");
            $("#PDADFE6D548FF40EE8109B030B5B31AE9 textarea, #PDADFE6D548FF40EE8109B030B5B31AE9 input").val("");
            $("#description-container").addClass("d-none");

            pendingSubtasks = [];
            pendingChecklist = [];
            tempRecurrenceSettings = null;
            tempApprovalSettings = null;
            window.tempApprovalUserEdited = false;
            window.lastSelectedTemplateID = null;

            renderPendingSubtasks();
            renderChecklist(window.activeDraftHistoryID || 0);
            if (typeof updateRecurrenceUI === "function") updateRecurrenceUI(null);
            if (typeof updateApprovalUI === "function") updateApprovalUI(null);
            renderCreatePriority(2, true);
            const instFile = getInstanceByUID("PEBB780F668924A108C0A9FF20D70CD80");
            if (instFile) {
                // Reset chuẩn cho dxFileUploader
                if (typeof instFile.reset === "function") {
                    instFile.reset();
                }
                // Clear value và dataSource
                if (typeof instFile.option === "function") {
                    instFile.option("value", []);
                    instFile.option("dataSource", []);
                }
            }
            // Dọn dẹp biến global lưu file tạm của hệ thống để không bị dính file cũ
            window.allFileTemp = [];
            window["DataSource_FileUrlTaskList"] = [];
        }

        function submitCreateTask() {
            // [FIX] Hàm highlight field bắt buộc khi chưa nhập
            function highlightRequiredField(uid, containerSelector) {
                const $el = containerSelector ? $(containerSelector) : $("#" + uid);
                if (!$el.length) return;
                $el.addClass("field-required-error");
                if (!$("#hpa-required-field-style-list").length) {
                    $("<style id=''hpa-required-field-style-list''>").html(`
             @keyframes hpaShakeField {
       0%,100%{transform:translateX(0)}
                    15%{transform:translateX(-6px)}
                                30%{transform:translateX(6px)}
                              45%{transform:translateX(-5px)}
                                60%{transform:translateX(5px)}

        75%{transform:translateX(-3px)}
                                90%{transform:translateX(3px)}
                            }
                            .field-required-error .dx-texteditor
                            .field-required-error {
                                border-radius: 6px;
                                animation: hpaShakeField 0.45s ease;
                            }
                        `).appendTo("head");
                }
                const inst = getInstanceByUID(uid);
                if (inst && typeof inst.focus === "function") {
                    setTimeout(() => inst.focus(), 50);
                } else {
                    $el.find("input").first().focus();
                }
                setTimeout(() => $el.removeClass("field-required-error"), 3000);
                if (inst && typeof inst.option === "function") {
                    const origChanged = inst.option("onValueChanged");
                    inst.option("onValueChanged", function (e) {
                        $el.removeClass("field-required-error");
                        inst.option("onValueChanged", origChanged);
                        if (typeof origChanged === "function") origChanged.call(this, e);
                    });
                }
            }

            // Chặn spam submit
            const $btnSubmit = $("#btn-submit-create");
            if (window.isSubmittingTask) return;
            window.isSubmittingTask = true;

            if ($btnSubmit.length) {
                $btnSubmit.prop("disabled", true);
                $btnSubmit.html('' < i class= "bi bi-hourglass-split me-2" ></i > % Loading %...'');
            }

            const name = getInstanceValue("P63128D34B83D4F9EA7BEB928C35C7CF7");
            if (!name || (typeof name === "string" && !name.trim())) {
                uiManager.showAlert({ type: "warning", message: "%TaskNameRequired%" });
                highlightRequiredField("P63128D34B83D4F9EA7BEB928C35C7CF7", "#P63128D34B83D4F9EA7BEB928C35C7CF7");
                window.isSubmittingTask = false;
                if ($btnSubmit.length) {
                    $btnSubmit.prop("disabled", false);
                    $btnSubmit.html('' < i class= "bi bi-send-check me-2" ></i > % AddNew % '');
                }
                return;
            }

            const project = getInstanceValue("P279678A95C514D7B815B1B357824875D");
            let assigneeId = formatIDList(getInstanceValue("PD76FE9F7E30A44A08B305AC908595419"));
            let mainAssigneeId = formatIDList(getInstanceValue("P0902358F935A441E868AADCB1DBFCF64"));
            let requestId = formatIDList(getInstanceValue("P1257D8B184374728847FCB0CAEC1B7DB"));
            let tagId = getInstanceValue("P3F6E55934BF74079A3EBA78D91296EE0");

            // Đảm bảo không có dấu phẩy thừa ở đầu/cuối
            assigneeId = assigneeId ? assigneeId.replace(/^,+|,+$/g, "") : null;
            mainAssigneeId = mainAssigneeId ? mainAssigneeId.replace(/^,+|,+$/g, "") : null;
            requestId = requestId ? requestId.replace(/^,+|,+$/g, "") : null;

            // Auto-fill MainAssigneeID with first Assignee if empty
            if (!mainAssigneeId && assigneeId) {
                mainAssigneeId = assigneeId.split(",")[0];
            }

            if (!assigneeId) {
                uiManager.showAlert({ type: "warning", message: "%AssigneeRequired%" });
                highlightRequiredField("PD76FE9F7E30A44A08B305AC908595419", "#PD76FE9F7E30A44A08B305AC908595419");
                window.isSubmittingTask = false;
                if ($btnSubmit.length) {
                    $btnSubmit.prop("disabled", false);
                    $btnSubmit.html('' < i class= "bi bi-send-check me-2" ></i > % AddNew % '');
                }
                return;
            }

            if (!isMobile() && !currentParentId && !project) {
                uiManager.showAlert({ type: "warning", message: "%ProjectRequired%" });
                highlightRequiredField("P279678A95C514D7B815B1B357824875D", "#P279678A95C514D7B815B1B357824875D");
                window.isSubmittingTask = false;
                if ($btnSubmit.length) {
                    $btnSubmit.prop("disabled", false);
                    $btnSubmit.html('' < i class= "bi bi-send-check me-2" ></i > % AddNew % '');
                }
                return;
            }

            if (mainAssigneeId !== null && mainAssigneeId !== undefined) {
                mainAssigneeId = String(mainAssigneeId).padStart(3, "0");
            }

            // Mặc định RequestID = EmployeeID của người tạo nếu không chọn
            if (!requestId && currentUser && currentUser.EmployeeID) {
                requestId = String(currentUser.EmployeeID);
            }

            const priority = currentCreatePriority || 2;
            const dueDate = getInstanceValue("P1D812C8523D54ECFB8BDE98FE5E7EF98");

            const standardTime = getInstanceValue("P136F0762551345078797DB3CC80DA470") || 0;

            if ((!pendingSubtasks || pendingSubtasks.length === 0) && (parseFloat(standardTime) || 0) <= 0) {
                uiManager.showAlert({ type: "warning", message: "%EnterStandardTime%" });
                highlightRequiredField("P136F0762551345078797DB3CC80DA470", "#P136F0762551345078797DB3CC80DA470");
                window.isSubmittingTask = false;
                if ($btnSubmit.length) {
                    $btnSubmit.prop("disabled", false);
                    $btnSubmit.html('' < i class= "bi bi-send-check me-2" ></i > % AddNew % '');
                }
                return;
            }

            let finalStandardTime = standardTime || 0;

            if (pendingSubtasks && pendingSubtasks.length > 0) {
                finalStandardTime = pendingSubtasks.reduce((sum, s) => sum + (parseFloat(s.StandardTime) || 0), 0);
            }

            const taskNameInstance = getInstanceByUID("P63128D34B83D4F9EA7BEB928C35C7CF7");
            const sourceTaskIDFromControl = taskNameInstance && typeof taskNameInstance.getSelectedID === "function"
                ? taskNameInstance.getSelectedID()
                : null;

            // --- LOGIC PHÊ DUYỆT TỰ ĐỘNG ---
            // Điều kiện: Task cha không từ mẫu HOẶC có ít nhất 1 task con không từ mẫu

            if (window._noManagerWarning && !window.tempApprovalUserEdited) {
                uiManager.showAlert({ type: "warning", message: "Người thực hiện chưa có quản lý trực tiếp. Không thể tạo công việc. Vui lòng chọn người thực hiện khác hoặc cấu hình người duyệt thủ công." });
                window.isSubmittingTask = false;
                if ($btnSubmit.length) {
                    $btnSubmit.prop("disabled", false);
                    $btnSubmit.html('' < i class= "bi bi-send-check me-2" ></i > % AddNew % '');
                }
                return;
            }

            const isParentFromTemplate = !!(sourceTaskIDFromControl || window.lastSelectedTemplateID);
            const hasManualSubtask = pendingSubtasks.some(s => !s.IsFromTemplate);

            // --- Manual Override Check ---
            const hasManualApproval = (tempApprovalSettings && tempApprovalSettings.RequireApproval);

            // isAutoApproval: only true if it''s NOT a pure template OR if it has manual additions
            // and the user hasn''t explicitly configured approval stages in the drawer.
            const isAutoApproval = (!isParentFromTemplate || hasManualSubtask) && !window.tempApprovalUserEdited;

            if (isAutoApproval || hasManualApproval) {
                // Force auto-calculate ONLY if NOT manually edited by user in drawer
                // If user edited (multi-level or specific single level), KEEP IT.
                if (!window.tempApprovalUserEdited) {
                    const defaultApprover = getDefaultApprover(requestId);
                    if (defaultApprover) {
                        tempApprovalSettings = {
                            RequireApproval: true,
                            Stages: [{ StageOrder: 1, ApproverID: defaultApprover, Deadline: null }],
                            Note: "%AutoActivatedNotInTemplate%"
                        };
                        // Cập nhật UI nút phê duyệt
                        const $btnApp = $("#btn-drawer-approval");
                        if ($btnApp.length) {
                            $btnApp.css("color", "#d97706");
                            $btnApp.html(`<i class="bi bi-check-circle-fill"></i> %OneApprover%`);
                        }
                    } else {
                        // Không có người duyệt mặc định
                        tempApprovalSettings = null;
                    }
                }

                if (!tempApprovalSettings || !tempApprovalSettings.RequireApproval || !tempApprovalSettings.Stages || tempApprovalSettings.Stages.length === 0) {
                    uiManager.showAlert({ type: "warning", message: "Vui lòng định cấu hình người duyệt!" });
                    window.isSubmittingTask = false;
                    if ($btnSubmit.length) {
                        $btnSubmit.prop("disabled", false);
                        $btnSubmit.html('' < i class= "bi bi-send-check me-2" ></i > % AddNew % '');
                    }
                    return; // BLOCKED
                }
            }

            const saveTask = async () => {
                try {
                    const res = await new Promise((resolve, reject) => {
                        AjaxHPAParadise({
                            data: {
                                name: "sp_Task_Save",
                                param: [
                                    "TaskID", window.activeDraftTaskID,
                                    "HistoryID", window.activeDraftHistoryID,
                                    "ProjectID", project || 0,
                                    "TaskName", name,
                                    "AssigneeID", assigneeId || null,
                                    "MainAssigneeID", mainAssigneeId || null,
                                    "RequestID", requestId || null,
                                    "StatusID", 1,
                                    "Priority", priority,
                                    "ParentTaskID", currentParentTaskId || null,
                                    "ParentHistoryID", currentParentId || null,
                                    "DueDate", dueDate,
                                    "ActualStartDate", null,
                                    "TagID", formatIDList(tagId),
                                    "SourceTaskID", sourceTaskIDFromControl || window.lastSelectedTemplateID,
                                    "StandardTime", finalStandardTime,
                                    "ApprovalStatus", (isAutoApproval || hasManualApproval ? 0 : 2), // Nếu cần duyệt thì 0, đã duyệt thì 2
                                    "LoginID", LoginID
                                ]
                            },
                            success: async (res) => {
                                try {
                                    let data = (typeof res === "string" ? JSON.parse(res) : res).data?.[0]?.[0] || {};
                                    const newTaskId = data.NewTaskID;
                                    const newHistoryId = data.NewHistoryID;

                                    window.currentRecordID_PEBB780F668924A108C0A9FF20D70CD80 = newHistoryId;
                                    if (typeof window[''save_PEBB780F668924A108C0A9FF20D70CD80''] === ''function'') {
                            window[''save_PEBB780F668924A108C0A9FF20D70CD80'']();
                        }
                        if (newTaskId) {
                            // Capture approval settings BEFORE they get reset by saveApprovalForNewTask
                            const capturedApprovalSettings = tempApprovalSettings && tempApprovalSettings.RequireApproval
                                ? JSON.parse(JSON.stringify(tempApprovalSettings))
                                : null;

                            // Save Recurrence if set
                            if (typeof saveRecurrenceForNewTask === "function") {
                                await saveRecurrenceForNewTask(newTaskId, LoginID);
                            }
                            // Save Approval if set (resets tempApprovalSettings to null)
                            if (typeof saveApprovalForNewTask === "function") {
                                await saveApprovalForNewTask(newHistoryId, LoginID);
                            }
                            // Save Pending Subtasks sequentially to honor order
                            if (pendingSubtasks.length > 0) {
                                const orderedSubtasks = pendingSubtasks.slice();
                                for (let i = 0; i < orderedSubtasks.length; i++) {
                                    const sub = orderedSubtasks[i];
                                    // Nếu nhiệm vụ con là từ template của cha (IsInherited),
                                    // bỏ qua việc lưu phẳng ở Frontend vì Backend sp_Task_Save đã tự đệ quy bung chúng.
                                    // Điều này tránh nhân đôi dữ liệu và gán sai ParentHistoryID bằng màn hình phẳng.
                                    if (sub.IsInherited == 1) continue;

                                    const isUnmodifiedTemplate = sub.IsFromTemplate && sub.TemplateID && (sub.TaskName === sub.TemplateName);
                                    const useTaskId = (sub.IsParentLink && sub.ExistingTaskID) ? String(sub.ExistingTaskID)
                                        : (isUnmodifiedTemplate ? String(sub.TemplateID) : "0");

                                    // Restore SourceTaskID passing so backend auto-expands grand-children properly
                                    const sourceTaskId = sub.TemplateID || (sub.IsParentLink ? sub.ExistingTaskID : null) || null;

                                    // FIX: IsParentLink subtask là task cha thực sự → cần duyệt (ApprovalStatus=0)
                                    const subApprovalStatus = sub.IsParentLink ? 0 : 2;

                                    const subRes = await new Promise((resolveSub) => {
                                        AjaxHPAParadise({
                                            data: {
                                                name: "sp_Task_Save",
                                                param: [
                                                    "TaskID", useTaskId,
                                                    "ProjectID", project || 0,
                                                    "TaskName", sub.TaskName,
                                                    "Description", "",
                                                    "AssigneeID", sub.AssigneeID ? String(sub.AssigneeID) : null,
                                                    "MainAssigneeID", sub.MainAssigneeID ? String(sub.MainAssigneeID) : null,
                                                    "RequestID", sub.RequestID ? String(sub.RequestID) : null,
                                                    "StatusID", 1,
                                                    "Priority", sub.Priority || 2,
                                                    "ParentTaskID", newTaskId.toString(),
                                                    "ParentHistoryID", newHistoryId,
                                                    "DueDate", sub.DueDate || dueDate,
                                                    "ActualStartDate", null,
                                                    "TagID", null,
                                                    "SourceTaskID", sourceTaskId,
                                                    "StandardTime", sub.StandardTime || 0,
                                                    "SortOrder", i + 1,
                                                    "ApprovalStatus", subApprovalStatus,
                                                    "LoginID", LoginID
                                                ]
                                            },
                                            success: resolveSub,
                                            error: resolveSub
                                        });
                                    });

                                    // FIX: Lưu approval riêng cho subtask là task cha (IsParentLink)
                                    if (sub.IsParentLink && sub.ExistingTaskID) {
                                        try {
                                            const subData = (typeof subRes === "string" ? JSON.parse(subRes) : subRes)?.data?.[0]?.[0] || {};
                                            const subNewHistoryId = subData.NewHistoryID;

                                            if (subNewHistoryId > 0) {
                                                // 1. [REMOVED] sp_Task_ReparentChildren đã được thay thế bằng
                                                // logic bung con MỚI trong sp_Task_Save để tránh cướp subtask.

                                                // 2. Lưu approval cho task cha-con (IsParentLink) nếu có cài đặt duyệt
                                                if (capturedApprovalSettings) {
                                                    const stagesJson = JSON.stringify(capturedApprovalSettings.Stages || []);
                                                    await new Promise((resolveApproval) => {
                                                        AjaxHPAParadise({
                                                            data: {
                                                                name: "sp_Task_Approval_Save",
                                                                param: [
                                                                    "HistoryID", subNewHistoryId,
                                                                    "StagesJson", stagesJson,
                                                                    "Note", capturedApprovalSettings.Note || "",
                                                                    "LoginID", LoginID
                                                                ]
                                                            },
                                                            success: resolveApproval,
                                                            error: resolveApproval
                                                        });
                                                    });
                                                }
                                            }
                                        } catch (e) {
                                            console.error("Failed to save approval for parent-link subtask:", e);
                                        }
                                    }
                                }
                            }

                            uiManager.showAlert({ type: "success", message: "%CreateTaskSuccess%" });
                            clearDraft(); // Xóa bản nháp sau khi tạo thành công
                        } else {
                            uiManager.showAlert({ type: "error", message: "%CreateTaskFailed%" });
                        }
                        closeCreateModal(true);
                        ReloadData();
                        resolve();
                    } catch (e) {
                        console.error("Success callback error:", e);
                        reject(e);
                    }
                },
                error: (err) => {
                    console.error("SaveTask Error:", err);
                    uiManager.showAlert({ type: "error", message: "%disconectServer%" });
                    reject(err);
                }
            });
        });
    } catch (err) {
        console.error("saveTask error:", err);
    } finally {
        window.isSubmittingTask = false;
        if ($btnSubmit.length) {
            $btnSubmit.prop("disabled", false);
            $btnSubmit.html('' < i class= "bi bi-send-check me-2" ></i > % AddNew % '');
        }
    }
                };

    saveTask();
            }

    // ========== TẢI DỮ LIỆU CHÍNH & HIỂN THỊ ==========
    function renderSkeleton(viewType) {
        const $container = $("#view-container");
        if (!$container.length) return;

        // Tạo skeleton nếu chưa tồn tại
        let $skeleton = $("#skeleton-container");
        if (!$skeleton.length) {
            $skeleton = $("<div/>", { id: "skeleton-container" });
            $container.append($skeleton);
        }

        $skeleton.removeClass("d-none");
        $("#grid-wrapper").addClass("d-none");
        $("#scheduler-container").addClass("d-none");

        let html = "";
        if (viewType === "list") {
            html = `<div class="p-3 bg-body" style="min-height: 100vh;">
                        ${Array(isMobile() ? 12 : 20).fill(0).map(() => `
           <div class="mb-4">
                                <div class="skeleton-loading mb-2" style="height: 18px; width: 65%; border-radius: 4px;"></div>
                                <div class="d-flex justify-content-between">
                                    <div class="skeleton-loading" style="height: 12px; width: 35%; border-radius: 4px;"></div>
                                    <div class="skeleton-loading" style="height: 12px; width: 25%; border-radius: 4px;"></div>
                                </div>
                            </div>
                     `).join("")}
                    </div>`;
        } else {
            // Calendar grid skeleton
            html = `<div class="p-3">
                        <div class="d-flex justify-content-center mb-4">
                            <div class="skeleton-loading" style="height: 32px; width: 140px; border-radius: 8px;"></div>
                        </div>
                        <div style="display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px;">
                            ${Array(35).fill(0).map(() => `<div class="skeleton-loading" style="aspect-ratio: 1; border-radius: 4px;"></div>`).join("")}
                        </div>
                        <div class="mt-4">
                            ${Array(3).fill(0).map(() => `

                                <div class="skeleton-loading mb-2" style="height: 48px; width: 100%; border-radius: 10px;"></div>
                            `).join("")}
                   </div>
                    </div>`;
        }
        $skeleton.html(html);
    }

    function hideSkeleton() {
        $("#skeleton-container").addClass("d-none");
        // Remove the "more" skeletons in ttv-body
        $(".ttv-skeleton-more-wrap").remove();
    }

    let _ttvIsResetting = true;
    function ReloadData(reset = true) {
        if (typeof window.saveFilterState === "function") window.saveFilterState();
        try {
            window.sp_Task_TaskList_param = {
                ttvSearch, currentView, currentCalendarView, selectedProjectIDs, selectedStatusIDs,
                selectedTagIDs, selectedPriorityFilters, selectedEmployeeIDs, selectedDueDateFilter,
                filterDateFrom, filterDateTo, isMyTask
            };
        } catch (e) { }

        if (!reset && (_isLoadingMore || !_hasMoreData)) return;
        _isLoadingMore = true;
        _ttvIsResetting = reset;

        if (!reset) {
            if (typeof showTreeViewSkeletonMore === "function") showTreeViewSkeletonMore();
        }

        if (reset) {
            allTasks = [];
            displayedTasks = []; // Initialize displayedTasks when resetting data
            ttvSkip = 0;
            ttvTotalCount = 0;
            _hasMoreData = true;
            window._ttvScrollAttached = false;

            if (currentView === "list") {
                if (isMobile()) {
                    renderSkeleton("list");
                } else {
                    $("#skeleton-container").addClass("d-none");
                    $("#grid-wrapper").removeClass("d-none");
                    if (typeof renderTreeViewSkeleton === "function") renderTreeViewSkeleton();
                }
            } else {
                renderSkeleton(currentView);
            }
        }

        const toParam = (arr) => (arr && arr.length > 0) ? arr.join(",") : "0";
        const fmt = formatDateLocal;

        if (!filterDateFrom || !filterDateTo) {
            const def = getDefaultDateRange();
            filterDateFrom = def.from;
            filterDateTo = def.to;
        }

        AjaxHPAParadise({
            data: {
                name: "sp_Task_GetData_List",
                param: [
                    "LoginID", LoginID,
                    "LanguageID", LanguageID,
                    "DateFrom", fmt(filterDateFrom),
                    "DateTo", fmt(filterDateTo),
                    "ProjectID", toParam(selectedProjectIDs),
                    "PriorityFilter", toParam(selectedPriorityFilters),
                    "StatusID", toParam(selectedStatusIDs),
                    "TagID", toParam(selectedTagIDs),
                    "EmployeeID", toParam(selectedEmployeeIDs),
                    "DueDateFilter", selectedDueDateFilter || "",
                    "Skip", ttvSkip,
                    "Take", ttvTake,
                    "Keyword", ttvSearch || "",
                    "ParentTaskID", currentViewParentID || 0
                ]
            },
            success: function (res) {
                try {
                    const json = typeof res === "string" ? JSON.parse(res) : res;
                    const tasksData = json.data?.[0]?.[0] || {};
                    const newTasks = parseJson(tasksData.Tasks);
                    ttvTotalCount = parseInt(json.data?.[1]?.[0]?.TotalCount) || 0;

                    if (reset) {
                        allTasks = newTasks;
                    } else {
                        const existingIDs = new Set(allTasks.map(t => t.HistoryID));
                        const unique = newTasks.filter(t => !existingIDs.has(t.HistoryID));
                        allTasks.push(...unique);
                    }

                    const _norm = (s) => (typeof RemoveToneMarks === "function" ? RemoveToneMarks(s) : (typeof RemoveToneMarks_Js === "function" ? RemoveToneMarks_Js(s) : s));
                    newTasks.forEach(t => {
                        if (t.TaskName && !t._normTaskName) {
                            t._normTaskName = _norm(t.TaskName).toLowerCase();
                        }
                    });

                    // Calculate Skip based on loaded "Anchor" tasks
                    const anchorLevel = currentViewParentID || 0;
                    const loadedAnchors = allTasks.filter(t => getDirectParentId(t.ParentTaskID) === anchorLevel).length;

                    ttvSkip = loadedAnchors;
                    _hasMoreData = (loadedAnchors < ttvTotalCount) && (newTasks.length > 0 || reset);

                    isLoading = false;
                    applyFilters();
                    if (window._updateMbFilterBadge) window._updateMbFilterBadge();
                } catch (e) {
                    console.error("ReloadData error:", e);
                } finally {
                    _isLoadingMore = false;
                    hideSkeleton();
                    isLoading = false;
                }
            },
            error: function () {
                _isLoadingMore = false;
                isLoading = false;
                hideSkeleton();
            }
        });
    }

    function parseJson(str) { try { return typeof str === "string" ? JSON.parse(str) : (str || []); } catch { return []; } }

    const getDirectParentId = (val) => {
        if (!val || val === "0" || val === 0) return 0;
        const s = String(val);
        if (!s.includes(",")) return parseInt(s) || 0;
        const parts = s.split(",");
        return parseInt(parts[parts.length - 1]) || 0;
    };

    function setMyTaskFilter(val, btn) {
        if (switchingLock || isMyTask === val) return;
        switchingLock = true;
        setTimeout(() => switchingLock = false, 300);

        isMyTask = val;
        const $container = $("#filter-switcher");
        $container.find(".switcher-item").removeClass("active");
        $(btn).addClass("active");
        updateSlider("filter-switcher", $(btn));

        applyFilters();
    }

    function getVisibilityMap() {
        const myEmpID_Raw = currentUser ? String(currentUser.EmployeeID) : null;
        const myEmpID = myEmpID_Raw ? myEmpID_Raw.padStart(3, "0") : null;
        const visibilityMap = {};

        allTasks.forEach(t => {
            let hasRole = false;
            if (isMyTask === "all") {
                hasRole = true;
            } else if (isMyTask === "doing") {
                if (t.AssigneeID) {
                    const ids = t.AssigneeID.split(",").map(s => s.trim());
                    hasRole = ids.includes(myEmpID_Raw) || ids.includes(myEmpID);
                }
            } else if (isMyTask === "assigned") {
                hasRole = String(t.RequestID) === myEmpID_Raw || String(t.RequestID) === myEmpID;
            } else if (isMyTask === "main") {
                hasRole = String(t.MainAssigneeID) === myEmpID_Raw || String(t.MainAssigneeID) === myEmpID;
            } else if (isMyTask === "review") {
                if (t.ApproverID) {
                    const ids = t.ApproverID.split(",").map(s => s.trim());
                    hasRole = ids.includes(myEmpID_Raw) || ids.includes(myEmpID);
                }
            } else if (isMyTask === "recent") {
                const now = new Date();
                const cutoff = new Date(now.getFullYear(), now.getMonth(), 1); // Từ ngày 1 tháng này
                const assignDate = t.AssignDate ? new Date(t.AssignDate) : null;
                hasRole = assignDate && !isNaN(assignDate.getTime()) && assignDate >= cutoff;
            }
            visibilityMap[t.HistoryID] = hasRole;
        });

        // Propagate visibility upward: A parent is visible if it or ANY descendant is visible
        const finalVisibility = { ...visibilityMap };
        const parentMap = {};
        allTasks.forEach(t => { if (t.ParentHistoryID) parentMap[t.HistoryID] = t.ParentHistoryID; });

        allTasks.forEach(t => {
            if (visibilityMap[t.HistoryID]) {
                let curr = t.ParentHistoryID;
                while (curr && curr !== 0) {
                    if (finalVisibility[curr]) break;
                    finalVisibility[curr] = true;
                    curr = parentMap[curr];
                }
            }
        });
        return finalVisibility;
    }

    function applyFilters() {
        if (typeof window.saveFilterState === "function") window.saveFilterState();
        const finalVisibility = getVisibilityMap();

        // 1. filter (client-side)
        const byParent = (t) => {
            const directParent = getDirectParentId(t.ParentTaskID);
            if (currentViewParentID === 0) return directParent === 0;
            return directParent === currentViewParentID;
        };

        // 2. Final filter combining hierarchy visibility
        displayedTasks = allTasks.filter(t => byParent(t) && finalVisibility[t.HistoryID]);

        // 4. Sort
        const today = new Date();

        displayedTasks.sort((a, b) => {
            // Nếu là bộ lọc Recent, ưu tiên sort theo ngày mới nhất lên đầu (AssignDate)
            if (isMyTask === "recent") {
                const da = a.AssignDate ? new Date(a.AssignDate) : new Date(0);
                const db = b.AssignDate ? new Date(b.AssignDate) : new Date(0);
                if (db - da !== 0) return db - da; // Mới nhất lên đầu
                return (b.HistoryID || 0) - (a.HistoryID || 0);
            }

            const statusA = (window.statusMap[a.StatusID] || "").toLowerCase();
            const statusB = (window.statusMap[b.StatusID] || "").toLowerCase();
            const isDoneA = statusA.includes("hoàn thành") || statusA.includes("done");
            const isDoneB = statusB.includes("hoàn thành") || statusB.includes("done");

            // 1. Task đã done xuống cuối
            if (isDoneA !== isDoneB) return isDoneA ? 1 : -1;

            // 2. Task quá hạn (chưa done) lên trước
            if (!isDoneA) {
                const dateA = a.DueDate ? new Date(a.DueDate) : null;
                const dateB = b.DueDate ? new Date(b.DueDate) : null;
                const isOverdueA = dateA && dateA < today;
                const isOverdueB = dateB && dateB < today;

                if (isOverdueA !== isOverdueB) return isOverdueA ? -1 : 1;
            }

            // 3. Theo hạn (DueDate)
            const da = a.DueDate ? new Date(a.DueDate) : new Date("9999-12-31");
            const db = b.DueDate ? new Date(b.DueDate) : new Date("9999-12-31");
            if (da.getTime() !== db.getTime()) return da - db;

            // 4. Theo độ ưu tiên (Priority)
            return (parseInt(b.Priority) || 2) - (parseInt(a.Priority) || 2);
        });

        // 5. Render Tree View
        renderTreeView();

        render();
    }

    function switchView(view, btn) {
        currentView = view;
        if (typeof window.saveFilterState === "function") window.saveFilterState();
        const $container = $("#view-switcher");
        $container.find(".switcher-item").removeClass("active");
        $(btn).addClass("active");
        updateSlider("view-switcher", $(btn));


        // If switching to list, re-render tree view
        if (currentView === "list") {
            renderTreeView();
        }

        render();
    }

    function switchCalendarView(view, btn) {
        currentCalendarView = view;
        const $container = $("#calendar-view-options");
        $container.find(".switcher-item").removeClass("active");
        $(btn).addClass("active");
        updateSlider("calendar-view-options", $(btn));

        if (window.InstanceScheduler && currentView === "calendar") {
            const viewMap = { "day": "timeGridDay", "week": "timeGridWeek", "month": "dayGridMonth" };
            window.InstanceScheduler.changeView(viewMap[view] || "dayGridMonth");
        }

        if (currentView === "list") {
            applyFilters();
        }
    }

    function render() {
        const $gridWrapper = $("#grid-wrapper");
        const $schedulerContainer = $("#scheduler-container");
        const $calendarOptionsGroup = $("#calendar-view-options-group");
        const $toolbarArea = $(".task-toolbar");

        // Move switcher back to main toolbar before clearing scheduler or if switching to list
        if ($calendarOptionsGroup.length && $toolbarArea.length && !$toolbarArea.find("#calendar-view-options-group").length) {
            $toolbarArea.prepend($calendarOptionsGroup);
        }

        // Điều chỉnh overflow của view-container theo loại view
        const $viewContainerEl = $("#view-container");
        if ($viewContainerEl.length) {
            $viewContainerEl.css("overflowY", (currentView === "list") ? "hidden" : "auto");
        }

        if (currentView === "list") {
            $calendarOptionsGroup.addClass("d-none");
            $schedulerContainer.addClass("d-none");
            $gridWrapper.removeClass("d-none");
        } else if (currentView === "calendar") {
            $gridWrapper.addClass("d-none");
            if ($schedulerContainer.length) {
                $schedulerContainer.removeClass("d-none").empty();
                renderCalendarView($schedulerContainer[0]);
            }
        }
    }

    function renderCalendarView(container) {
        if (typeof FullCalendar === "undefined") {
            setTimeout(() => renderCalendarView(container), 200);
            return;
        }

        const fcLocale = (typeof LanguageID !== "undefined" && LanguageID == "VN") ? "vi" : "en";

        const schedulerData = displayedTasks.map(t => {
            const statusVal = (window.statusMap[t.StatusID] || "").toLowerCase();
            const isDone = statusVal.includes("hoàn thành") || statusVal.includes("done");
            const eventDate = t.DueDate ? new Date(t.DueDate) : (t.AssignDate ? new Date(t.AssignDate) : new Date());

            let className = `event-prio-${t.Priority || 2}`;
            if (isDone) className += " event-status-done";

            const pIcon = t.Priority >= 3 ? "⭐" : (t.Priority >= 2 ? "•" : "");
            const sIcon = isDone ? "✓" : "";

            return {
                id: t.TaskID,
                title: `${sIcon} ${pIcon} ${t.TaskName}`,
                start: eventDate,
                allDay: false,
                className: className,
                extendedProps: { ...t }
            };
        });

        const viewMap = { "day": "timeGridDay", "week": "timeGridWeek", "month": "dayGridMonth" };

        const calendar = new FullCalendar.Calendar(container, {
            initialView: viewMap[currentCalendarView] || "dayGridMonth",
            locale: fcLocale,
            headerToolbar: {
                left: "prev,next today",
                center: "title",
                right: "" // Handled by our custom switcher
            },
            events: schedulerData,
            height: "100%",
            selectable: true,
            editable: false,
            eventClick: function (info) {
                showTaskPreview(info.event, info.el);
                info.jsEvent.stopPropagation();
            },
            // Matching DevExtreme start/end hour roughly
            slotMinTime: "07:00:00",
            slotMaxTime: "21:00:00",
            eventTimeFormat: {
                hour: "2-digit",
                minute: "2-digit",
                meridiem: false,
                hour12: false
            }
        });

        calendar.render();
        window.InstanceScheduler = calendar;

        // Move the Day/Week/Month switcher into the header toolbar (right side)
        const $rightChunk = $(container).find(".fc-toolbar-chunk:last-child");
        const $switcherGroup = $("#calendar-view-options-group");
        const isMobile = window.innerWidth <= 767;

        if ($rightChunk.length && $switcherGroup.length) {
            if (isMobile) {
                $switcherGroup.addClass("d-none");
            } else {
                $rightChunk.append($switcherGroup);
                $switcherGroup.removeClass("d-none");
                setTimeout(() => {
                    const $activeBtn = $switcherGroup.find(".switcher-item.active");
                    if ($activeBtn.length) updateSlider("calendar-view-options", $activeBtn);
                }, 50);
            }
        }
    }

    // --- LOGIC XEM NHANH CÔNG VIỆC ---
    function showTaskPreview(event, targetEl) {
        const $popover = $("#task-preview-popover");
        if (!$popover.length) return;

        const t = event.extendedProps;
        const rect = targetEl.getBoundingClientRect();

        // Populate content
        $popover.find(".preview-title").text(t.TaskName || "Không tiêu đề");

        const $body = $popover.find(".preview-body");
        let html = "";

        // Project
        if (t.ProjectName) {
            html += `<div class="preview-info-item"><i class="bi bi-folder2"></i> ${t.ProjectName}</div>`;
        }

        // Assignee
        if (t.AssigneeName) {
            html += `<div class="preview-info-item"><i class="bi bi-person"></i> ${t.AssigneeName}</div>`;
        }

        // Deadline
        const deadline = t.Deadline || t.DueDate;
        if (deadline) {
            const d = new Date(deadline);
            html += `<div class="preview-info-item"><i class="bi bi-calendar-event"></i> Hạn: ${d.toLocaleDateString("vi-VN")} ${d.toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" })}</div>`;
        }

        $body.html(html);

        // Setup Detail Button
        $popover.find(".btn-preview-detail").off("click").on("click", () => {
            closeTaskPreview();
            openDetailHistoryID(t.HistoryID);
        });

        // Position Popover
        $popover.css({ display: "flex", visibility: "hidden" });

        // Allow browser to calculate size
        setTimeout(() => {
            let top = rect.top - $popover.outerHeight() - 12;
            let left = rect.left + (rect.width / 2) - ($popover.outerWidth() / 2);

            // Boundary check
            if (top < 10) top = rect.bottom + 12;
            if (left < 10) left = 10;
            if (left + $popover.outerWidth() > window.innerWidth - 10) left = window.innerWidth - $popover.outerWidth() - 10;

            $popover.css({ top: top + "px", left: left + "px", visibility: "visible" });
        }, 0);
    }

    function closeTaskPreview() {
        const $popover = $("#task-preview-popover");
        if ($popover.length) $popover.hide();
    }

    // Close preview when clicking outside
    $("#sp_Task_TaskList_html").off("click.previewOutside").on("click.previewOutside", function (e) {
        const $popover = $("#task-preview-popover");
        if ($popover.length && $popover.is(":visible") && !$popover.is(e.target) && $popover.has(e.target).length === 0) {
            closeTaskPreview();
        }
    });

    // --- CALENDAR HELPER FUNCTIONS ---
    function formatDate(d) { return d ? new Date(d).toLocaleDateString("vi-VN", { day: "2-digit", month: "2-digit" }) : ""; }
    function renderStars(p) {
        let s = "<div class=''star-container''>";
        for (let i = 1; i <= 3; i++) s += `<i class="bi bi-star-fill priority-star ${i <= p ? "active" : ""}"></i>`;
        s += "</div>";
        return s;
    }

    // ========== TÙY CHỈNH INSTANCE GRID TỪ LOADUI ==========
    let lastUpdateDay = "";
    let dateBoundaries = null;

    function getBoundaries() {
        const now = new Date();
        const todayStr = now.toDateString();
        if (todayStr === lastUpdateDay && dateBoundaries) return dateBoundaries;
        lastUpdateDay = todayStr;
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const currentDay = today.getDay() || 7;
        const endOfWeek = new Date(today);
        endOfWeek.setDate(today.getDate() + (7 - currentDay));
        endOfWeek.setHours(23, 59, 59, 999);
        const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0);
        endOfMonth.setHours(23, 59, 59, 999);
        dateBoundaries = { today, endOfWeek, endOfMonth };
        return dateBoundaries;
    }

    function calculateTimeGroup(rowData) {
        const statusID = rowData.StatusID;
        const dueDateRaw = rowData.Deadline || rowData.DueDate;

        const statusName = window.statusMap ? window.statusMap[statusID] || "" : "";
        if (statusName.includes("done") || statusName.includes("finish") || statusName.includes("cancel") || statusName.includes("close") || statusName.includes("hủy") || statusName.includes("xong")) return "6_Done";

        if (!dueDateRaw) return "5_Later";

        const b = getBoundaries();
        let result = "5_Later";
        let due = null;
        if (typeof dueDateRaw === "string") {
            if (dueDateRaw.includes("/")) {
                const p = dueDateRaw.split("/");
                if (p.length === 3) due = new Date(p[2], p[1] - 1, p[0]);
            } else {
                due = new Date(dueDateRaw);
            }
        } else if (dueDateRaw instanceof Date) {
            due = dueDateRaw;
        }

        if (due && !isNaN(due.getTime())) {
            const now = new Date();
            const dueTime = due.getTime();

            if (dueTime < now.getTime()) result = "1_Overdue";
            else if (due.getFullYear() === now.getFullYear() && due.getMonth() === now.getMonth() && due.getDate() === now.getDate()) result = "2_Today";
            else if (dueTime <= b.endOfWeek.getTime()) result = "3_ThisWeek";
            else if (dueTime <= b.endOfMonth.getTime()) result = "4_ThisMonth";
            else result = "5_Later";
        }

        return result;
    }

    let ttvExpanded = {};
    let ttvSearch = "";

    // Pagination (infinite scroll)
    let ttvSkip = 0;
    let ttvTake = 50;
    let ttvTotalCount = 0;
    let _isLoadingMore = false;
    let _hasMoreData = true;

    // Sort state: { col: "TaskName"|"DueDate"|"AssignDate"|"StatusID"|"Priority", dir: 1|-1 }
    let ttvSort = { col: null, dir: 1 };

    function renderTreeViewSkeleton() {
        const $container = $("#task-tree-view");
        if (!$container.length) return;
        const ROW_COUNT = 20;
        let html = `
                <div class="ttv-header">
                    <div class="ttv-header-cell" style="justify-content:center">
                        <button class="ttv-toggle ttv-toggle-all-btn" title="Thu phóng tất cả"><i class="bi bi-chevron-right"></i></button>
                    </div>
                    <div class="ttv-header-cell">ID</div>
                    <div class="ttv-header-cell">%TaskName%</div>
                    <div class="ttv-header-cell">%Assignee1%</div>
                    <div class="ttv-header-cell">%Requester1%</div>
       <div class="ttv-header-cell">%MainAssignee1%</div>
                  <div class="ttv-header-cell">%Status%</div>
                    <div class="ttv-header-cell">%Deadline1%</div>
                    <div class="ttv-header-cell">%AssignedDate%</div>
              <div class="ttv-header-cell">%CompletionDate%</div>
               <div class="ttv-header-cell">%Priority%</div>
                    <div class="ttv-header-cell"></div>
                </div>`;
        for (let i = 0; i < ROW_COUNT; i++) {
            const w1 = 45 + Math.random() * 40;
            const w2 = 50 + Math.random() * 30;
            html += `
                    <div class="ttv-skeleton-row">
                        <div style="display:flex;align-items:center;justify-content:center"><div class="sk-icon skeleton-loading"></div></div>
                        <div><div class="sk-icon skeleton-loading"></div></div>
                        <div style="padding:0 5px"><div class="sk-date skeleton-loading" style="width:30px"></div></div>
                        <div style="display:flex;align-items:center;gap:6px;padding:0 5px">
                            <div class="sk-name skeleton-loading" style="width:${w1}%"></div>
                        </div>
                        <div style="padding:0 5px;display:flex;align-items:center"><div class="sk-avatar skeleton-loading"></div></div>
                        <div style="padding:0 5px;display:flex;align-items:center"><div class="sk-avatar skeleton-loading"></div></div>
                    <div style="padding:0 5px;display:flex;align-items:center"><div class="sk-avatar skeleton-loading"></div></div>
                 <div style="padding:0 5px"><div class="sk-badge skeleton-loading" style="width:${w2}%"></div></div>
                        <div style="padding:0 5px"><div class="sk-date skeleton-loading"></div></div>
                   <div style="padding:0 5px"><div class="sk-date skeleton-loading"></div></div>
                        <div style="padding:0 5px"><div class="sk-pri skeleton-loading"></div></div>
                        <div></div>
                    </div>`;
        }
        $container.html(html);
    }

    function showTreeViewSkeletonMore() {
        const $body = $("#task-tree-view .ttv-body");
        if (!$body.length) return;
        if ($body.find(".ttv-skeleton-more-wrap").length) return;

        const $wrap = $("<div/>", { class: "ttv-skeleton-more-wrap" });
        let html = "";
        for (let i = 0; i < 5; i++) {
            const w1 = 40 + Math.random() * 40;
            const w2 = 50 + Math.random() * 30;
            html += `
                    <div class="ttv-skeleton-row">
                        <div style="display:flex;align-items:center;justify-content:center"><div class="sk-icon skeleton-loading"></div></div>
                        <div><div class="sk-icon skeleton-loading"></div></div>
                        <div style="padding:0 5px"><div class="sk-date skeleton-loading" style="width:30px"></div></div>
                        <div style="display:flex;align-items:center;gap:6px;padding:0 5px">
                            <div class="sk-name skeleton-loading" style="width:${w1}%"></div>
                        </div>
                        <div style="padding:0 5px;display:flex;align-items:center"><div class="sk-avatar skeleton-loading"></div></div>
                        <div style="padding:0 5px;display:flex;align-items:center"><div class="sk-avatar skeleton-loading"></div></div>
                        <div style="padding:0 5px;display:flex;align-items:center"><div class="sk-avatar skeleton-loading"></div></div>
                        <div style="padding:0 5px"><div class="sk-badge skeleton-loading" style="width:${w2}%"></div></div>
                        <div style="padding:0 5px"><div class="sk-date skeleton-loading"></div></div>
            <div style="padding:0 5px"><div class="sk-date skeleton-loading"></div></div>
                        <div style="padding:0 5px"><div class="sk-pri skeleton-loading"></div></div>
               <div></div>
                    </div>`;
        }
        $wrap.html(html).appendTo($body);
    }

    function renderTreeView() {
        if (isLoading) { renderTreeViewSkeleton(); return; }
        const $container = $("#task-tree-view");
        if (!$container.length) return;

        // Xây dựng map subtask: parentHistoryID -> [children]
        const childrenMap = {};
        allTasks.forEach(t => {
            const pid = parseInt(t.ParentHistoryID) || 0;
            if (pid !== 0) {
                if (!childrenMap[pid]) childrenMap[pid] = [];
                childrenMap[pid].push(t);
            }
        });

        const finalVisibility = getVisibilityMap();
        const byRole = (t) => finalVisibility[t.HistoryID] || false;

        const today = new Date();

        function fmtDate(raw) {
            if (!raw) return "";
            const d = new Date(raw);
            if (isNaN(d)) return "";
            const datePart = d.toLocaleDateString("vi-VN", { day: "2-digit", month: "2-digit", year: "numeric" });
            const h = d.getHours(), m = d.getMinutes();
            const hasTime = h !== 0 || m !== 0;
            const timePart = hasTime ? `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}` : "";
            return hasTime
                ? `<span class="ttv-date-main">${datePart}</span><span class="ttv-date-time">${timePart}</span>`
                : `<span class="ttv-date-main">${datePart}</span>`;
        }

        function fmtDateSimple(raw) {
            if (!raw) return "";
            const d = new Date(raw); if (isNaN(d)) return "";
            const day = String(d.getDate()).padStart(2, "0");
            const mon = String(d.getMonth() + 1).padStart(2, "0");
            const h = d.getHours(), m = d.getMinutes();
            const hasTime = h !== 0 || m !== 0;
            return hasTime
                ? `${day}/${mon}/${d.getFullYear()} ${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`
                : `${day}/${mon}/${d.getFullYear()}`;
        }

        function fmtDateRaw(raw) {
            // Dùng để sort và so sánh
            if (!raw) return 0;
            const d = new Date(raw);
            return isNaN(d) ? 0 : d.getTime();
        }

        function dueCls(raw, statusID) {
            if (statusID == 4) return "";
            if (statusID !== undefined) {
                const sName = (window.statusMap?.[statusID] || "").toLowerCase();
                const isDone = sName.includes("done") || sName.includes("finish") || sName.includes("cancel") || sName.includes("close") || sName.includes("hủy") || sName.includes("xong");
                if (isDone) return "";
            }
            if (!raw) return "";
            const d = new Date(raw);
            if (isNaN(d)) return "";
            const ddTime = d.getTime();
            const checkNow = new Date();
            const nowTime = checkNow.getTime();

            // Nếu thời gian hiện thiện vượt quá thời gian hạn -> Overdue (Đỏ/Hồng)
            if (ddTime < nowTime) return "overdue";

            // Nếu cùng ngày nhưng chưa tới giờ trễ -> Today (Vàng)
            if (d.getFullYear() === checkNow.getFullYear() && d.getMonth() === checkNow.getMonth() && d.getDate() === checkNow.getDate()) return "today";
            return "";
        }

        function getInitials(name) {
            if (!name) return "?";
            const words = name.trim().split(/\s+/);
            if (words.length >= 2) return (words[0][0] + words[words.length - 1][0]).toUpperCase();
            return name.substring(0, 2).toUpperCase();
        }

        const avatarColors = [
            { bg: "#dbeafe", text: "#1d4ed8" }, { bg: "#ede9fe", text: "#7c3aed" },
            { bg: "#dcfce7", text: "#16a34a" }, { bg: "#fef3c7", text: "#d97706" },
            { bg: "#fce7f3", text: "#be185d" }, { bg: "#e0f2fe", text: "#0369a1" },
            { bg: "#f0fdf4", text: "#15803d" }, { bg: "#fdf2f8", text: "#9d174d" }
        ];
        function getAvatarColor(id) {
            const n = parseInt(id) || 0;
            return avatarColors[Math.abs(n) % avatarColors.length];
        }

        function buildAvatarHTML(assigneeIDRaw) {
            if (!assigneeIDRaw) return "";
            const ids = String(assigneeIDRaw).split(",").map(s => s.trim()).filter(Boolean);
            const MAX = 3;
            let inner = "";
            const visible = ids.slice(0, MAX);
            visible.forEach((id, i) => {
                const emp = employees.find(e => String(e.EmployeeID) === id || String(e.EmployeeID).padStart(3, "0") === id);
                const name = emp ? (emp.FullName || emp.Name || "?") : "?";
                const cl = getAvatarColor(id);
                const img = window.GlobalEmployeeAvatarCache && window.GlobalEmployeeAvatarCache[id];
                if (img) {
                    inner += `<span class="ttv-avatar" data-empid="${id}" title="${name}"><img src="${img}" alt="${name}"></span>`;
                } else {
                    inner += `<span class="ttv-avatar" data-empid="${id}" title="${name}" style="background:${cl.bg};color:${cl.text}">${getInitials(name)}</span>`;
                }
            });
            if (ids.length > MAX) {
                inner += `<span class="ttv-avatar ttv-avatar-more" title="+${ids.length - MAX} người nữa">+${ids.length - MAX}</span>`;
            }
            return `<div class="ttv-avatar-group">${inner}</div>`;
        }

        function buildStatusHTML(statusID) {
            const s = statusList.find(ss => ss.StatusID === statusID);
            if (!s) return "";
            const color = s.Color || "#6c757d";
            return `<span class="ttv-status-badge" style="background:${color}15; color:${color}; border: 1px solid ${color}40; border-radius: 4px; padding: 4px 10px; font-size: 0.7rem; font-weight: 500; vertical-align: middle;">${s.StatusName}</span>`;
        }

        function buildPriorityHTML(taskID, priority) {
            const p = Math.max(1, Math.min(3, parseInt(priority) || 1));
            let html = "";
            for (let i = 1; i <= 3; i++) {
                html += `<i class="bi bi-star-fill ttv-star ${i <= p ? "active" : ""}" data-task="${taskID}" data-star="${i}"></i>`;
            }
            return html;
        }

        function highlight(text, search, normText) {
            if (!search) return escHtml(text);
            const _hNorm = (s) => (typeof RemoveToneMarks === "function" ? RemoveToneMarks(s) : (typeof RemoveToneMarks_Js === "function" ? RemoveToneMarks_Js(s) : s));
            const searchNorm = _hNorm(search).toLowerCase();
            if (!searchNorm || searchNorm.length === 0) return escHtml(text);

            const textNorm = normText || _hNorm(text).toLowerCase();
            let result = "";
            let i = 0;
            const searchLen = searchNorm.length;

            while (i < text.length) {
                const idx = textNorm.indexOf(searchNorm, i);
                if (idx === -1) {
                    result += escHtml(text.slice(i));
                    break;
                }
                result += escHtml(text.slice(i, idx));
                result += `<mark>${escHtml(text.slice(idx, idx + searchLen))}</mark>`;
                i = idx + searchLen;
                if (searchLen === 0) break; // Safeguard
            }
            return result;
        }

        function escHtml(str) {
            return String(str || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
        }

        // Lọc tasks theo search
        const _sNorm = (s) => (typeof RemoveToneMarks === "function" ? RemoveToneMarks(s) : (typeof RemoveToneMarks_Js === "function" ? RemoveToneMarks_Js(s) : s));
        const searchQ = _sNorm(ttvSearch.trim()).toLowerCase();
        function matchSearch(t) {
            if (!searchQ) return true;
            const normContent = t._normTaskName || _sNorm(t.TaskName || "").toLowerCase();
            return normContent.includes(searchQ) || String(t.HistoryID || "").includes(searchQ);
        }

        // Sort helper
        function sortIcon(col) {
            if (ttvSort.col !== col) return `<i class="bi bi-arrow-down-up ttv-sort-icon" style="opacity:0.3"></i>`;
            return ttvSort.dir === 1
                ? `<i class="bi bi-arrow-up ttv-sort-icon"></i>`
                : `<i class="bi bi-arrow-down ttv-sort-icon"></i>`;
        }
        function sortClass(col) {
            return `sortable${ttvSort.col === col ? " sorted" : ""}`;
        }

        function hasMatchingChild(historyID) {
            const children = childrenMap[historyID] || [];
            return children.some(st => (byRole(st) && matchSearch(st)) || hasMatchingChild(st.HistoryID));
        }

        const displayedTasks = allTasks.filter(t => getDirectParentId(t.ParentTaskID) === (currentViewParentID || 0) && byRole(t));

        // Lọc + sort tasks trước khi hiển thị
        let filteredTasks = displayedTasks.filter(t => matchSearch(t) || hasMatchingChild(t.HistoryID));
        if (ttvSort.col || isMyTask === "recent") {
            filteredTasks.sort((a, b) => {
                // Bộ lọc Recent: sort theo AssignDate mới nhất trước
                if (!ttvSort.col && isMyTask === "recent") {
                    const da = a.AssignDate ? new Date(a.AssignDate) : new Date(0);
                    const db = b.AssignDate ? new Date(b.AssignDate) : new Date(0);
                    if (db - da !== 0) return db - da;
                    return (b.HistoryID || 0) - (a.HistoryID || 0);
                }

                let va, vb;
                const col = ttvSort.col;
                const dir = ttvSort.dir || 1;

                if (col === "DueDate" || col === "AssignDate" || col === "ActualFinishDate") {
                    va = fmtDateRaw(a[col]);
                    vb = fmtDateRaw(b[col]);
                } else if (col === "Priority") {
                    va = parseInt(a.Priority) || 0;
                    vb = parseInt(b.Priority) || 0;
                } else if (col === "StatusID") {
                    const sa = statusList.find(s => s.StatusID === a.StatusID);
                    const sb = statusList.find(s => s.StatusID === b.StatusID);
                    va = sa ? (sa.StatusName || "") : "";
                    vb = sb ? (sb.StatusName || "") : "";
                } else {
                    va = String(a[col] || "").toLowerCase();
                    vb = String(b[col] || "").toLowerCase();
                }
                if (va < vb) return -1 * dir;
                if (va > vb) return 1 * dir;
                return 0;
            });
        }

        // Phân trang (infinite scroll)
        const totalItems = ttvTotalCount;
        const pagedTasks = filteredTasks;

        // 1. Header cố định (11 cột)
        // Nút Toggle All hướng xuống nếu có ít nhất 1 cái đang mở
        const totalExpandable = filteredTasks.filter(t => childrenMap[t.HistoryID] && childrenMap[t.HistoryID].length > 0).length;
        const expandedCount = filteredTasks.filter(t => childrenMap[t.HistoryID] && childrenMap[t.HistoryID].length > 0 && ttvExpanded[t.HistoryID] === true).length;
        const isAnyExpanded = expandedCount > 0;

        let headerHtml = `
                <div class="ttv-header">
                    <div class="ttv-header-cell" style="justify-content:center">
                        <button class="ttv-toggle ttv-toggle-all-btn ${isAnyExpanded ? "expanded" : ""}" title="${isAnyExpanded ? "Thu gọn tất cả" : "Mở rộng tất cả"}">
                            <i class="bi bi-chevron-right"></i>
                        </button>
                    </div>
                    <div class="ttv-header-cell ${sortClass("HistoryID")}" data-sort="HistoryID">ID ${sortIcon("HistoryID")}</div>
                    <div class="ttv-header-cell ${sortClass("TaskName")}" data-sort="TaskName">%TaskName% ${sortIcon("TaskName")}</div>
                    <div class="ttv-header-cell">%Assignee1%</div>
                    <div class="ttv-header-cell">%Requester1%</div>
                    <div class="ttv-header-cell">%MainAssignee1%</div>
                    <div class="ttv-header-cell ${sortClass("StatusID")}" data-sort="StatusID">%Status% ${sortIcon("StatusID")}</div>
                    <div class="ttv-header-cell ${sortClass("DueDate")}" data-sort="DueDate">%Deadline1% ${sortIcon("DueDate")}</div>
                    <div class="ttv-header-cell ${sortClass("AssignDate")}" data-sort="AssignDate">%AssignedDate% ${sortIcon("AssignDate")}</div>
                    <div class="ttv-header-cell ${sortClass("ActualFinishDate")}" data-sort="ActualFinishDate">%CompletionDate% ${sortIcon("ActualFinishDate")}</div>
                    <div class="ttv-header-cell ${sortClass("Priority")}" data-sort="Priority">%Priority% ${sortIcon("Priority")}</div>
                    <div class="ttv-header-cell"></div>
                </div>`;

        // 2. Body cuộn
        let rowsHtml = "";
        let rowCount = 0;

        pagedTasks.forEach(task => {
            const historyID = task.HistoryID;
            const hasSubs = !!(childrenMap[historyID] && childrenMap[historyID].length > 0);
            const isExpanded = ttvExpanded[historyID] === true; // default collapsed (đổi từ !== false sang === true)
            const subCount = hasSubs ? childrenMap[historyID].length : 0;

            const toggleIcon = hasSubs
                ? `<button class="ttv-toggle ${isExpanded ? "expanded" : ""}" data-toggle="${historyID}" title="${isExpanded ? "Thu gọn" : "Mở rộng"}"><i class="bi bi-chevron-right"></i></button>`
                : `<span style="width:24px;display:inline-block;"></span>`;

            const subCountBadge = hasSubs ? `<span class="ttv-subtask-count"><i class="bi bi-diagram-3"></i>${subCount}</span>` : "";

            rowsHtml += `
                    <div class="ttv-row ${dueCls(task.DueDate, task.StatusID)}" data-taskid="${task.TaskID}" data-historyid="${historyID}" data-parentid="0">
                        <div style="display:flex;align-items:center;justify-content:center">${toggleIcon}</div>
                        <div class="ttv-id-cell">#${task.HistoryID || ""}</div>
                        <div class="ttv-name-cell">
                            <i class="bi bi-check-square ttv-task-icon parent"></i>
                            <span class="ttv-task-name" data-open="${task.HistoryID || ""}" title="${escHtml(task.TaskName)}">${highlight(task.TaskName || "", ttvSearch, task._normTaskName)}</span>
                            ${subCountBadge}
                        </div>
                        <div class="ttv-assignee-cell">${buildAvatarHTML(task.AssigneeID)}</div>
                        <div class="ttv-assignee-cell">${buildAvatarHTML(task.RequestID)}</div>
                        <div class="ttv-assignee-cell">${buildAvatarHTML(task.MainAssigneeID)}</div>
                        <div class="ttv-status-cell">${buildStatusHTML(task.StatusID)}</div>
                     <div class="ttv-date-cell ${dueCls(task.DueDate, task.StatusID)}">${fmtDate(task.DueDate)}</div>
                        <div class="ttv-date-cell">${fmtDate(task.AssignDate)}</div>
                        <div class="ttv-date-cell">${fmtDate(task.ActualFinishDate)}</div>
                        <div class="ttv-priority-cell">${buildPriorityHTML(task.TaskID, task.Priority)}</div>
              <div class="ttv-actions-cell">
                            <button class="ttv-btn-action" data-detail="${task.HistoryID || ""}" title="Xem chi tiết"><i class="bi bi-arrow-up-right-square"></i></button>
                        </div>
                        <!-- MOBILE CARD (Parent) -->
                        <div class="ttv-card-top">
                            <span class="ttv-task-name" data-open="${task.HistoryID || ""}" title="${escHtml(task.TaskName)}">${highlight(task.TaskName || "", ttvSearch, task._normTaskName)}</span>
                         <span class="ttv-card-id">#${task.HistoryID || ""}</span>
                            ${hasSubs ? `<button class="ttv-card-sub-toggle ${isExpanded ? "expanded" : ""}" data-toggle="${historyID}"><i class="bi bi-chevron-down"></i> ${subCount}</button>` : ""}
                        </div>
                        <div class="ttv-card-meta">
                            <div class="ttv-status-cell">${buildStatusHTML(task.StatusID)}</div>
                            <div class="mb-meta-right">
                                ${task.DueDate ? `<span class="mb-date-chip ${dueCls(task.DueDate, task.StatusID)}"><i class="bi bi-calendar3 me-1"></i>${fmtDateSimple(task.DueDate)}</span>` : ""}
                                <div class="ttv-assignee-cell">${buildAvatarHTML(task.AssigneeID)}</div>
                            </div>
                        </div>
                    </div>`;
            rowCount++;

            // Render subtasks
            if (hasSubs && (ttvExpanded[historyID] === true)) {
                const parentMatch = matchSearch(task);
                const subs = childrenMap[historyID].filter(st => byRole(st) && (parentMatch || matchSearch(st)));
                subs.forEach(sub => {
                    rowsHtml += `
                            <div class="ttv-row ttv-subtask ${dueCls(sub.DueDate, sub.StatusID)}" data-taskid="${sub.TaskID}" data-historyid="${sub.HistoryID || ""}" data-parentid="${historyID}">
                                <div style="display:flex;align-items:center;justify-content:flex-end;padding-right:2px">
                                    <div class="ttv-indent-line"></div>
                                </div>
       <div class="ttv-id-cell"></div>
                                <div class="ttv-name-cell">
           <i class="bi bi-check2 ttv-task-icon sub" style="margin-left:4px"></i>
                                    <span class="ttv-task-name" data-open="${sub.HistoryID || ""}" title="${escHtml(sub.TaskName)}">${highlight(sub.TaskName || "", ttvSearch, sub._normTaskName)}</span>
                         </div>
                                <div class="ttv-assignee-cell">${buildAvatarHTML(sub.AssigneeID)}</div>
                                <div class="ttv-assignee-cell">${buildAvatarHTML(sub.RequestID)}</div>
                                <div class="ttv-assignee-cell">${buildAvatarHTML(sub.MainAssigneeID)}</div>
                                <div class="ttv-status-cell">${buildStatusHTML(sub.StatusID)}</div>
                                <div class="ttv-date-cell ${dueCls(sub.DueDate, sub.StatusID)}">${fmtDate(sub.DueDate)}</div>
                                <div class="ttv-date-cell">${fmtDate(sub.AssignDate)}</div>
                                <div class="ttv-date-cell">${fmtDate(sub.ActualFinishDate)}</div>
                        <div class="ttv-priority-cell">${buildPriorityHTML(sub.TaskID, sub.Priority)}</div>
                                <div class="ttv-actions-cell">
                 <button class="ttv-btn-action" data-detail="${sub.HistoryID || ""}" title="Xem chi tiết"><i class="bi bi-arrow-up-right-square"></i></button>
                                </div>
                                <!-- MOBILE CARD (Subtask) -->
                                <div class="ttv-card-top">
                           <span class="ttv-task-name" data-open="${sub.HistoryID || ""}" title="${escHtml(sub.TaskName)}">${highlight(sub.TaskName || "", ttvSearch, sub._normTaskName)}</span>
                                    <span class="ttv-card-id">#${sub.HistoryID || ""}</span>
                                </div>
                                <div class="ttv-card-meta">
                                    <div class="ttv-status-cell">${buildStatusHTML(sub.StatusID)}</div>
                                 <div class="mb-meta-right">
                                        ${sub.DueDate ? `<span class="mb-date-chip ${dueCls(sub.DueDate, sub.StatusID)}"><i class="bi bi-calendar3 me-1"></i>${fmtDateSimple(sub.DueDate)}</span>` : ""}
                                        <div class="ttv-assignee-cell">${buildAvatarHTML(sub.AssigneeID)}</div>
                                    </div>
                                </div>
                            </div>`;
                    rowCount++;
                });
            }
        });

        if (rowCount === 0) {
            rowsHtml = `<div class="ttv-empty"><i class="bi bi-inbox"></i><p>Không có công việc nào</p></div>`;
        }

        // 5. Restore scroll if not resetting
        const $oldBody = $container.find(".ttv-body");
        const oldScrollTop = $oldBody.length ? $oldBody.scrollTop() : 0;

        // Optimization: Only update the body innerHTML if header already exists
        const $existingHeader = $container.find(".ttv-header");
        if ($existingHeader.length) {
            // Cập nhật trạng thái nút Toggle All trong header cũ
            const $headerToggle = $existingHeader.find(".ttv-toggle-all-btn");
            if (isAnyExpanded) {
                $headerToggle.addClass("expanded").attr("title", "Thu gọn tất cả");
            } else {
                $headerToggle.removeClass("expanded").attr("title", "Mở rộng tất cả");
            }

            if ($oldBody.length) {
                $oldBody.html(rowsHtml);
            } else {
                $container.html(headerHtml + `<div class="ttv-body">${rowsHtml}</div>`);
            }
        } else {
            $container.html(headerHtml + `<div class="ttv-body">${rowsHtml}</div>`);
        }

        // 6. Restore scroll position
        if (_ttvIsResetting) {
            _ttvIsResetting = false;
        } else if (oldScrollTop > 0) {
            const $newBody = $container.find(".ttv-body");
            if ($newBody.length) {
                $newBody.scrollTop(oldScrollTop);
            }
        }

        // 3. Trigger load ảnh avatar hiệu quả
        const allNeededIDs = new Set();
        const collect = (val) => {
            if (!val) return;
            String(val).split(",").forEach(id => {
                const s = id.trim();
                if (s) allNeededIDs.add(s);
            });
        };

        pagedTasks.forEach(t => {
            collect(t.AssigneeID); collect(t.RequestID); collect(t.MainAssigneeID);
            const subs = childrenMap[t.HistoryID];
            if (subs && (ttvExpanded[t.HistoryID] === true)) {
                subs.forEach(st => {
                    collect(st.AssigneeID); collect(st.RequestID); collect(st.MainAssigneeID);
                });
            }
        });

        const _avatarIDs = [...allNeededIDs]; // copy để closure an toàn
        const _doAvatarLoad = () => {
            _avatarIDs.forEach(id => {
                if (!id) return;
                if (window.GlobalEmployeeAvatarCache?.[id]) {
                    // Đã có trong cache → update DOM ngay (fast, no network)
                    $container.find(`.ttv-avatar[data-empid="${id}"]`).each(function () {
                        if (!$(this).find("img").length) {
                            $(this).html(`<img src="${window.GlobalEmployeeAvatarCache[id]}" alt="">`);
                        }
                    });
                } else {
                    // Chưa có → lazy load
                    const emp = employees.find(e =>
                        String(e.EmployeeID) === id ||
                        String(e.EmployeeID).padStart(3, "0") === id
                    );
                    if (emp && emp.StoreImgName && typeof hpaUtils !== "undefined" && hpaUtils.loadAvatar) {
                        hpaUtils.loadAvatar(id, emp.StoreImgName, emp.ImgParamV, function (url) {
                            if (!url) return;
                            if (!window.GlobalEmployeeAvatarCache) window.GlobalEmployeeAvatarCache = {};
                            window.GlobalEmployeeAvatarCache[id] = url;
                            $container.find(`.ttv-avatar[data-empid="${id}"]`)
                                .html(`<img src="${url}" alt="">`);
                        });
                    }
                }
            });
        };

        // ★ Chạy avatar loading sau khi browser đã paint xong frame hiện tại
        if (typeof requestIdleCallback === "function") {
            requestIdleCallback(_doAvatarLoad, { timeout: 500 });
        } else {
            setTimeout(_doAvatarLoad, 0);
        }

        renderPagination($container[0], totalItems, pagedTasks.length);
        _attachScrollListener();


        // Sort header click
        $container.find(".ttv-header-cell.sortable").off("click").on("click", function () {

            const col = $(this).data("sort");
            if (ttvSort.col === col) {
                ttvSort.dir = ttvSort.dir === 1 ? -1 : 1;
            } else {
                ttvSort.col = col;
                ttvSort.dir = 1;
            }
            _ttvIsResetting = true;
            renderTreeView();
        });

        // Bind toggle expand/collapse
        $container.find("[data-toggle]").off("click").on("click", function (e) {
            e.stopPropagation();
            const tid = parseInt($(this).data("toggle"));
            if (isNaN(tid)) return;
            // Mặc định collapsed (false), toggle sang true khi click lần đầu
            const wasExpanded = ttvExpanded[tid] === true;
            ttvExpanded[tid] = !wasExpanded;
            renderTreeView();
        });

        $container.find("[data-open]").off("click").on("click", function (e) {
            e.stopPropagation();
            const hid = parseInt($(this).data("open"));
            if (hid) openDetailHistoryID(hid);
        });

        $container.find("[data-detail]").off("click").on("click", function (e) {
            e.stopPropagation();
            const hid = parseInt($(this).data("detail"));
            if (hid) openDetailHistoryID(hid);
        });

        // Row click -> open detail
        $container.find(".ttv-row").off("click").on("click", function (e) {
            if ($(e.target).closest("[data-toggle],[data-open],[data-detail]").length) return;
            const hid = parseInt($(this).data("historyid"));
            if (hid) openDetailHistoryID(hid);
        });

        // Toggle All Logic
        $container.find(".ttv-toggle-all-btn").off("click").on("click", function (e) {
            e.stopPropagation();
            const shouldExpand = !$(this).hasClass("expanded");
            filteredTasks.forEach(t => {
                if (childrenMap[t.HistoryID] && childrenMap[t.HistoryID].length > 0) {
                    ttvExpanded[t.HistoryID] = shouldExpand;
                }
            });
            renderTreeView();
        });
    }

    function renderPagination(container, totalItems, loaded) {
        const $container = $(container);
        let $pag = $container.find("#ttv-pagination-bar");
        const isNew = $pag.length === 0;

        if (isNew) {
            $pag = $("<div>", { class: "ttv-pagination", id: "ttv-pagination-bar" });
        }

        $pag.html(`
                    <div class="ttv-page-size" style="line-height: normal;">
                        ${loaded} / ${totalItems}
                    </div>
                    ${!_hasMoreData && totalItems > 0
                ? `<span class="ttv-page-info">%All%: ${totalItems}</span>`
                : ""}
                `);

        if ($("#ttv-spin-style").length === 0) {
            $("<style>", { id: "ttv-spin-style" })
                .text("@keyframes ttvSpin{to{transform:rotate(360deg)}}")
                .appendTo("head");
        }

        if (isNew) {
            $container.append($pag);
        }
    }

    function _isTaskListVisible() {
        const $el = $("#sp_Task_TaskList_html");
        return $el.length > 0 && $el.is(":visible");
    }

    function _attachScrollListener() {
        // ★ Chỉ attach 1 lần, tránh re-attach sau mỗi renderTreeView
        const $body = $("#task-tree-view .ttv-body");
        if (!$body.length) return;
        const el = $body[0];

        // Nếu đã attach cho đúng element này rồi thì bỏ qua
        if (window._ttvBodyScrollEl === el && window._ttvScrollAttached) return;

        // Cleanup listener cũ
        if (window._ttvBodyScrollEl && window._ttvBodyScrollHandler) {
            window._ttvBodyScrollEl.removeEventListener("scroll", window._ttvBodyScrollHandler);
        }

        const mobileOS = window.getMobileOperatingSystem?.() || "";
        const isMob = ["Android", "iOS"].includes(mobileOS) || window.innerWidth <= 767;
        const threshold = isMob ? 300 : 150;

        let _scrollRaf = null;

        // ★ RAF throttle: chỉ xử lý 1 lần mỗi frame, không block main thread
        const checkBodyScroll = function () {
            if (_scrollRaf) return;
            _scrollRaf = requestAnimationFrame(function () {
                _scrollRaf = null;
                if (!_hasMoreData || _isLoadingMore || currentView !== "list") return;
                if (!_isTaskListVisible()) return;
                const isAtBottom = el.scrollTop + el.clientHeight >= el.scrollHeight - threshold;
                if (isAtBottom) ReloadData(false);
            });
        };

        // ★ passive: true = browser không cần chờ JS trước khi scroll
        el.addEventListener("scroll", checkBodyScroll, { passive: true });

        window._ttvBodyScrollHandler = checkBodyScroll;
        window._ttvBodyScrollEl = el;
        window._ttvScrollAttached = true;
    }

    function initAdvancedFilter() {
        // Luôn kiểm tra instance có còn gắn với DOM hiện tại không
        const $el = $("#P_Filter_EmployeeID");
        if ($el.length) {
            let liveInst = null;
            try {
                liveInst = DevExpress.ui.dxTagBox.getInstance($el[0]);
            } catch (e) { }

            if (!liveInst) {
                // DOM mới (form mở lần 2+) hoặc chưa khởi tạo → tạo mới
                try {
                    if (window.InstanceP_Filter_EmployeeID &&
                        typeof window.InstanceP_Filter_EmployeeID.dispose === "function") {
                        window.InstanceP_Filter_EmployeeID.dispose();
                    }
                } catch (e) { }

                window.InstanceP_Filter_EmployeeID = new DevExpress.ui.dxTagBox($el[0], {
                    dataSource: employees || [],
                    valueExpr: "EmployeeID",
                    displayExpr: "FullName",
                    placeholder: "%SelectEmployee%...",
                    showClearButton: true,
                    searchEnabled: true,
                    stylingMode: "filled",
                    onValueChanged: function () {
                        _fpdFilterChanged = true;
                    }
                });
            } else {
                // Instance vẫn còn sống trên đúng element → chỉ update data
                window.InstanceP_Filter_EmployeeID = liveInst;
                if (employees && employees.length > 0) {
                    liveInst.option("dataSource", employees);
                }
            }
        }

        const $btn = $("#btn-filter-advanced");
        const $dropdown = $("#filter-advanced-dropdown");
        if (!$btn.length || !$dropdown.length) return;

        // Declare label for filter count display
        const $label = $btn.find(".fpd-filter-count");

        // --- HELPERS ---
        const toggleArr = (arr, val) => {
            const idx = arr.indexOf(val);
            if (idx > -1) arr.splice(idx, 1);
            else arr.push(val);
        };

        function countActive() {
            let n = 0;
            if (selectedProjectIDs.length > 0) n++;
            if (selectedStatusIDs.length > 0) n++;
            if (selectedTagIDs.length > 0) n++;
            if (selectedPriorityFilters.length > 0) n++;
            if (selectedEmployeeIDs.length > 0) n++;
            if (selectedDueDateFilter) n++;
            return n;
        }

        function updateLabel() {
            const n = countActive();
            if ($label.length) $label.text(n > 0 ? `(${n})` : "");
            $btn.toggleClass("active", n > 0);
            if (typeof window._updateMbFilterBadge === "function") {
                window._updateMbFilterBadge();
            }
        }

        function renderDropdown() {
            const dueDates = [
                { val: "overdue", label: "%Overdue%", icon: "bi-exclamation-circle" },
                { val: "today", label: "%Today%", icon: "bi-calendar-check" },
                { val: "week", label: "%ThisWeek%", icon: "bi-calendar-week" },
                { val: "month", label: "%ThisMonth%", icon: "bi-calendar-month" },
            ];

            const projectOptions = projects.map(p => {
                const isSelected = selectedProjectIDs.includes(p.ProjectID);
                return `<span class="fpd-option ${isSelected ? "selected" : ""}" data-type="project" data-val="${p.ProjectID}">
                                    <i class="bi bi-folder2"></i> ${p.ProjectName}
</span>`;
            }).join("");

            const statusOptions = statusList.map(s => {

                const isSelected = selectedStatusIDs.includes(s.StatusID);
                return `<span class="fpd-option ${isSelected ? "selected" : ""}" data-type="status" data-val="${s.StatusID}"
 style="${isSelected ? "" : `border-color:${s.Color || "#ccc"};color:${s.Color || "#666"}`}">
                                    <span style="display:inline-block;width:7px;height:7px;border-radius:50%;background:${s.Color || "#ccc"};margin-right:4px;"></span>${s.StatusName}
                                </span>`;

            }).join("");

            const tagOptions = tags.map(t => {
                const isSelected = selectedTagIDs.includes(t.TagID);
                return `<span class="fpd-option ${isSelected ? "selected" : ""}" data-type="tag" data-val="${t.TagID}"># ${t.TagName}</span>`;
            }).join("");

            const priorityOptions = [
                { val: 3, label: "Cao" },
                { val: 2, label: "Trung bình" },
                { val: 1, label: "Thấp" }
            ].map(p => {
                const isSelected = selectedPriorityFilters.includes(p.val);
                return `<span class="fpd-option ${isSelected ? "selected" : ""}" data-type="priority" data-val="${p.val}">${p.label}</span>`;
            }).join("");

            // Move controls back to storage BEFORE clearing dropdown innerHTML
            const $storage = $("#fpd-date-storage");
            if ($storage.length) {
                const $ctrlDateF = $("#PC6BB82D3F057477BBEA1A0BD3B77AF2D");
                const $ctrlDateT = $("#P72DD5A0B80D24D4EBFFF8F48E6B6D838");
                const $ctrlProj = $("#P794C2F8348554BF6B8EB236EC6F3A215");
                const $ctrlEmp = $("#P_Filter_EmployeeID");
                if ($ctrlDateF.length) $storage.append($ctrlDateF);
                if ($ctrlDateT.length) $storage.append($ctrlDateT);
                if ($ctrlProj.length) $storage.append($ctrlProj);
                if ($ctrlEmp.length) $storage.append($ctrlEmp);
            }

            $dropdown.html(`
                        ${window.innerWidth < 768 ? `
                        <div class="fpd-header-mobile" style="display:flex; justify-content:center; align-items:center; position:relative; padding:16px 16px 8px 16px; border-bottom:1px solid #f1f5f9;">
                            <div class="fpd-pull-bar" style="position:absolute; top:8px; left:50%; transform:translateX(-50%); width:40px; height:4px; border-radius:2px; background:#cbd5e1;"></div>
                            <span style="font-weight: bold; font-size: 1.1rem; padding-top:4px;">%Filter%</span>
                            <button class="btn-close-filter-mobile" style="position:absolute; right:8px; top:8px; border:none; background:none; font-size:1.5rem; color:#94a3b8; padding:4px 8px; cursor:pointer; z-index:10;"><i class="bi bi-x-lg"></i></button>
                        </div>
                        ` : ""}
                        <div class="fpd-body">
                            <div class="fpd-section">
                                <div class="fpd-label"><i class="bi bi-calendar-range"></i> %StartAssignmentPeriod%</div>
                                <div style="display:flex;align-items:center;gap:6px;width: 100%;overflow: auto;">
                                    <div id="fpd-slot-from" style="flex:1;"></div>
                                    <span style="color:#94a3b8;flex-shrink:0;">→</span>
                                    <div id="fpd-slot-to" style="flex:1;"></div>
                                </div>
                                <div class="fpd-options mt-2">
${dueDates.map(d => `
                                        <span class="fpd-option ${selectedDueDateFilter === d.val ? "selected" : ""}" data-type="duedate" data-val="${d.val}">
                                       <i class="bi ${d.icon}"></i> ${d.label}
                                        </span>
                                    `).join("")}
                                </div>
                            </div>
                            <div class="fpd-section">
                                <div class="fpd-label"><i class="bi bi-folder2"></i> %Project%</div>
                                <div id="filter-project-tagbox-container"></div>
                            </div>
                            <div class="fpd-section">
                                <div class="fpd-label"><i class="bi bi-person"></i> %Employee%</div>
                                <div id="filter-employee-tagbox-container"></div>
                            </div>
                            <div class="fpd-section">
                                <div class="fpd-label"><i class="bi bi-star-fill text-warning"></i> %Priority%</div>
                                <div class="fpd-options">${priorityOptions}</div>
                            </div>
                            <div class="fpd-section">
                                <div class="fpd-label"><i class="bi bi-circle-half"></i> %Status%</div>
                                <div class="fpd-options">${statusOptions}</div>
                            </div>
                            <div class="fpd-section">
                                <div class="fpd-label"><i class="bi bi-hash"></i> %Tag%</div>
                                <div class="fpd-options">${tagOptions || "<i>No tags</i>"}</div>
                            </div>
                        </div>
                        <div class="fpd-footer" style="padding: 16px 24px; border-top:1px solid #eee; display:flex; justify-content:space-between;">
                        <button id="fpd-btn-clear-all" class="fpd-btn-clear" style="border:1px solid #fca5a5; border-radius:8px; padding:8px 16px; background:none; color:#dc2626; font-size:0.85rem; font-weight: 600;">
                                <i class="bi bi-x-circle me-1"></i>%ClearAll%
                            </button>
                            <button id="fpd-btn-apply" class="btn btn-success px-4 py-2" style="border-radius:8px; font-weight: 600;">
                                <i class="bi bi-check-lg me-1"></i>%Apply%
                            </button>
                        </div>
                    `);

            // Chặn tất cả click/touch từ các control bên trong không bubble lên ngoài
            setTimeout(function () {
                const $fpd = $("#filter-advanced-dropdown");

                // Chặn toàn bộ event bubble từ bên trong dropdown
                $fpd.off("click.fpdStop mousedown.fpdStop touchstart.fpdStop touchend.fpdStop")
                    .on("click.fpdStop mousedown.fpdStop touchstart.fpdStop touchend.fpdStop", function (e) {
                        e.stopPropagation();
                    });

                // Riêng các DevExtreme overlay (render ra ngoài body) cũng cần chặn
                $(document).off("click.fpdDxStop mousedown.fpdDxStop touchstart.fpdDxStop")
                    .on("click.fpdDxStop mousedown.fpdDxStop touchstart.fpdDxStop", function (e) {
                        const isDxOverlay = $(e.target).closest([
                            ".dx-overlay-wrapper",
                            ".dx-overlay-content",
                            ".dx-popup-wrapper",
                            ".dx-selectbox-popup-wrapper",
                            ".dx-tagbox-popup-wrapper",
                            ".dx-dropdowneditor-overlay",
                            ".dx-list",
                            ".dx-scrollable"
                        ].join(",")).length > 0;

                        if (isDxOverlay) {
                            e.stopPropagation();
                        }
                    });
            }, 100);

            // Handle date controls
            const $slotDateF = $("#fpd-slot-from");
            const $slotDateT = $("#fpd-slot-to");
            const $slotProj = $("#filter-project-tagbox-container");
            const $slotEmp = $("#filter-employee-tagbox-container");

            const $ctrlDateF = $("#PC6BB82D3F057477BBEA1A0BD3B77AF2D");
            const $ctrlDateT = $("#P72DD5A0B80D24D4EBFFF8F48E6B6D838");
            const $ctrlProj = $("#P794C2F8348554BF6B8EB236EC6F3A215");
            const $ctrlEmp = $("#P_Filter_EmployeeID");

            if ($slotDateF.length && $ctrlDateF.length) $slotDateF.append($ctrlDateF);
            if ($slotDateT.length && $ctrlDateT.length) $slotDateT.append($ctrlDateT);
            if ($slotProj.length && $ctrlProj.length) $slotProj.append($ctrlProj);
            if ($slotEmp.length && $ctrlEmp.length) $slotEmp.append($ctrlEmp);

            setTimeout(() => {
                const instFrom = getInstanceByUID("PC6BB82D3F057477BBEA1A0BD3B77AF2D");
                const instTo = getInstanceByUID("P72DD5A0B80D24D4EBFFF8F48E6B6D838");
                const instEmp = getInstanceByUID("P_Filter_EmployeeID");
                const instProj = getInstanceByUID("P794C2F8348554BF6B8EB236EC6F3A215");

                if (instFrom) { instFrom.option("value", filterDateFrom); instFrom.repaint(); }
                if (instTo) { instTo.option("value", filterDateTo); instTo.repaint(); }
                if (instProj) {
                    instProj.repaint();
                    $("#P794C2F8348554BF6B8EB236EC6F3A215")
                        .css("pointer-events", "auto")
                        .find("*")
                        .css("pointer-events", "auto");
                }
                if (instEmp) { instEmp.option("value", selectedEmployeeIDs); instEmp.repaint(); }
            }, 50);

            $dropdown.find(".fpd-option").off("click").on("click", function (e) {
                e.stopPropagation();
                const $this = $(this);
                const type = $this.data("type");
                let val = $this.data("val");
                val = isNaN(val) ? val : parseInt(val);

                if (type === "project") toggleArr(selectedProjectIDs, val);
                if (type === "status") toggleArr(selectedStatusIDs, val);
                if (type === "tag") toggleArr(selectedTagIDs, val);
                if (type === "priority") toggleArr(selectedPriorityFilters, val);
                if (type === "duedate") selectedDueDateFilter = (selectedDueDateFilter === val) ? null : val;

                _fpdFilterChanged = true;
                refreshOptionStates();
            });

            $("#fpd-btn-clear-all").off("click").on("click", function (e) {
                e.stopPropagation();
                selectedProjectIDs = [];
                selectedStatusIDs = [];
                selectedTagIDs = [];
                selectedPriorityFilters = [];
                selectedEmployeeIDs = [];
                selectedDueDateFilter = null;

                const def = getDefaultDateRange();
                filterDateFrom = def.from;
                filterDateTo = def.to;

                // Reset UI date pickers
                const instFrom = getInstanceByUID("PC6BB82D3F057477BBEA1A0BD3B77AF2D");
                const instTo = getInstanceByUID("P72DD5A0B80D24D4EBFFF8F48E6B6D838");
                const instProj = getInstanceByUID("P794C2F8348554BF6B8EB236EC6F3A215");
                const instEmp = getInstanceByUID("P_Filter_EmployeeID");

                if (instFrom) instFrom.option("value", filterDateFrom);
                if (instTo) instTo.option("value", filterDateTo);
                if (instProj) instProj.option("value", []);
                if (instEmp) instEmp.option("value", []);

                _fpdFilterChanged = true;
                refreshOptionStates();
            });

            $("#fpd-btn-apply").off("click").on("click", function (e) {
                e.stopPropagation();
                closeDropdown(true);
            });

            // Fix: Stop propagation on drawer clicks
            $dropdown.off("click").on("click", (e) => e.stopPropagation());

            // Fix: Functional Close Button
            $dropdown.find(".btn-close-filter-mobile").off("click").on("click", (e) => {
                e.stopPropagation();
                closeDropdown(false);
            });
        }

        let _fpdFilterChanged = false;
        let _fpdBackup = {};

        function openDropdown() {
            _fpdFilterChanged = false;
            $("body").css("overflow", "hidden"); // Lock scroll

            // Desktop positioning fix
            if (window.innerWidth >= 768) {
                const $wrap = $("#filter-advanced-wrap");
                if ($wrap.length) {
                    const rect = $wrap[0].getBoundingClientRect();
                    const $parent = $("#sp_Task_TaskList_html");
                    const parentRect = $parent[0].getBoundingClientRect();
                    $dropdown.css({
                        top: (rect.bottom - parentRect.top + 8) + "px",
                        right: (parentRect.right - rect.right) + "px",
                        position: "absolute"
                    });
                }
            }

            const $overlay = $("#mb-filter-overlay");
            if ($overlay.length) {
                $overlay.addClass("active")
                    .off("click touchend")
                    .on("click touchend", function (e) {
                        e.stopPropagation();
                        closeDropdown(false);
                    });
            }

            _fpdBackup = {
                projects: [...selectedProjectIDs],
                statuses: [...selectedStatusIDs],
                tags: [...selectedTagIDs],
                priorities: [...selectedPriorityFilters],
                employees: [...selectedEmployeeIDs],
                dueDate: selectedDueDateFilter,
                dateFrom: filterDateFrom,
                dateTo: filterDateTo
            };

            $dropdown.addClass("show");
            $btn.addClass("open");
            renderDropdown();
        }

        function closeDropdown(forceReload = false) {
            if (!$dropdown.hasClass("show")) return;
            $(document).off("click.fpdDxStop mousedown.fpdDxStop touchstart.fpdDxStop");
            $("body").css("overflow", ""); // Unlock scroll

            const $overlay = $("#mb-filter-overlay");
            if ($overlay.length) $overlay.removeClass("active");


            $dropdown.removeClass("show");
            $btn.removeClass("open");

            // Commit or Rollback
            if (forceReload || _fpdFilterChanged) {
                const instFrom = getInstanceByUID("PC6BB82D3F057477BBEA1A0BD3B77AF2D");
                const instTo = getInstanceByUID("P72DD5A0B80D24D4EBFFF8F48E6B6D838");
                const instProj = getInstanceByUID("P794C2F8348554BF6B8EB236EC6F3A215");
                const instEmp = getInstanceByUID("P_Filter_EmployeeID");

                if (instFrom) filterDateFrom = instFrom.option("value");
                if (instTo) filterDateTo = instTo.option("value");
                if (instProj) {
                    const val = instProj.option("value");
                    const fmtVal = formatIDList(val);
                    selectedProjectIDs = fmtVal ? fmtVal.split(",").map(id => parseInt(id)) : [];
                }
                if (instEmp) {
                    const val = instEmp.option("value");
                    const fmtVal = formatIDList(val);
                    selectedEmployeeIDs = fmtVal ? fmtVal.split(",") : [];
                }
                if (typeof window.saveFilterState === "function") window.saveFilterState();
            } else if (_fpdBackup.projects) {
                selectedProjectIDs = [...(_fpdBackup.projects || [])];
                selectedStatusIDs = [...(_fpdBackup.statuses || [])];
                selectedTagIDs = [...(_fpdBackup.tags || [])];
                selectedPriorityFilters = [...(_fpdBackup.priorities || [])];
                selectedEmployeeIDs = [...(_fpdBackup.employees || [])];
                selectedDueDateFilter = _fpdBackup.dueDate;
                filterDateFrom = _fpdBackup.dateFrom;
                filterDateTo = _fpdBackup.dateTo;
            }

            // Wait for 400ms closing animation to finish
            setTimeout(() => {
                const $storage = $("#fpd-date-storage");

                const $ctrlDateF = $("#PC6BB82D3F057477BBEA1A0BD3B77AF2D");
                const $ctrlDateT = $("#P72DD5A0B80D24D4EBFFF8F48E6B6D838");
                const $ctrlProj = $("#P794C2F8348554BF6B8EB236EC6F3A215");
                const $ctrlEmp = $("#P_Filter_EmployeeID");

                if ($storage.length) {
                    if ($ctrlDateF.length) $storage.append($ctrlDateF);
                    if ($ctrlDateT.length) $storage.append($ctrlDateT);
                    if ($ctrlProj.length) $storage.append($ctrlProj);
                    if ($ctrlEmp.length) $storage.append($ctrlEmp);
                }

                if (forceReload || _fpdFilterChanged) {
                    _fpdFilterChanged = false;
                    ReloadData();
                }
            }, 400);

            updateLabel();
        }

        window.openDropdown = openDropdown;
        window.closeDropdown = closeDropdown;

        function refreshOptionStates() {
            $dropdown.find(".fpd-option").each(function () {
                const $el = $(this);
                const type = $el.data("type");
                const rawVal = $el.data("val");
                const val = isNaN(rawVal) ? rawVal : parseInt(rawVal);

                let isSelected = false;
                if (type === "project") isSelected = selectedProjectIDs.includes(val);
                if (type === "status") isSelected = selectedStatusIDs.includes(val);
                if (type === "tag") isSelected = selectedTagIDs.includes(val);
                if (type === "priority") isSelected = selectedPriorityFilters.includes(val);
                if (type === "duedate") isSelected = (selectedDueDateFilter === val);

                $el.toggleClass("selected", isSelected);
            });
            updateLabel();
        }

        $btn.off("click").on("click", function (e) {
            e.stopPropagation();
            $dropdown.hasClass("show") ? closeDropdown(false) : openDropdown();
        });

        updateLabel();
    }

    function getMainAssigneeManagerID() {
        // Ưu tiên dùng biến lưu trực tiếp để tránh race condition với DevExtreme control
        let mainAssigneeID = window._currentCreateAssigneeID || null;

        // Fallback về reading control nếu biến chưa có
        if (!mainAssigneeID) {
            const mainAssigneeInst = getInstanceByUID("P0902358F935A441E868AADCB1DBFCF64");
            let raw = mainAssigneeInst ? mainAssigneeInst.option("value") : null;
            if (raw) {
                raw = formatIDList(raw);
                mainAssigneeID = raw ? raw.split(",")[0] : null;
            }
        }

        // Nếu vẫn rỗng, thử đọc từ Assignee control
        if (!mainAssigneeID) {
            const assigneeInst = getInstanceByUID("PD76FE9F7E30A44A08B305AC908595419");
            let assigneeID = assigneeInst ? assigneeInst.option("value") : null;
            if (assigneeID) {
                assigneeID = formatIDList(assigneeID);
                mainAssigneeID = assigneeID ? assigneeID.split(",")[0] : null;
            }
        }

        if (!mainAssigneeID) return null;

        const emp = employees.find(e =>
            String(e.EmployeeID) === String(mainAssigneeID) ||
            String(e.EmployeeID).padStart(3, "0") === String(mainAssigneeID)
        );
        const managerId = emp && emp.LineManagerID ? String(emp.LineManagerID) : null;
        return managerId;
    }

    function getDefaultApprover(requestId) {
        const managerID = getMainAssigneeManagerID();
        if (managerID) {
            return managerID;
        }

        // Không có LineManager của Assignee → fallback về LineManager của Requester

        // Không lấy chính Requester làm người duyệt
        if (!requestId) return null;

        const mainAssigneeInst = getInstanceByUID("P0902358F935A441E868AADCB1DBFCF64");
        const mainAssigneeID = mainAssigneeInst ? String(formatIDList(mainAssigneeInst.option("value") || "")).split(",")[0] : "";

        const requester = employees.find(e =>
            String(e.EmployeeID) === String(requestId) ||
            String(e.EmployeeID).padStart(3, "0") === String(requestId)
        );

        if (requester && requester.LineManagerID) {
            // Nếu LineManager của Requester chính là MainAssignee → không dùng
            if (String(requester.LineManagerID) === mainAssigneeID) {
                return null;
            }
            return String(requester.LineManagerID);
        }

        return null;
    }

    function getDefaultDateRange() {
        const now = new Date();
        const from = new Date(now.getFullYear(), now.getMonth() - 1, 1);
        const to = new Date(now.getFullYear(), now.getMonth() + 2, 0); // cuối tháng sau
        return { from, to };
    };

    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'P63128D34B83D4F9EA7BEB928C35C7CF7'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'P279678A95C514D7B815B1B357824875D'),'let Instance','window.Instance'),'')+N'

    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'PD76FE9F7E30A44A08B305AC908595419'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'P1D812C8523D54ECFB8BDE98FE5E7EF98'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'PDADFE6D548FF40EE8109B030B5B31AE9'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'P1257D8B184374728847FCB0CAEC1B7DB'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'P0902358F935A441E868AADCB1DBFCF64'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'P3F6E55934BF74079A3EBA78D91296EE0'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'PEBB780F668924A108C0A9FF20D70CD80'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'PF542142C17247A09FCD23C6FCF8462P'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'P4386BF8B5C97415683E8B1F2FAA230DB'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'P25F5CBFA3D854FFD8AC3C1984B5439FC'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'P136F0762551345078797DB3CC80DA470'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'P9686718A3B6347518BDF5C6E3E8A391B'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'PC6BB82D3F057477BBEA1A0BD3B77AF2D'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'P72DD5A0B80D24D4EBFFF8F48E6B6D838'),'let Instance','window.Instance'),'')+N'
    '+ISNULL(REPLACE((select loadUI from tblCommonControlType_Signed where UID = 'P794C2F8348554BF6B8EB236EC6F3A215'),'let Instance','window.Instance'),'')+N'

    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'P63128D34B83D4F9EA7BEB928C35C7CF7'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'P279678A95C514D7B815B1B357824875D'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'PD76FE9F7E30A44A08B305AC908595419'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'P1D812C8523D54ECFB8BDE98FE5E7EF98'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'PDADFE6D548FF40EE8109B030B5B31AE9'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'P1257D8B184374728847FCB0CAEC1B7DB'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'P0902358F935A441E868AADCB1DBFCF64'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'P3F6E55934BF74079A3EBA78D91296EE0'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'PEBB780F668924A108C0A9FF20D70CD80'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'PF542142C17247A09FCD23C6FCF8462P'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'P4386BF8B5C97415683E8B1F2FAA230DB'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'P25F5CBFA3D854FFD8AC3C1984B5439FC'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'P136F0762551345078797DB3CC80DA470'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'P9686718A3B6347518BDF5C6E3E8A391B'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'PC6BB82D3F057477BBEA1A0BD3B77AF2D'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'P72DD5A0B80D24D4EBFFF8F48E6B6D838'),'')+N'
    '+ISNULL((select loadData from tblCommonControlType_Signed where UID = 'P794C2F8348554BF6B8EB236EC6F3A215'),'')+N'

    // Auto-inherit parent assignee for subtasks when parent assignee changes
    setTimeout(() => {
        const assigneeInst = getInstanceByUID("PD76FE9F7E30A44A08B305AC908595419");
        if (assigneeInst) {
            const syncAssigneeToMain = function (rawVal, isUserEvent) {
                const newVal = formatIDList(rawVal);
                const firstAssignee = newVal ? newVal.split(",")[0] : null;

                // Lưu ngay lập tức để tránh race condition khi đọc từ DevExtreme control
                window._currentCreateAssigneeID = firstAssignee;

                if (isUserEvent && firstAssignee) {
                    if (!tempApprovalSettings || tempApprovalSettings.Note === "%AutoActivatedNotInTemplate%") {
                        tempApprovalSettings = null;
                    }
                }

                if (firstAssignee && pendingSubtasks && pendingSubtasks.length > 0) {
                    pendingSubtasks.forEach(s => { s.AssigneeID = firstAssignee; });
                    renderPendingSubtasks();
                }

                // Chỉ fill Main Assignee nếu user chưa tự chọn (dùng flag)
                if (!window._mainAssigneeManuallySet) {
                    const parentMainAssigneeInst = getInstanceByUID("P0902358F935A441E868AADCB1DBFCF64");
                    if (parentMainAssigneeInst) {
                        // Đảm bảo dataSource đã load
                        const ds = parentMainAssigneeInst.option("dataSource");
                        if (!ds || (Array.isArray(ds) && ds.length === 0)) {
                            parentMainAssigneeInst.option("dataSource", employees);
                        }

                        let exactValToSet = null;
                        if (firstAssignee) {
                            const matchEmp = employees.find(e => String(e.EmployeeID) === String(firstAssignee) || String(e.EmployeeID).padStart(3, "0") === String(firstAssignee));
                            // Use the exact type that DevExtreme dataSource consumes (often Number or exact string without extra padding)
                            exactValToSet = matchEmp ? matchEmp.EmployeeID : firstAssignee;

                            // Bổ sung: Nếu valToSet trước đó là array (TagBox/GridSelection) thì gói lại trong array
                            const currVal = parentMainAssigneeInst.option("value");
                            if (Array.isArray(currVal) || parentMainAssigneeInst.NAME === "dxTagBox") {
                                exactValToSet = [exactValToSet];
                            }
                        }
                        setInstanceValue("P0902358F935A441E868AADCB1DBFCF64", exactValToSet);
                    }
                }

                setTimeout(() => {
                    if (typeof updateAutoApprovalState === "function") {
                        updateAutoApprovalState();
                    }
                }, 200);
            };

            // Control nhân viên là custom popup picker - KHÔNG fire DevExtreme onValueChanged khi chọn
            // Dùng MutationObserver để theo dõi khi DOM của ô Assignee thay đổi sau khi user chọn xong
            const $assigneeContainer = $("#PD76FE9F7E30A44A08B305AC908595419");
            if ($assigneeContainer.length) {
                let _lastAssigneeValue = null;
                const _assigneeObserver = new MutationObserver(function () {
                    const rawVal = formatIDList(getInstanceValue("PD76FE9F7E30A44A08B305AC908595419"));
                    const firstAssignee = rawVal ? rawVal.split(",")[0] : null;

                    if (firstAssignee === _lastAssigneeValue) return; // Không đổi thì bỏ qua
                    _lastAssigneeValue = firstAssignee;

                    // Auto-set Main Assignee
                    syncAssigneeToMain(rawVal, true);

                    // Lưu ngay vào biến để getMainAssigneeManagerID đọc được đúng
                    window._currentCreateAssigneeID = firstAssignee;

                    // Validate LineManagerID
                    if (firstAssignee) {
                        const emp = employees.find(e =>
                            String(e.EmployeeID) === String(firstAssignee) ||
                            String(e.EmployeeID).padStart(3, "0") === String(firstAssignee)
                        );
                        if (emp && !emp.LineManagerID) {
                            // Check nếu là mẫu thuần túy thì không báo lỗi vì không cần người duyệt
                            if (typeof isTaskActuallyTemplate === "function" && isTaskActuallyTemplate()) {
                                window._noManagerWarning = false;
                                return;
                            }
                            window._noManagerWarning = true;
                            uiManager.showAlert({ type: "warning", message: "Người thực hiện chưa có quản lý trực tiếp. Vui lòng chọn người duyệt thủ công hoặc chọn người thực hiện khác." });
                            window._currentCreateAssigneeID = null;
                            tempApprovalSettings = null;
                            if (typeof updateApprovalUI === "function") updateApprovalUI({ RequireApproval: false });
                            return;
                        }
                        // Nhân viên hợp lệ (có manager) → xóa cảnh báo
                        window._noManagerWarning = false;
                    }

                    // Reset auto-approval để updateAutoApprovalState tính lại
                    if (!tempApprovalSettings || tempApprovalSettings.Note === "%AutoActivatedNotInTemplate%") {
                        tempApprovalSettings = null;
                    }

                    setTimeout(() => {
                        if (typeof updateAutoApprovalState === "function") updateAutoApprovalState();
                    }, 100);
                });
                _assigneeObserver.observe($assigneeContainer[0], { childList: true, subtree: true });
            }
        }

        // Theo dõi thay đổi Phụ trách chính (khi user tự chọn)
        setTimeout(() => {
            const mainAssigneeInst = getInstanceByUID("P0902358F935A441E868AADCB1DBFCF64");
            if (mainAssigneeInst) {
                mainAssigneeInst.option("onValueChanged", function (e) {
                    const mainAssigneeID = e.value !== null && e.value !== undefined ? String(e.value).padStart(3, "0") : null;

                    // e.event tồn tại nghĩa là user tự chọn (có interaction)
                    if (e.event) {
                        window._mainAssigneeManuallySet = true;
                    }

                    if (mainAssigneeID && mainAssigneeID !== "null" && pendingSubtasks && pendingSubtasks.length > 0) {
                        pendingSubtasks.forEach(s => { s.MainAssigneeID = mainAssigneeID; });
                        renderPendingSubtasks();
                    }

                    if (typeof updateAutoApprovalState === "function") {
                        updateAutoApprovalState();
                    }
                });
            }

            const requesterInst = getInstanceByUID("P1257D8B184374728847FCB0CAEC1B7DB");
            if (requesterInst) {
                requesterInst.option("onValueChanged", function (e) {
                    const newVal = e.value;
                    // Sync all pending subtasks immediately
                    if (Array.isArray(pendingSubtasks)) {
                        pendingSubtasks.forEach(s => {
                            s.RequestID = newVal ? String(newVal) : null;
                        });
                    }
                    if (typeof updateAutoApprovalState === "function") {
                        updateAutoApprovalState();
                    }
                });
            }
        }, 1500);
        // Tự động bật phê duyệt khi người dùng nhập tên task mà không chọn mẫu (khi click ra ngoài)
        const $taskNameContainer = $("#P63128D34B83D4F9EA7BEB928C35C7CF7");
        if ($taskNameContainer.length) {
            // focusout vẫn giữ để xử lý khi click ra ngoài
            $taskNameContainer.off("focusout").on("focusout", function () {
                setTimeout(() => {
                    if (typeof updateAutoApprovalState === "function") updateAutoApprovalState();
                }, 200);
            });

            // Thêm listener trên input bên trong để phát hiện khi người dùng sửa/chỉnh tên
            try {
                if (!$taskNameContainer.attr("data-auto-listener-attached")) {
                    const $innerInput = $taskNameContainer.find("input, textarea");
                    if ($innerInput.length) {
                        let inputDebounce = null;
                        $innerInput.on("input", function () {
                            clearTimeout(inputDebounce);
                            inputDebounce = setTimeout(() => {
                                if (typeof updateAutoApprovalState === "function") updateAutoApprovalState();
                            }, 250);
                        });
                    }

                    // Bắt event xóa taskname của template thì xóa các subtask khác
                    $taskNameContainer.attr("data-auto-listener-attached", "1");

                    const $innerInput2 = $taskNameContainer.find("input, textarea");
                    if ($innerInput2.length) {
                        $innerInput2.on("input", function () {
                            const val = $(this).val().trim();
                            if (!val && window.lastSelectedTemplateID) {
                                // Xóa hết subtask từ mẫu, giữ lại subtask manual
                                pendingSubtasks = pendingSubtasks.filter(s => !s.IsFromTemplate);
                                window.lastSelectedTemplateID = null;
                                window.lastSelectedTemplateName = "";
                                window.editingSubtaskIndex = -1;
                                window.currentAssigneeIndex = -1;
                                renderPendingSubtasks();
                            }
                        });
                    }
                }
            } catch (e) {
                console.warn("Could not attach input listener to taskName control", e);
            }
        }
    }, 1500);

    // --- GHI ĐÈ DateBox Hạn (Due Date) bằng flatpickr ---
    const initFlatpickrMain = () => {
        const hasLib = typeof flatpickr !== "undefined";
        if (!hasLib) {
            setTimeout(initFlatpickrMain, 150);
            return;
        }

        // vn locale optional - fallback về default nếu chưa load
        try {
            if (flatpickr.l10ns && flatpickr.l10ns.vn) {
                flatpickr.setDefaults({ locale: flatpickr.l10ns.vn });
            }
        } catch (e) { }

        const $fpTarget = $("#P1D812C8523D54ECFB8BDE98FE5E7EF98");
        if (!$fpTarget.length) { setTimeout(initFlatpickrMain, 150); return; }

        // Destroy cũ nếu có
        if ($fpTarget[0]._flatpickr) { $fpTarget[0]._flatpickr.destroy(); }

        window.InstanceDueDateP1D812C8523D54ECFB8BDE98FE5E7EF98 = flatpickr($fpTarget[0], {
            dateFormat: "d/m/Y",
            allowInput: true,
            disableMobile: false,
            appendTo: document.body,
            onClose: function (selectedDates, dateStr, instance) {
                if (typeof scheduleDraftSave === "function") scheduleDraftSave();
            }
        });
    };
    initFlatpickrMain();

    function loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback) {
        if (!columnName || !dataSourceSP || dataSourceSP.trim() === "") {
            console.warn("[loadDataSourceCommon] Missing columnName or dataSourceSP");
            return;
        }

        const dataSourceKey = "DataSource_" + columnName;
        // Sử dụng format: columnNameDataSourceLoaded để tương thích với code hiện tại
        const loadedKey = columnName + "DataSourceLoaded";

        // Kiểm tra nếu đã load rồi thì không load lại
        if (window[loadedKey] === true) {
            if (typeof onSuccessCallback === "function") {
                onSuccessCallback(window[dataSourceKey] || []);
            }
            return;
        }

        // Kiểm tra nếu đang load thì đợi
        if (window[loadedKey] === "loading") {
            // Đợi một chút rồi thử lại
            setTimeout(function () {
                loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback);
            }, 100);

            return;
        }


        // Đánh dấu đang load để tránh load trùng lặp
        window[loadedKey] = "loading";

        return new Promise((resolve, reject) => {
            AjaxHPAParadise({
                data: {
                    name: dataSourceSP,
                    param: ["LoginID", LoginID, "LanguageID", LanguageID]
                },
                success: function (res) {
                    const json = typeof res === "string" ? JSON.parse(res) : res;

                    window[dataSourceKey] = (json.data && json.data[0]) || [];
                    window[loadedKey] = true;

                    // Ưu tiên lấy từ json response (nếu API trả về explicit)
                    // Sau đó mới fallback query dataSchema
                    let idField = json.valueExpr;
                    let nameField = json.displayExpr;

                    if (!idField || !nameField) {
                        if (json.dataSchema && json.dataSchema[0]) {
                            const schema = json.dataSchema[0];
                            if (!idField) idField = schema[0]?.name;
                            if (!nameField) nameField = schema[1]?.name;
                        }
                    }

                    window["DataSourceIDField_" + columnName] = idField || "ID";
                    window["DataSourceNameField_" + columnName] = nameField || "Name";

                    const data = window[dataSourceKey];

                    // callback trước
                    if (typeof onSuccessCallback === "function") {
                        onSuccessCallback(data, json);
                    }

                    // resolve sau
                    resolve(data);

                },
                error: function (err) {
                    console.error("[loadDataSourceCommon] Failed to load datasource for", columnName, ":", err);
                    window[loadedKey] = false;

                    if (typeof onSuccessCallback === "function") {
                        onSuccessCallback([]);
                    }

                    reject(err);
                }
            });
        });
    }

    // =============== LOGIC DANH MỤC KIỂM TRA (CHECKLIST) ===============
    if (typeof pendingChecklist === "undefined" || !Array.isArray(pendingChecklist)) {
        pendingChecklist = [];
    }
    function renderChecklist(historyId) {
        const $listContainer = $("#checklist-items-list");
        if (!$listContainer.length) return;

        let items = [];
        if (historyId === 0 || (window.activeDraftHistoryID && historyId === window.activeDraftHistoryID)) {
            items = pendingChecklist;
        } else {
            items = (window.checklists || []).filter(c => c.HistoryID === historyId);
        }

        // Cập nhật Tiến độ Compact (Header)
        const completed = items.filter(c => c.IsDone).length;
        const total = items.length;
        const percent = total > 0 ? Math.round((completed / total) * 100) : 0;

        $("#checklist-progress-bar").css("width", percent + "%");
        $("#checklist-count-text").text(`${completed}/${total}`);
        $("#checklist-percent-text").text(`${percent}%`);

        // Điều khiển hiển thị ô nhập checklist
        const $addBoxWrapper = $("#checklist-add-box-wrapper");
        if ($addBoxWrapper.length) {
            if (total === 0) {
                $addBoxWrapper.hide();
            } else {
                $addBoxWrapper.show().css("display", "flex");
            }
        }

        $listContainer.html(items.map((item, index) => {
            const id = historyId === 0 ? index : item.ChecklistID;
            return `
        <div class="checklist-card-item d-flex align-items-center gap-3 border-0 rounded-4"
                         data-id="${id}"
                        style="background-color: var(--bs-tertiary-bg, #f8fafc); padding: 10px 14px; transition: all 0.2s; cursor: pointer; position: relative;">

           <div class="checklist-custom-check d-flex align-items-center justify-content-center flex-shrink-0"
      style="width: 28px; height: 28px; border-radius: 8px; background-color: ${item.IsDone ? ''#d1fae5'' : ''var(--bs - primary - bg, #ffffff)''
        }; color: ${ item.IsDone ? ''#10b981'' : ''#cbd5e1'' }; border: 1px solid ${ item.IsDone ? ''#10b981'' : ''#e2e8f0'' }; transition: all 0.3s; ">
            < i class="bi ${item.IsDone ? ''bi-check-lg'' : ''bi-app''} fs-5" style = "-webkit-text-stroke: 1px;" ></i >
                        </div >

                        <div class="flex-grow-1 overflow-hidden">
                            <input type="text" class="checklist-item-text fw-bold m-0 p-0"
                                   value="${(item.ItemName || "").replace(/"/g, "&quot;")}"
                                   style="width: 100%; border: none; background: transparent; outline: none; font-size: 0.9rem; color: ${item.IsDone ? ''#94a3b8'' : ''var(--bs-body-color, #1e293b)''}; text-decoration: ${item.IsDone ? ''line-through'' : ''none''}; transition: all 0.3s;">
                        </div>

                        <div class="d-flex align-items-center gap-2">
                            ${item.IsDone ? `<span class="badge rounded-pill text-uppercase d-none d-sm-inline-block" style="background-color: rgba(16, 185, 129, 0.15); color: #10b981; font-size: 0.6rem; padding: 4px 10px; font-weight: 800; letter-spacing: 0.5px;">Done</span>` : ''''}
                            <i class="bi bi-trash checklist-btn-delete text-danger" style="cursor: pointer; font-size: 1rem; padding: 4px; transition: opacity 0.2s;"></i>
                        </div>
                    </div >

            `;
                }).join(""));

                // Attach event listeners to checklist items
                $("#checklist-items-list").off("click change blur keypress")
                .on("click", ".checklist-btn-delete", function(e) {
   e.stopPropagation();
                    const id = $(this).closest(".checklist-card-item").data("id");
                    deleteChecklistItem(Number(id));
                })
                .on("click", ".checklist-item-text", function(e) {
                    if (document.activeElement !== this) {
                        const id = $(this).closest(".checklist-card-item").data("id");
                        const item = items[id] || items.find(it => String(it.ChecklistID) === String(id));
                        const isDone = item ? !!item.IsDone : false;
                        toggleChecklistItem(Number(id), isDone ? 0 : 1);
                    }
                })
                .on("click", ".checklist-card-item", function(e) {
                    if (!$(e.target).is(".checklist-item-text, .checklist-btn-delete")) {
                        const id = $(this).data("id");
                        const item = items[id] || items.find(it => String(it.ChecklistID) === String(id));
                        const isDone = item ? !!item.IsDone : false;
                        toggleChecklistItem(Number(id), isDone ? 0 : 1);
                    }
                })
                .on("blur", ".checklist-item-text", function() {
                    const id = $(this).closest(".checklist-card-item").data("id");
                    updateChecklistItem(Number(id), $(this).val());
                })

                .on("keypress", ".checklist-item-text", function(e) {
                    if (e.key === "Enter") {
                        $(this).blur();
                    }
                });
               if (historyId === 0) {
                    scheduleDraftSave();
                }
            }

            function addChecklistItem() {
                if (window.isSubmittingTask) return;

                const $input = $("#checklist-add-input");
                if (!$input.length) return;

                const val = $input.val().trim();
                if (!val) {
                    $input.focus();
          return;
                }

                window.isSubmittingTask = true;
                const $btnAdd = $("#btn-add-checklist-item");
                if ($btnAdd.length) $btnAdd.prop("disabled", true);

                const historyId = window.currentRecordID_HistoryID || 0;

          // Sync with local draft early so it knows a change is happening
                saveDraft();

                if (historyId === 0) {
                    window.isSubmittingTask = false;
                    if ($btnAdd.length) $btnAdd.prop("disabled", false);
                    return;
                }

                AjaxHPAParadise({
                    data: {
                        name: "sp_Task_Checklist_Save",
                        param: [
                            "ChecklistID", 0,
                            "HistoryID", historyId,
                            "ItemName", val,
                            "IsDone", 0,
                            "LoginID", LoginID
                        ]
                    },
                    success: function (res) {
                        const resData = (typeof res === "string" ? JSON.parse(res) : res).data?.[0]?.[0] || {};
                        if (resData.Status === "SUCCESS" && resData.NewChecklistID) {
                            if (!pendingChecklist || !Array.isArray(pendingChecklist)) pendingChecklist = [];
                            pendingChecklist.push({
                                ChecklistID: resData.NewChecklistID,
                                HistoryID: historyId,
                                ItemName: val,
                                IsDone: false
           });
                            // Chỉ focus khi thực sự thêm thành công
                            $input.val("").focus();
                            renderChecklist(historyId);
      }
                        window.isSubmittingTask = false;
                        if ($btnAdd.length) $btnAdd.prop("disabled", false);
                        saveDraft();
                    },
                    error: function(err) {
                        window.isSubmittingTask = false;
                        if ($btnAdd.length) $btnAdd.prop("disabled", false);
                        console.error("Checklist Save Error:", err);
                    }
                });
            }

            function toggleChecklistItem(id, isDone) {
                const historyId = window.currentRecordID_HistoryID || 0;

                // Update local state if in Create Modal
                if (historyId === 0 || (window.activeDraftHistoryID && historyId === window.activeDraftHistoryID)) {
                    const item = (typeof id === "number" && pendingChecklist[id]) ? pendingChecklist[id] : pendingChecklist.find(it => String(it.ChecklistID) === String(id));
                    if (item) {
                        item.IsDone = !!isDone;
                        renderChecklist(historyId);
                        saveDraft();
                    }
                }

                if (historyId === 0) return;

                AjaxHPAParadise({
                    data: {
                        name: "sp_Task_Checklist_Toggle",
 param: [
                            "ChecklistID", id,
                            "IsDone", isDone,
                            "LoginID", LoginID
                        ]
                    },
                    success: function (res) {
                        saveDraft();
                    }
                });
            }

 function updateChecklistItem(id, name) {
                if (!name.trim()) return;
                const historyId = window.currentRecordID_HistoryID || 0;

                // Update local state if in Create Modal
                if (historyId === 0 || (window.activeDraftHistoryID && historyId === window.activeDraftHistoryID)) {
                    const item = (typeof id === "number" && pendingChecklist[id]) ? pendingChecklist[id] : pendingChecklist.find(it => String(it.ChecklistID) === String(id));
                    if (item) {
                item.ItemName = name;
                        renderChecklist(historyId);
                        saveDraft();
                    }
                }

                if (historyId === 0) return;

                AjaxHPAParadise({
                    data: {
                        name: "sp_Task_Checklist_Save",
                        param: [
                            "ChecklistID", id,
                            "HistoryID", historyId,
                            "ItemName", name,
                            "IsDone", null,
                            "LoginID", LoginID
                        ]
                    },
                    success: function (res) {
                        saveDraft();
                    }
                });
            }

            function deleteChecklistItem(id) {
                if (window.isSubmittingTask) return; // Không cho xóa khi đang thêm
                const historyId = window.currentRecordID_HistoryID || 0;

                const proceedDelete = () => {
                    // Update local state if in Create Modal
                    if (historyId === 0 || (window.activeDraftHistoryID && historyId === window.activeDraftHistoryID)) {
                        const index = (typeof id === "number" && pendingChecklist[id]) ? id : pendingChecklist.findIndex(it => String(it.ChecklistID) === String(id));
                        if (index !== -1) {
                            pendingChecklist.splice(index, 1);
                            renderChecklist(historyId);
                            saveDraft();
                        }
                    }

                    if (historyId === 0) return;

                    AjaxHPAParadise({
                        data: {
                            name: "sp_Task_Checklist_Delete",
                            param: [
                                "ChecklistID", id,
                                "LoginID", LoginID
                            ]
                        },
                        success: function (res) {
                            saveDraft();
                        }
                    });
                };

                if (typeof showConfirmPopup === "function") {
                    showConfirmPopup({
                   title: "%ConfirmDelete%",
                        message: "%ConfirmDeleteChecklistItem%",
                        onYes: proceedDelete
                    });
                }
            }

            // ========== HỖ TRỢ CÔNG VIỆC CON ĐANG CHỜ ==========
            window.isAddingSubtaskManual = false;
            window.editingSubtaskIndex = -1; // Theo dõi công việc con nào đang được sửa
            window.currentAssigneeIndex = -1; // Theo dõi người thực hiện công việc con nào đang được sửa

            // ========== DRAG AND DROP HANDLERS FOR SUBTASKS ==========
            function handleSubtaskDragStart(e, index) {
                const oe = e.originalEvent || e;
                if (oe.dataTransfer) oe.dataTransfer.setData("text/plain", index);
                $(e.target).closest(".subtask-item-wrapper").addClass("dragging");
            };

            function handleSubtaskDragOver(e) {
                e.preventDefault();
                $(e.target).closest(".subtask-item-wrapper").addClass("drag-over");
            };

            function handleSubtaskDragLeave(e) {
                $(e.target).closest(".subtask-item-wrapper").removeClass("drag-over");
            };

            function handleSubtaskDrop(e, toIndex) {
                e.preventDefault();
                const fromIndex = parseInt(e.dataTransfer.getData("text/plain"));

                $(".subtask-item-wrapper").removeClass("dragging drag-over");

                if (isNaN(fromIndex) || fromIndex === toIndex) return;

                // Sửa lại: tách item ra và chèn đúng vị trí
                const movedItem = pendingSubtasks.splice(fromIndex, 1)[0];

                // Tính toán lại toIndex sau khi splice

                const adjustedToIndex = fromIndex < toIndex ? toIndex - 1 : toIndex;
                pendingSubtasks.splice(adjustedToIndex, 0, movedItem);

                renderPendingSubtasks();
            }

            function buildSubAssigneeHTML(index, sub) {
                const ids = sub.AssigneeID
                    ? String(sub.AssigneeID).split(",").map(s => s.trim()).filter(Boolean)
                    : [];

                if (ids.length === 0) {
                    return `< div class="sub-assignee-trigger text-muted" data - index="${index}" style = "width:34px;height:34px;display:flex;align-items:center;justify-content:center;cursor:pointer;border-radius:50%;" > <i class="bi bi-person-plus"></i></div > `;
                }

                let avatarHtml = `< div class="d-flex align-items-center gap-1 sub-assignee-trigger" data - index="${index}" style = "cursor:pointer;" > `;

                ids.slice(0, 3).forEach((id, i) => {
                    const emp = employees.find(e =>
                        String(e.EmployeeID) === id ||
                        String(e.EmployeeID).padStart(3,"0") === id
                    );
                    const name = emp ? (emp.FullName || "?") : "?";
                    const cl = hpaUtils.getColorForId(id);
                    const initials = hpaUtils.getInitials(name);
    const cached = window.GlobalEmployeeAvatarCache?.[id];

                    avatarHtml += `< div style = "
        width: 28px; height: 28px; border - radius: 50 %;
        border: 2px solid #fff; box - shadow: 0 1px 3px rgba(0, 0, 0, 0.15);
        margin - left:${ i === 0 ? 0 : -8 } px; z - index:${ i + 1 };
        display: flex; align - items: center; justify - content: center;
        font - size: 0.6rem; font - weight: 700; overflow: hidden;
        background:${ cl.bg }; color:${ cl.text }; "
        title = "${name}" >
            ${
            cached
                ? `<img src="${cached}" style="width:100%;height:100%;object-fit:cover;">`
                : initials
        }
                    </div > `;
                });

                if (ids.length > 3) {
                    avatarHtml += `< div style = "width:28px;height:28px;border-radius:50%;
        background: #f1f5f9; color:#64748b; font - size: 0.6rem; font - weight: 700;
        display: flex; align - items: center; justify - content: center;
        margin - left: -8px; border: 2px solid #fff; ">
            + ${ ids.length - 3 }
                    </div > `;
                }

                avatarHtml += `</div > `;
                return avatarHtml;
            }

            function updateStandardTimeSummaryTaskList() {

                const instMainTime = getInstanceByUID("P136F0762551345078797DB3CC80DA470");
                if (!instMainTime) return;

                if (pendingSubtasks && pendingSubtasks.length > 0) {
                    const total = pendingSubtasks.reduce((sum, s) => sum + (parseFloat(s.StandardTime) || 0), 0);
                    instMainTime.option("value", total);
                    instMainTime.option("readOnly", true);
                } else {
                    instMainTime.option("readOnly", false);
                }
            }

            function renderPendingSubtasks() {
                updateStandardTimeSummaryTaskList();
                const isAdding = window.isAddingSubtaskManual;

                const $container = $("#added-subtasks-list");
                const $storage = $("#subtask-instances-storage");
                const $subNameCon = $("#P25F5CBFA3D854FFD8AC3C1984B5439FC");
                const $timeCon = $("#PF542142C17247A09FCD23C6FCF8462P");
                const $subAssignCon = $("#P4386BF8B5C97415683E8B1F2FAA230DB");

                // Detach controls first to prevent visible flash when DOM is replaced
                const $subNameConDetached = $subNameCon.length ? $subNameCon.detach() : $();
                const $timeConDetached    = $timeCon.length    ? $timeCon.detach()    : $();
                const $subAssignDetached  = ($subAssignCon.length && !window.assigneePopupActive) ? $subAssignCon.detach() : $();

                // Render List
         let htmlsection = pendingSubtasks.map((sub, index) => {
                    const isExpanded = window.editingSubtaskIndex === index;

                    let metricsHtml = "";
                    if (sub.StandardTime) {
                        metricsHtml = `< div class="text-muted d-flex gap-2" style = "font-size: 0.85rem;" > `;
                        metricsHtml += `< span style = "white-space: nowrap;" > <i class="bi bi-clock me-1"></i>${ sub.StandardTime } % minutes %</span > `;
                        metricsHtml += `</div > `;
                    }

                    return `
            < div class="subtask-item-wrapper mb-2" data - index="${index}" draggable = "true" >
                <div class="subtask-row d-flex flex-row flex-wrap align-items-center gap-2 px-3 py-2 rounded bg-body shadow-sm border justify-content-between">
                    <div class="d-flex align-items-center gap-2 flex-1" style="min-width:0;flex:1;">
                        <div class="drag-handle" style="flex-shrink:0;"><i class="bi bi-grip-vertical"></i></div>
                        <span class="text-muted fw-bold" style="font-size:0.78rem;flex-shrink:0;min-width:14px;">${index + 1}</span>
                        ${sub.IsInherited == 1 ?
                            `<span class="template-badge-inherited" style="font-size:0.68rem;padding:1px 6px;border-radius:4px;background:rgba(59,130,246,0.1);color:#3b82f6;font-weight:600;flex-shrink:0;border:1px solid rgba(59,130,246,0.2);"><i class="bi bi-diagram-3 me-1"></i>Kế thừa</span>`
                            : (sub.IsFromTemplate || sub.IsParentLink ?
                                `<span class="template-badge-manual" style="font-size:0.68rem;padding:1px 6px;border-radius:4px;background:rgba(59,130,246,0.1);color:#3b82f6;font-weight:600;flex-shrink:0;border:1px solid rgba(59,130,246,0.2);"><i class="bi bi-stack me-1"></i>Mẫu</span>`
                                : "")
                        }
                        <div style="min-width:0;flex:1;">
                            <div class="fw-semibold text-body subtask-task-name-text" style="font-size:0.9rem;line-height:1.3;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${sub.TaskName}</div>
                            ${metricsHtml}
                        </div>
                    </div>
                    <div class="d-flex align-items-center gap-2" style="flex-shrink:0;">
                        ${buildSubAssigneeHTML(index, sub)}

                        <div class="subtask-actions d-flex gap-1">
                            <div class="subtask-icon-btn btn-toggle-detail ${isExpanded ? " bg-primary text-white" : "bg-body text-body border"}" data-index="${index}" title="%Edit%" style="width: 34px; height: 34px; border-radius: 8px; display: flex; align-items: center; justify-content: center; cursor: pointer; ${sub.ApprovalStatus === 1 ? ''opacity: 0.5; cursor: not-allowed;'' : ''''}" ${sub.ApprovalStatus === 1 ? ''disabled'' : ''''}>
                            <i class="bi bi-${isExpanded ? " chevron-up" : "info-circle"}"></i>
                    </div>
                    <div class="subtask-icon-btn btn-remove-subtask bg-body text-danger border" data-index="${index}" style="width: 34px; height: 34px; border-radius: 8px; display: flex; align-items: center; justify-content: center; cursor: pointer;">
                        <i class="bi bi-trash"></i>
                    </div>
                </div>
                      </div >
                        </div >
            ${
            isExpanded ? `
                            <div class="subtask-detail-form">
                                ${sub.ApprovalStatus === 1 ? `
                                <div class="d-flex align-items-center gap-2 rounded-2 mb-3 px-3 py-2" style="background:rgba(59,130,246,0.07);font-size:0.82rem;color:#3b82f6;border:1px solid rgba(59,130,246,0.2);">
                                    <i class="bi bi-lock-fill"></i> %TemplateTaskNotEditable%
                                </div>` : ""}
                                <div class="subtask-detail-grid">
                                    <div style="grid-column: span 2;">
                                        <div class="subtask-detail-label">
                                            <i class="bi bi-pencil-square" style="color:#3b82f6"></i> %TaskName%
                                            ${sub.IsFromTemplate ? `<span class="badge template-badge-manual ms-2" style="font-size: 0.65rem; color: #3b82f6; background: rgba(59,130,246,0.1); border: 1px solid rgba(59,130,246,0.2);"><i class="bi bi-stack me-1"></i>Mẫu</span>` : ""}
                                        </div>
                  <div id="detail-name-${index}" class="mt-2 w-100"></div>
                                    </div>
                                    <div>
                                        <div class="subtask-detail-label">
             <i class="bi bi-person-fill" style="color:#4a9e0f"></i> %Assignee%
                                        </div>
                                        <div id="sub-assignee-detail-${index}" data-readonly="${sub.ApprovalStatus === 1 ? ''1'' : ''0''
        } "></div>
                                    </div >
                                    <div style="grid-column: span 2;">
                                        <div class="subtask-detail-label">
                                            <i class="bi bi-clock" style="color:#0ea5e9"></i> %Time% (m)
                                            ${sub.IsFromTemplate ? `<span style="font-size:0.6rem;padding:1px 4px;border-radius:3px;background:var(--bs-tertiary-bg,#f1f5f9);border:1px solid var(--bs-border-color,#e2e8f0);"><i class="bi bi-lock"></i></span>` : ""}
                                        </div>
                                        <div id="detail-time-${index}"></div>
                                    </div>
                                    <div class="subtask-detail-actions">
                                        <button type="button" class="btn-subtask-save btn-save-subtask-detail" data-index="${index}">
                                            <i class="bi bi-check-lg"></i> %Update%
                                        </button>
                                        <button type="button" class="btn-subtask-cancel btn-cancel-subtask-detail">
                                            %Cancel%
   </button>
                                    </div>
                                </div >
  </div >
            ` : ""}
                    </div>
                `}).join("");

    // Manual add form
    if (window.isAddingSubtaskManual) {
        htmlsection += `
                        <div class="subtask-detail-form mb-2" style="border:1px dashed #3cafcf !important;border-radius:10px !important;border-top:1px dashed #3cafcf !important;">
      <div class="subtask-detail-grid">
                                <div>
                                    <div class="subtask-detail-label"><i class="bi bi-pencil-square" style="color:#3b82f6"></i> %TaskName% <span id="manual-template-badge"></span></div>
                                    <div id="target-name-manual"></div>
        </div>
                                <div>
                                    <div class="subtask-detail-label"><i class="bi bi-clock" style="color:#0ea5e9"></i> %Time% (m)</div>
                                    <div id="target-time-manual"></div>
                                </div>
                                <div class="subtask-detail-actions">
<button type="button" class="btn-subtask-save btn-submit-manual" title="%Save%">
                                        <i class="bi bi-check-lg"></i> %Save%
                                    </button>
                                    <button type="button" class="btn-subtask-cancel btn-cancel-manual" title="%Cancel%">
                                        %Cancel%
                                    </button>
                                </div>
                            </div>
                        </div>
                    `;
    }

    // Inject HTML (controls were already detached so they are safe)
    $container.html(htmlsection);

    // Put detached controls into storage (invisible, keeps DevExtreme instances alive)
    if ($storage.length) {
        if ($subNameConDetached.length) $storage.append($subNameConDetached);
        if ($timeConDetached.length) $storage.append($timeConDetached);
        if ($subAssignDetached.length) $storage.append($subAssignDetached);
    }

    // Attach shared selectemployee control into the correct expanded detail slot after render
    try {
        const $subAssignCon2 = $("#P4386BF8B5C97415683E8B1F2FAA230DB");
        const instAssignee2 = getInstanceByUID("P4386BF8B5C97415683E8B1F2FAA230DB");

        if (window.editingSubtaskIndex >= 0 && !window.assigneePopupActive) {
            const idx = window.editingSubtaskIndex;
            const $detailSlot = $(`#sub-assignee-detail-${idx}`);
            if ($detailSlot.length && $subAssignCon2.length) {
                // [FIX] Vẫn cho phép chọn người thực hiện kể cả khi là task mẫu
                try {
                    if (typeof instAssignee2.option === "function") {
                        instAssignee2.option("readOnly", false);
                    }
                } catch (e) { }

                // Track which subtask owns the control right now
                window.currentAssigneeIndex = idx;
                $detailSlot.empty().append($subAssignCon2);

                if (instAssignee2) {
                    if (typeof instAssignee2.repaint === "function") instAssignee2.repaint();

                    // Set value from data model
                    const sub2 = pendingSubtasks[idx] || {};
                    const ids2 = sub2.AssigneeID
                        ? String(sub2.AssigneeID).split(",").map(s => s.trim()).filter(Boolean)
                        : [];
                    try {
                        instAssignee2.option("dataSource", employees);
                        instAssignee2.option("value", ids2.length === 1 ? ids2[0] : (ids2.length > 1 ? ids2 : null));
                    } catch (e) { console.warn(''init subtask assignee value failed'', e); }

                    // Re-attach value-changed handler (reads window.currentAssigneeIndex at event time)
                    try {
                        instAssignee2.option("onValueChanged", function (e) {
                            if (window.isAddingSubtaskManual) return;
                            const activeIdx = window.currentAssigneeIndex;
                            if (activeIdx >= 0 && activeIdx < pendingSubtasks.length) {
                                const newVal = e.value;
                                const newAssigneeID = (newVal && (Array.isArray(newVal) ? newVal.length > 0 : !!newVal))
                                    ? (Array.isArray(newVal) ? newVal.join(",") : String(newVal))
                                    : null;
                                pendingSubtasks[activeIdx].AssigneeID = newAssigneeID;
                                scheduleDraftSave();
                                // Refresh avatar preview in the subtask row header
                                const $trigger = $("#added-subtasks-list").find(`.sub-assignee-trigger[data-index="${activeIdx}"]`);
                                if ($trigger.length) {
                                    $trigger.parent().html(buildSubAssigneeHTML(activeIdx, pendingSubtasks[activeIdx]));
                                }
                            }
                        });
                        instAssignee2.option("onClosed", function () {
                            window.assigneePopupActive = false;
                        });
                    } catch (e) { console.warn(''re - attach subtask assignee handlers failed'', e); }
                }
            }
        } else if (!window.assigneePopupActive) {
            // No subtask is being edited — reset tracking index
            window.currentAssigneeIndex = -1;
        }
    } catch (e) { console.warn("subtask assignee control attach error", e); }

    // Disable avatar click opening — editing happens in Detail only
    $container.find(".sub-assignee-trigger").off("click.subAssignee");

    // Initialize detail form controls
    if (window.editingSubtaskIndex >= 0) {
        const idx = window.editingSubtaskIndex;
        $(`#detail-time-${idx}`).append($timeCon);

        const sub = pendingSubtasks[idx];
        setInstanceValue("PF542142C17247A09FCD23C6FCF8462P", sub.StandardTime || 0);

        const instP = getInstanceByUID("PF542142C17247A09FCD23C6FCF8462P");
        const $btnUpdate = $container.find(".btn-save-subtask-detail");

        const instManualName = getInstanceByUID("P25F5CBFA3D854FFD8AC3C1984B5439FC");
        $(`#detail-name-${idx}`).append($subNameCon);

        const validateEdit = () => {
            const name = instManualName ? instManualName.option("value") : (sub.TaskName || "");
            const time = instP ? instP.option("value") : 0;
            const isValid = String(name || "").trim() !== "" && parseFloat(time) > 0;
            $btnUpdate.prop("disabled", !isValid).css("opacity", isValid ? 1 : 0.5);
        };

        if (instManualName) {
            const isLockedName = (sub.IsInherited == 1 || sub.IsFromTemplate || sub.IsParentLink || sub.ApprovalStatus === 1);
            instManualName.option("disabled", isLockedName);
            instManualName.option("placeholder", "%SubtaskName%...");

            // Đặt giá trị tĩnh hiện tại để khỏi bị trigger oan trước khi gán sự kiện thay đổi
            instManualName.option("onValueChanged", null);
            instManualName.option("value", sub.TaskName || "");
            instManualName.repaint();

            // Gắn sự kiện chuẩn để đọc
            instManualName.option("onValueChanged", (e) => {
                if (window.isAddingSubtaskManual) return;
                const val = e.value;
                // Chỉ thay đổi data base nếu bản thân nội dung input sinh ra val khác với sub.TaskName gốc
                if (sub && sub.IsInherited != 1 && typeof val === "string" && val !== sub.TaskName) {
                    sub.TaskName = val;
                    validateEdit();
                    // Cập nhật text ở đầu dòng
                    const $itemTitle = $(`.subtask-item-wrapper[data-index="${idx}"]`).find(".subtask-task-name-text");
                    if ($itemTitle.length) $itemTitle.text(val);

                    if (sub.IsFromTemplate) {
                        sub.IsFromTemplate = false;
                        sub.TemplateID = 0;
                        sub.ExistingTaskID = 0;
                        sub.IsParentLink = false;
                        // Xóa badge ở tiêu đề và form sửa
                        $(`.subtask-item-wrapper[data-index="${idx}"]`).find(".template-badge-manual").remove();
                        $(`.subtask-item-wrapper[data-index="${idx}"]`).find(".subtask-detail-form .template-badge-manual").remove();
                        if (instP) instP.option("disabled", false);
                    }
                }
            });
        }

        if (instP) {
            // Khóa nếu là kế thừa hoặc mẫu (IsFromTemplate) hoặc đã duyệt
            const isFromTemplate = !!(sub.IsFromTemplate || sub.IsParentLink || (sub.TemplateID > 0) || (sub.SourceTaskID > 0) || (sub.ExistingTaskID > 0));
            const isInherited = sub.IsInherited == 1;
            instP.option("disabled", isInherited || isFromTemplate || (sub.ApprovalStatus === 1));
            instP.option("placeholder", "Phút");
            instP.option("onValueChanged", (e) => {
                sub.StandardTime = e.value;
                validateEdit();
            });
        }
        validateEdit();
    }

    // Initialize manual add form controls
    if (window.isAddingSubtaskManual) {
        if ($subNameCon.length) {
            const $target = $("#target-name-manual");
            if ($target.length) $target.append($subNameCon);
        }
        $("#target-time-manual").append($timeCon);

        const instManualName = getInstanceByUID("P25F5CBFA3D854FFD8AC3C1984B5439FC");
        const instP = getInstanceByUID("PF542142C17247A09FCD23C6FCF8462P");
        const $btnSubmit = $container.find(".btn-submit-manual");

        const validateManual = (currentName) => {
            const name = typeof currentName === "string" ? currentName : (instManualName ? instManualName.option("value") : "");

            // DevExpress sẽ cung cấp đúng giá trị thời gian nhờ thiết lập valueChangeEvent bên dưới
            const time = instP ? instP.option("value") : 0;

            // Khi chọn mẫu, time có thể được lock nhưng vẫn hợp lệ nếu mẫu có StandardTime
            const effectiveTime = parseFloat(time) > 0
                ? time
                : (window.selectedSubtaskItem ? (window.selectedSubtaskItem.StandardTime || 0) : 0);
            const isValid = String(name || "").trim() !== "" && parseFloat(effectiveTime) > 0;
            $btnSubmit.prop("disabled", !isValid).css("opacity", isValid ? 1 : 0.5);
        };

        // Fix tab navigation
        $container.off("keydown.subtaskManualTab").on("keydown.subtaskManualTab", ".btn-cancel-manual", function (e) {
            if (e.key === "Tab" && !e.shiftKey) {
                e.preventDefault();
                if (instManualName && typeof instManualName.focus === "function") instManualName.focus();
            }
        });
        // Manual Name input focus trap for Shift+Tab
        setTimeout(() => {
            const $manualNameInp = $("#target-name-manual").find("input");
            $manualNameInp.on("keydown", function (e) {
                if (e.key === "Tab" && e.shiftKey) {
                    e.preventDefault();
                    $container.find(".btn-cancel-manual").focus();
                }
            });
        }, 500);

        // Trong renderPendingSubtasks, sau khi appendChild + repaint:
        if (instManualName) {
            // Reset lại trạng thái để nếu trước đó control này đang ở dạng "edit template" (readonly) sẽ được mở lại
            instManualName.option("disabled", false);
            instManualName.setValue("");
            instManualName.option("placeholder", "%SubtaskName%...");

            // Khôi phục badge nếu đã chọn mẫu
            if (window.selectedSubtaskItem) {
                setTimeout(() => {
                    const $badge = $("#manual-template-badge");
                    if ($badge.length && !$badge.html()) {
                        $badge.html('' < span class= "badge bg-primary-subtle text-primary border border-primary-subtle ms-2" > <i class="bi bi-stack me-1"></i> Mẫu</span > '');
                    }
                }, 50);
            }
            instManualName.repaint();
            instManualName.rebindInputEvent();
            instManualName.option("onValueChanged", validateManual);

            // Khi sửa tên thì tách khỏi mẫu và mở khóa ô giờ
            instManualName.option("onInput", function (e) {
                const val = e.event.target.value;
                const templateName = window.selectedSubtaskItem ? (window.selectedSubtaskItem.TaskName || window.selectedSubtaskItem.Name || "") : "";

                if (window.selectedSubtaskItem && val !== templateName) {
                    // Mở khóa ô thời gian
                    window.selectedSubtaskItem = null;
                    $("#manual-template-badge").empty();
                    const instP = getInstanceByUID("PF542142C17247A09FCD23C6FCF8462P");
                    if (instP) instP.option("disabled", false);
                }
                validateManual(val);
            });

            // ===== FILTER: loại bỏ TemplateID đã có trong pendingSubtasks =====
            const $subNameEl = $("#P25F5CBFA3D854FFD8AC3C1984B5439FC");
            const $drop = $subNameEl.length ? $subNameEl.find(".hpa-textsearch-dropdown") : $();

            if ($drop.length) {
                // Override MutationObserver để filter items sau khi render
                const observer = new MutationObserver(function () {
                    const usedIds = pendingSubtasks
                        .map(s => s.TemplateID || s.ExistingTaskID)
                        .filter(id => id > 0);
                    if (usedIds.length === 0) return;


                    $drop.find(".hpa-textsearch-item").each(function () {
                        const $item = $(this);
                        // Lấy text "ID - Name" từ item-name
                        const idText = ($item.find(".item-name").text() || "").split(" - ")[0].trim();
                        const itemId = parseInt(idText);
                        if (!isNaN(itemId) && usedIds.includes(itemId)) {
                            $item.remove();
                        }
                    });
                });
                observer.observe($drop[0], { childList: true });

                // Lưu observer để disconnect khi không cần nữa
                window._subtaskDropObserver = observer;
            }
        }
        if (instP) {
            // Lock thời gian nếu đã chọn từ mẫu và mẫu có StandardTime
            const isLockedByTemplate = !!(window.selectedSubtaskItem &&
                (window.selectedSubtaskItem.StandardTime > 0));
            instP.option("disabled", isLockedByTemplate);
            instP.option("placeholder", "Phút");
            instP.option("valueChangeEvent", "keyup input change");
            instP.option("onValueChanged", validateManual);
            // Set value từ mẫu nếu có

            if (isLockedByTemplate) {
                instP.option("value", window.selectedSubtaskItem.StandardTime);
            }
        }

        if (!window.selectedSubtaskItem || !window.selectedSubtaskItem.StandardTime) {
            setInstanceValue("PF542142C17247A09FCD23C6FCF8462P", 0);
        }
        validateManual();

        setTimeout(() => {
            if (instManualName && typeof instManualName.focus === "function") {
                instManualName.focus();
            }
        }, 100);
    }

    // Gắn sự kiện kéo thả và lưu nháp (Cần chạy sau mỗi lần render)
    const $addedList = $("#added-subtasks-list");

    $addedList.find(".subtask-item-wrapper").each(function () {
        const $itemWrapper = $(this);
        const idx = parseInt($itemWrapper.data("index"), 10);
        if (!isNaN(idx)) {
            $itemWrapper.off("dragstart dragover dragleave drop").on({
                dragstart: (e) => handleSubtaskDragStart(e.originalEvent || e, idx),
                dragover: (e) => handleSubtaskDragOver(e.originalEvent || e),
                dragleave: (e) => handleSubtaskDragLeave(e.originalEvent || e),
                drop: (e) => handleSubtaskDrop(e.originalEvent || e, idx)
            });
        }
    });

    if (window.isAddingSubtaskManual === false) {
        scheduleDraftSave();
    }
            }

    // Subtask Events – scope vào form TaskList để tránh xung đột với form Detail (cùng class CSS)
    const $listRootSub = $("#sp_Task_TaskList_html");

    $listRootSub.off("click.subtaskAction").on("click.subtaskAction", ".btn-submit-manual, .btn-cancel-manual, .btn-toggle-detail, .btn-remove-subtask, .btn-save-subtask-detail, .btn-cancel-subtask-detail", function (e) {
        const $target = $(this);
        e.preventDefault();
        e.stopPropagation();

        if ($target.hasClass("btn-submit-manual")) {
            submitManualSubtask();
        } else if ($target.hasClass("btn-cancel-manual")) {
            window.isAddingSubtaskManual = false;
            renderPendingSubtasks();
        } else if ($target.hasClass("btn-toggle-detail")) {
            toggleSubtaskDetail(parseInt($target.data("index")));
        } else if ($target.hasClass("btn-remove-subtask")) {
            removePendingSubtask(parseInt($target.data("index")));
        } else if ($target.hasClass("btn-save-subtask-detail")) {
            saveSubtaskDetail(parseInt($target.data("index")));
        } else if ($target.hasClass("btn-cancel-subtask-detail")) {
            cancelSubtaskDetail();
        }
    });

    $listRootSub.off("click.subtaskRow").on("click.subtaskRow", ".subtask-row", function (e) {
        if ($(e.target).closest(".drag-handle, .btn-toggle-detail, .btn-remove-subtask, .subtask-detail-form, .sub-assignee-trigger, button").length) return;
        const $wrapper = $(this).closest(".subtask-item-wrapper");
        const idx = parseInt($wrapper.data("index"));
        if (!isNaN(idx)) {
            e.preventDefault();
            e.stopPropagation();
            toggleSubtaskDetail(idx);
        }
    });

    $listRootSub.off("keydown.subtaskEnter").on("keydown.subtaskEnter", ".subtask-detail-form input", function (e) {
        if (e.key === "Enter" || e.keyCode === 13) {
            e.preventDefault();
            if (window.isAddingSubtaskManual) submitManualSubtask();
            else {
                const $saveBtn = $(this).closest(".subtask-detail-form").find(".btn-save-subtask-detail");
                if ($saveBtn.length) $saveBtn.click();
            }
        }
    });

    function addSubtaskManual() {
        window.editingSubtaskIndex = -1; // Đóng ô sửa nếu đang mở
        window.isAddingSubtaskManual = true;
        renderPendingSubtasks();
    }

    function submitManualSubtask() {
        let taskName = "";
        let selectedItem = null;
        let assigneeID = null;

        if (window.isAddingSubtaskManual) {
            const subNameInst = getInstanceByUID("P25F5CBFA3D854FFD8AC3C1984B5439FC");
            taskName = subNameInst ? subNameInst.getValue() : "";

            // Nếu tên khác tên mẫu thì coi như việc mới (không dùng TemplateID)
            const templateName = (window.selectedSubtaskItem ? (window.selectedSubtaskItem.TaskName || window.selectedSubtaskItem.Name || "") : "").trim().toLowerCase();
            const currentName = (taskName || "").trim().toLowerCase();
            if (window.selectedSubtaskItem && currentName !== templateName) {
                selectedItem = null;
                window.selectedSubtaskItem = null;
            } else {
                selectedItem = window.selectedSubtaskItem || (subNameInst && typeof subNameInst.getSelectedItem === "function" ? subNameInst.getSelectedItem() : null);
            }
        }

        if (!taskName || (typeof taskName === "string" && !taskName.trim())) {
            uiManager.showAlert({ type: "warning", message: "%TaskNameRequired%" });
            const inst = getInstanceByUID("P25F5CBFA3D854FFD8AC3C1984B5439FC");
            if (inst && typeof inst.focus === "function") inst.focus();
            return;
        }


        // Check for Parent type
        const isParentType = selectedItem &&
            (selectedItem.Description === "Parent" || selectedItem.Description === "Parent & Sub");

        // Auto-fill subtask assignee
        const mainAssigneeIdList = formatIDList(getInstanceValue("PD76FE9F7E30A44A08B305AC908595419"));
        if (mainAssigneeIdList) assigneeID = mainAssigneeIdList.split(",")[0];
        const dueDateVal = getInstanceValue("P1D812C8523D54ECFB8BDE98FE5E7EF98");

        const standardTime = getInstanceValue("PF542142C17247A09FCD23C6FCF8462P") || 0;

        // Nếu chọn từ mẫu, dùng StandardTime của mẫu nếu control = 0
        const effectiveTime = parseFloat(standardTime) > 0
            ? standardTime
            : (window.selectedSubtaskItem ? (window.selectedSubtaskItem.StandardTime || 0) : 0);

        if (parseFloat(effectiveTime) <= 0) {
            uiManager.showAlert({ type: "warning", message: "%StandardTimeRequired%" });
            const instP = getInstanceByUID("PF542142C17247A09FCD23C6FCF8462P");
            if (instP && typeof instP.focus === "function") instP.focus();
            return;
        }

        const doReset = () => {
            setInstanceValue("P25F5CBFA3D854FFD8AC3C1984B5439FC", null);
            setInstanceValue("PF542142C17247A09FCD23C6FCF8462P", 0);
            window.selectedSubtaskItem = null;

            // Bước 1: Đóng form và render list để item mới hiện ra
            window.isAddingSubtaskManual = false;
            renderPendingSubtasks();

            // Bước 2: Sau 1 tick nhỏ, mở lại form thêm mới cho lần tiếp theo
            setTimeout(() => {
                window.isAddingSubtaskManual = true;
                renderPendingSubtasks();
                setTimeout(() => {
                    const instName = getInstanceByUID("P25F5CBFA3D854FFD8AC3C1984B5439FC");
                    if (instName && typeof instName.focus === "function") instName.focus();
                }, 50);
            }, 80);
        };

        pendingSubtasks.push({
            TaskName: taskName,
            IsParentLink: isParentType,
            ExistingTaskID: selectedItem ? (selectedItem.ID || selectedItem.TaskID) : 0,
            IsFromTemplate: !!selectedItem,
            TemplateID: isParentType ? 0 : (selectedItem ? (selectedItem.ID || selectedItem.TaskID) : 0),
            AssigneeID: assigneeID ? String(assigneeID) : null,
            StandardTime: effectiveTime,
            MainAssigneeID: getInstanceValue("P0902358F935A441E868AADCB1DBFCF64") ? String(getInstanceValue("P0902358F935A441E868AADCB1DBFCF64")).padStart(3, "0") : null,
            RequestID: getInstanceValue("P1257D8B184374728847FCB0CAEC1B7DB") ? String(getInstanceValue("P1257D8B184374728847FCB0CAEC1B7DB")) : null,
            Priority: (selectedItem && selectedItem.Priority) ? selectedItem.Priority : 2,
            DueDate: dueDateVal ? String(dueDateVal) : null,
            IsManual: true,
            SourceHistoryID: selectedItem ? (selectedItem.HistoryID || 0) : 0
        });
        updateStandardTimeSummaryTaskList();
        doReset();
    }

    // Toggle subtask detail editing
    function toggleSubtaskDetail(index) {
        const sub = pendingSubtasks[index];
        if (!sub) return;

        // ApprovalStatus === 1 (approved template): still allow toggling panel to show info,
        // but the form fields will be disabled by the render logic.
        // IsFromTemplate without ApprovalStatus === 1: allow open with readonly time only.

        if (window.editingSubtaskIndex === index) {
            // Close if already open
            window.editingSubtaskIndex = -1;
            window.currentAssigneeIndex = -1;
        } else {
            window.editingSubtaskIndex = index;
            window.isAddingSubtaskManual = false; // Đóng ô thêm mới nếu đang mở
        }
        renderPendingSubtasks();
    }

    // Save subtask detail changes
    function saveSubtaskDetail(index) {
        const sub = pendingSubtasks[index];
        if (!sub) return;

        // Read StandardTime (only if not a template subtask — template time is locked)
        if (!sub.IsFromTemplate) {
            const newTime = getInstanceValue("PF542142C17247A09FCD23C6FCF8462P") || 0;
            // Validate số phút > 0
            if (parseFloat(newTime) <= 0) {
                uiManager.showAlert({ type: "warning", message: "%StandardTimeRequired%" });
                return;
            }
            sub.StandardTime = newTime;
        }

        // AssigneeID: read directly from control at save time to ensure latest value is captured
        const instSaveAssignee = getInstanceByUID("P4386BF8B5C97415683E8B1F2FAA230DB");
        if (instSaveAssignee) {
            try {
                const rawVal = instSaveAssignee.option("value");
                if (rawVal !== null && rawVal !== undefined) {
                    const newAssigneeID = Array.isArray(rawVal)
                        ? (rawVal.length > 0 ? rawVal.join(",") : null)
                        : (rawVal ? String(rawVal) : null);
                    if (newAssigneeID !== null) sub.AssigneeID = newAssigneeID;
                }
            } catch (e) { console.warn("saveSubtaskDetail: read assignee failed", e); }
        }

        window.editingSubtaskIndex = -1;
        window.currentAssigneeIndex = -1;
        updateStandardTimeSummaryTaskList();
        renderPendingSubtasks();
    }

    // Cancel subtask detail editing
    function cancelSubtaskDetail() {
        window.editingSubtaskIndex = -1;
        window.currentAssigneeIndex = -1;
        renderPendingSubtasks();
    }

    function removePendingSubtask(index) {
        // Force close any active assignee popup
        if (window.assigneePopupActive) {
            window.assigneePopupActive = false;
            const inst = getInstanceByUID("P4386BF8B5C97415683E8B1F2FAA230DB");
            if (inst && inst.close) inst.close();
        }

        pendingSubtasks.splice(index, 1);
        if (window.editingSubtaskIndex === index) {
            window.editingSubtaskIndex = -1;
        }

        // Also reset assignee index if we deleted the row being edited
        if (window.currentAssigneeIndex === index) {
            window.currentAssigneeIndex = -1;
        } else if (window.currentAssigneeIndex > index) {
            // Shift index if above
            window.currentAssigneeIndex--;
        }

        updateStandardTimeSummaryTaskList();
        renderPendingSubtasks();
    }

    init();
    setupEventListeners();

    // LOGIC XỬ LÝ DRAWER LẶP LẠI (RECURRENCE)
    let tempRecurrenceSettings = null;

    // dxDateBox Instances for Drawer
    let instDrawerStartDate, instDrawerEndDate;
    const initRecurrenceDateBoxes = () => {
        instDrawerStartDate = $("#rec-drawer-start-date").dxDateBox({
            type: "date",
            displayFormat: "dd/MM/yyyy",
            value: new Date(),
            onValueChanged: function (e) {
                const start = e.value;
                if (instDrawerEndDate && start) {
                    const end = instDrawerEndDate.option("value");
                    if (!end || end < start) {
                        instDrawerEndDate.option("value", start);
                    }
                }
            }
        }).dxDateBox("instance");

        instDrawerEndDate = $("#rec-drawer-end-date").dxDateBox({
            type: "date",
            displayFormat: "dd/MM/yyyy",
            value: new Date()
        }).dxDateBox("instance");
    };
    initRecurrenceDateBoxes();

    const $btnDrawerRepeat = $("#btn-drawer-repeat");
    const $mdlRecurrenceDrawer = $("#mdlRecurrenceDrawer");
    const $btnConfirmRecurrenceDrawer = $("#btn-confirm-recurrence-drawer");

    if ($btnDrawerRepeat.length) {
        $btnDrawerRepeat.on("click", function () {
            $mdlRecurrenceDrawer.addClass("active");
            $mdlRecurrenceDrawer.find(".custom-modal-container").scrollTop(0);

            if (!tempRecurrenceSettings) {
                $("#rec-drawer-interval").val(1);
                instDrawerStartDate.option("value", new Date());
                instDrawerEndDate.option("value", new Date());
            } else {
                instDrawerStartDate.option("value", new Date(tempRecurrenceSettings.StartDate));
                instDrawerEndDate.option("value", tempRecurrenceSettings.EndDate ? new Date(tempRecurrenceSettings.EndDate) : new Date(tempRecurrenceSettings.StartDate));
            }
        });
    }

    // Radio Logic for Drawer
    $(''input[name = "rec-drawer-type"]'').on("change", function () {
        const type = $(this).val();
        const $unitLabel = $("#rec-drawer-interval-unit");
        const $weekDaysContainer = $("#rec-drawer-weekly-days-container");

        if (type == "1") { // Daily
            $unitLabel.text("Ngày");
            $weekDaysContainer.addClass("d-none");
        } else if (type == "2") { // Weekly
            $unitLabel.text("Tuần");
            $weekDaysContainer.removeClass("d-none");
        } else { // Monthly
            $unitLabel.text("Tháng");
            $weekDaysContainer.addClass("d-none");
        }
    });

    const closeRecurrenceDrawer = () => {
        $mdlRecurrenceDrawer.removeClass("active");
        // Wait for transition
    };
    $("#btn-close-recurrence-drawer-x, #btn-cancel-recurrence-drawer").on("click", closeRecurrenceDrawer);

    if ($btnConfirmRecurrenceDrawer.length) {
        $btnConfirmRecurrenceDrawer.on("click", function () {
            const RepeatType = $(''input[name = "rec-drawer-type"]: checked'').val();
            const RepeatInterval = $("#rec-drawer-interval").val();
            const StartDateVal = instDrawerStartDate.option("value");
            const EndDateVal = instDrawerEndDate.option("value");

            if (!StartDateVal) { uiManager.showAlert({ type: "warning", message: "%validationFromDate%" }); return; }
            if (!EndDateVal) { uiManager.showAlert({ type: "warning", message: "%validationToDate%" }); return; }

            const StartDate = StartDateVal.toISOString().split("T")[0];
            const EndDate = EndDateVal.toISOString().split("T")[0];
            const DueAfterDays = Math.max(0, Math.floor((new Date(EndDateVal).getTime() - new Date(StartDateVal).getTime()) / 86400000));

            let days = [];
            if (RepeatType == "2") {
                $(".rec-drawer-day:checked").each(function () { days.push($(this).val()); });
                if (days.length === 0) { uiManager.showAlert({ type: "warning", message: "%SelectAtLeastOneDay%" }); return; }
            }

            tempRecurrenceSettings = {
                RepeatType, RepeatInterval, StartDate, EndDate, DueAfterDays,
                RepeatDaysOfWeek: days.join(",")
            };

            const DueDateVal = new Date(StartDateVal);
            DueDateVal.setDate(DueDateVal.getDate() + parseInt(DueAfterDays));

            // Không đồng bộ ngược về form chính - tính định kỳ độc lập với các ngày của instance
            closeRecurrenceDrawer();
            // Chỉ báo trực quan
            $btnDrawerRepeat.addClass("active").html(`<i class="bi bi-check-circle-fill"></i> %RepeatConfigured%`);

            scheduleDraftSave();
        });
    }

    // Sync Main DueDate changes to Recurrence Rule
    setTimeout(() => {
        const mainDueInst = getInstanceByUID("P1D812C8523D54ECFB8BDE98FE5E7EF98");
        if (mainDueInst) {
            const originalHandler = mainDueInst.option("onValueChanged");
            mainDueInst.option("onValueChanged", function (e) {
                if (typeof originalHandler === "function") originalHandler.call(this, e);

                // Update recurrence rule if exists
                if (tempRecurrenceSettings && e.value) {
                    const startVal = new Date(tempRecurrenceSettings.StartDate);
                    const dueVal = new Date(e.value);
                    tempRecurrenceSettings.DueAfterDays = Math.max(0, Math.floor((dueVal.getTime() - startVal.getTime()) / 86400000));
                }
            });
        }
    }, 500);

    function saveRecurrenceForNewTask(NewTaskID, LoginID) {
        return new Promise((resolve) => {
            if (tempRecurrenceSettings && NewTaskID > 0) {
                AjaxHPAParadise({
                    data: {
                        name: "sp_Task_Recurrence_Save",
                        param: [
                            "RecurrenceID", 0,
                            "TemplateTaskID", NewTaskID,
                            "RepeatType", tempRecurrenceSettings.RepeatType,
                            "RepeatInterval", tempRecurrenceSettings.RepeatInterval,
                            "RepeatDaysOfWeek", tempRecurrenceSettings.RepeatDaysOfWeek,
                            "StartDate", tempRecurrenceSettings.StartDate,
                            "EndDate", tempRecurrenceSettings.EndDate,
                            "DueAfterDays", tempRecurrenceSettings.DueAfterDays,
                            "IsActive", 1,
                            "LoginID", LoginID
                        ]
                    },
                    success: (res) => {
                        tempRecurrenceSettings = null; // Reset
                        // Reset UI
                        if ($btnDrawerRepeat.length) {
                            $btnDrawerRepeat.removeClass("active").html(`<i class="bi bi-arrow-repeat"></i> %Repeat%`);
                        }
                        resolve(res);
                    },
                    error: (err) => {
                        console.error("Failed to save recurrence for new task", err);
                        resolve(); // Resolve anyway to not block
                    }
                });
            } else {
                resolve();
            }
        });
    }

    // DRAWER APPROVAL LOGIC
    let tempApprovalSettings = null;
    // When user manually configures approval stages, set this flag
    // to prevent auto-default logic from overwriting their choices.
    window.tempApprovalUserEdited = false;
    let approvalEmployeeList = []; // Cache danh sách nhân viên
    let approvalStageInstances = []; // Mảng DevExtreme instances cho từng cấp

    // Helper helper to determine if current task is purely from a template
    window.lastSelectedTemplateID = null;
    function isTaskActuallyTemplate() {
        const taskNameInst = (typeof getInstanceByUID === "function") ? getInstanceByUID("P63128D34B83D4F9EA7BEB928C35C7CF7") : null;
        const taskNameVal = (taskNameInst && typeof taskNameInst.option === "function") ? taskNameInst.option("value") : "";
        const currentSourceID = (taskNameInst && typeof taskNameInst.getSelectedID === "function") ? taskNameInst.getSelectedID() : null;
        let arr = (typeof pendingSubtasks !== "undefined") ? pendingSubtasks : (pendingSubtasks || []);

        let displayName = "";
        try {
            if (taskNameVal == null) displayName = "";
            else if (typeof taskNameVal === "object") displayName = taskNameVal.TaskName || taskNameVal.Name || taskNameVal.label || taskNameVal.text || "";
            else displayName = String(taskNameVal || "");
        } catch (e) { displayName = String(taskNameVal || ""); }

        const sourceID = currentSourceID || window.lastSelectedTemplateID;
        const normalizedDisplay = String(displayName || "").trim();
        const normalizedTemplate = String(window.lastSelectedTemplateName || "").trim();

        let isActuallyFromTemplate = !!sourceID;
        if (sourceID && normalizedTemplate && normalizedDisplay) {
            if (normalizedDisplay !== normalizedTemplate) {
                isActuallyFromTemplate = false;
            }
        }

        if (normalizedDisplay === "" || !isActuallyFromTemplate) return false;

        // Nếu có bất kỳ subtask nào thêm tay hoặc không phải từ mẫu
        const hasManualAddition = (arr || []).some(s => s.IsManual || !s.IsFromTemplate);
        return !hasManualAddition;
    }

    function updateAutoApprovalState() {
        if (window.isRestoringDraft) return;
        if (currentParentId > 0) return;

        const taskNameInst = (typeof getInstanceByUID === "function") ? getInstanceByUID("P63128D34B83D4F9EA7BEB928C35C7CF7") : null;
        const taskNameVal = (taskNameInst && typeof taskNameInst.option === "function") ? taskNameInst.option("value") : "";
        let displayName = "";
        try {
            if (taskNameVal == null) displayName = "";
            else if (typeof taskNameVal === "object") displayName = taskNameVal.TaskName || taskNameVal.Name || taskNameVal.label || taskNameVal.text || "";
            else displayName = String(taskNameVal || "");
        } catch (e) { displayName = String(taskNameVal || ""); }

        const isManualParent = (displayName.trim() !== "" && !isTaskActuallyTemplate());
        const arr = (typeof pendingSubtasks !== "undefined") ? pendingSubtasks : (pendingSubtasks || []);

        const hasManualSubtask = (arr || []).some(s => s.IsManual || !s.IsFromTemplate);

        if (isManualParent || hasManualSubtask) {
            // Don''t touch manual user-configured approval
            if (window.tempApprovalUserEdited) return;
            // Only auto-enable if not manually configured or if it was already an auto-config
            if (!tempApprovalSettings || tempApprovalSettings.Note === "%AutoActivatedNotInTemplate%") {
                const requestId = (typeof getInstanceValue === "function") ? getInstanceValue("P1257D8B184374728847FCB0CAEC1B7DB") : null;
                const defaultApprover = getDefaultApprover(requestId);

                if (!defaultApprover) {
                    updateApprovalUI({ RequireApproval: false });
                    tempApprovalSettings = null;
                } else {
                    tempApprovalSettings = {
                        RequireApproval: true,
                        Stages: [{ StageOrder: 1, ApproverID: defaultApprover, Deadline: null }],
                        Note: "%AutoActivatedNotInTemplate%"
                    };
                    updateApprovalUI(tempApprovalSettings);
                }
            }
        } else if (!tempApprovalSettings || tempApprovalSettings.Note === "%AutoActivatedNotInTemplate%") {
            // Only reset if user hasn''t manually edited the approval via drawer
            if (!window.tempApprovalUserEdited) {
                updateApprovalUI({ RequireApproval: false });
                tempApprovalSettings = null;
            }
        }
    }

    // Helper: Tạo một stage card và init DevExtreme instances
    function createApprovalStageCard(stageIndex, savedData) {
        const stageId = "approval-stage-" + stageIndex;
        const isMulti = $("#approval-drawer-multilevel").is(":checked");

        const $card = $("<div/>", {
            id: stageId,
            class: "approval-stage-card border rounded-3 bg-body",
            css: { padding: "14px", position: "relative" }
        });

        const approverDivId = stageId + "-approver";

        $card.html(`
                    <div class="d-flex align-items-center justify-content-between mb-2">
                        <span class="small fw-bold text-muted text-uppercase" style="font-size: 0.7rem; letter-spacing: 0.5px;">
                            ${isMulti ? "%Level% " + (stageIndex + 1) : "%Approver%"}
                        </span>

                      ${stageIndex > 0 ? `<button type="button" class="btn btn-md btn-outline-danger border-0 p-0 approval-remove-stage" data-stage="${stageIndex}" style="font-size: 0.8rem; width: 22px; height: 22px;"><i class="bi bi-x-lg"></i></button>` : ""}
                    </div>
                    <div id="${approverDivId}" class="mb-2"></div>
                `);

        $("#approval-stages-container").append($card);

        // State object riêng cho từng cấp
        const curReqID = (typeof getInstanceValue === "function") ? getInstanceValue("P1257D8B184374728847FCB0CAEC1B7DB") : null;
        const defaultApprover = (stageIndex === 0 && typeof getDefaultApprover === "function") ? getDefaultApprover(curReqID) : null;
        const stageState = { ApproverID: savedData?.ApproverID || defaultApprover };
        // Hàm này nhận vào containerId, selectedId, onSave callback
        const renderStageApprover = () => {
            if (typeof renderDisplayBoxApproverIDP9686718A3B6347518BDF5C6E3E8A391B === "function") {
                // Tạm thời ghi đè biến state để render đúng cho stage này
                renderDisplayBoxApproverIDP9686718A3B6347518BDF5C6E3E8A391B();
            }
        };

        // Factory function mô phỏng CHÍNH XÁC loadUI.txt nhưng khép kín cho từng cấp
        (function createStageApproverControl(containerId, initSelectedId, onValueSaved) {
            // --- STATE (closure riêng cho từng cấp) ---
            let selectedId = initSelectedId ? String(initSelectedId) : null;
            let selectedIdOriginal = selectedId;
            let popupInst = null;
            let popupOnce = false;
            let gridContainer = null;
            let _avatarLoading = false;

            const getColor = (id) => {
                const colors = [
                    { bg: "#e3f2fd", text: "#1976d2" }, { bg: "#f3e5f5", text: "#7b1fa2" },
                    { bg: "#e8f5e9", text: "#388e3c" }, { bg: "#fff3e0", text: "#f57c00" }, { bg: "#fce4ec", text: "#c2185b" }
                ];
                const numId = parseInt(id, 10);
                return colors[isNaN(numId) ? 0 : Math.abs(numId) % colors.length];
            };

            // --- RENDER DISPLAY BOX (copy từ loadUI.txt) ---
            const renderDisplayBox = () => {
                const $box = $("#" + containerId);
                if (!$box.length) return;
                $box.empty();

                const $wrapper = $("<div>").css({
                    borderBottom: "1px solid #ddd", padding: "0 6px", minHeight: "40px",
                    display: "flex", alignItems: "center", gap: "10px", cursor: "pointer",
                    transition: "border-bottom-color 0.2s"
                })
                    .attr("tabIndex", "0")
                    .on("keydown", function (e) {
                        if (e.key === "Enter" || e.key === " " || e.key === "Spacebar") {
                            e.preventDefault();
                            openPopup();
                        }
                    })
                    .on("focus", function () { $wrapper.css({ borderBottom: "2px solid #337ab7", outline: "none" }); })
                    .on("blur", function () { $wrapper.css({ borderBottom: "1px solid #ddd" }); })
                    .hover(
                        () => { if (!$wrapper.is(":focus")) $wrapper.css({ borderBottom: "1px solid #337ab7" }); },
                        () => { if (!$wrapper.is(":focus")) $wrapper.css({ borderBottom: "1px solid #ddd" }); }
                    );

                if (!selectedId) {
                    $wrapper.append($("<span>").addClass("text-muted").html(`<i class="bi bi-person-plus me-2"></i>%SelectEmployee%...`));
                } else {
                    const item = (window["DataSource_ApproverID"] || []).find(e => String(e.ID) === String(selectedId));
                    if (!item) {
                        $wrapper.append($("<span>").addClass("text-muted").text("%EmployeeNotFound%"));
                    } else {
                        const name = item.Name || item.FullName || "?";
                        const $avatar = $("<div>").css({
                            width: "40px", height: "40px", borderRadius: "50%",
                            boxShadow: "0 2px 6px rgba(0,0,0,0.15)",
                            display: "flex", alignItems: "center", justifyContent: "center",
                            fontWeight: "600", fontSize: "14px", position: "relative", overflow: "hidden", flexShrink: 0
                        });
                        const cachedUrl = window.GlobalEmployeeAvatarCache?.[String(selectedId)];
                        if (cachedUrl) {
                            $avatar.append($("<img>").attr("src", cachedUrl).css({ width: "100%", height: "100%", objectFit: "cover" }));
                        } else if (item.storeImgName) {
                            if (!_avatarLoading) {
                                _avatarLoading = true;
                                loadGlobalAvatarIfNeededApproverIDP9686718A3B6347518BDF5C6E3E8A391B(item.ID, item.storeImgName, item.paramImg, () => {
                                    _avatarLoading = false;
                                    renderDisplayBox();
                                });
                            }
                            const clr = getColor(selectedId);
                            $avatar.css({ background: clr.bg, color: clr.text }).text(hpaUtils.getInitials(name));
                        } else {
                            const clr = getColor(selectedId);
                            $avatar.css({ background: clr.bg, color: clr.text }).text(hpaUtils.getInitials(name));
                        }
                        const $info = $("<div>").css({ flex: 1, overflow: "hidden" });
                        $info.append($("<div>").css({ fontWeight: "500", fontSize: "14px", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }).text(name));
                        if (item.Position) $info.append($("<div>").css({ fontSize: "12px", color: "#6c757d", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }).text(item.Position));
                        $wrapper.append($avatar).append($info);
                    }
                }

                $box.append($wrapper);
                $wrapper.off("click").on("click", openPopup);
            };

            // --- POPUP (copy từ loadUI.txt) ---
            const openPopup = () => {
                if (!popupInst) {
                    initPopup();
                    setTimeout(() => popupInst.show(), 0);
                } else {
                    popupInst.show();
                }
            };

            const initPopup = () => {
                if (popupOnce) { popupInst.show(); return; }
                popupOnce = true;
                popupInst = $("<div>").appendTo(document.body).addClass("hpa-responsive").dxPopup({
                    width: function () { return window.innerWidth > 750 ? 750 : "95%"; },
                    height: "auto", maxHeight: "90vh", animation: null, showTitle: true,
                    title: "%SelectEmployee%", dragEnabled: true, closeOnOutsideClick: true, showCloseButton: true,
                    toolbarItems: [
                        {
                            widget: "dxButton", location: "after", toolbar: "bottom",
                            options: {
                                text: "%Cancel%", onClick: () => {
                                    selectedId = selectedIdOriginal;
                                    popupInst.hide();
                                }
                            }

                        },
                        {
                            widget: "dxButton", location: "after", toolbar: "bottom",
                            options: {
                                text: "Lưu", type: "success", onClick: () => {
                                    selectedIdOriginal = selectedId;
                                    renderDisplayBox();
                                    if (onValueSaved) onValueSaved(selectedId);
                                    popupInst.hide();
                                }
                            }
                        }
                    ],
                    contentTemplate: (contentElement) => {
                        gridContainer = $("<div>").css({ width: "100%", "overflow-x": "auto", "display": "block", "min-width": "0" });
                        contentElement.append(gridContainer);
                    },
                    onShown: () => {
                        const sortedData = (window["DataSource_ApproverID"] || []).slice().sort((a, b) => {
                            return (String(b.ID) === String(selectedId)) - (String(a.ID) === String(selectedId));
                        });
                        try { const gi = gridContainer.dxDataGrid("instance"); if (gi) gi.dispose(); } catch (e) { }
                        gridContainer.empty().dxDataGrid({
                            dataSource: sortedData, keyExpr: "ID",
                            width: "100%", columnHidingEnabled: true,
                            remoteOperations: false, columnAutoWidth: false, allowColumnResizing: true,
                            selection: { mode: "single" }, selectedRowKeys: selectedId ? [selectedId] : [],
                            hoverStateEnabled: true,
                            onRowClick: e => {
                                e.component.selectRows([e.key], false);
                            },
                            onRowPrepared: e => { if (e.rowType === "data") e.rowElement.css("cursor", "pointer"); },
                            columns: [
                                {
                                    caption: "Ảnh", width: 80, alignment: "center", hidingPriority: 4, cellTemplate: (container, options) => {
                                        const item = options.data;
                                        const $cell = $("<div>").css({ display: "flex", justifyContent: "center", alignItems: "center", height: "100%" });
                                        const cachedUrl = window.GlobalEmployeeAvatarCache?.[String(item.ID)];
                                        if (cachedUrl) {
                                            $cell.append($("<img>").attr("src", cachedUrl).css({ width: "40px", height: "40px", borderRadius: "50%", objectFit: "cover", border: "2px solid #fff", boxShadow: "0 2px 4px rgba(0,0,0,0.1)" }));
                                        } else {
                                            if (item.storeImgName) {
                                                loadGlobalAvatarIfNeededApproverIDP9686718A3B6347518BDF5C6E3E8A391B(item.ID, item.storeImgName, item.paramImg, (url) => {
                                                    if (!url) return;
                                                    $cell.empty().append(
                                                        $("<img>").attr("src", url).css({ width: "40px", height: "40px", borderRadius: "50%", objectFit: "cover", border: "2px solid #fff", boxShadow: "0 2px 4px rgba(0,0,0,0.1)" })
                                                    );
                                                });
                                            }
                                            const clr = getColor(item.ID);
                                            $cell.append($("<div>").text(hpaUtils.getInitials(item.Name || item.FullName || "?")).css({ width: "40px", height: "40px", borderRadius: "50%", background: clr.bg, color: clr.text, display: "flex", justifyContent: "center", alignItems: "center", fontWeight: "600", fontSize: "14px", boxShadow: "0 2px 4px rgba(0,0,0,0.1)" }));
                                        }
                                        $(container).append($cell);
                                    }
                                },
                                { dataField: "Name", caption: "%Fullname%", hidingPriority: 3 },
                                { dataField: "Email", caption: "Email", hidingPriority: 1 },
                                { dataField: "Position", caption: "%Position%", hidingPriority: 2 }
                            ],
                            searchPanel: { visible: true, placeholder: "" },
                            onContentReady: (e) => {
                                const grid = e.component;
                                grid.option("searchPanel.text", "");
                                const searchBox = grid.getView("headerPanel")._$element.find(".dx-datagrid-search-panel input");
                                if (searchBox.length) {
                                    searchBox.off().on("input", function () {
                                        const val = $(this).val();
                                        if (!val) { grid.clearFilter(); return; }
                                        const norm = RemoveToneMarks(val);
                                        grid.filter(item => {
                                            for (const f of ["Name", "Email", "Position"]) {
                                                if (item[f] && RemoveToneMarks(String(item[f])).indexOf(norm) !== -1) return true;
                                            }
                                            return false;
                                        });
                                    });
                                }
                            },
                            paging: { enabled: true, pageSize: 5, pageIndex: 0 },
                            pager: { visible: true, allowedPageSizes: [5, 10], showPageSizeSelector: true, showInfo: true, showNavigationButtons: true },
                            onSelectionChanged: e => selectedId = (e.selectedRowKeys && e.selectedRowKeys[0]) || null
                        });
                    },
                    onHidden: () => {
                        try { const gi = gridContainer.dxDataGrid("instance"); if (gi) gi.dispose(); } catch (e) { }
                        popupInst.option("position", { my: "center", at: "center", of: window });
                        renderDisplayBox();
                    }
                }).dxPopup("instance");
            };

            // --- INIT ---
            renderDisplayBox();

            // Trả về object để đọc giá trị khi confirm
            stageState.getValue = () => selectedId;
            stageState.setValue = (val) => {
                selectedId = val ? String(val) : null;
                selectedIdOriginal = selectedId;
                renderDisplayBox();
            };
        })(approverDivId, stageState.ApproverID, (newId) => { stageState.ApproverID = newId; });

        // Store initial entry (placeholder for instDeadline until loaded)
        approvalStageInstances[stageIndex] = { card: $card[0], instDeadline: null, stageState };

        // Remove button handler
        $card.find(".approval-remove-stage").on("click", function () {
            $card.remove();
            approvalStageInstances.splice(stageIndex, 1);
            refreshStageLabels();
        });

        return $card[0];
    }

    // Re-label stages after remove
    function refreshStageLabels() {
        const isMulti = $("#approval-drawer-multilevel").is(":checked");
        $(".approval-stage-card").each(function (i) {
            const $label = $(this).find(".small.fw-bold.text-muted");
            if ($label.length) $label.text(isMulti ? "%Level% " + (i + 1) : "%Approver%");
        });
    }

    // Reset all stage cards
    function clearApprovalStages() {
        $("#approval-stages-container").empty();
        approvalStageInstances = [];
    }

    const $mdlApprovalDrawer = $("#mdlApprovalDrawer");
    const $btnDrawerApproval = $("#btn-drawer-approval");
    const $btnConfirmApprovalDrawer = $("#btn-confirm-approval-drawer");
    const $approvalRequiredToggle = $("#approval-drawer-required");
    const $approvalMultiToggle = $("#approval-drawer-multilevel");
    const $approvalExtra = $("#approval-drawer-extra");
    const $btnAddStage = $("#btn-add-approval-stage");

    const closeApprovalDrawer = () => {
        $mdlApprovalDrawer.removeClass("active");

    };

    // Toggle required
    $approvalRequiredToggle.on("change", function () {
        $approvalExtra.toggle(this.checked);
        if (this.checked && approvalStageInstances.length === 0) {
            createApprovalStageCard(0, null);
        }
    });

    // Toggle multi-level
    $approvalMultiToggle.on("change", function () {
        $btnAddStage.toggle(this.checked);
        refreshStageLabels();
    });

    // Add stage button
    $btnAddStage.find("button").on("click", function () {
        const idx = approvalStageInstances.length;
        createApprovalStageCard(idx, null);
    });

    // Open drawer
    if ($btnDrawerApproval.length) {
        $btnDrawerApproval.on("click", function () {
            $mdlApprovalDrawer.addClass("active");
            $mdlApprovalDrawer.find(".custom-modal-container").scrollTop(0);

            clearApprovalStages();

            if (tempApprovalSettings) {
                $approvalRequiredToggle.prop("checked", tempApprovalSettings.RequireApproval);
                $approvalExtra.toggle(tempApprovalSettings.RequireApproval);
                const isMulti = tempApprovalSettings.Stages && tempApprovalSettings.Stages.length > 1;
                $approvalMultiToggle.prop("checked", isMulti);
                $btnAddStage.toggle(isMulti);
                $("#approval-drawer-note").val(tempApprovalSettings.Note || "");
                (tempApprovalSettings.Stages || [{ ApproverID: null, Deadline: null }]).forEach((s, i) => {
                    createApprovalStageCard(i, s);
                });
            } else {
                $approvalRequiredToggle.prop("checked", false);
                $approvalMultiToggle.prop("checked", false);
                $approvalExtra.hide();
                $btnAddStage.hide();
                $("#approval-drawer-note").val("");
            }
        });
    }

    $("#btn-close-approval-drawer-x, #btn-cancel-approval-drawer").on("click", closeApprovalDrawer);

    if ($btnConfirmApprovalDrawer.length) {
        $btnConfirmApprovalDrawer.on("click", function () {
            const RequireApproval = $approvalRequiredToggle.is(":checked");

            if (!RequireApproval) {
                tempApprovalSettings = { RequireApproval: false };
                closeApprovalDrawer();
                $btnDrawerApproval.removeClass("active").css("color", "").html(`<i class="bi bi-person-check"></i> %Approval%`);
                return;
            }

            // Collect stages
            const Stages = [];
            let valid = true;
            approvalStageInstances.forEach((inst, i) => {
                if (!inst || !inst.stageState) return;

                const ApproverID = inst.stageState.getValue ? inst.stageState.getValue() : (inst.stageState.ApproverID || null);
                if (!ApproverID) {
                    valid = false;
                    uiManager.showAlert({ type: "warning", message: `%SelectApproverLevel% ${i + 1}` });
                    return;
                }

                Stages.push({ StageOrder: i + 1, ApproverID });
            });


            if (!valid || Stages.length === 0) {
                if (Stages.length === 0) uiManager.showAlert({ type: "warning", message: "%RequireAtLeastOneApprover%" });
                return;
            }

            const Note = $("#approval-drawer-note").val();
            tempApprovalSettings = { RequireApproval: true, Stages, Note };

            closeApprovalDrawer();
            // Mark that user intentionally configured approval — prevent auto overrides
            window.tempApprovalUserEdited = true;
            $btnDrawerApproval.addClass("active").css("color", "#d97706");
            const stageCount = Stages.length;
            if (window.LanguageID == "VN") {
                $btnDrawerApproval.html(`<i class="bi bi-check-circle-fill"></i> Duyệt ${stageCount > 1 ? stageCount + " cấp" : "1 người"}`);
            } else {
                $btnDrawerApproval.html(`<i class="bi bi-check-circle-fill"></i> Approval ${stageCount > 1 ? stageCount + " levels" : "1 person"}`);
            }
            scheduleDraftSave();
        });
    }

    function saveApprovalForNewTask(HistoryID, LoginID) {
        return new Promise((resolve) => {
            if (tempApprovalSettings && tempApprovalSettings.RequireApproval && HistoryID > 0) {
                try {
                    const stagesJson = JSON.stringify(tempApprovalSettings.Stages || []);
                    AjaxHPAParadise({
                        data: {
                            name: "sp_Task_Approval_Save",
                            param: [
                                "HistoryID", HistoryID,
                                "StagesJson", stagesJson,
                                "Note", tempApprovalSettings.Note || "",
                                "LoginID", LoginID
                            ]
                        },
                        success: (res) => {
                            tempApprovalSettings = null;
                            const $btnDrawerApproval = $("#btn-drawer-approval");
                            if ($btnDrawerApproval.length) {
                                $btnDrawerApproval.removeClass("active").css("color", "").html(`<i class="bi bi-person-check"></i> %Approval%`);
                            }
                            resolve(res);
                        },
                        error: (err) => {
                            console.error("Failed to save approval", err);
                            resolve();
                        }
                    });
                } catch (e) {
                    console.error("Failed to save approval for new task", e);
                    resolve();
                }
            } else {
                resolve();
            }
        });
    }
    window.saveApprovalForNewTask = saveApprovalForNewTask;

    window.initManualTaskValidation = function ($container) {
        const instManualName = getInstanceByUID("P25F5CBFA3D854FFD8AC3C1984B5439FC");
        const instP = getInstanceByUID("PF542142C17247A09FCD23C6FCF8462P");
        const $btnSubmit = $container.find(".btn-submit-manual");

        const validateManual = () => {
            const name = instManualName ? instManualName.option("value") : "";
            const time = instP ? instP.option("value") : 0;
            const isValid = String(name || "").trim() !== "" && parseFloat(time) > 0;
            $btnSubmit.prop("disabled", !isValid).css("opacity", isValid ? 1 : 0.5);
        };

        if (instManualName) {
            instManualName.option("value", "");
            instManualName.option("onValueChanged", validateManual);
            instManualName.option("placeholder", "%TaskName%...");

            instManualName.option("valueChangeEvent", "keyup input change");
        }
        if (instP) {
            instP.option("value", 0);
            instP.option("onValueChanged", validateManual);
            instP.option("placeholder", "Phút");

            instP.option("valueChangeEvent", "keyup input change");
        }
        validateManual();
    };

    window["onTextSearchSelected_TaskName"] = function (item, instance) {
        if (!item || !item.ID) return;

        const mainInst = (typeof getInstanceByUID === "function") ? getInstanceByUID("P63128D34B83D4F9EA7BEB928C35C7CF7") : null;
        const subInst = (typeof getInstanceByUID === "function") ? getInstanceByUID("P25F5CBFA3D854FFD8AC3C1984B5439FC") : null;

        // 1. Nếu là Main Task
        if (instance === mainInst) {
            // Xóa subtask từ mẫu cũ trước khi load mẫu mới
            if (window.lastSelectedTemplateID && window.lastSelectedTemplateID !== item.ID) {
                pendingSubtasks = pendingSubtasks.filter(s => !s.IsFromTemplate);
                window.editingSubtaskIndex = -1;
                window.currentAssigneeIndex = -1;
            }

            window.lastSelectedTemplateID = item.ID;
            window.lastSelectedTemplateName = item.TaskName || item.Name || "";
            if (item.StandardTime) {
                setInstanceValue("P136F0762551345078797DB3CC80DA470", item.StandardTime);
            }
        }
        // 2. Nếu là Manual Subtask
        else if (instance === subInst) {
            if (window.editingSubtaskIndex >= 0) {
                const idx = window.editingSubtaskIndex;
                const sub = pendingSubtasks[idx];
                if (sub && sub.IsInherited != 1) {
                    sub.TaskName = item.TaskName || item.Name || "";
                    sub.StandardTime = item.StandardTime || 0;
                    sub.IsFromTemplate = true;
                    sub.IsParentLink = false;
                    sub.TemplateID = item.ID || item.TaskID || 0;
                    sub.ExistingTaskID = item.ID || item.TaskID || 0;
                    renderPendingSubtasks();
                }
                return; // Bỏ qua việc load tự động các mẫu con khi đang ở chế độ chỉnh sửa đè dòng
            } else {
                window.selectedSubtaskItem = item;
                // Hiển thị badge preview ngay trong form manual
                $("#manual-template-badge").html('' < span class= "badge bg-primary-subtle text-primary border border-primary-subtle ms-2" > <i class="bi bi-stack me-1"></i> Mẫu</span > '');
                if (item.StandardTime) {
                    setInstanceValue("PF542142C17247A09FCD23C6FCF8462P", item.StandardTime);
                }
                // Readonly ngay lập tức khi chọn mẫu trong ô thêm mới
                const instP = getInstanceByUID("PF542142C17247A09FCD23C6FCF8462P");
                if (instP) {
                    const isFromTemplate = !!(item.TaskID || item.ID);
                    instP.option("disabled", isFromTemplate);
                }
            }
        }

        const isParentType = item.Description && (item.Description === "Parent" || item.Description === "Parent & Sub" || item.TaskType === "Parent");
        if (isParentType) {
            window.selectedSubtaskItem = item;
            if (typeof updateAutoApprovalState === "function") updateAutoApprovalState();
            return;
        }

        // Cảnh báo: Chỉ tự động bung các subtask thành dòng trên giao diện nếu chọn Template làm Task CHÍNH
        // Nếu chọn Template làm Task Phụ, thì không load các cháu lên UI để tránh làm phẳng danh sách, backend sẽ tự đệ quy tạo cháu.
        if (instance !== mainInst) {
            if (typeof updateAutoApprovalState === "function") updateAutoApprovalState();
            return;
        }

        AjaxHPAParadise({
            data: { name: "sp_Task_GetTemplateChildren", param: ["ParentTaskID", item.ID, "LoginID", LoginID] },
            success: function (data) {
                try {
                    const json = typeof data === "string" ? JSON.parse(data) : data;
                    const children = (json.data && json.data[0]) || [];
                    if (children.length > 0) {
                        children.forEach(child => {
                            // Chặn trùng lặp nếu công việc đã có trong danh sách chờ
                            const templateID = child.TaskID || 0;
                            if (templateID <= 0) return;

                            // If an entry for this template already exists, merge safely
                            const existing = pendingSubtasks.find(s => s.TemplateID === templateID);

                            const parentAssignee = formatIDList(getInstanceValue("PD76FE9F7E30A44A08B305AC908595419"));
                            const firstAssignee = parentAssignee ? parentAssignee.split(",")[0] : null;

                            const pMainInst = getInstanceByUID("P0902358F935A441E868AADCB1DBFCF64");
                            let pMainVal = pMainInst ? pMainInst.option("value") : null;

                            if (!pMainVal && firstAssignee) {
                                pMainVal = String(firstAssignee);
                                if (pMainInst) pMainInst.option("value", pMainVal);
                            }

                            const parentMainAssignee = pMainVal ? String(pMainVal) : null;

                            if (existing) {
                                // Preserve any user-updated assignee; only fill missing fields
                                existing.TaskName = existing.TaskName || child.TaskName;
                                existing.IsFromTemplate = true;
                                existing.IsInherited = 1; // Mark as inherited from parent template
                                existing.StandardTime = existing.StandardTime || child.StandardTime || 0;
                                existing.Priority = existing.Priority || child.Priority || 2;
                                existing.MainAssigneeID = existing.MainAssigneeID || parentMainAssignee || null;
                                existing.RequestID = existing.RequestID || (getInstanceValue("P1257D8B184374728847FCB0CAEC1B7DB") ? String(getInstanceValue("P1257D8B184374728847FCB0CAEC1B7DB")) : null);
                                existing.DueDate = existing.DueDate || getInstanceValue("P1D812C8523D54ECFB8BDE98FE5E7EF98");
                                existing.ApprovalStatus = existing.ApprovalStatus || child.ApprovalStatus || 0;
                                existing.TemplateName = existing.TemplateName || child.TaskName;
                            } else {
                                pendingSubtasks.push({
                                    TaskName: child.TaskName,
                                    IsFromTemplate: true,
                                    IsInherited: 1, // Mark as inherited from parent template
                                    TemplateID: templateID,
                                    AssigneeID: firstAssignee ? String(firstAssignee) : null,
                                    StandardTime: child.StandardTime || 0,
                                    Priority: child.Priority || 2,
                                    MainAssigneeID: parentMainAssignee ? String(parentMainAssignee) : null,
                                    RequestID: getInstanceValue("P1257D8B184374728847FCB0CAEC1B7DB") ? String(getInstanceValue("P1257D8B184374728847FCB0CAEC1B7DB")) : null,
                                    DueDate: getInstanceValue("P1D812C8523D54ECFB8BDE98FE5E7EF98"),
                                    ApprovalStatus: child.ApprovalStatus || 0,
                                    TemplateName: child.TaskName
                                });
                            }
                        });
                        renderPendingSubtasks();
                    }
                    if (typeof updateAutoApprovalState === "function") updateAutoApprovalState();
                } catch (e) { console.error("Error parsing subtasks", e); }
            }
        });
    };
        }) ();

    $(function () {
        if (typeof ttvSearch !== "undefined" && ttvSearch) {
            const $ttvSearchInput = $("#ttv-search-input");
            const $mbSearch = $("#mb-search-input");
            if ($ttvSearchInput.length) $ttvSearchInput.val(ttvSearch);
            if ($mbSearch.length) $mbSearch.val(ttvSearch);
        }
        if (typeof currentView !== "undefined" && currentView) {
            const $btn = $(`#view-switcher .switcher-item[data-view=''${currentView}'']`);
            if ($btn.length) {
                $("#view-switcher .switcher-item").removeClass("active");
                $btn.addClass("active");
                if (typeof updateMobileSlider === "function") {
                    updateMobileSlider("view-switcher", $btn, "view-slider");
                }
            }
        }
        if (typeof isMyTask !== "undefined" && isMyTask) {
            const $btnTask = $(`#btn-filter-${isMyTask}`);
            if ($btnTask.length) {
                $("#filter-switcher .switcher-item").removeClass("active");
                $btnTask.addClass("active");
                if (typeof updateSlider === "function") {
                    setTimeout(() => updateSlider("filter-switcher", $btnTask), 100);
                }
            }
        }
    });
</script>
';
SELECT @html AS html;
--EXEC sptblCommonControlType_Signed 'sp_Task_TaskList_html'
--EXEC sp_GenerateHTMLScript_new 'sp_Task_TaskList_html'
END
GO

-- 2. Update Menu Metadata
PRINT 'Updating MEN_Menu configuration...'
GO
IF EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = 'MnuAT001')
BEGIN
    UPDATE MEN_Menu
    SET ShortcutKeys = 'CONTROL+B'
    WHERE MenuID = 'MnuAT001';
END
GO
PRINT 'Migration script preparation done.'
