function Compare-ADUserGroups
{
	#requires -pssnapin Quest.ActiveRoles.ADManagement
	param (
		[string] $FirstUser = $(Throw "SAMAccountName required."),
		[string] $SecondUser = $(Throw "SAMAccountName required.")
	)

	$a = (Get-QADUser $FirstUser).MemberOf
	$b = (Get-QADUser $SecondUser).MemberOf
	$c = Compare-Object -referenceObject $a -differenceObject $b
	$c
	
}
