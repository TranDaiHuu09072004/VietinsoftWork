/* =============================================================================
   fix_sp_ViewEmployeePaySlip_IrregularIncomeTV_20260525.sql
   ---------------------------------------------------------------------------
   Mục đích : Fix bug — nhân viên đang thử việc có "Thu nhập không cố định"
              (ADJ_Child / ADJ_Woman / ADJ_Meal / ADJ_Meal_Night /
               ADJ_13thMonthSalary / ADJ_Add / ADJ_PerformanceBonus
               và mọi item `tblIrregularIncome` IncomeKind = 1)
              bị hiển thị bên cột CT (Chính thức) trên payslip thay vì cột TV.
   Yêu cầu KH: Nhân viên đang thử việc → toàn bộ tiền phải hiển thị bên cột TV,
              KHÔNG được hiển thị bên cột CT.
   Database : Paradise_STVN_TEST (SVRVTS01\SQL2022).
   Đối tượng: sp_ViewEmployeePaySlip (chỉ sửa duy nhất section "Nhóm thu nhập
              không cố định" = result set 'AdjustInfo'; các section khác đã đúng).
   Idempotent: CREATE OR ALTER (chạy nhiều lần an toàn).
   Khuyến cáo: BACKUP DB trước khi chạy. Test lại payslip tháng 4/2026 cho các
              employee D00180, D00194, D00207, D00212, D00213 sau khi fix.
   =============================================================================

   PHÂN TÍCH ROOT CAUSE (cho reviewer)
   -----------------------------------------------------------------------------
   Section "Nhóm thu nhập không cố định" trong sp_ViewEmployeePaySlip dùng
   dynamic SQL build INSERT chỉ với 3 cột (EmployeeID, ColumnInfo, CT):

     INSERT INTO #DetailSalary (EmployeeID, ColumnInfo, CT)
     SELECT EmployeeID, ..., <IncomeCode> FROM #SAL_Export

   → Toàn bộ giá trị `IncomeCode` (vd ADJ_Meal, ADJ_Woman) bị dồn vào cột CT
     bất kể nhân viên đang thử việc hay đã chính thức.

   Lý do gốc: `tblIrregularIncome` chỉ định nghĩa 1 IncomeCode duy nhất cho
   mỗi item (không có column `_Pro` riêng). Tác giả SP đơn giản dump hết vào CT
   thay vì check trạng thái thử việc qua `BeginDate`.

   Quy ước `BeginDate` trong SAL_Export (đã xác minh từ sp_PayrollSheetDetails):
     BeginDate = CASE WHEN ProbationEndDate IS NULL OR HireDate = ProbationEndDate
                      THEN HireDate
                      ELSE DATEADD(D, 1, ProbationEndDate)
                 END
   → BeginDate là ngày BẮT ĐẦU CT (Chính thức). Nếu BeginDate > @ToDate (cuối
     kỳ lương) nghĩa là nhân viên CÒN trong giai đoạn thử việc throughout kỳ.

   FIX
   -----------------------------------------------------------------------------
   Thay 3-col INSERT (..., CT) bằng 4-col INSERT (..., TV, CT) với CASE WHEN
   trên `BeginDate > @ToDate`:
     - BeginDate > @ToDate → còn thử việc → giá trị vào TV, CT = NULL
     - Ngược lại → đã chính thức → CT, TV = NULL

   Logic này nhất quán với các section khác trong cùng SP (`Salary_Pro` vs
   `Salary`, `AllowanceCode_Pro_Cal` vs `AllowanceCode_Cal`, v.v.).

   ============================================================================= */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'================================================================';
PRINT N' FIX sp_ViewEmployeePaySlip — route IrregularIncome theo BeginDate';
PRINT N'================================================================';
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_ViewEmployeePaySlip]
(
    @LoginID    int,
    @Month      int,
    @Year       int,
    @PeriodID   int          = 0,
    @LanguageID varchar(2)   = 'VN',
    @EmployeeID varchar(20)  = '-1'
)
AS
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    DECLARE @FromDate date, @ToDate date;
    SELECT @FromDate = FromDate, @ToDate = ToDate
    FROM   dbo.fn_Get_SalaryPeriod_Term(@Month, @Year, @PeriodID);

    SELECT EmployeeID, FullName, HireDate, DepartmentID, PositionID, SectionID, GroupID
    INTO   #EmployeeList_Bydate
    FROM   dbo.fn_vtblEmployeeList_Simple_ByDate(@ToDate, @EmployeeID, @LoginID)
    WHERE  (DateR IS NULL OR DateR > @FromDate);

    SELECT * INTO #fn_ColumnExcel FROM dbo.fn_ColumnExcel('A', 'Z');

    -- Thủ tục lấy thông tin lương chính thức để đảm bảo đủ cột trong bảng lương
    EXEC dbo.sp_PayrollSheetDetails
         @LoginID         = @LoginID,
         @Month           = @Month,
         @Year            = @Year,
         @IsGetSalaryInfo = 1;

    -- Bảng lương chính thức
    SELECT s.*
    INTO   #SAL_Export
    FROM   SAL_Export AS s
    INNER JOIN tblEmployee AS te ON te.EmployeeID = s.EmployeeID
                                 AND (te.DateR IS NULL OR te.DateR > @FromDate)
    WHERE  EXISTS (SELECT 1 FROM tmpEmployeeTree AS e
                   WHERE e.EmployeeID = s.EmployeeID AND e.LoginID = @LoginID)
      AND  s.Month = @Month AND s.Year = @Year
      AND  ISNULL(s.GrossTakeHome, 0) <> 0;

    /* ===== Result set 1: Thông tin tiêu đề + nhân viên + công chuẩn ===== */
    SELECT @Month  AS Month, @Year AS Year,
           CONVERT(varchar, @FromDate, 103) FromDate,
           CONVERT(varchar, @ToDate,   103) ToDate,
           c.Logo,
           N'Phiếu lương nhân viên Kỳ lương: ' + CAST(@Month AS varchar(2)) + '-' + CAST(@Year AS varchar(4))
             + ' ( ' + CONVERT(varchar, @FromDate, 103) + ' - ' + CONVERT(varchar, @ToDate, 103) + ' )' AS MY,
           s.EmployeeID, s.FullName, s.DepartmentName, s.PositionName,
           CONVERT(varchar, HireDate, 103) HireDate
    FROM   #SAL_Export AS s
    LEFT JOIN tblCompany AS c ON 1 = 1;
    SELECT 'EmployeeInfo' AS TableName, 'EmployeeList.EmployeeID' AS Parameter;

    /* ===== Result set 2: Nhóm thông tin lương ===== */
    CREATE TABLE #DetailSalary (
        ID         int identity,
        EmployeeID varchar(20),
        ColumnInfo nvarchar(500),
        TV         float,
        CT         float,
        TypeValue  nvarchar(20)
    );

    INSERT INTO #DetailSalary (EmployeeID, ColumnInfo, TV, CT)
    SELECT EmployeeID, N'a. Mức lương căn bản', Salary_Pro,      Salary      FROM #SAL_Export UNION ALL
    SELECT EmployeeID, N'b. Phụ cấp chức vụ',   Position_AL_Pro, Position_AL FROM #SAL_Export;

    INSERT INTO #DetailSalary (EmployeeID, ColumnInfo, TV, CT)
    SELECT EmployeeID, N'd. Lương tổng (a + b)', SUM(TV), SUM(CT)
    FROM   #DetailSalary GROUP BY EmployeeID;

    INSERT INTO #DetailSalary (EmployeeID, ColumnInfo, TV, CT)
    SELECT EmployeeID, N'c. Lương giờ công',
           SUM(TV) / w.WorkingDays_Std / 8.0,
           SUM(CT) / w.WorkingDays_Std / 8.0
    FROM   #DetailSalary
    INNER JOIN tblWorkingDaySetting AS w ON Month = @Month AND Year = @Year AND EmployeeTypeID = 1
    WHERE  ColumnInfo NOT LIKE '%(a + b)%'
    GROUP  BY EmployeeID, w.WorkingDays_Std;

    SELECT EmployeeID, ColumnInfo,
           dbo.fn_ConvertMoneyToString(TV) TV,
           dbo.fn_ConvertMoneyToString(CT) CT,
           'vnd' TypeValue
    FROM   #DetailSalary
    ORDER  BY EmployeeID, ColumnInfo;
    SELECT 'ActualSalary' AS TableName, 'EmployeeList.EmployeeID' AS Parameter;

    /* ===== Result set 3: HeaderTotalOT ===== */
    SELECT EmployeeID,
           ISNULL(Salary_Pro, 0) + ISNULL(Position_AL_Pro, 0) AS Salary_Pro,
           ISNULL(Salary,     0) + ISNULL(Position_AL,     0) AS Salary
    FROM   #SAL_Export
    ORDER  BY EmployeeID;
    SELECT 'HeaderTotalOT' AS TableName, 'EmployeeList.EmployeeID' AS Parameter;

    /* ===== Nhóm thông tin tiền công và tiền phép ===== */
    TRUNCATE TABLE #DetailSalary;

    INSERT INTO #DetailSalary (EmployeeID, ColumnInfo, TV, CT, TypeValue)
    SELECT e.EmployeeID, N'. Giờ công chuẩn của tháng', w.WorkingDays_Std * 8, NULL, N'giờ'
    FROM   #EmployeeList_Bydate AS e
    LEFT JOIN tblWorkingDaySetting AS w ON Month = @Month AND Year = @Year AND EmployeeTypeID = 1
    UNION ALL SELECT EmployeeID, N'a. Giờ công thực tế hưởng lương', AttDay_Pro,    AttDay,    N'giờ' FROM #SAL_Export
    UNION ALL SELECT EmployeeID, N'b. Lương giờ công thực tế ',      Salary_Pro_Cal,Salary_Cal,N'vnd' FROM #SAL_Export;

    DECLARE @QueryA nvarchar(max) = '';

    -- Bổ sung các cột thử việc cho từng loại nghỉ (nếu chưa có)
    SELECT @QueryA += ',' + LeaveCode + '_Pro float'
    FROM   tblLeaveType
    WHERE  IsVisible = 1
       AND LeaveCode + '_Pro' NOT IN (SELECT name FROM tempdb.sys.columns
                                       WHERE object_id = OBJECT_ID('tempdb..#SAL_Export'));
    IF LEN(@QueryA) > 0
    BEGIN
        SET @QueryA = 'ALTER TABLE #SAL_Export ADD ' + SUBSTRING(@QueryA, 2, LEN(@QueryA));
        EXEC (@QueryA);
    END

    SET @QueryA = '';
    SELECT @QueryA += ',' + LeaveCode + '_Pro_Amount float'
    FROM   tblLeaveType
    WHERE  IsVisible = 1
       AND LeaveCode + '_Pro_Amount' NOT IN (SELECT name FROM tempdb.sys.columns
                                              WHERE object_id = OBJECT_ID('tempdb..#SAL_Export'));
    IF LEN(@QueryA) > 0
    BEGIN
        SET @QueryA = 'ALTER TABLE #SAL_Export ADD ' + SUBSTRING(@QueryA, 2, LEN(@QueryA));
        EXEC (@QueryA);
    END

    SET @QueryA = '';
    SELECT @QueryA += ',' + LeaveCode + '_Amount float'
    FROM   tblLeaveType
    WHERE  IsVisible = 1
       AND LeaveCode + '_Amount' NOT IN (SELECT name FROM tempdb.sys.columns
                                          WHERE object_id = OBJECT_ID('tempdb..#SAL_Export'));
    IF LEN(@QueryA) > 0
    BEGIN
        SET @QueryA = 'ALTER TABLE #SAL_Export ADD ' + SUBSTRING(@QueryA, 2, LEN(@QueryA));
        EXEC (@QueryA);
    END

    -- Insert số giờ công của từng loại nghỉ (TV / CT)
    SET @QueryA = '';
    SELECT @QueryA += N'
    INSERT INTO #DetailSalary (EmployeeID, ColumnInfo, TV, CT)
    SELECT EmployeeID, N''' + Description + ''', ' + LeaveCode + '_Pro, ' + LeaveCode + ' FROM #SAL_Export '
    FROM   tblLeaveType
    WHERE  IsVisible = 1 AND LeaveCode <> 'ML';
    EXEC (@QueryA);
    UPDATE #DetailSalary SET TypeValue = N'giờ' WHERE TypeValue IS NULL;

    -- Insert số tiền của từng loại nghỉ có lương (TV / CT)
    SET @QueryA = '';
    SELECT @QueryA += N'
    INSERT INTO #DetailSalary (EmployeeID, ColumnInfo, TV, CT)
    SELECT EmployeeID, N''' + Description + ''', ' + LeaveCode + '_Pro_Amount, ' + LeaveCode + '_Amount FROM #SAL_Export '
    FROM   tblLeaveType
    WHERE  IsVisible = 1 AND PaidRate > 0 AND LeaveCode <> 'ML';
    EXEC (@QueryA);
    UPDATE #DetailSalary SET TypeValue = N'vnd' WHERE TypeValue IS NULL;

    INSERT INTO #DetailSalary (EmployeeID, ColumnInfo, TV, CT, TypeValue)
    SELECT EmployeeID, N'c. Lương phụ cấp chức vụ', Position_AL_Pro_Cal, Position_AL_Cal, 'vnd' FROM #SAL_Export;

    -- Đánh số thứ tự cho từng hạng mục nghỉ
    SELECT a.*, LOWER(f.ColumnExcel) + '. ' + Description ColumnExcel
    INTO   #Description_List
    FROM (
        SELECT ROW_NUMBER() OVER (ORDER BY TTT, ORD, Description) + 3 AS TT, *
        FROM (
            SELECT CASE WHEN PaidRate > 0 THEN 1 ELSE 2 END TTT, ORD, Description ColumnInfo,
                   N'Giờ '   + Description Description, N'giờ' TypeValue
            FROM   tblLeaveType WHERE IsVisible = 1 AND LeaveCode <> 'ML'
            UNION ALL
            SELECT CASE WHEN PaidRate > 0 THEN 1 ELSE 2 END TTT, ORD, Description ColumnInfo,
                   N'Lương ' + Description Description, N'vnd' TypeValue
            FROM   tblLeaveType WHERE IsVisible = 1 AND LeaveCode <> 'ML' AND PaidRate > 0
        ) AS a
    ) AS a
    INNER JOIN #fn_ColumnExcel AS f ON f.ORD = a.TT;

    UPDATE #DetailSalary
       SET ColumnInfo = d.ColumnExcel
      FROM #DetailSalary AS s
      INNER JOIN #Description_List AS d ON d.ColumnInfo = s.ColumnInfo AND s.TypeValue = d.TypeValue;

    SELECT EmployeeID, ColumnInfo,
           dbo.fn_ConvertMoneyToString(TV) TV,
           dbo.fn_ConvertMoneyToString(CT) CT,
           TypeValue
    FROM   #DetailSalary
    ORDER  BY EmployeeID, ColumnInfo, TypeValue;
    SELECT 'PaidleaveInfo' AS TableName, 'EmployeeList.EmployeeID' AS Parameter;

    /* ===== Tổng cộng lương thực nhận ===== */
    SET @QueryA = '';
    SELECT @QueryA += '+ isnull(' + LeaveCode + '_Pro_Amount,0)' FROM tblLeaveType WHERE PaidRate > 0;
    DECLARE @QueryB nvarchar(max) = '';
    SELECT @QueryB += '+ isnull(' + LeaveCode + '_Amount,0)'     FROM tblLeaveType WHERE PaidRate > 0;
    SET @QueryA = 'SELECT EmployeeID, isnull(Salary_Pro_Cal,0) ' + @QueryA
                + ' + isnull(Position_AL_Pro_Cal,0) TotalSal_Pro, isnull(Salary_Cal,0) '
                + @QueryB + ' + isnull(Position_AL_Cal,0) TotalSal FROM #SAL_Export ORDER BY EmployeeID';
    EXEC (@QueryA);
    SELECT 'HeaderTotalActual' AS TableName, 'EmployeeList.EmployeeID' AS Parameter;

    /* ===== Nhóm phụ cấp ===== */
    TRUNCATE TABLE #DetailSalary;
    SELECT @QueryA = '', @QueryB = '';

    SELECT ROW_NUMBER() OVER (ORDER BY ORD) TT, * INTO #AllowanceSetting
    FROM   tblAllowanceSetting WHERE AllowanceCode <> 'Position_AL';

    SET @QueryA = '';
    SELECT @QueryA += N'
    INSERT INTO #DetailSalary (EmployeeID, ColumnInfo, TV, CT)
    SELECT EmployeeID, ''' + ISNULL(LOWER(f.ColumnExcel), '') + N'. '' + N''' + AllowanceName + ''',
           ' + AllowanceCode + '_Pro_Cal, ' + AllowanceCode + '_Cal
    FROM #SAL_Export '
    FROM   #AllowanceSetting AS a
    LEFT JOIN #fn_ColumnExcel AS f ON f.ORD = a.TT
    WHERE  Visible = 1 AND AllowanceCode <> 'Position_AL';
    EXEC (@QueryA);

    SELECT EmployeeID, ColumnInfo,
           dbo.fn_ConvertMoneyToString(TV) TV,
           dbo.fn_ConvertMoneyToString(CT) CT,
           'vnd' TypeValue
    FROM   #DetailSalary
    ORDER  BY EmployeeID, ColumnInfo, TypeValue;
    SELECT 'AllowancesInfo' AS TableName, 'EmployeeList.EmployeeID' AS Parameter;
    UPDATE #DetailSalary SET TypeValue = 'vnd';

    /* =============================================================================
       FIX BEGIN — Nhóm thu nhập không cố định (Irregular Income / AdjustInfo)
       -----------------------------------------------------------------------------
       Trước: INSERT (EmployeeID, ColumnInfo, CT) → toàn bộ giá trị vào CT.
       Sau  : INSERT (EmployeeID, ColumnInfo, TV, CT) với CASE WHEN BeginDate > @ToDate
              route giá trị qua TV khi nhân viên còn thử việc throughout kỳ lương.
       =============================================================================*/
    SELECT @QueryA = '', @QueryB = '';

    DECLARE @ToDateStr varchar(10) = CONVERT(varchar(10), @ToDate, 121);   -- 'YYYY-MM-DD'

    SET @QueryA = '';
    SELECT @QueryA += N'
    INSERT INTO #DetailSalary (EmployeeID, ColumnInfo, TV, CT)
    SELECT EmployeeID,
           ''' + ISNULL(LOWER(f.ColumnExcel), '') + N'. '' + N''' + Description + ''',
           CASE WHEN BeginDate > ''' + @ToDateStr + N''' THEN ' + IncomeCode + ' ELSE NULL END,
           CASE WHEN BeginDate > ''' + @ToDateStr + N''' THEN NULL ELSE ' + IncomeCode + ' END
    FROM #SAL_Export '
    FROM   tblIrregularIncome AS a
    LEFT JOIN #fn_ColumnExcel AS f ON f.ORD = a.Ord + (SELECT COUNT(1) FROM tblAllowanceSetting WHERE Visible = 1)
    WHERE  Visible = 1 AND IncomeKind = 1;
    EXEC (@QueryA);
    /* =============================================================================
       FIX END
       =============================================================================*/

    SELECT EmployeeID, ColumnInfo,
           dbo.fn_ConvertMoneyToString(TV) TV,
           dbo.fn_ConvertMoneyToString(CT) CT,
           'vnd' TypeValue
    FROM   #DetailSalary
    WHERE  TypeValue IS NULL
    ORDER  BY EmployeeID, ColumnInfo, TypeValue;
    SELECT 'AdjustInfo' AS TableName, 'EmployeeList.EmployeeID' AS Parameter;

    SELECT EmployeeID, N'Tổng tiền phụ cấp', SUM(TV) TV, SUM(CT) CT, 'vnd' TypeValue
    FROM   #DetailSalary GROUP BY EmployeeID;
    SELECT 'HeaderTotalAllowancesInfo' AS TableName, 'EmployeeList.EmployeeID' AS Parameter;

    /* ===== Nhóm tăng ca (OT) — pattern TotalTV / TotalCT theo cột _Pro vs non-Pro ===== */
    ALTER TABLE #SAL_Export ADD ADJ_Pro float, EmployeeTotal_Pro float, TaxAmt_Pro float, EmpUnion_Pro float;

    SET @QueryA = '';
    SELECT @QueryA += '+isnull(' + name + ',0)'
    FROM   tempdb.sys.columns
    WHERE  object_id = OBJECT_ID('tempdb..#SAL_Export')
       AND name LIKE '%OTkind%' AND name LIKE '%Amount%' AND name LIKE '%Pro%';
    SET @QueryB = '';
    SELECT @QueryB += '+isnull(' + name + ',0)'
    FROM   tempdb.sys.columns
    WHERE  object_id = OBJECT_ID('tempdb..#SAL_Export')
       AND name LIKE '%OTkind%' AND name LIKE '%Amount%' AND name NOT LIKE '%Pro%';

    SET @QueryA = '
    SELECT *, ' + SUBSTRING(@QueryA, 2, LEN(@QueryA)) + ' TotalTV, '
              + SUBSTRING(@QueryB, 2, LEN(@QueryB)) + ' TotalCT FROM #SAL_Export ORDER BY EmployeeID';
    EXEC (@QueryA);
    SELECT 'OvertimesInfo' AS TableName, 'EmployeeList.EmployeeID' AS Parameter;
GO

PRINT N'[OK] sp_ViewEmployeePaySlip đã được ALTER với fix IrregularIncome → TV.';
GO

/* =============================================================================
   VERIFY — chạy thử cho April 2026 với 1 nhân viên đang thử việc
   ============================================================================= */
PRINT N'';
PRINT N'================================================================';
PRINT N' VERIFY — chạy sp_ViewEmployeePaySlip cho D00180 (April 2026)';
PRINT N'================================================================';
PRINT N'';
PRINT N'-- Chạy thủ công sau khi script complete:';
PRINT N'-- EXEC dbo.sp_ViewEmployeePaySlip @LoginID = 3, @Month = 4, @Year = 2026, @EmployeeID = ''D00180'';';
PRINT N'-- ';
PRINT N'-- Kết quả mong đợi ở result set ''AdjustInfo'' cho EmployeeID = D00180:';
PRINT N'--   ColumnInfo: "g. Phụ cấp cơm ngày"      TV: "550.000"  CT: NULL/empty';
PRINT N'--   ColumnInfo: "h. Trợ cấp phụ nữ"        TV: "48.462"   CT: NULL/empty';
PRINT N'-- (Lý do: D00180 có BeginDate = 2026-05-02 > @ToDate = 2026-04-30 → còn thử việc)';
PRINT N'';

-- Quick check: meta info của các employee có khả năng test
SELECT TOP 10 EmployeeID, HireDate, ProbationEndDate,
       CASE WHEN ProbationEndDate IS NULL OR HireDate = ProbationEndDate
            THEN HireDate ELSE DATEADD(D, 1, ProbationEndDate) END AS BeginDate,
       CAST(CASE WHEN
            (CASE WHEN ProbationEndDate IS NULL OR HireDate = ProbationEndDate
                  THEN HireDate ELSE DATEADD(D, 1, ProbationEndDate) END)
            > '2026-04-30' THEN 1 ELSE 0 END AS bit) AS ShouldShowInTV
FROM SAL_Export
WHERE Month = 4 AND Year = 2026
  AND ProbationEndDate >= '2026-05-01'
ORDER BY EmployeeID;
GO

PRINT N'';
PRINT N'>>> HOÀN TẤT. Vui lòng test giao diện payslip + xác nhận với khách hàng.';
GO
