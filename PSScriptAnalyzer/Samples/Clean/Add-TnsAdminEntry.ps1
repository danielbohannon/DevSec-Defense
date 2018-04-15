param
(
    [string] $Name = $(Read-Host "Provide a value for parameter 'Name'"),
    [string] $Protocol = 'TCP',
    [string] $Hostname = $(Read-Host "Provide a value for parameter 'Hostname'"),
    [string] $Port = '1521',
    [string] $Sid = $(Read-Host "Provide a value for parameter 'Sid'"),
    [System.IO.FileInfo] $File = $(Read-Host "Provide the tnsnames.ora file path")
)

function Get-OracleDataSources
{
    [System.reflection.assembly]::LoadWithPartialName("System.Data")                                                  
    
    $f = [System.Data.Common.DbProviderFactories]::GetFactory("Oracle.DataAccess.Client")
    
    if ($f.CanCreateDataSourceEnumerator)
    {
        $e = $f.CreateDataSourceEnumerator()                                                                              
        $e.GetDataSources()
    }
}

function Out-TnsAdminFile
{
    param
    (
        [System.Object[]] $Entries,
        [System.IO.FileInfo] $File = $(throw "Parameter -File <System.IO.FileInfo> is required.")
    )
    
    begin 
    {
        if ($File.Exists)
        {
            $originalEntries = @(Get-TnsAdminEntries $File.FullName)
        }
    }
    
    process
    {
        if ($_)
        {
            $Entries = @($_)
        }
    
        $Entries | % {
            
            $entry = $_
            
            $existingEntry = $originalEntries | ? {$_.Name -eq $entry.Name}
            
            if ($existingEntry)
            {
                $existingEntry.Name = $entry.Name
                $existingEntry.Protocol = $entry.Protocol
                $existingEntry.Host = $entry.Host
                $existingEntry.Port = $entry.Port
                $existingEntry.Service = $entry.Service
            }
            else
            {
                $originalEntries += $entry
            }
        }
        
        $originalEntries | % {
        
            $entry = $_
        
            $Name = $entry.Name
            $Protocol = $entry.Protocol
            $Hostname = $entry.Host
            $Port = $entry.Port
            $Service = $entry.Service

            [string] $text += @"
$Name =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = $Protocol)(HOST = $Hostname)(PORT = $Port))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = $Service)
    )
)

"@
        }
        $text | Out-File $File.FullName -Encoding ASCII
        Remove-Variable text
    }
    
    end {}
}

function Get-TnsAdminEntries
{
    param
    (
        [System.IO.FileInfo] $File
    )
    
    begin {}
    
    process
    {
    
        if ($_)
        {
            $File = [System.IO.FileInfo] $_
        }
        if (!$File)
        {
            Write-Error "Parameter -File <System.IO.FileInfo> is required."
            break
        }
        if (!$File.Exists)
        {
            Write-Error "'$File.FullName' does not exist."
            break
        }
        
        [string] $data = gc $File.FullName | ? {!$_.StartsWith('#')}
        
        $pattern =  '(?<name>^(\\w)+[\\s]*?)|\\)\\)(?<name>\\w+)|HOST=(?<host>\\w+)|PORT=(?<port>\\d+)|PROTOCOL=(?<protocol>\\w+)|SERVICE_NAME=(?<service>\\w+)'
        
        $patternMatches = [regex]::Matches($data.Replace(" ", ""), $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        $tnsEntries = @()
        
        for ($i = 0; $i -lt $patternMatches.Count; $i++)
        {
            if ($i -eq 0 -or $i % 5 -eq 0)
            {
                $tnsEntry = New-Object System.Object
                $tnsEntry | Add-Member -type NoteProperty -name Name     -value $patternMatches[$i + 0].Groups["name"].value
                $tnsEntry | Add-Member -type NoteProperty -name Protocol -value $patternMatches[$i + 1].Groups["protocol"].value
                $tnsEntry | Add-Member -type NoteProperty -name Host     -value $patternMatches[$i + 2].Groups["host"].value
                $tnsEntry | Add-Member -type NoteProperty -name Port     -value $patternMatches[$i + 3].Groups["port"].value
                $tnsEntry | Add-Member -type NoteProperty -name Service  -value $patternMatches[$i + 4].Groups["service"].value
                
                $tnsEntries += $tnsEntry
            }
        }
        $tnsEntries
    }
    
    end {}
}

$tnsEntry = New-Object System.Object

$tnsEntry | Add-Member -type NoteProperty -name Name     -value $Name
$tnsEntry | Add-Member -type NoteProperty -name Protocol -value $Protocol
$tnsEntry | Add-Member -type NoteProperty -name Host     -value $Hostname
$tnsEntry | Add-Member -type NoteProperty -name Port     -value $Port
$tnsEntry | Add-Member -type NoteProperty -name Service  -value $Sid

$tnsEntry | Out-TnsAdminFile -File $File

