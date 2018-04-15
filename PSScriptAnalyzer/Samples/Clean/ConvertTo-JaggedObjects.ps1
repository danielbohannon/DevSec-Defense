function ConvertTo-JaggedObjects {
###################################################################################################
# .Synopsis
#    Convert a hashtable full of arrays into formattable objects
# .Description
#    When you have multiple arrays that you need to somehow group together for output, ConvertTo-JaggedObjects is your solution.  It takes a hashtable of arrays (strictly so that you can give a name to each array), and produces a series of objects which have a property for each source array.   
# .Parameter Hash
#    The hashtable which applies names to arrays. For example: @{English=@("one","two"); Spanish=@("uno","dos")}
# .Example
#   $a = "one","two","three"
#   $b = "uno","dos","tres","cuatro"
#   $c = "un","deux","trois"
# 
#   ConvertTo-JaggedObjects @{English=$a; Spanish=$b; French=$c}
# 
# .Example
# It now sorts alphabetically, so you can do something like:
#  
# $a = "one","two","three"
# $b = "uno","dos","tres","cuatro"
# $c = "un","deux","trois"
#  
# ConvertTo-JaggedObjects @{"1 English"=$a; "2 Spanish"=$b; "3 French"=$c}
#  
# Will have output like:
#    
#     1 English     2 Spanish    3 French
#     ---------     ---------    --------
#     one           uno          un
#     two           dos          deux
#     three         tres         trois
#                   cuatro
###################################################################################################
Param([HashTable]$hash)
   $max = ($hash.Values | Measure Length -Max).Maximum
   ForEach($i in 0..($max-1)) { 
      $o = New-Object PSObject
      foreach($name in $hash.Keys | Sort) { 
         Add-Member -in $o -Type NoteProperty -Name $name -Value $hash[$name][$i] 
      }
      Write-Output $o
   }
}

