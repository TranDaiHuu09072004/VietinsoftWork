# INDEX — ParadiseHR Knowledge Base Directory

Read this index to locate target knowledge files before scanning the codebase. Ensure all referenced tables, columns, procedures, and parameters are verified against [99_deprecated.md](99_deprecated.md) before use.

---

## 1. Directory of Knowledge Files
| File Name | Primary Topic | Target Context |
|---|---|---|
| [00_quick_context.md](00_quick_context.md) | Project Overview | Repository structure, DB servers, and target workspace boundaries. |
| [01_architecture.md](01_architecture.md) | Client Platforms | Windows Desktop, Web App, Mobile ESS, client parameters, and flags. |
| [02_db_employee.md](02_db_employee.md) | Employee Profiles | Schema for `tblEmployee` and satellite history tables. |
| [03_db_contract.md](03_db_contract.md) | Labour Contracts | Schema for `tblLabourContract` and Crystal Reports print logic. |
| [04_db_biometric.md](04_db_biometric.md) | Biometrics | Fingerprint, face, and palm templates mapping ZKTeco models. |
| [05_db_attendance.md](05_db_attendance.md) | Attendance Pipeline | Logs raw to daily fact calculation flow (`tblTmpAttend` -> `tblHasTA`). |
| [06_db_login_account.md](06_db_login_account.md) | User Accounts | `tblSC_Login` structure, authentication procedures, and 2FA settings. |
| [07_menu_system.md](07_menu_system.md) | Navigation Menu | 5 menu elements, HTML caching (`tblHtmlScriptCache`), and ranking. |
| [08_workflow_crm.md](08_workflow_crm.md) | CRM Module | Lead collection, pipeline status, client accounts, contracts, and KPIs. |
| [09_workflow_payroll.md](09_workflow_payroll.md) | Payroll Pipeline | 10 calculation steps, insurance (SI/HI/UI), PIT, and Trade Union fees. |
| [10_workflow_performance.md](10_workflow_performance.md) | Performance | Standard reviews, BSC KPIs, probation tracking, and gamification. |
| [11_permissions.md](11_permissions.md) | Authorization | Role-based permissions (RBAC), data visibility filters, and parents. |
| [12_CreateMenu.md](12_CreateMenu.md) | Menu Creation | Standard sequence for deploying custom HTML-rendered Web menus. |
| [13_Migrate_Menu.md](13_Migrate_Menu.md) | Menu Migration | Porting screens cross-DB using idempotent scripts. |
| [14_ParadiseStyle.md](14_ParadiseStyle.md) | UI Guidelines | Visual design tokens, local scope guidelines, and Bootstrap Icons. |
| [15_employee_query_apis.md](15_employee_query_apis.md) | Core Queries | Snapshot query `fn_vtblEmployeeList_Bydate` and permission filter APIs. |
| [16_mobile_notification.md](16_mobile_notification.md) | Mobile Push | FCM token mappings (`tblDeviceCodeInfo`) and dispatch pipelines. |
| [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) | Secure Rendering | Escape rules for T-SQL boundaries, binary image streams (Msg 257). |
| [18_FindMenuProcedure.md](18_FindMenuProcedure.md) | Menu Search | Step-by-step lookup matching menu names to backing procedures. |
| [19_TaskAssignment.md](19_TaskAssignment.md) | Tasks System | Version-controlled task workflows, checklists, and approvals. |
| [20_ControlSystem.md](20_ControlSystem.md) | HPA Controls | `tblCommonControlType_Signed` settings, JS APIs, and data sources. |
| [21_SPA_Routing.md](21_SPA_Routing.md) | Router | Routing transitions (`openFormParam`) and parameters fetching. |
| [22_UI_Helpers.md](22_UI_Helpers.md) | Global Alerts | Popup wrappers: toast alerts (`uiManager.showAlert`) and modals. |
| [23_CallAPI.md](23_CallAPI.md) | AJAX Operations | Client AJAX operations using `AjaxHPAParadise` with flat arrays. |
| [24_CreateStoredProcedure.md](24_CreateStoredProcedure.md) | SP Programming | Boilerplate templates and design guidelines. |
| [25.HPA_Controls_Guidelines.md](25.HPA_Controls_Guidelines.md) | Control Guidelines | Grid column format rules (dates/currency) and runtime overrides. |
| [26_QueryOptimization.md](26_QueryOptimization.md) | SQL Performance | Query diagnostics (DMVs, missing indexes), temp tables vs CTEs. |
| [27_MCP_Troubleshooting.md](27_MCP_Troubleshooting.md) | MCP Workarounds | Alternate queries for bugged MCP operations (`describe_table`). |
| [28_Zalo_Integration.md](28_Zalo_Integration.md) | Zalo Chat API | Personal Zalo logins, session tokens, and image uploads. |
| [29_zalo_web_Official.md](29_zalo_web_Official.md) | Zalo Web Client | chat.zalo.me internal IndexedDB schemas and WebSocket specs. |
| [soSanhZaloParadiseVS_ZaloOffficial.md](soSanhZaloParadiseVS_ZaloOffficial.md) | Zalo Compare | Features comparisons: Paradise Client API vs Official Zalo Web client. |
| [29_PythonToolSafety.md](29_PythonToolSafety.md) | Python Tool Safety | Rules to avoid python tool errors in CLI. |
| [richtext.md](richtext.md) | Rich Text Editor | Premium editor base64 UTF-16LE conversion scripts. |
| [email_batching_guide.md](email_batching_guide.md) | Email Batching | Microsoft Graph API batch payloads (max 20 requests per call). |
| [LOAD_EMPLOYEE_AVATAR_GUIDE.md](LOAD_EMPLOYEE_AVATAR_GUIDE.md) | Avatar Loading | Default SVG to Blob async lazy loading and memory caching. |
| [99_deprecated.md](99_deprecated.md) | Deprecated | Obsolete schemas (ASPX pages, Zalo OA templates, legacy task tables). |

---
## 2. Keywords Directory

| Từ khoá / Keywords | File chính |
|---|---|
| **nhân viên / hồ sơ / employee / gia đình / phụ thuộc / dependant / Profiles / Dependents / Education / Bank Details** | [02_db_employee.md](02_db_employee.md) |
| **snapshot nhân viên theo ngày / `fn_vtblEmployeeList_Bydate` / `fn_vEmployeeStatus_ByDate` / `tmpEmployeeTree` / temporal employee / Subordinates / User Permission Subtree / Temporal Snapshot** | [15_employee_query_apis.md](15_employee_query_apis.md) |
| **danh sách nhân viên theo quyền / `sp_getEmployeeListWithPermission` / `fn_Common_GetAccessID` / Full access / Manager access / Customer access / meta-role / ParentLoginID** | [15_employee_query_apis.md](15_employee_query_apis.md) |
| **gia đình / phụ thuộc / dependant** | [02_db_employee.md](02_db_employee.md) |
| **hợp đồng / contract / in hợp đồng / Representatives / Template Prints** | [03_db_contract.md](03_db_contract.md) |
| **vân tay / khuôn mặt / sinh trắc / biometric / face / fingerprint / Clock Terminals / Palm / FaceTemp / MachinesBadgeNumberUploaded** | [04_db_biometric.md](04_db_biometric.md) |
| **chấm công / attendance / GPS / Wifi / IO card / `tblTmpAttend` / `tblHasTA` / Raw Logs / GPS/Wifi Limits / Daily Calculation / Shift Detection / `sp_ShiftDetector_*` / `TA_Process_Main`** | [05_db_attendance.md](05_db_attendance.md) |
| **tạo user / đăng nhập / mật khẩu / login / `tblSC_Login` / Account / Login / Password Security / 2FA / `sp_CreateUser` / `SC_Login_CheckLogin`** | [06_db_login_account.md](06_db_login_account.md) |
| **menu / `MEN_Menu` / tạo menu / `sp_s_CreateMenu` / DataSetting / HTML cache / `tblHtmlScriptCache` / ParadiseWebView2 / Menu Registry / Caching / Assembly Settings** | [07_menu_system.md](07_menu_system.md) |
| **tạo menu mới end-to-end / skill tạo menu / AjaxHPAParadise / gọi API hiển thị data / Hello world Vietinsoft / đa ngôn ngữ / i18n / %placeholder% / tblMD_Message / Rule 7 / Create Menu** | [12_CreateMenu.md](12_CreateMenu.md) |
| **migrate menu / update menu / script update menu / script migrate menu / Quản lý bài học / Nhật ký công việc / copy giao diện menu / không chèn trùng quyền menu / KHÔNG USE database / Rule 7 / Rule 8 / %placeholder% tblMD_Message / Migrate Menu** | [13_Migrate_Menu.md](13_Migrate_Menu.md) |
| **thiết kế giao diện / làm đẹp menu / refactor UI / CSS menu / ParadiseStyle / 4 layout gốc inject CSS (`sp_dashboard_mobile_Beta`, `paradise_dashboard_sslayoutbody`, `sslayoutbody`, `HtmlMacOSLayOut`) / `sp_MainStyleCSSParadise` (chỉ ở layout gốc, KHÔNG gọi ở renderer menu) / không thiết lập background / token `--paradise-*` / class `.paradise-*` / UI/UX Standard Styles / CSS Tokens / Layout Shells** | [14_ParadiseStyle.md](14_ParadiseStyle.md) |
| **control system / HPA Control / tạo control / thêm field vào màn hình / cấu hình ô nhập liệu / `tblCommonControlType_Signed` / `sptblCommonControlType_Signed_DUC` / `sp_GenerateHTMLScript` / `hpaControlText` (SelectBox, TagBox, TextSearch, SelectEmployee, Date, Money, CheckBox, TextArea, RichTextEditorPremium, File, Phone, Number, Pipeline, Segmented, Time) / ControlGrid / Grid_View / AutoSave / IsRequired / ReadOnly / callback `onSelectBoxChanged_` `onTagBoxChanged_` `onTextSearchSelected_` / suppress resume / `loadUI` `loadData` / `Instance*.setValue` `getValue` `option` / `loadDataSourceCommon` / `openDetail<Key>` / Control Creation / Types Configuration / Binding APIs** | [20_ControlSystem.md](20_ControlSystem.md) |
| **SPA routing / chuyển trang / điều hướng / truyền tham số giữa các màn hình / `openFormParam` / `OpenFormParamMobile` / `<FormName>_param` / `openDetail<Key>` (pattern gọi từ ControlGrid) / `IsOpenDetailRowGrid` / đăng ký menu ẩn cho routing / `DataSettingListViewActivity` / `getMobileOperatingSystem()` / SPA Transitions / Parameters Passing** | [21_SPA_Routing.md](21_SPA_Routing.md) |
| **hiển thị alert / thông báo / popup xác nhận / showAlert / showConfirmPopup / `uiManager.showAlert` / `showConfirmPopup` / YesText / NoText / onYes / onNo / Alerts / Confirmation Modals** | [22_UI_Helpers.md](22_UI_Helpers.md) |
| **gọi API / gọi procedure từ client / AjaxHPAParadise / giải mã api / EncryptionStringDecryption / tải file ảnh qua api / paradisefile_sp_GetFileAPI / AJAX Fetch / Binary Download** | [23_CallAPI.md](23_CallAPI.md) |
| **renderer HTML JS an toàn / escape T-SQL → JS / quote boundary `N'...'` / Msg 257 implicit conversion / `varbinary(max)` / dynamic SQL `tblCommonControlType_Signed` / UID deterministic / script render export DB khác / `Incorrect syntax near 'function'` / `InstanceXXX is not defined` / polyfill `loadDataSourceCommon` / cache `tblHtmlScriptCache` do `sp_GenerateHTMLScript` xử lý / Layer 2b i18n / %placeholder% / đa ngôn ngữ tblMD_Message / Escape SQL boundaries / Unicode boundaries / Varbinary streams** | [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) |
| **tìm procedure từ tên menu / debug giao diện menu / lookup menu → proc / "menu X dùng proc nào" / xác định renderer `%_html` / `tblMD_Message → MEN_Menu → ClassName → sys.objects` / menu không tồn tại trong DB / tra cứu Mnu / `MessageID = MenuID` / Find Menu SPs / Debug Wrapper** | [18_FindMenuProcedure.md](18_FindMenuProcedure.md) |
| **giao diện desktop / giao diện web** | [07_menu_system.md](07_menu_system.md) + [14_ParadiseStyle.md](14_ParadiseStyle.md) nếu có thiết kế UI |
| **xếp hạng nhân viên / ranking / điểm kinh nghiệm / coin / XP** | [07_menu_system.md](07_menu_system.md) (section 10) |
| **Sales Pipeline / `MnuKPI007`** | [07_menu_system.md](07_menu_system.md) (section 13) |
| **CRM / lead / customer / sales pipeline / hợp đồng CRM / công nợ / CRM Sales Pipeline / Accounts / CRM KPI** | [08_workflow_crm.md](08_workflow_crm.md) |
| **tính lương / payroll / `SALCAL_MAIN` / phiếu lương / payslip / bank file / chuyển khoản / Payroll Engine / PIT scale / Union Fees** | [09_workflow_payroll.md](09_workflow_payroll.md) |
| **BHXH / BHYT / BHTN / bảo hiểm / Insurance / Insurance calculation** | [09_workflow_payroll.md](09_workflow_payroll.md) (giai đoạn 4) |
| **thuế / PIT / TNCN / quyết toán thuế / PIT scale / personal income tax** | [09_workflow_payroll.md](09_workflow_payroll.md) (giai đoạn 5) |
| **công đoàn / Union / Trade Union fees** | [09_workflow_payroll.md](09_workflow_payroll.md) (giai đoạn 6) |
| **OT / tăng ca / làm thêm giờ / overtime** | [09_workflow_payroll.md](09_workflow_payroll.md) (giai đoạn 3) + [05_db_attendance.md](05_db_attendance.md) |
| **đánh giá hiệu suất / Performance Appraisal / KPI / Balanced Scorecard / BSC / Appraisals / BSC Targets / Probation Reviews / Gamification** | [10_workflow_performance.md](10_workflow_performance.md) |
| **thử việc / probation / đánh giá thử việc** | [10_workflow_performance.md](10_workflow_performance.md) (section 3) |
| **phân quyền / permission / role / group quyền / `tblSC_Object` / `tblSC_GroupRight` / data scope / `FullAccess` / Permissions / Groups / Department Views Access** | [11_permissions.md](11_permissions.md) |
| **3 nền tảng / web app / mobile app / desktop / ESS / Self-Service / Client Platforms / Windows Desktop / Mobile ESS** | [01_architecture.md](01_architecture.md) |
| **thông báo mobile / push notification / Firebase / FCM / token thiết bị / `tblDeviceCodeInfo` / `tblEmailList.EmailType=10` / `sp_RegisterDeviceInfo` / `api_GetNotificationForEmployee` / Mobile Push / FCM token mappings** | [16_mobile_notification.md](16_mobile_notification.md) |
| **giao việc / task management / công việc / approval task / TaskTimeLine / MyWork / subtask / template task / recurring task / `tblTask_Tasks` / `HistoryID` / history-versioning / `tblTask_Approvals` StageOrder / `NotifycationSendID` 1/2/4/6 / SignalR Task / phân biệt với `TaskSchedule` cron và `tblLabourAssignTask` sản xuất / Giao Việc (Tasks) / Project Scopes / Stage Approvals** | [19_TaskAssignment.md](19_TaskAssignment.md) |
| **rich text editor / soạn thảo văn bản / `hpaControlRichTextEditorPremium` / Base64 UTF-16LE / `getHtml` `setHtml` / decode HTML / encode HTML / `rteObj_` / `xs:base64Binary` / `utf16_le_to_b64_` / UTF-16LE conversion** | [richtext.md](richtext.md) |
| **python tool / viết Python script / SyntaxError / unterminated string literal / PowerShell unexpected token / escape triple quote / Python Tool Safety / CLI safety** | [29_PythonToolSafety.md](29_PythonToolSafety.md) |
| **email batch / gửi email hàng loạt / `sp_EmailSendingByDuc` / `@BatchJson` / Graph API `$batch` / Microsoft 365 mail / gửi mail tự động / retry email lỗi / `tblEmailList` log email / Batching Emails** | [email_batching_guide.md](email_batching_guide.md) |
| **load avatar / ảnh nhân viên / `GlobalEmployeeAvatarCache` / `paramImg` / `loadEmployeeAvatarAsync` / `loadEmployeeAvatarsBatch` / blob avatar / avatar stack / `fn_GetStringParamImageByEmployeeID` / SVG default avatar / avatar cache / Avatar Loading / lazy loading** | [LOAD_EMPLOYEE_AVATAR_GUIDE.md](LOAD_EMPLOYEE_AVATAR_GUIDE.md) |
| **chọn loại control / format ngày tháng trên lưới / format tiền tệ trên lưới / format giờ phút / hpaControlDate format / hpaControlDateTime format / hpaControlMoney format / quy tắc chọn control input grid / `_autoSave` `_readOnly` runtime / Control Guidelines / column format** | [25.HPA_Controls_Guidelines.md](25.HPA_Controls_Guidelines.md) |
| **tối ưu hiệu năng / procedure chạy chậm / query chậm / fix performance / QueryOptimization / missing index / execution plan / DMV / parameter sniffing / implicit conversion / scalar UDF chậm / statistics cũ / tạo index / tối ưu join / `sys.dm_exec_procedure_stats` / `sys.dm_db_missing_index_details` / SQL Performance / DMVs execution tracking** | [26_QueryOptimization.md](26_QueryOptimization.md) |
| **MCP lỗi / describe_table lỗi / list_databases lỗi / workaround MCP / `@bilims/mcp-sqlserver` bug / `sp_help` / INFORMATION_SCHEMA.COLUMNS / sys.databases / MCP Troubleshooting** | [27_MCP_Troubleshooting.md](27_MCP_Troubleshooting.md) |
| **tích hợp Zalo / Zalo cá nhân / Zalo OA / Zalo Official Account / gửi tin nhắn Zalo / gửi ảnh Zalo / đồng bộ Zalo / Zalo Client API / `sp_CallAPIZalo` / `ss_RequestHttp_Zalo` / `sp_ZaloSendSMSPaySlipForEmployeeID` / `sp_ZaloSendSMSForRemainFollower` / OLE Automation Zalo / upload ảnh Zalo / Zalo Integration** | [28_Zalo_Integration.md](28_Zalo_Integration.md) |
| **Zalo Web Official / chat.zalo.me / socket realtime connection / 7 Web Workers / mainless-worker / soc-worker / zd-worker / dal-worker / trust-worker / opfs-worker / libsignal-protocol / e2ee_identity / e2ee_session / e2ee_prekey / e2ee_signed_prekey / e2ee_group / zdb_ / msginfo_ / e2ee_ / media_ / r_db_ / sidx_ / sync_ / message store schema / cliMsgIdIndex / msgType_sendDttm / status_sendDttm / userId_msgType_sendDttm / stkw keyword / stidx keywordId / stcont search text / fallback HTTP polling / E2EE Signal Protocol / Optimistic UI / Chrome DevTools Protocol remote debugging** | [29_zalo_web_Official.md](29_zalo_web_Official.md) |
| **So sánh Zalo / so sánh Paradise Zalo vs Zalo Official / Plaintext vs E2EE / REST API vs WebSocket / Realtime Connection / Realtime ACK / OLE Automation security risk / Zalo Web endpoints / cookie session QR** | [soSanhZaloParadiseVS_ZaloOffficial.md](soSanhZaloParadiseVS_ZaloOffficial.md) |

---

## 3. Database Table to File Mappings
*   `tblEmployee`, `tblFamilyInfo`, `tblBinaryForEmployee`: [02_db_employee.md](02_db_employee.md)
*   `tblEmployeeStatusHistory`, `tblDivDepSecPos`, `tmpEmployeeTree`: [15_employee_query_apis.md](15_employee_query_apis.md)
*   `tblLabourContract`, `tblMST_ContractType`, `tblRepresentativeSetting`: [03_db_contract.md](03_db_contract.md)
*   `USERINFO`, `TEMPLATE`, `FaceTemp`, `MachinesBadgeNumberUploaded`: [04_db_biometric.md](04_db_biometric.md)
*   `CHECKINOUT`, `tblTmpAttend`, `tblHasTA`, `tblAttendanceConfirmRequest`: [05_db_attendance.md](05_db_attendance.md)
*   `tblSC_Login`, `tblUserPasswordHistory`: [06_db_login_account.md](06_db_login_account.md)
*   `MEN_Menu`, `tblHtmlScriptCache`, `tblCommonControlType_Signed`: [07_menu_system.md](07_menu_system.md) / [20_ControlSystem.md](20_ControlSystem.md)
*   `tblCRM_CompanyInfo`, `tblCRM_CustomerPersonInfo`, `tblCRM_Contract`: [08_workflow_crm.md](08_workflow_crm.md)
*   `tblSal_Lock`, `tblSal_Sal`, `tblUnionFeeMethod`, `tblSal_Insurance`: [09_workflow_payroll.md](09_workflow_payroll.md)
*   `tblPerformanceAppraisal`, `tblKPITarget`, `tblPROBATIONASSESSEMENT`: [10_workflow_performance.md](10_workflow_performance.md)
*   `tblSC_Right_Stored`, `tblUserGrantGroup`, `tblSC_DepartmentView_Group`: [11_permissions.md](11_permissions.md)
*   `tblDeviceCodeInfo`, `tblEmailList`, `tblNotificationLocal`, `TaskSchedule`: [16_mobile_notification.md](16_mobile_notification.md)
*   `tblTasks`, `tblTask_Tasks`, `tblTask_Approvals`, `tblTask_Checklists`: [19_TaskAssignment.md](19_TaskAssignment.md)
*   `tblZalo_User`, `tblZaloQR`, `tblZaloClientFriends`: [28_Zalo_Integration.md](28_Zalo_Integration.md)

---

## 4. Backing Procedures Mapping
*   `sp_CrystalRptLabourContract`, `Print_LabourContract_List`: [03_db_contract.md](03_db_contract.md)
*   `TA_Process_Main`, `TA_Calculate_WorkingTime`, `sp_ShiftDetector*`: [05_db_attendance.md](05_db_attendance.md)
*   `SC_User_Insert`, `SC_Login_CheckLogin`, `SC_UserPassword_Update`: [06_db_login_account.md](06_db_login_account.md)
*   `sp_s_CreateMenu`, `sp_GenerateHTMLScript`, `sptblCommonControlType_Signed_DUC`: [07_menu_system.md](07_menu_system.md)
*   `sp_CRM_SaveLead`, `sp_ExecuteDateCRMDataCollection`, `sp_CRM_RecalculateKPI`: [08_workflow_crm.md](08_workflow_crm.md)
*   `SALCAL_MAIN`, `sp_CreateSalaryInsurance`, `rpt_PR_SalaryToBank`: [09_workflow_payroll.md](09_workflow_payroll.md)
*   `sp_ImportKPI`, `sp_BonusKPI`, `sp_ExportPROBATIONASSESSEMENT`: [10_workflow_performance.md](10_workflow_performance.md)
*   `sp_Common_GetUserPermissions`, `SC_USEROBJECTRIGHT_GET`, `LoadUserRightTree`: [11_permissions.md](11_permissions.md)
*   `fn_vtblEmployeeList_Bydate`, `sp_getEmployeeListWithPermission`: [15_employee_query_apis.md](15_employee_query_apis.md)
*   `sp_RegisterDeviceInfo`, `sp_ProcessNotificationLocal`, `api_GetNotificationForEmployee`: [16_mobile_notification.md](16_mobile_notification.md)
*   `sp_Task_Save`, `sp_Task_CompleteTask`, `sp_Task_ApproveTask`: [19_TaskAssignment.md](19_TaskAssignment.md)
*   `sp_CallAPIZalo`, `sp_ZaloContactBook`: [28_Zalo_Integration.md](28_Zalo_Integration.md)
*   `sp_EmailSendingByDuc`: [email_batching_guide.md](email_batching_guide.md)
*   `fn_GetStringParamImageByEmployeeID`: [LOAD_EMPLOYEE_AVATAR_GUIDE.md](LOAD_EMPLOYEE_AVATAR_GUIDE.md)