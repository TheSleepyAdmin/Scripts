## Add the presentationFramework Assemblty that will be used to creat the Windows PowerShell form
Add-Type -AssemblyName PresentationFramework

## Create function
function Check-LAPS ($client, $domName){
## Remove any with space from inputs
$dom = $domName.trim()
$comp = $client.trim()

## Get domain details to be called in adsiserach
$domContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Domain", $domName)
$LDAP= [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($domContext).GetDirectoryEntry()
$Search = [adsisearcher]$LDAP

## Filtering result to only show required computer
$Search.Filter = "(&(objectCategory=Computer)(name=$client))"
## Return all objects for the required computer
$comp = $Search.FindAll()

## Formate responses 
$Response.text = "$($comp.Properties.'ms-mcs-admpwd')"
$Response1.text = "$([DateTime]::FromFileTime([Int64]::Parse($comp.Properties.'ms-mcs-admpwdexpirationtime')))"
}

## Create the XAML taht will be used for the form
[xml]$XMLForm  = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="LAPS Password Check" Height="300" Width="625" Background="#696969">
    <Grid>
    <Label Name="Domain" Content="Domain" HorizontalAlignment="Left" Height="25" Margin="10,10,0,0" VerticalAlignment="Top" Width="69" FontFamily="Segoe UI" Foreground="White"/>
    <TextBox Name="Dom" HorizontalAlignment="Left" Height="25" Margin="79,10,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="155" BorderBrush="#B22222"/>
    <Label Name="Computer" Content="Computer" HorizontalAlignment="Left" Height="26" Margin="10,41,0,0" VerticalAlignment="Top" Width="69" Foreground="White"/>
    <TextBox Name="Comp" HorizontalAlignment="Left" Height="26" Margin="79,41,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="155" BorderBrush="#B22222"/>
    <Label Name="Password" Content="Password" HorizontalAlignment="Left" Height="24" Margin="10,114,0,0" VerticalAlignment="Top" Width="92" Foreground="White" FontWeight="Bold"/>
    <TextBox Name="response" HorizontalAlignment="Left" Height="40" Margin="10,141,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="495" BorderBrush="#B22222"/>
    <Label Name="Expiry_Date" Content="Expiry_Date" HorizontalAlignment="Left" Height="24" Margin="10,175,0,0" VerticalAlignment="Top" Width="92" Foreground="White" FontWeight="Bold"/>
    <TextBox Name="response1" HorizontalAlignment="Left" Height="30" Margin="10,200,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="495" BorderBrush="#B22222"/>
    <Button Name="Check" Content="Check" HorizontalAlignment="Left" Height="60" Margin="279,10,0,0" VerticalAlignment="Top" Width="226" Background="#191970" Foreground="#FFFDFDFD" FontSize="36" FontWeight="Bold" />
    </Grid>
</Window>
"@

## Out put xml to reader 
$Form=(New-Object System.Xml.XmlNodeReader $XMLForm)

## Load XML
$app=[Windows.Markup.XamlReader]::Load( $Form )

## Get object from form inputs
$start = $app.FindName("Check")
$comp = $app.FindName("Comp")
$dom = $app.FindName("Dom")
$Response = $app.FindName("response")
$Response1 = $app.FindName("response1")

## Craete start button action
$start.Add_Click({

## Create varaibles from form inputs
$client = $comp.text
$domName = $dom.text

## if statments to check for blank domainame or computername
if ($client -like ""){
[System.Windows.MessageBox]::Show('No ComputerName Entered')
    }
elseif ($domName -like ""){
[System.Windows.MessageBox]::Show('No DomainName Entered')
}

else{

## Run check laps fuction
Check-LAPS $client $domName
} 
    })

## Display form
$app.showdialog()
