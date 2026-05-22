-- ============================================================================
-- File   : SQL script/update_menu_TaskTimeLine_html_ParadiseStyle.sql
-- Mục đích: Thiết kế lại giao diện menu Nhật ký công việc (sp_Task_TaskTimeLine_html)
--          tuân thủ chuẩn thiết kế ParadiseStyle.
-- Cảnh báo: USER tự review và CHẠY. Agent KHÔNG tự động thực thi.
-- Idempotent: Có thể chạy nhiều lần; tự động dọn dẹp và nạp lại HTML cache.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID('dbo.sp_Task_TaskTimeLine_html', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Task_TaskTimeLine_html;
GO

CREATE PROCEDURE [dbo].[sp_Task_TaskTimeLine_html]
    @LoginID    INT = 3,
    @LanguageID VARCHAR(2) = 'VN',
    @isWeb      INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- Trigger Recurring Tasks Generation (On Form Open)
    IF OBJECT_ID('dbo.sp_Task_GenerateRecurringTasks', 'P') IS NOT NULL
        EXEC dbo.sp_Task_GenerateRecurringTasks;

    DECLARE @html NVARCHAR(MAX);
    SET @html = N'
<style>
    .hpa-task-board-page {
        --danger-bg: var(--paradise-bg-danger-subtle);
        --warning-bg: var(--paradise-bg-warning-subtle);
        --text-primary: var(--paradise-text-body);
        --text-light: var(--paradise-text-body);

        position: fixed; top: 0; left: 0; right: 0; bottom: 0;
        z-index: 200000; display: none; flex-direction: column;
        cursor: default;
        user-select: none;
        background-color: var(--paradise-bg-body) !important;
    }

    .hpa-task-board-page .hpa-modal-header {
        position: absolute; top: 15px; right: 30px; z-index: 101;
    }

    .hpa-task-board-page .hpa-btn-close {
        font-size: 20px;
        cursor: pointer;
        opacity: 0.8;
        padding: 8px;
        color: var(--paradise-text-muted);
        transition: var(--paradise-transition-fast);
        display: flex;
        align-items: center;
        justify-content: center;
        width: 36px;
        height: 36px;
        border-radius: 50%;
        background-color: var(--paradise-bg-2);
    }
    .hpa-task-board-page .hpa-btn-close:hover {
        opacity: 1;
        color: var(--paradise-color-danger);
        background-color: var(--paradise-bg-danger-subtle);
    }

    /* TITLE */
    .hpa-task-board-page .hpa-task-title {
        font-size: 22px;
        font-weight: 700;
        text-align: center;
        background-color: var(--paradise-bg-1);
        color: var(--paradise-color-primary);
        padding: 16px 0;
        margin: 0;
        text-transform: uppercase;
        letter-spacing: 1px;
        border-bottom: 1px solid var(--paradise-border-color);
    }

    /* DASHBOARD LAYOUT */
    .hpa-task-board-page .hpa-task-dashboard {
        padding: 0; overflow: hidden; flex: 1; display: flex; flex-direction: column;
    }

    /* DX-DATAGRID MODERN CUSTOMIZATION */
    .hpa-task-board-page .dx-datagrid {
        background: transparent !important;
        color: var(--paradise-text-body) !important;
        border: none !important;
        border-radius: 0;
        overflow: hidden;
    }

    .hpa-task-board-page .dx-datagrid-headers {
        background: transparent !important;
        color: var(--paradise-color-primary) !important;
        font-weight: 700 !important;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        font-size: 15px;
        border-bottom: 2px solid var(--paradise-border-color) !important;
    }

    .hpa-task-board-page .dx-datagrid-headers .dx-datagrid-table .dx-header-row > td {
        padding: 15px 20px !important;
        background: transparent !important;
        text-align: left !important;
        border-right: 1px solid var(--paradise-border-color) !important;
    }

    /* ROWS */
    .hpa-task-board-page .dx-datagrid-rowsview .dx-row {
        margin-bottom: 0px;
    }

    .hpa-task-board-page .row-danger {
        background: var(--paradise-bg-danger-subtle) !important;
        color: var(--paradise-text-body) !important;
    }

    .hpa-task-board-page .row-warning {
        background: var(--paradise-bg-warning-subtle) !important;
        color: var(--paradise-text-body) !important;
    }

    .hpa-task-board-page .row-normal {
        background: transparent !important;
        color: var(--paradise-text-body) !important;
    }

    .hpa-task-board-page .dx-row[class*="row-"] {
        border-radius: 0px;
        overflow: hidden;
    }

    /* AVATAR & CELL STYLING */
    .hpa-task-board-page .td-avatar {
        width: 38px; height: 38px; border-radius: 50%;
        background: var(--paradise-bg-3); display: flex; align-items: center; justify-content: center;
        overflow: hidden; flex-shrink: 0;
        border: 2px solid var(--paradise-bg-body);
        box-sizing: border-box;
    }
    .hpa-task-board-page .td-avatar img,
    .hpa-task-board-page .td-avatar svg { width: 100%; height: 100%; object-fit: cover; }

    /* Stacked avatar group */
    .hpa-task-board-page .td-avatar-group {
        display: flex; align-items: center; margin-right: 12px;
    }
    .hpa-task-board-page .td-avatar-group .td-avatar { margin-left: -10px; }
    .hpa-task-board-page .td-avatar-group .td-avatar:first-child { margin-left: 0; }
    
    .hpa-task-board-page .td-avatar-extra {
        width: 38px; height: 38px; border-radius: 50%;
        background: var(--paradise-color-primary); color: var(--paradise-text-on-primary, #fff);
        display: flex; align-items: center; justify-content: center;
        font-size: 12px; font-weight: 800; margin-left: -10px;
        border: 2px solid var(--paradise-bg-body); flex-shrink: 0;
    }

    .hpa-task-board-page .td-assignee-cell { display: flex; align-items: center; font-weight: 600; font-size: 15px; }
    .hpa-task-board-page .td-assignee-names { display: flex; flex-direction: column; gap: 1px; overflow: hidden; }
    .hpa-task-board-page .td-assignee-names span {
        white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
    }
    .hpa-task-board-page .td-task-name { font-weight: 700; font-size: 16px;}
    
    /* STATUS BADGE (STATUS TOKEN PILL) */
    .hpa-task-board-page .td-time-badge {
        display: inline-block;
        padding: var(--paradise-space-1) var(--paradise-space-3);
        border-radius: var(--paradise-border-radius-pill);
        font-weight: 600;
        font-size: var(--paradise-font-size-xs, 0.75rem);
        text-align: center;
        border: 1px solid transparent;
        white-space: nowrap;
    }
    .hpa-task-board-page .td-time-badge.badge-danger {
        background-color: var(--paradise-bg-danger-subtle) !important;
        color: var(--paradise-color-danger) !important;
        border-color: var(--paradise-bg-danger-subtle) !important;
    }
    .hpa-task-board-page .td-time-badge.badge-warning {
        background-color: var(--paradise-bg-warning-subtle) !important;
        color: var(--paradise-color-warning) !important;
        border-color: var(--paradise-bg-warning-subtle) !important;
    }
    .hpa-task-board-page .td-time-badge.badge-normal {
        background-color: var(--paradise-bg-info-subtle) !important;
        color: var(--paradise-color-info) !important;
        border-color: var(--paradise-bg-info-subtle) !important;
    }

    .hpa-task-board-page .dx-datagrid-content .dx-datagrid-table .dx-row > td {
        vertical-align: middle !important;
        padding: 9px 20px !important;
        border-right: 1px solid var(--paradise-border-color) !important;
        border-bottom: 1px solid var(--paradise-border-color) !important;
        white-space: nowrap !important;
        overflow: hidden !important;
        text-overflow: ellipsis !important;
    }
    .hpa-task-board-page .dx-datagrid-table { table-layout: fixed !important; width: 100% !important; }
    .hpa-task-board-page .dx-datagrid-content .dx-datagrid-table .dx-row > td:last-child { border-right: none !important; }

    /* REMOVE ALL INTERACTION EFFECTS */
    .hpa-task-board-page .dx-row-alt { background: transparent !important; }
    .hpa-task-board-page .dx-datagrid-rowsview .dx-selection.dx-row > td,
    .hpa-task-board-page .dx-datagrid-rowsview .dx-row-focused > td { background-color: transparent !important; }

    /* NO DATA AND CONTAINER BGs */
    .hpa-task-board-page .dx-datagrid-rowsview,
    .hpa-task-board-page .dx-datagrid-nodata {
        background-color: transparent !important;
        color: var(--paradise-text-body) !important;
    }
</style>

<div id="hpa-task-board-wrapper" class="bg-body hpa-task-board-page">
    <div class="hpa-modal-header">
        <i class="fas fa-times hpa-btn-close"></i>
    </div>
    <div class="hpa-task-title">THEO DÕI TIẾN ĐỘ CÔNG VIỆC</div>
    <div class="hpa-task-dashboard">
        <div id="overdueGrid"></div>
    </div>
</div>

<script>
    (function() {
        const $wrapper = $("#hpa-task-board-wrapper").last();
        const $tab = $wrapper.closest(".tab-pane");
        const menuId = $tab.length && $tab.attr("id") ? $tab.attr("id").replace("dynamic-pane-", "") : null;
        $("body").append($wrapper);

        const imgCache = {};
        const DEFAULT_AVATAR = `<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg"><circle cx="100" cy="100" r="100" fill="#333"/><circle cx="100" cy="160" r="80" fill="#555"/><circle cx="100" cy="76" r="43" fill="#777"/></svg>`;
        let refreshTimer = null;
        let lastTickTime = 0;

        function getStatusText(dueDate) {
            if (!dueDate) return "";
            const diff = new Date() - new Date(dueDate);
            if (diff > 0) return "Quá hạn";
            if (Math.abs(diff) <= 86400000) return "Sắp tới hạn";
            return "Đang thực hiện";
        }

        // Render nhom avatar chong len nhau (stacked)
        const MAX_VISIBLE_AVATARS = 3;
        function renderAvatarGroup(container, namesStr, imagesStr) {
            const $cell = $(`<div class="td-assignee-cell"></div>`).appendTo(container);

            const names = namesStr ? namesStr.split('', '').filter(n => n.trim()) : [];
            const images = imagesStr ? imagesStr.split(''|||'').filter(p => p !== undefined) : [];

            if (names.length === 0) {
                const $group = $(`<div class="td-avatar-group"></div>`).appendTo($cell);
                const $av = $(`<div class="td-avatar"></div>`).appendTo($group);
                $av.append(DEFAULT_AVATAR);
                $cell.append(`<span style="color:var(--paradise-text-muted);">N/A</span>`);
                return;
            }

            // Avatar group
            const $group = $(`<div class="td-avatar-group"></div>`).appendTo($cell);
            const visibleCount = Math.min(names.length, MAX_VISIBLE_AVATARS);

            for (let i = 0; i < visibleCount; i++) {
                const $av = $(`<div class="td-avatar" title="${names[i]}"></div>`).appendTo($group);
                const imgPath = images[i] ? images[i].trim() : '''';
                if (imgPath) {
                    const $img = $(`<img src="">`).appendTo($av);
                    loadAvatar(imgPath, $img);
                } else {
                    $av.append(DEFAULT_AVATAR);
                }
            }

            // +N badge neu qua nhieu
            if (names.length > MAX_VISIBLE_AVATARS) {
                $group.append(`<div class="td-avatar-extra">+${names.length - MAX_VISIBLE_AVATARS}</div>`);
            }

            // Ten hien thi ben canh
            const $namesDiv = $(`<div class="td-assignee-names"></div>`).appendTo($cell);
            if (names.length <= 2) {
                names.forEach(n => $namesDiv.append(`<span>${n}</span>`));
            } else {
                $namesDiv.append(`<span>${names.slice(0, 2).join('', '')}</span>`);
                $namesDiv.append(`<span style="font-size:12px; color:var(--paradise-text-muted);">+${names.length - 2} người khác</span>`);
            }
        }

        function formatDateTime(dateStr) {
            if (!dateStr) return "";
            const d = new Date(dateStr);
            const pad = v => v.toString().padStart(2, ''0'');
            return `${pad(d.getDate())}/${pad(d.getMonth()+1)}/${d.getFullYear()} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
        }

        async function loadAvatar(path, $img) {
            if (!path) return;

            // 1. Nếu đã có trong cache (đã tải xong), gắn luôn
            if (typeof imgCache[path] === "string") {
                return $img.attr("src", imgCache[path]);
            }

            // 2. Nếu đang trong quá trình tải (là một Promise), chờ tải xong rồi gắn
            if (imgCache[path] instanceof Promise) {
                const url = await imgCache[path];
                return $img.attr("src", url);
            }

            // 3. Nếu chưa tải, tạo Promise tải mới và lưu vào cache
            imgCache[path] = new Promise((resolve) => {
                AjaxHPAParadise({
                    xhrFields: {
                        responseType: "blob"
                    },
                    data: {
                        name: "paradisefile_sp_GetFileAPI",
                        param: ["FilePath", path]
                    },
                    success: function (blob) {
                        try {
                            const url = URL.createObjectURL(new Blob([blob], { type: "image/png" }));
                            imgCache[path] = url; // Ghi đè Promise bằng URL chuỗi
                            $img.attr("src", url);
                            resolve(url);
                        } catch (e) {
                            delete imgCache[path];
                            resolve("");
                        }
                    },
                    error: () => {
                        delete imgCache[path]; // Nếu lỗi thì cho phép tải lại lần sau
                        resolve("");
                    }
                });
            });
        }

        // 1. KHỞI TẠO STORE DỮ LIỆU (ARRAY STORE)
        const taskStore = new DevExpress.data.ArrayStore({
            key: "TaskID",
            data: []
        });

        // 2. KHỞI TẠO GRID REAL-TIME
        const gridInstance = $("#overdueGrid").dxDataGrid({
            dataSource: {
                store: taskStore,
                reshapeOnPush: true,
                sort: [{ selector: "_SortOrder", desc: false }]
            },
            repaintChangesOnly: true,
            highlightChanges: true,
            columnAutoWidth: false,
            showBorders: false,
            showColumnLines: true,
            showRowLines: true,
            scrolling: { mode: "none" },
            paging: { enabled: false },
            noDataText: "Không có dữ liệu công việc",
            onRowPrepared: function(e) {
                if (e.rowType === "data") {
                    const now = new Date();
                    const dueDate = new Date(e.data.DueDate);
                    const diffMs = now - dueDate;

                    e.rowElement.removeClass("row-danger row-warning row-normal");
                    if (diffMs > 0) e.rowElement.addClass("row-danger");
                    else if (Math.abs(diffMs) <= 86400000) e.rowElement.addClass("row-warning");
                    else e.rowElement.addClass("row-normal");
                }
            },
            columns: [
                {
                    dataField: "TaskName", caption: "CÔNG VIỆC", alignment: "left", width: "30%",
                    cellTemplate: function(container, options) {
                        const raw = options.value || '''';
                        const idx = raw.lastIndexOf('' - '');
                        const $wrapper = $("<div class=\"td-task-name-wrapper\" style=\"display:flex; flex-direction:column; justify-content:center; height:100%; overflow:hidden;\"></div>").appendTo(container);
                        
                        if (idx !== -1) {
                            const childName = raw.substring(0, idx);
                            const parentName = raw.substring(idx + 3);
                            $wrapper.append(`<div style="font-size:16px; font-weight:700; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; line-height:1.2;">${parentName}</div>`);
                            $wrapper.append(`<div style="font-size:14px; opacity:0.75; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; line-height:1.1;">
                                <i class="fas fa-chevron-down me-1" style="font-size:10px;"></i>${childName}
                            </div>`);
                        } else {
                            $wrapper.append(`<div style="font-size:16px; font-weight:700; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;">${raw}</div>`);
                        }
                    }
                },
                {
                    caption: "NGƯỜI THỰC HIỆN", alignment: "left", width: "20%",
                    cellTemplate: function(container, options) {
                        renderAvatarGroup(container, options.data.NameAssignee, options.data.ImageLocationAsignee);
                    }
                },
                {
                    caption: "NGƯỜI PHỤ TRÁCH", alignment: "left", width: "20%",
                    cellTemplate: function(container, options) {
                        renderAvatarGroup(container, options.data.NameMainAssignee, options.data.ImageLocationMainAssignee);
                    }
                },
                {
                    dataField: "DueDate", caption: "NGÀY HẾT HẠN", alignment: "center", width: "15%",
                    cellTemplate: function(container, options) {
                        $("<div style=\"font-size:16px; font-weight:600; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;\"></div>")
                            .text(formatDateTime(options.value))
                            .appendTo(container);
                    }
                },
                {
                    dataField: "DueDate", caption: "TRẠNG THÁI", alignment: "center", width: "15%",
                    cellTemplate: function(container, options) {
                        const val = options.value;
                        const statusText = getStatusText(val);
                        let badgeClass = ''badge-normal'';
                        if (val) {
                            const diff = new Date() - new Date(val);
                            if (diff > 0) badgeClass = ''badge-danger'';
                            else if (Math.abs(diff) <= 86400000) badgeClass = ''badge-warning'';
                        }
                        $(`<span class="td-time-badge" data-due="${val}"></span>`)
                            .addClass(badgeClass)
                            .text(statusText)
                            .appendTo(container);
                    }
                }
            ]
        }).dxDataGrid("instance");

        async function updateWebClientConnection(connectionId) {
            if (!connectionId) return;
            return new Promise((resolve) => {
                AjaxHPAParadise({
                    data: {
                        name: "sp_zalo_updateWebClientConnection",
                        param: ["LoginID", window.LoginID, "ConnectionID", connectionId]
                    },
                    success: resolve,
                    error: resolve
                });
            });
        }

        async function lh_zalo_registerConnection() {
            let connectionId = "";
            try {
                if (typeof hub !== "undefined" && hub.connection && hub.connection.id) {
                    connectionId = hub.connection.id;
                } else if (typeof connection !== "undefined" && connection.id) {
                    connectionId = connection.id;
                } else if ($.connection && $.connection.hub && $.connection.hub.id) {
                    connectionId = $.connection.hub.id;
                }
            } catch(e) {}

            if (connectionId) {
                console.log("[Task] Registering connectionId:", connectionId);
                await updateWebClientConnection(connectionId);
            } else {
                setTimeout(lh_zalo_registerConnection, 2000);
            }
        }

        function TaskSync_InsertOrUpdate(data) {
            console.log("[Task] TaskSync_InsertOrUpdate received:", data);
            if (!gridInstance || !data) return;
            try {
                let items;
                if (typeof data === "string") {
                    try {
                        items = JSON.parse(data);
                    } catch (e) {
                        items = data;
                    }
                } else {
                    items = data;
                }

                if (!Array.isArray(items)) items = [items];

                items.forEach(item => {
                    if (item && item.TaskID) {
                        gridInstance.getDataSource().store().push([{
                            type: "update", key: item.TaskID, data: item, insertIfMissing: true
                        }]);
                    }
                });
                syncData();
            } catch (e) {
                console.error("[Task] TaskSync_InsertOrUpdate error:", e, data);
            }
        }

        function TaskSync_Remove(data) {
            console.log("[Task] TaskSync_Remove received:", data);
            if (!gridInstance || !data) return;
            try {
                let items;
                if (typeof data === "string") {
                    try {
                        items = JSON.parse(data);
                    } catch (e) {
                        items = data;
                    }
                } else {
                    items = data;
                }

                if (!Array.isArray(items)) items = [items];

                items.forEach(item => {
                    if (item) {
                        const key = item.TaskID || item;
                        if (key) {
                            gridInstance.getDataSource().store().push([{ type: "remove", key: key }]);
                        }
                    }
                });
                syncData();
            } catch (e) {
                console.error("[Task] TaskSync_Remove error:", e, data);
            }
        }

        async function TaskSync_Reload() {
            console.log("[Task] TaskSync_Reload called");
            await syncData();
        }

        // EXPOSE TO GLOBAL FOR SIGNALR
        window.TaskSync_InsertOrUpdate = TaskSync_InsertOrUpdate;
        window.TaskSync_Remove = TaskSync_Remove;
        window.TaskSync_Reload = TaskSync_Reload;

        async function syncData() {
            return new Promise((resolve) => {
                AjaxHPAParadise({
                    data: {
                        name: "sp_getTaskDueDate",
                        param: []
                    },
                    success: function (res) {
                        try {
                            if (res) {
                                const rawData = typeof res === "string" ? JSON.parse(res) : res;
                                let newData = [];
                                if (rawData.data && Array.isArray(rawData.data) && rawData.data.length > 0) {
                                    newData = rawData.data[0] || [];
                                } else if (Array.isArray(rawData)) {
                                    newData = rawData;
                                }

                                if (gridInstance) {
                                    gridInstance.option("dataSource", newData);
                                }
                            }
                        } catch (e) {
                            console.error("[Task] syncData parse lỗi:", e, res);
                        }
                        resolve();
                    },
                    error: function() {
                        resolve();
                    }
                });
            });
        }

        function closeDashboard() {
            if (refreshTimer) cancelAnimationFrame(refreshTimer);
            if (window.checkChangeInterval) clearInterval(window.checkChangeInterval);
            $(document).off("keydown.hpaDashboard");
            $wrapper.fadeOut(200, function() {
                $(this).remove();
                if (menuId && typeof CloseTab === "function") CloseTab([menuId]);
            });
        }

        function startTick(timestamp) {
            if (!lastTickTime || timestamp - lastTickTime >= 1000) {
                lastTickTime = timestamp;
                const now = new Date();

                $wrapper.find(".td-time-badge").each(function() {
                    const $badge = $(this);
                    const dueDateStr = $badge.data("due");
                    if (dueDateStr) {
                        const dueDate = new Date(dueDateStr);
                        const diffMs = now - dueDate;

                        // 1. Cập nhật chữ trạng thái
                        $badge.text(getStatusText(dueDateStr));

                        // 2. Cập nhật màu sắc badge
                        $badge.removeClass("badge-danger badge-warning badge-normal");
                        if (diffMs > 0) {
                            $badge.addClass("badge-danger");
                        } else if (Math.abs(diffMs) <= 86400000) {
                            $badge.addClass("badge-warning");
                        } else {
                            $badge.addClass("badge-normal");
                        }

                        // 3. Cập nhật màu sắc hàng tự động
                        const $row = $badge.closest(".dx-row");
                        if ($row.length) {
                            if (diffMs > 0) {
                                if (!$row.hasClass("row-danger")) $row.removeClass("row-warning row-normal").addClass("row-danger");
                            } else if (Math.abs(diffMs) <= 86400000) {
                                if (!$row.hasClass("row-warning")) $row.removeClass("row-danger row-normal").addClass("row-warning");
                            } else {
                                if (!$row.hasClass("row-normal")) $row.removeClass("row-danger row-warning").addClass("row-normal");
                            }
                        }
                    }
                });
            }
            refreshTimer = requestAnimationFrame(startTick);
        }

        $wrapper.show().css("display", "flex");
        syncData().then(() => {
            refreshTimer = requestAnimationFrame(startTick);
        });
        lh_zalo_registerConnection();

        $(document).on("keydown.hpaDashboard", function(e) { if (e.keyCode === 27) closeDashboard(); });
        $wrapper.find(".hpa-btn-close").on("click", closeDashboard);
    })();
</script>
';

    -- MERGE vào tblHtmlScriptCache
    MERGE dbo.tblHtmlScriptCache AS tgt
    USING (SELECT 'sp_Task_TaskTimeLine' AS TableName,
                  @LanguageID           AS LanguageID,
                  '-1'                  AS ScreenType,
                  @html                 AS html,
                  N''                   AS HtmlParadise,
                  N''                   AS paradiseJs,
                  '1'                   AS Version,
                  N''                   AS VersionData) AS src
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

    -- Fallback SELECT
    SELECT @html AS html;
END
GO

PRINT '1. Da tao procedure sp_Task_TaskTimeLine_html.';
GO

-- Rebuild cache tự động
DELETE FROM tblHtmlScriptCache WHERE TableName = 'sp_Task_TaskTimeLine';
GO
EXEC dbo.sp_GenerateHTMLScript 'sp_Task_TaskTimeLine_html', @TableName = 'sp_Task_TaskTimeLine';
GO
PRINT '2. Da refresh cache HTML thanh cong cho sp_Task_TaskTimeLine.';
GO
