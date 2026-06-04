# 10 — Workflow: Performance Management

Reference: [09_workflow_payroll.md](09_workflow_payroll.md) (Payroll dispatcher), [08_workflow_crm.md](08_workflow_crm.md) (Sales CRM module).

ParadiseHR has 5 parallel appraisal pipelines that aggregate data into employee files or directly ingest adjustments into the monthly Payroll Engine.

## 1. The Five Appraisal Systems
| System | Analytical Goal | Evaluated Interval | Core Tables |
|---|---|---|---|
| **Performance Appraisal** | Formal appraisals (salary reviews, annual grading) | Quarterly / Annually | `tblPerformanceAppraisal`, `tblPerformanceAppraisal_Detail`, `tblAppraisalItems` |
| **Balanced Scorecard KPI** | Numeric strategic objectives | Monthly / Quarterly | `tblKPITarget` (BSC weighting), `tblKPIResultItem`, `tblBonusKPI` |
| **Probation Assessment** | Evaluation of new hires | End of probation | `tblPROBATIONASSESSEMENT` |
| **Rank & Coin** | Gamified behavior scoring (experience points & coins) | Continuous (Real-time) | `tblRank_PersonalRating_Detail`, `tblRank_Coin_Wallet` |
| **CRM KPI** | Sales activities (leads, emails, calls, client meetings) | Monthly | `tblCRM_KPI_Setup`, `tblCRM_KPI_Results` |

---

## 2. System Implementations & Workflows

### 2.1. Performance Appraisal (Formal Review)
*   **Schema Hierarchy**:
    `tblPerformanceAppraisalPeriod` (Period bounds: `FromDate`, `ToDate`, linked to salary month `SalMonth`/`SalYear`) -> `tblPerformanceAppraisal` (Header per Employee per Period: active basic wage, `TotalScore`, rating `GradeRatingID`, `[New basic salary]`, approvals `Approve_Status`, completion `isComplete`) -> `tblPerformanceAppraisal_Detail` (Score per appraisal item) -> `tblAppraisalItems` (Master items, `StandardCore` targets) -> `tblSubAppraisalItems` (Drill-down sub-items).
*   **Execution Flow**:
    `Admin sets Period` -> `Draft Appraisal header per employee` -> `Self-appraisal & manager scoring (Details)` -> `Compile score & rating` -> `Manager -> HR -> CEO Approvals` -> `Map [New basic salary] to tblSalaryHistory` -> `Set isComplete = 1`.

### 2.2. BSC KPI System
*   **BSC Hierarchy Strategy**:
    `tblKPIStrategy` (Corporate strategies) -> `tblKPIPerspective` ( BSC Perspectives: Financial, Customer, Internal Process, Learning & Growth) -> `tblKPI_Items` (KPI catalog) -> `tblKPITarget` (Weights Assigned to employees, e.g. sum of `WeightRate` = 100%) -> `tblKPIResultItem` (Actual results & calculated bonus ratios).
*   **Execution Flow**:
    `Configure Strategy Perspectives` -> `Assign Targets (WeightRate) via sp_ImportKPI` -> `Record Actuals (tblKPIResultItem)` -> `Compute performance bonuses (sp_BonusKPI -> tblBonusKPI)` -> `Appraisal Close & Notify (sp_LockBonusKPI)` -> `Ingest into Payroll`.

### 2.3. Probation Assessment
*   **Database**: `tblPROBATIONASSESSEMENT` (`EmployeeID`, `ContractStartDay`, `ContractEndDay`, `Duration`, `IsPrint` flag).
*   **Execution Flow**:
    `Initiate probation (tblEmployee.ProbationStartDate/EndDate)` -> `Generate evaluations list (Gen_ProbationCommitment_List)` -> `Save evaluation (tblPROBATIONASSESSEMENT)` -> `Approve (Set Official = 1 & update ContractFirstDate) OR extend probation (tmpProbationRenewal) OR terminate`.

### 2.4. Rank & Coin (Gamification)
*   **Database**: `tblRank_PersonalRating_Detail` (stores XP, coins, `PointType`), `tblRank_PointType` (rules like punctual attendance, target reached), `tblRank_Coin_Wallet` (wallets), `tblRank_Coin_Transaction` (ledger), `tblRank_Payment_Transactions` (claim rewards).
*   *Note*: Experience Points (XP) and Coin reward configurations are listed in [07_menu_system.md](07_menu_system.md) Section 10.

### 2.5. CRM KPI (Sales Metrics)
*   **Database**: `tblCRM_KPI_Setup` (setup rules), `tblCRM_KPI_Results` (results/coin earnings), `tblCRM_KPICategories` (metrics lookups). Registers activities from email (`tblCRM_EmailKPI`), sales contact calls (`tblCRM_KPIContactActivity`), meetings (`tblCRM_KPIScheduleMeeting`), and post posts (`tblCRM_KPIContent`).
*   *Note*: Detailed processing rules are listed in [08_workflow_crm.md](08_workflow_crm.md) Section 6.

---

## 3. Payroll Ingestion Mappings
*   **Performance Appraisal**: `[New basic salary]` -> `tblSalaryHistory` -> Ingested by `SALCAL_MONTHLYBASIC_FINISHED`.
*   **KPI System**: `tblBonusKPI` / `tblEfficiencyBonus` -> Ingested by `SALCAL_ALLOWANCE_*` or `SALCAL_ADJUSTMENT_*`.
*   **Rank & Coin**: `tblRank_Payment_Transactions` -> Ingested by `tblSal_Adjustment`.
*   **Probation**: Passing results update `tblEmployee.Official = 1` -> Updates contracts/salary grades.

---

## 4. Diagnostics Queries
```sql
-- 1. View employee appraisal headers
SELECT pa.AppraisalID, p.PeriodEvaluationName, pa.TotalScore, pa.GradeRatingID, pa.Approve_Status, pa.isComplete
FROM tblPerformanceAppraisal pa
INNER JOIN tblPerformanceAppraisalPeriod p ON p.EvaluationID = pa.EvaluationID
WHERE pa.EmployeeID = N'<EmployeeID>' ORDER BY p.FromDate DESC;

-- 2. View appraisal item score details
SELECT ai.AppraisalItemName, ai.StandardCore, d.Score, (d.Score - ai.StandardCore) AS Variance
FROM tblPerformanceAppraisal_Detail d
INNER JOIN tblAppraisalItems ai ON ai.AppraisalItemID = d.AppraisalItemID
WHERE d.AppraisalID = <AppraisalID>;

-- 3. Check employees nearing end of probation (next 14 days)
SELECT EmployeeID, FullName, PositionName, ContractStartDay, ContractEndDay
FROM tblPROBATIONASSESSEMENT
WHERE ContractEndDay BETWEEN GETDATE() AND DATEADD(DAY, 14, GETDATE()) ORDER BY ContractEndDay;

-- 4. View employee gamification XP wallet balance
SELECT SUM(ExperiencePoints) AS TotalXP, SUM(Coin) AS TotalCoin
FROM tblRank_PersonalRating_Detail WHERE EmployeeID = N'<EmployeeID>';
```
