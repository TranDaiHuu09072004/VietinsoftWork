# 11 — Phân quyền user (RBAC + Data scope + Inheritance)

> Phân quyền sử dụng tính năng của hệ thống ParadiseHR. Liên quan: [06_db_login_account.md](06_db_login_account.md) (bảng `tblSC_Login`), [07_menu_system.md](07_menu_system.md) (đối tượng phân quyền link qua `MenuID`).

ParadiseHR dùng mô hình **RBAC + Data scope + Inheritance**. Quyền không tập trung một chỗ — app phải tổng hợp từ nhiều layer khi user gọi chức năng.

## 1. Đối tượng được phân quyền

Mọi chức năng (menu, screen, report) đều có một record trong **`tblSC_Object`** (`ObjectID`, `ObjectName`, `Description` → `MenuID`, `Visible`). Đây là "danh sách những gì có thể phân quyền". Mapping `ClassName / TemplateFileName → ObjectID` lấy thêm qua `tblExportList`.

## 2. Hai khái niệm "Group" — phân biệt rõ

| Khái niệm | Bảng định nghĩa | Bảng thành viên | Mục đích |
|---|---|---|---|
| **User Right Group** (group quyền — RBAC role) | `tblUserRightGroup` (`UserGroupID`, `UserGroupName`) | `tblUserGrantGroup` (`UserID = LoginID`, `UserGroupID`) | Gom user theo role (vd: HR Manager, Kế toán lương). Là cơ chế cấp quyền chính. |
| **SC Group** (group nhân viên — data scope) | `tblSC_Group` (`GroupID`, `GroupName`) | `tblSC_GroupMember` (`GroupID`, `LoginID`) | Gom nhân viên thành nhóm để user khác có thể *xem dữ liệu của nhóm đó*. |

## 3. Bốn layer quyền khi truy cập 1 chức năng

| Layer | Bảng | Ý nghĩa |
|---|---|---|
| **A. Cờ override trên tài khoản** | `tblSC_Login.isAdmin`, `AdminRight`, `IsHRManager`, `IsBigBoss`, `AlwaysFullAccess`, `UseGroupRightOnly` | Bật cờ → bypass kiểm tra chi tiết, full access |
| **B. Quyền cá nhân (direct)** | `tblSC_Right`, `tblSC_Right_Stored` (`LoginID`, `ObjectID`, `FullAccess`) | Quyền gán thẳng cho `LoginID` lên 1 `ObjectID` |
| **C. Quyền theo group** | `tblUserGrantGroup` × `tblSC_GroupRight` (`UserGroupID`, `ObjectID`, `FullAccess`) | Quyền kế thừa từ User Right Group |
| **D. Quyền thừa kế cha** | `tblSC_Login.ParentLoginID` (chuỗi LoginID cha, separator `&`) | Tự động kế thừa quyền của (các) tài khoản cha |

## 4. Enum `FullAccess`

| Giá trị | Ý nghĩa |
|---|---|
| `0` | Denied — không có quyền |
| `1` | Read only — chỉ đọc |
| `8` | Follow for group — không quyết, lấy theo group |
| `32` | Updatable / Full access — toàn quyền |

## 5. Tầng Access Level toàn cục (`sp_Common_GetUserPermissions`)

Procedure quét `tblSC_Right_Stored` cho `ObjectName` đặc biệt (trên `LoginID` + tất cả parent `LoginID`), trả về access level theo ưu tiên giảm dần:

1. **`Full access`** → `IsAdmin = 1`
2. **`Manager access` / `Managers access`** → `IsAdmin = 1`
3. **`Customer access`** → `IsCustomer = 1`
4. **`Users access`** → `IsCustomer = 1`
5. **No Access**

## 6. Phạm vi xem dữ liệu (Data scope)

Tách riêng khỏi quyền chức năng — quy định user xem được data của ai:

| Bảng | Phạm vi |
|---|---|
| `tblSC_DepartmentView_Group` | Group quyền nào xem được `DepartmentID` nào (cột `UserGroupID`, `DepartmentID`, `ViewInfo`) |
| `tblSC_SectionView_Group` | Group quyền nào xem được section nào (`UserGroupID`, `SectionID`, `DepartmentID`, `ViewInfo`) |
| `tblSC_GroupView_Group` | Group quyền nào xem được data của SC Group nhân viên nào (`UserGroupID`, `GroupID`, `SectionID`, `ViewInfo`) |
| `tblSC_Right_ByLoginID` | View theo từng `LoginID` (cá nhân, không qua group): `GroupID`, `SectionID`, `ViewInfo`, `Right` |
| `tblSC_DepartmentView`, `tblSC_SectionView` (per user) | Per-user override |
| `tblSC_GroupView` (`ObjectID`, `ObjectName`) | Master object dùng cho view |

`ViewInfo = 1` → được xem; thiếu row → không xem được.

## 7. Quy trình resolve quyền khi user gọi chức năng

Trích từ procedure `SC_USEROBJECTRIGHT_GET(@FullClassName, @LoginID)`:

```text
1. Map @FullClassName → @ObjectID
   (qua tblExportList.TemplateFileName hoặc tblSC_Object.ObjectName)
2. Gọi sp_SC_Right(@LoginID, @ObjectID)
   → lấy quyền cá nhân từ tblSC_Right_Stored
3. NẾU FullAccess = NULL hoặc = '8' (follow for group):
       JOIN tblSC_Login × tblUserGrantGroup × tblSC_GroupRight × tblSC_Object
       → lấy FullAccess theo User Right Group
4. Chuẩn hoá giá trị về {0, 1, 32} qua dbo.SplitString separator '&':
       - max(quyền) > 0 → 32
       - = 0 → Denied
5. RETURN @rightId
```

Song song, app gọi `sp_Common_GetUserPermissions(@LoginID)` để lấy access level toàn cục (có check `ParentLoginID` chain).

## 8. Quy trình admin **gán quyền**

| Thao tác | Procedure | Bảng đích |
|---|---|---|
| Tạo / cập nhật / xoá user | `SC_User_Insert`, `SC_User_Update`, `SC_User_Delete` | `tblSC_Login` |
| Gán user vào User Right Group | `sp_tblSC_LoginWithGroupSaver` | `tblUserGrantGroup` |
| Gán quyền object cho user (cá nhân) | `SC_UserObjects_Save` | `tblSC_Right`, `tblSC_Right_Stored` |
| Gán phạm vi xem phòng ban | `SC_UserDeptViewInfo_Save` | `tblSC_DepartmentView*` |
| Gán phạm vi xem division | `SC_UserDivViewInfo_Save` | (bảng View Division) |
| Gán phạm vi xem section | `SC_UserSectViewInfo_Save` | `tblSC_SectionView*` |
| Gán phạm vi xem SC group | `SC_UserGroupViewInfo_Save` | `tblSC_GroupView_Group` |
| Cập nhật menu sau khi đổi quyền | `sp_UpdateMenuInUserRight` | `MEN_Menu` filter |
| Load cây quyền cho UI | `LoadUserRightTree` | (đọc) |

## 9. Quy trình khi user đăng nhập

1. **`Login` / `spParadiseLogin` / `SC_Login_CheckLogin`** — validate username + password mã hoá, check `IsDisable`, `IsLockout`, `AttemptCounter`, `ValidTimeBegin/End`.
2. **`SC_Login_CheckLogin_Finish`** — finalize: reset `AttemptCounter`, cập nhật `LastChangedDate`.
3. **`sp_Common_GetUserPermissions`** — xác định access level toàn cục.
4. **`LoadUserRightTree`** + **`sp_UpdateMenuInUserRight`** — load cây menu user được phép xem, lọc `MEN_Menu` theo quyền **và** nền tảng (`IsWeb` / `IsUseMobileDevice`, xem [01_architecture.md](01_architecture.md)).

## 10. Sơ đồ tổng hợp

```
                    tblSC_Login (LoginID, isAdmin, IsHRManager,
                                 ParentLoginID, AlwaysFullAccess, ...)
                          │
              ┌───────────┼───────────────┬─────────────────┐
              │           │               │                 │
      (A) Cờ override     │      (D) Parent inheritance     │
                          │               │                 │
      (B) Quyền cá nhân   │       (C) Quyền theo group      │
  tblSC_Right_Stored      │  tblUserGrantGroup              │
  (LoginID, ObjectID,     │     │                           │
   FullAccess)            │     ▼                           │
                          │  tblUserRightGroup              │
                          │     │                           │
                          │     ▼                           │
                          │  tblSC_GroupRight               │
                          │  (UserGroupID, ObjectID,        │
                          │   FullAccess)                   │
                          │                                 │
                          └─→ Merge → FullAccess ──→ {0,1,32}
                                                            │
                                                            ▼
                                                Data scope filter:
                                                tblSC_DepartmentView_Group
                                                tblSC_SectionView_Group
                                                tblSC_GroupView_Group
                                                tblSC_Right_ByLoginID
```

## 11. Câu SQL mẫu

```sql
-- 1. Xem user thuộc User Right Group nào
SELECT l.LoginID, l.LoginName, urg.UserGroupID, urg.UserGroupName
FROM tblSC_Login l
LEFT JOIN tblUserGrantGroup ug ON ug.UserID = CAST(l.LoginID AS varchar)
LEFT JOIN tblUserRightGroup urg ON urg.UserGroupID = ug.UserGroupID
WHERE l.LoginName = 'nv001';

-- 2. Liệt kê quyền cá nhân (direct) của 1 user
SELECT o.ObjectName, rs.FullAccess
FROM tblSC_Right_Stored rs
INNER JOIN tblSC_Object o ON o.ObjectID = rs.ObjectID
WHERE rs.LoginID = <LoginID>
ORDER BY o.ObjectName;

-- 3. Liệt kê quyền theo group của 1 user
SELECT o.ObjectName, gr.FullAccess, urg.UserGroupName
FROM tblSC_Login l
INNER JOIN tblUserGrantGroup ug ON ug.UserID = CAST(l.LoginID AS varchar)
INNER JOIN tblUserRightGroup urg ON urg.UserGroupID = ug.UserGroupID
INNER JOIN tblSC_GroupRight gr ON gr.UserGroupID = urg.UserGroupID
INNER JOIN tblSC_Object o ON o.ObjectID = gr.ObjectID
WHERE l.LoginID = <LoginID>;

-- 4. Access level toàn cục
EXEC dbo.sp_Common_GetUserPermissions @LoginID = <LoginID>;

-- 5. Resolve quyền cho 1 chức năng cụ thể (theo tên class / template)
EXEC dbo.SC_USEROBJECTRIGHT_GET
     @p_FullClassName = 'SomeMenuID',
     @p_LoginID       = <LoginID>;

-- 6. Phòng ban mà 1 group được xem
SELECT d.DepartmentID, d.DepartmentName, dvg.ViewInfo
FROM tblSC_DepartmentView_Group dvg
INNER JOIN tblDepartment d ON d.DepartmentID = dvg.DepartmentID
WHERE dvg.UserGroupID = <UserGroupID> AND dvg.ViewInfo = 1;
```

> Lưu ý: cột `tblUserGrantGroup.UserID` lưu **varchar** mà chứa giá trị `LoginID` (int) — khi join phải cast.
