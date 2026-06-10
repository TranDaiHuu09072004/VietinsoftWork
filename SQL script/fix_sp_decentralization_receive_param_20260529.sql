if object_id('[dbo].[sp_zalo_autoSendMessage_html]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_zalo_autoSendMessage_html] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_zalo_autoSendMessage_html]
    @LoginID INT = 3,
    @LanguageID VARCHAR(2) = 'VN',
    @isWeb int = 0
AS
-- taidang
BEGIN
    SET NOCOUNT ON;
    DECLARE @html nvarchar(max)
    SET @html = N'
        <style>
            #GridZalo .dx-datagrid-table .dx-row > td { vertical-align: middle !important; }
            #GridZalo .dx-data-row { height: 60px !important; }
            .dx-datagrid .dx-column-indicators.dx-visibility-hidden { display: none !important; }
            #GridZalo .dx-command-select {
                width: 50px !important;
                min-width: 50px !important;
                max-width: 50px !important;
                text-align: center !important;
            }
            .dx-datagrid-search-panel{
                margin-right: 0px !important;
            }
            .dx-tabpanel .dx-inkripple {
                display: none !important;
            }

            /* VTS_RESPONSIVE_ZALO_FINAL_20260609 */
            .sp_zalo_autoSendMessage {
                width: 100%;
                height: 100%;
                min-width: 0;
                overflow: hidden;
                box-sizing: border-box;
            }
            .sp_zalo_autoSendMessage *,
            .sp_zalo_autoSendMessage *::before,
            .sp_zalo_autoSendMessage *::after {
                box-sizing: border-box;
            }
            .sp_zalo_autoSendMessage #GridZalo {
                width: 100%;
                height: 100%;
                min-width: 0;
                overflow: hidden;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-table .dx-row > td,
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-text-content {
                overflow: hidden;
                text-overflow: ellipsis;
                white-space: nowrap;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-headers,
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-rowsview {
                overflow-x: auto;
            }
            .sp_zalo_autoSendMessage .zalo-auto-toolbar {
                display: flex;
                align-items: center;
                flex-wrap: wrap;
                gap: 8px;
                width: 100%;
                min-width: 0;
                margin-right: 8px;
                padding-bottom: 5px;
            }
            .sp_zalo_autoSendMessage .zalo-auto-toolbar__software {
                flex: 1 1 190px;
                min-width: 150px;
                max-width: 260px;
            }
            .sp_zalo_autoSendMessage .zalo-auto-toolbar__quantity {
                flex: 0 1 104px;
                min-width: 90px;
            }
            .sp_zalo_autoSendMessage .zalo-auto-toolbar__segment {
                flex: 1 1 220px;
                min-width: 170px;
            }
            .sp_zalo_autoSendMessage .zalo-auto-toolbar__ai {
                flex: 1 1 170px;
                min-width: 145px;
                max-width: 230px;
            }
            .sp_zalo_autoSendMessage .zalo-auto-toolbar__gear {
                flex: 0 0 auto;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar,
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-items-container {
                height: auto !important;
                min-height: 40px;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-before {
                max-width: calc(100% - 260px);
                min-width: 0;
                white-space: normal;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-after {
                min-width: 210px;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-search-panel {
                width: 240px !important;
                min-width: 140px;
                max-width: 100%;
                margin-left: 0 !important;
                margin-right: 0 !important;
            }
            .sp_zalo_autoSendMessage #GridZalo img {
                max-width: 100%;
                object-fit: cover;
            }
            @media (max-width: 991px) {
                .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-before,
                .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-after {
                    display: block;
                    width: 100%;
                    max-width: 100%;
                    min-width: 0;
                }
                .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-search-panel {
                    width: 100% !important;
                }
            }
            @media (max-width: 575px) {
                .sp_zalo_autoSendMessage .zalo-auto-toolbar {
                    display: grid;
                    grid-template-columns: minmax(0, 1fr) 96px;
                    gap: 6px;
                    margin-right: 0;
                }
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__software,
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__quantity,
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__segment,
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__ai,
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__gear {
                    min-width: 0;
                    max-width: none;
                    width: 100%;
                }
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__segment,
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__ai {
                    grid-column: 1 / -1;
                }
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__gear {
                    justify-self: end;
                }
                .sp_zalo_autoSendMessage #GridZalo .dx-data-row {
                    height: 56px !important;
                }
                .sp_zalo_autoSendMessage #GridZalo .dx-command-select {
                    width: 42px !important;
                    min-width: 42px !important;
                    max-width: 42px !important;
                }
            }

        
            /* VTS_RESPONSIVE_ZALO_FINAL_20260609_V2: CSS-only toolbar/table responsive fix */
            .sp_zalo_autoSendMessage {
                width: 100% !important;
                max-width: 100% !important;
                min-width: 0 !important;
                height: 100% !important;
                overflow: hidden !important;
            }
            .sp_zalo_autoSendMessage #GridZalo,
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid,
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-headers,
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-rowsview,
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-pager {
                width: 100% !important;
                max-width: 100% !important;
                min-width: 0 !important;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-header-panel {
                overflow: visible !important;
                padding: 6px 8px 8px !important;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar,
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-items-container,
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-header-panel .dx-toolbar-items-container {
                display: flex !important;
                flex-wrap: wrap !important;
                align-items: stretch !important;
                gap: 8px !important;
                width: 100% !important;
                max-width: 100% !important;
                min-width: 0 !important;
                height: auto !important;
                min-height: 0 !important;
                overflow: visible !important;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-before,
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-center,
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-after {
                position: static !important;
                left: auto !important;
                right: auto !important;
                top: auto !important;
                bottom: auto !important;
                transform: none !important;
                display: flex !important;
                flex-wrap: wrap !important;
                align-items: center !important;
                gap: 8px !important;
                width: auto !important;
                max-width: 100% !important;
                min-width: 0 !important;
                height: auto !important;
                overflow: visible !important;
                white-space: normal !important;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-before {
                flex: 1 1 520px !important;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-after {
                flex: 1 1 240px !important;
                justify-content: flex-end !important;
                margin-left: auto !important;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-item,
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-button,
            .sp_zalo_autoSendMessage #GridZalo .dx-toolbar .dx-item {
                position: static !important;
                flex: 0 1 auto !important;
                max-width: 100% !important;
                min-width: 0 !important;
                height: auto !important;
                margin: 0 !important;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-search-panel {
                flex: 1 1 220px !important;
                width: min(320px, 100%) !important;
                min-width: 180px !important;
                max-width: 100% !important;
                margin: 0 !important;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-texteditor,
            .sp_zalo_autoSendMessage #GridZalo .dx-selectbox,
            .sp_zalo_autoSendMessage #GridZalo .dx-dropdowneditor,
            .sp_zalo_autoSendMessage #GridZalo .dx-button {
                max-width: 100% !important;
                min-width: 0 !important;
            }
            .sp_zalo_autoSendMessage .zalo-auto-toolbar,
            .sp_zalo_autoSendMessage .zalo-auto-toolbar .dx-field-item,
            .sp_zalo_autoSendMessage .zalo-auto-toolbar .dx-widget {
                max-width: 100% !important;
                min-width: 0 !important;
            }
            .sp_zalo_autoSendMessage .zalo-auto-toolbar {
                display: flex !important;
                flex: 1 1 auto !important;
                flex-wrap: wrap !important;
                align-items: center !important;
                gap: 8px !important;
                width: 100% !important;
                margin: 0 !important;
                overflow: visible !important;
            }
            .sp_zalo_autoSendMessage .zalo-auto-toolbar__software {
                flex: 1 1 190px !important;
                min-width: 150px !important;
                max-width: 260px !important;
            }
            .sp_zalo_autoSendMessage .zalo-auto-toolbar__quantity {
                flex: 0 1 110px !important;
                min-width: 88px !important;
                max-width: 130px !important;
            }
            .sp_zalo_autoSendMessage .zalo-auto-toolbar__segment {
                flex: 1 1 250px !important;
                min-width: 190px !important;
                max-width: 100% !important;
                overflow-x: auto !important;
                overflow-y: hidden !important;
                scrollbar-width: thin;
            }
            .sp_zalo_autoSendMessage .zalo-auto-toolbar__ai {
                flex: 1 1 170px !important;
                min-width: 140px !important;
                max-width: 240px !important;
            }
            .sp_zalo_autoSendMessage .zalo-auto-toolbar__gear {
                flex: 0 0 auto !important;
            }
            .sp_zalo_autoSendMessage .dx-tabs-wrapper,
            .sp_zalo_autoSendMessage .dx-tabs-scrollable,
            .sp_zalo_autoSendMessage .dx-tabpanel-tabs,
            .sp_zalo_autoSendMessage .dx-tabpanel .dx-tabs {
                max-width: 100% !important;
                min-width: 0 !important;
                overflow-x: auto !important;
                overflow-y: hidden !important;
                scrollbar-width: thin;
            }
            .sp_zalo_autoSendMessage .dx-tab,
            .sp_zalo_autoSendMessage .dx-tab-content,
            .sp_zalo_autoSendMessage .dx-tab-text {
                white-space: nowrap !important;
                overflow: hidden !important;
                text-overflow: ellipsis !important;
                max-width: 140px !important;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-table {
                min-width: 780px !important;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-headers,
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-rowsview {
                overflow-x: auto !important;
                overflow-y: hidden !important;
                -webkit-overflow-scrolling: touch;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-content {
                max-width: 100% !important;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-table .dx-row > td,
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-text-content {
                white-space: nowrap !important;
                overflow: hidden !important;
                text-overflow: ellipsis !important;
            }
            .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-pager {
                overflow-x: auto !important;
                overflow-y: hidden !important;
                white-space: nowrap !important;
            }
            @media (max-width: 1024px) {
                .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-before,
                .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-after {
                    flex: 1 1 100% !important;
                    width: 100% !important;
                    margin-left: 0 !important;
                    justify-content: flex-start !important;
                }
                .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-search-panel {
                    flex: 1 1 260px !important;
                    width: 100% !important;
                }
                .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-table {
                    min-width: 740px !important;
                }
            }
            @media (max-width: 768px) {
                .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-header-panel {
                    padding: 6px !important;
                }
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__software,
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__quantity,
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__ai,
                .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-search-panel {
                    flex: 1 1 calc(50% - 8px) !important;
                    width: auto !important;
                    min-width: 150px !important;
                    max-width: 100% !important;
                }
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__segment {
                    flex: 1 1 100% !important;
                    width: 100% !important;
                    min-width: 0 !important;
                }
                .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-table {
                    min-width: 700px !important;
                }
            }
            @media (max-width: 480px) {
                .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-before,
                .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-after,
                .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-item,
                .sp_zalo_autoSendMessage #GridZalo .dx-toolbar-button {
                    flex: 1 1 100% !important;
                    width: 100% !important;
                    max-width: 100% !important;
                }
                .sp_zalo_autoSendMessage .zalo-auto-toolbar {
                    display: flex !important;
                    flex-direction: column !important;
                    align-items: stretch !important;
                }
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__software,
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__quantity,
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__segment,
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__ai,
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__gear,
                .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-search-panel {
                    flex: 1 1 auto !important;
                    width: 100% !important;
                    min-width: 0 !important;
                    max-width: 100% !important;
                }
                .sp_zalo_autoSendMessage .zalo-auto-toolbar__gear {
                    align-self: flex-end !important;
                    width: auto !important;
                }
                .sp_zalo_autoSendMessage .dx-tab,
                .sp_zalo_autoSendMessage .dx-tab-text {
                    max-width: none !important;
                }
                .sp_zalo_autoSendMessage #GridZalo .dx-datagrid-table {
                    min-width: 660px !important;
                }
                .sp_zalo_autoSendMessage #GridZalo .dx-command-select {
                    width: 40px !important;
                    min-width: 40px !important;
                    max-width: 40px !important;
                }
            }</style>
        <div class="sp_zalo_autoSendMessage">
            <div id="GridZalo" style="height: 100%;"></div>
            <div id="SelectBoxContainer_Temp" style="display:none">
                <div id="P36EB8FEA286C46F7A109BD6404CA9BAA"></div>
                <div id="PC3ECBD81231B40B294775F6A0D74C861"></div>
                <div id="PAEF4A083A6D44ACD92F01B2834695EED"></div>
                <div id="PBE6706C7F3944933A71F067C581E0677"></div>
            </div>
        </div>
    '

    SET @html = @html + N'
    <script>
      (async () => {
            let api = true;
            let DataSource = [];
            let _pageCache = {};
            let _currentKeyword = "";
            let dataStore_GridZalo = null;
            let obj = null;
            let friendAvatarMap = {};
            let P36EB8FEA286C46F7A109BD6404CA9BAA_data = []; // Chọn phần mềm (Tag)
            let PC3ECBD81231B40B294775F6A0D74C861_data = []; // Số lượng
            let PAEF4A083A6D44ACD92F01B2834695EED_data = []; // Menu
            let PBE6706C7F3944933A71F067C581E0677_data = []; // AI Menu

            // Biến quản lý trạng thái chọn dòng thủ công (Custom Selection)
            let customSelectedKeys_GridZalo = [];
            let isSelectAllActive_GridZalo = false;
            let _currentTagID = ""; // Lưu trữ ID phần mềm đang chọn lọc

            // Biến quản lý lịch sử các lượt test AI
            let aiHistory_Log = []; // Array of { timestamp: "HH:mm:ss", prompt: "...", results: {...} }

            '
                +(select loadUI from tblCommonControlType_Signed where UID = 'P573D5BF0C93B424BA49F7C7FE5871D8B')
                +(select loadUI from tblCommonControlType_Signed where UID = 'P36EB8FEA286C46F7A109BD6404CA9BAA')
                +(select loadUI from tblCommonControlType_Signed where UID = 'PAEF4A083A6D44ACD92F01B2834695EED')
                +(select loadUI from tblCommonControlType_Signed where UID = 'PC3ECBD81231B40B294775F6A0D74C861')
                +(select loadUI from tblCommonControlType_Signed where UID = 'PBE6706C7F3944933A71F067C581E0677')
            +N'

            function openSetAutoPopup() {
                let $popup = $("<div />").appendTo("body");
                let $innerWrap = $("<div style=''height:100%; display:flex; flex-direction:column; gap:10px;'' />");

                // ====== Nút Thêm lịch mới ======
                let $topBar = $("<div style=''display:flex; justify-content:flex-end;'' />").appendTo($innerWrap);
                let $listWrap = $("<div style=''flex:1; overflow:auto;'' />").appendTo($innerWrap);
                let $dxList = $("<div />").appendTo($listWrap);

                // ====== Load danh sách lịch đã tạo ======
                function loadScheduleList() {
                    AjaxHPAParadise({
                        data: {
                            name: "sp_zalo_createAI_TaskSchedule",
                            param: ["LoginID", UserID, "LanguageID", LanguageID, "ActionType", "SELECT"]
                        },
                        success: function(res) {
                            let json = typeof res === "string" ? JSON.parse(res) : res;
                            let data = (json.data && json.data[0]) ? json.data[0] : [];

                            $dxList.empty();
                            if (data.length === 0) {
                                $dxList.html("<div style=''color:var(--bs-secondary-color); text-align:center; padding:30px;''>%zalo_schedule_empty%</div>");
                                return;
                            }

                            data.forEach(function(row) {
                                let statusIcon = row.IsActive ? "&#9989;" : "&#9898;";
                                let nextRunDisplay = row.NextRunDate ? row.NextRunDate.replace("T", " ").substring(0, 16) : "";
                                let taskNameDisplay = row.TaskName || row.TaskScheduleName || "";
                                let productBadge = row.ProductName ? " <span style=''background:rgba(var(--bs-success-rgb), 0.15); color:var(--bs-success); border-radius:4px; padding:1px 7px; font-size:11px; margin-left:4px;''>" + row.ProductName + "</span>" : "";
                                let recipientCount = row.Param ? row.Param.split(",").length : 0;
                                let recipientBadge = "<span style=''color:var(--bs-secondary-color); font-size:11px; margin-left:6px;''>&#128101; " + recipientCount + " %zalo_schedule_recipient_members%</span>";
                                let $item = $("<div style=''padding:10px 5px; border-bottom:1px solid var(--bs-border-color);'' />");
                                let $left = $("<div style=''display:flex; flex-direction:column; gap:3px;'' />");

                                let statusText = row.IsActive ? "%zalo_schedule_status_on%" : "%zalo_schedule_status_off%";
                                let statusBg = row.IsActive ? "rgba(var(--bs-success-rgb), 0.15)" : "var(--bs-secondary-bg)";
                                let statusColor = row.IsActive ? "var(--bs-success)" : "var(--bs-secondary-color)";
                                let $statusBtn = $("<div style=''cursor:pointer; border-radius:20px; padding:4px 10px; font-size:11px; font-weight:bold; background:" + statusBg + "; color:" + statusColor + "; display:flex; align-items:center; gap:4px;'' title=''" + (row.IsActive ? "%zalo_schedule_toggle_on%" : "%zalo_schedule_toggle_off%") + "''>" + statusText + "</div>");
                                $statusBtn.click(function() {
                                    AjaxHPAParadise({
                                        data: {
                                            name: "sp_zalo_createAI_TaskSchedule",
                                            param: ["LoginID", UserID, "LanguageID", LanguageID, "ActionType", "TOGGLE_ACTIVE", "TaskScheduleID", row.IDTask || ""]
                                        },
                                        success: function() { loadScheduleList(); },
                                        error: function() { if (window.uiManager) uiManager.showAlert({ type: "error", message: "%zalo_schedule_toggle_error%" }); }
                                    });
                                });

                                let $titleLine = $("<div style=''display:flex; align-items:center;'' />").append($("<b>" + taskNameDisplay + "</b>" + productBadge + recipientBadge));
                                $left.append($titleLine);

                                let typeMap = { "0": "%zalo_schedule_once%", "1": "%zalo_schedule_hour%", "2": "%zalo_schedule_day%", "3": "%zalo_schedule_week%", "4": "%zalo_schedule_month%", "5": "%zalo_schedule_year%" };
                                let typeDisplay = typeMap[row.TaskType] || row.TaskType || "";
                       $left.append($("<div />").html("<span style=''color:var(--bs-secondary-color); font-size:11px; margin-left:24px;''>" + typeDisplay + " &bull; " + nextRunDisplay + "</span>"));
                                let $rightWrap = $("<div style=''display:flex; align-items:center; gap:6px;'' />");
                                $item.append($("<div style=''display:flex; justify-content:space-between; align-items:center;'' />").append($left).append($rightWrap));

                                let $edit = $("<div />").dxButton({
                                    icon: "edit", type: "normal", stylingMode: "outlined", hint: "%zalo_schedule_edit_hint%",
                                    onClick: function() {
                                        openAddForm(row);
                                    }
                                });
                                let $del = $("<div />").dxButton({
                                    icon: "trash", type: "danger", stylingMode: "outlined", hint: "%zalo_schedule_delete_hint%",
                                    onClick: function() {
                                        DevExpress.ui.dialog.confirm("<i>%zalo_schedule_delete_confirm_msg%</i>", "%zalo_schedule_delete_confirm_title%").done(function(ok) {
                                            if (!ok) return;
                                            AjaxHPAParadise({
                                                data: {
                                                    name: "sp_zalo_createAI_TaskSchedule",
                                                    param: ["LoginID", UserID, "LanguageID", LanguageID, "ActionType", "DELETE", "TaskScheduleID", row.IDTask || ""]
                                                },
                                                success: function() { loadScheduleList(); },
                                                error: function() { if (window.uiManager) uiManager.showAlert({ type: "error", message: "%zalo_schedule_delete_error%" }); }
                                            });
                                        });
                                    }
                                });
                                $rightWrap.append($statusBtn).append($edit).append($del);
                                $dxList.append($item);
                            });
                        },
                        error: function() {
                            $dxList.html("<div style=''color:#f66; text-align:center; padding:20px;''>%zalo_schedule_load_error%</div>");
                        }
                    });
                }

                // ====== Form thêm mới ======
                function openAddForm(editData) {
                    let $addPopup = $("<div />").appendTo("body");
                    let $form = $("<div style=''padding:10px; display:flex; flex-direction:column; gap:14px; overflow:auto;'' />");

                    let isEdit = !!(editData && editData.IDTask);
                    let preSelected = isEdit && editData.Param ? editData.Param.split(",") : (customSelectedKeys_GridZalo || []).slice();
                    let initialTaskName = isEdit ? (editData.TaskName || editData.TaskScheduleName || "") : "";
                    let initialDate = isEdit && editData.NextRunDate ? new Date(editData.NextRunDate.replace("T", " ")) : new Date(new Date().getTime() + 10 * 60000);
                    let initialRunType = isEdit ? (editData.TaskType || "Once") : "Once";
                    let initialProductID = isEdit ? editData.ProductID : null;
                    let editTaskID = isEdit ? editData.IDTask : "";

                    // --- Tên lịch ---
                    let $nameWrap = $("<div />").appendTo($form);
                    $("<label style=''font-size:12px; color:#aaa; margin-bottom:4px; display:block;''>%zalo_schedule_name% <span style=''color:red''>*</span></label>").appendTo($nameWrap);
                    let $nameBox = $("<div />").appendTo($nameWrap);
                    $nameBox.dxTextBox({ value: initialTaskName, placeholder: "%zalo_schedule_name_placeholder%" });

                    // --- Thời gian chạy ---
                    let $dateWrap = $("<div />").appendTo($form);
                    $("<label style=''font-size:12px; color:#aaa; margin-bottom:4px; display:block;''>%zalo_schedule_run_time% <span style=''color:red''>*</span></label>").appendTo($dateWrap);
                    let $dateBox = $("<div />").appendTo($dateWrap);
                    $dateBox.dxDateBox({
                        type: "datetime",
                        displayFormat: "dd/MM/yyyy HH:mm",
                        value: initialDate,
                        min: new Date()
                    });

                    // --- Kiểu chạy ---
                    let $typeWrap = $("<div />").appendTo($form);
                    $("<label style=''font-size:12px; color:#aaa; margin-bottom:4px; display:block;''>%zalo_schedule_run_type% <span style=''color:red''>*</span></label>").appendTo($typeWrap);
                    let $typeBox = $("<div />").appendTo($typeWrap);
                    $typeBox.dxSelectBox({
                        items: [
                            { ID: "0", Name: "%zalo_schedule_once%" },
                            { ID: "1", Name: "%zalo_schedule_hour%" },
                            { ID: "2", Name: "%zalo_schedule_day%" },
                            { ID: "3", Name: "%zalo_schedule_week%" },
                            { ID: "4", Name: "%zalo_schedule_month%" },
                            { ID: "5", Name: "%zalo_schedule_year%" }
                        ],
                        displayExpr: "Name", valueExpr: "ID",
                        value: initialRunType
                    });

                    // --- Phần mềm ---
                    let $swWrap = $("<div />").appendTo($form);
                    $("<label style=''font-size:12px; color:#aaa; margin-bottom:4px; display:block;''>%zalo_schedule_software% <span style=''color:red''>*</span></label>").appendTo($swWrap);
                    let $swBox = $("<div />").appendTo($swWrap);
                    // Giá trị mặc định lấy từ toolbar hiện tại
                    let defaultProductID = initialProductID;
                    let productDataSource = (typeof P36EB8FEA286C46F7A109BD6404CA9BAA_data !== "undefined") ? P36EB8FEA286C46F7A109BD6404CA9BAA_data : [];
                    try {
                        let inst = $("#P36EB8FEA286C46F7A109BD6404CA9BAA").dxSelectBox("instance");
                        if (inst) {
                            if (!isEdit) defaultProductID = inst.option("value");
                            let instItems = inst.option("items");
                            if (instItems && instItems.length > 0) productDataSource = instItems;
                        }
                    } catch(ex) {}

                    // --- Người nhận ---
                    let $tagWrap = $("<div />").appendTo($form);
                    $("<label style=''font-size:12px; color:#aaa; margin-bottom:4px; display:block;''>%zalo_schedule_recipient% <span style=''color:red''>*</span></label>").appendTo($tagWrap);
                    let $tagBox = $("<div />").appendTo($tagWrap);
                    let contactDS = preSelected.map(id => ({ ID: id, Name: id }));

                    function loadContactList(prodID) {
                        let items = [];
                        let debugNguon = "KHÔNG CÓ DỮ LIỆU";

                        try {
                            let gInst = $("#GridZalo").dxDataGrid("instance");
                            if (gInst) {
                                // CÁCH 1: Lấy các dòng hiển thị hiện tại trên grid (chuẩn nhất cho UI)
                                let rows = gInst.getVisibleRows();
                                if (rows && rows.length > 0) {
                                    items = rows.map(r => r.data);
                                    debugNguon = "getVisibleRows() của GridZalo";
                                }
                                // CÁCH 2: Lấy mảng gốc từ dataSource option
                                else {
                                    let optDs = gInst.option("dataSource");
                                    if (Array.isArray(optDs) && optDs.length > 0) {
                                        items = optDs;
                                        debugNguon = "GridZalo.option(''dataSource'') (Array)";
                                    }
                                    else if (optDs && optDs.store && typeof optDs.store._array !== "undefined") {
                                        items = optDs.store._array;
                                        debugNguon = "GridZalo.option(''dataSource'').store._array";
                                    }
                                }
                            }
                        } catch(e) {}

                        // CÁCH 3: Lấy từ biến cục bộ dataStore_GridZalo nếu grid instance fail
                        if ((!items || items.length === 0) && typeof dataStore_GridZalo !== "undefined" && dataStore_GridZalo && dataStore_GridZalo._array) {
                            items = dataStore_GridZalo._array;
                            debugNguon = "Biến dataStore_GridZalo._array";
                        }

                        console.log("🚀 taidang~ NGUỒN KHAI THÁC:", debugNguon);
                        console.log("🚀 taidang~ SỐ LƯỢNG ITEMS TÌM THẤY:", items ? items.length : 0);
                        console.log("🚀 taidang~ CHI TIẾT DỮ LIỆU GỐC:", items);

                        let finalDS = [];
                        let mapUnique = {};
                        if (items && items.length > 0) {
                            console.log("🚀 taidang~ Cấu trúc Object dòng đầu tiên:", Object.keys(items[0]), items[0]);
                            items.forEach(it => {
                                if (!it) return;
                                let id = it.ZaloID || it.zaloID || it.ID || it.Id || it.id || it.UserID || it.userID || it.ContactID || it.Phone;
                                let name = it.FullName || it.fullName || it.ZaloName || it.zaloName || it.Name || it.name || id;
                                let avatar = it.Avatar || it.avatar || it.UrlAvatar || it.avatarUrl || it.Image || it.image || "";
                                let tags = it.tag || it.tagID || it.TagID || it.Tags || it.tags || it.ProductID || it.productID || it.GroupID || it.groupID || "";

                                let isMatch = true;
                                if (prodID) {
                                    // Bắt buộc phải có tag và match với prodID
                                    if (!tags) {
                                        isMatch = false;
                                    } else if (tags.toString().indexOf(prodID.toString()) === -1) {
                                        isMatch = false;
                                    }
                                }

                                if (isMatch && id && !mapUnique[id]) {
                                    mapUnique[id] = true;
                                    finalDS.push({ ID: id, Name: name, Avatar: avatar });
                                }
                            });
                        }

                        // Không gộp mù quáng các preSelected nếu nó không thuộc Phần mềm (loại bỏ bug dư người ngoài)

                        console.log("🚀 taidang~ DATA GỘP TAGBOX CUỐI CÙNG (LENGTH=" + finalDS.length + "):", finalDS);

                        try {
                            let tagInst = $tagBox.dxTagBox("instance");
                            tagInst.option("dataSource", finalDS);
                            tagInst.option("placeholder", finalDS.length > 0 ? "%zalo_schedule_recipient_placeholder%" : "%zalo_schedule_recipient_empty%");
                        } catch(e) {}
                    }

                    $swBox.dxSelectBox({
                        dataSource: productDataSource,
                        displayExpr: "Name", valueExpr: "ID",
                        placeholder: "%zalo_schedule_software_placeholder%",
                        value: defaultProductID || null,
                        searchEnabled: true,
                        onValueChanged: function(e) {
                            try {
                                let tagInst = $tagBox.dxTagBox("instance");
                                if (e.value) {
                                    tagInst.option("disabled", false);
                                    loadContactList(e.value);
                                } else {
                                    tagInst.option("disabled", true);
                                    tagInst.option("placeholder", "%zalo_schedule_recipient_require_sw%");
                                }
                            } catch(ex) {}
                        }
                    });

                    $tagBox.dxTagBox({
                        dataSource: contactDS,
                        displayExpr: "Name", valueExpr: "ID",
                        value: preSelected,
                        disabled: !defaultProductID, // Bắt buộc chọn phần mềm trước
                        acceptCustomValue: true,
                        searchEnabled: true,
                        searchExpr: ["Name", "ID"],
                        showSelectionControls: true,
                        applyValueMode: "useButtons",
                        placeholder: defaultProductID ? "%zalo_schedule_recipient_loading%" : "%zalo_schedule_recipient_require_sw%",
                        itemTemplate: function(data) {
                            let img = data.Avatar ? data.Avatar : "https://ui-avatars.com/api/?name=" + encodeURIComponent(data.Name || "Z") + "&background=random";
                            return $("<div style=''display:flex; align-items:center; gap:8px;''><img src=''"+img+"'' style=''width:24px; height:24px; border-radius:50%; object-fit:cover;'' /><span>"+data.Name+"</span></div>");
                        },
                        onCustomItemCreating: function(args) {
                            if (!args.text || !args.text.trim()) { args.customItem = null; return; }
                            args.customItem = { ID: args.text.trim(), Name: args.text.trim() };
                        },
                        noDataText: "%zalo_schedule_recipient_empty%"
                    });

                    if (defaultProductID) {
                        setTimeout(function() { loadContactList(defaultProductID); }, 100);
                    }

                    // --- Nút xác nhận ---
                    let $btnRow = $("<div style=''display:flex; gap:8px; justify-content:flex-end; margin-top:6px;'' />").appendTo($form);
                    $btnRow.dxButton({
                        text: isEdit ? "%zalo_schedule_btn_update%" : "%zalo_schedule_btn_create%", icon: "check",
                        elementAttr: { class: "btn-success-paradise" },
                        onClick: function() {
                            let selectedDate  = $dateBox.dxDateBox("instance").option("value");
                            let taskName      = $nameBox.dxTextBox("instance").option("value");
                            let runType       = $typeBox.dxSelectBox("instance").option("value");
              let chosenProduct = $swBox.dxSelectBox("instance").option("value");
                            let chosenIDs     = $tagBox.dxTagBox("instance").option("value") || [];

                            if (!chosenProduct || chosenProduct == 0) {
                                if (window.uiManager) uiManager.showAlert({ type: "warning", message: "Vui lòng chọn Phần mềm!" });
                                return;
                            }
                            if (!chosenIDs || chosenIDs.length === 0) {
                                if (window.uiManager) uiManager.showAlert({ type: "warning", message: "Vui lòng nhập ít nhất 1 ZaloID người nhận!" });
                                return;
                            }
                            if (!selectedDate) {
                                if (window.uiManager) uiManager.showAlert({ type: "warning", message: "Vui lòng chọn thời gian chạy!" });
                                return;
                            }

                            let d = new Date(selectedDate);
                            let hour = d.getHours();
                            let minute = d.getMinutes();
                            let nextRunStr = DevExpress.localization.formatDate(d, "yyyy-MM-dd HH:mm:ss");
                            let paramStr = chosenIDs.join(",");

                            AjaxHPAParadise({
                                data: {
                                    name: "sp_zalo_createAI_TaskSchedule",
                                    param: [
                                        "LoginID", UserID,
                                        "LanguageID", LanguageID,
                                        "ActionType", isEdit ? "UPDATE" : "INSERT",
                                        "TaskScheduleID", editTaskID || "",
                                        "TaskName", taskName,
                                        "TaskType", runType,
                                        "Hour", hour,
                                        "Minute", minute,
                                        "NextRun", nextRunStr,
                                        "Params", paramStr,
                                        "ProductID", chosenProduct
                                    ]
                                },
                                success: function() {
                                    $addPopup.dxPopup("instance").hide();
                                    if (window.uiManager) uiManager.showAlert({ type: "success", message: isEdit ? "%zalo_schedule_update_success%" : "%zalo_schedule_create_success%" });
                                    loadScheduleList();
                                },
                                error: function() {
                                    if (window.uiManager) uiManager.showAlert({ type: "error", message: "%zalo_schedule_save_error%" });
                                }
                            });
                        }
                    });

                    $addPopup.dxPopup({
                        title: isEdit ? "%zalo_schedule_title_edit%" : "%zalo_schedule_title_add%",
                        width: Math.min($(window).width() * 0.9, 500),
                        height: Math.min($(window).height() * 0.9, 580),
                        visible: true,
                        showCloseButton: true,
                        hideOnOutsideClick: true,
                        contentTemplate: function(c) { c.css({padding:"10px", overflowY:"auto"}).append($form); },
                        onHidden: function() { $addPopup.remove(); }
                    });
                }

                // Nút thêm mới
                $topBar.dxButton({
                    text: "%zalo_schedule_add_new%",
                    icon: "plus",
                    elementAttr: { class: "btn-success-paradise" },
        onClick: openAddForm
                });

                $popup.dxPopup({
                    title: "%zalo_schedule_title_main%",
                    width: Math.min($(window).width() * 0.9, 600),
                    height: Math.min($(window).height() * 0.85, 480),
                    visible: true,
                    showCloseButton: true,
                    hideOnOutsideClick: true,
                    contentTemplate: function(contentElement) {
                        contentElement.css({ padding: "14px" }).append($innerWrap);
                    },
                    onShown: function() { loadScheduleList(); },
                    onHidden: function() { $popup.remove(); }
                });
            }

            function updateAIDebugIcon() {
                let $fab = $("#AI_Debug_FAB");
                if (!$fab.length) {
                    $fab = $("<div id=''AI_Debug_FAB'' title=''Lịch sử Test AI'' style=''position:fixed; bottom:30px; right:30px; width:50px; height:50px; border-radius:12px; background:var(--paradise-color-logo-main); color:white; display:flex; align-items:center; justify-content:center; cursor:pointer; box-shadow: 0 4px 12px rgba(0,0,0,0.3); z-index:10005; transition: all 0.3s; opacity:0; transform: scale(0);''><i class=''dx-icon dx-icon-box''></i></div>").appendTo("body");
                    $fab.on("click", function() {
                        showAIHistoryList();
                    });
                }

                if (aiHistory_Log.length > 0) {
                    $fab.css({ "opacity": "1", "transform": "scale(1)" });
                } else {
                    $fab.css({ "opacity": "0", "transform": "scale(0)" });
                }
            }

            function showAIHistoryList() {
                if (aiHistory_Log.length === 0) return;

                let $container = $("<div style=''padding:10px;'' />");
                let $list = $("<div />").appendTo($container);

                $list.dxList({
                    dataSource: aiHistory_Log,
                    scrollByContent: false, // Để ScrollView bên ngoài xử lý cuộn toàn bộ
                    itemTemplate: function(data) {
                        return $("<div style=''padding:8px;'' />").append(
                            $("<span style=''font-weight:bold; color:var(--paradise-color-header1);'' />").text("[" + data.timestamp + "] "),
                            $("<span />").text("%zalo_auto_test_at%" + data.timestamp)
                        );
                    },
                    onItemClick: function(e) {
                        showAIHistoryDetail(e.itemData);
                    }
                });

                // Nút Xóa Lịch sử đặt ở cuối danh sách
                let $btnGroup = $("<div style=''display:flex; justify-content:flex-end; gap:10px; margin-top:20px; padding-bottom:10px;'' />");
                $("<div />").dxButton({
                    text: "%zalo_auto_delete_history%",
                    icon: "trash",
                    type: "danger",
                    stylingMode: "contained",
                    onClick: function() {
                        DevExpress.ui.dialog.confirm("%zalo_auto_confirm_delete_history%", "%Confirm%").done(function(result) {
                            if (result) {
                                aiHistory_Log = [];
                                updateAIDebugIcon();
                                $("#Popup_AIHistory").dxPopup("instance").hide();
                                if (window.uiManager) uiManager.showAlert({ type: "success", message: "%zalo_auto_delete_history_success%" });
                            }
                        });
                    }
                }).appendTo($btnGroup);

                $container.append($btnGroup);

                let $popupContainer = $("<div id=''Popup_AIHistory'' />").appendTo("body");
                $popupContainer.dxPopup({
                    title: "%zalo_auto_history_title%",
                    width: 400,
                    height: 500,
                    visible: true,
                    dragEnabled: true,
                    showCloseButton: true,
                    closeOnOutsideClick: true,
                    contentTemplate: function(contentElement) {
                        let scrollView = $("<div />").dxScrollView({ width: "100%", height: "100%", direction: "vertical" });
                        scrollView.dxScrollView("instance").content().append($container);
                        contentElement.append(scrollView);
                    },
                    onHidden: function() { $popupContainer.remove(); }
                });
            }

            function showAIHistoryDetail(historyItem) {
                let $popupDetail = $("<div />").appendTo("body");
                const popupHeight = Math.min($(window).height() * 0.9, 650);
                $popupDetail.dxPopup({
                    title: "%zalo_auto_detail_title%" + historyItem.timestamp,
                    width: Math.min($(window).width() * 0.9, 850),
                    height: popupHeight,
                    visible: true,
                    dragEnabled: true,
                    showCloseButton: true,
                    closeOnOutsideClick: true,
                    contentTemplate: function(contentElement) {
                        $(contentElement).css("padding", "0");
                        let $tabPanel = $("<div />").css("height", "100%").appendTo(contentElement);
                        $tabPanel.dxTabPanel({
                            height: "100%",
                            dataSource: [
                                { title: "%zalo_auto_result%", icon: "box", type: "result" },
                                { title: "%zalo_auto_rule%", icon: "info", type: "prompt" }
                            ],
                            selectedIndex: 0,
                            itemTemplate: function(data, index, element) {
                                $(element).css("height", "100%");
                                let $container = $("<div style=''height:100%; position:relative; overflow:hidden;'' />");

                                // Ép chiều cao cụ thể để thanh cuộn luôn hoạt động (trừ đi phần header/tabs khoảng 110px)
                                let $scrollView = $("<div />").appendTo($container).dxScrollView({
                                    height: (popupHeight - 110) + "px",
                                    width: "100%",
                                    direction: "both",
                                    showScrollbar: "always",
                                    useNative: false
                                });

                                if (data.type === "result") {
                                    let results = historyItem.results || {};
                                    let keys = Object.keys(results);
                                    let fullData = [];
                                    try {
                                        fullData = window.gridInstance.getDataSource().items() || [];
                                        if (fullData.length === 0 && window.gridInstance.getDataSource().store()._array) {
                                            fullData = window.gridInstance.getDataSource().store()._array;
                                        }
                                    } catch(e) {}

                                    let $listContainer = $("<div style=''padding:15px;'' />").appendTo($scrollView.dxScrollView("instance").content());

                                    if (keys.length > 1) {
 let selectorData = keys.map(function(k) {
                                            let r = fullData.find(function(row) { return (row.zaloID || row.ZaloID || "").toString() === k.toString(); });
                                            return { id: k, name: r ? (r.zaloName || r.Name || r.ZaloName) : ("Khách hàng " + k) };
                                        });
                                        $("<div style=''font-weight:bold; color:var(--paradise-color-header1); margin-bottom:5px; font-size:12px;'' />").text("%zalo_auto_select_customer%").appendTo($listContainer);
                                        $("<div style=''margin-bottom:20px;'' />").appendTo($listContainer).dxSelectBox({
                                            dataSource: selectorData,
                                            displayExpr: "name",
                                            valueExpr: "id",
                                            value: keys[0],
                                            onValueChanged: function(e) { renderSingleResult(e.value, true); }
                                        });
                                    }

                                    let $resultContent = $("<div />").appendTo($listContainer);

                                    function renderSingleResult(zaloID, hideName) {
                                        $resultContent.empty();
                                        if (!zaloID) return;

                                        let msg = results[zaloID.toString()] || results[zaloID];
                                        let $item = $("<div style=''padding:10px 0; border-left:4px solid var(--paradise-color-logo-main); padding-left:15px;'' />");

                                        if (!hideName) {
                                            let r = fullData.find(function(row) {
                                                let rId = (row.zaloID || row.ZaloID || "").toString();
                                                return rId === zaloID.toString();
                                            });
                                            let name = r ? (r.zaloName || r.Name || r.ZaloName) : ("Khách hàng " + zaloID);
                                            $("<div style=''font-weight:bold; font-size:16px; color:var(--paradise-color-header1); margin-bottom:8px; border-bottom: 1px dashed #ccc; padding-bottom: 8px;'' />").text(name).appendTo($item);
                                        }

                                        $("<div style=''font-size:14px; white-space:pre-wrap; color:var(--paradise-color-brown); line-height: 1.6;'' />").text(msg || "%zalo_auto_no_msg%").appendTo($item);
                                        $item.appendTo($resultContent);
                                    }

                                    if (keys.length > 0) renderSingleResult(keys[0], keys.length > 1);
                                    else $listContainer.append($("<div style=''text-align:center; padding:20px; color:#999;'' />").text("%zalo_auto_no_data%"));

                                } else {
                                    // Nút Copy
                                    let $copyBtn = $("<div style=''position:absolute; top:5px; right:15px; z-index:10;'' />").appendTo($container);
                                    $copyBtn.dxButton({
                                        icon: "copy",
                                        hint: "%zalo_auto_copy_prompt%",
                                        type: "default",
                                        stylingMode: "text",
                                        onClick: function() {
                                            if (navigator.clipboard) {
                                                navigator.clipboard.writeText(historyItem.prompt).then(function() {
                                                    if (window.uiManager) uiManager.showAlert({ type: "success", message: "%zalo_auto_copy_success%" });
                                                });
                                            }
                                        }
                                    });

                                    // Hiển thị Prompt GỐC bằng thẻ <pre>
                                    let $promptContent = $("<pre style=''margin:0; padding:15px; font-family:''Consolas'', ''Monaco'', monospace; white-space:pre; font-size:12px; color:var(--paradise-color-brown); line-height: 1.5;'' />")
                                        .text(historyItem.prompt || "Không có dữ liệu Prompt.");
                                    $scrollView.dxScrollView("instance").content().append($promptContent);
                                }
                                element.append($container);
                            },
                            onSelectionChanged: function() {
                                setTimeout(function() { $(".dx-scrollview").dxScrollView("instance").update(); }, 150);
                            }
                        });
                    },
                    onHidden: function() { $popupDetail.remove(); }
                });
            }

            // Kiểm tra trạng thái đăng nhập ngay khi load
            checkZaloStatus();

            function open_zaloLogin(LoginID) {
                if (typeof openFormParam === "function") {
                    openFormParam(`sp_zalo`, { LoginID: LoginID, LanguageID: LanguageID, isWeb: window.isWeb });
                }
            }

            async function checkZaloStatus() {
                let res = await AjaxHPAParadiseAsync({
                    data: {
                        name: "sp_ViewZaloClient",
                        param: ["LoginID", UserID]
                    }
                });
                if(!res){
                    uiManager.showAlert({ type: "error", message: "%Error%" });
                    return;
                }
                let jsonRes = (typeof res === "string") ? JSON.parse(res) : res;
                if (jsonRes.data[0][0].status === "haveLogout") {
                    if (typeof showConfirmPopup === "function") {
                        showConfirmPopup({
                            title: "%Confirm%",
                            message: "%zalo_logout_confirm%",
                            YesText: "%Agree%",
                            NoText: "%Cancel%",
                            onYes: () => {
                                open_zaloLogin(UserID);
                            }
                        });
                    }
                }
            }


            function loadFriendAvatars() {
                AjaxHPAParadise({
                    data: {
                        name: "sp_zalo_getFriendAvatar",
                        param: ["LoginID", UserID]
                    },
                    success: function (res) {
                        let json = typeof res === "string" ? JSON.parse(res) : res;
                        let data = json.data?.[0] || [];
                        data.forEach(function(item) {
                            if (item.zaloID) friendAvatarMap[item.zaloID] = item.avatar;
                        });
                        // Sau khi load xong ảnh bạn bè → repaint grid để hiện ảnh ghép group
                        if (window.gridInstance) {
                            window.gridInstance.repaint();
                        }
                    }
                });
            }
            loadFriendAvatars();

            // ============================================================
            // 1. KHỞI TẠO DATASTORE DUY NHẤT MỘT LẦN
            // ============================================================
            dataStore_GridZalo = new DevExpress.data.CustomStore({
                key: "zaloID",
                byKey: function(key) {
                    let d = new $.Deferred();
                    d.resolve({ zaloID: key });
                    return d.promise();
                },
                load: function(loadOptions) {
                    const deferred = $.Deferred();

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
                    // SP nghiệp vụ
                    params.push("@ProcName", "sp_zalo_Grid");
                    // Lấy giá trị tag đã chọn trực tiếp từ control hoặc biến state
                    let tagVal = "";
                    try {
                        let tagBox = $("#P36EB8FEA286C46F7A109BD6404CA9BAA").dxSelectBox("instance");
                        if (tagBox) tagVal = tagBox.option("value") || "";
                    } catch(ex) {}
                    if (!tagVal) tagVal = _currentTagID || "";

                    // 2. Tính toán Sort
                    const sort = loadOptions.sort
                        ? loadOptions.sort.map(s => s.selector + (s.desc ? " DESC" : " ASC")).join(",")
                        : "lastActionTime DESC";

                    // 3. Kiểm tra Cache
                    const cacheKey = JSON.stringify({
                        skip: loadOptions.skip,
                        take: loadOptions.take,
                        keyword: _currentKeyword,
                        tag: tagVal,
                        sort: sort,
                        filter: loadOptions.filter
                    });

                    if (_pageCache[cacheKey]) {
                        deferred.resolve(_pageCache[cacheKey]);
                        return deferred.promise();
                    }

                    // 4. Chuẩn bị Parameters
                    let procParam = "@LoginID = " + (window.UserID || window.LoginID) + ", @LanguageID = " + window.LanguageID
                        + ", @tagID = N''" + tagVal + "''"
                        + ", @SearchValue = N''" + (_currentKeyword || "") + "''";

                    console.log("🚀 Grid Load Params:", { tagVal, _currentKeyword, procParam });
                    params.push("@ProcParam", procParam);
                    params.push("@tagID", tagVal);

                    // Phân trang
                    params.push("@Take", loadOptions.take || 50);
                    params.push("@Skip", loadOptions.skip || 0);

                    // TotalCount
                    if (loadOptions.requireTotalCount) {
                        params.push("@RequireTotalCount", 1);
                    }
                    params.push("@Sort", "ORDER BY " + sort);

                    // Search
                    if (_currentKeyword) {
                        params.push("@SearchValue", _currentKeyword);
                        params.push("@ColumnSearch", "zaloName");
                    }

                    // Filter
                    if (loadOptions.filter) {
                        const hasFunction = JSON.stringify(loadOptions.filter).includes(''FUNCTION'');
                        if (!hasFunction) {
                            params.push("@Filters", createConditionQuery(loadOptions.filter));
                        }
                    }

                   // Summary
                    if (loadOptions.totalSummary) {
                        const summary = loadOptions.totalSummary.map(item => {
                            const type = item.summaryType === "custom"
                                ? `count(CASE WHEN [${item.selector}] = 1 THEN 1 END) as ${item.selector}_COUNT`
                                : `${item.summaryType}([${item.selector}]) as ${item.selector}_${item.summaryType.toUpperCase()}`;
                            return type;
                        });
                        params.push("@TotalSummary", summary.join(", "));
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
                                let tc = json?.data?.[1]?.[0]?.TotalCount;
                                if (tc === undefined || tc === null) tc = json?.data?.[1]?.[0]?.totalCount;
                                if (tc === undefined || tc === null) tc = results.length;
                                result.totalCount = tc;

                                if (loadOptions.totalSummary) {
                                    result.summary = Object.values(json?.data?.[2]?.[0] ?? {});
                                }
                            } else {
                                if (loadOptions.totalSummary) {
                                    result.summary = Object.values(json?.data?.[1]?.[0] ?? {});
                                }
                            }

                            DataSource = results;

                            // Lưu vào cache
                            _pageCache[cacheKey] = result;

                            deferred.resolve(result);

                            if (window._pendingSelectionCheck) {
                                setTimeout(function() {
                                    if (typeof applySelectionLogic === "function") applySelectionLogic(window._pendingMenuID);
                                    window._pendingSelectionCheck = false;
                                    window._pendingMenuID = undefined;
                                }, 300);
                            }
                        },
                    });

                    return deferred.promise();
                }
            });


            // Khi SelectBox thay đổi → reload grid với tagID mới hoặc xử lý chọn số lượng
            window["onSelectBoxChanged_P36EB8FEA286C46F7A109BD6404CA9BAA"] = function(value, instance, e) {
                console.log("Zalo Grid Filter Changed:", value);
                _currentTagID = (value != null && value !== "" && value != 0) ? value.toString() : "";
                _pageCache = {};

                // Thực hiện refresh grid
                try {
                    let grid = $("#GridZalo").dxDataGrid("instance");
                    if (grid) {
                        grid.refresh();
                    } else if (window.gridInstance) {
                        window.gridInstance.refresh();
                    }
                } catch(ex) {
                    console.error("Refresh grid error:", ex);
                }
            };

            window["onSelectBoxChanged_PC3ECBD81231B40B294775F6A0D74C861"] = function(value, instance, e) {
                if (!e.event) return;
                if (typeof applySelectionLogic === "function") applySelectionLogic();
            };

            window["onSelectBoxChanged_Số lượng"] = window["onSelectBoxChanged_PC3ECBD81231B40B294775F6A0D74C861"];
            window["onSelectBoxChanged_So luong"] = window["onSelectBoxChanged_PC3ECBD81231B40B294775F6A0D74C861"];
            window["onSelectBoxChanged_Phần mềm"] = window["onSelectBoxChanged_P36EB8FEA286C46F7A109BD6404CA9BAA"];
            window["onSelectBoxChanged_Phan mem"] = window["onSelectBoxChanged_P36EB8FEA286C46F7A109BD6404CA9BAA"];

            window._pendingSelectionCheck = false;
            window._pendingMenuID = undefined;

            // Helper: Lấy menuID hiện tại từ Custom Segmented Control
            function getCurrentMenuID() {
                try {
                    let inst = window["InstanceSegmented_zalo_autoSendMessage_statusPAEF4A083A6D44ACD92F01B2834695EED"];
                    if (inst) return inst.getValue();
                } catch(ex) {}
                return undefined;
            }

            let _lastMenuID = null;

            // Callback hệ thống: khi người dùng click chọn menu (Đoạn đầu / Đặt biệt / Gần đây / Tất cả)
            window["onSegmentedChanged_zalo_autoSendMessage_statusPAEF4A083A6D44ACD92F01B2834695EED"] = function(id, step) {
                console.log("taidang~ onSegmentedChanged, menuID =", id, "_lastMenuID =", _lastMenuID);

                // Nếu click lại cái đang chọn (và không phải là "Tất cả") -> Reset về "Tất cả"
                if (id !== -1 && id === _lastMenuID) {
                    _lastMenuID = -1;
                    try {
                        let inst = $("#PAEF4A083A6D44ACD92F01B2834695EED").dxButtonGroup("instance");
                        if (inst) inst.option("selectedItemKeys", [-1]);
                    } catch(ex) {}

                    // Xóa các tích chọn
                    customSelectedKeys_GridZalo = [];
                    let grid = $("#GridZalo").dxDataGrid("instance");
                    if (grid) safeRepaintGrid(grid);
                    return;
                }

                _lastMenuID = id;

                try {
                    let numInst = $("#PC3ECBD81231B40B294775F6A0D74C861").dxSelectBox("instance");
                    if (numInst) {
                        if (id == -1) {
                            // Nếu chọn "Tất cả" thì clear số lượng
                            numInst.option("value", null);
                        } else if (!numInst.option("value")) {
                            // Tự set Số lượng mặc định = 1 (10 dòng) nếu chọn menu khác mà chưa có số lượng
                            numInst.option("value", 1);
                        }
                    }
                } catch(ex) {}
                applySelectionLogic(id);
            };

            // Bổ sung xử lý onItemClick để bắt được sự kiện click lại menu đang chọn (vì onSegmentedChanged chỉ chạy khi value đổi)
            setTimeout(function() {
                try {
                    let seg = $("#PAEF4A083A6D44ACD92F01B2834695EED").dxButtonGroup("instance");
                    if (seg) {
                        seg.off("itemClick").on("itemClick", function(e) {
                            let currentVal = seg.option("selectedItemKeys")[0];
                            if (e.itemData.ID === currentVal && currentVal !== -1) {
                                window["onSegmentedChanged_zalo_autoSendMessage_statusPAEF4A083A6D44ACD92F01B2834695EED"](currentVal);
                            }
                        });
                    }
                } catch(ex) {}
            }, 1000);

            // Helper: Lấy numVal từ SelectBox Số lượng
            function getCurrentNumVal() {
                let numVal = 10; // fallback mặc định
                try {
                    let numInst = $("#PC3ECBD81231B40B294775F6A0D74C861").dxSelectBox("instance");
                    if (numInst) {
                        let numBoxID = numInst.option("value");
                        let item = numInst.option("selectedItem");
                        if (item && item.Name) {
                            let matches = item.Name.toString().match(/\d+/g);
                            if (matches) numVal = parseInt(matches[matches.length - 1]);
                        } else if (numBoxID) {
                            if (numBoxID == 1) numVal = 10;
                            else if (!isNaN(parseInt(numBoxID))) {
                                numVal = parseInt(numBoxID); // Nhận số do user nhập thủ công (vd: 41)
                            }
                            else {
                                let found = PC3ECBD81231B40B294775F6A0D74C861_data.find(function(x) { return x.ID == numBoxID; });
                                if (found && found.Name) {
                                    let m = found.Name.toString().match(/\d+/g);
                                    numVal = m ? parseInt(m[m.length - 1]) : 10;
                                }
                            }
                        }
                    }
                } catch(ex) {}
                return numVal;
            }

            // Hàm repaint/refresh an toàn: cất các control đi trước khi Grid xóa DOM của toolbar
            function safeRepaintGrid(gridObj, isRefresh) {
                if (!gridObj) return;
                $("#P36EB8FEA286C46F7A109BD6404CA9BAA").appendTo("#SelectBoxContainer_Temp");
                $("#PC3ECBD81231B40B294775F6A0D74C861").appendTo("#SelectBoxContainer_Temp");
                $("#PAEF4A083A6D44ACD92F01B2834695EED").appendTo("#SelectBoxContainer_Temp");
                $("#PBE6706C7F3944933A71F067C581E0677").appendTo("#SelectBoxContainer_Temp");
                if (isRefresh) gridObj.refresh();
                else gridObj.repaint();
            }

            async function applySelectionLogic(menuID) {
                let skel = null;
                try {
                    let grid = $("#GridZalo").dxDataGrid("instance");
                    if (!grid) return;

                    // Tự đọc menuID nếu không truyền vào
                    if (menuID === undefined) menuID = getCurrentMenuID();
                    let numVal = getCurrentNumVal();

                    console.log("taidang~", { menuID: menuID, numVal: numVal });

                    // Cập nhật trạng thái Chọn Tất Cả
                    if (menuID == -1) isSelectAllActive_GridZalo = true;
                    else isSelectAllActive_GridZalo = false;

                    if (numVal <= 0 && menuID != -1 && menuID != 3) return;

                    // Hiển thị Skeleton Screen chuẩn hệ thống
                    if (window.uiManager && uiManager.showSkeleton) {
                        skel = uiManager.showSkeleton({ target: "#GridZalo", type: "list" });
                    }

                    // Lấy Filter hiện tại
                    let tagID = "";
                    try {
                        let tagBox = $("#P36EB8FEA286C46F7A109BD6404CA9BAA").dxSelectBox("instance");
                        if (tagBox) tagID = tagBox.option("value") || "";
                    } catch(ex) {}

                    // Gọi API lấy full danh sách thỏa mãn điều kiện tìm kiếm/lọc để select đúng qua các trang lazy load
                    let res = await AjaxHPAParadiseAsync({
                        data: {
                            name: "sp_zalo_Grid",
                            param: [
                                "LoginID", UserID,
                                "LanguageID", LanguageID,
                                "TempTableAPIName", "",
                                "SearchValue", _currentKeyword,
                                "tagID", tagID
              ]
                        }
                    });

                    let json = typeof res === "string" ? JSON.parse(res) : res;
                    let allData = (json.data && json.data[0]) ? json.data[0] : [];
                    let selectedData = [];

                    if (menuID == -1) {
                        // Tất cả
                        selectedData = allData;
                    } else if (menuID == 1) {
                        // Đoạn đầu (đã sort DESC từ DB)
                        selectedData = allData.slice(0, numVal);
                    } else if (menuID == 2) {
                        // Đặt biệt: N dòng có lastActionTime cũ nhất (ASC)
                        let sorted = allData.slice().sort(function(a, b) {
                            let ta = a.lastActionTime ? new Date(a.lastActionTime).getTime() : 0;
                            let tb = b.lastActionTime ? new Date(b.lastActionTime).getTime() : 0;
                            return ta - tb;
                        });
                        selectedData = sorted.slice(0, numVal);
                    } else if (menuID == 3) {
                        // Gần đây: Lấy lịch sử từ bảng tblZalo_AdvertisingHistory
                        if (!tagID || tagID == 0) {
                            if (window.uiManager) uiManager.showAlert({ type: "warning", message: "%zalo_auto_select_software_first%" });
                            return;
                        }

                        let historyRes = await AjaxHPAParadiseAsync({
                            data: {
                                name: "sp_zalo_getAdHistory",
                                param: ["ProductID", tagID, "LanguageID", LanguageID]
                            }
                        });
                        let historyJson = typeof historyRes === "string" ? JSON.parse(historyRes) : historyRes;
                        let historyIDs = (historyJson.data && historyJson.data[0]) ? historyJson.data[0].map(function(x) { return (x.zaloID || "").toString(); }) : [];

                        // Lọc những ID có trong lịch sử và đang hiển thị trong grid hiện tại
                        selectedData = allData.filter(function(r) {
                            return historyIDs.includes((r.zaloID || "").toString());
                        });
                    }

                    let keys = selectedData.map(function(r) { return r.zaloID; });
                    console.log("taidang~ keys selected:", keys.length);

                    customSelectedKeys_GridZalo = keys;
                    safeRepaintGrid(grid);
                } catch(ex) {
                    console.error("applySelectionLogic error:", ex);
                } finally {
                    if (skel && window.uiManager && uiManager.hideSkeleton) uiManager.hideSkeleton();
                    else if (skel && typeof skel.remove === "function") skel.remove();
                }
            }

            function loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback) {
                if (!columnName || !dataSourceSP || dataSourceSP.trim() === "") return;

                const dataSourceKey = "DataSource_" + dataSourceSP;
                const loadedKey = dataSourceSP + "DataSourceLoaded";

                if (window[loadedKey] === true) {
                    let data = window[dataSourceKey] || [];
                    if (dataSourceSP === "sp_zalo_getMarketingProduction") {
                        P36EB8FEA286C46F7A109BD6404CA9BAA_data = data;
                        if (window.gridInstance) window.gridInstance.repaint();
                    } else if (dataSourceSP === "sp_zalo_get_autoSendMessage_numberSelection") {
                        PC3ECBD81231B40B294775F6A0D74C861_data = data;
                    } else if (dataSourceSP === "sp_zalo_get_autoSendMessage_Menu") {
                        PAEF4A083A6D44ACD92F01B2834695EED_data = data;
                    } else if (dataSourceSP === "sp_zalo_get_autoSendMessage_AI_Menu") {
                        PBE6706C7F3944933A71F067C581E0677_data = data;
                    }
                    if (typeof onSuccessCallback === "function") onSuccessCallback(data);
                    return Promise.resolve(data);
                }

                if (window[loadedKey] === "loading") {
                    setTimeout(function() { loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback); }, 100);
                    return;
                }

                window[loadedKey] = "loading";

                return new Promise((resolve, reject) => {
                    AjaxHPAParadise({
                        data: {
                            name: dataSourceSP,
                            param: ["LoginID", UserID, "LanguageID", LanguageID]
                        },
                        success: function (res) {
                            const json = typeof res === "string" ? JSON.parse(res) : res;
                            const data = (json.data && json.data[0]) || [];

                            window[dataSourceKey] = data;
                            window[loadedKey] = true;

                            // Gán vào biến let theo yêu cầu của người dùng
                            if (dataSourceSP === "sp_zalo_getMarketingProduction") {
                                P36EB8FEA286C46F7A109BD6404CA9BAA_data = data;
                                if (window.gridInstance) window.gridInstance.repaint();
                            } else if (dataSourceSP === "sp_zalo_get_autoSendMessage_numberSelection") {
                                PC3ECBD81231B40B294775F6A0D74C861_data = data;
                            } else if (dataSourceSP === "sp_zalo_get_autoSendMessage_Menu") {
                                PAEF4A083A6D44ACD92F01B2834695EED_data = data;
                            } else if (dataSourceSP === "sp_zalo_get_autoSendMessage_AI_Menu") {
                                PBE6706C7F3944933A71F067C581E0677_data = data;
                            }

                            if (typeof onSuccessCallback === "function") onSuccessCallback(data);
                            resolve(data);
                        },
                        error: function (err) {
                            window[loadedKey] = false;
                            reject(err);
                        }
                    });
                });
            }

            window.currentRecordID_ID = null; window.currentRecordID_zaloID = null;

            function clearPageCache() {
                _pageCache = {};
            }

            function getGridHeight() {
                const gridEl = InstanceGridZaloP573D5BF0C93B424BA49F7C7FE5871D8B.element();
                const domElement = gridEl.jquery ? gridEl[0] : gridEl;
                const top = domElement.getBoundingClientRect().top;
                return window.innerHeight - top - 20;
            }

            // ============================================================
            // 2. KHỞI TẠO GRID LAYOUT MỘT LẦN DUY NHẤT
            // ============================================================
            let gridInstance = null;
            try {
                gridInstance = $("#GridZalo").dxDataGrid("instance");
            } catch(ex) {
                // Fallback nếu chưa có instance
                gridInstance = InstanceGridZaloP573D5BF0C93B424BA49F7C7FE5871D8B;
            }
            window.gridInstance = gridInstance;

            function applyResponsiveGridLayout() {
                if (!gridInstance) return;
                var w = $("#GridZalo").outerWidth() || window.innerWidth || 1200;
                var isMobile = w < 576;
                var isTablet = w >= 576 && w < 992;

                try {
                    gridInstance.option("height", getGridHeight());
                    gridInstance.option("searchPanel.width", isMobile ? "100%" : (isTablet ? 220 : 240));
                    gridInstance.option("columnMinWidth", isMobile ? 56 : 72);

                    gridInstance.columnOption("avatar", { width: isMobile ? 54 : 72, minWidth: isMobile ? 48 : 64, allowHiding: false, hidingPriority: 10 });
                    gridInstance.columnOption("zaloName", { width: isMobile ? 158 : (isTablet ? 210 : 260), minWidth: 130, allowHiding: false, hidingPriority: 11 });
                    gridInstance.columnOption("lastActionTime", { width: isMobile ? 118 : (isTablet ? 150 : 170), minWidth: 108, hidingPriority: 7 });
                    gridInstance.columnOption("isGroup", { width: isMobile ? 92 : 120, minWidth: 84, hidingPriority: 5 });
                    gridInstance.columnOption("tag", { width: isMobile ? 120 : 180, minWidth: 100, hidingPriority: 3 });
                    gridInstance.columnOption("memVerList", { width: isMobile ? 120 : 180, minWidth: 100, hidingPriority: 1 });
                    gridInstance.columnOption("zaloID", { visible: !isMobile, hidingPriority: 0 });

                    gridInstance.updateDimensions();
                } catch (ex) {
                    console.warn("applyResponsiveGridLayout failed", ex);
                }
            }

            var _zaloResizeTimer = null;
            $(window).off("resize.zaloAutoResponsive").on("resize.zaloAutoResponsive", function() {
                clearTimeout(_zaloResizeTimer);
                _zaloResizeTimer = setTimeout(function() { applyResponsiveGridLayout(); }, 160);
            });

            if (!gridInstance) return;

            gridInstance.beginUpdate();
            gridInstance.option("remoteOperations", {
                paging: true, filtering: true, sorting: true, searching: true
            });

            gridInstance.option({
                selection: {
                    mode: "none"
                },
                onCellClick: function(e) {
                    if (e.rowType !== "data") return;

                    // Chỉ xử lý mở Detail khi click vào Ảnh hoặc Tên Zalo
                    if (e.column && (e.column.dataField === "zaloName" || e.column.dataField === "avatar")) {
                        openDetailzaloID(e.data);
                    }
                },
                "scrolling.mode": "infinite",
                "scrolling.rowRenderingMode": "virtual",
                "scrolling.preloadEnabled": false,
                "paging.enabled": true,
                "paging.pageSize": 50,
                "pager.visible": false,
                "columnAutoWidth": false,
                "wordWrapEnabled": false,
                "columnHidingEnabled": true,
                "allowColumnResizing": true,
                "columnResizingMode": "widget",
                "scrolling.useNative": true,
                "scrolling.showScrollbar": "onHover",
                "searchPanel.highlightSearchText": false,
                "dataSource": dataStore_GridZalo,
                "height": getGridHeight(),
                "width": "100%",
                onToolbarPreparing: function(e) {
                    e.toolbarOptions.items.unshift({
                        location: "before",
                        template: function() {
                            return $("<div class=''zalo-auto-toolbar''>" +
                                        "<div id=''Toolbar_SelectBox_Placeholder'' class=''zalo-auto-toolbar__software''></div>" +
                                        "<div id=''Toolbar_Quantity_Placeholder'' class=''zalo-auto-toolbar__quantity''></div>" +
                                        "<div id=''Toolbar_Segmented_Placeholder'' class=''zalo-auto-toolbar__segment''></div>" +
                                        "<div id=''Toolbar_AIMenu_Placeholder'' class=''zalo-auto-toolbar__ai''></div>" +
                                        "<div id=''Toolbar_AIGear_Placeholder'' class=''zalo-auto-toolbar__gear''></div>" +
                                    "</div>");
                        }
                    });
                },
                onContentReady: function(e) {
                    // Di chuyển SelectBox Chọn phần mềm thực vào placeholder trong toolbar
                    let $placeholder = $("#Toolbar_SelectBox_Placeholder");
                    let $sb = $("#P36EB8FEA286C46F7A109BD6404CA9BAA");
                    if ($placeholder.length && $sb.length) {
                         if ($sb.parent()[0] !== $placeholder[0]) {
                             $sb.appendTo($placeholder);
                         }

                         // Thiết lập placeholder và xử lý giá trị 0
                         try {
                             let inst = $sb.dxSelectBox("instance");
                             if (inst) {
                                 inst.option("placeholder", "%zalo_auto_software%");
                                 if (P36EB8FEA286C46F7A109BD6404CA9BAA_data.length > 0) {
                                     inst.option("dataSource", P36EB8FEA286C46F7A109BD6404CA9BAA_data);
                                 }
                                 let val = inst.option("value");
                                 if (val === 0 || val === "0") inst.option("value", null);

                                 // Backup listener để đảm bảo luôn refresh grid
                                 inst.off("valueChanged").on("valueChanged", function(ev) {
                                     if (ev.event) { // Chỉ xử lý khi người dùng thao tác trực tiếp
                                         _currentTagID = (ev.value != null && ev.value !== "" && ev.value != 0) ? ev.value.toString() : "";
                                         _pageCache = {};
                                         try {
                                             let grid = $("#GridZalo").dxDataGrid("instance");
                                             if (grid) grid.refresh();
                                             else if (window.gridInstance) window.gridInstance.refresh();
                                         } catch(err) {}
                                     }
                                 });
                             }
                         } catch(ex) {}
                    }

                    // Di chuyển Segmented Control vào placeholder
                    let $segPlaceholder = $("#Toolbar_Segmented_Placeholder");
                    if ($segPlaceholder.length && $("#PAEF4A083A6D44ACD92F01B2834695EED").parent().attr("id") !== "Toolbar_Segmented_Placeholder") {
                        $("#PAEF4A083A6D44ACD92F01B2834695EED").appendTo($segPlaceholder);
                    }

                    // Di chuyển Quantity SelectBox vào placeholder
                    let $qtyPlaceholder = $("#Toolbar_Quantity_Placeholder");
                    if ($qtyPlaceholder.length && $("#PC3ECBD81231B40B294775F6A0D74C861").parent().attr("id") !== "Toolbar_Quantity_Placeholder") {
                        let $qtySb = $("#PC3ECBD81231B40B294775F6A0D74C861");
                        $qtySb.appendTo($qtyPlaceholder);

                        try {
                            let inst = $qtySb.dxSelectBox("instance");
                            if (inst) {
                                inst.option("placeholder", "%zalo_auto_quantity%");
                                inst.option("acceptCustomValue", true); // Bật tính năng cho phép nhập số tự do
                                inst.option("onCustomItemCreating", function(args) {
                                    if (!args.text) {
                                        args.customItem = null;
                                        return;
                                    }
                                    let val = parseInt(args.text);
                                    if (isNaN(val) || val <= 0) {
                                        args.customItem = null;
                                        return;
                                    }
                                    let newItem = { ID: val, Name: val + " dòng" };

                                    // Thêm vào dataSource hiện tại để không bị mất khi click ra ngoài
                                    let ds = inst.option("dataSource");
                                    if (Array.isArray(ds)) {
                                        let exists = ds.find(function(x) { return x.ID == val; });
                                        if (!exists) {
                                            ds.push(newItem);
                                            // Sắp xếp lại danh sách theo số lượng tăng dần
                                            ds.sort(function(a, b) { return a.ID - b.ID; });
                                            inst.option("dataSource", ds);
                                        }
                                    }

                                    args.customItem = newItem;
                                    return newItem;
                                });

                                if (PC3ECBD81231B40B294775F6A0D74C861_data.length > 0) {
                                    inst.option("dataSource", PC3ECBD81231B40B294775F6A0D74C861_data);
                                }
                            }
                        } catch(ex) {}
                    }

                    // Di chuyển AI Menu SelectBox vào placeholder
                    let $aiPlaceholder = $("#Toolbar_AIMenu_Placeholder");
                    if ($aiPlaceholder.length && $("#PBE6706C7F3944933A71F067C581E0677").parent().attr("id") !== "Toolbar_AIMenu_Placeholder") {
                        let $aiSb = $("#PBE6706C7F3944933A71F067C581E0677");
                        $aiSb.appendTo($aiPlaceholder);
                     let inst = $aiSb.dxSelectBox("instance");
                        if (inst) {
                            inst.option("placeholder", "%zalo_auto_ai_tasks%");
                            inst.option("dropDownOptions", { width: "auto" });
                            if (PBE6706C7F3944933A71F067C581E0677_data.length > 0) {
                                inst.option("dataSource", PBE6706C7F3944933A71F067C581E0677_data);
                            }
                            inst.option("onItemClick", function(e) {
                                if (!e.itemData) return;
                                let menuID = e.itemData.ID;

                                // ID = 3: Sửa rule (Sửa prompt)
                                if (menuID == 3) {
                                    let productID = "";
                                    try {
                                        let selProduct = $("#P36EB8FEA286C46F7A109BD6404CA9BAA").dxSelectBox("instance");
                                        if (selProduct) productID = selProduct.option("value");
                                    } catch(ex) {}

                                    if (!productID) {
                                        if (window.uiManager) uiManager.showAlert({ type: "warning", message: "%zalo_auto_select_software_warn%" });
                                        setTimeout(() => inst.option("value", null), 100);
                                        return;
                                    }

                                    if (typeof openFormParam === "function") {
                                        openFormParam("sp_zalo_sale_prompt");
                                    }
                                    setTimeout(() => inst.option("value", null), 100);
                                    return;
                                }

                                // ID = 4: Nút cài đặt thời gian chạy tự động từ AI Menu
                                if (menuID == 4) {
                                    openSetAutoPopup();
                                    setTimeout(() => inst.option("value", null), 100);
                                    return;
                                }

                                // Các tác vụ còn lại (ID = 1 hoặc 2) yêu cầu chọn người nhận
                                let selectedIDs = customSelectedKeys_GridZalo.join(",");
                                if (!selectedIDs) {
                                    if (window.uiManager) uiManager.showAlert({ type: "warning", message: "Vui lòng chọn ít nhất 1 người/nhóm để gửi" });
                                    setTimeout(() => inst.option("value", null), 100);
                                    return;
                                }

                                // ID = 2: Thử nghiệm (isTest = 1), ID = 1: Bắt đầu gửi (isTest = 0)
                                let isTest = (menuID == 2 ? 1 : 0);

                                let category = e.itemData ? (e.itemData.ID || e.itemData.Code) : "";

                                // --- LOGIC XỬ LÝ AI ---
                                let productID = "";
                                try {
                                    let selProduct = $("#P36EB8FEA286C46F7A109BD6404CA9BAA").dxSelectBox("instance");
                                    if (selProduct) productID = selProduct.option("value");
                                } catch(ex) {}

                                const startAIExecution = (useSample) => {
                                    let isCancelled = false;
                                    let timerInterval = null;
                                    let $loadingPopup = $("<div />").appendTo("body");
                                    $loadingPopup.dxPopup({
                                        title: "AI đang soạn tin nhắn...",
                                        width: 350,
                                        height: 320,
                                        visible: true,
                                        closeOnOutsideClick: false,
                                        showCloseButton: false,
                                        contentTemplate: function(content) {
                                            let $cont = $("<div style=''text-align:center; padding:20px;'' />").appendTo(content);
                                            $("<div style=''color:var(--paradise-color-header1); font-weight:bold; font-size:16px;'' />").text("Đang xử lý dữ liệu").appendTo($cont);

                                            // Bộ đếm thời gian
                                            let startTime = Date.now();
                                            let $timer = $("<div style=''font-size:24px; font-weight:bold; color:var(--paradise-color-logo-main); margin:15px 0;'' />").text("00:00").appendTo($cont);
                                            timerInterval = setInterval(function() {
                                                let diff = Math.floor((Date.now() - startTime) / 1000);
                                                let m = Math.floor(diff / 60).toString().padStart(2, ''0'');
                                                let s = (diff % 60).toString().padStart(2, ''0'');
                                                $timer.text(m + ":" + s);
                                            }, 1000);

                                            $("<div style=''margin-bottom:15px; font-size:13px; color:#666;'' />").text("Dự kiến hoàn thành trong ~1 phút").appendTo($cont);
                                            $("<div />").dxProgressBar({
                                                min: 0, max: 100, value: 0, statusFormat: () => "Đang chạy..."
                                            }).appendTo($cont);

                                            $("<div style=''margin-top:20px;'' />").dxButton({
                                                text: "Hủy bỏ", type: "danger", stylingMode: "outlined",
                                                onClick: function() {
                                                    isCancelled = true;
                                                    $loadingPopup.dxPopup("instance").hide();
                                                    if (window.uiManager) uiManager.showAlert({ type: "info", message: "Đã hủy yêu cầu AI." });
                                                }
                                            }).appendTo($cont);
                                        },
                                        onHidden: function() {
                                            if (timerInterval) clearInterval(timerInterval);
                                            $loadingPopup.remove();
                                        }
                                    });

                                    if (!productID || productID == 0) {
                                        $loadingPopup.dxPopup("instance").hide();
                                        if (window.uiManager) uiManager.showAlert({ type: "warning", message: "Vui lòng chọn phần mềm trước khi sử dụng tác vụ AI!" });
                                        return;
                                    }

                                    AjaxHPAParadise({
                                        data: {
                                            name: "sp_AI_zalo_autoSendMessage",
                                            param: [
                                                "LoginID", UserID,
                                                "prompt", selectedIDs,
                                                "productID", productID,
                                      "sample", (useSample ? 1 : 0),
                                                "test", isTest,
                                                "LanguageID", LanguageID
                                            ]
                                        },
                                        success: function(res) {
                                            if (isCancelled) return;
                                            $loadingPopup.dxPopup("instance").hide();

                                            let parsedRes = typeof res === "string" ? JSON.parse(res) : res;
                                            if (!parsedRes || parsedRes.result !== "success") {
                                                if (window.uiManager) uiManager.showAlert({ type: "error", message: (parsedRes ? parsedRes.reason : "Lỗi không xác định") });
                                                return;
                                            }

                                            let aiDebug = "";
                                            if (parsedRes.data && parsedRes.data.length > 1) {
                                                let debugPart = parsedRes.data[1];
                                                if (Array.isArray(debugPart) && debugPart[0]) aiDebug = debugPart[0].Debug || "";
                                            }

                                            if (isTest) {
                                                let aiData = "";
                                                let dataPart = parsedRes.data[0];
                                                if (Array.isArray(dataPart) && dataPart[0]) {
                                                    aiData = dataPart[0].Result || "";
                                                } else if (dataPart) {
                                                    aiData = dataPart.Result || "";
                                                }

                                                let jsonContent = {};
                                                if (aiData) {
                                                    if (typeof aiData === "string" && aiData.trim() !== "") {
                                                        try {
                                                            jsonContent = JSON.parse(aiData);
                                                        } catch(e) {
                                                            try {
                                                                let fixedStr = aiData.replace(/\n/g, "\\n").replace(/\r/g, "\\r").replace(/\t/g, "\\t");
                                                                jsonContent = JSON.parse(fixedStr);
                                                            } catch (e2) {
                                                                console.error("Parse AI Result failed:", e2);
                                                                jsonContent = { "Lỗi": "Không thể giải mã kết quả từ AI" };
                                                            }
                                                        }
                                                    } else if (typeof aiData === "object") {
                                                        jsonContent = aiData;
                                                    }
                                                }

                                                let now = new Date();
                                                let timeStr = now.getHours().toString().padStart(2, ''0'') + ":" + now.getMinutes().toString().padStart(2, ''0'') + ":" + now.getSeconds().toString().padStart(2, ''0'');
                                                aiHistory_Log.unshift({
      timestamp: timeStr,
                                                    prompt: aiDebug,
                                                    results: jsonContent
                                                });
                                                updateAIDebugIcon();
                                                showAIHistoryDetail(aiHistory_Log[0]);
                                                if (window.uiManager) uiManager.showAlert({ type: "success", message: "Đã hoàn thành mẫu thử nghiệm." });
                                            } else {
                                                if (window.uiManager) uiManager.showAlert({ type: "success", message: "Hoàn tất gửi tin nhắn AI" });
                                                if (window.gridInstance) {
                                                    customSelectedKeys_GridZalo = [];
                                                    safeRepaintGrid(gridInstance, true);
                                                }
                                            }
                                        },
                                        error: function(err) {
                                            if (isCancelled) return;
                                            $loadingPopup.dxPopup("instance").hide();
                                            if (window.uiManager) uiManager.showAlert({ type: "error", message: "Lỗi hệ thống khi gọi AI" });
                                        }
                                    });
                                };

                                // Kiểm tra Prompt cá nhân trước khi thực hiện
                                if (productID) {
                                    AjaxHPAParadise({
                                        data: {
                                            name: "sp_zalo_sale_rule_crud",
                                            param: ["LoginID", UserID, "ActionType", "SELECT", "productID", productID]
                                        },
                                        success: function(res) {
                                            let jsonRes = typeof res === "string" ? JSON.parse(res) : res;
                                            let personalData = (jsonRes && jsonRes.data && jsonRes.data[0]) ? jsonRes.data[0] : [];
                                            let hasPersonal = personalData.length > 0 && personalData[0].Rule;

                                            if (hasPersonal) {
                                                // Nếu CÓ cá nhân, chạy mẫu cá nhân
                                                startAIExecution(false);
                                            } else {
                                                // Không có prompt cá nhân -> Mặc định dùng Sample
                                                startAIExecution(true);
                                            }
                                        },
                                        error: function() { startAIExecution(true); }
                                    });
                                } else {
                                    startAIExecution(true);
                                }

                                // Reset SelectBox về null sau khi click
                                setTimeout(function() {
                                    inst.option("value", null);
                                }, 100);
                            });
                        }
                    }

                    // Thêm nút Clock kế bên AI Menu
                    let $gearPlaceholder = $("#Toolbar_AIGear_Placeholder");
                    if ($gearPlaceholder.length && $gearPlaceholder.is(":empty")) {
                        $gearPlaceholder.dxButton({
                            icon: "clock",
                            hint: "Lịch gửi tự động AI (Set Auto)",
                            onClick: function() {
                                openSetAutoPopup();
                            }
                        });
                    }

                    // Gán sự kiện click cho Checkbox header (Select All)
                    $(document).off("change", "#chk_select_all_zalo").on("change", "#chk_select_all_zalo", function() {
                        // Lưu ý: với dxCheckBox thì dùng onValueChanged bên trong template sẽ tốt hơn
                        // nhưng ở đây ta dùng DOM event cho gọn vì template đang dùng dxCheckBox
                    });
                },
                onRowPrepared: function(e) {
                    if (e.rowType === "data") {
                        const rowKey = e.key ? e.key.toString() : "";
                        const isSelected = customSelectedKeys_GridZalo.some(function(k) { return k.toString() === rowKey; });
                        if (isSelected) {
                            $(e.rowElement).addClass("dx-selection");
                        } else {
                            $(e.rowElement).removeClass("dx-selection");
                        }

                        if (e.data && (e.data.isHide === 1 || e.data.isHide === "1")) {
                            $(e.rowElement).hide();
                        } else {
                            $(e.rowElement).show();
                            $(e.rowElement).css("visibility", "visible");
                        }
                    }
                },
                "customizeColumns": function (columns) {
                    let hasCustomCol = columns.some(function(c) { return c.name === "ChonCustom"; });
                    if (!hasCustomCol) {
                        columns.unshift({
                            name: "ChonCustom",
                            caption: "",
                            width: 50,
                            alignment: "center",
                            fixed: true,
                            fixedPosition: "left",
                            cssClass: "dx-command-select",
                            headerCellTemplate: function(container) {
                                $("<div>").attr("id", "chk_select_all_zalo").appendTo(container).dxCheckBox({
                                    value: isSelectAllActive_GridZalo,
                                    onValueChanged: function(args) {
                                        if (args.event) {
                                            if (args.value) {
                                                applySelectionLogic(-1);
                                            } else {
                                                customSelectedKeys_GridZalo = [];
                                                isSelectAllActive_GridZalo = false;
                                                safeRepaintGrid(window.gridInstance);
                                            }
                                        }
                                    }
                                });
                            },
                            cellTemplate: function(container, options) {
                                let rowKey = options.key ? options.key.toString() : "";
                                let isChecked = customSelectedKeys_GridZalo.some(function(k) { return k.toString() === rowKey; });
                                $("<div>").dxCheckBox({
                                    value: isChecked,
                                    onValueChanged: function(e) {
                                        if (!e.event) return; // Chỉ xử lý khi người dùng click thủ công

                                        const index = customSelectedKeys_GridZalo.findIndex(function(k) { return k.toString() === rowKey; });
                        if (e.value && index === -1) {
                                            customSelectedKeys_GridZalo.push(rowKey);
                                        } else if (!e.value && index > -1) {
                                            customSelectedKeys_GridZalo.splice(index, 1);
                                        }

                                        // Thêm/Xóa class dx-selection ngay lập tức để đổi màu nền không cần reload Grid
                                        let $row = container.closest(".dx-row");
                                        if (e.value) {
                                            $row.addClass("dx-selection");
                                        } else {
                                            $row.removeClass("dx-selection");
                                        }

                                        // Reset Segmented control về "Tất cả" nếu đang ở chế độ lọc
                                        let $seg = $("#PAEF4A083A6D44ACD92F01B2834695EED");
                                        let segInst = null;
                                        try {
                                            segInst = $seg.dxButtonGroup("instance");
                                            if (!segInst) segInst = $seg.dxSegmentedControl("instance");
                                        } catch(ex) {}

                                        if (segInst && segInst.option("value") != -1) {
                                            isSelectAllActive_GridZalo = false;
                                            segInst.option("value", -1);
                                            let chkAll = $("#chk_select_all_zalo").dxCheckBox("instance");
                                            if (chkAll) chkAll.option("value", false);
                                        }
                                    }
                                }).appendTo(container);
                            }
                        });
                    }

                    let hasSalutationCol = columns.some(function(c) { return c.dataField === "salutation"; });
                    if (!hasSalutationCol) {
                        columns.splice(3, 0, {
                            dataField: "salutation",
                            caption: "%zalo_chat_salutation_col_salutation%",
                            visibleIndex: 3.5,
                            width: 100,
                            alignment: "center",
                            allowFiltering: false,
                            allowHeaderFiltering: false,
                            allowSorting: false,
                            cellTemplate: function(container, options) {
                                let sal = options.data.salutation || "";
                                let $div = $("<div style=''cursor:pointer; color:var(--paradise-color-decor-main); font-weight:500; font-size:12px; display:inline-block; padding:2px 6px; border:1px solid var(--paradise-color-input-border); border-radius:4px;'' />");
                                $div.text(sal ? sal : "Xưng hô");
                                $div.on("click", function(e) {
                                    e.stopPropagation();
                                    window.zalo_chat_openSalutationPopup(options.data);
                                });
                                $div.appendTo(container);
                            }
                        });
                    }

                    columns.forEach(function (column) {
                        if (column.command === "select") {
                            column.width = 50;
                        }
                        if (column.dataField === "zaloID") {
                            column.visible = false;
                        }
                        if (column.dataField === "memVerList") {
                            column.visible = false;
                        }
                        if (column.dataField === "zaloName") {
                            column.caption = "Tên Zalo";
                            column.visibleIndex = 1;
                            column.width = "auto";
                            column.minWidth = 200;
                            column.cellTemplate = function(container, options) {
                                let val = options.value || "";
                                container.attr("title", val);
                                $("<div></div>")
                                    .text(val)
                                    .css({
                                        "white-space": "nowrap",
                                        "overflow": "hidden",
                                        "text-overflow": "ellipsis",
                                        "width": "100%",
                                        "display": "block"
                                    })
                                    .appendTo(container);
                            };
                        }
                        function renderAvatar(url, container, sizeInfo) {
                            if (!url) return;
                            $("<img />").attr({
                                "src": url,
                                "loading": "lazy"
                            }).css({
                                "width": sizeInfo.width || "35px",
                                "height": sizeInfo.height || "35px",
                                "border-radius": sizeInfo.borderRadius || "50%",
                                "object-fit": "cover",
                                "border": sizeInfo.border || "1px solid var(--paradise-color-decor-main)"
                            }).appendTo(container);
                        }

                        if (column.dataField === "avatar") {
                            column.caption = "Ảnh";
                            column.visibleIndex = 0;
                            column.width = 60;
                            column.alignment = "center";
                            column.cellTemplate = function (container, options) {
                                if (options.value) {
                                    renderAvatar(options.value, container, { width: "35px", height: "35px", borderRadius: "50%" });
                                } else if (options.data.isGroup == 1) {
                                    let memData = options.data.memVerList;
                                    if (memData) {
                                        try {
                                            let members = [];
                                            if (typeof memData === "string") {
                                                if (memData.trim().startsWith("[")) members = JSON.parse(memData);
                                                else members = memData.split(",").map(s => s.trim());
                                            } else if (Array.isArray(memData)) {
                                                members = memData;
                                            }

                                            let avatars = [];
                                            for(let i = 0; i < members.length; i++) {
                                                let id = members[i];
                                                let cleanId = id ? id.toString().split("_")[0] : "";
                                                if (friendAvatarMap[cleanId]) {
                                                    avatars.push(friendAvatarMap[cleanId]);
                                                    if (avatars.length >= 4) break;
                                                }
                         }

                                            if (avatars.length > 0) {
                                                let $div = $("<div></div>").css({
                                                    "width": "35px",
                                                    "height": "35px",
                                                    "display": "flex",
                                                    "flex-wrap": "wrap",
                                                    "border-radius": "50%",
                                                    "overflow": "hidden",
                                                    "border": "1px solid var(--paradise-color-decor-main)",
                                                    "background": "var(--paradise-color-decor-bg1)",
                                                    "margin": "auto"
                                                });

                                                let size = avatars.length >= 3 ? "50%" : (avatars.length == 2 ? "50%" : "100%");
                                                avatars.forEach(function(url, idx) {
                                                    renderAvatar(url, $div, {
                                                        width: size,
                                                        height: (avatars.length == 2) ? "100%" : size,
                                                        borderRadius: "0",
                                                        border: "none"
                                                    });
                                                });
                                                $div.appendTo(container);
                                            } else {
                                                renderPlaceholder(container);
                                            }
                                        } catch (e) {
                                            renderPlaceholder(container);
                                        }
                                    } else {
                                        renderPlaceholder(container);
                                    }
                                } else {
                                    renderPlaceholder(container);
                                }
                            };

                            function renderPlaceholder(container) {
                                $("<div></div>")
                                    .css({
                                        "width": "35px",
                                        "height": "35px",
                                        "border-radius": "50%",
                                        "background": "var(--paradise-color-decor-bg1)",
                                        "display": "inline-block"
                                    })
                                    .appendTo(container);
                            }
                        }
                        if (column.dataField === "lastActionTime") {
                            column.caption = "Hoạt động cuối";
                            column.visibleIndex = 2;
                            column.width = 130;
                            column.alignment = "center";
                        }
                        if (column.dataField === "isGroup") {
                            column.caption = "Loại";
                            column.visibleIndex = 3;
                            column.width = 80;
                            column.alignment = "center";
                            column.cellTemplate = function (container, options) {
                                let text = options.value == 1 ? "Nhóm" : "Cá nhân";
                                let color = "var(--paradise-color-text-bg)";
                                $("<span />")
                                   .text(text)
                                    .css({ "color": color, "font-weight": "bold" })
                                    .appendTo(container);
                            };
                        }
                        if (column.dataField === "tag") {
                            column.caption = "Tag";
                            column.visibleIndex = 4;
                            column.minWidth = 150;
                            column.allowFiltering = false;
                            column.headerFilter = { visible: false };
                            column.cellTemplate = function (container, options) {
                                let val = options.data.tag || "";
                                // Tách tag bằng dấu cách hoặc dấu phẩy, xử lý cả ký tự #
                                let ids = val ? val.split(/[ ,]+/).filter(function(x) { return x.trim(); }) : [];
                                let tagList = P36EB8FEA286C46F7A109BD6404CA9BAA_data || [];

                                let tagNames = ids.map(function(id) {
                                    let cleanId = id.replace("#", "").trim();
                                    let tag = tagList.find(function(x) { return x.ID.toString() === cleanId; });
                                    return tag ? tag.Name : id.trim();
                                });
                                container.attr("title", tagNames.join(", "));

                                let $div = $("<div style=''display:flex;align-items:center;flex-wrap:nowrap;gap:4px;cursor:pointer;overflow:hidden;'' />");

                                if (ids.length === 0) {
                                    $div.css("display", "none");
                                } else {
                                    $div.css({ "display": "flex", "visibility": "visible" });
                                }

                                let maxShow = 3;
                                let visibleIds = ids.slice(0, maxShow);
                                let remaining = ids.length - maxShow;

                                visibleIds.forEach(function(id) {
                                    let cleanId = id.replace("#", "").trim();
                                    let tag = tagList.find(function(x) { return x.ID.toString() === cleanId; });
                                    let displayText = tag ? "#" + tag.Name : (id.trim().startsWith("#") ? id.trim() : "#" + id.trim());

                                    $("<span></span>")
                                        .text(displayText)
                                        .css({
                                            "color": "var(--paradise-color-decor-main)",
                                            "font-weight": "500",
                                            "font-size": "11px",
                                            "white-space": "nowrap"
                                        })
                                        .appendTo($div);
                                });

                                if (remaining > 0) {
                                    $("<span></span>")
                                        .text("+" + remaining + "...")
                                        .css({
                                            "color": "var(--paradise-color-brown)",
                                            "font-size": "10px",
                                            "font-style": "italic",
                                            "white-space": "nowrap"
                                        })
                                        .appendTo($div);
                                }

                                if (ids.length === 0) {
                                    $("<span style=''font-style:italic;font-size:11px;opacity:0.5;cursor:pointer;'' />")
                                        .text("Click để gán tag")
                                        .on("click", function(e) {
                                            e.stopPropagation();
                                            openTagMenu(e.currentTarget, options.data);
                                        })
                                        .appendTo(container);
                                }

                                $div.on("click", function(e) {
                                    e.stopPropagation();
                                    openTagMenu(e.currentTarget, options.data);
                                });

                                $div.appendTo(container);
                            };
                        }
                    });
                }
            });

            gridInstance.option("onOptionChanged", function (e) {
                if (e.name === "searchPanel" && e.fullName === "searchPanel.text") {
                    _currentKeyword = (e.value || "").trim();
                    _pageCache = {};
                }
          });
            applyResponsiveGridLayout();
            gridInstance.endUpdate();

            // ============================================================
            // 3. HÀM RELOAD DATA TỐI GIẢN VÀ XỬ LÝ POPUP
            // ============================================================

            window.zalo_chat_openSalutationPopup = function(rowData) {
                if (!rowData || !rowData.zaloID) return;
                var receiver = {
                    uid: rowData.zaloID,
                    isGroup: rowData.isGroup,
                    name: rowData.zaloName,
                    salutation: rowData.salutation
                };
                var currentSal = receiver.salutation || "";
                var isGroup = receiver.isGroup;

                var $container = $("#zalo-salutation-popup-host");
                if ($container.length > 0) {
                    try { $container.dxPopup("instance").dispose(); } catch(e) {}
                    $container.remove();
                }
                $("body").append(''<div id="zalo-salutation-popup-host"></div>'');
                $container = $("#zalo-salutation-popup-host");

                var popupHtml =
                    ''<div style="padding: 20px 24px 16px;">'' +
                        ''<div style="font-size:0.92rem; margin-bottom:12px; font-weight:500;">'';

                if (isGroup == 1) {
                    popupHtml += ''<div id="zalo-sal-member-list" style="max-height:340px; overflow-y:auto;"></div>'';
                } else {
                    popupHtml +=
                        ''<div style="margin-bottom:8px;">%zalo_chat_salutation_label%: <strong>'' + (receiver.name ? receiver.name.replace(/[&<>"'']/g, function(m){return m==="&"?"&amp;":m==="<"?"&lt;":m===">"?"&gt;":m==="\""?"&quot;":"&apos;"}) : "") + ''</strong></div>'' +
                        ''<div id="zalo-sal-single"></div>'';
                }

                popupHtml +=
                        ''</div>'' +
                        ''<div style="display:flex; justify-content:flex-end; gap:8px; margin-top:16px;">'' +
                            ''<div id="zalo-sal-save-btn"></div>'' +
                            ''<div id="zalo-sal-cancel-btn"></div>'' +
                        ''</div>'' +
                    ''</div>'';

                $container.dxPopup({
                    title: "%zalo_chat_salutation_popup_title%",
                    width: isGroup == 1 ? 520 : 360,
                    height: "auto",
                    contentTemplate: function() { return popupHtml; },
                    showTitle: true,
                    dragEnabled: true,
                    closeOnOutsideClick: false,
                    visible: true,
onShown: function() {
                        if (isGroup == 1) {
                            var $list = $("#zalo-sal-member-list");
                            $list.html(''<div style="text-align:center; padding:20px; opacity:0.6;"><i class="fas fa-spinner fa-spin"></i> Đang tải...</div>'');

                            AjaxHPAParadiseAsync({
                                data: { name: "sp_zalo_getGroupMembers", param: ["LoginID", UserID, "GroupID", receiver.uid] }
                            }).then(function(res) {
                                var json = typeof res === "string" ? JSON.parse(res) : res;
                                var data = (json && json.data && json.data[0]) ? json.data[0] : [];
                                $list.empty();

                                if (!data || data.length === 0) {
                                    $list.html(''<div style="text-align:center; padding:20px; opacity:0.5; font-size:0.88rem;">%zalo_chat_salutation_no_member%</div>'');
                                    return;
                                }

                                $list.append(
                                    ''<div style="display:flex; font-weight:600; font-size:0.85rem; color:var(--paradise-color-text-main); border-bottom:1px solid var(--paradise-color-decor-main); padding-bottom:6px; margin-bottom:8px;">'' +
                                        ''<div style="flex:1;">%zalo_chat_salutation_col_name%</div>'' +
                                        ''<div style="width:130px;">%zalo_chat_salutation_col_salutation%</div>'' +
                                    ''</div>''
                                );

                                window._zaloSalMembers = data;

                                data.forEach(function(m, idx) {
                                    $list.append(
                                        ''<div style="display:flex; align-items:center; gap:10px; padding:6px 0; border-bottom:1px solid var(--paradise-color-decor-bg2);">'' +
                                            ''<div style="width:28px; height:28px; border-radius:50%; background:var(--paradise-color-decor-bg1); display:flex; align-items:center; justify-content:center; font-weight:600; font-size:0.8rem; flex-shrink:0;">'' +
                                                (m.avatar ? ''<img src="'' + m.avatar + ''" style="width:100%; height:100%; border-radius:50%; object-fit:cover;">'' : (m.displayName||"?").charAt(0)) +
                                            ''</div>'' +
                                            ''<div style="flex:1; min-width:0;">'' +
                                                ''<div style="font-size:0.88rem; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">'' + (m.displayName||m.userId).replace(/[&<>"'']/g, function(match){return match==="&"?"&amp;":match==="<"?"&lt;":match===">"?"&gt;":match==="\""?"&quot;":"&apos;"}) + ''</div>'' +
                                                ''<div style="font-size:0.75rem; opacity:0.5;">'' + (m.gender === ''1'' ? ''%zalo_chat_salutation_gender_male%'' : m.gender === ''0'' ? ''%zalo_chat_salutation_gender_female%'' : '''') + ''</div>'' +
                                            ''</div>'' +
                                            ''<div id="zalo-sal-sel-'' + idx + ''" style="width:130px; flex-shrink:0;"></div>'' +
                                        ''</div>''
                                    );
                                    (function(member, i) {
                                        setTimeout(function() {
                                            $("#zalo-sal-sel-" + i).dxSelectBox({
                                                items: ["Anh", "Chị", "Bạn", "Em"],
                                                value: member.salutation || (member.gender === ''1'' ? ''Anh'' : member.gender === ''0'' ? ''Chị'' : null),
                placeholder: "%zalo_chat_salutation_select%",
                                                acceptCustomValue: true,
                                                showClearButton: true,
                                                width: 130,
                                                onValueChanged: function(e) { window._zaloSalMembers[i]._newSal = e.value; },
                                                onCustomItemCreating: function(e) { e.customItem = e.text; }
                                            });
                                        }, 0);
                                    })(m, idx);
                                });
                            });
                        } else {
                            $("#zalo-sal-single").dxSelectBox({
                                items: ["Anh", "Chị", "Bạn", "Em"],
                                value: currentSal || null,
                                placeholder: "%zalo_chat_salutation_select%",
                                acceptCustomValue: true,
                                showClearButton: true,
                                width: "100%",
                                onValueChanged: function(e) { window._zaloNewSalutation = e.value; },
                                onCustomItemCreating: function(e) { e.customItem = e.text; }
                            });
                            window._zaloNewSalutation = currentSal;
                        }

                        $("#zalo-sal-save-btn").dxButton({
                            text: "%zalo_chat_save%",
                            type: "success",
                            onClick: function() {
                                if (isGroup == 1) {
                                    var tasks = (window._zaloSalMembers || []).filter(function(m) { return m._newSal !== undefined; }).map(function(m) {
                                        return AjaxHPAParadiseAsync({
                                            data: { name: "sp_zalo_setSalutation", param: ["LoginID", LoginID, "UserID", m.userId, "GroupID", receiver.uid, "Salutation", m._newSal || ""] }
                                        });
                                    });
                                    Promise.all(tasks).then(function() {
                                        uiManager.showAlert({ type: "success", message: "%zalo_chat_salutation_saved%" });
                                        $container.dxPopup("instance").hide();
                                    }).catch(function() {
                                        uiManager.showAlert({ type: "error", message: "%zalo_chat_salutation_saved%" });
                                    });
                                } else {
                                    AjaxHPAParadiseAsync({
                                        data: { name: "sp_zalo_setSalutation", param: ["LoginID", LoginID, "UserID", receiver.uid, "GroupID", "", "Salutation", window._zaloNewSalutation || ""] }
                                    }).then(function() {
                                        uiManager.showAlert({ type: "success", message: "%zalo_chat_salutation_saved%" });
                                        $container.dxPopup("instance").hide();
                                        rowData.salutation = window._zaloNewSalutation;
                                        if(window.gridInstance) window.gridInstance.refresh();
                                    }).catch(function() {
                                        uiManager.showAlert({ type: "error", message: "%zalo_chat_salutation_saved%" });
                                    });
                                }
                            }
                        });
                        $("#zalo-sal-cancel-btn").dxButton({
                            text: "%zalo_chat_cancel%",
                            stylingMode: "outlined",
                            onClick: function() { $container.dxPopup("instance").hide(); }
                        });
                    }
                });
            };

            function openTagMenu(target, rowData) {
                let tagList = P36EB8FEA286C46F7A109BD6404CA9BAA_data || [];

                if (tagList.length === 0) {
                    uiManager.showAlert({ type: "warning", message: "Không tìm thấy dữ liệu tag" });
                    return;
                }

                // Lấy các tag ID hiện tại của row, lọc bỏ các ID không phải là số nếu cần hoặc giữ lại để hiển thị
                let currentTagIDs = rowData.tag ? rowData.tag.split(",").filter(x => x.trim()).map(x => isNaN(x) ? x : parseInt(x)) : [];

                let $wrapper = $("<div></div>").appendTo("body");
                let popoverInstance = $wrapper.dxPopover({
                    target: target,
                    width: 280,
                    height: "auto",
                    showTitle: true,
                    title: "Chọn tag để gán",
                    contentTemplate: function(contentEl) {
                        $("<div></div>").dxTagBox({
                            dataSource: tagList,
                            displayExpr: "Name",
                            valueExpr: "ID",
                            value: currentTagIDs,
                            searchEnabled: true,
                            showSelectionControls: true,
                            maxDisplayedTags: 5,
                            placeholder: "Chọn tag...",
                            onValueChanged: function(e) {
                                // Chỉ gọi update khi thực sự có sự thay đổi từ người dùng
                                if (!e.event) return;
                                let newIDs = (e.value || []).join(",");
                                updateRowTag(rowData, newIDs, popoverInstance);
                            }
                        }).appendTo(contentEl);
                    },
                    onHidden: function() {
                        $wrapper.remove();
                    }
                }).dxPopover("instance");
                popoverInstance.show();
            }

            function updateRowTag(rowData, newTagStr, popoverInstance) {
                AjaxHPAParadise({
                    data: {
                        name: "sp_zalo_UpdateTag",
                        param: [
                            "LoginID", UserID,
                            "zaloID", rowData.zaloID,
                            "isGroup", rowData.isGroup,
                            "tagIDs", newTagStr
                        ]
                    },
                    success: function() {
                        if (popoverInstance) popoverInstance.hide();
                        uiManager.showAlert({ type: "success", message: "Đã cập nhật tag thành công" });

                        // Cập nhật dữ liệu tại chỗ (local) trước khi refresh để UI mượt mà hơn
                        rowData.tag = newTagStr;
                        if (window.gridInstance) {
                            window.gridInstance.refresh();
                        }
                    }
                });
            }

            // Load DataSource: Segmented Menu
            loadDataSourceCommon("zalo_autoSendMessage_status", "sp_zalo_get_autoSendMessage_Menu");

            // Load DataSource: Phần mềm
            loadDataSourceCommon("SelectBoxCustom", "sp_zalo_getMarketingProduction", function(data) {
                 try {
                     let sb = $("#P36EB8FEA286C46F7A109BD6404CA9BAA").dxSelectBox("instance");
                     if (sb) sb.option("dataSource", data);
                 } catch(ex) {}
            });

            // Load DataSource: AI Menu
            loadDataSourceCommon("AIMenuCustom", "sp_zalo_get_autoSendMessage_AI_Menu", function(data) {
                 try {
                     let aiSb = $("#PBE6706C7F3944933A71F067C581E0677").dxSelectBox("instance");
                     if (aiSb) aiSb.option("dataSource", data);
                 } catch(ex) {}
            });



            let _isOpeningDetail = false;
            function openDetailzaloID(rowData) {
                if (_isOpeningDetail) return;
                if (rowData && rowData.zaloID) {
                    _isOpeningDetail = true;
                    window.currentRecordID_zaloID = rowData.zaloID;
                    openFormParam(`sp_zalo_chat`, {LoginID:UserID, LanguageID: LanguageID})
                    // Reset cờ sau 1 giây để cho phép các lần click tiếp theo
                    setTimeout(function() { _isOpeningDetail = false; }, 1000)
                }
            }

            // Sửa lỗi hiển thị danh sách phần mềm ở ô Số lượng (do cấu hình hệ thống bị đè nhầm)
            loadDataSourceCommon("QuantityBoxCustom", "sp_zalo_get_autoSendMessage_numberSelection", function(data) {
                let numBox = $("#PC3ECBD81231B40B294775F6A0D74C861").dxSelectBox("instance");
                if (numBox) {
                    numBox.option("dataSource", data);
                    numBox.option("displayExpr", "Name");
                    numBox.option("valueExpr", "ID");
                }
            });

            // Không được loại bỏ ReloadData
            function ReloadData(pageNumber, pageSize, keyword = null) {
                if (keyword !== null) _currentKeyword = keyword.trim();
                _pageCache = {};
                gridInstance.refresh();
            }
            ReloadData();

        })();
    </script>
';

    SELECT @html as html
END
/*=====

EXEC sptblCommonControlType_Signed_DUC 'sp_zalo_autoSendMessage_html'
EXEC sp_GenerateHTMLScript_new 'sp_zalo_autoSendMessage_html'
SELECT * FROM tblCommonControlType_Signed where TableName = 'sp_zalo_autoSendMessage_html'

=====*/
GO

EXEC sptblCommonControlType_Signed_DUC 'sp_zalo_autoSendMessage_html'
GO
EXEC sp_GenerateHTMLScript_new 'sp_zalo_autoSendMessage_html'
GO
EXEC sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_zalo_autoSendMessage'
GO

SELECT
    name,
    modify_date,
    CASE
        WHEN OBJECT_DEFINITION(object_id) LIKE N'%VTS_RESPONSIVE_ZALO_FINAL_20260609%' THEN 1
        ELSE 0
    END AS HasResponsivePatch
FROM sys.objects
WHERE object_id = OBJECT_ID(N'dbo.sp_zalo_autoSendMessage_html');
GO

