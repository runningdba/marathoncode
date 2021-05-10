--create docker container met mssql on ubuntu in azure 
$dockername ='<dock-name>'
$resourceGroupName = '<rg-name>'
$sqladminpwd ='<password>'
$dnslab = '<dns label name>'
az container create --image mcr.microsoft.com/mssql/server:2019-latest  --name $dockername --resource-group $resourceGroupName --cpu 1 --memory 3.5 --port 1433 --ip-address public -e ACCEPT_EULA=Y MSSQL_SA_PASSWORD=$sqladminpwd MSSQL_PID=Developer MSSQL_COLLATION=Latin1_General_CI_AS MSSQL_ENABLE_HADR=N --location westeurope  --dns-name-label $dnslab

--view log 

az container logs --resource-group $resourceGroupName --name $dockername

--create db

sqlcmd -S fill-ip-adress -U SA -P $sqladminpwd -Q "create database ditocontainer"

-test connection

sqlcmd -S fill-ip-adress -U SA -P $sqladminpwd -Q "select * from sysdatabases"   

--delete container 

az container delete --resource-group $resourceGroupName --name $dockername
