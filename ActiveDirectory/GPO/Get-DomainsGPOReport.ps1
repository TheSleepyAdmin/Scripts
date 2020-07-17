## Setting the script paramaters
param (
    [parameter(Mandatory = $true)]
    [String[]]$Domians,
    [parameter(Mandatory = $true)]
    [String]$ExportPath
)
$Results = @()

## Looping through each domain specified in the doamin variable
foreach ($domain in $Domians) {
    
Write-Host "Checking GPO's on $($domain)" -ForegroundColor Green

## Get list of all GPOs on domain
$AllGpos = Get-GPO -All -Domain $domain

## Looping through each GPO
foreach ($Gpo in $AllGpos) {

## typecast XML results
[xml]$GpoReportXml = Get-GPOReport -Guid $Gpo.ID -ReportType xml -Domain $domain

## set GP assigned variable
if (-not $GpoReportXml.GPO.LinksTo) {
$GPAssigned = "False"
    }
if ($GpoReportXml.GPO.LinksTo){
$GPAssigned = "True"
    }

## Create hash table for properties
$properties = @{
GPO_Name = $gpo.DisplayName
GPO_Assigned = $GPAssigned
Doamin = $gpo.DomainName
Created = $gpo.CreationTime
Last_Modified = $gpo.ModificationTime
Linked_OU = $GpoReportXml.GPO.LinksTo.SOMPath -join ','
}

## out results to variable 
$Results += New-Object psobject -Property $properties
}

## Exprot resutls
$Results | Select-Object GPO_Name,Doamin,GPO_Assigned,Created,Last_Modified,Linked_OU | 
Export-Csv -Path $ExportPath\$domain-GPOReport.csv -NoTypeInformation
}
