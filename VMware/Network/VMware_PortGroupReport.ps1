<#
.SYNOPSIS
VMware PortGroup Report
This script is used to get all distributed port group and VM's connected to each port group
Author: Geoff Phillis
Version: 1.0

.DESCRIPTION
 This script needs to be run on with either VMware PowerCli snappin or module and an
 account that has appropriate rights to connecting using Powercli
 To install PowerCli module run
 Install-Module -Name VMware.PowerCLI
 Install-Module -Name VMware.PowerCLI –Scope CurrentUser

.PARAMETER VCServer
Mandatory Variable for VMware vCenter server.

.PARAMETER Export
Mandatory Variables for Export location.

.EXAMPLE
.\VMware_PortGroupReport.ps1 -VCServer vcenter.domain.local -ConsoleOnly

.EXAMPLE
 .\VMware_PortGroupReport.ps1 -VCServer vcenter.domain.local -ReportExport c:\temp

.NOTES
THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR
RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#>

## script paramter
param(
    [parameter(Mandatory = $false)]
    [switch]$ConsoleOnly,
    [parameter(Mandatory = $true)]
    [String]$VCServer,
    [parameter(Mandatory = $false)]
    [string]$ReportExport
   )

## VCenter Connection
connect-VIServer $VCServer -ErrorAction SilentlyContinue -ErrorVariable ErrorProcess;
if($ErrorProcess){
    Write-Warning "Error connecting to vCenter Server $VCServer error message below"
    Write-Warning $Error[0].Exception.Message
    $Error[0].Exception.Message | Out-File $ReportExport\ConnectionError.txt
exit
    }

else
{

## Create results array
$results = @()

## Get distributed port groups
$portGroups = Get-VDPortgroup

## Loop through each port group
foreach ($port in $portGroups) {

Write-Host "Checking VMs on $($port)" -foreground green

## Get port group view and add addtionaly properties
$networks = Get-View -ViewType Network -Property Name -Filter @{"Name" = $($port.name)}
$networks | ForEach-Object{($_.UpdateViewData("Vm.Name","Vm.Runtime.Host.Name","Vm.Runtime.Host.Parent.Name","vm.Runtime.PowerState"))}

## Loop through each view
foreach ($network in $networks){

## Get VM's
$vms = $network.LinkedView.Vm

## Check if any data in VMS variable
if ($vms){

## Loop through VM's
foreach ($vm in $vms){

## Create hash table for properties
$properties = @{
VMName = $vm.name
PortGroup = $network.Name
Host = $vm.Runtime.LinkedView.Host.Name
Cluster = $vm.Runtime.LinkedView.Host.LinkedView.Parent.Name
PowerStatus = $vm.Runtime.PowerState
}

## Export results
$results += New-Object pscustomobject -Property $properties
    }
}

## for any networks that have no VMs
else {

## Create hash table for properties
$properties = @{
VMName = "No VMs"
PortGroup = $network.Name
Host = "N/A"
Cluster = "N/A"
PowerStatus = "N/A"  
}

## Export results
$results += New-Object pscustomobject -Property $properties
        }
    }
}

## Output to console
if ($ConsoleOnly -and !$ReportExport){
$results | Select-Object VMName, PortGroup, Host, Cluster, PowerStatus
}

## Export resutls 
if ($ReportExport){
$results | Select-Object VMName, PortGroup, Host, Cluster, PowerStatus | 
Export-csv $ReportExport\$VCServer-PortGroupExport.csv -NoTypeInformation
    }
}
