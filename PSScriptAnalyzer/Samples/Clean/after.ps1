Get-WmiObject -Class Win32_MountPoint | 
where {$_.Directory -like ‘Win32_Directory.Name="D:\\\\MDBDATA*"’} | 
foreach {
    $vol = $_.Volume
    Get-WmiObject -Class Win32_Volume | where {$_.__RELPATH -eq $vol} | 
    Select @{Name="Folder"; Expression={$_.Caption}}, 
    @{Name="Server"; Expression={$_.SystemName}},
    @{Name="Size (GB)"; Expression={"{0:F3}" -f $($_.Capacity / 1GB)}},
    @{Name="Free (GB)"; Expression={"{0:F3}" -f $($_.FreeSpace / 1GB)}},
    @{Name="%Free"; Expression={"{0:F2}" -f $(($_.FreeSpace/$_.Capacity)*100)}}
} 
