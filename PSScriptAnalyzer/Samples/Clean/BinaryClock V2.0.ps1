Function Start-BinaryClock {
<#
.SYNOPSIS
    This is a binary clock that lists the time in hours, minutes and seconds
    
.DESCRIPTION
    This is a binary clock that lists the time in hours, minutes and seconds.
    
    Key Input Tips:
    r: Toggles the resize mode of the clock so you can adjust the size.
    d: Toggles the date to hide/show
    o: Toggles whether the clock remains on top of windows or not.
    +: Increases the opacity of the clock so it is less transparent.
    -: Decreases the opacity of the clock so it appears more transparent.
    
    Right-Click to close.
    Use left mouse button to drag clock.
    
.PARAMETER OnColor
    Define the color used for the active time (1).
    
.PARAMETER OffColor
    Define the color used for the inactive time (0).
    
.PARAMETER RandomColor    
    Default parameter if manual colors are not used. Picks a random color for On and Off colors.

.NOTES  
    Name: BinaryClock.ps1
    Author: Boe Prox
    DateCreated: 07/05/2011
    Version 2.0 

.EXAMPLE
    Start-BinaryClock
    
Description
-----------
Starts the binary clock using randomly generated colors 

.EXAMPLE
    Start-BinaryClock -OnColor Red -OffColor Gold -DateColor Black
    
Description
-----------
Starts the binary clock using using specified colors.        
#>
[cmdletbinding(
    DefaultParameterSetName = 'RandomColor'
    )]
Param (
    [parameter(Mandatory = 'True',ParameterSetName = 'SetColor')]
    [system.windows.media.brush] $OnColor,
    [parameter(Mandatory = 'True',ParameterSetName = 'SetColor')]
    [system.windows.media.brush] $OffColor,
    [parameter(ParameterSetName = 'RandomColor')]
    [Switch]$RandomColor, 
    [parameter(Mandatory = 'True',ParameterSetName = 'SetColor')]
    [system.windows.media.brush] $DateColor   
    )
If ($PSCmdlet.ParameterSetName -eq 'RandomColor') {
    [switch]$RandomColor = $True
    }
   
$Global:rs = [RunspaceFactory]::CreateRunspace()
$rs.ApartmentState = “STA”
$rs.ThreadOptions = “ReuseThread”
$rs.Open() 
$psCmd = {Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase}.GetPowerShell() 
$rs.SessionStateProxy.SetVariable('OnColor',$OnColor)
$rs.SessionStateProxy.SetVariable('OffColor',$OffColor)
$rs.SessionStateProxy.SetVariable('RandomColor',$RandomColor)
$rs.SessionStateProxy.SetVariable('DateColor',$DateColor)
$psCmd.Runspace = $rs 
$psCmd.Invoke() 
$psCmd.Commands.Clear() 
$psCmd.AddScript({ 

#Load Required Assemblies
Add-Type –assemblyName PresentationFramework
Add-Type –assemblyName PresentationCore
Add-Type –assemblyName WindowsBase

##Colors
If ($RandomColor) {
    #On Color
    $OnColor = "#{0:X}" -f (Get-Random -min 1 -max 16777215)
    Try {
        [system.windows.media.brush]$OnColor | Out-Null
        }
    Catch {
        $OnColor = "White"
        }
    #Off Color
    $OffColor = "#{0:X}" -f (Get-Random -min 1 -max 16777215)
    Try {
        [system.windows.media.brush]$OffColor | Out-Null
        }
    Catch {
        $OffColor = "Black"
        }
    #DateColor Color
    $DateColor = "#{0:X}" -f (Get-Random -min 1 -max 16777215)
    Try {
        [system.windows.media.brush]$DateColor | Out-Null
        }
    Catch {
        $DateColor = "Black"
        }        
    }

[xml]$xaml = @"
<Window
    xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
    xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
    x:Name='Window' WindowStyle = 'None' WindowStartupLocation = 'CenterScreen' Width = '170' Height = '101' ShowInTaskbar = 'True' 
    ResizeMode = 'NoResize' Title = 'Clock' AllowsTransparency = 'True' Background = 'Transparent' Opacity = '1' Topmost = 'True'>
        <Grid x:Name = 'Grid' HorizontalAlignment="Stretch" ShowGridLines='false'  Background = 'Transparent'>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="2"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="5"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="2"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="5"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="2"/>
                <ColumnDefinition Width="*"/>                
                <ColumnDefinition Width="2"/>
                <ColumnDefinition Width="*" x:Name = 'DayColumn'/> 
                <ColumnDefinition Width="*" x:Name = 'MonthColumn'/> 
            </Grid.ColumnDefinitions>
            <Grid.RowDefinitions>
                <RowDefinition Height = '*'/>
                <RowDefinition Height = '2'/>
                <RowDefinition Height = '*'/>
                <RowDefinition Height = '2'/>
                <RowDefinition Height = '*'/>                
                <RowDefinition Height = '2'/>
                <RowDefinition Height = '*'/>
                <RowDefinition Height = '2'/>
                <RowDefinition x:Name = 'timerow' Height = '0'/>
            </Grid.RowDefinitions>
            <Ellipse Grid.Row = '0' Grid.Column = '0' Fill = 'Transparent'/>
            <Ellipse Grid.Row = '2' Grid.Column = '0' Fill = 'Transparent' />
            <Ellipse x:Name = 'HourA0' Grid.Row = '6' Grid.Column = '0' Fill = 'Transparent' />
            <Ellipse x:Name = 'HourA1' Grid.Row = '4' Grid.Column = '0' Fill = 'Transparent' />    
            <Ellipse x:Name = 'HourB0' Grid.Row = '6' Grid.Column = '2' Fill = 'Transparent'/>
            <Ellipse x:Name = 'HourB1' Grid.Row = '4' Grid.Column = '2' Fill = 'Transparent' />
            <Ellipse x:Name = 'HourB2' Grid.Row = '2' Grid.Column = '2' Fill = 'Transparent' />
            <Ellipse x:Name = 'HourB3' Grid.Row = '0' Grid.Column = '2' Fill = 'Transparent' />
            <Ellipse Grid.Row = '0' Grid.Column = '4' Fill = 'Transparent'/>
            <Ellipse x:Name = 'MinuteA0' Grid.Row = '6' Grid.Column = '4' Fill = 'Transparent' />
            <Ellipse x:Name = 'MinuteA1' Grid.Row = '4' Grid.Column = '4' Fill = 'Transparent' />
            <Ellipse x:Name = 'MinuteA2' Grid.Row = '2' Grid.Column = '4' Fill = 'Transparent' /> 
            <Ellipse x:Name = 'MinuteB0' Grid.Row = '6' Grid.Column = '6' Fill = 'Transparent'/>
            <Ellipse x:Name = 'MinuteB1' Grid.Row = '4' Grid.Column = '6' Fill = 'Transparent' />
            <Ellipse x:Name = 'MinuteB2' Grid.Row = '2' Grid.Column = '6' Fill = 'Transparent' />
            <Ellipse x:Name = 'MinuteB3' Grid.Row = '0' Grid.Column = '6' Fill = 'Transparent' />  
            <Ellipse Grid.Row = '0' Grid.Column = '8' Fill = 'Transparent'/>
            <Ellipse x:Name = 'SecondA0' Grid.Row = '6' Grid.Column = '8' Fill = 'Transparent' />
            <Ellipse x:Name = 'SecondA1' Grid.Row = '4' Grid.Column = '8' Fill = 'Transparent' />
            <Ellipse x:Name = 'SecondA2' Grid.Row = '2' Grid.Column = '8' Fill = 'Transparent' />  
            <Ellipse x:Name = 'SecondB0' Grid.Row = '6' Grid.Column = '10' Fill = 'Transparent'/>
            <Ellipse x:Name = 'SecondB1' Grid.Row = '4' Grid.Column = '10' Fill = 'Transparent' />
            <Ellipse x:Name = 'SecondB2' Grid.Row = '2' Grid.Column = '10' Fill = 'Transparent' />
            <Ellipse x:Name = 'SecondB3' Grid.Row = '0' Grid.Column = '10' Fill = 'Transparent' />                                                                                  
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' Grid.Column = '12' Grid.RowSpan = '7'
            StretchDirection = 'Both' Stretch = 'Fill'>
                <TextBlock x:Name = 'DayLabel' VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch'
                FontWeight = 'Bold'> 
                    <TextBlock.LayoutTransform>
                        <RotateTransform Angle="90" />
                    </TextBlock.LayoutTransform>            
                </TextBlock>
            </Viewbox>
            <Viewbox VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch' Grid.Column = '13' Grid.RowSpan = '7'
            StretchDirection = 'Both' Stretch = 'Fill'>
                <TextBlock x:Name = 'MonthLabel' VerticalAlignment = 'Stretch' HorizontalAlignment = 'Stretch'
                FontWeight = 'Bold'>
                    <TextBlock.LayoutTransform>
                        <RotateTransform Angle="90" />
                    </TextBlock.LayoutTransform>               
                </TextBlock>
            </Viewbox>
        </Grid>
</Window>
"@ 

$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$Global:Window=[Windows.Markup.XamlReader]::Load( $reader )
$Global:DayLabel = $Global:window.FindName("DayLabel")
$Global:MonthLabel = $Global:window.FindName("MonthLabel")
$Global:DayColumn = $Global:window.FindName("DayColumn")
$Global:MonthColumn = $Global:window.FindName("MonthColumn")
$Global:TimeRow = $Global:window.FindName("TimeRow")
$Global:Grid = $Global:window.FindName("Grid")

##Events 
#Key Events
$Global:Window.Add_KeyDown({
    Switch ($_.Key) {
        {'Add','OemPlus' -contains $_} {
            If ($Window.Opacity -lt 1) {
                $Window.Opacity = $Window.Opacity + .1
                $Window.UpdateLayout()
                }            
            }
        {'Subtract','OemMinus' -contains $_} {
            If ($Window.Opacity -gt .2) {
                $Window.Opacity = $Window.Opacity - .1
                $Window.UpdateLayout()
                }             
            }
        "r" {
            If ($Window.ResizeMode -eq 'NoResize') {
                $Window.ResizeMode = 'CanResizeWithGrip'
                }      
            Else {
                $Window.ResizeMode = 'NoResize'             
                }       
            } 
        "d" {
            Switch ($MonthLabel.visibility) {
                'Collapsed' {$MonthLabel.visibility = 'Visible';$DayLabel.Visibility = 'Visible'}
                'Visible' {$MonthLabel.visibility = 'Collapsed ';$DayLabel.Visibility = 'Collapsed '}
                }
            }    
        "o" {
            If ($Window.TopMost) {
                $Window.TopMost = $False
                }
            Else {
                $Window.TopMost = $True
                }
            }     
        }
    }) 
        
$Window.Add_MouseRightButtonUp({
    $This.close()
    })
$Window.Add_MouseLeftButtonDown({
    $This.DragMove()
    })  
         
$update = {
$DayLabel.Text = "$(((Get-Date).ToLongDateString() -split ',')[0] -split '')"
$DayLabel.Foreground = $DateColor
$MonthLabel.Text = Get-Date -u "%B %d %G"
$MonthLabel.Foreground = $DateColor
$hourA,$hourB = [string](Get-Date -f HH) -split "" | Where {$_}
$minuteA,$minuteB = [string](Get-Date -f mm) -split "" | Where {$_}
$secondA,$secondB = [string](Get-Date -f ss) -split "" | Where {$_}

$hourAdock = $grid.children | Where {$_.Name -like "hourA*"}
$minuteAdock = $grid.children | Where {$_.Name -like "minuteA*"}
$secondAdock = $grid.children | Where {$_.Name -like "secondA*"}
$hourBdock = $grid.children | Where {$_.Name -like "hourB*"}
$minuteBdock = $grid.children | Where {$_.Name -like "minuteB*"}
$secondBdock = $grid.children | Where {$_.Name -like "secondB*"}

#hourA
[array]$splittime = ([convert]::ToString($houra,2)) -split"" | Where {$_}
[array]::Reverse($splittime)
$i = 0
ForEach ($hdock in $hourAdock) {
    Write-Verbose "i: $($i)"
    Write-Verbose "split: $($splittime[$i])"
    If ($splittime[$i] -eq "1") {
        $hdock.Fill = $OnColor
        }
    Else {
        $hdock.Fill = $OffColor
        }
    $i++
    }
$i = 0

#hourB
[array]$splittime = ([convert]::ToString($hourb,2)) -split"" | Where {$_}
[array]::Reverse($splittime)
$i = 0
ForEach ($hdock in $hourBdock) {
    Write-Verbose "i: $($i)"
    Write-Verbose "split: $($splittime[$i])"
    If ($splittime[$i] -eq "1") {
        $hdock.Fill = $OnColor
        }
    Else {
        $hdock.Fill = $OffColor
        }
    $i++
    }
$i = 0

#minuteA
[array]$splittime = ([convert]::ToString($minutea,2)) -split"" | Where {$_}
[array]::Reverse($splittime)
$i = 0
ForEach ($hdock in $minuteAdock) {
    Write-Verbose "i: $($i)"
    Write-Verbose "split: $($splittime[$i])"
    If ($splittime[$i] -eq "1") {
        $hdock.Fill = $OnColor
        }
    Else {
        $hdock.Fill = $OffColor
        }
    $i++
    }
$i = 0

#minuteB
[array]$splittime = ([convert]::ToString($minuteb,2)) -split"" | Where {$_}
[array]::Reverse($splittime)
$i = 0
ForEach ($hdock in $minuteBdock) {
    Write-Verbose "i: $($i)"
    Write-Verbose "split: $($splittime[$i])"
    If ($splittime[$i] -eq "1") {
        $hdock.Fill = $OnColor
        }
    Else {
        $hdock.Fill = $OffColor
        }
    $i++
    }
$i = 0

#secondA
[array]$splittime = ([convert]::ToString($seconda,2)) -split"" | Where {$_}
[array]::Reverse($splittime)
$i = 0
ForEach ($hdock in $secondAdock) {
    Write-Verbose "i: $($i)"
    Write-Verbose "split: $($splittime[$i])"
    If ($splittime[$i] -eq "1") {
        $hdock.Fill = $OnColor
        }
    Else {
        $hdock.Fill = $OffColor
        }
    $i++
    }
$i = 0

#secondB
[array]$splittime = ([convert]::ToString($secondb,2)) -split"" | Where {$_}
[array]::Reverse($splittime)
$i = 0
ForEach ($hdock in $secondBdock) {
    Write-Verbose "i: $($i)"
    Write-Verbose "split: $($splittime[$i])"
    If ($splittime[$i] -eq "1") {
        $hdock.Fill = $OnColor
        }
    Else {
        $hdock.Fill = $OffColor
        }
    $i++
    }
$i = 0
}

$Global:Window.Add_KeyDown({
    If ($_.Key -eq "F5") {
        &$update 
        }
    })

#Timer Event
$Window.Add_SourceInitialized({
    #Create Timer object
    Write-Verbose "Creating timer object"
    $Global:timer = new-object System.Windows.Threading.DispatcherTimer 

    Write-Verbose "Adding interval to timer object"
    $timer.Interval = [TimeSpan]"0:0:.10"
    #Add event per tick
    Write-Verbose "Adding Tick Event to timer object"
    $timer.Add_Tick({
        &$update
        Write-Verbose "Updating Window"
        })
    #Start timer
    Write-Verbose "Starting Timer"
    $timer.Start()
    If (-NOT $timer.IsEnabled) {
        $Window.Close()
        }
    })

&$update
$window.Showdialog() | Out-Null             
}).BeginInvoke() | out-null
}
