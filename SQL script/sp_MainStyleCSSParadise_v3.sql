
ALTER   PROCEDURE [dbo].sp_MainStyleCSSParadise
    @StyleHtml nvarchar(max) output
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Html nvarchar(max) = N'';

    -- ====================================================================
    -- SECTION 1 — DESIGN TOKENS (DARK MODE — Paradise Modern Default)
    -- All values exposed as CSS custom properties for global consumption.
    -- Components SHOULD use var(--paradise-*) instead of hardcoding colors.
    -- Inspired by Paradise Modern Dark palette (xem css/styles.css).
    -- ====================================================================
    SET @Html = N'
:root {
    /* ===== FONT FAMILY — Inter cho UI, JetBrains Mono cho data/value ===== */
    --paradise-font-family-base: ''Inter'', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, system-ui, "Helvetica Neue", Arial, sans-serif;
    --paradise-font-family-mono: ''JetBrains Mono'', ''SF Mono'', Monaco, Consolas, "Liberation Mono", "Courier New", monospace;

    /* ===== SPACING SCALE ===== */
    --paradise-space-0: 0;
    --paradise-space-1: 0.25rem;   /* 4px */
    --paradise-space-2: 0.5rem;    /* 8px */
    --paradise-space-3: 0.75rem;   /* 12px */
    --paradise-space-4: 1rem;      /* 16px */
    --paradise-space-5: 1.5rem;    /* 24px */
    --paradise-space-6: 2rem;      /* 32px */
    --paradise-space-7: 3rem;      /* 48px */
    --paradise-space-8: 4rem;      /* 64px */

    /* ===== Z-INDEX SCALE ===== */
    --paradise-z-base: 1;
    --paradise-z-dropdown: 1000;
    --paradise-z-sticky: 1020;
    --paradise-z-fixed: 1030;
    --paradise-z-modal-backdrop: 1040;
    --paradise-z-modal: 1050;
    --paradise-z-popup: 1060;
    --paradise-z-tooltip: 1080;
    --paradise-z-toast: 1090;

    /* ===== SHADOW SCALE — dark theme: bóng đậm để card nổi trên bg-0 ===== */
    --paradise-shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.3);
    --paradise-shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.4), 0 2px 4px -2px rgba(0, 0, 0, 0.3);
    --paradise-shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.5), 0 4px 6px -4px rgba(0, 0, 0, 0.4);
    --paradise-shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.55), 0 8px 10px -6px rgba(0, 0, 0, 0.4);

    /* ===== TRANSITION — fast 0.15s đặc trưng Paradise Modern ===== */
    --paradise-transition-fast: all 0.15s ease;
    --paradise-transition-base: all 0.25s ease-in-out;
    --paradise-transition-slow: all 0.4s ease;

    /* ===== BORDER RADIUS — sharp corners (4px / 2px) cho card/badge;
            pill 1.25rem giữ cho action button (theo yêu cầu) ===== */
    --paradise-border-radius-sm: 2px;
    --paradise-border-radius-md: 4px;
    --paradise-border-radius-lg: 6px;
    --paradise-border-radius-xl: 1.25rem;
    --paradise-border-radius-pill: 999px;

    /* ===== PARADISE PALETTE — dark default (theo css/styles.css) ===== */
    --paradise-bg-0: #0b0e11;          /* Global background */
    --paradise-bg-1: #1e2329;          /* Surface / card */
    --paradise-bg-2: #2b3139;          /* Hover / border */
    --paradise-bg-3: #474d57;          /* Active / lighter border */
    --paradise-border-color: #2b3139;
    --paradise-border-strong: #474d57;

    --paradise-fg-0: #eaecef;          /* Primary text */
    --paradise-fg-1: #b7bdc6;          /* Secondary text */
    --paradise-fg-2: #848e9c;          /* Muted text */
    --paradise-fg-3: #707a8a;          /* Deep muted */

    /* ===== MÀU SẮC CƠ BẢN (dark default) ===== */
    --paradise-color-primary: #22ab3f;             /* Paradise Green accent (WCAG AA compliant: 4.95:1 contrast) */
    --paradise-color-secondary: rgba(140, 150, 160, 1);
    --paradise-color-success: #0ecb81;             /* pos */
    --paradise-color-danger: #f6465d;              /* neg */
    --paradise-color-warning: #f0b90b;             /* warn */
    --paradise-color-info: #3b82f6;
    --paradise-color-dark: var(--paradise-fg-0);
    --paradise-color-light: var(--paradise-bg-1);

    /* ===== SUBTLE BACKGROUND TOKENS — Used by: badges, alerts, chips, KPI ===== */
    --paradise-bg-primary-subtle: rgba(34, 171, 63, 0.16);
    --paradise-bg-secondary-subtle: rgba(140, 150, 160, 0.16);
    --paradise-bg-success-subtle: rgba(14, 203, 129, 0.15);
    --paradise-bg-danger-subtle: rgba(246, 70, 93, 0.15);
    --paradise-bg-warning-subtle: rgba(240, 185, 11, 0.15);
    --paradise-bg-info-subtle: rgba(59, 130, 246, 0.15);
    --paradise-bg-dark-subtle: rgba(184, 192, 207, 0.12);
    --paradise-bg-light-subtle: rgba(60, 65, 70, 0.85);
    --paradise-bg-header1-subtle: rgba(34, 171, 63, 0.18);
    --paradise-bg-header2-subtle: rgba(14, 110, 70, 0.18);
    --paradise-bg-important-subtle: rgba(246, 70, 93, 0.15);

    /* ===== BODY & SURFACE — DARK ===== */
    --paradise-bg-body: var(--paradise-bg-0);
    --paradise-bg-surface: var(--paradise-bg-1);
    --paradise-text-body: var(--paradise-fg-0);
    --paradise-text-muted: var(--paradise-fg-2);

    /* ===== CARD TOKENS — sharp 4px corner, dark surface ===== */
    --paradise-card-bg: var(--paradise-bg-1);
    --paradise-card-border: 1px solid var(--paradise-border-color);
    --paradise-card-shadow: var(--paradise-shadow-sm);
    --paradise-card-radius: var(--paradise-border-radius-md);
    --paradise-card-padding: var(--paradise-space-4);

    /* ===== MODAL TOKENS — dark + blur backdrop ===== */
    --paradise-modal-bg: var(--paradise-bg-1);
    --paradise-modal-backdrop: rgba(0, 0, 0, 0.7);
    --paradise-modal-radius: 6px;
    --paradise-modal-shadow: 0 16px 48px rgba(0, 0, 0, 0.6);

    /* ===== DECORATION & LOGO — dark-tinted ===== */
    --paradise-color-decor-bg1: rgba(40, 50, 30, 1);
    --paradise-color-decor-bg2: rgba(60, 80, 40, 1);
    --paradise-color-decor-main: rgba(120, 180, 60, 1);
    --paradise-color-logo-main: #22ab3f;
    --paradise-color-text-bg: #22ab3f;
    --paradise-color-header1: #22ab3f;
    --paradise-color-header2: #14723f;
    --paradise-color-important: #f6465d;

    /* ===== BUTTON SEMANTIC COLORS — adjusted cho dark ===== */
    --paradise-color-btnreload: #0ecb81;
    --paradise-color-btnfwadd: #0ecb81;
    --paradise-color-btnexport: #22ab3f;
    --paradise-color-btnfwsave: #3b82f6;
    --paradise-color-btnfwdelete: #f6465d;
    --paradise-color-btnfwreset: #f0b90b;

    /* ===== INPUT & CHECKBOX — dark ===== */
    --paradise-color-input-border: var(--paradise-bg-2);
    --paradise-color-input-border-hover: var(--paradise-bg-3);
    --paradise-color-input-disabled: rgba(43, 49, 57, 0.6);
    --paradise-color-input-focus-ring: rgba(34, 171, 63, 0.35);

    --paradise-color-checkbox: #22ab3f;
    --paradise-color-checkbox-border: #22ab3f;
    --paradise-color-checkbox-border-hover: rgba(34, 171, 63, 0.55);
    --paradise-color-checkbox-border-disabled: var(--paradise-bg-2);

    /* ===== GRID & DATA CELL — dark surface ===== */
    --paradise-bg-edit-cell: rgba(240, 185, 11, 0.12);
    --paradise-bg-focus-cell: rgba(59, 130, 246, 0.18);
    --paradise-bg-weekend-cell: inherit;
    --paradise-border-focus-cell: rgba(59, 130, 246, 0.4);

    /* ===== TYPOGRAPHY — dense (13px base như styles.css) ===== */
    --paradise-font-heading-main: 1.125rem;
    --paradise-font-heading-sub: 1rem;
    --paradise-font-label: 0.8125rem;
    --paradise-font-body1: 0.8125rem;
    --paradise-font-body2: 0.75rem;

    --paradise-font-button-xl: 1rem;
    --paradise-font-button-lg: 0.875rem;
    --paradise-font-button-md: 0.8125rem;
    --paradise-font-button-sm: 0.75rem;
    --paradise-font-button-xs: 0.625rem;

    --font-weight-thin: 100;
    --font-weight-light: 300;
    --font-weight-regular: 400;
    --font-weight-medium: 500;
    --font-weight-semi-bold: 600;
    --font-weight-bold: 700;

    --line-height-xs: 0.75rem;
    --line-height-sm: 1rem;
    --line-height-md: 1.25rem;
    --line-height-lg: 1.5rem;

    /* ===== TOPBAR (Paradise Modern) ===== */
    --paradise-topbar-h: 52px;

    /* ===== LEGACY ALIASES (giữ tương thích — không xoá) ===== */
    --paradise-input-border-radius: var(--paradise-border-radius-md);
    --paradise-button-border-radius: var(--paradise-border-radius-xl);
}

/* ====================================================================
   SECTION 2 — LIGHT MODE OVERRIDE (TOÀN BỘ color tokens)
   Trigger: <html data-bs-theme="light"> hoặc <body data-bs-theme="light">
   Đảo lại palette cho light mode (vẫn giữ tone xanh Paradise).
   ==================================================================== */
[data-bs-theme="light"] {
    /* Body / surface */
    --paradise-bg-0: #f5f6f8;
    --paradise-bg-1: #ffffff;
    --paradise-bg-2: #edffc8;
    --paradise-bg-3: #d1d4dc;
    --paradise-border-color: #e5e7eb;
    --paradise-border-strong: #d1d4dc;

    --paradise-fg-0: #1e2329;
    --paradise-fg-1: #474d57;
    --paradise-fg-2: #707a8a;
    --paradise-fg-3: #848e9c;

    --paradise-bg-body: #ffffff;
    --paradise-bg-surface: color(display-p3 0.97 1 0.95 / 0.5);
    --paradise-text-body: var(--paradise-fg-0);
    --paradise-text-muted: var(--paradise-fg-2);

    /* Card / Modal — light */
    --paradise-card-bg: #ffffff;
    --paradise-card-border: 1px solid #e5e7eb;
    --paradise-card-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
    --paradise-modal-bg: #ffffff;
    --paradise-modal-backdrop: rgba(0, 0, 0, 0.5);
    --paradise-modal-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);

    /* Brand colors — Paradise Green đậm hơn cho contrast trên bg sáng */
    --paradise-color-primary: #00673b;
    --paradise-color-secondary: rgba(108, 117, 125, 1);
    --paradise-color-success: #198754;
    --paradise-color-danger: #dc3545;
    --paradise-color-warning: #ffc107;
    --paradise-color-info: #17a2b8;
    --paradise-color-dark: rgba(52, 58, 64, 1);
    --paradise-color-light: rgba(248, 249, 250, 1);

    /* Subtle backgrounds — light variants */
    --paradise-bg-primary-subtle: rgba(0, 103, 59, 0.10);
    --paradise-bg-secondary-subtle: rgba(108, 117, 125, 0.12);
    --paradise-bg-success-subtle: rgba(25, 135, 84, 0.12);
    --paradise-bg-danger-subtle: rgba(220, 53, 69, 0.10);
    --paradise-bg-warning-subtle: rgba(255, 193, 7, 0.18);
    --paradise-bg-info-subtle: rgba(23, 162, 184, 0.12);
    --paradise-bg-dark-subtle: rgba(52, 58, 64, 0.10);
    --paradise-bg-light-subtle: rgba(248, 249, 250, 0.90);
    --paradise-bg-header1-subtle: rgba(0, 103, 59, 0.10);
    --paradise-bg-header2-subtle: rgba(0, 76, 57, 0.10);
    --paradise-bg-important-subtle: rgba(255, 0, 0, 0.08);

    /* Button colors — light */
    --paradise-color-btnreload: rgba(25, 135, 84, 1);
    --paradise-color-btnfwadd: rgba(25, 135, 84, 1);
    --paradise-color-btnexport: rgba(0, 100, 0, 1);
    --paradise-color-btnfwsave: rgba(37, 32, 94, 1);
    --paradise-color-btnfwdelete: rgba(233, 66, 53, 1);
    --paradise-color-btnfwreset: rgba(255, 192, 0, 1);

    /* Header & decoration — light */
    --paradise-color-header1: rgba(0, 103, 59, 1);
    --paradise-color-header2: rgba(0, 76, 57, 1);
    --paradise-color-text-bg: rgba(29, 147, 54, 1);
    --paradise-color-logo-main: rgba(115, 196, 29, 1);
    --paradise-color-important: rgba(255, 0, 0, 1);

    --paradise-color-decor-bg1: rgba(237, 255, 200, 1);
    --paradise-color-decor-bg2: rgba(213, 254, 129, 1);
    --paradise-color-decor-main: rgba(159, 225, 45, 1);

    /* Input */
    --paradise-color-input-border: rgba(229, 231, 234, 1);
    --paradise-color-input-border-hover: rgba(158, 162, 174, 1);
    --paradise-color-input-disabled: rgba(229, 231, 234, 1);
    --paradise-color-input-focus-ring: rgba(13, 110, 253, 0.25);

    /* Checkbox */
    --paradise-color-checkbox: rgba(21, 115, 71, 1);
    --paradise-color-checkbox-border: rgba(21, 115, 71, 1);
    --paradise-color-checkbox-border-hover: rgba(21, 115, 71, 0.5);
    --paradise-color-checkbox-border-disabled: rgba(229, 231, 234, 1);

    /* Grid */
    --paradise-bg-edit-cell: cornsilk;
    --paradise-bg-focus-cell: #d0e5fb;
    --paradise-border-focus-cell: #d0e5fb;
}
</style>

<style>
/* ====================================================================
   SECTION 3 — BASE & ACCESSIBILITY
   ==================================================================== */

/* Reduced motion — tôn trọng preference user */
@media (prefers-reduced-motion: reduce) {
    *,
    *::before,
    *::after {
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
        scroll-behavior: auto !important;
    }
}

/* Focus visible — keyboard navigation */
*:focus-visible {
    outline: 2px solid var(--paradise-color-primary);
    outline-offset: 2px;
}

/* Body base — dark default, Inter, dense 13px như styles.css */
body {
    background-color: var(--paradise-bg-body);
    color: var(--paradise-text-body);
    font-family: var(--paradise-font-family-base);
    font-size: 13px;
    line-height: 1.2;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
}

/* Anchor — hover sang Paradise Green */
a {
    color: inherit;
    text-decoration: none;
    transition: var(--paradise-transition-fast);
}
a:hover {
    color: var(--paradise-color-primary);
}

/* Transition chỉ apply cho INTERACTIVE elements */
:where(button, a, input, textarea, select,
       .btn, .card, .paradise-card, .data-setting-button,
       .paradise-btn, .dx-button, .dx-checkbox-icon) {
    transition: background-color 0.15s ease, border-color 0.15s ease, box-shadow 0.15s ease, color 0.15s ease;
}

/* Scrollbar — dark theme custom (webkit) */
::-webkit-scrollbar {
    width: 10px;
    height: 10px;
}
::-webkit-scrollbar-track {
    background: var(--paradise-bg-0);
}
::-webkit-scrollbar-thumb {
    background: var(--paradise-bg-3);
    border-radius: var(--paradise-border-radius-sm);
}
::-webkit-scrollbar-thumb:hover {
    background: var(--paradise-fg-3);
}

/* ====================================================================
   SECTION 4 — GRID & DATA SETTING (DevExtreme integration)
   Dark-aware: header uppercase nhỏ, hàng zebra subtle, hover sang bg-0.
   ==================================================================== */
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
.dx-datagrid .data-setting-edit-cell.dx-checkbox > .dx-checkbox-container,
.dx-datagrid .data-setting-edit-cell > .dx-checkbox > .dx-checkbox-container,
.dx-datagrid .dx-checkbox > .dx-checkbox-container {
    display: flex;
    justify-content: center;
}

/* DevExtreme datagrid theming — dark surface, uppercase header */
.dx-datagrid {
    background-color: var(--paradise-bg-1);
    color: var(--paradise-text-body);
}
.dx-datagrid .dx-row > td {
    border-bottom: 1px solid var(--paradise-border-color);
}
.dx-datagrid-headers {
    background-color: var(--paradise-bg-1);
    color: var(--paradise-text-muted);
    border-bottom: 1px solid var(--paradise-border-color);
}
.dx-datagrid-headers .dx-datagrid-text-content {
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.4px;
}
.dx-datagrid-rowsview .dx-data-row:hover > td {
    background-color: var(--paradise-bg-0);
}

/* Cell value: monospace nếu container có class .paradise-data-mono */
.paradise-data-mono,
.paradise-data-mono .dx-datagrid-rowsview td,
.dx-datagrid.paradise-data-mono .dx-datagrid-text-content {
    font-family: var(--paradise-font-family-mono);
}

/* ====================================================================
   SECTION 5 — BUTTONS
   New BEM modifier classes: .paradise-btn--lg, .paradise-btn--reload, ...
   Legacy alias classes giữ tương thích: .btn-lg, .btnreload, ...
   Action button giữ pill (1.25rem) theo yêu cầu.
   ==================================================================== */

/* Base button — :where() để KHÔNG override Bootstrap với specificity cao */
:where(.data-setting-button, .btn) {
    --paradise-btn-padding-y: 0.75rem;
    --paradise-btn-padding-x: 1rem;
    --paradise-btn-border-radius: var(--paradise-button-border-radius);
    --paradise-btn-font-size: var(--paradise-font-button-md);

    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: var(--paradise-space-2);
    vertical-align: middle;
    padding: var(--paradise-btn-padding-y) var(--paradise-btn-padding-x);
    border-radius: var(--paradise-btn-border-radius);
    min-width: min-content;
    font-size: var(--paradise-btn-font-size);
    font-weight: var(--font-weight-semi-bold);
    line-height: var(--line-height-md);
    text-align: center;
    transition: var(--paradise-transition-fast);
    white-space: nowrap;
}

.paradise-btn {
    --paradise-btn-padding-y: 0.75rem;
    --paradise-btn-padding-x: 1rem;
    --paradise-btn-border-radius: var(--paradise-border-radius-pill);
    --paradise-btn-font-size: var(--paradise-font-button-md);

    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: var(--paradise-space-2);
    vertical-align: middle;
    padding: var(--paradise-btn-padding-y) var(--paradise-btn-padding-x);
    border-radius: var(--paradise-border-radius-pill);
    min-width: min-content;
    font-size: var(--paradise-btn-font-size);
    font-weight: var(--font-weight-semi-bold);
    line-height: var(--line-height-md);
    text-align: center;
    transition: var(--paradise-transition-fast);
    white-space: nowrap;
}

/* Hover: brighten (dark default); light mode đảo lại trong override bên dưới */
:where(.data-setting-button, .paradise-btn, .btn):hover {
    filter: brightness(1.1);
}

[data-bs-theme="light"] :where(.data-setting-button, .paradise-btn, .btn):hover {
    filter: brightness(0.9);
}

/* Size variants — BEM modifier (mới) + alias (legacy) */
:where(.paradise-btn--lg, .paradise-btn-lg /* [LEGACY] */, .btn-lg) {
    --paradise-btn-padding-y: 0.875rem;
    --paradise-btn-padding-x: 1.25rem;
    --paradise-btn-font-size: var(--paradise-font-button-lg);
}
:where(.paradise-btn--xl, .paradise-btn-xl /* [LEGACY] */, .btn-xl) {
    --paradise-btn-padding-y: 1rem;
    --paradise-btn-padding-x: 1.5rem;
    --paradise-btn-border-radius: 2rem;
    --paradise-btn-font-size: var(--paradise-font-button-xl);
}
:where(.paradise-btn--sm, .paradise-btn-sm /* [LEGACY] */, .btn-sm) {
    --paradise-btn-padding-y: 0.5rem;
    --paradise-btn-padding-x: 0.75rem;
    --paradise-btn-font-size: var(--paradise-font-button-sm);
}

/* Action button — base style (chung cho mọi nút nghiệp vụ) */
.btnreload, .paradise-btn-reload, .paradise-btn--reload,
.btnfwadd, .paradise-btn-add, .paradise-btn--add,
.btnfwsave, .paradise-btn-save, .paradise-btn--save,
.btnfwdelete, .paradise-btn-delete, .paradise-btn--delete,
.btnfwreset, .paradise-btn-reset, .paradise-btn--reset,
.btnexport, .paradise-btn-export, .paradise-btn--export, .data-setting-button-export,
.btnimport, .paradise-btn-import, .paradise-btn--import, .data-setting-button-import,
.btnspaction, .data-setting-button-spaction {
    color: white;
    height: 2.5rem;
    min-width: 10rem;
    border: 1px solid transparent;
}

/* Action button — màu theo nghiệp vụ */
.btnreload, .paradise-btn-reload, .paradise-btn--reload {
    background-color: var(--paradise-color-btnreload);
    border-color: var(--paradise-color-btnreload);
}
.btnfwadd, .paradise-btn-add, .paradise-btn--add {
    background-color: var(--paradise-color-btnfwadd);
    border-color: var(--paradise-color-btnfwadd);
}
.btnfwsave, .paradise-btn-save, .paradise-btn--save {
    background-color: var(--paradise-color-btnfwsave);
    border-color: var(--paradise-color-btnfwsave);
}
.btnfwdelete, .paradise-btn-delete, .paradise-btn--delete {
    background-color: var(--paradise-color-btnfwdelete);
    border-color: var(--paradise-color-btnfwdelete);
}
.btnfwreset, .paradise-btn-reset, .paradise-btn--reset {
    background-color: var(--paradise-color-btnfwreset);
    border-color: var(--paradise-color-btnfwreset);
    color: #000;
}
.btnexport, .paradise-btn-export, .paradise-btn--export, .data-setting-button-export,
.btnimport, .paradise-btn-import, .paradise-btn--import, .data-setting-button-import {
    background-color: var(--paradise-color-btnexport);
    border-color: var(--paradise-color-btnexport);
}

/* Primary accent button (Paradise Green filled) */
.btn-primary, .paradise-btn--primary {
    background-color: var(--paradise-color-primary);
    border-color: var(--paradise-color-primary);
    color: #fff;
    font-weight: var(--font-weight-bold);
}

/* ====================================================================
   SECTION 6 — INPUTS & CONTROLS
   Dark surface, border subtle, focus ring Paradise Green.
   ==================================================================== */

:where(.paradise-input,
       .dx-texteditor-input-container,
       .dx-editor-outlined,
       input.dx-texteditor-input,
       input, textarea) {
    border-radius: var(--paradise-input-border-radius);
}

.dx-texteditor.dx-editor-outlined,
.dx-texteditor.dx-editor-outlined .dx-texteditor-input {
    height: 2.5rem;
    border-color: var(--paradise-color-input-border);
    background-color: var(--paradise-bg-body);
    color: var(--paradise-text-body);
}

.dx-texteditor.dx-editor-outlined.dx-state-active,
.dx-texteditor.dx-editor-outlined.dx-state-focused,
.dx-texteditor.dx-editor-outlined.dx-state-hover {
    border-color: var(--paradise-color-input-border-hover);
}

.dx-texteditor.dx-editor-outlined.dx-state-focused {
    box-shadow: 0 0 0 0.125rem var(--paradise-color-input-focus-ring);
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

/* Checkbox & Radio modernization */
.dx-checkbox-icon,
.dx-radiobutton-icon {
    border-radius: var(--paradise-border-radius-sm);
    border: 1px solid var(--paradise-color-checkbox-border);
    transition: var(--paradise-transition-fast);
    background-color: var(--paradise-bg-1);
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

/* ====================================================================
   SECTION 7 — CARDS & MODALS
   Sharp 4px corner, dark surface, blur backdrop.
   ==================================================================== */

.paradise-card {
    background-color: var(--paradise-card-bg);
    border: var(--paradise-card-border);
    box-shadow: var(--paradise-card-shadow);
    border-radius: var(--paradise-card-radius);
    padding: var(--paradise-card-padding);
    transition: var(--paradise-transition-fast);
}

.paradise-card.clickable:hover {
    transform: translateY(-2px);
    box-shadow: var(--paradise-shadow-lg);
    border-color: var(--paradise-border-strong);
    cursor: pointer;
}

/* [LEGACY] .glass-card — alias từ phong cách cũ của MnuKPI001, KHÔNG xoá */
.glass-card {
    background-color: var(--paradise-card-bg);
    border: var(--paradise-card-border);
    box-shadow: var(--paradise-card-shadow);
    border-radius: var(--paradise-card-radius);
    padding: var(--paradise-card-padding);
    transition: var(--paradise-transition-fast);
}
.glass-card.clickable:hover {
    transform: translateY(-2px);
    box-shadow: var(--paradise-shadow-lg);
    border-color: var(--paradise-border-strong);
    cursor: pointer;
}

/* Bootstrap modal override với tokens — blur backdrop kiểu Paradise Modern */
.modal-content {
    background-color: var(--paradise-modal-bg);
    border: 1px solid var(--paradise-border-strong);
    border-radius: var(--paradise-modal-radius);
    box-shadow: var(--paradise-modal-shadow);
    color: var(--paradise-text-body);
}
.modal-backdrop.show {
    background: var(--paradise-modal-backdrop);
    backdrop-filter: blur(6px);
    -webkit-backdrop-filter: blur(6px);
}

/* ====================================================================
   SECTION 8 — TYPOGRAPHY, BADGES & BACKGROUND UTILITIES
   ==================================================================== */
.paradise-text-primary   { color: var(--paradise-color-primary); }
.paradise-text-secondary { color: var(--paradise-color-secondary); }
.paradise-text-success   { color: var(--paradise-color-success); }
.paradise-text-danger    { color: var(--paradise-color-danger); }
.paradise-text-warning   { color: var(--paradise-color-warning); }
.paradise-text-info      { color: var(--paradise-color-info); }
.paradise-text-dark      { color: var(--paradise-text-body); }
.paradise-text-muted     { color: var(--paradise-text-muted); }

/* Semantic shortcut classes (theo styles.css: .pos / .neg / .muted) */
.paradise-pos    { color: var(--paradise-color-success) !important; }
.paradise-neg    { color: var(--paradise-color-danger) !important; }
.paradise-muted  { color: var(--paradise-text-muted); }

.paradise-bg-primary-subtle   { background-color: var(--paradise-bg-primary-subtle); }
.paradise-bg-secondary-subtle { background-color: var(--paradise-bg-secondary-subtle); }
.paradise-bg-success-subtle   { background-color: var(--paradise-bg-success-subtle); }
.paradise-bg-danger-subtle    { background-color: var(--paradise-bg-danger-subtle); }
.paradise-bg-warning-subtle   { background-color: var(--paradise-bg-warning-subtle); }
.paradise-bg-info-subtle      { background-color: var(--paradise-bg-info-subtle); }
.paradise-bg-dark-subtle      { background-color: var(--paradise-bg-dark-subtle); }
.paradise-bg-light-subtle     { background-color: var(--paradise-bg-light-subtle); }
.paradise-bg-header1-subtle   { background-color: var(--paradise-bg-header1-subtle); }
.paradise-bg-header2-subtle   { background-color: var(--paradise-bg-header2-subtle); }
.paradise-bg-important-subtle { background-color: var(--paradise-bg-important-subtle); }

/* Badge — compact uppercase chip (Paradise Modern style) */
.paradise-badge {
    display: inline-flex;
    padding: 2px 6px;
    border-radius: var(--paradise-border-radius-sm);
    font-size: 10px;
    font-weight: var(--font-weight-bold);
    text-transform: uppercase;
    letter-spacing: 0.4px;
    line-height: 1.4;
}
.paradise-badge--success { background: var(--paradise-bg-success-subtle); color: var(--paradise-color-success); }
.paradise-badge--error,
.paradise-badge--danger  { background: var(--paradise-bg-danger-subtle);  color: var(--paradise-color-danger); }
.paradise-badge--warn,
.paradise-badge--warning { background: var(--paradise-bg-warning-subtle); color: var(--paradise-color-warning); }
.paradise-badge--info    { background: var(--paradise-bg-info-subtle);    color: var(--paradise-color-info); }
.paradise-badge--primary { background: var(--paradise-bg-primary-subtle); color: var(--paradise-color-primary); }

/* KPI block — Paradise Modern dashboard pattern */
.paradise-kpi-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
    gap: 1px;
    background: var(--paradise-border-color);
    border: 1px solid var(--paradise-border-color);
    border-radius: var(--paradise-card-radius);
    overflow: hidden;
    margin-bottom: var(--paradise-space-4);
}
.paradise-kpi {
    background: var(--paradise-bg-1);
    padding: var(--paradise-space-4);
    display: flex;
    flex-direction: column;
}
.paradise-kpi__label {
    color: var(--paradise-text-muted);
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.4px;
    margin-bottom: var(--paradise-space-1);
    font-weight: var(--font-weight-semi-bold);
}
.paradise-kpi__value {
    font-family: var(--paradise-font-family-mono);
    font-size: 20px;
    font-weight: var(--font-weight-bold);
    color: var(--paradise-text-body);
}
.paradise-kpi__value.paradise-pos { color: var(--paradise-color-success); }
.paradise-kpi__value.paradise-neg { color: var(--paradise-color-danger); }
.paradise-kpi__sub {
    margin-top: var(--paradise-space-1);
    font-size: 11px;
    color: var(--paradise-text-muted);
}

/* ====================================================================
   SECTION 9 — TIMELINE / REQUEST CARDS
   ==================================================================== */

.timeline-step .circle.blue   { background-color: var(--paradise-color-primary); }
.timeline-step .circle.gray   { background-color: var(--paradise-text-muted); }
.timeline-step .circle.yellow { background-color: var(--paradise-color-warning); }
.timeline-step .circle.green  { background-color: var(--paradise-color-success); }
.timeline-step .circle.red    { background-color: var(--paradise-color-danger); }

.request-CardList .card {
    transition: var(--paradise-transition-fast);
    background-color: var(--paradise-bg-1);
    border: none;
    border-bottom: 1px solid var(--paradise-border-color);
    border-radius: 0;
}
.request-CardList .card:hover {
    box-shadow: var(--paradise-shadow-md);
    transform: translateY(-2px);
}

/* Fade in animation — giữ utility từ styles.css */
@keyframes vtsFadeIn {
    from { opacity: 0; }
    to   { opacity: 1; }
}
.paradise-fade-in { animation: vtsFadeIn 0.3s ease; }

/* ====================================================================
   SECTION 9.5 — STANDARD AVATAR STYLES (ParadiseStyle)
   Consistent circle styling for employee avatar images across menus.
   ==================================================================== */
.avatar-img {
    width: 48px;
    height: 48px;
    object-fit: cover;
    border-radius: 50% !important;
    border: 2px solid var(--paradise-border-color);
    padding: 2px;
    box-sizing: border-box;
    display: inline-block;
    vertical-align: middle;
}
</style>

<style>
/* ====================================================================
   SECTION 10 — RESPONSIVE BREAKPOINTS
   Mobile-first: tăng tap target, card stack, button full-width.
   ==================================================================== */

/* MOBILE SMALL (max-width: 480px) */
@media (max-width: 480px) {
    .btnreload, .paradise-btn-reload, .paradise-btn--reload,
    .btnfwadd, .paradise-btn-add, .paradise-btn--add,
    .btnfwsave, .paradise-btn-save, .paradise-btn--save,
    .btnfwdelete, .paradise-btn-delete, .paradise-btn--delete,
    .btnfwreset, .paradise-btn-reset, .paradise-btn--reset,
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
    .dx-datagrid-rowsview .dx-row-focused.dx-data-row > td:not(.dx-focused),
    .dx-datagrid-rowsview .dx-row-focused.dx-data-row > tr > td:not(.dx-focused) {
        background-color: var(--paradise-bg-focus-cell);
        color: var(--paradise-text-body);
    }

    /* Card padding nhỏ hơn cho mobile */
    .paradise-card, .glass-card {
        padding: var(--paradise-space-3);
    }

    /* KPI grid: 1 cột khi quá hẹp */
    .paradise-kpi-grid { grid-template-columns: 1fr; }
    .paradise-kpi { padding: var(--paradise-space-3); }
    .paradise-kpi__value { font-size: 16px; }
}

/* TABLET (481px - 768px) */
@media (min-width: 481px) and (max-width: 768px) {
    .paradise-card, .glass-card {
        padding: var(--paradise-space-4);
    }
    .modal-dialog {
        margin: var(--paradise-space-3) auto;
    }
    .data-setting-grid {
        max-height: 65dvh;
    }
    .paradise-kpi-grid { grid-template-columns: 1fr 1fr; }
}

/* LAPTOP (769px - 1024px) */
@media (min-width: 769px) and (max-width: 1024px) {
    .data-setting-grid {
        max-height: 70dvh;
    }
}

/* DESKTOP WIDE (min-width: 1280px) */
@media (min-width: 1280px) {
    .paradise-card, .glass-card {
        padding: var(--paradise-space-5);
    }
    .data-setting-grid {
        max-height: 80dvh;
    }
}
';

    -- ====================================================================
    -- SECTION 11 — DETERMINISTIC CSS OPTIMIZATION (NO HTTP / NO CREDENTIAL)
    -- ====================================================================
    -- [P4 #15] Không gọi `ss_RequestHttp`, không đọc credential từ `tblSC_Login`,
    --          không phụ thuộc network/API để sinh CSS toàn cục.
    -- [P4 #16] Pipeline tối ưu nội bộ:
    --          1) Bỏ comment CSS dạng /* ... */ bằng vòng lặp CHARINDEX.
    --          2) Chuẩn hoá CR/LF/TAB thành khoảng trắng.
    --          3) Nén khoảng trắng lặp.
    --          4) Bỏ khoảng trắng quanh delimiter CSS phổ biến.
    --          5) Bỏ `;}` dư để giảm kích thước output.
    --
    -- Lý do chọn cách này: procedure sinh style chạy ngay trong SQL Server;
    -- phương án hiện đại/an toàn nhất trong phạm vi T-SQL là deterministic,
    -- side-effect-free, không outbound HTTP, không credential, dễ audit.
    -- ====================================================================

    DECLARE @debug int = 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.tblParameter WHERE Code = 'debug' AND Value = '1')
       OR HOST_NAME() LIKE '%thanhlong%'
        SET @debug = 0;

    IF @debug != 1
    BEGIN
        -- Remove CSS comments: /* ... */
        DECLARE @commentStart int = CHARINDEX(N'/*', @Html);
        DECLARE @commentEnd int;

        WHILE @commentStart > 0
        BEGIN
            SET @commentEnd = CHARINDEX(N'*/', @Html, @commentStart + 2);

            IF @commentEnd = 0
            BEGIN
                -- Nếu comment bị thiếu dấu đóng, bỏ phần còn lại để CSS không bị vỡ.
                SET @Html = LEFT(@Html, @commentStart - 1);
                BREAK;
            END;

            SET @Html = STUFF(@Html, @commentStart, @commentEnd - @commentStart + 2, N' ');
            SET @commentStart = CHARINDEX(N'/*', @Html);
        END;

        -- Normalize whitespace characters.
        SET @Html = REPLACE(@Html, CHAR(13), N' ');
        SET @Html = REPLACE(@Html, CHAR(10), N' ');
        SET @Html = REPLACE(@Html, CHAR(9),  N' ');

        -- Collapse repeated spaces. 10 vòng là đủ cho CSS hiện tại; WHILE bảo vệ
        -- trường hợp formatter sinh nhiều khoảng trắng liên tiếp hơn.
        WHILE CHARINDEX(N'  ', @Html) > 0
            SET @Html = REPLACE(@Html, N'  ', N' ');

        -- Remove whitespace around common CSS delimiters.
        SET @Html = REPLACE(@Html, N' {', N'{');
        SET @Html = REPLACE(@Html, N'{ ', N'{');
        SET @Html = REPLACE(@Html, N' }', N'}');
        SET @Html = REPLACE(@Html, N'} ', N'}');
        SET @Html = REPLACE(@Html, N' ;', N';');
        SET @Html = REPLACE(@Html, N'; ', N';');
        SET @Html = REPLACE(@Html, N' :', N':');
        SET @Html = REPLACE(@Html, N': ', N':');
        SET @Html = REPLACE(@Html, N' ,', N',');
        SET @Html = REPLACE(@Html, N', ', N',');
        SET @Html = REPLACE(@Html, N' > ', N'>');
        SET @Html = REPLACE(@Html, N' >', N'>');
        SET @Html = REPLACE(@Html, N'> ', N'>');
        SET @Html = REPLACE(@Html, N' + ', N'+');
        SET @Html = REPLACE(@Html, N' ~ ', N'~');
        SET @Html = REPLACE(@Html, N'( ', N'(');
        SET @Html = REPLACE(@Html, N' )', N')');
        SET @Html = REPLACE(@Html, N';}', N'}');

        SET @Html = LTRIM(RTRIM(@Html));
    END

    -- Wrap toàn bộ trong 1 <style> ngoài cùng (các </style><style> bên trong
    -- tạo các sub-block để browser parse nhẹ hơn từng phần)
    SET @Html = N'<style>' + @Html + N'</style>';
    SET @StyleHtml = @Html;
END
