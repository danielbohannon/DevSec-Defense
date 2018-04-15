function copy-data {
	param($source, $dest)
	$counter = 0
	$files = Get-ChildItem $source -Force -Recurse
	foreach($file in $files)
		{
		$status = "Copying file {0} of {1}: {2}" -f $counter, $files.count, $file.name
		Write-Progress -Activity "Copyng Files" -Status $status -PercentComplete ($counter/$files.count * 100)
		Copy-Item $file.pspath $dest -Force
		$counter++
		}
}
