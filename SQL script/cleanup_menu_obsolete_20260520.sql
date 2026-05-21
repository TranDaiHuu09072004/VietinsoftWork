-- =====================================================================
-- File:        cleanup_menu_obsolete_20260520.sql
-- Mục đích:    Xoá 2 menu lỗi thời đã được user xác nhận ngày 2026-05-20:
--                - MnuATTAppOT  (Duyệt tăng ca — URL /ATT/ApprovalOTList.aspx)
--                - MnuWebATT    (Quản lý chấm công — orphan parent, đã không
--                                tồn tại trong MEN_Menu nhưng còn label trong
--                                tblMD_Message)
-- Tác giả:     Agent (built from verified DB state, 2026-05-20)
-- Database:    Vietinsoft_Pay
-- =====================================================================
-- CẢNH BÁO:
--   1. User TỰ REVIEW và CHẠY. Agent KHÔNG thực thi tự động.
--   2. BACKUP DATABASE TRƯỚC KHI CHẠY.
--   3. Script idempotent — chạy nhiều lần không lỗi.
--   4. Script không bao gồm `tblSC_Object` / `tblSC_Right_Stored` /
--      `tblSC_GroupRight` vì đã verify cả 2 menu KHÔNG có object phân quyền.
--   5. ⚠️ ORPHAN CON: sau khi xoá MnuWebATT, 3 menu con sau vẫn còn
--      ParentMenuID = 'MnuWebATT' (đã không tồn tại):
--          MnuAtt1, MnuAtt3, MnuATTOTRe
--      → User cần quyết định riêng: re-parent về menu hợp lệ, hoặc xoá
--        bằng script tiếp theo (nếu cũng đã lỗi thời). Script này KHÔNG
--        tự động xử lý 3 menu con.
-- =====================================================================

USE [Vietinsoft_Pay];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    PRINT '=== Cleanup MnuATTAppOT + MnuWebATT — start ===';

    ---------------------------------------------------------------------
    -- 1. Cảnh báo orphan children (chỉ in cảnh báo, không xoá)
    ---------------------------------------------------------------------
    DECLARE @OrphanChildren NVARCHAR(MAX);
    SELECT @OrphanChildren = STRING_AGG(MenuID, ', ')
    FROM MEN_Menu
    WHERE ParentMenuID = 'MnuWebATT' AND MenuID <> 'MnuATTAppOT';

    IF @OrphanChildren IS NOT NULL
        PRINT '[WARN] Sau khi xoá MnuWebATT, các menu con sau sẽ bị orphan: '
              + @OrphanChildren
              + '. User cần re-parent hoặc xoá riêng.';

    ---------------------------------------------------------------------
    -- 2. Xoá MnuATTAppOT (Duyệt tăng ca)
    ---------------------------------------------------------------------
    PRINT '--- Xoá MnuATTAppOT ---';

    -- 2a. tblMD_Message (VN + EN)
    DECLARE @cnt_msg_appot INT;
    DELETE FROM tblMD_Message WHERE MessageID = 'MnuATTAppOT';
    SET @cnt_msg_appot = @@ROWCOUNT;
    PRINT '   tblMD_Message: deleted ' + CAST(@cnt_msg_appot AS VARCHAR) + ' row(s)';

    -- 2b. tblSC_Object (verify cấp đầu nếu có)
    DECLARE @cnt_obj_appot INT;
    DELETE FROM tblSC_Right_Stored
        WHERE ObjectID IN (SELECT ObjectID FROM tblSC_Object WHERE Description = 'MnuATTAppOT');
    DELETE FROM tblSC_GroupRight
        WHERE ObjectID IN (SELECT ObjectID FROM tblSC_Object WHERE Description = 'MnuATTAppOT');
    DELETE FROM tblSC_Object WHERE Description = 'MnuATTAppOT';
    SET @cnt_obj_appot = @@ROWCOUNT;
    PRINT '   tblSC_Object: deleted ' + CAST(@cnt_obj_appot AS VARCHAR) + ' row(s)';

    -- 2c. MEN_Menu
    DECLARE @cnt_menu_appot INT;
    DELETE FROM MEN_Menu WHERE MenuID = 'MnuATTAppOT';
    SET @cnt_menu_appot = @@ROWCOUNT;
    PRINT '   MEN_Menu: deleted ' + CAST(@cnt_menu_appot AS VARCHAR) + ' row(s)';

    ---------------------------------------------------------------------
    -- 3. Xoá MnuWebATT (Quản lý chấm công — orphan parent)
    --    Tại thời điểm verify, MEN_Menu KHÔNG có record này, chỉ còn lại
    --    label trong tblMD_Message. Script vẫn cover đủ các bảng để an toàn.
    ---------------------------------------------------------------------
    PRINT '--- Xoá MnuWebATT ---';

    DECLARE @cnt_msg_webatt INT;
    DELETE FROM tblMD_Message WHERE MessageID = 'MnuWebATT';
    SET @cnt_msg_webatt = @@ROWCOUNT;
    PRINT '   tblMD_Message: deleted ' + CAST(@cnt_msg_webatt AS VARCHAR) + ' row(s)';

    DECLARE @cnt_obj_webatt INT;
    DELETE FROM tblSC_Right_Stored
        WHERE ObjectID IN (SELECT ObjectID FROM tblSC_Object WHERE Description = 'MnuWebATT');
    DELETE FROM tblSC_GroupRight
        WHERE ObjectID IN (SELECT ObjectID FROM tblSC_Object WHERE Description = 'MnuWebATT');
    DELETE FROM tblSC_Object WHERE Description = 'MnuWebATT';
    SET @cnt_obj_webatt = @@ROWCOUNT;
    PRINT '   tblSC_Object: deleted ' + CAST(@cnt_obj_webatt AS VARCHAR) + ' row(s)';

    DECLARE @cnt_menu_webatt INT;
    DELETE FROM MEN_Menu WHERE MenuID = 'MnuWebATT';
    SET @cnt_menu_webatt = @@ROWCOUNT;
    PRINT '   MEN_Menu: deleted ' + CAST(@cnt_menu_webatt AS VARCHAR) + ' row(s)';

    ---------------------------------------------------------------------
    -- 4. KHÔNG gọi sp_Men_Menu_AfterSave_Simple / sp_UpdateMenuInUserRight ở đây
    --    vì cả 2 proc YÊU CẦU tham số (@ClassName / @ObjectID) chỉ dành cho menu
    --    đang được SAVE/CREATE — không có ý nghĩa khi đang DELETE.
    --    User chỉ cần logout/login để app load lại cây menu.
    ---------------------------------------------------------------------
    PRINT '   [INFO] Không cần refresh — user logout/login để cây menu cập nhật.';

    COMMIT TRANSACTION;
    PRINT '=== Cleanup completed successfully. ===';
    PRINT '    User cần logout/login để cây menu được load lại.';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT '[ERROR] ' + ERROR_MESSAGE();
    THROW;
END CATCH
GO
