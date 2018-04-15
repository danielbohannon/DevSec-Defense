function Set-ComputerName {
	param(	[switch]$help,
		[string]$originalPCName=$(read-host "Please specify the current name of the computer"),
		[string]$computerName=$(read-host "Please specify the new name of the computer"))
			
	$usage = "set-ComputerName -originalPCname CurrentName -computername AnewName"
	if ($help) {Write-Host $usage;break}
	
	$computer = Get-WmiObject Win32_ComputerSystem -OriginalPCname OriginalName -computername $originalPCName
	$computer.Rename($computerName)
	}
