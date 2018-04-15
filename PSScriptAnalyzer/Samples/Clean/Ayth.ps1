# ========================================================================
# 
# Microsoft PowerShell Source File -- Created with PowerShell Plus Professional
# 
# NAME: Disable-MassMailPF.ps1
# 
# AUTHOR: Darrin Henshaw , Ignition IT Canada Ltd.
# DATE  : 8/13/2008
# 
# COMMENT: Used to disable mail on an imported list of public folders.
# 
# ========================================================================
# param($csv = $Args[0])
# 
# # Import the list of the public folders to the variable $pflist
# $pflist = Import-Csv -path $csv
# 
# # Loop through allt he public folder names in the variable we created above.
# foreach ($pf in $pflist)
# 
# # For all of them, we get their properties and examine as to whether they are mail enabled already. If they are we disable the mail on them.
# {Get-PublicFolder -identity $pf.Identity |Where-Object {$_.MailEnabled -eq "True"}|Disable-MailPublicFolder -confirm:$false -Server hfxignvmexpf1}
# 
# # Line of code used for testing just outs to the commandline the value of our imported property.
# # {Out-Host -inputObject $pf.Identity -paging}

param($csv = $Args[0]) 
$Preference = $ConfirmPreference 
$ConfirmPreference = 'none' 

# Import the list of the public folders to the variable $pflist 
$pflist = Import-Csv -path $csv 

# Loop through allt he public folder names in the variable we created above. 
foreach ($pf in $pflist) 

# For all of them, we get their properties and examine as to whether they are mail enabled already. If they are we disable the mail on them. 
{Get-PublicFolder -identity $pf.Identity |Where-Object {$_.MailEnabled -eq $true}|Disable-MailPublicFolder -Server hfxignvmexpf1} 
$ConfirmPreference = $Preference 
