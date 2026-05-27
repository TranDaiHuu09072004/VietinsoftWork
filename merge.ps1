$main = Get-Content "SQL script\migrate_menu_REC_20260526.sql" -Raw -Encoding UTF8
$procs = Get-Content "SQL script\migrate_menu_REC_20260526_Procedures2.sql" -Raw -Encoding UTF8
$regex = "(?s)-- \[PHASE 1\] PROCEDURE DDLS.*?-- ----------------------------------------------------------------------------"
$main = $main -replace $regex, $procs
Set-Content "SQL script\migrate_menu_REC_20260526_Full.sql" -Value $main -Encoding UTF8
