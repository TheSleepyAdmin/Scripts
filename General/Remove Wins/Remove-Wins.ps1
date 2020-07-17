$comps = Get-Content "C:\Temp\complist.txt"
$WINSServer = "192.168.0.2"
foreach ($comp in $comps){
Write-Warning "Checking $comp"
$NETBios = Get-WmiObject -ComputerName $comp -Class Win32_NetworkAdapterConfiguration -Filter "WINSPrimaryServer='$WINSServer'"
foreach($net in $NETBios){
Write-Warning "WINS currently set to $($net.WINSPrimaryServer) on $comp"
Write-Warning "Removing WINS and Disabling NetBios on Interface $($net.InterfaceIndex) with IP:$($net.IPAddress)"
$NETBios.SetWINSServer("$Null","$Null") | Out-Null
$NETBios.SetTcpipNetbios("2") | Out-Null
}
}
