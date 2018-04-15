param( 	[String[]]$Table = $null,
		$SqlServerOne = 'YourDatabaseServer',
        $FirstDatabase = 'FirstDatabaseToCompare',
        $SqlUsernameOne = 'SQL Login',
        $SqlPasswordOne = 'SQL Password',
        $SqlServerTwo = 'YourDatabaseServer',
        $SecondDatabase = 'SecondDatabaseToCompare',
        $SqlUsernameTwo = 'SQL Login',
        $SqlPasswordTwo = 'SQL Password',
        $FilePrefix = 'Log',
        [switch]$Log,
        [switch]$Column)
		
if ($Input)
{
	foreach ($item in $Input)
	{
		if ($item -is [string])
		{
			$Table += $item
		}
		else 
		{
			foreach ($property in $item.psobject.properties)
			{
				if ('name', 'TableName' -contains $property.name)
				{
					$Table += $Property.value
					break
				}
			}
		}
	}
}

if ($Table.count -eq 0)
{
	throw 'A table to compare is required.'
}

$File = $FilePrefix + '{0}-{1}.csv'

$OFS = "', '"

$ColumnQuery = @"
SELECT sysobjects.name AS TableName, syscolumns.name AS ColumnName, systypes.name AS type, 
	syscolumns.length
FROM systypes
  INNER JOIN syscolumns ON systypes.xusertype = syscolumns.xusertype  --get data type info
  INNER JOIN sysobjects ON syscolumns.id = sysobjects.id 
WHERE     
sysobjects.name IN ('$Table')
"@

function Run-Query()
{
	param (
	$SqlQuery,
	$SqlServer,
	$SqlCatalog, 
	$SqlUser,
	$SqlPass
	)
	
	$SqlConnString = "Server = $SqlServer; Database = $SqlCatalog; user = $SqlUser; password = $SqlPass"
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = $SqlConnString
	
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.CommandText = $SqlQuery
	$SqlCmd.Connection = $SqlConnection
	
	$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
	$SqlAdapter.SelectCommand = $SqlCmd
	
	$DataSet = New-Object System.Data.DataSet
	$a = $SqlAdapter.Fill($DataSet)
	
	$SqlConnection.Close()
	
	$DataSet.Tables | Select-Object -ExpandProperty Rows
}

[String[]]$Properties = 'TableName', 'ColumnName', 'Type', 'Length'

Write-Debug "Checking Tables: '$Table'"

$ColumnsDBOne = Run-Query -SqlQuery $ColumnQuery -SqlServer $SqlServerOne -SqlCatalog $FirstDatabase -SqlUser $SqlUsernameOne -SqlPass $SqlPasswordOne | Select-Object -Property $Properties
 
$ColumnsDBTwo = Run-Query -SqlQuery $ColumnQuery -SqlServer $SqlServerTwo -SqlCatalog $SecondDatabase -SqlUser $SqlUsernameTwo -SqlPass $SqlPasswordTwo | Select-Object -Property $Properties
 
Write-Host 'Differences in Columns: '
$Database = @{Name='Database';Expression={if ($_.SideIndicator -eq '<='){'{0} / {1}' -f $FirstDatabase, $SqlServerOne} else {'{0} / {1}' -f $SecondDatabase, $SqlServerTwo}}}

$ColumnDifference = Compare-Object $ColumnsDBOne $ColumnsDBTwo -SyncWindow (($TablesDBOne.count + $TablesDBTwo.count)/2) -Property $Properties | select 'TableName', 'ColumnName', 'Type', 'Length', $Database
 
if ($log)
{
	$ColumnDifference | Export-Csv -Path ($file -f $FirstDatabase, $SecondDatabase) -NoTypeInformation
}

$OFS = ', '
$ColumnDifference | Sort-Object -Property 'TableName', 'ColumnName', 'Type', 'Length', 'Database'
