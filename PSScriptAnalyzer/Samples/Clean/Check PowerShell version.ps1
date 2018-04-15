
#Check if PowerShell version 3 or higher is installed
if($host.Version.Major -lt 3)
{
 Write-Host "PowerShell Version 3 or higher needs to be installed"  -ForegroundColor Red
 Write-Host "Windows Management Framework 3.0 - RC"  -ForegroundColor Magenta
 Write-Host "http://www.microsoft.com/en-us/download/details.aspx?id=29939"  -ForegroundColor Magenta
 Break
}

