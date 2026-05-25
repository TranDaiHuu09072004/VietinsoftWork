$connectionString = "Server=192.168.11.51,2222;Database=Paradise_Dev;User Id=vts.sa;Password=LuaThieng1@3@2020;Encrypt=false;"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
try {
    $connection.Open()
    Write-Host "Connected successfully to Paradise_Dev database."
    $sqlFile = "d:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\modernize_MnuHRS501_EmployeeList2_20260524.sql"
    $query = Get-Content -Raw -Path $sqlFile -Encoding UTF8
    
    # Split query by GO on separate lines
    $batches = [System.Text.RegularExpressions.Regex]::Split($query, "(?i)^\s*GO\s*$", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    
    $index = 1
    foreach ($batch in $batches) {
        $cleanBatch = $batch.Trim()
        if ($cleanBatch -ne "") {
            Write-Host "Executing batch $index..."
            $command = New-Object System.Data.SqlClient.SqlCommand($cleanBatch, $connection)
            $command.ExecuteNonQuery() | Out-Null
            $index++
        }
    }
    Write-Host "MnuHRS501 Modernization SQL Script executed successfully on Paradise_Dev."
} catch {
    Write-Error $_.Exception.Message
    exit 1
} finally {
    if ($connection.State -eq [System.Data.ConnectionState]::Open) {
        $connection.Close()
    }
}
