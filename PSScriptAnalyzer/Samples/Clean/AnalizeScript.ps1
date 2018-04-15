<#
.SYNOPSIS
	Analyzes script and gives starting lines & columns of script components 
.DESCRIPTION
 	AnalizeScript opens a dialog box for user selection; checks that input is 
	a powershell script; parses and agrigates the script components into the 
    	following tokens:

	      Unknown(s)
	      Command(s)
	      CommandParameter(s)
	      CommandArgument(s)
	      Variable(s)
	      Member(s)
	      LoopLabel(s)
	      Attribute(s)
	      Keyword(s)
	      LineContinuation(s) 

.LINK
		None
.NOTES
  Name:         AnalizeScript.ps1
  Author:       Paul A. Drinnon
  Date Created: 03/24/2011
  Date Revised: - (New Release)
  Version:      1.0
  History:      1.0 

  This script can be altered to output other "Types" of tokenized content

  Below is a complete list
  
                Types
  ______________________________________
                Name   Example /   Value
                       Comment  
  __________________  ___________  _____
             Unknown                 0
             Command                 1
    CommandParameter                 2
     CommandArgument                 3
              Number                 4
              String                 5
            Variable      -$!        6
              Member                 7
           LoopLabel                 8
           Attribute                 9
                Type                10
            Operator  (-+*/=|...)   11
          GroupStart      ({        12
            GroupEnd      )}        13
             Keyword                14
             Comment                15
  StatementSeparator                16
             NewLine                17
    LineContinuation                18
            Position                19


  requires -Version 2.0
  ** Licensed under a Creative Commons Attribution 3.0 License ** 

#>

Add-Type -TypeDefinition @"
using System;
using System.Windows.Forms;

public class WindowWrapper : IWin32Window {
    private IntPtr _hWnd;
    
    public WindowWrapper(IntPtr handle) {
        _hWnd = handle;
    }
    public IntPtr Handle {
        get { return _hWnd; }
    }
}

"@ -ReferencedAssemblies "System.Windows.Forms.dll"

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

$handle = [System.Diagnostics.Process]::GetCurrentProcess().MainWindowHandle
$owner = New-Object WindowWrapper -ArgumentList $handle

function Select-File
{
    param (
        [String]$Title = "Enter a Windows PowerShell script", 
        [String]$InitialDirectory = $home,                                        
        [String]$Filter = "All Files(*.*)|*.*"
    )
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = $filter
    $dialog.InitialDirectory = $initialDirectory
    $dialog.ShowHelp = $true
    $dialog.Title = $title
    $result = $dialog.ShowDialog($owner)
    if ($result -eq "OK") {
        return $dialog.FileName
    }
    else {
        Write-Error "Operation cancelled by user."
    }
}

function TokenName-Count ($file, $str)
{
    $content = gc $file
    $a = [System.Management.Automation.PsParser]::Tokenize($content, [ref] $null) |
        ? { $_.Type -eq $str } |  Measure-Object | select Count
    $su = $str.ToUpper() + "S"    
    "$su`t`t$a"
}

function CustomTable ($file, $str)
{
    $content = gc $file
    [System.Management.Automation.PsParser]::Tokenize($content, [ref] $null) |
        ? { $_.Type -eq $str } |  ft content, startline, startcolumn -auto
}

$selectPSfile = ""
while (-!($selectPSfile -match ".ps1|.psm1|.psd1|.ps1xml")) {
    $selectPSfile = Select-File
}

$TokenNames =  `
    "Unknown", `
    "Command", `
    "CommandParameter", `
    "CommandArgument",  `
    "Variable", `
    "Member",   `
    "LoopLabel",`
    "Attribute",`
    "Keyword",  `
    "LineContinuation" 

$date = (Get-Date).ToShortDateString()

"`n$selectPSfile`t`t`t`t$date`n"
$TokenNames | foreach {
    [string]$s = $_
    TokenName-Count $selectPSfile $s
    CustomTable $selectPSfile $s
}
