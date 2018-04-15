function Convert-MacAddress {
<#
	.SYNOPSIS
		Converts a MAC address from one valid format to another.

	.DESCRIPTION
		The Convert-MacAddress function takes a valid hex MAC address and converts it to another valid hex format.
		Valid formats include the colon, dash, and dot delimiters as well as a raw address with no delimiter.

	.PARAMETER MacAddress
		Specifies the MAC address to be converted.

	.PARAMETER Delimiter
		Specifies a valid MAC address delimiting character. The format specified by the delimiter determines the conversion of the input string.
		Default value: ':'

	.EXAMPLE
		Convert-MacAddress 012345abcdef
		Converts the MAC address '012345abcdef' to '01:23:45:ab:cd:ef'.

	.EXAMPLE
		Convert-MacAddress 0123.45ab.cdef
		Converts the MAC address '0123.45ab.cdef' to '01:23:45:ab:cd:ef'.
		
	.EXAMPLE
		Convert-MacAddress 01:23:45:ab:cd:ef -Delimiter .
		Converts the MAC address '01:23:45:ab:cd:ef' to '0123.45ab.cdef'.

	.EXAMPLE
		Convert-MacAddress 01:23:45:ab:cd:ef -Delimiter ""
		Converts the dotted MAC address '01:23:45:ab:cd:ef' to '012345abcdef'.

	.INPUTS
		Sysetm.String

	.OUTPUTS
		System.String

	.NOTES
		Name: Convert-MacAddress
		Author: Rich Kusak
		Created: 2011-08-28
		LastEdit: 2011-08-29 10:02
		Version: 1.0.0.0

	.LINK
		http://en.wikipedia.org/wiki/MAC_address
	
	.LINK
		about_regular_expressions

#>

	[CmdletBinding()]
	param (
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateScript({
			$patterns = @(
				'^([0-9a-f]{2}:){5}([0-9a-f]{2})$'
				'^([0-9a-f]{2}-){5}([0-9a-f]{2})$'
				'^([0-9a-f]{4}.){2}([0-9a-f]{4})$'
				'^([0-9a-f]{12})$'
			)
			if ($_ -match ($patterns -join '|')) {$true} else {
				throw "The argument '$_' does not match a valid MAC address format."
			}
		})]
		[string]$MacAddress,
		
		[Parameter(ValueFromPipelineByPropertyName=$true)]
		[ValidateSet(':', '-', '.', $null)]
		[string]$Delimiter = ':'
	)
	
	process {

		$rawAddress = $MacAddress -replace '\\W'
		
		switch ($Delimiter) {
			{$_ -match ':|-'} {
				for ($i = 2 ; $i -le 14 ; $i += 3) {
					$result = $rawAddress = $rawAddress.Insert($i, $_)
				}
				break
			}

			'.' {
				for ($i = 4 ; $i -le 9 ; $i += 5) {
					$result = $rawAddress = $rawAddress.Insert($i, $_)
				}
				break
			}
			
			default {
				$result = $rawAddress
			}
		} # switch
		
		$result
	} # process
} # function Convert-MacAddress

