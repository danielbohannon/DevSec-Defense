# the order of the set custom WSP template
# &#1057;&#1087;&#1080;&#1089;&#1086;&#1082; &#1085;&#1077;&#1086;&#1073;&#1093;&#1086;&#1076;&#1080;&#1084;&#1086;&#1075;&#1086; &#1076;&#1083;&#1103; &#1080;&#1089;&#1087;&#1086;&#1083;&#1100;&#1079;&#1086;&#1074;&#1072;&#1085;&#1080;&#1103; &#1083;&#1080;&#1095;&#1085;&#1086;&#1075;&#1086; WSP &#1096;&#1072;&#1073;&#1083;&#1086;&#1085;&#1072;
#Add-SPSolution D:\\tmp\\ps\\template\\test.wsp
#Install-SPSolution -identity "test.wsp"
#Install-SPSolution -Identity test.wsp -GACDeployment
#Enable-SPFeature test -url http://spf 
# delete WSP
#Remove-SPSolution -identity "test.wsp"
#Uninstall-SPSolution -identity "Test.wsp"

 $site = Get-SPSite http://spf/
$web = $site.RootWeb
$templates = "{055CF2A7-43A8-48E1-95CB-19DC393F0215}#kolam"""

write-host "template = $templates ; web = $web "

New-SPWeb -name 'KoKA2' -url http://spf/koka2 -UseParentTopNav -AddToTopNav -Template  $templates 
# -UniquePermissions #kolam"

 
 #New-SPWeb -Url http://sps2010/sites/mynewsite -Name "my new site" -Template ""{E6BD7EFF-8336-4975-BA22-2256970781E2}#SubWebTemplate"
#" -UseParentTopNav -UniquePermissions
 
 #> 
