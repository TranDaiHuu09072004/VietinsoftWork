/* =============================================================================
   recreate_MnuREC033_EditEmailTemplate_Huu_20260525.sql
   ---------------------------------------------------------------------------
   Mục đích:
     1. Tạo lại menu MnuREC033 đặt tên là "Tạo mẫu email" ở cả tiếng Việt và tiếng Anh.
     2. Tạo stored procedure sp_REC_EditTemplateEmailType làm wrapper menu để 
        hiển thị danh sách mẫu email theo chuẩn ParadiseStyle.
     3. Tạo stored procedure sp_REC_EditEmailTemplate_Huu làm wrapper edit form,
        truyền vào TemplateName để hiển thị nội dung email cần chỉnh sửa từ tblEmailTemplate.
        Hỗ trợ các chức năng thêm mới, sửa, xóa.
     4. Đăng ký các controls, đặc biệt control Body kiểu hpaControlRichTextEditorPremium 
        trong bảng tblCommonControlType_Signed.
     5. Cấp quyền ban đầu và rebuild cache.
   
   Database: Paradise_Dev (SVRVTS01\SQL2022)
   ============================================================================= */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'================================================================';
PRINT N' BẮT ĐẦU TẠO LẠI MENU MnuREC033 & GIAO DIỆN EDIT TEMPLATE';
PRINT N'================================================================';
GO

/* =============================================================================
   1. ĐĂNG KÝ TÊN HIỂN THỊ MENU ĐA NGÔN NGỮ (VN & EN)
   ============================================================================= */
PRINT N'1. Thiết lập nhãn hiển thị menu cho MnuREC033...';
GO

-- Tiếng Việt
IF EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'MnuREC033' AND [Language] = 'VN')
    UPDATE dbo.tblMD_Message SET Content = N'Tạo mẫu email' WHERE MessageID = 'MnuREC033' AND [Language] = 'VN';
ELSE
    INSERT INTO dbo.tblMD_Message (MessageID, [Language], Content) VALUES ('MnuREC033', 'VN', N'Tạo mẫu email');

-- Tiếng Anh
IF EXISTS (SELECT 1 FROM dbo.tblMD_Message WHERE MessageID = 'MnuREC033' AND [Language] = 'EN')
    UPDATE dbo.tblMD_Message SET Content = N'Tạo mẫu email' WHERE MessageID = 'MnuREC033' AND [Language] = 'EN';
ELSE
    INSERT INTO dbo.tblMD_Message (MessageID, [Language], Content) VALUES ('MnuREC033', 'EN', N'Tạo mẫu email');
GO

/* =============================================================================
   2. CẤP QUYỀN TRUY CẬP VÀ ĐĂNG KÝ ĐỐI TƯỢNG BẢO MẬT
   ============================================================================= */
PRINT N'2. Tạo đối tượng bảo mật và sao chép phân quyền từ MnuREC048...';
GO

-- Xóa đối tượng cũ nếu còn sót
DELETE FROM dbo.tblSC_Right_Stored WHERE ObjectID IN (SELECT ObjectID FROM dbo.tblSC_Object WHERE Description = 'MnuREC033' OR ObjectName = 'DataSetting.sp_REC_EditTemplateEmailType');
DELETE FROM dbo.tblSC_Object WHERE Description = 'MnuREC033' OR ObjectName = 'DataSetting.sp_REC_EditTemplateEmailType';

-- Tạo ObjectID mới
DECLARE @NewObjectID INT = ISNULL((SELECT MAX(ObjectID) FROM dbo.tblSC_Object), 0) + 1;

-- Xóa sạch mọi quyền mồ côi (orphan rights) của ObjectID mới này nếu có trong tblSC_Right_Stored
DELETE FROM dbo.tblSC_Right_Stored WHERE ObjectID = @NewObjectID;

INSERT INTO dbo.tblSC_Object (ObjectID, ObjectName, Description, Visible, ParentObjectID)
VALUES (@NewObjectID, 'DataSetting.sp_REC_EditTemplateEmailType', 'MnuREC033', 1, 495);

-- Copy phân quyền từ MnuREC048 (Quản lý Template email)
INSERT INTO dbo.tblSC_Right_Stored (LoginID, ObjectID, FullAccess)
SELECT LoginID, @NewObjectID, FullAccess
FROM dbo.tblSC_Right_Stored
WHERE ObjectID = 499;

PRINT N'  [OK] Đã hoàn tất đăng ký bảo mật và phân quyền.';
GO

/* =============================================================================
   3. CẤU HÌNH MENU MnuREC033 TRONG MEN_Menu
   ============================================================================= */
PRINT N'3. Tạo mới cấu hình menu MnuREC033 trong MEN_Menu...';
GO

IF EXISTS (SELECT 1 FROM dbo.MEN_Menu WHERE MenuID = 'MnuREC033')
    DELETE FROM dbo.MEN_Menu WHERE MenuID = 'MnuREC033';

INSERT INTO dbo.MEN_Menu (
    MenuID, ClassName, Priority, IsModal, ParentMenuID, LinkMenuID, IsCollapsed, 
    AssemblyName, ShortcutKeys, IsVisible, SupperAdmin, LargeTile, Colors, 
    superForm, DefaultParam, Notification, IsWeb, URL, IsNotAjax, glyphicon, 
    GroupID, InstructionID, showDialog, ProcessDataForNotifyProc, Showinsuperform, 
    Activity, ViewOnWeb, Separation, MobileDeviceGroup, IsUseMobileDevice, 
    PriorityMobileDevice, IsLeftMenu, NotUsePlatform, OptionAuthentication, 
    IconBackColor, IconForeColor, isParentMenu, ParentMenuMobileID, 
    isShowInMobileLayOut, isShowLayOutWeb, IsHiddenInTree
)
VALUES (
    'MnuREC033', 'sp_REC_EditTemplateEmailType', 60, 0, 'MnuREC001', '', 0, 
    'DataSetting', '', 1, 0, 0, '', 
    '', '', 0, 1, '', 0, 'Email', 
    'MnuREC001', '', 0, '', 0, 
    'DataSettingListViewActivity', 0, 1, 'MnuTAD000', 0, 
    1, 0, '2', 0, '', '', 0, '', 
    0, 1, 0
);
GO

/* =============================================================================
   4. ĐĂNG KÝ METADATA CONTROLS TRONG tblCommonControlType_Signed
   ============================================================================= */
PRINT N'4. Đăng ký cấu hình các controls (Grid & Edit Form)...';
GO

DELETE FROM dbo.tblCommonControlType_Signed 
WHERE TableName IN ('sp_REC_EditTemplateEmailType_html', 'sp_REC_EditEmailTemplate_Huu_html');

-- A. Đăng ký Grid trong sp_REC_EditTemplateEmailType_html
INSERT INTO dbo.tblCommonControlType_Signed (ID, TableName, ColumnName, ColumnIDName, Type, TableEditor, DisplayName, DataSourceSP, UID)
VALUES (
    'PHUUGRIID0000000000000000000000', 
    'sp_REC_EditTemplateEmailType_html', 
    'GridEditEmailTemplate_Huu', 
    'ID', 
    'hpaControlGrid_Duc', 
    'tblEmailTemplate', 
    N'Danh sách mẫu email', 
    'sp_REC_EditEmailTemplate_Huu_List', 
    'PHUUGRIID0000000000000000000000'
);

-- B. Đăng ký các cột cho Grid
INSERT INTO dbo.tblCommonControlType_Signed (ID, TableName, ColumnName, Type, GridColumnName, DisplayName, UID)
VALUES 
('PHUUSTTCOL000000000000000000000', 'sp_REC_EditTemplateEmailType_html', 'STT', 'hpaControlNumber', 'GridEditEmailTemplate_Huu', N'STT', 'PHUUSTTCOL000000000000000000000'),
('PHUUTEMPLATECOL000000000000000', 'sp_REC_EditTemplateEmailType_html', 'TemplateName', 'hpaControlText', 'GridEditEmailTemplate_Huu', N'Tên Template', 'PHUUTEMPLATECOL000000000000000'),
('PHUUSUBJECTCOL0000000000000000', 'sp_REC_EditTemplateEmailType_html', 'Subject', 'hpaControlText', 'GridEditEmailTemplate_Huu', N'Tiêu đề email', 'PHUUSUBJECTCOL0000000000000000'),
('PHUUEMAILCOL000000000000000000', 'sp_REC_EditTemplateEmailType_html', 'Email', 'hpaControlText', 'GridEditEmailTemplate_Huu', N'Tài khoản gửi', 'PHUUEMAILCOL000000000000000000'),
('PHUUACTIVECOL00000000000000000', 'sp_REC_EditTemplateEmailType_html', 'IsActive', 'hpaControlCheckBox', 'GridEditEmailTemplate_Huu', N'Kích hoạt', 'PHUUACTIVECOL00000000000000000');

-- C. Đăng ký 5 controls cho Edit Form sp_REC_EditEmailTemplate_Huu_html
INSERT INTO dbo.tblCommonControlType_Signed (ID, TableName, ColumnName, ColumnIDName, Type, TableEditor, DisplayName, SPLoadData, UID)
VALUES 
('PHUUTEMPLATE000000000000000000', 'sp_REC_EditEmailTemplate_Huu_html', 'TemplateName', 'TemplateName', 'hpaControlText', 'tblEmailTemplate', N'Tên Template', NULL, 'PHUUTEMPLATE000000000000000000'),
('PHUUSUBJECT00000000000000000000', 'sp_REC_EditEmailTemplate_Huu_html', 'Subject', 'TemplateName', 'hpaControlText', 'tblEmailTemplate', N'Tiêu đề email', NULL, 'PHUUSUBJECT00000000000000000000'),
('PHUUEMAILACC000000000000000000', 'sp_REC_EditEmailTemplate_Huu_html', 'EmailAccountId', 'TemplateName', 'hpaControlSelectBox', 'tblEmailTemplate', N'Tài khoản gửi', 'sp_REC_getEmailAccount', 'PHUUEMAILACC000000000000000000'),
('PHUUACTIVE000000000000000000000', 'sp_REC_EditEmailTemplate_Huu_html', 'IsActive', 'TemplateName', 'hpaControlCheckBox', 'tblEmailTemplate', N'Kích hoạt', NULL, 'PHUUACTIVE000000000000000000000'),
('PHUUBODY000000000000000000000000', 'sp_REC_EditEmailTemplate_Huu_html', 'Body', 'TemplateName', 'hpaControlRichTextEditorPremium', 'tblEmailTemplate', N'Nội dung email', NULL, 'PHUUBODY000000000000000000000000');

PRINT N'  [OK] Đã đăng ký controls trong tblCommonControlType_Signed.';
GO

/* =============================================================================
   5. XÂY DỰNG CÁC STORED PROCEDURE
   ============================================================================= */
PRINT N'5. Tạo các stored procedure...';
GO

-- 5.1. Grid Data SP: sp_REC_EditEmailTemplate_Huu_List
PRINT N'  - Tạo sp_REC_EditEmailTemplate_Huu_List...';
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_REC_EditEmailTemplate_Huu_List]
    @LoginID    INT          = 3,
    @LanguageID VARCHAR(2)   = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        et.TemplateName AS ID,
        ROW_NUMBER() OVER (ORDER BY et.TemplateName ASC) AS STT,
        et.TemplateName AS TemplateName,
        et.Subject AS Subject,
        es.Email AS Email,
        et.IsActive AS IsActive
    FROM tblEmailTemplate et
    LEFT JOIN tblEmailSetting es ON et.EmailAccountId = es.ID
    ORDER BY et.TemplateName ASC;
END
GO

-- 5.2. Menu wrapper: sp_REC_EditTemplateEmailType
PRINT N'  - Tạo sp_REC_EditTemplateEmailType...';
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

-- 5.3. Menu Grid Renderer: sp_REC_EditTemplateEmailType_html
PRINT N'  - Tạo sp_REC_EditTemplateEmailType_html...';
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_REC_EditTemplateEmailType_html]
    @LoginID    INT        = 3,
    @LanguageID VARCHAR(2) = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @html NVARCHAR(MAX);

    DECLARE @GridUID VARCHAR(50);
    SELECT TOP 1 @GridUID = UID 
    FROM tblCommonControlType_Signed 
    WHERE TableName = 'sp_REC_EditTemplateEmailType_html' AND ColumnName = 'GridEditEmailTemplate_Huu';

    SET @html = N'
<div id="sp_REC_EditTemplateEmailType_html">
    <div id="GridEditEmailTemplate_Huu" style="height:100%"></div>
</div>

<script>
  (() => {
    let DataSource = [];

    let _showtoolbarGrid_' + @GridUID + ' = true;

    window.currentClicked_GridEditEmailTemplate = null;
    window.currentClickedGridEditEmailTemplate  = null;

    function openEditPopup(rowData) {
        window.currentClickedGridEditEmailTemplate  = rowData || null;
        window.currentClicked_GridEditEmailTemplate = rowData ? rowData.TemplateName : null;

        AjaxHPAParadise({
            data: { 
                name: "sp_REC_EditEmailTemplate_Huu", 
                param: [
                    "TemplateName", rowData ? rowData.TemplateName : "", 
                    "LoginID", LoginID, 
                    "LanguageID", LanguageID
                ] 
            },
            success: function(res) {
                const json = typeof res === "string" ? JSON.parse(res) : res;
                const html = json?.data?.[0]?.[0]?.html || json?.html || "";

                const title = rowData ? "Sửa mẫu email" : "Tạo mẫu email";
                showEditPopupHTML(html, title);
            }
        });
    }

    // ============================================================
    // Gán các hàm cho Toolbar framework sinh ra
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
        WHERE TableName = 'sp_REC_EditTemplateEmailType_html' AND ColumnName = 'GridEditEmailTemplate_Huu'
    ) AS NVARCHAR(MAX)), '') + N'

    function ReloadData() {
        AjaxHPAParadise({
            data: { name: "sp_REC_EditEmailTemplate_Huu_List", param: [] },
            success: function(res) {
                const json = typeof res === "string" ? JSON.parse(res) : res;
                let results = Array.isArray(json?.data?.[0]) ? json.data[0]
                            : (json?.data?.[0] ? [json.data[0]] : []);

                if (results.length > 0 && Array.isArray(results[0])) {
                    results = results.map(row => ({
                        ID:            row[0],
                        STT:           row[1],
                        TemplateName:  row[2],
                        Subject:       row[3],
                        Email:         row[4],
                        IsActive:      row[5]
                    }));
                }

                DataSource = results;
                const gridEl = $("#GridEditEmailTemplate_Huu");
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
        .off("onHpaAutoSaveSuccess.GridEditEmailTemplate_Huu")
        .on("onHpaAutoSaveSuccess.GridEditEmailTemplate_Huu", function(e) {
            const detail = e.originalEvent?.detail;
            if (detail && detail.tableName &&
               (detail.tableName === "tblEmailTemplate" ||
                detail.tableName === "sp_REC_EditEmailTemplate_Huu_List" ||
                detail.tableName === "sp_REC_EditTemplateEmailType_html")) {
                ReloadData();
            }
        });
  })();
</script>
    ';

    SELECT @html AS html;
END
GO

-- 5.4. Edit form wrapper: sp_REC_EditEmailTemplate_Huu
PRINT N'  - Tạo sp_REC_EditEmailTemplate_Huu...';
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_REC_EditEmailTemplate_Huu]
    @TemplateName NVARCHAR(800) = NULL,
    @LoginID      INT           = NULL,
    @LanguageID   VARCHAR(2)    = 'VN'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Subject NVARCHAR(1000) = N'';
    DECLARE @Body NVARCHAR(MAX) = N'';
    DECLARE @EmailAccountId INT = NULL;
    DECLARE @IsActive BIT = 0;

    IF @TemplateName IS NOT NULL AND LTRIM(RTRIM(@TemplateName)) <> ''
    BEGIN
        SELECT @Subject = Subject,
               @Body = Body,
               @EmailAccountId = EmailAccountId,
               @IsActive = IsActive
        FROM tblEmailTemplate
        WHERE TemplateName = @TemplateName;
    END

    DECLARE @html NVARCHAR(MAX) = N'';
    SELECT @html = html 
    FROM tblHtmlScriptCache 
    WHERE TableName = 'sp_REC_EditEmailTemplate_Huu_html' AND ScreenType = -1 AND LanguageID = @LanguageID;

    -- Thay thế giá trị các biến cấu hình khởi tạo của form JS
    IF @TemplateName IS NOT NULL AND LTRIM(RTRIM(@TemplateName)) <> ''
    BEGIN
        SET @html = REPLACE(@html, 'window.currentTemplateName = null;', 'window.currentTemplateName = N''' + REPLACE(@TemplateName, '''', '''''') + ''';');
        SET @html = REPLACE(@html, 'window.currentSubject = null;', 'window.currentSubject = N''' + REPLACE(ISNULL(@Subject, ''), '''', '''''') + ''';');
        SET @html = REPLACE(@html, 'window.currentBody = null;', 'window.currentBody = N''' + REPLACE(ISNULL(@Body, ''), '''', '''''') + ''';');
        SET @html = REPLACE(@html, 'window.currentEmailAccountId = null;', 'window.currentEmailAccountId = ' + ISNULL(CAST(@EmailAccountId AS VARCHAR), 'null') + ';');
        SET @html = REPLACE(@html, 'window.currentIsActive = null;', 'window.currentIsActive = ' + ISNULL(CAST(@IsActive AS VARCHAR), '0') + ';');
    END
    ELSE
    BEGIN
        SET @html = REPLACE(@html, 'window.currentTemplateName = null;', 'window.currentTemplateName = null;');
        SET @html = REPLACE(@html, 'window.currentSubject = null;', 'window.currentSubject = null;');
        SET @html = REPLACE(@html, 'window.currentBody = null;', 'window.currentBody = null;');
        SET @html = REPLACE(@html, 'window.currentEmailAccountId = null;', 'window.currentEmailAccountId = null;');
        SET @html = REPLACE(@html, 'window.currentIsActive = null;', 'window.currentIsActive = null;');
    END

    SELECT @html AS html;
END
GO

-- 5.5. Edit form renderer: sp_REC_EditEmailTemplate_Huu_html
PRINT N'  - Tạo sp_REC_EditEmailTemplate_Huu_html...';
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_REC_EditEmailTemplate_Huu_html]
    @LoginID    INT = 3,
    @LanguageID VARCHAR(2) = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @html NVARCHAR(MAX) = N'';

    DECLARE @UID_TemplateName VARCHAR(50) = 'PHUUTEMPLATE000000000000000000';
    DECLARE @UID_Subject VARCHAR(50) = 'PHUUSUBJECT00000000000000000000';
    DECLARE @UID_EmailAccountId VARCHAR(50) = 'PHUUEMAILACC000000000000000000';
    DECLARE @UID_IsActive VARCHAR(50) = 'PHUUACTIVE000000000000000000000';
    DECLARE @UID_Body VARCHAR(50) = 'PHUUBODY000000000000000000000000';

    SET @html = N'
<style>
  #sp_REC_EditEmailTemplate_Huu_html .form-body {
    display: flex;
    flex-direction: column;
    gap: 16px;
    margin-bottom: 24px;
  }
  #sp_REC_EditEmailTemplate_Huu_html .form-group-item-inline {
    display: flex;
    flex-direction: row;
    align-items: center;
    gap: 16px;
  }
  #sp_REC_EditEmailTemplate_Huu_html .form-label {
    flex: 0 0 140px;
    font-size: 11px;
    font-weight: 700;
    color: var(--paradise-color-secondary, #64748b);
    text-transform: uppercase;
    letter-spacing: 0.8px;
    margin-bottom: 0;
  }
  #sp_REC_EditEmailTemplate_Huu_html .form-footer-actions {
    display: flex;
    justify-content: flex-end;
    gap: 12px;
    border-top: 1px solid var(--paradise-color-input-border, #e2e8f0);
    padding-top: 20px;
  }
  #sp_REC_EditEmailTemplate_Huu_html .btn-form-action {
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
  #sp_REC_EditEmailTemplate_Huu_html .btn-cancel {
    background-color: transparent;
    border-color: var(--paradise-color-input-border, #cbd5e1);
    color: var(--paradise-color-secondary, #64748b);
  }
  #sp_REC_EditEmailTemplate_Huu_html .btn-cancel:hover {
    background-color: var(--background-color-hover, #f1f5f9);
    border-color: var(--paradise-color-secondary, #94a3b8);
  }
  #sp_REC_EditEmailTemplate_Huu_html .btn-save {
    background-color: var(--paradise-color-success, #198754);
    color: #ffffff;
    box-shadow: 0 4px 12px rgba(25,135,84,0.15);
  }
  #sp_REC_EditEmailTemplate_Huu_html .btn-save:hover {
    background-color: var(--paradise-color-success-dark, #157347);
    transform: translateY(-1px);
    box-shadow: 0 6px 16px rgba(25,135,84,0.25);
  }
  #sp_REC_EditEmailTemplate_Huu_html .btn-save:active { transform: translateY(0); }
  #sp_REC_EditEmailTemplate_Huu_html .btn-delete {
    background-color: var(--paradise-color-danger, #dc3545);
    color: #ffffff;
    box-shadow: 0 4px 12px rgba(220,53,69,0.15);
  }
  #sp_REC_EditEmailTemplate_Huu_html .btn-delete:hover {
    background-color: #b21f2d;
    transform: translateY(-1px);
    box-shadow: 0 6px 16px rgba(220,53,69,0.25);
  }
  #sp_REC_EditEmailTemplate_Huu_html .btn-delete:active { transform: translateY(0); }
</style>

<div id="sp_REC_EditEmailTemplate_Huu_html" class="edit-form-wrapper p-3" style="width: 50vw; min-width: 650px;">
  <div class="edit-form-card">
    <div class="form-body">
      <!-- Tên Template -->
      <div class="form-group-item form-group-item-inline">
        <label class="form-label">Tên Template</label>
        <div id="' + @UID_TemplateName + N'" style="flex: 1"></div>
      </div>
      <!-- Tiêu đề email -->
      <div class="form-group-item form-group-item-inline">
        <label class="form-label">Tiêu đề email</label>
        <div id="' + @UID_Subject + N'" style="flex: 1"></div>
      </div>
      <!-- Tài khoản gửi -->
      <div class="form-group-item form-group-item-inline">
        <label class="form-label">Tài khoản gửi</label>
        <div id="' + @UID_EmailAccountId + N'" style="flex: 1"></div>
      </div>
      <!-- Kích hoạt -->
      <div class="form-group-item form-group-item-inline">
        <label class="form-label">Kích hoạt</label>
        <div id="' + @UID_IsActive + N'" style="flex: 1"></div>
      </div>
      <!-- Nội dung email -->
      <div class="form-group-item" style="display: flex; flex-direction: column; gap: 8px;">
        <label class="form-label" style="text-align: left;">Nội dung email</label>
        <div id="' + @UID_Body + N'" style="width: 100%; height: 350px;"></div>
      </div>
    </div>

    <div class="form-footer-actions">
      <button class="btn-form-action btn-delete"
              onclick="onDeleteEditEmailTemplate_Huu()"
              style="display:none; margin-right:auto">
        <i class="fas fa-trash-alt me-1"></i>Xóa
      </button>
      <button class="btn-form-action btn-cancel" onclick="onCancelEditEmailTemplate_Huu()">
        <i class="fas fa-times me-1"></i>Hủy bỏ
      </button>
      <button class="btn-form-action btn-save" onclick="onSaveEditEmailTemplate_Huu()">
        <i class="fas fa-check me-1"></i>Lưu lại
      </button>
    </div>
  </div>
</div>

<script>
  (() => {
    // Placeholder variables to be replaced by the wrapper SP
    window.currentTemplateName = null;
    window.currentSubject = null;
    window.currentBody = null;
    window.currentEmailAccountId = null;
    window.currentIsActive = null;

    // ============================================================
    // 1. INJECT UI CONTROLS
    // ============================================================
    ' + ISNULL(CAST((SELECT loadUI FROM tblCommonControlType_Signed WHERE UID = @UID_TemplateName) AS NVARCHAR(MAX)), '') + N'
    ' + ISNULL(CAST((SELECT loadUI FROM tblCommonControlType_Signed WHERE UID = @UID_Subject) AS NVARCHAR(MAX)), '') + N'
    ' + ISNULL(CAST((SELECT loadUI FROM tblCommonControlType_Signed WHERE UID = @UID_EmailAccountId) AS NVARCHAR(MAX)), '') + N'
    ' + ISNULL(CAST((SELECT loadUI FROM tblCommonControlType_Signed WHERE UID = @UID_IsActive) AS NVARCHAR(MAX)), '') + N'
    ' + ISNULL(CAST((SELECT loadUI FROM tblCommonControlType_Signed WHERE UID = @UID_Body) AS NVARCHAR(MAX)), '') + N'

    // ============================================================
    // 2. NẠP DỮ LIỆU
    // ============================================================
    function ReloadData() {
        const hasData = window.currentTemplateName != null && window.currentTemplateName.trim() !== "";

        _autoSaveTemplateName' + @UID_TemplateName + N' = false;
        _autoSaveSubject' + @UID_Subject + N' = false;
        _autoSaveEmailAccountId' + @UID_EmailAccountId + N' = false;
        _autoSaveIsActive' + @UID_IsActive + N' = false;

        // Load TextBoxes & Controls
        try {
            InstanceTemplateName' + @UID_TemplateName + N'.clearValidationError();
        } catch(e) {}
        InstanceTemplateName' + @UID_TemplateName + N'._suppressValueChangeAction();
        InstanceTemplateName' + @UID_TemplateName + N'.option("value", window.currentTemplateName || "");
        InstanceTemplateName' + @UID_TemplateName + N'.option("disabled", hasData);
        InstanceTemplateName' + @UID_TemplateName + N'._resumeValueChangeAction();

        try {
            InstanceSubject' + @UID_Subject + N'.clearValidationError();
        } catch(e) {}
        InstanceSubject' + @UID_Subject + N'._suppressValueChangeAction();
        InstanceSubject' + @UID_Subject + N'.option("value", window.currentSubject || "");
        InstanceSubject' + @UID_Subject + N'._resumeValueChangeAction();

        try {
            InstanceEmailAccountId' + @UID_EmailAccountId + N'.clearValidationError();
        } catch(e) {}
        InstanceEmailAccountId' + @UID_EmailAccountId + N'._suppressValueChangeAction();
        InstanceEmailAccountId' + @UID_EmailAccountId + N'.option("value", window.currentEmailAccountId);
        InstanceEmailAccountId' + @UID_EmailAccountId + N'._resumeValueChangeAction();

        try {
            InstanceIsActive' + @UID_IsActive + N'.clearValidationError();
        } catch(e) {}
        InstanceIsActive' + @UID_IsActive + N'._suppressValueChangeAction();
        InstanceIsActive' + @UID_IsActive + N'.option("value", hasData ? window.currentIsActive : true);
        InstanceIsActive' + @UID_IsActive + N'._resumeValueChangeAction();

        // Load RichTextEditorPremium
        if (typeof rteObj_Body' + @UID_Body + N' !== "undefined" && rteObj_Body' + @UID_Body + N') {
            let rawHtml = window.currentBody || "";
            let safeHtml = rawHtml.replace(/<img([^>]*?)src=[\"\\\'''']([^\"\\\''''\+]+)[\"\\\'''']([^>]*?)>/gi, function(match, p1, srcVal, p2) {
                if (srcVal.indexOf("http") === 0 || srcVal.indexOf("data:") === 0 || srcVal.indexOf("blob:") === 0) return match;
                return `<img ${p1} src=\"data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=\" data-original-url=\"${srcVal}\" ${p2}>`;
            });
            rteObj_Body' + @UID_Body + N'.setHtml(safeHtml);
            if (typeof InstanceBody' + @UID_Body + N' !== "undefined") {
                InstanceBody' + @UID_Body + N'.value = rteObj_Body' + @UID_Body + N'.getHtml();
            }
        }

        // Điều khiển nút Lưu / Xóa
        if (hasData) {
            $("#sp_REC_EditEmailTemplate_Huu_html .btn-save").hide();
            $("#sp_REC_EditEmailTemplate_Huu_html .btn-delete").show();
        } else {
            $("#sp_REC_EditEmailTemplate_Huu_html .btn-save").show();
            $("#sp_REC_EditEmailTemplate_Huu_html .btn-delete").hide();
        }
    }

    // ============================================================
    // 3. XỬ LÝ HÀNH ĐỘNG
    // ============================================================
    window.onCancelEditEmailTemplate_Huu = function() {
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

    window.onSaveEditEmailTemplate_Huu = async function() {
        try {
            let templateName = InstanceTemplateName' + @UID_TemplateName + N'.option("value") || "";
            let subject = InstanceSubject' + @UID_Subject + N'.option("value") || "";
            let emailAccountId = InstanceEmailAccountId' + @UID_EmailAccountId + N'.option("value") || null;
            let isActive = InstanceIsActive' + @UID_IsActive + N'.option("value") || false;
            let body = "";

            if (typeof rteObj_Body' + @UID_Body + N' !== "undefined" && rteObj_Body' + @UID_Body + N') {
                body = rteObj_Body' + @UID_Body + N'.getHtml() || "";
            }

            if (!templateName || templateName.trim() === "") {
                uiManager.showAlert({ type: "danger", message: "Vui lòng nhập tên Template!" });
                return;
            }

            const currentID = window.currentTemplateName || "";
            const dataJSON = JSON.stringify({
                OriginalTemplateName: currentID,
                TemplateName: templateName.trim(),
                Subject: subject.trim(),
                EmailAccountId: emailAccountId,
                IsActive: isActive,
                Body: body
            });

            AjaxHPAParadise({
                data: {
                    name: "sp_REC_TemplateEmailEdit_Huu",
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
                            window.updateSharedGridRow("GridEditEmailTemplate_Huu", newRow);
                        onCancelEditEmailTemplate_Huu();
                    } else {
                        uiManager.showAlert({ type: "danger", message: statusRow.Message || "Gặp lỗi khi lưu dữ liệu!" });
                    }
                },
                error: function() {
                    uiManager.showAlert({ type: "danger", message: "Không kết nối được máy chủ!" });
                }
            });
        } catch(ex) {
            uiManager.showAlert({ type: "danger", message: "Lưu thất bại: " + ex });
        }
    };

    window.onDeleteEditEmailTemplate_Huu = function() {
        const currentID = window.currentTemplateName || "";
        if (!currentID) return;

        showConfirmPopup({
            title:   "Xóa Template Email?",
            message: "Bạn có chắc chắn muốn xóa template này không?",
            YesText: "Xóa",
            NoText:  "Hủy",
            onYes: () => {
                try {
                    const dataJSON = JSON.stringify({ OriginalTemplateName: currentID });
                    AjaxHPAParadise({
                        data: {
                            name: "sp_REC_TemplateEmailEdit_Huu",
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
                                    window.removeSharedGridRow("GridEditEmailTemplate_Huu", { key: currentID });
                                onCancelEditEmailTemplate_Huu();
                            } else {
                                uiManager.showAlert({ type: "danger", message: statusRow.Message || "Xóa thất bại!" });
                            }
                        },
                        error: function() {
                            uiManager.showAlert({ type: "danger", message: "Không kết nối được máy chủ!" });
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

-- 5.6. Save Action SP: sp_REC_TemplateEmailEdit_Huu
PRINT N'  - Tạo sp_REC_TemplateEmailEdit_Huu...';
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_REC_TemplateEmailEdit_Huu]
    @LoginID    INT          = NULL,
    @JsonData   NVARCHAR(MAX)= NULL,
    @Type       INT          = 1,   -- 1: Insert/Update, 2: Delete
    @LanguageID VARCHAR(2)   = 'VN'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TemplateName NVARCHAR(800);
    DECLARE @OriginalTemplateName NVARCHAR(800);
    DECLARE @Subject NVARCHAR(1000);
    DECLARE @EmailAccountId INT;
    DECLARE @IsActive BIT;
    DECLARE @Body NVARCHAR(MAX);

    -- Parse JSON
    SET @TemplateName         = JSON_VALUE(@JsonData, '$.TemplateName');
    SET @OriginalTemplateName = JSON_VALUE(@JsonData, '$.OriginalTemplateName');
    SET @Subject              = JSON_VALUE(@JsonData, '$.Subject');
    SET @EmailAccountId       = TRY_CAST(JSON_VALUE(@JsonData, '$.EmailAccountId') AS INT);
    SET @IsActive             = TRY_CAST(JSON_VALUE(@JsonData, '$.IsActive') AS BIT);
    SET @Body                 = JSON_VALUE(@JsonData, '$.Body');

    -- ---- DELETE ----
    IF @Type = 2
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM tblEmailTemplate WHERE TemplateName = @OriginalTemplateName)
        BEGIN
            SELECT 'ERROR' AS Status, N'Không tìm thấy mẫu email cần xóa.' AS Message;
            RETURN;
        END

        DELETE FROM tblEmailTemplate WHERE TemplateName = @OriginalTemplateName;
        SELECT 'SUCCESS' AS Status, N'Xóa mẫu email thành công!' AS Message;
        RETURN;
    END

    -- ---- INSERT / UPDATE ----
    -- Nếu không có OriginalTemplateName => Thêm mới
    IF @OriginalTemplateName IS NULL OR LTRIM(RTRIM(@OriginalTemplateName)) = ''
    BEGIN
        IF EXISTS (SELECT 1 FROM tblEmailTemplate WHERE TemplateName = @TemplateName)
        BEGIN
            SELECT 'ERROR' AS Status, N'Tên Template đã tồn tại.' AS Message;
            RETURN;
        END

        INSERT INTO tblEmailTemplate (TemplateName, Subject, EmailAccountId, IsActive, Body)
        VALUES (@TemplateName, @Subject, @EmailAccountId, @IsActive, @Body);

        SELECT 'SUCCESS' AS Status, N'Thêm mẫu email thành công!' AS Message;

        -- Trả về dòng dữ liệu để Grid update
        SELECT 
            @TemplateName AS ID,
            @TemplateName AS TemplateName,
            @Subject AS Subject,
            es.Email AS Email,
            @IsActive AS IsActive
        FROM tblEmailTemplate et
        LEFT JOIN tblEmailSetting es ON et.EmailAccountId = es.ID
        WHERE et.TemplateName = @TemplateName;
    END
    ELSE
    BEGIN
        -- Update
        IF NOT EXISTS (SELECT 1 FROM tblEmailTemplate WHERE TemplateName = @OriginalTemplateName)
        BEGIN
            SELECT 'ERROR' AS Status, N'Không tìm thấy mẫu email cần cập nhật.' AS Message;
            RETURN;
        END

        UPDATE tblEmailTemplate
        SET TemplateName = @TemplateName,
            Subject = @Subject,
            EmailAccountId = @EmailAccountId,
            IsActive = @IsActive,
            Body = @Body
        WHERE TemplateName = @OriginalTemplateName;

        SELECT 'SUCCESS' AS Status, N'Cập nhật mẫu email thành công!' AS Message;

        -- Trả về dòng dữ liệu để Grid update
        SELECT 
            @TemplateName AS ID,
            @TemplateName AS TemplateName,
            @Subject AS Subject,
            es.Email AS Email,
            @IsActive AS IsActive
        FROM tblEmailTemplate et
        LEFT JOIN tblEmailSetting es ON et.EmailAccountId = es.ID
        WHERE et.TemplateName = @TemplateName;
    END
END
GO

/* =============================================================================
   6. COMPILE & REBUILD CACHE
   ============================================================================= */
PRINT N'6. Compile controls, Rebuild HTML cache và Reset Menu Cache...';
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- Compile control scripts từ metadata
    EXEC dbo.sptblCommonControlType_Signed_DUC 'sp_REC_EditTemplateEmailType_html';
    EXEC dbo.sptblCommonControlType_Signed_DUC 'sp_REC_EditEmailTemplate_Huu_html';

    -- Xóa cache cũ và rebuild cache mới
    DELETE FROM dbo.tblHtmlScriptCache 
    WHERE TableName IN (
        N'sp_REC_EditTemplateEmailType_html', 
        N'sp_REC_EditTemplateEmailType', 
        N'sp_REC_EditEmailTemplate_Huu_html', 
        N'sp_REC_EditEmailTemplate_Huu'
    );

    EXEC dbo.sp_GenerateHTMLScript 'sp_REC_EditTemplateEmailType_html';
    EXEC dbo.sp_GenerateHTMLScript 'sp_REC_EditEmailTemplate_Huu_html';
    
    -- Cache các wrapper SP
    EXEC dbo.sp_GenerateHTMLScript 'sp_REC_EditTemplateEmailType';
    EXEC dbo.sp_GenerateHTMLScript 'sp_REC_EditEmailTemplate_Huu';

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
PRINT N' HOÀN TẤT RECREATION MENU MnuREC033 VÀ PHÂN HỆ SOẠN THẢO';
PRINT N'================================================================';
GO
