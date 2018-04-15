add-type -AssemblyName "Microsoft.SqlServer.ConnectionInfo, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
add-type -AssemblyName "Microsoft.SqlServer.Smo, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
add-type -AssemblyName "Microsoft.SqlServer.SMOExtended, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
add-type -AssemblyName "Microsoft.SqlServer.SqlEnum, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"
add-type -AssemblyName "Microsoft.SqlServer.Management.Sdk.Sfc, Version=10.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"


#######################
<#
.SYNOPSIS
Backs up a database object definition.
.DESCRIPTION
The Backup-DatabaseObject function backs up a database object definition by scripting out the object to a .sql text file.
.EXAMPLE
Backup-DatabaseObject -ServerInstance Z002 -Database AdventureWorks -Schema HumanResources -Name vEmployee -Path "C:\\Users\\Public"
This command backups up the vEmployee view to a .sql file.
.NOTES 
Version History 
v1.0   - Chad Miller - Initial release 
#>
function Backup-DatabaseObject
{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullorEmpty()]
    [string]$ServerInstance,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullorEmpty()]
    [string]$Database,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullorEmpty()]
    [string]$Schema,
    #Database Object Name
    [Parameter(Mandatory=$true)]
    [ValidateNotNullorEmpty()]
    [string]$Name,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullorEmpty()]
    [string]$Path
    )
    
    $server = new-object Microsoft.SqlServer.Management.Smo.Server($ServerInstance)
    $db = $server.Databases[$Database]

    #Create a UrnCollection. URNs are used by SMO as unique identifiers of objects. You can think of URN like primary keys
    #The URN format is similar to XPath
    $urns = new-object Microsoft.SqlServer.Management.Smo.UrnCollection

    #Get a list of database object which match the schema and object name specified
    #New up an URN object and add the URN to the urns collection
    $db.enumobjects() | where {$_.schema -eq $Schema -and  $_.name -eq $Name } |
        foreach {$urn = new-object Microsoft.SqlServer.Management.Sdk.Sfc.Urn($_.Urn);
                 $urns.Add($urn) }

    if ($urns.Count -gt 0) {
        
        #Create a scripter object with a connection to the server object created above
        $scripter = new-object Microsoft.SqlServer.Management.Smo.Scripter($server)
        
        #Set some scripting option properties
        $scripter.options.ScriptBatchTerminator = $true
        $scripter.options.FileName = "$Path\\BEFORE_$Schema.$Name.sql"
        $scripter.options.ToFileOnly = $true
        $scripter.options.Permissions = $true
        $scripter.options.DriAll = $true
        $scripter.options.Triggers = $true
        $scripter.options.Indexes = $true
        $scripter.Options.IncludeHeaders = $true
        
        #Script the collection of URNs
        $scripter.Script($urns)
        
    }
    else {
        write-warning "Object $Schema.$Name Not Found!"
    }

} #Backup-DatabaseObject

