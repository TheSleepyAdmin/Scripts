## Setting script parameters
param(
[parameter(Mandatory = $true)]
[String]$FolderPath,
[parameter(Mandatory = $true)]
[String]$ExportPath
)

## Results variable
$results = @()

## Get Folders
$error.clear()
$Folders = Get-ChildItem -Path $FolderPath -Directory |  Select-Object Name,FullName,LastWriteTime,Length
foreach ($err in $Error) {
$err.Exception.Message | Out-File $ExportPath\AccessDenied.txt -Append
}

## Loop through folders
foreach ($Folder in $Folders){

## Get Size of each folder
$size = ((Get-ChildItem -Path $Folder.FullName -Recurse | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB)

## Get access control list
$Acls = Get-Acl -Path $Folder.FullName -ErrorAction SilentlyContinue

## Loop through ACL
foreach ($Acl in $Acls.Access) {

if ($Acl.IdentityReference -notlike "BUILTIN\Administrators" -and $Acl.IdentityReference -notlike "CREATOR OWNER" -and
$Acl.IdentityReference -notlike "NT AUTHORITY\SYSTEM" -and $Acl.FileSystemRights -notlike "-*" -and  $Acl.FileSystemRights -notlike "268435456"`
-and $Acl.IdentityReference -notlike "S-1-*"){

## format properties for result hash table
$properties = @{
FolderName = $Folder.Name
FolderPath = $Folder.FullName
IdentityReference = $Acl.IdentityReference.ToString()
Size = [math]::Round($size,2)
Permissions = $Acl.FileSystemRights
AccessControlType = $Acl.AccessControlType.ToString()
IsInherited = $Acl.IsInherited
}
$results += New-Object psobject -Property $properties
            }
        }

    }

## Export results
$results | Select-Object FolderName,FolderPath,IdentityReference,Size,Permissions,AccessControlType,IsInherited | 
Export-Csv -Path $ExportPath\PermissionExport.csv -Append -NoTypeInformation