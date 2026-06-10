IF OBJECT_ID('sp_CRM_SaleInCRM_html') IS NOT NULL
    DROP PROCEDURE sp_CRM_SaleInCRM_html
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_CRM_SaleInCRM_html]
    @LoginID INT = null,
    @LanguageID VARCHAR(2) = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @html NVARCHAR(MAX);
    SET @html = N'
    <div id="sp_CRM_SaleInCRM_Premium" class="crm-container-ttv">
        <!-- ── TOOLBAR TOP ── -->
        <div class="ttv-toolbar-top d-flex align-items-center gap-2 flex-wrap">
            <div id="filter-group-main" class="d-flex align-items-center gap-2 flex-wrap">
                <div class="ttv-switcher-container time-switcher" id="time-range-pills">
                    <button class="ttv-pill" data-range="week">%CRM_Week%</button>
                    <button class="ttv-pill active" data-range="month">%CRM_Month%</button>
                    <button class="ttv-pill" data-range="quarter">%CRM_Quarter%</button>
                    <button class="ttv-pill" data-range="year">%CRM_Year%</button>
                    <div class="ttv-pill-slider"></div>
                </div>
                <div style="width:1px; height:24px; background:var(--bs-border-color); flex-shrink:0;"></div>
                <select id="filter-year" class="ttv-input-control" style="width:80px;"></select>
                <select id="filter-month" class="ttv-input-control" style="width:95px;"></select>
                <select id="filter-week" class="ttv-input-control" style="display:none; width:85px;"></select>
                <select id="filter-quarter" class="ttv-input-control" style="display:none; width:90px;"></select>
                <div class="d-flex align-items-center gap-2 ms-2">
                    <span class="filter-lbl-ttv">%CRM_From%</span>
                    <div id="filter-date-from" class="dx-date-custom" style="width: 155px;"></div>
                    <span class="text-muted">–</span>
                    <span class="filter-lbl-ttv">%CRM_To%</span>
                    <div id="filter-date-to" class="dx-date-custom" style="width: 155px;"></div>
                </div>
            </div>
            <div class="flex-grow-1"></div>
            <div id="list-date-range-display" class="small fw-bold opacity-50 me-3" style="text-transform: uppercase; letter-spacing: 0.5px;"></div>
            <button class="btn-ttv-action-icon" id="btn-reload-main" title="%CRM_Reload%"><i class="fas fa-sync-alt"></i></button>
        </div>

        <div id="pdf-loading" class="pdf-loading-overlay">
            <div class="pdf-loading-card">
                <div class="skeleton-pdf-preview mb-3">
                    <div class="skeleton-ttv mb-2" style="width: 60%; height: 20px; margin: 0 auto;"></div>
                    <div class="skeleton-ttv mb-4" style="width: 40%; height: 12px; margin: 0 auto; opacity: 0.5;"></div>
                    <div class="row g-2 mb-3">
                        <div class="col-4"><div class="skeleton-ttv" style="height: 40px;"></div></div>
                        <div class="col-4"><div class="skeleton-ttv" style="height: 40px;"></div></div>
                        <div class="col-4"><div class="skeleton-ttv" style="height: 40px;"></div></div>
                    </div>
                    <div class="skeleton-ttv" style="height: 80px; width: 100%;"></div>
                </div>
                <div class="fw-bold fs-5 mb-1" style="color: var(--paradise-color-header1);">%CRM_PDFLoading%</div>
                <div class="small opacity-50">%CRM_PDFWait%</div>
            </div>
        </div>
        <div class="crm-content-ttv">
            <div id="crm-list-view" class="h-100 flex-column d-flex">
                <!-- Overview Stats Grid -->
                <div class="row g-3 mb-4 flex-shrink-0">
                    <div class="col-6 col-sm-4 col-lg-2">
                        <div class="metric-card shadow-sm border-0" style="background: rgba(var(--bs-primary-rgb), 0.05);">
                            <div class="metric-label">%CRM_TotalRevenue%</div>
                            <div id="sum-total-revenue" class="metric-value text-primary" style="font-size: 20px;">0</div>
                        </div>
                    </div>
                    <div class="col-6 col-sm-4 col-lg-2">
                        <div class="metric-card shadow-sm border-0" style="background: rgba(var(--bs-danger-rgb), 0.05);">
                            <div class="metric-label">%CRM_Outstanding%</div>
                            <div id="sum-total-unpaid" class="metric-value text-danger" style="font-size: 20px;">0</div>
                        </div>
                    </div>
                    <div class="col-6 col-sm-4 col-lg-2">
                        <div class="metric-card shadow-sm border-0" style="background: rgba(var(--bs-success-rgb), 0.05);">
                            <div class="metric-label">%CRM_Paid%</div>
                            <div id="sum-total-paid" class="metric-value text-success" style="font-size: 20px;">0</div>
                        </div>
                    </div>
                    <div class="col-6 col-sm-4 col-lg-2">
                        <div class="metric-card shadow-sm border-0" style="background: rgba(var(--bs-info-rgb), 0.05);">
                            <div class="metric-label">%CRM_FinalizedRev%</div>
                            <div id="sum-finalized-revenue" class="metric-value text-info" style="font-size: 20px;">0</div>
                        </div>
                    </div>
                    <div class="col-6 col-sm-4 col-lg-2">
                        <div class="metric-card shadow-sm border-0" style="background: rgba(139, 92, 246, 0.05);">
                            <div class="metric-label">%CRM_EstCommission%</div>
                            <div id="sum-total-commission" class="metric-value" style="font-size: 20px; color: #8b5cf6;">0</div>
                        </div>
                    </div>
                    <div class="col-6 col-sm-4 col-lg-2">
                        <div class="metric-card shadow-sm border-0" style="background: rgba(var(--bs-emphasis-color-rgb), 0.05);">
                            <div class="metric-label">%CRM_TotalContracts%</div>
                            <div id="sum-total-contracts" class="metric-value" style="color:var(--bs-emphasis-color); font-size: 20px;">0</div>
                        </div>
                    </div>
                </div>

                <div class="ttv-grid-wrap shadow-sm">
                    <div class="ttv-grid-header">
                        <div style="flex: 2;">%CRM_Employee%</div>
                        <div class="text-end" style="flex: 1;">%CRM_Revenue%</div>
                        <div class="text-end" style="flex: 1;">%CRM_Receivable%</div>
                        <div class="text-end" style="flex: 1;">%CRM_Collected%</div>
                        <div class="text-end" style="flex: 1;">%CRM_Finalized%</div>
                        <div class="text-end" style="flex: 1;">%CRM_Commission%</div>
                    </div>
                    <div id="crm-body-list" class="ttv-grid-body"></div>
                </div>
            </div>
            
            <div id="crm-dash-view" class="h-100 d-none flex-column p-3">
                <!-- Header Detail -->
                <div class="d-flex align-items-center gap-3 mb-4">
                    <div id="dash-avatar-container" class="rounded-circle shadow-sm" style="width: 64px; height: 64px; border: 3px solid #fff; overflow: hidden; background-color: #eee; background-size: cover; background-position: center; flex-shrink: 0;"></div>
                    <div>
                        <h4 class="fw-bold mb-0" id="dash-emp-name"></h4>
                        <div class="small opacity-50 fw-bold">%CRM_PerfAnalysis%</div>
                    </div>
                    <div class="flex-grow-1 d-flex flex-column align-items-center justify-content-center d-none d-md-flex">
                        <div class="dash-period-header" id="dash-time-summary-text">%CRM_ReportTitle%</div>
                        <div class="dash-period-sub" id="dash-time-range-text">01/01/2024 - 31/12/2024</div>
                    </div>
                    <div class="ms-auto d-flex align-items-center gap-2 d-print-none">
                         <button class="btn-ttv-action-icon" id="btn-export-pdf" title="%CRM_ExportPDF%" style="color:#e11d48"><i class="fas fa-file-pdf"></i></button>
                         <button class="btn-ttv-action-icon" id="btn-reload-detail" title="%CRM_Reload%"><i class="fas fa-sync-alt"></i></button>
                         <button class="btn btn-outline-secondary btn-sm rounded-pill px-3 fw-bold" id="btn-back-detail-new">
                            <i class="fas fa-chevron-left me-1"></i> %CRM_Back%
                         </button>
                    </div>
                </div>

                <!-- Row 1: Image-style Metric Cards -->
                <div class="row g-3 mb-4">
                    <div class="col-6 col-sm-4 col-lg-2">
                        <div class="metric-card shadow-sm">
                            <div class="metric-label">%CRM_TotalRevenue%</div>
                            <div id="stat-revenue" class="metric-value text-primary" style="font-size: 20px;">0</div>
                        </div>
                    </div>
                    <div class="col-6 col-sm-4 col-lg-2">
                        <div class="metric-card shadow-sm">
                            <div class="metric-label">%CRM_Outstanding%</div>
                            <div id="stat-unpaid" class="metric-value text-danger" style="font-size: 20px;">0</div>
                        </div>
                    </div>
                    <div class="col-6 col-sm-4 col-lg-2">
                        <div class="metric-card shadow-sm">
                            <div class="metric-label">%CRM_Paid%</div>
                            <div id="stat-paid" class="metric-value text-success" style="font-size: 20px;">0</div>
                        </div>
                    </div>
                    <div class="col-6 col-sm-4 col-lg-2">
                        <div class="metric-card shadow-sm">
                            <div class="metric-label">%CRM_FinalizedRev%</div>
                            <div id="stat-finalized" class="metric-value text-info" style="font-size: 20px;">0</div>
                        </div>
                    </div>
                    <div class="col-6 col-sm-4 col-lg-2">
                        <div class="metric-card shadow-sm">
                            <div class="metric-label">%CRM_EstCommission%</div>
                            <div id="stat-commission" class="metric-value" style="font-size: 20px; color: #8b5cf6;">0</div>
                        </div>
                    </div>
                    <div class="col-6 col-sm-4 col-lg-2">
                        <div class="metric-card shadow-sm">
                            <div class="metric-label">%CRM_TotalContracts%</div>
                            <div id="stat-count" class="metric-value" style="color:var(--bs-emphasis-color); font-size: 20px;">0</div>
                        </div>
                    </div>
                </div>

                <!-- Row 2: Trend Chart -->
                <div class="row g-4 mb-4">
                    <div class="col-md-8">
                        <div class="dash-card h-100 shadow-sm">
                             <div class="d-flex align-items-center justify-content-between mb-4">
                                <h6 class="fw-bold mb-0">%CRM_TrendTitle%</h6>
                                <div class="small text-muted">%CRM_TrendSub%</div>
                             </div>
                             <!-- Chart layout: Y-labels | Canvas / X-labels bên ngoài canvas -->
                             <div style="height:270px; display:flex;">
                                 <div id="chart-y-axis-html" style="width:95px; position:relative; flex-shrink:0; pointer-events:none;"></div>
                                 <div style="flex:1; position:relative;">
                                     <canvas id="chart-revenue-trend" style="position:absolute; top:0; left:0; width:100%; height:100%;"></canvas>
                                 </div>
                             </div>
                             <div id="chart-x-axis-html" style="position:relative; margin-left:95px; height:22px; pointer-events:none;"></div>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <div class="dash-card h-100 shadow-sm">
                            <h6 class="fw-bold mb-4">%CRM_CollectRatio%</h6>
                            <div class="position-relative d-flex align-items-center justify-content-center" style="height: 220px;">
                                <canvas id="chart-payment-donut" style="position:absolute; top:0; left:0; width:100%; height:100%;"></canvas>
                                <div id="chart-percent" style="font-size:22px; font-weight: 800; color: var(--bs-body-color); z-index: 2; pointer-events: none;">0%</div>
                            </div>
                            <div class="mt-4" id="chart-custom-legend"></div>
                        </div>
                    </div>
                </div>

                <!-- Row 3: Breakdown Table -->
                <div class="dash-card shadow-sm mb-4">
                    <h6 class="fw-bold mb-4">%CRM_BreakdownTitle%</h6>
                    <div id="dash-contract-type-list" class="custom-scrollbar">
                        <div class="p-3">
                            <div class="skeleton-ttv mb-3" style="height: 60px; width: 100%; border-radius: 12px;"></div>
                            <div class="skeleton-ttv mb-3" style="height: 60px; width: 100%; border-radius: 12px;"></div>
                            <div class="skeleton-ttv mb-3" style="height: 60px; width: 100%; border-radius: 12px;"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js">
        // --- Bắt đầu cấu hình Responsive (Tự động thêm vào) ---
        setTimeout(function() {
            var gridElements = document.querySelectorAll(".dx-datagrid");
            gridElements.forEach(function(el) {
                var instance = $(el).dxDataGrid("instance");
                if (instance) {
                    instance.beginUpdate();
                    instance.option("columnAutoWidth", true);
                    instance.option("allowColumnResizing", true);
                    instance.option("columnResizingMode", "widget");
                    instance.option("columnHidingEnabled", false);
                    instance.option("scrolling.useNative", false);
                    instance.option("scrolling.scrollByContent", true);
                    instance.option("scrolling.scrollByThumb", true);
                    instance.option("scrolling.showScrollbar", "always");
                    instance.endUpdate();
                }
            });
        }, 1000);
        // --- Kết thúc cấu hình Responsive ---

</script>
    <script src="https://cdn.jsdelivr.net/npm/chartjs-plugin-datalabels@2.0.0"></script>
    <style>
        #sp_CRM_SaleInCRM_Premium { height: 100vh; display: flex; flex-direction: column; background: var(--bs-body-bg); font-family: ''Inter'', sans-serif; overflow: hidden !important; }
        #sp_CRM_SaleInCRM_Premium .ttv-toolbar-top { padding: 4px 16px; background: var(--bs-body-bg); border-bottom: 1px solid var(--bs-border-color); min-height: 50px; height: auto !important; flex-wrap: wrap; flex-shrink: 0; }
        #sp_CRM_SaleInCRM_Premium .ttv-switcher-container { display: flex; background: var(--bs-tertiary-bg); border-radius: 50px; padding: 3px; position: relative; border: 1px solid var(--bs-border-color); height: 36px !important; width: fit-content; align-items: center; }
        #sp_CRM_SaleInCRM_Premium .ttv-pill { border: none; background: transparent; padding: 0 18px; font-size: 13px; font-weight: 600; color: var(--bs-secondary-color); position: relative; z-index: 2; cursor: pointer; border-radius: 50px; height: 100%; display: flex; align-items: center; justify-content: center; transition: color 0.3s; }
        #sp_CRM_SaleInCRM_Premium .ttv-pill.active { color: white; }
        #sp_CRM_SaleInCRM_Premium .ttv-pill-slider { position: absolute; top: 3px; left: 3px; height: calc(100% - 6px); background: var(--paradise-color-header1, #005f4b); border-radius: 50px; z-index: 1; transition: all 0.3s ease; }
        #sp_CRM_SaleInCRM_Premium .ttv-input-control { height: 34px; border-radius: 8px; border: 1px solid var(--bs-border-color); background: var(--bs-tertiary-bg); padding: 0 10px; font-size: 13px; color: var(--bs-body-color); outline: none; }
        #sp_CRM_SaleInCRM_Premium .filter-lbl-ttv { font-size: 11px; font-weight: 700; color: var(--bs-secondary-color); text-transform: uppercase; }
        #sp_CRM_SaleInCRM_Premium .btn-ttv-action-icon { width: 34px; height: 34px; border-radius: 50%; border: 1px solid var(--bs-border-color); background: transparent; display: flex; align-items: center; justify-content: center; color: var(--bs-secondary-color); cursor: pointer; }

        #sp_CRM_SaleInCRM_Premium .crm-content-ttv { flex: 1; overflow: hidden; padding: 16px; display: flex; flex-direction: column; }
        #sp_CRM_SaleInCRM_Premium .ttv-grid-wrap { border: 1px solid var(--bs-border-color); border-radius: 10px; flex: 0 1 auto; min-height: 0; max-height: 100%; display: flex; flex-direction: column; overflow-x: auto; overflow-y: hidden; background: var(--bs-body-bg); }
        #sp_CRM_SaleInCRM_Premium .ttv-grid-header { display: flex; background: var(--bs-tertiary-bg); padding: 12px 16px; border-bottom: 2px solid var(--bs-border-color); font-size: 11px; font-weight: 800; color: var(--bs-secondary-color); text-transform: uppercase; flex-shrink: 0; min-width: 800px; }
        #sp_CRM_SaleInCRM_Premium .ttv-grid-body { flex: 1; overflow-y: auto; overflow-x: hidden; scrollbar-width: none; -ms-overflow-style: none; min-width: 800px; }
        #sp_CRM_SaleInCRM_Premium .ttv-grid-body::-webkit-scrollbar { display: none; width: 0; }
        #sp_CRM_SaleInCRM_Premium .ttv-grid-row { display: flex; padding: 4px 8px; border-bottom: 1px solid var(--bs-border-color-translucent); align-items: center; cursor: pointer; font-size: 14px; }
        #sp_CRM_SaleInCRM_Premium .ttv-grid-row:hover { background: rgba(var(--bs-primary-rgb), 0.05); }

        #sp_CRM_SaleInCRM_Premium .emp-avatar { width: 34px; height: 34px; border-radius: 50% !important; background: var(--bs-secondary-bg); border: 1px solid var(--bs-border-color); display: flex; align-items: center; justify-content: center; font-weight: 700; color: var(--paradise-color-header1); overflow: hidden; margin-right: 12px; }
        #sp_CRM_SaleInCRM_Premium .emp-avatar img { width: 100%; height: 100%; object-fit: cover !important; border-radius: 50% !important; }

        #sp_CRM_SaleInCRM_Premium #crm-dash-view { overflow-y: auto; overflow-x: hidden; scroll-behavior: smooth; scrollbar-width: none; -ms-overflow-style: none; }
        #sp_CRM_SaleInCRM_Premium #crm-dash-view::-webkit-scrollbar { display: none; width: 0; }
        #sp_CRM_SaleInCRM_Premium .emp-avatar-large { width: 64px; height: 64px; border-radius: 50% !important; background: var(--bs-body-bg); border: 2px solid var(--bs-border-color); display: flex; align-items: center; justify-content: center; font-weight: 800; color: var(--paradise-color-header1); overflow: hidden; position: relative; }
        #sp_CRM_SaleInCRM_Premium .emp-avatar-large img { width: 100%; height: 100%; object-fit: cover !important; border-radius: 50% !important; }
        #sp_CRM_SaleInCRM_Premium .money-val { font-family: "Roboto Mono", monospace; font-weight: 600; }
        #sp_CRM_SaleInCRM_Premium .text-emerald { color: #10b981; }
        #sp_CRM_SaleInCRM_Premium .bg-emerald-light { background: rgba(16, 185, 129, 0.1); }
        #sp_CRM_SaleInCRM_Premium .metric-card { background: var(--bs-body-bg); border: 1px solid var(--bs-border-color); border-radius: 28px; padding: 20px; transition: transform 0.2s; }
        #sp_CRM_SaleInCRM_Premium .metric-card:hover { transform: translateY(-3px); }
        #sp_CRM_SaleInCRM_Premium .metric-label { font-size: 11px; font-weight: 700; color: var(--bs-secondary-color); text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 10px; }
        #sp_CRM_SaleInCRM_Premium .metric-value { font-size: 24px; font-weight: 800; font-family: "Roboto Mono", monospace; }
        #sp_CRM_SaleInCRM_Premium .metric-subtext { font-size: 11px; margin-top: 10px; opacity: 0.6; }

        #sp_CRM_SaleInCRM_Premium .dash-card { background: var(--bs-body-bg); border: 1px solid var(--bs-border-color); border-radius: 32px; padding: 24px; transition: all 0.3s; }
        #sp_CRM_SaleInCRM_Premium .ttv-detail-row { display: flex; padding: 14px 0; border-bottom: 1px solid rgba(var(--bs-border-color-rgb), 0.5); font-size: 13px; align-items: center; transition: all 0.2s; }
        #sp_CRM_SaleInCRM_Premium .ttv-detail-row:hover { background: rgba(var(--bs-primary-rgb), 0.02); }
        #sp_CRM_SaleInCRM_Premium .ttv-detail-row:last-child { border-bottom: none; }
        
        #sp_CRM_SaleInCRM_Premium .progress-micro { height: 6px; background: rgba(var(--bs-border-color-rgb), 0.2); border-radius: 50px; overflow: hidden; margin-top: 8px; width: 100%; }
        #sp_CRM_SaleInCRM_Premium .progress-micro-bar { height: 100%; border-radius: 50px; transition: width 0.8s cubic-bezier(0.34, 1.56, 0.64, 1); }
        
        #sp_CRM_SaleInCRM_Premium .custom-scrollbar::-webkit-scrollbar { width: 4px; }
        #sp_CRM_SaleInCRM_Premium .custom-scrollbar::-webkit-scrollbar-track { background: transparent; }
        #sp_CRM_SaleInCRM_Premium .custom-scrollbar::-webkit-scrollbar-thumb { background: var(--bs-border-color); border-radius: 10px; }
        
        #sp_CRM_SaleInCRM_Premium .dx-date-custom.dx-datebox { border-radius: 8px !important; border: 1px solid var(--bs-border-color) !important; background: var(--bs-tertiary-bg) !important; height: 34px !important; }
        #sp_CRM_SaleInCRM_Premium .dx-date-custom .dx-texteditor-input { padding: 0 10px !important; font-size: 13px !important; color: var(--bs-body-color) !important; }
        
        #sp_CRM_SaleInCRM_Premium .dash-period-header { font-size: 20px; font-weight: 800; color: var(--paradise-color-header1); letter-spacing: -0.5px; line-height: 1.2; }
        #sp_CRM_SaleInCRM_Premium .dash-period-sub { font-size: 11px; font-weight: 700; color: var(--bs-primary); text-transform: uppercase; letter-spacing: 1.5px; margin-top: 4px; opacity: 0.8; }
        
        @media print {
            @page { size: A4 landscape; margin: 10mm; }
            html, body { -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
            
            /* Chỉ hiện .printing-now, ẩn hết mọi thứ khác */
            body > :not(.printing-now) { display: none !important; }
            
            .printing-now {
                display: block !important;
                margin: 0 auto !important;
                padding: 0 !important;
                background: white !important;
                -webkit-print-color-adjust: exact !important;
                print-color-adjust: exact !important;
            }
            
            /* Layout bên trong Dashboard */
            .printing-now .row { display: flex !important; flex-wrap: wrap !important; }
            .printing-now .col-md-2 { flex: 0 0 16.66% !important; max-width: 16.66% !important; }
            .printing-now .col-md-4 { flex: 0 0 33.33% !important; max-width: 33.33% !important; }
            .printing-now .col-md-8 { flex: 0 0 66.66% !important; max-width: 66.66% !important; }
            
            .printing-now .metric-card {
                box-shadow: none !important; 
                border: 1px solid #e5e7eb !important;
                border-radius: 28px !important;
                padding: 20px !important;
                break-inside: avoid !important;
            }
            .printing-now .dash-card {
                box-shadow: none !important; 
                border: 1px solid #e5e7eb !important;
                border-radius: 32px !important;
                padding: 24px !important;
                break-inside: avoid !important;
            }
            
            /* Cố định màu tiêu đề không bị trình duyệt tự chuyển thành đen khi in */
            .printing-now .dash-period-header { color: var(--paradise-color-header1, #005f4b) !important; }
            .printing-now .dash-period-sub { color: var(--bs-primary, #0d6efd) !important; }
            
            /* Giữ flex layout cho danh sách hợp đồng */
            .printing-now .ttv-detail-row { display: flex !important; flex-wrap: nowrap !important; align-items: center !important; }
            .printing-now .ttv-detail-row > div { flex-shrink: 0 !important; }
            .printing-now .ttv-detail-row .flex-grow-1 { flex-grow: 1 !important; flex-shrink: 1 !important; }
            
            /* Hiện tiêu đề giữa (bị ẩn bởi d-none d-md-flex trên mobile) */
            .printing-now .d-none.d-md-flex { display: flex !important; }
            .printing-now .d-none.d-md-block { display: block !important; }
            
            /* Canvas biểu đồ */
            canvas { max-width: 100% !important; }
            
            /* Đảm bảo overlay labels hiển thị trong PDF */
            .printing-now #chart-labels-overlay { display: block !important; }
        }

        #sp_CRM_SaleInCRM_Premium .pdf-loading-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(var(--bs-body-bg-rgb), 0.8); backdrop-filter: blur(8px); z-index: 10000; display: none; align-items: center; justify-content: center; }
        #sp_CRM_SaleInCRM_Premium .pdf-loading-card { background: var(--bs-body-bg); padding: 40px; border-radius: 24px; border: 1px solid var(--bs-border-color); box-shadow: 0 20px 50px rgba(0,0,0,0.3); text-align: center; width: 320px; }
        
        #sp_CRM_SaleInCRM_Premium .skeleton-ttv { background: var(--bs-tertiary-bg); background: linear-gradient(90deg, var(--bs-tertiary-bg) 25%, var(--bs-secondary-bg) 50%, var(--bs-tertiary-bg) 75%); background-size: 200% 100%; animation: skeleton-loading-ttv 1.5s infinite; border-radius: 8px; }
        @keyframes skeleton-loading-ttv { 0% { background-position: 200% 0; } 100% { background-position: -200% 0; } }

        /* Các class hỗ trợ PDF (Chỉ dùng khi xuất bằng html2pdf) */
        .pdf-export-mode { background: white !important; color: inherit !important; padding: 15mm !important; height: auto !important; width: 275mm !important; display: block !important; overflow: visible !important; -webkit-print-color-adjust: exact !important; print-color-adjust: exact !important; }
        .pdf-export-mode #dash-avatar-container { width: 64px !important; height: 64px !important; min-width: 64px !important; border-radius: 50% !important; border: 2px solid #ddd !important; overflow: hidden !important; float: left !important; margin-right: 20px !important; background: #eee !important; }
        .pdf-export-mode #dash-avatar-img { width: 100% !important; height: 100% !important; object-fit: cover !important; display: block !important; border-radius: 50% !important; }
        .pdf-export-mode .metric-card, .pdf-export-mode .dash-card { border: 1px solid rgba(0,0,0,0.1) !important; box-shadow: none !important; transition: none !important; break-inside: avoid !important; }
        
        /* Fix lỗi vỡ danh sách hợp đồng chi tiết khi xuất PDF */
        .pdf-export-mode .ttv-detail-row { display: flex !important; flex-wrap: nowrap !important; align-items: center !important; gap: 15px !important; padding: 12px 0 !important; border-bottom: 1px solid #eee !important; width: 100% !important; }
        .pdf-export-mode .ttv-detail-row > div { flex-shrink: 0 !important; }
        .pdf-export-mode .ttv-detail-row .flex-grow-1 { flex-grow: 1 !important; flex-shrink: 1 !important; }
        
        .pdf-export-mode .row { display: flex !important; flex-wrap: wrap !important; width: 100% !important; }
                .pdf-export-mode canvas { max-width: 100% !important; height: auto !important; }

        @media (max-width: 992px) {
            #sp_CRM_SaleInCRM_Premium { height: auto !important; min-height: 100vh; overflow: visible !important; }
            #sp_CRM_SaleInCRM_Premium .crm-content-ttv { overflow: visible !important; display: flex; flex-direction: column; }
            #sp_CRM_SaleInCRM_Premium .ttv-grid-wrap { min-height: 500px; flex: none; }
        }
    </style>
    ' + N'
    <script>
    (function($) {
        "use strict";
        const currentLoginID = ' + CAST(ISNULL(@LoginID, 0) AS VARCHAR(10)) + N';
        ' + N'
        
        async function loadAvatar(path, $container) {
            if (!path) return;
            if (_imgCache[path]) return $container.css("background-image", `url(${await _imgCache[path]})`).show();
            _imgCache[path] = new Promise((resolve) => {
                AjaxHPAParadise({
                    xhrFields: { responseType: "blob" },
                    data: { name: "paradisefile_sp_GetFileAPI", param: ["FilePath", path] },
                    success: function (blob) {
                        const reader = new FileReader();
                        reader.onloadend = () => {
                            const base64data = reader.result;
                            $container.css({
                                "background-image": `url("${base64data}")`,
                                "background-size": "cover",
                                "background-position": "center",
                                "background-repeat": "no-repeat",
                                "background-color": "transparent"
                            }).fadeIn(200);
                            resolve(base64data);
                        };
                        reader.readAsDataURL(blob);
                    }, error: () => resolve("")
                });
            });
        }

        function init() {
            initValues();
            initDateBoxes();
            bindEvents();
            updateUIMode("month");
            setTimeout(() => { moveSlider($(''.ttv-pill.active'')); loadData("auto"); }, 300);
        }

        function initDateBoxes() {
            const dxOpts = { 
                type: "date", 
                displayFormat: "dd/MM/yyyy", 
                dateSerializationFormat: "yyyy-MM-dd", 
                useMaskBehavior: true, 
                showClearButton: true,
                onValueChanged: function(e) {
                    if (!_isInternal) loadData("manual");
                }
            };
            $(''#filter-date-from'').dxDateBox(dxOpts);
            $(''#filter-date-to'').dxDateBox(dxOpts);
        }

        function loadData(mode) {
            const $activePill = $(''.ttv-pill.active'');
            const range = $activePill.length ? $activePill.data(''range'') : "custom";
            const params = [
                "FilterType", range,
                "FilterYear", $(''#filter-year'').val(),
                "FilterMonth", $(''#filter-month'').val(),
                "FilterQuarter", range === "quarter" ? $(''#filter-quarter'').val() : null,
                "FilterWeek", range === "week" ? $(''#filter-week'').val() : null,
                "DateFrom", (mode === "manual" || range === "custom") ? $(''#filter-date-from'').dxDateBox("instance").option("value") : null,
                "DateTo", (mode === "manual" || range === "custom") ? $(''#filter-date-to'').dxDateBox("instance").option("value") : null,
                "LoginID", currentLoginID
            ];
            AjaxHPAParadise({
                data: { name: "sp_getSumContractInCRM", param: params },
                success: function(res) {
                    const json = typeof res === "string" ? JSON.parse(res) : res;
                    const data = (json.data && json.data[0]) || [];
                    const info = (json.data && json.data[1] && json.data[1][0]) || {};
                    _isInternal = true;
                    if (info.DateFrom) $(''#filter-date-from'').dxDateBox("instance").option("value", info.DateFrom);
                    if (info.DateTo)   $(''#filter-date-to'').dxDateBox("instance").option("value", info.DateTo);
                    $(''#list-date-range-display'').text(`${fmtDate(info.DateFrom)} - ${fmtDate(info.DateTo)}`);
                    _isInternal = false;
                    
                    // Tính toán tổng cộng cho Summary Cards
                    const totalRev = data.reduce((s, x) => s + (x.TotalRevenue || 0), 0);
                    const totalPaid = data.reduce((s, x) => s + (x.TotalPaid || 0), 0);
                    const totalUnpaid = data.reduce((s, x) => s + (x.TotalUnpaid || 0), 0);
                    const totalCount = data.reduce((s, x) => s + (x.ContractCount || 0), 0);
                    const totalFinalized = data.reduce((s, x) => s + (x.FinalizedRevenue || 0), 0);
                    const totalComm = data.reduce((s, x) => s + (x.TotalCommission || 0), 0);
                    
                    $(''#sum-total-revenue'').text(fmt(totalRev));
                    $(''#sum-total-paid'').text(fmt(totalPaid));
                    $(''#sum-total-unpaid'').text(fmt(totalUnpaid));
                    $(''#sum-total-contracts'').text(fmt(totalCount));
                    $(''#sum-finalized-revenue'').text(fmt(totalFinalized));
                    $(''#sum-total-commission'').text(fmt(totalComm));
                    $(''#sum-contract-subtext'').text(fmt(totalCount) + " %CRM_ContractInPeriodSuffix%");

                    renderRows(data);
                    $(''#filter-search'').trigger(''keyup'');
                }
            });
        }

        function renderRows(data) {
            const $body = $(''#crm-body-list'').empty();
            if(!data || !data.length) {
                $body.append(''<div class="p-5 text-center text-muted">%CRM_NoData%</div>'');
                return;
            }
            data.forEach(p => {
                const initial = (p.EmployeeName || "NV").split(" ").pop().substring(0, 2).toUpperCase();
                const $row = $(`<div class="ttv-grid-row">
                    <div style="flex: 2;" class="d-flex align-items-center"><div class="emp-avatar" style="background-size: cover; background-position: center;">${p.ImageLocation ? '''' : initial}</div><span class="fw-bold">${p.EmployeeName}</span></div>
                    <div class="text-end money-val" style="flex: 1;">${fmt(p.TotalRevenue)}</div>
                    <div class="text-end money-val text-danger" style="flex: 1;">${fmt(p.TotalUnpaid)}</div>
                    <div class="text-end money-val text-success" style="flex: 1;">
                        <div>${fmt(p.TotalPaid)}</div>
                        ${p.OldDebtCollection > 0 ? `<div class="small opacity-50" style="font-size:9px; font-weight:normal">%CRM_OldDebt%: ${fmt(p.OldDebtCollection)}</div>` : ''''}
                    </div>
                    <div class="text-end money-val text-info" style="flex: 1;">${fmt(p.FinalizedRevenue)}</div>
                    <div class="text-end money-val" style="flex: 1; color: #8b5cf6;">${fmt(p.TotalCommission)}</div>
                </div>`).appendTo($body);
                $row.on(''click'', () => showDetail(p));
                if (p.ImageLocation) loadAvatar(p.ImageLocation, $row.find(".emp-avatar"));
            });
        }

        function showDetail(p) {
            $(''#crm-list-view, #filter-group-main, .ttv-toolbar-top'').addClass(''d-none'');
            $(''#crm-dash-view, #btn-back-list'').removeClass(''d-none''); 
            
            // Cập nhật text tổng quan dựa trên filter
            const range = $(''.ttv-pill.active'').data(''range'');
            let label = "";
            const prefix = "%CRM_OverviewPrefix% ";
            if(range === ''month'') label = prefix + "%CRM_LblMonth% " + $(''#filter-month'').val() + "/" + $(''#filter-year'').val();
            else if(range === ''quarter'') label = prefix + "%CRM_LblQuarter% " + $(''#filter-quarter'').val() + "/" + $(''#filter-year'').val();
            else if(range === ''year'') label = prefix + "%CRM_LblYear% " + $(''#filter-year'').val();
            else if(range === ''week'') label = prefix + "%CRM_LblWeek% " + $(''#filter-week'').val() + " (" + $(''#filter-month'').val() + "/" + $(''#filter-year'').val() + ")";
            else label = prefix + "%CRM_LblCustom%";

            const dFrom = $(''#filter-date-from'').dxDateBox("instance").option("value");
            const dTo = $(''#filter-date-to'').dxDateBox("instance").option("value");
            $(''#dash-time-summary-text'').text(label);
            $(''#dash-time-range-text'').text(`${fmtDate(dFrom)} - ${fmtDate(dTo)}`);

            $(''#dash-emp-name'').text(p.EmployeeName);
            $(''#stat-revenue'').text(fmt(p.TotalRevenue));
            $(''#stat-paid'').text(fmt(p.TotalPaid));
            $(''#stat-unpaid'').text(fmt(p.TotalUnpaid));
            $(''#stat-finalized'').text(fmt(p.FinalizedRevenue));
            $(''#stat-commission'').text(fmt(p.TotalCommission));
            
            // Xử lý avatar lần chi tiết
            const initial = (p.EmployeeName || "NV").split(" ").pop().substring(0, 2).toUpperCase();
            const $avatarCont = $(''#dash-avatar-container'').html(p.ImageLocation ? '''' : initial).data(''empId'', p.EmployeeID);
            if (p.ImageLocation) loadAvatar(p.ImageLocation, $avatarCont);

            renderChart(p.TotalPaid, p.TotalUnpaid);
            $(''#dash-contract-type-list'').html(`
                <div class="p-3">
                    <div class="skeleton-ttv mb-3" style="height: 60px; width: 100%; border-radius: 12px;"></div>
                    <div class="skeleton-ttv mb-3" style="height: 60px; width: 100%; border-radius: 12px;"></div>
                    <div class="skeleton-ttv mb-3" style="height: 60px; width: 100%; border-radius: 12px;"></div>
                </div>
            `);
            loadEmployeeBreakdown(p.EmployeeID);
        }

        function loadEmployeeBreakdown(empId) {
            const range = $(''.ttv-pill.active'').data(''range'');
            const $list = $(''#dash-contract-type-list'').html(''<div class="p-5 text-center opacity-30"><i class="fas fa-circle-notch fa-spin fs-2"></i></div>'');
            const params = [
                "FilterType", range,
                "FilterYear", $(''#filter-year'').val(),
                "FilterMonth", $(''#filter-month'').val(),
                "FilterQuarter", range === "quarter" ? $(''#filter-quarter'').val() : null,
                "FilterWeek", range === "week" ? $(''#filter-week'').val() : null,
                "DateFrom", $(''#filter-date-from'').dxDateBox("instance").option("value"),
                "DateTo", $(''#filter-date-to'').dxDateBox("instance").option("value"),
                "EmployeeID", empId,
                "LoginID", currentLoginID
            ];
            AjaxHPAParadise({
                data: { name: "sp_getSumContractInCRM", param: params },
                success: function(res) {
                    const json = typeof res === "string" ? JSON.parse(res) : res;
                    const types = (json.data && json.data[2]) || [];
                    const trend = (json.data && json.data[3]) || [];
                    const payments = (json.data && json.data[4]) || [];
                    const totalContracts = types.reduce((acc, t) => acc + (t.ContractCount || 0), 0);
                    
                    $(''#stat-count'').text(totalContracts);
                    $(''#contract-count-summary'').text(totalContracts + " %CRM_ContractInPeriodSuffix%");
                    $list.empty();
                    
                    if(!types.length) $list.html(''<div class="py-5 text-center text-muted opacity-50">%CRM_NoContractData%</div>'');
                    else {
                        $list.empty(); // Xóa skeleton
                        types.forEach((t, index) => {
                            const percent = t.TotalRevenue > 0 ? Math.round(((t.TotalPaid - t.OldDebtCollection) / t.TotalRevenue) * 100) : (t.TotalPaid > 0 ? 100 : 0);
                            const contractPayments = payments.filter(p => String(p.ContractID) == String(t.ContractID));
                            
                            const $row = $(`<div class="ttv-contract-group mb-2" style="border: 1px solid var(--bs-border-color); border-radius: 12px; overflow: hidden; background: rgba(var(--bs-tertiary-bg-rgb), 0.3); opacity: 0; transform: translateY(10px); transition: all 0.4s ease-out;">
                                <div class="ttv-detail-row px-3 py-2 d-flex align-items-center" style="border-bottom: none; background: rgba(var(--bs-primary-rgb), 0.03); cursor: ${contractPayments.length > 0 ? ''pointer'' : ''default''};">
                                    <!-- Phần tên hợp đồng & Progress -->
                                    <div style="width: 250px; flex-shrink: 0;">
                                        <div class="fw-bold text-truncate d-flex align-items-center" style="color: var(--paradise-color-header1)">
                                            ${contractPayments.length > 0 ? `<i class="fas fa-chevron-right me-2 opacity-50 expand-icon" style="transition: transform 0.3s; font-size: 9px;"></i>` : ''''}
                                            <span>${t.ContractTypeName}</span>
                                        </div>
                                        <div class="progress-micro mt-1" style="width: 150px;"><div class="progress-micro-bar bg-success" style="width:0%"></div></div>
                                    </div>

                                    <!-- Phần thông tin khách hàng căn lề trái -->
                                    <div class="flex-grow-1 d-flex justify-content-start px-3">
                                        <div class="ttv-customer-badge d-inline-flex align-items-center px-3 py-1 rounded-pill bg-primary-subtle text-primary fw-normal" style="font-size: 11px; border: 1px solid rgba(var(--bs-primary-rgb), 0.2); box-shadow: 0 2px 4px rgba(0,0,0,0.05); cursor: pointer;">
                                            <i class="fas fa-user-circle me-2"></i> 
                                            <span class="fw-bold">${t.CustomerName || ''''}</span>
                                            ${t.CustomerPhone ? `<span class="ms-2 ps-2 border-start border-primary border-opacity-25 opacity-75"><i class="fas fa-phone-alt me-1" style="font-size: 9px;"></i> ${t.CustomerPhone}</span>` : ''''}
                                        </div>
                                    </div>
                                    <div class="text-end px-3" style="width: 110px; flex-shrink:0;">
                                        <div class="small opacity-50 text-uppercase" style="font-size:9px">%CRM_NewRevenue%</div>
                                        <div class="money-val text-primary" style="font-size:13px;">${fmt(t.TotalRevenue)}</div>
                                    </div>
                                    <div class="text-end px-3" style="width: 110px; flex-shrink:0;">
                                        <div class="small opacity-50 text-uppercase" style="font-size:9px">%CRM_UnpaidLabel%</div>
                                        <div class="money-val text-danger" style="font-size:13px;">${fmt(t.TotalUnpaid)}</div>
                                    </div>
                                    <div class="text-end px-3" style="width: 110px; flex-shrink:0;">
                                        <div class="small opacity-50 text-uppercase" style="font-size:9px">%CRM_PaidLabel%</div>
                                        <div class="money-val text-success" style="font-size:13px;">${fmt(t.TotalPaid)}</div>
                                        ${t.OldDebtCollection > 0 ? `<div class="small opacity-50" style="font-size:8px; font-weight:normal">%CRM_OldDebt%: ${fmt(t.OldDebtCollection)}</div>` : ''''}
                                    </div>
                                    <div class="text-end px-3" style="width: 110px; flex-shrink:0;">
                                        <div class="small opacity-50 text-uppercase" style="font-size:9px">%CRM_Finalized%</div>
                                        <div class="money-val text-info" style="font-size:13px;">${fmt(t.FinalizedRevenue)}</div>
                                    </div>
                                    <div class="text-end ps-3" style="width: 100px; flex-shrink:0;">
                                        <div class="small opacity-50 text-uppercase" style="font-size:9px">Hoa hồng</div>
                                        <div class="money-val" style="font-size:12px; color: #8b5cf6;">${fmt(t.CommissionAmount)}</div>
                                        <div class="small opacity-50" style="font-size:8px">(${t.CommissionRate}%)</div>
                                    </div>
                                </div>
                                <div class="ttv-payment-list px-4 pb-3" style="background: rgba(var(--bs-tertiary-bg-rgb), 0.5); display: none; position: relative;">
                                    <!-- Đường kẻ timeline dọc -->
                                    <div style="position: absolute; left: 32px; top: 0; bottom: 15px; width: 2px; background: rgba(var(--bs-primary-rgb), 0.1);"></div>
                                    
                                    ${contractPayments.map(p => `
                                        <div class="d-flex align-items-center py-2" style="position: relative; z-index: 1;">
                                            <!-- Icon điểm nút -->
                                            <div style="width: 24px; height: 24px; background: var(--bs-body-bg); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-left: -7px; border: 2px solid ${p.IsSalesFinalized == 2 ? ''var(--bs-info)'' : ''var(--bs-success)''}; box-shadow: 0 0 0 3px rgba(var(--bs-body-bg-rgb), 1);">
                                                <i class="fas ${p.IsSalesFinalized == 2 ? ''fa-award text-info'' : ''fa-check text-success''}" style="font-size: 10px;"></i>
                                            </div>
                                            
                                            <!-- Nội dung đợt thu -->
                                            <div class="ms-3 d-flex align-items-center flex-grow-1 bg-body rounded-pill px-3 py-1 border shadow-sm" style="font-size: 11px;">
                                                <div style="width: 100px;" class="opacity-75"><i class="far fa-calendar-alt me-1"></i> ${fmtDate(p.PaidDate)}</div>
                                                <div class="flex-grow-1"></div>
                                                <div class="money-val fw-bold ${p.IsSalesFinalized == 2 ? ''text-info'' : ''text-success''}" style="font-size: 12px;">${fmt(p.PaymentAmount)}</div>
                                                <div class="ms-3 badge ${p.IsSalesFinalized == 2 ? ''bg-info-subtle text-info'' : ''bg-success-subtle text-success''}" style="font-size: 9px; font-weight: normal; min-width: 60px;">
                                                    ${p.IsSalesFinalized == 2 ? ''%CRM_Finalized%'' : ''%CRM_PaidLabel%''}
                                                </div>
                                            </div>
                                        </div>
                                    `).join('''')}
                                </div>
                            </div>`).appendTo($list);
                            
                            // Event mở chi tiết khách hàng
                            $row.find(".ttv-customer-badge").on("click", function(e) {
                                e.stopPropagation();
                                const companyID = t.CRM_CompanyID;
                                if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
                                    OpenFormParamMobile(`sp_CRM_CustomerDetail`, { Company_ID: companyID });
                                } else {
                                    openFormParam(`sp_CRM_CustomerDetail`, { Company_ID: companyID });
                                }
                            });

                            if (contractPayments.length > 0) {
                                $row.find(".ttv-detail-row").on("click", function() {
                                    const $pList = $(this).siblings(".ttv-payment-list");
                                    const $icon = $(this).find(".expand-icon");
                                    
                                    $pList.stop(true, true).slideToggle(400, function() {
                                        $icon.css("transform", $(this).is(":visible") ? "rotate(90deg)" : "rotate(0deg)");
                                    });
                                });
                            }
                            
                            setTimeout(() => {
                                $row.css({ "opacity": 1, "transform": "translateY(0)" });
                                $row.find(".progress-micro-bar").css("width", percent + "%");
                            }, 50 + (index * 50));
                        });
                    }
                    renderTrendChart(trend);
                }
            });
        }

        function renderTrendChart(data) {
            if (!data) return;
            if (_trendChart) _trendChart.destroy();
            const ctx = document.getElementById(''chart-revenue-trend'').getContext(''2d'');
            
            const labels = data.map(d => fmtDate(d.RevenueDate));
            const vals = data.map(d => d.DailyRevenue);

            _trendChart = new Chart(ctx, {
                type: ''line'',
                data: {
                    labels: labels,
                    datasets: [{
                        label: ''%CRM_DailyRevenue%'',
                        data: vals,
                        borderColor: ''#10b981'',
                        backgroundColor: (context) => {
                            const chart = context.chart; const {ctx, chartArea} = chart;
                            if (!chartArea) return null;
                            const gradient = ctx.createLinearGradient(0, chartArea.top, 0, chartArea.bottom);
                            gradient.addColorStop(0, ''rgba(16, 185, 129, 0.2)'');
                            gradient.addColorStop(1, ''rgba(16, 185, 129, 0)'');
                            return gradient;
                        },
                        fill: true, tension: 0.4, pointRadius: 4, borderWidth: 2
                    }]
                },
                options: {
                    maintainAspectRatio: false,
                    layout: { padding: { top: 10 } },
                    scales: {
                        y: { 
                            beginAtZero: true, 
                            grid: { display: true, color: ''rgba(0,0,0,0.05)'' },
                            border: { display: false },
                            afterFit: function(scale) { scale.width = 0; },
                            ticks: { display: false }
                        },
                        x: { 
                            grid: { display: true, color: ''rgba(0,0,0,0.03)'' },
                            border: { display: false },
                            afterFit: function(scale) { scale.height = 0; },
                            ticks: { display: false }
                        }
                    },
                    animation: {
                        onComplete: function() {
                            const chart = this;
                            if (!chart.chartArea) return;
                            const fmtNum = n => new Intl.NumberFormat(''vi-VN'').format(Math.round(n));

                            // Y-axis labels - DOM thực bên ngoài canvas
                            const yDiv = document.getElementById(''chart-y-axis-html'');
                            if (yDiv) {
                                yDiv.innerHTML = '''';
                                const yScale = chart.scales.y;
                                if (yScale && yScale.ticks) {
                                    yScale.ticks.forEach((tick, i) => {
                                        const yPx = yScale.getPixelForTick(i);
                                        const el = document.createElement(''div'');
                                        el.style.cssText = `position:absolute; right:6px; top:${yPx}px; transform:translateY(-50%); font-size:10px; color:rgba(0,0,0,0.5); white-space:nowrap; line-height:1.4;`;
                                        el.textContent = fmtNum(tick.value);
                                        yDiv.appendChild(el);
                                    });
                                }
                            }

                            // X-axis labels - DOM thực bên ngoài canvas
                            const xDiv = document.getElementById(''chart-x-axis-html'');
                            if (xDiv) {
                                xDiv.innerHTML = '''';
                                const xScale = chart.scales.x;
                                if (xScale && xScale.ticks) {
                                    xScale.ticks.forEach((tick, i) => {
                                        const xPx = xScale.getPixelForTick(i);
                                        const el = document.createElement(''div'');
                                        el.style.cssText = `position:absolute; left:${xPx}px; top:3px; transform:translateX(-50%); font-size:10px; color:rgba(0,0,0,0.5); white-space:nowrap; line-height:1.4;`;
                                        el.textContent = chart.data.labels[i] || '''';
                                        xDiv.appendChild(el);
                                    });
                                }
                            }
                        }
                    },
                    plugins: { legend: { display: false } }
                }
            });
        }

        function renderChart(paid, unpaid) {
            const total = paid + unpaid;
            const percent = total > 0 ? Math.round((paid / total) * 100) : 0;
            $(''#chart-percent'').text(percent + "%");

            if (_chart) _chart.destroy();
            const ctx = document.getElementById(''chart-payment-donut'').getContext(''2d'');
            _chart = new Chart(ctx, { 
                type: ''doughnut'', 
                data: { 
                    labels: [''%CRM_ChartPaid%'', ''%CRM_ChartUnpaid%''], 
                    datasets: [{ 
                        data: [paid, unpaid], 
                        backgroundColor: [''#10b981'', ''#ef4444''], 
                        hoverOffset: 4,
                        borderWidth: 0,
                        cutout: ''80%''
                    }] 
                }, 
                options: { 
                    maintainAspectRatio: false, 
                    plugins: { 
                        legend: { display: false },
                        datalabels: { display: false }
                    } 
                }
            });
            
            const $legend = $(''#chart-custom-legend'').empty();
            [{l:''%CRM_ChartPaid%'', v:paid, c:''#10b981''}, {l:''%CRM_ChartUnpaid%'', v:unpaid, c:''#ef4444''}].forEach(item => {
                $(`<div class="d-flex align-items-center justify-content-between p-2 rounded-3 bg-tertiary mb-2">
                    <div class="d-flex align-items-center gap-2">
                        <div style="width:8px; height:8px; border-radius:50%; background:${item.c}"></div>
                        <span class="small fw-bold opacity-75">${item.l}</span>
                    </div>
                    <span class="money-val small">${fmt(item.v)}</span>
                </div>`).appendTo($legend);
            });
        }

        const _imgCache = {};
        let _isInternal = false, _chart = null, _trendChart = null;

        function fmt(n) { return new Intl.NumberFormat(''vi-VN'').format(Math.round(n || 0)); }
        function fmtDate(d) { 
            if(!d) return ""; 
            const date = new Date(d); 
            const day = date.getDate().toString().padStart(2, ''0'');
            const month = (date.getMonth() + 1).toString().padStart(2, ''0'');
            return day + "/" + month + "/" + date.getFullYear(); 
        }

        function bindEvents() {
            $(''.ttv-pill'').on(''click'', function() {
                const $b = $(this); if ($b.hasClass(''active'')) return;
                $(''.ttv-pill'').removeClass(''active''); $b.addClass(''active'');
                $(''.ttv-pill-slider'').css(''opacity'', 1);
                moveSlider($b); updateUIMode($b.data(''range'')); loadData("auto");
            });
            $(''#btn-back-list, #btn-back-detail-new'').on(''click'', function() { 
                $(''#crm-list-view, #filter-group-main, .ttv-toolbar-top'').removeClass(''d-none''); 
                $(''#crm-dash-view, #btn-back-list'').addClass(''d-none''); 
            });
            $(''#filter-year, #filter-month, #filter-quarter, #filter-week'').on(''change'', () => loadData("auto"));
            $(''#filter-date-from, #filter-date-to'').each(function() {
                $(this).dxDateBox("instance").option("onValueChanged", (e) => {
                    if (!_isInternal) {
                        $(''.ttv-pill'').removeClass(''active''); 
                        $(''.ttv-pill-slider'').css(''opacity'', 0);
                        loadData("manual");
                    }
                });
            });
            $(''#btn-reload-main'').on(''click'', () => loadData("manual"));
            $(''#btn-reload-detail'').on(''click'', () => {
                 const currentEmpId = $(''#dash-avatar-container'').data(''empId'');
                 if(currentEmpId) loadEmployeeBreakdown(currentEmpId);
                 else loadData("manual");
            });
            $(''#btn-export-pdf'').on(''click'', function() {
                const empName = $(''#dash-emp-name'').text() || "Report";
                const originalTitle = document.title;
                const $target = $(''#crm-dash-view'');
                $(''#pdf-loading'').css(''display'', ''flex'');
                requestAnimationFrame(() => {
                    requestAnimationFrame(() => {
                        const $ph = $(''<div style="display:none"></div>'').insertAfter($target);
                        // Cố định width = 1100px để chart.resize() khớp với trang A4
                        $target.appendTo(''body'').addClass(''printing-now'').css({
                            ''display'': ''block'',
                            ''width'': ''1100px''
                        }).removeClass(''d-none'');
                        document.title = `BaoCao_CRM_${empName.replace(/\s+/g, ''_'')}`;

                        // Resize chart để tính lại tọa độ overlay theo kích thước trang in
                        const doPrint = () => {
                            window.print();
                            $target.insertAfter($ph).removeClass(''printing-now'').css({''display'': '''', ''width'': ''''});
                            $ph.remove();
                            document.title = originalTitle;
                            $(''#pdf-loading'').hide();
                        };

                        if (_trendChart) {
                            _trendChart.resize();
                            // Đợi animation.onComplete chạy lại (vẽ overlay mới) rồi mới in
                            setTimeout(doPrint, 400);
                        } else {
                            doPrint();
                        }
                    });
                });
            });
        }

        function initValues() {
            const now = new Date(); 
            let y = now.getFullYear(); 
            let m = now.getMonth() + 1;
            
            // Nếu là đầu tháng (trước ngày 10) thì mặc định xem chu kỳ tháng trước
            if (now.getDate() < 10) {
                m--;
                if (m === 0) { m = 12; y--; }
            }
            
            const q = Math.ceil(m / 3); 
            
            // Tính tuần hiện tại của tháng (Tuần 1 bắt đầu từ Thứ Hai đầu tiên)
            let firstMonday = new Date(y, m - 1, 1);
            while (firstMonday.getDay() !== 1) { firstMonday.setDate(firstMonday.getDate() + 1); }
            
            let currentWeek = 1;
            const refDate = (now.getMonth() + 1 === m) ? now : new Date(y, m, 0); // Nếu xem tháng trước thì lấy ngày cuối tháng đó làm mốc
            if (refDate >= firstMonday) {
                currentWeek = Math.ceil((refDate.getDate() - firstMonday.getDate() + 1) / 7);
            }

            for(let i=y; i>=y-5; i--) $(''#filter-year'').append(`<option value="${i}">${i}</option>`);
            $(''#filter-month'').append(''<option value="1">%CRM_Month1%</option><option value="2">%CRM_Month2%</option><option value="3">%CRM_Month3%</option><option value="4">%CRM_Month4%</option><option value="5">%CRM_Month5%</option><option value="6">%CRM_Month6%</option><option value="7">%CRM_Month7%</option><option value="8">%CRM_Month8%</option><option value="9">%CRM_Month9%</option><option value="10">%CRM_Month10%</option><option value="11">%CRM_Month11%</option><option value="12">%CRM_Month12%</option>'');
            $(''#filter-week'').append(''<option value="1">%CRM_Week1%</option><option value="2">%CRM_Week2%</option><option value="3">%CRM_Week3%</option><option value="4">%CRM_Week4%</option><option value="5">%CRM_Week5%</option>'');
            $(''#filter-quarter'').append(''<option value="1">%CRM_Q1%</option><option value="2">%CRM_Q2%</option><option value="3">%CRM_Q3%</option><option value="4">%CRM_Q4%</option>'');
            
            $(''#filter-year'').val(y); 
            $(''#filter-month'').val(m);
            $(''#filter-quarter'').val(q);
            $(''#filter-week'').val(currentWeek > 5 ? 5 : currentWeek);
        }

        function updateUIMode(range) {
            $(''#filter-month, #filter-quarter, #filter-week'').hide();
            if (range === "month") $(''#filter-month'').show();
            else if (range === "quarter") $(''#filter-quarter'').show();
            else if (range === "week") { $(''#filter-month, #filter-week'').show(); }
        }

        function moveSlider($b) { if(!$b || !$b.length) return; const p = $b.position(); $(''.ttv-pill-slider'').css({ width: $b.outerWidth(), left: p.left }); }
        $(document).ready(init);
    })(jQuery);
    </script>
    ';
    SELECT @html AS html;
END
GO
