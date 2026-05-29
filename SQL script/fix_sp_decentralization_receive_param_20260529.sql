-- ============================================================
-- File: fix_sp_decentralization_receive_param_20260529.sql
-- Mục đích: Patch sp_decentralization — thêm đọc tham số từ
--           openFormParam routing qua sp_decentralization_param.
--           Pattern: <ClassName>_param (xem Knowledge/21_SPA_Routing.md)
--           Production code GIỮ NGUYÊN 100%, chỉ thêm 5 dòng JS.
-- DB đích: Paradise_Dev
-- Ngày:   2026-05-29
-- Cảnh báo: User TỰ REVIEW và CHẠY.
-- ============================================================
SET NOCOUNT ON;
GO

USE [Paradise_Dev];
GO

-- ============================================================
-- Đọc source production, thêm _param check sau initLabels()
-- ============================================================
DECLARE @src NVARCHAR(MAX);
SELECT @src = OBJECT_DEFINITION(OBJECT_ID('dbo.sp_decentralization'));

-- Tìm đoạn cuối JS: initLabels(); [newline]     if(getLogin()) loadData();
-- Thêm block đọc sp_decentralization_param vào giữa
DECLARE @oldTail NVARCHAR(100) = 'initLabels();' + CHAR(13) + CHAR(10) + '    if(getLogin()) loadData();';
DECLARE @newTail NVARCHAR(500) = 'initLabels();' + CHAR(13) + CHAR(10)
    + '    var routedParam = window.sp_decentralization_param;' + CHAR(13) + CHAR(10)
    + '    if(routedParam && routedParam.LoginAccount){' + CHAR(13) + CHAR(10)
    + '        if(!getLogin()) byId("scr699Login").value = routedParam.LoginAccount;' + CHAR(13) + CHAR(10)
    + '        loadData();' + CHAR(13) + CHAR(10)
    + '    } else {' + CHAR(13) + CHAR(10)
    + '        if(getLogin()) loadData();' + CHAR(13) + CHAR(10)
    + '    }';

IF CHARINDEX(@oldTail, @src) = 0
BEGIN
    -- Thử LF thay CRLF
    SET @oldTail = 'initLabels();' + CHAR(10) + '    if(getLogin()) loadData();';
    SET @newTail = 'initLabels();' + CHAR(10)
        + '    var routedParam = window.sp_decentralization_param;' + CHAR(10)
        + '    if(routedParam && routedParam.LoginAccount){' + CHAR(10)
        + '        if(!getLogin()) byId("scr699Login").value = routedParam.LoginAccount;' + CHAR(10)
        + '        loadData();' + CHAR(10)
        + '    } else {' + CHAR(10)
        + '        if(getLogin()) loadData();' + CHAR(10)
        + '    }';
END

IF CHARINDEX(@oldTail, @src) = 0
BEGIN
    PRINT 'ERROR: Cannot find target pattern in sp_decentralization.';
    PRINT 'The procedure may have been modified. Please review manually.';
    RETURN;
END

SET @src = REPLACE(@src, @oldTail, @newTail);

-- CREATE → ALTER
IF LEFT(LTRIM(@src), 6) = 'CREATE'
    SET @src = STUFF(@src, CHARINDEX('CREATE', @src), 6, 'ALTER');

EXEC sp_executesql @src;
PRINT 'OK sp_decentralization patched.';
GO

-- ============================================================
-- REBUILD CACHE (BẮT BUỘC sau khi sửa renderer)
-- ============================================================
DELETE FROM dbo.tblHtmlScriptCache WHERE TableName = 'sp_decentralization';
EXEC dbo.sp_GenerateHTMLScript 'sp_decentralization';

SELECT TableName, LanguageID, ScreenType, DATALENGTH(html) AS HtmlBytes, Version
FROM dbo.tblHtmlScriptCache
WHERE TableName = 'sp_decentralization'
ORDER BY LanguageID;
GO

PRINT '';
PRINT '=== PATCH COMPLETE ===';
PRINT 'Added: sp_decentralization_param routing support (5 lines)';
PRINT 'Cache rebuilt.';
PRINT '';
PRINT 'Test: click row in User Management grid';
PRINT '  -> sp_decentralization opens with LoginAccount pre-filled + auto-loaded.';
GO
