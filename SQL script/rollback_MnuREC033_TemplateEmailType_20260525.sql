/* =============================================================================
   rollback_MnuREC033_TemplateEmailType_20260525.sql
   ---------------------------------------------------------------------------
   Mục đích:
     Xóa hoàn toàn menu MnuREC033 (Loại Template Email) và các đối tượng
     cơ sở dữ liệu liên quan để dọn dẹp hệ thống.
   
   Các đối tượng sẽ xóa:
     1. Menu record MnuREC033 trong bảng MEN_Menu.
     2. Bản ghi phân quyền và đối tượng trong tblSC_Right_Stored và tblSC_Object.
     3. Drop các stored procedure được tạo hoặc khôi phục:
        - sp_REC_TemplateEmailType (Wrapper Grid)
        - sp_REC_TemplateEmailTypeList (Data SP)
        - sp_REC_TemplateEmailType_html (Renderer Grid)
        - sp_REC_EditTemplateEmailType (Wrapper Popup Edit)
        - sp_REC_EditTemplateEmailType_html (Renderer Popup Edit)
        - sp_REC_TemplateEmailTypeEdit (Save Action SP)
     4. Xóa cache giao diện HTML liên quan trong tblHtmlScriptCache.
     5. Reset cache menu trên client bằng sp_Men_Menu_AfterSave_Simple.
   
   Database: Paradise_Dev (SVRVTS01\SQL2022)
   ============================================================================= */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'================================================================';
PRINT N' BẮT ĐẦU DỌN DẸP / XÓA MENU MnuREC033 VÀ CÁC ĐỐI TƯỢNG LIÊN QUAN';
PRINT N'================================================================';
GO

/* =============================================================================
   1. XÓA CONFIG MENU TRONG MEN_Menu
   ============================================================================= */
PRINT N'1. Xóa cấu hình Menu MnuREC033 trong MEN_Menu...';
GO

IF EXISTS (SELECT 1 FROM dbo.MEN_Menu WHERE MenuID = 'MnuREC033')
BEGIN
    DELETE FROM dbo.MEN_Menu WHERE MenuID = 'MnuREC033';
    PRINT N'  [OK] Đã xóa menu MnuREC033 khỏi MEN_Menu.';
END
ELSE
BEGIN
    PRINT N'  [Info] Menu MnuREC033 không tồn tại trong MEN_Menu.';
END
GO

/* =============================================================================
   2. XÓA PHÂN QUYỀN VÀ BẢO MẬT
   ============================================================================= */
PRINT N'2. Xóa phân quyền và đối tượng bảo mật liên quan đến MnuREC033...';
GO

-- Xóa các quyền được gán cho menu MnuREC033
DELETE FROM dbo.tblSC_Right_Stored
WHERE ObjectID IN (SELECT ObjectID FROM dbo.tblSC_Object WHERE Description = 'MnuREC033');

-- Xóa đối tượng bảo mật của menu MnuREC033
DELETE FROM dbo.tblSC_Object
WHERE Description = 'MnuREC033';

PRINT N'  [OK] Đã dọn dẹp tblSC_Right_Stored và tblSC_Object.';
GO

/* =============================================================================
   3. DROP CÁC STORED PROCEDURE LIÊN QUAN
   ============================================================================= */
PRINT N'3. DROP các stored procedure nghiệp vụ và giao diện...';
GO

DROP PROCEDURE IF EXISTS [dbo].[sp_REC_TemplateEmailType];
DROP PROCEDURE IF EXISTS [dbo].[sp_REC_TemplateEmailTypeList];
DROP PROCEDURE IF EXISTS [dbo].[sp_REC_TemplateEmailType_html];
DROP PROCEDURE IF EXISTS [dbo].[sp_REC_EditTemplateEmailType];
DROP PROCEDURE IF EXISTS [dbo].[sp_REC_EditTemplateEmailType_html];
DROP PROCEDURE IF EXISTS [dbo].[sp_REC_TemplateEmailTypeEdit];

PRINT N'  [OK] Đã DROP các stored procedure liên quan.';
GO

/* =============================================================================
   4. DỌN DẸP HTML CACHE TRONG tblHtmlScriptCache
   ============================================================================= */
PRINT N'4. Xóa cache HTML trong tblHtmlScriptCache...';
GO

DELETE FROM dbo.tblHtmlScriptCache 
WHERE TableName IN (
    N'sp_REC_TemplateEmailType', 
    N'sp_REC_TemplateEmailType_html', 
    N'sp_REC_EditTemplateEmailType', 
    N'sp_REC_EditTemplateEmailType_html'
);

PRINT N'  [OK] Đã xóa các bản ghi cache HTML liên quan.';
GO

/* =============================================================================
   5. RESET CACHE MENU HỆ THỐNG
   ============================================================================= */
PRINT N'5. Reset Menu Cache hệ thống...';
GO

EXEC dbo.sp_Men_Menu_AfterSave_Simple;
PRINT N'  [OK] Đã đồng bộ lại Menu Cache.';
GO

PRINT N'================================================================';
PRINT N' HOÀN TẤT DỌN DẸP MENU MnuREC033 VÀ CÁC ĐỐI TƯỢNG LIÊN QUAN.';
PRINT N'================================================================';
GO
