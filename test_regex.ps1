$q = "SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sp_REC_ListViewNew_html')) as Code"
$res = Invoke-Sqlcmd -Query $q -ServerInstance ".\SQLEXPRESS" -Database "Paradise_HPSF" -MaxCharLength 2147483647
Write-Host "Length: " $res.Code.Length

$regexStr = '(?i)["'''']+(sp_REC_[a-zA-Z0-9_]+)["'''']+'
Write-Host "Regex: $regexStr"
$matches = [regex]::Matches($res.Code, $regexStr)
foreach ($m in $matches) {
    Write-Host "Found: " $m.Groups[1].Value
}
