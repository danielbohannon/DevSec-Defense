<#
.SYNOPSIS 
Compares Registry Key Properties and subkeys across multiple computers
.DESCRIPTION
The function Get-AllRegKey  will recurse down from a given key, returning an array having
    the key's properties, subkeys, and their properties and subkeys.
Provide Get-AllRegKey a list of computernames, and it will remote to those computers
    and return the properties, etc. of the same key on the remote computer
Provide function Compare-AllRegKey with the name of the reference computer, a list of
    two or more computer names, and it will call Get-AllRegKey to retrieve the key 
    information from all the listed computers, then use Compare-Object to return 
    just the differences.
If you want more control over the Compare-Object step, you should modify the 
    function (suggestions welcome for an efficient/concise way to add Compare-Object 
    parameters to the Compare-AllRegKey function)
  
.PARAMETER ComputerNames
In the Get-AllRegKey function this is a single computer name or an array of computer names
In the Compare-AllRegKey function, this must be an array of at least two computer names
.PARAMETER RegKey
a single registry key/hive from which recursion starts, using the Registry Provider syntax
The value defaults to the current-scoped variable $DefaultRegistryKey
.PARAMETER -ReferenceObject
Applies only to the Compare-AllRegKey function, this parameter identifies the computer
against which the other computers are compared. This string must be one of the computer
names found in the ComputerNames parameter.
.EXAMPLE
C:\\PS> Get-AllRegKey
.EXAMPLE
C:\\PS> Get-AllRegKey -RegistryKey 'HKLM:\\SOFTWARE\\Microsoft\\PowerShell'
.EXAMPLE
C:\\PS> Get-AllRegKey -ComputerNames @('localhost','RemoteCN')
.EXAMPLE
C:\\PS> Get-AllRegKey -ComputerNames @('localhost','Computer1','Computer2')
.EXAMPLE
C:\\PS> Get-AllRegKey localhost 'HKLM:\\SOFTWARE\\Microsoft\\PowerShell'
.EXAMPLE
C:\\PS> Compare-AllRegKey -ComputerNames @('localhost','RemoteCN') 
.EXAMPLE
C:\\PS> Compare-AllRegKey -ComputerNames @('CN1','CN2') -ReferenceObject CN2
#>

################################################################################
# Default values for the Registry Key and the list of computernames
$DefaultRegistryKey='HKLM:\\SOFTWARE\\Microsoft\\PowerShell'
$computerNames= @('localhost','ncat099')

################################################################################
# The scriptblock that does the actual work of creating an object representing a 
#  registry key and all it's properties and subkeys and their properties. No Defaults
#  This is recursive and remoteable
$_getRegKeySB = {Param($RegistryHive)
  # Create a local named function
  function _getRegKey {
    Param($RegistryHive)
    # $data is an array, local to each loop of the recursion
    #    initialize it with the name of the hive/key
    $data=@($RegistryHive)
    # Get the hive/keys properties, excluding the ones added by PS
    $props = Get-ItemProperty -Path $RegistryHive | 
      Select * -Exclude PS*Path,PSChildName,PSDrive,PSProvider
    # if $props is empty, piping it to get-member produces an error message
    # so test it for non-null first
    if ($props) {
      $props = $props | get-member -memberType NoteProperty
      # prepend each property with the full name of the key, and add it to $data
      foreach ($p in $props) {$data+=("$RegistryHive`:"+$p.Definition)}
    }
    # recursivly call the same algorithm for any subkeys of the hive/key
    foreach ($sk in (get-item $RegistryHive).GetSubKeyNames()) {
      # if there are any subkeys, append their data to the current data.
      # Use the full name of the key
      $data += (&_getRegKey (($RegistryHive)+'\\'+ $sk))
    }
    # the local named function's output is the array representation of the hive/key
    $data
  }
  # Call the local named function
  &_getRegKey $RegistryHive
}

################################################################################
# Across all computers, get the key and subkeys from the registry
#  returns a hash of array objects, keyed by computer name
function Get-AllRegKey {
  Param (
    # Single computer name or an array of computer names. 
    #  Defaults to the "current scoped variable by the same name"
    $computerNames = $computerNames
    # A valid key
    ,$RegistryKey = $DefaultRegistryKey
  )
  # create the empty hash
  $AllRegKey = @{}
  # iterate over each computer name
  foreach ($cn in $computerNames) {
    switch ($cn) {
      # If the computer name is localhost, or the same name as hostname
      #   use the Call operator to call the scriptblock, and assign the array returned 
      #   to the hash using the current computername as the key
      {$_ -match "localhost|" + (hostname)} {
        $AllRegKey.$cn = &$_getRegKeySB $RegistryKey
        break
      }
      # for all other computer names, execute the command remotely using invoke-command
      default {
        # pass the scriptblock to the remote computers
        #  assign the array returned to the hash using the current computername as the key
        $AllRegKey.$cn = (invoke-command -Scriptblock $_getRegKeySB `
            -ArgumentList $RegistryKey -computername "$cn")
      }
    }
  }
  #return the hash of arrays
  $AllRegKey
}

################################################################################
# Across all computers, get the key and subkeys from the registry
#  returns a hash of array objects, keyed by computer name
function Compare-AllRegKey {
  Param (
    # Must be an array, with 2 or more members; 
    #   defaults to the "current scoped variable by the same name"
    $computerNames = $computerNames
    # A valid key
    ,$RegistryKey = $DefaultRegistryKey
    # The name of the computer to use as the reference 
    ,$ReferenceObject
  )
Begin {
  # If the argument for $ReferenceObject is null, then default 
  #    to the first element of $computerNames
  if (!$ReferenceObject) {$ReferenceObject =$computerNames[0]}
  else {
    # Validate that the $referenceObject is an element of $computerNames
    if (!($computerNames -contains $ReferenceObject)) {
          throw ("{0} is not a member of the list {1}" -f $ReferenceObject, `
               ($computerNames -join ','))}
  }
  # Get the Registry Key data for all computers 
  $AllRegKey = Get-AllRegKey $computerNames $RegistryKey
} 
Process {
  # Iterate over the computernames, excluding the $ReferenceObject
  $diff = @{};
  foreach ($cn in $computerNames | Where {$cn -ne $ReferenceObject}) {
    # compare $ReferenceObject to the remaining objects, accumulate into $diff
    $diff.$cn = Compare-Object -ReferenceObject $AllRegKey.$ReferenceObject `
        $AllRegKey.$cn | Where-Object { `
            ($_.SideIndicator -eq '=>') -or ($_.SideIndicator -eq '<=') }
  }
    # Return the difference hash
  $diff
}
}

# The following lines will compare the default registry key 
#  across the default array of computernames
Compare-AllRegKey 


