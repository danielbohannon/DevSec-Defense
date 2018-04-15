#Requires -version 2

#Author: Nathan Linley
#More details: http://myitpath.blogspot.com/2012/02/dell-components-check-for-updates-via.html
#OUTPUT FORMAT:

#Component      : FlashBIOS Updates
#path           : PE2850_BIOS_WIN_A07.EXE
#vendorVersion  : A07
#currentversion : A05
#releaseDate    : May 23, 2008
#Criticality    : Optional
#AtCurrent      : False

param(
	[parameter(mandatory=$true)][ValidateScript({test-path $_ -pathtype 'leaf'})][string]$catalogpath,
	[parameter(mandatory=$true,ValueFromPipeline=$true)][string]$server
)

$catalog = [xml](get-Content $catalogpath)
$oscodeid = &{
	$caption = (Get-WmiObject win32_operatingsystem -ComputerName $server).caption
	if ($caption -match "2003") {
		if ($caption -match "x64") { return "WX64E" } else { return "WNET2"}
		if ($caption -match "2008 R2") { return "W8R2"} 
		if ($caption -match "2008" ) {
			if ($caption -match "x64") { return "WSSP2" } else {return "LHS86"}
		}
	}
}

$systemID = (Get-WmiObject -Namespace "root\\cimv2\\dell" -query "Select Systemid from Dell_CMInventory" -ComputerName $server).systemid
$model = (Get-WmiObject -Namespace "root\\cimv2\\dell" -query "select Model from Dell_chassis" -ComputerName $server).Model
$model = $model.replace("PowerEdge","PE").replace("PowerVault","PV").split(" ")   #model[0] = Brand Prefix  #model[1] = Model #

$devices = Get-WmiObject -Namespace "root\\cimv2\\dell" -Class dell_cmdeviceapplication -ComputerName $server
foreach ($dev in $devices) {
	$xpathstr = $parts = $version = ""
	if ($dev.Dependent -match "(version=`")([A-Z\\d.]+)`"") { $version = $matches[2]	} else { $version = "unknown" }
	$parts = $dev.Antecedent.split(",")
	$depparts = $dev.dependent.split(",")
	$componentType = $depparts[0].substring($depparts[0].indexof('"'))
	if ($dev.Antecedent -match 'componentID=""') {
		$xpathstr = "//SoftwareComponent[@packageType='LWXP']/SupportedDevices/Device/PCIInfo"
		if ($componentType -match "DRVR") {
			$xpathstr += "[@" + $parts[2] + " and @" + $parts[3] + "]/../../.."
			$xpathstr += "/SupportedOperatingSystems/OperatingSystem[@osVendor=`'Microsoft`' and @osCode=`'" + $osCodeID + "`']/../.."
		} else {
			$xpathstr += "[@" + $parts[2] + " and @" + $parts[3] + " and @" + $parts[4] + " and @" + $parts[5] + "]/../../.."
			$xpathstr += "/SupportedSystems/Brand[@prefix=`'" + $model[0] + "`']/Model[@systemID=`'" + $systemID + "`']/../../.."
		}
		$xpathstr += "/ComponentType[@value=" + $componentType + "]/.."
	} else {
		$xpathstr = "//SoftwareComponent[@packageType='LWXP']/SupportedDevices/Device[@"	
		$xpathstr += $parts[0].substring($parts[0].indexof("componentID"))
		$xpathstr += "]/../../SupportedSystems/Brand[@prefix=`'" + $model[0] + "`']/Model[@systemID=`'"
		$xpathstr += $systemID + "`']/../../.."
	}
	$result = Select-Xml $catalog -XPath $xpathstr |Select-Object -ExpandProperty Node
	$result |Select-Object @{Name="Component";Expression = {$_.category.display."#cdata-section"}},path,vendorversion,@{Name="currentversion"; Expression = {$version}},releasedate,@{Name="Criticality"; Expression={($_.Criticality.display."#cdata-section").substring(0,$_.Criticality.display."#cdata-section".indexof("-"))}},@{Name="AtCurrent";Expression = {$_.vendorVersion -eq $version}}
}
