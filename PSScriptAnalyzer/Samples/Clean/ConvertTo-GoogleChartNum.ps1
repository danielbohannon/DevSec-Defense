## Google Chart API extended value encoding function
#########################################################################
#function ConvertTo-GoogleChartNum{
BEGIN {
   ## Google's odydecody is a 64 character array
   $ody = "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","-","."

   ## The actual filter function
   filter encode {
      # we have a hard-coded "overflow" value 
      if($_ -ge ($ody.Count * $ody.Count) ) { return "__" } 
      $y = -1  # $y is a ref variable, so it has to be defined
      $x = [Math]::DivRem( $_, $ody.Count, [ref]$y )
      return "$($ody[$x])$($ody[$y])"
   }
   ## Handle numbers as parameters
   [int[]]$nums = $args | % { [int]$_ }
}
## Or handle numbers from the pipeline. We don't care :-)
PROCESS {
   if($_ -ne $null) { $nums += $_ }
}
#}

END {
   $diff =  ($nums | sort  | select -last 1) / ($ody.Count * $ody.Count -1)
   $nums | %{$_/$diff} | encode
}
