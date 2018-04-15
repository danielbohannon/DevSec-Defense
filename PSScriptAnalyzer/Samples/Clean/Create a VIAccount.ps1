function New-VIAccount($principal) {
	$flags = `
		[System.Reflection.BindingFlags]::NonPublic    -bor
		[System.Reflection.BindingFlags]::Public       -bor
		[System.Reflection.BindingFlags]::DeclaredOnly -bor
		[System.Reflection.BindingFlags]::Instance
	$method = $defaultviserver.GetType().GetMethods($flags) |
		where { $_.Name -eq "VMware.VimAutomation.Types.VIObjectCore.get_Client" }
	$client = $method.Invoke($global:DefaultVIServer, $null)
	Write-Output `
		(New-Object VMware.VimAutomation.Client20.PermissionManagement.VCUserAccountImpl `
			-ArgumentList $principal, "", $client)
}

