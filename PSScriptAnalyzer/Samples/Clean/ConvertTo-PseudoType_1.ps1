function ConvertTo-PseudoType {
<#
.Synopsis
   Converts objects to custom PSObjects with robust type support
.Parameter TypeName
   The name(s) of the PseudoType(s) to be inserted into the objects for the sake of formatting
.Parameter Mapping
   A Hashtable of property names to types (or conversion scripts)
.Parameter InputObject
   An object to convert.
.Example
   Get-ChildItem | Where { !$_.PsIsContainer } | Export-CSV files.csv
   ## Given that a CSV file of file information exists, 
   ## And we want to rehydrate it and be able to compare things...
   ## We need to create a mapping of properties to types
   ## Optionally, we can provide scriptblocks to convert instances
   $Mapping = @{ 
      Attributes         = [System.IO.FileAttributes]
      CreationTime       = [System.DateTime]
      CreationTimeUtc    = [System.DateTime]
      Directory          = [System.IO.DirectoryInfo]
      DirectoryName      = [System.String]
      Exists             = [System.Boolean]
      Extension          = [System.String]
      FullName           = [System.String]
      IsReadOnly         = [System.Boolean]
      LastAccessTime     = [System.DateTime]
      LastAccessTimeUtc  = [System.DateTime]
      LastWriteTime      = [System.DateTime]
      LastWriteTimeUtc   = [System.DateTime]
      Length             = [System.Int64]
      Name               = [System.String]
      PSChildName        = [System.String]
      PSDrive            = [System.Management.Automation.PSDriveInfo]
      PSIsContainer      = [System.Boolean]
      PSParentPath       = [System.String]
      PSPath             = [System.String]
      PSProvider         = { Get-PSProvider $_ }
      ReparsePoint       = [System.Management.Automation.PSCustomObject]
      VersionInfo        = [System.Diagnostics.FileVersionInfo]
   }
   
   ## When we import, we the Selected.System.IO.FileInfo, which is what you'd get from | Select *
   Import-CSV | ConvertTo-PseudoType Selected.System.IO.FileInfo $Mapping
   
   ## That way, the output will look as though you had run:
   Get-ChildItem | Where { !$_.PsIsContainer } | Select *
   
   NOTE: Not all types are rehydrateable from CSV output -- the "VersionInfo" will be hydrated as a string...
#>
[CmdletBinding()]
param(
   [Parameter(Mandatory=$true, Position=0)]
   [Alias("Name","Tn")]
   [String]$TypeName
,
   [Parameter(Mandatory=$true, Position=1)]
   [Hashtable]$Mapping
,
   [Parameter(Mandatory=$true, Position=99, ValueFromPipeline=$true)]
   [PSObject[]]$InputObject
)
begin {
   $MappingFunction = @{}
   foreach($key in $($Mapping.Keys)) {
      $MappingFunction.$Key = {$_.$Key -as $Mapping.$Key}
   }
}
process {
   foreach($IO in $InputObject) {
      $Properties = @{}
      foreach($key in $($Mapping.Keys)) {
         if($Mapping.$Key -is [ScriptBlock]) {
            $Properties.$Key = $IO.$Key | ForEach-Object $Mapping.$Key
         } elseif($Mapping.$Key -is [Type]) {
            if($Value = $IO.$Key -as $Mapping.$Key) {
               $Properties.$Key = $Value
            } else {
               $Properties.$Key = $IO.$Key
            }
         } else {
            $Properties.$Key = [PSObject]$IO.$Key
         }
      }
      New-Object PSObject -Property $Properties | %{ $_.PSTypeNames.Insert(0, $TypeName); $_ }
    }
}
}

