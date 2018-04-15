function prompt {
  $mapped_drives =    Get-WmiObject Win32_LogicalDisk -Filter "drivetype=4" | foreach {echo $_.deviceid}
  $local_drives =     Get-WmiObject Win32_LogicalDisk -Filter "drivetype=3" | foreach {echo $_.deviceid}
  $removable_drives = Get-WmiObject Win32_LogicalDisk -Filter "drivetype=2" | foreach {echo $_.deviceid}
  $t = $(get-date -format "HH:mm:ss")
  $a = (get-location).path
  $d = (get-location).path.substring(0,$a.indexof(":")+1)
  $a = $a.substring($a.LastIndexOf("`\\")+1)
  if ((get-location).path.substring(0,(get-location).path.indexof(":")) -eq "Microsoft.PowerShell.Core\\FileSystem") {
    $a = (get-location).path
	$a = $a.substring($a.indexof(":")+2)
    write-host -fore white -back blue "$t - $a ";"`$`> "}
  else {
    if ($a -eq "") {$a = "`\\"}
    if ($d.length -gt 2) {
      write-host -ForegroundColor black -backgroundcolor red "[$t] - [$d] $a ";"`$`> "}
	elseif ($local_drives -contains "$d") {
      write-host -ForegroundColor black -backgroundcolor green "[$t] - [$d] $a ";"`$`> "}
	elseif ($removable_drives -contains "$d") {
      write-host -ForegroundColor black -backgroundcolor yellow "[$t] - [$d] $a ";"`$`> "}
	elseif ($mapped_drives -contains "$d") {
	  write-host -ForegroundColor black -backgroundcolor magenta "[$t] - [$d] $a ";"`$`> "}
  }
}
