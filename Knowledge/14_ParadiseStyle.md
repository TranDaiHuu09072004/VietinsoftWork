# 14 — ParadiseStyle: Chuẩn thiết kế giao diện ParadiseHR Web

> **Skill file** — dùng bắt buộc khi Agent làm bất kỳ việc gì liên quan đến thiết kế, refactor, update UI/UX, renderer HTML, CSS/JS giao diện cho menu Web ParadiseHR.
>
> Nguồn chuẩn hiện tại: [SQL script/sp_MainStyleCSSParadise_v3.sql](../SQL%20script/sp_MainStyleCSSParadise_v3.sql), procedure `dbo.sp_MainStyleCSSParadise` sinh CSS toàn cục qua output `@StyleHtml`.
>
> Liên quan: [07_menu_system.md](07_menu_system.md) (menu + HTML cache), [12_CreateMenu.md](12_CreateMenu.md) (tạo menu mới), [13_Migrate_Menu.md](13_Migrate_Menu.md) (migrate/update menu có sẵn), [99_deprecated.md](99_deprecated.md) (item lỗi thời).

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

### Rule 2 — Bắt buộc dùng `sp_MainStyleCSSParadise`

Renderer HTML của menu phải gọi global style trước khi build HTML:

```sql
DECLARE @StyleHtml nvarchar(max) = N'';
IF OBJECT_ID('dbo.sp_MainStyleCSSParadise', 'P') IS NOT NULL
BEGIN
    EXEC dbo.sp_MainStyleCSSParadise @StyleHtml = @StyleHtml OUTPUT;
END

SET @html = ISNULL(@StyleHtml, N'') + N'...HTML menu...';
```

Không copy toàn bộ CSS global vào từng menu. Chỉ viết CSS local tối thiểu cho layout riêng của menu.

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
| Border | `var(--paradise-border-color)` |
| Card | `var(--paradise-card-bg/border/shadow/radius/padding)` |
| Button | `.paradise-btn`, `.paradise-btn--reload`, `.paradise-btn--add`, `.paradise-btn--save`, `.paradise-btn--delete`, `.paradise-btn--reset`, `.paradise-btn--export` |

### Rule 4 — Không import font/CSS ngoài trong từng menu

- ❌ Không dùng `@import` Google Fonts trong renderer.
- ❌ Không nhúng CDN CSS riêng nếu không có yêu cầu rõ ràng.
- ✅ Font chuẩn đã có token `--paradise-font-family-base`.

### Rule 5 — Không dùng inline style nếu có thể viết class local

- ❌ Tránh `style="..."` dài trong HTML.
- ✅ Tạo class local có prefix riêng của menu, ví dụ `hwvts-`, `crm-`, `lesson-`.
- ✅ CSS local phải đặt trong `<style>` cùng renderer, sau `@StyleHtml`, để scope theo menu.

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

Chỉ dùng class local có scope riêng khi đó là khác biệt thiết kế riêng của menu, không phải bug của button global. Khi user yêu cầu điều tra nguyên nhân gốc, phải kiểm tra `sp_MainStyleCSSParadise`, `tblHtmlScriptCache`, computed/matched CSS trước khi đề xuất override local.

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

SET @html = ISNULL(@StyleHtml, N'') + N'
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
