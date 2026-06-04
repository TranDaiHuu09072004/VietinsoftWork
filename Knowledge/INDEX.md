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
| [richtext.md](richtext.md) | Rich Text Editor | Premium editor base64 UTF-16LE conversion scripts. |
| [email_batching_guide.md](email_batching_guide.md) | Email Batching | Microsoft Graph API batch payloads (max 20 requests per call). |
| [LOAD_EMPLOYEE_AVATAR_GUIDE.md](LOAD_EMPLOYEE_AVATAR_GUIDE.md) | Avatar Loading | Default SVG to Blob async lazy loading and memory caching. |
| [99_deprecated.md](99_deprecated.md) | Deprecated | Obsolete schemas (ASPX pages, Zalo OA templates, legacy task tables). |

---

## 2. Keywords Directory
*   **Profiles, Dependents, Education, Bank Details**: [02_db_employee.md](02_db_employee.md)
*   **Subordinates, User Permission Subtree, Temporal Snapshot**: [15_employee_query_apis.md](15_employee_query_apis.md)
*   **Contracts, Representatives, Template Prints**: [03_db_contract.md](03_db_contract.md)
*   **Biometrics (Face/Fingerprint/Palm), Clock Terminals**: [04_db_biometric.md](04_db_biometric.md)
*   **Attendance, Raw Logs, GPS/Wifi Limits, Daily Calculation**: [05_db_attendance.md](05_db_attendance.md)
*   **Account, Login, Password Security, 2FA**: [06_db_login_account.md](06_db_login_account.md)
*   **Menu Registry, Caching, Assembly Settings**: [07_menu_system.md](07_menu_system.md)
*   **Create Menu**: [12_CreateMenu.md](12_CreateMenu.md) | **Migrate Menu**: [13_Migrate_Menu.md](13_Migrate_Menu.md)
*   **UI/UX Standard Styles, CSS Tokens, Layout Shells**: [14_ParadiseStyle.md](14_ParadiseStyle.md)
*   **Control Creation, Types Configuration, Binding APIs**: [20_ControlSystem.md](20_ControlSystem.md) | [25.HPA_Controls_Guidelines.md](25.HPA_Controls_Guidelines.md)
*   **SPA Transitions, Parameters Passing**: [21_SPA_Routing.md](21_SPA_Routing.md)
*   **Alerts, Confirmation Modals**: [22_UI_Helpers.md](22_UI_Helpers.md)
*   **AJAX Fetch, Binary Download**: [23_CallAPI.md](23_CallAPI.md)
*   **Escape SQL boundaries, Unicode boundaries, Varbinary streams**: [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md)
*   **Find Menu SPs, Debug Wrapper**: [18_FindMenuProcedure.md](18_FindMenuProcedure.md)
*   **CRM Sales Pipeline, Accounts, CRM KPI**: [08_workflow_crm.md](08_workflow_crm.md)
*   **Payroll Engine, Insurance calculation, PIT scale, Union Fees**: [09_workflow_payroll.md](09_workflow_payroll.md)
*   **Appraisals, BSC Targets, Probation Reviews, Gamification**: [10_workflow_performance.md](10_workflow_performance.md)
*   **Permissions, Groups, Department Views Access**: [11_permissions.md](11_permissions.md)
*   **Mobile push, Device registrations, SendPendingEmail**: [16_mobile_notification.md](16_mobile_notification.md)
*   **Giao Việc (Tasks), Project Scopes, Stage Approvals**: [19_TaskAssignment.md](19_TaskAssignment.md)
*   **Rich Text Editor, UTF-16LE conversion**: [richtext.md](richtext.md)
*   **Batching Emails**: [email_batching_guide.md](email_batching_guide.md)
*   **Avatar caching**: [LOAD_EMPLOYEE_AVATAR_GUIDE.md](LOAD_EMPLOYEE_AVATAR_GUIDE.md)
*   **SQL Performance, DMVs execution tracking, Indexing**: [26_QueryOptimization.md](26_QueryOptimization.md)
*   **Zalo Integration (QR Login, Friend List)**: [28_Zalo_Integration.md](28_Zalo_Integration.md)
*   **Zalo Web Client Specs**: [29_zalo_web_Official.md](29_zalo_web_Official.md)
*   **Zalo Clients Comparative**: [soSanhZaloParadiseVS_ZaloOffficial.md](soSanhZaloParadiseVS_ZaloOffficial.md)
*   **MCP Troubleshooting**: [27_MCP_Troubleshooting.md](27_MCP_Troubleshooting.md)

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