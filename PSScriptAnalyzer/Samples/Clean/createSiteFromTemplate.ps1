# Load the template
$url = "http://spf" # where template base
$namesite = "Good Site" #name new site title
$targeturl = "goodsite" #name url new site
# find id = viewAlltemplate
$templateID = "{055CF2A7-43A8-48E1-95CB-19DC393F0215}"
#$templateID = "{055CF2A7-43A8-48E1-95CB-19DC393F0215}#kolam"

$site= new-Object Microsoft.SharePoint.SPSite($url ) 
# 1049 - russian, 1033 -english
$loc= [System.Int32]::Parse(1049) 

# have list template with Russian localization
$templates= $site.GetWebTemplates($loc) 

#Write-Host "templates = " $templates

# view all templates in table - 
# this for find id custom template for installing
foreach ($child in $templates){    write-host $child.Name "  " $child.Title} 
# &#1058;&#1077;&#1086;&#1088;&#1077;&#1090;&#1080;&#1095;&#1077;&#1089;&#1082;&#1080; - &#1074;&#1099;&#1089;&#1074;&#1086;&#1073;&#1086;&#1078;&#1076;&#1072;&#1077;&#1090; &#1088;&#1077;&#1089;&#1091;&#1088;&#1089;&#1099;
$site.Dispose() 

#look in the Output for the right one, and copy the Template Name

#create a new-SPWeb
$web = New-SPWeb -Url http://spf/$targeturl -Name "$namesite" -UseParentTopNav -AddToTopNav -UniquePermissions

#-Template ""{E6BD7EFF-8336-4975-BA22-2256970781E2}#SubWebTemplate"


# Another option is to create the New-SPWeb without the
#-template argument. Then you can apply the custom template 
# by following line:
$web.ApplyWebTemplate($templateID)

