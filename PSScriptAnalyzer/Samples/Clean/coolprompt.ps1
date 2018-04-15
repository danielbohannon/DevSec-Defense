
	$global:wmilocalcomputer = get-WMIObject -class Win32_OperatingSystem -computer "."
	$global:lastboottime=[System.Management.ManagementDateTimeconverter]::ToDateTime($wmilocalcomputer.lastbootuptime)
	$global:originaltitle = [console]::title

function prompt 
{
	$up=$(get-date)-$lastboottime

	$upstr="$([datetime]::now.toshorttimestring()) $([datetime]::now.toshortdatestring()) up $($up.days) days, $($up.hours) hours, $($up.minutes) minutes"

	$dir = $pwd.path

	$homedir = (get-psprovider 'FileSystem').home

	if ($homedir -ne "" -and $dir.toupper().startswith($homedir.toupper()))
	{
		$dir=$dir.remove(0,$homedir.length).insert(0,'~')
	}
	
	$retstr = "$env:username@$($env:computername.tolower())&#9679;$dir" 

	[console]::title = "$global:originaltitle &#9830; $retstr &#9830; $upstr" 

	return "$retstr&#9658;"
}
