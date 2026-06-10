# Hướng Dẫn: Thống Kê Công Theo Tháng - Export Excel (Cập Nhật)

> **Ngày cập nhật:** 2026-06-04  
> **Phiên bản:** 2.0 - Chi tiết tương tự procedure thống kê phép
> **Procedure chính:** `sp_Export_ThongKeCong_Thang_Detailed`  
> **Tác dụng:** Xuất báo cáo thống kê công nhân viên hằng tháng ra Excel

---

## 1. Cấu Trúc Dữ Liệu & Bảng Liên Quan

### Bảng chính:

| Bảng                  | Vai trò        | Cột sử dụng                                                      |
| --------------------- | -------------- | ---------------------------------------------------------------- |
| **`tblHasTA`**        | Công hằng ngày | `EmployeeID`, `AttDate`, `WorkingTime`, `NoTAReasonCode`, `isNS` |
| **`tblEmployee`**     | Thông tin NV   | `EmployeeID`, `FullName`, `HireDate`, `DepartmentID`, `GroupID`  |
| **`tblDepartment`**   | Phòng ban      | `DepartmentID`, `DepartmentName`                                 |
| **`tblGroup`**        | Nhóm/Chi nhánh | `GroupID`, `GroupName`                                           |
| **`tmpEmployeeTree`** | Quyền truy cập | `EmployeeID`, `LoginID`                                          |

### Mối liên kết:

```
tblHasTA (Công hằng ngày)
  ├─ EmployeeID → tblEmployee (Nhân viên)
  │   ├─ DepartmentID → tblDepartment (Phòng ban)
  │   └─ GroupID → tblGroup (Chi nhánh)
  └─ AttDate (Ngày công)
       └─ NoTAReasonCode → Loại công:
           ├─ 'PH', 'PHLD' → Công đức (Public Holiday)
           ├─ 'AL' → Phép năm (Annual Leave)
           ├─ 'SL', 'SLK' → Phép bệnh (Sick Leave)
           ├─ 'ML' → Phép không lương (Unpaid Leave)
           ├─ 'OFF', 'ORG' → Ngày OFF / Tổ chức
           └─ NULL → Công thường (Normal Shift)
       isNS = 1 → Công đêm (Night Shift)
```

---

## 2. Cài Đặt Procedure (2 Phiên Bản)

### **PHIÊN BẢN 1: CHI TIẾT (RECOMMENDED) ✅**

```sql
-- Mở file: sp_Export_ThongKeCong_Thang_Detailed.sql
-- Chạy toàn bộ file để tạo procedure
```

**Đặc điểm:**

- ✅ Xử lý tham số tháng/năm động chi tiết (kiểm tra hợp lệ)
- ✅ Lấy kỳ lương từ `fn_Get_SalaryPeriod` (nếu có)
- ✅ Log từng bước xử lý (PRINT)
- ✅ PIVOT động theo loại công
- ✅ Excel config (cấu hình export)
- ✅ Giống architecture của procedure `sp_Export_ThongKePhep_Thang5`

### **PHIÊN BẢN 2: RÚT GỌN**

```sql
-- Mở file: sp_Export_ThongKeCong_Thang_v2.sql
-- Chạy toàn bộ file
```

**Đặc điểm:** Đơn giản hơn, không có log chi tiết

---

## 3. Test Procedure

### Test 1: Xuất công tháng cụ thể

```sql
EXEC dbo.sp_Export_ThongKeCong_Thang_Detailed
    @Month = 6,
    @Year = 2026,
    @LoginID = 3,
    @LanguageID = 'VN';
```

**Output Console (PRINT):**

```
✓ Lấy kỳ lương từ fn_Get_SalaryPeriod: 01/06/2026 - 30/06/2026
✓ Tạo danh sách nhân sự: 45 nhân viên
✓ Tính dữ liệu công: 120 dòng loại công
✓ Xuất dữ liệu PIVOT xong
✓ Hoàn tất thống kê công tháng 06/2026 - LoginID=3 - Lang=VN
```

**Output Bảng (kết quả query):**
| STT | Mã nhân viên | Họ tên | Ngày vào | Bộ phận | Kỳ báo cáo | Công thường | Công đêm | Công đức | Phép năm | Phép bệnh | Phép KKL | Ngày OFF | Tổng Cộng |
|-----|-------------|--------|----------|--------|-----------|-------------|----------|----------|----------|----------|----------|----------|-----------|
| 1 | EMP001 | Nguyễn Văn A | 01/01/2020 | Phòng IT | 06/2026 | 20.0 | 2.5 | 1.0 | 1.5 | 0.0 | 0.0 | 0.0 | 25.0 |
| 2 | EMP002 | Trần Thị B | 15/03/2021 | Phòng HR | 06/2026 | 18.0 | 0.0 | 0.0 | 2.0 | 0.5 | 0.0 | 1.0 | 21.5 |

### Test 2: Dùng tháng/năm hiện tại (tự động)

```sql
-- Không cần truyền @Month & @Year, sẽ tự lấy mặc định
EXEC dbo.sp_Export_ThongKeCong_Thang_Detailed @LoginID = 3;
```

### Test 3: Tiếng Anh

```sql
EXEC dbo.sp_Export_ThongKeCong_Thang_Detailed
    @Month = 6,
    @Year = 2026,
    @LoginID = 3,
    @LanguageID = 'EN';
```

---

## 4. Thêm Menu Vào ParadiseHR

### Option A: Menu Database/Procedure (Tùy chọn)

```sql
-- 1. Thêm menu vào MEN_Menu
INSERT INTO MEN_Menu
    (MenuID, ClassName, ParentMenuID, Priority, IsVisible, IsWeb, ViewOnWeb, glyphicon)
VALUES
    ('MnuTAD_ExportDetailed', 'sp_Export_ThongKeCong_Thang_Detailed', 'MnuTAD', 5, 1, 1, 1, 'icon-file-excel');

-- 2. Nhãn tiếng Việt
INSERT INTO tblMD_Message (MessageID, Language, Content)
VALUES
    ('MnuTAD_ExportDetailed', 'VN', N'📊 Xuất Thống Kê Công Excel (Chi tiết)');

-- 3. Nhãn tiếng Anh
INSERT INTO tblMD_Message (MessageID, Language, Content)
VALUES
    ('MnuTAD_ExportDetailed', 'EN', N'📊 Export Attendance Summary Excel (Detailed)');

-- 4. Kiểm tra
SELECT * FROM MEN_Menu WHERE MenuID = 'MnuTAD_ExportDetailed';
```

### Option B: HTML Renderer Menu (Nếu cần form interactive)

```sql
-- Mở file: sp_ExportThongKeCong_Thang_html.sql
-- Chạy để tạo procedure renderer với form HTML
```

---

## 5. Cấu Trúc Output (Dữ Liệu Xuất)

### **14 Cột Excel:**

| Cột Excel        | Loại          | Ví dụ        | Ghi chú                          |
| ---------------- | ------------- | ------------ | -------------------------------- |
| **STT**          | int           | 1, 2, 3      | Số thứ tự                        |
| **Mã nhân viên** | varchar(20)   | EMP001       | EmployeeID                       |
| **Họ tên**       | nvarchar(100) | Nguyễn Văn A | FullName                         |
| **Ngày vào**     | date          | 01/01/2020   | HireDate (định dạng dd/MM/yyyy)  |
| **Bộ phận**      | nvarchar(100) | Phòng IT     | DepartmentName hoặc GroupName    |
| **Kỳ báo cáo**   | varchar(10)   | 06/2026      | Định dạng MM/yyyy                |
| **Công thường**  | decimal(10,2) | 20.0         | NoTAReasonCode IS NULL           |
| **Công đêm**     | decimal(10,2) | 2.5          | isNS = 1                         |
| **Công đức**     | decimal(10,2) | 1.0          | NoTAReasonCode IN ('PH', 'PHLD') |
| **Phép năm**     | decimal(10,2) | 1.5          | NoTAReasonCode = 'AL'            |
| **Phép bệnh**    | decimal(10,2) | 0.5          | NoTAReasonCode IN ('SL', 'SLK')  |
| **Phép KKL**     | decimal(10,2) | 0.0          | NoTAReasonCode = 'ML'            |
| **Ngày OFF**     | decimal(10,2) | 0.0          | NoTAReasonCode IN ('OFF', 'ORG') |
| **Tổng Cộng**    | decimal(10,2) | 25.5         | SUM(tất cả loại công)            |

---

## 6. Quy Trình Trong Procedure (Chi Tiết)

```
┌─────────────────────────────────────────────────────────┐
│ sp_Export_ThongKeCong_Thang_Detailed                    │
└─────────────────────────────────────────────────────────┘
           │
           ├─ BƯỚC 1: Xử lý tham số (@Month, @Year)
           │   └─ Kiểm tra hợp lệ, gán mặc định
           │
           ├─ BƯỚC 2: Lấy khoảng ngày (@FromDate, @ToDate)
           │   ├─ Thử gọi fn_Get_SalaryPeriod
           │   └─ Nếu không có → Tính tháng bình thường
           │
           ├─ BƯỚC 3: Tạo danh sách nhân viên (#TmpEmployee)
           │   └─ Gọi fn_vtblEmployeeList_Bydate
           │       (áp dụng quyền LoginID)
           │
           ├─ BƯỚC 4: Lấy dữ liệu công (#AttendanceData)
           │   └─ FROM tblHasTA
           │       GROUP BY EmployeeID + NoTAReasonCode
           │
           ├─ BƯỚC 5: PIVOT dữ liệu
           │   └─ Chuyển 6 loại công → 6 cột
           │       (Công thường, Công đêm, Công đức, Phép năm, ...)
           │
           ├─ BƯỚC 6: Cấu hình Excel (#ExportConfig)
           │   └─ Position A3, WithHeader=1, WithBestFit=1
           │
           └─ BƯỚC 7: Dọn dẹp bảng tạm
               └─ DROP #AttendanceData, #TmpEmployee
```

---

## 7. Công Thức Tính Toán

### Công thường (Công thường):

```sql
SUM(WorkingTime)
WHERE NoTAReasonCode IS NULL
```

### Công đêm (Công đêm):

```sql
SUM(WorkingTime)
WHERE isNS = 1 (từ bất kỳ ngày nào)
```

### Công đức (Công đức):

```sql
SUM(WorkingTime)
WHERE NoTAReasonCode IN ('PH', 'PHLD')
```

### Phép năm:

```sql
SUM(WorkingTime)
WHERE NoTAReasonCode = 'AL'
```

### Phép bệnh:

```sql
SUM(WorkingTime)
WHERE NoTAReasonCode IN ('SL', 'SLK')
```

### Phép không lương (Phép KKL):

```sql
SUM(WorkingTime)
WHERE NoTAReasonCode = 'ML'
```

### Ngày OFF:

```sql
SUM(WorkingTime)
WHERE NoTAReasonCode IN ('OFF', 'ORG')
```

### Tổng Cộng:

```sql
SUM(WorkingTime) của tháng (tất cả loại công)
```

---

## 8. Gọi Procedure Từ JavaScript (Web)

### Cách gọi từ Menu Form:

```javascript
// Khi nhấp nút "Xuất Excel"
function exportAttendanceSummary() {
  var month = parseInt(
    document.getElementById("attendanceMonth").value.split("-")[1],
  );
  var year = parseInt(
    document.getElementById("attendanceMonth").value.split("-")[0],
  );

  // Gọi API qua AjaxHPAParadise
  AjaxHPAParadise.CallAPI(
    {
      api: "sp_Export_ThongKeCong_Thang_Detailed",
      Month: month,
      Year: year,
      LoginID: currentLoginID,
      LanguageID: "VN",
    },
    function (response) {
      // Nhận dữ liệu, có thể export ra Excel
      console.log("Dữ liệu công:", response);
      uiManager.showAlert("✓ Dữ liệu sẵn sàng xuất", "success");
    },
    function (error) {
      console.error("Lỗi:", error);
      uiManager.showAlert("❌ Lỗi: " + error, "danger");
    },
  );
}
```

---

## 9. File Liên Quan

| File                                       | Mục đích                                    | Ghi chú             |
| ------------------------------------------ | ------------------------------------------- | ------------------- |
| `sp_Export_ThongKeCong_Thang_Detailed.sql` | **Procedure export chi tiết** (Recommended) | ✅ Dùng cái này     |
| `sp_Export_ThongKeCong_Thang_v2.sql`       | Procedure export rút gọn                    | Nếu cần tối giản    |
| `sp_ExportThongKeCong_Thang_html.sql`      | HTML renderer cho menu Web                  | Tùy chọn            |
| `attendance_export_guide.md`               | Hướng dẫn này                               | Cập nhật 2026-06-04 |
| `timekeeping_payroll_overview.md`          | Kiến trúc Chấm công & Lương                 | Tham khảo           |

---

## 10. Troubleshooting

### Vấn đề 1: Procedure không tìm thấy

```
❌ Lỗi: Invalid procedure name 'sp_Export_ThongKeCong_Thang_Detailed'
```

**Giải pháp:** Chạy lại file SQL để tạo procedure

### Vấn đề 2: Không lấy được dữ liệu

```
❌ Lỗi: No data returned for the month
```

**Giải pháp:**

- Kiểm tra bảng `tblHasTA` có dữ liệu cho tháng đó không
- Kiểm tra `LoginID` có quyền xem những nhân viên đó không (tmpEmployeeTree)
- Kiểm tra ngày `HireDate` và `TerminateDate` hợp lệ

### Vấn đề 3: PIVOT lỗi

```
❌ Lỗi: Incorrect syntax near 'PIVOT'
```

**Giải pháp:** Đảm bảo SQL Server version ≥ 2012 (PIVOT được hỗ trợ)

### Vấn đề 4: @Month hoặc @Year không hợp lệ

```
❌ Lỗi: Invalid @Month (phải 1-12) hoặc @Year (phải ≥ 1753)
```

**Giải pháp:** Procedure sẽ tự gán mặc định, không cần lo lắng

---

## 11. So Sánh Với Procedure Thống Kê Phép

| Khía cạnh        | Thống kê phép                  | Thống kê công                          |
| ---------------- | ------------------------------ | -------------------------------------- |
| **Tên**          | `sp_Export_ThongKePhep_Thang5` | `sp_Export_ThongKeCong_Thang_Detailed` |
| **Bảng nguồn**   | `tblLvHistory`                 | `tblHasTA`                             |
| **Loại dữ liệu** | PIVOT động (5-20+ loại phép)   | PIVOT cố định (7 loại công)            |
| **Kỳ lương**     | `fn_Get_SalaryPeriod()`        | `fn_Get_SalaryPeriod()` (nếu có)       |
| **Nhân viên**    | `fn_vtblEmployeeList_Bydate()` | `fn_vtblEmployeeList_Bydate()`         |
| **Output**       | Pivot theo Description         | Pivot theo AttTypeName                 |
| **Excel config** | ✅ Có (#ExportConfig)          | ✅ Có (#ExportConfig)                  |
| **Log PRINT**    | ✅ Có                          | ✅ Có (trong phiên bản chi tiết)       |

---

**Cập nhật:** 2026-06-04  
**Phiên bản:** 2.0 - Chi tiết
