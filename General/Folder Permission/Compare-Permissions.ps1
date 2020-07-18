$PreCIFSCheck = Import-Csv -Path "C:\Pre_OAT_CIFS_Export.csv"
$PostCIFSCheck = Import-Csv -Path  "C:\Exports\Post_OAT_CIFS_Export.csv"
$comparePermssions = Compare-Object $PreCIFSCheck $PostCIFSCheck -Property FolderName,FolderPath,IdentityReference,Permissions,AccessControlType
if ($comparePermssions){
Foreach ($Folder in $comparePermssions){
Write-Warning "Permssion missing from $($Folder.FolderName)"
$Folder | Export-Csv -Path "C:\Exports\Results.csv" -NoTypeInformation -Append
            }
    }
