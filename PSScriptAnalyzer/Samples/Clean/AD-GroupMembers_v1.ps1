function AD-GroupMembers() {
param (
$Domen,
$Group,
$User
)
if ($User){$Connection = Get-Credential -Credential $user}
if($Connection){$Member = Get-QADGroupMember -Service $Domen -Identity $Group -Credential $Connection -SizeLimit 0 -ErrorAction SilentlyContinue | Sort Name | Format-Table Name,NTAccountName,Sid,AccountIsDisabled -AutoSize}
else{$Member = Get-QADGroupMember -Service $Domen -Identity $Group -SizeLimit 0 -ErrorAction SilentlyContinue | Sort Name | Format-Table Name,NTAccountName,Sid,AccountIsDisabled -AutoSize}
$Member
}
