## ConvertTo-DekiContent (aka Convert Help to Html)
####################################################################################################
## Converts the -Full help output to HTML markup for insertion into web pages.
####################################################################################################
## Usage:
##
## foreach($cmd in (gcm -type cmdlet | ? { $_.PsSnapin -like "Microsoft.PowerShell*" })) {
##
##    Get-Help $cmd.Name -full | ConvertTo-DekiContent Cmdlet_Help | 
##    %{ Set-DekiContent "Cmdlet_Help/$($cmd.PSSnapin)/$($cmd.Name)" $_ }
## }
##
####################################################################################################
## History:
## v2.0 - Refactoring of markup and code by Joel "Jaykul" Bennett to avoid line-wrapping, and 'pre'
##        blocks in the code and to format the parameters and examples more like the originals.
## v1.0 - Original version by http://blogs.vmware.com/vipowershell/2007/09/new-htmlhelp.html
####################################################################################################

#Import System.Web in order to use HtmlEncode functionality
[System.Reflection.Assembly]::LoadWithPartialName("System.Web") | out-null

## Get-HtmlHelp - A Helper function for generating help:
## Usage:  Get-HtmlHelp Get-*
function Get-HtmlHelp {
   param([string[]]$commands, [string]$baseUrl)
   $commands | Get-Command -type Cmdlet -EA "SilentlyContinue" | get-help -Full | ConvertTo-DekiContent $baseUrl
}

function ConvertTo-DekiContent {
param($baseUrl)
PROCESS {
   if($_ -and ($_.PSObject.TypeNames -contains "MamlCommandHelpInfo#FullView")) {
      $help = $_
      
      # Name isn't needed, since this is going as the body, but ...
      # $data = "<html><head><title>$(encode($help.Name))</title></head><body>";
      # $data += "<h1>$(encode($help.Name))</h1>"
   
      # Synopsis
      $data += "<h2>Synopsis</h2>$($help.Synopsis | Out-HtmlPara)"
      
      # Syntax
      $data += "<h2>Syntax</h2>$($help.Syntax | Out-HtmlPara)"
   
      # Related Commands
      $data += "<h2>Related Commands</h2>"
      foreach ($relatedLink in $help.relatedLinks.navigationLink) {
         if($relatedLink.linkText -ne $null -and $relatedLink.linkText.StartsWith("about") -eq $false) {
            $uri = ""
            if( $relatedLink.uri -ne "" ) {
               $uri = $relatedLink.uri
            } else{
               $uri = "$baseUrl/$((get-command $relatedLink.linkText -EA "SilentlyContinue").PSSnapin.Name)/$($relatedLink.linkText)"
            }
            $data += "<a href='$(encode($uri)).html'>$(encode($relatedLink.linkText))</a><br>"
         }
      }
   
      # Detailed Description
      $data += "<h2>Detailed Description</h2>$(encode(&{$help.Description | out-string -width 200000}))"
   
      # Parameters
      $data += "<h2>Parameters</h2>"
      $help.parameters.parameter | %{
         $param = $_
         $data += "<h4>-$(encode($param.Name)) [&lt;$(encode($param.type.name))&gt;]</h4>"
         $data += $param.Description | Out-HtmlPara
         $data += "<table>"
         $data += "<tr><th>Required? &nbsp;</th><td> $(encode($param.Required))</td></tr>"
         $data += "<tr><th>Position? &nbsp;</th><td> $(encode($param.Position))</td></tr>"
         $data += "<tr><th>Default value? &nbsp;</th><td> $(encode($param.defaultValue))</td></tr>"
         $data += "<tr><th>Accept pipeline input? &nbsp;</th><td> $(encode($param.pipelineInput))</td></tr>"
         $data += "<tr><th>Accept wildcard characters? &nbsp;</th><td> $(encode($param.globbing))</td></tr></table>"
      }
   
      if($help.inputTypes) {
         # Input Type
         $data += "<h3>Input Type</h3>$($help.inputTypes | Out-HtmlPara)"
      }
      if($help.returnValues) {
         # Return Type
         $data += "<h3>Return Type</h3>$($help.returnValues | Out-HtmlPara)"
      }
      # Notes
      $data += "<h2>Notes</h2>$($help.alertSet | Out-HtmlPara)"
   
      # Examples
      $data += "<h2>Examples</h2>"
      
      $help.Examples.example | %{
         $example = $_
         $data += "<h4>$(encode($example.title.trim(' -')))</h4>"
         $data += "<code><strong>PS&gt;</strong>&nbsp;$(encode($example.code))</code>"
         $data += "<p>$($example.remarks | out-string -width ([int]::MaxValue) | Out-HtmlPara)</p>"

      }
      # $data += "</body>"

      write-output $data
   } else { 
      Write-Error "Can only process -Full view help output"
   }
}}



function encode($str) {
   begin{ if($str){ $str.split("`n") | encode  } }
   process{ if($_){ [System.Web.HttpUtility]::HtmlEncode($_).Trim() } }
}

function trim($str) {
   begin{ if($str){ $str.Trim() } }
   process{ if($_){ $_.Trim() } }
}

function split($Separator="`n",$inputObject) {
   begin{ if($inputObject){ $inputObject | split $Separator } }
   process{ if($_){ [regex]::Split($_,$Separator) | ? {$_.Length} } }
}

function join($Separator=$ofs,$inputObject) {
   begin{ if($inputObject){ [string]::Join($Separator,$inputObject) } else { $array =@() }}
   process{ if($_){ $array += $_ } }
   end{ if($array.Length) { [string]::Join($Separator,$array) } }
}

function Out-HtmlPara {
   process{if($_){"<p>$($_ | out-string -width ([int]::MaxValue) | split "\\s*`n" | encode | trim | join "</p>`n<p>")</p>"}}
}

