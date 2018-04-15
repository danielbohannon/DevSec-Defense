#region vars
$statvalues=("mem.usage.average", "cpu.usage.average")
$nsca_stat = ""
[int]$warnlevel = 85
[int]$criticallevel = 90
$status = ""
$nagsrv = "nagios-srv.local"
#endregion

$vms = Get-VM | Where-Object { $_.PowerState -eq "PoweredOn" } | sort-object

foreach ($vm in $vms) {
	$statvalues | foreach {
		[int]$statavg = ($vm | Get-Stat -Stat $_ -Start ((get-date).AddMinutes(-5)) -MaxSamples 500 | Measure-Object -Property Value -Average).Average
		$vmdns = ($vm | Get-VMGuest).Hostname
		switch ($_) {
			"mem.usage.average" { $nsca_stat = "mem_vm"; $desc = "Memory Usage" }
			"cpu.usage.average" { $nsca_stat = "cpu_vm"; $desc = "CPU Usage" }
		}
		if ($statavg -gt $criticallevel) {
			$status = "2"
			$desc = "CRITICAL: " + $desc
		} elseif ($statavg -gt $warnlevel) {
			$status = "1"
			$desc = "WARNING: " + $desc
		} elseif ($statavg -lt $warnlevel) {
			$status = "0"
		}
		$nsca = "${vmdns};${nsca_stat};${status};${desc} ${statavg}% | ${nsca_stat}=${statavg};$warnlevel;$criticallevel;0;100"
		Write-Host $nsca
		if ($vmdns) { echo $nsca | ./send_nsca.exe -H $nagsrv -c send_nsca.cfg -d ";" }
	}
}
