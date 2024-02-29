<#
.SYNOPSIS
This Script is to check scheduled task that use the specified run as account or accounts on a list of devices specifed in a txt file.
.DESCRIPTION
This Script is to check scheduled task that use the specified run as account or accountson a list of devices specifed in a txt file.
To search for these scheduled task the script will call schtask.exe. 
.EXAMPLE
.\Check_RunAsAccount.ps1 -CompList D:\Scripts\Task_Scheduler\Complist.txt -RunAsAccount test1 -ExportLocation D:\Scripts\Task_Scheduler\
.EXAMPLE
.\Check_RunAsAccount.ps1 -CompList D:\Scripts\Task_Scheduler\Complist.txt -RunAsAccount test1,test2 -ExportLocation D:\Scripts\Task_Scheduler\
#>


function Get-ScheduledTaskUsers
{
    ## Set script parameter
    param(
        [parameter(Mandatory = $true)]
        [String]$CompList,
        [parameter(Mandatory = $false)]
        [String[]]$RunAsAccount,
        [parameter(Mandatory = $true)]
        [String]$ExportLocation,
        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential
    )

    ## Get list of device to check
    $comps = Get-Content $CompList

    ## Loop through each device
    foreach ($comp in $comps)
    {
        Write-Host "Testing connection to $($comp)" -ForegroundColor DarkGreen
        $TC = Test-Connection $comp -Count 1 -ErrorAction SilentlyContinue

        if ($TC)
        {
            Write-Host "Checking $($comp)" -ForegroundColor Green

            ## Check scheduled task for specified run as account
            if ($null -ne $RunAsAccount)
            {
                $schtask = Invoke-Command -Credential $Credential -ComputerName $comp -ArgumentList $RunAsAccount -ScriptBlock {
                    schtasks.exe /query /V /FO CSV | ConvertFrom-Csv | Select-Object HostName, TaskName, Status, "Next Run Time", "Run As User" |
                    Where-Object { $_."Run As User" -contains $RunAsAccount } }
            }
            else
            {
                $schtask = Invoke-Command -Credential $Credential -ComputerName $comp -ArgumentList $RunAsAccount -ScriptBlock {
                    schtasks.exe /query /V /FO CSV | ConvertFrom-Csv | Select-Object HostName, TaskName, Status, "Next Run Time", "Run As User" }
            }
            if ($schtask)
            {

                ## Export results
                Write-Host "Task found exporting to results to $($ExportLocation)"
                $schtask | Export-csv "$ExportLocation\ScheduledTaskExport.csv" -NoTypeInformation -Append
            }
            else
            {
                Write-Host "No task found with run as account"
            }

        }
        else
        {
            Write-Host "$($comp) not responding Exporting failures to log file located in $($ExportLocation)" -ForegroundColor Yellow
            $comp | Out-File "$ExportLocation\FailureReport.log" -NoTypeInformation -Append
        }
    }
}
