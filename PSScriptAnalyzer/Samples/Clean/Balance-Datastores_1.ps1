<# TODO
-Change number of DSTs to is selection of $DSTMostFree to be variable.  Also add in logic to select DSTs with lower VMCounts.
Total DSTs   Select DSTs
----------   -----------
   <5            1
   5-20          3
   >20           5
   
-For $DSTLeastFree add in logic to select DSTs with higher VMCounts.
#>

#Parameter- Name of the VMware cluster to work in
param($Cluster,$Action)

Write-Output "`n$(Get-Date)- Script started"

# Validate parameter input
If ( ($Action -ne "Move") -and ($Action -ne "Report") )  {
	Write-Output "$(Get-Date)- Valid values for the parameter ""Action"" are either ""Move"" or ""Report"""
	Write-Output "$(Get-Date)- Script aborted`n"
	break
}

$IsClusterNameInvalid = $true
Get-Cluster | % { If ($_.Name -eq $Cluster) {$IsClusterNameInvalid = $false} }
If ($IsClusterNameInvalid) {
	Write-Host "Error- Invalid Cluster Name" -Background Yellow -Foreground Red
	Write-Host "Valid cluster names for this Virtual Center server."
	Write-Host "---------------------------------------------------"
	Get-Cluster | Sort
	Write-Output "$(Get-Date)- Script aborted`n"
	break
}

# Prep
$ScriptDir = "\\\\vmscripthost201\\repo"
. $ScriptDir\\Get-mDataStoreList.ps1
If ($Cluster -match "Prod") { $DatastoreNumVMsLimit = 15 } Else { $DatastoreNumVMsLimit = 20 }
$FreeSpacePercentMoveThreshold = 25

# Get the list of valid datastores and pick the one with the least free space.
$DSTs = Get-mDataStoreList $Cluster
$DSTInfoAll = $DSTs | Select-Object Name,@{n="CapacityGB";e={[int](($_.CapacityMB/1024))}},@{n="FreeSpaceGB";e={[int](($_.FreeSpaceMB/1024))}},@{n="FreeSpacePercent";e={[int](($_.FreeSpaceMB/$_.CapacityMB*100))}},@{n="ProvisionedGB";e={[int](($_.ExtensionData.Summary.Capacity - $_.ExtensionData.Summary.Freespace + $_.ExtensionData.Summary.Uncommitted)/1024/1024/1024)}},@{n="ProvisionedPercent";e={[int](($_.ExtensionData.Summary.Capacity - $_.ExtensionData.Summary.Freespace + $_.ExtensionData.Summary.Uncommitted)/$_.ExtensionData.Summary.Capacity*100)}},@{n="VMCount";e={(Get-VM -Datastore $_ | Measure-Object).Count}}

If     ($DSTInfoAll | Where-Object { $_.FreeSpacePercent -lt $FreeSpacePercentMoveThreshold } ) 
	{ $DSTInfoLeastCandidates = $DSTInfoAll | Where-Object { $_.FreeSpacePercent -lt 25 } }
ElseIf ($DSTInfoAll | Where-Object { $_.VMCount -gt $DatastoreNumVMsLimit } ) 
	{ $DSTInfoLeastCandidates = $DSTInfoAll | Where-Object { $_.VMCount -gt $DatastoreNumVMsLimit } }
Else   
	{ $DSTInfoLeastCandidates = $DSTInfoAll }

$DSTLeastFree = $DSTInfoLeastCandidates | Sort-Object FreespacePercent | Select-Object  -First 3 | Sort-Object ProvisionedPercent | Select-Object -Last 1
$DSTMostFree  = $DSTInfoAll | Where-Object { $_.VMCount -lt $DatastoreNumVMsLimit } | Sort FreeSpacePercent | Select-Object -Last 3 | Sort-Object ProvisionedPercent | Select-Object -First 1

  #$DSTInfo | ft -a
  #$DSTLeastFree | ft -a
  #$DSTMostFree | ft -a

# Get all the VMs on the datastore with the least free space and having less than 16GB of RAM.  VMs with high RAM are more likely to fail svMotion.
# $SourceVMsInitial = Get-VM -Datastore $DSTLeastFree.Name | Where-Object { $_.MemoryMB -le 16384 } | Sort-Object UsedSpaceGB
# cjm 110719- Removing the above restriction to 16GB VMs or lower because there are too many with more than that.
$SourceVMsInitial = Get-VM -Datastore $DSTLeastFree.Name | Sort-Object UsedSpaceGB

# Remove any VMs that are in the exclusions text file.
$SourceVMsNotExcludeded = $SourceVMsInitial | ForEach-Object { 
	$vmtemp = $_.Name
	$match = $false
	Get-Content $ScriptDir\\StaticInfo\\sVMotion_ExcludeList.txt | ForEach-Object {
		If ($vmtemp -eq $_) { $match = $true }
	}
	If ($match -eq $false) { $vmtemp }
}

# 
$SourceVMs = $SourceVMsNotExcludeded | Where-Object { $_.MemoryMB -le 32768 } 

# Pick the VM
$SourceVMCount = ($SourceVMs | Measure-Object).Count
$SourceVMIndex = [int]($SourceVMCount/2)
$SourceVMToMove = $SourceVMs[$SourceVMIndex]

If ($Action -eq "Report" ) { Write-Output "+++++++ Reporting only +++++++" }

$DSTLeastFree | Format-Table -AutoSize
$DSTMostFree | Format-Table -AutoSize
Get-VM $SourceVMToMove | Select Name,PowerState,VMHost,ResourcePool,NumCpu,MemoryMB,@{n="ProvisionedSpaceGB";e={[int]($_.ProvisionedSpaceGB)}},@{n="UsedSpaceGB";e={[int]($_.UsedSpaceGB)}} | Format-Table -AutoSize

If ($Action -eq "Move" ) {
	# svMotion the VM
	Write-Output "$(Get-Date)- *** Moving $($SourceVMToMove) from $(($DSTLeastFree).Name) to $(($DSTMostFree).Name)"
	Move-VM -VM $SourceVMToMove -Datastore ($DSTMostFree).Name -Confirm:$false | Format-Table -AutoSize
}

Write-Output "$(Get-Date)- Script finished`n"

