[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.Sdk.Sfc") | Out-Null

$serverName = "192.168.11.51,2222"
$databaseName = "Paradise_DEV"
$user = "vts"
$password = "LuaThieng1@3@2020"

$conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection
$conn.ServerInstance = $serverName
$conn.LoginSecure = $false
$conn.Login = $user
$conn.Password = $password

$server = New-Object Microsoft.SqlServer.Management.Smo.Server($conn)
$db = $server.Databases[$databaseName]

if ($null -eq $db) {
    Write-Host "Database not found."
    exit
}

$options = New-Object Microsoft.SqlServer.Management.Smo.ScriptingOptions
$options.ScriptSchema = $true
$options.ScriptData = $false
$options.IncludeIfNotExists = $true
$options.Indexes = $true
$options.DriAll = $true
$options.Triggers = $false

$output = New-Object System.Text.StringBuilder
[void]$output.AppendLine("-- =======================================================")
[void]$output.AppendLine("-- [PHASE 0] DDL CÁC BẢNG (TABLES)")
[void]$output.AppendLine("-- Quét các bảng dạng tblREC%")
[void]$output.AppendLine("-- =======================================================")
[void]$output.AppendLine("SET NOCOUNT ON; SET XACT_ABORT ON;")
[void]$output.AppendLine("GO")

$count = 0
foreach ($table in $db.Tables) {
    if ($table.Name -like "tblREC*" -and $table.IsSystemObject -eq $false) {
        $count++
        $scripts = $table.Script($options)
        foreach ($line in $scripts) {
            [void]$output.AppendLine($line)
            [void]$output.AppendLine("GO")
        }
    }
}

if ($count -gt 0) {
    $outFile = "x:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526_Tables.sql"
    [System.IO.File]::WriteAllText($outFile, $output.ToString(), [System.Text.Encoding]::UTF8)
    
    # Merge into Full
    $fullFile = "x:\VietinsoftWork-main\SQL script\migrate_menu_REC_20260526_Full.sql"
    $main = [System.IO.File]::ReadAllText($fullFile, [System.Text.Encoding]::UTF8)
    $tablesCode = [System.IO.File]::ReadAllText($outFile, [System.Text.Encoding]::UTF8)
    
    $main = $tablesCode + "`n`n" + $main
    [System.IO.File]::WriteAllText($fullFile, $main, [System.Text.Encoding]::UTF8)

    Write-Host "Table scripts saved and prepended to Full script. Count: $count"
} else {
    Write-Host "No tables found matching criteria."
}

$conn.Disconnect()
