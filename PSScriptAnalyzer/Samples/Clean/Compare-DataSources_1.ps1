#Define DPMHosts
[CmdletBinding()]
param([string]$PrimaryDPMHost, [string]$SecondaryDPMHost);
Write-Verbose "Compare-DataSources.ps1 written by Shai Perednik shaiss@gmail.com"

Write-Verbose "Primary DPM Host: $PrimaryDPMHost"
Write-Verbose "Secondary DPM Host: $SecondaryDPMHost"

#Load DPM Snaping
Write-Verbose "Loading DPM PowerShell snapin"
Add-PSSnapin -name Microsoft.DataProtectionManager.PowerShell  -ErrorAction SilentlyContinue
Write-Verbose "Finished loading DPM PowerShell snapin"


#*=============================================================================
#* FUNCTION GetDataSourcesFromDPMHost
#*=============================================================================
# Function: GetDataSourcesFromDPMHost
# Created: [05/03/2012]
# Author: Shai Perednik shaiss@gmail.com http://shaiperednik.com
# Arguments:DPMHost
# Version: 0.0.1
# =============================================================================
# Purpose: Gets the DPM Hosts DataSources in a sorted array
#
#
# =============================================================================

Function GetDataSourcesFromDPMHost ($DPMHost){
	Write-Verbose "==========================================================================="
	Write-Verbose "Starting GetDataSourcesFromDPMHost Function on DPM Host: $DPMHost"
	Write-Verbose "==========================================================================="
	#Get the ProtectionGroups on the Primary
	Write-Verbose "Getting Protection Groups from $DPMHost"
	$PG = Get-Protectiongroup -DPMServerName $DPMHost | Sort-Object FriendlyName

	#Initialize the variable $DataSourceDetails 
	$DataSourceDetails = @()

	#Loop through the Protection Groups and Get the DataSources
	foreach ($pgitem in $PG) {
		Write-Verbose "Getting DataSources from $DPMHost"
		$DS = Get-Datasource -ProtectionGroup $pgitem | Sort-Object FriendlyName
		Write-Verbose "Checking individual datasource items and adding them to the array"
		#Check what kind of DataSource it is
		foreach ($dsitem in $DS) {
			#Write-Host $dsitem.Type.DatasourceType
			switch ($dsitem.Type.DatasourceType) {
				"Microsoft.Internal.EnterpriseStorage.Dls.UI.ObjectModel.SQL.SQLObjectType" {
					Write-Verbose "SQL DataSource: $dsitem.DisplayPath"
					$DataSourceDetails += $dsitem.DisplayPath
					break
				}
				"Microsoft.Internal.EnterpriseStorage.Dls.UI.ObjectModel.SystemProtection.SystemProtectionObjectType" {
					Write-Verbose "System State DataSource: $dsitem.ProductionServerName\\$dsitem.DataSourceName"
					$DataSourceDetails += $dsitem.ProductionServerName + "\\" + $dsitem.DataSourceName
					break
				}
				"Microsoft.Internal.EnterpriseStorage.Dls.UI.ObjectModel.FileSystem.FsObjectType" {
					Write-Verbose "Volume DataSource: $dsitem.ProductionServerName\\$dsitem.DataSourceName"
					$DataSourceDetails += $dsitem.ProductionServerName + "\\" + $dsitem.DataSourceName
					break
				}
				"Microsoft.Internal.EnterpriseStorage.Dls.UI.ObjectModel.FileSystem.FsDataSource" {
					Write-Verbose "Volume DataSource: $dsitem.ProductionServerName\\$dsitem.DataSourceName"
					$DataSourceDetails += $dsitem.ProductionServerName + "\\" + $dsitem.DataSourceName
					break
				}
				default {
					Write-Verbose "Other/Unknown DataSource: $dsitem"
					break
				}
			}
		}
	}
	#disconnect from DPMhost
	Write-Verbose "Disconnecting form $DPMHost"
	Disconnect-DPMServer -DPMServerName $DPMHost
	#Sort the Array
	Write-Verbose "Sorting the Array"
	[Array]::Sort([array]$DataSourceDetails)
	#Return a value
	return $DataSourceDetails
} 
#*=============================================================================
#* End of Function
#*=============================================================================


#*=============================================================================
#* SCRIPT BODY
#*=============================================================================
#Get the DataSources of the Primary and Secondary DPM hosts
Write-Verbose "Geting the datasources from the primary host $PrimaryDPMHost using GetDataSourcesFromDPMHost function"
$arPrimaryHost = GetDataSourcesFromDPMHost $PrimaryDPMHost
Write-Verbose "Geting the datasources from the Secondary host $SecondaryDPMHost using GetDataSourcesFromDPMHost function"
$arSecondaryHost = GetDataSourcesFromDPMHost $SecondaryDPMHost

#Now compare the two arrays
#Define container arrays
$PrimaryDataSourcesInSecondaryHost = @()
$PrimaryDataSourcesNotInSecondaryHost = @()
#do the work
Write-Verbose "Comparing the DataSources of the primary DPM host $PrimaryDPMHost againsnt the secodary $SecondaryDPMHost"
Foreach ($PrimaryHostItem in $arPrimaryHost)
{
If ($arSecondaryHost -contains $PrimaryHostItem){
	$PrimaryDataSourcesInSecondaryHost += $PrimaryHostItem
	}
	Else{
	$PrimaryDataSourcesNotInSecondaryHost += $PrimaryHostItem
	}
}
Write-Verbose "==============================================================================================="
Write-Verbose "Primary, $PrimaryDPMHost, DataSources in secondary host $SecondaryDPMHost"
Write-Verbose "==============================================================================================="
$strOutString = Out-String -InputObject $PrimaryDataSourcesInSecondaryHost
Write-Verbose $strOutString
Write-Verbose "==============================================================================================="

Write-Verbose "==============================================================================================="
Write-Verbose "Primary, $PrimaryDPMHost, DataSources ***NOT*** in secondary host $SecondaryDPMHost"
Write-Verbose "==============================================================================================="
$strOutString = Out-String -InputObject $PrimaryDataSourcesNotInSecondaryHost
Write-Verbose $strOutString
Write-Verbose "==============================================================================================="


#Write the Results to a file on c:\\temp\\logs
Write-Host "Writing the comparisons to log files under c:\\temp\\logs" 
New-Item -Path c:\\temp\\logs -ItemType directory -ErrorAction SilentlyContinue
$inpath = "c:\\temp\\logs\\" + $PrimaryDPMHost + "_DataSources_In_" + $SecondaryDPMHost + ".log"
$notinpath = "c:\\temp\\logs\\" + $PrimaryDPMHost + "_DataSources_Not_In_" + $SecondaryDPMHost + ".log"
Out-File -FilePath $inpath -InputObject $PrimaryDataSourcesInSecondaryHost
Write-Host "Wrote $inpath" -ForegroundColor Green -BackgroundColor Black
Out-File -FilePath $notinpath -InputObject $PrimaryDataSourcesNotInSecondaryHost
Write-Host "Wrote $notinpath" -ForegroundColor Green -BackgroundColor Black
Write-Verbose "Script finished"

#*=============================================================================
#* END OF SCRIPT:
#*=============================================================================
