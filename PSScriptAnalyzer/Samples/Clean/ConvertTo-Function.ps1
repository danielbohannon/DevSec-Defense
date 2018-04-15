## ConvertTo-Function
## By Steven Murawski (http://www.mindofroot.com / http://blog.usepowershell.com)
###################################################################################################
## Usage:
## ./ConvertTo-Function Get-Server.ps1 
## dir *.ps1 | ./convertto-Function
###################################################################################################
param ($filename)

PROCESS
{
	if ($_ -ne $Null)
	{
		$filename = $_
	}
	
	if ($filename -is [System.IO.FileInfo])
	{
		$filename = $filename.Name
	}
	
	if (Test-Path $filename) 
	{	
		
		$name = (Resolve-Path $filename | Split-Path -Leaf) -replace '\\.ps1'	
		
		$scriptblock = get-content $filename | Out-String
		
		if (Test-Path function:global:$name)
		{
			Set-Item -Path function:global:$name -Value $scriptblock 
			Get-Item -Path function:global:$name
		}
		else
		{
			New-Item -Path function:global:$name -Value $scriptblock
		}
	}
	else 
	{
		throw 'Either a valid path or a FileInfo object'
	}
}
