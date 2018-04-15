[CmdletBinding()]
param(
	[string]$Path = 'C:\\',
	[string]$User1 = "$Env:USERDOMAIN\\$Env:UserName",
	[string]$User2 = "BuiltIn\\Administrators",
	[switch]$recurse
)
foreach($fso in ls $path -recurse:$recurse) { 
	$acl = @(get-acl $fso.FullName | select -expand Access | Where IdentityReference -in $user1,$user2) 
	if($acl.Count -eq 1) { 
		Write-Warning "Only $($acl[0].IdentityReference) has access to $($fso.FullName)"
	} elseif($acl.Count -eq 2) { 
		if(compare-object $acl[0] $acl[1] -Property FileSystemRights, AccessControlType) { 
			Write-Warning "Different rights to $($fso.FullName)" 
		}
	} # if acl.count -eq 0 they're the same
}
