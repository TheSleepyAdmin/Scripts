$comps = Get-Content "C:\Temp\complist.txt"
$WINSServer = "192.168.0.2"
foreach ($comp in $comps){
Write-Warning "Checking $comp"
$NETBios = Get-WmiObject -ComputerName $comp -Class Win32_NetworkAdapterConfiguration -Filter "WINSPrimaryServer='$WINSServer'"
foreach($net in $NETBios){
$net | Select-Object @{N="ComputerName";E={$comp}},IPAddress,DefaultIPGateway,IPSubnet,WINSPrimaryServer
}
}
