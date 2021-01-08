<#
.SYNOPSIS
Check local group for members and export to a csv

.DESCRIPTION
This script is used to check local group members and export the resutls to a csv. 

.PARAMETER CompList
Complist parameter is used to import the txt file that contians the computer names that will be check for local groups

.PARAMETER exportPath
Parameter that specifies the path that csv will be exported to

.PARAMETER groups
Parameter to set what groups will be checked

.EXAMPLE
Get-RemoteGroupMembers -CompList c:\Temp\Comps.txt c:\Temp\Results -groups "Administrators"

.EXAMPLE
Get-RemoteGroupMembers -CompList .\Comps.txt -exportPath .\ -groups "Administrators","Remote Desktop Users"

.NOTES

#>
[CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [string]$CompList,
        [parameter(Mandatory=$true)]
        [String] $exportPath,
        [parameter(Mandatory=$true)]
        [String[]] $groups,
        [String] $date = (Get-Date -Format dd-MM-yy)
        )

## Import computer list
$comps = Get-Content $CompList

## Blank results array
$results = @()

## Loop through server in list
foreach ($comp in $comps){

## Check connection to device
$tc = Test-Connection -ComputerName $comp -Count 1 -Quiet
if ($tc -eq $true){


## Loop through groups
foreach ($group in $groups){

## Get Local groups members
$groupmembers = Get-WmiObject -computername $comp -Class Win32_GroupUser -Filter "GroupComponent=""Win32_Group.Domain='$comp',Name='$group'""" `
 -ErrorAction SilentlyContinue -ErrorVariable ErrorProcess;

if($ErrorProcess){
Write-Warning "Error from $comp error message below"
Write-Warning $Error[0].Exception.Message
}

##Format results

## Loop through each users in results
foreach ($member in $groupmembers){

## Filter result using regular expression
$member.partcomponent -match ".+Domain\=(.+)\,Name\=(.+)$" | Out-Null  

##Format results
$domain = $matches[1].trim('"')
$username = $matches[2].trim('"')


## Filter result using regular expression
$member.GroupComponent -match '.+Name\="(.+)$' | Out-Null

##Format results
$groupesult = $matches[1].Trim('"')

## Results hash table
$props = @{
Users = $username
Group = $groupesult
Computer = $member.PSComputerName
Domain = $domain
}

## Create results array
$results += New-Object psobject -Property $props
        }
    }
}
else{

Write-Host "$comp is not responding " -ForegroundColor Red
    }
}

$results | Export-csv -Path $exportPath\Remote_GroupExport_$date.csv -NoTypeInformation
$results
Write-Host "Report has been Exported to $($exportPath)" -ForegroundColor Green
