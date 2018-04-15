Function Convert-FspToUsername
{
    <#
        .SYNOPSIS
            Convert a FSP to a sAMAccountName
        .DESCRIPTION
            This function converts FSP's to sAMAccountName's.
        .PARAMETER UserSID
            This is the SID of the FSP in the form of S-1-5-20. These can be found
            in the ForeignSecurityPrincipals container of your domain.
        .EXAMPLE
            Convert-FspToUsername -UserSID "S-1-5-11","S-1-5-17","S-1-5-20"

            sAMAccountName                      Sid
            --------------                      ---
            NT AUTHORITY\\Authenticated Users    S-1-5-11
            NT AUTHORITY\\IUSR                   S-1-5-17
            NT AUTHORITY\\NETWORK SERVICE        S-1-5-20

            Description
            ===========
            This example shows passing in multipe sids to the function
        .EXAMPLE
            Get-ADObjects -ADSPath "LDAP://CN=ForeignSecurityPrincipals,DC=company,DC=com" -SearchFilter "(objectClass=foreignSecurityPrincipal)" |
            foreach {$_.Properties.name} |Convert-FspToUsername

            sAMAccountName                      Sid
            --------------                      ---
            NT AUTHORITY\\Authenticated Users    S-1-5-11
            NT AUTHORITY\\IUSR                   S-1-5-17
            NT AUTHORITY\\NETWORK SERVICE        S-1-5-20

            Description
            ===========
            This example takes the output of the Get-ADObjects function, and pipes it through foreach to get to the name
            property, and the resulting output is piped through Convert-FspToUsername.
        .NOTES
            This function currently expects a SID in the same format as you see being displayed
            as the name property of each object in the ForeignSecurityPrincipals container in your
            domain. 
        .LINK
            http://scripts.patton-tech.com/wiki/PowerShell/ActiveDirectoryManagement#Convert-FspToUsername
    #>
    
    Param
    (
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true)]
        $UserSID
    )
    
    Begin
    {
        }

    Process
    {
        foreach ($Sid in $UserSID)
        {
            try
            {
                $SAM = (New-Object System.Security.Principal.SecurityIdentifier($Sid)).Translate([System.Security.Principal.NTAccount])
                $Result = New-Object -TypeName PSObject -Property @{
                    Sid = $Sid
                    sAMAccountName = $SAM.Value
                    }
                Return $Result
                }
            catch
            {
                $Result = New-Object -TypeName PSObject -Property @{
                    Sid = $Sid
                    sAMAccountName = $Error[0].Exception.InnerException.Message.ToString().Trim()
                    }
                Return $Result
                }
            }
        }

    End
    {
        }
    }
