-- ============================================================================
-- File   : SQL script/sp_MainStyleCSSParadise_v3.sql
-- Version: 3.0.0
-- Date   : 2026-05-20
-- Mục đích: Sinh CSS toàn cục cho ParadiseHR Web (output qua @StyleHtml).
--           Refactor từ sp_MainStyleCSSParadise_Refactored.sql với 21 cải tiến
--           thuộc 5 Priority đã thống nhất với user.
--
-- CHANGELOG so với version cũ:
--   ── Priority 1: Bug fix + Performance ─────────────────────────────────
--   [1] Bỏ dòng `SET @debug = 1` đè cuối → minification thực sự chạy production.
--   [2] Bỏ `* { transition: ... }` global → chỉ apply cho interactive elements
--       (button, a, input, textarea, select, .btn, .card, .dx-button, ...).
--   [3] Scope `input, textarea` qua `:where()` → specificity = 0,0,0 → user
--       component có thể override dễ dàng.
--   [4] Scope `.btn` override qua `:where()` → không vỡ Bootstrap thuần.
--
--   ── Priority 2: Dark mode + Token enrichment ──────────────────────────
--   [5] Spacing scale: --paradise-space-0..8 (0 → 4rem).
--   [6] Z-index scale: --paradise-z-* (base, dropdown, sticky, fixed,
--       modal-backdrop, modal, popup, tooltip, toast).
--   [7] Shadow scale: --paradise-shadow-sm/md/lg/xl.
--   [8] Card tokens: --paradise-card-bg/border/shadow/radius/padding.
--   [9] Modal tokens: --paradise-modal-bg/backdrop/radius/shadow.
--   [10] Dark mode override TOÀN BỘ color/button/decoration/checkbox variables
--        (không chỉ 8 var như trước).
--
--   ── Priority 3: Responsive + Accessibility ────────────────────────────
--   [11] Bổ sung breakpoints: 768px (tablet), 1024px (laptop), 1280px+ (wide).
--   [12] `@media (prefers-reduced-motion: reduce)` → tắt animation cho user
--        nhạy cảm với chuyển động.
--   [13] `:focus-visible` outline → keyboard navigation rõ ràng.
--   [14] Timeline colors dùng variables thay vì hardcode hex.
--
--   ── Priority 4: Security + Code organization ──────────────────────────
--   [15] Loại bỏ minify runtime qua HTTP (`ss_RequestHttp`) để tránh phụ thuộc
--        network/API/credential trong procedure sinh style toàn cục.
--   [16] Tối ưu CSS nội bộ bằng pipeline deterministic: bỏ comment CSS và
--        chuẩn hoá whitespace an toàn ngay trong T-SQL, không gọi service ngoài.
--   [17] Tách `--paradise-font-family-base` (Inter + fallback system-ui) thành
--        token chung → menu không cần tự import Google Fonts riêng lẻ.
--
--   ── Priority 5: Long-term refactor ────────────────────────────────────
--   [18] Tổ chức CSS thành 10 SECTION rõ ràng (variables → base → buttons →
--        inputs → cards/modals → grid → utilities → timeline → responsive →
--        legacy compat). Mỗi section có comment banner.
--   [19] BEM modifier convention mới: `.paradise-btn--lg`, `.paradise-btn--reload`.
--        GIỮ alias cũ (`.btnreload`, `.paradise-btn-lg`) cho backward compat —
--        đánh dấu [LEGACY] trong comment để dần deprecate.
--   [20] Mỗi token quan trọng có comment "Used by: <component>" để dev biết
--        impact khi đổi.
--
--   ── Note về adoption ──────────────────────────────────────────────────
--   [21] Item "Áp dụng vào component" KHÔNG thuộc phạm vi file này — đây là
--        việc refactor renderer của từng menu (vd sp_CRMDashboard,
--        sp_KPIListDataCollection) để dùng var(--paradise-color-header1) thay
--        vì hardcode #00673b. Sẽ thực hiện trong các PR riêng cho từng menu.
--
-- Cảnh báo: BACKUP DB trước khi chạy. Đây là CREATE OR ALTER procedure —
--           sẽ thay thế version cũ. Test ở môi trường dev trước.
-- ============================================================================

SET NOCOUNT ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_MainStyleCSSParadise]
    @StyleHtml nvarchar(max) output
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Html nvarchar(max) = N'';

    -- ====================================================================
    -- SECTION 1 — DESIGN TOKENS (LIGHT MODE)
    -- All values exposed as CSS custom properties for global consumption.
    -- Components SHOULD use var(--paradise-*) instead of hardcoding colors.
    -- ====================================================================
    SET @Html = N'
:root {
    /* ===== FONT FAMILY (NEW) — Used by: body, all menu containers ===== */
    --paradise-font-family-base: ''Inter'', system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    --paradise-font-family-mono: ''SF Mono'', Monaco, Consolas, "Liberation Mono", "Courier New", monospace;

    /* ===== SPACING SCALE (NEW) — Used by: card padding, modal margin, grid gap ===== */
    --paradise-space-0: 0;
    --paradise-space-1: 0.25rem;   /* 4px */
    --paradise-space-2: 0.5rem;    /* 8px */
    --paradise-space-3: 0.75rem;   /* 12px */
    --paradise-space-4: 1rem;      /* 16px */
    --paradise-space-5: 1.5rem;    /* 24px */
    --paradise-space-6: 2rem;      /* 32px */
    --paradise-space-7: 3rem;      /* 48px */
    --paradise-space-8: 4rem;      /* 64px */

    /* ===== Z-INDEX SCALE (NEW) — Used by: dropdown, modal, popup, tooltip ===== */
    --paradise-z-base: 1;
    --paradise-z-dropdown: 1000;
    --paradise-z-sticky: 1020;
    --paradise-z-fixed: 1030;
    --paradise-z-modal-backdrop: 1040;
    --paradise-z-modal: 1050;
    --paradise-z-popup: 1060;
    --paradise-z-tooltip: 1080;
    --paradise-z-toast: 1090;

    /* ===== SHADOW SCALE (NEW) — Used by: card, modal, hover effects ===== */
    --paradise-shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
    --paradise-shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -2px rgba(0, 0, 0, 0.06);
    --paradise-shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -4px rgba(0, 0, 0, 0.05);
    --paradise-shadow-xl: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.04);

    /* ===== TRANSITION (3 tốc độ) — Used by: button hover, card hover, modal ===== */
    --paradise-transition-fast: all 0.15s ease;
    --paradise-transition-base: all 0.25s ease-in-out;
    --paradise-transition-slow: all 0.4s ease;

    /* ===== BORDER RADIUS SCALE (NEW) ===== */
    --paradise-border-color: rgba(229, 231, 234, 1);
    --paradise-border-radius-sm: 0.375rem;     /* 6px  - input/badge nhỏ */
    --paradise-border-radius-md: 0.75rem;      /* 12px - input/card chuẩn */
    --paradise-border-radius-lg: 1rem;         /* 16px - card lớn */
    --paradise-border-radius-xl: 1.25rem;      /* 20px - button bo tròn */
    --paradise-border-radius-pill: 999px;      /* pill - badge/status */

    /* ===== MÀU SẮC CƠ BẢN (light mode) ===== */
    /* Primary đổi sang xanh CRM cho đồng bộ với MnuKPI001 (Tổng quan CRM) */
    --paradise-color-primary: rgba(0, 103, 59, 1);          /* #00673b - xanh CRM brand */
    --paradise-color-secondary: rgba(108, 117, 125, 1);
    --paradise-color-success: rgba(25, 135, 84, 1);         /* #198754 - xanh success */
    --paradise-color-danger: rgba(220, 53, 69, 1);
    --paradise-color-warning: rgba(255, 193, 7, 1);
    --paradise-color-info: rgba(23, 162, 184, 1);
    --paradise-color-dark: rgba(52, 58, 64, 1);
    --paradise-color-light: rgba(248, 249, 250, 1);

    /* ===== SUBTLE BACKGROUND TOKENS (NEW) — Used by: badges, alerts, chips, KPI cards ===== */
    /* Quy ước: màu nền cùng tone với text semantic nhưng rất nhạt để dùng cho highlight nhỏ. */
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

    /* ===== MÀU NỀN & TEXT ===== */
    --paradise-bg-body: #ffffff;
    --paradise-bg-surface: color(display-p3 0.97 1 0.95 / 0.5);
    --paradise-text-body: #212529;
    --paradise-text-muted: #6c757d;

    /* ===== CARD TOKENS (NEW) — Used by: .paradise-card, .glass-card (legacy) ===== */
    --paradise-card-bg: #ffffff;
    --paradise-card-border: 1px solid #e5e7eb;
    --paradise-card-shadow: var(--paradise-shadow-sm);
    --paradise-card-radius: var(--paradise-border-radius-md);
    --paradise-card-padding: var(--paradise-space-5);

    /* ===== MODAL TOKENS (NEW) — Used by: Bootstrap .modal-content, .modal-backdrop ===== */
    --paradise-modal-bg: #ffffff;
    --paradise-modal-backdrop: rgba(0, 0, 0, 0.65);
    --paradise-modal-radius: var(--paradise-border-radius-md);
    --paradise-modal-shadow: var(--paradise-shadow-xl);

    /* ===== MÀU TRANG TRÍ & LOGO ===== */
    --paradise-color-decor-bg1: rgba(237, 255, 200, 1);
    --paradise-color-decor-bg2: rgba(213, 254, 129, 1);
    --paradise-color-decor-main: rgba(159, 225, 45, 1);
    --paradise-color-logo-main: rgba(115, 196, 29, 1);
    --paradise-color-text-bg: rgba(29, 147, 54, 1);
    --paradise-color-header1: rgba(0, 103, 59, 1);          /* Used by: MnuKPI001 title gradient */
    --paradise-color-header2: rgba(0, 76, 57, 1);
    --paradise-color-important: rgba(255, 0, 0, 1);

    /* ===== MÀU NÚT BẤM CỤ THỂ ===== */
    --paradise-color-btnreload: rgba(25, 135, 84, 1);
    --paradise-color-btnfwadd: rgba(25, 135, 84, 1);
    --paradise-color-btnexport: rgba(0, 100, 0, 1);
    --paradise-color-btnfwsave: rgba(37, 32, 94, 1);
    --paradise-color-btnfwdelete: rgba(233, 66, 53, 1);
    --paradise-color-btnfwreset: rgba(255, 192, 0, 1);

    /* ===== INPUT & CHECKBOX ===== */
    --paradise-color-input-border: rgba(229, 231, 234, 1);
    --paradise-color-input-border-hover: rgba(158, 162, 174, 1);
    --paradise-color-input-disabled: rgba(229, 231, 234, 1);
    --paradise-color-input-focus-ring: rgba(13, 110, 253, 0.25);

    --paradise-color-checkbox: rgba(21, 115, 71, 1);
    --paradise-color-checkbox-border: rgba(21, 115, 71, 1);
    --paradise-color-checkbox-border-hover: rgba(21, 115, 71, 0.5);
    --paradise-color-checkbox-border-disabled: rgba(229, 231, 234, 1);

    /* ===== GRID & DATA CELL ===== */
    --paradise-bg-edit-cell: cornsilk;
    --paradise-bg-focus-cell: #d0e5fb;
    --paradise-bg-weekend-cell: inherit;
    --paradise-border-focus-cell: #d0e5fb;

    /* ===== TYPOGRAPHY ===== */
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

    --line-height-xs: 0.75rem;
    --line-height-sm: 1rem;
    --line-height-md: 1.25rem;
    --line-height-lg: 1.5rem;

    /* ===== LEGACY ALIASES (giữ tương thích — không xoá) ===== */
    --paradise-input-border-radius: var(--paradise-border-radius-md);
    --paradise-button-border-radius: var(--paradise-border-radius-xl);
}

/* ====================================================================
   SECTION 2 — DARK MODE OVERRIDE (TOÀN BỘ color tokens)
   Trigger: <html data-bs-theme="dark"> hoặc <body data-bs-theme="dark">
   ==================================================================== */
[data-bs-theme="dark"] {
    /* Body / surface */
    --paradise-bg-body: #121212;
    --paradise-bg-surface: #1e1e1e;
    --paradise-text-body: #e0e0e0;
    --paradise-text-muted: #a0a0a0;

    /* Border */
    --paradise-border-color: #2e2e2e;

    /* Card / Modal */
    --paradise-card-bg: #1e1e1e;
    --paradise-card-border: 1px solid #2e2e2e;
    --paradise-card-shadow: 0 1px 3px rgba(0, 0, 0, 0.5);
    --paradise-modal-bg: #1e1e1e;
    --paradise-modal-backdrop: rgba(0, 0, 0, 0.85);
    --paradise-modal-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.7);

    /* Brand colors — sáng hơn cho contrast tốt trên bg đen */
    --paradise-color-primary: rgba(0, 150, 80, 1);
    --paradise-color-secondary: rgba(140, 150, 160, 1);
    --paradise-color-success: rgba(40, 180, 100, 1);
    --paradise-color-danger: rgba(240, 80, 90, 1);
    --paradise-color-warning: rgba(255, 200, 40, 1);
    --paradise-color-info: rgba(50, 180, 200, 1);
    --paradise-color-dark: rgba(200, 205, 215, 1);
    --paradise-color-light: rgba(60, 65, 70, 1);

    /* Subtle backgrounds — dark mode: cùng tone nhưng đủ nổi trên nền tối */
    --paradise-bg-primary-subtle: rgba(0, 150, 80, 0.20);
    --paradise-bg-secondary-subtle: rgba(140, 150, 160, 0.18);
    --paradise-bg-success-subtle: rgba(40, 180, 100, 0.20);
    --paradise-bg-danger-subtle: rgba(240, 80, 90, 0.18);
    --paradise-bg-warning-subtle: rgba(255, 200, 40, 0.20);
    --paradise-bg-info-subtle: rgba(50, 180, 200, 0.20);
    --paradise-bg-dark-subtle: rgba(200, 205, 215, 0.16);
    --paradise-bg-light-subtle: rgba(60, 65, 70, 0.85);
    --paradise-bg-header1-subtle: rgba(0, 150, 80, 0.20);
    --paradise-bg-header2-subtle: rgba(0, 110, 70, 0.20);
    --paradise-bg-important-subtle: rgba(255, 90, 90, 0.16);

    /* Button colors — adjust cho dark */
    --paradise-color-btnreload: rgba(40, 180, 100, 1);
    --paradise-color-btnfwadd: rgba(40, 180, 100, 1);
    --paradise-color-btnexport: rgba(30, 150, 40, 1);
    --paradise-color-btnfwsave: rgba(80, 75, 160, 1);
    --paradise-color-btnfwdelete: rgba(240, 80, 90, 1);
    --paradise-color-btnfwreset: rgba(255, 180, 40, 1);

    /* Header colors */
    --paradise-color-header1: rgba(0, 150, 80, 1);
    --paradise-color-header2: rgba(0, 110, 70, 1);
    --paradise-color-text-bg: rgba(50, 180, 90, 1);

    /* Decoration */
    --paradise-color-decor-bg1: rgba(40, 50, 30, 1);
    --paradise-color-decor-bg2: rgba(60, 80, 40, 1);
    --paradise-color-decor-main: rgba(120, 180, 60, 1);
    --paradise-color-logo-main: rgba(140, 220, 80, 1);
    --paradise-color-important: rgba(255, 90, 90, 1);

    /* Input */
    --paradise-color-input-border: #495057;
    --paradise-color-input-border-hover: #6c757d;
    --paradise-color-input-disabled: #343a40;
    --paradise-color-input-focus-ring: rgba(40, 180, 100, 0.4);

    /* Checkbox */
    --paradise-color-checkbox: rgba(40, 180, 100, 1);
    --paradise-color-checkbox-border: rgba(40, 180, 100, 1);
    --paradise-color-checkbox-border-hover: rgba(40, 180, 100, 0.5);
    --paradise-color-checkbox-border-disabled: #343a40;

    /* Grid */
    --paradise-bg-edit-cell: #014D4E;
    --paradise-bg-focus-cell: #0c3b5e;
    --paradise-border-focus-cell: #0c3b5e;
}
</style>

<style>
/* ====================================================================
   SECTION 3 — BASE & ACCESSIBILITY
   ==================================================================== */

/* [P3 #12] Reduced motion — tôn trọng preference user */
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

/* [P3 #13] Focus visible — keyboard navigation */
*:focus-visible {
    outline: 2px solid var(--paradise-color-primary);
    outline-offset: 2px;
}

/* Body base — dùng font-family token */
body {
    background-color: var(--paradise-bg-body);
    color: var(--paradise-text-body);
    font-family: var(--paradise-font-family-base);
}

/* [P1 #2] Transition chỉ apply cho INTERACTIVE elements (KHÔNG dùng `*` global) */
/* :where() giữ specificity = 0,0,0 để user component dễ override */
:where(button, a, input, textarea, select,
       .btn, .card, .paradise-card, .data-setting-button,
       .paradise-btn, .dx-button, .dx-checkbox-icon) {
    transition: background-color 0.2s ease, border-color 0.2s ease, box-shadow 0.2s ease;
}

/* ====================================================================
   SECTION 4 — GRID & DATA SETTING (DevExtreme integration)
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

/* ====================================================================
   SECTION 5 — BUTTONS
   New BEM modifier classes: .paradise-btn--lg, .paradise-btn--reload, ...
   Legacy alias classes giữ tương thích: .btn-lg, .btnreload, ...
   ==================================================================== */

/* [P1 #4] Base button — :where() để KHÔNG override Bootstrap với specificity cao */
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
    transition: var(--paradise-transition-base);
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
    transition: var(--paradise-transition-base);
}

:where(.data-setting-button, .paradise-btn, .btn):hover {
    filter: brightness(0.9);
}

[data-bs-theme="dark"] :where(.data-setting-button, .paradise-btn, .btn):hover {
    filter: brightness(1.1);
}

/* [P5 #19] Size variants — BEM modifier (mới) + alias (legacy) */
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
}
.btnexport, .paradise-btn-export, .paradise-btn--export, .data-setting-button-export,
.btnimport, .paradise-btn-import, .paradise-btn--import, .data-setting-button-import {
    background-color: var(--paradise-color-btnexport);
    border-color: var(--paradise-color-btnexport);
}

/* ====================================================================
   SECTION 6 — INPUTS & CONTROLS
   ==================================================================== */

/* [P1 #3] Scope `input, textarea` với :where() — specificity 0 → user override dễ */
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

/* ====================================================================
   SECTION 7 — CARDS & MODALS (NEW)
   ==================================================================== */

/* [P2 #8] Paradise card — token-based */
.paradise-card {
    background-color: var(--paradise-card-bg);
    border: var(--paradise-card-border);
    box-shadow: var(--paradise-card-shadow);
    border-radius: var(--paradise-card-radius);
    padding: var(--paradise-card-padding);
    transition: var(--paradise-transition-base);
}

.paradise-card.clickable:hover {
    transform: translateY(-4px);
    box-shadow: var(--paradise-shadow-lg);
    cursor: pointer;
}

/* [LEGACY] .glass-card — alias từ phong cách cũ của MnuKPI001, KHÔNG xoá */
.glass-card {
    background-color: var(--paradise-card-bg);
    border: var(--paradise-card-border);
    box-shadow: var(--paradise-card-shadow);
    border-radius: var(--paradise-card-radius);
    padding: var(--paradise-card-padding);
    transition: var(--paradise-transition-base);
}
.glass-card.clickable:hover {
    transform: translateY(-4px);
    box-shadow: var(--paradise-shadow-lg);
    cursor: pointer;
}

/* [P2 #9] Bootstrap modal override với tokens */
.modal-content {
    background-color: var(--paradise-modal-bg);
    border-radius: var(--paradise-modal-radius);
    box-shadow: var(--paradise-modal-shadow);
    color: var(--paradise-text-body);
}
.modal-backdrop.show {
    background: var(--paradise-modal-backdrop);
}

/* ====================================================================
   SECTION 8 — TYPOGRAPHY & BACKGROUND UTILITIES
   ==================================================================== */
.paradise-text-primary   { color: var(--paradise-color-primary); }
.paradise-text-secondary { color: var(--paradise-color-secondary); }
.paradise-text-success   { color: var(--paradise-color-success); }
.paradise-text-danger    { color: var(--paradise-color-danger); }
.paradise-text-warning   { color: var(--paradise-color-warning); }
.paradise-text-info      { color: var(--paradise-color-info); }
.paradise-text-dark      { color: var(--paradise-text-body); }
.paradise-text-muted     { color: var(--paradise-text-muted); }

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

/* ====================================================================
   SECTION 9 — TIMELINE / REQUEST CARDS
   ==================================================================== */

/* [P3 #14] Timeline colors — dùng variables thay vì hardcode */
.timeline-step .circle.blue   { background-color: var(--paradise-color-primary); }
.timeline-step .circle.gray   { background-color: var(--paradise-text-muted); }
.timeline-step .circle.yellow { background-color: var(--paradise-color-warning); }
.timeline-step .circle.green  { background-color: var(--paradise-color-success); }
.timeline-step .circle.red    { background-color: var(--paradise-color-danger); }

.request-CardList .card {
    transition: var(--paradise-transition-base);
    border: none;
    border-bottom: 1px solid var(--paradise-border-color);
    border-radius: 0;
}
.request-CardList .card:hover {
    box-shadow: var(--paradise-shadow-md);
    transform: translateY(-2px);
}
</style>

<style>
/* ====================================================================
   SECTION 10 — RESPONSIVE BREAKPOINTS
   Mobile-first approach: base styles cho mobile, override cho larger.
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
        padding: var(--paradise-space-4);
    }
}

/* [P3 #11] TABLET (481px - 768px) */
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
}

/* [P3 #11] LAPTOP (769px - 1024px) */
@media (min-width: 769px) and (max-width: 1024px) {
    .data-setting-grid {
        max-height: 70dvh;
    }
}

/* [P3 #11] DESKTOP WIDE (min-width: 1280px) */
@media (min-width: 1280px) {
    .paradise-card, .glass-card {
        padding: var(--paradise-space-6);
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
GO

PRINT '[OK] Created/Altered procedure dbo.sp_MainStyleCSSParadise v3.0.0';
GO

-- ============================================================================
-- TEST CALL — Verify procedure compile + optimized output.
-- ============================================================================
DECLARE @TestHtml nvarchar(max);
EXEC dbo.sp_MainStyleCSSParadise @StyleHtml = @TestHtml output;
SELECT
    DATALENGTH(@TestHtml) / 2 AS HtmlChars,
    CASE WHEN @TestHtml LIKE N'%ss_RequestHttp%' THEN 1 ELSE 0 END AS HasHttpMinifyCall,
    CASE WHEN @TestHtml LIKE N'%/*%' THEN 1 ELSE 0 END AS HasCssComments,
    LEFT(@TestHtml, 200)      AS Preview_First200,
    RIGHT(@TestHtml, 200)     AS Preview_Last200;
GO
