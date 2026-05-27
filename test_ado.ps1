$connString = "Server=.\SQLEXPRESS;Database=Paradise_HPSF;Integrated Security=True;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connString)
$conn.Open()
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT OBJECT_DEFINITION(OBJECT_ID('sp_REC_ListViewNew'))"
$code = $cmd.ExecuteScalar()
Write-Host "Type: $($code.GetType().Name)"
if ($code -is [string]) {
    Write-Host "Length: $($code.Length)"
} else {
    Write-Host "Value: $code"
}
$conn.Close()
