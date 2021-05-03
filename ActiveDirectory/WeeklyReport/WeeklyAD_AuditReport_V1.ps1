<#
.SYNOPSIS
WeeklyAD Audit report 

.DESCRIPTION
This report is used to report on all GPO that have been created or modified in the last 7 day's, AD Objects created in the last 7 day's,
AD Objects deleted in the last 7 day's and Account that are due to expire in the next 7 day's

There are two pre requisites for script to run. The Group policy managment module needs to be install and the AD managment module

.EXAMPLE
.\WeeklyAD_AuditReport_V1.ps1 -exportPath c:\Temp\AD_Audit\ -domains domian.local

.EXAMPLE
.\WeeklyAD_AuditReport_V1.ps1 -SMTPServer mailserver.domain.local -toAddress administrator@domain.local -FromAddress ADreport@domain.local -exportPath c:\Temp\AD_Audit\ -domains domian.local

 .EXAMPLE
.\WeeklyAD_AuditReport_V1.ps1 -SMTPServer mailserver.domain.local -toAddress administrator@domain.local, Admin2@thesleepyadmin.local -FromAddress ADreport@domain.local -exportPath c:\Temp\AD_Audit\ -domains domian.local, Domain.com
#>

param(
    [parameter(Mandatory = $false)]
    [String]$SMTPServer,
    [parameter(Mandatory = $false)]
    [String[]]$toAddress,
    [parameter(Mandatory = $false)]
    [String]$FromAddress,
    [parameter(Mandatory)]
    [String]$exportPath,
    [parameter(Mandatory)]
    [String[]]$domains   
    ) 

function CreateDirectory {
$dlfolder = "$exportPath"
if (!(Test-Path -path $dlfolder)) {
Write-Host $dlfolder "not found, creating it."
New-Item $dlfolder -type directory
   }
      }
CreateDirectory

## Create Date Variable
$date = (Get-Date).AddDays(-7)

foreach ($domain in $domains){

Write-Warning "Checking $($domain)"

$domainName = (Get-ADDomain $domain).Name

## Get All GPO's Create or edited in the last 7 day's
Get-GPO -All -Server $domain | Where-Object {$_.ModificationTime -gt $date -or $_.CreationTime -gt $date} | 
Select-Object DisplayName,DomainName,CreationTime,ModificationTime | Export-Csv $exportPath\$domainName-GPOUpdateReport.csv -NoTypeInformation

## Get AD Objects created in the last 7 day's
Get-ADObject -Filter * -Server $domain -Properties Name,WhenCreated,whenChanged,ObjectClass | Where-Object {$_.whenCreated -gt $date -and `
($_.ObjectClass -like "computer" -or $_.ObjectClass -like "User" -or $_.ObjectClass -like "Group")} | 
Select-Object Name,@{N="ObjectType";E={$_.ObjectClass}},WhenCreated,whenChanged | Export-Csv $exportPath\$domainName-ADOjectReport.csv -NoTypeInformation

## Get AD Objects deleted in the last 7 day's
Get-ADObject -Filter "Name -like '*DEL:*'" -Server $domain -IncludeDeletedObjects -Properties Name,whenChanged,ObjectClass,LastKnownParent,Deleted | Where-Object {$_.whenChanged -gt $date} |
Select-Object Name,whenChanged,@{N="ObjectType";E={$_.ObjectClass}},LastKnownParent,Deleted | Export-Csv $exportPath\$domainName-ADOjectDeletedReport.csv -NoTypeInformation

## Get Account Expiring in the next 7 day's
Get-ADUser -Filter "Enabled -eq '$True'" -Server $domain -Properties AccountExpirationDate | Where-Object {$_.AccountExpirationDate -gt $date} | 
Select-Object -Property SamAccountName, AccountExpirationDate | Export-Csv $exportPath\$domainName-ADUserExpiredReport.csv -NoTypeInformation
}

## Get csv to be attached to Mail
$reportAttachment = Get-ChildItem "$exportPath*.csv"

if ($SMTPServer){
## Send Email report 
Send-MailMessage -From $FromAddress -To $toaddress.Split(',') -Subject "Weekly Domain Reports"`
-Body "Attached is the weekly Domain reports."  -SmtpServer $SMTPServer -Attachments $reportAttachment
}
