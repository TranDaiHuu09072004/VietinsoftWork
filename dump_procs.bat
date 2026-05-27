@echo off
set OUT_FILE="SQL script\migrate_menu_REC_20260526_Procedures.sql"
echo -- ============================================================================ > %OUT_FILE%
echo -- STORED PROCEDURES >> %OUT_FILE%
echo -- ============================================================================ >> %OUT_FILE%
echo GO >> %OUT_FILE%

sqlcmd -E -S .\SQLEXPRESS -d Paradise_HPSF -y 0 -Q "SET NOCOUNT ON; SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_REC_ListViewNew_html'))" >> %OUT_FILE%
echo GO >> %OUT_FILE%
sqlcmd -E -S .\SQLEXPRESS -d Paradise_HPSF -y 0 -Q "SET NOCOUNT ON; SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_REC_ListViewNew'))" >> %OUT_FILE%
echo GO >> %OUT_FILE%
sqlcmd -E -S .\SQLEXPRESS -d Paradise_HPSF -y 0 -Q "SET NOCOUNT ON; SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_REC_ViewDetailNew_html'))" >> %OUT_FILE%
echo GO >> %OUT_FILE%
sqlcmd -E -S .\SQLEXPRESS -d Paradise_HPSF -y 0 -Q "SET NOCOUNT ON; SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_REC_ViewDetailNew'))" >> %OUT_FILE%
echo GO >> %OUT_FILE%
sqlcmd -E -S .\SQLEXPRESS -d Paradise_HPSF -y 0 -Q "SET NOCOUNT ON; SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_REC_EmailSending_html'))" >> %OUT_FILE%
echo GO >> %OUT_FILE%
sqlcmd -E -S .\SQLEXPRESS -d Paradise_HPSF -y 0 -Q "SET NOCOUNT ON; SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_REC_EmailSending'))" >> %OUT_FILE%
echo GO >> %OUT_FILE%

echo -- Bảng tạm và procedure phụ trợ >> %OUT_FILE%
sqlcmd -E -S .\SQLEXPRESS -d Paradise_HPSF -y 0 -Q "SET NOCOUNT ON; SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_REC_GetJobsList'))" >> %OUT_FILE%
echo GO >> %OUT_FILE%
sqlcmd -E -S .\SQLEXPRESS -d Paradise_HPSF -y 0 -Q "SET NOCOUNT ON; SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_REC_getFieldList'))" >> %OUT_FILE%
echo GO >> %OUT_FILE%
sqlcmd -E -S .\SQLEXPRESS -d Paradise_HPSF -y 0 -Q "SET NOCOUNT ON; SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_REC_getProvinceList'))" >> %OUT_FILE%
echo GO >> %OUT_FILE%
sqlcmd -E -S .\SQLEXPRESS -d Paradise_HPSF -y 0 -Q "SET NOCOUNT ON; SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_REC_PopupAddNewCadidate'))" >> %OUT_FILE%
echo GO >> %OUT_FILE%
