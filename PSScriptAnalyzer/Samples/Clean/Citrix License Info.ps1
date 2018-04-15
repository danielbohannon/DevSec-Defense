###########################################
# Licence Checking Script for Citrix #
# Virtu-Al - http://teckinfo.blogspot.com/
###########################################

param( [string] $sendmailsched )

Function Sendemail ($LicTypeText, $InstalledLicNum, $InUseNum, $PercentageNum)
{
#Email options for automated emailed report
$smtpServer = "mysmtpserver.co.uk"

$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer)

$msg.From = "someone@mydomain.co.uk"
$msg.To.Add("me@mydomain.co.uk")
$msg.Subject = "Citrix License Server Stats"
$msg.Body = "The below is the current status of the license server:`n`nLicense Type: $LicTypeText`n`nInstalled Licences: $InstalledLicNum`n`nLicences In Use: $InUseNum`n`nPercentage: $PercentageNum%"

$smtp.Send($msg)
}

# Set licence server and temporary file
$licserver = "mylicserver.mydomain.co.uk"
$tempfile = "c:\\lictest.txt"

# Retrieve web page into a text file
$webClient = New-Object System.Net.WebClient
$webClient.credentials = New-Object system.net.networkcredential("usernametoaccesssite", "Password")
$webadd = "http://$licserver/lmc/current_usage/currentUsage.jsp"
$webClient.DownloadString($webadd) > $tempfile

# Find Line numbers of text
$Myline = Select-String -Path "$tempfile" -pattern "Enterprise"
$LicTypeLine = $Myline.LineNumber - 1
$InstalledLicLine = $LicTypeLine + 3
$InUseLine = $InstalledLicLine + 1
$PercentageLine = $LicTypeLine +6


# Read line for Installed Licences
$LicTypeRAW = @(gc $tempfile)[$LicTypeLine]
$LicTypeText = [regex]::match($LicTypeRAW,'(?<=).+(?=)').value
#Write "License Type: $LicTypeText"

# Read line for Installed Licences
$InstalledLicRAW = @(gc $tempfile)[$InstalledLicLine]
$InstalledLicNum = [regex]::match($InstalledLicRAW,'(?<=).+(?=)').value
#Write "Installed Licences: $InstalledLicNum"

# Read line for Licences in use
$InUseRAW = @(gc $tempfile)[$InUseLine]
$InUseNum = [regex]::match($InUseRAW,'(?<=).+(?=)').value
#Write "Licences In Use: $InUseNum"

# Read Percentage used line
$PercentageRAW = @(gc $tempfile)[$PercentageLine]
$PercentageNum = [regex]::match($PercentageRAW,'[0-9]+').value
#Write "Percentage: $PercentageNum%"

# Check the usage and send an email if over 90%
if ($PercentageNum -lt 90)
{
}
else
{
Sendemail $LicTypeText $InstalledLicNum $InUseNum $PercentageNum
}

if ($sendmailsched -eq "send")
{
Sendemail $LicTypeText $InstalledLicNum $InUseNum $PercentageNum
}

# Remove the temporary contents file
Remove-Item $tempfile
