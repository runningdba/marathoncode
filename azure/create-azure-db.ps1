##############create script

# The SubscriptionId in which to create these objects Mandatory
$SubscriptionName = '<subname>'
#Set the resource group name and location for your server Mandatory
$resourceGroupName = "<rgname>"

#rest of Vars will be created if they don't exist
# Set server name - the logical server name has to be unique in the system
$serverName = "<server-name>"
# Set an admin login  for your server
$adminSqlLogin = "<sqladminloginname>"

# The database name
$databaseName = "<dbname>"
# vesion
$edition = 'Standard'
# The firewallruleName
$FirewallRuleName = ''


$aaduser = "<aadgroup/user>"
$location = "westeurope"
$rand = random(99)

# If SQlservername exists we will convert the name to lowercase else we create a 'unique' name
if ($serverName)
{
    $serverName = $serverName.ToLower()
}
else
{
    $serverName = $resourceGroupName.replace("-rg", "sql") + $rand                    
}
# If databaseName exists we will convert the name to lowercase else we create a 'unique' name
if ($databaseName)
{
    $databaseName = $databaseName.ToLower()
}
else
{
    $databaseName = $resourceGroupName.replace("-rg", "sqldb")
}
# If no FirewallRuleName exists we will create one
if (!$FirewallRuleName)
{
    $FirewallRuleName = $resourceGroupName.replace("-rg", "fwr")
}

# If no sqlLoginName exists exists we will create one and remove the hyphens
if (!$adminSqlLogin)
{
    $adminSqlLogin = $resourceGroupName.replace("-rg", "dba")
    $adminSqlLogin = $adminSqlLogin.replace("-", "")                                          
}
else
{
    $adminSqlLogin = $adminSqlLogin.replace("-", "")                                          
}

# Create keyVaultName 
$keyVaultName = $resourceGroupName.replace("-rg", "") + "kv" + $rand                    
$keyVaultName = $keyVaultName.replace("-", "")                                          

# get-ipaddress for firewall rules
$localIp = Invoke-RestMethod -Uri ifconfig.me/ip
$startIp = $localIp
$endIp = $localIp

# Create a random password
$password = ((([char[]]([char]33..[char]95) + ([char[]]([char]97..[char]126)) + 0..9 | sort { Get-Random })[0..16] -join '') -replace "'". "-") -replace '"'. '-'
[securestring]$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

#login and set context to subscription
#login-azaccount
$context = set-azcontext -Subscription $subscriptionName

# Create resourceGroup if it does not yet exist
$resourceGroup = get-AzResourceGroup -Name $resourceGroupName -Location $location
if (!$resourceGroup)  
{
    $resourceGroup = New-AzResourceGroup -Name $resourceGroupName -Location $location
}

# Create keyVault if it does not yet exist
$keyvault = Get-AzKeyvault -ResourceGroupName $resourceGroupName
if (!$keyvault)
{
    write-output "Creating Keyvault $keyVaultName"
    $keyvault = New-AzKeyvault -name $keyVaultName -ResourceGroupName $resourceGroupName -Location $location -EnabledForDiskEncryption
}
# Set accesspolicy and add secret to keyVault
Set-AzKeyVaultAccessPolicy -VaultName $keyvault.VaultName -UserPrincipalName $azcontext.Account.Id `
    -PermissionsToSecrets get, list, set, delete, purge, backup
$secret = Set-AzKeyVaultSecret -VaultName $keyvault.VaultName -Name $adminSqlLogin -SecretValue $SecurePassword
# Set keyvault firewall
Add-AzKeyVaultNetworkRule -VaultName $keyvault.VaultName -IpAddressRange $localIp 
Update-AzKeyVaultNetworkRuleSet -VaultName $keyvault.VaultName -DefaultAction Deny

# Create a server with a system wide unique server name
$server = New-AzSqlServer -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $securePassword)

# Create a server firewall rule that allows access from the specified IP range
$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -FirewallRuleName $FirewallRuleName -StartIpAddress $startIp -EndIpAddress $endIp

# Create a blank database with an S0 performance level
$database = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName `
    -ServerName $serverName `
    -DatabaseName $databaseName `
    -RequestedServiceObjectiveName "S0" `
    -edition $edition  

# show sqlsever config
$SqlConfig = Get-AzSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $serverName
# show connect string
#az sql db show-connection-string -s $serverName -n $databaseName -c ado.net

# set admin
Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $resourceGroupName -ServerName $serverName -DisplayName $aaduser


# set audit aan
Set-AzSqlServerAudit -ResourceGroupName $resourceGroupName -ServerName $serverName -LogAnalyticsTargetState Enabled -WorkspaceResourceId `
    "/subscriptions/<sub-id>"