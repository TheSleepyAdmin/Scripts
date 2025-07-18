$result = @()
$Services = ("RpcLocator","SSDPSRV","icssvc","XboxGipSvc","XblAuthManager","XblGameSave","XboxNetApiSvc","dafsd")

foreach ($service in $Services){

try {
    $servicecheck = Get-service -Name $service -ErrorAction stop | Select-Object Name,StartType

    $property = @{
        ServiceName = $servicecheck.Name
        StartType   = $servicecheck.StartType
    }

    $result += New-Object PSObject -Property $property
    $result
}

catch {
    

    $error[0].Exception | Out-File C:\Windows\System32\LogFiles\Intune_Services_error.log -Append

}

}

if ($report.StartType -notlike "Disabled"){

    Write-Host "Services not disabled" -ForegroundColor Red

    exit 1
}
else {
    Write-Host "Services are disabled" -ForegroundColor Green
    
    exit 0
}
