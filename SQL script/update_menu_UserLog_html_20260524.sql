-- ============================================================================
-- File      : SQL script/update_menu_UserLog_html_20260524.sql
-- Mục đích  : Tạo lại và lập trình lại giao diện MnuSCR605 'Nhật ký người dùng' sang phong cách Web.
--             Sửa giao diện: Bỏ tiêu đề, xếp nhãn và control của bộ lọc trên cùng một hàng ngang.
--             Idempotent: IF NOT EXISTS cho tất cả INSERT, CREATE OR ALTER cho procedure.
-- Tác giả   : Antigravity
-- Ngày cập nhật: 2026-05-24 (bổ sung loại bỏ tiêu đề và xếp hàng ngang các bộ lọc)
-- Cảnh báo  : USER tự review và CHẠY trên database Paradise_Dev.
-- ============================================================================

SET NOCOUNT ON;
GO

PRINT N'BẮT ĐẦU CẬP NHẬT GIAO DIỆN NHẬT KÝ NGƯỜI DÙNG...';
GO

-- ============================================================================
-- PHASE 1: Nâng cấp thủ tục SC_EZLog_List để hỗ trợ @TempTableAPIName
-- ============================================================================
PRINT N'1. Đang cập nhật thủ tục SC_EZLog_List...';
GO

CREATE OR ALTER PROCEDURE [dbo].[SC_EZLog_List]
(
    @FromDate          DATETIME,
    @ToDate            DATETIME,
    @EmployeeID        VARCHAR(20),
    @LoginID           INT,
    @TempTableAPIName  VARCHAR(128) = N''
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        lg.LogID, 
        lg.LoginID, 
        lg.LogTime, 
        lg.EmployeeID, 
        te.FullName, 
        lg.FunctionClassName, 
        lg.FunctionName, 
        lg.KindOfData, 
        lg.DateOfData, 
        lg.OldData, 
        lg.NewData,
        lg.IPWan,
        lg.ComputerName
    INTO #tmpData
    FROM tblSC_Ezlog lg
    LEFT JOIN tblEmployee te ON lg.EmployeeID = te.EmployeeID
    WHERE lg.LogTime BETWEEN @FromDate AND @ToDate
      AND ((lg.EmployeeID = @EmployeeID OR @EmployeeID = '-1'))
    ORDER BY lg.LogTime DESC;

    DECLARE @sql NVARCHAR(MAX) = N'';
    IF (ISNULL(@TempTableAPIName, '') <> '')
        SET @sql = N'SELECT * INTO ' + QUOTENAME(@TempTableAPIName) + N' FROM #tmpData';
    ELSE
        SET @sql = N'SELECT * FROM #tmpData';
    EXEC (@sql);
END
GO

PRINT N'  [OK] Đã cập nhật SC_EZLog_List.';
GO

-- ============================================================================
-- PHASE 2: Tạo thủ tục Wrapper EzLog
-- ============================================================================
PRINT N'2. Đang tạo thủ tục Wrapper EzLog...';
GO

CREATE OR ALTER PROCEDURE [dbo].[EzLog]
(
    @LoginID    INT = NULL,
    @LanguageID VARCHAR(5) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Lấy mã HTML từ cache theo đúng chuẩn IsWeb = 1
    SELECT html FROM tblHtmlScriptCache
    WHERE TableName  = 'EzLog'
      AND LanguageID = @LanguageID;

    IF @@ROWCOUNT = 0
    BEGIN
        EXEC EzLog_html @LanguageID = @LanguageID;
    END
END
GO

PRINT N'  [OK] Đã tạo wrapper EzLog.';
GO

-- ============================================================================
-- PHASE 3: Tạo thủ tục renderer EzLog_html
-- ============================================================================
PRINT N'3. Đang tạo thủ tục renderer EzLog_html...';
GO

CREATE OR ALTER PROCEDURE [dbo].[EzLog_html]
(
    @LanguageID VARCHAR(5) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @html NVARCHAR(MAX) = N'';

    SET @html = N'
<div id="ezLogRoot" class="ezl-page">
    <style>
        .ezl-page {
            display: flex;
            flex-direction: column;
            height: 100%;
            padding: var(--paradise-space-4);
            color: var(--paradise-text-body);
            font-family: var(--paradise-font-family-base);
            box-sizing: border-box;
            gap: var(--paradise-space-4);
        }
        .ezl-filter-bar {
            display: flex;
            flex-wrap: wrap;
            gap: var(--paradise-space-4);
            align-items: center;
            background-color: var(--paradise-card-bg);
            border: var(--paradise-card-border);
            border-radius: var(--paradise-card-radius);
            padding: var(--paradise-card-padding);
            box-shadow: var(--paradise-card-shadow);
        }
        .ezl-filter-item {
            display: flex;
            flex-direction: row;
            align-items: center;
            gap: var(--paradise-space-2);
        }
        .ezl-filter-item label {
            font-size: var(--paradise-font-body2);
            font-weight: var(--font-weight-semi-bold);
            color: var(--paradise-text-body);
            white-space: nowrap;
        }
        .ezl-input {
            background-color: var(--paradise-bg-surface);
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-input-border-radius);
            padding: var(--paradise-space-2) var(--paradise-space-3);
            color: var(--paradise-text-body);
            font-family: var(--paradise-font-family-base);
            font-size: var(--paradise-font-body1);
            height: 36px;
            box-sizing: border-box;
            min-width: 220px;
            transition: var(--paradise-transition-fast);
        }
        .ezl-input:focus {
            outline: none;
            border-color: var(--paradise-color-input-border-hover);
            box-shadow: 0 0 0 2px var(--paradise-bg-primary-subtle);
        }
        .ezl-grid-container {
            background-color: var(--paradise-card-bg);
            border: var(--paradise-card-border);
            border-radius: var(--paradise-card-radius);
            padding: var(--paradise-card-padding);
            box-shadow: var(--paradise-card-shadow);
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }
        .ezl-grid-container .dx-datagrid {
            background: transparent !important;
        }
        .ezl-grid-container .dx-datagrid-headers {
            border-bottom: 2px solid var(--paradise-border-color) !important;
            background-color: var(--paradise-bg-1) !important;
        }
        .ezl-grid-container .dx-datagrid-headers .dx-header-row > td {
            color: var(--paradise-color-primary) !important;
            font-weight: var(--font-weight-bold) !important;
            padding: var(--paradise-space-3) var(--paradise-space-4) !important;
        }
        .ezl-grid-container .dx-datagrid-rowsview .dx-data-row > td {
            padding: var(--paradise-space-3) var(--paradise-space-4) !important;
            border-bottom: 1px solid var(--paradise-border-color) !important;
            vertical-align: middle !important;
        }
        .ezl-pre-old, .ezl-pre-new {
            white-space: pre-wrap;
            word-break: break-all;
            background-color: var(--paradise-bg-body) !important;
            color: var(--paradise-text-body) !important;
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-md);
            padding: var(--paradise-space-3);
            margin: 0;
            max-height: 320px;
            overflow-y: auto;
            font-family: var(--paradise-font-family-mono);
            font-size: 13px;
        }
        .ezl-pre-old {
            border-left: 4px solid var(--paradise-color-danger);
        }
        .ezl-pre-new {
            border-left: 4px solid var(--paradise-color-success);
        }
        .ezl-pre-info {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: var(--paradise-space-4);
            margin-bottom: var(--paradise-space-4);
            font-size: 14px;
            border-bottom: 1px dashed var(--paradise-border-color);
            padding-bottom: var(--paradise-space-3);
            color: var(--paradise-text-body);
        }
    </style>

    <div class="ezl-filter-bar">
        <div class="ezl-filter-item">
            <label></label>
            <div id="ezlFromDate"></div>
        </div>
        <div class="ezl-filter-item">
            <label></label>
            <div id="ezlToDate"></div>
        </div>
        <div class="ezl-filter-item">
            <label></label>
            <div id="ezlEmployee"></div>
        </div>
        <div class="ezl-filter-item">
            <label></label>
            <input type="text" id="ezlSearchInput" class="ezl-input" />
        </div>
        <div class="ezl-filter-item">
            <button type="button" id="ezlReloadBtn" class="paradise-btn paradise-btn--reload"></button>
        </div>
    </div>

    <div class="ezl-grid-container">
        <div id="ezlGrid"></div>
    </div>

    <div id="ezlDiffPopup"></div>
</div>

<script>
(() => {
    const lang = window.LanguageID || "VN";
    const labels = {
        VN: {
            title: "Nhật ký người dùng",
            fromDate: "Từ ngày",
            toDate: "Đến ngày",
            employee: "Nhân viên",
            search: "Tìm kiếm",
            searchPlaceholder: "Tìm kiếm trong nội dung nhật ký...",
            reload: "Tải lại",
            loading: "Đang tải dữ liệu nhật ký...",
            noData: "Không tìm thấy bản ghi nhật ký nào.",
            logTime: "Thời gian",
            colEmployee: "Nhân viên",
            action: "Thao tác / Form",
            fieldName: "Trường / Khoá",
            dateOfData: "Ngày dữ liệu",
            computerName: "Tên máy",
            ipWan: "Địa chỉ IP",
            oldValue: "Dữ liệu cũ",
            newValue: "Dữ liệu mới",
            popupTitle: "Chi tiết thay đổi dữ liệu",
            popupOld: "DỮ LIỆU CŨ (TRƯỚC)",
            popupNew: "DỮ LIỆU MỚI (SAU)",
            selectEmployee: "Chọn nhân viên...",
            allEmployees: "Tất cả nhân viên"
        },
        EN: {
            title: "User Log History",
            fromDate: "From Date",
            toDate: "To Date",
            employee: "Employee",
            search: "Search Text",
            searchPlaceholder: "Search in log content...",
            reload: "Reload",
            loading: "Loading log data...",
            noData: "No logs found.",
            logTime: "Time",
            colEmployee: "Employee",
            action: "Action/Screen",
            fieldName: "Field/Key",
            dateOfData: "Log Date",
            computerName: "Computer Name",
            ipWan: "IP Address",
            oldValue: "Old Value",
            newValue: "New Value",
            popupTitle: "Data Change Details",
            popupOld: "OLD VALUE (BEFORE)",
            popupNew: "NEW VALUE (AFTER)",
            selectEmployee: "Select employee...",
            allEmployees: "All Employees"
        }
    };
    const curLabels = labels[lang] || labels.VN;

    // Cập nhật các label tĩnh
    $("#ezLogRoot .ezl-filter-item label").eq(0).text(curLabels.fromDate + ":");
    $("#ezLogRoot .ezl-filter-item label").eq(1).text(curLabels.toDate + ":");
    $("#ezLogRoot .ezl-filter-item label").eq(2).text(curLabels.employee + ":");
    $("#ezLogRoot .ezl-filter-item label").eq(3).text(curLabels.search + ":");
    $("#ezlSearchInput").attr("placeholder", curLabels.searchPlaceholder);
    $("#ezlReloadBtn").text(curLabels.reload);

    let selectedEmployeeID = "-1";
    let now = new Date();
    let fromDateValue = new Date(now.getFullYear(), now.getMonth(), 1);
    let toDateValue = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59);
    let _currentKeyword = "";
    let gridInstance = null;

    const formatDateDb = (date) => {
        if (!date) return "";
        const d = new Date(date);
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, "0");
        const day = String(d.getDate()).padStart(2, "0");
        return y + "-" + m + "-" + day;
    };

    const formatDateTime = (dateStr) => {
        if (!dateStr) return "";
        const d = new Date(dateStr);
        const day = String(d.getDate()).padStart(2, "0");
        const month = String(d.getMonth() + 1).padStart(2, "0");
        const year = d.getFullYear();
        const hour = String(d.getHours()).padStart(2, "0");
        const min = String(d.getMinutes()).padStart(2, "0");
        const sec = String(d.getSeconds()).padStart(2, "0");
        return day + "/" + month + "/" + year + " " + hour + ":" + min + ":" + sec;
    };

    const escapeHtml = (text) => {
        if (text === null || text === undefined) return "";
        return String(text)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/\u0027/g, "&#039;");
    };

    $("#ezlFromDate").dxDateBox({
        type: "date",
        displayFormat: "dd/MM/yyyy",
        value: fromDateValue,
        useMaskBehavior: true,
        height: 36,
        onValueChanged: (e) => {
            fromDateValue = e.value;
            refreshGrid();
        }
    });

    $("#ezlToDate").dxDateBox({
        type: "date",
        displayFormat: "dd/MM/yyyy",
        value: toDateValue,
        useMaskBehavior: true,
        height: 36,
        onValueChanged: (e) => {
            toDateValue = e.value;
            refreshGrid();
        }
    });

    $("#ezlEmployee").dxSelectBox({
        dataSource: [],
        displayExpr: "FullName",
        valueExpr: "EmployeeID",
        value: selectedEmployeeID,
        searchEnabled: true,
        height: 36,
        width: 240,
        placeholder: curLabels.selectEmployee,
        onValueChanged: (e) => {
            selectedEmployeeID = e.value || "-1";
            refreshGrid();
        }
    });

    if (typeof AjaxHPAParadise === "function") {
        AjaxHPAParadise({
            data: {
                name: "sp_getEmployeeListWithPermission",
                param: ["LoginID", window.UserID || 3, "IsFullName", 1]
            },
            success: (res) => {
                const json = typeof res === "string" ? JSON.parse(res) : res;
                const emps = (json && json.data && json.data[0]) ? json.data[0] : [];
                const defaultItem = { 
                    EmployeeID: "-1", 
                    FullName: curLabels.allEmployees
                };
                const datasource = [defaultItem, ...emps];
                $("#ezlEmployee").dxSelectBox("instance").option("dataSource", datasource);
            }
        });
    }

    $("#ezlSearchInput").on("input", function() {
        _currentKeyword = $(this).val().trim();
        refreshGrid();
    });

    $("#ezlReloadBtn").on("click", () => {
        refreshGrid();
    });

    const logDataStore = new DevExpress.data.CustomStore({
        key: "LogID",
        load: (loadOptions) => {
            const deferred = $.Deferred();
            let params = [];
            params.push("@ProcName", "SC_EZLog_List");

            let fromStr = formatDateDb(fromDateValue);
            let toStr = formatDateDb(toDateValue);

            let procParam = "@FromDate=''" + fromStr + "'', @ToDate=''" + toStr + "'', @EmployeeID=''" + selectedEmployeeID + "'', @LoginID=" + (window.UserID || 3);
            params.push("@ProcParam", procParam);

            params.push("@Take", loadOptions.take || 50);
            params.push("@Skip", loadOptions.skip || 0);

            if (loadOptions.requireTotalCount) params.push("@RequireTotalCount", 1);

            const sortExpr = loadOptions.sort
                ? loadOptions.sort.map(s => s.selector + (s.desc ? " DESC" : " ASC")).join(",")
                : "LogTime DESC";
            params.push("@Sort", "ORDER BY " + sortExpr);

            if (_currentKeyword) {
                params.push("@SearchValue", _currentKeyword);
                params.push("@ColumnSearch", "FullName,FunctionName,FunctionClassName,KindOfData,OldData,NewData,ComputerName,IPWan");
            }

            if (loadOptions.filter) {
                const hasFunc = JSON.stringify(loadOptions.filter).includes("FUNCTION");
                if (!hasFunc) {
                    params.push("@Filters", createConditionQuery(loadOptions.filter));
                }
            }

            if (typeof AjaxHPAParadise === "function") {
                AjaxHPAParadise({
                    data: {
                        name: "sp_LoadGridUsingAPI",
                        param: params
                    },
                    success: (res) => {
                        const json = typeof res === "string" ? JSON.parse(res) : res;
                        const rows = (json && json.data && Array.isArray(json.data[0])) ? json.data[0] : [];
                        let result = { data: rows };
                        
                        if (loadOptions.requireTotalCount) {
                            result.totalCount = (json && json.data && json.data[1] && json.data[1][0]) 
                                ? (json.data[1][0].TotalCount ?? 0) 
                                : 0;
                        }
                        deferred.resolve(result);
                    },
                    error: () => deferred.reject("Error loading data from server")
                });
            } else {
                deferred.resolve({ data: [] });
            }

            return deferred.promise();
        }
    });

    function getGridHeight() {
        const filterEl = document.querySelector(".ezl-filter-bar");
        const fHeight = filterEl ? filterEl.offsetHeight : 54;
        return window.innerHeight - fHeight - 80;
    }

    gridInstance = $("#ezlGrid").dxDataGrid({
        dataSource: logDataStore,
        remoteOperations: {
            paging: true, filtering: true, sorting: true, searching: true
        },
        scrolling: {
            mode: "infinite",
            rowRenderingMode: "virtual",
            preloadEnabled: false
        },
        paging: {
            enabled: true,
            pageSize: 50
        },
        pager: {
            visible: false
        },
        height: getGridHeight(),
        columnAutoWidth: true,
        allowColumnResizing: true,
        showBorders: true,
        showColumnLines: true,
        showRowLines: true,
        hoverStateEnabled: true,
        noDataText: curLabels.noData,
        columns: [
            { 
                dataField: "LogTime", 
                caption: curLabels.logTime, 
                alignment: "center", 
                width: 160, 
                dataType: "datetime", 
                format: "dd/MM/yyyy HH:mm:ss" 
            },
            { 
                dataField: "FullName", 
                caption: curLabels.colEmployee, 
                alignment: "left", 
                width: 200,
                cellTemplate: (container, options) => {
                    const name = options.value || "";
                    const empId = options.data.EmployeeID || "";
                    if (name) {
                        $("<span>").text(name + " (" + empId + ")").appendTo(container);
                    } else {
                        $("<span>").text(empId || "--").appendTo(container);
                    }
                }
            },
            { dataField: "FunctionName", caption: curLabels.action, alignment: "left", width: 250 },
            { dataField: "KindOfData", caption: curLabels.fieldName, alignment: "left", width: 180 },
            { 
                dataField: "DateOfData", 
                caption: curLabels.dateOfData, 
                alignment: "center", 
                width: 130, 
                dataType: "date", 
                format: "dd/MM/yyyy" 
            },
            { dataField: "ComputerName", caption: curLabels.computerName, alignment: "left", width: 150 },
            { dataField: "IPWan", caption: curLabels.ipWan, alignment: "left", width: 130 },
            { dataField: "OldData", visible: false },
            { dataField: "NewData", visible: false }
        ],
        onRowClick: (e) => {
            if (e.rowType === "data" && e.data) {
                showDiffPopup(e.data);
            }
        }
    }).dxDataGrid("instance");

    window.addEventListener("resize", () => {
        if (gridInstance) {
            gridInstance.option("height", getGridHeight());
        }
    });

    function refreshGrid() {
        if (gridInstance) {
            gridInstance.refresh();
        }
    }

    $("#ezlDiffPopup").dxPopup({
        width: 850,
        height: 600,
        showTitle: true,
        dragEnabled: true,
        closeOnOutsideClick: true,
        showCloseButton: true,
        title: curLabels.popupTitle,
        contentTemplate: (contentElement) => {
            // Sẽ được vẽ động khi mở
        }
    });

    function showDiffPopup(data) {
        const popup = $("#ezlDiffPopup").dxPopup("instance");
        if (!popup) return;

        popup.option("title", curLabels.popupTitle + " - " + (data.FullName || data.EmployeeID || ""));
        const contentEl = popup.content();
        contentEl.empty();

        const $info = $("<div>").addClass("ezl-pre-info");
        $info.append("<div><strong>" + curLabels.logTime + ":</strong> <span>" + formatDateTime(data.LogTime) + "</span></div>");
        $info.append("<div><strong>" + curLabels.fieldName + ":</strong> <span>" + escapeHtml(data.KindOfData) + "</span></div>");
        $info.append("<div><strong>" + curLabels.action + ":</strong> <span>" + escapeHtml(data.FunctionName) + "</span></div>");
        $info.append("<div><strong>" + curLabels.computerName + " / IP:</strong> <span>" + escapeHtml(data.ComputerName) + " / " + escapeHtml(data.IPWan) + "</span></div>");
        contentEl.append($info);

        const $diffContainer = $("<div>").css({
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            gap: "var(--paradise-space-4)",
            height: "calc(100% - 70px)",
            minHeight: "380px"
        });

        const $oldColumn = $("<div>").css({ display: "flex", flexDirection: "column", gap: "var(--paradise-space-2)" });
        $oldColumn.append("<span style=\"font-weight: bold; color: var(--paradise-color-danger); display: flex; align-items: center; gap: var(--paradise-space-1);\"><i class=\"bi bi-dash-circle-fill\"></i> " + curLabels.popupOld + "</span>");
        $oldColumn.append($("<pre>").addClass("ezl-pre-old").text(data.OldData || curLabels.noData));
        $diffContainer.append($oldColumn);

        const $newColumn = $("<div>").css({ display: "flex", flexDirection: "column", gap: "var(--paradise-space-2)" });
        $newColumn.append("<span style=\"font-weight: bold; color: var(--paradise-color-success); display: flex; align-items: center; gap: var(--paradise-space-1);\"><i class=\"bi bi-plus-circle-fill\"></i> " + curLabels.popupNew + "</span>");
        $newColumn.append($("<pre>").addClass("ezl-pre-new").text(data.NewData || curLabels.noData));
        $diffContainer.append($newColumn);

        contentEl.append($diffContainer);
        popup.show();
    }
})();
</script>
';

    SELECT @html AS html;
END
GO

PRINT N'  [OK] Đã tạo renderer EzLog_html.';
GO

-- ============================================================================
-- PHASE 4: Tạo lại MEN_Menu cho MnuSCR605 (Idempotent - IF NOT EXISTS)
-- CẤU HÌNH THEO CHUẨN PURE-HTML (IsWeb = 1, isShowLayOutWeb = 1)
-- ============================================================================
PRINT N'4. Đang tạo/cập nhật MEN_Menu cho MnuSCR605...';
GO

IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = 'MnuSCR605')
BEGIN
    INSERT INTO MEN_Menu (
        MenuID, ClassName, AssemblyName, ParentMenuID, Priority, IsVisible, 
        IsWeb, ViewOnWeb, isShowLayOutWeb, IsUseMobileDevice, isShowInMobileLayOut, 
        glyphicon, GroupID, IsNotAjax, showDialog, Colors, LargeTile, SupperAdmin, 
        IsModal, IsCollapsed, IsLeftMenu, IsHiddenInTree, Notification
    )
    VALUES (
        'MnuSCR605', N'EzLog', N'DataSetting', 'MnuSCR000', 11, 1, 
        1, 0, 1, 0, 0, 
        N'history', N'', 0, 0, N'', 0, 0, 
        0, 0, 0, 0, 0
    );
    PRINT N'  [OK] Đã INSERT MEN_Menu MnuSCR605.';
END
ELSE
BEGIN
    -- Đã tồn tại: cập nhật lại các cờ quan trọng theo chuẩn IsWeb=1
    UPDATE MEN_Menu
    SET
        ClassName            = N'EzLog',
        AssemblyName         = N'DataSetting',
        IsWeb                = 1,
        ViewOnWeb            = 0,
        isShowLayOutWeb      = 1,
        IsUseMobileDevice    = 0,
        isShowInMobileLayOut = 0,
        glyphicon            = N'history',
        GroupID              = N'',
        IsNotAjax            = 0,
        showDialog           = 0,
        Colors               = N'',
        LargeTile            = 0,
        SupperAdmin          = 0,
        IsModal              = 0,
        IsCollapsed          = 0,
        IsLeftMenu           = 0,
        IsHiddenInTree       = 0,
        Notification         = 0
    WHERE MenuID = 'MnuSCR605';
    PRINT N'  [OK] MnuSCR605 đã tồn tại — đã cập nhật cờ theo chuẩn IsWeb=1.';
END
GO

-- ============================================================================
-- PHASE 4c: Tạo lại tblSC_Object cho MnuSCR605 (Idempotent - IF NOT EXISTS)
-- ObjectID an toàn: dùng MAX(ObjectID)+1 động để tránh xung đột
-- ParentObjectID = 6 (HPA.SystemAdmin — ObjectID của MnuSCR000)
-- ============================================================================
PRINT N'4c. Đang tạo tblSC_Object cho MnuSCR605...';
GO

IF NOT EXISTS (SELECT 1 FROM tblSC_Object WHERE Description = 'MnuSCR605')
BEGIN
    DECLARE @NewObjectID INT;
    SELECT @NewObjectID = MAX(ObjectID) + 1 FROM tblSC_Object;

    INSERT INTO tblSC_Object (ObjectID, ObjectName, Description, Visible, ParentObjectID)
    VALUES (@NewObjectID, N'DataSetting.EzLog', 'MnuSCR605', 1, 6);

    -- Cấp quyền FullAccess=32 cho LoginID = 3 (Admin mặc định theo chuẩn dự án)
    INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess)
    VALUES (@NewObjectID, 3, '32');

    PRINT N'  [OK] Đã INSERT tblSC_Object và cấp quyền LoginID=3.';
END
ELSE
    PRINT N'  [SKIP] tblSC_Object MnuSCR605 đã tồn tại.';
GO

-- ============================================================================
-- PHASE 4d: Tạo lại tên menu đa ngôn ngữ trong tblMD_Message (Idempotent)
-- ============================================================================
PRINT N'4d. Đang tạo tên menu đa ngôn ngữ (tblMD_Message)...';
GO

IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'MnuSCR605' AND Language = 'VN')
    INSERT INTO tblMD_Message (MessageID, Language, Content)
    VALUES ('MnuSCR605', 'VN', N'Nhật ký người dùng');
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'MnuSCR605' AND Language = 'EN')
    INSERT INTO tblMD_Message (MessageID, Language, Content)
    VALUES ('MnuSCR605', 'EN', N'User Log History');
GO

PRINT N'  [OK] Đã tạo tên VN/EN cho MnuSCR605.';
GO

-- ============================================================================
-- PHASE 5: Dọn dẹp cấu hình cũ trong tblDataSetting và tblDataSettingLayout (nếu có)
-- ============================================================================
PRINT N'5. Đang dọn dẹp cấu hình tblDataSetting & tblDataSettingLayout cũ...';
GO

DELETE FROM tblDataSetting WHERE TableName = 'ezlog';
DELETE FROM tblDataSettingLayout WHERE TableName = 'ezlog';
GO

PRINT N'  [OK] Đã dọn dẹp cấu hình cũ.';
GO

-- ============================================================================
-- PHASE 6: Rebuild HTML Cache
-- ============================================================================
PRINT N'6. Đang build cache HTML cho EzLog...';
GO

DELETE FROM tblHtmlScriptCache WHERE TableName = 'EzLog';
GO

EXEC dbo.sp_GenerateHTMLScript 'EzLog_html', 'VN', 'EzLog';
EXEC dbo.sp_GenerateHTMLScript 'EzLog_html', 'EN', 'EzLog';
GO

PRINT N'  [OK] Đã build cache HTML.';
GO

-- ============================================================================
-- PHASE 7: Làm mới menu cache phía client
-- ============================================================================
PRINT N'7. Đang làm mới cache hệ thống...';
GO

EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'EzLog';
GO

PRINT N'CẬP NHẬT GIAO DIỆN NHẬT KÝ NGƯỜI DÙNG THÀNH CÔNG!';
GO
