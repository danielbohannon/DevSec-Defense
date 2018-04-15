<#
.SYNOPSIS 
A template for a function that creates a PSObject
.DESCRIPTION
If you find yourself creating a lot of custom PSObjects with lots of Properties, this template
may help save you some typing.  It discovers the function paramters, and uses them to create a hash
that is splatted against a  (new-object psObject)
Any arguments to the function are used as values of the corresponding property when the object is created
Any default values of the function parameters are used as values of the corresponding property
The ParameterSetName defaults to 'All', and is stored as a Property of the object. 
If you use ParameterSetName attribute for a function parameter, and call the function specifying one such ParameterSetNamed argument,
the value of the ParamterSetName property identifies which set of Properties are created on the object

Becasue this is a snippet intended to be reused, the first four non-comment lines are the important part
The lines are a bit long, but that makes it easier to cut'n'paste them into a function
.PARAMETER Name
Any Parameter supplied to the function becomes a Property on the PSObject
Any value supplied for a Parameter becomes the value of the Property on the PSObject
.OUTPUTS
As written, a PSOBject is returned, with Properties as defined by the Parameters.
The following is an Example, only the first four non-commented lines are important
#>
function New-CustomDemoObject {
  [CmdletBinding(DefaultParametersetName='All')] 
  Param (
  # Replace all of the following parameters with your specific needs
   [parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)] $Workbook = 'T1.xlsx'
  ,[parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][switch] $isVisible 
  ,[parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][switch] $isKeepOpen
  ,[parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string] $SortDirection = 'Ascending'
  ,[parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][string[]] $DatabaseConnectionStrings = @('connecstr1','connectstr2')
  ,[parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)] $ParameterWithDefaultArray = @('connecstr5','connectstr6')
  ,[parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][hashtable] $CommandStringsHash  = @{cmd1=@{cmdstr='a command';vo=1;so=2};cmd2=@{cmdstr='b command';vo=2;so=1}}
  ,[parameter(ParameterSetName='PathToDir',ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)] $PathToDir = 'C:/Logs'
  ,[parameter(ParameterSetName='PathToZip',ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)] $PathToZip = 'C:/Logs/Backups'
  ,[parameter(ParameterSetName='PathToZip',ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)] $PathInZip = './'
  ,[parameter(Position=0, ValueFromRemainingArguments=$true)] $RemainingArgs
  )
  # the following four non-comment lines are the snippet that creates an object from the parameters
  # Create a list of the common parameters as a RegExp match string
  # Do this by creating a function 'gcp' that has no arguments, then get it's parameters. 
  #  These are the Common Parameters Powershell puts on every function
  #  List them, Stick ^ at the beginning of each and $ at the end of each,
  #  and join them using '|' into a single string, 
  $cp = iex 'function gcp{[CmdletBinding()]Param()$p1=@();((gci Function:$($pscmdlet.MyInvocation.MyCommand)).Parameters).Keys|%{$p1+=$_};$p1|%{"^$_`$"}};[string]::join("|",(gcp))'
  # Now operate on "this" function, list it's function's parameters, eliminate the Common Parameters,
  #   and with the remainder create a hash using the parameter name and parameter type 
  $p1=@{};((gci Function:$($pscmdlet.MyInvocation.MyCommand)).Parameters).Keys|?{$_ -notmatch $cp}|%{$p1.$_=((gci Function:$($pscmdlet.MyInvocation.MyCommand)).Parameters).$_.ParameterType.Name}
  # Iterate over this function's real parameters, turn switches to bools,
  #  remove ActionPreference (and you can do whatever else you want to in this loop)
  #  This is a good place to remove any properties, or change them, or add things
  $p2=$p1.Clone();$p1.Keys|%{$key=$_;switch ($p1.$_) {'SwitchParameter' {$p2.$key='Bool';break}'ActionPreference' {$p2.Remove($key);break}}}
  # Add the ParameterSet as a property  and create a new object
  #  using the hash of argument names and values
  # This version of the last line creates strongly-typed Properties, 
  #  but won't handle Parameters/Properties of type arrary or hashtable
  # new-object psObject -Property (&(iex $('{@{ParameterSet=[string]'+ "'$($PsCmdlet.ParameterSetName)';" +[string]::join(";",($p2.Keys|%{("{0}="-f $_+'['+$p2.$_+']'+'"$'+$_ +'"')}))+'}}')))
  # This version of the last line creates untyped Properties, and does handle hashtables and arrays.
  #  The keys of $p2 are the properties for the object. the variable (psuedocode) $$key is the value
  #   Create a statement that can be invoked, then called, which results in a long hash to pass to the -Property operator
  #   See also this blog https://jamesone111.wordpress.com/2011/01/11/why-it-is-better-not-to-use-powershell-parameter-validation/
  new-object psObject -Property (&(iex $('{@{ParameterSet=[string]'+"'$($PsCmdlet.ParameterSetName)';"+[string]::join(";",($p2.Keys|%{("{0}="-f $_+"`$$_")}))+'}}')))
  # Now in your own function, you can move properties around, change them, extend them, etc
  # I strip out all the comments above, and replace them all with a reference back to this post, to save space.
}

$newobj1 = New-CustomDemoObject # If none of the specific ParamterSet arguments are supplied, the default ParamterSetName 'All' causes all parameters to be created on the PsObject as empty Properties
$newobj2 = New-CustomDemoObject -Workbook 'another.xlsx' -PathToDir 'D:\\Logs'
$newobj3 = New-CustomDemoObject -isVisible -PathToZip 'D:\\Logs\\Backups'
#$newobj4 = New-CustomDemoObject -Workbook 'another.xlsx' -PathToZip 'D:\\Logs\\Backups' -PathToDir 'D:\\Logs' # Uncomment this - you will see an error about paramterset cannot be resolved

# Type $newobj1 ( and $newobj2, and  $newobj3) at the command prompt to see the objects that got created 

