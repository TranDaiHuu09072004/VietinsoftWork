# 06 — Database: Login Accounts & Access Credentials

Reference: [02_db_employee.md](02_db_employee.md) (linked via `EmployeeID`), [11_permissions.md](11_permissions.md) (Access Rights & Permissions).

## 1. Master Table: `tblSC_Login`
Houses access accounts for Web, Desktop, and Mobile clients.

### Framework User Systems Comparison
| Feature | `tblSC_Login` (App Account) | `USERINFO` (Hardware Biometric User) |
|---|---|---|
| **Purpose** | Access ParadiseHR application | Authenticate on physical terminal readers |
| **PK** | `LoginID` (int identity) | `USERID` (int) |
| **Relation** | `EmployeeID` -> `tblEmployee.EmployeeID` | `BADGENUMBER` -> `tblEmployee.EmployeeID` |
| **Credential** | `PassWord` (salted hash) | `PASSWORD`, `VerifyCode` (numeric pin on machine) |

### Key Columns in `tblSC_Login`
*   **Mandatory fields**: `LoginName` (unique string), `PassWord` (encrypted hash), `EmployeeID`, `DepartmentID`.
*   **Permission flags**: `IsDisable`, `IsActive`, `ActiveWeb`, `AdminRight`, `isAdmin`, `IsHRManager`, `IsBigBoss`, `IsSelfService` (Employee-only portals), `IsAuditAccount`, `IsGroup`, `ParentLoginID`, `UseGroupRightOnly`, `AlwaysFullAccess`.
*   **Security & Brute-Force locks**: `IsLockout`, `AttemptCounter`, `LastAttemptsTime`.
*   **MFA / 2FA**: `TwoStepVerification`, `TwoStepPasscode`, `OTP_KEY`, `OTP_NAME`, `OTP_QR`, `TokenID`, `SecretKey`, `AccountName`, `Issuer`.
*   **Federation / SSO**: `DomainLoginName` (Active Directory login name).

## 2. Core Stored Procedures
*   `SC_User_Insert` (`@p_LoginName`, `@p_Password`, `@p_EmployeeID`, `@p_DepartmentID`, `@p_Retval OUTPUT`): Creates an account. Output values: `1` (Success), `0` (DB error), `-1` (LoginName exists).
*   `SC_User_Update` / `SC_User_Delete` / `SC_User_List`: Updates, deletes, and lists user accounts.
*   `SC_UserPassword_Update` / `sp_User_ChangePassWord_Action` / `ForgotPasswordForm`: Manage password changes and resets.
*   `SC_Login_CheckLogin` / `Login` / `spParadiseLogin`: Standard authentication hooks.
*   `sp_GetEmployeeLogin` / `sp_GetEmployeeInforByLoginID`: Fetches employee profiles mapping to current Login ID.

## 3. Account Permission Schemas
`tblSC_Login` provides authentication; permissions are managed across authorization satellite tables (see [11_permissions.md](11_permissions.md)):
*   `tblSC_Group` / `tblSC_GroupMember`: Group definitions and memberships.
*   `tblSC_GroupRight` / `tblSC_Right_ByLoginID`: Group-level and user-level menu/object access rules.
*   `tblSC_GroupView` / `tblSC_DepartmentView_Group` / `tblSC_SectionView_Group`: Data visibility boundaries (filter limits on Departments, Division, Sections, Groups).
*   *Assign Procedure*: `sp_tblSC_LoginWithGroupSaver`, `SC_UserObjects_Save`, `SC_UserDeptViewInfo_Save`, `sp_Common_GetUserPermissions`.

## 4. SQL Usage Examples
```sql
-- Create a new account
DECLARE @Ret int;
EXEC dbo.SC_User_Insert
     @p_LoginName    = 'nv001',
     @p_Password     = '<encrypted_hash>',  -- Never pass plain text
     @p_EmployeeID   = 'EMP001',
     @p_DepartmentID = '10',
     @p_Retval       = @Ret OUTPUT;
SELECT @Ret AS CreateResult; -- 1=Success, -1=Duplicate LoginName, 0=DB Error

-- Fetch account info by EmployeeID
SELECT LoginID, LoginName, EmployeeID, isAdmin, IsHRManager, IsDisable, IsLockout, ActiveWeb, IsSelfService
FROM tblSC_Login
WHERE EmployeeID = N'<EmployeeID>';

-- Identify employees lacking account credentials
SELECT e.EmployeeID, e.FullName
FROM tblEmployee e
LEFT JOIN tblSC_Login l ON l.EmployeeID = e.EmployeeID
WHERE l.LoginID IS NULL;
```
