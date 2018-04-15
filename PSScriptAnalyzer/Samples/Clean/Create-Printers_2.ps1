###########################################################################"
#
# NAME: Create-Printers.ps1
#
# AUTHOR: Jan Egil Ring
# EMAIL: jan.egil.ring@powershell.no
# BLOG: http://blog.powershell.no
#
# COMMENT: Simple script to bulk-create printers on a print-server. Printers are imported from a csv-file.
#          Running the script from Windows Server 2003 returns an access denied error, possibly due to the impersonation-model in Windows Server 2003.
#          Created and tested from Windows Server 2008 against a remote Windows Server 2003 print-server.
#          Should work from Windows Vista, Windows 7, Windows Server 2008 and Windows Server 2008 R2 against remote print-servers (2000/2003/2008/2008 R2)
#
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the creator, owner above has no warranty, obligations,
# or liability for such use.
#
# VERSION HISTORY:
# 1.0 07.11.2009 - Initial release
#
###########################################################################"



function CreatePrinter {
$server = $args[0]
$print = ([WMICLASS]"\\\\$server\\ROOT\\cimv2:Win32_Printer").createInstance() 
$print.drivername = $args[1]
$print.PortName = $args[2]
$print.Shared = $true
$print.Sharename = $args[3]
$print.Location = $args[4]
$print.Comment = $args[5]
$print.DeviceID = $args[6]
$print.Put() 
}

function CreatePrinterPort {
$server =  $args[0] 
$port = ([WMICLASS]"\\\\$server\\ROOT\\cimv2:Win32_TCPIPPrinterPort").createInstance() 
$port.Name= $args[1]
$port.SNMPEnabled=$false 
$port.Protocol=1 
$port.HostAddress= $args[2] 
$port.Put() 
}

$printers = Import-Csv c:\\printers.csv

foreach ($printer in $printers) {
CreatePrinterPort $printer.Printserver $printer.Portname $printer.IPAddress
CreatePrinter $printer.Printserver $printer.Driver $printer.Portname $printer.Sharename $printer.Location $printer.Comment $printer.Printername
}
