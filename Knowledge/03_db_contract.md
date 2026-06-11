# 03 — Database: Hợp đồng lao động (Labour Contract)

> Schema + procedure in HĐ lao động. Liên quan: [02_db_employee.md](02_db_employee.md) (link qua `EmployeeID`), [09_workflow_payroll.md](09_workflow_payroll.md) (lương theo HĐ).

## Bảng chính: `tblLabourContract`

Mỗi dòng là một hợp đồng lao động của nhân viên.

- Khoá chính: `ContractID` (bigint). Mỗi nhân viên có nhiều dòng (lịch sử HĐ); HĐ hiện hành thường là dòng có `ContractID` lớn nhất theo `EmployeeID`.
- Cột nghiệp vụ chính: `ContractNo`, `EmployeeID`, `ContractCode` (loại HĐ — FK tới `tblMST_ContractType`), `ContractStartDay`, `ContractEndDay`, `SalaryCode` (FK `tblSalaryHistory.SalaryHistoryID`), `ChuyenMonID`, `LBIssueDate`.

## Bảng phụ trợ khi in HĐ

| Bảng | Mục đích |
|---|---|
| `tblMST_ContractType` | Loại HĐ — `ContractName`, `ContractNameEN` |
| `tblSalaryHistory` | Bậc lương tương ứng HĐ (join qua `SalaryCode = SalaryHistoryID`) |
| `tblRepresentativeSetting` | Người đại diện công ty ký HĐ — chọn bản ghi `Activated = 1` |
| `tblCompany` | Thông tin công ty (mặc định `CompanyID = 1`) |
| `tblContractResponsibility` | Mô tả trách nhiệm theo `PositionID` (`DetailVN`, `DetailEN`) |
| `tblChuyenMon` | Chuyên môn (`TenChuyenMon`) |

## Procedure dùng để IN hợp đồng lao động

| Procedure | Tham số | Mục đích |
|---|---|---|
| `sp_CrystalRptLabourContract` | `@ContractID bigint`, `@loginID int` | **In 1 HĐ** cụ thể qua Crystal Report. Trả full dữ liệu nhân viên + HĐ + công ty + đại diện. |
| `Print_LabourContract_List` | `@list varchar(MAX)` (danh sách `EmployeeID` cách nhau bằng dấu phẩy, mỗi ID bao bằng nháy đơn), `@LoginID int` | **In hàng loạt**. Tự lấy `MAX(ContractID)` (HĐ mới nhất) cho từng nhân viên trong `@list`. Lưu ý: dùng dynamic SQL nội bộ qua bảng tạm `tmpHopdong`. |
| `sp_GetContractTemplate` | `@ContractID bigint` | Lấy mẫu HĐ (`tblMST_ContractType`) ứng với 1 HĐ — biết dùng Crystal template nào. |
| `sp_GetContractTemplateList` | — | Danh sách template HĐ để chọn khi in. |
| `SalaryDetailForLabourContract` | — | Chi tiết bậc/cấu phần lương đính kèm bản in HĐ. |
| `sp_CurrentLabourContractDisplay` | — | Hiển thị HĐ hiện hành (preview trước khi in). |

```sql
-- In 1 HĐ
EXEC dbo.sp_CrystalRptLabourContract @ContractID = 12345, @loginID = 1;

-- In hàng loạt theo danh sách EmployeeID (mỗi ID bao nháy đơn)
EXEC dbo.Print_LabourContract_List
     @list    = '''EMP001'',''EMP002''',
     @LoginID = 1;

-- Lấy HĐ hiện hành (ContractID lớn nhất) của 1 nhân viên
SELECT TOP 1 ContractID, ContractNo, ContractCode, ContractStartDay, ContractEndDay
FROM tblLabourContract
WHERE EmployeeID = N'<EmployeeID>'
ORDER BY ContractID DESC;
```

> Lưu ý bảo mật: `Print_LabourContract_List` build SQL động từ `@list`. Khi gọi từ ứng dụng cần sanitize tham số để tránh SQL injection.
