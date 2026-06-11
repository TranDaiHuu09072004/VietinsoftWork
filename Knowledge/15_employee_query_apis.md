# 15 — API tra cứu danh sách nhân viên theo thời điểm & theo quyền

> File này mô tả chi tiết 2 API trung tâm mà toàn hệ thống ParadiseHR dùng để **lấy danh sách nhân viên**, kèm 2 helper liên đới. Đây là tri thức trục — payroll / attendance / CRM / KPI / task / mobile / web HTML-rendered đều dựa vào.
>
> Liên quan: [02_db_employee.md](02_db_employee.md) (schema `tblEmployee` + bảng vệ tinh), [11_permissions.md](11_permissions.md) (RBAC, data scope, `tblSC_Right_Stored`), [05_db_attendance.md](05_db_attendance.md) (pipeline chấm công dùng `fn_vtblEmployeeList_Bydate`), [09_workflow_payroll.md](09_workflow_payroll.md) (SALCAL dùng `fn_vtblEmployeeList_Bydate`), [08_workflow_crm.md](08_workflow_crm.md) (CRM dùng `sp_getEmployeeListWithPermission`).
>
> ⚠️ Trước khi dùng tên item nào trong câu trả lời, kiểm tra [99_deprecated.md](99_deprecated.md).

---

## 1. Tổng quan — bốn object liên đới

| # | Object | Loại | Vai trò |
|---|---|---|---|
| 1 | `fn_vtblEmployeeList_Bydate(@ViewDate, @EmployeeID, @LoginID)` | Inline TVF | Trả snapshot nhân viên **as-of** ngày `@ViewDate` — kết hợp `tblEmployee` với toàn bộ bảng history (status, division/department/section/group, position, contract, employee type, level, cost center, position titles, working place). |
| 2 | `fn_vEmployeeStatus_ByDate(@ViewDate, @EmployeeID, @LoginID)` | Inline TVF (helper) | Lọc danh sách nhân viên hợp lệ theo `@EmployeeID`/`@LoginID` rồi trả status của họ tại `@ViewDate`. `fn_vtblEmployeeList_Bydate` JOIN vào TVF này — nó là **filter chính** quyết định ai có trong kết quả. |
| 3 | `sp_getEmployeeListWithPermission(@LoginID, @IsFullName)` | Stored procedure | Trả danh sách nhân viên user `@LoginID` **được phép xem**, dựa trên mức quyền (Full / Manager / Customer / User). Dùng `fn_vtblEmployeeList_Bydate(GETDATE(), -1, null)` làm nguồn rồi lọc theo `LineManagerID` / accessID. |
| 4 | `fn_Common_GetAccessID(@LoginID)` | Scalar function | Resolver — đọc `tblSC_Right_Stored` xác định mức quyền của user (`-1`=Full, `1`=Manager, `2`=Customer, `0`=User thường). `sp_getEmployeeListWithPermission` gọi function này để chia nhánh. |

Phụ thuộc:

```
sp_getEmployeeListWithPermission
   ├── fn_Common_GetAccessID            ← resolve AccessID
   └── fn_vtblEmployeeList_Bydate       ← lấy snapshot nhân viên
          └── fn_vEmployeeStatus_ByDate ← filter employee hợp lệ + status
                 └── tmpEmployeeTree    ← cây nhân viên theo LoginID (khi @EmployeeID='-1')
```

`fn_vtblEmployeeList_Bydate` được **575 procedure khác** trong DB tham chiếu (verify từ `sys.sql_modules` 2026-05-21) — đây là API nhân viên trung tâm.

---

## 2. `fn_vtblEmployeeList_Bydate` — snapshot nhân viên as-of ngày

### 2.1. Signature

```sql
CREATE FUNCTION dbo.fn_vtblEmployeeList_Bydate
(
    @ViewDate   DATE,            -- ngày xem dữ liệu
    @EmployeeID NVARCHAR(4000),  -- '-1' / '' = lấy tất / theo cây; danh sách phân biệt bằng ';' = lấy theo list
    @LoginID    INT              -- NULL = bỏ qua cây nhân viên, lấy toàn bộ; khác NULL = filter theo tmpEmployeeTree
)
RETURNS TABLE
```

### 2.2. Ba chế độ filter

| Chế độ | `@EmployeeID` | `@LoginID` | Hành vi |
|---|---|---|---|
| **A. Theo list cụ thể** | `'E001;E002;E003'` (delim `;`) | bất kỳ | Chỉ trả các EmployeeID nằm trong list. Internally `fn_vEmployeeStatus_ByDate` split string. |
| **B. Theo cây user** | `'-1'` hoặc `''` | `<LoginID>` (NOT NULL) | Lấy theo `tmpEmployeeTree` nơi `LoginID = @LoginID` — đây là phạm vi user được phép xem trong cây nhân viên (cập nhật runtime). |
| **C. Toàn bộ nhân viên** | `'-1'` hoặc `''` | `NULL` | Bỏ qua tree, trả tất cả nhân viên có history trong `tblEmployeeStatusHistory` ≤ `@ViewDate`. Dùng cho job nội bộ (payroll, attendance summary, ranking). |

> Nhánh A/B/C được implement trong `fn_vEmployeeStatus_ByDate` qua 3 `SELECT UNION ALL` với điều kiện loại trừ lẫn nhau (vd nhánh A bật khi `ISNULL(@EmployeeID,'') NOT IN ('-1','')`).

### 2.3. Cấu trúc result-set (cột trả về)

Lấy tất cả cột của `tblEmployee` (`te.*`), cộng các cột history "as-of":

| Nhóm | Cột | Nguồn lấy |
|---|---|---|
| Mã hiển thị | `EmployeeCodeReal`, `EmployeeCodePrefix` | Split prefix từ `tblDivision.EmployeeCodePrefix` |
| Hồ sơ tĩnh | `te.*` | `tblEmployee` |
| Working place | `WorkingPlaceID`, `WorkingPlaceEffectiveDate` | `tblWorkingPlaceHistory` (MAX EffectiveDate, không filter ≤ ViewDate) |
| Trạng thái | `EmployeeStatusID`, `StatusChangedDate` (alias từ `stat.ChangedDate`), `StatusEndDate`, `TerminateDate` | `fn_vEmployeeStatus_ByDate` — TerminateDate=`StatusChangedDate` khi `EmployeeStatusID=20`, ngược lại `NULL` |
| Tổ chức | `DivisionID`, `DepartmentID`, `SectionID`, `GroupID`, `DivDepSecChangedDate` | `tblDivDepSecPos` (MAX ChangedDate ≤ ViewDate) |
| Vị trí | `PositionID`, `PositionEffectiveDate`, `LeveSalaryID` | `tblPositionHistory` (MAX EffectiveDate ≤ ViewDate) |
| Loại NV | `EmployeeTypeID`, `EmployeeTypeEffectiveDate` | `tblEmployeeTypeHistory` |
| Cấp bậc | `LevelID`, `LevelIDEffectiveDate` | `tblLevelIDHistory` |
| Cost center | `CostCenter`, `CostCenterEffectiveDate` | `tblCostCenterHistory` |
| Position title | `PositionTitlesID`, `PositionTitlesEffectiveDate` | `tblPositionTitlesHistory` |
| Hợp đồng | `ContractID`, `ContractCode`, `ContractStartDay` | `tblLabourContract` (MAX ContractStartDay ≤ ViewDate) |
| Tính sẵn | `LastWorkingDate` | `dateadd(dd, -1, TerminateDate)` nếu đã nghỉ; `'9999-12-31'` nếu còn làm |

**Filter cứng**: `WHERE stat.EmployeeID IS NOT NULL` — chỉ trả nhân viên có row trong `fn_vEmployeeStatus_ByDate` (tức là có ít nhất 1 record `tblEmployeeStatusHistory` ≤ ViewDate).

### 2.4. Pattern temporal join

Mọi bảng history đều dùng cùng pattern:

```sql
LEFT JOIN (
    SELECT h.EmployeeID, h.<Field>, h.EffectiveDate
    FROM dbo.<tblXxxHistory> h
    INNER JOIN (
        SELECT EmployeeID, MAX(EffectiveDate) EffectiveDate
        FROM dbo.<tblXxxHistory>
        WHERE EffectiveDate <= @ViewDate
        GROUP BY EmployeeID
    ) tmp ON h.EmployeeID = tmp.EmployeeID AND h.EffectiveDate = tmp.EffectiveDate
) <alias> ON te.EmployeeID = <alias>.EmployeeID
```

→ Lấy **record gần nhất có hiệu lực ≤ ViewDate** cho mỗi nhân viên. Ngoại lệ: `tblWorkingPlaceHistory` dùng `CROSS APPLY MAX(WorkingPlaceEffectiveDate)` **không filter** ≤ ViewDate (lấy working place mới nhất tuyệt đối).

### 2.5. Ví dụ dùng phổ biến

```sql
-- (A) Snapshot 1 nhân viên cụ thể tại ngày 2026-01-31
SELECT * FROM dbo.fn_vtblEmployeeList_Bydate('2026-01-31', N'E001', NULL);

-- (B) Toàn bộ nhân viên user LoginID=5 được phép xem trong cây (kỳ chấm công 2026-05)
SELECT EmployeeID, FullName, DepartmentID, PositionID
FROM   dbo.fn_vtblEmployeeList_Bydate('2026-05-31', '-1', 5);

-- (C) Toàn bộ nhân viên còn làm việc hôm nay (job nội bộ, không cần cây)
SELECT EmployeeID, FullName, EmployeeStatusID, TerminateDate
FROM   dbo.fn_vtblEmployeeList_Bydate(GETDATE(), '-1', NULL)
WHERE  TerminateDate IS NULL;

-- (D) Danh sách nhân viên thuộc 1 phòng ban X tại ngày Y
SELECT EmployeeID, FullName
FROM   dbo.fn_vtblEmployeeList_Bydate('2026-03-01', '-1', NULL)
WHERE  DepartmentID = 'D001' AND TerminateDate IS NULL;
```

### 2.6. Use cases trong hệ thống thực

| Module | Procedure tiêu biểu | Cách dùng |
|---|---|---|
| Attendance pipeline | `TA_Process_Main`, `sp_PerformanceKPI_Working_Process` | Mode C — quét toàn bộ nhân viên hợp lệ trong kỳ tính. |
| Payroll | `SALCAL_MAIN`, các SALCAL_* | Mode C — lấy snapshot nhân viên cuối kỳ lương để tính tổng hợp. |
| Ranking | `sp_Rank_getPersonalRating` | Mode C — lấy danh sách nhân viên cho `ROW_NUMBER()` xếp hạng. |
| Mobile / Web filter | `sp_EmployeeListDataMultiSelectSelectBox` | Mode B — giới hạn theo cây user. |
| `sp_getEmployeeListWithPermission` | Internal | Mode C (lấy hết) rồi filter theo `LineManagerID` ở procedure ngoài. |

---

## 3. `fn_vEmployeeStatus_ByDate` — TVF lọc nhân viên hợp lệ (helper nội bộ)

```sql
CREATE FUNCTION dbo.fn_vEmployeeStatus_ByDate
(
    @ViewDate   DATE,
    @EmployeeID NVARCHAR(4000),
    @LoginID    INT
) RETURNS TABLE AS RETURN
(
    WITH FilteredEmployees AS (
        -- Trường hợp 1: theo list ';'
        SELECT LTRIM(RTRIM(Items)) AS EmpID FROM dbo.SplitString(@EmployeeID, ';')
        WHERE ISNULL(@EmployeeID, '') NOT IN ('-1', '')
        UNION ALL
        -- Trường hợp 2: theo cây nhân viên (tmpEmployeeTree)
        SELECT tr.EmployeeID FROM tmpEmployeeTree tr
        WHERE ISNULL(@EmployeeID, '') IN ('-1', '') AND tr.LoginID = @LoginID
        UNION ALL
        -- Trường hợp 3: tất cả
        SELECT te.EmployeeID FROM tblEmployee te
        WHERE ISNULL(@EmployeeID, '') IN ('-1', '') AND @LoginID IS NULL
    )
    SELECT h.EmployeeID, h.EmployeeStatusID, h.ChangedDate, tes.EmployeeStatus, h.StatusEndDate
    FROM   FilteredEmployees f
    CROSS APPLY (
        SELECT TOP 1 tesh.EmployeeID, tesh.EmployeeStatusID, tesh.ChangedDate, tesh.StatusEndDate
        FROM   dbo.tblEmployeeStatusHistory tesh
        WHERE  tesh.EmployeeID = f.EmpID AND tesh.ChangedDate <= @ViewDate
        ORDER BY tesh.ChangedDate DESC
    ) h
    LEFT JOIN dbo.tblEmployeeStatus tes ON h.EmployeeStatusID = tes.EmployeeStatusID
);
```

Điểm cần nhớ:

- 3 nhánh `UNION ALL` chính là cơ sở của 3 chế độ filter ở §2.2.
- Nhân viên không có row trong `tblEmployeeStatusHistory` ≤ `@ViewDate` sẽ **không xuất hiện** → `fn_vtblEmployeeList_Bydate` cũng không trả họ.
- `tmpEmployeeTree` là bảng nội bộ chứa cặp `(LoginID, EmployeeID)` — định nghĩa phạm vi user được phép xem trong cây nhân viên. Bảng này được rebuild qua quy trình phân quyền (xem [11_permissions.md](11_permissions.md)).

---

## 4. `sp_getEmployeeListWithPermission` — danh sách NV theo quyền

### 4.1. Signature

```sql
CREATE PROCEDURE dbo.sp_getEmployeeListWithPermission
(
    @LoginID    INT,
    @IsFullName BIT = 1     -- 1 = trả (EmployeeID, FullName); 0 = chỉ (EmployeeID)
)
```

### 4.2. Logic — UNION theo `@AccessID`

```sql
DECLARE @AccessID INT = dbo.fn_Common_GetAccessID(@LoginID);   -- -1/0/1/2
DECLARE @EmployeeID VARCHAR(50);
SELECT  @EmployeeID = EmployeeID FROM tblSC_Login WHERE LoginID = @LoginID;

-- (Phiên bản @IsFullName = 1; @IsFullName = 0 tương tự nhưng chỉ SELECT EmployeeID)
SELECT te.EmployeeID, te.FullName FROM tblEmployee te WHERE te.EmployeeID = @EmployeeID
UNION
SELECT EmployeeID, FullName FROM dbo.fn_vtblEmployeeList_Bydate(GETDATE(), -1, NULL) te
WHERE  @AccessID = 1                                  -- Manager
   AND te.TerminateDate IS NULL
   AND te.LineManagerID = @EmployeeID
UNION
SELECT EmployeeID, FullName FROM dbo.fn_vtblEmployeeList_Bydate(GETDATE(), -1, NULL) te
WHERE  @AccessID = -1                                 -- Full access
   AND te.TerminateDate IS NULL;
```

### 4.3. Hành vi theo mức quyền

| `@AccessID` | Tên mức | Trả về |
|---:|---|---|
| `-1` | **Full access** | Bản thân + toàn bộ nhân viên còn làm việc |
| `1` | **Manager** | Bản thân + nhân viên trực tiếp dưới quyền (`LineManagerID = @EmployeeID`, `TerminateDate IS NULL`) |
| `2` | **Customer access** | Chỉ bản thân (cả 2 nhánh kia đều `WHERE FALSE`) |
| `0` | **User thường** | Chỉ bản thân |

### 4.4. Khi @LoginID không gắn với nhân viên

`SELECT @EmployeeID = EmployeeID FROM tblSC_Login WHERE LoginID = @LoginID` — nếu `tblSC_Login.EmployeeID` NULL/rỗng (tài khoản hệ thống), nhánh "bản thân" `WHERE te.EmployeeID = @EmployeeID` không match. Khi đó:
- `@AccessID = -1` → vẫn trả toàn bộ nhân viên (qua nhánh 3).
- `@AccessID = 1` → trả nhân viên có `LineManagerID` match `@EmployeeID` rỗng (thường = 0 row).
- `@AccessID = 0/2` → 0 row.

### 4.5. Use cases

Verify từ `sys.sql_modules` (2026-05-21) — 20 procedure ngoài + nhiều hơn trong DB cuộn lên:

| Module | Procedure dùng |
|---|---|
| **CRM** | `sp_CRM_CompanyDetail_View`, `sp_CRM_getContentPostByID`, `sp_CRM_GetDetailCustomer`, `sp_CRM_GetKPIResults`, `sp_CRM_KpiPedingLoadData`, `sp_CRM_LeadList`, `sp_CRM_ListEmployeeConfigKPI`, `sp_CRM_LoadCustomerDetail_selectemployee`, `sp_CRM_SaveOwnerCustomerDetail_lienhe` |
| **KPI** | `sp_KPIgetDataCollection`, `sp_KPIgetDataContentPost`, `sp_KPIGetProcessStatus`, `sp_KPIgetScheduleMeeting`, `sp_MailSumaryKPI` |
| **Task** | `sp_Task_CheckPermission`, `sp_Task_GetData`, `sp_Task_GetData_Detail` |
| **SelectBox/Mail** | `sp_EmployeeListDataMultiSelectSelectBox`, `sp_MailListSenderOrigin`, `sp_getCustomerPersonInfo_WH` |

Pattern dùng phổ biến nhất trong các proc trên: `INNER JOIN dbo.sp_getEmployeeListWithPermission(@LoginID, 0) perm ON perm.EmployeeID = <NV của entity>` để filter result-set theo quyền.

> ⚠️ **`sp_getEmployeeListWithPermission` chỉ trả nhân viên `TerminateDate IS NULL`** — tức nhân viên còn làm việc tại thời điểm chạy (`GETDATE()`). Không hỗ trợ `@ViewDate` quá khứ. Nếu cần list "nhân viên thuộc quyền user tại tháng 3/2026", phải gọi trực tiếp `fn_vtblEmployeeList_Bydate('2026-03-31', '-1', @LoginID)` rồi tự áp logic Manager (`LineManagerID = ...`).

---

## 5. `fn_Common_GetAccessID` — resolver mức quyền

### 5.1. Signature

```sql
CREATE FUNCTION dbo.fn_Common_GetAccessID(@LoginID BIGINT) RETURNS INT
```

### 5.2. Logic

1. Đọc `ParentLoginID` của user từ `tblSC_Login`. Cột này là chuỗi phân biệt bằng `&` chứa danh sách `LoginID` cha (cho tài khoản proxy / hệ thống multi-account).
2. Build set `@tblParent`:
   - Nếu `ParentLoginID` rỗng → chỉ chứa chính `@LoginID`.
   - Ngược lại → split `&` thành các LoginID cha.
3. Kiểm tra 3 quyền theo thứ tự ưu tiên — `tblSC_Right_Stored.FullAccess = '32'` JOIN `tblSC_Object` JOIN `@tblParent`:

| Thứ tự | Điều kiện `tblSC_Object.ObjectName` | Return |
|---:|---|---:|
| 1 | `'Full access'` | `-1` |
| 2 | `'Managers access'` hoặc `'Manager access'` | `1` |
| 3 | `'Customer access'` | `2` |
| 4 | (không match) | `0` |

> Các `ObjectName` này là **special permission objects** không gắn với menu cụ thể — chỉ tồn tại để gán meta-role. User được cấp quyền `FullAccess=32` với 1 trong 3 object đó để trở thành Full/Manager/Customer.

### 5.3. Lưu ý quan trọng

- Quyền **cộng dồn theo `ParentLoginID`**: nếu user `LoginID=10` có `ParentLoginID = '5&7'`, thì AccessID được resolve trên tổ hợp `{10, 5, 7}` — user nhận quyền cao nhất trong nhóm.
- Đây là **không phải** quyền menu / data scope thông thường — đây là **meta-role** điều khiển logic `sp_getEmployeeListWithPermission`. Quyền menu / scope khác xem [11_permissions.md](11_permissions.md).

---

## 6. Quyết định dùng cái nào (decision tree)

```
Cần lấy danh sách nhân viên?
├── Cần snapshot tại 1 ngày quá khứ / cuối kỳ? ─────────► fn_vtblEmployeeList_Bydate(@ViewDate, ...)
│       └── Lấy theo list cụ thể? ──► mode A: @EmployeeID = 'E001;E002', @LoginID = NULL
│       └── Lấy theo cây user?    ──► mode B: @EmployeeID = '-1',       @LoginID = <LoginID>
│       └── Lấy toàn bộ?          ──► mode C: @EmployeeID = '-1',       @LoginID = NULL
│
└── Cần filter theo quyền user (Full/Manager/User) tại hiện tại? ──► sp_getEmployeeListWithPermission
        └── Chỉ EmployeeID?       ──► @IsFullName = 0
        └── Có FullName?          ──► @IsFullName = 1 (default)
```

| Tình huống | Đối tượng dùng |
|---|---|
| Payroll cuối kỳ lương 2026-03 | `fn_vtblEmployeeList_Bydate('2026-03-31', '-1', NULL)` |
| Mở dropdown chọn nhân viên trong form (theo quyền user) | `sp_getEmployeeListWithPermission @LoginID, 1` |
| Render grid CRM Lead "chỉ thấy lead của mình + lead chưa có owner" | JOIN `sp_getEmployeeListWithPermission` |
| Job nội bộ rebuild `tblTmpAttend` cho mọi nhân viên | `fn_vtblEmployeeList_Bydate(GETDATE(), '-1', NULL)` |
| Snapshot hồ sơ nhân viên cụ thể ngày ký hợp đồng | `fn_vtblEmployeeList_Bydate(@ContractStartDay, N'E001', NULL)` |

---

## 7. Bảng phụ trợ liên quan

| Bảng | Vai trò |
|---|---|
| `tblEmployee` | Hồ sơ tĩnh — xem [02_db_employee.md](02_db_employee.md) |
| `tblEmployeeStatusHistory` | History trạng thái — TVF lọc nhân viên dựa vào bảng này |
| `tblEmployeeStatus` | Master các trạng thái (`EmployeeStatusID=20` = nghỉ việc) |
| `tblDivDepSecPos` | History tổ chức (Division/Department/Section/Group) |
| `tblPositionHistory` | History vị trí |
| `tblEmployeeTypeHistory` | History loại NV |
| `tblLevelIDHistory` | History cấp bậc |
| `tblCostCenterHistory` | History cost center |
| `tblPositionTitlesHistory` | History chức danh |
| `tblWorkingPlaceHistory` | History địa điểm làm việc |
| `tblLabourContract` | Hợp đồng — xem [03_db_contract.md](03_db_contract.md) |
| `tmpEmployeeTree` | `(LoginID, EmployeeID)` — phạm vi user trong cây nhân viên |
| `tblSC_Login` | Tài khoản — xem [06_db_login_account.md](06_db_login_account.md). Cột `ParentLoginID` (phân cách `&`) dùng cho proxy/multi-account. |
| `tblSC_Object`, `tblSC_Right_Stored` | RBAC + meta-role `'Full access'` / `'Manager access'` / `'Customer access'` — xem [11_permissions.md](11_permissions.md) |

---

## 8. Risks / Gotchas

| Vấn đề | Nguyên nhân | Cách tránh |
|---|---|---|
| Performance kém khi filter lại theo `DepartmentID` ở proc ngoài | `fn_vtblEmployeeList_Bydate` quét nhiều bảng history; gọi trong vòng lặp = thảm hoạ | Gọi 1 lần vào temp table rồi join — không gọi trong `WHERE` của vòng lặp |
| Kết quả thay đổi giữa các lần gọi cùng `@ViewDate` | `tblWorkingPlaceHistory` lấy MAX không filter ≤ ViewDate; thêm row mới hôm nay → snapshot quá khứ cũng đổi | Nếu cần snapshot bất biến: snapshot kết quả vào bảng riêng + filter `WorkingPlaceEffectiveDate ≤ @ViewDate` thủ công |
| `sp_getEmployeeListWithPermission` không thấy nhân viên cũ đã nghỉ | Cứng `TerminateDate IS NULL` | Gọi trực tiếp `fn_vtblEmployeeList_Bydate(@ViewDate, '-1', @LoginID)` để có snapshot quá khứ |
| User `Full access` thấy nhân viên đã nghỉ trong kỳ | Mode C của `fn_vtblEmployeeList_Bydate` không filter `TerminateDate`; người gọi phải tự filter | Thêm `WHERE TerminateDate IS NULL OR TerminateDate > @ViewDate` |
| `tmpEmployeeTree` rỗng → user thấy 0 nhân viên ở mode B | Tree chưa được build cho `LoginID` | Rebuild tree qua quy trình phân quyền (xem [11_permissions.md](11_permissions.md)) hoặc chuyển sang mode C nếu logic cho phép |
| Resolve AccessID sai khi `ParentLoginID` chứa LoginID rỗng / không phải số | `fn_SplitString` filter `ISNUMERIC(Items) = 1` nên khá an toàn, nhưng chuỗi format sai có thể bỏ ID cha hợp lệ | Đảm bảo `tblSC_Login.ParentLoginID` đúng format `<id>&<id>&<id>` |
| Object `'Full access'` / `'Managers access'` bị đổi tên / xoá | `fn_Common_GetAccessID` so sánh chính xác string `LTRIM(RTRIM(o.ObjectName))` | Không sửa tên các meta-role object trong `tblSC_Object` |

---

## 9. Câu SQL audit / verify nhanh

```sql
-- (1) Đếm nhân viên mỗi nhánh
SELECT
    (SELECT COUNT(*) FROM dbo.fn_vtblEmployeeList_Bydate(GETDATE(), '-1', NULL)) AS Mode_C_All,
    (SELECT COUNT(*) FROM dbo.fn_vtblEmployeeList_Bydate(GETDATE(), '-1', 3))    AS Mode_B_Login3,
    (SELECT COUNT(*) FROM dbo.fn_vtblEmployeeList_Bydate(GETDATE(), N'E001', NULL)) AS Mode_A_E001;

-- (2) Resolve AccessID cho 1 user
SELECT @AccessID = dbo.fn_Common_GetAccessID(<LoginID>);

-- (3) Test sp_getEmployeeListWithPermission
EXEC dbo.sp_getEmployeeListWithPermission @LoginID = 3, @IsFullName = 1;

-- (4) Đếm procedure dùng fn_vtblEmployeeList_Bydate
SELECT COUNT(*) FROM sys.sql_modules WHERE definition LIKE '%fn_vtblEmployeeList_Bydate%';
-- (2026-05-21 verify: ~575 proc + 1 function self)

-- (5) Liệt kê meta-role object đang có
SELECT ObjectID, ObjectName, Description
FROM   tblSC_Object
WHERE  LTRIM(RTRIM(ObjectName)) IN ('Full access', 'Managers access', 'Manager access', 'Customer access');

-- (6) Liệt kê user có Full access
SELECT rs.LoginID, l.LoginName, l.EmployeeID
FROM   tblSC_Right_Stored rs
JOIN   tblSC_Object o ON o.ObjectID = rs.ObjectID
JOIN   tblSC_Login l  ON l.LoginID = rs.LoginID
WHERE  LTRIM(RTRIM(o.ObjectName)) = 'Full access'
  AND  rs.FullAccess = '32';
```
