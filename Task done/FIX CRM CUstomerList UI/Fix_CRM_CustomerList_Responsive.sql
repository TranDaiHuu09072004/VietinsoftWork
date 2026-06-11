
IF OBJECT_ID('[dbo].[sp_CRM_CustomerList_html]') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[sp_CRM_CustomerList_html] AS SELECT 1')
GO

-- ============================================================
-- RENDERER sp_CRM_CustomerList_html — Chuẩn ParadiseStyle & Skill 17
-- ============================================================
ALTER PROCEDURE dbo.sp_CRM_CustomerList_html
(
    @LoginID    INT          = 3,
    @LanguageID VARCHAR(5)   = 'VN',
    @isWeb      INT          = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Load UI cấu hình từ tblCommonControlType_Signed (UID cố định)
    DECLARE @loadUI NVARCHAR(MAX) = N'';
    SELECT @loadUI = ISNULL(loadUI, N'') 
    FROM dbo.tblCommonControlType_Signed 
    WHERE UID = 'PED6A4AAAA14F4706822A32B2859DDDAD';

    -- 2. Build HTML + CSS + JS
    DECLARE @html NVARCHAR(MAX) = N'';

    SET @html = N'
<style>
    .crm-customer-list-page,
    .crm-customer-list-page #gridCustomerList {
        width: 100%;
        max-width: 100%;
        overflow-x: hidden;
        box-sizing: border-box;
    }

    .crm-customer-list-page #gridCustomerList .dx-scrollable-container::-webkit-scrollbar,
    .crm-customer-list-page #gridCustomerList .dx-datagrid-rowsview::-webkit-scrollbar {
        height: 8px;
        width: 8px;
    }

    .crm-customer-list-page #gridCustomerList .dx-scrollable-container::-webkit-scrollbar-thumb,
    .crm-customer-list-page #gridCustomerList .dx-datagrid-rowsview::-webkit-scrollbar-thumb {
        background: var(--paradise-border-color);
        border-radius: var(--paradise-border-radius-pill);
    }

    .crm-customer-list-page #gridCustomerList .dx-toolbar {
        height: auto !important;
    }
    .crm-customer-list-page #gridCustomerList .dx-toolbar .dx-toolbar-items-container {
        height: auto !important;
        min-height: 52px;
        padding: var(--paradise-space-2) 0;
        display: flex !important;
        flex-wrap: wrap;
        align-items: center;
        justify-content: space-between;
        gap: 15px;
    }
    .crm-customer-list-page #gridCustomerList .dx-toolbar-before,
    .crm-customer-list-page #gridCustomerList .dx-toolbar-center,
    .crm-customer-list-page #gridCustomerList .dx-toolbar-after {
        position: relative !important;
        transform: none !important;
        top: auto !important;
        left: auto !important;
        right: auto !important;
        display: flex !important;
        align-items: center;
        padding: 0 !important;
    }
    .crm-customer-list-page #gridCustomerList .dx-toolbar-before {
        flex: 0 1 auto;
        flex-wrap: wrap;
        min-width: 0;
    }
    
    /* GHI ĐÈ INLINE STYLE - Nguyên nhân gây rớt dòng trên Desktop */
    .crm-customer-list-page .ms-filter-toolbar {
        width: auto !important; 
    }

    .crm-customer-list-page #gridCustomerList .dx-toolbar-after {
        flex: 1 1 250px;
        flex-wrap: nowrap !important; /* Đảm bảo Column Chooser và Search nằm trên 1 hàng */
        justify-content: flex-end;
        min-width: 200px;
        gap: 10px;
    }
    
    /* Thu gọn ô tìm kiếm search ngắn lại - theo yêu cầu người dùng */
    .crm-customer-list-page #gridCustomerList .dx-toolbar-after .dx-item {
        flex: 0 0 auto !important;
    }
    .crm-customer-list-page #gridCustomerList .dx-toolbar-after .dx-item:has(.dx-datagrid-search-panel) {
        flex: 0 0 220px !important;
        width: 220px !important;
        max-width: 220px !important;
    }
    .crm-customer-list-page #gridCustomerList .dx-datagrid-search-panel {
        width: 220px !important;
        max-width: 220px !important;
    }

    /* Tablet & Mobile (Hiển thị 3 hàng) */
    @media (max-width: 850px) {
        .crm-customer-list-page #gridCustomerList .dx-toolbar-before,
        .crm-customer-list-page #gridCustomerList .dx-toolbar-after {
            flex: 1 1 100% !important;
            width: 100% !important;
            justify-content: flex-start !important;
        }
        .crm-customer-list-page .ms-filter-toolbar {
            width: 100% !important;
        }
        /* Hàng 1 (Chọn nhân viên) và Hàng 2 (Nút trạng thái) */
        .crm-customer-list-page .ms-filter-toolbar > div {
            flex-direction: column !important;
            align-items: flex-start !important;
            gap: 10px !important;
            width: 100%;
        }
        .crm-customer-list-page #emailFilterEmployeeToolbarsp_CRM_CustomerList {
            width: 100% !important;
            max-width: 100% !important;
        }
        
        /* Bộ lọc trạng thái trên màn hình nhỏ vẫn giữ hàng ngang, tự wrap khi quá hẹp */
        .stock-filter {
            width: auto !important;
            display: inline-flex !important;
            flex-direction: row !important;
            flex-wrap: wrap !important;
            justify-content: flex-start !important;
        }
        
        /* Hàng 3 (Tìm kiếm và Tuỳ chọn cột) */
        .crm-customer-list-page #gridCustomerList .dx-toolbar-after {
            margin-top: 10px;
        }
        .crm-customer-list-page #gridCustomerList .dx-toolbar-after .dx-item:has(.dx-datagrid-search-panel) {
            max-width: 100% !important;
            width: 100% !important;
            flex: 1 1 auto !important;
        }
        .crm-customer-list-page #gridCustomerList .dx-datagrid-search-panel {
            width: 100% !important;
            max-width: 100% !important;
        }
    }

    .crm-customer-list-page #gridCustomerList .badge-view {
        text-align: center;
        padding: var(--paradise-space-1) var(--paradise-space-3);
        border-radius: var(--paradise-border-radius-pill);
        font-weight: 500;
        font-size: var(--paradise-font-size-xs, 0.8rem);
        width: fit-content;
        border: 1px solid var(--paradise-border-color);
        white-space: nowrap;
    }

    .crm-customer-list-page #gridCustomerList .badge-view.badge-view-success {
        background-color: var(--paradise-bg-success-subtle);
        color: var(--paradise-color-success);
        border-color: var(--paradise-bg-success-subtle);
    }
    .crm-customer-list-page #gridCustomerList .badge-view.badge-view-danger {
        background-color: var(--paradise-bg-danger-subtle);
        color: var(--paradise-color-danger);
        border-color: var(--paradise-bg-danger-subtle);
    }
    .crm-customer-list-page #gridCustomerList .badge-view.badge-view-warning {
        background-color: var(--paradise-bg-warning-subtle);
        color: var(--paradise-color-warning);
        border-color: var(--paradise-bg-warning-subtle);
    }
    .crm-customer-list-page #gridCustomerList .badge-view.badge-view-info {
        background-color: var(--paradise-bg-info-subtle);
        color: var(--paradise-color-info);
        border-color: var(--paradise-bg-info-subtle);
    }
    .crm-customer-list-page #gridCustomerList .badge-view.badge-view-primary {
        background-color: var(--paradise-bg-primary-subtle);
        color: var(--paradise-color-primary);
        border-color: var(--paradise-bg-primary-subtle);
    }

    /* Định dạng Stock Filter và Stock Button (bỏ bớt cờ crm-customer-list-page để tăng tính bao phủ và fallback an toàn) */
    .stock-filter {
        display: inline-flex !important;
        flex-direction: row !important;
        flex-wrap: nowrap !important;
        justify-content: center;
        align-items: center;
        gap: var(--paradise-space-2, 8px) !important;
        width: fit-content !important;
        max-width: 100% !important;
        border-radius: var(--paradise-border-radius-pill, 30px) !important;
        border: 1px solid var(--paradise-border-color, #444) !important;
        padding: var(--paradise-space-1, 4px) !important;
        position: relative !important;
        background-color: var(--paradise-bg-body, #1e1e24) !important;
        box-sizing: border-box !important;
    }

    .stock-btn {
        border-radius: var(--paradise-border-radius-pill, 30px) !important;
        padding: var(--paradise-space-2, 6px) var(--paradise-space-4, 16px) !important;
        font-size: var(--paradise-font-size-sm, 0.85rem) !important;
        border: none !important;
        background: transparent !important;
        color: var(--paradise-text-muted, #888) !important;
        cursor: pointer !important;
        transition: var(--paradise-transition-fast, all 0.15s ease) !important;
        position: relative !important;
        z-index: 2 !important;
        white-space: nowrap !important;
        font-weight: 600 !important;
        display: inline-flex !important;
        align-items: center !important;
        justify-content: center !important;
    }

    .stock-btn:hover {
        color: var(--paradise-text-body, #fff) !important;
        background-color: rgba(255, 255, 255, 0.05) !important;
    }

    .stock-btn.active {
        background: var(--paradise-color-primary, #28a745) !important;
        color: var(--paradise-text-on-primary, #fff) !important;
        box-shadow: var(--paradise-shadow-sm, 0 1px 3px rgba(0,0,0,0.2)) !important;
    }

    /* Input select-wrapper as premium input field */
    .crm-customer-list-page .crm-emp-select-wrapper {
        background-color: var(--paradise-bg-body);
        border: 1px solid var(--paradise-border-color);
        border-radius: var(--paradise-input-border-radius, var(--paradise-border-radius-md));
        padding: var(--paradise-space-1) var(--paradise-space-3);
        min-height: 38px;
        display: flex;
        align-items: center;
        cursor: pointer;
        transition: border-color 0.15s ease, box-shadow 0.15s ease;
        box-sizing: border-box;
    }
    .crm-customer-list-page .crm-emp-select-wrapper:focus {
        border-color: var(--paradise-color-primary);
        box-shadow: 0 0 0 2px var(--paradise-bg-primary-subtle);
        outline: none;
    }
    .crm-customer-list-page .crm-emp-select-wrapper:hover:not(:focus) {
        border-color: var(--paradise-color-primary);
    }
    .crm-customer-list-page .crm-avatar-group {
        display: flex;
        align-items: center;
    }
    .crm-customer-list-page .crm-avatar-chip {
        width: 32px;
        height: 32px;
        border-radius: var(--paradise-border-radius-pill);
        border: 2px solid var(--paradise-bg-surface);
        box-shadow: var(--paradise-shadow-sm);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 600;
        font-size: 12px;
        position: relative;
        overflow: hidden;
    }
    .crm-customer-list-page .crm-avatar-chip img {
        width: 100%;
        height: 100%;
        object-fit: cover;
    }
    .crm-customer-list-page .crm-avatar-chip-more {
        width: 32px;
        height: 32px;
        border-radius: var(--paradise-border-radius-pill);
        border: 2px solid var(--paradise-bg-surface);
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 700;
        font-size: 11px;
        background-color: var(--paradise-bg-3);
        color: var(--paradise-text-muted);
        box-shadow: var(--paradise-shadow-sm);
    }

    /* Custom Checkbox inside Toolbar */
    .crm-customer-list-page .ms-filter-toolbar input[type="checkbox"] {
        appearance: none;
        -webkit-appearance: none;
        width: 16px;
        height: 16px;
        border: 1.5px solid var(--paradise-border-color);
        border-radius: 3px;
        background-color: var(--paradise-bg-body);
        cursor: pointer;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        position: relative;
        transition: var(--paradise-transition-fast);
    }
    .crm-customer-list-page .ms-filter-toolbar input[type="checkbox"]:hover {
        border-color: var(--paradise-color-primary);
    }
    .crm-customer-list-page .ms-filter-toolbar input[type="checkbox"]:checked {
        background-color: var(--paradise-color-primary);
        border-color: var(--paradise-color-primary);
    }
    .crm-customer-list-page .ms-filter-toolbar input[type="checkbox"]:checked::after {
        content: "";
        position: absolute;
        left: 4.5px;
        top: 1.5px;
        width: 5px;
        height: 9px;
        border: solid #fff;
        border-width: 0 2px 2px 0;
        transform: rotate(45deg);
    }

    /* Grid avatar classes */
    .crm-customer-list-page .crm-cell-avatar-wrapper {
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100%;
    }
    .crm-customer-list-page .crm-cell-avatar {
        width: 36px;
        height: 36px;
        border-radius: var(--paradise-border-radius-pill);
        object-fit: cover;
        border: 2px solid var(--paradise-border-color);
        box-shadow: var(--paradise-shadow-sm);
        display: flex;
        justify-content: center;
        align-items: center;
        font-weight: 600;
        font-size: 13px;
    }

    .crm-customer-list-page #gridCustomerList .dx-datagrid-rowsview .dx-row > td > div {
        white-space: nowrap !important;
    }
</style>
<div id="sp_GridEmployeeID_html" class="crm-customer-list-page">
    <div style="display: none;">
        <div id="GridEmployeeID"></div>
    </div>
    <div id="gridCustomerList" style="height: 90%;"></div>
</div>

<script>
    (() => {
        let fromDateValue = null, toDateValue = null, isViewNewContract = false, isViewAllData = true;
        let DataSource = [];
        let _pageCache = {};
        let _currentKeyword = "";
        let _activeArrEmployeeID = "";
        let api = true;
        let InstanceFromDate, InstanceToDate;
';

    -- Nối loadUI động
    SET @html = @html + ISNULL(@loadUI, N'') + N'

        // Load DataSource: sp_CRM_getCompanySize
        if ("sp_CRM_getCompanySize" && "sp_CRM_getCompanySize".trim() !== "") {
            loadDataSourceCommon("CompanySize_ID", "sp_CRM_getCompanySize", function (data) {
                // Data được shared qua callback
            });
        }

        // Load DataSource: sp_CRM_getIndustry
        if ("sp_CRM_getIndustry" && "sp_CRM_getIndustry".trim() !== "") {
            loadDataSourceCommon("Industry_ID", "sp_CRM_getIndustry", function (data) {
                // Data được shared qua callback
            });
        }

        function loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback) {
            if (!columnName || !dataSourceSP || dataSourceSP.trim() === "") {
                console.warn("[loadDataSourceCommon] Missing columnName or dataSourceSP");
                return;
            }

            const dataSourceKey = "DataSource_" + columnName;
            const loadedKey = columnName + "DataSourceLoaded";

            if (window[loadedKey] === true) {
                if (typeof onSuccessCallback === "function") {
                    onSuccessCallback(window[dataSourceKey] || []);
                }
                return;
            }

            if (window[loadedKey] === "loading") {
                setTimeout(function () {
                    loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback);
                }, 100);
                return;
            }

            window[loadedKey] = "loading";

            AjaxHPAParadise({
                data: {
                    name: dataSourceSP,
                    param: ["LoginID", LoginID, "LanguageID", LanguageID]
                },
                success: function (res) {
                    const json = typeof res === "string" ? JSON.parse(res) : res;
                    window[dataSourceKey] = (json.data && json.data[0]) || [];

                    window[loadedKey] = true;

                    if (typeof onSuccessCallback === "function") {
                        onSuccessCallback(window[dataSourceKey]);
                    }

                    const instanceVariants = [
                        "Instance" + columnName.charAt(0).toUpperCase() + columnName.slice(1) + "PED6A4AAAA14F4706822A32B2859DDDAD",
                        "Instance" + columnName + "PED6A4AAAA14F4706822A32B2859DDDAD",
                        "instance" + columnName.charAt(0).toUpperCase() + columnName.slice(1) + "PED6A4AAAA14F4706822A32B2859DDDAD"
                    ];

                    for (let i = 0; i < instanceVariants.length; i++) {
                        const instanceKey = instanceVariants[i];

                        if (window[instanceKey] || instanceKey) {
                            const instanceObj = window[instanceKey] || instanceKey;

                            if (typeof instanceObj.dxDataGrid === "function" || instanceObj.option && instanceObj.option("dataSource") !== undefined) {
                                try {
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
                                    // Continue
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

        window.currentRecordID_Company_ID = null;

        function clearPageCache() {
            _pageCache = {};
        }

        function getGridHeight() {
            const gridEl = InstancegridCustomerListPED6A4AAAA14F4706822A32B2859DDDAD.element();
            const domElement = gridEl.jquery ? gridEl[0] : gridEl;
            const top = domElement.getBoundingClientRect().top;
            return window.innerHeight - top - 20;
        }

        const dataStore_gridCustomerList = new DevExpress.data.CustomStore({
            key: "ID",
            load: function (loadOptions) {
                const deferred = $.Deferred();
                let arrEmployeeID = InstanceEmployeeIDGridEmployeeID.option("value") || "";
                let paramEmployee = "";
                if (arrEmployeeID) {
                    paramEmployee = `,@arrEmployeeID=''${arrEmployeeID || ''''}''`;
                }

                if (!api) {
                    const results = DataSource || [];
                    const skip = loadOptions.skip || 0;
                    const take = loadOptions.take || 50;
                    const pageData = results.slice(skip, skip + take);
                    deferred.resolve({
                        data: pageData,
                        totalCount: results.length
                    });
                    api = true;
                    return deferred.promise();
                }

                let params = [];
                params.push("@ProcName", "sp_CRM_GetCustomerList");

                let procParam = "@LoginID = " + (window.UserID || window.LoginID) + ", @LanguageID = " + window.LanguageID + ", @Status = " + getFilterOption() + paramEmployee;
                params.push("@ProcParam", procParam);
                console.log(procParam);
                params.push("@Take", loadOptions.take || 50);
                params.push("@Skip", loadOptions.skip || 0);

                if (loadOptions.requireTotalCount) params.push("@RequireTotalCount", 1);

                const sort = loadOptions.sort
                    ? loadOptions.sort.map(s => s.selector + (s.desc ? " DESC" : " ASC")).join(",")
                    : "StatusID";

                params.push("@Sort", "ORDER BY " + sort);

                let keyword = loadOptions.searchValue || _currentKeyword || "";
                if (!keyword) {
                    let searchInput = document.querySelector(".dx-datagrid-search-panel input");
                    if (searchInput) {
                        keyword = searchInput.value.trim();
                    }
                }

                if (keyword) {
                    params.push("@SearchValue", keyword);
                    params.push("@ColumnSearch", "Company,TaxCode,InchargePerson,IP_Email,IP_Phone,ContractName,ContactName,Content");
                }

                if (loadOptions.filter) {
                    const hasFunction = JSON.stringify(loadOptions.filter).includes("FUNCTION");
                    if (!hasFunction) {
                        params.push("@Filters", createConditionQuery(loadOptions.filter));
                    }
                }

                AjaxHPAParadise({
                    data: {
                        name: "sp_LoadGridUsingAPI",
                        param: params
                    },
                    success: function (res) {
                        const json = typeof res === "string" ? JSON.parse(res) : res;
                        const results = Array.isArray(json?.data?.[0]) ? json.data[0] : [];
                        let result = { data: results };

                        if (loadOptions.requireTotalCount) {
                            result.totalCount = json?.data?.[1]?.[0]?.TotalCount ?? 0;
                            if (loadOptions.totalSummary) {
                                result.summary = Object.values(json?.data?.[2]?.[0] ?? {});
                            }
                        } else {
                            if (loadOptions.totalSummary) {
                                result.summary = Object.values(json?.data?.[1]?.[0] ?? {});
                            }
                        }

                        DataSource = results;
                        window.syncSharedGridData("gridCustomerList");
                        deferred.resolve(result);
                    },
                    error: function (err) {
                        deferred.reject("Data Loading Error");
                    }
                });

                return deferred.promise();
            }
        });

        const gridInstance = InstancegridCustomerListPED6A4AAAA14F4706822A32B2859DDDAD;

        gridInstance.beginUpdate();
        gridInstance.option("remoteOperations", {
            paging: true, filtering: true, sorting: true, searching: true
        });

        gridInstance.option({
            "columnAutoWidth": true,
            "columnHidingEnabled": false,
            "scrolling.showScrollbar": "always",
            "scrolling.mode": "infinite",
            "scrolling.rowRenderingMode": "virtual",
            "scrolling.preloadEnabled": false,
            "paging.enabled": true,
            "paging.pageSize": 50,
            "pager.visible": false,
            "searchPanel.highlightSearchText": false,
            "dataSource": dataStore_gridCustomerList,
            "height": getGridHeight()
        });

        gridInstance.option("onOptionChanged", function (e) {
            if (e.name === "searchPanel" && e.fullName === "searchPanel.text") {
                _currentKeyword = (e.value || "").trim();
                _pageCache = {};
            }
        });

        gridInstance.option("onRowClick", function (e) {
            if (!e.data || !e.data.ID) return;

            let CompanyInfo = { Company_ID: e.data.Company_ID, ContractID: e.data.ID };
            window.currentRecordID_Company_ID = e.data.Company_ID;

            const targetForm = "sp_CRM_CustomerDetail";
            const params = {
                LoginID: window.UserID || window.LoginID,
                LanguageID: window.LanguageID,
                Company_ID: CompanyInfo,
                TableName: "sp_CRM_CustomerList",
            };

            openFormParam(targetForm, params);
        });

        gridInstance.option("onToolbarPreparing", function (e) {
            e.toolbarOptions.items.unshift({
                location: "before",
                template: function (data, index, element) {
                    const $wrap = $(
                        `<div class="stock-filter" id="stock-filter-contract-tracking"></div>`,
                    );
                    const filters = [
                        { text: "Tất cả", value: 0 },
                        { text: "Đang hiệu lực", value: 3 },
                        { text: "Sắp tới hạn", value: 2 },
                        { text: "Hết hạn", value: 1 },
                    ];

                    filters.forEach((f) => {
                        const $btn = $(`
                            <div class="stock-btn ${f.value === 0 ? "active" : ""}" data-value="${f.value}">
                                ${f.text}
                            </div>
                        `);

                        $btn.on("click", function () {
                            $wrap.find(".stock-btn").removeClass("active");
                            $(this).addClass("active");
                            gridInstance.refresh();
                        });

                        $wrap.append($btn);
                    });
                    const $container = $(`<div class="ms-filter-toolbar" style="display: flex; flex-direction: column; gap: 12px; width: 100%; box-sizing: border-box; min-height: auto;">`);

                    const $row1 = $(`<div style="display: flex; gap: var(--paradise-space-3); align-items: center; flex-wrap: wrap; width: 100%;">`);

                    const $employeeRow = $(`<div style="display: flex; align-items: center; gap: 8px;">`);             
                    $employeeRow.append(`<div id="emailFilterEmployeeToolbarsp_CRM_CustomerList" style="width: 200px;"></div>`);

                    $row1.append($employeeRow, $wrap);

                    const $row2 = $(`<div style="display: flex; gap: var(--paradise-space-4); align-items: center; flex-wrap: wrap; width: 100%; padding-top: var(--paradise-space-1); border-top: 1px dashed var(--paradise-border-color);">`);

                    const createToggle = (id, label, initialValue, onChange) => {
                        const $wrap = $(`<div style="display: flex; align-items: center; gap: 6px; cursor: pointer;">`);
                        const $check = $(`<input type="checkbox" id="${id}" style="width: 16px; height: 16px; cursor: pointer;">`);
                        $check.prop("checked", initialValue);
                        $check.on("change", function () { onChange($(this).is(":checked")); });
                        $wrap.append($check, `<label for="${id}" style="font-size: 12px; color: var(--paradise-text-muted); margin: 0; cursor: pointer; font-weight: 500;">${label}</label>`);
                        return $wrap;
                    };

                    if (window.EmployeeID_Login || window.UserID) {
                        const $myData = createToggle("toolbarIsOnlyUser", "Xem của tôi", false, (checked) => {
                            if (checked) {
                                InstanceEmployeeIDGridEmployeeID.option("value", window.EmployeeID_Login || window.UserID);
                            } else {
                                InstanceEmployeeIDGridEmployeeID.option("value", null);
                            }
                            ReloadData(InstanceEmployeeIDGridEmployeeID.option("value"));
                        });
                        $row2.append($myData);
                    }

                    $container.append($row1);
                    $(element).append($container);

                    setTimeout(() => {
                        var employeeFilterWrapper = document.getElementById("emailFilterEmployeeToolbarsp_CRM_CustomerList");
                        if (employeeFilterWrapper && employeeFilterWrapper.children.length === 0) {
                            var originalEmployee = document.getElementById("GridEmployeeID");
                            if (originalEmployee && originalEmployee.parentElement) {
                                var employeeDiv = originalEmployee.parentElement.querySelector("div");
                                if (employeeDiv) { employeeFilterWrapper.appendChild(employeeDiv); }
                            }
                        }
                    }, 50);
                }
            });
        });

        gridInstance.columnOption("Content", {
            cellTemplate: function (cellElement, cellInfo) {
                const val = cellInfo.value;

                if (!val) {
                    $("<div>")
                        .addClass("dx-placeholder text-center py-2")
                        .text("--")
                        .appendTo(cellElement);
                    return;
                }

                $("<div>")
                    .addClass(`badge-view badge-view-${cellInfo.data.Color}`)
                    .text(val)
                    .appendTo(cellElement);
            }
        });

        gridInstance.endUpdate();

        function ReloadData(arrEmployeeID = "", fromDate = null, toDate = null, isNewContract = null, isViewAll = null, keyword = null) {
            if (arrEmployeeID !== null && arrEmployeeID !== undefined && arrEmployeeID !== "") {
                _activeArrEmployeeID = arrEmployeeID;
            } else if (arrEmployeeID === "") {
                _activeArrEmployeeID = "";
            }

            if (fromDate !== null) fromDateValue = fromDate;
            if (toDate !== null) toDateValue = toDate;
            if (isNewContract !== null) isViewNewContract = isNewContract;
            if (isViewAll !== null) isViewAllData = isViewAll;
            if (keyword !== null) _currentKeyword = keyword.trim();

            _pageCache = {};
            gridInstance.refresh();
        }

        window.ReloadData_CustomerList = ReloadData;

        window.GlobalEmployeeAvatarCache = window.GlobalEmployeeAvatarCache || {};
        window.GlobalEmployeeAvatarLoading = window.GlobalEmployeeAvatarLoading || {};
        let InstanceEmployeeIDGridEmployeeID = null;

        function loadGlobalAvatarIfNeededEmployeeIDGridEmployeeID(employeeId, storeImgName, paramImg, callbackFn) {
            const idStr = String(employeeId);

            if (window.GlobalEmployeeAvatarCache[idStr]) {
                if (callbackFn) callbackFn(window.GlobalEmployeeAvatarCache[idStr]);
                return window.GlobalEmployeeAvatarCache[idStr];
            }

            if (window.GlobalEmployeeAvatarLoading[idStr]) {
                if (callbackFn) {
                    window.GlobalEmployeeAvatarLoading[idStr].callbacks =
                        window.GlobalEmployeeAvatarLoading[idStr].callbacks || [];
                    window.GlobalEmployeeAvatarLoading[idStr].callbacks.push(callbackFn);
                }
                return null;
            }

            if (!storeImgName) {
                return null;
            }

            window.GlobalEmployeeAvatarLoading[idStr] = {
                loading: true,
                callbacks: callbackFn ? [callbackFn] : []
            };

            let paramArray = [];
            if (paramImg) {
                try {
                    const decoded = decodeURIComponent(paramImg);
                    paramArray = JSON.parse(decoded);
                } catch (e) {
                    paramArray = [];
                }
            }

            AjaxHPAParadise({
                data: {
                    name: storeImgName,
                    param: paramArray
                },
                xhrFields: { responseType: "blob" },
                cache: true,
                success: function (blob) {
                    const callbacks = window.GlobalEmployeeAvatarLoading[idStr]?.callbacks || [];
                    delete window.GlobalEmployeeAvatarLoading[idStr];

                    if (blob && blob.size > 0) {
                        const url = URL.createObjectURL(blob);
                        window.GlobalEmployeeAvatarCache[idStr] = url;

                        callbacks.forEach(cb => {
                            try { cb(url); } catch (e) { console.error(e); }
                        });
                    } else {
                        callbacks.forEach(cb => {
                            try { cb(null); } catch (e) { console.error(e); }
                        });
                    }
                },
                error: function () {
                    const callbacks = window.GlobalEmployeeAvatarLoading[idStr]?.callbacks || [];
                    delete window.GlobalEmployeeAvatarLoading[idStr];

                    callbacks.forEach(cb => {
                        try { cb(null); } catch (e) { console.error(e); }
                    });
                }
            });

            return null;
        }

        window["DataSource_EmployeeIDGridEmployeeID"] = window["DataSource_EmployeeIDGridEmployeeID"] || [];
        let spNameDSEEmployeeIDGridEmployeeID = "sp_EmployeeListDataMultiSelectSelectBox";
        let EmployeeIDGridEmployeeIDSelectedIds = [], EmployeeIDGridEmployeeIDSelectedIdsOriginal = [];
        const MAX_VISIBLE_EmployeeIDGridEmployeeID = 3;
        let _autoSaveEmployeeIDGridEmployeeID = false;
        let _readOnlyEmployeeIDGridEmployeeID = false;
        let EmployeeIDGridEmployeeIDIsSaving = false;

        $(document).ready(function () {
            if (spNameDSEEmployeeIDGridEmployeeID && spNameDSEEmployeeIDGridEmployeeID.trim() !== "") {
                loadDataSourceCommon("EmployeeIDGridEmployeeID", spNameDSEEmployeeIDGridEmployeeID, function (data) {
                    window["DataSource_EmployeeIDGridEmployeeID"] = data || [];
                    if (Array.isArray(data) && data.length > 0) {
                        data.forEach(emp => {
                            hpaUtils.loadAvatar(emp.ID, emp.StoreImgName, emp.ImgParamV);
                        });
                    }

                    if (typeof renderDisplayBoxEmployeeIDGridEmployeeID === "function") {
                        renderDisplayBoxEmployeeIDGridEmployeeID();
                    }
                });
            }
        });

        function getInitialsEmployeeIDGridEmployeeID(name) {
            if (!name) return "?";
            const words = name.trim().split(/\s+/);
            if (words.length >= 2) return (words[0][0] + words[words.length - 1][0]).toUpperCase();
            return name.substring(0, 2).toUpperCase();
        }

        function getColorForIdEmployeeIDGridEmployeeID(id) {
            const colors = [
                { bg: "var(--paradise-bg-primary-subtle)", text: "var(--paradise-color-primary)" },
                { bg: "var(--paradise-bg-success-subtle)", text: "var(--paradise-color-success)" },
                { bg: "var(--paradise-bg-warning-subtle)", text: "var(--paradise-color-warning)" },
                { bg: "var(--paradise-bg-danger-subtle)", text: "var(--paradise-color-danger)" },
                { bg: "var(--paradise-bg-info-subtle)", text: "var(--paradise-color-info)" }
            ];
            const numId = parseInt(id, 10);
            const index = isNaN(numId) ? 0 : Math.abs(numId) % colors.length;
            return colors[index];
        }

        function renderDisplayBoxEmployeeIDGridEmployeeID() {
            if (!$("#EmployeeIDGridEmployeeID_display").length) return;
            $("#EmployeeIDGridEmployeeID_display").empty();

            const $wrapper = $("<div>")
                .addClass("crm-emp-select-wrapper")
                .attr("tabIndex", "0")
                .on("keydown", function (e) {
                    if (e.key === "Enter" || e.key === " " || e.key === "Spacebar") {
                        e.preventDefault();
                        if (_readOnlyEmployeeIDGridEmployeeID) return;
                        if (!popupEmployeeIDGridEmployeeID) {
                            initPopupEmployeeIDGridEmployeeID();
                            setTimeout(() => popupEmployeeIDGridEmployeeID.show(), 0);
                        } else {
                            popupEmployeeIDGridEmployeeID.show();
                        }
                    }
                });

            if (EmployeeIDGridEmployeeIDSelectedIds.length === 0) {
                $wrapper.append($("<span>").addClass("text-muted").html("<i class=\"bi bi-person-plus me-2\"></i>Chọn nhân viên..."));
            } else {
                const displayIds = EmployeeIDGridEmployeeIDSelectedIds.slice(0, MAX_VISIBLE_EmployeeIDGridEmployeeID);
                const $group = $("<div>").addClass("crm-avatar-group");

                displayIds.forEach((id, index) => {
                    const item = window["DataSource_EmployeeIDGridEmployeeID"].find(e => String(e.ID) === String(id));
                    if (!item) return;

                    const $chip = $("<div>")
                        .addClass("crm-avatar-chip")
                        .css({
                            marginLeft: index === 0 ? "0" : "-10px",
                            zIndex: index + 1
                        })
                        .attr("title", item.Name || item.FullName || "");

                    const cachedUrl = window.GlobalEmployeeAvatarCache[String(id)];

                    if (cachedUrl) {
                        $chip.append($("<img>")
                            .attr("src", cachedUrl)
                        );
                    } else if (item.storeImgName) {
                        loadGlobalAvatarIfNeededEmployeeIDGridEmployeeID(id, item.storeImgName, item.paramImg, function (url) {
                            renderDisplayBoxEmployeeIDGridEmployeeID();
                        });
                        const color = getColorForIdEmployeeIDGridEmployeeID(id);
                        const initials = getInitialsEmployeeIDGridEmployeeID(item.Name || item.FullName);
                        $chip.css({ background: color.bg, color: color.text }).text(initials);
                    } else {
                        const color = getColorForIdEmployeeIDGridEmployeeID(id);
                        const initials = getInitialsEmployeeIDGridEmployeeID(item.Name || item.FullName);
                        $chip.css({ background: color.bg, color: color.text }).text(initials);
                    }

                    $group.append($chip);
                });

                if (EmployeeIDGridEmployeeIDSelectedIds.length > MAX_VISIBLE_EmployeeIDGridEmployeeID) {
                    const remaining = EmployeeIDGridEmployeeIDSelectedIds.length - MAX_VISIBLE_EmployeeIDGridEmployeeID;
                    $group.append($("<div>")
                        .addClass("crm-avatar-chip-more")
                        .css({
                            marginLeft: "-10px",
                            zIndex: MAX_VISIBLE_EmployeeIDGridEmployeeID + 1
                        })
                        .text("+" + remaining)
                        .attr("title", "Còn " + remaining + " người nữa")
                    );
                }

                $wrapper.append($group);
            }

            $displayBoxEmployeeIDGridEmployeeID.append($wrapper);
            $wrapper.off("click").on("click", () => {
                if (_readOnlyEmployeeIDGridEmployeeID) {
                    if (typeof uiManager !== "undefined" && uiManager.showAlert) {
                        uiManager.showAlert({ type: "info", message: "This field is read-only." });
                    } else {
                        alert("This field is read-only.");
                    }
                    return;
                }
                if (!popupEmployeeIDGridEmployeeID) {
                    initPopupEmployeeIDGridEmployeeID();
                    setTimeout(() => {
                        popupEmployeeIDGridEmployeeID.show();
                    }, 0);
                } else {
                    popupEmployeeIDGridEmployeeID.show();
                }
            });
        }

        const $containerEmployeeIDGridEmployeeID = $("#GridEmployeeID");
        $containerEmployeeIDGridEmployeeID.empty();
        const $displayBoxEmployeeIDGridEmployeeID = $("<div>").attr("id", "EmployeeIDGridEmployeeID_display");
        $containerEmployeeIDGridEmployeeID.append($displayBoxEmployeeIDGridEmployeeID);

        let popupEmployeeIDGridEmployeeID;
        let popupEmployeeIDGridEmployeeIDOnce = false;
        let EmployeeIDGridEmployeeIDGridContainer = null;

        function initPopupEmployeeIDGridEmployeeID() {
            if (popupEmployeeIDGridEmployeeIDOnce) {
                popupEmployeeIDGridEmployeeID.show();
                return;
            }

            $("#EmployeeIDGridEmployeeID_popup").remove();

            popupEmployeeIDGridEmployeeIDOnce = true;
            popupEmployeeIDGridEmployeeID = $("<div>").attr("id", "EmployeeIDGridEmployeeID_popup")
                .appendTo(document.body)
                .addClass("hpa-responsive")
                .dxPopup({
                    width: 750,
                    height: "auto",
                    animation: null,
                    showTitle: true,
                    title: "Chọn nhân viên",
                    dragEnabled: true,
                    closeOnOutsideClick: true,
                    showCloseButton: true,
                    toolbarItems: [
                        {
                            widget: "dxButton",
                            location: "after",
                            toolbar: "bottom",
                            options: {
                                text: "Hủy",
                                onClick: () => {
                                    EmployeeIDGridEmployeeIDSelectedIds = [...EmployeeIDGridEmployeeIDSelectedIdsOriginal];
                                    renderDisplayBoxEmployeeIDGridEmployeeID();
                                    popupEmployeeIDGridEmployeeID.hide();
                                }
                            }
                        },
                        {
                            widget: "dxButton",
                            location: "after",
                            toolbar: "bottom",
                            options: {
                                text: "Lưu",
                                type: "success",
                                onClick: async () => {
                                    if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {
                                        try {
                                            const grid = cellInfo.component;
                                            const newValue = EmployeeIDGridEmployeeIDSelectedIds.join(",");
                                            grid.cellValue(cellInfo.rowIndex, "EmployeeID", newValue || null);
                                            grid.repaint();
                                        } catch (e) { console.warn(e); }
                                    }
                                    EmployeeIDGridEmployeeIDSelectedIdsOriginal = [...EmployeeIDGridEmployeeIDSelectedIds];

                                    renderDisplayBoxEmployeeIDGridEmployeeID();

                                    popupEmployeeIDGridEmployeeID.hide();

                                    ReloadData(EmployeeIDGridEmployeeIDSelectedIds.join(","));
                                }
                            }
                        }
                    ],
                    contentTemplate: function (contentElement) {
                        EmployeeIDGridEmployeeIDGridContainer = $("<div>");
                        contentElement.append(EmployeeIDGridEmployeeIDGridContainer);
                    },
                    onShown: () => {
                        const sortedData = window["DataSource_EmployeeIDGridEmployeeID"].sort((a, b) => {
                            const aSelected = EmployeeIDGridEmployeeIDSelectedIds.includes(String(a.ID));
                            const bSelected = EmployeeIDGridEmployeeIDSelectedIds.includes(String(b.ID));
                            return bSelected - aSelected;
                        });

                        try {
                            const existingInstance = EmployeeIDGridEmployeeIDGridContainer.dxDataGrid("instance");
                            if (existingInstance) {
                                existingInstance.dispose();
                            }
                        } catch (e) {
                            // Suppress
                        }

                        EmployeeIDGridEmployeeIDGridContainer
                            .empty()
                            .dxDataGrid({
                                dataSource: sortedData,
                                keyExpr: "ID",
                                remoteOperations: false,
                                columnAutoWidth: true,
                                allowColumnResizing: true,
                                selection: { mode: "multiple", showCheckBoxesMode: "always" },
                                selectedRowKeys: EmployeeIDGridEmployeeIDSelectedIds,
                                focusStateEnabled: true,
                                keyboardNavigation: { enabled: true },
                                hoverStateEnabled: true,
                                columns: [
                                    {
                                        caption: "Ảnh",
                                        width: 80,
                                        alignment: "center",
                                        cellTemplate: function (container, options) {
                                            const item = options.data;
                                            const $cell = $("<div>").addClass("crm-cell-avatar-wrapper");

                                            const cachedUrl = window.GlobalEmployeeAvatarCache[String(item.ID)];

                                            if (cachedUrl) {
                                                $cell.append($("<img>")
                                                    .attr("src", cachedUrl)
                                                    .addClass("crm-cell-avatar")
                                                );
                                            } else if (item.storeImgName) {
                                                loadGlobalAvatarIfNeededEmployeeIDGridEmployeeID(item.ID, item.storeImgName, item.paramImg, function (url) {
                                                    EmployeeIDGridEmployeeIDGridContainer.dxDataGrid("instance").refresh();
                                                });

                                                const initials = getInitialsEmployeeIDGridEmployeeID(item.Name || item.FullName || "?");
                                                const color = getColorForIdEmployeeIDGridEmployeeID(item.ID);
                                                $cell.append($("<div>")
                                                    .text(initials)
                                                    .addClass("crm-cell-avatar")
                                                    .css({ background: color.bg, color: color.text })
                                                );
                                            } else {
                                                const initials = getInitialsEmployeeIDGridEmployeeID(item.Name || item.FullName || "?");
                                                const color = getColorForIdEmployeeIDGridEmployeeID(item.ID);
                                                $cell.append($("<div>")
                                                    .text(initials)
                                                    .addClass("crm-cell-avatar")
                                                    .css({ background: color.bg, color: color.text })
                                                );
                                            }

                                            container.append($cell);
                                        }
                                    },
                                    { dataField: "Name", caption: "Họ tên" },
                                    { dataField: "Email", caption: "Email" },
                                    { dataField: "Position", caption: "Chức vụ" }
                                ],
                                searchPanel: {
                                    visible: true,
                                    placeholder: ""
                                },
                                onContentReady: function (e) {
                                    const grid = e.component;

                                    grid.option("searchPanel.text", "");

                                    const searchBox = grid.getView("headerPanel")._$element.find(".dx-datagrid-search-panel input");

                                    if (searchBox.length) {
                                        if (!$("#custom-search-style-EmployeeIDGridEmployeeID").length) {
                                            $("<style>")
                                                .attr("id", "custom-search-style-EmployeeIDGridEmployeeID")
                                                .text(`
                                                    .dx-datagrid-search-panel input:not(:placeholder-shown) {
                                                        color: var(--paradise-text-body) !important;
                                                    }
                                                    .dx-datagrid-search-panel input::placeholder {
                                                        color: var(--paradise-text-muted) !important;
                                                        opacity: 1 !important;
                                                    }
                                                `)
                                                .appendTo("head");
                                        }

                                        searchBox.off("input keyup");

                                        searchBox.on("input", function () {
                                            const searchValue = $(this).val();

                                            if (!searchValue) {
                                                grid.clearFilter();
                                                return;
                                            }

                                            const searchNormalized = RemoveToneMarks_Js(searchValue);

                                            grid.filter(function (item) {
                                                const fields = ["Name", "Email", "Position"];
                                                for (let i = 0; i < fields.length; i++) {
                                                    const fieldValue = item[fields[i]];
                                                    if (fieldValue) {
                                                        const fieldNormalized = RemoveToneMarks_Js(String(fieldValue));
                                                        if (fieldNormalized.indexOf(searchNormalized) !== -1) {
                                                            return true;
                                                        }
                                                    }
                                                }
                                                return false;
                                            });
                                        });
                                    }
                                },
                                paging: {
                                    enabled: true,
                                    pageSize: 5,
                                    pageIndex: 0
                                },
                                pager: {
                                    visible: true,
                                    allowedPageSizes: [5, 10],
                                    showPageSizeSelector: true,
                                    showInfo: true,
                                    showNavigationButtons: true
                                },
                                onSelectionChanged: e => EmployeeIDGridEmployeeIDSelectedIds = e.selectedRowKeys || []
                            });
                    },
                    onHidden: () => {
                        popupEmployeeIDGridEmployeeID.option("position", { my: "center", at: "center", of: window });
                        renderDisplayBoxEmployeeIDGridEmployeeID();
                    }
                }).dxPopup("instance");
        }

        async function saveValueEmployeeIDGridEmployeeID() {
            if (_readOnlyEmployeeIDGridEmployeeID) {
                if (typeof uiManager !== "undefined" && uiManager.showAlert) {
                    uiManager.showAlert({ type: "info", message: "This field is read-only." });
                } else {
                    alert("This field is read-only.");
                }
                return;
            }

            const original = EmployeeIDGridEmployeeIDSelectedIdsOriginal.slice().sort().join(",");
            const current = EmployeeIDGridEmployeeIDSelectedIds.slice().sort().join(",");
            if (original === current || EmployeeIDGridEmployeeIDIsSaving) return;

            EmployeeIDGridEmployeeIDIsSaving = true;
            try {
                const newValue = EmployeeIDGridEmployeeIDSelectedIds.join(",");
                const dataJSON = JSON.stringify(["-99218308", ["EmployeeID"], [newValue || null]]);

                let id1 = window.currentRecordID_EmployeeID;
                if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {
                    id1 = cellInfo.data["EmployeeID"] || id1;
                }
                let idValues = [id1];
                let idFields = ["EmployeeID"];

                if ("" && "".trim() !== "") {
                    let id2 = currentRecordID_;
                    if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {
                        id2 = cellInfo.data[""] || id2;
                    }
                    idValues.push(id2);
                    idFields.push("");
                }
                const idValsJSON = JSON.stringify([idValues, idFields]);

                const json = await saveFunction(dataJSON, idValsJSON);
                const errors = json.data?.[json.data.length - 1] || [];
                if (errors.length > 0 && errors[0].Status === "ERROR") {
                    uiManager.showAlert({ type: "error", message: errors[0].Message || "%SaveErrorMessage%" });
                    return;
                }

                if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {
                    try {
                        const grid = cellInfo.component;
                        grid.cellValue(cellInfo.rowIndex, "EmployeeID", newValue);
                        grid.repaint();
                    } catch (syncErr) {
                        console.warn("[Grid Sync] SelectEmployee EmployeeIDGridEmployeeID: Không thể sync grid:", syncErr);
                    }
                }

                EmployeeIDGridEmployeeIDSelectedIdsOriginal = [...EmployeeIDGridEmployeeIDSelectedIds];
                renderDisplayBoxEmployeeIDGridEmployeeID();
            } catch (err) {
                uiManager.showAlert({ type: "error", message: "%SaveErrorMessage%" });
            } finally {
                EmployeeIDGridEmployeeIDIsSaving = false;
            }
        }
        
        let _onValueChangedEmployeeIDGridEmployeeID = null;
        
        InstanceEmployeeIDGridEmployeeID = {
            setValue: function (val) {
                if (typeof val === "string" && val.trim()) {
                    EmployeeIDGridEmployeeIDSelectedIds = val.split(",").map(v => v.trim()).filter(v => v);
                } else if (Array.isArray(val)) {
                    EmployeeIDGridEmployeeIDSelectedIds = val.map(String);
                } else {
                    EmployeeIDGridEmployeeIDSelectedIds = [];
                }
                EmployeeIDGridEmployeeIDSelectedIdsOriginal = [...EmployeeIDGridEmployeeIDSelectedIds];

                renderDisplayBoxEmployeeIDGridEmployeeID();
            },
            getValue: () => EmployeeIDGridEmployeeIDSelectedIds,
            getValueAsString: () => EmployeeIDGridEmployeeIDSelectedIds.join(","),
            setDataSource: data => {
                window["DataSource_EmployeeIDGridEmployeeID"] = data || [];
            },
            repaint: renderDisplayBoxEmployeeIDGridEmployeeID,
            _readOnly: false,
            _autoSave: false,
            option: function (name, value) {
                if (arguments.length === 2) {
                    if (name === "value") this.setValue(value);
                    if (name === "readOnly") {
                        this._readOnly = value;
                        _readOnlyEmployeeIDGridEmployeeID = value;
                        const $displayBox = $("#EmployeeIDGridEmployeeID_display");
                        if (value) $displayBox.addClass("disabled-control").css("opacity", "0.6");
                        else $displayBox.removeClass("disabled-control").css("opacity", "1");
                    }

                    if (name === "autoSave") {
                        this._autoSave = value;
                        _autoSaveEmployeeIDGridEmployeeID = value;
                    }
                } else if (arguments.length === 1) {
                    if (name === "value") return this.getValueAsString();
                    if (name === "dataSource") return window["DataSource_EmployeeIDGridEmployeeID"];
                    if (name === "readOnly") return _readOnlyEmployeeIDGridEmployeeID;
                    if (name === "autoSave") return _autoSaveEmployeeIDGridEmployeeID;
                }
                return undefined;
            },
            _suppressValueChangeAction: function () { },
            _resumeValueChangeAction: function () { }
        };

        InstanceEmployeeIDGridEmployeeID.option("onValueChanged", function (e) {
            if (e.value) {
                console.log("Giá trị mới:", e.value);
            }
        });

        function ReNewGrid() {
            InstanceEmployeeIDGridEmployeeID.option("value", null);
            fromDateValue = null;
            toDateValue = null;
            isViewNewContract = false;
            isViewAllData = true;

            if (InstanceFromDate) InstanceFromDate.option({ disabled: true, value: null });
            if (InstanceToDate) InstanceToDate.option({ disabled: true, value: null });
            $("#toolbarMsFilterAllData").prop("checked", true);
            $("#toolbarIsViewNewContract").prop("checked", false);
            $("#toolbarIsOnlyUser").prop("checked", false);

            ReloadData();
        }

        function getFilterOption() {
            let value = 0;
            $("#stock-filter-contract-tracking .stock-btn.active").each(function () {
                const v = $(this).data("value");
                if (v) value = v;
            });
            return value;
        }

        ReNewGrid();
    })();
</script>
';

    -- 4. MERGE vào tblHtmlScriptCache
    MERGE dbo.tblHtmlScriptCache AS tgt
    USING (SELECT 'sp_CRM_CustomerList' AS TableName,
                  @LanguageID    AS LanguageID,
                  '-1'           AS ScreenType,
                  @html          AS html,
                  N''            AS HtmlParadise,
                  N''            AS paradiseJs,
                  '1'            AS Version,
                  N''            AS VersionData) AS src
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

    -- 5. Fallback SELECT
    SELECT @html AS html;
END
