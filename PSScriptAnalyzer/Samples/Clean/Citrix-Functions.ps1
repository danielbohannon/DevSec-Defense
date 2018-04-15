#########################################
####     Citrix Farm Functions       ####
#########################################
# Get Citrix Farm
function Get-CitrixFarm{
    param($Server)
    $type = [System.Type]::GetTypeFromProgID("MetaframeCOM.MetaframeFarm",$Server)
    $mfarm = [system.Activator]::CreateInstance($type)
    $mfarm.Initialize(1)
    return $mFarm
}

# Get Online Servers by Zone
function Get-CitrixOnline {
    Param($zone)
    $mfzone = New-Object -ComObject MetaFrameCOM.MetaFrameZone
    $mfzone.Initialize($zone)
    $servers = $mfzone.OnlineServers
    $servers
}

# Get Citrix Load Evaluators (only 4.0/4.5)
function Get-CitrixLE{
    Param($server=$(throw "Server is Required"))
    function Load-Farm{
        param($srv)
        $type = [System.Type]::GetTypeFromProgID("MetaframeCOM.MetaframeFarm",$srv)
        $mfarm = [system.Activator]::CreateInstance($type)
        $mfarm.Initialize(1)
        return $mFarm
    }
    $Farm = load-farm $server
    if($Farm.LoadEvaluators){
        foreach($eval in $Farm.LoadEvaluators)
        {
            $eval.loadData(1)
            "+ Load Evaluator: {0}" -f $eval.LEName
            $servers = $eval.AttachedServers(1)
            if($servers.count -ne 0)
            {
                "  + Servers"
                $servers | %{"    - {0}" -f $_.ServerName}
            }
            $rules = $eval.rules | Select-Object RuleType,HWM,LWM,Schedules
            if($rules.count -ne 0)
            {
                "  + Rules"
                foreach($rule in $rules)
                {
                    "    - {0}" -f $rule
                }
            }
        }
    }
}

# Gets the Citrix Printer Drivers for the Farm (Can be REAL slow)
function Get-CitrixPrintDrivers{
    Param($server=$(throw "Server is Required"))
    function Load-Farm{
        param($srv)
        $type = [System.Type]::GetTypeFromProgID("MetaframeCOM.MetaframeFarm",$srv)
        $mfarm = [system.Activator]::CreateInstance($type)
        $mfarm.Initialize(1)
        return $mFarm
    }
    $farm = Load-Farm $Server
    $farm.Drivers 
}

# Gets Citrix Policies
function Get-CitrixPolicies{
    param($Server)
    function Load-Farm{
        param($srv)
        $type = [System.Type]::GetTypeFromProgID("MetaframeCOM.MetaframeFarm",$srv)
        $mfarm = [system.Activator]::CreateInstance($type)
        $mfarm.Initialize(1)
        return $mFarm
    }
    $farm = Load-Farm $server
    $type = [System.Type]::GetTypeFromProgID("MetaFrameCOM.MetaFrameUserPolicy")
    foreach($pol in $Farm.policies($type))
    {
        $pol.loadData(1)
        "+ Name: {0}" -f $pol.Name
        "  - Description: {0}" -f $pol.Description
        "  - Enabled: {0}" -f $pol.Enabled
        if($pol.AllowedAccounts)
        {
            "  + AllowedAccounts"
            foreach($aa in $pol.AllowedAccounts)
            {
                "    - {0}" -f $aa.AccountName
            }
        }
        if($pol.UserPolicy2)
        {
            "  + UserPolicy"
            $props = $pol.UserPolicy2 | Get-Member -membertype Property | %{$_.Name} | Sort-Object Name
            foreach($prop in $props)
            {
                if(($pol.UserPolicy2.$prop -match "\\d") -and ($pol.UserPolicy2.$prop -ne 0))
                {
                    "     - {0}:{1}" -f $prop,$pol.UserPolicy2.$prop
                }
            }
        }
        write-Output " "
    }
}

# Set-CitrixLoadEvalutor
function Set-CitrixLoadEvalutor{
    Param($server = $(throw '$Server is Required'),$LoadEvaluator = "MFDefaultLE")
    
    # Loading Server Object
    $type = [System.Type]::GetTypeFromProgID("MetaframeCOM.MetaframeServer",$Server)
    $mfServer = [system.Activator]::CreateInstance($type)
    $mfServer.Initialize(6,$Server)
    
    # Getting Current LE
    $le = $mfServer.AttachedLE
    $le.LoadData(1)
    Write-Host "Old Evaluator: $($le.LEName)"
    Write-Host "Setting Load Evaluator on $server to $LoadEvaluator"
    
    # Assigning New LE
    $mfServer.AttachLEByName($LoadEvaluator)
    
    # Checking LE
    $le = $mfServer.AttachedLE
    $le.LoadData(1)
    Write-Host "Load Evaluator Set to $($le.LEName)"
}

#########################################
####     Citrix App Functions        ####
#########################################

# Gets Citrix App
function Get-CTXApplication{
    Param($Server,$AppName)
    $type = [System.Type]::GetTypeFromProgID("MetaframeCOM.MetaFrameApplication",$Server)
    $app = [system.Activator]::CreateInstance($type)
    Write-Verbose "Loading Farm for $Server"
    $app.Initialize(3,$appName)
    $app.LoadData(0)
    $app
}

# Outputs the number of Users using a Citrix App or Apps
function Get-ApplicationUserCount {
    Param([string]$app,[string]$farmServer = $(throw '$FarmServer is Required'))
    function List-AllCitrixApps{
        Param($mFarm)
        ForEach($app in $mFarm.Applications) 
        {
            $name = $app.BrowserName.PadRight(25)
            $count = "$($app.Sessions.Count)"
            $count = $count.PadRight(10)
            Write-Host "$name $count"
        }
    }
    function List-App{
        param($mApp,$mfFarm)
        ForEach($app in $mfFarm.Applications) 
        {
            if($app.BrowserName -eq "$mApp") 
            { 
                $name = $app.BrowserName.PadRight(25)
                $count = "$(($app.Sessions | ?{$_.SessionState -eq 1}).Count)"
                $count = $count.PadRight(10)
                Write-Host "$name $count"
            }
        }
    }
    function Load-Farm{
        $type = [System.Type]::GetTypeFromProgID("MetaframeCOM.MetaframeFarm",$srv)
        $mfarm = [system.Activator]::CreateInstance($type)
        $mfarm.Initialize(1)
        return $mFarm
    }
    Write-Host 
    $title1 = "Application".PadRight(25)
    $title2 = "===========".PadRight(25)
    Write-Host "$title1 User Count" -ForegroundColor White
    Write-Host "$title2 ==========" -ForegroundColor Red
    $mf = Load-Farm $farmServer
    While($true) 
    {
        $oldpos = $host.UI.RawUI.CursorPosition
        If($app) 
        {
            List-App $app $mf
        }
        else
        {
            List-AllCitrixApps $mf                    
        }
        sleep(5)
        $host.UI.RawUI.CursorPosition = $oldpos
    }
    Write-Host ""
}

# Finds what Server a User is on
function Find-CitrixUser {
    Param([string]$LoginName,[switch]$verbose)
    $user = $LoginName.Split("\\")[1]
    $Domain = $LoginName.Split("\\")[0]
    $mfuser = New-Object -ComObject MetaframeCOM.MetaframeUser
    $mfuser.Initialize(1,$Domain,1,$user)
    Write-Host
    Write-Host "User: $($mfuser.UserName) found on the Following:"
    foreach ($s in $mfuser.Sessions)
    {
        if($verbose)
        {
            Write-Host 
            Write-Host "$($s.ServerName)"
            Write-Host "-=-=-=-=-=-"
            Write-Host "AppName          : $($s.AppName)" -foregroundcolor yellow
            Write-Host "SessionName      : $($s.SessionName)" -foregroundcolor yellow
            Write-Host "SessionID        : $($s.SessionID)" -foregroundcolor yellow
            Write-Host "ClientAddress    : $($s.ClientAddress)" -foregroundcolor yellow
            Write-Host "ClientEncryption : $($s.ClientEncryption)" -foregroundcolor yellow
            Write-Host  
            Write-Host "Processes"
            Write-Host "========="
            foreach ($proc in $s.Processes)
            {
                Write-Host $proc.ProcessName -foregroundcolor Green
            }
            Write-host
        }
        else
        {
            write-Host "   -> $($s.ServerName)"        
        }
    }
}

# Gets Servers Published for specified App (or just returns count)
function Get-CitrixAppServers {
    Param($app = $(throw '$app is required'),[switch]$count)
    $mfm = New-Object -com MetaFrameCOM.MetaFrameFarm
    $mfm.Initialize(1)
    $servers = $mfm.Applications | ?{$_.AppName -eq $app}
    $servers = $servers.Servers | sort -Property ServerName
    if($count)
    {
        Write-Host 
        Write-Host "Found [$($Servers.Count)] Servers for Application [$app]" -ForegroundColor White
        Write-Host 
    }
    else
    {
        Write-Host ""
        Write-Host "Found [$($Servers.Count)] Servers for Application [$app]" -ForegroundColor White
        Write-Host "-----------------------------------------------" -ForegroundColor gray
        foreach($server in $servers){Write-Host "$($server.ServerName)" -ForegroundColor Green}
        Write-Host "-----------------------------------------------" -ForegroundColor gray
        Write-Host "Found [$($Servers.Count)] Servers for Application [$app]" -ForegroundColor White
        Write-Host ""
    }
}

# Returns Users currently using Citrix App
function Get-CitrixAppUsers {
	Param($app = $(throw '$app is required'),[switch]$count)
	$ErrorActionPreference = "SilentlyContinue"
	Write-host
	$mfm = New-Object -com MetaFrameCOM.MetaFrameFarm
	$mfm.Initialize(1)
	$users = $mfm.Applications | ?{$_.AppName -eq $app} 
	$Users = $users.Sessions | sort -Property UserName
	if($count){
		Write-Host "Found [$($Users.Count)] Users for Application [$app]" -ForegroundColor White
		Write-Host
	}
	else{
		Write-Host ""
		Write-Host "Found [$($Users.Count)] Users for Application [$app]" -ForegroundColor White
		Write-Host "-----------------------------------------------------" -ForegroundColor gray
		foreach($user in $Users){
			If($User.SessionState -eq 1){
				Write-Host ($User.UserName).PadRight(10) -ForegroundColor Green -NoNewline 
			}
			else{
				Write-Host ($User.UserName).PadRight(10) -ForegroundColor yellow -NoNewline 
			}
		}
		Write-Host 
		Write-Host "-----------------------------------------------------" -ForegroundColor gray
		Write-Host "Found [$($Users.Count)] Users for Application [$app]" -ForegroundColor White
		Write-Host
	}
}

# Sets PNFolder for App
function Set-CTXAppFolder{
    param($Server,$folder,$filter,[switch]$add,[switch]$remove,[switch]$verbose,[switch]$whatif)
    if($verbose){$VerbosePreference = "Continue"}
    Write-Verbose "Loading Remote DCOM"
    $type = [System.Type]::GetTypeFromProgID("MetaframeCOM.MetaframeFarm",$Server)
    $mfarm = [system.Activator]::CreateInstance($type)
    Write-Verbose "Loading Farm for $Server"
    $mfarm.Initialize(1)
    if($filter)
    {
        Write-Verbose "Getting Apps for $Filter"
        $Applications = $mFarm.Applications | Where-Object{$_.BrowserName -match $filter}
    }
    else
    {
        Write-Verbose "Returning All Apps"
        $Applications = $mFarm.Applications | Where-Object{$_.BrowserName -match $filter}
    }
    foreach($app in $Applications)
    {
        Write-Verbose "Loading $($app.BrowserName)"
        $app.LoadData(0)
        if($Remove)
        {
            if($app.PNFolder -eq $folder)
            {
                Write-Verbose "Removing $Folder for $($app.BrowserName)"
                $app.PNFolder = ""
                if(!$whatif){$app.SaveData()}
            }
        }
        if($add)
        {
            Write-Verbose "Adding $Folder for $($app.BrowserName)"
            $app.PNFolder = $folder
            if(!$whatif){$app.SaveData()}
        }
        "APP: {0,-15}Folder:{1}" -f $app.BrowserName,$app.PNFolder
    }
}

# Adds user to Citrix App
function Add-CTXApplicationUser{
    Param($Server,$AppName,$UserName)
    $domain = $userName.split('\\')[0]
    $user = $userName.split('\\')[1]
    $type = [System.Type]::GetTypeFromProgID("MetaframeCOM.MetaFrameApplication",$Server)
    $app = [system.Activator]::CreateInstance($type)
    Write-Verbose "Loading Farm for $Server"
    $app.Initialize(3,$appName)
    $app.LoadData(0)
    $app.AddUser(1,$domain,2,$user)
    $app.SaveData()
}

##########################################
####     Citrix Server Functions      ####
##########################################
# Get a Citrix Server Object
function Get-CitrixServer{
    Param($Server)
    $type = [System.Type]::GetTypeFromProgID("MetaframeCOM.MetaframeServer",$Server)
    $mfServer = [system.Activator]::CreateInstance($type)
    $mfServer.Initialize(6,$Server)
    $mfServer
}

# Publish Application to Server(s)
function Publish-CitrixApplication{
	Param([string]$server,[string]$app)
	Begin{
		Write-Host
		function cPublish {
			Param([string]$Srv,[string]$myapp)
			$Srv = $Srv.toUpper()
			$mfSrv = New-Object -ComObject MetaFrameCOM.MetaFrameServer
			$mfSrv.Initialize(6,"$Srv")
			$mfApp = New-Object -ComObject MetaFrameCOM.MetaFrameApplication
			$mfApp.Initialize(3,"Applications\\$myapp")
			$mfApp.LoadData($true)
			$mfAppBinding = New-Object -ComObject MetaFrameCOM.MetaFrameAppSrvBinding
			$mfAppBinding.Initialize(6,$Srv,"Applications\\$app")
			if($mfAppBinding) 
            {
				Write-Host "Publishing App[$myapp] on Server [$Srv]" -ForegroundColor Green
				$mfApp.AddServer($mfAppBinding)
				$mfApp.SaveData()
			}
			else 
            {
				Write-Host "Unable To Create App Binding" -ForegroundColor Red
			}
		}
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
		foreach($s in $process){
			cPublish -srv $s -myapp $app
			Write-Host
		}
	}
}

# UnPublish All Application from Server(s)
function UnPublish-CitrixServer{
	Param([string]$server)
	Begin{
		function cUnPublish {
			Param([string]$Srv)
			$Srv = $Srv.toUpper()
			$mfSrv = New-Object -ComObject MetaFrameCOM.MetaFrameServer
			$mfSrv.Initialize(6,"$Srv")
			If($mfSrv.Applications.Count -gt 0) 
            {
				Write-Host "Removing All Published Applications from $Srv" -ForegroundColor Red
				Write-Host "===================================================" -ForegroundColor Green
				ForEach($a in $mfSrv.Applications) 
                {	     
					$myApp = $a.AppName
					Write-Host "Removing App [$myApp] from Server [$Srv]" -ForegroundColor White
					$a.RemoveServer($Srv)
					$a.SaveData()
				}
			}
			else 
            {
				Write-Host "No Published Applications for $Srv" -ForegroundColor Red
			}
		}
		Write-Host
		$process = @()
	}
	Process{
		if($_){
			if($_.ServerName)
            {
				$process += $_.ServerName
			}
			else
            {
				$process += $_
			}
		}
	}
	End{
		if($Server){$Process += $Server}
		foreach($s in $process){
			cUnPublish $s
			Write-Host
		}
	}
}

# Remove a Citrix App from Server
function Remove-CitrixApplication {
	Param([string]$server,[string]$app)
	Begin{
		function RemoveApp {
			Param([string]$Srv,[string]$myapp)
			$AppRemoved = $false
			$Srv = $Srv.toUpper()
			$mfSrv = New-Object -ComObject MetaFrameCOM.MetaFrameServer
			$mfSrv.Initialize(6,"$Srv")
			If($mfSrv.Applications.Count -gt 0) 
            {
				ForEach($a in $mfSrv.Applications) 
                {	     
					If($a.AppName -eq "$myapp") 
                    {
						Write-Host "Removing App [$myApp] from Server [$Srv]" -ForegroundColor Green
						$a.RemoveServer($Srv)
						$a.SaveData()
						$AppRemoved = $true
					}
				} 
			}
			else 
            {
				Write-Host "No Applications Published for $Srv" -ForegroundColor Red
				$AppRemoved = $true
			}
			If($AppRemoved -eq $false) 
            {
				Write-Host "This Application not Published for $Srv" -ForegroundColor Red
			}
		}
		Write-Host
		$process = @()
	}
	Process{
		if($_)
        {
			if($_.ServerName){
            
				$process += $_.ServerName
			}
			else
            {
				$process += $_
			}
		}
	}
	End{
		if($Server){$Process += $Server}
		if($process.Length -eq 0){$Process += get-content env:COMPUTERNAME}
		foreach($s in $process)
        {
			RemoveApp -Srv $s -myapp $app
			Write-Host
		}
	}
}

# List Citrix Apps Published to Server
function Get-CitrixApplications {
	Param([string]$Server)
	Begin {
		Write-Host
		function cGetApps {
			param([string]$srv)
			$srv = $srv.ToUpper()
			$mfsrv = New-Object -ComObject MetaFrameCOM.MetaFrameServer
			$mfsrv.Initialize(6,"$srv")
			Write-Host "SERVER $srv" -foregroundcolor Red
			Write-Host "==================" -ForegroundColor Green
			If($mfSrv.Applications.Count -gt 0) {
				$mfSrv.Applications | %{Write-Host "Published:   $($_.AppName.ToUpper())"}
			}
			else {
				Write-Host "No Applications Published for $srv" -foregroundcolor white
			}
		}
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
	End {
		if($Server){$Process += $Server}
		foreach($s in $process){
			cGetApps $s
			Write-Host
		}
	}
}

# Return Current Terminal Server User Count
function Get-TSUserCount {
	Param([string]$Server)
	Begin{
		function TsUserCount {
			param([string]$srv)
			$msg = "Checking For Users on Server [$srv]"
			$msg = $msg.PadRight($pad)
			Write-host $msg -ForegroundColor White 
			$msg = "==========================================="
			$msg = $msg.PadRight($pad)
			Write-host $msg -ForegroundColor gray 
			$msg = "Terminal Server User Count on Server " 
			$msg1 = "[$srv]"
			$msg1 = $msg1.PadRight($pad)
			$ts = Get-WmiObject Win32_PerfFormattedData_TermService_TerminalServices -ComputerName $srv
			$count = $ts.activeSessions
			If($count -eq 0) 
            {
				Write-host "$msg [Users:$count]" -ForegroundColor Green
			}
			else 
            {
				Write-host "$msg [Users:$count]" -ForegroundColor Yellow
			}
		}
		$process = @()
	}
	Process{
		if($_){
			if($_.ServerName)
            {
				$process += $_.ServerName
			}
			else
            {
				$process += $_
			}
		}
	}
	End{
		if($Server){$Process += $Server}
		if($process.Length -eq 0){$Process += get-content env:COMPUTERNAME}
		foreach($s in $process)
        {
			TSUserCount $s
			Write-Host
		}
	}
}
