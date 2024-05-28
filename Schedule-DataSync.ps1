workflow Schedule-DataSync
{
    Param(
        [Parameter(Mandatory = $true)]
        [string] $ResourceGroup,
        [Parameter(Mandatory = $true)]
        [string] $ServerName,
        [Parameter(Mandatory = $true)]
        [string] $DatabaseName,
        [Parameter(Mandatory = $true)]
        [string] $SyncGroupName,
        [Parameter(Mandatory = $false)]
        [int] $Maxtime = 3600
    )

    inlineScript
    {
        # # $connectionName = "AzureRunAsConnection"
        # # try {
        # #     # Get the connection "AzureRunAsConnection "
        # #     $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

        # #     Write-Output "Login to Azure"

        # #     Add-AzureRmAccount `
        # #     -ServicePrincipal `
        # #     -TenantId $servicePrincipalConnection.TenantId `
        # #     -ApplicationId $servicePrincipalConnection.ApplicationId `
        # #     -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
        # # }
        # # catch {
        # #     if (!$servicePrincipalConnection) {
        # #         $ErrorMessage = "Connection $connectionName not found."
        # #         throw $ErrorMessage
        # #     }
        # #     else {
        # #         Write-Error -Message $_.Exception
        # #         throw $_.Exception
        # #     }
        # # }

        try
        {
            "Logging in to Azure..."
            Connect-AzAccount -Identity
        }
        catch {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }

        # #Get all Resource Manager resources from all resource groups
        # $ResourceGroups = Get-AzResourceGroup

        # foreach ($ResourceGroup in $ResourceGroups)
        # {    
        #     Write-Output ("Showing resources in resource group " + $ResourceGroup.ResourceGroupName)
        #     $Resources = Get-AzResource -ResourceGroupName $ResourceGroup.ResourceGroupName
        #     foreach ($Resource in $Resources)
        #     {
        #         Write-Output ($Resource.Name + " of type " +  $Resource.ResourceType)
        #     }
        #     Write-Output ("")
        # }

        ######

        # Sync Group to start
        $ResourceGroupName = $using:ResourceGroup
        $ServerName = $using:ServerName
        $DatabaseName = $using:DatabaseName
        $SyncGroupName = $using:SyncGroupName
        $Maxtime = $using:Maxtime

        # Trigger sync manually
        Write-Output "Trigger sync manually"
        $SyncLogStartTime = Get-Date
        #Start-AzureRmSqlSyncGroupSync -ResourceGroupName $ResourceGroupName `
        Start-AzSqlSyncGroupSync -ResourceGroupName $ResourceGroupName `
        -ServerName $ServerName `
        -DatabaseName $DatabaseName `
        -SyncGroupName $SyncGroupName

        # Check the sync log and wait until the first sync succeeded
        Write-Output "Check the sync log"
        $IsSucceeded = $false

        For ($i = 0; ($i -lt $Maxtime) -and (-not $IsSucceeded); $i = $i + 10)
        {
            Start-Sleep -s 10
            $SyncLogEndTime = Get-Date
            #$SyncLogList = Get-AzureRmSqlSyncGroupLog -ResourceGroupName $ResourceGroupName `
            $SyncLogList = Get-AzSqlSyncGroupLog -ResourceGroupName $ResourceGroupName `
            -ServerName $ServerName `
            -DatabaseName $DatabaseName `
            -SyncGroupName $SyncGroupName `
            -StartTime $SyncLogStartTime.ToUniversalTime() `
            -EndTime $SyncLogEndTime.ToUniversalTime()
            if ($SyncLogList.Length -gt 0)
            {
                foreach ($SyncLog in $SyncLogList)
                {
                    if ($SyncLog.Details.Contains("Sync completed successfully"))
                    {
                        Write-Host $SyncLog.TimeStamp : $SyncLog.Details
						Write-Output $SyncLog.TimeStamp : $SyncLog.Details
                        $IsSucceeded = $true
                    }
                }
            }
        }

        if ($IsSucceeded)
        {
            # Enable scheduled sync
            Write-Output "Sync succeed!"
        }
        else
        {
            # Output all log if sync doesn't succeed in 300 seconds
            $SyncLogEndTime = Get-Date
            #$SyncLogList = Get-AzureRmSqlSyncGroupLog -ResourceGroupName $ResourceGroupName `
            $SyncLogList = Get-AzSqlSyncGroupLog -ResourceGroupName $ResourceGroupName `
            -ServerName $ServerName `
            -DatabaseName $DatabaseName `
            -SyncGroupName $SyncGroupName `
            -StartTime $SyncLogStartTime.ToUniversalTime() `
            -EndTime $SyncLogEndTime.ToUniversalTime()
            if ($SyncLogList.Length -gt 0)
            {
                foreach ($SyncLog in $SyncLogList)
                {
                    Write-Host $SyncLog.TimeStamp : $SyncLog.Details
					Write-Output $SyncLog.TimeStamp : $SyncLog.Details
                }
            }
        }
        # Stop sync manually
        Write-Output "Set automatic sync OFF"
        #Update-AzureRmSqlSyncGroup -ResourceGroupName $ResourceGroupName `
        Update-AzSqlSyncGroup -ResourceGroupName $ResourceGroupName `
        -ServerName $ServerName `
        -DatabaseName $DatabaseName `
        -Name $SyncGroupName `
        -IntervalInSeconds "-1"

        # Stop sync
        Write-Output "Stop sync"
        #Stop-AzureRmSqlSyncGroupSync -ResourceGroupName $ResourceGroupName `
        Stop-AzSqlSyncGroupSync -ResourceGroupName $ResourceGroupName `
        -ServerName $ServerName `
        -DatabaseName $DatabaseName `
        -SyncGroupName $SyncGroupName
    }
}