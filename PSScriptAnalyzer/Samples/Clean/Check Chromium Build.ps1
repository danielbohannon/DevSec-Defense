# Name  : Check-LatestChromium.ps1
# Author: David "Makovec" Moravec
# Web   : http://www.powershell.cz
# Email : powershell.cz@googlemail.com
#
# Description: Check latest Chromium build
#            : Uses HttpRest http://poshcode.org/787
#
# Version: 0.1
# History:
#  v0.1 - (add) build check
#       - (add) split to handle more return values
#      
# ToDo: download file
#       unzip 
#       check installed version of Chromium
#
# Usage: Check-LatestChromium 
#
#################################################################

function Check-LatestChromium {

	$url = 'http://build.chromium.org/buildbot/snapshots/chromium-rel-xp/'
	$XPathRelDate = "//tr[position()=last()-2]//td[3]"
	$XPathBuild = "//tr[position()=last()-2]//td[2]//a"
	
	$page = Invoke-Http get $url
	
	$releaseDate = $page | Receive-Http text $XPathRelDate
	($page | Receive-Http text $XPathBuild) -match "(?<build>\\d*)" | Out-Null	
	
	"Latest Build is: {0}, released at {1}" -f $matches.build, $releaseDate 

}
