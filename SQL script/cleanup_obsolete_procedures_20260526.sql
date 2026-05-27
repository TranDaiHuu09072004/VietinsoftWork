-- ============================================================================
-- SQL SCRIPT: CLEANUP OBSOLETE STORED PROCEDURES
-- SCOPE: DROP sp_CompanySalarySummary AND ITS RELATED PROCEDURES
-- DATE: 2026-05-26
-- WARNING: Please review and execute manually. Backup your DB before running.
-- ============================================================================

USE [Paradise_Dev]; -- Update with your target database name if needed
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. Drop sp_CompanySalarySummary
    IF OBJECT_ID('dbo.sp_CompanySalarySummary', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.sp_CompanySalarySummary;
        PRINT 'Dropped procedure: dbo.sp_CompanySalarySummary';
    END

    -- 2. Drop sp_CompanySalarySummary_BeforeLoad
    IF OBJECT_ID('dbo.sp_CompanySalarySummary_BeforeLoad', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.sp_CompanySalarySummary_BeforeLoad;
        PRINT 'Dropped procedure: dbo.sp_CompanySalarySummary_BeforeLoad';
    END

    -- 3. Drop sp_CompanySalarySummary_Debug
    IF OBJECT_ID('dbo.sp_CompanySalarySummary_Debug', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.sp_CompanySalarySummary_Debug;
        PRINT 'Dropped procedure: dbo.sp_CompanySalarySummary_Debug';
    END

    -- 4. Drop sp_CompanySalarySummary_EMC
    IF OBJECT_ID('dbo.sp_CompanySalarySummary_EMC', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.sp_CompanySalarySummary_EMC;
        PRINT 'Dropped procedure: dbo.sp_CompanySalarySummary_EMC';
    END

    -- 5. Drop sp_CompanySalarySummary_Export01
    IF OBJECT_ID('dbo.sp_CompanySalarySummary_Export01', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.sp_CompanySalarySummary_Export01;
        PRINT 'Dropped procedure: dbo.sp_CompanySalarySummary_Export01';
    END

    -- 6. Drop sp_CompanySalarySummary_html
    IF OBJECT_ID('dbo.sp_CompanySalarySummary_html', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.sp_CompanySalarySummary_html;
        PRINT 'Dropped procedure: dbo.sp_CompanySalarySummary_html';
    END

    -- 7. Drop sp_CompanySalarySummary_STD
    IF OBJECT_ID('dbo.sp_CompanySalarySummary_STD', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.sp_CompanySalarySummary_STD;
        PRINT 'Dropped procedure: dbo.sp_CompanySalarySummary_STD';
    END

    -- 8. Drop sp_CompanySalarySummary_view
    IF OBJECT_ID('dbo.sp_CompanySalarySummary_view', 'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.sp_CompanySalarySummary_view;
        PRINT 'Dropped procedure: dbo.sp_CompanySalarySummary_view';
    END

    COMMIT TRANSACTION;
    PRINT 'Cleanup completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'ERROR: ' + ERROR_MESSAGE();
    THROW;
END CATCH
GO
