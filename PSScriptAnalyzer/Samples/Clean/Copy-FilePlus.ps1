<#
.SYNOPSIS
	Copies a file from one location to another while displaying a GUI progress window.
.PARAMETER Path
	Specifies the filename or FileInfo object representing file to be copied.  Right now, this must be fully-qualified, relative paths will produce an error.  Try it with Get-Item or Get-ChildItem, this works great.
.PARAMETER Destination
	Specifies the filename including path for resulting copy operation.
.EXAMPLE
	PS > Copy-FilePlus -Path c:\\tmp\\windows7.iso -Destination e:\\tmp\\windows7.iso
.EXAMPLE
	PS > Get-Item c:\\tmp\\windows7.iso | Copy-FilePlus -Destination e:\\tmp\\windows7.iso
#>
#requires -version 2
param (
	[Parameter(
		Mandatory = $true, 
		ValueFromPipeline = $true
	)]$Path,
	[Parameter(Mandatory=$true)]
	[string]
	$Destination
)
try {
	add-type -a microsoft.visualbasic
	[Microsoft.VisualBasic.FileIO.FileSystem]::CopyFile(
		$Path,
		$Destination,
		[Microsoft.VisualBasic.FileIO.UIOption]::AllDialogs,
		[Microsoft.VisualBasic.FileIO.UICancelOption]::ThrowException
	)
} catch { $_ }


