#Author:    	Glenn Sizemore glnsize@get-admin.com
#
#Purpose:	Convert a DN to a conicalname, and back again.
#
#Example:	PS > ConvertFrom-Canonical 'get-admin.local/test/test1/Sizemore, Glenn E'
#		CN=Sizemore\\, Glenn E,OU=test1,OU=test,DC=getadmin,DC=local
#	 	PS > ConvertFrom-DN 'CN=Sizemore\\, Glenn E,OU=test1,OU=test,DC=getadmin,DC=local'
#		get-admin.local/test/test1/Sizemore, Glenn E


function ConvertFrom-DN 
{
param([string]$DN=(Throw '$DN is required!'))
    foreach ( $item in ($DN.replace('\\,','~').split(",")))
    {
        switch -regex ($item.TrimStart().Substring(0,3))
        {
            "CN=" {$CN = '/' + $item.replace("CN=","");continue}
            "OU=" {$ou += ,$item.replace("OU=","");$ou += '/';continue}
            "DC=" {$DC += $item.replace("DC=","");$DC += '.';continue}
        }
    } 
    $canoincal = $dc.Substring(0,$dc.length - 1)
    for ($i = $ou.count;$i -ge 0;$i -- ){$canoincal += $ou[$i]}
    $canoincal += $cn.ToString().replace('~',',')
    return $canoincal
}

function ConvertFrom-Canonical 
{
param([string]$canoincal=(trow '$Canonical is required!'))
    $obj = $canoincal.Replace(',','\\,').Split('/')
    [string]$DN = "CN=" + $obj[$obj.count - 1]
    for ($i = $obj.count - 2;$i -ge 1;$i--){$DN += ",OU=" + $obj[$i]}
    $obj[0].split(".") | ForEach-Object { $DN += ",DC=" + $_}
    return $dn
}
