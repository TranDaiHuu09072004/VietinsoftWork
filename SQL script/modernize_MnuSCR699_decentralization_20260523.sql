/*
File: SQL script/modernize_MnuSCR699_decentralization_20260523.sql
Database: Vietinsoft_ForTest
Menu: MnuSCR699 - Phân quyền truy cập / Grant Access Right
Mục đích: Cải tổ giao diện phân quyền theo ParadiseStyle, đơn giản hoá thao tác và giữ nguyên cơ chế lưu quyền hiện có.
Cảnh báo: User tự review và chạy. Agent không thực thi tự động.
Khuyến nghị: Backup database trước khi chạy.

Nguồn xác minh:
- MEN_Menu: MnuSCR699 -> ClassName = sp_decentralization, AssemblyName = DataSetting
- tblDataSetting: sp_decentralization dùng ParadiseWebView2, IsProcedure=1, IsShowLayout=1
- Procedure cũ: sp_decentralization, sp_decentralization_Menu, sp_decentralization_Emp, sp_decentralization_update
*/
USE [Vietinsoft_ForTest];
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -------------------------------------------------------------------------
    -- 1) API dữ liệu quyền menu: giữ logic nguồn SC_ObjectRightList, trả JSON
    -------------------------------------------------------------------------
    EXEC(N'
CREATE OR ALTER PROCEDURE dbo.sp_decentralization_MenuData
(
    @LoginID INT = 3,
    @LanguageID CHAR(2) = ''VN'',
    @LoginAccount VARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LoginIDAccount INT = (
        SELECT TOP 1 LoginID FROM dbo.tblSC_Login WHERE LoginName = @LoginAccount
    );

    IF @LoginIDAccount IS NULL
    BEGIN
        SELECT CAST(0 AS bit) AS IsValid, N'''' AS JsonData;
        RETURN;
    END;

    CREATE TABLE #DataView
    (
        ObjectID INT,
        ParentObjectID INT,
        ObjectName VARCHAR(200),
        Description NVARCHAR(500),
        [Right] VARCHAR(30),
        Prio INT
    );

    INSERT INTO #DataView(ObjectID, ParentObjectID, ObjectName, Description, [Right], Prio)
    EXEC dbo.SC_ObjectRightList @LoginID = @LoginIDAccount, @LanguageID = @LanguageID, @IsInsertTable = 1;

    UPDATE #DataView SET ParentObjectID = ObjectID WHERE ISNULL(ParentObjectID, 0) = 0;
    UPDATE #DataView SET ParentObjectID = Prio WHERE ObjectName = ''DataSetting.sp_DashBoard'';

    SELECT CAST(1 AS bit) AS IsValid,
           (
               SELECT ObjectID,
                      ParentObjectID,
                      ObjectName,
                      ISNULL(Description, N'''') AS Description,
                      ISNULL([Right], '''') AS FullAccess,
                      ISNULL(Prio, 0) AS Prio
               FROM #DataView
               ORDER BY ISNULL(Prio, 0), ObjectID
               FOR JSON PATH
           ) AS JsonData;
END
');

    -------------------------------------------------------------------------
    -- 2) API dữ liệu phạm vi nhân viên: giữ logic nguồn LoadUserRightTree
    -------------------------------------------------------------------------
    EXEC(N'
CREATE OR ALTER PROCEDURE dbo.sp_decentralization_EmpData
(
    @LoginID INT = 3,
    @LanguageID CHAR(2) = ''VN'',
    @LoginAccount VARCHAR(100) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LoginIDAccount INT = (
        SELECT TOP 1 LoginID FROM dbo.tblSC_Login WHERE LoginName = @LoginAccount
    );

    IF @LoginIDAccount IS NULL
    BEGIN
        SELECT CAST(0 AS bit) AS IsValid, N'''' AS JsonData;
        RETURN;
    END;

    CREATE TABLE #DataView
    (
        LoginID INT,
        ObjectID VARCHAR(30),
        Description NVARCHAR(500),
        ViewInfo INT,
        [Right] INT,
        ParentObjectID VARCHAR(30)
    );

    INSERT INTO #DataView(LoginID, ObjectID, Description, ViewInfo, [Right], ParentObjectID)
    EXEC dbo.LoadUserRightTree @LoginID = @LoginIDAccount, @LanguageID = @LanguageID;

    IF LOWER(@LanguageID) = ''en''
        UPDATE #DataView SET Description = dbo.fn_RemoveToneMark(Description);

    SELECT CAST(1 AS bit) AS IsValid,
           (
               SELECT ObjectID,
                      ISNULL(ParentObjectID, '''') AS ParentObjectID,
                      ISNULL(Description, N'''') AS Description,
                      ISNULL(ViewInfo, 0) AS ViewInfo,
                      ISNULL([Right], 0) AS [Right]
               FROM #DataView
               ORDER BY ParentObjectID, ObjectID
               FOR JSON PATH
           ) AS JsonData;
END
');

    -------------------------------------------------------------------------
    -- 3) Renderer mới: một màn hình duy nhất, client render menu/data-scope
    --    Không gọi sp_MainStyleCSSParadise; dùng token/class ParadiseStyle sẵn có.
    -------------------------------------------------------------------------
    EXEC(N'
CREATE OR ALTER PROCEDURE dbo.sp_decentralization
(
    @LoginID INT = 3,
    @LanguageID CHAR(2) = ''VN'',
    @IsWeb INT = NULL,
    @LoginAccount VARCHAR(100) = NULL,
    @IsAcessEmp BIT = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @isVN BIT = CASE WHEN LOWER(ISNULL(@LanguageID, ''VN'')) = ''vn'' THEN 1 ELSE 0 END;
    DECLARE @title NVARCHAR(200) = IIF(@isVN = 1, N''Phân quyền truy cập'', N''Grant Access Right'');
    DECLARE @subtitle NVARCHAR(300) = IIF(@isVN = 1, N''Tìm tài khoản, chọn nhóm quyền hoặc phạm vi dữ liệu, sau đó lưu thay đổi.'', N''Find an account, choose feature permissions or data scope, then save changes.'');
    DECLARE @accountLabel NVARCHAR(200) = IIF(@isVN = 1, N''Tên truy cập / tên nhóm'', N''Login name / group name'');
    DECLARE @menuTab NVARCHAR(100) = IIF(@isVN = 1, N''Quyền chức năng'', N''Feature permissions'');
    DECLARE @empTab NVARCHAR(100) = IIF(@isVN = 1, N''Phạm vi dữ liệu'', N''Data scope'');
    DECLARE @reload NVARCHAR(80) = IIF(@isVN = 1, N''Tải dữ liệu'', N''Load data'');
    DECLARE @save NVARCHAR(80) = IIF(@isVN = 1, N''Lưu thay đổi'', N''Save changes'');
    DECLARE @search NVARCHAR(120) = IIF(@isVN = 1, N''Tìm nhanh quyền, menu, phòng ban...'', N''Search permissions, menus, departments...'');
    DECLARE @empty NVARCHAR(200) = IIF(@isVN = 1, N''Nhập tên truy cập rồi bấm Tải dữ liệu.'', N''Enter login name, then load data.'');
    DECLARE @invalid NVARCHAR(200) = IIF(@isVN = 1, N''Không tìm thấy tên truy cập / tên nhóm.'', N''Login name / group name was not found.'');
    DECLARE @confirm NVARCHAR(200) = IIF(@isVN = 1, N''Xác nhận lưu thay đổi?'', N''Confirm saving changes?'');
    DECLARE @saved NVARCHAR(200) = IIF(@isVN = 1, N''Đã lưu thay đổi.'', N''Changes saved.'');

    DECLARE @titleJs NVARCHAR(400) = REPLACE(REPLACE(@title, N''\'', N''\\''), N''"'', N''\"'');
    DECLARE @subtitleJs NVARCHAR(600) = REPLACE(REPLACE(@subtitle, N''\'', N''\\''), N''"'', N''\"'');
    DECLARE @accountLabelJs NVARCHAR(400) = REPLACE(REPLACE(@accountLabel, N''\'', N''\\''), N''"'', N''\"'');
    DECLARE @menuTabJs NVARCHAR(200) = REPLACE(REPLACE(@menuTab, N''\'', N''\\''), N''"'', N''\"'');
    DECLARE @empTabJs NVARCHAR(200) = REPLACE(REPLACE(@empTab, N''\'', N''\\''), N''"'', N''\"'');
    DECLARE @reloadJs NVARCHAR(200) = REPLACE(REPLACE(@reload, N''\'', N''\\''), N''"'', N''\"'');
    DECLARE @saveJs NVARCHAR(200) = REPLACE(REPLACE(@save, N''\'', N''\\''), N''"'', N''\"'');
    DECLARE @searchJs NVARCHAR(300) = REPLACE(REPLACE(@search, N''\'', N''\\''), N''"'', N''\"'');
    DECLARE @emptyJs NVARCHAR(400) = REPLACE(REPLACE(@empty, N''\'', N''\\''), N''"'', N''\"'');
    DECLARE @invalidJs NVARCHAR(400) = REPLACE(REPLACE(@invalid, N''\'', N''\\''), N''"'', N''\"'');
    DECLARE @confirmJs NVARCHAR(400) = REPLACE(REPLACE(@confirm, N''\'', N''\\''), N''"'', N''\"'');
    DECLARE @savedJs NVARCHAR(400) = REPLACE(REPLACE(@saved, N''\'', N''\\''), N''"'', N''\"'');
    DECLARE @loginAccountJs NVARCHAR(300) = REPLACE(REPLACE(ISNULL(@LoginAccount, ''''), N''\'', N''\\''), N''"'', N''\"'');

    SELECT N''
<div id="scr699Root" class="scr699-page">
    <style>
        .scr699-page{font-family:var(--paradise-font-family-base);color:var(--paradise-text-body);padding:var(--paradise-space-5);}
        .scr699-shell{display:grid;grid-template-columns:minmax(280px,360px) 1fr;gap:var(--paradise-space-5);align-items:start;}
        .scr699-panel{min-height:calc(100vh - 190px);}
        .scr699-title{display:flex;gap:var(--paradise-space-3);align-items:flex-start;margin-bottom:var(--paradise-space-4);}
        .scr699-title-icon{width:44px;height:44px;border-radius:var(--paradise-border-radius-xl);display:inline-flex;align-items:center;justify-content:center;color:var(--paradise-color-primary);border:1px solid var(--paradise-border-color);box-shadow:var(--paradise-shadow-sm);}
        .scr699-page h2{font-size:1.35rem;margin:0 0 var(--paradise-space-1);font-weight:700;color:var(--paradise-text-heading,var(--paradise-text-body));}
        .scr699-muted{color:var(--paradise-text-muted);font-size:.92rem;line-height:1.5;}
        .scr699-field{display:flex;flex-direction:column;gap:var(--paradise-space-2);margin-bottom:var(--paradise-space-4);}
        .scr699-label{font-weight:600;font-size:.9rem;}
        .scr699-input,.scr699-search,.scr699-select{width:100%;border:1px solid var(--paradise-border-color);border-radius:var(--paradise-input-border-radius);padding:.72rem .9rem;color:var(--paradise-text-body);background-color:var(--paradise-bg-surface);outline:none;}
        .scr699-input:focus,.scr699-search:focus,.scr699-select:focus{border-color:var(--paradise-color-primary);box-shadow:0 0 0 3px var(--paradise-bg-primary-subtle);}
        .scr699-tabs{display:grid;grid-template-columns:1fr 1fr;gap:var(--paradise-space-2);margin:var(--paradise-space-4) 0;}
        .scr699-tab{border:1px solid var(--paradise-border-color);border-radius:var(--paradise-border-radius-pill);padding:.65rem .8rem;color:var(--paradise-text-body);background:transparent;cursor:pointer;font-weight:600;display:inline-flex;align-items:center;justify-content:center;gap:var(--paradise-space-2);}
        .scr699-tab.is-active{color:var(--paradise-color-primary);border-color:var(--paradise-color-primary);box-shadow:var(--paradise-shadow-sm);}
        .scr699-actions{display:flex;gap:var(--paradise-space-2);flex-wrap:wrap;margin-top:var(--paradise-space-4);}
        .scr699-stats{display:grid;grid-template-columns:repeat(3,1fr);gap:var(--paradise-space-3);margin-bottom:var(--paradise-space-4);}
        .scr699-stat{border:1px solid var(--paradise-border-color);border-radius:var(--paradise-border-radius-lg);padding:var(--paradise-space-3);}
        .scr699-stat strong{display:block;font-size:1.25rem;}
        .scr699-toolbar{display:flex;gap:var(--paradise-space-3);align-items:center;margin-bottom:var(--paradise-space-4);}
        .scr699-tree{max-height:calc(100vh - 310px);overflow:auto;padding-right:var(--paradise-space-2);}
        .scr699-node{border:1px solid var(--paradise-border-color);border-radius:var(--paradise-border-radius-lg);margin-bottom:var(--paradise-space-2);padding:var(--paradise-space-2);}
        .scr699-node-row{display:grid;grid-template-columns:auto 1fr minmax(160px,240px);gap:var(--paradise-space-2);align-items:center;}
        .scr699-toggle{border:0;background:transparent;color:var(--paradise-text-muted);cursor:pointer;width:28px;height:28px;border-radius:var(--paradise-border-radius-pill);}
        .scr699-toggle:hover{color:var(--paradise-color-primary);}
        .scr699-name{font-weight:600;line-height:1.35;}
        .scr699-children{margin-top:var(--paradise-space-2);padding-left:var(--paradise-space-4);display:none;}
        .scr699-node.is-open>.scr699-children{display:block;}
        .scr699-check{display:flex;align-items:center;gap:var(--paradise-space-2);cursor:pointer;font-weight:600;}
        .scr699-empty{border:1px dashed var(--paradise-border-color);border-radius:var(--paradise-border-radius-lg);padding:var(--paradise-space-6);text-align:center;color:var(--paradise-text-muted);}
        .scr699-hidden{display:none!important;}
        @media (max-width: 920px){.scr699-shell{grid-template-columns:1fr}.scr699-node-row{grid-template-columns:auto 1fr}.scr699-select{grid-column:2/3}.scr699-stats{grid-template-columns:1fr}}
    </style>

    <div class="scr699-shell">
        <aside class="paradise-card scr699-side">
            <div class="scr699-title">
                <span class="scr699-title-icon"><i class="bi bi-shield-check"></i></span>
                <div><h2 id="scr699Title"></h2><div class="scr699-muted" id="scr699Subtitle"></div></div>
            </div>
            <div class="scr699-field">
                <label class="scr699-label" for="scr699Login"></label>
                <input id="scr699Login" class="scr699-input" autocomplete="off" />
            </div>
            <div class="scr699-tabs">
                <button type="button" class="scr699-tab" data-mode="0"><i class="bi bi-list-check"></i><span></span></button>
                <button type="button" class="scr699-tab" data-mode="1"><i class="bi bi-diagram-3"></i><span></span></button>
            </div>
            <div class="scr699-actions">
                <button type="button" id="scr699Reload" class="paradise-btn paradise-btn--reload"><i class="bi bi-arrow-clockwise"></i><span></span></button>
                <button type="button" id="scr699Save" class="paradise-btn paradise-btn--save"><i class="bi bi-save"></i><span></span></button>
            </div>
        </aside>

        <main class="paradise-card scr699-panel">
            <div class="scr699-stats">
                <div class="scr699-stat"><span class="scr699-muted">Items</span><strong id="scr699Total">0</strong></div>
                <div class="scr699-stat"><span class="scr699-muted">Selected</span><strong id="scr699Selected">0</strong></div>
                <div class="scr699-stat"><span class="scr699-muted">Mode</span><strong id="scr699ModeLabel"></strong></div>
            </div>
            <div class="scr699-toolbar">
                <input id="scr699Search" class="scr699-search" />
            </div>
            <div id="scr699Tree" class="scr699-tree"><div class="scr699-empty" id="scr699Empty"></div></div>
        </main>
    </div>
</div>
<script>
(function(){
    var LOGIN_ID = '' + CAST(@LoginID AS NVARCHAR(20)) + N'';
    var LANGUAGE_ID = "'' + @LanguageID + N''";
    var mode = '' + CAST(ISNULL(@IsAcessEmp,0) AS NVARCHAR(2)) + N'';
    var texts = {title:"'' + @titleJs + N''",subtitle:"'' + @subtitleJs + N''",account:"'' + @accountLabelJs + N''",menu:"'' + @menuTabJs + N''",emp:"'' + @empTabJs + N''",reload:"'' + @reloadJs + N''",save:"'' + @saveJs + N''",search:"'' + @searchJs + N''",empty:"'' + @emptyJs + N''",invalid:"'' + @invalidJs + N''",confirm:"'' + @confirmJs + N''",saved:"'' + @savedJs + N''"};
    var state = {rows:[], tree:[]};
    var root = document.getElementById("scr699Root");
    var $ = window.jQuery;

    function byId(id){return document.getElementById(id);}
    function escapeHtml(v){if(v===null||v===undefined)return "";return String(v).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/\u0027/g,"&#039;");}
    function normalize(v){return String(v||"").normalize("NFD").replace(/[\u0300-\u036f]/g,"").toLowerCase();}
    function paramName(){return mode === 1 ? "Json_update_Emp" : "Json_update";}
    function apiName(){return mode === 1 ? "sp_decentralization_EmpData" : "sp_decentralization_MenuData";}
    function getLogin(){return byId("scr699Login").value.trim();}

    function initLabels(){
        byId("scr699Title").textContent = texts.title;
        byId("scr699Subtitle").textContent = texts.subtitle;
        root.querySelector("label[for=scr699Login]").textContent = texts.account;
        root.querySelector(".scr699-tab[data-mode=0] span").textContent = texts.menu;
        root.querySelector(".scr699-tab[data-mode=1] span").textContent = texts.emp;
        byId("scr699Reload").querySelector("span").textContent = texts.reload;
        byId("scr699Save").querySelector("span").textContent = texts.save;
        byId("scr699Search").placeholder = texts.search;
        byId("scr699Empty").textContent = texts.empty;
        byId("scr699Login").value = "'' + @loginAccountJs + N''";
        setMode(mode, false);
    }

    function setMode(nextMode, load){
        mode = Number(nextMode) === 1 ? 1 : 0;
        root.querySelectorAll(".scr699-tab").forEach(function(btn){btn.classList.toggle("is-active", Number(btn.dataset.mode) === mode);});
        byId("scr699ModeLabel").textContent = mode === 1 ? texts.emp : texts.menu;
        if(load) loadData();
    }

    function buildTree(rows){
        var map = {}, roots = [];
        rows.forEach(function(r){
            var id = mode === 1 ? String(r.ObjectID) : String(r.ObjectID);
            r._id = id;
            r._children = [];
            map[id] = r;
        });
        rows.forEach(function(r){
            var pid = mode === 1 ? String(r.ParentObjectID||"") : String(r.ParentObjectID||r.ObjectID);
            if(pid && pid !== r._id && map[pid]) map[pid]._children.push(r); else roots.push(r);
        });
        roots.sort(sortNode); rows.forEach(function(r){r._children.sort(sortNode);});
        return roots;
    }
    function sortNode(a,b){return (Number(a.Prio||0)-Number(b.Prio||0)) || String(a.Description||"").localeCompare(String(b.Description||""));}

    function render(){
        var tree = byId("scr699Tree");
        byId("scr699Total").textContent = state.rows.length;
        if(!state.rows.length){tree.innerHTML = "<div class=\"scr699-empty\">" + texts.empty + "</div>"; updateSelected(); return;}
        tree.innerHTML = state.tree.map(renderNode).join("");
        updateSelected();
    }

    function renderNode(n){
        var hasChild = n._children && n._children.length;
        var name = escapeHtml(n.Description || n.ObjectName || n.ObjectID);
        var control = mode === 1 ? renderCheckbox(n) : renderSelect(n);
        return "<div class=\"scr699-node" + (hasChild ? " is-open" : "") + "\" data-text=\"" + escapeHtml(normalize(name)) + "\" data-id=\"" + escapeHtml(n._id) + "\">"
            + "<div class=\"scr699-node-row\">"
            + "<button type=\"button\" class=\"scr699-toggle\">" + (hasChild ? "<i class=\"bi bi-chevron-down\"></i>" : "") + "</button>"
            + "<div class=\"scr699-name\">" + name + "</div>" + control + "</div>"
            + (hasChild ? "<div class=\"scr699-children\">" + n._children.map(renderNode).join("") + "</div>" : "")
            + "</div>";
    }
    function renderSelect(n){
        var rights = String(n.FullAccess||"").split("&");
        var opts = [{id:"0",name:"Denied"},{id:"1",name:"Read"},{id:"8",name:"Follow group"},{id:"32",name:"Full"}];
        return "<select multiple class=\"scr699-select\" id=\"select_access_" + escapeHtml(n.ObjectID) + "\">" + opts.map(function(o){return "<option value=\""+o.id+"\""+(rights.indexOf(o.id)>=0?" selected":"") + ">"+o.name+"</option>";}).join("") + "</select>";
    }
    function renderCheckbox(n){
        return "<label class=\"scr699-check\"><input type=\"checkbox\" id=\"IsFull_" + escapeHtml(n.ObjectID) + "\" " + (Number(n.ViewInfo)===1 ? "checked" : "") + "> <span>View</span></label>";
    }

    function loadData(){
        var login = getLogin();
        if(!login){state.rows=[];state.tree=[];render();return;}
        byId("scr699Tree").innerHTML = "<div class=\"scr699-empty\"><i class=\"bi bi-hourglass-split\"></i> Loading...</div>";
        AjaxHPAParadise({data:{name:apiName(),param:["LoginID",LOGIN_ID,"LanguageID",LANGUAGE_ID,"LoginAccount",login]},success:function(res){
            var json = typeof res === "string" ? JSON.parse(res) : res;
            var row = json && json.data && json.data[0] && json.data[0][0];
            if(!row || !row.IsValid){state.rows=[];state.tree=[];byId("scr699Tree").innerHTML = "<div class=\"scr699-empty\">"+texts.invalid+"</div>";updateSelected();return;}
            state.rows = row.JsonData ? JSON.parse(row.JsonData) : [];
            state.tree = buildTree(state.rows);
            render();
        }});
    }

    function saveData(){
        if(!getLogin()){return;}
        if(!window.confirm(texts.confirm)){return;}
        var payload = {};
        if(mode === 1){
            root.querySelectorAll("input[type=checkbox][id^=IsFull_]").forEach(function(el){payload[el.id]=el.checked?1:0;});
        } else {
            root.querySelectorAll("select[id^=select_access_]").forEach(function(el){payload[el.id]=Array.from(el.selectedOptions).map(function(o){return o.value;}).join("&");});
        }
        var params = ["LoginID",LOGIN_ID,"LoginAccount",getLogin(),paramName(),JSON.stringify(payload)];
        AjaxHPAParadise({data:{name:"sp_decentralization_update",param:params},success:function(){alert(texts.saved);loadData();}});
    }

    function updateSelected(){
        var count = mode === 1 ? root.querySelectorAll("input[type=checkbox][id^=IsFull_]:checked").length : Array.from(root.querySelectorAll("select[id^=select_access_] option:checked")).length;
        byId("scr699Selected").textContent = count;
    }
    function filterTree(){
        var q = normalize(byId("scr699Search").value);
        root.querySelectorAll(".scr699-node").forEach(function(n){
            var match = !q || n.dataset.text.indexOf(q) >= 0 || Array.from(n.querySelectorAll(".scr699-node")).some(function(c){return c.dataset.text.indexOf(q)>=0;});
            n.classList.toggle("scr699-hidden", !match);
            if(q && match) n.classList.add("is-open");
        });
    }

    root.addEventListener("click", function(e){
        var tab = e.target.closest(".scr699-tab"); if(tab){setMode(tab.dataset.mode, true);return;}
        if(e.target.closest("#scr699Reload")){loadData();return;}
        if(e.target.closest("#scr699Save")){saveData();return;}
        var toggle = e.target.closest(".scr699-toggle"); if(toggle){var node=toggle.closest(".scr699-node"); if(node) node.classList.toggle("is-open");}
    });
    root.addEventListener("change", updateSelected);
    byId("scr699Search").addEventListener("input", filterTree);
    byId("scr699Login").addEventListener("keydown", function(e){if(e.key === "Enter") loadData();});
    initLabels();
    if(getLogin()) loadData();
    if(typeof HideLoadingByClassOrID === "function") HideLoadingByClassOrID("#sp_decentralization");
})();
</script>'' AS col1;
END
');

    -------------------------------------------------------------------------
    -- 4) Đảm bảo metadata hiện tại vẫn đúng cho HTML-rendered/DataSetting
    -------------------------------------------------------------------------
    UPDATE dbo.tblDataSetting
       SET IsProcedure = 1,
           IsShowLayout = 1,
           ColumnDataType = 'col1&ViewHtml',
           ColumnOrderBy = 'col1&0'
     WHERE TableName = 'sp_decentralization';

    IF NOT EXISTS (SELECT 1 FROM dbo.tblDataSettingLayout WHERE TableName = 'sp_decentralization' AND Name = 'root')
    BEGIN
        INSERT INTO dbo.tblDataSettingLayout(TableName, Name, ControlName, NamePa, Type, TypeLayout, WidthPercentage)
        VALUES ('sp_decentralization', 'root', '', '', 'g', '6', 100);
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.tblDataSettingLayout WHERE TableName = 'sp_decentralization' AND ControlName = 'col1')
    BEGIN
        INSERT INTO dbo.tblDataSettingLayout(TableName, Name, ControlName, NamePa, Type, TypeLayout, ControlType, WidthPercentage)
        VALUES ('sp_decentralization', 'lblcol1', 'col1', 'root', 'i', '6', 'ParadiseWebView2', 100);
    END;

    IF OBJECT_ID('dbo.sp_Men_Menu_AfterSave_Simple', 'P') IS NOT NULL
        EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_decentralization';

    COMMIT TRANSACTION;
    PRINT 'Modernized MnuSCR699 / sp_decentralization successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
