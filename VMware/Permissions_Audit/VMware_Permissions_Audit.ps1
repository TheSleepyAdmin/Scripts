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
# VMware Permission Audit Report
# Tested with Powercli 12.0 and above. Requires Powercli install
# on computer running script. 
#  
# ------------------------------------------------------------------------------ 
# Mandatory Variables Vcenter Server and export path
# 
#.EXAMPLE
# .\VMware_Permissions_Audit.ps1 -VCServer vc.domain.local -ReportExport c:\temp
#
# ------------------------------------------------------------------------------

## VMware vCenter and export path paramters
param(
    [parameter(Mandatory)]
    [String]$VCServer,
    [parameter(Mandatory)]
    [string]$ReportExport
    )

## Function to check for export directory and create directory if does not exist.
function CreateDirectory {
    $dlfolder = $ReportExport
    if (!(Test-Path -path $dlfolder)) {
    Write-Host $dlfolder "not found, creating it."
    New-Item $dlfolder -type directory
    }
    }
    CreateDirectory | Out-Null

## Import Vmware Powershell Module
Import-Module -Name VMware.VimAutomation.Core

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
## Create Blank Array
$results = @()

## Get Permissions
$RolesPermissions = Get-VIPermission

foreach ($RolesPermission in $RolesPermissions)
{


Write-Host "checking Permmission $($RolesPermission.Principal)" -ForegroundColor Green

## Get Role
$Role = (Get-VIRole -Name $RolesPermission.Role)

## Set type
if ($RolesPermission.IsGroup -eq "True"){
$Object = "Group"
 }
Else{
$Object = "User"
    }

## Results Hash table
$props = @{
Account = $RolesPermission.Principal
Assigment = $RolesPermission.Entity
Role = $RolesPermission.Role
ObjectType = $Object
Propagate = $RolesPermission.Propagate
AssignedPrivilege = $Role.PrivilegeList -join ","
SystemRole = $Role.IsSystem
}

## Add Properties To Results Array
$results += New-Object psobject -Property $props
}

## Export Results To CSV file
$results | Select-Object Account,Assigment,Role,ObjectType,Propagate,SystemRole,AssignedPrivilege | 
Export-Csv $ReportExport\$VCServer-PermissionsExport.csv -NoTypeInformation
}
Disconnect-VIServer -Confirm:$false
