#==================================================================================================
#              File Name : CiscoInventory.ps1
#        Original Author : Kenneth C. Mazie (kcmjr)
#            Description : As written it will poll Cisco routers and switches and if the snmp OID's
#                        :  match it will pull out model, serial, and IOS version.  The resulting 
#                        :  spreadsheet contains IP, host name, serial, model, IOS version, and
#                        :  rack location.
#
#                  Notes : Normal operation is with no command line options. 
#                        :  This PowerShell script was cobbled together from various sources around 
#                        :  the Internet. It was inspired by an article by David Davis over at ZDNet
#                        :  but came about because I had yet to find a PowerShell script to do what
#                        :  it does in any of my searches.  
#                        :
#                        : The script requires net-snmp tools. The script will first attempt to 
#                        :  ping a target, then process it if the ping succeeds. Our devices use a 
#                        :  standard naming convention of 12 characters. The script parses the host 
#                        :  name and determines the location of the device by what it finds in 
#                        :  character position 2 and 3 so you may want to remove that section or 
#                        :  edit it for your needs.
#                        :
#                        : The script creates an excel spreadsheet and saves it as a date & time 
#                        :  stamped file on the root of C:, so you need Excel installed.  Target 
#                        :  systems are read from a file named "devices.txt" that should reside in
#                        :  the same folder as the script and contain a list of target IP addresses,
#                        :  one per line.
#                        :
#               Warnings : None
#                        :
#                  Legal : Script provided "AS IS" without warranties or guarantees of any
#                        :  kind.  USE AT YOUR OWN RISK.  Public domain, no rights reserved.
#                        :  Please keep this header in tact if at all possible.
#                        : 
#                Credits : Code snippets and/or ideas came from many sources including but 
#                        : 
#         Last Update by : Kenneth C. Mazie 
#        Version History : v1.0 - 06-24-10 - Original 
#         Change History : v1.1 - 
#
#=======================================================================================

Clear-Host

#--[ Global presets ]----------------------------------
$Invocation = (Get-Variable MyInvocation -Scope 0).Value
#$ScriptPath = Split-Path $Invocation.MyCommand.Path
$strExe = "f:\\usr\\bin\\snmpget.exe"    #--[ Set the location of the net-snmp tools bin folder ]---------
$strCommunity = "Public"              #--[ set your community string ]---------

#--[ Assorted Excel presets settings ]----------------------------------
$xlAutomatic = -4105     # 
$xlBottom = -4107        # Text alignment bottom
$xlCenter = -4108        # Text alignment center
$xlContext = -5002       # Text alignment
$xlContinuous = 1        # 
$xlDiagonalDown = 5      # Cell line position
$xlDiagonalUp = 6        # Cell line position
$xlEdgeBottom = 9        # Cell line position
$xlEdgeLeft = 7          # Cell line position
$xlEdgeRight = 10        # Cell line position
$xlEdgeTop = 8           # Cell line position
$xlInsideHorizontal = 12 # Cell line position
$xlInsideVertical = 11   # Cell line position
$xlDash = -4115          # Dashed line
$xlDashDot = 4           # Alternating dashes and dots
$xlDashDotDot = 5        # Dash followed by two dots
$xlDot = -4118           # Dotted line
$xlDouble = -4119        # Double line
$xlNone = -4142          # No line
$xlSlantDashDot = 13     # Slanted dashes.
$xlThick = 4             # Thick line
$xlThin = 2              # Thin line
$sortCol = 5             # what column to place sort code in

#--[ Create Spreadsheet ]-------------------------------
$Excel = New-Object -comobject Excel.Application
$Excel.Visible = $True
$Excel = $Excel.Workbooks.Add(1)
$WorkSheet = $Excel.Worksheets.Item(1)
$WorkSheet.Cells.Item(1,1) = "Target IP"
$WorkSheet.Cells.Item(1,2) = "Hostname"
$WorkSheet.Cells.Item(1,3) = "Model #"
$WorkSheet.Cells.Item(1,4) = "Serial #"
$WorkSheet.Cells.Item(1,5) = "IOS Ver"
$WorkSheet.Cells.Item(1,6) = "Location"
$Workbook = $WorkSheet.UsedRange
$WorkBook.Interior.ColorIndex = 8
$WorkBook.Font.ColorIndex = 11
$WorkBook.Font.Bold = $True
$WorkBook.EntireColumn.AutoFit()

#--[ Formatting ]----------------------------
$Col = 1
while ($Col -le 6){
	$Edge = 7
	while ($Edge -le 10){
		$WorkSheet.Cells.Item(1,$Col).Borders.Item($Edge).LineStyle = 1
		#$WorkSheet.Cells.Item(1,$Col).Borders.Item($Edge).Weight = 4   #--[ uncomment to make borders bold ]---------
		$Edge++
	}
	$Col++
}

#$arrDevices = @("192.168.10.2","192.168.10.252")
$arrDevices = Get-Content ($ScriptPath + "\\devicelist.txt")

$intRow = 1
$count = 0

# NOTE: Cisco MIB for chassis serial # = mib-2.47.1.1.1.1.11.1001
# NOTE: Cisco MIB for chassis model # = mib-2.47.1.1.1.1.13.1001
# NOTE: Cisco MIB for IOS Ver = mib-2.47.1.1.1.1.13.1001
# NOTE: Cisco MIB for hostname = sysName.0

#--[ populate spreadsheet with data ]------------------
foreach ($strTarget in $arrDevices){ #--[ Cycle through targets ]--------
   $intRow = $intRow + 1 
   $WorkSheet.Cells.Item($intRow,1) = $strTarget #--[ Place Target IP in current row, column A ]----------
   Write-Host "Processing..... " $strTarget
   if (test-connection $strTarget) {
		if ($count = 5) {$count = 0}
		
		$strSerial = iex "cmd.exe /c `"$strExe -v 1 -c $strCommunity $strTarget mib-2.47.1.1.1.1.11.1001`""
		$strModel = iex "cmd.exe /c `"$strExe -v 1 -c $strCommunity $strTarget mib-2.47.1.1.1.1.13.1001`""
		$strIOS = iex "cmd.exe /c `"$strExe -v 1 -c $strCommunity $strTarget mib-2.47.1.1.1.1.9.1001`""
		$strHostName = iex "cmd.exe /c `"$strExe -v 1 -c $strCommunity $strTarget sysName.0`""
		
		#--[ If we get back a model place it in current row, column C ]----------
		if ($strModel.Length -gt 1) {$WorkSheet.Cells.Item($intRow,3) = ($strModel.Split('"'))[1]} 
		
		#--[ If we get back a serial # place it in current row, column D ]----------
		if ($strSerial.Length -gt 1) {$WorkSheet.Cells.Item($intRow,4) = ($strSerial.Split('"'))[1]}
		
		#--[ If we get back an IOS version place it in current row, column E ]----------
		if ($strIOS.Length -gt 1) {$WorkSheet.Cells.Item($intRow,5) = ($strIOS.Split('"'))[1]}
		
		#--[ If we get back a hostname place it in current row, column B ]----------
		if ($strHostname.Length -gt 1) {
		$strHostName = ($strHostName.Split(' '))[3]
		$WorkSheet.Cells.Item($intRow,2) = $strHostName 
		switch($strHostName.substring(1,2)) {
		   "00" { $errorcode = 'Rack 00' }
		   "01" { $errorcode = 'Rack 01' }
		   "02" { $errorcode = 'Rack 02' }
		   "03" { $errorcode = 'Rack 03' }
		   "04" { $errorcode = 'Rack 04' }
		   "05" { $errorcode = 'Rack 05' }
		   "06" { $errorcode = 'Rack 06' }
		   "07" { $errorcode = 'Rack 07' }
		   "08" { $errorcode = 'Rack 08' }
		   "09" { $errorcode = 'Rack 09' }
		   "10" { $errorcode = 'Rack 10' }
		   "11" { $errorcode = 'Rack 11' }
		   "12" { $errorcode = 'Rack 12' }
		   "13" { $errorcode = 'Rack 13' }
		   "14" { $errorcode = 'Rack 14' }
           default { $errorcode = 'Unknown' }
        }  
        $WorkSheet.Cells.Item($intRow,6) = $errorcode #--[ Place location in current row, column F ]----------
	  }
   } 
else
{
   $WorkSheet.Cells.Item($intRow,2) = "Unreachable"       #--[ Place model # in current row, column B ]----------
		}
		
	$count = $count + 1
	if ($count =5) {$WorkBook.EntireColumn.AutoFit()}
}

	$WorkBook.EntireColumn.AutoFit() #--[ Adjust column width across used columns ]---------
	$WorkSheet.Cells.Item($intRow + 2, 1) = "DONE" 
	$strFilename = "c:\\CiscoInventory-{0:dd-MM-yyyy_HHmm}.xls" -f (Get-Date)  #--[ Places a date stamped spreadsheet in the root of C: ]------
	$Excel.SaveAs($StrFilename)
	Write-Host ("Output saved to " + $strFilename)
	Write-Host "Done..."


