# 24 — Skill: Thiết kế & Lập trình Stored Procedure chuẩn ParadiseHR

> Hướng dẫn chi tiết quy chuẩn đặt tên, khai báo biến, gọi hàm nghiệp vụ cốt lõi và các bước lập trình stored procedure (T-SQL) an toàn và chuẩn hóa trong dự án ParadiseHR.

---

## Mục lục

1. [Giai đoạn 0: Khảo sát và Thu thập thông tin (Bắt buộc)](#giai-đoạn-0-khảo-sát-và-thu-thập-thông-tin-bắt-buộc)
2. [6 Nguyên tắc vàng lập trình stored procedure](#2-6-nguyên-tắc-vàng-lập-trình-stored-procedure)
3. [Quy tắc đặt tên (Naming Conventions)](#3-quy-tắc-đặt-tên-naming-conventions)
4. [Mẫu Header khai báo thông tin thủ tục](#4-mẫu-header-khai-báo-thông-tin-thủ-tục)
5. [Các hàm và API nghiệp vụ cốt lõi (Bắt buộc dùng)](#5-các-hàm-và-api-nghiệp-vụ-cốt-lõi-bắt-buộc-dùng)
6. [Chuẩn lưu trữ mã nguồn SQL](#6-chuẩn-lưu-trữ-mã-nguồn-sql)
7. [Mẫu khung stored procedure chuẩn (Boilerplates)](#7-mẫu-khung-stored-procedure-chuẩn-boilerplates)

---

## Giai đoạn 0: Khảo sát và Thu thập thông tin (Bắt buộc)

Trước khi tiến hành viết code của bất kỳ thủ tục stored procedure nào, Agent **bắt buộc phải hỏi và yêu cầu người dùng cung cấp đầy đủ các thông tin cần thiết sau** (không được tự ý phỏng đoán nếu chưa có sự xác nhận của người dùng):

- **Yêu cầu mô tả mục đích**: Yêu cầu người dùng mô tả rõ ràng mục đích của thủ tục này dùng để làm gì.
- **Các bảng (tables), hàm (functions) hoặc view liên quan**: Xác định rõ các bảng hoặc hàm nào cần sử dụng để tạo thủ tục này. *Đồng thời, Agent nên chủ động phân tích và khuyến nghị một số cái tên bảng/hàm/view liên quan dựa trên ngữ cảnh mô tả của người dùng để họ dễ dàng lựa chọn và phản hồi.*
- **Phân loại ứng dụng**: Thủ tục này áp dụng để tạo menu, xuất báo cáo (Report SP) hay xử lý dữ liệu (Action SP: thêm/sửa/xóa) trong database.
- **Các tham số (Parameters) đầu vào**: Các tham số nào cần truyền vào thủ tục (ví dụ: `@LoginID`, `@ViewDate`, `@FromDate`, `@ToDate`, `@DepartmentID`,... và kiểu dữ liệu tương ứng).
- **Các câu hỏi làm rõ khác**: Nếu thấy yêu cầu của người dùng còn mơ hồ, chưa rõ thông tin (ví dụ: nghiệp vụ tính toán đặc thù, cấu trúc cột mong muốn, ràng buộc dữ liệu), Agent phải đặt câu hỏi làm rõ cho đến khi nắm rõ yêu cầu trước khi bắt tay vào code.

> [!IMPORTANT]
> **Quy định nghiêm ngặt**: Agent chỉ được phép tiến hành đọc schema và viết code sau khi đã nhận được câu trả lời hoặc sự xác nhận rõ ràng của người dùng đối với các câu hỏi trên.

---

## 2. 6 Nguyên tắc vàng lập trình stored procedure

Khi viết mới hoặc chỉnh sửa stored procedure, Agent bắt buộc phải tuân thủ nghiêm ngặt 6 nguyên tắc sau:

### Rule 1 — Bắt buộc đọc schema (Cấm tự đoán cột)
- Trước khi lập trình, tất cả các bảng liên quan trong store bắt buộc phải được đọc và xác định schema thành công thông qua công cụ MCP.
- Nếu không đọc được schema qua công cụ MCP, Agent bắt buộc phải tra cứu thông tin schema trong file [Database_Tables_Schema.txt](file:///d:/VTS%20User/Cuong.vu/Agent%20work/VietinsoftWork/Database_Tables_Schema.txt).
- Nếu vẫn không tìm thấy hoặc không đọc được, Agent bắt buộc phải hỏi người dùng để được cung cấp thông tin schema chính xác.
- **Tuyệt đối KHÔNG tự suy đoán tên cột hoặc kiểu dữ liệu** của bất kỳ bảng nào.

### Rule 2 — Các tùy chọn mặc định (SET Options)
Đầu mọi procedure bắt buộc phải bật đủ 3 cờ thiết lập tiêu chuẩn:
```sql
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
```

### Rule 3 — Tham số bảo mật bắt buộc
- Mọi stored procedure trong hệ thống phải có tối thiểu một tham số là `@LoginID INT`.
- Tham số này dùng để kiểm tra quyền hạn của người dùng đăng nhập và lọc dữ liệu (Data Scope).

### Rule 4 — Kiểm tra tri thức lỗi thời
- Trước khi sử dụng bất kỳ bảng, cột, hàm hay procedure nào, bắt buộc phải tra cứu danh sách tại [99_deprecated.md](file:///d:/VTS%20User/Cuong.vu/Agent%20work/VietinsoftWork/Knowledge/99_deprecated.md).
- Tuyệt đối không sử dụng các đối tượng đã được ghi nhận lỗi thời trong registry.

### Rule 5 — Độc lập và Idempotent
- Sử dụng mệnh đề `CREATE OR ALTER PROCEDURE` để đảm bảo script có thể chạy nhiều lần mà không gây lỗi hoặc xung đột.
- Khi tạo các bảng tạm toàn cục (`##...`), phải kiểm tra sự tồn tại và xóa trước khi tạo.

### Rule 6 — Cấm gọi `sp_UpdateMenuInUserRight` tự động
- Khi đăng ký thủ tục mới với hệ thống menu, chỉ cấp quyền truy cập đầy đủ (`FullAccess='32'`) cho quản trị viên `LoginID = 3` (qua bảng `tblSC_Right_Stored`).
- **Cấm gọi** `sp_UpdateMenuInUserRight` tự động trong script vì nó sẽ mở quyền truy cập cho toàn bộ người dùng trong hệ thống CSDL.

---

## 3. Quy tắc đặt tên (Naming Conventions)

Tên của thủ tục phải phản ánh đúng mục đích và lớp kiến trúc của nó trong hệ thống:

| Lớp thủ tục | Quy tắc đặt tên | Ví dụ |
| :--- | :--- | :--- |
| **Wrapper (Thủ tục menu chính)** | `sp_<TenNghiepVu>` | `sp_HelloWorldVietinsoft` |
| **Renderer (Thủ tục dựng HTML)** | `sp_<TenNghiepVu>_html` | `sp_HelloWorldVietinsoft_html` |
| **Data API (Thủ tục lấy dữ liệu)** | `sp_<TenNghiepVu>_GetData` hoặc `_List` hoặc `_DataSource` | `sp_HelloWorld_EmployeeList` |
| **Action API (Sửa đổi dữ liệu)** | `sp_<TenNghiepVu>_<HanhDong>` (Hành động: `Update`, `Delete`, `Submit`, `Approve`) | `sp_ContactCustommer_Update` |
| **Báo cáo (Report SP)** | `sp_Report_<TenBaoCao>` hoặc `rpt_<TenBaoCao>` | `sp_Report_EmployeeSalary_Jan2025` |

---

## 4. Mẫu Header khai báo thông tin thủ tục

Mỗi stored procedure bắt buộc phải chứa phần comment mô tả mục đích sử dụng rõ ràng ở đầu file:

```sql
-- ============================================================================
-- SQL SCRIPT: [Tên Tệp Tin SQL]
-- STORED PROCEDURE: [Tên Stored Procedure]
-- AUTHOR: [Tên Tác Giả / Agent]
-- DATE: [Ngày Tạo YYYY-MM-DD]
-- MỤC ĐÍCH:
--   [Mô tả chi tiết mục đích của thủ tục dùng để làm gì]
--   [Ví dụ: Load danh sách nhân viên phục vụ màn hình quản lý CRM]
--
-- CÁC BẢNG & HÀM LIÊN QUAN SỬ DỤNG:
--   - Bảng: [tblCRM_CustomerPersonInfo], [tblEmployee], ...
--   - Hàm/View: [dbo.fn_vtblEmployeeList_Bydate], ...
--
-- CÁC THỦ TỤC / MÀN HÌNH GỌI:
--   - Được gọi từ: [sp_CRM_CustomerList_html] hoặc [AjaxHPAParadise] từ client
-- ============================================================================
```

---

## 5. Các hàm và API nghiệp vụ cốt lõi (Bắt buộc dùng)

Hệ thống ParadiseHR cung cấp các hàm nghiệp vụ tối ưu để truy xuất thông tin nhân viên, lương và hợp đồng. **Bắt buộc** sử dụng các hàm này thay vì tự viết câu truy vấn kết nối các bảng gốc:

### 5.1 Lấy danh sách nhân viên theo thời điểm và quyền hạn
Để lấy danh sách nhân viên đang làm việc tính đến ngày xác định, được phân quyền theo cấu trúc tổ chức và mức bảo mật:
```sql
SELECT * FROM dbo.fn_vtblEmployeeList_Bydate(@ViewDate, @EmployeeID, @LoginID);
```
- `@ViewDate`: Ngày snapshot (định dạng `DATE` hoặc `DATETIME`).
- `@EmployeeID`: Bộ lọc ID nhân viên cụ thể (truyền `NULL` để lấy tất cả).
- `@LoginID`: ID tài khoản người dùng đang đăng nhập.

### 5.2 Lấy thông tin Lương và Phụ cấp hiện tại
Để tra cứu mức lương cơ bản, lương bảo hiểm và các khoản phụ cấp đang có hiệu lực của nhân viên tại một thời điểm:
```sql
SELECT * FROM dbo.fn_CurrentSalaryByDate(@ViewDate, @LoginID);
```

### 5.3 Lấy thông tin Hợp đồng lao động hiện tại
Để tra cứu số hợp đồng, loại hợp đồng, ngày bắt đầu và ngày kết thúc của hợp đồng lao động đang hoạt động tại thời điểm truy vấn:
```sql
SELECT * FROM dbo.fn_CurrentContractListByDate(@ViewDate, @LoginID);
```

### 5.4 Xác định chu kỳ tính công/lương (Salary Period)
Để xác định ngày bắt đầu (`FromDate`) và ngày kết thúc (`ToDate`) của chu kỳ lương theo tháng và năm:
```sql
SELECT FromDate, ToDate FROM dbo.fn_Get_SalaryPeriod(@Month, @Year);
```
*Trường hợp không có tháng/năm xác định, dùng ngày hiện tại làm mốc:*
```sql
SELECT FromDate, ToDate FROM dbo.fn_Get_SalaryPeriod_ByDate(GETDATE());
```

---

## 6. Chuẩn lưu trữ mã nguồn SQL

- Tất cả các mã nguồn tạo mới stored procedure, view, function hoặc nâng cấp schema bảng bắt buộc phải được viết vào file độc lập (định dạng `.sql`).
- Lưu trữ tệp tin trong thư mục gốc của dự án: **`SQL script/`**.
- Đặt tên file theo chuẩn: `[LoạiThaoTac]_[TenDoiTuong]_[YYYYMMDD].sql`
  - Ví dụ 1: `create_rpt_EmployeeSalary_Jan2025.sql`
  - Ví dụ 2: `update_tblCRM_CustomerPersonInfo_IsCRMLead_20260527.sql`

---

## 7. Mẫu khung stored procedure chuẩn (Boilerplates)

### 7.1 Mẫu stored procedure Data/Report SP (Trả dữ liệu thô)
```sql
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Report_EmployeeActiveContract_ByDate
    @LoginID INT,
    @ViewDate DATE = NULL,
    @DepartmentID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET ANSI_NULLS ON;
    SET QUOTED_IDENTIFIER ON;

    -- 1. Default @ViewDate if not supplied
    IF @ViewDate IS NULL
        SET @ViewDate = CAST(GETDATE() AS DATE);

    -- 2. Main Query
    SELECT 
        emp.EmployeeCodeReal AS [Mã nhân viên],
        emp.FullName AS [Họ và tên],
        sal.DepartmentName AS [Phòng ban],
        sal.PositionName AS [Chức vụ],
        sal.Salary AS [Lương cơ bản],
        ct.ContractNo AS [Số hợp đồng],
        ct.ContractName AS [Loại hợp đồng],
        CAST(ct.ContractStartDay AS DATE) AS [Ngày ký],
        @ViewDate AS [Thời điểm báo cáo]
    FROM dbo.fn_vtblEmployeeList_Bydate(@ViewDate, NULL, @LoginID) emp
    LEFT JOIN dbo.fn_CurrentSalaryByDate(@ViewDate, @LoginID) sal ON emp.EmployeeID = sal.EmployeeID
    OUTER APPLY (
        SELECT TOP 1 c.ContractNo, c.ContractStartDay, c.ContractEndDay, t.ContractName
        FROM dbo.tblLabourContract c
        LEFT JOIN dbo.tblMST_ContractType t ON c.ContractCode = t.ContractCode
        WHERE c.EmployeeID = emp.EmployeeID
          AND c.ContractStartDay <= @ViewDate
          AND (c.ContractEndDay IS NULL OR c.ContractEndDay >= @ViewDate)
        ORDER BY c.ContractStartDay DESC, c.ContractID DESC
    ) ct
    WHERE (@DepartmentID IS NULL OR emp.DepartmentID = @DepartmentID)
    ORDER BY sal.DepartmentName, emp.EmployeeCodeReal;
END
GO
```

### 7.2 Mẫu stored procedure Wrapper (Đọc cache giao diện menu)
```sql
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE dbo.sp_HelloWorldVietinsoft
    @LoginID INT = NULL,
    @LanguageID VARCHAR(2) = 'VN'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Load HTML content directly from script cache
    SELECT html 
    FROM dbo.tblHtmlScriptCache 
    WHERE TableName = 'sp_HelloWorldVietinsoft_html' 
      AND ScreenType = -1 
      AND LanguageID = @LanguageID;
END
GO
```
