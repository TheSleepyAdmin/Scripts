$registryPath = "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient"
$registryvalue = "EnableNetbios"
$datavalue = "2"

If (-not (Test-Path $registryPath)) {
    Write-Host "$($registryvalue) Registry Key Not found" -ForegroundColor Red
      try {
        New-Item -Path $registryPath -Force -ErrorAction Stop
      }

      catch {
        $error[0].Exception | Out-File C:\Windows\Logs\Intune_Remidation_Script.log
        Exit 1
        
      }
}

If (Test-Path $registryPath){

    $reg = Get-ItemProperty -Path  $registryPath
    If ($reg.$registryvalue -ne $datavalue) {
    Write-Host "$($registryvalue) registry value not set to $($datavalue)" -ForegroundColor Yellow

      try {
        Set-ItemProperty -LiteralPath $registryPath -Name $registryvalue -Value $datavalue -Force -ErrorAction Stop
      }

      catch {
        $error[0].Exception | Out-File C:\Windows\Logs\Intune_Remidation_Script.log
        Exit 1
      }

    }

    else {

    Write-Host "Registry value found" -ForegroundColor Green
    Exit 0
    }
}

