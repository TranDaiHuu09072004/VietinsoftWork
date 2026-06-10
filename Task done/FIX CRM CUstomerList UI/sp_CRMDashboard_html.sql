CREATE PROCEDURE [dbo].[sp_CRMDashboard_html]
(
    @LoginID INT = 3,
    @LanguageID VARCHAR(2) = 'EN',
    @isWeb INT = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @html NVARCHAR(MAX);

    SET @html = N'
<style>
    @import url(''https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap'');

    /* --- Cấu hình chung --- */
    #sp_CRMDashboard {
        font-family: ''Inter'', sans-serif;
        /* Màu chữ đen xám */
        min-height: 100vh;
        padding: 1.5rem;
    }

    /* --- Style cho Card (Khung nội dung) --- */
    /* Giữ class glass-card để tương thích code cũ nhưng style thành thẻ trắng phẳng */
    #sp_CRMDashboard .glass-card {
        background: #ffffff;
        border: 1px solid #e5e7eb;
        box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
        border-radius: 12px;
        padding: 24px;
        height: 100%;
        position: relative;
        overflow: hidden;
        transition: all 0.2s ease-in-out;
    }

    /* Hiệu ứng hover cho thẻ có thể click */
    #sp_CRMDashboard .glass-card.clickable:hover {
        transform: translateY(-4px);
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
        border-color: #00673b;
        cursor: pointer;
    }

    #sp_CRMDashboard .crm-title-link {
        font-size: 1.7rem;
        display: flex;
        align-items: center;
        transition: all 0.2s;
        font-size: 1.5rem;
        background: linear-gradient(to right, #004c39, #1d9336);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
    }

    #sp_CRMDashboard .crm-title-link i {
        color: inherit;
    }

    /* --- Tiêu đề & Header --- */
    #sp_CRMDashboard .section-header {
        display: flex;
        align-items: center;
        margin-bottom: 20px;
    }

    #sp_CRMDashboard .section-title {
        font-size: 1.3rem;
        font-weight: 700;
        color: #00673b;
        margin: 0;
        display: flex;
        align-items: center;
        gap: 10px;
    }

    /* --- Thanh lọc (Filter Bar) --- */
    #sp_CRMDashboard .filter-bar-container {
        display: flex;
        flex-wrap: wrap;
        gap: 20px;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 2rem;
        background: #ffffff;
    }

    #sp_CRMDashboard .filter-group {
        display: flex;
        align-items: center;
        gap: 10px;
    }

    #sp_CRMDashboard .filter-label {
        font-weight: 600;
        font-size: 0.9rem;
        margin-bottom: 0;
        white-space: nowrap !important;
    }

    /* --- Action Buttons --- */
    #sp_CRMDashboard #btnRecalculate {
        border: 1px solid #10b981;
        color: #10b981;
        font-weight: 600;
        padding: 8px 16px;
        border-radius: 8px;
        transition: all 0.2s ease;
    }

    #sp_CRMDashboard #btnRecalculate:hover {
        background-color: #10b981;
        color: white;
        transform: translateY(-1px);
        box-shadow: 0 4px 12px rgba(16, 185, 129, 0.2);
    }

    #sp_CRMDashboard #btnRecalculate:disabled {
        opacity: 0.6;
        transform: none;
        box-shadow: none;
    }

    #sp_CRMDashboard #btnSettings {
        border: 1px solid #6b7280;
        width: 40px;
        height: 40px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s ease;
    }

    #sp_CRMDashboard #btnSettings:hover {
        background-color: #6b7280;
        color: white;
        transform: translateY(-1px);
        box-shadow: 0 4px 12px rgba(107, 114, 128, 0.2);
    }

    /* --- Form Inputs (Giao diện sáng chuẩn) --- */
    #sp_CRMDashboard .form-control-cus,
    #sp_CRMDashboard .form-select-cus,
    .custom-modal .form-control,
    .custom-modal .form-select {
        border-bottom: 1px solid #d7d7d7;
        border-radius: 0 !important;
        padding: 0.1rem 0.75rem;
        font-size: 0.95rem;
    }

    #sp_CRMDashboard .form-control-cus:focus,
    #sp_CRMDashboard .form-select-cus:focus,
    .custom-modal .form-control:focus,
    .custom-modal .form-select:focus {
        border-color: #3b82f6;
        box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.15);
        outline: none;
    }

    /* --- Hot Notification --- */
    #sp_CRMDashboard .hot-notification-glass {
        background-color: #fee2e2;
        border-left: 4px solid #ef4444;
        color: #b91c1c;
        padding: 16px 20px;
        border-radius: 8px;
        font-weight: 600;
        margin-bottom: 2rem;
        display: flex;
        align-items: center;
        gap: 12px;
        cursor: pointer;
        animation: pulse-red 2s infinite;
    }

    @keyframes pulse-red {
        0% {
            box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.2);
        }

        70% {
            box-shadow: 0 0 0 10px rgba(239, 68, 68, 0);
        }

        100% {
            box-shadow: 0 0 0 0 rgba(239, 68, 68, 0);
        }
    }

    /* --- KPI Cards Layout --- */
    #sp_CRMDashboard .kpi-grid-container {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
        gap: 24px;
        margin-bottom: 2.5rem;
    }

    #sp_CRMDashboard .kpi-card-header {
        display: flex;
        align-items: center;
        gap: 12px;
        margin-bottom: 16px;
    }

    #sp_CRMDashboard .kpi-icon-wrapper {
        width: 40px;
        height: 40px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.2rem;
        background: #f3f4f6;
    }

    #sp_CRMDashboard .kpi-card-title {
        font-size: 0.8rem;
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.5px;
    }

    #sp_CRMDashboard .kpi-current-value {
        font-size: 2.2rem;
        font-weight: 800;
        margin-bottom: 0.5rem;
        line-height: 1;
        text-align: center;
    }

    #sp_CRMDashboard .kpi-card-footer {
        display: flex;
        justify-content: space-between;
        align-items: flex-end;
        border-top: 1px solid #f3f4f6;
        padding-top: 12px;
        margin-top: 12px;
    }

    #sp_CRMDashboard .trend-badge {
        padding: 4px 10px;
        border-radius: 20px;
        font-size: 0.85rem;
        font-weight: 700;
        display: inline-flex;
        align-items: center;
        gap: 4px;
    }

    #sp_CRMDashboard .growth.positive .trend-badge {
        background: #dcfce7;
        color: #15803d;
    }

    #sp_CRMDashboard .growth.negative .trend-badge {
        background: #fee2e2;
        color: #b91c1c;
    }

    #sp_CRMDashboard .previous-period {
        text-align: right;
        font-size: 0.85rem;
        font-weight: 500;
    }

    #sp_CRMDashboard .previous-period small {
        display: block;
        font-size: 0.75rem;
        font-weight: 400;
    }

    /* Màu sắc nhấn cho từng thẻ KPI */
    #sp_CRMDashboard .kpi-card[data-kpi="manual-email"] {
        border-bottom: 4px solid #3b82f6;
    }

    #sp_CRMDashboard .kpi-card[data-kpi="manual-email"] .kpi-icon-wrapper i {
        color: #3b82f6;
    }

    #sp_CRMDashboard .kpi-card[data-kpi="data-collect"] {
        border-bottom: 4px solid #a855f7;
    }

    #sp_CRMDashboard .kpi-card[data-kpi="data-collect"] .kpi-icon-wrapper i {
        color: #a855f7;
    }

    #sp_CRMDashboard .kpi-card[data-kpi="contact"] {
        border-bottom: 4px solid #73c41d;
    }

    #sp_CRMDashboard .kpi-card[data-kpi="contact"] .kpi-icon-wrapper i {
        color: #73c41d;
    }

    #sp_CRMDashboard .kpi-card[data-kpi="content"] {
        border-bottom: 4px solid #f97316;
    }

    #sp_CRMDashboard .kpi-card[data-kpi="content"] .kpi-icon-wrapper i {
        color: #f97316;
    }

    #sp_CRMDashboard .kpi-card[data-kpi="demo"] {
        border-bottom: 4px solid #ef4444;
    }

    #sp_CRMDashboard .kpi-card[data-kpi="demo"] .kpi-icon-wrapper i {
        color: #ef4444;
    }

    #sp_CRMDashboard .kpi-card[data-kpi="followup"] {
        border-bottom: 4px solid #eab308;
    }

    #sp_CRMDashboard .kpi-card[data-kpi="followup"] .kpi-icon-wrapper i {
        color: #eab308;
    }

    /* --- Bảng biểu (Tables) --- */
    #sp_CRMDashboard .table-responsive {
        border-radius: 8px;
        border: 1px solid #e5e7eb;
        overflow-x: auto;
        overflow-y: hidden;
        -webkit-overflow-scrolling: touch;
        background: #fff;
    }

    #sp_CRMDashboard .table-responsive::-webkit-scrollbar {
        height: 8px;
        width: 8px;
    }
    #sp_CRMDashboard .table-responsive::-webkit-scrollbar-thumb {
        background: var(--paradise-border-color, #c1c1c1);
        border-radius: 4px;
    }


    #sp_CRMDashboard .table {
        margin-bottom: 0;
        width: 100%;
        min-width: 1000px; /* Bắt buộc bảng phải rộng để có thanh cuộn */
        border-collapse: collapse;
    }

    #sp_CRMDashboard .table thead th {
        font-weight: 600;
        text-transform: uppercase;
        font-size: 0.75rem;
        letter-spacing: 0.05em;
        border-bottom: 1px solid #e5e7eb;
        padding: 12px 16px;
        white-space: nowrap !important;
    }

    #sp_CRMDashboard .table tbody td {
        border-bottom: 1px solid #e5e7eb;
        padding: 12px 16px;
        font-size: 0.9rem;
        vertical-align: middle;
        white-space: nowrap !important;
    }

    #sp_CRMDashboard .table-hover tbody tr:hover {
        background-color: #f3f4f6;
    }

    /* --- Phân trang (Pagination) --- */
    #sp_CRMDashboard .pagination .page-link {
        border: 1px solid #d1d5db;
        border-radius: 6px;
        margin: 0 2px;
        padding: 6px 12px;
        font-size: 0.9rem;
        transition: all 0.2s;
    }

    #sp_CRMDashboard .pagination .page-link:hover {
        background-color: #f3f4f6;
        border-color: #9ca3af;
    }

    #sp_CRMDashboard .pagination .page-item.active .page-link {
        background-color: #3b82f6;
        border-color: #3b82f6;
        font-weight: 600;
    }

    #sp_CRMDashboard .pagination .page-item.disabled .page-link {
        opacity: 0.6;
        cursor: not-allowed;
    }

    /* --- Modal Styles (Giao diện chuẩn) --- */
    #sp_CRMDashboard .custom-modal .modal-content {
        background: #ffffff;
        border: none;
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
        border-radius: 12px;
    }

    #sp_CRMDashboard .custom-modal .modal-header {
        border-bottom: 1px solid #e5e7eb;
        padding: 16px 24px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        background: #f9fafb;
        border-radius: 12px 12px 0 0;
    }

    #sp_CRMDashboard .custom-modal .modal-title {
        font-size: 1.25rem;
        font-weight: 700;
        margin: 0;
    }

    #sp_CRMDashboard .custom-modal .close-btn {
        background: transparent;
        border: none;
        width: 32px;
        height: 32px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all 0.2s;
    }

    #sp_CRMDashboard .custom-modal .close-btn:hover {
        background: #fee2e2;
        color: #ef4444;
    }

    #sp_CRMDashboard .custom-modal .modal-body {
        padding: 24px;
        overflow-y: auto;
        max-height: 75vh;
    }

    #sp_CRMDashboard .custom-modal .modal-footer {
        border-top: 1px solid #e5e7eb;
        padding: 16px 24px;
        background: #f9fafb;
        display: flex;
        justify-content: flex-end;
        gap: 12px;
        border-radius: 0 0 12px 12px;
    }

    #sp_CRMDashboard .custom-modal label {
        font-weight: 600;
        margin-bottom: 6px;
        font-size: 0.9rem;
    }

    /* Nút bấm (Buttons) */
    #sp_CRMDashboard .btn-custom-primary {
        background: #3b82f6;
        border: none;
        padding: 8px 16px;
        border-radius: 6px;
        font-weight: 600;
        box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
        transition: all 0.2s;
    }

    #sp_CRMDashboard .btn-custom-primary:hover {
        background: #2563eb;
        transform: translateY(-1px);
    }

    #sp_CRMDashboard .btn-custom-secondary {
        background: #ffffff;
        border: 1px solid #d1d5db;
        padding: 8px 16px;
        border-radius: 6px;
        font-weight: 600;
        transition: all 0.2s;
    }

    #sp_CRMDashboard .btn-custom-secondary:hover {
        background: #f3f4f6;
    }

    /* Chart Container */
    #sp_CRMDashboard .chart-wrapper {
        position: relative;
        height: 300px;
        width: 100%;
    }

    /* Checkbox Custom */
    #sp_CRMDashboard .form-check-input {
        cursor: pointer;
    }

    #sp_CRMDashboard .form-check-input:checked {
        background-color: #3b82f6;
        border-color: #3b82f6;
    }

    .dark-mode #sp_CRMDashboard {
        background-color: #1e2329;
    }

    .dark-mode #sp_CRMDashboard .filter-bar-container {
        background-color: #242a30;
        border-color: #313a43;
        box-shadow: none;
    }

    .dark-mode #sp_CRMDashboard .crm-title-link {
        background: linear-gradient(to right, #1d9336, #9fe12d);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
    }

    .dark-mode #sp_CRMDashboard .filter-label {
        color: gray;
    }

    .dark-mode #sp_CRMDashboard .glass-card {
        background-color: #242a30;
        border-color: #313a43;
        box-shadow: none;
    }

    .dark-mode #sp_CRMDashboard .kpi-icon-wrapper {
        background-color: #2f3740;
    }

    .dark-mode #sp_CRMDashboard .kpi-card[data-kpi="manual-email"] {
        border-bottom: 4px solid #3b82f6;
    }

    .dark-mode #sp_CRMDashboard .kpi-card[data-kpi="manual-email"] .kpi-icon-wrapper i {
        color: #3b82f6;
    }

    .dark-mode #sp_CRMDashboard .kpi-card[data-kpi="data-collect"] {
        border-bottom: 4px solid #a855f7;
    }

    .dark-mode #sp_CRMDashboard .kpi-card[data-kpi="data-collect"] .kpi-icon-wrapper i {
        color: #a855f7;
    }

    .dark-mode #sp_CRMDashboard .kpi-card[data-kpi="contact"] {
        border-bottom: 4px solid #73c41d;
    }

    .dark-mode #sp_CRMDashboard .kpi-card[data-kpi="contact"] .kpi-icon-wrapper i {
        color: #73c41d;
    }

    .dark-mode #sp_CRMDashboard .kpi-card[data-kpi="content"] {
        border-bottom: 4px solid #f97316;
    }

    .dark-mode #sp_CRMDashboard .kpi-card[data-kpi="content"] .kpi-icon-wrapper i {
        color: #f97316;
    }

    .dark-mode #sp_CRMDashboard .kpi-card[data-kpi="demo"] {
        border-bottom: 4px solid #ef4444;
    }

    .dark-mode #sp_CRMDashboard .kpi-card[data-kpi="demo"] .kpi-icon-wrapper i {
        color: #ef4444;
    }

    .dark-mode #sp_CRMDashboard .kpi-card[data-kpi="followup"] {
        border-bottom: 4px solid #eab308;
    }

    .dark-mode #sp_CRMDashboard .kpi-card[data-kpi="followup"] .kpi-icon-wrapper i {
        color: #eab308;
    }

    .dark-mode #sp_CRMDashboard .kpi-current-value {
        color: #fff;
    }
</style>

<div class="container-fluid" id="sp_CRMDashboard">

    <div class="glass-card filter-bar-container">
        <div>
            <h4 class="m-0 fw-bold crm-title-link">
                <i class="fas fa-chart-line me-2"></i>%CRMDashboard%
            </h4>
        </div>

        <div class="d-flex gap-3 align-items-center flex-wrap justify-content-start justify-content-md-end">
           <!-- Create Lead Button -->
            <button type="button" id="btnCreateLead" style= "padding:8px;" class="btn btn-success" onclick="openCreateLeadForm()"
                title="Thêm LEAD">
                <i class="fas fa-plus-circle"></i>
                <span>Thêm Lead</span>
            </button>
            <!-- Recalculate Button -->
            <button type="button" id="btnRecalculate"
                class="btn btn-outline-success btn-sm d-flex align-items-center gap-2" title="%RecalculateData%">
                <i class="fas fa-sync-alt"></i>
                <span>%Recalculate%</span>
            </button>

            <!-- Settings Gear Button -->
            <button type="button" id="btnSettings" class="btn btn-outline-secondary btn-sm d-flex align-items-center"
                title="%Settings%" data-bs-toggle="modal" data-bs-target="#settingsModal">
                <i class="fas fa-cog"></i>
            </button>



            <div class="filter-group">
                <label for="dashboardFilterEmployee" class="filter-label"><i
                        class="fas fa-user me-2 text-secondary"></i>%Employee%:</label>
                <!-- <select id="dashboardFilterEmployee" class="form-select-cus" style="width: auto; min-width: 150px;">
                    <option value="">%AllEmployees%</option>
                </select> -->
                <div id="PF21433BAA7444823B61584359F91D433"></div>
            </div>

            <div class="filter-group">
                <label for="filterType" class="filter-label"><i
                        class="fas fa-filter me-2 text-secondary"></i>%Viewby%:</label>
                <select id="filterType" class="form-select-cus"
                    style="    background: transparent;width: auto; min-width: 140px;">
                    <option value="day">%Date%</option>
                    <option value="week" selected>%week%</option>
                    <option value="month">%Month%</option>
                </select>
            </div>

            <div id="datePickerContainer" class="filter-group">
                <label for="filterDate" class="filter-label"><i
                        class="fas fa-calendar-alt me-2 text-secondary"></i>%Time%:</label>
                <input type="week" id="filterDate" class="form-control-cus"
                    style="    background: transparent;width: auto; min-width: 200px;">
                <span id="weekRangeDisplay" class="badge bg-primary text-white ms-2 p-2"
                    style="font-weight: 500; border-radius: 6px; background-color: #00673b !important;"></span>
            </div>
        </div>
    </div>

    <div id="hotNotificationContainer" style="display:none;">
        <div id="hotNotificationContent" class="hot-notification-glass">
        </div>
    </div>

    <div class="kpi-grid-container">
        <div class="glass-card clickable kpi-card" data-kpi="manual-email">
            <div class="kpi-card-header">
                <div class="kpi-icon-wrapper"><i class="fas fa-envelope"></i></div>
                <span class="kpi-card-title">%ManualEmail%</span>
            </div>
            <h2 class="kpi-current kpi-current-value"></h2>
            <div class="kpi-card-footer">
                <div class="growth positive">
                    <span class="trend-badge growth-value"><i class="fas fa-arrow-up me-1"></i> +0%</span>
                </div>
                <div class="previous previous-period">
                    <span></span> <small>%Previousperiod%</small>
                </div>
            </div>
        </div>

        <div class="glass-card clickable kpi-card" data-kpi="data-collect">
            <div class="kpi-card-header">
                <div class="kpi-icon-wrapper"><i class="fas fa-database"></i></div>
                <span class="kpi-card-title">%CollectData%</span>
            </div>
            <h2 class="kpi-current kpi-current-value"></h2>
            <div class="kpi-card-footer">
                <div class="growth negative">
                    <span class="trend-badge growth-value"><i class="fas fa-arrow-down me-1"></i> +0%</span>
                </div>
                <div class="previous previous-period">
                    <span></span> <small>%Previousperiod%</small>
                </div>
            </div>
        </div>

        <!-- <div class="glass-card clickable kpi-card" data-kpi="contact">
            <div class="kpi-card-header">
                <div class="kpi-icon-wrapper"><i class="fas fa-address-book"></i></div>
                <span class="kpi-card-title">%ContactActivitie%</span>
            </div>
            <h2 class="kpi-current kpi-current-value"></h2>
            <div class="kpi-card-footer">
                <div class="growth positive">
                    <span class="trend-badge growth-value"><i class="fas fa-arrow-up me-1"></i> +0%</span>
                </div>
                <div class="previous previous-period">
                    <span></span> <small>%Previousperiod%</small>
                </div>
            </div>
        </div> -->

        <div class="glass-card clickable kpi-card" data-kpi="content">
            <div class="kpi-card-header">
                <div class="kpi-icon-wrapper"><i class="fas fa-pen-nib"></i></div>
                <span class="kpi-card-title">Content</span>
            </div>
            <h2 class="kpi-current kpi-current-value"></h2>
            <div class="kpi-card-footer">
                <div class="growth negative">
                    <span class="trend-badge growth-value"><i class="fas fa-arrow-down me-1"></i> +0%</span>
                </div>
                <div class="previous previous-period">
                    <span></span> <small>%Previousperiod%</small>
                </div>
            </div>
        </div>

        <div class="glass-card clickable kpi-card" data-kpi="demo">
            <div class="kpi-card-header">
                <div class="kpi-icon-wrapper"><i class="fas fa-video"></i></div>
                <span class="kpi-card-title">Demo</span>
            </div>
            <h2 class="kpi-current kpi-current-value"></h2>
            <div class="kpi-card-footer">
                <div class="growth positive">
                    <span class="trend-badge growth-value"><i class="fas fa-arrow-up me-1"></i> +0%</span>
                </div>
                <div class="previous previous-period">
                    <span></span> <small>%Previousperiod%</small>
                </div>
            </div>
        </div>

        <div class="glass-card clickable kpi-card" data-kpi="followup">
            <div class="kpi-card-header">
                <div class="kpi-icon-wrapper"><i class="fas fa-clock-rotate-left"></i></div>
                <span class="kpi-card-title">%needfollowup%</span>
            </div>
            <h2 class="kpi-current kpi-current-value"></h2>
            <div class="kpi-card-footer">
                <div class="growth negative">
                    <span class="trend-badge growth-value"><i class="fas fa-arrow-down me-1"></i> +0%</span>
                </div>
                <div class="previous previous-period">
                    <span></span> <small>%Previousperiod%</small>
                </div>
            </div>
        </div>
    </div>

    <!-- KPI RESULTS SECTION -->
    <div class="glass-card mb-5" id="kpiResultsSection">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div class="section-header m-0">
                <h5 class="section-title"><i class="fas fa-chart-line text-info me-2"></i>%KPIResults%</h5>
            </div>
            <!-- <div class="d-flex gap-2">
                <button type="button" id="btnToggleKPIResults" class="btn btn-outline-secondary btn-sm">
                    <i class="fas fa-eye-slash me-1"></i>Thu gọn
                </button>
                <button type="button" id="btnRefreshKPIResults" class="btn btn-outline-primary btn-sm">
                    <i class="fas fa-sync-alt me-1"></i>Làm mới
                </button>
            </div> -->
        </div>

        <!-- KPI Type Filter -->
<div class="mb-4 d-flex gap-3 align-items-center">
            <div class="filter-group">
                <label for="dashboardFilterKPIType" class="filter-label"><i
                        class="fas fa-list me-2 text-secondary"></i>Loại KPI:</label>
                <select id="dashboardFilterKPIType" class="form-select-cus" style="width: auto; min-width: 150px;">
                    <option value="">Tất cả KPI</option>
                    <option value="1">Email</option>
                    <option value="2">Thu thập dữ liệu</option>
                    <!-- <option value="3">Hoạt động liên hệ</option> -->
                    <option value="4">Content</option>
                    <option value="5">Demo</option>
                    <option value="6">Cần follow-up</option>
                </select>
            </div>
        </div>

        <!-- Filters - Temporarily hidden -->
        <!--
        <div class="row g-3 mb-4">
            <div class="col-md-3">
                <label for="dashboardFilterEmployee" class="form-label small fw-bold">
                    <i class="fas fa-user me-1"></i>%Employee%
                </label>
                <select id="dashboardFilterEmployee" class="form-select form-select-sm">
                    <option value="">Đang tải...</option>
                </select>
            </div>
            <div class="col-md-3">
                <label for="dashboardFilterKPIType" class="form-label small fw-bold">
                    <i class="fas fa-list me-1"></i>Loại KPI
                </label>
                <select id="dashboardFilterKPIType" class="form-select form-select-sm">
                    <option value="">Tất cả KPI</option>
                    <option value="1">Email</option>
                    <option value="2">Thu thập dữ liệu</option>
                    <option value="3">Hoạt động liên hệ</option>
                    <option value="4">Content</option>
                    <option value="5">Demo</option>
                    <option value="6">Cần chăm sóc</option>
                </select>
            </div>
            <div class="col-md-2">
                <label for="dashboardFilterFromDate" class="form-label small fw-bold">
                    <i class="fas fa-calendar-alt me-1"></i>%FromDate%
                </label>
                <input type="date" id="dashboardFilterFromDate" class="form-control form-control-sm">
            </div>
            <div class="col-md-2">
                <label for="dashboardFilterToDate" class="form-label small fw-bold">
                    <i class="fas fa-calendar-alt me-1"></i>%ToDate%
                </label>
                <input type="date" id="dashboardFilterToDate" class="form-control form-control-sm">
            </div>
            <div class="col-md-2 d-flex align-items-end">
                <button type="button" id="btnFilterDashboardKPI" class="btn btn-primary btn-sm w-100">
                    <i class="fas fa-filter me-1"></i>%Filter%
                </button>
            </div>
        </div>
        -->

        <!-- Loading State -->
        <div id="dashboardKpiLoading" class="text-center py-5">
            <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">%Loading%</span>
            </div>
            <div class="mt-2 text-muted">%LoadingKPIData%</div>
        </div>

        <!-- Empty State -->
        <div id="dashboardKpiEmpty" class="text-center py-5 d-none">
            <i class="fas fa-chart-line fa-3x text-muted mb-3"></i>
            <h6 class="text-muted mb-2">%NoKPIData%</h6>
            <p class="text-muted small">%TryChangeFilter%</p>
        </div>

        <!-- Data Table -->
        <div id="dashboardKpiContainer" class="d-none">
            <div class="table-responsive">
                <table class="table table-hover table-striped">
                    <thead class="table-light">
                        <tr>
                            <th class="text-center" style="width: 50px;">#</th>
                            <th>Nhân viên</th>
                            <th>KPI</th>
                            <th class="text-center">Đơn vị</th>
                            <th class="text-center">Thời gian</th>
                         <th class="text-center">Yêu cầu</th>
                            <th class="text-center">Thực tế</th>
                            <th class="text-center" style="width: 150px;">Đạt được</th>
                            <th class="text-center">Trạng thái</th>
                            <th class="text-center">EXP</th>
                            <th class="text-center">Coin</th>
                        </tr>
                    </thead>
                    <tbody id="dashboardKpiBody">
                        <!-- Data will be populated by JavaScript -->
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <nav aria-label="Dashboard KPI Pagination" class="mt-4" id="dashboardKpiPaginationContainer">
                <ul class="pagination justify-content-end mb-0" id="dashboardKpiPagination">
                    <!-- Pagination will be generated by JavaScript -->
                </ul>
            </nav>


        </div>
    </div>
    <!-- END KPI RESULTS SECTION -->

    <div class="glass-card mb-5">
        <div class="section-header">
            <h5 class="section-title mb-3"><i class="fas fa-trophy text-warning me-2"></i> %EmpKPIRank%</h5>
        </div>
        <div class="table-responsive">
            <table class="table table-hover w-100">
                <thead>
                    <tr>
                        <th>%Rank%</th>
                        <th>%EmployeeName%</th>
                        <th>%StartDate%</th>
                        <th>%KPIScore%</th>
                    </tr>
                </thead>
                <tbody id="employeeKpiRankingBody">
                </tbody>
            </table>
        </div>
        <div class="mt-4 d-flex justify-content-end">
            <nav aria-label="Employee Ranking Pagination">
                <ul class="pagination mb-0" id="employeeKpiPagination"></ul>
            </nav>
        </div>
    </div>

    <div class="glass-card mb-4">
        <div class="d-flex justify-content-between align-items-center mb-4">
            <div class="section-header m-0">
                <h5 class="section-title"><i class="fas fa-users me-2"></i>%RecentCus%</h5>
            </div>
            <div class="d-flex align-items-center gap-2">
                <label for="rowsPerPage" class="filter-label fw-normal small">%Display%:</label>
                <select id="rowsPerPage" class="form-select form-select-sm" style="width: auto;">
                    <option value="5" selected>5</option>
                    <option value="10">10</option>
                    <option value="15">15</option>
                    <option value="20">20</option>
                </select>
            </div>
        </div>

        <div class="table-responsive">
            <table class="table table-hover w-100">
                <thead>
                    <tr>
                        <th>%STT%</th>
                        <th>%CustomerName%</th>
                        <th>%Email%</th>
                        <th>%Phone%</th>
                        <th>%Company%</th>
                        <th>%Status%</th>
                        <th>%ContactDate%</th>
                    </tr>
                </thead>
                <tbody id="customerTableBody">
                </tbody>
            </table>
        </div>

        <div class="d-flex justify-content-between align-items-center mt-4 pt-3" style="border-top: 1px solid #f3f4f6;">
            <div id="pageInfo" class="text-secondary small fw-medium"></div>
      <nav aria-label="Customer Pagination">
                <ul class="pagination mb-0" id="pagination">
                </ul>
            </nav>
        </div>
    </div>

    <div class="row g-4 mb-5">
        <div class="col-lg-4">
            <div class="glass-card">
                <div class="section-header">
              <h5 class="section-title"><i class="fas fa-chart-pie me-2"></i>%ActivityOverview%</h5>
                </div>
                <div class="chart-wrapper">
                    <canvas id="pieChart"></canvas>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="glass-card">
                <div class="section-header">
                    <h5 class="section-title"><i class="fas fa-chart-bar me-2"></i>%EmailStats%</h5>
                </div>
                <div class="chart-wrapper">
                    <canvas id="barChart"></canvas>
                </div>
            </div>
        </div>

        <div class="col-lg-4">
            <div class="glass-card">
                <div class="section-header">
                    <h5 class="section-title"><i class="fas fa-chart-bar fa-rotate-90 me-2"></i>%SalesPerf%</h5>
                </div>
                <div class="chart-wrapper">
                    <canvas id="horizontalChart"></canvas>
                </div>
            </div>
        </div>
    </div>

</div>

<!-- KPI Configuration Modal -->
<div class="modal fade" id="settingsModal" tabindex="-1" aria-labelledby="settingsModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="settingsModalLabel">
                    <i class="fas fa-cog me-2"></i>Cấu hình KPI
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form id="kpiConfigForm">
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="employeeCode" class="form-label">
                                    <i class="fas fa-id-card me-2"></i>Mã nhân viên <span class="text-danger">*</span>
                                </label>
                                <div id="PF2722DC090454A53A549F3E773C07EC4"></div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="kpiCategory" class="form-label">
                                    <i class="fas fa-list me-2"></i>Hạng mục tính KPI <span class="text-danger">*</span>
                                </label>
                                <div id="P7A6682CA6E8141DFB2244DB71032A266"></div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="kpiUnit" class="form-label">
                                    <i class="fas fa-ruler me-2"></i>Đơn vị tính KPI <span class="text-danger">*</span>
                                </label>
                                <div id="P39A23829013F4A98ADF6641FB04BFB7B"></div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="kpiTarget" class="form-label">
                                    <i class="fas fa-bullseye me-2"></i>KPI yêu cầu <span class="text-danger">*</span>
        </label>
                            <div id="PCF26DFF3C8E1439783E535E6C90E0468"></div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="experiencePointsAchieved" class="form-label">
                                    <i class="fas fa-star me-2"></i>Điểm kinh nghiệm khi đạt <span
                                        class="text-danger">*</span>
                                </label>
                                <div id="P9A3C6268FB014323A095C16A60E1925F"></div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="coinAchieved" class="form-label">
                                    <i class="fas fa-coins me-2"></i>Coin khi đạt <span class="text-danger">*</span>
                                </label>
                                <div id="P90AA0D5082AD44AA8EBBB09EFF1A79EC"></div>
                            </div>
                        </div>
                    </div>

                    <!-- <div class="row">
                <div class="col-md-6">
   <div class="mb-3">
                                <label for="bonusExperiencePoints" class="form-label">
                                    <i class="fas fa-arrow-up me-2"></i>Bonus điểm kinh nghiệm vượt KPI<span
                                        class="text-danger">*</span>
                                </label>
<div id="P5F4411446A9447688E6023972985B894"></div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="bonusCoin" class="form-label">
                                    <i class="fas fa-gift me-2"></i>Bonus coin vượt KPI<span
                                        class="text-danger">*</span>
                                </label>
                                <div id="P16FAB824436D423EA05CFE561E321AA4"></div>
                            </div>
                        </div>
                    </div> -->

                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="effectiveDate" class="form-label">
                                    <i class="fas fa-calendar-alt me-2"></i>Ngày hiệu lực<span
                                        class="text-danger">*</span>
                                </label>
                                <div id="P4FA6222B45A34106B51C016423D0A78B"></div>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-success" id="manageKpiConfig">
                    <i class="fas fa-cog me-2"></i>Quản lý danh sách KPI
                </button>
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                    <i class="fas fa-times me-2"></i>Hủy
                </button>
                <button type="button" class="btn btn-success" id="saveKpiConfig">
                    <i class="fas fa-save me-2"></i>Lưu cấu hình
                </button>
            </div>
        </div>
    </div>
</div>

<!-- KPI Results Modal -->
<div class="modal fade" id="kpiResultsModal" tabindex="-1" aria-labelledby="kpiResultsModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header bg-primary text-white">
           <h5 class="modal-title" id="kpiResultsModalLabel">
                    <i class="fas fa-chart-line me-2"></i>%KPIResults%
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"
                    aria-label="Close"></button>
            </div>
 <div class="modal-body">
                <!-- Filter Section -->
                <div class="row mb-4">
                    <div class="col-md-3">
                        <label for="filterEmployee" class="form-label fw-bold">%Employee%:</label>
                        <select class="form-select" id="filterEmployee">
                            <option value="">%AllEmployees%</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label for="filterKPITypeModal" class="form-label fw-bold">Loại KPI:</label>
                        <select class="form-select" id="filterKPITypeModal">
                            <option value="">Tất cả</option>
                            <option value="manual-email">Email thủ công</option>
                            <option value="data-collect">Thu thập dữ liệu</option>
                            <option value="contact">Liên hệ</option>
                            <option value="content">Nội dung</option>
                            <option value="demo">Demo</option>
                            <option value="followup">Follow-up</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label for="filterFromDate" class="form-label fw-bold">%FromDate%:</label>
                        <input type="date" class="form-control" id="filterFromDate">
                    </div>
                    <div class="col-md-2">
                        <label for="filterToDate" class="form-label fw-bold">%ToDate%:</label>
                        <input type="date" class="form-control" id="filterToDate">
                    </div>
                    <div class="col-md-1">
                        <label class="form-label">&nbsp;</label>
                        <button type="button" class="btn btn-success d-block w-100" id="btnFilterKPI">
                            <i class="fas fa-search me-2"></i>%Filter%
                        </button>
                    </div>
                </div>

                <!-- Loading Spinner -->
                <div class="text-center my-4 d-none" id="kpiResultsLoading">
                    <div class="spinner-border text-primary" role="status">
                        <span class="visually-hidden">%Loading%</span>
                    </div>
                    <p class="mt-2 text-muted">%LoadingKPIData%</p>
                </div>

                <!-- Results Table -->
                <div class="table-responsive" id="kpiResultsContainer">
                    <table class="table table-hover table-striped" id="kpiResultsTable">
                        <thead class="table-dark">
                            <tr>
                                <th scope="col">#</th>
                                <th scope="col">%Employee%</th>
                                <th scope="col">KPI</th>
                                <th scope="col">Unit</th>
                                <th scope="col">Period</th>
                                <th scope="col">Target</th>
                                <th scope="col">Actual</th>
                                <th scope="col">Achieved (%)</th>
                                <th scope="col">%Status%</th>
                                <th scope="col">Exp</th>
                                <th scope="col">Coin</th>
                                <th scope="col">Ghi chú</th>
                            </tr>
                        </thead>
                        <tbody id="kpiResultsBody">
                       <!-- Data will be populated here -->
                        </tbody>
                    </table>
                </div>

                <!-- Empty State -->
                <div class="text-center py-5 d-none" id="kpiResultsEmpty">
                    <i class="fas fa-inbox fa-3x text-muted mb-3"></i>
                    <h5 class="text-muted">%NoKPIData%</h5>
                    <p class="text-muted">%TryChangeFilterOrRecalculate%</p>
                </div>

                <!-- Pagination -->
                <nav aria-label="KPI Results Pagination" class="mt-4" id="kpiResultsPaginationContainer">
                    <ul class="pagination justify-content-center" id="kpiResultsPagination">
                        <!-- Pagination will be generated here -->
                    </ul>
                </nav>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                    <i class="fas fa-times me-2"></i>Đóng
                </button>
                <button type="button" class="btn btn-success" id="btnExportKPI">
                    <i class="fas fa-download me-2"></i>Xuất Excel
                </button>
            </div>
        </div>
    </div>
</div>

<script>

    function openCreateLeadForm() {
        if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
            OpenFormParamMobile(`sp_CRM_CreateLead`);
        } else {
            openFormParam(`sp_CRM_CreateLead`);
        }
    }

    function initDarkMode_CRMDashboard() {
        const savedDarkMode = localStorage.getItem(''darkMode_CRMDashboard'');
        if (savedDarkMode === ''true'') {
            document.body.classList.add(''dark-mode'');
        }
    }
    initDarkMode_CRMDashboard()
    var mailEmployeeList = [];
    async function loadMailEmployee() {
        AjaxHPAParadise({
            data: {
                name: "sp_KPIgetEmailListCompany",
                param: [''LoginID'', window.UserID]
            },
            success: function (data) {
                if (typeof data == "string" && !IsNullOrEmpty(data)) {
                    data = data.includes("{") ? data : EncryptionStringDecryption(data);
                }
                let dataObject = JSON.parse(data);
                let mailEmployeeData = dataObject.data?.[0];
                if (mailEmployeeData) {
                    mailEmployeeList = mailEmployeeData;

                    // Populate datalist for demo_attendees
                    let $datalist = $(''#employeeList'');
                    if ($datalist.length) {
                        $datalist.empty();
                        mailEmployeeList.forEach(emp => {
                            if (emp.Email) {
                                // Add option with Email as value and Name as hint
                                // Store EmployeeID in data attribute
                                let label = emp.FullName || emp.EmployeeName || emp.Email;
                                $datalist.append(`<option value="${emp.Email}" data-emp-id="${emp.EmployeeID || ''''}">${label}</option>`);
                            }
                        });
                    }
                }
            }
        })
    }

    async function getOutlookAccountInfo(attendeeEmpIds = '''') {
        return new Promise(resolve => {
            // First try Corporate Token (365 enterprise)
            AjaxHPAParadise({
                data: {
                    name: "sp_Calendar_GetAccessToken",
                    param: [''LoginID'', window.UserID, ''CalendarID'', 1]
                },
                success: function (data) {
                    if (typeof data == "string" && !IsNullOrEmpty(data)) {
                        data = data.includes("{") ? data : EncryptionStringDecryption(data);
                    }
                   let res = JSON.parse(data);
                  if (res.data && res.data[0] && res.data[0].length > 0 && res.data[0][0].AccessToken) {
                        // Corporate 365 mode: single token for all users
                        resolve({
                            mode: ''corporate'',
                            token: res.data[0][0].AccessToken,
                        });
                    } else {
                        // Try Individual Tokens (each employee has own token)
                        fetchIndividualToken(resolve, attendeeEmpIds);
                    }
                },
                error: () => fetchIndividualToken(resolve, attendeeEmpIds)
            })
        });
    }

    function fetchIndividualToken(resolve, attendeeEmpIds = '''') {
        // Build EmployeeIDs list: organizer + attendees
        const organizerEmpId = window.EmployeeID_Login || '''';

        // Build array of IDs, filter empty values, then join
        const allEmpIds = [organizerEmpId, attendeeEmpIds]
            .filter(id => id && id.trim() !== '''')
            .join('','');

        // If no EmployeeIDs available, cannot fetch token
        if (!allEmpIds) {
            console.error(''No EmployeeIDs available for token fetch'');
            resolve({ mode: ''individual'', tokens: [] });
            return;
        }

        AjaxHPAParadise({
            data: {
                name: "sp_Calendar_GetAccessTokenFree",
                param: [''EmployeeIDs'', allEmpIds.toString()]
            },
            success: function (data) {
                if (typeof data == "string" && !IsNullOrEmpty(data)) {
                    data = data.includes("{") ? data : EncryptionStringDecryption(data);
                }
                let res = JSON.parse(data);
                if (res.data && res.data[0] && res.data[0].length > 0) {
                    // Return ALL tokens as array
                    resolve({ mode: ''individual'', tokens: res.data[0] });
                } else {
                    resolve({ mode: ''individual'', tokens: [] });
                }
            },
            error: () => resolve({ mode: ''individual'', tokens: [] })
        });
    }

    $(async () => {
        let PermissionAsscess = {
            HasFullAccess: false,
            HasManagerAccess: false,
            HasCustomerAccess: false,
            HasUsersAccess: false
        }
        let AccessKey = '''';
        await loadPermission();
        async function loadPermission() {
            return new Promise((resolve, reject) => {
                AjaxHPAParadise({
                    data: {
                        name: "sp_Common_GetUserPermissions",
                        param: ["LoginID", window.UserID]
                    },
                    success: function (data) {
                        if (typeof data == "string" && !IsNullOrEmpty(data)) {
                            data = data.includes("{") ? data : EncryptionStringDecryption(data);
                        }
                        let dataObject = JSON.parse(data);
                        let permissionData = dataObject.data?.[0];
                        if (permissionData && permissionData.length > 0) {
                            PermissionAsscess.HasFullAccess = permissionData[0].HasFullAccess;
                            PermissionAsscess.HasManagerAccess = permissionData[0].HasManagerAccess;
                            PermissionAsscess.HasCustomerAccess = permissionData[0].HasCustomerAccess;
                            PermissionAsscess.HasUsersAccess = permissionData[0].HasUsersAccess;
                        }

                        if (AccessKey === '''') {
                            if (PermissionAsscess.HasFullAccess) {
                                AccessKey = ''FULLACCESS'';
                            } else if (PermissionAsscess.HasManagerAccess) {
            AccessKey = ''MANAGER'';
                        } else if (PermissionAsscess.HasUsersAccess) {
                                AccessKey = ''USER'';
                            } else if (PermissionAsscess.HasCustomerAccess) {
                                AccessKey = ''CUSTOMER'';
                            }
                        }

                        // Ẩn select Employee nếu là USER
                        if (AccessKey === ''USER'') {
                            const $employeeFilter = $(''#dashboardFilterEmployee'').closest(''.filter-group'');
                            if ($employeeFilter.length) {
                                $employeeFilter.hide();
                            }
                        }
                        // Ẩn btnSettings nếu không phải FULLACCESS hoặc MANAGER
                        if (AccessKey !== ''FULLACCESS'' && AccessKey !== ''MANAGER'') {
                            const $btnSettings = $(''#btnSettings'');

                            if (AccessKey !== ''FULLACCESS'' && AccessKey !== ''MANAGER'') {
                                $btnSettings.attr(
                                    ''style'',
                                    ''display: none !important;''
                                );
                            } else {
                                $btnSettings.attr(
                                    ''style'',
                                    ''display: flex !important;''
                                );
                            }

                        }
                        resolve();
                    },
                    error: reject
                })
            })
        }
        // InstanceNVKPI_IDPF2722DC090454A53A549F3E773C07EC4
        // InstanceDVT_IDP39A23829013F4A98ADF6641FB04BFB7B
        // InstanceKPI_IDP7A6682CA6E8141DFB2244DB71032A266
        // KPI_requiredPCF26DFF3C8E1439783E535E6C90E0468RealInstance
        // ExperiencePointsP9A3C6268FB014323A095C16A60E1925FRealInstance
        // BonusPerItemP5F4411446A9447688E6023972985B894RealInstance
        // Coin_BonusPerItemP16FAB824436D423EA05CFE561E321AA4RealInstance
        // InstanceEffectiveDateP4FA6222B45A34106B51C016423D0A78B
        // CoinP90AA0D5082AD44AA8EBBB09EFF1A79ECRealInstance

        let DataSource = []

        // Load DataSource: sp_CRM_getKPICategories
        if ("sp_CRM_getKPICategories" && "sp_CRM_getKPICategories".trim() !== "") {
            loadDataSourceCommon("KPI_ID", "sp_CRM_getKPICategories", function (data) {
                // Data được shared qua callback
            });
        }

        // Load DataSource: sp_CRM_getKPITimeUnits
        if ("sp_CRM_getKPITimeUnits" && "sp_CRM_getKPITimeUnits".trim() !== "") {
            loadDataSourceCommon("DVT_ID", "sp_CRM_getKPITimeUnits", function (data) {
                // Data được shared qua callback
            });
        }

        // Load DataSource: sp_EmployeeListDataMultiSelect
        if ("sp_EmployeeListDataMultiSelectSelectBox" && "sp_EmployeeListDataMultiSelectSelectBox".trim() !== "") {
            loadDataSourceCommon("NVKPI_ID", "sp_EmployeeListDataMultiSelectSelectBox", function (data) {
                // Data được shared qua callback
            });
        }

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
                        param: ["LoginID", LoginID, "LanguageID", LanguageID, "AccessKey", AccessKey]
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



        if (!document.getElementById("hpa-central-styles")) {
            $("<style>")
                .attr("id", "hpa-central-styles")
                .text(`
                    /* --- Base Styles --- */
                    .dx-widget { font-size:inherit!important; font-weight:inherit!important; line-height:inherit!important; border-radius:inherit!important; }
                    .dx-texteditor, .dx-texteditor-input { font-size:inherit!important; font-weight:inherit!important; line-height:inherit!important; box-sizing:border-box!important; }

                    /* --- Responsive & Popup Styles --- */
                    .hpa-responsive { max-width: 98vw !important; max-height: 98vh !important; }
                    .hpa-responsive .dx-popup-content { padding: 8px !important; display: flex !important; flex-direction: column !important; }
                    .hpa-responsive .dx-popup-content-scrollable { flex: 1 !important; min-height: 0 !important; overflow: auto !important; }

                    /* --- Grid Customizations --- */
                  .dx-datagrid-headers { white-space: normal; word-break: break-word; }
                    .dx-datagrid-header-panel { padding: 8px; }
                    .dx-datagrid .dx-row > td { padding: 8px !important; vertical-align: middle !important; }
                    .dx-datagrid-rowsview .dx-row > td > div { white-space: nowrap !important; overflow: hidden; text-overflow: ellipsis; line-height: 1.4 !important; }

                    /* --- Search Styles --- */
                    .dx-datagrid-search-panel .dx-placeholder { display: none !important; }
    .dx-datagrid-search-panel input:not(:placeholder-shown) { color: #000 !important; }

                  /* --- Avatar & Chip Styles --- */
                    .hpa-avatar-group { display: flex; alignItems: center; }
                    .hpa-avatar { border: 2px solid #fff; box-shadow: 0 2px 4px rgba(0,0,0,0.1); object-fit: cover; }

                    /* --- KPI Results Modal Styles --- */
                    .table-hover tbody tr:hover { background-color: rgba(0,123,255,0.1) !important; }
                    .badge-success-custom { background-color: #28a745; color: white; border-radius: 12px; padding: 4px 8px; font-size: 0.8em; }
                    .badge-danger-custom { background-color: #dc3545; color: white; border-radius: 12px; padding: 4px 8px; font-size: 0.8em; }
                    .achievement-bar { height: 20px; background-color: #e9ecef; border-radius: 10px; overflow: hidden; }
                    .achievement-fill { height: 100%; background: linear-gradient(90deg, #28a745, #20c997); transition: width 0.3s ease; }
                    .kpi-card-mini { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px; border-radius: 10px; margin-bottom: 10px; }
                    .period-badge { background-color: #6c757d; color: white; border-radius: 15px; padding: 2px 8px; font-size: 0.75em; }
                `)
                .appendTo("head");
        }


        if (!window.__hpaSelectBoxUnderlineStyleInjected) {
            $("<style>")
                .attr("id", "hpa-selectbox-underline-style")
                .text(`
                    .dx-selectbox.dx-editor-underlined::after {
                        border-bottom-color: #ddd !important;
                    }
                    .dx-selectbox.dx-editor-underlined .dx-texteditor-input {
                        background: transparent;
                        box-shadow: none;
                        padding: 2px 0px;
                        font-size: inherit;
                        font-weight: inherit;
                    }
                `)
                .appendTo("head");
            window.__hpaSelectBoxUnderlineStyleInjected = true;
        }

        window["DataSource_NVKPI_ID"] = window["DataSource_NVKPI_ID"] || [];

        let NVKPI_IDPF21433BAA7444823B61584359F91D433DataSourceSP = "sp_EmployeeListDataMultiSelectSelectBox";
        let NVKPI_IDPF21433BAA7444823B61584359F91D433IsLoading = false;
        let NVKPI_IDPF21433BAA7444823B61584359F91D433IsDataLoaded = false;
        let _autoSaveNVKPI_IDPF21433BAA7444823B61584359F91D433 = false;
        let _readOnlyNVKPI_IDPF21433BAA7444823B61584359F91D433 = false;
        let NVKPI_IDPF21433BAA7444823B61584359F91D433TableAddNew = "";
        let NVKPI_IDPF21433BAA7444823B61584359F91D433ColumnAddNew = "";
        let NVKPI_IDPF21433BAA7444823B61584359F91D433CurrentSearch = "";
        let NVKPI_IDPF21433BAA7444823B61584359F91D433LastSearchValue = "";
        let InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433 = null;
        const NVKPI_IDPF21433BAA7444823B61584359F91D433LastSearchClass = "hpa-last-search-PF21433BAA7444823B61584359F91D433";

        function getDataSourceConfigNVKPI_IDPF21433BAA7444823B61584359F91D433(data) {
            const idField = window["DataSourceIDField_NVKPI_ID"] || "ID";
            return new DevExpress.data.DataSource({
           paginate: false,
          store: new DevExpress.data.CustomStore({
           key: idField,
                    load: function (loadOptions) {
                        let searchValue = NVKPI_IDPF21433BAA7444823B61584359F91D433CurrentSearch || "";

                        if (!searchValue && loadOptions && loadOptions.searchValue) {
                            searchValue = loadOptions.searchValue;
                        }

                        if (!searchValue && InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433 && InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option) {
                            searchValue = InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("searchValue") || "";
                        }

                        let result = data || [];

                        if (searchValue && searchValue.trim()) {
                            result = result.filter(item => customSearchNVKPI_ID(item, searchValue));

                            if (NVKPI_IDPF21433BAA7444823B61584359F91D433TableAddNew && NVKPI_IDPF21433BAA7444823B61584359F91D433TableAddNew.trim() !== "") {
                                const nameField = window["DataSourceNameField_NVKPI_ID"] || "Name";
                                const addNewItem = { IsAddNew: true };
                                addNewItem[nameField] = searchValue.trim();
                                result.push(addNewItem);
                            }
                        }

                        return Promise.resolve(result);
                    },
                    byKey: function (key) {
                        const idField = window["DataSourceIDField_NVKPI_ID"] || "ID";
                        return Promise.resolve((data || []).find(i => i[idField] === key));
                    }
                })
            });
        }

        async function processAddNewNVKPI_ID(newValue) {
            if (!newValue || !newValue.trim()) return;
            console.log(newValue);
            InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("disabled", true);

            const dataJSON = JSON.stringify([NVKPI_IDPF21433BAA7444823B61584359F91D433TableAddNew, [NVKPI_IDPF21433BAA7444823B61584359F91D433ColumnAddNew], [newValue.trim()]]);

            try {
                console.log("dataJSON", dataJSON);
                const json = await saveFunction(dataJSON);
                const dtError = json.data[json.data.length - 1] || [];

                if (dtError.length > 0 && dtError[0].Status === "ERROR") {
                    uiManager.showAlert({ type: "error", message: dtError[0]?.Message || "Lỗi thêm mới" });
                } else {
                    const newItemID = dtError[0]?.IDValue || null;

                    if (newItemID) {
                        const idField = window["DataSourceIDField_NVKPI_ID"] || "ID";
                        const nameField = window["DataSourceNameField_NVKPI_ID"] || "Name";

                        const newItem = {};
                        newItem[idField] = newItemID;
                        newItem[nameField] = newValue.trim();

                        if (!window["DataSource_NVKPI_ID"]) {
                            window["DataSource_NVKPI_ID"] = [];
                        }
                        window["DataSource_NVKPI_ID"].push(newItem);

                        InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("dataSource", getDataSourceConfigNVKPI_IDPF21433BAA7444823B61584359F91D433(window["DataSource_NVKPI_ID"]));

                        InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("value", newItemID);
                        InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("searchValue", "");
                        NVKPI_IDPF21433BAA7444823B61584359F91D433CurrentSearch = "";
                    }
                }
            } catch (e) {
                console.error(e);
                uiManager.showAlert({ type: "error", message: "Có lỗi khi thêm mới" });

            } finally {
                InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("disabled", false);
                InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.close();
            }
        }

        function customSearchNVKPI_ID(item, searchValue) {
            if (!searchValue) return true;
            const searchNormalized = hpaUtils.removeToneMarks(searchValue).toLowerCase();
            const idField = window["DataSourceIDField_NVKPI_ID"] || "ID";
            const nameField = window["DataSourceNameField_NVKPI_ID"] || "Name";
            const fields = [idField, nameField, "Code", "Description"];

            for (let i = 0; i < fields.length; i++) {
                const fieldValue = item[fields[i]];
                if (fieldValue) {
                    const fieldNormalized = hpaUtils.removeToneMarks(String(fieldValue)).toLowerCase();
                    if (fieldNormalized.indexOf(searchNormalized) !== -1) return true;
                }
            }
            return false;
        }

        function renderLastSearchHintNVKPI_IDPF21433BAA7444823B61584359F91D433($popupContent) {
            if (!$popupContent || !$popupContent.length) return;

            const lastSearch = (NVKPI_IDPF21433BAA7444823B61584359F91D433LastSearchValue || "").trim();
            let $hint = $popupContent.find("." + NVKPI_IDPF21433BAA7444823B61584359F91D433LastSearchClass);

            if (!lastSearch) {
                if ($hint.length) {
                    $hint.remove();
                }
                return;
            }

            if (!$hint.length) {
                $hint = $("<div>")
                    .addClass(NVKPI_IDPF21433BAA7444823B61584359F91D433LastSearchClass + " d-flex align-items-center justify-content-between gap-2 px-3 py-2 border-bottom")
                    .css({
                        fontSize: "12px",
                        background: "#f8f9fa"
                    })
                    .prependTo($popupContent);

                $("<span>")
                    .addClass("flex-fill text-muted text-truncate")
                    .appendTo($hint);

                $("<button>")
                    .attr("type", "button")
                    .addClass("btn btn-link p-0 text-decoration-none fw-semibold")
                    .text("Áp dụng lại")
                    .on("dxclick", function (ev) {
                        ev.preventDefault();
                        ev.stopPropagation();
                        if (!NVKPI_IDPF21433BAA7444823B61584359F91D433LastSearchValue) return;
                        NVKPI_IDPF21433BAA7444823B61584359F91D433CurrentSearch = NVKPI_IDPF21433BAA7444823B61584359F91D433LastSearchValue;
                        InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("searchValue", NVKPI_IDPF21433BAA7444823B61584359F91D433LastSearchValue);
                        const $input = $("#PF21433BAA7444823B61584359F91D433").find(".dx-texteditor-input");
                        if ($input && $input.length) {
                            setTimeout(function () { $input.focus(); }, 0);
                        }
                    })
                    .appendTo($hint);
            }

            $hint.find("span").text("Lần tìm trước: \"" + lastSearch + "\"");
        }

        InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433 = $("#PF21433BAA7444823B61584359F91D433").dxSelectBox({
            readOnly: _readOnlyNVKPI_IDPF21433BAA7444823B61584359F91D433,
            dataSource: getDataSourceConfigNVKPI_IDPF21433BAA7444823B61584359F91D433(window["DataSource_NVKPI_ID"]),
            valueExpr: window["DataSourceIDField_NVKPI_ID"] || "ID",
            displayExpr: window["DataSourceNameField_NVKPI_ID"] || "Name",
            onOptionChanged: function (e) {
                if (!e || !e.component) return;
                if (e.name === "searchValue") {
                    const newVal = (e.value || "").toString();
                    NVKPI_IDPF21433BAA7444823B61584359F91D433CurrentSearch = newVal;
                    if (newVal && newVal.trim()) {
                        NVKPI_IDPF21433BAA7444823B61584359F91D433LastSearchValue = newVal;
                    }

                    if (e.component.option("opened") && e.component._popup) {
                        renderLastSearchHintNVKPI_IDPF21433BAA7444823B61584359F91D433($(e.component._popup.content()));
                    }
                }
            },
            onContentReady: function (e) { },
            placeholder: "Tìm kiếm hoặc chọn 0...",
            searchEnabled: true,
            searchTimeout: 300,
            minSearchLength: 0,
            showDataBeforeSearch: true,
            showClearButton: false,
            stylingMode: "underlined",
            dropDownOptions: {
                showTitle: false,
                closeOnOutsideClick: true,
                height: "auto",
                maxHeight: 400,
                minWidth: 320,
                onShowing: function (e) {
                    if (InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433 && InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option) {
                        const pendingSearch = InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("searchValue") || "";
                        if (pendingSearch && pendingSearch.trim()) {
                            NVKPI_IDPF21433BAA7444823B61584359F91D433LastSearchValue = pendingSearch;
                        }
                        NVKPI_IDPF21433BAA7444823B61584359F91D433CurrentSearch = "";
                        InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("searchValue", "");
                    }
                },
                onHidden: function () {
                    NVKPI_IDPF21433BAA7444823B61584359F91D433CurrentSearch = "";
                    if (InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433 && InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option) {
                        InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("searchValue", "");
                    }
                }
            },
            itemTemplate: function (data, index) {
                if (data.IsAddNew) {
                    const nameField = window["DataSourceNameField_NVKPI_ID"] || "Name";
                    const $item = $("<div>")
                        .addClass("d-flex align-items-center gap-2 px-3 py-2 text-primary")
                        .css({ cursor: "pointer", borderTop: "1px dashed #dee2e6", fontWeight: "600" });

                    $("<i>").addClass("bi bi-plus-circle fs-6").appendTo($item);
                    $("<span>").text("Thêm mới: \"" + data[nameField] + "\"").appendTo($item);

                    $item.on("dxclick", async function (e) {
                        e.stopPropagation();
                        if (InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433 && InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.blur) InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.blur();
                        await processAddNewNVKPI_ID(data[nameField]);
                    });

                    return $item;
                }

                const idField = window["DataSourceIDField_NVKPI_ID"] || "ID";
                const nameField = window["DataSourceNameField_NVKPI_ID"] || "Name";
                const searchValue = InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("searchValue") || "";

                const $item = $("<div>")
                    .addClass("d-flex align-items-center gap-2 px-3 py-2 border-bottom border-light")
                    .css({ cursor: "pointer" });

                const $content = $("<div>").addClass("flex-fill").css("minWidth", "0");

                const displayName = (data[idField] !== undefined ? data[idField] + " - " : "") + (data[nameField] || "");
                $("<div>")
                    .addClass("fw-normal ")
                    .css({
                        fontSize: "13px",
                        overflow: "hidden",
                        textOverflow: "ellipsis",
                        whiteSpace: "nowrap"
                    })
                    .html(hpaUtils.highlightText(displayName, searchValue))
                    .appendTo($content);

                if (data.Description || data.Code) {
$("<div>")
                        .addClass("text-muted")
                        .css({
                            fontSize: "11px",
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                            whiteSpace: "nowrap"
                        })
                        .text(data.Code || data.Description)
                        .appendTo($content);
                }

                $content.appendTo($item);

                if (data.Status) {
                    const badgeClass = data.Status === "Active" ? "bg-success" : "bg-secondary";
                    $("<span>")
                        .addClass("badge " + badgeClass)
                        .css({
                            fontSize: "9px",
                            padding: "3px 6px",
                            borderRadius: "4px",
                            opacity: "0.8"
                        })
                        .text(data.Status)
                        .appendTo($item);
                }

                return $item;
            },
            onOpened: function (e) {
                const $popupContent = $(e.component._popup.content());
                $popupContent.parent()
                    .addClass("shadow-lg border rounded")
                    .css({
                        borderRadius: "8px",
                        padding: "4px 0",
                        borderColor: "#dee2e6"
                    });

                renderLastSearchHintNVKPI_IDPF21433BAA7444823B61584359F91D433($popupContent);
            },
            onFocusIn: function (e) {
                InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("showClearButton", true);
            },
            onFocusOut: function (e) {
                InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("showClearButton", false);
            },
            onKeyDown: function (e) {
                if (e.key === "Enter" || e.key === "Tab") {
                    InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("showClearButton", false);
                }
            },
            onValueChanged: async function (e) {
                console.log(''=== Employee onValueChanged ==='', e.value);
                if (e.value === e.previousValue) return;

                const filterType = $(''#filterType'').val();
                const filterDate = $(''#filterDate'').val();
                if (typeof reloadDashboardWithDate === ''function'') {
                    reloadDashboardWithDate(filterType, filterDate);
                }

                if (typeof window["onSelectBoxChanged_NVKPI_ID"] === "function") {
                    window["onSelectBoxChanged_NVKPI_ID"](e.value, InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433, e);
                }

                if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {
                    try {
                        const grid = cellInfo.component;
                        grid.cellValue(cellInfo.rowIndex, "NVKPI_ID", e.value);
                        grid.repaint();
                    } catch (syncErr) {
                        console.warn("[Grid Sync] Không thể sync grid:", syncErr);
                    }
                }
            }
        }).dxSelectBox("instance");

        let _initialNVKPI_IDPF21433BAA7444823B61584359F91D433 = InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("value");

        if (NVKPI_IDPF21433BAA7444823B61584359F91D433DataSourceSP && NVKPI_IDPF21433BAA7444823B61584359F91D433DataSourceSP !== "") {
            loadDataSourceCommon("NVKPI_ID", NVKPI_IDPF21433BAA7444823B61584359F91D433DataSourceSP, function (data) {
                NVKPI_IDPF21433BAA7444823B61584359F91D433IsDataLoaded = true;

                const idField = window["DataSourceIDField_NVKPI_ID"] || "ID";
                const nameField = window["DataSourceNameField_NVKPI_ID"] || "Name";

                InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("valueExpr", idField);
                InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("displayExpr", nameField);

                InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.option("dataSource", getDataSourceConfigNVKPI_IDPF21433BAA7444823B61584359F91D433(data));
                InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433.repaint();


            });
        }

        '
            + (select loadUI from tblCommonControlType_Signed where UID = 'PF2722DC090454A53A549F3E773C07EC4')
        + (select loadUI from tblCommonControlType_Signed where UID = 'P39A23829013F4A98ADF6641FB04BFB7B')
    +(select loadUI from tblCommonControlType_Signed where UID = 'P7A6682CA6E8141DFB2244DB71032A266')
    +(select loadUI from tblCommonControlType_Signed where UID = 'PCF26DFF3C8E1439783E535E6C90E0468')
    +(select loadUI from tblCommonControlType_Signed where UID = 'P9A3C6268FB014323A095C16A60E1925F')
    -- + (select loadUI from tblCommonControlType_Signed where UID = 'P5F4411446A9447688E6023972985B894')
    -- + (select loadUI from tblCommonControlType_Signed where UID = 'P16FAB824436D423EA05CFE561E321AA4')
    +(select loadUI from tblCommonControlType_Signed where UID = 'P4FA6222B45A34106B51C016423D0A78B')
    +(select loadUI from tblCommonControlType_Signed where UID = 'P90AA0D5082AD44AA8EBBB09EFF1A79EC') +N'

    window.currentRecordID_ID = null;

    // Load KPI config when modal opens
    const loadKpiConfig = () => {
        const kpiConfig = JSON.parse(localStorage.getItem(''kpiConfig'') || ''{}'');
        const today = new Date().toISOString();
        // let obj = {
        //     EffectiveDate: today
        // };
        // ''+
        //     (select loadData from tblCommonControlType_Signed where UID = ''PF2722DC090454A53A549F3E773C07EC4'')
        //     + N''
    };

    // Load config on page load
    loadKpiConfig();

    // Load config when modal is shown
    $(''#settingsModal'').on(''show.bs.modal'', loadKpiConfig);

    // Save KPI config
    $(''#saveKpiConfig'').on(''click'', () => {
        // Validate required fields

        //InstanceNVKPI_IDPF2722DC090454A53A549F3E773C07EC4
        //InstanceDVT_IDP39A23829013F4A98ADF6641FB04BFB7B
        //InstanceKPI_IDP7A6682CA6E8141DFB2244DB71032A266
        //KPI_requiredPCF26DFF3C8E1439783E535E6C90E0468RealInstance
        //ExperiencePointsP9A3C6268FB014323A095C16A60E1925FRealInstance
        //BonusPerItemP5F4411446A9447688E6023972985B894RealInstance
        //Coin_BonusPerItemP16FAB824436D423EA05CFE561E321AA4RealInstance
        //InstanceEffectiveDateP4FA6222B45A34106B51C016423D0A78B
        // Get values từ các instance DevExpress
        let isValid = true;

        // Kiểm tra xem các instance có value không
        if (!InstanceNVKPI_IDPF2722DC090454A53A549F3E773C07EC4?.option(''value'') ||
            !InstanceDVT_IDP39A23829013F4A98ADF6641FB04BFB7B?.option(''value'') ||
            !InstanceKPI_IDP7A6682CA6E8141DFB2244DB71032A266?.option(''value'') ||
            !KPI_requiredPCF26DFF3C8E1439783E535E6C90E0468RealInstance?.option(''value'') ||
            !ExperiencePointsP9A3C6268FB014323A095C16A60E1925FRealInstance?.option(''value'') ||
            // !BonusPerItemP5F4411446A9447688E6023972985B894RealInstance?.option(''value'') ||
            // !Coin_BonusPerItemP16FAB824436D423EA05CFE561E321AA4RealInstance?.option(''value'') ||
            !InstanceEffectiveDateP4FA6222B45A34106B51C016423D0A78B?.option(''value'')) {
            isValid = false;
        }

        if (!isValid) {
            uiManager.showAlert({ type: "error", message: "Vui lòng nhập đủ các trường thông tin!" });
            return;
        }

        // bonusExperiencePoints: parseFloat(BonusPerItemP5F4411446A9447688E6023972985B894RealInstance?.option(''value'')) || 0,
        // bonusCoin: parseFloat(Coin_BonusPerItemP16FAB824436D423EA05CFE561E321AA4RealInstance?.option(''value'')) || 0,

        const kpiConfig = {
            employeeCode: InstanceNVKPI_IDPF2722DC090454A53A549F3E773C07EC4?.option(''value''),
            kpiCategory: InstanceKPI_IDP7A6682CA6E8141DFB2244DB71032A266?.option(''value''),
            kpiUnit: InstanceDVT_IDP39A23829013F4A98ADF6641FB04BFB7B?.option(''value''),
            kpiTarget: parseFloat(KPI_requiredPCF26DFF3C8E1439783E535E6C90E0468RealInstance?.option(''value'')) || 0,
            experiencePointsAchieved: parseFloat(ExperiencePointsP9A3C6268FB014323A095C16A60E1925FRealInstance?.option(''value'')) || 0,
            coinAchieved: parseFloat(CoinP90AA0D5082AD44AA8EBBB09EFF1A79ECRealInstance?.option(''value'')) || 0,
            effectiveDate: InstanceEffectiveDateP4FA6222B45A34106B51C016423D0A78B?.option(''value'')
        };

        console.log(''KPI Config to save:'', kpiConfig);

        // Chuẩn bị data để gửi API
        const apiData = {
            NVKPI_ID: kpiConfig.employeeCode,
            DVT_ID: kpiConfig.kpiUnit,
            KPI_ID: kpiConfig.kpiCategory,
            KPI_required: kpiConfig.kpiTarget,
            ExperiencePoints: kpiConfig.experiencePointsAchieved,
            BonusPerItem: kpiConfig.kpiTarget > 0 ? (kpiConfig.experiencePointsAchieved / kpiConfig.kpiTarget).toFixed(2) : 0,
            Coin_BonusPerItem: kpiConfig.kpiTarget > 0 ? (kpiConfig.coinAchieved / kpiConfig.kpiTarget).toFixed(2) : 0,
            EffectiveDate: kpiConfig.effectiveDate,
            CreateDate: new Date().toISOString().split(''T'')[0], // YYYY-MM-DD format
            Coin: kpiConfig.coinAchieved
        };

        // Gọi API để lưu KPI config
        AjaxHPAParadise({
            data: {
                name: "sp_CRM_SaveConfigKPI",
                param: [
                    ''apiData'', JSON.stringify(apiData)
                ]
            },
            success: function (data) {
                try {
                    if (typeof data == "string" && !IsNullOrEmpty(data)) {
                        data = data.includes("{") ? data : EncryptionStringDecryption(data);
                    }
                    let result = JSON.parse(data);

                    if (result.data && result.data[0] && result.data[0].length > 0) {
                        const response = result.data[0][0];

                        if (response.Result === ''SUCCESS'' || response.Result === ''UPDATED'' || response.Result === ''INSERTED'') {
                            uiManager.showAlert({ type: "success", message: "Lưu thành công!" });
                            $(''#settingsModal'').modal(''hide'');
                            document.getElementById(''kpiConfigForm'').reset();
                        } else {
                            uiManager.showAlert({ type: "error", message: "Có lỗi xảy ra, vui lòng thử lại" });
                        }
                    } else {
                        uiManager.showAlert({ type: "error", message: "Có lỗi xảy ra khi xử lý dữ liệu!" });
                    }
                } catch (e) {
                    console.error(''Parse error:'', e);
                    uiManager.showAlert({ type: "error", message: "Có lỗi xảy ra khi xử lý phản hồi!" });
                }
            },
            error: function (error) {
   console.error(''Error saving KPI config:'', error);
                uiManager.showAlert({ type: "error", message: "Có lỗi xảy ra khi lưu cấu hình KPI!" });
            }
        });

    });

    $("#btnRecalculate").on("click", function () {
        const btn = $(this);

        // Disable button
        btn.prop(''disabled'', true);
        btn.data(''original-text'', btn.find(''span'').text());
        btn.html(''<i class="fas fa-spinner fa-spin me-2"></i><span>%Loading%</span>'');

        // Lấy date range từ filter
        const filterType = $(''#filterType'').val();
        const filterDate = $(''#filterDate'').val();

        let dateRange = { start: new Date(), end: new Date() };

        if (filterType === ''day'') {
            const selectedDate = new Date(filterDate);
            dateRange = { start: selectedDate, end: selectedDate };
        } else if (filterType === ''week'') {
            const parts = filterDate.split(''-W'');
            if (parts.length === 2) {
                const year = parseInt(parts[0]);
                const week = parseInt(parts[1]);
                const jan4 = new Date(year, 0, 4);
                const dayOfJan4 = jan4.getDay() || 7;
                const monOfJan4 = new Date(jan4);
                monOfJan4.setDate(jan4.getDate() - dayOfJan4 + 1);
                const weekStart = new Date(monOfJan4);
                weekStart.setDate(monOfJan4.getDate() + (week - 1) * 7);
                dateRange.start = weekStart;
                dateRange.end = new Date(weekStart);
                dateRange.end.setDate(dateRange.end.getDate() + 6);
            }
        } else if (filterType === ''month'') {
            const parts = filterDate.split(''-'');
            if (parts.length === 2) {
                const year = parseInt(parts[0]);
                const month = parseInt(parts[1]);
                dateRange.start = new Date(year, month - 1, 1);
                dateRange.end = new Date(year, month, 0);
            }
        }

        // Format dates
        const formatLocalDate = (date) => {
            return String(date.getFullYear()).padStart(4, ''0'') + ''-'' +
                String(date.getMonth() + 1).padStart(2, ''0'') + ''-'' +
                String(date.getDate()).padStart(2, ''0'');
        };

        const fromDateParam = formatLocalDate(dateRange.start);
        const toDateParam = formatLocalDate(dateRange.end);

        // Gọi API
        AjaxHPAParadise({
            data: {
                name: "sp_CRM_RecalculateKPI",
                param: [''FromDate'', fromDateParam, ''ToDate'', toDateParam]
            },
            success: function (data) {
                try {
                    if (typeof data == "string" && !IsNullOrEmpty(data)) {
                        data = data.includes("{") ? data : EncryptionStringDecryption(data);
                    }
                    let result = JSON.parse(data);
                    if (result.data && result.data[0] && result.data[0].length > 0) {
                        const response = result.data[0][0];

                        if (response.Result == "SUCCESS") {
                            uiManager.showAlert({ type: "success", message: "%RecalculateSuccess%" });
                            // Reload dashboard
                            reloadDashboardWithDate(filterType, filterDate);
                        } else {
                            uiManager.showAlert({ type: "error", message: "%RecalculateFailed%" });
                        }
                    } else {
                        uiManager.showAlert({ type: "error", message: "%DataProcessingError%" });
                    }
                    btn.prop(''disabled'', false);
                    btn.html(''<i class="fas fa-sync me-2"></i>'' + (btn.data(''original-text'') || ''Tính toán lại''));
                } catch (e) {
                    console.error(''Parse error:'', e);
                    uiManager.showAlert({ type: "error", message: "%RecalculateError%" });
                btn.prop(''disabled'', false);
                    btn.html(''<i class="fas fa-sync me-2"></i>'' + (btn.data(''original-text'') || ''%Recalculate%''));
                }

            },
            error: function (error) {
                console.error(''Error:'', error);
                uiManager.showAlert({ type: "error", message: "%RecalculateError%" });

                // Re-enable button sau 3 giây
                setTimeout(function () {
                    btn.prop(''disabled'', false);
                    btn.html(''<i class="fas fa-sync me-2"></i>'' + (btn.data(''original-text'') || ''%Recalculate%''));
                }, 3000);
            }
        });
    });
    // ========== MODAL FUNCTIONS ==========

    // Handle email input for demo_attendees
    $(document).on(''keydown'', ''#demo_attendees'', function (e) {
        const email = $(this).val().trim();

        if (e.key === ''Enter'' || e.key === '','') {
            e.preventDefault();

            // Remove comma if user typed comma
            const cleanEmail = email.replace(/,\s*$/, '''').trim();

            if (cleanEmail) {
                // Try to find EmployeeID from mailEmployeeList
                const emp = mailEmployeeList.find(e => e.Email === cleanEmail);
                const empId = emp ? emp.EmployeeID : '''';
                addEmailTag(cleanEmail, empId);
            }
        }
    });

    // Handle datalist selection for demo_attendees
    $(document).on(''change'', ''#demo_attendees'', function () {
        const email = $(this).val().trim();
        if (email && email !== '''') {
            // Find EmployeeID from mailEmployeeList
            const emp = mailEmployeeList.find(e => e.Email === email);
            const empId = emp ? emp.EmployeeID : '''';
            addEmailTag(email, empId);
        }
    });

    // Handle view data list button
    $(document).ready(function () {
        const $viewDataListBtn = $(''#viewDataListBtn'');
        if ($viewDataListBtn.length) {
            $viewDataListBtn.on(''click'', function (e) {
                e.preventDefault();
                // You can replace this with actual page navigation or open a modal
                console.log(''Viewing data collection list'');
                showNotification(''%DataCollectionMessage%'', ''info'');
                // Example: window.location.href = ''data-list.html'';
            });
        }
    });

    // ========== EMPLOYEE KPI RANKING DATA ==========
    // var employeeKpiRankingData = [
    //     { rank: 1, name: ''Nguyễn Thái Sơn'', department: ''Sales'', score: 95, emails: 28, calls: 12, demos: 5, followups: 8 },
    //     { rank: 2, name: ''Trần Minh Hằng'', department: ''Sales'', score: 92, emails: 26, calls: 11, demos: 4, followups: 7 },
    //     { rank: 3, name: ''Phạm Huy Hoàng'', department: ''Business Dev'', score: 88, emails: 24, calls: 10, demos: 4, followups: 6 },
    //     { rank: 4, name: ''Lê Văn Tùng'', department: ''Sales'', score: 85, emails: 22, calls: 9, demos: 3, followups: 5 },
    //     { rank: 5, name: ''Đỗ Quỳnh Anh'', department: ''Account Manager'', score: 82, emails: 20, calls: 8, demos: 3, followups: 5 },
    //     { rank: 6, name: ''Hoàng Mạnh Cường'', department: ''Sales'', score: 79, emails: 18, calls: 7, demos: 2, followups: 4 },
    //     { rank: 7, name: ''Vũ Thị Hương'', department: ''Business Dev'', score: 76, emails: 16, calls: 6, demos: 2, followups: 3 },
    //     { rank: 8, name: ''Tô Văn Khoa'', department: ''Sales'', score: 73, emails: 14, calls: 5, demos: 2, followups: 3 }
    // ];

    var employeeKpiRankingData = [
    ];

    async function loadEmployeeKpiRankingData(fromDate, toDate) {
        return new Promise((resolve, reject) => {
            AjaxHPAParadise({
         data: {
                    name: "sp_KPIgetEmployeeKpiRanking",
                    param: [
          ''LoginID'', window.UserID,
                        ''FromDate'', fromDate,
                        ''ToDate'', toDate,
                        ''LanguageID'', window.LanguageID
                    ]
                },
                success: function (data) {
                    if (typeof data == "string" && !IsNullOrEmpty(data)) {
                        data = data.includes("{") ? data : EncryptionStringDecryption(data);
                    }
                    let res = JSON.parse(data);
                    if (res.data && res.data[0]) {
                        employeeKpiRankingData = res.data[0];
                        resolve();
                    } else {
                        employeeKpiRankingData = [];
                        resolve();
                    }
                },
                error: () => {
                    employeeKpiRankingData = [];
                    resolve();
                }
            });
        });
    }

    // Handle industry selection change
    $(document).ready(function () {
        const $industrySelect = $(''#industry'');
        const $industryOtherInput = $(''#industryOther'');

        if ($industrySelect.length) {
            $industrySelect.on(''change'', function () {
                if ($(this).val() === ''Other'') {
                    $industryOtherInput.show();
                    $industryOtherInput.prop(''required'', true);
                } else {
                    $industryOtherInput.hide();
                    $industryOtherInput.prop(''required'', false);
                    $industryOtherInput.val('''');
                }
            });
        }
    });

    // Phân trang cho bảng KPI nhân viên
    let employeeKpiCurrentPage = 1;
    const employeeKpiRowsPerPage = 10;

    function renderEmployeeKpiRanking() {
        const $tbody = $(''#employeeKpiRankingBody'');
        $tbody.empty();

        // Hiển thị thông báo nếu không có dữ liệu
        if (!employeeKpiRankingData || employeeKpiRankingData.length === 0) {
            const $emptyRow = $(`
                    <tr>
                        <td colspan="4" style="text-align: center; padding: 20px; color: #999;">
                            <em>Chưa có dữ liệu</em>
                        </td>
                    </tr>
                `);
            $tbody.append($emptyRow);
            renderEmployeeKpiPagination();
            return;
        }

        const start = (employeeKpiCurrentPage - 1) * employeeKpiRowsPerPage;
        const end = start + employeeKpiRowsPerPage;
        const pageData = employeeKpiRankingData.slice(start, end);

        pageData.forEach(employee => {
            const scoreColor = employee.score >= 90 ? ''text-success'' : (employee.TotalExp >= 80 ? ''text-warning'' : ''text-danger'');
            const medalIcon = employee.RankNo === 1 ? ''🥇'' : (employee.RankNo === 2 ? ''🥈'' : (employee.RankNo === 3 ? ''🥉'' : ''''));
            const $row = $(`
                <tr>
                    <td><strong>${medalIcon} ${employee.TotalExp}</strong></td>
                    <td>${employee.FullName}</td>
                    <td>${DevExpress.localization.formatDate(new Date(employee.HireDate), "dd/MM/yyyy")}</td>
                    <td><span class="${scoreColor}"><strong>${employee.TotalExp}</strong></span></td>
                </tr>
            `);
            $tbody.append($row);
        });
        renderEmployeeKpiPagination();
    }

    function renderEmployeeKpiPagination() {
        let totalPages = Math.ceil(employeeKpiRankingData.length / employeeKpiRowsPerPage);
        let $paginationEl = $(''#employeeKpiPagination'');
        if ($paginationEl.length === 0) {
            $paginationEl = $(`<ul class="pagination justify-content-end" id="employeeKpiPagination"></ul>`);
            $(''#employeeKpiRankingBody'').parent().parent().append($paginationEl);
  }
        $paginationEl.empty();

        // Previous button
        const $prevLi = $(`<li class="page-item ${employeeKpiCurrentPage === 1 ? ''disabled'' : ''''}"><a class="page-link" href="#">Previous</a></li>`);
        $prevLi.on(''click'', function (e) {
            e.preventDefault();
            if (employeeKpiCurrentPage > 1) {
                employeeKpiCurrentPage--;
renderEmployeeKpiRanking();
            }
        });
        $paginationEl.append($prevLi);

        // Page numbers
        for (let i = 1; i <= totalPages; i++) {
            const $li = $(`<li class="page-item ${i === employeeKpiCurrentPage ? ''active'' : ''''}"><a class="page-link" href="#">${i}</a></li>`);
            $li.on(''click'', function (e) {
                e.preventDefault();
                employeeKpiCurrentPage = i;
                renderEmployeeKpiRanking();
            });
            $paginationEl.append($li);
        }

        // Next button
        const $nextLi = $(`<li class="page-item ${employeeKpiCurrentPage === totalPages ? ''disabled'' : ''''}"><a class="page-link" href="#">Next</a></li>`);
        $nextLi.on(''click'', function (e) {
            e.preventDefault();
            if (employeeKpiCurrentPage < totalPages) {
                employeeKpiCurrentPage++;
                renderEmployeeKpiRanking();
            }
        });
        $paginationEl.append($nextLi);
    }


    // ========== PAGINATION DATA & FUNCTIONS ==========
    // const customerData = [
    //     { id: 1, name: ''Nguyễn Văn A'', email: ''nguyenvana@email.com'', phone: ''0912345678'', company: ''Tech Corp'', status: ''Đang theo dõi'', date: ''2025-12-28'' },
    //     { id: 2, name: ''Trần Thị B'', email: ''tranthib@email.com'', phone: ''0923456789'', company: ''Solution Inc'', status: ''Liên hệ lần 2'', date: ''2025-12-27'' },
    //     { id: 3, name: ''Phạm Văn C'', email: ''phamvanc@email.com'', phone: ''0934567890'', company: ''Digital Hub'', status: ''Chưa liên hệ'', date: ''2025-12-26'' },
    //     { id: 4, name: ''Lê Thị D'', email: ''lethid@email.com'', phone: ''0945678901'', company: ''Smart Biz'', status: ''Đã demo'', date: ''2025-12-25'' },
    //     { id: 5, name: ''Đặng Văn E'', email: ''dangvane@email.com'', phone: ''0956789012'', company: ''Future Tech'', status: ''Đang theo dõi'', date: ''2025-12-24'' },
    //     { id: 6, name: ''Hoàng Thị F'', email: ''hoangthif@email.com'', phone: ''0967890123'', company: ''Cloud Systems'', status: ''Liên hệ lần 1'', date: ''2025-12-23'' },
    //     { id: 7, name: ''Vũ Văn G'', email: ''vuvang@email.com'', phone: ''0978901234'', company: ''Data Works'', status: ''Chưa liên hệ'', date: ''2025-12-22'' },
    //     { id: 8, name: ''Tô Thị H'', email: ''tothih@email.com'', phone: ''0989012345'', company: ''Web Solutions'', status: ''Đã demo'', date: ''2025-12-21'' },
    //     { id: 9, name: ''Bùi Văn I'', email: ''buivani@email.com'', phone: ''0990123456'', company: ''Mobile Apps'', status: ''Đang theo dõi'', date: ''2025-12-20'' },
    //     { id: 10, name: ''Đinh Thị J'', email: ''dinhthij@email.com'', phone: ''0901234567'', company: ''AI Innovations'', status: ''Liên hệ lần 2'', date: ''2025-12-19'' },
    //     { id: 11, name: ''Giang Văn K'', email: ''giangvank@email.com'', phone: ''0912345670'', company: ''Enterprise Plus'', status: ''Chưa liên hệ'', date: ''2025-12-18'' },
    //     { id: 12, name: ''Hương Thị L'', email: ''huongthil@email.com'', phone: ''0923456780'', company: ''Global Tech'', status: ''Đã demo'', date: ''2025-12-17'' },
    //     { id: 13, name: ''Ích Văn M'', email: ''ichvanm@email.com'', phone: ''0934567891'', company: ''Smart Office'', status: ''Đang theo dõi'', date: ''2025-12-16'' },
    //     { id: 14, name: ''Khanh Thị N'', email: ''khanhthin@email.com'', phone: ''0945678902'', company: ''Cloud Plus'', status: ''Liên hệ lần 1'', date: ''2025-12-15'' },
    //     { id: 15, name: ''Linh Văn O'', email: ''linhvano@email.com'', phone: ''0956789013'', company: ''Digital First'', status: ''Chưa liên hệ'', date: ''2025-12-14'' },
    //     { id: 16, name: ''Mỹ Thị P'', email: ''mythip@email.com'', phone: ''0967890124'', company: ''Tech Solutions'', status: ''Đã demo'', date: ''2025-12-13'' },
    //     { id: 17, name: ''Nghĩa Văn Q'', email: ''nghiavantq@email.com'', phone: ''0978901235'', company: ''Soft Works'', status: ''Đang theo dõi'', date: ''2025-12-12'' },
    //     { id: 18, name: ''Oanh Thị R'', email: ''oanhthir@email.com'', phone: ''0989012346'', company: ''Business Hub'', status: ''Liên hệ lần 2'', date: ''2025-12-11'' },
    //     { id: 19, name: ''Phong Văn S'', email: ''phongvans@email.com'', phone: ''0990123457'', company: ''Smart Systems'', status: ''Chưa liên hệ'', date: ''2025-12-10'' },
    //     { id: 20, name: ''Quỳnh Thị T'', email: ''quynhthit@email.com'', phone: ''0901234568'', company: ''Tech Pioneers'', status: ''Đã demo'', date: ''2025-12-09'' }
    // ];

    var customerData = [];

    async function getCusTomerRecent(fromDate = '''', toDate = '''') {
        await AjaxHPAParadise({
            data: {
                name: "sp_KPIGetProcessCustomerRecent",
                param: [
                    ''LoginID'', window.UserID,
                    ''LanguageID'', window.LanguageID,
                    ''FromDate'', fromDate || '''',
                    ''ToDate'', toDate || ''''
                ]
            },
            success: function (data) {
                if (typeof data == "string" && !IsNullOrEmpty(data)) {
                    data = data.includes("{") ? data : EncryptionStringDecryption(data);
                }
                let dataObject = JSON.parse(data);
                if (dataObject.data && dataObject.data[0] && dataObject.data[0].length > 0) {
                    customerData = dataObject.data[0];
                    renderTable();
                }
            }
        })
    }

    let currentPage = 1;
    let rowsPerPage = 5;

    // ========== PAGINATION FUNCTIONS ==========
    function renderTable() {
        const $tbody = $(''#customerTableBody'');
        $tbody.empty();

        // Hiển thị thông báo nếu không có dữ liệu
        if (!customerData || customerData.length === 0) {
            const $emptyRow = $(`
                    <tr>
                        <td colspan="7" style="text-align: center; padding: 20px; color: #999;">
                            <em>Chưa có dữ liệu</em>
                        </td>
                    </tr>
                `);
            $tbody.append($emptyRow);
            renderPagination();
            updatePageInfo();
            return;
        }

        const start = (currentPage - 1) * rowsPerPage;
        const end = start + rowsPerPage;
        const pageData = customerData.slice(start, end);

        pageData.forEach((customer, index) => {
            const stt = start + index + 1;
            let statusColor = ''text-warning'';

            if (customer.StatusName === ''Đã demo'') statusColor = ''text-success'';
            if (customer.StatusName === ''Chưa liên hệ'') statusColor = ''text-danger'';

            const fullName = customer.FullName || ''Chưa có'';
            const email = customer.Email || ''Chưa có'';
            const phone = customer.Phone || ''Chưa có'';
            const company = customer.Company || ''Chưa có'';
            const statusName = customer.StatusName || ''Chưa có'';
            const updateTime = customer.UpdateTime
                ? DevExpress.localization.formatDate(new Date(customer.UpdateTime), "HH:mm dd/MM/yyyy")
                : ''Chưa có'';

            const $row = $(`
                <tr>
                    <td>${stt}</td>
                    <td>${fullName}</td>
              <td>${email}</td>
                    <td>${phone}</td>
                    <td>${company}</td>
       <td><span class="${statusColor}">${statusName}</span></td>
        <td>${updateTime}</td>
                </tr>
            `);
            $tbody.append($row);
        });

        renderPagination();
        updatePageInfo();
    }

    function renderPagination() {
        const totalPages = Math.ceil(customerData.length / rowsPerPage);
        const $paginationEl = $(''#pagination'');
        $paginationEl.empty();

        // Previous button
        const $prevLi = $(`<li class="page-item ${currentPage === 1 ? ''disabled'' : ''''}"><a class="page-link" href="#">Previous</a></li>`);
        $prevLi.on(''click'', function (e) {
            e.preventDefault();
            if (currentPage > 1) {
                currentPage--;
                renderTable();
            }
        });
        $paginationEl.append($prevLi);

        // Page numbers
        const startPage = Math.max(1, currentPage - 2);
        const endPage = Math.min(totalPages, currentPage + 2);

        if (startPage > 1) {
            const $firstLi = $(`<li class="page-item"><a class="page-link" href="#">1</a></li>`);
            $firstLi.on(''click'', function (e) {
                e.preventDefault();
                currentPage = 1;
                renderTable();
            });
            $paginationEl.append($firstLi);

            if (startPage > 2) {
                const $dotsLi = $(`<li class="page-item disabled"><span class="page-link">...</span></li>`);
                $paginationEl.append($dotsLi);
            }
        }

        for (let i = startPage; i <= endPage; i++) {
            const $li = $(`<li class="page-item ${i === currentPage ? ''active'' : ''''}"><a class="page-link" href="#">${i}</a></li>`);
            $li.on(''click'', function (e) {
                e.preventDefault();
                currentPage = i;
                renderTable();
            });
            $paginationEl.append($li);
        }

        if (endPage < totalPages) {
            if (endPage < totalPages - 1) {
                const $dotsLi = $(`<li class="page-item disabled"><span class="page-link">...</span></li>`);
                $paginationEl.append($dotsLi);
            }

            const $lastLi = $(`<li class="page-item"><a class="page-link" href="#">${totalPages}</a></li>`);
            $lastLi.on(''click'', function (e) {
                e.preventDefault();
                currentPage = totalPages;
                renderTable();
            });
            $paginationEl.append($lastLi);
        }

        // Next button
        const $nextLi = $(`<li class="page-item ${currentPage === totalPages ? ''disabled'' : ''''}"><a class="page-link" href="#">Next</a></li>`);
        $nextLi.on(''click'', function (e) {
            e.preventDefault();
            if (currentPage < totalPages) {
                currentPage++;
                renderTable();
            }
        });
        $paginationEl.append($nextLi);
    }

    function updatePageInfo() {
        const totalPages = Math.ceil(customerData.length / rowsPerPage);
        const start = (currentPage - 1) * rowsPerPage + 1;
        const end = Math.min(currentPage * rowsPerPage, customerData.length);
        $(''#pageInfo'').text(`Showing ${start} to ${end} of ${customerData.length} customers`);
    }

    // Handle rows per page change
    $(''#rowsPerPage'').on(''change'', function () {
        rowsPerPage = parseInt($(this).val());
        currentPage = 1;
        renderTable();
    });

    // Initialize on page load
    loadMailEmployee();
    renderEmployeeKpiRanking();
    renderTable();

    // Helper function to detect mobile operating system
    function getMobileOperatingSystem() {
        const userAgent = navigator.userAgent || navigator.vendor || window.opera;

        if (/android/i.test(userAgent)) {
  return ''Android'';
        }

        if (/iPad|iPhone|iPod/.test(userAgent) && !window.MSStream) {
            return ''iOS'';
        }

        return ''unknown'';
    }

    // ========== KPI CARD CLICK HANDLERS ==========
    const kpiHandlers = {
        ''manual-email'': ''sp_KPIListEmailManual'',
        ''data-collect'': ''sp_KPIListDataCollection'',
        ''contact'': ''sp_KPIListActivityContact'',
        ''content'': ''sp_KPIContentPost'',
        ''demo'': ''sp_KPIMeetingDemo'',
        ''followup'': ''sp_KPIListDataCollection''
    };

    Object.keys(kpiHandlers).forEach(key => {
        const $card = $(`.kpi-card[data-kpi="${key}"]`);
        if ($card.length) {
            $card.off(''click'').on(''click'', function () {
                const spName = kpiHandlers[key];
                if(key == ''data-collect''){
                window.TypeKPIFilter = 1
                 window.activeStatusFilter = null
                }else if(key == ''followup''){
                window.TypeKPIFilter = 2
                window.activeStatusFilter = 3
                }
                if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
                    OpenFormParamMobile(spName);
                } else {
                    openFormParam(spName);
                }
            });
        }
    });

    $(''#manageKpiConfig'').on(''click'', function () {
        if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
            OpenFormParamMobile("sp_CRM_ListConfigKPI");
        } else {
            openFormParam("sp_CRM_ListConfigKPI");
        }
    });

    // Handle hot notification click
    $(document).on(''click'', ''#hotNotificationContent'', function () {
        const spName = ''sp_KPIProcessCustomer'';
        if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
            OpenFormParamMobile(spName);
        } else {
            openFormParam(spName);
        }
    });


    // Date filter button handlers
    const $filterType = $(''#filterType'');
    const $filterDate = $(''#filterDate'');
    const $datePickerContainer = $(''#datePickerContainer'');

    function getWeekString(date) {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        const dayNum = d.getUTCDay() || 7;
        d.setUTCDate(d.getUTCDate() + 4 - dayNum);
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        const weekNum = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
        return d.getUTCFullYear() + ''-W'' + String(weekNum).padStart(2, ''0'');
    }

    // onclick CRM_Recalculate
    $(''.CRM_Recalculate'').on(''click'', async function () {
        await reloadDashboardWithDate($(''#filterType'').val(), $(''#filterDate'').val());
    });

    function reloadDashboardWithDate(filterType, filterValue) {
        if (!filterValue) return;

        let dateRange = { start: new Date(), end: new Date() };

        if (filterType === ''day'') {
            const selectedDate = new Date(filterValue);
            dateRange = { start: selectedDate, end: selectedDate };
        } else if (filterType === ''week'') {
            const parts = filterValue.split(''-W'');
            if (parts.length !== 2) return;
            const year = parseInt(parts[0]);
            const week = parseInt(parts[1]);
            const jan4 = new Date(year, 0, 4);
            const dayOfJan4 = jan4.getDay() || 7;
            const monOfJan4 = new Date(jan4);
            monOfJan4.setDate(jan4.getDate() - dayOfJan4 + 1);
            const weekStart = new Date(monOfJan4);
            weekStart.setDate(monOfJan4.getDate() + (week - 1) * 7);
            dateRange.start = weekStart;
            dateRange.end = new Date(weekStart);
            dateRange.end.setDate(dateRange.end.getDate() + 6);
        } else if (filterType === ''month'') {
            const parts = filterValue.split(''-'');
            if (parts.length !== 2) return;
            const year = parseInt(parts[0]);
            const month = parseInt(parts[1]);
            dateRange.start = new Date(year, month - 1, 1);
     dateRange.end = new Date(year, month, 0);
        }

        if (filterType === ''week'') {
            const s = dateRange.start.toLocaleDateString(''vi-VN'', { day: ''2-digit'', month: ''2-digit'' });
            const e = dateRange.end.toLocaleDateString(''vi-VN'', { day: ''2-digit'', month: ''2-digit'' });
            $(''#weekRangeDisplay'').text(`(${s} - ${e})`).show();
        } else {
            $(''#weekRangeDisplay'').hide();
        }

        let modeview = $(''#filterType'').val();

        // Format dates using local time instead of ISO to avoid timezone offset
        const formatLocalDate = (date) => {
            return String(date.getFullYear()).padStart(4, ''0'') + ''-'' +
                String(date.getMonth() + 1).padStart(2, ''0'') + ''-'' +
                String(date.getDate()).padStart(2, ''0'');
        };

        let FromDateParam = formatLocalDate(dateRange.start);
        let ToDateParam = formatLocalDate(dateRange.end);

        // Lưu vào biến toàn cục để dùng cho openFormParam
        window.FromDateKPI = FromDateParam;
        window.ToDateKPI = ToDateParam;

        let nvkpiId = null;
        if (AccessKey === ''USER'') {
            nvkpiId = window.EmployeeID_Login || null;
        } else {
            nvkpiId = InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433?.option(''value'') || null;
        }

           window.EmployeeIDsKPI = nvkpiId;

        AjaxHPAParadise({
            data: {
                name: "sp_MailSumaryKPI",
                param: [''LoginID'', window.UserID, ''FromDate'', FromDateParam, ''ToDate'', ToDateParam, ''ViewMode'', modeview, ''EmployeeID'', nvkpiId]
            },
            success: function (data) {
                if (typeof data == "string" && !IsNullOrEmpty(data)) {
                    data = data.includes("{") ? data : EncryptionStringDecryption(data);
                }
                let dataObject = JSON.parse(data);
                console.log("Dữ liệu dataObject: ", dataObject)
                let newData = dataObject.data[0];
                if (newData && newData.length > 0) {
                    renderKPI(''manual-email'', newData[0].CurrentMailOrigin, newData[0].PreviousMailOrigin);
                    renderKPI(''data-collect'', newData[0].CurrentDataCollection, newData[0].PreviousDataCollection);
                    renderKPI(''contact'', newData[0].CurrentContactActivity, newData[0].PreviousContactActivity);
                    renderKPI(''content'', newData[0].CurrentContent, newData[0].PreviousContent);
                    renderKPI(''demo'', newData[0].CurrentMeeting, newData[0].PreviousMeeting);
                    renderKPI(''followup'', newData[0].CurrentFollowUp, newData[0].PreviousFollowUp);

                    $(''.hot-notification-glass'').text(`🔥 ${newData[0].HotNotificate || 0} %CusConsulReqs%`);

                    if (newData[0].HotNotificate && newData[0].HotNotificate > 0) {
                        $(''#hotNotificationContainer'').show();
                        // HotFromDate and HotToDate are strings from SQL (e.g., "2025-01-12T10:30:00"), not Date objects
                        let FromDateParam = newData[0].HotFromDate.split(''T'')[0];
                        let ToDateParam = newData[0].HotToDate.split(''T'')[0];
                        window.FromDateRequestCus = FromDateParam;
                        window.ToDateRequestCus = ToDateParam;
                    } else {
                        $(''#hotNotificationContainer'').hide();
                    }


                    // Update charts with real data
                    initCharts(newData[0]);
                }
                let charCol = dataObject.data[1];
                renderBarChart(charCol && charCol.length > 0 ? charCol : []);
            }
        });

        // Load employee KPI ranking data with date filter
        const formatLocalDate2 = (date) => {
     return String(date.getFullYear()).padStart(4, ''0'') + ''-'' +
                String(date.getMonth() + 1).padStart(2, ''0'') + ''-'' +
                String(date.getDate()).padStart(2, ''0'');
        };
        const FromDateStr = formatLocalDate2(dateRange.start);
        const ToDateStr = formatLocalDate2(dateRange.end);
        loadEmployeeKpiRankingData(FromDateStr, ToDateStr).then(() => {
            renderEmployeeKpiRanking();
        });

        // Load customer data with date filter
        getCusTomerRecent(FromDateStr, ToDateStr);

        customerData.forEach((cus, idx) => {
            const randomDate = new Date(dateRange.start);
            randomDate.setDate(randomDate.getDate() + Math.floor(Math.random() * 7));
            cus.date = randomDate.toISOString().split(''T'')[0];
        });
        renderTable();

        loadDashboardKpiResults();
    }

    $filterType.on(''change'', function () {
        const now = new Date();
        const type = $(this).val();
        const label = $datePickerContainer.find(''.form-label'');

        if (type === ''day'') {
            $filterDate.attr(''type'', ''date'').val(now.toISOString().split(''T'')[0]);
        } else if (type === ''week'') {
            $filterDate.attr(''type'', ''week'').val(getWeekString(now));
        } else if (type === ''month'') {
            $filterDate.attr(''type'', ''month'').val(now.getFullYear() + ''-'' + String(now.getMonth() + 1).padStart(2, ''0''));
        }
        reloadDashboardWithDate(type, $filterDate.val());
    });

    $filterDate.on(''change'', function () {
        reloadDashboardWithDate($filterType.val(), $(this).val());
    });

    // ========== INITIAL LOAD ==========
    const initialNow = new Date();
    const initialWeek = getWeekString(initialNow);

    $filterType.val(''week'');
    $filterDate.attr(''type'', ''week'');

    // Set value sau khi type attribute được áp dụng
    setTimeout(() => {
        $filterDate[0].value = initialWeek; // Dùng DOM element trực tiếp
        reloadDashboardWithDate(''week'', initialWeek);
    }, 50);

    // ========== KPI FUNCTIONS ==========
    function renderKPI(kpiKey, current, previous, isPercent = false) {
        const $card = $(`.kpi-card[data-kpi="${kpiKey}"]`);
        if ($card.length === 0) return;

        const $currentEl = $card.find(''.kpi-current'');
        const $previousEl = $card.find(''.previous'');
        const $growthEl = $card.find(''.growth'');
        const $growthValueEl = $card.find(''.growth-value'');

        let growth;

        // Xử lý trường hợp previous = 0
        if (previous === 0) {
            if (current === 0) {
                growth = 0; // Cả hai đều 0
            } else {
                growth = 999; // Hiệu số dương từ 0 (tăng từ 0)
            }
        } else {
            growth = ((current - previous) / previous * 100).toFixed(1);
        }

        $currentEl.text(isPercent ? `${current}%` : current);

        // Update only the first text node while preserving the <small> tag
        const previousValue = isPercent ? `${previous}%` : previous;
        $previousEl.contents().filter(function () {
            return this.nodeType === 3; // Text node
        }).first().replaceWith(previousValue);

        $growthEl.removeClass(''positive negative'');

        if (growth >= 0) {
            $growthEl.addClass(''positive'');
            if (growth === 999) {
                $growthValueEl.text(''Mới'');
            } else {
                $growthValueEl.text(`+${growth}%`);
            }
        } else {
            $growthEl.addClass(''negative'');
            $growthValueEl.text(`${growth}%`);
        }

    }


    // function reloadDashboard(range) {
    //     let data;
    //     console.log(''Reloading dashboard for range:'', range);
    //     if (range === ''week'') {
    //         data = { current: 86, previous: 95 };
    //     }
    //     if (range === ''month'') {
    //         data = { current: 320, previous: 290 };
    //     }
    //     if (range === ''day'') {
    //         data = { current: 12, previous: 10 };
    //     }

    //     // Update all KPI cards with demo data for each range

    //     // Update employee KPI ranking (simulate data change)
    //     // You can replace this with real logic as needed
    //     employeeKpiRankingData.forEach((emp, idx) => {
    //         emp.score = data.current + idx;
    //      emp.emails = data.current - idx;
    //         emp.calls = data.previous - idx;
    //         emp.demos = Math.max(1, Math.floor(data.current / 10) - idx);
    //         emp.followups = Math.max(1, Math.floor(data.previous / 10) - idx);
    //     });
    //     renderEmployeeKpiRanking();

    //     // Update customer list (simulate data change)
    //     customerData.forEach((cus, idx) => {
    //         cus.date = `2025-12-${Math.max(1, 28 - idx)}`;
    //     });
    //     renderTable();

    //     // Update charts (simulate data change)
    //     if (window.pieChartInstance) window.pieChartInstance.destroy();
    //     if (window.barChartInstance) window.barChartInstance.destroy();
    //     if (window.horizontalChartInstance) window.horizontalChartInstance.destroy();

    //     // Safely destroy previous chart instances if they exist
    //     if (window.pieChartInstance && typeof window.pieChartInstance.destroy === ''function'') {
    //         window.pieChartInstance.destroy();
    //         window.pieChartInstance = null;
    //     }
    //     if (window.barChartInstance && typeof window.barChartInstance.destroy === ''function'') {
    //         window.barChartInstance.destroy();
    //         window.barChartInstance = null;
    //     }
    //     if (window.horizontalChartInstance && typeof window.horizontalChartInstance.destroy === ''function'') {
    //         window.horizontalChartInstance.destroy();
    //         window.horizontalChartInstance = null;
    //     }

    //     // Create new chart instances
    //   window.pieChartInstance = new Chart($(''#pieChart'')[0].getContext(''2d''), {
    //         type: ''pie'',
    //         data: {
    //             labels: [''Emails'', ''Calls'', ''Meetings'', ''Follow-ups''],
    //             datasets: [{
    //                 data: [data.current, data.previous, data.current / 2, data.previous / 2],
    //                 backgroundColor: [''#38bdf8'', ''#34d399'', ''#f87171'', ''#fbbf24'']
    //             }]
    //         }
    //     });

    //     window.horizontalChartInstance = new Chart($(''#horizontalChart'')[0].getContext(''2d''), {
    //         type: ''bar'',
    //         data: {
    //     labels: [''Đã demo & gửi báo giá'', ''Follow-Up'', ''Thành công''],
    //             datasets: [{
    //                 label: ''Hiệu suất kinh doanh'',
    //                 data: [data.current / 2, data.previous / 2, data.current / 4],
    //                 backgroundColor: ''#38bdf8''
    //             }]
    //         },
    //         options: {
    //             indexAxis: ''y''
    //         }
    //     });
    // }

    // Hàm render chart dựa trên ChartMode
    function renderBarChart(data) {
        let mode = $(''#filterType'').val() || ''week'';

        // Destroy chart cũ nếu có
        if (window.barChartInstance) {
            window.barChartInstance.destroy();
        }

        let chartConfig = {};

        // ============================================
        // XỬ LÝ KHI DATA RỖNG
        // ============================================
        if (!data || data.length === 0) {
            if (mode === ''day'') {
                chartConfig = {
                    type: ''bar'',
                    data: {
                        labels: [''Không có dữ liệu''],
       datasets: [{
                            label: ''Emails'',
                            data: [0],
                            backgroundColor: ''#e5e7eb'',
                            borderRadius: 6
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            title: {
                                display: true,
                                text: ''Số email nhận theo ngày'',
       font: { size: 16, weight: ''bold'' }
                            }
                 },
                        scales: {
                            y: {
                                beginAtZero: true,
                                max: 10,
                                title: {
                                    display: true,
                                    text: ''Số lượng email''
                                }
                            }
                        }
                    }
                };
            } else if (mode === ''week'') {
                const dayNames = [''Mon'', ''Tue'', ''Wed'', ''Thu'', ''Fri'', ''Sat'', ''Sun''];
                chartConfig = {
                    type: ''bar'',
                    data: {
                        labels: dayNames,
                        datasets: [{
                            label: ''Emails'',
                            data: [0, 0, 0, 0, 0, 0, 0],
                            backgroundColor: dayNames.map((day, idx) => {
                                return (idx >= 5) ? ''#e5e7eb'' : ''#d1d5db'';
                            }),
                            borderRadius: 6
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            title: {
                                display: true,
                                text: ''Trung bình email theo thứ (Không có dữ liệu)'',
                                font: { size: 16, weight: ''bold'' }
                            }
                        },
                        scales: {
                            y: {
                                beginAtZero: true,
                                max: 10,
                                title: {
                                    display: true,
                                    text: ''Số lượng email''

                                }
                            },
                            x: {
                                title: {
                                    display: true,
                                    text: ''Thứ''
                                }
                            }
                        }
                    }
                };
            } else if (mode === ''month'') {
                chartConfig = {
                    type: ''bar'',
                    data: {
                        labels: [''Không có dữ liệu''],
                        datasets: [{
                            label: ''Emails'',
                            data: [0],
                            backgroundColor: ''#e5e7eb'',
                            borderRadius: 6
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: {
                            title: {
                                display: true,
                                text: ''Tổng email theo tuần'',
                                font: { size: 16, weight: ''bold'' }
                            }
                        },
                scales: {
                            y: {
                beginAtZero: true,
                                max: 10,
                                title: {
                             display: true,
                                    text: ''Số lượng email''
                                }
                            }
                        }
                    }
                };
            }

            // Tạo chart với dữ liệu rỗng
            window.barChartInstance = new Chart($(''#barChart'')[0].getContext(''2d''), chartConfig);
            return; // Dừng hàm ở đây
        }

        // ============================================
// XỬ LÝ KHI CÓ DATA
        // ============================================
        if (mode === ''day'') {
            // DATA FORMAT: { DateValue, Label, EmailCount }
            chartConfig = {
                type: ''bar'',
                data: {
                    labels: data.map(item => item.Label), // ''02/01'', ''05/01'', ...
                    datasets: [{
                        label: ''Emails'',
                        data: data.map(item => item.EmailCount),
                        backgroundColor: ''#38bdf8'',
                        borderRadius: 6
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        title: {
                            display: true,
                            text: ''Số email nhận theo ngày'',
                            font: { size: 16, weight: ''bold'' }
                        },
                        tooltip: {
                            callbacks: {
                                label: function (context) {
                                    return `Tổng: ${context.parsed.y} emails`;
                                }

                            }
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: ''Số lượng email''
                            },
                            ticks: {
                                precision: 0 // Hiển thị số nguyên
                            }
                        },
                        x: {
                            title: {
                                display: true,
                                text: ''Ngày''
                            }
                        }
                    }
                }
            };
        }
        else if (mode === ''week'') {
            // DATA FORMAT: { DayOfWeekNumber, TotalEmails, TotalDays }
            const dayNames = [''Mon'', ''Tue'', ''Wed'', ''Thu'', ''Fri'', ''Sat'', ''Sun''];
            const dayNamesVN = [''Thứ 2'', ''Thứ 3'', ''Thứ 4'', ''Thứ 5'', ''Thứ 6'', ''Thứ 7'', ''CN''];

            // Tạo mảng đầy đủ 7 ngày (0-6)
            const fullWeekData = Array(7).fill(0);
            const fullWeekDays = Array(7).fill(0);

            // Fill dữ liệu từ SQL vào đúng vị trí
            data.forEach(item => {
                // DayOfWeekNumber từ SQL: 1=Mon, 2=Tue, ..., 7=Sun
                // Chuyển sang index 0-6: 0=Mon, 1=Tue, ..., 6=Sun
                const index = parseInt(item.DayOfWeekNumber) - 1;
                fullWeekData[index] = item.TotalEmails || 0;
                fullWeekDays[index] = item.TotalDays || 0;
            });

            chartConfig = {
                type: ''bar'',
                data: {
                    labels: dayNames,
                    datasets: [{
                        label: ''Emails'',
                        data: fullWeekData,
                        backgroundColor: dayNames.map((day, idx) => {
                            return (idx >= 5) ? ''#B0E0E6'' : ''#38bdf8'';
                        }),
                        borderRadius: 6
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        title: {
                            display: true,
                            text: ''Trung bình email theo thứ'',
                            font: { size: 16, weight: ''bold'' }
                        },
                        tooltip: {
                            callbacks: {
 title: function (context) {
                                    return dayNamesVN[context[0].dataIndex];
                  },
                                label: function (context) {
                                    const idx = context.dataIndex;
                                    const totalEmails = fullWeekData[idx];
                                    const totalDays = fullWeekDays[idx];

                                    return [
                                        `Tổng: ${totalEmails} emails`,
                                    ];
                                },
                                afterLabel: function (context) {
                                    const day = dayNames[context.dataIndex];
                                    return (day === ''Sat'' || day === ''Sun'') ? ''(Cuối tuần)'' : '''';
                                }
                            }
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: ''Số lượng email''
                            },
                            ticks: {
                                precision: 0
                            }
                        },
                        x: {
                            title: {
                                display: true,
                                text: ''Thứ''
                            }
                        }
                    }
                }
            };
        }
        else if (mode === ''month'') {
            // DATA FORMAT: { Label, EmailCount, WeekInMonth, WeekStartDate, WeekEndDate }
            chartConfig = {
                type: ''bar'',
                data: {
                    labels: data.map(item => item.Label), // ''29/12 - 04/01'', ''05/01 - 11/01'', ...
                    datasets: [{
                        label: ''Emails'',
                        data: data.map(item => item.EmailCount),
                        backgroundColor: ''#38bdf8'',
                        borderRadius: 6
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        title: {
                            display: true,
                            text: ''Tổng email theo tuần'',
                            font: { size: 16, weight: ''bold'' }
                        },
                        tooltip: {
                            callbacks: {
                                label: function (context) {
                                    const item = data[context.dataIndex];
                                    return [
                                        `Tổng: ${context.parsed.y} emails`,
                                        `Tuần ${item.WeekInMonth}`,
                                        `${formatDate(item.WeekStartDate)} - ${formatDate(item.WeekEndDate)}`
                                    ];
                                }
                            }
      }
                    },
                    scales: {
                        y: {
                           beginAtZero: true,
                            title: {
               display: true,
                                text: ''Số lượng email''
                            },
                            ticks: {
                                precision: 0
                            }
                        },
                        x: {
                            title: {
                                display: true,
                                text: ''Tuần''
                            },
                  ticks: {
                                maxRotation: 45,
                                minRotation: 45
                       }
                        }
                    }
                }
            };
        }

        // Tạo chart mới
        window.barChartInstance = new Chart($(''#barChart'')[0].getContext(''2d''), chartConfig);
    }

    // Helper function để format date
    function formatDate(dateString) {
        if (!dateString) return '''';
        const date = new Date(dateString);
        const day = String(date.getDate()).padStart(2, ''0'');
        const month = String(date.getMonth() + 1).padStart(2, ''0'');
        return `${day}/${month}`;
    }

    // Chart.js: Only initialize charts once, and destroy if already exists
    function initCharts(chartData = null) {
        if (window.pieChartInstance && typeof window.pieChartInstance.destroy === ''function'') {
            window.pieChartInstance.destroy();
            window.pieChartInstance = null;
        }
        if (window.barChartInstance && typeof window.barChartInstance.destroy === ''function'') {
            window.barChartInstance.destroy();
            window.barChartInstance = null;
        }
        if (window.horizontalChartInstance && typeof window.horizontalChartInstance.destroy === ''function'') {
            window.horizontalChartInstance.destroy();
            window.horizontalChartInstance = null;
        }

        // Pie chart data from database or dummy data
        const pieLabels = [''Emails'', ''Data Collect'', ''Contact Activity'', ''Content'', ''Meetings'', ''Follow-ups''];
        let pieValues = [0, 0, 0, 0, 0, 0]; // Default dummy values

        if (chartData) {
            pieValues = [
                chartData.CurrentMailOrigin || 0,
                chartData.CurrentDataCollection || 0,
                chartData.CurrentContactActivity || 0,
                chartData.CurrentContent || 0,
                chartData.CurrentMeeting || 0,
                chartData.CurrentFollowUp || 0,
                chartData.Success || 0,
                chartData.InitialContract || 0
            ];
        }

        window.pieChartInstance = new Chart($(''#pieChart'')[0].getContext(''2d''), {
            type: ''pie'',
            data: {
                labels: pieLabels,
                datasets: [{
                    data: pieValues,
                    backgroundColor: [''#38bdf8'', ''#a855f7'', ''#34d399'', ''#ec4899'', ''#f87171'', ''#fbbf24'']
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: ''bottom'',
                        labels: {
                            color: ''#9ca3af'',
                            padding: 20,
                            font: {
                                size: 11
                            }
                        }
                    }
                }
            }
        });

        // window.barChartInstance = new Chart($(''#barChart'')[0].getContext(''2d''), {
        //     type: ''bar'',
        //     data: {
        //         labels: [''Mon'', ''Tue'', ''Wed'', ''Thu'', ''Fri'', ''Sat'', ''Sun''],
        //         datasets: [{
        //             label: ''Emails (Demo)'',
        //             data: [10, 27, 18, 33, 22, 12, 8],
//             backgroundColor: ''#38bdf8''
        //         }]
        //     },
        //     options: {
        //         responsive: true,
        //         maintainAspectRatio: false,
        //         scales: {
        //             y: {
        //                 beginAtZero: true,
        //                 ticks: { precision: 0 }
        //             }
        //         }
        //     }
        // });

        let horizontalChartData = [
            chartData.InitialContract || 0,
            chartData.CurrentFollowUp || 0,
            chartData.Success || 0,
        ]

        window.horizontalChartInstance = new Chart($(''#horizontalChart'')[0].getContext(''2d''), {
            type: ''bar'',
            data: {
                labels: [''Đã demo & gửi báo giá'', ''Follow-Up'', ''Thành công''],
                datasets: [{
                    label: ''Tình hình kinh doanh'',
                    data: horizontalChartData,
                    backgroundColor: ''#38bdf8''
                }]
            },
            options: {
                indexAxis: ''y'',
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    x: {
                        beginAtZero: true,
                        ticks: { precision: 0 }
                    }
                }
            }
        });
    }

    // Initialize charts on page load
    $(document).ready(function () {
        initCharts();

        // Recalculate button functionality
        $(''#btnRecalculate'').on(''click'', function () {
            const btn = $(this);
            const originalHtml = btn.html();

            // Show loading state
            btn.prop(''disabled'', true);
            btn.html(''<i class="fas fa-spinner fa-spin me-2"></i><span>%Loading%</span>'');

            // Simulate recalculation (replace with actual API call)
            setTimeout(function () {
                // Refresh dashboard data
                window.loadDashboardData();

                // Reset button
                btn.prop(''disabled'', false);
                btn.html(originalHtml);

                // Show success notification
                showNotification(''%RecalculateSuccess%'', ''success'');
            }, 2000);
        });
    });

    // Show notification function
    function showNotification(message, type = ''info'') {
        const alertClass = type === ''success'' ? ''alert-success'' : type === ''error'' ? ''alert-danger'' : ''alert-info'';
        const notification = $(`
                <div class="alert ${alertClass} alert-dismissible fade show position-fixed"
                     style="top: 20px; right: 20px; z-index: 9999; min-width: 300px;">
                    <i class="fas fa-${type === ''success'' ? ''check-circle'' : type === ''error'' ? ''exclamation-circle'' : ''info-circle''} me-2"></i>
                    ${message}
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            `);

        $(''body'').append(notification);

        // Auto hide after 3 seconds
        setTimeout(function () {
            notification.alert(''close'');
        }, 3000);
    }

    // ========== KPI RESULTS DASHBOARD SECTION ==========
    let dashboardKpiData = [];
    let dashboardKpiCurrentPage = 1;
    const dashboardKpiRowsPerPage = 10;
    let kpiSectionVisible = true;

    // Initialize dashboard KPI section
    $(document).ready(function () {
        setDashboardDefaultDateRange();
        loadDashboardKpiResults();
    });

    // Toggle KPI Results section
    $(''#btnToggleKPIResults'').on(''click'', function () {
        const $section = $(''#kpiResultsSection'');
        const $btn = $(this);

        if (kpiSectionVisible) {
            $section.slideUp();
            $btn.html(''<i class="fas fa-eye me-1"></i>Hiện thị'');
            kpiSectionVisible = false;
        } else {
            $section.slideDown();
            $btn.html(''<i class="fas fa-eye-slash me-1"></i>Thu gọn'');
            kpiSectionVisible = true;
        }
    });

    // Refresh KPI Results
    $(''#btnRefreshKPIResults'').on(''click'', function () {
        dashboardKpiCurrentPage = 1;
        loadDashboardKpiResults();
    });

    // Handle KPI Type filter change in Dashboard KPI Results section
    $(''#dashboardFilterKPIType'').on(''change'', function () {
        dashboardKpiCurrentPage = 1;
        loadDashboardKpiResults();
    });

    // Note: btnViewResults has been removed from UI


    // Set default date range for dashboard (current month)
    function setDashboardDefaultDateRange() {
        const now = new Date();
        const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
        const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);

        $(''#dashboardFilterFromDate'').val(firstDay.toISOString().split(''T'')[0]);
        $(''#dashboardFilterToDate'').val(lastDay.toISOString().split(''T'')[0]);
    }

    // Dashboard filter button click
    $(''#btnFilterDashboardKPI'').on(''click'', function () {
        dashboardKpiCurrentPage = 1;
        loadDashboardKpiResults();
    });

    // Load Dashboard KPI Results
    async function loadDashboardKpiResults() {
        // Nếu là USER thì sử dụng window.EmployeeID_Login, còn không thì lấy từ select
        let nvkpiId = null;
        if (AccessKey === ''USER'') {
            nvkpiId = window.EmployeeID_Login || null;
        } else {
            nvkpiId = InstanceNVKPI_IDPF21433BAA7444823B61584359F91D433?.option(''value'') || null;
        }

        // Calculate fromDate and toDate based on filterType and filterDate
        const filterType = $(''#filterType'').val();
        const filterValue = $(''#filterDate'').val();
        let fromDate = null;
        let toDate = null;

        if (filterType === ''day'') {
            const selectedDate = new Date(filterValue);
            fromDate = selectedDate.toISOString().split(''T'')[0];
            toDate = selectedDate.toISOString().split(''T'')[0];
        } else if (filterType === ''week'') {
            const parts = filterValue.split(''-W'');
            if (parts.length === 2) {
                const year = parseInt(parts[0]);
                const week = parseInt(parts[1]);
                const jan4 = new Date(year, 0, 4);
                const dayOfJan4 = jan4.getDay() || 7;
                const monOfJan4 = new Date(jan4);
                monOfJan4.setDate(jan4.getDate() - dayOfJan4 + 1);
                const weekStart = new Date(monOfJan4);
                weekStart.setDate(monOfJan4.getDate() + (week - 1) * 7);
                const weekEnd = new Date(weekStart);
                weekEnd.setDate(weekStart.getDate() + 6);
                fromDate = weekStart.toISOString().split(''T'')[0];
                toDate = weekEnd.toISOString().split(''T'')[0];
            }
        } else if (filterType === ''month'') {
            const parts = filterValue.split(''-'');
            if (parts.length === 2) {
                const year = parseInt(parts[0]);
                const month = parseInt(parts[1]);
                const monthStart = new Date(year, month - 1, 1);
                const monthEnd = new Date(year, month, 0);
                fromDate = monthStart.toISOString().split(''T'')[0];
                toDate = monthEnd.toISOString().split(''T'')[0];
            }
        }

        const kpiType = $(''#dashboardFilterKPIType'').val() || null;

        $(''#dashboardKpiLoading'').removeClass(''d-none'');
        $(''#dashboardKpiContainer'').addClass(''d-none'');
        $(''#dashboardKpiEmpty'').addClass(''d-none'');

   try {
            const response = await new Promise((resolve, reject) => {
                AjaxHPAParadise({
                    data: {
                        name: "sp_CRM_GetKPIResults",
                        param: [
                            ''NVKPI_ID'', nvkpiId,
                            ''FromDate'', fromDate,
                            ''ToDate'', toDate,
                            ''KPIType'', kpiType,
                            ''LoginID'', window.UserID,
                        ]
           },
                    success: function (data) {
                        if (typeof data == "string" && !IsNullOrEmpty(data)) {
                            data = data.includes("{") ? data : EncryptionStringDecryption(data);
                        }
                        resolve(JSON.parse(data));
                    },
                    error: reject
                });
            });

            dashboardKpiData = response.data?.[0] || [];
            renderDashboardKpiResults();

        } catch (error) {
            console.error(''Error loading dashboard KPI results:'', error);
            showNotification(''Có lỗi khi tải dữ liệu KPI!'', ''error'');
            $(''#dashboardKpiEmpty'').removeClass(''d-none'');
        } finally {
            $(''#dashboardKpiLoading'').addClass(''d-none'');
        }
    }

    // Render Dashboard KPI Results table
    function renderDashboardKpiResults() {
        const $tbody = $(''#dashboardKpiBody'');
        $tbody.empty();

        if (!dashboardKpiData || dashboardKpiData.length === 0) {
            $(''#dashboardKpiContainer'').addClass(''d-none'');
            $(''#dashboardKpiEmpty'').removeClass(''d-none'');
            $(''#dashboardKpiPaginationContainer'').addClass(''d-none'');
            return;
        }

        $(''#dashboardKpiContainer'').removeClass(''d-none'');
        $(''#dashboardKpiEmpty'').addClass(''d-none'');
        $(''#dashboardKpiPaginationContainer'').removeClass(''d-none'');

        const start = (dashboardKpiCurrentPage - 1) * dashboardKpiRowsPerPage;
        const end = start + dashboardKpiRowsPerPage;
        const pageData = dashboardKpiData.slice(start, end);

        pageData.forEach((item, index) => {
            const stt = start + index + 1;
            const periodStart = item.PeriodStart ? new Date(item.PeriodStart).toLocaleDateString(''vi-VN'') : '''';
            const periodEnd = item.PeriodEnd ? new Date(item.PeriodEnd).toLocaleDateString(''vi-VN'') : '''';
            const periodText = periodStart === periodEnd ? periodStart : `${periodStart} - ${periodEnd}`;

            const achievementPercent = parseFloat(item.Achievement_Percent || 0);
            const isAchieved = achievementPercent >= 100;

            const statusBadge = isAchieved ?
                ''<span class="badge bg-success" style="font-size: 0.7rem; padding: 2px 6px;"><i class="fas fa-check me-1" style="font-size: 0.6rem;"></i>Đạt</span>'' :
                ''<span class="badge bg-danger" style="font-size: 0.7rem; padding: 2px 6px;"><i class="fas fa-times me-1" style="font-size: 0.6rem;"></i>Chưa đạt</span>'';

            const achievementBar = `
                <div class="progress" style="height: 16px;">
                    <div class="progress-bar ${isAchieved ? ''bg-success'' : ''bg-warning''}"
                         style="width: ${Math.min(achievementPercent, 100)}%; font-size: 0.7rem; line-height: 16px;"
                         aria-valuenow="${achievementPercent}" aria-valuemin="0" aria-valuemax="100">
                        ${achievementPercent.toFixed(1)}%
                    </div>
                </div>
            `;

            const totalExp = (parseFloat(item.Total_ExperiencePoints || 0)).toLocaleString(''vi-VN'');
            const totalCoin = (parseFloat(item.Total_Coin || 0)).toLocaleString(''vi-VN'');

            const $row = $(`
      <tr class="compact-row">
                    <td class="text-center"><small><strong>${stt}</strong></small></td>
                    <td class="py-1">
                        <div class="fw-bold text-primary" style="font-size: 0.85rem; line-height: 1.2;">${item.EmployeeName || ''N/A''}</div>
                        <small class="text-muted" style="font-size: 0.7rem;">${item.NVKPI_ID}</small>
                    </td>
                    <td class="py-1">
                        <div class="fw-bold" style="font-size: 0.8rem; line-height: 1.2;">${item.KPI_Name || item.KPI_Name_EN || ''N/A''}</div>
                    </td>
<td class="text-center py-1"><span class="badge bg-secondary" style="font-size: 0.7rem; padding: 2px 6px;">${item.TimeUnit || ''N/A''}</span></td>
                    <td class="text-center py-1"><small style="font-size: 0.75rem;">${periodText}</small></td>
                    <td class="text-end py-1"><strong class="text-info" style="font-size: 0.85rem;">${parseFloat(item.KPI_Required || 0).toLocaleString(''vi-VN'')}</strong></td>
                    <td class="text-end py-1"><strong class="text-success" style="font-size: 0.85rem;">${parseFloat(item.KPI_Actual || 0).toLocaleString(''vi-VN'')}</strong></td>
                    <td class="py-1" style="min-width: 100px;">${achievementBar}</td>
                    <td class="text-center py-1">${statusBadge}</td>
                    <td class="text-end py-1">
                        <span class="text-warning fw-bold d-block" style="font-size: 0.8rem; line-height: 1;">${totalExp}</span>
                        <small class="text-muted" style="font-size: 0.65rem;">exp</small>
                    </td>
                    <td class="text-end py-1">
                        <span class="text-primary fw-bold d-block" style="font-size: 0.8rem; line-height: 1;">${totalCoin}</span>
                        <small class="text-muted" style="font-size: 0.65rem;">coin</small>
                    </td>
                </tr>
            `);

            $tbody.append($row);
        });

        renderDashboardKpiPagination();
    }

    // Render pagination for Dashboard KPI Results
    function renderDashboardKpiPagination() {
        const totalPages = Math.ceil(dashboardKpiData.length / dashboardKpiRowsPerPage);
        const $pagination = $(''#dashboardKpiPagination'');
        $pagination.empty();

        if (totalPages <= 1) {
            $(''#dashboardKpiPaginationContainer'').addClass(''d-none'');
            return;
        }

        $(''#dashboardKpiPaginationContainer'').removeClass(''d-none'');

        // Previous button
        const $prevLi = $(`<li class="page-item ${dashboardKpiCurrentPage === 1 ? ''disabled'' : ''''}"><a class="page-link" href="#">« Trước</a></li>`);
        $prevLi.on(''click'', function (e) {
            e.preventDefault();
            if (dashboardKpiCurrentPage > 1) {
                dashboardKpiCurrentPage--;
                renderDashboardKpiResults();
            }
        });
        $pagination.append($prevLi);

        // Page numbers
        const startPage = Math.max(1, dashboardKpiCurrentPage - 2);
        const endPage = Math.min(totalPages, dashboardKpiCurrentPage + 2);

        for (let i = startPage; i <= endPage; i++) {
            const $li = $(`<li class="page-item ${i === dashboardKpiCurrentPage ? ''active'' : ''''}"><a class="page-link" href="#">${i}</a></li>`);
            $li.on(''click'', function (e) {
                e.preventDefault();
                dashboardKpiCurrentPage = i;
                renderDashboardKpiResults();
            });
            $pagination.append($li);
        }

        // Next button
        const $nextLi = $(`<li class="page-item ${dashboardKpiCurrentPage === totalPages ? ''disabled'' : ''''}"><a class="page-link" href="#">Tiếp »</a></li>`);
        $nextLi.on(''click'', function (e) {
            e.preventDefault();
            if (dashboardKpiCurrentPage < totalPages) {
   dashboardKpiCurrentPage++;
                renderDashboardKpiResults();
            }
        });
        $pagination.append($nextLi);
    }

    // ========== KPI RESULTS MODAL FUNCTIONS (Keep for backward compatibility) ==========
    let kpiResultsData = [];
    let kpiResultsCurrentPage = 1;
    const kpiResultsRowsPerPage = 10;

    // Note: Modal functionality kept for backward compatibility if needed


    // Load employee options for filter
    async function loadEmployeeOptions() {
        try {
            const response = await new Promise((resolve, reject) => {
                AjaxHPAParadise({
                    data: {
                        name: "sp_EmployeeListDataMultiSelect",
                        param: [''LoginID'', window.UserID, ''LanguageID'', window.LanguageID]
                    },
                    success: function (data) {
                        if (typeof data == "string" && !IsNullOrEmpty(data)) {
                            data = data.includes("{") ? data : EncryptionStringDecryption(data);
                        }
                        resolve(JSON.parse(data));
                    },
                    error: reject
                });
            });

            const employees = response.data?.[0] || [];
            const $filterEmployee = $(''#filterEmployee'');
            $filterEmployee.empty().append(''<option value="">%AllEmployees%</option>'');

            employees.forEach(emp => {
                const empId = emp.EmployeeID || emp.ID;
                const empName = emp.FullName || emp.EmployeeName || emp.Name;
                $filterEmployee.append(`<option value="${empId}">${empName}</option>`);
            });
        } catch (error) {
            console.error(''Error loading employees:'', error);
        }
    }

    // Set default date range (current month)
    function setDefaultDateRange() {
        const now = new Date();
        const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
        const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);

        $(''#filterFromDate'').val(firstDay.toISOString().split(''T'')[0]);
        $(''#filterToDate'').val(lastDay.toISOString().split(''T'')[0]);
    }

    // Filter button click
    $(''#btnFilterKPI'').on(''click'', function () {
        kpiResultsCurrentPage = 1;
        loadKpiResults();
    });

    // Load KPI Results
    async function loadKpiResults() {
        const nvkpiId = $(''#filterEmployee'').val() || null;
        const fromDate = $(''#filterFromDate'').val() || null;
        const toDate = $(''#filterToDate'').val() || null;
        const kpiType = $(''#filterKPITypeModal'').val() || null;

        $(''#kpiResultsLoading'').removeClass(''d-none'');
        $(''#kpiResultsContainer'').addClass(''d-none'');
        $(''#kpiResultsEmpty'').addClass(''d-none'');

        try {
            const response = await new Promise((resolve, reject) => {
                AjaxHPAParadise({
                    data: {
                        name: "sp_CRM_GetKPIResults",
                        param: [
                            ''NVKPI_ID'', nvkpiId,
                            ''FromDate'', fromDate,
                            ''ToDate'', toDate,
                            ''KPIType'', kpiType
                        ]
                    },
                    success: function (data) {
                        if (typeof data == "string" && !IsNullOrEmpty(data)) {
                            data = data.includes("{") ? data : EncryptionStringDecryption(data);
                        }
                        resolve(JSON.parse(data));
                    },
                    error: reject
                });
            });

            kpiResultsData = response.data?.[0] || [];
            renderKpiResults();

    } catch (error) {
            console.error(''Error loading KPI results:'', error);
            uiManager.showAlert({ type: "error", message: "Có lỗi khi tải dữ liệu KPI!" });
            $(''#kpiResultsEmpty'').removeClass(''d-none'');
        } finally {
            $(''#kpiResultsLoading'').addClass(''d-none'');
        }
    }

    // Render KPI Results table
    function renderKpiResults() {
        const $tbody = $(''#kpiResultsBody'');
        $tbody.empty();

      if (!kpiResultsData || kpiResultsData.length === 0) {
            $(''#kpiResultsContainer'').addClass(''d-none'');
            $(''#kpiResultsEmpty'').removeClass(''d-none'');
            $(''#kpiResultsPaginationContainer'').addClass(''d-none'');
            return;
        }

        $(''#kpiResultsContainer'').removeClass(''d-none'');
        $(''#kpiResultsEmpty'').addClass(''d-none'');
        $(''#kpiResultsPaginationContainer'').removeClass(''d-none'');

        const start = (kpiResultsCurrentPage - 1) * kpiResultsRowsPerPage;
        const end = start + kpiResultsRowsPerPage;
        const pageData = kpiResultsData.slice(start, end);

        pageData.forEach((item, index) => {
            const stt = start + index + 1;
            const periodStart = item.PeriodStart ? new Date(item.PeriodStart).toLocaleDateString(''vi-VN'') : '''';
            const periodEnd = item.PeriodEnd ? new Date(item.PeriodEnd).toLocaleDateString(''vi-VN'') : '''';
            const periodText = periodStart === periodEnd ? periodStart : `${periodStart} - ${periodEnd}`;

            const achievementPercent = parseFloat(item.Achievement_Percent || 0);
            const isAchieved = achievementPercent >= 100;

            const statusBadge = isAchieved ?
                ''<span class="badge-success-custom"><i class="fas fa-check me-1"></i>Đạt</span>'' :
                ''<span class="badge-danger-custom"><i class="fas fa-times me-1"></i>Chưa đạt</span>'';

            const achievementBar = `
                <div class="achievement-bar">
                    <div class="achievement-fill" style="width: ${Math.min(achievementPercent, 100)}%"></div>
                </div>
                <small class="text-muted">${achievementPercent.toFixed(1)}%</small>
            `;

            const totalExp = (parseFloat(item.Total_ExperiencePoints || 0)).toLocaleString(''vi-VN'');
            const totalCoin = (parseFloat(item.Total_Coin || 0)).toLocaleString(''vi-VN'');

            const $row = $(`
                <tr>
                    <td><strong>${stt}</strong></td>
                    <td>
                        <div class="fw-bold text-primary">${item.EmployeeName || ''N/A''}</div>

                        <small class="text-muted">${item.NVKPI_ID}</small>
         </td>
                    <td>
                        <div class="fw-bold">${item.KPI_Name || item.KPI_Name_EN || ''N/A''}</div>
                    </td>
                    <td><span class="period-badge">${item.TimeUnit || ''N/A''}</span></td>
                    <td><small>${periodText}</small></td>
                    <td><strong class="text-info">${parseFloat(item.KPI_Required || 0).toLocaleString(''vi-VN'')}</strong></td>
                    <td><strong class="text-success">${parseFloat(item.KPI_Actual || 0).toLocaleString(''vi-VN'')}</strong></td>
                    <td>${achievementBar}</td>
                    <td>${statusBadge}</td>
                    <td>
                        <div class="text-warning fw-bold">${totalExp}</div>
                        <small class="text-muted">exp</small>
                    </td>
                    <td>
                        <div class="text-primary fw-bold">${totalCoin}</div>
                        <small class="text-muted">coin</small>
                    </td>
                    <td><small class="text-muted">${item.Notes || ''''}</small></td>
                </tr>
            `);

            $tbody.append($row);
        });

        renderKpiResultsPagination();
    }

    // Render pagination for KPI Results
    function renderKpiResultsPagination() {
        const totalPages = Math.ceil(kpiResultsData.length / kpiResultsRowsPerPage);
        const $pagination = $(''#kpiResultsPagination'');
        $pagination.empty();

        if (totalPages <= 1) return;

        // Previous button
        const $prevLi = $(`<li class="page-item ${kpiResultsCurrentPage === 1 ? ''disabled'' : ''''}"><a class="page-link" href="#">« Trước</a></li>`);
        $prevLi.on(''click'', function (e) {
            e.preventDefault();
            if (kpiResultsCurrentPage > 1) {
                kpiResultsCurrentPage--;
                renderKpiResults();
            }
        });
        $pagination.append($prevLi);

        // Page numbers
        const startPage = Math.max(1, kpiResultsCurrentPage - 2);
        const endPage = Math.min(totalPages, kpiResultsCurrentPage + 2);

        for (let i = startPage; i <= endPage; i++) {
            const $li = $(`<li class="page-item ${i === kpiResultsCurrentPage ? ''active'' : ''''}"><a class="page-link" href="#">${i}</a></li>`);
            $li.on(''click'', function (e) {
                e.preventDefault();
                kpiResultsCurrentPage = i;
                renderKpiResults();
            });
            $pagination.append($li);
        }

        // Next button
        const $nextLi = $(`<li class="page-item ${kpiResultsCurrentPage === totalPages ? ''disabled'' : ''''}"><a class="page-link" href="#">Tiếp »</a></li>`);
        $nextLi.on(''click'', function (e) {
            e.preventDefault();
            if (kpiResultsCurrentPage < totalPages) {
                kpiResultsCurrentPage++;
                renderKpiResults();
            }
        });
        $pagination.append($nextLi);
    }

    // Export to Excel (placeholder)
    $(''#btnExportKPI'').on(''click'', function () {
        if (kpiResultsData.length === 0) {
            uiManager.showAlert({ type: "warning", message: "Không có dữ liệu để xuất!" });
            return;
        }

        // TODO: Implement Excel export functionality
        uiManager.showAlert({ type: "info", message: "Tính năng xuất Excel đang phát triển..." });
    });

    })

</script>
    '

    SELECT @html AS html;
	--  exec sptblCommonControlType_Signed_Duc 'sp_CRMDashboard_html'
    -- EXEC sp_GenerateHTMLScript_new 'sp_CRMDashboard_html'
    -- EXEC sp_GenerateHTMLScript 'sp_Dashboard_Mobile_beta'
END
