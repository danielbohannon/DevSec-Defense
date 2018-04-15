## New-CodeSigningCert.ps1
########################################################################################################################
## Does the setup needed to self-sign PowerShell scripts ...
## Generates a "test" self-signed root Certificate Authority 
## And then generates a code-signing certificate (and signs it with the CA certificate)
## OPTIONALLY (specify -import or -importall) imports the certificates to the store(s)
########################################################################################################################
## NOTE: Uses OpenSSL (because it's xcopy redistributable -- wake up Microsoft)
##       In order for this to work you should KEEP the script in the folder with OpenSsl.exe
## Also, it is VERY important that you properly provide passwords and the locale data...
## You can obviously reorder the parameters however you like, and hard-code some of the values in the parameters, but 
## you need to make sure that if you use this to generate multiple certificates, that you preserve all of the certs
## and keep track of all your passwords so you don't lock yourself out of any of them.
########################################################################################################################
## Usage:
## \\\\Server\\PoshCerts\\New-CodeSigningCert.ps1 $pwd\\Certs "Joel Bennett" Jaykul@HuddledMasses.org HuddledMasses.org Mystery Rochester "New York" US -importall -OpenSSLLocation C:\\Users\\Joel\\Documents\\WindowsPowershell\\PoshCerts\\bin -CAPassword MyCleverRootPassword -CodeSignPassword EvenMoreCleverPasswords
##
## If I hard-coded the company/dept/etc ... I could use this to generate certs for all my devs:
## 
## \\\\Server\\PoshCerts\\New-CodeSigningCert.ps1 $pwd\\Certs "Mark Andreyovich" FakeEmail@Xerox.net -CAPassword MyCleverRootPassword -CodeSignPassword MarksPassword
## \\\\Server\\PoshCerts\\New-CodeSigningCert.ps1 $pwd\\Certs "Jesse Voller" FakeEmail2@Xerox.net -CAPassword MyCleverRootPassword -CodeSignPassword JessesPassword
##
## For the signed scripts to work, I just  have to -import on the devices where the scripts need to run:
##
## \\\\Server\\PoshCerts\\New-CodeSigningCert.ps1 $pwd\\Certs "Jesse Voller" -import
## \\\\Server\\PoshCerts\\New-CodeSigningCert.ps1 $pwd\\Certs "Mark Andreyovich" -import
## \\\\Server\\PoshCerts\\New-CodeSigningCert.ps1 $pwd\\Certs "Joel Bennett" -import
##
## On the developers' workstations, I need to use Get-PfxCertificate to sign, or else run -importall 
## That will load the codesigning cert in their "my" store, and will only require the password for the initial import
##
## \\\\Server\\PoshCerts\\New-CodeSigningCert.ps1 $pwd\\Certs "Joel Bennett" -importall -CodeSignPassword MyCodeSignPassword
########################################################################################################################
## History
##  1.0 - Initial public release
##  1.1 - Bug fix release to make it easier to use...
##  1.2 - Bug fix to get the ORG and COMMON NAME set correctly -- Major whoops!
##
Param(
$CertStorageLocation = (join-path (split-path $Profile) "Certs"),
$UserName       = (Read-Host "User name")

, $email        
, $company      
, $department   
, $city         
, $state        
, $country      

, $RootCAName   = "Self-Signed-Root-CA"
, $CodeSignName = "$UserName Code-Signing"
, $alias        = "PoshCert",


[string]$keyBits = 4096,
[string]$days = 365,
[string]$daysCA = (365 * 5),

[switch]$forceNew = $false,
[switch]$importall = $false,
[switch]$import = ($false -or $importall),

## we ask you to specify the CA password and your codesign password
## You can leave these null when importing on end-user desktops
$CAPassword = $null,
$CodeSignPassword = $null,

## You really shouldn't pass these unless you know what you're doing
$OpenSSLLocation = $null,
$RootCAPassword = $Null, 
$CodeSignCertPassword = $null
)


function Get-UserEmail {
   if(!$script:email) {
      $script:email = (Read-Host "Email address")
   }
   return $script:email
}

function Get-RootCAPassword {
   if(!$script:RootCAPassword) { 
      if(!$script:CAPassword) {
         $script:CAPassword = ((new-object System.Management.Automation.PSCredential "hi",(Read-Host -AsSecureString "Root CA Password")).GetNetworkCredential().Password)
      }

      ## Then down here we calculate large passwords to actually use:
      ## This works as long as you keep the same company name and root ca name 
      $script:RootCAPassword = [Convert]::ToBase64String( (new-Object Security.Cryptography.PasswordDeriveBytes ([Text.Encoding]::UTF8.GetBytes($CaPassword)), ([Text.Encoding]::UTF8.GetBytes("$company$RootCAName")), "SHA1", 5).GetBytes(64) )
   }
   return $script:RootCAPassword
}

function Get-CodeSignPassword {
   if(!$script:CodeSignCertPassword) { 
    
      if(!$script:CodeSignPassword) {
         $script:CodeSignPassword = ((new-object System.Management.Automation.PSCredential "hi",(Read-Host -AsSecureString "Code Signing Password")).GetNetworkCredential().Password)
      }
      ## This works as long as you keep the same PFX password and email address
      $script:CodeSignCertPassword = ([Convert]::ToBase64String( (new-Object Security.Cryptography.PasswordDeriveBytes ([Text.Encoding]::UTF8.GetBytes($CodeSignPassword)), ([Text.Encoding]::UTF8.GetBytes((Get-UserEmail))), "SHA1", 5).GetBytes(64) ))
   }
   return $script:CodeSignCertPassword
}

function Get-SslConfig {
Param ( 
   $keyBits, 
   $Country    = (Read-Host "Country (2-Letter code)"), 
   $State      = (Read-Host "State (Full Name, no intials)"), 
   $city       = (Read-Host "City"), 
   $company    = (Read-Host "Company Name (or Web URL)"), 
   $orgUnit    = (Read-Host "Department (team, group, family)"), 
   $CommonName, 
   $email = (Read-Host "Email Address")
)
@"
# OpenSSL example configuration file for BATCH certificate generation
# This definition stops the following lines choking if HOME isn't  defined.
HOME			   = .
RANDFILE		   = $($ENV::HOME)/.rnd

# To use this configuration with the "-extfile" option of the "openssl x509" utility
# name here the section containing the X.509v3 extensions to use:
#extensions		= code_sign

####################################################################
[ req ]
default_bits		   = {0}
default_keyfile 	   = privkey.pem
distinguished_name	= req_distinguished_name
#attributes		      = req_attributes
x509_extensions	   = v3_ca  # The extentions to add to the self signed cert
# req_extensions     = v3_ca  # Other extensions to add to a certificate request?

## Passwords for private keys could be specified here, instead of on the commandline
# input_password = secret
# output_password = secret

## Set the permitted string types...
## Some software crashes on BMPStrings or UTF8Strings, so we'll stick with 
string_mask = nombstr

[ req_distinguished_name ]
countryName			      = Country Name (2 letter code)
countryName_default		= {1}
countryName_min			= 2
countryName_max			= 2

stateOrProvinceName		= State or Province Name (full name)
stateOrProvinceName_default	= {2}

localityName			= Locality Name (eg, city)
localityName_default = {3}

0.organizationName		= Organization Name (eg, company)
0.organizationName_default	= {4}

# we can do this but it is not usually needed
#1.organizationName		= Second Organization Name (eg, company)
#1.organizationName_default	= World Wide Web Pty Ltd

organizationalUnitName		      = Organizational Unit Name (eg, section)
organizationalUnitName_default	= {5}

commonName			= Common Name (eg, YOUR name)
commonName_default = {6}
commonName_max			= 64

emailAddress			= Email Address
emailAddress_default = {7}
emailAddress_max		= 64

# SET-ex3			= SET extension number 3

# [ req_attributes ]
# challengePassword		= A challenge password
# challengePassword_min		= 4
# challengePassword_max		= 20
# unstructuredName		= An optional company name

[ v3_ca ]
## Extensions for a typical CA

## PKIX recommendations:
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
## PKIX suggests we should include email address in subject alt name
# subjectAltName=email:copy
## But really they want it *only* there or the certs are "deprecated"
# subjectAltName=email:move
## And the issuer details
# issuerAltName=issuer:copy


## This is what PKIX recommends 
basicConstraints = critical,CA:true
## some broken software chokes on critical extensions, so you could do this instead.
#basicConstraints = CA:true

## For a normal CA certificate you would want to specify this.
## But it will cause problems for our self-signed certificate.
# keyUsage = cRLSign, keyCertSign

## You might want the netscape-compatible stuff too
# nsCertType = sslCA, emailCA

[ code_sign ]
# These extensions are added when we get a code_signing cert
## PKIX recommendations:
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer

## PKIX suggests we should include email address in subject alt name
# subjectAltName=email:copy
## But really they want it *only* there or the certs are "deprecated"
# subjectAltName=email:move
## And the issuer details
# issuerAltName=issuer:copy

# This goes against PKIX guidelines but some CAs do it and some software
# requires this to avoid interpreting an end user certificate as a CA.
basicConstraints=CA:FALSE

# If nsCertType is omitted, the certificate can be used for anything *except* object signing.
# We just want to allow everything including object signing:
nsCertType = server, client, email, objsign
# This is the vital bit for code-signing
extendedKeyUsage       = critical, serverAuth,clientAuth,codeSigning

# This is typical in keyUsage for a client certificate.
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment

# This will be displayed in Netscape's comment listbox.
nsComment			= "OpenSSL Generated Certificate"

[ crl_ext ]
# CRL extensions.
# Only issuerAltName and authorityKeyIdentifier make any sense in a CRL.

# issuerAltName=issuer:copy
authorityKeyIdentifier=keyid:always,issuer:always
"@ -f $keyBits,$Country,$State,$city,$company,$orgUnit,$CommonName,$email
}

if(!$OpenSSLLocation) {
   ## You should be running the script from the OpenSsl folder
   $OpenSSLLocation = Split-Path $MyInvocation.MyCommand.Path
   Write-Debug "OpenSSL: $OpenSSLLocation"
}
if( Test-Path $OpenSslLocation ) {
   ## The OpenSslLoction needs to actually have OpenSsl in it ...
   $files = ls (Join-Path $OpenSSLLocation "*.[de][lx][el]") -include libeay32.dll,ssleay32.dll,OpenSSL.exe # libssl32.dll,
   if($files.count -lt 3) {
      THROW "You need to configure a location where OpenSSL can be run from"
   }
} else { THROW "You need to configure a location where OpenSSL can be run from" }

## Don't touch these
[string]$SslCnfPath = (join-path (Convert-Path $CertStorageLocation) PoshOpenSSL.config)
New-Alias OpenSsl (join-path $OpenSSLLocation OpenSSL.exe)

if( !(Test-Path $CertStorageLocation) ) {
   New-Item -type directory -path $CertStorageLocation | Push-Location
   $forceNew = $true
} else {
   Push-Location $CertStorageLocation
}

Write-Debug "SslCnfPath: $SslCnfPath"
Write-Debug "OpenSsl: $((get-alias OpenSsl).Definition)"

## Process the CSR and generate a pfx file 
if($forceNew -or (@(Test-Path "$CodeSignName.crt","$CodeSignName.pfx") -contains $false)) {

   ## Generate the private code-signing key and a certificate signing request (csr)
   if($forceNew -or (@(Test-Path "$CodeSignName.key","$CodeSignName.csr") -contains $false)) {

      ## Generate the private root CA key and convert it into a self-signed certificate (crt)
      if($forceNew -or (@(Test-Path "$RootCAName.key","$RootCAName.crt") -contains $false)) {

         ## Change configuration before -batch processing root key
         $CommonName = "$company Certificate Authority"
         $orgUnit = "$department Certificate Authority"
         $email = Get-UserEmail
         Set-Content $SslCnfPath (Get-SslConfig $keyBits $Country $State $city $company $orgUnit $CommonName $email) ## My special config file

         OpenSsl genrsa -out "$RootCAName.key" -des3 -passout pass:$(Get-RootCAPassword) $keyBits
         OpenSsl req -new -x509 -days $daysCA -key "$RootCAName.key" -out "$RootCAName.crt" -passin pass:$(Get-RootCAPassword) -config $SslCnfPath -batch
      }

      ## Change configuration before -batch processing code-signing key
      $CommonName = "$UserName"
      $orgUnit = "$department"
      $email = Get-UserEmail
      Set-Content $SslCnfPath (Get-SslConfig $keyBits $Country $State $city $company $orgUnit $CommonName $email) ## My special config file

      OpenSsl genrsa -out "$CodeSignName.key" -des3 -passout pass:$(Get-CodeSignPassword) $keyBits
      OpenSsl req -new -key "$CodeSignName.key" -out "$CodeSignName.csr" -passin pass:$(Get-CodeSignPassword) -config $SslCnfPath -batch
   }

   ## Use the root CA key to process the CSR and sign the code-signing key in one step...
   OpenSsl x509 -req -days $days -in "$CodeSignName.csr" -CA "$RootCAName.crt" -CAcreateserial -CAkey "$RootCAName.key" -out "$CodeSignName.crt" -setalias $alias -extfile $SslCnfPath -extensions code_sign -passin pass:$(Get-RootCAPassword)
   ## Combine the signed certificate and the private key into a single file and specify a new password for it ...
   OpenSsl pkcs12 -export -out "$CodeSignName.pfx" -inkey "$CodeSignName.key" -in "$CodeSignName.crt" -passin pass:$(Get-CodeSignPassword) -passout pass:$script:CodeSignPassword
}

Pop-Location

if($import) {
   ## Now we need to import the certificates to the computer so we can use them...
   ## Sadly, the PowerShell Certificate Provider is read-only, so we need to do this by hand
   
   trap {
      if($_.Exception.GetBaseException() -is [UnauthorizedAccessException]) {
         write-error "Cannot import certificates as 'Root CA' or 'Trusted Publisher' except in an elevated console."
         continue
      }
   }
   
   ## In order to be able to use scripts signed by these certs
   ## The root cert that signed the code-signing certs must be loaded into the "Root" store
   $lm = new-object System.Security.Cryptography.X509certificates.X509Store "root", "LocalMachine"
   $lm.Open("ReadWrite")
   $lm.Add( (Get-PfxCertificate "$CertStorageLocation\\$RootCAName.crt") )
   if($?) {
      Write-Host "Successfully imported root certificate to trusted root store" -fore green
   }
   $lm.Close()

   ## In order to avoid the "untrusted publisher" prompt
   ## The public code-signing cert must be loaded into the "TrustedPublishers" store
   $tp = new-object System.Security.Cryptography.X509certificates.X509Store "TrustedPublisher", "LocalMachine"
   $tp.Open("ReadWrite")
   $tp.Add( (Get-PfxCertificate "$CertStorageLocation\\$CodeSignName.crt") )
   if($?) {
      Write-Host "Successfully imported code-signing certificate to trusted publishers store" -fore green
   }
   $tp.Close()

   if($importall) {
      ## It's a good practice to go ahead and put our private certificates in "OUR" store too
      ### Otherwise we have to load it each time from the pfx file using Get-PfxCertificate
      ##### $cert = Get-PfxCertificate "$CodeSignName.pfx"
      ##### Set-AuthenticodeSignature -Cert $cert -File Test-Script.ps1
      $my = new-object System.Security.Cryptography.X509certificates.X509Store "My", "CurrentUser"
      $my.Open( "ReadWrite" )
      Get-CodeSignPassword
      $my.Add((Get-PfxCertificate "$CertStorageLocation\\$CodeSignName.pfx"))      #$script:CodeSignPassword, $DefaultStorage)
      if($?) {
         Write-Host "Successfully imported code-signing certificate to 'my' store" -fore yellow
      }
      $my.Close()
   }
}

# SIG # Begin signature block
# MIILCQYJKoZIhvcNAQcCoIIK+jCCCvYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUunVl0UTZlvAjOS219sL9EUT4
# EE6gggbgMIIG3DCCBMSgAwIBAgIJALPpqDj9wp7xMA0GCSqGSIb3DQEBBQUAMIHj
# MQswCQYDVQQGEwJVUzERMA8GA1UECBMITmV3IFlvcmsxEjAQBgNVBAcTCVJvY2hl
# c3RlcjEhMB8GA1UEChMYaHR0cDovL0h1ZGRsZWRNYXNzZXMub3JnMSgwJgYDVQQL
# Ex9TY3JpcHRpbmcgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MTcwNQYDVQQDEy5odHRw
# Oi8vSHVkZGxlZE1hc3Nlcy5vcmcgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MScwJQYJ
# KoZIhvcNAQkBFhhKYXlrdWxASHVkZGxlZE1hc3Nlcy5vcmcwHhcNMDkwMzE1MTkx
# OTE5WhcNMTAwMzE1MTkxOTE5WjCBqzELMAkGA1UEBhMCVVMxETAPBgNVBAgTCE5l
# dyBZb3JrMRIwEAYDVQQHEwlSb2NoZXN0ZXIxITAfBgNVBAoTGGh0dHA6Ly9IdWRk
# bGVkTWFzc2VzLm9yZzESMBAGA1UECxMJU2NyaXB0aW5nMRUwEwYDVQQDEwxKb2Vs
# IEJlbm5ldHQxJzAlBgkqhkiG9w0BCQEWGEpheWt1bEBIdWRkbGVkTWFzc2VzLm9y
# ZzCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAPfqxOG9TQN+qZjZ6KfM
# +zBK0YpjeyPL/cFgiGBhiIdYWTBtkbZydFr3IiERKRsUJ0/SKFbhf0C3Bvd/neTJ
# qiZjH4D6xkrfdLlWMmmSXXqjSt48jZp+zfCAIaF8K84e9//7lMicdVFE6VcgoATZ
# /eMKQky4JvphJpzDHYPLxLJQrKd0pjDDwspjdX5RedWkzeZBG7VfBnebLWUzgnMX
# IxRQKfFCMryQDP8weceOnJjfJEf2FYmdpsEg5EKKKbuHsQCMVTxfteKdPvh1oh05
# 1GWyPsvEPh4auJUT8pAVvrdxq+/O9KW/UV01UxjRYM1vdklNw8g7mkJTrrHjSjl7
# tuugCnJjt5kN6v/OaUtRRMR68O85bSTVGOxJGCHUKlyuuTx9tnfIgy4siFYX1Ve8
# xwaAdN3haTon3UkWzncHOq3reCIVF0luwRZu7u+TnOAnz2BRlt+rcT0O73GN20Fx
# gyN2f5VGBbw1KuS7T8XZ0TFCspUdgwAcmTGuEVJKGhVcGAvNlLx+KPc5dba4qEfs
# VZ0MssC2rALC1z61qWuucb5psHYhuD2tw1SrztywuxihIirZD+1+yKE4LsjkM1zG
# fQwDO/DQJwkdByjfB2I64p6mk36OlZAFxVfRBpXSCzdzbgKpuPsbtjkb5lGvKjE1
# JFVls1SHLJ9q80jHz6yW7juBAgMBAAGjgcgwgcUwHQYDVR0OBBYEFO0wLZyg+qGH
# Z4WO8ucEGNIdU1T9MB8GA1UdIwQYMBaAFN2N42ZweJLF1mz0j70TMxePMcUHMAkG
# A1UdEwQCMAAwEQYJYIZIAYb4QgEBBAQDAgTwMCoGA1UdJQEB/wQgMB4GCCsGAQUF
# BwMBBggrBgEFBQcDAgYIKwYBBQUHAwMwCwYDVR0PBAQDAgTwMCwGCWCGSAGG+EIB
# DQQfFh1PcGVuU1NMIEdlbmVyYXRlZCBDZXJ0aWZpY2F0ZTANBgkqhkiG9w0BAQUF
# AAOCAgEAmKihxd6KYamLG0YLvs/unUTVJ+NW3jZP16R28PpmidY/kaBFOPhYyMl2
# bBGQABe7LA5rpHFAs0F56gYETNoFk0qREVvaoz9u18VfLb0Uwqtnq0P68L4c7p2q
# V3nKmWjeI6H7BAyFuogxmMH5TGDfiqrrVSuh1LtPbkV2Wtto0SAxP0Ndyts2J8Ha
# vu/2rt0Ic5AkyD+RblFPtzkCC/MLVwSNAiDSKGRPRrLaiGxntEzR59GRyf2vwhGg
# oAXUqcJ/CVeHCP6qdSTM39Ut3RmMZHXz5qY8bvLgNYL6MtcJAx+EeUhW497alzm1
# jInXdbikIh0d/peTSDyLbjS8CPFFtS6Z56TDGMf+ouTpEA16otcWIPA8Zfjq+7n7
# iBHjeuy7ONoJ2VDNgqn9B+ft8UWRwnJbyB85T83OAGf4vyhCPz3Kg8kWxY30Bhnp
# Fayc6zQKCpn5o5T0/a0BBHwAyMfr7Lhav+61GpzzG1KfAw58N2GV8KCPKNEd3Zdz
# y07aJadroVkW5R+35mSafKRJp5pz20GDRwZQllqGH1Y/UJFEiI0Bme9ecbl2vzNp
# JjHyl/jLVzNVrBI5Zwb0lCLsykApgNY0yrwEqaiqwcxq5nkXFDhDPQvbdulihSo0
# u33fJreCm2fFyGbTuvR61goSksAvLQhvijLAzcKqWKG+laOtYpAxggOTMIIDjwIB
# ATCB8TCB4zELMAkGA1UEBhMCVVMxETAPBgNVBAgTCE5ldyBZb3JrMRIwEAYDVQQH
# EwlSb2NoZXN0ZXIxITAfBgNVBAoTGGh0dHA6Ly9IdWRkbGVkTWFzc2VzLm9yZzEo
# MCYGA1UECxMfU2NyaXB0aW5nIENlcnRpZmljYXRlIEF1dGhvcml0eTE3MDUGA1UE
# AxMuaHR0cDovL0h1ZGRsZWRNYXNzZXMub3JnIENlcnRpZmljYXRlIEF1dGhvcml0
# eTEnMCUGCSqGSIb3DQEJARYYSmF5a3VsQEh1ZGRsZWRNYXNzZXMub3JnAgkAs+mo
# OP3CnvEwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFGPa+3yKeAOuG8MGktIPE98U9IQyMA0GCSqG
# SIb3DQEBAQUABIICACukiWmmkw/T3q/IukaKIIO4/jJLng9v52P60RViKwJn7TOZ
# C6Qcov2zO8/LBm8oIlY+kQil8MXqA3+5D7TGtFfYpyzoUh+Nwks1C9KAMWeRBKAL
# b3H6CVX0H5nRh9PLa2a4WxbYHM6IxCOa/Z8clH4veAZbs5Zq5mtjLV14u8PszAYM
# 4P/H0sXHMZYb9nj0vKjsZdxOlM0g6JHqUszE40tND/5dFuzdr3Tyu/aC6/j/ZFGZ
# jdyaM88kE88qAU9Bs2M18LsSUJx6GsdlXwDD4eCBRH59+QtAnQZB4HUL5KkF53DG
# J0WtRuI+wWmeMU9nNtDMQgSGJev0LVEJ2Ui+UsVA+RvWH04VCBrzlXi2TLzS9bCQ
# 5Fo/t/czCbC4m/WrXQyYNDoHtI/fXE2ctSPq2QQaDF9Bu65MuMGzWa3iFSFmq0uA
# nYivtHSlgyqhPBBmu8fspePkye7PzYoH2Gpykp17R5fBx+rQriKjTkZcGNdAGdQY
# j7SEC93e0KjtZRQA+ABxmVacmNrO6NGbMN2Zd8Pheham1T38V3aWjKvq2d94iUfh
# dgqvWhSu6zw0yE/NaJPTKnixN0j+up/Y7jSO9Cytvl4TNWJkFjDp+u0exl4s6eQ5
# cspbWHwWyYWyg7e0YaclbL7mPygvjxQDWOWgMN9cddvHCq8fiq6VPNTJqeLB
# SIG # End signature block
