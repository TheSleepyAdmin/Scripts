#------------------------------------------------------------------------------ 
# THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED "AS IS� WITHOUT 
# WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT 
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS 
# FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR  
# RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER. 
# 
#------------------------------------------------------------------------------ 
# Author: Geoff Phillis 
# Version: 1.0
#------------------------------------------------------------------------------ 
# VMware NetworkAdapter Details
# Tested with Powercli 12.0 and above. Requires Powercli install
# on computer running script. 
#  
# ------------------------------------------------------------------------------ 
# Mandatory Variables Vcenter Server and export path
# 
#.EXAMPLE
# .\Get-ESXiPowerPlan -ReportOnly
#
#.EXAMPLE
#.\Get-ESXiPowerPlan -ReportOnly -ReportExport c:\temp
#
#.EXAMPLE
#.\Get-ESXiPowerPlan -Setplan 
# ------------------------------------------------------------------------------

param(
    [parameter(Mandatory = $false)]
    [switch]$ReportOnly,
    [parameter(Mandatory = $false)]
    [string]$ReportExport,
    [parameter(Mandatory = $false)]
    [string]$Setplan
    )

## Get date to add to report export
$date = get-date -Format dd_mm_yyyy

## Get list of VMhost
$vmhosts = Get-VMHost

foreach ($vmhost in $vmhosts){

## Retrieve EsxCli information
$vmhostesxcli = Get-EsxCli -VMHost $vmhost -V2

## Retrieve PowerPlan settings
$PowerPlan = $vmhostesxcli.hardware.Power.policy.get.invoke()

## checks if the set ReportOnly paramter is set and ReportExport is not set
if ($ReportOnly -and !$ReportExport){

## Get PowerPlan details and exports to the PowerShell console
$PowerPlan | Select-Object @{N="VMHost";E={$($vmhost)}},@{N="Name";E={$PowerPlan.Name}},
@{N="Id";E={$PowerPlan.Id}},@{N="ShortName";E={$PowerPlan.ShortName}}
    
}

## checks if the set ReportExport paramter is set
if ($ReportExport){

## Get PowerPlan details and exports to a csv
$PowerPlan | Select-Object @{N="VMHost";E={$($vmhost)}},@{N="Name";E={$PowerPlan.Name}},
@{N="Id";E={$PowerPlan.Id}},@{N="ShortName";E={$PowerPlan.ShortName}} | 
Export-Csv $ReportExport\PowerPlanReport_$date.csv -Append -NoTypeInformation
    
}

## checks if the set powerplan paramter is selected
if ($Setplan){

if ($PowerPlan -ne $Setplan){

## Update PowerPlan to set Id
$vmhostesxcli.hardware.Power.policy.set.Invoke(@{id=$("$Setplan")})

}
else{
Write-Warning "Host PowerPlan is already set"
}

}

}
