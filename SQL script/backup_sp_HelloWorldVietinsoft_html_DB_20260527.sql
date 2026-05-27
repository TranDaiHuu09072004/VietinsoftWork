-- =====================================================================================
-- BACKUP: Source gốc renderer sp_HelloWorldVietinsoft_html từ DB Vietinsoft_Pay
-- Ngày lấy: 2026-05-27
-- Mục đích: Lưu lại source hiện tại trước khi sửa
-- VI PHẠM: Đang gọi sp_MainStyleCSSParadise (pattern cũ đã deprecated)
-- =====================================================================================

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
        SET @formTitle   = N'Form controls';
        SET @tokenTitle  = N'Token samples';
        SET @statusTitle = N'Status samples';
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
        SET @formTitle   = N'Mẫu form control';
        SET @tokenTitle  = N'Mẫu token màu';
        SET @statusTitle = N'Mẫu trạng thái';
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
        .hwvts-token-primary {
            color: var(--paradise-color-primary);
        }
        .hwvts-token-success { color: var(--paradise-color-success); }
        .hwvts-token-danger { color: var(--paradise-color-danger); }
        .hwvts-token-warning { color: var(--paradise-color-warning); }
        .hwvts-token-info { color: var(--paradise-color-info); }
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
        .hwvts-grid-2 {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: var(--paradise-space-5);
        }
        .hwvts-grid-3 {
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: var(--paradise-space-4);
        }
        .hwvts-actions,
        .hwvts-status-list,
        .hwvts-token-list {
            display: flex;
            flex-wrap: wrap;
            gap: var(--paradise-space-3);
            align-items: center;
        }
        .hwvts-token-card {
            display: grid;
            gap: var(--paradise-space-2);
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-md);
            padding: var(--paradise-space-4);
        }
        .hwvts-token-name {
            font-family: var(--paradise-font-family-mono);
            color: var(--paradise-text-muted);
            font-size: var(--paradise-font-body2);
        }
        .hwvts-token-value {
            margin: 0;
            font-weight: var(--font-weight-bold);
        }
        .hwvts-form-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: var(--paradise-space-4);
        }
        .hwvts-field {
            display: grid;
            gap: var(--paradise-space-2);
        }
        .hwvts-field label {
            color: var(--paradise-text-body);
            font-size: var(--paradise-font-body2);
            font-weight: var(--font-weight-semi-bold);
        }
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
        .hwvts-textarea {
            min-height: 5rem;
            resize: vertical;
        }
        .hwvts-check-row {
            display: flex;
            gap: var(--paradise-space-3);
            align-items: center;
            color: var(--paradise-text-body);
            font-size: var(--paradise-font-body1);
            cursor: pointer;
        }
        input[type="radio"] {
            accent-color: var(--paradise-color-checkbox);
        }
        .hwvts-table-wrap {
            overflow: hidden;
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-md);
        }
        .hwvts-table {
            width: 100%;
            border-collapse: collapse;
        }
        .hwvts-table th {
            padding: var(--paradise-space-3) var(--paradise-space-4);
            color: var(--paradise-text-muted);
            font-size: var(--paradise-font-body2);
            font-weight: var(--font-weight-semi-bold);
            text-align: left;
        }
        .hwvts-table th.hwvts-no-col { width: 5rem; }
        .hwvts-table th.hwvts-points-col { width: 10rem; text-align: right; }
        .hwvts-table td {
            padding: var(--paradise-space-3) var(--paradise-space-4);
            border-top: 1px solid var(--paradise-border-color);
            color: var(--paradise-text-body);
        }
        .hwvts-rank,
        .hwvts-icon {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border: 1px solid var(--paradise-border-color);
            color: var(--paradise-color-primary);
            font-weight: var(--font-weight-bold);
        }
        .hwvts-rank {
            width: 2rem;
            height: 2rem;
            border-radius: var(--paradise-border-radius-pill);
        }
        .hwvts-icon {
            width: 3.25rem;
            height: 3.25rem;
            border-radius: var(--paradise-border-radius-lg);
            font-size: 1.5rem;
        }
        .hwvts-points {
            text-align: right;
            font-weight: var(--font-weight-bold);
            color: var(--paradise-color-primary);
        }
        .hwvts-empty {
            padding: var(--paradise-space-6);
            text-align: center;
            color: var(--paradise-text-muted);
        }
        .hwvts-demo-list {
            margin: 0;
            padding-left: var(--paradise-space-5);
            color: var(--paradise-text-muted);
            line-height: var(--line-height-lg);
        }
        .hwvts-footer {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: var(--paradise-space-4);
            color: var(--paradise-text-muted);
            font-size: var(--paradise-font-body2);
        }
        @media (max-width: 1024px) {
            .hwvts-grid-3 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
        }
        @media (max-width: 768px) {
            .hwvts-page { padding: var(--paradise-space-4); }
            .hwvts-grid-2,
            .hwvts-grid-3,
            .hwvts-form-grid { grid-template-columns: 1fr; }
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
            .replace(/'/g, "&#039;");
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
            html += "<tr>" +
                    "<td><span class=\"hwvts-rank\">" + (i + 1) + "</span></td>" +
                    "<td>" + name + "</td>" +
                    "<td class=\"hwvts-points\">" + points + "</td>" +
                    "</tr>";
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
        if(typeof AjaxHPAParadise !== "function"){
            render([]);
            return;
        }
        AjaxHPAParadise({
            data: {
                name: "sp_HelloWorldVietinsoft_GetTopRank",
                param: ["FilterYear", null, "FilterMonth", null]
            },
            success: function(res){
                try { render(normalizeRows(res)); }
                catch(e) { render([]); }
            },
            error: function(){ render([]); }
        });
    }

    var btn = document.getElementById("hwVtsReloadBtn");
    if(btn) btn.addEventListener("click", loadData);
    loadData();
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
              '3.2'                          AS Version,
              N'ParadiseStyle v3.2 - title synced to Hello Vietinsoft + input bg-surface + check-row cursor + h2 hierarchy' AS VersionData
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

    SELECT @html AS html;
END
GO
