-- =================================================================================
-- MIGRATION SCRIPT: REDESIGN XP POINT CALCULATION BASED ON EMPLOYEE LEVEL
-- Target Database: Vietinsoft_Pay (Production)
-- Date: 2026-05-22
-- =================================================================================

-- STEP 1: Add OrgXP_Point column to tblRank_PersonalRating_Detail if it does not exist
IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_NAME = 'tblRank_PersonalRating_Detail' AND COLUMN_NAME = 'OrgXP_Point'
)
BEGIN
    PRINT 'Adding OrgXP_Point column to tblRank_PersonalRating_Detail...';
    ALTER TABLE tblRank_PersonalRating_Detail ADD OrgXP_Point INT NULL;
END
ELSE
BEGIN
    PRINT 'OrgXP_Point column already exists in tblRank_PersonalRating_Detail.';
END
GO

-- STEP 2: Compile/Deploy sp_PerformanceKPI_Working_Process
PRINT 'Deploying stored procedure sp_PerformanceKPI_Working_Process...';
GO
CREATE OR ALTER PROCEDURE [dbo].[sp_PerformanceKPI_Working_Process]
	@FromDate datetime = null,
	@ToDate datetime = null,
	@EmployeeID varchar(20) = '-1',
	@LoginID int = 3,
	@isDebug bit = 0
AS
BEGIN
	SET NOCOUNT ON;
	set @isDebug = 1
	-------------------------------------------------------------------
	-- Xác định chu kỳ tính lương và kiểm tra điều kiện chạy định kỳ
	-------------------------------------------------------------------
	DECLARE @Now_DT DATETIME = GETDATE();
	DECLARE @SalaryFrom DATETIME, @SalaryTo DATETIME;
	
	SELECT @SalaryFrom = FromDate, @SalaryTo = ToDate 
	FROM dbo.fn_Get_SalaryPeriod_ByDate(@Now_DT);

	-- Tự động gán FromDate/ToDate nếu để trống
	IF @FromDate IS NULL SET @FromDate = @SalaryFrom;
	IF @ToDate IS NULL SET @ToDate = @SalaryTo;
	
	-- Kiểm tra điều kiện chạy (Thứ 2 hàng tuần hoặc Ngày cuối kỳ lương)
	-- Nếu isDebug = 1 thì bỏ qua kiểm tra này
	IF @isDebug = 0
	BEGIN
		DECLARE @IsMonday BIT = CASE WHEN (DATEPART(dw, @Now_DT) + @@DATEFIRST - 2) % 7 = 0 THEN 1 ELSE 0 END;
		DECLARE @IsLastDayOfPeriod BIT = CASE WHEN CAST(@Now_DT AS DATE) = CAST(@SalaryTo AS DATE) THEN 1 ELSE 0 END;

		IF @IsMonday = 0 AND @IsLastDayOfPeriod = 0
		BEGIN
			PRINT 'Khong phai thoi diem tinh toan (Thu 2 hoac Ngay cuoi ky luong).';
			RETURN;
		END
	END

	IF @FromDate IS NULL OR @ToDate IS NULL RETURN;
	-------------------------------------------------------------------
	-- 0. Xử lý tránh gọi lệnh nhiều lần liên tục (Dùng Application Lock) va check thoi gian truoc do qua 10s
	-------------------------------------------------------------------
	DECLARE @LockResult INT, @Lock_Resource nvarchar(30) = 'Lock_PerformanceKPI_Process' -- luu y neu dat ten resource qua dai se bi loi khong release lock duoc, do ten tu dong bi cat mot phan
	DECLARE @Now DATETIME = GETDATE(), @waitInterval int = 15000;
	if @isDebug = 1 set @waitInterval = 1
	-- Dùng Application Lock
	if @isDebug = 0 EXEC @LockResult = sp_getapplock  @Resource = @Lock_Resource,  @LockMode = 'Exclusive', @LockOwner = 'Session', @LockTimeout = @waitInterval;
	--print 'Vaule of @LockResult:' + cast(@LockResult as varchar(10))
	
	IF @LockResult < 0 RETURN;
	UPDATE tblProcessTracker
	SET LastExecuted = @Now
	WHERE ProcessName = @Lock_Resource
	  AND (
	      DATEDIFF(day, LastExecuted, @Now) >= 1
	      OR DATEDIFF(MILLISECOND, LastExecuted, @Now) >= @waitInterval
	  );
	IF @@ROWCOUNT = 0
	BEGIN
		if @isDebug = 0 EXEC sp_releaseapplock @Resource = @Lock_Resource, @LockOwner = 'Session';
		print 'Waiting for some seconds'
		RETURN;
	END
	
	set @FromDate = CAST(CAST(@FromDate AS DATE) AS DATETIME);
	set @ToDate = DATEADD(DAY, 1, CAST(CAST(@ToDate AS DATE) AS DATETIME));
	IF OBJECT_ID('tempdb..#tmpEmpList') IS NOT NULL DROP TABLE #tmpEmpList;
	SELECT a.EmployeeID, a.FullName, a.HireDate, a.TerminateDate, et.SaturdayOff, et.SundayOff
	INTO #tmpEmpList
	FROM dbo.fn_vtblEmployeeList_Bydate(@ToDate, @EmployeeID, NULL) a
	INNER JOIN tblEmployeeType et ON a.EmployeeTypeID = et.EmployeeTypeID
	WHERE (a.EmployeeStatusID <> 20 OR a.StatusChangedDate >= @FromDate)
	  AND ISNULL(a.TAOptionID, 0) = 0
	  AND NOT EXISTS (
		  SELECT 1 FROM tblPosition b WITH(NOLOCK)
		  WHERE a.PositionID = b.PositionID AND b.NoTA = 1
	  );

	
CREATE CLUSTERED INDEX CIX_tmpEmpList ON #tmpEmpList(EmployeeID);
	IF OBJECT_ID('tempdb..#tmpSchedule_Base') IS NOT NULL DROP TABLE #tmpSchedule_Base;
	IF OBJECT_ID('tempdb..#tmpSchedule') IS NOT NULL DROP TABLE #tmpSchedule;
	--WAITFOR DELAY '00:00:20';
	-- 2.0 Kiểm tra điều kiện và lấy ShiftID mặc định
	DECLARE @DefaultShiftID INT = NULL;
	-- Kiểm tra xem hệ thống có duy nhất 1 loại ca (ShiftCode) hay không
	IF (SELECT COUNT(DISTINCT ShiftCode) FROM tblShiftSetting WITH(NOLOCK)) = 1
	BEGIN
		-- Lấy ShiftID của ngày thứ 2 (WeekDays = 2) làm cơ sở mặc định
		SELECT TOP 1 @DefaultShiftID = ShiftID
		FROM tblShiftSetting WITH(NOLOCK)
		WHERE WeekDays = 2;
	END
	-- 2.1 Lấy dữ liệu thô và đồng bộ ngày (Date Math + Xử lý thiếu lịch)
	;WITH CTE_Dates AS (
		-- Tạo danh sách chuỗi ngày từ @FromDate đến @ToDate
		SELECT CAST(@FromDate AS DATE) AS ScheduleDate
		UNION ALL
		SELECT DATEADD(day, 1, ScheduleDate)
		FROM CTE_Dates
		WHERE ScheduleDate < CAST(@ToDate AS DATE)
	),
	CTE_Emp_Dates AS (
		SELECT e.EmployeeID, d.ScheduleDate, e.SaturdayOff, e.SundayOff, e.TerminateDate
		FROM #tmpEmpList e
		CROSS JOIN CTE_Dates d
		where (e.TerminateDate is null or d.ScheduleDate < e.TerminateDate)
		and d.ScheduleDate >= e.HireDate
	)
	SELECT
		ed.EmployeeID,
		ed.ScheduleDate,
		ss.ShiftID,
	
		CASE
			WHEN a.HolidayStatus IS NOT NULL THEN a.HolidayStatus -- Ưu tiên lấy HolidayStatus của lịch gốc nếu có
			WHEN (DATEDIFF(d, 0, ed.ScheduleDate) % 7 = 5) AND ed.SaturdayOff = 1 THEN 1 -- Nếu là Thứ 7 và đc nghỉ Thứ 7
			WHEN (DATEDIFF(d, 0, ed.ScheduleDate) % 7 = 6) AND ed.SundayOff = 1 THEN 1 -- Nếu là Chủ nhật và đc nghỉ Chủ nhật
			ELSE 0 -- Các ngày làm việc bình thường
		END AS HolidayStatus,

		CAST(NULL AS DATETIME) AS AttStart, CAST(NULL AS DATETIME) AS AttEnd,
		CAST(NULL AS FLOAT) AS LvAmount, CAST(NULL AS FLOAT) AS LeaveStatus,
		DATEADD(day, DATEDIFF(day, ss.WorkStart, ed.ScheduleDate), ss.WorkStart) AS BaseWorkStart,
		DATEADD(day, DATEDIFF(day, ss.WorkEnd, ed.ScheduleDate), ss.WorkEnd) AS BaseWorkEnd,
		DATEADD(day, DATEDIFF(day, ss.BreakStart, ed.ScheduleDate), ss.BreakStart) AS BaseBreakStart,
		DATEADD(day, DATEDIFF(day, ss.BreakEnd, ed.ScheduleDate), ss.BreakEnd) AS BaseBreakEnd
	INTO #tmpSchedule_Base
	FROM CTE_Emp_Dates ed
	LEFT JOIN tblWSchedule a WITH(NOLOCK) ON ed.EmployeeID = a.EmployeeID AND ed.ScheduleDate = a.ScheduleDate
	INNER JOIN tblShiftSetting ss WITH(NOLOCK) ON ss.ShiftID = COALESCE(a.ShiftID, @DefaultShiftID)
	OPTION (MAXRECURSION 32767); -- Tránh lỗi đệ quy của CTE khi khoảng thời gian chọn > 100 ngày

	
	
	-- 2.2 Xử lý ca qua đêm (Gộp 4 lệnh UPDATE cũ thành 1 bước)
	SELECT
		EmployeeID, ScheduleDate, ShiftID, HolidayStatus, AttStart, AttEnd, LvAmount, LeaveStatus,0 as WorkingTimeMinute,0 as MissGPSAttStart,0 as MissGPSAttEnd,
		BaseWorkStart AS WorkStart,
		CASE WHEN BaseWorkStart > BaseWorkEnd THEN DATEADD(day, 1, BaseWorkEnd) ELSE BaseWorkEnd END AS WorkEnd,
		CASE WHEN BaseWorkStart > BaseBreakStart THEN DATEADD(day, 1, BaseBreakStart) ELSE BaseBreakStart END AS BreakStart,
		CASE WHEN BaseBreakStart > BaseBreakEnd THEN DATEADD(day, 1, BaseBreakEnd) ELSE BaseBreakEnd END AS BreakEnd
	INTO #tmpSchedule
	FROM #tmpSchedule_Base;

	CREATE CLUSTERED INDEX CIX_tmpSchedule ON #tmpSchedule(EmployeeID, ScheduleDate);
	-- Dọn rác & Đánh Index
	DROP TABLE #tmpSchedule_Base;
	IF OBJECT_ID('tempdb..#tmpGPSData') IS NOT NULL DROP TABLE #tmpGPSData;

	SELECT a.EmployeeID,
		   CAST(a.AttTime AS DATE) AS AttDate,
		   a.AttTime,
		   CASE WHEN a.UrlFileLocal <> '' or ra.IsSoftwareError = 1 THEN 0 ELSE 1 END AS MissedGPS,
		   a.AttState
	INTO #tmpGPSData
	FROM tblTmpAttend a WITH(NOLOCK)
	INNER JOIN #tmpEmpList te ON a.EmployeeID = te.EmployeeID
	left join tblAttendanceConfirmRequest ra on te.EmployeeID = ra.EmployeeID and a.IdentityID = ra.IdentityID
	WHERE a.AttTime >= DATEADD(DAY, -1, @FromDate)
	  AND a.AttTime < @ToDate
	  AND (a.UrlFileLocal <> '' OR a.IdentityID <> '');
	CREATE CLUSTERED INDEX CIX_tmpGPSData ON #tmpGPSData(EmployeeID, AttState, AttTime);
	;WITH CTE_Deduplicate AS (
		SELECT
			EmployeeID,
			AttDate,
			AttTime,
			AttState,
			ROW_NUMBER() OVER (
				PARTITION BY EmployeeID, AttDate, AttState
				ORDER BY
					CASE WHEN AttState = 1 THEN AttTime END ASC,
					CASE WHEN AttState = 2 THEN AttTime END DESC
			) as RowNum
		FROM #tmpGPSData
	)
	DELETE FROM CTE_Deduplicate WHERE RowNum > 1;
	-- 4. MAP GPS VÀO LỊCH TRÌNH
	-- Cập nhật Giờ vào (AttStart)
	UPDATE a SET AttStart = b.MinAttTime, MissGPSAttStart = b.MissedGPS
	FROM #tmpSchedule a
	INNER JOIN (
		SELECT t.EmployeeID, t.AttDate, MIN(t.AttTime) as MinAttTime, MIN(t.MissedGPS) as MissedGPS
		FROM #tmpGPSData t
		INNER JOIN #tmpSchedule s ON t.EmployeeID = s.EmployeeID AND t.AttDate = s.ScheduleDate
		WHERE (t.AttState = 1 OR t.AttState IS NULL) AND t.AttTime <= s.BreakEnd
		GROUP BY t.EmployeeID, t.AttDate
	) b ON a.EmployeeID = b.EmployeeID AND a.ScheduleDate = b.AttDate;

	-- Cập nhật Giờ ra (AttEnd)
	UPDATE a SET AttEnd = b.MaxAttTime, MissGPSAttEnd = b.MissedGPS
	FROM #tmpSchedule a
	INNER JOIN (
		SELECT t.EmployeeID, t.AttDate, MAX(t.AttTime) as MaxAttTime, MIN(t.MissedGPS) as MissedGPS
		FROM #tmpGPSData t
		INNER JOIN #tmpSchedule s ON t.EmployeeID = s.EmployeeID AND t.AttDate = s.ScheduleDate
		WHERE (t.AttState = 2 OR t.AttState IS NULL) AND t.AttTime >= COALESCE(DATEADD(mi, 15, s.AttStart), s.BreakStart, DATEADD(mi, 30, s.WorkStart))
		GROUP BY t.EmployeeID, t.AttDate
	) b ON a.EmployeeID = b.EmployeeID AND a.ScheduleDate = b.AttDate;

	-- Trường hợp vào làm buổi chiều ngày cuối tuần
	UPDATE a SET AttStart = b.MinAttTime
	FROM #tmpSchedule a
	INNER JOIN (
		SELECT t.EmployeeID, t.AttDate, MIN(t.AttTime) as MinAttTime
		FROM #tmpGPSData t
		GROUP BY t.EmployeeID, t.AttDate
	) b ON a.EmployeeID = b.EmployeeID AND a.ScheduleDate = b.AttDate
	WHERE a.AttStart IS NULL AND a.AttEnd IS NOT NULL AND b.MinAttTime <= DATEADD(mi, -15, a.AttEnd);
	
	-- 5. CẬP NHẬT NGÀY NGHỈ & LUẬT CUỐI TUẦN
	;WITH tmpLeave AS (
		SELECT a.EmployeeID, a.LeaveDate, SUM(LvAmount) AS LvAmount
		FROM tblLvHistory a WITH(NOLOCK)
		WHERE a.LeaveDate BETWEEN @FromDate AND @ToDate
		  AND EXISTS(SELECT 1 FROM #tmpEmpList e WHERE a.EmployeeID = e.EmployeeID)
		  AND a.LeaveCode NOT IN ('CT','WFH')
		GROUP BY a.EmployeeID, a.LeaveDate
	)
	UPDATE a SET LvAmount = b.LvAmount
	FROM #tmpSchedule a
	INNER JOIN tmpLeave b ON a.EmployeeID = b.EmployeeID AND a.ScheduleDate = b.LeaveDate;

	-- Cuối tuần bắt buộc phải chấm công đầy đủ
	DELETE FROM #tmpSchedule WHERE HolidayStatus > 0 AND (AttStart IS NULL OR AttEnd IS NULL);

	-- TÍNH TOÁN SỐ PHÚT LÀM VIỆC (WORKING TIME MINUTE)
	UPDATE s
	SET WorkingTimeMinute =
		CASE
			WHEN Gross.Minutes > 0 THEN
				Gross.Minutes - CASE WHEN Brk.Minutes > 0 THEN Brk.Minutes ELSE 0 END
			ELSE 0
		END
	FROM #tmpSchedule s
	CROSS APPLY (
		SELECT
			EffStart = CASE WHEN s.AttStart < s.WorkStart THEN s.WorkStart ELSE s.AttStart END,
			EffEnd   = CASE WHEN s.AttEnd > s.WorkEnd THEN s.WorkEnd ELSE s.AttEnd END
	) Eff
	CROSS APPLY (
		SELECT Minutes = DATEDIFF(minute, Eff.EffStart, Eff.EffEnd)
	) Gross
	CROSS APPLY (
		SELECT
			BrkStart = CASE WHEN Eff.EffStart > s.BreakStart THEN Eff.EffStart ELSE s.BreakStart END,
			BrkEnd   = CASE WHEN Eff.EffEnd < s.BreakEnd THEN Eff.EffEnd ELSE s.BreakEnd END
	) BrkOverlap
	CROSS APPLY (
		SELECT Minutes = DATEDIFF(minute, BrkOverlap.BrkStart, BrkOverlap.BrkEnd)
	) Brk
	WHERE s.HolidayStatus = 0 and s.AttStart IS NOT NULL
	  AND s.AttEnd IS NOT NULL
	  AND s.AttStart < s.WorkEnd
	  AND s.AttEnd > s.WorkStart;

	-- 6. PHÂN LOẠI VÀ CHẤM ĐIỂM
	IF OBJECT_ID('tempdb..#tmpPointWorking') IS NOT NULL DROP TABLE #tmpPointWorking;
	CREATE TABLE #tmpPointWorking(
		EmployeeID varchar(20), CreatedDate datetime, PointType int, iPoint int, MiAtt int, Rate float,
		OrgXP_Point int, ExperiencePonits int
	);
	CREATE CLUSTERED INDEX CIX_tmpPointWorking ON #tmpPointWorking(EmployeeID, CreatedDate, PointType);
	
	INSERT INTO #tmpPointWorking(EmployeeID, CreatedDate, MiAtt, PointType, Rate)
	SELECT s.EmployeeID, s.ScheduleDate, p.MiAtt, p.PType, p.PRate
	FROM #tmpSchedule s
	CROSS APPLY (
		-- Phạt đi trễ (PointType 5)
		SELECT DATEDIFF(mi, s.WorkStart, s.AttStart), 5, -2.0 
		WHERE s.AttStart BETWEEN s.WorkStart AND DATEADD(mi, 30, s.WorkStart) AND ISNULL(s.LvAmount, 8) >= 1.0 AND s.HolidayStatus = 0
		UNION ALL
		-- Phạt về sớm (PointType 6)
		SELECT DATEDIFF(mi, s.AttEnd, s.WorkEnd), 6, -2.0
		WHERE s.AttEnd BETWEEN DATEADD(mi, -30, s.WorkEnd) AND s.WorkEnd AND ISNULL(s.LvAmount, 8) >= 1.0 AND s.HolidayStatus = 0
		UNION ALL
		-- Vào làm sớm (PointType 7)
		SELECT DATEDIFF(mi, s.AttStart, s.WorkStart), 7, 0.5
		WHERE s.HolidayStatus = 0 AND s.AttStart < s.WorkStart AND s.MissGPSAttStart = 0
		UNION ALL
		-- Về trễ (PointType 8)
		SELECT DATEDIFF(mi, s.WorkEnd, s.AttEnd), 8, 0.5
		WHERE s.HolidayStatus = 0 AND s.AttEnd > s.WorkEnd AND s.MissGPSAttEnd = 0
		UNION ALL
		-- Giờ công thực tế (PointType 9)
		SELECT ROUND(s.WorkingTimeMinute, 0), 9, 1.0
		WHERE s.WorkingTimeMinute <> 0
		UNION ALL
		-- Đi làm cuối tuần (PointType 10)
		SELECT DATEDIFF(mi, s.AttStart, s.AttEnd), 10, 1.0
		WHERE s.HolidayStatus > 0 AND DATEDIFF(mi, s.AttStart, s.AttEnd) >= 30
	) p (MiAtt, PType, PRate);

	-- Đi công tác/WFH vẫn được tính đủ công (PointType 9)
	;WITH tmpLeave AS (
		SELECT a.EmployeeID, a.LeaveDate, SUM(LvAmount) AS LvAmount
		FROM tblLvHistory a WITH(NOLOCK)
		WHERE a.LeaveDate BETWEEN @FromDate AND @ToDate
		  AND EXISTS(SELECT 1 FROM #tmpEmpList e WHERE a.EmployeeID = e.EmployeeID)
		  AND a.LeaveCode in ('CT','WFH')
		GROUP BY a.EmployeeID, a.LeaveDate
	)
	MERGE #tmpPointWorking AS Target
	USING tmpLeave AS Source
	ON (Target.EmployeeID = Source.EmployeeID AND Target.CreatedDate = Source.LeaveDate AND Target.PointType = 9)
	WHEN MATCHED THEN
		UPDATE SET Target.MiAtt = ISNULL(Target.MiAtt,0) + ISNULL(Source.LvAmount * 60,0)
	WHEN NOT MATCHED THEN
		INSERT (EmployeeID, CreatedDate, MiAtt, PointType, Rate)
		VALUES (Source.EmployeeID, Source.LeaveDate, Source.LvAmount * 60, 9, 1.0);
	
	UPDATE #tmpPointWorking SET MiAtt = 480 WHERE MiAtt > 480 AND PointType = 9;
	
	-- Tính điểm & Lọc bỏ điểm = 0
	UPDATE #tmpPointWorking SET iPoint = CAST((MiAtt * Rate) AS INT);

	-- 5.9 Fix data bug: Inherit dates from parent for leaf tasks missing them
	-- Case 1: Has parent
	UPDATE t
	SET t.ActualStartDate = p.ActualStartDate,
	    t.ActualFinishDate = p.ActualFinishDate
	FROM tblTask_Tasks t WITH(NOLOCK)
	INNER JOIN tblTask_Tasks p WITH(NOLOCK) ON t.ParentHistoryID = p.HistoryID
	WHERE t.StatusID = 4 -- Approved
	  AND t.ActualStartDate IS NULL 
	  AND t.ActualFinishDate IS NULL
	  AND (p.ActualStartDate IS NOT NULL OR p.ActualFinishDate IS NOT NULL)
	  AND NOT EXISTS (SELECT 1 FROM tblTask_Tasks sub WITH(NOLOCK) WHERE sub.ParentHistoryID = t.HistoryID)
	  -- Tối ưu: Chỉ quét các task trong vòng 3 tháng gần đây để tránh scan toàn bộ lịch sử
	  AND (t.ModifiedDate >= DATEADD(month, -3, @FromDate) OR t.dDate >= DATEADD(month, -3, @FromDate));

	-- Case 2: Independent task (no parent) - use ModifiedDate/dDate as fallback
	UPDATE t
	SET t.ActualStartDate = COALESCE(t.ModifiedDate, t.dDate),
	    t.ActualFinishDate = COALESCE(t.ModifiedDate, t.dDate)
	FROM tblTask_Tasks t WITH(NOLOCK)
	WHERE t.StatusID = 4 -- Approved
	  AND t.ActualStartDate IS NULL 
	  AND t.ActualFinishDate IS NULL
	  AND t.ParentHistoryID IS NULL
	  AND NOT EXISTS (SELECT 1 FROM tblTask_Tasks sub WITH(NOLOCK) WHERE sub.ParentHistoryID = t.HistoryID)
	  -- Tối ưu: Chỉ quét các task trong kỳ lương hiện tại
	  AND (t.ModifiedDate >= @FromDate OR t.dDate >= @FromDate);

	IF OBJECT_ID('tempdb..#tmpAllTasks') IS NOT NULL DROP TABLE #tmpAllTasks;
	IF OBJECT_ID('tempdb..#tmpLeafTasks') IS NOT NULL DROP TABLE #tmpLeafTasks;
	
	-- Bước 1: Lấy tất cả các task thỏa mãn điều kiện ngày và status vào bảng tạm trung gian
	SELECT 
		t.HistoryID,
		t.AssigneeID,
		t.StandardTime,
		COALESCE(t.ActualFinishDate, t.ActualStartDate) AS TaskDate,
		t.StatusID,
		t.ParentHistoryID
	INTO #tmpAllTasks
	FROM tblTask_Tasks t WITH(NOLOCK)
	WHERE COALESCE(t.ActualFinishDate, t.ActualStartDate) >= @FromDate 
	  AND COALESCE(t.ActualFinishDate, t.ActualStartDate) < @ToDate
	  AND t.AssigneeID IS NOT NULL
	  AND t.StatusID = 4;

	CREATE CLUSTERED INDEX CIX_tmpAllTasks ON #tmpAllTasks(HistoryID);

	-- Bước 2: Lọc ra task lá từ bảng tạm #tmpAllTasks
	SELECT * 
	INTO #tmpLeafTasks
	FROM #tmpAllTasks t
	WHERE NOT EXISTS (
		SELECT 1 FROM #tmpAllTasks sub 
		WHERE sub.ParentHistoryID = t.HistoryID
	);
	
	CREATE CLUSTERED INDEX CIX_tmpLeafTasks ON #tmpLeafTasks(HistoryID);

	-- Bước 2.1: Tìm tất cả HistoryID của task lá và các tổ tiên của chúng để giới hạn phạm vi quét approval
	IF OBJECT_ID('tempdb..#tmpLeafAndAncestors') IS NOT NULL DROP TABLE #tmpLeafAndAncestors;
	
	WITH CTE_Hierarchy AS (
		SELECT HistoryID, ParentHistoryID, 1 AS Depth
		FROM #tmpLeafTasks
		
		UNION ALL
		
		SELECT parent.HistoryID, parent.ParentHistoryID, cte.Depth + 1
		FROM CTE_Hierarchy cte
		INNER JOIN tblTask_Tasks parent WITH(NOLOCK) ON cte.ParentHistoryID = parent.HistoryID
		WHERE cte.ParentHistoryID IS NOT NULL
		  AND cte.Depth < 10
	)
	SELECT DISTINCT HistoryID
	INTO #tmpLeafAndAncestors
	FROM CTE_Hierarchy;
	
	CREATE CLUSTERED INDEX CIX_tmpLeafAndAncestors ON #tmpLeafAndAncestors(HistoryID);

	-- Bước 2.2: Tối ưu hóa - Tính toán trước trạng thái phê duyệt của các task có liên quan
	IF OBJECT_ID('tempdb..#tmpApprovalStatus') IS NOT NULL DROP TABLE #tmpApprovalStatus;
	SELECT HistoryID, ApprovalStatus
	INTO #tmpApprovalStatus
	FROM (
		SELECT HistoryID, ApprovalStatus,
			   ROW_NUMBER() OVER (PARTITION BY HistoryID ORDER BY StageOrder DESC, dDate DESC) as rn
		FROM tblTask_Approvals WITH(NOLOCK)
		WHERE HistoryID IN (SELECT HistoryID FROM #tmpLeafAndAncestors)
	) a WHERE rn = 1;

	CREATE CLUSTERED INDEX CIX_tmpApprovalStatus ON #tmpApprovalStatus(HistoryID);

	-- Bước 2.3: Sử dụng CTE đệ quy để kiểm tra phê duyệt từ lá lên đến gốc (Phương án A)
	IF OBJECT_ID('tempdb..#tmpLeafApprovals') IS NOT NULL DROP TABLE #tmpLeafApprovals;
	
	WITH CTE_AncestorApproval AS (
		-- Neo (Anchor): Chính các task lá
		SELECT 
			t.HistoryID AS LeafHistoryID,
			t.HistoryID AS AncestorHistoryID,
			t.ParentHistoryID,
			1 AS Depth
		FROM #tmpLeafTasks t
		
		UNION ALL
		
		-- Phần đệ quy (Recursive): Duyệt ngược lên cha (Chỉ sử dụng INNER JOIN)
		SELECT 
			cte.LeafHistoryID,
			parent.HistoryID AS AncestorHistoryID,
			parent.ParentHistoryID,
			cte.Depth + 1
		FROM CTE_AncestorApproval cte
		INNER JOIN tblTask_Tasks parent WITH(NOLOCK) ON cte.ParentHistoryID = parent.HistoryID
		WHERE cte.ParentHistoryID IS NOT NULL
		  AND cte.Depth < 10
	)
	SELECT 
		cte.LeafHistoryID, 
		MAX(COALESCE(ap.ApprovalStatus, 0)) AS FinalApprovalStatus
	INTO #tmpLeafApprovals
	FROM CTE_AncestorApproval cte
	LEFT JOIN #tmpApprovalStatus ap ON cte.AncestorHistoryID = ap.HistoryID
	GROUP BY cte.LeafHistoryID;

	CREATE CLUSTERED INDEX CIX_tmpLeafApprovals ON #tmpLeafApprovals(LeafHistoryID);

	-- Bước 3: Xác định trạng thái phê duyệt cuối cùng và tính điểm
	INSERT INTO #tmpPointWorking(EmployeeID, CreatedDate, MiAtt, PointType, Rate, iPoint)
	SELECT 
		TRIM(s.value) AS EmployeeID, 
		CAST(t.TaskDate AS DATE) AS CreatedDate, 
		SUM(t.StandardTime), 
		2, 
		2.0, 
		CAST(SUM(t.StandardTime) * 2.0 AS INT)
	FROM #tmpLeafTasks t
	CROSS APPLY STRING_SPLIT(t.AssigneeID, ',') s
	INNER JOIN #tmpLeafApprovals la ON t.HistoryID = la.LeafHistoryID
	WHERE la.FinalApprovalStatus = 1
	  AND EXISTS(SELECT 1 FROM #tmpEmpList e WHERE TRIM(s.value) = e.EmployeeID)
	GROUP BY TRIM(s.value), CAST(t.TaskDate AS DATE);

	DROP TABLE #tmpAllTasks;
	DROP TABLE #tmpLeafTasks;
	DROP TABLE #tmpLeafAndAncestors;
	DROP TABLE #tmpApprovalStatus;
	DROP TABLE #tmpLeafApprovals;
	
	DELETE FROM #tmpPointWorking WHERE iPoint = 0 OR iPoint IS NULL;

	-- Cập nhật OrgXP_Point và ExperiencePonits dựa trên LevelRate hoạt động tại CreatedDate
	UPDATE t
	SET t.OrgXP_Point = t.iPoint,
		t.ExperiencePonits = CASE 
			WHEN t.PointType = 2 THEN CAST(ROUND(CAST(t.iPoint AS float) / COALESCE(NULLIF(lvl.LevelRate, 0), 1.0), 0) AS int)
			ELSE t.iPoint
		END
	FROM #tmpPointWorking t
	OUTER APPLY (
		SELECT TOP 1 l.LevelRate
		FROM tblLevelIDHistory lh WITH(NOLOCK)
		INNER JOIN tblLevel l WITH(NOLOCK) ON lh.LevelID = l.LevelID
		WHERE lh.EmployeeID = t.EmployeeID
		  AND lh.EffectiveDate <= t.CreatedDate
		ORDER BY lh.EffectiveDate DESC
	) lvl;

	-- gui thong bao bu cong len ung dung ParadiseHR tren dien thoai cua nhan vien
	SELECT te.EmployeeID, te.FullName,
    STRING_AGG(CONVERT(varchar(10), ws.ScheduleDate, 103), ', ') WITHIN GROUP (ORDER BY ws.ScheduleDate) AS ScheduleDates
	INTO #DailyAttendance_Notify
	FROM #tmpSchedule ws
	INNER JOIN #tmpEmpList te ON ws.EmployeeID = te.EmployeeID
	WHERE ws.ScheduleDate < DATEADD(day, -1, @Now)
	  AND (ws.LvAmount IS NULL OR ws.LvAmount < 8)
	  AND (ws.AttStart IS NULL OR ws.AttEnd IS NULL)
	GROUP BY te.EmployeeID, te.FullName;
		
	insert into tblEmailList(TemplateName,SendStatus,Approved_Send,SendToEmployeeID,ParadiseBadge,EmailType,SendBodyEmail,CreateTime)
	select 'DailyAttendance_Remind',0 ,1 as Approved_Send,te.EmployeeID SendToEmployeeID,1 ParadiseBadge,10 EmailType
	, N'Ngày: '+ScheduleDates+N'
Dữ liệu chấm công chưa hoàn thiện.
Vui lòng làm thủ tục bổ sung nhé ' + isnull(te.FullName,'') , @Now
	from #DailyAttendance_Notify te
	where not exists (
		select 1
		from tblEmailList e
		where e.TemplateName = 'DailyAttendance_Remind'
		  and e.SendToEmployeeID = te.EmployeeID
		  and DATEDIFF(day,e.LastUpdateTime,@Now) = 0
	);
	
	if @@ROWCOUNT > 0
		UPDATE TaskSchedule SET LastTryDay = '2026-01-01',NextRunDate = '2026-01-01' from TaskSchedule where FunctionName = 'SendPendingEmail' and IsActive = 1
	
	IF OBJECT_ID('tempdb..#tblRank_PersonalRating_Detail') IS NOT NULL DROP TABLE #tblRank_PersonalRating_Detail;
	
	CREATE TABLE #tblRank_PersonalRating_Detail (
		ID bigint, EmployeeID varchar(20), CreatedDate datetime,
		PointType int, ExperiencePonits int, OrgXP_Point int, NeedDelete bit DEFAULT 0
	);

	INSERT INTO #tblRank_PersonalRating_Detail (ID, EmployeeID, CreatedDate, PointType, ExperiencePonits, OrgXP_Point, NeedDelete)
	SELECT ID, EmployeeID, CreatedDate, PointType, ExperiencePonits, OrgXP_Point, 0
	FROM tblRank_PersonalRating_Detail a WITH(NOLOCK)
	WHERE CreatedDate BETWEEN @FromDate AND @ToDate
	  AND PointType IN (2,5,6,7,8,9,10)
	  AND EXISTS(SELECT 1 FROM #tmpEmpList e WHERE a.EmployeeID = e.EmployeeID);

	CREATE CLUSTERED INDEX CIX_tblRank_Detail ON #tblRank_PersonalRating_Detail(ID);
	CREATE NONCLUSTERED INDEX IX_tblRank_Detail_Match ON #tblRank_PersonalRating_Detail(EmployeeID, CreatedDate, PointType);
	
	--UPDATE a SET ExperiencePonits = b.ExperiencePonits
	--FROM #tblRank_PersonalRating_Detail a
	--INNER JOIN #tmpPointWorking b ON a.EmployeeID = b.EmployeeID AND a.CreatedDate = b.CreatedDate AND a.PointType = b.PointType;

	UPDATE a SET NeedDelete = 1
	FROM #tblRank_PersonalRating_Detail a
	WHERE NOT EXISTS(SELECT 1 FROM #tmpPointWorking b WHERE a.EmployeeID = b.EmployeeID AND a.CreatedDate = b.CreatedDate AND a.PointType = b.PointType);
	
	BEGIN TRY
		BEGIN TRAN; 

		MERGE tblRank_PersonalRating_Detail AS Target
		USING #tmpPointWorking AS Source
		ON (
			Target.EmployeeID = Source.EmployeeID AND Target.CreatedDate = Source.CreatedDate AND Target.PointType = Source.PointType
		)
		WHEN MATCHED AND (Target.ExperiencePonits <> Source.ExperiencePonits OR ISNULL(Target.OrgXP_Point, -999999) <> ISNULL(Source.OrgXP_Point, -999999)) THEN
			UPDATE SET Target.ExperiencePonits = Source.ExperiencePonits,
					   Target.OrgXP_Point = Source.OrgXP_Point
		WHEN NOT MATCHED THEN
			INSERT (EmployeeID, ExperiencePonits, OrgXP_Point, Coin, CreatedDate, PointType)
			VALUES (Source.EmployeeID, Source.ExperiencePonits, Source.OrgXP_Point, 0, Source.CreatedDate, Source.PointType);
		
		DELETE a FROM tblRank_PersonalRating_Detail a
		INNER JOIN #tblRank_PersonalRating_Detail b ON a.ID = b.ID
		WHERE b.NeedDelete = 1;

		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN;
		-- GIẢI PHÓNG KHÓA NẾU CÓ LỖI VÀ VĂNG VÀO CATCH
		if @isDebug = 0 EXEC sp_releaseapplock @Resource = @Lock_Resource, @LockOwner = 'Session';
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH
	if @isDebug = 0 EXEC sp_releaseapplock @Resource = @Lock_Resource, @LockOwner = 'Session';
	print 'eof sp_PerformanceKPI_Working_Process'
END
GO
PRINT 'Stored procedure sp_PerformanceKPI_Working_Process deployed successfully.';
GO
