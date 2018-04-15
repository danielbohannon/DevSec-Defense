function ConvertTo-MultiArray {
    <#
 .Notes
 NAME: ConvertTo-MultiArray
 AUTHOR: Tome Tanasovski
 Website: http://powertoe.wordpress.com
 Twitter: http://twitter.com/toenuff
 Version: 1.0
 CREATED: 11/5/2010
 LASTEDIT:
 11/5/2010 1.0
 Initial Release

 .Synopsis
 Converts a collection of PowerShell objects into a multi-dimensional array

 .Description
 Converts a collection of PowerShell objects into a multi-dimensional array.  The first row of the array contains the property names.  Each additional row contains the values for each object.
 
 This cmdlet was created to act as an intermediary to importing PowerShell objects into a range of cells in Exchange.  By using a multi-dimensional array you can greatly speed up the process of adding data to Excel through the Excel COM objects.

 .Parameter InputObject
 Specifies the objects to export into the multi dimensional array.  Enter a variable that contains the objects or type a command or expression that gets the objects. You can also pipe objects to ConvertTo-MultiArray.

 .Parameter Array
 Takes a reference to an object.  The object will be formatted as a new multi-dimensional array of the appropriate size for the InputObject passed to the cmdlet.

 .Inputs
 System.Management.Automation.PSObject
        You can pipe any .NET Framework object to ConvertTo-MultiArray

 .Outputs
 $Null & Object[,]
        There is no direct output from this cmdlet, however, the object passed as a reference in the -Array parameter will contain a new multi-dimensional array.

 .Example
 $array = $null
 get-process |Convertto-MultiArray ([ref]$array)

 .Example
 $array = $null
 $dir = Get-ChildItem c:\\
 Convertto-MultiArray -InputObject $dir -Array ([ref]$array)

 .LINK
 http://powertoe.wordpress.com

#>
    param(
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,
        [Parameter(Mandatory=$true, Position=0)]
        [ref] $Array
    )
    BEGIN {
        $objects = @()
    }
    Process {
        $objects += $InputObject        
    }
    END {
        $properties = $objects[0].psobject.properties |%{$_.name}
        $array.Value = New-Object 'object[,]' ($objects.Count+1),$properties.count
        # i = row and j = column
        $j = 0
        $properties |%{
            $array.Value[0,$j] = $_
            $j++
        }
        $i = 1
        $objects |% {
            $item = $_
            $j = 0
            $properties | % {
                $array.value[$i,$j] = $item.($_)
                $j++
            }
            $i++
        }
    }    
}

