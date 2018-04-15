Import-Module PowerBoots

# This simulates a download function, say Jaykul's Get-Webfile
# You can output current progress for a large file, or if it's an array of links then out put the current (index/length)%
# You will need to run the function as a background thread in order for it to not interfere with the UI thread (freezes UI) when called from event handler.
Function Start-FakeDownload {
	$global:job = Start-Job {
		foreach ($i in $(1..50)){
			sleep 0.7
			($i/50)*100
		}
	}
}

# GUI using boots. Registers controls as global variables.

$global:Window = Boots -Async -Passthru -Title "Progress Meter" {
	StackPanel  {
		ProgressBar -Height 25 -Width 250 -Name "Progress" | tee -var global:progress
		Button "Download" -Name "Download" | tee -var global:download
		Textblock | Tee -var global:status
	}
}

# Add event handler for the Download button.
# Runs Background job and updates Ui
$download.Add_Click({
	# Prevents download from being pressed while running ... causes overload with $timer.
	$download.IsEnabled = $false
	# Get background job out and updates controls with value
	$updateblock = {
		# If job is running, or just completed.
		# Notice the -Keep usage. Job result/output clears everytime you Receive-Job.
		# -Keep allows us to get the result from the background job multiple times and also serves as a marker to figure out when the job completes
		if($($job.State -eq "Running") -or $($($job.State -eq "Completed") -and $($(Receive-Job $job -Keep)[-1] -eq 100))){
			Invoke-BootsWindow $Window {
				$progress.Value = $(Receive-Job $job -Keep)[-1]
				$status.Text = "$($(Receive-Job $job)[-1])`% done"
			}
		}
		if($($job.State -eq "Completed") -and $($(Receive-Job $job) -eq $null)){
			Invoke-BootsWindow $Window {
				$status.Text = "Download Complete"
			}
			$timer.Stop()
			$download.IsEnabled = $true
		}
	}
	$timer = new-object System.Windows.Threading.DispatcherTimer
	$timer.Interval = [TimeSpan]"0:0:3"
	$timer.Add_Tick( $updateBlock )
	Start-FakeDownload 
	$timer.start()
})
