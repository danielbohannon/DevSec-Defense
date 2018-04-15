PARAM ( $MaxEntryCount = 50) 
<# 
    Author: Bartek Bielawski (@bielawb on Twitter)
    Adds cd- functionality known in bash, an probably some other shells.
    Version: 0.1
    Any comments/ feedback welcome, ping me on twitter on via e-mail (bartb at aster dot pl)
#>


<#
    We have to modify prompt function to handle changes in current location.
    To prevent Remove-Module from deleting it we stored in private variable and restore from there OnRemove event.
#>

$oldPrompt = Get-Content function:\\prompt -ErrorAction SilentlyContinue
$MyPrompt = @"
    # Added by cd module
        Add-LocationToList
    # Back to your original prompt
"@

Set-Content function:\\prompt -Force $($MyPrompt + $oldPrompt)

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    # Remove-Module would actually remove Funtion:\\Prompt and we... would like to avoid it
    Set-Content Function:\\prompt -Value $oldPrompt
}


function Add-LocationToList {
  
<#
    .Synopsis
        Adds directory to list of recent locations used by Set-PrevLocation function
    .Description
        This command will add string to collection of recent folders. It checks if string is a valid path.
        It will ignore path if it's the last one added to collection.
        By default it uses global $pwd variable as a parameter, so when launched without parameters will add current location to the list.
    .Example
        Add-LocationtoList
        Adds current location (if not last one added) to collection of recent folders.
    .Example
        Add-LocationList C:\\temp\\foo\\bar
        Adds c:\\temp\\foo\\bar (if it exists and is a container) to the list of recent folders.  
#>
  
    param (
        [ValidateScript( { Test-Path -Path $_ -PathType Container })]
        [string]$pwd = $global:pwd
    )
    if (!($Script:LocationList)) {
        $Script:LocationList = New-Object System.Collections.Generic.List[string]
    }
    if ($Script:LocationList[0] -ne $pwd) { 
        $Script:LocationList.Insert(0,$pwd) 
    }
    while ($Script:LocationList.Count -gt $MaxEntryCount) {
        $Script:LocationList.RemoveAt($MaxEntryCount - 1)
    }
}
    

function Set-PrevLocation {

<#
    .Synopsis
        Goes to folder that was previously visited/ added to the list of recent folders.
    .Description
        This function has 3 possible uses:
        cd- => when used without parameters it will simply move to the folder that is first on the list. Usually that means last visited folder.
        cd- -List => lists all folders available, with Level assigned to them.
        cd- -Level X => changes location to folder with level equal to X
        In order to work correctly requires that prompt function will not be overwritten after module was loaded.
    .Example
        cd c:\\
        cd ~
        cd-
        If prompt function have not been overwritten:
        This will change to root directory, than to home (OS/ user dependent path), and than back to root folder (last visited).
    .Example
        Set-PrevLocation -List
        Lists all folders that are stored on the list of recent folders.
    .example
        cd c:\\
        cd ~
        cd hklm:
        cd hkcu:
        cd function:
        cd alias:
        cd- 5
        If prompt function have not been overwritten:
        Moves to each folder and than jumps back to the one that was visited 5 'jumps' ago.
#>
    PARAM (
        [int]$Level = 1,
        [switch]$List
        )
    if ($List) {
        if ( $Script:LocationList.Count -gt 1) {
            for ($i = 1; $i -lt $LocationList.Count; $i ++) {
                New-Object PSObject -Property @{Level = $I; Path = $LocationList[$i] }
            } 
        } else {
            "List is empty."
        }
        return
    }
    if ($script:LocationList.Count -gt $Level) { 
        Set-Location $script:LocationList[$Level]; 
        for($RemoveAt = 0;$RemoveAt -lt $Level; $RemoveAt++) { 
            $Script:LocationList.RemoveAt(0)
            # That will move others up so next one will always have '0' index. ;)
        }        
    } else {
        Write-Error "Value of Level parameter out of range. Try different value or check list of stored folders (-List)."
    }
}

New-Alias -Name cd- -Value Set-PrevLocation -Force
    
Export-ModuleMember -Function Set-PrevLocation, Add-LocationToList -Alias cd-
