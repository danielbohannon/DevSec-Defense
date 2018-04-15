# Compile-Help.ps1
# by Jeff Hillman
#
# this script uses the text and XML PowerShell help files to generate HTML help
# for all PowerShell Cmdlets, PSProviders, and "about" topics.  the help topics 
# are compiled into a .chm file using HTML Help Workshop.

param( [string] $outDirectory = ".\\PSHelp", [switch] $GroupByPSSnapIn )

function Html-Encode( [string] $value )
{
    # System.Web.HttpUtility.HtmlEncode() doesn't quite get everything, and 
    # I don't want to load the System.Web assembly just for this.  I'm sure 
    # I missed something here, but these are the characters I saw that needed 
    # to be encoded most often
    $value = $value -replace "&(?![\\w#]+;)", "&amp;"
    $value = $value -replace "<(?!!--)", "&lt;"
    $value = $value -replace "(?<!--)>", "&gt;"
    $value = $value -replace "’", "&#39;"
    $value = $value -replace '["“”]', "&quot;"
    
    $value = $value -replace "\\n", "<br />"

    $value
}

function Capitalize-Words( [string] $value )
{
    $capitalizedString = ""

    # convert the string to lower case and split it into individual words. for each one,
    # capitalize the first character, and append it to the converted string
    [regex]::Split( $value.ToLower(), "\\s" ) | ForEach-Object {
        $capitalizedString += ( [string]$_.Chars( 0 ) ).ToUpper() + $_.SubString( 1 ) + " "
    }

    $capitalizedString.Trim()
}

function Get-ParagraphedHtml( [string] $xmlText )
{
    $value = ""
    
    if ( $xmlText -match "<(\\w+:)?para" )
    {
        $value = ""
        $options = [System.Text.RegularExpressions.RegexOptions]::Singleline

        foreach ( $match in [regex]::Matches( $xmlText, 
            "<(?:\\w+:)?para[^>]*>(?<Text>.*?)</(?:\\w+:)?para>", $options ) )
        {
            $value += "<p>$( Html-Encode $match.Groups[ 'Text' ].Value )</p>"    
        }
    }
    else
    {
        $value = Html-Encode $xmlText
    }
    
    $value
}

function Get-SyntaxHtml( [xml] $syntaxXml )
{
    $syntaxHtml = ""

    # generate the HTML for each form of the Cmdlet syntax
    foreach ( $syntaxItem in $syntaxXml.syntax.syntaxItem )
    {
        if ( $syntaxHtml -ne "" )
        {
            $syntaxHtml += "<br /><br />`n"
        }

        $syntaxHtml += "        $( $syntaxItem.name.get_InnerText().Trim() ) "

        if ( $syntaxItem.parameter )
        {
            foreach ( $parameter in $syntaxItem.parameter )
            {
                $required = [bool]::Parse( $parameter.required )

                $syntaxHtml += "<nobr>[-$( $parameter.name.get_InnerText().Trim() )"

                if ( $required )
                {
                    $syntaxHtml += "]"
                }

                if ( $parameter.parameterValue )
                {
                    $syntaxHtml += 
                        " &lt;$( $parameter.parameterValue.get_InnerText().Trim() )&gt;"
                }

                if ( !$required )
                {
                    $syntaxHtml += "]"
                }

                $syntaxHtml += "</nobr> "
            }
        }

        $syntaxHtml += " <nobr>[&lt;CommonParameters&gt;]</nobr>"
    }

    $syntaxHtml.Trim()
}

function Get-ParameterHtml( [xml] $parameterXml )
{
    $parameterHtml = ""

    # generate HTML for each parameter
    foreach ( $parameter in $parameterXml.parameters.parameter )
    {
        if ( $parameterHtml -ne "" )
        {
            $parameterHtml += "        <br /><br />`n"
        }

        $parameterHtml += 
            "        <nobr><span class=`"boldtext`">-$( $parameter.name.get_InnerText().Trim() )"

        if ( $parameter.parameterValue )
        {
            $parameterHtml += " &lt;$( $parameter.parameterValue.get_InnerText().Trim() )&gt;"
        }

        $parameterHtml += "</span></nobr>`n"

        $parameterHtml += @"
        <br />
        <div id="contenttext">
          $( Get-ParagraphedHtml $parameter.description.get_InnerXml().Trim() )

"@
        if ( $parameter.possibleValues )
        {
            foreach ( $possibleValue in $parameter.possibleValues.possibleValue )
            {
                $parameterHtml += @"
          $( $possibleValue.value.Trim() )<br />

"@
                if ( $possibleValue.description.get_InnerText().Trim() -ne "" )
                {
                    $parameterHtml += @"
          <div id="contenttext">
            $( Get-ParagraphedHtml $possibleValue.description.get_InnerXml().Trim() )
          </div>

"@
                }
            }
        }
        
        $parameterHtml += @"
        <br />
        </div>
        <table class="parametertable">
          <tr>
            <td>Required</td>
            <td>$( $parameter.required )</td>
          </tr>
          <tr>
            <td>Position</td>
            <td>$( $parameter.position )</td>
          </tr>
          <tr>
            <td>Accepts pipeline input</td>
            <td>$( $parameter.pipelineInput )</td>
          </tr>
          <tr>
            <td>Accepts wildcard characters</td>
            <td>$( $parameter.globbing )</td>
          </tr>

"@

        if ( $parameter.defaultValue )
        {
            if( $parameter.defaultValue.get_InnerText().Trim() -ne "" )
            {
                $parameterHtml += @"
          <tr>
            <td>Default Value</td>
            <td>$( $parameter.defaultValue.get_InnerText().Trim() )</td>
          </tr>

"@
            }
        }

        $parameterHtml += @"
        </table>

"@
    }

    if ( $parameterHtml -ne "" )
    {
        $parameterHtml += "        <br /><br />`n"
    }

    $parameterHtml += @"
        <nobr><span class="boldtext">&lt;CommonParameters&gt;</span></nobr>
        <br />
        <div id="contenttext">
          <p>
            For more information about common parameters, type "Get-Help about_commonparameters".
          </p>
        </div>

"@

    $parameterHtml.Trim()
}

function Get-InputHtml( [xml] $inputXml )
{
    $inputHtml = ""
    $inputCount = 0

    # generate HTML for each input type
    foreach ( $inputType in $inputXml.inputTypes.inputType )
    {
        if ( $inputHtml -ne "" )
        {
            $inputHtml += "        <br /><br />`n"
        }

        if ( $inputType.type.name.get_InnerText().Trim() -ne "" -or 
            $inputType.type.description.get_InnerText().Trim() -ne "" )
        {
            $inputHtml += "      $( $inputType.type.name.get_InnerText().Trim() )`n"
            $inputHtml += @"
      <div id="contenttext">
        $( Get-ParagraphedHtml $inputType.type.description.get_InnerXml().Trim() )
      </div>

"@
            $inputCount++
        }
    }

    $inputHtml.Trim()
    $inputCount
}

function Get-ReturnHtml( [xml] $returnXml )
{
    $returnHtml = ""
    $returnCount = 0

    # generate HTML for each return value
    foreach ( $returnValue in $returnXml.returnValues.returnValue )
    {
        if ( $returnHtml -ne "" )
        {
            $returnHtml += "        <br /><br />`n"
        }

        if ( $returnValue.type.name.get_InnerText().Trim() -ne "" -or 
            $returnValue.type.description.get_InnerText().Trim() -ne "" )
        {
            $returnHtml += "      $( $returnValue.type.name.get_InnerText().Trim() )`n"
            $returnHtml += @"
      <div id="contenttext">
        $( Get-ParagraphedHtml $returnValue.type.description.get_InnerXml().Trim() )
      </div>

"@
            $returnCount++
        }
    }

    $returnHtml.Trim()
    $returnCount
}

function Get-ExampleHtml( [xml] $exampleXml )
{
    $exampleHtml = ""
    $exampleTotalCount = 0
    $exampleCount = 0

    foreach ( $example in $exampleXml.examples.example )
    {
        $exampleTotalCount++
    }

    # generate HTML for each example
    foreach ( $example in $exampleXml.examples.example )
    {
        if ( $example.code -and $example.code.get_InnerText().Trim() -ne "" )
        {
            if ( $exampleHtml -ne "" )
            {
                $exampleHtml += "        <br />`n"
            }
    
            if ( $exampleTotalCount -gt 1 )
            {
                $exampleHtml += 
                    "        <nobr><span class=`"boldtext`">Example $( $exampleCount + 1 )</span></nobr>`n"
            }
    
            $exampleCodeHtml = "$( Html-Encode $example.introduction.get_InnerText().Trim() )" + 
                "$( Html-Encode $example.code.get_InnerText().Trim() )"
            
            $exampleHtml += "        <div class=`"syntaxregion`">$exampleCodeHtml</div>`n"

            $foundFirstPara = $false
    
            foreach ( $para in $example.remarks.para )
            {
                if ( $para.get_InnerText().Trim() -ne "" )
                {
                    # the first para is generally the description of the example.
                    # other para tags usually contain sample output
                    if ( !$foundFirstPara )
                    {
                        $exampleHtml += @"
        <div id="contenttext">
          <p>
            $( Html-Encode $para.get_InnerText().Trim() )
          </p>
        </div>

"@
                        $foundFirstPara = $true
                    }
                    else
                    {
                        $exampleHtml += @"
        <pre class="syntaxregion">$( $( ( Html-Encode $para.get_InnerText().Trim() )  -replace "<br />", "`n" ) )</pre>

"@
                    }
                }
            }
    
            $exampleCount++
        }
    }

    $exampleHtml.Trim()
    $exampleCount
}

function Get-TaskExampleHtml( [xml] $exampleXml )
{
    $exampleHtml = ""
    $exampleCount = 0
    $exampleTotalCount = 0

    foreach ( $example in $exampleXml.examples.example )
    {
        $exampleTotalCount++
    }

    # generate HTML for each example
    foreach ( $example in $exampleXml.examples.example )
    {
        if ( $exampleHtml -ne "" )
        {
            $exampleHtml += "        <br />`n"
        }

        if ( $exampleTotalCount -gt 1 )
        {
            $exampleHtml += "        <nobr><span class=`"boldtext`">Example $( $exampleCount + 1 )</span></nobr>`n"
        }

        $exampleHtml += "        <div>$( Get-ParagraphedHtml $example.introduction.get_InnerXml().Trim() )</div>`n"
        
        $exampleCodeHtml = ( Html-Encode $example.code.Trim() ) -replace "<br />", "`n"

        $exampleHtml += "        <pre class=`"syntaxregion`">$exampleCodeHtml</pre>"

        $exampleHtml += "        <div>$( Get-ParagraphedHtml $example.remarks.get_InnerXml().Trim() )</div>`n"

        $exampleCount++
    }

    $exampleHtml.Trim()
}

function Get-LinkHtml( [xml] $linkXml )
{
    $linkHtml = ""
    $linkCount = 0

    # generate HTML for each related link
    foreach ( $navigationLink in $linkXml.relatedLinks.navigationLink )
    {
        if ( $navigationLink.linkText -and `
            ( $helpHash.Keys | Foreach-Object { $_.ToUpper() } ) -contains $navigationLink.linkText.Trim().ToUpper() )
        {
            $linkHtml += "        $( $navigationLink.linkText.Trim() )<br />`n"
            $linkCount++
        }
    }

    $linkHtml.Trim()
    $linkCount
}

function Get-TaskHtml( [xml] $taskXml )
{
    $taskHtml = ""
    $taskCount = 0

    foreach ( $task in $taskXml.tasks.task )
    {
        if ( $taskHtml -ne "" )
        {
            $taskHtml += "        <br />`n"
        }

        $taskHtml += "        <nobr><span class=`"boldtext`">Task:</span> $( $task.title.Trim() )</nobr>`n"
        
        $taskDescriptionHtml = ( Get-ParagraphedHtml $task.description.get_InnerXml().Trim() )
        
        $taskHtml += "        <div id=`"contenttext`">$taskDescriptionHtml</div>`n"

        # add the example sections
        if ( $task.examples )
        {
            $taskHtml += @"
        <div id="contenttext">
          <p>
            $( Get-TaskExampleHtml ( [xml]$task.examples.get_OuterXml() ) )
          </p>
        </div>
    
"@
        }

        $taskCount++
    }
    
    $taskHtml.Trim()
    $taskCount
}

function Get-DynamicParameterHtml( [xml] $dynamicParameterXml )
{
    $dynamicParameterHtml = ""
    
    # generate HTML for each dynamic parameter
    foreach ( $dynamicParameter in $dynamicParameterXml.dynamicparameters.dynamicparameter )
    {
        $dynamicParameterHtml += "        <nobr><span class=`"boldtext`">-$( $dynamicParameter.name.Trim() )"

        if ( $dynamicParameter.type )
        {
            $dynamicParameterHtml += " &lt;$( $dynamicParameter.type.name.Trim() )&gt;"
        }

        $dynamicParameterHtml += "</span></nobr>`n"

        $dynamicParameterHtml += @"
        <br />
        <div id="contenttext">
          <p>
            $( Html-Encode $dynamicParameter.description.Trim() )
          </p>

"@
        if ( $dynamicParameter.possiblevalues )
        {
            foreach ( $possibleValue in $dynamicParameter.possiblevalues.possiblevalue )
            {
                $dynamicParameterHtml += @"
          <div id="contenttext">
            <span class=`"boldtext`">$( $possibleValue.value )</span>
            <div id="contenttext">
              $( Get-ParagraphedHtml $possibleValue.description.get_InnerXml().Trim() )
            </div>
          </div>

"@
            }
        }

        $dynamicParameterHtml += @"
          <br />
          <span class=`"boldtext`">Cmdlets Supported</span>
          <div id="contenttext">
            <p>
              $( Html-Encode $dynamicParameter.cmdletsupported.Trim() )
            </p>
          </div>
        </div>
        <br />

"@
    }

    $dynamicParameterHtml.Trim()
}

function Write-AboutTopic( [string] $topicName, [string] $topicPath )
{
    # just dump the contents of the about topic exactly as it is.  the only changes needed
    # are to encode the special HTML characters and add topic links
    $topicHtml = @"
<html>
  <head>
    <link rel="stylesheet" type="text/css" href="powershell.css" />
    <title>About $( Capitalize-Words ( $topicName -replace "(about)?_", " " ).Trim() )</title>
  </head>
  <body>
    <div id="topicheading">
      <div id="topictitle">PowerShell Help</div>
      About $( Capitalize-Words ( $topicName -replace "(about)?_", " " ).Trim() )
    </div>
    <pre>
$( ( Html-Encode ( [string]::Join( [Environment]::NewLine, ( Get-Content -Path $topicPath ) ) ) ) -replace "<br />" )
    </pre>
  </body>
</html>
"@

    $topicHtml = Add-Links $topicName $topicHtml

    Out-File -FilePath "$outDirectory\\Topics\\$topicName.html" -Encoding Ascii -Input $topicHtml
}

function Write-ProviderTopic( [string] $providerFullName, [xml] $providerXml )
{
    $providerName = $providerXml.providerhelp.Name.Trim()
    
    $topicHtml = @"
<html>
  <head>
    <link rel="stylesheet" type="text/css" href="powershell.css" />
    <title>$providerName Help</title>
  </head>
  <body>
    <div id="topicheading">
      <div id="topictitle">PowerShell Help</div>
      $providerName Provider
      <div style="text-align: right; padding-right: 3px;">
         $( $providerFullName -replace "^\\w+\\." )
      </div>
    </div>
    <div class="categorytitle">Drives</div>
    <div id="contenttext">
      $( Get-ParagraphedHtml $providerXml.providerhelp.drives.get_InnerXml().Trim() )
    </div>
    <div class="categorytitle">Synopsis</div>
    <div id="contenttext">
      <p>$( Html-Encode $providerXml.providerhelp.synopsis.Trim() )</p>
    </div>

"@
    
    $topicHtml += @"
    <div class="categorytitle">Description</div>
    <div id="contenttext">
      $( Get-ParagraphedHtml $providerXml.providerhelp.detaileddescription.get_InnerXml().Trim() )
    </div>

"@

    if ( $providerXml.providerhelp.capabilities.get_InnerText().Trim() -ne "" )
    {
        $topicHtml += @"
    <div class="categorytitle">Capabilities</div>
    <div id="contenttext">
      $( Get-ParagraphedHtml $providerXml.providerhelp.capabilities.get_InnerXml().Trim() )
    </div>

"@
    }

    $taskHtml, $taskCount = Get-TaskHtml( $providerXml.providerhelp.tasks.get_OuterXml() )
    
    if ( $taskCount -gt 0 )
    {
        $topicHtml += @"
    <div class="categorytitle">Task$( if ( $taskCount -gt 1 ) { "s" } )</div>
    <div id="contenttext">
      $taskHtml
    </div>

"@
    }

    if ( $providerXml.providerhelp.dynamicparameters )
    {
        $topicHtml += @"
    <div class="categorytitle">Dynamic Parameters</div>
    <div id="contenttext">
      $( Get-DynamicParameterHtml( $providerXml.providerhelp.dynamicparameters.get_OuterXml() ) )
    </div>

"@
    }

    if ( $providerXml.providerhelp.notes.Trim() -ne "" )
    {
        $topicHtml += @"
    <div class="categorytitle">Notes</div>
    <div id="contenttext">
      <p>$( Html-Encode $providerXml.providerhelp.notes.Trim() )</p>
    </div>

"@
    }

    $topicHtml += @"
    <div class="categorytitle">Related Links</div>
    <div id="contenttext">
      <p>$( Html-Encode $providerXml.providerhelp.relatedlinks.Trim() )</p>
    </div>
    <br />
  </body>
</html>    
"@    

    $topicHtml = Add-Links $providerName $topicHtml

    Out-File -FilePath "$outDirectory\\Topics\\$providerFullName.html" -Encoding Ascii -Input $topicHtml
}

function Write-CmdletTopic( [string] $cmdletFullName, [xml] $cmdletXml )
{
    $cmdletName = $cmdletXml.command.details.name.Trim()
    
    # add the heading, syntax section, and description
    $topicHtml = @"
<html>
  <head>
    <link rel="stylesheet" type="text/css" href="powershell.css" />
    <title>$cmdletName Help</title>
  </head>
  <body>
    <div id="topicheading">
      <div id="topictitle">PowerShell Help</div>
      $cmdletName Cmdlet
      <div style="text-align: right; padding-right: 3px;">
         $( $cmdletFullName -replace "^\\w+-\\w+\\." )
      </div>
    </div>
    <div class="categorytitle">Synopsis</div>
    <div id="contenttext">
      $( Get-ParagraphedHtml $cmdletXml.command.details.description.get_InnerXml().Trim() )
    </div>
    <div class="categorytitle">Syntax</div>
    <div id="contenttext">
      <div class="syntaxregion">$( Get-SyntaxHtml ( [xml]$cmdletXml.command.syntax.get_OuterXml() ) )</div>
    </div>
    <div class="categorytitle">Description</div>
    <div id="contenttext">
      $( Get-ParagraphedHtml $cmdletXml.command.description.get_InnerXml().Trim() )
    </div>

"@

    # add the parameters section
    if ( $cmdletXml.command.parameters )
    {
        $topicHtml += @"
    <div class="categorytitle">Parameters</div>
    <div id="contenttext">
      <p>
        $( Get-ParameterHtml ( [xml]$cmdletXml.command.parameters.get_OuterXml() ) )
      </p>
    </div>

"@
    }
    else
    {
        $topicHtml += @"
    <div class="categorytitle">Parameters</div>
    <div id="contenttext">
      <p>
       <nobr><span class="boldtext">&lt;CommonParameters&gt;</span></nobr><br />
       <div id="contenttext">
         <p>
            For more information about common parameters, type "Get-Help about_commonparameters".
         </p>
        </div>
      </p>
    </div>

"@
    }

    # add the input types section
    if ( $cmdletXml.command.inputTypes )
    {
        $inputHtml, $inputCount = Get-InputHtml ( [xml]$cmdletXml.command.inputTypes.get_OuterXml() )
    
        if ( $inputCount -gt 0 )
        {
            $topicHtml += @"
    <div class="categorytitle">Input Type$( if ( $inputCount -gt 1 ) { "s" } )</div>
    <div id="contenttext">
      $inputHtml
    </div>

"@
        }
    }

    # add the return values section
    if ( $cmdletXml.command.returnValue )
    {
        $returnHtml, $returnCount = Get-ReturnHtml ( [xml]$cmdletXml.command.returnValues.get_OuterXml() )
    
        if ( $returnCount -gt 0 )
        {
            $topicHtml += @"
    <div class="categorytitle">Return Value$( if ( $returnCount -gt 1 ) { "s" } )</div>
    <div id="contenttext">
      $returnHtml
    </div>

"@
        }
    }

    # add the notes section
    if ( $cmdletXml.command.alertSet )
    {
        if ( $cmdletXml.command.alertSet.get_InnerText().Trim() -ne "" )
        {
            $topicHtml += @"
    <div class="categorytitle">Notes</div>
    <div id="contenttext">
      $( Get-ParagraphedHtml $cmdletXml.command.alertSet.get_InnerXml().Trim() )
    </div>

"@
        }
    }

    # add the example section
    if ( $cmdletXml.command.examples )
    {
        $exampleHtml, $exampleCount = Get-ExampleHtml ( [xml]$cmdletXml.command.examples.get_OuterXml() )

        if ( $exampleCount -gt 0 )
        {
            $topicHtml += @"
    <div class="categorytitle">Example$( if ( $exampleCount -gt 1 ) { "s" } )</div>
    <div id="contenttext">
      <p>
        $exampleHtml
      </p>
    </div>

"@
        }
    }

    # add the related links section
    if ( $cmdletXml.command.relatedLinks )
    {
        $linkHtml, $linkCount = Get-LinkHtml ( [xml]$cmdletXml.command.relatedLinks.get_OuterXml() )

        if ( $linkCount -gt 0 )
        {
            $topicHtml += @"
    <div class="categorytitle">Related Link$( if ( $linkCount -gt 1 ) { "s" } )</div>
    <div id="contenttext">
      <p>
        $linkHtml
      </p>
    </div>
    <br />

"@
        }
        else
        {
            $topicHtml +=  "        <br />`n"
        }
    }
    else
    {
        $topicHtml +=  "        <br />`n"
    }

    $topicHtml += @"
  </body>
</html>
"@

    $topicHtml = Add-Links $cmdletName $topicHtml

    Out-File -FilePath "$outDirectory\\Topics\\$cmdletFullName.html" -Encoding Ascii -Input $topicHtml
}

function Add-Links( [string] $topicName, [string] $topicHtml )
{
    # we only want to add links for Cmdlets and about topics
    $helpHash.Keys | Where-Object { $_ -match "(^\\w+-\\w+|^about_)" } | Foreach-Object {
        $searchText = $_
    
        # keys representing Cmdlets are formatted like this:
        # <Cmdlet Name>.<PSProvider name>
        if ( $_ -match "^\\w+-\\w+" )
        {
            # we only want to search for the Cmdlet name
            $searchText = $matches[ 0 ]
        }

        # if the search text isn't the topic being processed
        if ( $searchText -ne $topicName )
        {
            $topicHtml = $topicHtml -replace "\\b($searchText)\\b", "<a href=`"Topics\\$_.html`"><nobr>`$1</nobr></a>"
        }
    }

    $topicHtml
}

# file dumping functions

function Write-Hhp
{
    # write the contents of the Html Help Project file
    Out-File -FilePath "$outDirectory\\powershell.hhp" -Encoding Ascii -Input @"
[OPTIONS]
Binary TOC=Yes
Compatibility=1.1 or later
Compiled file=PowerShell.chm
Contents file=powershell.hhc
Default topic=Topics/default.html
Full-text search=Yes
Language=0x409 English (United States)
Title=PowerShell Help

[INFOTYPES]
"@
}

function Write-DefaultPage
{
    $defaultHtml =  @"
<html>
  <head>
    <link rel="stylesheet" type="text/css" href="powershell.css" />
    <title>PowerShell Help</title>
  </head>
  <body style="margin: 5px 5px 5px 5px; color: #FFFFFF; background-color: #C86400;">
    <h2>Windows PowerShell Help</h2>
    <br />
    This complied help manual contains the help for all of the built-in PowerShell Cmdlets 
    and PSProviders, as well as the help for any Cmdlets or PSProviders added through 
    Add-PSSnapin, if help for them is available.  Also included are all of the "about" topics.
    <br /><br />
    To use this manual from the PowerShell command line, add the following function and 
    alias to your PowerShell profile:
    <div id="contenttext">
      <pre class="syntaxregion">function Get-CompiledHelp( [string] `$topic )
{
    if ( `$topic )
    {
        # Get-Command will fail if the topic is a PSProvider or an "about" topic.
        `$ErrorActionPreference = "SilentlyContinue"

        # we don't want Get-Command to resolve to an application or a function 
        `$command = Get-Command `$topic | Where-Object { `$_.CommandType -match "Alias|Cmdlet" }

        # if the topic is an alias or a Cmdlet, combine its name with
        # its PSProvider to get the full name of the help file
        if ( `$command -and `$command.CommandType -eq "Alias" )
        {
            `$topic = "`$( `$command.Definition ).`$( `$command.ReferencedCommand.PSSnapIn.Name )"
        }
        elseif ( `$command -and `$command.CommandType -eq "Cmdlet" )
        {
            `$topic = "`$( `$command.Name ).`$( `$command.PSSnapIn.Name )"
        }
        else
        {
            # check to see if we have a PSProvider
            `$psProvider = Get-PSProvider `$topic

            if ( `$psProvider )
            {
                `$topic = "`$( `$psProvider.Name ).`$( `$psProvider.PSSnapIn.Name )"
            }
        }

        hh.exe "mk:@MSITStore:$( Resolve-Path "$outDirectory" )\\PowerShell.chm::/Topics/`$topic.html"
    }
    else
    {
        hh.exe "$( Resolve-Path "$outDirectory" )\\PowerShell.chm"
    }
}

Set-Alias chelp Get-CompiledHelp</pre>
    </div>
    <br />
    The path in the Get-CompliedHelp function corresponds to the location where this compiled 
    help manual was originally created.  If this file is moved to another location, the path 
    in the function will need to be updated.
    <br />
    <br />
    To view the help topic for Get-ChildItem, type the following:
    <div id="contenttext">
      <div class="syntaxregion">PS$ Get-CompiledHelp Get-ChildItem</div>
    </div>
    <br />
    Because "ls" is an alias for Get-ChildItem, and "chelp" is an alias for Get-CompliedHelp, the following also works:
    <div id="contenttext">
      <div class="syntaxregion">PS$ chelp ls</div>
    </div>
  </body>
</html>
"@

    $defaultHtml = Add-Links "" $defaultHtml

    Out-File -FilePath "$outDirectory\\Topics\\default.html" -Encoding Ascii -Input $defaultHtml
}

function Write-Css
{
    Out-File -FilePath "$outDirectory\\powershell.css" -Encoding Ascii -Input @"
body
{
  margin: 0px 0px 0px 0px;
  padding: 0px 0px 0px 0px;
  font-family: Verdana, Arial, Helvetica, sans-serif;
  font-size: 70%;
  width: 100%;
}

div#topicheading
{
  position: relative;
  left: 0px;
  padding: 5px 0px 5px 10px;
  border-bottom: 1px solid #999999;
  color: #FFFFFF;
  background-color: #C86400;
  font-size: 110%;
  font-weight: bold;
  text-align: left;
}

div#topictitle
{
  padding: 5px 5px 5px 5px;
  color: #FFFFFF
  font-size: 90%;
  font-weight: normal;
}

div#contenttext
{
  top: 0px;
  padding: 0px 25px 0px 25px;
}

p { margin: 5px 0px 5px 0px; }

a:link    { color: #0000FF; }
a:visited { color: #0000FF; }
a:hover   { color: #3366FF; }

table.parametertable
{
  margin-left: 25px;
  font-size: 100%;
  border-collapse:collapse
}

table.parametertable td
{
  font-size: 100%;
  border: solid #999999 1px;
  padding: 0in 5.4pt 0in 5.4pt
}

pre.syntaxregion, div.syntaxregion
{
  background: #DDDDDD;
  padding: 4px 8px;
  cursor: text;
  margin-top: 1em;
  margin-bottom: 1em;
  margin-left: .6em;
  color: #000000;
  border-width: 1px;
  border-style: solid;
  border-color: #999999;
}

.categorytitle
{
  padding-top: .8em;
  font-size: 110%;
  font-weight: bold;
  text-align: left;
  margin-left: 5px;
}

.boldtext { font-weight: bold; }
"@
}

### main ###

# create the topics directory
New-Item -Type Directory -Path "$outDirectory" -Force | Out-Null
New-Item -Type Directory -Path "$outDirectory\\Topics" -Force | Out-Null

"`nRetrieving help content...`n"

# initialize variables for HHC file
$hhcContentsHtml = ""
$cmdletCategoryHtml = ""
$cmdletCategoryHash = @{}

# help content hash
$helpHash = @{}

# get the Cmdlet help
Get-PSSnapIn | Sort-Object -Property Name | Foreach-Object { 
    $psSnapInName = $_.Name
    
    $helpFilePath = Join-Path $_.ApplicationBase ( ( Get-Command -PSSnapIn $_ ) | Select-Object -First 1 ).HelpFile
    
    # the culture needs to be added to the path on Vista    
    if ( !( Test-Path $helpFilePath ) )
    {
        $helpFilePath = "$( $_.ApplicationBase )\\$( $Host.CurrentUICulture.Name )\\$( Split-Path -Leaf $helpFilePath )"
    }

    if ( Test-Path $helpFilePath )
    {
        $helpXml = [xml]( Get-Content $helpFilePath )
    
        $cmdletCategoryContents = ""
    
        Get-Command -PSSnapIn $_ | Foreach-Object {
            $commandName = $_.Name
    
            $helpXml.helpitems.command | Where-Object { 
                $_.details.name -and $_.details.name.Trim() -imatch "\\b$commandName\\b" 
            } | Foreach-Object {
                # add the Xml Help of the Cmdlet to the help hashtable
                $helpHash[ "{0}.{1}" -f $commandName, $psSnapInName ] = $_.get_OuterXml()

                $cmdletTopicItem = @"
          <li><object type="text/sitemap">
            <param name="Name" value="$commandName">
            <param name="Local" value="Topics\\$( "{0}.{1}" -f $commandName, $psSnapInName ).html">
          </object>

"@
                if ( $GroupByPSSnapIn )
                {    
                    $cmdletCategoryContents += $cmdletTopicItem
                }
                else
                {
                    # save the topics so they can be sorted properly and added to the HHC later
                    $cmdletCategoryHash[ "{0}.{1}" -f $commandName, $psSnapInName ] = $cmdletTopicItem
                }
            }
        } 
    
        if ( $GroupByPSSnapIn )
        {
            # add a category in the HHC for this PSSnapIn and its Cmdlets
            $cmdletCategoryHtml += @"
        <li><object type="text/sitemap">
          <param name="Name" value="$psSnapInName">
        </object>
        <ul>
          $( $cmdletCategoryContents.Trim() )
        </ul>

"@
        }
    }
}

# sort the Cmdlets so they are added to the HHC in a logical order
if ( !$GroupByPSSnapIn )
{
    $cmdletCategoryHash.Keys | Sort-Object | Foreach-Object {
        $cmdletCategoryHtml += $cmdletCategoryHash[ $_ ]
    }
}

# add the Cmdlet category to the HHC
$hhcContentsHtml += @"
      <li><object type="text/sitemap">
        <param name="Name" value="Cmdlet Help">
      </object>
      <ul>
        $( $cmdletCategoryHtml.Trim() )
      </ul>

"@

$providerCategoryHtml = ""
$providerCategoryHash = @{}

# get the PSProvider help
Get-PSSnapIn | Sort-Object -Property Name | Foreach-Object {
    $psSnapInName = $_.Name

    $helpFilePath = Join-Path $_.ApplicationBase ( ( Get-Command -PSSnapIn $_ ) | Select-Object -First 1 ).HelpFile

    # the culture needs to be added to the path on Vista    
    if ( !( Test-Path $helpFilePath ) )
    {
        $helpFilePath = "$( $_.ApplicationBase )\\$( $Host.CurrentUICulture.Name )\\$( Split-Path -Leaf $helpFilePath )"
    }

    if ( Test-Path $helpFilePath )
    {
        $helpXml = [xml]( Get-Content $helpFilePath )
        
        $providerCategoryContents = ""

        Get-PSProvider | Where-Object { $_.PSSnapin.Name -eq $psSnapInName } | Foreach-Object {
            $psProviderName = $_.Name

            $helpXml.helpitems.providerhelp | 
            Where-Object { $_.name.Trim() -imatch "\\b$psProviderName\\b" } | 
            Foreach-Object {
                $helpHash[ "{0}.{1}" -f $psProviderName, $psSnapInName ] = $_.get_OuterXml()
    
                # add a category in the HHC for this PSProvider
                $providerTopicItem = @"
        <li><object type="text/sitemap">
          <param name="Name" value="$psProviderName">
          <param name="Local" value="Topics\\$( "{0}.{1}" -f $psProviderName, $psSnapInName ).html">
        </object>

"@
                if ( $GroupByPSSnapIn )
                {    
                    $providerCategoryContents += $providerTopicItem
                }
                else
                {
                    # save the topics so they can be sorted properly and added to the HHC later
                    $providerCategoryHash[ "{0}.{1}" -f $psProviderName, $psSnapInName ] = $providerTopicItem
                }
            }
        }
    
        if ( $GroupByPSSnapIn -and $providerCategoryContents -ne "" )
        {
            # add a category in the HHC for this PSSnapIn and its Cmdlets
            $providerCategoryHtml += @"
        <li><object type="text/sitemap">
          <param name="Name" value="$psSnapInName">
        </object>
        <ul>
          $( $providerCategoryContents.Trim() )
        </ul>

"@
        }
    }
}

# sort the PSProviders so they are added to the HHC in a logical order
if ( !$GroupByPSSnapIn )
{
    $providerCategoryHash.Keys | Sort-Object | Foreach-Object {
        $providerCategoryHtml += $providerCategoryHash[ $_ ]
    }
}

# add the PSProvider category to the HHC
$hhcContentsHtml += @"
      <li><object type="text/sitemap">
        <param name="Name" value="Provider Help">
      </object>
      <ul>
        $( $providerCategoryHtml.Trim() )
      </ul>

"@

# get the about topics
$about_TopicPaths = @()

$helpPath = ""

if ( Resolve-Path "$pshome\\about_*.txt" )
{
    $helpPath = "$pshome"
}
elseif ( Resolve-Path "$pshome\\$( $Host.CurrentUICulture.Name )\\about_*.txt" )
{
    $helpPath = "$pshome\\$( $Host.CurrentUICulture.Name )"
}

if ( Test-Path $helpPath )
{
    $about_TopicPaths += Get-ChildItem "$helpPath\\about_*.txt"
}

# we SilentlyContinue with Get-ChildItem errors because the ModuleName
# for the built-in PSSnapins doesn't resolve to anything, since the assemblies
# are only in the GAC.
$about_TopicPaths += Get-PSSnapin | Foreach-Object { 
    ( Get-ChildItem $_.ModuleName -ErrorAction "SilentlyContinue" ).DirectoryName 
} | Foreach-Object { 
    Get-ChildItem "$_\\about_*.txt" 
}

if ( $about_TopicPaths.Count -gt 0 )
{
    $aboutCategoryHtml = ""
    
    $about_TopicPaths | Sort-Object -Unique -Property @{ Expression = { $_.Name.ToUpper() } }| Foreach-Object {
        # pull the topic name out of the file name
        $name = ( $_.Name -replace "(.xml)?.help.txt", "`$1" )
    
        # add the path of the topic to the help hashtable
        $helpHash[ $name ] = $_.FullName
    
        $topicName = Capitalize-Words ( $name -replace "(about)?_", " " ).Trim()
    
        # add a category in the HHC for this about topic
        $aboutCategoryHtml += @"
        <li><object type="text/sitemap">
          <param name="Name" value="$topicName">
          <param name="Local" value="Topics\\$name.html">
        </object>

"@
    }

    # add the About Topics category to the HHC
    $hhcContentsHtml += @"
      <li><object type="text/sitemap">
        <param name="Name" value="About Topics">
      </object>
      <ul>
        $( $aboutCategoryHtml.Trim() )
      </ul>

"@
}

# write the contents file
Out-File -FilePath "$outDirectory\\powershell.hhc" -Encoding Ascii -Input @"
<!doctype html public "-//ietf//dtd html//en">
<html>
  <head>
    <meta name="Generator" content="Microsoft&reg; HTML Help Workshop 4.1">
    <!-- Sitemap 1.0 -->
  </head>
  <body>
    <object type="text/site properties">
      <param name="Window Styles" value="0x800025">
    </object>
    <ul>
      <li><object type="text/sitemap">
        <param name="Name" value="PowerShell Help">
        <param name="Local" value="Topics\\default.html">
      </object>
      $( $hhcContentsHtml.Trim() )
    </ul>
  </body>
</html>
"@

$helpHash.Keys | Sort-Object | Foreach-Object {
    switch -regex ( $_ )
    {
        # about topic
        "about_"
        {
            "Creating help for the $_ about topic..."
            Write-AboutTopic $_ $helpHash[ $_ ]
        }

        # Verb-Noun: Cmdlet
        "\\w+-\\w+"
        {
            "Creating help for the $( $_ -replace '(^\\w+-\\w+).*', '$1' ) Cmdlet..."
            Write-CmdletTopic $_ $helpHash[ $_ ]
        }
        
        # PSProvider
        default
        {
            "Creating help for the $( $_ -replace '(^\\w+).*', '$1' ) PSProvider..."
            Write-ProviderTopic $_ $helpHash[ $_ ]
        }
    }
}

Write-DefaultPage
Write-Css
Write-Hhp

if ( Test-Path "C:\\Program Files\\HTML Help Workshop\\hhc.exe" )
{
    # compile the help
    "`nCompiling the help manual...`n"
    Push-Location
    Set-Location $outDirectory
    & "C:\\Program Files\\HTML Help Workshop\\hhc.exe" powershell.hhp
    Pop-Location
    
    # open the help file
    & "$outDirectory\\PowerShell.chm"
}
else
{
    Write-Host -ForegroundColor Red @"

HTML Help Workshop is not installed, or it was not installed in its default
location of "C:\\Program Files\\HTML Help Workshop".

HTML Help Workshop is required to compile the help manual.  It can be downloaded
free of charge from Microsoft:

http://www.microsoft.com/downloads/details.aspx?familyid=00535334-c8a6-452f-9aa0-d597d16580cc&displaylang=en

If you do not want to install HTML Help Workshop on this machine, all of the
files necessary to compile the manual have been created here:

$( Resolve-Path $outDirectory ) 

Copy these files to a machine with HTML Help Workshop, and you can compile the
manual there, with the following command:

<HTML Help Workshop location>\\hhc.exe powershell.hhp

"@
}
