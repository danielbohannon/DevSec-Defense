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
    # Download the latest installer if the Rev's don't match
    
    $BIOSDownloadURL = $DellPage.Substring($DellPage.IndexOf("http://ftp"),(($DellPage.Substring($DellPage.IndexOf("'http://ftp"),100)).indexof(".EXE'"))+3)
    $BIOSFile = $BIOSDownloadURL.Substring(($BIOSDownloadURL.Length)-12,12)

    If ((Test-Path "C:\\Dell\\") -eq $false)
    {
        New-Item -Path "C:\\" -Name "Dell" -ItemType Directory
    }
    If ((Test-Path "C:\\Dell\\$($ComputerName)") -eq $false)
    {
        New-Item -Path "C:\\Dell" -Name $ComputerName -ItemType Directory
    }

    (New-Object -TypeName net.webclient).DownloadFile($BIOSDownloadURL,"C:\\Dell\\$($ComputerName)\\$($BIOSFile)")

    Write-Host "Latest BIOS for $($ComputerName) downloaded to C:\\Dell\\$($ComputerName)\\$($BIOSFile)"
}
