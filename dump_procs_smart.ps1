$baseProcs = @('sp_REC_ListViewNew','sp_REC_ViewDetailNew','sp_REC_EmailSending')
$allProcs = New-Object System.Collections.Generic.HashSet[string]([StringComparer]::InvariantCultureIgnoreCase)
$queue = New-Object System.Collections.Generic.Queue[string]

foreach ($p in $baseProcs) {
    [void]$allProcs.Add($p)
    [void]$allProcs.Add($p + "_html")
    $queue.Enqueue($p)
    $queue.Enqueue($p + "_html")
}

$procCodes = @{}

Write-Host "Bắt đầu quét phụ thuộc đệ quy các Stored Procedures (sử dụng sqlcmd)..."
while ($queue.Count -gt 0) {
    $current = $queue.Dequeue()
    if ($procCodes.ContainsKey($current)) { continue }

    $tempFile = "temp_$current.txt"
    $sql = "SET NOCOUNT ON; SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.$current'))"
    sqlcmd -E -S .\SQLEXPRESS -d Paradise_HPSF -y 0 -Q $sql -o $tempFile
    
    if (Test-Path $tempFile) {
        $code = Get-Content $tempFile -Raw
        Remove-Item $tempFile -Force
        
        $code = $code -replace '(?m)^-+\s*$', ''
        $code = $code -replace '(?m)^\(\d+ rows affected\)\s*$', ''
        $code = $code.Trim()

        if ($code -notmatch '^NULL$' -and $code.Length -gt 10) {
            $procCodes[$current] = $code
            Write-Host "[OK] Extracted: $current ($($code.Length) bytes)"
            
            $regexStr = '(?i)["'']+(sp_REC_[a-zA-Z0-9_]+)["'']+'
            $matches = [regex]::Matches($code, $regexStr)
            foreach ($m in $matches) {
                $foundProc = $m.Groups[1].Value
                if (-not $allProcs.Contains($foundProc)) {
                    [void]$allProcs.Add($foundProc)
                    $queue.Enqueue($foundProc)
                    Write-Host "  -> Found dependency: $foundProc"
                }
            }
        }
    }
}

$outFile = "x:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526_Procedures_Smart.sql"
$output = New-Object System.Text.StringBuilder
[void]$output.AppendLine("-- =======================================================")
[void]$output.AppendLine("-- TẤT CẢ STORED PROCEDURE LIÊN QUAN ĐẾN 3 MENU (QUÉT TỰ ĐỘNG)")
[void]$output.AppendLine("-- CÁC SP PHỤ THUỘC TÌM THẤY: " + $procCodes.Count)
[void]$output.AppendLine("-- =======================================================")

foreach ($key in $procCodes.Keys) {
    $code = $procCodes[$key]
    $regex = [regex] '(?i)\bCREATE\s+PROC(?:EDURE)?\b'
    $code = $regex.Replace($code, 'CREATE OR ALTER PROCEDURE', 1)

    [void]$output.AppendLine("GO")
    [void]$output.AppendLine($code)
    [void]$output.AppendLine("GO")
}

$tablesQuery = "SET NOCOUNT ON; SELECT name FROM sys.tables WHERE name LIKE 'tblREC%'"
sqlcmd -E -S .\SQLEXPRESS -d Paradise_HPSF -y 0 -Q $tablesQuery -o "temp_tables.txt"
if (Test-Path "temp_tables.txt") {
    $tablesCode = Get-Content "temp_tables.txt" -Raw
    Remove-Item "temp_tables.txt" -Force
    $tablesCode = $tablesCode -replace '(?m)^name\s*$', ''
    $tablesCode = $tablesCode -replace '(?m)^-+\s*$', ''
    $tablesCode = $tablesCode -replace '(?m)^\(\d+ rows affected\)\s*$', ''
    $tableNames = $tablesCode -split "`n" | Where-Object { $_.Trim() -ne '' }
    
    if ($tableNames.Count -gt 0) {
        [void]$output.AppendLine("-- =======================================================")
        [void]$output.AppendLine("-- GHI CHÚ: CÁC TABLE LIÊN QUAN BẮT ĐẦU BẰNG tblREC%")
        [void]$output.AppendLine("-- =======================================================")
        foreach ($t in $tableNames) {
            $tableName = $t.Trim()
            if ($tableName) {
                [void]$output.AppendLine("-- Table: $tableName (Bạn có thể dùng SSMS để Generate Script Create cho table này nếu cần thiết)")
            }
        }
    }
}

[System.IO.File]::WriteAllText($outFile, $output.ToString(), [System.Text.Encoding]::UTF8)

$main = [System.IO.File]::ReadAllText("x:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526.sql", [System.Text.Encoding]::UTF8)
$procs = [System.IO.File]::ReadAllText($outFile, [System.Text.Encoding]::UTF8)

$regexMerge = "(?s)-- \[PHASE 1\] PROCEDURE DDLS.*?-- ----------------------------------------------------------------------------"
$main = $main -replace $regexMerge, $procs

$fullFile = "x:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526_Full.sql"
[System.IO.File]::WriteAllText($fullFile, $main, [System.Text.Encoding]::UTF8)
Write-Host "Hoàn tất Merge script đầy đủ! Tổng số Procedures đã dump: $($procCodes.Count)"
