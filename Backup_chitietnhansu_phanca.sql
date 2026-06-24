USE Paradise_ITL
GO
if object_id('[dbo].[sp_TAD_EmployeeScheduleDetail_html]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_TAD_EmployeeScheduleDetail_html] as select 1')
GO

-- ==============================================================================
-- 3. HTML RENDERER
-- ==============================================================================
ALTER PROCEDURE [dbo].[sp_TAD_EmployeeScheduleDetail_html]
    @LoginID INT = NULL,
    @LanguageID VARCHAR(5) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET @LanguageID = ISNULL(NULLIF(@LanguageID, ''), 'VN');

    DECLARE @html NVARCHAR(MAX) = N'';
    SET @html = @html + N'<style>
:root{--tad-brand:#03412C;--tad-green:#22c55e;--tad-soft:#eaf7f0;--tad-bg:#f4f7f5;--tad-surface:#fff;--tad-surface2:#f8fbf9;--tad-border:#d8e4de;--tad-text:#132019;--tad-muted:#6d7b73;--tad-shadow:0 18px 45px rgba(3,65,44,.10)}
body.dark,body.dark-mode,.dark-mode,.theme-dark,.dx-theme-generic-dark,[data-bs-theme="dark"]{--tad-bg:#12191a;--tad-surface:#1b2425;--tad-surface2:#202b2b;--tad-border:#334344;--tad-text:#f4faf6;--tad-muted:#9eaca5;--tad-soft:rgba(34,197,94,.12);--tad-shadow:0 22px 60px rgba(0,0,0,.35)}
.tad-esd-page{min-height:calc(100vh - 116px);background:var(--tad-bg);color:var(--tad-text);font:14px/1.45 "Segoe UI",Arial,sans-serif;padding:0 18px 18px;box-sizing:border-box}
.tad-hero{background:var(--tad-brand);border-radius:0 0 24px 24px;color:#fff;padding:22px 24px 66px;display:flex;justify-content:space-between;align-items:flex-start;gap:18px;box-shadow:var(--tad-shadow)}
.tad-person{display:flex;gap:16px;align-items:center}.tad-avatar{width:82px;height:82px;border-radius:50%;background:#fff;border:3px solid rgba(255,255,255,.65);object-fit:cover}.tad-name{font-size:26px;font-weight:900;margin:0 0 3px;color:#f4fff8;text-shadow:0 1px 10px rgba(0,0,0,.22)}.tad-sub{opacity:.96;color:#f4fff8}.tad-badges{display:flex;gap:8px;flex-wrap:wrap;margin-top:10px}.tad-badge{border:1px solid rgba(255,255,255,.55);background:rgba(255,255,255,.18);color:#fff;border-radius:999px;padding:5px 11px;font-size:12px;font-weight:800}.tad-close{background:rgba(255,255,255,.15);color:#fff;border:1px solid rgba(255,255,255,.35);border-radius:12px;padding:9px 15px;font-weight:800;cursor:pointer}
.tad-profile-card{margin:-44px 20px 0;background:var(--tad-surface);border:1px solid var(--tad-border);border-radius:18px;box-shadow:var(--tad-shadow);padding:18px}.tad-title{color:var(--tad-green);font-size:20px;font-weight:900;margin:0 0 14px}.tad-info-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:16px}.tad-field{border-bottom:1px solid var(--tad-border);padding-bottom:10px}.tad-field label{display:block;color:var(--tad-muted);font-size:12px;font-weight:800;margin-bottom:4px}.tad-field b{font-size:14px;color:var(--tad-text)}.tad-field.hidden{display:none}.tad-edit-control{width:100%;box-sizing:border-box;background:var(--tad-surface2);color:var(--tad-text);border:1px solid var(--tad-border);border-radius:10px;padding:8px 10px;font-weight:800}
.tad-tabs{margin:18px 20px 0;background:var(--tad-surface);border:1px solid var(--tad-border);border-radius:18px;box-shadow:var(--tad-shadow);overflow:hidden}.tad-tabbar{display:flex;gap:4px;border-bottom:1px solid var(--tad-border);padding:0 14px}.tad-tab{border:0;background:transparent;color:var(--tad-muted);padding:14px 12px;font-weight:900;cursor:pointer;border-bottom:2px solid transparent}.tad-tab.active{color:var(--tad-green);border-bottom-color:var(--tad-green)}.tad-panel{display:none;padding:18px}.tad-panel.active{display:block}
.tad-cal-head{display:flex;justify-content:space-between;align-items:center;margin-bottom:14px;gap:10px}.tad-cal-tools{display:flex;align-items:center;gap:10px;flex-wrap:wrap}.tad-auto-btn{background:linear-gradient(135deg,#16a34a,#4ade80);border-color:#22c55e;color:#fff;box-shadow:0 10px 26px rgba(34,197,94,.34);text-shadow:0 1px 0 rgba(0,0,0,.18)}.tad-auto-btn:hover{filter:brightness(1.08);transform:translateY(-1px);box-shadow:0 12px 30px rgba(34,197,94,.42)}.tad-seg{display:flex;border:1px sol';
    SET @html = @html + N'id var(--tad-border);border-radius:999px;padding:3px;background:var(--tad-surface2)}.tad-seg button{border:0;background:transparent;color:var(--tad-muted);border-radius:999px;padding:8px 14px;font-weight:900;cursor:pointer}.tad-seg button.active{background:var(--tad-green);color:#fff;box-shadow:0 8px 18px rgba(34,197,94,.25)}
.tad-calendar{border:1px solid var(--tad-border);border-radius:18px;overflow-x:auto;background:var(--tad-surface)}.tad-calendar-inner{min-width:700px}.tad-weekdays,.tad-days{display:grid;grid-template-columns:repeat(7,1fr)}.tad-weekdays div{background:var(--tad-surface2);border-right:1px solid var(--tad-border);border-bottom:1px solid var(--tad-border);padding:10px;text-align:center;color:var(--tad-muted);font-weight:900}.tad-day{min-height:104px;border-right:1px solid var(--tad-border);border-bottom:1px solid var(--tad-border);padding:10px;background:var(--tad-surface);cursor:pointer;transition:.15s}.tad-day.large{min-height:180px}.tad-day:nth-child(7n){border-right:0}.tad-day:hover{background:var(--tad-soft)}.tad-day.empty{background:var(--tad-surface2);cursor:default}.tad-num{font-weight:900;margin-bottom:8px;color:var(--tad-text)}.tad-event{border-left:4px solid var(--tad-green);background:linear-gradient(90deg,var(--tad-soft),rgba(34,197,94,.04));border-radius:8px;padding:7px 8px;min-height:50px}.tad-shift{font-weight:900;color:var(--tad-brand)}.dark-mode .tad-shift{color:#fff}.tad-time,.tad-line{font-size:11px;color:var(--tad-muted);font-weight:700}
.tad-modal-backdrop{position:fixed;inset:0;background:rgba(0,0,0,.45);display:none;align-items:center;justify-content:center;z-index:1000;padding:18px}.tad-modal{width:min(520px,100%);background:var(--tad-surface);color:var(--tad-text);border:1px solid var(--tad-border);border-radius:20px;box-shadow:0 30px 90px rgba(0,0,0,.35);overflow:hidden;max-height:100%;overflow-y:auto}.tad-modal-head{background:var(--tad-brand);color:#fff;padding:18px 20px;display:flex;justify-content:space-between;gap:12px}.tad-modal-head h3,.tad-modal-head #popupDateText{color:#fff;margin:0}.tad-modal-head h3{font-size:18px}.tad-x{border:0;background:rgba(255,255,255,.16);color:#fff;border-radius:10px;width:36px;height:36px;cursor:pointer}.tad-modal-body{padding:18px;display:grid;gap:13px}.tad-input-row label{display:block;font-size:12px;font-weight:900;color:var(--tad-muted);margin-bottom:6px}.tad-native-input{width:100%;box-sizing:border-box;background:var(--tad-surface2);color:var(--tad-text);border:1px solid var(--tad-border);border-radius:12px;padding:10px 12px;min-height:40px}.tad-modal-actions{display:flex;justify-content:flex-end;gap:10px;padding:14px 18px 18px}.tad-btn{border:1px solid var(--tad-border);background:var(--tad-surface);color:var(--tad-text);border-radius:12px;padding:10px 14px;font-weight:900;cursor:pointer}.tad-btn.primary{background:var(--tad-brand);border-color:var(--tad-brand);color:#fff}.tad-btn.primary.tad-auto-btn{background:linear-gradient(135deg,#16a34a,#4ade80);border-color:#22c55e;color:#fff;box-shadow:0 10px 26px rgba(34,197,94,.38);text-shadow:0 1px 0 rgba(0,0,0,.18)}
.tad-timeline{position:relative;display:flex;flex-direction:column;gap:0;border-radius:12px;backgrou';
    SET @html = @html + N'nd:var(--tad-surface);border:1px solid var(--tad-border);padding:20px 24px;min-height:130px;overflow:hidden}.tad-timeline:before{content:"";position:absolute;left:29px;top:64px;bottom:28px;width:1px;background:linear-gradient(180deg,rgba(34,197,94,.72),rgba(34,197,94,.08))}.tad-timeline-title{color:var(--tad-text);font-size:16px;font-weight:900;margin:0 0 18px}.tad-timeline-item{position:relative;display:flex;gap:12px;align-items:flex-start;padding:0 0 14px 0;animation:tadHistoryIn .36s ease both}.tad-timeline-item:last-child{padding-bottom:0}.tad-timeline-dot{position:relative;z-index:1;flex:0 0 10px;width:10px;height:10px;border-radius:999px;background:#22c55e;margin-top:5px;box-shadow:0 0 0 6px rgba(34,197,94,.14),0 0 16px rgba(34,197,94,.55);animation:tadPulse 1.9s ease-in-out infinite}.tad-timeline-content{min-width:0;padding-top:0}.tad-timeline-main{display:flex;align-items:baseline;gap:6px;flex-wrap:wrap}.tad-timeline-date,.tad-timeline-status{font-weight:900;color:var(--tad-text)}.tad-timeline-note{color:var(--tad-muted);font-size:13px;line-height:1.35;margin-top:2px}@keyframes tadHistoryIn{from{opacity:0;transform:translateY(8px)}to{opacity:1;transform:translateY(0)}}@keyframes tadPulse{0%,100%{box-shadow:0 0 0 6px rgba(34,197,94,.14),0 0 16px rgba(34,197,94,.55)}50%{box-shadow:0 0 0 9px rgba(34,197,94,.06),0 0 22px rgba(34,197,94,.75)}}
.tad-cert-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:16px}.tad-cert-card{background:var(--tad-surface2);border:1px solid var(--tad-border);border-radius:12px;padding:16px}.tad-cert-title{font-size:14px;font-weight:800;color:var(--tad-text);margin:0 0 10px}.tad-cert-desc{font-size:12px;color:var(--tad-muted);margin:0}.tad-empty{color:var(--tad-muted);font-weight:700;padding:16px;border:1px dashed var(--tad-border);border-radius:12px;background:var(--tad-surface2)}.tad-day-head{display:flex;align-items:center;gap:6px;flex-wrap:wrap;margin-bottom:8px}.tad-day-status{font-size:10px;line-height:1;border-radius:999px;background:var(--tad-soft);color:var(--tad-brand);border:1px solid rgba(34,197,94,.18);font-weight:900;padding:3px 6px}.tad-day.training-past{cursor:default}.tad-day.training-past:hover{background:var(--tad-surface)}.tad-day.training-past .tad-event{opacity:.58;filter:saturate(.72)}.tad-day.training-past .tad-day-status{opacity:.72}.tad-auto-btn:disabled{opacity:.48;cursor:not-allowed;filter:saturate(.65);box-shadow:none;transform:none}.tad-btn.danger{color:#b91c1c;border-color:rgba(220,38,38,.34);background:rgba(220,38,38,.06)}.tad-btn.danger:hover{background:rgba(220,38,38,.12);border-color:rgba(220,38,38,.55);color:#991b1b}.dark-mode .tad-btn.danger,[data-bs-theme="dark"] .tad-btn.danger{color:#fca5a5;background:rgba(220,38,38,.10);border-color:rgba(248,113,113,.32)}.dark-mode .tad-btn.danger:hover,[data-bs-theme="dark"] .tad-btn.danger:hover{background:rgba(220,38,38,.20);color:#fecaca}.tad-modal-actions{align-items:center}.tad-modal-actions .spacer{flex:1}
/* --- BỔ SUNG DARK MODE OVERRIDES --- */
.dark-mode .tad-day-status,
[data-bs-theme="dark"] .tad-day-status {
  background: rgba(34,197,94,0.15) !important;
  color: #4ade80 !important;
  border-color: rgba(34,197,94,0.3) !important;
}

@media(max-width:1024px){
  .tad-info-grid{grid-template-columns:repeat(2,1fr)}
  .tad-cert-grid{grid-template-columns:repeat(2,1fr)}
}
@media(max-width:768px){
  .tad-hero{flex-direction:column;padding:16px 16px 50px}
  .tad-info-grid{grid-template-columns:1fr}
  .tad-cert-grid{grid-template-columns:1fr}
  .tad-tabbar{overflow-x:auto;white-space:nowrap;padding-bottom:5px;}
  .tad-cal-head{flex-direction:column;align-items:flex-start}.tad-cal-tools{width:100%;justify-content:space-between}
  .tad-calendar-inner{min-width:650px}
}
</style>

<div class="tad-esd-page">
  <div class="tad-hero">
    <div class="tad-person"><img id="tadEsdAvatar" class="tad-avatar" alt="Avatar" src="data:image/svg+xml;utf8,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%22-4 -4 32 32%22 fill=%22%2303412C%22><path d=%22M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z%22/></svg>"><div><h2 id="tadEsdName" class="tad-name">--</h2><div id="tadEsdTitle" class="tad-sub">--</div><div class="tad-badges"><span id="tadEsdCode" class="tad-badge">--</span><span id="tadEsdDept" class="tad-badge">--</span><span id="tadEsdLevel" class="tad-badge">--</span></div></div></div>
    <button id="tadEsdCloseBtn" class="tad-close" type="button">Đóng</button>
  </div>
  <div class="tad-profile-card"><h3 class="tad-title">Thông tin hồ sơ</h3><div class="tad-info-grid">
    <div class="tad-field"><label>Họ và tên</label><b id="fFullName">--</b></div>
    <div class="tad-field"><label>Chức danh</label><b id="fPosition">--</b></div>
    <div class="tad-field"><label>Phòng ban</label><b id="fDept">--</b></div>
    <div class="tad-field"><label>Trạng thái đào tạo</label><select id="trainingStatusSelect" class="tad-edit-control"></select></div>
    <div class="tad-field"><label>Level</label><select id="levelSelect" class="tad-edit-control"></select></div>
    <div class="tad-field"><label>PIC chấm công</label><b id="fPic">--</b></div>
    <div id="trainerField" class="tad-field hidden"><label>Dedicated Trainer</label><b id="fTrainer">--</b></div>
    <div id="leaderField" class="tad-field hidden"><label>Team Leader</label><b id="fLeader">--</b></div>
    <div id="hireDateField" class="tad-field"><label>Ngày vào làm</label><b id="fHireDate">--</b></div>
  </div></div>
  <div class="tad-tabs"><div class="tad-tabbar"><button class="tad-tab active" data-tab="schedule">Lịch làm việc & phân ca</button><b';
    SET @html = @html + N'utton class="tad-tab" data-tab="cert">Chứng chỉ / Kỹ năng</button><button class="tad-tab" data-tab="history">Lịch sử trạng thái</button></div>
    <div id="tab-schedule" class="tad-panel active"><div class="tad-cal-head"><h3 class="tad-title" id="calendarTitle">Lịch tháng</h3><div class="tad-cal-tools"><button id="btnAutoSchedule" class="tad-btn primary tad-auto-btn" type="button">Tạo lịch tự động</button><div class="tad-seg"><button class="active" data-filter="ThisWeek">Tuần này</button><button data-filter="ThisMonth">Tháng này</button></div></div></div><div class="tad-calendar"><div class="tad-calendar-inner"><div class="tad-weekdays"><div>T2</div><div>T3</div><div>T4</div><div>T5</div><div>T6</div><div>T7</div><div>CN</div></div><div id="calendarDays" class="tad-days"></div></div></div></div>
    <div id="tab-cert" class="tad-panel"><div class="tad-cert-grid" id="certGrid"></div></div>
    <div id="tab-history" class="tad-panel"><div id="historyGrid" class="tad-timeline"></div></div>
  </div>
</div>
<div id="shiftPopup" class="tad-modal-backdrop"><div class="tad-modal"><div class="tad-modal-head"><div><h3 id="shiftPopupTitle">Sửa ca làm việc</h3><div id="popupDateText"></div></div><button id="closeShiftPopup" class="tad-x" type="button">x</button></div><div class="tad-modal-body"><div class="tad-input-row"><label>Ca làm việc</label><select id="editShift" class="tad-native-input"></select></div><div class="tad-input-row"><label>Trạng thái đào tạo</label><select id="editTrainingStatus" class="tad-native-input"></select></div><div class="tad-input-row"><label>Giờ bắt đầu</label><input id="editStart" class="tad-native-input" type="text" placeholder="HH:mm" readonly></div><div class="tad-input-row"><label>Giờ kết thúc</label><input id="editEnd" class="tad-native-input" type="text" placeholder="HH:mm" readonly></div></div><div class="tad-modal-actions"><button id="deleteShift" class="tad-btn danger" type="button">Xóa ca</button><span class="spacer"></span><button id="cancelShift" class="tad-btn" type="button">Hủy</button><button id="saveShift" class="tad-btn primary" type="button">Lưu phân ca</button></div></div></div>

<script>
(function(){
var routeParam=window.sp_TAD_EmployeeScheduleDetail_param||window.MnuTAD3364_param||{};
var empId=routeParam.EmployeeID||routeParam.employeeID||routeParam.id||null;
var scheduleRows=[];
var selectedDay=null;
var filterType="ThisWeek";
var LoginID=window.LoginID||routeParam.LoginID||0;
var LanguageID=window.LanguageID||routeParam.LanguageID||"VN";
var shiftOptions=[];
var statusOptions=[];
var levelOptions=[];
var suppressProfileSave=false;
var currentPhaseCompletedDays=0;
var currentPhaseRequiredDays=0;
var firstTrainingDate="";
var employeeHireDate="";
var popupShiftTouched=false;
var employeeProfileLoaded=false;

function parseResponse(res){try{return typeof res==="string"?JSON.parse(res):res}catch(e){return {}}}
function rowsOf(res){var j=parseResponse(res);return (j&&j.data&&j.data[0])||[]}
function oneOf(res){var rows=rowsOf(res);return rows&&rows[0]?rows[0]:null}
function showAlert(type,msg){if(window.uiManager&&uiManager.showAlert)uiManager.showAlert({type:type,message:msg});else console.warn(msg)}
function closeForm(){if(typeof window.CloseCurrentForm==="function")window.CloseCurrentForm();else history.back()}
function pad(n){return n<10?"0"+n:n}
function fmt(d){var x=new Date(d);return x.getFullYear()+"-"+pad(x.getMonth()+1)+"-"+pad(x.getDate())}
function viDate(d){var x=new Date(d);return pad(x.getDate())+"/"+pad(x.getMonth()+1)+"/"+x.getFullYear()}
function html(v){if(v===null||v===undefined)retur';
    SET @html = @html + N'n "";return String(v).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").split(String.fromCharCode(39)).join("&#39;")}
function normalizeTime(v){
    v=(v||"").toString().trim();if(!v)return "";
    var m=v.match(/^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?$/i);
    if(m){var h=parseInt(m[1],10),min=m[2],ampm=(m[3]||"").toUpperCase();if(ampm==="PM"&&h<12)h+=12;if(ampm==="AM"&&h===12)h=0;return pad(h)+":"+min}
    return v.length>=5?v.substring(0,5):v;
}
function getShiftId(item){return item.ID!==undefined?item.ID:item.ShiftID}
function getShiftName(item){return item.Name||item.ShiftName||String(getShiftId(item))}
function getShift(id){for(var i=0;i<shiftOptions.length;i++){if(String(getShiftId(shiftOptions[i]))===String(id))return shiftOptions[i]}return null}
function getShiftByGroup(group){for(var i=0;i<shiftOptions.length;i++){if(String(shiftOptions[i].ShiftGroup||"").toLowerCase()===String(group||"").toLowerCase())return shiftOptions[i]}return null}
function isPriorityStatus(statusId){var s=getStatus(statusId);var name=String((s&&(s.StatusName||s.Name))||"").toUpperCase();return name.indexOf("FBT")>=0||name.indexOf("SHTP")>=0}
function getStatus(statusId){for(var i=0;i<statusOptions.length;i++){if(String(statusOptions[i].ID||statusOptions[i].StatusID)===String(statusId))return statusOptions[i]}return null}
function getStatusName(statusId){var s=getStatus(statusId);return s?(s.Name||s.StatusName||"giai đoạn đào tạo hiện tại"):"giai đoạn đào tạo hiện tại"}
function getFBTStatus(){for(var i=0;i<statusOptions.length;i++){var n=String(statusOptions[i].StatusName||statusOptions[i].Name||"").toUpperCase();if(n.indexOf("FBT")>=0)return statusOptions[i]}return statusOptions[0]||null}
function getDefaultStatusId(){var s=getFBTStatus();return s?String(s.ID||s.StatusID):""}
function isHCShift(item){return item&&String(item.ShiftGroup||"").toUpperCase()==="HC"}
function getHCShift(){for(var i=0;i<shiftOptions.length;i++){if(isHCShift(shiftOptions[i]))return shiftOptions[i]}return null}
function getRowByDate(dateStr){for(var i=0;i<scheduleRows.length;i++){if(fmt(scheduleRows[i].ScheduleDate)===dateStr)return scheduleRows[i]}return null}
function api(name,param,ok,err){AjaxHPAParadise({data:{name:name,param:param||[]},success:function(res){if(ok)ok(res)},error:function(){if(err)err();else showAlert("error","Không tải được dữ liệu")}})}
function confirmAction(message,onYes){
    if(typeof window.showConfirmPopup==="function"){
        try{window.showConfirmPopup({title:"Xác nhận",Title:"Xác nhận",message:message,Message:message,YesText:"Có",NoText:"Hủy",onYes:onYes});return}catch(e){}
    }
    if(window.confirm(message))onYes();
}
function showSkeleton(){
    var root=$(".tad-esd-page");if(!root.length||$("#tadOverlay").length)return;
    root.css("position","relative").append("<div id=\"tadOverlay\" style=\"position:absolute;inset:0;background:rgba(18,25,26,.72);z-index:9999;display:flex;align-items:center;justify-content:center;font-size:16px;font-weight:900;color:#22c55e;flex-direction:column;border-radius:0;\"><div style=\"margin-bottom:15px;width:44px;height:44px;border:4px solid rgba(255,255,255,.18);border-top:4px solid #22c55e;border-radius:50%;animation:tadSpin 1s linear infinite;\"></div>Đang tải dữ liệu...</div>");
    if(!$("#tadStyleExtra").length)$("<style id=\"tadStyleExtra\">@keyframes tadSpin{0%{transform:rotate(0deg)}100%{transform:rotate(360deg)}}</style>").appendTo("head");
}
function hideSkeleton(){$("#tadOverlay").remove()}

function loadAvatar(info){
    var imgEl=document.getElementById("tadEsdAvatar");if(!imgEl||!info)return;
    var defaultSvg=imgEl.getAttribute("src");imgEl.onerror=function(){this.onerror=null;this.src=defaultSvg;};
    var code=info.ID||info.EmployeeID||empId;
    $(imgEl).attr("data-emp-id",code).attr("title",info.Name||info.FullName||code);
    var avatarInfo={ID:code,Name:info.Name||info.FullName||code,Code:info.Code||code,paramImg:info.paramImg,storeImgName:info.storeImgName||"paradisefile_sp_GetFileAPI"};
    if(window.GlobalEmployeeAvatarCache&&window.GlobalEmployeeAvatarCache[code]){imgEl.src=window.GlobalEmployeeAvatarCache[code];return}
    function fallback(){
        if(!avatarInfo.paramImg||typeof AjaxHPAParadise!=="function")return;
        var raw=String(avatarInfo.paramImg), param=[];
        try{param=JSON.parse(decodeURIComponent(raw))}catch(e1){try{param=JSON.parse(raw)}catch(e2){param=[]}}
        if(!param||!param.length)return;
        AjaxHPAParadise({data:{name:avatarInfo.storeImgName,param:param},xhrFields:{responseType:"blob"},success:function(blob){
            if(!blob)return;
            if(typeof blob==="string"){imgEl.src=blob;return}
            var url=(window.URL||window.webkitURL).createObjectURL(blob);imgEl.src=url;
            if(window.GlobalEmployeeAvatarCache)window.GlobalEmployeeAvatarCache[code]=url;
        },error:function(){}});
    }
    if(typeof window.loadEmployeeAvatarAsync==="function"){
        var p=window.loadEmployeeAvatarAsync(code,avatarInfo);
        if(p&&typeof p.then==="function"){p.then(function(url){if(url)imgEl.src=url;else fallback();}).catch(fallback);return}
    }
    fallback();
}

function fillSelect(el,rows,idField,nameField,placeholder){
    var out="";
    if(placeholder) out += "<option value=\"\">-- "+html(placeholder)+" --</option>";
    rows.forEach(function(r){out+="<option value=\""+html(r[idField])+"\">"+html(r[nameField])+"</option>"});
    $(el).html(out);
}

function loadOptions(done){
    api("sp_TAD_EmployeeScheduleDetail_GetTrainingStatusOptions",["LoginID",LoginID,"LanguageID",LanguageID],function(res){
        statusOptions=rowsOf(res);
        fillSelect("#trainingStatusSelect",statusOptions,"ID","Name",null);
        api("sp_TAD_EmployeeScheduleDetail_GetLevelOptions",["LoginID",LoginID,"LanguageID",LanguageID],function(res2){
            levelOptions=rowsOf(res2);
            fillSelect("#levelSelect",levelOptions,"ID","Name","Chưa có Level nào");
            if(done)done();
        });
    });
}

function loadEmp(done){
    employeeProfileLoaded=false;
    if(!empId){
        showAlert("error","Thiếu EmployeeID");
        employeeProfileLoaded=true;
        if(done)done(false);
        return;
    }
    api("sp_TAD_EmployeeScheduleDetail_GetEmpInfo",["LoginID",LoginID,"LanguageID",LanguageID,"EmployeeID",empId],function(res){
        var info=oneOf(res);
        if(!info){
            employeeProfileLoaded=true;
            if(done)done(false);
            return;
        }
        suppressProfileSave=true;
        $("#tadEsdName,#fFullName").text(info.FullName||info.Name||"--");
        $("#tadEsdCode").text(info.EmployeeID||info.ID||"--");
        $("#tadEsdTitle,#fPosition").text(info.PositionName||"");
        $("#tadEsdDept,#fDept").text(info.DepartmentName||"");
        $("#tadEsdLevel").text(info.EmployeeLevel?("Level "+info.EmployeeLevel):"--");
        var statusValue=info.TrainingStatus||info.StatusID||info.DefaultTrainingStatusID||getDefaultStatusId()||"";
        $("#trainingSta';
    SET @html = @html + N'tusSelect").val(statusValue);
        $("#levelSelect").val(info.EmployeeLevel||"");
        firstTrainingDate=info.FirstTrainingDate?fmt(info.FirstTrainingDate):"";
        employeeHireDate=info.HireDate?fmt(info.HireDate):"";
        currentPhaseCompletedDays=parseInt(info.CurrentPhaseCompletedDays||"0",10);
        currentPhaseRequiredDays=parseInt(info.CurrentPhaseRequiredDays||"0",10);
        $("#fPic").text(info.TeamLeaderName||info.LineManagerName||"");
        if(info.DedicatedTrainerName){$("#trainerField").removeClass("hidden");$("#fTrainer").text(info.DedicatedTrainerName)}else{$("#trainerField").addClass("hidden")}
        if(info.TeamLeaderName){$("#leaderField").removeClass("hidden");$("#fLeader").text(info.TeamLeaderName)}else{$("#leaderField").addClass("hidden")}
        $("#fHireDate").text(info.HireDate?viDate(info.HireDate):"--");
        suppressProfileSave=false;
        updateAutoScheduleButton();
        loadAvatar(info);
        employeeProfileLoaded=true;
        if(done)done(true);
    },function(){
        employeeProfileLoaded=true;
        showAlert("error","Không tải được thông tin nhân viên");
        if(done)done(false);
    });
}

function saveProfile(field,value){
    if(suppressProfileSave||!empId)return;
    var param=["LoginID",LoginID,"LanguageID",LanguageID,"EmployeeID",empId];
    if(field==="TrainingStatus")param=param.concat(["TrainingStatus",parseInt(value,10)]);
    if(field==="Level")param=param.concat(["Level",value===""?null:parseInt(value,10),"LevelIsSet",1]);
    api("sp_TAD_EmployeeScheduleDetail_UpdateProfile",param,function(res){
        var r=oneOf(res);
        if(r&&String(r.Status)==="0"){showAlert("error",r.Message||"Không lưu được");loadEmp();return}
        showAlert("success","Đã lưu");
        loadEmp(function(){loadSchedule()});
        loadTraining();
    },function(){showAlert("error","Không lưu được")});
}

function loadTraining(){
    if(!empId)return;
    api("sp_TAD_EmployeeScheduleDetail_GetTraining",["LoginID",LoginID,"LanguageID",LanguageID,"EmployeeID",empId],function(res){
        var rows=rowsOf(res), out="<div class=\"tad-timeline-title\">Lịch sử trạng thái Training</div>";
        if(!rows.length){$("#historyGrid").html(out+"<div class=\"tad-empty\">Chưa có lịch sử trạng thái.</div>");hideSkeleton();return}
        rows.forEach(function(r,i){
            var chgDate=new Date(r.ChangedDate);
            var dateStr=isNaN(chgDate.getTime())?viDate(r.ChangedDate):(pad(chgDate.getDate())+"/"+pad(chgDate.getMonth()+1)+"/"+chgDate.getFullYear()+" "+pad(chgDate.getHours())+":"+pad(chgDate.getMinutes()));
            var range=dateStr+" · Bởi "+(r.ChangedBy||"System");
            out+="<div class=\"tad-timeline-item\" style=\"animation-delay:"+(i*55)+"ms\"><div class=\"tad-timeline-dot\"></div><div class=\"tad-timeline-content\"><div class=\"tad-timeline-main\"><span class=\"tad-timeline-date\">"+html(range)+" · </span><span class=\"tad-timeline-status\">"+html(r.StatusName||"")+"</span></div><div class=\"tad-timeline-note\"></div></div></div>";
        });
        $("#historyGrid").html(out);
        hideSkeleton();
    });
}

function loadCerts(){
    if(!empId)return;
    api("sp_TAD_EmployeeScheduleDetail_GetCerts",["LoginID",LoginID,"LanguageID",LanguageID,"EmployeeID",empId],function(res){
        var rows=rowsOf(res), out="";
        if(!rows.length){$("#certGrid").html("<div class=\"tad-empty\">Chưa có chứng chỉ / kỹ năng.</div>");hideSkeleton();return}
        rows.forEach(function(r){out+="<div class=\"tad-cert-card\"><h4 class=\"tad-cert-title\">"+html(r.ModuleName)+"</h4><p class=\"tad-cert-desc\">"+html(r.Description||"")+"</p></div>"});
        $("#certGrid").html(out);
        hideSkeleton();
    });
}

function loadShiftOptions(dateStr,done){
    api("sp_TAD_EmployeeScheduleDetail_GetShiftOptions",["LoginID",LoginID,"LanguageID",LanguageID,"ScheduleDate",dateStr],function(res){
        shiftOptions=rowsOf(res);
        if(done)done();
    },function(){shiftOptions=[];if(done)done()});
}


function shiftName(id){var f=getShift(id);return f?getShiftName(f):String(id||"")}

function loadSchedule(){
    if(!empId){scheduleRows=[];renderCalen';
    SET @html = @html + N'dar();return}
    api("sp_TAD_EmployeeScheduleDetail_GetSchedule",["LoginID",LoginID,"LanguageID",LanguageID,"EmployeeID",empId,"FilterType",filterType],function(res){
        scheduleRows=rowsOf(res);renderCalendar();
    },function(){scheduleRows=[];renderCalendar()});
}

function renderCalendar(){
    if(!employeeProfileLoaded){
        showSkeleton();
        return;
    }
    var today=new Date();var y=today.getFullYear(),m=today.getMonth();var out="";
    if(filterType==="ThisWeek"){
        var d=today.getDay()||7;var mon=new Date(today);mon.setDate(today.getDate()-d+1);var sun=new Date(today);sun.setDate(today.getDate()-d+7);
        $("#calendarTitle").text("Lịch tuần từ "+viDate(mon)+" - "+viDate(sun));
        for(var date=new Date(mon);date<=sun;date.setDate(date.getDate()+1)){
            out+=dayHtml(fmt(date),date.getDate(),getRowByDate(fmt(date)),true);
        }
    }else{
        $("#calendarTitle").text("Lịch tháng "+pad(m+1)+"/"+y);
        var first=new Date(y,m,1),last=new Date(y,m+1,0),start=(first.getDay()+6)%7;
        for(var i=0;i<start;i++)out+="<div class=\"tad-day empty\"></div>";
        for(var dt=1;dt<=last.getDate();dt++){var date2=new Date(y,m,dt);out+=dayHtml(fmt(date2),dt,getRowByDate(fmt(date2)),false)}
    }
    api("sp_TAD_EmployeeScheduleDetail_UpdateProfile",param,function(res){
        var r=oneOf(res);
        if(r&&String(r.Status)==="0"){showAlert("error",r.Message||"Không lưu được");loadEmp();return}
        showAlert("success","Đã lưu");
        loadEmp(function(){loadSchedule()});
        loadTraining();
    },function(){showAlert("error","Không lưu được")});
}

function loadTraining(){
    if(!empId)return;
    api("sp_TAD_EmployeeScheduleDetail_GetTraining",["LoginID",LoginID,"LanguageID",LanguageID,"EmployeeID",empId],function(res){
        var rows=rowsOf(res), out="<div class=\"tad-timeline-title\">Lịch sử trạng thái Training</div>";
        if(!rows.length){$("#historyGrid").html(out+"<div class=\"tad-empty\">Chưa có lịch sử trạng thái.</div>");hideSkeleton();return}
        rows.forEach(function(r,i){
            var range="Từ "+viDate(r.StartDate||r.ChangedDate)+(String(r.IsCurrent)==="1"?" · Đang áp dụng":(r.EndDate?(" đến "+viDate(r.EndDate)):""));
            out+="<div class=\"tad-timeline-item\" style=\"animation-delay:"+(i*55)+"ms\"><div class=\"tad-timeline-dot\"></div><div class=\"tad-timeline-content\"><div class=\"tad-timeline-main\"><span class=\"tad-timeline-date\">"+html(range)+" · </span><span class=\"tad-timeline-status\">"+html(r.StatusName)+"</span></div><div class=\"tad-timeline-note\">"+html(r.Description||"")+"</div></div></div>";
        });
        $("#historyGrid").html(out);
        hideSkeleton();
    });
}

function loadCerts(){
    if(!empId)return;
    api("sp_TAD_EmployeeScheduleDetail_GetCerts",["LoginID",LoginID,"LanguageID",LanguageID,"EmployeeID",empId],function(res){
        var rows=rowsOf(res), out="";
        if(!rows.length){$("#certGrid").html("<div class=\"tad-empty\">Chưa có chứng chỉ / kỹ năng.</div>");hideSkeleton();return}
        rows.forEach(function(r){out+="<div class=\"tad-cert-card\"><h4 class=\"tad-cert-title\">"+html(r.ModuleName)+"</h4><p class=\"tad-cert-desc\">"+html(r.Description||"")+"</p></div>"});
        $("#certGrid").html(out);
        hideSkeleton();
    });
}

function loadShiftOptions(dateStr,done){
    api("sp_TAD_EmployeeScheduleDetail_GetShiftOptions",["LoginID",LoginID,"LanguageID",LanguageID,"ScheduleDate",dateStr],function(res){
        shiftOptions=rowsOf(res);
        if(done)done();
    },function(){shiftOptions=[];if(done)done()});
}


function shiftName(id){var f=getShift(id);return f?getShiftName(f):String(id||"")}

function loadSchedule(){
    if(!empId){scheduleRows=[];renderCalendar();return}
    api("sp_TAD_EmployeeScheduleDetail_GetSchedule",["LoginID",LoginID,"LanguageID",LanguageID,"EmployeeID",empId,"FilterType",filterType],function(res){
        scheduleRows=rowsOf(res);renderCalendar();
    },function(){scheduleRows=[];renderCalendar()});
}

function renderCalendar(){
    if(!employeeProfileLoaded){
        showSkeleton();
  return;
    }
    var today=new Date();var y=today.getFullYear(),m=today.getMonth();var out="";
    if(filterType==="ThisWeek"){
        var d=today.getDay()||7;var mon=new Date(today);mon.setDate(today.getDate()-d+1);var sun=new Date(today);sun.setDate(today.getDate()-d+7);
        $("#calendarTitle").text("Lịch tuần từ "+viDate(mon)+" - "+viDate(sun));
        for(var date=new Date(mon);date<=sun;date.setDate(date.getDate()+1)){
            out+=dayHtml(fmt(date),date.getDate(),getRowByDate(fmt(date)),true);
        }
    }else{
        $("#calendarTitle").text("Lịch tháng "+pad(m+1)+"/"+y);
        var first=new Date(y,m,1),last=new Date(y,m+1,0),start=(first.getDay()+6)%7;
        for(var i=0;i<start;i++)out+="<div class=\"tad-day empty\"></div>";
        for(var dt=1;dt<=last.getDate();dt++){var date2=new Date(y,m,dt);out+=dayHtml(fmt(date2),dt,getRowByDate(fmt(date2)),false)}
    }
    $("#calendarDays").html(out);
    updateAutoScheduleButton();
    hideSkeleton();
}

function updateAutoScheduleButton(){
    var currentStatus=$("#trainingStatusSelect").val()||getDefaultStatusId()||"";
    var currentStatusName=getStatusName(currentStatus);
    var isAllowedStatus = /FBT|SHTP/i.test(currentStatusName);
    var level=parseInt($("#levelSelect").val()||"0",10);
    var required=currentPhaseRequiredDays||(/SHTP/i.test(currentStatusName)?level:4);
    var completed=currentPhaseCompletedDays||0;
    var missingLevel=/SHTP/i.test(currentStatusName)&&!level;
    var isComplete=required>0&&completed>=required;

    var isDisabled = !isAllowedStatus || missingLevel || isComplete;
    var tooltip = "";
    if (!isAllowedStatus) {
        tooltip = "Tạo lịch tự động chỉ áp dụng cho FBT Training và SHTP.";
    } else if (missingLevel) {
        tooltip = "Vui lòng chọn Level trước khi tạo lịch SHTP.";
    } else if (isComplete) {
        tooltip = "Giai đoạn này đã đủ " + required + " ngày.";
    } else {
        tooltip = "Tạo lịch tự động";
    }

    $("#btnAutoSchedule").prop("disabled",isDisabled).attr("title",tooltip);
}

function dayHtml(dateStr,dayNumber,row,large){
    var todayStr=fmt(new Date());
    var beforeHire=employeeHireDate&&dateStr<employeeHireDate;
    var pastDay=dateStr<todayStr;
    if(beforeHire) return "<div class=\"tad-day empty\" title=\"Ngày trước HireDate\"></div>";
    if(!row||!row.ShiftGroup){
        var locked=pastDay;
        var tip=pastDay?"Ngày đã qua":"";
        return "<div class=\"tad-day "+(large?"large":"")+(locked?" training-past":"")+"\" data-date=\""+dateStr+"\""+(locked?" data-locked=\"1\" title=\""+tip+"\"":"")+"><div class=\"tad-day-head\"><div class=\"tad-num\">"+dayNumber+"</div></div><div class=\"tad-empty\">Chưa phân ca</div></div>"
    }
    var statusText=row.TrainingPhaseText||row.TrainingStatusName||"";
    var status=statusText?("<span class=\"tad-day-status\">"+html(statusText)+"</span>"):"";
    var rowLocked=pastDay;
    var rowTip=pastDay?"Ngày đã qua":"";
    return "<div class=\"tad-day "+(large?"large":"")+(rowLocked?" training-past":"")+"\" data-date=\""+dateStr+"\""+(rowLocked?" data-locked=\"1\" title=\""+rowTip+"\"":"")+"><div class=\"tad-day-head\"><div class=\"tad-num\">"+dayNumber+"</div>"+status+"</div><div class=\"tad-event\"><div class=\"tad-shift\">"+html(row.ShiftDisplay||shiftName(row.ShiftID))+"</div><div class=\"tad-time\">"+html(normalizeTime(row.StartTime))+" - "+html(normalizeTime(row.EndTime))+"</div></div></div>";
}

function syncShiftTime(){
    var s=getShift($("#editShift").val());
    $("#editStart").val(s?normalizeTime(s.WorkStart||s.WorkStartStr||""):"");
    $("#editEnd").val(s?normalizeTime(s.WorkEnd||s.WorkEndStr||""):"");
}

function refreshShiftRecommendation(){
    var current=$("#editShift").val();
    var priority=isPriorityStatus($("#editTrainingStatus").val());
    var out="";
    shiftOptions.forEach(function(s){out+="<option value=\""+html(getShiftId(s))+"\">"+html(getShiftName(s))+"</option>"});
    $("#editShift").html(out);
    if(priority&&!popupShiftTouched){var hc=getHCShift();if(hc)current=String(getShiftId(hc))}
    if(!getShift(current))current=String(getShiftId(shiftOptions[0]||{}));
    $("#editShift").val(current);
    syncShiftTime();
}

function openPopup(dateStr){
    selectedDay=dateStr;
    popupShiftTouched=false;
    var row=getRowByDate(dateStr);
    $("#shiftPopupTitle").text(row&&row.ShiftID?"Sửa ca làm việc":"Chọn ca làm việc");
    $("#popupDateText").text(viDate(dateStr));
    loadShiftOptions(dateStr,function(){
        if(!shiftOptions.length){showAlert("error","Chưa có cấu hình ca cho ngày này");return}
        var empCurrentStatus = $("#trainingStatusSelect").val()||getDefaultStatusId();
        var dayStatus = (row&&row.TrainingStatus) ? row.TrainingStatus : empCurrentStatus;
        var isPriority=isPriorityStatus(dayStatus);
        var out="";shiftOptions.forEach(function(s){out+="<option value=\""+html(getShiftId(s))+"\">"+html(getShiftName(s))+"</option>"});
        var selectedOption=row&&row.ShiftGroup?getShiftByGroup(row.ShiftGroup):null;
        var selectedShift=selectedOption?String(getShiftId(selectedOption)):(row&&row.ShiftID?String(row.ShiftID):String(getShiftId(shiftOptions[0]||{})));
        if(!row&&isPriority){var hc=getHCShift();if(hc)selectedShift=String(getShiftId(hc))}
        if(!getShift(selectedShift))selectedShift=String(getShiftId(shiftOptions[0]||{}));

        // Trạng thái đào tạo
        fillSelect("#editTrainingStatus",statusOptions,"ID","Name",null);
        $("#editTrainingStatus").val(dayStatus);

        // Khóa ngày được xử lý bên ngoài, nên ở đây mặc định cho mở form và chọn
        $("#editShift").html(out).val(selectedShift).prop("disabled", false);
        $("#editTrainingStatus").prop("disabled", false);
        $("#deleteShift").show();
        if($("#msgOffDay").length) $("#msgOffDay").hide();
        $("#saveShift").prop("disabled", false).css("opacity", 1);

        syncShiftTime();
        $("#shiftPopup").css("display","flex");
    });
}
function savePopup(force){
    if(!selectedDay){showAlert("error","Thiếu ngày làm việc");return}
    var shiftId=$("#editShift").val();
    var statusId=$("#editTrainingStatus").val()||getDefaultStatusId()||"0";
    var param=["LoginID",LoginID,"LanguageID",LanguageID,"EmployeeID",empId,"ScheduleDate",selectedDay,"ShiftID",shiftId,"TrainingStatusID",statusId];
    if(force)param.push("Force",1);
    api("sp_TAD_EmployeeScheduleDetail_SaveSchedule",param,function(res){
        var r=oneOf(res);
        if(r&&String(r.Status)==="2"&&String(r.NeedConfirm)==="1"){
            confirmAction(r.Message,function(){ savePopup(true); });
            return;
        }
        if(r&&String(r.Status)==="0"){showAlert("error",r.Message||"Không lưu được phân ca");return}
        showAlert("success","Đã lưu phân ca");$("#shiftPopup").hide();
        loadEmp(function(){loadSchedule()});
        loadTraining();
    },function(){showAlert("error","Không lưu được phân ca")});
}

function deletePopup(){
    if(!selectedDay){showAlert("error","Thiếu ngày làm việc");return}
    confirmAction("Bạn có muốn xóa ca hiện tại không?",function(){
        api("sp_TAD_EmployeeScheduleDetail_DeleteSchedule",["LoginID",LoginID,"LanguageID",LanguageID,"EmployeeID",empId,"ScheduleDate",selectedDay],function(res){
            var r=oneOf(res);
            if(r&&String(r.Status)==="0"){showAlert("error",r.Message||"Không xóa được ca");return}
            showAlert("success","Đã xóa ca");$("#shiftPopup").hide();
            loadEmp(function(){loadSchedule()});
            loadTraining();
        },function(){showAlert("error","Không xóa được ca")});
    });
}

function runAutoSchedule(force){
    if(!empId){showAlert("error","Thiếu EmployeeID");hideSkeleton();return}
    var statusId=$("#trainingStatusSelect").val()||getDefaultStatusId()||"0";
    api("sp_TAD_EmployeeScheduleDetail_AutoSchedule",["LoginID",LoginID,"LanguageID",LanguageID,"EmployeeID",empId,"FilterType",filterType,"TrainingStatusID",statusId,"Force",force?1:0],function(res){
        var r=oneOf(res)||{};
        if(String(r.Status)==="0"){hideSkeleton();showAlert("error",r.Message||"Không tạo được lịch tự động");return}
        if(String(r.NeedConfirm)==="1"){
            hideSkeleton();
            confirmAction(r.Message||"Lịch tự động cần xác nhận thêm. Anh có muốn tiếp tục không?",function(){showSkeleton();runAutoSchedule(true)});
            return;
        }
        showAlert("success",(r.Message||"Đã tạo lịch tự động")+(r.InsertedRows!==undefined?(" ("+r.InsertedRows+" ngày)"):""));
        loadEmp(function(){
            loadSchedule();
        });
        loadTraining();
    },function(){hideSkeleton();showAlert("error","Không tạo được lịch tự động")});
}

function autoSchedule(){
    if($("#btnAutoSchedule").prop("disabled"))return;
    var statusId=$("#trainingStatusSelect").val()||getDefaultStatusId()||"";
    var phaseName=getStatusName(statusId);
    confirmAction("Anh có muốn tự động tạo lịch Hành Chính cho giai đoạn "+phaseName+" hiện tại không?",function(){
        showSkeleton();
        runAutoSchedule(false);
    });
}

$(function(){
    showSkeleton();

    $("#tadEsdCloseBtn").on("click",closeForm);
    $(".tad-tab").on("click",function(){var t=$(this).data("tab");showSkeleton();$(".tad-tab").removeClass("active");$(this).addClass("active");$(".tad-panel").removeClass("active");$("#tab-"+t).addClass("active");if(t==="history")loadTraining();if(t==="schedule")loadSchedule();if(t==="cert")loadCerts()});
    $(".tad-seg button").on("click",function(){showSkeleton();$(".tad-seg button").removeClass("active");$(this).addClass("active");filterType=$(this).data("filter");loadSchedule()});
    $(document).on("click",".tad-day:not(.empty)",function(){
        if($(this).data("locked"))return;
        var dateStr=$(this).data("date");
        openPopup(dateStr);
    });
    $("#closeShiftPopup,#cancelShift").on("click",function(){$("#shiftPopup").hide()});
    $("#editShift").on("change",function(){popupShiftTouched=true;syncShiftTime()});
    $("#editTrainingStatus").on("change",refreshShiftRecommendation);
    $("#saveShift").on("click",savePopup);
    $("#deleteShift").on("click",deletePopup);
    $("#btnAutoSchedule").on("click",autoSchedule);
    $("#trainingStatusSelect").on("change",function(){updateAutoScheduleButton();saveProfile("TrainingStatus",this.value)});
    $("#levelSelect").on("change",function(){saveProfile("Level",this.value)});
    loadOptions(function(){
        loadEmp(function(){
            loadSchedule();
        });
    });
});
})();
</script>';

    SELECT @html AS html;
END
GO