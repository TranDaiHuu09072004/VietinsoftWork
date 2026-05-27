-- =====================================================================
-- Cleanup menu MnuKPI448 (Marketing Lead Tracking) on Paradise_dev
-- Date: 2026-05-27
-- Note: Review and run manually. Agent does not execute destructive SQL.
-- =====================================================================

USE [Paradise_dev];
GO

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @MenuID    VARCHAR(100) = 'MnuKPI448';
    DECLARE @ClassName VARCHAR(100) = 'sp_LeadTrackingForMarketing';
    DECLARE @Renderer  VARCHAR(120) = @ClassName + '_html';
    DECLARE @ObjectID  INT = (SELECT TOP 1 ObjectID FROM tblSC_Object WHERE Description = @MenuID);

    -- UI cache + metadata
    DELETE FROM tblHtmlScriptCache WHERE TableName = @Renderer;
    DELETE FROM tblDataSettingLayout WHERE TableName = @ClassName;
    DELETE FROM tblDataSetting WHERE TableName = @ClassName;
    DELETE FROM tblCommonControlType_Signed WHERE TableName = @Renderer;

    -- Rights
    IF @ObjectID IS NOT NULL
    BEGIN
        DELETE FROM tblSC_Right_Stored WHERE ObjectID = @ObjectID;
        DELETE FROM tblSC_GroupRight WHERE ObjectID = @ObjectID;
    END

    -- Menu objects + messages
    DELETE FROM tblSC_Object WHERE Description = @MenuID;
    DELETE FROM tblMD_Message WHERE MessageID = @MenuID;
    DELETE FROM MEN_Menu WHERE MenuID = @MenuID;

    -- Procedures (renderer + wrapper)
    IF OBJECT_ID('dbo.sp_LeadTrackingForMarketing_html', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_LeadTrackingForMarketing_html;

    IF OBJECT_ID('dbo.sp_LeadTrackingForMarketing', 'P') IS NOT NULL
        DROP PROCEDURE dbo.sp_LeadTrackingForMarketing;

    COMMIT TRANSACTION;
    PRINT 'Cleanup completed for MnuKPI448.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    THROW;
END CATCH
GO
