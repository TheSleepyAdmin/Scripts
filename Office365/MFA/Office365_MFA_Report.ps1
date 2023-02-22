<#
.SYNOPSIS
Office365 MFA Report
.DESCRIPTION
This script is used to report on all users MFA status in Office365. The following properties are exported 
DisplayName, UPN, AssingedLicence, Licensed, DefaultMethod, MFA Enabled
.EXAMPLE
.\Office365_MFA_Report.ps1 -ExportPath C:\Temp\
#>
param(
    [parameter(Mandatory)]
    [String]$ExportPath 
    ) 

## Import user list
$users = Get-MsolUser -All

## Set result array
$results = @()
foreach ($user in $Users){

## Get user properties
Write-Host "Checking $($user.UserPrincipalName) For strong authenticaiton" -ForegroundColor Green
if($user.StrongAuthenticationMethods){
Write-Host "Authentication Method found for  $($user.UserPrincipalName)" -ForegroundColor Yellow

## Create report hash table
$props = @{
DisplayName = $user.DisplayName
UPN = $user.UserPrincipalName
PhoneNumber = $user.StrongAuthenticationUserDetails.PhoneNumber
"MFA Enabled" = "True"
DefaultMethod = $user.StrongAuthenticationMethods | Where-Object {$_.IsDefault -eq "True"} | Select-Object MethodType -ExpandProperty MethodType
Licensed  = $user.IsLicensed
AssingedLicence = if($user.Licenses.AccountSkuId){$user.Licenses.AccountSkuId -join ","} else {"No Licence Assigned"}
}

## Create result object
$results += New-Object PSObject -Property $props
    }

else {
Write-Host "No Authentication Method found on $($user.UserPrincipalName)" -ForegroundColor red

## Create report hash table
$props = @{
DisplayName = $user.DisplayName
UPN = $user.UserPrincipalName
PhoneNumber = "N/A"
"MFA Enabled" = "False"
DefaultMethod = "N/A"
Licensed  = $user.IsLicensed
AssingedLicence = if($user.Licenses.AccountSkuId){$user.Licenses.AccountSkuId -join ","} else {"No Licence Assigned"}
}

## Create result object
$results += New-Object PSObject -Property $props
        }
    }

## Export results
$results | Select-Object DisplayName,UPN,PhoneNumber,"MFA Enabled",DefaultMethod,Licensed,AssingedLicence | 
Export-Csv "$ExportPath\MFA_User_Report.csv" -NoTypeInformation
