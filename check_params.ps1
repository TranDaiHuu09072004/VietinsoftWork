$conn = New-Object System.Data.SqlClient.SqlConnection("Server=.;Database=ParadiseHR;Integrated Security=True;");
$conn.Open();
$cmd = $conn.CreateCommand();
$cmd.CommandText = "SELECT PARAMETER_NAME FROM INFORMATION_SCHEMA.PARAMETERS WHERE SPECIFIC_NAME = 'sp_TAD_EmployeeScheduleDetail_AutoSchedule'";
$r = $cmd.ExecuteReader();
while($r.Read()) { Write-Output $r[0] }
$conn.Close();
