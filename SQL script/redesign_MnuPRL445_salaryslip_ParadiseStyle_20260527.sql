
-- =====================================================================================
-- Phase 1: Tạo wrapper sp_salaryslip (đọc từ cache)
-- =====================================================================================

CREATE OR ALTER PROCEDURE [dbo].[sp_salaryslip]
(
    @LoginID    INT          = 3,
    @LanguageID VARCHAR(5)   = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 1 html
    FROM dbo.tblHtmlScriptCache
    WHERE TableName  = 'sp_salaryslip_html'
      AND ScreenType = '-1'
      AND LanguageID = @LanguageID;
END
GO

PRINT '1. Da tao wrapper sp_salaryslip.';
GO

-- =====================================================================================
-- Phase 2: Tạo renderer sp_salaryslip_html (ParadiseStyle CSS + MERGE cache)
-- =====================================================================================

CREATE OR ALTER PROCEDURE [dbo].[sp_salaryslip_html]
(
    @LoginID    INT          = 3,
    @LanguageID VARCHAR(5)   = 'VN',
    @isWeb      INT          = 1
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Layer 2: Text đa ngôn ngữ
    DECLARE @tabPayslip     NVARCHAR(100);
    DECLARE @tabHistory     NVARCHAR(100);
    DECLARE @allYears       NVARCHAR(100);
    DECLARE @noData         NVARCHAR(200);
    DECLARE @noOvertime     NVARCHAR(200);
    DECLARE @noDaysOff      NVARCHAR(200);
    DECLARE @noLateEarly    NVARCHAR(200);
    DECLARE @loading        NVARCHAR(100);
    DECLARE @errorLoading   NVARCHAR(200);
    DECLARE @errorApi       NVARCHAR(200);
    DECLARE @viewBtn        NVARCHAR(50);
    DECLARE @titlePayslip   NVARCHAR(200);
    DECLARE @titleMonthYear NVARCHAR(100);
    DECLARE @labelEmpID     NVARCHAR(100);
    DECLARE @labelFullName  NVARCHAR(100);
    DECLARE @labelHireDate  NVARCHAR(100);
    DECLARE @labelPosition  NVARCHAR(100);
    DECLARE @labelDepend    NVARCHAR(100);
    DECLARE @secSalary      NVARCHAR(100);
    DECLARE @secOtherInc    NVARCHAR(100);
    DECLARE @secDeduction   NVARCHAR(100);
    DECLARE @secTax         NVARCHAR(100);
    DECLARE @secNet         NVARCHAR(100);
    DECLARE @labelStdDays   NVARCHAR(100);
    DECLARE @labelActDays   NVARCHAR(100);
    DECLARE @labelOTHours   NVARCHAR(100);
    DECLARE @labelDaysOff   NVARCHAR(100);
    DECLARE @labelLateEarly NVARCHAR(100);
    DECLARE @labelDaySalary NVARCHAR(100);
    DECLARE @labelOTSalary  NVARCHAR(100);
    DECLARE @totalOtherInc  NVARCHAR(100);
    DECLARE @totalIncome    NVARCHAR(100);
    DECLARE @totalDeduction NVARCHAR(100);
    DECLARE @labelSelfTax   NVARCHAR(100);
    DECLARE @labelDepTax    NVARCHAR(100);
    DECLARE @labelTaxIncome NVARCHAR(100);
    DECLARE @labelPIT       NVARCHAR(100);
    DECLARE @netTakeHome    NVARCHAR(100);
    DECLARE @days           NVARCHAR(20);
    DECLARE @hours          NVARCHAR(20);
    DECLARE @minutes        NVARCHAR(20);
    DECLARE @monthLabel     NVARCHAR(50);
    DECLARE @overtimeTitle  NVARCHAR(200);
    DECLARE @daysOffTitle   NVARCHAR(200);
    DECLARE @lateEarlyTitle NVARCHAR(200);
    DECLARE @colDate        NVARCHAR(50);
    DECLARE @colStart       NVARCHAR(50);
    DECLARE @colEnd         NVARCHAR(50);
    DECLARE @colHours       NVARCHAR(50);
    DECLARE @colLeaveType   NVARCHAR(50);
    DECLARE @colMinutes     NVARCHAR(50);

    IF @LanguageID = 'EN'
    BEGIN
        SET @tabPayslip     = N'Pay Slip';
        SET @tabHistory     = N'History';
        SET @allYears       = N'All years';
        SET @noData         = N'No payslip data.';
        SET @noOvertime     = N'No overtime data.';
        SET @noDaysOff      = N'No days off data.';
        SET @noLateEarly    = N'No late/early data.';
        SET @loading        = N'Loading...';
        SET @errorLoading   = N'Error loading history. Please try again.';
        SET @errorApi       = N'Invalid API data. Please try again.';
        SET @viewBtn        = N'View';
        SET @titlePayslip   = N'EMPLOYEE PAY SLIP';
        SET @titleMonthYear = N'Month/Year';
        SET @labelEmpID     = N'Employee ID';
        SET @labelFullName  = N'Full Name';
        SET @labelHireDate  = N'Hire Date';
        SET @labelPosition  = N'Position';
        SET @labelDepend    = N'Dependants';
        SET @secSalary      = N'I/ Salary Information';
        SET @secOtherInc    = N'II/ Other Incomes';
        SET @secDeduction   = N'III/ Deductions';
        SET @secTax         = N'IV/ Personal Income Tax';
        SET @secNet         = N'V/ Net Take Home';
        SET @labelStdDays   = N'Standard days';
        SET @labelActDays   = N'Actual days';
        SET @labelOTHours   = N'Overtime hours';
        SET @labelDaysOff   = N'Days off';
        SET @labelLateEarly = N'Late/Early';
        SET @labelDaySalary = N'Daily wage';
        SET @labelOTSalary  = N'OT wage';
        SET @totalOtherInc  = N'Total other incomes';
        SET @totalIncome    = N'TOTAL INCOME';
        SET @totalDeduction = N'Total deduction';
        SET @labelSelfTax   = N'Self deduction';
        SET @labelDepTax    = N'Dependant deduction';
        SET @labelTaxIncome = N'Taxable income';
        SET @labelPIT       = N'PIT payable';
        SET @netTakeHome    = N'NET TAKE HOME';
        SET @days           = N'days';
        SET @hours          = N'hours';
        SET @minutes        = N'minutes';
        SET @monthLabel     = N'Month';
        SET @overtimeTitle  = N'Overtime Details';
        SET @daysOffTitle   = N'Days Off Details';
        SET @lateEarlyTitle = N'Late/Early Details';
        SET @colDate        = N'Date';
        SET @colStart       = N'Start';
        SET @colEnd         = N'End';
        SET @colHours       = N'Hours';
        SET @colLeaveType   = N'Leave Type';
        SET @colMinutes     = N'Minutes';
    END
    ELSE
    BEGIN
        SET @tabPayslip     = N'Phiếu Lương';
        SET @tabHistory     = N'Lịch Sử';
        SET @allYears       = N'Tất cả các năm';
        SET @noData         = N'Không có dữ liệu phiếu lương.';
        SET @noOvertime     = N'Không có dữ liệu tăng ca.';
        SET @noDaysOff      = N'Không có dữ liệu ngày nghỉ.';
        SET @noLateEarly    = N'Không có dữ liệu đi trễ/về sớm.';
        SET @loading        = N'Đang tải...';
        SET @errorLoading   = N'Lỗi tải lịch sử. Vui lòng thử lại.';
        SET @errorApi       = N'Dữ liệu từ API không hợp lệ. Vui lòng thử lại.';
        SET @viewBtn        = N'Xem';
        SET @titlePayslip   = N'PHIẾU LƯƠNG NHÂN VIÊN';
        SET @titleMonthYear = N'Tháng/Năm';
        SET @labelEmpID     = N'Mã nhân viên';
        SET @labelFullName  = N'Họ và tên';
        SET @labelHireDate  = N'Ngày vào làm';
        SET @labelPosition  = N'Chức vụ';
        SET @labelDepend    = N'Người phụ thuộc';
        SET @secSalary      = N'I/ Thông tin lương';
        SET @secOtherInc    = N'II/ Các khoản thu nhập khác';
        SET @secDeduction   = N'III/ Các khoản khấu trừ';
        SET @secTax         = N'IV/ Thông tin khấu trừ thuế TNCN';
        SET @secNet         = N'V/ Thực lãnh';
        SET @labelStdDays   = N'Công chuẩn';
        SET @labelActDays   = N'Công thực tế';
        SET @labelOTHours   = N'Số giờ tăng ca';
        SET @labelDaysOff   = N'Số ngày nghỉ';
        SET @labelLateEarly = N'Đi trễ/về sớm';
        SET @labelDaySalary = N'Lương ngày công';
        SET @labelOTSalary  = N'Lương TC';
        SET @totalOtherInc  = N'Tổng thu nhập khác';
        SET @totalIncome    = N'TỔNG LƯƠNG / TOTAL INCOME';
        SET @totalDeduction = N'Tổng khấu trừ / Total deduction';
        SET @labelSelfTax   = N'Giảm trừ thuế bản thân';
        SET @labelDepTax    = N'Giảm trừ người phụ thuộc';
        SET @labelTaxIncome = N'Thu nhập chịu thuế';
        SET @labelPIT       = N'Thuế TNCN phải đóng';
        SET @netTakeHome    = N'THỰC LÃNH / NET TAKE HOME';
        SET @days           = N'ngày';
        SET @hours          = N'giờ';
        SET @minutes        = N'phút';
        SET @monthLabel     = N'Tháng';
        SET @overtimeTitle  = N'Chi tiết tăng ca';
        SET @daysOffTitle   = N'Chi tiết ngày nghỉ';
        SET @lateEarlyTitle = N'Chi tiết đi trễ/về sớm';
        SET @colDate        = N'Ngày';
        SET @colStart       = N'Giờ bắt đầu';
        SET @colEnd         = N'Giờ kết thúc';
        SET @colHours       = N'Số giờ';
        SET @colLeaveType   = N'Loại nghỉ';
        SET @colMinutes     = N'Phút khấu trừ';
    END

    -- Layer 3: Escape text cho JS
    DECLARE @noDataJs       NVARCHAR(400) = REPLACE(REPLACE(@noData,       N'\', N'\\'), N'"', N'\"');
    DECLARE @noOvertimeJs   NVARCHAR(400) = REPLACE(REPLACE(@noOvertime,   N'\', N'\\'), N'"', N'\"');
    DECLARE @noDaysOffJs    NVARCHAR(400) = REPLACE(REPLACE(@noDaysOff,    N'\', N'\\'), N'"', N'\"');
    DECLARE @noLateEarlyJs  NVARCHAR(400) = REPLACE(REPLACE(@noLateEarly,  N'\', N'\\'), N'"', N'\"');
    DECLARE @loadingJs      NVARCHAR(200) = REPLACE(REPLACE(@loading,      N'\', N'\\'), N'"', N'\"');
    DECLARE @errorLoadJs    NVARCHAR(400) = REPLACE(REPLACE(@errorLoading, N'\', N'\\'), N'"', N'\"');
    DECLARE @errorApiJs     NVARCHAR(400) = REPLACE(REPLACE(@errorApi,     N'\', N'\\'), N'"', N'\"');
    DECLARE @viewBtnJs      NVARCHAR(100) = REPLACE(REPLACE(@viewBtn,      N'\', N'\\'), N'"', N'\"');
    DECLARE @daysJs         NVARCHAR(40)  = REPLACE(REPLACE(@days,         N'\', N'\\'), N'"', N'\"');
    DECLARE @hoursJs        NVARCHAR(40)  = REPLACE(REPLACE(@hours,        N'\', N'\\'), N'"', N'\"');
    DECLARE @minutesJs      NVARCHAR(40)  = REPLACE(REPLACE(@minutes,      N'\', N'\\'), N'"', N'\"');
    DECLARE @monthLabelJs   NVARCHAR(100) = REPLACE(REPLACE(@monthLabel,   N'\', N'\\'), N'"', N'\"');

    -- Layer 4: Build @html
    DECLARE @html NVARCHAR(MAX);

    SET @html = N'
<div id="psRoot" class="ps-page">
    <style>
        .ps-page {
            min-height: 100%;
            padding: var(--paradise-space-4);
            color: var(--paradise-text-body);
            font-family: var(--paradise-font-family-base);
        }
        .ps-container {
            max-width: 820px;
            margin: 0 auto;
            border: var(--paradise-card-border);
            border-radius: var(--paradise-card-radius);
            box-shadow: var(--paradise-card-shadow);
            background-color: var(--paradise-card-bg);
        }
        .ps-tab-nav {
            display: flex;
            align-items: center;
            border-bottom: 1px solid var(--paradise-border-color);
            padding: var(--paradise-space-2) var(--paradise-space-4);
            background-color: var(--paradise-bg-secondary-subtle);
            border-radius: var(--paradise-card-radius) var(--paradise-card-radius) 0 0;
        }
        .ps-tab-nav button.ps-tab-btn {
            background: none;
            border: none;
            padding: var(--paradise-space-2) var(--paradise-space-4);
            cursor: pointer;
            font-weight: var(--font-weight-semi-bold);
            font-size: var(--paradise-font-body1);
            color: var(--paradise-text-muted);
            margin: 0 var(--paradise-space-2);
            transition: var(--paradise-transition-fast);
            border-bottom: 2px solid transparent;
        }
        .ps-tab-nav button.ps-tab-btn.active {
            color: var(--paradise-color-primary);
            border-bottom-color: var(--paradise-color-primary);
        }
        .ps-tab-nav button.ps-back-btn {
            background: none;
            border: none;
            padding: var(--paradise-space-2);
            cursor: pointer;
            color: var(--paradise-color-primary);
            margin-right: auto;
            font-size: var(--paradise-font-body1);
            transition: var(--paradise-transition-fast);
        }
        .ps-tab-nav button.ps-back-btn:hover {
            color: var(--paradise-color-success);
        }
        .ps-tab-content {
            display: none;
        }
        .ps-tab-content.active {
            display: block;
        }
        .ps-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: var(--paradise-space-4);
            padding: var(--paradise-space-3) var(--paradise-space-4);
            border-bottom: 1px solid var(--paradise-border-color);
            color: var(--paradise-text-body);
        }
        .ps-header img {
            width: 100px;
            height: auto;
        }
        .ps-company-name {
            font-weight: var(--font-weight-bold);
            color: var(--paradise-color-primary);
        }
        .ps-company-addr {
            font-size: var(--paradise-font-body2);
            color: var(--paradise-text-muted);
        }
        .ps-payslip-title {
            text-align: center;
            font-weight: var(--font-weight-bold);
            color: var(--paradise-color-primary);
            text-transform: uppercase;
            font-size: var(--paradise-font-heading-main);
            padding: var(--paradise-space-3) var(--paradise-space-4) var(--paradise-space-1);
        }
        .ps-month-year {
            text-align: center;
            color: var(--paradise-text-muted);
            font-size: var(--paradise-font-body1);
            padding-bottom: var(--paradise-space-3);
        }
        .ps-info-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: var(--paradise-space-2);
            padding: 0 var(--paradise-space-3);
        }
        .ps-info-item {
            display: flex;
            align-items: baseline;
            padding: var(--paradise-space-2) var(--paradise-space-3);
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-md);
        }
        .ps-info-label {
            color: var(--paradise-text-muted);
            font-size: var(--paradise-font-body2);
            white-space: nowrap;
        }
        .ps-info-value {
            font-weight: var(--font-weight-semi-bold);
            margin-left: auto;
            font-size: var(--paradise-font-body2);
        }
        .ps-info-value .ps-eye {
            cursor: pointer;
            margin-left: var(--paradise-space-2);
            color: var(--paradise-text-muted);
            font-size: var(--paradise-font-body1);
            transition: var(--paradise-transition-fast);
        }
        .ps-info-value .ps-eye:hover {
            color: var(--paradise-color-primary);
        }
        .ps-section {
            padding: var(--paradise-space-2) var(--paradise-space-3);
        }
        .ps-section-title {
            padding: var(--paradise-space-2) var(--paradise-space-3);
            margin-bottom: var(--paradise-space-2);
            font-weight: var(--font-weight-bold);
            color: var(--paradise-color-primary);
            background-color: var(--paradise-bg-primary-subtle);
            border-radius: var(--paradise-border-radius-md);
            font-size: var(--paradise-font-body1);
        }
        .ps-total-item {
            display: flex;
            align-items: baseline;
            padding: var(--paradise-space-2) var(--paradise-space-3);
            border-radius: var(--paradise-border-radius-md);
            font-weight: var(--font-weight-bold);
        }
        .ps-net-item {
            display: flex;
            align-items: baseline;
            padding: var(--paradise-space-2) var(--paradise-space-3);
            border-radius: var(--paradise-border-radius-md);
            font-weight: var(--font-weight-bold);
            color: var(--paradise-color-primary);
            background-color: var(--paradise-bg-primary-subtle);
            border: 1px solid var(--paradise-color-primary);
        }
        .ps-net-item span:last-child {
            margin-left: auto;
        }
        .ps-modal {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background-color: var(--paradise-modal-backdrop);
            z-index: var(--paradise-z-modal);
        }
        .ps-modal-content {
            margin: 10% auto;
            padding: var(--paradise-space-5);
            border-radius: var(--paradise-modal-radius);
            box-shadow: var(--paradise-modal-shadow);
            background-color: var(--paradise-modal-bg);
            width: 90%;
            max-width: 600px;
            position: relative;
            color: var(--paradise-text-body);
        }
        .ps-modal-close {
            position: absolute;
            top: var(--paradise-space-2);
            right: var(--paradise-space-3);
            cursor: pointer;
            font-size: 1.5rem;
            color: var(--paradise-color-danger);
            transition: var(--paradise-transition-fast);
            background: none;
            border: none;
            line-height: 1;
        }
        .ps-modal-close:hover {
            color: var(--paradise-color-important);
        }
        .ps-detail-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: var(--paradise-space-3);
            font-size: var(--paradise-font-body2);
        }
        .ps-detail-table th,
        .ps-detail-table td {
            padding: var(--paradise-space-2) var(--paradise-space-3);
            border-bottom: 1px solid var(--paradise-border-color);
            text-align: left;
        }
        .ps-detail-table th {
            font-weight: var(--font-weight-semi-bold);
            color: var(--paradise-text-muted);
        }
        .ps-detail-table tr:last-child td {
            border-bottom: none;
        }
        .ps-year-filter {
            padding: var(--paradise-space-3);
            display: flex;
            align-items: center;
            gap: var(--paradise-space-3);
        }
        .ps-year-filter select {
            flex: 1;
            padding: var(--paradise-space-2) var(--paradise-space-3);
            border-radius: var(--paradise-input-border-radius);
            border: 1px solid var(--paradise-border-color);
            font-size: var(--paradise-font-body1);
            cursor: pointer;
            background-color: var(--paradise-bg-surface);
            color: var(--paradise-text-body);
            transition: var(--paradise-transition-fast);
        }
        .ps-year-filter select:focus {
            outline: none;
            border-color: var(--paradise-color-primary);
            box-shadow: 0 0 0 0.125rem var(--paradise-color-input-focus-ring);
        }
        .ps-history-list {
            display: flex;
            flex-direction: column;
            gap: var(--paradise-space-3);
            padding: var(--paradise-space-3);
        }
        .ps-payslip-item {
            display: flex;
            align-items: center;
            padding: var(--paradise-space-3);
            border: var(--paradise-card-border);
            border-radius: var(--paradise-card-radius);
            transition: var(--paradise-transition-fast);
            background-color: var(--paradise-card-bg);
        }
        .ps-payslip-item:hover {
            transform: translateY(-2px);
            box-shadow: var(--paradise-shadow-md);
            border-color: var(--paradise-border-strong);
        }
        .ps-payslip-info {
            flex: 1;
            display: flex;
            align-items: center;
            gap: var(--paradise-space-3);
        }
        .ps-payslip-month {
            font-size: var(--paradise-font-body1);
            font-weight: var(--font-weight-semi-bold);
            color: var(--paradise-text-body);
        }
        .ps-payslip-amount {
            font-size: var(--paradise-font-body1);
            color: var(--paradise-color-primary);
            font-weight: var(--font-weight-medium);
        }
        .ps-no-data {
            text-align: center;
            color: var(--paradise-text-muted);
            font-size: var(--paradise-font-body1);
            padding: var(--paradise-space-5);
        }
        .ps-total-row {
            display: flex;
            align-items: baseline;
            padding: var(--paradise-space-2) var(--paradise-space-3);
            border: 1px solid var(--paradise-border-color);
            border-radius: var(--paradise-border-radius-md);
            margin-top: var(--paradise-space-1);
        }
        .ps-amount-right {
            margin-left: auto;
            font-weight: var(--font-weight-semi-bold);
        }
        .ps-text-success { color: var(--paradise-color-primary); }
        .ps-text-danger  { color: var(--paradise-color-danger); }
        .ps-fw-bold { font-weight: var(--font-weight-bold); }

        @media (max-width: 768px) {
            .ps-page { padding: var(--paradise-space-2); }
            .ps-container { border: none; border-radius: 0; box-shadow: none; }
            .ps-tab-nav { border-radius: 0; }
            .ps-info-grid { grid-template-columns: 1fr; }
            .ps-header { flex-wrap: wrap; }
            .ps-modal-content { width: 95%; max-width: 95%; margin: 20% auto; }
            .ps-year-filter { flex-direction: column; }
            .ps-payslip-item { flex-wrap: wrap; gap: var(--paradise-space-2); }
        }
    </style>

    <div class="ps-container">
        <div class="ps-tab-nav">
            <button class="ps-back-btn" onclick="goBackFromChildMenu(''sp_SalarySlip'')" id="psBackBtn"><i class="bi bi-arrow-left"></i></button>
            <div style="flex-grow:1;display:flex;justify-content:center;">
                <button class="ps-tab-btn active" onclick="switchTabPs(''' + N'psPayslip' + N''')">' + @tabPayslip + N'</button>
                <button class="ps-tab-btn" onclick="switchTabPs(''' + N'psHistory' + N''')">' + @tabHistory + N'</button>
            </div>
        </div>

        <div id="psPayslip" class="ps-tab-content active">
            <div class="ps-header">
                <div style="flex-shrink:0;">
                    <img src="https://cdn.paradisehrm.com/Image/cropped-ParadiseHRCopyRight.png" alt="Logo ParadiseHR" />
                </div>
                <div style="text-align:right;">
                    <div class="ps-company-name" id="psCompanyName"></div>
                    <p class="ps-company-addr" id="psCompanyAddr"></p>
                </div>
            </div>

            <h2 class="ps-payslip-title">' + @titlePayslip + N'</h2>
            <p class="ps-month-year" id="psMonthYear"></p>

            <div class="ps-info-grid">
                <div class="ps-info-item"><span class="ps-info-label">' + @labelEmpID + N':</span><span class="ps-info-value" id="psEmpID"></span></div>
                <div class="ps-info-item"><span class="ps-info-label">' + @labelFullName + N':</span><span class="ps-info-value" id="psFullName"></span></div>
                <div class="ps-info-item"><span class="ps-info-label">' + @labelHireDate + N':</span><span class="ps-info-value" id="psHireDate"></span></div>
                <div class="ps-info-item"><span class="ps-info-label">' + @labelPosition + N':</span><span class="ps-info-value" id="psPosition"></span></div>
                <div class="ps-info-item"><span class="ps-info-label">' + @labelDepend + N':</span><span class="ps-info-value" id="psDependents"></span></div>
            </div>

            <div class="ps-section">
                <div class="ps-section-title">' + @secSalary + N'</div>
                <div class="ps-info-grid">
                    <div class="ps-info-item"><span class="ps-info-label">' + @labelStdDays + N':</span><span class="ps-info-value" id="psStdDays"></span></div>
                    <div class="ps-info-item"><span class="ps-info-label">' + @labelActDays + N':</span><span class="ps-info-value" id="psActDays"></span></div>
                    <div class="ps-info-item"><span class="ps-info-label">' + @labelOTHours + N':</span><span class="ps-info-value"><span id="psOTHours"></span><i class="bi bi-eye ps-eye" onclick="showPsModal(''' + N'overtime' + N''')"></i></span></div>
                    <div class="ps-info-item"><span class="ps-info-label">' + @labelDaysOff + N':</span><span class="ps-info-value"><span id="psDaysOff"></span><i class="bi bi-eye ps-eye" onclick="showPsModal(''' + N'daysoff' + N''')"></i></span></div>
                    <div class="ps-info-item"><span class="ps-info-label">' + @labelLateEarly + N':</span><span class="ps-info-value"><span id="psLateEarly"></span><i class="bi bi-eye ps-eye" onclick="showPsModal(''' + N'lateearly' + N''')"></i></span></div>
                    <div class="ps-info-item"><span class="ps-info-label">' + @labelDaySalary + N':</span><span class="ps-info-value" id="psBasicSalary"></span></div>
                    <div class="ps-info-item"><span class="ps-info-label">' + @labelOTSalary + N':</span><span class="ps-info-value" id="psOTSalary"></span></div>
                </div>
            </div>

            <div class="ps-section">
                <div class="ps-section-title">' + @secOtherInc + N'</div>
                <div class="ps-info-grid" id="psOtherIncomes"></div>
                <div class="ps-total-row"><span class="ps-fw-bold ps-text-success">' + @totalOtherInc + N':</span><span class="ps-amount-right ps-text-success" id="psTotalOther"></span></div>
                <div class="ps-total-row" style="margin-top:var(--paradise-space-2);"><span class="ps-fw-bold ps-text-success">' + @totalIncome + N':</span><span class="ps-amount-right ps-text-success" id="psTotalIncome"></span></div>
            </div>

            <div class="ps-section">
                <div class="ps-section-title">' + @secDeduction + N'</div>
                <div class="ps-info-grid" id="psDeductions"></div>
                <div class="ps-total-row"><span class="ps-fw-bold ps-text-danger">' + @totalDeduction + N':</span><span class="ps-amount-right ps-text-danger" id="psTotalDeductions"></span></div>
            </div>

            <div class="ps-section">
                <div class="ps-section-title">' + @secTax + N'</div>
                <div class="ps-info-grid">
                    <div class="ps-info-item"><span class="ps-info-label">' + @labelSelfTax + N':</span><span class="ps-info-value" id="psSelfTax"></span></div>
                    <div class="ps-info-item"><span class="ps-info-label">' + @labelDepTax + N':</span><span class="ps-info-value" id="psDepTax"></span></div>
                    <div class="ps-info-item"><span class="ps-info-label">' + @labelTaxIncome + N':</span><span class="ps-info-value" id="psTaxIncome"></span></div>
                    <div class="ps-info-item"><span class="ps-info-label">' + @labelPIT + N':</span><span class="ps-info-value ps-text-danger" id="psPIT"></span></div>
                </div>
            </div>

            <div class="ps-section">
                <div class="ps-section-title">' + @secNet + N'</div>
                <div class="ps-net-item"><span>' + @netTakeHome + N':</span><span id="psNetSalary"></span></div>
            </div>
        </div>

        <div id="psHistory" class="ps-tab-content">
            <div class="ps-year-filter">
                <select id="psYearSelect" onchange="filterPsHistory()">
                    <option value="">' + @allYears + N'</option>
                </select>
            </div>
            <div class="ps-history-list" id="psHistoryContent"></div>
        </div>

        <div id="psModalOvertime" class="ps-modal">
            <div class="ps-modal-content">
                <button class="ps-modal-close" onclick="closePsModal(''' + N'overtime' + N''')">&times;</button>
                <h2 style="margin:0 0 var(--paradise-space-3) 0;color:var(--paradise-text-body);font-size:var(--paradise-font-heading-main);">' + @overtimeTitle + N'</h2>
                <div id="psOvertimeDetail"></div>
            </div>
        </div>

        <div id="psModalDaysoff" class="ps-modal">
            <div class="ps-modal-content">
                <button class="ps-modal-close" onclick="closePsModal(''' + N'daysoff' + N''')">&times;</button>
                <h2 style="margin:0 0 var(--paradise-space-3) 0;color:var(--paradise-text-body);font-size:var(--paradise-font-heading-main);">' + @daysOffTitle + N'</h2>
                <div id="psDaysOffDetail"></div>
            </div>
        </div>

        <div id="psModalLateearly" class="ps-modal">
            <div class="ps-modal-content">
                <button class="ps-modal-close" onclick="closePsModal(''' + N'lateearly' + N''')">&times;</button>
                <h2 style="margin:0 0 var(--paradise-space-3) 0;color:var(--paradise-text-body);font-size:var(--paradise-font-heading-main);">' + @lateEarlyTitle + N'</h2>
                <div id="psLateEarlyDetail"></div>
            </div>
        </div>
    </div>
</div>

<script>
(function(){
    var NO_DATA      = "' + @noDataJs + N'";
    var NO_OVERTIME  = "' + @noOvertimeJs + N'";
    var NO_DAYSOFF   = "' + @noDaysOffJs + N'";
    var NO_LATEEARLY = "' + @noLateEarlyJs + N'";
    var LOADING      = "' + @loadingJs + N'";
    var ERROR_LOAD   = "' + @errorLoadJs + N'";
    var ERROR_API    = "' + @errorApiJs + N'";
    var VIEW_BTN     = "' + @viewBtnJs + N'";
    var DAYS         = "' + @daysJs + N'";
    var HOURS        = "' + @hoursJs + N'";
    var MINUTES      = "' + @minutesJs + N'";
    var MONTH_LABEL  = "' + @monthLabelJs + N'";

    var COL_DATE      = "' + @colDate + N'";
    var COL_START     = "' + @colStart + N'";
    var COL_END       = "' + @colEnd + N'";
    var COL_HOURS     = "' + @colHours + N'";
    var COL_LEAVE     = "' + @colLeaveType + N'";
    var COL_MINUTES   = "' + @colMinutes + N'";

    if (typeof $ === "undefined") { console.warn("jQuery not loaded"); }

    $("#header_sp_salaryslip").addClass("d-none");
    if (' + CAST(@isWeb AS NVARCHAR(20)) + N' == 1) {
        $("#psBackBtn").addClass("d-none");
    }
    $("#contentContainer_sp_salaryslip").css("height", "calc(100vh - 65px)");

    function formatCurrency(number) {
        return number != null ? new Intl.NumberFormat("en-US", { minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(number) : "0";
    }

    function formatDate(dateStr) {
        if (!dateStr) return "";
        var date = new Date(dateStr);
        return date.toLocaleDateString("vi-VN", { day: "2-digit", month: "2-digit", year: "numeric" });
    }

    function formatTime(timeStr) {
        if (!timeStr) return "";
        try {
            var cleanTime = timeStr.split(".")[0];
            return new Date("1970-01-01T" + cleanTime).toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" });
        } catch (e) { return ""; }
    }

    function stripHtml(value) {
        if (value === null || value === undefined) return "";
        return String(value).replace(/[<>"\u0027&]/g, "");
    }

    window.switchTabPs = function(tabId) {
        $(".ps-tab-content").removeClass("active");
        $(".ps-tab-btn").removeClass("active");
        $("#" + tabId).addClass("active");
        $("button[onclick*=\"" + tabId + "\"]").addClass("active");
        if (tabId === "psHistory") { loadPsHistory(); }
    };

    function buildDetailTable(rows, colKeys, emptyMsg) {
        var cols = colKeys || [];
        var html = "<table class=\"ps-detail-table\"><thead><tr>";
        for (var i = 0; i < cols.length; i++) {
            html += "<th>" + cols[i] + "</th>";
        }
        html += "</tr></thead><tbody>";
        if (!rows || rows.length === 0) {
            html += "<tr><td colspan=\"" + cols.length + "\" style=\"text-align:center;\">" + emptyMsg + "</td></tr>";
        } else {
            for (var j = 0; j < rows.length; j++) {
                var r = rows[j] || {};
                html += "<tr>";
                for (var k = 0; k < cols.length; k++) {
                    html += "<td>" + stripHtml(String(r["col" + k] || "")) + "</td>";
                }
                html += "</tr>";
            }
        }
        html += "</tbody></table>";
        return html;
    }

    window.showPsModal = function(type) {
        var dataRows = [];
        var cols = [];
        var emptyMsg = "";
        var detailId = "";

        if (type === "overtime") {
            var otData = window._empData && window._empData.OvertimeDetails ? window._empData.OvertimeDetails : [];
            for (var i = 0; i < otData.length; i++) {
                var item = otData[i] || {};
                dataRows.push({
                    col0: formatDate(item.OTDate),
                    col1: formatTime(item.OTFrom),
                    col2: formatTime(item.OTTo),
                    col3: (Number(item.OTHour) || 0) + " " + HOURS
                });
            }
            cols = [COL_DATE, COL_START, COL_END, COL_HOURS];
            emptyMsg = NO_OVERTIME;
            detailId = "psOvertimeDetail";
        } else if (type === "daysoff") {
            var doData = window._empData && window._empData.DaysOffDetails ? window._empData.DaysOffDetails : [];
            for (var j = 0; j < doData.length; j++) {
                var d = doData[j] || {};
                dataRows.push({
                    col0: formatDate(d.LeaveDate),
                    col1: stripHtml(String(d.LeaveCode || "")),
                    col2: (Number(d.LvAmount) || 0) + " " + HOURS
                });
            }
            cols = [COL_DATE, COL_LEAVE, COL_HOURS];
            emptyMsg = NO_DAYSOFF;
            detailId = "psDaysOffDetail";
        } else if (type === "lateearly") {
            var leData = window._empData && window._empData.LateEarlyDetails ? window._empData.LateEarlyDetails : [];
            for (var k = 0; k < leData.length; k++) {
                var le = leData[k] || {};
                dataRows.push({
                    col0: formatDate(le.IODate),
                    col1: formatTime(le.IOStart),
                    col2: formatTime(le.IOEnd),
                    col3: (Number(le.IOMinutesDeduct) || 0) + " " + MINUTES
                });
            }
            cols = [COL_DATE, COL_START, COL_END, COL_MINUTES];
            emptyMsg = NO_LATEEARLY;
            detailId = "psLateEarlyDetail";
        }

        if (detailId) {
            try {
                $("#" + detailId).html(buildDetailTable(dataRows, cols, emptyMsg));
            } catch (e) { console.error(e); }
        }

        var modalId = type === "overtime" ? "psModalOvertime" : (type === "daysoff" ? "psModalDaysoff" : "psModalLateearly");
        $("#" + modalId).css("display", "block");
    };

    window.closePsModal = function(type) {
        var modalId = type === "overtime" ? "psModalOvertime" : (type === "daysoff" ? "psModalDaysoff" : "psModalLateearly");
        $("#" + modalId).css("display", "none");
    };

    $(document).on("click", ".ps-modal", function(e) {
        if (e.target === this) { $(this).css("display", "none"); }
    });

    window._historyData = [];

    function loadPsHistory() {
        var container = $("#psHistoryContent");
        var yearSelect = $("#psYearSelect");
        container.empty();
        yearSelect.empty();
        yearSelect.append("<option value=\"\">' + @allYears + N'</option>");

        if (typeof AjaxHPAParadise !== "function") {
            container.html("<p class=\"ps-no-data\">" + ERROR_LOAD + "</p>");
            return;
        }

        AjaxHPAParadise({
            data: {
                name: "sp_getSalSalSalarySlip",
                param: ["LoginID", UserID]
            },
            success: function(result) {
                var response;
                try { response = JSON.parse(result); } catch (e) {
                    container.html("<p class=\"ps-no-data\">" + ERROR_API + "</p>");
                    return;
                }
                if (!response || !response.data || !response.data[0]) {
                    container.html("<p class=\"ps-no-data\">" + NO_DATA + "</p>");
                    return;
                }
                window._historyData = response.data[0] || [];
                var yearsSet = {};
                for (var i = 0; i < window._historyData.length; i++) {
                    yearsSet[window._historyData[i].Year] = true;
                }
                var years = Object.keys(yearsSet).sort(function(a, b) { return b - a; });
                for (var y = 0; y < years.length; y++) {
                    yearSelect.append("<option value=\"" + years[y] + "\">" + years[y] + "</option>");
                }
                filterPsHistory();
            },
            error: function() {
                container.html("<p class=\"ps-no-data\">" + ERROR_LOAD + "</p>");
            }
        });
    }

    window.filterPsHistory = function() {
        var selectedYear = $("#psYearSelect").val();
        var container = $("#psHistoryContent");
        container.empty();

        var filtered = window._historyData || [];
        if (selectedYear) {
            filtered = filtered.filter(function(item) { return item.Year == selectedYear; });
        }

        if (filtered.length === 0) {
            container.html("<p class=\"ps-no-data\">" + NO_DATA + "</p>");
            return;
        }

        filtered.sort(function(a, b) { return b.Year - a.Year || b.Month - a.Month; });
        var html = "";
        for (var i = 0; i < filtered.length; i++) {
            var item = filtered[i];
            var monthYear = String(item.Month).padStart(2, "0") + "/" + item.Year;
            var total = Number(item.GrossTakeHome) || 0;
            html += "<div class=\"ps-payslip-item\">";
            html += "<div class=\"ps-payslip-info\">";
            html += "<span class=\"ps-payslip-month\">" + MONTH_LABEL + " " + monthYear + "</span>";
            html += "<span class=\"ps-payslip-amount\">" + formatCurrency(total) + "</span>";
            html += "</div>";
            html += "<button class=\"paradise-btn paradise-btn--add\" onclick=\"viewPayslipPs(" + item.Month + "," + item.Year + ")\">" + VIEW_BTN + "</button>";
            html += "</div>";
        }
        try { container.html(html); } catch (e) { container.html("<p class=\"ps-no-data\">" + ERROR_LOAD + "</p>"); }
    };

    window.viewPayslipPs = function(month, year) {
        if (typeof AjaxHPAParadise !== "function") {
            alert(ERROR_LOAD);
            return;
        }
        AjaxHPAParadise({
            data: {
                name: "sp_PaySlipView",
                param: ["LoginID", UserID, "Month", month, "Year", year]
            },
            success: function(result) {
                var response;
                try { response = JSON.parse(result); } catch (e) {
                    alert(ERROR_API);
                    return;
                }
                if (!response || !response.data) return;
                var data = response.data;

                var companyData  = (data[0] && data[0].length) ? data[0][0] : {};
                var empArr       = data[1] || [];
                var allowanceData = data[4] || [];
                var prAdjustment = data[5] || [];
                var deductionsData = data[6] || [];
                var taxData      = data[7] || [];
                var overtimeData = data[8] || [];
                var daysOffData  = data[9] || [];
                var lateEarlyData = data[10] || [];

                var emp = (empArr && empArr.length) ? empArr[0] : {};
                window._empData = emp;
                window._empData.OvertimeDetails = overtimeData;
                window._empData.DaysOffDetails  = daysOffData;
                window._empData.LateEarlyDetails = lateEarlyData;

                $("#psCompanyName").text(stripHtml(companyData.CompanyFullName || ""));
                $("#psCompanyAddr").text(stripHtml(companyData.Address || ""));
                $("#psEmpID").text(stripHtml(emp.EmployeeID || ""));
                $("#psFullName").text(stripHtml(emp.FullName || ""));
                $("#psHireDate").text(formatDate(emp.HireDate));
                $("#psPosition").text(stripHtml(emp.PositionName || ""));
                $("#psDependents").text(stripHtml(emp.DependantNumber || ""));
                $("#psMonthYear").text(emp.Month && emp.Year ? "' + @titleMonthYear + N': " + stripHtml(String(emp.Month)) + "/" + stripHtml(String(emp.Year)) : "");

                $("#psStdDays").text((Number(emp.StandardWDays) || 0) + " ' + @days + N'");
                $("#psActDays").text((Number(emp.DaysOfSalEntry) || 0) + " ' + @days + N'");
                $("#psOTHours").text((Number(emp.OTHour) || 0) + " ' + @hours + N'");
                $("#psDaysOff").text((Number(emp.TotalLeave) || 0) + " ' + @days + N'");
                $("#psLateEarly").text((Number(emp.IOMinutesDeduct) || 0) + " ' + @days + N'");
                $("#psBasicSalary").text(formatCurrency(emp.ActualMonthlyBasic));
                $("#psOTSalary").text(formatCurrency(emp.OTAmount));

                var totalIncome = Number(emp.TotalIncome) || 0;
                $("#psTotalIncome").text(formatCurrency(totalIncome));

                var otherContainer = $("#psOtherIncomes");
                otherContainer.empty();
                var totalOther = 0;
                if (allowanceData && allowanceData.length) {
                    for (var ai = 0; ai < allowanceData.length; ai++) {
                        var al = allowanceData[ai];
                        var amt = Number(al.Amount) || 0;
                        totalOther += amt;
                        var name = stripHtml(al.AllowanceName || "");
                        otherContainer.append("<div class=\"ps-info-item\"><span class=\"ps-info-label\">" + name + ":</span><span class=\"ps-info-value\">" + formatCurrency(amt) + "</span></div>");
                    }
                }
                if (prAdjustment && prAdjustment.length) {
                    for (var pi = 0; pi < prAdjustment.length; pi++) {
                        var adj = prAdjustment[pi];
                        var adjAmt = Number(adj.Amount) || 0;
                        totalOther += adjAmt;
                        var desc = stripHtml(adj.Description || "");
                        otherContainer.append("<div class=\"ps-info-item\"><span class=\"ps-info-label\">" + desc + ":</span><span class=\"ps-info-value\">" + formatCurrency(adjAmt) + "</span></div>");
                    }
                }
                $("#psTotalOther").text(formatCurrency(totalOther));

                var dedContainer = $("#psDeductions");
                dedContainer.empty();
                var totalDed = 0;
                if (deductionsData && deductionsData.length) {
                    for (var di = 0; di < deductionsData.length; di++) {
                        var dd = deductionsData[di];
                        var ddAmt = Number(dd.AmountDeduct) || 0;
                        totalDed += ddAmt;
                        var ddName = stripHtml(dd.Description || "");
                        dedContainer.append("<div class=\"ps-info-item\"><span class=\"ps-info-label\">" + ddName + ":</span><span class=\"ps-info-value\">" + formatCurrency(ddAmt) + "</span></div>");
                    }
                }
                $("#psTotalDeductions").text(formatCurrency(totalDed));

                var selfTax = 0, depTax = 0, taxIncome = 0, pit = 0;
                if (taxData && taxData.length) {
                    for (var ti = 0; ti < taxData.length; ti++) {
                        var tx = taxData[ti];
                        var txAmt = Number(tx.AmountDeduct) || 0;
                        if (tx.STT === 0) selfTax = txAmt;
                        else if (tx.STT === 1) depTax = txAmt;
                        else if (tx.STT === 2) taxIncome = txAmt;
                        else if (tx.STT === 3) pit = txAmt;
                    }
                }
                $("#psSelfTax").text(formatCurrency(selfTax));
                $("#psDepTax").text(formatCurrency(depTax));
                $("#psTaxIncome").text(formatCurrency(taxIncome));
                $("#psPIT").text(formatCurrency(pit));
                $("#psNetSalary").text(emp.GrossTakeHome != null ? formatCurrency(emp.GrossTakeHome) : "");

                switchTabPs("psPayslip");
            },
            error: function() { alert(ERROR_LOAD); }
        });
    };

    $(document).ready(function() {
        if (typeof AjaxHPAParadise === "function") {
            AjaxHPAParadise({
                data: {
                    name: "sp_PaySlipView",
                    param: ["LoginID", UserID]
                },
                success: function(result) {
                    var response;
                    try { response = JSON.parse(result); } catch (e) { return; }
                    if (!response || !response.data) return;
                    var data = response.data;

                    var companyData  = (data[0] && data[0].length) ? data[0][0] : {};
                    var empArr       = data[1] || [];
                    var allowanceData = data[4] || [];
                    var prAdjustment = data[5] || [];
                    var deductionsData = data[6] || [];
                    var taxData      = data[7] || [];
                    var overtimeData = data[8] || [];
                    var daysOffData  = data[9] || [];
                    var lateEarlyData = data[10] || [];

                    var emp = (empArr && empArr.length) ? empArr[0] : {};
                    window._empData = emp;
                    window._empData.OvertimeDetails = overtimeData;
                    window._empData.DaysOffDetails  = daysOffData;
                    window._empData.LateEarlyDetails = lateEarlyData;

                    $("#psCompanyName").text(stripHtml(companyData.CompanyFullName || ""));
                    $("#psCompanyAddr").text(stripHtml(companyData.Address || ""));
                    $("#psEmpID").text(stripHtml(emp.EmployeeID || ""));
                    $("#psFullName").text(stripHtml(emp.FullName || ""));
                    $("#psHireDate").text(formatDate(emp.HireDate));
                    $("#psPosition").text(stripHtml(emp.PositionName || ""));
                    $("#psDependents").text(stripHtml(emp.DependantNumber || ""));
                    $("#psMonthYear").text(emp.Month && emp.Year ? "' + @titleMonthYear + N': " + stripHtml(String(emp.Month)) + "/" + stripHtml(String(emp.Year)) : "");

                    $("#psStdDays").text((Number(emp.StandardWDays) || 0) + " ' + @days + N'");
                    $("#psActDays").text((Number(emp.DaysOfSalEntry) || 0) + " ' + @days + N'");
                    $("#psOTHours").text((Number(emp.OTHour) || 0) + " ' + @hours + N'");
                    $("#psDaysOff").text((Number(emp.TotalLeave) || 0) + " ' + @days + N'");
                    $("#psLateEarly").text((Number(emp.IOMinutesDeduct) || 0) + " ' + @days + N'");
                    $("#psBasicSalary").text(formatCurrency(emp.ActualMonthlyBasic));
                    $("#psOTSalary").text(formatCurrency(emp.OTAmount));

                    var totalIncome = Number(emp.TotalIncome) || 0;
                    $("#psTotalIncome").text(formatCurrency(totalIncome));

                    var otherContainer = $("#psOtherIncomes");
                    otherContainer.empty();
                    var totalOther = 0;
                    if (allowanceData && allowanceData.length) {
                        for (var ai = 0; ai < allowanceData.length; ai++) {
                            var al = allowanceData[ai];
                            var amt = Number(al.Amount) || 0;
                            totalOther += amt;
                            var name = stripHtml(al.AllowanceName || "");
                            otherContainer.append("<div class=\"ps-info-item\"><span class=\"ps-info-label\">" + name + ":</span><span class=\"ps-info-value\">" + formatCurrency(amt) + "</span></div>");
                        }
                    }
                    if (prAdjustment && prAdjustment.length) {
                        for (var pi = 0; pi < prAdjustment.length; pi++) {
                            var adj = prAdjustment[pi];
                            var adjAmt = Number(adj.Amount) || 0;
                            totalOther += adjAmt;
                            var desc = stripHtml(adj.Description || "");
                            otherContainer.append("<div class=\"ps-info-item\"><span class=\"ps-info-label\">" + desc + ":</span><span class=\"ps-info-value\">" + formatCurrency(adjAmt) + "</span></div>");
                        }
                    }
                    $("#psTotalOther").text(formatCurrency(totalOther));

                    var dedContainer = $("#psDeductions");
                    dedContainer.empty();
                    var totalDed = 0;
                    if (deductionsData && deductionsData.length) {
                        for (var di = 0; di < deductionsData.length; di++) {
                            var dd = deductionsData[di];
                            var ddAmt = Number(dd.AmountDeduct) || 0;
                            totalDed += ddAmt;
                            var ddName = stripHtml(dd.Description || "");
                            dedContainer.append("<div class=\"ps-info-item\"><span class=\"ps-info-label\">" + ddName + ":</span><span class=\"ps-info-value\">" + formatCurrency(ddAmt) + "</span></div>");
                        }
                    }
                    $("#psTotalDeductions").text(formatCurrency(totalDed));

                    var selfTax = 0, depTax = 0, taxIncome = 0, pit = 0;
                    if (taxData && taxData.length) {
                        for (var ti = 0; ti < taxData.length; ti++) {
                            var tx = taxData[ti];
                            var txAmt = Number(tx.AmountDeduct) || 0;
                            if (tx.STT === 0) selfTax = txAmt;
                            else if (tx.STT === 1) depTax = txAmt;
                            else if (tx.STT === 2) taxIncome = txAmt;
                            else if (tx.STT === 3) pit = txAmt;
                        }
                    }
                    $("#psSelfTax").text(formatCurrency(selfTax));
                    $("#psDepTax").text(formatCurrency(depTax));
                    $("#psTaxIncome").text(formatCurrency(taxIncome));
                    $("#psPIT").text(formatCurrency(pit));
                    $("#psNetSalary").text(emp.GrossTakeHome != null ? formatCurrency(emp.GrossTakeHome) : "");
                },
                error: function() {}
            });
        }
    });
})();
</script>';

    -- Layer 5: MERGE cache
    MERGE dbo.tblHtmlScriptCache AS tgt
    USING (SELECT
              'sp_salaryslip_html'        AS TableName,
              @LanguageID                 AS LanguageID,
              '-1'                        AS ScreenType,
              @html                       AS html,
              N''                         AS HtmlParadise,
              N''                         AS paradiseJs,
              '1.0'                       AS Version,
              N'ParadiseStyle v1.0 - complete redesign from sp_SalarySlip: Bootstrap Icons, var(--paradise-*), scoped ps- CSS, 2-layer pattern' AS VersionData
          ) AS src
       ON tgt.TableName = src.TableName AND tgt.LanguageID = src.LanguageID
    WHEN MATCHED THEN
        UPDATE SET tgt.ScreenType   = src.ScreenType,
                   tgt.html         = src.html,
                   tgt.HtmlParadise = src.HtmlParadise,
                   tgt.paradiseJs   = src.paradiseJs,
                   tgt.Version      = src.Version,
                   tgt.VersionData  = src.VersionData
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData)
        VALUES (src.TableName, src.LanguageID, src.ScreenType, src.html, src.HtmlParadise, src.paradiseJs, src.Version, src.VersionData);

    SELECT @html AS html;
END
GO

PRINT '2. Da tao renderer sp_salaryslip_html (ParadiseStyle v1.0).';
GO

-- =====================================================================================
-- Phase 3: tblDataSetting (1 row) + tblDataSettingLayout (2 rows)
-- =====================================================================================

-- DataSetting: MERGE để idempotent
IF NOT EXISTS (SELECT 1 FROM dbo.tblDataSetting WHERE TableName = 'sp_salaryslip')
BEGIN
    INSERT INTO dbo.tblDataSetting (
        TableName, ViewName, IsProcedure, IsShowLayout,
        ColumnOrderBy, ColumnDataType, ColumnHide, ControlHiddenInShowLayout,
        LayoutDataConfigFillter, LayoutParamConfig,
        LayoutDataConfigColumnView, LayoutDataConfigCardView,
        LayoutMobileLocalConfig
    )
    VALUES (
        'sp_salaryslip', 'sp_salaryslip', 1, 1,
        'html&0', 'html&ViewHtml',
        'isReadOnlyRow,dtftxxENGColumns',
        'grdTableEditor,txtFilter,btnReload,btnFWDelete,btnFWReset,btnExport,btnFWSave,btnFWAdd,isReadOnlyRow,dtftxxENGColumns',
        CAST(NULL AS VARBINARY(MAX)), CAST(NULL AS VARBINARY(MAX)),
        CAST(NULL AS VARBINARY(MAX)), CAST(NULL AS VARBINARY(MAX)),
        CAST(NULL AS VARBINARY(MAX))
    );
    PRINT '3a. Da INSERT tblDataSetting cho sp_salaryslip.';
END
ELSE
BEGIN
    UPDATE dbo.tblDataSetting
       SET IsProcedure = 1, IsShowLayout = 1,
           ColumnOrderBy = 'html&0', ColumnDataType = 'html&ViewHtml'
     WHERE TableName = 'sp_salaryslip';
    PRINT '3a. Da UPDATE tblDataSetting cho sp_salaryslip.';
END
GO

-- DataSettingLayout: DELETE + INSERT để idempotent
DELETE FROM dbo.tblDataSettingLayout WHERE TableName = 'sp_salaryslip';

INSERT INTO dbo.tblDataSettingLayout (
    TableName, Name, ControlName, NamePa, Type, TypeLayout, ControlType,
    Lx, Ly, Sx, Sy, WidthPercentage, BackgroundImage
)
VALUES
    ('sp_salaryslip', 'root',    '',     '',     'g', '6', '',             0,0,1,1,100, CAST(NULL AS VARBINARY(MAX))),
    ('sp_salaryslip', 'lblhtml', 'html', 'root', 'i', '6', 'ParadiseWebView2', 0,0,1,1,100, CAST(NULL AS VARBINARY(MAX)));

PRINT '3b. Da INSERT tblDataSettingLayout (root + lblhtml/ParadiseWebView2).';
GO

-- =====================================================================================
-- Phase 4: Rebuild cache + Refresh menu
-- =====================================================================================

delete dbo.tblHtmlScriptCache WHERE TableName in ('sp_salaryslip_html','sp_salaryslip');
GO

EXEC dbo.sp_GenerateHTMLScript 'sp_salaryslip_html';
GO

PRINT '4. Da rebuild cache HTML cho sp_salaryslip_html (VN + EN).';
GO

EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_salaryslip';
GO

PRINT '5. Da refresh menu cache client.';
GO

-- =====================================================================================
-- Verify
-- =====================================================================================

SELECT TableName, LanguageID, ScreenType, DATALENGTH(html) AS HtmlBytes, Version
FROM dbo.tblHtmlScriptCache
WHERE TableName = 'sp_salaryslip_html'
ORDER BY LanguageID;
GO

PRINT '=== HOAN TAT ===';
PRINT 'Redesign MnuPRL445 - Phieu luong theo chuan ParadiseStyle v1.0';
PRINT '  1. 2-layer: wrapper sp_salaryslip + renderer sp_salaryslip_html';
PRINT '  2. Bootstrap Icons (bi bi-*) thay Font Awesome CDN';
PRINT '  3. Toan bo CSS dung var(--paradise-*) token';
PRINT '  4. CSS scoped ps- prefix, khong set background';
PRINT '  5. .paradise-btn cho button chuan';
PRINT '  6. tblDataSetting + tblDataSettingLayout day du';
PRINT '  7. Cache MERGE + sp_GenerateHTMLScript + refresh menu';
GO
