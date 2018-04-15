############################################################################ 
## Create-SPFarm
## V 0.3
## Jos.Verlinde
############################################################################ 
Param (	[String] $Farm		= "SP2010",
	[String] $SQLServer 	= $env:COMPUTERNAME,
	[String] $Passphrase	= "pass@word1",
	[int]	 $CAPort	    = 26101	,
    [switch] $Force         = $false )
    

# Disable the Loopback Check on stand alone demo servers.  
# This setting usually kicks out a 401 error when you try to navigate to sites that resolve to a loopback address e.g.  127.0.0.1 

New-ItemProperty HKLM:\\System\\CurrentControlSet\\Control\\Lsa -Name "DisableLoopbackCheck"  -value "1" -PropertyType dword




#region Process Input Parameters

$SecPhrase=ConvertTo-SecureString  $Passphrase AsPlaintext Force
$Passphrase = $null

## get Farm Account
$cred_farm = $host.ui.PromptForCredential("FARM Setup", "SP Farm Account (SP_farm)", "contoso\\sp_farm", "NetBiosUserName" )


#Endregion



# Create a new farm  
New-SPConfigurationDatabase DatabaseName $FARM-Config DatabaseServer $SQLServer AdministrationContentDatabaseName $FARM-Admin-Content Passphrase $SecPhrase FarmCredentials $Cred_Farm

# Create Central Admin 
New-SPCentralAdministration -Port $CAPort -WindowsAuthProvider "NTLM"

#Install Help Files 
Install-SPApplicationContent 


#Secure resources
Initialize-SPResourceSecurity

#Install (all) features

If ( $Force ) {
    $Features = Install-SPFeature AllExistingFeatures -force
} else {
    $Features = Install-SPFeature AllExistingFeatures 
}    
## Report features installed 
$Features 


# Provision all Services works only on stand alone servers (ie one-click-install )
# Install-SPService  -Provision

## Todo : Check for Errors in the evenlog 
## 
## Start Central Admin 
Start-Process "http://$($env:COMPUTERNAME):$CAPort"

## Run Farm configuration Wizard 
Start-Process "http://$($env:COMPUTERNAME):$CAPort/_admin/adminconfigintro.aspx?scenarioid=adminconfig&welcomestringid=farmconfigurationwizard_welcome"


##@@ Todo - Run Farm Wizard or better yet create required service applications (minimal - normal - all template)
