function Add-SSLCertificate{
    param([string]$pfxPath,[string]$pfxPassword,[string]$hostHeader,[string]$siteName)

    $certMgr = New-Object -ComObject IIS.CertObj -ErrorAction SilentlyContinue    
    $certMgr.ImportToCertStore($pfxPath,$pfxPassword,$true,$true)

    Import-Module WebAdministration;
    New-WebBinding -Name $siteName -Port 443 -Protocol https -HostHeader $hostHeader    
}
