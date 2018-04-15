#Parameter- Name of the VMware cluster to work in
param($cluster)

Write-Output "`n$(Get-Date)- Script started`n"

# Validate parameter input
$IsClusterNameInvalid = $true
Get-Cluster | % { If ($_.Name -eq $Cluster) {$IsClusterNameInvalid = $false} }
If ($IsClusterNameInvalid) {
	Write-Host "Error- Invalid Cluster Name" -Background Yellow -Foreground Red
	Write-Host "Valid cluster names for this Virtual Center server."
	Write-Host "---------------------------------------------------"
	Get-Cluster | Sort
	break
}

# Prep
$ScriptDir = "\\\\vmscripthost201\\repo"
. $ScriptDir\\mGet-DataStoreList.ps1

# Get the list of valid datastores and pick the one with the least free space.
$DSTs = mGet-DataStoreList $Cluster
$DSTInfo = $DSTs | Select-Object Name,@{n="CapacityGB";e={[math]::round(($_.CapacityMB/1024))}},@{n="FreeSpaceGB";e={[math]::round(($_.FreeSpaceMB/1024))}},@{n="FreeSpacePercent";e={[math]::round(($_.FreeSpaceMB/$_.CapacityMB*100))}} | Sort-Object FreeSpacePercent
$DSTLeastFree = $DSTInfo | Select-Object -first 1
$DSTMostFree  = $DSTInfo | Select-Object -last  1

# Get all the VMs on the datastore with the least free space.
$SourceVMsInitial = Get-VM -Datastore $DSTLeastFree.Name

# Remove any VMs that are in the exclusions text file.
$SourceVMsNotExcludeded = $SourceVMsInitial | ForEach-Object { 
	$vmtemp = $_.Name
	$match = $false
	Get-Content $ScriptDir\\StaticInfo\\sVMotion_Exclude.txt | ForEach-Object {
		If ($vmtemp -eq $_) { $match = $true }
	}
	If ($match -eq $false) { $vmtemp }
}

# Remove any VMs with more than 8GB of RAM (takes longer to svMotion, greater chance of failure).
$SourceVMs = $SourceVMsNotExcludeded | Where-Object { $_.MemoryMB -le 8192 } 

# Pick the VM
$SourceVMCount = ($SourceVMs | Measure-Object).Count
$SourceVMIndex = [math]::round($SourceVMCount/2)
$SourceVMToMove = $SourceVMs[$SourceVMIndex]

# Output reference info
Get-VM $SourceVMToMove | Format-Table -AutoSize
$DSTLeastFree          | Format-Table -AutoSize
$DSTMostFree           | Format-Table -AutoSize
Write-Output "`n $(Get-Date)- Moving $($SourceVMToMove) from $(($DSTLeastFree).Name) to $(($DSTMostFree).Name)`n"

# svMotion the VM
Move-VM -VM $SourceVMToMove -Datastore ($DSTMostFree).Name -Confirm:$false

Write-Output "`n$(Get-Date)- Script finished`n"

