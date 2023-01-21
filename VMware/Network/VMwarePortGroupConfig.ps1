<#
.SYNOPSIS
VMware Distributed Port Groups Report:
Script is used to report on configuration of VMware Distributed Port Groups 

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
 .\VMwarePortGroupConfig.ps1 -VCServer VcenterServer

 .EXAMPLE
 .\VMwarePortGroupConfig.ps1 -VCServer VcenterServer -ReportExport c:\temp

.NOTES
THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR
RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#>

## Script Paramaters
param(
   [parameter(Mandatory = $true)]
   [String]$VCServer,
   [parameter(Mandatory = $false)]
   [string]$ReportExport
   )

# Create results array
$results = @()

# Date variable
$date = Get-Date -Format dd_MM_yyyy

# Connect to vCenter Server
Connect-VIServer $VCServer

# Get all distributed switches
$vds = Get-VDSwitch

# Loop through each distributed switch
foreach ($vs in $vds) {

# Get all port groups on the distributed switch
$pgs = Get-VDPortgroup -VDSwitch $vs

# Loop through each port group
foreach ($pg in $pgs) {

# Get Port group details
$PortGDetails = Get-VDPortgroup -Name $pg

# Get teaming policy
$PortGDetailsTeaming = $PortGDetails | Get-VDUplinkTeamingPolicy

# Get security Policy
$PortGDetailsSecurity = $PortGDetails  | Get-VDSecurityPolicy

# Create hash table for configuration details
$properties = @{

  PortGroupName = $PortGDetails.Name
  VLAN = $PortGDetails.VlanConfiguration
  PortBinding = $PortGDetails.PortBinding
  Num_Ports = $PortGDetails.NumPorts
  VDSwitch = $PortGDetails.VDSwitch
  Load_Balancing = $PortGDetailsTeaming.LoadBalancingPolicy
  Failover_Detection = $PortGDetailsTeaming.FailoverDetectionPolicy
  NotifySwitches = $PortGDetailsTeaming.NotifySwitches
  EnableFailback = $PortGDetailsTeaming.EnableFailback
  ActiveUplinkPort = $PortGDetailsTeaming.ActiveUplinkPort -join ","
  StandbyUplinkPort = $PortGDetailsTeaming.StandbyUplinkPort -join ","
  AllowPromiscuous = $PortGDetailsSecurity.AllowPromiscuous
  MacChanges = $PortGDetailsSecurity.MacChanges
  ForgedTransmits = $PortGDetailsSecurity.ForgedTransmits
  NetFlow = $PortGDetails.ExtensionData.Config.DefaultPortConfig.IpFixEnabled.Value


}

## Write results to Array
$results += New-Object pscustomobject -Property $properties

  }
}

if ($ReportExport){

  ## Export report
  $results | Select-Object PortGroupName,VLAN,PortBinding,Num_Ports,VDSwitch,Load_Balancing,Failover_Detection,`
  NotifySwitches,EnableFailback,ActiveUplinkPort,StandbyUplinkPort,`
  AllowPromiscuous,MacChanges,ForgedTransmits,NetFlow | 
  Export-Csv $ReportExport\VMwarePortGroup_ConfigExport_$date.csv -NoTypeInformation
  }
  
  else{
  
  ## Out put results to console
  $results | Select-Object PortGroupName,VLAN,PortBinding,Num_Ports,VDSwitch,Load_Balancing,Failover_Detection,`
  NotifySwitches,EnableFailback,ActiveUplinkPort,StandbyUplinkPort,`
  AllowPromiscuous,MacChanges,ForgedTransmits,NetFlow
  }

  Disconnect-VIServer -Confirm:$false
