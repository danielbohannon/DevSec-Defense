if(!$global:CommandTranscriptPrompt) {
   ## Record the original prompt so we can put it back if they change their minds...
   $global:CommandTranscriptPrompt = ${Function:Prompt}
}

function Start-CommandTranscript {
#.Synopsis
#  Start a transcript recording the commands you enter, and optionally, the success and duration of them
#.Description
#  Each time your prompt is displayed, the previous command is logged to the transcript. 
#  If you specify plain (or ps1) output, the result is basically a PowerShell script containing the commands you enter.
#  If you specify Full (or csv) output, the result is a csv file with start and end times, success, etc.
#  If you specify Annotated (the default) the duration and success of the command are appended as a comment
#.Parameter Output
#  What output format you prefer
#
#  If you specify plain (or ps1) output, the result is basically a PowerShell script containing the commands you enter.
#  If you specify Full (or csv) output, the result is a csv file with start and end times, success, etc.
#  If you specify Annotated (the default) the duration and success of the command are appended as a comment
#.Parameter Append
#  Whether to overwrite the file or append to it.
#.Parameter Path
#  The path to the file to log to
#.Example
#  Start-CommandTranscript "$(Split-Path $Profile)\\Session-$(Get-Date -f 'yyyy-mm-dd').ps1" -Output Plain
#
#  Description
#  -----------
#  Logs commands as a script to the profile directory with and output file something like: Session-2010-07-04.ps1
#.Example
#  Start-CommandTranscript "~\\Documents\\Logs\\Session $(Get-Date -f 'yyyy-mm-dd').csv" -Output Full
#
#  Description
#  -----------
#  Logs commands in CSV format to the specified file. Note that you must have a Documents\\Logs folder in your $home directory.
param(
   [Parameter(Position=0, Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
   [Alias("PSPath","Name")]
   [string]$Path = "CommandTranscript"
,
   [Parameter(Position=1,Mandatory=$false)]
   [ValidateSet("Annotated","Plain","Ps1","Csv","Full")]
   [string]$Output = "Annotated"
,
   [switch]$Append
)

end {
   switch -regex ($Output) {
      "Csv|Full"  { $extension = $Output = "csv" }
      "Plain|Ps1" { $extension = $Output = "ps1" }
      "Annotated" { $extension = "ps1" }
   }
   
   $global:CommandTranscriptOutput = $Output
   

   if( test-path $path -PathType Container ) {
      $path = Join-Path $path "CommandTranscript.$extension"
   }
#  else ## You can uncomment this block to FORCE the csv/ps1 extension.
#  {
#     $path = [System.Io.Path]::ChangeExtension($path,$extension)
#  }
   
   $global:CommandTranscriptPath = $path

   $Start = "# Command Transcript Started $(Get-Date)"
   
   if(!$Append) {
      switch($CommandTranscriptOutput) {
         "Csv" { 
            $Type, $Header, $Value = Get-History -count 1 | Add-Member -MemberType NoteProperty -Name Success -Value $? -Passthru | ConvertTo-CSV
            Set-Content -LiteralPath $global:CommandTranscriptPath -Value $Type, $Start, $Header
         }
         default {
            Set-Content -LiteralPath $global:CommandTranscriptPath -Value "$Start`n`n"
         }
      }
   } else {
      Add-Content -LiteralPath $global:CommandTranscriptPath -Value "`n`n$Start`n`n"
   }
   
   $global:CommandTranscriptPath = Resolve-Path $global:CommandTranscriptPath
   
   
   ## Insert our transcript prompt
   Function Global:Prompt {
      $last = Get-History -count 1 | Add-Member -MemberType NoteProperty -Name Success -Value $? -Passthru
      
      switch($CommandTranscriptOutput) {
         "ps1" {
            $Value = $last.CommandLine.Trim()
         }
         "csv" { 
            $null, $Value = ConvertTo-CSV -Input $last -NoTypeInformation
         }
         "annotated" {
            $Value = "{0,-75} ## Success: {1}, Execution Time: {2} " -f $last.CommandLine.Trim(), $last.Success, ($last.EndExecutionTime - $last.StartExecutionTime)
         }
      }
      
      Add-Content -LiteralPath $global:CommandTranscriptPath -Value $Value
      return &$global:CommandTranscriptPrompt @args
   }

   Write-Host $Start -Foreground Yellow -Background Black
   Write-Host "Logging commands to $global:CommandTranscriptPath" -Foreground Yellow -Background Black
}
}

function Stop-CommandTranscript {
#.Synopsis 
#  End a transcript session
#.Description
#  Terminates transcription and writes out the file item where logging occurred.
end {
   $End = "# Command Transcript Ended $(Get-Date)"
   Add-Content -LiteralPath $global:CommandTranscriptPath -Value "`n`n$End"
   ${Function:Prompt} = $Global:CommandTranscriptPrompt
   
   Write-Host $End -Foreground Yellow -Background Black
   Write-Host "Transcript is at $global:CommandTranscriptPath" -Foreground Yellow -Background Black
   
   Get-Item $global:CommandTranscriptPath
}
}

# SIG # Begin signature block
# MIIIDQYJKoZIhvcNAQcCoIIH/jCCB/oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDdMb/v/9BfEnzKwp6TIIyISK
# cmygggUrMIIFJzCCBA+gAwIBAgIQKQm90jYWUDdv7EgFkuELajANBgkqhkiG9w0B
# AQUFADCBlTELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0
# IExha2UgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYD
# VQQLExhodHRwOi8vd3d3LnVzZXJ0cnVzdC5jb20xHTAbBgNVBAMTFFVUTi1VU0VS
# Rmlyc3QtT2JqZWN0MB4XDTEwMDUxNDAwMDAwMFoXDTExMDUxNDIzNTk1OVowgZUx
# CzAJBgNVBAYTAlVTMQ4wDAYDVQQRDAUwNjg1MDEUMBIGA1UECAwLQ29ubmVjdGlj
# dXQxEDAOBgNVBAcMB05vcndhbGsxFjAUBgNVBAkMDTQ1IEdsb3ZlciBBdmUxGjAY
# BgNVBAoMEVhlcm94IENvcnBvcmF0aW9uMRowGAYDVQQDDBFYZXJveCBDb3Jwb3Jh
# dGlvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMfUdxwiuWDb8zId
# KuMg/jw0HndEcIsP5Mebw56t3+Rb5g4QGMBoa8a/N8EKbj3BnBQDJiY5Z2DGjf1P
# n27g2shrDaNT1MygjYfLDntYzNKMJk4EjbBOlR5QBXPM0ODJDROg53yHcvVaXSMl
# 498SBhXVSzPmgprBJ8FDL00o1IIAAhYUN3vNCKPBXsPETsKtnezfzBg7lOjzmljC
# mEOoBGT1g2NrYTq3XqNo8UbbDR8KYq5G101Vl0jZEnLGdQFyh8EWpeEeksv7V+YD
# /i/iXMSG8HiHY7vl+x8mtBCf0MYxd8u1IWif0kGgkaJeTCVwh1isMrjiUnpWX2NX
# +3PeTmsCAwEAAaOCAW8wggFrMB8GA1UdIwQYMBaAFNrtZHQUnBQ8q92Zqb1bKE2L
# PMnYMB0GA1UdDgQWBBTK0OAaUIi5wvnE8JonXlTXKWENvTAOBgNVHQ8BAf8EBAMC
# B4AwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzARBglghkgBhvhC
# AQEEBAMCBBAwRgYDVR0gBD8wPTA7BgwrBgEEAbIxAQIBAwIwKzApBggrBgEFBQcC
# ARYdaHR0cHM6Ly9zZWN1cmUuY29tb2RvLm5ldC9DUFMwQgYDVR0fBDswOTA3oDWg
# M4YxaHR0cDovL2NybC51c2VydHJ1c3QuY29tL1VUTi1VU0VSRmlyc3QtT2JqZWN0
# LmNybDA0BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmNv
# bW9kb2NhLmNvbTAhBgNVHREEGjAYgRZKb2VsLkJlbm5ldHRAWGVyb3guY29tMA0G
# CSqGSIb3DQEBBQUAA4IBAQAEss8yuj+rZvx2UFAgkz/DueB8gwqUTzFbw2prxqee
# zdCEbnrsGQMNdPMJ6v9g36MRdvAOXqAYnf1RdjNp5L4NlUvEZkcvQUTF90Gh7OA4
# rC4+BjH8BA++qTfg8fgNx0T+MnQuWrMcoLR5ttJaWOGpcppcptdWwMNJ0X6R2WY7
# bBPwa/CdV0CIGRRjtASbGQEadlWoc1wOfR+d3rENDg5FPTAIdeRVIeA6a1ZYDCYb
# 32UxoNGArb70TCpV/mTWeJhZmrPFoJvT+Lx8ttp1bH2/nq6BDAIvu0VGgKGxN4bA
# T3WE6MuMS2fTc1F8PCGO3DAeA9Onks3Ufuy16RhHqeNcMYICTDCCAkgCAQEwgaow
# gZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2FsdCBMYWtl
# IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8GA1UECxMY
# aHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0wGwYDVQQDExRVVE4tVVNFUkZpcnN0
# LU9iamVjdAIQKQm90jYWUDdv7EgFkuELajAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUNZLFo6r7
# 7CXUN+MEwwPtHMHYkMcwDQYJKoZIhvcNAQEBBQAEggEAsPgQe5TRWt3x0vxW86jT
# OXc6fNQo1Li4rtkt8ukxt0fgQlanKbWBDZb1Rjt4MqqZhm/ukrsbv/kKatMsJDpS
# YHb2m5LTt6gvzxZl8n/uSxz1cHwnXTX/T1U96Htv+951HqrOky1z/nSKc9dqpLMC
# LLbjvoNLgVM1Q6VQRN0eF1sTxJrLxoVwf3W/Cla3P3hXA83mngYbp7EZUrJcdNGD
# JEzBJK/5RgUpnSqGv2lO6sHByJEpVEpJTJE9HsrM4Z5Utg30hhPcTRq2ksIPzKBv
# FGvAz1lsnHA0gKhdWSh6iG7yvtlXdh/TkiI+9xunWe31mpAitBLGX3PJ+xIgyt98
# LA==
# SIG # End signature block

