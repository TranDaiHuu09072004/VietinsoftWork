# 11 — User Permissions: RBAC & Data Scope

Reference: [06_db_login_account.md](06_db_login_account.md) (`tblSC_Login`), [07_menu_system.md](07_menu_system.md) (`MenuID` links), [15_employee_query_apis.md](15_employee_query_apis.md) (Data scope filters and `fn_Common_GetAccessID` implementation).

ParadiseHR implements Role-Based Access Control (RBAC) combined with Data Scope security filters and Login Parent chains.

## 1. Securable Objects
All securable features (menus, screens, reports) are mapped to **`tblSC_Object`** (`ObjectID`, `ObjectName`, `Description`, `MenuID`, `Visible`). Matching of application classes/templates to `ObjectID` is mapped in `tblExportList` (`TemplateFileName` -> `ObjectID`).

## 2. User Right Groups vs SC Groups
*   **User Right Group (RBAC Roles)**: Defs in `tblUserRightGroup` (`UserGroupID`, `UserGroupName`). Membership in `tblUserGrantGroup` (`UserID` [matches `LoginID` cast to varchar] + `UserGroupID`). Dictates functional access rules.
*   **SC Group (Data Scope Groups)**: Defs in `tblSC_Group` (`GroupID`, `GroupName`). Membership in `tblSC_GroupMember` (`GroupID` + `LoginID`). Defines employee groups whose records can be viewed/modified.

## 3. Four-Layer Access Resolution
Functional access permission uses the following hierarchy:
1.  **A. Bypass Flags** (`tblSC_Login`): `isAdmin = 1`, `AdminRight = 1`, `IsHRManager = 1`, `IsBigBoss = 1`, `AlwaysFullAccess = 1`. If active, bypasses validation.
2.  **B. Direct Permissions**: Individual user rules in `tblSC_Right_Stored` (`LoginID` + `ObjectID` -> `FullAccess`).
3.  **C. Group Permissions**: Inherited rules in `tblSC_GroupRight` (`UserGroupID` + `ObjectID` -> `FullAccess`).
4.  **D. Parent Inheritance**: Rules in `tblSC_Login.ParentLoginID` (a `&` delimited string of ancestor `LoginID`s). Automatically inherits all parent permissions.

### Quyền truy cập (Enum `FullAccess`)
*   `0`: Denied (No access).
*   `1`: Read-only.
*   `8`: Follow group (defer control to active User Right Groups).
*   `32`: Full access (read, write, delete).

## 4. Data Scope Filters (Data Visibility Limits)
Separate from functional rights, data scopes dictate whose employee files a login can view:
*   `tblSC_DepartmentView_Group` / `tblSC_SectionView_Group` / `tblSC_GroupView_Group`: Define which `UserGroupID` can access which departments, sections, or SC Groups. `ViewInfo = 1` yields access.
*   `tblSC_Right_ByLoginID`: Individual user scope overrides (`GroupID`, `SectionID`, `ViewInfo`).
*   `tblSC_DepartmentView` / `tblSC_SectionView`: User-specific data filters.

## 5. Security Resolution Process
1.  **Functional Right Resolution** (`SC_USEROBJECTRIGHT_GET`):
    *   Map `FullClassName` to `ObjectID` via `tblExportList` or `tblSC_Object`.
    *   Query `tblSC_Right_Stored` for direct `LoginID` permission.
    *   If `FullAccess` is NULL or `8`, join `tblUserGrantGroup` and `tblSC_GroupRight` to resolve group rights.
    *   Parse multiple rights via parent chain (`ParentLoginID`) split by `&` and return max access value (`32` > `1` > `0`).
2.  **Global Access Roles** (`sp_Common_GetUserPermissions`):
    *   Checks the `LoginID` and parent chain for meta-roles: `Full access` -> `isAdmin = 1`, `Manager access` -> `isAdmin = 1`, `Customer access` -> `isCustomer = 1`, `Users access` -> `isCustomer = 1`.

## 6. Administrative Operations
*   Assign Group: `sp_tblSC_LoginWithGroupSaver` writes to `tblUserGrantGroup`.
*   Assign Rights: `SC_UserObjects_Save` writes to `tblSC_Right` / `tblSC_Right_Stored`.
*   Assign Scope: `SC_UserDeptViewInfo_Save` / `SC_UserSectViewInfo_Save` / `SC_UserGroupViewInfo_Save` write to scope tables.

## 7. Diagnostics Queries
```sql
-- 1. Identify User Right Groups for a LoginName
SELECT l.LoginID, l.LoginName, urg.UserGroupID, urg.UserGroupName
FROM tblSC_Login l
LEFT JOIN tblUserGrantGroup ug ON ug.UserID = CAST(l.LoginID AS varchar)
LEFT JOIN tblUserRightGroup urg ON urg.UserGroupID = ug.UserGroupID
WHERE l.LoginName = 'nv001';

-- 2. List direct (override) permissions of a user
SELECT o.ObjectName, rs.FullAccess
FROM tblSC_Right_Stored rs
INNER JOIN tblSC_Object o ON o.ObjectID = rs.ObjectID
WHERE rs.LoginID = <LoginID>;

-- 3. Resolve functional right for a specific page/module
EXEC dbo.SC_USEROBJECTRIGHT_GET @p_FullClassName = 'MenuID_Or_ClassName', @p_LoginID = <LoginID>;

-- 4. Fetch global access meta-roles
EXEC dbo.sp_Common_GetUserPermissions @LoginID = <LoginID>;
```
