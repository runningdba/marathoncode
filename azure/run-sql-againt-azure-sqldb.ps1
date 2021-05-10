$databaseName = '<db-name>'
$serverName =  '<servername>'
$sqlauthUsername = '<sqladminname>'
$sqlauthPassword = '<pwdsqladmin>'
$subscriptions='<subscname>'

$sql_q1 = "selct * from dba-emp;"

Invoke-SQLCmd -Query $sql_q1 -ServerInstance $serverName -Database $databaseName -Username $sqlauthUsername -Password $sqlauthPassword -OutputSqlErrors $True
