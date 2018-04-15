$BiosRev = Get-WmiObject -Class Win32_BIOS -ComputerName $ComputerName -Credential $Credentials

# Shortened URL for the Dell Support page, fileid=441102, appears to be the identifier for BIOS downloads
# I tested this on a few different models of Dell workstations.

$DellBIOSPage = "http://support.dell.com/support/downloads/download.aspx?c=us&cs=RC956904&l=en&s=hied&releaseid=R294848&SystemID=PLX_960&servicetag=$($BiosRev.SerialNumber)&fileid=441102"

# This HTML code immediately preceed's the actual service tag, you can see it when you 'view source' on the page

$DellPageVersionString = "<span id=`"Version`" class=`"para`">"

If ($BiosRev.Manufacturer -match "Dell")
{
    $DellPage = (New-Object -TypeName net.webclient).DownloadString($DellBIOSPage)
    
    # Assuming that Dell BIOS rev's remain 3 characters, I find where my string starts and add the length to it
    # and the substring returns the BIOS rev.
    
    $DellCurrentBios = $DellPage.Substring($DellPage.IndexOf($DellPageVersionString)+$DellPageVersionString.Length,3)
}

If (($BiosRev.SMBIOSBIOSVersion -eq $DellCurrentBios) -eq $false)
{
    # Something more interesting might go here, perhaps to actually download the latest installer
    
    Write-Host "For the latest bios for $($ComputerName)"
    Write-Host "Please visit $($DellBIOSPage)"
}
