--exec sp_PerformanceKPI_Working_Process '2026-03-10','2026-03-20','-1',3
CREATE PROCEDURE [dbo].[sp_PerformanceKPI_Working_Process]
	@FromDate datetime = null,
	@ToDate datetime = null,
	@EmployeeID varchar(20) = '-1',
	@LoginID int = 3,
	@isDebug bit = 0
AS
BEGIN
	SET NOCOUNT ON;
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
	  AND DATEDIFF(MILLISECOND, LastExecuted, @Now) >= @waitInterval;
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
		SELECT e.EmployeeID, d.ScheduleDate, e.SaturdayOff, e.SundayOff
		FROM #tmpEmpList e
		CROSS JOIN CTE_Dates d
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
	LEFT JOIN tblWSchedule a WITH(NOLOCK)
		ON ed.EmployeeID = a.EmployeeID AND ed.ScheduleDate = a.ScheduleDate
	INNER JOIN tblShiftSetting ss WITH(NOLOCK)
		ON ss.ShiftID = COALESCE(a.ShiftID, @DefaultShiftID)
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
	-- Dọn rác & Đánh Index
	DROP TABLE #tmpSchedule_Base;
	IF OBJECT_ID('tempdb..#tmpGPSData') IS NOT NULL DROP TABLE #tmpGPSData;

	SELECT a.EmployeeID,
		   CAST(a.AttTime AS DATE) AS AttDate,
		   a.AttTime,
		   CASE WHEN a.UrlFileLocal <> '' THEN 0 ELSE 1 END AS MissedGPS,
		   a.AttState
	INTO #tmpGPSData
	FROM tblTmpAttend a WITH(NOLOCK)
	INNER JOIN #tmpEmpList te ON a.EmployeeID = te.EmployeeID
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
	UPDATE a SET AttStart = b.MinAttTime, MissGPSAttStart = b.MissedGPS
	FROM #tmpSchedule a
	INNER JOIN (
		SELECT t.EmployeeID, t.AttDate, MIN(t.AttTime) as MinAttTime, Min (t.MissedGPS) MissedGPS
		FROM #tmpGPSData t
		INNER JOIN #tmpSchedule s ON t.EmployeeID = s.EmployeeID AND t.AttDate = s.ScheduleDate
		WHERE (t.AttState = 1 or t.AttState is null) and t.AttTime <= s.BreakEnd
		GROUP BY t.EmployeeID, t.AttDate
	) b ON a.EmployeeID = b.EmployeeID AND a.ScheduleDate = b.AttDate;
	UPDATE a SET AttEnd = b.MaxAttTime, MissGPSAttEnd = b.MissedGPS
	FROM #tmpSchedule a
	INNER JOIN (
		SELECT t.EmployeeID, t.AttDate, MAX(t.AttTime) as MaxAttTime , Min (t.MissedGPS) MissedGPS
		FROM #tmpGPSData t
		INNER JOIN #tmpSchedule s ON t.EmployeeID = s.EmployeeID AND t.AttDate = s.ScheduleDate
		WHERE (t.AttState = 2 or t.AttState is null) and t.AttTime >= COALESCE(DATEADD(mi, 15, s.AttStart), s.BreakStart, DATEADD(mi, 30, s.WorkStart))
		GROUP BY t.EmployeeID, t.AttDate
	) b ON a.EmployeeID = b.EmployeeID AND a.ScheduleDate = b.AttDate;

	-- Trường hợp vào làm buổi chiều ngày cuối tuần
	UPDATE a SET AttStart = b.MinAttTime
	FROM #tmpSchedule a
	INNER JOIN (
		SELECT t.EmployeeID, t.AttDate, MIN(t.AttTime) as MinAttTime
		FROM #tmpGPSData t
		INNER JOIN #tmpSchedule s ON t.EmployeeID = s.EmployeeID AND t.AttDate = s.ScheduleDate
		WHERE s.AttStart IS NULL AND s.AttEnd IS NOT NULL AND t.AttTime <= DATEADD(mi, -15, s.AttEnd)
		GROUP BY t.EmployeeID, t.AttDate
	) b ON a.EmployeeID = b.EmployeeID AND a.ScheduleDate = b.AttDate;
	
	-- 5. CẬP NHẬT NGÀY NGHỈ & LUẬT CUỐI TUẦN
	;WITH tmpLeave AS (
		SELECT a.EmployeeID, a.LeaveDate, SUM(LvAmount) AS LvAmount
		FROM tblLvHistory a WITH(NOLOCK)
		WHERE a.LeaveDate BETWEEN @FromDate AND @ToDate
		  AND EXISTS(SELECT 1 FROM #tmpEmpList e WHERE a.EmployeeID = e.EmployeeID)
		  AND a.LeaveCode NOT IN ('CT')
		GROUP BY a.EmployeeID, a.LeaveDate
	)
	UPDATE a SET LvAmount = b.LvAmount
	FROM #tmpSchedule a
	INNER JOIN tmpLeave b ON a.EmployeeID = b.EmployeeID AND a.ScheduleDate = b.LeaveDate;

	-- Cuối tuần bắt buộc phải chấm công đầy đủ
	DELETE FROM #tmpSchedule WHERE HolidayStatus > 0 AND (AttStart IS NULL OR AttEnd IS NULL);
	-- 6. PHÂN LOẠI VÀ CHẤM ĐIỂM
	IF OBJECT_ID('tempdb..#tmpPointWorking') IS NOT NULL DROP TABLE #tmpPointWorking;
	CREATE TABLE #tmpPointWorking(
		EmployeeID varchar(20), CreatedDate datetime, PointType int, iPoint int, MiAtt int, Rate float
	);

	-- Phạt đi trễ (-2)
	INSERT INTO #tmpPointWorking(EmployeeID, CreatedDate, MiAtt, PointType, Rate)
	SELECT EmployeeID, ScheduleDate, DATEDIFF(mi, WorkStart, AttStart), 5, -2.0
	FROM #tmpSchedule
	WHERE AttStart BETWEEN WorkStart AND DATEADD(mi, 30, WorkStart)
	  AND ISNULL(LvAmount, 8) >= 1.0 AND HolidayStatus = 0;

	-- Phạt về sớm (-2)
	INSERT INTO #tmpPointWorking(EmployeeID, CreatedDate, MiAtt, PointType, Rate)
	SELECT EmployeeID, ScheduleDate, DATEDIFF(mi, AttEnd, WorkEnd), 6, -2.0
	FROM #tmpSchedule
	WHERE AttEnd BETWEEN DATEADD(mi, -30, WorkEnd) AND WorkEnd
	  AND ISNULL(LvAmount, 8) >= 1.0 AND HolidayStatus = 0;

	-- Vào làm sớm (0.5)
	INSERT INTO #tmpPointWorking(EmployeeID, CreatedDate, MiAtt, PointType, Rate)
	SELECT EmployeeID, ScheduleDate, DATEDIFF(mi, AttStart, WorkStart), 7, 0.5
	FROM #tmpSchedule WHERE HolidayStatus = 0 AND AttStart < WorkStart and MissGPSAttStart  = 0;
	-- Về trễ (0.5)
	INSERT INTO #tmpPointWorking(EmployeeID, CreatedDate, MiAtt, PointType, Rate)
	SELECT EmployeeID, ScheduleDate, DATEDIFF(mi, WorkEnd, AttEnd), 8, 0.5
	FROM #tmpSchedule WHERE HolidayStatus = 0 AND AttEnd > WorkEnd and MissGPSAttEnd = 0;
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
	  AND s.AttStart < s.WorkEnd   -- Chỉ tính nếu có làm việc trước khi hết ca
	  AND s.AttEnd > s.WorkStart;  -- Chỉ tính nếu có làm việc sau khi bắt đầu ca
	  INSERT INTO #tmpPointWorking(EmployeeID, CreatedDate, MiAtt, PointType, Rate)
	SELECT EmployeeID, ScheduleDate, ROUND(WorkingTimeMinute, 0), 9, 1.0
	FROM #tmpSchedule WHERE WorkingTimeMinute <> 0;

	-- Đi làm cuối tuần x1 điểm
	INSERT INTO #tmpPointWorking(EmployeeID, CreatedDate, MiAtt, PointType, Rate)
	SELECT EmployeeID, ScheduleDate, DATEDIFF(mi, AttStart, AttEnd), 10, 1.0
	FROM #tmpSchedule
	WHERE HolidayStatus > 0 AND DATEDIFF(mi, AttStart, AttEnd) >= 30;
	
	-- Tính điểm & Lọc bỏ điểm = 0
	UPDATE #tmpPointWorking SET iPoint = CAST((MiAtt * Rate) AS INT);
	DELETE FROM #tmpPointWorking WHERE iPoint = 0 OR iPoint IS NULL;
	-- gui thong bao bu cong len ung dung ParadiseHR tren dien thoai cua nhan vien
	select te.EmployeeID, te.FullName,
    STUFF((
        select ', ' + CONVERT(varchar(10), ws2.ScheduleDate, 103)
        from #tmpSchedule ws2
        where ws2.EmployeeID = te.EmployeeID
            and ws2.ScheduleDate < dateadd(day, -1, @Now)
            and (ws2.LvAmount is null or ws2.LvAmount < 8)
            and (ws2.AttStart is null or ws2.AttEnd is null)
        for xml path(''), type).value('.', 'nvarchar(max)'), 1, 2, '') as ScheduleDates
		into #DailyAttendance_Notify
	from #tmpSchedule ws inner join #tmpEmpList te on ws.EmployeeID = te.EmployeeID  where ws.ScheduleDate < dateadd(day,-1,@Now) and (ws.LvAmount is null or ws.LvAmount < 8) and (ws.AttStart is null or ws.AttEnd is null)
	group by te.EmployeeID, te.FullName
	
	if not exists (select e.SendToEmployeeID from tblEmailList e where e.TemplateName = 'DailyAttendance_Remind' and exists (select 1 from #DailyAttendance_Notify te where te.EmployeeID = e.SendToEmployeeID and DATEDIFF(day,e.LastUpdateTime,@Now) = 0))
		begin
		insert into tblEmailList(TemplateName,SendStatus,Approved_Send,SendToEmployeeID,ParadiseBadge,EmailType,SendBodyEmail,CreateTime)
		select 'DailyAttendance_Remind',0 ,1 as Approved_Send,te.EmployeeID SendToEmployeeID,1 ParadiseBadge,10 EmailType
		, N'Ngày: '+ScheduleDates+N'
Dữ liệu chấm công chưa hoàn thiện.
Vui lòng làm thủ tục bổ sung nhé ' + isnull(te.FullName,'') , @Now
		from #DailyAttendance_Notify te
		UPDATE TaskSchedule SET LastTryDay = '2026-01-01',NextRunDate = '2026-01-01' from TaskSchedule where FunctionName = 'SendPendingEmail' and IsActive = 1
	 end
	CREATE CLUSTERED INDEX CIX_tmpPointWorking ON #tmpPointWorking(EmployeeID, CreatedDate, PointType);
	IF OBJECT_ID('tempdb..#tblRank_PersonalRating_Detail') IS NOT NULL DROP TABLE #tblRank_PersonalRating_Detail;
	
	CREATE TABLE #tblRank_PersonalRating_Detail (
		ID bigint, EmployeeID varchar(20), CreatedDate datetime,
		PointType int, ExperiencePonits int, NeedDelete bit DEFAULT 0
	);

	INSERT INTO #tblRank_PersonalRating_Detail (ID, EmployeeID, CreatedDate, PointType, ExperiencePonits, NeedDelete)
	SELECT ID, EmployeeID, CreatedDate, PointType, ExperiencePonits, 0
	FROM tblRank_PersonalRating_Detail a WITH(NOLOCK)
	WHERE CreatedDate BETWEEN @FromDate AND @ToDate
	  AND PointType IN (5,6,7,8,9,10)
	  AND EXISTS(SELECT 1 FROM #tmpEmpList e WHERE a.EmployeeID = e.EmployeeID);

	CREATE CLUSTERED INDEX CIX_tblRank_Detail ON #tblRank_PersonalRating_Detail(ID);
	CREATE NONCLUSTERED INDEX IX_tblRank_Detail_Match ON #tblRank_PersonalRating_Detail(EmployeeID, CreatedDate, PointType);
	
	UPDATE a SET ExperiencePonits = b.iPoint
	FROM #tblRank_PersonalRating_Detail a
	INNER JOIN #tmpPointWorking b ON a.EmployeeID = b.EmployeeID AND a.CreatedDate = b.CreatedDate AND a.PointType = b.PointType;

	UPDATE a SET NeedDelete = 1
	FROM #tblRank_PersonalRating_Detail a
	WHERE NOT EXISTS(SELECT 1 FROM #tmpPointWorking b WHERE a.EmployeeID = b.EmployeeID AND a.CreatedDate = b.CreatedDate AND a.PointType = b.PointType);
	
	BEGIN TRY
		BEGIN TRAN;
		
		UPDATE a SET ExperiencePonits = b.ExperiencePonits
		FROM tblRank_PersonalRating_Detail a
		INNER JOIN #tblRank_PersonalRating_Detail b ON a.ID = b.ID
		WHERE a.ExperiencePonits <> b.ExperiencePonits;
		
		INSERT INTO tblRank_PersonalRating_Detail(EmployeeID, ExperiencePonits, Coin, CreatedDate, PointType)
		SELECT EmployeeID, iPoint, 0, CreatedDate, PointType
		FROM #tmpPointWorking a
		WHERE NOT EXISTS(SELECT 1 FROM #tblRank_PersonalRating_Detail b WHERE a.EmployeeID = b.EmployeeID AND a.CreatedDate = b.CreatedDate AND a.PointType = b.PointType);
		
		DELETE a
		FROM tblRank_PersonalRating_Detail a
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
