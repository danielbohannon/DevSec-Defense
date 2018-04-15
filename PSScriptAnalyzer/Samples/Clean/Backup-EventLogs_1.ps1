Function Backup-EventLogs
{
    <#
        .SYNOPSIS
            Backup Eventlogs from remote computer
        .DESCRIPTION
            This function backs up all logs on a Windows computer that have events written in them. This
            log is stored as a .csv file in the current directory, where the filename is the ComputerName+
            Logname+Date+Time the backup was created.
        .PARAMETER ComputerName
            The NetBIOS name of the computer to connect to.
        .EXAMPLE
            Backup-EventLogs -ComputerName dc1
        .NOTES
            May need to be a user with rights to access various logs, such as security on remote computer.
        .LINK
            http://scripts.patton-tech.com/wiki/PowerShell/ComputerManagemenet#Backup-EventLogs
    #>
    
    Param
    (
        [string]$ComputerName
    )
    
    Begin
    {
        $EventLogs = Get-WinEvent -ListLog * -ComputerName $ComputerName
        }

    Process
    {
        Foreach ($EventLog in $EventLogs)
        {
            If ($EventLog.RecordCount -gt 0)
            {
                $LogName = ($EventLog.LogName).Replace("/","-")
                $BackupFilename = "$($ComputerName)-$($LogName)-"+(Get-Date -format "yyy-MM-dd HH-MM-ss").ToString()+".csv"
                Get-WinEvent -LogName $EventLog.LogName -ComputerName $ComputerName |Export-Csv -Path ".\\$($BackupFilename)"
                }
            }
        }

    End
    {
        Return $?
        }
}
