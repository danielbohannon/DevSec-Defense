#.SYNOPSIS
#  Gets a directory entry from ActiveDirectory based on the login user name
function Get-ADUser {
[CmdletBinding()]
param([string]$UserName=${Env:userName})
   $ads = New-Object System.DirectoryServices.DirectorySearcher([ADSI]'')
   $ads.filter = "(&(objectClass=Person)(samAccountName=$UserName))"
   $ads.FindAll().GetEnumerator() | %{ $_.GetDirectoryEntry() }
}


#.SYNOPSIS
#  Gets a directory entry from ActiveDirectory based on the computer name
function Get-ADComputer {
[CmdletBinding()]
param([string]$ComputerName=${Env:ComputerName})
   $ads = New-Object System.DirectoryServices.DirectorySearcher([ADSI]'')
   $ads.filter = "(&(objectClass=Computer)(name=$ComputerName))"
   $ads.FindAll().GetEnumerator() | %{ 
      $Computer = $_.GetDirectoryEntry()
	  $Computer = Resolve-PropertyValueCollection -InputObject $Computer
      Add-Member -InputObject $Computer -Type NoteProperty -Name SID -Value $(new-object security.principal.securityidentifier $Computer.objectSID, 0)
      Add-Member -InputObject $Computer -Type NoteProperty -Name GUID -Value $(new-object GUID (,[byte[]]$Computer.objectGUID))
      Add-Member -InputObject $Computer -Type NoteProperty -Name CreatorSID -Value $(new-object security.principal.securityidentifier $Computer."mS-DS-CreatorSID", 0)
	  $Computer
   }
}

#.SYNOPSIS
#  Gets a directory entry from ActiveDirectory based on the group's friendly name
function Get-ADGroup {
[CmdletBinding()]
param([string]$UserName)
   $ads = New-Object System.DirectoryServices.DirectorySearcher([ADSI]'')
   $ads.filter = "(&(objectClass=Group)(samAccountName=$UserName))"
   $ads.FindAll().GetEnumerator() | %{ $_.GetDirectoryEntry() }
}


#.SYNOPSIS
#  Look up a DN from a user's (login) name 
function Get-DistinguishedName { 
[CmdletBinding()]
param([string]$UserName)
   (Get-ADUser $UserName).DistinguishedName
}

#.SYNOPSIS
#  Get Active Directory group membership recursively
#.EXAMPLE
#  $groups = Get-GroupMembership (Get-DistinguishedName Jaykul)
#.EXAMPLE
#  $groups = Get-GroupMembership (Get-DistinguishedName Jaykul) -RecurseLimit 0
#
#  Gets the groups the user belongs to without recursing
function Get-GroupMembership {
[CmdletBinding()]
param([string]$Name,[int]$RecurseLimit=-1)

if(!$Name.StartsWith("CN=","InvariantCultureIgnoreCase")) {
   $Name = Get-DistinguishedName $Name
}

   $groups = ([adsi]"LDAP://$Name").MemberOf
   if ($groups -and $RecurseLimit) {
      Foreach ($gr in $groups) {
         $groups += @(Get-GroupMembership $gr -RecurseLimit:$($RecurseLimit-1) |
                    ? {$groups -notcontains $_})
      }
   }
   return $groups | Convert-DistinguishedName
}

function Convert-DistinguishedName {
[CmdletBinding()]
param(
   [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
   [string]$name
)
process {
   if(!$Name.StartsWith("CN=","InvariantCultureIgnoreCase")) {
      $Name = Get-DistinguishedName $Name
   }
   $name -replace "CN=","Name=" -replace "DC=","Domain=" -replace "OU=","Org=" | ConvertFrom-PropertyString -Delimiter "," | ForEach { $_.Domain = $_.Domain -join "."; $_ } | Add-Member NoteProperty DN $name -passthru
}
}

function Resolve-PropertyValueCollection { 
param(
	[Parameter(ValueFromPipeline=$true)]
	$InputObject
)
process {
	$SingleMembers = @()
	$MultiMembers = @()
	$InputObject | Get-Member -Type Property | ForEach-Object {
		$Name = $_.Name
		if($InputObject.($Name).Count -le 1) {
			$SingleMembers += $Name
		} else {
			$MultiMembers += $Name
		}
	}
	
	$OutputObject = Select-Object -InputObject $InputObject -Property $MultiMembers
	foreach($member in $singleMembers) {
		Add-Member -InputObject $OutputObject -Type NoteProperty -Name $Member -Value ($InputObject.$Member)[0]
	}
	$OutputObject
}
}


#. SYNOPSIS
#  Pretty-print the vitals on a user...
function Select-UserInfo {
[CmdletBinding()]
param(
   [Parameter(Mandatory=$true,Position=0,ParameterSetName="Input",ValueFromPipeline=$true)]
   [System.DirectoryServices.DirectoryEntry[]]$InputObject
,
   [Parameter(Mandatory=$true,Position=0,ParameterSetName="Name",ValueFromPipelineByPropertyName=$true)]
   [string[]]$name
)
process {
   switch($PSCmdlet.ParameterSetName) {
   "Name" {
      foreach($n in $Name) {
         Write-Verbose "Getting $n User Info"
         Get-ADUser $n | Resolve-PropertyValueCollection
      }
   }
   "Input" {
      foreach($io in $InputObject) {
         Write-Verbose "Converting User Info for $($io.displayName)"
         Resolve-PropertyValueCollection -InputObject $io
      }
   }
   }
}
}


function Get-GroupMembers {
[CmdletBinding()]
param(
[Parameter(Mandatory=$true,Position=0,ParameterSetName="Input",ValueFromPipeline=$true)]
[string]$GroupName
)
process {
   Foreach ($member in (Get-ADGroup $GroupName).Members() ) {
      new-object System.DirectoryServices.DirectoryEntry $member | Resolve-PropertyValueCollection
   }
}
}

