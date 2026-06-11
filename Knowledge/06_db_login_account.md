# 06 — Database: Tài khoản đăng nhập ParadiseHR (Login Account)

> Schema bảng `tblSC_Login` + procedure quản lý tài khoản. Liên quan: [11_permissions.md](11_permissions.md) (phân quyền chi tiết), [02_db_employee.md](02_db_employee.md) (link qua `EmployeeID`).

## Bảng chính: `tblSC_Login`

Tài khoản đăng nhập **phần mềm ParadiseHR** (web/desktop/mobile).

### Lưu ý quan trọng — phân biệt 2 hệ user

| | `tblSC_Login` | `USERINFO` (xem [04_db_biometric.md](04_db_biometric.md)) |
|---|---|---|
| Mục đích | Đăng nhập phần mềm ParadiseHR | User trên máy chấm công (sinh trắc học) |
| Khoá nội bộ | `LoginID` | `USERID` |
| Link nhân viên | `EmployeeID` → `tblEmployee.EmployeeID` | `BADGENUMBER` → `tblEmployee.EmployeeID` |
| Mật khẩu | `PassWord` (mã hoá, mật khẩu web) | `PASSWORD`, `MVerifyPass` (mật khẩu nhập trên máy) |

## Cấu trúc `tblSC_Login`

- Khoá chính: `LoginID` (int identity).
- **Bắt buộc khi tạo**: `LoginName` (unique), `PassWord` (đã mã hoá), `EmployeeID`, `DepartmentID`.
- **Cờ quyền/trạng thái**: `IsDisable`, `IsActive`, `ActiveWeb`, `AdminRight`, `isAdmin`, `IsHRManager`, `IsBigBoss`, `IsSelfService`, `IsAuditAccount`, `IsGroup`, `ParentLoginID`, `UseGroupRightOnly`, `AlwaysFullAccess`.
- **Khoá tài khoản (brute-force)**: `IsLockout`, `AttemptCounter`, `LastAttemptsTime`.
- **2FA / OTP**: `TwoStepVerification`, `TwoStepPasscode`, `OTP_KEY`, `OTP_NAME`, `OTP_QR`, `TokenID`, `SecretKey`, `AccountName`, `Issuer`, `SentEmailSecretKey`.
- **SSO/AD**: `DomainLoginName`.
- **Khác**: `NeedEncryptPassWordColumnList`, `ServerURI`, `MobilePhone`, `ParadiseLogOutTimeOut`, `LastChangedDate`, `Remark`, `CanApprovePublishPS`, `isCustomer`.

## Procedure quản lý tài khoản

| Procedure | Mục đích |
|---|---|
| **`SC_User_Insert`** | **Tạo user mới** — insert vào `tblSC_Login`. Param: `@p_LoginName`, `@p_Password`, `@p_EmployeeID`, `@p_DepartmentID`, `@p_Retval OUTPUT` (1=OK, 0=lỗi DB, -1=trùng `LoginName`) |
| `SC_User_Update` | Cập nhật thông tin user |
| `SC_User_Delete` | Xoá user |
| `SC_User_List`, `sp_UserManagementList`, `sp_LoginList` | Danh sách user (UI quản trị) |
| `sp_CheckExistsUser` | Kiểm tra `LoginName` đã tồn tại |
| `SC_UserPassword_Update`, `sp_ChangePasswordForm`, `sp_User_ChangePassWord_Action`, `sp_User_ChangePassWord_Validation`, `sp_User_ChangePassWord_Before_Save` | Đổi mật khẩu |
| `ChangePasswordReset`, `ForgotPassword`, `ForgotPasswordForm`, `ss_ResetPassword`, `ssResetPassword`, `ssForgotPasswordGetEmail` | Quên / reset mật khẩu |
| `SetInitialPasswordForm` | Set mật khẩu khởi tạo |
| `sp_ChangeLoginName` | Đổi `LoginName` |
| `sp_UpdateEmployeeIDLoginNew`, `sp_DeleteEmployeeIDLoginNew` | Sync khi đổi/xoá `EmployeeID` của hồ sơ |
| `sp_SendEmailNewAccount` | Gửi email báo tài khoản mới |
| `sp_PasswordPolicyConfig`, `sp_PasswordPolicyConfig_Save`, `sp_PasswordPolicyInfo`, `ValidatePassword` | Chính sách & validate mật khẩu |
| `sp_UserPasswordHistory_Save` + bảng `tblUserPasswordHistory` | Lịch sử mật khẩu (chặn dùng lại) |
| `sp_CreatePasswordEncrypt_viaAPI`, `ssEncryptPasswordBulkData` | Mã hoá mật khẩu trước khi lưu |
| `SC_Login_CheckLogin`, `SC_Login_CheckLogin_Finish`, `SC_Login_GetLoginID`, `Login`, `spParadiseLogin`, `ssThirdPartyLogin` | Xử lý khi đăng nhập |
| `sp_GetEmployeeLogin`, `sp_GetEmployeeInforByLoginID`, `sp_getInfoEmployeeAccount` | Lấy thông tin nhân viên/tài khoản theo LoginID |
| `sp_GetOrInsertExternalUserByEmail` | Tạo user từ email (login bên ngoài) |

## Phân quyền sau khi tạo user

`tblSC_Login` chỉ là tài khoản — quyền truy cập menu/chức năng/phạm vi xem nằm ở các bảng `tblSC_*` riêng. **Xem chi tiết tại [11_permissions.md](11_permissions.md).**

Tóm tắt các bảng:

| Bảng | Mục đích |
|---|---|
| `tblSC_Group`, `tblSC_GroupMember` | Group quyền & danh sách user trong group |
| `tblSC_GroupRight` | Quyền của group (đối tượng / menu) |
| `tblSC_GroupView`, `tblSC_DepartmentView_Group`, `tblSC_SectionView_Group`, `tblSC_GroupView_Group` | Phạm vi xem (phòng ban / section) của group |
| `tblSC_Right_ByLoginID` | Quyền gán trực tiếp theo từng `LoginID` (override group) |
| `tblUserGrantGroup`, `tblUserRightGroup` | Group cấp quyền |

Procedure gán quyền: `sp_tblSC_LoginWithGroupSaver`, `SC_UserObjects_Save`, `SC_UserDeptViewInfo_Save`, `SC_UserDivViewInfo_Save`, `SC_UserSectViewInfo_Save`, `SC_UserGroupViewInfo_Save`, `sp_UpdateMenuInUserRight`, `sp_UserAccessRight`, `sp_Common_GetUserPermissions`.

## Câu SQL mẫu

```sql
-- Tạo user mới qua procedure chuẩn
DECLARE @Retval int;
EXEC dbo.SC_User_Insert
     @p_LoginName    = 'nv001',
     @p_Password     = '<encrypted_pwd>',  -- KHÔNG insert plain text
     @p_EmployeeID   = 'EMP001',
     @p_DepartmentID = '10',
     @p_Retval       = @Retval OUTPUT;
SELECT @Retval AS Result;  -- 1=OK, 0=lỗi, -1=LoginName đã tồn tại

-- Lấy tài khoản theo EmployeeID
SELECT LoginID, LoginName, EmployeeID, DepartmentID, isAdmin, IsHRManager,
       IsDisable, IsLockout, ActiveWeb, IsSelfService
FROM tblSC_Login
WHERE EmployeeID = N'<EmployeeID>';

-- Danh sách nhân viên CHƯA có tài khoản đăng nhập
SELECT e.EmployeeID, e.FullName
FROM tblEmployee e
LEFT JOIN tblSC_Login l ON l.EmployeeID = e.EmployeeID
WHERE l.LoginID IS NULL;
```

> Lưu ý bảo mật:
> - Mật khẩu **phải mã hoá** trước khi truyền vào `@p_Password` (dùng `sp_CreatePasswordEncrypt_viaAPI` hoặc cơ chế của tầng app).
> - Cột `NeedEncryptPassWordColumnList` chỉ định danh sách cột mật khẩu khác cần mã hoá kèm theo.
> - Khoá tài khoản sau N lần sai dựa vào `IsLockout` + `AttemptCounter`.
