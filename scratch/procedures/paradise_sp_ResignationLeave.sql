-- ============================================================================
-- Wrapper Procedure: sp_ResignationLeave (Desktop Menu MnuWPT315)
-- ============================================================================
CREATE   PROCEDURE [dbo].[sp_ResignationLeave]
(
    @LoginID INT = 3,
    @LanguageID VARCHAR(2) = 'VN',
    @IdentityID varchar(36) = ''
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT html html FROM dbo.tblHtmlScriptCache WHERE LanguageID = @LanguageID AND ScreenType = -1 AND TableName = 'sp_ResignationLeave';
END;

