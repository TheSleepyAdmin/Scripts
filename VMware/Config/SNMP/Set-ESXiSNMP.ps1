<#
.SYNOPSIS
VMware Set ESXi Host SNMP Config:
Script is used to set ESXi SNMP Configuration

Author: Geoff Phillis
Version: 1.0

.DESCRIPTION
 This script needs to be run on with either VMware PowerCli snappin or module and an
 account that has appropriate rights to connecting using Powercli
 To install PowerCli module run
 Install-Module -Name VMware.PowerCLI
 Install-Module -Name VMware.PowerCLI –Scope CurrentUser

.PARAMETER ESXiHostList
Mandatory Variable for location of csv file with ESXi hosts.

.PARAMETER ESXiUser
Mandatory Variable for ESXi local user. 

.PARAMETER ESXipass
Mandatory Variable for ESXi local user password.

.PARAMETER SNMPString
Mandatory Variable for ESXi SNMP commmunity string.

.PARAMETER SNMPTarget
Mandatory Variables for  setting SNMP target address.

.EXAMPLE
 .\Set-ESXiSNMP.ps1 -ESXiHostList c:\temp\ESXiHosts.csv -ESXiUser root -ESXipass passwrod -SNMPString public -SNMPTarget snmp.domain.local

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
   [String]$ESXiHostList,
   [parameter(Mandatory = $true)]
   [String]$ESXiUser,
   [parameter(Mandatory = $true)]
   [String]$ESXipass,
   [parameter(Mandatory = $true)]
   [String]$SNMPString,
   [parameter(Mandatory = $true)]
   [String]$SNMPTarget
   )

$ESXiHosts = Import-csv -Path $($ESXiHostList)

foreach ($ESXiHost in $ESXiHosts) {

## Connect to ESXi Host
Connect-VIServer $ESXiHost.EsxiHost -user $ESXiUser -password $ESXipass

## Check SNMP settings
Write-Host "Getting SNMP Settings" -ForegroundColor Yellow

## Get Current SNMP Config
$SNmpSettings = Get-VMHostSnmp

if ($SNmpSettings.Enabled  -like 'false'){

Write-Warning "SNMP is not enabled, setting SNMP config"

## Enable SNMP and set snmp config
Get-VMHostSnmp | Set-VMHostSnmp -Enabled:$true -ReadOnlyCommunity $SNMPString -TargetCommunity $SNMPString -TargetHost $SNMPTarget -TargetPort 162 -AddTarget

## Disconnect from ESXi Host
Disconnect-VIServer $ESXiHost.EsxiHost  -Confirm:$false

}

if ($SNmpSettings.Enabled -like 'true'){

Write-Host "Checking existing SNMP configuration" -ForegroundColor Green

if ($SNmpSettings.TrapTargets.HostName -notlike $SNMPTarget){

Write-Host "SNMP configuration does not match, Updatating SNMP configuration"

## Reset SNMP Settings
Get-VMHostSnmp | Set-VMHostSnmp -ReadOnlyCommunity @() | Out-Null

## Set SNMP Config
Get-VMHostSnmp | Set-VMHostSnmp -Enabled:$true -ReadOnlyCommunity $SNMPString -TargetCommunity $SNMPString -TargetHost $SNMPTarget -TargetPort 162 -AddTarget

## Disconnect from ESXi Host
Disconnect-VIServer $ESXiHost.EsxiHost  -Confirm:$false

         }

## Disconnect from ESXi Host
Disconnect-VIServer $ESXiHost.EsxiHost  -Confirm:$false

      }
}
