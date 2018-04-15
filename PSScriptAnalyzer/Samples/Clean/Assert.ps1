function Assert {
#.Example
# set-content C:\\test2\\Documents\\test2 "hi"
# C:\\PS>assert { get-item C:\\test2\\Documents\\test2 } "File wasn't created by Set-Content!"
#
[CmdletBinding()]
param( 
   [Parameter(Position=0,ParameterSetName="Script",Mandatory=$true)]
   [ScriptBlock]$condition
,
   [Parameter(Position=0,ParameterSetName="Bool",Mandatory=$true)]
   [bool]$success
,
   [Parameter(Position=1,Mandatory=$true)]
   [string]$message
)

   $message = "ASSERT FAILED: $message"
  
   if($PSCmdlet.ParameterSetName -eq "Script") {
      try {
         $ErrorActionPreference = "STOP"
         $success = &$condition
      } catch {
         $success = $false
         $message = "$message`nEXCEPTION THROWN: $($_.Exception.GetType().FullName)"         
      }
   }
   if(!$success) {
      throw $message
   }
}
