## SVN STAT colorizer - http://www.overset.com/2008/11/18/colorized-subversion-svn-stat-powershell-function/
function ss () {
	$c = @{ "A"="Magenta"; "D"="Red"; "C"="Yellow"; "G"="Blue"; "M"="Cyan"; "U"="Green"; "?"="DarkGray"; "!"="DarkRed" }
	foreach ( $svno in svn stat ) {  
		if ( $c.ContainsKey($svno.ToString().SubString(0,1).ToUpper()) ) { 
			write-host $svno -Fore $c.Get_Item($svno.ToString().SubString(0,1).ToUpper()).ToString()
		} else { 
			write-host $svno
		}
	}
}
