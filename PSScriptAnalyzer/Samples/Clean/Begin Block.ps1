Begin { 
	#VMware VM Host (ESX) UUID
	$VMHost_UUID = @{ 
        Name = "VMHost_UUID" 
        Expression = { $_.Summary.Hardware.Uuid } 
    }
	#XenServer Host UUID
	$XenHost_UUID = @{
		Name = "XenHost_UUID"
		Expression = { $_.Uuid }
	} 
}
