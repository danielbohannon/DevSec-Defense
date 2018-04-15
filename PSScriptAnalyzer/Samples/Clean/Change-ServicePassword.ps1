Param([string]$server,[string]$service,[string]$user,[string]$password)
Begin{
	function ChangeServicePassword{
        Param([string]$srv,[string]$ms,[string]$usr,[string]$pwd)
        
        # Setup for WMI
        $class = "Win32_Service"
        $method = "change"
        $computer = $srv
        $filter = "Name=`'$ms`'"
        
        # Getting Service Via WMI
        $MyService = get-WmiObject $class -computer $computer -filter $filter
        
        # Setting Parameters for Change Method
        $inparams = $MyService.psbase.GetMethodParameters($method)
        $inparams["StartName"] = $usr
        $inparams["StartPassword"] = $pwd
        
        # Calling Change Method and Return $results
        $result = $MyService.psbase.InvokeMethod($method,$inparams,$null)
        if($result.ReturnValue -eq 0)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
	Write-Host
	$process = @()
}
Process{
	if($_){
		if($_.ServerName){
			$process += $_.ServerName
		}
		else{
			$process += $_
		}
	}
}
End{
	if($Server){$Process += $Server}
	if($process.Length -eq 0){$Process += get-content env:COMPUTERNAME}
	foreach($s in $process)
    {
		if(ChangeServicePass -Srv $s -ms $service -usr $user -pwd $password)
        {
            Write-host "Service [$Service] changed on Server [$s] now using [$user]" 
        }
        else
        {
            Write-Host "Service Change Failed on Server[$s]"
        }
		Write-Host
	}
}

