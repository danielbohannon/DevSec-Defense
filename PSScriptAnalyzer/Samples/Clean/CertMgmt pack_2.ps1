#####################################################################
# CertMgmtPack.ps1
# Version 0.51
#
# Digital certificate management pack
#
# Vadims Podans (c) 2009
# http://www.sysadmins.lv/
#####################################################################
#requires -Version 2.0

function Import-Certificate {
<#
.Synopsis
	Imports digital certificates to Certificate Store from files
.Description
	Improrts digital certificates to Certificate Store from various types of
	certificates files, such .CER, .DER, .PFX (password required), .P7B.
.Parameter Path
	Specifies the path to certificate file
.Parameter Password
	Specifies password to PFX/PKCS#12 file only. For other certificate types
	is not required. 
	
	Note: this parameter must be passed as SecureString.
.Parameter Storage
	Specifies place in Sertificate Store for certificate. For user certificates
	(default) you MAY specify 'User' and importing certificate will be stored
	in CurrentUser Certificate Store. For computer certificates you MUST specify
	'Computer' and importing certificates will be stored in LocalMachine Certificate
	Store.
.Parameter Container
	Specifies container within particular Certificate Store location. Container may
	be one of AuthRoot/CA/Disallowed/My/REQUEST/Root/SmartCardRoot/Trust/TrustedPeople/
	TrustedPublisher/UserDS. These containers represent MMC console containers
	as follows:
	AddressBook		-	AddressBook
	AuthRoot			-	Third-Party Root CAs
	CA			-	Intermediate CAs
	Disallowed		-	Untrused Certificates
	My			-	Personal
	REQUEST			-	Certificate Enrollment Requests
	Root			-	Trusted Root CAs
	SmartCardRoot		-	Smart Card Trusted Roots
	Trust			-	Enterprise Trust
	TrustedPeople		-	Trusted People
	TrustedPublishers		-	Trusted Publishers
	UserDS				-	Active Directory User Object
.Parameter Exportable
	Marks imported certificates private key as exportable. May be used only for PFX
	files only. If this switch is not presented for PFX files, after importing you
	will not be able to export this certificate with private key again.
.Parameter StrongProtection
	Enables private key strong protection that requires user password each time
	when certificate private key is used. Not available for computer certificates,
	because computers certificates are used under LocalSystem account and here is
	no UI for user to type password.
.Outputs
	This command provide a simple message if the export is successful.
#>
[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		[string]$Path,
		[Parameter(Position = 1)]
		[System.Security.SecureString]$Password,
		[Parameter(Position = 2)]
		[string][ValidateSet("CurrentUser", "LocalMachine")]$Storage = "CurrentUser",
		[string][ValidateSet("AddressBook", "AuthRoot", "CA", "Disallowed", "My", "REQUEST",
			"Root", "SmartCardRoot", "Trust", "TrustedPeople", "TrustedPublisher", "UserDS")]$Container = "My",
		[switch]$Exportable,
		[switch]$StrongProtection
	)
	if (!(Resolve-Path $Path)) {throw "Looks like your specified certificate file doesn't exist"}
	$file = gi $Path -Force -ErrorAction Stop
	$certs = New-Object system.security.cryptography.x509certificates.x509certificate2
	switch ($Storage) {
		"CurrentUser" {$flags = "UserKeySet"}
		"LocalMachine" {$flags = "MachineKeySet"}
	}
	switch -regex ($file.Extension) {
	".CER|.DER" {$certs.Import($file.FullName, $null, $flags)}
	".PFX" {
			if (!$password) {throw "For PFX files password is required."}
			if ($StrongProtection -and $Storage -eq "Computer") {
				throw "You cannot use Private Key Strong Protection for computer certificates!"
			}
			if ($Exportable) {$flags = $flags + ", Exportable"}
			if ($StrongProtection) {$flags = $flags + ", UserProtected"}
			$certs.Import($file.FullName, $password, $flags)
		}
	".P7B|.SST" {
			$certs = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
			$certs.Import([System.IO.File]::ReadAllBytes($file.FullName))
		}
	default {throw "Looks like your specified file is not a certificate file"}
	}
	$store = New-Object system.security.cryptography.X509Certificates.X509Store $Container, $Storage
	$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
	$certs | %{$store.Add($_)}
	if ($?) {Write-Host -ForegroundColor Green Certificate file`: $file.fullname was successfully added to $Container container}
	$store.Close()
}

function Export-Certificate {
<#
.Synopsis
	Exports digital certificates to file Certificate Store.
.Description
	Exports digital certificates from Certificate Store to various types of certificate
	file such .CER, .DER, .PFX (password required), .P7B or .SST (serializd store).
.Parameter Path
	Specifies the path to certificate storing folder
.Parameter Type
	Specifies type of imported certificate. May be one of CERT/PFX/PKCS#12/P7B/PKCS#7.
.Parameter Password
	Specifies a password for PFX files and used only if type is specified as PFX/PKCS#12.
	
	Note: password must be supplied as SecureString.
.Parameter Storage
	Specifies place in Sertificate Store for certificate. For user certificates
	(default) you MAY specify 'User' to export certificates from CurrentUser Certificate Store.
	For computer certificates you MUST specify 'Computer' to export certificates from
	LocalMachine Certificate Store.
.Parameter Container
	Specifies container within particular Certificate Store location. Container may
	be one of AuthRoot/CA/Disallowed/My/REQUEST/Root/SmartCardRoot/Trust/TrustedPeople/
	TrustedPublisher/UserDS. These containers represent MMC console containers
	as follows:
	AddressBook		-	AddressBook
	AuthRoot			-	Third-Party Root CAs
	CA			-	Intermediate CAs
	Disallowed		-	Untrused Certificates
	My			-	Personal
	REQUEST			-	Certificate Enrollment Requests
	Root			-	Trusted Root CAs
	SmartCardRoot		-	Smart Card Trusted Roots
	Trust			-	Enterprise Trust
	TrustedPeople		-	Trusted People
	TrustedPublishers		-	Trusted Publishers
	UserDS			-	Active Directory User Object
.EXAMPLE

.Outputs
	This command doesn't provide any output, except errors.
.Link
#>
[CmdletBinding()]
	param (
		[Parameter(Position = 0)]
		[string]$Path,
		[Parameter(Mandatory = $true, Position = 1)]
		[string][ValidatePattern("Cert|Pfx|pkcs12|pkcs7|SST")]$Type,
		[Parameter(Position = 2)]
		[System.Security.SecureString]$Password,
		[Parameter(Position = 3)]
		[string][ValidateSet("CurrentUser", "LocalMachine")]$Storage = "CurrentUser",
		[Parameter(ValueFromPipeline = $true, Position = 4)]
		[string][ValidateSet("AddressBook", "AuthRoot", "CA", "Disallowed", "My", "REQUEST",
			"Root", "SmartCardRoot", "Trust", "TrustedPeople", "TrustedPublisher", "UserDS")]$Container = "My",
		[string]$Thumbprint,
		[string]$Subject,
		[string]$Issuer,
		[string]$SerialNumber,
		[string]$NotAfter,
		[string]$NotBefore,
		[switch]$DeleteKey,
		[switch]$Recurse
	)
	
	if (!(Test-Path $Path)) {
		New-Item -ItemType directory -Path $Path -Force -ErrorAction Stop
	}
	if ((Resolve-Path $Path).Provider.Name -ne "FileSystem") {
		throw "Spicifed path is not recognized as filesystem path. Try again"
	}
	if ($Recurse) {
		function dirx ($Storage) {
			dir cert:\\$Storage -Recurse | ?{!$_.PsIsContainer}
		}
	} else {
		function dirx ($Storage, $Container) {
			dir cert:\\$Storage\\$Container
		}
	}
	if ($Type -eq 'pkcs12') {$Type = "PFX"}
	if ($Type -eq 'SST') {$Type = "SerializedStore"}
	if ($Type -eq "PFX" -and !$Password) {throw "For PFX files password is required."}
	$Type = [System.Security.Cryptography.X509Certificates.X509ContentType]::$Type
	if ($NotAfter) {$NotAfter = [datetime]::ParseExact($NotAfter, "dd.MM.yyy", $null)}
	if ($NotBefore) {$NotBefore = [datetime]::ParseExact($NotBefore, "dd.MM.yyy", $null)}
	if ($Thumbprint) {$certs = @(dirx | ?{$_.Thumbprint -like "*$Thumbprint*"})}
	elseif ($Subject) {$certs = @(dirx | ?{$_.Subject -like "*$Subject*"})}
	elseif ($Issuer) {$certs = @(dirx | ?{$_.Issuer -like "*$Issuer*"})}
	elseif ($SerialNumber) {$certs = @(dirx | ?{$_.SerialNumber -like "*$SerialNumber*"})}
	elseif ($NotAfter -and !$NotBefore) {$certs = @(dirx | ?{$_.NotAfter -lt $NotAfter})}
	elseif (!$NotAfter -and $NotBefore) {$certs = @(dirx | ?{$_.NotBefore -gt $NotBefore})}
	elseif ($NotAfter -and $NotBefore) {$certs = @(dirx | ?{$_.NotAfter -lt $NotAfter `
		-and $_.NotBefore -gt $NotBefore})}
	else {$certs = @(dirx)}
	if ($certs.Count -eq 0) {Write-Warning "Sorry, we unable to find certificates that correspond your filter :("; return}
	switch -regex ($Type) {
	"Cert" {
			foreach ($cert in $certs) {
				[void]($cert.Subject -match 'CN=([^,]+)')
				$CN = $matches[1] -replace '[\\\\/:\\*?`"<>|]', ''
				$bytes = $cert.Export($type)
				$base64Data = [System.Convert]::ToBase64String($bytes)
				Set-Content -LiteralPath $(Join-Path $Path ($CN + "_" + $cert.Thumbprint + ".cer")) -Value $base64Data
			}
		}
	"PFX" {
			foreach ($cert in $certs) {
				[void]($cert.Subject -match 'CN=([^,]+)')
				$CN = $matches[1] -replace '[\\\\/:\\*?`"<>|]', ''
				$bytes = $cert.Export($Type, $Password)
				[System.IO.File]::WriteAllBytes($(Join-Path $Path ($CN + "_" + $cert.Thumbprint + ".pfx")), $bytes)
				if ($DeleteKey) {
					$tempcert = $cert.Export("Cert")
					$store = New-Object system.security.cryptography.X509Certificates.X509Store $container, $Storage
					$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
					$store.Remove($cert)
					$store.Add($tempcert)
					$store.Close()
				}
			}
		}
	"Pkcs7|SerializedStore" {
			$certcol = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
			$certs | %{[void]$certcol.Add($_)}
			$bytes = $certcol.Export($Type)
			if ($Type -eq "Pkcs7") {$ext = ".p7b"} else {$ext = ".sst"}
			[System.IO.File]::WriteAllBytes($("ExportedCertificates" + $ext, $bytes))
		}
	}
}
