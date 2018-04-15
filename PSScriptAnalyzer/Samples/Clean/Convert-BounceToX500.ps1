# $Id: Convert-BounceToX500.ps1 608 2010-10-31 02:12:44Z jon $
# $Revision: 608 $

#.Synopsis
#  Convert Bounce to X500
#.Description
#  Convert URL Encoded address in a Bounce message to an X500 address
#  that can be added as an alias to the mail-enabled object
#.Parameter bounceAddress
#  URL Encoded bounce message address
#
#.Example
#  Convert-BounceToX500 "IMCEAEX-_O=CONTOSO_OU=First+20Administrative+20Group_cn=Recipients_cn=john+5Fjacob+2Esmith@contoso.com"

[CmdletBinding()]
PARAM (
	[Parameter(Mandatory=$true)][string]$bounceAddress
)

Add-Type -AssemblyName System.Web|Out-Null

$bounceAddress = $bounceAddress -Replace "%2B","%" # This is a urlEncoded "+"
$bounceAddress = $bounceAddress -Replace "%3D","="
$bounceAddress = $bounceAddress -Replace "\\+","%"
$bounceAddress = $bounceAddress -Replace "_O=","/O="
$bounceAddress = $bounceAddress -Replace "_OU=","/OU="
$bounceAddress = $bounceAddress -Replace "_CN=","/CN="

if([Web.HttpUtility]::UrlDecode($bounceAddress) -match "(/o=.*)@[\\w\\d.]+$"){$matches[1]}

