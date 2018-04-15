# check-disabledstatus.ps1
# by Ken Hoover <ken.hoover@yale.edu> - Yale University ITS Windows Systems Team - Spring 2009
#
# reads a text file of usernames and outputs CSV showing the status of that user - OK, DISABLED or NOTFOUND

if (!($args[0])) {
	Write-Host "`nPlease specify a file containing usernames to check on the command line.`n" -ForegroundColor yellow
	exit
}

# the bit pattern for a disabled user
$isdisabled = 0x02

$searcher = new-object DirectoryServices.DirectorySearcher([ADSI]"")

$userlist = Get-Content $args[0] | sort

$i = 0

foreach ($user in $userlist)
{
	$status  = "NOSUCHUSER"
	$i++
	
	$pc = [int](($i / $userlist.count) * 100)
	
	Write-Progress -Activity "Checking users" -Status "$user..." -percentcomplete $pc
	
	$searcher.filter = "(&(objectClass=user)(sAMAccountName= $user))"
	$founduser = $searcher.findOne()
	
	# $uac = ($founduser.psbase.properties.useraccountcontrol[0])
	
	if ($founduser.psbase.properties.useraccountcontrol) {
		if ($founduser.psbase.properties.useraccountcontrol[0] -band $isdisabled) {   # Logical AND test
			$status = "DISABLED"
		} else {
			$status = "OK"
		}
	}
	Write-Host "$user, $status"
}

