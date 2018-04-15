###########################################################################"
#
# NAME: Add-NetworkPrinter.ps1
#
# AUTHOR: Jan Egil Ring
# EMAIL: jan.egil.ring@powershell.no
#
# COMMENT: Windows PowerShell script to map a network printer based on Active Directory group membership.
#          The get-GroupMembership function are created by Andy Grogan, see his blogpost for more information on this function:
#          http://www.telnetport25.com/component/content/article/15-powershell/127-quick-tip-determining-group-ad-membership-using-powershell.html
#          Also see this blogpost for more information:
#          http://blog.powershell.no/2009/11/28/mapping-printers-based-on-active-directory-group-membership-using-windows-powershell
#          Tested with Windows PowerShell v 1.0/2.0 and Windows XP/Vista/7.
#
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the creator, owner above has no warranty, obligations,
# or liability for such use.
#
# VERSION HISTORY:
# 1.0 28.11.2009 - Initial release
#
###########################################################################"

$strName = $env:username

function get-GroupMembership($DNName,$cGroup){
	
	$strFilter = "(&(objectCategory=User)(samAccountName=$strName))"

	$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
	$objSearcher.Filter = $strFilter

	$objPath = $objSearcher.FindOne()
	$objUser = $objPath.GetDirectoryEntry()
	$DN = $objUser.distinguishedName
		
	$strGrpFilter = "(&(objectCategory=group)(name=$cGroup))"
	$objGrpSearcher = New-Object System.DirectoryServices.DirectorySearcher
	$objGrpSearcher.Filter = $strGrpFilter
	
	$objGrpPath = $objGrpSearcher.FindOne()
	
	If (!($objGrpPath -eq $Null)){
		
		$objGrp = $objGrpPath.GetDirectoryEntry()
		
		$grpDN = $objGrp.distinguishedName
		$ADVal = [ADSI]"LDAP://$DN"
	
		if ($ADVal.memberOf.Value -eq $grpDN){
			$returnVal = 1
			return $returnVal = 1
		}else{
			$returnVal = 0
			return $returnVal = 0
	
		}
	
	}else{
			$returnVal = 0
			return $returnVal = 0
	
	}
		
}

$result = get-groupMembership $strName "Printer_group_01"
if ($result -eq '1') {
Invoke-Expression 'rundll32 printui.dll,PrintUIEntry /in /q /n"\\\\print-server\\printer-share"'
}
