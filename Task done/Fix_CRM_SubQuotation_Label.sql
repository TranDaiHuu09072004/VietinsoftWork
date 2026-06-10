

CREATE OR ALTER PROCEDURE [dbo].[sp_Sub_SubQuotation_html]



as



	declare @html nvarchar(max) = '',@empty nvarchar(max) = ''



	select @html = N'



   <style>



  #sp_Sub_SubQuotation_html .btn-add-SubQuotation {



    white-space: nowrap;



    padding: 6px 18px;



    font-weight: 500;



    font-size: 0.9rem;



    border: none;



    box-shadow: 0 2px 4px rgba(74, 158, 15, 0.2);



    transition: background-color 0.2s;



  }



  #sp_Sub_SubQuotation_html .modal-overlay {



    position: fixed;



    inset: 0;



    background: rgba(0, 0, 0, 0.7);



    z-index: 1050;



    align-items: center;



    justify-content: center;



    padding: 1rem;



    visibility: hidden;



    opacity: 0;



    transition:



      opacity 0.2s,



      visibility 0.2s;



    display: flex;



    /* Luon co display flex de reserve space */



  }







    #sp_Sub_SubQuotation_html .dx-datagrid-header-panel



     {



        padding-bottom: 32px;



     }



     #sp_Sub_SubQuotation_html .dx-button-has-icon.dx-button-has-text .dx-button-content



     {







        padding: 10px;







     }







    #sp_Sub_SubQuotation_html .btn-icon {



        border-radius: 8px;



    }



  #sp_Sub_SubQuotation_html .btn-add-item {



    background: rgba(46, 125, 50, 0.1);



    color: var(--quote-primary);



    border: 2px dashed var(--quote-primary);



    padding: 0.75rem;



    border-radius: 8px;



    width: 100%;



    cursor: pointer;



    margin-top: 1rem;



    font-weight: 600;



    transition: all 0.2s;



  }







  #sp_Sub_SubQuotation_html .btn-add-item:hover {



    background: rgba(46, 125, 50, 0.2);



    transform: translateY(-2px);



  }







      /* TTV Grid Wrap cho Responsive */

  #sp_Sub_SubQuotation_html .ttv-grid-wrap {

    border: 1px solid var(--bs-border-color);

    border-radius: 10px;

    flex: 0 1 auto;

    min-height: 0;

    max-height: calc(100vh - 120px);

    display: flex;

    flex-direction: column;

    overflow-x: auto;

    overflow-y: hidden;

    background: var(--bs-body-bg);

  }

  @media (max-width: 992px) {

    #sp_Sub_SubQuotation_html .ttv-grid-wrap {

      max-height: none;

      min-height: 500px;

    }

  }



  /* Grid Toolbar Wrap Responsive KI Rules */

  #sp_Sub_SubQuotation_html .dx-datagrid-header-panel .dx-toolbar-items {

    display: flex !important;

    flex-wrap: wrap;

    align-items: center;

    justify-content: space-between;

    gap: 15px;

  }



  #sp_Sub_SubQuotation_html .dx-toolbar-before {

    flex: 0 1 auto;

    flex-wrap: wrap;

  }



  #sp_Sub_SubQuotation_html .dx-toolbar-after {

    flex: 1 1 250px;

    flex-wrap: nowrap !important;

    justify-content: flex-end;

  }



  #sp_Sub_SubQuotation_html .dx-toolbar-after .dx-item:has(.dx-datagrid-search-panel) {

    flex: 1 1 auto !important;

    width: 100%;

    max-width: 350px;

  }



  @media (max-width: 850px) {

    #sp_Sub_SubQuotation_html .dx-toolbar-before,

    #sp_Sub_SubQuotation_html .dx-toolbar-after {

        flex: 1 1 100% !important;

        width: 100% !important;

        justify-content: flex-start !important;

    }

    #sp_Sub_SubQuotation_html .dx-toolbar-after .dx-item:has(.dx-datagrid-search-panel) {

        max-width: 100%;

    }

  }



  #sp_Sub_SubQuotation_html .ms-filter-toolbar {

    margin-bottom: 5px;

  }

  #sp_Sub_SubQuotation_html .dx-datagrid-header-panel .dx-toolbar-item {

    margin-bottom: 5px;

  }



  /* VTS_RESPONSIVE_SUBQUOTATION_CSS_ONLY_20260609

     Chi sua CSS responsive cho sp_Sub_SubQuotation_html, khong doi HTML/JS/API/query. */

  #sp_Sub_SubQuotation_html,

  #sp_Sub_SubQuotation_html * {

    box-sizing: border-box;

  }



  #sp_Sub_SubQuotation_html.container-fluid {

    width: 100%;

    max-width: 100%;

    min-width: 0;

    padding-left: 14px;

    padding-right: 14px;

    overflow-x: hidden;

  }



  #sp_Sub_SubQuotation_html .header-section,

  #sp_Sub_SubQuotation_html .header-section > .d-flex,

  #sp_Sub_SubQuotation_html .header-section h3,

  #sp_Sub_SubQuotation_html .header-section p {

    max-width: 100%;

    min-width: 0;

    white-space: normal;

    overflow-wrap: anywhere;

  }



  #sp_Sub_SubQuotation_html .header-section h3 {

    line-height: 1.25;

  }



  #sp_Sub_SubQuotation_html .ttv-grid-wrap {

    width: 100%;

    max-width: 100%;

    min-width: 0;

    max-height: calc(100dvh - 150px);

    overflow: auto !important;

    -webkit-overflow-scrolling: touch;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-headers,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-rowsview {

    min-width: 0;

    max-width: 100%;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-header-panel {

    padding: 8px 8px 10px !important;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-header-panel .dx-toolbar,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-header-panel .dx-toolbar-items-container,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-header-panel .dx-toolbar-items {

    height: auto !important;

    min-height: 0 !important;

    overflow: visible !important;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-header-panel .dx-toolbar-items {

    display: flex !important;

    flex-wrap: wrap !important;

    align-items: stretch !important;

    justify-content: flex-start !important;

    gap: 8px !important;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-before,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-center,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-after {

    position: static !important;

    display: flex !important;

    flex: 1 1 auto !important;

    width: auto !important;

    min-width: 0 !important;

    height: auto !important;

    flex-wrap: wrap !important;

    align-items: center !important;

    gap: 8px !important;

    transform: none !important;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-after {

    justify-content: flex-end !important;

    margin-left: auto !important;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-item,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar .dx-item,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-button {

    flex: 0 1 auto !important;

    min-width: 0 !important;

    max-width: 100% !important;

    height: auto !important;

    margin: 0 !important;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-search-panel,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-item .dx-texteditor,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-item .dx-selectbox,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-item .dx-datebox,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-item .dx-dropdowneditor {

    width: 100% !important;

    min-width: 0 !important;

    max-width: 100% !important;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-search-panel {

    flex: 1 1 240px !important;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-button {

    max-width: 100%;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-button-has-icon.dx-button-has-text .dx-button-content,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-button-content,

  #sp_Sub_SubQuotation_html .btn-add-SubQuotation {

    min-width: 0;

    max-width: 100%;

    padding: 8px 12px !important;

    white-space: nowrap;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-button-text,

  #sp_Sub_SubQuotation_html .btn-add-SubQuotation {

    overflow: hidden;

    text-overflow: ellipsis;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-table {

    min-width: 980px;

  }



  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-headers .dx-datagrid-text-content,

  #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-rowsview .dx-data-row td {

    white-space: nowrap;

    overflow: hidden;

    text-overflow: ellipsis;

  }



  .dx-popup.hpa-responsive,

  .dx-popup-wrapper .dx-popup.hpa-responsive,

  .dx-overlay-content.dx-popup-normal.dx-popup-draggable.dx-resizable {

    max-width: calc(100vw - 24px) !important;

    max-height: calc(100dvh - 24px) !important;

  }



  .dx-popup.hpa-responsive .dx-popup-content,

  .dx-popup.hpa-responsive .dx-popup-content-scrollable,

  .dx-popup-content.dx-popup-content-scrollable {

    max-height: calc(100dvh - 96px) !important;

    overflow: auto !important;

    -webkit-overflow-scrolling: touch;

  }



  .dx-popup.hpa-responsive .dx-form,

  .dx-popup.hpa-responsive .dx-form-group,

  .dx-popup.hpa-responsive .dx-field-item,

  .dx-popup.hpa-responsive .dx-texteditor,

  .dx-popup.hpa-responsive .dx-selectbox,

  .dx-popup.hpa-responsive .dx-datebox,

  .dx-popup.hpa-responsive .dx-dropdowneditor {

    max-width: 100%;

    min-width: 0;

  }



  @media (max-width: 1024px) {

    #sp_Sub_SubQuotation_html.container-fluid {

      padding-left: 10px;

      padding-right: 10px;

    }



    #sp_Sub_SubQuotation_html .ttv-grid-wrap {

      min-height: 420px !important;

      max-height: calc(100dvh - 170px);

    }



    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-table {

      min-width: 920px;

    }



    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-after {

      justify-content: flex-start !important;

      margin-left: 0 !important;

    }

  }



  @media (max-width: 768px) {

    #sp_Sub_SubQuotation_html.container-fluid {

      padding-left: 8px;

      padding-right: 8px;

    }



    #sp_Sub_SubQuotation_html .header-section h3 {

      font-size: 1.25rem;

    }



    #sp_Sub_SubQuotation_html .header-section p {

      font-size: 0.875rem;

    }



    #sp_Sub_SubQuotation_html .ttv-grid-wrap {

      border-radius: 8px;

      min-height: 360px !important;

      max-height: calc(100dvh - 185px);

    }



    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-header-panel .dx-toolbar-items,

    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-before,

    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-center,

    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-after {

      width: 100% !important;

      flex: 1 1 100% !important;

      justify-content: flex-start !important;

    }



    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-item,

    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar .dx-item,

    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-button {

      flex: 1 1 160px !important;

    }



    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-item:has(.dx-datagrid-search-panel),

    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-search-panel {

      flex: 1 1 100% !important;

      width: 100% !important;

    }



    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-button {

      width: 100%;

    }



    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-table {

      min-width: 860px;

    }



    .dx-popup.hpa-responsive,

    .dx-popup-wrapper .dx-popup.hpa-responsive,

    .dx-overlay-content.dx-popup-normal.dx-popup-draggable.dx-resizable {

      width: calc(100vw - 16px) !important;

      height: auto !important;

      max-width: calc(100vw - 16px) !important;

      max-height: calc(100dvh - 16px) !important;

    }

  }



  @media (max-width: 480px) {

    #sp_Sub_SubQuotation_html.container-fluid {

      padding-left: 6px;

      padding-right: 6px;

    }



    #sp_Sub_SubQuotation_html .header-section {

      padding-bottom: 8px !important;

    }



    #sp_Sub_SubQuotation_html .header-section h3 {

      font-size: 1.1rem;

    }



    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-header-panel {

      padding: 6px !important;

    }



    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-item,

    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar .dx-item,

    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-button {

      flex: 1 1 100% !important;

      width: 100% !important;

    }



    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-button-has-icon.dx-button-has-text .dx-button-content,

    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-button-content,

    #sp_Sub_SubQuotation_html .btn-add-SubQuotation {

      width: 100%;

      justify-content: center;

      padding: 8px 10px !important;

    }



    #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-table {

      min-width: 820px;

    }



    #sp_Sub_SubQuotation_html .ttv-grid-wrap {

      min-height: 330px !important;

      max-height: calc(100dvh - 200px);

    }

  }

  /* Định vị nút "Tạo báo giá mới" lên cùng hàng với bộ lọc trên Desktop */
  @media (min-width: 992px) {
      #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-header-panel .dx-toolbar-items-container,
      #sp_Sub_SubQuotation_html #QuouteListGrid .dx-datagrid-header-panel .dx-toolbar-items {
          position: relative !important;
      }
      
      #sp_Sub_SubQuotation_html .toolbar-right {
          position: absolute !important;
          right: 0 !important;
          top: 0 !important;
          z-index: 100;
      }
      
      #sp_Sub_SubQuotation_html #QuouteListGrid .dx-toolbar-after {
          width: 100% !important;
          flex: 1 1 100% !important;
          justify-content: flex-start !important;
      }
  }
</style>



<div id="sp_Sub_SubQuotation_html" class="container-fluid">



  <div class="header-section pb-2">



    <div



      class="d-flex flex-column flex-md-row justify-content-between align-items-start align-items-md-center gap-3"



    >



      <div>



        <h3 class="mb-1 fw-bold">



          <i class="bi bi-file-earmark-text-fill me-2"></i



          >Quản lý Báo giá Tùy chỉnh



        </h3>



        <p class="mb-0 opacity-75">Tạo và quản lý báo giá cho khách hàng một cách chuyên nghiệp</p>



      </div>



    </div>



  </div>



  <div class="d-none"><div id="SelectedEmployeeSub_SubQuotation"></div></div>



  <div class="ttv-grid-wrap shadow-sm mb-3">



    <div id="QuouteListGrid"></div>



  </div>



</div>



<script>



  (() => {



    let fromDateValue,



      toDateValue,



      isViewAll = true;



    let DataSource = [];







    // Load DataSource: EmployeeListAll_DataSetting_Custom



    if (



      "EmployeeListAll_DataSetting_Custom" &&



      "EmployeeListAll_DataSetting_Custom".trim() !== ""



    ) {



      loadDataSourceCommon(



        "EmployeeID",



        "EmployeeListAll_DataSetting_Custom",



        function (data) {



          // Data du?c shared qua callback



        },



      );



    }







    // Load DataSource: sp_getCustomerPersonInfo



    if (



      "sp_getCustomerPersonInfo" &&



      "sp_getCustomerPersonInfo".trim() !== ""



    ) {



      loadDataSourceCommon(



        "CustomerID",



        "sp_getCustomerPersonInfo",



        function (data) {



          // Data du?c shared qua callback



        },



      );



    }







    window.InstanceQuouteListGridP389C21A8E8BD4889B7C593D29585A11A = null;



    // Them responsive styles cho grid header



    const styleQuouteListGrid = document.createElement("style");



    styleQuouteListGrid.textContent = `



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



                                  table-layout: fixed !important;



                              }







                              /* FIX COLUMN WIDTH ALIGNMENT */



                              .dx-datagrid-table {



                                  table-layout: fixed !important;



                                  width: 100% !important;



                              }







                              .dx-datagrid-headers .dx-datagrid-table {



                                  table-layout: fixed !important;



                              }







                              .dx-datagrid-rowsview .dx-datagrid-table {



                                  table-layout: fixed !important;



                              }







                              /* Ensure header and content cells have same width calculation */



                              .dx-datagrid .dx-header-row > td,



                              .dx-datagrid .dx-data-row > td {



   box-sizing: border-box !important;



                                  overflow: hidden !important;



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







                              /* FORCE COLUMN WIDTH CONSISTENCY */



                              .dx-datagrid .dx-header-row > td,



                              .dx-datagrid .dx-data-row > td {



                                  min-width: 0 !important;



                                  width: auto !important;



                                  max-width: none !important;



                              }







                              /* Prevent column width calculation conflicts */



                              .dx-datagrid-headers .dx-header-row td,



                              .dx-datagrid-rowsview .dx-data-row td {



                                  position: relative !important;



                              }







                              /* Group row - sat mep */



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







                                  /* Fix grid width alignment on tablet */



                                  .dx-datagrid-table {



                                      min-width: 100% !important;



                                  }



                              }







                              @media (max-width: 768px) {



                                  .dx-datagrid {



                                      font-size: 12px;



                                  }







                                  /* Maintain fixed table layout on mobile */



                                  .dx-datagrid-table {



                                      table-layout: fixed !important;



                                      min-width: 100% !important;



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



         overflow: hidden !important;



                           white-space: nowrap !important;



                                      text-overflow: ellipsis !important;



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







     white-space: nowrap !important;



                     text-overflow: ellipsis !important;



                                      word-break: break-word !important;



    vertical-align: middle !important;



                                      overflow: hidden !important;



                                      box-sizing: border-box !important;



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



    document.head.appendChild(styleQuouteListGrid);







    // Helper normalize function: bo dau - dung chung cho search/grid



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







    InstanceQuouteListGridP389C21A8E8BD4889B7C593D29585A11A = $(



      "#QuouteListGrid",



    )



      .dxDataGrid({



        dataSource: [],



        keyExpr: "QuouteID",



        height: "auto",



        width: "100%",



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



        onRowDblClick: function(e) {







           if (["Android", "iOS"].includes(getMobileOperatingSystem())) {



                    OpenFormParamMobile(`sp_Sub_CUSubQuotation`,{QuouteID: e.key});



                } else {



          openFormParam(`sp_Sub_CUSubQuotation`, {QuouteID: e.key});



                }



        },



        scrolling: {



          mode: "virtual", // standard



          showScrollbar: "onHover",



        },







        paging: {



          enabled: true,



          pageSize: 50,



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



          storageKey: "gridState_QuouteListGrid",



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



        noDataText: "Không có dữ liệu",



        columns: [



          {



            dataField: "QuoteCode",



            caption: "Mã báo giá",



            width: 180,



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



                  .text("")



                  .appendTo(cellElement);



                return;



              }



              $("<div>").text(val).appendTo(cellElement);



            },



            allowEditing: false,



          },







          {



            dataField: "CustomerID",



            caption: "Tên khách hàng",



            width: 180,



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



                  .text("")



                  .appendTo(cellElement);



                return;



              }



              $("<div>").text(val).appendTo(cellElement);



            },



            allowEditing: false,



          },



          {



            dataField: "Company",



            caption: "Công ty",



            width: 180,



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



                  .text("")



                  .appendTo(cellElement);



                return;



              }



              $("<div>").text(val).appendTo(cellElement);



            },



            allowEditing: false,



          },







          {



            dataField: "QuoteDate",



            caption: "Ngày tạo",



            width: 180,



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



                  .text("")



                  .appendTo(cellElement);



                return;



              }



              $("<div>").text(val).appendTo(cellElement);



            },



            allowEditing: false,



          },







          {



            dataField: "CustomerID",



            caption: "Người liên hệ",



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



                  .text("")



                  .appendTo(cellElement);



                return;



   }



              $("<div>").text(val).appendTo(cellElement);



            },



            allowEditing: false,



          },







          {



            dataField: "EmployeeID",



            caption: "Người tạo",



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



                  .text("")



                  .appendTo(cellElement);



                return;



              }



              $("<div>").text(val).appendTo(cellElement);



            },



            allowEditing: false,



          },







          {



            dataField: "TotalAmount",



            caption: "Tổng tiền",



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



                  .text("")



                  .appendTo(cellElement);



                return;



              }



              $("<div>").text(val).appendTo(cellElement);



            },



            allowEditing: false,



          },



          {



            caption: "Xuất file",



            width: 150,



            alignment: "center",



            cellTemplate: function (container, options) {



                const key = options.key;



                // Nut Excel



                $("<div>")



                    .dxButton({



                        text: "Excel",



                        icon: "exportxlsx",



                        stylingMode: "contained",



                        type: "success",



                        onClick: function () {



                            exportSubQuoute(key);



                        }



                    })



                    .css("margin-right", "5px")



                    .appendTo(container);







                // Nut PDF



              /*  $("<div>")



                    .dxButton({



                        text: "PDF",



                        icon: "exportpdf",



         stylingMode: "contained",



                        type: "danger",



                        onClick: function () {



                            exportPDF(key);



                        }



                    })



                    .appendTo(container); */



            }



        }



        ],



        onToolbarPreparing: function (e) {



          e.toolbarOptions.items.unshift(



            {



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



                        <div id="multilselectedEmployeebtnSubQuotation" style="width:160px;"></div>



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



                    value: new Date(



                      new Date().getFullYear(),



                      new Date().getMonth(),



                      1,



                    ),



                    onValueChanged: function (e) {



                      fromDateValue = e.value;



                    },



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



                    value: new Date(



                      new Date().getFullYear(),



                      new Date().getMonth() + 1,



                      0,



                    ),



                    onValueChanged: function (e) {



                      toDateValue = e.value;



                    },



                  })



                  .dxDateBox("instance");







                $dateContainer.append($fromDiv, $toDiv);







                const $actionButtonContainer = $(`



                    <div style="display:flex;gap:5px;align-items:center;"></div>



                  `);



                $filterBtn =



                  $(`<button class="btn btn-add-SubQuotation btn-success">



                                               <i class="bi bi-funnel"></i> Tìm kiếm



      </button>



                                                  `);







                $filterBtn.on("click", function () {



                  InstanceQuouteListGridP389C21A8E8BD4889B7C593D29585A11A.getDataSource().reload();



                });







                const $resetBtn = $(`



                    <button class="btn btn-outline-success btn-add-SubQuotation">



                      <i class="bi bi-arrow-clockwise"></i> Làm mới



                    </button>



                  `);



                $resetBtn.off("click").on("click", function () {



                  isViewAll = true;



                  InstanceToDate.option("disabled", isViewAll);



                  InstanceFromDate.option("disabled", isViewAll);



                  $checkboxRow.find(".toolbar-view-all").prop("checked", true);



                  $checkboxRow



                    .find(".toolbar-only-user")



                    .prop("checked", false);



                  fromDateValue = null;



                  toDateValue = null;



                  InstanceEmployeeIDSelectedEmployeeSub_SubQuotation.option(



                    "value",



                    null,



                  );



                  InstanceQuouteListGridP389C21A8E8BD4889B7C593D29585A11A.getDataSource().reload();



                });



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







                    isViewAll = checked;







                    InstanceToDate.option("disabled", checked);



                    InstanceFromDate.option("disabled", checked);







                    if (checked) {



                      fromDateValue = null;



            toDateValue = null;



                    } else {



                      fromDateValue = InstanceFromDate.option("value");



                      toDateValue = InstanceToDate.option("value");



                    }







                    InstanceQuouteListGridP389C21A8E8BD4889B7C593D29585A11A.getDataSource().reload();







     $fromDiv.css("opacity", checked ? "0.4" : "1");



                    $toDiv.css("opacity", checked ? "0.4" : "1");



                  });



                $checkboxRow



                  .find(".toolbar-only-user")



                  .off("change")



                  .on("change", function () {



                    const checked = $(this).is(":checked");



                    if (checked) {



                      InstanceEmployeeIDSelectedEmployeeSub_SubQuotation.option(



                        "value",



                        EmployeeID_Login,



                      );



                    } else {



                      InstanceEmployeeIDSelectedEmployeeSub_SubQuotation.option(



                        "value",



                        null,



                      );



                    }







                    let arrEm =



                      InstanceEmployeeIDSelectedEmployeeSub_SubQuotation.option(



                        "value",



                      );



                    InstanceQuouteListGridP389C21A8E8BD4889B7C593D29585A11A.getDataSource().reload();



                  });



$resetBtn.on("click", function () {});







                $actionButtonContainer.append($filterBtn, $resetBtn);







                $firstRow.append(



                  $employeeDiv || $("<div></div>"),



                  $dateContainer,



                  $actionButtonContainer,



                );







                const $secondRow = $(`



                    <div style="display:flex;gap:10px;align-items:center;flex-wrap:wrap;width:100%;"></div>



                  `);







                $secondRow.append($checkboxRow);







                $container.append($firstRow, $secondRow);







                $(element).parent().prepend($container);



              },



            },



            {



              location: "after",



              template: function () {



                const $wrap = $(



                  ''<div class="toolbar-right d-flex align-items-center gap-2"></div>'',



                );



                const $btnAdd =



                  $(`<button class="btn btn-add-SubQuotation btn-success">



                                              <i class="bi bi-plus-lg"></i> Tạo báo giá mới



                                                  </button>



                                                  `);



                $btnAdd.off("click").on("click", function () {



                       if (["Android", "iOS"].includes(getMobileOperatingSystem())) {



                        OpenFormParamMobile(`sp_Sub_CUSubQuotation`);



                    } else {



                        openFormParam(`sp_Sub_CUSubQuotation`);



                    }



                });



                const $btnGroup = $(



                  ''<div class="d-flex align-items-center gap-2"></div>'',



                );



                $btnGroup.append($btnAdd);



                $wrap.append($btnGroup);



                return $wrap;



              },



            },



          );



        },



      })



      .dxDataGrid("instance");







    // Shared grid data source registry so detail forms can trigger refreshes



    window.hpaSharedGridDataSources = window.hpaSharedGridDataSources || {};







    if (!window.__hpaTextBoxUnderlineStyleInjected) {



      $("<style>")



        .attr("id", "hpa-textbox-underline-style")



        .text(



          `



                          .dx-texteditor.dx-editor-underlined::after { border-bottom-color: #ddd !important; }



                          .dx-texteditor.dx-editor-underlined.dx-state-focused::after { border-bottom-color: #337ab7 !important; border-bottom-width: 2px !important; }



                          .dx-texteditor.dx-editor-underlined.dx-invalid::after { border-bottom-color: #d9534f !important; border-bottom-width: 2px !important; }



                      `,



        )



        .appendTo("head");



      window.__hpaTextBoxUnderlineStyleInjected = true;



    }



    async function loadDataSourceCommon(



      columnName,



      dataSourceSP,



      onSuccessCallback,



    ) {



      if (!columnName || !dataSourceSP || dataSourceSP.trim() === "") {



        console.warn(



          "[loadDataSourceCommon] Missing columnName or dataSourceSP",



        );



        return;



      }







      const dataSourceKey = "DataSource_" + columnName;



      // S? d?ng format: columnNameDataSourceLoaded d? tuong thï¿½ch v?i code hi?n t?i



      const loadedKey = columnName + "DataSourceLoaded";







      // KiÃ¡Â»Æ’m tra n?u dï¿½ load r?i thï¿½ khï¿½ng load l?i



      if (window[loadedKey] === true) {



        if (typeof onSuccessCallback === "function") {



          onSuccessCallback(window[dataSourceKey] || []);



        }



        return;



      }







      // KiÃ¡Â»Æ’m tra nÃ¡ÂºÂ¿u dang load thï¿½ d?i



      if (window[loadedKey] === "loading") {



        // Ã„ÂÃ¡Â»Â£i mÃ¡Â»â„¢t chÃƒÂºt rÃ¡Â»â€œi thÃ¡Â»Â­ lÃ¡ÂºÂ¡i



        setTimeout(function () {



          loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback);



        }, 100);



        return;



      }







      // Ã„ÂÃƒÂ¡nh dÃ¡ÂºÂ¥u Ã„â€˜ang load d? trÃƒÂ¡nh load trÃƒÂ¹ng lÃ¡ÂºÂ·p



      window[loadedKey] = "loading";







      await AjaxHPAParadiseAsync({



        data: {



          name: dataSourceSP,



          param: ["LoginID", LoginID, "LanguageID", LanguageID],



        },



        success: function (res) {



          const json = typeof res === "string" ? JSON.parse(res) : res;



          window[dataSourceKey] = (json.data && json.data[0]) || [];







          // load trong form bth co combox luon







          window[loadedKey] = true;







          // GÃ¡Â»Âi callback nÃ¡ÂºÂ¿u cÃƒÂ³



          if (typeof onSuccessCallback === "function") {



            onSuccessCallback(window[dataSourceKey]);



          }







          // T? d?ng c?p nh?t control n?u cï¿½ method setDataSource hoÃ¡ÂºÂ·c option



          // ThÃ¡Â»Â­ nhiÃ¡Â»Âu format tÃƒÂªn instance d? tÃ†Â°Ã†Â¡ng thÃƒÂ­ch



          const instanceVariants = [



            "Instance" +



              columnName.charAt(0).toUpperCase() +



              columnName.slice(1) +



              "PED6A4AAAA14F4706822A32B2859DDDAD",



            "Instance" + columnName + "PED6A4AAAA14F4706822A32B2859DDDAD",



            "instance" +



              columnName.charAt(0).toUpperCase() +



              columnName.slice(1) +



              "PED6A4AAAA14F4706822A32B2859DDDAD",



          ];







          for (let i = 0; i < instanceVariants.length; i++) {



            const instanceKey = instanceVariants[i];







            if (window[instanceKey] || instanceKey) {



              const instanceObj = window[instanceKey] || instanceKey;







              // Ki?m tra n?u dï¿½y lï¿½ dxDataGrid



              if (



                typeof instanceObj.dxDataGrid === "function" ||



                (instanceObj.option &&



                  instanceObj.option("dataSource") !== undefined)



              ) {



                try {



                  // N?u lÃƒÂ  Grid, apply dynamic config



                  const gridConfigFn =



                    window[



                      "getGridConfig_" +



                        columnName.charAt(0).toUpperCase() +



                        columnName.slice(1)



                    ];



                  if (typeof gridConfigFn === "function") {



                    const gridConfig = gridConfigFn(window[dataSourceKey]);



                    instanceObj.option(



                      "remoteOperations",



                      gridConfig.remoteOperations,



                    );



                    instanceObj.option("paging.pageSize", gridConfig.pageSize);



                    instanceObj.option(



                      "pager.allowedPageSizes",



                      gridConfig.allowedPageSizes,



                    );



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



          console.error(



            "[loadDataSourceCommon] Failed to load datasource for",



            columnName,



            ":",



            err,



          );



          window[loadedKey] = false;



          if (typeof onSuccessCallback === "function") {



            onSuccessCallback([]);



          }



        },



      });



    }



    let api = true;



    let _pageCache = {};



    let dataStore_GridSubQuotation = null;



    function clearPageCache() {



_pageCache = {};



    }







    function getGridHeight() { return "auto"; }



    function ReloadData() {



      let _currentKeyword = String(



             InstanceQuouteListGridP389C21A8E8BD4889B7C593D29585A11A.option(



              "searchPanel.text",



            ) || "",



      ).trim();



      const arrEmployee =



        InstanceEmployeeIDSelectedEmployeeSub_SubQuotation.option("value") ||



        "";







      dataStore_GridSubQuotation = new DevExpress.data.CustomStore({



        key: "QuoteID",



        load: function (loadOptions) {



          const deferred = $.Deferred();



          if (!api) {



            const results = DataSource || [];



            const skip = loadOptions.skip || 0;



            const take = loadOptions.take || 50;



            const pageData = results.slice(skip, skip + take);



            deferred.resolve({



              data: pageData,



              totalCount: results.length,



            });



            api = true;



            return deferred.promise();



          }







          let params = [];







          // SP nghi?p v?



          params.push("@ProcName", "sp_CRM_SubQuotationList");







          // Tham s? riï¿½ng c?a sp_KPIgetDataCollection



          let procParam = "";







          procParam += `@LoginID=${window.UserID}`;



          procParam += `,@isViewAll=${isViewAll}`;



          procParam += `,@FromDate=${fromDateValue || null}`;



          procParam += `,@ToDate=${toDateValue || null}`;







          let arrEm =



            InstanceEmployeeIDSelectedEmployeeSub_SubQuotation.option("value");



          procParam += `,@arrEmployee=''${arrEm || ""}''`;







          params.push("@ProcParam", procParam);



          // Phï¿½n trang



          params.push("@Take", loadOptions.take || 50);



          params.push("@Skip", loadOptions.skip || 0);







          // TotalCount



          if (loadOptions.requireTotalCount) {



            params.push("@RequireTotalCount", 1);



          }







          // Sort



          const sort = loadOptions.sort



            ? loadOptions.sort



                .map((s) => s.selector + (s.desc ? " DESC" : " ASC"))



                .join(",")



            : "QuoteCode DESC"; // nÃƒÂ y cho mÃ¡ÂºÂ·c Ã„â€˜Ã¡Â»â€¹nh. tÃ¡Â»Â± chÃ¡Â»â€°nh theo menu mÃ¡Â»â€”i ngÃ†Â°Ã¡Â»Âi







          params.push("@Sort", "ORDER BY " + sort);







          // Search







          if (_currentKeyword) {



            params.push("@SearchValue", _currentKeyword);



            params.push(



              "@ColumnSearch",



              "QuoteCode, Company, CustomerID",



            );



          }







          if (loadOptions.filter) {



            // Ki?m tra filter item cï¿½ ph?i function khï¿½ng



            const isJSFunction = (item) => typeof item === "function";



            const hasFunction = JSON.stringify(



              loadOptions.filter,



              (key, val) => {



                if (typeof val === "function") return "FUNCTION";



                return val;



              },



            ).includes("FUNCTION");







            if (!hasFunction) {



              params.push("@Filters", createConditionQuery(loadOptions.filter));



            }



          }











          // Group



          if (loadOptions.group) {



            let selectGroup = "",



              groupBy = "GROUP BY ";



            loadOptions.group.forEach((item, index) => {



              if (selectGroup) selectGroup += ", ";



              if (groupBy !== "GROUP BY ") groupBy += ", ";



              if (item.groupInterval) {



                selectGroup += `${item.groupInterval.toUpperCase()}(${item.selector}) as col${index}`;



                groupBy += `${item.groupInterval.toUpperCase()}(${item.selector})`;



              } else {



                selectGroup += `${item.selector} as col${index}`;



               groupBy += `${item.selector}`;



              }



            });



            selectGroup += `, Count(*) as totalCount`;



            params.push("@SelectGroup", selectGroup);



            params.push("@GroupBy", groupBy);



          }







          // Summary



          if (loadOptions.totalSummary) {



            const summary = loadOptions.totalSummary.map((item) => {



              const type =



                item.summaryType === "custom"



                  ? `count(CASE WHEN [${item.selector}] = 1 THEN 1 END) as ${item.selector}_COUNT`



                  : `${item.summaryType}([${item.selector}]) as ${item.selector}_${item.summaryType.toUpperCase()}`;



              return type;



            });



            params.push("@TotalSummary", summary.join(", "));



          }



          console.log(params)



          AjaxHPAParadise({



            data: {



              name: "sp_LoadGridUsingAPI",



              param: params,



            },



            success: function (res) {



              const json = typeof res === "string" ? JSON.parse(res) : res;



              const results = Array.isArray(json?.data?.[0])



                ? json.data[0]



                : [];







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







              deferred.resolve(result);



            },



            error: function (err) {



              deferred.reject("Data Loading Error");



            },



          });







          return deferred.promise();



        },



      });







      // GÃƒÂ¡n store vÃƒÂ o grid d? kÃƒÂ­ch hoÃ¡ÂºÂ¡t load



      const gridInstance =



        InstanceQuouteListGridP389C21A8E8BD4889B7C593D29585A11A;



      gridInstance.beginUpdate();



      gridInstance.option("remoteOperations", {



        paging: true,



        filtering: true,



        sorting: true,



        searching: true,



      });







      // scroll



      gridInstance.option("scrolling.mode", "infinite");



      gridInstance.option("scrolling.rowRenderingMode", "virtual");



      gridInstance.option("scrolling.preloadEnabled", false);







 gridInstance.option("paging.enabled", true);



      gridInstance.option("paging.pageSize", 50);



      gridInstance.option("pager.visible", false);



      gridInstance.option("pager.allowedPageSizes", [50]);



      gridInstance.option("searchPanel.highlightSearchText", false);



      gridInstance.option("dataSource", dataStore_GridSubQuotation);



      gridInstance.option("height", getGridHeight());



      gridInstance.option("onOptionChanged", function (e) {



        if (e.name === "searchPanel" && e.fullName === "searchPanel.text") {



          const raw = e.value || "";



          let t = String(raw);



          _currentKeyword = t.trim();



          _pageCache = {};



        }



      });



      gridInstance.endUpdate();



    }







    window.GlobalEmployeeAvatarCache = window.GlobalEmployeeAvatarCache || {};



    window.GlobalEmployeeAvatarLoading =



      window.GlobalEmployeeAvatarLoading || {};



    let InstanceEmployeeIDSelectedEmployeeSub_SubQuotation = null;







    function loadGlobalAvatarIfNeededEmployeeIDSelectedEmployeeSub_SubQuotation(



      employeeId,



      storeImgName,



      paramImg,



      callbackFn,



    ) {



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



        callbacks: callbackFn ? [callbackFn] : [],



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



          param: paramArray,



        },



        xhrFields: { responseType: "blob" },



        cache: true,



        success: function (blob) {



          const callbacks =



            window.GlobalEmployeeAvatarLoading[idStr]?.callbacks || [];



          delete window.GlobalEmployeeAvatarLoading[idStr];







          if (blob && blob.size > 0) {



            const url = URL.createObjectURL(blob);



            window.GlobalEmployeeAvatarCache[idStr] = url;







            callbacks.forEach((cb) => {



              try {



                cb(url);



              } catch (e) {



                console.error(e);



              }



            });



          } else {



            callbacks.forEach((cb) => {



              try {



                cb(null);



              } catch (e) {



                console.error(e);



              }



            });



          }



        },



        error: function () {



          const callbacks =



            window.GlobalEmployeeAvatarLoading[idStr]?.callbacks || [];



          delete window.GlobalEmployeeAvatarLoading[idStr];







          callbacks.forEach((cb) => {



            try {



              cb(null);



            } catch (e) {



              console.error(e);



            }



          });



        },



      });







      return null;



    }







    window["DataSource_EmployeeID"] = window["DataSource_EmployeeID"] || [];



    let spNameDSEEmployeeIDSelectedEmployeeSub_SubQuotation =



      "sp_EmployeeListDataMultiSelectSelectBox";



    let EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds = [],



      EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIdsOriginal = [];



    const MAX_VISIBLE_EmployeeIDSelectedEmployeeSub_SubQuotation = 3;



    let _autoSaveEmployeeIDSelectedEmployeeSub_SubQuotation = false;



    let _readOnlyEmployeeIDSelectedEmployeeSub_SubQuotation = false;



    let EmployeeIDSelectedEmployeeSub_SubQuotationIsSaving = false;







    $(document).ready(function () {



      // SÃ¡Â»Â­ dÃ¡Â»Â¥ng hÃƒÂ m loadDataSourceCommon tÃ¡Â»Â« sptblCommonControlType_Signed



      if (



        spNameDSEEmployeeIDSelectedEmployeeSub_SubQuotation &&



        spNameDSEEmployeeIDSelectedEmployeeSub_SubQuotation.trim() !== ""



      ) {



        loadDataSourceCommon(



          "EmployeeIDSelectedEmployeeSub_SubQuotation",



          spNameDSEEmployeeIDSelectedEmployeeSub_SubQuotation,



          function (data) {



            window["DataSource_EmployeeID"] = data || [];



            if (Array.isArray(data) && data.length > 0) {



              data.forEach((emp) => {



                hpaUtils.loadAvatar(emp.ID, emp.StoreImgName, emp.ImgParamV);



              });



            }



            if (



              typeof renderDisplayBoxEmployeeIDSelectedEmployeeSub_SubQuotation ===



              "function"



            ) {



              renderDisplayBoxEmployeeIDSelectedEmployeeSub_SubQuotation();



            }



          },



        );



      }



    });







    function getInitialsEmployeeIDSelectedEmployeeSub_SubQuotation(name) {



      if (!name) return "?";



      const words = name.trim().split(/\s+/);



      if (words.length >= 2)



        return (words[0][0] + words[words.length - 1][0]).toUpperCase();



      return name.substring(0, 2).toUpperCase();



    }







    function getColorForIdEmployeeIDSelectedEmployeeSub_SubQuotation(id) {



      const colors = [



        { bg: "#e3f2fd", text: "#1976d2" },



        { bg: "#f3e5f5", text: "#7b1fa2" },



        { bg: "#e8f5e9", text: "#388e3c" },



        { bg: "#fff3e0", text: "#f57c00" },



        { bg: "#fce4ec", text: "#c2185b" },



      ];



      const numId = parseInt(id, 10);



      const index = isNaN(numId) ? 0 : Math.abs(numId) % colors.length;



      return colors[index];



    }







    function renderDisplayBoxEmployeeIDSelectedEmployeeSub_SubQuotation() {



      const $displayBoxEmployeeIDSelectedEmployeeSub_SubQuotation = $(



        "#EmployeeIDSelectedEmployeeSub_SubQuotation_display",



      );



      if (!$displayBoxEmployeeIDSelectedEmployeeSub_SubQuotation.length) return;



      $displayBoxEmployeeIDSelectedEmployeeSub_SubQuotation.empty();







      const $wrapper = $("<div>")



        .css({



          borderBottom: "1px solid #ddd",



          padding: "0 6px",



          minHeight: "30px",



          display: "flex",



          alignItems: "center",



          cursor: "pointer",



          transition: "border-bottom-color 0.2s",



        })



        .attr("tabIndex", "0")



        .on("keydown", function (e) {



          if (e.key === "Enter" || e.key === " " || e.key === "Spacebar") {



            e.preventDefault();



            if (_readOnlyEmployeeIDSelectedEmployeeSub_SubQuotation) return;



            if (!popupEmployeeIDSelectedEmployeeSub_SubQuotation) {



              initPopupEmployeeIDSelectedEmployeeSub_SubQuotation();



              setTimeout(



                () => popupEmployeeIDSelectedEmployeeSub_SubQuotation.show(),



                0,



              );



            } else {



              popupEmployeeIDSelectedEmployeeSub_SubQuotation.show();



            }



          }



        })



        .on("focus", function () {



          $wrapper.css({ borderBottom: "2px solid #337ab7", outline: "none" });



        })



        .on("blur", function () {



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



          },



        );







      if (EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds.length === 0) {



        $wrapper.append(



          $("<span>")



            .addClass("text-muted")



            .html(''<i class="bi bi-person-plus me-2"></i>Chọn nhân viên...''),



        );



      } else {



        const displayIds =



          EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds.slice(



            0,



            MAX_VISIBLE_EmployeeIDSelectedEmployeeSub_SubQuotation,



          );



        const $group = $("<div>").css({





          display: "flex",



          alignItems: "center",



        });







        displayIds.forEach((id, index) => {







          const item = window["DataSource_EmployeeID"].find(



            (e) => String(e.ID) === String(id),



          );



          if (!item) return;







          const $chip = $("<div>")



            .css({



              width: "36px",



              height: "36px",



              borderRadius: "50%",



              border: "3px solid #fff",



              boxShadow: "0 2px 6px rgba(0,0,0,0.15)",



              marginLeft: index === 0 ? "0" : "-10px",



              zIndex: index + 1,



              display: "flex",



              alignItems: "center",



              justifyContent: "center",



              fontWeight: "600",



              fontSize: "13px",



              position: "relative",



              overflow: "hidden",



            })



            .attr("title", item.Name || item.FullName || "");







          const cachedUrl = window.GlobalEmployeeAvatarCache[String(id)];







          if (cachedUrl) {



            $chip.append(



              $("<img>")



                .attr("src", cachedUrl)



                .css({ width: "100%", height: "auto", objectFit: "cover" }),



            );



          } else if (item.storeImgName) {



            loadGlobalAvatarIfNeededEmployeeIDSelectedEmployeeSub_SubQuotation(



              id,



              item.storeImgName,



              item.paramImg,



              function (url) {



                if (url)



                  renderDisplayBoxEmployeeIDSelectedEmployeeSub_SubQuotation();



              },



            );



            const color =



              getColorForIdEmployeeIDSelectedEmployeeSub_SubQuotation(id);



            const initials =



              getInitialsEmployeeIDSelectedEmployeeSub_SubQuotation(



                item.Name || item.FullName,



              );



            $chip



              .css({ background: color.bg, color: color.text })



              .text(initials);



          } else {



            const color =



              getColorForIdEmployeeIDSelectedEmployeeSub_SubQuotation(id);



            const initials =



              getInitialsEmployeeIDSelectedEmployeeSub_SubQuotation(



                item.Name || item.FullName,



              );



            $chip



              .css({ background: color.bg, color: color.text })



              .text(initials);



          }







          $group.append($chip);



        });







        if (



          EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds.length >



          MAX_VISIBLE_EmployeeIDSelectedEmployeeSub_SubQuotation



        ) {



          const remaining =



            EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds.length -



            MAX_VISIBLE_EmployeeIDSelectedEmployeeSub_SubQuotation;



          $group.append(



            $("<div>")



              .css({



                width: "36px",



                height: "36px",



                borderRadius: "50%",



                border: "3px solid #fff",



                marginLeft: "-10px",



                zIndex:



                  MAX_VISIBLE_EmployeeIDSelectedEmployeeSub_SubQuotation + 1,



                display: "flex",



                alignItems: "center",



                justifyContent: "center",



                fontWeight: "700",



                fontSize: "12px",



              })



              .text("+" + remaining)



              .attr("title", "Còn " + remaining + " người nữa"),



          );



        }







        $wrapper.append($group);



      }







      $displayBoxEmployeeIDSelectedEmployeeSub_SubQuotation.append($wrapper);



      $wrapper.off("click").on("click", () => {



        if (_readOnlyEmployeeIDSelectedEmployeeSub_SubQuotation) {



          if (typeof uiManager !== "undefined" && uiManager.showAlert) {



            uiManager.showAlert({



              type: "info",



              message: "This field is read-only.",



            });



          } else {



            alert("This field is read-only.");



          }



          return;



        }



        if (!popupEmployeeIDSelectedEmployeeSub_SubQuotation) {



          initPopupEmployeeIDSelectedEmployeeSub_SubQuotation();



          setTimeout(() => {



            popupEmployeeIDSelectedEmployeeSub_SubQuotation.show();



          }, 0);



        } else {



          popupEmployeeIDSelectedEmployeeSub_SubQuotation.show();



        }



      });



    }







    const $containerEmployeeIDSelectedEmployeeSub_SubQuotation = $(



      "#SelectedEmployeeSub_SubQuotation",



    );



    $containerEmployeeIDSelectedEmployeeSub_SubQuotation.empty();



    const $displayBoxEmployeeIDSelectedEmployeeSub_SubQuotation = $(



      "<div>",



    ).attr("id", "EmployeeIDSelectedEmployeeSub_SubQuotation_display");



    $containerEmployeeIDSelectedEmployeeSub_SubQuotation.append(



      $displayBoxEmployeeIDSelectedEmployeeSub_SubQuotation,



    );







    let popupEmployeeIDSelectedEmployeeSub_SubQuotation;



    let popupEmployeeIDSelectedEmployeeSub_SubQuotationOnce = false;



    let EmployeeIDSelectedEmployeeSub_SubQuotationGridContainer = null;







    function initPopupEmployeeIDSelectedEmployeeSub_SubQuotation() {



      if (popupEmployeeIDSelectedEmployeeSub_SubQuotationOnce) {



        popupEmployeeIDSelectedEmployeeSub_SubQuotation.show();



        return;



      }







      // FIXED: DÃ¡Â»Ân dÃ¡ÂºÂ¹p DOM rÃƒÂ¡c



      $("#EmployeeIDSelectedEmployeeSub_SubQuotation_popup").remove();







      popupEmployeeIDSelectedEmployeeSub_SubQuotationOnce = true;



      popupEmployeeIDSelectedEmployeeSub_SubQuotation = $("<div>")



        .attr("id", "EmployeeIDSelectedEmployeeSub_SubQuotation_popup")



        .appendTo(document.body)



        .addClass("hpa-responsive")



        .dxPopup({



          width: () => (window.innerWidth < 768 ? "95vw" : 750),



          maxHeight: "90vh",



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



              location: "before",



              toolbar: "bottom",



              options: {



                text: "Xóa chọn",



                type: "danger",



                stylingMode: "outlined",



                onClick: () => {



                  EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds = [];



                  try {



                    EmployeeIDSelectedEmployeeSub_SubQuotationGridContainer.dxDataGrid(



                      "instance",



                    ).deselectAll();



                  } catch (e) {}



                },



              },



            },



            {



              widget: "dxButton",



              location: "after",



              toolbar: "bottom",



              options: {



                text: "Hủy",



                onClick: () => {



                  EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds = [



                    ...EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIdsOriginal,



                  ];



                  popupEmployeeIDSelectedEmployeeSub_SubQuotation.hide();



                },



              },



            },



            {



              widget: "dxButton",



              location: "after",



              toolbar: "bottom",



              options: {



                text: "Lưu",



                type: "success",



                onClick: async () => {



                  if (



   _autoSaveEmployeeIDSelectedEmployeeSub_SubQuotation &&



                    typeof saveValueEmployeeIDSelectedEmployeeSub_SubQuotation ===



                      "function"



                  ) {



                    await saveValueEmployeeIDSelectedEmployeeSub_SubQuotation();



                  } else {



                    // Local Save (Sync Grid)



                    if (



                      typeof cellInfo !== "undefined" &&



                      cellInfo &&



                      cellInfo.component



                    ) {



                      try {



                        const grid = cellInfo.component;



                        const newValue =



                          EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds.join(



                            ",",



                          );



                        grid.cellValue(



                          cellInfo.rowIndex,



                          "EmployeeID",



                          newValue || null,



                        );



                        grid.repaint();



                      } catch (e) {



                        console.warn(e);



                      }



                    }



                    EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIdsOriginal =



                      [



                        ...EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds,



       ];



                    renderDisplayBoxEmployeeIDSelectedEmployeeSub_SubQuotation();



                  }



              popupEmployeeIDSelectedEmployeeSub_SubQuotation.hide();



                },



              },



            },



          ],



          contentTemplate: function (contentElement) {



            EmployeeIDSelectedEmployeeSub_SubQuotationGridContainer =



              $("<div>");



            contentElement.append(



              EmployeeIDSelectedEmployeeSub_SubQuotationGridContainer,



            );



          },



          onShown: () => {



            const sortedData = window["DataSource_EmployeeID"].sort((a, b) => {



              const aSelected =



                EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds.includes(



                  String(a.ID),



                );



              const bSelected =



                EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds.includes(



                  String(b.ID),



                );



              return bSelected - aSelected;



            });







            try {



              const existingInstance =



                EmployeeIDSelectedEmployeeSub_SubQuotationGridContainer.dxDataGrid(



                  "instance",



                );



              if (existingInstance) {



                existingInstance.dispose();



              }



            } catch (e) {



              // Instance chÃ†Â°a tÃ¡Â»â€œn tÃ¡ÂºÂ¡i hoÃ¡ÂºÂ·c Ã„â€˜ÃƒÂ£ bÃ¡Â»â€¹ destroy



            }







            EmployeeIDSelectedEmployeeSub_SubQuotationGridContainer.empty().dxDataGrid(



              {



                dataSource: sortedData,



                keyExpr: "ID",



                remoteOperations: false,



                columnAutoWidth: true,



                allowColumnResizing: true,



                selection: { mode: "multiple", showCheckBoxesMode: "always" },



                selectedRowKeys:



                  EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds,



                focusStateEnabled: true,



                keyboardNavigation: { enabled: true },



                hoverStateEnabled: true,



                columns: [



                  {



                    caption: "Ảnh",



                    width: 70,



                    alignment: "center",



                    cellTemplate: function (container, options) {



                      const item = options.data;



                      const $cell = $("<div>").css({



                        display: "flex",



                        justifyContent: "center",



                        alignItems: "center",



                        height: "auto",







                      });







                      const cachedUrl =



                        window.GlobalEmployeeAvatarCache[String(item.ID)];







                      if (cachedUrl) {



                        $cell.append(



                          $("<img>").attr("src", cachedUrl).css({



                            width: "30px",



                            height: "30px",



                            borderRadius: "50%",



                            objectFit: "cover",



                            border: "2px solid #fff",



                            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",



                          }),



                        );



                      } else if (item.storeImgName) {



                        loadGlobalAvatarIfNeededEmployeeIDSelectedEmployeeSub_SubQuotation(



                          item.ID,



                          item.storeImgName,



                          item.paramImg,



                          function (url) {



                            if (!url) return;



                            $cell.empty().append(



                              $("<img>").attr("src", url).css({



                                width: "30px",



                                height: "30px",



                                borderRadius: "50%",



                                objectFit: "cover",



                                border: "2px solid #fff",



                                boxShadow: "0 2px 4px rgba(0,0,0,0.1)",



                              }),



                           );



                          },



                        );







                        const initials =



                          getInitialsEmployeeIDSelectedEmployeeSub_SubQuotation(



                            item.Name || item.FullName || "?",



                          );



                        const color =



                          getColorForIdEmployeeIDSelectedEmployeeSub_SubQuotation(



                            item.ID,



                          );



                        $cell.append(



                          $("<div>").text(initials).css({



                            width: "30px",



                            height: "30px",



                            borderRadius: "50%",



                            background: color.bg,



                            color: color.text,



                            display: "flex",



                            justifyContent: "center",



                            alignItems: "center",



                            fontWeight: "600",



                            fontSize: "14px",



                            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",



                          }),



                        );



                      } else {



                        const initials =



                          getInitialsEmployeeIDSelectedEmployeeSub_SubQuotation(



                            item.Name || item.FullName || "?",



                          );



                        const color =



                          getColorForIdEmployeeIDSelectedEmployeeSub_SubQuotation(



                            item.ID,



                          );



                        $cell.append(



                          $("<div>").text(initials).css({



                            width: "30px",



                            height: "30px",



                            borderRadius: "50%",



                            background: color.bg,



                            color: color.text,



                            display: "flex",



                            justifyContent: "center",



                            alignItems: "center",



   fontWeight: "600",



                            fontSize: "14px",



                            boxShadow: "0 2px 4px rgba(0,0,0,0.1)",



                          }),



                        );



                      }







                      container.append($cell);



                    },



                  },







                  { dataField: "Name", caption: "Họ tên" },



                  { dataField: "Email", caption: "Email", hidingPriority: 0 },



                  {



                    dataField: "Position",



                    caption: "Chức vụ",



                    hidingPriority: 1,



                  },



                ],



                searchPanel: {



                  visible: true,



                  placeholder: "",



                },



                onContentReady: function (e) {



                  const grid = e.component;



                  const searchBox = grid



                    .getView("headerPanel")



                    ._$element.find(".dx-datagrid-search-panel input");







                  if (!searchBox.length) return;







                  // ChÃ¡Â»â€° bind 1 lÃ¡ÂºÂ§n, trÃƒÂ¡nh re-bind sau mÃ¡Â»â€”i lÃ¡ÂºÂ§n filter re-render



                  if (searchBox.data("hpa-search-bound")) return;



                  searchBox.data("hpa-search-bound", true);







                  if (



                    !$(



                      "#custom-search-style-EmployeeIDSelectedEmployeeSub_SubQuotation",



                    ).length



                  ) {



                    $("<style>")



                      .attr(



                        "id",



                        "custom-search-style-EmployeeIDSelectedEmployeeSub_SubQuotation",



                      )



                      .text(



                        `



													.dx-datagrid-search-panel input:not(:placeholder-shown) {



														color: #000 !important;



													}



													.dx-datagrid-search-panel input::placeholder {



														color: #999 !important;



														opacity: 1 !important;



													}



												`,



                      )



                      .appendTo("head");



                  }







                  searchBox.off("input keyup change");







                  searchBox.on("input", function () {



                    const $self = $(this);



                    const searchValue = $self.val();







                    if (!searchValue) {



                      grid.clearFilter();



                      // Restore focus sau clearFilter



                      setTimeout(() => $self.focus(), 0);



                      return;



                    }







                    const searchNormalized = RemoveToneMarks_Js(searchValue);



                    grid.filter(function (item) {



                      const fields = ["Name", "Email", "Position"];



                      for (let i = 0; i < fields.length; i++) {



                        const fieldValue = item[fields[i]];



                        if (



                          fieldValue &&



                          RemoveToneMarks_Js(String(fieldValue)).indexOf(



                            searchNormalized,



                          ) !== -1



                        ) {



                          return true;



                        }



                      }



                      return false;



                    });







                    // Restore focus sau filter (grid re-render khÃƒÂ´ng cÃ†Â°Ã¡Â»â€ºp focus)



                    setTimeout(() => $self.focus(), 0);



                  });



                },



                paging: {



                  enabled: true,



                  pageSize: 5,



                  pageIndex: 0,



                },



                pager: {



                  visible: true,



                  allowedPageSizes: [5, 10],





                  showPageSizeSelector: true,



                  showInfo: true,



                  showNavigationButtons: true,



                },



                onSelectionChanged: (e) =>



                  (EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds =



                    e.selectedRowKeys || []),



              },



            );



          },



          onHidden: () => {



            // FIXED: KHÃƒâ€NG dispose grid tÃ¡ÂºÂ¡i Ã„â€˜ÃƒÂ¢y



            // Reset position cÃ¡Â»Â§a popup vÃ¡Â»Â default



            popupEmployeeIDSelectedEmployeeSub_SubQuotation.option("position", {



              my: "center",



              at: "center",



              of: window,



            });







            renderDisplayBoxEmployeeIDSelectedEmployeeSub_SubQuotation();



          },



        })



        .dxPopup("instance");



    }







    async function saveValueEmployeeIDSelectedEmployeeSub_SubQuotation() {



      if (_readOnlyEmployeeIDSelectedEmployeeSub_SubQuotation) {



        if (typeof uiManager !== "undefined" && uiManager.showAlert) {



          uiManager.showAlert({



            type: "info",



            message: "This field is read-only.",



          });



        } else {



          alert("This field is read-only.");



        }



        return;



      }







      const original =



        EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIdsOriginal.slice()



          .sort()



          .join(",");



      const current =



        EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds.slice()



          .sort()



          .join(",");



      if (



        original === current ||



        EmployeeIDSelectedEmployeeSub_SubQuotationIsSaving



      )



        return;







      EmployeeIDSelectedEmployeeSub_SubQuotationIsSaving = true;



      try {



        const newValue =



          EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds.join(",");



        const dataJSON = JSON.stringify([



          "-99218308",



["EmployeeID"],



          [newValue || null],



        ]);







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



          uiManager.showAlert({



            type: "error",



            message: errors[0].Message || "%SaveErrorMessage%",



          });



          return;



        }







        // SYNC GRID



        if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {



          try {



            const grid = cellInfo.component;



            grid.cellValue(cellInfo.rowIndex, "EmployeeID", newValue);



            grid.repaint();



          } catch (syncErr) {



            console.warn(



              "[Grid Sync] SelectEmployee EmployeeIDSelectedEmployeeSub_SubQuotation: KhÃƒÂ´ng thÃ¡Â»Æ’ sync grid:",



              syncErr,



            );



          }



        }







        EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIdsOriginal = [



          ...EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds,



        ];



        renderDisplayBoxEmployeeIDSelectedEmployeeSub_SubQuotation();



      } catch (err) {



        uiManager.showAlert({ type: "error", message: "%SaveErrorMessage%" });



      } finally {



        EmployeeIDSelectedEmployeeSub_SubQuotationIsSaving = false;



      }



    }







    InstanceEmployeeIDSelectedEmployeeSub_SubQuotation = {



      setValue: function (val) {



        if (typeof val === "string" && val.trim()) {



          EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds = val



            .split(",")



            .map((v) => v.trim())



            .filter((v) => v);



        } else if (Array.isArray(val)) {



          EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds =



            val.map(String);



        } else {



          EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds = [];



        }



        EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIdsOriginal = [



          ...EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds,



        ];



        renderDisplayBoxEmployeeIDSelectedEmployeeSub_SubQuotation();



      },



      getValue: () => EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds,



      getValueAsString: () =>



        EmployeeIDSelectedEmployeeSub_SubQuotationSelectedIds.join(","),



      setDataSource: (data) => {



        window["DataSource_EmployeeID"] = data || [];



      },



      repaint: renderDisplayBoxEmployeeIDSelectedEmployeeSub_SubQuotation,



      _readOnly: false,



      _autoSave: false,



      option: function (name, value) {



        if (arguments.length === 2) {



          if (name === "value") this.setValue(value);



          if (name === "readOnly") {



            this._readOnly = value;



            _readOnlyEmployeeIDSelectedEmployeeSub_SubQuotation = value;



            const $displayBox = $(



              "#EmployeeIDSelectedEmployeeSub_SubQuotation_display",



            );



            if (value)



              $displayBox.addClass("disabled-control").css("opacity", "0.6");



            else



              $displayBox.removeClass("disabled-control").css("opacity", "1");



          }



          if (name === "autoSave") {



            this._autoSave = value;



            _autoSaveEmployeeIDSelectedEmployeeSub_SubQuotation = value;



          }



        } else if (arguments.length === 1) {



          if (name === "value") return this.getValueAsString();



          if (name === "dataSource") return window["DataSource_EmployeeID"];



          if (name === "readOnly")



            return _readOnlyEmployeeIDSelectedEmployeeSub_SubQuotation;



          if (name === "autoSave")



            return _autoSaveEmployeeIDSelectedEmployeeSub_SubQuotation;



        }



        return undefined;



      },



      _suppressValueChangeAction: function () {},



      _resumeValueChangeAction: function () {},



    };







    setTimeout(() => {



      var employeeFilterWrapper = document.getElementById(



        "multilselectedEmployeebtnSubQuotation",



      );



      if (



        employeeFilterWrapper &&



        employeeFilterWrapper.children.length === 0



      ) {



        var originalEmployee = document.getElementById(



          "SelectedEmployeeSub_SubQuotation",



        );



        if (originalEmployee && originalEmployee.parentElement) {



          var employeeDiv = originalEmployee.parentElement.querySelector("div");



          if (employeeDiv) {



            employeeFilterWrapper.appendChild(employeeDiv);



          }



        }



      }



    }, 300);







     async function exportSubQuoute(QuoteID) {



        showLoadingByClassOrID("#QuouteListGrid", "Xuất dữ liệu");



        //console.log(arg);



        let exportItem = {



          item: "ExportQuoteExcel",



          query: "sp_Sub_ExportQuote_Excel",



          fileName: "exportExcelQuote.xlsx",



        };



        let ExportName = exportItem.item;







        try {



          if (!exportItem.fileName) {



            let exportTemp = await AjaxHPAParadiseAsync({



              data: {



                name: exportItem.item,



                param: ["@QuoteID", QuoteID],



              },



              success: function (resultData) {},



            });







            exportTemp =



              typeof exportTemp === "string" ? JSON.parse(exportTemp) : exportTemp;



            ExportName =



              exportTemp.data[0][0][



                Object.keys(exportTemp.data[0][0]).find(



                  (x) => x.toLowerCase() == "exportname",



                )



              ] ?? ExportName;



          }







          let resultData = await AjaxHPAParadiseParadiseAsync({



            data: {



              //name: "ExportLocationFolderSaveAsFileAsync",



              name: "ExportLocationFolder",



              param: ["", ExportName, exportItem.fileName, "@QuoteID", QuoteID],



            },



            success: function (resultData) {},



            error: function (xhr, status, error) {},



          });







          let jsonData =



            typeof resultData === "string" ? JSON.parse(resultData) : resultData;







          if (jsonData.result == "error")



            throw new Error(jsonData.reason ?? "Lỗi bất thường");



          //console.log(resultData)



          if (jsonData) {



            if (



              ParadiseOption &&



              ParadiseOption.AppInfoPackageName ==



                "com.vietinsoft.onshiftparadisehr"



            ) {



              AjaxHPAParadiseParadise({



                data: {



                  name: "MobileOpenFileAsync",



                  param: [jsonData.FilePath, exportItem.fileName],



                },



                success: function (resultData) {},



                error: function (xhr, status, error) {},



              });



            } else {



              jsonData =



                typeof jsonData.data === "string"



                  ? JSON.parse(jsonData.data)



                  : jsonData.data;







              AjaxHPAParadiseParadise({



                data: {



                  name: "ReadPathFileToByte",



                  param: [jsonData.FilePath],



                },



                success: function (result) {



                  let resultData =



                    typeof result === "string" ? JSON.parse(result) : result;



                  saveAsFile(jsonData.FileName, resultData.data);



                },



                error: function (xhr, status, error) {},



              });



            }



      }







          HideLoadingByClassOrID("#QuouteListGrid");



        } catch (error) {



          HideLoadingByClassOrID("#QuouteListGrid");



          let direction = "up-push";



          let position = "bottom right";







          try {



            let reason = JSON.parse(jsonData.reason);



            reason = Array.isArray(reason) ? reason[0] : reason;



            jsonData.reason = reason.ErrorDetail;



          } catch (jsonError) {}







          let message =



            jsonData.result == "error" && jsonData.reason



              ? jsonData.reason



              : error.message;







          DevExpress.ui.notify(



            {



              message: message,



              type: "error",



              displayTime: 2500,



            },



            {



              position,



              direction,



            },



          );



        }



      }



    ReloadData();







  })();



</script>



'







    select @html



    --sp_GenerateHTMLScript_new 'sp_Sub_SubQuotation_html'



