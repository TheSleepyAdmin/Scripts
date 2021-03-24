<#
.SYNOPSIS
Script to list all share on a remote system and export folder permission

.DESCRIPTION
This Script is used to check for all shares on the specified servers and to export folder permission, the default shares like Admin$ and c$ 
are excluded from this script. 

This script require that WMI and SMB are open and that the account run has the correct permisions. 

.EXAMPLE
.\Get-SharesAndPermissions.ps1 -ExportPath c:\Export -Servers LAB-Host01
.EXAMPLE
.\Get-SharesAndPermissions.ps1 -ExportPath c:\Export -Servers LAB-Host01,LAB-ConfigMgr
#>

## Setting script parameters
param(
[parameter(Mandatory = $true)]
[String]$ExportPath,
[parameter(Mandatory = $true)]
[String[]]$Servers
)

## Results variable
$results = @()

## Lopping through specified servers
Foreach ($Server in $Servers){

Write-Host "Checking $($server)" -ForegroundColor Green

## query WMI for shares
$Shares = Get-WmiObject -ComputerName $Server -Class win32_share -Filter "Description != 'Remote Admin' and Description != 'Default share' and Description != 'Remote IPC' and Description != 'Printer Drivers'" | Select-Object Name -ExpandProperty Name

## Lopping through Shares
foreach ($share in $Shares) {

## Creating folderpath variable
$FolderPath =  "\\$Server\$share"

Write-Warning "Checking permissions $($FolderPath)"

## Get Root Folder Permissions
$Folders = @(Get-Item -Path $FolderPath | Select-Object Name,FullName,LastWriteTime,Length)

## Get Folders
$error.clear()
$Folders += Get-ChildItem -Path $FolderPath -Directory |  Select-Object Name,FullName,LastWriteTime,Length -ErrorAction SilentlyContinue
foreach ($err in $Error) {
$err.Exception.Message | Out-File $ExportPath\AccessDenied.txt -Append
}

## Loop through folders
foreach ($Folder in $Folders){

## Get access control list
$Acls = Get-Acl -Path $Folder.FullName -ErrorAction SilentlyContinue

## Loop through ACL
foreach ($Acl in $Acls.Access) {

if ($Acl.IdentityReference -notlike "BUILTIN\Administrators" -and $Acl.IdentityReference -notlike "CREATOR OWNER" -and
$Acl.IdentityReference -notlike "NT AUTHORITY\SYSTEM" -and $Acl.FileSystemRights -notlike "-*" -and  $Acl.FileSystemRights -notlike "268435456"`
-and $Acl.IdentityReference -notlike "S-1-*"){

## format properties for result hash table
$properties = @{
FolderName = $Folder.Name
FolderPath = $Folder.FullName
IdentityReference = $Acl.IdentityReference.ToString()
Permissions = $Acl.FileSystemRights
AccessControlType = $Acl.AccessControlType.ToString()
IsInherited = $Acl.IsInherited
}
$results += New-Object psobject -Property $properties
                    }
                }

            }
        }
    }
## Export results
$results | Select-Object FolderName,FolderPath,IdentityReference,Permissions,AccessControlType,IsInherited | 
Export-Csv -Path $ExportPath\Share_PermissionExport.csv -NoTypeInformation
