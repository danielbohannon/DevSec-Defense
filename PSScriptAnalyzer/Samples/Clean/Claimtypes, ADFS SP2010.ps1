Add-PSSnapin -Name Microsoft.SharePoint.PowerShell

$claim = New-SPClaimTypeMapping -IncomingClaimType "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" -IncomingClaimTypeDisplayName "EmailAddress" -SameAsIncoming

$claim2 = New-SPClaimTypeMapping -IncomingClaimType "http://schemas.microsoft.com/ws/2008/06/identity/claims/role" -IncomingClaimTypeDisplayName "Role" -SameAsIncoming

$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2("C:\\path-to-certificate\\certificate.cer")

$realm = "urn:" + $env:ComputerName + ":adfs"

$signinurl = "https://signin.domain.com/adfs/ls/"

$ap = New-SPTrustedIdentityTokenIssuer -Name "ADFS20Server" -Description "ADFS 2.0 Federated Server" -Realm $realm -ImportTrustCertificate $cert -ClaimsMappings $claim,$claim2 -SignInUrl $signinurl -IdentifierClaim $claim.InputClaimType

$ap.AddClaimTypeInformation($claim)
$ap.AddClaimTypeInformation($claim2)

$uri = new-object System.Uri("https://someuri.domain.com/")

$ap.ProviderRealms.Add($uri, “urn:" + $env:ComputerName + ":adfssite”)

$ap.Update()
