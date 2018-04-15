
#--------------------------------------------------------
# Script  : Advanced2_2011.ps1
# Author  : marc carter (marcadamcarter)
# Date    : 4/5/2011
# Keywords: PowerShell, Scripting Games
# Comments:    
# Expected Arguments: ADquery, Excel, textfile, <device_name_or_ip>
# Examples:    .\\Advanced2_2011.ps1 ADquery
#              .\\Advanced2_2011.ps1 Excel <file_fullname>
#              .\\Advanced2_2011.ps1 textfile <file_fullname>  -  File format: List of device names, one per line.
#              .\\Advanced2_2011.ps1 <device_name_or_ip>
#--------------------------------------------------------



#Begin Functions
Function get-runningServices{
#--------------------------------------------------------
<#   
.SYNOPSIS   
    Retrieves currently running Services and their Dependent services and reports on the dependent services status
.DESCRIPTION 
    Retrieves currently running Services and their Dependent services and reports on the dependent services status
.PARAMETER server
    Name of the server(s) you wish to query. 
.NOTES   
    Name: get-runningServices
    Author: Marc Carter
    DateCreated: 5APR2011
.EXAMPLE  
    get-ModuleInfo LOCALHOST
     
Description 
------------ 
Returns a formatted list of running Services and their dependancies. 
#>  
[cmdletbinding( 
    DefaultParameterSetName = 'server', 
    ConfirmImpact = 'low' 
)] 
Param( 
    [Parameter( 
        Mandatory = $True, 
        Position = 0, 
        ParameterSetName = '', 
        ValueFromPipeline = $True)] 
        [string][ValidatePattern(".{2,}")]$server
) 
    Begin{
        $ErrorActionPreference = "SilentlyContinue"
        $array = @()
    }

    Process{
        $isServer = get-OSVersion $server
        #Test to see if running server OS
        if($isServer){
            get-service -ComputerName $server | where-object {$_.Status -eq "Running"} | Select-Object name | % {
                $BaseServiceName = $_.Name
                Get-Service -name $_.Name -DependentServices | Sort-Object Name | Select-Object Name, Status | % {
                    #Group values into a custom object in order to output in table view.
                    $tmpObj = New-Object Object
                    $tmpObj | add-member -membertype noteproperty -name "BaseServiceName" -value $BaseServiceName
                    $tmpObj | add-member -membertype noteproperty -name "DependentName" -value $_.Name
                    $tmpObj | add-member -membertype noteproperty -name "DependentStatus" -value $_.Status
                    #Append the object to the existing array.
                    $array += $tmpObj
                
                }
            }
        }
        else { "Skipping $server (Not running Server OS)" }
    }
    
    End{
        #Output results of the array and set both to $Null when done.
        $array | ft @{Name='BaseServiceName';Expression={$_.BaseServiceName}; Align='Right';}, @{Name='DependentName';Expression={$_.DependentName};}, @{Name='DependentStatus';Expression={$_.DependentStatus};align='Left';} -auto
        $array = $Null
        $tmpObj = $Null
    }
}
#--------------------------------------------------------
#End function get-runningServices



function get-listFromAD{
#--------------------------------------------------------
<#  
.SYNOPSIS  
    Retrieves list of devices from active directory.
.DESCRIPTION
    Retrieves list of devices from active directory.
Description
------------
Returns list of devices from AD query.
#>  
   $strFilter = "(&(objectcategory=computer)(operatingsystem=Windows Server*))"  #All Server OS
   $props = "cn"
   $dse = [ADSI]"LDAP://rootdse"
   #$root = "LDAP://"+$dse.defaultNamingContext
   $ds = New-Object DirectoryServices.DirectorySearcher([ADSI]$root,$strFilter,$props)
   $ds.PageSize = 1000
   $results = $ds.FindAll()
   foreach($obj in $results){
       $obj.properties.cn
   }
}
#--------------------------------------------------------
#End function get-listFromAD


function get-OSVersion($computer){
#--------------------------------------------------------
    $os = Get-WmiObject -class Win32_OperatingSystem -computerName $computer 
    Switch ($os.Version){ 
        "5.1.2600" { $False } 
        "5.1.3790" { $True } 
        "6.0.6001" { 
            if($os.ProductType -eq 1){ $False }
            else{ $True }
        }
        "6.1.7600"{ 
            if($os.ProductType -eq 1){ $False }
            else{ $True }
        }
        DEFAULT { "N/A" } 
    }
} 
#--------------------------------------------------------
#End get-OSVersion 
#End Functions



#Main Script 
#--------------------------------------------------------
#If arguments are present, determine how to proceed.
if($args){
    <#
    If arguments exist, assume input from external sorce
    .Expected: ADquery, Excel, Text, <device_name_or_ip>
    
    .Examples:  .\\Advanced2_2011.ps1 ADquery
                .\\Advanced2_2011.ps1 Excel <file_fullname>
                .\\Advanced2_2011.ps1 textfile <file_fullname>  -  File format: List of device names, one per line.
                .\\Advanced2_2011.ps1 <device_name_or_ip>
    #>
    switch($args[0].toLower()){
        "adquery" {
            foreach($device in get-listFromAD){
                $device.toUpper()
                get-runningServices $device
            }
        }
        "excel" {
            if(Test-Path $args[1]){
                $xlCSV=6
                $xls=$args[1]
                $csv=$args[1] -replace(".xls",".csv")
                $xl=New-Object -com "Excel.Application"
                $wb=$xl.workbooks.open($xls)
                $wb.SaveAs($csv,$xlCSV)
                $xl.displayalerts=$False
                $xl.quit()

                Import-Csv $csv | Select-Object name | % {
                    $_.name
                    get-runningServices $_.name
                }
            }
            else{
                Write-Error "`nInvalid path for $args[1]`nCheck the path and try again."
            }
            
        }
        "textfile" {
            if(Test-Path $args[1]){
                Get-Content -Path $args[1] | % {
                    $_
                    get-runningServices $_
                }
            }
            else{
                Write-Error "`nInvalid path for $args[1]`nCheck the path and try again."
            }
        }
        Default {
            #Initiate the function taking the first argument (assume single server instance name).
            get-runningServices $args[0]
        }
    }
}
else{ 
    #Otherwise, initiate the function and prompt for device.
    get-runningServices
}
