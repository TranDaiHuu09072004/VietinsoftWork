-- ============================================================================
-- File   : SQL script/migrate_menu_ComplaintForm_20260523.sql
-- Mục đích: Migrate cặp menu KHIẾU NẠI từ Paradise_Dev sang DB ParadiseHR khác
--          - MnuAT009 = "Danh sách đơn khiếu nại" (ClassName: sp_Task_GetComplaintList)
--          - MnuAT010 = "Đơn khiếu nại"           (ClassName: sp_Task_ComplaintForm)
-- Nguồn  : DB Paradise_Dev (SVRVTS01\SQL2022), extract qua MCP `Paradise_Dev`
--          ngày 2026-05-23 — đã verify đầy đủ:
--            * MEN_Menu, tblSC_Object, tblMD_Message
--            * 6 row tblCommonControlType_Signed (sp_Task_ComplaintForm_html)
--            * 4 procedure API (sp_Task_Complaint_GetDataList/GetDetail/Resolve/Submit)
--            * 2 procedure datasource (sp_Task_Complaint_GetUnfinishedTasks/getComplaintTypes)
--            * 2 procedure wrapper + 2 renderer _html
--            * 2 bảng master (tblTask_Complaints, tblTask_ComplaintTypes + 2 row seed)
--
-- Cảnh báo:
--   - USER tự review và CHẠY. Agent KHÔNG tự động thực thi.
--   - BACKUP DB trước khi chạy.
--   - DB ĐÍCH phải có sẵn các dependencies sau (KHÔNG tạo trong script này):
--       * Bảng    : tblTask_Tasks, tblTasks, tblTask_Approvals, tblTask_Comments,
--                   tblEmployee, tblSC_Login, tblSC_Object, tblMD_Message,
--                   tblEmailList, tblFileRequest, tblApproveStatus,
--                   tblHtmlScriptCache, tblCommonControlType_Signed,
--                   tblDataSetting, tblDataSettingLayout, MEN_Menu,
--                   tblSC_Right_Stored
--       * Function: fn_GetStringParamImageByEmployeeID
--       * SP      : sp_GetFile, sp_getEmployeeListWithPermission,
--                   sp_Task_SignalR_Detail_Update,
--                   sp_GenerateHTMLScript, sptblCommonControlType_Signed_DUC,
--                   sp_Men_Menu_AfterSave_Simple, dbo.[1rename_Mess]
--       * Template thông báo: sp_Task_NotiComplaint, sp_Task_NotiComplaintResult
--                   (không được tạo trong script này; nếu thiếu, notification
--                    insert vào tblEmailList sẽ rớt khi service đẩy noti.)
--
-- Idempotent: Chạy nhiều lần KHÔNG chèn trùng menu / object / quyền / cache.
-- ============================================================================

-- USE [<TenDBDich>];  -- USER mở comment + sửa tên DB đích trước khi chạy
-- GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT N'[INFO] === BEGIN migrate cặp menu Khiếu Nại MnuAT009 + MnuAT010 ===';
GO

-- ============================================================================
-- PHASE 1: Tạo 2 bảng master data (idempotent)
-- ============================================================================

IF OBJECT_ID('dbo.tblTask_ComplaintTypes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tblTask_ComplaintTypes (
        ComplaintTypeID     int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        ComplaintTypeName   nvarchar(255) NOT NULL,
        ComplaintTypeNameEN nvarchar(255) NULL
    );
    PRINT N'[OK] Created table tblTask_ComplaintTypes';
END
ELSE
    PRINT N'[SKIP] Table tblTask_ComplaintTypes already exists';
GO

IF OBJECT_ID('dbo.tblTask_Complaints', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.tblTask_Complaints (
        ComplaintID      int IDENTITY(1,1) NOT NULL PRIMARY KEY,
        HistoryID        int NULL,
        TaskID           int NULL,
        OldDueDate       datetime NULL,
        ProposedDueDate  datetime NULL,
        ComplaintReason  nvarchar(max) NULL,
        Approve_Status   int NULL,
        CreatedBy        varchar(30) NULL,
        CreatedDate      datetime NULL,
        ApprovedBy       varchar(30) NULL,
        ApprovedDate     datetime NULL,
        ApprovalNote     nvarchar(max) NULL,
        ComplaintType    int NULL
    );
    PRINT N'[OK] Created table tblTask_Complaints';
END
ELSE
    PRINT N'[SKIP] Table tblTask_Complaints already exists';
GO

-- ============================================================================
-- PHASE 2: Seed tblTask_ComplaintTypes (2 row - idempotent qua MERGE)
-- ============================================================================

-- Chỉ SET IDENTITY_INSERT ON/OFF khi cột ComplaintTypeID thực sự là IDENTITY ở DB đích.
-- DB đích có thể đã có sẵn bảng nhưng cột không khai báo IDENTITY → SET sẽ raise Msg 8106.
IF COLUMNPROPERTY(OBJECT_ID('dbo.tblTask_ComplaintTypes'), 'ComplaintTypeID', 'IsIdentity') = 1
    SET IDENTITY_INSERT dbo.tblTask_ComplaintTypes ON;
GO

MERGE dbo.tblTask_ComplaintTypes AS tgt
USING (VALUES
    (1, N'Gia hạn thời gian hoàn thành', N'Extend Deadline'),
    (2, N'Khiếu nại từ chối duyệt',      N'Appeal Rejection')
) AS src(ComplaintTypeID, ComplaintTypeName, ComplaintTypeNameEN)
   ON tgt.ComplaintTypeID = src.ComplaintTypeID
WHEN MATCHED THEN UPDATE SET
    tgt.ComplaintTypeName   = src.ComplaintTypeName,
    tgt.ComplaintTypeNameEN = src.ComplaintTypeNameEN
WHEN NOT MATCHED BY TARGET THEN
    INSERT (ComplaintTypeID, ComplaintTypeName, ComplaintTypeNameEN)
    VALUES (src.ComplaintTypeID, src.ComplaintTypeName, src.ComplaintTypeNameEN);
GO

IF COLUMNPROPERTY(OBJECT_ID('dbo.tblTask_ComplaintTypes'), 'ComplaintTypeID', 'IsIdentity') = 1
    SET IDENTITY_INSERT dbo.tblTask_ComplaintTypes OFF;
GO
PRINT N'[OK] Seeded tblTask_ComplaintTypes (2 rows)';
GO

-- ============================================================================
-- PHASE 3: Datasource Stored Procedures
-- ============================================================================

IF OBJECT_ID('dbo.sp_Task_Complaint_GetUnfinishedTasks', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Task_Complaint_GetUnfinishedTasks;
GO

    CREATE   PROCEDURE [dbo].[sp_Task_Complaint_GetUnfinishedTasks] (
        @LoginID INT,
        @LanguageID VARCHAR(2) = 'VN'
    )
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @EmployeeID VARCHAR(40);
        SELECT @EmployeeID = EmployeeID FROM tblSC_Login WHERE LoginID = @LoginID;

        IF @EmployeeID IS NULL OR @EmployeeID = ''
        BEGIN
            SELECT
                CAST(NULL AS INT) AS ID,
                CAST(NULL AS NVARCHAR(MAX)) AS Name,
                CAST(NULL AS DATETIME) AS DueDate
            WHERE 1 = 0;
            RETURN;
        END;

        -- Get the latest history record for each task
        WITH LatestHistory AS (
            SELECT
                HistoryID,
                TaskID,
                MainAssigneeID,
                AssigneeID,
                StatusID,
                DueDate,
                ROW_NUMBER() OVER (PARTITION BY TaskID ORDER BY HistoryID DESC) AS rn
            FROM tblTask_Tasks
        )
        SELECT
            h.HistoryID AS ID,
            tk.TaskName AS Name,
            h.DueDate
        FROM LatestHistory h
        JOIN tblTasks tk ON h.TaskID = tk.TaskID
        WHERE h.rn = 1
        -- Unfinished tasks (Assigned = 1, In Progress = 2, In Review = 3, Declined = 6)
        AND h.StatusID NOT IN (4, 5) -- Exclude Done (4) and Cancelled (5)
        -- Must have a due date
        AND h.DueDate IS NOT NULL
        -- Filter to only tasks assigned to the logged-in user
        AND (
            h.MainAssigneeID = @EmployeeID
            OR @EmployeeID IN (SELECT value FROM STRING_SPLIT(h.AssigneeID, ','))
        )
        ORDER BY tk.TaskName;
    END
GO
PRINT N'[OK] Created procedure sp_Task_Complaint_GetUnfinishedTasks';
GO

IF OBJECT_ID('dbo.sp_Task_getComplaintTypes', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Task_getComplaintTypes;
GO

create   procedure sp_Task_getComplaintTypes(
@LoginID int,
@LanguageID varchar(5) = 'VN'
)
as
begin
select ComplaintTypeID as ID,case when @LanguageID = 'VN' then ComplaintTypeName else ComplaintTypeNameEN end [Name] from tblTask_ComplaintTypes
end
GO
PRINT N'[OK] Created procedure sp_Task_getComplaintTypes';
GO

-- ============================================================================
-- PHASE 4: API Stored Procedures (Submit / GetDataList / GetDetail / Resolve)
-- ============================================================================

IF OBJECT_ID('dbo.sp_Task_Complaint_Submit', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Task_Complaint_Submit;
GO

    CREATE   PROCEDURE [dbo].[sp_Task_Complaint_Submit] (
        @HistoryID INT,
        @LoginID INT,
        @ComplaintReason NVARCHAR(MAX),  -- Base64 encoded HTML content from RichText editor
        @ProposedDueDate DATETIME = NULL,
        @ComplaintType INT = 1, -- 1 = Gia hạn, 2 = Khiếu nại từ chối
        @TempComplaintID VARCHAR(100) = NULL
    )
    AS
    BEGIN
        SET NOCOUNT ON;

        -- Validate if the task exists and LoginID has permission
        DECLARE @TaskID INT;
        DECLARE @AssigneeID NVARCHAR(MAX);
        DECLARE @MainAssigneeID NVARCHAR(MAX);
        DECLARE @OldDueDate DATETIME;
        DECLARE @TaskName NVARCHAR(MAX);

        SELECT @TaskID = t.TaskID,
            @AssigneeID = t.AssigneeID,
            @MainAssigneeID = t.MainAssigneeID,
            @OldDueDate = t.DueDate,
            @TaskName = tk.TaskName
        FROM tblTask_Tasks t
        JOIN tblTasks tk ON t.TaskID = tk.TaskID
        WHERE t.HistoryID = @HistoryID;

        IF @TaskID IS NULL
        BEGIN
            SELECT 'ERROR' AS Status, N'Công việc không tồn tại' AS Message;
            RETURN;
        END

        -- Check if LoginID is in AssigneeID list or is MainAssigneeID
        DECLARE @EmployeeID VARCHAR(40);
        SELECT @EmployeeID = EmployeeID FROM tblSC_Login WHERE LoginID = @LoginID;

        IF NOT EXISTS (
            SELECT 1
            WHERE @EmployeeID = @MainAssigneeID
            OR @EmployeeID IN (SELECT value FROM STRING_SPLIT(@AssigneeID, ','))
        )
        BEGIN
            SELECT 'ERROR' AS Status, N'Bạn không có quyền khiếu nại công việc này' AS Message;
            RETURN;
        END

        -- Check if there is already a pending complaint
        IF EXISTS (
            SELECT 1 FROM tblTask_Complaints
            WHERE HistoryID = @HistoryID AND Approve_Status = 1
        )
        BEGIN
            SELECT 'ERROR' AS Status, N'Đơn khiếu nại cho công việc này đang chờ xử lý' AS Message;
            RETURN;
        END

        -- Decode Base64 ComplaintReason to HTML
        DECLARE @ActualHTML NVARCHAR(MAX);

        /* --- GIẢI MÃ BASE64 --- */
        /* Logic: Client gửi Base64 của UTF-16LE.
        XML convert trả về VARBINARY (chính là byte UTF-16LE).
        CAST(VARBINARY AS NVARCHAR) sẽ hiển thị đúng tiếng Việt. */
        BEGIN TRY
            IF @ComplaintReason IS NULL OR @ComplaintReason = ''
                SET @ActualHTML = N'';
            ELSE IF @ComplaintReason LIKE 'PHNjcmlwdA%' OR @ComplaintReason LIKE '<%' -- Nếu có vẻ là HTML thô hoặc script
                SET @ActualHTML = @ComplaintReason;
            ELSE
                SET @ActualHTML = CAST(
                    CAST(N'' AS XML).value('xs:base64Binary(sql:variable("@ComplaintReason"))', 'VARBINARY(MAX)')
                    AS NVARCHAR(MAX)
                );
        END TRY
        BEGIN CATCH
            SET @ActualHTML = @ComplaintReason;
        END CATCH

        -- Create complaint record
        DECLARE @NewComplaintID INT;
        INSERT INTO tblTask_Complaints (HistoryID, TaskID, OldDueDate, ProposedDueDate, ComplaintReason, Approve_Status, CreatedBy, CreatedDate, ComplaintType)
        VALUES (@HistoryID, @TaskID, @OldDueDate, @ProposedDueDate, @ActualHTML, 1, @EmployeeID, GETDATE(), @ComplaintType);

        SET @NewComplaintID = SCOPE_IDENTITY();

        -- Reset approval stages in tblTask_Approvals to Pending (0) if this is a deadline extension (Type 1)
        -- to allow the approval flow to start fresh from Stage 1.
        IF @ComplaintType = 1
        BEGIN
            UPDATE tblTask_Approvals
            SET ApprovalStatus = 0,
                Note = NULL,
                dDate = NULL
            WHERE HistoryID = @HistoryID;
        END

        update tblFileRequest set IdentityID = 'ComplaintForm' + CAST(@NewComplaintID AS VARCHAR(30)) where IdentityID =  @TempComplaintID;

        -- Log to task comments
        DECLARE @EmployeeName NVARCHAR(MAX);
        SELECT @EmployeeName = FullName FROM tblEmployee WHERE EmployeeID = @EmployeeID;

        DECLARE @LogComment NVARCHAR(MAX);
        IF @ComplaintType = 2
        BEGIN
            SET @LogComment = N'Gửi khiếu nại từ chối công việc: ' + @EmployeeName +
                            N'. Lý do: ' + @ActualHTML;
        END
        ELSE
        BEGIN
            SET @LogComment = N'Gửi khiếu nại gia hạn deadline: ' + @EmployeeName +
                            N'. Lý do: ' + @ActualHTML +
                            N'. Hạn chót đề xuất: ' + ISNULL(FORMAT(@ProposedDueDate, 'dd/MM/yyyy HH:mm'), N'');
        END

        INSERT INTO tblTask_Comments (HistoryID, LoginID, Comment, dDate)
        VALUES (@HistoryID, @LoginID, @LogComment, GETDATE());

        -- Notify the approver who rejected the task, or the requester
        INSERT INTO tblEmailList (TemplateName, SendStatus, Approved_Send, Identity_Id, SendToEmployeeID, EmailType, NotifycationSendID)
        SELECT DISTINCT 'sp_Task_NotiComplaint', 0, 1, CAST(@HistoryID AS VARCHAR(36)), RecipientID, 10, 3
        FROM (
            SELECT TOP 1 ApproverID AS RecipientID
            FROM tblTask_Approvals
            WHERE HistoryID = @HistoryID AND ApprovalStatus = 2
            ORDER BY dDate DESC
            UNION
            SELECT RequestID FROM tblTask_Tasks WHERE HistoryID = @HistoryID
        ) t WHERE RecipientID IS NOT NULL AND RecipientID <> '';

        BEGIN TRY EXEC dbo.sp_Task_SignalR_Detail_Update @HistoryID = @HistoryID, @LoginID = @LoginID; END TRY BEGIN CATCH END CATCH

        SELECT 'SUCCESS' AS Status, N'Gửi đơn khiếu nại thành công' AS Message, @NewComplaintID AS ComplaintID;
    END
GO
PRINT N'[OK] Created procedure sp_Task_Complaint_Submit';
GO

IF OBJECT_ID('dbo.sp_Task_Complaint_Resolve', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Task_Complaint_Resolve;
GO

    CREATE   PROCEDURE [dbo].[sp_Task_Complaint_Resolve] (
        @ComplaintID INT,
        @LoginID INT,
        @ApprovedStatus INT, -- 2 = Approved (Đồng ý), 3 = Rejected (Từ chối), 4 = Cancelled (Hủy thành công), 5 = Cancellation Request (Xin hủy đăng ký)
        @ReviewNote NVARCHAR(MAX),
        @FinalDueDate DATETIME = NULL -- Optional override of the proposed due date
    )
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @HistoryID INT;
        DECLARE @ProposedDueDate DATETIME;
        DECLARE @TaskID INT;
        DECLARE @ComplaintType INT;
        DECLARE @CurrentApproveStatus INT;

        SELECT @HistoryID = HistoryID, @ProposedDueDate = ProposedDueDate, @TaskID = TaskID,
            @ComplaintType = ComplaintType, @CurrentApproveStatus = Approve_Status
        FROM tblTask_Complaints
        WHERE ComplaintID = @ComplaintID AND Approve_Status IN (1, 5);

        IF @HistoryID IS NULL
        BEGIN
            SELECT 'ERROR' AS Status, N'Đơn khiếu nại không tồn tại hoặc đã được xử lý' AS Message;
            RETURN;
        END

        DECLARE @ResolvedDueDate DATETIME = ISNULL(@FinalDueDate, @ProposedDueDate);

        DECLARE @ApprovedByEmployeeID VARCHAR(30);
        SELECT @ApprovedByEmployeeID = EmployeeID FROM tblSC_Login WHERE LoginID = @LoginID;

        -- Xử lý đặc biệt cho yêu cầu hủy (status 5)
        DECLARE @FinalApproveStatus INT = @ApprovedStatus;
        IF @CurrentApproveStatus = 5
        BEGIN
            IF @ApprovedStatus = 2
                SET @FinalApproveStatus = 4;  -- Phê duyệt hủy → Hủy thành công
            ELSE IF @ApprovedStatus = 3
                SET @FinalApproveStatus = 2;  -- Từ chối hủy → quay về Đã duyệt
        END

        -- Ánh xạ: Complaint status → Stage status
        -- Complaint: 1=Pending, 2=Approved, 3=Rejected, 4=Cancelled, 5=CancelRequest
        -- Stage:     0=Pending, 1=Approved, 2=Rejected, 4=Cancelled, 5=CancelRequest
        DECLARE @StageNewStatus INT = CASE
            WHEN @FinalApproveStatus = 2 THEN 1
            WHEN @FinalApproveStatus = 3 THEN 2
            WHEN @FinalApproveStatus = 4 THEN 4
            WHEN @FinalApproveStatus = 5 THEN 5
            ELSE 0
        END;

        -- Bước 1: Cập nhật stage hiện tại của approver trong tblTask_Approvals
        -- Với khiếu nại type 2 (từ chối): cập nhật cả stage đang bị rejected (stage ApprovalStatus=2)
        UPDATE tblTask_Approvals
        SET ApprovalStatus = @StageNewStatus,
            Note = @ReviewNote,
            dDate = GETDATE()
        WHERE HistoryID = @HistoryID
        AND ApproverID = @ApprovedByEmployeeID
        AND (
            ApprovalStatus = 0  -- Stage đang chờ duyệt
            OR (@ComplaintType = 2 AND ApprovalStatus = 2)  -- Type 2: người đã từ chối duyệt lại (chấp nhận cả duyệt và từ chối khiếu nại)
        );

        -- Bước 2: Kiểm tra còn stage nào đang chờ không (chỉ khi action là Duyệt)
        DECLARE @ComplaintNewStatus INT = @FinalApproveStatus;

        IF @FinalApproveStatus = 2  -- Action là Duyệt
        BEGIN
            DECLARE @PendingStageCount INT;
            SELECT @PendingStageCount = COUNT(*)
            FROM tblTask_Approvals
            WHERE HistoryID = @HistoryID AND ApprovalStatus = 0;

            IF @PendingStageCount > 0
                SET @ComplaintNewStatus = 1;  -- Vẫn còn stage chưa duyệt → đơn tiếp tục Pending
            -- else: @ComplaintNewStatus = 2 → tất cả đã duyệt → Finalize
        END

        -- Bước 3: Cập nhật trạng thái đơn khiếu nại
        -- Chỉ ghi ApprovedBy/Date/Note khi đơn được finalize (không còn pending)
        UPDATE tblTask_Complaints
        SET Approve_Status    = @ComplaintNewStatus,
            ApprovedBy        = CASE WHEN @ComplaintNewStatus <> 1 THEN @ApprovedByEmployeeID ELSE ApprovedBy    END,
            ApprovedDate      = CASE WHEN @ComplaintNewStatus <> 1 THEN GETDATE()              ELSE ApprovedDate   END,
            ApprovalNote      = CASE WHEN @ComplaintNewStatus <> 1 THEN @ReviewNote            ELSE ApprovalNote   END,
            ProposedDueDate   = CASE WHEN @ComplaintNewStatus = 2  THEN @ResolvedDueDate       ELSE ProposedDueDate END
        WHERE ComplaintID = @ComplaintID;

        DECLARE @ReviewerName NVARCHAR(MAX);
        SELECT @ReviewerName = e.FullName
        FROM tblEmployee e JOIN tblSC_Login l ON e.EmployeeID = l.EmployeeID
        WHERE l.LoginID = @LoginID;

        DECLARE @LogComment NVARCHAR(MAX);

        -- Bước 4: Ghi log và thông báo
        IF @ComplaintNewStatus = 1  -- Duyệt trung gian — vẫn còn stage chưa duyệt
        BEGIN
            SET @LogComment = N'Duyệt trung gian bởi: ' + @ReviewerName +
                            ISNULL(N'. Ý kiến: ' + @ReviewNote, N'') +
                            N'. Đang chờ cấp duyệt tiếp theo.';
            INSERT INTO tblTask_Comments (HistoryID, LoginID, Comment, dDate)
            VALUES (@HistoryID, @LoginID, @LogComment, GETDATE());

            -- Thông báo cho người duyệt tiếp theo (StageOrder thấp nhất còn pending)
            INSERT INTO tblEmailList (TemplateName, SendStatus, Approved_Send, Identity_Id, SendToEmployeeID, EmailType, NotifycationSendID)
            SELECT DISTINCT N'sp_Task_NotiComplaint', 0, 1, CAST(@HistoryID AS VARCHAR(36)), app.ApproverID, 10, 3
            FROM tblTask_Approvals app
            WHERE app.HistoryID = @HistoryID
            AND app.ApprovalStatus = 0
            AND app.StageOrder = (
                SELECT MIN(a2.StageOrder)
                FROM tblTask_Approvals a2
                WHERE a2.HistoryID = @HistoryID AND a2.ApprovalStatus = 0
            );
        END
        ELSE
        BEGIN
            -- Finalized: xử lý xác nhận hủy, duyệt, từ chối
            IF @CurrentApproveStatus = 5
            BEGIN
                IF @FinalApproveStatus = 4
                BEGIN
                    SET @LogComment = CASE WHEN @ComplaintType = 2
                        THEN N'Phê duyệt hủy đơn từ chối công việc: '
                        ELSE N'Phê duyệt hủy đơn gia hạn deadline: ' END +
                        @ReviewerName + ISNULL(N'. Ý kiến: ' + @ReviewNote, N'');
                END
                ELSE IF @FinalApproveStatus = 2
                BEGIN
                    SET @LogComment = CASE WHEN @ComplaintType = 2
                        THEN N'Từ chối hủy đơn từ chối công việc: '
                        ELSE N'Từ chối hủy đơn gia hạn deadline: ' END +
                        @ReviewerName + ISNULL(N'. Lý do: ' + @ReviewNote, N'');
                END

                INSERT INTO tblTask_Comments (HistoryID, LoginID, Comment, dDate)
                VALUES (@HistoryID, @LoginID, @LogComment, GETDATE());
            END
            ELSE
            BEGIN
                -- Duyệt hoàn toàn hoặc Từ chối
                IF @FinalApproveStatus = 2  -- Đã duyệt toàn bộ
                BEGIN
                    IF @ComplaintType = 2
                    BEGIN
                        -- Khiếu nại từ chối được duyệt → cập nhật task thành Hoàn thành (StatusID = 4)
                        UPDATE tblTask_Tasks SET StatusID = 4, ModifiedDate = GETDATE() WHERE HistoryID = @HistoryID;
                        SET @LogComment = N'Phê duyệt khiếu nại từ chối công việc: ' + @ReviewerName +
                                        ISNULL(N'. Ý kiến: ' + @ReviewNote, N'');
                    END
                    ELSE
                    BEGIN
                        -- Gia hạn được duyệt → cập nhật deadline của task
                        UPDATE tblTask_Tasks SET DueDate = @ResolvedDueDate, ModifiedDate = GETDATE() WHERE HistoryID = @HistoryID;
                        SET @LogComment = N'Phê duyệt khiếu nại gia hạn deadline: ' + @ReviewerName +
                                        N'. Gia hạn deadline đến: ' + FORMAT(@ResolvedDueDate, 'dd/MM/yyyy HH:mm') +
                                        ISNULL(N'. Ý kiến: ' + @ReviewNote, N'');
                    END
                END
                ELSE  -- Từ chối
                BEGIN
                    SET @LogComment = CASE WHEN @ComplaintType = 2
                        THEN N'Từ chối khiếu nại từ chối công việc: '
                        ELSE N'Từ chối khiếu nại gia hạn deadline: ' END +
                        @ReviewerName + ISNULL(N'. Lý do: ' + @ReviewNote, N'');
                END

                INSERT INTO tblTask_Comments (HistoryID, LoginID, Comment, dDate)
                VALUES (@HistoryID, @LoginID, @LogComment, GETDATE());
            END

            -- Thông báo cho người được giao việc khi đơn được finalize
            INSERT INTO tblEmailList (TemplateName, SendStatus, Approved_Send, Identity_Id, SendToEmployeeID, EmailType, NotifycationSendID)
            SELECT DISTINCT N'sp_Task_NotiComplaintResult', 0, 1, CAST(@HistoryID AS VARCHAR(36)), RecipientID, 10, 3
            FROM (
                SELECT value AS RecipientID FROM STRING_SPLIT((SELECT AssigneeID FROM tblTask_Tasks WHERE HistoryID = @HistoryID), ',')
                UNION
                SELECT MainAssigneeID FROM tblTask_Tasks WHERE HistoryID = @HistoryID
            ) t WHERE RecipientID IS NOT NULL AND RecipientID <> '';
        END

        BEGIN TRY EXEC dbo.sp_Task_SignalR_Detail_Update @HistoryID = @HistoryID, @LoginID = @LoginID; END TRY BEGIN CATCH END CATCH

        SELECT 'SUCCESS' AS Status,
            CASE
                WHEN @ComplaintNewStatus = 1 THEN N'Đã duyệt - đang chờ cấp duyệt tiếp theo!'
                WHEN @FinalApproveStatus = 2 THEN N'Đã phê duyệt khiếu nại thành công!'
                ELSE N'Đã từ chối đơn khiếu nại!'
            END AS Message;
    END
GO
PRINT N'[OK] Created procedure sp_Task_Complaint_Resolve';
GO

IF OBJECT_ID('dbo.sp_Task_Complaint_GetDetail', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Task_Complaint_GetDetail;
GO

    CREATE   PROCEDURE [dbo].[sp_Task_Complaint_GetDetail] (
        @HistoryID INT = NULL,
        @ComplaintID INT = NULL,
        @ComplaintType INT = 1,
        @LoginID INT = NULL
    )
    AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @EmployeeID VARCHAR(40);
        DECLARE @IdentityID VARCHAR(36);
        SELECT @EmployeeID = EmployeeID FROM tblSC_Login WHERE LoginID = @LoginID;

        IF @ComplaintID IS NOT NULL
        BEGIN
            -- Result Set 1: Complaint Details
            SELECT
                'view' AS [Mode],
                c.ComplaintID,
                c.HistoryID,
                c.TaskID,
                tk.TaskName,
                t.Description AS TaskDescription,
                t.AssigneeID,
                e_main.FullName AS MainAssigneeName,
                e_req.FullName AS RequesterName,
                CONVERT(VARCHAR(25), ISNULL(c.OldDueDate, t.DueDate), 126) AS OldDueDate,
                CONVERT(VARCHAR(25), c.ProposedDueDate, 126) AS ProposedDueDate,
                c.ComplaintReason,
                c.Approve_Status,
                e_creator.FullName AS CreatorName,
                CONVERT(VARCHAR(25), c.CreatedDate, 126) AS CreatedDate,
                e_approver.FullName AS ApproverName,
                CONVERT(VARCHAR(25), c.ApprovedDate, 126) AS ApprovedDate,
                c.ApprovalNote,
                c.ComplaintType,
                c.CreatedBy,
                (SELECT TOP 1 LoginID FROM tblSC_Login WHERE EmployeeID = c.CreatedBy) AS CreatorLoginID,
                @EmployeeID AS CurrentEmployeeID,
                ISNULL((
                    SELECT TOP 1 Note
                    FROM tblTask_Approvals
                    WHERE HistoryID = c.HistoryID AND ApprovalStatus = 2
                    ORDER BY dDate DESC
                ), N'Không có nội dung lý do cụ thể.') AS RejectionNote,
                CAST(
                    CASE
                        WHEN c.Approve_Status NOT IN (1, 5) THEN 0
                        WHEN c.CreatedBy = @EmployeeID THEN 0
                        WHEN c.ComplaintType != 2 AND EXISTS (
                            SELECT 1
                            FROM tblTask_Approvals app
                            WHERE app.HistoryID = c.HistoryID
                            AND app.ApprovalStatus = 0
                            AND app.ApproverID = @EmployeeID
                            AND app.StageOrder = (
                                SELECT MIN(a2.StageOrder)
                                FROM tblTask_Approvals a2
                                WHERE a2.HistoryID = c.HistoryID AND a2.ApprovalStatus = 0
                            )
                        ) THEN 1
                        WHEN c.ComplaintType = 2 AND EXISTS (
                            SELECT 1
                            FROM tblTask_Approvals app
                            WHERE app.HistoryID = c.HistoryID
                            AND app.ApprovalStatus = 2
                            AND app.ApproverID = @EmployeeID
                        ) THEN 1
                        ELSE 0
                    END AS INT
                ) AS CanApprove,
                (
                    SELECT
                        a.ApprovalID,
                        a.HistoryID,
                        a.ApproverID,
                        emp.EmployeeID,
                        emp.FullName  AS ApproverName,
                        a.ApprovalStatus,
                        a.StageOrder,
                        a.Note,
                        dbo.fn_GetStringParamImageByEmployeeID(a.ApproverID) AS paramImg,
                        'paradisefile_sp_GetFileAPI' AS storeImgName
                    FROM tblTask_Approvals a
                    LEFT JOIN tblEmployee emp ON emp.EmployeeID = a.ApproverID
                    WHERE a.HistoryID = c.HistoryID
                    ORDER BY a.StageOrder
                    FOR JSON PATH
                ) AS ApprovalStages
            FROM tblTask_Complaints c
            JOIN tblTask_Tasks t ON c.HistoryID = t.HistoryID
            JOIN tblTasks tk ON t.TaskID = tk.TaskID
            LEFT JOIN tblEmployee e_main ON t.MainAssigneeID = e_main.EmployeeID
            LEFT JOIN tblEmployee e_req ON t.RequestID = e_req.EmployeeID
            LEFT JOIN tblEmployee e_creator ON c.CreatedBy = e_creator.EmployeeID
            LEFT JOIN tblEmployee e_approver ON c.ApprovedBy = e_approver.EmployeeID
            WHERE c.ComplaintID = @ComplaintID;

            -- Result Set 2: Files associated with this complaint
            SELECT @IdentityID = 'ComplaintForm' + CAST(HistoryID AS NVARCHAR(50))
            FROM tblTask_Complaints
            WHERE ComplaintID = @ComplaintID;

            EXEC sp_GetFile @LoginID = @LoginID, @IdentityID = @IdentityID;
        END
        ELSE IF @HistoryID IS NOT NULL
        BEGIN
            -- Result Set 1: Complaint Details
            SELECT
                'submit' AS [Mode],
                CAST(NULL AS INT) AS ComplaintID,
                t.HistoryID,
                t.TaskID,
                tk.TaskName,
                t.Description AS TaskDescription,
                t.AssigneeID,
                e_main.FullName AS MainAssigneeName,
                e_req.FullName AS RequesterName,
                CONVERT(VARCHAR(25), t.DueDate, 126) AS OldDueDate,
                CAST(NULL AS VARCHAR(25)) AS ProposedDueDate,
                CAST(NULL AS NVARCHAR(MAX)) AS ComplaintReason,
                1 AS Approve_Status,
                CAST(NULL AS NVARCHAR(MAX)) AS CreatorName,
                CAST(NULL AS VARCHAR(25)) AS CreatedDate,
                CAST(NULL AS NVARCHAR(MAX)) AS ApproverName,
                CAST(NULL AS VARCHAR(25)) AS ApprovedDate,
                CAST(NULL AS NVARCHAR(MAX)) AS ApprovalNote,
                @ComplaintType AS ComplaintType,
                CAST(NULL AS VARCHAR(30)) AS CreatedBy,
                CAST(NULL AS INT) AS CreatorLoginID,
                @EmployeeID AS CurrentEmployeeID,
                ISNULL((
                    SELECT TOP 1 Note
                    FROM tblTask_Approvals
                    WHERE HistoryID = t.HistoryID AND ApprovalStatus = 2
                    ORDER BY dDate DESC
                ), N'Không có nội dung lý do cụ thể.') AS RejectionNote,
                0 AS CanApprove,
                (
                    SELECT
                        a.ApprovalID,
                        a.HistoryID,
                        a.ApproverID,
                        emp.EmployeeID,
                        emp.FullName  AS ApproverName,
                        a.ApprovalStatus,
                        a.StageOrder,
                        a.Note,
                        dbo.fn_GetStringParamImageByEmployeeID(a.ApproverID) AS paramImg,
                        'paradisefile_sp_GetFileAPI' AS storeImgName
                    FROM tblTask_Approvals a
                    LEFT JOIN tblEmployee emp ON emp.EmployeeID = a.ApproverID
                    WHERE a.HistoryID = t.HistoryID
                    ORDER BY a.StageOrder
                    FOR JSON PATH
                ) AS ApprovalStages
            FROM tblTask_Tasks t
            JOIN tblTasks tk ON t.TaskID = tk.TaskID
            LEFT JOIN tblEmployee e_main ON t.MainAssigneeID = e_main.EmployeeID
            LEFT JOIN tblEmployee e_req ON t.RequestID = e_req.EmployeeID
            WHERE t.HistoryID = @HistoryID;

            -- Result Set 2: Files associated with this HistoryID
            SET @IdentityID = 'ComplaintForm' + CAST(@HistoryID AS NVARCHAR(50));
            EXEC sp_GetFile @LoginID = @LoginID, @IdentityID = @IdentityID;
        END
    END
GO
PRINT N'[OK] Created procedure sp_Task_Complaint_GetDetail';
GO

IF OBJECT_ID('dbo.sp_Task_Complaint_GetDataList', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Task_Complaint_GetDataList;
GO

    CREATE   PROCEDURE [dbo].[sp_Task_Complaint_GetDataList] (
        @LoginID INT = NULL,
        @LanguageID VARCHAR(2) = 'VN',
        @StatusFilter INT = -1
    )
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @EmployeeID VARCHAR(40);
        SELECT @EmployeeID = EmployeeID FROM tblSC_Login WHERE LoginID = @LoginID;

        -- Temporary table to hold list of managed employee IDs (for hierarchy permission check)
        CREATE TABLE #tmpEmployeeList (EmployeeID VARCHAR(30));
        INSERT INTO #tmpEmployeeList EXEC sp_getEmployeeListWithPermission @LoginID, 0;

        SELECT
            c.ComplaintID,
            c.HistoryID,
            c.TaskID,
            tk.TaskName,
            t.Description AS TaskDescription,
            t.AssigneeID,
            e_main.FullName AS MainAssigneeName,
            e_req.FullName AS RequesterName,
            ISNULL(c.OldDueDate, t.DueDate) AS OldDueDate,
            c.ProposedDueDate,
            c.ComplaintReason,
            c.Approve_Status,
            s.Description AS StatusName,
            s.Color AS StatusColor,
            e_creator.FullName AS CreatorName,
            c.CreatedDate,
            e_approver.FullName AS ApproverName,
            c.ApprovedDate,
            c.ApprovalNote,
            c.ComplaintType,
            c.CreatedBy,
            (SELECT TOP 1 LoginID FROM tblSC_Login WHERE EmployeeID = c.CreatedBy) AS CreatorLoginID,
            @EmployeeID AS CurrentEmployeeID,
            -- Get the last rejection note from tblTask_Approvals
            ISNULL((
                SELECT TOP 1 Note
                FROM tblTask_Approvals
                WHERE HistoryID = c.HistoryID AND ApprovalStatus = 2
                ORDER BY dDate DESC
            ), N'Không có nội dung lý do cụ thể.') AS RejectionNote,
            -- Compute CanApprove dynamically based on sp_Task_TaskDetail permissions
            CAST(
                CASE
                    WHEN c.Approve_Status NOT IN (1, 5) THEN 0
                    WHEN c.CreatedBy = @EmployeeID THEN 0
                    -- Gia hạn (type 1) và các loại khác: duyệt tuần tự —
                    -- chỉ approver ở StageOrder thấp nhất còn pending mới được duyệt
                    WHEN c.ComplaintType != 2 AND EXISTS (
                        SELECT 1
                        FROM tblTask_Approvals app
                        WHERE app.HistoryID = c.HistoryID
                        AND app.ApprovalStatus = 0
                        AND app.ApproverID = @EmployeeID
                        AND app.StageOrder = (
                            SELECT MIN(a2.StageOrder)
                            FROM tblTask_Approvals a2
                            WHERE a2.HistoryID = c.HistoryID AND a2.ApprovalStatus = 0
                        )
                    ) THEN 1
                    -- Khiếu nại từ chối (type 2): người đã từ chối có quyền duyệt lại
                    WHEN c.ComplaintType = 2 AND EXISTS (
                        SELECT 1
                        FROM tblTask_Approvals app
                        WHERE app.HistoryID = c.HistoryID
                        AND app.ApprovalStatus = 2
                        AND app.ApproverID = @EmployeeID
                    ) THEN 1
                    -- Không có stage nào → task requester duyệt
                    WHEN t.RequestID = @EmployeeID
                        AND NOT EXISTS (SELECT 1 FROM tblTask_Approvals WHERE HistoryID = c.HistoryID) THEN 1
                    ELSE 0
                END AS INT
            ) AS CanApprove,
            -- Get task approval stages JSON for rendering the approval chain
            (
                SELECT
                    a.ApprovalID,
                    a.HistoryID,
                    a.ApproverID,
                    emp.EmployeeID,
                    emp.FullName  AS ApproverName,
                    a.ApprovalStatus,
                    a.StageOrder,
                    a.Note,
                    dbo.fn_GetStringParamImageByEmployeeID(a.ApproverID) AS paramImg,
                    'paradisefile_sp_GetFileAPI' AS storeImgName
                FROM tblTask_Approvals a
                LEFT JOIN tblEmployee emp ON emp.EmployeeID = a.ApproverID
                WHERE a.HistoryID = c.HistoryID
                ORDER BY a.StageOrder
                FOR JSON PATH
            ) AS ApprovalStages
        FROM tblTask_Complaints c
        JOIN tblTask_Tasks t ON c.HistoryID = t.HistoryID
        JOIN tblTasks tk ON t.TaskID = tk.TaskID
        LEFT JOIN tblEmployee e_main ON t.MainAssigneeID = e_main.EmployeeID
        LEFT JOIN tblEmployee e_req ON t.RequestID = e_req.EmployeeID
        LEFT JOIN tblEmployee e_creator ON c.CreatedBy = e_creator.EmployeeID
        LEFT JOIN tblEmployee e_approver ON c.ApprovedBy = e_approver.EmployeeID
        LEFT JOIN tblApproveStatus s ON c.Approve_Status = s.Approve_Status
        WHERE
            (@StatusFilter = -1 OR c.Approve_Status = @StatusFilter)
            AND (
                c.CreatedBy = @EmployeeID
                OR c.CreatedBy IN (SELECT EmployeeID FROM #tmpEmployeeList)
                OR t.RequestID = @EmployeeID
                OR EXISTS (
                    SELECT 1 FROM tblTask_Approvals app
                    WHERE app.HistoryID = c.HistoryID AND app.ApproverID = @EmployeeID
                )
            )
        ORDER BY c.CreatedDate DESC;

        DROP TABLE #tmpEmployeeList;
    END
GO
PRINT N'[OK] Created procedure sp_Task_Complaint_GetDataList';
GO

-- ============================================================================
-- PHASE 5a: Renderer sp_Task_GetComplaintList_html (HTML list view)
-- ============================================================================

IF OBJECT_ID('dbo.sp_Task_GetComplaintList_html', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Task_GetComplaintList_html;
GO

-- 6. Stored Procedure sp_Task_GetComplaintList_html (returns the raw HTML content)
CREATE   PROCEDURE [dbo].[sp_Task_GetComplaintList_html](
    @LanguageID varchar(10) = 'VN'
)
AS
BEGIN
    DECLARE @html nvarchar(max) = N'
<div id="sp_Task_GetComplaintList_html">
  <style>
    /* ===== SYSTEM STYLING INTEGRATION ===== */
    #sp_Task_GetComplaintList_html {
      font-family: inherit;
      color: var(--paradise-fg-0);
      min-height: 100vh;
      padding: var(--paradise-space-5);
      box-sizing: border-box;
      position: relative;
    }

    #sp_Task_GetComplaintList_html * {
      box-sizing: border-box;
    }

    /* ===== STATS CARDS ===== */
    #sp_Task_GetComplaintList_html .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: var(--paradise-space-4);
      margin-bottom: var(--paradise-space-5);
    }

    #sp_Task_GetComplaintList_html .stat-card {
      background-color: var(--paradise-bg-1);
      border: 1px solid var(--paradise-border-color);
      border-radius: var(--paradise-border-radius-xl);
      padding: 20px;
      display: flex;
      align-items: center;
      gap: var(--paradise-space-4);
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }

    #sp_Task_GetComplaintList_html .stat-card:hover {
      transform: translateY(-4px);
      box-shadow: var(--paradise-shadow-md);
      border-color: var(--paradise-color-primary);
    }

    #sp_Task_GetComplaintList_html .stat-icon {
      width: 48px;
      height: 48px;
      border-radius: var(--paradise-border-radius-xl);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 20px;
      flex-shrink: 0;
    }

    #sp_Task_GetComplaintList_html .stat-icon.total {
      background-color: var(--paradise-bg-primary-subtle);
      color: var(--paradise-color-primary);
    }

    #sp_Task_GetComplaintList_html .stat-icon.pending {
      background-color: var(--paradise-bg-warning-subtle);
      color: var(--paradise-color-warning);
    }

    #sp_Task_GetComplaintList_html .stat-icon.approved {
      background-color: var(--paradise-bg-success-subtle);
      color: var(--paradise-color-success);
    }

    #sp_Task_GetComplaintList_html .stat-icon.rejected {
      background-color: var(--paradise-bg-danger-subtle);
      color: var(--paradise-color-danger);
    }

    #sp_Task_GetComplaintList_html .stat-info {
      display: flex;
      flex-direction: column;
    }

    #sp_Task_GetComplaintList_html .stat-lbl {
      font-size: 12px;
      font-weight: var(--font-weight-semi-bold);
      color: var(--paradise-fg-2);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      margin-bottom: 4px;
    }

    #sp_Task_GetComplaintList_html .stat-val {
      font-family: inherit;
      font-size: 24px;
      font-weight: var(--font-weight-bold);
      color: var(--paradise-fg-0);
      line-height: 1;
    }

    /* ===== FILTER BAR ===== */
    #sp_Task_GetComplaintList_html .filter-bar {
      background-color: var(--paradise-bg-1);
      backdrop-filter: blur(12px);
      border: 1px solid var(--paradise-border-color);
      border-radius: var(--paradise-border-radius-xl);
      padding: 16px;
      margin-bottom: var(--paradise-space-5);
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      align-items: center;
      gap: var(--paradise-space-4);
    }

    #sp_Task_GetComplaintList_html .status-tabs {
      display: flex;
      background-color: var(--paradise-bg-2);
      padding: 4px;
      border-radius: var(--paradise-border-radius-pill);
      gap: 2px;
    }



    #sp_Task_GetComplaintList_html .tab-item {
      border: none;
      background-color: transparent;
      padding: 8px 18px;
      border-radius: var(--paradise-border-radius-pill);
      font-size: 13px;
      font-weight: var(--font-weight-semi-bold);
      color: var(--paradise-fg-2);
      cursor: pointer;
      transition: all 0.2s ease;
      white-space: nowrap;
    }

    #sp_Task_GetComplaintList_html .tab-item.active {
      background-color: var(--paradise-bg-1);
      color: var(--paradise-fg-0);
      box-shadow: var(--paradise-shadow-sm);
    }



    #sp_Task_GetComplaintList_html .search-wrapper {
      position: relative;
      flex: 1;
      max-width: 360px;
      min-width: 240px;
    }

    #sp_Task_GetComplaintList_html .search-input {
      width: 100%;
      padding: 10px 16px 10px 42px;
      font-size: 13.5px;
      border-radius: var(--paradise-border-radius-pill);
      border: 1px solid var(--paradise-border-color);
      background-color: var(--paradise-bg-1);
      color: var(--paradise-fg-0);
      outline: none;
      transition: all 0.2s;
    }



    #sp_Task_GetComplaintList_html .search-input:focus {
      border-color: var(--paradise-color-primary);
      background-color: var(--paradise-bg-1);
      box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
    }

    #sp_Task_GetComplaintList_html .search-icon {
      position: absolute;
      left: 16px;
      top: 50%;
      transform: translateY(-50%);
      color: var(--paradise-fg-2);
      font-size: 14px;
      pointer-events: none;
    }

    /* ===== COMPLAINTS LIST / CARDS ===== */
    #sp_Task_GetComplaintList_html .complaints-container {
      display: grid;
      grid-template-columns: 1fr;
      gap: var(--paradise-space-3);
      margin-bottom: var(--paradise-space-5);
    }

    #sp_Task_GetComplaintList_html .complaint-card {
      background-color: var(--paradise-bg-1);
      backdrop-filter: blur(12px);
      border: 1px solid var(--paradise-border-color);
      border-radius: var(--paradise-border-radius-xl);
      padding: 16px 20px;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      position: relative;
      overflow: hidden;
    }

    #sp_Task_GetComplaintList_html .complaint-card:hover {
      transform: translateY(-2px);
    }

    /* Status indicator strip on the left */
    #sp_Task_GetComplaintList_html .status-strip {
      position: absolute;
      left: 0;
      top: 0;
      bottom: 0;
      width: 6px;
    }

    #sp_Task_GetComplaintList_html .status-strip.pending {
      background-color: var(--paradise-color-warning);
    }

    #sp_Task_GetComplaintList_html .status-strip.approved {
      background-color: var(--paradise-color-success);
    }

    #sp_Task_GetComplaintList_html .status-strip.rejected {
      background-color: var(--paradise-color-danger);
    }

    #sp_Task_GetComplaintList_html .card-header-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: var(--paradise-space-3);
      flex-wrap: wrap;
      gap: var(--paradise-space-3);
    }

    #sp_Task_GetComplaintList_html .title-area {
      display: flex;
      align-items: center;
      gap: var(--paradise-space-2);
      flex-wrap: wrap;
    }

    #sp_Task_GetComplaintList_html .task-title-link {
      font-family: inherit;
      font-size: 17px;
      font-weight: var(--font-weight-bold);
      color: var(--paradise-color-primary);
      text-decoration: none;
      transition: color 0.2s;
      line-height: 1.3;
    }

    #sp_Task_GetComplaintList_html .task-title-link:hover {
      color: rgba(0, 123, 255, 0.85);
      text-decoration: underline;
    }

    /* Type Badges */
    #sp_Task_GetComplaintList_html .type-badge {
      display: inline-flex;
      align-items: center;
      padding: 4px 8px;
      border-radius: var(--paradise-border-radius-sm);
      font-size: 11px;
      font-weight: var(--font-weight-bold);
      text-transform: uppercase;
      letter-spacing: 0.03em;
      border: 1px solid transparent;
    }

    #sp_Task_GetComplaintList_html .type-badge.extension {
      background-color: var(--paradise-bg-primary-subtle);
      color: var(--paradise-color-info);
      border-color: var(--paradise-color-info);
    }

    #sp_Task_GetComplaintList_html .type-badge.appeal {
      background-color: var(--paradise-bg-warning-subtle);
      color: var(--paradise-color-warning);
      border-color: var(--paradise-color-warning);
    }

    #sp_Task_GetComplaintList_html .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 6px 14px;
      border-radius: var(--paradise-border-radius-pill);
      font-size: 12px;
      font-weight: var(--font-weight-bold);
      text-transform: uppercase;
      letter-spacing: 0.03em;
    }

    #sp_Task_GetComplaintList_html .status-badge.pending {
      background-color: var(--paradise-bg-warning-subtle);
      color: var(--paradise-color-warning);
    }

    #sp_Task_GetComplaintList_html .status-badge.approved {
      background-color: var(--paradise-bg-success-subtle);
      color: var(--paradise-color-success);
    }

    #sp_Task_GetComplaintList_html .status-badge.rejected {
      background-color: var(--paradise-bg-danger-subtle);
      color: var(--paradise-color-danger);
    }

    /* Compact Meta Row */
    #sp_Task_GetComplaintList_html .meta-row {
      display: flex;
      flex-wrap: wrap;
      gap: var(--paradise-space-4);
      margin-bottom: 6px;
      font-size: 13px;
      color: var(--paradise-fg-2);
      align-items: center;
    }

    #sp_Task_GetComplaintList_html .meta-item {
      display: flex;
      align-items: center;
      gap: 6px;
    }

    /* Comparison timeline for due dates */
    #sp_Task_GetComplaintList_html .timeline-row {
      margin-bottom: var(--paradise-space-3);
    }

    #sp_Task_GetComplaintList_html .timeline-extension {
      background-color: var(--paradise-bg-2);
      border-radius: var(--paradise-border-radius-xl);
      padding: 6px 12px;
      display: inline-flex;
      align-items: center;
      gap: var(--paradise-space-2);
      font-size: 13px;
    }



    #sp_Task_GetComplaintList_html .date-val {
      font-weight: var(--font-weight-bold);
    }

    #sp_Task_GetComplaintList_html .date-val.old {
      color: var(--paradise-fg-2);
      text-decoration: line-through;
    }

    #sp_Task_GetComplaintList_html .date-val.new {
      color: var(--paradise-color-success);
    }

    /* Content Callout Blocks */
    #sp_Task_GetComplaintList_html .reason-section {
      margin-bottom: 4px;
    }

    #sp_Task_GetComplaintList_html .section-label {
      font-size: 11px;
      font-weight: var(--font-weight-bold);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--paradise-fg-2);
      margin-bottom: 4px;
      display: flex;
      align-items: center;
      gap: 4px;
    }

    #sp_Task_GetComplaintList_html .resolution-callout {
      background-color: var(--paradise-bg-success-subtle);
      border-left: 3px solid var(--paradise-color-success);
      padding: 8px 12px;
      border-radius: 0 8px 8px 0;
      font-size: 13px;
      line-height: 1.45;
    }

    /* Review Action Group in Header */
    #sp_Task_GetComplaintList_html .action-header-group {
      display: flex;
      align-items: center;
      gap: var(--paradise-space-2);
    }

    #sp_Task_GetComplaintList_html .btn-action-sm {
      border: none;
      padding: 6px 12px;
      border-radius: var(--paradise-border-radius-sm);
      font-size: 12px;
      font-weight: var(--font-weight-semi-bold);
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s;
    }

    #sp_Task_GetComplaintList_html .btn-action-sm.reject {
      background-color: var(--paradise-bg-danger-subtle);
      color: var(--paradise-color-danger);
    }

    #sp_Task_GetComplaintList_html .btn-action-sm.reject:hover {
      background-color: var(--paradise-color-danger);
      color: white;
      box-shadow: 0 4px 10px rgba(239, 68, 68, 0.2);
    }

    #sp_Task_GetComplaintList_html .btn-action-sm.approve {
      background-color: var(--paradise-bg-success-subtle);
      color: var(--paradise-color-success);
    }

    #sp_Task_GetComplaintList_html .btn-action-sm.approve:hover {
      background-color: var(--paradise-color-success);
      color: white;
      box-shadow: 0 4px 10px rgba(16, 185, 129, 0.2);
    }

    /* ===== MODERN GLASSMORPHIC MODAL ===== */
    #sp_Task_GetComplaintList_html .complaint-modal-overlay {
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(15, 23, 42, 0.5);
      backdrop-filter: blur(8px);
      z-index: 9999;
      display: none;
      align-items: center;
      justify-content: center;
      opacity: 0;
      transition: opacity 0.3s ease;
    }

    #sp_Task_GetComplaintList_html .complaint-modal {
      background-color: var(--paradise-bg-1);
      backdrop-filter: blur(20px);
      border: 1px solid var(--paradise-border-color);
      width: 90%;
      max-width: 500px;
      border-radius: var(--paradise-border-radius-xl);
      box-shadow: var(--paradise-shadow-xl);
      transform: scale(0.9);
      transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
      overflow: hidden;
    }

    #sp_Task_GetComplaintList_html .complaint-modal-overlay.active {
      display: flex;
      opacity: 1;
    }

    #sp_Task_GetComplaintList_html .complaint-modal-overlay.active .complaint-modal {
      transform: scale(1);
    }

    #sp_Task_GetComplaintList_html .modal-header {
      padding: 24px 24px 16px 24px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 1px solid var(--paradise-color-input-border, #e5e7ea);
    }

    #sp_Task_GetComplaintList_html .modal-title {
      font-family: inherit;
      font-size: 20px;
      font-weight: var(--font-weight-bold);
      color: var(--paradise-fg-0);
      margin: 0;
    }

    #sp_Task_GetComplaintList_html .modal-close {
      background-color: transparent;
      border: none;
      font-size: 20px;
      color: var(--paradise-fg-2);
      cursor: pointer;
      transition: color 0.2s;
    }

    #sp_Task_GetComplaintList_html .modal-close:hover {
      color: var(--paradise-color-danger);
    }

    #sp_Task_GetComplaintList_html .modal-body {
      padding: var(--paradise-space-5);
    }

    #sp_Task_GetComplaintList_html .form-group {
      margin-bottom: 18px;
    }

    #sp_Task_GetComplaintList_html .form-label {
      font-size: 13px;
      font-weight: var(--font-weight-bold);
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: var(--paradise-fg-2);
      margin-bottom: var(--paradise-space-2);
      display: block;
    }

    #sp_Task_GetComplaintList_html .form-textarea {
      width: 100%;
      height: 100px;
      padding: 12px;
      border-radius: var(--paradise-border-radius-xl);
      border: 1px solid var(--paradise-border-color);
      background-color: var(--paradise-bg-1);
      color: var(--paradise-fg-0);
      outline: none;
      resize: none;
      font-size: 14px;
      transition: border-color 0.2s;
    }



    #sp_Task_GetComplaintList_html .form-textarea:focus {
      border-color: var(--paradise-color-primary);
      box-shadow: 0 0 0 3px rgba(2, 132, 199, 0.15);
    }

    #sp_Task_GetComplaintList_html .form-input-date {
      width: 100%;
      padding: 10px 12px;
      border-radius: var(--paradise-border-radius-xl);
      border: 1px solid var(--paradise-border-color);
      background-color: var(--paradise-bg-1);
      color: var(--paradise-fg-0);
      outline: none;
      font-size: 14px;
    }



    #sp_Task_GetComplaintList_html .modal-footer {
      padding: 16px 24px 24px 24px;
      display: flex;
      justify-content: flex-end;
      gap: var(--paradise-space-3);
      border-top: 1px solid var(--paradise-color-input-border, #e5e7ea);
    }

    #sp_Task_GetComplaintList_html .btn-modal {
      border: none;
      padding: 10px 22px;
      border-radius: var(--paradise-border-radius-pill);
      font-size: 13.5px;
      font-weight: var(--font-weight-bold);
      cursor: pointer;
      transition: all 0.2s;
    }

    #sp_Task_GetComplaintList_html .btn-modal.cancel {
      background-color: transparent;
      color: var(--paradise-fg-2);
      border: 1px solid var(--paradise-border-color);
    }

    #sp_Task_GetComplaintList_html .btn-modal.cancel:hover {
      background-color: var(--paradise-bg-2);
      color: var(--paradise-fg-0);
    }

    #sp_Task_GetComplaintList_html .btn-modal.submit {
      background-color: var(--paradise-color-primary);
      color: white;
    }

    #sp_Task_GetComplaintList_html .btn-modal.submit:hover {
      background: rgba(0, 123, 255, 0.85);
      box-shadow: 0 4px 12px rgba(2, 132, 199, 0.25);
    }

    /* ===== EMPTY STATE ===== */
    #sp_Task_GetComplaintList_html .empty-state {
      background-color: var(--paradise-bg-1);
      backdrop-filter: blur(12px);
      border: 1px solid var(--paradise-border-color);
      border-radius: var(--paradise-border-radius-xl);
      padding: 50px 24px;
      text-align: center;
      box-shadow: var(--paradise-shadow-sm);
    }

    #sp_Task_GetComplaintList_html .empty-icon {
      font-size: 48px;
      color: var(--paradise-fg-2);
      margin-bottom: var(--paradise-space-4);
    }

    #sp_Task_GetComplaintList_html .empty-title {
      font-family: inherit;
      font-size: 18px;
      font-weight: var(--font-weight-bold);
      margin: 0 0 8px 0;
    }

    #sp_Task_GetComplaintList_html .empty-desc {
      font-size: 13.5px;
      color: var(--paradise-fg-2);
      margin: 0;
    }

    /* ===== PAGINATION ===== */
    #sp_Task_GetComplaintList_html .pagination-row {
      display: flex;
      justify-content: center;
      margin-top: 24px;
    }

    #sp_Task_GetComplaintList_html .page-btn {
      border: 1px solid var(--paradise-border-color);
      background-color: var(--paradise-bg-1);
      color: var(--paradise-fg-0);
      padding: 8px 16px;
      margin: 0 4px;
      border-radius: var(--paradise-border-radius-xl);
      font-size: 13px;
      font-weight: var(--font-weight-semi-bold);
      cursor: pointer;
      transition: all 0.2s;
    }

    #sp_Task_GetComplaintList_html .page-btn:hover:not(.disabled) {
      border-color: var(--paradise-color-primary);
      color: var(--paradise-color-primary);
    }

    #sp_Task_GetComplaintList_html .page-btn.active {
      background-color: var(--paradise-color-primary);
      color: white;
      border-color: var(--paradise-color-primary);
    }

    #sp_Task_GetComplaintList_html .page-btn.disabled {
      opacity: 0.5;
      cursor: default;
    }

    /* ===== APPROVAL CHAIN MINI STYLES ===== */
    #sp_Task_GetComplaintList_html .approval-chain-container {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      flex-wrap: wrap;
    }

    #sp_Task_GetComplaintList_html .approvers-chain-row {
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }

    #sp_Task_GetComplaintList_html .approver-node {
      display: inline-flex;
      align-items: center;
      gap: 4px;
      background-color: var(--paradise-bg-2);
      padding: 2px 6px;
      border-radius: var(--paradise-border-radius-xl);
      font-size: 11.5px;
    }

    #sp_Task_GetComplaintList_html .approver-avatar-mini {
      width: 18px;
      height: 18px;
      border-radius: var(--paradise-border-radius-pill);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      font-size: 8px;
      font-weight: var(--font-weight-bold);
      background-color: var(--paradise-bg-1);
      color: var(--paradise-fg-1);
    }

    #sp_Task_GetComplaintList_html .approver-mini-name {
      font-weight: var(--font-weight-medium);
      color: var(--paradise-fg-2);
    }

    #sp_Task_GetComplaintList_html .chain-separator {
      font-size: 8px;
      color: var(--paradise-fg-3);
      display: inline-flex;
      align-items: center;
    }

    /* Spinner animation for Bootstrap Icons replacement */
    @keyframes paradise-spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    .paradise-spin {
      display: inline-block;
      animation: paradise-spin 1s linear infinite;
    }
  
    /* Spinner animation for Bootstrap Icons replacement */
    @keyframes paradise-spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    .paradise-spin {
      display: inline-block;
      animation: paradise-spin 1s linear infinite;
    }
  </style>

  <main>
    <!-- Quick Stats Grid -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-icon total">
          <i class="bi bi-folder2-open"></i>
        </div>
        <div class="stat-info">
          <span class="stat-lbl">Tổng số khiếu nại</span>
          <span class="stat-val" id="stat-total">0</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon pending">
          <i class="bi bi-hourglass-split"></i>
        </div>
        <div class="stat-info">
          <span class="stat-lbl">Chờ giải quyết</span>
          <span class="stat-val" id="stat-pending">0</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon approved">
          <i class="bi bi-check-circle-fill"></i>
        </div>
        <div class="stat-info">
          <span class="stat-lbl">Đã đồng ý</span>
          <span class="stat-val" id="stat-approved">0</span>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon rejected">
          <i class="bi bi-x-circle-fill"></i>
        </div>
        <div class="stat-info">
          <span class="stat-lbl">Đã từ chối</span>
          <span class="stat-val" id="stat-rejected">0</span>
        </div>
      </div>
    </div>

    <!-- Filter & Search Bar -->
    <div class="filter-bar">
      <div class="status-tabs" id="status-tabs-container">
        <button class="tab-item active" data-status="-1">Tất cả</button>
        <button class="tab-item" data-status="1">Chờ duyệt</button>
        <button class="tab-item" data-status="2">Đồng ý</button>
        <button class="tab-item" data-status="3">Từ chối</button>
      </div>

      <div class="search-wrapper">
        <i class="bi bi-search search-icon"></i>
        <input type="text" class="search-input" id="search-input" placeholder="Tìm tên công việc, nhân viên..." />
      </div>
    </div>

    <!-- Complaints Container -->
    <div class="complaints-container" id="complaints-list-container">
      <!-- Cards dynamically rendered here -->
    </div>

    <!-- Pagination -->
    <div class="pagination-row" id="pagination-nav">
      <!-- Pagination buttons here -->
    </div>
  </main>

  <!-- Sleek Decision Modal -->
  <div class="complaint-modal-overlay" id="resolution-modal-overlay">
    <div class="complaint-modal">
      <div class="modal-header">
        <h3 class="modal-title" id="modal-headline">Xử lý khiếu nại</h3>
        <button class="modal-close" id="modal-close-btn">&times;</button>
      </div>
      <div class="modal-body">
        <input type="hidden" id="modal-complaint-id" />
        <input type="hidden" id="modal-resolution-status" />

        <div class="form-group" id="proposed-date-field" style="display: none">
          <label class="form-label">Hạn chót phê duyệt (Gia hạn)</label>
          <input type="datetime-local" class="form-input-date" id="modal-approved-duedate" />
        </div>

        <div class="form-group">
          <label class="form-label" id="modal-notes-label">Ý kiến phản hồi / Lý do từ chối</label>
          <textarea class="form-textarea" id="modal-review-notes"
            placeholder="Nhập ý kiến phê duyệt hoặc lý do từ chối..."></textarea>
        </div>
      </div>
      <div class="modal-footer">
        <button class="btn-modal cancel" id="modal-cancel-btn">Hủy bỏ</button>
        <button class="btn-modal submit" id="modal-submit-btn">Xác nhận</button>
      </div>
    </div>
  </div>

  <script>
    (function () {
      // Mock data in case DB connection is unavailable
      const mockComplaints = [];

      let complaintsData = [];
      let currentFilterStatus = -1; // All
      let searchKeyword = "";
      let currentPage = 1;
      const itemsPerPage = 5;

      // DOM Elements
      const container = document.getElementById("complaints-list-container");
      const searchInput = document.getElementById("search-input");
      const tabsContainer = document.getElementById("status-tabs-container");
      const paginationNav = document.getElementById("pagination-nav");

      // Stat value elements
      const statTotal = document.getElementById("stat-total");
      const statPending = document.getElementById("stat-pending");
      const statApproved = document.getElementById("stat-approved");
      const statRejected = document.getElementById("stat-rejected");

      // Modal Elements
      const modalOverlay = document.getElementById("resolution-modal-overlay");
      const modalHeadline = document.getElementById("modal-headline");
      const modalComplaintId = document.getElementById("modal-complaint-id");
      const modalResolutionStatus = document.getElementById(
        "modal-resolution-status",
      );
      const modalApprovedDuedate = document.getElementById(
        "modal-approved-duedate",
      );
      const modalReviewNotes = document.getElementById("modal-review-notes");
      const modalNotesLabel = document.getElementById("modal-notes-label");
      const proposedDateField = document.getElementById("proposed-date-field");

      // Load data from server or use mock
      function loadComplaints() {
        container.innerHTML = `
          <div class="col-12 text-center p-5">
            <div class="spinner-border text-info" role="status" style="width: 3rem; height: 3rem;"></div>
            <p class="mt-3 text-muted">Đang tải danh sách khiếu nại...</p>
          </div>`;

        const loginID = window.UserID || 38; // Default fallback for dev environment
        const lang = window.LanguageID || "VN";

        if (typeof AjaxHPAParadise !== "undefined") {
          AjaxHPAParadise({
            data: {
              name: "sp_Task_Complaint_GetDataList",
              param: [
                "LoginID",
                loginID,
                "LanguageID",
                lang,
                "StatusFilter",
                -1, // Fetch all first, client will filter to make counters work perfectly
              ],
            },
            success: function (res) {
              try {
                const json = typeof res === "string" ? JSON.parse(res) : res;
                const rows = json.data && json.data[0] ? json.data[0] : [];

                complaintsData = rows || [];
              } catch (e) {
                console.error("Error parsing DB response:", e);
                complaintsData = [];
              }
              calculateStats();
              filterAndRender();
            },
            error: function (err) {
              console.error("AJAX call error:", err);
              complaintsData = [];
              calculateStats();
              filterAndRender();
            },
          });
        } else {
          setTimeout(() => {
            complaintsData = [];
            calculateStats();
            filterAndRender();
          }, 400);
        }
      }

      function calculateStats() {
        const total = complaintsData.length;
        const pending = complaintsData.filter(
          (c) => parseInt(c.Approve_Status) === 1,
        ).length;
        const approved = complaintsData.filter(
          (c) => parseInt(c.Approve_Status) === 2,
        ).length;
        const rejected = complaintsData.filter(
          (c) => parseInt(c.Approve_Status) === 3,
        ).length;

        statTotal.innerText = total;
        statPending.innerText = pending;
        statApproved.innerText = approved;
        statRejected.innerText = rejected;
      }

      function filterAndRender() {
        // Apply filters
        let filtered = complaintsData.filter((c) => {
          // Status filter
          const statusMatch =
            currentFilterStatus === -1 ||
            parseInt(c.Approve_Status) === currentFilterStatus;

          // Search keyword match
          const keyword = searchKeyword.toLowerCase();
          const taskNameMatch =
            c.TaskName && c.TaskName.toLowerCase().includes(keyword);
          const assigneeMatch =
            c.MainAssigneeName &&
            c.MainAssigneeName.toLowerCase().includes(keyword);
          const creatorMatch =
            c.CreatorName && c.CreatorName.toLowerCase().includes(keyword);
          const searchMatch =
            !searchKeyword || taskNameMatch || assigneeMatch || creatorMatch;

          return statusMatch && searchMatch;
        });

        // Render Pagination
        const totalItems = filtered.length;
        const totalPages = Math.ceil(totalItems / itemsPerPage);

        if (currentPage > totalPages && totalPages > 0) {
          currentPage = totalPages;
        }

        const startIndex = (currentPage - 1) * itemsPerPage;
        const endIndex = startIndex + itemsPerPage;
        const pageData = filtered.slice(startIndex, endIndex);

        renderList(pageData);
        renderPagination(totalPages);
      }

      function renderApprovalChain(stagesJson, requesterName) {
        if (!stagesJson) {
          // Fallback to requester
          return `
            <div class="meta-item" title="Người giao việc kiêm người duyệt">
              <i class="bi bi-person-check" style="color: var(--paradise-color-primary, #007bff)"></i>
              <span>Người duyệt: <strong>${escapeHtml(requesterName)}</strong></span>
            </div>`;
        }

        let stages = [];
        try {
          stages =
            typeof stagesJson === "string"
              ? JSON.parse(stagesJson)
              : stagesJson;
        } catch (e) {
          console.error("Error parsing approval stages:", e);
        }

        if (!Array.isArray(stages) || stages.length === 0) {
          return `
            <div class="meta-item" title="Người giao việc kiêm người duyệt">
              <i class="bi bi-person-check" style="color: var(--paradise-color-primary, #007bff)"></i>
              <span>Người duyệt: <strong>${escapeHtml(requesterName)}</strong></span>
            </div>`;
        }

        const chainHtml = stages
          .map((s, idx) => {
            const status = parseInt(s.ApprovalStatus) || 0;
            let badgeColor = "#94a3b8"; // Pending (gray)
            let statusText = "Chờ duyệt";

            if (status === 1) {
              badgeColor = "#16a34a"; // Approved (green)
              statusText = "Đã duyệt";
            } else if (status === 2) {
              badgeColor = "#ef4444"; // Rejected (red)
              statusText = "Từ chối";
            }

            const initials = s.ApproverName
              ? s.ApproverName.split(" ").pop().substring(0, 2).toUpperCase()
              : "?";

            return `
            <span class="approver-node" title="Cấp ${s.StageOrder}: ${escapeHtml(s.ApproverName)} (${statusText}${s.Note ? " - " + escapeHtml(s.Note) : ""})">
              <span class="approver-avatar-mini" style="border: 2px solid ${badgeColor};">
                ${escapeHtml(initials)}
              </span>
              <span class="approver-mini-name">${escapeHtml(s.ApproverName.split(" ").pop())}</span>
            </span>
          `;
          })
          .join(
            ''<span class="chain-separator"><i class="bi bi-chevron-right"></i></span>'',
          );

        return `
          <div class="meta-item approval-chain-container">
            <i class="bi bi-shield-shaded" style="color: var(--paradise-color-secondary, #6c757d)"></i>
            <span>Người duyệt:</span>
            <div class="approvers-chain-row">${chainHtml}</div>
          </div>
        `;
      }

      function renderList(data) {
        if (data.length === 0) {
          container.innerHTML = `
            <div class="empty-state">
              <i class="bi bi-folder2-open empty-icon"></i>
              <h4 class="empty-title">Không tìm thấy đơn khiếu nại</h4>
              <p class="empty-desc">Không có bản ghi khiếu nại nào phù hợp với bộ lọc hoặc từ khóa tìm kiếm của bạn.</p>
            </div>`;
          return;
        }

        container.innerHTML = data
          .map((c) => {
            const status = parseInt(c.Approve_Status);
            const type = parseInt(c.ComplaintType) || 1;
            let statusText = "Chờ duyệt";
            let statusClass = "pending";
            let iconClass = "bi bi-hourglass-split";

            if (status === 2) {
              statusText = "Đồng ý";
              statusClass = "approved";
              iconClass = "bi bi-check-circle-fill";
            } else if (status === 3) {
              statusText = "Từ chối";
              statusClass = "rejected";
              iconClass = "bi bi-x-circle-fill";
            }

            // Safe note rendering
            const rejectionNote =
              c.RejectionNote || "Không có nội dung lý do cụ thể.";
            const complaintReason =
              c.ComplaintReason || "Không có nội dung lý do khiếu nại.";
            const approvalNote = c.ApprovalNote || "";

            // Check if current user is an approver in ApprovalStages who has already approved or rejected
            let myStageStatus = 0;
            if (c.ApprovalStages) {
              try {
                const stages = typeof c.ApprovalStages === "string" ? JSON.parse(c.ApprovalStages) : c.ApprovalStages;
                if (Array.isArray(stages)) {
                  const currentEmpID = c.CurrentEmployeeID;
                  if (currentEmpID) {
                    const myStage = stages.find(s => s.ApproverID === currentEmpID || s.approverID === currentEmpID);
                    if (myStage) {
                      myStageStatus = parseInt(myStage.ApprovalStatus !== undefined ? myStage.ApprovalStatus : (myStage.approvalStatus !== undefined ? myStage.approvalStatus : (myStage.approvalstatus !== undefined ? myStage.approvalstatus : 0))) || 0;
                    }
                  }
                }
              } catch (e) {
                console.error("Error parsing approval stages for card status:", e);
              }
            }

            return `
            <div class="complaint-card" data-id="${c.ComplaintID}" onclick="window.openComplaintForm(${c.ComplaintID})" style="cursor: pointer;">
              <div class="status-strip ${statusClass}"></div>

              <div class="card-header-row">
                <div class="title-area">
                  <a href="#" onclick="event.preventDefault(); event.stopPropagation(); window.openComplaintForm(${c.ComplaintID})" class="task-title-link">${escapeHtml(c.TaskName)}</a>
                  <span class="type-badge ${type === 2 ? "appeal" : "extension"}">
                    ${type === 2 ? "Khiếu nại từ chối" : "Gia hạn"}
                  </span>
                </div>
                ${status === 1 && parseInt(c.CanApprove) === 1
                ? `
                  <div class="action-header-group" onclick="event.stopPropagation();">
                    <button class="btn-action-sm reject" onclick="window.openComplaintForm(${c.ComplaintID})" title="Từ chối khiếu nại">
                      <i class="bi bi-x-lg"></i> Từ chối
                    </button>
                    <button class="btn-action-sm approve" onclick="window.openComplaintForm(${c.ComplaintID})" title="Phê duyệt khiếu nại">
                      <i class="bi bi-check-lg"></i> Duyệt
                    </button>
                  </div>
                `
                : status === 1
                  ? (myStageStatus === 1
                    ? `
                    <span class="status-badge approved" style="background-color: var(--paradise-bg-success-subtle); color: var(--paradise-color-success);" title="Bạn đã phê duyệt đơn này">
                      <i class="bi bi-check-circle-fill"></i> Bạn đã duyệt
                    </span>
                    `
                    : myStageStatus === 2
                      ? `
                      <span class="status-badge rejected" style="background-color: var(--paradise-bg-danger-subtle); color: var(--paradise-color-danger);" title="Bạn đã từ chối đơn này">
                        <i class="bi bi-x-circle-fill"></i> Bạn đã từ chối
                      </span>
                      `
                      : `
                      <span class="status-badge pending" style="background: rgba(148, 163, 184, 0.12); color: #64748b;" title="Bạn không có quyền xử lý đơn này">
                        <i class="bi bi-hourglass-split"></i> Chờ duyệt
                      </span>
                      `
                  )
                  : `
                  <span class="status-badge ${statusClass}">
                    <i class="${iconClass}"></i> ${statusText}
                  </span>
                `
              }
              </div>

              <!-- Metadata row -->
              <div class="meta-row">
                <div class="meta-item">
                  <i class="bi bi-person-workspace" style="color: var(--paradise-color-primary, #007bff)"></i>
                  <span>Người khiếu nại: <strong>${escapeHtml(c.MainAssigneeName)}</strong></span>
                </div>
                ${renderApprovalChain(c.ApprovalStages, c.RequesterName)}
                <div class="meta-item">
                  <i class="bi bi-clock"></i>
                  <span>Gửi lúc: ${formatDateTime(c.CreatedDate)}</span>
                </div>
                <div class="meta-item" onclick="event.stopPropagation();">
                  <i class="bi bi-box-arrow-up-right" style="color: var(--paradise-color-primary, #007bff)"></i>
                  <a href="#" onclick="event.preventDefault(); window.openTaskDetail(${c.HistoryID})" style="color: inherit; text-decoration: none; font-weight: var(--font-weight-semi-bold);">Xem Task</a>
                </div>
              </div>

              <!-- Timeline Extension comparison -->
              ${type === 1
                ? `
                <div class="timeline-row">
                  <div class="timeline-extension">
                    <i class="bi bi-calendar3" style="color: var(--paradise-color-secondary, #6c757d)"></i>
                    <span>Gia hạn: </span>
                    <span class="date-val old">${formatDateTime(c.OldDueDate)}</span>
                    <i class="bi bi-arrow-right" style="margin: 0 4px; opacity: 0.7;"></i>
                    <span class="date-val new">${formatDateTime(c.ProposedDueDate)}</span>
                  </div>
                </div>
              `
                : ""
              }

            </div>
          `;
          })
          .join("");
      }

      function renderPagination(totalPages) {
        if (totalPages <= 1) {
          paginationNav.innerHTML = "";
          return;
        }

        let html = `
          <button class="page-btn ${currentPage === 1 ? "disabled" : ""}" data-dir="prev">
            <i class="bi bi-chevron-left"></i>
          </button>
        `;

        for (let i = 1; i <= totalPages; i++) {
          html += `
            <button class="page-btn ${i === currentPage ? "active" : ""}" data-page="${i}">
              ${i}
            </button>
          `;
        }

        html += `
          <button class="page-btn ${currentPage === totalPages ? "disabled" : ""}" data-dir="next">
            <i class="bi bi-chevron-right"></i>
          </button>
        `;

        paginationNav.innerHTML = html;

        // Add event listeners
        paginationNav.querySelectorAll(".page-btn").forEach((btn) => {
          btn.addEventListener("click", function (e) {
            e.preventDefault();
            if (
              btn.classList.contains("disabled") ||
              btn.classList.contains("active")
            )
              return;

            const page = btn.getAttribute("data-page");
            const dir = btn.getAttribute("data-dir");

            if (page) {
              currentPage = parseInt(page);
            } else if (dir === "prev" && currentPage > 1) {
              currentPage--;
            } else if (dir === "next" && currentPage < totalPages) {
              currentPage++;
            }

            filterAndRender();

            // Scroll to the list smoothly
            container.scrollIntoView({ behavior: "smooth", block: "start" });
          });
        });
      }

      // Event Listeners for Filters
      searchInput.addEventListener("input", function (e) {
        searchKeyword = e.target.value;
        currentPage = 1;
        filterAndRender();
      });

      tabsContainer.addEventListener("click", function (e) {
        const tab = e.target.closest(".tab-item");
        if (!tab) return;

        tabsContainer
          .querySelectorAll(".tab-item")
          .forEach((t) => t.classList.remove("active"));
        tab.classList.add("active");

        currentFilterStatus = parseInt(tab.getAttribute("data-status"));
        currentPage = 1;
        loadComplaints();
      });

      // Global window functions for click handlers
      window.openTaskDetail = function (historyID) {
        // Call global function in Paradise HRM to open task details if available
        if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
          OpenFormParamMobile("sp_Task_TaskDetail", { HistoryID: historyID });
        } else {
          openFormParam("sp_Task_TaskDetail", { HistoryID: historyID });
        }
      };

      window.openComplaintForm = function (complaintID) {
        // Call global function in Paradise HRM to open complaint details form
        if (typeof openFormParam === "function") {
          openFormParam("sp_Task_ComplaintForm", { ComplaintID: complaintID });
        } else {
          window.location.href = `/complaint_form.html?ComplaintID=${complaintID}`;
        }
      };

      window.openSubmitComplaintForm = function (historyID, type) {
        if (typeof openFormParam === "function") {
          openFormParam("sp_Task_ComplaintForm", {
            HistoryID: historyID,
            ComplaintType: type,
          });
        } else {
          window.location.href = `/complaint_form.html?HistoryID=${historyID}&ComplaintType=${type}`;
        }
      };

      window.openReviewModal = function (
        complaintID,
        statusID,
        proposedDate,
        type,
      ) {
        modalComplaintId.value = complaintID;
        modalResolutionStatus.value = statusID;
        modalReviewNotes.value = "";

        type = parseInt(type) || 1;

        if (statusID === 2) {
          if (type === 2) {
            modalHeadline.innerText = "Phê duyệt khiếu nại & Duyệt công việc";
            proposedDateField.style.display = "none";
          } else {
            modalHeadline.innerText = "Phê duyệt khiếu nại & Gia hạn";
            proposedDateField.style.display = "block";
          }
          modalNotesLabel.innerText = "Ý kiến phê duyệt";

          // Format proposedDate for input type="datetime-local" (YYYY-MM-DDTHH:MM)
          if (proposedDate) {
            const dateObj = new Date(proposedDate);
            if (!isNaN(dateObj.getTime())) {
              const formatted = dateObj.toISOString().slice(0, 16);
              modalApprovedDuedate.value = formatted;
            }
          } else {
            modalApprovedDuedate.value = "";
          }
        } else {
          modalHeadline.innerText = "Từ chối đơn khiếu nại";
          modalNotesLabel.innerText = "Lý do từ chối";
          proposedDateField.style.display = "none";
        }

        modalOverlay.classList.add("active");
      };

      function closeReviewModal() {
        modalOverlay.classList.remove("active");
      }

      // Modal Events
      document
        .getElementById("modal-close-btn")
        .addEventListener("click", closeReviewModal);
      document
        .getElementById("modal-cancel-btn")
        .addEventListener("click", closeReviewModal);

      document
        .getElementById("modal-submit-btn")
        .addEventListener("click", function () {
          const complaintID = parseInt(modalComplaintId.value);
          const statusID = parseInt(modalResolutionStatus.value);
          const reviewNotes = modalReviewNotes.value.trim();
          const finalDueDate = modalApprovedDuedate.value;
          const loginID = window.UserID || 38;

          if (statusID === 3 && !reviewNotes) {
            if (typeof uiManager !== "undefined") {
              uiManager.showAlert({
                type: "warning",
                message: "Vui lòng nhập lý do từ chối khiếu nại!",
              });
            } else {
              alert("⚠️ Vui lòng nhập lý do từ chối khiếu nại!");
            }
            return;
          }

          container.innerHTML = `
          <div class="col-12 text-center p-5">
            <div class="spinner-border text-success" role="status" style="width: 3rem; height: 3rem;"></div>
            <p class="mt-3 text-muted">Đang xử lý yêu cầu...</p>
          </div>`;

          closeReviewModal();

          if (typeof AjaxHPAParadise !== "undefined") {
            AjaxHPAParadise({
              data: {
                name: "sp_Task_Complaint_Resolve",
                param: [
                  "ComplaintID",
                  complaintID,
                  "LoginID",
                  loginID,
                  "ApprovedStatus",
                  statusID,
                  "ReviewNote",
                  reviewNotes,
                  "FinalDueDate",
                  finalDueDate, // Pass the final deadline to update
                ],
              },
              success: function (res) {
                try {
                  const json = typeof res === "string" ? JSON.parse(res) : res;
                  const result =
                    json.data && json.data[0] ? json.data[0][0] : {};

                  if (result.Status === "SUCCESS") {
                    if (typeof uiManager !== "undefined") {
                      uiManager.showAlert({
                        type: "success",
                        message: result.Message,
                      });
                    } else {
                      alert(`✅ ${result.Message}`);
                    }
                  } else {
                    if (typeof uiManager !== "undefined") {
                      uiManager.showAlert({
                        type: "error",
                        message: result.Message || "Có lỗi xảy ra!",
                      });
                    } else {
                      alert(`❌ ${result.Message || "Có lỗi xảy ra!"}`);
                    }
                  }
                } catch (e) {
                  console.error("Error processing resolution result:", e);
                }
                // Reload complaints from DB
                loadComplaints();
              },
              error: function (err) {
                console.error("Failed to submit resolution:", err);
                // Local update for offline mock fallback
                const idx = complaintsData.findIndex(
                  (c) => c.ComplaintID === complaintID,
                );
                if (idx !== -1) {
                  complaintsData[idx].Approve_Status = statusID;
                  complaintsData[idx].ApprovalNote =
                    reviewNotes || (statusID === 2 ? "Đồng ý." : "Từ chối.");
                  complaintsData[idx].ApprovedDate = new Date().toISOString();

                  if (statusID === 2 && finalDueDate) {
                    complaintsData[idx].ProposedDueDate = finalDueDate;
                  }
                }

                if (typeof uiManager !== "undefined") {
                  uiManager.showAlert({
                    type: "success",
                    message:
                      statusID === 2
                        ? "Đã phê duyệt khiếu nại thành công! (Offline Mode)"
                        : "Đã từ chối đơn khiếu nại thành công! (Offline Mode)",
                  });
                } else {
                  alert(`✅ Xử lý thành công! (Offline Mode)`);
                }
                calculateStats();
                filterAndRender();
              },
            });
          } else {
            // Offline mockup submit handler
            setTimeout(() => {
              const idx = complaintsData.findIndex(
                (c) => c.ComplaintID === complaintID,
              );
              if (idx !== -1) {
                complaintsData[idx].Approve_Status = statusID;
                complaintsData[idx].ApprovalNote =
                  reviewNotes || (statusID === 2 ? "Đồng ý." : "Từ chối.");
                complaintsData[idx].ApprovedDate = new Date().toISOString();

                if (statusID === 2 && finalDueDate) {
                  complaintsData[idx].ProposedDueDate = finalDueDate;
                }
              }
              if (typeof uiManager !== "undefined") {
                uiManager.showAlert({
                  type: "success",
                  message:
                    statusID === 2
                      ? "Đã phê duyệt khiếu nại thành công!"
                      : "Đã từ chối đơn khiếu nại thành công!",
                });
              } else {
                alert(`✅ Xử lý thành công!`);
              }
              calculateStats();
              filterAndRender();
            }, 500);
          }
        });

      // Utility Helpers
      function escapeHtml(str) {
        if (!str) return "";
        return str.replace(/[&<>''"]/g, (tag) => {
          const chars = {
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            "''": "&#39;",
            ''"'': "&quot;",
          };
          return chars[tag] || tag;
        });
      }

      function formatDateTime(dateStr) {
        if (!dateStr) return "-";
        const dateObj = new Date(dateStr);
        if (isNaN(dateObj.getTime())) return dateStr;

        const day = String(dateObj.getDate()).padStart(2, "0");
        const month = String(dateObj.getMonth() + 1).padStart(2, "0");
        const year = dateObj.getFullYear();
        const hours = String(dateObj.getHours()).padStart(2, "0");
        const minutes = String(dateObj.getMinutes()).padStart(2, "0");

        return `${day}/${month}/${year} ${hours}:${minutes}`;
      }

      // Initial Call
      loadComplaints();
    })();
  </script>
</div>
';
    SELECT @html AS html;
END
GO
PRINT N'[OK] Created procedure sp_Task_GetComplaintList_html';
GO

-- ============================================================================
-- PHASE 5b: Renderer sp_Task_ComplaintForm_html (HTML detail form, config-driven)
-- Note: renderer dùng pattern dynamic SQL với `(select loadUI from tblCommonControlType_Signed where UID = '...')`
--       Cần đảm bảo 6 row tblCommonControlType_Signed đã được seed + DUC chạy trước khi build cache.
-- ============================================================================

IF OBJECT_ID('dbo.sp_Task_ComplaintForm_html', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Task_ComplaintForm_html;
GO

CREATE   PROCEDURE [dbo].[sp_Task_ComplaintForm_html](
	@LanguageID varchar(10) = 'VN'
)
as
begin


	declare @html nvarchar(max) = N'';
	set @html = N'
<div id="sp_Task_ComplaintForm_html">
  <style>
    /* ===== SYSTEM STYLING & DESIGN SYSTEM ===== */
    .dx-inkripple-wave {
      display: none;
    }

    #sp_Task_ComplaintForm_html {
      font-family: var(--paradise-font-family-base);
      color: var(--paradise-fg-0);
      background: var(--paradise-bg-0);
      min-height: 100vh;
      padding: var(--paradise-space-6) var(--paradise-space-4);
      box-sizing: border-box;
      display: flex;
      justify-content: center;
      align-items: flex-start;
      width: 100%;
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html {
      color: var(--paradise-fg-0);
      background: var(--paradise-bg-0);
    }

    #sp_Task_ComplaintForm_html * {
      box-sizing: border-box;
      transition: all 0.2s ease-in-out;
    }

    /* ===== CARD CONTAINER ===== */
    #sp_Task_ComplaintForm_html .app-card {
      background: var(--paradise-card-bg);
      border: var(--paradise-card-border);
      border-radius: 20px;
      width: 100%;
      max-width: 680px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .app-card {
      background: var(--paradise-card-bg);
      border: var(--paradise-card-border);
      box-shadow: var(--paradise-shadow-lg);
    }

    /* ===== TAB NAVIGATION ===== */
    #sp_Task_ComplaintForm_html .tabs-header {
      display: flex;
      border-bottom: 1px solid var(--paradise-border-color);
      background: var(--paradise-card-bg);
      padding: 0 var(--paradise-space-5);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .tabs-header {
      background: var(--paradise-card-bg);
      border-bottom-color: var(--paradise-border-color);
    }

    #sp_Task_ComplaintForm_html .tab-btn {
      flex: 1;
      padding: var(--paradise-space-4) var(--paradise-space-2);
      font-size: 16px;
      font-weight: 600;
      color: var(--paradise-fg-2);
      background: transparent;
      border: none;
      cursor: pointer;
      text-align: center;
      position: relative;
      outline: none;
      transition: var(--paradise-transition-fast);
    }

    #sp_Task_ComplaintForm_html .tab-btn:hover {
      color: var(--paradise-color-primary);
    }

    #sp_Task_ComplaintForm_html .tab-btn.active {
      color: var(--paradise-color-primary);
    }

    #sp_Task_ComplaintForm_html .tab-btn.active::after {
      content: "";
      position: absolute;
      bottom: 0;
      left: 15%;
      right: 15%;
      height: 3px;
      background-color: var(--paradise-color-primary);
      border-radius: 3px 3px 0 0;
    }

    /* ===== CONTENT CONTAINERS ===== */
    #sp_Task_ComplaintForm_html .tab-content {
      padding: var(--paradise-space-6);
      display: none;
    }

    #sp_Task_ComplaintForm_html .tab-content.active {
      display: block;
      animation: tabFadeIn 0.3s ease-out;
    }

    @keyframes tabFadeIn {
      from {
        opacity: 0;
        transform: translateY(8px);
      }

      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    /* ===== REJECTION BANNER ===== */
    #sp_Task_ComplaintForm_html .rejection-banner {
      background: var(--paradise-bg-danger-subtle);
      border-left: 4px solid var(--paradise-color-danger);
      border-radius: 0 var(--paradise-border-radius-lg) var(--paradise-border-radius-lg) 0;
      padding: var(--paradise-space-3) var(--paradise-space-4);
      margin-bottom: var(--paradise-space-5);
      font-size: 13.5px;
      color: var(--paradise-color-danger);
      line-height: 1.45;
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .rejection-banner {
      background: var(--paradise-bg-danger-subtle);
      color: var(--paradise-color-danger);
    }

    #sp_Task_ComplaintForm_html .rejection-banner strong {
      display: block;
      margin-bottom: 4px;
      text-transform: uppercase;
      font-size: 11px;
      letter-spacing: 0.05em;
      font-weight: 700;
    }

    /* ===== FORM LAYOUT & GROUPS ===== */
    #sp_Task_ComplaintForm_html .form-group {
      margin-bottom: var(--paradise-space-5);
    }

    #sp_Task_ComplaintForm_html .form-row {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: var(--paradise-space-4);
    }

    @media (max-width: 576px) {
      #sp_Task_ComplaintForm_html .form-row {
        grid-template-columns: 1fr;
        gap: 20px;
      }
    }

    #sp_Task_ComplaintForm_html .form-label {
      display: flex;
      align-items: center;
      gap: var(--paradise-space-2);
      font-size: 14px;
      font-weight: 600;
      color: var(--paradise-fg-2);
      margin-bottom: var(--paradise-space-2);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .form-label {
      color: var(--paradise-fg-2);
    }

    #sp_Task_ComplaintForm_html .form-label i {
      font-size: 14px;
      width: 16px;
      text-align: center;
      color: var(--paradise-fg-2);
    }

    #sp_Task_ComplaintForm_html .form-label .required {
      color: var(--paradise-color-danger);
      margin-left: 2px;
      font-weight: bold;
    }

    /* ===== INPUTS & SELECTS ===== */
    #sp_Task_ComplaintForm_html .form-select-wrapper {
      position: relative;
      width: 100%;
    }

    #sp_Task_ComplaintForm_html .form-select,
    #sp_Task_ComplaintForm_html .form-input,
    #sp_Task_ComplaintForm_html .form-textarea {
      width: 100%;
      border-radius: var(--paradise-border-radius-md);
      border: 1px solid var(--paradise-color-input-border);
      background: var(--paradise-bg-0);
      padding: var(--paradise-space-2) var(--paradise-space-3);
      font-size: 14.5px;
      color: var(--paradise-fg-0);
      outline: none;
      font-family: inherit;
      transition: var(--paradise-transition-fast);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .form-select,
    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .form-input,
    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .form-textarea {
      border-color: var(--paradise-color-input-border);
      background: var(--paradise-bg-0);
      color: var(--paradise-fg-0);
    }

    #sp_Task_ComplaintForm_html .form-select:focus,
    #sp_Task_ComplaintForm_html .form-input:focus,
    #sp_Task_ComplaintForm_html .form-textarea:focus {
      border-color: var(--paradise-color-primary);
      background: var(--paradise-card-bg);
      box-shadow: 0 0 0 3px var(--paradise-color-input-focus-ring);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .form-select:focus,
    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .form-input:focus,
    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .form-textarea:focus {
      background: var(--paradise-card-bg);
    }

    #sp_Task_ComplaintForm_html .form-textarea {
      height: 100px;
      resize: vertical;
      line-height: 1.5;
    }

    #sp_Task_ComplaintForm_html .detail-text {
      font-size: 15px;
      font-weight: 500;
      color: var(--paradise-fg-0);
      padding: 6px 0;
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .detail-text {
      color: var(--paradise-fg-0);
    }

    #sp_Task_ComplaintForm_html .detail-badge {
      display: inline-flex;
      align-items: center;
      gap: var(--paradise-space-1);
      padding: var(--paradise-space-1) var(--paradise-space-3);
      border-radius: var(--paradise-border-radius-pill);
      font-size: var(--paradise-font-button-xs);
      font-weight: 700;
      text-transform: uppercase;
    }

    #sp_Task_ComplaintForm_html .detail-badge.pending {
      background: var(--paradise-bg-warning-subtle);
      color: var(--paradise-color-warning);
    }

    #sp_Task_ComplaintForm_html .detail-badge.approved {
      background: var(--paradise-bg-success-subtle);
      color: var(--paradise-color-success);
    }

    #sp_Task_ComplaintForm_html .detail-badge.rejected {
      background: var(--paradise-bg-danger-subtle);
      color: var(--paradise-color-danger);
    }

    /* ===== FILE ATTACHMENT ===== */
    #sp_Task_ComplaintForm_html .file-attach-btn {
      display: inline-flex;
      align-items: center;
      gap: var(--paradise-space-2);
      padding: var(--paradise-space-2) var(--paradise-space-4);
      background: var(--paradise-bg-0);
      border: 1px solid var(--paradise-border-color);
      border-radius: var(--paradise-border-radius-xl);
      font-size: var(--paradise-font-body3);
      font-weight: 500;
      color: var(--paradise-fg-1);
      cursor: pointer;
      outline: none;
      transition: var(--paradise-transition-fast);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .file-attach-btn {
      background: var(--paradise-bg-0);
      border-color: var(--paradise-border-color);
      color: var(--paradise-fg-1);
    }

    #sp_Task_ComplaintForm_html .file-attach-btn:hover {
      background: var(--paradise-bg-1);
      border-color: var(--paradise-border-strong);
      color: var(--paradise-fg-0);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .file-attach-btn:hover {
      background: var(--paradise-bg-1);
      color: var(--paradise-fg-0);
    }

    #sp_Task_ComplaintForm_html .file-list-preview {
      margin-top: var(--paradise-space-2);
      font-size: var(--paradise-font-body3);
      color: var(--paradise-fg-2);
    }

    /* ===== APPROVER STATUS BADGE ===== */
    #sp_Task_ComplaintForm_html .approver-status-badge {
      display: inline-flex;
      align-items: center;
      gap: var(--paradise-space-1);
      padding: var(--paradise-space-1) var(--paradise-space-2);
      border-radius: var(--paradise-border-radius-md);
      font-size: var(--paradise-font-body3);
      font-weight: 700;
      text-transform: uppercase;
      white-space: nowrap;
    }

    #sp_Task_ComplaintForm_html .approver-status-badge.pending {
      background: var(--paradise-bg-warning-subtle);
      color: var(--paradise-color-warning);
    }

    #sp_Task_ComplaintForm_html .approver-status-badge.approved {
      background: var(--paradise-bg-success-subtle);
      color: var(--paradise-color-success);
    }

    #sp_Task_ComplaintForm_html .approver-status-badge.rejected {
      background: var(--paradise-bg-danger-subtle);
      color: var(--paradise-color-danger);
    }

    #sp_Task_ComplaintForm_html .approver-status-badge.cancelled {
      background: var(--paradise-bg-warning-subtle);
      color: var(--paradise-color-warning);
    }

    #sp_Task_ComplaintForm_html .approver-status-badge.cancellation-request {
      background: rgba(147, 51, 234, 0.1);
      color: #9333ea;
    }

    /* ===== RESOLVED PANEL DETAILS ===== */
    #sp_Task_ComplaintForm_html .resolution-panel {
      background: var(--paradise-bg-success-subtle);
      border: 1px solid var(--paradise-color-success);
      border-radius: var(--paradise-border-radius-lg);
      padding: var(--paradise-space-5);
      margin-top: var(--paradise-space-5);
    }

    #sp_Task_ComplaintForm_html .resolution-panel.rejected {
      background: var(--paradise-bg-danger-subtle);
      border-color: var(--paradise-color-danger);
    }

    #sp_Task_ComplaintForm_html .resolution-title {
      font-size: 14px;
      font-weight: 700;
      margin: 0 0 12px 0;
      display: flex;
      align-items: center;
      gap: 6px;
    }

    #sp_Task_ComplaintForm_html .resolution-panel.approved .resolution-title {
      color: var(--paradise-color-success);
    }

    #sp_Task_ComplaintForm_html .resolution-panel.rejected .resolution-title {
      color: var(--paradise-color-danger);
    }

    /* ===== APPROVAL CHAIN ===== */
    #sp_Task_ComplaintForm_html .approval-section-title {
      display: flex;
      align-items: center;
      gap: var(--paradise-space-2);
      font-size: 14px;
      font-weight: 600;
      color: var(--paradise-fg-2);
      margin-bottom: var(--paradise-space-4);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .approval-section-title {
      color: var(--paradise-fg-2);
    }

    #sp_Task_ComplaintForm_html .approval-flow {
      display: flex;
      justify-content: center;
      align-items: flex-start;
      /* Align all nodes at the top to prevent vertical shifting when some have notes */
      margin-bottom: var(--paradise-space-5);
      padding: var(--paradise-space-3);
    }

    #sp_Task_ComplaintForm_html .approver-node {
      display: flex;
      flex-direction: column;
      align-items: center;
      text-align: center;
      position: relative;
    }

    #sp_Task_ComplaintForm_html .approver-avatar-wrapper {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      overflow: hidden;
      border: 2px solid var(--paradise-border-color);
      background: var(--paradise-bg-1);
      display: flex;
      align-items: center;
      justify-content: center;
      margin-bottom: var(--paradise-space-2);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .approver-avatar-wrapper {
      border-color: var(--paradise-border-color);
      background: var(--paradise-bg-1);
    }

    #sp_Task_ComplaintForm_html .approver-info {
      font-size: 13px;
      line-height: 1.4;
    }

    #sp_Task_ComplaintForm_html .approver-name {
      font-weight: 600;
      color: var(--paradise-fg-0);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .approver-name {
      color: var(--paradise-fg-0);
    }

    #sp_Task_ComplaintForm_html .approver-code {
      color: var(--paradise-fg-2);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .approver-code {
      color: var(--paradise-fg-2);
    }

    #sp_Task_ComplaintForm_html .flow-connector {
      color: var(--paradise-fg-2);
      margin: 0 var(--paradise-space-4);
      font-size: 16px;
      align-self: flex-start;
      /* Keep arrow at the top */
      margin-top: 16px;
      /* Offset the arrow vertically to align perfectly with the middle of the 48px avatar */
    }

    /* ===== APPROVER NOTE UNDER NODE ===== */
    #sp_Task_ComplaintForm_html .approver-note-box {
      margin-top: var(--paradise-space-3);
      padding: var(--paradise-space-2) var(--paradise-space-3);
      border-radius: var(--paradise-border-radius-md);
      font-size: var(--paradise-font-body2);
      line-height: 1.4;
      background: var(--paradise-bg-1);
      border: 1px solid var(--paradise-border-color);
      border-left: 3px solid var(--paradise-border-strong);
      color: var(--paradise-fg-1);
      min-width: 140px;
      max-width: 180px;
      text-align: left;
      word-wrap: break-word;
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .approver-note-box {
      background: var(--paradise-bg-1);
      border-color: var(--paradise-border-color);
      border-left-color: var(--paradise-border-strong);
      color: var(--paradise-fg-1);
    }

    #sp_Task_ComplaintForm_html .approver-note-box.approved {
      background: var(--paradise-bg-success-subtle);
      border-color: var(--paradise-color-success);
      border-left-color: var(--paradise-color-success);
    }

    #sp_Task_ComplaintForm_html .approver-note-box.rejected {
      background: var(--paradise-bg-danger-subtle);
      border-color: var(--paradise-color-danger);
      border-left-color: var(--paradise-color-danger);
    }

    #sp_Task_ComplaintForm_html .approver-note-box.cancelled {
      background: var(--paradise-bg-warning-subtle);
      border-color: var(--paradise-color-warning);
      border-left-color: var(--paradise-color-warning);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .approver-note-box.cancelled {
      background: var(--paradise-bg-warning-subtle);
      border-color: var(--paradise-color-warning);
      border-left-color: var(--paradise-color-warning);
    }

    #sp_Task_ComplaintForm_html .approver-note-box.cancellation-request {
      background: rgba(147, 51, 234, 0.05);
      border-color: rgba(147, 51, 234, 0.2);
      border-left-color: #9333ea;
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .approver-note-box.cancellation-request {
      background: rgba(147, 51, 234, 0.1);
      border-color: rgba(147, 51, 234, 0.25);
      border-left-color: #d8b4fe;
    }

    /* ===== SUBMIT ACTION ===== */
    #sp_Task_ComplaintForm_html .submit-action-wrapper {
      margin-top: var(--paradise-space-6);
      display: flex;
      gap: var(--paradise-space-3);
      width: 100%;
    }

    #sp_Task_ComplaintForm_html .submit-action-wrapper .btn-submit {
      flex: 1;
      min-width: 140px;
      width: auto;
    }

    #sp_Task_ComplaintForm_html .btn-submit {
      background: var(--paradise-color-primary);
      color: white;
      border: none;
      padding: var(--paradise-space-3) var(--paradise-space-5);
      border-radius: var(--paradise-border-radius-xl);
      font-size: 16px;
      font-weight: 700;
      cursor: pointer;
      text-align: center;
      box-shadow: var(--paradise-shadow-md);
      transition: var(--paradise-transition-fast);
    }

    /* Default full width for standalone submit buttons */
    #sp_Task_ComplaintForm_html form .btn-submit {
      width: 100%;
    }

    #sp_Task_ComplaintForm_html .btn-submit:active {
      transform: translateY(1px);
    }

    /* ===== REVIEW PANEL ===== */
    #sp_Task_ComplaintForm_html .review-panel {
      margin-top: var(--paradise-space-6);
      border-top: 1px dashed var(--paradise-border-color);
      padding-top: var(--paradise-space-5);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .review-panel {
      border-top-color: var(--paradise-border-color);
    }

    #sp_Task_ComplaintForm_html .actions-row-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: var(--paradise-space-4);
      margin-top: var(--paradise-space-5);
    }

    #sp_Task_ComplaintForm_html .btn-action {
      border: none;
      padding: var(--paradise-space-3) var(--paradise-space-5);
      border-radius: var(--paradise-border-radius-xl);
      font-size: var(--paradise-font-button-md);
      font-weight: 700;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: var(--paradise-space-2);
      color: white;
      transition: var(--paradise-transition-fast);
    }

    #sp_Task_ComplaintForm_html .btn-action.approve-btn {
      background: var(--paradise-color-primary);
      box-shadow: var(--paradise-shadow-md);
    }

    #sp_Task_ComplaintForm_html .btn-action.reject-btn {
      background: var(--paradise-color-danger);
      box-shadow: var(--paradise-shadow-md);
    }

    #sp_Task_ComplaintForm_html .manager-status-badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      gap: var(--paradise-space-2);
      padding: var(--paradise-space-3) var(--paradise-space-5);
      border-radius: var(--paradise-border-radius-xl);
      font-size: 16px;
      font-weight: 700;
      text-transform: uppercase;
      width: 100%;
      text-align: center;
      box-shadow: var(--paradise-shadow-sm);
    }

    #sp_Task_ComplaintForm_html .manager-status-badge.approved {
      background: var(--paradise-bg-success-subtle);
      color: var(--paradise-color-success);
      border: 1px solid var(--paradise-color-success);
    }

    #sp_Task_ComplaintForm_html .manager-status-badge.rejected {
      background: var(--paradise-bg-danger-subtle);
      color: var(--paradise-color-danger);
      border: 1px solid var(--paradise-color-danger);
    }

    /* ===== HISTORY VIEW STYLES ===== */
    #sp_Task_ComplaintForm_html .history-filter-bar {
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      align-items: center;
      gap: var(--paradise-space-4);
      margin-bottom: var(--paradise-space-5);
      border-bottom: 1px dashed var(--paradise-border-color);
      padding-bottom: var(--paradise-space-4);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .history-filter-bar {
      border-bottom-color: var(--paradise-border-color);
    }

    #sp_Task_ComplaintForm_html .filter-tabs {
      display: flex;
      background: var(--paradise-bg-1);
      padding: var(--paradise-space-1);
      border-radius: var(--paradise-border-radius-xl);
      gap: var(--paradise-space-0);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .filter-tabs {
      background: var(--paradise-bg-1);
    }

    #sp_Task_ComplaintForm_html .filter-btn {
      border: none;
      background: transparent;
      padding: 6px 14px;
      border-radius: var(--paradise-border-radius-lg);
      font-size: var(--paradise-font-body3);
      font-weight: 600;
      color: var(--paradise-fg-2);
      cursor: pointer;
    }

    #sp_Task_ComplaintForm_html .filter-btn.active {
      background: var(--paradise-bg-0);
      color: var(--paradise-color-primary);
      box-shadow: var(--paradise-shadow-sm);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .filter-btn.active {
      background: var(--paradise-bg-0);
      color: var(--paradise-color-primary);
    }

    #sp_Task_ComplaintForm_html .history-search-wrapper {
      position: relative;
      flex: 1;
      max-width: 260px;
      min-width: 200px;
    }

    #sp_Task_ComplaintForm_html .history-search-input {
      width: 100%;
      padding: var(--paradise-space-2) var(--paradise-space-2) var(--paradise-space-2) 32px;
      font-size: var(--paradise-font-body3);
      border-radius: var(--paradise-border-radius-xl);
      border: 1px solid var(--paradise-border-color);
      background: var(--paradise-bg-0);
      outline: none;
      color: var(--paradise-fg-0);
      transition: var(--paradise-transition-fast);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .history-search-input {
      background: var(--paradise-bg-0);
      border-color: var(--paradise-border-color);
      color: var(--paradise-fg-0);
    }

    #sp_Task_ComplaintForm_html .history-search-input:focus {
      border-color: var(--paradise-color-primary);
      background: var(--paradise-card-bg);
    }

    #sp_Task_ComplaintForm_html .history-search-icon {
      position: absolute;
      left: var(--paradise-space-3);
      top: 50%;
      transform: translateY(-50%);
      color: var(--paradise-fg-2);
      font-size: 14px;
      pointer-events: none;
    }

    /* ===== HISTORY CARDS ===== */
    #sp_Task_ComplaintForm_html .history-list {
      display: flex;
      flex-direction: column;
      gap: var(--paradise-space-4);
    }

    #sp_Task_ComplaintForm_html .history-card {
      background: var(--paradise-card-bg);
      border: var(--paradise-card-border);
      border-radius: var(--paradise-border-radius-md);
      padding: var(--paradise-space-4);
      display: flex;
      flex-direction: column;
      gap: var(--paradise-space-3);
      cursor: pointer;
      position: relative;
      overflow: hidden;
      transition: var(--paradise-transition-fast);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .history-card {
      background: var(--paradise-card-bg);
      border: var(--paradise-card-border);
    }

    #sp_Task_ComplaintForm_html .history-card:hover {
      box-shadow: var(--paradise-shadow-md);
      border-color: var(--paradise-color-primary);
    }

    #sp_Task_ComplaintForm_html .history-card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
    }

    #sp_Task_ComplaintForm_html .history-card-title {
      font-size: 15px;
      font-weight: 700;
      color: var(--paradise-fg-0);
      margin: 0;
      flex: 1;
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .history-card-title {
      color: var(--paradise-fg-0);
    }

    #sp_Task_ComplaintForm_html .status-badge {
      display: inline-flex;
      align-items: center;
      gap: var(--paradise-space-2);
      padding: var(--paradise-space-1) var(--paradise-space-3);
      border-radius: var(--paradise-border-radius-md);
      font-size: var(--paradise-font-body3);
      font-weight: 700;
      text-transform: uppercase;
      white-space: nowrap;
    }

    #sp_Task_ComplaintForm_html .status-badge.pending {
      background: var(--paradise-bg-warning-subtle);
      color: var(--paradise-color-warning);
    }

    #sp_Task_ComplaintForm_html .status-badge.approved {
      background: var(--paradise-bg-success-subtle);
      color: var(--paradise-color-success);
    }

    #sp_Task_ComplaintForm_html .status-badge.rejected {
      background: var(--paradise-bg-danger-subtle);
      color: var(--paradise-color-danger);
    }

    #sp_Task_ComplaintForm_html .history-card-body {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: var(--paradise-space-3);
      font-size: var(--paradise-font-body3);
      color: var(--paradise-fg-1);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .history-card-body {
      color: var(--paradise-fg-1);
    }

    @media (max-width: 576px) {
      #sp_Task_ComplaintForm_html .history-card-body {
        grid-template-columns: 1fr;
      }
    }

    #sp_Task_ComplaintForm_html .history-meta-item {
      display: flex;
      align-items: center;
      gap: 8px;
    }

    #sp_Task_ComplaintForm_html .history-meta-item i {
      color: var(--paradise-fg-2);
      width: 16px;
      text-align: center;
    }

    #sp_Task_ComplaintForm_html .history-meta-label {
      color: var(--paradise-fg-2);
      margin-right: 4px;
    }

    #sp_Task_ComplaintForm_html .history-reason-box {
      grid-column: 1 / -1;
      background: var(--paradise-bg-1);
      padding: 10px var(--paradise-space-3);
      border-radius: var(--paradise-border-radius-md);
      font-style: italic;
      font-size: var(--paradise-font-body3);
      border-left: 3px solid var(--paradise-border-color);
      color: var(--paradise-fg-1);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .history-reason-box {
      background: var(--paradise-bg-1);
      border-left-color: var(--paradise-border-strong);
      color: var(--paradise-fg-1);
    }

    #sp_Task_ComplaintForm_html .history-card-detail-panel {
      grid-column: 1 / -1;
      border-top: 1px dashed var(--paradise-border-color);
      padding-top: var(--paradise-space-3);
      margin-top: var(--paradise-space-2);
      display: none;
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .history-card-detail-panel {
      border-top-color: var(--paradise-border-color);
    }

    #sp_Task_ComplaintForm_html .history-card.expanded .history-card-detail-panel {
      display: block;
      animation: slideDown var(--paradise-transition-base) ease-out;
    }

    @keyframes slideDown {
      from {
        opacity: 0;
        transform: translateY(-4px);
      }

      to {
        opacity: 1;
        transform: translateY(0);
      }
    }

    #sp_Task_ComplaintForm_html .detail-panel-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: var(--paradise-space-3);
      font-size: var(--paradise-font-body3);
    }

    @media (max-width: 576px) {
      #sp_Task_ComplaintForm_html .detail-panel-grid {
        grid-template-columns: 1fr;
      }
    }

    #sp_Task_ComplaintForm_html .history-empty {
      text-align: center;
      padding: var(--paradise-space-8) var(--paradise-space-5);
      color: var(--paradise-fg-2);
    }

    #sp_Task_ComplaintForm_html .history-empty i {
      font-size: 40px;
      margin-bottom: var(--paradise-space-3);
    }

    /* ===== PAGINATION ===== */
    #sp_Task_ComplaintForm_html .pagination-row {
      display: flex;
      justify-content: center;
      gap: var(--paradise-space-2);
      margin-top: var(--paradise-space-5);
    }

    #sp_Task_ComplaintForm_html .page-btn {
      min-width: 32px;
      height: 32px;
      border: 1px solid var(--paradise-border-color);
      background: var(--paradise-bg-0);
      color: var(--paradise-fg-1);
      border-radius: var(--paradise-border-radius-md);
      font-size: var(--paradise-font-body3);
      font-weight: 600;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: var(--paradise-transition-fast);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .page-btn {
      background: var(--paradise-bg-0);
      border-color: var(--paradise-border-color);
      color: var(--paradise-fg-1);
    }

    #sp_Task_ComplaintForm_html .page-btn:hover:not(.disabled) {
      border-color: var(--paradise-color-primary);
      color: var(--paradise-color-primary);
    }

    #sp_Task_ComplaintForm_html .page-btn.active {
      background: var(--paradise-color-primary);
      color: white;
      border-color: var(--paradise-color-primary);
    }

    #sp_Task_ComplaintForm_html .page-btn.disabled {
      opacity: 0.5;
      cursor: default;
    }

    /* ===== TASK DETAIL BUTTON ===== */
    #sp_Task_ComplaintForm_html .btn-view-task-detail {
      display: inline-flex;
      align-items: center;
      gap: var(--paradise-space-2);
      padding: var(--paradise-space-2) var(--paradise-space-3);
      background: var(--paradise-bg-0);
      border: 1px solid var(--paradise-border-color);
      border-radius: var(--paradise-border-radius-xl);
      font-size: var(--paradise-font-body3);
      font-weight: 600;
      color: var(--paradise-color-primary);
      cursor: pointer;
      outline: none;
      transition: var(--paradise-transition-fast);
    }

    #sp_Task_ComplaintForm_html .btn-view-task-detail:hover {
      background: var(--paradise-bg-success-subtle);
      border-color: var(--paradise-color-primary);
      box-shadow: var(--paradise-shadow-md);
    }

    #sp_Task_ComplaintForm_html .btn-view-task-detail:active {
      transform: translateY(1px);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .btn-view-task-detail {
      background: var(--paradise-bg-0);
      border-color: var(--paradise-border-color);
      color: var(--paradise-color-primary);
    }

    [data-bs-theme="dark"] #sp_Task_ComplaintForm_html .btn-view-task-detail:hover {
      background: var(--paradise-bg-1);
      border-color: var(--paradise-color-primary);
    }

    /* Spinner animation for Bootstrap Icons replacement */
    @keyframes paradise-spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    .paradise-spin {
      display: inline-block;
      animation: paradise-spin 1s linear infinite;
    }
  
    /* Spinner animation for Bootstrap Icons replacement */
    @keyframes paradise-spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    .paradise-spin {
      display: inline-block;
      animation: paradise-spin 1s linear infinite;
    }
  </style>

  <div class="app-card">
    <!-- Header Tabs -->
    <div class="tabs-header">
      <button type="button" class="tab-btn active" id="tab-form-btn" data-tab="tab-form">
        Đơn đề nghị
      </button>
      <button type="button" class="tab-btn" id="tab-history-btn" data-tab="tab-history">
        Lịch sử khiếu nại
      </button>
    </div>

    <!-- Tab 1: Form (Tạo mới hoặc Xem chi tiết) -->
    <div class="tab-content active" id="tab-form">
      <!-- Rejected Task Approver''s Note Banner -->
      <div class="rejection-banner" id="rejection-note-banner" style="display: none">
        <strong>Lý do từ chối công việc từ cấp trên:</strong>
        <span id="rejection-note-text"></span>
      </div>

      <!-- Main Input/View Fields Form -->
      <form id="complaint-form-element" onsubmit="event.preventDefault()">
        <!-- Task Selection dropdown -->
        <div class="form-group" id="group-task-select">
          <label class="form-label" for="P3B400D95FDB64B7F8DCE8FB445CF5E15">
            <i class="bi bi-list-task"></i> Công việc cần đề nghị / khiếu nại
            <span class="required">(*)</span>
          </label>
          <div style="display: flex; gap: 12px; align-items: flex-start;">
            <div id="P3B400D95FDB64B7F8DCE8FB445CF5E15" style="flex: 1;"></div>
            <button type="button" class="btn-view-task-detail" id="btn-view-task-detail" style="margin-top: 0;">
              <i class="bi bi-box-arrow-up-right"></i> Xem chi tiết công việc
            </button>
          </div>
        </div>

        <!-- Complaint Type Field -->
        <div class="form-group" id="group-type">
          <label class="form-label" for="select-complaint-type">
            <i class="bi bi-card-list"></i> Loại đơn đề nghị
            <span class="required">(*)</span>
          </label>
          <div id="PF824852E41004F53B87E683F9ACDEE09"></div>
          <div class="detail-text" id="type-text-readonly" style="display: none; font-weight: 700"></div>
        </div>

        <!-- Proposed Due Date / Current Due Date Symmetrical Row -->
        <div class="form-row form-group" id="group-date-row">
          <div class="form-col">
            <label class="form-label">
              <i class="bi bi-calendar3"></i> Hạn chót hiện tại
            </label>
            <div id="019E42EB6ECB72988DACC5334048AD51"></div>
          </div>
          <div class="form-col" id="col-proposed-date">
            <label class="form-label">
              <i class="bi bi-calendar3"></i> Hạn chót đề xuất mới
              <span class="required">(*)</span>
            </label>
            <div id="019E42EB6ECB70F3A08D659D244C9533"></div>
            <div class="detail-text" id="proposed-date-readonly"
              style="display: none; font-weight: 700; color: var(--paradise-color-primary)"></div>
          </div>
        </div>

        <!-- Reason / Explanation -->
        <div class="form-group">
          <label class="form-label">
            <i class="bi bi-emoji-smile"></i> Lý do & Nội dung giải trình
            <span class="required">(*)</span>
          </label>
          <div id="019E42EB6ECB76C5A4155B25A04CBB49"></div>
          <div class="detail-text" id="reason-readonly" style="display: none"></div>
        </div>

        <!-- File upload input -->
        <div class="form-group" id="group-attachments">
          <label class="form-label">
            <i class="bi bi-paperclip"></i> Tệp đính kèm
          </label>
          <div id="019E42EB6ECE77848FEF1C6C394FBA2C"></div>
        </div>



        <!-- Approval Process graphical sequence -->
        <div class="form-group" style="margin-top: 28px" id="group-approval-flow">
          <h4 class="approval-section-title">
            <i class="bi bi-person-check"></i> Quá trình duyệt
          </h4>
          <div class="approval-flow" id="approval-flow-container">
            <!-- Rendered dynamically -->
          </div>
        </div>

        <!-- Resolved Panel details (Approved / Rejected) -->
        <div class="resolution-panel" id="detail-resolution-panel" style="display: none">
          <h4 class="resolution-title" id="resolution-panel-title">
            <i class="bi bi-check-circle-fill"></i> Ý kiến phản hồi của người
            duyệt
          </h4>
          <div class="detail-text" id="detail-resolution-note" style="font-style: italic"></div>
          <div class="context-grid" style="margin-top: 12px; font-size: 12.5px; color: var(--paradise-fg-2)">
            <div class="context-item">
              Người duyệt: <strong id="detail-reviewer"></strong>
            </div>
            <div class="context-item">
              Thời gian duyệt: <strong id="detail-revieweddate"></strong>
            </div>
          </div>
        </div>

        <!-- Mode: SUBMIT Actions Bar -->
        <div class="submit-action-wrapper" id="submit-actions-row" style="display: none">
          <button type="button" class="btn-submit" id="btn-confirm-submit">
            Gửi đơn đề nghị
          </button>
        </div>

        <!-- Mode: REVIEW Decision Action Panel (Pending and current user is authorized approver) -->
        <div class="review-panel" id="review-panel-actions" style="display: none">
          <div class="form-group">
            <label class="form-label">Ý kiến phản hồi / Lý do giải quyết</label>
            <textarea class="form-textarea" id="textarea-review-note"
              placeholder="Nhập nhận xét phê duyệt hoặc lý do từ chối giải quyết..." style="height: 80px"></textarea>
          </div>
          <div class="actions-row-grid">
            <button type="button" class="btn-action reject-btn" id="btn-resolve-reject">
              <i class="bi bi-x-lg"></i> Từ chối
            </button>
            <button type="button" class="btn-action approve-btn" id="btn-resolve-approve">
              <i class="bi bi-check-lg"></i> Phê duyệt
            </button>
          </div>
        </div>

        <!-- Mode: MANAGER RESOLVED Badge -->
        <div class="submit-action-wrapper" id="manager-status-row"
          style="display: none; justify-content: center; align-items: center; margin-top: var(--paradise-space-6);">
          <div id="manager-status-badge-el" class="manager-status-badge"></div>
        </div>

        <!-- Action Buttons - Cancel & Create New -->
        <div class="submit-action-wrapper" id="close-actions-row" style="display: none;">
          <button type="button" class="btn-submit btn-cancel-action" id="btn-cancel-request"
            style="display: none; background: var(--paradise-color-danger); color: white">
            <i class="bi bi-x-lg" style="margin-right: 6px;"></i>Hủy
          </button>
          <button type="button" class="btn-submit btn-create-action" id="btn-create-new-complaint"
            style="display: none; background: var(--paradise-color-primary); color: white">
            <i class="bi bi-plus-lg" style="margin-right: 6px;"></i>Tạo mới
          </button>
        </div>
      </form>
    </div>

    <!-- Tab 2: Lịch sử -->
    <div class="tab-content" id="tab-history">
      <!-- Filter and search row -->
      <div class="history-filter-bar">
        <div class="filter-tabs" id="history-filter-tabs">
          <button type="button" class="filter-btn active" data-status="-1">
            Tất cả
          </button>
          <button type="button" class="filter-btn" data-status="1">
            Chờ duyệt
          </button>
          <button type="button" class="filter-btn" data-status="2">
            Đồng ý
          </button>
          <button type="button" class="filter-btn" data-status="3">
            Từ chối
          </button>
        </div>

        <div class="history-search-wrapper">
          <i class="bi bi-search history-search-icon"></i>
          <input type="text" class="history-search-input" id="search-history-input"
            placeholder="Tìm lý do, công việc..." />
        </div>
      </div>

      <!-- History List dynamic box container -->
      <div class="history-list" id="history-items-container">
        <!-- Rendered dynamically by script -->
      </div>

      <!-- Pagination row -->
      <div class="pagination-row" id="history-pagination">
        <!-- Renders dynamically -->
      </div>
    </div>
  </div>

  <script>
    (function () {
      let currentRecordID_Temp_ComplaintID = "Complaint_" + Date.now() + "_" + Math.floor(Math.random() * 1000);

      const uidMap = {
        "019E42EB6ECB70F3A08D659D244C9533": "PE4C6698E797E4E73B3B904F2AC6EAD7B", // ProposedDueDate
        "019E42EB6ECB72988DACC5334048AD51": "PB3EAB30500524A39AACA503B753377B5", // OldDueDate
        "019E42EB6ECB76C5A4155B25A04CBB49": "P509F121B87BF45788C3587BD5C5A539A", // ComplaintReason
        "019E42EB6ECE7614867EF2386C44B208": "PF824852E41004F53B87E683F9ACDEE09", // ComplaintType selectbox (Unfinished tasks)
        "019E42EB6ECE77848FEF1C6C394FBA2C": "P75A67EB5C0AD4D899DBEAB3F52C6B2FA", // File uploader
      };

      window.complaintUidMap = uidMap;

      // Rename DOM element IDs immediately
      for (const key in uidMap) {
        const el = document.getElementById(key);
        if (el) {
          el.id = uidMap[key];
        }
      }

      // Setup window proxies for Instance variables
      const propMap = [
        {
          alias: "InstanceProposedDueDate019E42EB6ECB70F3A08D659D244C9533",
          real: "InstanceProposedDueDatePE4C6698E797E4E73B3B904F2AC6EAD7B",
        },
        {
          alias: "InstanceOldDueDate019E42EB6ECB72988DACC5334048AD51",
          real: "InstanceOldDueDatePB3EAB30500524A39AACA503B753377B5",
        },
        {
          alias: "InstanceComplaintReason019E42EB6ECB76C5A4155B25A04CBB49",
          real: "InstanceComplaintReasonP509F121B87BF45788C3587BD5C5A539A",
        },
        {
          alias: "InstanceComplaintType019E42EB6ECE7614867EF2386C44B208",
          real: "InstanceComplaintTypePF824852E41004F53B87E683F9ACDEE09",
        },
        {
          alias: "InstanceFileURL019E42EB6ECE77848FEF1C6C394FBA2C",
          real: "InstanceFileURLP75A67EB5C0AD4D899DBEAB3F52C6B2FA",
        },
      ];

      propMap.forEach((item) => {
        Object.defineProperty(window, item.alias, {
          get() {
            return (
              window[item.real] ||
              (typeof globalThis !== "undefined"
                ? globalThis[item.real]
                : undefined)
            );
          },
          set(val) {
            window[item.real] = val;
          },
          configurable: true,
          enumerable: true,
        });
      });

      '
        + (select loadUI from tblCommonControlType_Signed where UID = 'PE4C6698E797E4E73B3B904F2AC6EAD7B')
      +(select loadUI from tblCommonControlType_Signed where UID = 'PB3EAB30500524A39AACA503B753377B5')
      +(select loadUI from tblCommonControlType_Signed where UID = 'P509F121B87BF45788C3587BD5C5A539A')
      +(select loadUI from tblCommonControlType_Signed where UID = 'PF824852E41004F53B87E683F9ACDEE09')
      +(select loadUI from tblCommonControlType_Signed where UID = 'P75A67EB5C0AD4D899DBEAB3F52C6B2FA')
      +(select loadUI from tblCommonControlType_Signed where UID = 'P3B400D95FDB64B7F8DCE8FB445CF5E15') +N'

      // Load DataSource: sp_Task_Complaint_GetUnfinishedTasks
      if ("sp_Task_Complaint_GetUnfinishedTasks" && "sp_Task_Complaint_GetUnfinishedTasks".trim() !== "") {
        loadDataSourceCommon("TaskID", "sp_Task_Complaint_GetUnfinishedTasks", function (data) {
          // Data được shared qua callback
        });
      }

      if ("sp_Task_getComplaintTypes" && "sp_Task_getComplaintTypes".trim() !== "") {
        loadDataSourceCommon("ComplaintType", "sp_Task_getComplaintTypes", function (data) {
          // Data được shared qua callback
        });
      }

      function loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback) {
        if (!columnName || !dataSourceSP || dataSourceSP.trim() === "") {
          console.warn("[loadDataSourceCommon] Missing columnName or dataSourceSP");
          return;
        }

        const dataSourceKey = "DataSource_" + columnName;
        // Sử dụng format: columnNameDataSourceLoaded để tương thích với code hiện tại
        const loadedKey = columnName + "DataSourceLoaded";

        // Kiểm tra nếu đã load rồi thì không load lại

        if (window[loadedKey] === true) {
          if (typeof onSuccessCallback === "function") {
            onSuccessCallback(window[dataSourceKey] || []);
          }
          return;
        }

        // Kiểm tra nếu đang load thì đợi
        if (window[loadedKey] === "loading") {
          // Đợi một chút rồi thử lại
          setTimeout(function () {
            loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback);
          }, 100);

          return;
        }


        // Đánh dấu đang load để tránh load trùng lặp
        window[loadedKey] = "loading";

        return new Promise((resolve, reject) => {
          AjaxHPAParadise({
            data: {
              name: dataSourceSP,
              param: ["LoginID", LoginID, "LanguageID", LanguageID]
            },
            success: function (res) {
              const json = typeof res === "string" ? JSON.parse(res) : res;

              window[dataSourceKey] = (json.data && json.data[0]) || [];
              window[loadedKey] = true;

              // Ưu tiên lấy từ json response (nếu API trả về explicit)
              // Sau đó mới fallback query dataSchema
              let idField = json.valueExpr;
              let nameField = json.displayExpr;

              if (!idField || !nameField) {
                if (json.dataSchema && json.dataSchema[0]) {
                  const schema = json.dataSchema[0];
                  if (!idField) idField = schema[0]?.name;
                  if (!nameField) nameField = schema[1]?.name;
                }
              }

              window["DataSourceIDField_" + columnName] = idField || "ID";
              window["DataSourceNameField_" + columnName] = nameField || "Name";

              const data = window[dataSourceKey];

              // callback trước
              if (typeof onSuccessCallback === "function") {
                onSuccessCallback(data, json);
              }

              // resolve sau
              resolve(data);
            },
            error: function (err) {
              console.error("[loadDataSourceCommon] Failed to load datasource for", columnName, ":", err);
              window[loadedKey] = false;

              if (typeof onSuccessCallback === "function") {
                onSuccessCallback([]);
              }

              reject(err);
            }
          });
        });
      }


      // Retrieve parameters from Paradise HRM global variable
      const serverParams = window.sp_Task_ComplaintForm_param || {};

      const urlComplaintID = serverParams.ComplaintID;
      const urlHistoryID = serverParams.HistoryID;
      const urlType = serverParams.ComplaintType;
      const loginID = serverParams?.LoginID || window.UserID;

      // Main complaint data object
      const defaultData = {
        Mode: urlComplaintID ? "view" : "submit",
        ComplaintID: urlComplaintID ? parseInt(urlComplaintID) : null,
        HistoryID: urlHistoryID ? parseInt(urlHistoryID) : null,
        TaskID: null,
        TaskName: "",
        TaskDescription: "",
        MainAssigneeName: "",
        RequesterName: "",
        OldDueDate: null,
        ProposedDueDate: null,
        ComplaintReason: "",
        Approve_Status: 1, // 1 = Pending, 2 = Approved, 3 = Rejected
        CreatorName: "",
        CreatedDate: null,
        ApprovedBy: null,
        ApproverName: null,
        ApprovedDate: null,
        ApprovalNote: null,
        ComplaintType: urlType ? parseInt(urlType) : 1, // 1 = Gia hạn, 2 = Khiếu nại từ chối
        RejectionNote: "",
        CanApprove: 0,
        ApprovalStages: [],
      };

      let data = defaultData;
      const lang = window.LanguageID || "VN";
      let selectedType = parseInt(data.ComplaintType) || 1;

      // Mock database of all complaints for History view
      const mockHistoryList = [];

      // Setup DOM
      const rejectionBanner = document.getElementById("rejection-note-banner");
      const rejectionText = document.getElementById("rejection-note-text");

      const typeSelectWrapper = document.getElementById("PF824852E41004F53B87E683F9ACDEE09");
      const typeTextReadonly = document.getElementById("type-text-readonly");

      const groupDateRow = document.getElementById("group-date-row");
      const colProposedDate = document.getElementById("col-proposed-date");
      const proposedDateReadonly = document.getElementById(
        "proposed-date-readonly",
      );

      const reasonReadonly = document.getElementById("reason-readonly");



      const resolutionPanel = document.getElementById(
        "detail-resolution-panel",
      );
      const resolutionPanelTitle = document.getElementById(
        "resolution-panel-title",
      );
      const resolutionNoteEl = document.getElementById(
        "detail-resolution-note",
      );
      const reviewerEl = document.getElementById("detail-reviewer");
      const revieweddateEl = document.getElementById("detail-revieweddate");



      // Action panels
      const submitActions = document.getElementById("submit-actions-row");
      const reviewActions = document.getElementById("review-panel-actions");
      const closeActions = document.getElementById("close-actions-row");
      const managerStatusRow = document.getElementById("manager-status-row");
      const managerStatusBadgeEl = document.getElementById("manager-status-badge-el");

      // Control Helpers for DevExpress dynamic components
      function getControlVal(id) {
        const uidMap = window.complaintUidMap || {};
        const realId = uidMap[id] || id;

        // Special handling for ComplaintReason Rich Text Editor
        if (realId === "P509F121B87BF45788C3587BD5C5A539A") {
          const editor = $("#editor-P509F121B87BF45788C3587BD5C5A539A");
          if (editor.length) {
            return editor.html();
          }
        }

        const el = $("#" + realId);
        if (el.length) {
          const widget = el.data("dxTextBox") ||
            el.data("dxDateBox") ||
            el.data("dxTextArea") ||
            el.data("dxSelectBox") ||
            el.data("dxFileUploader");
          if (widget) {
            return widget.option("value");
          }
        }
        const dom = document.getElementById(realId);
        if (dom) {
          if (dom.tagName === "INPUT" || dom.tagName === "TEXTAREA" || dom.tagName === "SELECT") {
            return dom.value;
          }
          const innerInput = dom.querySelector("input, textarea, select");
          if (innerInput) return innerInput.value;
        }
        return "";
      }

      function setControlVal(id, val) {
        const uidMap = window.complaintUidMap || {};
        const realId = uidMap[id] || id;

        // Special handling for ComplaintReason Rich Text Editor
        if (realId === "P509F121B87BF45788C3587BD5C5A539A") {
          const editor = $("#editor-P509F121B87BF45788C3587BD5C5A539A");
          if (editor.length) {
            editor.html(val || "");
            if (typeof checkEditorHeight_ComplaintReasonP509F121B87BF45788C3587BD5C5A539A === "function") {
              checkEditorHeight_ComplaintReasonP509F121B87BF45788C3587BD5C5A539A();
            }
            return;
          }
        }

        const el = $("#" + realId);
        if (el.length) {
          const widget = el.data("dxTextBox") ||
            el.data("dxDateBox") ||
            el.data("dxTextArea") ||
            el.data("dxSelectBox");
          if (widget) {
            if (el.data("dxDateBox")) {
              let parsedDate = null;
              if (val && val !== "-") {
                if (val instanceof Date) {
                  parsedDate = val;
                } else {
                  let strVal = String(val).trim();
                  if (strVal.match(/^\d{2}\/\d{2}\/\d{4}/)) {
                    const parts = strVal.split(/[\s/:]+/);
                    if (parts.length >= 3) {
                      const day = parseInt(parts[0], 10);
                      const month = parseInt(parts[1], 10) - 1;
                      const year = parseInt(parts[2], 10);
                      const hour = parts[3] ? parseInt(parts[3], 10) : 0;
                      const min = parts[4] ? parseInt(parts[4], 10) : 0;
                      parsedDate = new Date(year, month, day, hour, min);
                    }
                  } else {
                    const d = new Date(strVal);
                    if (!isNaN(d.getTime())) {
                      parsedDate = d;
                    }
                  }
                }
              }
              widget.option("value", parsedDate);
            } else {
              widget.option("value", val);
            }
            return;
          }
        }
        const dom = document.getElementById(realId);
        if (dom) {
          if (dom.tagName === "INPUT" || dom.tagName === "TEXTAREA" || dom.tagName === "SELECT") {
            dom.value = val;
            return;
          }
          const innerInput = dom.querySelector("input, textarea, select");
          if (innerInput) {
            innerInput.value = val;
            return;
          }
          dom.innerText = val;
        }
      }

      function setControlDisabled(id, disabled) {
        const uidMap = window.complaintUidMap || {};
        const realId = uidMap[id] || id;

        // Special handling for ComplaintReason Rich Text Editor
        if (realId === "P509F121B87BF45788C3587BD5C5A539A" && typeof window.rteObj_ComplaintReasonP509F121B87BF45788C3587BD5C5A539A !== "undefined") {
          if (window.rteObj_ComplaintReasonP509F121B87BF45788C3587BD5C5A539A.rte) {
            window.rteObj_ComplaintReasonP509F121B87BF45788C3587BD5C5A539A.rte.readOnly(disabled);
          }
        }

        const el = $("#" + realId);
        if (el.length) {
          const widget = el.data("dxTextBox") ||
            el.data("dxDateBox") ||
            el.data("dxTextArea") ||
            el.data("dxSelectBox") ||
            el.data("dxFileUploader");
          if (widget) {
            widget.option("disabled", disabled);
            return;
          }
        }
        const dom = document.getElementById(realId);
        if (dom) dom.disabled = disabled;
      }

      function setupTaskSelectboxListener() {
        // Instance là let trong cùng scope — reference trực tiếp
        if (InstanceTaskIDP3B400D95FDB64B7F8DCE8FB445CF5E15) {
          InstanceTaskIDP3B400D95FDB64B7F8DCE8FB445CF5E15.option("onValueChanged", function (e) {
            const selectedHistoryID = e.value;
            if (selectedHistoryID) {
              data.HistoryID = parseInt(selectedHistoryID);
              fetchComplaintDetails(null, data.HistoryID, selectedType);
            }
          });
        }
      }

      // Open task detail form
      function openTaskDetailForm() {
        if (!data.HistoryID) {
          showAlert("warning", "Vui lòng chọn công việc trước");
          return;
        }

        // Detect mobile OS
        function getMobileOperatingSystem() {
          const ua = navigator.userAgent;
          if (/android/i.test(ua)) return "Android";
          if (/iphone|ipad|ipod/i.test(ua)) return "iOS";
          return "unknown";
        }

        if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
          if (typeof OpenFormParamMobile === "function") {
            OpenFormParamMobile("sp_Task_TaskDetail", { HistoryID: data.HistoryID });
          }
        } else {
          if (typeof openFormParam === "function") {
            openFormParam("sp_Task_TaskDetail", { HistoryID: data.HistoryID });
          }
        }
      }

      // Setup task detail button handler
      const btnViewTaskDetail = document.getElementById("btn-view-task-detail");
      if (btnViewTaskDetail) {
        btnViewTaskDetail.onclick = (e) => {
          e.preventDefault();
          openTaskDetailForm();
        };
      }

      // Setup global Create New button handler
      const btnCreateNewGlobal = document.getElementById("btn-create-new-complaint");
      if (btnCreateNewGlobal) {
        btnCreateNewGlobal.onclick = () => {
          // Reset to submit mode for creating new complaint, preserving task context
          data = {
            ...data,
            Mode: "submit",
            ComplaintID: null,
            ProposedDueDate: null,
            ComplaintReason: "",
            Approve_Status: 1,
            CreatorName: "",
            CreatedDate: null,
            ApprovedBy: null,
            ApproverName: null,
            ApprovedDate: null,
            ApprovalNote: null,
            RejectionNote: "",
            CanApprove: 0,
          };
          selectedType = 1;

          // Clear control values
          setControlVal("019E42EB6ECB70F3A08D659D244C9533", null);
          setControlVal("019E42EB6ECB76C5A4155B25A04CBB49", "");

          if (InstanceFileURLP75A67EB5C0AD4D899DBEAB3F52C6B2FA) {
            InstanceFileURLP75A67EB5C0AD4D899DBEAB3F52C6B2FA.option("value", []);
            InstanceFileURLP75A67EB5C0AD4D899DBEAB3F52C6B2FA.option("dataSource", []);
          }

          initFormUI();

          // Hide history tab to focus on form
          const tabButtons = document.querySelectorAll("#sp_Task_ComplaintForm_html .tab-btn");
          const tabContents = document.querySelectorAll("#sp_Task_ComplaintForm_html .tab-content");
          tabButtons.forEach((b) => b.classList.remove("active"));
          tabContents.forEach((c) => c.classList.remove("active"));

          const formTab = document.querySelector("#sp_Task_ComplaintForm_html .tab-btn[data-tab=''tab-form'']");
          if (formTab) {
            formTab.classList.add("active");
            document.getElementById("tab-form").classList.add("active");
          }
        };
      }

      // Setup global Cancel request button handler
      const btnCancelGlobal = document.getElementById("btn-cancel-request");
      if (btnCancelGlobal) {
        btnCancelGlobal.onclick = () => {
          showConfirmPopup({
            title: "Xác nhận hủy đơn",
            message: "Bạn có chắc chắn muốn hủy đơn khiếu nại này?",
            YesText: "Hủy",
            NoText: "Quay lại",
            onYes: () => {
              // Call resolve API with status 4 (Cancelled)
              if (typeof AjaxHPAParadise !== "undefined") {
                AjaxHPAParadise({
                  data: {
                    name: "sp_Task_Complaint_Resolve",
                    param: [
                      "ComplaintID",
                      data.ComplaintID,
                      "LoginID",
                      loginID,
                      "ApprovedStatus",
                      4,
                      "ReviewNote",
                      "Người dùng tự hủy đơn khiếu nại.",
                      "FinalDueDate",
                      null,
                    ],
                  },
                  success: function (res) {
                    try {
                      const json = typeof res === "string" ? JSON.parse(res) : res;
                      const result = json.data && json.data[0] ? json.data[0][0] : {};
                      if (result.Status === "SUCCESS") {
                        showAlert("success", "Đơn đã được hủy thành công!");
                        fetchComplaintDetails(data.ComplaintID, data.HistoryID, selectedType);
                      } else {
                        showAlert("error", result.Message || "Lỗi hủy đơn.");
                      }
                    } catch (e) {
                      showAlert("error", "Lỗi xử lý kết quả hủy đơn.");
                    }
                  },
                  error: function () {
                    showAlert("error", "Lỗi kết nối máy chủ để hủy đơn.");
                  },
                });
              } else {
                showAlert("success", "Đơn đã được hủy thành công! (Môi trường offline)");
                data.Approve_Status = 4;
                initFormUI();
              }
            }
          });
        };
      }

      // instance: DevExpress dxSelectBox instance (let variable, NOT window[name])
      // value: giá trị cần chọn
      // displayVal: tên hiển thị (dùng khi item chưa có trong datasource)
      // loadedKey: window[loadedKey] === true khi datasource đã load xong
      // dataSourceKey: window[dataSourceKey] = mảng dữ liệu
      // disabled: set disabled state sau khi apply value
      function ensureSelectBoxLoaded(instance, value, displayVal, loadedKey, dataSourceKey, disabled) {
        if (!instance) {
          console.warn("[ensureSelectBoxLoaded] instance chưa sẵn sàng");
          return;
        }

        // Disabled ngay lập tức — không cần chờ datasource load xong
        if (disabled !== undefined) instance.option("disabled", disabled);

        function applyValue() {
          if (window[loadedKey] !== true) return;

          let ds = instance.option("dataSource");
          let items = [];
          if (ds) {
            if (ds instanceof DevExpress.data.DataSource) {
              items = ds.store()._array || [];
            } else if (Array.isArray(ds)) {
              items = ds;
            } else if (ds.store && typeof ds.store === ''function'') {
              items = ds.store()._array || [];
            }
          } else {
            items = window[dataSourceKey] || [];
          }

          const exists = items.some(item => String(item.ID) === String(value));
          if (!exists && value && displayVal) {
            const newItem = { ID: value, Name: displayVal };
            if (ds instanceof DevExpress.data.DataSource) {
              ds.store().insert(newItem).then(() => {
                ds.reload().then(() => {
                  instance.option("value", value);
                  if (disabled !== undefined) instance.option("disabled", disabled);
                });
              });
            } else if (Array.isArray(ds)) {
              ds.push(newItem);
              instance.option("dataSource", ds);
              instance.option("value", value);
              if (disabled !== undefined) instance.option("disabled", disabled);
            } else {
              window[dataSourceKey] = window[dataSourceKey] || [];
              window[dataSourceKey].push(newItem);
              instance.option("dataSource", window[dataSourceKey]);
              instance.option("value", value);
              if (disabled !== undefined) instance.option("disabled", disabled);
            }
          } else {
            instance.option("value", value);
            if (disabled !== undefined) instance.option("disabled", disabled);
          }
        }

        if (window[loadedKey] === true) {
          // DataSource đã load xong — áp dụng ngay
          applyValue();
        } else {
          // DataSource chưa load — đăng ký setter trên window[loadedKey]
          let _loadedVal = window[loadedKey];
          Object.defineProperty(window, loadedKey, {
            configurable: true,
            enumerable: true,
            get() { return _loadedVal; },
            set(v) {
              _loadedVal = v;
              Object.defineProperty(window, loadedKey, {
                configurable: true, enumerable: true,
                writable: true, value: v
              });
              if (v === true) applyValue();
            }
          });
        }
      }

      function initFormUI() {
        // Set current deadline value
        const formattedOldDueDate = formatDateTime(data.OldDueDate);
        setControlVal("019E42EB6ECB72988DACC5334048AD51", formattedOldDueDate);
        setControlDisabled("019E42EB6ECB72988DACC5334048AD51", true);

        // Render Rejection note from supervisor if present
        if (
          data.RejectionNote &&
          data.RejectionNote !== "Không có nội dung lý do cụ thể."
        ) {
          rejectionText.innerText = data.RejectionNote;
          rejectionBanner.style.display = "block";
        } else {
          rejectionBanner.style.display = "none";
        }

        // Render Approval Flow
        renderApprovalFlow();

        // Task Selectbox — truyền instance trực tiếp (là let trong cùng IIFE scope)
        document.getElementById("group-task-select").style.display = "block";
        if (data.Mode === "view" || urlHistoryID) {
          ensureSelectBoxLoaded(InstanceTaskIDP3B400D95FDB64B7F8DCE8FB445CF5E15, data.HistoryID, data.TaskName, "TaskIDDataSourceLoaded", "DataSource_TaskID", true);
        } else {
          if (data.HistoryID) {
            ensureSelectBoxLoaded(InstanceTaskIDP3B400D95FDB64B7F8DCE8FB445CF5E15, data.HistoryID, data.TaskName, "TaskIDDataSourceLoaded", "DataSource_TaskID", false);
          }
          setupTaskSelectboxListener();
        }

        // MODE Setup
        // Reset visibility of all mode-dependent panels first to avoid mixture of states
        submitActions.style.display = "none";
        reviewActions.style.display = "none";
        closeActions.style.display = "none";
        resolutionPanel.style.display = "none";
        if (managerStatusRow) managerStatusRow.style.display = "none";

        if (data.Mode === "submit") {
          // Hide approval flow in submit mode (not submitted yet)
          document.getElementById("group-approval-flow").style.display = "none";

          typeSelectWrapper.style.display = "block";
          typeTextReadonly.style.display = "none";
          submitActions.style.display = "block";

          ensureSelectBoxLoaded(InstanceComplaintTypePF824852E41004F53B87E683F9ACDEE09, selectedType, selectedType === 2 ? "Khiếu nại từ chối duyệt" : "Gia hạn thời gian hoàn thành", "ComplaintTypeDataSourceLoaded", "DataSource_ComplaintType", false);

          // Hide/Show proposed date based on initial selectedType
          if (selectedType === 2) {
            colProposedDate.style.visibility = "hidden";
          } else {
            colProposedDate.style.visibility = "visible";
          }

          // Dropdown change listener — instance là let trong cùng scope
          if (InstanceComplaintTypePF824852E41004F53B87E683F9ACDEE09) {
            InstanceComplaintTypePF824852E41004F53B87E683F9ACDEE09.option("onValueChanged", function (e) {
              selectedType = parseInt(e.value);
              if (selectedType === 2) {
                colProposedDate.style.visibility = "hidden";
              } else {
                colProposedDate.style.visibility = "visible";
              }
            });
          }

          // Setup proposed due date default value (Current Due Date + 3 days)
          if (data.OldDueDate) {
            const defaultDate = new Date(data.OldDueDate);
            defaultDate.setDate(defaultDate.getDate() + 3);
            if (!isNaN(defaultDate.getTime())) {
              setControlVal("019E42EB6ECB70F3A08D659D244C9533", defaultDate);
            }
          }

          // Enable reason and proposed date inputs
          setControlDisabled("019E42EB6ECB70F3A08D659D244C9533", false);
          setControlDisabled("019E42EB6ECB76C5A4155B25A04CBB49", false);
          setControlDisabled("019E42EB6ECE77848FEF1C6C394FBA2C", false);

          // Reset Rich Text Editor explicitly
          const rteElement = document.getElementById("editor-P509F121B87BF45788C3587BD5C5A539A");
          if (rteElement) {
            rteElement.setAttribute("contenteditable", "true");
            rteElement.style.opacity = "";
            rteElement.style.pointerEvents = "";
          }

          // Enable file uploader and show select button
          const fileUploaderElement = document.getElementById("P75A67EB5C0AD4D899DBEAB3F52C6B2FA");
          if (fileUploaderElement) {
            const selectButton = fileUploaderElement.querySelector(".dx-button") || fileUploaderElement.querySelector("[class*=''dx-button'']");
            if (selectButton) {
              selectButton.style.display = "";
            }
            const dragDropArea = fileUploaderElement.querySelector(".dx-fileuploader-dxuploadarea") || fileUploaderElement.querySelector("[class*=''dx-uploadarea'']");
            if (dragDropArea) {
              dragDropArea.style.pointerEvents = "";
              dragDropArea.style.opacity = "";
            }
          }

          // Submit handler
          document.getElementById("btn-confirm-submit").onclick =
            submitComplaint;
        } else {
          // VIEW / RESOLVE Mode
          // Show approval flow in view mode
          document.getElementById("group-approval-flow").style.display = "block";

          typeSelectWrapper.style.display = "block";
          typeTextReadonly.style.display = "none";

          ensureSelectBoxLoaded(InstanceComplaintTypePF824852E41004F53B87E683F9ACDEE09, selectedType, selectedType === 2 ? "Khiếu nại từ chối duyệt" : "Gia hạn thời gian hoàn thành", "ComplaintTypeDataSourceLoaded", "DataSource_ComplaintType", true);

          // Set reason and disable control (including Rich Text Editor)
          setControlVal("019E42EB6ECB76C5A4155B25A04CBB49", data.ComplaintReason || "Không có nội dung lý do khiếu nại.");
          setControlDisabled("019E42EB6ECB76C5A4155B25A04CBB49", true);

          // Also disable the rich text editor directly
          const rteElement = document.getElementById("editor-P509F121B87BF45788C3587BD5C5A539A");
          if (rteElement) {
            rteElement.setAttribute("contenteditable", "false");
            rteElement.style.opacity = "0.6";
            rteElement.style.pointerEvents = "none";
          }

          // Disable file uploader and hide select button
          setControlDisabled("019E42EB6ECE77848FEF1C6C394FBA2C", true);

          // Hide file upload select button in view mode
          const fileUploaderElement = document.getElementById("P75A67EB5C0AD4D899DBEAB3F52C6B2FA");
          if (fileUploaderElement) {
            // Hide select file button
            const selectButton = fileUploaderElement.querySelector(".dx-button") || fileUploaderElement.querySelector("[class*=''dx-button'']");
            if (selectButton) {
              selectButton.style.display = "none";
            }
            // Disable drag-drop area
            const dragDropArea = fileUploaderElement.querySelector(".dx-fileuploader-dxuploadarea") || fileUploaderElement.querySelector("[class*=''dx-uploadarea'']");
            if (dragDropArea) {
              dragDropArea.style.pointerEvents = "none";
              dragDropArea.style.opacity = "0.5";
            }
          }

          if (selectedType === 1) {
            colProposedDate.style.visibility = "visible";
            setControlVal("019E42EB6ECB70F3A08D659D244C9533", data.ProposedDueDate);
            setControlDisabled("019E42EB6ECB70F3A08D659D244C9533", true);
          } else {
            colProposedDate.style.visibility = "hidden";
          }

          // Display elements based on Approve Status
          const status = parseInt(data.Approve_Status) || 1; // 1 = Pending, 2 = Approved, 3 = Rejected

          if (status === 1) {
            // Pending: Check if user has approval authority
            if (parseInt(data.CanApprove) === 1) {
              reviewActions.style.display = "block";

              if (selectedType === 1) {
                // ProposedDueDate control will be used for resolve date
                if (data.ProposedDueDate) {
                  const pDate = new Date(data.ProposedDueDate);
                  if (!isNaN(pDate.getTime())) {
                    setControlVal("019E42EB6ECB70F3A08D659D244C9533", pDate);
                  }
                }
              }

              document.getElementById("btn-resolve-approve").onclick = () =>
                resolveComplaint(2);
              document.getElementById("btn-resolve-reject").onclick = () =>
                resolveComplaint(3);
            } else {
              // Just viewing pending complaint: show Close button
              closeActions.style.display = "block";
            }
          } else {
            // Already Approved or Rejected: show Resolution Panel and Close button
            resolutionPanel.style.display = "block";
            closeActions.style.display = "block";

            if (status === 2) {
              closeActions.style.display = "flex";
              resolutionPanel.className = "resolution-panel approved";
              resolutionPanelTitle.innerHTML = ''<i class="bi bi-check-circle-fill"></i> Ý kiến phản hồi của người duyệt (Đồng ý)'';
            } else {
              resolutionPanel.className = "resolution-panel rejected";
              resolutionPanelTitle.innerHTML = ''<i class="bi bi-x-circle-fill"></i> Ý kiến phản hồi của người duyệt (Từ chối)'';
            }

            resolutionNoteEl.innerText = data.ApprovalNote || "Không có ý kiến phản hồi.";
            reviewerEl.innerText = data.ApproverName || "";
            revieweddateEl.innerText = formatDateTime(data.ApprovedDate);
          }

          // Display Cancel and Create New buttons correctly on direct load
          const btnCancel = document.getElementById("btn-cancel-request");
          const btnCreateNew = document.getElementById("btn-create-new-complaint");

          if (parseInt(data.CanApprove) === 1 && status === 1) {
            closeActions.style.display = "none";
          } else {
            closeActions.style.display = "flex";
            if (status === 2) {
              // Approved: Show both Cancel and Create New
              if (btnCancel) btnCancel.style.display = "inline-block";
              if (btnCreateNew) btnCreateNew.style.display = "inline-block";
            } else {
              // Other statuses: Show only Create New
              if (btnCancel) btnCancel.style.display = "none";
              if (btnCreateNew) btnCreateNew.style.display = "inline-block";
            }
          }

          // Display Manager status badge if current user has already approved/rejected
          let myStage = null;
          if (data.ApprovalStages) {
            try {
              const stages = typeof data.ApprovalStages === "string" ? JSON.parse(data.ApprovalStages) : data.ApprovalStages;
              if (Array.isArray(stages)) {
                const currentEmpID = data.CurrentEmployeeID;
                if (currentEmpID) {
                  myStage = stages.find(s => s.ApproverID === currentEmpID || s.approverID === currentEmpID);
                }
              }
            } catch (e) {
              console.error(e);
            }
          }

          if (myStage) {
            const myStatus = parseInt(myStage.ApprovalStatus !== undefined ? myStage.ApprovalStatus : (myStage.approvalStatus !== undefined ? myStage.approvalStatus : (myStage.approvalstatus !== undefined ? myStage.approvalstatus : 0))) || 0;
            if (myStatus !== 0) {
              // Special case: If this is an appeal rejection (selectedType = 2), it is currently Pending (status = 1),
              // and the current user has approval capability (CanApprove = 1), then they should be allowed to approve/reject again.
              // We do not hide the approval buttons in this scenario.
              const isPendingAppeal = (status === 1 && selectedType === 2 && parseInt(data.CanApprove) === 1);

              if (!isPendingAppeal) {
                if (managerStatusRow && managerStatusBadgeEl) {
                  managerStatusRow.style.display = "flex";
                  if (myStatus === 1) {
                    managerStatusBadgeEl.className = "manager-status-badge approved";
                    managerStatusBadgeEl.innerHTML = ''<i class="bi bi-check-circle-fill"></i> Bạn đã duyệt'';
                  } else if (myStatus === 2) {
                    managerStatusBadgeEl.className = "manager-status-badge rejected";
                    managerStatusBadgeEl.innerHTML = ''<i class="bi bi-x-circle-fill"></i> Bạn đã từ chối'';
                  }
                }
                // Hide approval buttons and enable close/create actions since the manager has already acted
                reviewActions.style.display = "none";
                closeActions.style.display = "flex";
                if (btnCancel) btnCancel.style.display = "none";
                if (btnCreateNew) btnCreateNew.style.display = "inline-block";
              } else {
                // If it is a pending appeal, display a banner indicating their prior rejection but allow them to take action.
                if (managerStatusRow && managerStatusBadgeEl) {
                  managerStatusRow.style.display = "flex";
                  managerStatusBadgeEl.className = "manager-status-badge rejected";
                  managerStatusBadgeEl.innerHTML = ''<i class="bi bi-x-circle-fill"></i> Bạn đã từ chối trước đó (Đang khiếu nại)'';
                }
                reviewActions.style.display = "block";
                closeActions.style.display = "none";
              }
            }
          }
        }
      }

      // Tab Switching Logic
      const tabButtons = document.querySelectorAll(
        "#sp_Task_ComplaintForm_html .tab-btn",
      );
      const tabContents = document.querySelectorAll(
        "#sp_Task_ComplaintForm_html .tab-content",
      );

      tabButtons.forEach((btn) => {
        btn.onclick = () => {
          tabButtons.forEach((b) => b.classList.remove("active"));
          tabContents.forEach((c) => c.classList.remove("active"));

          btn.classList.add("active");
          const targetTabId = btn.getAttribute("data-tab");
          document.getElementById(targetTabId).classList.add("active");

          if (targetTabId === "tab-history") {
            loadHistory();
          }
        };
      });

      function utf16_le_to_b64(str) {
        if (!str) return "";
        try {
          let binary = "";
          let len = str.length;
          for (let i = 0; i < len; i++) {
            let code = str.charCodeAt(i);
            binary += String.fromCharCode(code & 0xFF, (code >>> 8) & 0xFF);
          }
          return window.btoa(binary);
        } catch (e) { return ""; }
      }

      // Submit new complaint
      function submitComplaint() {
        // Show confirmation popup before submitting
        showConfirmPopup({
          title: "Xác nhận gửi đơn",
          message: "Bạn có chắc chắn muốn gửi đơn khiếu nại này? Sau khi gửi, đơn sẽ được gửi đến cấp trên duyệt.",
          YesText: "Gửi",
          NoText: "Hủy",
          onYes: () => {
            performSubmitComplaint();
          },
          onNo: () => {
            console.log("Người dùng đã hủy gửi đơn");
          }
        });
      }

      // Perform the actual complaint submission after confirmation
      function performSubmitComplaint() {
        const reason = rteObj_ComplaintReasonP509F121B87BF45788C3587BD5C5A539A.getHtml();
        const resasonStandard = getStandardHtml_ComplaintReasonP509F121B87BF45788C3587BD5C5A539A(reason);
        const resolvedReason = utf16_le_to_b64_ComplaintReasonP509F121B87BF45788C3587BD5C5A539A(resasonStandard);
        const proposedDate = getControlVal("019E42EB6ECB70F3A08D659D244C9533");

        if (!reason || reason == `<div class="editor-block"><br></div>`) {
          showAlert("warning", "Vui lòng nhập lý do đề nghị khiếu nại!");
          return;
        }

        if (selectedType === 1 && !proposedDate) {
          showAlert("warning", "Vui lòng chọn hạn chót đề xuất gia hạn!");
          return;
        }

        // Call stored procedure via Ajax
        if (typeof AjaxHPAParadise !== "undefined") {
          AjaxHPAParadise({
            data: {
              name: "sp_Task_Complaint_Submit",
              param: [
                "HistoryID",
                data.HistoryID,
                "LoginID",
                loginID,
                "ComplaintReason",
                resolvedReason,
                "ProposedDueDate",
                selectedType === 1 ? proposedDate : null,
                "ComplaintType",
                selectedType,
                "TempComplaintID",
                currentRecordID_Temp_ComplaintID
              ],
            },
            success: function (res) {
              try {
                const json = typeof res === "string" ? JSON.parse(res) : res;
                const result = json.data && json.data[0] ? json.data[0][0] : {};
                if (result && result.ComplaintID) {
                  showAlert(
                    "success",
                    "Gửi đơn khiếu nại thành công!",
                  );

                  // Get newly created ComplaintID from procedure response
                  const newComplaintID = result.ComplaintID;

                  // Save uploaded files with the ComplaintID (only if files are selected)
                  if (newComplaintID) {
                    try {
                      const filesSelected = getControlVal("019E42EB6ECE77848FEF1C6C394FBA2C");
                      if (filesSelected && filesSelected.length > 0) {
                        save_P75A67EB5C0AD4D899DBEAB3F52C6B2FA();
                      }
                    } catch (err) {
                      console.error("Error saving files:", err);
                    }
                  }

                  data.ProposedDueDate = getControlVal("019E42EB6ECB70F3A08D659D244C9533");
                  data.ComplaintReason = getControlVal("019E42EB6ECB76C5A4155B25A04CBB49");

                  // Chuyển mode thành view - dùng data có sẵn
                  data.Mode = "view";
                  data.ComplaintID = newComplaintID;
                  data.Approve_Status = 1; // Chờ duyệt

                  // Set tất cả approval stages là pending (status = 0)
                  if (data.ApprovalStages && typeof data.ApprovalStages === "string") {
                    data.ApprovalStages = JSON.parse(data.ApprovalStages);
                  }
                  if (Array.isArray(data.ApprovalStages)) {
                    data.ApprovalStages.forEach(stage => {
                      stage.ApprovalStatus = 0; // Pending
                      stage.approvalStatus = 0;
                      stage.approvalstatus = 0;
                    });
                  }

                  // Re-render form: disable controls + hiển thị approval chain với status pending
                  initFormUI();
                } else {
                  showAlert(
                    "error",
                    result.Message || "Có lỗi xảy ra khi gửi đơn.",
                  );
                }
              } catch (e) {
                showAlert("error", "Lỗi xử lý phản hồi từ hệ thống.");
              }
            },
            error: function () {
              showAlert("error", "Lỗi kết nối máy chủ để gửi đơn khiếu nại.");
            },
          });
        } else {
          // Mock Submit Success (Offline mode)
          showAlert(
            "success",
            "Gửi đơn đề nghị thành công! (Môi trường offline)",
          );

          // Chuyển mode thành view - dùng data có sẵn
          data.Mode = "view";
          data.Approve_Status = 1; // Chờ duyệt

          // Set tất cả approval stages là pending (status = 0)
          if (data.ApprovalStages && typeof data.ApprovalStages === "string") {
            data.ApprovalStages = JSON.parse(data.ApprovalStages);
          }
          if (Array.isArray(data.ApprovalStages)) {
            data.ApprovalStages.forEach(stage => {
              stage.ApprovalStatus = 0; // Pending
              stage.approvalStatus = 0;
              stage.approvalstatus = 0;
            });
          }

          // Re-render form: disable controls + hiển thị approval chain với status pending
          initFormUI();
        }
      }

      // Resolve complaint (Approve or Reject)
      function resolveComplaint(statusID) {
        const reviewNote = document
          .getElementById("textarea-review-note")
          .value.trim();
        let finalDueDate = getControlVal("019E42EB6ECB70F3A08D659D244C9533");

        if (statusID === 3 && !reviewNote) {
          showAlert("warning", "Vui lòng nhập lý do từ chối giải quyết đơn!");
          return;
        }

        // Convert date object to proper datetime format if provided
        if (finalDueDate && selectedType === 1) {
          if (finalDueDate instanceof Date) {
            // Convert Date object to SQL datetime format
            finalDueDate = finalDueDate.toISOString().slice(0, 19).replace(''T'', '' '');
          } else if (typeof finalDueDate === ''string'' && finalDueDate.length === 10) {
            // If it''s just a date string (YYYY-MM-DD), add time
            finalDueDate = finalDueDate + " 00:00:00";
          }
        } else {
          // If no date provided or not deadline extension, set to null
          finalDueDate = null;
        }

        if (typeof AjaxHPAParadise !== "undefined") {
          AjaxHPAParadise({
            data: {
              name: "sp_Task_Complaint_Resolve",
              param: [
                "ComplaintID",
                data.ComplaintID,
                "LoginID",
                loginID,
                "ApprovedStatus",
                statusID,
                "ReviewNote",
                reviewNote,
                "FinalDueDate",
                selectedType === 1 ? finalDueDate : null,
              ],
            },
            success: function (res) {
              try {
                const json = typeof res === "string" ? JSON.parse(res) : res;
                const result = json.data && json.data[0] ? json.data[0][0] : {};
                if (result.Status === "SUCCESS") {
                  showAlert(
                    "success",
                    result.Message || "Xử lý khiếu nại thành công!",
                  );
                  // Refresh form details instead of closing
                  fetchComplaintDetails(data.ComplaintID, data.HistoryID, selectedType);
                } else {
                  showAlert("error", result.Message || "Lỗi xử lý khiếu nại.");
                }
              } catch (e) {
                showAlert("error", "Lỗi đọc dữ liệu kết quả phê duyệt.");
              }
            },
            error: function () {
              showAlert("error", "Lỗi kết nối máy chủ để phê duyệt khiếu nại.");
            },
          });
        } else {
          // Mock Resolve Success
          showAlert(
            "success",
            `Đã ${statusID === 2 ? "phê duyệt" : "từ chối"} khiếu nại thành công! (Môi trường offline)`,
          );
          data.Approve_Status = statusID;
          initFormUI();
        }
      }

      // Close Form logic
      function closeForm() {
        if (typeof closeCurrentForm === "function") {
          closeCurrentForm();
        } else if (
          window.parent &&
          typeof window.parent.closeCurrentForm === "function"
        ) {
          window.parent.closeCurrentForm();
        } else {
          alert("Quay lại danh sách khiếu nại.");
        }
      }

      // Dynamic History List Loading
      let historyData = [];
      let activeFilterStatus = -1;
      let searchQuery = "";

      let currentPage = 1;
      const itemsPerPage = 10;
      let isLoadingMore = false;

      const filterButtons = document.querySelectorAll(
        "#history-filter-tabs .filter-btn",
      );
      filterButtons.forEach((btn) => {
        btn.onclick = () => {
          filterButtons.forEach((b) => b.classList.remove("active"));
          btn.classList.add("active");
          activeFilterStatus = parseInt(btn.getAttribute("data-status"));
          currentPage = 1; // Reset pagination on filter
          renderHistory();
        };
      });

      const searchInput = document.getElementById("search-history-input");
      searchInput.oninput = (e) => {
        searchQuery = e.target.value.toLowerCase().trim();
        renderHistory();
      };

      function loadHistory() {
        const container = document.getElementById("history-items-container");
        container.innerHTML = `
              <div style="text-align: center; padding: 32px; color: var(--paradise-fg-2);">
                <i class="bi bi-arrow-repeat paradise-spin" style="font-size: 24px; margin-bottom: 8px;"></i>
                <p>Đang tải danh sách lịch sử...</p>
              </div>
            `;

        if (typeof AjaxHPAParadise !== "undefined") {
          AjaxHPAParadise({
            data: {
              name: "sp_Task_Complaint_GetDataList",
              param: [
                "LoginID",
                loginID,
                "LanguageID",
                lang,
                "StatusFilter",
                -1, // Fetch all, client filters
              ],
            },
            success: function (res) {
              try {
                const json = typeof res === "string" ? JSON.parse(res) : res;
                const rows = json.data && json.data[0] ? json.data[0] : [];
                historyData = rows || [];
              } catch (e) {
                historyData = [];
              }
              renderHistory();
            },
            error: function () {
              historyData = [];
              renderHistory();
            },
          });
        } else {
          // Offline empty fallback
          setTimeout(() => {
            historyData = [];
            renderHistory();
          }, 400);
        }
      }

      function renderHistory() {
        const container = document.getElementById("history-items-container");
        if (currentPage === 1) {
          container.innerHTML = "";
        }

        const filtered = historyData.filter((item) => {
          // Restrict to own complaints only (CreatorLoginID matches loginID)
          if (item.CreatorLoginID !== undefined && item.CreatorLoginID !== null) {
            if (parseInt(item.CreatorLoginID) !== parseInt(loginID)) {
              return false;
            }
          }

          // Status filter
          if (
            activeFilterStatus !== -1 &&
            item.Approve_Status !== activeFilterStatus
          )
            return false;

          // Search query filter
          if (searchQuery) {
            const matchesTask =
              item.TaskName &&
              item.TaskName.toLowerCase().includes(searchQuery);
            const matchesReason =
              item.ComplaintReason &&
              item.ComplaintReason.toLowerCase().includes(searchQuery);
            return matchesTask || matchesReason;
          }
          return true;
        });

        if (filtered.length === 0 && currentPage === 1) {
          container.innerHTML = `
                <div class="history-empty">
                  <i class="bi bi-folder2-open"></i>
                  <p>Không tìm thấy dữ liệu khiếu nại nào</p>
                </div>
              `;
          document.getElementById("history-pagination").innerHTML = "";
          return;
        }

        // Pagination logic
        const startIdx = (currentPage - 1) * itemsPerPage;
        const endIdx = startIdx + itemsPerPage;
        const pageItems = filtered.slice(startIdx, endIdx);

        pageItems.forEach((item) => {
          const card = document.createElement("div");
          card.className = "history-card";

          let statusText = "Chờ duyệt";
          let statusClass = "pending";
          let statusIcon = ''<i class="bi bi-hourglass-split"></i>'';

          if (item.Approve_Status === 2) {
            statusText = "Đồng ý";
            statusClass = "approved";
            statusIcon = ''<i class="bi bi-check-circle-fill"></i>'';
          } else if (item.Approve_Status === 3) {
            statusText = "Từ chối";
            statusClass = "rejected";
            statusIcon = ''<i class="bi bi-x-circle-fill"></i>'';
          }

          const typeText =
            parseInt(item.ComplaintType) === 2
              ? "Khiếu nại từ chối"
              : "Gia hạn";
          const typeClass =
            parseInt(item.ComplaintType) === 2 ? "rejected" : "approved";

          card.innerHTML = `
                <div class="history-card-header">
                  <h4 class="history-card-title">${item.TaskName}</h4>
                  <span class="status-badge ${statusClass}">${statusIcon} ${statusText}</span>
                </div>
                <div class="history-card-body">
                  <div class="history-meta-item" style="grid-column: 1 / -1;">
                    <i class="bi bi-tag"></i>
                    <span class="history-meta-label">Loại đơn:</span>
                    <span style="font-weight: 700; color: ${parseInt(item.ComplaintType) === 2 ? "var(--paradise-color-danger)" : "var(--paradise-color-primary)"}">${typeText}</span>
                  </div>

                  <div class="history-meta-item">
                    <i class="bi bi-calendar-date"></i>
                    <span class="history-meta-label">Hạn chót cũ:</span>
                    <strong style="${item.Approve_Status === 2 ? ''text-decoration: line-through; opacity: 0.6;'' : ''''}">${formatDateTime(item.OldDueDate)}</strong>
                  </div>

                  ${item.ProposedDueDate
              ? `
                  <div class="history-meta-item">
                    <i class="bi bi-calendar-check"></i>
                    <span class="history-meta-label">Đề xuất mới:</span>
                    <strong class="text-success">${formatDateTime(item.ProposedDueDate)}</strong>
                  </div>
                  `
              : ""
            }

                  <!-- Expanded Approval Details Panel -->
                  <div class="history-card-detail-panel">
                    <div class="detail-panel-grid">
                      <div class="history-meta-item">
                        <i class="bi bi-person-badge"></i>
                        <span class="history-meta-label">Người duyệt:</span>
                        <strong>${item.ApproverName || item.RequesterName || "-"}</strong>
                      </div>
                      <div class="history-meta-item">
                        <i class="bi bi-calendar-check"></i>
                        <span class="history-meta-label">Ngày duyệt:</span>
                        <strong>${item.ApprovedDate ? formatDateTime(item.ApprovedDate) : "-"}</strong>
                      </div>
                      ${item.ApprovalNote
              ? `
                      <div class="history-reason-box" style="grid-column: 1 / -1; border-left-color: ${item.Approve_Status === 2 ? "var(--paradise-color-success)" : "var(--paradise-color-danger)"}; margin-top: 8px;">
                        <strong>Phản hồi của người duyệt:</strong> ${item.ApprovalNote}
                      </div>
                      `
              : ""
            }
                    </div>
                  </div>
                </div>
              `;

          // Handle click to load complaint details
          card.onclick = () => {
            loadComplaintFromHistory(item.ComplaintID, item.HistoryID, item.ComplaintType);
          };

          container.appendChild(card);
        });

        // Infinite scroll: Load more button
        if (endIdx < filtered.length) {
          const loadMoreBtn = document.createElement("button");
          loadMoreBtn.className = "btn-submit";
          loadMoreBtn.style.marginTop = "24px";
          loadMoreBtn.innerHTML = ''<i class="bi bi-arrow-down" style="margin-right: 8px;"></i>Tải thêm'';
          loadMoreBtn.onclick = (e) => {
            e.preventDefault();
            currentPage++;
            renderHistory();
          };
          container.appendChild(loadMoreBtn);
        }

        // Hide pagination
        document.getElementById("history-pagination").innerHTML = "";
      }

      // Dynamic Approver Node Builder
      function renderApprovalFlow() {
        const container = document.getElementById("approval-flow-container");
        container.innerHTML = "";

        let stages = [];
        if (data.ApprovalStages) {
          try {
            stages =
              typeof data.ApprovalStages === "string"
                ? JSON.parse(data.ApprovalStages)
                : data.ApprovalStages;
          } catch (e) {
            console.error("Error parsing approval stages:", e);
          }
        }

        if (!Array.isArray(stages) || stages.length === 0) {
          // Default single stage using task requester
          container.innerHTML = `
                <div class="approver-node">
                  <div class="approver-avatar-wrapper">
                    ${window.DEFAULT_AVATAR_SVG || `<svg viewBox="0 0 24 24" width="70%" height="70%" fill="none" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" /></svg>`}
                  </div>
                  <div class="approver-info">
                    <div class="approver-name">${data.RequesterName || "Người giao việc"}</div>
                    <div class="approver-code">[Người duyệt]</div>
                  </div>
                </div>
              `;
          return;
        }

        // Render each stage in sequence
        stages.forEach((stage, idx) => {
          const node = document.createElement("div");
          node.className = "approver-node";

          const status = parseInt(stage.ApprovalStatus !== undefined ? stage.ApprovalStatus : (stage.approvalStatus !== undefined ? stage.approvalStatus : (stage.approvalstatus !== undefined ? stage.approvalstatus : 0))) || 0;
          const approverName = stage.ApproverName || stage.approverName || "";
          const approverID = stage.ApproverID || stage.approverID || "";
          const stageOrder = stage.StageOrder !== undefined ? stage.StageOrder : (stage.stageOrder !== undefined ? stage.stageOrder : idx + 1);
          const approvalNote = stage.ApprovalNote || stage.Note || stage.note || "";
          const paramImg = stage.paramImg || stage.paramimg || "";

          let borderStyle = "2px solid var(--paradise-color-warning)"; // Default: Pending (Amber/Orange)
          if (status === 0) {
            borderStyle = "2px solid var(--paradise-color-warning)"; // Pending - Orange/Amber
          } else if (status === 1) {
            borderStyle = "2px solid var(--paradise-color-primary)"; // Approved - Green
          } else if (status === 2) {
            borderStyle = "2px solid var(--paradise-color-danger)"; // Rejected - Red
          } else if (status === 4) {
            borderStyle = "2px solid var(--paradise-fg-2)"; // Cancelled - Gray
          } else if (status === 5) {
            borderStyle = "2px solid #9333ea"; // Cancellation Request - Purple
          }

          const cachedUrl = window.GlobalEmployeeAvatarCache && window.GlobalEmployeeAvatarCache[approverID];

          // Render approver avatar wrapper
          const avatarWrapper = document.createElement("div");
          avatarWrapper.className = "approver-avatar-wrapper";
          avatarWrapper.style.border = borderStyle;
          avatarWrapper.setAttribute("data-emp-id", approverID);
          avatarWrapper.setAttribute("title", `${approverID} - ${approverName}`);
          avatarWrapper.style.cursor = "pointer";

          if (cachedUrl) {
            // Nếu đã có cache → render blob image ngay
            avatarWrapper.innerHTML = `
                  <img src="${cachedUrl}" style="width: 100%; height: 100%; border-radius: 50%; object-fit: cover;" />
                `;
          } else {
            // Nếu chưa → render SVG default từ biến global
            avatarWrapper.innerHTML = window.DEFAULT_AVATAR_SVG || `<svg viewBox="0 0 24 24" width="70%" height="70%" fill="none" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" /></svg>`;
          }

          const approverInfo = document.createElement("div");
          approverInfo.className = "approver-info";
          approverInfo.innerHTML = `
                <div class="approver-name">${approverName}</div>
                <div class="approver-code">[Cấp ${stageOrder}]</div>
              `;

          node.appendChild(avatarWrapper);
          node.appendChild(approverInfo);

          // Add status badge under approver node
          const statusBadge = document.createElement("div");
          statusBadge.style.marginTop = "8px";
          statusBadge.style.fontSize = "11px";
          statusBadge.style.fontWeight = "600";
          statusBadge.style.textTransform = "uppercase";
          statusBadge.style.padding = "3px 10px";
          statusBadge.style.borderRadius = "12px";
          statusBadge.style.whiteSpace = "nowrap";

          if (status === 0) {
            statusBadge.innerHTML = "Chờ duyệt";
            statusBadge.className = "approver-status-badge pending";
          } else if (status === 1) {
            statusBadge.innerHTML = "Đã duyệt";
            statusBadge.className = "approver-status-badge approved";
          } else if (status === 2) {
            statusBadge.innerHTML = "Từ chối";
            statusBadge.className = "approver-status-badge rejected";
          } else if (status === 4) {
            statusBadge.innerHTML = "Hủy thành công";
            statusBadge.className = "approver-status-badge cancelled";
          } else if (status === 5) {
            statusBadge.innerHTML = "Xin hủy đăng ký";
            statusBadge.className = "approver-status-badge cancellation-request";
          }

          node.appendChild(statusBadge);

          // Add approver note/feedback under the node if available and status is resolved
          if (approvalNote && (status === 1 || status === 2 || status === 4 || status === 5)) {
            const noteBox = document.createElement("div");
            noteBox.className = "approver-note-box";

            if (status === 1) {
              noteBox.classList.add("approved");
            } else if (status === 2) {
              noteBox.classList.add("rejected");
            } else if (status === 4) {
              noteBox.classList.add("cancelled");
            } else if (status === 5) {
              noteBox.classList.add("cancellation-request");
            }

            noteBox.innerHTML = `<strong style="display: block; margin-bottom: 4px;">Ghi chú:</strong>${approvalNote}`;
            node.appendChild(noteBox);
          }

          if (idx > 0) {
            const sep = document.createElement("div");
            sep.className = "flow-connector";
            sep.innerHTML = ''<i class="bi bi-chevron-right"></i>'';
            container.appendChild(sep);
          }

          container.appendChild(node);

          // Load avatar async nếu chưa có cache
          if (!cachedUrl && approverID && paramImg) {
            loadEmployeeAvatarAsync(approverID, stage, avatarWrapper);
          }
        });
      }

      /**
       * Load avatar cho nhân viên từ cache global hoặc server
       * @param {string} empId - ID nhân viên
       * @param {object} employee - Object nhân viên với paramImg, storeImgName
       * @param {element} containerElement - DOM element để update khi load xong (optional)
       */
      function loadEmployeeAvatarAsync(empId, employee, containerElement) {
        return new Promise((resolve) => {
          // Kiểm tra cache trước
          if (window.GlobalEmployeeAvatarCache && window.GlobalEmployeeAvatarCache[empId]) {
            const cachedUrl = window.GlobalEmployeeAvatarCache[empId];
            // Update container nếu được truyền vào
            if (containerElement) {
              containerElement.innerHTML = `
                          <img src="${cachedUrl}" style="width: 100%; height: 100%; border-radius: 50%; object-fit: cover;" />
                        `;
            }
            resolve(cachedUrl);
            return;
          }

          if (!employee || !employee.paramImg) {
            resolve(null);
            return;
          }

          const paramImg = employee.paramImg;
          const storeImgName = employee.storeImgName || "paradisefile_sp_GetFileAPI";

          AjaxHPAParadise({
            data: {
              name: storeImgName,
              param: decodeURIComponent(paramImg)
            },
            xhrFields: { responseType: "blob" },
            cache: true,
            success: function (blob) {
              try {
                let blobUrl = "";

                if (blob instanceof Blob) {
                  blobUrl = URL.createObjectURL(blob);
                } else if (blob instanceof ArrayBuffer) {
                  const newBlob = new Blob([blob], { type: "image/jpeg" });
                  blobUrl = URL.createObjectURL(newBlob);
                } else if (typeof blob === "string" && blob.startsWith("blob:")) {
                  blobUrl = blob;
                }

                if (blobUrl) {
                  // Lưu vào cache
                  window.GlobalEmployeeAvatarCache = window.GlobalEmployeeAvatarCache || {};
                  window.GlobalEmployeeAvatarCache[empId] = blobUrl;

                  // Update container element nếu được truyền vào
                  if (containerElement) {
                    containerElement.innerHTML = `
                                      <img src="${blobUrl}" style="width: 100%; height: 100%; border-radius: 50%; object-fit: cover;" />
                                    `;
                  }

                  // Cập nhật tất cả img tag với data-emp-id tương ứng (fallback)
                  $("img[data-emp-id=''" + empId + "'']").attr("src", blobUrl);
                }

                resolve(blobUrl || null);
              } catch (ex) {
                console.warn("Error processing avatar blob for " + empId, ex);
                resolve(null);
              }
            },
            error: function (err) {
              console.warn("Failed to load avatar for " + empId, err);
              resolve(null);
            }
          });
        });
      }

      // Helper Utilities
      function showAlert(type, message) {
        if (typeof uiManager !== "undefined") {
          uiManager.showAlert({ type: type, message: message });
        } else {
          alert(
            `${type === "success" ? "✅" : type === "warning" ? "⚠️" : "❌"} ${message}`,
          );
        }
      }

      function formatDateTime(dateStr) {
        if (!dateStr) return "-";
        const dateObj = new Date(dateStr);
        if (isNaN(dateObj.getTime())) return dateStr;

        const day = String(dateObj.getDate()).padStart(2, "0");
        const month = String(dateObj.getMonth() + 1).padStart(2, "0");
        const year = dateObj.getFullYear();
        const hours = String(dateObj.getHours()).padStart(2, "0");
        const minutes = String(dateObj.getMinutes()).padStart(2, "0");

        return `${day}/${month}/${year} ${hours}:${minutes}`;
      }

      // Fetch dynamic record details on load if running in production context
      function fetchComplaintDetails(complaintID, historyID, complaintType) {
        if (typeof AjaxHPAParadise !== "undefined") {
          AjaxHPAParadise({
            data: {
              name: "sp_Task_Complaint_GetDetail",
              param: [
                "HistoryID",
                historyID ? parseInt(historyID) : null,
                "ComplaintID",
                complaintID ? parseInt(complaintID) : null,
                "ComplaintType",
                complaintType ? parseInt(complaintType) : 1,
                "LoginID",
                loginID,
              ],
            },
            success: function (res) {
              try {
                const json = typeof res === "string" ? JSON.parse(res) : res;
                const dbData = json.data && json.data[0] ? json.data[0][0] : null;
                if (dbData) {
                  data = dbData;
                  data.Mode = dbData.Mode || (complaintID ? "view" : "submit");
                  selectedType = parseInt(data.ComplaintType) || 1;

                  // Update window.sp_Task_ComplaintForm_param with ComplaintID for file uploader
                  if (!window.sp_Task_ComplaintForm_param) window.sp_Task_ComplaintForm_param = {};
                  window.sp_Task_ComplaintForm_param.ComplaintID = data.ComplaintID;
                  window.currentRecordID_ComplaintID = data.ComplaintID;
                }
              } catch (e) {
                console.error("Error parsing complaint details:", e);
              }
              initFormUI();
            },
            error: function () {
              initFormUI();
            },
          });
        } else {
          initFormUI();
        }
      }

      // Load complaint from history and populate form in view mode
      function loadComplaintFromHistory(complaintID, historyID, complaintType) {
        console.log(complaintID, historyID, complaintType)
        if (typeof AjaxHPAParadise !== "undefined") {
          AjaxHPAParadise({
            data: {
              name: "sp_Task_Complaint_GetDetail",
              param: [
                "HistoryID",
                historyID ? parseInt(historyID) : null,
                "ComplaintID",
                complaintID ? parseInt(complaintID) : null,
                "ComplaintType",
                complaintType ? parseInt(complaintType) : 1,
                "LoginID",
                loginID,
              ],
            },
            success: function (res) {
              try {
                const json = typeof res === "string" ? JSON.parse(res) : res;
                const dbData = json.data && json.data[0] ? json.data[0][0] : null;
                if (dbData) {
                  data = dbData;
                  data.Mode = "view"; // Set to view mode
                  selectedType = parseInt(data.ComplaintType) || 1;

                  // Update window.sp_Task_ComplaintForm_param with ComplaintID for file uploader
                  if (!window.sp_Task_ComplaintForm_param) window.sp_Task_ComplaintForm_param = {};
                  window.sp_Task_ComplaintForm_param.ComplaintID = data.ComplaintID;
                  window.currentRecordID_ComplaintID = data.ComplaintID;

                  // Extract files from response (sp_Task_Complaint_GetDetail should return both complaint and files)
                  let DataSource_FileURL = [];
                  if (json.data && json.data[1]) {
                    // Files data should be in json.data[1]
                    const fileRows = json.data[1];
                    fileRows.forEach((file) => {
                      if (file.UrlFile) {
                        DataSource_FileURL.push({
                          IdentityID: file.IdentityID,
                          UrlFile: file.UrlFile,
                        });
                      }
                    });
                  }

                  // Update the file uploader widget with data source
                  if (InstanceFileURLP75A67EB5C0AD4D899DBEAB3F52C6B2FA) {
                    InstanceFileURLP75A67EB5C0AD4D899DBEAB3F52C6B2FA.option("dataSource", DataSource_FileURL);
                  }

                  // Initialize form UI in view mode
                  initFormUI();

                  // Hide submit button when viewing from history
                  submitActions.style.display = "none";

                  // Button setup is handled globally during initialization
                  // and visibility configured dynamically in initFormUI()

                  // Switch to form tab
                  const tabButtons = document.querySelectorAll("#sp_Task_ComplaintForm_html .tab-btn");
                  const tabContents = document.querySelectorAll("#sp_Task_ComplaintForm_html .tab-content");
                  tabButtons.forEach((b) => b.classList.remove("active"));
                  tabContents.forEach((c) => c.classList.remove("active"));

                  const formTab = document.querySelector("#sp_Task_ComplaintForm_html .tab-btn[data-tab=''tab-form'']");
                  if (formTab) {
                    formTab.classList.add("active");
                    document.getElementById("tab-form").classList.add("active");
                  }
                }
              } catch (e) {
                console.error("Error parsing complaint details:", e);
              }
            },
            error: function () {
              initFormUI();
            },
          });
        }
      }

      if (urlComplaintID || urlHistoryID) {
        fetchComplaintDetails(urlComplaintID, urlHistoryID, urlType);
      } else {
        initFormUI();
      }
    })();
  </script>
</div>
	'
--    exec sptblCommonControlType_Signed_DUC 'sp_Task_ComplaintForm_html'
--EXEC sp_GenerateHTMLScript_new 'sp_Task_ComplaintForm_html'
	select @html as html
end
GO
PRINT N'[OK] Created procedure sp_Task_ComplaintForm_html';
GO

-- ============================================================================
-- PHASE 6: Wrapper procedures (đọc cache HTML từ tblHtmlScriptCache)
-- Lưu ý pattern: cache key = ClassName (KHÔNG có suffix _html)
-- ============================================================================

IF OBJECT_ID('dbo.sp_Task_GetComplaintList', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Task_GetComplaintList;
GO

CREATE   PROCEDURE [dbo].[sp_Task_GetComplaintList] (
    @LoginID INT = NULL,
    @LanguageID VARCHAR(2) = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Try to load from tblHtmlScriptCache
    SELECT html FROM tblHtmlScriptCache
    WHERE TableName = 'sp_Task_GetComplaintList' AND LanguageID = @LanguageID;

    -- Fallback in case cache is not populated
    IF @@ROWCOUNT = 0
    BEGIN
        EXEC sp_Task_GetComplaintList_html @LanguageID = @LanguageID;
    END
END
GO
PRINT N'[OK] Created procedure sp_Task_GetComplaintList';
GO

IF OBJECT_ID('dbo.sp_Task_ComplaintForm', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Task_ComplaintForm;
GO

CREATE PROCEDURE [dbo].[sp_Task_ComplaintForm]
 @LoginID int = null,
 @LanguageID varchar(2) = 'VN'
AS
 select html from tblHtmlScriptCache where TableName = 'sp_Task_ComplaintForm' and ScreenType = -1 and LanguageID = @LanguageID
GO
PRINT N'[OK] Created procedure sp_Task_ComplaintForm';
GO

-- ============================================================================
-- PHASE 7: Metadata transaction
-- ============================================================================

BEGIN TRY
    BEGIN TRANSACTION;

    -- ----- Variables -----
    DECLARE @ParentMenuID  varchar(100) = 'MnuCSM000';
    DECLARE @Priority      int = 60;
    DECLARE @Glyphicon     nvarchar(100) = N'Home';
    DECLARE @GroupID       varchar(100) = 'TrainingGroup';
    DECLARE @AdminLoginID  int = 3;
    DECLARE @FullAccess    nvarchar(10) = N'32';

    -- Verify parent menu tồn tại + IsVisible = 1
    IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = @ParentMenuID AND IsVisible = 1)
    BEGIN
        DECLARE @errMsg nvarchar(400) = N'[FATAL] Parent menu ' + @ParentMenuID + N' không tồn tại hoặc IsVisible = 0. Migrate sẽ tạo menu nhưng UI sẽ không hiển thị. Dừng để user kiểm tra.';
        RAISERROR(@errMsg, 16, 1);
    END
    PRINT N'[OK] Parent menu MnuCSM000 verified (IsVisible=1)';

    -- ============ 7.1 MEN_Menu (MnuAT009 - List) ============
    IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = 'MnuAT009')
    BEGIN
        INSERT INTO MEN_Menu
            (MenuID, ClassName, AssemblyName, ParentMenuID, Priority,
             IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb,
             IsUseMobileDevice, isShowInMobileLayOut,
             glyphicon, GroupID,
             IsModal, LinkMenuID, IsCollapsed, ShortcutKeys, SupperAdmin, LargeTile,
             Colors, superForm, DefaultParam, Notification, URL, IsNotAjax,
             InstructionID, showDialog, ProcessDataForNotifyProc,
             ClassName_Audit, ClassName_CT, Showinsuperform, Activity, Separation,
             MobileDeviceGroup, PriorityMobileDevice, IsLeftMenu, NotUsePlatform,
             OptionAuthentication, IconBackColor, IconForeColor, isParentMenu,
             ParentMenuMobileID, IsHiddenInTree)
        VALUES
            ('MnuAT009', 'sp_Task_GetComplaintList', 'DataSetting', @ParentMenuID, @Priority,
             1, 1, 0, 1,
             0, 0,
             @Glyphicon, @GroupID,
             0, '', 0, '', 0, 0,
             '', '', '', 0, '', 0,
             '', 0, '',
             '', '', 0, N'', 0,
             N'', 0, 0, N'',
             0, N'', N'', 0,
             '', 0);
        PRINT N'[OK] Inserted MEN_Menu MnuAT009';
    END
    ELSE
    BEGIN
        UPDATE MEN_Menu
        SET ClassName              = 'sp_Task_GetComplaintList',
            AssemblyName           = 'DataSetting',
            ParentMenuID           = @ParentMenuID,
            Priority               = @Priority,
            IsVisible              = 1,
            IsWeb                  = 1,
            ViewOnWeb              = 0,
            isShowLayOutWeb        = 1,
            IsUseMobileDevice      = 0,
            isShowInMobileLayOut   = 0,
            glyphicon              = @Glyphicon,
            GroupID                = @GroupID
        WHERE MenuID = 'MnuAT009';
        PRINT N'[OK] Updated MEN_Menu MnuAT009';
    END

    -- ============ 7.2 MEN_Menu (MnuAT010 - Form) ============
    IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = 'MnuAT010')
    BEGIN
        INSERT INTO MEN_Menu
            (MenuID, ClassName, AssemblyName, ParentMenuID, Priority,
             IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb,
             IsUseMobileDevice, isShowInMobileLayOut,
             glyphicon, GroupID,
             IsModal, LinkMenuID, IsCollapsed, ShortcutKeys, SupperAdmin, LargeTile,
             Colors, superForm, DefaultParam, Notification, URL, IsNotAjax,
             InstructionID, showDialog, ProcessDataForNotifyProc,
             ClassName_Audit, ClassName_CT, Showinsuperform, Activity, Separation,
             MobileDeviceGroup, PriorityMobileDevice, IsLeftMenu, NotUsePlatform,
             OptionAuthentication, IconBackColor, IconForeColor, isParentMenu,
             ParentMenuMobileID, IsHiddenInTree)
        VALUES
            ('MnuAT010', 'sp_Task_ComplaintForm', 'DataSetting', @ParentMenuID, @Priority,
             1, 0, 0, 0,
             0, 0,
             @Glyphicon, @GroupID,
             0, '', 0, '', 0, 0,
             '', '', '', 0, '', 0,
             '', 0, '',
             '', '', 0, N'', 0,
             N'', 0, 0, N'',
             0, N'', N'', 0,
             '', 0);
        PRINT N'[OK] Inserted MEN_Menu MnuAT010';
    END
    ELSE
    BEGIN
        UPDATE MEN_Menu
        SET ClassName              = 'sp_Task_ComplaintForm',
            AssemblyName           = 'DataSetting',
            ParentMenuID           = @ParentMenuID,
            Priority               = @Priority,
            IsVisible              = 1,
            IsWeb                  = 0,
            ViewOnWeb              = 0,
            isShowLayOutWeb        = 0,
            IsUseMobileDevice      = 0,
            isShowInMobileLayOut   = 0,
            glyphicon              = @Glyphicon,
            GroupID                = @GroupID
        WHERE MenuID = 'MnuAT010';
        PRINT N'[OK] Updated MEN_Menu MnuAT010';
    END

    -- ============ 7.3 tblSC_Object (MnuAT009 + MnuAT010) ============
    DECLARE @ParentObjectID int;
    SELECT TOP 1 @ParentObjectID = ObjectID FROM tblSC_Object WHERE Description = @ParentMenuID;
    IF @ParentObjectID IS NULL SET @ParentObjectID = 1;

    DECLARE @ObjID_009 int, @ObjID_010 int;

    IF NOT EXISTS (SELECT 1 FROM tblSC_Object WHERE Description = 'MnuAT009')
    BEGIN
        SET @ObjID_009 = ISNULL((SELECT MAX(ObjectID) FROM tblSC_Object), 0) + 1;
        INSERT INTO tblSC_Object
            (ObjectID, ObjectName, Description, Visible, ParentObjectID, ParentObjectRightID, ParentRight)
        VALUES
            (@ObjID_009, 'DataSetting.sp_Task_GetComplaintList', 'MnuAT009', 1, @ParentObjectID, NULL, NULL);
        PRINT N'[OK] Inserted tblSC_Object for MnuAT009';
    END
    ELSE
    BEGIN
        UPDATE tblSC_Object
        SET ObjectName     = 'DataSetting.sp_Task_GetComplaintList',
            Visible        = 1,
            ParentObjectID = @ParentObjectID
        WHERE Description = 'MnuAT009';
        SELECT TOP 1 @ObjID_009 = ObjectID FROM tblSC_Object WHERE Description = 'MnuAT009';
        PRINT N'[OK] Updated tblSC_Object for MnuAT009';
    END

    IF NOT EXISTS (SELECT 1 FROM tblSC_Object WHERE Description = 'MnuAT010')
    BEGIN
        SET @ObjID_010 = ISNULL((SELECT MAX(ObjectID) FROM tblSC_Object), 0) + 1;
        INSERT INTO tblSC_Object
            (ObjectID, ObjectName, Description, Visible, ParentObjectID, ParentObjectRightID, ParentRight)
        VALUES
            (@ObjID_010, 'DataSetting.sp_Task_ComplaintForm', 'MnuAT010', 1, @ParentObjectID, NULL, NULL);
        PRINT N'[OK] Inserted tblSC_Object for MnuAT010';
    END
    ELSE
    BEGIN
        UPDATE tblSC_Object
        SET ObjectName     = 'DataSetting.sp_Task_ComplaintForm',
            Visible        = 1,
            ParentObjectID = @ParentObjectID
        WHERE Description = 'MnuAT010';
        SELECT TOP 1 @ObjID_010 = ObjectID FROM tblSC_Object WHERE Description = 'MnuAT010';
        PRINT N'[OK] Updated tblSC_Object for MnuAT010';
    END

    -- ============ 7.4 tblMD_Message (labels) ============
    MERGE tblMD_Message AS tgt
    USING (VALUES
        ('MnuAT009', 'VN', N'Danh sách đơn khiếu nại'),
        ('MnuAT009', 'EN', N'Rejection Appeal List'),
        ('MnuAT010', 'VN', N'Đơn khiếu nại')
    ) AS src(MessageID, Language, Content)
       ON tgt.MessageID = src.MessageID AND tgt.Language = src.Language
    WHEN MATCHED THEN UPDATE SET tgt.Content = src.Content
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (MessageID, Language, Content)
        VALUES (src.MessageID, src.Language, src.Content);
    PRINT N'[OK] Merged tblMD_Message (3 rows)';

    -- ============ 7.5 tblCommonControlType_Signed (6 controls cho sp_Task_ComplaintForm_html) ============
    -- Chỉ insert/update metadata. Các cột html/loadUI/loadData sẽ được sptblCommonControlType_Signed_DUC populate ở PHASE 8.
    MERGE tblCommonControlType_Signed AS tgt
    USING (VALUES
        ('P3B400D95FDB64B7F8DCE8FB445CF5E15', 'sp_Task_ComplaintForm_html', N'ComplaintID', N'TaskID',           'hpaControlSelectBox',             N'Công việc cần đề nghị / khiếu nại', 'sp_Task_Complaint_GetUnfinishedTasks'),
        ('P509F121B87BF45788C3587BD5C5A539A', 'sp_Task_ComplaintForm_html', N'ComplaintID', N'ComplaintReason',  'hpaControlRichTextEditorPremium', NULL,                                  NULL),
        ('P75A67EB5C0AD4D899DBEAB3F52C6B2FA', 'sp_Task_ComplaintForm_html', N'ComplaintID', N'FileURL',          'hpaControlFile',                  NULL,                                  NULL),
        ('PB3EAB30500524A39AACA503B753377B5', 'sp_Task_ComplaintForm_html', NULL,           N'OldDueDate',       'hpaControlDateTime',              NULL,                                  NULL),
        ('PE4C6698E797E4E73B3B904F2AC6EAD7B', 'sp_Task_ComplaintForm_html', N'ComplaintID', N'ProposedDueDate',  'hpaControlDateTime',              NULL,                                  NULL),
        ('PF824852E41004F53B87E683F9ACDEE09', 'sp_Task_ComplaintForm_html', N'ComplaintID', N'ComplaintType',    'hpaControlSelectBox',             NULL,                                  'sp_Task_getComplaintTypes')
    ) AS src(UID, TableName, ColumnIDName, ColumnName, Type, DisplayName, DataSourceSP)
       ON tgt.UID = src.UID
    WHEN MATCHED THEN UPDATE SET
        tgt.TableName     = src.TableName,
        tgt.ColumnIDName  = src.ColumnIDName,
        tgt.ColumnName    = src.ColumnName,
        tgt.Type          = src.Type,
        tgt.DisplayName   = src.DisplayName,
        tgt.DataSourceSP  = src.DataSourceSP,
        tgt.IsRequired    = CASE WHEN src.UID = 'P3B400D95FDB64B7F8DCE8FB445CF5E15' THEN 1 ELSE tgt.IsRequired END
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (UID, TableName, ColumnIDName, ColumnName, Type, DisplayName, DataSourceSP, IsRequired)
        VALUES (src.UID, src.TableName, src.ColumnIDName, src.ColumnName, src.Type, src.DisplayName, src.DataSourceSP,
                CASE WHEN src.UID = 'P3B400D95FDB64B7F8DCE8FB445CF5E15' THEN 1 ELSE NULL END);
    PRINT N'[OK] Merged tblCommonControlType_Signed (6 rows for sp_Task_ComplaintForm_html)';

    -- ============ 7.6 tblSC_Right_Stored (chỉ LoginID = 3, theo rule cấp quyền) ============
    -- ⚠️ Rule: chỉ cấp cho LoginID = 3 (admin). KHÔNG dùng sp_UpdateMenuInUserRight.
    IF NOT EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID = @ObjID_009 AND LoginID = @AdminLoginID)
        INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@ObjID_009, @AdminLoginID, @FullAccess);
    ELSE
        UPDATE tblSC_Right_Stored SET FullAccess = @FullAccess WHERE ObjectID = @ObjID_009 AND LoginID = @AdminLoginID;

    IF NOT EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID = @ObjID_010 AND LoginID = @AdminLoginID)
        INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@ObjID_010, @AdminLoginID, @FullAccess);
    ELSE
        UPDATE tblSC_Right_Stored SET FullAccess = @FullAccess WHERE ObjectID = @ObjID_010 AND LoginID = @AdminLoginID;
    PRINT N'[OK] Granted FullAccess to LoginID=3 (admin) for both menus';

    COMMIT TRANSACTION;
    PRINT N'[OK] PHASE 7 metadata transaction committed';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT N'[ERROR] Line ' + CAST(ERROR_LINE() AS varchar(10)) + N': ' + ERROR_MESSAGE();
    THROW;
END CATCH
GO

-- ============================================================================
-- PHASE 8: Build cache HTML + refresh menu/right cache
-- ============================================================================

-- 8.1 Populate html/loadUI/loadData trong tblCommonControlType_Signed cho config-driven renderer
PRINT N'[INFO] Running sptblCommonControlType_Signed_DUC for sp_Task_ComplaintForm_html...';
EXEC dbo.sptblCommonControlType_Signed_DUC 'sp_Task_ComplaintForm_html';
PRINT N'[OK] sptblCommonControlType_Signed_DUC completed';
GO

-- 8.2 Build HTML cache (lưu vào tblHtmlScriptCache với key TableName = ClassName)
PRINT N'[INFO] Building HTML cache for sp_Task_GetComplaintList_html...';
EXEC dbo.sp_GenerateHTMLScript 'sp_Task_GetComplaintList_html';
PRINT N'[INFO] Building HTML cache for sp_Task_ComplaintForm_html...';
EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html';
GO

-- 8.3 Refresh menu/right cache
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_Task_GetComplaintList';
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_Task_ComplaintForm';
PRINT N'[OK] sp_Men_Menu_AfterSave_Simple completed for both ClassName';
GO

-- ❌ KHÔNG gọi sp_UpdateMenuInUserRight — rule cấp quyền chỉ cho LoginID = 3.

-- ============================================================================
-- PHASE 9: Verify
-- ============================================================================

PRINT N'[INFO] === VERIFY ===';

SELECT m.MenuID,
       m.ClassName,
       m.AssemblyName,
       m.ParentMenuID,
       m.Priority,
       m.IsVisible,
       m.IsWeb,
       m.ViewOnWeb,
       m.isShowLayOutWeb,
       m.IsUseMobileDevice,
       o.ObjectID,
       o.ObjectName,
       msgVN.Content AS NameVN,
       msgEN.Content AS NameEN,
       (SELECT COUNT(*) FROM tblSC_Right_Stored WHERE ObjectID = o.ObjectID) AS RightStoredRows,
       (SELECT COUNT(*) FROM tblHtmlScriptCache WHERE TableName = m.ClassName) AS HtmlCacheLangs
FROM MEN_Menu m
LEFT JOIN tblSC_Object o
       ON o.Description = m.MenuID
LEFT JOIN tblMD_Message msgVN
       ON msgVN.MessageID = m.MenuID AND msgVN.Language = 'VN'
LEFT JOIN tblMD_Message msgEN
       ON msgEN.MessageID = m.MenuID AND msgEN.Language = 'EN'
WHERE m.MenuID IN ('MnuAT009','MnuAT010')
ORDER BY m.MenuID;

SELECT TableName, LanguageID, ScreenType,
       DATALENGTH(html) AS HtmlBytes, Version
FROM tblHtmlScriptCache
WHERE TableName IN ('sp_Task_GetComplaintList','sp_Task_ComplaintForm')
ORDER BY TableName, LanguageID;

SELECT TableName, COUNT(*) AS ControlCount,
       SUM(CASE WHEN loadUI IS NULL OR DATALENGTH(loadUI)=0 THEN 1 ELSE 0 END) AS LoadUIEmpty
FROM tblCommonControlType_Signed
WHERE TableName = 'sp_Task_ComplaintForm_html'
GROUP BY TableName;

PRINT N'[INFO] === END migrate cặp menu Khiếu Nại MnuAT009 + MnuAT010 ===';
GO
