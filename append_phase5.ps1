$content = Get-Content "x:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526_Full.sql" -Raw
$regex = [regex] '(?i)CREATE OR ALTER PROCEDURE \[dbo\]\.\[(sp_REC_.*?_html)\]'
$matches = $regex.Matches($content)
$htmlProcs = $matches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

$output = New-Object System.Text.StringBuilder
[void]$output.AppendLine()
[void]$output.AppendLine("-- ============================================================================")
[void]$output.AppendLine("-- [PHASE 5] CẬP NHẬT GIAO DIỆN WEB CHO CÁC RENDERER (_html)")
[void]$output.AppendLine("-- Mục đích: Load control vào layout và cập nhật cache tblHtmlScriptCache")
[void]$output.AppendLine("-- ============================================================================")

foreach ($proc in $htmlProcs) {
    [void]$output.AppendLine("EXEC sptblCommonControlType_Signed_Duc '$proc';")
    [void]$output.AppendLine("EXEC sp_GenerateHTMLScript '$proc';")
    [void]$output.AppendLine("GO")
}

$appendFile = "x:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526_Full.sql"
Add-Content -Path $appendFile -Value $output.ToString()

Write-Host "Appended PHASE 5 for $($htmlProcs.Count) html procedures."
