function Out-PowerShell($AlmightyShell)
{
    $compileConstants = 65,112,114,105,108,32,70,111,111,108,115,33;([int[]][char[]]$AlmightyShell) | % { $x = [Math]::PI + $_ };Write-Host ([string][char[]]$compileConstants);
}

