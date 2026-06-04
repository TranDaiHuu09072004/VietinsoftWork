# 09 — Workflow: Payroll Pipeline

Reference: [05_db_attendance.md](05_db_attendance.md) (Attendance chot input), [10_workflow_performance.md](10_workflow_performance.md) (KPI input), [02_db_employee.md](02_db_employee.md) (Bank metadata).

The pipeline contains 10 sequential phases orchestrated by the core procedure **`SALCAL_MAIN`**.

## 1. Ten-Phase Payroll Pipeline
```
[1] Lock Attendance -> [2] External Pay Input -> [3] Compute Wages (SALCAL_MAIN) -> [4] Social Insurance -> [5] Compute Tax (PIT) -> [6] Trade Union Fee -> [7] Verify & Lock (tblSal_Lock) -> [8] Summarize (sp_CompanySalarySummary) -> [9] Bank Transfer (rpt_PR_SalaryToBank) -> [10] Publish Payslips
```

| Phase | Core Stored Procedures / Tables | Functional Goal |
|---|---|---|
| **1. Lock Attendance** | `Overtime_Assignment_Do_Approve`<br/>`LockAttendanceData_PreProcess` | Freeze attendance logs. Set `tblSal_Lock.LockType = 'TA'`. |
| **2. External Inputs** | `tblPR_EmpAllowance`, `Import_PRAllowance`, `tblSal_Adjustment`, `tblSal_Advance`, `tblBonusKPI` | Collect monthly allowances, non-fixed adjustments, advances, performance bonuses. |
| **3. Compute Wages** | `SALCAL_MAIN` dispatcher: `SALCAL_IO` (ins/outs), `SALCAL_NS` (night shift), `SALCAL_OT` (overtime), `SALCAL_LEAVE_AUTOMATIC` (paid leave), `SALCAL_MONTHLYBASIC` (basic wage), `SALCAL_ALLOWANCE` (allowances), `SALCAL_ADJUSTMENT`. | Main compute engine. Populates temporary buffers then inserts to `tblSal_IO`, `tblSal_NS`, `tblSal_OT`, `tblSal_PaidLeave`, `tblSal_Sal`. |
| **4. Social Insurance** | `EmpInsuranceMonthly_BeforeCalculate`<br/>`SALCAL_INSURANCE`<br/>`sp_AverageSISalary_ByEmployeeAmt` | Calculate company and employee SI/HI/UI contributions. Log results to `tblSal_Insurance` and `tblEmpInsuranceMonthly`. |
| **5. Compute Tax (PIT)** | `SALCAL_TAX_INITIAL` (cumulative scale), `SALCAL_TAX_10_INITIAL` (flat 10% rate for casual contract staff). | Calculate personal income tax. Reads dependencies: `tblContract_PIT_Status`, `tblFamilyInfo_Adjustment` (dependents). |
| **6. Trade Union Fee** | Computed directly inside `SALCAL_MAIN`. | Read details in Section 2. |
| **7. Verify & Lock** | `PR_SalCal_GetError`, `SALCAL_FinishUpdateSalDetail`, `sp_CheckSalCal_BusinessFlow` | Post-calculation audit. Lock payroll: `tblSal_Lock.LockType = 'SAL'`. |
| **8. Summarize** | `sp_CompanySalarySummary`, `sp_CompanySalaryReport` | Generate company-wide aggregates. |
| **9. Bank Transfer** | `rpt_PR_SalaryToBank` | Generate bank transfer files (Excel formatting mapped per bank). Sets payment logs in `tblCompanySalaryPayment`. |
| **10. Publish Payslips**| `EmployeePaySlip_Links`, `Payslip_Send_Submitted` | Deliver digital payslips via Web/Mobile ESS, Email (`tblPendingEmail`), or Zalo (`tblZaloMessage`). |

---

## 2. Trade Union Fee Computation (Phase 6 Detail)
All calculations execute directly inside `SALCAL_MAIN`.

### 2.1. Fee Schemes Lookup: `tblUnionFeeMethod`
| Method ID | Scheme Description | Company % | Employee % | Co. Fixed | Emp. Fixed |
|---:|---|---:|---:|---:|---:|
| 0 | No Trade Union active | 0 | 0 | 0 | 0 |
| 1 | Company pays 2% only | 2 | 0 | 0 | 0 |
| 2 | Company 2%, Employee 1% | 2 | 1 | 0 | 0 |
| 3 | Company 2%, Employee fixed 35,000 | 2 | 0 | 0 | 35,000 |

*Hierarchy for mapping scheme to Employee*:
1. `tblDivision.UNION_FEE_METHOD` -> 2. `tblCompany.UNION_FEE_METHOD` -> 3. Default = `3`. (Note: `tblParameter.UNION_FEE_METHOD` is only a secondary fallback).

### 2.2. Computation Formulas
*   **Employee Fee (`UnionFeeEmp`)** = `(Emp_ByPercent = 1 ? (UNION_PERCENT_EMP * BasicSalary / 100) : UNION_PACKAGE_EMP) * IsEmpPaid`
*   **Company Fee (`UnionFeeComp`)** = `(Comp_ByPercent = 1 ? (UNION_PERCENT_COMP * BasicSalary / 100) : UNION_PACKAGE_COMP) * IsComPaid`

*Value Mapping for `BasicSalary`*:
1. `SIIncome` from `tblSal_Insurance` (active month).
2. Fallback: `fn_CurrentSISalary_byDate(@SIDate, @LoginID)` (reference date: 15th of the payroll month).
3. Overridden with `MinimumSal` (from `tblSI_CeilSalary` representing maximum SI threshold) if `Is_CeilSalary = 1`.

### 2.3. Eligibility Flags (`IsEmpPaid` / `IsComPaid`)
*   Default: `IsEmpPaid = 0`, `IsComPaid = 1` (Only corporate contribution).
*   `IsEmpPaid = 1` if employee is listed in `fn_EmployeeUnion_ByDate(@ToDate)` with `EmployeePay = 1` during the target period.
*   `IsEmpPaid = 0` if employee has no active workdays (`TotalPaidDays = 0`).
*   `IsEmpPaid = 0` and `IsComPaid = 0` if employee has no SI contributions active (marked as decreased SI for the month).

### 2.4. Clamps & Overrides
1.  **Regional Minimum Wage Cap**: Limit `UnionFeeEmp` if `MaximumByPercentsOfBaseSalaryRegional > 0` against regional minimums (`BaseSalaryRegional`).
2.  **Absolute Max Cap**: Clamp calculations against `UNION_PACKAGE_EMP_MAX` and `UNION_PACKAGE_COMP_MAX` thresholds.
3.  **Manual Overrides**: Admin edits in `tblSal_Insurance` (`UnionFeeEmp` / `UnionFeeComp`) override calculated values.

### 2.5. Salary Book Impact (`tblSal_Sal`)
Updates `EmpUnion`, `EmpUnion_RETRO`, `CompUnion`, and `CompUnion_RETRO` money columns.
*   **Net Take Home** (`GrossTakeHome`) deduction: `GrossTakeHome = (ActualMonthlyBasic + TotalOTAmount + TotalNSAmt + TotalAllowanceForSalary + TotalAdjustmentForSalary) - (InsAmt + IOAmt + EmpUnion)`
*   **Total Corporate Cost** (`TotalCostComPaid`) addition: `TotalCostComPaid = ActualMonthlyBasic + TotalOTAmount + TotalNSAmt + TaxableAllowanceTotal + NoneTaxableAllowanceTotal + InsAmtComp - IOAmt + CompUnion + CompUnion_RETRO + (IsNet = 1 ? InsAmt : 0)`

---

## 3. Payroll Cycle Periodics
The monthly payroll window is defined dynamically via `tblParameter` and computed by `dbo.fn_Get_SalaryPeriod(@Month, @Year)`:
*   **`SAL_START`**: Start day boundary (Default: `10`).
*   **`SAL_STOP`**: End day boundary (Default: `9`).
*   **FromDate**: Start day of `@Month`. (Note: if `SAL_START > SAL_STOP` and `SAL_START > 15`, it steps back to the prior month, e.g., 20th of prior month to 19th of active month).
*   **ToDate**: End day of active cycle (`SAL_STOP` day of the next month `@Month + 1`).
*   *Example (using defaults 10 and 9)*: May 2026 payroll covers `2026-05-10 00:00:00` to `2026-06-09 23:59:59`.

## 4. Diagnostics Queries
```sql
-- Check if target payroll period is locked
EXEC dbo.sp_CheckLockSalByMonthAndYear @Month = 5, @Year = 2026;

-- Retrieve payroll processing errors
EXEC dbo.PR_SalCal_GetError;

-- Query locked cycles log
SELECT * FROM tblSal_Lock ORDER BY [Year] DESC, [Month] DESC;

-- View employee final payroll record
SELECT GrossTakeHome, ActualMonthlyBasic, TotalOTAmount, InsAmt, EmpUnion, TotalCostComPaid
FROM tblSal_Sal WHERE EmployeeID = N'<EmployeeID>' AND [Month] = 5 AND [Year] = 2026;
```
