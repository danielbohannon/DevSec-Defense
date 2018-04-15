$SystemEnclosure = Get-WMIObject -Class Win32_SystemEnclosure; $Type = $SystemEnclosure.ChassisTypes; CLS ; Write-Host -BackgroundColor White -ForegroundColor Blue "Chassis Type:"
	if ($Type -eq 1)
		{Write-Host "$Type - Other"}
	elseif ($Type -eq 2)
		{Write-Host "$Type - Virtual Machine"}
	elseif ($Type -eq 3)
		{Write-Host "$Type - Desktop"}
	elseif ($Type -eq 4)
		{Write-Host "$Type - Low Profile Desktop"}
	elseif ($Type -eq 5)
		{Write-Host "$Type - Pizza Box"}
	elseif ($Type -eq 6)
		{Write-Host "$Type - Mini Tower"}
	elseif ($Type -eq 7)
		{Write-Host "$Type - Tower"}
	elseif ($Type -eq 8)
		{Write-Host "$Type - Portable"}
	elseif ($Type -eq 9)
		{Write-Host "$Type - Laptop"}
	elseif ($Type -eq 10)
		{Write-Host "$Type - Notebook"}
	elseif ($Type -eq 11)
		{Write-Host "$Type - Handheld"}
	elseif ($Type -eq 12)
		{Write-Host "$Type - Docking Station"}
	elseif ($Type -eq 13)
		{Write-Host "$Type - All-in-One"}
	elseif ($Type -eq 14)
		{Write-Host "$Type - Sub-Notebook"}
	elseif ($Type -eq 15)
		{Write-Host "$Type - Space Saving"}
	elseif ($Type -eq 16)
		{Write-Host "$Type - Lunch Box"}
	elseif ($Type -eq 17)
		{Write-Host "$Type - Main System Chassis"}
	elseif ($Type -eq 18)
		{Write-Host "$Type - Expansion Chassis"}
	elseif ($Type -eq 19)
		{Write-Host "$Type - Sub-Chassis"}
	elseif ($Type -eq 20)
		{Write-Host "$Type - Bus Expansion Chassis"}
	elseif ($Type -eq 21)
		{Write-Host "$Type - Peripheral Chassis"}
	elseif ($Type -eq 22)
		{Write-Host "$Type - Storage Chassis"}
	elseif ($Type -eq 23)
		{Write-Host "$Type - Rack Mount Chassis"}
	elseif ($Type -eq 24)
		{Write-Host "$Type - Sealed-Case PC"}
	else
		{Write-Host "$Type - Unknown"}
