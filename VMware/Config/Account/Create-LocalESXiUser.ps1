<#
.SYNOPSIS
VMware Set ESXi Host Local Account
Script is used to create and set the a  local ESXi users account

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

.PARAMETER ESXiNewUser
Mandatory Variable for ESXi new user account

.PARAMETER ESXiUserPass
Mandatory Variables for new user account password

.PARAMETER ESXiPermission
Mandatory Variables for permission to be set on the new account

.EXAMPLE
.\Create-LocalESXiUser -ESXiHostList c:\temp\ESXiHosts.csv -ESXiUser root -ESXipass password -ESXiNewUser newuser -ESXiUserPass Pass -ESXiPermission Admin -Description "account decription"

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
   [String]$ESXiNewUser,
   [parameter(Mandatory = $true)]
   [String]$ESXiUserPass,
   [parameter(Mandatory = $true)]
   [String]$ESXiUserdesc,
   [parameter(Mandatory = $true)]
   [String]$ESXiPermission
   )

$ESXiHosts = Import-csv -Path $($ESXiHostList)

foreach ($ESXiHost in $ESXiHosts) {

## Connect to ESXi Host
Connect-VIServer -Server $ESXiHost.EsxiHost -User $ESXiUser -Password $ESXipass

Write-Host "Checking if account exist" -BackgroundColor DarkGray -ForegroundColor Yellow

## Check for existing account
$UserCheck = Get-VMHostAccount -User $ESXiNewUser -ErrorAction SilentlyContinue

if ($null -eq $UserCheck){

Write-Host "Account not found creating new account for $($ESXiNewUser)" -ForegroundColor Green

## Ceate new account
New-VMHostAccount -Id $ESXiNewUser -Password $ESXiUserPass -Description $ESXiUserdesc

## Set Permission for new account
New-VIPermission -Entity (Get-Folder root) -Principal $ESXiNewUser -Role $ESXiPermission

## Disconnect from ESXi Host
Disconnect-VIServer -Server $ESXiHost.EsxiHost -Confirm:$false 

}

if ($UserCheck){

Write-Warning "Account already exist checking correct permission are set"

## Check existing permission
$CheckPermission = Get-VIPermission -Principal $ESXiNewUser

if($CheckPermission.Role -notlike $ESXiPermission){

Write-Host "Incorrect permission set, updating permissions" -BackgroundColor DarkRed -ForegroundColor green

## Update Permission on account
New-VIPermission -Entity (Get-Folder root) -Principal $ESXiNewUser -Role $ESXiPermission

## Disconnect from ESXi Host
Disconnect-VIServer -Server $ESXiHost.EsxiHost -Confirm:$false 
    
}

else {

Write-Host "Permission already set" -BackgroundColor DarkGreen -ForegroundColor Yellow

## Disconnect from ESXi Host
Disconnect-VIServer -Server $ESXiHost.EsxiHost -Confirm:$false 

}

     }

        }
