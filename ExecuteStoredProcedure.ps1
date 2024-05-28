<#
.SYNOPSIS
    Executes a stored procedure on a specified database

.DESCRIPTION
    This runbook allows you to execute a stored procedure on a defined database.

.PARAMETER SqlServer
    Name of the SQL Server.

.PARAMETER Database
    Name of the database.

.PARAMETER Credentials
    Name of the stored credentials.

.PARAMETER StoredProcedure
    Name of the stored procedure to execute.

.PARAMETER Parameters
    List of parameters to pass to the procedure. Eg. 'param1', 'param2'.

.NOTES
    Author: Andreas Holmberg
    Last Update: Jan 2020  
#>

param(
[parameter(Mandatory=$true)]
[string] $SqlServer,    

[parameter(Mandatory=$true)]
[string] $Database,

[parameter(Mandatory=$true)]
[string] $Credentials,

[parameter(Mandatory=$true)]
[string] $StoredProcedure,

[parameter(Mandatory=$false)]
[string] $Parameters
)

$AzureSQLServerName = $SqlServer + ".database.windows.net" 
$Cred = Get-AutomationPSCredential -Name $Credentials 
$SQLOutput = $(Invoke-Sqlcmd -ServerInstance $AzureSQLServerName -Username $Cred.UserName -Password $Cred.GetNetworkCredential().Password -Database $Database -Query "exec $StoredProcedure $Parameters" -QueryTimeout 65535 -ConnectionTimeout 60 -Verbose) 4>&1 

Write-Output $SQLOutput