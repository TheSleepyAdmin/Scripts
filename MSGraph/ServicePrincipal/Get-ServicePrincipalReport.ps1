<#
.SYNOPSIS
This script is used to report on Service Principal in Azure using Microsoft Graph PowerShell SDK.
.DESCRIPTION
This script needs to be run on with Microsoft Graph PowerShell SDK intalled, the script will attempt to install the required module

.PARAMETER ConsoleOnly
Non Mandatory Variables to output to PowerShell Console
.PARAMETER ReportExport
Non Mandatory Variables for Export location.
.PARAMETER ServicePrincipals
Mandatory Variables for Display Name of Service Principal to search for

.EXAMPLE
.\Get-ServicePrincipalReport.ps1 -ConsoleOnly -servicePrincipals TheSleepyAdmin_Graph
.EXAMPLE
.\Get-ServicePrincipalReport.ps1 -ConsoleOnly -servicePrincipals TheSleepyAdmin_Graph,SleepyAdmin_vCenter
.EXAMPLE
.\Get-ServicePrincipalReport.ps1 -servicePrincipals TheSleepyAdmin_Graph  -ReportExport C:\temp\Graph\

.NOTES
THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR
RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#>

param(
     [parameter(Mandatory = $false)]
     [switch]$ConsoleOnly,
     [parameter(Mandatory = $false)]
     [string]$ReportExport,
     [parameter(Mandatory = $true)]
     [String[]]$ServicePrincipals
    )

# Install Microsoft Graph PowerShell SDK if not already installed
$GraphSKDCheck = Get-Module -ListAvailable Microsoft.Graph
if ($null -eq $GraphSKDCheck){
try {
    Install-Module -Name Microsoft.Graph 
}
catch {
    Write-Warning "Micorsoft Graph SDK not installed and install failed to run"
}

}

if ($GraphSKDCheck){

# Authenticate to Microsoft Graph
Connect-MgGraph -Scopes "Group.Read.All", "Application.Read.All"

# Create empty array to store results
$results = @()

# Loop through each service principal
foreach ($ServicePrincipal in $ServicePrincipals) {

# Get all service principals
$sp = Get-MgServicePrincipal -Filter "DisplayName eq '$($ServicePrincipal)'"

# Get the groups that the service principal is a member of
$spgroups = Get-MgServicePrincipalTransitiveMemberOf -ServicePrincipalId $sp.Id

# Create variable for service principal groups displaynames 
$spgroupsresults = $spgroups | ForEach-Object {(Get-MgGroup -GroupId $_.Id).DisplayName}

# Add the service principal and its group memberships to the properties hash table
$properties = @{
ServicePrincipalName = $sp.DisplayName
ServicePrincipalType = $sp.ServicePrincipalType
AccountEnabled = $sp.AccountEnabled
AppId = $sp.AppId
Datecreated = $sp.AdditionalProperties.createdDateTime
Groups = $spgroupsresults -join ","

    }

## Add Properties To Results Array
$results += New-Object psobject -Property $properties

}

}

# Output to console
if ($ConsoleOnly -and !$ReportExport){
    $results | Select-Object ServicePrincipalName, ServicePrincipalType, AccountEnabled, AppId, Datecreated, groups
    }
    
# Export results to CSV
if ($ReportExport){
    $results | Select-Object ServicePrincipalName, ServicePrincipalType, AccountEnabled, AppId, Datecreated, groups | 
    Export-Csv $ReportExport\ServicePrincipal_Report.csv -NoTypeInformation
        }
if (!$ConsoleOnly -and !$ReportExport){
    # Output to console if not paramter is set
    $results | Select-Object ServicePrincipalName, ServicePrincipalType, AccountEnabled, AppId, Datecreated, groups
}
