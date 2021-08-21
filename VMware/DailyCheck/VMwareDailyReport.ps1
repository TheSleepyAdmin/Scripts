<#
.SYNOPSIS
VMware Daily Check Report:
Script is used to run daily health Check for Snapshots, VMware Tools, Datastore Below 20%, Vcenter, Host and VM Alarms.

Author: TheSleepyAdmin
Version: 1.1

.DESCRIPTION
 This script needs to be run on with either VMware PowerCli snappin or module and an
 account that has appropriate rights to connecting using Powercli
 To install PowerCli module run
 Install-Module -Name VMware.PowerCLI
 Install-Module -Name VMware.PowerCLI –Scope CurrentUser

.PARAMETER VCServer
Mandatory Variable for VMware vCenter server.

.PARAMETER SMTPServer
Mandatory Variable for SMTP server. 

.PARAMETER FromAddress
Mandatory Variable for senders address.

.PARAMETER ToAddress
Mandatory Variable for recipients address.

.PARAMETER Export
Mandatory Variables for Export location.

.EXAMPLE
 .\VMwareDailReport.ps1 -VCServer VcenterServer -SMTPServer "smtpserver" -FromAddress "VMwareReport@domain.local" -toAddress user@domain.local -ReportExport c:\temp

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
   [String]$VCServer,
   [parameter(Mandatory = $true)]
   [String]$SMTPServer,
   [parameter(Mandatory = $true)]
   [String[]]$toAddress,
   [parameter(Mandatory = $true)]
   [String]$FromAddress,
   [parameter(Mandatory = $true)]
   [string]$ReportExport
   )

## Script Variables
$snapshotdays = "3"
$Snapshotdate = (Get-Date).AddDays(-$snapshotdays)
$VCEventDate = (Get-Date).AddDays(-1)
$datastorePrecFree = "20"

## Clear VMware Tools Variable
$VMwareToolsReport = ""

## Function to check for export directory and create directory if does not exist.
function CreateDirectory {
$folderCheck = Test-Path -Path "$ReportExport"
if ($folderCheck  -eq $false) {
Write-Warning $dlfolder "not found, creating it."
New-Item $dlfolder -type directory
    }
}
CreateDirectory | Out-Null

## Add Vmware Powershell Module
Add-PSsnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue -ErrorVariable ProcessError;
if ($processerror) {
Write-Warning "PSsnapin is not avaliable. Will load VMware powercli PS Module"
Import-Module -Name VMware.VimAutomation.Core
    }

## VCenter Connection
$VCStatus = connect-VIServer $VCServer -ErrorAction SilentlyContinue -ErrorVariable ErrorProcess;
if($ErrorProcess){
    Write-Warning "Error connecting to vCenter Server $VCServer error message below"
    Write-Warning $Error[0].Exception.Message
    $Error[0].Exception.Message | Out-File $ReportExport\ConnectionError.txt
exit
    }

else
{

## Heading 
$Heading = "<h1>VMware Daily Report</h1>"

## HTML Formating
$HTMLFormat = @"
<style>
body {background-color: #9AB2C7;font-family: Arial; font-size: 14pt;}
h1 {color: 	#080D07; text-align: center;font-size: 40px;display: block;font-family: "Arial Black", Times, serif;}
h2 {color: 	#080D07; font-family: "Arial Black"}
TABLE{border-style: solid;border-color: black;}
TH{border-style: solid;border-color: Black;background-color:	#4682B4;}
TD{background-color:#DCDCDC}
table {
    border-collapse: collapse;width: 100%;
}

table, th, td {
    border: 4px solid black;height: 25px;text-align: Center;font-weight: bold;
}
</style>
"@

## Vcenter Connection Test
Write-Host "Checking vCenter Connection" -ForegroundColor Green
if($VCStatus.IsConnected -eq $true){

$VCConnect = $VCStatus | Select-Object  Name,@{N="Vcenter Server Available";E={$VCStatus.IsConnected}},Port,version | 
ConvertTo-HTML -Fragment -PreContent "<h2>vCenter PowerShell Response</h2>"
    }
Else
{
$VCConnect  = "<h2>vCenter PowerShell Response</h2>" + "Cannot Connect to $($VCStatus.Name)"
    }

## Check Vcenter Web Client
$VCName = $VCStatus.Name
$VCURL = "HTTPS://$VCName/ui"

## Exclude SSL check for Invoke web request
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
try {$VCWebCheck = Invoke-WebRequest -Uri $VCURL -UseBasicParsing} catch {
$ErrorException = $_.Exception
$ErrorResponse = $_.Exception.Response}
if ($VCWebCheck.StatusCode -eq "200") {
$VCResponseStatus = $VCWebCheck| Select-Object @{N="VC Web URL";E={$VCURL}},StatusCode,@{N="StatusDescription";E={"OK"}} | 
ConvertTo-Html -Fragment -PreContent "<h2>vCenter Connection Response</h2>"
    }
Else
{
$VCResponseStatus = $ErrorResponse | Select-Object @{N="VC Web URL";E={$_.ResponseUri}},StatusCode,
@{N="StatusDescription";E={$ErrorException.Message}} | 
ConvertTo-Html -Fragment -PreContent "<h2>vCenter Connection Response</h2>"
}

## VMware Tools Version
Write-Host "Checking for out of date VMware tools" -ForegroundColor Green
$VMwareToolsReport = Get-VM | get-view | Select-Object Name, 
@{N="HW Version";E={$_.Config.Version}}, @{N="ToolsVersion";E={$_.Config.tools.ToolsVersion}},
@{N="VMToolsStatus";E={$_.Guest.ToolsStatus}},@{N="ToolsVersionStatus";E={$_.Guest.ToolsVersionStatus}},@{N="VMPowerstatus";E={$_.runtime.PowerState}} | 
Where-Object {$_.VMToolsStatus -Notlike "toolsOK" -and $_.VMPowerstatus -eq "poweredOn"}
if ($VMwareToolsReport) {
$vmToolsReport = $VMwareToolsReport | ConvertTo-HTML -Fragment -PreContent "<h2>VMwareTools Report</h2>"
}
else {
$vmToolsReport = "<h2>VMwareTools Report</h2>" + "No VM's With Out Of Date VMware Tools"
}

## Snapshots Older than three days
Write-Host "Checking for Snapshots older than $($snapshotdays) days" -ForegroundColor Green
$Snapshot  = get-vm | get-snapshot
$SnapshotReport = $Snapshot | Select-Object vm, name,created,description | Where-Object {$_.created -lt $Snapshotdate}
if ($SnapshotReport) {
$SnapReport = $SnapshotReport | ConvertTo-HTML -Fragment -PreContent "<h2>Snapshot Report</h2>" }
else {
$SnapReport = "<h2>Snapshot Report</h2>" + "No Snapshots older than $($snapshotdays)"
}

## VMHost Alarms
Write-Host "Checking for active VMware host alarms" -ForegroundColor Green
$VMHAlarmReport = @()
$VMHostStatus = (Get-VMHost | Get-View) | Select-Object Name,OverallStatus,ConfigStatus,TriggeredAlarmState
$HostErrors= $VMHostStatus  | Where-Object {$_.OverallStatus -ne "Green" -and $_.TriggeredAlarmState -ne $null} 
if ($HostErrors){
foreach ($hosterror in $HostErrors){
foreach($alarm in $HostError.TriggeredAlarmState){
$Hprops = @{
Host = $HostError.Name
OverAllStatus = $HostError.OverallStatus
TriggeredAlarms = (Get-AlarmDefinition -Id $alarm.alarm).Name
}
[array]$VMHAlarmReport += New-Object PSObject -Property $Hprops
}
}
}

if ($VMHAlarmReport){
$VMHAlarms = $VMHAlarmReport | Select-Object Host,OverAllStatus,TriggeredAlarms | ConvertTo-HTML -Fragment -PreContent "<h2>VMHost Alerts</h2>" 
}
else{
$VMHAlarms = "<h2>VMHost Alerts</h2>" + "No active alarms for VMware host's"
}

## VM Alarms
Write-Host "Checking for active VM alarms" -ForegroundColor Green
$VMAlarmReport = @()
$VMStatus = (Get-VM | Get-View) | Select-Object Name,OverallStatus,ConfigStatus,TriggeredAlarmState
$VMErrors = $VMStatus  | Where-Object {$_.OverallStatus -ne "Green"}
if ($VMErrors) {
foreach ($VMError in $VMErrors){
foreach ($TriggeredAlarm in $VMError.TriggeredAlarmstate) {
$VMprops = @{
VM = $VMError.Name
OverAllStatus = $VMError.OverallStatus
TriggeredAlarms = (Get-AlarmDefinition -Id $TriggeredAlarm.Alarm).Name
}
[array]$VMAlarms += New-Object PSObject -Property $VMprops
}
}
}

if ($VMAlarms){
$VMAlarmReport = $VMAlarms | ConvertTo-HTML -Fragment -PreContent "<h2>VM Alerts</h2>" 
}
else{
$VMAlarmReport = "<h2>VM Alerts</h2>" + "No active alarms for VM"
}

## Vcenter Events
Write-Host "Checking for Critical events for the last 12 hours" -ForegroundColor Green
$start = (Get-Date).AddHours(-12)
$VCAlerts = Get-VIEvent -Start $start -MaxSamples ([int]::MaxValue) |
Where-Object {$_ -is [VMware.Vim.AlarmStatusChangedEvent] -and ($_.To -match "red|yellow") -and
($_.FullFormattedMessage -notlike "*Virtual machine*")`
-and ($_.CreatedTime -gt $VCEventDate)}
if ($VCAlerts) {
$ActiveVCAlert = $VCAlerts | Select-Object @{N="vCenter Events";E={$_.FullFormattedMessage}},CreatedTime | Sort-Object -Property CreatedTime -Descending | 
ConvertTo-Html -Fragment -PreContent "<h2>vCenter Alerts</h2>"
}
else
{
$ActiveVCAlert = "<h2>vCenter Alerts</h2>" + "No Active Alerts For The Last 12Hours"
}

## Datastore Functions
Write-Host "Checking for datastores below $($datastorePrecFree)% free space" -ForegroundColor Green
$DSReport = Get-Datastore | Select-Object Name,@{N="UsedSpaceGB";E={[math]::Round(($_.CapacityGB),2)}},
@{N="FreeSpaceGB";E={[math]::Round(($_.FreeSpaceGB),2)}},
@{N="%Free";E={[math]::Round(($_.FreeSpaceGB)/($_.CapacityGB)*100,2)}}
$DSBelow = $DSReport | Where-Object {$_."%Free" -lt $($datastorePrecFree)}
if ($DSBelow) {
$DSExport = $DSBelow | ConvertTo-HTML -Fragment -PreContent "<h2>DataStore Under $($datastorePrecFree)% Free Space</h2>"
}
else{
$DSExport = "<h2>DataStore Under $($datastorePrecFree)% Free Space</h2>" + "No DataStores below $($datastorePrecFree)% free space"
}

## check for old reports
$file = Get-ChildItem $ReportExport\$VCServer-DailyReport.htm -ErrorAction SilentlyContinue
if (!$file){
Remove-Item $ReportExport\$VCServer-DailyReport.htm -ErrorAction SilentlyContinue
    }

## export results
ConvertTo-Html -Body "$Heading $VCConnect $VCResponseStatus $vmToolsReport $SnapReport $VMHAlarms $VMAlarmReport $ActiveVCAlert $DSExport"  -Head $HTMLFormat | 
Out-File $ReportExport\$VCServer-DailyReport.htm

## Mail variables
Send-MailMessage -From $FromAddress -To $toaddress -Subject "VMware Daily Report"`
-Body "VMware Daily Report attached"  -SmtpServer $SMTPServer -Attachments $ReportExport\$VCServer-DailyReport.htm

## Report export location 
Write-Host "Report has been exported to $ReportExport\$VCServer-DailyReport.htm" -ForegroundColor Yellow
## Disconnect session from VC
disconnect-viserver -confirm:$false
}
