# Script:	Exch2010QueueMonitor.ps1
# Purpose:  This script can be set as a scheduled task to run every 30minutes and will monitor all exchange 2010 queue's. If a threshold of 10 is met an 
#			output file with the queue details will be e-mailed to all intended admins listed in the e-mail settings
# Author:   Paperclips (The Dark Lord)
# Email:	magiconion_M@hotmail.com
# Date:     May 2011
# Comments: Lines 27, 31-35 should be populated with your own e-mail settings
# Notes:    
#			- tested with Exchange 2010 SP1
#			- The log report output file will be created under "c:\\temp\\qu.txt"

$s = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ukvms-wcas2/PowerShell/ -Authentication Kerberos
Import-PSSession $s

Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010
. $env:ExchangeInstallPath\\bin\\RemoteExchange.ps1
Connect-ExchangeServer -auto

$filename = “c:\\temp\\qu.txt”
Start-Sleep -s 10
if (Get-ExchangeServer | Where { $_.isHubTransportServer -eq $true } | get-queue | Where-Object { $_.MessageCount -gt 10 })

{

Get-ExchangeServer | Where { $_.isHubTransportServer -eq $true } | get-queue | Where-Object { $_.MessageCount -gt 10 } | Format-Table -Wrap -AutoSize | out-file -filepath c:\\temp\\qu.txt
Start-Sleep -s 10

$smtpServer = “xxx.xxx.xxx.xxx”
$msg = new-object Net.Mail.MailMessage
$att = new-object Net.Mail.Attachment($filename)
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$msg.From = “Monitor@contoso.com”
$msg.To.Add("admin1@mycompany.com")
#$msg.To.Add("admin2@mycompany.com")
#$msg.To.Add("admin3@mycompany.com")
#$msg.To.Add("admin4@mycompany.com")
$msg.Subject = “CAS SERVER QUEUE THRESHOLD REACHED - PLEASE CHECK EXCHANGE QUEUES”
$msg.Body = “Please see attached queue log file for queue information”
$msg.Attachments.Add($att)
$smtp.Send($msg)

}
