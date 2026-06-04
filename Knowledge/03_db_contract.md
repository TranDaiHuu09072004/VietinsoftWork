# 03 — Database: Labour Contract

Reference: [02_db_employee.md](02_db_employee.md) (Employee link), [09_workflow_payroll.md](09_workflow_payroll.md) (Salary link).

## 1. Master Table: `tblLabourContract`
Contains employee contract history. The active contract is usually the record with the maximum `ContractID` for a given `EmployeeID`.
*   **Primary Key**: `ContractID` (bigint).
*   **Key Columns**: `ContractNo`, `EmployeeID`, `ContractCode` (FK to `tblMST_ContractType`), `ContractStartDay`, `ContractEndDay`, `SalaryCode` (FK to `tblSalaryHistory.SalaryHistoryID`), `ChuyenMonID` (Specialization ID), `LBIssueDate`.

## 2. Satellite Tables
*   `tblMST_ContractType`: Contract templates/categories (`ContractName`, `ContractNameEN`).
*   `tblSalaryHistory`: Grade/step and wage configuration (joined via `SalaryCode = SalaryHistoryID`).
*   `tblRepresentativeSetting`: Corporate representatives (`Activated = 1` signifies active representative).
*   `tblCompany`: Corporate information (default `CompanyID = 1`).
*   `tblContractResponsibility`: Task/responsibility scopes based on `PositionID` (`DetailVN`, `DetailEN`).
*   `tblChuyenMon`: Specialization detail descriptions (`TenChuyenMon`).

## 3. Operations & Printing Stored Procedures
*   `sp_CrystalRptLabourContract` (`@ContractID bigint`, `@loginID int`): Generates printable data for a single contract.
*   `Print_LabourContract_List` (`@list varchar(MAX)`, `@LoginID int`): Prints contracts in batch. `@list` is a comma-separated list of single-quoted Employee IDs (e.g. `'''EMP001'',''EMP002'''`). Uses dynamic SQL internally. *Caution*: Ensure `@list` input validation to prevent SQL Injection.
*   `sp_GetContractTemplate` (`@ContractID bigint`): Identifies Crystal template associated with contract type.
*   `sp_GetContractTemplateList`: Fetches list of all printable templates.
*   `SalaryDetailForLabourContract`: Yields structured salary breakdowns for contract prints.
*   `sp_CurrentLabourContractDisplay`: Previews active contract details.

## 4. SQL Usage Examples
```sql
-- Single Contract Print
EXEC dbo.sp_CrystalRptLabourContract @ContractID = 12345, @loginID = 1;

-- Batch Contract Print
EXEC dbo.Print_LabourContract_List @list = '''EMP001'',''EMP002''', @LoginID = 1;

-- Query Active Contract
SELECT TOP 1 ContractID, ContractNo, ContractCode, ContractStartDay, ContractEndDay
FROM tblLabourContract
WHERE EmployeeID = N'<EmployeeID>'
ORDER BY ContractID DESC;
```
