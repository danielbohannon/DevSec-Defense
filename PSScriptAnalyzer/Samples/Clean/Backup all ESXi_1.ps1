# Change this to where you would like your backups to go.
# There is no versioning so backup theses backups with real backup software (e.g. on an SMB share).
$backupDir = "c:\\backups"

# Get just your ESXi hosts.
$esxiHosts = Get-VMHost | Where { $_ | Get-View -Property Config | Where { $_.Config.Product.ProductLineId -eq "embeddedEsx" } }

# Back them all up.
$esxiHosts | Foreach {
	$fullPath = $backupDir + "\\" + $_.Name
	mkdir $fullPath -ea SilentlyContinue | Out-Null
	Set-VMHostFirmware -VMHost $_ -BackupConfiguration -DestinationPath $fullPath
}
