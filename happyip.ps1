#===================================
#            Happy IP
#              by
#         Robert Cortese
#     robert@robertcortese.com
#   
#   POSH replacement for Angry IP
#===================================



#====================
#Bunch of GUI Stuff
#====================
$inputXML = @"
<Window x:Name="Happy_IP" x:Class="WpfApp1.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp1"
        mc:Ignorable="d"
        Title="Happy IP" Height="97.131" Width="247.951">
    <Grid>
        <Button x:Name="Scan" Content="Scan" HorizontalAlignment="Left" Margin="157,10,0,0" VerticalAlignment="Top" Width="75"/>
        <TextBox x:Name="IPRange" HorizontalAlignment="Left" Height="23" Margin="10,7,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="142"/>
        <TextBlock HorizontalAlignment="Left" Margin="10,35,0,0" TextWrapping="Wrap" Text="Enter first 3 octets.  Ex: 192.168.1" VerticalAlignment="Top" Width="230" Height="21"/>

    </Grid>
</Window>

"@ 
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
$reader=(New-Object System.Xml.XmlNodeReader $xaml)
try{
    $Form=[Windows.Markup.XamlReader]::Load( $reader )
}
catch{
    Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
    throw
}
 
#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
  
$xaml.SelectNodes("//*[@Name]") | %{"trying item $($_.Name)";
    try {Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop}
    catch{throw}
    }
 
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}
 
Get-FormVariables
 


#=====================================================
#Start
#=====================================================
$WPFScan.Add_Click({
#=====================================================
#Read scan range from text box
#=====================================================
$Scanrange = $WPFIPRange.text
#=====================================================
#Define some known port numbers
#=====================================================
$SSH=22
$HTTP=80
$HTTPS = 443
#=====================================================
#Count from 1 to 254, generating the 4th IP Octet
#=====================================================
1..254 | Foreach-object {

  $requestCallback = $state = $null
#=====================================================
#Test SSH
#=====================================================
  $client = New-Object System.Net.Sockets.TcpClient
  $beginConnect = $client.BeginConnect(($Scanrange+"."+$_),$SSH,$requestCallback,$state)
  Start-Sleep -milli 100
  if ($client.Connected) { $SSHresult = $true } else { $SSHresult = $false }
  $client.Close()
#=====================================================
#Test HTTP
#=====================================================
    $client = New-Object System.Net.Sockets.TcpClient
  $beginConnect = $client.BeginConnect(($Scanrange+"."+$_),$HTTP,$requestCallback,$state)
  Start-Sleep -milli 100
  if ($client.Connected) { $HTTPresult = $true } else { $HTTPresult = $false }
  $client.Close()
#=====================================================
#Test HTTPS
#=====================================================
    $client = New-Object System.Net.Sockets.TcpClient
  $beginConnect = $client.BeginConnect(($Scanrange+"."+$_),$HTTPS,$requestCallback,$state)
  Start-Sleep -milli 100
  if ($client.Connected) { $HTTPSresult = $true } else { $HTTPSresult = $false }
  $client.Close()

  If ($SSHresult -eq $True -or $HTTPresult -eq $True -or $HTTPresult -eq $True){$Inuse = $True} Else {$Inuse = $false}
  
#=====================================================
#Turn test results into a nice grid
#=====================================================
[pscustomobject]@{hostname=($Scanrange+"."+$_);SSH=$SSHresult;HTTP=$HTTPresult;HTTPS=$HTTPSresult;InUse=$Inuse
    } 
  }| Out-GridView -Title ("Results "+$Scanrange+".X")
})
$Form.ShowDialog() | out-null

