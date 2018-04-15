function Update-ModulePath {
<#
    .Synopsis
        Command insures that path and the name of psm1 file are alike.
    .Description
        This function should help to troubleshoot modules. It loooks up path that should contain modules.
        For each .psm1 file found it checks if parent folder containing this file has same name.
        I created this function after I was banging my head for few hours why my module won't show up.
        After several approaches it came out clear that it was simple TYPO in file.psm1 name...
    .Example
        Update-ModulePath -Fix Files
        Will look all files and rename .psm1 files to match parent folder
    .Example
        Update-ModulePath -Fix Folder
        Will look all files and rename parent folder to match file names
    .Parameter Fix
        Switch to decide if we prefer to name folders or files to get all matches.
#>
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Files","Folders")]
    [string]$Fix
    )
    <# Steps to be taken:
        * enumerate all .psm1 files
        * check which one is misconfigured
        * rename file/ folder to fix this issue
    #>
    
    ForEach ($ModuleFile in @(Get-ChildItem -Recurse @($($env:PSModulePath).Split(";")) -filter *.psm1)) {
        if (($file = $ModuleFile.BaseName) -eq ($folder = $ModuleFile.Directory.ToString().Split('\\')[-1])) {
            Write-Verbose "$Modulefile.Name is fine"
        } else {
            Write-Verbose "$ModuleFile.Name  is BAD"
            switch ($Fix) {
                "Files" {
                    Write-Verbose "We rename file $file"
                    $OldName = $ModuleFile.FullName
                    $NewName = $OldName -replace "$file.psm1$", "$folder.psm1"
                    
                    
                }
                "Folders" {
                    Write-Verbose "We rename folder $folder"
                    $OldName = $ModuleFile.FullName -replace "\\\\$file.psm1", ""
                    $NewName = $OldName -replace "$folder$", $file
                }
            }
            Write-Host "Renaming $OldName to $NewName"
            Rename-Item -Force $OldName $NewName
        }
    }
}
        
