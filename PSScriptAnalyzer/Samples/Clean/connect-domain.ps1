function connect-domain_X {
		BEGIN {$foregroundcolor= (get-host).ui.rawui.get_foregroundcolor()
			Write-Host "";
					"---------------------------------" ;
					"Entering Nested Prompt for Quest connection to DOMAIN_X."; 
					"Type `"Exit`" when finished.";
					"---------------------------------" ;
					""
					
			(get-host).ui.rawui.set_foregroundcolor("magenta")
			$pw = Read-Host "Enter your DOMAIN_X password" -AsSecureString
					}
		PROCESS {connect-QADService -service 'domaincontroller' -ConnectionAccount 'domain_x\\username' -ConnectionPassword $pw
			$host.enternestedprompt()
		}
		END {
			(get-host).ui.rawui.set_foregroundcolor($foregroundcolor)
		}
	}
