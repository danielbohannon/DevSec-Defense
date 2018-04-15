function get-binary($number,$words=1+(1*[int]($number -gt 255))) {
	# Takes the passed numerical value and converts to a Binary word.
	# Pads 0 to the left to make it a proper set of 8 or 16
	#
	# If you use this function outside of the clock, it is automatically
	# designed to generate a 16 bit output padded if the value is greater
	# than 255
	
	return [convert]::tostring($number,2).padleft(8*$words,"0")
}
Clear-Host
Do {
	# Get the Current Date/Time
	$Current=GET-DATE
	
	#Build a String with the Hours, Minutes and Seconds in Binary
	$output=(Get-Binary $current.hour)+":"+(get-binary $Current.minute)+":"+(Get-Binary $Current.Second)
	
	# Remember our location
	$location=$Host.UI.RawUI.CursorPosition
	
	# Send output to the screen
	Write-Host $output
	
	# The Position back
	$Host.UI.RawUI.CursorPosition=$location
	
	# Take a nap for a second
	Start-sleep 1
} until ($FALSE) # Do it over and over and over since $FALSE will never be $TRUE

