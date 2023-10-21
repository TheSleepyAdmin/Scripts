<#
.SYNOPSIS
This script is used to report on Azure App Registration client secret / certificates in Azure using 
Microsoft Graph PowerShell SDK and export the report as a hmt file.
.DESCRIPTION
This script needs to be run on with Microsoft Graph PowerShell SDK intalled and certficate based authnetication. 
To install PowerShell SDK
Install-Module Microsoft.Graph -Scope CurrentUser 
or for all users
Install-Module Microsoft.Graph -Scope AllUsers

.PARAMETER ReportExport
Parameter for Export location.
.PARAMETER CertificateThumbprint
Mandatory parameter for certificate thumbrpint
.PARAMETER AppID
Mandatory parameter for AppID 
.PARAMETER TenantID
Mandatory parameter for TenantId 
.PARAMETER ExpiryDate
Mandatory parameter to set date for expiry check
.EXAMPLE
.\Get-AppRegistrationdetailsHTMLv2.ps1 -CertificateThumbprint thumbprint -ClientId ClientID -TenantId TenantID -ReportExport C:\temp\Graph\ -ExpiryDate 180
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
    [string]$ExpiryRange,
    [parameter(Mandatory)]
    [string]$ReportExport
    )

## Connect MGGraph Splat
$GraphDetails = @{
    CertificateThumbprint = $CertificateThumbprint  
    ClientId = $ClientId
    TenantId = $TenantId
}

#HTML Formating 
$header = @"
<style>
body {background-color: #778899;font-family: Arial; font-size: 14pt;}
h2 {color: 	#353839; font-family: "Arial Black"}

TH{border-style: solid;border-color: Black;background-color:#4d5d53;}
TD{background-color:#bfc1c2}

table {
    border-collapse: collapse;width: 100%;
}

table, th, td, tr{
    border: 4px solid black;height: 25px;text-align: Center;font-weight: bold; color:#080808
}

.Expired {
    color: #ff0000;
}

.DuetoExpire {
    color: #ff8c00;

}

.Valid {
    color: #008000;
}

</style>
"@

## Result Array
$results = @()

## Connect to Graph
Connect-MgGraph @GraphDetails | Out-Null

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
        elseif ($Creds.EndDateTime -lt (Get-date).AddDays($ExpiryRange)){"Secret due to expire"}
        else {"Secret is not due to expire within date range"}
        DaysToExpire = if ($Creds.EndDateTime -lt (Get-date)){"N/A"} 
        elseif ($Creds.EndDateTime -lt (Get-date).AddDays($ExpiryRange)){($Creds.EndDateTime - (Get-Date)).Days}
        else {"N/A"}
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
        elseif ($cert.EndDateTime -lt (Get-date).AddDays($ExpiryRange)){"Certificate due to expire"} 
        else {"Certificate is not due to expire within date range"}
        DaysToExpire = if ($Creds.EndDateTime -lt (Get-date)){"N/A"} 
        elseif ($Creds.EndDateTime -lt (Get-date).AddDays($ExpiryRange)){($Creds.EndDateTime - (Get-Date)).Days}
        else {"N/A"}
        AuthType = "Certificate"
        }

## Out put results to array
        $results += New-Object psobject -Property $properties

            }
        }
}

## Create HTML Report Content
$appresult = $results | Select-Object ApplicationName,CreatedDateTime,AuthType,StartDateTime,EndDateTime,Expired,DaysToExpire,SigninType | 
ConvertTo-Html -Fragment -As Table -PreContent "<h2>Azure App Registration Details</h2>" | Out-String

## Set color for Expired status
$appresult = $appresult  -replace '<td>Secret has expired</td>','<td class="Expired">Secret has expired</td>' 
$appresult = $appresult  -replace '<td>Secret due to expire</td>','<td class="DuetoExpire">Secret due to expire</td>' 
$appresult = $appresult  -replace '<td>Secret is not due to expire within date range</td>','<td class="Valid">Secret is not due to expire within date range</td>' 

$appresult = $appresult  -replace '<td>Certificate has expired</td>','<td class="Expired">Certificate has expired</td>' 
$appresult = $appresult  -replace '<td>Certificate due to expire</td>','<td class="DuetoExpire">Certificate due to expire</td>' 
$appresult = $appresult  -replace '<td>Certificate is not due to expire within date range</td>','<td class="Valid">Certificate is not due to expire within date range</td>' 

## Export report
ConvertTo-Html -Head $header  -Body "$appresult" | Out-File $ReportExport\Applicaiton_Regisration_Report.htm
