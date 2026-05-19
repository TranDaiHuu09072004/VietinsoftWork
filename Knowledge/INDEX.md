# INDEX — Chỉ mục Knowledge Base ParadiseHR

> **Agent đọc file này TRƯỚC khi tra cứu.** Bảng dưới giúp tìm đúng file Knowledge chứa tri thức cần thiết, không phải đọc toàn bộ.
>
> Sau khi xác định được file mục tiêu, dùng `Read` mở file đó. Nếu thông tin chưa đủ → query MCP `mssql-vietinsoft` để xác minh từ DB thực tế, rồi cập nhật file Knowledge tương ứng.

---

## 1. Danh sách file Knowledge

| File | Chủ đề chính | Khi nào dùng |
|---|---|---|
| [00_quick_context.md](00_quick_context.md) | Tổng quan dự án ParadiseHR, repo, nguồn dữ liệu | Session mới, cần biết bối cảnh |
| [01_architecture.md](01_architecture.md) | 3 nền tảng (Desktop / Web / Mobile), ESS, cờ tách nền tảng | Hỏi về platform, ESS, cờ menu theo nền tảng |
| [02_db_employee.md](02_db_employee.md) | Bảng `tblEmployee` + bảng vệ tinh hồ sơ NV | Hỏi về hồ sơ nhân viên, gia đình, học vấn, kinh nghiệm |
| [03_db_contract.md](03_db_contract.md) | Hợp đồng lao động — `tblLabourContract` + procedure in HĐ | Hỏi về hợp đồng, in HĐ, loại HĐ |
| [04_db_biometric.md](04_db_biometric.md) | Vân tay, khuôn mặt, palm (ZKTeco), `USERINFO`, `TEMPLATE`, `FaceTemp` | Hỏi về sinh trắc học, đăng ký vân tay/khuôn mặt |
| [05_db_attendance.md](05_db_attendance.md) | 5 kênh chấm công + pipeline `tblTmpAttend` → `tblHasTA` → `tblSal_AttendanceData` | Hỏi về chấm công, log raw, pipeline xử lý, GPS/Wifi mobile |
| [06_db_login_account.md](06_db_login_account.md) | `tblSC_Login` — tài khoản đăng nhập ParadiseHR | Hỏi về tạo user, mật khẩu, 2FA, login flow |
| [07_menu_system.md](07_menu_system.md) | Toàn bộ logic menu: 5 mảnh dữ liệu, `sp_s_CreateMenu`, HTML cache, ví dụ MnuHRS142 & MnuKPI007 | Hỏi về tạo menu, sửa menu, giao diện desktop/web, HTML cache, ParadiseWebView2 |
| [08_workflow_crm.md](08_workflow_crm.md) | Module CRM: lead → khách hàng → hợp đồng → KPI CRM | Hỏi về CRM, lead, customer, sales pipeline, KPI sale |
| [09_workflow_payroll.md](09_workflow_payroll.md) | Pipeline tính lương 10 giai đoạn — `SALCAL_MAIN`, BHXH, thuế, payslip | Hỏi về tính lương, lương cuối tháng, BHXH, thuế TNCN, bank file, payslip |
| [10_workflow_performance.md](10_workflow_performance.md) | 5 hệ thống đánh giá: Performance Appraisal, KPI, Probation, Gamification, CRM KPI | Hỏi về đánh giá hiệu suất, KPI, đánh giá thử việc, xếp hạng |
| [11_permissions.md](11_permissions.md) | Phân quyền — RBAC + Data scope + Inheritance | Hỏi về phân quyền, role, group, quyền user |

---

## 2. Map từ khoá tiếng Việt → file

| Từ khoá | File chính |
|---|---|
| **nhân viên / hồ sơ / employee** | [02_db_employee.md](02_db_employee.md) |
| **gia đình / phụ thuộc / dependant** | [02_db_employee.md](02_db_employee.md) |
| **hợp đồng / contract / in hợp đồng** | [03_db_contract.md](03_db_contract.md) |
| **vân tay / khuôn mặt / sinh trắc / biometric / face / fingerprint** | [04_db_biometric.md](04_db_biometric.md) |
| **chấm công / attendance / GPS / Wifi / IO card / `tblTmpAttend` / `tblHasTA`** | [05_db_attendance.md](05_db_attendance.md) |
| **tạo user / đăng nhập / mật khẩu / login / `tblSC_Login`** | [06_db_login_account.md](06_db_login_account.md) |
| **menu / `MEN_Menu` / tạo menu / `sp_s_CreateMenu` / DataSetting / HTML cache / `tblHtmlScriptCache` / ParadiseWebView2** | [07_menu_system.md](07_menu_system.md) |
| **giao diện desktop / giao diện web** | [07_menu_system.md](07_menu_system.md) |
| **xếp hạng nhân viên / ranking / điểm kinh nghiệm / coin / XP** | [07_menu_system.md](07_menu_system.md) (section 10) |
| **Sales Pipeline / `MnuKPI007`** | [07_menu_system.md](07_menu_system.md) (section 13) |
| **CRM / lead / customer / sales pipeline / hợp đồng CRM / công nợ** | [08_workflow_crm.md](08_workflow_crm.md) |
| **tính lương / payroll / `SALCAL_MAIN` / phiếu lương / payslip / bank file / chuyển khoản** | [09_workflow_payroll.md](09_workflow_payroll.md) |
| **BHXH / BHYT / BHTN / bảo hiểm / Insurance** | [09_workflow_payroll.md](09_workflow_payroll.md) (giai đoạn 4) |
| **thuế / PIT / TNCN / quyết toán thuế** | [09_workflow_payroll.md](09_workflow_payroll.md) (giai đoạn 5) |
| **công đoàn / Union** | [09_workflow_payroll.md](09_workflow_payroll.md) (giai đoạn 6) |
| **OT / tăng ca / làm thêm giờ / overtime** | [09_workflow_payroll.md](09_workflow_payroll.md) (giai đoạn 3) + [05_db_attendance.md](05_db_attendance.md) |
| **đánh giá hiệu suất / Performance Appraisal / KPI / Balanced Scorecard / BSC** | [10_workflow_performance.md](10_workflow_performance.md) |
| **thử việc / probation / đánh giá thử việc** | [10_workflow_performance.md](10_workflow_performance.md) (section 3) |
| **phân quyền / permission / role / group quyền / `tblSC_Object` / `tblSC_GroupRight` / data scope / `FullAccess`** | [11_permissions.md](11_permissions.md) |
| **3 nền tảng / web app / mobile app / desktop / ESS / Self-Service** | [01_architecture.md](01_architecture.md) |

---

## 3. Map theo bảng (table) → file chứa info chi tiết

| Bảng | File |
|---|---|
| `tblEmployee` | [02_db_employee.md](02_db_employee.md) |
| `tblFamilyInfo`, `tblEducationHistory`, `tblExperience`, `tblEmployeeSkill`, `tblEmployeeHealth`, `tblEmployeeStatus`, `tblEmployeeType`, `tblEmployeeUnion`, `tblEmployeeAllowance`, `tblEmployeeOffer`, `tblEmployeeSelfService`, `tblBinaryForEmployee` | [02_db_employee.md](02_db_employee.md) |
| `tblLabourContract`, `tblMST_ContractType`, `tblContractResponsibility`, `tblRepresentativeSetting`, `tblCompany`, `tblChuyenMon` | [03_db_contract.md](03_db_contract.md) |
| `USERINFO`, `TEMPLATE`, `TEMPLATE_History`, `FaceTemp`, `FaceTemp_History`, `Palm`, `PalmTemp`, `Machines`, `MachinesBadgeNumberUploaded`, `tblWorkingDevice`, `tblDeviceCodeInfo`, `tblRegisterFingerPrintOnlineImage`, `tblPending_ProcessFaceTempFromEmployeePhoto` | [04_db_biometric.md](04_db_biometric.md) |
| `CHECKINOUT`, `tmpCHECKINOUT`, `tblTmpAttend`, `tblTmpAttendError`, `tblHasTA`, `tblAttendance_IOCard`, `tblAttendanceConfirmRequest`, `tblInsertAttendanceTime`, `tblCustomAttendanceData`, `tblMealAttendance`, `tblAttendanceRecord_MZH`, `tblAttendanceType`, `tblPendingTaProcessMain`, `tblRunningTaProcessMain`, `tblPendingImportAttend`, `tblAttendanceSummaryMonthly`, `tblSal_AttendanceData`, `tblSal_IO_Detail`, `tblEmployeeTAOptions`, `tblEmployeeAccessMachine`, `tblDepartmentAccessMachine`, `tblGPSOptionData`, `tblAttendanceAllSetting` | [05_db_attendance.md](05_db_attendance.md) |
| `tblSC_Login`, `tblUserPasswordHistory` | [06_db_login_account.md](06_db_login_account.md) |
| `MEN_Menu`, `tblSC_Object`, `tblMD_Message`, `tblDataSetting`, `tblDataSettingLayout`, `tblHtmlScriptCache`, `tblExportList`, `Menu_FrameSetting`, `tblContextMenu`, `tblWorkFlow`, `tblRank_PersonalRating_Detail`, `tblRank_PointType`, `tblRank_Coin_Wallet`, `tblRank_Coin_Transaction` | [07_menu_system.md](07_menu_system.md) |
| `tblCRM_CompanyInfo`, `tblCRM_CustomerPersonInfo`, `tblCRM_CustomerOwner`, `tblCRM_ContactCustommerStatus`, `tblCRM_NotesHistory`, `tblCRM_Contract`, `tblCRM_Contact_Detail`, `tblCRM_ContractType`, `tblCRM_ContractStatus`, `tblCRM_ContractPayment`, `tblCRM_KPI_Setup`, `tblCRM_KPI_Results`, `tblCRM_KPICategories`, `tblCRM_EmailKPI`, `tblCRM_KPIDataCollection`, `tblCRM_KPIContactActivity`, `tblCRM_KPIContent`, `tblCRM_KPIScheduleMeeting` | [08_workflow_crm.md](08_workflow_crm.md) |
| `tblSal_Lock`, `tblSal_Sal`, `tblSal_Sal_Detail`, `tblSal_NS`, `tblSal_NS_Detail`, `tblSal_OT`, `tblSal_OT_Detail`, `tblSal_IO`, `tblSal_Allowance`, `tblSal_Allowance_Detail`, `tblSal_Adjustment`, `tblSal_Insurance`, `tblSal_Tax`, `tblSal_PaidLeave`, `tblSal_Retro`, `tblSal_Advance`, `tblSal_Error`, `tblEmpInsuranceMonthly`, `tblPR_EmpAllowance`, `tblPR_Adjustment`, `tblSalaryHistory`, `tblSalary13`, `tblTetBonusPayment`, `tblYearlyBonusRate_MBN`, `tblTerminateAllowance`, `tblTax`, `tblTaxDeduction`, `tblTaxSetlement`, `tblPITforExpat`, `tblFamilyInfo_Adjustment`, `tblPIT_Adjustment_For_ChangedDependants`, `tblUnionFeeMethod`, `tblBonusKPI`, `tblEfficiencyBonus`, `tblPerformenceBonusPayment`, `tblCompanySalaryPayment`, `tblDanhSachDeNghiTangBHXH`, `tblDanhSachDeNghiGiamBHXH`, `tblDanhSachDieuChinhLuongBHXH`, `tblCutSIHistory_BHXH`, `tblHuongCheDoOmDau_BHXH`, `tblHuongCheDoThaiSan_BHXH`, `tblSI_SummaryHeader_BHXH`, `tblSISummaryInfo_BHXH`, `tblPrintA01FormListBHXH`, `tblSIPercentageHistory`, `tblLockDeclareInsuranceData_BHXH` | [09_workflow_payroll.md](09_workflow_payroll.md) |
| `tblPerformanceAppraisal`, `tblPerformanceAppraisal_Detail`, `tblPerformanceAppraisalPeriod`, `tblPerformanceAppraisalRating`, `tblPerformanceAppraisalModifyStatus`, `tblAppraisalItems`, `tblSubAppraisalItems`, `tblAppraisalPurpose`, `tblKPIStrategy`, `tblKPIPerspective`, `tblKPI_Items`, `tblKPITarget`, `tblKPIResultItem`, `tblPROBATIONASSESSEMENT` | [10_workflow_performance.md](10_workflow_performance.md) |
| `tblSC_Right`, `tblSC_Right_Stored`, `tblSC_GroupRight`, `tblSC_Group`, `tblSC_GroupMember`, `tblUserRightGroup`, `tblUserGrantGroup`, `tblSC_DepartmentView_Group`, `tblSC_SectionView_Group`, `tblSC_GroupView_Group`, `tblSC_Right_ByLoginID`, `tblSC_GroupView` | [11_permissions.md](11_permissions.md) |

---

## 4. Map theo procedure → file

| Procedure pattern | File |
|---|---|
| `sp_CrystalRptLabourContract`, `Print_LabourContract_List`, `sp_GetContractTemplate*` | [03_db_contract.md](03_db_contract.md) |
| `get_mobileatt_GPS`, `Import_CheckTime`, `sp_API_GetAttCheckin`, `api_getDataCheckInOutGPS`, `TA_Process_Main`, `TA_Calculate_WorkingTime`, `TA_Process_InLateOutEarly`, `TA_ProcessMain_*`, `sp_ShiftDetector*`, `sp_ProcessAttendanceSummaryMonthly`, `sp_AttendanceSummaryMonthly`, `sp_ApproveAttendanceRequest`, `ProcessNoti_RemindCheckInOut`, `sp_InsertPendingProcessAttendanceData` | [05_db_attendance.md](05_db_attendance.md) |
| `SC_User_Insert/Update/Delete`, `SC_Login_CheckLogin`, `Login`, `spParadiseLogin`, `sp_CheckExistsUser`, `SC_UserPassword_Update`, `ChangePasswordReset`, `ForgotPassword`, `sp_SendEmailNewAccount`, `sp_ChangeLoginName`, `sp_PasswordPolicyConfig`, `ValidatePassword`, `sp_CreatePasswordEncrypt_viaAPI` | [06_db_login_account.md](06_db_login_account.md) |
| `sp_s_CreateMenu`, `sp_Men_Menu_AfterSave*`, `sp_UpdateMenuInUserRight`, `sp_UpdateMenuName`, `[1rename_Mess]`, `sp_LoadMenuByMenuID`, `sp_Menu_Load*`, `MenuMobile`, `sp_Mobile_GetFullInfoMenu`, `sp_Mobile_GetLeftMenu`, `MenuSearch`, `sp_GenerateHTMLScript`, `sp_Train_Ranking_Template*`, `sp_Rank_getPersonalRating`, `sp_Rank_GetEmployeeDetail`, `sp_PerformanceKPI_Working_Process`, `sp_KPIProcessCustomer*` | [07_menu_system.md](07_menu_system.md) |
| `sp_CRM_SaveLead`, `sp_CRM_CreateLead`, `sp_ExecuteDateCRMDataCollection`, `sp_CRM_AddContract`, `sp_CRM_SaveContract`, `sp_CRM_GetCustomerList`, `sp_CRM_LeadList`, `sp_CRM_LoadCustomerDetail_*`, `sp_CRM_RecalculateKPI`, `sp_CRMDashboard`, `sp_CRMCreateOutlookEvent` | [08_workflow_crm.md](08_workflow_crm.md) |
| `SALCAL_MAIN`, `SALCAL_IO_*`, `SALCAL_NS_*`, `SALCAL_OT_*`, `SALCAL_ALLOWANCE_*`, `SALCAL_ADJUSTMENT_*`, `SALCAL_INSURANCE`, `SALCAL_TAX_*`, `SALCAL_MONTHLYBASIC_FINISHED`, `SALCAL_PROCESS_MULTISALARY_LEVEL`, `SALCAL_LEAVE_AUTOMATIC_FINISHED`, `SAL_CAL_LEAVE_NEWCOMER`, `sp_CreateSalaryOT`, `sp_CreateSalaryInsurance`, `sp_AverageSISalary_ByEmployeeAmt`, `EmpInsuranceMonthly_*`, `LockAttendanceData_PreProcess`, `PR_Sal_Lock_*`, `PR_SalCal_GetError`, `sp_CheckLockSalByMonthAndYear`, `sp_CompletedAndLockInsuranceData_BHXH`, `sp_CompanySalarySummary*`, `sp_CompanySalaryReport`, `sp_CompanySalaryPayment_Process`, `rpt_PR_SalaryToBank`, `EmployeePaySlip_Links`, `Payslip_Send_Submitted`, `rpt_PR_PaySlip_PaidLeaveDetail`, `Import_PRAllowance`, `Import_Salary_Abroad`, `SAL_Advance_Process` | [09_workflow_payroll.md](09_workflow_payroll.md) |
| `sp_ImportKPI`, `sp_BonusKPI`, `sp_LockBonusKPI`, `sp_MailSumaryKPI`, `sp_KPIgetEmployeeKpiRanking`, `Gen_ProbationCommitment_List`, `sp_ColumnChangeProbationEndDate`, `sp_ExportPROBATIONASSESSEMENT` | [10_workflow_performance.md](10_workflow_performance.md) |
| `sp_Common_GetUserPermissions`, `SC_USEROBJECTRIGHT_GET`, `sp_SC_Right`, `sp_UserAccessRight`, `LoadUserRightTree`, `sp_tblSC_LoginWithGroupSaver`, `SC_UserObjects_Save`, `SC_UserDeptViewInfo_Save`, `SC_UserDivViewInfo_Save`, `SC_UserSectViewInfo_Save`, `SC_UserGroupViewInfo_Save` | [11_permissions.md](11_permissions.md) |

---

## 5. Cách dùng INDEX này (cho Agent)

1. Đọc câu hỏi của user, xác định **từ khoá nghiệp vụ** chính.
2. Tra bảng 2 (keyword → file) hoặc bảng 3 (table → file) hoặc bảng 4 (procedure → file).
3. Mở file Knowledge tương ứng bằng `Read`.
4. Nếu chưa đủ → query MCP `mssql-vietinsoft` để xác minh.
5. Cập nhật phát hiện mới vào đúng file Knowledge đã đọc (Self-Learning).
6. Nếu phát hiện chủ đề **chưa có file Knowledge nào phù hợp** → tạo file mới (đặt số tiếp theo, vd `12_xxx.md`) và cập nhật INDEX này.
