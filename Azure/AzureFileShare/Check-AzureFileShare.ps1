<#
.SYNOPSIS
Azure File Share Report for files over certain date
.DESCRIPTION
Azure File share report that check for files as
Requires that the AZ PowerShell Module is installed

Install-Module -Name Az -Repository PSGallery -Force

.PARAMETER Filedays
Use -Filedays to set the date that will for filtering files
.PARAMETER Resourcegroupname
Use -Resourcegroupname to specify resource group of the storage account 
.PARAMETER Storageaccname
Use -storageaccname to specify storage account name
.PARAMETER azfileshareName
use -azfileshareName to specify azure file share name
.PARAMETER ReportExport
-ReportOnly and -ReportExport to export files to a csv
.PARAMETER DeleteFiles
Use -DeleteFiles to delete files 
.EXAMPLE
.\Check-AzureFileShare.ps1 -FileDate 15 -Resourcegroupname Resourcename -storageaccname storagename -azfileshareName sharename
.EXAMPLE
.\Check-AzureFileShare.ps1 -FileDate 15 -Resourcegroupname Resourcename -storageaccname storagename -azfileshareName sharename -ReportExport c:\temp
.EXAMPLE
.\Check-AzureFileShare.ps1 -FileDate 15 -Resourcegroupname Resourcename -storageaccname storagename -azfileshareName sharename -DeleteFiles
.NOTES
THIS CODE AND ANY ASSOCIATED INFORMATION ARE PROVIDED “AS IS” WITHOUT
WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS
FOR A PARTICULAR PURPOSE. THE ENTIRE RISK OF USE, INABILITY TO USE, OR
RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
#>

param(

    [parameter(Mandatory = $true)]
    [string]$FileDate,    
    [parameter(Mandatory = $true)]
    [string]$Resourcegroupname,    
    [parameter(Mandatory = $true)]
    [string]$storageaccname,
    [parameter(Mandatory = $true)]
    [string]$azfileshareName,
    [parameter(Mandatory = $false)]
    [string]$ReportExport,
    [parameter(Mandatory = $false)]
    [switch]$DeleteFiles
    )

# Resutls Array
$results = @()

# Set date variabled
$date = (Get-Date).AddDays(-$FileDate)

# Get the storage account context  
$sacontext = (Get-AzStorageAccount -ResourceGroupName $resourcegroupname -Name $storageaccname).Context

# Root folder files
$rootfiles = (Get-AZStorageFile -Context $sacontext -ShareName $azfileshareName).CloudFile

# loop through and remove old files
foreach ($rootfile in $rootfiles) {

    # Fetch attributes for files on root folder
    $rootfile.FetchAttributes()

    if($rootfiles.Properties.LastModified -lt $date){
    $properties = @{
    Name = $rootfile.Name
    ShareName = $rootfile.Share.Name
    Uri = $rootfile.Uri
    LastModified = $rootfile.Properties.LastModified
    
    }
    $results += New-Object pscustomobject -Property $properties

    if($DeleteFiles.IsPresent -eq "True" -and $rootfile){
        $rootfile | Remove-AzStorageFile
    Write-Warning "Removing File $($rootfile.Name)" 
    }
}
}

# List folders on Azure FileShare 
$folders = (Get-AZStorageFile -Context $sacontext -ShareName $azfileshareName).CloudFileDirectory

# Loop through Folder 
foreach ($folder in $folders) {  

    Write-Host "Checking Folder $($folder.Name)" -ForegroundColor Green
    
    # Get files in subfolders
    $files = (Get-AZStorageFile -Context $sacontext -ShareName $azfileshareName -Path $folder.Name | Get-AZStorageFile).CloudFile
    
    # Loop through files  
    foreach ($file in $files) { 
      
        # Remove file if it's older than date variable.  
        if ($file.Properties.LastModified -lt $date) {     

                # Fetch attributes for files on root folder
                $file.FetchAttributes()

            $properties = @{
                Name = $file.Name
                ShareName = $file.Share.Name
                Uri = $file.Uri
                LastModified = $file.Properties.LastModified
                
                }
                $results += New-Object pscustomobject -Property $properties

                if($DeleteFiles.IsPresent -eq "True"){
                    Write-Warning "Removing File $($file.Name)"
                    $file | Remove-AzStorageFile
                    }
         }  
    }  

    }

    if ($DeleteFiles.IsPresent -ne "True"){
    $results | Select-Object Name,ShareName,Uri,LastModified    
    }

    if ($ReportExport){
    $results | Select-Object Name,ShareName,Uri,LastModified | Export-Csv $ReportExport\$azfileshareName-Export.csv -NoTypeInformation
    }
