-- File: SQL script/cleanup_junk_tables_paradise_dev_20260526.sql
-- Ngày tạo: 2026-05-26
-- Scope: Xoá các bảng rác dbo.aaa, dbo.aaaTempTableData, dbo.aabb, dbo.abc, dbo.abcd, dbo.[1], dbo.[2]
--        và stored procedure liên quan trực tiếp dbo.spDailyAttendanceData_Update.
-- Cảnh báo: User TỰ REVIEW và CHẠY. Agent KHÔNG thực thi tự động.
-- Khuyến nghị: BACKUP database Paradise_Dev trước khi chạy.
-- Chứng cứ:
--   1) Database_Tables_Schema.txt có đủ 7 table trên sau khi chạy db_explorer.py Paradise_Dev.
--   2) sys.sql_expression_dependencies chỉ tìm thấy dbo.spDailyAttendanceData_Update tham chiếu trực tiếp dbo.aaaTempTableData.
--   3) sys.foreign_keys không tìm thấy FK liên quan tới 7 table trên.

USE [Paradise_Dev];
GO

SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -------------------------------------------------------------------------
    -- 1. Drop stored procedures liên quan trực tiếp tới các bảng rác
    -------------------------------------------------------------------------
    IF OBJECT_ID(N'dbo.spDailyAttendanceData_Update', N'P') IS NOT NULL
    BEGIN
        DROP PROCEDURE dbo.spDailyAttendanceData_Update;
        PRINT N'Dropped procedure: dbo.spDailyAttendanceData_Update';
    END
    ELSE
    BEGIN
        PRINT N'Skipped procedure: dbo.spDailyAttendanceData_Update does not exist';
    END

    -------------------------------------------------------------------------
    -- 2. Drop foreign keys nếu phát sinh sau thời điểm kiểm tra
    -------------------------------------------------------------------------
    DECLARE @sql nvarchar(max) = N'';

    SELECT @sql = @sql + N'ALTER TABLE '
        + QUOTENAME(OBJECT_SCHEMA_NAME(fk.parent_object_id)) + N'.' + QUOTENAME(OBJECT_NAME(fk.parent_object_id))
        + N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';'
        + CHAR(13) + CHAR(10)
        + N'PRINT N''Dropped FK: ' + REPLACE(fk.name, '''', '''''') + N''';'
        + CHAR(13) + CHAR(10)
    FROM sys.foreign_keys fk
    WHERE fk.parent_object_id IN (
            OBJECT_ID(N'dbo.aaa'),
            OBJECT_ID(N'dbo.aaaTempTableData'),
            OBJECT_ID(N'dbo.aabb'),
            OBJECT_ID(N'dbo.abc'),
            OBJECT_ID(N'dbo.abcd'),
            OBJECT_ID(N'dbo.[1]'),
            OBJECT_ID(N'dbo.[2]')
        )
       OR fk.referenced_object_id IN (
            OBJECT_ID(N'dbo.aaa'),
            OBJECT_ID(N'dbo.aaaTempTableData'),
            OBJECT_ID(N'dbo.aabb'),
            OBJECT_ID(N'dbo.abc'),
            OBJECT_ID(N'dbo.abcd'),
            OBJECT_ID(N'dbo.[1]'),
            OBJECT_ID(N'dbo.[2]')
        );

    IF NULLIF(@sql, N'') IS NOT NULL
    BEGIN
        EXEC sys.sp_executesql @sql;
    END
    ELSE
    BEGIN
        PRINT N'No FK constraints found for target junk tables';
    END

    -------------------------------------------------------------------------
    -- 3. Drop các bảng rác, idempotent
    -------------------------------------------------------------------------
    IF OBJECT_ID(N'dbo.aaa', N'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.aaa;
        PRINT N'Dropped table: dbo.aaa';
    END
    ELSE
    BEGIN
        PRINT N'Skipped table: dbo.aaa does not exist';
    END

    IF OBJECT_ID(N'dbo.aaaTempTableData', N'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.aaaTempTableData;
        PRINT N'Dropped table: dbo.aaaTempTableData';
    END
    ELSE
    BEGIN
        PRINT N'Skipped table: dbo.aaaTempTableData does not exist';
    END

    IF OBJECT_ID(N'dbo.aabb', N'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.aabb;
        PRINT N'Dropped table: dbo.aabb';
    END
    ELSE
    BEGIN
        PRINT N'Skipped table: dbo.aabb does not exist';
    END

    IF OBJECT_ID(N'dbo.abc', N'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.abc;
        PRINT N'Dropped table: dbo.abc';
    END
    ELSE
    BEGIN
        PRINT N'Skipped table: dbo.abc does not exist';
    END

    IF OBJECT_ID(N'dbo.abcd', N'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.abcd;
        PRINT N'Dropped table: dbo.abcd';
    END
    ELSE
    BEGIN
        PRINT N'Skipped table: dbo.abcd does not exist';
    END

    IF OBJECT_ID(N'dbo.[1]', N'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.[1];
        PRINT N'Dropped table: dbo.[1]';
    END
    ELSE
    BEGIN
        PRINT N'Skipped table: dbo.[1] does not exist';
    END

    IF OBJECT_ID(N'dbo.[2]', N'U') IS NOT NULL
    BEGIN
        DROP TABLE dbo.[2];
        PRINT N'Dropped table: dbo.[2]';
    END
    ELSE
    BEGIN
        PRINT N'Skipped table: dbo.[2] does not exist';
    END

    COMMIT TRANSACTION;
    PRINT N'Cleanup completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT N'Cleanup failed. Transaction rolled back.';
    PRINT N'ERROR_NUMBER: ' + CONVERT(nvarchar(20), ERROR_NUMBER());
    PRINT N'ERROR_MESSAGE: ' + ERROR_MESSAGE();
    THROW;
END CATCH;
GO
