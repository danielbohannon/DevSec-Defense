#Requires -Version 2.0
## Automatically load functions from scripts on-demand, instead of having to dot-source them ahead of time, or reparse them from the script every time.
## Provides significant memory benefits over pre-loading all your functions, and significant performance benefits over using plain scripts.  Can also *inject* functions into Modules so they inherit the module scope instead of the current local scope.
## Please see the use example in the script below

## Version History
## v 1.0  - 2010.10.20
##          Officially out of beta -- this is working for me without problems on a daily basis.
##          Renamed functions to respect the Verb-Noun expectations, and added Export-ModuleMember
## beta 8 - 2010.09.20
##          Finally fixed the problem with aliases that point at Invoke-Autoloaded functions!
## beta 7 - 2010.06.03
##          Added some help, and a function to force loading "now"
##          Added a function to load AND show the help...
## beta 6 - 2010.05.18
##          Fixed a bug in output when multiple outputs happen in the END block
## beta 5 - 2010.05.10
##          Fixed non-pipeline use using $MyInvocation.ExpectingInput
## beta 4 - 2010.05.10
##          I made a few tweaks and bug fixes while testing it's use with PowerBoots.
## beta 3 - 2010.05.10
##          fix for signed scripts (strip signature)
## beta 2 - 2010.05.09
##          implement module support
## beta 1 - 2010.04.14
##          Initial Release


## To use:
## 1) Create a function. To be 100% compatible, it should specify pipeline arguments
## For example:
<#
function Skip-Object {
param( 
   [int]$First = 0, [int]$Last = 0, [int]$Every = 0, [int]$UpTo = 0,  
   [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
   $InputObject
)
begin {
   if($Last) {
      $Queue = new-object System.Collections.Queue $Last
   }
   $e = $every; $UpTo++; $u = 0
}
process {
   $InputObject | where { --$First -lt 0 } | 
   foreach {
      if($Last) {
         $Queue.EnQueue($_)
         if($Queue.Count -gt $Last) { $Queue.DeQueue() }
      } else { $_ }
   } |
   foreach { 
      if(!$UpTo) { $_ } elseif( --$u -le 0) {  $_; $U = $UpTo }
   } |
   foreach { 
      if($every -and (--$e -le 0)) {  $e = $every  } else { $_ } 
   }
}
}
#>

## 2) Put the function into a script (for our example: C:\\Users\\${Env:UserName}\\Documents\\WindowsPowerShell\\Scripts\\SkipObject.ps1 )
## 3) Import the Autoload Module
## 5) Run this command (or add it to your profile):
<#
New-Autoload C:\\Users\\${Env:UserName}\\Documents\\WindowsPowerShell\\Scripts\\SkipObject.ps1 Skip-Object
#>

## This tells us that you want to have that function loaded for you out of the script file if you ever try to use it.
## Now, you can just use the function:
## 1..10 | Skip-Object -first 2 -upto 2

function Invoke-Autoloaded {
#.Synopsis
#	This function was autoloaded, but it has not been parsed yet.
#  Use Get-AutoloadHelp to force parsing and get the correct help (or just invoke the function once).
#.Description
#   You are seeing this help because the command you typed was imported via the New-Autoload command from the Autoload module.  The script file containing the function has not been loaded nor parsed yet. In order to see the correct help for your function we will need to parse the full script file, to force that at this time you may use the Get-AutoloadHelp function.
#
#   For example, if your command was Get-PerformanceHistory, you can force loading the help for it by running the command: Get-AutoloadHelp Get-PerformanceHistory
   [CmdletBinding()]Param()
   DYNAMICPARAM {
      $CommandName = $MyInvocation.InvocationName
	   return LoadNow $CommandName
   }#DynamicParam

   begin {
      Write-Verbose "Command: $CommandName"
      if(!$Script:AutoloadHash[$CommandName]) {
         do {
            $Alias = $CommandName
            $CommandName = Get-Alias $CommandName -ErrorAction SilentlyContinue | Select -Expand Definition
            Write-Verbose "Invoke-Autoloaded Begin: $Alias -> $CommandName"
         } while(!$Script:AutoloadHash[$CommandName] -and (Get-Alias $CommandName -ErrorAction SilentlyContinue))
      } else {
         Write-Verbose "CommandHash: $($Script:AutoloadHash[$CommandName])"
      }
      if(!$Script:AutoloadHash[$CommandName]) { throw "Unable to determine command!" }

      $ScriptName, $ModuleName, $FunctionName = $Script:AutoloadHash[$CommandName]
      Write-Verbose "Invoke-Autoloaded Begin: $Alias -> $CommandName -> $FunctionName"
      
      
      #Write-Host "Parameters: $($PSBoundParameters | ft | out-string)" -Fore Magenta
   
      $global:command = $ExecutionContext.InvokeCommand.GetCommand( $FunctionName, [System.Management.Automation.CommandTypes]::Function )
      Write-Verbose "Autoloaded Command: $($Command|Out-String)"
      $scriptCmd = {& $command @PSBoundParameters | Write-Output }
      $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
      $steppablePipeline.Begin($myInvocation.ExpectingInput)
   }
   process
   {
      Write-Verbose "Invoke-Autoloaded Process: $CommandName ($_)"
      try {
         if($_) {
            $steppablePipeline.Process($_)
         } else {
            $steppablePipeline.Process()
         }
      } catch {
         throw
      }
   }

   end
   {
      try {
         $steppablePipeline.End()
      } catch {
         throw
      }
      Write-Verbose "Invoke-Autoloaded End: $CommandName"
   }
}#Invoke-Autoloaded


function Get-AutoloadHelp {
	[CmdletBinding()]
	Param([Parameter(Mandatory=$true)][String]$CommandName)
	$null = LoadNow $CommandName
	Get-Help $CommandName
}

function LoadNow {
[CmdletBinding()]
Param([Parameter(Mandatory=$true)][String]$CommandName)
      Write-Verbose "Command: $CommandName"
      if(!$Script:AutoloadHash[$CommandName]) {
         do {
            $Alias = $CommandName
            $CommandName = Get-Alias $CommandName -ErrorAction SilentlyContinue | Select -Expand Definition
            Write-Verbose "LoadNow Begin: $Alias -> $CommandName"
         } while(!$Script:AutoloadHash[$CommandName] -and (Get-Alias $CommandName -ErrorAction SilentlyContinue))
      } else {
         Write-Verbose "CommandHash: $($Script:AutoloadHash[$CommandName])"
      }
      if(!$Script:AutoloadHash[$CommandName]) { throw "Unable to determine command!" }
      
      Write-Verbose "LoadNow DynamicParam: $CommandName from $($Script:AutoloadHash[$CommandName])"
      $ScriptName, $ModuleName, $FunctionName = $Script:AutoloadHash[$CommandName]
      Write-Verbose "Autoloading:`nScriptName: $ScriptName `nModuleName: $ModuleName `nFunctionName: $FunctionName"
      
      if(!$ScriptName){ $ScriptName = $CommandName }
      if(!$FunctionName){ $FunctionName = $CommandName }
      if($ModuleName) {
         $Module = Get-Module $ModuleName
      } else { $Module = $null }
      
      
      ## Determine the command name based on the alias used to invoke us
      ## Store the parameter set for use in the function later...
      $paramDictionary = new-object System.Management.Automation.RuntimeDefinedParameterDictionary
      
      #$externalScript = $ExecutionContext.InvokeCommand.GetCommand( $CommandName, [System.Management.Automation.CommandTypes]::ExternalScript )
      $externalScript = Get-Command $ScriptName -Type ExternalScript | Select -First 1
      Write-Verbose "Processing Script: $($externalScript |Out-String)"
      $parserrors = $null
      $prev = $null
      $script = $externalScript.ScriptContents
      [System.Management.Automation.PSToken[]]$tokens = [PSParser]::Tokenize( $script, [ref]$parserrors )
      [Array]::Reverse($tokens)
      
      ForEach($token in $tokens) {
         if($prev -and $token.Content -eq "# SIG # Begin signature block") {
            $script = $script.SubString(0, $token.Start )
         }
         if($prev -and $token.Type -eq "Keyword" -and $token.Content -ieq "function" -and $prev.Content -ieq $FunctionName ) {
            $script = $script.Insert( $prev.Start, "global:" )
            Write-Verbose "Globalized: $($script[(($prev.Start+7)..($prev.Start + 7 +$prev.Content.Length))] -join '')"
         }
         $prev = $token
      }
      
      if($Module) {
         $script = Invoke-Expression "{ $Script }"
         Write-Verbose "Importing Function into $($Module) module."
         &$Module $Script | Out-Null
         $command = Get-Command $FunctionName -Type Function
         Write-Verbose "Loaded Module Function: $($command | ft CommandType, Name, ModuleName, Visibility|Out-String)"
      } else {
         Write-Verbose "Importing Function without module."
         Invoke-Expression $script | out-null
         $command = Get-Command $FunctionName -Type Function
         Write-Verbose "Loaded Local Function: $($command | ft CommandType, Name, ModuleName, Visibility|Out-String)"
      }
      if(!$command) {
         throw "Something went wrong autoloading the $($FunctionName) function. Function definition doesn't exist in script: $($externalScript.Path)"
      }
      
      if($CommandName -eq $FunctionName) {
         Remove-Item Alias::$($CommandName)
         Write-Verbose "Defined the function $($FunctionName) and removed the alias $($CommandName)"
      } else {
         Set-Alias $CommandName $FunctionName -Scope Global
         Write-Verbose "Defined the function $($FunctionName) and redefined the alias $($CommandName)"
      }
      foreach( $pkv in $command.Parameters.GetEnumerator() ){
         $parameter = $pkv.Value
         if( $parameter.Aliases -match "vb|db|ea|wa|ev|wv|ov|ob" ) { continue } 
         $param = new-object System.Management.Automation.RuntimeDefinedParameter( $parameter.Name, $parameter.ParameterType, $parameter.Attributes)
         $paramdictionary.Add($pkv.Key, $param)
      } 
      return $paramdictionary
}

function New-Autoload {
[CmdletBinding()]
param(
   [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
   [string[]]$Name
,
   [Parameter(Position=1,Mandatory=$False,ValueFromPipelineByPropertyName=$true)]
   [Alias("BaseName")]
   $Alias = $Name
,
   [Parameter(Position=2,Mandatory=$False,ValueFromPipelineByPropertyName=$true)]
   $Function = $Alias
,
   [Parameter(Position=3,Mandatory=$false)]
   [String]$Module
,
   [Parameter(Mandatory=$false)]
   [String]$Scope = '2'
  
)
begin {
   $xlr8r = [type]::gettype("System.Management.Automation.TypeAccelerators")
   if(!$xlr8r::Get["PSParser"]) {
      $xlr8r::Add( "PSParser", "System.Management.Automation.PSParser, System.Management.Automation, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35" )
   }   
}
process {
   for($i=0;$i -lt $Name.Count;$i++){
      if($Alias -is [Scriptblock]) {
         $a = $Name[$i] | &$Alias
      } elseif($Alias -is [Array]) {
         $a = $Alias[$i]
      } else {
         $a = $Alias
      }
      
      if($Function -is [Scriptblock]) {
         $f = $Name[$i] | &$Function
      } elseif($Function -is [Array]) {
         $f = $Function[$i]
      } else {
         $f = $Function
      }
      
      Write-Verbose "Set-Alias $Module\\$a Invoke-Autoloaded -Scope $Scope"
      Set-Alias $a Invoke-Autoloaded -Scope $Scope
      $Script:AutoloadHash[$a] = $Name[$i],$Module,$f
      Write-Verbose "`$AutoloadHash[$a] = $($Script:AutoloadHash[$a])"
   }
}
}

Set-Alias Autoload New-Autoload

$Script:AutoloadHash = @{}

Export-ModuleMember -Function New-Autoload, Invoke-Autoloaded, Get-AutoloadHelp -Alias *
# SIG # Begin signature block
# MIIIDQYJKoZIhvcNAQcCoIIH/jCCB/oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUb3/clQw2bZEEQ0SGW6DCheFL
# mMegggUrMIIFJzCCBA+gAwIBAgIQKQm90jYWUDdv7EgFkuELajANBgkqhkiG9w0B
# AQUFADCBlTELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0
# IExha2UgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYD
# VQQLExhodHRwOi8vd3d3LnVzZXJ0cnVzdC5jb20xHTAbBgNVBAMTFFVUTi1VU0VS
# Rmlyc3QtT2JqZWN0MB4XDTEwMDUxNDAwMDAwMFoXDTExMDUxNDIzNTk1OVowgZUx
# CzAJBgNVBAYTAlVTMQ4wDAYDVQQRDAUwNjg1MDEUMBIGA1UECAwLQ29ubmVjdGlj
# dXQxEDAOBgNVBAcMB05vcndhbGsxFjAUBgNVBAkMDTQ1IEdsb3ZlciBBdmUxGjAY
# BgNVBAoMEVhlcm94IENvcnBvcmF0aW9uMRowGAYDVQQDDBFYZXJveCBDb3Jwb3Jh
# dGlvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMfUdxwiuWDb8zId
# KuMg/jw0HndEcIsP5Mebw56t3+Rb5g4QGMBoa8a/N8EKbj3BnBQDJiY5Z2DGjf1P
# n27g2shrDaNT1MygjYfLDntYzNKMJk4EjbBOlR5QBXPM0ODJDROg53yHcvVaXSMl
# 498SBhXVSzPmgprBJ8FDL00o1IIAAhYUN3vNCKPBXsPETsKtnezfzBg7lOjzmljC
# mEOoBGT1g2NrYTq3XqNo8UbbDR8KYq5G101Vl0jZEnLGdQFyh8EWpeEeksv7V+YD
# /i/iXMSG8HiHY7vl+x8mtBCf0MYxd8u1IWif0kGgkaJeTCVwh1isMrjiUnpWX2NX
# +3PeTmsCAwEAAaOCAW8wggFrMB8GA1UdIwQYMBaAFNrtZHQUnBQ8q92Zqb1bKE2L
# PMnYMB0GA1UdDgQWBBTK0OAaUIi5wvnE8JonXlTXKWENvTAOBgNVHQ8BAf8EBAMC
# B4AwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzARBglghkgBhvhC
# AQEEBAMCBBAwRgYDVR0gBD8wPTA7BgwrBgEEAbIxAQIBAwIwKzApBggrBgEFBQcC
# ARYdaHR0cHM6Ly9zZWN1cmUuY29tb2RvLm5ldC9DUFMwQgYDVR0fBDswOTA3oDWg
# M4YxaHR0cDovL2NybC51c2VydHJ1c3QuY29tL1VUTi1VU0VSRmlyc3QtT2JqZWN0
# LmNybDA0BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmNv
# bW9kb2NhLmNvbTAhBgNVHREEGjAYgRZKb2VsLkJlbm5ldHRAWGVyb3guY29tMA0G
# CSqGSIb3DQEBBQUAA4IBAQAEss8yuj+rZvx2UFAgkz/DueB8gwqUTzFbw2prxqee
# zdCEbnrsGQMNdPMJ6v9g36MRdvAOXqAYnf1RdjNp5L4NlUvEZkcvQUTF90Gh7OA4
# rC4+BjH8BA++qTfg8fgNx0T+MnQuWrMcoLR5ttJaWOGpcppcptdWwMNJ0X6R2WY7
# bBPwa/CdV0CIGRRjtASbGQEadlWoc1wOfR+d3rENDg5FPTAIdeRVIeA6a1ZYDCYb
# 32UxoNGArb70TCpV/mTWeJhZmrPFoJvT+Lx8ttp1bH2/nq6BDAIvu0VGgKGxN4bA
# T3WE6MuMS2fTc1F8PCGO3DAeA9Onks3Ufuy16RhHqeNcMYICTDCCAkgCAQEwgaow
# gZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2FsdCBMYWtl
# IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8GA1UECxMY
# aHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0wGwYDVQQDExRVVE4tVVNFUkZpcnN0
# LU9iamVjdAIQKQm90jYWUDdv7EgFkuELajAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUJpn1AoNt
# fkCBtyXmwWmxrRhYWdEwDQYJKoZIhvcNAQEBBQAEggEAWOPeCojDVAZDOQvT+QCH
# satm5ghVu6MCt71WYsb67G6UI1dfQ8vJkI2GddFrEyjECEVoySaVHieBGLpknvMI
# Ek/CdPFUya6pN1IkK7C6TOJRK98ohaiao3EJIf4qmy5uQwwp60dUzcJkfkndJv5t
# 37mUU9JXJWiWk5r/kTUlkYawPd4gheJFi4QOo69t4TCzsbk8pTZTdLm91ByGBr0i
# WrjegJAvfqOT126AwRRVUDbNW04TNNxTx0+ISdoVsjhFR/4F0GpiMYZMZa7BBwpa
# j+VitSQci9I9p1D19eES5wAk1UHbzEFTOz1TXcAz6GTbwgtgTcV1klmSlLghsr6k
# EQ==
# SIG # End signature block

