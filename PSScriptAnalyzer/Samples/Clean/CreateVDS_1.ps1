function CreateVDS(
   $vdsName, $datacenter, $vmHost, $physicalNic, $portGroupType = "earlyBinding", `
   [array]$portGroupNameList = @(),[array]$uplinkList = @() ) {
   
   # ------- Create vDS ------- #

   $vdsCreateSpec = New-Object VMware.Vim.DVSCreateSpec
   $vdsCreateSpec.configSpec = New-Object VMware.Vim.DVSConfigSpec
   $vdsCreateSpec.configSpec.name = $vdsName
   $vdsCreateSpec.configSpec.uplinkPortPolicy = 
      New-Object VMware.Vim.DVSNameArrayUplinkPortPolicy
   if ($uplinkList.Count -eq 0) {
      $vdsCreateSpec.configSpec.uplinkPortPolicy.uplinkPortName = 
         New-Object System.String[] (2)
      $vdsCreateSpec.configSpec.uplinkPortPolicy.uplinkPortName[0] = "dvUplink1"
      $vdsCreateSpec.configSpec.uplinkPortPolicy.uplinkPortName[1] = "dvUplink2"
   } else {
      $vdsCreateSpec.configSpec.uplinkPortPolicy.uplinkPortName = 
         New-Object System.String[] ($uplinkList.Count)
      for ($i = 0; $i -lt $uplinkList.Count; $i++){
         $vdsCreateSpec.configSpec.uplinkPortPolicy.uplinkPortName[$i] = 
            $uplinkList[$i]
      }
   }
   
   $hostIdValue = ($vmHost.Id.Split('-', 2))[1]

   $vdsCreateSpec.configSpec.host = 
      New-Object VMware.Vim.DistributedVirtualSwitchHostMemberConfigSpec[] (1)
   $vdsCreateSpec.configSpec.host[0] = 
      New-Object VMware.Vim.DistributedVirtualSwitchHostMemberConfigSpec
   $vdsCreateSpec.configSpec.host[0].operation = "add"
   $vdsCreateSpec.configSpec.host[0].host = 
      New-Object VMware.Vim.ManagedObjectReference
   $vdsCreateSpec.configSpec.host[0].host.type = "HostSystem"
   $vdsCreateSpec.configSpec.host[0].host.value = $hostIdValue
   $vdsCreateSpec.configSpec.host[0].backing = 
      New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicBacking

   $vdsCreateSpec.configSpec.host[0].backing = 
      New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicBacking
   $vdsCreateSpec.configSpec.host[0].backing.pnicSpec = 
      New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec[] (1)
   $vdsCreateSpec.configSpec.host[0].backing.pnicSpec[0] = 
      New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec
   $vdsCreateSpec.configSpec.host[0].backing.pnicSpec[0].pnicDevice = 
      $physicalNic.DeviceName

   $networkFolderView = Get-View -Id (($datacenter | Get-View).NetworkFolder)
   

   $dvsMoRef = $networkFolderView.CreateDVS($vdsCreateSpec)

   # ------- Add vDPortGroup ------- #
   
   if ($portGroupNameList.Count -eq 0){
      $portGroupNameList += "dvPortGroup"
   }

   $vdProtGroupSpec = 
      New-Object VMware.Vim.DVPortgroupConfigSpec[] ($portGroupNameList.Length)
   for ($i = 0; $i -lt $portGroupNameList.Length; $i++){
      $vdProtGroupSpec[$i] = New-Object VMware.Vim.DVPortgroupConfigSpec
      $vdProtGroupSpec[$i].name = $portGroupNameList[$i]
      $vdProtGroupSpec[$i].numPorts = 128
      $vdProtGroupSpec[$i].defaultPortConfig = 
         New-Object VMware.Vim.VMwareDVSPortSetting
      $vdProtGroupSpec[$i].defaultPortConfig.vlan = 
         New-Object VMware.Vim.VmwareDistributedVirtualSwitchVlanIdSpec
      $vdProtGroupSpec[$i].defaultPortConfig.vlan.inherited = $false
      $vdProtGroupSpec[$i].defaultPortConfig.vlan.vlanId = 0
      $vdProtGroupSpec[$i].type = $portGroupType
   }

   $vdsView = Get-View -Id $vdsMoRef.ToString()

   $vdsView.AddDVPortgroup($vdProtGroupSpec)

   return $vdsMoRef
}

