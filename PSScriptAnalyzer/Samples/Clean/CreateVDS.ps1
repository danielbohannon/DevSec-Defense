function CreateVDS(
   $dvsName, $datacenter, $vmHost, $physicalNic, $portGroupType = "earlyBinding", `
   [array]$portGroupNameList = @(),[array]$uplinkList = @() ) {
   
   # ------- Create vDS ------- #

   $dvsCreateSpec = New-Object VMware.Vim.DVSCreateSpec
   $dvsCreateSpec.configSpec = New-Object VMware.Vim.DVSConfigSpec
   $dvsCreateSpec.configSpec.name = $dvsName
   $dvsCreateSpec.configSpec.uplinkPortPolicy = 
      New-Object VMware.Vim.DVSNameArrayUplinkPortPolicy
   if ($uplinkList.Count -eq 0) {
      $dvsCreateSpec.configSpec.uplinkPortPolicy.uplinkPortName = 
         New-Object System.String[] (2)
      $dvsCreateSpec.configSpec.uplinkPortPolicy.uplinkPortName[0] = "dvUplink1"
      $dvsCreateSpec.configSpec.uplinkPortPolicy.uplinkPortName[1] = "dvUplink2"
   } else {
      $dvsCreateSpec.configSpec.uplinkPortPolicy.uplinkPortName = 
         New-Object System.String[] ($uplinkList.Count)
      for ($i = 0; $i -lt $uplinkList.Count; $i++){
         $dvsCreateSpec.configSpec.uplinkPortPolicy.uplinkPortName[$i] = 
            $uplinkList[$i]
      }
   }
   
   $hostIdValue = ($vmHost.Id.Split('-', 2))[1]

   $dvsCreateSpec.configSpec.host = 
      New-Object VMware.Vim.DistributedVirtualSwitchHostMemberConfigSpec[] (1)
   $dvsCreateSpec.configSpec.host[0] = 
      New-Object VMware.Vim.DistributedVirtualSwitchHostMemberConfigSpec
   $dvsCreateSpec.configSpec.host[0].operation = "add"
   $dvsCreateSpec.configSpec.host[0].host = 
      New-Object VMware.Vim.ManagedObjectReference
   $dvsCreateSpec.configSpec.host[0].host.type = "HostSystem"
   $dvsCreateSpec.configSpec.host[0].host.value = $hostIdValue
   $dvsCreateSpec.configSpec.host[0].backing = 
      New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicBacking

   $dvsCreateSpec.configSpec.host[0].backing = 
      New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicBacking
   $dvsCreateSpec.configSpec.host[0].backing.pnicSpec = 
      New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec[] (1)
   $dvsCreateSpec.configSpec.host[0].backing.pnicSpec[0] = 
      New-Object VMware.Vim.DistributedVirtualSwitchHostMemberPnicSpec
   $dvsCreateSpec.configSpec.host[0].backing.pnicSpec[0].pnicDevice = 
      $physicalNic.DeviceName

   $networkFolderView = Get-View -Id (($datacenter | Get-View).NetworkFolder)
   

   $dvsMoRef = $networkFolderView.CreateDVS($dvsCreateSpec)

   # ------- Add vDPortGroup ------- #
   
   if ($portGroupNameList.Count -eq 0){
      $portGroupNameList += "dvPortGroup"
   }

   $dvProtGroupSpec = 
      New-Object VMware.Vim.DVPortgroupConfigSpec[] ($portGroupNameList.Length)
   for ($i = 0; $i -lt $portGroupNameList.Length; $i++){
      $dvProtGroupSpec[$i] = New-Object VMware.Vim.DVPortgroupConfigSpec
      $dvProtGroupSpec[$i].name = $portGroupNameList[$i]
      $dvProtGroupSpec[$i].numPorts = 128
      $dvProtGroupSpec[$i].defaultPortConfig = 
         New-Object VMware.Vim.VMwareDVSPortSetting
      $dvProtGroupSpec[$i].defaultPortConfig.vlan = 
         New-Object VMware.Vim.VmwareDistributedVirtualSwitchVlanIdSpec
      $dvProtGroupSpec[$i].defaultPortConfig.vlan.inherited = $false
      $dvProtGroupSpec[$i].defaultPortConfig.vlan.vlanId = 0
      $dvProtGroupSpec[$i].type = $portGroupType
   }

   $dvsView = Get-View -Id $dvsMoRef.ToString()

   $dvsView.AddDVPortgroup($dvProtGroupSpec)

   return $dvsMoRef
}
