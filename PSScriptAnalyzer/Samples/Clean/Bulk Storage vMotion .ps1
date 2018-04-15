#========================================================================
# Created on:   5/31/2012 4:31 PM
# Created by:   Clint Jones
# Organization: Virtually Genius!
# Filename:     StorageVMotion-BulkVMs
#========================================================================

#Import Plugins and Connect to vCenter
Add-PSSnapin VMware.VimAutomation.Core
$creds = Get-Credential
$viserver = Read-Host "vCenter Server:"
Connect-VIServer -Server $viserver -Credential $creds

#Load information from the selected cluster
$cluster = Read-Host "What cluster do you want to migrate:"
$destdata1 = Read-Host "Destination datastore #1:"
$destdata2 = Read-Host "Destination datastore #2:"
$vms = Get-Cluster -Name $cluster | Get-VM

#Stoage vMotion each VM in selected cluster in a staged fashion
foreach($vm in $vms)
{
	#Ensure that the storage is balanced as it was before the transfer
	$currentdata = Get-VM -Name $vm.Name | Get-Datastore
	$currentdata = $currentdata.Name
	if ($currentdata.EndsWith("a") -eq "True")
	{$destdata = $destdata1}
	else
	{$destdata = $destdata2}
	#Storage vMotion to the datastore of choice and wait to start next transfer
	$task = Get-VM -Name $vm.Name | Move-VM -Datastore (Get-Datastore -Name $destdata)
	Wait-Task -Task $task
}
