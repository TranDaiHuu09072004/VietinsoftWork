/* =============================================================================
   migrate_MnuREC033_TemplateEmailType_20260525.sql
   ---------------------------------------------------------------------------
   Mục đích:
     Thiết lập để menu MnuREC033 (Loại Template Email) là menu web chuẩn mới
     và là con của menu Tuyển Dụng (MnuREC001) giống như menu MnuREC048.
   
   Phân tích cấu trúc & giải pháp:
     1. Khôi phục/Tạo Grid Data SP:
        - Grid trong sp_REC_TemplateEmailType_html tải dữ liệu bằng Ajax gọi tới
          stored procedure sp_REC_TemplateEmailType.
        - Tuy nhiên, trên giao diện web chuẩn mới, khi click menu, hệ thống sẽ
          thực thi stored procedure trùng tên với ClassName của menu (hiện tại là
          sp_REC_EditTemplateEmailType - không đúng vì đây là edit form, hoặc
          sp_REC_TemplateEmailType - bị trùng với data SP).
        - Giải pháp:
          + Tạo mới sp_REC_TemplateEmailTypeList làm nguồn dữ liệu (Grid Data SP)
            giống như sp_REC_TemplateEmailList của MnuREC048.
          + Chuyển sp_REC_TemplateEmailType thành Wrapper Procedure để trả về
            HTML của Grid từ cache (giống như sp_REC_TemplateEmail).
     2. Cập nhật Grid Renderer sp_REC_TemplateEmailType_html:
        - Sửa Ajax load data để gọi sp_REC_TemplateEmailTypeList thay vì
          sp_REC_TemplateEmailType.
     3. Khôi phục/Tạo Edit Popup Wrapper sp_REC_EditTemplateEmailType:
        - Tạo mới sp_REC_EditTemplateEmailType để trả về HTML của edit form
          sp_REC_EditTemplateEmailType_html từ cache.
     4. Tạo Edit Popup Renderer sp_REC_EditTemplateEmailType_html:
        - Tạo mới sp_REC_EditTemplateEmailType_html chứa mã HTML/JS của form sửa
          loại email (kết nối với sp_REC_TemplateEmailTypeEdit để Lưu/Xóa).
     5. Cấu hình MEN_Menu cho MnuREC033:
        - Đặt ClassName = 'sp_REC_TemplateEmailType' (trỏ tới Wrapper Grid).
        - Thiết lập: IsWeb = 1, isShowLayOutWeb = 1, IsUseMobileDevice = 0,
          IsHiddenInTree = 0, IsVisible = 1, ParentMenuID = 'MnuREC001'.
     6. Rebuild cache:
        - Chạy DUC compiler cho các control.
        - Chạy sp_GenerateHTMLScript biên dịch HTML.
        - Chạy sp_Men_Menu_AfterSave_Simple xóa cache menu client.
   
   Database: Paradise_Dev (SVRVTS01\SQL2022)
   ============================================================================= */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'================================================================';
PRINT N' BẮT ĐẦU MIGRATION MENU MnuREC033 — LOẠI TEMPLATE EMAIL';
PRINT N'================================================================';
GO

/* =============================================================================
   1. TẠO DATA SP MỚI: sp_REC_TemplateEmailTypeList
   ============================================================================= */
PRINT N'1. Tạo Grid Data SP: sp_REC_TemplateEmailTypeList...';
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_REC_TemplateEmailTypeList]
    @LoginID    INT          = NULL,
    @LanguageID VARCHAR(2)   = 'VN',
    @PageSize   INT          = 9999,
    @PageIndex  INT          = 1,
    @Filter     NVARCHAR(MAX)= NULL,
    @Sort       NVARCHAR(MAX)= NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        EmailType AS ID,
        ROW_NUMBER() OVER (ORDER BY EmailType ASC) AS STT,
        EmailType,
        EmailTypeName
    FROM tblEmailType;
END
GO

/* =============================================================================
   2. CẬP NHẬT GRID RENDERER: sp_REC_TemplateEmailType_html
   - Trỏ nguồn dữ liệu từ sp_REC_TemplateEmailType về sp_REC_TemplateEmailTypeList
   ============================================================================= */
PRINT N'2. Cập nhật Grid Renderer: sp_REC_TemplateEmailType_html...';
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_REC_TemplateEmailType_html]
    @LoginID    INT        = 3,
    @LanguageID VARCHAR(2) = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @html NVARCHAR(MAX);

    -- Lấy UID được sinh động từ compiler cho GridRECEmailType
    DECLARE @GridRECEmailType_UID VARCHAR(50);
    SELECT TOP 1 @GridRECEmailType_UID = UID 
    FROM tblCommonControlType_Signed 
    WHERE TableName = 'sp_REC_TemplateEmailType_html' AND ColumnName = 'GridRECEmailType';

    SET @html = N'
<div id="sp_REC_TemplateEmailType_html">
    <div id="GridRECEmailType" style="height:100%"></div>
</div>

<script>
  (() => {
    let DataSource = [];

    let _showtoolbarGrid_' + @GridRECEmailType_UID + ' = true;

    window.currentClicked_GridRECEmailType = null;
    window.currentClickedGridRECEmailType  = null;

    function openEditPopup(rowData) {
        window.currentClickedGridRECEmailType  = rowData || null;
        window.currentClicked_GridRECEmailType = rowData ? rowData.EmailType : null;

        AjaxHPAParadise({
            data: { name: "sp_REC_EditTemplateEmailType", param: ["LoginID", LoginID, "LanguageID", LanguageID] },
            success: function(res) {
                const json = typeof res === "string" ? JSON.parse(res) : res;
                const html = json?.data?.[0]?.[0]?.html || json?.html || "";

                const title = rowData ? "Sửa loại email" : "Thêm loại email";
                showEditPopupHTML(html, title);
            }
        });
    }

    // ============================================================
    // Gán các hàm cho Toolbar framework sinh ra (dựa theo khóa chính là ID)
    // Phải khai báo function cục bộ TRƯỚC KHI nạp loadUI
    // ============================================================
    function addID() {
        openEditPopup(null);
    }

    function openDetailID(rowData) {
        openEditPopup(rowData);
    }

    '
    + ISNULL(CAST((
        SELECT loadUI FROM tblCommonControlType_Signed
        WHERE TableName = 'sp_REC_TemplateEmailType_html' AND ColumnName = 'GridRECEmailType'
    ) AS NVARCHAR(MAX)), '') + N'

    function ReloadData() {
        AjaxHPAParadise({
            data: { name: "sp_REC_TemplateEmailTypeList", param: [] },
            success: function(res) {
                const json = typeof res === "string" ? JSON.parse(res) : res;
                let results = Array.isArray(json?.data?.[0]) ? json.data[0]
                            : (json?.data?.[0] ? [json.data[0]] : []);

                if (results.length > 0 && Array.isArray(results[0])) {
                    results = results.map(row => ({
                        ID:            row[0],
                        STT:           row[1],
                        EmailType:     row[2],
                        EmailTypeName: row[3]
                      }));
                }

                DataSource = results;
                const gridEl = $("#GridRECEmailType");
                if (gridEl.length && gridEl.data("dxDataGrid")) {
                    const inst = gridEl.dxDataGrid("instance");
                    inst.state(null);
                    inst.option("dataSource", DataSource);
                }
            }
        });
    }

    if (typeof restoreFilterState === "function") restoreFilterState();

    ReloadData();

    $(document)
        .off("onHpaAutoSaveSuccess.GridRECEmailType")
        .on("onHpaAutoSaveSuccess.GridRECEmailType", function(e) {
            const detail = e.originalEvent?.detail;
            if (detail && detail.tableName &&
               (detail.tableName === "sp_REC_TemplateEmailType" ||
                detail.tableName === "sp_REC_TemplateEmailTypeList" ||
                detail.tableName === "sp_REC_TemplateEmailType_html")) {
                ReloadData();
            }
        });
  })();
</script>
    ';

    SELECT @html AS html;
END
GO

/* =============================================================================
   3. CHUYỂN ĐỔI DATA SP CŨ THÀNH MENU GRID WRAPPER: sp_REC_TemplateEmailType
   ============================================================================= */
PRINT N'3. Tạo Wrapper Procedure cho Menu Grid: sp_REC_TemplateEmailType...';
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_REC_TemplateEmailType]
    @LoginID    INT          = NULL,
    @LanguageID VARCHAR(2)   = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT html 
    FROM tblHtmlScriptCache 
    WHERE TableName = 'sp_REC_TemplateEmailType_html' AND ScreenType = -1 AND LanguageID = @LanguageID;
END
GO

/* =============================================================================
   4. TẠO WRAPPER CHO POPUP CHỈNH SỬA: sp_REC_EditTemplateEmailType
   ============================================================================= */
PRINT N'4. Tạo Wrapper cho Edit Popup: sp_REC_EditTemplateEmailType...';
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_REC_EditTemplateEmailType]
    @LoginID    INT          = NULL,
    @LanguageID VARCHAR(2)   = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT html 
    FROM tblHtmlScriptCache 
    WHERE TableName = 'sp_REC_EditTemplateEmailType_html' AND ScreenType = -1 AND LanguageID = @LanguageID;
END
GO

/* =============================================================================
   5. TẠO RENDERER CHO POPUP CHỈNH SỬA: sp_REC_EditTemplateEmailType_html
   ============================================================================= */
PRINT N'5. Tạo Renderer cho Edit Popup: sp_REC_EditTemplateEmailType_html...';
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_REC_EditTemplateEmailType_html]
    @LoginID    INT        = 3,
    @LanguageID VARCHAR(2) = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @html NVARCHAR(MAX) = N'';

    DECLARE @UID_EmailTypeName VARCHAR(50);
    SELECT @UID_EmailTypeName = UID 
    FROM tblCommonControlType_Signed 
    WHERE TableName = 'sp_REC_EditTemplateEmailType_html' AND ColumnName = 'EmailTypeName';

    SET @html = N'
<style>
  #sp_REC_EditTemplateEmailType_html .form-body {
    display: flex;
    flex-direction: column;
    gap: 20px;
    margin-bottom: 28px;
  }
  #sp_REC_EditTemplateEmailType_html .form-group-item-inline {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 16px;
  }
  #sp_REC_EditTemplateEmailType_html .form-label {
    flex: 0 0 160px;
    font-size: 11px;
    font-weight: 700;
    color: var(--paradise-color-secondary, #64748b);
    text-transform: uppercase;
    letter-spacing: 0.8px;
    margin-bottom: 0;
  }
  #sp_REC_EditTemplateEmailType_html .form-footer-actions {
    display: flex;
    justify-content: flex-end;
    gap: 12px;
    border-top: 1px solid var(--paradise-color-input-border, #e2e8f0);
    padding-top: 20px;
  }
  #sp_REC_EditTemplateEmailType_html .btn-form-action {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 8px 18px;
    font-size: 13px;
    font-weight: 600;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    border: 1px solid transparent;
  }
  #sp_REC_EditTemplateEmailType_html .btn-cancel {
    background-color: transparent;
    border-color: var(--paradise-color-input-border, #cbd5e1);
    color: var(--paradise-color-secondary, #64748b);
  }
  #sp_REC_EditTemplateEmailType_html .btn-cancel:hover {
    background-color: var(--background-color-hover, #f1f5f9);
    border-color: var(--paradise-color-secondary, #94a3b8);
  }
  #sp_REC_EditTemplateEmailType_html .btn-save {
    background-color: var(--paradise-color-success, #198754);
    color: #ffffff;
    box-shadow: 0 4px 12px rgba(25,135,84,0.15);
  }
  #sp_REC_EditTemplateEmailType_html .btn-save:hover {
    background-color: var(--paradise-color-success-dark, #157347);
    transform: translateY(-1px);
    box-shadow: 0 6px 16px rgba(25,135,84,0.25);
  }
  #sp_REC_EditTemplateEmailType_html .btn-save:active { transform: translateY(0); }
  #sp_REC_EditTemplateEmailType_html .btn-delete {
    background-color: var(--paradise-color-danger, #dc3545);
    color: #ffffff;
    box-shadow: 0 4px 12px rgba(220,53,69,0.15);
  }
  #sp_REC_EditTemplateEmailType_html .btn-delete:hover {
    background-color: #b21f2d;
    transform: translateY(-1px);
    box-shadow: 0 6px 16px rgba(220,53,69,0.25);
  }
  #sp_REC_EditTemplateEmailType_html .btn-delete:active { transform: translateY(0); }
</style>

<div id="sp_REC_EditTemplateEmailType_html" class="edit-form-wrapper p-3">
  <div class="edit-form-card">
    <div class="form-body">
      <!-- Tên loại email (TextBox) -->
      <div class="form-group-item form-group-item-inline">
        <label class="form-label">Tên loại email</label>
        <div id="' + ISNULL(@UID_EmailTypeName, '') + N'" style="flex: 1"></div>
      </div>
    </div>

    <div class="form-footer-actions">
      <button class="btn-form-action btn-delete"
              onclick="onDeleteEditEmailType()"
              style="display:none; margin-right:auto">
        <i class="fas fa-trash-alt me-1"></i>Xóa
      </button>
      <button class="btn-form-action btn-cancel" onclick="onCancelEditEmailType()">
        <i class="fas fa-times me-1"></i>Hủy bỏ
      </button>
      <button class="btn-form-action btn-save" onclick="onSaveEditEmailType()">
        <i class="fas fa-check me-1"></i>Lưu lại
      </button>
    </div>
  </div>
</div>

<script>
  (() => {
    // ============================================================
    // 1. INJECT UI CONTROLS
    // ============================================================
    ' + ISNULL(CAST((SELECT loadUI FROM tblCommonControlType_Signed WHERE TableName = 'sp_REC_EditTemplateEmailType_html' AND ColumnName = 'EmailTypeName') AS NVARCHAR(MAX)), '') + N'

    // ============================================================
    // 2. NẠP DỮ LIỆU
    // ============================================================
    function ReloadData() {
        const obj = window.currentClickedGridRECEmailType || {
            "EmailType": null,
            "EmailTypeName": null
        };

        if (window.currentClickedGridRECEmailType) {
            _autoSaveEmailTypeName' + ISNULL(@UID_EmailTypeName, '') + N' = true;
        } else {
            _autoSaveEmailTypeName' + ISNULL(@UID_EmailTypeName, '') + N' = false;
        }

        // Load dữ liệu vào TextBox
        ' + ISNULL(CAST((SELECT loadData FROM tblCommonControlType_Signed WHERE TableName = 'sp_REC_EditTemplateEmailType_html' AND ColumnName = 'EmailTypeName') AS NVARCHAR(MAX)), '') + N'

        // Điều khiển nút Lưu / Xóa
        const currentID = window.currentClicked_GridRECEmailType;
        if (currentID) {
            $("#sp_REC_EditTemplateEmailType_html .btn-save").hide();
            $("#sp_REC_EditTemplateEmailType_html .btn-delete").show();
        } else {
            $("#sp_REC_EditTemplateEmailType_html .btn-save").show();
            $("#sp_REC_EditTemplateEmailType_html .btn-delete").hide();
        }
    }

    // ============================================================
    // 3. XỬ LÝ CÁC NÚT HÀNH ĐỘNG
    // ============================================================
    window.onCancelEditEmailType = function() {
        try {
            const $popups = $(".dx-popup:visible");
            if ($popups.length > 0) {
                $popups.each(function() {
                    try {
                        const popup = $(this).dxPopup("instance");
                        if (popup && popup.option("visible")) popup.hide();
                    } catch(e) {}
                });
            } else {
                $("#edit-popup-container").removeClass("open");
            }
        } catch(ex) {
            $("#edit-popup-container").removeClass("open");
        }
    };

    window.onSaveEditEmailType = async function() {
        try {
            let emailTypeName = "";
            try {
                emailTypeName = typeof InstanceEmailTypeName' + ISNULL(@UID_EmailTypeName, '') + N' !== "undefined"
                    ? InstanceEmailTypeName' + ISNULL(@UID_EmailTypeName, '') + N'.option("value")
                    : "";
            } catch(e) {
                emailTypeName = $("#' + ISNULL(@UID_EmailTypeName, '') + N'").val() || "";
            }

            if (!emailTypeName || emailTypeName.trim() === "") {
                uiManager.showAlert({ type: "danger", message: "Vui lòng nhập tên loại email!" });
                return;
            }

            const currentID = window.currentClicked_GridRECEmailType || "";

            const dataJSON = JSON.stringify({
                EmailType:     currentID,
                EmailTypeName: emailTypeName.trim()
            });

            AjaxHPAParadise({
                data: {
                    name: "sp_REC_TemplateEmailTypeEdit",
                    param: [
                        "LoginID",    window.LoginID || window.UserID,
                        "JsonData",   dataJSON,
                        "Type",       1,
                        "LanguageID", window.LanguageID || "VN"
                    ]
                },
                success: function(res) {
                    let data = res;
                    if (typeof data === "string" && !IsNullOrEmpty(data))
                        data = data.includes("{") ? data : EncryptionStringDecryption(data);

                    const json = typeof data === "string" ? JSON.parse(data) : data;
                    const statusRow = json?.data?.[0]?.[0] || json?.[0] || json || {};

                    if (statusRow.Status === "SUCCESS" || json?.Status === "SUCCESS") {
                        uiManager.showAlert({ type: "success", message: statusRow.Message || "Lưu thành công!" });

                        const newRow = json?.data?.[1]?.[0];
                        if (newRow && window.updateSharedGridRow)
                            window.updateSharedGridRow("GridRECEmailType", newRow);

                        onCancelEditEmailType();
                    } else {
                        uiManager.showAlert({ type: "danger", message: statusRow.Message || "Gặp lỗi khi lưu dữ liệu!" });
                    }
                },
                error: function() {
                    uiManager.showAlert({ type: "danger", message: "Không thể kết nối đến máy chủ!" });
                }
            });
        } catch(ex) {
            uiManager.showAlert({ type: "danger", message: "Lưu thất bại: " + ex });
        }
    };

    window.onDeleteEditEmailType = function() {
        const currentID = window.currentClicked_GridRECEmailType || "";
        if (!currentID) return;

        showConfirmPopup({
            title:   "Xóa loại email?",
            message: "Bạn có chắc chắn muốn xóa loại email này không?",
            YesText: "Xóa",
            NoText:  "Hủy",
            onYes: () => {
                try {
                    const dataJSON = JSON.stringify({ EmailType: currentID });

                    AjaxHPAParadise({
                        data: {
                            name: "sp_REC_TemplateEmailTypeEdit",
                            param: [
                                "LoginID",    window.LoginID || window.UserID,
                                "JsonData",   dataJSON,
                                "Type",       2,
                                "LanguageID", window.LanguageID || "VN"
                            ]
                        },
                        success: function(res) {
                            let data = res;
                            if (typeof data === "string" && !IsNullOrEmpty(data))
                                data = data.includes("{") ? data : EncryptionStringDecryption(data);

                            const json = typeof data === "string" ? JSON.parse(data) : data;
                            const statusRow = json?.data?.[0]?.[0] || json?.[0] || json || {};

                            if (statusRow.Status === "SUCCESS" || json?.Status === "SUCCESS") {
                                uiManager.showAlert({ type: "success", message: statusRow.Message || "Xóa thành công!" });
                                if (window.removeSharedGridRow)
                                    window.removeSharedGridRow("GridRECEmailType", { key: currentID });
                                onCancelEditEmailType();
                            } else {
                                uiManager.showAlert({ type: "danger", message: statusRow.Message || "Xóa thất bại!" });
                            }
                        },
                        error: function() {
                            uiManager.showAlert({ type: "danger", message: "Không thể kết nối đến máy chủ!" });
                        }
                    });
                } catch(ex) {
                    uiManager.showAlert({ type: "danger", message: "Lỗi khi xóa: " + ex });
                }
            }
        });
    };

    ReloadData();
  })();
</script>
';

    SELECT @html AS html;
END
GO

/* =============================================================================
   6. CẬP NHẬT CẤU HÌNH MENU: MEN_Menu
   ============================================================================= */
PRINT N'6. Cập nhật metadata trong MEN_Menu cho MnuREC033...';
GO

UPDATE dbo.MEN_Menu
SET ParentMenuID = 'MnuREC001',
    AssemblyName = 'DataSetting',
    ClassName = 'sp_REC_TemplateEmailType',
    IsWeb = 1,
    isShowLayOutWeb = 1,
    IsUseMobileDevice = 0,
    IsHiddenInTree = 0,
    IsVisible = 1
WHERE MenuID = 'MnuREC033';
GO

/* =============================================================================
   7. COMPILE & REBUILD CACHE
   ============================================================================= */
PRINT N'7. Compile controls, Rebuild HTML cache và Clear Menu Cache...';
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- Compile control scripts từ metadata
    EXEC dbo.sptblCommonControlType_Signed_DUC 'sp_REC_TemplateEmailType_html';
    EXEC dbo.sptblCommonControlType_Signed_DUC 'sp_REC_EditTemplateEmailType_html';

    -- Xóa cache cũ và rebuild cache mới
    DELETE FROM dbo.tblHtmlScriptCache 
    WHERE TableName IN (N'sp_REC_TemplateEmailType_html', N'sp_REC_EditTemplateEmailType_html', N'sp_REC_EditTemplateEmailType');

    EXEC dbo.sp_GenerateHTMLScript 'sp_REC_TemplateEmailType_html';
    EXEC dbo.sp_GenerateHTMLScript 'sp_REC_EditTemplateEmailType_html';
    
    -- Cache lại Wrapper Form cho edit popup
    EXEC dbo.sp_GenerateHTMLScript 'sp_REC_EditTemplateEmailType', 'VN', 'sp_REC_EditTemplateEmailType_html';
    EXEC dbo.sp_GenerateHTMLScript 'sp_REC_EditTemplateEmailType', 'EN', 'sp_REC_EditTemplateEmailType_html';

    -- Đồng bộ lại menu cache
    EXEC dbo.sp_Men_Menu_AfterSave_Simple;

    COMMIT TRANSACTION;
    PRINT N'  [OK] Đã DUC, rebuild cache HTML và xóa cache menu thành công!';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @err NVARCHAR(MAX) = ERROR_MESSAGE();
    PRINT N'  [LỖI] ' + @err;
    THROW;
END CATCH
GO

PRINT N'================================================================';
PRINT N' HOÀN TẤT MIGRATION CỦA MENU MnuREC033.';
PRINT N'================================================================';
GO
