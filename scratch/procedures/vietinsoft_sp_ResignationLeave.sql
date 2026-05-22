
CREATE PROCEDURE [dbo].[sp_ResignationLeave]
(
    @LoginID INT = 3,
    @LanguageID VARCHAR(2) = 'VN'
    ,@IdentityID varchar(36) = ''
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @html NVARCHAR(MAX);
    select html html from tblHtmlScriptCache where LanguageID = @LanguageID and ScreenType = -1 and TableName = 'sp_ResignationLeave_Mobile'
END
