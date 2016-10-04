
$rawdump = test-path -Path C:\Util\BilInfo\rawdump
if ($rawdump -eq $false){
    mkdir C:\util\BilInfo\rawdump
    }

$carlist = test-path -Path C:\Util\BilInfo\carlist
if ($carlist -eq $false){
    mkdir C:\util\Bilinfo\carlist
    }





$inputXML = @"
<Window x:Class="TestApplikasjon.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:TestApplikasjon"
        mc:Ignorable="d"
        Title="BilInfo v 0.1 ALPHA" Height="430" Width="1000">
    <Grid>
        <Button x:Name="button" Content="Søk" HorizontalAlignment="Left" Margin="196,30,0,0" VerticalAlignment="Top" Width="75"/>
        <Button x:Name="button_exit" Content="Exit" HorizontalAlignment="Left" Margin="900,30,0,0" VerticalAlignment="Top" Width="75"/>
        <Button x:Name="button_export" Content="Export" HorizontalAlignment="Left" Margin="820,30,0,0" VerticalAlignment="Top" Width="75"/>
        <TextBox x:Name="textBox" HorizontalAlignment="Left" Height="23" Margin="16,30,0,0" TextWrapping="Wrap" Text="Skriv inn regnr..." VerticalAlignment="Top" Width="168" FontSize="12"/>
        <ListView x:Name="listView" HorizontalAlignment="Left" Height="327" Margin="10,65,0,0" VerticalAlignment="Top" Width="965" Grid.ColumnSpan="2">
            <ListView.View>
                <GridView>
                    <GridViewColumn Header="RegNr" DisplayMemberBinding ="{Binding 'Regnummer'}" Width="100"/>
                    <GridViewColumn Header="Biltype" DisplayMemberBinding ="{Binding 'Biltype'}" Width="100"/>
                    <GridViewColumn Header="EUkontroll" DisplayMemberBinding ="{Binding 'EUKontroll'}" Width="200"/>
                    <GridViewColumn Header="Heftelser" DisplayMemberBinding ="{Binding 'Heftelser'}" Width="200"/>
                    <GridViewColumn Header="Drivverk" DisplayMemberBinding ="{Binding 'Drivverk'}" Width="360"/>
                </GridView>
            </ListView.View>
        </ListView>

    </Grid>
</Window>


"@       
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
 
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."}
 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
 
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
 
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}
 
Get-FormVariables
 
#===========================================================================
# Actually make the objects work
#===========================================================================
cls

$AlleBiler = @()

function Get-CarInfo {

param (
$Regnummer = $WPFtextBox.Text
)

$Bilinformasjon = @()

foreach ($regnr in $Regnummer){

$rest = Invoke-webrequest -Uri "https://regnr.info/$regnr"
$rest.ParsedHtml.body.outerText | Out-File .\rawdump\$regnr.txt
$BilInfoRaw = get-content .\rawdump\$regnr.txt

$props = @{
Regnummer = $regnr
Biltype = $BilInfoRaw[14]
#Bilmodell = $BilInfoRaw[16]
Bilinfo = $BilInfoRaw[16]
Heftelser = $BilInfoRaw[21]
EUkontroll = $BilInfoRaw[23]
Chassisnummer = $BilInfoRaw[24]
Drivverk = $BilInfoRaw[25] 
}

$obj = New-Object psobject -Property $props

$Bilinformasjon += $obj

}
 
$bilinformasjon | Select-Object @{Name='Regnummer';ex={$_.Regnummer}}, # regnummer,bilmodell,biltype,eukontroll,heftelser,chassisnummer,bilinfo,motorogdrivverk 
                                @{Name='Biltype';ex={$_.Biltype}},
                                @{Name='EUKontroll';ex={$_.EUKontroll}},
                                @{Name='Heftelser';ex={$_.Heftelser}},
                                @{Name='Drivverk';ex={$_.Drivverk}}


}



$WPFbutton.Add_Click({
#$WPFlistView.Items.Clear()
#start-sleep -Milliseconds 840
Get-CarInfo | % {$WPFlistView.AddChild($_)}
})

$WPFbutton_export.add_click({
$WPFlistView.items | Export-Csv -Path C:\git\privat\BilInfo\carlist\biler.csv
})

$WPFbutton_exit.add_click({
$Form.close()
})


#$Services = get-service -name spooler | Select-Object @{Name='Name';ex={$_.DisplayName}},`#                                        @{Name='Status';ex={$_.status}}


#$WPFbutton.Add_Click({
#$WPFlistView.Items.Clear()
#start-sleep -Milliseconds 840
#$Services | % {$WPFlistView.AddChild($_)}
#})

#$WPFbutton.Add_Click({
#$WPFlistView.AddChild('test,test')
##$Form.close()
# })


<#Function Get-DiskInfo {
param($computername =$env:COMPUTERNAME)
 
Get-WMIObject Win32_logicaldisk -ComputerName $computername | Select-Object @{Name='ComputerName';Ex={$computername}},`
                                                                    @{Name=‘Drive Letter‘;Expression={$_.DeviceID}},`
                                                                    @{Name=‘Drive Label’;Expression={$_.VolumeName}},`
                                                                    @{Name=‘Size(MB)’;Expression={[int]($_.Size / 1MB)}},`
                                                                    @{Name=‘FreeSpace%’;Expression={[math]::Round($_.FreeSpace / $_.Size,2)*100}}
                                                                 }

                                                                 #>
 
#$WPFtextBox.Text = $env:COMPUTERNAME
#$WPFtextBox.Text = "ZZ10867"

#$WPFbutton.Add_Click({
#$Regnr = $($WPFtextBox.Text)
#$Url = "https://regnr.info/$regnr"
#$WPFlistView.Items.Clear()
#start-sleep -Milliseconds 840
#echo FØKK
#Get-CarInfo -Regnr $WPFtextBox.Text #| % {$WPFlistView.AddChild($_)}

#Sample entry of how to add data to a field
 
#$vmpicklistView.items.Add([pscustomobject]@{'VMName'=($_).Name;Status=$_.Status;Other="Yes"})
 
#===========================================================================
# Shows the form
#===========================================================================
write-host "To show the form, run the following" -ForegroundColor Cyan
$Form.ShowDialog() | out-null 