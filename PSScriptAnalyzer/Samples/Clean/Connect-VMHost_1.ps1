#requires -version 2 
#requires -pssnapin VMware.VimAutomation.Core 
Function Connect-VMHost {
    <#
    .Summary
        Used to Connect a disconnected host to vCenter.
    .Parameter VMHost
        VMHost to reconnect to virtual center
    .Example
        Get-VMHost | Where-Object {$_.state -eq "Disconnected"} | Connect-VMHost
        
        Will Attempt to reconnect any host that are currently disconnected.
    .Example
        Connect-VMHost -Name ESX1.get-admin.local
        
        Will reconnect ESX1 to vCenter
    #>
    [CmdletBinding(
        SupportsShouldProcess=$True,
	    SupportsTransactions=$False,
	    ConfirmImpact="low",
	    DefaultParameterSetName="ByString"
	)]
    Param(
        [Parameter(
            Mandatory=$True,
            Valuefrompipeline=$true,
            ParameterSetName="ByObj"
        )]
        [VMware.VimAutomation.Client20.VMHostImpl[]]
        $VMHost,
        
        [Parameter(
            Mandatory=$True,
            Position=0,
            ParameterSetName="ByString"
        )]
        [string[]]
        $Name
    )
    Begin {
        IF ($Name) {
            $VMHost = $Name|%{ Get-VMHost -Name $_ }
        }
    }
    process {
        Foreach ($VMHostImpl in ($VMHost|Get-View)) {
            $ReconnectSpec = New-Object VMware.Vim.HostConnectSpec
            $ReconnectSpec.HostName = $VMHostImpl.Summary.Config.Name
            $ReconnectSpec.Port = $VMHostImpl.Summary.Config.Port
            $ReconnectSpec.Force = $true
            if ($pscmdlet.ShouldProcess($VMHostImpl.name)) {
                $VMHostImpl.ReconnectHost_Task($ReconnectSpec)
            }
        }
    }
}
