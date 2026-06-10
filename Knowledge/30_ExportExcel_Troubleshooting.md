# Hướng dẫn Xử lý Lỗi & Cơ chế Export Excel Động (Dynamic Export)

Tài liệu này tổng hợp các bài học kinh nghiệm và quy trình chuẩn khi xử lý tính năng Xuất Excel (Export Excel) báo cáo động trong hệ thống Paradise HR, đặc biệt là các báo cáo dùng PIVOT động (như Thống kê tăng ca, Thống kê phép).

## 1. Cơ chế Auto-Generate Excel (Tự động sinh mẫu)

Hệ thống Paradise HR hỗ trợ tự động vẽ file Excel (bao gồm cả dòng tiêu đề và các header cột) từ kết quả của Stored Procedure mà không cần dùng đến file mẫu `.xlsx` gắn ngoài.

### Quy tắc cấu hình bảng `#ExportConfig`
Trong thủ tục SQL, cần trả về result set thứ 2 cho bảng `#ExportConfig`:
```sql
CREATE TABLE #ExportConfig(
    TableIndex VARCHAR(MAX), RowIndex INT, ColumnName NVARCHAR(200), 
    ParseType NVARCHAR(MAX), Position NVARCHAR(200), SheetIndex INT, 
    TestDescription NVARCHAR(MAX), WithHeader INT, WithBestFit BIT
);

INSERT INTO #ExportConfig (TableIndex, SheetIndex, ParseType, Position, WithHeader, TestDescription, WithBestFit)
VALUES ('0', 0, 'Table', 'A2', 1, N'Tiêu đề báo cáo sẽ in ở dòng 1', 1);

SELECT * FROM #ExportConfig;
```

**Giải thích:**
- `ParseType = 'Table'`: Dữ liệu sẽ đổ ra dưới dạng Data Table.
- `WithHeader = 1`: Tự động in ra các tên cột của Data Table (lấy trực tiếp từ tên cột của lệnh SELECT).
- `Position = 'A2'`: Bắt đầu in Header từ ô `A2`. Dòng `A1` sẽ được hệ thống dùng để in Tiêu đề báo cáo (chính là chuỗi trong `TestDescription`). Dữ liệu sẽ tự động đổ từ dòng `A3` trở đi.
- **Quan trọng:** Phải đảm bảo cột `RptTemplate` trong bảng cấu hình (như `tblDataSetting` hoặc `tblExportList`) **bằng NULL**. Nếu có file template đính kèm mà file đó có các ô Merge (gộp ô), giao diện auto-generate sẽ bị vỡ nát và các field bị trộn lẫn.

## 2. Lỗi "ExportData_Is_Empty:VN" và Cách Khắc Phục

Khi bấm xuất báo cáo trên UI (đặc biệt là màn hình "Danh sách các báo cáo") và nhận được thông báo lỗi Empty, nguyên nhân thường rơi vào 3 trường hợp sau:

### Trường hợp 1: Màn hình UI không gọi đúng thủ tục (Sai Mapping)
Cây thư mục "Danh sách báo cáo" được ánh xạ từ bảng `tblExportList`. Nếu tạo thủ tục mới (`sp_Export_New`) nhưng quên chưa cập nhật lại `tblExportList`, UI vẫn sẽ gọi thủ tục cũ (`sp_Export_Old`). 
- **Cách fix:** Kiểm tra và update lại cột `ProcedureName`:
  ```sql
  UPDATE tblExportList 
  SET ProcedureName = 'sp_Export_New' 
  WHERE Description LIKE N'%Tên báo cáo trên UI%';
  ```

### Trường hợp 2: Giao diện UI truyền tham số (Parameter) bị lệch chuẩn
Một số Combobox trên UI (như Combobox chọn Năm) không truyền Text hiển thị (VD: `2023`) mà truyền **Index** của dòng đó (VD: `5` - vì 2023 đứng thứ 5 tính từ năm gốc 2018).
Nếu thủ tục SQL không bắt trường hợp này, nó sẽ nhận `@Year = 5`, hiểu là năm không hợp lệ và reset về năm hiện tại (chưa có dữ liệu), dẫn đến kết quả trả về bằng rỗng.

- **Cách fix:** Bắt lỗi Index trong thủ tục SQL:
  ```sql
  -- Giao diện UI có thể truyền Index của năm (VD: 5 = 2023, 8 = 2026)
  IF @Year IS NOT NULL AND @Year < 100
      SET @Year = 2018 + @Year; -- 2018 là năm gốc, thay đổi tùy theo cấu hình của dự án
  ```

### Trường hợp 3: Trùng lặp tham số tự động nặn ra UI (UI Checkbox lạ)
Nếu thủ tục SQL có khai báo tham số thừa mà UI không biết cách xử lý ngầm (VD: `@UseSalaryPeriod BIT = 1`), UI sẽ tự động Generate ra một ô Checkbox vô duyên trên màn hình.
- **Cách fix:** Không đưa biến đó vào phần tham số `( @... )` của PROCEDURE. Hãy mang nó vào bên trong body của SP và dùng lệnh `DECLARE @UseSalaryPeriod BIT = 1;`.

## 3. Lỗi thứ tự cột PIVOT bị đảo lộn
Khi làm PIVOT động (Dynamic PIVOT) lấy danh sách cột từ bảng hệ thống (VD: `tblOvertimeSetting`), hàm `ORDER BY` khi gom cột rất quan trọng.
- Nếu ORDER BY theo Mã ID (`OTKind`), cột `OT 300%` (ID 21) có thể ra trước cột `OT 200%` (ID 22), làm đảo lộn logic hiển thị trên file Excel.
- **Cách fix:** Cần ORDER BY theo giá trị thực tế của nghiệp vụ (VD: `OvValue ASC`) để cột xuất ra đúng thứ tự logic (150%, 200%, 270%, 300%, 390%).
