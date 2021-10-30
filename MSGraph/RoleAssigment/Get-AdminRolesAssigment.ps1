<#
.SYNOPSIS
This script is used to report on admin role assigment in Azure using Microsoft Graph PowerShell SDK.

.DESCRIPTION
This script needs to be run on with Microsoft Graph PowerShell SDK intalled and certficate based authnetication. 

To install PowerShell SDK
Install-Module Microsoft.Graph -Scope CurrentUser 
or for all users
Install-Module Microsoft.Graph -Scope AllUsers

There are 3 required values to conect using the script. 
TennantId (AzureAD) 
ClientID (from the Enterprise app)
ClientCert (Thumprint of the certficate that was uploaded to the Azure Enterprise app)

.PARAMETER ReportExport
Mandatory Variables for Export location.

.PARAMETER CertificateThumbprint
Mandatory Variables for certificate thumbrpint

.PARAMETER AppID
Mandatory Variables for AppID 

.PARAMETER TenantID
Mandatory Variables for TenantId 

.EXAMPLE
.\Get-AdminRolesAssigment.ps1 -CertificateThumbprint "Cert_Thumbprint" -ClientId "AppID" -TenantId "TenantID" -ReportExport C:\temp\Graph

.NOTES
THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR
RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#>

param(
    [parameter(Mandatory)]
    [string]$CertificateThumbprint,
    [parameter(Mandatory)]
    [string]$ClientId,
    [parameter(Mandatory)]
    [string]$TenantId,
    [parameter(Mandatory)]
    [string]$ReportExport
    )

## Connect MGGraph Splat
$GraphDetails = @{
CertificateThumbprint = "$CertificateThumbprint"
ClientId = "$ClientId"
TenantId = "$TenantId"
}

## Result Array
$results = @()

## Connect to Graph
Connect-MgGraph @GraphDetails

## Set Graph Profile
Select-MgProfile -Name beta

## Get all Directory Roles
$roles = Get-MgDirectoryRole

## Loop through all users
foreach ($role in $roles){

## Get Directory Role Members
$members = Get-MgDirectoryRoleMember -DirectoryRoleId $($role.Id)

foreach ($member in $members){

## Create properties hash table
$properties = @{
Role_Name = $role.DisplayName
Role_Description = $role.Description
DisplayName = $member.AdditionalProperties.displayName
Objecttype = $member.AdditionalProperties."@odata.type" -replace "#microsoft.graph."
UserPrincipalName = if ($member.AdditionalProperties.userPrincipalName){$member.AdditionalProperties.userPrincipalName} else{"N/A"}
}

## Add Properties To Results Array
$results += New-Object psobject -Property $properties
    }
}

## Return results
$results | Select-Object Role_Name, Role_Description, DisplayName, Objecttype, UserPrincipalName |
Export-Csv $ReportExport\AdminRole_Export.csv -NoTypeInformation
