<#
.SYNOPSIS
This script is used to report on Azure App Registration client secret / certificates in Azure using Microsoft Graph PowerShell SDK.
.DESCRIPTION
This script needs to be run on with Microsoft Graph PowerShell SDK intalled and certficate based authnetication. 
To install PowerShell SDK
Install-Module Microsoft.Graph -Scope CurrentUser 
or for all users
Install-Module Microsoft.Graph -Scope AllUsers

.PARAMETER ReportExport
Parameter for Export location.
.PARAMETER ReportOnly
Parameter to display results to the PowerShell Console
.PARAMETER CertificateThumbprint
Mandatory parameter for certificate thumbrpint
.PARAMETER AppID
Mandatory parameter for AppID 
.PARAMETER TenantID
Mandatory parameter for TenantId 
.PARAMETER ExpiryDate
Mandatory parameter to set date for expiry check
.EXAMPLE
.\Get-AppRegistrationDetails.ps1 -CertificateThumbprint Thumprint -ClientId ClientID -TenantId TenantID -ReportOnly -ExpiryDate 200
.EXAMPLE
.\Get-AppRegistrationDetails.ps1 -CertificateThumbprint thumbprint -ClientId ClientID -TenantId TenantID -ReportExport C:\temp\Graph\ -ExpiryDate 200
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
    [string]$ExpiryDate,
    [string]$ReportExport,
    [switch]$ReportOnly
    )

## Connect MGGraph Splat
$GraphDetails = @{
    CertificateThumbprint = $CertificateThumbprint  
    ClientId = $ClientId
    TenantId = $TenantId
}

## Date Format
$ReportDate = Get-Date -Format dd_MM_yyyy

## Result Array
$results = @()

## Connect to Graph
Connect-MgGraph @GraphDetails

## Set Graph Profile
Select-MgProfile -Name beta

## Results Array
$results = @()

## Get Applications
$apps = Get-MgApplication

foreach ($app in $apps){

## Check application for client secret
if ($null -ne $app.PasswordCredentials){

foreach ($Creds in $app.PasswordCredentials){

## Create hash table for results
    $properties = @{
        ApplicationName = $app.DisplayName
        CreatedDateTime = $app.CreatedDateTime
        SigninType = $app.SignInAudience
        StartDateTime = $Creds.StartDateTime
        EndDateTime = $Creds.EndDateTime
        Expired = if ($Creds.EndDateTime -lt (Get-date)){"Secret has expired"} 
        elseif ($Creds.EndDateTime -lt (Get-date).AddDays($ExpiryDate))
        {"Secret due to expiry in " + ($Creds.EndDateTime - (Get-Date)).Days + " days"}
        else {"Secret is not due to expire in next $ExpiryDate days"}
        AuthType = "Client_Secret"
        }

## Out put results to array
        $results += New-Object psobject -Property $properties

        }
}

## Check application for certificate
if ($null -ne $app.KeyCredentials){

foreach ($cert in $app.KeyCredentials){

## Create hash table for results
    $properties = @{
        ApplicationName = $app.DisplayName
        CreatedDateTime = $app.CreatedDateTime
        SigninType = $app.SignInAudience
        StartDateTime = $cert.StartDateTime
        EndDateTime = $cert.EndDateTime
        Expired = if ($Cert.EndDateTime -lt (Get-date)){"Certificate has expired"} 
        elseif ($cert.EndDateTime -lt (Get-date).AddDays($ExpiryDate))
        {"Certificate due to expiry in " + ($cert.EndDateTime  - (Get-Date)).days + " days"} 
        else {"Certificate is not due to expire in next $ExpiryDate days"}
        AuthType = "Certificate"
        }

## Out put results to array
        $results += New-Object psobject -Property $properties

            }
        }
}

if ($ReportOnly){
$results | Select-Object ApplicationName, CreatedDateTime, SigninType, StartDateTime, EndDateTime, AuthType, Expired
}

if ($ReportExport){
    $results | Select-Object ApplicationName, CreatedDateTime, SigninType, StartDateTime, EndDateTime, AuthType, Expired | 
    Export-Csv $ReportExport\AzureAppRegistration_$ReportDate.csv -Append -NoTypeInformation
}
