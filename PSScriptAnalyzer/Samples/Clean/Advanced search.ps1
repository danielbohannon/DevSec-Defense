<#
Using examples:
 Example 1:
   Get-ItemPlace *.log -h
 It will search all (including that have "Hidden" attribute) *.log files on local drives.

 Example 2:
   Get-ItemPlace sysinternals hkcu:\\
 This command invoke search Sysinyetrnals key into HKEY_CURRENT_USER.
#>

function Get-ItemPlace {
  param ([string]$wildcard, `
         [array]$path = $(gdr | % {$_.Root} | ? {$_ -like '*:\\' -and $_ -ne 'A:\\'}), `
         [switch]$hidden)

  if ($path -match "(HKCU|HKLM)\\:\\\\") {
    dir $path -r -i $wildcard -ea 0 | % {$_.Name}
  }
  else {
    dir $path -r -i $wildcard -fo:$hidden -ea 0 | % {$_.FullName}
  }
}
