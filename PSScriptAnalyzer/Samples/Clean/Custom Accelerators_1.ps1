#requires -version 2.0
## Custom Accelerators for PowerShell 2
####################################################################################################
## A script module for PowerShell 2 which allows the user to create their own custom type accelerators. 
## Thanks to "Oisin Grehan for the discovery":http://www.nivot.org/2008/12/25/ListOfTypeAcceleratorsForPowerShellCTP3.aspx. 
####################################################################################################
## Revision History
## v1.0  - Modularization of Oisin's idea, by Joel 'Jaykul' Bennett
## v2.0  - Update for RTM (nothing significant)
## v2.1  - Minor tweaks to make it more pipelineable (I'm including this in my Reflection module)
####################################################################################################

# get a reference to the Type   
$xlr8r = [type]::gettype("System.Management.Automation.TypeAccelerators")  

function Add-Accelerator {
<#
   .Synopsis
      Add a type accelerator to the current session
   .Description
      The Add-Accelerator function allows you to add a simple type accelerator (like [regex]) for a longer type (like [System.Text.RegularExpressions.Regex]).
   .Example
      Add-Accelerator list System.Collections.Generic.List``1
      $list = New-Object list[string]
      
      Creates an accelerator for the generic List[T] collection type, and then creates a list of strings.
   .Example
      Add-Accelerator "List T", GList System.Collections.Generic.List``1
      $list = New-Object "list t[string]"
      
      Creates two accelerators for the Generic List[T] collection type.
   .Parameter Accelerator
      The short form accelerator should be just the name you want to use (without square brackets).
   .Parameter Type
      The type you want the accelerator to accelerate (without square brackets)
   .Notes
      When specifying multiple values for a parameter, use commas to separate the values. 
      For example, "-Accelerator string, regex".
      
      PowerShell requires arguments that are "types" to NOT have the square bracket type notation, because of the way the parsing engine works.  You can either just type in the type as System.Int64, or you can put parentheses around it to help the parser out: ([System.Int64])

      Also see the help for Get-Accelerator and Remove-Accelerator
   .Link
      http://huddledmasses.org/powershell-2-ctp3-custom-accelerators-finally/
      
#>
[CmdletBinding()]
PARAM(
   [Parameter(Position=0,ValueFromPipelineByPropertyName=$true)]
   [Alias("Key","Name")]
   [string[]]$Accelerator
,
   [Parameter(Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
   [Alias("Value","FullName")]
   [type]$Type
)
PROCESS {
   # add a user-defined accelerator  
   foreach($a in $Accelerator) { 
      $xlr8r::Add( $a, $Type) 
      trap [System.Management.Automation.MethodInvocationException] {
         if($xlr8r::get.keys -contains $a) {
            Write-Error "Cannot add accelerator [$a] for [$($Type.FullName)]`n                  [$a] is already defined as [$($xlr8r::get[$a].FullName)]"
            Continue;
         } 
         throw
      }
   }
}
}

function Get-Accelerator {
<#
   .Synopsis
      Get one or more type accelerator definitions
   .Description
      The Get-Accelerator function allows you to look up the type accelerators (like [regex]) defined on your system by their short form or by type
   .Example
      Get-Accelerator System.String
      
      Returns the KeyValue pair for the [System.String] accelerator(s)
   .Example
      Get-Accelerator ps*,wmi*
      
      Returns the KeyValue pairs for the matching accelerator definition(s)
   .Parameter Accelerator
      One or more short form accelerators to search for (Accept wildcard characters).
   .Parameter Type
      One or more types to search for.
   .Notes
      When specifying multiple values for a parameter, use commas to separate the values. 
      For example, "-Accelerator string, regex".
      
      Also see the help for Add-Accelerator and Remove-Accelerator
   .Link
      http://huddledmasses.org/powershell-2-ctp3-custom-accelerators-finally/
#>
[CmdletBinding(DefaultParameterSetName="ByType")]
PARAM(
   [Parameter(Position=0, ParameterSetName="ByAccelerator", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
   [Alias("Key","Name")]
   [string[]]$Accelerator
,
   [Parameter(Position=0, ParameterSetName="ByType", ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
   [Alias("Value","FullName")]
   [type[]]$Type
)
PROCESS {
   # add a user-defined accelerator  
   switch($PSCmdlet.ParameterSetName) {
      "ByAccelerator" { 
         $xlr8r::get.GetEnumerator() | % {
            foreach($a in $Accelerator) {
               if($_.Key -like $a) { $_ }
            }
         }
         break
      }
      "ByType" { 
         if($Type -and $Type.Count) {
            $xlr8r::get.GetEnumerator() | ? { $Type -contains $_.Value }
         }
         else {
            $xlr8r::get.GetEnumerator() | %{ $_ }
         }
         break
      }
   }
}
}

function Remove-Accelerator {
<#
   .Synopsis
      Remove a type accelerator from the current session
   .Description
      The Remove-Accelerator function allows you to remove a simple type accelerator (like [regex]) from the current session. You can pass one or more accelerators, and even wildcards, but you should be aware that you can remove even the built-in accelerators.
      
   .Example
      Remove-Accelerator int
      Add-Accelerator int Int64
      
      Removes the "int" accelerator for Int32 and adds a new one for Int64. I can't recommend doing this, but it's pretty cool that it works:
      
      So now, "$(([int]3.4).GetType().FullName)" would return "System.Int64"
   .Example
      Get-Accelerator System.Single | Remove-Accelerator
      
      Removes both of the default accelerators for System.Single: [float] and [single]
   .Example
      Get-Accelerator System.Single | Remove-Accelerator -WhatIf
      
      Demonstrates that Remove-Accelerator supports -Confirm and -Whatif. Will Print:
         What if: Removes the alias [float] for type [System.Single]
         What if: Removes the alias [single] for type [System.Single]
   .Parameter Accelerator
      The short form accelerator that you want to remove (Accept wildcard characters).
   .Notes
      When specifying multiple values for a parameter, use commas to separate the values. 
      For example, "-Accel string, regex".
      
      Also see the help for Add-Accelerator and Get-Accelerator
   .Link
      http://huddledmasses.org/powershell-2-ctp3-custom-accelerators-finally/
#>
[CmdletBinding(SupportsShouldProcess=$true)]
PARAM(
   [Parameter(Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
   [Alias("Key","FullName")]
   [string[]]$Accelerator
)
PROCESS {
   foreach($a in $Accelerator) {
      foreach($key in $xlr8r::Get.Keys -like $a) { 
         if($PSCmdlet.ShouldProcess( "Removes the alias [$($Key)] for type [$($xlr8r::Get[$key].FullName)]",
                                     "Remove the alias [$($Key)] for type [$($xlr8r::Get[$key].FullName)]?",
                                     "Removing Type Accelerator" )) {
            # remove a user-defined accelerator
            $xlr8r::remove($key)   
         }
      }
   }
}
}

Add-Accelerator list System.Collections.Generic.List``1
Add-Accelerator dictionary System.Collections.Generic.Dictionary``2
