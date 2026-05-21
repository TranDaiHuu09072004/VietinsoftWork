CREATE PROCEDURE [dbo].[sp_MainStyleCSSParadise] @StyleHtml nVarchar(max) output
AS
DECLARE @Html nVarchar(max) = N''
SET @Html = N'
:root {
    /* MÀU SẮC CƠ BẢN (LIGHT MODE) */
    --paradise-color-primary: rgba(0, 123, 255, 1);
    --paradise-color-secondary: rgba(108, 117, 125, 1);
    --paradise-color-success: rgba(40, 167, 69, 1);
    --paradise-color-danger: rgba(220, 53, 69, 1);
    --paradise-color-warning: rgba(255, 193, 7, 1);
    --paradise-color-info: rgba(23, 162, 184, 1);
    --paradise-color-dark: rgba(52, 58, 64, 1);
    --paradise-color-light: rgba(248, 249, 250, 1);

    /* MÀU NỀN & BỀ MẶT */
    --paradise-bg-body: #ffffff;
    --paradise-bg-surface: #f8f9fa;
    --paradise-text-body: #212529;
    --paradise-text-muted: #6c757d;

    /* MÀU TRANG TRÍ & LOGO */
    --paradise-color-decor-bg1: rgba(237, 255, 200, 1);
    --paradise-color-decor-bg2: rgba(213, 254, 129, 1);
    --paradise-color-decor-main: rgba(159, 225, 45, 1);
    --paradise-color-logo-main: rgba(115, 196, 29, 1);
    --paradise-color-text-bg: rgba(29, 147, 54, 1);
    --paradise-color-header1: rgba(0, 103, 59, 1);
    --paradise-color-header2: rgba(0, 76, 57, 1);
    --paradise-color-important: rgba(255, 0, 0, 1);

    /* MÀU NÚT BẤM CỤ THỂ */
    --paradise-color-btnreload: rgba(25, 135, 84, 1);
    --paradise-color-btnfwadd: rgba(25, 135, 84, 1);
    --paradise-color-btnexport: rgba(0, 100, 0, 1);
    --paradise-color-btnfwsave: rgba(37, 32, 94, 1);
    --paradise-color-btnfwdelete: rgba(233, 66, 53, 1);
    --paradise-color-btnfwreset: rgba(255, 192, 0, 1);

    /* INPUT & CHON LỰA (CHECKBOX, BORDER) */
    --paradise-color-input-border: rgba(229, 231, 234, 1);
    --paradise-color-input-border-hover: rgba(158, 162, 174, 1);
    --paradise-color-input-disabled: rgba(229, 231, 234, 1);
    --paradise-color-input-focus-ring: rgba(13, 110, 253, 0.25);
    
    --paradise-color-checkbox: rgba(21, 115, 71, 1);
    --paradise-color-checkbox-border: rgba(21, 115, 71, 1);
    --paradise-color-checkbox-border-hover: rgba(21, 115, 71, 0.5);
    --paradise-color-checkbox-border-disabled: rgba(229, 231, 234, 1);

    /* CHUYÊN BIỆT CHO GRID & DATACELL */
    --paradise-bg-edit-cell: cornsilk;
    --paradise-bg-focus-cell: #d0e5fb;
    --paradise-bg-weekend-cell: inherit;
    --paradise-border-focus-cell: #d0e5fb;

    /* TYPOGRAPHY */
    --paradise-font-heading-main: 1.125rem;
    --paradise-font-heading-sub: 1rem;
    --paradise-font-label: 1rem;
    --paradise-font-body1: 0.875rem;
    --paradise-font-body2: 0.875rem;

    --paradise-font-button-xl: 1.125rem;
    --paradise-font-button-lg: 1rem;
    --paradise-font-button-md: 0.875rem;
    --paradise-font-button-sm: 0.75rem;
    --paradise-font-button-xs: 0.625rem;

    --font-weight-thin: 100;
    --font-weight-light: 300;
    --font-weight-regular: 400;
    --font-weight-medium: 500;
    --font-weight-semi-bold: 600;
    --font-weight-bold: 700;

    /* SPACING & BORDER RADIUS */
    --line-height-xs: 0.75rem;
    --line-height-sm: 1rem;
    --line-height-md: 1.25rem;
    --line-height-lg: 1.5rem;

    --paradise-input-border-radius: 0.75rem;
    --paradise-button-border-radius: 1.25rem;
    --paradise-transition-base: all 0.25s ease-in-out;
}

/* ĐỊNH NGHĨA DARK MODE */
[data-bs-theme="dark"] {
    --paradise-bg-body: #121212;
    --paradise-bg-surface: #1e1e1e;
    --paradise-text-body: #e0e0e0;
    --paradise-text-muted: #a0a0a0;

    --paradise-color-input-border: #495057;
    --paradise-color-input-border-hover: #6c757d;
    --paradise-color-input-disabled: #343a40;
    --paradise-color-input-focus-ring: rgba(13, 110, 253, 0.4);

    --paradise-bg-edit-cell: #014D4E;
    --paradise-bg-focus-cell: #0c3b5e;
    --paradise-border-focus-cell: #0c3b5e;
    
    --paradise-color-header1: rgba(0, 150, 80, 1);
    --paradise-color-header2: rgba(0, 110, 70, 1);
}
</style>

<!-- CSS LÕI & COMPONENT -->
<style>
/* HIỆU ỨNG CHUNG MƯỢT MÀ */
* {
    transition: background-color 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease;
}

body {
    background-color: var(--paradise-bg-body);
    color: var(--paradise-text-body);
}

/* --- GRID & DATA SETTING --- */
.data-setting-edit-cell {
    background-color: var(--paradise-bg-edit-cell);
}
.paint-row .data-setting-edit-cell {
    background-color: transparent;
}
.sunday-row .data-setting-edit-cell,
.saturday-row .data-setting-edit-cell {
    background-color: var(--paradise-bg-weekend-cell);
}
.column-max-width:focus {
    background-color: var(--paradise-bg-focus-cell);
}
.dx-header-row > td > .dx-datagrid-text-content {
    white-space: normal;
}
.dx-datagrid .dx-data-row.sunday-row .dx-datagrid-sticky-column,
.dx-datagrid .dx-data-row.sunday-row .dx-datagrid-sticky-column-left,
.dx-datagrid .dx-data-row.sunday-row .dx-datagrid-sticky-column-right,
.dx-datagrid .dx-data-row.saturday-row .dx-datagrid-sticky-column,
.dx-datagrid .dx-data-row.saturday-row .dx-datagrid-sticky-column-left,
.dx-datagrid .dx-data-row.saturday-row .dx-datagrid-sticky-column-right,
.dx-datagrid .dx-data-row.paint-row .dx-datagrid-sticky-column,
.dx-datagrid .dx-data-row.paint-row .dx-datagrid-sticky-column-left,
.dx-datagrid .dx-data-row.paint-row .dx-datagrid-sticky-column-right {
    background-color: inherit;
}
.dx-datagrid .data-setting-edit-cell.dx-checkbox>.dx-checkbox-container,
.dx-datagrid .data-setting-edit-cell>.dx-checkbox>.dx-checkbox-container,
.dx-datagrid .dx-checkbox>.dx-checkbox-container {
    display: flex;
    justify-content: center;
}

/* --- BUTTONS --- */
.data-setting-button, .paradise-btn, .btn {
    --paradise-btn-padding-y: 0.75rem;
    --paradise-btn-padding-x: 1rem;
    --paradise-btn-border-radius: var(--paradise-button-border-radius);
    --paradise-btn-font-size: var(--paradise-font-button-md);
    
    padding: var(--paradise-btn-padding-y) var(--paradise-btn-padding-x);
    border-radius: var(--paradise-btn-border-radius);
    min-width: min-content;
    font-size: var(--paradise-btn-font-size);
    font-weight: var(--font-weight-semi-bold);
    transition: var(--paradise-transition-base);
}

.data-setting-button:hover, .paradise-btn:hover, .btn:hover {
    filter: brightness(0.9);
}
[data-bs-theme="dark"] .data-setting-button:hover, 
[data-bs-theme="dark"] .paradise-btn:hover, 
[data-bs-theme="dark"] .btn:hover {
    filter: brightness(1.1);
}

/* Kích thước Button */
.paradise-btn-lg, .btn-lg {
    --paradise-btn-padding-y: 0.875rem;
    --paradise-btn-padding-x: 1.25rem;
    --paradise-btn-font-size: var(--paradise-font-button-lg);
}
.paradise-btn-xl, .btn-xl {
    --paradise-btn-padding-y: 1rem;
    --paradise-btn-padding-x: 1.5rem;
    --paradise-btn-border-radius: 2rem;
    --paradise-btn-font-size: var(--paradise-font-button-xl);
}
.paradise-btn-sm, .btn-sm {
    --paradise-btn-padding-y: 0.5rem;
    --paradise-btn-padding-x: 0.75rem;
    --paradise-btn-font-size: var(--paradise-font-button-sm);
}

/* Các Nút Chuyên Biệt */
.btnreload, .paradise-btn-reload,
.btnfwadd, .paradise-btn-add,
.btnfwsave, .paradise-btn-save,
.btnfwdelete, .paradise-btn-delete,
.btnfwreset, .paradise-btn-reset,
.btnexport, .paradise-btn-export, .data-setting-button-export,
.btnimport, .paradise-btn-import, .data-setting-button-import,
.btnspaction, .data-setting-button-spaction {
    color: white;
    height: 2.5rem;
    min-width: 10rem;
}

.btnreload, .paradise-btn-reload { background-color: var(--paradise-color-btnreload); border-color: var(--paradise-color-btnreload); }
.btnfwadd, .paradise-btn-add { background-color: var(--paradise-color-btnfwadd); border-color: var(--paradise-color-btnfwadd); }
.btnfwsave, .paradise-btn-save { background-color: var(--paradise-color-btnfwsave); border-color: var(--paradise-color-btnfwsave); }
.btnfwdelete, .paradise-btn-delete { background-color: var(--paradise-color-btnfwdelete); border-color: var(--paradise-color-btnfwdelete); }
.btnfwreset, .paradise-btn-reset { background-color: var(--paradise-color-btnfwreset); border-color: var(--paradise-color-btnfwreset); }
.btnexport, .paradise-btn-export, .data-setting-button-export,
.btnimport, .paradise-btn-import, .data-setting-button-import { background-color: var(--paradise-color-btnexport); border-color: var(--paradise-color-btnexport); }

/* --- INPUTS & CONTROLS --- */
.paradise-input, .dx-texteditor-input-container, .dx-editor-outlined, input.dx-texteditor-input, input, textarea {
    border-radius: var(--paradise-input-border-radius);
}

.dx-texteditor.dx-editor-outlined, .dx-texteditor.dx-editor-outlined .dx-texteditor-input {
    height: 2.5rem;
    border-color: var(--paradise-color-input-border);
}

.dx-texteditor.dx-editor-outlined.dx-state-active,
.dx-texteditor.dx-editor-outlined.dx-state-focused,
.dx-texteditor.dx-editor-outlined.dx-state-hover {
    border-color: var(--paradise-color-input-border-hover);
}

.dx-texteditor.dx-editor-outlined.dx-state-focused {
    box-shadow: 0 0 0 .125rem var(--paradise-color-input-focus-ring);
}

/* Tắt bóng đổ dư thừa trong grid */
.dx-datagrid .dx-texteditor.dx-editor-outlined.dx-state-focused {
    box-shadow: none;
}

/* Readonly / Disabled States */
.dx-texteditor.dx-editor-outlined.dx-state-disabled,
.dx-texteditor.dx-editor-outlined.dx-state-readonly {
    background-color: var(--paradise-color-input-disabled);
    color: var(--paradise-text-body);
    opacity: 1;
    box-shadow: unset;
}

/* Checkbox & Radio Modernization */
.dx-checkbox-icon, .dx-radiobutton-icon {
    border-radius: 0.25rem;
    border: 1px solid var(--paradise-color-checkbox-border);
    transition: var(--paradise-transition-base);
}

.dx-checkbox-checked.dx-state-active .dx-checkbox-icon,
.dx-checkbox-checked.dx-state-focused .dx-checkbox-icon,
.dx-checkbox-checked.dx-state-hover .dx-checkbox-icon,
.dx-checkbox-checked .dx-checkbox-icon {
    border-color: var(--paradise-color-checkbox);
    background-color: var(--paradise-color-checkbox);
}

.form-check-input:checked {
    background-color: var(--paradise-color-checkbox);
    border-color: var(--paradise-color-checkbox);
}
input[type="checkbox"] {
    accent-color: var(--paradise-color-checkbox);
}

/* TYPOGRAPHY UTILITIES */
.paradise-text-primary { color: var(--paradise-color-primary); }
.paradise-text-secondary { color: var(--paradise-color-secondary); }
.paradise-text-success { color: var(--paradise-color-success); }
.paradise-text-danger { color: var(--paradise-color-danger); }
.paradise-text-warning { color: var(--paradise-color-warning); }
.paradise-text-info { color: var(--paradise-color-info); }
.paradise-text-dark { color: var(--paradise-text-body); }

/* LỊCH SỬ ĐƠN & TIMELINE */
.timeline-step .circle.blue { background-color: #007bff; }
.timeline-step .circle.gray { background-color: #939496; }
.timeline-step .circle.yellow { background-color: #ffc107; }
.timeline-step .circle.green { background-color: #198754; }
.timeline-step .circle.red { background-color: #dc3545; }

.request-CardList .card {
    transition: 0.3s all;
    border: none;
    border-bottom: 1px solid rgba(0, 0, 0, 0.1);
    border-radius: 0;
}
.request-CardList .card:hover {
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
    transform: translateY(-2px);
}
</style>

<!-- MEDIA QUERIES (GOM NHÓM MOBILE-FIRST VÀ MAX-WIDTH: 480PX) -->
<style>
@media (max-width: 480px) {
    .btnreload, .paradise-btn-reload,
    .btnfwadd, .paradise-btn-add,
    .btnfwsave, .paradise-btn-save,
    .btnfwdelete, .paradise-btn-delete,
    .btnfwreset, .paradise-btn-reset,
    .data-setting-button-export, .data-setting-button-spaction, .data-setting-button-import {
        width: 100%;
        min-width: auto;
    }

    .data-setting-grid {
        max-width: 100%;
        max-height: 60dvh;
    }

    .column-max-width {
        max-width: 100%;
    }

    /* Khắc phục lố giao diện thẻ input floating label */
    .data-setting-item .dx-texteditor-label .dx-label-before,
    .data-setting-item .dx-texteditor-label .dx-label-after {
        border-bottom-color: var(--paradise-color-input-border);
    }
    
    .dx-texteditor.dx-editor-outlined {
        box-shadow: unset;
        -webkit-box-shadow: unset;
        background-color: var(--paradise-bg-body);
        border: 1px solid var(--paradise-color-input-border);
    }

    .dx-datagrid-rowsview .dx-row-focused.dx-data-row .dx-command-edit .dx-link,
    .dx-datagrid-rowsview .dx-row-focused.dx-data-row>td:not(.dx-focused),
    .dx-datagrid-rowsview .dx-row-focused.dx-data-row>tr>td:not(.dx-focused) {
        background-color: var(--paradise-bg-focus-cell);
        color: var(--paradise-text-body);
    }
}
'

-- Thực thi khối minification và xử lý output
DECLARE @debug int = 1
IF NOT EXISTS (SELECT * FROM dbo.tblParameter WHERE Code='debug' AND Value='1')
   OR HOST_NAME() LIKE '%thanhlong%'
    SET @debug=0
SET @debug = 1

IF @debug != 1 BEGIN
    DECLARE @url nVarchar(max) = dbo.fn_GetAPPLICATION_ADDRESS_Local(), 
            @user nVarchar(max) = N'', 
            @password nVarchar(max) = N'', 
            @Status int, 
            @StatusText varchar(256), 
            @ResponseText nVarchar(max)
            
    SELECT TOP 1 @user=LoginName, @password=PassWord
      FROM dbo.tblSC_Login
     WHERE LoginName IN ('adminApi', 'admin', 'vts')
     ORDER BY CASE LoginName
              WHEN 'adminApi' THEN 1
              WHEN 'admin' THEN 2
              WHEN 'vts' THEN 3
              END
              
    SET @url += N'/api/hpa/paradiseparadise'
    SET @Html = STRING_ESCAPE(@Html, 'json')
    DECLARE @data nVarchar(max) = N'{"user":"'+@user+N'", "password":"'+@password+N'", "name":"MinifyFile", "param":["'+@Html+N'","\",\".css"] }'
    
    EXEC ss_RequestHttp @Url=@url, @NoSelect=1, @Status=@Status output, @StatusText=@StatusText output, @ResponseText=@ResponseText output, @Method='Post', @data=@data
    
    SET @Html = JSON_VALUE(@ResponseText, '$.data')
    IF @Html IS NULL
        SELECT @Html=[data]
          FROM OPENJSON(@ResponseText)
          WITH([data] nVarchar(max) '$.data')
END

SET @Html = N'<style>' + @Html + N'</style>'
SET @StyleHtml = @Html
GO
