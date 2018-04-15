##Purpose: Search Active Directory for all users, add them to specific groups based on homemta value, remove disabled users from same groups, and export all users to excel. 

##Requires Excel 2003 or 2007 be installed on the local machine for exporting.
##Requires Quest ActiveRoles Management Shell for Active Directory
##http://www.quest.com/powershell/activeroles-server.aspx

##Helpful tool: ADSIEDIT.MSC
##Use it to find the values for most of these Active Directory variables.
##For the example values, I used the values presented in this link:
##http://technet.microsoft.com/en-us/library/bb125087(EXCHG.65).aspx


Add-PSSnapin Quest.ActiveRoles.ADManagement

$strRootLDAP = 'contoso.com/Users'

##$strServerx = the homeMTA value in AD for your users.
$strServer1 = "CN=Microsoft MTA,CN=Exchange1,CN=Servers,CN=AG1,CN=Administrative Groups,CN=Organization,CN=Microsoft Exchange,CN=Services,CN=Configuration,DC=contoso,DC=com"
$strServer2 = "CN=Microsoft MTA,CN=Exchange2,CN=Servers,CN=AG1,CN=Administrative Groups,CN=Organization,CN=Microsoft Exchange,CN=Services,CN=Configuration,DC=contoso,DC=com"

##$strGroupNamex = the name of the group you want your users to be added to based on their mail server. 
$strGroupName1 = "Exchange1 Users"
$strGroupName2 = "Exchange2 Users"

##$objGroupx = the distinguished name of the groups above.
$strGroupDN1 = "CN=Exchange1 Users,OU=Groups,DC=contoso,DC=com"
$strGroupDN2 = "CN=Exchange2 Users,OU=Groups,DC=contoso,DC=com"

##$strServerx = the homeMDB value in AD for your users.
$strServer1DB1SG1 = "CN=DB1,CN=SG1,CN=InformationStore,CN=Exchange1,CN=Servers,CN=AG1,CN=Administrative Groups,CN=Organization,CN=Microsoft Exchange,CN=Services,CN=Configuration,DC=contoso,DC=com"
$strServer1DB1SG2 = "CN=DB1,CN=SG2,CN=InformationStore,CN=Exchange1,CN=Servers,CN=AG1,CN=Administrative Groups,CN=Organization,CN=Microsoft Exchange,CN=Services,CN=Configuration,DC=contoso,DC=com"
$strServer1DB2SG1 = "CN=DB2,CN=SG1,CN=InformationStore,CN=Exchange1,CN=Servers,CN=AG1,CN=Administrative Groups,CN=Organization,CN=Microsoft Exchange,CN=Services,CN=Configuration,DC=contoso,DC=com"
$strServer1DB2SG2 = "CN=DB2,CN=SG2,CN=InformationStore,CN=Exchange1,CN=Servers,CN=AG1,CN=Administrative Groups,CN=Organization,CN=Microsoft Exchange,CN=Services,CN=Configuration,DC=contoso,DC=com"

$strServer2DB1SG1 = "CN=DB1,CN=SG1,CN=InformationStore,CN=Exchange2,CN=Servers,CN=AG1,CN=Administrative Groups,CN=Organization,CN=Microsoft Exchange,CN=Services,CN=Configuration,DC=contoso,DC=com"
$strServer2DB1SG2 = "CN=DB1,CN=SG2,CN=InformationStore,CN=Exchange2,CN=Servers,CN=AG1,CN=Administrative Groups,CN=Organization,CN=Microsoft Exchange,CN=Services,CN=Configuration,DC=contoso,DC=com"
$strServer2DB2SG1 = "CN=DB2,CN=SG1,CN=InformationStore,CN=Exchange2,CN=Servers,CN=AG1,CN=Administrative Groups,CN=Organization,CN=Microsoft Exchange,CN=Services,CN=Configuration,DC=contoso,DC=com"
$strServer2DB2SG2 = "CN=DB2,CN=SG2,CN=InformationStore,CN=Exchange2,CN=Servers,CN=AG1,CN=Administrative Groups,CN=Organization,CN=Microsoft Exchange,CN=Services,CN=Configuration,DC=contoso,DC=com"

function ScanEnabledUsers ($colEnabledUserResults)
	{
	$rowcounter = 1
	$intTotal = $colEnabledUserResults.Count
	foreach ($colEnabledUserResult in $colEnabledUserResults)
		{
		$strName = $colEnabledUserResult.name
		$strDN = $colEnabledUserResult.distinguishedname
		$strMTA = $colEnabledUserResult.homemta
		switch  ($strMTA)
			{
			$strServer1	
				{
				Write-Host "$rowcounter of $intTotal : Exchange1 : $strName"
				add-QADGroupMember -Identity $strGroupDN1 -Member "$strDN" 
				foreach ($strMemberof in $colEnabledUserResult.memberof) {
					switch  ($strMemberOf)
						{
						$strGroupDN2 
							{
							Write-Host -ForegroundColor Red "Removing from Exchange2: $strName"
							Remove-QADGroupMember -Identity $strGroupDN2 -Member $strDN
							}
						}
					}
				}
			$strServer2 {
				Write-Host "$rowcounter of $intTotal : Exchange2 : $strName"
				add-QADGroupMember -Identity $strGroupDN2 -Member "$strDN" 
				foreach ($strMemberof in $colEnabledUserResult.memberof) {
					switch  ($strMemberOf){
						$strGroupDN1 
							{
							Write-Host -ForegroundColor Red "Removing from Exchange1: $strName"
							Remove-QADGroupMember -Identity $strGroupDN1 -Member $strDN
							}
						}
					}
				}
			}
		$rowcounter++
		}
	}

function ScanDisabledUsers ($colDisabledUserResults)
	{
	## Now to remove any "disabled" users from these groups.
	Write-Host "Checking all disabled User accounts and removing them from distribution groups."
	$rowcounter = 1
	$intTotal = $colDisabledUserResults.Count
	foreach ($colDisabledUserResult in $colDisabledUserResults)
		{
		#$objItem = $objResult.Properties; 
		#$strDN = $objItem.distinguishedname
		$strDN = $colDisabledUserResult.distinguishedname
		$strName = $colDisabledUserResult.Name
		Write-Host $rowcounter of $intTotal : $strName
		foreach ($strMemberOf in $colDisabledUserResult.memberof)
			{
			switch  ($strMemberOf)
				{
				$strGroupDN1 
					{
					Write-Host -ForegroundColor Red "Removing from Exchange1: $strName"
					Remove-QADGroupMember -Identity $strGroupDN1 -Member $strDN
					}
				$strGroupDN2 
					{
					Write-Host -ForegroundColor Red "Removing from Exchange2: $strName"
					Remove-QADGroupMember -Identity $strGroupDN2 -Member $strDN
					}
				}
			}
		$rowcounter++
    	}
	}

function ExportGroupToExcel ($strRootLDAP)
{
Write-Host Exporting Users to Excel...
$colExcelUserResults = $colEnabledUserResults + $colDisabledUserResults
$intEnabledCount = [int]$colEnabledUserResults.Count
Write-Host Enabled Count:  $intEnabledCount
$intDisabledCount = [int]$colDisabledUserResults.Count
Write-Host Disabled Count: $intDisabledCount
$intTotalCount = [int]$colExcelUserResults.Count
Write-Host Total Count:    $intTotalCount
##$rowcounter needs to be set to two in order to leave a line for the header row.
$rowcounter = 2
$ws.Cells.Item(1,1) = "Name"
$ws.Cells.Item(1,2) = "Logon Name"
$ws.Cells.Item(1,3) = "CAC ID Number"
$ws.Cells.Item(1,4) = "Exch Server"
$ws.Cells.Item(1,5) = "Exch DB & SG"
$ws.Cells.Item(1,6) = "Logon Count"
$ws.Cells.Item(1,7) = "Dis/Enabled"
$ws.Cells.Item(1,8) = "Exchange Server DistinguishedName LONG"
$ws.Cells.Item(1,9) = "Exchange Database and Storage Group LONG"
foreach ($colQADUserResult in $colExcelUserResults) 
    {
	##I'm using write-progress here just to learn how to use it.
	$intComplete = ($rowcounter/$intTotalCount)*100
	write-progress "Export to Excel in Progress" "Complete % : " -PercentComplete $intComplete
    $ws.Cells.Item("$rowcounter",1) = $colQADUserResult.name
    $ws.Cells.Item("$rowcounter",2) = $colQADUserResult.samaccountname
	$ws.Cells.Item("$rowcounter",3) = $colQADUserResult.employeeid
	$strMTA = $colQADUserResult.homemta
    switch ($strMTA) {
        $strServer1 {$ws.Cells.Item("$rowcounter",4) = "Exchange1"}
        $strServer2 {$ws.Cells.Item("$rowcounter",4) = "Exchange2"}
        }
	$strMDB = $colQADUserResult.homemdb
    switch ($strMDB) {
        $strServer1DB1SG1 {$ws.Cells.Item("$rowcounter",5) = "DB1 SG1"}
        $strServer1DB1SG2 {$ws.Cells.Item("$rowcounter",5) = "DB1 SG2"}
        $strServer1DB2SG1 {$ws.Cells.Item("$rowcounter",5) = "DB2 SG1"}
        $strServer1DB2SG2 {$ws.Cells.Item("$rowcounter",5) = "DB2 SG2"}
        
        $strServer2DB1SG1 {$ws.Cells.Item("$rowcounter",5) = "DB1 SG1"}
        $strServer2DB1SG2 {$ws.Cells.Item("$rowcounter",5) = "DB1 SG2"}
        $strServer2DB2SG1 {$ws.Cells.Item("$rowcounter",5) = "DB2 SG1"}
        $strServer2DB2SG2 {$ws.Cells.Item("$rowcounter",5) = "DB2 SG2"}
        }
	$ws.Cells.Item("$rowcounter",6) = $colQADUserResult.logoncount
	if (($rowcounter - 1) -le [int]$colEnabledUserResults.Count) 
		{$ws.Cells.Item("$rowcounter",7) = "Enabled"}
	else 
		{$ws.Cells.Item("$rowcounter",7) = "Disabled"}
	##I still record the raw $strMTA and $strMDB in Excel here because I found the exchange team 
	##creating mailboxes on the bridgehead server. This helps spot the oddballs when sorting.
	$ws.Cells.Item("$rowcounter",8) = $strMTA
    $ws.Cells.Item("$rowcounter",9) = $strMDB
    $rowcounter++
    }
}

Write-Host 'Searching for all "Enabled" User accounts in $strRootLDAP'
$colEnabledUserResults = Get-QADUser -Enabled -SearchRoot $strRootLDAP -SizeLimit 0 -DontUseDefaultIncludedProperties -IncludedProperties 'memberof','name','distinguishedname','employeeid','samaccountname','homemta','homemdb','logoncount'
Write-Host 'Searching for all "Disabled" User accounts in $strRootLDAP'
$colDisabledUserResults = Get-QADUser -Disabled -SearchRoot $strRootLDAP -SizeLimit 0 -DontUseDefaultIncludedProperties -IncludedProperties 'memberof','name','distinguishedname','employeeid','samaccountname','homemta','homemdb','logoncount'

ScanEnabledUsers ($colEnabledUserResults)
ScanDisabledUsers ($colDisabledUserResults)

$a = New-Object -comobject Excel.Application
$b = $a.Workbooks.Add()
$ws = $b.Worksheets.Item(1)
$ws.Name = "Users"
$a.Visible = $True

ExportGroupToExcel ($strRootLDAP)

