#alias,addnewemailaddress

import-csv .\\source.csv | foreach {
$user = Get-Mailbox $_.alias
$user.emailAddresses+= $_.addnewemailaddress
$user.primarysmtpaddress = $_.addnewemailaddress
Set-Mailbox $user -emailAddresses $user.emailAddresses
set-Mailbox $user -PrimarySmtpAddress $user.primarysmtpaddress
}
