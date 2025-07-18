$registryPath = "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient"
$registryvalue = "EnableNetbios"
$datavalue = "2"

If (-not (Test-Path $registryPath)) {
    Write-Host "$($registryvalue) Registry Key Not found" -ForegroundColor Red
      
    Exit 1
}

If (Test-Path $registryPath){

    $reg = Get-ItemProperty -Path  $registryPath
    If ($reg.$registryvalue  -ne $datavalue) {
    Write-Host "$($registryvalue)  registry value not set to $($registryvalue)" -ForegroundColor Yellow
    Exit 1
    }

    else {

    Write-Host "Registry value found" -ForegroundColor Green
    Exit 0
    
}
}
