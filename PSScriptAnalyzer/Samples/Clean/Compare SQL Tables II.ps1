function Convert-TableToList
{
    param(
        $t,
        $colid = 0
    )
    $t | % {$_.item($colid)}
}


function Compare-Tables
{
    param(
        $name,
        $db1,
        $db2,
        $exclude = @()
        )

# @bernd_k http://pauerschell.blogspot.com/
# requires on sqlise http://sqlpsx.codeplex.com/

$sql = "select name from sys.columns  where object_id = object_id('$db1..$name') order by column_id"
Invoke-ExecuteSql  $sql 'variable' columns

$columns = Convert-TableToList $columns | % { if ($exclude -notcontains $_) {$_} }
$columnlist = $columns -join ', '
$sql = @"
Select 1 [table], $columnlist from $db1..$name
except
Select 1 [table], $columnlist from $db2..$name
union
Select 2 [table], $columnlist from $db2..$name
except
Select 2 [table], $columnlist from $db1..$name
ORDER by 2
"@
$sql
Invoke-ExecuteSql  $sql 'grid'
}

# Compare-Table2  sometable db1 db2 -ex @('colx', 'coly')


