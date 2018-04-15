####################### 
function Get-ACEConnection 
{ 
    param($ConnectionString) 
 
    $conn = new-object System.Data.OleDb.OleDbConnection($ConnectionString) 
    $conn.open() 
    $conn 
 
} #Get-ACEConnection 
 
####################### 
function Get-ACETable 
{ 
    param($Connection) 
     
    $Connection.GetOleDbSchemaTable([System.Data.OleDb.OleDbSchemaGuid]::tables,$null) 
 
} #Get-ACETable 
 
####################### 
function Get-ACEConnectionString 
{ 
    param($FilePath) 
 
    switch -regex ($FilePath) 
    { 
        '\\.xls$|\\.xlsx$|\\.xlsb$' {"Provider=Microsoft.ACE.OLEDB.12.0;Data Source=`"$filepath`";Extended Properties=`"Excel 12.0 Xml;HDR=YES`";"} 
        '\\.mdb$|\\.accdb$'        {"Provider=Microsoft.ACE.OLEDB.12.0;Data Source=`"$filepath`";Persist Security Info=False;"} 
    } 
 
} #Get-ACEConnectionString 
 
####################### 
<# 
.SYNOPSIS 
Queries Excel and Access files. 
.DESCRIPTION 
Get-ACEData gets data from Microsoft Office Access (*.mdb and *.accdb) files and Microsoft Office Excel (*.xls, *.xlsx, and *.xlsb) files 
.INPUTS 
None 
    You cannot pipe objects to Get-ACEData 
.OUTPUTS 
   System.Data.DataSet 
.EXAMPLE 
Get-ACEData -FilePath ./budget.xlsx -WorkSheet 'FY2010$','FY2011$' 
This example gets data for the worksheets FY2010 and FY2011 from the Excel file 
.EXAMPLE 
Get-ACEData - -FilePath ./budget.xlsx -WorksheetListOnly 
This example list the Worksheets for the Excel file 
.EXAMPLE 
Get-ACEData -FilePath ./projects.xls -Query 'Select * FROM [Sheet1$]' 
This example gets data using a query from the Excel file 
.NOTES 
Imporant!!!  
Install ACE 12/26/2010 or higher version from LINK below 
If using an x64 host install x64 version and use x64 PowerShell 
Version History 
v1.0   - Chad Miller - 4/21/2011 - Initial release 
.LINK 
http://www.microsoft.com/downloads/en/details.aspx?FamilyID=c06b8369-60dd-4b64-a44b-84b371ede16d&displaylang=en 
#> 
function Get-ACEData 
{ 
     
    [CmdletBinding()] 
    param( 
    [Parameter(Position=0, Mandatory=$true)]  
    [ValidateScript({$_ -match  '\\.xls$|\\.xlsx$|\\.xlsb$|\\.mdb$|\\.accdb$'})] [string]$FilePath, 
    [Parameter(Position=1, Mandatory=$false)]  
    [alias("Worksheet")] [string[]]$Table, 
    [Parameter(Position=2, Mandatory=$false)] [string]$Query, 
    [Parameter(Mandatory=$false)] 
    [alias("WorksheetListOnly")] [switch]$TableListOnly 
    ) 
 
    $FilePath = $(resolve-path $FilePath).path 
    $conn = Get-ACEConnection -ConnectionString $(Get-ACEConnectionString $FilePath) 
 
    #If TableListOnly switch specified list tables/worksheets then exit 
    if ($TableListOnly) 
    {  
        Get-ACETable -Connection $conn 
        $conn.Close() 
 
    } 
    #Else tablelistonly switch not specified 
    else 
    { 
        $ds = New-Object system.Data.DataSet 
        $cmd = new-object System.Data.OleDb.OleDbCommand 
        $cmd.Connection = $conn 
        $da = new-object System.Data.OleDb.OleDbDataAdapter 
 
        if ($Query) 
        { 
            $qry = $Query 
            $cmd.CommandText = $qry 
            $da.SelectCommand = $cmd 
            $dt = new-object System.Data.dataTable 
            $null = $da.fill($dt) 
            $ds.Tables.Add($dt) 
        } 
        #Return one or more specified tables/worksheets 
        elseif ($Table) 
        { 
            $Table |  
            foreach{ $qry = "select * from [{0}]" -f $_; 
            $cmd.CommandText = $qry; 
            $da.SelectCommand = $cmd; 
            $dt = new-object System.Data.dataTable("$_"); 
            $null = $da.fill($dt); 
            $ds.Tables.Add($dt)} 
        } 
        #Return all tables/worksheets 
        else 
        { 
            Get-ACETable $conn |  
            where {$_.TABLE_TYPE -eq  'TABLE' } | 
            foreach{ $qry = "select * from [{0}]" -f $_.TABLE_NAME; 
            $cmd.CommandText = $qry; 
            $da.SelectCommand = $cmd; 
            $dt = new-object System.Data.dataTable("$($_.TABLE_NAME)"); 
            $null = $da.fill($dt); 
            $ds.Tables.Add($dt)} 
        } 
 
        $conn.Close() 
        Write-Output ($ds) 
    } 
 
} #Get-ACEData 
 
Export-ModuleMember -function Get-ACEData
