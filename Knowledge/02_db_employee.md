# 02 — Database: Employee Profiles

Reference: [03_db_contract.md](03_db_contract.md) (Contract link), [04_db_biometric.md](04_db_biometric.md) (Biometrics), [06_db_login_account.md](06_db_login_account.md) (Accounts), [15_employee_query_apis.md](15_employee_query_apis.md) (Query functions: `fn_vtblEmployeeList_Bydate`, `sp_getEmployeeListWithPermission`).

## 1. Master Table: `tblEmployee`
Primary Key: `EmployeeID` (varchar).
*   **Identity**: `FullName`, `LastName`, `FirstName`, `CallName`, `Title`, `TitleID`, `Sex`, `Birthday`, `BirthPlace`, `BirthPlaceEN`, `BirthPlaceProvinceID`, `NationID`, `EthnicID`, `ReligionID`, `MaritalStatusID`, `BloodTypeID`.
*   **Documents**: `ID_Number`, `ID_Issue_Date`, `ID_Issue_Place`, `ID_Issue_PlaceEN`, `ID_ProvinceID`; `LBNo`, `LB_IssueDate`, `LB_ExpireDate`, `LB_Issue_Place` (Work Permit); `TaxRegNo`, `TaxRegDate`, `TaxRegPlace`; `SocialNo` (Social Insurance Book).
*   **Contact**: `BusinessPhone`, `Extension`, `MobilePhone`, `HomePhone`, `FaxNumber`, `Email`, `HomeEmail`, `TelegramChatID`.
*   **Emergency**: `EmergencyContact`, `EmergencyContact_RelationID`, `EmergencyContact_Address`, `EmergencyContact_HomePhone`, `EmergencyContact_CellPhone`.
*   **Address**: `ResidentAdd`/`ResidentAddEN`, `WardID`/`Ward`, `DistrictID`, `ProvinceID`, `ZipCode`; `tmpAddress*` (Temporary).
*   **Organization**: `AreaID`, `BranchID`, `LineManagerID`, `AreaSupID`, `DirectReport`, `NewCostCenter`, `OldCostCenter`, `DivisionTAD`, `OccupationID`, `RateID`, `Ranking`.
*   **Milestones**: `HireDate`, `RenewHireDate`, `FirstJoinDate`, `SignedDate`, `ProbationStartDate`, `ProbationEndDate`, `ContractFirstDate`, `TrainingDate`, `SocialJoinDate`, `Official` (0/1), `TerminateReasonID`, `ReasonTerminateInterviewID`, `LastResignedUpdateDate`.
*   **Education**: `EducationalBase`, `FinalEducationID`, `HighestEducationID`, `FinalUniversity`/`FinalUniversityEN`, `TypeSchoolID`, `GraduateYear`, `ProfessionalID`, `OtherEducation`, `WorkingExperience`, `WorkedStartYear`.
*   **Payroll & Bank**: `PaymentID`, `BankCode`, `AccountNo`, `AccountName`, `IDForBankTransfer`, `BankQR`, `PIT20Percent`, `BenefitInsurance`, `EmpInsuranceStatusID`.
*   **Leave & Attendance**: `WorkingTimePercent`, `WHPerWeek`, `StdWorkingDay`, `ALBudget`, `ALHazard`, `HR_AL_CARRY_MAX`, `LATE_PERMIT`, `TAOptionID`, `InOutFreedom`.
*   **Classifiers**: `IsWorker`, `IsCashHandler`, `IsContact`, `IsShuttle`, `IsSo`, `LocalExpat`, `PrintCard`, `SizeID`.
*   **System Accounts**: `LoginName`, `username`, `GoogleAuthenticatorID`, `FunctionString`.
*   **Binary Assets**: `PhotoImage` (varbinary(MAX)), `PhotoImageVersion`, `ImageLocation`, `ChopImage`, `SignImage`.
*   **Audit**: `InputDate`, `LastUpdateDate`, `EmployeeIDOld`, `BasicInfoNotes`, `HomeNotes`, `SendNotifyEmailToDepartments`.

## 2. Satellite Tables (FKey `EmployeeID`)
*   **Family**: `tblFamilyInfo`, `tblFamilyInfo_Adjustment` (dependents).
*   **History & Status**: `tblEducationHistory`, `tblExperience` (past work), `tblEmployeeSkill` (certifications), `tblEmployeeHealth`, `tblEmployeeAccident`, `tblEmployeeStatus`, `tblEmployeeStatusHistory`, `tblEmployeeType`, `tblEmployeeTypeHistory` (Probation/Official history), `tblEmployeeWorkerHistory` (worker category).
*   **Union & Compensation**: `tblEmployeeUnion`, `tblEmployeeUnionHistory`, `tblEmployeeAllowance`, `tblEmployeeAnnual` (annual leave history), `tblAllowanceRuleAssignedEmployee`.
*   **Attachments**: `tblEmployeeID_Docs`, `tblBinaryForEmployee` (scanned docs / binaries).
*   **Offers & Position**: `tblEmployeeOffer`, `tblEmployeeOfferExtend`, `tblContractResponsibility`.
*   **User Preferences**: `tblEmployeeAvatarFrame`, `tblEmployee_Options_List`, `tblEmployee_Options_Setting`, `tblEmployeeSelfService`.

## 3. Sample Query
Avoid `SELECT *` due to heavy `varbinary` fields (`PhotoImage`, `BankQR`, `ChopImage`, `SignImage`).
```sql
SELECT EmployeeID, FullName, Sex, Birthday, ID_Number, MobilePhone, Email, HireDate, Official, BranchID, AreaID, LineManagerID
FROM tblEmployee
WHERE EmployeeID = N'<EmployeeID>';
```
