#######################################################################
# Convert-PowerPack2Ps1
# 
# Converts PowerGUI .PowerPack files to ps1 PowerShell script library
# v1 - raw conversion, no name changes, only script elements converted
######################################################################
# Example:
# & .\\Convert-PowerPack2Ps1 "ActiveDirectory.powerpack" "ActiveDirectory.ps1"
# . .\\ActiveDirectory.ps1
# Get-QADUser 'Dmitry Sotnikov' | MemberofRecursive
######################################################################
#
# (c) Dmitry Sotnikov
#  http://dmitrysotnikov.wordpress.com
#
#####################################################################
param(
	$PowerPackFile = (throw 'Please supply  path to source powerpack file'),
	$OutputFilePath = (throw 'Please supply  path to output ps1 file')
)

#region Functions

function IterateTree {
	# processes all script nodes
	param($segment)
	if ( $segment.Type -like 'Script*' ) {
		
		$name = $segment.name -replace ' |\\(|\\)', ''
		$code = $segment.script.PSBase.InnerText
		
@"

########################################################################
# Function: $name
# Return type: $($segment.returntype)
########################################################################
function $name {
$code
}
"@ | Out-File $OutputFilePath -Append		
		
	}
	# recurse folders
	if ($segment.items.container -ne $null) {
		$segment.items.container | ForEach-Object { IterateTree $_ }
	}
}


function Output-Link {
	PROCESS {
		if ( $_.script -ne $null ) { 
			$name = $_.name -replace ' |\\(|\\)', ''
			$code = $_.script.PSBase.InnerText

@"

########################################################################
# Function: $name
# Input type: $($_.type)
# Return type: $($_.returntype)
########################################################################
function $name {
$code
}
"@ | Out-File $OutputFilePath -Append		
		}
	}
}


#endregion


$sourcefile = Get-ChildItem $PowerPackFile
if ($sourcefile -eq $null) { throw 'File not found' }
	
@"
########################################################################
# Generated from: $PowerPackFile
#   by Convert-PowerPack2Ps1 script
#   on $(get-date)
########################################################################
"@ | Out-File $OutputFilePath

$pp = [XML] (Get-Content $sourcefile)

@"

# Scripts generated from script nodes
"@ | Out-File $OutputFilePath -Append
IterateTree $pp.configuration.items.container[0]

@"

# Scripts generated from script links
"@ | Out-File $OutputFilePath -Append

$pp.configuration.items.container[1].items.container | 
	where { $_.id -eq '481eccc0-43f8-47b8-9660-f100dff38e14' } | ForEach-Object {
		$_.items.item, $_.items.container | Output-Link
	}


@"

# Scripts generated from script actions
"@ | Out-File $OutputFilePath -Append

$pp.configuration.items.container[1].items.container | 
	where { $_.id -eq '7826b2ed-8ae4-4ad0-bf29-1ff0a25e0ece' } | ForEach-Object {
		$_.items.item, $_.items.container | Output-Link
	}
