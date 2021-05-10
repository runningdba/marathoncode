$resourceGroupName = '<rg-name>'
$serverName =  ',severname>'
$ovz = Get-AzSqlServer  -ResourceGroupName $resourceGroupName -ServerName $serverName
$ovz.identity
Set-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $serverName -AssignIdentity