# ---------------------------------------------------------------------------
### <Script>
### <Author>Ted Wagner</Author>
### <Version='2.4'>
### <Script Name='Create-ADTestLabContent.ps1'>
### <Derived From='Dmitry Sotnikov - http://dmitrysotnikov.wordpress.com/2007/12/14/setting-demo-ad-environments/'>
### <Description>
### This script design uses the original script (base script) written by Dmitry Sotnikov.  The script's
### original comments are included below.  I am referring to Dmitry's script as "version 1.0"
### 
### My goal is to standardize variables, functions and libraries such that the script is portable.  
### This is so that I can place all files for PowerShell on an ISO file and re-use the content 
### with as little modification as possible from test scenario to test scenario.
###
### My scripts folder is a directory copied from the ISO file.  When I build a virtual environment, 
### I bring up a completely configured and empty AD domain.  I then attach the ISO to the VM and 
### copy the "scripts" folder to the root of C:.  I then drop in a default profile.ps1 into the 
### WindowsPowerShell directory (the default All Users profile) and run this script.
### 
### There is more work, yet to do; I want to "pare down" the functions so that the functions could be added to
### a functions.ps1 "library" file.
### 
### The labs I set up for testing use an OU structure similar to the following:
###
### OU=DeptName	-
###		|- Computers
###		|- Groups
###		|- Users
### 
### The profile.ps1 sets up the PSDrive and then creates a variable to the provider.  The profile.ps1
### script is in the root of the scripts directoy which is copied from the ISO file.
###
### Contents of the profile.ps1 file:
###
### New-PSDrive -name ScriptLib -psProvider FileSystem -root "C:\\Scripts"
### $ScriptLib = 'ScriptLib:'
### 
### The Scripts folder contains a subfolder named "LabSetup".  The LabSetup folder contains this script,
### titled "Create-ADTestLabContent.ps1" and all of the text files necessary for creating the user 
### objects, OU's, etc.  You can create your own files and/or edit this script to match your file names.
### I've listed the contents of each file below.
###
### I deviated from the original text files from Dmitry's script.
### My goal was to have a "true" list of random names by utilizing the "select-random" written by
### Joel Bennett.  This can be downloaded from poshcode.org.  I found that the combination of the
### select-ramdom on the census files and parsing the extra data was extremely time consuming.
### I went to the census.org page for year 2000 and downloaded the top 1000 names spreadsheet.
### Then, I simply stripped off ALL of the extra data (first row and all columns after column A)
### and saved it as an ascii file called "surnames.txt".  The link to that page is:
### http://www.census.gov/genealogy/www/data/2000surnames/index.html
###
### Additionally, I did something similar with the first names.
### I downloaded common male and female names from http://infochimps.org/collections/moby-project-word-lists
### Those files are named fgivennames.txt and mgivennames.txt.  You can alternately download a text file
### of 21,000+ common given names from the same site instead of using the surnames from census.gov.
### However, for my testing, a sample of 1000 last names was sufficient for my needs.
###
### departments.txt - Name of each Department which will be both an OU, group, and the department 
### property on user objects.
### ous.txt - Name of child-containers for each Department OU (Computers, Groups, Users).  
### cities.txt - Names of cities I will use on user properties
### dist.all.last.txt - ASCII file of last names downloaded from the Census.gov website
### dist.male.first.txt - ASCII file of male first names downloaded from the Census.gov website
### dist.female.first.txt - ASCII file of female first names downloaded from the Census.gov website
###
### The descriptions of the deparments match the OU name.  This differentiates them from the default 
### containers created when AD is set up from those added by this script.  This allows for easily removing 
### containers and all child items quickly during testing.
### </Description>
###
### <Dependencies> 
### Requires ActiveRoles Management Shell for Active Directory.  This script will check
### for the snapin and add the snapin at runtime.
### </Dependencies>
###
### <History>
### changes 01/08/2010 - version 2.0
###  	- Change Display name and full name properties to format of Lastname, Firstname
### 	- Change password to p@ssw0rd
### Changes 01/11/2010 - version 2.1
###  - Assume base config of empty domain.  Create variable for root domain name
###  - make sure not attempt is made to duplicate usernames
###  - Create containers
### Changes 02/19/2010 - version 2.2
###  - added function to create empty departmental OUs and child containers for users, groups and computers
### Changes 02/22/2010 - version 2.3
###  - added computer account creation to occur when the user is added
###  - dot source functions.ps1
###  - added Joel Bennett's select-random v2.2 script to functions.ps1.  functions.ps1 in root of scripts folder
### Changes 02/23/2010
###  - Made script more readible by using word-wrap
###	 - Cleaned up description and commenting
### Changes 02/24/2010 - Version 2.4
###  - Using new ascii files for first and given names (see notes)
###  - Removed original lines for parsing census.gov files
### Changes 02/25/2010
###  - added better description for containers added via script to differentiate them to account for 
###  manually added containers
###	 - fixed issue with computer object creation - computer objects weren't always getting created
###
### Original Script name:  demoprovision.ps1
##################################################
### Script to provision demo AD labs
### (c) Dmitry Sotnikov, xaegr
### Requires AD cmdlets
##################################################
###
### set folder in which the data files are located
### this folder should contain files from
### http://www.census.gov/genealogy/names/names_files.html
### as well as cities.txt and departments.txt with the
### lists of cities and departments for the lab
### </History>
### </Script>
# ---------------------------------------------------------------------------

#Load Function Library
. $ScriptLib\\functions.ps1

# function to create empty OUs
function create-LabOUs (){
	# Create Each Dept OU
	for ($i = 0; $i -le $DeptOUs.Length - 1; $i++){
		$OUName = "Test Lab Container - " + $DeptOUs[$i]
		$CreateDeptOU += @(new-QADObject -ParentContainer $RootDomain.RootDomainNamingContext `
		-type 'organizationalUnit' -NamingProperty 'ou' -name $DeptOUs[$i] -description $OUName )
	}

	# Create Child OUs for each Dept
	foreach ($DeptOU in $CreateDeptOU){
		for ($i = 0; $i -le $ChildOUs.Length - 1; $i++){
			new-qadObject -ParentContainer $DeptOU.DN -type 'organizationalUnit' -NamingProperty 'ou' `
			-name $ChildOUs[$i]
		}
	}
}

function New-RandomADUser (){
	# set up random number generator
	$rnd = New-Object System.Random

	# pick a male or a female first name
	if($rnd.next(2) -eq 1) {
		$fn = $firstm[$rnd.next($firstm.length)]
	} else {
		$fn = $firstf[$rnd.next($firstf.length)]
	}
	# random last name
	$ln = $last[$rnd.next($last.length)]

	# Set proper caps
	$ln = $ln[0] + $ln.substring(1, $ln.length - 1).ToLower()
	$fn = $fn[0] + $fn.substring(1, $fn.length - 1).ToLower()

	# random city and department
	$city = $cities[$rnd.next($cities.length)]
	$dept = $depts[$rnd.next($depts.length)]

	$SName = ($fn.substring(0,1) + $ln)

	# set user OU variable
	switch ($dept){
		$DeptContainers[0].name {$UserOU = Get-QADObject -SearchRoot $DeptContainers[0].DN | `
			where { $_.DN -match "Users" -and $_.Type -ne "user" }} 
		$DeptContainers[1].name {$UserOU = Get-QADObject -SearchRoot $DeptContainers[1].DN | `
			where { $_.DN -match "Users" -and $_.Type -ne "user" }}
		$DeptContainers[2].name {$UserOU = Get-QADObject -SearchRoot $DeptContainers[2].DN | `
			where { $_.DN -match "Users" -and $_.Type -ne "user" }}
		$DeptContainers[3].name {$UserOU = Get-QADObject -SearchRoot $DeptContainers[3].DN | `
			where { $_.DN -match "Users" -and $_.Type -ne "user" }}
		$DeptContainers[4].name {$UserOU = Get-QADObject -SearchRoot $DeptContainers[4].DN | `
			where { $_.DN -match "Users" -and $_.Type -ne "user" }}
		$DeptContainers[5].name {$UserOU = Get-QADObject -SearchRoot $DeptContainers[5].DN | `
			where { $_.DN -match "Users" -and $_.Type -ne "user" }}
		$DeptContainers[6].name {$UserOU = Get-QADObject -SearchRoot $DeptContainers[6].DN | `
			where { $_.DN -match "Users" -and $_.Type -ne "user" }}
		$DeptContainers[7].name {$UserOU = Get-QADObject -SearchRoot $DeptContainers[7].DN | `
			where { $_.DN -match "Users" -and $_.Type -ne "user" }}
		$DeptContainers[8].name {$UserOU = Get-QADObject -SearchRoot $DeptContainers[8].DN | `
			where { $_.DN -match "Users" -and $_.Type -ne "user" }}
		$DeptContainers[9].name {$UserOU = Get-QADObject -SearchRoot $DeptContainers[9].DN | `
			where { $_.DN -match "Users" -and $_.Type -ne "user" }}
	}

	# Check for account, if not exist, create account
	if ((get-qaduser $SName) -eq $null){
		# Create and enable a user
		New-QADUser -Name "$ln`, $fn" -SamAccountName $SName -ParentContainer $UserOU -City $city `
		-Department $dept -UserPassword "p@ssw0rd" -FirstName $fn -LastName $ln -DisplayName "$ln`, $fn" `
		-Description "$city $dept" -Office $city | Enable-QADUser
	}

	# set group OU variable
	switch ($dept){
		$DeptContainers[0].name {$GroupOU = Get-QADObject -SearchRoot $DeptContainers[0].DN | `
			where { $_.DN -match "Groups" -and $_.Type -ne "group" }} 
		$DeptContainers[1].name {$GroupOU = Get-QADObject -SearchRoot $DeptContainers[1].DN | `
			where { $_.DN -match "Groups" -and $_.Type -ne "group" }}
		$DeptContainers[2].name {$GroupOU = Get-QADObject -SearchRoot $DeptContainers[2].DN | `
			where { $_.DN -match "Groups" -and $_.Type -ne "group" }}
		$DeptContainers[3].name {$GroupOU = Get-QADObject -SearchRoot $DeptContainers[3].DN | `
			where { $_.DN -match "Groups" -and $_.Type -ne "group" }}
		$DeptContainers[4].name {$GroupOU = Get-QADObject -SearchRoot $DeptContainers[4].DN | `
			where { $_.DN -match "Groups" -and $_.Type -ne "group" }}
		$DeptContainers[5].name {$GroupOU = Get-QADObject -SearchRoot $DeptContainers[5].DN | `
			where { $_.DN -match "Groups" -and $_.Type -ne "group" }}
		$DeptContainers[6].name {$GroupOU = Get-QADObject -SearchRoot $DeptContainers[6].DN | `
			where { $_.DN -match "Groups" -and $_.Type -ne "group" }}
		$DeptContainers[7].name {$GroupOU = Get-QADObject -SearchRoot $DeptContainers[7].DN | `
			where { $_.DN -match "Groups" -and $_.Type -ne "group" }}
		$DeptContainers[8].name {$GroupOU = Get-QADObject -SearchRoot $DeptContainers[8].DN | `
			where { $_.DN -match "Groups" -and $_.Type -ne "group" }}
		$DeptContainers[9].name {$GroupOU = Get-QADObject -SearchRoot $DeptContainers[9].DN | `
			where { $_.DN -match "Groups" -and $_.Type -ne "group" }}
	}

	# Create groups for each department, create group if it doesn't exist
	if ((get-QADGroup $dept) -eq $null){
		New-QADGroup -Name $dept -SamAccountName $dept -ParentContainer $GroupOU -Description "$dept Users"
	}

	# Add user to the group based on their department
	Get-QADUser $SName -SearchRoot $UserOU | Add-QADGroupMember -Identity { $_.Department }
	
	# set computer OU variable
	switch ($dept){
		$DeptContainers[0].name {$ComputerOU = Get-QADObject -SearchRoot $DeptContainers[0].DN | `
			where { $_.DN -match "Computers" -and $_.Type -ne "computer" }} 
		$DeptContainers[1].name {$ComputerOU = Get-QADObject -SearchRoot $DeptContainers[1].DN | `
			where { $_.DN -match "Computers" -and $_.Type -ne "computer" }}
		$DeptContainers[2].name {$ComputerOU = Get-QADObject -SearchRoot $DeptContainers[2].DN | `
			where { $_.DN -match "Computers" -and $_.Type -ne "computer" }}
		$DeptContainers[3].name {$ComputerOU = Get-QADObject -SearchRoot $DeptContainers[3].DN | `
			where { $_.DN -match "Computers" -and $_.Type -ne "computer" }}
		$DeptContainers[4].name {$ComputerOU = Get-QADObject -SearchRoot $DeptContainers[4].DN | `
			where { $_.DN -match "Computers" -and $_.Type -ne "computer" }}
		$DeptContainers[5].name {$ComputerOU = Get-QADObject -SearchRoot $DeptContainers[5].DN | `
			where { $_.DN -match "Computers" -and $_.Type -ne "computer" }}
		$DeptContainers[6].name {$ComputerOU = Get-QADObject -SearchRoot $DeptContainers[6].DN | `
			where { $_.DN -match "Computers" -and $_.Type -ne "computer" }}
		$DeptContainers[7].name {$ComputerOU = Get-QADObject -SearchRoot $DeptContainers[7].DN | `
			where { $_.DN -match "Computers" -and $_.Type -ne "computer" }}
		$DeptContainers[8].name {$ComputerOU = Get-QADObject -SearchRoot $DeptContainers[8].DN | `
			where { $_.DN -match "Computers" -and $_.Type -ne "computer" }}
		$DeptContainers[9].name {$ComputerOU = Get-QADObject -SearchRoot $DeptContainers[9].DN | `
			where { $_.DN -match "Computers" -and $_.Type -ne "computer" }}
	}

	# Create a computer account for the user
	if ((get-qadcomputer "$SName-Computer") -eq $null){
		New-QADComputer -Name "$SName-Computer" -SamAccountName "$SName-Computer" -ParentContainer `
		$ComputerOU -Location "$city $dept"
	}
}

$TestQADSnapin = get-pssnapin | where { $_.Name -eq "Quest.ActiveRoles.ADManagement"} 
if($TestQADSnapin -eq $null){
	add-pssnapin -Name Quest.ActiveRoles.ADManagement -ErrorAction SilentlyContinue
} 

# number of accounts to generate - edit
$num = 50

# Read root domain text
$RootDomain = Get-QADRootDSE

# Read all text data
# OU's to create
$DeptOUs = @(Get-Content "$ScriptLib\\LabSetup\\Departments.txt")
$ChildOUs = @(Get-Content "$ScriptLib\\labsetup\\ous.txt")
# read department and city info
$cities = Get-Content C:\\scripts\\LabSetup\\Cities.txt
$depts = Get-Content C:\\scripts\\LabSetup\\Departments.txt

# read name files
# randomly select names from census files
# Use Joel Bennet's select-random v 2.2; saved in functions.ps1
1..$num | ForEach-Object {
	$last += @(Get-Content C:\\scripts\\LabSetup\\surnames.txt | select-random)
	$firstm += @(Get-Content C:\\scripts\\LabSetup\\mgivennames.txt | select-random)
	$firstf += @(Get-Content C:\\scripts\\LabSetup\\fgivennames.txt | select-random)
}

# Let's do the work

# Create OUs first - call function
create-LabOUs

# Retrieve all newly created OU DN's for use in next function
$DeptContainers = @(Get-QADObject -Type "organizationalUnit" | where {$_.Name -ne "Computers" -and $_.Name `
	-ne "Groups" -and $_.Name -ne "Users" -and $_.Description -match "Test Lab Container"})

foreach ($item in $DeptContainers){
	$item.description
}
# Create users, create dept groups
1..$num | ForEach-Object { New-RandomADUser }

trap{
	Write-Host "ERROR: script execution was terminated.`n" $_.Exception.Message
	break
}
