foreach ($i in 10..1) {
	Set-VMHostAdvancedConfiguration -name Annotations.WelcomeMessage -value "This host will self destruct in $i"
}
Start-Sleep 10
Set-VMHostAdvancedConfiguration -name Annotations.WelcomeMessage -value ""

