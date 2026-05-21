-- ============================================================================
-- File   : SQL script/cleanup_menu_aspx_20260520.sql
-- Mục đích: Xoá toàn bộ menu Web kiểu ASPX-style (URL trỏ tới *.aspx) — kiểu này
--           đã được user xác nhận lỗi thời. ParadiseHR hiện chỉ dùng menu
--           Web kiểu HTML-rendered (cặp procedure wrapper + renderer + cache).
-- Phạm vi:
--   - 6 menu trong MEN_Menu có URL = '*.aspx' (đã xác minh từ DB ngày 2026-05-20):
--       MnuAtt1            /ATT/LeaveHistory.aspx       (IsVisible=1)
--       MnuAtt3            /ATT/LeaveSummary1.aspx      (IsVisible=1)
--       MnuEmployeeInfo    /EmpInfo.aspx                (IsVisible=1)
--       MnuPRL1            /PRL/Payslip.aspx            (IsVisible=1)
--       MnuATTAppOT        /ATT/ApprovalOTList.aspx     (IsVisible=0)
--       MnuATTOTRe         /ATT/OTRegistration.aspx     (IsVisible=0)
--   - 3 parent label orphan trong tblMD_Message (KHÔNG còn record trong MEN_Menu):
--       MnuWebATT, MnuWebHRM, MnuWebPRL
-- Đã xác minh: KHÔNG có entry nào trong tblSC_Object / tblSC_Right_Stored /
--             tblSC_GroupRight cho 6 menu ASPX trên → script chỉ đụng
--             MEN_Menu và tblMD_Message.
-- Cảnh báo: USER tự review và CHẠY. Không tự động thực thi. BACKUP DB trước.
-- Idempotent: chạy nhiều lần không lỗi (dùng IF EXISTS + check trước khi xoá).
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

PRINT '======================================================================';
PRINT 'CLEANUP ASPX MENUS — ParadiseHR';
PRINT 'Date: 2026-05-20';
PRINT '======================================================================';
GO

BEGIN TRY
    BEGIN TRANSACTION;

    -- ------------------------------------------------------------------
    -- Bảng tạm chứa danh sách MenuID ASPX cần xoá khỏi MEN_Menu + tblMD_Message
    -- ------------------------------------------------------------------
    DECLARE @AspxMenus TABLE (MenuID VARCHAR(100) PRIMARY KEY);
    INSERT INTO @AspxMenus(MenuID)
    VALUES ('MnuAtt1'),
           ('MnuAtt3'),
           ('MnuEmployeeInfo'),
           ('MnuPRL1'),
           ('MnuATTAppOT'),
           ('MnuATTOTRe');

    -- Bảng tạm chứa parent label orphan chỉ trong tblMD_Message (không có ở MEN_Menu)
    DECLARE @OrphanLabels TABLE (MessageID VARCHAR(100) PRIMARY KEY);
    INSERT INTO @OrphanLabels(MessageID)
    VALUES ('MnuWebATT'),
           ('MnuWebHRM'),
           ('MnuWebPRL');

    -- ------------------------------------------------------------------
    -- BƯỚC 1 — An toàn: xoá tblSC_Right_Stored / tblSC_GroupRight nếu có
    --                   (đã verify hiện không có dòng nào, nhưng vẫn check để idempotent)
    -- ------------------------------------------------------------------
    DECLARE @cnt INT;

    SELECT @cnt = COUNT(*)
    FROM   tblSC_Right_Stored r
    JOIN   tblSC_Object o ON o.ObjectID = r.ObjectID
    WHERE  o.Description IN (SELECT MenuID FROM @AspxMenus);

    IF @cnt > 0
    BEGIN
        DELETE r
        FROM   tblSC_Right_Stored r
        JOIN   tblSC_Object o ON o.ObjectID = r.ObjectID
        WHERE  o.Description IN (SELECT MenuID FROM @AspxMenus);
        PRINT  '[OK] Deleted ' + CAST(@cnt AS VARCHAR(10)) + ' rows from tblSC_Right_Stored';
    END
    ELSE
        PRINT  '[SKIP] tblSC_Right_Stored: nothing to delete';

    SELECT @cnt = COUNT(*)
    FROM   tblSC_GroupRight g
    JOIN   tblSC_Object o ON o.ObjectID = g.ObjectID
    WHERE  o.Description IN (SELECT MenuID FROM @AspxMenus);

    IF @cnt > 0
    BEGIN
        DELETE g
        FROM   tblSC_GroupRight g
        JOIN   tblSC_Object o ON o.ObjectID = g.ObjectID
        WHERE  o.Description IN (SELECT MenuID FROM @AspxMenus);
        PRINT  '[OK] Deleted ' + CAST(@cnt AS VARCHAR(10)) + ' rows from tblSC_GroupRight';
    END
    ELSE
        PRINT  '[SKIP] tblSC_GroupRight: nothing to delete';

    -- ------------------------------------------------------------------
    -- BƯỚC 2 — Xoá tblSC_Object (nếu có)
    -- ------------------------------------------------------------------
    SELECT @cnt = COUNT(*)
    FROM   tblSC_Object
    WHERE  Description IN (SELECT MenuID FROM @AspxMenus);

    IF @cnt > 0
    BEGIN
        DELETE FROM tblSC_Object
        WHERE  Description IN (SELECT MenuID FROM @AspxMenus);
        PRINT  '[OK] Deleted ' + CAST(@cnt AS VARCHAR(10)) + ' rows from tblSC_Object';
    END
    ELSE
        PRINT  '[SKIP] tblSC_Object: nothing to delete';

    -- ------------------------------------------------------------------
    -- BƯỚC 3 — Xoá tblMD_Message: cả label của 6 ASPX menu + 3 parent orphan
    -- ------------------------------------------------------------------
    DECLARE @cntAspx INT, @cntOrphan INT;

    SELECT @cntAspx = COUNT(*)
    FROM   tblMD_Message
    WHERE  MessageID IN (SELECT MenuID FROM @AspxMenus);

    IF @cntAspx > 0
    BEGIN
        DELETE FROM tblMD_Message
        WHERE  MessageID IN (SELECT MenuID FROM @AspxMenus);
        PRINT  '[OK] Deleted ' + CAST(@cntAspx AS VARCHAR(10)) + ' rows from tblMD_Message (ASPX menus)';
    END
    ELSE
        PRINT  '[SKIP] tblMD_Message (ASPX menus): nothing to delete';

    SELECT @cntOrphan = COUNT(*)
    FROM   tblMD_Message
    WHERE  MessageID IN (SELECT MessageID FROM @OrphanLabels);

    IF @cntOrphan > 0
    BEGIN
        DELETE FROM tblMD_Message
        WHERE  MessageID IN (SELECT MessageID FROM @OrphanLabels);
        PRINT  '[OK] Deleted ' + CAST(@cntOrphan AS VARCHAR(10)) + ' rows from tblMD_Message (orphan parent labels: MnuWebATT, MnuWebHRM, MnuWebPRL)';
    END
    ELSE
        PRINT  '[SKIP] tblMD_Message (orphan parent labels): nothing to delete';

    -- ------------------------------------------------------------------
    -- BƯỚC 4 — Xoá MEN_Menu (CUỐI CÙNG — sau khi đã handle tham chiếu)
    -- ------------------------------------------------------------------
    SELECT @cnt = COUNT(*)
    FROM   MEN_Menu
    WHERE  MenuID IN (SELECT MenuID FROM @AspxMenus);

    IF @cnt > 0
    BEGIN
        DELETE FROM MEN_Menu
        WHERE  MenuID IN (SELECT MenuID FROM @AspxMenus);
        PRINT  '[OK] Deleted ' + CAST(@cnt AS VARCHAR(10)) + ' rows from MEN_Menu (ASPX menus)';
    END
    ELSE
        PRINT  '[SKIP] MEN_Menu: nothing to delete';

    COMMIT TRANSACTION;

    PRINT '======================================================================';
    PRINT '[DONE] Cleanup ASPX menus thành công.';
    PRINT '======================================================================';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    DECLARE @errMsg NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @errLine INT = ERROR_LINE();
    PRINT '[ERROR] Line ' + CAST(@errLine AS VARCHAR(10)) + ': ' + @errMsg;
    THROW;
END CATCH
GO

-- ----------------------------------------------------------------------------
-- VERIFY — chạy SAU CÙNG để chắc chắn không còn record ASPX nào sót.
-- Output mong đợi: tất cả COUNT = 0.
-- ----------------------------------------------------------------------------
SELECT 'MEN_Menu ASPX còn sót'             AS Metric,
       COUNT(*) AS Cnt
FROM   MEN_Menu
WHERE  MenuID IN ('MnuAtt1','MnuAtt3','MnuEmployeeInfo','MnuPRL1','MnuATTAppOT','MnuATTOTRe')
UNION ALL
SELECT 'MEN_Menu URL .aspx khác còn sót',
       COUNT(*)
FROM   MEN_Menu
WHERE  ISNULL(URL,'') LIKE '%.aspx%'
UNION ALL
SELECT 'tblMD_Message label ASPX còn sót',
       COUNT(*)
FROM   tblMD_Message
WHERE  MessageID IN ('MnuAtt1','MnuAtt3','MnuEmployeeInfo','MnuPRL1','MnuATTAppOT','MnuATTOTRe',
                     'MnuWebATT','MnuWebHRM','MnuWebPRL')
UNION ALL
SELECT 'tblSC_Object ASPX còn sót',
       COUNT(*)
FROM   tblSC_Object
WHERE  Description IN ('MnuAtt1','MnuAtt3','MnuEmployeeInfo','MnuPRL1','MnuATTAppOT','MnuATTOTRe');
GO

-- ----------------------------------------------------------------------------
-- CẢNH BÁO ORPHAN CÒN LẠI
-- Sau khi xoá parent ASPX, kiểm tra menu con nào còn ParentMenuID trỏ tới parent đã xoá.
-- Script CHỈ in cảnh báo, KHÔNG tự xử lý (user quyết định re-parent hay xoá).
-- ----------------------------------------------------------------------------
PRINT '----------------------------------------------------------------------';
PRINT '[WARNING] Các menu còn lại có ParentMenuID trỏ tới parent đã xoá:';
PRINT '----------------------------------------------------------------------';
SELECT m.MenuID, m.ParentMenuID, m.AssemblyName, m.ClassName, m.IsVisible
FROM   MEN_Menu m
WHERE  m.ParentMenuID IN ('MnuWebATT','MnuWebHRM','MnuWebPRL')
ORDER BY m.ParentMenuID, m.MenuID;
GO

-- ----------------------------------------------------------------------------
-- LƯU Ý — KHÔNG cần gọi sp_Men_Menu_AfterSave_Simple / sp_UpdateMenuInUserRight
--         sau cleanup:
--   - sp_Men_Menu_AfterSave_Simple @ClassName chỉ refresh cache 1 menu cụ thể vừa
--     SAVE/CREATE (không có ý nghĩa khi đang DELETE).
--   - sp_UpdateMenuInUserRight @ObjectID chỉ insert quyền cho 1 ObjectID mới —
--     ObjectID của menu đã xoá là vô nghĩa.
-- User chỉ cần LOGOUT/LOGIN để app load lại cây menu (các menu ASPX biến mất).
-- ----------------------------------------------------------------------------
PRINT '[INFO] User cần logout/login để app cập nhật cây menu sau cleanup.';
GO
