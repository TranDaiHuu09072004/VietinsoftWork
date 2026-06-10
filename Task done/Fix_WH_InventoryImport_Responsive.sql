CREATE OR ALTER PROCEDURE [dbo].[sp_WH_InventoryImport_html]
as
	DECLARE @Empty nvarchar(100) = '',@Html nvarchar(max) = ''

	select @Html = N'
   <style>
   #sp_WH_InventoryImport_html .btn-add-inventory {
                white-space: nowrap;
                padding: 6px 18px;
                font-weight: 500;
                font-size: 0.9rem;
                border: none;
                box-shadow: 0 2px 4px rgba(74, 158, 15, 0.2);
                transition: background-color 0.2s;

        }
  #sp_WH_InventoryImport_html
    .dx-button-has-icon.dx-button-has-text
    .dx-button-content {
    padding: 6px 12px 6px 12px !important;
  }
   #gridInventoryImport .dx-datagrid-header-panel {
              padding-bottom: 32px;
         }
</style>
<div id="sp_WH_InventoryImport_html">
  <div class="container-fluid mt-4">
    <div id="gridInventoryImport"></div>
  </div>
</div>
 <div class="d-none">
        <div id="SelectedEmployeesp_CRM_CustomerList"></div>
  </div>
<script>
  (() => {


    window.InstancegridInventoryImportPF1056C745EBA4177B902DDA26509CA4D = null;
    // Thêm responsive styles cho grid header
    const stylegridInventoryImport = document.createElement("style");
    stylegridInventoryImport.textContent = `
                              /* =============== RESPONSIVE POPUP STYLES =============== */
                              .dx-datagrid-search-panel .dx-placeholder {
                                  display: none !important;
                              }

                              /* =============== FIX TEXTBOX TRONG GRID =============== */
                              .dx-datagrid .dx-texteditor {
                                  width: 100% !important;
                                  min-width: 0 !important;
                              }

                              .dx-datagrid .dx-texteditor-input {
                                  width: 100% !important;
                                  min-width: 0 !important;
                                  box-sizing: border-box !important;
                              }

                              .dx-datagrid-rowsview .dx-row > td > div {
                                  white-space: nowrap;
                                  overflow: hidden;
                                  text-overflow: ellipsis;
                                  word-break: break-word !important;
                                  line-height: 1.4 !important;
                              }

                              .dx-popup.hpa-responsive {
                                  max-width: 95vw !important;
                                  max-height: 95vh !important;
                                  width: 95vw !important;
                                  left: 0 !important;
                                  top: 0 !important;
                              }

                              .dx-popup.hpa-responsive .dx-popup-content {
                                  height: calc(95vh - 120px) !important;
                                  max-height: calc(95vh - 120px) !important;
                                  overflow-y: auto !important;
                                  padding: 8px !important;
                                  display: flex !important;
        flex-direction: column !important;
                              }

                   .dx-popup.hpa-responsive .dx-popup-content-scrollable {
                                  flex: 1 !important;
                                  min-height: 0 !important;
                                  overflow: auto !important;
                              }

                              .dx-popup-content.dx-popup-content-scrollable {
                    height: auto !important;
                              }

                              .dx-popup.hpa-responsive .dx-toolbar-items {
                                  padding: 4px 0 !important;
                                  flex-wrap: wrap;
                              }

                              .dx-popup.hpa-responsive .dx-toolbar-item {
                                  margin: 2px 2px !important;
                              }

                              /* =============== GRID HEADER STYLES =============== */
                       .dx-datagrid {
                                  font-size: 14px;
                              }

                              .dx-datagrid-headers {
                                  white-space: normal;
                                  word-break: break-word;
                              }

                              .dx-datagrid-header-panel {
                                  padding: 8px;
                              }

                              .dx-datagrid .dx-header-row {
                                  height: auto;
                                  min-height: 44px;
                              }

                              .dx-datagrid .dx-row > td {
                                  padding: 8px !important;
                                  vertical-align: middle !important;
                              }

                              .dx-datagrid .dx-col-fixed {
                                  z-index: 800 !important;
                              }

                              /* Group row - sát mép */
                              .dx-datagrid .dx-group-row {
                                  padding: 0 !important;
                              }

                              .dx-datagrid .dx-group-row > td {
                                  padding: 8px !important;
                              }

                              .dx-datagrid .dx-group-row .dx-group-text {
                                  padding: 0 !important;
                                  margin: 0 !important;
                              }

                              /* Mobile responsive */
                              @media (max-width: 1024px) {
                                  .dx-popup.hpa-responsive {
                                      max-width: 90vw !important;
                                      max-height: 90vh !important;
                                      width: 90vw !important;
                                      left: 5vw !important;
                        }
                .dx-overlay-content.dx-popup-normal.dx-popup-draggable.dx-resizable {
                                      width: 90vw !important;
                                      max-width: 90vw !important;
                                  }
                                  .dx-popup.hpa-responsive .dx-popup-content {
                                      max-height: calc(95vh - 120px) !important;
                                  }
                              }

                              @media (max-width: 768px) {
                                  .dx-datagrid {
                                      font-size: 12px;
                                  }

                                  .dx-datagrid-headers {
                                      padding: 4px !important;
                                  }

                                  .dx-datagrid .dx-header-row {
                                      height: auto;
                           min-height: 36px;
                                      padding: 0 !important;
                     }

                                  .dx-datagrid-text-content {
                                      padding: 4px 2px !important;
                                      font-size: 11px !important;
                                      line-height: 1.3 !important;
         overflow: visible !important;
                                 white-space: nowrap;
                                      text-overflow: ellipsis;







                                      word-break: break-word !important;
                                  }

                                  .dx-datagrid-text-content.dx-header-filter {
                                      padding: 2px 1px !important;
                                  }

                                  .dx-checkbox {
                                      width: 24px !important;
                               height: 24px !important;
                    }

                                  .dx-datagrid-rowsview {
                                      padding: 0 !important;
                                  }

                                  .dx-datagrid .dx-row {
                                      height: auto;
  min-height: 36px !important;
                                      padding: 0 !important;
                                  }

                                  .dx-datagrid .dx-data-row > td > div {
                                      padding: 4px 8px !important;
                                      white-space: nowrap;
                                      text-overflow: ellipsis;
                                      word-break: break-word !important;
                                      vertical-align: middle !important;
                                  }

                                  .dx-datagrid .dx-group-row > td {
                                      padding: 4px 2px !important;
                                  }

                                  .dx-pager {
                                      padding: 4px 0 !important;
                                  }

                                  .dx-pager-page,
                                  .dx-pager-navigation {
                                      padding: 2px 4px !important;
                                      font-size: 11px !important;
                                  }

                                  .dx-searchbox {
                                      width: 100% !important;
                                      max-width: none !important;
                                  }

                                  .dx-searchbox .dx-texteditor-input {
                                      padding: 4px !important;
                                      font-size: 12px !important;
                                      height: 32px !important;
                                  }

                                  .dx-popup.hpa-responsive {
           max-width: 95vw !important;
                                      max-height: 85vh !important;
                                      width: 95vw !important;
                                      left: 2.5vw !important;
                                      top: 5vh !important;
                                  }
                                  .dx-overlay-content.dx-popup-normal.dx-popup-draggable.dx-resizable {
                                      width: 95vw !important;
                                      max-width: 95vw !important;
                                      height: auto !important;
                                      max-height: 85vh !important;
                                  }
                                  .dx-popup.hpa-responsive .dx-overlay-wrapper {
                                      position: fixed !important;
                                  }
         .dx-popup.hpa-responsive .dx-popup-content {
                                      height: calc(95vh - 120px) !important;
                                      max-height: calc(95vh - 120px) !important;
                                      font-size: 13px !important;
                                      padding: 6px !important;
                               display: flex !important;
      flex-direction: column !important;
                                  }

.dx-popup.hpa-responsive .dx-popup-content-scrollable {
                                      flex: 1 !important;
                                      min-height: 0 !important;
                                      overflow: auto !important;
                                  }

                                  .dx-popup-content.dx-popup-content-scrollable {
                                      height: auto !important;
                                  }

                       /* Toolbar buttons */
                                  .dx-popup.hpa-responsive .dx-toolbar-item .dx-button {
                                      padding: 6px 12px !important;
                                      font-size: 12px !important;
                                      min-height: 36px !important;
                                  width: auto !important;
                                  }
                             .dx-popup.hpa-responsive .dx-toolbar-item .dx-button .dx-button-text {
                                      font-size: 12px !important;
                                  }
                                  .dx-popup.hpa-responsive .dx-button {
                                      padding: 6px 12px !important;
                                      font-size: 12px !important;
                                      min-height: 36px !important;
                                      width: auto !important;
                                  }
                                  .dx-popup.hpa-responsive .dx-button .dx-button-text {
                                      font-size: 12px !important;
                                  }
                                  .dx-popup.hpa-responsive .dx-datagrid {
                                      font-size: 11px !important;
                                  }
                                  .dx-popup.hpa-responsive .dx-datagrid .dx-data-row td {
                                      padding: 4px 2px !important;
                                  }
                              }

                              @media (max-width: 480px) {
                                  .dx-datagrid {
                                      font-size: 12px;
                                  }

                                  .dx-datagrid-headers {
                                      padding: 2px !important;
                                  }

                                  .dx-datagrid .dx-header-row {
                                      min-height: 32px;
                                  }

       .dx-datagrid-text-content {
  padding: 2px 1px !important;

                                      font-size: 12px !important;
                                  }

                                  .dx-checkbox {
                                      width: 20px !important;
                                      height: 20px !important;
                                  }

                                  .dx-datagrid .dx-row {
                                      min-height: 32px;
                                  }

                                  .dx-datagrid .dx-data-row > td > div {
                                      padding: 8px !important;
                                      font-size: 12px !important;
                                  }

                                  .dx-pager-page,
                                  .dx-pager-navigation {
              padding: 1px 2px !important;
                                      font-size: 12px !important;
                                  }

                                .dx-popup.hpa-responsive {
                                      max-width: 98vw !important;
                                      max-height: 80vh !important;
                        width: 98vw !important;
                            left: 1vw !important;
 top: 10vh !important;
                                  }
                    .dx-overlay-content.dx-popup-normal.dx-popup-draggable.dx-resizable {
                                      width: 98vw !important;
                                      max-width: 98vw !important;
                                      height: auto !important;
                                      max-height: 80vh !important;
                                  }
                                  .dx-popup.hpa-responsive .dx-overlay-wrapper {

                                      position: fixed !important;
                      }
                                  .dx-popup.hpa-responsive .dx-popup-content {
                                      height: calc(95vh - 120px) !important;
                                      max-height: calc(95vh - 120px) !important;
                                      font-size: 12px !important;
                                      padding: 4px !important;
  display: flex !important;
                                      flex-direction: column !important;
                                  }

                                  .dx-popup.hpa-responsive .dx-popup-content-scrollable {
                                      flex: 1 !important;
                                      min-height: 0 !important;
                                      overflow: auto !important;
                                  }

                                  .dx-popup-content.dx-popup-content-scrollable {
                                      height: auto !important;
                                  }
                                  /* Toolbar buttons */
                                  .dx-popup.hpa-responsive .dx-toolbar-item .dx-button {
                                      padding: 4px 8px !important;
                                      font-size: 11px !important;
                                      min-height: 32px !important;
                                      width: auto !important;
                                  }
                                  .dx-popup.hpa-responsive .dx-toolbar-item .dx-button .dx-button-text {
                                      font-size: 11px !important;
                                  }
                                  .dx-popup.hpa-responsive .dx-button {
                                      padding: 4px 8px !important;
                                      font-size: 11px !important;
                                      min-height: 32px !important;
                                      width: auto !important;
        }
                                  .dx-popup.hpa-responsive .dx-button .dx-button-text {
         font-size: 11px !important;
                                  }
                                  .dx-popup.hpa-responsive .dx-datagrid {
                                      font-size: 10px !important;
                                  }
                                  .dx-popup.hpa-responsive .dx-datagrid .dx-data-row td {
                                      padding: 2px 1px !important;
                                      font-size: 10px !important;
                                  }
                                  .dx-popup.hpa-responsive .dx-datagrid .dx-header-row {
                                      min-height: 28px !important;
                                  }
                                  .dx-popup.hpa-responsive .dx-checkbox {
                                     width: 18px !important;
                                      height: 18px !important;
         }
                              }
                          `;
    document.head.appendChild(stylegridInventoryImport);
    async function loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback) {
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
                setTimeout(function() {
                    loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback);
                }, 100);
                return;
            }

 // Đánh dấu đang load để tránh load trùng lặp
            window[loadedKey] = "loading";

            await AjaxHPAParadiseAsync({
                data: {
                   name: dataSourceSP,
                    param: ["LoginID", LoginID, "LanguageID", LanguageID]
                },
                success: function(res) {
                    const json = typeof res === "string" ? JSON.parse(res) : res;
                    window[dataSourceKey] = (json.data && json.data[0]) || [];					

					// load trong form bth co combox luon
					

                    window[loadedKey] = true;

                    // Gọi callback nếu có
                    if (typeof onSuccessCallback === "function") {
                        onSuccessCallback(window[dataSourceKey]);
                    }

                    // Tự động cập nhật control nếu có method setDataSource hoặc option
                    // Thử nhiều format tên instance để tương thích
                    const instanceVariants = [
                        "Instance" + columnName.charAt(0).toUpperCase() + columnName.slice(1) + "PED6A4AAAA14F4706822A32B2859DDDAD",
                        "Instance" + columnName + "PED6A4AAAA14F4706822A32B2859DDDAD",
                        "instance" + columnName.charAt(0).toUpperCase() + columnName.slice(1) + "PED6A4AAAA14F4706822A32B2859DDDAD"
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
                                } catch(e) {
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
                       } catch(e) {
                           // Continue to next variant
                             }
                            }
                        }
                    }
                },
                error: function(err) {
                   console.error("[loadDataSourceCommon] Failed to load datasource for", columnName, ":", err);
                    window[loadedKey] = false;
                    if (typeof onSuccessCallback === "function") {
                        onSuccessCallback([]);
  }
                }
            });
        }


    let fromDateValue,toDateValue,isViewAll = true

    // Helper normalize function: bỏ dấu - dùng chung cho search/grid
    window.normalizeVietnameseText =
      window.normalizeVietnameseText ||
      function (value) {
        if (value === undefined || value === null) return "";
        let text = String(value);
        if (typeof RemoveToneMarks_Js === "function") {
          text = RemoveToneMarks_Js(text);
        } else if (text.normalize) {
          text = text.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
        }
        return text.replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase();
      };

    InstancegridInventoryImportPF1056C745EBA4177B902DDA26509CA4D = $(
      "#gridInventoryImport",
    )
      .dxDataGrid({
        dataSource: [],
        keyExpr: "InventoryCode",
        height: "86vh",
        width: "99%",
        showBorders: true,
        showRowLines: true,
        rowAlternationEnabled: false,
        hoverStateEnabled: false,
        columnAutoWidth: true,
        allowColumnReordering: true,
        allowColumnResizing: true,
        columnResizingMode: "widget",
        columnMinWidth: 80,
        wordWrapEnabled: true,

        scrolling: {
          mode: "virtual", // standard
          showScrollbar: "onHover",
        },
        paging: {
          enabled: true,
          pageSize: 10,
        },

        pager: {
          visible: true,
          allowedPageSizes: [5, 10, 50, 100],
          showPageSizeSelector: true,
          showInfo: true,
          showNavigationButtons: true,
        },

        selection: {
          mode: "single",
          showCheckBoxesMode: "none",
          allowSelectAll: false,
        },

        searchPanel: {
          visible: true,
          width: 260,
          highlightSearchResults: false,
          highlightCaseSensitive: false,
          placeholder: "Tìm kiếm theo nội dung",
        },

        headerFilter: { visible: false },

        stateStoring: {
          enabled: false,
          type: "localStorage",
          storageKey: "gridState_gridInventoryImport",
        },

        grouping: {
          autoExpandAll: false,
          contextMenuEnabled: false,
          allowCollapsing: false,
        },

        groupPanel: { visible: false },
        columnFixing: { enabled: false },

        customizeColumns: function (columns) {
          const normalizeText =
            window.normalizeVietnameseText ||
            function (val) {
              if (val === undefined || val === null) return "";
              return String(val).toLowerCase();
            };

          columns.forEach(function (column) {
    if (column._hpaSearchNormalized) return;
            column._hpaSearchNormalized = true;

            const originalCalculate = column.calculateFilterExpression;
            const dataFieldPath = column.dataField || column.name || "";
            const getValue = column.calculateCellValue
              ? column.calculateCellValue.bind(column)
              : function (dataObj) {
                  if (!dataObj || !dataFieldPath) return null;
                  if (dataFieldPath.indexOf(".") === -1) {
                    return dataObj[dataFieldPath];
                  }
                  return dataFieldPath.split(".").reduce(function (acc, key) {
                    return acc && acc[key] !== undefined ? acc[key] : null;
                  }, dataObj);
                };

            column.calculateFilterExpression = function (
              filterValue,
              selectedFilterOperation,
              target,
            ) {
              if (target === "search") {
                const normalizedFilter = normalizeText(filterValue);
                if (!normalizedFilter) {
                  if (originalCalculate) {
                    return originalCalculate.call(
                      this,
                      filterValue,
                      selectedFilterOperation,
                      target,
                    );
                  }
                  if (this.defaultCalculateFilterExpression) {
                    return this.defaultCalculateFilterExpression(
                      filterValue,
                      selectedFilterOperation,
                      target,
                    );
                  }
                  return null;
                }

                return function (dataItem) {
                  const rawValue = getValue ? getValue(dataItem) : null;
                  const normalizedValue = normalizeText(rawValue);
                  return normalizedValue.indexOf(normalizedFilter) > -1;
                };
              }

              if (originalCalculate) {
                return originalCalculate.call(
                  this,
                  filterValue,
                  selectedFilterOperation,
                  target,
                );
              }

              if (this.defaultCalculateFilterExpression) {
                return this.defaultCalculateFilterExpression(
                  filterValue,
                  selectedFilterOperation,
                  target,
                );
              }

              return null;
            };
          });
        },

        editing: {
          mode: "cell",
          allowUpdating: false,
        },
        rowDragging: {
          allowReordering: false,
          showDragIcons: false,
        },
        noDataText: "Không có dữ liệu",
        columns: [
          {
            dataField: "InventoryCode",
            caption: "Lệnh nhập hàng",
            width: 150,
            alignment: "left",
            minWidth: 80,
            maxWidth: 400,
            allowSorting: true,
            allowFiltering: true,
            cellTemplate: function (cellElement, cellInfo) {
              const val = cellInfo.value;
              if (val === undefined || val === null || val === "") {
                $("<div>")
                  .addClass("dx-placeholder")
                  .text("--")
                  .appendTo(cellElement);
                return;
              }
              $("<div>").text(val).appendTo(cellElement);
            },
            allowEditing: false,
          },

          {
            dataField: "Date",
            caption: "Ngày lập lệnh",
            width: 150,
            alignment: "left",
            minWidth: 80,
            maxWidth: 400,
            allowSorting: true,
            allowFiltering: true,
            cellTemplate: function (cellElement, cellInfo) {
      const val = cellInfo.value;
              if (!val || val === "") {
         $("<div>")

                  .addClass("dx-placeholder")
                  .text("--")
                  .appendTo(cellElement);
                return;
              }
              const d = new Date(val);
              let text = "";
              text = DevExpress.localization.formatDate(d, "dd/MM/yyyy");
              $("<div>").text(text).appendTo(cellElement);
            },
            allowEditing: false,
          },

         /* {
            dataField: "ExpDate",
            caption: "Hạn nhập kho",
            width: 150,
            alignment: "left",
            minWidth: 80,
            maxWidth: 400,
            allowSorting: true,
            allowFiltering: true,
            cellTemplate: function (cellElement, cellInfo) {
              const val = cellInfo.value;
              if (!val || val === "") {
                $("<div>")
                  .addClass("dx-placeholder")
                  .text("--")
                  .appendTo(cellElement);
                return;
              }
              const d = new Date(val);
              let text = "";
              text = DevExpress.localization.formatDate(d, "dd/MM/yyyy");
              $("<div>").text(text).appendTo(cellElement);
            },
            allowEditing: false,
          },*/

          {
            dataField: "EmployeeID",
            caption: "Người thực hiện",
            width: 150,
            alignment: "left",
            minWidth: 80,
            maxWidth: 400,
            allowSorting: true,
            allowFiltering: true,
            cellTemplate: function (cellElement, cellInfo) {
              const val = cellInfo.value;
              if (!val || val === "") {
                $("<div>")
                  .addClass("dx-placeholder")
                  .text("--")
                  .appendTo(cellElement);
                return;
              }
              const ds = window["DataSource_EmployeeIDMultiselectedsp_WH_InventoryImport"];
              if (ds && Array.isArray(ds)) {
                const f = ds.find((x) => x.id == val || x.ID == val);
                if (f) {
                  $("<div>")
                    .text(f.Text || f.Name || "")
                    .appendTo(cellElement);
                  return;
                }
              }

              $("<div>").text(val).appendTo(cellElement);
            },
            allowEditing: false,
          },

          {
            dataField: "CommandTypeID",
            caption: "Loại lệnh",
            width: 200,
            alignment: "left",
            minWidth: 80,
            maxWidth: 400,
            allowSorting: true,
            allowFiltering: true,
            cellTemplate: function (cellElement, cellInfo) {
              const val = cellInfo.value;
              if (!val || val === "") {
                $("<div>")
                  .addClass("dx-placeholder")
                  .text("--")
                  .appendTo(cellElement);
                return;
              }
              const ds = window["DataSource_CommandTypeID"];
              if (ds && Array.isArray(ds)) {
                const f = ds.find((x) => x.id == val || x.ID == val);
                if (f) {
                  $("<div>")
                    .text(f.Text || f.Name || "")
                    .appendTo(cellElement);
                  return;
                }
              }

              $("<div>").text(val).appendTo(cellElement);
            },
            allowEditing: false,
          },

          {
            dataField: "StatusID",
            caption: "Tình trạng thực hiện",
            width: 200,
            alignment: "left",
            minWidth: 80,
            maxWidth: 400,
            allowSorting: true,
            allowFiltering: true,
            cellTemplate: function (cellElement, cellInfo) {
              const val = cellInfo.value;


              if (!val || val === "") {
                $("<div>")
                  .addClass("dx-placeholder")
                  .text("--")
                  .appendTo(cellElement);
                return;
              }


              $("<div>").text(val).addClass(`text-${cellInfo.data.Color}`).appendTo(cellElement);
            },
            allowEditing: false,
          },
         {
                    caption: "",
                    width: 50,
                    alignment: "center",
                    cellTemplate: function (cellElement, cellInfo) {
                        if (String(cellInfo.data.Status) === "2" || String(cellInfo.data.StatusID) === "2") {
                            let $btn = $("<button>").addClass("text-danger").html(''<i class="bi bi-trash"></i>'');
                            $btn.on("click", async function (e) {
                                e.stopPropagation();
                                showConfirmPopup({
                                    title: "%ACComfirm%",
                                    message: "%Common_Confirm_DeleteTitle%",
                                    YesText: "%ConfirmYes%",
                                    NoText: "%cancelBtn%",
                                    onYes: async () => {
                                        const skeletonId = "skeleton-delete-" + Date.now();
                                        const skeletonHTML = `
                                        <div id="${skeletonId}" style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(var(--bs-body-bg-rgb), 0.8); z-index: 9999; display: flex; align-items: center; justify-content: center;">
                                            <div style="color: var(--bs-primary); font-size: 24px; font-weight: bold; letter-spacing: 4px;">║  ║  ║</div>
                                        </div>
                                    `;
                                        $("body").append(skeletonHTML);

                                        try {
                                            let res = await AjaxHPAParadiseAsync({
                                                data: { name: "spWH_DeleteInventoryImport", param: ["Action", "Delete", "InventoryCode", cellInfo.data.InventoryCode] }
                                            });

                                            if (res) {
                                                uiManager.showAlert({ type: "success", message: "Xóa thành công!" });
                                                // Xóa row đã xóa trong _pageCache
                                                    if (typeof _pageCache !== "undefined") {
                                                        const deletedCode = cellInfo.data.InventoryCode;
                                                        Object.keys(_pageCache).forEach(key => {
                                                            if (_pageCache[key] && Array.isArray(_pageCache[key].data)) {
                                                                let originalLength = _pageCache[key].data.length;
                                                                _pageCache[key].data = _pageCache[key].data.filter(item => item.InventoryCode !== deletedCode);
                                                                let newLength = _pageCache[key].data.length;
                                                                if (originalLength > newLength) {
                                                                    _pageCache[key].totalCount = Math.max(0, _pageCache[key].totalCount - (originalLength - newLength));
                                                                }
                                                            }
                                                        });
                                                    }
                                                InstancegridInventoryImportPF1056C745EBA4177B902DDA26509CA4D.getDataSource().reload();
                                            } else {
                                                uiManager.showAlert({ type: "warning", message: "Xóa thất bại!" });
                                            }
                                        } catch (err) {
                                            uiManager.showAlert({ type: "danger", message: "Lỗi hệ thống!" });
                                        } finally {
                                            $("#" + skeletonId).remove();
                                        }
                                    }
                                })
                            });
                            cellElement.append($btn);
                        }
                    },
                    allowEditing: false,
                },
        ],
        onCellClick(e) {
          if (0 !== 1) return;

          // Nếu có multi select:
          // - Click vào detail column (_detailAction) thì mở detail
          // - Click vào checkbox column thì chỉ select
          // - Click vào columns khác thì không làm gì
          if (0 === 1) {
            if (e.column.dataField === "_detailAction") {
              // Click vào detail button - mở detail
              const rowDataObject = e.data;
              const recordID = e.key ?? e.data?.["InventoryCode"];
              if (!recordID) return;
              window.currentClicked_gridInventoryImport = recordID;
              window.currentRecordID_InventoryCode = recordID;
              openDetailInventoryCode?.(rowDataObject);
            }
            return; // Không xử lý các column khác khi có multi select
          }

          const rowDataObject = e.data;

          const recordID = e.key ?? e.data?.["InventoryCode"];
          if (!recordID) return;
          window.currentClicked_gridInventoryImport = recordID;
          window.currentRecordID_InventoryCode = recordID;
          openDetailInventoryCode?.(rowDataObject);
        },
        onRowPrepared(e) {},
        onOptionChanged(e) {
          // Persist column chooser changes (visibility/order/width)
          if (e.fullName && e.fullName.startsWith("columns[")) {
            const timers = chooser.saveTimers;
            if (timers[gridName]) {
              clearTimeout(timers[gridName]);
            }
            timers[gridName] = setTimeout(function () {
              chooser.save(
                InstancegridInventoryImportPF1056C745EBA4177B902DDA26509CA4D,
                gridName,
              );
            }, 400);
          }
        },
        onRowClick: function (e) {
          InvenCode = e.data.InventoryCode;
          //SetValueControl(e.data);
        },
        onToolbarPreparing: function (e) {
            e.toolbarOptions.items.unshift({
              location: "before",
              template: function (data, index, element) {

                const $container = $(`
                  <div class="ms-filter-toolbar" style="display:flex;flex-direction:column;gap:3px;width:100%;box-sizing:border-box;min-height:auto;">
                  </div>
                `);

                let $employeeDiv;
                if (window.EmployeeID_Login) {
                  $employeeDiv = $(`
                    <div style="display:flex;align-items:center;gap:5px;min-width:160px;">
                      <label style="font-size:11px;color:#64748b;white-space:nowrap;">Nhân viên:</label>
                      <div id="multilselectedEmployeeInventoryImport" style="width:160px;"></div>
                    </div>
                  `);
                }

                const $firstRow = $(`
                  <div style="display:flex;gap:6px;align-items:center;flex-wrap:wrap;width:100%;margin-bottom:8px;"></div>
                `);

                const $dateContainer = $(`
                  <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap;"></div>
                `);

                const $fromDiv = $(`
                  <div style="display:flex;align-items:center;gap:5px;min-width:120px;">
                    <div class="filter-from-date"></div>
                  </div>
                `);

                let InstanceFromDate = $fromDiv
                  .find(".filter-from-date")

                  .dxDateBox({
                    width: 160,
label: "Từ",
                    labelMode: "static",
                    type: "date",
                    disabled: true,
                    displayFormat: "dd/MM/yyyy",
                    value: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
                    onValueChanged: function (e) {
                      fromDateValue = e.value;
                    }
                  })
                  .dxDateBox("instance");


                const $toDiv = $(`
                  <div style="display:flex;align-items:center;gap:5px;min-width:120px;">
                    <div class="filter-to-date"></div>
                  </div>
                `);

                let InstanceToDate = $toDiv
                  .find(".filter-to-date")
                  .dxDateBox({
                    width: 160,
                    label: "Đến",
                    labelMode: "static",
                    type: "date",
                    displayFormat: "dd/MM/yyyy",
                    disabled: true,
                    value:new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0),
                    onValueChanged: function (e) {
                      toDateValue = e.value;
                    }
                  })
                  .dxDateBox("instance");

                $dateContainer.append($fromDiv, $toDiv);

                const $actionButtonContainer = $(`
                  <div style="display:flex;gap:5px;align-items:center;"></div>
                `);
                $filterBtn = $(`<button class="btn btn-add-inventory btn-success">
                                             <i class="bi bi-funnel"></i> %search%
                                                </button>
                                                `);

                $filterBtn.on("click", function () {
                  InstancegridInventoryImportPF1056C745EBA4177B902DDA26509CA4D.getDataSource().reload();
                });

                const $resetBtn = $(`
                  <button class="btn btn-outline-success btn-add-inventory">
                    <i class="bi bi-arrow-clockwise"></i> Làm mới
                  </button>
                `);
                $resetBtn.off("click").on("click",function(){
                    isViewAll = true
                     InstanceToDate.option("disabled", isViewAll);
                    InstanceFromDate.option("disabled", isViewAll);
                    $checkboxRow.find(".toolbar-view-all").prop("checked",true)
                     $checkboxRow.find(".toolbar-only-user").prop("checked",false)
                    fromDateValue = null;
                    toDateValue = null;
                    InstanceEmployeeIDSelectedEmployeesp_CRM_CustomerList.option("value",null);
                    InstancegridInventoryImportPF1056C745EBA4177B902DDA26509CA4D.getDataSource().reload();
                })
                const $checkboxRow = $(`
                  <div style="display:flex;align-items:center;gap:15px;"></div>
                `);

                $checkboxRow.append(`
                  <input type="checkbox" checked class="toolbar-view-all" style="width:15px;height:15px;cursor:pointer;accent-color:#198754;">
                  <label style="font-size:12px;color:#64748b;cursor:pointer;margin:0;">Xem tất cả</label>
                `);

                if (window.EmployeeID_Login) {
                  $checkboxRow.append(`
      <input type="checkbox" class="toolbar-only-user" style="width:15px;height:15px;cursor:pointer;accent-color:#198754;">
                    <label style="font-size:12px;color:#64748b;cursor:pointer;margin:0;">Chỉ xem của tôi</label>
                  `);
                }

                $checkboxRow
                  .find(".toolbar-view-all")
                  .off("change")
    .on("change", function () {

                    const checked = $(this).is(":checked");

        isViewAll= checked;

                    InstanceToDate.option("disabled", checked);
                    InstanceFromDate.option("disabled", checked);

                if (checked) {
                    fromDateValue = null;
                      toDateValue = null;
                    } else {
                      fromDateValue = InstanceFromDate.option("value");
                      toDateValue = InstanceToDate.option("value");
                    }

                    InstancegridInventoryImportPF1056C745EBA4177B902DDA26509CA4D.getDataSource().reload();

                    $fromDiv.css("opacity", checked ? "0.4" : "1");
                    $toDiv.css("opacity", checked ? "0.4" : "1");
                  });
                $checkboxRow
                  .find(".toolbar-only-user")
                  .off("change")
                  .on("change", function () {
                    const checked = $(this).is(":checked");
                    if (checked) {
                        InstanceEmployeeIDSelectedEmployeesp_CRM_CustomerList.option("value",EmployeeID_Login)

                    } else {
                        InstanceEmployeeIDSelectedEmployeesp_CRM_CustomerList.option("value",null);
                    }

                    let arrEm = InstanceEmployeeIDSelectedEmployeesp_CRM_CustomerList.option("value")
                    InstancegridInventoryImportPF1056C745EBA4177B902DDA26509CA4D.getDataSource().reload();

                });
                $resetBtn.on("click", function () {


                });

                $actionButtonContainer.append($filterBtn, $resetBtn);

                $firstRow.append(
                  $employeeDiv || $("<div></div>"),
                  $dateContainer,
                  $actionButtonContainer
                );

                const $secondRow = $(`
                  <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap;width:100%;"></div>
                `);

                $secondRow.append($checkboxRow);

                $container.append($firstRow, $secondRow);

                $(element).parent().prepend($container);

              }
            },{
                 location: "after",
                 template: function () {
                       const $wrap = $(''<div class="toolbar-right d-flex align-items-center gap-2"></div>'');
                        const $btnAdd = $(`<button class="btn btn-add-inventory btn-success">
                                            <i class="bi bi-plus-lg"></i> %addnew%
                                                </button>
                                                `);
                          $btnAdd.off("click").on("click", function(){
                            addInventory()
                          })
                         const $btnGroup = $(''<div class="d-flex align-items-center gap-2"></div>'');
                         $btnGroup.append($btnAdd);
                         $wrap.append($btnGroup)
                        return $wrap
                 }
            });
        },
        onRowDblClick: function (e) {
            let InventoryCode = e?.data?.InventoryCode || "";

            if (InventoryCode !== "") {
                if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
                    OpenFormParamMobile("sp_WH_InventoryImport_Detail", {
                        InventoryCode: InventoryCode
                    });
                } else {
                    openFormParam("sp_WH_InventoryImport_Detail", {
                        InventoryCode: InventoryCode
                    });
                }
            }
        }
      })
      .dxDataGrid("instance");

      let _pageCache = {};
        let dataStore_GridInventoryImport = [];
        let _currentKeyword = "";

   async function ReloadData(pageNumber = 1, pageSize = 50) {

          function normalizeKeyword(text) {

            if (!text) return "";

            let t = String(text);

            if (typeof RemoveToneMarks_Js === "function") t = RemoveToneMarks_Js(t);
            else if (t.normalize)
              t = t.normalize("NFD").replace(/[\u0300-\u036f]/g, "");

            return t.replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase().trim();
          }

          let gridInstance = InstancegridInventoryImportPF1056C745EBA4177B902DDA26509CA4D;

          dataStore_GridInventoryImport = new DevExpress.data.CustomStore({
            key: "InventoryCode",

            load: async function (loadOptions) {
              const arrEmployee = InstanceEmployeeIDSelectedEmployeesp_CRM_CustomerList.option("value") || ""
              const take = loadOptions.take || pageSize;
              const skip = loadOptions.skip || 0;

              const curPage = Math.floor(skip / take) + 1;

              const keyword = _currentKeyword;

              const cacheKey =
                `${fromDateValue}_${toDateValue}_${isViewAll}_${arrEmployee}_${keyword}_${curPage}_${take}`;

              if (_pageCache[cacheKey]) {
                return _pageCache[cacheKey];
              }

              let result = await AjaxHPAParadiseAsync({
                data: {
                  name: "sp_WH_getGridInventoryImport",
                  param: [
                    "FromDate", fromDateValue,
                    "ToDate", toDateValue,
                    "isViewAll", isViewAll,
                    "arrEmployee", arrEmployee,
                    "Keyword", keyword,
                    "PageNumber", curPage,
                    "PageSize", take
                  ],
                },
              });

              let json = typeof result === "string" ? JSON.parse(result) : result;

              let rows = Array.isArray(json?.data?.[0])
                ? json.data[0]
                : json?.data?.[0]
                  ? [json.data[0]]
                  : [];

              let totalCount = json?.data?.[1]?.[0]?.TotalCount ?? rows.length;

              const pageData = {
                data: rows,
                totalCount: totalCount
              };

              _pageCache[cacheKey] = pageData;

              return pageData;
            },
          });

          gridInstance.beginUpdate();

          gridInstance.option({
            dataSource: dataStore_GridInventoryImport,

            scrolling: {
              mode: "standard",
              showScrollbar: "onHover",
            },

            remoteOperations: {
              paging: true,
              filtering: false
            },

            paging: {
              enabled: true,
              pageSize: pageSize,
            },

            pager: {
              visible: true,
              allowedPageSizes: [5, 10, 50, 100],
              showPageSizeSelector: true,
              showInfo: true,
              showNavigationButtons: true,
            },

            searchPanel: {
              highlightSearchText: false,
            },

            onOptionChanged: function (e) {
              if (e.fullName === "searchPanel.text") {

                _currentKeyword = normalizeKeyword(e.value);

                _pageCache = {};

                gridInstance.refresh();
              }
            },
          });

          gridInstance.endUpdate();
        }


      //LuongNQ
           window.GlobalEmployeeAvatarCache = window.GlobalEmployeeAvatarCache || {};
           window.GlobalEmployeeAvatarLoading = window.GlobalEmployeeAvatarLoading || {};
           let InstanceEmployeeIDSelectedEmployeesp_CRM_CustomerList = null;

           function loadGlobalAvatarIfNeededEmployeeIDSelectedEmployeesp_CRM_CustomerList(employeeId, storeImgName, paramImg, callbackFn) {
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

           window["DataSource_EmployeeIDSelectedEmployeesp_CRM_CustomerList"] = window["DataSource_EmployeeIDSelectedEmployeesp_CRM_CustomerList"] || [];
           let spNameDSEEmployeeIDSelectedEmployeesp_CRM_CustomerList = "sp_EmployeeListDataMultiSelectSelectBox";
           let EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds = [], EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIdsOriginal = [];
           const MAX_VISIBLE_EmployeeIDSelectedEmployeesp_CRM_CustomerList = 3;
           let _autoSaveEmployeeIDSelectedEmployeesp_CRM_CustomerList = false;
           let _readOnlyEmployeeIDSelectedEmployeesp_CRM_CustomerList = false;
let EmployeeIDSelectedEmployeesp_CRM_CustomerListIsSaving = false;
           $(document).ready(function () {
               // Sử dụng hàm loadDataSourceCommon từ sptblCommonControlType_Signed
               if (spNameDSEEmployeeIDSelectedEmployeesp_CRM_CustomerList && spNameDSEEmployeeIDSelectedEmployeesp_CRM_CustomerList.trim() !== "") {
                   loadDataSourceCommon("EmployeeIDSelectedEmployeesp_CRM_CustomerList", spNameDSEEmployeeIDSelectedEmployeesp_CRM_CustomerList, function(data) {
    window["DataSource_EmployeeIDSelectedEmployeesp_CRM_CustomerList"] = data || [];
                       if (Array.isArray(data) && data.length > 0) {
                           data.forEach(emp => {
                               hpaUtils.loadAvatar(emp.ID, emp.StoreImgName, emp.ImgParamV);
                           });
                       }

                       if (typeof renderDisplayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList === "function") {
                           renderDisplayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList();
                       }
                   });
               }

           })


           function getInitialsEmployeeIDSelectedEmployeesp_CRM_CustomerList(name) {
               if (!name) return "?";
               const words = name.trim().split(/\s+/);
               if (words.length >= 2) return (words[0][0] + words[words.length - 1][0]).toUpperCase();
               return name.substring(0, 2).toUpperCase();
           }

           function getColorForIdEmployeeIDSelectedEmployeesp_CRM_CustomerList(id) {
               const colors = [
                   { bg: "#e3f2fd", text: "#1976d2" },
                   { bg: "#f3e5f5", text: "#7b1fa2" },
                   { bg: "#e8f5e9", text: "#388e3c" },
                   { bg: "#fff3e0", text: "#f57c00" },
                   { bg: "#fce4ec", text: "#c2185b" }
               ];
               const numId = parseInt(id, 10);
               const index = isNaN(numId) ? 0 : Math.abs(numId) % colors.length;
               return colors[index];
           }

           function renderDisplayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList() {

               //const $displayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList = $("#EmployeeIDSelectedEmployeesp_CRM_CustomerList_display");
               if (!$("#EmployeeIDSelectedEmployeesp_CRM_CustomerList_display").length) return;
               $("#EmployeeIDSelectedEmployeesp_CRM_CustomerList_display").empty();

               const $wrapper = $("<div>").css({
                   borderBottom: "1px solid #ddd",
                   padding: "0 6px",
                   minHeight: "40px",
                   display: "flex",
            alignItems: "center",
                   cursor: "pointer",
                   transition: "border-bottom-color 0.2s"
               })
               .attr("tabIndex", "0")
               .on("keydown", function(e) {
                   if (e.key === "Enter" || e.key === " " || e.key === "Spacebar") {
                       e.preventDefault();
                       if (_readOnlyEmployeeIDSelectedEmployeesp_CRM_CustomerList) return;
                       if (!popupEmployeeIDSelectedEmployeesp_CRM_CustomerList) {
                    initPopupEmployeeIDSelectedEmployeesp_CRM_CustomerList();
                           setTimeout(() => popupEmployeeIDSelectedEmployeesp_CRM_CustomerList.show(), 0);
                       } else {
                           popupEmployeeIDSelectedEmployeesp_CRM_CustomerList.show();
                       }
                   }
               })
               .on("focus", function() {
                   $wrapper.css({ borderBottom: "2px solid #337ab7", outline: "none" });
               })
               .on("blur", function() {
                   $wrapper.css({ borderBottom: "1px solid #ddd" });
               })
               .hover(
     () => {
                       if (!$wrapper.is(":focus")) {
                           $wrapper.css({ borderBottom: "1px solid #337ab7" });
                       }
                   },
                   () => {
      if (!$wrapper.is(":focus")) {
                           $wrapper.css({ borderBottom: "1px solid #ddd" });
                       }
                   }
               );

     if (EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds.length === 0) {
            $wrapper.append($("<span>").addClass("text-muted").html("<i class=\"bi bi-person-plus me-2\"></i>Chọn nhân viên..."));
               } else {
                   const displayIds = EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds.slice(0, MAX_VISIBLE_EmployeeIDSelectedEmployeesp_CRM_CustomerList);
                   const $group = $("<div>").css({ display: "flex", alignItems: "center" });

                   displayIds.forEach((id, index) => {
                       const item = window["DataSource_EmployeeIDSelectedEmployeesp_CRM_CustomerList"].find(e => String(e.ID) === String(id));
                       if (!item) return;

                       const $chip = $("<div>").css({
                           width: "36px", height: "36px", borderRadius: "50%",
                           border: "3px solid #fff",
                           boxShadow: "0 2px 6px rgba(0,0,0,0.15)",
                           marginLeft: index === 0 ? "0" : "-10px",
                           zIndex: index + 1,
                           display: "flex", alignItems: "center", justifyContent: "center",
                     fontWeight: "600", fontSize: "13px",
                           position: "relative", overflow: "hidden"
                       }).attr("title", item.Name || item.FullName || "");

                       const cachedUrl = window.GlobalEmployeeAvatarCache[String(id)];

                       if (cachedUrl) {
                           $chip.append($("<img>")
                               .attr("src", cachedUrl)
                               .css({ width: "100%", height: "100%", objectFit: "cover" })
                           );
                       } else if (item.storeImgName) {

                           loadGlobalAvatarIfNeededEmployeeIDSelectedEmployeesp_CRM_CustomerList(id, item.storeImgName, item.paramImg, function(url) {
                               renderDisplayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList();
                           });
                           const color = getColorForIdEmployeeIDSelectedEmployeesp_CRM_CustomerList(id);
                           const initials = getInitialsEmployeeIDSelectedEmployeesp_CRM_CustomerList(item.Name || item.FullName);
                           $chip.css({ background: color.bg, color: color.text }).text(initials);
                       } else {
                         const color = getColorForIdEmployeeIDSelectedEmployeesp_CRM_CustomerList(id);
                           const initials = getInitialsEmployeeIDSelectedEmployeesp_CRM_CustomerList(item.Name || item.FullName);
                           $chip.css({ background: color.bg, color: color.text }).text(initials);
                       }

                       $group.append($chip);
                   });

                   if (EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds.length > MAX_VISIBLE_EmployeeIDSelectedEmployeesp_CRM_CustomerList) {
  const remaining = EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds.length - MAX_VISIBLE_EmployeeIDSelectedEmployeesp_CRM_CustomerList;
                       $group.append($("<div>").css({
                           width: "36px", height: "36px", borderRadius: "50%",
                           border: "3px solid #fff", marginLeft: "-10px",
                           zIndex: MAX_VISIBLE_EmployeeIDSelectedEmployeesp_CRM_CustomerList + 1,
                           display: "flex", alignItems: "center", justifyContent: "center",
                           fontWeight: "700", fontSize: "12px"
                       }).text("+" + remaining).attr("title", "Còn " + remaining + " người nữa"));
            }

                   $wrapper.append($group);
               }

               $displayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList.append($wrapper);
               $wrapper.off("click").on("click", () => {
                   if (_readOnlyEmployeeIDSelectedEmployeesp_CRM_CustomerList) {
   if (typeof uiManager !== "undefined" && uiManager.showAlert) {
                           uiManager.showAlert({ type: "info", message: "This field is read-only." });
                       } else {
                           alert("This field is read-only.");
                       }
                       return;
                   }
                   if (!popupEmployeeIDSelectedEmployeesp_CRM_CustomerList) {
                       initPopupEmployeeIDSelectedEmployeesp_CRM_CustomerList();
                       setTimeout(() => {
                           popupEmployeeIDSelectedEmployeesp_CRM_CustomerList.show();
                       }, 0);
                   } else {
                       popupEmployeeIDSelectedEmployeesp_CRM_CustomerList.show();
                   }
               });
           }

           const $containerEmployeeIDSelectedEmployeesp_CRM_CustomerList = $("#SelectedEmployeesp_CRM_CustomerList");
           $containerEmployeeIDSelectedEmployeesp_CRM_CustomerList.empty();
           const $displayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList = $("<div>").attr("id", "EmployeeIDSelectedEmployeesp_CRM_CustomerList_display");
           $containerEmployeeIDSelectedEmployeesp_CRM_CustomerList.append($displayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList);

           let popupEmployeeIDSelectedEmployeesp_CRM_CustomerList;
           let popupEmployeeIDSelectedEmployeesp_CRM_CustomerListOnce = false;
           let EmployeeIDSelectedEmployeesp_CRM_CustomerListGridContainer = null;

           function initPopupEmployeeIDSelectedEmployeesp_CRM_CustomerList() {
               if (popupEmployeeIDSelectedEmployeesp_CRM_CustomerListOnce) {
                   popupEmployeeIDSelectedEmployeesp_CRM_CustomerList.show();
                   return;
               }

               // FIXED: Dọn dẹp DOM rác
               $("#EmployeeIDSelectedEmployeesp_CRM_CustomerList_popup").remove();

               popupEmployeeIDSelectedEmployeesp_CRM_CustomerListOnce = true;
               popupEmployeeIDSelectedEmployeesp_CRM_CustomerList = $("<div>").attr("id", "EmployeeIDSelectedEmployeesp_CRM_CustomerList_popup")
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

                                       EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds = [...EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIdsOriginal];
                                       renderDisplayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList()
                                       popupEmployeeIDSelectedEmployeesp_CRM_CustomerList.hide();
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

                        // Local Save (Sync Grid)
        if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {
                                          try {
                                     const grid = cellInfo.component;
                                                   const newValue = EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds.join(",");
                                                   grid.cellValue(cellInfo.rowIndex, "EmployeeID", newValue || null);
                                                   grid.repaint();
                                               } catch (e) { console.warn(e); }
                                           }
                                           EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIdsOriginal = [...EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds];

                                           renderDisplayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList();

                                           popupEmployeeIDSelectedEmployeesp_CRM_CustomerList.hide();
                                   }
          }
                           }
                       ],
                       contentTemplate: function (contentElement) {
                           EmployeeIDSelectedEmployeesp_CRM_CustomerListGridContainer = $("<div>");
                           contentElement.append(EmployeeIDSelectedEmployeesp_CRM_CustomerListGridContainer);
                       },
                       onShown: () => {
                           const sortedData = window["DataSource_EmployeeIDSelectedEmployeesp_CRM_CustomerList"].sort((a, b) => {
                               const aSelected = EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds.includes(String(a.ID));
                               const bSelected = EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds.includes(String(b.ID));
                               return bSelected - aSelected;
                           });

                           try {
                               const existingInstance = EmployeeIDSelectedEmployeesp_CRM_CustomerListGridContainer.dxDataGrid("instance");
                               if (existingInstance) {
                                   existingInstance.dispose();
                               }
                           } catch (e) {
                               // Instance chưa tồn tại hoặc đã bị destroy
                           }

                           EmployeeIDSelectedEmployeesp_CRM_CustomerListGridContainer
                           .empty()
                           .dxDataGrid({
                               dataSource: sortedData,
                               keyExpr: "ID",
                               remoteOperations: false,
                               columnAutoWidth: true,
                               allowColumnResizing: true,
                               selection: { mode: "multiple", showCheckBoxesMode: "always" },
                               selectedRowKeys: EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds,
                               focusStateEnabled: true,
                               keyboardNavigation: { enabled: true },
                               hoverStateEnabled: true,
                               columns: [
                                   {
            caption: "Ảnh",
                                       width: 80,
                                       alignment: "center",
                                       cellTemplate: function(container, options) {
                  const item = options.data;
                                           const $cell = $("<div>").css({
                                               display: "flex",
                                               justifyContent: "center",
                                               alignItems: "center",
      height: "100%"
               });

                                           const cachedUrl = window.GlobalEmployeeAvatarCache[String(item.ID)];

  if (cachedUrl) {
                                               $cell.append($("<img>")
                                                   .attr("src", cachedUrl)
                                                   .css({
                                                       width: "40px",
                                                       height: "40px",
                                                       borderRadius: "50%",
                                                       objectFit: "cover",
                                                       border: "2px solid #fff",
                                                       boxShadow: "0 2px 4px rgba(0,0,0,0.1)"
                                                   })
                                               );
                                           } else if (item.storeImgName) {

                                               loadGlobalAvatarIfNeededEmployeeIDSelectedEmployeesp_CRM_CustomerList(item.ID, item.storeImgName, item.paramImg, function(url) {
                                                   EmployeeIDSelectedEmployeesp_CRM_CustomerListGridContainer.dxDataGrid("instance").refresh();
                                               });

                                               const initials = getInitialsEmployeeIDSelectedEmployeesp_CRM_CustomerList(item.Name || item.FullName || "?");
                                               const color = getColorForIdEmployeeIDSelectedEmployeesp_CRM_CustomerList(item.ID);
                                               $cell.append($("<div>")
                                                   .text(initials)
                                                   .css({
                                                       width: "40px",
                                                       height: "40px",
                                                       borderRadius: "50%",
                                                       background: color.bg,
                                                       color: color.text,
                                                       display: "flex",
                                                       justifyContent: "center",
                                                       alignItems: "center",
                                                       fontWeight: "600",
                                                       fontSize: "14px",
                                                       boxShadow: "0 2px 4px rgba(0,0,0,0.1)"
                                                   })
                                               );
                                           } else {
                                               const initials = getInitialsEmployeeIDSelectedEmployeesp_CRM_CustomerList(item.Name || item.FullName || "?");
                                               const color = getColorForIdEmployeeIDSelectedEmployeesp_CRM_CustomerList(item.ID);
                                               $cell.append($("<div>")
                                                   .text(initials)
          .css({
                                                       width: "40px",
                                                       height: "40px",
                                               borderRadius: "50%",
                                                       background: color.bg,
                                                       color: color.text,
                                                       display: "flex",
                                                       justifyContent: "center",
       alignItems: "center",
                                               fontWeight: "600",
                                                      fontSize: "14px",
            boxShadow: "0 2px 4px rgba(0,0,0,0.1)"
                                                   })

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
                               onContentReady: function(e) {
                      const grid = e.component;

                                   grid.option("searchPanel.text", "");

                                   const searchBox = grid.getView("headerPanel")._$element.find(".dx-datagrid-search-panel input");

                                   if (searchBox.length) {
                                       if (!$("#custom-search-style-EmployeeIDSelectedEmployeesp_CRM_CustomerList").length) {
                                           $("<style>")
                                               .attr("id", "custom-search-style-EmployeeIDSelectedEmployeesp_CRM_CustomerList")
                                               .text(`
                                                   .dx-datagrid-search-panel input:not(:placeholder-shown) {
                                                       color: #000 !important;
                                                   }
                                                   .dx-datagrid-search-panel input::placeholder {
                                                       color: #999 !important;
                                                       opacity: 1 !important;
                                                   }
                                               `)
                                               .appendTo("head");
                                       }

                                       // Unbind only search-related events (preserve click, focus, etc.)
                                       searchBox.off("input keyup");

                                       searchBox.on("input", function() {
                                           const searchValue = $(this).val();

                                           if (!searchValue) {
                                               grid.clearFilter();
                                               return;
                                           }

                                           const searchNormalized = RemoveToneMarks_Js(searchValue);

                                           grid.filter(function(item) {
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
                               onSelectionChanged: e => EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds = e.selectedRowKeys || []
                           });
                       },
                       onHidden: () => {
                           // FIXED: KHÔNG dispose grid tại đây
                           // Reset position của popup về default
                           popupEmployeeIDSelectedEmployeesp_CRM_CustomerList.option("position", { my: "center", at: "center", of: window });

                           renderDisplayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList();
                       }
                }).dxPopup("instance");
           }

           async function saveValueEmployeeIDSelectedEmployeesp_CRM_CustomerList() {
               if (_readOnlyEmployeeIDSelectedEmployeesp_CRM_CustomerList) {
                   if (typeof uiManager !== "undefined" && uiManager.showAlert) {
                       uiManager.showAlert({ type: "info", message: "This field is read-only." });
                   } else {
                       alert("This field is read-only.");
                   }
                   return;
               }

               const original = EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIdsOriginal.slice().sort().join(",");
               const current = EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds.slice().sort().join(",");
               if (original === current || EmployeeIDSelectedEmployeesp_CRM_CustomerListIsSaving) return;

               EmployeeIDSelectedEmployeesp_CRM_CustomerListIsSaving = true;
               try {
                   const newValue = EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds.join(",");
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

                   // SYNC GRID
                   if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {
             try {
                           const grid = cellInfo.component;
                     grid.cellValue(cellInfo.rowIndex, "EmployeeID", newValue);
                grid.repaint();
                       } catch (syncErr) {
                           console.warn("[Grid Sync] SelectEmployee EmployeeIDSelectedEmployeesp_CRM_CustomerList: Không thể sync grid:", syncErr);
                       }
 }

                   EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIdsOriginal = [...EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds];
                   renderDisplayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList();
               } catch (err) {
                   uiManager.showAlert({ type: "error", message: "%SaveErrorMessage%" });
               } finally {
                   EmployeeIDSelectedEmployeesp_CRM_CustomerListIsSaving = false;
               }
           }
           let _onValueChangedEmployeeIDSelectedEmployeesp_CRM_CustomerList = null
           InstanceEmployeeIDSelectedEmployeesp_CRM_CustomerList = {
               setValue: function(val) {

                   if (typeof val === "string" && val.trim()) {
                       EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds = val.split(",").map(v => v.trim()).filter(v => v);
                   } else if (Array.isArray(val)) {
                       EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds = val.map(String);
                   } else {
                       EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds = [];
                   }
                   EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIdsOriginal = [...EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds];

                    renderDisplayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList()

               },
               getValue: () => EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds,
               getValueAsString: () => EmployeeIDSelectedEmployeesp_CRM_CustomerListSelectedIds.join(","),
               setDataSource: data => {
                   window["DataSource_EmployeeIDSelectedEmployeesp_CRM_CustomerList"] = data || [];
               },
               repaint: renderDisplayBoxEmployeeIDSelectedEmployeesp_CRM_CustomerList,
               _readOnly: false,
               _autoSave: false,
               option: function(name, value) {
                   if (arguments.length === 2) {
                       if (name === "value") this.setValue(value);
                       if (name === "readOnly") {
                           this._readOnly = value;
                           _readOnlyEmployeeIDSelectedEmployeesp_CRM_CustomerList = value;
                           const $displayBox = $("#EmployeeIDSelectedEmployeesp_CRM_CustomerList_display");
                           if (value) $displayBox.addClass("disabled-control").css("opacity", "0.6");
                           else $displayBox.removeClass("disabled-control").css("opacity", "1");
                       }

                       if (name === "autoSave") {
                           this._autoSave = value;
                           _autoSaveEmployeeIDSelectedEmployeesp_CRM_CustomerList = value;
                       }
                       } else if (arguments.length === 1) {
                           if (name === "value") return this.getValueAsString();
                           if (name === "dataSource") return window["DataSource_EmployeeIDSelectedEmployeesp_CRM_CustomerList"];
                           if (name === "readOnly") return _readOnlyEmployeeIDSelectedEmployeesp_CRM_CustomerList;
                           if (name === "autoSave") return _autoSaveEmployeeIDSelectedEmployeesp_CRM_CustomerList;
                       }
                   return undefined;
               },
               _suppressValueChangeAction: function() {

               },
               _resumeValueChangeAction: function() {}
           };
           InstanceEmployeeIDSelectedEmployeesp_CRM_CustomerList.option("onValueChanged", function (e) {
                   if (e.value) {
                       console.log("Giá trị mới:", e.value);
                   }
               });
           setTimeout(() => {
               var employeeFilterWrapper = document.getElementById("multilselectedEmployeeInventoryImport");
                   if (employeeFilterWrapper && employeeFilterWrapper.children.length === 0) {
                       var originalEmployee = document.getElementById("SelectedEmployeesp_CRM_CustomerList");
                       if (originalEmployee && originalEmployee.parentElement) {
                           var employeeDiv = originalEmployee.parentElement.querySelector(''div'');
                           if (employeeDiv) {
                               employeeFilterWrapper.appendChild(employeeDiv);
                           }
                       }
                   }

           }, 300);
           async function addInventory()
           {
                await AjaxHPAParadiseAsync({
                    data: {
                        name: "sp_WH_CRUDCommandImport",
                        param: ["LoginID", UserID,
                            "CommandTypeID", 1]
                    },
                    success: function (res) {
                        if (typeof res == "string" && !IsNullOrEmpty(res)) {
                            res = res.includes("{") ? res : EncryptionStringDecryption(res);
                        }
                        let data = JSON.parse(res).data[0]
                        let IventoryCode = data.length > 0 ? data[0].InventoryCode : ""

                        if(IventoryCode != "")
                        {
                            if (["Android", "iOS"].includes(getMobileOperatingSystem()))
                            {
                                OpenFormParamMobile(`sp_WH_InventoryImport_Detail`,{InventoryCode: IventoryCode});
                            }
                            else
                            {
                                openFormParam(`sp_WH_InventoryImport_Detail`,{InventoryCode: IventoryCode });
                            }
                        }
                    }
                });
           }
    ReloadData();
  })();
</script>
'
	select @Html

    --exec sp_GenerateHTMLScript_new 'sp_WH_InventoryImport_html'
