# 02 — Database: Hồ sơ nhân viên (Employee)

> Schema bảng `tblEmployee` + các bảng vệ tinh. Liên quan: [03_db_contract.md](03_db_contract.md), [04_db_biometric.md](04_db_biometric.md), [06_db_login_account.md](06_db_login_account.md).
>
> 💡 **Cần lấy danh sách nhân viên runtime (theo ngày / theo quyền user / theo cây)?** Xem [15_employee_query_apis.md](15_employee_query_apis.md) — mô tả chi tiết `fn_vtblEmployeeList_Bydate` (snapshot as-of) và `sp_getEmployeeListWithPermission` (filter theo quyền) — đây là API trục được 575+ procedure khác dùng.

## 1. Hồ sơ nhân viên (Employee Profile)

**Bảng chính: `tblEmployee`** — lưu toàn bộ hồ sơ nhân viên (62 dòng tại thời điểm tra cứu).

- Khóa chính: `EmployeeID` (varchar) — mã nhân viên.
- ~135 cột, nhóm theo chủ đề:
  - **Định danh**: `FullName`, `LastName`, `FirstName`, `CallName`, `Title`, `TitleID`, `Sex`, `Birthday`, `BirthPlace` / `BirthPlaceEN`, `BirthPlaceProvinceID`, `NationID`, `EthnicID`, `ReligionID`, `MaritalStatusID`, `BloodTypeID`.
  - **Giấy tờ**: `ID_Number`, `ID_Issue_Date`, `ID_Issue_Place` / `ID_Issue_PlaceEN`, `ID_ProvinceID`; `LBNo`, `LB_IssueDate`, `LB_ExpireDate`, `LB_Issue_Place` (giấy phép lao động); `TaxRegNo`, `TaxRegDate`, `TaxRegPlace`; `SocialNo` (sổ BHXH).
  - **Liên hệ**: `BusinessPhone`, `Extension`, `MobilePhone`, `HomePhone`, `FaxNumber`, `Email`, `HomeEmail`, `TelegramChatID`.
  - **Liên hệ khẩn cấp**: `EmergencyContact`, `EmergencyContact_RelationID`, `EmergencyContact_Address`, `EmergencyContact_HomePhone`, `EmergencyContact_CellPhone`.
  - **Địa chỉ**: `ResidentAdd` / `ResidentAddEN`, `WardID`/`Ward`, `DistrictID`, `ProvinceID`, `ZipCode`; bộ `tmpAddress*` cho địa chỉ tạm trú.
  - **Tổ chức/phân công**: `AreaID`, `BranchID`, `LineManagerID`, `AreaSupID`, `DirectReport`, `NewCostCenter`, `OldCostCenter`, `DivisionTAD`, `OccupationID`, `RateID`, `Ranking`.
  - **Hợp đồng / mốc thời gian**: `HireDate`, `RenewHireDate`, `FirstJoinDate`, `SignedDate`, `ProbationStartDate`, `ProbationEndDate`, `ContractFirstDate`, `TrainingDate`, `SocialJoinDate`, `Official`, `TerminateReasonID`, `ReasonTerminateInterviewID`, `LastResignedUpdateDate`.
  - **Học vấn / nghề nghiệp**: `EducationalBase`, `FinalEducationID`, `HighestEducationID`, `FinalUniversity` / `FinalUniversityEN`, `TypeSchoolID`, `GraduateYear`, `ProfessionalID`, `OtherEducation`, `WorkingExperience`, `WorkedStartYear`.
  - **Lương / ngân hàng / thuế**: `PaymentID`, `BankCode`, `AccountNo`, `AccountName`, `IDForBankTransfer`, `BankQR`, `PIT20Percent`, `BenefitInsurance`, `EmpInsuranceStatusID`.
  - **Chế độ phép / chấm công**: `WorkingTimePercent`, `WHPerWeek`, `StdWorkingDay`, `ALBudget`, `ALHazard`, `HR_AL_CARRY_MAX`, `LATE_PERMIT`, `TAOptionID`, `InOutFreedom`.
  - **Phân loại đặc biệt**: `IsWorker`, `IsCashHandler`, `IsContact`, `IsShuttle`, `IsSo`, `LocalExpat`, `PrintCard`, `SizeID`.
  - **Tài khoản hệ thống**: `LoginName`, `username`, `GoogleAuthenticatorID`, `FunctionString`.
  - **Ảnh / chữ ký**: `PhotoImage` (varbinary), `PhotoImageVersion`, `ImageLocation`, `ChopImage`, `SignImage`.
  - **Audit**: `InputDate`, `LastUpdateDate`, `EmployeeIDOld`, `BasicInfoNotes`, `HomeNotes`, `SendNotifyEmailToDepartments`.

## 2. Bảng vệ tinh mở rộng hồ sơ nhân viên

Các bảng dưới đây bổ sung dữ liệu chi tiết cho hồ sơ, đều liên kết về `tblEmployee.EmployeeID`:

| Nhóm | Bảng | Mục đích |
|---|---|---|
| Gia đình / phụ thuộc | `tblFamilyInfo`, `tblFamilyInfo_Adjustment` | Người thân, người phụ thuộc giảm trừ thuế |
| Học vấn | `tblEducationHistory` | Quá trình học |
| Kinh nghiệm | `tblExperience` | Quá trình công tác trước khi vào công ty |
| Kỹ năng | `tblEmployeeSkill` | Kỹ năng / chứng chỉ chuyên môn |
| Sức khỏe / tai nạn | `tblEmployeeHealth`, `tblEmployeeAccident` | Khám sức khỏe, tai nạn lao động |
| Trạng thái nhân viên | `tblEmployeeStatus`, `tblEmployeeStatusHistory` | Trạng thái hiện tại + lịch sử |
| Loại nhân viên | `tblEmployeeType`, `tblEmployeeTypeHistory` | Chính thức / thử việc / thời vụ + lịch sử |
| Công nhân | `tblEmployeeWorkerHistory` | Lịch sử công nhân |
| Công đoàn | `tblEmployeeUnion`, `tblEmployeeUnionHistory` | Công đoàn |
| Phụ cấp / phép | `tblEmployeeAllowance`, `tblEmployeeAnnual`, `tblAllowanceRuleAssignedEmployee` | Phụ cấp, phép năm |
| Giấy tờ / file đính kèm | `tblEmployeeID_Docs`, `tblBinaryForEmployee` | Giấy tờ scan, file binary (ảnh / tài liệu) |
| Offer / hợp đồng | `tblEmployeeOffer`, `tblEmployeeOfferExtend`, `tblContractResponsibility` | Thư mời, gia hạn, trách nhiệm hợp đồng |
| Cá nhân hóa UI | `tblEmployeeAvatarFrame`, `tblEmployee_Options_List`, `tblEmployee_Options_Setting`, `tblEmployeeSelfService` | Tùy chọn cá nhân, self-service |

### Câu SQL mẫu — lấy thông tin tóm tắt 1 nhân viên

```sql
SELECT EmployeeID, FullName, Sex, Birthday, ID_Number,
       MobilePhone, Email, HireDate, Official,
       BranchID, AreaID, LineManagerID
FROM tblEmployee
WHERE EmployeeID = N'<EmployeeID>';
```

> Ghi chú: tránh `SELECT *` vì cột `PhotoImage` / `BankQR` / `ChopImage` / `SignImage` là `varbinary` nặng. Khi cần ảnh, lấy riêng theo `EmployeeID`.
