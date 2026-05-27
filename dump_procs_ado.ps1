$connString = "Server=192.168.11.51,2222;Database=Paradise_DEV;User Id=vts;Password=LuaThieng1@3@2020;TrustServerCertificate=True"
$conn = New-Object System.Data.SqlClient.SqlConnection($connString)
$conn.Open()

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

Write-Host "Bắt đầu quét phụ thuộc đệ quy các Stored Procedures trên Paradise_DEV (sử dụng ADO.NET)..."

while ($queue.Count -gt 0) {
    $current = $queue.Dequeue()
    if ($procCodes.ContainsKey($current)) { continue }

    $cmd = $conn.CreateCommand()
    $cmd.CommandText = "SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.$current'))"
    $code = $cmd.ExecuteScalar()

    if ($null -ne $code -and $code -is [string] -and $code.Length -gt 10) {
        $procCodes[$current] = $code
        Write-Host "[OK] Extracted: $current ($($code.Length) bytes)"
        
        # Quét dependency: tìm các chuỗi 'sp_REC_...' hoặc "sp_REC_..."
        $regexStr = '(?i)["'']+(sp_REC_[a-zA-Z0-9_]+)["'']+'
        $matches = [regex]::Matches($code, $regexStr)
        foreach ($m in $matches) {
            $foundProc = $m.Groups[1].Value
            if (-not $allProcs.Contains($foundProc)) {
                [void]$allProcs.Add($foundProc)
                $queue.Enqueue($foundProc)
                Write-Host "  -> Found dependency: $foundProc"
                
                # Nếu proc này có _html, thêm luôn html vào hàng đợi
                $htmlProc = $foundProc + "_html"
                if (-not $allProcs.Contains($htmlProc)) {
                    [void]$allProcs.Add($htmlProc)
                    $queue.Enqueue($htmlProc)
                }
            }
        }
    }
}

$conn.Close()

$outFile = "x:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526_Procedures_Smart.sql"
$output = New-Object System.Text.StringBuilder
[void]$output.AppendLine("-- =======================================================")
[void]$output.AppendLine("-- TẤT CẢ STORED PROCEDURE LIÊN QUAN ĐẾN 3 MENU (QUÉT TỰ ĐỘNG BẰNG ADO.NET TỪ PARADISE_DEV)")
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

# Dump table hints
$tablesQuery = "SET NOCOUNT ON; SELECT name FROM sys.tables WHERE name LIKE 'tblREC%'"
$tablesOutput = (sqlcmd -S "192.168.11.51,2222" -U "vts" -P "LuaThieng1@3@2020" -d Paradise_DEV -y 0 -Q $tablesQuery) -join "`n"
$tablesOutput = $tablesOutput -replace '(?m)^name\s*$', ''
$tablesOutput = $tablesOutput -replace '(?m)^-+\s*$', ''
$tablesOutput = $tablesOutput -replace '(?m)^\(\d+ rows affected\)\s*$', ''
$tableNames = $tablesOutput -split "`n" | Where-Object { $_.Trim() -ne '' }

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

[System.IO.File]::WriteAllText($outFile, $output.ToString(), [System.Text.Encoding]::UTF8)

# Merge back to Full SQL
$main = [System.IO.File]::ReadAllText("x:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526.sql", [System.Text.Encoding]::UTF8)
$procs = [System.IO.File]::ReadAllText($outFile, [System.Text.Encoding]::UTF8)

$regexMerge = "(?s)-- \[PHASE 1\] PROCEDURE DDLS.*?-- ----------------------------------------------------------------------------"
$main = $main -replace $regexMerge, $procs

# Tìm tất cả _html procedures đã được dump
$htmlProcs = $procCodes.Keys | Where-Object { $_ -like "*_html" }

if ($htmlProcs.Count -gt 0) {
    $phase5 = New-Object System.Text.StringBuilder
    [void]$phase5.AppendLine("`n-- ============================================================================")
    [void]$phase5.AppendLine("-- [PHASE 5] CẬP NHẬT GIAO DIỆN WEB CHO CÁC RENDERER (_html)")
    [void]$phase5.AppendLine("-- Mục đích: Load control vào layout và cập nhật cache tblHtmlScriptCache")
    [void]$phase5.AppendLine("-- ============================================================================")
    
    foreach ($proc in $htmlProcs) {
        [void]$phase5.AppendLine("EXEC sptblCommonControlType_Signed_Duc '$proc';")
        [void]$phase5.AppendLine("EXEC sp_GenerateHTMLScript '$proc';")
        [void]$phase5.AppendLine("GO")
    }
    
    $main += $phase5.ToString()
}

$fullFile = "x:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526_Full.sql"
[System.IO.File]::WriteAllText($fullFile, $main, [System.Text.Encoding]::UTF8)
Write-Host "Hoàn tất Merge script đầy đủ! Tổng số Procedures đã dump: $($procCodes.Count)"
