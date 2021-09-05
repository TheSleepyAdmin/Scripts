<#
.SYNOPSIS
VMware Power Policy Report and configuration update
Author: Geoff Phillis
Version: 1.0

.DESCRIPTION
VMware Power Policy Report and configuration update for ESXi Power policy
Tested with Powercli 12.0 and above. Requires Powercli install
To install PowerCli module run
Install-Module -Name VMware.PowerCLI
Install-Module -Name VMware.PowerCLI –Scope CurrentUser

.PARAMETER ReportOnly
Use -ReportOnly to return the current Power policy to the PowerShell console

.PARAMETER ReportExport
-ReportOnly and -ReportExport to out put the reprot to a csv

.PARAMETER SetPolicy
Use -SetPolicy to update the active power policy setting

.EXAMPLE
.\Get-ESXiPowerPolicy -ReportOnly

.EXAMPLE
.\Get-ESXiPowerPolicy -ReportOnly -ReportExport c:\temp

.EXAMPLE
.\Get-ESXiPowerPolicy -SetPolicy 1

.NOTES
THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR
RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#>

param(
    [parameter(Mandatory = $false)]
    [switch]$ReportOnly,
    [parameter(Mandatory = $false)]
    [string]$ReportExport,
    [parameter(Mandatory = $false)]
    [string]$SetPolicy
    )

## Get date to add to report export
$date = get-date -Format dd_mm_yyyy

## Get list of VMhost
$vmhosts = Get-VMHost

foreach ($vmhost in $vmhosts){

## Retrieve EsxCli information
$vmhostesxcli = Get-EsxCli -VMHost $vmhost -V2

## Retrieve PowerPolicy settings
$PowerPolicy = $vmhostesxcli.hardware.Power.policy.get.invoke()

## checks if the set ReportOnly paramter is set and ReportExport is not set
if ($ReportOnly -and !$ReportExport){

## Get PowerPolicy details and exports to the PowerShell console
$PowerPolicy | Select-Object @{N="VMHost";E={$($vmhost)}},@{N="Name";E={$PowerPolicy.Name}},
@{N="Id";E={$PowerPolicy.Id}},@{N="ShortName";E={$PowerPolicy.ShortName}}
    
}

## checks if the set ReportExport paramter is set
if ($ReportExport){

## Get PowerPolicy details and exports to a csv
$PowerPolicy | Select-Object @{N="VMHost";E={$($vmhost)}},@{N="Name";E={$PowerPolicy.Name}},
@{N="Id";E={$PowerPolicy.Id}},@{N="ShortName";E={$PowerPolicy.ShortName}} | 
Export-Csv $ReportExport\PowerPolicyReport_$date.csv -Append -NoTypeInformation
    
}

## checks if the set powerPolicy paramter is selected
if ($SetPolicy){

## Check if Power Policy is already set to correct Id
if ($PowerPolicy.Id -ne $SetPolicy){

## Update PowerPolicy to set Id
$vmhostesxcli.hardware.Power.policy.set.Invoke(@{id=$("$SetPolicy")})
}
else{
Write-Warning "Host PowerPolicy is already set"
}

}

}
