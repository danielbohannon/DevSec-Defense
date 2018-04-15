[Array]$ExchSrvs = @("")
[String]$StrFilter = “(objectCategory=msExchExchangeServer)”
$objRootDSE = [ADSI]“LDAP://RootDSE”
[String]$strContainer = $objRootDSE.configurationNamingContext
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = New-object `
System.DirectoryServices.DirectoryEntry(”LDAP://$strContainer”)
$objSearcher.PageSize = 1000
$objSearcher.Filter = $strFilter
$objSearcher.SearchScope = “Subtree”
$colResults = $objSearcher.FindAll()
ForEach($objResult in $colResults)
{
[String]$Server = $objResult.Properties.name
$ExchSrvs += $Server
}
$ExchSrvs.Count
