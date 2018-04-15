function Run-DosCommand($program, [string[]]$programArgs)
{
	write-host "Running command: $program";
	write-host " Args:"
	0..($programArgs.Count-1) | foreach { Write-Host "  $($programArgs[$_])" }
	& $program $programArgs
}

#Get-FullPath function defined elsewhere, refers to a "base directory" which allows me to make
#all path references RELATIVE to this base directory. Feel free to hardcode the path instead.
$wspbuilder = Get-FullPath("tools\\WSPBuilder.exe")
function Run-WspBuilder($rootDirectory)
{
	pushd
	cd $rootDirectory
	Run-DosCommand -program $WSPBuilder -programArgs @("-BuildWSP", 
		"true", 
		"-OutputPath", 
		(Get-FullPath 'deployment'), 
		"-ExcludePaths",
		(Join-Path -path (Get-FirstDirectoryUnderneathSrc).fullname -childPath "bin\\Debug"))
	popd
}


