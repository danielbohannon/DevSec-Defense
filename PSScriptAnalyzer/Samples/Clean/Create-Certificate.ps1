#####################################################################
# Create PowerShell cert.ps1
# Version 1.0
#
# Creates self-signed signing certificate and install it to certificate store
#
# Note: Requires at least Windows Vista. Windows XP/Windows Server 2003
# are not supported.
#
# Vadims Podans (c) 2010
# http://www.sysadmins.lv/
#####################################################################
#requires -Version 2.0

function New-SigningCert {
<#
.Synopsis
	Creates self-signed signing certificate and install it to certificate store
.Description
	This function generates self-signed certificate with some pre-defined and
	user-definable settings. User may elect to perform complete certificate
	installation, by installing generated certificate to Trusted Root Certification
	Authorities and Trusted Publishers containers in *current user* store.
	
.Parameter Subject
	Specifies subject for certificate. This parameter must be entered in X500
	Distinguished Name format. Default is: CN=PowerShell User, OU=Test Signing Cert.

.Parameter KeyLength
	Specifies private key length. Due of performance and security reasons, only
	1024 and 2048 bit are supported. by default 1024 bit key length is used.

.Parameter NotBefore
	Sets the date in local time on which a certificate becomes valid. By default
	current date and time is used.

.Parameter NotAfter
	Sets the date in local time after which a certificate is no longer valid. By
	default certificate is valid for 365 days.

.Parameter Force
	If Force switch is asserted, script will prepare certificate for use by adding
	it to Trusted Root Certification Authorities and Trusted Publishers containers
	in current user certificate store. During certificate installation you will be
	prompted to confirm if you want to add self-signed certificate to Trusted Root
	Certification Authorities container.
#>
[CmdletBinding()]
	param (
		[string]$Subject = "CN=PowerShell User, OU=Test Signing Cert",
		[int][ValidateSet("1024", "2048")]$KeyLength = 1024,
		[datetime]$NotBefore = [DateTime]::Now,
		[datetime]$NotAfter = $NotBefore.AddDays(365),
		[switch]$Force
	)
	
	$OS = (Get-WmiObject Win32_OperatingSystem).Version
	if ($OS[0] -lt 6) {
		Write-Warning "Windows XP, Windows Server 2003 and Windows Server 2003 R2 are not supported!"
		return
	}
	# while all certificate fields MUST be encoded in ASN.1 DER format
	# we will use CryptoAPI COM interfaces to generate and encode all necessary
	# extensions.
	
	# create Subject field in X.500 format using the following interface:
	# http://msdn.microsoft.com/en-us/library/aa377051(VS.85).aspx
	$SubjectDN = New-Object -ComObject X509Enrollment.CX500DistinguishedName
	$SubjectDN.Encode($Subject, 0x0)
	
	# define CodeSigning enhanced key usage (actual OID = 1.3.6.1.5.5.7.3.3) from OID
	# http://msdn.microsoft.com/en-us/library/aa376784(VS.85).aspx
	$OID = New-Object -ComObject X509Enrollment.CObjectID
	$OID.InitializeFromValue("1.3.6.1.5.5.7.3.3")
	# while IX509ExtensionEnhancedKeyUsage accept only IObjectID collection
	# (to support multiple EKUs) we need to create IObjectIDs object and add our
	# IObjectID object to the collection:
	# http://msdn.microsoft.com/en-us/library/aa376785(VS.85).aspx
	$OIDs = New-Object -ComObject X509Enrollment.CObjectIDs
	$OIDs.Add($OID)
	
	# now we create Enhanced Key Usage extension, add our OID and encode extension value
	# http://msdn.microsoft.com/en-us/library/aa378132(VS.85).aspx
	$EKU = New-Object -ComObject X509Enrollment.CX509ExtensionEnhancedKeyUsage
	$EKU.InitializeEncode($OIDs)
	
	# generate Private key as follows:
	# http://msdn.microsoft.com/en-us/library/aa378921(VS.85).aspx
	$PrivateKey = New-Object -ComObject X509Enrollment.CX509PrivateKey
	$PrivateKey.ProviderName = "Microsoft Base Cryptographic Provider v1.0"
	# private key is supposed for signature: http://msdn.microsoft.com/en-us/library/aa379409(VS.85).aspx
	$PrivateKey.KeySpec = 0x2
	$PrivateKey.Length = $KeyLength
	# key will be stored in current user certificate store
	$PrivateKey.MachineContext = 0x0
	$PrivateKey.Create()
	
	# now we need to create certificate request template using the following interface:
	# http://msdn.microsoft.com/en-us/library/aa377124(VS.85).aspx
	$Cert = New-Object -ComObject X509Enrollment.CX509CertificateRequestCertificate
	$Cert.InitializeFromPrivateKey(0x1,$PrivateKey,"")
	$Cert.Subject = $SubjectDN
	$Cert.Issuer = $Cert.Subject
	$Cert.NotBefore = $NotBefore
	$Cert.NotAfter = $NotAfter
	$Cert.X509Extensions.Add($EKU)
	# completing certificate request template building
	$Cert.Encode()
	
	# now we need to process request and build end certificate using the following
	# interface: http://msdn.microsoft.com/en-us/library/aa377809(VS.85).aspx
	
	$Request = New-Object -ComObject X509Enrollment.CX509enrollment
	# process request
	$Request.InitializeFromRequest($Cert)
	# retrievecertificate encoded in Base64.
	$endCert = $Request.CreateRequest(0x1)
	# install certificate to user store
	$Request.InstallResponse(0x2,$endCert,0x1,"")
	
	if ($Force) {
		# convert Bas64 string to a byte array
	 	[Byte[]]$bytes = [System.Convert]::FromBase64String($endCert)
		foreach ($Container in "Root", "TrustedPublisher") {
			# open Trusted Root CAs and TrustedPublishers containers and add
			# certificate
			$x509store = New-Object Security.Cryptography.X509Certificates.X509Store $Container, "CurrentUser"
			$x509store.Open([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
			$x509store.Add([Security.Cryptography.X509Certificates.X509Certificate2]$bytes)
			# close store when operation is completed
			$x509store.Close()
		}
	}
}
# SIG # Begin signature block
# MIIVAwYJKoZIhvcNAQcCoIIU9DCCFPACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0KtSTs5dBa+keiTXHCrRnHa1
# bU2gghDIMIIDejCCAmKgAwIBAgIQOCXX+vhhr570kOcmtdZa1TANBgkqhkiG9w0B
# AQUFADBTMQswCQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xKzAp
# BgNVBAMTIlZlcmlTaWduIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EwHhcNMDcw
# NjE1MDAwMDAwWhcNMTIwNjE0MjM1OTU5WjBcMQswCQYDVQQGEwJVUzEXMBUGA1UE
# ChMOVmVyaVNpZ24sIEluYy4xNDAyBgNVBAMTK1ZlcmlTaWduIFRpbWUgU3RhbXBp
# bmcgU2VydmljZXMgU2lnbmVyIC0gRzIwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJ
# AoGBAMS18lIVvIiGYCkWSlsvS5Frh5HzNVRYNerRNl5iTVJRNHHCe2YdicjdKsRq
# CvY32Zh0kfaSrrC1dpbxqUpjRUcuawuSTksrjO5YSovUB+QaLPiCqljZzULzLcB1
# 3o2rx44dmmxMCJUe3tvvZ+FywknCnmA84eK+FqNjeGkUe60tAgMBAAGjgcQwgcEw
# NAYIKwYBBQUHAQEEKDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC52ZXJpc2ln
# bi5jb20wDAYDVR0TAQH/BAIwADAzBgNVHR8ELDAqMCigJqAkhiJodHRwOi8vY3Js
# LnZlcmlzaWduLmNvbS90c3MtY2EuY3JsMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMI
# MA4GA1UdDwEB/wQEAwIGwDAeBgNVHREEFzAVpBMwETEPMA0GA1UEAxMGVFNBMS0y
# MA0GCSqGSIb3DQEBBQUAA4IBAQBQxUvIJIDf5A0kwt4asaECoaaCLQyDFYE3CoIO
# LLBaF2G12AX+iNvxkZGzVhpApuuSvjg5sHU2dDqYT+Q3upmJypVCHbC5x6CNV+D6
# 1WQEQjVOAdEzohfITaonx/LhhkwCOE2DeMb8U+Dr4AaH3aSWnl4MmOKlvr+ChcNg
# 4d+tKNjHpUtk2scbW72sOQjVOCKhM4sviprrvAchP0RBCQe1ZRwkvEjTRIDroc/J
# ArQUz1THFqOAXPl5Pl1yfYgXnixDospTzn099io6uE+UAKVtCoNd+V5T9BizVw9w
# w/v1rZWgDhfexBaAYMkPK26GBPHr9Hgn0QXF7jRbXrlJMvIzMIIDxDCCAy2gAwIB
# AgIQR78Zld+NUkZD99ttSA0xpDANBgkqhkiG9w0BAQUFADCBizELMAkGA1UEBhMC
# WkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIGA1UEBxMLRHVyYmFudmlsbGUx
# DzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhhd3RlIENlcnRpZmljYXRpb24x
# HzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcgQ0EwHhcNMDMxMjA0MDAwMDAw
# WhcNMTMxMjAzMjM1OTU5WjBTMQswCQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNp
# Z24sIEluYy4xKzApBgNVBAMTIlZlcmlTaWduIFRpbWUgU3RhbXBpbmcgU2Vydmlj
# ZXMgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCpyrKkzM0grwp9
# iayHdfC0TvHfwQ+/Z2G9o2Qc2rv5yjOrhDCJWH6M22vdNp4Pv9HsePJ3pn5vPL+T
# rw26aPRslMq9Ui2rSD31ttVdXxsCn/ovax6k96OaphrIAuF/TFLjDmDsQBx+uQ3e
# P8e034e9X3pqMS4DmYETqEcgzjFzDVctzXg0M5USmRK53mgvqubjwoqMKsOLIYdm
# vYNYV291vzyqJoddyhAVPJ+E6lTBCm7E/sVK3bkHEZcifNs+J9EeeOyfMcnx5iIZ
# 28SzR0OaGl+gHpDkXvXufPF9q2IBj/VNC97QIlaolc2uiHau7roN8+RN2aD7aKCu
# FDuzh8G7AgMBAAGjgdswgdgwNAYIKwYBBQUHAQEEKDAmMCQGCCsGAQUFBzABhhho
# dHRwOi8vb2NzcC52ZXJpc2lnbi5jb20wEgYDVR0TAQH/BAgwBgEB/wIBADBBBgNV
# HR8EOjA4MDagNKAyhjBodHRwOi8vY3JsLnZlcmlzaWduLmNvbS9UaGF3dGVUaW1l
# c3RhbXBpbmdDQS5jcmwwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQD
# AgEGMCQGA1UdEQQdMBukGTAXMRUwEwYDVQQDEwxUU0EyMDQ4LTEtNTMwDQYJKoZI
# hvcNAQEFBQADgYEASmv56ljCRBwxiXmZK5a/gqwB1hxMzbCKWG7fCCmjXsjKkxPn
# BFIN70cnLwA4sOTJk06a1CJiFfc/NyFPcDGA8Ys4h7Po6JcA/s9Vlk4k0qknTnqu
# t2FB8yrO58nZXt27K4U+tZ212eFX/760xX71zwye8Jf+K9M7UhsbOCf3P0owggSn
# MIIDj6ADAgECAgphnWDwAAAAAAACMA0GCSqGSIb3DQEBBQUAMH4xCzAJBgNVBAYT
# AkxWMRUwEwYDVQQKEwxTeXNhZG1pbnMgTFYxHDAaBgNVBAsTE0luZm9ybWF0aW9u
# IFN5c3RlbXMxOjA4BgNVBAMTMVN5c2FkbWlucyBMViBDbGFzcyAxIFJvb3QgQ2Vy
# dGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTAwNDE0MTc0MTE2WhcNMjAwNDE0MTYy
# NTU1WjByMQswCQYDVQQGEwJMVjEVMBMGA1UEChMMU3lzYWRtaW5zIExWMRwwGgYD
# VQQLExNJbmZvcm1hdGlvbiBTeXN0ZW1zMS4wLAYDVQQDEyVTeXNhZG1pbnMgTFYg
# SW50ZXJuYWwgQ2xhc3MgMSBTdWJDQS0xMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
# MIIBCgKCAQEAuHHw5SbkYZip0ZeLh2vKLXT6U5FHwKZDWGhqD5fFRKvMdwbhcDOj
# WDkMFLAGAOaut0nRsdtWn59vghcZxbHQGNaB1otcnL9cVgliGKaKiP/i3GbXwpOC
# RIOeVoldKpSOR1qlN8AWTXUXpjRBUp5Dgymi0Cnj7kKpn1w45Iea49oIHGUM8v64
# NHrpY6rv9EQDyE98/qjMMpHZkJlOAeGm+mL1bgyGWGg0kXyBYOZ/e7xCOia70u0+
# t5aUdWgAx2SSIuUholnyBStGMPcPrJtUVHk9Ygdc/W8Dg7bZQPFGDioPvYNI35v6
# fceKi7cSgtwj8xqRqG7cynfqx2lnqSLFjQIDAQABo4IBMTCCAS0wEAYJKwYBBAGC
# NxUBBAMCAQAwHQYDVR0OBBYEFBv6XnMtZxNcztMO5uh6qWCMC2P8MBkGCSsGAQQB
# gjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/
# MB8GA1UdIwQYMBaAFE1IjcunX0Cos22iqY5OcfxPFhnUMDYGA1UdHwQvMC0wK6Ap
# oCeGJWh0dHA6Ly93d3cuc3lzYWRtaW5zLmx2L3BraS9yY2EtMS5jcmwwaAYIKwYB
# BQUHAQEEXDBaMDEGCCsGAQUFBzAChiVodHRwOi8vd3d3LnN5c2FkbWlucy5sdi9w
# a2kvcmNhLTEuY3J0MCUGCCsGAQUFBzABhhlodHRwOi8vb2NzcC5zeXNhZG1pbnMu
# bHYvMA0GCSqGSIb3DQEBBQUAA4IBAQCscUpz7yWwjkKRDmaolN9o0HjU6FvRfXAz
# EkL9JuymyDN/fvFfCHqqM49GNGAlh2ESemHisfS2Gf/dS0B8uSYSxiaNH8RSOOK1
# Tr8xvr+W/2vsVBiYFA0/SciJStBjBrcOKhwy2zW/dQMOEX86qPyEKqGAR1gsyNsO
# yABSBFCRsK3Tw+tlbRXldyj2pYBt1XxHuzPiZMA1Zz8O4rwcJRNLD6KNi49K49c7
# S1/9GEyT31TRTAx08VgLzLZ6kCSToGHM/mLeNUpW2ondzje6nqdBmxRHg++wrAKX
# 05DRuRri8MAVtaBwHxgQb+RO6KqZNoSVHZJ/0b7SSaZQgQW66zXXMIIE0zCCA7ug
# AwIBAgIKYTydVQAAAAAAEzANBgkqhkiG9w0BAQUFADByMQswCQYDVQQGEwJMVjEV
# MBMGA1UEChMMU3lzYWRtaW5zIExWMRwwGgYDVQQLExNJbmZvcm1hdGlvbiBTeXN0
# ZW1zMS4wLAYDVQQDEyVTeXNhZG1pbnMgTFYgSW50ZXJuYWwgQ2xhc3MgMSBTdWJD
# QS0xMB4XDTEwMDQxNTE3NDA1NloXDTE1MDQxNDE3NDA1NlowWjELMAkGA1UEBxMC
# TFYxFTATBgNVBAoTDFN5c2FkbWlucyBMVjEcMBoGA1UECxMTSW5mb3JtYXRpb24g
# U3lzdGVtczEWMBQGA1UEAxMNVmFkaW1zIFBvZGFuczCCASIwDQYJKoZIhvcNAQEB
# BQADggEPADCCAQoCggEBAIcw8V5Bjn11ZLAG/GhiQ+y7CEpYt/Z6alFQdkBNPSHu
# WMC+ebPUQgEky57JOeo9DeXUv8+rOxOt1thptEDEIZ5tJQHhSxLEfoxLSHQCkn4O
# mQXk6q/UZWfvktv73k2Rq+xdtvmMFTH4xqvhddVma6MeKEBWPu5URhT7wvnI+cGh
# 5TeE8kmErq/E2hVIOeZ1r85IC1naBiV4VxJMMQkePswBTYCAcjYCT1UU8GihEdgq
# 8dClNmsE2a/dYNoTktxIGUk2wFnP/ptSEtrlzhczKa5WDlGeuMx62lfRuTfzq+gO
# zk4JDleud6NPqqIijh/iYBS+qJ+4GexYPL0wZCdTPVUCAwEAAaOCAYEwggF9MDsG
# CSsGAQQBgjcVBwQuMCwGJCsGAQQBgjcVCJadTYWSsni9nzyF6Ox0gs7YRHqCqvdC
# h+fENgIBZAIBAzAfBgNVHSUEGDAWBgorBgEEAYI3CgMMBggrBgEFBQcDAzAOBgNV
# HQ8BAf8EBAMCB4AwKQYJKwYBBAGCNxUKBBwwGjAMBgorBgEEAYI3CgMMMAoGCCsG
# AQUFBwMDMB0GA1UdDgQWBBQsddpa07a5NYAClLLmLzGiK9dXmTAfBgNVHSMEGDAW
# gBQb+l5zLWcTXM7TDuboeqlgjAtj/DA3BgNVHR8EMDAuMCygKqAohiZodHRwOi8v
# d3d3LnN5c2FkbWlucy5sdi9wa2kvcGljYS0xLmNybDBpBggrBgEFBQcBAQRdMFsw
# MgYIKwYBBQUHMAKGJmh0dHA6Ly93d3cuc3lzYWRtaW5zLmx2L3BraS9waWNhLTEu
# Y3J0MCUGCCsGAQUFBzABhhlodHRwOi8vb2NzcC5zeXNhZG1pbnMubHYvMA0GCSqG
# SIb3DQEBBQUAA4IBAQBJ2bGbZu+3T+0ZJXOTSjQfXfAcBzzqHM+R16Up6qXkjUnQ
# gguINT/1Ktqr3y7SdPGkyHZytqz0ABwr/hgZ1bdl4WaV9xpy4oJni7wU4Gq6Mh8Q
# zvhGwrQmQifbRyumM/EKMzyYZU+KkD7TAHoN1CiEGhiEyK+9OVaQNxAxwO3jmWWN
# cj2Q86YrV7r+XzkAU/N6gSeVUXii5eGA30wQNnCWQd2cTzL9tHdNH8t4qKN9Lhij
# t0EoxGEZYGDniROmIYlIwZUj6nU/XsmeHyJ5vpcvBxu12AVQMNIUY+HzCLStKnCy
# Sd1htmJBemlaam0OPeYp7QSUKgwzm1+gK813GUzKMYIDpTCCA6ECAQEwgYAwcjEL
# MAkGA1UEBhMCTFYxFTATBgNVBAoTDFN5c2FkbWlucyBMVjEcMBoGA1UECxMTSW5m
# b3JtYXRpb24gU3lzdGVtczEuMCwGA1UEAxMlU3lzYWRtaW5zIExWIEludGVybmFs
# IENsYXNzIDEgU3ViQ0EtMQIKYTydVQAAAAAAEzAJBgUrDgMCGgUAoHgwGAYKKwYB
# BAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAc
# BgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUin+n
# vVp8jJLwSWikhJbHlH09Hy4wDQYJKoZIhvcNAQEBBQAEggEAGtWm9io5wvAkVWs1
# 2cHs9S9aVXvfJCSLC+EmgdTIkjms/F4/XyiETdaZw5Klh4gTunXllVEUiGzgJY3v
# q7uIAqtfanu91ttSalsaj5PKHBHpmSRTgAIxZ+lsnXpwav9dOFGgcthUgVXKlsrb
# sgKOqBYeNPN8H2aYjEyhiHEcN+Jo7hYUmzGJzZ1LCwMEpHdWartzgYOB9bdEFBZx
# DOclp4NRgP+Gp/NncXJ/xuO3/PeEZzN2LvI4SgA+wa4+Bn3zu5OuQpNBbI2gJhOg
# GERJDOSN0GoVCKYMHHetA5m4K/zxUzNWzsQiyB2Oj/FXj7dBMbS48mDs1V9k4bUw
# 66FdlKGCAX8wggF7BgkqhkiG9w0BCQYxggFsMIIBaAIBATBnMFMxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5WZXJpU2lnbiwgSW5jLjErMCkGA1UEAxMiVmVyaVNpZ24g
# VGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQQIQOCXX+vhhr570kOcmtdZa1TAJBgUr
# DgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUx
# DxcNMTAwNDE4MDg0MTE0WjAjBgkqhkiG9w0BCQQxFgQUWolmHMfK7jXucZQKpMkl
# ghPrawowDQYJKoZIhvcNAQEBBQAEgYANJxNrwTB2xRLj/edK+jJOGyH33jlrT3AI
# DVCgUvAQlC7uD25l8vxKqsowovDMRodGPZqdnNGE3oLz6K4sS3RrnDTrRr6jxPwK
# bnxTDJ6oCP2ZgcwFWnxHGzH6QeLzReuy5VmGXlambWCmQgdi6OYfvCQ0uE6Kl9/a
# SBQE1dd++Q==
# SIG # End signature block
