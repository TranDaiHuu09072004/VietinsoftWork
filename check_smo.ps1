[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null
if ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.FullName -match "Microsoft.SqlServer.Smo" }) {
    Write-Host "SMO is loaded"
} else {
    Write-Host "SMO is NOT loaded"
}
