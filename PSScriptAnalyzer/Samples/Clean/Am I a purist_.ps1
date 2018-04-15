###########
# PS1 script to launch gpupdate on all computers in domain, without some stupid QAD cmdlets, just pure PS1 and WMI
# Made by pan_2@LJ (gunkan@yandex.ru)
# Note: if by some reason RPC host was unavaible - there will be exception throwed, I didn't use trap so I can see real reason.
###########
function PingComputer ([string]$Compname)
{
$pingvar  = Get-WmiObject -Class Win32_PingStatus -Filter "Address='$Compname'"
if ($pingvar.STatusCode -eq 0) {return $True} else {return $False}
}

function SearchAD ()
{
$strFilter = "(objectCategory=Computer)"

$objDomain = New-Object System.DirectoryServices.DirectoryEntry

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.PageSize = 1000
$objSearcher.Filter = $strFilter

$colProplist = "name"

foreach ($i in $colPropList)
	{ 
	$null = $objSearcher.PropertiesToLoad.Add($i) 
	}

$colResults = $objSearcher.FindAll()

foreach ($objResult in $colResults)
	{
	$objItem = $objResult.Properties; 
	[string]$str = ""
	$str = $objItem.name
	$str
	}
}


foreach($str in SearchAD )
{
Write-host "Now trying... $str " -nonew
if (PingComputer $str)
	{
	if ( (([WMICLASS]"\\\\$str\\ROOT\\CIMV2:win32_process").Create("gpupdate.exe").ReturnValue) -eq 0) {write-host " succesfully!" -fo Green} else {write-host "failed!" -fo Red} 
	}
	else
	{ write-host "not responding..." -fo yellow}
}
