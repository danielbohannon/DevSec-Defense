# Copyright (c) 2011 Justin Dearing <zippy1981@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# The authoritative version of this script lives at: https://gist.github.com/1166670


#TODO: Get The PInvoke calls to actually use these ENUMS.
Add-Type -TypeDefinition @"
namespace PInvoke {
	public enum ODBC_Constants {
		ODBC_ADD_DSN = 1,
		ODBC_CONFIG_DSN,
		ODBC_REMOVE_DSN,
		ODBC_ADD_SYS_DSN,
		ODBC_CONFIG_SYS_DSN,
		ODBC_REMOVE_SYS_DSN,
		ODBC_REMOVE_DEFAULT_DSN,
	};

	public enum SQL_RETURN_CODE {
		SQL_ERROR = -1,
		SQL_INVALID_HANDLE = -2,
		SQL_SUCCESS = 0,
		SQL_SUCCESS_WITH_INFO = 1,
		SQL_STILL_EXECUTING = 2,
		SQL_NEED_DATA = 99,
		SQL_NO_DATA = 100
	}
}
"@;

$signature = @'
[DllImport("ODBCCP32.DLL",CharSet=CharSet.Unicode, SetLastError=true)]
public static extern int SQLConfigDataSource 
	(int hwndParent, int fRequest, string lpszDriver, string lpszAttributes);

[DllImport("odbccp32", CharSet=CharSet.Auto)]
public static extern int SQLInstallerError(int iError, ref int pfErrorCode, StringBuilder lpszErrorMsg, int cbErrorMsgMax, ref int pcbErrorMsg);
'@;

Add-Type -MemberDefinition $signature -Name Win32Utils -Namespace PInvoke -Using PInvoke,System.Text;

Function Create-MDB ([string] $fileName, [switch] $DeleteIfExists = $false) {
	# We need to pass the full path of the file to SQLConfigDataSource(). Relative paths will fail.
	$fileName = [System.IO.Path]::GetFullPath($fileName);
	if ($DeleteIfExists -and (Test-Path $fileName)) {
		Remove-Item $fileName;
	}
	[string] $attrs = [string]::Format("CREATE_DB=`"{0}`" General`0", $fileName);
	# For 32 bit processes we use the older ODBCJT32.dll driver
	[string] $driver = 'Microsoft Access Driver (*.mdb)';
	# There is no 64 bit version of this driver so we use ACEODBC.dll
	# This requires the Microsoft Access Database Engine 2010 Redistributable
	# http://www.microsoft.com/download/en/details.aspx?id=13255
	if ([IntPtr]::Size -eq 8) { 
		$driver = 'Microsoft Access Driver (*.mdb, *.accdb)';
	}
	# TODO: Interogate the registry (HKEY_LOCAL_MACHINE\\SOFTWARE\\ODBC\\ODBCINST.INI) to search for which driver to use.
	# TODO: If no driver found use the 64 bit ones
	[int] $retCode = [PInvoke.Win32Utils]::SQLConfigDataSource(
		0, [PInvoke.ODBC_Constants]::ODBC_ADD_DSN, 
		$driver, $attrs);
	if ($retCode -eq 0) {
		[int] $errorCode = 0 ;
		[int]  $resizeErrorMesg = 0 ;
		$sbError = New-Object System.Text.StringBuilder(512);
	[PInvoke.Win32Utils]::SQLInstallerError(1, [ref] $errorCode, $sbError, $sbError.MaxCapacity, [ref] $resizeErrorMesg);
	if ($sbError.ToString() -eq 'Component not found in the registry') {
		$sbError = New-Object System.Text.StringBuilder(512);
		if ([intptr]::Size -eq 8) { $sbError.Append("Their appears to be no 64 bit MS Access Driver installed. Please install a 64 bit access driver or run this script from a 32 bit powershell instance"); }
		if ([intptr]::Size -eq 4) { $sbError.Append("Their appears to be no 32 bit MS Access Driver installed. Please install a 32 bit access driver or run this script from a 64 bit powershell instance"); }
		}
		throw New-Object ApplicationException([string]::Format("Cannot create file: {0}. Error: {1}", $fileName, $sbError));
	}
}


Create-Mdb ".\\foo.mdb" -DeleteIfExists

