### Written by Mark A. Weaver
##  Date: 7/27/2008
##  Version: 1.0
##  Blog site: blog.vmweaver.com
##
##  Call this function and pass in -ServerName <VC Server Name> -ClusterName <ClusterName>
##  Output should be an object containing the information
##
##  Feel free to modify as needed to suit your needs, but please keep this header
##  
##  Thanks  -- Mark


function Get-HACapacity(
[string]$ServerName, 
[string]$ClusterName)
{	
		if (($ServerName -ne "") -and ($ClusterName -ne ""))
	{
		# These booleans tell me if I am using the VMware default memory and cpu reservations for the cluster.
			$DASMemDefault = $True
			$DASCPUDefault = $True
					
		# The following numbers are derived from VMware published numbers for memory overhead.
		# I have dropped them into arrays using the number of vCPUs as an index to get the correct constant.
		# This is why you will notice only [1], [2], and [4] have non-zero values 
		# These constants are used later on when calculating Memory Reserve.
			$MemConst32 = 0, 3.262, 5.769059, 0, 6.77933
			$MemConst64 = 0, 3.2678, 5.79251, 0, 6.82622
			$MemBase32 = 0, 87.56, 108.73, 0, 146.75
			$MemBase64 = 0, 107.54, 146.41, 0, 219.82
									
		# Initialize some Variables
			$MaxMemRes = 0
			$MacNumCPU = 0
			$MaxCPUResVM = ""				
		$VMCount = 0
		
		# define default memory and cpu reservation	
			$DASMinMHz = 256
			$DASMinMemory = 256
		
			$viServerName = $ServerName
			$viClusterName = $ClusterName
											
		# Connect to the VirtualCenter Server and get some info
			$viServer = Connect-VIServer $viServerName
			$viCluster = get-cluster $viClusterName
			$viHosts = get-vmhost -location $viCluster					
			$viClusterV = get-view $viCluster.ID
												
		# Get the "Resources" Resource Pool from the cluster.  
		# This gives us the Reservation Pools for Memory and CPU
			$viResGroup = Get-ResourcePool -Name "Resources" -Location $viCluster
			$viCPURes = $viResGroup.CpuReservationMHz
			$viMemRes = $viResGroup.MemReservationMB									
			$viHostCount = $viClusterV.Summary.NumHosts
			
		# Get HA cluster configuration information
			$viHostFailures = $viClusterV.Configuration.DasConfig.FailoverLevel
				
		# Get a list of options that may be configured at the clusters level
		# We are looking for whether or not the default memory and cpu 
		#  reservations have been overridden 
			$viDASOptions = $viClusterV.Configuration.DASConfig.Option
			$viVMs = get-vm -Location $viCluster
				
		# Is Adminisssion Control enabled on the cluster?
			$viClusterControl = $viClusterV.Configuration.DASConfig.AdmissionControlEnabled	
														
		# See if das.vmMemoryMinMB key is defined and grab its value
		# See if das.vmCpuMinMHZ key is defined and grab its value
			if ($viDASoptions.Count -ne 0)
			{
				foreach ($viDASOption in $viDASOptions)
				{
					if ($viDASOption.Key -eq "das.vmMemoryMinMB")
					{
						$DASMemDefault = $False
					$DASMinMemory = $viDASOption.Value }
																																							
					if ($viDASOption.Key -eq "das.vmCpuMinMHz")
					{
						$DASCPUDefault = $False
					$DASMinMHz = $viDASOption.Value }							
				}
		}
		
		# Let's go through every VM and see what the maximum CPU and Memory reservation is.
		# We will also get a count of powered on VMs.
		# When we hit a maximum reservation, save the machine name that set that maximum
			foreach ($viVM in $viVMs)
			{
				$NumCPU = $viVm.NumCPU
				$VMMem = $viVm.MemoryMB
				$MemRes = 0
																					
				if ($viVM.PowerState -eq "PoweredOn")
				{
					$VMCount += 1
			}
						
			# Get the VM-view and determine if the current guest CPU or memory reservations configured
			$vmView = get-view $viVM.ID
			$vmViewCPURes = $vmView.ResourceConfig.CpuAllocation.Reservation
			$vmViewMemRes = $vmView.ResourceConfig.MemoryAllocation.Reservation
						
			# If no reservations are set at the VM level, calculate the memory reservation.		
			if ($vmViewMemRes -eq 0)
			{
				if ($VMMem -le 256)
				{
					$MemRes = $MemConst64[$NumCpu] + $MemBase64[$NumCPU]
				}
				else
				{
					if ((($viVM.Guest.OSFullName | Select-String "64-bit").Matches.Count) -ge 1)
					{
						$MemRes = ($VMMem / 256) * $MemConst64[$NumCPU] + $MemBase64[$NumCPU]
					}
					else
					{
						$MemRes = ($VMMem / 256) * $MemConst32[$NumCPU] + $MemBase32[$NumCPU]
					}
				}
																															
				$MemRes += $DASMinMemory
			}																						
			else
			{
				$MemRes = $vmViewMemRes 									
																
			}
						
			#Figure out if the current VM holds the highest reservation so far
			
				if ($vmViewCPURes -gt $DASMinMHz) 
				{ 
					$DASMinMHz = $vmViewCPURes 
					$MaxCPUResVM = $viVM.Name
				}			
			
				if ($MemRes -gt $MaxMemRes)
				{
					$MaxMemRes = $MemRes
					$MaxMemResVM = $viVM.Name
				}
																											
				if ($NumCPU -gt $MaxNumCPU)
				{
					$MaxNumCPU = $NumCPU
					$MaxCPUNumVM = $viVM.Name
				}
																														
			}
						
						
			if ($MaxCPUResVM -eq "") { $MaxCPUResVM = $MaxCPUNumVM }			
			
			
		$MaxCPURes = $MaxNumCPU * $DASMinMHz
				
		# Calculate the VM Capacity for the cluster based on memory and cpu reservations.
			$ClusterVMCapacityMEM = [Math]::Truncate(((($viMemRes / $MaxMemRes) * ( $viHostCount - $viHostFailures )) / $viHostCount))
			$ClusterVMCapacityCPU = [Math]::Truncate(((($viCPURes / $MaxCPURes) * ( $viHostCount - $viHostFailures )) / $viHostCount))
												
			if ($ClusterVMCapacityMEM -lt $ClusterVMCapacityCPU)
			{
				$ClusterVMCapacity = $ClusterVMCapacityMEM				
			}
			else
			{
				$ClusterVMCapacity = $ClusterVMCapacityCPU			
		}
				
		
		# Create an object to return											
			$CPUObj = New-Object System.Object
			$CPUObj | Add-Member -type NoteProperty -name ClusterCPURes -value $viCPURes
			$CPUObj | Add-Member -type NoteProperty -name DefaultCPURes -value $DASCPUDefault
			$CPUObj | Add-Member -type NoteProperty -name MinCPURes -value $DASMinMHz
		   $CPUObj | Add-Member -type NoteProperty -name MaxCPUNumVM -value $MaxCPUNumVM
			$CPUObj | Add-Member -type NoteProperty -name MaxCPURes -value $MaxCPURes
			$CPUObj | Add-Member -type NoteProperty -name MaxCPUResVM -value $MaxCPUResVM
			$CPUObj | Add-Member -type NoteProperty -name MaxCPUs -value $MaxNumCPU
			$CPUObj | Add-Member -type NoteProperty -name VMCapacityCPU -value $ClusterVMCapacityCPU
									
			$MemObj = New-Object System.Object
			$MemObj | Add-Member -type NoteProperty -name ClusterMemRes -value $viMemRes
			$MemObj | Add-Member -type NoteProperty -name DefaultMemRes -value $DASMemDefault
			$MemObj | Add-Member -type NoteProperty -name MinMemRes -value $DASMinMemory
			$MemObj | Add-Member -type NoteProperty -name MaxMemRes -value $MaxMemRes
			$MemObj | Add-Member -type NoteProperty -name MaxMemResVM -value $MaxMemResVM
			$MemObj | Add-Member -type NoteProperty -name VMCapacityMem -value $ClusterVMCapacityMEM
											
			$OutObj = New-Object System.Object
			$OutObj | Add-Member -type NoteProperty -name AdmissionControl -value $viClusterControl
			$OutObj | Add-Member -type NoteProperty -name CPU -value $CPUObj
			$OutObj | Add-Member -type NoteProperty -name FailoverHosts -value $viHostFailures
			$OutObj | Add-Member -type NoteProperty -name HostCount -value $viHostCount
			$OutObj | Add-Member -type NoteProperty -name Memory -value $MemObj
			$OutObj | Add-Member -type NoteProperty -name RunningVMs -value $VMCount
			$OutObj | Add-Member -type NoteProperty -name VIServer -value $viServerName
			$OutObj | Add-Member -type NoteProperty -name VICluster -value $viClusterName
			$OutObj | Add-Member -type NoteProperty -name VMCapacity -value $ClusterVMCapacity	
										
			return($outObj)					
	}
	else
	{  	
		# Write usage info
		Write-Host ("")
		Write-Host ("-------------------------------------")
		Write-Host ("Get-HACapacity.ps1 Usage:")
		Write-Host( "You must specify the following parameters: ")
		Write-Host ("     '-ServerName <servername>'  where <servername> is the name of the VirtualCenter Server")
		Write-Host("     '-ClusterName <clustername>'  where <clustername> is the name of the cluster to query")
		Write-Host ("")
		}
}
