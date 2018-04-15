<#
    .SYNOPSIS
        Copy group membership between two accounts.
    .DESCRIPTION
        This script will copy the group membership from an existing user
        account to a new user account.
    .PARAMETER ADSPath
        This is the LDAP URL to where your user accounts are stored
    .PARAMETER NewUser
        The username of the new user account
    .PARAMETER SearchFilter
        The searchFilter to pass on to AD, I'm using FSPs so it defaults
        to foreignSecurityPrincipal, but it could be Person if you're
        working with user accounts all within the same ActiveDirectory domain.
    .PARAMETER ExistingUser
        The username of the existing user account
    .PARAMETER Verbose
        Enable the debugging statements
    .EXAMPLE
        .\\New-StudentWorker.ps1 -NewUser 'Newton' -ExistingUser 'Oldson' -ADSPath 'CN=ForeignSecurityPrincipals,DC=company,DC=com'

        GroupDN                           UserDN                           Added
        -------                           ------                           -----
        LDAP://CN=IGroup,OU=Profile,OU... LDAP://CN=S-1-5-21-57989841-1... The object already exists. (E...
        LDAP://CN=ECSStaffProfessional... LDAP://CN=S-1-5-21-57989841-1... True
        
        Description
        -----------
        This sample shows the syntax and working against FSPs, as well as a potential error you might encounter.
    .EXAMPLE
        .\\New-StudentWorker.ps1 -NewUser 'Guest' -ExistingUser 'krbtgt' -ADSPath 'DC=company,DC=com' -SearchFilter '(objectCategory=Person)'

        GroupDN                           UserDN                                                      Added
        -------                           ------                                                      -----
        LDAP://CN=Denied RODC Password... LDAP://CN=Guest,CN=Users,DC=c...                             True

        Description
        -----------
        This example shows the syntax for copying group membership between accounts in the same domain.
    .NOTES
        ScriptName : Copy-GroupMembership
        Created By : jspatton
        Date Coded : 09/22/2011 10:17:53
        ScriptName is used to register events for this script
        LogName is used to determine which classic log to write to
 
        ErrorCodes
            100 = Success
            101 = Error
            102 = Warning
            104 = Information
    .LINK
 #>
Param
    (
    [Parameter(Mandatory=$true)]$ADSPath,
    [Parameter(Mandatory=$true)]$NewUser,
    $SearchFilter = '(objectCategory=foreignSecurityPrincipal)',
    $ExistingUser
    )
Begin
    {
        $ScriptName = $MyInvocation.MyCommand.ToString()
        $LogName = "Application"
        $ScriptPath = $MyInvocation.MyCommand.Path
        $Username = $env:USERDOMAIN + "\\" + $env:USERNAME
 
        New-EventLog -Source $ScriptName -LogName $LogName -ErrorAction SilentlyContinue
 
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nStarted: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message
 
        if ($Verbose)
        {
            $DebugPreference = "Continue"
            $VerbosePreference = $DebugPreference
            }
        #	Dotsource in the functions you need.
        . .\\includes\\ActiveDirectoryManagement.ps1
        
        }
Process
    {
        if ($SearchFilter -like "*foreignSecurityPrincipal*")
        {
            Write-Verbose "Need to get a list of FSP objects and convert them to sAMAccountNames"
            $Users = Get-ADObjects -ADSPath $ADSPath -SearchFilter $SearchFilter |foreach {$_.Properties.name |Convert-FspToUsername}
            $NewUser = $Users |Where-Object {$_.sAMAccountName -like "*$($NewUser)"}
            $ExistingUser = $Users |Where-Object {$_.sAMAccountName -like "*$($ExistingUser)"}
            Write-Verbose "Found $($NewUser.sAMAccountName)"
            Write-Verbose "Found $($ExistingUser.sAMAccountName)"

            Write-Verbose "Get the group membership for CN=$($ExistingUser.Sid),$($ADSPath)"
            $UserGroups = Get-UserGroupMembership -UserDN "CN=$($ExistingUser.Sid),$($ADSPath)"
            foreach ($UserGroup in $UserGroups)
            {
                Write-Verbose "Try adding $($NewUser.sAMAccountName) to $UserGroup.GroupDN"
                Add-UserToGroup -GroupDN $UserGroup.GroupDN -UserDN "LDAP://CN=$($NewUser.Sid),$($ADSPath)"
                }
            }
        else
        {
            Write-Verbose "Get a list of user objects"
            $Users = Get-ADObjects -ADSPath $ADSPath -SearchFilter $SearchFilter
            $NewUser = $Users |Where-Object {$_.Properties.name -like "*$($NewUser)"}
            $ExistingUser = $Users |Where-Object {$_.Properties.name -like "*$($ExistingUser)"}
            Write-Verbose "Found $($NewUser.Properties.name)"
            Write-Verbose "Found $($ExistingUser.Properties.name)"
            
            Write-Verbose "Get the group membership for $($ExistingUser.Path)"
            $UserGroups = Get-UserGroupMembership -UserDN $ExistingUser.Path
            foreach ($UserGroup in $UserGroups)
            {
                Write-Verbose "Try adding $($NewUser.Properties.name) to $UserGroup.GroupDN"
                Add-UserToGroup -GroupDN $UserGroup.GroupDN -UserDN $NewUser.Path
                }
            }
        }
End
    {
        $Message = "Script: " + $ScriptPath + "`nScript User: " + $Username + "`nFinished: " + (Get-Date).toString()
        Write-EventLog -LogName $LogName -Source $ScriptName -EventID "104" -EntryType "Information" -Message $Message
        if ($Verbose)
        {
            $DebugPreference = "SilentlyContinue"
            $VerbosePreference = $DebugPreference
            }
        }
