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
# .\Get-NetworkAdapterDetails -ReportExport c:\temp
#
# ------------------------------------------------------------------------------

param(
    [parameter(Mandatory = $false)]
    [string]$ReportExport
    )

## Create results array
$results = @()

## Get ESXi Hosts
$vmhosts = Get-VMHost

foreach ($vmhost in $vmhosts){

## Retrieve EsxCli information
$vmhostesxcli = Get-EsxCli -VMHost $vmhost -V2

## Retrieve Nic list 
$nics = $vmhostesxcli.network.nic.list.Invoke()

foreach ($nic in $nics){

## Get Nic information
$nicinfo = $vmhostesxcli.network.nic.get.invoke(@{nicname=$($nic.Name)})

## Create Hashtable for formating results. 
$props = @{
VMHost = $vmhost.Name
NetworkAdapter = $nic.Name
Driver = $nicinfo.DriverInfo.Driver
Version = $nicinfo.DriverInfo.Version
FirmwareVersion = $nicinfo.DriverInfo.FirmwareVersion

}

## Write results to Array
$results += New-Object pscustomobject -Property $props

}
}

if ($ReportExport){

## Export report
$results | Select-Object VMHost,NetworkAdapter,Driver,Version,FirmwareVersion | 
Export-Csv $ReportExport\VMwareHostNetworkAdapterDetails.csv -NoTypeInformation
}

else{

## Out put results to console
$results | Select-Object VMHost,NetworkAdapter,Driver,Version,FirmwareVersion
}
