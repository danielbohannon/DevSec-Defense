
## Check-ClusterPatches.ps1

param($ClusterNode=$Env:ComputerName)

$Patches = @{}
$PatchList = $Null
$PatchListComplete = $Null
$Results = @()

Write-Host "Getting Nodes via WMI..." -foregroundcolor Green
$Nodes = Get-WmiObject -computerName $ClusterNode -namespace ROOT\\MSCluster -class MSCluster_Node | Select Name | foreach {$_.Name}


foreach ( $Node in $Nodes )
{
    Write-Host "Getting the Patches on:" $Node -foregroundcolor Green
    
    $Patchlist = Get-WmiObject -computerName $Node -namespace ROOT\\CimV2 -class Win32_QuickFixEngineering | select HotFixID
	
	foreach ($Patch in $PatchList)
		{
			[array]$PatchListComplete = $PatchListComplete + $Patch.HotFixID
		}
    
    Write-Host "Adding Patches to Hashtable For:" $Node -foregroundcolor Green 
    foreach($Patch in $PatchListComplete)
    {
        # Check to see if the Patch is in the hashtable, if not, add it.
		if(!$Patches.$Patch)
        {
            $Patches.Add($Patch,"Added")
        }
    }
}

Write-Host "Comparing Patch Levels across Cluster Nodes...This can take several minutes..." -foregroundcolor Yellow
foreach ($Patch in $Patches.Keys)
	{
		$PatchObj = New-Object System.Object
		
		$PatchObj | Add-Member -memberType NoteProperty -name HotFixID -Value $Patch
		
		foreach ($Node in $Nodes)
			{
				if (Get-WmiObject -computerName $Node -namespace ROOT\\CimV2 -class Win32_QuickFixEngineering | Where-Object {$_.HotFixID -eq $Patch})
					{
						$PatchObj | Add-Member -memberType NoteProperty -name $Node -value "Installed"
					}
				else
					{
						$PatchObj | Add-Member -memberType NoteProperty -name $Node -value "Missing"
					}
			}
			
		$Results += $PatchObj
	}

Write-Host "Displaying Results..." -foregroundcolor Green
""
foreach ($Result in $Results)
	{
		$Match = $true
		
		$Servers = $Result | Get-Member -memberType NoteProperty | Where-Object {$_.Name -ne "HotFixID"} | foreach {$_.Name}
		
		foreach($Server in $Servers)
			{
				foreach($Srv in $Servers)
				{
					if($Srv -ne $Server)
					{
						# If the the value is different we set $Match to $false
						if($Result."$Srv" -ne $Result."$Server"){$Match = $false}
					}
				}
			}
			
		$Result | add-Member -MemberType NoteProperty -Name Match -value $Match
		
		$Result
	}
	
