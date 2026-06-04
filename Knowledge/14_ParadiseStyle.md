# 14 — ParadiseStyle: Web UI & UX Guidelines

Reference: [07_menu_system.md](07_menu_system.md) (Menu caching), [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) (Secure rendering).
Global CSS is injected by layout shells (`paradise_dashboard_sslayoutbody`, `sslayoutbody`, etc.). Individual menus must use active tokens directly.

## UI Design & Styling Rules

### Rule 1: No Custom Page Backgrounds
*   Never declare `background-color`, `background-image`, or `linear-gradient` on page wrappers or body tags.
*   Avoid hardcoded `#fff` or `#f8f9fa` backgrounds. Use `.paradise-card` and `var(--paradise-card-bg)` for wrapper boundaries.

### Rule 2: Do Not Call `sp_MainStyleCSSParadise` in Menus
*   Global CSS loads via the page shell layout. Do not run `sp_MainStyleCSSParadise` or assign `@StyleHtml` inside normal menu renderers.

### Rule 3: Standardize on Paradise CSS Variables
*   **Fonts**: `var(--paradise-font-family-base)`.
*   **Spacing / Radius / Shadow**: `var(--paradise-space-1)` to `-8`, `var(--paradise-border-radius-sm)` to `-pill`, `var(--paradise-shadow-sm)` to `-xl`.
*   **Colors & States**: `var(--paradise-color-primary)`, `var(--paradise-text-body)`, `var(--paradise-text-muted)`.
*   **Semantic Subtles** (badges/KPIs): `var(--paradise-bg-success-subtle)`, `var(--paradise-bg-danger-subtle)`, etc.
*   **Buttons**: Use `.paradise-btn` with modifiers like `.paradise-btn--reload`, `--add`, `--save`, `--delete`.

### Rule 4: No External Font/CSS Imports
*   Do not inject `@import` Google Fonts or external CDN stylesheets in menu renderers.

### Rule 5 & 6: Namespace & Scope CSS Locally
*   Always bind your menu to a unique root element (e.g., `<div id="menuRoot" class="hwvts-page">`).
*   Namespace all local CSS rules (e.g., `.hwvts-page .hwvts-card`). Do not override base HTML selectors globally (like `table`, `button`, `*`).

### Rule 7: Accessibility & Dark Mode Adaptation
*   **Inputs inside Cards**: Set background to `var(--paradise-bg-surface)` (not `--paradise-bg-body`) for dark-mode contrast. Set radius to `var(--paradise-input-border-radius)`.
*   **A11y**: Add `cursor: pointer` to labels bocking checkboxes/radios.
*   **Headings**: Set menu primary headers to `<h2>`, never `<h1>` (which belongs to page shell wrapper).
*   **Buttons**: Do not override padding/alignments locally for generic bugs. Align base layouts inside `sp_MainStyleCSSParadise_v3.sql`.

### Rule 8: Retain Menu Metadata on UI Tweaks
*   When performing UI/refactoring work, only update the HTML renderer (`sp_X_html`) and regenerate `tblHtmlScriptCache`. Do not touch `MEN_Menu` metadata or permissions.

---

## Code Safety & Assets Rules

### Rule 9: Safe SQL Single-Quote Escaping
When embedding JS/HTML strings inside NVARCHAR variables, escape single quotes `'` to `''` or declare `@SQ NCHAR(1) = CHAR(39)` and concatenate.
*   Checklist:
    - Use double quotes `"` for HTML attributes/JS string literals inside SQL.
    - Avoid Javascript `.replace(/'/g)` string parsing; use `.replace(/\u0027/g, "&#039;")` instead.
    - Format multilanguage texts into T-SQL local variables before embedding them.

### Rule 10: Bootstrap Icons (BI) Only
*   **Never** use FontAwesome icon selectors (e.g., `fa-solid`, `fa-regular`). Only use Bootstrap Icons (e.g., `bi bi-folder2-open`, `bi bi-calendar3`).
*   For loading spinners, use `bi bi-arrow-repeat` with the global rotating helper class `.paradise-spin`.

### Rule 11: Valid Navigation Icons
*   `MEN_Menu.glyphicon` value **must** exist as an IconName registry inside the `ParadiseIconSVG` table (which serves the sidebar SVG dynamically).
*   If an icon does not exist, use matching defaults: `clock` $\rightarrow$ `history` / `TimeClock`; `shield-lock` $\rightarrow$ `UserRight` / `Security`; `Pencil` $\rightarrow$ `Information`.
