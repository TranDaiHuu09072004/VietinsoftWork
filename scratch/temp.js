
(function(){
    var LOGIN_ID = 3;
    var LANGUAGE_ID = "VN";
    var mode = 0;
    var texts = {title:"Phân quyền truy cập",subtitle:"Tìm tài khoản, chọn nhóm quyền hoặc phạm vi dữ liệu, sau đó lưu thay đổi.",account:"Tên/nhóm đăng nhập",menu:"Chức năng",emp:"Dữ liệu",reload:"Xem",save:"Lưu",search:"Tìm nhanh quyền, menu, phòng ban...",empty:"Nhập tên truy cập rồi bấm Xem.",invalid:"Không tìm thấy tên truy cập / tên nhóm.",confirm:"Xác nhận lưu thay đổi?",saved:"Đã lưu thay đổi."};
    var state = {rows:[], tree:[]};
    var root = document.getElementById("scr699Root");
    var $ = window.jQuery;

    function getDataSource(callback){
        if (window.DataSource_scr699Select && window.DataSource_scr699Select.length) {
            callback(window.DataSource_scr699Select);
            return;
        }
        if (typeof AjaxHPAParadise === "function") {
            AjaxHPAParadise({
                data: {
                    name: "sp_decentralization_SelectOptions",
                    param: ["LoginID", LOGIN_ID, "LanguageID", LANGUAGE_ID]
                },
                success: function(res) {
                    var json = typeof res === "string" ? JSON.parse(res) : res;
                    window.DataSource_scr699Select = (json && json.data && json.data[0]) || [];
                    callback(window.DataSource_scr699Select);
                },
                error: function() {
                    callback([]);
                }
            });
        } else {
            callback([]);
        }
    }

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
        byId("scr699Login").value = "cuong.vu";
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
            var id = String(r.ObjectID);
            r._id = id;
            r._children = [];
            map[id] = r;
        });
        rows.forEach(function(r){
            var pid = mode === 1 ? String(r.ParentObjectID||"") : String(r.ParentObjectID||r.ObjectID);
            if(pid && pid !== r._id && map[pid]) map[pid]._children.push(r); else roots.push(r);
        });
        roots.sort(sortNode); roots.forEach(function(r){r._children.sort(sortNode);});
        return roots;
    }
    function sortNode(a,b){return (Number(a.Prio||0)-Number(b.Prio||0)) || String(a.Description||"").localeCompare(String(b.Description||""));}

    function render(){
        var tree = byId("scr699Tree");
        byId("scr699Total").textContent = state.rows.length;
        if(!state.rows.length){tree.innerHTML = "<div class=\"scr699-empty\">" + texts.empty + "</div>"; updateSelected(); return;}
        tree.innerHTML = state.tree.map(renderNode).join("");
        initializeNodeControls();
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
    
    // Trả về container cho TagBox khởi tạo động
    function renderSelect(n){
        return "<div class=\"scr699-select-container\" id=\"select_container_" + escapeHtml(n.ObjectID) + "\" data-value=\"" + escapeHtml(n.FullAccess || "") + "\"></div>";
    }
    
    function renderCheckbox(n){
        return "<label class=\"scr699-check\"><input type=\"checkbox\" id=\"IsFull_" + escapeHtml(n.ObjectID) + "\" " + (Number(n.ViewInfo)===1 ? "checked" : "") + "> <span>View</span></label>";
    }

    // Khởi tạo các TagBox của DevExpress cho từng node
    function initializeNodeControls() {
        getDataSource(function(ds) {
            document.querySelectorAll(".scr699-select-container").forEach(function(el) {
                var id = el.id.replace("select_container_", "");
                var val = el.dataset.value;
                var selectedVals = val ? val.split("&").map(function(s){return s.trim();}).filter(function(s){return s !== "";}) : [];
                
                $(el).dxTagBox({
                    dataSource: ds || [],
                    valueExpr: "ID",
                    displayExpr: "Name",
                    value: selectedVals,
                    width: "100%",
                    placeholder: "...",
                    showSelectionControls: true,
                    applyValueMode: "useButtons",
                    onValueChanged: function(e) {
                        updateSelected();
                    }
                });
            });
        });
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
        
        var confirmDialog = DevExpress.ui.dialog.custom({
            title: texts.title,
            messageHtml: "<div style=\"width: 300px; font-size: 14px; padding: 10px 0;\">" + texts.confirm + "</div>",
            buttons: [
                {
                    text: LANGUAGE_ID === "VN" ? "Đồng ý" : "Yes",
                    onClick: function() { return true; }
                },
                {
                    text: LANGUAGE_ID === "VN" ? "Hủy" : "Cancel",
                    onClick: function() { return false; }
                }
            ]
        });
        
        confirmDialog.show().done(function(dialogResult) {
            if (!dialogResult) return;
            
            var payload = {};
            if(mode === 1){
                root.querySelectorAll("input[type=checkbox][id^=IsFull_]").forEach(function(el){payload[el.id]=el.checked?1:0;});
            } else {
                // Lấy dữ liệu từ các DevExpress TagBox instances
                document.querySelectorAll(".scr699-select-container").forEach(function(el) {
                    var id = el.id.replace("select_container_", "");
                    var instance = $(el).dxTagBox("instance");
                    if (instance) {
                        var val = instance.option("value");
                        payload["select_access_" + id] = Array.isArray(val) ? val.join("&") : (val || "0");
                    }
                });
            }
            var params = ["LoginID",LOGIN_ID,"LoginAccount",getLogin(),paramName(),JSON.stringify(payload)];
            AjaxHPAParadise({
                data:{name:"sp_decentralization_update",param:params},
                success:function(){
                    if (typeof showPopupNotify === "function") {
                        showPopupNotify(texts.title, texts.saved, "OK", "300px");
                    } else {
                        DevExpress.ui.dialog.custom({
                            title: texts.title,
                            messageHtml: "<div style=\"width: 300px; font-size: 14px; padding: 10px 0;\">" + texts.saved + "</div>",
                            buttons: [{ text: "OK", onClick: function() { return true; } }]
                        }).show();
                    }
                    loadData();
                }
            });
        });
    }

    function updateSelected(){
        var count = 0;
        if(mode === 1){
            count = root.querySelectorAll("input[type=checkbox][id^=IsFull_]:checked").length;
        } else {
            document.querySelectorAll(".scr699-select-container").forEach(function(el) {
                var instance = $(el).dxTagBox("instance");
                if (instance) {
                    var val = instance.option("value");
                    if (Array.isArray(val)) {
                        // Chỉ đếm các quyền khác "0" (Từ chối)
                        var activeRights = val.filter(function(v){return v !== "0";});
                        count += activeRights.length;
                    }
                }
            });
        }
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
