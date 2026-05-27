-- File: SQL script/update_gridtest_detail_isactive_20260527.sql
-- Muc dich: Them control "Kich hoat" (IsActive) cho sp_REC_GridTest_Detail_html
--          va cap nhat cac procedure detail de load/insert IsActive.
-- Luu y: User tu review va chay.

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1) Them control IsActive neu chua co
    IF NOT EXISTS (
        SELECT 1
        FROM tblCommonControlType_Signed
        WHERE TableName = 'sp_REC_GridTest_Detail_html'
          AND ColumnName = 'IsActive'
    )
    BEGIN
        INSERT INTO tblCommonControlType_Signed
            (TableName, ColumnIDName, TableEditor, ColumnName, Type, DisplayName,
             IsRequired, AutoSave, ReadOnly, TabIndex)
        SELECT
            'sp_REC_GridTest_Detail_html', 'TemplateName', 'tblEmailTemplate', 'IsActive',
            'hpaControlCheckBox', N'Kích hoạt', 0, 0, 0, 5;
    END

    -- 2) Cap nhat procedure load detail
    EXEC('ALTER PROCEDURE dbo.sp_REC_EmailTemplateDetail_Load
        @TemplateName NVARCHAR(400)
    AS
    BEGIN
        SET NOCOUNT ON;
        SELECT TemplateName, EmailAccountId, Subject, Body, IsActive
        FROM tblEmailTemplate
        WHERE TemplateName = @TemplateName
    END');

    -- 3) Cap nhat procedure insert detail
    EXEC('ALTER PROCEDURE dbo.sp_REC_EmailTemplateDetail_Insert
        @TemplateName NVARCHAR(400),
        @EmailAccountId INT,
        @Subject NVARCHAR(500) = '''',
        @Body NVARCHAR(MAX) = '''',
        @IsActive BIT = 1
    AS
    BEGIN
        SET NOCOUNT ON;
        
        IF EXISTS (SELECT 1 FROM tblEmailTemplate WHERE TemplateName = @TemplateName)
        BEGIN
            SELECT ''ERROR'' AS Status, N''Mã Template này đã tồn tại trong hệ thống!'' AS Message;
            RETURN;
        END

        INSERT INTO tblEmailTemplate (TemplateName, EmailAccountId, Subject, Body, IsActive)
        VALUES (@TemplateName, @EmailAccountId, @Subject, @Body, ISNULL(@IsActive, 1));

        SELECT ''SUCCESS'' AS Status, N''Thêm mới Template thành công!'' AS Message;
    END');

    -- 4) Cap nhat procedure giao dien (sp_REC_GridTest_Detail_html)
    EXEC('ALTER PROCEDURE dbo.sp_REC_GridTest_Detail_html (@LoginID INT=3, @LanguageID VARCHAR(5)=''VN'', @isWeb INT=1)
    AS BEGIN 
        SET NOCOUNT ON;

        DECLARE @TableName NVARCHAR(255) = ''sp_REC_GridTest_Detail_html'';

        -- Lay ma control da bien dich
        DECLARE @cTemplateName_Html NVARCHAR(MAX), @cTemplateName_UI NVARCHAR(MAX);
        DECLARE @cEmail_Html NVARCHAR(MAX), @cEmail_UI NVARCHAR(MAX);
        DECLARE @cSubject_Html NVARCHAR(MAX), @cSubject_UI NVARCHAR(MAX);
        DECLARE @cBody_Html NVARCHAR(MAX), @cBody_UI NVARCHAR(MAX);
        DECLARE @cIsActive_Html NVARCHAR(MAX), @cIsActive_UI NVARCHAR(MAX);

        DECLARE @uidTemplateName NVARCHAR(36);
        DECLARE @uidEmailAccountId NVARCHAR(36);
        DECLARE @uidSubject NVARCHAR(36);
        DECLARE @uidBody NVARCHAR(36);
        DECLARE @uidIsActive NVARCHAR(36);

        SELECT @uidTemplateName = CAST(UID AS NVARCHAR(36))
        FROM tblCommonControlType_Signed
        WHERE TableName = @TableName AND ColumnName = ''TemplateName'';

        SELECT @uidEmailAccountId = CAST(UID AS NVARCHAR(36))
        FROM tblCommonControlType_Signed
        WHERE TableName = @TableName AND ColumnName = ''EmailAccountId'';

        SELECT @uidSubject = CAST(UID AS NVARCHAR(36))
        FROM tblCommonControlType_Signed
        WHERE TableName = @TableName AND ColumnName = ''Subject'';

        SELECT @uidBody = CAST(UID AS NVARCHAR(36))
        FROM tblCommonControlType_Signed
        WHERE TableName = @TableName AND ColumnName = ''Body'';

        SELECT @uidIsActive = CAST(UID AS NVARCHAR(36))
        FROM tblCommonControlType_Signed
        WHERE TableName = @TableName AND ColumnName = ''IsActive'';

        SELECT @cTemplateName_Html = html, @cTemplateName_UI = loadUI
        FROM tblCommonControlType_Signed
        WHERE UID = @uidTemplateName;

        SELECT @cEmail_Html = html, @cEmail_UI = loadUI
        FROM tblCommonControlType_Signed
        WHERE UID = @uidEmailAccountId;

        SELECT @cSubject_Html = html, @cSubject_UI = loadUI
        FROM tblCommonControlType_Signed
        WHERE UID = @uidSubject;

        SELECT @cBody_Html = html, @cBody_UI = loadUI
        FROM tblCommonControlType_Signed
        WHERE UID = @uidBody;

        SELECT @cIsActive_Html = html, @cIsActive_UI = loadUI
        FROM tblCommonControlType_Signed
        WHERE UID = @uidIsActive;

        -- Bien chuoi text cho JS
        DECLARE @lblSave NVARCHAR(200) = N''Lưu lại'';
        IF @LanguageID = ''EN'' SET @lblSave = N''Save'';

        -- Ghep giao dien
        DECLARE @html NVARCHAR(MAX) = N''
<div class="paradise-form-container" style="padding: 15px;">
    <!-- Thanh Toolbar -->
    <div class="row mb-3">
        <div class="col-md-12 text-right">
            <button id="btnSaveEmailTemplate" class="btn btn-primary paradise-btn" style="display:none;">
                <i class="fa fa-save"></i> '' + @lblSave + N''
            </button>
            <button id="btnDeleteEmailTemplate" class="btn btn-danger paradise-btn" style="display:none; margin-left: 8px;">
                <i class="fa fa-trash"></i> Xoá
            </button>
        </div>
    </div>

    <!-- Khung nhap lieu -->
    <div class="row">
        <div class="col-md-6 mb-3">
            <label class="paradise-label">Mã Template</label>
            '' + ISNULL(@cTemplateName_Html, '''') + N''
        </div>
        <div class="col-md-6 mb-3">
            <label class="paradise-label">Tài khoản gửi</label>
            '' + ISNULL(@cEmail_Html, '''') + N''
        </div>
    </div>
    <div class="row">
        <div class="col-md-12 mb-3">
            <label class="paradise-label">Tiêu đề Email</label>
            '' + ISNULL(@cSubject_Html, '''') + N''
        </div>
    </div>
    <div class="row">
        <div class="col-md-12 mb-3">
            <label class="paradise-label">Nội dung</label>
            '' + ISNULL(@cBody_Html, '''') + N''
        </div>
    </div>
    <div class="row">
        <div class="col-md-6 mb-3">
            <label class="paradise-label">Kích hoạt</label>
            '' + ISNULL(@cIsActive_Html, '''') + N''
        </div>
    </div>
</div>

<script>
(async () => {
    const uidTemplateName = "'' + @uidTemplateName + N''";
    const uidEmailAccountId = "'' + @uidEmailAccountId + N''";
    const uidSubject = "'' + @uidSubject + N''";
    const uidBody = "'' + @uidBody + N''";
    const uidIsActive = "'' + @uidIsActive + N''";

    const getInstance = (columnName, uid) => window["Instance" + columnName + uid];
    const btnSaveEmailTemplate = document.getElementById("btnSaveEmailTemplate");
    const btnDeleteEmailTemplate = document.getElementById("btnDeleteEmailTemplate");

    if (btnSaveEmailTemplate) {
        btnSaveEmailTemplate.addEventListener("click", saveNewEmailTemplate);
    }

    if (btnDeleteEmailTemplate) {
        btnDeleteEmailTemplate.addEventListener("click", deleteEmailTemplate);
    }

    // 1. Nhan tham so truyen vao tu Grid
    let prm = window.sp_REC_GridTest_Detail_param || {};
    let isEdit = !!prm.TemplateName;

    // 2.5 Polyfill helpers cho control config-driven
    if (typeof window.LoginID === "undefined") { window.LoginID = '' + CAST(@LoginID AS NVARCHAR(20)) + N''; }
    if (typeof window.LanguageID === "undefined") { window.LanguageID = "'' + @LanguageID + N''"; }
    if (typeof window.loadDataSourceCommon === "undefined") {
        window.loadDataSourceCommon = function(columnName, dataSourceSP, cb) {
            AjaxHPAParadise({
                data: { name: dataSourceSP, param: ["LoginID", window.LoginID, "LanguageID", window.LanguageID] },
                success: function(res) {
                    var json = typeof res === "string" ? JSON.parse(res) : res;
                    var data = (json && json.data && json.data[0]) || [];
                    window["DataSource_" + columnName] = data;
                    if (json && json.dataSchema && json.dataSchema[0]) {
                        window["DataSourceIDField_" + columnName] = json.dataSchema[0][0] && json.dataSchema[0][0].name;
                        window["DataSourceNameField_" + columnName] = json.dataSchema[0][1] && json.dataSchema[0][1].name;
                    }
                    if (typeof cb === "function") cb(data, json);
                }
            });
        };
    }
    if (typeof window.hpaUtils === "undefined") {
        window.hpaUtils = { loadAvatar: function(){}, highlightText: function(t, s){ return t; } };
    }
    if (typeof window.RemoveToneMarks_Js === "undefined") {
        window.RemoveToneMarks_Js = function(s) {
            return String(s || "").normalize("NFD").replace(/[̀-ͯ]/g, "")
                .replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase();
        };
    }
    if (typeof window.uiManager === "undefined") {
        window.uiManager = { showAlert: function(opt){ console.warn(opt); } };
    }

    // 3. Khoi tao UI (cac control widget)
    '' + ISNULL(@cTemplateName_UI, '''') + N''
    '' + ISNULL(@cEmail_UI, '''') + N''
    '' + ISNULL(@cSubject_UI, '''') + N''
    '' + ISNULL(@cBody_UI, '''') + N''
    '' + ISNULL(@cIsActive_UI, '''') + N''

    // 4. Cau hinh AutoSave/ReadOnly sau khi loadUI
    if (isEdit) {
        window.currentRecordID_TemplateName = prm.TemplateName;
        _autoSaveTemplateName'' + @uidTemplateName + N'' = true;
        _readOnlyTemplateName'' + @uidTemplateName + N'' = true;

        _autoSaveEmailAccountId'' + @uidEmailAccountId + N'' = true;
        _autoSaveSubject'' + @uidSubject + N'' = true;
        _autoSaveBody'' + @uidBody + N'' = true;
        _autoSaveIsActive'' + @uidIsActive + N'' = true;

        const instanceTemplateName = getInstance("TemplateName", uidTemplateName);
        if (instanceTemplateName && instanceTemplateName.option) {
            instanceTemplateName.option("readOnly", true);
        }

        $("#btnDeleteEmailTemplate").show();
    } else {
        _autoSaveTemplateName'' + @uidTemplateName + N'' = false;
        _autoSaveEmailAccountId'' + @uidEmailAccountId + N'' = false;
        _autoSaveSubject'' + @uidSubject + N'' = false;
        _autoSaveBody'' + @uidBody + N'' = false;
        _autoSaveIsActive'' + @uidIsActive + N'' = false;

        $("#btnSaveEmailTemplate").show();
    }

    // 5. Load du lieu neu o che do Sua
    if (isEdit) {
        AjaxHPAParadise({
            data: {
                name: "sp_REC_EmailTemplateDetail_Load",
                param: ["TemplateName", prm.TemplateName]
            },
            success: function(res) {
                const json = typeof res === "string" ? JSON.parse(res) : res;
                const data = (json && json.data && json.data[0] && json.data[0][0])
                    || (Array.isArray(json) ? json[0] : null);
                if (data) {
        
                const obj = {
                    TemplateName: data.TemplateName,
                    EmailAccountId: data.EmailAccountId,
                    Subject: data.Subject,
                    Body: data.Body,
                    IsActive: data.IsActive
                };           

                '' + (SELECT loadData FROM tblCommonControlType_Signed WHERE UID = @uidTemplateName) + N''
                '' + (SELECT loadData FROM tblCommonControlType_Signed WHERE UID = @uidEmailAccountId) + N''
                '' + (SELECT loadData FROM tblCommonControlType_Signed WHERE UID = @uidSubject) + N''
                '' + (SELECT loadData FROM tblCommonControlType_Signed WHERE UID = @uidBody) + N''
                '' + (SELECT loadData FROM tblCommonControlType_Signed WHERE UID = @uidIsActive) + N''

                // Instances (controls) — values are assigned inside injected loadData blocks above
                const instanceTemplateName = getInstance("TemplateName", uidTemplateName);
                const instanceEmailAccountId = getInstance("EmailAccountId", uidEmailAccountId);
                const instanceSubject = getInstance("Subject", uidSubject);
                const instanceBody = getInstance("Body", uidBody);
                const instanceIsActive = getInstance("IsActive", uidIsActive);
                } else {
                    console.warn("sp_REC_EmailTemplateDetail_Load: empty data", json);
                }
            }
        });
    }

    // 5. Ham luu thu cong cho trang thai Them Moi
    function saveNewEmailTemplate() {
        const instanceTemplateName = getInstance("TemplateName", uidTemplateName);
        const instanceEmailAccountId = getInstance("EmailAccountId", uidEmailAccountId);
        const instanceSubject = getInstance("Subject", uidSubject);
        const instanceBody = getInstance("Body", uidBody);
        const instanceIsActive = getInstance("IsActive", uidIsActive);

        let payload = {
            TemplateName: instanceTemplateName.getValue(),
            EmailAccountId: instanceEmailAccountId.getValue(),
            Subject: instanceSubject.getValue(),
            Body: instanceBody.getValue(),
            IsActive: instanceIsActive.getValue()
        };

        if(!payload.TemplateName || !payload.EmailAccountId) {
            uiManager.showAlert({ type: "warning", message: "Vui lòng nhập đủ Mã Template và Tài khoản gửi!" });
            return;
        }

        AjaxHPAParadise({
            data: {
                name: "sp_REC_EmailTemplateDetail_Insert",
                param: [
                    "TemplateName", payload.TemplateName,
                    "EmailAccountId", payload.EmailAccountId,
                    "Subject", payload.Subject,
                    "Body", payload.Body,
                    "IsActive", payload.IsActive
                ]
            },
            success: function(res) {
                let resData = typeof res === "string" ? JSON.parse(res)[0] : res[0];
                if(resData.Status === "SUCCESS") {
                    uiManager.showAlert({ type: "success", message: resData.Message });
                    // Sau khi luu xong, an nut luu, chuyen sang che do Sua
                    $("#btnSaveEmailTemplate").hide();
                    $("#btnDeleteEmailTemplate").show();
                    
                    window.currentRecordID_TemplateName = payload.TemplateName;
                    _autoSaveTemplateName'' + @uidTemplateName + N'' = true;
                    _readOnlyTemplateName'' + @uidTemplateName + N'' = true;
                    instanceTemplateName.option("readOnly", true);

                    _autoSaveEmailAccountId'' + @uidEmailAccountId + N'' = true;
                    _autoSaveSubject'' + @uidSubject + N'' = true;
                    _autoSaveBody'' + @uidBody + N'' = true;
                    _autoSaveIsActive'' + @uidIsActive + N'' = true;
                } else {
                    uiManager.showAlert({ type: "error", message: resData.Message });
                }
            }
        });
    }

    // 6. Ham xoa template (chi dung o che do Sua)
    function deleteEmailTemplate() {
        let templateName = prm.TemplateName || window.currentRecordID_TemplateName;
        if (!templateName) return;

        showConfirmPopup({
            title: "Xóa Template?",
            message: "Bạn có chắc chắn muốn xóa Template này?",
            YesText: "Xóa",
            NoText: "Hủy",
            onYes: () => {
                AjaxHPAParadise({
                    data: {
                        name: "sp_REC_EmailTemplateDetail_Delete",
                        param: ["TemplateName", templateName]
                    },
                    success: function(res) {
                        let resData = typeof res === "string" ? JSON.parse(res)[0] : res[0];
                        if(resData.Status === "SUCCESS") {
                            uiManager.showAlert({ type: "success", message: resData.Message });

                            // Quay lai danh sach sau khi xoa
                            if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
                                OpenFormParamMobile("sp_REC_GridTest", {});
                            } else if (typeof openFormParam === "function") {
                                openFormParam("sp_REC_GridTest", {});
                            }
                        } else {
                            uiManager.showAlert({ type: "error", message: resData.Message });
                        }
                    }
                });
            },
            onNo: () => {
                // no-op
            }
        });
    }
})();
</script>'';

        SELECT @html AS html;
    END');

    -- 5) Build lai control + cache HTML
    EXEC sptblCommonControlType_Signed_DUC 'sp_REC_GridTest_Detail_html';
    EXEC sp_GenerateHTMLScript 'sp_REC_GridTest_Detail_html';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
