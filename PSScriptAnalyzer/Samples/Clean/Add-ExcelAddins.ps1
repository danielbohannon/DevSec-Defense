###########################################################################"
#
# NAME: Add-ExcelAddins.ps1
#
# AUTHOR: Jan Egil Ring
# EMAIL: jan.egil.ring@powershell.no
#
# COMMENT: This script will check if the specified Microsoft Office Excel Addins are loaded, and if not load them.
#          Tested with PowerShell v2 and Microsoft Office Excel 2007, although it should work fine with PowerShell v1 and older
#	  versions of Microsoft Office Excel.
#
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the creator, owner above has no warranty, obligations,
# or liability for such use.
#
# VERSION HISTORY:
# 1.0 01.11.2009 - Initial release
#
###########################################################################"

$Addinfilename = 'Addin_01.xla'
$Addinfilepath = 'C:\\MyAddins\\'
$Excel = New-Object -ComObject excel.application
$ExcelWorkbook = $excel.Workbooks.Add()
if (($ExcelWorkbook.Application.AddIns | Where-Object {$_.name -eq $Addinfilename}) -eq $null) {
$ExcelAddin = $ExcelWorkbook.Application.AddIns.Add("$Addinfilepath$Addinfilename", $True)
$ExcelAddin.Installed = "True"
Write-Host "$Addinfilename added"}
else
{Write-Host "$Addinfilename already added"}
$Excel.Quit()
