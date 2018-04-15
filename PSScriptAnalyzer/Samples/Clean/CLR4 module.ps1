function Start-CLR4 {
   
	[CmdletBinding()]
    
	param ( [string] $cmd )


    
    if ($PSVersionTable.CLRVersion.Major -eq 4) 
    {    
	write-debug 'already running clr 4'
	invoke-expression $cmd;
	return
    }

    $RunActivationConfigPath = resolve-path ~ | Join-Path -ChildPath .CLR4PowerShell;
    
    write-debug "clr4 config path: $runactivationconfigpath"

    if( -not( test-path $runactivationconfigpath ))
    {
	   New-Item -Path $RunActivationConfigPath -ItemType Container | Out-Null;
    

@"
<?xml version="1.0" encoding="utf-8" ?>
<configuration>
  <startup useLegacyV2RuntimeActivationPolicy="true">
  <supportedRuntime version="v4.0"/>
</startup>
</configuration>
"@ | Set-Content -Path $RunActivationConfigPath\\powershell.exe.activation_config -Encoding UTF8;

    }
    
    $EnvVarName = 'COMPLUS_ApplicationMigrationRuntimeActivationConfigPath';
    [Environment]::SetEnvironmentVariable($EnvVarName, $RunActivationConfigPath);
    
    write-debug "current COMPLUS_ApplicationMigrationRuntimeActivationConfigPath: $env:COMPLUS_ApplicationMigrationRuntimeActivationConfigPath";

    & powershell.exe -nologo -command "$cmd";
}


