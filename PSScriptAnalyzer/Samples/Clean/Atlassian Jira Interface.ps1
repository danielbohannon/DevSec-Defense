# jirafunctions.ps1
#
# Note: Some functions are incomplete/untested. Be sure to TEST before placing in production!!
#
# Dot-source this script to connect to jira and initialize the functions.
# Ex: PS C:\\scripts\\jira> . .\\jirafunctions.ps1
# Ex: PS C:\\scripts\\jira> get-JiraReport
#
# Connects to Jira and initializes several functions that can be
# used to interface with Jira.
#
# Author: Robbie Foust (rfoust@duke.edu)
# Last Modified: December 26, 2008
#
# connect-webservice script written by Lee Holmes (http://www.leeholmes.com/guide)
# and slightly modified by Robbie Foust.
#

$global:jiraURL = "https://server.yourdomain.com/jira/rpc/soap/jirasoapservice-v2?wsdl"

function global:connect-jira ($wsdlLocation)
{
	##############################################################################
	##
	## Connect-WebService.ps1
	##
	## From Windows PowerShell, The Definitive Guide (O'Reilly)
	## by Lee Holmes (http://www.leeholmes.com/guide)
	##
	## Connect to a given web service, and create a type that allows you to
	## interact with that web service.
	##
	## Example:
	##
	##     $wsdl = "http://terraserver.microsoft.com/TerraService2.asmx?WSDL"
	##     $terraServer = Connect-WebService $wsdl
	##     $place = New-Object Place
	##     $place.City = "Redmond"
	##     $place.State = "WA"
	##     $place.Country = "USA"
	##     $facts = $terraserver.GetPlaceFacts($place)
	##     $facts.Center
	##############################################################################
#	param(
#	    [string] $wsdlLocation = $(throw "Please specify a WSDL location"),
#	    [string] $namespace,
#	    [Switch] $requiresAuthentication)

	## Create the web service cache, if it doesn't already exist
	if(-not (Test-Path Variable:\\Lee.Holmes.WebServiceCache))
	{
	    ${GLOBAL:Lee.Holmes.WebServiceCache} = @{}
	}

	## Check if there was an instance from a previous connection to
	## this web service. If so, return that instead.
	$oldInstance = ${GLOBAL:Lee.Holmes.WebServiceCache}[$wsdlLocation]
	if($oldInstance)
	{
	    $oldInstance
	    return
	}

	## Load the required Web Services DLL
	[void] [Reflection.Assembly]::LoadWithPartialName("System.Web.Services")

	## Download the WSDL for the service, and create a service description from
	## it.
	$wc = new-object System.Net.WebClient

	if($requiresAuthentication)
	{
	    $wc.UseDefaultCredentials = $true
	}

	$wsdlStream = $wc.OpenRead($wsdlLocation)

	## Ensure that we were able to fetch the WSDL
	if(-not (Test-Path Variable:\\wsdlStream))
	{
	    return
	}

	$serviceDescription =
	    [Web.Services.Description.ServiceDescription]::Read($wsdlStream)
	$wsdlStream.Close()

	## Ensure that we were able to read the WSDL into a service description
	if(-not (Test-Path Variable:\\serviceDescription))
	{
	    return
	}

	## Import the web service into a CodeDom
	$serviceNamespace = New-Object System.CodeDom.CodeNamespace
	if($namespace)
	{
	    $serviceNamespace.Name = $namespace
	}

	$codeCompileUnit = New-Object System.CodeDom.CodeCompileUnit
	$serviceDescriptionImporter = 
	    New-Object Web.Services.Description.ServiceDescriptionImporter
	$serviceDescriptionImporter.AddServiceDescription(
	    $serviceDescription, $null, $null)
	[void] $codeCompileUnit.Namespaces.Add($serviceNamespace)
	[void] $serviceDescriptionImporter.Import(
	    $serviceNamespace, $codeCompileUnit)

	## Generate the code from that CodeDom into a string
	$generatedCode = New-Object Text.StringBuilder
	$stringWriter = New-Object IO.StringWriter $generatedCode
	$provider = New-Object Microsoft.CSharp.CSharpCodeProvider 
	$provider.GenerateCodeFromCompileUnit($codeCompileUnit, $stringWriter, $null)

	## Compile the source code.
	$references = @("System.dll", "System.Web.Services.dll", "System.Xml.dll")
	$compilerParameters = New-Object System.CodeDom.Compiler.CompilerParameters 
	$compilerParameters.ReferencedAssemblies.AddRange($references)
	$compilerParameters.GenerateInMemory = $true

	$compilerResults = 
	    $provider.CompileAssemblyFromSource($compilerParameters, $generatedCode)

	## Write any errors if generated.         
	if($compilerResults.Errors.Count -gt 0) 
	{ 
	    $errorLines = "" 
	    foreach($error in $compilerResults.Errors) 
	    { 
		$errorLines += "`n`t" + $error.Line + ":`t" + $error.ErrorText 
	    } 

	    Write-Error $errorLines
	    return 
	}
	## There were no errors.  Create the webservice object and return it.
	else 
	{
	    ## Get the assembly that we just compiled 
	    $assembly = $compilerResults.CompiledAssembly

	    ## Find the type that had the WebServiceBindingAttribute. 
	    ## There may be other "helper types" in this file, but they will 
	    ## not have this attribute
	    $type = $assembly.GetTypes() |
		Where-Object { $_.GetCustomAttributes(
		    [System.Web.Services.WebServiceBindingAttribute], $false) }

	    if(-not $type)
	    {
		Write-Error "Could not generate web service proxy."
		return
	    }

	    ## Create an instance of the type, store it in the cache,
	    ## and return it to the user.
	    $instance = $assembly.CreateInstance($type)

	    ## Many services that support authentication also require it on the
	    ## resulting objects
	    if($requiresAuthentication)
	    {
		if(@($instance.PsObject.Properties | 
		    where { $_.Name -eq "UseDefaultCredentials" }).Count -eq 1)
		{
		    $instance.UseDefaultCredentials = $true
		}
	    }
	    
	    ${GLOBAL:Lee.Holmes.WebServiceCache}[$wsdlLocation] = $instance

	    $instance
	}
}


function global:get-JiraServerInfo
	{
	$jira.GetServerInfo($jiraAuthID)
	}


function global:get-JiraIssueType
	{
	$jira.GetIssueTypes($jiraAuthID)
	}

function global:get-JiraSubtaskIssueType
	{
	$jira.GetSubtaskIssueTypes($jiraAuthID)
	}

function global:get-JiraStatus
	{
	$jira.GetStatuses($jiraAuthID)
	}

function global:get-JiraPriority
	{
	$jira.GetPriorities($jiraAuthID)
	}

function global:get-JiraResolution
	{
	$jira.GetResolutions($jiraAuthID)
	}

function global:get-JiraReport
	{
	$jira.GetSavedFilters($jiraAuthID)
	}

function global:get-JiraProject
	{
	$jira.GetProjects($jiraAuthID)
	}

function global:get-JiraComment ($issueKey)
	{
	$jira.GetComments($jiraAuthID,$issueKey)
	}

function global:new-JiraComment ($issueKey, $comment)
	{
	$jiraComment = new-object RemoteComment
	$jiraComment.body = $comment

	$jira.AddComment($jiraAuthID, $issueKey, $jiraComment)
	}

function global:export-JiraReport ($reportNumber)
	{
	$jira.GetIssuesFromFilter($jiraAuthID, $reportNumber)
	}

# needs work
function global:update-JiraIssue ([string]$issueKey)
	{
	
	$jira.UpdateIssue($jiraAuthID,$issueKey,$placeholder)
	} 

# needs work
function global:set-JiraIssueStatus ($issueKey,$actionID,$placeholder)
	{
	$jira.ProgressWorkflowAction($jiraAuthID,$issueKey,$actionID,$placeholder)
	}

function global:get-JiraIssue ($issueKey)
	{
	$jira.GetIssue($jiraAuthID, $issueKey)
	}

function global:new-JiraIssue ($project, $type, $summary, $description)
	{
	$jiraIssue = new-object RemoteIssue
	$jiraIssue.project = $project
	$jiraIssue.type = $type
	$jiraIssue.summary = $summary
	$jiraIssue.description = $description

	$newIssue = $jira.CreateIssue($jiraAuthID, $jiraIssue)
	
	$newIssue
	}

function global:disconnect-jira
	{
	$jira.logout($jiraAuthID)
	}


$global:jira = connect-jira $jiraURL

if (!$credential)
	{
	$global:credential = get-credential
	}

$BSTR = [System.Runtime.InteropServices.marshal]::SecureStringToBSTR($credential.Password)
$global:jiraAuthID = $jira.login($credential.UserName.TrimStart("\\"),[System.Runtime.InteropServices.marshal]::PtrToStringAuto($BSTR))
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR);


