# 09 — Workflow: Quy trình tính lương cuối tháng (Payroll pipeline)

> Pipeline 10 giai đoạn từ khoá công đến phát hành phiếu lương. Liên quan: [05_db_attendance.md](05_db_attendance.md) (giai đoạn 1 dùng output của pipeline chấm công), [10_workflow_performance.md](10_workflow_performance.md) (giai đoạn 2 nhận output từ KPI/Appraisal), [02_db_employee.md](02_db_employee.md) (cột bank cho giai đoạn 9).

Pipeline gồm **10 giai đoạn** chạy tuần tự. Procedure entry point chính: **`SALCAL_MAIN`**.

## Lưu đồ tổng quan

```
[1] Khoá bảng chấm công  →  [2] Nhập dữ liệu lương ngoài  →  [3] SALCAL_MAIN (tính lương)
                                                                   │
        [4] Tính BHXH/BHYT/BHTN  ←─────────────────────────────────┤
                  │                                                 │
        [5] Tính thuế TNCN  ←──────────────────────────────────────┤
                  │                                                 │
        [6] Phí công đoàn  ←───────────────────────────────────────┘
                  │
                  ▼
        [7] Check lỗi → Khoá kỳ lương (tblSal_Lock)
                  │
                  ▼
        [8] Tổng hợp bảng lương toàn cty (sp_CompanySalarySummary)
                  │
                  ▼
        [9] Xuất file chuyển khoản bank (rpt_PR_SalaryToBank)
                  │
                  ▼
        [10] Phát hành phiếu lương (Payslip_Send_Submitted)
```

## Giai đoạn 1 — Khoá bảng chấm công

- Chốt `CHECKINOUT` + `tblTmpAttend` đến hết kỳ (xem [05_db_attendance.md](05_db_attendance.md)).
- Xử lý xong đơn xác nhận trong `tblAttendanceConfirmRequest`.
- Phê duyệt OT (`Overtime_Assignment_Do_Approve`).
- `LockAttendanceData_PreProcess` → kiểm tra trước khi khoá.
- Ghi `tblSal_Lock` (LockType = TA) → chặn sửa công.

## Giai đoạn 2 — Nhập dữ liệu lương ngoài (trước khi chạy SALCAL)

| Khoản | Bảng / Procedure |
|---|---|
| Phụ cấp định kỳ | `tblPR_EmpAllowance`, `tblEmployeeAllowance`, `PR_EmployeeAllowance_Insert` |
| Phụ cấp 1 lần / import | `Import_PRAllowance` |
| Điều chỉnh thu nhập không cố định | `tblSal_Adjustment`, `tblSal_Adjustment_ForAllowance`, `tblPR_Adjustment` |
| Tạm ứng | `tblSal_Advance`, `SAL_Advance_Process`, `SAL_Advance_SignedList` |
| Thưởng KPI / hiệu suất | `tblBonusKPI`, `tblKPITarget`, `tblEfficiencyBonus`, `tblPerformenceBonusPayment` |
| Thưởng Tết / năm | `tblTetBonusPayment`, `tblYearlyBonusRate_MBN` |
| Lương nước ngoài | `Import_Salary_Abroad` → `tblSalaryAbroad`, `tblSalaryImport_TriLuat` |
| Truy lĩnh / hồi tố | `tblSal_Retro`, `tblSal_Retro_Imported`, `tblSal_Retro_Sumary` |
| Trợ cấp thôi việc | `tblTerminateAllowance` |

## Giai đoạn 3 — Tính lương (SALCAL_MAIN dispatcher)

`SALCAL_MAIN` orchestrate các sub-procedure theo thứ tự. Mỗi cấu phần thường có cặp `_INITIAL` / `_FINISHED`:

| Step | Procedure | Output |
|---|---|---|
| Chuẩn bị bảng tạm | `SALCAL_ADD_COLUMN_INTO_TMP_TABLE` | — |
| IO (giờ vào/ra) | `SALCAL_IO_INITIAL` → `SALCAL_IO` → `SALCAL_CustomizeIO` | `tblSal_IO`, `tblSal_IO_Detail` |
| Ca đêm | `SALCAL_NS_INITIAL` → `SALCAL_NS_FINISHED` | `tblSal_NS`, `tblSal_NS_Detail` |
| Tăng ca (OT) | `SALCAL_OT_INITIAL` → `SALCAL_OT_FINISHED`, `sp_CreateSalaryOT` | `tblSal_OT`, `tblSal_OT_Detail` |
| Phép có lương | `SALCAL_LEAVE_AUTOMATIC_FINISHED`, `SAL_CAL_LEAVE_NEWCOMER` | `tblSal_PaidLeave`, `tblSal_PaidLeave_Detail` |
| Lương cơ bản tháng | `SALCAL_MONTHLYBASIC_FINISHED`, `SALCAL_PROCESS_MULTISALARY_LEVEL`, `SALCAL_EXCHANGERATESALARY` | `tblSal_Sal`, `tblSal_Sal_Detail` |
| Phụ cấp | `SALCAL_ALLOWANCE_BEFORE_PROCESS` → `_CUSTOMER_RULE` → `_DILIGENTALL_INITIAL/_FINISHED` → `_SENIORIRY_INITIAL/_FINISHED` → `_FINISHED` | `tblSal_Allowance`, `tblSal_Allowance_Detail` |
| Điều chỉnh | `SALCAL_ADJUSTMENT_INITIAL` → `_BEFORE_INSERT` → `SALCAL_ADJUSTMENT` → `_FINISHED` | `tblSal_Adjustment` |
| Customize / note | `SALCAL_CUSTOMIZE_TADATA`, `SALCAL_NOTE` | — |

## Giai đoạn 4 — Tính bảo hiểm (BHXH/BHYT/BHTN)

```
EmpInsuranceMonthly_BeforeCalculate
  → SALCAL_INSURANCE
  → sp_CreateSalaryInsurance
  → sp_AverageSISalary_ByEmployeeAmt          (lương BH bình quân)
  → sp_CreateCurrentSISalary_byDateFunction
  → EmpInsuranceMonthly_AfterCalculate
  → tblSal_Insurance, tblEmpInsuranceMonthly
```

Đối chiếu BHXH (kê khai cơ quan BH):

| Bảng | Mục đích |
|---|---|
| `tblDanhSachDeNghiTangBHXH` | Đề nghị tăng (NV mới đóng) |
| `tblDanhSachDeNghiGiamBHXH` | Đề nghị giảm (NV nghỉ) |
| `tblDanhSachDieuChinhLuongBHXH` | Điều chỉnh mức lương đóng |
| `tblCutSIHistory_BHXH`, `tblCutSIUnpaidLeave_BHXH` | Cắt BH (nghỉ không lương) |
| `tblHuongCheDoOmDau_BHXH`, `tblHuongCheDoThaiSan_BHXH`, `tblHuongNghiDSPHSK_BHXH` | Hưởng chế độ ốm đau / thai sản / DSPHSK |
| `tblSI_SummaryHeader_BHXH`, `tblSISummaryInfo_BHXH`, `tblSID02_TS_BHXH` | Tổng hợp kê khai |
| `tblPrintA01FormListBHXH` | Form A01 |
| `tblNotEmpinsuranceByDecreaseEms` | NV không đóng BH (do giảm) |
| `tblDongOCtyKhac_BHXH` | NV đóng BH ở công ty khác |
| `tblExcel_Insurance` | Export Excel cho cơ quan BH |
| `tblSIPercentageHistory` | Lịch sử tỷ lệ % đóng |

## Giai đoạn 5 — Tính thuế TNCN (PIT)

| Procedure | Đối tượng |
|---|---|
| `SALCAL_TAX_INITIAL` | NV có HĐ chính thức — tính luỹ tiến |
| `SALCAL_TAX_10_INITIAL` | NV thời vụ / cộng tác viên — khấu trừ 10% |
| `SALCAL_TAX_FINISHED` | Hoàn tất tính thuế |

Tham chiếu:
- `tblContract_PIT_Status` — loại thuế theo HĐ.
- `tblPITforExpat` — thuế cho người nước ngoài.
- `tblFamilyInfo_Adjustment` — người phụ thuộc giảm trừ.
- `tblPIT_Adjustment_For_ChangedDependants` — điều chỉnh khi thay đổi người phụ thuộc.
- Tham số `CAL_SALTAX_PROGRESSIVE_ALLEMPS` (`tblParameter`) quyết định có áp luỹ tiến cho thời vụ / học việc / thử việc hay khấu trừ 10%.

Output: `tblSal_Tax`, `tblTax`, `tblTaxDeduction`, `tblTaxSetlement` (quyết toán năm).

## Giai đoạn 6 — Phí công đoàn (Trade Union Fee)

**Logic tính nằm trực tiếp trong `SALCAL_MAIN`** (không phải sub-procedure riêng). `sys.sql_expression_dependencies` xác nhận chỉ `SALCAL_MAIN` và `sp_UnionFeeMethod_List` tham chiếu `tblUnionFeeMethod`.

### 6.1. Master `tblUnionFeeMethod` — 4 phương pháp đăng ký trong DB

| ID | Mô tả | Comp_% | Emp_% | Comp_Fixed | Emp_Fixed |
|---:|---|---:|---:|---:|---:|
| 0 | Công ty chưa thành lập công đoàn | 0 | 0 | 0 | 0 |
| 1 | Chỉ công ty đóng 2% | 2 | 0 | 0 | 0 |
| 2 | Công ty 2%, NV 1% | 2 | 1 | 0 | 0 |
| 3 | Công ty 2%, NV cố định 35,000 | 2 | 0 | 0 | 35,000 |

Cấu trúc bảng:
- `Comp_ByPercent` / `Emp_ByPercent` (bit) — đóng theo % hay số cố định.
- `UNION_PERCENT_COMP` / `UNION_PERCENT_EMP` — % nếu chọn theo %.
- `UNION_PACKAGE_COMP` / `UNION_PACKAGE_EMP` — số tiền cố định.
- `Is_CeilSalary` (bit) — dùng lương trần BHXH làm base thay vì SI income thực.
- `MaximumByPercentsOfBaseSalaryRegional` — chặn theo % lương tối thiểu vùng.
- `UNION_PACKAGE_EMP_MAX`, `UNION_PACKAGE_COMP_MAX` (money) — chặn mức tuyệt đối.

### 6.2. Chọn phương pháp cho từng NV (thứ tự ưu tiên)

```sql
left join tblUnionFeeMethod f on f.UnionFeeMethodID =
    isnull(isnull(div.UNION_FEE_METHOD, c.UNION_FEE_METHOD), 3)
```

1. `tblDivision.UNION_FEE_METHOD` — cấu hình theo Division.
2. `tblCompany.UNION_FEE_METHOD` — cấu hình toàn công ty.
3. Default = 3 nếu cả 2 đều NULL.

> Tham số `tblParameter.UNION_FEE_METHOD` (hiện = 0) **chỉ là fallback secondary**, không phải nguồn chính.

### 6.3. Công thức tính (verbatim từ `SALCAL_MAIN`)

```sql
update #tblTradeUnion
set UnionFeeEmp  = case when isnull(Emp_ByPercent, 0) = 1
                        then UNION_PERCENT_EMP * BasicSalary / 100
                        else UNION_PACKAGE_EMP
                   end * IsEmpPaid,
    UnionFeeComp = case when isnull(Comp_ByPercent, 0) = 1
                        then UNION_PERCENT_COMP * BasicSalary / 100
                        else UNION_PACKAGE_COMP
                   end * IsComPaid
```

- **Phí NV** = (theo % thì `%_EMP × BasicSalary / 100`, ngược lại số cố định `PACKAGE_EMP`) × `IsEmpPaid`.
- **Phí công ty** = tương tự × `IsComPaid`.

### 6.4. `BasicSalary` — thứ tự ưu tiên

1. `SIIncome` từ `tblSal_Insurance_Forquery` (lương đóng BHXH tháng hiện tại, từ `tblSal_Insurance` / `tblSal_Insurance_Retro`).
2. Nếu không có → `fn_CurrentSISalary_byDate(@SIDate, @LoginID)` (lương đóng BHXH theo ngày 15 kỳ).
3. Nếu `Is_CeilSalary = 1` → ghi đè bằng `MinimumSal` từ `tblSI_CeilSalary` (lương trần BHXH).

`BaseSalaryRegional` = `MinimumSal` (lương tối thiểu vùng).

### 6.5. Điều kiện đóng (`IsEmpPaid` / `IsComPaid`)

| Quy tắc | Hiệu lực |
|---|---|
| Mặc định | `IsEmpPaid = 0`, `IsComPaid = 1` (chỉ công ty đóng) |
| NV có trong `fn_EmployeeUnion_ByDate(@ToDate)` với `EmployeePay = 1` và kỳ hiệu lực bao phủ `@SIDate` | → `IsEmpPaid = 1` |
| Báo giảm BHXH tháng này (không có phát sinh `EmployeeSI` và `CompanySI`) | → cả `IsComPaid` và `IsEmpPaid` = `0` |
| NV không có công đi làm (`TotalPaidDays = 0`) | → `IsEmpPaid = 0` (công ty vẫn đóng) |

Quy tắc nghiệp vụ comment trong source: *"có phát sinh BHXH trong tháng này thì sẽ đóng tiền công đoàn"*.

### 6.6. Clamp sau khi tính

1. **Chặn theo % lương tối thiểu vùng** (nếu `MaximumByPercentsOfBaseSalaryRegional > 0`):
   ```sql
   UPDATE #tblTradeUnion set UnionFeeEmp = BaseSalaryRegional * MaximumByPercentsOfBaseSalaryRegional / 100
   where MaximumByPercentsOfBaseSalaryRegional > 0
     and UnionFeeEmp > BaseSalaryRegional * MaximumByPercentsOfBaseSalaryRegional / 100
   ```
2. **Override nếu user nhập tay trong `tblSal_Insurance`** (cho phép admin sửa thủ công):
   ```sql
   UPDATE #tblTradeUnion SET UnionFeeEmp = ISNULL(i.UnionFeeEmp, u.UnionFeeEmp),
                              UnionFeeComp = ISNULL(i.UnionFeeComp, u.UnionFeeComp)
   from #tblTradeUnion u inner join #tblSal_Insurance_Forquery i on u.EmployeeID = i.EmployeeID
   where i.UnionFeeEmp is not null or i.UnionFeeComp is not null
   ```
3. **Chặn mức tuyệt đối**:
   ```sql
   update #tblTradeUnion set UnionFeeEmp  = UNION_PACKAGE_EMP_MAX  where UNION_PACKAGE_EMP_MAX  > 0 and UnionFeeEmp  > UNION_PACKAGE_EMP_MAX
   update #tblTradeUnion set UnionFeeComp = UNION_PACKAGE_COMP_MAX where UNION_PACKAGE_COMP_MAX > 0 and UnionFeeComp > UNION_PACKAGE_COMP_MAX
   ```

### 6.7. Ghi vào `tblSal_Sal`

4 cột (kiểu `money`):

```sql
UPDATE sal SET
  EmpUnion_RETRO  = round(re.Union_RETRO_EE, 0),
  EmpUnion        = round(uni.UnionFeeEmp, 0),
  CompUnion_RETRO = round(re.Union_RETRO_ER, 0),
  CompUnion       = round(uni.UnionFeeComp, 0)
FROM #tblSalDetail sal
LEFT JOIN #tblTradeUnion uni       ON sal.EmployeeID = uni.EmployeeID
LEFT JOIN #tblsal_retro_Final re   ON sal.EmployeeID = re.EmployeeID
WHERE sal.LatestSalEntry = 1
```

### 6.8. Tác động xuống các cột tổng hợp lương

**`GrossTakeHome` (lương thực lãnh) — `EmpUnion` bị trừ:**

```sql
GrossTakeHome = round((ActualMonthlyBasic + TotalOTAmount + TotalNSAmt
                       + TotalAllowanceForSalary + TotalAdjustmentForSalary), @ROUND_TAKE)
              - (InsAmt + IOAmt + EmpUnion)
```

**`TotalCostComPaid` (tổng chi phí công ty) — `CompUnion` cộng vào:**

```sql
TotalCostComPaid = ActualMonthlyBasic + TotalOTAmount + TotalNSAmt
                 + TaxableAllowanceTotal + NoneTaxableAllowanceTotal
                 + InsAmtComp - IOAmt + CompUnion + CompUnion_RETRO
                 + (IsNet = 1 ? InsAmt : 0)
```

### 6.9. 5 phương pháp theo comment source (tham chiếu)

Comment trong `SALCAL_MAIN` liệt kê 5 phương pháp `UNION_FEE_METHOD` cũ:
1. Dựa vào phần trăm lương.
2. Số tiền đóng cố định.
3. NV đóng số tiền cố định, công ty đóng theo % lương cơ bản.
4. Đóng theo phần trăm lương tối thiểu.
5. Đóng theo phần trăm lương cơ bản, NV đóng tối đa 10% lương tối thiểu.

> Lưu ý: thực tế DB hiện chỉ có 4 record (`UnionFeeMethodID = 0..3`) trong `tblUnionFeeMethod`. Cấu hình per-record qua các cờ `Comp_ByPercent/Emp_ByPercent/Is_CeilSalary/MaximumByPercentsOfBaseSalaryRegional` đã đủ biểu diễn cả 5 phương pháp trên.

## Giai đoạn 7 — Kiểm tra lỗi & khoá kỳ lương

```
PR_SalCal_GetError  → kiểm tra tblSal_Error
SALCAL_FinishUpdateSalDetail
sp_CheckSalCal_BusinessFlow
   ↓
Ghi tblSal_Lock (LockType = SAL) → chặn tính lại
sp_CheckLockSalByMonthAndYear / sp_CheckLockedMonth_Data       (verify)
sp_CompletedAndLockInsuranceData_BHXH → tblLockDeclareInsuranceData_BHXH   (khoá BHXH)
```

Quản lý lock: `PR_Sal_Lock_Update`, `PR_Sal_Lock_Delete`, `PR_Sal_Entry_Delete`.

## Giai đoạn 8 — Tổng hợp bảng lương toàn công ty

```
sp_CompanySalarySummary_BeforeLoad
  → sp_CompanySalarySummary   (variants: _STD, _EMC, _view, _Export01)
  → sp_CompanySalaryReport
  → tblSalarySummaryData_Lotte  (customer-specific) hoặc grid view
```

## Giai đoạn 9 — Xuất file chuyển khoản ngân hàng

Tham chiếu thông tin trên `tblEmployee`: `BankCode`, `AccountNo`, `AccountName`, `IDForBankTransfer` (xem [02_db_employee.md](02_db_employee.md)). Cấu hình ngân hàng: `MD_BankSetting_List`, `HR_BankInfor_List`, `HR_StaffInformationBank`.

```
rpt_PR_SalaryToBank          → xuất Excel/file theo format từng bank
sp_CompanySalaryPayment_Process  → đánh dấu đã thanh toán
→ ghi tblCompanySalaryPayment
```

## Giai đoạn 10 — Công bố phiếu lương (Payslip)

| Procedure | Mục đích |
|---|---|
| `EmployeePaySlip_Links` | Sinh link payslip per-employee |
| `Payslip_Send_Submitted` | Gửi / đánh dấu đã phát hành |
| `rpt_PR_PaySlip_PaidLeaveDetail` | Chi tiết phép kèm payslip |

Nhân viên xem trên **Web/Mobile ESS** (xem [01_architecture.md](01_architecture.md)). Có thể gửi qua email (`tblPendingEmail`) hoặc Zalo (`tblZaloMessage`).

## Tham số `tblParameter` chi phối tính lương

| Code | Ý nghĩa |
|---|---|
| `CAL_SALTAX_PROGRESSIVE_ALLEMPS` | Áp dụng thuế luỹ tiến cho cả thời vụ / học việc / thử việc? |
| `ROUND_ATTDAYS` | Làm tròn ngày công hưởng lương |
| `HAFT_DAY_ATT_OPTION` | Cách tính nghỉ nửa buổi |
| `ATT_SHOWTIMEINOUT` | Chế độ hiển thị bảng công tổng hợp |

## Câu SQL hỗ trợ debug / kiểm tra trạng thái

```sql
-- Check kỳ đã khoá chưa
EXEC dbo.sp_CheckLockSalByMonthAndYear @Month = 5, @Year = 2026;

-- Lấy lỗi tính lương
EXEC dbo.PR_SalCal_GetError;

-- Bảng kỳ lương đang khoá
SELECT * FROM tblSal_Lock ORDER BY [Year] DESC, [Month] DESC;

-- Bảng lương 1 NV trong tháng
SELECT * FROM tblSal_Sal
WHERE EmployeeID = N'<EmployeeID>' AND [Month] = 5 AND [Year] = 2026;
```
