$vmlist = Import-Csv toolboxesx.csv

#vsphere settings
$vsphere_server = ""
$cluster_name = ""

#dvSwitch Names to connect each side to
$prod_net = ""
$aux_net = ""

#Networks to temporarally add the vmxnet3 nics to before connecting to dvSwitch
$prod_temp_net = ""
$aux_temp_net = ""

#Folder to add VM's to
$folder_id = ""

#Script Start
$vsphere = Connect-VIServer $vsphere_server
$cluster = Get-Cluster $cluster_name
$datacenter = Get-Datacenter -cluster $cluster
$folder = Get-Folder -Id $folder_id

foreach($vm in $vmlist) {
	$vmhost = $cluster | Get-VMHost | Sort-Object -Property MemoryUsageMB | Where-Object {$_.State -eq "Connected"}
	if ($vmhost.length -gt 1) { $vmhost = $vmhost[0] }
	$datastore = $vmhost | Get-Datastore  | Sort-Object -Property FreeSpaceMB -desc | Where-Object {$_.CapacityMB -gt 100000} | Where-Object {$_.FreeSpaceMB -gt 30000} #using 100gb as threshold for local storage vs san storage and not adding to any datastore with less than 30gb free space
	if ($datastore.length -gt 1) { $datastore = $datastore[0] }
	$vmdisk =[Math]::Round([Int32]::Parse($vm.Disk)*1024)
	$esx = $vmhost | Get-View
	Write-Host Finding Prod/Aux Switches on $vmhost
	foreach($netMoRef in $esx.Network){
		if($netMoRef.Type -eq "DistributedVirtualPortGroup"){
			$net = Get-View -Id $netMoRef
			if($net.Name -eq  $prod_net){
				$prod_PGKey  = $net.MoRef.Value
				$prod_Uuid = (Get-View -Id $net.Config.DistributedVirtualSwitch).Summary.Uuid
			}
			if($net.Name -eq  $aux_net){
				$aux_PGKey  = $net.MoRef.Value
				$aux_Uuid = (Get-View -Id $net.Config.DistributedVirtualSwitch).Summary.Uuid
			}
		}
	}
	Write-Host Creating $vm.Name on host $vmhost
	New-VM -Debug -name $vm.Name -vmhost $vmhost -Location $folder -DiskStorageFormat thick -NumCpu 2 -DiskMB $vmdisk -memoryMB $vm.Memory -Datastore $datastore.Name -GuestID $vm.OS -Description $vm.Description
	$adapter = Get-NetworkAdapter -VM $vm.Name
	Remove-NetworkAdapter -NetworkAdapter $adapter -confirm:$false
	$vm = Get-VM $vm.Name
	New-NetworkAdapter -VM $vm -NetworkName $prod_temp_net -Type "vmxnet3" -StartConnected
	New-NetworkAdapter -VM $vm -NetworkName $aux_temp_net -Type "vmxnet3" -StartConnected
	$view = $vm | Get-View
	$vmConfigSpec = New-Object VMware.Vim.VirtualMachineConfigSpec
	foreach($tempdev  in $view.Config.Hardware.Device){
		if($tempdev.DeviceInfo.Label -eq "Network adapter 1"){
			Write-Host "Connecting VM to Prod Switch $prod_net"
			$devSpec = New-Object VMware.Vim.VirtualDeviceConfigSpec
			$dev = New-Object ("VMware.Vim."  + $tempdev.GetType().Name)
			$dev.deviceInfo = New-Object VMware.Vim.Description
			$dev.deviceInfo.label = $tempdev.DeviceInfo.Label
			$dev.deviceInfo.summary = $tempdev.DeviceInfo.Summary
			$dev.Backing = New-Object VMware.Vim.VirtualEthernetCardDistributedVirtualPortBackingInfo
			$dev.Backing.Port = New-Object VMware.Vim.DistributedVirtualSwitchPortConnection
			$dev.Backing.Port.PortgroupKey = $prod_PGKey
			$dev.Backing.Port.SwitchUuid = $prod_Uuid
			$dev.Key = $tempdev.Key
			$devSpec.Device = $dev
			$devSpec.Operation = "edit"
			$vmConfigSpec.deviceChange += $devSpec
		}
        if($tempdev.DeviceInfo.Label -eq "Network adapter 2"){
			Write-Host "Connecting VM to Aux Switch $aux_net"
			$devSpec = New-Object VMware.Vim.VirtualDeviceConfigSpec
			$dev = New-Object ("VMware.Vim."  + $tempdev.GetType().Name)
			$dev.deviceInfo = New-Object VMware.Vim.Description
			$dev.deviceInfo.label = $tempdev.DeviceInfo.Label
			$dev.deviceInfo.summary = $tempdev.DeviceInfo.Summary
			$dev.Backing = New-Object VMware.Vim.VirtualEthernetCardDistributedVirtualPortBackingInfo
			$dev.Backing.Port = New-Object VMware.Vim.DistributedVirtualSwitchPortConnection
			$dev.Backing.Port.PortgroupKey = $aux_PGKey
			$dev.Backing.Port.SwitchUuid = $aux_Uuid
			$dev.Key = $tempdev.Key
			$devSpec.Device = $dev
			$devSpec.Operation = "edit"
			$vmConfigSpec.deviceChange += $devSpec
		}
	}
    Write-Host "Reconfiguring VM"
    foreach($v in $view){
                    $v.ReconfigVM($vmConfigSpec)
    }
    $vm | Start-VM -Confirm:$false
    Write-Host $vm.Name "Done"
}
