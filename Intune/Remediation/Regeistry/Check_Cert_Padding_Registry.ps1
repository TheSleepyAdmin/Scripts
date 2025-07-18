$registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography\Wintrust\Config"
$registryvalue = "EnableCertPaddingCheck"
$datavalue = "1"


    Write-Host "$registryPath" -ForegroundColor Green

If (-not (Test-Path $registryPath)) {
    Write-Host "$($registryPath) Registry Key Not found" -ForegroundColor Red
      
    Exit 1
}

If (Test-Path $registryPath){

    $reg = Get-ItemProperty -Path  $registryPath
    If ($reg.$registryvalue  -ne $datavalue) {
    Write-Host "$($registryvalue) registry value not set to $($registryvalue)" -ForegroundColor Yellow
    Exit 1
    }

    else {

    Write-Host "Registry value found" -ForegroundColor Green
    Exit 0
    
}
}
