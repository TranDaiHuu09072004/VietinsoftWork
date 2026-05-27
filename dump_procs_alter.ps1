$procs = @('sp_REC_ListViewNew_html','sp_REC_ListViewNew','sp_REC_ViewDetailNew_html','sp_REC_ViewDetailNew','sp_REC_EmailSending_html','sp_REC_EmailSending','sp_REC_GetJobsList','sp_REC_getFieldList','sp_REC_getProvinceList','sp_REC_PopupAddNewCadidate', 'sp_REC_PopupAddNewCadidate_html')

$outFile = "x:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526_Procedures2.sql"
$output = New-Object System.Text.StringBuilder
[void]$output.AppendLine("-- =======================================================")
[void]$output.AppendLine("-- TẤT CẢ STORED PROCEDURE LIÊN QUAN ĐẾN 3 MENU")
[void]$output.AppendLine("-- =======================================================")

foreach ($p in $procs) {
    $q = "SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.$p')) as Code"
    try {
        $res = Invoke-Sqlcmd -Query $q -ServerInstance ".\SQLEXPRESS" -Database "Paradise_HPSF" -MaxCharLength 2147483647
        if ($res.Code) {
            $code = $res.Code
            # Thay thế lệnh CREATE PROCEDURE đầu tiên thành CREATE OR ALTER PROCEDURE
            $regex = [regex] '(?i)\bCREATE\s+PROC(?:EDURE)?\b'
            $code = $regex.Replace($code, 'CREATE OR ALTER PROCEDURE', 1)

            [void]$output.AppendLine("GO")
            [void]$output.AppendLine($code)
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

# Merge back to Full SQL
$main = [System.IO.File]::ReadAllText("x:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526.sql", [System.Text.Encoding]::UTF8)
$procs = [System.IO.File]::ReadAllText($outFile, [System.Text.Encoding]::UTF8)

$regexMerge = "(?s)-- \[PHASE 1\] PROCEDURE DDLS.*?-- ----------------------------------------------------------------------------"
$main = $main -replace $regexMerge, $procs

$fullFile = "x:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526_Full.sql"
[System.IO.File]::WriteAllText($fullFile, $main, [System.Text.Encoding]::UTF8)
Write-Host "Done"
