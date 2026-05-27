$procs = @('sp_REC_ListViewNew_html','sp_REC_ListViewNew','sp_REC_ViewDetailNew_html','sp_REC_ViewDetailNew','sp_REC_EmailSending_html','sp_REC_EmailSending','sp_REC_GetJobsList','sp_REC_getFieldList','sp_REC_getProvinceList','sp_REC_PopupAddNewCadidate', 'sp_REC_PopupAddNewCadidate_html')

$outFile = "X:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526_Procedures2.sql"
$output = New-Object System.Text.StringBuilder
[void]$output.AppendLine("-- =======================================================")
[void]$output.AppendLine("-- TẤT CẢ STORED PROCEDURE LIÊN QUAN ĐẾN 3 MENU")
[void]$output.AppendLine("-- =======================================================")

foreach ($p in $procs) {
    $q = "SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.$p')) as Code"
    try {
        $res = Invoke-Sqlcmd -Query $q -ServerInstance ".\SQLEXPRESS" -Database "Paradise_HPSF" -MaxCharLength 2147483647
        if ($res.Code) {
            [void]$output.AppendLine("GO")
            [void]$output.AppendLine("IF OBJECT_ID('dbo.$p') IS NOT NULL DROP PROCEDURE dbo.$p;")
            [void]$output.AppendLine("GO")
            [void]$output.AppendLine($res.Code)
            [void]$output.AppendLine("GO")
        }
    } catch {
        Write-Host "Failed to dump $p"
    }
}

# DUMP Tables (We'll dump tblREC_*)
$tablesQuery = "SELECT name FROM sys.tables WHERE name LIKE 'tblREC%'"
$tables = Invoke-Sqlcmd -Query $tablesQuery -ServerInstance ".\SQLEXPRESS" -Database "Paradise_HPSF"
if ($tables) {
    [void]$output.AppendLine("-- =======================================================")
    [void]$output.AppendLine("-- GHI CHÚ: CÁC TABLE LIÊN QUAN BẮT ĐẦU BẰNG tblREC%")
    [void]$output.AppendLine("-- =======================================================")
    foreach ($t in $tables) {
        $tableName = $t.name
        [void]$output.AppendLine("-- Table: $tableName (Bạn có thể dùng SSMS để Generate Script Create cho table này nếu cần thiết)")
    }
}

[System.IO.File]::WriteAllText($outFile, $output.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "Done writing to $outFile"
