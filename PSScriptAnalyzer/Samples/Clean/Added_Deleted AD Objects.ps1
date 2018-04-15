#REQUIRES -pssnapin quest.activeroles.admanagement
#REQUIRES -pssnapin Pscx

begin {

# Build variables
$strSMTPServer = "192.168.251.144";
$strEmailFrom = "AD_Admin@hfinc.com";
$strEmailTo = "jdelatorre@hfinc.com";
$borders = "=" * 25;
[int]$days = -60

function TombStonedObjects {
	# create Directory Searcher object and set properties to search
	# for tombstoned objects

	$ds = New-Object System.DirectoryServices.DirectorySearcher
	$ds.Tombstone = $TRUE
	$ds.Filter = "isDeleted=TRUE"

	# Query for objects and filter for DN 
	$DSResults=$DS.FindAll() | select path

	# Build simple RegExp to get just Common Name
	$r=[regex]"(?<=CN=).+(?=\\\\)"
	$DSR2=$DSResults | % { $r.Matches($_);$script:delCount++}
	foreach ($DSobject in $DSR2) { $delMessage += "Deleted object: " + $DSobject.value.trim() + "`n" }
	
	$delMessage
	
	# end function
	}


function AddedComputersAndUsers {
# Query AD for Computer and users created in the last 'x' amount of days.
$ADObjects=Get-QADObject | ? {$_.type -match ("computer|user")} | ? {$_.whencreated -gt ((get-date).addDays($days))}

  if ($ADObjects) {
	foreach ($ADObject in $ADObjects) {
		switch ($ADObject.Type) {
			'user'	{
				$usrCount ++;
				$ADObject | fl * | Out-Null; #This is needed for some reason some objects are not returned without it 
				$usrMessage += "Display Name: " + $ADobject.displayname + "`n";
				$usrMessage += "SAMAccountName: " + $ADObject.get_LogonName() + "`n";
				$usrMessage += "Container: " + $ADObject.parentcontainer + "`n";
				$usrMessage += "When Created: " + $ADObject.whencreated + "`n";
				$usrMessage += "Principal Name: " + $ADObject.userPrincipalName + "`n";
				$usrMessage += "Groups: `n";
					# Build array of groups and populate $usrMessage variable
					$groups=$adobject.MemberOf
					foreach ($group in $groups) { $usrMessage += "$group `n"}
				$usrMessage += "`n";
				}				
			'computer' {
				$computerCount ++;
				$ADObject | fl * | Out-Null; #This is needed for some reason some objects are not returned without it 
				$compMessage += "DNS HostName: " + $ADObject.dnsname + "`n";
				$compMessage += "OperatingSystem: " + $ADObject.osName + "`n";
				$compMessage += "OS Service Pack: " + $ADObject.osservicepack + "`n";
				$compMessage += "Computer Role: " + $ADObject.computerrole + "`n";
				$compMessage += "When Created: " + $ADObject.whencreated + "`n";
				$compMessage += "Container: " + $ADObject.parentcontainer + "`n";
				$compMessage += "`n";
				}
			}
		}
	
	$deletedobjects = TombStonedObjects
	
	# Build emailBody with the Usermessage and ComputerMessage variables 
	$script:emailMessage = "AD User/Computer Objects created in the last " + [math]::abs($days) + " day(s).`n";
	if ($usrMessage) {$script:emailMessage += "$borders Users $borders`n" + $usrMessage;}
	if ($compMessage) {$script:emailMessage += "$borders Computers $borders`n" + $compMessage;}
	if ($deletedobjects) {$script:emailMessage += "$borders Deleted Objects for the last 60 days $borders `n" + $deletedobjects;}
	$script:emailSubject = "Users Added: " + $usrCount + ". Computers Added: " + $computerCount + ".  Objects Deleted: " + $script:delCount + ".";
	
	}
	
	else {
	# No users or computers found created in the last 'x' days.
	$deletedobjects = TombStonedObjects
	$script:emailSubject = "Users Added: " + $usrCount + ". Computers Added: " + $computerCount + ".  Objects Deleted: " + $script:delCount + ".";
	$script:emailMessage = "No Users or Computers have been added in the last " + [math]::abs($days) + " day(s). `n";
	if ($deletedobjects) {$script:emailMessage += "$borders Deleted Objects for the last 60 days $borders `n" + $deletedobjects;}
		}
	# end function
	}
# end Begin
}


process {


AddedComputersAndUsers
Send-SmtpMail -Subject $script:emailSubject -To $strEmailTo -From $strEmailFrom -SmtpHost $strSMTPServer -Body $script:emailMessage;

# end Process
}





