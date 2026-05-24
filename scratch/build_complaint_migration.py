import pyodbc
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

procs_to_migrate = [
    'sp_Task_GetComplaintList',
    'sp_Task_GetComplaintList_html',
    'sp_Task_ComplaintForm',
    'sp_Task_ComplaintForm_html',
    'sp_Task_Complaint_Resolve',
    'sp_Task_Complaint_GetDataList',
    'sp_Task_getComplaintTypes',
    'sp_Task_Complaint_GetUnfinishedTasks',
    'sp_Task_Complaint_GetDetail',
    'sp_Task_Complaint_Submit'
]

output_file = Path(r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\migrate_menu_complaint_20260523.sql")

sql_content = []

# Header
sql_content.append("""-- ============================================================================
-- File   : SQL script/migrate_menu_complaint_20260523.sql
-- Mục đích: Migrate Menu Đơn Khiếu Nại (MnuAT010) và Danh sách đơn khiếu nại (MnuAT009)
--          từ Paradise_Dev sang hệ thống khác.
-- Cảnh báo: USER tự review và CHẠY. Agent KHÔNG tự động thực thi trên DB đích.
-- Khuyến cáo: BACKUP DB trước khi chạy.
-- Idempotent: Có thể chạy nhiều lần; không chèn trùng bảng/menu/object/quyền/cache.
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
""")

# Table structures
sql_content.append("""-- PHASE 1: Tạo các bảng liên quan nếu chưa tồn tại
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblTask_ComplaintTypes')
BEGIN
    CREATE TABLE [dbo].[tblTask_ComplaintTypes] (
        [ComplaintTypeID] INT IDENTITY(1,1) NOT NULL,
        [ComplaintTypeName] NVARCHAR(255) NOT NULL,
        [ComplaintTypeNameEN] NVARCHAR(255) NULL,
        CONSTRAINT [PK_tblTask_ComplaintTypes] PRIMARY KEY CLUSTERED ([ComplaintTypeID])
    );
    PRINT '[OK] Created table tblTask_ComplaintTypes.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'tblTask_Complaints')
BEGIN
    CREATE TABLE [dbo].[tblTask_Complaints] (
        [ComplaintID] INT IDENTITY(1,1) NOT NULL,
        [HistoryID] INT NULL,
        [TaskID] INT NULL,
        [OldDueDate] DATETIME NULL,
        [ProposedDueDate] DATETIME NULL,
        [ComplaintReason] NVARCHAR(MAX) NULL,
        [Approve_Status] INT NULL DEFAULT ((1)),
        [CreatedBy] VARCHAR(30) NULL,
        [CreatedDate] DATETIME NULL DEFAULT (getdate()),
        [ApprovedBy] VARCHAR(30) NULL,
        [ApprovedDate] DATETIME NULL,
        [ApprovalNote] NVARCHAR(MAX) NULL,
        [ComplaintType] INT NULL DEFAULT ((1)),
        CONSTRAINT [PK_tblTask_Complaints] PRIMARY KEY CLUSTERED ([ComplaintID])
    );
    PRINT '[OK] Created table tblTask_Complaints.';
END
GO
""")

# Table Seeding
sql_content.append("""-- PHASE 2: Seed dữ liệu cho tblTask_ComplaintTypes
SET IDENTITY_INSERT [dbo].[tblTask_ComplaintTypes] ON;

MERGE [dbo].[tblTask_ComplaintTypes] AS Target
USING (
    VALUES 
        (1, N'Gia hạn thời gian hoàn thành', N'Extend Deadline'),
        (2, N'Khiếu nại từ chối duyệt', N'Appeal Rejection')
) AS Source (ComplaintTypeID, ComplaintTypeName, ComplaintTypeNameEN)
ON Target.ComplaintTypeID = Source.ComplaintTypeID
WHEN MATCHED THEN
    UPDATE SET Target.ComplaintTypeName = Source.ComplaintTypeName,
               Target.ComplaintTypeNameEN = Source.ComplaintTypeNameEN
WHEN NOT MATCHED THEN
    INSERT (ComplaintTypeID, ComplaintTypeName, ComplaintTypeNameEN)
    VALUES (Source.ComplaintTypeID, Source.ComplaintTypeName, Source.ComplaintTypeNameEN);

SET IDENTITY_INSERT [dbo].[tblTask_ComplaintTypes] OFF;
PRINT '[OK] Seeded table tblTask_ComplaintTypes.';
GO
""")

try:
    print("Connecting to Paradise_Dev...")
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    # Extract procedures
    sql_content.append("-- PHASE 3: Cài đặt/Cập nhật các Stored Procedure liên quan")
    for proc in procs_to_migrate:
        print(f"Fetching definition for {proc}...")
        cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID(?))", proc)
        defn_row = cursor.fetchone()
        if defn_row and defn_row[0]:
            defn = defn_row[0].strip()
            # Wrap with DROP + CREATE or CREATE OR ALTER
            sql_content.append(f"""
IF OBJECT_ID('dbo.{proc}', 'P') IS NOT NULL
    DROP PROCEDURE dbo.{proc};
GO
{defn}
GO
PRINT '[OK] Created procedure {proc}';
GO""")
        else:
            print(f"WARNING: Procedure {proc} not found or null definition.")
            
    # Phase 4: Metadata (MEN_Menu, tblSC_Object, tblMD_Message)
    sql_content.append("""-- PHASE 4: Đồng bộ cấu hình Menu, Phân quyền và Ngôn ngữ
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @AdminLoginID INT = 3;
    DECLARE @FullAccess NVARCHAR(10) = N'32';
    DECLARE @ObjectID INT;
    DECLARE @ParentObjectID INT;

    -- ==========================================
    -- MENU 1: MnuAT009 (Danh sách đơn khiếu nại)
    -- ==========================================
    IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = 'MnuAT009')
    BEGIN
        INSERT INTO MEN_Menu (
            MenuID, ClassName, AssemblyName, ParentMenuID, Priority,
            IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb,
            IsUseMobileDevice, isShowInMobileLayOut,
            glyphicon, GroupID, IsModal, LinkMenuID, IsCollapsed, Separation,
            MobileDeviceGroup, OptionAuthentication
        ) VALUES (
            'MnuAT009', 'sp_Task_GetComplaintList', 'DataSetting', 'MnuCSM000', 60,
            1, 1, 0, 1,
            0, 0,
            N'Home', 'TrainingGroup', 0, '', 0, 1,
            'MnuTAD000', 1
        );
    END
    ELSE
    BEGIN
        UPDATE MEN_Menu
        SET ClassName = 'sp_Task_GetComplaintList',
            AssemblyName = 'DataSetting',
            ParentMenuID = 'MnuCSM000',
            Priority = 60,
            IsVisible = 1,
            IsWeb = 1,
            isShowLayOutWeb = 1,
            glyphicon = N'Home',
            GroupID = 'TrainingGroup',
            Separation = 1,
            MobileDeviceGroup = 'MnuTAD000',
            OptionAuthentication = 1
        WHERE MenuID = 'MnuAT009';
    END

    -- Object phân quyền MnuAT009
    SELECT TOP 1 @ParentObjectID = ObjectID FROM tblSC_Object WHERE Description = 'MnuCSM000';
    IF @ParentObjectID IS NULL SET @ParentObjectID = 1;

    IF NOT EXISTS (SELECT 1 FROM tblSC_Object WHERE Description = 'MnuAT009')
    BEGIN
        SET @ObjectID = ISNULL((SELECT MAX(ObjectID) FROM tblSC_Object), 0) + 1;
        INSERT INTO tblSC_Object (ObjectID, ObjectName, Description, Visible, ParentObjectID, ParentObjectRightID, ParentRight)
        VALUES (@ObjectID, 'DataSetting.sp_Task_GetComplaintList', 'MnuAT009', 1, @ParentObjectID, 0, 0);
    END
    ELSE
    BEGIN
        UPDATE tblSC_Object
        SET ObjectName = 'DataSetting.sp_Task_GetComplaintList',
            Visible = 1,
            ParentObjectID = @ParentObjectID
        WHERE Description = 'MnuAT009';
        
        SELECT TOP 1 @ObjectID = ObjectID FROM tblSC_Object WHERE Description = 'MnuAT009';
    END

    -- Cấp quyền LoginID = 3 cho MnuAT009
    IF NOT EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID = @ObjectID AND LoginID = @AdminLoginID)
        INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@ObjectID, @AdminLoginID, @FullAccess);
    ELSE
        UPDATE tblSC_Right_Stored SET FullAccess = @FullAccess WHERE ObjectID = @ObjectID AND LoginID = @AdminLoginID;

    -- Việt hóa / Anh hóa cho MnuAT009
    EXEC dbo.[1rename_Mess] 'MnuAT009', 'VN', N'Danh sách đơn khiếu nại';
    EXEC dbo.[1rename_Mess] 'MnuAT009', 'EN', N'Rejection Appeal List';


    -- ==========================================
    -- MENU 2: MnuAT010 (Đơn khiếu nại)
    -- ==========================================
    IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE MenuID = 'MnuAT010')
    BEGIN
        INSERT INTO MEN_Menu (
            MenuID, ClassName, AssemblyName, ParentMenuID, Priority,
            IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb,
            IsUseMobileDevice, isShowInMobileLayOut,
            glyphicon, GroupID, IsModal, LinkMenuID, IsCollapsed, Separation,
            MobileDeviceGroup, OptionAuthentication
        ) VALUES (
            'MnuAT010', 'sp_Task_ComplaintForm', 'DataSetting', 'MnuCSM000', 60,
            1, 0, 0, 0,
            0, 0,
            N'Home', 'TrainingGroup', 0, '', 0, 1,
            'MnuTAD000', 1
        );
    END
    ELSE
    BEGIN
        UPDATE MEN_Menu
        SET ClassName = 'sp_Task_ComplaintForm',
            AssemblyName = 'DataSetting',
            ParentMenuID = 'MnuCSM000',
            Priority = 60,
            IsVisible = 1,
            IsWeb = 0,
            isShowLayOutWeb = 0,
            glyphicon = N'Home',
            GroupID = 'TrainingGroup',
            Separation = 1,
            MobileDeviceGroup = 'MnuTAD000',
            OptionAuthentication = 1
        WHERE MenuID = 'MnuAT010';
    END

    -- Object phân quyền MnuAT010
    IF NOT EXISTS (SELECT 1 FROM tblSC_Object WHERE Description = 'MnuAT010')
    BEGIN
        SET @ObjectID = ISNULL((SELECT MAX(ObjectID) FROM tblSC_Object), 0) + 1;
        INSERT INTO tblSC_Object (ObjectID, ObjectName, Description, Visible, ParentObjectID, ParentObjectRightID, ParentRight)
        VALUES (@ObjectID, 'DataSetting.sp_Task_ComplaintForm', 'MnuAT010', 1, @ParentObjectID, 0, 0);
    END
    ELSE
    BEGIN
        UPDATE tblSC_Object
        SET ObjectName = 'DataSetting.sp_Task_ComplaintForm',
            Visible = 1,
            ParentObjectID = @ParentObjectID
        WHERE Description = 'MnuAT010';
        
        SELECT TOP 1 @ObjectID = ObjectID FROM tblSC_Object WHERE Description = 'MnuAT010';
    END

    -- Cấp quyền LoginID = 3 cho MnuAT010
    IF NOT EXISTS (SELECT 1 FROM tblSC_Right_Stored WHERE ObjectID = @ObjectID AND LoginID = @AdminLoginID)
        INSERT INTO tblSC_Right_Stored (ObjectID, LoginID, FullAccess) VALUES (@ObjectID, @AdminLoginID, @FullAccess);
    ELSE
        UPDATE tblSC_Right_Stored SET FullAccess = @FullAccess WHERE ObjectID = @ObjectID AND LoginID = @AdminLoginID;

    -- Việt hóa cho MnuAT010 (Dùng VN làm EN fallback nếu không có EN record)
    EXEC dbo.[1rename_Mess] 'MnuAT010', 'VN', N'Đơn khiếu nại';
    EXEC dbo.[1rename_Mess] 'MnuAT010', 'EN', N'Đơn khiếu nại';

    COMMIT TRANSACTION;
    PRINT '[OK] Metadata, Permissions and Messages configured successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT '[ERROR] Metadata configuration failed: ' + ERROR_MESSAGE();
    THROW;
END CATCH
GO
""")

    # Phase 5: Rebuild Cache
    sql_content.append("""-- PHASE 5: Biên dịch và Rebuild HTML cache
PRINT 'Rebuilding HTML Cache for sp_Task_GetComplaintList...';
EXEC dbo.sp_GenerateHTMLScript 'sp_Task_GetComplaintList_html', 'VN', 'sp_Task_GetComplaintList';
EXEC dbo.sp_GenerateHTMLScript 'sp_Task_GetComplaintList_html', 'EN', 'sp_Task_GetComplaintList';
GO

PRINT 'Rebuilding HTML Cache for sp_Task_ComplaintForm...';
EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'VN', 'sp_Task_ComplaintForm';
-- Dùng VN làm EN cache cho sp_Task_ComplaintForm vì menu không có EN resources
EXEC dbo.sp_GenerateHTMLScript 'sp_Task_ComplaintForm_html', 'VN', 'sp_Task_ComplaintForm';
GO

PRINT 'Refreshing Menu Cache...';
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_Task_GetComplaintList';
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'sp_Task_ComplaintForm';
GO

-- PHASE 6: Kiểm tra xác minh sau khi chạy
PRINT '=== VERIFY MIGRATION RESULTS ===';
SELECT m.MenuID, m.ClassName, m.AssemblyName, m.ParentMenuID,
       o.ObjectID, o.ObjectName,
       msgVN.Content AS NameVN, msgEN.Content AS NameEN,
       (SELECT COUNT(*) FROM tblSC_Right_Stored WHERE ObjectID = o.ObjectID) AS RightsCount,
       (SELECT COUNT(*) FROM tblHtmlScriptCache WHERE TableName = m.ClassName) AS CacheLangsCount
FROM MEN_Menu m
LEFT JOIN tblSC_Object o ON o.Description = m.MenuID
LEFT JOIN tblMD_Message msgVN ON msgVN.MessageID = m.MenuID AND msgVN.Language = 'VN'
LEFT JOIN tblMD_Message msgEN ON msgEN.MessageID = m.MenuID AND msgEN.Language = 'EN'
WHERE m.MenuID IN ('MnuAT009', 'MnuAT010');
GO
""")

    # Write output file
    output_file.write_text("\n".join(sql_content), encoding="utf-8")
    print(f"SUCCESS: Completed building migration script. Output path: {output_file}")
    
    conn.close()
except Exception as e:
    print("Error during script construction:", e)
