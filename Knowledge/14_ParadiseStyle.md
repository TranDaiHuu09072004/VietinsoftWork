# 14 — ParadiseStyle: Chuẩn thiết kế giao diện ParadiseHR Web

> **Skill file** — dùng bắt buộc khi Agent làm bất kỳ việc gì liên quan đến thiết kế, refactor, update UI/UX, renderer HTML, CSS/JS giao diện cho menu Web ParadiseHR.
>
> **Nguồn CSS toàn cục**: file [SQL script/sp_MainStyleCSSParadise_v3.sql](../SQL%20script/sp_MainStyleCSSParadise_v3.sql) — procedure `dbo.sp_MainStyleCSSParadise` sinh CSS toàn cục cho hệ thống.
>
> ⚠️ **Procedure này CHỈ được EXEC 1 lần tại 4 layout gốc** bao quát page shell:
> - `sp_dashboard_mobile_Beta`
> - `paradise_dashboard_sslayoutbody`
> - `sslayoutbody`
> - `HtmlMacOSLayOut`
>
> CSS đã được inject sẵn vào `<head>` của page bởi 4 layout này → **renderer menu thông thường KHÔNG cần gọi `sp_MainStyleCSSParadise`** và **KHÔNG dùng biến `@StyleHtml`**. Token `--paradise-*` + class `.paradise-*` đã sẵn dùng trong scope page (xem Rule 2).
>
> Liên quan: [07_menu_system.md](07_menu_system.md) (menu + HTML cache), [12_CreateMenu.md](12_CreateMenu.md) (tạo menu mới), [13_Migrate_Menu.md](13_Migrate_Menu.md) (migrate/update menu có sẵn), [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) (skill viết renderer an toàn), [99_deprecated.md](99_deprecated.md) (item lỗi thời).
>
> Ghi chú kỹ thuật về `sp_MainStyleCSSParadise` (chỉ liên quan khi maintain proc gốc): proc không gọi `ss_RequestHttp`, không đọc credential từ `tblSC_Login` để minify CSS. Khi không phải debug, CSS được tối ưu nội bộ trong T-SQL bằng pipeline deterministic: bỏ comment CSS, chuẩn hoá whitespace, nén khoảng trắng và bỏ khoảng trắng quanh delimiter CSS phổ biến.

---

## ⚠️ Quy tắc bắt buộc — đọc trước tiên

### Rule 1 — KHÔNG thiết lập background cho bất cứ menu nào

Khi thiết kế hoặc refactor giao diện menu:

- ❌ Không set `background`, `background-color`, `background-image`, `linear-gradient`, `radial-gradient` page wrapper, body.
- ❌ Không tạo nền riêng kiểu full-page như `.page { background: ... }`, `.container { background: ... }`.
- ❌ Không hardcode màu nền `#fff`, `#f8f9fa`, `rgba(...)` cho wrapper chính.
- ✅ Chỉ dùng nền có sẵn từ framework/app shell ParadiseHR.
- ✅ Nếu cần card/panel, dùng class/token card chuẩn: `.paradise-card`, `var(--paradise-card-bg)`, `var(--paradise-card-border)`, `var(--paradise-card-shadow)`.
- ✅ Nếu cần highlight nhỏ bên trong component, dùng border, text color, badge, icon, shadow nhẹ — không tạo background toàn menu.

Mục tiêu: mọi menu đồng nhất với shell của ParadiseHR, không phá theme, dark mode, layout tổng và không tạo mảng nền lệch chuẩn.

### Rule 2 — KHÔNG gọi `sp_MainStyleCSSParadise` trong renderer menu thông thường

`sp_MainStyleCSSParadise` **CHỈ** được EXEC 1 lần tại 4 layout gốc bao quát page shell:

- `sp_dashboard_mobile_Beta`
- `paradise_dashboard_sslayoutbody`
- `sslayoutbody`
- `HtmlMacOSLayOut`

CSS toàn cục (token `--paradise-*`, class `.paradise-*`, dark-mode override) được 4 layout này inject vào `<head>` của page **một lần duy nhất** → mọi renderer menu HTML-rendered chạy bên trong page shell **tự động có sẵn toàn bộ token + class** mà không cần khai báo lại.

❌ Pattern cũ — KHÔNG dùng nữa:

```sql
-- LỖI THỜI, không gọi proc này trong renderer menu nữa
DECLARE @StyleHtml nvarchar(max) = N'';
IF OBJECT_ID('dbo.sp_MainStyleCSSParadise', 'P') IS NOT NULL
BEGIN
    EXEC dbo.sp_MainStyleCSSParadise @StyleHtml = @StyleHtml OUTPUT;
END
SET @html = ISNULL(@StyleHtml, N'') + N'...HTML menu...';
```

✅ Pattern đúng cho renderer thông thường:

```sql
SET @html = N'<div id="menuRoot" class="<prefix>-page">
    <!-- nội dung menu — dùng .paradise-card, .paradise-btn, var(--paradise-*) trực tiếp -->
</div>
<style>
    .<prefix>-page { /* CSS local nếu cần */ }
</style>';
```

Không copy toàn bộ CSS global vào từng menu. Chỉ viết CSS local tối thiểu cho layout riêng của menu.

> Trường hợp ngoại lệ: nếu Agent đang **maintain chính 4 layout gốc** trên, EXEC `sp_MainStyleCSSParadise` vẫn cần — nhưng đây là việc của framework, không phải của renderer menu thông thường.

### Rule 3 — Ưu tiên token `--paradise-*`, không hardcode màu/spacing/font

Bất kỳ CSS mới nào phải ưu tiên token từ ParadiseStyle:

| Nhu cầu | Dùng token/class |
|---|---|
| Font | `var(--paradise-font-family-base)` |
| Spacing | `var(--paradise-space-1)` → `var(--paradise-space-8)` |
| Radius | `var(--paradise-border-radius-sm/md/lg/xl/pill)` |
| Shadow | `var(--paradise-shadow-sm/md/lg/xl)` |
| Text | `var(--paradise-text-body)`, `var(--paradise-text-muted)` |
| Brand/header | `var(--paradise-color-primary)`, `var(--paradise-color-header1)`, `var(--paradise-color-header2)` |
| Semantic | `var(--paradise-color-success/danger/warning/info)` |
| Nền highlight nhạt cùng tone màu chữ | `var(--paradise-bg-primary-subtle)`, `var(--paradise-bg-success-subtle)`, `var(--paradise-bg-danger-subtle)`, `var(--paradise-bg-warning-subtle)`, `var(--paradise-bg-info-subtle)` hoặc class `.paradise-bg-*-subtle` |
| Border | `var(--paradise-border-color)` |
| Card | `var(--paradise-card-bg/border/shadow/radius/padding)` |
| Button | `.paradise-btn`, `.paradise-btn--reload`, `.paradise-btn--add`, `.paradise-btn--save`, `.paradise-btn--delete`, `.paradise-btn--reset`, `.paradise-btn--export` |

#### Ghi chú token nền `*-bg-subtle`

ParadiseStyle có nhóm token nền nhạt cùng tone với màu chữ/semantic để dùng cho badge, alert, chip, KPI card hoặc trạng thái nhỏ bên trong component:

- Token: `--paradise-bg-primary-subtle`, `--paradise-bg-secondary-subtle`, `--paradise-bg-success-subtle`, `--paradise-bg-danger-subtle`, `--paradise-bg-warning-subtle`, `--paradise-bg-info-subtle`, `--paradise-bg-header1-subtle`, `--paradise-bg-important-subtle`.
- Utility class tương ứng: `.paradise-bg-primary-subtle`, `.paradise-bg-success-subtle`, `.paradise-bg-danger-subtle`, ...
- Chỉ dùng cho vùng highlight nhỏ; vẫn không được dùng để tạo background toàn page/menu wrapper theo Rule 1.
- Dark mode đã có override riêng trong CSS toàn cục (inject sẵn từ 4 layout gốc, xem Rule 2), nên renderer không hardcode màu nền subtle.

### Rule 4 — Không import font/CSS ngoài trong từng menu

- ❌ Không dùng `@import` Google Fonts trong renderer.
- ❌ Không nhúng CDN CSS riêng nếu không có yêu cầu rõ ràng.
- ✅ Font chuẩn đã có token `--paradise-font-family-base`.

### Rule 5 — Không dùng inline style nếu có thể viết class local

- ❌ Tránh `style="..."` dài trong HTML.
- ✅ Tạo class local có prefix riêng của menu, ví dụ `hwvts-`, `crm-`, `lesson-`.
- ✅ CSS local phải đặt trong `<style>` cùng renderer (KHÔNG cần ghép sau `@StyleHtml` — CSS toàn cục đã có sẵn từ layout gốc), để scope theo menu.

### Rule 6 — CSS local phải scope theo root menu

Mỗi renderer phải có root duy nhất:

```html
<div id="<uniqueMenuRoot>" class="<prefix>-page">
```

CSS local phải scope qua root/prefix:

```css
.<prefix>-page { ... }
.<prefix>-card { ... }
.<prefix>-title { ... }
```

Không viết selector global như:

```css
.card { ... }
button { ... }
table { ... }
* { ... }
body { ... }
```

Nếu bắt buộc style element, scope dưới root:

```css
.<prefix>-page table { ... }
.<prefix>-page button { ... }
```

### Rule 7 — Dark mode và accessibility phải tự tương thích

- Không hardcode màu chữ/nền làm vỡ dark mode.
- Dùng `var(--paradise-text-body)`, `var(--paradise-text-muted)`, `var(--paradise-card-bg)`, `var(--paradise-border-color)`.
- Button dùng `.paradise-btn` để hưởng focus/hover chuẩn.
- Không tắt outline/focus-visible.
- Không tạo animation mạnh; nếu có animation phải tôn trọng `prefers-reduced-motion` đã có trong global CSS.

#### Ghi chú input/control bên trong card

- Input/select/textarea **nằm trong card** dùng `background-color: var(--paradise-bg-surface)`, **KHÔNG** dùng `--paradise-bg-body`. Lý do: dark mode `--bg-body = #121212` còn `--card-bg = #1e1e1e` → input dùng `--bg-body` sẽ tối hơn card và thị giác flat; `--bg-surface` (`#f8f9fa` light / `#1e1e1e` dark) đồng bộ với card hoặc nổi nhẹ.
- Input dùng `border-radius: var(--paradise-input-border-radius)` (alias chuyên cho input), không gắn trực tiếp `--paradise-border-radius-md` để khi global đổi shape input thì menu tự cập nhật.
- Row `label` chứa `<input type="checkbox">` / `<input type="radio">` phải có `cursor: pointer` — affordance a11y, không có sẵn từ browser default cho `<label>` bọc.

#### Ghi chú heading hierarchy của menu

- Tiêu đề chính của menu HTML-rendered ưu tiên dùng `<h2>`, KHÔNG `<h1>`. Lý do: shell ParadiseHR (header app) đã chiếm `<h1>` của page; menu nằm bên trong shell ⇒ chỉ nên là cấp `<h2>` trở xuống để giữ heading hierarchy hợp lệ cho screen reader.

#### Ghi chú button: căn giữa dọc và xử lý nguyên nhân gốc

`paradise-btn` global dùng `--paradise-btn-font-size: var(--paradise-font-button-md)`; trong `sp_MainStyleCSSParadise_v3.sql`, token này hiện là `0.875rem`.

Các lỗi thuộc hành vi chuẩn của button như chữ lệch thấp/cao, căn giữa dọc, `line-height`, `display`, `align-items`, `justify-content` phải sửa tại base rule chung trong `sp_MainStyleCSSParadise_v3.sql`, không tạo class local chỉ để ghi đè riêng từng menu.

Base rule chuẩn của button phải có các thuộc tính căn giữa:

```css
:where(.data-setting-button, .btn) {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: var(--paradise-space-2);
    vertical-align: middle;
    line-height: var(--line-height-md);
    text-align: center;
}
```

`.paradise-btn` là class button chuẩn riêng của ParadiseStyle, nên phải tự định nghĩa phong cách pill ngay trong base class, không phụ thuộc alias `--paradise-button-border-radius`, `.btn`, `.data-setting-button`, hoặc modifier khác:

```css
.paradise-btn {
    --paradise-btn-border-radius: var(--paradise-border-radius-pill);
    border-radius: var(--paradise-border-radius-pill);
}
```

Chỉ dùng class local có scope riêng khi đó là khác biệt thiết kế riêng của menu, không phải bug của button global. Khi user yêu cầu điều tra nguyên nhân gốc, phải kiểm tra file [sp_MainStyleCSSParadise_v3.sql](../SQL%20script/sp_MainStyleCSSParadise_v3.sql) (nguồn CSS toàn cục), `tblHtmlScriptCache` (cache renderer), computed/matched CSS trước khi đề xuất override local.

Khi user yêu cầu "bo tròn giống badge/status/chip", ưu tiên sửa trực tiếp `.paradise-btn` trong global style nếu đây là chuẩn chung; chỉ override local khi user xác nhận đó là ngoại lệ menu.

### Rule 8 — Không sửa metadata menu khi chỉ thiết kế UI

Nếu user chỉ yêu cầu "thiết kế lại giao diện", "đổi UI", "refactor ParadiseStyle":

- Chỉ update renderer `sp_X_html` và build lại `tblHtmlScriptCache`.
- Không đổi `MEN_Menu`, `tblSC_Object`, `tblMD_Message`, `tblDataSetting`, `tblDataSettingLayout`, quyền nếu không được yêu cầu rõ.
- Không gọi `sp_UpdateMenuInUserRight`.
- Chỉ refresh bằng `sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>'` nếu cần.

### Rule 9 — Khi nhúng HTML/JS vào `N'...'`, phải escape chuỗi theo T-SQL trước

Khi renderer build HTML bằng chuỗi `NVARCHAR(MAX)` như `SET @html = ... + N'...<script>...</script>'`, mọi dấu nháy đơn `'` nằm bên trong HTML/JavaScript **bắt buộc** phải được xử lý để không làm SQL Server đóng chuỗi sớm.

Lỗi điển hình nếu làm sai: SQL Server báo `Incorrect syntax near the keyword 'function'`, `String is not a recognized built-in function name`, hoặc báo lỗi gần các identifier JavaScript dài. Nguyên nhân là chuỗi `N'...'` đã bị đóng trước đoạn `<script>`, khiến JavaScript bị parse như T-SQL.

Checklist bắt buộc khi viết renderer:

- [ ] Ưu tiên dùng dấu nháy kép `"` trong JavaScript/HTML attribute bên trong chuỗi SQL.
- [ ] Nếu bắt buộc dùng nháy đơn trong literal SQL, phải viết thành `''`.
- [ ] Không dùng pattern JavaScript `.replace(/''/g, ...)` trong chuỗi `N'...'`; dùng `.replace(/\u0027/g, "&#039;")` để tránh nháy đơn phá chuỗi SQL.
- [ ] Biến text đa ngôn ngữ đưa vào JavaScript phải escape trước bằng biến T-SQL riêng, không chèn `REPLACE(...)` phức tạp trực tiếp giữa block `<script>`.
- [ ] Sau khi sửa renderer, kiểm tra đoạn `<script>` nằm trong chuỗi `N'...'`, còn `MERGE tblHtmlScriptCache` nằm ngoài chuỗi.

Mẫu an toàn:

```sql
DECLARE @emptyJs nvarchar(400) = REPLACE(REPLACE(@empty, N'\', N'\\'), N'"', N'\"');
DECLARE @loadingJs nvarchar(400) = REPLACE(REPLACE(@loading, N'\', N'\\'), N'"', N'\"');

SET @html = N'
<script>
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
})();
