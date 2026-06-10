CREATE OR ALTER PROCEDURE [dbo].[sp_CRM_ListConfigKPI_html]
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
    /* Modal Styles for KPI Setup */
    .kpi-modal .modal-content {
        border-radius: 12px;
        border: none;
        box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
    }

    .kpi-modal .modal-header {
        background: linear-gradient(135deg, #00673b 0%, #1d9336 100%);
        color: white;
        border-radius: 12px 12px 0 0;
        padding: 1.5rem;
    }

    .kpi-modal .modal-title {
        font-weight: 700;
        font-size: 1.25rem;
    }

    .kpi-modal .btn-close {
        filter: brightness(0) invert(1);
    }

    .kpi-modal .form-label {
        font-weight: 600;
        color: #374151;
        margin-bottom: 0.5rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }

    .kpi-modal .form-label i {
        color: #00673b;
    }

    .kpi-modal .text-danger {
        color: #dc2626 !important;
    }

    .kpi-modal .btn-success {
        border: none;
        font-weight: 600;
        transition: all 0.3s ease;
    }

    .kpi-modal .btn-success:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(0, 103, 59, 0.3);
    }

    .kpi-modal .btn-secondary {
        background-color: #6b7280;
        border: none;
        font-weight: 600;
    }

    .kpi-modal .modal-body {
        padding: 2rem;
    }

    /* --- Responsive Toolbar & Layout Fixes --- */
    /* Add margin to Add button so it doesn't touch the grid */
    #btnAddKPI {
        margin-bottom: 12px;
    }

    /* Force DevExtreme Toolbar to allow wrapping instead of overlapping */
    #GridConfigKPI .dx-toolbar {
        height: auto !important;
        min-height: 48px;
        padding-top: 5px;
        padding-bottom: 5px;
    }
    #GridConfigKPI .dx-toolbar-items-container {
        flex-wrap: wrap !important;
        height: auto !important;
        align-items: flex-start !important;
    }
    #GridConfigKPI .dx-toolbar-before,
    #GridConfigKPI .dx-toolbar-after {
        display: flex;
        flex-wrap: wrap;
        align-items: center;
        padding-bottom: 5px;
    }

    /* Mobile & Tablet adjustments (< 768px) */
    @media (max-width: 768px) {
        .kpi-filter {
            flex-direction: column !important;
            align-items: stretch !important;
            width: 100%;
            gap: 10px !important;
        }
        .kpi-filter > div {
            width: 100% !important;
            justify-content: space-between;
        }
        .kpi-filter input[type="date"] {
            width: calc(100% - 40px) !important;
        }
        #setupKPIEmployeeToolbar {
            width: calc(100% - 70px) !important;
        }
        #setupKPISearchBtn, #setupKPIResetBtn {
            width: 100% !important;
            margin-top: 5px;
        }
        #GridConfigKPI .dx-toolbar-after {
            width: 100% !important;
            justify-content: space-between !important;
        }
        #GridConfigKPI .dx-toolbar-after .dx-toolbar-item {
            margin-bottom: 5px;
        }
    }

    /* Responsive container, grid, toolbar and modal overrides */
    #sp_CRM_ListConfigKPI_html {
        box-sizing: border-box;
        width: 100%;
        max-width: 100%;
        overflow-x: hidden;
    }

    #sp_CRM_ListConfigKPI_html > div:first-child {
        flex-wrap: wrap;
        gap: 8px;
        margin-bottom: 12px;
    }

    #btnAddKPI {
        max-width: 100%;
        white-space: normal;
        justify-content: center;
    }

    #GridConfigKPI {
        width: 100%;
        max-width: 100%;
        min-height: 420px;
        overflow: hidden;
    }

    #GridConfigKPI .dx-datagrid {
        max-width: 100%;
    }

    #GridConfigKPI .dx-datagrid-header-panel {
        height: auto !important;
        min-height: 0 !important;
        padding: 0 0 10px 0 !important;
        overflow: visible !important;
    }

    #GridConfigKPI .dx-toolbar {
        overflow: visible !important;
    }

    #GridConfigKPI .dx-toolbar-items-container {
        display: flex !important;
        flex-wrap: wrap !important;
        align-items: flex-start !important;
        gap: 8px 12px;
        height: auto !important;
        min-height: 0 !important;
        overflow: visible !important;
    }

    #GridConfigKPI .dx-toolbar-before,
    #GridConfigKPI .dx-toolbar-after {
        position: static !important;
        left: auto !important;
        right: auto !important;
        top: auto !important;
        transform: none !important;
        display: flex !important;
        flex-wrap: wrap;
        align-items: center;
        gap: 8px;
        max-width: 100%;
        height: auto !important;
        padding: 0 !important;
    }

    #GridConfigKPI .dx-toolbar-before {
        flex: 1 1 560px;
        min-width: 0;
        order: 1;
    }

    #GridConfigKPI .dx-toolbar-after {
        flex: 0 1 320px;
        justify-content: flex-end;
        margin-left: auto;
        order: 2;
    }

    #GridConfigKPI .dx-toolbar-item,
    #GridConfigKPI .dx-toolbar-item > div,
    .kpi-filter,
    .kpi-filter > div {
        max-width: 100%;
        min-width: 0 !important;
    }

    .kpi-filter {
        display: grid !important;
        grid-template-columns: minmax(180px, 220px) repeat(2, minmax(132px, 150px)) auto auto;
        align-items: end !important;
        gap: 8px 10px !important;
        width: 100%;
    }

    .kpi-filter > div {
        width: 100%;
    }

    .kpi-filter label {
        flex: 0 0 auto;
        line-height: 1.2;
    }

    .kpi-filter input[type="date"],
    #setupKPIEmployeeToolbar {
        max-width: 100%;
        box-sizing: border-box;
    }

    #setupKPISearchBtn,
    #setupKPIResetBtn {
        min-height: 32px;
    }

    #GridConfigKPI .dx-searchbox,
    #GridConfigKPI .dx-toolbar-after .dx-texteditor {
        width: min(260px, 100%) !important;
        max-width: 100%;
    }

    #GridConfigKPI .dx-datagrid-headers,
    #GridConfigKPI .dx-datagrid-rowsview {
        overflow-x: auto;
    }

    #GridConfigKPI .dx-datagrid-table {
        min-width: 760px;
    }

    .kpi-modal .modal-dialog {
        width: min(900px, calc(100vw - 32px));
        max-width: calc(100vw - 32px);
        margin-left: auto;
        margin-right: auto;
    }

    .kpi-modal .modal-content {
        max-height: calc(100vh - 32px);
        overflow: hidden;
    }

    .kpi-modal .modal-body {
        max-height: calc(100vh - 190px);
        overflow-y: auto;
        overflow-x: hidden;
    }

    .kpi-modal .modal-footer {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
    }

    .kpi-modal .modal-footer .btn {
        min-width: 96px;
    }

    @media (max-width: 1024px) {
        #sp_CRM_ListConfigKPI_html {
            padding: 16px !important;
        }

        #GridConfigKPI {
            min-height: 380px;
        }

        #GridConfigKPI .dx-toolbar-before,
        #GridConfigKPI .dx-toolbar-after {
            flex-basis: 100%;
            width: 100%;
            justify-content: flex-start;
            margin-left: 0;
        }

        .kpi-filter {
            grid-template-columns: minmax(180px, 1fr) repeat(2, minmax(130px, 150px)) auto auto;
        }

        #GridConfigKPI .dx-datagrid-table {
            min-width: 720px;
        }

        #GridConfigKPI .dx-searchbox,
        #GridConfigKPI .dx-toolbar-after .dx-texteditor {
            width: 260px !important;
        }
    }

    @media (max-width: 768px) {
        #sp_CRM_ListConfigKPI_html {
            padding: 12px !important;
        }

        #sp_CRM_ListConfigKPI_html > div:first-child {
            justify-content: stretch !important;
        }

        #btnAddKPI {
            width: 100%;
            min-height: 38px;
        }

        #GridConfigKPI {
            min-height: 360px;
        }

        .kpi-filter {
            grid-template-columns: repeat(2, minmax(0, 1fr));
            align-items: stretch !important;
        }

        .kpi-filter > div {
            align-items: flex-start !important;
            flex-direction: column;
            gap: 4px !important;
        }

        .kpi-filter input[type="date"],
        #setupKPIEmployeeToolbar,
        #setupKPISearchBtn,
        #setupKPIResetBtn {
            width: 100% !important;
        }

        #GridConfigKPI .dx-datagrid-table {
            min-width: 680px;
        }

        #GridConfigKPI .dx-toolbar-after {
            justify-content: flex-start !important;
        }

        #GridConfigKPI .dx-searchbox,
        #GridConfigKPI .dx-toolbar-after .dx-texteditor {
            width: 100% !important;
        }

        .kpi-modal .modal-dialog {
            width: calc(100vw - 20px);
            max-width: calc(100vw - 20px);
            margin: 10px auto;
        }

        .kpi-modal .modal-header {
            padding: 1rem;
        }

        .kpi-modal .modal-title {
            font-size: 1rem;
            line-height: 1.3;
        }

        .kpi-modal .modal-body {
            padding: 1rem;
            max-height: calc(100vh - 170px);
        }

        .kpi-modal .form-label {
            font-size: 12px;
            line-height: 1.35;
        }

        .kpi-modal .modal-footer {
            justify-content: stretch;
            padding: 0.75rem 1rem;
        }

        .kpi-modal .modal-footer .btn {
            flex: 1 1 calc(50% - 8px);
            min-width: 0;
            white-space: normal;
        }
    }

    @media (max-width: 480px) {
        #sp_CRM_ListConfigKPI_html {
            padding: 8px !important;
        }

        #GridConfigKPI {
            min-height: 330px;
        }

        .kpi-filter {
            grid-template-columns: 1fr;
        }

        .kpi-filter label {
            width: 100%;
        }

        #GridConfigKPI .dx-datagrid-table {
            min-width: 640px;
        }

        #setupKPISearchBtn,
        #setupKPIResetBtn {
            min-height: 36px;
        }

        .kpi-modal .modal-content {
            max-height: calc(100vh - 20px);
        }

        .kpi-modal .modal-body {
            max-height: calc(100vh - 185px);
        }

        .kpi-modal .modal-footer .btn {
            flex-basis: 100%;
        }
    }

</style>

<div id="sp_CRM_ListConfigKPI_html" style="padding: 20px;">
    <div style="display: flex; justify-content: flex-end;">
        <button type="button" class="btn btn-success" id="btnAddKPI"
            style="padding: 6px 12px;font-weight: 500;font-size: 12px;display: inline-flex;align-items: center;transition: all 0.3s ease;    ">
            <i class="fas fa-plus me-2"></i>Thêm cấu hình KPI
        </button>
    </div>
    <div id="GridConfigKPI" style="height: 100%;"></div>
</div>

<!-- KPI Configuration Modal -->
<div class="modal fade kpi-modal" id="kpiSetupModal" tabindex="-1" aria-labelledby="kpiSetupModalLabel"
    aria-hidden="true" data-bs-backdrop="static" data-bs-keyboard="false">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="kpiSetupModalLabel">
                    <i class="fas fa-cog me-2"></i>Cấu hình KPI nhân viên
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
                <form id="kpiConfigForm">
                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="employeeCode" class="form-label">
                                    <i class="fas fa-id-card"></i>%EmployeeID% <span class="text-danger">*</span>
                                </label>
                                <div id="P811BD1D510B745C599591201AE86927E"></div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="kpiCategory" class="form-label">
                                    <i class="fas fa-list"></i>%CategoriesKPI% <span class="text-danger">*</span>
                                </label>
                                <div id="P0DB085F51685461082210C31F2596A6E"></div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
<div class="mb-3">
                                <label for="kpiUnit" class="form-label">
                                    <i class="fas fa-ruler"></i>%TimeUnits% <span class="text-danger">*</span>
                                </label>
                                <div id="P5B1413F12E1F4B48AA0628E5DC980523"></div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="kpiTarget" class="form-label">
                                    <i class="fas fa-bullseye"></i>%kpi_required% <span class="text-danger">*</span>
                                </label>
                                <div id="PCA32840E4FB241388D141634E36C763C"></div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="experiencePoints" class="form-label">
                                    <i class="fas fa-star"></i>%exp_achieve% <span class="text-danger">*</span>
                                </label>
                                <div id="PDEFEC5963ABD4874933EC47D2428A046"></div>
                            </div>
                            <div class="mb-3">
                                <label for="experiencePoints" class="form-label">
                                    <i class="fas fa-star"></i>%BonusPerItem(exp)% <span class="text-danger">*</span>
                                </label>
                                <div id="P914C917F26C941FB85DEDA0CDD8934B2"></div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="coinAchieved" class="form-label">
                                    <i class="fas fa-coins"></i>%coin_achieve%<span class="text-danger">*</span>
                                </label>
                                <div id="PDA740F856FEC433F915E379487DC78DF"></div>
                            </div>
                            <div class="mb-3">
                                <label for="coinAchieved" class="form-label">
                                    <i class="fas fa-coins"></i>%Coin_BonusPerItem%<span class="text-danger">*</span>
                                </label>
                                <div id="PC69BC341ED5841C798845AC822C26FCA"></div>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="col-md-6">
                            <div class="mb-3">
                                <label for="effectiveDate" class="form-label">
                                    <i class="fas fa-calendar-alt"></i>%EffectiveDate% <span
                                        class="text-danger">*</span>
                                </label>
                                <div id="P025272E283ED4578A2D5F096CCC91AF1"></div>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-danger" id="deleteKpiConfig" style="display: none;">
                    <i class="fas fa-trash me-2"></i>Xóa
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
<div class="d-none">
    <div id="P99BE835E820540B0B555475634369742"></div>
</div>

<script>
    (() => {
        let kpiToolbarConfigured = false;
        let DataSource = []
        let oldKpiData = {}; // Store old data for edit comparison


        let InstanceKPI_requiredPCA32840E4FB241388D141634E36C763C = null;
        let KPI_requiredTimeOut;
        let _autoSaveKPI_requiredPCA32840E4FB241388D141634E36C763C = false;
        let _readOnlyKPI_requiredPCA32840E4FB241388D141634E36C763C = false;
        let $containerKPI_requiredPCA32840E4FB241388D141634E36C763C = $("#PCA32840E4FB241388D141634E36C763C");

        async function NumberBoxSaveLogicKPI_required() {
            let val = InstanceKPI_requiredPCA32840E4FB241388D141634E36C763C.option("value");

            const dataJSON = JSON.stringify(["1236064503", ["KPI_required"], [val]]);

            // Context-aware record IDs
            let id1 = currentRecordID_ID;
            if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {
                id1 = cellInfo.data["ID"] || id1;
            }
            let currentRecordIDValue = [id1];
            let currentRecordID = ["ID"];

            if ("" && "".trim() !== "") {
                let id2 = currentRecordID_;
                if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {
                    id2 = cellInfo.data[""] || id2;
                }
                currentRecordIDValue.push(id2);
                currentRecordID.push("");
            }

            const idValsJSON = JSON.stringify([currentRecordIDValue, currentRecordID]);

            try {
                const json = await saveFunction(dataJSON, idValsJSON);
                const dtError = json.data[json.data.length - 1] || [];
                if (dtError.length > 0 && dtError[0].Status === "ERROR") {
                    uiManager.showAlert({ type: "error", message: dtError[0]?.Message || "%SaveErrorMessage%" });
                } else {
                    if (GridConfigKPI != 0 && GridConfigKPI != null && GridConfigKPI != "" && window.hpaSharedGridDataSources["GridConfigKPI"]) {
                        try {
                            var updateData = {};
                            updateData["ID"] = currentRecordIDValue[0];
                            updateData["KPI_required"] = InstanceKPI_requiredPCA32840E4FB241388D141634E36C763C.option("value");

                            var id2FieldName = "";
                            var hasKey2 = id2FieldName && id2FieldName !== "" && id2FieldName.indexOf("%") === -1;

                            if (hasKey2) {
                                if (currentRecordIDValue.length > 1 && currentRecordIDValue[1] !== undefined) {
                                    updateData[id2FieldName] = currentRecordIDValue[1];
                                }
                            }

                            // Thực hiện update shared grid
                            window.updateSharedGridRow("GridConfigKPI", updateData);

                            // Kiểm tra và cập nhật biến DataSource cục bộ
                            if (typeof DataSource !== "undefined" && Array.isArray(DataSource)) {
                                var ds;
                                if (!hasKey2) {
                                    // Trường hợp 1 khóa
                                    ds = DataSource.filter(item => item["ID"] === updateData["ID"]);
                                } else {
                                    // Trường hợp 2 khóa
                                    ds = DataSource.filter(item =>
                                        item["ID"] === updateData["ID"] &&
                                        item[id2FieldName] === updateData[id2FieldName]
                                    );
                                }

              if (ds && ds.length > 0) {
                                    ds[0]["KPI_required"] = updateData["KPI_required"];
                                }
                            }
                        } catch (dsErr) {
                            console.warn("[Grid Sync] NumberBox KPI_requiredPCA32840E4FB241388D141634E36C763C: Không thể sync shared grid data source:", dsErr);
                        }
                    }
                }

                if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {
                    try {
                        const grid = cellInfo.component;
                        grid.cellValue(cellInfo.rowIndex, "KPI_required", val);
                        grid.repaint();
                    } catch (syncErr) {
                        console.warn("[Grid Sync] NumberBox KPI_requiredPCA32840E4FB241388D141634E36C763C: Error", syncErr);
                    }
                }
            } catch (err) {
                console.error("NumberBox Save Error:", err);
            }
        }

        let KPI_requiredPCA32840E4FB241388D141634E36C763CRealInstance = $("#PCA32840E4FB241388D141634E36C763C").dxNumberBox({
            stylingMode: "underlined",
            format: "#,##0",
            showSpinButtons: false,
            showClearButton: false,
            width: "100%",
            elementAttr: { class: "hpa-dx-numberbox-inline" },
            readOnly: _readOnlyKPI_requiredPCA32840E4FB241388D141634E36C763C,
            onContentReady: function (e) {
                if (!$("#custom-style-underlined-KPI_requiredPCA32840E4FB241388D141634E36C763C").length) {
                    $("<style>").attr("id", "custom-style-underlined-KPI_requiredPCA32840E4FB241388D141634E36C763C").text(" .dx-texteditor.dx-editor-underlined::after { border-bottom-color: #ddd !important; } .dx-texteditor.dx-editor-underlined.dx-state-focused::after { border-bottom-color: #337ab7 !important; border-bottom-width: 2px !important; } ").appendTo("head");
                }
            },
            onKeyDown: function (e) {
                if (e.event.key === "Enter") {
                    e.event.preventDefault();
                    if (_autoSaveKPI_requiredPCA32840E4FB241388D141634E36C763C) {
                        NumberBoxSaveLogicKPI_required();
                    }
                }
            },
            onValueChanged: async (e) => {
                if (_autoSaveKPI_requiredPCA32840E4FB241388D141634E36C763C) {
                    clearTimeout(KPI_requiredTimeOut);
                    e.event && await NumberBoxSaveLogicKPI_required();
                } else {
                    if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {
                        const grid = cellInfo.component;
                        grid.cellValue(cellInfo.rowIndex, "KPI_required", e.value);
                    }
                }

                // Real-time calculation when KPI_required changes
                const kpiRequired = e.value || 0;

                // Recalculate BonusPerItem (exp)
                if (typeof InstanceExperiencePointsPDEFEC5963ABD4874933EC47D2428A046 !== "undefined" &&
                    typeof InstanceBonusPerItemP914C917F26C941FB85DEDA0CDD8934B2 !== "undefined") {
                    const experiencePoints = InstanceExperiencePointsPDEFEC5963ABD4874933EC47D2428A046.option("value") || 0;
                    const bonusPerItem = (kpiRequired && kpiRequired > 0) ? (experiencePoints / kpiRequired) : 0;
                    InstanceBonusPerItemP914C917F26C941FB85DEDA0CDD8934B2.option("value", bonusPerItem);
                }

                // Recalculate Coin_BonusPerItem
                if (typeof InstanceCoinPDA740F856FEC433F915E379487DC78DF !== "undefined" &&
                    typeof InstanceCoin_BonusPerItemPC69BC341ED5841C798845AC822C26FCA !== "undefined") {
       const coin = InstanceCoinPDA740F856FEC433F915E379487DC78DF.option("value") || 0;
                    const coinBonusPerItem = (kpiRequired && kpiRequired > 0) ? (coin / kpiRequired) : 0;
                    InstanceCoin_BonusPerItemPC69BC341ED5841C798845AC822C26FCA.option("value", coinBonusPerItem);
                }
            },
            onKeyUp: (e) => {
                if (_autoSaveKPI_requiredPCA32840E4FB241388D141634E36C763C) {
                    clearTimeout(KPI_requiredTimeOut);
                    KPI_requiredTimeOut = setTimeout(async () => NumberBoxSaveLogicKPI_required(), 1000);
                }
            }
        }).dxNumberBox("instance");

        /* =============== Public API =============== */
        InstanceKPI_requiredPCA32840E4FB241388D141634E36C763C = {
            option: function (name, value) {

                if (value !== undefined) {
                    return KPI_requiredPCA32840E4FB241388D141634E36C763CRealInstance.option(name, value);
                } else {
                    return KPI_requiredPCA32840E4FB241388D141634E36C763CRealInstance.option(name);
                }
            },
            repaint: function () {
                KPI_requiredPCA32840E4FB241388D141634E36C763CRealInstance.repaint();
            },
            focus: function () {
                KPI_requiredPCA32840E4FB241388D141634E36C763CRealInstance.focus();
            },
            _suppressValueChangeAction: function () {
                // NumberBox không hỗ trợ method này
            },
            _resumeValueChangeAction: function () {
                // NumberBox không hỗ trợ method này
            }
        };



        let InstanceExperiencePointsPDEFEC5963ABD4874933EC47D2428A046 = null;
        let ExperiencePointsTimeOut;
        let _autoSaveExperiencePointsPDEFEC5963ABD4874933EC47D2428A046 = false;
        let _readOnlyExperiencePointsPDEFEC5963ABD4874933EC47D2428A046 = false;
        let $containerExperiencePointsPDEFEC5963ABD4874933EC47D2428A046 = $("#PDEFEC5963ABD4874933EC47D2428A046");

        async function NumberBoxSaveLogicExperiencePoints() {
            let val = InstanceExperiencePointsPDEFEC5963ABD4874933EC47D2428A046.option("value");

            const dataJSON = JSON.stringify(["1236064503", ["ExperiencePoints"], [val]]);

            // Context-aware record IDs
            let id1 = currentRecordID_ID;
            if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {
                id1 = cellInfo.data["ID"] || id1;
            }
            let currentRecordIDValue = [id1];
            let currentRecordID = ["ID"];

            if ("" && "".trim() !== "") {
                let id2 = currentRecordID_;
                if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {
                    id2 = cellInfo.data[""] || id2;
                }
                currentRecordIDValue.push(id2);
                currentRecordID.push("");
            }

            const idValsJSON = JSON.stringify([currentRecordIDValue, currentRecordID]);

            try {
                const json = await saveFunction(dataJSON, idValsJSON);
                const dtError = json.data[json.data.length - 1] || [];
                if (dtError.length > 0 && dtError[0].Status === "ERROR") {
                    uiManager.showAlert({ type: "error", message: dtError[0]?.Message || "%SaveErrorMessage%" });
                } else {
                    if (GridConfigKPI != 0 && GridConfigKPI != null && GridConfigKPI != "" && window.hpaSharedGridDataSources["GridConfigKPI"]) {
                        try {
                            var updateData = {};
                            updateData["ID"] = currentRecordIDValue[0];
                            updateData["ExperiencePoints"] = InstanceExperiencePointsPDEFEC5963ABD4874933EC47D2428A046.option("value");

                            var id2FieldName = "";
                            var hasKey2 = id2FieldName && id2FieldName !== "" && id2FieldName.indexOf("%") === -1;

                            if (hasKey2) {
                                if (currentRecordIDValue.length > 1 && currentRecordIDValue[1] !== undefined) {
                                    updateData[id2FieldName] = currentRecordIDValue[1];
                                }
                            }

                            // Thực hiện update shared grid
                            window.updateSharedGridRow("GridConfigKPI", updateData);

                            // Kiểm tra và cập nhật biến DataSource cục bộ
                            if (typeof DataSource !== "undefined" && Array.isArray(DataSource)) {
                                var ds;
                                if (!hasKey2) {
                                    // Trường hợp 1 khóa
                                    ds = DataSource.filter(item => item["ID"] === updateData["ID"]);
                                } else {
                                    // Trường hợp 2 khóa
                                    ds = DataSource.filter(item =>
                                        item["ID"] === updateData["ID"] &&
                                        item[id2FieldName] === updateData[id2FieldName]
                                    );
                                }

                                if (ds && ds.length > 0) {
                                    ds[0]["ExperiencePoints"] = updateData["ExperiencePoints"];
                                }
                            }
                        } catch (dsErr) {
                            console.warn("[Grid Sync] NumberBox ExperiencePointsPDEFEC5963ABD4874933EC47D2428A046: Không thể sync shared grid data source:", dsErr);
                        }
                    }
                }

                if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {
                    try {
                        const grid = cellInfo.component;
                        grid.cellValue(cellInfo.rowIndex, "ExperiencePoints", val);
                        grid.repaint();
                    } catch (syncErr) {
                        console.warn("[Grid Sync] NumberBox ExperiencePointsPDEFEC5963ABD4874933EC47D2428A046: Error", syncErr);
                    }
                }
            } catch (err) {
                console.error("NumberBox Save Error:", err);
            }
        }

        let ExperiencePointsPDEFEC5963ABD4874933EC47D2428A046RealInstance = $("#PDEFEC5963ABD4874933EC47D2428A046").dxNumberBox({
            stylingMode: "underlined",
            format: "#,##0",
            showSpinButtons: false,
            showClearButton: false,
            width: "100%",
            elementAttr: { class: "hpa-dx-numberbox-inline" },
            readOnly: _readOnlyExperiencePointsPDEFEC5963ABD4874933EC47D2428A046,
            onContentReady: function (e) {
                if (!$("#custom-style-underlined-ExperiencePointsPDEFEC5963ABD4874933EC47D2428A046").length) {
                    $("<style>").attr("id", "custom-style-underlined-ExperiencePointsPDEFEC5963ABD4874933EC47D2428A046").text(" .dx-texteditor.dx-editor-underlined::after { border-bottom-color: #ddd !important; } .dx-texteditor.dx-editor-underlined.dx-state-focused::after { border-bottom-color: #337ab7 !important; border-bottom-width: 2px !important; } ").appendTo("head");
                }
            },
            onKeyDown: function (e) {
                if (e.event.key === "Enter") {
                    e.event.preventDefault();
                    if (_autoSaveExperiencePointsPDEFEC5963ABD4874933EC47D2428A046) {
                        NumberBoxSaveLogicExperiencePoints();
                    }
                }
            },
            onValueChanged: async (e) => {
                if (_autoSaveExperiencePointsPDEFEC5963ABD4874933EC47D2428A046) {
                    clearTimeout(ExperiencePointsTimeOut);
                    e.event && await NumberBoxSaveLogicExperiencePoints();
                } else {
                    if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {
                        const grid = cellInfo.component;
                        grid.cellValue(cellInfo.rowIndex, "ExperiencePoints", e.value);
                    }
                }

                // Real-time calculation: BonusPerItem (exp) = ExperiencePoints / KPI_required
                if (typeof InstanceKPI_requiredPCA32840E4FB241388D141634E36C763C !== "undefined" &&
                    typeof InstanceBonusPerItemP914C917F26C941FB85DEDA0CDD8934B2 !== "undefined") {
                    const kpiRequired = InstanceKPI_requiredPCA32840E4FB241388D141634E36C763C.option("value");
                    const experiencePoints = e.value || 0;
                    const bonusPerItem = (kpiRequired && kpiRequired > 0) ? (experiencePoints / kpiRequired) : 0;
                    InstanceBonusPerItemP914C917F26C941FB85DEDA0CDD8934B2.option("value", bonusPerItem);
                }
            },
            onKeyUp: (e) => {
                if (_autoSaveExperiencePointsPDEFEC5963ABD4874933EC47D2428A046) {
                    clearTimeout(ExperiencePointsTimeOut);
                    ExperiencePointsTimeOut = setTimeout(async () => NumberBoxSaveLogicExperiencePoints(), 1000);
                }
            }
        }).dxNumberBox("instance");

        /* =============== Public API =============== */
        InstanceExperiencePointsPDEFEC5963ABD4874933EC47D2428A046 = {
            option: function (name, value) {

                if (value !== undefined) {
                    return ExperiencePointsPDEFEC5963ABD4874933EC47D2428A046RealInstance.option(name, value);
                } else {
                    return ExperiencePointsPDEFEC5963ABD4874933EC47D2428A046RealInstance.option(name);
                }
            },
            repaint: function () {
                ExperiencePointsPDEFEC5963ABD4874933EC47D2428A046RealInstance.repaint();
            },
            focus: function () {
                ExperiencePointsPDEFEC5963ABD4874933EC47D2428A046RealInstance.focus();
            },
            _suppressValueChangeAction: function () {
                // NumberBox không hỗ trợ method này
            },
            _resumeValueChangeAction: function () {
                // NumberBox không hỗ trợ method này
            }
        };


        let InstanceCoinPDA740F856FEC433F915E379487DC78DF = null;
        let CoinTimeOut;
        let _autoSaveCoinPDA740F856FEC433F915E379487DC78DF = false;
        let _readOnlyCoinPDA740F856FEC433F915E379487DC78DF = false;
        let $containerCoinPDA740F856FEC433F915E379487DC78DF = $("#PDA740F856FEC433F915E379487DC78DF");

        async function NumberBoxSaveLogicCoin() {
            let val = InstanceCoinPDA740F856FEC433F915E379487DC78DF.option("value");

            const dataJSON = JSON.stringify(["1236064503", ["Coin"], [val]]);

            // Context-aware record IDs
            let id1 = currentRecordID_ID;
            if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {
                id1 = cellInfo.data["ID"] || id1;
            }
            let currentRecordIDValue = [id1];
            let currentRecordID = ["ID"];

            if ("" && "".trim() !== "") {
                let id2 = currentRecordID_;
                if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {
                    id2 = cellInfo.data[""] || id2;
                }
                currentRecordIDValue.push(id2);
                currentRecordID.push("");
            }

            const idValsJSON = JSON.stringify([currentRecordIDValue, currentRecordID]);

            try {
                const json = await saveFunction(dataJSON, idValsJSON);
                const dtError = json.data[json.data.length - 1] || [];
                if (dtError.length > 0 && dtError[0].Status === "ERROR") {
                    uiManager.showAlert({ type: "error", message: dtError[0]?.Message || "%SaveErrorMessage%" });
                } else {
                    if (GridConfigKPI != 0 && GridConfigKPI != null && GridConfigKPI != "" && window.hpaSharedGridDataSources["GridConfigKPI"]) {
                        try {
                            var updateData = {};
                            updateData["ID"] = currentRecordIDValue[0];
                            updateData["Coin"] = InstanceCoinPDA740F856FEC433F915E379487DC78DF.option("value");

                            var id2FieldName = "";
                            var hasKey2 = id2FieldName && id2FieldName !== "" && id2FieldName.indexOf("%") === -1;

                            if (hasKey2) {
                                if (currentRecordIDValue.length > 1 && currentRecordIDValue[1] !== undefined) {
                                    updateData[id2FieldName] = currentRecordIDValue[1];
                                }
                            }

                            // Thực hiện update shared grid
                            window.updateSharedGridRow("GridConfigKPI", updateData);

                            // Kiểm tra và cập nhật biến DataSource cục bộ
                            if (typeof DataSource !== "undefined" && Array.isArray(DataSource)) {
                                var ds;
                                if (!hasKey2) {
                                    // Trường hợp 1 khóa
                                    ds = DataSource.filter(item => item["ID"] === updateData["ID"]);
                                } else {
                                    // Trường hợp 2 khóa
                                    ds = DataSource.filter(item =>
                                        item["ID"] === updateData["ID"] &&
                                        item[id2FieldName] === updateData[id2FieldName]
                                    );
                                }

                                if (ds && ds.length > 0) {
                                    ds[0]["Coin"] = updateData["Coin"];
                                }
                            }
                        } catch (dsErr) {
                            console.warn("[Grid Sync] NumberBox CoinPDA740F856FEC433F915E379487DC78DF: Không thể sync shared grid data source:", dsErr);
                        }
                    }
                }

                if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {
                    try {
                        const grid = cellInfo.component;
                        grid.cellValue(cellInfo.rowIndex, "Coin", val);
                        grid.repaint();
                    } catch (syncErr) {
                        console.warn("[Grid Sync] NumberBox CoinPDA740F856FEC433F915E379487DC78DF: Error", syncErr);
                    }
                }
            } catch (err) {
                console.error("NumberBox Save Error:", err);
            }
        }

        let CoinPDA740F856FEC433F915E379487DC78DFRealInstance = $("#PDA740F856FEC433F915E379487DC78DF").dxNumberBox({
            stylingMode: "underlined",
            format: "#,##0",
            showSpinButtons: false,
            showClearButton: false,
            width: "100%",
            elementAttr: { class: "hpa-dx-numberbox-inline" },
            readOnly: _readOnlyCoinPDA740F856FEC433F915E379487DC78DF,
            onContentReady: function (e) {
                if (!$("#custom-style-underlined-CoinPDA740F856FEC433F915E379487DC78DF").length) {
                    $("<style>").attr("id", "custom-style-underlined-CoinPDA740F856FEC433F915E379487DC78DF").text(" .dx-texteditor.dx-editor-underlined::after { border-bottom-color: #ddd !important; } .dx-texteditor.dx-editor-underlined.dx-state-focused::after { border-bottom-color: #337ab7 !important; border-bottom-width: 2px !important; } ").appendTo("head");
                }
            },
            onKeyDown: function (e) {
                if (e.event.key === "Enter") {
                    e.event.preventDefault();
                    if (_autoSaveCoinPDA740F856FEC433F915E379487DC78DF) {
                        NumberBoxSaveLogicCoin();
                    }
                }
            },
            onValueChanged: async (e) => {
                if (_autoSaveCoinPDA740F856FEC433F915E379487DC78DF) {
                    clearTimeout(CoinTimeOut);
                    e.event && await NumberBoxSaveLogicCoin();
                } else {
                    if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {
                        const grid = cellInfo.component;
                        grid.cellValue(cellInfo.rowIndex, "Coin", e.value);
                    }
                }

                // Real-time calculation: Coin_BonusPerItem = Coin / KPI_required
                if (typeof InstanceKPI_requiredPCA32840E4FB241388D141634E36C763C !== "undefined" &&
                    typeof InstanceCoin_BonusPerItemPC69BC341ED5841C798845AC822C26FCA !== "undefined") {
                    const kpiRequired = InstanceKPI_requiredPCA32840E4FB241388D141634E36C763C.option("value");
                    const coin = e.value || 0;
                    const coinBonusPerItem = (kpiRequired && kpiRequired > 0) ? (coin / kpiRequired) : 0;
                    InstanceCoin_BonusPerItemPC69BC341ED5841C798845AC822C26FCA.option("value", coinBonusPerItem);
                }
            },
            onKeyUp: (e) => {
                if (_autoSaveCoinPDA740F856FEC433F915E379487DC78DF) {
                    clearTimeout(CoinTimeOut);
                    CoinTimeOut = setTimeout(async () => NumberBoxSaveLogicCoin(), 1000);
                }
            }
        }).dxNumberBox("instance");

        /* =============== Public API =============== */
        InstanceCoinPDA740F856FEC433F915E379487DC78DF = {
            option: function (name, value) {

                if (value !== undefined) {
                    return CoinPDA740F856FEC433F915E379487DC78DFRealInstance.option(name, value);
                } else {
                    return CoinPDA740F856FEC433F915E379487DC78DFRealInstance.option(name);
                }
            },
            repaint: function () {
                CoinPDA740F856FEC433F915E379487DC78DFRealInstance.repaint();
            },
            focus: function () {
                CoinPDA740F856FEC433F915E379487DC78DFRealInstance.focus();
            },
            _suppressValueChangeAction: function () {
                // NumberBox không hỗ trợ method này
            },
            _resumeValueChangeAction: function () {
                // NumberBox không hỗ trợ method này
            }
        };

        '
            + (select loadUI from tblCommonControlType_Signed where UID = 'P99BE835E820540B0B555475634369742')
        + (select loadUI from tblCommonControlType_Signed where UID = 'P79246E015FF042BD8BBF5CE4BC06CF8A')
        +(select loadUI from tblCommonControlType_Signed where UID = 'P811BD1D510B745C599591201AE86927E')
        +(select loadUI from tblCommonControlType_Signed where UID = 'P5B1413F12E1F4B48AA0628E5DC980523')
        +(select loadUI from tblCommonControlType_Signed where UID = 'P0DB085F51685461082210C31F2596A6E')
        +(select loadUI from tblCommonControlType_Signed where UID = 'P914C917F26C941FB85DEDA0CDD8934B2')
        +(select loadUI from tblCommonControlType_Signed where UID = 'PC69BC341ED5841C798845AC822C26FCA')
        +(select loadUI from tblCommonControlType_Signed where UID = 'P025272E283ED4578A2D5F096CCC91AF1') +N'

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
        if ("sp_EmployeeListDataMultiSelect" && "sp_EmployeeListDataMultiSelect".trim() !== "") {
            loadDataSourceCommon("NVKPI_ID", "sp_EmployeeListDataMultiSelect", function (data) {
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

        // Function to configure toolbar for grid instance
        function configureKpiGridToolbar(gridInstance) {
            if (!gridInstance) return;

            gridInstance.option("toolbar", {
                items: [
                    {
                        location: "before",
                        template: function (data, index, element) {
                            const $container = $(''<div class="kpi-filter" style="display: flex; gap: 10px; align-items: center; flex-wrap: wrap;">'');

                            // From Date
                            const $fromDiv = $(''<div style="display: flex; align-items: center; gap: 5px; min-width: 120px;">'');
                            $fromDiv.append(''<label style="font-size: 11px; color: #64748b; white-space: nowrap;">Từ:</label>'');
                            $fromDiv.append(''<input type="date" id="setupKPIFromDate" style="padding: 6px; border: 1px solid #ccc; border-radius: 4px; font-size: 12px; width: 140px;">'');

                            // To Date
                            const $toDiv = $(''<div style="display: flex; align-items: center; gap: 5px; min-width: 120px;">'');
                            $toDiv.append(''<label style="font-size: 11px; color: #64748b; white-space: nowrap;">Đến:</label>'');
                            $toDiv.append(''<input type="date" id="setupKPIToDate" style="padding: 6px; border: 1px solid #ccc; border-radius: 4px; font-size: 12px; width: 140px;">'');

                            // Employee filter
                            const $employeeDiv = $(''<div style="display: flex; align-items: center; gap: 5px; min-width: 180px;">'');
                            $employeeDiv.append(''<label style="font-size: 11px; color: #64748b; white-space: nowrap;">Nhân viên:</label>'');
                            $employeeDiv.append($(''<div id="setupKPIEmployeeToolbar" style="width: 200px;"></div>''));

                            // Action buttons
                            const $searchBtn = $(''<button class="btn btn-success" id="setupKPISearchBtn" style="padding: 6px 12px; color: white; border: none; border-radius: 4px; font-size: 12px; cursor: pointer; white-space: nowrap;"><i class="bi bi-filter"></i> Tìm kiếm</button>'');
                            const $resetBtn = $(''<button class="btn btn-outline-success" id="setupKPIResetBtn" style="border: 1px solid #198754; padding: 6px 12px; font-size: 12px; cursor: pointer; white-space: nowrap;"><i class="bi bi-arrow-clockwise"></i> Làm mới</button>'');

                            $container.append($employeeDiv, $fromDiv, $toDiv, $searchBtn, $resetBtn);

                            // Insert before dx-toolbar-items-container
                            $(element).parent().prepend($container);

                            // Initialize default dates and employee list
                            setTimeout(() => {
                                const today = new Date();
                                const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
                                const fromDate = firstDayOfMonth.toISOString().split(''T'')[0];
                                const toDate = today.toISOString().split(''T'')[0];

                                $(''#setupKPIFromDate'').val(fromDate);
                                $(''#setupKPIToDate'').val(toDate);

                                // Attach event handlers
                                $(''#setupKPISearchBtn'').off(''click'').on(''click'', function () {
                                    filterKpiData();
                                });

                                $(''#setupKPIResetBtn'').off(''click'').on(''click'', function () {
                                    resetKpiFilter();
                                });
                            }, 100);
                        }
                    },
                    {
                        location: "after",
                        widget: "dxButton",
                        options: {
                            icon: "columnchooser",
                            hint: "Column Chooser",
                            onClick: function () {
                                gridInstance.showColumnChooser();
                            }
                        }
                    },
                    {
                        location: "after",
                        name: "searchPanel"
                    }
                ]
            });
        }

        // Filter function
        function filterKpiData() {
            const fromDate = $(''#setupKPIFromDate'').val();
            const toDate = $(''#setupKPIToDate'').val();
            const employeeId = InstanceFullNameP99BE835E820540B0B555475634369742?.getValueAsString() || null;

            if (fromDate > toDate) {
                uiManager.showAlert({ type: "error", message: "Từ ngày phải nhỏ hơn đến ngày" });
                return;
            }

            ReloadDataWithFilter(fromDate, toDate, employeeId);
        }

        // Reset filter function
        function resetKpiFilter() {
            const today = new Date();
            const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);

            $(''#setupKPIFromDate'').val(firstDayOfMonth.toISOString().split(''T'')[0]);
            $(''#setupKPIToDate'').val(today.toISOString().split(''T'')[0]);

            // Reset employee filter
            if (InstanceFullNameP99BE835E820540B0B555475634369742) {
                InstanceFullNameP99BE835E820540B0B555475634369742.option("value", null);
            }

            // Reload data with reset filters
            ReloadDataWithFilter(
                firstDayOfMonth.toISOString().split(''T'')[0],
                today.toISOString().split(''T'')[0],
                null
            );
        }

        // Export function
        function exportKpiData() {
            const gridInstance = InstanceGridConfigKPIP79246E015FF042BD8BBF5CE4BC06CF8A;
            if (!gridInstance) return;

            // Show loading
            uiManager.showAlert({ type: "info", message: "Đang xuất dữ liệu..." });

            // Export to Excel
            gridInstance.exportToExcel(false);
        }

        function ReloadData() {
            // Set default date range (current month)
            const today = new Date();
            const firstDayOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
            const fromDate = firstDayOfMonth.toISOString().split(''T'')[0];
            const toDate = today.toISOString().split(''T'')[0];
            const employeeId = InstanceFullNameP99BE835E820540B0B555475634369742?.getValueAsString() || null;

            const params = [
                "FromDate", fromDate,
                "ToDate", toDate,
                "LoginID", UserID
            ];

            if (employeeId) {
                params.push("EmployeeID", employeeId);
            }

            AjaxHPAParadise({
                data: {
                    name: "sp_CRM_ListEmployeeConfigKPI",
                    param: params
                },
                success: function (res) {
                    const json = typeof res === "string" ? JSON.parse(res) : res;
                    const results = Array.isArray(json?.data?.[0])
                        ? json.data[0]
                    : (json?.data?.[0] ? [json.data[0]] : []);

                    const obj = results.length === 1 ? results[0] : (results[0] || null);


                    // Xử lý cho grid layout
                    const gridInstance = InstanceGridConfigKPIP79246E015FF042BD8BBF5CE4BC06CF8A;
                    const gridConfig = window.getGridConfig_GridConfigKPI(results);

                    gridInstance.beginUpdate();

                    gridInstance.option("scrolling", {
                        mode: "standard",
                        showScrollbar: "onHover"
                    });

                    gridInstance.option("remoteOperations", false);  // Client-side cho <= 1000

                    // Set paging config
                    gridInstance.option("paging.enabled", true);
                    gridInstance.option("paging.pageSize", gridConfig.pageSize);
                    gridInstance.option("pager.allowedPageSizes", gridConfig.allowedPageSizes);
                    gridInstance.pageIndex(0);

                    gridInstance.option("dataSource", results);

                    // Configure toolbar
                    if (!kpiToolbarConfigured) {
                        configureKpiGridToolbar(gridInstance);
                        kpiToolbarConfigured = true;
                    }

                    gridInstance.endUpdate();

                    if (obj) { window.currentRecordID_ID = (obj.ID !== undefined && obj.ID !== null) ? obj.ID : window.currentRecordID_ID; }
                    DataSource = results;


            // Move employee filter to toolbar
            setTimeout(() => {
                const employeeFilterWrapper = document.getElementById("setupKPIEmployeeToolbar");
                if (employeeFilterWrapper && employeeFilterWrapper.children.length === 0) {
                    const originalEmployee = document.getElementById("P99BE835E820540B0B555475634369742");
                    if (originalEmployee && originalEmployee.parentElement) {
                        const employeeDiv = originalEmployee.parentElement.querySelector("div");
                        if (employeeDiv) {
                            employeeFilterWrapper.appendChild(employeeDiv);
                        }
                    }
                }
            }, 300);
        }
    })
        }

    function ReloadDataWithFilter(fromDate, toDate, employeeId) {
        const params = [
            "FromDate", fromDate,
            "ToDate", toDate,
            "LoginID", UserID,
        ];

        if (employeeId) {
            params.push("EmployeeID", employeeId);
        }

        AjaxHPAParadise({
            data: {
                name: "sp_CRM_ListEmployeeConfigKPI",
                param: params
            },
            success: function (res) {
                const json = typeof res === "string" ? JSON.parse(res) : res;
                const results = Array.isArray(json?.data?.[0])
                    ? json.data[0]
                    : (json?.data?.[0] ? [json.data[0]] : []);

                const gridInstance = InstanceGridConfigKPIP79246E015FF042BD8BBF5CE4BC06CF8A;
                const gridConfig = window.getGridConfig_GridConfigKPI(results);

                gridInstance.beginUpdate();

                gridInstance.option("scrolling", {
                    mode: "standard",
                    showScrollbar: "onHover"
                });

                gridInstance.option("remoteOperations", false);

                gridInstance.option("paging.enabled", true);
                gridInstance.option("paging.pageSize", gridConfig.pageSize);
                gridInstance.option("pager.allowedPageSizes", gridConfig.allowedPageSizes);
                gridInstance.pageIndex(0);

                gridInstance.option("dataSource", results);
                gridInstance.endUpdate();

                DataSource = results;
            }
        });
    }

    function openDetailID(obj) {
        window.currentRecordID_ID = obj.ID;

        // Save old data for comparison
        oldKpiData = {
            NVKPI_ID: obj.NVKPI_ID,
            KPI_ID: obj.KPI_ID,
            DVT_ID: obj.DVT_ID,
            KPI_required: obj.KPI_required,
            ExperiencePoints: obj.ExperiencePoints,
            Coin: obj.Coin,
            BonusPerItem: obj.BonusPerItem,
            Coin_BonusPerItem: obj.Coin_BonusPerItem,
            EffectiveDate: obj.EffectiveDate
        };

        // Show delete button when editing
        $(''#deleteKpiConfig'').show();

        // _autoSaveNVKPI_IDP811BD1D510B745C599591201AE86927E = false;
        // _autoSaveDVT_IDP5B1413F12E1F4B48AA0628E5DC980523 = true;
        // _autoSaveKPI_IDP0DB085F51685461082210C31F2596A6E = true;
        // _autoSaveKPI_requiredPCA32840E4FB241388D141634E36C763C = true;
        // _autoSaveExperiencePointsPDEFEC5963ABD4874933EC47D2428A046 = true;
        // _autoSaveBonusPerItemP914C917F26C941FB85DEDA0CDD8934B2 = true;
        // _autoSaveCoin_BonusPerItemPC69BC341ED5841C798845AC822C26FCA = true;
        // _autoSaveEffectiveDateP025272E283ED4578A2D5F096CCC91AF1 = true;
        // _autoSaveCoinPDA740F856FEC433F915E379487DC78DF = true;

        '
            + (select loadData from tblCommonControlType_Signed where UID = 'P811BD1D510B745C599591201AE86927E')
        +(select loadData from tblCommonControlType_Signed where UID = 'P5B1413F12E1F4B48AA0628E5DC980523')
        +(select loadData from tblCommonControlType_Signed where UID = 'P0DB085F51685461082210C31F2596A6E')
        +(select loadData from tblCommonControlType_Signed where UID = 'PCA32840E4FB241388D141634E36C763C')
        +(select loadData from tblCommonControlType_Signed where UID = 'PDEFEC5963ABD4874933EC47D2428A046')
        +(select loadData from tblCommonControlType_Signed where UID = 'P914C917F26C941FB85DEDA0CDD8934B2')
        +(select loadData from tblCommonControlType_Signed where UID = 'PDA740F856FEC433F915E379487DC78DF')
        +(select loadData from tblCommonControlType_Signed where UID = 'P025272E283ED4578A2D5F096CCC91AF1')
        +N'

        InstanceNVKPI_IDP811BD1D510B745C599591201AE86927E.option("disabled", true);

        $(''#kpiSetupModal'').modal(''show'');
    }

    // Open modal for adding new KPI config
    $(''#btnAddKPI'').on(''click'', function () {
        // Reset form
        window.currentRecordID_ID = null;
        oldKpiData = {}; // Clear old data for new record
        const today = new Date().toISOString();

        // Hide delete button when adding new
        $(''#deleteKpiConfig'').hide();

        _autoSaveNVKPI_IDP811BD1D510B745C599591201AE86927E = false;
        _autoSaveDVT_IDP5B1413F12E1F4B48AA0628E5DC980523 = false;
        _autoSaveKPI_IDP0DB085F51685461082210C31F2596A6E = false;
        _autoSaveKPI_requiredPCA32840E4FB241388D141634E36C763C = false;
        _autoSaveExperiencePointsPDEFEC5963ABD4874933EC47D2428A046 = false;
        _autoSaveBonusPerItemP914C917F26C941FB85DEDA0CDD8934B2 = false;
        _autoSaveCoin_BonusPerItemPC69BC341ED5841C798845AC822C26FCA = false;
        _autoSaveEffectiveDateP025272E283ED4578A2D5F096CCC91AF1 = false;
        _autoSaveCoinPDA740F856FEC433F915E379487DC78DF = false;

        InstanceNVKPI_IDP811BD1D510B745C599591201AE86927E.option("disabled", false);

        let obj = {
            NVKPI_ID: null,
            KPI_ID: null,
            DVT_ID: null,
            KPI_required: null,
            ExperiencePoints: null,
            Coin: null,
            EffectiveDate: today
        };

        '
            + (select loadData from tblCommonControlType_Signed where UID = 'P811BD1D510B745C599591201AE86927E')
        + (select loadData from tblCommonControlType_Signed where UID = 'P5B1413F12E1F4B48AA0628E5DC980523')
    +(select loadData from tblCommonControlType_Signed where UID = 'P0DB085F51685461082210C31F2596A6E')
    +(select loadData from tblCommonControlType_Signed where UID = 'PCA32840E4FB241388D141634E36C763C')
    +(select loadData from tblCommonControlType_Signed where UID = 'PDEFEC5963ABD4874933EC47D2428A046')
    +(select loadData from tblCommonControlType_Signed where UID = 'P914C917F26C941FB85DEDA0CDD8934B2')
    +(select loadData from tblCommonControlType_Signed where UID = 'PDA740F856FEC433F915E379487DC78DF')
    +(select loadData from tblCommonControlType_Signed where UID = 'P025272E283ED4578A2D5F096CCC91AF1')
    +N'

    // Show modal
    $(''#kpiSetupModal'').modal(''show'');
        });

    // Save KPI configuration
    $(''#saveKpiConfig'').on(''click'', function () {
        // Get values from instances
        const nvkpiId = InstanceNVKPI_IDP811BD1D510B745C599591201AE86927E?.option("value");
        const kpiId = InstanceKPI_IDP0DB085F51685461082210C31F2596A6E?.option("value");
        const dvtId = InstanceDVT_IDP5B1413F12E1F4B48AA0628E5DC980523?.option("value");
        const kpiRequired = KPI_requiredPCA32840E4FB241388D141634E36C763CRealInstance?.option("value");
        const experiencePoints = ExperiencePointsPDEFEC5963ABD4874933EC47D2428A046RealInstance?.option("value");
        const bonusPerItem = InstanceBonusPerItemP914C917F26C941FB85DEDA0CDD8934B2?.option("value");
        const coin = CoinPDA740F856FEC433F915E379487DC78DFRealInstance?.option("value");
        const coinBonusPerItem = InstanceCoin_BonusPerItemPC69BC341ED5841C798845AC822C26FCA?.option("value");
        const effectiveDate = InstanceEffectiveDateP025272E283ED4578A2D5F096CCC91AF1?.option("value");

        // Validate required fields
        if (!nvkpiId || !kpiId || !dvtId || !kpiRequired || !experiencePoints || !coin || !effectiveDate) {
            uiManager.showAlert({ type: "error", message: "Vui lòng nhập đủ các trường thông tin bắt buộc!" });
            return;
        }

        // Prepare API data
        const apiData = {
            NVKPI_ID: nvkpiId,
            KPI_ID: kpiId,
            DVT_ID: dvtId,
            KPI_required: parseFloat(kpiRequired) || 0,
            ExperiencePoints: parseFloat(experiencePoints) || 0,
            BonusPerItem: parseFloat(bonusPerItem) || 0,
            Coin_BonusPerItem: parseFloat(coinBonusPerItem) || 0,
            EffectiveDate: effectiveDate,
            CreateDate: new Date().toISOString().split("T")[0],
            Coin: parseFloat(coin) || 0,
            ID: window.currentRecordID_ID || null,
        };

        // Check if data has changed (only for edit, not for new)
        if (window.currentRecordID_ID && Object.keys(oldKpiData).length > 0) {
            const hasChanges =
                oldKpiData.NVKPI_ID !== apiData.NVKPI_ID ||
                oldKpiData.KPI_ID !== apiData.KPI_ID ||
                oldKpiData.DVT_ID !== apiData.DVT_ID ||
                oldKpiData.KPI_required !== apiData.KPI_required ||
                oldKpiData.ExperiencePoints !== apiData.ExperiencePoints ||
                oldKpiData.Coin !== apiData.Coin ||
                oldKpiData.EffectiveDate !== apiData.EffectiveDate;

            if (!hasChanges) {
                 $("#kpiSetupModal").modal("hide");

                return;
            }
        }

        // Call API to save
        AjaxHPAParadise({
            data: {
                name: "sp_CRM_SaveConfigKPI",
                param: ["apiData", JSON.stringify(apiData)]
            },
            success: function (data) {
                try {
                    if (typeof data === "string" && !IsNullOrEmpty(data)) {
                        data = data.includes("{") ? data : EncryptionStringDecryption(data);
                    }
                    const result = JSON.parse(data);

                    if (result.data && result.data[0] && result.data[0].length > 0) {
                        const response = result.data[0][0];

                        if (response.Result === "SUCCESS" || response.Result === "UPDATED" || response.Result === "INSERTED") {
                            uiManager.showAlert({ type: "success", message: "Lưu cấu hình KPI thành công!" });
                            $("#kpiSetupModal").modal("hide");

                            // Reload grid data
                            ReloadData();
                        } else {
                            uiManager.showAlert({ type: "error", message: "%KPI_OVERLAP_PERIOD%" });
                        }
                    } else {
                        uiManager.showAlert({ type: "error", message: "Có lỗi xảy ra khi xử lý dữ liệu!" });
                    }
                } catch (e) {
                    console.error("Parse error:", e);
                    uiManager.showAlert({ type: "error", message: "Có lỗi xảy ra khi xử lý phản hồi!" });
                }
            },
            error: function (error) {
                console.error("Error saving KPI config:", error);
                uiManager.showAlert({ type: "error", message: "Có lỗi xảy ra khi lưu cấu hình KPI!" });
            }
        });
    });

    // Delete KPI configuration
    $(''#deleteKpiConfig'').on(''click'', function () {
        if (!window.currentRecordID_ID) {
            uiManager.showAlert({ type: "error", message: "Không có cấu hình để xóa!" });
            return;
        }

        showConfirmPopup({
            title: "Xác nhận xóa?",
            message: "Bạn có chắc chắn muốn xóa thiết lập KPI này?",
            YesText: "Xóa",
            NoText: "Hủy",

            onYes: async () => {
                const result = await updateOrDeleteDataExample(''tblCRM_KPI_Setup'', 2, [{ ID: window.currentRecordID_ID }]);
                if(result){
                    uiManager.showAlert({ type: "success", message: "Xóa thiết lập KPI thành công!" });
                    $("#kpiSetupModal").modal("hide");
                    document.getElementById("kpiConfigForm").reset();
                    // Reload grid data
                    ReloadData();
                }else{
                    uiManager.showAlert({ type: "error", message: "Xóa thiết lập KPI thất bại!" });
                }

            },
            onNo: () => {

            }
        });
    });

    ReloadData()
    }) ();
</script>
	'

    SELECT @html AS html;
	-- exec sptblCommonControlType_Signed_DUC 'sp_CRM_ListConfigKPI_html'
    -- EXEC sp_GenerateHTMLScript_new 'sp_CRM_ListConfigKPI_html'
    -- EXEC sp_GenerateHTMLScript 'sp_Dashboard_Mobile_beta'
END
