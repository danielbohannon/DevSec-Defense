function New-DatastoreByLun { param( [string]$vmHost, [string]$hbaId, [int]$targetId, [int]$lunId, [string]$dataStoreName )

  $view = Get-VMHost $vmHost | get-view

  $lun = $view.Config.StorageDevice.ScsiTopology | ForEach-Object { $_.Adapter } | Where-Object {$_.Key -match $hbaId} | ForEach-Object {$_.Target} | Where-Object {$_.Target -eq $targetId} | ForEach-Object {$_.Lun} | Where-Object {$_.Lun -eq $lunId}

  $scsiLun = Get-VMHost $vmHost | Get-ScsiLun | Where-Object {$_.Key -eq $lun.ScsiLun}

  New-Datastore -VMHost $vmHost -Name $dataStoreName -Path $scsiLun.CanonicalName -Vmfs -BlockSizeMB 8 -FileSystemVersion 3
}


