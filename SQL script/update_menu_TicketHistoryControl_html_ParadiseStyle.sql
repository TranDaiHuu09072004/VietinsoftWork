CREATE OR ALTER PROCEDURE [dbo].[sp_Ticket_HistoryControl_html](
@LoginID int = 3,
@LanguageID varchar(2) = 'VN'
)
as
begin
DECLARE @html NVARCHAR(MAX);

SET @html = N'
<style>
    /* Scope all local styles under root class to prevent global pollution */
    .tk-history-control-page {
        height: 100%;
        padding-bottom: 15px;
        box-sizing: border-box;
    }

    /* Ensure text inside root element inherits body styling */
    .tk-history-control-page .text-dark {
        color: inherit !important;
    }

    /* CSS NÚT GỬI YÊU CẦU */
    .tk-history-control-page .filter-buttons {
        display: flex;
        justify-content: flex-end;
        margin-bottom: var(--paradise-space-2);
        padding-right: 5px;
    }

    /* Modal Overlay with glassmorphism */
    .tk-history-control-page #ticketModalOverlay {
        display: none;
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.4);
        backdrop-filter: blur(6px);
        -webkit-backdrop-filter: blur(6px);
        z-index: 9999;
        justify-content: center;
        align-items: center;
        transition: all 0.3s ease;
    }

    /* Modal Content premium card layout */
    .tk-history-control-page #ticketModalContent {
        max-width: 55%;
        width: 100%;
        max-height: 90vh;
        border-radius: var(--paradise-border-radius-lg);
        box-shadow: var(--paradise-shadow-lg);
        background: var(--paradise-card-bg);
        border: 1px solid var(--paradise-card-border);
        display: flex;
        flex-direction: column;
        overflow: hidden;
        animation: tk-modal-fade-in 0.3s cubic-bezier(0.16, 1, 0.3, 1);
    }

    @keyframes tk-modal-fade-in {
        from {
            opacity: 0;
            transform: scale(0.95) translateY(10px);
        }
        to {
            opacity: 1;
            transform: scale(1) translateY(0);
        }
    }

    .tk-history-control-page .modal-header {
        background: var(--paradise-bg-1);
        color: var(--paradise-color-primary);
        border-bottom: 1px solid var(--paradise-border-color);
        padding: var(--paradise-space-4);
        display: flex;
        justify-content: space-between;
        align-items: center;
        font-weight: 600;
        font-size: 16px;
    }

    /* Round close button with hover state */
    .tk-history-control-page .btn-close-modal {
        background: none;
        border: none;
        color: var(--paradise-text-muted);
        font-size: 24px;
        cursor: pointer;
        width: 32px;
        height: 32px;
        border-radius: var(--paradise-border-radius-pill);
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s;
    }

    .tk-history-control-page .btn-close-modal:hover {
        background: var(--paradise-bg-danger-subtle);
        color: var(--paradise-color-danger);
    }

    .tk-history-control-page .modal-body {
        padding: var(--paradise-space-5);
        overflow-y: auto;
        background: var(--paradise-card-bg);
    }

    /* Style inputs inside modal */
    .tk-history-control-page .modal-body .dx-texteditor {
        background-color: var(--paradise-bg-surface) !important;
        border-radius: var(--paradise-input-border-radius) !important;
        border-color: var(--paradise-border-color) !important;
    }

    .tk-history-control-page .modal-body .dx-texteditor.dx-state-focused {
        border-color: var(--paradise-color-primary) !important;
    }

    .tk-history-control-page .ticket-form-label {
        font-weight: 600;
        margin-bottom: var(--paradise-space-1);
        display: block;
        font-size: 13px;
        color: var(--paradise-text-body);
    }

    .tk-history-control-page .ticket-form-label.required::after {
        content: " *";
        color: var(--paradise-color-danger);
        font-weight: bold;
    }

    /* CSS Upload Container */
    .tk-history-control-page .upload-container {
        border: 1px dashed var(--paradise-border-color);
        background: var(--paradise-bg-surface);
        padding: var(--paradise-space-3);
        border-radius: var(--paradise-input-border-radius);
    }

    .tk-history-control-page .modal-footer {
        padding: var(--paradise-space-4);
        border-top: 1px solid var(--paradise-border-color);
        background: var(--paradise-bg-1);
        display: flex;
        justify-content: flex-end;
        gap: 10px;
    }

    /* Pill shaped status badges for GridTicket and mobile expand panel */
    .tk-history-control-page #GridTicket .badge-view,
    .tk-history-control-page .tk-expand-badge {
        text-align: center;
        padding: 4px 12px;
        border-radius: var(--paradise-border-radius-pill);
        font-weight: 500;
        font-size: 0.8rem;
        width: fit-content;
        border: 1px solid transparent;
        white-space: nowrap;
        display: inline-flex;
        align-items: center;
        gap: 0.25rem;
        transition: all 0.2s;
    }

    .tk-history-control-page .badge-view i,
    .tk-history-control-page .tk-expand-badge i {
        font-size: 0.85em;
    }

    /* Pill styles mapping to design system tokens */
    .tk-history-control-page .bg-priority-low,
    .tk-history-control-page .bg-completed,
    .tk-history-control-page .bg-success {
        background-color: var(--paradise-bg-success-subtle) !important;
        color: var(--paradise-color-success) !important;
        border-color: var(--paradise-color-success) !important;
    }

    .tk-history-control-page .bg-priority-medium,
    .tk-history-control-page .bg-pending,
    .tk-history-control-page .bg-warning {
        background-color: var(--paradise-bg-warning-subtle) !important;
        color: var(--paradise-color-warning) !important;
        border-color: var(--paradise-color-warning) !important;
    }

    .tk-history-control-page .bg-priority-high,
    .tk-history-control-page .bg-cancelled,
    .tk-history-control-page .bg-danger {
        background-color: var(--paradise-bg-danger-subtle) !important;
        color: var(--paradise-color-danger) !important;
        border-color: var(--paradise-color-danger) !important;
    }

    .tk-history-control-page .bg-priority-urgent {
        background-color: var(--paradise-color-danger) !important;
        color: #ffffff !important;
        border-color: var(--paradise-color-danger) !important;
        animation: pulse-urgent 2s infinite;
    }

    .tk-history-control-page .bg-processing,
    .tk-history-control-page .bg-primary {
        background-color: var(--paradise-bg-primary-subtle) !important;
        color: var(--paradise-color-primary) !important;
        border-color: var(--paradise-color-primary) !important;
    }

    .tk-history-control-page .bg-draft,
    .tk-history-control-page .bg-closed,
    .tk-history-control-page .bg-secondary {
        background-color: var(--paradise-bg-secondary-subtle) !important;
        color: var(--paradise-text-muted) !important;
        border-color: var(--paradise-border-color) !important;
    }

    /* Animation for urgent status */
    @keyframes pulse-urgent {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.85; }
    }

    /* DevExtreme green add button custom style using primary color token */
    .tk-history-control-page .btn-custom-green.dx-button {
        background-color: var(--paradise-color-primary) !important;
        border-color: var(--paradise-color-primary) !important;
        border-radius: var(--paradise-border-radius-pill) !important;
    }

    .tk-history-control-page .btn-custom-green.dx-button:hover {
        background-color: var(--paradise-color-primary) !important;
        opacity: 0.9 !important;
        border-color: var(--paradise-color-primary) !important;
    }

    .tk-history-control-page .btn-custom-green.dx-button:active,
    .tk-history-control-page .btn-custom-green.dx-button.dx-state-active {
        background-color: var(--paradise-color-primary) !important;
        opacity: 0.8 !important;
        border-color: var(--paradise-color-primary) !important;
    }

    .tk-history-control-page .btn-custom-green.dx-button .dx-button-text {
        color: white !important;
    }

    .tk-history-control-page .btn-custom-green.dx-button:hover .dx-button-text,
    .tk-history-control-page .btn-custom-green.dx-button:active .dx-button-text,
    .tk-history-control-page .btn-custom-green.dx-button.dx-state-active .dx-button-text {
        color: #ffffff !important;
    }

    /* Filter wrappers and grid layouts */
    .tk-history-control-page .tk-filter-wrapper {
        display: flex;
        flex-direction: row;
        align-items: center;
        gap: 6px;
        margin-left: 10px;
        white-space: nowrap;
    }

    .tk-history-control-page .tk-filter-label {
        font-size: 13px;
        font-weight: 600;
        color: var(--paradise-text-muted);
        white-space: nowrap;
    }

    .tk-history-control-page .tk-filter-box {
        width: 130px !important;
        height: 32px !important;
    }

    .tk-history-control-page .tk-filter-box.dx-selectbox {
        width: 200px !important;
    }

    .tk-history-control-page .dx-datagrid-header-panel .dx-toolbar,
    .tk-history-control-page .dx-toolbar-items-container {
        height: auto !important;
        min-height: 40px;
        display: flex !important;
        flex-wrap: wrap !important;
        justify-content: space-between;
        background-color: transparent !important;
    }

    .tk-history-control-page .dx-toolbar-before {
        display: flex !important;
        flex-direction: row !important;
        flex-wrap: wrap !important;
        align-items: center;
        position: static !important;
        max-width: 100% !important;
        flex: 1 1 auto;
        gap: 6px;
    }

    .tk-history-control-page .dx-toolbar-after {
        padding: 5px 0;
        display: flex !important;
        flex-wrap: wrap !important;
        align-items: center;
        position: static !important;
        margin-left: auto;
        gap: 4px;
    }

    /* Mobile Eye-Expand buttons & wrapper */
    .tk-history-control-page .tk-eye-btn {
        background: none;
        border: 1px solid var(--paradise-color-primary);
        border-radius: var(--paradise-border-radius-md);
        color: var(--paradise-color-primary);
        cursor: pointer;
        padding: 4px 8px;
        font-size: 16px;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .tk-history-control-page .tk-eye-btn:hover {
        background: var(--paradise-bg-primary-subtle);
    }

    .tk-history-control-page .tk-eye-btn.active {
        background: var(--paradise-color-primary);
        color: #ffffff;
    }

    .tk-history-control-page .tk-expand-wrapper {
        display: none;
        overflow: hidden;
        width: 100%;
    }

    .tk-history-control-page .tk-mobile-expand-row {
        background: var(--paradise-bg-primary-subtle);
        border-top: 1px solid var(--paradise-border-color);
        padding: 10px 14px;
        display: grid !important;
        grid-template-columns: repeat(2, 1fr) !important;
        gap: 10px 12px;
        width: 100%;
        box-sizing: border-box;
    }

    .tk-history-control-page .tk-expand-item {
        display: flex;
        flex-direction: column;
        gap: 3px;
    }

    .tk-history-control-page .tk-expand-label {
        font-size: 11px;
        color: var(--paradise-text-muted);
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.3px;
    }

    .tk-history-control-page .tk-expand-value {
        font-size: 13px;
        color: var(--paradise-text-body);
        font-weight: 500;
    }

    /* Customer badge layouts */
    .tk-history-control-page .badge-customer-internal {
        background-color: var(--paradise-bg-warning-subtle) !important;
        color: var(--paradise-color-warning) !important;
        border: 1px solid var(--paradise-color-warning) !important;
        padding: 4px 10px;
        border-radius: var(--paradise-border-radius-pill);
        font-weight: 500;
        font-size: 0.85rem;
        display: inline-flex;
        align-items: center;
        gap: 6px;
        width: fit-content;
    }

    .tk-history-control-page .badge-customer-external {
        background-color: var(--paradise-bg-success-subtle) !important;
        color: var(--paradise-color-success) !important;
        border: 1px solid var(--paradise-color-success) !important;
        padding: 4px 10px;
        border-radius: var(--paradise-border-radius-pill);
        font-weight: 500;
        font-size: 0.85rem;
        display: inline-flex;
        align-items: center;
        gap: 6px;
        width: fit-content;
    }

    /* Rating stars */
    .tk-history-control-page .star-rating-icon {
        font-size: 18px;
        transition: color 0.2s, transform 0.1s;
    }
    .tk-history-control-page .star-rating-icon.active {
        color: #ffc107 !important;
    }
    .tk-history-control-page .star-rating-icon.inactive {
        color: var(--paradise-text-muted) !important;
    }

    /* Filter buttons for mobile toggling */
    .tk-history-control-page .tk-filter-toggle-btn {
        background: var(--paradise-bg-primary-subtle);
        color: var(--paradise-color-primary);
        border: 1px solid var(--paradise-color-primary);
        border-radius: var(--paradise-border-radius-md);
        padding: 6px 10px;
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s;
    }

    .tk-history-control-page .tk-filter-toggle-btn:hover,
    .tk-history-control-page .tk-filter-toggle-btn.active {
        background: var(--paradise-color-primary);
        color: #ffffff;
    }

    .tk-history-control-page .tk-filter-clear-btn {
        color: var(--paradise-color-danger);
        background: var(--paradise-bg-danger-subtle);
        border: 1px solid var(--paradise-color-danger);
        border-radius: var(--paradise-border-radius-md);
        padding: 6px 12px;
        font-size: 12px;
        font-weight: 500;
        cursor: pointer;
        transition: all 0.2s;
    }

    .tk-history-control-page .tk-filter-clear-btn:hover {
        background: var(--paradise-color-danger);
        color: #ffffff;
    }

    /* Ticket dialog cancel & submit buttons */
    .tk-history-control-page .btn-cancel-ticket {
        background: var(--paradise-bg-secondary-subtle) !important;
        color: var(--paradise-text-muted) !important;
        border: 1px solid var(--paradise-border-color) !important;
        border-radius: var(--paradise-border-radius-pill) !important;
        padding: 8px 18px !important;
        font-weight: 500 !important;
        cursor: pointer !important;
        transition: all 0.2s !important;
    }

    .tk-history-control-page .btn-cancel-ticket:hover {
        background: var(--paradise-bg-3) !important;
        color: var(--paradise-text-body) !important;
    }

    .tk-history-control-page .btn-submit-ticket {
        background: var(--paradise-color-primary) !important;
        color: #ffffff !important;
        border: 1px solid var(--paradise-color-primary) !important;
        border-radius: var(--paradise-border-radius-pill) !important;
        padding: 8px 18px !important;
        font-weight: 500 !important;
        cursor: pointer !important;
        transition: all 0.2s !important;
    }

    .tk-history-control-page .btn-submit-ticket:hover {
        opacity: 0.9 !important;
    }

    @media (min-width: 769px) {
        .tk-history-control-page #tk-filter-panel {
            display: flex;
            flex-direction: row;
            flex-wrap: wrap;
            align-items: center;
            gap: 4px 8px;
            padding: 0 !important;
        }
        .tk-history-control-page #tk-filter-panel .tk-filter-wrapper {
            margin-left: 0;
            margin-bottom: 0;
        }
    }

    /* ===== Mobile responsive overrides ===== */
    @media (max-width: 768px) {
        .tk-history-control-page #tk-mobile-filter-panel {
            display: none;
            flex-direction: column;
            width: 100%;
            padding: 6px 8px;
            box-sizing: border-box;
        }
        .tk-history-control-page #tk-mobile-filter-panel.active {
            display: flex !important;
        }

        .tk-history-control-page .dx-toolbar-items-container {
            height: auto !important;
        }
        .tk-history-control-page .dx-toolbar-after {
            display: flex !important;
            flex-wrap: nowrap !important;
            justify-content: flex-end !important;
            align-items: center !important;
            position: static !important;
            padding: 5px 0 !important;
            gap: 6px !important;
        }

        .tk-history-control-page .dx-toolbar-before {
            display: none !important;
        }

        .tk-history-control-page .dx-toolbar-after .dx-button,
        .tk-history-control-page .tk-filter-toggle-btn {
            height: 34px !important;
            min-width: 34px !important;
            border-radius: var(--paradise-border-radius-md) !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            margin: 0 !important;
            flex-shrink: 0 !important;
        }

        .tk-history-control-page .dx-toolbar-after .dx-button .dx-button-content {
            padding: 0 !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            height: 100% !important;
        }

        .tk-history-control-page .dx-toolbar-after .dx-item:not(:first-child) .dx-button,
        .tk-history-control-page .tk-filter-toggle-btn {
            width: 36px !important;
            padding: 0 !important;
        }

        .tk-history-control-page .dx-toolbar-after .btn-custom-green {
            width: auto !important;
            padding: 0 12px !important;
        }

        .tk-history-control-page .btn-hdsd .dx-button-text {
            display: none !important;
        }
        .tk-history-control-page .btn-hdsd .dx-icon {
            margin: 0 !important;
        }

        .tk-history-control-page .dx-toolbar-after .dx-item {
            flex-shrink: 0 !important;
        }

        .tk-history-control-page #ticketModalContent {
            max-width: 95% !important;
            width: 95% !important;
        }

        .tk-history-control-page .tk-filter-wrapper {
            margin-left: 0 !important;
            margin-bottom: 6px !important;
            width: 100% !important;
            max-width: 100% !important;
            box-sizing: border-box !important;
            display: flex !important;
            padding-right: 4px !important;
        }
        .tk-history-control-page .tk-filter-box,
        .tk-history-control-page .tk-filter-box.dx-selectbox {
            flex: 1 1 0% !important;
            width: 0 !important;
            min-width: 0 !important;
        }
        .tk-history-control-page .tk-filter-label {
            min-width: 70px !important;
            max-width: 70px !important;
            flex-shrink: 0;
            font-size: 12px !important;
        }

        .tk-history-control-page .tk-filter-clear-row {
            display: flex !important;
            justify-content: flex-end !important;
            width: 100% !important;
            margin-top: 4px !important;
            padding-right: 0 !important;
        }

        .tk-history-control-page .dx-datagrid-scroll-container {
            overflow-x: hidden !important;
        }
        .tk-history-control-page .dx-datagrid-search-panel {
            width: 100% !important;
            margin: 5px 0 !important;
        }
    }
</style>

<div id="sp_Ticket_HistoryControl_html" class="tk-history-control-page">
    <div id="GridTicket" style="height: 100%;"></div>

    <div id="ticketModalOverlay">
        <div id="ticketModalContent">
            <div class="modal-header">
                <span><i class="fa fa-ticket-alt me-2"></i> %TKCreateNewTK%</span>
                <button type="button" class="btn-close-modal" onclick="window.closeTicketModal()">×</button>
            </div>

            <div class="modal-body">
                <div class="row g-3">
                    <div class="col-md-6 ">
                        <label class="ticket-form-label required">%TKCusName%</label>
                        <div id="P204298E1C9314A0582404443CBB5D8A7"></div>
                    </div>
                    <div class="col-md-6 ">
                        <label class="ticket-form-label required">%ACEmail%</label>
                        <div id="PCA74EB22EAFB4496B36C0207AE3E070B"></div>
                    </div>

                    <div class="col-md-6 ">
                        <label class="ticket-form-label">%TKDPSupport%</label>
                        <div id="P252C9FAACFA748C6BE6238266555C999"></div>
                    </div>
                    <div class="col-md-6 ">
                        <label class="ticket-form-label required">%TKEmployeeSP%</label>
                        <div id="PBCCAC0E331424C56ACC6E04F90D5B9D5"></div>
                    </div>

                    <div class="col-md-6 ">
                        <label class="ticket-form-label">%TPSPType%</label>
                        <div id="PE1E3F98AED2F407EB0710D05E3C391BE"></div>
                    </div>
                    <div class="col-md-6 ">
                        <label class="ticket-form-label">%TKPriority%</label>
                        <div id="PD96D81AC1BF3478BB8F74E08C4751659"></div>
                    </div>

                    <div class="col-12 ">
                        <label class="ticket-form-label required">%TKTitle%</label>
                        <div id="P445AB4D6127F481D840E462DF5CC093A"></div>
                    </div>

                    <div class="col-12 ">
                        <label class="ticket-form-label required">%TKRequest%</label>
                        <div id="PC3DC3952A3A148EDAF3D552490A9744D"></div>
                    </div>
                    <div class="col-12">
                        <div id="P9DC7FDC9417941169AB7D49D8E45D402"></div>
                    </div>

                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn-cancel-ticket" onclick="window.closeTicketModal()">%TKBtnCan%</button>
                <button type="button" class="btn-submit-ticket" onclick="window.submitTicket()">%TKBtnSub%</button>
            </div>
        </div>
    </div>
</div>
<script>
    (() => {
        let DataSource_EmployeeID_All = null;
        let DataSource_ServiceID_All = null;

        '
            + (select loadUI from tblCommonControlType_Signed where UID = 'PBE85F4D0401941B491282F2377C47C18')
        +(select loadUI from tblCommonControlType_Signed where UID = 'P204298E1C9314A0582404443CBB5D8A7')
        +(select loadUI from tblCommonControlType_Signed where UID = 'PCA74EB22EAFB4496B36C0207AE3E070B')
        +(select loadUI from tblCommonControlType_Signed where UID = 'P252C9FAACFA748C6BE6238266555C999')
        +(select loadUI from tblCommonControlType_Signed where UID = 'PBCCAC0E331424C56ACC6E04F90D5B9D5')
        +(select loadUI from tblCommonControlType_Signed where UID = 'PE1E3F98AED2F407EB0710D05E3C391BE')
        +(select loadUI from tblCommonControlType_Signed where UID = 'PD96D81AC1BF3478BB8F74E08C4751659')
        +(select loadUI from tblCommonControlType_Signed where UID = 'P445AB4D6127F481D840E462DF5CC093A')
        +(select loadUI from tblCommonControlType_Signed where UID = 'PC3DC3952A3A148EDAF3D552490A9744D')
        +(select loadUI from tblCommonControlType_Signed where UID = 'P9DC7FDC9417941169AB7D49D8E45D402') +N'

        // Apply hpa-no-id class to SelectBoxes in this form to hide ID in dropdowns
        $("#P204298E1C9314A0582404443CBB5D8A7, #P252C9FAACFA748C6BE6238266555C999, #PBCCAC0E331424C56ACC6E04F90D5B9D5, #PE1E3F98AED2F407EB0710D05E3C391BE, #PD96D81AC1BF3478BB8F74E08C4751659").addClass("hpa-no-id");

        window.openTicketModal = function () {
            $("#ticketModalOverlay").css("display", "flex");

            setTimeout(function () {
                console.log("🚀 START: Init Ticket Modal");

                // 1. INFO KHÁCH HÀNG
                AjaxHPAParadise({
                    data: {
                        name: "sp_Tick_GetCustomerInfo",
                        param: ["LoginID", LoginID, "LanguageID", LanguageID]
                    },
                    success: function (res) {
                        try {
                            var data = (typeof res === "string") ? JSON.parse(res) : res;
                            var info = (data.data && data.data[0]) ? data.data[0][0] : null;
                        } catch (e) { }
                    }
                });

                // 2. TẠO BẢN NHÁP
                AjaxHPAParadise({
                    data: {
                        name: "sp_Ticket_CreateDraft",
                        param: ["TicketID", 0, "LoginID", LoginID]
                    },
                    success: function (res) {
                        try {
                            var data = (typeof res === "string") ? JSON.parse(res) : res;
                            var obj = null;
                            if (data.data && data.data[0] && data.data[0][0]) obj = data.data[0][0];
                            else if (data.data && !Array.isArray(data.data[0])) obj = data.data[0];

                            if (obj) {
                                console.log("✅ Draft Loaded:", obj);
                                window.currentRecordID_TicketID = obj.TicketID;
                                window.currentRecordID_TicketHistoryID = obj.TicketID;

                                // ✅ LOAD DATA VÀO CONTROLS (PHẦN NÀY BỊ THIẾU)
                                '
                                +(select loadData from tblCommonControlType_Signed where UID = 'P204298E1C9314A0582404443CBB5D8A7')
                                +(select loadData from tblCommonControlType_Signed where UID = 'PCA74EB22EAFB4496B36C0207AE3E070B')
                                +(select loadData from tblCommonControlType_Signed where UID = 'P252C9FAACFA748C6BE6238266555C999')
                                +(select loadData from tblCommonControlType_Signed where UID = 'PD96D81AC1BF3478BB8F74E08C4751659')
                                +(select loadData from tblCommonControlType_Signed where UID = 'P445AB4D6127F481D840E462DF5CC093A')
                                +(select loadData from tblCommonControlType_Signed where UID = 'PC3DC3952A3A148EDAF3D552490A9744D')
                                +(select loadData from tblCommonControlType_Signed where UID = 'P9DC7FDC9417941169AB7D49D8E45D402') +N'


                                // ✅ SAU KHI LOAD DATA XONG → FILTER NGAY THEO DEPARTMENT CÓ SẴN

                                let currentDeptID = InstanceDepartmentIDP252C9FAACFA748C6BE6238266555C999.option("value");

                                if (currentDeptID) {
                                    window.DataSource_EmployeeID = (DataSource_EmployeeID_All || []).filter(emp => emp.DepartmentID == currentDeptID);
                                    InstanceEmployeeIDPBCCAC0E331424C56ACC6E04F90D5B9D5.option("dataSource", window.DataSource_EmployeeID);

                                    window.DataSource_ServiceID = (DataSource_ServiceID_All || []).filter(svc => svc.DepartmentID == currentDeptID || svc.DepartmentID == -1);
                                    InstanceServiceIDPE1E3F98AED2F407EB0710D05E3C391BE.option("dataSource", window.DataSource_ServiceID);
                                } else {
                                    // Chưa chọn bộ phận → chỉ hiển thị service có DepartmentID = -1
                                    window.DataSource_ServiceID = (DataSource_ServiceID_All || []).filter(svc => svc.DepartmentID == currentDeptID || svc.DepartmentID == -1);
                                    InstanceServiceIDPE1E3F98AED2F407EB0710D05E3C391BE.option("dataSource", window.DataSource_ServiceID);
                                }

                                '+   +(select loadData from tblCommonControlType_Signed where UID = 'PBCCAC0E331424C56ACC6E04F90D5B9D5')
                                +(select loadData from tblCommonControlType_Signed where UID = 'PE1E3F98AED2F407EB0710D05E3C391BE')+N'

                                setTimeout(function() {
                                    let deptID = InstanceDepartmentIDP252C9FAACFA748C6BE6238266555C999.option("value");
                                    let svcValue = InstanceServiceIDPE1E3F98AED2F407EB0710D05E3C391BE.option("value");

                                    let filteredSvc = [];
                                    if(deptID) {
                                        filteredSvc = (DataSource_ServiceID_All || []).filter(svc => svc.DepartmentID == deptID || svc.DepartmentID == -1);
                                    } else {
                                        filteredSvc = (DataSource_ServiceID_All || []).filter(svc => svc.DepartmentID == -1);
                                    }

                                    InstanceServiceIDPE1E3F98AED2F407EB0710D05E3C391BE.option("dataSource", filteredSvc);
                                    if(svcValue) {
                                        InstanceServiceIDPE1E3F98AED2F407EB0710D05E3C391BE.option("value", svcValue);
                                    }
                                }, 300);


                                // ✅ SETUP EVENT CHO LẦN SAU KHI USER CHỌN LẠI
                                InstanceDepartmentIDP252C9FAACFA748C6BE6238266555C999.off("valueChanged");
                                InstanceDepartmentIDP252C9FAACFA748C6BE6238266555C999.on("valueChanged", function (e) {
                                    if (e.value) {
                                        const selectedDeptID = e.value;
                                        console.log("🔄 Department changed to:", selectedDeptID);

                                        // Filter Employee
                                        const filteredEmployees = (DataSource_EmployeeID_All || []).filter(emp => emp.DepartmentID === selectedDeptID);
                                        InstanceEmployeeIDPBCCAC0E331424C56ACC6E04F90D5B9D5.option("dataSource", filteredEmployees);
                                        InstanceEmployeeIDPBCCAC0E331424C56ACC6E04F90D5B9D5.option("value", null); // Reset chọn


                                        // Filter Service
                                        const filteredServices = (DataSource_ServiceID_All || []).filter(svc => svc.DepartmentID === selectedDeptID || svc.DepartmentID == -1);
                                        InstanceServiceIDPE1E3F98AED2F407EB0710D05E3C391BE.option("dataSource", filteredServices);
                                        InstanceServiceIDPE1E3F98AED2F407EB0710D05E3C391BE.option("value", null); // Reset chọn

                                    } else {
                                        // Nếu bỏ chọn → reset full data

                                        InstanceEmployeeIDPBCCAC0E331424C56ACC6E04F90D5B9D5.option("dataSource", DataSource_EmployeeID_All || []);
                                        InstanceServiceIDPE1E3F98AED2F407EB0710D05E3C391BE.option("dataSource", (DataSource_ServiceID_All || []).filter(svc => svc.DepartmentID == -1));
                                        InstanceServiceIDPE1E3F98AED2F407EB0710D05E3C391BE.option("value", null);

                                    }
                                });
                            }
                        } catch (e) { console.error(e); }
                    }
                });

            }, 200);
        };

        window.closeTicketModal = function () {
            $("#ticketModalOverlay").hide();
            window.currentRecordID_TicketID = null;
            if (DataSource_EmployeeID_All) {
                window.DataSource_EmployeeID = DataSource_EmployeeID_All;
                InstanceEmployeeIDPBCCAC0E331424C56ACC6E04F90D5B9D5.option("dataSource", DataSource_EmployeeID_All);
            }

            if (DataSource_ServiceID_All) {
                // Reset về service mặc định (DepartmentID = -1)
                window.DataSource_ServiceID = DataSource_ServiceID_All.filter(svc => svc.DepartmentID == -1);
                InstanceServiceIDPE1E3F98AED2F407EB0710D05E3C391BE.option("dataSource", window.DataSource_ServiceID);
            }
        };

        window.callGuidePPTX = async function() {
            let path = ''C:/DATA/Folder có dấu Tiếng Việt/FileHuongDan/HDSD Ticket.pptx'';
            console.log("path", path);
            var aaa = `["FilePath","${path}"]`;
            console.log("aaa", aaa);
            var param = JSON.parse(aaa);

            let skeletonId = "skeleton_" + new Date().getTime();
            let skeletonHtml = `
                <div id="${skeletonId}" style="position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(var(--bs-dark-rgb), 0.5);z-index:9999;display:flex;justify-content:center;align-items:center;">
                    <div style="background: var(--bs-body-bg); padding: 20px; border-radius: 8px; text-align: center; width: 300px; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                        <div style="width: 100%; height: 15px; margin-bottom: 10px; background: var(--bs-secondary-bg); border-radius: 4px; animation: pulse-urgent 1.5s infinite;"></div>
                        <div style="width: 80%; height: 15px; margin-bottom: 15px; background: var(--bs-secondary-bg); border-radius: 4px; animation: pulse-urgent 1.5s infinite;"></div>
                        <div style="font-size: 14px; font-weight: bold; color: var(--bs-body-color);">Đang tải hướng dẫn sử dụng...</div>
                    </div>
                </div>`;
            $("body").append(skeletonHtml);

            var success = function (blob, status, xhr) {
                // Xác minh xem có phải trên thiết bị di động hay không
                var userAgent = navigator.userAgent || navigator.vendor || window.opera;
                var isMobile = /android/i.test(userAgent) || (/iPad|iPhone|iPod/.test(userAgent) && !window.MSStream);

                if (isMobile) {
                    // Trên Mobile, chuyển đổi Blob thành Base64 và sử dụng getFileQlbeta để Native App mở View file lên
                    var reader = new FileReader();
                    reader.readAsDataURL(blob);
                    reader.onloadend = function() {
                        var base64data = reader.result.split('','')[1];
                        // Truyền base64 vào function hỗ trợ view của hệ thống
                        getFileQlbeta(base64data, "HDSD Ticket.pptx", false, 1);
                    }
                } else {
                    // Trên Web, ép trình duyệt tải tệp xuống trực tiếp (vì PPTX không thể xem native trong browser iframe)
                    var newBlob = new Blob([blob], { type: "application/vnd.openxmlformats-officedocument.presentationml.presentation" });
                    var url = URL.createObjectURL(newBlob);
                    var a = document.createElement("a");
                    a.href = url;
                    a.download = "HDSD_Ticket.pptx";
                    document.body.appendChild(a);
                    a.click();
                    a.remove();
                    URL.revokeObjectURL(url);
                    uiManager.showAlert({ type: "success", message: "Đã tải xong hướng dẫn sử dụng!" });
                }
            };

            try {
                await AjaxHPAParadiseAsync({
                    data: { name: ''paradisefile_sp_GetFileAPI'', param: param },
                    xhrFields: { responseType: "blob" },
                    cache: true,
                    success: success
                });
            } catch(e) {
                uiManager.showAlert({ type: "error", message: "Không thể tải hướng dẫn sử dụng!" });
            } finally {
                $("#" + skeletonId).remove();
            }
        };

        window.deleteTicket = function (ticketID) {
            showConfirmPopup({
                title: "%TKComfirmDelete%",
                message: "%TKComfirmDelete1%",
                YesText: "%delete%",
                NoText: "%TKCancel%",
                onYes: function () {
                    AjaxHPAParadise({
                        data: {
                            name: "sp_Ticket_Delete",
                            param: ["TicketID", ticketID, "LoginID", LoginID]
                        },
                        success: function (res) {
                            uiManager.showAlert({ type: "success", message: "%TKSubSuccess%" });
                            ReloadData();
                        },
                        error: function (err) {
                            console.error(err);
                            uiManager.showAlert({ type: "error", message: "%TKSubError%" });
                        }
                    });
                }
            });
        };

        window.submitTicket = function () {
            console.log("🔍 ===== START SUBMIT TICKET =====");

            let departmentID = InstanceDepartmentIDP252C9FAACFA748C6BE6238266555C999.option("value");
            let employeeID = InstanceEmployeeIDPBCCAC0E331424C56ACC6E04F90D5B9D5.option("value");

            let subject = null;
            let description = null;

            // Thử lấy giá trị Chủ đề
            try {
                if (typeof InstanceShortDescriptionP445AB4D6127F481D840E462DF5CC093A !== "undefined") {
                    subject = InstanceShortDescriptionP445AB4D6127F481D840E462DF5CC093A.option("value");
                }
            } catch (e) {
                console.warn("Cannot get subject value:", e);
            }

            try {
                if (typeof InstanceDescriptionPC3DC3952A3A148EDAF3D552490A9744D !== "undefined") {
                    const rteInstance = InstanceDescriptionPC3DC3952A3A148EDAF3D552490A9744D;

                    console.log("🔍 RTE Instance:", rteInstance);

                    // Cách 1: Nếu là Quill instance
                    if (rteInstance && rteInstance.quill) {
                        description = rteInstance.quill.root.innerHTML;
                        console.log("✅ Got from quill.root.innerHTML:", description);
                    }
                    else if (typeof rteInstance.getHtml === "function") {
                        description = rteInstance.getHtml();
                        console.log("✅ Got from getHtml():", description);
                    }
                    else if (typeof rteInstance.getHTML === "function") {
                        description = rteInstance.getHTML();
                        console.log("✅ Got from getHTML():", description);
                    }
                    // Cách 3: Nếu có property html
                    else if (rteInstance.html) {
                        description = rteInstance.html;
                        console.log("✅ Got from .html property:", description);
                    }
                    // Cách 4: DevExtreme HtmlEditor
                    else if (typeof rteInstance.option === "function") {
                        description = rteInstance.option("value");
                        console.log("✅ Got from option(''value''):", description);
                    }
                }
            } catch (e) {
                console.warn("Cannot get description value:", e);
            }

            //Fallback: Lấy trực tiếp từ DOM
            if (!description || description === null) {
                try {
                    // Thử tìm Quill editor
                    const quillEditor = document.querySelector("#PC3DC3952A3A148EDAF3D552490A9744D .ql-editor");
                    if (quillEditor) {
                        description = quillEditor.innerHTML;
                        console.log("✅ Got from DOM .ql-editor:", description);
                    }

                    // Thử tìm textarea/div khác
                    if (!description) {
                        const container = document.querySelector("#PC3DC3952A3A148EDAF3D552490A9744D");
                        if (container) {
                            const textarea = container.querySelector("textarea");
                            const contentDiv = container.querySelector("[contenteditable=''true'']");

                            if (textarea) {
                                description = textarea.value;
                                console.log("✅ Got from textarea:", description);
                            } else if (contentDiv) {
                                description = contentDiv.innerHTML;
                                console.log("✅ Got from contenteditable div:", description);
                            }
                        }
                    }
                } catch (e) {
                    console.warn("Cannot get description from DOM:", e);
                }
            }

            console.log("📋 Current values:");
            console.log("   - DepartmentID:", departmentID);
            console.log("   - EmployeeID:", employeeID);
            console.log("   - Subject:", subject);
            console.log("   - Description:", description);

            // ✅ VALIDATION: Kiểm tra các trường bắt buộc
            if (!employeeID) {
                uiManager.showAlert({
                    type: "warning",
                    message: "%TKChooseEmWar%"
                });
                console.log("⚠️ Validation failed: EmployeeID is required");
                return;
            }

            // ✅ Validate Subject
            if (!subject || (typeof subject === "string" && subject.trim() === "")) {
                uiManager.showAlert({
                    type: "warning",
                    message: "%TKEnterSub%"
                });
                console.log("⚠️ Validation failed: Subject is required");
                return;
            }

            // ✅ Validate Description - kiểm tra cả HTML rỗng
            if (!description || description === null) {
                uiManager.showAlert({
                    type: "warning",
                    message: "%TKEnterRQDetail%"
                });
                console.log("⚠️ Validation failed: Description is null");
                return;
            }

            // Remove HTML tags để kiểm tra nội dung thực
            const textOnly = description.replace(/<[^>]*>/g, '''').trim();

            if (textOnly === "" || textOnly === "&nbsp;") {
                uiManager.showAlert({
                    type: "warning",
                    message: "%TKEnterRQDetail%"
                });
                console.log("⚠️ Validation failed: Description is empty after removing HTML");
                return;
            }

            // Nếu không chọn Department nhưng có chọn Employee
            if (!departmentID && employeeID) {
                console.log("⚠️ DepartmentID is empty but EmployeeID exists. Auto-detecting...");

                let selectedEmployee = (DataSource_EmployeeID_All || []).find(emp => emp.ID == employeeID);

                console.log("🔎 Found employee:", selectedEmployee);

                if (selectedEmployee && selectedEmployee.DepartmentID) {
                    departmentID = selectedEmployee.DepartmentID;

                    console.log("✅ Auto-set DepartmentID from Employee:", departmentID);

                    // Tự động set giá trị Department
                    InstanceDepartmentIDP252C9FAACFA748C6BE6238266555C999.option("value", departmentID);
                }
            }

            console.log("📤 Final DepartmentID before submit:", departmentID);
            console.log("🔍 ===== END SUBMIT TICKET =====");

            // Tạm ẩn popup điền yêu cầu để hiển thị popup xác nhận
            $("#ticketModalOverlay").hide();

            // Show confirmation popup
            showConfirmPopup({
                title: "%TKComfirmRequest%",
                message: `%TKComfirmRequest1%`,
                YesText: "%TkSubNow%",
                NoText: "%TKCancel%",
                onNo: () => {
                    // Nhấn hủy thì mở lại popup điền yêu cầu
                    $("#ticketModalOverlay").css("display", "flex");
                },
                onCancel: () => {
                    // Đề phòng hàm confirm gọi là onCancel
                    $("#ticketModalOverlay").css("display", "flex");
                },
                onYes: () => {
                    if (!window.currentRecordID_TicketID) {
                        uiManager.showAlert({ type: "error", message: "Lỗi: Không tìm thấy mã đơn hàng!" });
                        $("#ticketModalOverlay").css("display", "flex"); // Hiện lại nếu lỗi logic
                        return;
                    }

                    // ✅ THÊM DepartmentID VÀO PARAM
                    let submitParams = [
                        "TicketID", window.currentRecordID_TicketID,
                        "LoginID", LoginID,
                        "LanguageID", LanguageID
                    ];

                    // ✅ CHỈ THÊM DepartmentID NẾU CÓ GIÁ TRỊ
                    if (departmentID) {
                        submitParams.push("DepartmentID", departmentID);
                        console.log("✅ Submitting with DepartmentID:", departmentID);
                    }

                    AjaxHPAParadise({
                        data: {
                            name: "sp_Ticket_Submit",
                            param: submitParams
                        },
                        success: function (res) {
                            console.log("✅ Submit response:", res);
                            uiManager.showAlert({
                                type: "success",
                                message: "%TKRQSubSuc%"
                            });
                            window.closeTicketModal();
                            ReloadData();
                        },
                        error: function (err) {
                            console.error("❌ Submit error:", err);
                            uiManager.showAlert({
                                type: "error",
                                message: "%TKRQSubErr%"
                            });
                            $("#ticketModalOverlay").css("display", "flex");
                        }
                    });
                }
            });
        };

        function openDetailTicketID(TicketID) {
            if ( ["Android", "iOS"].includes(getMobileOperatingSystem())) {
                OpenFormParamMobile(`sp_Ticket_Message`, { LoginID: UserID, LanguageID: LanguageID, TicketID: TicketID });
            } else {
                openFormParam(`sp_Ticket_Message`, { LoginID: UserID, LanguageID: LanguageID, TicketID: TicketID });
            }
        }

        window.getGridConfig_GridTicket = function(dataSource) {
            return {
                remoteOperations: {
                    paging: true,
                    filtering: true,
                    sorting: true,
                    search: true
                },
                scrolling: {
                    mode: "infinite",
                    rowRenderingMode: "virtual",
                    preloadEnabled: false
                },
                paging: {
                    enabled: true,
                    pageSize: 10
                },
                pager: {
                    visible: false
                },
                customizeColumns: function(columns) {
                    // Tìm cột Status
                    const statusCol = columns.find(c =>
                        c.dataField === "TicketStatusName" ||
                        c.dataField === "StatusID" ||
                        c.caption && c.caption.includes("Trạng thái")
                    );

                    if (statusCol) {
                        statusCol.cellTemplate = function(cellElement, cellInfo) {
                            const val = cellInfo.value;

                            if (!val) {
                                $("<div>")
                                    .addClass("dx-placeholder text-center py-2")
                                    .text("--")
                                    .appendTo(cellElement);
                                return;
                            }

                            // Map StatusID hoặc StatusName sang class màu
                            let colorClass = "bg-draft"; // default

                            if (cellInfo.data.StatusID == 1 || val.includes("Nháp")) {
                                colorClass = "bg-draft";
                            } else if (cellInfo.data.StatusID == 2 || val.includes("Chờ")) {
                                colorClass = "bg-pending";
                            } else if (cellInfo.data.StatusID == 3 || val.includes("Đang xử lý")) {
                                colorClass = "bg-processing";
                            } else if (cellInfo.data.StatusID == 4 || val.includes("Hoàn thành")) {
                                colorClass = "bg-completed";
                            } else if (cellInfo.data.StatusID == 5 || val.includes("Đóng")) {
                                colorClass = "bg-closed";
                            } else if (cellInfo.data.StatusID == 6 || val.includes("Hủy")) {
                                colorClass = "bg-cancelled";
                            }

                            $("<div>")
                                .addClass("badge-view " + colorClass)
                                .text(val)
                                .appendTo(cellElement);
                        };
                    }
                }
            };
        };

        let DataSource = []

        if ("sp_GetFile" && "sp_GetFile".trim() !== "") {
            loadDataSourceCommon("FileUrl", "sp_GetFile", function (data) {
                // Data được shared qua callback
            });
        }

        // Load DataSource: sp_Ticket_GetSupportLevel
        if ("sp_Ticket_GetSupportLevel" && "sp_Ticket_GetSupportLevel".trim() !== "") {
            loadDataSourceCommon("SupportLevelID", "sp_Ticket_GetSupportLevel", function (data) {
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
            if (window[loadedKey] === true && DataSource_EmployeeID_All != null && DataSource_ServiceID_All != null) {
                if (typeof onSuccessCallback === "function") {
                    onSuccessCallback(window[dataSourceKey] || []);
                }
                return;
            }

            if (window[loadedKey] === "loading") {
                // Đợi một chút rồi thử lại
                setTimeout(function () {
                    loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback);
                }, 100);
                return;
            }

            // Đánh dấu đang load để tránh load trùng lặp
            window[loadedKey] = "loading";

            AjaxHPAParadise({
                data: {
                    name: dataSourceSP,
                    param: ["LoginID", LoginID, "LanguageID", LanguageID]
                },
                success: function (res) {
                    const json = typeof res === "string" ? JSON.parse(res) : res;

                    //Xu ly them de load data
                    if(dataSourceSP == "sp_Ticket_GetEmployee"){
                        DataSource_EmployeeID_All = (json.data && json.data[0]) || [];
                    }else if(dataSourceSP == "sp_Ticket_GetService"){
                        DataSource_ServiceID_All = (json.data && json.data[0]) || [];
                    }
                    console.log(DataSource_EmployeeID_All)
                    window[dataSourceKey] = (json.data && json.data[0]) || [];

                    // load trong form bth co combox luon
                    if (InstanceDepartmentIDP252C9FAACFA748C6BE6238266555C999.getDataSource().items().length == 0 && window["DataSource_DepartmentID"].length > 0) { InstanceDepartmentIDP252C9FAACFA748C6BE6238266555C999.option("dataSource", window["DataSource_DepartmentID"]); }

                    if (InstanceEmployeeIDPBCCAC0E331424C56ACC6E04F90D5B9D5.getDataSource().items().length == 0 && window["DataSource_EmployeeID"].length > 0) { InstanceEmployeeIDPBCCAC0E331424C56ACC6E04F90D5B9D5.option("dataSource", window["DataSource_EmployeeID"]); }
                    if (InstanceServiceIDPE1E3F98AED2F407EB0710D05E3C391BE.getDataSource().items().length == 0 && window["DataSource_ServiceID"].length > 0) { InstanceServiceIDPE1E3F98AED2F407EB0710D05E3C391BE.option("dataSource", window["DataSource_ServiceID"]); }
                    if (InstanceSupportLevelIDPD96D81AC1BF3478BB8F74E08C4751659.getDataSource().items().length == 0 && window["DataSource_SupportLevelID"].length > 0) { InstanceSupportLevelIDPD96D81AC1BF3478BB8F74E08C4751659.option("dataSource", window["DataSource_SupportLevelID"]); }


                    window[loadedKey] = true;

                    // Gọi callback nếu có
                    if (typeof onSuccessCallback === "function") {
                        onSuccessCallback(window[dataSourceKey]);
                    }

                    // Tự động cập nhật control nếu có method setDataSource hoặc option
                    // Thử nhiều format tên instance để tương thích
                    const instanceVariants = [
                        "Instance" + columnName.charAt(0).toUpperCase() + columnName.slice(1) + "PBE85F4D0401941B491282F2377C47C18",
                        "Instance" + columnName + "PBE85F4D0401941B491282F2377C47C18",
                        "instance" + columnName.charAt(0).toUpperCase() + columnName.slice(1) + "PBE85F4D0401941B491282F2377C47C18"
                    ];

                    for (let i = 0; i < instanceVariants.length; i++) {
                        const instanceKey = instanceVariants[i];

                        if (window[instanceKey] || instanceKey) {
                            const instanceObj = window[instanceKey] || instanceKey;


                            // Kiểm tra nếu đây là dxDataGrid
                            if (typeof instanceObj.dxDataGrid === "function" || instanceObj.option && instanceObj.option("dataSource") !== undefined) {
                                try {
                                    // Nếu là Grid, apply dynamic config
                                    const gridConfigFn = window["getGridConfig_" + columnName.charAt(0).toUpperCase() + columnName.slice(1)];
                                    if (typeof gridConfigFn === "function") {
                                        const gridConfig = gridConfigFn(window[dataSourceKey]);
                                        instanceObj.option("remoteOperations", gridConfig.remoteOperations);
                                        instanceObj.option("paging.pageSize", gridConfig.pageSize);
                                        instanceObj.option("pager.allowedPageSizes", gridConfig.allowedPageSizes);
                                    }

                                    instanceObj.option("dataSource", window[dataSourceKey]);
                                    break;
                                } catch (e) {
                                    console.warn("[LoadDataSourceCommon] Grid config error:", e);
                                    // Fallback: just set data source
                                    instanceObj.option("dataSource", window[dataSourceKey]);
                                    break;
                                }
                            } else if (typeof instanceObj.setDataSource === "function") {
                                instanceObj.setDataSource(window[dataSourceKey]);
                                break;
                            } else if (typeof instanceObj.option === "function") {
                                try {
                                    instanceObj.option("dataSource", window[dataSourceKey]);
                                    break;
                                } catch (e) {
                                    // Continue to next variant
                                }
                            }
                        }
                    }
                },
                error: function (err) {
                    console.error("[loadDataSourceCommon] Failed to load datasource for", columnName, ":", err);
                    window[loadedKey] = false;
                    if (typeof onSuccessCallback === "function") {
                        onSuccessCallback([]);
                    }
                }
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
                    .dx-datagrid-rowsview .dx-row > td > div { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; line-height: 1.4 !important; }

                    /* --- Search Styles --- */
                    .dx-datagrid-search-panel .dx-placeholder { display: none !important; }
                    .dx-datagrid-search-panel input:not(:placeholder-shown) { color: #1a1a1a !important; }

                    /* --- Avatar & Chip Styles --- */
                    .hpa-avatar-group { display: flex; alignItems: center; }
                    .hpa-avatar { border: 2px solid #fff; box-shadow: 0 2px 4px rgba(0,0,0,0.1); object-fit: cover; }
                `)
                .appendTo("head");
        }

        window.hpaUtils = window.hpaUtils || {
            removeToneMarks: function(str) {
                if (!str) return "";
                return RemoveToneMarks_Js(str);
            },
            highlightText: function(text, search) {
                if (!search || !text) return text;
                const regex = new RegExp("(" + search.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + ")", "gi");
                return text.replace(regex, "<mark class=\"bg-warning fw-bold px-1 rounded\">$1</mark>");
            },
            getInitials: function(name) {
                if (!name) return "?";
                const words = name.trim().split(/\s+/);
                if (words.length >= 2) return (words[0][0] + words[words.length - 1][0]).toUpperCase();
                return name.substring(0, 2).toUpperCase();
            },
            getColorForId: function(id) {
                const colors = [
                    { bg: "#e3f2fd", text: "#1976d2" },
                    { bg: "#f3e5f5", text: "#7b1fa2" },
                    { bg: "#e8f5e9", text: "#388e3c" },
                    { bg: "#fff3e0", text: "#f57c00" },
                    { bg: "#fce4ec", text: "#c2185b" }
                ];
                return colors[Math.abs(id) % colors.length];
            },
            loadAvatar: function(employeeId, storeImgName, paramImg, callbackFn) {
                window.GlobalEmployeeAvatarCache = window.GlobalEmployeeAvatarCache || {};
                window.GlobalEmployeeAvatarLoading = window.GlobalEmployeeAvatarLoading || {};

                const idStr = String(employeeId);
                if (window.GlobalEmployeeAvatarCache[idStr]) {
                    if (callbackFn) callbackFn(window.GlobalEmployeeAvatarCache[idStr]);
                    return window.GlobalEmployeeAvatarCache[idStr];
                }

                if (window.GlobalEmployeeAvatarLoading[idStr]) {
                    if (callbackFn) {
                        window.GlobalEmployeeAvatarLoading[idStr].callbacks = window.GlobalEmployeeAvatarLoading[idStr].callbacks || [];
                        window.GlobalEmployeeAvatarLoading[idStr].callbacks.push(callbackFn);
                    }
                    return null;
                }

                if (!storeImgName) return null;

                window.GlobalEmployeeAvatarLoading[idStr] = { loading: true, callbacks: callbackFn ? [callbackFn] : [] };

                let paramArray = [];
                if (paramImg) {
                    try { paramArray = JSON.parse(decodeURIComponent(paramImg)); } catch (e) { paramArray = []; }
                }

                AjaxHPAParadise({
                    data: { name: storeImgName, param: paramArray },
                    xhrFields: { responseType: "blob" },
                    cache: true,
                    success: function (blob) {
                        const callbacks = window.GlobalEmployeeAvatarLoading[idStr]?.callbacks || [];
                        delete window.GlobalEmployeeAvatarLoading[idStr];
                        if (blob && blob.size > 0) {
                            const url = URL.createObjectURL(blob);
                            window.GlobalEmployeeAvatarCache[idStr] = url;
                            callbacks.forEach(cb => { try { cb(url); } catch (e) {} });
                        } else {
                            callbacks.forEach(cb => { try { cb(null); } catch (e) {} });
                        }
                    },
                    error: function () {
                        const callbacks = window.GlobalEmployeeAvatarLoading[idStr]?.callbacks || [];
                        delete window.GlobalEmployeeAvatarLoading[idStr];
                        callbacks.forEach(cb => { try { cb(null); } catch (e) {} });
                    }
                });
                return null;
            }
        };

        window.ValidationEngine = window.ValidationEngine || {
            getRequiredMessage: function(displayName) {
                return "không được để trống " + (displayName || "trường này");
            }
        };
        window.currentRecordID_CRM_CustomerID = null; window.currentRecordID_TicketID = null;
        function applyGridFilters() {
            const gridInstance = InstanceGridTicketPBE85F4D0401941B491282F2377C47C18;
            if (!gridInstance) return;

            // When using CustomStore, filtering is handled server-side during load()
            gridInstance.refresh();
            console.log("🔍 Filter applied (Refresh custom store):", window.currentFilters);
        }
        // Helper: build distinct employee list, filter theo companyID nếu có
        function _buildDistinctEmployee(companyID) {
            var raw = window._ticketEmployeeListFull || [];
            var empMap = new Map();
            raw.forEach(function(item) {
                if (!item.EmployeeName) return;
                // Nếu có filter company → chỉ lấy employee của company đó
                if (companyID && item.CompanyID != companyID) return;
                if (!empMap.has(item.EmployeeName)) {
                    empMap.set(item.EmployeeName, { EmployeeName: item.EmployeeName });
                }
            });
            return Array.from(empMap.values())
                .sort((a, b) => a.EmployeeName.localeCompare(b.EmployeeName));
        }
        function ReloadData() {
            // Load DataSource: sp_Ticket_GetDepartment
            if ("sp_Ticket_GetDepartment" && "sp_Ticket_GetDepartment".trim() !== "") {
                loadDataSourceCommon("DepartmentID", "sp_Ticket_GetDepartment", function (data) {
                    // Data được shared qua callback
                });
            }

            // Load DataSource: sp_Ticket_GetEmployee
            if ("sp_Ticket_GetEmployee" && "sp_Ticket_GetEmployee".trim() !== "") {
                loadDataSourceCommon("EmployeeID", "sp_Ticket_GetEmployee", function (data) {
                    // Data được shared qua callback
                });
            }

            // Load DataSource: sp_Ticket_GetService
            if ("sp_Ticket_GetService" && "sp_Ticket_GetService".trim() !== "") {
                loadDataSourceCommon("ServiceID", "sp_Ticket_GetService", function (data) {
                    // Data được shared qua callback
                });
            }

            const gridInstance = InstanceGridTicketPBE85F4D0401941B491282F2377C47C18;
            const isInitialized = gridInstance.option("dataSource") instanceof DevExpress.data.CustomStore;

            if (isInitialized) {
                gridInstance.refresh();
                return;
            }

            let dataStore_GridTicket = new DevExpress.data.CustomStore({
                key: "TicketID",
                load: function (loadOptions) {
                    const deferred = $.Deferred();

                    let params = [];
                    let skip = loadOptions.skip || 0;
                    let take = loadOptions.take || 50;

                    // Build params for sp_LoadGridUsingAPI
                    params.push("@ProcName", "spTicket_apiGetInfomationTicketUser");

                    let procParam = "";
                    procParam += `@LoginID=${LoginID}`;
                    procParam += `,@Language=''${LanguageID}''`;

                    if (window.currentFilters) {
                        if (window.currentFilters.companyID) {
                            procParam += `,@CompanyID=${window.currentFilters.companyID}`;
                        }
                        if (window.currentFilters.employeeName) {
                            procParam += `,@EmployeeName=N''${window.currentFilters.employeeName}''`;
                        }
                        if (window.currentFilters.fromDate) {
                            let fd = new Date(window.currentFilters.fromDate);
                            const fdStr = fd.getFullYear() + ''-''
                                + (''0''+(fd.getMonth()+1)).slice(-2) + ''-''
                                + (''0''+fd.getDate()).slice(-2);
                            procParam += `,@FromDate=''${fdStr}''`;
                        }
                        if (window.currentFilters.toDate) {
                            let td = new Date(window.currentFilters.toDate);
                            const tdStr = td.getFullYear() + ''-''
                                + (''0''+(td.getMonth()+1)).slice(-2) + ''-''
                                + (''0''+td.getDate()).slice(-2);
                            procParam += `,@ToDate=''${tdStr}''`;
                        }
                    }
                    params.push("@ProcParam", procParam);

                    // Phân trang
                    params.push("@Take", take);
                    params.push("@Skip", skip);

                    // TotalCount
                    if (loadOptions.requireTotalCount) {
                        params.push("@RequireTotalCount", 1);
                    } else {
                        params.push("@RequireTotalCount", 1); // Always ask for TotalCount just in case for infinite
                    }

                    // Search
                    let _currentKeyword = (gridInstance.option("searchPanel.text") || "").trim();
                    if (_currentKeyword) {
                        params.push("@SearchValue", _currentKeyword);
                        params.push("@ColumnSearch", "ShortDescription,FullNameUser,FullNameEmployee,TicketStatusName,LevelName");
                    }

                    if (loadOptions.filter) {
                        const hasFunction = JSON.stringify(loadOptions.filter, (key, val) => {
                            if (typeof val === ''function'') return ''FUNCTION'';
                            return val;
                        }).includes(''FUNCTION'');

                        if (!hasFunction && typeof createConditionQuery === ''function'') {
                            params.push("@Filters", createConditionQuery(loadOptions.filter));
                        }
                    }

                    let sort = loadOptions.sort
                        ? loadOptions.sort.map(s => s.selector + (s.desc ? " DESC" : " ASC")).join(",")
                        : "CreatedDate DESC";
                    params.push("@Sort", "ORDER BY " + sort);

                    AjaxHPAParadise({
                        data: {
                            name: "sp_LoadGridUsingAPI",
                            param: params
                        },
                        success: function (res) {
                            const json = typeof res === "string" ? JSON.parse(res) : res;
                            const results = Array.isArray(json?.data?.[0]) ? json.data[0] : [];

                            let result = { data: results };
                            result.totalCount = json?.data?.[1]?.[0]?.TotalCount ?? 0;

                            if (skip === 0) {
                                DataSource = results.length > 0 ? results : [];

                                // Build distinct company list
                                var compMap = new Map();
                                results.forEach(function(item) {
                                    if (item.Company && item.CRM_CompanyID && !compMap.has(item.CRM_CompanyID)) {
                                        compMap.set(item.CRM_CompanyID, {
                                            CompanyID: item.CRM_CompanyID,
                                            CompanyName: item.Company
                                        });
                                    }
                                });
                                window._ticketCompanyListFull = Array.from(compMap.values()).sort((a, b) => (a.CompanyName||"").localeCompare(b.CompanyName||""));

                                // Build employee list raw — mỗi dòng giữ CompanyID = FullNameUser
                                var empArr = [];
                                results.forEach(function(item) {
                                    if (item.FullNameEmployee) {
                                        empArr.push({
                                            EmployeeName: item.FullNameEmployee,
                                            CompanyID: item.FullNameUser  // liên kết theo FullNameUser
                                        });
                                    }
                                });
                                window._ticketEmployeeListFull = empArr;

                                // Đổ vào selectbox nếu đã khởi tạo rồi
                                if (window.FilterCompanyInstance) {
                                    window.FilterCompanyInstance.option("dataSource", window._ticketCompanyListFull);
                                }
                                if (window.FilterEmployeeInstance) {
                                    // Distinct employee toàn bộ
                                    window.FilterEmployeeInstance.option("dataSource",
                                        _buildDistinctEmployee(null));
                                }
                            }

                            deferred.resolve(result);
                        }
                    });

                    return deferred.promise();
                }
            });

            window.dataStore_GridTicket = dataStore_GridTicket;
            const gridConfig = window.getGridConfig_GridTicket([]);

            gridInstance.beginUpdate();

            // Hàm khởi tạo DevExpress filter controls (dùng chung)
            window._initFilterControls = function() {
                window.FilterCompanyInstance = $("#FilterCompany").dxSelectBox({
                    dataSource: window._ticketCompanyListFull || [],
                    displayExpr: "CompanyName",
                    valueExpr: "CompanyID",
                    width: "100%",
                    dropDownOptions: { width: "auto", minWidth: 250 },
                    placeholder: "%TKAllCompany%",
                    showClearButton: true,
                    searchEnabled: true,
                    onValueChanged: function(ev) {
                        window.currentFilters = window.currentFilters || {};
                        window.currentFilters.companyID = ev.value || null;
                        var empList = _buildDistinctEmployee(ev.value);
                        if (window.FilterEmployeeInstance) {
                            window.FilterEmployeeInstance.option("dataSource", empList);
                            window.FilterEmployeeInstance.option("value", null);
                            window.currentFilters.employeeName = null;
                        }
                        applyGridFilters();
                    }
                }).dxSelectBox("instance");

                window.FilterEmployeeInstance = $("#FilterEmployee").dxSelectBox({
                    dataSource: _buildDistinctEmployee(null),
                    displayExpr: "EmployeeName",
                    valueExpr: "EmployeeName",
                    width: "100%",
                    dropDownOptions: { width: "auto", minWidth: 250 },
                    placeholder: "%TKAll%",
                    showClearButton: true,
                    searchEnabled: true,
                    onValueChanged: function(ev) {
                        window.currentFilters = window.currentFilters || {};
                        window.currentFilters.employeeName = ev.value || null;
                        applyGridFilters();
                    }
                }).dxSelectBox("instance");

                window.FilterFromDateInstance = $("#FilterFromDate").dxDateBox({
                    displayFormat: "dd/MM/yyyy",
                    placeholder: "%TKChoose%",
                    showClearButton: true,
                    width: "100%",
                    onValueChanged: function(ev) {
                        window.currentFilters = window.currentFilters || {};
                        window.currentFilters.fromDate = ev.value || null;
                        applyGridFilters();
                    }
                }).dxDateBox("instance");

                window.FilterToDateInstance = $("#FilterToDate").dxDateBox({
                    displayFormat: "dd/MM/yyyy",
                    placeholder: "%TKChoose%",
                    showClearButton: true,
                    width: "100%",
                    onValueChanged: function(ev) {
                        window.currentFilters = window.currentFilters || {};
                        window.currentFilters.toDate = ev.value || null;
                        applyGridFilters();
                    }
                }).dxDateBox("instance");

                if (window._ticketCompanyListFull && window._ticketCompanyListFull.length > 0) {
                    window.FilterCompanyInstance.option("dataSource", window._ticketCompanyListFull);
                }
                if (window._ticketEmployeeListFull && window._ticketEmployeeListFull.length > 0) {
                    window.FilterEmployeeInstance.option("dataSource", _buildDistinctEmployee(null));
                }
            };

            // ===== THAY TOÀN BỘ PHẦN onToolbarPreparing =====
            gridInstance.option("onToolbarPreparing", function(e) {
                var isMobileView = window.innerWidth <= 768;

                // ===== DESKTOP: filter trong toolbar =====
                // ===== MOBILE: filter tách ra ngoài toolbar =====
                if (!isMobileView) {
                    e.toolbarOptions.items.unshift({
                        location: "before",
                        template: function() {
                            const $wrapper = $("<div>")
                                .attr("id", "tk-filter-panel-wrapper")
                                .css({ display: "flex", flexWrap: "wrap", alignItems: "center", gap: "6px", width: "100%" });

                            const $filterPanel = $("<div>")
                                .attr("id", "tk-filter-panel")
                                .css({ display: "flex", flexWrap: "wrap", alignItems: "center", gap: "6px" })
                                .appendTo($wrapper);

                            var $r1 = $("<div>").addClass("tk-filter-wrapper").appendTo($filterPanel);
                            $("<span>").addClass("tk-filter-label").text("%TCCompany%").appendTo($r1);
                            $("<div>").addClass("tk-filter-box").attr("id", "FilterCompany").appendTo($r1);

                            var $r2 = $("<div>").addClass("tk-filter-wrapper").appendTo($filterPanel);
                            $("<span>").addClass("tk-filter-label").text("%TCEmployee%").appendTo($r2);
                            $("<div>").addClass("tk-filter-box").attr("id", "FilterEmployee").appendTo($r2);

                            var $r3 = $("<div>").addClass("tk-filter-wrapper").appendTo($filterPanel);
                            $("<span>").addClass("tk-filter-label").text("%TKFromDate%").appendTo($r3);
                            $("<div>").addClass("tk-filter-box").attr("id", "FilterFromDate").appendTo($r3);

                            var $r4 = $("<div>").addClass("tk-filter-wrapper").appendTo($filterPanel);
                            $("<span>").addClass("tk-filter-label").text("%TKToDate%").appendTo($r4);
                            $("<div>").addClass("tk-filter-box").attr("id", "FilterToDate").appendTo($r4);

                            setTimeout(function() { window._initFilterControls(); }, 300);
                            return $wrapper;
                        }
                    });
                }

                // Nút toggle filter - CHỈ MOBILE
                if (isMobileView) {
                    e.toolbarOptions.items.unshift({
                        location: "after",
                        template: function() {
                            var $btn = $("<button>")
                                .addClass("tk-filter-toggle-btn")
                                .html(''<i class="bi bi-funnel-fill"></i>'');

                            $btn.on("click", function() {
                                var $panel = $("#tk-mobile-filter-panel");
                                var $thisBtn = $(this);
                                $thisBtn.toggleClass("active");
                                if ($panel.hasClass("active")) {
                                    $panel.slideUp(300, function() { $panel.removeClass("active"); });
                                } else {
                                    $panel.addClass("active").hide().slideDown(300, function() {
                                        if (window.FilterCompanyInstance) window.FilterCompanyInstance.repaint();
                                        if (window.FilterEmployeeInstance) window.FilterEmployeeInstance.repaint();
                                        if (window.FilterFromDateInstance) window.FilterFromDateInstance.repaint();
                                        if (window.FilterToDateInstance) window.FilterToDateInstance.repaint();
                                    });
                                }
                            });
                            return $btn;
                        }
                    });
                }

                // Nút Refresh
                e.toolbarOptions.items.unshift({
                    location: "after",
                    widget: "dxButton",
                    options: {
                        icon: "refresh",
                        type: "default",
                        stylingMode: "contained",
                        hint: "Tải lại dữ liệu",
                        onClick: function() {
                            window.currentFilters = {};
                            ReloadData();
                            uiManager.showAlert({ type: "success", message: "%TKReloadSuc%" });
                        }
                    }
                });


                // Nút Tạo mới
                e.toolbarOptions.items.unshift({
                    location: "after",
                    widget: "dxButton",
                    options: {
                        text: "%TkAddNewTK%",
                        type: "default",
                        stylingMode: "contained",
                        hint: "Tạo yêu cầu hỗ trợ mới",
                        elementAttr: { class: "btn-custom-green" },
                        onClick: function() { window.openTicketModal(); }
                    }
                });
            });
            gridInstance.option("customizeColumns", function(columns) {
                // ===== MOBILE: Dùng visible: false để DevExtreme thực sự loại cột khỏi layout =====
                const isMobile = window.innerWidth <= 768;
                const colsToHideOnMobile = ["CreatedDate", "TicketStatusName", "LevelName", "FullNameUser"];
                columns.forEach(c => {
                    if (colsToHideOnMobile.includes(c.dataField)) {
                        c.visible = !isMobile;
                    }
                });

                const customerCol = columns.find(c => c.dataField === "FullNameUser");
                if (customerCol) {
                    customerCol.cellTemplate = function(cellElement, cellInfo) {
                        const isInternal = cellInfo.data.IsInternalTicket;
                        const customerName = cellInfo.value;

                        if (!customerName) {
                            $("<div>")
                                .addClass("dx-placeholder text-center py-2")
                                .text("--")
                                .appendTo(cellElement);
                            return;
                        }

                        const customerClass = isInternal === true ? "badge-customer-internal" : "badge-customer-external";
                        const icon = isInternal === true ? "bi-person-workspace" : "bi-person-check";

                        $("<div>")
                            .addClass(customerClass)
                            .html(`<i class="bi ${icon}"></i>${customerName}`)
                            .appendTo(cellElement);
                    };
                }
                const dateCol = columns.find(c => c.dataField === "CreatedDate");
                if (dateCol) {

                    dateCol.dataType = "string";
                    dateCol.alignment = "center";
                    dateCol.width = 150;

                    dateCol.customizeText = function(cellInfo) {
                        if (!cellInfo.value) return "";
                        const dateStr = cellInfo.value;
                        if (typeof dateStr === "string" && dateStr.includes("T")) {
                            const match = dateStr.match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/);
                            if (match) {
                                return `${match[3]}/${match[2]}/${match[1]} ${match[4]}:${match[5]}`;
                            }
                        }
                        return dateStr;
                    };
                }

                const priorityCol = columns.find(c => c.dataField === "LevelName");

                if (priorityCol) {
                    priorityCol.cellTemplate = function(cellElement, cellInfo) {
                        const val = cellInfo.value;

                        if (!val) {
                            $("<div>")
                                .addClass("dx-placeholder text-center py-2")
                                .text("--")
                                .appendTo(cellElement);
                            return;
                        }

                        let bootstrapClass = "";
                        let icon = "";

                        // Thấp = Xanh lá (success)
                        if (val.includes("Thấp") || val.includes("Low")) {
                            bootstrapClass = "bg-success";
                            icon = "bi-arrow-down-circle";
                        }
                        // Trung bình = Vàng (warning)
                        else if (val.includes("Trung bình") || val.includes("Medium") || val.includes("Normal")) {
                            bootstrapClass = "bg-warning";
                            icon = "bi-dash-circle";
                        }
                        // Khẩn cấp = Đỏ đặc biệt (pulse)
                        else if (val.includes("Khẩn cấp") || val.includes("Urgent")) {
                            bootstrapClass = "bg-priority-urgent";
                            icon = "bi-exclamation-triangle-fill";
                        }
                        // Cao = Đỏ (danger)
                        else if (val.includes("Cao") || val.includes("High")) {
                            bootstrapClass = "bg-danger";
                            icon = "bi-arrow-up-circle";
                        }
                        else {
                            bootstrapClass = "bg-secondary";
                            icon = "bi-question-circle";
                        }

                        $("<div>")
                            .addClass("badge-view " + bootstrapClass)
                            .html(`<i class="bi ${icon} me-1"></i>${val}`)
                            .appendTo(cellElement);
                    };
                }

                const statusCol = columns.find(c => c.dataField === "TicketStatusName");

                if (statusCol) {
                    statusCol.cellTemplate = function(cellElement, cellInfo) {
                        const val = cellInfo.value;
                        const statusID = cellInfo.data.StatusID;

                        if (!val) {
                            $("<div>")
                                .addClass("dx-placeholder text-center py-2")
                                .text("--")
                                .appendTo(cellElement);
                            return;
                        }

                        let bootstrapClass = "";
                        let icon = "";

                        // Chưa xác nhận = Vàng (warning)
                        if (statusID === 0) {
                            bootstrapClass = "bg-warning";
                            icon = "bi-file-earmark";
                        }
                        // Đang xử lý = Xanh dương (primary)
                        else if (statusID === 1) {
                            bootstrapClass = "bg-primary";
                            icon = "bi-gear-fill";
                        }
                        // Hoàn thành = Xanh lá (success)
                        else if (statusID === 2) {
                            bootstrapClass = "bg-success";
                            icon = "bi-check-circle-fill";
                        }
                        // Đã đóng = Xám (secondary)
                        else if (statusID === 3) {
                            bootstrapClass = "bg-secondary";
                            icon = "bi-lock-fill";
                        }
                        // Hủy = Đỏ (danger)
                        else if (statusID === 4) {
                            bootstrapClass = "bg-danger";
                            icon = "bi-x-circle-fill";
                        }
                        // Chờ xử lý = Vàng (warning)
                        else if (val.includes("Chờ") || val.includes("Pending") || val.includes("Waiting")) {
                            bootstrapClass = "bg-warning";
                            icon = "bi-clock-history";
                        }
                        else {
                            bootstrapClass = "bg-secondary";
                            icon = "bi-circle";
                        }

                        $("<div>")
                            .addClass("badge-view " + bootstrapClass)
                            .html(`<i class="bi ${icon} me-1"></i>${val}`)
                            .appendTo(cellElement);
                    };
                }
                if (!columns.find(c => c.name === "RatingColumn")) {
                    columns.push({
                        name: "RatingColumn",
                        caption: "%TKRating%",
                        width: 150,
                        alignment: "center",
                        allowFiltering: false,
                        allowSorting: false,
                        visible: !isMobile,
                        cellTemplate: function (container, options) {
                            const currentRating = options.data.Rating || 0;
                            const ticketID = options.data.TicketID;
                            const statusID = options.data.StatusID;

                            const ticketCreatorID = options.data.CRM_CustomerID;
                            const currentUserCRM_ID = options.data.CurrentUserCRM_CustomerID;
                            const isTicketCreator = ticketCreatorID && currentUserCRM_ID &&
                            ticketCreatorID.toString() === currentUserCRM_ID.toString();

                            const isTicketClosed = statusID === 3;
                            const canRate = isTicketCreator && isTicketClosed;

                            const $ratingContainer = $("<div/>")
                                .css({
                                    display: "flex",
                                    gap: "4px",
                                    justifyContent: "center",
                                    cursor: canRate ? "pointer" : "not-allowed",
                                    opacity: canRate ? 1 : 0.5
                                })
                                .appendTo(container);

                            // Function để update hiển thị sao sử dụng class CSS thay vì inline color
                            function updateStars(rating) {
                                $ratingContainer.find(".star-rating-icon").each(function(idx) {
                                    const $star = $(this);
                                    if (idx < rating) {
                                        $star.removeClass("bi-star inactive").addClass("bi-star-fill active");
                                    } else {
                                        $star.removeClass("bi-star-fill active").addClass("bi-star inactive");
                                    }
                                });
                            }

                            // Tạo 5 ngôi sao
                            for (let i = 1; i <= 5; i++) {
                                const $star = $("<i/>")
                                    .addClass("bi star-rating-icon")
                                    .addClass(i <= currentRating ? "bi-star-fill active" : "bi-star inactive")
                                    .attr("data-rating", i)
                                    .appendTo($ratingContainer);

                                if (canRate) {
                                    // Hover effect
                                    $star.on("mouseenter", function() {
                                        const hoverRating = $(this).data("rating");
                                        updateStars(hoverRating);
                                    });

                                    // Click để lưu rating
                                    $star.on("click", function(e) {
                                        e.stopPropagation();
                                        const newRating = $(this).data("rating");

                                        // Gọi API để lưu rating
                                        AjaxHPAParadise({
                                            data: {
                                                name: "sp_Ticket_SaveRating",
                                                param: [
                                                    "TicketID", ticketID,
                                                    "Rating", newRating,
                                                    "LoginID", LoginID
                                                ]
                                            },
                                            success: function(res) {
                                                console.log("✅ Rating saved:", newRating);

                                                // ✅ CẬP NHẬT DATA TRONG GRID
                                                options.data.Rating = newRating;

                                                // ✅ CẬP NHẬT HIỂN THỊ
                                                updateStars(newRating);


                                                uiManager.showAlert({
                                                    type: "success",
                                                    message: `%TKRateThis% ${newRating} %TKRateStart%`
                                                });
                                            },
                                            error: function(err) {
                                                console.error("❌ Rating save failed:", err);
                                                uiManager.showAlert({
                                                    type: "error",
                                                    message: "%TKUnSaveRate%"
                                                });

                                                updateStars(options.data.Rating || 0);
                                            }
                                        });
                                    });
                                } else {
                                    // Không cho phép tương tác
                                    $star.on("click", function(e) {
                                        e.stopPropagation();

                                        if (!isTicketCreator) {
                                            uiManager.showAlert({
                                                type: "warning",
                                                message: "%TKOnlyReRating%"
                                            });

                                        } else if (!isTicketClosed) {
                                            uiManager.showAlert({
                                                type: "warning",
                                                message: "%TKOnlyReRatingClose%"
                                            });
                                        }
                                    });
                                }
                            }

                            // Mouse leave - reset về rating hiện tại
                            if (canRate) {
                                $ratingContainer.on("mouseleave", function() {
                                    updateStars(options.data.Rating || 0);
                                });
                            }

                            // Tooltip cho người không có quyền
                            if (!canRate) {
                                let tooltipText = "";
                                if (!isTicketCreator) {
                                    tooltipText = "%TKOnlyReRating%";
                                } else if (!isTicketClosed) {
                                    tooltipText = "%TKOnlyReRatingClose%";
                                }
                                $ratingContainer.attr("title", tooltipText);
                            }
                        }
                    });
                }

                // ===== CỘT CON MẮT - CHỈ HIỆN TRÊN MOBILE =====
                if (!columns.find(c => c.name === "EyeColumn")) {
                    columns.push({
                        name: "EyeColumn",
                        caption: "",
                        width: 45,
                        alignment: "center",
                        allowFiltering: false,
                        allowSorting: false,
                        visible: isMobile,
                        cellTemplate: function (container, options) {
                            const rowData = options.data;
                            const rowIndex = options.rowIndex;

                            const $btn = $("<button>")
                                .addClass("tk-eye-btn")
                                .attr("data-row-index", rowIndex)
                                .html(''<i class="bi bi-eye"></i>'')
                                .appendTo(container);

                            $btn.on("click", function (e) {
                                e.stopPropagation();

                                // Toggle active state
                                const isActive = $btn.hasClass("active");

                                // 1. Kiểm tra chính dòng này
                                const $existingRow = $(container).closest("tr").next(".tk-mobile-expand-row-tr");
                                if ($existingRow.length > 0) {
                                    $existingRow.find(".tk-expand-wrapper").stop(true, true).slideUp(500, function() {
                                        $existingRow.remove();
                                        $btn.removeClass("active").find("i").removeClass("bi-eye-slash").addClass("bi-eye");
                                    });
                                    return;
                                }

                                // 2. Đóng các dòng khác
                                $("#sp_Ticket_HistoryControl_html .tk-expand-wrapper").stop(true, true).slideUp(400, function() {
                                    $(this).closest(".tk-mobile-expand-row-tr").remove();
                                });
                                $("#sp_Ticket_HistoryControl_html .tk-eye-btn").removeClass("active").find("i").removeClass("bi-eye-slash").addClass("bi-eye");

                                // 3. Đổi icon ngay
                                $btn.addClass("active").find("i").removeClass("bi-eye").addClass("bi-eye-slash");

                                // Format ngày
                                let dateDisplay = "--";
                                if (rowData.CreatedDate) {
                                    const dateStr = rowData.CreatedDate;
                                    if (typeof dateStr === "string" && dateStr.includes("T")) {
                                        const match = dateStr.match(/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})/);
                                        if (match) dateDisplay = match[3] + "/" + match[2] + "/" + match[1] + " " + match[4] + ":" + match[5];
                                    } else {
                                        dateDisplay = dateStr;
                                    }
                                }

                                // Tạo expand row
                                const $expandRow = $("<tr>").addClass("tk-mobile-expand-row-tr");
                                const colSpan = $(container).closest("tr").find("td").length;
                                const $expandCell = $("<td>").attr("colspan", colSpan).css("padding", "0").appendTo($expandRow);

                                // Dùng wrapper bọc ngoài để slide mượt mà KHÔNG mất layout grid bên trong
                                const $expandWrapper = $("<div>").addClass("tk-expand-wrapper").appendTo($expandCell);
                                const $expandContent = $("<div>").addClass("tk-mobile-expand-row").appendTo($expandWrapper);

                                // === Tạo badge trạng thái ===
                                let statusBadge = ''--'';
                                if (rowData.TicketStatusName) {
                                    let stClass = ''bg-secondary'';
                                    let stIcon = ''bi-circle'';
                                    const sid = rowData.StatusID;
                                    if (sid === 0) { stClass = ''bg-warning''; stIcon = ''bi-file-earmark''; }
                                    else if (sid === 1) { stClass = ''bg-primary''; stIcon = ''bi-gear-fill''; }
                                    else if (sid === 2) { stClass = ''bg-success''; stIcon = ''bi-check-circle-fill''; }
                                    else if (sid === 3) { stClass = ''bg-secondary''; stIcon = ''bi-lock-fill''; }
                                    else if (sid === 4) { stClass = ''bg-danger''; stIcon = ''bi-x-circle-fill''; }
                                    statusBadge = ''<span class="tk-expand-badge '' + stClass + ''"><i class="bi '' + stIcon + ''"></i> '' + rowData.TicketStatusName + ''</span>'';
                                }

                                // === Tạo badge ưu tiên ===
                                let priorityBadge = ''--'';
                                if (rowData.LevelName) {
                                    let prClass = ''bg-secondary'';
                                    let prIcon = ''bi-question-circle'';
                                    const lv = rowData.LevelName;
                                    if (lv.includes(''Thấp'') || lv.includes(''Low'')) { prClass = ''bg-success''; prIcon = ''bi-arrow-down-circle''; }
                                    else if (lv.includes(''Trung'') || lv.includes(''Medium'') || lv.includes(''Normal'')) { prClass = ''bg-warning''; prIcon = ''bi-dash-circle''; }
                                    else if (lv.includes(''Khẩn'') || lv.includes(''Urgent'')) { prClass = ''bg-priority-urgent''; prIcon = ''bi-exclamation-triangle-fill''; }
                                    else if (lv.includes(''Cao'') || lv.includes(''High'')) { prClass = ''bg-danger''; prIcon = ''bi-arrow-up-circle''; }
                                    priorityBadge = ''<span class="tk-expand-badge '' + prClass + ''"><i class="bi '' + prIcon + ''"></i> '' + lv + ''</span>'';
                                }

                                $expandContent.html(
                                    ''<div class="tk-expand-item">'' +
                                        ''<span class="tk-expand-label"><i class="bi bi-person-fill me-1"></i>%TKCustomer%</span>'' +
                                        ''<span class="tk-expand-value">'' + (rowData.FullNameUser || "--") + ''</span>'' +
                                    ''</div>'' +
                                    ''<div class="tk-expand-item">'' +
                                        ''<span class="tk-expand-label"><i class="bi bi-flag-fill me-1"></i>%TKStatus%</span>'' +
                                        statusBadge +
                                    ''</div>'' +
                                    ''<div class="tk-expand-item">'' +
                                        ''<span class="tk-expand-label"><i class="bi bi-calendar-event me-1"></i>%TKDateRece%</span>'' +
                                        ''<span class="tk-expand-value"><i class="bi bi-clock me-1" style="color:var(--paradise-color-info)"></i>'' + dateDisplay + ''</span>'' +
                                    ''</div>'' +
                                    ''<div class="tk-expand-item">'' +
                                        ''<span class="tk-expand-label"><i class="bi bi-layers-fill me-1"></i>%TKPriority%</span>'' +
                                        priorityBadge +
                                    ''</div>''
                                );

                                // === Thêm mục Rating ===
                                const $ratingItem = $("<div>").addClass("tk-expand-item").appendTo($expandContent);
                                $("<span>").addClass("tk-expand-label").html(''<i class="bi bi-star-fill me-1"></i>%TKRating%'').appendTo($ratingItem);

                                const ratingCurrent = rowData.Rating || 0;
                                const r_ticketID = rowData.TicketID;
                                const r_statusID = rowData.StatusID;
                                const r_ticketCreatorID = rowData.CRM_CustomerID;
                                const r_currentUserCRM_ID = rowData.CurrentUserCRM_CustomerID;
                                const r_isTicketCreator = r_ticketCreatorID && r_currentUserCRM_ID && r_ticketCreatorID.toString() === r_currentUserCRM_ID.toString();
                                const r_isTicketClosed = r_statusID === 3;
                                const r_canRate = r_isTicketCreator && r_isTicketClosed;

                                const $ratingVal = $("<div>").addClass("tk-expand-value").css({ display: "flex", gap: "2px" }).appendTo($ratingItem);

                                function renderMobileStars(rating) {
                                    $ratingVal.empty();
                                    for (let i = 1; i <= 5; i++) {
                                        const $star = $("<i>").addClass("bi star-rating-icon")
                                            .addClass(i <= rating ? "bi-star-fill active" : "bi-star inactive")
                                            .css({ fontSize: "16px" })
                                            .attr("data-rating", i)
                                            .appendTo($ratingVal);

                                        if (r_canRate) {
                                            $star.on("click", function(ev) {
                                                ev.stopPropagation();
                                                const newRating = $(this).data("rating");
                                                AjaxHPAParadise({
                                                    data: { name: "sp_Ticket_SaveRating", param: ["TicketID", r_ticketID, "Rating", newRating, "LoginID", LoginID] },
                                                    success: function(res) {
                                                        rowData.Rating = newRating;
                                                        renderMobileStars(newRating);
                                                        uiManager.showAlert({ type: "success", message: `%TKRateThis% ${newRating} %TKRateStart%` });
                                                    },
                                                    error: function(err) {
                                                        uiManager.showAlert({ type: "error", message: "%TKUnSaveRate%" });
                                                        renderMobileStars(rowData.Rating || 0);
                                                    }
                                                });
                                            });
                                        } else {
                                            $star.on("click", function(ev) {
                                                ev.stopPropagation();
                                                if (!r_isTicketCreator) uiManager.showAlert({ type: "warning", message: "%TKOnlyReRating%" });
                                                else if (!r_isTicketClosed) uiManager.showAlert({ type: "warning", message: "%TKOnlyReRatingClose%" });
                                            });
                                        }
                                    }
                                }
                                renderMobileStars(ratingCurrent);
                                const hasFullAccess = rowData.HasFullAccessRight === true;
                                const hasManagerAccess = rowData.HasManagerAccessRight === true;
                                const canDelete = hasFullAccess || hasManagerAccess;

                                const $actItem = $("<div>").addClass("tk-expand-item").appendTo($expandContent);
                                $("<span>").addClass("tk-expand-label").html(''<i class="bi bi-shield-fill-exclamation me-1"></i>Delete'').appendTo($actItem);

                                const $delBtn = $("<span>")
                                    .addClass("tk-expand-badge bg-danger")
                                    .css({
                                        cursor: canDelete ? "pointer" : "not-allowed",
                                        opacity: canDelete ? 1 : 0.5
                                    })
                                    .html(''<i class="bi bi-trash-fill"></i> Xóa'')
                                    .appendTo($actItem);

                                $delBtn.on("click", function(ev) {
                                    ev.stopPropagation();
                                    if (!canDelete) {
                                        uiManager.showAlert({ type: "warning", message: "%TKNoPermission%" });
                                        return;
                                    }
                                    window.deleteTicket(rowData.TicketID);
                                });

                                // Chèn vào DOM
                                $(container).closest("tr").after($expandRow);

                                // Thực hiện slide trên Wrapper
                                $expandWrapper.stop(true, true).slideDown(500);
                            });
                        }
                    });
                }

                if (!columns.find(c => c.name === "DeleteColumn")) {
                    columns.push({
                        name: "DeleteColumn",
                        width: 60,
                        alignment: "center",
                        allowFiltering: false,
                        allowSorting: false,
                        visible: !isMobile,
                        fixed: true,
                        fixedPosition: "right",
                        cellTemplate: function (container, options) {

                            const hasFullAccess = options.data.HasFullAccessRight === true;
                            const hasManagerAccess = options.data.HasManagerAccessRight === true;
                            const canDelete = hasFullAccess || hasManagerAccess;

                            const $wrapper = $("<div/>").css({
                                opacity: canDelete ? 1 : 0.3,
                                cursor: canDelete ? "pointer" : "not-allowed",
                                display: "inline-block"
                            }).appendTo(container);

                            $("<div/>").dxButton({
                                icon: "trash",
                                type: "danger",
                                stylingMode: "text",
                                hint: canDelete ? "Xóa yêu cầu" : "%TKNoPermission%",
                                onClick: function (e) {
                                    e.event.stopPropagation();

                                    // ✅ Không có quyền → hiện warning, KHÔNG disabled, giống rating
                                    if (!canDelete) {
                                        uiManager.showAlert({
                                            type: "warning",
                                            message: "%TKNoPermission%"
                                        });
                                        return;
                                    }

                                    window.deleteTicket(options.data.TicketID);
                                }
                            }).appendTo($wrapper);
                        }
                    });
                }
            });
            gridInstance.option("scrolling", {
                mode: "infinite",
                rowRenderingMode: "virtual",
                preloadEnabled: false
            });

            gridInstance.option("remoteOperations", {
                paging: true,
                filtering: true,
                sorting: true,
                searching: true
            });

            function getGridHeight() {
                const gridEl = gridInstance.element();
                const domElement = gridEl.jquery ? gridEl[0] : gridEl;
                const top = domElement.getBoundingClientRect().top;
                const newHeight = window.innerHeight - top - 20;
                return newHeight > 300 ? newHeight : 500;
            }

            // Set paging config
            gridInstance.option("paging.enabled", true);
            gridInstance.option("paging.pageSize", 50);
            gridInstance.option("pager.visible", false);
            gridInstance.option("searchPanel.highlightSearchText", false);
            gridInstance.option("height", getGridHeight());

            gridInstance.option("dataSource", dataStore_GridTicket);

            gridInstance.endUpdate();

            // ===== MOBILE: Tạo filter panel ngoài toolbar =====
            if (window.innerWidth <= 768) {
                setTimeout(function() {
                    var $headerPanel = $("#sp_Ticket_HistoryControl_html .dx-datagrid-header-panel");
                    if ($headerPanel.length && $("#tk-mobile-filter-panel").length === 0) {
                        var $mobileFilter = $("<div>")
                            .attr("id", "tk-mobile-filter-panel")
                            .css({ display: "none", flexDirection: "column", width: "100%", padding: "6px 8px", boxSizing: "border-box" });

                        var $r1 = $("<div>").addClass("tk-filter-wrapper").appendTo($mobileFilter);
                        $("<span>").addClass("tk-filter-label").text("%TCCompany%").appendTo($r1);
                        $("<div>").addClass("tk-filter-box").attr("id", "FilterCompany").appendTo($r1);

                        var $r2 = $("<div>").addClass("tk-filter-wrapper").appendTo($mobileFilter);
                        $("<span>").addClass("tk-filter-label").text("%TCEmployee%").appendTo($r2);
                        $("<div>").addClass("tk-filter-box").attr("id", "FilterEmployee").appendTo($r2);

                        var $r3 = $("<div>").addClass("tk-filter-wrapper").appendTo($mobileFilter);
                        $("<span>").addClass("tk-filter-label").text("%TKFromDate%").appendTo($r3);
                        $("<div>").addClass("tk-filter-box").attr("id", "FilterFromDate").appendTo($r3);

                        var $r4 = $("<div>").addClass("tk-filter-wrapper").appendTo($mobileFilter);
                        $("<span>").addClass("tk-filter-label").text("%TKToDate%").appendTo($r4);
                        $("<div>").addClass("tk-filter-box").attr("id", "FilterToDate").appendTo($r4);

                        var $clearRow = $("<div>")
                            .addClass("tk-filter-clear-row")
                            .css({ textAlign: "right", marginTop: "6px", width: "100%" })
                            .appendTo($mobileFilter);
                        $("<button>")
                            .addClass("tk-filter-clear-btn")
                            .html(''<i class="bi bi-x-circle me-1"></i> Xóa lọc'')
                            .on("click", function() {
                                if (window.FilterFromDateInstance) window.FilterFromDateInstance.option("value", null);
                                if (window.FilterToDateInstance) window.FilterToDateInstance.option("value", null);
                                if (window.FilterEmployeeInstance) window.FilterEmployeeInstance.option("value", null);
                                if (window.FilterCompanyInstance) window.FilterCompanyInstance.option("value", null);
                                window.currentFilters = {};
                                applyGridFilters();
                                uiManager.showAlert({ type: "info", message: "%TKFilterClear%" });
                            })
                            .appendTo($clearRow);

                        $headerPanel.after($mobileFilter);

                        setTimeout(function() { window._initFilterControls(); }, 200);
                    }
                }, 500);
            }

            gridInstance.on("optionChanged", function(e) {
                if (e.name === "searchPanel" && e.fullName === "searchPanel.text") {
                    gridInstance.refresh();
                }
            });
            '
                + (select loadData from tblCommonControlType_Signed where UID = 'PBE85F4D0401941B491282F2377C47C18')
                + (select loadData from tblCommonControlType_Signed where UID = 'P204298E1C9314A0582404443CBB5D8A7')
            +(select loadData from tblCommonControlType_Signed where UID = 'PCA74EB22EAFB4496B36C0207AE3E070B')
            +(select loadData from tblCommonControlType_Signed where UID = 'P252C9FAACFA748C6BE6238266555C999')
            +(select loadData from tblCommonControlType_Signed where UID = 'PBCCAC0E331424C56ACC6E04F90D5B9D5')
            +(select loadData from tblCommonControlType_Signed where UID = 'PE1E3F98AED2F407EB0710D05E3C391BE')
            +(select loadData from tblCommonControlType_Signed where UID = 'PD96D81AC1BF3478BB8F74E08C4751659')
            +(select loadData from tblCommonControlType_Signed where UID = 'P445AB4D6127F481D840E462DF5CC093A')
            +(select loadData from tblCommonControlType_Signed where UID = 'PC3DC3952A3A148EDAF3D552490A9744D')
            +(select loadData from tblCommonControlType_Signed where UID = 'P9DC7FDC9417941169AB7D49D8E45D402') +N'
    }
    ReloadData()
}) ();
</script>
';

-- Ghi đè cache HTML
MERGE dbo.tblHtmlScriptCache AS target
USING (SELECT 'sp_Ticket_HistoryControl_html' AS ClassName) AS source
ON (target.ClassName = source.ClassName)
WHEN MATCHED THEN
    UPDATE SET HtmlCache = @html, UpdateDate = GETDATE()
WHEN NOT MATCHED THEN
    INSERT (ClassName, HtmlCache, UpdateDate)
    VALUES (source.ClassName, @html, GETDATE());

--exec sptblCommonControlType_Signed_DUC 'sp_Ticket_HistoryControl_html'
--exec sp_GenerateHTMLScript_new 'sp_Ticket_HistoryControl_html'
SELECT @html AS html;
end
