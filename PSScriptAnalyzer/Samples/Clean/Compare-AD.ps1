###############################################################################
# Compare-AD - a set of functions (and sample code using them) to create 
# snapshots of user accounts in the current Active Directory domain
# save them in an xml file, and then compare live AD environment
# against that XML
#
# (C) Dmitry Sotnikov
# http://dmitrysotnikov.wordpress.com/2008/10/14/compare-ad-against-snapshotscompare-ad-against-snapshots
# 
###############################################################################

# Requires QAD cmdlets
if ((Get-PSSnapin "Quest.ActiveRoles.ADManagement" `
			-ErrorAction SilentlyContinue) -eq $null) {
	Add-PSSnapin "Quest.ActiveRoles.ADManagement"
}


###############################################################################
# Functions
###############################################################################

# Retrives all AD users from the current domain and stores the selected 
# set of properties (passed as an array of strings in the $properties parameter)
# as an xml file by the path passed as $path
# See sample use below
function New-Snapshot {
    param($path, $properties)
    Get-QADUser -SizeLimit 0 -DontUseDefaultIncludedProperties `
		-IncludedProperties $properties | 
			Select $properties | Export-Clixml $path
}

# Load the snapshot and compare it against current AD domain
function Compare-ActiveDirectory {
    param($path, $properties)
	
	# $old is the snapshot, $new is the current environment data
    $old = Import-Clixml $path
    $new = Get-QADUser -SizeLimit 0 -DontUseDefaultIncludedProperties `
		-IncludedProperties $properties | 
        	Select $properties

	# First lets report the ones which got created or deleted
    $diff = Compare-Object $old $new -Property Name
    $created = , ($diff | where { $_.SideIndicator -eq "=>" })
    $deleted = , ($diff | where { $_.SideIndicator -eq "<=" })
    
    if ( $created.Count -gt 0 ) {
        "New accounts:"
        $created | Format-Table Name
    }
    
    if ( $deleted.Count -gt 0 ) {
        "Deleted accounts:"
        $deleted | Format-Table Name
    }
    
    # Now let's load the accounts in a hash-table so it is easier to locate them
    $hash = @{}
    $new | ForEach-Object { $hash[$_.DistinguishedName] = $_ }
    
	# Let's enumerate the accounts and their properties and report any changes
    "Modified objects:"
    foreach ( $snapshot in $old ) {
        $current = $hash[$snapshot.DistinguishedName]
        if ( $current -and 
            ($current.ModificationDate -ne $snapshot.ModificationDate )) {
@"

Object $($snapshot.distinguishedname)
Modified at $($current.ModificationDate)
                
Property`tOld Value`tNew Value
========`t=========`t=========
"@
			foreach ($property in $properties) {
				if ( ($property -ne "ModificationDate") -and 
					($snapshot.$property -ne $current.$property )) {
				"$property`t$($snapshot.$property)`t$($current.$property)"
				}
			}
		}
    }
}

###############################################################################
# Common parameters
###############################################################################

# These are the properties to be compared
# Make sure they include Name, DistinguishedName, and ModificationDate
# Remove the TS attributes if your system requirements for retrieving those
# are not met: 
# http://dmitrysotnikov.wordpress.com/2008/07/23/system-requirements-for-powershell-terminal-services-management/
$Members_to_Compare = @( "Name", "DistinguishedName", "ModificationDate", 
    "AccountIsDisabled", "AccountIsLockedOut", "AccountName", 
    "CanonicalName", "City", "Company", "Department", "Description", 
    "DisplayName", "Email", "Fax",
    "FirstName", "HomeDirectory", "HomeDrive", "HomePhone", "Initials", 
    "LastName", "LdapDisplayName", "LogonName", "LogonScript", "Manager", 
    "MobilePhone", "Notes", "Office", "Pager", 
    "ParentContainerDN", "PasswordNeverExpires", 
    "PhoneNumber", "PostalCode", "PostOfficeBox", "ProfilePath", 
    "SamAccountName", "StateOrProvince", "StreetAddress", "Title", 
    "TsAllowLogon", "TsBrokenConnectionAction", "TsConnectClientDrives", 
    "TsConnectPrinterDrives", "TsDefaultToMainPrinter", "TsHomeDirectory", 
    "TsHomeDrive", "TsInitialProgram", "TsMaxConnectionTime", 
    "TsMaxDisconnectionTime", "TsMaxIdleTime", "TsProfilePath", 
    "TsReconnectionAction", "TsRemoteControl", "TsWorkDirectory", 
    "UserPrincipalName", "WebPage" )

# Path to the snapshot file
$SnapshotPath = "c:\\snapshot.xml"

###############################################################################
# Sample usage
###############################################################################

# Create a snapshot
New-Snapshot -Path $SnapshotPath -Properties $Members_to_Compare

# Make some changes
New-QADUser -Name "Lawrence Alford"  -ParentContainer mydomain.local/test
Set-QADUser "Jennifer Clarke" -PhoneNumber "(249) 111-22-33"
Set-QADUser "Ernest Cantrell" -City "San Francisco"
Remove-QADObject "Andreas Bold"  -Force

# Let's see if we find them
Compare-ActiveDirectory -Path $SnapshotPath -Properties $Members_to_Compare

