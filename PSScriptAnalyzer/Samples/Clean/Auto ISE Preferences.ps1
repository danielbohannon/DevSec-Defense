##############################################################
#Author: Ravikanth Chaganti (http://www.ravichaganti.com/blog)
#Script: SaveISEPrefs.ps1
#Description: PowerShell ISE profile script to automatically
#             archive changes to ISE preferences such as color
#             schemes, font, etc
##############################################################

#Add System.XML namespace
Add-Type -AssemblyName System.XML

#Initialize XML serializer
$xmlSerializer = New-Object System.Xml.Serialization.XmlSerializer($PSISE.Options.GetType())

#Path to ISE Preferences xml file. This will be created on first use
$file = $("$env:APPDATA\\isePreferences.xml")

#This function will be called when PropertyChanged event gets fired
function New-EventAction {
    param ([System.Management.Automation.PSEventArgs]$objEvent)
    $changedProperty = ($objEvent.SourceEventArgs.PropertyName).ToString()
    Write-Host "Value of $changedProperty changed to $($objEvent.SourceArgs.Get(0).$changedProperty)"
    $xmlWriter = [System.Xml.XmlTextWriter]::Create($file)
    $xmlSerializer.Serialize($xmlWriter,$psISE.Options)
    $xmlWriter.Close()
}

#This function gets called everytime we open ISE to restore the ISE prefernces from $File
function Update-ISEOptions {
    If (!(Get-Item $file -ea SilentlyContinue)) {
            Write-Host "$file not found"
            return
    }
        $xmlReader = New-Object System.Xml.XmlTextReader($file)
        $newISEOptions = $xmlSerializer.Deserialize($xmlReader)        
        $psISE.Options.SelectedScriptPaneState=$newISEOptions.SelectedScriptPaneState
        $psISE.Options.ShowToolBar=$newISEOptions.ShowToolBar
        $psISE.Options.FontSize=$newISEOptions.FontSize
        $psISE.Options.FontName=$newISEOptions.FontName
        $psISE.Options.ErrorForegroundColor=$newISEOptions.ErrorForegroundColor
        $psISE.Options.ErrorBackgroundColor=$newISEOptions.ErrorBackgroundColor
        $psISE.Options.WarningForegroundColor=$newISEOptions.WarningForegroundColor
        $psISE.Options.WarningBackgroundColor=$newISEOptions.WarningBackgroundColor
        $psISE.Options.VerboseForegroundColor=$newISEOptions.VerboseForegroundColor
        $psISE.Options.VerboseBackgroundColor=$newISEOptions.VerboseBackgroundColor
        $psISE.Options.DebugForegroundColor=$newISEOptions.DebugForegroundColor
        $psISE.Options.DebugBackgroundColor=$newISEOptions.DebugBackgroundColor
        $psISE.Options.OutputPaneBackgroundColor=$newISEOptions.OutputPaneBackgroundColor
        $psISE.Options.OutputPaneTextBackgroundColor=$newISEOptions.OutputPaneTextBackgroundColor
        $psISE.Options.OutputPaneForegroundColor=$newISEOptions.OutputPaneForegroundColor
        $psISE.Options.CommandPaneBackgroundColor=$newISEOptions.CommandPaneBackgroundColor
        $psISE.Options.ScriptPaneBackgroundColor=$newISEOptions.ScriptPaneBackgroundColor
        $psISE.Options.ScriptPaneForegroundColor=$newISEOptions.ScriptPaneForegroundColor
        $psISE.Options.ShowWarningForDuplicateFiles=$newISEOptions.ShowWarningForDuplicateFiles
        $psISE.Options.ShowWarningBeforeSavingOnRun=$newISEOptions.ShowWarningBeforeSavingOnRun
        $psISE.Options.UseLocalHelp=$newISEOptions.UseLocalHelp
        $psISE.Options.CommandPaneUp = $newISEOptions.CommandPaneUp
        $xmlReader.Close()
    
}

#Check for $psISE and then register the event subscriber
if ($psise) {
    Update-ISEOptions
    Register-ObjectEvent -InputObject $psISE.Options -EventName PropertyChanged -Action { New-EventAction $Event } | Out-Null
}
