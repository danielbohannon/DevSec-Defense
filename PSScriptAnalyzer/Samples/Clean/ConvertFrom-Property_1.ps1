<#
.SYNOPSIS
   Converts data from flat or single-level property files into PSObjects
.DESCRIPTION
   Converts delimited string data into objects
.PARAMETER PropertyText
   The text to be parsed
.PARAMETER Separator
   The value separator string used between name=value pairs. Allows regular expressions.
   Defaults to "=" and is usually either "=" or ":" or ";"
.PARAMETER Delimiter
   The property separator string used between sets of name=value pairs. Allows regular expressions.
   Defaults to "\\n\\s*\\n?" and is usually either "`n" or "`n`n" or "\\n\\s*\\n"
.PARAMETER RecordSeparator
   The record separator string is used between records or sections in a text file.
   Defaults to "\\n\\[(.+)\\]\\s*\\n" for ini files, and is usually either "\\n\\s*\\n" or "\\n\\[(.*)\\]\\s*\\n"
   
   To support named sections or records, make sure to use a regular expression here that has a capture group defined.
.EXAMPLE
   ConvertFrom-PropertyString config.ini
   
   Reads in an ini file (which has key=value pairs), using the default settings

   .EXAMPLE
   @"
   ID:3468
   Type:Developer
   StartDate:1998-02-01
   Code:SWENG3
   Name:Baraka

   ID:11234
   Type:Management
   StartDate:2005-05-21
   Code:MGR1
   Name:Jax
   "@ |ConvertFrom-PropertyString -sep ":" -RecordSeparator "\\r\\n\\s*\\r\\n" | Format-Table


   Code             StartDate       Name            ID              Type           
   ----             ---------       ----            --              ----           
   SWENG3           1998-02-01      Baraka          3468            Developer      
   MGR1             2005-05-21      Jax             11234           Management     
   
   
   Reads records from a key:value property file with records separated by blank lines.
.EXAMPLE
   ConvertFrom-PropertyString data.txt -Separator ":"
   
   Reads in a property file which has key:value pairs
.EXAMPLE
   Get-Content data.txt -Delimiter "`r`n`r`n" | ConvertFrom-PropertyString -Separator ";"
   
   Reads in a property file with key;value pairs, and sections separated by blank lines, and converts it to objects
.EXAMPLE
   ConvertFrom-PropertyString data.txt -delimiter '\\r\\n\\r\\n' -Separator ";"
   
   Reads in a property file with key;value pairs, and sections separated by blank lines, and converts it to objects   
.EXAMPLE
   ConvertFrom-PropertyString data.txt -RecordSeparator "^;(.*?)\\r*\\n" -Separator ";"
   
   Reads in a property file with key:value pairs, and sections with a header that starts with the comment character ';'
   
.NOTES
   v2 changes the output so that if there are multiple instances of the same key, we collect the values in an array
#>

#function ConvertFrom-PropertyString {
[CmdletBinding(DefaultParameterSetName="Data")]
param(
   [Parameter(Position=99, Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Data")]
   [Alias("Data","Content")]
   [string]$RecordText
,
   [Parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName="File")]
   [Alias("PSPath","FileName")]
   [string]$InputFile
,
   [Parameter()][Alias("ValueSeparator")]
   [String]$Separator='='
,
   [Parameter()][Alias("PropertySeparator")]
   [String]$Delimiter='(?:\\s*\\n+\\s*)+'
,
   [Parameter()]
   [String]$RecordSeparator='(?:\\n|^)\\[([^\\]]+)\\]\\s*\\n'
,
   [Parameter(ParameterSetName="Data")]
   [Alias("MultiRecords","MR")]
   [Switch]$MultipleRecords
   
)
begin {
   $Splitter = New-Object System.Text.RegularExpressions.Regex ([System.String]$RecordSeparator), ([System.Text.RegularExpressions.RegexOptions]"Multiline,IgnoreCase,Compiled")
}
process {
   Write-Verbose "ParameterSet: $($PSCmdlet.ParameterSetName)"
   $InputData = @{}
   if($PSCmdlet.ParameterSetName -eq "File") {
      $MultipleRecords = $true
      $RecordText = Get-Content $InputFile -Delimiter ([char]0)
   }
   if($PsBoundParameters.ContainsKey("RecordSeparator")) {
      $MultipleRecords = $true
   }
   if($MultipleRecords) {
      $Records = $splitter.Split( $RecordText ) | ? { $_ }
      if($Splitter.GetGroupNumbers().Count -gt 1) {
         while($Records) {
            $key,$value,$Records = $Records
            $InputData.$Key += @($value)
         }
      } else {
         $InputData."" = $Records
      }
   } else {
      $InputData."" = @($RecordText)
   }

   foreach($key in $InputData.Keys) {
      foreach($record in $InputData.$key) {
         Write-Verbose "Record: $record"
         if($Key) { $output = @{"PSName"=$key} }
         elseif($InputFile) { $output = @{"PSName"=((get-item $InputFile).PSChildName)} }
         else{ $output = @{} }
         
         foreach($line in $record -split $Delimiter) {
            [string[]]$data = $line -split $Separator,2 | foreach { $_.Trim() } | where { $_ }
            Write-Verbose "Line: $Line | Data: $($data -join '--')"
            switch($data.Count) {
               1 { $output.($Data[0]) += @($null)    }
               2 { $output.($Data[0]) += @($Data[1]) }
            }
         }
         foreach($key in $Output.Keys | Where { $Output.$_.Count -eq 1 } ) {
            $Output.$key = $Output.$key[0]
         }
         
         if($output.Count) {
            New-Object PSObject -Property $output
         }
      }
   }
}
#}

