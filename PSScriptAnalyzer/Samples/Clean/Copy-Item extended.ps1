function Copy-ToCreateFolder
{
    param(
        [string]$src,
        [string]$dest,
        $exclude,
        [switch]$Recurse
    )
    
    # The promlem with Copy-Item -Rec -Exclude is that -exclude effects only top-level files
    # Copy-Item $src $dest    -Exclude $exclude       -EA silentlycontinue -Recurse:$recurse
    # http://stackoverflow.com/questions/731752/exclude-list-in-powershell-copy-item-does-not-appear-to-be-working
    
    if (Test-Path($src))
    {
        # nonstandard: I create destination directories on the fly
        [void](New-Item $dest -itemtype directory -EA silentlycontinue )
        Get-ChildItem -Path $src -Force -exclude $exclude | % {
            
            if ($_.psIsContainer)
            {
                if ($Recurse) # non standard: I don't want to copy empty directories
                {
                    $sub = $_
                    $p = Split-path $sub
                    $currentfolder = Split-Path $sub -leaf
                    #Get-ChildItem $_ -rec -name  -exclude $exclude -Force | % {  "{0}    {1}" -f $p, "$currentfolder\\$_" }
                    [void](New-item $dest\\$currentfolder -type directory -ea silentlycontinue)
                    Get-ChildItem $_ -Recurse:$Recurse -name  -exclude $exclude -Force | % {  Copy-item $sub\\$_ $dest\\$currentfolder\\$_ }
                }
            }
            else
            {
                
                #"{0}    {1}" -f (split-path $_.fullname), (split-path $_.fullname -leaf)
                Copy-Item $_ $dest
            }
        }
    }
}

