####################################################################################
#PoSH script to check if a server is up and if it is check for a service.
#If the service isn't running, start it and send an email
# JK - 7/2009
####################################################################################

$erroractionpreference = "SilentlyContinue"

$i = "testserver" 	#Server Name
$service = "spooler" 	#Service to monitor

 $ping = new-object System.Net.NetworkInformation.Ping
    $rslt = $ping.send($i)
        if ($rslt.status.tostring() –eq "Success")
{
        $b = get-wmiobject win32_service -computername $i -Filter "Name = '$service'"

	If ($b.state -eq "stopped")
	{
	$b.startservice()

	$emailFrom = "services@yourdomain.com"
	$emailTo = "you@yourdomain.com"
	$subject = "$service Service has restarted on $i"
	$body = "The $service service on $i has crashed and been restarted"
	$smtpServer = "xx.yourdomain.com"
	$smtp = new-object Net.Mail.SmtpClient($smtpServer)
	$smtp.Send($emailFrom, $emailTo, $subject, $body)
	}
	
	else
	{exit}

}

else
{exit}
