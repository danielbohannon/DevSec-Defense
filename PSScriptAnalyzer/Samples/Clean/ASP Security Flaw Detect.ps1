#
# This script will help detect vulnerable configuration for the Padding Oracle 
# ASP.Net vulnerability documented in MS advisory 2416728.
# 

cls
function List-WebServerPaths($server_instance) {
	foreach($child in $server_instance.get_Children()) {
		if($child.get_SchemaClassName() -eq "IIsWebVirtualDir")
		{
			$out = $child | select SchemaClassName, Path
			$parent = new-object System.DirectoryServices.DirectoryEntry($child.Parent)
			if($root_path -ne $child.Path) {
				Detect-OraclePaddingSecurityFlaw $child.Path $parent.Properties["ServerComment"].ToString()
			}
		}
		if($child.get_SchemaClassName() -eq "IIsWebServer")
		{
			List-WebServerPaths $child
		}
	}
}
function Detect-OraclePaddingSecurityFlaw($virtual_directory_path, $server_comment) {
 	$out = New-Object psobject
	
	$count = (Get-ChildItem $virtual_directory_path -Recurse | ? { $_.Name -eq "web.config" }).count
	Get-ChildItem $virtual_directory_path -Recurse | ? { $_.Name -eq "web.config" } | select FullName | %{
		$root_web_config = $virtual_directory_path.ToString() +"\\" +"web.config"
		$CurrentPath = $_
		if(Test-Path $CurrentPath.FullName) {
			if($root_web_config -eq $CurrentPath.FullName) {
				$resultant_obj = Check-WebConfig $server_comment $virtual_directory_path $CurrentPath.FullName $true 
				$index = $list.Add($resultant_obj);
			}
			else {
				$resultant_obj = Check-WebConfig $server_comment $virtual_directory_path $CurrentPath.FullName $false 
				$index = $list.Add($resultant_obj);
			}
		}
	}
}
# Check the web.config
function Check-WebConfig($name, $server_comment, $webconfig_path, $is_root) {
 	$out = New-Object psobject
	$out | add-member -MemberType NoteProperty -Name "Path" -Value $webconfig_path
	$out | add-member -MemberType NoteProperty -Name "Is Root" -Value $is_root
	$xml = [xml](Get-Content $webconfig_path);
	$root = $xml.get_DocumentElement();
	$custom_errors = $root."system.web".customErrors;
	
	if($is_root) {
		$siteName = "{" +$name +"}"
		$out | add-member -MemberType NoteProperty -Name "Name" -Value $siteName
	}
	else {
		$dirName = (Get-Item $webconfig_path).DirectoryName
		$dirName = $dirName.Substring($dirName.LastIndexOf("\\") + 1)
		$siteName = "{" +$name +" - " +$dirName +"}"
		$out | add-member -MemberType NoteProperty -Name "Name" -Value $siteName
	}
	if($custom_errors -eq $null -and $is_root) {
		$out | add-member -MemberType NoteProperty -Name "Disabled" -Value $true
		$out | add-member -MemberType NoteProperty -Name "Non Homogenous" -Value $false
	}
	else {
		$status = Check-CustomErrorsMode $custom_errors $is_root
		$disabled_status = -not $status
		$out | add-member -MemberType NoteProperty -Name "Disabled" -Value $disabled_status
		
		$HomogeneityStatus = Check-CustomErrorsHomogeneity $custom_errors
		$out | add-member -MemberType NoteProperty -Name "Non Homogenous" -Value $HomogeneityStatus
	}
	return $out;
}
# Get the Page Url given the HTTP Error Code
function Get-ErrorPages($error_nodes_list,$error_num)
{
	$pageUrl = ""
	foreach($error_node in $error_nodes_list)
	{
		if($error_node.statusCode -ne $null)
		{
			if($error_node.statusCode -eq $error_num)
			{
				$pageUrl = $error_node.redirect
			}
		}
	}
	return $pageUrl;
}
# Check Error Homogeneity 
# Comparing the Default Error Page, 404 & 500 Error Pages
function Check-CustomErrorsHomogeneity($custom_errors_list) {
	$HomogeneityStatusResult = $false;
	$error_nodes_list = ($custom_errors_list.error)
	$count = $error_nodes_list.Count
				
	if($count -gt 0) {
		$404Pages = Get-ErrorPages($error_nodes_list,404)
		$500Pages = Get-ErrorPages($error_nodes_list,500)
	}
	else {
		$404Pages = ""
		$500Pages = ""
	}
	
	$defaultRedirect = $custom_errors_list.defaultRedirect
	if($404Pages -eq "" -and $500Pages -eq ""  -and $defaultRedirect -eq $null)
	{
		# Missing defaultRedirect in this case will cause config to be vulnerable

		$HomogeneityStatusResult = $true
	}
	elseif($404Pages -eq "" -and $500Pages -ne "" -and $500Pages -notcontains $defaultRedirect)
	{
		# 500 and default error pages
		$HomogeneityStatusResult = $true
	}
	elseif($500Pages -eq "" -and $404Pages -ne "" -and $404Pages -notcontains $defaultRedirect) 
	{
		# 404 and default error pages differ
		$HomogeneityStatusResult = $true
	}
	elseif($500Pages -ne $404Pages) 
	{
		# 404 and 500 error pages differ
		$HomogeneityStatusResult = $true
	}
	return $HomogeneityStatusResult;
}
function Get-ApplicationUsage($invalidInput, $userInput)
{
	
	Write-Host -ForegroundColor Green "Note the Configuration Items Numbers above and enter the items that you need to fix for which either Attribute is true."
	Write-Host -ForegroundColor DarkGreen --------------------------------------------------------------
	Write-Host -ForegroundColor Green - USAGE ********************************************************
	Write-Host -ForegroundColor DarkGreen --------------------------------------------------------------
	Write-Host -ForegroundColor Green "**** Valid User Input Example: 1-2,3,4-5 <<VALID>> *******"
	Write-Host -ForegroundColor Red   "**** InValid User Input Example: -2,-3,, <<INVALID>>*******"
	Write-Host 
	Write-Host -ForegroundColor DarkGreen  "Note: Enter 0(zero) or 'exit' to terminate the shell instance."
	Write-Host 
	Write-Host -ForegroundColor Blue "* Disabled - Indicates that the customError Section of the Configuration is disabled and needs to be rearmed with defaultRedirect Attribute"
	Write-Host -ForegroundColor DarkBlue "* Non Homogenous - Indicates that the customError Section of the Configuration is either disabled or has different Urls for different error types, it needs to be same so that the attacker does not do a differential analysis of the response."
	Write-Host
	if($invalidInput -ne $null -and $invalidInput) {
		Write-Host 
		Write-Host -ForegroundColor Red  $userInput " is invalid User Input. Please refer USAGE details above."
		Write-Host 
	}
	$userInput = Read-Host -Prompt "Enter your items to fix: "
	return $userInput;
}
function Check-CustomErrorsMode($custom_errors_node, $is_root) {
	$mode = $custom_errors_node.mode;
	$defaultRedirect = $custom_errors_node.defaultRedirect
	if($mode -eq "off") {
		return $false;
	}
	elseif($defaultRedirect -eq $null -and $is_root) {
		return $false;
	}
	else {
		return $true;
	}
}

$root_path_obj = New-Object System.DirectoryServices.DirectoryEntry("IIS://localhost/W3SVC/1")
foreach($child in $root_path_obj.get_Children()) {
	if($child.get_SchemaClassName() -eq "IIsWebVirtualDir")
	{
		$root_path = $child.Path
	}
}

$list = new-Object system.Collections.ArrayList
$fix_numbers = new-Object system.Collections.ArrayList
$root = New-Object System.DirectoryServices.DirectoryEntry("IIS://localhost/W3SVC")
List-WebServerPaths $root
[int]$arrIndex = 1;
$list | %{ $_ | add-member -MemberType NoteProperty -Name "No" -Value $arrIndex;$arrIndex++; 
	};
[string]$userInput = ""
$list | select No, Name, "Is Root","Disabled", "Non Homogenous", Path | Format-Table -Wrap No, Name, "Is Root","Disabled", "Non Homogenous", Path 


