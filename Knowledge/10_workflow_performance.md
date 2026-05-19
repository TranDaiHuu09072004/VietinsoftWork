# 10 — Workflow: Hệ thống đánh giá hiệu suất công việc (Performance Management)

> 5 hệ thống đánh giá song song. Liên quan: [09_workflow_payroll.md](09_workflow_payroll.md) (output từ Performance feed vào Payroll giai đoạn 2), [08_workflow_crm.md](08_workflow_crm.md) (CRM KPI là 1 trong 5 hệ).

ParadiseHR có **5 hệ thống đánh giá song song**, mỗi cái phục vụ một mục đích riêng nhưng đều feed vào Payroll:

| Hệ thống | Mục đích | Tần suất |
|---|---|---|
| **Performance Appraisal** | Đánh giá định kỳ chính thức (review lương, đánh giá năm) | Quý / Năm |
| **KPI** | Mục tiêu định lượng theo chiến lược (Balanced Scorecard) | Tháng / Quý |
| **Probation Assessment** | Đánh giá NV thử việc | Cuối kỳ thử việc |
| **Rank / Coin (Gamification)** | Tích điểm XP + xu thưởng | Real-time |
| **CRM KPI** | KPI riêng cho sale/marketing (CRM module) | Tháng |

## 1. Performance Appraisal — đánh giá định kỳ chính thức

### Cấu trúc dữ liệu — 5 bảng chính

```
tblPerformanceAppraisalPeriod  (Master kỳ đánh giá)
   ├─ EvaluationID, PeriodEvaluationName ("Q1-2026", "Năm 2025")
   ├─ FromDate, ToDate
   └─ SalMonth, SalYear   ← liên kết kỳ lương để áp lương mới
        │
        ▼
tblPerformanceAppraisal  (Header — 1 record / NV / kỳ)
   ├─ AppraisalID (PK), EmployeeID, PositionID, DepartmentID, EvaluationID
   ├─ PurpsoseOfReviewID → tblAppraisalPurpose
   ├─ SalaryHistoryCurrent     ← lương hiện tại
   ├─ TotalScore               ← tổng điểm
   ├─ GradeRatingID → tblPerformanceAppraisalRating   ← xếp loại A/B/C
   ├─ Strengths, Weakness, KeyDevelopmentPlans, CareerAspirations
   ├─ SpecialAdjustment, AdjustNewLawInJan, [New basic salary]
   ├─ Approve_Status, Current_Approve_Level   ← workflow duyệt nhiều cấp
   ├─ ModifyStatus → tblPerformanceAppraisalModifyStatus
   ├─ Attachment, Age, Remark
   └─ isComplete   ← khoá phiếu
        │
        ▼
tblPerformanceAppraisal_Detail  (Detail — n record per AppraisalID)
   ├─ Identity_ID (PK), AppraisalID (FK), AppraisalItemID (FK)
   └─ Score
        │
        ▼
tblAppraisalItems (Master tiêu chí)
   ├─ AppraisalItemID, AppraisalItemName, Description, DescriptionEN
   └─ StandardCore   ← điểm chuẩn

tblSubAppraisalItems   ← tiêu chí con (drill-down)
```

### Quy trình 7 bước

```
[1] Admin tạo kỳ                                tblPerformanceAppraisalPeriod
[2] Tạo phiếu cho từng NV                       tblPerformanceAppraisal (Approve_Status = Draft)
[3] NV tự đánh giá + Manager chấm điểm          tblPerformanceAppraisal_Detail
[4] Tổng hợp                                    UPDATE TotalScore, GradeRatingID, định tính
[5] Workflow duyệt                              Current_Approve_Level: NV → LM → HR → CEO
[6] Áp dụng điều chỉnh lương                    [New basic salary] → tblSalaryHistory
                                                → vào kỳ lương SalMonth/SalYear
[7] Khoá phiếu                                  isComplete = 1
```

## 2. KPI System — Balanced Scorecard model

### Cấu trúc — 4 tầng phân cấp

```
tblKPIStrategy          Chiến lược cấp công ty
        ▼
tblKPIPerspective       Góc nhìn BSC (Tài chính / Khách hàng / Quy trình / Học hỏi)
        ▼
tblKPI_Items            Danh mục KPI items
        ▼
tblKPITarget            (TargetID, TargetName, WeightRate, Priority, StrategyID)
                        ← chỉ tiêu giao cho NV với trọng số % (Σ WeightRate = 100%)
        ▼
tblKPIResultItem        (KPIID, KPIName, BonusRate)
                        ← kết quả thực tế + tỷ lệ thưởng
```

### Quy trình

```
[1] Thiết kế chiến lược      tblKPIStrategy → tblKPIPerspective → tblKPI_Items
[2] Giao chỉ tiêu            tblKPITarget (WeightRate %)
                             import: sp_ImportKPI / sp_ImportKPI_Schemal
[3] Thu thập kết quả         tblKPIResultItem (real-time hoặc import)
[4] Tính thưởng              sp_BonusKPI → tblBonusKPI
                             sp_KPIgetEmployeeKpiRanking → xếp hạng NV
[5] Khoá kỳ                  sp_LockBonusKPI
                             sp_MailSumaryKPI → email tổng hợp
[6] Đẩy vào Payroll          tblBonusKPI / tblEfficiencyBonus / tblPerformenceBonusPayment
                             → SALCAL_ALLOWANCE_* / SALCAL_ADJUSTMENT_* (xem 09_workflow_payroll)
```

## 3. Probation Assessment — đánh giá thử việc

**Bảng**: `tblPROBATIONASSESSEMENT` (`EmployeeID`, `PositionCode/Name`, `SectionName`, `ContractName`, `ContractStartDay/EndDay`, `LBIssueDate`, `Duration`, `IsPrint`).

### Quy trình

```
[1] NV ký HĐ thử việc          tblEmployee.ProbationStartDate, ProbationEndDate
[2] Trước ngày ProbationEndDate
        Gen_ProbationCommitment_List   → sinh danh sách cam kết
        Quản lý đánh giá               → tblPROBATIONASSESSEMENT
[3] Quyết định:
        • Pass   → ký HĐ chính thức (Official = 1, ContractFirstDate)
        • Renew  → gia hạn (sp_ColumnChangeProbationEndDate, tmpProbationRenewal)
        • Fail   → terminate
[4] Export biên bản              sp_ExportPROBATIONASSESSEMENT (IsPrint = 1)
```

## 4. Rank / Coin — Gamification

### Cấu trúc

```
tblRank_PersonalRating_Detail  (EmployeeID, ExperiencePonits XP, Coin, CreatedDate, PointType)
tblRank_PointType              (loại điểm: hoàn thành KPI / đi đúng giờ / đóng góp / …)
tblRank_Coin_Wallet            Ví xu của NV
tblRank_Coin_Transaction       Giao dịch cộng/trừ xu
tblRank_Payment_Transactions   Đổi xu → tiền/quà
tblRank_PayOS_Config           Cấu hình cổng thanh toán PayOS
```

NV được auto-cộng XP+Coin khi hoàn thành hành vi/KPI cụ thể, có thể đổi thưởng qua cổng PayOS. Cơ chế real-time, không gắn chu kỳ đánh giá cố định.

> **Quy trình tính điểm chi tiết** (PointType 1-10, công thức từng loại): xem [07_menu_system.md](07_menu_system.md) section 10 — "Quy trình tính điểm kinh nghiệm và xếp hạng nhân viên".

## 5. CRM KPI — KPI cho module CRM (sale/marketing)

| Bảng | Mục đích |
|---|---|
| `tblCRM_KPI_Setup`, `tblCRM_KPI_Results` | Setup & kết quả |
| `tblCRM_KPICategories` | Loại KPI |
| `tblCRM_KPIContent`, `tbl_CRM_KPIContentPostType`, `tbl_CRM_KPIContentStatus` | KPI tạo content |
| `tblCRM_EmailKPI`, `EmailKPI_SyncRange` | KPI email sale |
| `tblCRM_KPIContactActivity`, `tblCRM_KPIDataCollection` | KPI tiếp xúc / thu thập data |
| `tblCRM_KPIScheduleMeeting`, `tblCRM_KPIScheduleMeetingAttendees`, `tblCRM_KPIScheduleSetting` | KPI họp khách |

Procedure: `sp_CRM_SaveConfigKPI`, `sp_CRM_RecalculateKPI`, `sp_CRM_KpiPedingApprove`, `sp_CRM_KpiPedingReject`, `sp_KPIProcessCustomer`, `sp_KPIgetDataCollection`, `sp_CRM_GetKPIResults`, `sp_CRM_EmailKPIFollow`.

> **Quy trình CRM KPI chi tiết**: xem [08_workflow_crm.md](08_workflow_crm.md) section 6 — "KPI CRM / sales".

## 6. Mối liên hệ với hệ Payroll

```
Performance Appraisal  →  [New basic salary]   →  tblSalaryHistory     →  SALCAL_MONTHLYBASIC_FINISHED
KPI System             →  tblBonusKPI          →  SALCAL_ALLOWANCE_* / SALCAL_ADJUSTMENT_*
                          tblEfficiencyBonus
                          tblPerformenceBonusPayment
Rank / Coin            →  tblRank_Payment_Transactions   →  tblSal_Adjustment
Probation Pass         →  ký HĐ chính thức     →  tblLabourContract    →  cập nhật bậc lương mới
```

## 7. Câu SQL hỗ trợ

```sql
-- Liệt kê phiếu đánh giá của 1 NV theo kỳ
SELECT pa.AppraisalID, p.PeriodEvaluationName, pa.TotalScore,
       pa.GradeRatingID, pa.Approve_Status, pa.isComplete
FROM tblPerformanceAppraisal pa
INNER JOIN tblPerformanceAppraisalPeriod p ON p.EvaluationID = pa.EvaluationID
WHERE pa.EmployeeID = N'<EmployeeID>'
ORDER BY p.FromDate DESC;

-- Chi tiết điểm từng tiêu chí của 1 phiếu
SELECT ai.AppraisalItemName, ai.StandardCore, d.Score,
       (d.Score - ai.StandardCore) AS Variance
FROM tblPerformanceAppraisal_Detail d
INNER JOIN tblAppraisalItems ai ON ai.AppraisalItemID = d.AppraisalItemID
WHERE d.AppraisalID = <AppraisalID>;

-- Xếp hạng KPI nhân viên
EXEC dbo.sp_KPIgetEmployeeKpiRanking;

-- Danh sách NV sắp hết hạn thử việc (14 ngày tới)
SELECT EmployeeID, FullName, PositionName, ContractStartDay, ContractEndDay, Duration
FROM tblPROBATIONASSESSEMENT
WHERE ContractEndDay BETWEEN GETDATE() AND DATEADD(DAY, 14, GETDATE())
ORDER BY ContractEndDay;

-- Tổng XP + Coin của 1 NV
SELECT SUM(ExperiencePonits) AS TotalXP, SUM(Coin) AS TotalCoin
FROM tblRank_PersonalRating_Detail
WHERE EmployeeID = N'<EmployeeID>';
```
