-- ============================================================================
-- File   : SQL script/update_menu_HelloVietinsoft_addconfigcontrols_20260521.sql
-- Date   : 2026-05-21
-- Author : Antigravity
-- Mục đích: Bổ sung sample các config-driven control (tblCommonControlType_Signed)
--           vào menu Hello Vietinsoft (sp_HelloWorldVietinsoft_html) làm tài liệu
--           tham khảo cho người mới tìm hiểu hệ thống ParadiseHR.
--
--   Giữ NGUYÊN section "Mẫu form control" tĩnh hiện tại; THÊM section mới
--   "Mẫu config-driven control" với 9 control:
--
--     1. hpaControlTextSearch       (DataSource: sp_getInfoEmployeeAccount_New)
--     2. hpaControlTextBox          (no datasource)
--     3. hpaControlFile             (DataSource: sp_GetFile)
--     4. hpaControlDateTime         (no datasource)
--     5. hpaControlCheckBox         (no datasource)
--     6. hpaControlSelectEmployee   (DataSource: EmployeeListAll_DataSetting_Custom)
--     7. hpaControlSelectBox        (DataSource: sp_loadDataDepartment)
--     8. hpaControlText             (no datasource)
--     9. hpaControlTextArea         (no datasource)
--
--   Tất cả AutoSave=0 (demo), tận dụng procedure datasource có sẵn để hạn chế
--   tạo proc mới gây rác hệ thống.
--
--   Pipeline triển khai:
--     1) MERGE 9 metadata rows vào tblCommonControlType_Signed (idempotent qua UID)
--     2) EXEC sptblCommonControlType_Signed_DUC @TableName -> populate html/loadUI/loadData
--     3) CREATE OR ALTER renderer + embed (SELECT loadUI/loadData ... WHERE UID=...)
--     4) sp_GenerateHTMLScript -> build cache VN + EN
--     5) sp_Men_Menu_AfterSave_Simple -> refresh menu (KHÔNG mở quyền cho mọi user)
-- ============================================================================

SET XACT_ABORT ON;
SET NOCOUNT ON;
GO

PRINT N'[1/5] MERGE metadata rows vao tblCommonControlType_Signed...';
GO

;WITH src AS (
    SELECT * FROM (VALUES
        -- (UID, Type, ColumnName, ColumnIDName, DisplayName, DataSourceSP, ReadOnly, ShowLabel, GroupIndex, SortOrder)
        ('PCAFEC0DE0001A1B2C3D4E5F600000001', 'hpaControlTextSearch',     N'DemoTextSearch',     NULL,        N'Tim kiem nhan vien (TextSearch)',           'sp_getInfoEmployeeAccount_New',         0, 1, 1, 10),
        ('PCAFEC0DE0001A1B2C3D4E5F600000002', 'hpaControlTextBox',        N'DemoTextBox',        N'DemoID',   N'Nhap text ngan (TextBox)',                  NULL,                                    0, 1, 1, 20),
        ('PCAFEC0DE0001A1B2C3D4E5F600000003', 'hpaControlFile',           N'DemoFile',           N'DemoID',   N'Tai file dinh kem (File)',                  'sp_GetFile',                            0, 1, 1, 30),
        ('PCAFEC0DE0001A1B2C3D4E5F600000004', 'hpaControlDateTime',       N'DemoDateTime',       N'DemoID',   N'Chon ngay gio (DateTime)',                  NULL,                                    0, 1, 1, 40),
        ('PCAFEC0DE0001A1B2C3D4E5F600000005', 'hpaControlCheckBox',       N'DemoCheckBox',       N'DemoID',   N'Bat tat tuy chon (CheckBox)',               NULL,                                    0, 1, 1, 50),
        ('PCAFEC0DE0001A1B2C3D4E5F600000006', 'hpaControlSelectEmployee', N'DemoSelectEmployee', N'DemoID',   N'Chon nhan vien (SelectEmployee)',           'EmployeeListAll_DataSetting_Custom',    0, 1, 1, 60),
        ('PCAFEC0DE0001A1B2C3D4E5F600000007', 'hpaControlSelectBox',      N'DemoSelectBox',      N'DemoID',   N'Chon phong ban (SelectBox)',                'sp_loadDataDepartment',                 0, 1, 1, 70),
        ('PCAFEC0DE0001A1B2C3D4E5F600000008', 'hpaControlText',           N'DemoText',           N'DemoID',   N'Hien thi text inline (Text - read-only)',   NULL,                                    1, 1, 1, 80),
        ('PCAFEC0DE0001A1B2C3D4E5F600000009', 'hpaControlTextArea',       N'DemoTextArea',       N'DemoID',   N'Nhap text nhieu dong (TextArea)',           NULL,                                    0, 1, 1, 90)
    ) v(UID, [Type], ColumnName, ColumnIDName, DisplayName, DataSourceSP, ReadOnly, ShowLabel, GroupIndex, SortOrder)
)
MERGE dbo.tblCommonControlType_Signed AS tgt
USING src
   ON tgt.UID = src.UID
WHEN MATCHED THEN
    UPDATE SET
        tgt.TableName    = 'sp_HelloWorldVietinsoft_html',
        tgt.[Type]       = src.[Type],
        tgt.ColumnName   = src.ColumnName,
        tgt.ColumnIDName = src.ColumnIDName,
        tgt.DisplayName  = src.DisplayName,
        tgt.DataSourceSP = src.DataSourceSP,
        tgt.ReadOnly     = src.ReadOnly,
        tgt.AutoSave     = 0,
        tgt.ShowLabel    = src.ShowLabel,
        tgt.GroupIndex   = src.GroupIndex,
        tgt.SortOrder    = src.SortOrder,
        tgt.IsRequired   = 0
        -- KHONG reset html/loadUI/loadData vi sptblCommonControlType_Signed_DUC se populate
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ID, TableName, [Type], ColumnName, ColumnIDName, DisplayName, DataSourceSP,
            ReadOnly, AutoSave, ShowLabel, GroupIndex, SortOrder, IsRequired,
            html, loadUI, loadData, UID)
    VALUES (LOWER(CONVERT(varchar(36), NEWID())), 'sp_HelloWorldVietinsoft_html', src.[Type], src.ColumnName, src.ColumnIDName, src.DisplayName, src.DataSourceSP,
            src.ReadOnly, 0, src.ShowLabel, src.GroupIndex, src.SortOrder, 0,
            N'', N'', N'', src.UID);

PRINT N'   -> Da MERGE ' + CAST(@@ROWCOUNT AS NVARCHAR(20)) + N' rows.';
GO

PRINT N'[2/5] EXEC sptblCommonControlType_Signed_DUC...';
GO

EXEC dbo.sptblCommonControlType_Signed_DUC @TableName = 'sp_HelloWorldVietinsoft_html';
PRINT N'   -> Da populate html/loadUI/loadData cho cac UID demo.';
GO

PRINT N'[3/5] CREATE OR ALTER renderer sp_HelloWorldVietinsoft_html...';
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_HelloWorldVietinsoft_html]
(
    @LoginID    INT          = 3,
    @LanguageID VARCHAR(5)   = 'VN',
    @isWeb      INT          = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StyleHtml NVARCHAR(MAX) = N'';
    IF OBJECT_ID('dbo.sp_MainStyleCSSParadise', 'P') IS NOT NULL
    BEGIN
        EXEC dbo.sp_MainStyleCSSParadise @StyleHtml = @StyleHtml OUTPUT;
    END

    DECLARE @title       NVARCHAR(200) = N'Hello Vietinsoft';
    DECLARE @subtitle    NVARCHAR(300);
    DECLARE @badge       NVARCHAR(100);
    DECLARE @colNo       NVARCHAR(50);
    DECLARE @colName     NVARCHAR(50);
    DECLARE @colPts      NVARCHAR(50);
    DECLARE @loading     NVARCHAR(100);
    DECLARE @empty       NVARCHAR(200);
    DECLARE @reloadText  NVARCHAR(80);
    DECLARE @footerText  NVARCHAR(200);
    DECLARE @metricTitle NVARCHAR(100);
    DECLARE @metricSub   NVARCHAR(100);
    DECLARE @guideTitle  NVARCHAR(160);
    DECLARE @guideText   NVARCHAR(400);
    DECLARE @btnTitle    NVARCHAR(120);
    DECLARE @formTitle   NVARCHAR(120);
    DECLARE @tokenTitle  NVARCHAR(120);
    DECLARE @statusTitle NVARCHAR(120);
    DECLARE @cfgTitle    NVARCHAR(160);
    DECLARE @cfgSubtitle NVARCHAR(400);
    DECLARE @lblTextSearch     NVARCHAR(160);
    DECLARE @lblTextBox        NVARCHAR(160);
    DECLARE @lblFile           NVARCHAR(160);
    DECLARE @lblDateTime       NVARCHAR(160);
    DECLARE @lblCheckBox       NVARCHAR(160);
    DECLARE @lblSelectEmployee NVARCHAR(160);
    DECLARE @lblSelectBox      NVARCHAR(160);
    DECLARE @lblText           NVARCHAR(160);
    DECLARE @lblTextArea       NVARCHAR(160);

    IF @LanguageID = 'EN'
    BEGIN
        SET @subtitle    = N'Reference menu demonstrating ParadiseStyle tokens, components, colors, spacing, status, form controls and runtime table.';
        SET @badge       = N'ParadiseStyle reference sample';
        SET @colNo       = N'#';
        SET @colName     = N'Employee';
        SET @colPts      = N'Total points';
        SET @loading     = N'Loading ranking data...';
        SET @empty       = N'No ranking data for this month.';
        SET @reloadText  = N'Reload data';
        SET @footerText  = N'Use this menu as a style reference for future HTML-rendered menus.';
        SET @metricTitle = N'Runtime data';
        SET @metricSub   = N'Top ranking this month';
        SET @guideTitle  = N'Design principles';
        SET @guideText   = N'No menu-level background, scoped CSS, ParadiseStyle tokens, standard buttons, card/panel layout, accessible controls and dark-mode-ready colors.';
        SET @btnTitle    = N'Button styles';
        SET @formTitle   = N'Form controls (static demo)';
        SET @tokenTitle  = N'Token samples';
        SET @statusTitle = N'Status samples';
        SET @cfgTitle    = N'Config-driven controls (live runtime)';
        SET @cfgSubtitle = N'Each control below is generated from tblCommonControlType_Signed metadata, populated by sptblCommonControlType_Signed_DUC, then embedded into this renderer via a (SELECT loadUI/loadData ... WHERE UID=...) subquery. Reusable DataSource SPs are preferred over creating new ones.';
        SET @lblTextSearch     = N'Search employee (TextSearch)';
        SET @lblTextBox        = N'Short text (TextBox)';
        SET @lblFile           = N'File upload (File)';
        SET @lblDateTime       = N'Date & time (DateTime)';
        SET @lblCheckBox       = N'Toggle (CheckBox)';
        SET @lblSelectEmployee = N'Pick employee (SelectEmployee)';
        SET @lblSelectBox      = N'Pick department (SelectBox)';
        SET @lblText           = N'Inline text (Text, read-only)';
        SET @lblTextArea       = N'Multi-line text (TextArea)';
    END
    ELSE
    BEGIN
        SET @subtitle    = N'Menu tham chiếu trình diễn token, component, màu sắc, spacing, trạng thái, form control và bảng dữ liệu runtime theo ParadiseStyle.';
        SET @badge       = N'Mẫu chuẩn ParadiseStyle';
        SET @colNo       = N'STT';
        SET @colName     = N'Nhân viên';
        SET @colPts      = N'Tổng điểm';
        SET @loading     = N'Đang tải dữ liệu xếp hạng...';
        SET @empty       = N'Không có dữ liệu xếp hạng cho tháng này.';
        SET @reloadText  = N'Tải lại dữ liệu';
        SET @footerText  = N'Dùng menu này làm mẫu tham chiếu khi thiết kế các menu HTML-rendered sau này.';
        SET @metricTitle = N'Dữ liệu runtime';
        SET @metricSub   = N'Bảng xếp hạng tháng hiện tại';
        SET @guideTitle  = N'Nguyên tắc thiết kế';
        SET @guideText   = N'Không set background cho menu, CSS có scope, dùng token ParadiseStyle, button chuẩn, layout card/panel, control dễ truy cập và tương thích dark mode.';
        SET @btnTitle    = N'Mẫu nút thao tác';
        SET @formTitle   = N'Mẫu form control (HTML tĩnh)';
        SET @tokenTitle  = N'Mẫu token màu';
        SET @statusTitle = N'Mẫu trạng thái';
        SET @cfgTitle    = N'Mẫu config-driven control (runtime live)';
        SET @cfgSubtitle = N'Mỗi control bên dưới được sinh động từ metadata trong tblCommonControlType_Signed, populate bởi sptblCommonControlType_Signed_DUC, sau đó embed vào renderer qua subquery (SELECT loadUI/loadData ... WHERE UID=...). Ưu tiên dùng DataSource SP có sẵn thay vì tạo proc mới.';
        SET @lblTextSearch     = N'Tìm kiếm nhân viên (TextSearch)';
        SET @lblTextBox        = N'Nhập text ngắn (TextBox)';
        SET @lblFile           = N'Tải file đính kèm (File)';
        SET @lblDateTime       = N'Chọn ngày giờ (DateTime)';
        SET @lblCheckBox       = N'Bật/tắt tuỳ chọn (CheckBox)';
        SET @lblSelectEmployee = N'Chọn nhân viên (SelectEmployee)';
        SET @lblSelectBox      = N'Chọn phòng ban (SelectBox)';
        SET @lblText           = N'Hiển thị text inline (Text, read-only)';
        SET @lblTextArea       = N'Nhập text nhiều dòng (TextArea)';
    END

    DECLARE @emptyJs NVARCHAR(400) = REPLACE(REPLACE(@empty, N'\', N'\\'), N'"', N'\"');
    DECLARE @loadingJs NVARCHAR(400) = REPLACE(REPLACE(@loading, N'\', N'\\'), N'"', N'\"');
    DECLARE @html NVARCHAR(MAX);

    SET @html = ISNULL(@StyleHtml, N'') + N'
<div id="helloWorldVtsContainer" class="hwvts-page">
    <style>
        .hwvts-page {
            min-height: 100%;
            padding: var(--paradise-space-5);
            color: var(--paradise-text-body);
            font-family: var(--paradise-font-family-base);
        }
        .hwvts-shell {
            max-width: 1180px;
            margin: 0 auto;
            display: grid;
            gap: var(--paradise-space-5);
        }
        .hwvts-card,
        .hwvts-hero {
            background-color: var(--paradise-card-bg);
            border: var(--paradise-card-border);
            border-radius: var(--paradise-card-radius);
            box-shadow: var(--paradise-card-shadow);
            padding: var(--paradise-card-padding);
        }
        .hwvts-hero-content,
        .hwvts-card-stack {
            display: grid;
            gap: var(--paradise-space-3);
        }
        .hwvts-badge,
        .hwvts-status,
        .hwvts-token-chip {
            width: fit-content;
            display: inline-flex;
            align-items: center;
            gap: var(--paradise-space-2);
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-pill);
            padding: var(--paradise-space-1) var(--paradise-space-3);
            color: var(--paradise-text-muted);
            font-size: var(--paradise-font-body2);
            font-weight: var(--font-weight-semi-bold);
        }
        .hwvts-badge,
        .hwvts-token-primary { color: var(--paradise-color-primary); }
        .hwvts-token-success { color: var(--paradise-color-success); }
        .hwvts-token-danger  { color: var(--paradise-color-danger); }
        .hwvts-token-warning { color: var(--paradise-color-warning); }
        .hwvts-token-info    { color: var(--paradise-color-info); }
        .hwvts-title {
            margin: 0;
            color: var(--paradise-color-primary);
            font-size: clamp(1.75rem, 3vw, 2.5rem);
            line-height: 1.1;
            font-weight: var(--font-weight-bold);
            letter-spacing: -.03em;
        }
        .hwvts-section-title,
        .hwvts-card-title {
            margin: 0;
            color: var(--paradise-text-body);
            font-size: var(--paradise-font-heading-main);
            font-weight: var(--font-weight-bold);
        }
        .hwvts-subtitle,
        .hwvts-muted,
        .hwvts-card-subtitle {
            margin: 0;
            color: var(--paradise-text-muted);
            font-size: var(--paradise-font-body1);
            line-height: var(--line-height-lg);
        }
        .hwvts-section {
            display: grid;
            gap: var(--paradise-space-4);
        }
        .hwvts-grid-2 { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: var(--paradise-space-5); }
        .hwvts-grid-3 { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: var(--paradise-space-4); }
        .hwvts-actions,
        .hwvts-status-list,
        .hwvts-token-list {
            display: flex; flex-wrap: wrap;
            gap: var(--paradise-space-3); align-items: center;
        }
        .hwvts-token-card {
            display: grid; gap: var(--paradise-space-2);
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-md);
            padding: var(--paradise-space-4);
        }
        .hwvts-token-name { font-family: var(--paradise-font-family-mono); color: var(--paradise-text-muted); font-size: var(--paradise-font-body2); }
        .hwvts-token-value { margin: 0; font-weight: var(--font-weight-bold); }
        .hwvts-form-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: var(--paradise-space-4); }
        .hwvts-field { display: grid; gap: var(--paradise-space-2); }
        .hwvts-field label { color: var(--paradise-text-body); font-size: var(--paradise-font-body2); font-weight: var(--font-weight-semi-bold); }
        .hwvts-input,
        .hwvts-select,
        .hwvts-textarea {
            width: 100%;
            background-color: var(--paradise-bg-surface);
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-input-border-radius);
            padding: var(--paradise-space-3) var(--paradise-space-4);
            color: var(--paradise-text-body);
            font-family: var(--paradise-font-family-base);
            font-size: var(--paradise-font-body1);
            transition: var(--paradise-transition-fast);
        }
        .hwvts-input:focus,
        .hwvts-select:focus,
        .hwvts-textarea:focus {
            outline: none;
            border-color: var(--paradise-color-input-border-hover);
            box-shadow: 0 0 0 0.125rem var(--paradise-color-input-focus-ring);
        }
        .hwvts-textarea { min-height: 5rem; resize: vertical; }
        .hwvts-check-row {
            display: flex; gap: var(--paradise-space-3); align-items: center;
            color: var(--paradise-text-body); font-size: var(--paradise-font-body1);
            cursor: pointer;
        }
        input[type="radio"] { accent-color: var(--paradise-color-checkbox); }
        .hwvts-table-wrap { overflow: hidden; border: 1px solid var(--paradise-border-color); border-radius: var(--paradise-border-radius-md); }
        .hwvts-table { width: 100%; border-collapse: collapse; }
        .hwvts-table th { padding: var(--paradise-space-3) var(--paradise-space-4); color: var(--paradise-text-muted); font-size: var(--paradise-font-body2); font-weight: var(--font-weight-semi-bold); text-align: left; }
        .hwvts-table th.hwvts-no-col { width: 5rem; }
        .hwvts-table th.hwvts-points-col { width: 10rem; text-align: right; }
        .hwvts-table td { padding: var(--paradise-space-3) var(--paradise-space-4); border-top: 1px solid var(--paradise-border-color); color: var(--paradise-text-body); }
        .hwvts-rank, .hwvts-icon {
            display: inline-flex; align-items: center; justify-content: center;
            border: 1px solid var(--paradise-border-color);
            color: var(--paradise-color-primary);
            font-weight: var(--font-weight-bold);
        }
        .hwvts-rank { width: 2rem; height: 2rem; border-radius: var(--paradise-border-radius-pill); }
        .hwvts-icon { width: 3.25rem; height: 3.25rem; border-radius: var(--paradise-border-radius-lg); font-size: 1.5rem; }
        .hwvts-points { text-align: right; font-weight: var(--font-weight-bold); color: var(--paradise-color-primary); }
        .hwvts-empty { padding: var(--paradise-space-6); text-align: center; color: var(--paradise-text-muted); }
        .hwvts-demo-list { margin: 0; padding-left: var(--paradise-space-5); color: var(--paradise-text-muted); line-height: var(--line-height-lg); }
        .hwvts-footer { display: flex; justify-content: space-between; align-items: center; gap: var(--paradise-space-4); color: var(--paradise-text-muted); font-size: var(--paradise-font-body2); }

        /* === Config-driven controls section === */
        .hwvts-ctrl-grid {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: var(--paradise-space-4);
        }
        .hwvts-ctrl-card {
            display: grid;
            gap: var(--paradise-space-2);
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-md);
            padding: var(--paradise-space-4);
            background-color: var(--paradise-bg-surface);
        }
        .hwvts-ctrl-type {
            font-family: var(--paradise-font-family-mono);
            font-size: 11px;
            color: var(--paradise-color-primary);
            font-weight: var(--font-weight-semi-bold);
            letter-spacing: .02em;
        }
        .hwvts-ctrl-label {
            color: var(--paradise-text-body);
            font-size: var(--paradise-font-body2);
            font-weight: var(--font-weight-semi-bold);
        }
        .hwvts-ctrl-host {
            min-height: 2.5rem;
            background-color: var(--paradise-card-bg);
            border: 1px dashed var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-sm);
            padding: var(--paradise-space-2);
        }
        .hwvts-ctrl-source {
            color: var(--paradise-text-muted);
            font-size: 11px;
        }
        .hwvts-ctrl-source code {
            font-family: var(--paradise-font-family-mono);
            color: var(--paradise-text-body);
        }

        @media (max-width: 1024px) {
            .hwvts-grid-3 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
            .hwvts-ctrl-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        }
        @media (max-width: 768px) {
            .hwvts-page { padding: var(--paradise-space-4); }
            .hwvts-grid-2,
            .hwvts-grid-3,
            .hwvts-form-grid,
            .hwvts-ctrl-grid { grid-template-columns: 1fr; }
            .hwvts-footer { align-items: stretch; flex-direction: column; }
            .hwvts-actions .paradise-btn { width: 100%; }
        }
    </style>

    <div class="hwvts-shell">
        <section class="hwvts-hero" aria-labelledby="hwvtsTitle">
            <div class="hwvts-hero-content">
                <span class="hwvts-badge">✦ ' + @badge + N'</span>
                <h2 id="hwvtsTitle" class="hwvts-title">' + @title + N'</h2>
                <p class="hwvts-subtitle">' + @subtitle + N'</p>
                <ul class="hwvts-demo-list">
                    <li>Root CSS scoped bằng prefix <strong>hwvts-</strong>.</li>
                    <li>Không khai báo background cho menu/page wrapper.</li>
                    <li>Dùng token <strong>var(--paradise-*)</strong> và class button chuẩn.</li>
                </ul>
            </div>
        </section>

        <section class="hwvts-grid-2">
            <article class="hwvts-card hwvts-card-stack">
                <span class="hwvts-badge">01</span>
                <h2 class="hwvts-card-title">' + @guideTitle + N'</h2>
                <p class="hwvts-card-subtitle">' + @guideText + N'</p>
            </article>
            <article class="hwvts-card hwvts-card-stack">
                <div class="hwvts-icon" aria-hidden="true">Aa</div>
                <h2 class="hwvts-card-title">Typography</h2>
                <p class="hwvts-card-subtitle">Font base, heading, body text, muted text và line-height dùng từ ParadiseStyle.</p>
            </article>
        </section>

        <section class="hwvts-section">
            <div>
                <h2 class="hwvts-section-title">' + @tokenTitle + N'</h2>
                <p class="hwvts-muted">Mẫu màu dùng semantic token; chỉ hiển thị bằng text/border, không tạo nền riêng cho menu.</p>
            </div>
            <div class="hwvts-grid-3">
                <div class="hwvts-token-card"><span class="hwvts-token-chip hwvts-token-primary">Primary</span><code class="hwvts-token-name">--paradise-color-primary</code><p class="hwvts-token-value hwvts-token-primary">Brand action</p></div>
                <div class="hwvts-token-card"><span class="hwvts-token-chip hwvts-token-success">Success</span><code class="hwvts-token-name">--paradise-color-success</code><p class="hwvts-token-value hwvts-token-success">Approved</p></div>
                <div class="hwvts-token-card"><span class="hwvts-token-chip hwvts-token-danger">Danger</span><code class="hwvts-token-name">--paradise-color-danger</code><p class="hwvts-token-value hwvts-token-danger">Delete/Error</p></div>
                <div class="hwvts-token-card"><span class="hwvts-token-chip hwvts-token-warning">Warning</span><code class="hwvts-token-name">--paradise-color-warning</code><p class="hwvts-token-value hwvts-token-warning">Need attention</p></div>
                <div class="hwvts-token-card"><span class="hwvts-token-chip hwvts-token-info">Info</span><code class="hwvts-token-name">--paradise-color-info</code><p class="hwvts-token-value hwvts-token-info">Information</p></div>
                <div class="hwvts-token-card"><span class="hwvts-token-chip">Muted</span><code class="hwvts-token-name">--paradise-text-muted</code><p class="hwvts-token-value">Secondary text</p></div>
            </div>
        </section>

        <section class="hwvts-grid-2">
            <article class="hwvts-card hwvts-card-stack">
                <h2 class="hwvts-card-title">' + @btnTitle + N'</h2>
                <p class="hwvts-card-subtitle">Dùng class chuẩn <code>paradise-btn</code> và modifier theo hành động.</p>
                <div class="hwvts-actions">
                    <button id="hwVtsReloadBtn" type="button" class="paradise-btn paradise-btn--reload">' + @reloadText + N'</button>
                    <button type="button" class="paradise-btn paradise-btn--add">Add</button>
                    <button type="button" class="paradise-btn paradise-btn--save">Save</button>
                    <button type="button" class="paradise-btn paradise-btn--delete">Delete</button>
                    <button type="button" class="paradise-btn paradise-btn--reset">Reset</button>
                    <button type="button" class="paradise-btn paradise-btn--export">Export</button>
                </div>
            </article>

            <article class="hwvts-card hwvts-card-stack">
                <h2 class="hwvts-card-title">' + @statusTitle + N'</h2>
                <div class="hwvts-status-list">
                    <span class="hwvts-status hwvts-token-success">● Active</span>
                    <span class="hwvts-status hwvts-token-warning">● Pending</span>
                    <span class="hwvts-status hwvts-token-danger">● Error</span>
                    <span class="hwvts-status hwvts-token-info">● Info</span>
                </div>
                <p class="hwvts-card-subtitle">Badge/status dùng border + text token để tương thích theme.</p>
            </article>
        </section>

        <section class="hwvts-card hwvts-card-stack">
            <h2 class="hwvts-card-title">' + @formTitle + N'</h2>
            <div class="hwvts-form-grid">
                <div class="hwvts-field"><label for="hwvtsInput">Input</label><input id="hwvtsInput" class="hwvts-input" value="ParadiseStyle input" /></div>
                <div class="hwvts-field"><label for="hwvtsSelect">Select</label><select id="hwvtsSelect" class="hwvts-select"><option>VN</option><option>EN</option></select></div>
                <div class="hwvts-field"><label for="hwvtsTextarea">Textarea</label><textarea id="hwvtsTextarea" class="hwvts-textarea">Ghi chú mẫu cho form control.</textarea></div>
                <div class="hwvts-field"><label>Checkbox / Radio</label><label class="hwvts-check-row"><input type="checkbox" checked /> Áp dụng token ParadiseStyle</label><label class="hwvts-check-row"><input type="radio" name="hwvtsRadio" checked /> Lựa chọn mẫu</label></div>
            </div>
        </section>

        <!-- ============================================================ -->
        <!--    CONFIG-DRIVEN CONTROLS (live runtime, hpaControl*)        -->
        <!--   Mỗi <div id="P..."> là placeholder DUC sẽ render vào.       -->
        <!--   Script ở dưới gọi loadUI rồi loadData từ DB chuẩn ParadiseHR.-->
        <!-- ============================================================ -->
        <section class="hwvts-card hwvts-card-stack">
            <h2 class="hwvts-card-title">' + @cfgTitle + N'</h2>
            <p class="hwvts-card-subtitle">' + @cfgSubtitle + N'</p>

            <div class="hwvts-ctrl-grid">
                <article class="hwvts-ctrl-card">
                    <span class="hwvts-ctrl-type">hpaControlTextSearch</span>
                    <label class="hwvts-ctrl-label">' + @lblTextSearch + N'</label>
                    <div class="hwvts-ctrl-host"><div id="PCAFEC0DE0001A1B2C3D4E5F600000001"></div></div>
                    <small class="hwvts-ctrl-source">DataSource: <code>sp_getInfoEmployeeAccount_New</code></small>
                </article>

                <article class="hwvts-ctrl-card">
                    <span class="hwvts-ctrl-type">hpaControlTextBox</span>
                    <label class="hwvts-ctrl-label">' + @lblTextBox + N'</label>
                    <div class="hwvts-ctrl-host"><div id="PCAFEC0DE0001A1B2C3D4E5F600000002"></div></div>
                    <small class="hwvts-ctrl-source">Không cần datasource</small>
                </article>

                <article class="hwvts-ctrl-card">
                    <span class="hwvts-ctrl-type">hpaControlFile</span>
                    <label class="hwvts-ctrl-label">' + @lblFile + N'</label>
                    <div class="hwvts-ctrl-host"><div id="PCAFEC0DE0001A1B2C3D4E5F600000003"></div></div>
                    <small class="hwvts-ctrl-source">DataSource: <code>sp_GetFile</code></small>
                </article>

                <article class="hwvts-ctrl-card">
                    <span class="hwvts-ctrl-type">hpaControlDateTime</span>
                    <label class="hwvts-ctrl-label">' + @lblDateTime + N'</label>
                    <div class="hwvts-ctrl-host"><div id="PCAFEC0DE0001A1B2C3D4E5F600000004"></div></div>
                    <small class="hwvts-ctrl-source">Không cần datasource</small>
                </article>

                <article class="hwvts-ctrl-card">
                    <span class="hwvts-ctrl-type">hpaControlCheckBox</span>
                    <label class="hwvts-ctrl-label">' + @lblCheckBox + N'</label>
                    <div class="hwvts-ctrl-host"><div id="PCAFEC0DE0001A1B2C3D4E5F600000005"></div></div>
                    <small class="hwvts-ctrl-source">Không cần datasource</small>
                </article>

                <article class="hwvts-ctrl-card">
                    <span class="hwvts-ctrl-type">hpaControlSelectEmployee</span>
                    <label class="hwvts-ctrl-label">' + @lblSelectEmployee + N'</label>
                    <div class="hwvts-ctrl-host"><div id="PCAFEC0DE0001A1B2C3D4E5F600000006"></div></div>
                    <small class="hwvts-ctrl-source">DataSource: <code>EmployeeListAll_DataSetting_Custom</code></small>
                </article>

                <article class="hwvts-ctrl-card">
                    <span class="hwvts-ctrl-type">hpaControlSelectBox</span>
                    <label class="hwvts-ctrl-label">' + @lblSelectBox + N'</label>
                    <div class="hwvts-ctrl-host"><div id="PCAFEC0DE0001A1B2C3D4E5F600000007"></div></div>
                    <small class="hwvts-ctrl-source">DataSource: <code>sp_loadDataDepartment</code></small>
                </article>

                <article class="hwvts-ctrl-card">
                    <span class="hwvts-ctrl-type">hpaControlText</span>
                    <label class="hwvts-ctrl-label">' + @lblText + N'</label>
                    <div class="hwvts-ctrl-host"><div id="PCAFEC0DE0001A1B2C3D4E5F600000008"></div></div>
                    <small class="hwvts-ctrl-source">Không cần datasource (read-only)</small>
                </article>

                <article class="hwvts-ctrl-card">
                    <span class="hwvts-ctrl-type">hpaControlTextArea</span>
                    <label class="hwvts-ctrl-label">' + @lblTextArea + N'</label>
                    <div class="hwvts-ctrl-host"><div id="PCAFEC0DE0001A1B2C3D4E5F600000009"></div></div>
                    <small class="hwvts-ctrl-source">Không cần datasource</small>
                </article>
            </div>
        </section>

        <section class="hwvts-grid-2">
            <article class="hwvts-card">
                <div class="hwvts-card-stack">
                    <div>
                        <h2 class="hwvts-card-title">' + @metricTitle + N'</h2>
                        <p class="hwvts-card-subtitle">' + @metricSub + N'</p>
                    </div>
                    <div class="hwvts-table-wrap">
                        <table class="hwvts-table" aria-label="Hello Vietinsoft ranking">
                            <thead>
                                <tr>
                                    <th class="hwvts-no-col">' + @colNo + N'</th>
                                    <th>' + @colName + N'</th>
                                    <th class="hwvts-points-col">' + @colPts + N'</th>
                                </tr>
                            </thead>
                            <tbody id="hwVtsTbody">
                                <tr><td colspan="3" class="hwvts-empty">' + @loading + N'</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </article>

            <aside class="hwvts-card hwvts-card-stack">
                <div class="hwvts-icon" aria-hidden="true">🏆</div>
                <p class="hwvts-card-subtitle">' + @metricTitle + N'</p>
                <p id="hwVtsCount" class="hwvts-title">0</p>
                <p class="hwvts-card-subtitle">' + @footerText + N'</p>
            </aside>
        </section>

        <footer class="hwvts-footer">
            <span>' + @footerText + N'</span>
            <span>LoginID: <strong>' + CAST(@LoginID AS NVARCHAR(20)) + N'</strong></span>
        </footer>
    </div>
</div>

<script>
/* === Top ranking demo (giữ nguyên) === */
(function(){
    var EMPTY_MSG = "' + @emptyJs + N'";
    var LOADING_MSG = "' + @loadingJs + N'";

    function escapeHtml(value){
        if(value === null || value === undefined) return "";
        return String(value)
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/\u0027/g, "&#039;");
    }

    function setCount(value){
        var el = document.getElementById("hwVtsCount");
        if(el) el.textContent = value || 0;
    }

    function render(rows){
        var tb = document.getElementById("hwVtsTbody");
        if(!tb) return;
        rows = Array.isArray(rows) ? rows : [];
        setCount(rows.length);
        if(rows.length === 0){
            tb.innerHTML = "<tr><td colspan=\"3\" class=\"hwvts-empty\">" + EMPTY_MSG + "</td></tr>";
            return;
        }
        var html = "";
        for(var i = 0; i < rows.length; i++){
            var r = rows[i] || {};
            var name = escapeHtml(r.FullName || r.EmployeeName || r.EmployeeID || "");
            var points = r.TotalPoints != null ? r.TotalPoints : 0;
            html += "<tr><td><span class=\"hwvts-rank\">" + (i + 1) + "</span></td><td>" + name + "</td><td class=\"hwvts-points\">" + points + "</td></tr>";
        }
        tb.innerHTML = html;
    }

    function setLoading(){
        var tb = document.getElementById("hwVtsTbody");
        if(tb) tb.innerHTML = "<tr><td colspan=\"3\" class=\"hwvts-empty\">" + LOADING_MSG + "</td></tr>";
        setCount(0);
    }

    function normalizeRows(res){
        var json = typeof res === "string" ? JSON.parse(res) : res;
        if(json && json.data && Array.isArray(json.data)) return json.data[0] || [];
        if(json && Array.isArray(json.Data)) return json.Data;
        if(Array.isArray(json)) return json;
        return [];
    }

    function loadData(){
        setLoading();
        if(typeof AjaxHPAParadise !== "function"){ render([]); return; }
        AjaxHPAParadise({
            data: { name: "sp_HelloWorldVietinsoft_GetTopRank", param: ["FilterYear", null, "FilterMonth", null] },
            success: function(res){ try { render(normalizeRows(res)); } catch(e) { render([]); } },
            error: function(){ render([]); }
        });
    }

    var btn = document.getElementById("hwVtsReloadBtn");
    if(btn) btn.addEventListener("click", loadData);
    loadData();
})();
</script>

<script>
/* === Config-driven controls bootstrap ===
   Menu này KHÔNG phải DataSetting menu nên các global helper (loadDataSourceCommon,
   hpaUtils, uiManager, LoginID, LanguageID, RemoveToneMarks_Js) KHÔNG được framework
   tự load. Bootstrap dưới đây polyfill các helper tối thiểu để 9 control hoạt động
   trong barebones HTML-rendered menu. AutoSave=0 nên saveFunction/updateOrDeleteDataExample
   không bao giờ được gọi tới (không cần polyfill).
*/
(function(){
    /* ===== Polyfill các global cần cho hpaControl* trong barebones menu ===== */

    // 1. LoginID / LanguageID — DataSetting menu set sẵn; barebones thì không.
    if (typeof window.LoginID === "undefined")    window.LoginID    = ' + CAST(@LoginID AS NVARCHAR(20)) + N';
    if (typeof window.LanguageID === "undefined") window.LanguageID = "' + @LanguageID + N'";

    // 2. loadDataSourceCommon — helper chuẩn của framework, gọi AjaxHPAParadise với
    //    param ["LoginID", LoginID, "LanguageID", LanguageID] rồi cache vào
    //    window["DataSource_<columnName>"]. Polyfill bằng phiên bản tối giản.
    if (typeof window.loadDataSourceCommon !== "function") {
        window.loadDataSourceCommon = function(columnName, dataSourceSP, onSuccessCallback) {
            if (!columnName || !dataSourceSP || !String(dataSourceSP).trim()) {
                if (typeof onSuccessCallback === "function") onSuccessCallback([]);
                return;
            }
            if (typeof AjaxHPAParadise !== "function") {
                console.warn("[hwvts polyfill] AjaxHPAParadise undefined => skip", dataSourceSP);
                if (typeof onSuccessCallback === "function") onSuccessCallback([]);
                return;
            }
            AjaxHPAParadise({
                data: { name: dataSourceSP, param: ["LoginID", window.LoginID, "LanguageID", window.LanguageID] },
                success: function(res){
                    try {
                        var json = typeof res === "string" ? JSON.parse(res) : res;
                        var data = (json && json.data && json.data[0]) || [];
                        var idField   = (json && json.valueExpr)   || (json && json.dataSchema && json.dataSchema[0] && json.dataSchema[0][0] && json.dataSchema[0][0].name) || "ID";
                        var nameField = (json && json.displayExpr) || (json && json.dataSchema && json.dataSchema[0] && json.dataSchema[0][1] && json.dataSchema[0][1].name) || "Name";
                        window["DataSource_"          + columnName] = data;
                        window["DataSourceIDField_"   + columnName] = idField;
                        window["DataSourceNameField_" + columnName] = nameField;
                        if (typeof onSuccessCallback === "function") onSuccessCallback(data, json);
                    } catch(e){
                        console.error("[hwvts polyfill] loadDataSourceCommon parse error:", e);
                        if (typeof onSuccessCallback === "function") onSuccessCallback([]);
                    }
                },
                error: function(err){
                    console.error("[hwvts polyfill] loadDataSourceCommon error", columnName, err);
                    if (typeof onSuccessCallback === "function") onSuccessCallback([]);
                }
            });
        };
    }

    // 3. hpaUtils — SelectEmployee cần loadAvatar; SelectBox itemTemplate cần highlightText
    if (typeof window.hpaUtils === "undefined") {
        window.hpaUtils = {
            loadAvatar: function(){ /* noop trong demo, không load avatar */ },
            highlightText: function(text, search){
                if (text == null) return "";
                if (!search)      return String(text);
                try {
                    var esc = String(search).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
                    return String(text).replace(new RegExp("(" + esc + ")", "gi"), "<mark>$1</mark>");
                } catch(e){ return String(text); }
            }
        };
    }

    // 4. RemoveToneMarks_Js — SelectEmployee grid search dùng để bỏ dấu tiếng Việt
    if (typeof window.RemoveToneMarks_Js !== "function") {
        window.RemoveToneMarks_Js = function(s){
            if (s == null) return "";
            return String(s).normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase();
        };
    }

    // 5. uiManager.showAlert — dùng ở các nhánh error/validation
    if (typeof window.uiManager === "undefined") {
        window.uiManager = { showAlert: function(opt){ console.warn("[uiManager polyfill]", opt); } };
    }

    var TRY_MAX = 60, tries = 0;
    function waitReady(cb){
        if (typeof window.$ !== "undefined" && typeof window.DevExpress !== "undefined") {
            window.$(document).ready(cb);
            return;
        }
        if (++tries >= TRY_MAX) { console.warn("[hwvts cfg-ctrl] jQuery/DevExpress khong san sang sau " + tries + " lan."); return; }
        setTimeout(function(){ waitReady(cb); }, 100);
    }

    waitReady(function(){
        // obj giả cho loadData (tên cột khớp với ColumnName đã insert vào tblCommonControlType_Signed)
        var obj = {
            DemoTextSearch:     "",
            DemoTextBox:        "ParadiseStyle TextBox demo",
            DemoFile:           null,
            DemoDateTime:       new Date().toISOString(),
            DemoCheckBox:       1,
            DemoSelectEmployee: "",
            DemoSelectBox:      "",
            DemoText:           "ParadiseStyle inline Text demo (read-only)",
            DemoTextArea:       "Ghi chu mau nhieu dong cho config-driven control."
        };
        // currentRecordID_DemoID dùng khi AutoSave=1 — ở demo này AutoSave=0 nên branch không chạm tới
        var currentRecordID_DemoID = "demo-0";

        // === loadUI cho 9 control ===
        try {
            ' + ISNULL((SELECT loadUI FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000001'), N'/* TextSearch loadUI rong */') + N'
            ' + ISNULL((SELECT loadUI FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000002'), N'/* TextBox loadUI rong */') + N'
            ' + ISNULL((SELECT loadUI FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000003'), N'/* File loadUI rong */') + N'
            ' + ISNULL((SELECT loadUI FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000004'), N'/* DateTime loadUI rong */') + N'
            ' + ISNULL((SELECT loadUI FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000005'), N'/* CheckBox loadUI rong */') + N'
            ' + ISNULL((SELECT loadUI FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000006'), N'/* SelectEmployee loadUI rong */') + N'
            ' + ISNULL((SELECT loadUI FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000007'), N'/* SelectBox loadUI rong */') + N'
            ' + ISNULL((SELECT loadUI FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000008'), N'/* Text loadUI rong */') + N'
            ' + ISNULL((SELECT loadUI FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000009'), N'/* TextArea loadUI rong */') + N'
        } catch(e) { console.error("[hwvts cfg-ctrl] loadUI failed:", e); }

        // === loadData cho 9 control (set giá trị mẫu từ obj) ===
        try {
            ' + ISNULL((SELECT loadData FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000001'), N'/* TextSearch loadData rong */') + N'
            ' + ISNULL((SELECT loadData FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000002'), N'/* TextBox loadData rong */') + N'
            ' + ISNULL((SELECT loadData FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000003'), N'/* File loadData rong */') + N'
            ' + ISNULL((SELECT loadData FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000004'), N'/* DateTime loadData rong */') + N'
            ' + ISNULL((SELECT loadData FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000005'), N'/* CheckBox loadData rong */') + N'
            ' + ISNULL((SELECT loadData FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000006'), N'/* SelectEmployee loadData rong */') + N'
            ' + ISNULL((SELECT loadData FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000007'), N'/* SelectBox loadData rong */') + N'
            ' + ISNULL((SELECT loadData FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000008'), N'/* Text loadData rong */') + N'
            ' + ISNULL((SELECT loadData FROM dbo.tblCommonControlType_Signed WHERE UID='PCAFEC0DE0001A1B2C3D4E5F600000009'), N'/* TextArea loadData rong */') + N'
        } catch(e) { console.error("[hwvts cfg-ctrl] loadData failed:", e); }
    });
})();
</script>';

    MERGE dbo.tblHtmlScriptCache AS tgt
    USING (SELECT
              'sp_HelloWorldVietinsoft_html' AS TableName,
              @LanguageID                    AS LanguageID,
              '-1'                           AS ScreenType,
              @html                          AS html,
              N''                            AS HtmlParadise,
              N''                            AS paradiseJs,
              '3.3'                          AS Version,
              N'ParadiseStyle v3.3 - add 9 config-driven hpaControl* samples + reuse existing datasource SPs' AS VersionData
          ) AS src
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
END
GO

PRINT N'[4/5] sp_GenerateHTMLScript build cache (VN + EN)...';
GO
EXEC dbo.sp_GenerateHTMLScript N'sp_HelloWorldVietinsoft_html';
GO

PRINT N'[5/5] sp_Men_Menu_AfterSave_Simple refresh menu...';
GO
IF OBJECT_ID(N'dbo.sp_Men_Menu_AfterSave_Simple', 'P') IS NOT NULL
    EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_HelloWorldVietinsoft';
GO

-- Verify
PRINT N'--- Verify ---';
SELECT UID, [Type], ColumnName, DataSourceSP,
       LEN(ISNULL(html, N''))     AS htmlLen,
       LEN(ISNULL(loadUI, N''))   AS loadUILen,
       LEN(ISNULL(loadData, N'')) AS loadDataLen
FROM dbo.tblCommonControlType_Signed
WHERE TableName = 'sp_HelloWorldVietinsoft_html'
ORDER BY SortOrder, UID;

SELECT TableName, LanguageID, Version, VersionData, LEN(html) AS HtmlLen
FROM dbo.tblHtmlScriptCache
WHERE TableName = 'sp_HelloWorldVietinsoft_html'
ORDER BY LanguageID;
