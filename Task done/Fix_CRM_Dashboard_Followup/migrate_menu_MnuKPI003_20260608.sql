-- ============================================================================
-- File: SQL script/migrate_menu_MnuKPI003_20260608.sql
-- Mục đích: Migrate menu MnuKPI003 (KPI List Data Collection) ParadiseHR.
-- Cảnh báo: USER review + chạy. BACKUP DB trước. Idempotent.
-- ============================================================================
SET NOCOUNT ON; SET XACT_ABORT ON;
GO

-- PHASE 1: API procedures (sp_KPIgetDataCollection - nằm ở file sql riêng)
-- File Update_sp_KPIgetDataCollection.sql đi kèm trong thư mục Task done.

-- PHASE 2: Renderer (sp_KPIListDataCollection_html)
IF OBJECT_ID('dbo.sp_KPIListDataCollection_html','P') IS NOT NULL DROP PROCEDURE dbo.sp_KPIListDataCollection_html;
GO

CREATE PROCEDURE [dbo].[sp_KPIListDataCollection_html]

(

    @LoginID INT = 3,

    @LanguageID VARCHAR(2) = 'VN',

    @isWeb INT = 0

)

AS

BEGIN

    SET NOCOUNT ON;




    DECLARE @html NVARCHAR(MAX);

    SET @html =  N'

<div id="dataCollectionComponent" class="dc-container">



    <style>

        /* Bỏ border của button */

        .custom-no-circle.dx-dropdownbutton .dx-button {

            border: none !important;

            background: transparent !important;

            box-shadow: none !important;

        }



        /* Bỏ border khi hover/focus */

        .custom-no-circle.dx-dropdownbutton .dx-button:hover,

        .custom-no-circle.dx-dropdownbutton .dx-button.dx-state-hover,

        .custom-no-circle.dx-dropdownbutton .dx-button.dx-state-focused {

            border: none !important;

            background: transparent !important;

            box-shadow: none !important;

        }



        /* Bỏ outline wrapper bên ngoài */

        .custom-no-circle.dx-dropdownbutton.dx-state-focused {

            outline: none !important;

            box-shadow: none !important;

        }



        #dataCollectionComponent .crm-status-row {

            display: none;

            flex-wrap: nowrap;

            align-items: center;

            padding: 6px;

            border: 1px solid #e0e0e0;

            border-radius: 999px;

            overflow-x: auto;

            -webkit-overflow-scrolling: touch;

            scrollbar-width: none;

        }



        #dataCollectionComponent .crm-status-row::-webkit-scrollbar {

            display: none;

            /* Hide scrollbar for Chrome, Safari, and Opera */

        }



        @keyframes slideInLeft {

            from {

                opacity: 0;

                transform: translateY(-4px);

            }



            to {

                opacity: 1;

                transform: translateY(0);

            }

        }



        @keyframes slideInRight {

            from {

                opacity: 0;

                transform: translateY(4px);

            }



            to {

                opacity: 1;

                transform: translateY(0);

            }

        }



        #dataCollectionComponent .crm-status-pill {

            padding: 6px 8px;

            border-radius: 999px;

            border: none;

            font-size: 12px;

            cursor: pointer;

            font-weight: 500;

            background: transparent;

            transition: all 0.25s ease-in-out;

            white-space: nowrap;

            line-height: 1.4;

            display: inline-block;

            position: relative;

            flex-shrink: 0;

            will-change: transform, opacity;

        }



        #dataCollectionComponent .crm-status-pill.slide-in-left {

            animation: slideInLeft 0.4s ease-out;

        }



        #dataCollectionComponent .crm-status-pill.slide-in-right {

            animation: slideInRight 0.4s ease-out;

        }



        #dataCollectionComponent .crm-status-pill:hover {

            background: #f1f5f9;

            color: #1e293b;

        }



        #dataCollectionComponent .crm-status-pill.status-pill-active {

            background: #198754;

            color: #ffffff;

            font-weight: 600;

            box-shadow: 0 2px 8px rgba(25, 135, 84, 0.2);

        }



        #dataCollectionComponent .crm-status-pill.status-pill-active:hover {

            background: #157347;

        }



        #GridKC .dx-toolbar .dx-toolbar-items-container {

            height: auto;

            min-height: 56px;

            flex-wrap: wrap;

            align-items: center;

            row-gap: 6px;

            margin-bottom: 15px;

        }



        .dc-container {

            border-radius: 8px;

            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);

            padding: 10px;

        }



        .dc-header-section {

            display: flex;

            justify-content: space-between;

    align-items: center;

            margin-bottom: 20px;

            padding-bottom: 15px;

            border-bottom: 2px solid #e9ecef;

        }



        .dc-header-section h2 {

            margin: 0;

        }



        #dataCollectionModal.show {

            display: flex !important;

            align-items: center !important;

            justify-content: center !important;

            min-height: 100vh;

            background: rgba(19, 16, 16, .8) !important;

        }



        .modal-backdrop.show {

            background: rgba(0, 0, 0, 0.65);

            backdrop-filter: blur(1px);

        }



        #dataCollectionModal .modal-dialog {

            margin: 0 !important;

            width: 90vw;

            max-width: 90vw;

            display: flex;

            align-items: center;

            justify-content: center;

            min-height: 100vh;

        }



        .modal-content {

            margin-top: 50px;

            border: none !important;

            box-shadow: none !important;

            width: 100%;

            max-height: 90vh;

            overflow-y: auto;

            scrollbar-width: none;

            -ms-overflow-style: none;

        }



        .modal-content::-webkit-scrollbar {

            display: none;

        }



        .modal-footer {

            border-top: 1px solid rgba(255, 255, 255, 0.1);

        }



        .dc-table tbody tr:hover {

            background-color: rgba(255, 255, 255, 0.05) !important;

        }



        .dc-filter {

            display: flex;

            gap: 15px;

            align-items: flex-end;

            flex-wrap: wrap;

        }



        .dc-filter>div {

            display: flex;

        }



        .dc-filter label {

            display: block;

            margin-bottom: 5px;

            font-weight: 600;

            font-size: 13px;

        }



        .dc-filter button {

            padding: 10px 20px;

            border: none;

            border-radius: 8px;

            cursor: pointer;

            font-weight: 500;

            font-size: 14px;

            display: inline-flex;

            align-items: center;

            gap: 8px;

            transition: all 0.3s ease;

        }



        .dc-filter .btn-filter {

            background-color: #198754;

            color: white;

        }



        .dc-filter .btn-filter:hover {

            background-color: #157347;

            transform: translateY(-2px);

            box-shadow: 0 4px 12px rgba(25, 135, 84, 0.4);

        }



        .dc-filter .btn-reset {

            background-color: transparent;

            color: #198754;

            border: 2px solid #198754;

        }



        .dc-filter .btn-reset:hover {

            background-color: #198754;

            color: white;

        }



        /* Responsive toolbar styles */

        .dc-filter {

            flex-wrap: wrap !important;

            gap: 3px !important;

        }



        @media (max-width: 1200px) {

            .dc-filter {

                flex-direction: column !important;

                align-items: flex-start !important;

                gap: 6px !important;

            }



            .dc-filter>div {

                display: flex !important;

                flex-wrap: wrap !important;







                gap: 6px !important;

                width: 100% !important;

            }



            #dcFilterEmployeeToolbar {

                width: 140px !important;

                min-width: 140px !important;

            }

        }



        @media (max-width: 768px) {

            .dc-filter {

                gap: 4px !important;

            }



            .dc-filter button {

                padding: 4px 8px !important;

                font-size: 11px !important;

            }



            .dc-filter input[type="date"] {

                padding: 4px !important;

font-size: 11px !important;

           }



            #dcFilterEmployeeToolbar {

                width: 120px !important;

                min-width: 120px !important;

            }

        }



        /* Loading overlay styles */

        .ai-processing-overlay {

            position: fixed;

            top: 0;

            left: 0;

            width: 100%;

            height: 100%;

            background: rgba(0, 0, 0, 0.7);

            display: none;

            justify-content: center;

            align-items: center;

            z-index: 9999;

            flex-direction: column;

        }



        .ai-processing-overlay.show {

            display: flex !important;

        }



        .ai-spinner {

            width: 60px;

            height: 60px;

            border: 4px solid #e9ecef;

            border-top: 4px solid #198754;

            border-radius: 50%;

            animation: ai-spin 1s linear infinite;

            margin-bottom: 20px;

        }



        @keyframes ai-spin {

            0% {

                transform: rotate(0deg);

            }



            100% {

                transform: rotate(360deg);

            }

        }



        .ai-processing-text {

            color: white;

            font-size: 16px;

            font-weight: 500;

            text-align: center;

            margin-bottom: 10px;

        }



        .ai-processing-subtext {

            color: #ccc;

            font-size: 14px;

            text-align: center;

        }



        .modal-content.processing {

            opacity: 0.6;

            pointer-events: none;

        }



        .image-processing-indicator {

            position: absolute;

            top: 50%;

            left: 50%;

            transform: translate(-50%, -50%);

            background: rgba(25, 135, 84, 0.9);

            color: white;

            padding: 15px 25px;

            border-radius: 8px;

            display: none;

            flex-direction: column;

            align-items: center;

            gap: 10px;

            z-index: 1000;

        }



        .image-processing-indicator.show {

            display: flex !important;

        }



        .mini-spinner {

            width: 24px;

            height: 24px;

            border: 3px solid rgba(255, 255, 255, 0.3);

            border-top: 3px solid white;

            border-radius: 50%;

            animation: ai-spin 1s linear infinite;

        }

    </style>



    <!-- Management Buttons -->

    <div class="d-none">

        <div style="display: flex; gap: 5px; align-items: center; flex-wrap: wrap; justify-content: flex-end;">

            <button class="btn btn-success CRM_DataCollection_BtnImportExcel"

                style="padding: 6px 12px; border: none; border-radius: 8px; cursor: pointer; font-weight: 500; font-size: 12px; display: inline-flex; align-items: center; gap: 8px; transition: all 0.3s ease; background-color: #198754; color: white;">

                <i class="bi bi-download"></i> Import







            </button>

            <button class="btn btn-success CRM_DataCollection_BtnExportExcel"

                style="padding: 6px 12px; border: none; border-radius: 8px; cursor: pointer; font-weight: 500; font-size: 12px; display: inline-flex; align-items: center; gap: 8px; transition: all 0.3s ease; background-color: #198754; color: white;">

                <i class="bi bi-file-earmark-excel"></i> Export

            </button>

            <button class="btn btn-success CRM_DataCollection_BtnAdd"

                style="padding: 6px 12px; border: none; border-radius: 8px; cursor: pointer; font-weight: 500; font-size: 12px; display: inline-flex; align-items: center; gap: 8px; transition: all 0.3s ease; background-color: #198754; color: white;">

                + Thêm mới

            </button>

            <button class="btn btn-success" id="btnPendingList"

                style="padding: 6px 12px; border: none; border-radius: 8px; cursor: pointer; font-weight: 500; font-size: 12px; display: inline-flex; align-items: center; gap: 8px; transition: all 0.3s ease; background-color: #198754; color: white;">

                <i class="bi bi-list-ul"></i> Danh sách bổ xung

            </button>

        </div>

    </div>



    <div class="d-none">

        <div id="PDF424130C28F4C1298C81F737570F7A7"></div>

        <div id="P4510BE8E25E842D286E3E8C0ACAE8E7E"></div>

        <div id="PF18C5687EA514B69BFBA6BCA32E2D629"></div>

    </div>



    <div>

        <!-- <table class="table table-striped table-hover dc-table">

            <thead>

                <tr>

                    <th>STT</th>

                    <th>Ngày</th>

                    <th>Công ty</th>

                    <th>Mã s? thu?</th>

                    <th>Ngành</th>

       <th>Email</th>

                    <th>SÐT</th>

                    <th>Hành d?ng</th>

                </tr>

            </thead>

            <tbody id="dataCollectionTableBody">

            </tbody>

        </table> -->

        <div id="GridKC" style="height: 100%;"></div>

    </div>



    <!-- AI Processing Loading Overlay -->

    <div id="aiProcessingOverlay" class="ai-processing-overlay">

        <div class="ai-spinner"></div>

        <div class="ai-processing-text">Đang phân tích hình ảnh với AI...</div>

        <div class="ai-processing-subtext">Vui lòng đợi một chút</div>

    </div>



    <!-- Data Collection Modal -->

    <div class="modal fade" id="dataCollectionModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false">

        <div class="modal-dialog modal-lg">

            <div class="modal-content">

                <div class="modal-header">

                    <h5 class="modal-title" id="dataCollectionModalTitle">%CompanyInfo%</h5>

                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>

                </div>

                <div class="modal-body">

                    <form id="dataCollectionForm">

                        <!-- Thông tin công ty -->

                        <div class="mb-4">

                            <h6 class="mb-3"

                                style="color: #198754; font-weight: 600; border-bottom: 2px solid #e9ecef; padding-bottom: 8px;">

                                <i class="bi bi-building"></i> %CompanyInfo%

                            </h6>



                            <div class="form-group mb-3">

                                <div class="row align-items-center">

                                    <div class="col-md-3">

                                        <label for="P93D36D79837B4A17A1D44F5B262DA097"

                                            class="form-label mb-0">%CreateDate%:</label>

                                    </div>

                                    <div class="col-md-9">

                                        <div id="P93D36D79837B4A17A1D44F5B262DA097"></div>

                                    </div>

            </div>

                            </div>



                            <div class="row mb-3">

                                <div class="col-md-6">

                                    <div class="row align-items-center">

                                        <div class="col-md-4">

                                            <label for="dc_company" class="form-label mb-0">%Company% (<span class="text-danger">*</span>):</label>

                                        </div>

                                        <div class="col-md-8">

                                            <div id="PCEA494414F404AF7AD9BFCE81F15F90E"></div>

                                        </div>

                                    </div>

                                </div>

                                <div class="col-md-6">

                                    <div class="row align-items-center">



       <div class="col-md-4">

                                            <label for="dc_taxCode" class="form-label mb-0">%TaxCode% (<span class="text-danger">*</span>):</label>

                                        </div>

                                        <div class="col-md-8">

                                            <div id="PE9DF5833F12044D78B19C7B41306E4C6"></div>

                                        </div>

                                    </div>

                                </div>

                            </div>



                            <div class="row mb-3">

                                <div class="col-md-6">

                                    <div class="row align-items-center">

                                        <div class="col-md-4">

                                            <label for="dc_industry" class="form-label mb-0">%Industry%:</label>

                                        </div>

                                        <div class="col-md-8">

                                            <div id="P8FD2ACDEFBB247A78E44E81876FF013A"></div>

                                        </div>

                                    </div>

                                </div>

                                <div class="col-md-6">

                                    <div class="row align-items-center">

                                        <div class="col-md-4">

                                            <label for="dc_address" class="form-label mb-0">%Address% (<span class="text-danger">*</span>):</label>

                                        </div>

                                        <div class="col-md-8">

                                            <div id="P4CA52B6C787249E68C408A05419C0C77"></div>

                                        </div>

                                    </div>

                                </div>

                            </div>



                            <div class="row mb-3">

                                <div class="col-md-6">

                                    <div class="row align-items-center">

                                        <div class="col-md-4">

                                            <label for="dc_companySize" class="form-label mb-0">%CompanySize%:</label>

                                        </div>

                                        <div class="col-md-8">

                                            <div id="PF09EBAE4C6DA4BE3B1A79BAF021AC73C"></div>

                                        </div>

                                    </div>

                                </div>

                                <div class="col-md-6">

                                    <div class="row align-items-center">

                                        <div class="col-md-4">

                                            <label for="dc_source" class="form-label mb-0">%Source%:</label>

                                        </div>

                                        <div class="col-md-8">

                                            <div id="P9A288D9BFC0A4460B0D404DE8E29E285"></div>

                                        </div>

                                    </div>

                                </div>

                            </div>

                        </div>



                        <!-- Thông tin liên hệ -->

                        <div class="mb-4">

                            <h6 class="mb-3"

                                style="color: #198754; font-weight: 600; border-bottom: 2px solid #e9ecef; padding-bottom: 8px;">

                                <i class="bi bi-person-badge"></i> %EmployeeContactDetails%

                            </h6>









                            <div class="row mb-3">

                                <div class="col-md-6">

                                    <div class="row align-items-center">

                  <div class="col-md-4">



            <label for="dc_contactPerson"

                                                class="form-label mb-0">%ContactPerson% (<span class="text-danger">*</span>):</label>

                                        </div>

                                        <div class="col-md-8">

                                            <div id="P505719422EBB4A44AA7EB825DC4B8126"></div>

                                        </div>

                                    </div>

                                </div>

                                <div class="col-md-6">

                                    <div class="row align-items-center">

                                        <div class="col-md-4">

                                            <label for="dc_phone" class="form-label mb-0">%PhoneNumber% (<span class="text-danger">*</span>):</label>

                                        </div>

                                        <div class="col-md-8">

                                            <div id="PB03D8BEAD0934DC2B599C27F771CE2DD"></div>

                                        </div>

                                    </div>

                                </div>

                            </div>



                            <div class="row mb-3">

                                <div class="col-md-6">

                                    <div class="row align-items-center">

                                        <div class="col-md-4">

                                            <label for="dc_email" class="form-label mb-0">%Email%:</label>

                                        </div>

                                        <div class="col-md-8">

                                            <div id="P0ED76598CC6C42B182C977574DB3960A"></div>

                                        </div>

                                    </div>

                                </div>

                                <div class="col-md-6">

                                    <div class="row align-items-center">

                                        <div class="col-md-4">

                                            <label for="dc_companySize"

                                                class="form-label mb-0">%ContactPosition%:</label>

                                        </div>

                                        <div class="col-md-8">

                                            <div id="P690E6110CC9042F0B7E64B4A3D7C4DF1"></div>

                                        </div>

                                    </div>

                                </div>

                            </div>



                            <div class="row mb-3">

  <div class="col-md-6">

                       <div class="row align-items-center">

                                        <div class="col-md-4">

                                            <label for="dc_email" class="form-label mb-0">%MSG_EMAIL_SUB%:</label>

                                        </div>

                                        <div class="col-md-8">

                                            <div id="P87BE9D5708F947458C9F37FA1B601478"></div>

                                        </div>

                                    </div>

                                </div>

                                <div class="col-md-6">

                                    <div class="row align-items-center">

                                        <div class="col-md-4">

                                            <label for="dc_companySize" class="form-label mb-0">%MSG_PHONE_SUB%:</label>

                                        </div>

                                        <div class="col-md-8">

                                            <div id="PA57E3C14412E427C8178E10709E06DF5"></div>

                   </div>

             </div>

                                </div>

          </div>



            <div class="row mb-3">

                                <div class="col-12">

                                    <div class="row align-items-center">

                                        <div class="col-md-2">

                                            <label for="dc_notes" class="form-label mb-0">%Note%:</label>

                                        </div>

                                        <div class="col-md-10">

                                            <div id="PB4BA98106A5F41ACAC2552D31EEA70D4"></div>

                                        </div>

                                    </div>

                                </div>

                            </div>

                        </div>



                        <!-- Tùy chọn khách hàng tiềm năng -->

                        <div class="mb-4">

                            <h6 class="mb-3"

                                style="color: #198754; font-weight: 600; border-bottom: 2px solid #e9ecef; padding-bottom: 8px;">

                                <i class="bi bi-star"></i> %Options%

                            </h6>



                            <div class="form-check"

                                style="padding: 15px; padding-left: 30px; border-radius: 8px; border: 1px solid #e9ecef;">

                                <input class="form-check-input" type="checkbox" id="isPotentialCustomer"

                                    name="isPotentialCustomer" value="1" style="margin-top: 0.25em;">

                                <label class="form-check-label" for="isPotentialCustomer"

                                    style="margin-left: 8px; font-weight: 500;">

                                    <i class="bi bi-award text-warning me-2"></i>

                                    %ConvertToPotentialCustomer%

                                </label>

                                <small class="form-text  d-block" style="margin-top: 5px; margin-left: 32px;">

                                    %MarkForSpecialTracking%

                                </small>

                            </div>

                        </div>



                        <!-- Image Upload Section -->

                        <div class="form-group mb-3 img-upload-section">

                            <label class="form-label">Kéo thả hình ảnh để AI phân tích:</label>

                            <div id="imageDropZone" style="

                                border: 2px dashed #198754;

     border-radius: 8px;

                                padding: 30px;

          text-align: center;

  cursor: pointer;

                                transition: all 0.3s ease;

                                min-height: 120px;

                                display: flex;

                                align-items: center;

                                justify-content: center;

      flex-direction: column;

                            ">

                                <i class="bi bi-cloud-arrow-up"

                                    style="font-size: 2rem; color: #198754; margin-bottom: 10px;"></i>

                                <p style="margin: 0; color: #198754; font-weight: 500;">Kéo thả hình ảnh tại đây</p>

                                <p style="margin: 5px 0 0 0; color: #64748b; font-size: 13px;">hoặc click chọn</p>

                                <input type="file" id="imageInput"

                                    accept=".jpg,.jpeg,.png,.webp,.gif,.heic,image/jpeg,image/png,image/webp,image/gif,image/heic"

                                    style="display: none;">

                            </div>

                            <div id="imagePreviewContainer"

                                style="margin-top: 10px; display: none; position: relative;">

   <img id="imagePreview" style="

         max-width: 100%;

            max-height: 200px;

                    border-radius: 8px;

                  border: 1px solid #e9ecef;

                                ">

                                <div id="imageProcessingIndicator" class="image-processing-indicator">

                                    <div class="mini-spinner"></div>

                                    <span style="font-size: 13px;">Đang xử lý...</span>

                                </div>

                                <button type="button" class="btn btn-sm btn-danger mt-2 CRM_DataCollection_ClearImage"

                                    style="width: 100%;">

                                    <i class="bi bi-trash"></i> Xóa hình ảnh

                                </button>

                            </div>

                        </div>



                    </form>

                </div>

                <div class="modal-footer">

                    <button type="button" class="btn btn-danger CRM_DataCollection_BtnDelete"

                        id="btnDeleteDataCollection" style="display:none; margin-right: auto;">

                        <i class="bi bi-trash"></i> %Delete%

                    </button>

                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">%Cancel%</button>

                    <button type="button" class="btn btn-primary CRM_DataCollection_BtnSave"

                        id="btnSaveDataCollection">%SaveContactInfo%</button>

                </div>

            </div>

        </div>

    </div>



    <script>

        (() => {

            let IsloadFilter = false;

            let IsloadFilterTab = false;

            let api = true;

            let dataCollectionList = [];

            let currentEditId = null;

            let originalPhoneNumberValue = null;

            let originalTaxCodeValue = null;

            let isProcessingImage = false; // Cờ chống paste lặp lại

            let AccessKey = ''''; // Permission level (FULLACCESS, MANAGER, USER, CUSTOMER)

            let _pageCache = {};

            let dataStore_GridKC = null;

            let statusList = [];

              // Hàm validate email

            const validateEmail = (value) => {

                if (!value || value.trim() === "") {

                    return true;



                }

                const pattern = /^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

                if (!pattern.test(value.trim())) {

                    uiManager.showAlert({ type: "error", message: "%InvalidEmail%" });

                    return false;

                }

                return true;

            };

             // Hàm validate số điện thoại

            const validatePhoneNumber = async (value) => {

                if (!value || value.trim() === "") {

                    return true;

                }

                // const pattern = /^[0-9]{10,11}$/;

                // if (!pattern.test(value.trim())) {

                //     uiManager.showAlert({ type: "error", message: "%InvalidPhoneNumber%" });

                //     return false;

                // }



                if (!isVietnamesePhoneNumberValid(value)) {

                    uiManager.showAlert({ type: "error", message: "%InvalidPhoneNumber%" });

                    return false;

                }



                // Check duplicate phone number

                const normalizedValue = value.trim();



                // Nếu đang edit và phone number giống với giá trị gốc thì pass

                if (

                    currentRecordID_CRM_CustomerID &&

                    originalPhoneNumberValue &&

                    normalizedValue === originalPhoneNumberValue

                ) {

                    return true;

                }



                // Call API check duplicate

                const params = ["PhoneNumber", normalizedValue];



                if (currentRecordID_CRM_CustomerID) {

                    params.push("ExcludeCRM_CustomerID", currentRecordID_CRM_CustomerID);

                }



                return new Promise((resolve) => {

                    AjaxHPAParadise({

                        data: {

                            name: "sp_KPIgetDataCollectionCheckTaxCode",

                            param: params

                        },

                        success: function (data) {

                            try {

                                if (typeof data === "string" && data) {

                                    data = data.includes("{")

                                        ? data

                                        : EncryptionStringDecryption(data);

                                }



          const dataObject = JSON.parse(data);

                                const exists = dataObject?.data?.[0]?.length > 0;



                                if (exists) {

                                    uiManager.showAlert({ type: "error", message: "%PhoneNumberExists%" });

                                    resolve(false);

                                } else {

                                    resolve(true);

                                }

                       } catch (e) {

                                resolve(true); // fail-safe

                            }

                        },

                        error: function () {

                            resolve(true); // fail-safe

                        }

                    });

                });

            };

            window.hpaUtils = window.hpaUtils || {

                removeToneMarks: function (str) {

                    if (!str) return "";

                    return RemoveToneMarks_Js(str);

                },

                highlightText: function (text, search) {

                    if (!search || !text) return text;

                    const regex = new RegExp("(" + search.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + ")", "gi");

                    return text.replace(regex, "<mark class=\"bg-warning fw-bold px-1 rounded\">$1</mark>");

                },

                getInitials: function (name) {

                    if (!name) return "?";

                    const words = name.trim().split(/\s+/);

                    if (words.length >= 2) return (words[0][0] + words[words.length - 1][0]).toUpperCase();

                    return name.substring(0, 2).toUpperCase();

                },

                getColorForId: function (id) {

                    const colors = [

                        { bg: "#e3f2fd", text: "#1976d2" },

                        { bg: "#f3e5f5", text: "#7b1fa2" },

                        { bg: "#e8f5e9", text: "#388e3c" },

                        { bg: "#fff3e0", text: "#f57c00" },

                        { bg: "#fce4ec", text: "#c2185b" }

                    ];

                    return colors[Math.abs(id) % colors.length];

                },

                loadAvatar: function (employeeId, storeImgName, paramImg, callbackFn) {

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

                                callbacks.forEach(cb => { try { cb(url); } catch (e) { } });

                            } else {

                                callbacks.forEach(cb => { try { cb(null); } catch (e) { } });

                            }

                        },

                        error: function () {

                            const callbacks = window.GlobalEmployeeAvatarLoading[idStr]?.callbacks || [];

                            delete window.GlobalEmployeeAvatarLoading[idStr];

                            callbacks.forEach(cb => { try { cb(null); } catch (e) { } });

                        }

                    });

                    return null;

              }

            };



            let DataSource = []



            // load createTime nhân viên



            if (!window.__hpaTextBoxUnderlineStyleInjected) {

                $("<style>")

                    .attr("id", "hpa-textbox-underline-style")

                    .text(`

                        .dx-texteditor.dx-editor-underlined::after {

                         border-bottom-color: #ddd !important;

                        }

                 `)

                    .appendTo("head");

                window.__hpaTextBoxUnderlineStyleInjected = true;

            }



            let InstancePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = null;

            let $containerPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = $("#PB03D8BEAD0934DC2B599C27F771CE2DD");



            let _autoSavePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = false;

            let _readOnlyPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = false;



            let PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDOriginalValue = "";

            let _savingPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = false;

            let PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance = null;



            /* =============== Helper Functions =============== */



            function isValidCustomFunction(func) {

                return func &&

                    func !== "" &&

                    func !== null &&

                    func !== undefined &&

      typeof func === "function";

            }



            function showValidationErrorPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD(message) {

                const $editor = $containerPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.find(".dx-texteditor");

                $editor.addClass("dx-invalid");

                $containerPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.find("input").css({

                    "background-color": "#ffe6e6"

                });

                if (message && message != "" && typeof uiManager !== "undefined" && uiManager.showAlert) {

                    uiManager.showAlert({ type: "error", message: message });

                }

            }



            function hideValidationErrorPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD() {

                const $editor = $containerPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.find(".dx-texteditor");

                $editor.removeClass("dx-invalid");

                $containerPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.find("input").css({

                    "background-color": ""

                });

            }



            async function saveValuePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD() {

                if (_savingPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD) return;



                const newVal = PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("value");



                if (newVal === PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDOriginalValue) {

                    _savingPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = false;

                    return;

                }



                try {

                    _savingPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = true;



                    if (1 === 1) {

                        if (!newVal || newVal.trim() === "") {

                            const errorMsg = window.ValidationEngine && window.ValidationEngine.getRequiredMessage

                                ? window.ValidationEngine.getRequiredMessage()

                                : "Trường này là bắt buộc";



                            showValidationErrorPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD(errorMsg);

                            _savingPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = false;



                            setTimeout(() => {

        $containerPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.find("input").focus();

                            }, 50);



                            return;

                        }

                    }



                    // Custom validation check

                    if (isValidCustomFunction(validatePhoneNumber)) {

                        try {

                            const validationResult = await validatePhoneNumber(newVal);

                            if (!validationResult) {

                                showValidationErrorPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD();

                                _savingPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = false;

                                return;

                            }

                        } catch (validationError) {

                            const errorMsg = typeof validationError === "string" ? validationError : "Validation failed";

                            showValidationErrorPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD();

                            _savingPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = false;

                            return;

                        }

                    }



                    hideValidationErrorPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD();

                    if (_autoSavePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD) {

                        const dataJSON = JSON.stringify(["315923535", ["PhoneNumber"], [newVal]]);



                        let id1 = window.currentRecordID_CRM_CustomerID;

                        if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {

                            id1 = cellInfo.data["CRM_CustomerID"] || id1;

                        }

   let currentRecordIDValue = [id1];

                        let currentRecordID = ["CRM_CustomerID"];



                        if ("" && "".trim() !== "") {

                            let id2 = currentRecordID_;

                            if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {

                                id2 = cellInfo.data[""] || id2;

                            }

                            currentRecordIDValue.push(id2);

                            currentRecordID.push("");

                        }



                        const idValsJSON = JSON.stringify([currentRecordIDValue, currentRecordID]);



                        const json = await saveFunction(dataJSON, idValsJSON);



                        const dtError = json.data[json.data.length - 1] || [];

                        if (dtError.length > 0 && dtError[0].Status === "ERROR") {

                            uiManager.showAlert({ type: "error", message: dtError[0]?.Message || "%SaveErrorMessage%" });

                            _savingPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = false;

                            return;

                        }



                        if (GridKC != 0 && GridKC != null && GridKC != "" && window.hpaSharedGridDataSources["GridKC"]) {

                            try {

                                let KeyRowTable = window.currentClicked_GridKC;

                                console.log("KeyRowTable:", KeyRowTable);

                                if (KeyRowTable != null && KeyRowTable != undefined) {

                                    var updateData = {};

                                    updateData["RowID"] = KeyRowTable;

                                    updateData["PhoneNumber"] = InstancePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.option("value");



                                    // 2. Thực hiện update Shared Grid

                                    // Vì dùng RowID, Grid sẽ tự tìm dòng cực nhanh

                                    window.updateSharedGridRow("GridKC", updateData);



                                    // 3. Cập nhật biến DataSource cục bộ (Dùng RowID để tìm)

                                    if (typeof DataSource !== "undefined" && Array.isArray(DataSource)) {

                                        // Chỉ cần 1 dòng filter duy nhất, không cần check hasKey2 rườm rà nữa

                                        var ds = DataSource.filter(item => item.RowID === KeyRowTable);



                                        if (ds && ds.length > 0) {

                                            ds[0]["PhoneNumber"] = updateData["PhoneNumber"];



                                            // Nếu bạn đang sửa chính là 1 trong các ID cấu thành RowID

                                            // Cần cập nhật lại RowID mới nếu cần thiết (tùy logic nghiệp vụ)



                                        }

                                    }

                                }



                                var updateData = {};

                                updateData["CRM_CustomerID"] = currentRecordIDValue[0];

                                updateData["PhoneNumber"] = InstancePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.option("value");



                                var id2FieldName = "";



                                var hasKey2 = id2FieldName && id2FieldName !== "" && id2FieldName.indexOf("%") === -1;



                                if (hasKey2) {

                                    if (currentRecordIDValue.length > 1 && currentRecordIDValue[1] !== undefined) {

                                        updateData[id2FieldName] = currentRecordIDValue[1];

                                    }

                                }



                                // Thực hiện update shared grid

                                window.updateSharedGridRow("GridKC", updateData);



                                // Kiểm tra và cập nhật biến DataSource cục bộ

                                if (typeof DataSource !== "undefined" && Array.isArray(DataSource)) {

                                    var ds;

                                    if (!hasKey2) {

                                        // Trường hợp 1 khóa

                                        ds = DataSource.filter(item => item["CRM_CustomerID"] === updateData["CRM_CustomerID"]);

                                    } else {

                                        // Trường hợp 2 khóa

                                        ds = DataSource.filter(item =>

                                            item["CRM_CustomerID"] === updateData["CRM_CustomerID"] &&

                                            item[id2FieldName] === updateData[id2FieldName]

                                        );

                                    }



                                    if (ds && ds.length > 0) {

                                        ds[0]["PhoneNumber"] = updateData["PhoneNumber"];

                                    }

                                }

                            } catch (dsErr) {

                                console.warn("[Grid Sync] TextBox PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD: Không thể sync shared grid data source:", dsErr);

                            }

                        }

                    }











                    PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDOriginalValue = newVal;



                    if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {

                        try {

                            const grid = cellInfo.component;

                            grid.cellValue(cellInfo.rowIndex, "PhoneNumber", newVal);

                            grid.repaint();

                        } catch (syncErr) {

                            console.warn("[Grid Sync] Không thể sync grid:", syncErr);

                        }

                    }



                } catch (err) {

                    console.warn("[PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD] Có lỗi:", err);

                } finally {

                    setTimeout(function () {

                        _savingPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = false;

                    }, 100);

                }

            }



            /* =============== Create UI =============== */



            PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance = $("<div>")

                .appendTo($containerPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD)

                .dxTextBox({

                    value: "",

                    width: "100%",

                    tabIndex: 6,

                    placeholder: "%phoneNumber%",

                    readOnly: _readOnlyPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD,

                    stylingMode: "underlined",

                    inputAttr: {

                        style: "font-size: inherit; font-weight: inherit; border-bottom-color: #ddd;"

                    },

                    onValueChanged: function (e) {

                        if (e.value != null && String(e.value).trim() !== "") {

                            // xử lí format số điện thoại - bỏ khoảng trắng và ký tự đặc biệt

                            const phoneValue = String(e.value);

                            const sanitized = phoneValue.replace(/[\s\-\(\)\.\,]/g, '''');

                            if (sanitized !== phoneValue) {

                                e.component.option("value", sanitized);

                            }



                            hideValidationErrorPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD();

                        }

                    },

                    onFocusOut: function (e) {

                        if (_readOnlyPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD) return;



                        const $input = $containerPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.find("input");

                        const currentValue = $input.val();



                        // Validate required

                        if (1 === 1) {

                            if (!currentValue || currentValue.trim() === "") {

                                const errorMsg = window.ValidationEngine && window.ValidationEngine.getRequiredMessage

                                    ? window.ValidationEngine.getRequiredMessage("%phoneNumber%")

                                    : "%phoneNumber% là bắt buộc";



                                showValidationErrorPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD(errorMsg);

                                return;

                            }

                        }



                        hideValidationErrorPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD();

                        // 👉 chỉ save khi value thay đổi

                        if (currentValue !== PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDOriginalValue) {

                            PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("value", currentValue);

                            saveValuePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD();

                            PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDOriginalValue = currentValue;

                        }

                    },

                    onKeyDown: function (e) {

                        if (e.event.key === "Enter") {

                            e.event.preventDefault();



                            const currentValue = $containerPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.find("input").val();



                            if (1 === 1) {

                                if (!currentValue || currentValue.trim() === "") {

                const errorMsg = window.ValidationEngine && window.ValidationEngine.getRequiredMessage

                                     ? window.ValidationEngine.getRequiredMessage("%phoneNumber%")

                                        : "%phoneNumber% là bắt buộc";



                                    showValidationErrorPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD(errorMsg);

                                    return;

                                }

                            }



                            hideValidationErrorPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD();

                            PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("value", currentValue);

                            saveValuePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD();

                        }

                        if (e.event.key === "Escape") {

                            e.event.preventDefault();

                            PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("value", PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDOriginalValue);

                            hideValidationErrorPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD();

                            $containerPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.find("input").blur();

                        }

                    }

                })

                .dxTextBox("instance");



            /* =============== Public API =============== */

            InstancePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = {

                setValue: function (val) {

                    const displayVal = (val == null || val === "") ? "" : String(val);

                    PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDOriginalValue = displayVal;

                    PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("value", displayVal);

                },

                getValue: function () {

                    return PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("value");

       },

                option: function (name, value) {

                    if (value !== undefined) {

      PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option(name, value);



                        if (name === "value") {

                            const val = value || "";

                            PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDOriginalValue = val;



                            if (

                                this.__cellInfo &&

                                typeof this.__cellInfo.setValue === "function" &&

                                this.__cellInfo.component

                            ) {

                                try {

                                    this.__cellInfo.setValue(val);

                                } catch (e) {

                                    console.warn("[hpaControlText] Grid sync skipped", e);

                                }

                            }

                        }

                    } else {

                        return PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option(name);

                    }

                },

                repaint: function () {

                    PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.repaint();

                },

                clearValidationError: function () {

                    hideValidationErrorPhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD();

                },

                _suppressValueChangeAction: function () {

                    if (PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance._suppressValueChangeAction) {

                        PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance._suppressValueChangeAction();

                    }

                },

       _resumeValueChangeAction: function () {

                    if (PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance._resumeValueChangeAction) {

                        PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance._resumeValueChangeAction();

                    }

                }

            };



            '

                + (select loadUI from tblCommonControlType_Signed where UID = 'P4510BE8E25E842D286E3E8C0ACAE8E7E')

            + (select loadUI from tblCommonControlType_Signed where UID = 'PF18C5687EA514B69BFBA6BCA32E2D629')



            + (select loadUI from tblCommonControlType_Signed where UID = 'PA57E3C14412E427C8178E10709E06DF5')

            + (select loadUI from tblCommonControlType_Signed where UID = 'P87BE9D5708F947458C9F37FA1B601478')



            + (select loadUI from tblCommonControlType_Signed where UID = 'P93D36D79837B4A17A1D44F5B262DA097')

            + (select loadUI from tblCommonControlType_Signed where UID = 'PCEA494414F404AF7AD9BFCE81F15F90E')

            +(select loadUI from tblCommonControlType_Signed where UID = 'P4CA52B6C787249E68C408A05419C0C77')

            +(select loadUI from tblCommonControlType_Signed where UID = 'P505719422EBB4A44AA7EB825DC4B8126')

            +(select loadUI from tblCommonControlType_Signed where UID = 'PE9DF5833F12044D78B19C7B41306E4C6')

            --+ (select loadUI from tblCommonControlType_Signed where UID = 'PB03D8BEAD0934DC2B599C27F771CE2DD')

            +(select loadUI from tblCommonControlType_Signed where UID = 'P0ED76598CC6C42B182C977574DB3960A')

            +(select loadUI from tblCommonControlType_Signed where UID = 'PF09EBAE4C6DA4BE3B1A79BAF021AC73C')

            +(select loadUI from tblCommonControlType_Signed where UID = 'P9A288D9BFC0A4460B0D404DE8E29E285')

            +(select loadUI from tblCommonControlType_Signed where UID = 'P8FD2ACDEFBB247A78E44E81876FF013A')

            +(select loadUI from tblCommonControlType_Signed where UID = 'P89D4A2BDA88F4F8A81EC9926B84F0D11')

            + (select loadUI from tblCommonControlType_Signed where UID = 'PB4BA98106A5F41ACAC2552D31EEA70D4')

            + (select LoadUI from tblCommonControlType_Signed where UID = 'P690E6110CC9042F0B7E64B4A3D7C4DF1')

            + (select LoadUI from tblCommonControlType_Signed where UID = 'PDF424130C28F4C1298C81F737570F7A7')

            +N'





            function configureGridToolbar() {

                if (IsloadFilter) return;

                const gridInstance = InstanceGridKCP89D4A2BDA88F4F8A81EC9926B84F0D11;

                if (!gridInstance) return;

                IsloadFilter = true;



                let activeStatus = (

                    window.activeStatusFilter !== undefined &&

                    window.activeStatusFilter !== null &&

                    String(window.activeStatusFilter).trim() !== "" &&

                    String(window.activeStatusFilter).toLowerCase() !== "null"

                ) ? String(window.activeStatusFilter) : null;

                let $statusRow = null;

                let _statusClickLocked = false;

                const _statusClickLockMs = 700;



                function applyFilter() {

                    window.activeStatusFilter = activeStatus;

                    ReloadData();

                }





                // ---- Configure Toolbar Items ----

                gridInstance.option("toolbar", {

                    items: [

                        {

                            location: ''before'',

                            template: function (data, index, element) {

                                $statusRow = $(''<div class="crm-status-row" style="display:flex;flex:1 1 auto;min-width:0;">'');

                                const $statusWrapper = $(''<div style="display:flex;flex-direction:column;gap:6px;width:100%;">'');

                         const $statusFilterRow = $(''<div class="dc-status-filter-row d-flex" style="display:flex;align-items:center;gap:5px;flex-wrap:nowrap;width:100%;min-width:0;overflow:visible;">'');

                                window.__dcStatusFilterRow = $statusFilterRow;



                                function makeStatusPill(label, value) {

                                    const isAll = value === null;

                                    const valueStr = value == null ? null : String(value);

                                    const $p = $(''<button type="button" data-status="'' + value + ''" class="crm-status-pill">'').text(label);

                                    const isActive = (activeStatus == null && isAll) || (activeStatus != null && valueStr === String(activeStatus));

                                    if (isActive) $p.addClass(''status-pill-active'');



                                    $p.on(''click'', function () {

                                        if (_statusClickLocked) {

                                            return;

                                        }

                                        _statusClickLocked = true;

                                        setTimeout(function () {

                                            _statusClickLocked = false;

                                        }, _statusClickLockMs);



                                        if (value != null) {

                                            $("#pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5").prop("checked", false);

                                        }



                                        const $oldActive = $statusRow.find(''.crm-status-pill.status-pill-active'');

                                        const oldIndex = $statusRow.find(''.crm-status-pill'').index($oldActive);

                                        const newIndex = $statusRow.find(''.crm-status-pill'').index(this);

                                        const slideDir = newIndex > oldIndex ? ''left'' : ''right'';



                                        $statusRow.find(''.crm-status-pill'').removeClass(''status-pill-active slide-in-left slide-in-right'');

                                        const $newActive = $(this).addClass(''status-pill-active'');

                                        $newActive.addClass(slideDir === ''left'' ? ''slide-in-left'' : ''slide-in-right'');

                                        setTimeout(() => $newActive.removeClass(''slide-in-left slide-in-right''), 400);



                                        activeStatus = valueStr;

                                        applyFilter();

                                    });

                                    return $p;

                                }



                 $statusRow.append(makeStatusPill(''Tất cả'', null));



                                function loadStatusPills() {

                                    statusList = DataSource_Status_Customer;

                                    const src = statusList.sort((a, b) => (a.Priority || 0) - (b.Priority || 0));

                                    if (src.length === 0) return false;

                                    const seen = {};

                                    src.forEach(function (item) {

                                        const name = item.Name || item.StatusName || item.name;

                                        const id = item.ID;

                                        if (name && !seen[name]) {

                                            seen[name] = true;

                                            $statusRow.append(makeStatusPill(name, id));

                                        }

                                    });



                                    // Nếu có activeStatus từ page trước, đảm bảo pill tương ứng được chọn.

                                    if (activeStatus != null) {

                const $match = $statusRow.find(''.crm-status-pill[data-status="'' + String(activeStatus) + ''"]'');

                                        if ($match.length > 0) {

                                            $statusRow.find(''.crm-status-pill'').removeClass(''status-pill-active'');

                                            $match.addClass(''status-pill-active'');

                                        } else {

                                            activeStatus = null;

                                            window.activeStatusFilter = null;

                                            $statusRow.find(''.crm-status-pill'').removeClass(''status-pill-active'');

                                            $statusRow.find(''.crm-status-pill[data-status="null"]'').addClass(''status-pill-active'');

                                        }

                                    }

                                    return true;

                                }



                                if (!loadStatusPills()) {

                                    let attempts = 0;

                                    const poll = setInterval(function () {

                                        attempts++;

                                        if (loadStatusPills() || attempts >= 10) clearInterval(poll);

                                    }, 300);

                                }



                                $statusFilterRow.append($statusRow);

                                $statusWrapper.append($statusFilterRow);



                                if (window.EmployeeID_Login) {

                                    const currentEmployeeValue = String(InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.option(''value'') || '''');

                                    const isMyDataChecked = currentEmployeeValue

                                        .split('','')

                                        .map(function (x) { return x.trim(); })

                                        .filter(function (x) { return x !== ''''; })

                                        .indexOf(String(window.EmployeeID_Login)) >= 0;



                                    const $quickMyData = $(''<label style="display:flex;align-items:center;gap:6px;cursor:pointer;font-size:11px;color:gray;padding-left:8px;user-select:none;white-space:nowrap;margin-top:5px;">'')

                                        .append($(''<input type="checkbox" id="quickMyDataP1D1261311DFB4BDABD06DE5867CFF5B5" style="width:14px;height:14px;accent-color:#198754;margin-top:-3px;cursor:pointer;">'').prop(''checked'', isMyDataChecked))

                                        .append(''Xem của tôi'');



                                    const $quickMyDataRow = $(''<div class="dc-quick-mydata-row" style="display:flex;align-items:center;gap:6px;width:100%;">'');



                                    $quickMyData.find(''input'').on(''change'', function () {

                                        const checked = $(this).is('':checked'');

                                        if (checked) {

                                            InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.option(''value'', window.EmployeeID_Login);

                                        } else {

                                            InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.option(''value'', null);

                                        }



                                        $(''#pillMyDataP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', checked);

                                        filterDataCollection();

                                    });



                                    $quickMyDataRow.append($quickMyData);

                                    $statusWrapper.append($quickMyDataRow);

                       }



                                $(element).append($statusWrapper);

                            }

                        },

                        // 2. Advanced Filter Panel

                        {

                            location: "before",

                            template: function (data, index, element) {

                                const $container = $(''<div class="dc-filter" style="display:flex;align-items:center;gap:8px;flex-wrap:nowrap;box-sizing:border-box;flex:0 0 auto;white-space:nowrap;">'');



                                const $pill = $(''<button style="display: inline-flex;align-items: center;gap: 2px;border-radius: 50px;padding: 6px 14px;font-size: 0.85rem;font-weight: 600;border: 1px solid #e0e0e0;background: transparent;cursor: pointer;transition: all 0.2s;white-space: nowrap;color: inherit;" class="filter-pill-btn-P1D1261311DFB4BDABD06DE5867CFF5B5 filter-pill-btn">''

                                    + ''<i class="bi bi-funnel"></i>''

                                    + ''''

                                    + ''<i class="bi bi-chevron-down pill-chevron-P1D1261311DFB4BDABD06DE5867CFF5B5"></i>''

                                    + ''</button>'');



                                let _ignorePillAutoCloseUntil = 0;



                                const $panel = $(''<div class="filter-pill-panel-P1D1261311DFB4BDABD06DE5867CFF5B5 filter-pill-dropdown">'')

                                    .css({

                                        display: ''none'',

                                        position: ''absolute'',

                                        zIndex: 9999,

                                        top: ''calc(100% + 6px)'',

                                        left: 0,

                                        borderRadius: ''12px'',

                                        padding: ''16px'',

                                        minWidth: ''350px'',

                                        maxWidth: ''95vw'',

                                        boxSizing: ''border-box''

                                    });



                                function applyPanelThemeP1D1261311DFB4BDABD06DE5867CFF5B5() {

                                    const dark = document.documentElement.getAttribute(''data-bs-theme'') === ''dark''

                   || document.body.getAttribute(''data-bs-theme'') === ''dark'';

          $panel.css({



                                      background: dark ? ''#1e293b'' : ''white'',

                                        border: dark ? ''0.5px solid #334155'' : ''0.5px solid #ddd'',

                                        boxShadow: dark ? ''0 4px 20px rgba(0,0,0,0.5)'' : ''0 4px 20px rgba(0,0,0,0.13)''

                                    });

                                }



                                applyPanelThemeP1D1261311DFB4BDABD06DE5867CFF5B5();



                                const themeObserverP1D1261311DFB4BDABD06DE5867CFF5B5 = new MutationObserver(function (mutations) {

                                    mutations.forEach(function (m) {

                                        if (m.attributeName === ''data-bs-theme'') {

                                            applyPanelThemeP1D1261311DFB4BDABD06DE5867CFF5B5();

                                        }

                                    });

                                });

                                themeObserverP1D1261311DFB4BDABD06DE5867CFF5B5.observe(document.documentElement, { attributes: true });

                                themeObserverP1D1261311DFB4BDABD06DE5867CFF5B5.observe(document.body, { attributes: true });





         const $dateSection = $(''<div style="margin-bottom:14px;">'');

                                $dateSection.append($(''<div style="font-size:11px;font-weight:600;letter-spacing:.5px;margin-bottom:7px;"><i class="bi bi-calendar-range me-1"></i>KHOẢNG THỜI GIAN</div>''));



                                const $quickRow = $(''<div style="display:flex;gap:6px;flex-wrap:wrap;margin-bottom:8px; margin-top:8px;">'');

                                const quickItems = [[''Hôm nay'', ''today''], [''Tuần này'', ''week''], [''Tháng này'', ''month'']];

                                const icons = [''bi-calendar-check'', ''bi-calendar-week'', ''bi-calendar-month''];

                                quickItems.forEach(function (item, index) {

                                    const $qBtn = $(''<button>'')

                                        .html(`<i class="bi ${icons[index]} me-1"></i>${item[0]}`)

                                        .css({ padding: "4px 10px", borderRadius: "16px", border: "1px solid #ddd", fontSize: "12px", cursor: "pointer" });

                                    $qBtn.on(''click'', function () {

                          $quickRow.find(''button'').css({ background: "", color: "", borderColor: "#ddd", fontWeight: "400" });

                                        $(this).css({ background: "#eef4ff", color: "#337ab7", borderColor: "#337ab7", fontWeight: "500" });

                                        const today = new Date();

                                        let from, to = today.toISOString().split(''T'')[0];

                                        if (item[1] === ''today'') {

    from = to;

                                        } else if (item[1] === ''week'') {

                                            const d = new Date(today);

                                            d.setDate(d.getDate() - ((d.getDay() + 6) % 7));

                                            from = d.toISOString().split(''T'')[0];

                                        } else {

                                            from = new Date(today.getFullYear(), today.getMonth(), 1).toISOString().split(''T'')[0];

                                        }

                                        try { InstanceFromDateP4510BE8E25E842D286E3E8C0ACAE8E7E.option(''value'', from); } catch (e) { }

                                        try { InstanceToDatePF18C5687EA514B69BFBA6BCA32E2D629.option(''value'', to); } catch (e) { }

                                        $(''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);

                                  });

                                    $quickRow.append($qBtn);

                    });





                                const $dateRow = $(''<div style="display:flex;gap:8px;align-items:flex-end;">'');



                                const $fromWrap = $(''<div style="flex:1;">'')

                                    .append($(''<div style="font-size:11px;margin-bottom:3px;">Từ</div>''))

                                    .append($(''<div id="pillFromDateContainerP4510BE8E25E842D286E3E8C0ACAE8E7E" style="min-height:32px;"></div>''));



                                const $arrow = $(''<div style="font-size:13px;color:#aaa;padding-bottom:9px;">Đến</div>'');



                                const $toWrap = $(''<div style="flex:1;">'')

                                    .append($(''<div style="font-size:11px;margin-bottom:3px;">Ðến</div>''))

                                    .append($(''<div id="pillToDateContainerPF18C5687EA514B69BFBA6BCA32E2D629" style="min-height:32px;"></div>''));



                                $dateRow.append($fromWrap, $arrow, $toWrap);

                                $dateSection.append($dateRow);

                                $dateSection.append($quickRow);

   $panel.append($dateSection);





                                const $empSection = $(''<div style="margin-bottom:14px;">'');

                                $empSection.append($(''<div style="font-size:11px;font-weight:600;letter-spacing:.5px;margin-bottom:7px;"><i class="bi bi-person me-1"></i>NHÂN VIÊN</div>''));

                                const $empContainer = $(''<div id="pillEmpContainerP1D1261311DFB4BDABD06DE5867CFF5B5" style="min-height:36px;"></div>'');

                                $empSection.append($empContainer);

                                $panel.append($empSection);



                                const $chkSection = $(''<div style="display:flex;flex-direction:column;gap:9px;margin-bottom:16px;">'');



                                const $lblViewAll = $(''<label style="display:flex;align-items:center;gap:8px;cursor:pointer;font-size:13px;">'')

                                    .append($(''<input type="checkbox" id="pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5" style="width:15px;height:15px;accent-color:#198754;cursor:pointer;">''))

                                    .append(''%ViewAllDays%'');

                                $chkSection.append($lblViewAll);



                                const $lblKPI = $(''<label style="display:flex;align-items:center;gap:8px;cursor:pointer;font-size:13px;">'')

                                    .append($(''<input type="checkbox" id="pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5" style="width:15px;height:15px;accent-color:#198754;cursor:pointer;">''))

                                    .append(''Dữ liệu tính KPI'');

                                $chkSection.append($lblKPI);



                                $panel.append($chkSection);



                                $(document).on(''change'', ''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'', function () {

                                    const checked = $(this).is('':checked'');

                                    if (checked) {

                                        $(''#pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);

                                        hasKPIDate = false;

                                    }

                                    $(''#pillFromDateP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''disabled'', checked).css(''opacity'', checked ? ''0.4'' : ''1'');

                                    $(''#pillToDateP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''disabled'', checked).css(''opacity'', checked ? ''0.4'' : ''1'');

                                });



                                $(document).on(''change'', ''#pillMyDataP1D1261311DFB4BDABD06DE5867CFF5B5'', function () {

                                    const checked = $(this).is('':checked'');

                     if (checked) {

                                        InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.option(''value'', window.EmployeeID_Login);

                                    } else {

                                        InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.option(''value'', null);

                                    }



                                    $(''#quickMyDataP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', checked);

                                });



                                $(document).on(''change'', ''#pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5'', function () {

                                    const checked = $(this).is('':checked'');

                                    if (checked) {

                                        $(''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);

                                        $(''#pillFromDateP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''disabled'', false).css(''opacity'', ''1'');

                                        $(''#pillToDateP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''disabled'', false).css(''opacity'', ''1'');

                                        hasKPIDate = true;

              } else {

                                        hasKPIDate = false;

                                    }

                                });



                                const $footer = $(''<div style="display:flex;justify-content:space-between;border-top:0.5px solid #eee;padding-top:12px;">'');

                                $(''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);

                                $(''#pillMyDataP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);

                                InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.option(''value'', null);

                                $(''#pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);

                                hasKPIDate = false;

                                $(''#pillFromDateP1D1261311DFB4BDABD06DE5867CFF5B5'').val('''').prop(''disabled'', false).css(''opacity'', ''1'');

                                $(''#pillToDateP1D1261311DFB4BDABD06DE5867CFF5B5'').val('''').prop(''disabled'', false).css(''opacity'', ''1'');

                                $quickRow.find(''button'').css({ borderColor: "#ddd", fontWeight: "400" });



                                const $applyBtn = $(''<button style="padding:6px 16px;border-radius:6px;border:none;background:#198754;color:white;font-size:12px;cursor:pointer;font-weight:500;">? Áp dụng</button>'');

                                $applyBtn.on(''click'', function () {

                                    $panel.hide();

                                    $pill.find(''.pill-chevron'').css(''transform'', '''');

                                    filterDataCollection();

                                });



                                try {

                                    $footer.append($resetBtn, $applyBtn);

                                } catch (error) {

                                    $footer.append($applyBtn);

                                }

                                $panel.append($footer);



                                $pill.on(''click'', function (e) {

                                    e.stopPropagation();

                                    const visible = $panel.is('':visible'');

                                    $panel.toggle(!visible);

                                    $(this).find(''.pill-chevron'').css(''transform'', !visible ? ''rotate(180deg)'' : '''');

                                });



                                $(document).off(''mousedown.pillFilterOverlayGuardP1D1261311DFB4BDABD06DE5867CFF5B5'').on(''mousedown.pillFilterOverlayGuardP1D1261311DFB4BDABD06DE5867CFF5B5'', function (e) {



                                    const $target = $(e.target);

                                    if ($target.closest(''.dx-overlay-wrapper, .dx-dropdowneditor-overlay, .dx-popup-wrapper, .dx-overlay-content, .dx-popup-content'').length) {

                                        // Giữ panel mở một nhịp ngắn sau thao tác popup (X/Lưu/Hủy)

                                        _ignorePillAutoCloseUntil = Date.now() + 450;

                                    }

                                });



                                $(document).off(''click.pillFilterP1D1261311DFB4BDABD06DE5867CFF5B5'').on(''click.pillFilterP1D1261311DFB4BDABD06DE5867CFF5B5'', function (e) {

                                    if (Date.now() < _ignorePillAutoCloseUntil) {

                                        return;

                                    }



                                    const $target = $(e.target);

                                    const clickedInsidePill = $target.closest(''.filter-pill-panel-P1D1261311DFB4BDABD06DE5867CFF5B5, .filter-pill-btn-P1D1261311DFB4BDABD06DE5867CFF5B5'').length > 0;

                                    const clickedInsideDxOverlay = $target.closest(''.dx-overlay-wrapper, .dx-dropdowneditor-overlay, .dx-popup-wrapper'').length > 0;



                                    // Giữ panel mở khi đang thao tác popup DevExpress (vd: chọn nhân viên).

                                    if (!clickedInsidePill && !clickedInsideDxOverlay) {

                                        $panel.hide();

                                        $pill.find(''.pill-chevron'').css(''transform'', '''');

                                    }

                                });



                                const $pillWrapper = $(''<div style="position:relative;display:inline-block;flex:0 0 auto;">'').append($pill, $panel);

                                $container.append($pillWrapper);



                                const $statusFilterRow = window.__dcStatusFilterRow;

                                if ($statusFilterRow && $statusFilterRow.length) {

                                    $statusFilterRow.append($container);

                                } else {

                                    $(element).parent().prepend($container);

                                }



                                setTimeout(function () {

                                    // window.TypeKPIFilter 1: data || 2; take care

                                    if (window.FromDateKPI && window.ToDateKPI) {

                                        $(''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);

                                        if (window.TypeKPIFilter == 1) {

                                            $(''#pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', true);

                                        } else {

                                            $(''#pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);

                                        }

                                        try { InstanceFromDateP4510BE8E25E842D286E3E8C0ACAE8E7E.option(''value'', window.FromDateKPI); } catch (e) { }

                                        try { InstanceToDatePF18C5687EA514B69BFBA6BCA32E2D629.option(''value'', window.ToDateKPI); } catch (e) { }

                                    } else {

                                        $(''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', true);

  $(''#pillFromDateP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''disabled'', true).css(''opacity'', ''0.4'');

                                        $(''#pillToDateP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''disabled'', true).css(''opacity'', ''0.4'');

                                        const today = new Date();

                                        const firstDay = new Date(today.getFullYear(), today.getMonth(), 1);

                                        $(''#pillFromDateP1D1261311DFB4BDABD06DE5867CFF5B5'').val(firstDay.toISOString().split(''T'')[0]);

                               $(''#pillToDateP1D1261311DFB4BDABD06DE5867CFF5B5'').val(today.toISOString().split(''T'')[0]);

                                        $quickRow.find(''button'').eq(2).css({ background: "#eef4ff", color: "#337ab7", borderColor: "#337ab7", fontWeight: "500" });

                                    }

                                    const fromWrapper = document.getElementById(''pillFromDateContainerP4510BE8E25E842D286E3E8C0ACAE8E7E'');

                                    if (fromWrapper && fromWrapper.children.length === 0) {

                                        const originalFrom = document.getElementById(''P4510BE8E25E842D286E3E8C0ACAE8E7E'');

                                        if (originalFrom) fromWrapper.appendChild(originalFrom);

                                    }

                                    const toWrapper = document.getElementById(''pillToDateContainerPF18C5687EA514B69BFBA6BCA32E2D629'');

                                    if (toWrapper && toWrapper.children.length === 0) {

                                        const originalTo = document.getElementById(''PF18C5687EA514B69BFBA6BCA32E2D629'');

                                        if (originalTo) toWrapper.appendChild(originalTo);

                                    }

                                    const empWrapper = document.getElementById(''pillEmpContainerP1D1261311DFB4BDABD06DE5867CFF5B5'');

                                    if (empWrapper && empWrapper.children.length === 0) {

                                        const originalEmp = document.getElementById(''PDF424130C28F4C1298C81F737570F7A7'');

                                        if (originalEmp && originalEmp.parentElement) {

                                            const empDiv = originalEmp.parentElement.querySelector(''div'');

                                            if (empDiv) empWrapper.appendChild(empDiv);

                                        }

                                    }

                                }, 100);

                            }

                        },

                        {

                            location: "after",

                            widget: "dxButton",

                            options: {

                                icon: "plus",

                                onClick: function () {

                                    if (typeof openDataModal === "function") {

                                        openDataModal();

                                        return;

                                    }



                                    const $btnAdd = $(''.CRM_DataCollection_BtnAdd'');

                                    if ($btnAdd.length) {

                                        $btnAdd.trigger(''click'');

                                    } else {

                                        console.warn(''[dc] Add button action is unavailable after menu switch.'');

                                    }

                                }

                            }

                        },

                        {

                            location: "after",

                            widget: "dxDropDownButton",

                            options: {

                                icon: "overflow",

                                showArrowIcon: false,

                                stylingMode: "text",

                                elementAttr: {

                                    class: "custom-no-circle",

                                    style: "border:none;box-shadow:none;background:transparent;"

                                },

     dropDownOptions: { width: 200 },

                                items: [

                                    { id: "import", text: "Import", iconClass: "bi-download" },

                                    { id: "export", text: "Export", iconClass: "bi-file-earmark-excel" },

                                    { id: "pending", text: "Danh sách bổ xung", iconClass: "bi-list-ul" }

                                ],



                                itemTemplate: function (itemData) {

                                    return $(`

                                            <div style="display: flex; align-items: center; gap: 8px; padding: 4px 2px;">

                                                <i class="bi ${itemData.iconClass}" style="font-size: 16px;"></i>

                                                <span style="font-size: 13px;">${itemData.text}</span>

    </div>

                                        `);

                                },

                                onItemClick: function (e) {

                                    if (e.itemData.id === "import") {

                                        $(''.CRM_DataCollection_BtnImportExcel'').trigger(''click'');

                                    } else if (e.itemData.id === "export") {

                                        $(''.CRM_DataCollection_BtnExportExcel'').trigger(''click'');

                                    } else if (e.itemData.id === "pending") {

                                        $(''#btnPendingList'').trigger(''click'');

                                    }

                                }

                            }

                        },

                        // 3. Column Chooser

                        {

                            location: "after",

                            widget: "dxButton",

                            options: {

                                icon: "columnchooser",

                                hint: "Column Chooser",

                                onClick: function () { gridInstance.columnChooser.show(); }

                            }

                        },

                        // 4. Search Panel

                        {

                            location: "after",

                            name: "searchPanel"

                        }

                    ]

                });

            }



            InstanceGridKCP89D4A2BDA88F4F8A81EC9926B84F0D11.columnOption("CreatedDate", "format", "HH:mm dd/MM/yyyy");

            InstanceCreatedDateP93D36D79837B4A17A1D44F5B262DA097.option("readOnly", true);



            function buildSearchUrl(keyword) {

                const encoded = encodeURIComponent(keyword);

                return encoded

            }



            const originalContentReady = InstanceGridKCP89D4A2BDA88F4F8A81EC9926B84F0D11.option("onContentReady");



            let _filterCollectionDone = false;



            InstanceGridKCP89D4A2BDA88F4F8A81EC9926B84F0D11.option("onContentReady", function (e) {

                if (originalContentReady) originalContentReady(e);



                const visibleRows = e.component.getVisibleRows();



                const keyword = e.component.option("searchPanel.text");





                if (visibleRows.length === 0 && keyword && keyword.trim() !== "" && keyword.length >= 4) {





                    if (!_filterCollectionDone && !window._isScraping) {

                        _filterCollectionDone = true;



                        InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.option("value", null);

                 $(''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', true);

                        $(''#pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);



                        $(''#P4510BE8E25E842D286E3E8C0ACAE8E7E'').prop(''disabled'', true);

                        $(''#P4510BE8E25E842D286E3E8C0ACAE8E7E'').prop(''opacity'', ''0.4'');

                        $(''#PF18C5687EA514B69BFBA6BCA32E2D629'').prop(''opacity'', ''0.4'');



                        // Active status = "Tất cả"

                        window.activeStatusFilter = null;

                        const $statusRow = $(''.crm-status-row'').first();

                        if ($statusRow.length) {

                            $statusRow.find(''.crm-status-pill'').removeClass(''status-pill-active'');

                            const $allPill = $statusRow.find(''.crm-status-pill[data-status="null"]'');

                            if ($allPill.length) {

                                $allPill.addClass(''status-pill-active'');

                            } else {

                 $statusRow.find(''.crm-status-pill'').first().addClass(''status-pill-active'');

                            }

                        }



                        ReloadData(null, null, null, 1, keyword);


                        return;

                    }





                    _filterCollectionDone = false;





                    if (keyword && keyword.trim() !== "" && keyword.length >= 5) {

                        let EmployeeID = InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.option("value");

                        let isViewAll = $(''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'').is('':checked'');



                        if (isViewAll && !EmployeeID) {

                            if (window._isScraping) {

                                _showScrapeBanner("waiting");

                                return;

                            }



                            // Debounce: Clear previous timer and create new one

                            clearTimeout(window._scrapeAPIDebounceTimer);

                            window._scrapeAPIDebounceTimer = setTimeout(() => {

                                callScrapeAPI(keyword);

                            }, 1200);

                        }

                    }



                } else {

                    _filterCollectionDone = false;

                }

            });



            /* -------------------------------------------------------

             * Banner helper

             *   state: "loading" | "waiting" | "done" (count) | "hide"

             * ------------------------------------------------------ */

            function _showScrapeBanner(state, count) {

                const BANNER_ID = "dc-scrape-banner";

                let $b = $("#" + BANNER_ID);



                if (state === "hide") {

                    $b.fadeOut(300, function () { $b.remove(); });

                    return;

                }



                if ($b.length === 0) {

                    $b = $(''<div id="'' + BANNER_ID + ''" style="'' +

                        ''position:fixed; bottom:20px; right:20px; z-index:99999;'' +

                        ''padding:10px 18px; border-radius:20px; font-size:13px;'' +

                        ''box-shadow:0 4px 12px rgba(0,0,0,0.15); display:none;'' +

                        ''display:flex; align-items:center; gap:8px; max-width:360px;'' +

                        ''"></div>'').appendTo("body");

                }



                if (state === "loading") {

                    $b.css({ background: "#67a8ff", color: "#fff" })

                        .html(''<i class="bi bi-arrow-repeat" style="animation:spin 1s linear infinite;"></i> Đang tìm kiếm dữ liệu mới...'')

                        .stop(true).fadeIn(200);



                    // Inject spin animation nếu chưa có

     if (!window.__scrapeBannerStyleInjected) {

                        $(''<style>@keyframes spin{from{transform:rotate(0deg)}to{transform:rotate(360deg)}}</style>'').appendTo("head");

                        window.__scrapeBannerStyleInjected = true;

                    }

                } else if (state === "waiting") {

 $b.css({ background: "#f59e0b", color: "#fff" })

                        .html(''<i class="bi bi-hourglass-split"></i> Hệ thống đang xử lý, vui lòng chờ...'')

                        .stop(true).fadeIn(200);

                    // Tự ẩn sau 2.5s

                  clearTimeout(window._scrapeBannerWaitTimer);

                    window._scrapeBannerWaitTimer = setTimeout(() => _showScrapeBanner("hide"), 2500);

                } else if (state === "done") {

                    const msg = count > 0

                        ? ''<i class="bi bi-check-circle"></i> Đã tìm thấy <b>'' + count + ''</b> công ty mới, vui lòng tìm kiếm lại''

                        : ''<i class="bi bi-info-circle"></i> Không tìm thấy công ty mới nào'';

                    $b.css({ background: count > 0 ? "#198754" : "#6c757d", color: "#fff" })

                        .html(msg)

                        .stop(true).fadeIn(200);

                    // Tự ẩn sau 4s

                    clearTimeout(window._scrapeBannerDoneTimer);

                    window._scrapeBannerDoneTimer = setTimeout(() => _showScrapeBanner("hide"), 4000);

                }

            }



            function callScrapeAPI(keyword) {

                // Đánh dấu đang xử lý TRƯỚC KHI gọi AJAX (callback-based, finally chạy ngay)

                window._isScraping = true;

                _showScrapeBanner("loading");



                //const encoded = buildSearchUrl(keyword);



                AjaxHPAParadise({

                    data: {

                        name: "sp_WebScroperCompanyByDuc",

                        param: [

                            "LoginID", window.UserID,

                            "Keyword", keyword,

                        ]

                    },

                    success: function (data) {

                        try {

                            if (typeof data === "string" && !IsNullOrEmpty(data)) {

                                data = data.includes("{") ? data : EncryptionStringDecryption(data);

                            }

                            const dataObject = JSON.parse(data);

                            const newData = dataObject.data[0];

                            console.log(newData);

                            let addedCount = 0;



                            if (newData && newData.length > 0) {

                                // Lọc trùng TaxCode với data hiện có

                                const existingTaxCodes = new Set(DataSource.map(item => item.TaxCode));

                                const uniqueNew = newData.filter(item =>

                                    item.TaxCode && !existingTaxCodes.has(item.TaxCode)

                                );



                                addedCount = uniqueNew.length;





                                if (uniqueNew.length > 0) {

                                    DataSource.push(...uniqueNew);

                                    api = false;

                                    InstanceGridKCP89D4A2BDA88F4F8A81EC9926B84F0D11.refresh();

                                }



                                _filterCollectionDone = false;

                            }



                            if (addedCount > 0) {

                                uiManager.showAlert({ type: "success", message: "Đã tìm thấy " + addedCount + " công ty mới, vui lòng tìm kiếm lại" });

                            } else {

                                uiManager.showAlert({ type: "error", message: "Không tìm thấy công ty mới nào" });

                            }

                            _showScrapeBanner("hide");

                        } catch (e) {

                            console.error("[callScrapeAPI] Error parsing response:", e);

                            _showScrapeBanner("hide");

                        } finally {

                            window._isScraping = false;

                        }

                    },



                    error: function () {

                        console.warn("[callScrapeAPI] Request failed");

                        _showScrapeBanner("hide");

                        window._isScraping = false;

                    }

         });

            }





            // InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.element().css("width", "100px");

            // InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.element().css("height", "28px");

         // InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.element().find(".dx-texteditor-input").css("height", "20px");

            // InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.element().find(".dx-texteditor-container").css("height", "28px");          



            function isVietnamesePhoneNumberValid(number) {

                number = number.trim().replace(/\s|\./g, '''');



                // Chuẩn hóa đầu số về dạng 0xx

                if (number.startsWith(''+84'')) number = ''0'' + number.slice(3);

                else if (number.startsWith(''84'')) number = ''0'' + number.slice(2);



                // Số di động: 0(3|5|7|8|9)xxxxxxxx → 10 số

                const mobileRegex = /^0(3|5|7|8|9)[0-9]{8}$/;



                // Số bàn: 02xxxxxxxxx → 11 số

                const landlineRegex = /^02[0-9]{9}$/;



                return mobileRegex.test(number) || landlineRegex.test(number);

            }           


            // Load DataSource: sp_CRM_getCompanySize

            if ("sp_CRM_getCompanySize" && "sp_CRM_getCompanySize".trim() !== "") {

                loadDataSourceCommon("CompanySize_ID", "sp_CRM_getCompanySize", function (data) {

                });

            }



            // sp_CRMLoadStatusCustomer



            if ("sp_CRMLoadStatusCustomer" && "sp_CRMLoadStatusCustomer".trim() !== "") {

                loadDataSourceCommon("Status_Customer", "sp_CRMLoadStatusCustomer", function (data) {

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

                        param: ["LoginID", LoginID, "LanguageID", LanguageID, "AccessKey", AccessKey]

                    },

                    success: function (res) {

                        const json = typeof res === "string" ? JSON.parse(res) : res;

                        window[dataSourceKey] = (json.data && json.data[0]) || [];

                        if (columnName === "CRM_CustomerID") {

                            statusList = window[dataSourceKey];

                        }

                        // load trong form bth co combox luon

                        if (InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C.getDataSource().items().length == 0 && window["DataSource_CompanySize_ID"].length > 0) { InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C.option("dataSource", window["DataSource_CompanySize_ID"]); }

                        if (InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A.getDataSource().items().length == 0 && window["DataSource_Industry_ID"].length > 0) { InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A.option("dataSource", window["DataSource_Industry_ID"]); }

        //if (InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.getDataSource().items().length == 0 && window["DataSource_EmployeeID"].length > 0) { InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.option("dataSource", window["DataSource_EmployeeID"]); }

                        if (InstancePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1.getDataSource().items().length == 0 && window["DataSource_PositionID"].length > 0) { InstancePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1.option("dataSource", window["DataSource_PositionID"]); }





                        window[loadedKey] = true;



                        if (typeof onSuccessCallback === "function") {

                            onSuccessCallback(window[dataSourceKey]);

                        }



                        const instanceVariants = [

                            "Instance" + columnName.charAt(0).toUpperCase() + columnName.slice(1) + "P89D4A2BDA88F4F8A81EC9926B84F0D11",

                            "Instance" + columnName + "P89D4A2BDA88F4F8A81EC9926B84F0D11",

                            "instance" + columnName.charAt(0).toUpperCase() + columnName.slice(1) + "P89D4A2BDA88F4F8A81EC9926B84F0D11"

                        ];



                        for (let i = 0; i < instanceVariants.length; i++) {



                            const instanceKey = instanceVariants[i];



                            if (window[instanceKey]) {

                                const instanceObj = window[instanceKey];





                                // Ki?m tra n?u dây là dxDataGrid

                                if (typeof instanceObj.dxDataGrid === "function" || instanceObj.option && instanceObj.option("dataSource") !== undefined) {

                                    try {

                                        // N?u là Grid, apply dynamic config

                                        const gridConfigFn = window["getGridConfig_" + columnName.charAt(0).toUpperCase() + columnName.slice(1)];

                                        if (typeof gridConfigFn === "function") {

                                            const gridConfig = gridConfigFn(window[dataSourceKey]);

                                            if (gridConfig && typeof gridConfig === "object") {

                                                if (gridConfig.remoteOperations && typeof gridConfig.remoteOperations === "object") {

                                                    instanceObj.option("remoteOperations", gridConfig.remoteOperations);

                                                }

                                                if (gridConfig.pageSize != null) {

                                                    instanceObj.option("paging.pageSize", gridConfig.pageSize);

                                                }

                                                if (Array.isArray(gridConfig.allowedPageSizes)) {

                                                    instanceObj.option("pager.allowedPageSizes", gridConfig.allowedPageSizes);

                                                }

                                            }

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



            window.currentRecordID_Company_ID = null;

            window.currentRecordID_CRM_CustomerID = null;



            // DevExpress FileUploader for Import

            var fileUploaderImportDataCollection = $("<div>").dxFileUploader({

                visible: false,

                multiple: true,

                dialogTrigger: ".CRM_DataCollection_BtnImportExcel",

                uploadMode: "useButtons",

                allowedFileExtensions: [".xlsx", ".xls", ".csv", ".txt"],

                inputAttr: {

                    accept: ".xlsx, .xls, .csv, .txt",

                },

                onValueChanged: async function (arg) {

                    if (arg.value.length === 0) return;



                    showConfirmPopup({

                        title: "Xác nhận",

                        message: "Bạn có muốn import dữ liệu",

                        YesText: "Ðồng ý",

                        NoText: "Hủy",

                        onYes: async () => {

                            for (const file of arg.value) {

                                const functionParam = ["CRM_ExportTemplateDataCollection"].find(

                                    (x) => file.name.toLowerCase().includes(x.toLowerCase())

                                );

                                if (!file.path) {

                                    const reader = new FileReader();

                                    reader.readAsDataURL(file);

                                    reader.onload = async function () {

                                        file.path = reader.result.split(",")[1];

                                        showLoadingByClassOrID("#sp_KPIListDataCollection", "Đang import dữ liệu...");

                                        await AjaxHPAParadiseParadiseAsync({

                                            data: {

                                                name: "ImportLocationFolder",

                                                param: [file.path, file.name, "", "@LoginID", window.UserID, "@EmployeeID", window.EmployeeID_Login, "@LanguageID", window.LanguageID],

                                            },

                                            success: function (data) {

                                                let dataObject = JSON.parse(data);

                                                let newData = dataObject.data;

                                                let finalMsg = parseErrorMessage(newData);



                                                if (finalMsg != "") {

                                             showPopupNotify("%Result%", finalMsg, "OK", "40vw");

                                                } else {

                                                    uiManager.showAlert({ type: "success", message: "%ImportData_Completed%" });

                                                }



HideLoadingByClassOrID("#sp_KPIListDataCollection");



                                                // Reload data after import

                                                ReloadData();

      },

                                            error: function (xhr, status, error) {

                                                HideLoadingByClassOrID("#sp_KPIListDataCollection");

                                                uiManager.showAlert({

                                                    type: "error",

                                                    message: "Import dữ liệu thất bại!",

                                                });

                                            }

                                        });



                                    };

                                } else {

                                    showLoadingByClassOrID("#sp_KPIListDataCollection", "Đang import dữ liệu...");

                                    await AjaxHPAParadiseParadiseAsync({

                                        data: {

                                            name: "ImportLocationFolder",

                                            param: [file.path, file.name, "", "@EmployeeID", window.EmployeeID_Login, "@LanguageID", window.LanguageID],

                                        },

                                        success: function (data) {



                                            let newData = dataObject.data;



                                            let finalMsg = parseErrorMessage(newData);



                                            showPopupNotify("%Result%", finalMsg, "OK", "40vw");

                                            HideLoadingByClassOrID("#sp_KPIListDataCollection");



                                            // Reload data after import

                                            ReloadData();

                                        },

                                        error: function (xhr, status, error) {

                                            HideLoadingByClassOrID("#sp_KPIListDataCollection");



                                            uiManager.showAlert({

                                                type: "error",

                                                message: "Import dữ liệu thất bại!",

                                            });

                                        }

                                    });

                                }

                                fileUploaderImportDataCollection

                                    .dxFileUploader("instance")

                                    .reset();

                            }

                        },

                    });

                },

            });



              function parseErrorMessage(rawData) {

                if (!rawData) return;



                // Convert to string if it''s an array

                let lines = [];

                if (Array.isArray(rawData)) {

                    lines = rawData;

                } else if (typeof rawData === "string") {

                    lines = rawData.split(''\n'');

                } else {

                    return;

                }



                let errorsByRow = {};

                let generalErrors = [];

                let successes = [];



                lines.forEach(line => {

                    const content = line.trim();

                    if (!content) return;



                    const upperContent = content.toUpperCase();

                    if (!upperContent.includes("ERROR") && !upperContent.includes("SUCCESS")) {

                        // Line không phải error/success (case: "Tìm thấy 1 dòng dữ liệu")

                        successes.push(content);

                        return;

                    }



                    if (upperContent.includes("ERROR")) {

                     // Parse format: "Error: MST|SĐT|Thông báo lỗi"

                        const pipes = content.split("|").map(function (x) { return String(x || "").trim(); });



                        if (pipes.length >= 3) {

                            // Format mới: Error|MST|SĐT|Thông báo lỗi|Row (hoặc thiếu Row)

                            const mst = (pipes[0] || "").replace(/^error\s*:?\s*/i, "").trim();

                            const phone = pipes[1] || "";

                            const errorText = pipes[2] || "Lỗi không xác định";

                            const row = (pipes[3] || "")

                                .replace(/^row\s*:?\s*/i, "")

                                .replace(/^dòng\s*:?\s*/i, "")

                                .trim();



                            const detail = `<span style="color: #dc3545;">${errorText}</span>`;



                            if (row) {

                                if (!errorsByRow[row]) errorsByRow[row] = [];

                                errorsByRow[row].push(detail);

                            } else {

                                generalErrors.push(detail);

                            }

                        } else {

                            // Fallback: parse old format or simple error

                            const message = content.replace(/Error:/gi, "").replace(/:/g, "").trim();

                            if (message) {

                                generalErrors.push(`<span class="badge bg-danger">Error</span> ${message}`);

                            }

                        }

                    }

                    else if (upperContent.includes("SUCCESS")) {

                        // Parse success line

                        const cleanSuccess = content.replace(/^Success:\s*/i, "").trim();



                        // Create badge HTML - Green for success

                        const badge = `<span class="badge bg-success" style="font-size: 12px; margin-right: 5px;">✓</span><span style="color: #198754;">${cleanSuccess}</span>`;

                        successes.push(badge);

                    }

                });



                let displayMessage = "";



                // Show successes first (Green badges)

                if (successes.length > 0) {

                    displayMessage += "<b style=''color: #198754;''>%Success%:</b><br/>";

                    successes.forEach(success => {

                        displayMessage += `<div style="margin-bottom: 8px; padding: 6px; background-color: #f0f9f6; border-left: 3px solid #198754; border-radius: 4px;">${success}</div>`;

                    });

                }



                // Show errors (Red badges)

                const rowKeys = Object.keys(errorsByRow).sort(function (a, b) {

                    const na = Number(a);

                    const nb = Number(b);

                    if (!Number.isNaN(na) && !Number.isNaN(nb)) return na - nb;

                    return String(a).localeCompare(String(b));

                });



                if (rowKeys.length > 0 || generalErrors.length > 0) {

                    if (displayMessage) displayMessage += "<br/>";

                    displayMessage += "<b style=''color: #dc3545;''>%Failure%:</b><br/>";

                    rowKeys.forEach(function (row) {

                        const rowErrors = errorsByRow[row] || [];

                        const rowHtml = rowErrors.map(function (error) {

                            return `<div style="margin-top:4px;">${error}</div>`;

                        }).join("");



                        displayMessage += `<div style="margin-bottom: 8px; padding: 6px; background-color: #fdf8f7; border-left: 3px solid #dc3545; border-radius: 4px;"><span class="badge bg-danger" style="font-size: 11px; margin-right: 5px;">Dòng: ${row}</span>${rowHtml}</div>`;

                    });



                    generalErrors.forEach(error => {

                        displayMessage += `<div style="margin-bottom: 8px; padding: 6px; background-color: #fdf8f7; border-left: 3px solid #dc3545; border-radius: 4px;">${error}</div>`;

                    });

             }



                return displayMessage;

            }



            /**

             * Show popup notification with scrollable content

             * @param {string} title - Popup title

             * @param {string} message - HTML message content

             * @param {string} buttonText - Button text (default: "OK")

             * @param {string} width - Popup width (default: "50vw")

             */

            function showPopupNotify(title, message, buttonText = "OK", width = "50vw") {

                // Remove existing popup if any

                $(''#notifyPopupModal'').remove();



                // Create modal HTML

                const modalHTML = `

                    <div id="notifyPopupModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">

                        <div class="modal-dialog" style="width: ${width}; max-width: 90vw;">

                            <div class="modal-content">

                                <div class="modal-header" style="border-bottom: 1px solid #dee2e6; padding: 1rem;">

                                    <h5 class="modal-title">${title || ''Thông báo''}</h5>

             <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>

                                </div>

                                <div class="modal-body" style="max-height: 60vh; overflow-y: auto; padding: 1rem; word-break: break-word; word-wrap: break-word;">

                   <div class="notify-content" style="user-select: text; -webkit-user-select: text; -moz-user-select: text; -ms-user-select: text; cursor: text;">

  ${message || ''''}

      </div>

   </div>

                                <div class="modal-footer" style="border-top: 1px solid #dee2e6; padding: 1rem;">

                                    <button type="button" class="btn btn-primary" data-bs-dismiss="modal">${buttonText}</button>



                                </div>

  </div>

                        </div>

                    </div>

                `;



                // Append modal to body

                $(''body'').append(modalHTML);



                // Show modal using Bootstrap 5 API

                const modal = new bootstrap.Modal(document.getElementById(''notifyPopupModal''));

                modal.show();



                // Clean up modal when hidden

                document.getElementById(''notifyPopupModal'').addEventListener(''hidden.bs.modal'', function () {

                    $(''#notifyPopupModal'').remove();

                });

            }



            function addValidatorToInstance(instance, rules) {

                if (!instance) {

                    console.error("Instance null");

                    return null;

                }



                // L?y element t? instance

                var element = instance.element();



                // Wrap b?ng jQuery và add validator

                var validator = $(element).dxValidator({

                    validationRules: rules

                }).dxValidator("instance");



                // Auto validate on value change

                instance.option("onValueChanged", function () {

                    setTimeout(function () {

                        const validationResult = validator.validate();

           if (validationResult && validationResult.isValid) {

                            validator.reset();

                        }

                    }, 100);

                });



                return validator;

            }



            /*  let validatorTaxCode = addValidatorToInstance(

                  TaxCodePE9DF5833F12044D78B19C7B41306E4C6RealInstance,

          [

{

                          type: "required",

                          message: "Mã số thuế là bắt buộc"

                      },

                      {

               type: "async",

                          validationCallback: function (options) {

                              if (!options.value) return Promise.resolve(true);



            return checkTaxCodeExists(options.value).then(function (exists) {

                                  return !exists;

                              });

    },

                          message: "Mã số thuế tồn tại trong hệ thống"

             },

                      {

                          type: "custom",

validationCallback: function (options) {

                              return validateMST(options.value);

           },

message: "Mã số thuế không hợp lệ"

                      }

                  ]

              ); */



            function validateMST(mst) {

                if (!mst) {

                    uiManager.showAlert({ type: "error", message: "%TaxCodeRequired%" });

                    return false;

                }



                 if (mst.trim().toLowerCase() == "auto")

                    return true;



                     if (mst.startsWith(''99'')) {

                return true;

            }



                mst = mst.replace(/[-\s]/g, '''').trim();



                // ✅ Cho phép 10, 12, hoặc 13 số

                 if (!/^\d{10}(\d{1,3})?$/.test(mst)) {

                uiManager.showAlert({ type: "error", message: "%TaxCodeLength%" });

                return false;

            }



                // Lấy 10 số đầu (MST chính)

                const mainMST = mst.substring(0, 10);

    const digits = mainMST.split('''').map(Number);



                const weights = [31, 29, 23, 19, 17, 13, 7, 5, 3];



                let sum = 0;

                for (let i = 0; i < 9; i++) {

                    sum += digits[i] * weights[i];

                }



                let checksum = 10 - (sum % 11);



                // ✅ checksum = 10 hoặc 11 → bỏ qua validate (MST đặc biệt)

                if (checksum === 10 || checksum === 11) {

                    return true;

                }



                const isValid = checksum === digits[9];

                if (!isValid) {

                    uiManager.showAlert({ type: "error", message: "%TaxCodeInvalidDigit%" });

                }

                return isValid;

            }



            function checkTaxCodeExists(taxCode, phoneNumber) {

                if (!taxCode || taxCode.trim() === "") {

                    return Promise.resolve(true);

                }





                const normalizedValue = phoneNumber.trim().toUpperCase();



                if (

                    currentRecordID_CRM_CustomerID &&

                    originalPhoneNumberValue &&

                    normalizedValue === originalPhoneNumberValue

                ) {

                    return Promise.resolve(true);

                }



                return new Promise((resolve) => {

                    AjaxHPAParadise({

                        data: {

                            name: "sp_KPIgetDataCollectionCheckTaxCode",

                            param: [

                                "TaxCode",

                                taxCode.trim(),



            "ExcludeCompany_ID",

                                currentRecordID_CRM_CustomerID,

                                "phoneNumber", phoneNumber

                            ]

                        },

                        success: function (data) {

                            try {


                                if (typeof data === "string" && data.includes("{")) {

                                    data = JSON.parse(data);

                                }



                                const rows = data?.data?.[0] || [];

                                resolve(rows.length === 0); // ? true / false

                            } catch {

                                resolve(true); // fail-open

                            }

    },

                        error: function () {

                            resolve(true); // fail-open

                        }

                    });

                });

            }



            // InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A

            // InstanceTaxCodePE9DF5833F12044D78B19C7B41306E4C6

            // CompanyPCEA494414F404AF7AD9BFCE81F15F90ERealInstance

            // InstanceAddressP4CA52B6C787249E68C408A05419C0C77

            // InstanceInchargePersonP505719422EBB4A44AA7EB825DC4B8126

            // PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance

            // InstanceIP_EmailP0ED76598CC6C42B182C977574DB3960A

            // InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C

            // InstanceSourceP9A288D9BFC0A4460B0D404DE8E29E285

            // InstanceNotesPB4BA98106A5F41ACAC2552D31EEA70D4



            function clearPageCache() {

                _pageCache = {};

            }



            function getGridHeight() {

                const gridEl = InstanceGridKCP89D4A2BDA88F4F8A81EC9926B84F0D11.element();

                const domElement = gridEl.jquery ? gridEl[0] : gridEl;

                const top = domElement.getBoundingClientRect().top;

                return window.innerHeight - top - 20;

            }



            function ReloadData(fromDate = null, toDate = null, employeeId = null, isViewAll = null, keyword = null, hasKPIDate = null) {

                hasKPIDate = hasKPIDate == null ? ($(''#pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5'').is('':checked'') ? 1 : 0) : hasKPIDate;

                let _isLoadingPage = false;

                _pageCache = {};

                let activeStatus = window.activeStatusFilter;



                let _currentKeyword = String(

                    keyword != null

                        ? keyword

                        : (InstanceGridKCP89D4A2BDA88F4F8A81EC9926B84F0D11.option("searchPanel.text") || "")

                ).trim();



                function _applyRecord(results) {

                    window.syncSharedGridData("GridKC");



                    if (typeof configureGridToolbar === ''function'') {

                        configureGridToolbar();



                    }

                }



                dataStore_GridKC = new DevExpress.data.CustomStore({

                    key: "RowID",

                    load: function (loadOptions) {

                        loadOptions = loadOptions || {};

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

                        params.push("@ProcName", "sp_KPIgetDataCollection");



                        // Tham số riêng của sp_KPIgetDataCollection

                        let procParam = "";

                        isViewAll = isViewAll == null ? ($(''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'').is('':checked'') ? 1 : 0) : isViewAll;

                        const fallbackFrom = InstanceFromDateP4510BE8E25E842D286E3E8C0ACAE8E7E.option(''value'');

                        const fallbackTo = InstanceToDatePF18C5687EA514B69BFBA6BCA32E2D629.option(''value'');



                        procParam += `@LoginID=${window.UserID}`;

                        procParam += `,@isViewAll=${isViewAll}`;



                        if (activeStatus != null) {

                            procParam += `,@activeStatus=${activeStatus}`;

                        }



                        if (!isViewAll) {

                            const effectiveFrom = fromDate || fallbackFrom;

                            const effectiveTo = toDate || fallbackTo;

                            if (effectiveFrom && effectiveTo) {

                                procParam += `,@FromDate=''${effectiveFrom}''`;

                                procParam += `,@ToDate=''${effectiveTo}''`;

                            }

                        }



                        procParam += `,@EmployeeID=''${InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.option(''value'') || ''''}''`;

                        procParam += `,@isDuLieuTinhKPI=${hasKPIDate}`;



                        params.push("@ProcParam", procParam);



                        // Phân trang

                        params.push("@Take", loadOptions.take || 50);

                        params.push("@Skip", loadOptions.skip || 0);



                        // TotalCount

                        if (loadOptions.requireTotalCount) {

                            params.push("@RequireTotalCount", 1);

                        }



                        // Sort

                        const sort = loadOptions.sort

                            ? loadOptions.sort.map(s => s.selector + (s.desc ? " DESC" : " ASC")).join(",")

                            : "CreatedDate DESC"; // này cho mặc định. tự chỉnh theo menu mỗi người



                        params.push("@Sort", "ORDER BY " + sort);



                        // Search

                        if (_currentKeyword) {



                            params.push("@SearchValue", _currentKeyword);

                            params.push("@ColumnSearch", "Company,TaxCode,FullName,PhoneNumber,Email,PhoneNumber1,Email1");

                        }



                        if (loadOptions.filter) {

                            // Kiểm tra filter item có phải function không

                            const isJSFunction = (item) => typeof item === ''function'';



                            const hasFunction = JSON.stringify(loadOptions.filter, (key, val) => {

                                if (typeof val === ''function'') return ''FUNCTION'';

                                return val;

                            }).includes(''FUNCTION'');



                            if (!hasFunction) {

                                params.push("@Filters", createConditionQuery(loadOptions.filter));

                            }

                        }



                        // Filter

                        // if (loadOptions.filter) {

                        //     params.push("@Filters", createConditionQuery(loadOptions.filter));

                        // }



                        // Group

                        if (loadOptions.group) {

                            let selectGroup = "", groupBy = "GROUP BY ";

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

                                dataCollectionList = results;

                                _applyRecord(results);



                                deferred.resolve(result);

                            },

                            error: function (err) {

                                deferred.reject("Data Loading Error");

                            }

                        });



                        return deferred.promise();

                    }

                });



                // Gán store vào grid để kích hoạt load

                const gridInstance = InstanceGridKCP89D4A2BDA88F4F8A81EC9926B84F0D11;

                gridInstance.beginUpdate();

                gridInstance.option("remoteOperations", {

                    paging: true,

                    filtering: true,

                    sorting: true,

                    searching: true

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

                gridInstance.option("dataSource", dataStore_GridKC);

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



            // Open modal for adding new data

  function openDataModal() {



                resetSaveButtonState();



                $("#isPotentialCustomer").prop("disabled", false);



                $("#isPotentialCustomer").prop("checked", false);



                // B? event

                _autoSaveIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A = false;



                _autoSaveCreatedDateP93D36D79837B4A17A1D44F5B262DA097 = false;



                _autoSaveCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C = false;



                _autoSaveCompanyPCEA494414F404AF7AD9BFCE81F15F90E = false;



                _autoSaveTaxCodePE9DF5833F12044D78B19C7B41306E4C6 = false;



                _autoSaveAddressP4CA52B6C787249E68C408A05419C0C77 = false;



                _autoSaveFullNameP505719422EBB4A44AA7EB825DC4B8126 = false;



                _autoSavePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = false;



                _autoSaveEmailP0ED76598CC6C42B182C977574DB3960A = false;



                _autoSaveSourceP9A288D9BFC0A4460B0D404DE8E29E285 = false;



                _autoSaveNotesPB4BA98106A5F41ACAC2552D31EEA70D4 = false;



                _autoSavePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1 = false;



                _autoSavePhoneNumber1PA57E3C14412E427C8178E10709E06DF5 = false;



                _autoSaveEmail1P87BE9D5708F947458C9F37FA1B601478 = false;



                window.currentRecordID_Company_ID = null;

                window.currentRecordID_CRM_CustomerID = null;

                currentEditId = null;

                originalPhoneNumberValue = null;

                originalTaxCodeValue = null;

                $(''#dataCollectionModalTitle'').text(''Thêm dữ liệu mới'');

                $(''#btnSaveDataCollection'').show();

                $(''#btnDeleteDataCollection'').hide();



                $(''.img-upload-section'').show();

                $(''#dataCollectionForm'')[0].reset();

                $(''#dc_taxCode'').prop(''readonly'', false);

                const today = new Date().toISOString();

                // EmailP0ED76598CC6C42B182C977574DB3960ARealInstance.option("value", "");

                // PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("value", "");

                // CompanyPCEA494414F404AF7AD9BFCE81F15F90ERealInstance.option("value", null);

                // SourceP9A288D9BFC0A4460B0D404DE8E29E285RealInstance.option("value", "");

                // InstanceCreatedDateP93D36D79837B4A17A1D44F5B262DA097.option("value", today);

     // InstanceCreatedDateP93D36D79837B4A17A1D44F5B262DA097.option("readOnly", true);

                // InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A.option("value", null);

                // InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C.option("value", null);



                let obj = {

                    CreatedDate: today,

                    CompanySize_ID: null,

                    Company: null,

                    TaxCode: null,

                    Address: null,

                    FullName: null,

                    PhoneNumber: null,

                    Email: null,

                    Source: null,

                    Industry_ID: null,

                    Notes: null,

                    PositionID: null,

                    PhoneNumber1: null,

                    Email1: null

                };







                '

                    + (select loadData from tblCommonControlType_Signed where UID = 'PA57E3C14412E427C8178E10709E06DF5')

                + (select loadData from tblCommonControlType_Signed where UID = 'P87BE9D5708F947458C9F37FA1B601478')



                + (select loadData from tblCommonControlType_Signed where UID = 'P93D36D79837B4A17A1D44F5B262DA097')

                + (select loadData from tblCommonControlType_Signed where UID = 'PCEA494414F404AF7AD9BFCE81F15F90E')

 +(select loadData from tblCommonControlType_Signed where UID = 'P4CA52B6C787249E68C408A05419C0C77')

  +(select loadData from tblCommonControlType_Signed where UID = 'P505719422EBB4A44AA7EB825DC4B8126')

                +(select loadData from tblCommonControlType_Signed where UID = 'PE9DF5833F12044D78B19C7B41306E4C6')

                +(select loadData from tblCommonControlType_Signed where UID = 'PB03D8BEAD0934DC2B599C27F771CE2DD')

                +(select loadData from tblCommonControlType_Signed where UID = 'P0ED76598CC6C42B182C977574DB3960A')



                +(select loadData from tblCommonControlType_Signed where UID = 'PF09EBAE4C6DA4BE3B1A79BAF021AC73C')

                +(select loadData from tblCommonControlType_Signed where UID = 'P9A288D9BFC0A4460B0D404DE8E29E285')

                +(select loadData from tblCommonControlType_Signed where UID = 'P8FD2ACDEFBB247A78E44E81876FF013A')

                + (select loadData from tblCommonControlType_Signed where UID = 'PB4BA98106A5F41ACAC2552D31EEA70D4')

                + (select loadData from tblCommonControlType_Signed where UID = 'P690E6110CC9042F0B7E64B4A3D7C4DF1')

                +N'



                $(''#dc_industryOther'').hide();



                // Show modal using jQuery

                $(''#dataCollectionModal'').modal(''show'');

            }



            // Edit data collection

      function openDetailRowID(obj) {



                let activeStatus = window.activeStatusFilter;

                window.currentRecordID_Company_ID = obj.Company_ID;



                try {

                    let statusIDArr = obj.StatusID.toString().split(",").map(s => s.trim());

                    const isMobile = ["Android", "iOS"].includes(getMobileOperatingSystem());



                    const hasOther = statusIDArr.some(item => item != "0" && item != "7");



                    if (hasOther) {

                        window.Company_ID = obj.Company_ID;

                        openFormParam(`sp_CRM_CustomerDetail`, {

                            LoginID: window.UserID,

                            LanguageID: window.LanguageID,

                            Company_ID: obj.Company_ID

                        });

                    } else {

                        if (isMobile) {

                            OpenFormParamMobile(`sp_CRM_CompanyDetail`);

                        } else {

                            openFormParam(`sp_CRM_CompanyDetail`);

   }

                    }

                }

                catch (error) {



                }





                return



                // InstanceCreatedDateP93D36D79837B4A17A1D44F5B262DA097.option("onValueChanged", cacheEventCreateTime.onValueChanged);

                // InstanceCreatedDateP93D36D79837B4A17A1D44F5B262DA097.option("onKeyUp", cacheEventCreateTime.onKeyUp);



                // InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C.option("onValueChanged", cacheEventCompanySize.onValueChanged);



                // CompanyPCEA494414F404AF7AD9BFCE81F15F90ERealInstance.option("onValueChanged", cacheEventCompany.onValueChanged);

                // CompanyPCEA494414F404AF7AD9BFCE81F15F90ERealInstance.option("onKeyUp", cacheEventCompany.onKeyUp);



                // TaxCodePE9DF5833F12044D78B19C7B41306E4C6RealInstance.option("onValueChanged", cacheEventTaxCode.onValueChanged);

                // TaxCodePE9DF5833F12044D78B19C7B41306E4C6RealInstance.option("onKeyUp", cacheEventTaxCode.onKeyUp);



                // AddressP4CA52B6C787249E68C408A05419C0C77RealInstance.option("onValueChanged", cacheEventAddress.onValueChanged);

                // AddressP4CA52B6C787249E68C408A05419C0C77RealInstance.option("onKeyUp", cacheEventAddress.onKeyUp);



                // FullNameP505719422EBB4A44AA7EB825DC4B8126RealInstance.option("onValueChanged", cacheEventContactPerson.onValueChanged);

                // FullNameP505719422EBB4A44AA7EB825DC4B8126RealInstance.option("onKeyUp", cacheEventContactPerson.onKeyUp);

                // PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("onValueChanged", cacheEventPhone.onValueChanged);

                // PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("onKeyUp", cacheEventPhone.onKeyUp);



                // EmailP0ED76598CC6C42B182C977574DB3960ARealInstance.option("onValueChanged", cacheEventEmail.onValueChanged);

                // EmailP0ED76598CC6C42B182C977574DB3960ARealInstance.option("onKeyUp", cacheEventEmail.onKeyUp);

                // SourceP9A288D9BFC0A4460B0D404DE8E29E285RealInstance.option("onValueChanged", cacheEventSource.onValueChanged);

                // SourceP9A288D9BFC0A4460B0D404DE8E29E285RealInstance.option("onKeyUp", cacheEventSource.onKeyUp);



                if (obj.IdentityID) {

                    $("#isPotentialCustomer").prop("checked", true);

                    $("#isPotentialCustomer").prop("disabled", true);

                } else {

                    $("#isPotentialCustomer").prop("disabled", false);

                    $("#isPotentialCustomer").prop("checked", false);

                }



                // clearn checked



                // tích chọn isPotentialCustomer thì check nếu đủ C



                $("#isPotentialCustomer").off("change").on("change", async function () {

               if ($(this).is(":checked") && window.currentRecordID_Company_ID != null) {

               showConfirmPopup({

                            title: "Xác nhận",

                            message: "Bạn có chắc chắn muốn đánh dấu khách hàng tiềm năng?",

                            YesText: "Ðồng ý",

                            NoText: "Hủy",

                            onYes: async () => {

                                const requiredFields = {

                                    ''Company'': CompanyPCEA494414F404AF7AD9BFCE81F15F90ERealInstance.option("value"),

                                    ''Mã số thuế'': TaxCodePE9DF5833F12044D78B19C7B41306E4C6RealInstance.option("value"),

                                    ''Ngành'': InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A.option("value"),

                                    ''Người liên hệ'': FullNameP505719422EBB4A44AA7EB825DC4B8126RealInstance.option("value"),

                                    ''Số điện thoại'': PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("value"),

                                    ''Nguồn'': SourceP9A288D9BFC0A4460B0D404DE8E29E285RealInstance.option("value")

                                };



                                for (const [fieldName, fieldValue] of Object.entries(requiredFields)) {

                        if (!fieldValue || (typeof fieldValue === ''string'' && fieldValue.trim() === '''')) {

                                        uiManager.showAlert({ type: "error", message: `${fieldName} là bắt buộc, không được để trống!` });

                                        return;

                                    }

                                }





                                // Validate phone number format and uniqueness

                                const phoneNumberValue = PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("value");

                                const isPhoneNumberValid = await validatePhoneNumber(phoneNumberValue);

                                if (!isPhoneNumberValid) {

                                    return;

                                }



                                // Validate tax code format and uniqueness

                                const taxCodeValue = TaxCodePE9DF5833F12044D78B19C7B41306E4C6RealInstance.option("value");



                                if (!validateMST(taxCodeValue)) {

                                    uiManager.showAlert({ type: "error", message: "Mã số thuế không hợp lệ!" });

   return;

                                }



                                //Company_ID

                                //CRM_CustomerID



                              AjaxHPAParadise({

                                    data: {

                                        name: "sp_KPIsetPotentialCustomerFromDataCollection",

                                        param: [

                                            "Company_ID", obj.Company_ID,

                                            "CRM_CustomerID", obj.CRM_CustomerID,

                                            "EmployeeID", window.EmployeeID_Login

                                        ]

                                    },

                                    success: function (data) {

                                        if (typeof data == "string" && !IsNullOrEmpty(data)) {

                                  data = data.includes("{") ? data : EncryptionStringDecryption(data);

                                        }

                                        try {

                                            let dataObject = typeof data === "string" ? JSON.parse(data) : data;

                                            let newData = dataObject.data[0];

                                            if (newData && newData.length > 0) {

uiManager.showAlert({ type: "success", message: "Đã đánh dấu là khách hàng tiềm năng." });



                                                $("#isPotentialCustomer").prop("disabled", true);

                                                ReloadData();

                                            } else {

                                                uiManager.showAlert({ type: "error", message: "Có lỗi xảy ra, vui lòng thử lại sau!" });

                                            }

                                        } catch (error) {



                                        }



                                    },

                                    error: function (xhr, status, error) {

                                        uiManager.showAlert({ type: "error", message: "Đánh dấu khách hàng tiềm năng thất bại!" });

                                    }

                                });

                            },


                            onNo: () => {

                                $("#isPotentialCustomer").prop("checked", false);

                                return;

                            }

                        });







                    }

                });



                _autoSaveIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A = true;

                _autoSaveCreatedDateP93D36D79837B4A17A1D44F5B262DA097 = true;

                _autoSaveCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C = true;

                _autoSaveCompanyPCEA494414F404AF7AD9BFCE81F15F90E = true;

                _autoSaveTaxCodePE9DF5833F12044D78B19C7B41306E4C6 = true;

                _autoSaveAddressP4CA52B6C787249E68C408A05419C0C77 = true;

                _autoSaveFullNameP505719422EBB4A44AA7EB825DC4B8126 = true;

                _autoSavePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD = true;

                _autoSaveEmailP0ED76598CC6C42B182C977574DB3960A = true;

                _autoSaveSourceP9A288D9BFC0A4460B0D404DE8E29E285 = true;



                _autoSaveNotesPB4BA98106A5F41ACAC2552D31EEA70D4 = true;

                _autoSavePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1 = true;



                _autoSavePhoneNumber1PA57E3C14412E427C8178E10709E06DF5 = true;

                _autoSaveEmail1P87BE9D5708F947458C9F37FA1B601478 = true;



                currentEditId = obj.Company_ID;



                if (!obj) return;



                originalPhoneNumberValue = obj.PhoneNumber ? String(obj.PhoneNumber).trim() : null;

                originalTaxCodeValue = obj.TaxCode ? String(obj.TaxCode).trim().toUpperCase() : null;



                $(''#dataCollectionModalTitle'').text(''Chỉnh sửa dữ liệu'');

                $(''#btnSaveDataCollection'').hide();



                $(''#btnDeleteDataCollection'').show();

          $(''.img-upload-section'').hide();

                $(''#dc_taxCode'').prop(''readonly'', true);



                window.currentRecordID_Company_ID = obj.Company_ID || window.currentRecordID_Company_ID;

                window.currentRecordID_CRM_CustomerID = obj.CRM_CustomerID || window.currentRecordID_CRM_CustomerID;

                // Fill all form fields

                const dateVal = obj.CreatedDate || obj.time;

                // $(''#dc_time'').val(dateVal ? dateVal.split(''T'')[0] : '''');



                '

                    + (select loadData from tblCommonControlType_Signed where UID = 'PA57E3C14412E427C8178E10709E06DF5')

  + (select loadData from tblCommonControlType_Signed where UID = 'P87BE9D5708F947458C9F37FA1B601478')

                + (select loadData from tblCommonControlType_Signed where UID = 'P93D36D79837B4A17A1D44F5B262DA097')

                + (select loadData from tblCommonControlType_Signed where UID = 'PCEA494414F404AF7AD9BFCE81F15F90E')

                +(select loadData from tblCommonControlType_Signed where UID = 'P4CA52B6C787249E68C408A05419C0C77')

                +(select loadData from tblCommonControlType_Signed where UID = 'P505719422EBB4A44AA7EB825DC4B8126')

                +(select loadData from tblCommonControlType_Signed where UID = 'PE9DF5833F12044D78B19C7B41306E4C6')

                +(select loadData from tblCommonControlType_Signed where UID = 'PB03D8BEAD0934DC2B599C27F771CE2DD')

                +(select loadData from tblCommonControlType_Signed where UID = 'P0ED76598CC6C42B182C977574DB3960A')

                +(select loadData from tblCommonControlType_Signed where UID = 'PF09EBAE4C6DA4BE3B1A79BAF021AC73C')

                +(select loadData from tblCommonControlType_Signed where UID = 'P9A288D9BFC0A4460B0D404DE8E29E285')

                +(select loadData from tblCommonControlType_Signed where UID = 'P8FD2ACDEFBB247A78E44E81876FF013A')

                +(select loadData from tblCommonControlType_Signed where UID = 'PB4BA98106A5F41ACAC2552D31EEA70D4')

                + (select loadData from tblCommonControlType_Signed where UID = 'P690E6110CC9042F0B7E64B4A3D7C4DF1')

                +N'



                // setSelectBoxValue(InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A, window.DataSource_Industry_ID, obj.Industry_ID);

                // setSelectBoxValue(InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C, window.DataSource_CompanySize_ID, obj.CompanySize_ID);



                // Match industry by text

                const industryText = obj.industry || '''';

                $(''#dc_industry option'').each(function () {

                    if ($(this).text() === industryText) {

                        $(this).prop(''selected'', true);

                    }

                });

                $(''#dc_industry'').trigger(''change'');



                // Show modal using jQuery

                $(''#dataCollectionModal'').modal(''show'');

            }



            function setSelectBoxValue(instance, dataSource, value) {

                // Ki?m tra instance có t?n t?i không

                if (!instance) {

                    console.error("Instance không t?n t?i");

                    return false;

                }



                // Ki?m tra dataSource có data không

                if (!dataSource || (Array.isArray(dataSource) && dataSource.length === 0)) {

                    console.warn("DataSource tr?ng ho?c không t?n t?i");

                    return false;

                }



                // N?u dataSource là array

                if (Array.isArray(dataSource)) {

                    instance.option("dataSource", dataSource);

                    // Ð?i render xong r?i set value

                    setTimeout(function () {

                        instance.option("value", value);

                    }, 50);

                    return true;

                }



                // N?u dataSource là DataSource object ho?c promise

                if (dataSource.load && typeof dataSource.load === ''function'') {

                    dataSource.load().done(function (items) {

                        if (items && items.length > 0) {

                            instance.option("dataSource", items);

                            setTimeout(function () {

                                instance.option("value", value);

                            }, 50);

                        } else {

                            console.warn("DataSource load nhung không có items");

                        }

                    }).fail(function (error) {

        console.error("L?i khi load dataSource:", error);

                    });

                    return true;

                }



                // Tru?ng h?p dataSource là object config

                instance.option("dataSource", dataSource);

                setTimeout(function () {

                    instance.option("value", value);

                }, 50);



                return true;

            }

            // Filter data collection

            function filterDataCollection() {

                const fromDate = InstanceFromDateP4510BE8E25E842D286E3E8C0ACAE8E7E.option(''value'');

                const toDate = InstanceToDatePF18C5687EA514B69BFBA6BCA32E2D629.option(''value'');

                const isViewAll = $(''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'').is('':checked'');

                const employeeSelect = InstanceEmployeeIDPDF424130C28F4C1298C81F737570F7A7.getValueAsString();



                const selectedEmployeeId = employeeSelect ? employeeSelect.value : null;

                const hasKPIDate = $(''#pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5'').is('':checked'');

                if (!isViewAll) {

                    if (!fromDate || !toDate) {

         uiManager.showAlert({ type: "error", message: "Vui lòng chọn ngày để tìm kiếm" });

                        return;

                    }



                    if (fromDate > toDate) {

                        uiManager.showAlert({ type: "error", message: "Từ ngày phải nhỏ hơn đến ngày" });

                        return;

                    }

            }



                ReloadData(isViewAll ? null : fromDate, isViewAll ? null : toDate, selectedEmployeeId, isViewAll, null, hasKPIDate);

            }





            // Initialize data collection

            function initDataCollection() {



                // Load permissions first

                loadPermission().then(() => {

                    let fromDateKPI, toDateKPI;

                    let hasKPIDate = false;

                    let isType = window.TypeKPIFilter ? window.TypeKPIFilter : null;

                    // 1 collection, 2 need care

                    if (window.FromDateKPI && window.ToDateKPI) {

                        fromDateKPI = window.FromDateKPI;

                        toDateKPI = window.ToDateKPI;

                    } else {

                        const today = new Date();

                        const currentYear = today.getFullYear();

                        const currentMonth = today.getMonth();



                        const monthStart = new Date(currentYear, currentMonth, 1);

                        const monthEnd = new Date(currentYear, currentMonth + 1, 0);



                        fromDateKPI = monthStart.toISOString().split(''T'')[0];

                        toDateKPI = monthEnd.toISOString().split(''T'')[0];

                    }

                    InstanceFromDateP4510BE8E25E842D286E3E8C0ACAE8E7E.option(''value'', fromDateKPI);

                    InstanceToDatePF18C5687EA514B69BFBA6BCA32E2D629.option(''value'', toDateKPI);

                    // Set checkbox states

                    let isViewAll = 1

                  if (isType == 1) {

                        $(''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);

               $(''#pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', true);

                        hasKPIDate = true

                        isViewAll = 0

                    } else if (isType == 2) {

                        $(''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);

                        $(''#pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);

                        hasKPIDate = false

                        isViewAll = 0

                    } else {

                        $(''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', true);

                  $(''#pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);

                        hasKPIDate = false

                    }

                    ReloadData(fromDateKPI, toDateKPI, null, isViewAll, null, hasKPIDate);



                }).catch((error) => {



                    // Still initialize with default dates even if permission load fails

                    const today = new Date();

                    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);

                    const monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 0);

                    InstanceFromDateP4510BE8E25E842D286E3E8C0ACAE8E7E.option(''value'', monthStart.toISOString().split(''T'')[0]);

                    InstanceToDatePF18C5687EA514B69BFBA6BCA32E2D629.option(''value'', monthEnd.toISOString().split(''T'')[0]);

                    // Set default checkbox states on error

                    $(''#pillViewAllP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', true);

                    $(''#pillKPIP1D1261311DFB4BDABD06DE5867CFF5B5'').prop(''checked'', false);



                    ReloadData(monthStart.toISOString().split(''T'')[0], monthEnd.toISOString().split(''T'')[0], null, 1, null, false);

                });

            }



            // Load user permissions

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

                                const perm = permissionData[0];

                                if (perm.HasFullAccess) {

                                    AccessKey = ''FULLACCESS'';

                                } else if (perm.HasManagerAccess) {

                                    AccessKey = ''MANAGER'';

                                } else if (perm.HasUsersAccess) {

                                    AccessKey = ''USER'';

                                } else if (perm.HasCustomerAccess) {

                                    AccessKey = ''CUSTOMER'';

                                }

                            }

                            resolve();

                        },

                        error: reject

                    })

                })

            }



            function getHTMLinDesciption() {

                let currentHtml = InstanceNotesPB4BA98106A5F41ACAC2552D31EEA70D4?.value;

                let standardHtml = getStandardHtml_NotesPB4BA98106A5F41ACAC2552D31EEA70D4(currentHtml);



                let base64Html = utf16_le_to_b64_NotesPB4BA98106A5F41ACAC2552D31EEA70D4(standardHtml);

                return base64Html;

            }



            // Save data collection

            async function saveDataCollection() {



                // Validate required fields



                const requiredFields = {

                    ''Company'': CompanyPCEA494414F404AF7AD9BFCE81F15F90ERealInstance.option("value"),

                    ''Mã số thuế'': TaxCodePE9DF5833F12044D78B19C7B41306E4C6RealInstance.option("value"),

                    // ''Ngành'': InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A.option("value"),

                    ''Người liên hệ'': FullNameP505719422EBB4A44AA7EB825DC4B8126RealInstance.option("value"),

          ''Số điện thoại'': PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("value"),

                    //  ''Nguồn'': SourceP9A288D9BFC0A4460B0D404DE8E29E285RealInstance.option("value")

                };



                for (const [fieldName, fieldValue] of Object.entries(requiredFields)) {

                    const isEmptyValue = fieldValue === null || fieldValue === undefined

                        || (typeof fieldValue === ''string'' && fieldValue.trim() === '''');

                    if (isEmptyValue) {

       uiManager.showAlert({ type: "error", message: `${fieldName} là bắt buộc, không được để trống!` });

                        return;

                    }

                }



                // Validate phone number format and uniqueness

                const phoneNumberValue = PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("value");

                const isPhoneNumberValid = await validatePhoneNumber(phoneNumberValue);

                if (!isPhoneNumberValid) {

                    return;

                }



                // Validate tax code format and uniqueness

                const taxCodeValue = TaxCodePE9DF5833F12044D78B19C7B41306E4C6RealInstance.option("value");



                if (!validateMST(taxCodeValue)) {

                    uiManager.showAlert({ type: "error", message: "Mã số thuế không hợp lệ!" });

                    return;

                }



                /*const validationResult = validatorTaxCode.validate();

                if (!validationResult.isValid) {

  uiManager.showAlert({ type: "error", message: "Vui lòng kiểm tra mã số thuế!" });

                    return;

    }*/



                const trimStr = (v) => (typeof v === ''string'' ? v.trim() : v);





                const formData = {

                    TaxCode: trimStr(TaxCodePE9DF5833F12044D78B19C7B41306E4C6RealInstance.option("value")),

                    CreatedDate: InstanceCreatedDateP93D36D79837B4A17A1D44F5B262DA097.option("value"),

                    Company: trimStr(CompanyPCEA494414F404AF7AD9BFCE81F15F90ERealInstance.option("value")),

                    Industry_ID: InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A.option("value"),

                    Address: trimStr(AddressP4CA52B6C787249E68C408A05419C0C77RealInstance.option("value")),

                    CompanySize_ID: InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C.option("value"),

                    Source: trimStr(SourceP9A288D9BFC0A4460B0D404DE8E29E285RealInstance.option("value"))

                };



                const formDataCustomer = {

                    FullName: trimStr(FullNameP505719422EBB4A44AA7EB825DC4B8126RealInstance.option("value")),

                    PhoneNumber: trimStr(PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("value")),

                    Email: trimStr(EmailP0ED76598CC6C42B182C977574DB3960ARealInstance.option("value")),

                    PositionID: InstancePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1.option("value"),

                    CreatedBy: window.EmployeeID_Login

                };

                let Notes = getHTMLinDesciption();



        const isPotential = $("#isPotentialCustomer").is(":checked") ? 1 : 0;



                // const result = await updateOrDeleteDataExample(''tblCRM_CompanyInfo'', 1, [formData]);

                await AjaxHPAParadise({

                    data: {

                        name: "sp_ExecuteDateCRMDataCollection",

                        param: [

                            "jsonFormData", JSON.stringify(formData),

                            "jsonFormDataCustomer", JSON.stringify(formDataCustomer),

                            "TableName", ''tblCRM_CompanyInfo'',

                            "TableName1", ''tblCRM_CustomerPersonInfo'',



                            "Type", 1,

                            "isPotential", isPotential,

                            "EmployeeID", window.EmployeeID_Login,

                            "Notes" , Notes

                        ]

                    },

                    success: function (data) {

                        if (typeof data == "string" && !IsNullOrEmpty(data)) {

                            data = data.includes("{") ? data : EncryptionStringDecryption(data);

                        }

                        let dataObject = JSON.parse(data);

                        let result = dataObject.data[0];

                        if (result && result.length > 0) {

                            let IsSuccess = result[0].Success;

                         if (IsSuccess) {

                                $(''#dataCollectionModal'').modal(''hide'');

                                uiManager.showAlert({ type: "success", message: "%AddSuccess%" });

                                initDataCollection();

                            } else {

                                console.error(''L?i khi luu d? li?u'');

                                uiManager.showAlert({ type: "error", message: "Có lỗi xảy ra khi lưu!" });

                            }

                        }

                    }


                })



            }



            // Delete data collection

            async function deleteDataCollection(companyID) {





                // const result = await updateOrDeleteDataExample(''tblCRM_CompanyInfo'', 2, [{ Company_ID: companyID }]);

                // if (result) {

                //     $(''#dataCollectionModal'').modal(''hide'');

                //     uiManager.showAlert({ type: "success", message: "%DltSuccess%" });

                //     initDataCollection();

                // } else {

                //     console.error(''L?i khi xóa d? li?u'');

                //     uiManager.showAlert({ type: "error", message: "Có l?i x?y ra khi xóa d? li?u!" });

                // }



                if (!confirm(''Bạn có xác muốn xóa?'')) return;



                const formData = {

                    Company_ID: window.currentRecordID_Company_ID

                };



                await AjaxHPAParadise({

                    data: {

                        name: "sp_ExecuteDateCRMDataCollection",

                        param: [

                            "jsonFormData", JSON.stringify(formData),

                            "TableName", ''tblCRM_CompanyInfo'',

                            "TableName1", ''tblCRM_CustomerPersonInfo'',

                            "Type", 2

                        ]

                    },

                    success: function (data) {

                        if (typeof data == "string" && !IsNullOrEmpty(data)) {

                            data = data.includes("{") ? data : EncryptionStringDecryption(data);

                        }

                        let dataObject = JSON.parse(data);

                        let result = dataObject.data[0];

                        if (result && result.length > 0) {

                            let IsSuccess = result[0].Success;

                            if (IsSuccess) {

                                $(''#dataCollectionModal'').modal(''hide'');

                                uiManager.showAlert({ type: "success", message: "%DltSuccess%" });

                                initDataCollection();

                            } else {

                                console.error(''L?i khi xóa d? li?u'');

                                uiManager.showAlert({ type: "error", message: "Có lỗi xảy ra khi lưu dữ liệu!" });

                            }

                        }

                    }

                })



            }



            // Import Excel data

            async function importDataFromExcel() {

                // Trigger file uploader dialog when clicking import button

                // DevExpress FileUploader will handle file selection and upload



                // The actual import logic is in the onValueChanged event of fileUploaderImportDataCollection

            }



            // Export Excel data

            async function exportDataToExcel() {



                showLoadingByClassOrID("#sp_KPIListDataCollection", "Xuất dữ liệu");



                let exportItem = {

                    name: "File mẫu import dữ liệu khách hàng",

                    text: "File mẫu import dữ liệu thu thập khách hàng",

                    item: "CRM_ExportTemplateDataCollection",

                    query: "sp_CRM_templateImportDataCollection",

                    fileName: "CRM_ExportTemplateDataCollection.xlsx",

                };

             let ExportName = exportItem.item;



                try {

                    if (!exportItem.fileName) {

                        let exportTemp = await AjaxHPAParadiseAsync({

                            data: {

                                name: exportItem.item,

                                param: [],

                            },

                         success: function (resultData) { },

                        });



                        exportTemp =

                            typeof exportTemp === "string"

                                ? JSON.parse(exportTemp)

                                : exportTemp;

                        ExportName =

                            exportTemp.data[0][0][

                            Object.keys(exportTemp.data[0][0]).find(

                                (x) => x.toLowerCase() == "exportname"

                            )

                            ] ?? ExportName;

                    }



                    let resultData = await AjaxHPAParadiseParadiseAsync({

                        data: {

                            //name: "ExportLocationFolderSaveAsFileAsync",

                            name: "ExportLocationFolder",

                            param: [

                                "",

                                ExportName,

                                exportItem.fileName

                            ],

                        },

                        success: function (resultData) { },

                        error: function (xhr, status, error) { },

                    });



                    let jsonData =

                        typeof resultData === "string" ? JSON.parse(resultData) : resultData;



                    if (jsonData.result == "error")

                        throw new Error(jsonData.reason ?? "L?i b?t thu?ng");



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

                                success: function (resultData) { },

        error: function (xhr, status, error) { },

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

                                error: function (xhr, status, error) { },

                            });

                        }

                    }



                    HideLoadingByClassOrID("#sp_KPIListDataCollection");

                } catch (error) {

                    HideLoadingByClassOrID("#sp_KPIListDataCollection");

                    let direction = "up-push";

        let position = "bottom right";



                    try {

              let reason = JSON.parse(jsonData.reason);

                        reason = Array.isArray(reason) ? reason[0] : reason;

                        jsonData.reason = reason.ErrorDetail;

                    } catch (jsonError) { }



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

                        }

                    );

                }



            }



            // Industry change handler

            $(''#dc_industry'').on(''change'', function () {

                if ($(this).val() === ''Other'') {

                    $(''#dc_industryOther'').show();



                } else {

                    $(''#dc_industryOther'').hide();

                    $(''#dc_industryOther'').val('''');

                }

            });



            // jQuery event handlers for CRM_DataCollection buttons

            $(document).on(''click'', ''.CRM_DataCollection_BtnFilter'', function (e) {

                e.preventDefault();

                filterDataCollection();

            });



            $(document).on(''click'', ''.CRM_DataCollection_BtnAdd'', function (e) {

                e.preventDefault();

                openDataModal();

            });



            $(document).on(''click'', ''#btnPendingList'', function (e) {

                e.preventDefault();

                window.pendingPage = ''dc'';

                if (["Android", "iOS"].includes(getMobileOperatingSystem())) {

                    OpenFormParamMobile(`sp_CRM_KpiPending`);

                } else {

                    openFormParam(`sp_CRM_KpiPending`);

                }

            });



            $(document).on(''click'', ''.CRM_DataCollection_BtnImportExcel'', function (e) {

                e.preventDefault();

                importDataFromExcel();

            });



            $(document).on(''click'', ''.CRM_DataCollection_BtnExportExcel'', function (e) {

                e.preventDefault();

                exportDataToExcel();

            });



            $(document).on(''click'', ''.CRM_DataCollection_ClearImage'', function (e) {

   e.preventDefault();

                clearImagePreview();

            });



            $(document).on(''click'', ''.CRM_DataCollection_BtnDelete'', function (e) {

                e.preventDefault();



                deleteDataCollection(window.currentRecordID_Company_ID);

            });



            $(document).on(''click'', ''.CRM_DataCollection_BtnSave'', function (e) {

                e.preventDefault();

                saveDataCollection();

            });



            // Export functions to window scope for legacy support

            // window.openDataModal = openDataModal;

            // window.openDetailCompany_ID = openDetailCompany_ID;

            // window.deleteDataCollection = deleteDataCollection;



            // window.filterDataCollection = filterDataCollection;

            // window.saveDataCollection = saveDataCollection;



            // Image upload functions

            const imageDropZone = document.getElementById(''imageDropZone'');

            const imageInput = document.getElementById(''imageInput'');

            const imagePreviewContainer = document.getElementById(''imagePreviewContainer'');

            const imagePreview = document.getElementById(''imagePreview'');



            // Upload file function

            async function UploadMergeFileSplit(src, fileName) {

                let splitImage = src.match(/.{1,500000}/g)

                let totalIndex = splitImage.length

                let index = 0

                let tempName = uuidv4() + ".tmp"

                if (!fileName) fileName = tempName

                let pathResult = ""



                while (index < totalIndex) {

                    try {

                        data = await AjaxHPAParadiseParadiseAsync({

                            data: {

                                sendEncryption: false,



                                name: "MergeFileSplit",

                                param: [

                                    splitImage[index],

                                    index,

                                    totalIndex,

                                    tempName,

                                    fileName,

                                ]

                            },

                        })

                        index += 1;

                        pathResult = data;

                    } catch (error) {

                        if (error.status == 200) index += 1;

                    }

                }

                return pathResult;

            }



            // Generate UUID for temp file names

            function uuidv4() {

                return ''xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx''.replace(/[xy]/g, function (c) {

                    var r = Math.random() * 16 | 0, v = c == ''x'' ? r : (r & 0x3 | 0x8);

                    return v.toString(16);

                });

            }



            // Validate image mime type

            function isValidImageType(file) {

                const validTypes = [

                    ''image/jpeg'',

                    ''image/png'',

                    ''image/webp'',



                    ''image/gif'',

                    ''image/heic''

                ];

                return validTypes.includes(file.type);

            }



            // Get file extension from mime type

            function getFileExtension(mimeType) {

                const mimeMap = {

                    ''image/jpeg'': ''.jpg'',

                    ''image/png'': ''.png'',

                    ''image/webp'': ''.webp'',

                    ''image/gif'': ''.gif'',

                    ''image/heic'': ''.heic''

                };

                return mimeMap[mimeType] || ''.jpg'';

            }



            // Click to upload

            imageDropZone.addEventListener(''click'', () => {

                imageInput.click();

            });



            // Drag and drop

            imageDropZone.addEventListener(''dragover'', (e) => {

                e.preventDefault();

                imageDropZone.style.backgroundColor = ''#e8f5e9'';

                imageDropZone.style.borderColor = ''#157347'';

            });



            imageDropZone.addEventListener(''dragleave'', () => {

                imageDropZone.style.backgroundColor = ''#f8f9fa'';

                imageDropZone.style.borderColor = ''#198754'';

            });



            imageDropZone.addEventListener(''drop'', (e) => {

                e.preventDefault();

                imageDropZone.style.backgroundColor = ''#f8f9fa'';

                imageDropZone.style.borderColor = ''#198754'';



                const files = e.dataTransfer.files;

                if (files.length > 0) {

                    imageInput.files = files;

                    displayImagePreview(files[0]);

                }

            });



            // File input change

           imageInput.addEventListener(''change'', (e) => {

                if (e.target.files.length > 0) {

                    displayImagePreview(e.target.files[0]);

                }

            });



            // Paste image from clipboard (Ctrl+V)

            document.addEventListener(''paste'', (e) => {

                // Only handle paste when modal is open


                if (!$(''#dataCollectionModal'').hasClass(''show'')) return;



                const items = e.clipboardData?.items;

                if (!items) return;



                for (let i = 0; i < items.length; i++) {

                    if (items[i].type.indexOf(''image'') !== -1) {

                        e.preventDefault();

                        const blob = items[i].getAsFile();

                        if (blob) {

                            displayImagePreview(blob);

                        }

                        break;

                    }

                }

            });



            async function displayImagePreview(file) {

                // Chống paste lặp lại khi đang xử lý

                if (isProcessingImage) {

                    uiManager.showAlert({ type: "error", message: "Đang xử lý ảnh trước đó, vui lòng chờ..." });

                    return;

                }



                // Validate file type

                if (!isValidImageType(file)) {

                    uiManager.showAlert({ type: "error", message: "Chỉ hỗ trợ định dạng file: JPG, JPEG, PNG, WEBP, GIF, HEIC." });

                    return;

                }



                // Check file size (max 10MB)

                const maxSize = 10 * 1024 * 1024; // 10MB

                if (file.size > maxSize) {

                    uiManager.showAlert({ type: "error", message: "Kích thước file không được lớn hơn 10MB" });

                    return;

                }



                const reader = new FileReader();

                reader.onload = async (e) => {

                    const base64Data = e.target.result;

                    imagePreview.src = base64Data;

                    imagePreviewContainer.style.display = ''block'';

                    imageDropZone.style.display = ''none'';



                    // Store image data for Gemini API call

                    window.selectedImageFile = file;

                    window.selectedImageData = base64Data;



                    // Upload file to server

                    try {

                        isProcessingImage = true; // Bắt đầu xử lý

                        const base64Content = base64Data.split('','')[1];

                        // Generate filename if not exists (for pasted images)

                        const fileName = file.name || `image_${Date.now()}${getFileExtension(file.type)}`;

                        const uploadedPath = await UploadMergeFileSplit(base64Content, fileName);

                        let dataURL = '''';

                        if (uploadedPath) {

                            try {

                          let dataEx = JSON.parse(uploadedPath);

                                dataURL = dataEx.data || '''';

                                dataURL = dataURL.replace(/\\/g, ''\\\\'');

                            } catch (error) {



                            }

                        }



                        if (dataURL) {

                            // Show loading indicators

                            showAIProcessingLoader();



                            AjaxHPAParadise({

                                data: {

                                    name: "sp_AI_api_DataCollection",

                                    param: [

                                        ''linkPdfBase64'', dataURL,

                                        ''mimeType'', file.type,

                                        ''LanguageID'', window.LanguageID,

                                    ]

                                },

                                success: function (data) {

                                    // Hide loading indicators

                                    isProcessingImage = false; // Kết thúc xử lý

                              hideAIProcessingLoader();



                                    if (typeof data == "string" && !IsNullOrEmpty(data)) {

                                        data = data.includes("{") ? data : EncryptionStringDecryption(data);

                                    }



                                    try {

                                        const responseData = JSON.parse(data);



                                        // Extract Result from response structure

                                        let companyData = null;



                                        if (responseData && responseData.data && Array.isArray(responseData.data)) {

                                            if (responseData.data.length > 0 && Array.isArray(responseData.data[0])) {

                                                if (responseData.data[0].length > 0) {

                                                    const resultData = responseData.data[0][0];



                                                    if (resultData && resultData.Result) {

                                                        let resultString = resultData.Result;



                                                        // Parse Result string

                                                        if (typeof resultString === ''string'') {

                                                            try {

                                                                const clean = resultString.replace(/```json|```/g, '''').trim();

                                                                companyData = JSON.parse(clean);

                                                            } catch (e1) {

                                                                console.warn(''!! Không parse được trực tiếp, thử format cũ...'');



                                                                try {

                                                                    const aiResultData = JSON.parse(resultString);



                                                                    if (aiResultData.Column1) {

                                                                        const geminiResponse = JSON.parse(aiResultData.Column1);

                                                                        const textContent = geminiResponse.candidates[0].content.parts[0].text;



                                                                        // Extract JSON t? markdown code block

                                                                        const extractJson = (str) => {

                                                                            const match = str.match(/```(?:json)?\s*\n?([\s\S]*?)\n?```/);

                                          return match ? match[1].trim() : str.trim();

                                                                        };



  const jsonString = extractJson(textContent);

                                                                        companyData = JSON.parse(jsonString);

                                                                    } else {

                                                                        companyData = aiResultData;

                                                                    }

                                                                } catch (e2) {

      console.error(''! Không parse được cả 2 format:'', e2);

                                                                    uiManager.showAlert({ type: "error", message: "Đã xảy ra lỗi khi phân tích dữ liệu, vui lòng thử lại sau vài giây!" });

                                                                }

                                                            }

                                                        } else {


                                                            companyData = resultString;



                                                        }

                                }

                                                }

                                            }

                                        }

                                        console.log(companyData)

                                        if (companyData) {

                                            // Clear validation messages for all controls

                                            // Set values from AI

                                            let obj = companyData;



                                            if (Array.isArray(companyData) && companyData.length > 0) {

                                                obj = companyData[0];

                                            }



                                            try {

                                                InstancePhoneNumber1PA57E3C14412E427C8178E10709E06DF5.clearValidationError();

                                            } catch (e) { }

                                            InstancePhoneNumber1PA57E3C14412E427C8178E10709E06DF5._suppressValueChangeAction();



                                            try {

                                                InstancePhoneNumber1PA57E3C14412E427C8178E10709E06DF5.option("searchValue", "");

                                                InstancePhoneNumber1PA57E3C14412E427C8178E10709E06DF5.option("text", "");

                                                InstancePhoneNumber1PA57E3C14412E427C8178E10709E06DF5.reset();

                                            } catch (e) { }



                                            if (obj && obj.PhoneNumber1) InstancePhoneNumber1PA57E3C14412E427C8178E10709E06DF5.option("value", obj.PhoneNumber1);

                                            else InstancePhoneNumber1PA57E3C14412E427C8178E10709E06DF5.option("value", "");



                                            InstancePhoneNumber1PA57E3C14412E427C8178E10709E06DF5._resumeValueChangeAction();





                                            try {

                                                InstanceEmail1P87BE9D5708F947458C9F37FA1B601478.clearValidationError();

                                            } catch (e) { }

                                            InstanceEmail1P87BE9D5708F947458C9F37FA1B601478._suppressValueChangeAction();



                                            try {

                                                InstanceEmail1P87BE9D5708F947458C9F37FA1B601478.option("searchValue", "");

                                                InstanceEmail1P87BE9D5708F947458C9F37FA1B601478.option("text", "");

                                                InstanceEmail1P87BE9D5708F947458C9F37FA1B601478.reset();

                                            } catch (e) { }



                                     if (obj && obj.Email1) InstanceEmail1P87BE9D5708F947458C9F37FA1B601478.option("value", obj.Email1);

                                            else InstanceEmail1P87BE9D5708F947458C9F37FA1B601478.option("value", "");



                                            InstanceEmail1P87BE9D5708F947458C9F37FA1B601478._resumeValueChangeAction();



                                            try {

       InstanceCompanyPCEA494414F404AF7AD9BFCE81F15F90E.clearValidationError();

                                            } catch (e) { }

                                            InstanceCompanyPCEA494414F404AF7AD9BFCE81F15F90E._suppressValueChangeAction();



                                            try {

                                                InstanceCompanyPCEA494414F404AF7AD9BFCE81F15F90E.option("searchValue", "");

                                  InstanceCompanyPCEA494414F404AF7AD9BFCE81F15F90E.option("text", "");

                                                InstanceCompanyPCEA494414F404AF7AD9BFCE81F15F90E.reset();

          } catch (e) { }



                                            if (obj && obj.Company) InstanceCompanyPCEA494414F404AF7AD9BFCE81F15F90E.option("value", obj.Company);

                                            else InstanceCompanyPCEA494414F404AF7AD9BFCE81F15F90E.option("value", "");



                                            InstanceCompanyPCEA494414F404AF7AD9BFCE81F15F90E._resumeValueChangeAction();



                                            try {

                                                InstanceAddressP4CA52B6C787249E68C408A05419C0C77.clearValidationError();

                                            } catch (e) { }

                                            InstanceAddressP4CA52B6C787249E68C408A05419C0C77._suppressValueChangeAction();



                                            try {

                                                InstanceAddressP4CA52B6C787249E68C408A05419C0C77.option("searchValue", "");

                                                InstanceAddressP4CA52B6C787249E68C408A05419C0C77.option("text", "");

                                                InstanceAddressP4CA52B6C787249E68C408A05419C0C77.reset();

                                            } catch (e) { }



                                            if (obj && obj.Address) InstanceAddressP4CA52B6C787249E68C408A05419C0C77.option("value", obj.Address);

                                            else InstanceAddressP4CA52B6C787249E68C408A05419C0C77.option("value", "");



                                            InstanceAddressP4CA52B6C787249E68C408A05419C0C77._resumeValueChangeAction();



                                            try {

                                                InstanceEmailP0ED76598CC6C42B182C977574DB3960A.clearValidationError();

                                            } catch (e) { }

                                            InstanceEmailP0ED76598CC6C42B182C977574DB3960A._suppressValueChangeAction();



                                            try {

                                                InstanceEmailP0ED76598CC6C42B182C977574DB3960A.option("searchValue", "");

                                                InstanceEmailP0ED76598CC6C42B182C977574DB3960A.option("text", "");

                                                InstanceEmailP0ED76598CC6C42B182C977574DB3960A.reset();

                                            } catch (e) { }



                                            if (obj && obj.Email) InstanceEmailP0ED76598CC6C42B182C977574DB3960A.option("value", obj.Email);

                                            else InstanceEmailP0ED76598CC6C42B182C977574DB3960A.option("value", "");



                                            InstanceEmailP0ED76598CC6C42B182C977574DB3960A._resumeValueChangeAction();





try {

                                                InstanceFullNameP505719422EBB4A44AA7EB825DC4B8126.clearValidationError();

                                            } catch (e) { }

                                            InstanceFullNameP505719422EBB4A44AA7EB825DC4B8126._suppressValueChangeAction();



                                            try {

     InstanceFullNameP505719422EBB4A44AA7EB825DC4B8126.option("searchValue", "");

                                                InstanceFullNameP505719422EBB4A44AA7EB825DC4B8126.option("text", "");

                                                InstanceFullNameP505719422EBB4A44AA7EB825DC4B8126.reset();

                                            } catch (e) { }



                                            if (obj && obj.FullName) InstanceFullNameP505719422EBB4A44AA7EB825DC4B8126.option("value", obj.FullName);

                                            else InstanceFullNameP505719422EBB4A44AA7EB825DC4B8126.option("value", "");



                                            InstanceFullNameP505719422EBB4A44AA7EB825DC4B8126._resumeValueChangeAction();



                                            try {

                                                InstancePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.clearValidationError();

                                            } catch (e) { }

                                            InstancePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD._suppressValueChangeAction();



                                            try {

                                                InstancePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.option("searchValue", "");

                                                InstancePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.option("text", "");

                                                InstancePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.reset();

                                            } catch (e) { }



                                            if (obj && obj.PhoneNumber) InstancePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.option("value", obj.PhoneNumber);

                                            else InstancePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD.option("value", "");



                                            InstancePhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DD._resumeValueChangeAction();



                                            try {

                                                InstanceSourceP9A288D9BFC0A4460B0D404DE8E29E285.clearValidationError();

                                            } catch (e) { }

                                            InstanceSourceP9A288D9BFC0A4460B0D404DE8E29E285._suppressValueChangeAction();



                                            try {

                                                InstanceSourceP9A288D9BFC0A4460B0D404DE8E29E285.option("searchValue", "");

                                                InstanceSourceP9A288D9BFC0A4460B0D404DE8E29E285.option("text", "");

                                                InstanceSourceP9A288D9BFC0A4460B0D404DE8E29E285.reset();

                                            } catch (e) { }



                                            if (obj && obj.Source) InstanceSourceP9A288D9BFC0A4460B0D404DE8E29E285.option("value", obj.Source);

                                            else InstanceSourceP9A288D9BFC0A4460B0D404DE8E29E285.option("value", "");





                                            InstanceSourceP9A288D9BFC0A4460B0D404DE8E29E285._resumeValueChangeAction();



                                            try {

                                                InstanceTaxCodePE9DF5833F12044D78B19C7B41306E4C6.clearValidationError();

                                            } catch (e) { }

                                            InstanceTaxCodePE9DF5833F12044D78B19C7B41306E4C6._suppressValueChangeAction();



                          try {

                                                InstanceTaxCodePE9DF5833F12044D78B19C7B41306E4C6.option("searchValue", "");

                                                InstanceTaxCodePE9DF5833F12044D78B19C7B41306E4C6.option("text", "");

                          InstanceTaxCodePE9DF5833F12044D78B19C7B41306E4C6.reset();

                                            } catch (e) { }



                                            if (obj && obj.TaxCode) InstanceTaxCodePE9DF5833F12044D78B19C7B41306E4C6.option("value", obj.TaxCode);

                                            else InstanceTaxCodePE9DF5833F12044D78B19C7B41306E4C6.option("value", "");



                                            InstanceTaxCodePE9DF5833F12044D78B19C7B41306E4C6._resumeValueChangeAction();



                                            try {

                                                InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C.clearValidationError();

                                            } catch (e) { }

  InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C._suppressValueChangeAction();



                                            try {

                                                InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C.option("searchValue", "");

                                                InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C.option("text", "");

                                                InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C.reset();

                                            } catch (e) { }



                                            if (obj && obj.CompanySize_ID) InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C.option("value", obj.CompanySize_ID);

                                            else InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C.option("value", "");



                                            InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C._resumeValueChangeAction();



                                            try {

                                                InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A.clearValidationError();

                                            } catch (e) { }

                                            InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A._suppressValueChangeAction();



                                            try {

                                                InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A.option("searchValue", "");

                                                InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A.option("text", "");

                                                InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A.reset();

                                            } catch (e) { }



                                            if (obj && obj.Industry_ID) InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A.option("value", obj.Industry_ID);

                                            else InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A.option("value", "");



                                            InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A._resumeValueChangeAction();



                                            try {

                                                InstancePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1.clearValidationError();

                                            } catch (e) { }

                                            InstancePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1._suppressValueChangeAction();



                                            try {

                                             InstancePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1.option("searchValue", "");

                                                InstancePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1.option("text", "");

                                                InstancePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1.reset();

                                            } catch (e) { }



                            if (obj && obj.PositionID) InstancePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1.option("value", obj.PositionID);

                                            else InstancePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1.option("value", "");



                                            InstancePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1._resumeValueChangeAction();



                                            // InstanceIndustry_IDP8FD2ACDEFBB247A78E44E81876FF013A.option("value", companyData.Industry_ID || null);

                                            // InstanceTaxCodePE9DF5833F12044D78B19C7B41306E4C6.option("value", companyData.TaxCode || null);

                                            // CompanyPCEA494414F404AF7AD9BFCE81F15F90ERealInstance.option("value", companyData.Company || null);

    // InstanceAddressP4CA52B6C787249E68C408A05419C0C77.option("value", companyData.Address || null);

                                            // InstanceInchargePersonP505719422EBB4A44AA7EB825DC4B8126.option("value", companyData.InchargePerson || null);

                                            // PhoneNumberPB03D8BEAD0934DC2B599C27F771CE2DDRealInstance.option("value", companyData.IP_Phone || null);

                                            // InstanceIP_EmailP0ED76598CC6C42B182C977574DB3960A.option("value", companyData.IP_Email || null);

                                            // InstanceCompanySize_IDPF09EBAE4C6DA4BE3B1A79BAF021AC73C.option("value", companyData.CompanySize_ID || null);

                                            // InstanceSourceP9A288D9BFC0A4460B0D404DE8E29E285.option("value", companyData.Source || null);

                                            // InstancePositionIDP690E6110CC9042F0B7E64B4A3D7C4DF1.option("value", companyData.PositionID || null);

                                        } else {

                                            console.warn("?? Không tìm th?y Result trong response");

                                            aiResult = { Result: "Không có dữ liệu" };

                                        }

                                    } catch (error) {

                                        console.error(''Error parsing AI response:'', error);

                                        uiManager.showAlert({ type: "error", message: "Đã xảy ra lỗi khi phân tích, vui lòng thử lại!" });



                                    }

                                },

                                error: function (error) {

                                    // Hide loading indicators on error

                                    hideAIProcessingLoader();

                                    console.error(''AI API call failed:'', error);

                                    uiManager.showAlert({ type: "error", message: "Đã xảy ra lỗi khi phân tích, vui lòng thử lại!" });

                                }

                            })



                        }

                    } catch (error) {

                        hideAIProcessingLoader();

                        console.error(''Failed to upload file:'', error);

                        isProcessingImage = false; // Kết thúc xử lý

                        uiManager.showAlert({ type: "error", message: "Đã xảy ra lỗi khi tải ảnh lên!" });

                    }

                };

                reader.readAsDataURL(file);

            }



            function clearImagePreview() {

                imageInput.value = '''';

                imagePreviewContainer.style.display = ''none'';

                imageDropZone.style.display = ''flex'';

                window.selectedImageFile = null;

                window.selectedImageData = null;

                window.uploadedImagePath = null;



            }



            window.clearImagePreview = clearImagePreview;



         function resetSaveButtonState() {

                const overlay = document.getElementById(''aiProcessingOverlay'');

                const indicator = document.getElementById(''imageProcessingIndicator'');

                const modalContent = document.querySelector(''#dataCollectionModal .modal-content'');

                const saveBtn = document.getElementById(''btnSaveDataCollection'');



                if (overlay) overlay.classList.remove(''show'');

                if (indicator) indicator.classList.remove(''show'');

                if (modalContent) modalContent.classList.remove(''processing'');



                if (saveBtn) {

                    if (!saveBtn.dataset.defaultLabel) {

                        saveBtn.dataset.defaultLabel = saveBtn.innerHTML;

                    }

                    saveBtn.disabled = false;

                    saveBtn.innerHTML = saveBtn.dataset.defaultLabel;

 }

            }



            // Loading indicator functions

            function showAIProcessingLoader() {

                // Show main overlay

                document.getElementById(''aiProcessingOverlay'').classList.add(''show'');



                // Show mini indicator on image

                document.getElementById(''imageProcessingIndicator'').classList.add(''show'');



                // Disable modal interactions

                document.querySelector(''#dataCollectionModal .modal-content'').classList.add(''processing'');



                // Disable save button

                const saveBtn = document.getElementById(''btnSaveDataCollection'');

                if (saveBtn) {

                    if (!saveBtn.dataset.defaultLabel) {

                        saveBtn.dataset.defaultLabel = saveBtn.innerHTML;

                    }

                    saveBtn.disabled = true;

                    saveBtn.innerHTML = ''<i class="bi bi-hourglass-split"></i> Đang xử lý...'';

                }

            }



            function hideAIProcessingLoader() {

                resetSaveButtonState();

            }



            $(''#dataCollectionModal'').off(''hidden.bs.modal.saveState'').on(''hidden.bs.modal.saveState'', function () {

                resetSaveButtonState();

                isProcessingImage = false;

            });



            // Export loading functions to window scope

            window.showAIProcessingLoader = showAIProcessingLoader;

            window.hideAIProcessingLoader = hideAIProcessingLoader;



            initDataCollection();



        })();

    </script>



</div>

	'

       -- exec sptblCommonControlType_Signed_DUC 'sp_KPIListDataCollection_html'
    -- EXEC sp_GenerateHTMLScript_new 'sp_KPIListDataCollection_html'

    SELECT @html AS html;

END

GO

-- PHASE 3: Wrapper
IF OBJECT_ID('dbo.sp_KPIListDataCollection','P') IS NOT NULL DROP PROCEDURE dbo.sp_KPIListDataCollection;
GO
CREATE PROCEDURE dbo.sp_KPIListDataCollection (@LoginID int, @LanguageID varchar(5)='VN')
AS BEGIN SET NOCOUNT ON;
    SELECT TOP 1 html FROM dbo.tblHtmlScriptCache
    WHERE TableName='sp_KPIListDataCollection_html' AND ScreenType='-1' AND LanguageID=@LanguageID;
END
GO

-- PHASE 4: Metadata + language + permission
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @MenuID varchar(100) = 'MnuKPI003';
    DECLARE @ParentMenuID varchar(100) = 'MnuKPI000';
    DECLARE @ClassName varchar(100) = 'sp_KPIListDataCollection';
    DECLARE @AssemblyName varchar(100) = 'DataSetting';
    DECLARE @ObjectName varchar(200) = @AssemblyName + '.' + @ClassName;
    DECLARE @Priority int = 2, @Glyphicon nvarchar(100) = N'UserList';
    DECLARE @GroupID varchar(100) = @ParentMenuID;
    DECLARE @IsWeb int=0, @ViewOnWeb int=0, @IsShowLayOutWeb int=0,
            @IsUseMobileDevice int=1, @IsShowInMobileLayOut int=0;
    DECLARE @AdminLoginID int=3, @FullAccess nvarchar(10)=N'32';

    -- MEN_Menu
    IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = @MenuID)
        INSERT INTO MEN_Menu
            (MenuID, ClassName, AssemblyName, ParentMenuID, Priority,
             IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb, IsUseMobileDevice, isShowInMobileLayOut,
             glyphicon, GroupID)
        VALUES (@MenuID, @ClassName, @AssemblyName, @ParentMenuID, @Priority,
                1, @IsWeb, @ViewOnWeb, @IsShowLayOutWeb, @IsUseMobileDevice, @IsShowInMobileLayOut,
                @Glyphicon, @GroupID);
    ELSE
        UPDATE MEN_Menu
           SET ClassName=@ClassName, AssemblyName=@AssemblyName, ParentMenuID=@ParentMenuID,
               Priority=@Priority, IsVisible=1, IsWeb=@IsWeb, ViewOnWeb=@ViewOnWeb,
               isShowLayOutWeb=@IsShowLayOutWeb, IsUseMobileDevice=@IsUseMobileDevice,
               isShowInMobileLayOut=@IsShowInMobileLayOut, glyphicon=@Glyphicon, GroupID=@GroupID
         WHERE MenuID = @MenuID;

    -- tblSC_Object
    DECLARE @ObjectID int, @ParentObjectID int;
    SELECT TOP 1 @ParentObjectID = ObjectID FROM tblSC_Object WHERE Description = @ParentMenuID;
    IF @ParentObjectID IS NULL SET @ParentObjectID = 1;

    IF NOT EXISTS (SELECT 1 FROM tblSC_Object WHERE Description = @MenuID)
    BEGIN
        SET @ObjectID = ISNULL((SELECT MAX(ObjectID) FROM tblSC_Object), 0) + 1;
        INSERT INTO tblSC_Object (ObjectID, ObjectName, Description, Visible, ParentObjectID, ParentObjectRightID, ParentRight)
        VALUES (@ObjectID, @ObjectName, @MenuID, 1, @ParentObjectID, 0, 0);
    END
    ELSE BEGIN
        UPDATE tblSC_Object SET ObjectName=@ObjectName, Visible=1, ParentObjectID=@ParentObjectID
         WHERE Description = @MenuID;
        SELECT TOP 1 @ObjectID = ObjectID FROM tblSC_Object WHERE Description = @MenuID;
    END

    -- tblSC_Right_Stored
    IF NOT EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID=@ObjectID AND LoginID=@AdminLoginID)
        INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@ObjectID, @AdminLoginID, @FullAccess);
    ELSE
        UPDATE tblSC_Right_Stored SET FullAccess=@FullAccess WHERE ObjectID=@ObjectID AND LoginID=@AdminLoginID;

    -- Cache build
    EXEC dbo.sp_GenerateHTMLScript 'sp_KPIListDataCollection_html';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT '[ERROR] Line '+CAST(ERROR_LINE() AS varchar(10))+': '+ERROR_MESSAGE();
    THROW;
END CATCH
GO

-- PHASE 5: Refresh menu cache (CHỈ 1 lệnh — Rule 1)
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_KPIListDataCollection';
GO

PRINT '[SUCCESS] Migration Menu MnuKPI003 Completed!';