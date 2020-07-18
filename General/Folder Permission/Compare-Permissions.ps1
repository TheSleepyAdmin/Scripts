$PreCIFSCheck = Import-Csv -Path "D:\Scripts\Folder_Permissions\Export\Pre_OAT_CIFS_Export.csv"
$PostCIFSCheck = Import-Csv -Path  "D:\Scripts\Folder_Permissions\Export\Post_OAT_CIFS_Export.csv"
$comparePermssions = Compare-Object $PreCIFSCheck $PostCIFSCheck -Property FolderName,FolderPath,IdentityReference,Permissions,AccessControlType
if ($comparePermssions){
Foreach ($Folder in $comparePermssions){
Write-Warning "Permssion missing from $($Folder.FolderName)"
$Folder | Export-Csv -Path "D:\Scripts\Folder_Permissions\Export\Results.csv" -NoTypeInformation -Append
            }
    }
