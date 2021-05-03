<#
.SYNOPSIS
LAPS script for checking remote doamin

.DESCRIPTION
This script can be used for checking the local admin passwrod attribute on local and remote domain. This script will work without the
need to install any addtional modules. There are two mandartory parramter required computername and domain name.

.EXAMPLE
.\LAPS-CheckFunction.ps1 -client client1 -domName testdom.local

.NOTES
#>

[CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [string]$client,
        [parameter(Mandatory=$true)]
        [String] $domName
    )
function Check-LAPS {

## Get domain details to be called in adsiserach
$domContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $domName)
$LDAP= [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($domContext).GetDirectoryEntry()
$Search = [adsisearcher]$LDAP

## Filtering result to only show required computer
$Search.Filter = "(&(objectCategory=Computer)(name=$client))"
## Return all objects for the required computer
$comp = $Search.FindAll()
## Select results and format
$comp.Properties.'ms-mcs-admpwd'
"$([DateTime]::FromFileTime([Int64]::Parse($comp.Properties.'ms-mcs-admpwdexpirationtime')))"
    }
Check-LAPS
