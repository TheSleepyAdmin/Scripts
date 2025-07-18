$services = @("RpcLocator","SSDPSRV","upnphost","WMPNetworkSvc","icssvc","XboxGipSvc","XblAuthManager","XblGameSave","XboxNetApiSvc")

foreach ($service in $services) {
$servicestatus = (Get-Service $Service).StartType

if ($servicestatus -ne 'Disabled'){

    Set-Service $service -StartupType Disabled

        }
}
