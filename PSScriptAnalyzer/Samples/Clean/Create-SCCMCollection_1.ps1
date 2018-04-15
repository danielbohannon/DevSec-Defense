function Create-SCCMCollection
{
param($Server = $Env:ComputerName, $Name, $Site, $ParentCollectionID = "COLLROOT")

$ColClass = [WMIClass]"\\\\$Server\\Root\\SMS\\Site_$($Site):SMS_Collection"
$Col = $ColClass.PSBase.CreateInstance()
$Col.Name = $Name
$Col.OwnedByThisSite = $True
$Col.Comment = "Collection $Name"
$Col.psbase
$Col.psbase.Put()

$NewCollectionID = (Get-WmiObject -computerName $Server -namespace Root\\SMS\\Site_$Site -class SMS_Collection | where {$_.Name -eq $Name}).CollectionID
				
$RelClass = [WMIClass]"\\\\$Server\\Root\\SMS\\Site_$($Site):SMS_CollectToSubCollect"
$Rel = $RelClass.PSBase.CreateInstance()
$Rel.ParentCollectionID = $ParentCollectionID
$Rel.SubCollectionID = $NewCollectionID
$Rel.psbase
$Rel.psbase.Put()

}
