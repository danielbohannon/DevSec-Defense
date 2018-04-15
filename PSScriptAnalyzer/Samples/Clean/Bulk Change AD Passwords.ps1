
#-------------------------------------------------------------
# install http://www.quest.com/powershell/activeroles-server.aspx
 Add-PSSnapin Quest.ActiveRoles.ADManagement

# CSV Format : NTAccountName,oldpassword,newpassword


$UserList = Import-Csv c:\\temp\\users.csv # | select-object -first 2 

$userlist | foreach-object {
    Write-output -----------------------------------------------
    Write-output $_.NTAccountName

    $ADUser= Get-QADUser  $_.NTAccountName
    $ADSIUser = [adsi] $ADUser.Path
    
    Write-output $ADSIUser.displayName
    Write-output "Changing password from $($_.OldPassword) to $($_.NewPassword) ...."
    $result = $ADSIUser.psbase.invoke("ChangePassword",$_.OldPassword, $_.NewPassword)
    Write-output "Password change result $result"
    ## Error and success handling is needed 0 is OK the rest is an error 
    ## http://msdn.microsoft.com/en-us/library/aa772195(v=VS.85).aspx 
}

